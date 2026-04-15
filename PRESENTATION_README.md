# FAS Deep Presentation README

This document is a presentation-ready technical guide for the active algorithm pipeline in this repository.
It is designed for viva, seminar, internal review, and project defense.

Use this document when you need:
- a clear end-to-end story of the system
- exact algorithm logic from source code
- line-by-line explanation of critical code blocks
- formulas and threshold logic to answer technical questions confidently

---

## 1) Project Summary For Presentation

FAS (Face Recognition Attendance System) is an offline mobile application built with Flutter.
It recognizes students from camera frames, marks attendance, attaches emotion tags, and exports reports.

The runtime recognition pipeline is:
1. Detect face with ML Kit (M1)
2. Crop face ROI
3. Generate 128D embedding with FaceNet TFLite (M2)
4. Compare with stored embeddings using Euclidean KNN logic (M3 + attendance runtime matcher)
5. Apply multi-stage verification and consecutive-frame gating
6. Mark attendance and store in local SharedPreferences database (M4 + DatabaseManager)
7. Optionally detect emotion from cues (expression model)
8. Export CSV reports

---

## 2) Architecture Map (What Runs Where)

Core runtime files:
- lib/modules/m1_face_detection.dart
- lib/modules/m2_face_embedding.dart
- lib/modules/m3_face_matching.dart
- lib/modules/m4_attendance_management.dart
- lib/modules/m5_liveness_detection.dart
- lib/modules/expression_cue_model.dart
- lib/modules/expression_cue_calibration.dart
- lib/screens/attendance_screen.dart
- lib/screens/enrollment_screen.dart
- lib/database/database_manager.dart

Data models used by algorithms:
- lib/models/face_detection_model.dart
- lib/models/embedding_model.dart
- lib/models/match_result_model.dart
- lib/models/attendance_model.dart
- lib/models/student_model.dart

---

## 3) Algorithm Formulas You Should Present

### 3.1 Euclidean Distance (face matching)
Given two embeddings a and b:

D(a,b) = sqrt(sum((a_i - b_i)^2))

Used in:
- lib/modules/m3_face_matching.dart
- lib/screens/attendance_screen.dart
- lib/database/database_manager.dart (similar-search helper)

### 3.2 Distance-to-Similarity Conversion
The app converts distance to similarity score:

S = 1 / (1 + D)

Properties:
- S in (0, 1]
- lower distance -> higher similarity

### 3.3 L2 Normalization (embedding quality)
For embedding vector v:

v_norm = v / ||v||, where ||v|| = sqrt(sum(v_i^2))

Used in lib/modules/m2_face_embedding.dart before matching.

### 3.4 Softmax For Emotion Probabilities
For score z_i and temperature T:

p_i = exp(z_i / T) / sum_j exp(z_j / T)

Used in lib/modules/expression_cue_model.dart.

### 3.5 Eye Aspect Ratio (liveness module)
EAR = (||p2-p6|| + ||p3-p5||) / (2 * ||p1-p4||)

Used in lib/modules/m5_liveness_detection.dart to detect blinks.

---

## 4) End-To-End Runtime Flow (Presentation Narrative)

### 4.1 Enrollment Flow
1. Enrollment screen opens camera
2. Detect face in captured image (ML Kit)
3. Enforce quality checks:
   - minimum face size
   - centered face
4. Crop face from full frame
5. Generate 128D normalized embedding
6. Repeat until required sample count (default 10)
7. Save student record + embeddings

### 4.2 Attendance Flow
1. Teacher and subject selected in prep screen
2. Attendance screen starts live stream scan every 400 ms
3. For each valid face:
   - crop
   - generate embedding
   - run KNN+verification matching
   - infer emotion (if model loaded)
4. Mark student present only if:
   - thresholds pass
   - candidate verification passes
   - consecutive detections pass
   - cooldown rule passes
5. Save attendance + teacher session
6. Export subject and cumulative CSV reports

---

## 5) Line-By-Line Explanation: M1 Face Detection

