import SwiftData
import SwiftUI

enum EntryEditorMode {
    case new
    case edit(HeadacheEntry)
}

private enum EntryEditorPage: String, CaseIterable, Identifiable {
    case basis = "Basis"
    case details = "Details"
    case scrollTest = "Scroll-Test"

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
                case .scrollTest:
                    scrollTestContent
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }

    private var basisContent: some View {
        Group {
            Section {
                intensityPicker
            } header: {
                Text("Intensitaet")
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
    }

    private var scrollTestContent: some View {
        Group {
            Section("Scroll-Test") {
                ForEach(1...30, id: \.self) { number in
                    HStack {
                        Text("Testzeile \(number)")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                }
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

    private var startDateControls: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                startAdjustButton("-1 Tag", systemImage: "chevron.left") {
                    adjustStart(.day, by: -1)
                }
                startAdjustButton("Heute", systemImage: "calendar") {
                    setStartToTodayKeepingTime()
                }
                startAdjustButton("+1 Tag", systemImage: "chevron.right") {
                    adjustStart(.day, by: 1)
                }

                startAdjustButton("-1 h", systemImage: "minus") {
                    adjustStart(.hour, by: -1)
                }
                startAdjustButton("-15 min", systemImage: "minus.circle") {
                    adjustStart(.minute, by: -15)
                }
                startAdjustButton("+15 min", systemImage: "plus.circle") {
                    adjustStart(.minute, by: 15)
                }

                startAdjustButton("+1 h", systemImage: "plus") {
                    adjustStart(.hour, by: 1)
                }
            }

            Toggle("Ende erfassen", isOn: $draft.hasEndedAt)
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private func startAdjustButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 42)
        }
        .buttonStyle(.bordered)
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

    private func setStartToTodayKeepingTime() {
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: draft.startedAt)
        var today = calendar.dateComponents([.year, .month, .day], from: Date())
        today.hour = currentTime.hour
        today.minute = currentTime.minute
        if let newDate = calendar.date(from: today) {
            setStart(newDate)
        }
    }

    private func adjustStart(_ component: Calendar.Component, by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: component, value: value, to: draft.startedAt) else {
            return
        }
        setStart(newDate)
    }

    private func setStart(_ date: Date) {
        draft.startedAt = date
        if !draft.hasEndedAt {
            draft.endedAt = date
        } else if draft.endedAt < draft.startedAt {
            draft.endedAt = draft.startedAt
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
