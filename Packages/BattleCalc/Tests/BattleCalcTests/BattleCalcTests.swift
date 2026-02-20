import XCTest
@testable import BattleCalc

final class CombatEngineTests: XCTestCase {
    let engine = CombatEngine()
    let iterations = 50_000

    // MARK: - Edge Cases

    func testBothFleetsEmpty() {
        let result = engine.simulate(attacker: [], defender: [], iterations: 1)
        XCTAssertEqual(result.attackerWinRate, 0)
        XCTAssertEqual(result.defenderWinRate, 0)
        XCTAssertEqual(result.drawRate, 1)
    }

    func testEmptyAttackerLoses() {
        let result = engine.simulate(attacker: [], defender: [.cruiser], iterations: 1)
        XCTAssertEqual(result.attackerWinRate, 0)
        XCTAssertEqual(result.defenderWinRate, 1)
        XCTAssertEqual(result.avgDefenderSurvivors, 1)
    }

    func testEmptyDefenderLoses() {
        let result = engine.simulate(attacker: [.cruiser], defender: [], iterations: 1)
        XCTAssertEqual(result.attackerWinRate, 1)
        XCTAssertEqual(result.defenderWinRate, 0)
        XCTAssertEqual(result.avgAttackerSurvivors, 1)
    }

    // MARK: - Dreadnought vs Cruiser

    func testDreadnoughtVsCruiser() {
        // DN: 5+ (60% hit), sustain damage. CR: 7+ (40% hit), no sustain.
        // DN has massive advantage from sustain — should win >80%.
        let result = engine.simulate(
            attacker: [.dreadnought], defender: [.cruiser],
            iterations: iterations, seed: 42
        )
        XCTAssertGreaterThan(result.attackerWinRate, 0.80,
            "Dreadnought should beat Cruiser >80% due to sustain + better combat value")
        XCTAssertLessThan(result.defenderWinRate, 0.15)
    }

    // MARK: - Fighters vs Destroyer (AFB)

    func testFightersVsDestroyerWithAFB() {
        // Destroyer has AFB 9 x2 (20% per die, kills fighters before combat).
        // After AFB, ~2.6 fighters remain. In combat, numbers advantage wins.
        let result = engine.simulate(
            attacker: [.fighter, .fighter, .fighter], defender: [.destroyer],
            iterations: iterations, seed: 42
        )
        XCTAssertGreaterThan(result.attackerWinRate, 0.50,
            "3 Fighters should beat 1 Destroyer despite AFB")
    }

    // MARK: - War Suns vs Dreadnoughts

    func testWarSunsVsDreadnoughts() {
        // 2 WS (3+, 3 dice, sustain) vs 4 DN (5+, sustain).
        // WS deal 4.8 hits/round, DN deal 2.4, but DN have more total HP.
        // Should be close to even.
        let result = engine.simulate(
            attacker: [.warSun, .warSun],
            defender: [.dreadnought, .dreadnought, .dreadnought, .dreadnought],
            iterations: iterations, seed: 42
        )
        XCTAssertGreaterThan(result.attackerWinRate, 0.25,
            "War Suns vs Dreadnoughts should be competitive")
        XCTAssertLessThan(result.attackerWinRate, 0.75,
            "War Suns vs Dreadnoughts should be competitive")
    }

    // MARK: - PDS Space Cannon

    func testPDSSpaceCannon() {
        // 10 PDS on defender fire Space Cannon 6 (50% per shot on d10) at 100 fighters.
        // Expected ~5 kills, then PDS removed (non-combat), attacker auto-wins.
        let attackerFleet = Array(repeating: FleetUnit.fighter, count: 100)
        let defenderFleet = Array(repeating: FleetUnit.pds, count: 10)
        let result = engine.simulate(
            attacker: attackerFleet, defender: defenderFleet,
            iterations: iterations, seed: 42
        )
        XCTAssertEqual(result.attackerWinRate, 1.0, accuracy: 0.001,
            "Attacker always wins when defender has only PDS")
        XCTAssertEqual(result.avgAttackerSurvivors, 95, accuracy: 2,
            "~5 fighters lost to 10 PDS shots at 50% each")
    }

    // MARK: - Sustain Damage Mechanics

    func testSustainDamageMirrorMatch() {
        // DN vs DN: identical units with sustain. High draw rate (~26%) from simultaneous kills.
        // Both sides should win roughly equally (~37% each).
        let result = engine.simulate(
            attacker: [.dreadnought], defender: [.dreadnought],
            iterations: iterations, seed: 42
        )
        XCTAssertEqual(result.attackerWinRate, result.defenderWinRate, accuracy: 0.05,
            "Mirror match should have equal win rates")
        XCTAssertGreaterThan(result.drawRate, 0.15,
            "Sustain mirror match should have significant draw rate")
    }

