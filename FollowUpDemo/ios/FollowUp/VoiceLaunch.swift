import Foundation
import MWDATCore

// Experimental launch request handling. This alone does not establish cold launch.
@MainActor
final class VoiceLaunch {
  private var stream: VoiceInvocationsStream?
  private var tokens: [AnyListenerToken] = []
  func start(deviceID: DeviceIdentifier, onLaunch: @escaping @MainActor (DeviceIdentifier) async -> Bool,
    onError: @escaping @MainActor (String) -> Void) throws {
    stop()
    let stream = try VoiceInvocationsStream(wearables: Wearables.shared)
    self.stream = stream
    tokens = [
      stream.invocationsPublisher.listen { invocation in
        guard let launch = invocation as? LaunchApp else { return }
        Task { @MainActor in
          let ready = await onLaunch(launch.deviceIdentifier)
          // Exactly one response call for each delivered LaunchApp. No retries.
          if ready { _ = await launch.responseHandle.sendSuccess(actionOutput: nil) }
          else { _ = await launch.responseHandle.sendFailure(actionOutput: nil) }
        }
      },
      stream.errorPublisher.listen { error in Task { @MainActor in onError(error.description) } }
    ]
    try stream.start(deviceIdentifier: deviceID)
  }
  func stop() { stream?.stop(); tokens.removeAll(); stream = nil }
}
