# 0026 — Paystack: verify the payment on return; webhooks keep it current

- **Status:** accepted
- **Date:** 2026-10-10

## Context
ADR 0004: Paystack first, behind `PaymentProvider`, test mode in Phase 6. Paystack's
subscription webhooks don't carry the metadata a checkout sets, so a webhook alone can't say
which workspace a new subscription belongs to.

## Decision
- **Checkout** (`POST /billing/checkout`, owners) initialises a transaction with the plan's
  Paystack plan code, a `sotto_…` reference and the workspace in its metadata, and returns
  Paystack's page. The api never sees a card.
- **On return** the web sends the reference (`POST /billing/confirm`); the api verifies the
  transaction with Paystack itself (never trusting the redirect), checks it belongs to this
  workspace, and only then changes the plan, looking up the subscription by customer and plan.
- **Webhooks** (`POST /webhooks/paystack`, public): HMAC-SHA512 of the raw body with the secret
  key, compared in constant time; each delivery handled once (`BillingEvent`, the body's hash,
  forgotten again if handling fails so Paystack's retry works). They link a just-created
  subscription, renew on paid invoices, mark failed payments past due, and cancel at the end of
  the period. A payment whose owner closed the tab is linked from `charge.success`.
- **Test mode only**: a live key is refused unless `BILLING_ALLOW_LIVE=true`. With no key at all
  the api uses a labelled stand-in ("Test checkout · no payment provider") so the demo and
  development work end to end with nothing charged.
- One Paystack subscription at a time: changing plan means cancelling in Paystack's manage page
  first (no double charge).

## Consequences
- The verify and subscription-list response shapes follow Paystack's documentation and SDK
  typings; they must be confirmed against Paystack test mode once the owner has a test key.
- Stripe can be added as a second `PaymentProvider` later without changing plans or meters.