File: lib/modules/m1_face_detection.dart

### 5.1 Detector Initialization Block
Code block:

```dart
_faceDetector = GoogleMlKit.vision.faceDetector(
  FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
    enableLandmarks: true,
    enableTracking: false,
    minFaceSize: 0.1,
    performanceMode: FaceDetectorMode.fast,
  ),
);
```

Line explanation:
1. Create ML Kit face detector instance.
2. Begin option configuration object.
3. Turn on contour extraction (eye/lip/face outlines).
4. Turn on classifications (smile/eye-open probabilities).
5. Turn on facial landmark extraction.
6. Disable identity tracking across frames for simplicity/performance.
7. Ignore tiny faces smaller than 10% of frame.
8. Use fast mode for real-time mobile inference.
9. Close options object.
10. Close detector constructor.

### 5.2 Face + Mesh Fusion Block
Code block:

```dart
final faces = await _faceDetector!.processImage(inputImage);
List<mesh.FaceMesh> meshes = const [];
if (_meshEnabled && _faceMeshDetector != null) {
  meshes = await _faceMeshDetector!.processImage(inputImage);
}

return faces.map((face) {
  final matchedMesh = _matchMesh(face.boundingBox, meshes);
  return DetectedFace.fromMlKitFace(face, faceMesh: matchedMesh);
}).toList();
```

Line explanation:
1. Run face detector on input image.
2. Initialize empty mesh list.
3. Check if mesh feature is enabled and detector exists.
4. Run mesh detector on same image.
5. End mesh condition.
6. Convert each ML Kit face to app-level model.
7. For each face, find best overlapping mesh by IoU.
8. Create DetectedFace object with face and mesh data.
9. End map function.
10. Return converted list.

### 5.3 IoU Matching Logic
Code block:

```dart
final intersectionW = (right - left).clamp(0.0, double.infinity);
final intersectionH = (bottom - top).clamp(0.0, double.infinity);
final intersectionArea = intersectionW * intersectionH;

final unionArea = a.width * a.height + b.width * b.height - intersectionArea;
if (unionArea <= 0.0) return 0.0;
return intersectionArea / unionArea;
```

Line explanation:
1. Compute non-negative overlap width.
2. Compute non-negative overlap height.
3. Intersection area = width x height.
4. Union area = area(A) + area(B) - intersection.
5. Guard divide-by-zero and invalid geometry.
6. Return IoU score.

### 5.4 Embedding Suitability Gate
Code block:

```dart
final faceArea = rect.width * rect.height;
if (faceArea < 10000) return false;

if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 30) {
  return false;
}
if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 15) {
  return false;
}

return true;
```

Line explanation:
1. Compute face area in pixels.
2. Reject if face is too small for reliable embedding.
3. If yaw exists and too high, reject profile-like pose.
4. Return false for excessive yaw.
5. If roll exists and too high, reject tilted face.
6. Return false for excessive roll.
7. If checks pass, mark face suitable.

---

## 6) Line-By-Line Explanation: M2 Face Embedding

File: lib/modules/m2_face_embedding.dart

### 6.1 Interpreter Initialization
Code block:

```dart
final options = InterpreterOptions()..threads = 4;
_interpreter = await Interpreter.fromAsset(
  modelAssetPath,
  options: options,
);
_interpreter?.allocateTensors();
```

Line explanation:
1. Create TFLite interpreter options with 4 threads.
2. Load model from bundled asset path.
3. Pass options while constructing interpreter.
4. Close constructor call.
5. Allocate tensor memory up front.

### 6.2 Input Tensor Preprocessing
Code block:

```dart
final resized = img.copyResize(image, width: _inputWidth, height: _inputHeight);

final inputBuffer = Float32List(_inputWidth * _inputHeight * 3);
var index = 0;
for (var y = 0; y < _inputHeight; y++) {
  for (var x = 0; x < _inputWidth; x++) {
    final pixel = resized.getPixel(x, y);
    inputBuffer[index++] = pixel.r / 255.0;
    inputBuffer[index++] = pixel.g / 255.0;
    inputBuffer[index++] = pixel.b / 255.0;
  }
}
```

