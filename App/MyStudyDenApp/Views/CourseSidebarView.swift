import SwiftUI
import MyStudyDenCore

struct CourseSidebarView: View {
    let courses: [Course]
    @Binding var selectedCourse: Course?

    var body: some View {
        List(selection: $selectedCourse) {
            Section("Courses") {
                ForEach(courses) { course in
                    Text(course.title)
                        .tag(Optional(course))
                }
            }
        }
        .navigationTitle("MyStudyDen")
    }
}

