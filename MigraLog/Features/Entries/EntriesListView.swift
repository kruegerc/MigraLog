import SwiftData
import SwiftUI

struct EntriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HeadacheEntry.startedAt, order: .reverse) private var entries: [HeadacheEntry]
    @State private var isAddingEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Eintraege",
                        systemImage: "waveform.path.ecg",
                        description: Text("Lege die erste Kopfschmerzepisode an.")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            NavigationLink {
                                EntryDetailView(entry: entry)
                            } label: {
                                EntryRowView(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("MigraLog")
            .safeAreaInset(edge: .bottom) {
                addEntryBar
            }
            .fullScreenCover(isPresented: $isAddingEntry) {
                EntryEditorView(mode: .new)
            }
        }
    }

    private var addEntryBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                isAddingEntry = true
            } label: {
                Label("Eintrag hinzufuegen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(.bar)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

private struct EntryRowView: View {
    let entry: HeadacheEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(intensityColor.opacity(0.16))
                Image(systemName: intensityIcon)
                    .foregroundStyle(intensityColor)
                    .font(.title3.weight(.semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(MigraFormat.dateTime.string(from: entry.startedAt))
                        .font(.headline)
                    Spacer()
                    Text("\(entry.intensity)/10")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(intensityColor)
                }

                Text("Dauer: \(MigraFormat.duration(entry.duration))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !entry.painTypes.isEmpty {
                    Text(entry.painTypes.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var intensityColor: Color {
        switch entry.intensity {
        case 0...2: .teal
        case 3...5: .orange
        case 6...8: .red
        default: .purple
        }
    }

    private var intensityIcon: String {
        switch entry.intensity {
        case 0...2: "circle"
        case 3...5: "circle.lefthalf.filled"
        case 6...8: "flame.fill"
        default: "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    EntriesListView()
        .modelContainer(PreviewData.container)
}
