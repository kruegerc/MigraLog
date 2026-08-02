import SwiftData
import SwiftUI

enum EntryEditorMode {
    case new
    case edit(HeadacheEntry)
}

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let mode: EntryEditorMode
    @State private var draft: EntryDraft

    init(mode: EntryEditorMode) {
        self.mode = mode
        switch mode {
        case .new:
            _draft = State(initialValue: EntryDraft())
        case .edit(let entry):
            _draft = State(initialValue: EntryDraft(entry: entry))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeit") {
                    DatePicker("Beginn", selection: $draft.startedAt)
                    Toggle("Ende erfassen", isOn: $draft.hasEndedAt)
                    if draft.hasEndedAt {
                        DatePicker("Ende", selection: $draft.endedAt, in: draft.startedAt...)
                    }
                }

                Section("Intensitaet") {
                    Stepper(value: $draft.intensity, in: 0...10) {
                        Text("\(draft.intensity)/10")
                    }
                }

                MultiSelectList(title: "Schmerzart", options: HeadacheOptions.painTypes, selection: $draft.painTypes)
                MultiSelectList(title: "Lokalisation", options: HeadacheOptions.locations, selection: $draft.locations)
                MultiSelectList(title: "Symptome", options: HeadacheOptions.symptoms, selection: $draft.symptoms)
                MultiSelectList(title: "Ausloeser", options: HeadacheOptions.triggers, selection: $draft.triggers)

                Section("Medikamente") {
                    TextField("Medikamente", text: $draft.medications, axis: .vertical)
                    Picker("Wirkung", selection: $draft.medicationEffect) {
                        ForEach(MedicationEffect.allCases) { effect in
                            Text(effect.title).tag(effect)
                        }
                    }
                }

                Section("Notiz") {
                    TextField("Notiz", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .new: "Neuer Eintrag"
        case .edit: "Eintrag bearbeiten"
        }
    }

    private func save() {
        switch mode {
        case .new:
            let entry = HeadacheEntry(
                startedAt: draft.startedAt,
                endedAt: draft.hasEndedAt ? draft.endedAt : nil,
                intensity: draft.intensity,
                painTypes: draft.painTypes,
                locations: draft.locations,
                symptoms: draft.symptoms,
                triggers: draft.triggers,
                medications: draft.medications,
                medicationEffect: draft.medicationEffect,
                notes: draft.notes
            )
            modelContext.insert(entry)
        case .edit(let entry):
            entry.apply(draft)
        }
        dismiss()
    }
}

#Preview {
    EntryEditorView(mode: .new)
        .modelContainer(PreviewData.container)
}
