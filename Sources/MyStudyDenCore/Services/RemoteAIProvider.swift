import Foundation

public struct RemoteAIProvider: AIProvider {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "http://127.0.0.1:8787")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft {
        let request = GenerateStudyPacketRequest(course: course, source: source)
        let response: GenerateStudyPacketResponse = try await post(path: "/generate-study-packet", body: request)
        return response.draft.studyPacketDraft
    }

    public func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft {
        throw RemoteAIProviderError.unsupportedEndpoint("generateCourseDigest")
    }

    public func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String {
        throw RemoteAIProviderError.unsupportedEndpoint("generateTutorHandoffPrompt")
    }

    private func post<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody
    ) async throws -> ResponseBody {
        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteAIProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw RemoteAIProviderError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        return try decoder.decode(ResponseBody.self, from: data)
    }
}

public struct GenerateStudyPacketRequest: Codable, Sendable {
    public var course: Course
    public var source: StudySource

    public init(course: Course, source: StudySource) {
        self.course = course
        self.source = source
    }
}

public struct GenerateStudyPacketResponse: Codable, Sendable {
    public var draft: RemoteStudyPacketDraft
    public var provider: String

    public init(draft: RemoteStudyPacketDraft, provider: String) {
        self.draft = draft
        self.provider = provider
    }
}

public struct RemoteStudyPacketDraft: Codable, Sendable {
    public var title: String
    public var compactSummary: String
    public var outline: [String]
    public var studyGuide: String
    public var conceptChunks: [RemoteConceptChunk]
    public var keyTerms: [RemoteKeyTerm]
    public var reviewQuestions: [RemoteReviewQuestion]

    public init(
        title: String,
        compactSummary: String,
        outline: [String],
        studyGuide: String,
        conceptChunks: [RemoteConceptChunk],
        keyTerms: [RemoteKeyTerm],
        reviewQuestions: [RemoteReviewQuestion]
    ) {
        self.title = title
        self.compactSummary = compactSummary
        self.outline = outline
        self.studyGuide = studyGuide
        self.conceptChunks = conceptChunks
        self.keyTerms = keyTerms
        self.reviewQuestions = reviewQuestions
    }

    var studyPacketDraft: StudyPacketDraft {
        StudyPacketDraft(
            title: title,
            compactSummary: compactSummary,
            outline: outline,
            studyGuide: studyGuide,
            conceptChunks: conceptChunks.map(\.conceptChunk),
            keyTerms: keyTerms.map(\.keyTerm),
            reviewQuestions: reviewQuestions.map(\.reviewQuestion)
        )
    }
}

public struct RemoteConceptChunk: Codable, Sendable {
    public var title: String
    public var summary: String
    public var keyPoints: [String]
    public var keywords: [String]

    public init(title: String, summary: String, keyPoints: [String], keywords: [String]) {
        self.title = title
        self.summary = summary
        self.keyPoints = keyPoints
        self.keywords = keywords
    }

    var conceptChunk: ConceptChunk {
        ConceptChunk(title: title, summary: summary, keyPoints: keyPoints, keywords: keywords)
    }
}

public struct RemoteKeyTerm: Codable, Sendable {
    public var term: String
    public var definition: String

    public init(term: String, definition: String) {
        self.term = term
        self.definition = definition
    }

    var keyTerm: KeyTerm {
        KeyTerm(term: term, definition: definition)
    }
}

public struct RemoteReviewQuestion: Codable, Sendable {
    public var question: String
    public var answerHint: String
    public var difficulty: Int

    public init(question: String, answerHint: String, difficulty: Int = 1) {
        self.question = question
        self.answerHint = answerHint
        self.difficulty = difficulty
    }

    var reviewQuestion: ReviewQuestion {
        ReviewQuestion(question: question, answerHint: answerHint, difficulty: difficulty)
    }
}

public enum RemoteAIProviderError: Error, Equatable, Sendable {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case unsupportedEndpoint(String)
}
