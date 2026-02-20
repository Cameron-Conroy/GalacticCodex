# GalacticCodex

TI4 companion iOS app with AI-powered session narratives, strategy advice, combat simulation, draft tools, and a searchable rules codex.

## Architecture

Thin app shell (`GalacticCodex/App.swift`) composing 7 SPM packages via `TabView`:

```
                  ┌─────────────┐
                  │  App Shell  │  (SwiftData, TabView, env injection)
                  └──────┬──────┘
         ┌───────┬───────┼───────┬──────────┐
         ▼       ▼       ▼       ▼          ▼
      Codex  DraftLab BattleCalc Chronicle Advisor
         │       │       │       │          │
         ▼       ▼       ▼       ├──────────┘
       TI4Data ◄─┘       │       ▼
         ▲               │   ClaudeAPI
         └───────────────┘
```

- **TI4Data** — Foundation layer: models, JSON resources, `GameDataStore`
- **ClaudeAPI** — Anthropic Messages API client (shared by Chronicle + Advisor)
- **Codex** — Searchable rules/faction/tech browser
- **DraftLab** — Milty draft slice generator + ban/pick state machine
- **BattleCalc** — Monte Carlo combat simulator (10k iterations)
- **Chronicle** — Session event logger → AI narrative generator
- **Advisor** — AI strategy chat with faction/round context

## Build & Test

```bash
# Full build (requires Xcode + iOS 17 simulator)
xcodebuild -project GalacticCodex.xcodeproj -scheme GalacticCodex -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Full test suite (132 tests)
xcodebuild -project GalacticCodex.xcodeproj -scheme GalacticCodex -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Test individual package (no simulator needed)
swift test --package-path Packages/TI4Data
swift test --package-path Packages/BattleCalc
swift test --package-path Packages/DraftLab
swift test --package-path Packages/Codex
swift test --package-path Packages/Chronicle
swift test --package-path Packages/Advisor
swift test --package-path Packages/ClaudeAPI

# Boot simulator for full-app builds
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null; sleep 2
```

## Code Conventions

### Naming

| Role | Pattern | Example |
|------|---------|---------|
| Root view | `{Feature}View` | `CodexView`, `BattleCalcView` |
| View model | `{Feature}ViewModel` | `CodexViewModel`, `BattleCalcViewModel` |
| Core logic | `{Feature}Engine` / `{Feature}Scorer` | `CombatEngine`, `CodexSearchEngine`, `BalanceScorer` |
| AI prompts | `{Feature}PromptBuilder` | `ChroniclePromptBuilder`, `AdvisorPromptBuilder` |
| Draft flow | `{Feature}StateMachine` | `DraftStateMachine` |

### Visibility

- **Views**: `public` (exported from packages for the app shell to consume)
- **ViewModels**: `internal` (file-scoped or package-internal)
- **Helpers/detail views**: `private` or internal

### View Composition

Split views into private computed properties for each section, using `// MARK: -` dividers:

```swift
public var body: some View {
    NavigationStack {
        List {
            sessionSection
            playersSection
            eventsSection
        }
    }
}

// MARK: - Sections

private var sessionSection: some View { ... }
```

### State Management

- `@EnvironmentObject` — Shared `GameDataStore` injected from app shell
- `@StateObject` — View-local `ObservableObject` instances (`CodexViewModel`, `MiltyDraft`, `ConversationManager`)
- `@State` + `@Observable` — Newer pattern used in `BattleCalcViewModel`
- `@MainActor` — Required on all `ObservableObject` classes

### Models

All model structs conform to `Codable, Identifiable, Hashable, Sendable`. Public initializers with all stored properties as parameters.

### JSON Decoding

```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
```

### Concurrency

- `@MainActor` on `ObservableObject` classes
- `Sendable` on all model structs
- `ClaudeAPIClient` is `Sendable` (uses `URLSession.shared`)

### Comments

No trivial comments. One-line `///` docstrings on public API only.

## Data Layer

JSON resources live in `Packages/TI4Data/Sources/TI4Data/Resources/`:

| File | Model |
|------|-------|
| `factions.json` | `Faction` |
| `technologies.json` | `Technology` |
| `system_tiles.json` | `SystemTile` |
| `units.json` | `UnitBlueprint` |
| `action_cards.json` | `ActionCard` |
| `agenda_cards.json` | `AgendaCard` |

Loaded via `Bundle.module` in `GameDataStore.load()`. The store is the single source of truth — initialized in `App.swift` and injected via `.environmentObject(dataStore)`.

## SwiftData

Persistence lives in the app target (not in packages):

- `PersistedSession` (`SessionStore.swift`) — `@Model` class that serializes `GameSession` to JSON `Data`
- `ChronicleWrapper` (`ChronicleWrapper.swift`) — Bridges `@Query` results to the Chronicle package's `ChronicleView`, converting `PersistedSession` → `GameSession`
- Model container registered in `App.swift`: `.modelContainer(for: PersistedSession.self)`

## Adding a New Feature

1. Create SPM package: `mkdir -p Packages/NewFeature/Sources/NewFeature && mkdir -p Packages/NewFeature/Tests/NewFeatureTests`
2. Add `Package.swift` with `platforms: [.iOS(.v17), .macOS(.v14)]`, depend on `TI4Data` (and `ClaudeAPI` if AI-powered)
3. Create a public root view: `public struct NewFeatureView: View`
4. Add the package as a dependency in the Xcode project
5. Wire into `App.swift` TabView with `.tabItem { ... }`
6. Add `.environmentObject(dataStore)` if the feature reads game data

## Remaining Work

See [TODO.md](TODO.md) for remaining features, enhancements, and code quality items.
