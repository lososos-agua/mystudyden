import SwiftUI
import MyStudyDenCore

@main
struct MyStudyDenApp: App {
    @State private var store = AppStore.preview

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .tint(StudyDenTheme.apricot)
        }
    }
}
