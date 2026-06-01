# MyStudyDen

MyStudyDen is a local-first study workspace for students. It turns scattered course materials into weekly study packets, concepts, questions, tasks, and review paths for each class.

## Product Boundary

MyStudyDen is not a Canvas replacement, a free-form Notion clone, or a full AI chat tutor in v0. It is a course and semester operating layer:

```text
StudySource -> StudyPacket -> Course Dashboard -> Semester Dashboard
```

## v0 Direction

- Platform: universal iPhone + iPad SwiftUI app
- Storage: local-first, SwiftData later in the app target
- AI: mock provider first, real provider behind an `AIProvider` abstraction later
- Core unit: `StudyPacket`
- Differentiator: learning state layered over course materials

## Repository Layout

```text
MyStudyDen/
  MyStudyDen.xcodeproj       iPhone/iPad SwiftUI app project
  Sources/MyStudyDenCore/    Shared domain models and AI pipeline
  Tests/MyStudyDenCoreTests/ Core tests
  App/MyStudyDenApp/         SwiftUI app skeleton for iPhone/iPad
  Docs/                      Product and architecture notes
```

## Tooling

Core package builds with SwiftPM:

```sh
swift build
```

Running the iPhone/iPad app requires full Xcode, not Command Line Tools only. See `Docs/XCODE_SETUP.md`.

## First Milestone

Build a local prototype that can:

1. Create a semester and courses.
2. Add pasted text or notes as study sources.
3. Generate a mock study packet.
4. Show course and semester dashboards.
5. Copy an AI tutor handoff prompt for an external AI app.
