# Architecture

## Layers

```text
SwiftUI App
  - iPhone: TabView + NavigationStack
  - iPad: NavigationSplitView

Application State
  - Dashboard view models
  - Capture flow view models

Core
  - Semester, Course, StudySource, StudyPacket
  - LearningState, TaskItem, ReviewQuestion
  - AIProvider protocol
  - MockAIProvider

Persistence
  - v0 prototype: in-memory seed data
  - v0 app: SwiftData local store
  - later: CloudKit or backend sync
```

## AI Strategy

Start with `MockAIProvider` so the product loop can be tested before provider cost, API keys, retry logic, and privacy concerns enter the design.

Later providers should implement:

```swift
public protocol AIProvider {
    func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft
    func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft
    func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String
}
```

## Device Strategy

v0 should be a universal iPhone + iPad app.

- iPhone: fast capture, course check-ins, review queue.
- iPad: dashboard scanning, packet reading, source organization.
- Mac later: Catalyst or native macOS after the iPad layout feels solid.

