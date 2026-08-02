import Foundation

struct EntryDraft {
    var startedAt: Date = Date()
    var hasEndedAt = false
    var endedAt: Date = Date()
    var intensity = 5
    var painTypes: [String] = []
    var locations: [String] = []
    var symptoms: [String] = []
    var triggers: [String] = []
    var medications = "Rizatriptan 10 mg"
    var medicationEffect: MedicationEffect = .notRecorded
    var notes = ""

    init() {}

    init(entry: HeadacheEntry) {
        startedAt = entry.startedAt
        hasEndedAt = entry.endedAt != nil
        endedAt = entry.endedAt ?? entry.startedAt
        intensity = entry.intensity
        painTypes = entry.painTypes
        locations = entry.locations
        symptoms = entry.symptoms
        triggers = entry.triggers
        medications = entry.medicationsText
        medicationEffect = entry.medicationEffect
        notes = entry.notes
    }

    var isValid: Bool {
        (0...10).contains(intensity) && (!hasEndedAt || endedAt >= startedAt)
    }
}
