import Foundation

struct FollowUpDraft: Codable, Sendable {
  let version: Int
  let subject: String
  let body: String
  let calendly: String
  let evidenceIds: [String]
}
struct ArmWindow: Codable, Sendable { let epoch: String; let minCaptureMs: Double; let deadline: Double }
struct FollowUpSession: Codable, Sendable {
  let id: String
  let phase: String
  let recipient: String
  let confirmed: Bool
  let draft: FollowUpDraft?
  let approved: FollowUpDraft?
  let epoch: String
  let source: String
  let reviewPage: Int
  let arm: ArmWindow?
  let outcome: String
  let outboxId: String?
}
struct Envelope: Codable, Sendable {
  let session: FollowUpSession; let pages: [String]; let cue: String
  let serverNow: Double?
  var transportElapsedMs: Double?
}
struct CapturedText: Sendable {
  let text: String
  let final: Bool
  let epoch: String
  let capturedMs: Double
  let confidence: Float?
}
enum FollowUpFailure: LocalizedError {
  case message(String)
  var errorDescription: String? { if case let .message(s) = self { s } else { nil } }
}
enum CueGuard {
  static func normalized(_ phrase: String) -> String {
    phrase.precomposedStringWithCompatibilityMapping.lowercased()
      .replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "‘", with: "'")
      .components(separatedBy: CharacterSet(charactersIn: ".,!?;:-–—").union(.whitespacesAndNewlines))
      .filter { !$0.isEmpty }.joined(separator: " ")
  }
  static func matches(_ text: CapturedText, phrase: String, epoch: String, boundary: Double) -> Bool {
    text.final && text.epoch == epoch && text.capturedMs > boundary && !phrase.isEmpty
      && normalized(text.text) == normalized(phrase)
  }
}
