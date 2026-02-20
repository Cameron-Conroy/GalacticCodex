import SwiftUI
import TI4Data
import Codex
import DraftLab
import BattleCalc
import Chronicle
import Advisor

@main
struct GalacticCodexApp: App {
    @StateObject private var dataStore = GameDataStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                CodexView()
                    .tabItem {
                        Label("Codex", systemImage: "book.closed.fill")
                    }

                DraftLabView()
                    .tabItem {
                        Label("Draft Lab", systemImage: "dice.fill")
                    }

                BattleCalcView()
                    .tabItem {
                        Label("Battle Calc", systemImage: "bolt.shield.fill")
                    }

                ChronicleView()
                    .tabItem {
                        Label("Chronicle", systemImage: "scroll.fill")
                    }

                AdvisorView()
                    .tabItem {
                        Label("Advisor", systemImage: "bubble.left.and.text.bubble.right.fill")
                    }
            }
            .environmentObject(dataStore)
            .preferredColorScheme(.dark)
            .tint(.cyan)
            .task {
                dataStore.load()
            }
        }
    }
}