    func testSustainUnitSurvivesFirstHit() {
        // Mech (6+, sustain) vs Fighter (9+, no sustain).
        // Mech hits 50%, Fighter hits 20%. Mech also has sustain.
        // Mech should dominate.
        let result = engine.simulate(
            attacker: [.mech], defender: [.fighter],
            iterations: iterations, seed: 42
        )
        XCTAssertGreaterThan(result.attackerWinRate, 0.85,
            "Mech with sustain should dominate a Fighter")
    }

    // MARK: - Determinism

    func testDeterministicWithSameSeed() {
        let fleet = [FleetUnit.cruiser, .cruiser, .fighter]
        let r1 = engine.simulate(attacker: fleet, defender: fleet, iterations: 1000, seed: 123)
        let r2 = engine.simulate(attacker: fleet, defender: fleet, iterations: 1000, seed: 123)
        XCTAssertEqual(r1.attackerWinRate, r2.attackerWinRate)
        XCTAssertEqual(r1.defenderWinRate, r2.defenderWinRate)
        XCTAssertEqual(r1.drawRate, r2.drawRate)
        XCTAssertEqual(r1.avgAttackerSurvivors, r2.avgAttackerSurvivors)
        XCTAssertEqual(r1.avgDefenderSurvivors, r2.avgDefenderSurvivors)
    }

    func testDifferentSeedsProduceDifferentResults() {
        let fleet = [FleetUnit.cruiser, .dreadnought, .fighter, .fighter]
        let r1 = engine.simulate(attacker: fleet, defender: fleet, iterations: 5000, seed: 1)
        let r2 = engine.simulate(attacker: fleet, defender: fleet, iterations: 5000, seed: 999)
        // With different seeds, at least one metric should differ
        let same = r1.attackerWinRate == r2.attackerWinRate
            && r1.defenderWinRate == r2.defenderWinRate
        XCTAssertFalse(same, "Different seeds should produce different results")
    }

    // MARK: - Large Fleet Smoke Test

    func testLargeFleetBattle() {
        let attacker: [FleetUnit] = [
            .warSun, .dreadnought, .dreadnought,
            .cruiser, .cruiser, .cruiser,
            .destroyer, .destroyer,
            .fighter, .fighter, .fighter, .fighter,
        ]
        let defender: [FleetUnit] = [
            .flagship, .dreadnought, .dreadnought, .dreadnought,
            .cruiser, .cruiser,
            .destroyer,
            .fighter, .fighter, .fighter,
        ]
        let result = engine.simulate(attacker: attacker, defender: defender, iterations: 10_000, seed: 42)
        // Just verify it completes and produces valid rates
        XCTAssertEqual(result.attackerWinRate + result.defenderWinRate + result.drawRate, 1.0, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(result.avgAttackerSurvivors, 0)
        XCTAssertGreaterThanOrEqual(result.avgDefenderSurvivors, 0)
    }

    // MARK: - AFB Only Targets Fighters

    func testAFBDoesNotTargetNonFighters() {
        // 1 Cruiser (not a fighter) vs 1 Destroyer (has AFB 9 x2).
        // AFB should have no effect since Cruiser isn't a fighter.
        // Combat: Cruiser 7+ (40%) vs Destroyer 9+ (20%). Cruiser should win >60%.
        let result = engine.simulate(
            attacker: [.cruiser], defender: [.destroyer],
            iterations: iterations, seed: 42
        )
        XCTAssertGreaterThan(result.attackerWinRate, 0.60,
            "Cruiser should beat Destroyer — AFB doesn't target non-fighters")
    }

    // MARK: - Hit Assignment Ordering

    func testHitAssignmentPrefersSustainOnExpensive() {
        // 1 Dreadnought + 1 Fighter vs 1 Cruiser.
        // If the cruiser lands 1 hit, it should be absorbed by DN sustain, not kill fighter.
        // DN (5+) + Fighter (9+) vs Cruiser (7+) — attacker should win overwhelmingly.
        let result = engine.simulate(
            attacker: [.dreadnought, .fighter], defender: [.cruiser],
            iterations: iterations, seed: 42
        )
        XCTAssertGreaterThan(result.attackerWinRate, 0.90)
        XCTAssertGreaterThan(result.avgAttackerSurvivors, 1.5,
            "Both units should usually survive")
    }
}
