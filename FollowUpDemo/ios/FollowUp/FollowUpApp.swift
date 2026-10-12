/* Adapted from Meta's official DisplayAccess sample. See META-LICENSE. */
import MWDATCore
import SwiftUI

@main
struct FollowUpApp: App {
  @State private var model: FollowUpModel
  init() {
    do { try Wearables.configure() }
    catch { NSLog("Follow-up SDK configuration failed; inspect configuration privately.") }
    _model = State(wrappedValue: FollowUpModel())
  }
  var body: some Scene {
    WindowGroup {
      FollowUpView(model: model)
        .onOpenURL { url in
          guard URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .contains(where: { $0.name == "metaWearablesAction" }) == true else { return }
          Task {
            do { _ = try await Wearables.shared.handleUrl(url) }
            catch { model.notice = "Meta callback failed: \(error.localizedDescription)" }
          }
        }
    }
  }
}
