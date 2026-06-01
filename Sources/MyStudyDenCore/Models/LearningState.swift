import Foundation

public enum UnderstandingState: String, CaseIterable, Codable, Sendable {
    case understood
    case shaky
    case confused
}

public struct LearningState: Hashable, Codable, Sendable {
    public var understanding: UnderstandingState
    public var isImportant: Bool
    public var isExamRelevant: Bool
    public var shouldReviewLater: Bool
    public var shouldAskProfessorOrTA: Bool

    public init(
        understanding: UnderstandingState = .shaky,
        isImportant: Bool = false,
        isExamRelevant: Bool = false,
        shouldReviewLater: Bool = false,
        shouldAskProfessorOrTA: Bool = false
    ) {
        self.understanding = understanding
        self.isImportant = isImportant
        self.isExamRelevant = isExamRelevant
        self.shouldReviewLater = shouldReviewLater
        self.shouldAskProfessorOrTA = shouldAskProfessorOrTA
    }
}

