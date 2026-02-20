import Foundation

/// Builds system prompts for the TI4 strategy advisor.
public struct AdvisorPromptBuilder {
    /// Build a system prompt with faction-specific strategy guidance.
    public static func buildSystemPrompt(
        factionId: String,
        neighbors: [String],
        currentRound: Int
    ) -> String {
        var lines: [String] = []

        lines.append("You are an expert Twilight Imperium 4th Edition strategy advisor.")
        lines.append("The player is controlling \(factionId).")
        lines.append("")

        lines.append("## Your Role")
        lines.append("- Provide specific, actionable strategy advice")
        lines.append("- Consider the player's faction strengths and weaknesses")
        lines.append("- Account for neighbor dynamics and diplomacy")
        lines.append("- Suggest optimal technology paths for this faction")
        lines.append("- Recommend action card and agenda strategies")
        lines.append("")

        if !neighbors.isEmpty {
            lines.append("## Neighbors")
            lines.append("The player's neighbors are: \(neighbors.joined(separator: ", ")).")
            lines.append("Consider how to interact with each neighbor — potential trades, threats, and alliances.")
            lines.append("")
        }

        lines.append("## Current Game State")
        lines.append("Round: \(currentRound) of ~6")
        lines.append("")

        lines.append(roundStrategy(for: currentRound))

        lines.append("")
        lines.append("Be concise and strategic. Reference specific game mechanics (strategy cards, tech, objectives) in your advice.")

        return lines.joined(separator: "\n")
    }

    private static func roundStrategy(for round: Int) -> String {
        switch round {
        case 1...2:
            return """
            ## Phase: Early Game
            Focus on: expanding to nearby systems, claiming key planets, researching foundational tech, and establishing economy. Avoid unnecessary conflict.
            """
        case 3...4:
            return """
            ## Phase: Mid Game
            Focus on: scoring public objectives, positioning for Mecatol Rex, building fleet presence, negotiating trade agreements, and researching advanced tech.
            """
        default:
            return """
            ## Phase: Late Game
            Focus on: scoring remaining objectives, kingmaking dynamics, timing the final push for victory points, and leveraging accumulated resources for decisive moves.
            """
        }
    }
}
