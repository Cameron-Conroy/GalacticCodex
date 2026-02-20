import SwiftUI

// MARK: - View Model

struct UnitEntry: Identifiable {
    let id: String
    let name: String
    let unit: FleetUnit
    var count: Int = 0
}

@Observable
final class BattleCalcViewModel {
    var attackerUnits: [UnitEntry]
    var defenderUnits: [UnitEntry]
    var result: CombatResult?

    init() {
        attackerUnits = Self.makeEntries()
        defenderUnits = Self.makeEntries()
    }

    static func makeEntries() -> [UnitEntry] {
        [
            UnitEntry(id: "fighter", name: "Fighter", unit: .fighter),
            UnitEntry(id: "infantry", name: "Infantry", unit: .infantry),
            UnitEntry(id: "destroyer", name: "Destroyer", unit: .destroyer),
            UnitEntry(id: "cruiser", name: "Cruiser", unit: .cruiser),
            UnitEntry(id: "carrier", name: "Carrier", unit: .carrier),
            UnitEntry(id: "dreadnought", name: "Dreadnought", unit: .dreadnought),
            UnitEntry(id: "warsun", name: "War Sun", unit: .warSun),
            UnitEntry(id: "flagship", name: "Flagship", unit: .flagship),
            UnitEntry(id: "pds", name: "PDS", unit: .pds),
            UnitEntry(id: "mech", name: "Mech", unit: .mech),
        ]
    }

    func simulate() {
        let attacker = attackerUnits.flatMap { Array(repeating: $0.unit, count: $0.count) }
        let defender = defenderUnits.flatMap { Array(repeating: $0.unit, count: $0.count) }
        guard !attacker.isEmpty || !defender.isEmpty else {
            result = nil
            return
        }
        result = CombatEngine().simulate(attacker: attacker, defender: defender)
    }
}

// MARK: - Main View

public struct BattleCalcView: View {
    @State private var viewModel = BattleCalcViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(alignment: .top, spacing: 16) {
                        fleetColumn(title: "Attacker", units: $viewModel.attackerUnits, color: .red)
                        fleetColumn(title: "Defender", units: $viewModel.defenderUnits, color: .blue)
                    }

                    Button(action: viewModel.simulate) {
                        Label("Simulate Combat", systemImage: "bolt.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.result?.attackerWinRate)

                    if let result = viewModel.result {
                        resultsPanel(result)
                    }
                }
                .padding()
            }
            .navigationTitle("Battle Calc")
        }
    }

    // MARK: - Fleet Column

    private func fleetColumn(
        title: String,
        units: Binding<[UnitEntry]>,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)

            ForEach(units.wrappedValue.indices, id: \.self) { index in
                HStack {
                    Text(units.wrappedValue[index].name)
                        .font(.subheadline)
                        .frame(width: 90, alignment: .leading)
                    Spacer()
                    Text("\(units.wrappedValue[index].count)")
                        .monospacedDigit()
                        .frame(width: 24)
                    Stepper(
                        "",
                        value: units[index].count,
                        in: 0...20
                    )
                    .labelsHidden()
                    .fixedSize()
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Results

    private func resultsPanel(_ result: CombatResult) -> some View {
        VStack(spacing: 16) {
            Text("Results (10,000 simulations)")
                .font(.headline)

            HStack(spacing: 20) {
                winRateStat("Attacker", value: result.attackerWinRate, color: .red)
                winRateStat("Draw", value: result.drawRate, color: .secondary)
                winRateStat("Defender", value: result.defenderWinRate, color: .blue)
            }

            Divider()

            HStack(spacing: 32) {
                survivorStat("Avg Attacker Left", value: result.avgAttackerSurvivors, color: .red)
                survivorStat("Avg Defender Left", value: result.avgDefenderSurvivors, color: .blue)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func winRateStat(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f%%", value * 100))
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 70)
    }

    private func survivorStat(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.title3.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
