import Foundation

public enum StudyPacketFactory {
    public static func makePacket(
        from draft: StudyPacketDraft,
        source: StudySource,
        course: Course,
        learningState: LearningState = LearningState()
    ) -> StudyPacket {
        StudyPacket(
            courseID: course.id,
            sourceIDs: [source.id],
            title: draft.title,
            compactSummary: draft.compactSummary,
            outline: draft.outline,
            studyGuide: draft.studyGuide,
            conceptChunks: draft.conceptChunks,
            keyTerms: draft.keyTerms,
            reviewQuestions: draft.reviewQuestions,
            learningState: learningState,
            completenessStatus: .readyForReview,
            sourceVersionHash: source.sourceVersionHash
        )
    }
}

