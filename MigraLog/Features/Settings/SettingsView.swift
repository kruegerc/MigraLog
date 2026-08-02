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
        let pageRect = CGRect(x: 0, y: 0, width: 842, height: 595)
        let margin: CGFloat = 28
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tableWidth = pageRect.width - (2 * margin)
        let columns: [(title: String, width: CGFloat)] = [
            ("Beginn", 74),
            ("Ende", 66),
            ("Dauer", 48),
            ("Int.", 32),
            ("Art", 82),
            ("Ort", 68),
            ("Symptome", 96),
            ("Auslöser", 88),
            ("Medikamente", 90),
            ("Wirkung", 76),
            ("Notiz", tableWidth - 720)
        ]

        return renderer.pdfData { context in
            var y = margin
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let bodyFont = UIFont.systemFont(ofSize: 8)
            let headerFont = UIFont.boldSystemFont(ofSize: 8)
            let summaryFont = UIFont.systemFont(ofSize: 10)

            func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .label) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                NSString(string: text).draw(
                    with: rect.insetBy(dx: 3, dy: 3),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
            }

            func textHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraph
                ]
                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: width - 6, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                return ceil(rect.height) + 8
            }

            func drawTableHeader() {
                var x = margin
                let rowHeight: CGFloat = 24
                UIColor.systemGray5.setFill()
                UIBezierPath(rect: CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)).fill()
                for column in columns {
                    let rect = CGRect(x: x, y: y, width: column.width, height: rowHeight)
                    UIColor.systemGray3.setStroke()
                    UIBezierPath(rect: rect).stroke()
                    drawText(column.title, in: rect, font: headerFont)
                    x += column.width
                }
                y += rowHeight
            }

            func drawHeader() {
                context.beginPage()
                y = margin
                drawText("MigraLog Arztbericht", in: CGRect(x: margin, y: y, width: tableWidth, height: 24), font: titleFont)
                y += 27
                drawText(
                    "Erstellt am \(MigraFormat.dateTime.string(from: Date())) | Einträge: \(entries.count) | Ø Intensität: \(averageIntensity(entries)) | Ø Dauer: \(averageDuration(entries))",
                    in: CGRect(x: margin, y: y, width: tableWidth, height: 18),
                    font: summaryFont,
                    color: .secondaryLabel
                )
                y += 25
                drawText(
                    "Hinweis: Dieser Bericht fasst lokal gespeicherte Kopfschmerzepisoden zusammen und ersetzt keine medizinische Diagnose oder Behandlung.",
                    in: CGRect(x: margin, y: y, width: tableWidth, height: 30),
                    font: summaryFont
                )
                y += 37
                drawTableHeader()
            }

            func beginPageIfNeeded(rowHeight: CGFloat) {
                if y + rowHeight > pageRect.height - margin {
                    drawHeader()
                }
            }

            func drawRow(_ values: [String], rowIndex: Int) {
                let rowHeight = max(28, zip(values, columns).map { pair in
                    textHeight(pair.0, width: pair.1.width, font: bodyFont)
                }.max() ?? 28)
                beginPageIfNeeded(rowHeight: rowHeight)

                var x = margin
                if rowIndex.isMultiple(of: 2) {
                    UIColor.systemGray6.setFill()
                    UIBezierPath(rect: CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)).fill()
                }

                for (value, column) in zip(values, columns) {
                    let rect = CGRect(x: x, y: y, width: column.width, height: rowHeight)
                    UIColor.systemGray4.setStroke()
                    UIBezierPath(rect: rect).stroke()
                    drawText(value, in: rect, font: bodyFont)
                    x += column.width
                }
                y += rowHeight
            }

            drawHeader()
            for (index, entry) in entries.enumerated() {
                drawRow(pdfRow(for: entry), rowIndex: index)
            }
        }
    }

    private func pdfRow(for entry: HeadacheEntry) -> [String] {
        [
            MigraFormat.dateTime.string(from: entry.startedAt),
            entry.endedAt.map { MigraFormat.dateTime.string(from: $0) } ?? "Offen",
            MigraFormat.duration(entry.duration),
            "\(entry.intensity)/10",
            listText(entry.painTypes),
            listText(entry.locations),
            listText(entry.symptoms),
            listText(entry.triggers),
            entry.medicationsText.isEmpty ? "Nicht erfasst" : entry.medicationsText,
            entry.medicationEffect.title,
            entry.notes
        ]
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