Line explanation:
1. Resize crop to model input size.
2. Allocate float buffer for RGB channels.
3. Track flat-array write index.
4. Loop over rows.
5. Loop over columns.
6. Read pixel.
7. Normalize red channel to [0,1] and store.
8. Normalize green channel to [0,1] and store.
9. Normalize blue channel to [0,1] and store.
10. End inner loop.
11. End outer loop.

### 6.3 Inference + Output Validation
Code block:

```dart
final inputData = inputBuffer.reshape([1, _inputHeight, _inputWidth, 3]);
final outputBuffer = List.generate(1, (_) => List.filled(outputLength, 0.0));
_interpreter!.run(inputData, outputBuffer);

List<double> embedding = (outputBuffer.first as List)
    .map((v) => (v as num).toDouble())
    .toList();

if (embedding.length != embeddingDimension) {
  throw Exception('Embedding dimension mismatch: expected $embeddingDimension, got ${embedding.length}');
}

return normalizeEmbedding(embedding);
```

Line explanation:
1. Reshape flat input into NHWC tensor format.
2. Prepare output tensor buffer.
3. Execute TFLite forward pass.
4. Convert output list elements to double.
5. Map each numeric value to double.
6. Build final list.
7. Validate output dimension is exactly 128.
8. Throw error if model output shape is wrong.
9. Return L2-normalized embedding.

---

## 7) Line-By-Line Explanation: M3 Face Matching

File: lib/modules/m3_face_matching.dart

### 7.1 Best Match Logic
Code block:

```dart
double bestDistance = double.infinity;
FaceEmbedding? bestMatch;

for (final dbEmbedding in databaseEmbeddings) {
  final dist = euclideanDistance(incomingEmbedding, dbEmbedding.vector);
  if (dist < bestDistance) {
    bestDistance = dist;
    bestMatch = dbEmbedding;
  }
}

final bestSimilarity = bestDistance.isFinite ? 1.0 / (1.0 + bestDistance) : 0.0;
```

Line explanation:
1. Start with worst possible distance.
2. Placeholder for winner embedding.
3. Iterate all stored embeddings.
4. Compute Euclidean distance to each.
5. If current distance is better, update winner.
6. Store new best distance.
7. Store new best embedding.
8. End if.
9. End loop.
10. Convert best distance into similarity.

### 7.2 Threshold Decision
Code block:

```dart
if (bestMatch != null && bestSimilarity >= similarityThreshold) {
  return MatchResult(
    identityType: 'known',
    studentId: bestMatch.studentId,
    similarity: bestSimilarity,
  );
}

return MatchResult(identityType: 'unknown', similarity: bestSimilarity);
```

Line explanation:
1. Confirm a candidate exists and passes threshold.
2. Return known identity result object.
3. Set identity type.
4. Store matched student id.
5. Store similarity score.
6. End object.
7. End if block.
8. Otherwise return unknown with diagnostic similarity.

---

## 8) Line-By-Line Explanation: Attendance Runtime Matcher

File: lib/screens/attendance_screen.dart
Function: _findMatchingStudent

This function is the most important anti-false-positive logic in the app.

### 8.1 Build Neighbor List
Code block:

```dart
for (final sample in _knnTrainingSet) {
  final dist = _euclideanDistance(embedding, sample.vector);
  if (!dist.isFinite) continue;
  final sim = 1.0 / (1.0 + dist);
  neighbors.add(_KnnNeighbor(studentId: sample.studentId, distance: dist, similarity: sim));
}
```

Line explanation:
1. Loop every stored sample embedding.
2. Compute distance query-vs-sample.
3. Skip invalid numeric values.
4. Convert distance to similarity.
5. Save neighbor metadata for ranking.

### 8.2 Top-K Selection
Code block:

