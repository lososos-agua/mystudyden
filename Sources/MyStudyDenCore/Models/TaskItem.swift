import Foundation

public enum TaskKind: String, CaseIterable, Codable, Sendable {
    case reading
    case assignment
    case exam
    case review
    case askProfessorOrTA
}

public struct TaskItem: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var courseID: EntityID
    public var title: String
    public var kind: TaskKind
    public var dueDate: Date?
    public var isComplete: Bool

    public init(
        id: EntityID = EntityID(),
        courseID: EntityID,
        title: String,
        kind: TaskKind,
        dueDate: Date? = nil,
        isComplete: Bool = false
    ) {
        self.id = id
        self.courseID = courseID
        self.title = title
        self.kind = kind
        self.dueDate = dueDate
        self.isComplete = isComplete
    }
}

