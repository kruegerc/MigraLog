import SwiftUI

struct MultiSelectList: View {
    let title: String
    let options: [String]
    @Binding var selection: [String]

    var body: some View {
        Section(title) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    toggle(option)
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        if selection.contains(option) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private func toggle(_ option: String) {
        if selection.contains(option) {
            selection.removeAll { $0 == option }
        } else {
            selection.append(option)
        }
    }
}
