import XCTest
@testable import TI4Data

final class TI4DataTests: XCTestCase {

    // MARK: - Faction Tests

    func testDecodeFactions() throws {
        let data = try loadJSON("factions")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let factions = try decoder.decode([Faction].self, from: data)
        XCTAssertEqual(factions.count, 25, "Should have 25 factions (17 base + 8 PoK)")
    }

    func testBaseFactionCount() throws {
        let factions = try decodeFactions()
        let base = factions.filter { $0.expansion == "base" }
        XCTAssertEqual(base.count, 17, "Should have 17 base game factions")
    }

    func testPoKFactionCount() throws {
        let factions = try decodeFactions()
        let pok = factions.filter { $0.expansion == "pok" }
        XCTAssertEqual(pok.count, 8, "Should have 8 PoK factions")
    }

    func testSolFaction() throws {
        let factions = try decodeFactions()
        let sol = try XCTUnwrap(factions.first { $0.id == "sol" })
        XCTAssertEqual(sol.name, "The Federation of Sol")
        XCTAssertEqual(sol.commodities, 4)
        XCTAssertEqual(sol.startingTech, ["Antimass Deflectors", "Neural Motivator"])
        XCTAssertEqual(sol.abilities.count, 2)
        XCTAssertEqual(sol.flagship, "Genesis")
    }

    func testJolNarStartingTech() throws {
        let factions = try decodeFactions()
        let jolnar = try XCTUnwrap(factions.first { $0.id == "jolnar" })
        XCTAssertEqual(jolnar.startingTech.count, 4, "Jol-Nar starts with 4 technologies")
    }

    func testNekroNoStartingTech() throws {
        let factions = try decodeFactions()
        let nekro = try XCTUnwrap(factions.first { $0.id == "nekro" })
        XCTAssertTrue(nekro.startingTech.isEmpty, "Nekro Virus starts with no technologies")
    }

    func testHacanCommodities() throws {
        let factions = try decodeFactions()
        let hacan = try XCTUnwrap(factions.first { $0.id == "hacan" })
        XCTAssertEqual(hacan.commodities, 6, "Hacan has the highest commodities at 6")
    }

    // MARK: - Technology Tests

    func testDecodeTechnologies() throws {
        let data = try loadJSON("technologies")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let techs = try decoder.decode([Technology].self, from: data)
        XCTAssertGreaterThanOrEqual(techs.count, 70, "Should have at least 70 technologies")
    }

    func testGenericTechCount() throws {
        let techs = try decodeTechnologies()
        let generic = techs.filter { $0.faction == nil }
        XCTAssertGreaterThanOrEqual(generic.count, 24, "Should have at least 24 generic techs (+ unit upgrades)")
    }

    func testFactionTechCount() throws {
        let techs = try decodeTechnologies()
        let factionTechs = techs.filter { $0.faction != nil }
        XCTAssertGreaterThanOrEqual(factionTechs.count, 40, "Should have faction-specific technologies")
    }

    func testTechTypeDistribution() throws {
        let techs = try decodeTechnologies()
        let generic = techs.filter { $0.faction == nil }
        let biotic = generic.filter { $0.type == .biotic }
        let warfare = generic.filter { $0.type == .warfare }
        let propulsion = generic.filter { $0.type == .propulsion }
        let cybernetic = generic.filter { $0.type == .cybernetic }
        XCTAssertEqual(biotic.count, 6, "6 generic biotic techs")
        XCTAssertEqual(warfare.count, 6, "6 generic warfare techs")
        XCTAssertEqual(propulsion.count, 6, "6 generic propulsion techs")
        XCTAssertEqual(cybernetic.count, 6, "6 generic cybernetic techs")
    }

    func testNeuralMotivatorHasNoPrereqs() throws {
        let techs = try decodeTechnologies()
        let nm = try XCTUnwrap(techs.first { $0.id == "neural_motivator" })
        XCTAssertTrue(nm.prerequisites.isEmpty)
        XCTAssertEqual(nm.type, .biotic)
        XCTAssertNil(nm.faction)
    }

    func testUnitUpgradeTechs() throws {
        let techs = try decodeTechnologies()
        let upgrades = techs.filter { $0.type == .unitUpgrade && $0.faction == nil }
        XCTAssertGreaterThanOrEqual(upgrades.count, 9, "At least 9 generic unit upgrade techs")
    }

    // MARK: - System Tile Tests

    func testDecodeSystemTiles() throws {
        let data = try loadJSON("system_tiles")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tiles = try decoder.decode([SystemTile].self, from: data)
        XCTAssertGreaterThanOrEqual(tiles.count, 80, "Should have at least 80 system tiles")
    }

    func testMecatolRexTile() throws {
        let tiles = try decodeSystemTiles()
        let mecatol = try XCTUnwrap(tiles.first { $0.tileNumber == 18 })
        XCTAssertEqual(mecatol.type, .mecatolRex)
        XCTAssertEqual(mecatol.planets.count, 1)
        XCTAssertEqual(mecatol.planets.first?.name, "Mecatol Rex")
        XCTAssertEqual(mecatol.planets.first?.resources, 1)
        XCTAssertEqual(mecatol.planets.first?.influence, 6)
    }

