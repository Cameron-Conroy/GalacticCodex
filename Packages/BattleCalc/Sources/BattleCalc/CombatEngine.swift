// MARK: - Types

public struct FleetUnit: Sendable, Hashable {
    public let name: String
    public let combatValue: Int
    public let numDice: Int
    public let sustainDamage: Bool
    public let antiFighterBarrage: DiceSpec?
    public let spaceCannon: DiceSpec?
    public let bombardment: DiceSpec?
    public let isFighter: Bool
    public let cost: Int

    public struct DiceSpec: Sendable, Hashable {
        public let hitOn: Int
        public let count: Int
        public init(hitOn: Int, count: Int) {
            self.hitOn = hitOn
            self.count = count
        }
    }

    public init(
        name: String,
        combatValue: Int,
        numDice: Int = 1,
        sustainDamage: Bool = false,
        antiFighterBarrage: DiceSpec? = nil,
        spaceCannon: DiceSpec? = nil,
        bombardment: DiceSpec? = nil,
        isFighter: Bool = false,
        cost: Int = 1
    ) {
        self.name = name
        self.combatValue = combatValue
        self.numDice = numDice
        self.sustainDamage = sustainDamage
        self.antiFighterBarrage = antiFighterBarrage
        self.spaceCannon = spaceCannon
        self.bombardment = bombardment
        self.isFighter = isFighter
        self.cost = cost
    }
}

// MARK: - Standard TI4 Units

extension FleetUnit {
    public static let infantry = FleetUnit(name: "Infantry", combatValue: 8)
    public static let fighter = FleetUnit(name: "Fighter", combatValue: 9, isFighter: true)
    public static let carrier = FleetUnit(name: "Carrier", combatValue: 9, cost: 3)
    public static let destroyer = FleetUnit(
        name: "Destroyer", combatValue: 9,
        antiFighterBarrage: DiceSpec(hitOn: 9, count: 2)
    )
    public static let cruiser = FleetUnit(name: "Cruiser", combatValue: 7, cost: 2)
    public static let dreadnought = FleetUnit(
        name: "Dreadnought", combatValue: 5, sustainDamage: true,
        bombardment: DiceSpec(hitOn: 5, count: 1), cost: 4
    )
    public static let warSun = FleetUnit(
        name: "War Sun", combatValue: 3, numDice: 3, sustainDamage: true,
        bombardment: DiceSpec(hitOn: 3, count: 3), cost: 12
    )
    public static let flagship = FleetUnit(
        name: "Flagship", combatValue: 5, numDice: 2, sustainDamage: true, cost: 8
    )
    public static let pds = FleetUnit(
        name: "PDS", combatValue: 0,
        spaceCannon: DiceSpec(hitOn: 6, count: 1), cost: 0
    )
    public static let mech = FleetUnit(name: "Mech", combatValue: 6, sustainDamage: true, cost: 2)
}

// MARK: - Combat Result

public struct CombatResult: Sendable {
    public let attackerWinRate: Double
    public let defenderWinRate: Double
    public let drawRate: Double
    public let avgAttackerSurvivors: Double
    public let avgDefenderSurvivors: Double
}

// MARK: - Combat Engine

public struct CombatEngine: Sendable {
    public init() {}

    /// Run Monte Carlo combat simulation over the given number of iterations.
    public func simulate(
        attacker: [FleetUnit],
        defender: [FleetUnit],
        iterations: Int = 10_000,
        seed: UInt64? = nil
    ) -> CombatResult {
        if attacker.isEmpty && defender.isEmpty {
            return CombatResult(
                attackerWinRate: 0, defenderWinRate: 0, drawRate: 1,
                avgAttackerSurvivors: 0, avgDefenderSurvivors: 0
            )
        }
        if attacker.isEmpty {
            return CombatResult(
                attackerWinRate: 0, defenderWinRate: 1, drawRate: 0,
                avgAttackerSurvivors: 0, avgDefenderSurvivors: Double(defender.count)
            )
        }
        if defender.isEmpty {
            return CombatResult(
                attackerWinRate: 1, defenderWinRate: 0, drawRate: 0,
                avgAttackerSurvivors: Double(attacker.count), avgDefenderSurvivors: 0
            )
        }

        var rng = SeededRNG(seed: seed ?? UInt64.random(in: 0...UInt64.max))
        var attackerWins = 0
        var defenderWins = 0
        var draws = 0
        var totalAttackerSurvivors = 0
        var totalDefenderSurvivors = 0

        for _ in 0..<iterations {
            let (aSurv, dSurv) = runBattle(attacker: attacker, defender: defender, rng: &rng)
            totalAttackerSurvivors += aSurv
            totalDefenderSurvivors += dSurv
            if aSurv > 0 && dSurv == 0 {
                attackerWins += 1
            } else if dSurv > 0 && aSurv == 0 {
                defenderWins += 1
            } else {
                draws += 1
            }
        }

        let n = Double(iterations)
        return CombatResult(
            attackerWinRate: Double(attackerWins) / n,
            defenderWinRate: Double(defenderWins) / n,
            drawRate: Double(draws) / n,
            avgAttackerSurvivors: Double(totalAttackerSurvivors) / n,
            avgDefenderSurvivors: Double(totalDefenderSurvivors) / n
        )
    }
}

