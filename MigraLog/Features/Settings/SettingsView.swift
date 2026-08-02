import SwiftData
import SwiftUI
import UIKit

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
                        createPDFExport()
                    } label: {
                        Label("PDF für Arzttermin erstellen", systemImage: "doc.richtext")
                    }
                    .disabled(entries.isEmpty)

                    Button {
                        createCSVExport()
                    } label: {
                        Label("CSV-Rohdaten erstellen", systemImage: "tablecells")
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

    private func createPDFExport() {
        do {
            let sortedEntries = entries.sorted { $0.startedAt < $1.startedAt }
            let data = makePDF(entries: sortedEntries)
            let fileName = "MigraLog-Arztbericht-\(Self.fileDateFormatter.string(from: Date())).pdf"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: fileURL, options: .atomic)
            exportURL = fileURL
            exportError = nil
        } catch {
            exportURL = nil
            exportError = error.localizedDescription
        }
    }

    private func createCSVExport() {
        do {
            let csv = makeCSV(entries: entries.sorted { $0.startedAt < $1.startedAt })
            let fileName = "MigraLog-Rohdaten-\(Self.fileDateFormatter.string(from: Date())).csv"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            exportError = nil
        } catch {
            exportURL = nil
            exportError = error.localizedDescription
        }
    }

    private func makePDF(entries: [HeadacheEntry]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 44
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            var y = margin

            func beginPageIfNeeded(requiredHeight: CGFloat) {
                if y + requiredHeight > pageRect.height - margin {
                    context.beginPage()
                    y = margin
                }
            }

            func draw(_ text: String, font: UIFont, color: UIColor = .label, spacing: CGFloat = 8) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let width = pageRect.width - (2 * margin)
                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                beginPageIfNeeded(requiredHeight: ceil(rect.height) + spacing)
                NSString(string: text).draw(
                    with: CGRect(x: margin, y: y, width: width, height: ceil(rect.height) + 4),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                y += ceil(rect.height) + spacing
            }

            func drawEntry(_ entry: HeadacheEntry, index: Int) {
                beginPageIfNeeded(requiredHeight: 170)
                draw("\(index). \(MigraFormat.dateTime.string(from: entry.startedAt))", font: .boldSystemFont(ofSize: 15), spacing: 6)
                draw("Intensität: \(entry.intensity)/10 | Dauer: \(MigraFormat.duration(entry.duration))", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Ende: \(entry.endedAt.map { MigraFormat.dateTime.string(from: $0) } ?? "Offen")", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Schmerzart: \(listText(entry.painTypes))", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Lokalisation: \(listText(entry.locations))", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Symptome: \(listText(entry.symptoms))", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Auslöser: \(listText(entry.triggers))", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Medikamente: \(entry.medicationsText.isEmpty ? "Nicht erfasst" : entry.medicationsText)", font: .systemFont(ofSize: 12), spacing: 4)
                draw("Wirkung: \(entry.medicationEffect.title)", font: .systemFont(ofSize: 12), spacing: 4)
                if !entry.notes.isEmpty {
                    draw("Notiz: \(entry.notes)", font: .systemFont(ofSize: 12), spacing: 4)
                }
                y += 8
            }

            context.beginPage()
            draw("MigraLog Arztbericht", font: .boldSystemFont(ofSize: 24), spacing: 10)
            draw("Erstellt am \(MigraFormat.dateTime.string(from: Date()))", font: .systemFont(ofSize: 12), color: .secondaryLabel, spacing: 14)
            draw("Dieser Bericht fasst die lokal gespeicherten Kopfschmerz- und Migräneepisoden zusammen. MigraLog ersetzt keine medizinische Diagnose oder Behandlung.", font: .systemFont(ofSize: 12), spacing: 14)
            draw("Übersicht", font: .boldSystemFont(ofSize: 17), spacing: 8)
            draw("Einträge: \(entries.count)", font: .systemFont(ofSize: 12), spacing: 4)
            draw("Durchschnittliche Intensität: \(averageIntensity(entries))", font: .systemFont(ofSize: 12), spacing: 4)
            draw("Durchschnittliche Dauer: \(averageDuration(entries))", font: .systemFont(ofSize: 12), spacing: 14)
            draw("Einträge", font: .boldSystemFont(ofSize: 17), spacing: 8)

            for (index, entry) in entries.enumerated() {
                drawEntry(entry, index: index + 1)
            }
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

    private func averageIntensity(_ entries: [HeadacheEntry]) -> String {
        guard !entries.isEmpty else { return "-" }
        let value = Double(entries.map(\.intensity).reduce(0, +)) / Double(entries.count)
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private func averageDuration(_ entries: [HeadacheEntry]) -> String {
        let durations = entries.compactMap(\.duration)
        guard !durations.isEmpty else { return "-" }
        let average = durations.reduce(0, +) / Double(durations.count)
        return MigraFormat.duration(average)
    }

    private func listText(_ values: [String]) -> String {
        values.isEmpty ? "Nicht erfasst" : values.joined(separator: ", ")
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
