import SwiftUI
import TI4Data
import ClaudeAPI

/// Root view for the Advisor tab — AI strategy chat.
public struct AdvisorView: View {
    @StateObject private var store = GameDataStore()
    @StateObject private var conversation = ConversationManager()
    private let apiClient: ClaudeAPIClient?

    @State private var selectedFaction = ""
    @State private var selectedNeighbors: Set<String> = []
    @State private var currentRound = 1
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSetupExpanded = true

    public init(apiClient: ClaudeAPIClient? = nil) {
        self.apiClient = apiClient
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                setupSection
                Divider()
                chatSection
                inputSection
            }
            .navigationTitle("Advisor")
            .task { store.load() }
        }
    }

    // MARK: - Setup

    private var setupSection: some View {
        DisclosureGroup("Game Setup", isExpanded: $isSetupExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Your Faction", selection: $selectedFaction) {
                    Text("Select…").tag("")
                    ForEach(store.factions) { faction in
                        Text(faction.name).tag(faction.id)
                    }
                }

                if !selectedFaction.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Neighbors").font(.subheadline.weight(.medium))
                        let otherFactions = store.factions.filter { $0.id != selectedFaction }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 4) {
                            ForEach(otherFactions) { faction in
                                Toggle(faction.name, isOn: Binding(
                                    get: { selectedNeighbors.contains(faction.id) },
                                    set: { isOn in
                                        if isOn { selectedNeighbors.insert(faction.id) }
                                        else { selectedNeighbors.remove(faction.id) }
                                    }
                                ))
                                .toggleStyle(.button)
                                .font(.caption)
                            }
                        }
                    }
                }

                Stepper("Round: \(currentRound)", value: $currentRound, in: 1...10)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Chat

    private var chatSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if isLoading {
                        HStack {
                            ProgressView()
                                .padding(.horizontal, 4)
                            Text("Thinking…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: conversation.messages.count) {
                if let last = conversation.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack {
                TextField("Ask for strategy advice…", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading || apiClient == nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, let apiClient else { return }

        inputText = ""
        errorMessage = nil
        conversation.addUserMessage(text)
        isLoading = true
        isSetupExpanded = false

        Task {
            let systemPrompt = AdvisorPromptBuilder.buildSystemPrompt(
                factionId: selectedFaction.isEmpty ? "Unknown faction" : selectedFaction,
                neighbors: Array(selectedNeighbors),
                currentRound: currentRound
            )

            do {
                let response = try await apiClient.sendMessage(
                    systemPrompt: systemPrompt,
                    messages: conversation.toChatMessages()
                )
                conversation.addAssistantMessage(response)
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationManager.ChatDisplayMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            Text(message.content)
                .padding(10)
                .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }
}
