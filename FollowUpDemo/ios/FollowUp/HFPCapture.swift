@preconcurrency import AVFoundation
@preconcurrency import Speech
import Foundation
import Darwin

private final class CaptureRequest: @unchecked Sendable {
  let request: SFSpeechAudioBufferRecognitionRequest
  private let lock = NSLock()
  private var origin: Double?
  private var lastVoice: Double?
  private var closed = false
  init(_ request: SFSpeechAudioBufferRecognitionRequest) { self.request = request }
  func append(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
    lock.lock(); defer { lock.unlock() }
    guard !closed, time.isHostTimeValid else { return }
    let seconds = AVAudioTime.seconds(forHostTime: time.hostTime)
    if origin == nil { origin = seconds }
    request.append(buffer)
    // End an utterance after measured silence so final results arrive during
    // conversation, rather than waiting for Apple's maximum task duration.
    if let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 {
      var sum: Float = 0
      for i in 0..<Int(buffer.frameLength) { sum += samples[i] * samples[i] }
      if sqrt(sum / Float(buffer.frameLength)) > 0.006 { lastVoice = seconds }
    }
    if let lastVoice, seconds - lastVoice > 0.9 {
      closed = true; request.endAudio()
    } else if let origin, seconds - origin > 8 {
      closed = true; request.endAudio()
    }
  }
  func firstCapture() -> Double? { lock.lock(); defer { lock.unlock() }; return origin }
  func end() { lock.lock(); defer { lock.unlock() }; closed = true; request.endAudio() }
}

@MainActor
final class HFPCapture {
  private let engine = AVAudioEngine()
  private var recognition: SFSpeechRecognitionTask?
  private var capture: CaptureRequest?
  private var tapInstalled = false
  private var observers: [NSObjectProtocol] = []
  private var rotationTask: Task<Void, Never>?
  private var generation = UUID()
  private var activeInputUID: String?
  var selectedInputUID = ""
  var sessionOrigin = 0.0
  var onText: (@MainActor (CapturedText) -> Void)?
  var onFailure: (@MainActor (String) -> Void)?
  var onDiagnostic: (@MainActor (String) -> Void)?
  static var hostSeconds: Double { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }
  var elapsedMs: Double { (Self.hostSeconds - sessionOrigin) * 1000 }

  func requestPermissionsAndListInputs() async throws -> [AVAudioSessionPortDescription] {
    let granted = await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
    }
    guard granted else { throw FollowUpFailure.message("Allow microphone access in iPhone Settings > Follow-up.") }
    let auth = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
    }
    guard auth == .authorized else { throw FollowUpFailure.message("Allow Speech Recognition in iPhone Settings > Follow-up.") }
    let a = AVAudioSession.sharedInstance()
    if #available(iOS 26.0, *) { try a.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothHFP]) }
    else { try a.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth]) }
    try a.setActive(true)
    return (a.availableInputs ?? []).filter { $0.portType == .bluetoothHFP }
  }
  func start(epoch: String, rotate: Bool = true) throws {
    stopRequest()
    let a = AVAudioSession.sharedInstance()
    guard let port = a.availableInputs?.first(where: { $0.portType == .bluetoothHFP && $0.uid == selectedInputUID }) else {
      throw FollowUpFailure.message("Selected glasses HFP input is unavailable. No phone microphone fallback.")
    }
    try a.setPreferredInput(port); try a.setActive(true)
    guard a.currentRoute.inputs.contains(where: { $0.portType == .bluetoothHFP && $0.uid == port.uid }) else {
      throw FollowUpFailure.message("The selected glasses HFP route did not become active.")
    }
    activeInputUID = port.uid
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable,
      recognizer.supportsOnDeviceRecognition else { throw FollowUpFailure.message("On-device English speech recognition is unavailable. Download the language or use Meta Speech diagnostics.") }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true; request.requiresOnDeviceRecognition = true; request.taskHint = .dictation
    let cap = CaptureRequest(request); capture = cap; let nonce = generation; let origin = sessionOrigin
    recognition = recognizer.recognitionTask(with: request) { [weak self] result, error in
      let text = result?.bestTranscription.formattedString; let final = result?.isFinal ?? false
      let start = cap.firstCapture(); let problem = error != nil
      Task { @MainActor in
        guard let self, self.generation == nonce else { return }
        if let text, let start { self.onText?(CapturedText(text: text, final: final, epoch: epoch, capturedMs: (start - origin) * 1000, confidence: nil)) }
        if problem { self.onFailure?("Speech recognition interrupted; sending disarmed. Start a new recognition interval.") }
        else if final && rotate { do { try self.start(epoch: epoch, rotate: true) } catch { self.onFailure?(error.localizedDescription) } }
      }
    }
    let input = engine.inputNode; let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else { throw FollowUpFailure.message("No valid HFP microphone format.") }
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in cap.append(buffer, time: time) }
    tapInstalled = true; engine.prepare(); try engine.start()
    onDiagnostic?("HFP input: \(port.portName) | UID \(port.uid) | \(Int(format.sampleRate)) Hz / \(format.channelCount) ch. On-device ASR; raw audio is not saved.")
    installObservers()
    if rotate {
      rotationTask = Task { [weak self] in
        try? await Task.sleep(for: .seconds(9))
        guard !Task.isCancelled, let self, self.generation == nonce else { return }
        self.capture?.end()
      }
    }
  }
  private func installObservers() {
    guard observers.isEmpty else { return }
    observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
      Task { @MainActor in self?.stop(); self?.onFailure?("Audio interruption. Resume explicitly; cue invalidated.") }
    })
    observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
      Task { @MainActor in
        guard let self, let uid = self.activeInputUID else { return }
        if !AVAudioSession.sharedInstance().currentRoute.inputs.contains(where: { $0.portType == .bluetoothHFP && $0.uid == uid }) {
          self.stop(); self.onFailure?("Glasses audio route changed. No microphone fallback; cue invalidated.")
        }
      }
    })
  }
  private func stopRequest() {
    generation = UUID(); rotationTask?.cancel(); rotationTask = nil
    engine.stop(); if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
    capture?.end(); recognition?.cancel(); recognition = nil; capture = nil
  }
  func stop() {
    stopRequest(); activeInputUID = nil
    observers.forEach(NotificationCenter.default.removeObserver); observers.removeAll()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
