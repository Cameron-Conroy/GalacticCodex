import XCTest
@testable import DraftLab

// MARK: - Test Helpers

private func makeTile(_ number: Int, planets: [(Int, Int)]) -> SliceTile {
    SliceTile(tileNumber: number, planets: planets.map { .init(resources: $0.0, influence: $0.1) })
}

private func makeSlice(id: Int, tiles: [SliceTile]) -> Slice {
    Slice(id: id, tiles: tiles)
}

// MARK: - SliceTile Tests

final class SliceTileTests: XCTestCase {
    func testPlanetResourcesAndInfluence() {
        let tile = makeTile(19, planets: [(2, 3), (1, 1)])
        XCTAssertEqual(tile.planets.count, 2)
        XCTAssertEqual(tile.planets[0].resources, 2)
        XCTAssertEqual(tile.planets[0].influence, 3)
    }

    func testEmptyTileHasNoPlanets() {
        let tile = makeTile(42, planets: [])
        XCTAssertTrue(tile.planets.isEmpty)
    }

    func testTileEquality() {
        let a = makeTile(19, planets: [(2, 3)])
        let b = makeTile(19, planets: [(2, 3)])
        XCTAssertEqual(a, b)
    }

    func testTileInequality() {
        let a = makeTile(19, planets: [(2, 3)])
        let b = makeTile(20, planets: [(2, 3)])
        XCTAssertNotEqual(a, b)
    }
}

// MARK: - Slice Tests

final class SliceTests: XCTestCase {
    func testTotalResources() {
        let slice = makeSlice(id: 0, tiles: [
            makeTile(1, planets: [(3, 1)]),
            makeTile(2, planets: [(2, 2), (1, 0)]),
        ])
        XCTAssertEqual(slice.totalResources, 6) // 3 + 2 + 1
    }

    func testTotalInfluence() {
        let slice = makeSlice(id: 0, tiles: [
            makeTile(1, planets: [(0, 4)]),
            makeTile(2, planets: [(1, 2), (0, 1)]),
        ])
        XCTAssertEqual(slice.totalInfluence, 7) // 4 + 2 + 1
    }

    func testOptimalValue() {
        // resources=5, influence=3 → 5*0.6 + 3*0.4 = 3.0 + 1.2 = 4.2
        let slice = makeSlice(id: 0, tiles: [
            makeTile(1, planets: [(3, 1)]),
            makeTile(2, planets: [(2, 2)]),
        ])
        XCTAssertEqual(slice.optimalValue, 4.2, accuracy: 0.001)
    }

    func testEmptySliceHasZeroValues() {
        let slice = makeSlice(id: 0, tiles: [])
        XCTAssertEqual(slice.totalResources, 0)
        XCTAssertEqual(slice.totalInfluence, 0)
        XCTAssertEqual(slice.optimalValue, 0.0)
    }

    func testSliceEquality() {
        let a = makeSlice(id: 1, tiles: [makeTile(10, planets: [(2, 3)])])
        let b = makeSlice(id: 1, tiles: [makeTile(10, planets: [(2, 3)])])
        XCTAssertEqual(a, b)
    }
}

// MARK: - BalanceScorer Tests

final class BalanceScorerTests: XCTestCase {
    func testScoreHighResources() {
        let highRes = makeSlice(id: 0, tiles: [
            makeTile(1, planets: [(4, 0)]),
            makeTile(2, planets: [(3, 0)]),
            makeTile(3, planets: [(3, 1)]),
        ])
        let balanced = makeSlice(id: 1, tiles: [
            makeTile(4, planets: [(2, 2)]),
            makeTile(5, planets: [(2, 2)]),
            makeTile(6, planets: [(2, 2)]),
        ])
        // High resources slice should score differently than balanced
        let highResScore = BalanceScorer.score(highRes)
        let balancedScore = BalanceScorer.score(balanced)
        XCTAssertNotEqual(highResScore, balancedScore, accuracy: 0.001)
    }

    func testScoreIsPositive() {
        let slice = makeSlice(id: 0, tiles: [makeTile(1, planets: [(2, 3)])])
        XCTAssertGreaterThan(BalanceScorer.score(slice), 0)
    }

    func testEmptySliceScoresZero() {
        let slice = makeSlice(id: 0, tiles: [])
        XCTAssertEqual(BalanceScorer.score(slice), 0.0, accuracy: 0.001)
    }

