# 0010 — CSRF: same-origin checks plus a per-session token on every write

- **Status:** accepted
- **Date:** 2026-10-03

## Context
Sessions are cookies on the web app's origin (`/api/*` is same-origin through the gateway or
Next's rewrite). A cookie-authenticated API needs protection against cross-site writes.

## Decision
- NestJS 12's built-in cross-origin protection (`Sec-Fetch-Site` / `Origin`) refuses cross-site
  requests.
- On top, every write needs `X-CSRF-Token`: an HMAC of the session id, returned by `GET /me`.
- The web client sends it on every write and, when it isn't known yet (a page that never loaded
  `/me`, such as an invite link, or right after a full page load), fetches `/me` first, once
  for all waiting writes (`csrfTokenForWrite` in sotto-web).

## Consequences
- Tokens need no storage: they follow the session and die with it.
- A write without the token is refused with "This page is out of date"; the client makes that
  rare. New write paths in the web must go through the typed client.
