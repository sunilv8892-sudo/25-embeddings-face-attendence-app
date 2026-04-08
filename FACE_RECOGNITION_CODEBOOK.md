# FAS Codebook

This document is the deep, implementation-level guide for the current codebase.
It is written for maintainers who need to understand exactly how the running app works,
why specific decisions were made, and where to change behavior safely.

Scope of this codebook:

- Current production architecture only.
- Behavior implemented in the existing `lib/` source tree.
- File responsibilities and runtime flow.
- Requirements, constraints, trade-offs, and known issues.

Out of scope:

- Historical legacy detection architectures that are no longer active.
- Deprecated migration plans that are no longer active in code.

---

## 1. System Snapshot

### 1.1 What the app does

FAS is an offline mobile attendance app that uses face recognition for marking student presence.
The app can:

1. Enroll students with profile details and multiple face samples.
2. Convert cropped face images into 128D embeddings.
3. Match live camera embeddings against stored embeddings using KNN-style nearest-neighbor logic.
4. Mark attendance with duplicate prevention and multi-step confidence gates.
5. Tag attendance with emotion labels from a cue-based expression model.
6. Export attendance and embedding reports to CSV/JSON.
7. Backup and restore the local datastore.

### 1.2 Core technology stack

- Flutter + Dart
- Camera plugin (`camera`)
- Face detection: Google ML Kit (`google_ml_kit`) + optional face mesh (`google_mlkit_face_mesh_detection`)
- Face embeddings: TFLite (`tflite_flutter`) using `assets/models/embedding_model.tflite`
- Local persistence: `shared_preferences`
- Speech feedback: `flutter_tts`
- Export/share: `share_plus`, platform channel, local file IO

### 1.3 Active app identity

Defined in `lib/utils/constants.dart`:

- App name: `FAS`
- App version constant: `18.4.0`
- Route root: `/`

Android label (`android/app/src/main/AndroidManifest.xml`) is also set to `FAS`.

---

## 2. Requirements and Runtime Preconditions

### 2.1 Development/runtime requirements

- Dart SDK compatible with `^3.10.7` (from `pubspec.yaml`)
- Flutter environment with platform setup for Android/iOS
- Camera hardware access
- Bundled model assets in `assets/models/`

### 2.2 Required permissions

Android manifest includes:

- `android.permission.CAMERA`
- `android.permission.READ_EXTERNAL_STORAGE`
- `android.permission.WRITE_EXTERNAL_STORAGE`

At runtime, camera permission is requested in enrollment/attendance/expression screens.

### 2.3 Required model assets

Used directly by app code:

1. `assets/models/embedding_model.tflite`
2. `assets/models/expression_cue_calibration.json`

Notes:

- `assets/models/lda.pkl`, `assets/models/scaler.pkl`, and `assets/models/svm.pkl` are present but not loaded by the active Flutter runtime.
- `models/README.md` discusses additional training artifacts for reproducibility.

---

## 3. High-Level Architecture

### 3.1 Layered structure

1. UI layer (`lib/screens/`, `lib/widgets/`)
2. Domain/model layer (`lib/models/`)
3. ML modules (`lib/modules/`)
4. Persistence layer (`lib/database/database_manager.dart`)
5. Cross-cutting utilities (`lib/utils/`)

### 3.2 Bootstrapping

`lib/main.dart` initializes `DatabaseManager` before `runApp`, then mounts `MaterialApp` with route table.

Active routes:

- `/` -> `HomeDashboardScreen`
- `/enroll` -> `EnrollmentScreen`
- `/attendance` -> `AttendancePrepScreen`
- `/database` -> `DatabaseScreen`
- `/export` -> `ExportScreen`
- `/settings` -> `SettingsScreen`
- `/expression_detection` -> `ExpressionDetectionScreen`

### 3.3 Design intent

- Offline-first: no backend dependency for normal operation.
- Predictable local state: JSON-like records in SharedPreferences.
- Modular ML pipeline: detection, embedding, matching, attendance management, liveness, and expression are separated into modules.
- Mobile UX priority: quick startup, camera-first workflows, and immediate feedback.

