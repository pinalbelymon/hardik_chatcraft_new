import Foundation
var checks = 0
func expect(_ value: @autoclosure () -> Bool, _ reason: String) {
    precondition(value(), reason)
    checks += 1
}
let payload = AnalyticsPayload.sanitize(["message_text": "private", "character_name": "private", "email": "private", "photo": Data([1]), "message_count": 4, "format": "vertical916", "reason": String(repeating: "a", count: 130), "duration_ms": Double.infinity, "value": Data([2])])
expect(payload["message_text"] == nil, "Message content leaked")
expect(payload["character_name"] == nil, "Character name leaked")
expect(payload["email"] == nil, "Email leaked")
expect(payload["photo"] == nil, "Photo data leaked")
expect(payload["message_count"] as? Int == 4, "Numeric count dropped")
expect(payload["format"] as? String == "vertical916", "Format dropped")
expect((payload["reason"] as? String)?.count == 100, "String bound failed")
expect(payload["duration_ms"] == nil, "Nonfinite numeric value accepted")
expect(payload["value"] == nil, "Binary payload accepted")
var ledger = AnalyticsTransactionLedger()
expect(ledger.register("verified_1"), "First transaction rejected")
expect(!ledger.register("verified_1"), "Duplicate purchase accepted")
var restored = AnalyticsTransactionLedger(storedIDs: ledger.ids)
expect(!restored.register("verified_1"), "Duplicate after restart accepted")
for i in 2...600 { _ = ledger.register("verified_\(i)") }
expect(ledger.ids.count == 500, "Transaction ledger unbounded")
expect(ledger.ids.last == "verified_600", "Newest transaction discarded")
expect(AnalyticsTransactionLedger(storedIDs: (0..<900).map(String.init)).ids.count == 500, "Loaded ledger unbounded")
print("Passed \(checks) analytics privacy/deduplication checks")
