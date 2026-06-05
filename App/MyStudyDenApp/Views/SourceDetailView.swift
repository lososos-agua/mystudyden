import SwiftUI
import MyStudyDenCore

struct SourceDetailView: View {
    @Bindable var store: AppStore
    let source: StudySource
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Type", value: source.type.displayName)
                LabeledContent("Intent", value: source.intent.displayName)

                if let sourceURL = source.sourceURL {
                    Link(sourceURL.absoluteString, destination: sourceURL)
                }
            }

            Section("Material") {
                Text(source.rawText)
                    .textSelection(.enabled)
            }
        }
        .studyDenListBackground()
        .navigationTitle(source.title)
        .toolbar {
            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete Source", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete this source?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Source", role: .destructive) {
                store.deleteSource(source)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Generated packets from this source will also be removed.")
        }
    }
}

extension StudySourceType {
    var displayName: String {
        switch self {
        case .text:
            "Pasted Text"
        case .personalNote:
            "Personal Note"
        case .url:
            "URL"
        case .pdf:
            "PDF"
        case .slides:
            "Slides"
        case .transcript:
            "Transcript"
        case .notebookLM:
            "NotebookLM"
        case .aiConversation:
            "AI Conversation"
        case .assignmentPrompt:
            "Assignment Prompt"
        case .examReview:
            "Exam Review"
        }
    }
}

extension CaptureIntent {
    var displayName: String {
        switch self {
        case .organize:
            "Organize"
        case .studyGuide:
            "Study Guide"
        case .quizMe:
            "Quiz Me"
        case .explainSimply:
            "Explain Simply"
        case .prepareForExam:
            "Prepare for Exam"
        }
    }
}
