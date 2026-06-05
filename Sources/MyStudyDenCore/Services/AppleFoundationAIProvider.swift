import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public struct AppleFoundationAIProvider: AIProvider {
    public init() {}

    public func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft {
        let response = try await respond(
            to: studyPacketPrompt(source: source, course: course),
            maximumResponseTokens: 900
        )

        return StudyPacketDraftParser.parse(response: response, source: source, course: course)
    }

    public func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft {
        let response = try await respond(
            to: courseDigestPrompt(course: course, packets: packets),
            maximumResponseTokens: 400
        )

        return CourseDigestDraftParser.parse(response: response, course: course, packets: packets)
    }

    public func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String {
        try await respond(to: tutorPrompt(context: context), maximumResponseTokens: 500)
    }

    private func respond(to prompt: String, maximumResponseTokens: Int) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let model = SystemLanguageModel.default

            guard model.isAvailable else {
                throw AppleFoundationAIProviderError.modelUnavailable(String(describing: model.availability))
            }

            let session = LanguageModelSession()
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(maximumResponseTokens: maximumResponseTokens)
            )
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !content.isEmpty else {
                throw AppleFoundationAIProviderError.emptyResponse
            }

            return content
        } else {
            throw AppleFoundationAIProviderError.osUnavailable
        }
        #else
        throw AppleFoundationAIProviderError.frameworkUnavailable
        #endif
    }

    private func studyPacketPrompt(source: StudySource, course: Course) -> String {
        """
        You create concise study packets from course material.
        Course: \(course.title)
        Source title: \(source.title)
        Source type: \(source.type.rawValue)
        Student intent: \(source.intent.rawValue)

        Return exactly these sections:
        TITLE:
        SUMMARY:
        OUTLINE:
        - item
        STUDY GUIDE:
        CONCEPTS:
        - concept title: concept summary | key point; key point | keyword, keyword
        KEY TERMS:
        - term: definition
        REVIEW QUESTIONS:
        - question? | answer hint

        Source text:
        \(source.rawText)
        """
    }

    private func courseDigestPrompt(course: Course, packets: [StudyPacket]) -> String {
        let summaries = packets.map { "- \($0.title): \($0.compactSummary)" }.joined(separator: "\n")

        return """
        Create a course digest for \(course.title).

        Return exactly these sections:
        SUMMARY:
        NEXT ACTIONS:
        - action
        WEAK CONCEPTS:
        - concept

        Study packets:
        \(summaries)
        """
    }

    private func tutorPrompt(context: TutorHandoffContext) -> String {
        """
        You are a calm course tutor.
        Course: \(context.course.title)
        Intent: \(context.intent.rawValue)
        Packet: \(context.packet.title)
        Summary: \(context.packet.compactSummary)
        Key terms: \(context.packet.keyTerms.map { "\($0.term): \($0.definition)" }.joined(separator: "; "))
        Student question: \(context.userQuestion ?? "None")

        Explain the material clearly, separate source-based points from general background, and end with two check questions.
        """
    }
}

public enum AppleFoundationAIProviderError: Error, Equatable, Sendable {
    case frameworkUnavailable
    case osUnavailable
    case modelUnavailable(String)
    case emptyResponse
}

private enum StudyPacketDraftParser {
    static func parse(response: String, source: StudySource, course: Course) -> StudyPacketDraft {
        let sections = SectionedResponse(response)
        let title = sections.singleLine("TITLE") ?? defaultTitle(source: source, course: course)
        let summary = sections.singleLine("SUMMARY") ?? fallbackSummary(from: response, course: course)
        let outline = sections.bullets("OUTLINE", fallback: ["Review the source", "Identify key terms", "Practice recall questions"])
        let studyGuide = sections.singleLine("STUDY GUIDE") ?? "Review the summary, explain each term, then answer the questions from memory."

        return StudyPacketDraft(
            title: title,
            compactSummary: summary,
            outline: outline,
            studyGuide: studyGuide,
            conceptChunks: parseConcepts(from: sections.bullets("CONCEPTS", fallback: []), source: source),
            keyTerms: parseKeyTerms(from: sections.bullets("KEY TERMS", fallback: [])),
            reviewQuestions: parseQuestions(from: sections.bullets("REVIEW QUESTIONS", fallback: []))
        )
    }

