import Foundation

enum MigraFormat {
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func duration(_ interval: TimeInterval?) -> String {
        guard let interval else { return "Offen" }
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours == 0 {
            return "\(remainingMinutes) min"
        }
        return "\(hours) h \(remainingMinutes) min"
    }
}
