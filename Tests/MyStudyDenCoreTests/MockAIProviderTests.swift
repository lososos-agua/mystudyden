import Testing
@testable import MyStudyDenCore

@Suite("Mock AI Provider")
struct MockAIProviderTests {
    @Test
    func mockProviderGeneratesAReadyStudyPacket() async throws {
        let provider = MockAIProvider()
        let course = SampleData.course
        let source = SampleData.source

        let draft = try await provider.generateStudyPacket(from: source, course: course)
        let packet = StudyPacketFactory.makePacket(from: draft, source: source, course: course)

        #expect(packet.courseID == course.id)
        #expect(packet.sourceIDs == [source.id])
        #expect(packet.completenessStatus == .readyForReview)
        #expect(!packet.keyTerms.isEmpty)
        #expect(!packet.reviewQuestions.isEmpty)
    }

    @Test
    func mockProviderBuildsTutorHandoffPrompt() async throws {
        let provider = MockAIProvider()
        let course = SampleData.course
        let source = SampleData.source
        let draft = try await provider.generateStudyPacket(from: source, course: course)
        let packet = StudyPacketFactory.makePacket(from: draft, source: source, course: course)

        let prompt = try await provider.generateTutorHandoffPrompt(
            context: TutorHandoffContext(
                course: course,
                packet: packet,
                intent: .quizMe,
                userQuestion: "How should I prepare for the exam?"
            )
        )

        #expect(prompt.contains(course.title))
        #expect(prompt.contains(packet.compactSummary))
        #expect(prompt.contains("How should I prepare for the exam?"))
    }

    @Test
    func studySourceVersionHashIsStableForSameText() {
        let course = SampleData.course
        let rawText = "A stable source should produce a stable version hash."

        let firstSource = StudySource(
            courseID: course.id,
            title: "First",
            type: .personalNote,
            rawText: rawText
        )
        let secondSource = StudySource(
            courseID: course.id,
            title: "Second",
            type: .personalNote,
            rawText: rawText
        )

        #expect(firstSource.sourceVersionHash == secondSource.sourceVersionHash)
        #expect(firstSource.sourceVersionHash.count == 64)
    }
}
