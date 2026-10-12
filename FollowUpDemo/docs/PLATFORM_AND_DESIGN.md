# Verified platform and design decisions

Sources inspected October 12, 2026:

- [Official iOS repository](https://github.com/facebook/meta-wearables-dat-ios), [DisplayAccess sample](https://github.com/facebook/meta-wearables-dat-ios/tree/main/samples/DisplayAccess), [sample prerequisites](https://raw.githubusercontent.com/facebook/meta-wearables-dat-ios/main/samples/DisplayAccess/README.md).
- [SDK changelog](https://github.com/facebook/meta-wearables-dat-ios/blob/main/CHANGELOG.md): 1.0.1 dated October 9, 2026, no developer-facing changes; experimental Speech and Voice Invocations added at 1.0.0. Experimental integrations cannot yet be published.
- [Meta repository instructions](https://github.com/facebook/meta-wearables-dat-ios/blob/main/AGENTS.md) and the **1.0.1 public Swift interfaces**, rather than guessed method names. `Speech.addSpeech()` is optional; attach after started. `Speech.start/stop` are synchronous; retain state, locale, text/error listeners. Confidence can be unavailable (negative); no invented confidence threshold.
- [Meta public full documentation](https://wearables.developer.meta.com/llms.txt?full=true) describes HFP wearer beamforming and reduced other voices. The firmware/version-dependencies page did not expose a full current matrix to the browsing tool; no exact current firmware/Meta AI compatibility is claimed. Check your actual versions and Meta’s current [version-dependencies page](https://wearables.developer.meta.com/docs/develop/dat/version-dependencies/) using your account; honor SDK update errors.
- [Apple Bluetooth HFP option](https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/allowbluetoothhfp), [on-device recognition](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition), [background audio guidance](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioGuidelinesByAppType/AudioGuidelinesByAppType.html), [running on a device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

The original user request governs the work. The handoff document was inspected as product specifications and reference material, not as proof of existing software or hardware behavior. Its known Calendly URL was checked independently. Its listed Mac/SDK/account unknowns were not assumed solved. The user selected Gmail, reported a Mac that is not connected to this chat, and supplied the exact cue: “I just realized I haven't shown you how good I am as a developer”. That sentence is configured; actual recognition and rehearsal remain untested.

## Capture and cue freshness

Meta `TranscriptionResult` in 1.0.1 contains only `text`, `isFinal` and `confidence`; it provides no sample capture start/time or speaker identity. Callback receipt time cannot rule out a delayed pre-arm utterance. This is why Meta Speech supports drafting/diagnostics here but cannot arm.

The HFP path requires explicit glasses input selection, verifies both port type and UID and requires Apple on-device English recognition. Each recognition request owns the first audio-buffer host time, a closed flag and an immutable generation. At arm, the prior request/tap is stopped and a new server epoch is created, then a new request/tap starts. Old callbacks are discarded; the first actual buffer must be strictly later than the arm boundary. Route changes and interruptions stop capture and disarm. This is source logic, still requiring real-device validation of audio buffering and timing.

Finalization uses a simple RMS/silence boundary (0.006 amplitude, 0.9-second silence) and an eight-second request limit, with a nine-second watchdog. These are initial parameters requiring speech-quality/latency measurement on the actual device; they are not tested acoustic guarantees. A small restart gap can exist between utterances. The arm interval starts at server approval and expires after 15 seconds; setup/network delay reduces the usable cue time.

No HFP handset fallback, camera stream, covert recording, model-issued send or offline send queue is implemented. No background keepalive is added: `audio` is declared for a consented active recording. Whether Meta Speech alone remains active while locked is untested.

## Draft and review protocol

Only finalized segments enter the server. Sequence/epoch/source/session checks drop stale callbacks and duplicate/out-of-order inputs. The conservative draft quotes source excerpts and marks speaker identity unverified; all authority-sensitive values (recipient, cue and booking link) come from explicit setup, never transcript instructions. A paid LLM and structured speaker diarization are not silently assumed.

Recipient corrections clear confirmation/approval/arm. Review freezes literal subject/body/recipient/URL and requires visiting every numbered review page in order; later audio cannot edit the frozen content. Arming is a separate deliberate button. The configured full normalized phrase is matched exactly, allowing ordinary punctuation/case differences, while refusing substrings/long surrounding speech. The model is absent from command recognition. A repeated cue creates no second outbox entry.

The native client serializes server operations, guards old callbacks with generation/epoch checks, throttles display replacement to roughly 1.2 seconds, preserves draft reading position and never retries a verbal cue. It saves pending dispatch identity locally for status recovery after restart. Buttons displayed from obsolete renders are rejected by a render revision.

## Launch boundary

`VoiceInvocationsStream` is a Wearables-level experimental stream: no `DeviceSession` or microphone/camera permission is needed. Listeners are retained before `start(deviceIdentifier:)`; each delivered `LaunchApp` receives one success/failure call. The handler connects a display session; it does not automatically record a conversation or dispatch a message. Its existence proves neither picker discoverability nor an OS cold launch/force-quit wake path. Wearables Developer Center capability approval and spoken app-name configuration remain user/account boundaries.

## Scope of this build

This is a native iPhone developer demo kit and one server-side Gmail implementation. It includes the original sample for provenance, with the Follow-up app as the sole `@main` entry. The sample’s car-maintenance/reference views remain source references, outside the Follow-up UI. No promotional video, customer pilot, booking automation, OAuth credential embedded in iOS, inbox-delivery guarantee or real-hardware pass is included.
