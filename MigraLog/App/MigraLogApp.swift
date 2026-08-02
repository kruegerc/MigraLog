import SwiftData
import SwiftUI

@main
struct MigraLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: HeadacheEntry.self)
    }
}
