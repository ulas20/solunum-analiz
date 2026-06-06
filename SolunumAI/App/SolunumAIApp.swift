import SwiftUI

@main
struct SolunumAIApp: App {
    @StateObject private var coreData = CoreDataService.shared
    @State private var selectedTab: Int = 0
    @AppStorage("disclaimer_accepted") private var disclaimerAccepted = false

    var body: some Scene {
        WindowGroup {
            if disclaimerAccepted {
                ContentView(selectedTab: $selectedTab)
                    .environmentObject(coreData)
                    .preferredColorScheme(nil)
            } else {
                DisclaimerView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        disclaimerAccepted = true
                    }
                }
                .preferredColorScheme(nil)
            }
        }
    }
}

// MARK: - Content View (Tab container)

struct ContentView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)

            AnalysisView()
                .tabItem {
                    Label("Analiz", systemImage: "waveform.badge.mic")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("Geçmiş", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            ExercisesView()
                .tabItem {
                    Label("Egzersizler", systemImage: "figure.mind.and.body")
                }
                .tag(3)
        }
        .tint(Color("AppPrimary"))
    }
}

#Preview {
    ContentView(selectedTab: .constant(0))
        .environmentObject(CoreDataService.shared)
}
