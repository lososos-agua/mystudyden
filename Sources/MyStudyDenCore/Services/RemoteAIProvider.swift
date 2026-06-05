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
        return response.draft
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
    public var draft: StudyPacketDraft
    public var provider: String

    public init(draft: StudyPacketDraft, provider: String) {
        self.draft = draft
        self.provider = provider
    }
}

public enum RemoteAIProviderError: Error, Equatable, Sendable {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case unsupportedEndpoint(String)
}
