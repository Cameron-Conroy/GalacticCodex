import Foundation
import Observation

/// The current phase of a ban/pick draft.
public enum DraftPhase: Equatable {
    case setup
    case banning(playerIndex: Int)
    case picking(playerIndex: Int)
    case complete
}

/// State machine for the ban/pick faction draft flow.
@Observable
public final class DraftStateMachine {
    public var phase: DraftPhase = .setup
    public var availableFactions: [String] = []
    public var bannedFactions: [String] = []
    public var picks: [String: String] = [:]

    public let playerNames: [String]
    public let bansPerPlayer: Int

    private var banCount = 0

    public init(playerNames: [String], factions: [String], bansPerPlayer: Int) {
        self.playerNames = playerNames
        self.bansPerPlayer = bansPerPlayer
        self.availableFactions = factions
    }

    /// Begin the draft. Moves to banning (or picking if bansPerPlayer == 0).
    public func start() {
        banCount = 0
        bannedFactions = []
        picks = [:]
        if bansPerPlayer > 0 {
            phase = .banning(playerIndex: 0)
        } else {
            phase = .picking(playerIndex: 0)
        }
    }

    /// Ban a faction during the banning phase. No-op if faction already banned or not in banning phase.
    public func ban(faction: String) {
        guard case .banning = phase else { return }
        guard availableFactions.contains(faction), !bannedFactions.contains(faction) else { return }

        availableFactions.removeAll { $0 == faction }
        bannedFactions.append(faction)
        banCount += 1

        let totalBans = playerNames.count * bansPerPlayer
        if banCount >= totalBans {
            phase = .picking(playerIndex: 0)
        } else {
            let playerIndex = banCount / bansPerPlayer
            phase = .banning(playerIndex: playerIndex)
        }
    }

    /// Pick a faction during the picking phase. No-op if faction unavailable or not in picking phase.
    public func pick(faction: String) {
        guard case let .picking(playerIndex) = phase else { return }
        guard availableFactions.contains(faction) else { return }
        guard !picks.values.contains(faction) else { return }

        let player = playerNames[playerIndex]
        picks[player] = faction
        availableFactions.removeAll { $0 == faction }

        let nextIndex = playerIndex + 1
        if nextIndex >= playerNames.count {
            phase = .complete
        } else {
            phase = .picking(playerIndex: nextIndex)
        }
    }

    /// Randomly assign factions to players, excluding specified factions.
    /// Returns empty dictionary if not enough factions are available.
    public static func randomAssignment(
        players: [String],
        factions: [String],
        excluding: Set<String>
    ) -> [String: String] {
        let pool = factions.filter { !excluding.contains($0) }.shuffled()
        guard pool.count >= players.count else { return [:] }
        return Dictionary(uniqueKeysWithValues: zip(players, pool))
    }
}
