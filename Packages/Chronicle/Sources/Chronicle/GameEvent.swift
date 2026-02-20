import Foundation

/// A single notable event in a TI4 game session.
public struct GameEvent: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: EventType
    public let involvedFactions: [String]
    public let systemName: String?
    public let note: String?

    public enum EventType: String, Codable, CaseIterable {
        case battle, trade, agenda, objective, betrayal, alliance
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: EventType,
        involvedFactions: [String] = [],
        systemName: String? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.involvedFactions = involvedFactions
        self.systemName = systemName
        self.note = note
    }
}

/// A full game session containing players, events, and an optional narrative.
public struct GameSession: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var events: [GameEvent]
    public var playerFactions: [String: String] // player name → faction ID
    public var createdAt: Date
    public var narrative: String?

    public init(
        id: UUID = UUID(),
        title: String = "New Session",
        events: [GameEvent] = [],
        playerFactions: [String: String] = [:],
        createdAt: Date = Date(),
        narrative: String? = nil
    ) {
        self.id = id
        self.title = title
        self.events = events
        self.playerFactions = playerFactions
        self.createdAt = createdAt
        self.narrative = narrative
    }
}
