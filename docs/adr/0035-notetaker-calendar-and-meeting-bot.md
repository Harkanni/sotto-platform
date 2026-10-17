# 0035 — The notetaker: calendar connections, a bot provider, one ingest path

- **Status:** proposed (Phase 7, M6–M7)
- **Date:** 2026-10-17

## Context

PLAN's second half of the Live notetaker: connect a Google or Microsoft calendar with the same
sign-in apps as Phase 3, and Sotto joins your calls as a participant named "Sotto Notetaker",
records and transcribes live, and the meeting is in Sotto when the call ends. It sits behind
`MeetingBotProvider` (`meetings.bot`); the first adapter is a self-hosted Google Meet bot, a
headless browser that becomes one Kubernetes Job per meeting once Phase 9's cluster exists.
Consent: the bot's name is visible, it announces itself in the meeting chat, and workspace admins
can turn bots off. Zoom and Teams come later (self-built, or a paid hosted bot API: ask first).

Forces:

- The Google and Microsoft OAuth apps don't exist yet (a Phase 3 blocker), so real calendars
  can't be connected until the owner creates them; the feature must still be buildable, testable
  and demoable, and labelled where it's a stand-in.
- Listen mode already has an ingest path for live audio (ADR 0028: numbered PCM chunks,
  transcribed per window, SSE out, End → the normal pipeline). A second path for the bot would
  double the code that has to stay private, ordered and resumable.
- A bot is not a signed-in person: it has no session cookie and can't hold a CSRF token, but it
  must only ever reach the one call it was sent to.
- The agent sandbox and CI can't reach Google Meet, so "the bot joins a Meet call" can only be
  proven on the demo, by the owner, with a real meeting.

## Decision

**Calendars.** `CalendarProvider` (in the api; calendars aren't AI) with three adapters:
`google` and `microsoft`, offered only when their OAuth credentials are set (the same
`GOOGLE_CLIENT_*` / `MICROSOFT_CLIENT_*` as sign-in), and `sample`, a labelled stand-in calendar
of made-up calls around today. Connecting is an OAuth code flow the api runs itself
(`POST /calendar/connect/:provider` → the consent page → `GET /calendar/callback/:provider`),
asking for read-only calendar access and offline access; the state is single-use, ten minutes
long, and bound to the signed-in person, so a callback can't connect someone else's calendar.
The refresh token is envelope-encrypted with the BYOK vault (ADR 0023) on `CalendarConnection`
and never leaves the api. Reading events asks the provider each time (cached a minute); Sotto
stores only what it needs to send a bot: the event id, title, times and meeting link, on the
`BotAssignment`.

**Sending the bot.** `PUT /calendar/events/:id/bot` sends or skips the notetaker for one event;
`PATCH /calendar/settings` turns auto-join on for a calendar (every future call with a supported
link, unless skipped one by one). A scheduler in the api claims due assignments atomically (so
several api processes never launch one twice) and calls `MeetingBotProvider.join` a minute
before the start, with the meeting link, the name "Sotto Notetaker", and where to report back.
`Workspace.meetingBots` (admins, audited) stops new joins and asks bots already in calls to
leave; the meeting is saved up to that moment.

**One ingest path.** When the bot is let into the call it reports `in_call` on the signed
webhook (`POST /webhooks/meeting-bot`: HMAC-SHA256 over the timestamp and raw body with
`MEETING_BOT_SECRET`, five minutes either way, no session), and the api starts a live session
(source BOT) for the person who sent it. The bot then sends the call's audio to the same
`POST /live-sessions/:id/audio?seq=n` as Listen mode, with `Authorization: Bot <token>`: a
token signed with the same secret that names one assignment and expires after the call, which
the auth guard accepts only on that route, only for that assignment's session, acting as its
sender (no CSRF: nothing rides on a cookie). Leaving, being removed or the call ending reports
`left`; the session ends and the meeting goes through the normal pipeline like any recording.

**Bot providers.** `sample` (in the api): a labelled stand-in that "joins" without going
anywhere and speaks made-up silence-and-tone audio through the real path, for tests and the
demo until a real bot runs. `meet` (M7): the self-hosted Google Meet bot as its own service
(Compose now, one Kubernetes Job per meeting in Phase 9), reached at `MEET_BOT_URL`. `MEETING_BOT`
picks one; unset means the notetaker is unavailable and the app says so.

## Consequences

- The bot reuses everything Listen mode proved: ordering, resends, offline gaps, privacy rules
  (Restricted stays in the cluster), live notes, Ask mid-call, End → the full transcript.
- Real calendars need the owner's OAuth apps with the callback URLs
  `https://<app>/api/v1/calendar/callback/google` and `…/microsoft` added; until then only the
  sample calendar shows, labelled.
- Without a Google account for the bot, Meet admits it as a guest the host must let in; a bot
  left waiting fails after ten minutes and says why.
- `MEETING_BOT_SECRET` is a new secret shared by the api and the bot service (SSM in the demo).
- Proving the Meet bot end to end needs a real meeting on the demo (the sandbox can't reach Meet).
