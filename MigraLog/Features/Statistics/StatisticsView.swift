import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query private var entries: [HeadacheEntry]

    var body: some View {
        NavigationStack {
            List {
                Section("Übersicht") {
                    LabeledContent("Einträge", value: "\(entries.count)")
                    LabeledContent("Durchschnittliche Intensität", value: averageIntensity)
                    LabeledContent("Durchschnittliche Dauer", value: averageDuration)
                }

                Section("Häufige Angaben") {
                    LabeledContent("Symptome", value: mostFrequent(entries.flatMap(\.symptoms)))
                    LabeledContent("Auslöser", value: mostFrequent(entries.flatMap(\.triggers)))
                    LabeledContent("Schmerzart", value: mostFrequent(entries.flatMap(\.painTypes)))
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Statistik",
                        systemImage: "chart.bar",
                        description: Text("Statistiken erscheinen nach dem ersten Eintrag.")
                    )
                }
            }
            .navigationTitle("Statistik")
        }
    }

    private var averageIntensity: String {
        guard !entries.isEmpty else { return "-" }
        let value = Double(entries.map(\.intensity).reduce(0, +)) / Double(entries.count)
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private var averageDuration: String {
        let durations = entries.compactMap(\.duration)
        guard !durations.isEmpty else { return "-" }
        let average = durations.reduce(0, +) / Double(durations.count)
        return MigraFormat.duration(average)
    }

    private func mostFrequent(_ values: [String]) -> String {
        guard !values.isEmpty else { return "-" }
        let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? "-"
    }
}

#Preview {
    StatisticsView()
        .modelContainer(PreviewData.container)
}
