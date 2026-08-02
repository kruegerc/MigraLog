import SwiftData
import SwiftUI

private enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case all = "Alle"
    case sevenDays = "7 Tage"
    case thirtyDays = "30 Tage"
    case ninetyDays = "90 Tage"
    case thisYear = "Dieses Jahr"
    case custom = "Eigener Zeitraum"

    var id: String { rawValue }

    func range(customStart: Date, customEnd: Date, calendar: Calendar = .current) -> ClosedRange<Date>? {
        let now = Date()
        switch self {
        case .all:
            return nil
        case .sevenDays:
            return rangeFrom(days: 7, now: now, calendar: calendar)
        case .thirtyDays:
            return rangeFrom(days: 30, now: now, calendar: calendar)
        case .ninetyDays:
            return rangeFrom(days: 90, now: now, calendar: calendar)
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            return start...now
        case .custom:
            let start = calendar.startOfDay(for: customStart)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEnd) ?? customEnd
            return min(start, end)...max(start, end)
        }
    }

    private func rangeFrom(days: Int, now: Date, calendar: Calendar) -> ClosedRange<Date> {
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now)) ?? now
        return start...now
    }
}

struct StatisticsView: View {
    @Query private var entries: [HeadacheEntry]
    @State private var period: StatisticsPeriod = .all
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEnd = Date()

    private var filteredEntries: [HeadacheEntry] {
        guard let range = period.range(customStart: customStart, customEnd: customEnd) else {
            return entries
        }
        return entries.filter { range.contains($0.startedAt) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Zeitraum") {
                    Picker("Zeitraum", selection: $period) {
                        ForEach(StatisticsPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }

                    if period == .custom {
                        DatePicker("Von", selection: $customStart, displayedComponents: .date)
                        DatePicker("Bis", selection: $customEnd, displayedComponents: .date)
                    }
                }

                Section("Übersicht") {
                    LabeledContent("Zeitraum", value: periodLabel)
                    LabeledContent("Einträge", value: "\(filteredEntries.count)")
                    LabeledContent("Kopfschmerztage", value: "\(headacheDays)")
                    LabeledContent("Durchschnittliche Intensität", value: averageIntensity)
                    LabeledContent("Durchschnittliche Dauer", value: averageDuration)
                }

                Section("Häufige Angaben") {
                    LabeledContent("Symptome", value: mostFrequent(filteredEntries.flatMap(\.symptoms)))
                    LabeledContent("Auslöser", value: mostFrequent(filteredEntries.flatMap(\.triggers)))
                    LabeledContent("Schmerzart", value: mostFrequent(filteredEntries.flatMap(\.painTypes)))
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Statistik",
                        systemImage: "chart.bar",
                        description: Text("Statistiken erscheinen nach dem ersten Eintrag.")
                    )
                } else if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "Keine Einträge im Zeitraum",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Wähle einen anderen Zeitraum.")
                    )
                }
            }
            .navigationTitle("Statistik")
        }
    }

    private var periodLabel: String {
        if let range = period.range(customStart: customStart, customEnd: customEnd) {
            return "\(MigraFormat.date.string(from: range.lowerBound)) - \(MigraFormat.date.string(from: range.upperBound))"
        }
        return "Alle Einträge"
    }

    private var headacheDays: Int {
        Set(filteredEntries.map { Calendar.current.startOfDay(for: $0.startedAt) }).count
    }

    private var averageIntensity: String {
        guard !filteredEntries.isEmpty else { return "-" }
        let value = Double(filteredEntries.map(\.intensity).reduce(0, +)) / Double(filteredEntries.count)
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private var averageDuration: String {
        let durations = filteredEntries.compactMap(\.duration)
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
