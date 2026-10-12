# 0024 — The AI gateway: workspace modes, model references, Restricted stays in

- **Status:** accepted
- **Date:** 2026-10-10

## Context
PLAN row 6: "switching models is a setting and Restricted never reaches outside AI". BRIEF §3:
Private, BYOK and Managed; admins choose which modes may read Confidential; Restricted is
Private-only; every answer shows where it was made. ADR 0020: no silent fallback.

## Decision
- **Model references** name a model and its mode unambiguously and are what gets stored (the
  default, disabled models, the model that answered): `private:<provider>:<model>`,
  `managed:<provider>:<model>`, `byok:<key id>:<model>`.
- **Policy** (`WorkspaceAiPolicy`, defaults when no row): allowed modes, default mode and model,
  Confidential modes, disabled models. A mode counts as allowed only if the plan includes it
  (Managed from Pro, ADR 0025).
- **No global model table**: the catalog is computed from the platform's config (Private and
  Managed models) and the workspace's keys. PLAN's `AiModel` table would need a platform
  operator UI, and toggling it from one workspace would change every tenant.
- **Resolving a chat** happens before the answer stream opens: the picked model (Switch model)
  or the workspace default; a model that isn't usable is a 409, never a swap for another.
- **Two lines of defence**: the retrieval SQL only selects sensitivities the route may read
  (in-cluster: all; outside: Internal, plus Confidential where the policy allows that mode;
  Restricted never) and counts what it hid; then `partitionSources` re-checks every passage
  before the provider call.
- Integration tests with recording stand-in providers prove Restricted text never reaches an
  outside model across default models, scopes, @-mentions, per-question switches and answer
  again.

## Consequences
- Moving to a new model is a settings change (or a new key); answers keep the reference of the
  model that wrote them.
- A Phase 5 platform chat on a third party (`AI_ASK_CHAT` on a hosted API) is Managed, never
  Private.
