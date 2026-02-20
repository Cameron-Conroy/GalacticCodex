import Foundation
import ClaudeAPI

/// Manages the chat conversation history for the Advisor.
@MainActor
public final class ConversationManager: ObservableObject {
    @Published public private(set) var messages: [ChatDisplayMessage] = []

    public init() {}

    /// A single message in the chat display.
    public struct ChatDisplayMessage: Identifiable {
        public let id: UUID
        public let role: ChatMessage.Role
        public let content: String
        public let timestamp: Date

        public init(id: UUID = UUID(), role: ChatMessage.Role, content: String, timestamp: Date = Date()) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }
    }

    /// Append a user message.
    public func addUserMessage(_ text: String) {
        messages.append(ChatDisplayMessage(role: .user, content: text))
    }

    /// Append an assistant message.
    public func addAssistantMessage(_ text: String) {
        messages.append(ChatDisplayMessage(role: .assistant, content: text))
    }

    /// Convert display messages to API-compatible ChatMessages.
    public func toChatMessages() -> [ChatMessage] {
        messages.map { ChatMessage(role: $0.role, content: $0.content) }
    }

    /// Clear all messages.
    public func clear() {
        messages.removeAll()
    }
}
