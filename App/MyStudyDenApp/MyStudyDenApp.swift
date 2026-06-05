import SwiftUI
import MyStudyDenCore

@main
struct MyStudyDenApp: App {
    @State private var store = AppStore.loadPersistedOrPreview()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .tint(StudyDenTheme.apricot)
        }
    }
}
