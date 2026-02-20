import XCTest
@testable import Codex
import TI4Data

final class CodexSearchTests: XCTestCase {
    var engine: CodexSearchEngine!

    override func setUp() {
        engine = CodexSearchEngine()
    }

    func testEmptyQueryReturnsNoResults() {
        let results = engine.search("")
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchFactionByName() {
        let factions = [
            Faction(id: "sol", name: "Federation of Sol", expansion: "base", commodities: 4, startingTech: ["Neural Motivator", "Antimass Deflectors"], abilities: [Faction.Ability(name: "Orbital Drop", description: "Test")], promissoryNote: "Political Favor", flagship: "Genesis"),
            Faction(id: "hacan", name: "Emirates of Hacan", expansion: "base", commodities: 6, startingTech: ["Antimass Deflectors", "Sarween Tools"], abilities: [], promissoryNote: "Trade Convoys", flagship: "Wrath of Kenara"),
        ]
        engine.index(factions: factions, technologies: [], actionCards: [], agendaCards: [])

        let results = engine.search("Sol")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Federation of Sol")
        XCTAssertEqual(results.first?.category, .faction)
    }

    func testSearchTechnologyByName() {
        let techs = [
            Technology(id: "neural_motivator", name: "Neural Motivator", type: .biotic, faction: nil, prerequisites: [], description: "During the status phase, draw 2 action cards instead of 1."),
            Technology(id: "plasma_scoring", name: "Plasma Scoring", type: .warfare, faction: nil, prerequisites: [], description: "+1 to bombardment and Space Cannon rolls."),
        ]
        engine.index(factions: [], technologies: techs, actionCards: [], agendaCards: [])

        let results = engine.search("plasma")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Plasma Scoring")
        XCTAssertEqual(results.first?.category, .technology)
    }

    func testSearchIsCaseInsensitive() {
        let techs = [
            Technology(id: "gravity_drive", name: "Gravity Drive", type: .propulsion, faction: nil, prerequisites: [.propulsion], description: "After you activate a system, apply +1 to the move value of 1 of your ships during this tactical action."),
        ]
        engine.index(factions: [], technologies: techs, actionCards: [], agendaCards: [])

        let upper = engine.search("GRAVITY")
        let lower = engine.search("gravity")
        XCTAssertEqual(upper.count, lower.count)
        XCTAssertEqual(upper.first?.title, "Gravity Drive")
    }

    func testSearchMatchesDescription() {
        let cards = [
            ActionCard(id: "sabotage", name: "Sabotage", phase: "Action", description: "When another player plays an action card: Cancel that action card."),
        ]
        engine.index(factions: [], technologies: [], actionCards: cards, agendaCards: [])

        let results = engine.search("cancel")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Sabotage")
    }

    func testSearchAgendaCards() {
        let agendas = [
            AgendaCard(id: "classified_document_leaks", name: "Classified Document Leaks", type: .directive, description: "When this agenda is revealed, each player who has the most victory points discards all of their action cards."),
        ]
        engine.index(factions: [], technologies: [], actionCards: [], agendaCards: agendas)

        let results = engine.search("classified")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.category, .agendaCard)
    }

    func testSearchReturnsMultipleCategories() {
        let factions = [
            Faction(id: "sol", name: "Federation of Sol", expansion: "base", commodities: 4, startingTech: [], abilities: [Faction.Ability(name: "Orbital Drop", description: "Action: Spend 1 token to place 2 infantry on a planet you control.")], promissoryNote: "Political Favor", flagship: "Genesis"),
        ]
        let cards = [
            ActionCard(id: "uprising", name: "Uprising", phase: "Action", description: "Exhaust a planet controlled by another player. Then, gain trade goods equal to its resource value."),
        ]
        engine.index(factions: factions, technologies: [], actionCards: cards, agendaCards: [])

        // "action" matches the action card phase and Sol's ability description
        let results = engine.search("action")
        XCTAssertTrue(results.count >= 1)
    }

    func testSearchResultContainsSubtitle() {
        let techs = [
            Technology(id: "daxcive_animators", name: "Daxcive Animators", type: .biotic, faction: nil, prerequisites: [.biotic], description: "After you win a ground combat, you may place 1 infantry from your reinforcements on that planet."),
        ]
        engine.index(factions: [], technologies: techs, actionCards: [], agendaCards: [])

        let results = engine.search("daxcive")
        XCTAssertEqual(results.first?.subtitle, "Biotic Technology")
    }
}
