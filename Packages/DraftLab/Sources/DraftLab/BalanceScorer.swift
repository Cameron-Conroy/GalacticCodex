import Foundation

/// Scores slices and evaluates draft fairness.
public struct BalanceScorer {
    /// Score a slice: higher = more desirable. Uses the community optimal value formula.
    public static func score(_ slice: Slice) -> Double {
        slice.optimalValue
    }

    /// Rate overall draft fairness as the standard deviation of slice scores.
    /// Lower = fairer. Returns 0 for empty input.
    public static func fairness(slices: [Slice]) -> Double {
        guard !slices.isEmpty else { return 0 }
        let scores = slices.map { score($0) }
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(scores.count)
        return variance.squareRoot()
    }
}