```dart
neighbors.sort((a, b) => a.distance.compareTo(b.distance));
final k = neighbors.length < _knnK ? neighbors.length : _knnK;
final topK = neighbors.take(k).toList();
```

Line explanation:
1. Sort neighbors by nearest first.
2. Use k as min(total_neighbors, configured_k).
3. Slice first k nearest entries.

### 8.3 Weighted Voting
Code block:

```dart
final weight = 1.0 / (dist + 1e-6);
voteWeights[sid] = (voteWeights[sid] ?? 0.0) + weight;
voteCounts[sid] = (voteCounts[sid] ?? 0) + 1;

final currentBest = bestPerStudentSim[sid] ?? 0.0;
if (sim > currentBest) {
  bestPerStudentSim[sid] = sim;
}
```

Line explanation:
1. Convert distance to vote weight; closer means stronger vote.
2. Accumulate weighted evidence per student.
3. Track how many top-k votes each student got.
4. Read best similarity currently seen for this student.
5. If current sample similarity is better,
6. update best per-student similarity.

### 8.4 Ranked Candidate Selection
Code block:

```dart
final ranked = voteWeights.entries.toList()
  ..sort((a, b) {
    final byWeight = b.value.compareTo(a.value);
    if (byWeight != 0) return byWeight;

    final c1 = voteCounts[a.key] ?? 0;
    final c2 = voteCounts[b.key] ?? 0;
    final byCount = c2.compareTo(c1);
    if (byCount != 0) return byCount;

    final s1 = bestPerStudentSim[a.key] ?? 0.0;
    final s2 = bestPerStudentSim[b.key] ?? 0.0;
    return s2.compareTo(s1);
  });
```

Line explanation:
1. Convert weight map into sortable list.
2. Sort with custom comparator.
3. Primary key: higher total vote weight wins.
4. If tie, continue to next criterion.
5. Secondary key: higher vote count wins.
6. If still tie, continue.
7. Tertiary key: better best similarity wins.
8. Return final order.

### 8.5 Effective Threshold Conversion
Code block:

```dart
final effectiveThreshold = _effectiveEuclideanSimilarityThreshold(_similarityThreshold);
```

Explanation:
1. Convert slider threshold (historically cosine tuned) to Euclidean-sim scale.

Helper function logic:

```dart
final cos = sliderThreshold.clamp(0.0, 0.999).toDouble();
final d = sqrt((2.0 - (2.0 * cos)).clamp(0.0, double.infinity));
return 1.0 / (1.0 + d);
```

Line explanation:
1. Bound cosine-like slider value safely.
2. Convert cosine relation to Euclidean distance on normalized vectors.
3. Convert that distance to app similarity scale.

### 8.6 Stage-2 Candidate Verification
Code block:

```dart
for (final saved in candidateEmbeddings) {
  final dist = _euclideanDistance(embedding, saved);
  if (!dist.isFinite) continue;
  final sim = 1.0 / (1.0 + dist);
  verificationScores.add(sim);
  if (sim > verificationBest) verificationBest = sim;
}
```

Line explanation:
1. Compare query only against winner candidate templates.
2. Compute pair distance.
3. Skip invalid values.
4. Convert to similarity.
5. Store score for statistics.
6. Track best candidate-specific similarity.

### 8.7 Support Count Guard
Code block:

```dart
final minSupport = candidateEmbeddings.length >= 8
    ? 3
    : candidateEmbeddings.length >= 5
        ? 2
        : 1;
if (verificationSupport < minSupport) {
  return null;
}
```

Line explanation:
1. Decide required support based on number of stored templates.
2. If many templates exist, require stronger agreement.
3. Reject candidate if enough templates do not support the match.

### 8.8 Ambiguity Rejection
Code block:

```dart
if (!isStrongMatch && ranked.length > 1 && margin < requiredMargin) {
  return null;
}
```

Line explanation:
1. If this is not an obviously strong match,
2. and there is a second candidate,
3. and similarity margin is too small,
4. reject as ambiguous to avoid false positive attendance.

