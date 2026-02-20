import SwiftUI
import TI4Data

/// Root view for the Codex tab — searchable rules reference and faction browser.
public struct CodexView: View {
    @EnvironmentObject private var dataStore: GameDataStore
    @State private var searchText = ""
    @State private var selectedCategory: CodexCategory?
    @StateObject private var viewModel = CodexViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    categoryBrowser
                } else {
                    searchResults
                }
            }
            .navigationTitle("Codex")
            .searchable(text: $searchText, prompt: "Search rules, factions, techs...")
            .onChange(of: searchText) { _, newValue in
                viewModel.search(newValue)
            }
            .onAppear {
                viewModel.index(from: dataStore)
            }
        }
    }

    @ViewBuilder
    private var categoryBrowser: some View {
        Section("Factions") {
            ForEach(dataStore.factions) { faction in
                NavigationLink(destination: FactionDetailView(faction: faction, techs: dataStore.technologies)) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading) {
                            Text(faction.name).font(.headline)
                            Text("\(faction.expansion.capitalized) — \(faction.commodities) commodities")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }

        Section("Technologies") {
            ForEach(Technology.TechType.allCases, id: \.self) { type in
                NavigationLink(destination: TechListView(type: type, techs: dataStore.technologies.filter { $0.type == type })) {
                    Label(type.displayName, systemImage: type.iconName)
                }
            }
        }

        Section("Cards") {
            NavigationLink(destination: CardListView(title: "Action Cards", cards: dataStore.actionCards.map { .action($0) })) {
                Label("Action Cards (\(dataStore.actionCards.count))", systemImage: "bolt.fill")
            }
            NavigationLink(destination: CardListView(title: "Agenda Cards", cards: dataStore.agendaCards.map { .agenda($0) })) {
                Label("Agenda Cards (\(dataStore.agendaCards.count))", systemImage: "building.columns.fill")
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if viewModel.searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ForEach(viewModel.searchResults) { result in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(result.category.rawValue)
                            .font(.caption2).fontWeight(.semibold)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.cyan.opacity(0.2))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    Text(result.title).font(.headline)
                    Text(result.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    if !result.description.isEmpty {
                        Text(result.description)
                            .font(.caption).foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class CodexViewModel: ObservableObject {
    @Published var searchResults: [CodexSearchResult] = []
    private let engine = CodexSearchEngine()

    func index(from store: GameDataStore) {
        engine.index(
            factions: store.factions,
            technologies: store.technologies,
            actionCards: store.actionCards,
            agendaCards: store.agendaCards
        )
    }

    func search(_ query: String) {
        searchResults = engine.search(query)
    }
}

// MARK: - Detail Views

struct FactionDetailView: View {
    let faction: Faction
    let techs: [Technology]

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Expansion", value: faction.expansion.capitalized)
                LabeledContent("Commodities", value: "\(faction.commodities)")
                LabeledContent("Flagship", value: faction.flagship)
                LabeledContent("Promissory Note", value: faction.promissoryNote)
            }

            if !faction.startingTech.isEmpty {
                Section("Starting Technologies") {
                    ForEach(faction.startingTech, id: \.self) { tech in
                        Label(tech, systemImage: "cpu")
                    }
                }
            }

            if !faction.abilities.isEmpty {
                Section("Abilities") {
                    ForEach(faction.abilities, id: \.name) { ability in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ability.name).font(.headline)
                            Text(ability.description).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            let factionTechs = techs.filter { $0.faction == faction.id }
            if !factionTechs.isEmpty {
                Section("Faction Technologies") {
                    ForEach(factionTechs) { tech in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tech.name).font(.headline)
                            Text(tech.description).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(faction.name)
    }
}

struct TechListView: View {
    let type: Technology.TechType
    let techs: [Technology]

    var body: some View {
        List(techs) { tech in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tech.name).font(.headline)
                    if tech.faction != nil {
                        Text("Faction").font(.caption2)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.orange.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                if !tech.prerequisites.isEmpty {
                    HStack(spacing: 4) {
                        Text("Requires:").font(.caption2).foregroundStyle(.secondary)
                        ForEach(tech.prerequisites, id: \.self) { prereq in
                            Text(prereq.displayName).font(.caption2).fontWeight(.semibold)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(prereq.color.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                Text(tech.description).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(type.displayName)
    }
}

enum CardItem: Identifiable {
    case action(ActionCard)
    case agenda(AgendaCard)

    var id: String {
        switch self {
        case .action(let c): return c.id
        case .agenda(let c): return c.id
        }
    }
}

struct CardListView: View {
    let title: String
    let cards: [CardItem]

    var body: some View {
        List(cards) { card in
            switch card {
            case .action(let c):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.name).font(.headline)
                        Spacer()
                        Text(c.phase).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(c.description).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            case .agenda(let c):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.name).font(.headline)
                        Spacer()
                        Text(c.type == .law ? "Law" : "Directive").font(.caption)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(c.type == .law ? .blue.opacity(0.2) : .orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    Text(c.description).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(title)
    }
}

// MARK: - TechType Helpers

extension Technology.TechType: CaseIterable {
    public static var allCases: [Technology.TechType] {
        [.biotic, .warfare, .propulsion, .cybernetic, .unitUpgrade]
    }

    var iconName: String {
        switch self {
        case .biotic: return "leaf.fill"
        case .warfare: return "shield.fill"
        case .propulsion: return "arrow.right.circle.fill"
        case .cybernetic: return "cpu.fill"
        case .unitUpgrade: return "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .biotic: return .green
        case .warfare: return .red
        case .propulsion: return .blue
        case .cybernetic: return .yellow
        case .unitUpgrade: return .purple
        }
    }
}