    func testHomeSystemCount() throws {
        let tiles = try decodeSystemTiles()
        let homes = tiles.filter { $0.type == .home }
        XCTAssertEqual(homes.count, 24, "Should have 24 home systems (Keleres uses another faction's home)")
    }

    func testBlueTileHasPlanets() throws {
        let tiles = try decodeSystemTiles()
        let blueTiles = tiles.filter { $0.type == .blue }
        for tile in blueTiles {
            XCTAssertFalse(tile.planets.isEmpty, "Blue tile \(tile.id) should have at least 1 planet")
        }
    }

    func testRedTileTypes() throws {
        let tiles = try decodeSystemTiles()
        let redTiles = tiles.filter { $0.type == .red }
        XCTAssertGreaterThanOrEqual(redTiles.count, 10, "Should have multiple red tiles")
    }

    func testAnomalyTiles() throws {
        let tiles = try decodeSystemTiles()
        let anomalies = tiles.filter { $0.anomaly != nil }
        XCTAssertGreaterThanOrEqual(anomalies.count, 4, "Should have asteroid field, supernova, nebula, and gravity rift tiles")
    }

    func testWormholeTiles() throws {
        let tiles = try decodeSystemTiles()
        let wormholes = tiles.filter { $0.wormhole != nil }
        XCTAssertGreaterThanOrEqual(wormholes.count, 4, "Should have alpha, beta, gamma, and delta wormhole tiles")
    }

    func testHyperlanes() throws {
        let tiles = try decodeSystemTiles()
        let hyperlanes = tiles.filter { $0.type == .hyperlane }
        XCTAssertGreaterThanOrEqual(hyperlanes.count, 1, "Should have hyperlane tiles (PoK)")
    }

    func testPlanetTraits() throws {
        let tiles = try decodeSystemTiles()
        let allPlanets = tiles.flatMap { $0.planets }
        let cultural = allPlanets.filter { $0.trait == .cultural }
        let hazardous = allPlanets.filter { $0.trait == .hazardous }
        let industrial = allPlanets.filter { $0.trait == .industrial }
        XCTAssertGreaterThan(cultural.count, 0)
        XCTAssertGreaterThan(hazardous.count, 0)
        XCTAssertGreaterThan(industrial.count, 0)
    }

    func testPlanetSpecialties() throws {
        let tiles = try decodeSystemTiles()
        let allPlanets = tiles.flatMap { $0.planets }
        let specialties = allPlanets.compactMap { $0.specialty }
        XCTAssertTrue(specialties.contains(.biotic))
        XCTAssertTrue(specialties.contains(.warfare))
        XCTAssertTrue(specialties.contains(.propulsion))
        XCTAssertTrue(specialties.contains(.cybernetic))
    }

    // MARK: - Unit Tests

    func testDecodeUnits() throws {
        let data = try loadJSON("units")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let units = try decoder.decode([UnitBlueprint].self, from: data)
        XCTAssertEqual(units.count, 11, "Should have 11 unit types")
    }

    func testDreadnought() throws {
        let units = try decodeUnits()
        let dread = try XCTUnwrap(units.first { $0.id == "dreadnought" })
        XCTAssertEqual(dread.cost, 4)
        XCTAssertEqual(dread.combat, 5)
        XCTAssertTrue(dread.sustainDamage)
        XCTAssertNotNil(dread.bombardment)
        XCTAssertEqual(dread.bombardment?.hitOn, 5)
    }

    func testPDSHasSpaceCannon() throws {
        let units = try decodeUnits()
        let pds = try XCTUnwrap(units.first { $0.id == "pds" })
        XCTAssertNotNil(pds.spaceCannon)
        XCTAssertEqual(pds.spaceCannon?.hitOn, 6)
        XCTAssertEqual(pds.spaceCannon?.count, 1)
    }

    func testDestroyerHasAFB() throws {
        let units = try decodeUnits()
        let destroyer = try XCTUnwrap(units.first { $0.id == "destroyer" })
        XCTAssertNotNil(destroyer.antiFighterBarrage)
        XCTAssertEqual(destroyer.antiFighterBarrage?.hitOn, 9)
    }

    func testSpaceDockHasProduction() throws {
        let units = try decodeUnits()
        let dock = try XCTUnwrap(units.first { $0.id == "space_dock" })
        XCTAssertNotNil(dock.productionValue)
        XCTAssertEqual(dock.productionValue, 2)
    }

    func testInfantryNoSpecialAbilities() throws {
        let units = try decodeUnits()
        let infantry = try XCTUnwrap(units.first { $0.id == "infantry" })
        XCTAssertNil(infantry.bombardment)
        XCTAssertNil(infantry.spaceCannon)
        XCTAssertNil(infantry.antiFighterBarrage)
        XCTAssertFalse(infantry.sustainDamage)
    }

