import SwiftUI
import MyStudyDenCore

struct PacketDetailView: View {
    let packet: StudyPacket

    var body: some View {
        List {
            Section("Summary") {
                Text(packet.compactSummary)
            }

            Section("Outline") {
                ForEach(packet.outline, id: \.self) { item in
                    Text(item)
                }
            }

            Section("Study Guide") {
                Text(packet.studyGuide)
            }

            Section("Concepts") {
                ForEach(packet.conceptChunks) { concept in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(concept.title)
                            .font(.headline)
                        Text(concept.summary)
                            .foregroundStyle(.secondary)

                        ForEach(concept.keyPoints, id: \.self) { keyPoint in
                            BulletText(keyPoint)
                        }
                    }
                }
            }

            Section("Key Terms") {
                ForEach(packet.keyTerms) { term in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(term.term)
                            .font(.headline)
                        Text(term.definition)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Review Questions") {
                ForEach(packet.reviewQuestions) { question in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question.question)
                        Text(question.answerHint)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .studyDenListBackground()
        .navigationTitle(packet.title)
    }
}

private struct BulletText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(StudyDenTheme.apricot)
                .frame(width: 5, height: 5)
                .alignmentGuide(.firstTextBaseline) { context in
                    context[VerticalAlignment.center]
                }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}
