import Foundation
import TI4Data

/// A searchable result from the Codex.
public struct CodexSearchResult: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let category: CodexCategory
    public let description: String
}

/// Categories of searchable content.
public enum CodexCategory: String, CaseIterable, Equatable {
    case faction = "Faction"
    case technology = "Technology"
    case actionCard = "Action Card"
    case agendaCard = "Agenda Card"
}

/// Full-text search engine over TI4 game data.
public final class CodexSearchEngine {
    private var entries: [CodexSearchResult] = []

    public init() {}

    /// Indexes all game data for searching.
    public func index(
        factions: [Faction],
        technologies: [Technology],
        actionCards: [ActionCard],
        agendaCards: [AgendaCard]
    ) {
        entries = []

        entries += factions.map { f in
            let abilityText = f.abilities.map { "\($0.name) \($0.description)" }.joined(separator: " ")
            return CodexSearchResult(
                id: f.id,
                title: f.name,
                subtitle: "\(f.expansion.capitalized) Faction — \(f.commodities) Commodities",
                category: .faction,
                description: abilityText
            )
        }

        entries += technologies.map { t in
            CodexSearchResult(
                id: t.id,
                title: t.name,
                subtitle: "\(t.type.displayName) Technology",
                category: .technology,
                description: t.description
            )
        }

        entries += actionCards.map { c in
            CodexSearchResult(
                id: c.id,
                title: c.name,
                subtitle: "\(c.phase) Phase",
                category: .actionCard,
                description: c.description
            )
        }

        entries += agendaCards.map { a in
            CodexSearchResult(
                id: a.id,
                title: a.name,
                subtitle: a.type == .law ? "Law" : "Directive",
                category: .agendaCard,
                description: a.description
            )
        }
    }

    /// Searches indexed data by matching query against title and description.
    public func search(_ query: String) -> [CodexSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let lowered = trimmed.lowercased()
        return entries.filter { entry in
            entry.title.lowercased().contains(lowered) ||
            entry.description.lowercased().contains(lowered) ||
            entry.subtitle.lowercased().contains(lowered)
        }
    }
}

extension Technology.TechType {
    var displayName: String {
        switch self {
        case .biotic: return "Biotic"
        case .warfare: return "Warfare"
        case .propulsion: return "Propulsion"
        case .cybernetic: return "Cybernetic"
        case .unitUpgrade: return "Unit Upgrade"
        }
    }
}