---

## 4. Repository and File Responsibilities

### 4.1 Current responsibility map

```
lib/
  main.dart                         # App entry point and route map
  database/
    database_manager.dart           # Active persistence gateway (SharedPreferences)
    database_connection.dart        # Drift/SQLite helper (currently not active in runtime)
    face_recognition_database.dart  # Deprecated placeholder, intentionally unused
  models/
    student_model.dart              # Student identity/profile schema
    embedding_model.dart            # Face embedding schema (vector + metadata)
    attendance_model.dart           # Attendance record schema and enums
    subject_model.dart              # Subject + teacher-session schema
    face_detection_model.dart       # Face detection DTO used by camera flows
    match_result_model.dart         # Matching result DTO
  modules/
    m1_face_detection.dart          # ML Kit face detection + mesh + ROI utilities
    m2_face_embedding.dart          # TFLite FaceNet-128 inference
    m3_face_matching.dart           # Generic Euclidean matcher (module-level)
    m4_attendance_management.dart   # Reporting/statistics/export helper logic
    m5_liveness_detection.dart      # Blink-based liveness checks
    expression_cue_model.dart       # Cue-based expression inference
    expression_cue_calibration.dart # Calibration load/defaults for expression model
  screens/
    home_dashboard_screen.dart      # Main dashboard and feature navigation
    enrollment_screen.dart          # Student registration + sample capture
    attendance_prep_screen.dart     # Teacher/subject setup for attendance session
    attendance_screen.dart          # Live recognition and attendance marking
    database_screen.dart            # Analytics and enrolled-student views
    export_screen.dart              # Attendance/embedding export and file management
    settings_screen.dart            # Preferences, backup/restore, credits, stats
    expression_detection_screen.dart# Standalone expression detection tool
    home_screen.dart                # Legacy screen (not in active route table)
  utils/
    constants.dart                  # Branding, theme, dimensions, route constants
    app_route_observer.dart         # Route observer singleton
    export_utils.dart               # Shared export directory resolver
    csv_export_service.dart         # Alternate CSV service (partially legacy path)
    theme.dart                      # Older alternate theme (not used by main app)
  widgets/
    animated_background.dart        # Shared visual background wrapper
```

### 4.2 Files that are present but not primary runtime path

1. `lib/database/face_recognition_database.dart`
   - Explicitly documented as deprecated.
2. `lib/utils/theme.dart`
   - Contains an alternate light theme system, but app uses `AppTheme` in `lib/utils/constants.dart`.
3. `lib/screens/home_screen.dart`
   - Legacy home screen, not referenced in route map.
4. `lib/database/database_connection.dart`
   - Drift helper, retained but not used by active storage implementation.

These files are useful for historical context but should not be treated as active architecture.

---

## 5. Persistence and Data Schema

### 5.1 Storage strategy

The active datastore is `SharedPreferences` with JSON-encoded records.
`DatabaseManager` centralizes all read/write logic and acts as the application persistence API.

### 5.2 SharedPreferences keys

- `students` -> list of serialized student records
- `embeddings` -> list of serialized embeddings
- `attendance` -> list of serialized attendance rows
- `subjects` -> list of serialized subject rows
- `teacherSessions` -> list of serialized teacher session rows
- `tts_enabled` -> boolean preference

### 5.3 Record schemas

Student fields:

- `id`
- `name`
- `roll_number`
- `class`
- `gender`
- `age`
- `phone_number`
- `enrollment_date`

Embedding fields:

- `id`
- `studentId`
- `vector` (128D)
- `captureDate`

Attendance fields:

- `id`
- `studentId`
- `date`
- `time`
- `status` (`present`, `absent`, `late`)
- `recordedAt`
- `emotion`

Subject fields:

- `id`
- `name`
- `createdAt`

Teacher session fields:

- `id`
- `teacherName`
- `subjectId`
- `subjectName`
- `date`
- `createdAt`

### 5.4 Data integrity behavior

`DatabaseManager` includes runtime protections:

