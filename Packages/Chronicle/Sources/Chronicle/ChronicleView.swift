import SwiftUI
import TI4Data
import ClaudeAPI

/// Root view for the Chronicle tab — session narrative generator.
public struct ChronicleView: View {
    @StateObject private var store = GameDataStore()
    private let apiClient: ClaudeAPIClient?
    private let onSave: ((GameSession) -> Void)?
    private let savedSessions: [GameSession]

    @State private var session = GameSession()
    @State private var selectedTone: NarrativeTone = .epic
    @State private var isGenerating = false
    @State private var errorMessage: String?

    // Event entry
    @State private var showingEventSheet = false
    @State private var newEventType: GameEvent.EventType = .battle
    @State private var newEventFactions: Set<String> = []
    @State private var newEventSystem = ""
    @State private var newEventNote = ""

    // Session setup
    @State private var showingSetup = false
    @State private var newPlayerName = ""
    @State private var newPlayerFaction = ""

    public init(
        apiClient: ClaudeAPIClient? = nil,
        savedSessions: [GameSession] = [],
        onSave: ((GameSession) -> Void)? = nil
    ) {
        self.apiClient = apiClient
        self.savedSessions = savedSessions
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            List {
                sessionSection
                playersSection
                eventsSection
                narrativeSection

                if onSave != nil {
                    Section {
                        Button("Save Session") {
                            onSave?(session)
                        }
                        .disabled(session.events.isEmpty)
                    }
                }

                if !savedSessions.isEmpty {
                    Section("Session History") {
                        ForEach(savedSessions) { saved in
                            Button {
                                session = saved
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(saved.title).font(.headline)
                                    Text("\(saved.events.count) events — \(saved.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Chronicle")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Setup") { showingSetup = true }
                }
            }
            .sheet(isPresented: $showingEventSheet) { eventSheet }
            .sheet(isPresented: $showingSetup) { setupSheet }
            .task { store.load() }
        }
    }

    // MARK: - Sections

    private var sessionSection: some View {
        Section("Session") {
            TextField("Session Title", text: $session.title)
            HStack {
                Text("Tone")
                Spacer()
                Picker("Tone", selection: $selectedTone) {
                    ForEach(NarrativeTone.allCases) { tone in
                        Text(tone.rawValue.capitalized).tag(tone)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
            }
        }
    }

    private var playersSection: some View {
        Section("Players (\(session.playerFactions.count))") {
            ForEach(session.playerFactions.sorted(by: { $0.key < $1.key }), id: \.key) { player, faction in
                HStack {
                    Text(player).bold()
                    Spacer()
                    Text(faction).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var eventsSection: some View {
        Section("Events (\(session.events.count))") {
            ForEach(session.events) { event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.type.rawValue.uppercased())
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(eventColor(event.type).opacity(0.2))
                            .clipShape(Capsule())
                        if !event.involvedFactions.isEmpty {
                            Text(event.involvedFactions.joined(separator: " vs "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let note = event.note, !note.isEmpty {
                        Text(note).font(.subheadline)
                    }
                }
            }
            .onDelete { indices in
                session.events.remove(atOffsets: indices)
            }

            Button("Add Event") { showingEventSheet = true }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: session.events.count)
    }

    private var narrativeSection: some View {
        Section("Narrative") {
            if isGenerating {
                ProgressView("Generating chronicle...")
            } else if let narrative = session.narrative {
                Text(narrative)
                ShareLink(item: narrative) {
                    Label("Share Chronicle", systemImage: "square.and.arrow.up")
                }
            }

            if let error = errorMessage {
                Text(error).foregroundStyle(.red).font(.caption)
            }

            Button("Generate Chronicle") {
                Task { await generateNarrative() }
            }
            .disabled(session.events.isEmpty || isGenerating || apiClient == nil)
            .sensoryFeedback(.success, trigger: session.narrative)
        }
    }

    // MARK: - Sheets

    private var eventSheet: some View {
        NavigationStack {
            Form {
                Picker("Event Type", selection: $newEventType) {
                    ForEach(GameEvent.EventType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }

                Section("Involved Factions") {
                    ForEach(store.factions) { faction in
                        Toggle(faction.name, isOn: Binding(
                            get: { newEventFactions.contains(faction.id) },
                            set: { isOn in
                                if isOn { newEventFactions.insert(faction.id) }
                                else { newEventFactions.remove(faction.id) }
                            }
                        ))
                    }
                }

                TextField("System Name", text: $newEventSystem)
                TextField("Note", text: $newEventNote)
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingEventSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let event = GameEvent(
                            type: newEventType,
                            involvedFactions: Array(newEventFactions),
                            systemName: newEventSystem.isEmpty ? nil : newEventSystem,
                            note: newEventNote.isEmpty ? nil : newEventNote
                        )
                        session.events.append(event)
                        resetEventForm()
                        showingEventSheet = false
                    }
                }
            }
        }
    }

    private var setupSheet: some View {
        NavigationStack {
            Form {
                Section("Add Player") {
                    TextField("Player Name", text: $newPlayerName)
                    Picker("Faction", selection: $newPlayerFaction) {
                        Text("Select…").tag("")
                        ForEach(store.factions) { faction in
                            Text(faction.name).tag(faction.id)
                        }
                    }
                    Button("Add Player") {
                        guard !newPlayerName.isEmpty, !newPlayerFaction.isEmpty else { return }
                        session.playerFactions[newPlayerName] = newPlayerFaction
                        newPlayerName = ""
                        newPlayerFaction = ""
                    }
                    .disabled(newPlayerName.isEmpty || newPlayerFaction.isEmpty)
                }

                Section("Current Players") {
                    ForEach(session.playerFactions.sorted(by: { $0.key < $1.key }), id: \.key) { player, faction in
                        HStack {
                            Text(player)
                            Spacer()
                            Text(faction).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Session Setup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingSetup = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func generateNarrative() async {
        guard let apiClient else { return }
        isGenerating = true
        errorMessage = nil

        let prompt = ChroniclePromptBuilder.buildPrompt(session: session, tone: selectedTone)
        let systemPrompt = ChroniclePromptBuilder.systemPrompt(for: selectedTone)

        do {
            let result = try await apiClient.sendMessage(
                systemPrompt: systemPrompt,
                messages: [ChatMessage(role: .user, content: prompt)]
            )
            session.narrative = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    private func resetEventForm() {
        newEventType = .battle
        newEventFactions = []
        newEventSystem = ""
        newEventNote = ""
    }

    private func eventColor(_ type: GameEvent.EventType) -> Color {
        switch type {
        case .battle: return .red
        case .trade: return .green
        case .agenda: return .blue
        case .objective: return .yellow
        case .betrayal: return .purple
        case .alliance: return .cyan
        }
    }
}
