# Account and deployment boundaries

This demo is single-wearer. The one privately provisioned device token owns its sessions. It has no anonymous send endpoint. The token should be rotated after rehearsal. Node 24+, one replica, encrypted SQLite and a persistent disk are required; this is not a horizontally scaled production service.

## Private Gmail authorization — Arnav performs consent

1. In your own Google Cloud project enable **Gmail API**. Configure an OAuth consent screen for this demo, add your intended Gmail account as a test user if the app is in Testing, and choose a **Web application** OAuth client. No email is sent by these steps.
2. Register the exact local callback `http://127.0.0.1:8765/callback` for the private one-time helper. Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `backend/.env` privately. Set `GMAIL_SENDER` to the intended authorized account, currently `arnavnambiar981@gmail.com` unless you choose another account.
3. On a private machine with this folder, run `node --env-file=.env src/oauth.ts` from `backend/`. Open its printed Google authorization URL yourself and approve the intended account. The helper requests `gmail.send` plus basic OpenID/email identity, uses a random state and PKCE challenge, validates the returned account, and stores the refresh token in **`.data/gmail.env`**, never in chat or stdout. The helper cannot send email. An existing credentials file is not overwritten.
4. Move `GOOGLE_REFRESH_TOKEN` and the returned `GMAIL_SENDER` into the backend’s private secret store. Keep the OAuth client secret there too. Protect the local files with owner-only permissions (on Windows, review the file’s Security permissions). Remove private temporary credential files when your deployment secret store is configured. A Google consent app in Testing can have time-limited refresh credentials; verify your project’s consent status before rehearsal.
5. Leave live flags false. Run the backend tests. Gmail authorization itself and a real provider request have not been run by Codex here.

Official references: [Gmail sending](https://developers.google.com/workspace/gmail/api/guides/sending), [OAuth web server flow](https://developers.google.com/identity/protocols/oauth2/web-server), [Gmail scopes](https://developers.google.com/workspace/gmail/api/auth/scopes).

## Hosting — an authorized destination is needed

Deploy `backend/Dockerfile` to a host you authorize. No deployment account has been selected and no spend is approved. Configure a persistent volume mounted at `/data`, writable by the container’s `node` user, and one instance. Do not use ephemeral/serverless storage for the outbox. Terminate HTTPS at the hosting platform/reverse proxy; do not expose plain HTTP to the iPhone.

Provision:

```text
APP_AUTH_TOKEN             random 32+ characters, provision only to this iPhone
DATA_ENCRYPTION_KEY        persistent 32 bytes encoded as 64 hex characters
DATABASE_PATH             /data/followup.sqlite
CALENDLY_URL              https://calendly.com/arnavnambiar981/30min
SEND_CUE                  I just realized I haven't shown you how good I am as a developer
ALLOW_LIVE_EMAIL          false
HARDWARE_CAPTURE_VERIFIED false
TEST_RECIPIENT_ALLOWLIST  initially blank
GOOGLE_CLIENT_ID          private OAuth application value
GOOGLE_CLIENT_SECRET      private OAuth secret
GOOGLE_REFRESH_TOKEN      private token from user’s consent
GMAIL_SENDER              account verified by the consent helper
```

Keep the encryption key stable across restarts; losing it makes stored sessions unreadable. Back up the volume and key privately. `/health` returns only readiness/provider/live-mode information. Run `curl -f https://<your-host>/health`, then configure that URL in phone setup. Deploying the runtime means it continues without Codex or a laptop; no such deployment has happened yet.

## Live enablement — a concrete authorized test remains

After recording physical display, two-person capture, locked/pocketed operation and the fresh cue boundary, obtain Arnav’s explicit approval for one named consenting test recipient. Add that literal address to the allowlist, set the hardware verification flag and enable live sending. A source other than `hfp` cannot live-arm. Disable live sending again after the rehearsal. Setting a flag is not evidence that a hardware test passed.

The connected Gmail plugin in Codex is not a runtime credential provider for this app. This implementation never asks Codex to send an email through a connector, retrieve account secrets or impersonate a different sending address.

## Retention and recovery

Raw audio is never saved by the application. Native diagnostics keep text in memory. Server transcripts/drafts/recipient and approved message are AES-256-GCM encrypted at rest, expire after four hours, and can be cleared with Stop/Delete. A minute-based purge removes expired content; an expired request also clears it. Minimal outbox metadata (session/identity hash, status, provider ID and timestamp) remains up to seven days, then is deleted. Protect host logs/backups with the same retention policy; the app cannot purge copies made outside it.

The server commits an immutable send record before provider I/O. Gmail does not offer a documented `messages.send` idempotency key. A timeout, server error or crash after `SENDING` becomes `UNKNOWN`; startup never redispatches it. A known pre-dispatch credential failure is `FAILED`. Reconciliation uses the saved identity/approved message and a private manual check of Gmail Sent; automated mailbox search is not implemented with the send-only scope. A Gmail message ID proves acceptance, not inbox delivery.
