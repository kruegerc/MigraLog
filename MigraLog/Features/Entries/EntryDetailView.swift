import SwiftData
import SwiftUI

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: HeadacheEntry
    @State private var isEditing = false
    @State private var showsDeleteConfirmation = false

    var body: some View {
        List {
            Section("Zeit") {
                LabeledContent("Beginn", value: MigraFormat.dateTime.string(from: entry.startedAt))
                LabeledContent("Ende", value: entry.endedAt.map { MigraFormat.dateTime.string(from: $0) } ?? "Offen")
                LabeledContent("Dauer", value: MigraFormat.duration(entry.duration))
            }

            Section("Schmerz") {
                LabeledContent("Intensität", value: "\(entry.intensity)/10")
                ValueList(label: "Art", values: entry.painTypes)
                ValueList(label: "Lokalisation", values: entry.locations)
            }

            Section("Begleitfaktoren") {
                ValueList(label: "Symptome", values: entry.symptoms)
                ValueList(label: "Auslöser", values: entry.triggers)
            }

            Section("Medikamente") {
                LabeledContent("Einnahme", value: entry.medicationsText.isEmpty ? "Nicht erfasst" : entry.medicationsText)
                LabeledContent("Wirkung", value: entry.medicationEffect.title)
            }

            if !entry.notes.isEmpty {
                Section("Notiz") {
                    Text(entry.notes)
                }
            }
        }
        .navigationTitle("Eintrag")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") {
                    isEditing = true
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Löschen", role: .destructive) {
                    showsDeleteConfirmation = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EntryEditorView(mode: .edit(entry))
        }
        .confirmationDialog("Eintrag löschen?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }
}

private struct ValueList: View {
    let label: String
    let values: [String]

    var body: some View {
        LabeledContent(label, value: values.isEmpty ? "Nicht erfasst" : values.joined(separator: ", "))
    }
}
