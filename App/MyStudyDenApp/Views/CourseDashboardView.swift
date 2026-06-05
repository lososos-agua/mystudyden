import SwiftUI
import MyStudyDenCore

struct CourseDashboardView: View {
    @Bindable var store: AppStore
    let course: Course
    @State private var isShowingAddSource = false

    var body: some View {
        let dashboard = store.dashboard(for: course)
        let courseSources = store.sources(for: course)

        List {
            Section("Next") {
                if dashboard.upcomingTasks.isEmpty {
                    ContentUnavailableView(
                        "No upcoming tasks",
                        systemImage: "checkmark.circle",
                        description: Text("Readings, reviews, and assignments will appear here.")
                    )
                } else {
                    ForEach(dashboard.upcomingTasks) { task in
                        Label(task.title, systemImage: task.kind.symbolName)
                            .foregroundStyle(.primary, StudyDenTheme.apricot)
                    }
                }
            }

            #if DEBUG
            if let status = store.lastGenerationStatus {
                Section("AI Status") {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            #endif

            Section("Sources") {
                if courseSources.isEmpty {
                    ContentUnavailableView(
                        "No sources yet",
                        systemImage: "doc.text",
                        description: Text("Added notes, prompts, and pasted material will appear here.")
                    )
                } else {
                    ForEach(courseSources) { source in
                        NavigationLink {
                            SourceDetailView(store: store, source: source)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.title)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Text(source.type.displayName)
                                    Text(source.intent.displayName)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.deleteSource(source)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("Study Packets") {
                if dashboard.recentPackets.isEmpty {
                    ContentUnavailableView(
                        "No packets yet",
                        systemImage: "tray",
                        description: Text("Add a source to create the first study packet.")
                    )
                } else {
                    ForEach(dashboard.recentPackets) { packet in
                        NavigationLink {
                            PacketDetailView(packet: packet)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(packet.title)
                                    .font(.headline)
                                Text(packet.compactSummary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }

            Section("Unresolved Questions") {
                if dashboard.unresolvedQuestions.isEmpty {
                    ContentUnavailableView(
                        "No open questions",
                        systemImage: "questionmark.circle",
                        description: Text("Questions from generated packets will appear here.")
                    )
                } else {
                    ForEach(dashboard.unresolvedQuestions) { question in
                        Text(question.question)
                    }
                }
            }

            Section("Weak Concepts") {
                if dashboard.weakConcepts.isEmpty {
                    ContentUnavailableView(
                        "No weak concepts marked",
                        systemImage: "lightbulb",
                        description: Text("Key terms from shaky packets will appear here.")
                    )
                } else {
                    ForEach(dashboard.weakConcepts) { term in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(term.term)
                                .font(.headline)
                            Text(term.definition)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .studyDenListBackground()
        .navigationTitle(course.title)
        .sheet(isPresented: $isShowingAddSource) {
            AddSourceView(course: course) { form in
                await store.addStudySource(
                    title: form.title,
                    type: form.type,
                    rawText: form.rawText,
                    intent: form.intent,
                    to: course
                )
            }
        }
        .alert(
            "Packet generation failed",
            isPresented: Binding(
                get: { store.generationErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        store.clearGenerationError()
                    }
                }
            )
        ) {
            Button("OK") {
                store.clearGenerationError()
            }
        } message: {
            Text(store.generationErrorMessage ?? "")
        }
        .toolbar {
            Button {
                isShowingAddSource = true
            } label: {
                Label("Add Source", systemImage: "plus")
            }
        }
    }
}
