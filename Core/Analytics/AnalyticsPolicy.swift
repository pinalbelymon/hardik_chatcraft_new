import Foundation

enum AnalyticsPayload {
    private static let allowedKeys: Set<String> = ["theme_id", "format", "scope", "media_type", "message_count", "character_count", "plan", "cadence", "product_id", "result", "source", "speed", "step", "option", "value", "duration_ms", "reason", "completed", "link", "category"]
    static func sanitize(_ parameters: [String: Any]) -> [String: Any] {
        var safe: [String: Any] = [:]
        for (key, value) in parameters where allowedKeys.contains(key) {
            if let text = value as? String { safe[key] = String(text.prefix(100)) }
            else if let number = value as? NSNumber, number.doubleValue.isFinite { safe[key] = number }
        }
        return safe
    }
}

struct AnalyticsTransactionLedger {
    private(set) var ids: [String]
    init(storedIDs: [String] = []) { ids = Array(storedIDs.suffix(500)) }
    mutating func register(_ id: String) -> Bool {
        guard !ids.contains(id) else { return false }
        ids.append(id)
        ids = Array(ids.suffix(500))
        return true
    }
}
