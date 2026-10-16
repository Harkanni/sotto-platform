# 0033 — A "keep" stack holds what survives `terraform destroy`: the model cache and the IP

- **Status:** superseded (2026-10-15): one stack; `terraform destroy` removes everything
- **Date:** 2026-10-14

## Context

The owner destroys `terraform/dev` after each build-and-test session. Each new GPU server then
downloads the vLLM image (~10 GB) and the weights (~37 GB) again, ~10–15 GPU minutes, and the
demo's Elastic IP changes, which changes the sslip.io address and breaks the OAuth redirect URLs.

## Decision

- A separate stack, `terraform/keep` (state key `keep/terraform.tfstate`, same bucket), owns:
  - `sotto-model-cache`: a 100 GB gp3 EBS volume (250 MB/s) in a zone that offers the GPU type.
  - `sotto-demo-kept`: an Elastic IP.
- `terraform/dev` looks both up by tag. With the cache, the model server starts in its zone,
  attaches it, mounts it at `/opt/keep`, and puts Docker's data and the Hugging Face cache there.
  With the kept IP, the demo uses it. Without the keep stack, dev behaves as before.
- `demo_eip_allocation_id` still wins over the kept IP when set.

## Consequences

- About $15 a month for the volume and ~$4 for the idle IP, kept even when everything else is
  destroyed. Destroying `terraform/keep` removes them (and the cached model).
- A new model server is ready in ~3–5 minutes instead of ~10–15.
- The cache is formatted on first use; a volume that's still attached elsewhere (a server that
  wasn't destroyed) makes the new one fall back to downloading to its root disk.

## Superseded, 2026-10-15

The owner wants one stack: `terraform apply` brings everything up and `terraform destroy` takes
everything down, with nothing left behind to remember. `terraform/keep` is removed. The demo's
Elastic IP belongs to `terraform/dev` again (a destroy releases it, so the sslip.io name and the
OAuth redirect URLs change each session until a real domain arrives), and a new GPU server
downloads the image and weights again (~10 minutes).
