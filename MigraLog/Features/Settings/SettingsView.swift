import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [HeadacheEntry]
    @State private var showsDeleteConfirmation = false
    @State private var exportURL: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Export") {
                    Button {
                        createCSVExport()
                    } label: {
                        Label("CSV für Arzttermin erstellen", systemImage: "doc.text")
                    }
                    .disabled(entries.isEmpty)

                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Export teilen", systemImage: "square.and.arrow.up")
                        }
                    }

                    if entries.isEmpty {
                        Text("Der Export ist verfügbar, sobald mindestens ein Eintrag vorhanden ist.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Datenschutz") {
                    Text("Alle Daten werden lokal auf diesem Gerät gespeichert. MigraLog verwendet im MVP kein Benutzerkonto, keine Werbung und keine Analyse-SDKs.")
                }

                Section("Medizinischer Hinweis") {
                    Text("MigraLog ersetzt keine Diagnose oder Behandlung. Bei starken, neuen oder ungewöhnlichen Beschwerden sollte medizinischer Rat eingeholt werden.")
                }

                Section("Daten") {
                    Button("Alle Einträge löschen", role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                    .disabled(entries.isEmpty)
                }

                Section("App") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Speicherung", value: "Lokal")
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Export fehlgeschlagen", isPresented: exportErrorBinding) {
                Button("OK", role: .cancel) {
                    exportError = nil
                }
            } message: {
                Text(exportError ?? "Der Export konnte nicht erstellt werden.")
            }
            .confirmationDialog("Alle Einträge löschen?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
                Button("Alle löschen", role: .destructive) {
                    for entry in entries {
                        modelContext.delete(entry)
                    }
                    exportURL = nil
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { isPresented in
                if !isPresented {
                    exportError = nil
                }
            }
        )
    }

    private func createCSVExport() {
        do {
            let csv = makeCSV(entries: entries.sorted { $0.startedAt < $1.startedAt })
            let fileName = "MigraLog-Export-\(Self.fileDateFormatter.string(from: Date())).csv"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            exportError = nil
        } catch {
            exportURL = nil
            exportError = error.localizedDescription
        }
    }

    private func makeCSV(entries: [HeadacheEntry]) -> String {
        var rows: [[String]] = [
            ["MigraLog Export"],
            ["Erstellt am", MigraFormat.dateTime.string(from: Date())],
            ["Anzahl Einträge", "\(entries.count)"],
            [],
            [
                "Beginn",
                "Ende",
                "Dauer",
                "Intensität",
                "Schmerzart",
                "Lokalisation",
                "Symptome",
                "Auslöser",
                "Medikamente",
                "Wirkung",
                "Notiz"
            ]
        ]

        rows += entries.map { entry in
            [
                MigraFormat.dateTime.string(from: entry.startedAt),
                entry.endedAt.map { MigraFormat.dateTime.string(from: $0) } ?? "Offen",
                MigraFormat.duration(entry.duration),
                "\(entry.intensity)/10",
                entry.painTypes.joined(separator: ", "),
                entry.locations.joined(separator: ", "),
                entry.symptoms.joined(separator: ", "),
                entry.triggers.joined(separator: ", "),
                entry.medicationsText,
                entry.medicationEffect.title,
                entry.notes
            ]
        }

        return rows.map(csvRow).joined(separator: "\n")
    }

    private func csvRow(_ values: [String]) -> String {
        values.map(csvCell).joined(separator: ";")
    }

    private func csvCell(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