    func testWarSun() throws {
        let units = try decodeUnits()
        let ws = try XCTUnwrap(units.first { $0.id == "war_sun" })
        XCTAssertEqual(ws.cost, 12)
        XCTAssertEqual(ws.combat, 3)
        XCTAssertTrue(ws.sustainDamage)
        XCTAssertNotNil(ws.bombardment)
        XCTAssertEqual(ws.capacity, 6)
    }

    func testMech() throws {
        let units = try decodeUnits()
        let mech = try XCTUnwrap(units.first { $0.id == "mech" })
        XCTAssertEqual(mech.cost, 2)
        XCTAssertEqual(mech.combat, 6)
        XCTAssertTrue(mech.sustainDamage)
    }

    // MARK: - Action Card Tests

    func testDecodeActionCards() throws {
        let data = try loadJSON("action_cards")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let cards = try decoder.decode([ActionCard].self, from: data)
        XCTAssertGreaterThanOrEqual(cards.count, 80, "Should have at least 80 action cards")
    }

    func testActionCardPhases() throws {
        let cards = try decodeActionCards()
        let phases = Set(cards.map { $0.phase })
        XCTAssertTrue(phases.contains("Action"))
        XCTAssertTrue(phases.contains("Combat"))
        XCTAssertTrue(phases.contains("Agenda"))
    }

    func testSabotageCard() throws {
        let cards = try decodeActionCards()
        let sabotage = try XCTUnwrap(cards.first { $0.id == "sabotage" })
        XCTAssertEqual(sabotage.name, "Sabotage")
        XCTAssertEqual(sabotage.phase, "Action")
    }

    // MARK: - Agenda Card Tests

    func testDecodeAgendaCards() throws {
        let data = try loadJSON("agenda_cards")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let cards = try decoder.decode([AgendaCard].self, from: data)
        XCTAssertGreaterThanOrEqual(cards.count, 50, "Should have at least 50 agenda cards")
    }

    func testAgendaTypeDistribution() throws {
        let cards = try decodeAgendaCards()
        let laws = cards.filter { $0.type == .law }
        let directives = cards.filter { $0.type == .directive }
        XCTAssertGreaterThan(laws.count, 0, "Should have law agenda cards")
        XCTAssertGreaterThan(directives.count, 0, "Should have directive agenda cards")
    }

    func testMutinyAgenda() throws {
        let cards = try decodeAgendaCards()
        let mutiny = try XCTUnwrap(cards.first { $0.id == "mutiny" })
        XCTAssertEqual(mutiny.type, .directive)
    }

    // MARK: - GameDataStore Tests

    @MainActor
    func testGameDataStoreLoad() throws {
        let store = GameDataStore()
        store.load()
        XCTAssertEqual(store.factions.count, 25)
        XCTAssertGreaterThanOrEqual(store.technologies.count, 70)
        XCTAssertGreaterThanOrEqual(store.systemTiles.count, 80)
        XCTAssertEqual(store.units.count, 11)
        XCTAssertGreaterThanOrEqual(store.actionCards.count, 80)
        XCTAssertGreaterThanOrEqual(store.agendaCards.count, 50)
    }

    @MainActor
    func testGameDataStoreRelationships() throws {
        let store = GameDataStore()
        store.load()

        // Sol's starting tech should exist in the technology list
        let sol = try XCTUnwrap(store.factions.first { $0.id == "sol" })
        for techName in sol.startingTech {
            XCTAssertTrue(
                store.technologies.contains { $0.name == techName },
                "Starting tech '\(techName)' should exist in technologies list"
            )
        }

        // Mecatol Rex tile should exist
        let mecatol = store.systemTiles.first { $0.tileNumber == 18 }
        XCTAssertNotNil(mecatol)
        XCTAssertEqual(mecatol?.planets.first?.name, "Mecatol Rex")
    }

    @MainActor
    func testAllFactionStartingTechsExist() throws {
        let store = GameDataStore()
        store.load()
        let techNames = Set(store.technologies.map { $0.name })
        for faction in store.factions {
            for tech in faction.startingTech {
                XCTAssertTrue(techNames.contains(tech),
                    "\(faction.name) starting tech '\(tech)' not found in technologies")
            }
        }
    }

    // MARK: - Helpers

    private func loadJSON(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private func decodeFactions() throws -> [Faction] {
        let data = try loadJSON("factions")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Faction].self, from: data)
    }

    private func decodeTechnologies() throws -> [Technology] {
        let data = try loadJSON("technologies")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Technology].self, from: data)
    }

    private func decodeSystemTiles() throws -> [SystemTile] {
        let data = try loadJSON("system_tiles")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([SystemTile].self, from: data)
    }

    private func decodeUnits() throws -> [UnitBlueprint] {
        let data = try loadJSON("units")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([UnitBlueprint].self, from: data)
    }

    private func decodeActionCards() throws -> [ActionCard] {
        let data = try loadJSON("action_cards")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([ActionCard].self, from: data)
    }

    private func decodeAgendaCards() throws -> [AgendaCard] {
        let data = try loadJSON("agenda_cards")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([AgendaCard].self, from: data)
    }
}
