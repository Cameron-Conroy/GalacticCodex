import XCTest
@testable import Advisor
import ClaudeAPI

final class AdvisorTests: XCTestCase {

    // MARK: - AdvisorPromptBuilder

    func testPromptContainsFactionId() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 1
        )
        XCTAssertTrue(prompt.contains("sol"))
    }

    func testPromptContainsNeighbors() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: ["hacan", "jol_nar"],
            currentRound: 3
        )
        XCTAssertTrue(prompt.contains("hacan"))
        XCTAssertTrue(prompt.contains("jol_nar"))
        XCTAssertTrue(prompt.contains("Neighbors"))
    }

    func testPromptEmptyNeighborsOmitsSection() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 1
        )
        XCTAssertFalse(prompt.contains("Neighbors"))
    }

    func testPromptEarlyGameStrategy() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 1
        )
        XCTAssertTrue(prompt.contains("Early Game"))
    }

    func testPromptMidGameStrategy() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 3
        )
        XCTAssertTrue(prompt.contains("Mid Game"))
    }

    func testPromptLateGameStrategy() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 5
        )
        XCTAssertTrue(prompt.contains("Late Game"))
    }

    func testPromptContainsRoundNumber() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 4
        )
        XCTAssertTrue(prompt.contains("Round: 4"))
    }

    func testPromptIncludesTI4Reference() {
        let prompt = AdvisorPromptBuilder.buildSystemPrompt(
            factionId: "sol",
            neighbors: [],
            currentRound: 1
        )
        XCTAssertTrue(prompt.contains("Twilight Imperium 4th Edition"))
    }

    // MARK: - ConversationManager

    @MainActor
    func testAddUserMessage() {
        let manager = ConversationManager()
        manager.addUserMessage("Hello")

        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertEqual(manager.messages[0].role, .user)
        XCTAssertEqual(manager.messages[0].content, "Hello")
    }

    @MainActor
    func testAddAssistantMessage() {
        let manager = ConversationManager()
        manager.addAssistantMessage("Hi there")

        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertEqual(manager.messages[0].role, .assistant)
        XCTAssertEqual(manager.messages[0].content, "Hi there")
    }

    @MainActor
    func testMessageOrdering() {
        let manager = ConversationManager()
        manager.addUserMessage("First")
        manager.addAssistantMessage("Second")
        manager.addUserMessage("Third")

        XCTAssertEqual(manager.messages.count, 3)
        XCTAssertEqual(manager.messages[0].content, "First")
        XCTAssertEqual(manager.messages[1].content, "Second")
        XCTAssertEqual(manager.messages[2].content, "Third")
    }

    @MainActor
    func testToChatMessages() {
        let manager = ConversationManager()
        manager.addUserMessage("Question")
        manager.addAssistantMessage("Answer")

        let chatMessages = manager.toChatMessages()

        XCTAssertEqual(chatMessages.count, 2)
        XCTAssertEqual(chatMessages[0].role, .user)
        XCTAssertEqual(chatMessages[0].content, "Question")
        XCTAssertEqual(chatMessages[1].role, .assistant)
        XCTAssertEqual(chatMessages[1].content, "Answer")
    }

    @MainActor
    func testClear() {
        let manager = ConversationManager()
        manager.addUserMessage("Hello")
        manager.addAssistantMessage("Hi")
        manager.clear()

        XCTAssertTrue(manager.messages.isEmpty)
    }

    @MainActor
    func testMessagesHaveUniqueIds() {
        let manager = ConversationManager()
        manager.addUserMessage("A")
        manager.addUserMessage("B")

        XCTAssertNotEqual(manager.messages[0].id, manager.messages[1].id)
    }
}
