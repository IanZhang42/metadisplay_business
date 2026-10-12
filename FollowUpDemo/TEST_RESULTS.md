# Test results — October 12, 2026

**21 backend tests PASS; 0 failures. TypeScript build PASS. Compiled JavaScript server startup/health/authenticated session creation PASS.** Actual output is in `evidence/backend-tests.txt` and `evidence/backend-build.txt`.

The tests executed on Windows with Node v24.19.0. All provider interactions in tests are injected fake HTTP responses. Simulation of text, source epochs and cue timing is controller simulation; no glasses, real audio, inbox, Google consent or booking was involved.

| Automated scenario | Result |
|---|---|
| Consent required / partials never notes or commands | PASS |
| Out-of-order draft inputs / duplicate callbacks | PASS |
| Recipient correction invalidates confirmation and review | PASS |
| Complete ordered review / exact frozen message / editing disarms | PASS |
| Unarmed cue, stale pre-arm audio, wrong epoch, partial cue | PASS |
| Substring cue / expired arm | PASS |
| Dry-run completion / repeated cue causes zero external sends | PASS |
| Hardware flag, selected HFP source, test recipient allowlist | PASS |
| Meta Speech with no capture timestamp cannot arm | PASS |
| Unset rehearsed sentence blocks arming | PASS |
| Arnav’s full reveal sentence / apostrophe typography / paraphrase rejection | PASS, injected text |
| Concurrent repeated cue dispatches once | PASS |
| Disconnect/interruption invalidates old audio epoch | PASS |
| Provider timeout -> durable UNKNOWN; no restart retry | PASS |
| Crash after committed SENDING -> UNKNOWN | PASS |
| Next conversation removes old prospect/callback authority | PASS |
| Transcript instructions cannot control recipient, URL or send | PASS |
| Session ownership / encryption at rest / four-hour expiry | PASS |
| MIME/header handling | PASS |
| Gmail token failure, dispatch timeout and API acceptance | PASS, fake transport |
| HTTP authentication, invalid JSON, health and absent public send route | PASS |
| Compiled JavaScript server startup and session request | PASS |

**Source verification PASS:** Swift grammar parsing for nine app files and one test file; OpenStep Xcode-project parsing and object-reference checks; URL scheme consistency and microphone, speech, Bluetooth, external-accessory and background-audio declarations. This verifies syntax/structure only, and cannot establish Swift SDK type compatibility or iOS behavior.

**Native tests authored, not run:** local final/epoch/full-phrase guard; immutable envelope decoding; official MockDeviceKit display and Meta Speech on the same session. Run with Xcode on the Mac using `scripts/mac-check.sh` and `SIMULATOR_ID`.

**BLOCKED:** actual Xcode build, simulator execution, signing and installation. **UNTESTED:** physical display controls, both-speaker intelligibility, background noise, locked/pocketed phone, interruptions, disconnect recovery, reading and arm UX, launch entry points, real Gmail acceptance, inbox delivery and booking. Record each physical case in `docs/HARDWARE_TEST.md`; a PASS requires observed evidence.
