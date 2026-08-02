import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [HeadacheEntry]
    @State private var showsDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
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
            .confirmationDialog("Alle Einträge löschen?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
                Button("Alle löschen", role: .destructive) {
                    for entry in entries {
                        modelContext.delete(entry)
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
