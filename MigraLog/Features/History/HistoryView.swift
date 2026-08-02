import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \HeadacheEntry.startedAt, order: .reverse) private var entries: [HeadacheEntry]
    @State private var entryToEdit: HeadacheEntry?

    private var monthGroups: [HistoryMonthGroup] {
        let calendar = Calendar.current
        let monthDictionary = Dictionary(grouping: entries) { entry in
            let components = calendar.dateComponents([.year, .month], from: entry.startedAt)
            return calendar.date(from: components) ?? calendar.startOfDay(for: entry.startedAt)
        }

        return monthDictionary
            .map { monthStart, monthEntries in
                let dayDictionary = Dictionary(grouping: monthEntries) { entry in
                    calendar.startOfDay(for: entry.startedAt)
                }
                let days = dayDictionary
                    .map { dayStart, dayEntries in
                        HistoryDayGroup(
                            id: dayStart,
                            title: Self.dayFormatter.string(from: dayStart),
                            entries: dayEntries.sorted { $0.startedAt > $1.startedAt }
                        )
                    }
                    .sorted { $0.id > $1.id }

                return HistoryMonthGroup(
                    id: monthStart,
                    title: Self.monthFormatter.string(from: monthStart),
                    days: days
                )
            }
            .sorted { $0.id > $1.id }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Noch kein Verlauf",
                        systemImage: "calendar",
                        description: Text("Der Verlauf erscheint nach dem ersten Eintrag.")
                    )
                } else {
                    List {
                        ForEach(monthGroups) { month in
                            Section(month.title) {
                                ForEach(month.days) { day in
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text(day.title)
                                                .font(.headline)
                                            Spacer()
                                            Text("\(day.entries.count) Einträge")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }

                                        ForEach(day.entries) { entry in
                                            Button {
                                                entryToEdit = entry
                                            } label: {
                                                HistoryEntryRow(entry: entry)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Verlauf")
            .fullScreenCover(item: $entryToEdit) { entry in
                EntryEditorView(mode: .edit(entry))
            }
        }
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct HistoryMonthGroup: Identifiable {
    let id: Date
    let title: String
    let days: [HistoryDayGroup]
}

private struct HistoryDayGroup: Identifiable {
    let id: Date
    let title: String
    let entries: [HeadacheEntry]
}

private struct HistoryEntryRow: View {
    let entry: HeadacheEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(intensityColor.opacity(0.16))
                Text("\(entry.intensity)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(intensityColor)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(Self.timeFormatter.string(from: entry.startedAt))
                        .font(.subheadline.weight(.semibold))
                    Text(MigraFormat.duration(entry.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private var summaryText: String {
        let painText = entry.painTypes.isEmpty ? "Schmerzart nicht erfasst" : entry.painTypes.joined(separator: ", ")
        let triggerText = entry.triggers.isEmpty ? nil : entry.triggers.joined(separator: ", ")
        if let triggerText {
            return "\(painText) · \(triggerText)"
        }
        return painText
    }

    private var intensityColor: Color {
        switch entry.intensity {
        case 0...2: .teal
        case 3...5: .orange
        case 6...8: .red
        default: .purple
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.container)
}
