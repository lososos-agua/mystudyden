import Foundation

public struct EntityID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

