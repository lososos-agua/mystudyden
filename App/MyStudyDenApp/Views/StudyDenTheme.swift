import SwiftUI

enum StudyDenTheme {
    static let apricot = Color(red: 0.93, green: 0.48, blue: 0.24)
    static let apricotSoft = Color(red: 1.0, green: 0.84, blue: 0.68)
    static let background = Color(red: 1.0, green: 0.97, blue: 0.92)
    static let lavender = Color(red: 0.60, green: 0.45, blue: 0.66)
    static let cream = Color(red: 1.0, green: 0.93, blue: 0.78)
}

extension View {
    func studyDenListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(StudyDenTheme.background)
    }
}
