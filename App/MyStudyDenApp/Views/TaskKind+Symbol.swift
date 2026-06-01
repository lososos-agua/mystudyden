import MyStudyDenCore

extension TaskKind {
    var symbolName: String {
        switch self {
        case .reading:
            "book"
        case .assignment:
            "pencil"
        case .exam:
            "graduationcap"
        case .review:
            "arrow.clockwise"
        case .askProfessorOrTA:
            "person.bubble"
        }
    }
}
