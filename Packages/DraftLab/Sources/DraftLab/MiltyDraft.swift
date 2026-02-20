import Foundation

/// A single planet's resource/influence values within a slice tile.
public struct SlicePlanet: Equatable, Sendable {
    public let resources: Int
    public let influence: Int

    public init(resources: Int, influence: Int) {
        self.resources = resources
        self.influence = influence
    }
}

/// A tile in a draft slice, containing zero or more planets.
public struct SliceTile: Equatable, Sendable {
    public let tileNumber: Int
    public let planets: [SlicePlanet]

    public init(tileNumber: Int, planets: [SlicePlanet]) {
        self.tileNumber = tileNumber
        self.planets = planets
    }
}

/// A 5-tile slice for a single player in the Milty Draft.
public struct Slice: Identifiable, Equatable, Sendable {
    public let id: Int
    public let tiles: [SliceTile]

    public var totalResources: Int {
        tiles.flatMap(\.planets).reduce(0) { $0 + $1.resources }
    }

    public var totalInfluence: Int {
        tiles.flatMap(\.planets).reduce(0) { $0 + $1.influence }
    }

    /// Community formula: resources * 0.6 + influence * 0.4
    public var optimalValue: Double {
        Double(totalResources) * 0.6 + Double(totalInfluence) * 0.4
    }

    public init(id: Int, tiles: [SliceTile]) {
        self.id = id
        self.tiles = tiles
    }
}

/// Core Milty Draft slice generation engine.
public final class MiltyDraft: ObservableObject {
    @Published public var slices: [Slice] = []
    @Published public var playerCount: Int = 6

    public init() {}

    /// Generate balanced slices from available tiles.
    ///
    /// Returns empty array if there aren't enough tiles (need count * 5).
    /// Shuffles tiles and uses greedy balancing to distribute them into slices.
    public func generateSlices(from tiles: [SliceTile], count: Int) -> [Slice] {
        let tilesPerSlice = 5
        guard tiles.count >= count * tilesPerSlice else { return [] }

        var pool = tiles.shuffled()
        // Sort by optimal value descending for serpentine drafting
        pool.sort { tileValue($0) > tileValue($1) }

        // Initialize empty slice buckets
        var buckets: [[SliceTile]] = Array(repeating: [], count: count)
        var bucketValues: [Double] = Array(repeating: 0, count: count)

        // Greedy assignment: assign each tile to the slice with lowest current value
        let needed = count * tilesPerSlice
        for tile in pool.prefix(needed) {
            let minIndex = bucketValues.enumerated().min(by: {
                if $0.element == $1.element { return $0.offset < $1.offset }
                return $0.element < $1.element
            })!.offset
            buckets[minIndex].append(tile)
            bucketValues[minIndex] += tileValue(tile)
        }

        let result = buckets.enumerated().map { Slice(id: $0.offset, tiles: $0.element) }
        slices = result
        return result
    }

    private func tileValue(_ tile: SliceTile) -> Double {
        let r = tile.planets.reduce(0) { $0 + $1.resources }
        let i = tile.planets.reduce(0) { $0 + $1.influence }
        return Double(r) * 0.6 + Double(i) * 0.4
    }
}
