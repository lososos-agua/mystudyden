import Foundation

public struct MockAIProvider: AIProvider {
    public init() {}

    public func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft {
        let title = source.title.isEmpty ? "\(course.title) Study Packet" : source.title
        let firstSentence = source.rawText
            .split(separator: ".")
            .first
            .map(String.init) ?? source.rawText

        return StudyPacketDraft(
            title: title,
            compactSummary: firstSentence.isEmpty
                ? "A study packet for \(course.title)."
                : firstSentence.trimmingCharacters(in: .whitespacesAndNewlines),
            outline: [
                "Core ideas from the source",
                "Important terms and relationships",
                "Questions to revisit before class or exam"
            ],
            studyGuide: "Review the summary, explain each key term in your own words, then answer the review questions without looking.",
            conceptChunks: [
                ConceptChunk(
                    title: "Main concept",
                    summary: "The central idea extracted from this source.",
                    keyPoints: ["Identify the claim", "Connect it to the course", "Mark confusing parts"],
                    keywords: ["concept", "course", "review"]
                )
            ],
            keyTerms: [
                KeyTerm(term: "Study Packet", definition: "A structured unit made from raw course material."),
                KeyTerm(term: "Learning State", definition: "The student's current understanding and review status.")
            ],
            reviewQuestions: [
                ReviewQuestion(
                    question: "What is the main idea of this source?",
                    answerHint: "Use the compact summary and outline."
                ),
                ReviewQuestion(
                    question: "Which concept still feels shaky?",
                    answerHint: "Mark it for review or ask a professor/TA."
                )
            ]
        )
    }

    public func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft {
        CourseDigestDraft(
            summary: "\(course.title) has \(packets.count) study packet(s) ready for review.",
            nextStudyActions: [
                "Review unresolved questions",
                "Open the latest study packet",
                "Mark weak concepts before the next class"
            ],
            weakConcepts: Array(packets.flatMap { $0.keyTerms.map(\.term) }.prefix(3))
        )
    }

    public func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String {
        var lines = [
            "You are a calm course tutor helping me study.",
            "Course: \(context.course.title)",
            "Intent: \(context.intent.rawValue)",
            "",
            "Study packet: \(context.packet.title)",
            "Summary: \(context.packet.compactSummary)",
            "",
            "Key terms:",
            context.packet.keyTerms.map { "- \($0.term): \($0.definition)" }.joined(separator: "\n"),
            "",
            "Review questions:",
            context.packet.reviewQuestions.map { "- \($0.question)" }.joined(separator: "\n")
        ]

        if let userQuestion = context.userQuestion, !userQuestion.isEmpty {
            lines.append(contentsOf: ["", "My question: \(userQuestion)"])
        }

        lines.append("")
        lines.append("Explain step by step, distinguish source-based facts from general background, and end with two check questions.")

        return lines.joined(separator: "\n")
    }
}