### 8.9 Final Output
If all guards pass, return best student object; else return null (unknown).

---

## 9) Line-By-Line Explanation: Expression Cue Model

File: lib/modules/expression_cue_model.dart
Function: predict

### 9.1 Feature Extraction
Code block:

```dart
final smile = _clamp01(face.smilingProbability ?? 0.0);
final leftEye = _clamp01(face.leftEyeOpenProbability ?? 0.5);
final rightEye = _clamp01(face.rightEyeOpenProbability ?? 0.5);
final eyeOpen = ((leftEye + rightEye) / 2.0).clamp(0.0, 1.0).toDouble();
```

Line explanation:
1. Read smile probability with fallback.
2. Read left-eye openness with neutral fallback.
3. Read right-eye openness with neutral fallback.
4. Average eye openness into one normalized cue.

### 9.2 Rule-Based Cue Scores
Code block:

```dart
final smileCue = _clamp01((smile * calibration.happySmileWeight) + (mouthWidth * calibration.happyMouthWeight));
final surpriseCue = _clamp01((mouthOpen * calibration.surpriseMouthWeight) + (eyeOpen * calibration.surpriseEyeWeight) + ((1.0 - smile) * calibration.surpriseSmilePenalty));
final neutralCue = _clamp01(((1.0 - smile) * calibration.neutralSmilePenalty) + ((1.0 - mouthOpen) * calibration.neutralMouthPenalty) + ((_centerPenalty(eyeOpen, 0.55) * calibration.neutralEyeReward)));
```

Line explanation:
1. Happy score combines smile and mouth-width effects.
2. Surprise score emphasizes mouth-open + eye-open with anti-smile penalty.
3. Neutral score favors low smile, low mouth-open, and mid-range eye-open.

### 9.3 Strong Override Rules
Code block:

```dart
if (smile >= calibration.happySmileThreshold && mouthOpen <= calibration.happyMouthOpenMax) {
  scores['Happy'] = math.max(scores['Happy']!, 0.94);
  scores['Surprise'] = scores['Surprise']! * 0.35;
}
```

Line explanation:
1. Detect very strong happy pattern.
2. Force happy confidence floor.
3. Suppress surprise confusion.

Equivalent override blocks exist for Surprise, Disgust, and Neutral.

### 9.4 Probabilistic Normalization
Code block:

```dart
final normalized = _softmax(scores, temperature: calibration.softmaxTemperature);
var best = normalized.entries.reduce((a, b) => a.value >= b.value ? a : b);
```

Line explanation:
1. Convert raw scores into probability distribution.
2. Select label with maximum probability.

### 9.5 Post-Decision Corrections
The model applies final safety corrections, for example:
- if Neutral is close to winner, choose Neutral
- if Surprise is weak and smile is high, switch to Happy

This reduces unstable label flips.

---

## 10) Line-By-Line Explanation: M4 Attendance Management

File: lib/modules/m4_attendance_management.dart

### 10.1 Duplicate Prevention
Code block:

```dart
final existing = await dbManager.getAttendanceForDate(date);
final alreadyMarked = existing.any((rec) => rec.studentId == studentId);
if (alreadyMarked) {
  return false;
}
```

Line explanation:
1. Load all attendance records for the date.
2. Check if target student already has a record.
3. If yes, reject duplicate mark.

### 10.2 Export Matrix Build
Code block:

```dart
lookup.putIfAbsent(record.studentId, () => {});
lookup[record.studentId]![dateKey] =
    record.status == AttendanceStatus.present ? '1' : '0';
```

Line explanation:
1. Ensure student row map exists.
2. Fill date cell with present=1 else 0.

This creates a date x student matrix for CSV.

---

## 11) Line-By-Line Explanation: M5 Liveness Detection

File: lib/modules/m5_liveness_detection.dart

### 11.1 EAR Sequence Construction
Code block:

