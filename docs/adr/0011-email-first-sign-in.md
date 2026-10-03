# 0011 — Email-first sign-in; passkeys added after; invites match verified email

- **Status:** accepted
- **Date:** 2026-10-03

## Context
PLAN decision 4: sign in with an email link, passkeys, Google and Microsoft. Invites are sent
to an address, and someone accepting must prove they own it.

## Decision
- Sign-up is by email link (magic link, hashed tokens) or by Google/Microsoft; both verify the
  address. Passkeys are added after signing in (Profile → Account) and then sign in, with
  browser autofill. There are no passkey-only accounts.
- An invite is accepted only by the account whose verified email matches it; the invite screen
  offers "Switch account" otherwise.
- Google and Microsoft buttons show only when the API has their credentials.

## Consequences
- Every account has a verified email, so invites and audit entries always name a real address.
- On iOS, an email link opened from an installed (Home Screen) app lands in Safari, which doesn't
  share its cookies; a typed one-time code would fix it, and is the owner's call (it changes
  the sign-in methods in PLAN).
- Passkeys are bound to the host name: those made on the sslip.io demo stop working when the
  demo moves to the real domain.