    func testFairnessOfIdenticalSlices() {
        let slices = (0..<4).map { i in
            makeSlice(id: i, tiles: [makeTile(i + 1, planets: [(2, 2)])])
        }
        // Identical slices → perfect fairness (std dev = 0)
        XCTAssertEqual(BalanceScorer.fairness(slices: slices), 0.0, accuracy: 0.001)
    }

    func testFairnessOfUnevenSlices() {
        let slices = [
            makeSlice(id: 0, tiles: [makeTile(1, planets: [(5, 0)])]),
            makeSlice(id: 1, tiles: [makeTile(2, planets: [(0, 1)])]),
        ]
        let fairness = BalanceScorer.fairness(slices: slices)
        XCTAssertGreaterThan(fairness, 0)
    }

    func testFairnessEmptySlicesIsZero() {
        XCTAssertEqual(BalanceScorer.fairness(slices: []), 0.0, accuracy: 0.001)
    }
}

// MARK: - MiltyDraft Tests

final class MiltyDraftTests: XCTestCase {
    func testGenerateSlicesCount() {
        let draft = MiltyDraft()
        let tiles = (1...30).map { makeTile($0, planets: [(2, 2)]) }
        let slices = draft.generateSlices(from: tiles, count: 6)
        XCTAssertEqual(slices.count, 6)
    }

    func testGenerateSlicesEachHasFiveTiles() {
        let draft = MiltyDraft()
        let tiles = (1...30).map { makeTile($0, planets: [(1, 1)]) }
        let slices = draft.generateSlices(from: tiles, count: 6)
        for slice in slices {
            XCTAssertEqual(slice.tiles.count, 5)
        }
    }

    func testGenerateSlicesNoDuplicateTiles() {
        let draft = MiltyDraft()
        let tiles = (1...30).map { makeTile($0, planets: [(2, 1)]) }
        let slices = draft.generateSlices(from: tiles, count: 6)
        let allTileNumbers = slices.flatMap { $0.tiles.map(\.tileNumber) }
        XCTAssertEqual(Set(allTileNumbers).count, allTileNumbers.count, "No duplicate tiles across slices")
    }

    func testGenerateSlicesWithTooFewTiles() {
        let draft = MiltyDraft()
        let tiles = (1...4).map { makeTile($0, planets: [(2, 2)]) }
        let slices = draft.generateSlices(from: tiles, count: 6)
        XCTAssertTrue(slices.isEmpty, "Should return empty when not enough tiles")
    }

    func testGenerateSlicesAreReasonablyBalanced() {
        let draft = MiltyDraft()
        var tiles: [SliceTile] = []
        for i in 1...30 {
            let res = (i % 4) + 1
            let inf = ((i + 2) % 4) + 1
            tiles.append(makeTile(i, planets: [(res, inf)]))
        }
        let slices = draft.generateSlices(from: tiles, count: 6)
        let scores = slices.map(BalanceScorer.score)
        let maxDiff = (scores.max() ?? 0) - (scores.min() ?? 0)
        // Slices should be somewhat balanced — max difference shouldn't be extreme
        XCTAssertLessThan(maxDiff, 20.0, "Slices should be reasonably balanced")
    }

    func testDefaultPlayerCount() {
        let draft = MiltyDraft()
        XCTAssertEqual(draft.playerCount, 6)
    }
}

// MARK: - DraftStateMachine Tests

final class DraftStateMachineTests: XCTestCase {
    private func makeMachine(
        players: [String] = ["Alice", "Bob", "Charlie"],
        factions: [String] = ["Sol", "Hacan", "Jol-Nar", "Xxcha", "Yin", "Letnev"],
        bansPerPlayer: Int = 1
    ) -> DraftStateMachine {
        DraftStateMachine(playerNames: players, factions: factions, bansPerPlayer: bansPerPlayer)
    }

    func testInitialPhaseIsSetup() {
        let sm = makeMachine()
        XCTAssertEqual(sm.phase, .setup)
    }

    func testStartMovesToBanning() {
        let sm = makeMachine()
        sm.start()
        XCTAssertEqual(sm.phase, .banning(playerIndex: 0))
    }

