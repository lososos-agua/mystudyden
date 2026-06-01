import SwiftUI

struct ReviewQueueView: View {
    @Bindable var store: AppStore

    var body: some View {
        let packetsWithOpenQuestions = store.packets.filter { packet in
            packet.reviewQuestions.contains { !$0.isResolved }
        }

        List {
            if packetsWithOpenQuestions.isEmpty {
                ContentUnavailableView(
                    "Review queue is empty",
                    systemImage: "checklist",
                    description: Text("Open review questions from study packets will appear here.")
                )
            } else {
                ForEach(packetsWithOpenQuestions) { packet in
                    Section(packet.title) {
                        ForEach(packet.reviewQuestions.filter { !$0.isResolved }) { question in
                            Text(question.question)
                        }
                    }
                }
            }
        }
        .navigationTitle("Review")
    }
}
