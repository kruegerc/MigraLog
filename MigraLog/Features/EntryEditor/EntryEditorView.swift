import SwiftData
import SwiftUI

enum EntryEditorMode {
    case new
    case edit(HeadacheEntry)
}

private enum EntryEditorPage: String, CaseIterable, Identifiable {
    case basis = "Basis"
    case details = "Details"

    var id: String { rawValue }
}

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let mode: EntryEditorMode
    @State private var draft: EntryDraft
    @State private var page: EntryEditorPage = .basis

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

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
                    Picker("Bereich", selection: $page) {
                        ForEach(EntryEditorPage.allCases) { page in
                            Text(page.rawValue).tag(page)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch page {
                case .basis:
                    basisContent
                case .details:
                    detailsContent
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

    private var basisContent: some View {
        Group {
            Section {
                intensityPicker
            } header: {
                Text("Intensität")
            }

            Section("Schmerzart") {
                painTypePicker
            }

            Section("Beginn") {
                startDateControls
            }
        }
    }

    private var detailsContent: some View {
        Group {
            optionSection("Symptome", options: HeadacheOptions.symptoms, selection: $draft.symptoms)
            optionSection("Auslöser", options: HeadacheOptions.triggers, selection: $draft.triggers)
            optionSection("Lokalisation", options: HeadacheOptions.locations, selection: $draft.locations)

            Section("Medikamente") {
                TextField("Medikament oder Dosis", text: $draft.medications, axis: .vertical)
                    .lineLimit(1...3)
            }

            Section("Wirkung") {
                medicationEffectPicker
            }

            Section("Notiz") {
                TextField("Was ist wichtig?", text: $draft.notes, axis: .vertical)
                    .lineLimit(4...8)
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
                    .accessibilityLabel("Intensität \(value) von 10")
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

    private var startDateControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    setStartToNow()
                } label: {
                    Label("Jetzt", systemImage: "clock")
                        .font(.headline)
                        .frame(minHeight: 42)
                }
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(MigraFormat.date.string(from: draft.startedAt))
                        .font(.headline)
                    Text(Self.timeFormatter.string(from: draft.startedAt))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            DatePicker("Datum", selection: $draft.startedAt, displayedComponents: .date)
                .datePickerStyle(.compact)

            VStack(alignment: .leading, spacing: 6) {
                Text("Uhrzeit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                DatePicker("Uhrzeit", selection: $draft.startedAt, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
            }

            Toggle("Ende erfassen", isOn: $draft.hasEndedAt)

            if draft.hasEndedAt {
                DatePicker("Ende Datum", selection: $draft.endedAt, in: draft.startedAt..., displayedComponents: .date)
                    .datePickerStyle(.compact)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ende Uhrzeit")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    DatePicker("Ende Uhrzeit", selection: $draft.endedAt, in: draft.startedAt..., displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .clipped()
                }
            }
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private var medicationEffectPicker: some View {
        VStack(spacing: 8) {
            ForEach(MedicationEffect.allCases) { effect in
                let isSelected = draft.medicationEffect == effect
                Button {
                    draft.medicationEffect = effect
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(isSelected ? Color.accentColor : Color.secondary)
                        Text(effect.title)
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

    private func setStartToNow() {
        let now = Date()
        draft.startedAt = now
        if !draft.hasEndedAt {
            draft.endedAt = now
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
