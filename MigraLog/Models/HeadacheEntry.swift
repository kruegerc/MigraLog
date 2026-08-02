import Foundation
import SwiftData

@Model
final class HeadacheEntry {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var intensity: Int
    var painTypesText: String
    var locationsText: String
    var symptomsText: String
    var triggersText: String
    var medicationsText: String
    var medicationEffectRaw: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        intensity: Int,
        painTypes: [String] = [],
        locations: [String] = [],
        symptoms: [String] = [],
        triggers: [String] = [],
        medications: String = "",
        medicationEffect: MedicationEffect = .notRecorded,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.intensity = Self.clampedIntensity(intensity)
        self.painTypesText = Self.encode(painTypes)
        self.locationsText = Self.encode(locations)
        self.symptomsText = Self.encode(symptoms)
        self.triggersText = Self.encode(triggers)
        self.medicationsText = medications
        self.medicationEffectRaw = medicationEffect.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return max(0, endedAt.timeIntervalSince(startedAt))
    }

    var painTypes: [String] {
        get { Self.decode(painTypesText) }
        set { painTypesText = Self.encode(newValue) }
    }

    var locations: [String] {
        get { Self.decode(locationsText) }
        set { locationsText = Self.encode(newValue) }
    }

    var symptoms: [String] {
        get { Self.decode(symptomsText) }
        set { symptomsText = Self.encode(newValue) }
    }

    var triggers: [String] {
        get { Self.decode(triggersText) }
        set { triggersText = Self.encode(newValue) }
    }

    var medicationEffect: MedicationEffect {
        get { MedicationEffect(rawValue: medicationEffectRaw) ?? .notRecorded }
        set { medicationEffectRaw = newValue.rawValue }
    }

    func apply(_ draft: EntryDraft) {
        startedAt = draft.startedAt
        endedAt = draft.hasEndedAt ? draft.endedAt : nil
        intensity = Self.clampedIntensity(draft.intensity)
        painTypes = draft.painTypes
        locations = draft.locations
        symptoms = draft.symptoms
        triggers = draft.triggers
        medicationsText = draft.medications
        medicationEffect = draft.medicationEffect
        notes = draft.notes
        updatedAt = Date()
    }

    static func clampedIntensity(_ value: Int) -> Int {
        min(10, max(0, value))
    }

    static func encode(_ values: [String]) -> String {
        values.sorted().joined(separator: "\n")
    }

    static func decode(_ value: String) -> [String] {
        value
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}

enum MedicationEffect: String, Codable, CaseIterable, Identifiable {
    case notRecorded
    case none
    case slight
    case good
    case complete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notRecorded: "Nicht erfasst"
        case .none: "Keine Wirkung"
        case .slight: "Leichte Wirkung"
        case .good: "Gute Wirkung"
        case .complete: "Beschwerdefrei"
        }
    }
}
