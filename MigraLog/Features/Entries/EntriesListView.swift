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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingEntry = true
                    } label: {
                        Label("Eintrag hinzufuegen", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingEntry) {
                EntryEditorView(mode: .new)
            }
        }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(MigraFormat.dateTime.string(from: entry.startedAt))
                    .font(.headline)
                Spacer()
                Text("\(entry.intensity)/10")
                    .font(.subheadline.weight(.semibold))
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
        .padding(.vertical, 4)
    }
}

#Preview {
    EntriesListView()
        .modelContainer(PreviewData.container)
}
