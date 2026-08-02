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
                Section {
                    intensityPicker
                } header: {
                    Text("Intensitaet")
                }

                Section("Schmerzart") {
                    painTypePicker
                }

                Section("Beginn") {
                    Button {
                        let now = Date()
                        draft.startedAt = now
                        if !draft.hasEndedAt {
                            draft.endedAt = now
                        }
                    } label: {
                        Label("Jetzt setzen", systemImage: "clock")
                    }

                    DatePicker("Beginn", selection: $draft.startedAt)

                    Toggle("Ende erfassen", isOn: $draft.hasEndedAt)

                    if draft.hasEndedAt {
                        DatePicker("Ende", selection: $draft.endedAt, in: draft.startedAt...)
                    }
                }

                optionSection("Symptome", options: HeadacheOptions.symptoms, selection: $draft.symptoms)
                optionSection("Ausloeser", options: HeadacheOptions.triggers, selection: $draft.triggers)
                optionSection("Lokalisation", options: HeadacheOptions.locations, selection: $draft.locations)

                Section("Medikamente") {
                    TextField("Medikament oder Dosis", text: $draft.medications, axis: .vertical)
                        .lineLimit(1...3)

                    Picker("Wirkung", selection: $draft.medicationEffect) {
                        ForEach(MedicationEffect.allCases) { effect in
                            Text(effect.title).tag(effect)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notiz") {
                    TextField("Was ist wichtig?", text: $draft.notes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(navigationTitle)
            .scrollDismissesKeyboard(.interactively)
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

    private var intensityPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("\(draft.intensity)/10")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(intensityColor(draft.intensity))
                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(Array(0...10), id: \.self) { value in
                    Button {
                        draft.intensity = value
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: intensityIcon(value))
                                .font(.headline.weight(.semibold))
                            Text("\(value)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
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
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private var painTypePicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            ForEach(Array(HeadacheOptions.painTypes.enumerated()), id: \.offset) { _, option in
                let isSelected = draft.painTypes.contains(option)
                Button {
                    toggle(option, in: $draft.painTypes)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.headline.weight(.semibold))
                        Text(option)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .padding(.horizontal, 10)
                    .foregroundColor(isSelected ? Color.white : Color.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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

    private func optionSection(_ title: String, options: [String], selection: Binding<[String]>) -> some View {
        Section(title) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let isSelected = selection.wrappedValue.contains(option)
                Button {
                    toggle(option, in: selection)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(isSelected ? Color.accentColor : Color.secondary)

                        Text(option)
                            .font(.headline)
                            .foregroundColor(Color.primary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
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
