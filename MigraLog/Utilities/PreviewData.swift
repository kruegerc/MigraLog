import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static var container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HeadacheEntry.self, configurations: configuration)

        container.mainContext.insert(
            HeadacheEntry(
                startedAt: Date().addingTimeInterval(-8 * 60 * 60),
                endedAt: Date().addingTimeInterval(-5 * 60 * 60),
                intensity: 7,
                painTypes: ["Pulsierend"],
                locations: ["Schläfe"],
                symptoms: ["Lichtempfindlichkeit", "Übelkeit"],
                triggers: ["Schlafmangel"],
                medications: "Ibuprofen",
                medicationEffect: .good,
                notes: "Nach Ruhe besser."
            )
        )

        return container
    }()
}
