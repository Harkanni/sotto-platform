# 0015 — The demo's email before the domain: Mailpit behind a password

- **Status:** proposed (needs the owner's approval and `terraform apply`)
- **Date:** 2026-10-03

## Context
Sign-in links and invites are emails. SES needs a verified domain, and `sotto.ai` isn't bought
yet, so the always-on demo has no way to send mail. Without it, nobody can sign in there.

## Decision
- The demo runs Mailpit, which catches every email the API sends; nothing leaves the server.
- Its web UI is served at `https://<demo>/mail/`, behind basic auth (user `sotto`, a password
  Terraform generates into SSM; `terraform output -raw demo_mail_password`).
- The API gets `APP_URL`, `AUTH_SECRET` (generated into SSM) and `SMTP_URL=smtp://mailpit:1025`.
- Once the domain exists: verify it in SES, set `SMTP_URL` to SES's SMTP endpoint, remove
  Mailpit.

## Consequences
- The owner can sign in and invite people on the demo now, reading their links in the mailbox.
- Invitees can't receive real email until SES; the owner shares links (Members → invite →
  Copy invite link).
- Costs nothing extra (one 64 MB container).