1. ID generation by max+1 for student/embedding/attendance inserts.
2. Date-based deduplication for attendance views, keeping latest `recordedAt` per student/day.
3. Helper methods for class/session filtering.

Trade-off:

- This model is simpler than relational SQL and avoids codegen friction.
- It is less ideal for large-scale querying or strict transactional guarantees.

---

## 6. ML Pipeline Modules

### 6.1 M1 - Face detection (`m1_face_detection.dart`)

Primary responsibilities:

1. Initialize ML Kit face detector.
2. Optionally initialize face mesh detector.
3. Detect faces from image path/bytes.
4. Convert ML Kit output into local `DetectedFace` model.
5. Support ROI extraction and quality checks.

Key parameters:

- `minFaceSize: 0.1`
- `performanceMode: fast`
- `minDetectionConfidence` constant exists at `0.5`

Quality gating:

- Reject very small faces (`faceArea < 10000`) for embedding suitability.
- Reject extreme yaw/roll ranges for enrollment quality.

Pattern:

- Implemented as singleton to prevent repeated heavy detector allocation.

### 6.2 M2 - Face embedding (`m2_face_embedding.dart`)

Primary responsibilities:

1. Load `assets/models/embedding_model.tflite` once.
2. Read tensor shapes dynamically.
3. Resize face ROI to model input dimensions.
4. Produce 128D embedding vector.
5. Apply L2 normalization.

Key details:

- Declared model: `FaceNet-128`
- Threads: 4
- Validates output dimensionality against expected 128
- Returns normalized embeddings for downstream KNN matching

### 6.3 M3 - Generic matching (`m3_face_matching.dart`)

Primary responsibilities:

1. Compute Euclidean distance between vectors.
2. Convert distance to similarity: `1 / (1 + distance)`.
3. Return best match or unknown based on threshold.

Notes:

- Module default threshold is `0.60`.
- Attendance screen has additional custom matching guards beyond this module.

### 6.4 M4 - Attendance management (`m4_attendance_management.dart`)

Primary responsibilities:

1. Record attendance while preventing same-day duplicates.
2. Produce attendance stats and reports.
3. Export attendance and embedding CSV outputs.

### 6.5 M5 - Liveness (`m5_liveness_detection.dart`)

Primary responsibilities:

1. Blink-based liveness estimation using Eye Aspect Ratio.
2. Detect blink pattern in temporal EAR sequence.

Key parameters:

- `blinkThreshold = 0.3`
- `requiredBlinks = 2`
- `blinkTimeout = 10 seconds`

### 6.6 Expression cue model (`expression_cue_model.dart`)

Primary responsibilities:

1. Load calibration from `expression_cue_calibration.json`.
2. Compute emotion scores using face probabilities and landmark-derived cues.
3. Apply heuristic overrides and normalization.
4. Return label + confidence + probability map.

Classes used by app flows:

- Attendance screen for emotion tagging at mark time
- Expression detection screen for standalone real-time analysis

---

## 7. Screen-by-Screen Behavior

### 7.1 Home dashboard (`home_dashboard_screen.dart`)

Responsibilities:

1. Show top-level stats: total students, present today, sessions.
2. Provide feature navigation cards.
3. Refresh stats on route return via `RouteAware`.

Details:

- Uses fixed percentage-based vertical layout sections.
- Calculates sessions using teacher sessions, with fallback logic when attendance exists but no explicit teacher session row.

### 7.2 Enrollment (`enrollment_screen.dart`)

Responsibilities:

1. Collect student metadata.
2. Capture multiple face samples from camera.
3. Run detection + quality checks + embedding generation.
4. Save student and embeddings.

Important quality guards:

- Minimum detected face dimensions (~150x150) for enrollment sample acceptance.
- Centering checks to reduce poor-angle captures.
- Required sample target driven by constants (`requiredEnrollmentSamples = 10`).

### 7.3 Attendance setup (`attendance_prep_screen.dart`)

Responsibilities:

1. Capture teacher name.
2. Select or create subject.
3. Transition into live attendance session with validated setup state.

### 7.4 Attendance runtime (`attendance_screen.dart`)

