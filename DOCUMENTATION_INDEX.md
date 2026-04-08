## FAS Documentation Index (Authoritative)

This index points to the maintained, code-accurate documentation for the current implementation.

## Primary Documents

1. [README.md](README.md)
- Short project overview
- High-level runtime flow
- Links to deep documentation

2. [FACE_RECOGNITION_CODEBOOK.md](FACE_RECOGNITION_CODEBOOK.md)
- Full architecture and design rationale
- File and module responsibilities
- End-to-end runtime behavior
- Data schema, thresholds, and tuning notes
- Known issues and mitigations

## Supporting Documents

1. [models/README.md](models/README.md)
- Notes for generated training artifacts and how they relate to app assets

2. [ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md)
- iOS launch image customization instructions

## Documentation Policy

- If behavior in docs conflicts with code, code is the source of truth.
- Keep documentation aligned with active routes in `lib/main.dart`.
- Do not reintroduce historical migration summaries as separate root markdown files.
- Update this index when adding or removing maintained docs.
