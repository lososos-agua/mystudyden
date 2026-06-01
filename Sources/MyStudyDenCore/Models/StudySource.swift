import CryptoKit
import Foundation

public enum StudySourceType: String, CaseIterable, Codable, Sendable {
    case text
    case personalNote
    case url
    case pdf
    case slides
    case transcript
    case notebookLM
    case aiConversation
    case assignmentPrompt
    case examReview
}

public enum CaptureIntent: String, CaseIterable, Codable, Sendable {
    case organize
    case studyGuide
    case quizMe
    case explainSimply
    case prepareForExam
}

public struct StudySource: Hashable, Codable, Sendable, Identifiable {
    public let id: EntityID
    public var courseID: EntityID
    public var title: String
    public var type: StudySourceType
    public var rawText: String
    public var sourceURL: URL?
    public var intent: CaptureIntent
    public var createdAt: Date
    public var sourceVersionHash: String

    public init(
        id: EntityID = EntityID(),
        courseID: EntityID,
        title: String,
        type: StudySourceType,
        rawText: String,
        sourceURL: URL? = nil,
        intent: CaptureIntent = .organize,
        createdAt: Date = Date(),
        sourceVersionHash: String? = nil
    ) {
        self.id = id
        self.courseID = courseID
        self.title = title
        self.type = type
        self.rawText = rawText
        self.sourceURL = sourceURL
        self.intent = intent
        self.createdAt = createdAt
        self.sourceVersionHash = sourceVersionHash ?? Self.makeSourceVersionHash(for: rawText)
    }

    private static func makeSourceVersionHash(for rawText: String) -> String {
        let digest = SHA256.hash(data: Data(rawText.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