// MARK: - Battle Simulation (private)

extension CombatEngine {
    private func runBattle(
        attacker: [FleetUnit],
        defender: [FleetUnit],
        rng: inout SeededRNG
    ) -> (attackerSurvivors: Int, defenderSurvivors: Int) {
        var aUnits = attacker.map(ActiveUnit.init)
        var dUnits = defender.map(ActiveUnit.init)

        // Phase 1: Anti-Fighter Barrage (simultaneous)
        let afbHitsOnDefender = rollAbility(units: aUnits, keyPath: \.afb, rng: &rng)
        let afbHitsOnAttacker = rollAbility(units: dUnits, keyPath: \.afb, rng: &rng)
        applyFighterHits(hits: afbHitsOnAttacker, to: &aUnits)
        applyFighterHits(hits: afbHitsOnDefender, to: &dUnits)

        // Phase 2: Space Cannon Defense (defender only)
        let scHits = rollAbility(units: dUnits, keyPath: \.spaceCannon, rng: &rng)
        applyHits(hits: scHits, to: &aUnits)

        // Remove non-combat units (PDS) before combat rounds
        aUnits.removeAll { !$0.participatesInCombat }
        dUnits.removeAll { !$0.participatesInCombat }

        // Phase 3: Combat rounds (repeat until one side eliminated)
        while !aUnits.isEmpty && !dUnits.isEmpty {
            let aHits = rollCombat(units: aUnits, rng: &rng)
            let dHits = rollCombat(units: dUnits, rng: &rng)
            // Simultaneous hit assignment
            applyHits(hits: dHits, to: &aUnits)
            applyHits(hits: aHits, to: &dUnits)
        }

        return (aUnits.count, dUnits.count)
    }

    private func rollAbility(
        units: [ActiveUnit],
        keyPath: KeyPath<ActiveUnit, FleetUnit.DiceSpec?>,
        rng: inout SeededRNG
    ) -> Int {
        var hits = 0
        for unit in units {
            guard let spec = unit[keyPath: keyPath] else { continue }
            for _ in 0..<spec.count {
                if Int.random(in: 1...10, using: &rng) >= spec.hitOn { hits += 1 }
            }
        }
        return hits
    }

    private func rollCombat(units: [ActiveUnit], rng: inout SeededRNG) -> Int {
        var hits = 0
        for unit in units where unit.participatesInCombat {
            for _ in 0..<unit.numDice {
                if Int.random(in: 1...10, using: &rng) >= unit.combatValue { hits += 1 }
            }
        }
        return hits
    }

    /// Assign hits optimally: sustain on most expensive first, then remove cheapest.
    private func applyHits(hits: Int, to units: inout [ActiveUnit]) {
        var remaining = hits

        // Use sustain damage on most expensive undamaged units first
        let sustainIndices = units.indices
            .filter { units[$0].canSustainHit }
            .sorted { units[$0].cost > units[$1].cost }
        for idx in sustainIndices {
            guard remaining > 0 else { break }
            units[idx].isDamaged = true
            remaining -= 1
        }

        // Remove cheapest units (prefer already-damaged among equal cost)
        while remaining > 0 && !units.isEmpty {
            guard let idx = units.indices.min(by: { a, b in
                if units[a].cost != units[b].cost { return units[a].cost < units[b].cost }
                return units[a].isDamaged && !units[b].isDamaged
            }) else { break }
            units.remove(at: idx)
            remaining -= 1
        }
    }

    /// AFB hits only target fighters.
    private func applyFighterHits(hits: Int, to units: inout [ActiveUnit]) {
        var remaining = hits
        while remaining > 0 {
            guard let idx = units.firstIndex(where: { $0.isFighter }) else { break }
            units.remove(at: idx)
            remaining -= 1
        }
    }
}

// MARK: - Seedable RNG (SplitMix64)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - Active Unit (mutable state during simulation)

private struct ActiveUnit {
    let combatValue: Int
    let numDice: Int
    let canSustain: Bool
    let afb: FleetUnit.DiceSpec?
    let spaceCannon: FleetUnit.DiceSpec?
    let isFighter: Bool
    let cost: Int
    var isDamaged: Bool = false

    var canSustainHit: Bool { canSustain && !isDamaged }
    var participatesInCombat: Bool { combatValue > 0 }

    init(from unit: FleetUnit) {
        combatValue = unit.combatValue
        numDice = unit.numDice
        canSustain = unit.sustainDamage
        afb = unit.antiFighterBarrage
        spaceCannon = unit.spaceCannon
        isFighter = unit.isFighter
        cost = unit.cost
    }
}
