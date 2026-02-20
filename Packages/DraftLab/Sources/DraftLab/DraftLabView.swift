import SwiftUI
import TI4Data

/// Root view for the Draft Lab tab — faction drafting tools.
public struct DraftLabView: View {
    @StateObject private var draft = MiltyDraft()
    @State private var draftMode: DraftMode = .milty
    @State private var stateMachine: DraftStateMachine?
    @State private var showingRandomAssignment = false

    enum DraftMode: String, CaseIterable {
        case milty = "Milty Draft"
        case random = "Random"
    }

    @EnvironmentObject private var dataStore: GameDataStore

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    configSection
                    actionSection

                    if !draft.slices.isEmpty {
                        slicesSection
                    }

                    if let sm = stateMachine {
                        draftFlowSection(sm)
                    }
                }
                .padding()
            }
            .navigationTitle("Draft Lab")
        }
    }

    // MARK: - Config

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $draftMode) {
                ForEach(DraftMode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            Stepper("Players: \(draft.playerCount)", value: $draft.playerCount, in: 3...8)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private var actionSection: some View {
        HStack {
            Button("Generate Slices") {
                let blueTiles = dataStore.systemTiles
                    .filter { $0.type == .blue }
                    .map { tile in
                        SliceTile(
                            tileNumber: tile.tileNumber,
                            planets: tile.planets.map { SlicePlanet(resources: $0.resources, influence: $0.influence) }
                        )
                    }
                _ = draft.generateSlices(from: blueTiles, count: draft.playerCount)
            }
            .buttonStyle(.borderedProminent)
            .disabled(dataStore.systemTiles.isEmpty)
            .sensoryFeedback(.impact(weight: .medium), trigger: draft.slices.count)

            if draftMode == .random {
                Button("Random Assign") {
                    let players = (1...draft.playerCount).map { "Player \($0)" }
                    let factionNames = dataStore.factions.map(\.name)
                    let assignments = DraftStateMachine.randomAssignment(
                        players: players, factions: factionNames, excluding: []
                    )
                    stateMachine = nil
                    showingRandomAssignment = !assignments.isEmpty
                    // Store for display
                    if !assignments.isEmpty {
                        let sm = DraftStateMachine(
                            playerNames: players, factions: factionNames, bansPerPlayer: 0
                        )
                        sm.start()
                        for player in players {
                            if let faction = assignments[player] {
                                sm.pick(faction: faction)
                            }
                        }
                        stateMachine = sm
                    }
                }
                .buttonStyle(.bordered)
                .disabled(dataStore.factions.isEmpty)
            }

            Button("Start Ban/Pick Draft") {
                let players = (1...draft.playerCount).map { "Player \($0)" }
                let factionNames = dataStore.factions.map(\.name)
                let sm = DraftStateMachine(
                    playerNames: players, factions: factionNames, bansPerPlayer: 1
                )
                sm.start()
                stateMachine = sm
            }
            .buttonStyle(.bordered)
            .disabled(dataStore.factions.isEmpty)
        }
    }

    // MARK: - Slices

    private var slicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Slices")
                .font(.headline)

            ForEach(draft.slices) { slice in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Slice \(slice.id + 1)")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("R: \(slice.totalResources) / I: \(slice.totalInfluence)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "Val: %.1f", slice.optimalValue))
                            .font(.caption.bold())
                    }
                    HexMapView(tiles: slice.tiles, tileSize: 30)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }

            if !draft.slices.isEmpty {
                let fairness = BalanceScorer.fairness(slices: draft.slices)
                Text(String(format: "Fairness (σ): %.2f — %@", fairness, fairnessLabel(fairness)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Draft Flow

    private func draftFlowSection(_ sm: DraftStateMachine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Draft Flow")
                .font(.headline)

            phaseIndicator(sm)

            if case let .banning(idx) = sm.phase {
                Text("\(sm.playerNames[idx])'s turn to ban")
                    .font(.subheadline)
                factionGrid(factions: sm.availableFactions) { sm.ban(faction: $0) }
            }

            if case let .picking(idx) = sm.phase {
                Text("\(sm.playerNames[idx])'s turn to pick")
                    .font(.subheadline)
                factionGrid(factions: sm.availableFactions) { sm.pick(faction: $0) }
            }

            if sm.phase == .complete {
                ForEach(sm.playerNames, id: \.self) { name in
                    HStack {
                        Text(name).bold()
                        Spacer()
                        Text(sm.picks[name] ?? "—").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func phaseIndicator(_ sm: DraftStateMachine) -> some View {
        HStack {
            phaseChip("Ban", active: isBanning(sm.phase))
            phaseChip("Pick", active: isPicking(sm.phase))
            phaseChip("Done", active: sm.phase == .complete)
        }
    }

    private func phaseChip(_ label: String, active: Bool) -> some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(active ? Color.accentColor : Color.gray.opacity(0.2), in: Capsule())
            .foregroundStyle(active ? .white : .primary)
    }

    private func factionGrid(factions: [String], action: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(factions, id: \.self) { faction in
                Button(faction) { action(faction) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private func isBanning(_ phase: DraftPhase) -> Bool {
        if case .banning = phase { return true }
        return false
    }

    private func isPicking(_ phase: DraftPhase) -> Bool {
        if case .picking = phase { return true }
        return false
    }

    private func fairnessLabel(_ sigma: Double) -> String {
        if sigma < 0.5 { return "Excellent" }
        if sigma < 1.0 { return "Good" }
        if sigma < 2.0 { return "Fair" }
        return "Unbalanced"
    }
}
