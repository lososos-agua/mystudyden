import Foundation

public struct CourseDashboard: Hashable, Codable, Sendable {
    public var course: Course
    public var recentPackets: [StudyPacket]
    public var upcomingTasks: [TaskItem]
    public var unresolvedQuestions: [ReviewQuestion]
    public var weakConcepts: [KeyTerm]

    public init(
        course: Course,
        recentPackets: [StudyPacket],
        upcomingTasks: [TaskItem],
        unresolvedQuestions: [ReviewQuestion],
        weakConcepts: [KeyTerm]
    ) {
        self.course = course
        self.recentPackets = recentPackets
        self.upcomingTasks = upcomingTasks
        self.unresolvedQuestions = unresolvedQuestions
        self.weakConcepts = weakConcepts
    }
}

public struct SemesterDashboard: Hashable, Codable, Sendable {
    public var semester: Semester
    public var dueSoon: [TaskItem]
    public var coursesNeedingAttention: [Course]
    public var reviewQueue: [ReviewQuestion]
    public var recentlyAddedPackets: [StudyPacket]

    public init(
        semester: Semester,
        dueSoon: [TaskItem],
        coursesNeedingAttention: [Course],
        reviewQueue: [ReviewQuestion],
        recentlyAddedPackets: [StudyPacket]
    ) {
        self.semester = semester
        self.dueSoon = dueSoon
        self.coursesNeedingAttention = coursesNeedingAttention
        self.reviewQueue = reviewQueue
        self.recentlyAddedPackets = recentlyAddedPackets
    }
}

