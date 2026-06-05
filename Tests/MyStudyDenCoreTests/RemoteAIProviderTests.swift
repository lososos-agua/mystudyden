import Foundation
import Testing
@testable import MyStudyDenCore

@Suite("Remote AI Provider")
struct RemoteAIProviderTests {
    @Test
    func decodesServerStudyPacketDraftWithoutModelIDs() throws {
        let data = Data(
            """
            {
              "draft": {
                "title": "Retrieval Practice Notes",
                "compactSummary": "Retrieval practice improves memory.",
                "outline": ["Recall", "Spacing"],
                "studyGuide": "Review, recall, and correct mistakes.",
                "conceptChunks": [
                  {
                    "title": "Retrieval practice",
                    "summary": "Recall strengthens memory.",
                    "keyPoints": ["Recall information", "Consolidate learning"],
                    "keywords": ["retrieval", "memory"]
                  }
                ],
                "keyTerms": [
                  {
                    "term": "Spacing",
                    "definition": "Reviewing material across time."
                  }
                ],
                "reviewQuestions": [
                  {
                    "question": "Why does retrieval practice help?",
                    "answerHint": "Think about recall.",
                    "difficulty": 1
                  }
                ]
              },
              "provider": "openrouter"
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(GenerateStudyPacketResponse.self, from: data)
        let draft = response.draft.studyPacketDraft

        #expect(draft.conceptChunks.count == 1)
        #expect(draft.conceptChunks.first?.id.rawValue.uuidString.isEmpty == false)
        #expect(draft.keyTerms.count == 1)
        #expect(draft.reviewQuestions.count == 1)
    }
}
