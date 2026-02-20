import Foundation

/// Central data store that loads and indexes all bundled TI4 game data.
@MainActor
public final class GameDataStore: ObservableObject {
    @Published public private(set) var factions: [Faction] = []
    @Published public private(set) var technologies: [Technology] = []
    @Published public private(set) var systemTiles: [SystemTile] = []
    @Published public private(set) var units: [UnitBlueprint] = []
    @Published public private(set) var actionCards: [ActionCard] = []
    @Published public private(set) var agendaCards: [AgendaCard] = []

    public init() {}

    /// Loads all game data from bundled JSON resources.
    public func load() {
        factions = Self.decode([Faction].self, from: "factions") ?? []
        technologies = Self.decode([Technology].self, from: "technologies") ?? []
        systemTiles = Self.decode([SystemTile].self, from: "system_tiles") ?? []
        units = Self.decode([UnitBlueprint].self, from: "units") ?? []
        actionCards = Self.decode([ActionCard].self, from: "action_cards") ?? []
        agendaCards = Self.decode([AgendaCard].self, from: "agenda_cards") ?? []
    }

    private static func decode<T: Decodable>(_ type: T.Type, from resource: String) -> T? {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "json") else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(type, from: Data(contentsOf: url))
    }
}
