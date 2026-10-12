import Foundation
import MWDATCore
import MWDATSpeech

@MainActor
final class MetaSpeechCapture {
  private var speech: Speech?
  private var session: DeviceSession?
  private var tokens: [AnyListenerToken] = []
  private var generation = UUID()
  private var hasStarted = false
  func start(session: DeviceSession, epoch: String, onText: @escaping @MainActor (CapturedText) -> Void,
    diagnostic: @escaping @MainActor (String) -> Void, failure: @escaping @MainActor (String) -> Void) throws {
    stop()
    guard let speech = try session.addSpeech() else { throw FollowUpFailure.message("Speech capability is unavailable on the started session.") }
    self.session = session; self.speech = speech; hasStarted = false
    let capturedGeneration = generation
    tokens = [
      speech.statePublisher.listen { [weak self] state in
        Task { @MainActor in
          guard self?.generation == capturedGeneration else { return }
          diagnostic("Meta Speech state: \(state). Audio routing is SDK-managed; no capture timestamp.")
          if state == .started { self?.hasStarted = true }
          if state == .stopped && self?.hasStarted == true { failure("Meta Speech stopped; session paused and disarmed.") }
        }
      },
      speech.localePublisher.listen { [weak self] locale in Task { @MainActor in
        guard self?.generation == capturedGeneration else { return }; diagnostic("Meta Speech locale: \(locale)")
      } },
      speech.errorPublisher.listen { [weak self] error in
        Task { @MainActor in guard self?.generation == capturedGeneration else { return }; failure(error.description) }
      },
      speech.transcriptionPublisher.listen { [weak self] result in
        let confidence: Float? = result.confidence.isFinite && result.confidence >= 0 ? result.confidence : nil
        let text = CapturedText(text: result.text, final: result.isFinal, epoch: epoch, capturedMs: 0, confidence: confidence)
        Task { @MainActor in guard self?.generation == capturedGeneration else { return }; onText(text) }
      }
    ]
    speech.start()
  }
  func stop() {
    generation = UUID(); speech?.stop(); tokens.removeAll()
    try? session?.removeSpeech(); speech = nil; session = nil
  }
}
