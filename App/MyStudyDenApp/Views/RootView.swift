import SwiftUI
import MyStudyDenCore

struct RootView: View {
    @Bindable var store: AppStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedCourse: Course?

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                iPhoneLayout
            } else {
                iPadLayout
            }
        }
    }

    private var iPhoneLayout: some View {
        TabView {
            NavigationStack {
                SemesterDashboardView(store: store)
            }
            .tabItem {
                Label("Today", systemImage: "calendar")
            }

            NavigationStack {
                CourseListView(store: store)
            }
            .tabItem {
                Label("Courses", systemImage: "books.vertical")
            }

            NavigationStack {
                ReviewQueueView(store: store)
            }
            .tabItem {
                Label("Review", systemImage: "checklist")
            }
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            CourseSidebarView(courses: store.courses, selectedCourse: $selectedCourse)
        } detail: {
            if let selectedCourse {
                CourseDashboardView(store: store, course: selectedCourse)
            } else {
                SemesterDashboardView(store: store)
            }
        }
    }
}

