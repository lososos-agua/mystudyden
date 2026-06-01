import Foundation

public struct Course: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var semesterID: EntityID?
    public var title: String
    public var courseCode: String?
    public var instructor: String?
    public var colorName: String
    public var personalGoal: String?
    public var createdAt: Date

    public init(
        id: EntityID = EntityID(),
        semesterID: EntityID? = nil,
        title: String,
        courseCode: String? = nil,
        instructor: String? = nil,
        colorName: String = "blue",
        personalGoal: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.semesterID = semesterID
        self.title = title
        self.courseCode = courseCode
        self.instructor = instructor
        self.colorName = colorName
        self.personalGoal = personalGoal
        self.createdAt = createdAt
    }
}

