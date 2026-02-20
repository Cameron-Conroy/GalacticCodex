import Foundation

/// A TI4 faction with its abilities, commodities, and starting tech.
public struct Faction: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let expansion: String
    public let commodities: Int
    public let startingTech: [String]
    public let abilities: [Ability]
    public let promissoryNote: String
    public let flagship: String

    public init(id: String, name: String, expansion: String, commodities: Int, startingTech: [String], abilities: [Ability], promissoryNote: String, flagship: String) {
        self.id = id; self.name = name; self.expansion = expansion; self.commodities = commodities
        self.startingTech = startingTech; self.abilities = abilities; self.promissoryNote = promissoryNote; self.flagship = flagship
    }

    public struct Ability: Codable, Hashable, Sendable {
        public let name: String
        public let description: String

        public init(name: String, description: String) {
            self.name = name; self.description = description
        }
    }
}

/// A technology card with its prerequisites and effects.
public struct Technology: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let type: TechType
    public let faction: String?
    public let prerequisites: [TechType]
    public let description: String

    public init(id: String, name: String, type: TechType, faction: String?, prerequisites: [TechType], description: String) {
        self.id = id; self.name = name; self.type = type; self.faction = faction
        self.prerequisites = prerequisites; self.description = description
    }

    public enum TechType: String, Codable, Hashable, Sendable {
        case biotic, warfare, propulsion, cybernetic, unitUpgrade
    }
}

/// A system tile on the game board.
public struct SystemTile: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let tileNumber: Int
    public let type: TileType
    public let planets: [Planet]
    public let anomaly: String?
    public let wormhole: String?

    public init(id: String, tileNumber: Int, type: TileType, planets: [Planet], anomaly: String?, wormhole: String?) {
        self.id = id; self.tileNumber = tileNumber; self.type = type; self.planets = planets
        self.anomaly = anomaly; self.wormhole = wormhole
    }

    public enum TileType: String, Codable, Hashable, Sendable {
        case home, blue, red, mecatolRex, hyperlane
    }
}

/// A planet within a system tile.
public struct Planet: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let resources: Int
    public let influence: Int
    public let trait: PlanetTrait?
    public let specialty: Technology.TechType?

    public init(id: String, name: String, resources: Int, influence: Int, trait: PlanetTrait?, specialty: Technology.TechType?) {
        self.id = id; self.name = name; self.resources = resources; self.influence = influence
        self.trait = trait; self.specialty = specialty
    }

    public enum PlanetTrait: String, Codable, Hashable, Sendable {
        case cultural, hazardous, industrial
    }
}

/// A unit type with its base combat values.
public struct UnitBlueprint: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let cost: Int
    public let combat: Int
    public let move: Int
    public let capacity: Int
    public let sustainDamage: Bool
    public let bombardment: DiceRoll?
    public let spaceCannon: DiceRoll?
    public let antiFighterBarrage: DiceRoll?
    public let productionValue: Int?

    public init(id: String, name: String, cost: Int, combat: Int, move: Int, capacity: Int, sustainDamage: Bool, bombardment: DiceRoll?, spaceCannon: DiceRoll?, antiFighterBarrage: DiceRoll?, productionValue: Int?) {
        self.id = id; self.name = name; self.cost = cost; self.combat = combat; self.move = move
        self.capacity = capacity; self.sustainDamage = sustainDamage; self.bombardment = bombardment
        self.spaceCannon = spaceCannon; self.antiFighterBarrage = antiFighterBarrage; self.productionValue = productionValue
    }

    public struct DiceRoll: Codable, Hashable, Sendable {
        public let hitOn: Int
        public let count: Int

        public init(hitOn: Int, count: Int) {
            self.hitOn = hitOn; self.count = count
        }
    }
}

/// An action card.
public struct ActionCard: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let phase: String
    public let description: String

    public init(id: String, name: String, phase: String, description: String) {
        self.id = id; self.name = name; self.phase = phase; self.description = description
    }
}

/// An agenda card voted on during the Agenda phase.
public struct AgendaCard: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let type: AgendaType
    public let description: String

    public init(id: String, name: String, type: AgendaType, description: String) {
        self.id = id; self.name = name; self.type = type; self.description = description
    }

    public enum AgendaType: String, Codable, Hashable, Sendable {
        case law, directive
    }
}