    private static func parseConcepts(from lines: [String], source: StudySource) -> [ConceptChunk] {
        let concepts = lines.compactMap { line -> ConceptChunk? in
            let parts = line.split(separator: "|", maxSplits: 2).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let titleAndSummary = parts.first ?? line
            let pair = titleAndSummary.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            guard let title = pair.first, !title.isEmpty else {
                return nil
            }

            let summary = pair.dropFirst().first ?? "A key concept from the source."
            let keyPoints = parts.dropFirst().first?.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
            let keywords = parts.dropFirst(2).first?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []

            return ConceptChunk(title: title, summary: summary, keyPoints: keyPoints, keywords: keywords)
        }

        if concepts.isEmpty {
            return [
                ConceptChunk(
                    title: source.title.isEmpty ? "Main concept" : source.title,
                    summary: "The main idea extracted from this source.",
                    keyPoints: ["Review the source details", "Connect the idea to the course"],
                    keywords: ["source", "concept"]
                )
            ]
        }

        return concepts
    }

    private static func parseKeyTerms(from lines: [String]) -> [KeyTerm] {
        let terms = lines.compactMap { line -> KeyTerm? in
            let pair = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let term = pair.first, !term.isEmpty else {
                return nil
            }

            return KeyTerm(term: term, definition: pair.dropFirst().first ?? "A key term from the source.")
        }

        return terms.isEmpty ? [KeyTerm(term: "Key idea", definition: "An important idea from the source material.")] : terms
    }

    private static func parseQuestions(from lines: [String]) -> [ReviewQuestion] {
        let questions = lines.compactMap { line -> ReviewQuestion? in
            let parts = line.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let question = parts.first, !question.isEmpty else {
                return nil
            }

            return ReviewQuestion(question: question, answerHint: parts.dropFirst().first ?? "Use the source summary and key terms.")
        }

        return questions.isEmpty
            ? [ReviewQuestion(question: "What is the main idea of this source?", answerHint: "Use the compact summary.")]
            : questions
    }

    private static func defaultTitle(source: StudySource, course: Course) -> String {
        source.title.isEmpty ? "\(course.title) Study Packet" : source.title
    }

    private static func fallbackSummary(from response: String, course: Course) -> String {
        let firstLine = response
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        return firstLine ?? "A study packet for \(course.title)."
    }
}

private enum CourseDigestDraftParser {
    static func parse(response: String, course: Course, packets: [StudyPacket]) -> CourseDigestDraft {
        let sections = SectionedResponse(response)

        return CourseDigestDraft(
            summary: sections.singleLine("SUMMARY") ?? "\(course.title) has \(packets.count) study packet(s) ready for review.",
            nextStudyActions: sections.bullets("NEXT ACTIONS", fallback: ["Review unresolved questions", "Open the latest study packet"]),
            weakConcepts: sections.bullets("WEAK CONCEPTS", fallback: Array(packets.flatMap { $0.keyTerms.map(\.term) }.prefix(3)))
        )
    }
}

private struct SectionedResponse {
    private let sections: [String: [String]]

    init(_ response: String) {
        let headingNames = Set([
            "TITLE",
            "SUMMARY",
            "OUTLINE",
            "STUDY GUIDE",
            "CONCEPTS",
            "KEY TERMS",
            "REVIEW QUESTIONS",
            "NEXT ACTIONS",
            "WEAK CONCEPTS"
        ])
        var current: String?
        var parsed: [String: [String]] = [:]

        for rawLine in response.split(whereSeparator: \.isNewline).map(String.init) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else {
                continue
            }

            let headingParts = line.split(separator: ":", maxSplits: 1).map(String.init)
            let heading = headingParts.first?.uppercased()

            if let heading, headingNames.contains(heading) {
                current = heading
                let inlineValue = headingParts.dropFirst().first?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let inlineValue, !inlineValue.isEmpty {
                    parsed[heading, default: []].append(inlineValue)
                }
                continue
            }

            if let current {
                parsed[current, default: []].append(line)
            }
        }

        sections = parsed
    }

    func singleLine(_ name: String) -> String? {
        sections[name]?.first?.removingBulletPrefix()
    }

    func bullets(_ name: String, fallback: [String]) -> [String] {
        let values = sections[name]?
            .map { $0.removingBulletPrefix() }
            .filter { !$0.isEmpty } ?? []

        return values.isEmpty ? fallback : values
    }
}

private extension String {
    func removingBulletPrefix() -> String {
        var value = trimmingCharacters(in: .whitespacesAndNewlines)

        while let first = value.first, ["-", "*", "•"].contains(first) {
            value.removeFirst()
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }
}