This is the core runtime surface.

Responsibilities:

1. Initialize camera stream and modules.
2. Detect faces from live frames.
3. Generate embeddings per detected face.
4. Match via KNN-like weighted voting and multi-stage verification.
5. Enforce consecutive detections before final mark.
6. Track and display overlays (name, status, emotion).
7. Persist attendance and session records.
8. Trigger TTS confirmation (if enabled).

Key runtime constants in this screen:

- Stream scan interval: `400ms`
- Similarity slider baseline: `0.75`
- K for local KNN voting: `5`
- Required consecutive detections: `2`
- Detection cooldown: `1 second`

Matching strategy in attendance runtime:

1. Build neighbor list from all enrollment embeddings.
2. Rank by Euclidean distance.
3. Weighted vote + count + best-sim tie-break.
4. Convert slider threshold into effective Euclidean-sim threshold.
5. Reject insufficient votes.
6. Stage-2 candidate verification against candidate's own templates.
7. Enforce minimum support counts and top-average strength.
8. Ambiguity rejection using margin against second-best candidate.

This layered gating is the main false-positive defense.

Persistence on submit:

- Writes attendance rows to `attendance` key.
- Writes teacher session to `teacherSessions`.
- Stores session payload keyed by teacher+subject+date in SharedPreferences.

### 7.5 Database dashboard (`database_screen.dart`)

Responsibilities:

1. Overview tab for system stats.
2. Attendance history grouped by date.
3. Per-student attendance summary.
4. Enrolled-students tab with attendance metrics.

### 7.6 Export (`export_screen.dart`)

Responsibilities:

1. Export attendance register CSV.
2. Export embeddings CSV.
3. Load, view, share, and delete saved export files.
4. Save to app export directory and attempt Android downloads save via method channel.

Directory source of truth:

- `getExportDirectory()` from `lib/utils/export_utils.dart`

### 7.7 Settings (`settings_screen.dart`)

Responsibilities:

1. Toggle TTS preference (`tts_enabled`).
2. Show datastore counts and approximate data size.
3. Backup all main lists to JSON.
4. Restore from backup file (replace mode).
5. Merge from backup file (additive mode).
6. Credits and about details.

### 7.8 Expression detection (`expression_detection_screen.dart`)

Responsibilities:

1. Standalone expression analysis workflow.
2. Continuous camera stream processing with warmup and stabilization.
3. Overlay rendering and expression timeline log.

Stabilization controls:

- Temporal window and confidence/margin gates.
- Min log interval and stable hold timers.

---

## 8. End-to-End Runtime Flows

### 8.1 Enrollment flow

1. User opens enrollment screen.
2. Student profile data entered.
3. Camera captures frames.
4. ML Kit detects best face.
5. Quality checks run (size/centering).
6. Face ROI passed to FaceNet module.
7. 128D normalized embedding stored in memory list.
8. After enough samples, student + embeddings persisted.

### 8.2 Attendance flow

1. User enters teacher + subject in prep screen.
2. Attendance screen starts live scanning.
3. Every interval, frame processed for faces.
4. For each valid face:
   - create embedding
   - run KNN+verification
   - derive emotion
5. If same student is confirmed for required consecutive detections:
   - mark present in local state
   - show overlay and optional TTS feedback
6. On submit:
   - write attendance rows
   - write teacher session
   - generate/export reports

### 8.3 Export/reporting flow

1. Export screen initializes `AttendanceManagementModule`.
2. User triggers attendance or embedding export.
3. CSV file generated and saved under `FaceAttendanceExports`.
4. App can share file via OS share sheet.

---

## 9. Thresholds, Defaults, and Tuning

### 9.1 Recognition-related values

- Global constant similarity threshold: `0.75` (`constants.dart`)
- Attendance screen working threshold baseline: `0.75`
- Attendance internal KNN vote size: `5`
- Attendance required consecutive detections: `2`
- Attendance stream scan period: `400ms`

### 9.2 Liveness values

- EAR blink threshold: `0.3`
- Required blinks: `2`
- Blink timeout window: `10s`

