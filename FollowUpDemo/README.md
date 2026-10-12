# Follow-up native iPhone demo

This is an implementation kit adapted from Meta’s official **iOS DisplayAccess** sample. The TypeScript backend has been compiled and tested on Windows. **The iOS app has not been compiled, simulated, installed, or tested on real glasses.** See `STATUS.md` and `TEST_RESULTS.md` before treating it as a rehearsable demo.

The separate promotional video is outside this app. The configured booking link is [Arnav’s 30 Minute Meeting](https://calendly.com/arnavnambiar981/30min), verified against the connected Calendly account on October 12, 2026. No availability, booking, or schedule was changed.

## Next action on your Mac

Copy the entire `FollowUpDemo` folder to the Mac. Open `ios/DisplayAccess.xcodeproj` with **Xcode 26.4+ / Swift 6.3+**. The deployment target is **iOS 17.2+** and the Meta SDK dependency is **exactly 1.0.1**. Run:

```sh
bash scripts/mac-check.sh
# Use an actual available simulator UUID from the script’s output:
SIMULATOR_ID=<uuid> bash scripts/mac-check.sh
```

The script records actual build and test logs in `build-evidence/`; it stops on failure. In Xcode, select your Apple signing team for the app and test targets, change `com.arnav.followup.demo` if needed, connect and trust your iPhone, enable iPhone Developer Mode, select the iPhone and Run. Apple sign-in, agreements, device trust and signing authorization are actions you perform. Record any exact signing/capability error; free Personal Team compatibility is not assumed.

Then pair/update the glasses and Meta AI, enable **Meta AI > Settings > your glasses > Developer Mode**, launch Follow-up and register it through Meta AI. Registration of this app can replace another developer-mode DAT integration. Approve Bluetooth/local-network access and the microphone permission only when beginning consented capture. Use the app’s update actions if Meta reports a firmware or DAT glasses app mismatch. `docs/HARDWARE_TEST.md` describes the required physical tests.

## What is implemented

- Official DisplayAccess lifecycle/registration/update handling retained; a Follow-up entry point renders one `FlexBox` root and real SDK button callbacks. An independent **Capture diagnostic** shows speech beside an interactive counter, with no backend/email dependency.
- Two explicit capture paths: experimental **Meta Speech** on the exact display session; or wearer-selected **Bluetooth HFP** with Apple on-device recognition, audio-route diagnostics and sample host-time boundaries. Partials are visible locally; only finals reach drafting/cue logic. No camera capture and no silent handset microphone fallback.
- Explicit consent, Start/Pause/Stop, evolving conservative email drafts, literal recipient confirmation, complete numbered review, immutable approved content, deliberate on-glasses arm, displayed 15-second deadline and exact normalized full cue. Cancel/edits/corrections/interruptions invalidate the arm.
- Server-side **Gmail API** dispatch, encrypted SQLite session records and durable outbox, authenticated/rate-limited endpoints and session isolation. `DRY_RUN`, Gmail acceptance and `UNKNOWN` outcomes are distinct. Ambiguous Gmail requests are never automatically retried.
- Experimental `LaunchApp` listener and acknowledgement, separate from operating an already-connected display. App-picker launch, cold launch, locked launch and force-quit launch have no pass claim.

Drafting currently uses the latest three finalized transcript **excerpts**, explicitly marks unidentified speakers, and deterministically includes the Calendly URL. It uses no paid model API and makes no inferred promises, ROI, prospect names or agreed appointment times. Semantic AI summarization and diarization are not configured. The recipient is entered during setup as an explicit typed fallback and verified on the glasses; speech-spelling recipient entry is not implemented.

## Backend and Gmail boundary

Node.js 24+ is required. There are no production npm dependencies. Developer tools are pinned in `backend/package-lock.json`.

```sh
node scripts/provision-local.mjs
cd backend
npm ci
npm run build
npm test
# Reads a privately configured .env, never an iOS resource:
node --env-file=.env src/server.ts
```

`SEND_CUE` is configured to Arnav’s exact sentence: **“I just realized I haven't shown you how good I am as a developer”**. It is the server default and is included in `.env.example`; setting an explicitly empty value disables arming. The complete sentence must come from fresh finalized audio while armed; case, ordinary punctuation and straight/curly apostrophe differences are normalized, while extra words and paraphrases are rejected. `ALLOW_LIVE_EMAIL=false` and `HARDWARE_CAPTURE_VERIFIED=false` remain the default. A dry-run cue never calls Gmail.

For a physical phone rehearsal, deploy the container to an authorized host with **HTTPS**, a persistent `/data` volume writable by the container’s `node` user, and a private secret store. Run **one Node process / one replica** for this SQLite demo. Point the phone at that deployed URL, not at localhost or a laptop. `GET /health` provides an actual readiness check. Hosting access, budget and deployment authorization have not been supplied, so no cloud deployment is claimed. See `docs/BACKEND_SETUP.md` for exact Gmail consent and deployment actions.

Keep `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`, `DATA_ENCRYPTION_KEY` and the server configuration private. Enter only the limited demo device bearer token into the phone’s setup; it is stored in Keychain with access after first unlock. Gmail credentials never enter the app. Never upload `.env`, `.data/`, credentials or private recordings with build logs.

## Physical feasibility boundary

Meta documents that **HFP beamforming isolates the wearer and significantly reduces other speakers**. Both people across a table may therefore fail useful capture, especially with background noise. No code or mock test can prove that away. Meta Speech also exposes **no capture timestamp**, so this implementation blocks cue arming through that source. Use it to investigate display/transcription together; use the timestamped HFP path for controlled cue tests only after hardware capture passes.

Speech and Voice Invocations are experimental in SDK 1.0.1; Meta says apps using experimental features cannot yet be published. The intended scope is a developer demonstration. A completed conversation rehearsal, distribution, live Gmail send and inbox delivery remain unverified.

## Files and evidence

- `ios/`: actual Xcode app/test project, official source adaptation and Meta’s license notice.
- `backend/src/`: TypeScript controller, encrypted storage, HTTP API, Gmail sender and private OAuth helper.
- `backend/dist/`: JavaScript emitted by the successful TypeScript build on this computer.
- `backend/test/`: adversarial controller, transport and compiled-server tests.
- `docs/`: hardware acceptance procedure, account boundaries, platform references and protocol details.
- `evidence/`: actual Windows build/test/source-check output. Native test source exists; native execution does not.

On unknown dispatch, preserve the session identity, use **Check status / Recover previous dispatch identity**, and inspect Gmail Sent privately. An API message ID means Gmail accepted the request; it does not prove recipient inbox arrival. Phrase matching provides no speaker identity authentication: another person saying the entire phrase while armed remains a physical-demo risk to assess during rehearsal.
