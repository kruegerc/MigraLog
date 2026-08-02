import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            EntriesListView()
                .tabItem {
                    Label("Tagebuch", systemImage: "list.bullet")
                }

            HistoryView()
                .tabItem {
                    Label("Verlauf", systemImage: "calendar")
                }

            StatisticsView()
                .tabItem {
                    Label("Statistik", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
