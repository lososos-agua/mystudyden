import SwiftUI
import MyStudyDenCore

struct AddSourceView: View {
    let course: Course
    let onSubmit: (StudySourceForm) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var type: StudySourceType = .personalNote
    @State private var intent: CaptureIntent = .organize
    @State private var rawText = ""
    @State private var isGenerating = false

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isGenerating
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Source") {
                    TextField("Title", text: $title)

                    Picker("Type", selection: $type) {
                        ForEach(StudySourceType.captureOptions, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Intent", selection: $intent) {
                        ForEach(CaptureIntent.allCases, id: \.self) { intent in
                            Text(intent.displayName).tag(intent)
                        }
                    }
                }

                Section("Material") {
                    TextEditor(text: $rawText)
                        .frame(minHeight: 220)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .studyDenListBackground()
            .navigationTitle("Add Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await submit()
                        }
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Generate")
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        isGenerating = true
        await onSubmit(
            StudySourceForm(
                title: title,
                type: type,
                rawText: rawText,
                intent: intent
            )
        )
        isGenerating = false
        dismiss()
    }
}

struct StudySourceForm: Hashable, Sendable {
    var title: String
    var type: StudySourceType
    var rawText: String
    var intent: CaptureIntent
}

private extension StudySourceType {
    static var captureOptions: [StudySourceType] {
        [.personalNote, .text, .url, .transcript, .assignmentPrompt, .examReview, .aiConversation, .notebookLM]
    }
}
