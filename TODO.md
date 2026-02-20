# GalacticCodex — TODO

## Phase 5: Polish

- [ ] App icon + launch screen (space-themed dark aesthetic)
- [ ] Dark theme refinement with faction color accents
- [ ] App Store metadata + screenshots

## BattleCalc Enhancements

- [ ] Technology modifier toggles (e.g., Plasma Scoring, Antimass Deflectors)
- [ ] Round-by-round breakdown display
- [ ] Faction-specific unit abilities (flagships, mechs)

## Chronicle Enhancements

- [ ] Rich ShareLink output (image/PDF rendering, not just text)
- [ ] API key management UI (currently hardcoded/nil)

## Advisor Enhancements

- [ ] Streaming response display (currently waits for full response)

## Codex Enhancements

- [ ] AI rules Q&A via Claude API (conversational rules lookup with citations)

## Data Completeness

- [ ] PromissoryNote model + JSON (mentioned in plan, not yet created)
- [ ] Draft history persistence in SwiftData

## Known Bugs

- [ ] Splash screen images don't cycle — `@State` initializer picks one random image per view lifetime, so relaunching the app often shows the same image. Need a mechanism to ensure variety across launches (e.g., persist last-shown index in `UserDefaults`).

## Code Quality

- [ ] Resolve @Observable vs @StateObject inconsistency (BattleCalcViewModel uses @Observable, CodexViewModel uses @MainActor ObservableObject)
- [ ] Add ClaudeAPI retry logic / exponential backoff

## Verification

- [ ] End-to-end test with real Claude API key
- [ ] Simulator screenshot verification of all 5 tabs
