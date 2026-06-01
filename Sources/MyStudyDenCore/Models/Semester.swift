import Foundation

public struct Semester: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var title: String
    public var startDate: Date?
    public var endDate: Date?
    public var courses: [Course]

    public init(
        id: EntityID = EntityID(),
        title: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        courses: [Course] = []
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.courses = courses
    }
}

