import Foundation
import SwiftData
import Chronicle

/// SwiftData model for persisting Chronicle game sessions.
@Model
final class PersistedSession {
    var title: String
    var createdAt: Date
    var sessionData: Data

    init(title: String, createdAt: Date, sessionData: Data) {
        self.title = title
        self.createdAt = createdAt
        self.sessionData = sessionData
    }

    /// Decode the stored GameSession.
    func toGameSession() -> GameSession? {
        try? JSONDecoder().decode(GameSession.self, from: sessionData)
    }

    /// Create from a GameSession.
    convenience init(from session: GameSession) {
        let data = (try? JSONEncoder().encode(session)) ?? Data()
        self.init(title: session.title, createdAt: session.createdAt, sessionData: data)
    }
}
