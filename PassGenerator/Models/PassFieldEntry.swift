import Foundation

/// One key/label/value row that becomes a field entry (primaryFields, secondaryFields, ...) in pass.json.
struct PassFieldEntry: Identifiable {
    let id = UUID()
    var key: String = ""
    var label: String = ""
    var value: String = ""

    var isValid: Bool {
        !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toDictionary() -> [String: String] {
        var dict: [String: String] = [
            "key": key.trimmingCharacters(in: .whitespacesAndNewlines),
            "value": value
        ]
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLabel.isEmpty {
            dict["label"] = trimmedLabel
        }
        return dict
    }
}
