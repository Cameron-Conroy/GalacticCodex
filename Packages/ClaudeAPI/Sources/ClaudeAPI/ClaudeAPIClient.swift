import Foundation

/// Client for the Anthropic Claude Messages API.
public final class ClaudeAPIClient: Sendable {
    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Sends a message to Claude and returns the response text.
    public func sendMessage(
        systemPrompt: String,
        messages: [ChatMessage],
        maxTokens: Int = 4096,
        model: String = "claude-sonnet-4-20250514"
    ) async throws -> String {
        let body = MessageRequest(
            model: model,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) }
        )

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAPIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
        return messageResponse.content.first?.text ?? ""
    }
}

// MARK: - Public Types

public struct ChatMessage: Codable, Sendable {
    public let role: Role
    public let content: String

    public enum Role: String, Codable, Sendable {
        case user, assistant
    }

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

public enum ClaudeAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}

// MARK: - Internal Request/Response Types

struct MessageRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system, messages
    }
}

struct MessageResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let text: String
    }
}
