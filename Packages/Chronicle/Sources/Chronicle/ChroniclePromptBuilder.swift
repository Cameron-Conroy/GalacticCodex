import Foundation

/// Narrative tone for the generated chronicle.
public enum NarrativeTone: String, CaseIterable, Identifiable {
    case epic, comedic, noir, documentary

    public var id: String { rawValue }

    var personaDescription: String {
        switch self {
        case .epic:
            return "You are an epic chronicler of galactic history. Write with grandeur, dramatic tension, and heroic language befitting a space opera saga."
        case .comedic:
            return "You are a witty, irreverent narrator recounting a chaotic board game night in space. Use humor, sarcasm, and playful exaggeration."
        case .noir:
            return "You are a hard-boiled detective narrating galactic intrigue. Write in a gritty, cynical noir style with atmospheric descriptions and world-weary observations."
        case .documentary:
            return "You are a neutral historian documenting galactic events. Write in a measured, analytical style with factual precision and strategic commentary."
        }
    }
}

/// Builds prompts for Claude to generate session narratives.
public struct ChroniclePromptBuilder {
    /// Build a Claude prompt from a game session and narrative tone.
    public static func buildPrompt(session: GameSession, tone: NarrativeTone) -> String {
        var lines: [String] = []

        lines.append("# Session: \(session.title)")
        lines.append("")

        if !session.playerFactions.isEmpty {
            lines.append("## Players")
            for (player, faction) in session.playerFactions.sorted(by: { $0.key < $1.key }) {
                lines.append("- \(player): \(faction)")
            }
            lines.append("")
        }

        lines.append("## Event Timeline")
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        for event in session.events {
            var entry = "[\(formatter.string(from: event.timestamp))] \(event.type.rawValue.uppercased())"
            if !event.involvedFactions.isEmpty {
                entry += " — \(event.involvedFactions.joined(separator: " vs "))"
            }
            if let system = event.systemName {
                entry += " in \(system)"
            }
            if let note = event.note {
                entry += ": \(note)"
            }
            lines.append("- \(entry)")
        }

        lines.append("")
        lines.append("Write a narrative of 500–1000 words in the \(tone.rawValue) style, transforming these events into a compelling story.")

        return lines.joined(separator: "\n")
    }

    /// Build the system prompt for the chosen tone.
    public static func systemPrompt(for tone: NarrativeTone) -> String {
        "\(tone.personaDescription) You are narrating events from a game of Twilight Imperium 4th Edition."
    }
}