```dart
final earValues = <double>[];
for (final face in faceSequence) {
  final ear = _calculateEyeAspectRatio(face);
  if (ear != null) {
    earValues.add(ear);
  }
}
```

Line explanation:
1. Create list of EAR values.
2. Iterate over temporal face sequence.
3. Compute EAR for frame.
4. If valid, append to signal list.

### 11.2 Blink Pattern Detection
Code block:

```dart
for (var i = 1; i < earValues.length - 1; i++) {
  if (earValues[i] < blinkThreshold &&
      earValues[i] < earValues[i - 1] &&
      earValues[i] < earValues[i + 1]) {
    blinkPoints.add(i);
  }
}

return blinkPoints.length >= requiredBlinks;
```

Line explanation:
1. Scan EAR signal interior points.
2. Check threshold drop.
3. Ensure local-minimum shape.
4. Mark blink point index.
5. End loop.
6. Confirm required number of blinks.

Note: module exists but is not currently wired into main attendance decision path.

---

## 12) Local Data Layer Explanation (DatabaseManager)

File: lib/database/database_manager.dart

Key design:
- SharedPreferences stores lists of JSON strings.
- IDs are generated by max(existing_ids) + 1.
- Attendance queries deduplicate records by date and student.
- For same day, latest recordedAt wins.

This is simple and offline-friendly, but less scalable than SQL for large datasets.

---

## 13) Thresholds and Important Constants

Recognition and scanning:
- stream interval: 400 ms (attendance screen)
- similarity slider baseline: 0.75
- K in local KNN: 5
- required consecutive detections: 2 (single-face mode)
- cooldown per student mark: 1 second

Enrollment quality:
- minimum enrollment face size: 150 x 150 px
- embedding dimension: 128

Face detection:
- minimum detector face size: 0.1 frame fraction
- frontal checks: yaw <= 30, roll <= 15 for suitability helper

Expression:
- calibration loaded from assets/models/expression_cue_calibration.json
- fallback defaults used if file read fails

Liveness module defaults:
- blink threshold: 0.3
- required blinks: 2

---

## 14) Viva Questions and Strong Answers

Q1. Why Euclidean distance and not cosine in final runtime?
Answer: Embeddings are L2-normalized; Euclidean works well and gives stable nearest-neighbor behavior. The app also uses a distance-to-similarity mapping for thresholding consistency.

Q2. How do you reduce false positives?
Answer: The attendance matcher uses layered guards: top-k weighted voting, per-candidate verification against own templates, support-count checks, top-average checks, ambiguity margin rejection, and consecutive-frame confirmation.

Q3. Why singleton modules?
Answer: ML Kit detectors and TFLite interpreters are heavy native objects. Singletons avoid repeated allocation and reduce memory pressure during repeated screen transitions.

Q4. Is liveness active in attendance now?
Answer: A blink-based liveness module is implemented (M5), but current attendance runtime does not enforce it yet.

Q5. Is the app online or offline?
Answer: It is offline-first. Recognition and attendance storage run locally using SharedPreferences.

---

## 15) Suggested Slide Deck Structure

1. Problem Statement
2. System Architecture
3. Face Detection (M1)
4. Embedding Generation (M2)
5. Matching + Verification (M3 + attendance matcher)
6. Attendance Logic and Duplicate Prevention (M4)
7. Emotion Cue Model
8. Liveness Module (current status and future integration)
9. Data Storage and Export Pipeline
10. Results, Limitations, and Future Work

---

## 16) Future Improvements You Can Mention

1. Replace SharedPreferences with SQLite/Drift for large-scale datasets.
2. Add ANN indexing for faster retrieval with many embeddings.
3. Integrate M5 liveness directly into attendance decision gate.
4. Add adaptive per-student thresholding from historical variance.
5. Persist calibrated confidence histograms for automatic threshold tuning.

---

## 17) Presentation Closing Statement

This project combines practical mobile engineering and applied machine learning.
Its key strength is not just face matching, but conservative multi-stage verification that prioritizes attendance integrity in real classroom conditions.
