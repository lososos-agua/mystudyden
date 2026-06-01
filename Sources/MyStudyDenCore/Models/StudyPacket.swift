import Foundation

public enum PacketCompletenessStatus: String, CaseIterable, Codable, Sendable {
    case needsSource
    case needsSummary
    case readyForReview
    case stale
}

public struct ConceptChunk: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var title: String
    public var summary: String
    public var keyPoints: [String]
    public var keywords: [String]

    public init(
        id: EntityID = EntityID(),
        title: String,
        summary: String,
        keyPoints: [String] = [],
        keywords: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.keyPoints = keyPoints
        self.keywords = keywords
    }
}

public struct KeyTerm: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var term: String
    public var definition: String

    public init(id: EntityID = EntityID(), term: String, definition: String) {
        self.id = id
        self.term = term
        self.definition = definition
    }
}

public struct ReviewQuestion: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var question: String
    public var answerHint: String
    public var difficulty: Int
    public var lastReviewedAt: Date?
    public var isResolved: Bool

    public init(
        id: EntityID = EntityID(),
        question: String,
        answerHint: String,
        difficulty: Int = 1,
        lastReviewedAt: Date? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.question = question
        self.answerHint = answerHint
        self.difficulty = difficulty
        self.lastReviewedAt = lastReviewedAt
        self.isResolved = isResolved
    }
}

public struct StudyPacket: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var courseID: EntityID
    public var sourceIDs: [EntityID]
    public var title: String
    public var compactSummary: String
    public var outline: [String]
    public var studyGuide: String
    public var conceptChunks: [ConceptChunk]
    public var keyTerms: [KeyTerm]
    public var reviewQuestions: [ReviewQuestion]
    public var learningState: LearningState
    public var completenessStatus: PacketCompletenessStatus
    public var generatedAt: Date
    public var sourceVersionHash: String

    public init(
        id: EntityID = EntityID(),
        courseID: EntityID,
        sourceIDs: [EntityID],
        title: String,
        compactSummary: String,
        outline: [String],
        studyGuide: String,
        conceptChunks: [ConceptChunk],
        keyTerms: [KeyTerm],
        reviewQuestions: [ReviewQuestion],
        learningState: LearningState = LearningState(),
        completenessStatus: PacketCompletenessStatus = .readyForReview,
        generatedAt: Date = Date(),
        sourceVersionHash: String
    ) {
        self.id = id
        self.courseID = courseID
        self.sourceIDs = sourceIDs
        self.title = title
        self.compactSummary = compactSummary
        self.outline = outline
        self.studyGuide = studyGuide
        self.conceptChunks = conceptChunks
        self.keyTerms = keyTerms
        self.reviewQuestions = reviewQuestions
        self.learningState = learningState
        self.completenessStatus = completenessStatus
        self.generatedAt = generatedAt
        self.sourceVersionHash = sourceVersionHash
    }
}

