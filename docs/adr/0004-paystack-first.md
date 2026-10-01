# 0004 — Paystack first, behind PaymentProvider

- **Status:** accepted
- **Date:** 2026-10-01

## Context
Stripe doesn't onboard Nigerian businesses directly; the owner is in Lagos.

## Decision
A `PaymentProvider` interface with a Paystack test-mode adapter in Phase 6. Stripe is a second adapter later.

## Consequences
Plans, prices and limits live in one shared config file, independent of the provider.
