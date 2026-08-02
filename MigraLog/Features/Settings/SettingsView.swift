import SwiftData
import SwiftUI
import UIKit

private enum ExportPeriod: String, CaseIterable, Identifiable {
    case all = "Alle"
    case sevenDays = "7 Tage"
    case thirtyDays = "30 Tage"
    case ninetyDays = "90 Tage"
    case thisYear = "Dieses Jahr"
    case custom = "Eigener Zeitraum"

    var id: String { rawValue }

    func range(customStart: Date, customEnd: Date, calendar: Calendar = .current) -> ClosedRange<Date>? {
        let now = Date()
        switch self {
        case .all:
            return nil
        case .sevenDays:
            return rangeFrom(days: 7, now: now, calendar: calendar)
        case .thirtyDays:
            return rangeFrom(days: 30, now: now, calendar: calendar)
        case .ninetyDays:
            return rangeFrom(days: 90, now: now, calendar: calendar)
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            return start...now
        case .custom:
            let start = calendar.startOfDay(for: customStart)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEnd) ?? customEnd
            return min(start, end)...max(start, end)
        }
    }

    private func rangeFrom(days: Int, now: Date, calendar: Calendar) -> ClosedRange<Date> {
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now)) ?? now
        return start...now
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [HeadacheEntry]
    @State private var showsDeleteConfirmation = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var exportPeriod: ExportPeriod = .all
    @State private var customExportStart = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customExportEnd = Date()

    private var exportEntries: [HeadacheEntry] {
        let sortedEntries = entries.sorted { $0.startedAt < $1.startedAt }
        guard let range = exportPeriod.range(customStart: customExportStart, customEnd: customExportEnd) else {
            return sortedEntries
        }
        return sortedEntries.filter { range.contains($0.startedAt) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Export") {
                    Picker("Zeitraum", selection: $exportPeriod) {
                        ForEach(ExportPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }

                    if exportPeriod == .custom {
                        DatePicker("Von", selection: $customExportStart, displayedComponents: .date)
                        DatePicker("Bis", selection: $customExportEnd, displayedComponents: .date)
                    }

                    LabeledContent("Einträge im Export", value: "\(exportEntries.count)")

                    Button {
                        createPDFExport()
                    } label: {
                        Label("PDF für Arzttermin erstellen", systemImage: "doc.richtext")
                    }
                    .disabled(exportEntries.isEmpty)

                    Button {
                        createCSVExport()
                    } label: {
                        Label("CSV-Rohdaten erstellen", systemImage: "tablecells")
                    }
                    .disabled(exportEntries.isEmpty)

                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Export teilen", systemImage: "square.and.arrow.up")
                        }
                    }

                    if entries.isEmpty {
                        Text("Der Export ist verfügbar, sobald mindestens ein Eintrag vorhanden ist.")
                            .foregroundStyle(.secondary)
                    } else if exportEntries.isEmpty {
                        Text("Keine Einträge im gewählten Zeitraum.")
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

    private var exportPeriodLabel: String {
        if let range = exportPeriod.range(customStart: customExportStart, customEnd: customExportEnd) {
            return "\(MigraFormat.date.string(from: range.lowerBound)) - \(MigraFormat.date.string(from: range.upperBound))"
        }
        return "Alle Einträge"
    }

    private func createPDFExport() {
        do {
            let data = makePDF(entries: exportEntries, periodLabel: exportPeriodLabel)
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
            let csv = makeCSV(entries: exportEntries, periodLabel: exportPeriodLabel)
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

    private func makePDF(entries: [HeadacheEntry], periodLabel: String) -> Data {
        let landscapeRect = CGRect(x: 0, y: 0, width: 842, height: 595)
        let portraitRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 28
        let renderer = UIGraphicsPDFRenderer(bounds: landscapeRect)
        let tableWidth = landscapeRect.width - (2 * margin)
        let columns: [(title: String, width: CGFloat)] = [
            ("Nr.", 28),
            ("Beginn", 86),
            ("Ende", 78),
            ("Dauer", 52),
            ("Int.", 34),
            ("Art", 112),
            ("Ort", 88),
            ("Symptome", 124),
            ("Auslöser", 112),
            ("Wirkung", tableWidth - 714)
        ]

        return renderer.pdfData { context in
            var y = margin
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let bodyFont = UIFont.systemFont(ofSize: 8)
            let headerFont = UIFont.boldSystemFont(ofSize: 8)
            let summaryFont = UIFont.systemFont(ofSize: 10)
            let detailTitleFont = UIFont.boldSystemFont(ofSize: 15)
            let detailBodyFont = UIFont.systemFont(ofSize: 11)
            let detailLabelFont = UIFont.boldSystemFont(ofSize: 11)

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

            func drawSummaryTableHeader() {
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

            func drawSummaryHeader() {
                context.beginPage(withBounds: landscapeRect, pageInfo: [:])
                y = margin
                drawText("MigraLog Arztbericht", in: CGRect(x: margin, y: y, width: tableWidth, height: 24), font: titleFont)
                y += 27
                drawText(
                    "Zeitraum: \(periodLabel) | Erstellt am \(MigraFormat.dateTime.string(from: Date())) | Einträge: \(entries.count) | Ø Intensität: \(averageIntensity(entries)) | Ø Dauer: \(averageDuration(entries))",
                    in: CGRect(x: margin, y: y, width: tableWidth, height: 30),
                    font: summaryFont,
                    color: .secondaryLabel
                )
                y += 34
                drawText(
                    "Teil 1 zeigt eine kompakte Übersicht. Vollständige Detailangaben stehen im Anhang ab Seite 2.",
                    in: CGRect(x: margin, y: y, width: tableWidth, height: 28),
                    font: summaryFont
                )
                y += 35
                drawSummaryTableHeader()
            }

            func beginSummaryPageIfNeeded(rowHeight: CGFloat) {
                if y + rowHeight > landscapeRect.height - margin {
                    drawSummaryHeader()
                }
            }

            func drawSummaryRow(_ values: [String], rowIndex: Int) {
                let rowHeight = max(28, zip(values, columns).map { pair in
                    textHeight(pair.0, width: pair.1.width, font: bodyFont)
                }.max() ?? 28)
                beginSummaryPageIfNeeded(rowHeight: rowHeight)

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

            func drawDetailLine(label: String, value: String, pageWidth: CGFloat) {
                let text = "\(label): \(value)"
                let height = textHeight(text, width: pageWidth - (2 * margin), font: detailBodyFont)
                if y + height > portraitRect.height - margin {
                    context.beginPage(withBounds: portraitRect, pageInfo: [:])
                    y = margin
                }
                drawText(label + ":", in: CGRect(x: margin, y: y, width: 110, height: height), font: detailLabelFont)
                drawText(value, in: CGRect(x: margin + 112, y: y, width: pageWidth - (2 * margin) - 112, height: height), font: detailBodyFont)
                y += height
            }

            func drawDetailEntry(_ entry: HeadacheEntry, index: Int) {
                let pageWidth = portraitRect.width
                if y + 190 > portraitRect.height - margin {
                    context.beginPage(withBounds: portraitRect, pageInfo: [:])
                    y = margin
                }

                drawText("Eintrag \(index)", in: CGRect(x: margin, y: y, width: pageWidth - (2 * margin), height: 24), font: detailTitleFont)
                y += 28
                drawDetailLine(label: "Beginn", value: MigraFormat.dateTime.string(from: entry.startedAt), pageWidth: pageWidth)
                drawDetailLine(label: "Ende", value: entry.endedAt.map { MigraFormat.dateTime.string(from: $0) } ?? "Offen", pageWidth: pageWidth)
                drawDetailLine(label: "Dauer", value: MigraFormat.duration(entry.duration), pageWidth: pageWidth)
                drawDetailLine(label: "Intensität", value: "\(entry.intensity)/10", pageWidth: pageWidth)
                drawDetailLine(label: "Schmerzart", value: listText(entry.painTypes), pageWidth: pageWidth)
                drawDetailLine(label: "Lokalisation", value: listText(entry.locations), pageWidth: pageWidth)
                drawDetailLine(label: "Symptome", value: listText(entry.symptoms), pageWidth: pageWidth)
                drawDetailLine(label: "Auslöser", value: listText(entry.triggers), pageWidth: pageWidth)
                drawDetailLine(label: "Medikamente", value: entry.medicationsText.isEmpty ? "Nicht erfasst" : entry.medicationsText, pageWidth: pageWidth)
                drawDetailLine(label: "Wirkung", value: entry.medicationEffect.title, pageWidth: pageWidth)
                drawDetailLine(label: "Notiz", value: entry.notes.isEmpty ? "Nicht erfasst" : entry.notes, pageWidth: pageWidth)
                y += 12
            }

            drawSummaryHeader()
            for (index, entry) in entries.enumerated() {
                drawSummaryRow(summaryRow(for: entry, index: index + 1), rowIndex: index)
            }

            context.beginPage(withBounds: portraitRect, pageInfo: [:])
            y = margin
            drawText("Detailanhang", in: CGRect(x: margin, y: y, width: portraitRect.width - (2 * margin), height: 28), font: titleFont)
            y += 34
            drawText("Zeitraum: \(periodLabel)", in: CGRect(x: margin, y: y, width: portraitRect.width - (2 * margin), height: 20), font: summaryFont, color: .secondaryLabel)
            y += 26
            for (index, entry) in entries.enumerated() {
                drawDetailEntry(entry, index: index + 1)
            }
        }
    }

    private func summaryRow(for entry: HeadacheEntry, index: Int) -> [String] {
        [
            "\(index)",
            MigraFormat.dateTime.string(from: entry.startedAt),
            entry.endedAt.map { MigraFormat.dateTime.string(from: $0) } ?? "Offen",
            MigraFormat.duration(entry.duration),
            "\(entry.intensity)/10",
            listText(entry.painTypes),
            listText(entry.locations),
            listText(entry.symptoms),
            listText(entry.triggers),
            entry.medicationEffect.title
        ]
    }

    private func makeCSV(entries: [HeadacheEntry], periodLabel: String) -> String {
        var rows: [[String]] = [
            ["MigraLog Export"],
            ["Zeitraum", periodLabel],
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