    func testBanRemovesFaction() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        XCTAssertTrue(sm.bannedFactions.contains("Sol"))
        XCTAssertFalse(sm.availableFactions.contains("Sol"))
    }

    func testBanAdvancesToNextPlayer() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        XCTAssertEqual(sm.phase, .banning(playerIndex: 1))
    }

    func testAllBansCompleteTransitionsToPicking() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")      // Alice bans
        sm.ban(faction: "Hacan")    // Bob bans
        sm.ban(faction: "Jol-Nar")  // Charlie bans
        XCTAssertEqual(sm.phase, .picking(playerIndex: 0))
    }

    func testPickAssignsFaction() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        sm.ban(faction: "Hacan")
        sm.ban(faction: "Jol-Nar")
        sm.pick(faction: "Xxcha")
        XCTAssertEqual(sm.picks["Alice"], "Xxcha")
    }

    func testPickAdvancesToNextPlayer() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        sm.ban(faction: "Hacan")
        sm.ban(faction: "Jol-Nar")
        sm.pick(faction: "Xxcha")
        XCTAssertEqual(sm.phase, .picking(playerIndex: 1))
    }

    func testAllPicksCompleteTransitionsToComplete() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        sm.ban(faction: "Hacan")
        sm.ban(faction: "Jol-Nar")
        sm.pick(faction: "Xxcha")   // Alice picks
        sm.pick(faction: "Yin")     // Bob picks
        sm.pick(faction: "Letnev")  // Charlie picks
        XCTAssertEqual(sm.phase, .complete)
    }

    func testCannotBanAlreadyBannedFaction() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        // Bob tries to ban Sol again — should be no-op, still banning(1)
        let phaseBefore = sm.phase
        sm.ban(faction: "Sol")
        // Phase should advance since ban was ignored and they need to ban something else
        // Actually the ban of an already-banned faction should be a no-op
        XCTAssertEqual(sm.phase, phaseBefore, "Banning already-banned faction is a no-op")
    }

    func testCannotPickBannedFaction() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        sm.ban(faction: "Hacan")
        sm.ban(faction: "Jol-Nar")
        let phaseBefore = sm.phase
        sm.pick(faction: "Sol") // banned, should be no-op
        XCTAssertEqual(sm.phase, phaseBefore)
    }

    func testCannotPickAlreadyPickedFaction() {
        let sm = makeMachine()
        sm.start()
        sm.ban(faction: "Sol")
        sm.ban(faction: "Hacan")
        sm.ban(faction: "Jol-Nar")
        sm.pick(faction: "Xxcha") // Alice picks
        let phaseBefore = sm.phase
        sm.pick(faction: "Xxcha") // Bob tries same — no-op
        XCTAssertEqual(sm.phase, phaseBefore)
    }

    func testZeroBansGoesDirectlyToPicking() {
        let sm = DraftStateMachine(
            playerNames: ["Alice", "Bob"],
            factions: ["Sol", "Hacan", "Jol-Nar"],
            bansPerPlayer: 0
        )
        sm.start()
        XCTAssertEqual(sm.phase, .picking(playerIndex: 0))
    }

    func testMultipleBansPerPlayer() {
        let sm = DraftStateMachine(
            playerNames: ["Alice", "Bob"],
            factions: ["Sol", "Hacan", "Jol-Nar", "Xxcha", "Yin", "Letnev"],
            bansPerPlayer: 2
        )
        sm.start()
        sm.ban(faction: "Sol")      // Alice ban 1
        sm.ban(faction: "Hacan")    // Alice ban 2
        XCTAssertEqual(sm.phase, .banning(playerIndex: 1))
        sm.ban(faction: "Jol-Nar")  // Bob ban 1
        sm.ban(faction: "Xxcha")    // Bob ban 2
        XCTAssertEqual(sm.phase, .picking(playerIndex: 0))
        XCTAssertEqual(sm.bannedFactions.count, 4)
    }

    func testRandomAssignment() {
        let factions = ["Sol", "Hacan", "Jol-Nar", "Xxcha", "Yin", "Letnev"]
        let excluded: Set<String> = ["Sol", "Hacan"]
        let players = ["Alice", "Bob", "Charlie"]
        let assignments = DraftStateMachine.randomAssignment(
            players: players,
            factions: factions,
            excluding: excluded
        )
        XCTAssertEqual(assignments.count, 3)
        for (_, faction) in assignments {
            XCTAssertFalse(excluded.contains(faction))
        }
        let assignedFactions = Set(assignments.values)
        XCTAssertEqual(assignedFactions.count, 3, "All players get unique factions")
    }

    func testRandomAssignmentNotEnoughFactions() {
        let factions = ["Sol", "Hacan"]
        let excluded: Set<String> = ["Sol"]
        let players = ["Alice", "Bob", "Charlie"]
        let assignments = DraftStateMachine.randomAssignment(
            players: players,
            factions: factions,
            excluding: excluded
        )
        XCTAssertTrue(assignments.isEmpty, "Should return empty when not enough factions")
    }
}