### 9.3 Expression calibration defaults

From `expression_cue_calibration.dart`:

- Happy smile threshold: `0.58`
- Surprise mouth-open minimum: `0.09`
- Neutral eye-open minimum: `0.35`
- Softmax temperature: `0.75`

These can be changed by updating `assets/models/expression_cue_calibration.json`.

---

## 10. Key Design Rationale

### 10.1 Why SharedPreferences over SQL in current build

1. Simpler deployment and maintenance.
2. Avoids drift/codegen migration friction.
3. Suitable for moderate local data volumes in mobile attendance context.

Trade-off:

- Lower query sophistication compared with proper relational DB.

### 10.2 Why singleton heavy modules

ML Kit detectors and TFLite interpreters are expensive native objects.
Singleton lifecycle reduces repeated allocation and helps avoid memory pressure during rapid navigation.

### 10.3 Why layered match verification

Simple nearest-neighbor alone can create false positives in near-look-alike cases.
Attendance screen adds:

1. vote support checks,
2. effective threshold conversion,
3. candidate-only verification support,
4. top-average strength checks,
5. ambiguity margin checks,
6. consecutive frame confirmation.

This is intentionally conservative for attendance integrity.

---

## 11. Known Issues and Maintenance Risks

### 11.1 Drift artifacts still present

Risk:

- `drift` dependencies and helper files remain while runtime uses SharedPreferences.

Impact:

- Potential confusion for new maintainers.

Mitigation:

- Keep this codebook and index explicit about active persistence path.
- If drift is truly retired, remove related packages/files in a dedicated cleanup PR.

### 11.2 Legacy/unrouted screen still in tree

Risk:

- `home_screen.dart` may be edited accidentally even though app starts at `home_dashboard_screen.dart`.

Mitigation:

- Treat route table in `main.dart` as canonical.

### 11.3 Export path behavior differs across platforms

Risk:

- Android external storage and media-store behavior can vary by device/OS.

Mitigation:

- Continue using `getExportDirectory()` as source of truth.
- Keep fallback to app documents directory.

### 11.4 Emotion assets mismatch confusion

Risk:

- Repository includes training artifacts (`.pkl`) that are not directly loaded by app runtime.

Mitigation:

- Keep `models/README.md` and this codebook clear on which assets are runtime-critical.

### 11.5 Performance under high enrollment sizes

Risk:

- Matching cost grows with total stored embeddings.

Mitigation:

- Use embedding-quality enrollment and duplicate control.
- Consider indexing or vector DB strategy if data scale grows significantly.

---

## 12. How To Change This System Safely

### 12.1 Changing recognition behavior

Prefer changing in this order:

1. Attendance screen thresholds/gates for runtime behavior.
2. `m3_face_matching.dart` if generic matcher logic must evolve.
3. Constants for shared defaults.

Always validate with:

- known students,
- unknown faces,
- similar-looking subjects,
- low-light conditions.

### 12.2 Changing expression behavior

1. Adjust calibration JSON values first.
2. Only edit cue-model formulas if calibration is insufficient.
3. Validate both attendance and standalone expression screens.

### 12.3 Changing storage schema

1. Update model serializers.
2. Update `DatabaseManager` read/write paths.
3. Update backup/restore merge logic.
4. Add one-time migration logic if old keys/fields are impacted.

---

## 13. Verification Checklist For Maintainers

Before release:

1. App launches and routes correctly from `/`.
2. Enrollment captures at least 10 valid samples.
3. Attendance marks known users and rejects unknown users.
4. Attendance submission creates both attendance rows and teacher session rows.
5. Export screen writes and shares CSV files.
6. Settings backup + restore succeeds on real data.
7. Expression detection screen runs and overlays labels without crash.
8. No stale doc links exist in `README.md` or `DOCUMENTATION_INDEX.md`.

---

## 14. Final Notes

This document intentionally prioritizes code-accurate behavior over historical narrative.
If you make architectural changes, update this codebook in the same PR.
Keeping documentation synchronized with code is mandatory for this repository to remain maintainable.
