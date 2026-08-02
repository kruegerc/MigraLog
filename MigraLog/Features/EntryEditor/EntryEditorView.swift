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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    quickTimeControls
                    intensityPicker
                    chipSection("Schmerzart", options: HeadacheOptions.painTypes, selection: $draft.painTypes)
                    chipSection("Symptome", options: HeadacheOptions.symptoms, selection: $draft.symptoms)
                    chipSection("Ausloeser", options: HeadacheOptions.triggers, selection: $draft.triggers)
                    chipSection("Lokalisation", options: HeadacheOptions.locations, selection: $draft.locations)
                    medicationControls
                    notesControl
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 110)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveBar
            }
        }
    }

    private var quickTimeControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Beginn")
                    .font(.headline)
                Spacer()
                Button("Jetzt") {
                    let now = Date()
                    draft.startedAt = now
                    if !draft.hasEndedAt {
                        draft.endedAt = now
                    }
                }
                .buttonStyle(.bordered)
            }

            DatePicker("Beginn", selection: $draft.startedAt)
                .datePickerStyle(.compact)

            Toggle("Ende erfassen", isOn: $draft.hasEndedAt)

            if draft.hasEndedAt {
                DatePicker("Ende", selection: $draft.endedAt, in: draft.startedAt...)
                    .datePickerStyle(.compact)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var intensityPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Intensitaet")
                    .font(.headline)
                Spacer()
                Text("\(draft.intensity)/10")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(intensityColor(draft.intensity))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(Array(0...10), id: \.self) { value in
                    Button {
                        draft.intensity = value
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: intensityIcon(value))
                                .font(.title3.weight(.semibold))
                            Text("\(value)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundColor(draft.intensity == value ? Color.white : intensityColor(value))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(draft.intensity == value ? intensityColor(value) : intensityColor(value).opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(intensityColor(value).opacity(0.55), lineWidth: draft.intensity == value ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Intensitaet \(value) von 10")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var medicationControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Medikamente")
                .font(.headline)

            TextField("Medikament oder Dosis", text: $draft.medications, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Picker("Wirkung", selection: $draft.medicationEffect) {
                ForEach(MedicationEffect.allCases) { effect in
                    Text(effect.title).tag(effect)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var notesControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notiz")
                .font(.headline)

            TextField("Was ist wichtig?", text: $draft.notes, axis: .vertical)
                .lineLimit(4...8)
                .textFieldStyle(.roundedBorder)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                save()
            } label: {
                Label("Speichern", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!draft.isValid)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(.bar)
    }

    private func chipSection(_ title: String, options: [String], selection: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    let isSelected = selection.wrappedValue.contains(option)
                    Button {
                        toggle(option, in: selection)
                    } label: {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(option)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .padding(.horizontal, 10)
                        .foregroundColor(isSelected ? Color.white : Color.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var navigationTitle: String {
        switch mode {
        case .new: "Schnellerfassung"
        case .edit: "Eintrag bearbeiten"
        }
    }

    private func intensityColor(_ value: Int) -> Color {
        switch value {
        case 0...2: .teal
        case 3...5: .orange
        case 6...8: .red
        default: .purple
        }
    }

    private func intensityIcon(_ value: Int) -> String {
        switch value {
        case 0...2: "circle"
        case 3...5: "circle.lefthalf.filled"
        case 6...8: "flame.fill"
        default: "exclamationmark.triangle.fill"
        }
    }

    private func toggle(_ option: String, in selection: Binding<[String]>) {
        if selection.wrappedValue.contains(option) {
            selection.wrappedValue.removeAll { $0 == option }
        } else {
            selection.wrappedValue.append(option)
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
