# Follow-up simulator startup/signing fix

This patch addresses the supplied startup crash. The original script disabled simulator signing; Meta documents that this can fail SDK keychain initialization. The app then hid that error and accessed `Wearables.shared` anyway.

The patch enables simulator ad-hoc signing and guards startup. It adds two native regression tests; those tests and the revised app have not been run on a Mac by this Windows chat.

Download and extract this ZIP in Downloads. From Terminal:

```sh
cd "/Users/bionicdonkey42/Downloads/metadisplay_business-main/FollowUpDemo"
bash "$HOME/Downloads/FollowUpStartupFix/apply.sh" "$PWD"
SIMULATOR_ID="PASTE-YOUR-IPHONE-17-UUID" bash scripts/mac-check.sh
open ios/DisplayAccess.xcodeproj
```

The installer copies only four files and backs up their originals. It does not replace the Xcode project, signing team, backend secrets or runtime data. If you extracted this fix elsewhere, use that actual path for `apply.sh`.

After the build/test succeeds, select the iPhone 17 simulator in Xcode and press Command-R. The app should either open normally or show a specific SDK initialization error instead of the generic fatal crash. For the display preview, tap **Enable Meta mock display**, then **Connect display / show counter**. Physical glasses/audio are not tested by that preview.

If it remains blocked, copy the on-screen error or console line beginning `Follow-up SDK startup blocked:`. No credentials are needed to report it. Duplicate SDK class warnings may still appear; their causal role is unverified and this patch does not modify vendor binaries.

Reference: [Meta's signing/keychain explanation](https://github.com/facebook/meta-wearables-dat-ios/issues/197#issuecomment-4549647052).
