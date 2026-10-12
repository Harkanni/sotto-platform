# 0025 — Metering and quotas: events for work, storage read live, one plans config

- **Status:** accepted
- **Date:** 2026-10-10

## Context
BRIEF §4 Billing: metering for AI tokens (Managed), transcription minutes and storage, with
friendly limits and upgrade prompts; placeholder prices and limits in one config shared by the
app and the pricing page.

## Decision
- **One plans config**: `sotto-api/packages/contracts/src/plans.ts` (Free, Pro, Business,
  Enterprise; prices in kobo for Paystack, all placeholders and labelled so). The api serves it
  to the web (`GET /billing`, later `GET /pricing`).
- **Usage events** (`UsageEvent`, quantities only, never content): tokens per answer by route
  and model reference; transcription seconds recorded by the worker once per file
  (`subject_id`, unique per kind, so a retried message can't count twice).
- **Storage is read live** from the files (the trash included until it's purged), so it can't
  drift from what is stored.
- **Quotas per calendar month (UTC)**, checked before work starts: Private and Managed tokens
  before a question (BYOK is shown, never limited: the workspace pays its own provider);
  storage and transcription minutes before an upload. Refusals are 402s with what to do
  (upgrade, use your own key, empty the trash, or wait until the reset date).
- **Plan gates**: Managed needs Pro or above. Business features in the config (admin policies,
  audit export) are listed, not enforced yet: gating the existing audit export would change
  approved behaviour, so that is the owner's decision.
- A subscription keeps its plan for 3 days after a period ends, so a late renewal webhook never
  drops a paying team to Free.

## Consequences
- Usage charts and quotas read the same rows. Periods are calendar months, not billing
  periods; aligning them is a later refinement.
