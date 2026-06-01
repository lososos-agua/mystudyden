import Foundation

public struct StudyPacketDraft: Hashable, Codable, Sendable {
    public var title: String
    public var compactSummary: String
    public var outline: [String]
    public var studyGuide: String
    public var conceptChunks: [ConceptChunk]
    public var keyTerms: [KeyTerm]
    public var reviewQuestions: [ReviewQuestion]

    public init(
        title: String,
        compactSummary: String,
        outline: [String],
        studyGuide: String,
        conceptChunks: [ConceptChunk],
        keyTerms: [KeyTerm],
        reviewQuestions: [ReviewQuestion]
    ) {
        self.title = title
        self.compactSummary = compactSummary
        self.outline = outline
        self.studyGuide = studyGuide
        self.conceptChunks = conceptChunks
        self.keyTerms = keyTerms
        self.reviewQuestions = reviewQuestions
    }
}

public struct CourseDigestDraft: Hashable, Codable, Sendable {
    public var summary: String
    public var nextStudyActions: [String]
    public var weakConcepts: [String]

    public init(summary: String, nextStudyActions: [String], weakConcepts: [String]) {
        self.summary = summary
        self.nextStudyActions = nextStudyActions
        self.weakConcepts = weakConcepts
    }
}

public struct TutorHandoffContext: Hashable, Codable, Sendable {
    public var course: Course
    public var packet: StudyPacket
    public var intent: CaptureIntent
    public var userQuestion: String?

    public init(
        course: Course,
        packet: StudyPacket,
        intent: CaptureIntent,
        userQuestion: String? = nil
    ) {
        self.course = course
        self.packet = packet
        self.intent = intent
        self.userQuestion = userQuestion
    }
}

public protocol AIProvider: Sendable {
    func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft
    func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft
    func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String
}

