import XCTest
@testable import Chronicle

final class ChronicleTests: XCTestCase {

    // MARK: - GameEvent Encoding/Decoding

    func testGameEventRoundTrip() throws {
        let event = GameEvent(
            type: .battle,
            involvedFactions: ["sol", "hacan"],
            systemName: "Mecatol Rex",
            note: "Epic fleet clash"
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(GameEvent.self, from: data)

        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.type, .battle)
        XCTAssertEqual(decoded.involvedFactions, ["sol", "hacan"])
        XCTAssertEqual(decoded.systemName, "Mecatol Rex")
        XCTAssertEqual(decoded.note, "Epic fleet clash")
    }

    func testGameEventAllTypes() {
        let types = GameEvent.EventType.allCases
        XCTAssertEqual(types.count, 6)
        XCTAssertTrue(types.contains(.battle))
        XCTAssertTrue(types.contains(.trade))
        XCTAssertTrue(types.contains(.agenda))
        XCTAssertTrue(types.contains(.objective))
        XCTAssertTrue(types.contains(.betrayal))
        XCTAssertTrue(types.contains(.alliance))
    }

    func testGameSessionRoundTrip() throws {
        var session = GameSession(title: "Test Game")
        session.playerFactions = ["Alice": "sol", "Bob": "hacan"]
        session.events = [
            GameEvent(type: .trade, involvedFactions: ["sol", "hacan"], note: "3 for 3")
        ]
        session.narrative = "A great trade was made."

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(GameSession.self, from: data)

        XCTAssertEqual(decoded.title, "Test Game")
        XCTAssertEqual(decoded.playerFactions.count, 2)
        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.narrative, "A great trade was made.")
    }

    // MARK: - Prompt Builder

    func testPromptContainsSessionTitle() {
        let session = GameSession(title: "Galactic War #7")
        let prompt = ChroniclePromptBuilder.buildPrompt(session: session, tone: .epic)
        XCTAssertTrue(prompt.contains("Galactic War #7"))
    }

    func testPromptContainsEvents() {
        var session = GameSession(title: "Test")
        session.events = [
            GameEvent(type: .battle, involvedFactions: ["sol", "hacan"], systemName: "Mecatol Rex"),
            GameEvent(type: .trade, involvedFactions: ["jol_nar"], note: "Tech trade")
        ]

        let prompt = ChroniclePromptBuilder.buildPrompt(session: session, tone: .documentary)

        XCTAssertTrue(prompt.contains("BATTLE"))
        XCTAssertTrue(prompt.contains("sol vs hacan"))
        XCTAssertTrue(prompt.contains("Mecatol Rex"))
        XCTAssertTrue(prompt.contains("TRADE"))
        XCTAssertTrue(prompt.contains("Tech trade"))
    }

    func testPromptContainsPlayers() {
        var session = GameSession(title: "Test")
        session.playerFactions = ["Alice": "sol", "Bob": "hacan"]

        let prompt = ChroniclePromptBuilder.buildPrompt(session: session, tone: .noir)

        XCTAssertTrue(prompt.contains("Alice"))
        XCTAssertTrue(prompt.contains("sol"))
        XCTAssertTrue(prompt.contains("Bob"))
        XCTAssertTrue(prompt.contains("hacan"))
    }

    func testPromptContainsTone() {
        let session = GameSession(title: "Test")
        for tone in NarrativeTone.allCases {
            let prompt = ChroniclePromptBuilder.buildPrompt(session: session, tone: tone)
            XCTAssertTrue(prompt.contains(tone.rawValue), "Prompt missing tone: \(tone.rawValue)")
        }
    }

    func testSystemPromptMatchesTone() {
        let epic = ChroniclePromptBuilder.systemPrompt(for: .epic)
        XCTAssertTrue(epic.contains("epic"))
        XCTAssertTrue(epic.contains("Twilight Imperium"))

        let noir = ChroniclePromptBuilder.systemPrompt(for: .noir)
        XCTAssertTrue(noir.contains("noir"))

        let comedic = ChroniclePromptBuilder.systemPrompt(for: .comedic)
        XCTAssertTrue(comedic.contains("witty"))

        let documentary = ChroniclePromptBuilder.systemPrompt(for: .documentary)
        XCTAssertTrue(documentary.contains("historian"))
    }

    func testAllNarrativeTones() {
        XCTAssertEqual(NarrativeTone.allCases.count, 4)
    }
}
