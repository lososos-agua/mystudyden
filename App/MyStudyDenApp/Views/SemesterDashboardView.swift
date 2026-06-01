import SwiftUI

struct SemesterDashboardView: View {
    @Bindable var store: AppStore

    var body: some View {
        let dashboard = store.semesterDashboard

        List {
            Section("Courses") {
                ForEach(store.courses) { course in
                    NavigationLink {
                        CourseDashboardView(store: store, course: course)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.title)
                                .font(.headline)
                            Text("\(store.packets(for: course).count) packet(s)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Due Soon") {
                if dashboard.dueSoon.isEmpty {
                    ContentUnavailableView(
                        "Nothing due soon",
                        systemImage: "checkmark.circle",
                        description: Text("Upcoming work will appear here.")
                    )
                } else {
                    ForEach(dashboard.dueSoon) { task in
                        Label(task.title, systemImage: task.kind.symbolName)
                    }
                }
            }

            Section("Needs Attention") {
                if dashboard.coursesNeedingAttention.isEmpty {
                    ContentUnavailableView(
                        "All clear",
                        systemImage: "sparkles",
                        description: Text("Courses with shaky concepts will appear here.")
                    )
                } else {
                    ForEach(dashboard.coursesNeedingAttention) { course in
                        NavigationLink {
                            CourseDashboardView(store: store, course: course)
                        } label: {
                            Text(course.title)
                        }
                    }
                }
            }
        }
        .navigationTitle(store.semester.title)
    }
}
