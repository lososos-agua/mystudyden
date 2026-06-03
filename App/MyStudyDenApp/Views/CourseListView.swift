import SwiftUI

struct CourseListView: View {
    @Bindable var store: AppStore

    var body: some View {
        List(store.courses) { course in
            NavigationLink {
                CourseDashboardView(store: store, course: course)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)

                    HStack(spacing: 8) {
                        if let courseCode = course.courseCode {
                            Text(courseCode)
                        }

                        Text("\(store.packets(for: course).count) packet(s)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .studyDenListBackground()
        .navigationTitle("Courses")
    }
}
