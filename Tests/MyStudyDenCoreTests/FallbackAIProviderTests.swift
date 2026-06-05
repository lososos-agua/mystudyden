import Testing
@testable import MyStudyDenCore

@Suite("Fallback AI Provider")
struct FallbackAIProviderTests {
    @Test
    func fallsBackWhenPrimaryCannotGenerateStudyPacket() async throws {
        let provider = FallbackAIProvider(primary: FailingAIProvider(), fallback: MockAIProvider())
        let course = SampleData.course
        let source = SampleData.source

        let draft = try await provider.generateStudyPacket(from: source, course: course)

        #expect(draft.title == source.title)
        #expect(!draft.keyTerms.isEmpty)
        #expect(!draft.reviewQuestions.isEmpty)
    }

    @Test
    func fallsBackWhenPrimaryCannotGenerateTutorPrompt() async throws {
        let fallback = MockAIProvider()
        let provider = FallbackAIProvider(primary: FailingAIProvider(), fallback: fallback)
        let course = SampleData.course
        let source = SampleData.source
        let draft = try await fallback.generateStudyPacket(from: source, course: course)
        let packet = StudyPacketFactory.makePacket(from: draft, source: source, course: course)

        let prompt = try await provider.generateTutorHandoffPrompt(
            context: TutorHandoffContext(course: course, packet: packet, intent: .quizMe)
        )

        #expect(prompt.contains(course.title))
        #expect(prompt.contains(packet.title))
    }
}

private struct FailingAIProvider: AIProvider {
    func generateStudyPacket(from source: StudySource, course: Course) async throws -> StudyPacketDraft {
        throw FailingAIProviderError.unavailable
    }

    func generateCourseDigest(course: Course, packets: [StudyPacket]) async throws -> CourseDigestDraft {
        throw FailingAIProviderError.unavailable
    }

    func generateTutorHandoffPrompt(context: TutorHandoffContext) async throws -> String {
        throw FailingAIProviderError.unavailable
    }
}

private enum FailingAIProviderError: Error {
    case unavailable
}
