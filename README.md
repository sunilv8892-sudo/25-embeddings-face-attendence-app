# FAS - Face Recognition Attendance System

This repository contains the current production architecture of the FAS app:

- Flutter mobile application
- ML Kit face detection (MediaPipe-backed)
- FaceNet-128 embedding generation with TFLite
- KNN-style matching with Euclidean distance
- SharedPreferences-backed local persistence
- Offline attendance marking, emotion tagging, and CSV export

## Documentation Entry Points

1. [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
2. [FACE_RECOGNITION_CODEBOOK.md](FACE_RECOGNITION_CODEBOOK.md)

Use the index for quick navigation. Use the codebook for deep implementation details.

## Quick Runtime Overview

1. Enroll students and collect multiple face samples.
2. Generate and store 128-dimensional embeddings per student.
3. Start attendance session (teacher + subject).
4. Run live camera scan, detect faces, generate embeddings, perform KNN matching.
5. Confirm with consecutive detections and write attendance + emotion to local storage.
6. View stats/dashboard and export CSV/JSON reports.

## Source Of Truth

This README and the codebook are the authoritative docs for the active code in `lib/`.
Legacy historical migration/refactoring markdown files were intentionally removed to avoid conflicting guidance.