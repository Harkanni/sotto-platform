# 0023 — Workspace API keys: envelope-encrypted, tested first, never shown again

- **Status:** accepted
- **Date:** 2026-10-10

## Context
BRIEF §3: BYOK keys are envelope-encrypted at rest (KMS in production, a local master key in
development), write-only in the UI with the last four characters shown, checked with Test
connection on save, and never logged or sent to the browser. Admins can also point Sotto at
their own OpenAI-compatible server, which makes the api fetch an address someone typed.

## Decision
- **Envelope encryption** (`packages/ai/src/vault.ts`): each key gets a fresh 256-bit data key
  (AES-256-GCM, fresh IV); a `KeyWrapper` wraps the data key. Rows store the ciphertext, the
  wrapped data key and the wrapper's id (`local:<hash>`), never the data key. The workspace id
  is the additional authenticated data, so a ciphertext copied into another workspace's row
  doesn't open. `AI_KEYS_MASTER` (32 bytes, base64) wraps new keys;
  `AI_KEYS_MASTER_PREVIOUS` opens older ones during a rotation (`rewrap`). With no master key
  the api refuses to store keys and the UI says so; it never stores them weakly. A KMS wrapper
  is the production adapter (Phase 11 creates the key: a paid resource, the owner's call).
- **Tested before stored**: the URL is checked, the provider's model list is fetched with the
  key, and only a key that works is sealed. A replacement that fails leaves the old key in
  place. Responses carry the last four characters only.
- **No hard-coded models**: a key's models come from its provider's `GET /models` when it is
  tested; admins turn models on and off.
- **Endpoint safety**: an admin-supplied base URL must be `https` and resolve only to public
  addresses (no loopback, private ranges, link-local/cloud metadata, CGNAT or ULA), so the api
  can't be used to reach Sotto's own network. `AI_BYOK_ALLOW_PRIVATE_URLS` exists for local
  development only.
- Every BYOK provider is THIRD_PARTY, including a self-described "OpenAI-compatible" server.

## Consequences
- Losing `AI_KEYS_MASTER` loses every saved key (admins paste them again); it lives in SSM on
  the demo. Rotation is a re-wrap, not a re-encryption of every key.
- DNS rebinding between the check and the call remains possible in principle; the window is
  small and the target must still answer an OpenAI-style API. Revisit with an egress proxy in
  Phase 11.
