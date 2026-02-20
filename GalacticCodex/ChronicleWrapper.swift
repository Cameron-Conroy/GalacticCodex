import SwiftUI
import SwiftData
import Chronicle

/// Bridges SwiftData persistence to the Chronicle package's view.
struct ChronicleWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersistedSession.createdAt, order: .reverse) private var persisted: [PersistedSession]

    var body: some View {
        ChronicleView(
            savedSessions: persisted.compactMap { $0.toGameSession() },
            onSave: { session in
                let stored = PersistedSession(from: session)
                modelContext.insert(stored)
            }
        )
    }
}
