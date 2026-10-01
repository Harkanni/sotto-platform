# Sotto — Build Prompt

Sep 30, 2026 · Akanni Emmanuel · source: https://claude.ai/code/artifact/27a335f4-03c1-492b-877a-577e52fbbfd1

## How to use this

Give sections 1–14 to your coding agent as its standing brief, then run the phase prompts at the end one at a time.

- Export this doc as Markdown and save it in each repo as the agent's context file (`CLAUDE.md` for Claude Code, or `AGENTS.md` for agents that read that), so every session starts with it.
- Run the phases in order. Review, test and commit between phases instead of asking for everything at once.
- "Sotto" is a working name (from *sotto voce*, "in a quiet voice"). Find-and-replace it to rename.

## 1. Role and goal

You are a senior full-stack and platform engineer with a strong product-design eye. Build **Sotto**: a premium, privacy-first SaaS where internal teams upload memos, documents and meeting recordings, then ask questions and get answers with sources.

Two goals, weighted equally:

1. A production-quality product with Apple-level UI and UX polish.
2. A realistic multi-service system I will run on Kubernetes (locally first, then AWS EKS) to learn DevOps and Platform Engineering. Choose an architecture that creates real operational practice, but add no complexity the product doesn't need.

## 2. Product

- **One-liner:** Private AI for your team's memos and meetings. Ask anything, get answers with sources, and control exactly where your data goes.
- **Users:** internal teams (product, leadership, legal, HR, operations). Roles: Owner, Admin, Member, Viewer.
- **Problem:** memos and recorded meetings hold confidential information that teams won't paste into public AI tools, yet they still need to search, summarize, re-listen to and ask questions across them.

## 3. AI modes and privacy model

This is the core differentiator: admins decide where questions may be answered, and every answer shows where it went.

| Mode | Where the model runs | Who pays |
| --- | --- | --- |
| Private | Open-weight models hosted by Sotto in its own cluster (Ollama in dev, vLLM on GPU nodes in prod). Never sent to a third-party AI provider. | Included in the plan, with a quota |
| Bring your own key (BYOK) | The user's Anthropic (Claude), OpenAI or Google API key, or any OpenAI-compatible endpoint. Data goes to that provider under its terms. | The user pays the provider; cheaper Sotto plan |
| Managed | Sotto's own provider accounts, metered against plan quotas | Subscription |

- Each workspace allows one or more modes; admins set the default mode and the allowed models.
- Transcription and embeddings always run in-house, whatever the chat mode. Whole files are never sent out just to be indexed; only the passages retrieved for a question can reach an external model.
- Every file carries a sensitivity label: Internal (default), Confidential or Restricted. Admins choose which modes may see Confidential content. Restricted content only ever goes to Private-mode models.
- When an external model answers, Restricted sources are excluded at retrieval and the UI says so, e.g. "2 restricted sources hidden. Switch to Private to include them."
- Every answer shows a data-route badge, e.g. "Private · Sotto-hosted model" or "Claude · your API key".
- BYOK keys are envelope-encrypted at rest (AWS KMS in prod, a local master key in dev), write-only in the UI (show the last 4 characters), checked with "Test connection" on save, and never logged or sent to the browser.
- Logs, traces and metrics never contain document text, prompts, answers or keys.
- Enterprise customers can self-host the whole stack in their own cloud using the Helm chart.
- Marketing copy must match this model: claim "never sent to third-party AI" only for Private mode, and "never leaves your infrastructure" only for self-hosting. Make no compliance claims (SOC 2, HIPAA, ISO 27001) unless they are true.

## 4. Features

Build the MVP list completely before anything under Next.

### MVP

**Library and ingestion**

- Upload PDF (keeping page numbers), DOCX, TXT, MD and audio (MP3, M4A, WAV, WebM) by drag-and-drop or file picker.
- Direct-to-storage presigned multipart uploads with progress, pause and resume, and retry. Recordings are often over 100 MB.
- In-app recording (MediaRecorder) with a live waveform, pause and resume, and a consent reminder before recording starts.
- Normalize all audio with ffmpeg before transcription, since browsers record different formats (MP4/AAC on iOS Safari, WebM/Opus in Chrome).
- Live processing status per file: Uploaded → Transcribing → Indexing → Ready, or Failed with Retry.
- Collections that hold both docs and meetings, plus tags, pin, rename, move and a 30-day trash. Permanent delete removes the file, transcript, chunks and embeddings.

**Meetings**

- Transcript with speaker labels and timestamps, follow-along highlighting during playback, tap any line to seek, and search within the transcript.
- Player with 0.75–2× speed, 15-second skips, lock-screen controls (Media Session API) and a remembered position for "Continue listening".
- Auto-generated summary, decisions, action items (owner and due date when mentioned), open questions, and chapters with timestamps.

**Ask**

- Scope: the whole workspace, a collection, or specific files picked with @-mentions.
- Streaming answers with numbered inline citations. Tapping a citation opens the source at the exact spot: the PDF page with the passage highlighted, or the recording playing from that timestamp.
- When the sources don't contain the answer, say so instead of guessing, and suggest follow-up questions.
- Per-answer actions: copy, regenerate, switch model, save as note, thumbs up or down.
- Searchable chat history.

**Search**

- Hybrid keyword and semantic search returning files, passages and meeting moments: a ⌘K palette on desktop, and a search field under the large title on mobile.

**Workspace and admin**

- Sign-in with passkeys, email magic link, Google and Microsoft.
- Workspaces, invites, roles, and collection-level permissions enforced at retrieval, so nobody gets an answer from a file they can't open.
- Settings for AI modes, default model, BYOK keys and sensitivity rules; usage charts with 7-, 30- and 90-day ranges; billing; and an audit log (upload, view, ask, export, delete, settings changes) with CSV export.
- Onboarding: create a workspace → choose an AI mode (with a plain-language privacy explanation) → upload a file or load fictional sample content → ask a first question.

**Billing**

- Tiers: Free (BYOK plus a small Private quota), Pro (Managed AI), Business (admin policies, audit export, more transcription minutes), Enterprise (self-hosted, SSO). Placeholder prices and limits live in one config file shared by the app and the pricing page.
- Metering for AI tokens (Managed), transcription minutes and storage, with friendly limit and upgrade prompts.
- Stripe in test mode behind a `PaymentProvider` interface, so another provider such as Paystack can be added later.

### Next (design the data model for these, but don't build them yet)

- Imports from Google Drive, Notion, Slack, and Zoom or Google Meet recordings.
- Live transcription during meetings, and web push notifications.
- PII redaction before any external model call.
- Cross-meeting insights ("what changed since last week", topic timelines) and weekly email digests.
- An MCP server so people's own AI tools can query Sotto with their permissions.
- SAML SSO, SCIM, retention policies, legal hold and ClamAV scanning.

## 5. Architecture and repos

Use three repos: the web app, a backend monorepo, and a platform repo for infrastructure and deployment.

See the architecture diagram in `PLAN.md`.

Only one arrow leaves Sotto's infrastructure: chat from the API, carrying retrieved passages but never Restricted ones.

1. **`sotto-web`**: Next.js (App Router). The marketing site lives in the `(marketing)` route group and the product in `(app)`. No database access; it only talks to the API.
2. **`sotto-api`**: a backend monorepo (pnpm workspaces).
   - `apps/api`: NestJS REST API with SSE streaming for auth, workspaces, files, chat and billing webhooks. It generates an OpenAPI spec from code.
   - `apps/worker`: a Node worker for text extraction, chunking, embeddings and meeting insights.
   - `services/transcriber`: Python (FastAPI + faster-whisper, with WhisperX-style diarization behind a flag). Stateless: it reads audio from object storage, writes transcript JSON back and publishes a completion message. It never touches the database.
   - `packages/db`: Prisma schema, migrations and seed, used only by `api` and `worker`.
3. **`sotto-platform`**: Terraform, Helm charts, Argo CD apps, local cluster setup, dashboards and runbooks.

**Backing services**

- PostgreSQL with pgvector (HNSW index) plus Postgres full-text search, for hybrid retrieval.
- Redis for caching and rate limits.
- RabbitMQ for jobs, behind a `Queue` interface so Amazon SQS can replace it.
- S3-compatible object storage: MinIO, SeaweedFS or LocalStack locally (check current image availability and licensing), and S3 with SSE-KMS on AWS.
- Model serving: an embedding model on CPU nodes (Ollama or Hugging Face Text Embeddings Inference), and Private-mode chat on Ollama in dev or vLLM on a GPU node group in prod.
- Mailpit for email in dev.

**Contract and routing**

- One origin: the gateway sends `/api/*` to the API and everything else to web; Next.js rewrites do the same locally. No CORS. Sessions use httpOnly, Secure, SameSite=Lax cookies, with CSRF protection on mutations.
- `sotto-web` generates a typed client from the OpenAPI spec (e.g. openapi-typescript or orval, with TanStack Query). CI fails when the committed client is stale.

**Ingestion flow**

1. The browser uploads straight to object storage with presigned URLs.
2. The API records the file and enqueues a job.
3. The worker extracts text, or the transcriber transcribes the audio.
4. The worker chunks it (structure-aware, about 500–800 tokens with overlap; audio by transcript segments), keeping page and timestamp metadata.
5. The worker embeds the chunks with the in-house model, writes them to Postgres and streams status to the UI.

**Answer flow**

1. Optionally rewrite the question.
2. Retrieve with vector and full-text search fused by Reciprocal Rank Fusion (reranker optional). Apply workspace, permission and sensitivity filters inside the SQL, never afterward.
3. Build a grounded prompt with numbered sources.
4. Call the model through the provider gateway and stream the answer with its citations.

## 6. Tech stack

Use the latest stable versions, follow the official docs, avoid deprecated APIs, and record key choices as ADRs.

- **Web:** Next.js App Router, React, TypeScript (strict), Tailwind CSS, shadcn/ui, Motion, TanStack Query, React Hook Form + Zod, next-themes, cmdk, Sonner, react-pdf, wavesurfer.js, Serwist (PWA), Storybook, Vitest, Playwright + axe.
- **API and worker:** Node LTS, NestJS, Prisma, Zod, OpenTelemetry, pino, Jest + Testcontainers, and a maintained auth library with Prisma support, passkeys, magic links, OAuth and organizations (e.g. Better Auth).
- **AI:** a provider-agnostic gateway module (e.g. the Vercel AI SDK) with adapters for Anthropic, OpenAI, Google and OpenAI-compatible endpoints, which also covers Ollama and vLLM. The embedding model and its dimension come from config (e.g. nomic-embed-text or bge-m3).
- **Transcriber:** Python, FastAPI, faster-whisper, ffmpeg.

## 7. Data model (Prisma)

Start from these entities and refine them in the Phase 0 plan.

- **Accounts:** User, Workspace, Membership (role), Invite.
- **Content:** Collection, CollectionPermission, File (kind: document, audio or note; status; sensitivity; storageKey; mime; size; checksum).
- **Meetings:** Transcript, TranscriptSegment (speaker, startMs, endMs, text), MeetingInsights (summary, decisions, action items, chapters).
- **Retrieval:** Chunk (text, embedding, tsvector, page, startMs, endMs, fileId, workspaceId).
- **Chat:** Conversation, Message (role, content, model, route, tokens), Citation.
- **AI and billing:** AiProviderConfig (mode, provider, encryptedKey, models), WorkspaceAiPolicy, UsageEvent, Subscription.
- **Operations:** AuditLog, Notification, Lead (landing-page forms).

Rules:

- Every tenant-owned table has `workspaceId`, enforced centrally by a Prisma client extension.
- pgvector columns use `Unsupported("vector(n)")`, with raw SQL or TypedSQL for similarity queries. Create the HNSW and GIN indexes in migrations.

## 8. Design system

Recreate the iOS 18 and macOS Sequoia look from Apple's Human Interface Guidelines using shadcn/ui and Tailwind. Apple's Figma kits are a visual reference only.

- Don't ship SF Pro, SF Symbols or Apple device images; they're licensed for Apple platforms only.
- Font stack: `-apple-system, BlinkMacSystemFont`, then Inter via next/font, then `system-ui`. Apple devices render SF natively; everyone else gets Inter.
- Icons: Lucide at a 1.75 stroke, which sits close to SF Symbols.

**Color tokens** (CSS variables mapped to shadcn's names; every text pairing must meet WCAG AA)

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| background | #F2F2F7 | #000000 | Grouped page background |
| card | #FFFFFF | #1C1C1E | Cells, cards, sheets |
| elevated | #FFFFFF | #2C2C2E | Popovers and menus |
| foreground | #000000 | #FFFFFF | Primary text |
| muted-foreground | #6C6C70 | rgba(235,235,245,0.6) | Secondary text. Apple's default light gray fails AA, so use #6C6C70 |
| fill | rgba(118,118,128,0.12) | rgba(118,118,128,0.24) | Inputs, chips, segmented controls |
| separator | rgba(60,60,67,0.29) | rgba(84,84,88,0.6) | Hairlines |
| primary | #5856D6 | #5E5CE6 | Indigo fills with white text |
| primary-text | #5856D6 | #7D7AFF | Indigo text and outlines; the dark value keeps AA on #1C1C1E |
| destructive | #D70015 | #D70015 | Red fills with white text. iOS's #FF3B30 and #FF453A are too light for white text, so use them only for icons |

**Type**

- Large Title 34px bold; Title 1, 2 and 3 at 28, 22 and 20px; Headline 17px semibold; Body 17px; Callout 16px.
- Nothing a user needs to read is below 16px. 12–15px is only for metadata: tab labels, timestamps, badges and captions.
- Long-form reading (transcripts, answers) uses about 1.5 line height.

**Layout**

- A 4px grid (4, 8, 12, 16, 20, 24, 32, 44) and 16px mobile gutters.
- Radii: button 8px, input 10px, card and grouped list 12px, sheet 16px on the top corners.
- Inset grouped lists for settings, with hairline separators.

**Materials**

- The tab bar, nav bar and sidebar are translucent: the card color at about 72% via `color-mix()`, plus `backdrop-filter: saturate(180%) blur(20px)`.
- Fall back to solid colors when blur isn't supported or reduced transparency is preferred.

**Motion**

- Springs (about stiffness 400, damping 30) for sheets, push and pop, and presses; 150–300 ms; animate only transform and opacity; View Transitions where supported.
- Sheets have medium and large detents, a drag handle and drag-to-dismiss, and the page behind scales to about 0.94 and dims.
- Under reduced motion, crossfade instead.

**Polish bar** (the level of finish to match, not designs to copy): Apple Notes and Voice Memos, Linear, Raycast, Granola.

### Button

Build `components/ui/button.tsx` as a drop-in shadcn button: keep its API (`variant`, `size`, `asChild` via Radix Slot, cva), replace the default variants with these four, and add a `loading` prop.

- **Variants:** primary (filled indigo, white label); secondary (1px indigo outline drawn as an inset ring, indigo label, transparent background); ghost (transparent, indigo label); destructive (filled `destructive`, white label).
- **States:**
  - Default.
  - Hover, only under `@media (hover: hover)`: fills darken about 8%; secondary and ghost get an 8% indigo tint.
  - Active: scale to 0.97 and darken about 12%, springing back on release.
  - Disabled: 40% opacity, `disabled` or `aria-disabled`, no pointer events.
  - Loading: a 16px spinner in `currentColor` replaces the leading icon, the label stays so the width doesn't jump, `aria-busy="true"` is set and clicks are ignored.
- **Size:** 8px radius, 16px horizontal and 10px vertical padding, and 16px text on a 24px line height, which makes every variant exactly 44px tall. Minimum width 44px; `size="icon"` is 44×44px.
- **Focus:** a visible 2px indigo ring with a 2px offset in the background color.
- **Storybook:** a 4 × 5 matrix (variants × states) in light and dark.

### Data widgets: loading, empty and error

Every data-driven widget (cards, lists, charts, panels) uses one shared `AsyncWidget` pattern: TanStack Query plus an error boundary per widget, so one failure never breaks the page.

- **Loading:** a skeleton that mirrors the final layout, so nothing shifts. Its color comes from the widget's own background, `color-mix(in oklab, var(--card) 92%, var(--foreground))`, slightly stronger in dark mode, with a gentle shimmer that turns static under reduced motion. Show it only when loading takes over 150 ms, then keep it for at least 300 ms to avoid flicker.
- **Empty:** a small inline-SVG illustration (one consistent line style in the accent color, theme-aware), a title, helper text and one action. Time-filtered widgets say **"No data for this period"** and offer to change the range. Content widgets use specific copy, e.g. "No recordings yet. Tap + to record your first meeting."
- **Error:** a plain-language message, a 44px Retry button that refetches only that widget (showing its loading state), and collapsible details with a request ID.
- Each state gets its own Storybook story.

## 9. Mobile UX and navigation

Design phone first, as an installable PWA built for one-handed use; tablet and desktop adapt from it.

**One-handed rules**

- Tap targets are at least 44×44px, with at least 8px between neighbors.
- Primary actions sit in the bottom 40% of the screen, within thumb reach: the + button, the chat composer and Send, play and pause, and sheet actions.
- Secondary actions (rename, move, share, delete) are hidden by default. Swipe a row left for Share, Move and Delete, or right to Pin; long-press for a context menu with a preview.
- Each row also has a "…" button that stays visually hidden until focused, so keyboard and screen-reader users can reach the same actions.
- Delete shows an Undo toast instead of a confirmation dialog; the trash handles recovery.
- Body text is at least 16px everywhere. Inputs are 16px too, so iOS Safari doesn't zoom on focus.
- Respect safe areas (`viewport-fit=cover`, `env(safe-area-inset-*)`), use `dvh` units, and keep the composer pinned above the on-screen keyboard (handle iOS `visualViewport`).
- Settings → Handedness mirrors the + button to the left side.
- PWA: app icon, splash screen, offline app shell and an offline banner.

**Tab bar** (translucent; five items with icon and label; the active tab is indigo)

| Tab | What it holds |
| --- | --- |
| Home | Widgets: Continue listening, Processing, My action items, Recent files, Recent chats, This week (time-filtered stats) |
| Docs | Documents and collections, with filters, sort and sensitivity labels |
| Ask | Chat threads; the composer sits at the bottom with scope chips above it |
| Meetings | Recordings, each opening to a player, transcript, summary, action items and chapters |
| Profile | Account, workspace and members, AI settings, usage and billing, audit log, appearance, handedness |

**Navigation behavior**

- Each tab owns its navigation stack (App Router segments per tab), with a 34px bold large title that collapses into a 17px inline title in the translucent bar as you scroll. The search field sits under the large title.
- Switching tabs keeps each tab's route and scroll position. Tapping the active tab pops to its root, then scrolls to the top.
- Pushed screens slide in from the right and show a back button labeled with the previous screen's title.
- A floating + button (56px, bottom-right, 16px above the tab bar, safe-area aware) opens a modal sheet, "Add to Sotto", with Upload files, Record a meeting, Import audio and New note. It's hidden on the Ask tab, where the composer is the primary action.

**Larger screens**

- Tablet: sidebar plus content.
- Desktop (1024px and up): macOS-style three panes, with a translucent sidebar (workspace switcher, sections, collections), a list, and a detail pane with a resizable Ask panel.
- Desktop also gets toolbar search, the ⌘K palette, right-click context menus, drag-and-drop upload anywhere, and keyboard shortcuts that don't clash with the browser's, listed in a "?" cheat sheet.

## 10. Landing page

Sell Sotto to team leads and IT or security buyers in a premium, calm, confident style: an Apple product page crossed with a modern SaaS site. Build it in `sotto-web` under `(marketing)`.

**Sections, top to bottom**

1. **Nav:** sticky and translucent, with logo, Product, Security, Pricing, Sign in and Start free.
2. **Hero:** a big headline (clamped from about 44px to 80px, tight tracking), a one-line subhead, and "Start free" plus "See how it works". Beside it, a large editorial photo of a professional listening back with wireless earbuds, overlaid with floating translucent UI cards: a question, an answer with a citation chip, and a waveform playing from 12:34. Behind it, a soft indigo aurora gradient with subtle grain. On mobile, the photo stacks under the copy.
3. **Product tour:** pinned, CSS-drawn phone and laptop frames whose screens change as you scroll: upload → transcript → ask → a citation jumping to the audio.
4. **Bento feature grid:** Ask your meetings; Answers with receipts; Private by design; Bring your own key; Action items that write themselves; Admin controls and audit log.
5. **How it works:** Upload → Sotto transcribes and indexes → Ask.
6. **Security and privacy:** an animated data-flow diagram of the three AI modes, plus sensitivity labels, encryption and self-hosting.
7. **Use cases by team** (tabs): Product, Leadership, Legal, HR, Sales.
8. **Pricing:** a monthly and yearly toggle, driven by the shared pricing config.
9. **Social proof:** clearly marked placeholder slots for testimonials and logos, to be replaced with real ones. Never invent customer names, quotes or logos.
10. **Close:** an FAQ accordion, a final call to action and the footer.

**Photography and art direction**

- Editorial, natural-light photos of diverse professionals, women and men, in bright modern workplaces: someone replaying a meeting with wireless earbuds, a small team around a table, someone reviewing notes on their phone on the move.
- Candid and warm rather than stock-cliché, with one color grade that complements indigo.
- You can't source photos, so build image slots with `next/image` placeholders and write `IMAGES.md`. For each slot, list the art direction, aspect ratio, alt text and a ready-to-use image-generation prompt, so I can drop in licensed stock or generated images.

**Quality**

- Scroll-triggered reveals that respect reduced motion.
- Lighthouse mobile scores of 90 or above in every category, with AVIF or WebP images, a priority hero image and lazy loading below the fold.
- Metadata, OG images (next/og), sitemap, robots.txt and JSON-LD.
- Waitlist and demo forms post to the API, with rate limiting and a honeypot.

## 11. Security baseline

Treat every file as confidential by default, and use OWASP ASVS Level 2 as the checklist.

- Tenant isolation is enforced centrally, retrieval is permission- and sensitivity-aware, and roles get least privilege.
- TLS everywhere, encryption at rest (S3 SSE-KMS, encrypted RDS), and short-lived signed download URLs.
- Uploads get magic-byte type checks, size limits and sanitized filenames.
- Prompt injection: document text is untrusted data. The system prompt tells the model never to follow instructions found in sources, and document content never triggers actions.
- Rate limiting in Redis per user, workspace and IP, stricter on auth routes.
- No secrets in git (only `.env.example`), gitleaks in CI, and Renovate or Dependabot for dependencies.
- Security headers, including CSP and HSTS.

## 12. Platform and DevOps learning track

The platform work is where I learn, so build it in five levels and teach as you go.

**Teaching mode**

- Annotate every Dockerfile, manifest and Terraform file with short "why" comments.
- End each platform phase with a `LEARNING.md`: the concepts used, commands to try, and two or three break-and-fix drills (e.g. a bad readiness probe, an OOMKilled pod, a failed migration).
- If I say "guide me", give me the task, hints and a way to check my work instead of the finished code.

**Level 1: Containers and local dev**

- Multi-stage Dockerfiles, small non-root images, a read-only root filesystem where possible, and healthchecks. Next.js uses `output: "standalone"`.
- One `docker compose up` runs everything with seed data; a Makefile or Taskfile covers common commands.

**Level 2: Kubernetes locally** (kind or k3d, with Tilt or Skaffold for the inner loop)

- An umbrella Helm chart with a subchart per service: Deployments, Services, ConfigMaps, Secrets and ServiceAccounts.
- Readiness, liveness and startup probes; requests and limits; HPA for web and api; KEDA scaling the worker and transcriber on queue depth, with the transcriber scaling to zero when idle.
- Gateway API for routing (`/api` to api, `/` to web) and cert-manager for TLS.
- Prisma migrations run as a Job (a Helm pre-upgrade hook or an Argo CD PreSync hook); a CronJob purges the trash.
- PodDisruptionBudgets, default-deny NetworkPolicies, and Pod Security Standards at "restricted".
- Postgres, Redis, RabbitMQ and object storage run in the cluster only for local work; AWS uses managed services.

**Level 3: GitOps and CI/CD**

- GitHub Actions in each repo: lint, type check, test and build; cached image builds; a Trivy scan; an SBOM; and a push to GHCR (local) or ECR (AWS) using GitHub OIDC, with no long-lived cloud keys.
- CI bumps image tags in `sotto-platform`, and Argo CD (app-of-apps) promotes dev → staging → prod with per-environment values.
- Stretch: preview environments per pull request, and cosign signatures verified by Kyverno.

**Level 4: AWS with Terraform** (remote state in S3 with native locking)

- A VPC with public and private subnets across two or three Availability Zones.
- EKS with managed node groups or Karpenter, plus an optional GPU node group for vLLM that scales to zero.
- RDS PostgreSQL with pgvector, ElastiCache, Amazon MQ for RabbitMQ (or SQS), S3 with KMS, and ECR.
- Secrets Manager with External Secrets Operator, EKS Pod Identity, Route 53 with ACM, and the AWS Load Balancer Controller.
- Cost guardrails: an estimated monthly cost per environment, AWS Budgets alerts, Spot capacity for workers, one NAT gateway outside prod, and everything removable with `terraform destroy`.

**Level 5: Operate it**

- OpenTelemetry in web, api and worker, sent through an OTel Collector to Prometheus, Tempo, Loki and Grafana, with dashboards as code.
- SLOs with alerts and runbooks for API p95 latency (excluding model time), ingestion success rate, time to first token and queue age.
- k6 load tests that exercise HPA and KEDA, an RDS backup-and-restore drill and, as a stretch, chaos experiments.

## 13. Quality bar

A phase is done only when it meets all of these.

- **Accessibility:** WCAG 2.2 AA, covering contrast, visible focus, logical focus order, labels and reduced motion. Automated axe checks run in CI with zero serious violations.
- **Performance:** LCP under 2.5 s, INP under 200 ms and CLS under 0.1 on a mid-range phone. Code-split heavy viewers such as the PDF viewer and waveform.
- **Tests:** unit tests, API integration tests with Testcontainers, and Playwright E2E on iPhone and desktop viewports (upload → ask → citation opens the source). Keep a retrieval eval set of about 20 fictional question-and-answer pairs, scored on every change to the AI pipeline.
- **States:** every screen works in light and dark and has loading, empty and error states; every component has Storybook stories.
- **Docs:** a README per repo with setup in under 10 minutes, a Mermaid architecture diagram, ADRs and published OpenAPI docs.

## 14. How to work with me

Plan first, then build one phase at a time.

- Start with a plan only: architecture diagram, repo trees, Prisma schema draft, API endpoint list, a phase plan with acceptance criteria, and your questions. Wait for my go-ahead.
- End each phase with what's done, how to run it, what's mocked or TODO, and what comes next.
- Never stub a feature silently; label every mock.
- Prefer boring, well-supported libraries, and ask before adding any paid service.
- Make small commits using Conventional Commits.

## Phase prompts

Paste one per session, in order, starting with: "Read CLAUDE.md first, then do this phase."

- **Phase 0: Plan.** Read the brief and produce the plan described in section 14. Don't write any code yet.
- **Phase 1: Scaffold.** Create the three repos with linting, formatting, type checking, test runners, `.env.example`, the Docker Compose stack and CI checks. Done when one command starts everything locally and CI passes.
- **Phase 2: Design system and app shell.** Build the tokens, type, light and dark themes, Button, AsyncWidget states and illustrations, then the shell: tab bar with per-tab stacks, large titles, the + sheet and the desktop three-pane layout. Done when every piece is in Storybook and the shell meets every rule in section 9.
- **Phase 3: Accounts and workspaces.** Auth, workspaces, invites, roles, collection permissions, audit log and onboarding. Done when E2E tests cover sign-up → create workspace → invite → role-restricted access.
- **Phase 4: Ingestion and meetings.** Uploads, recording, the queue, text extraction, the transcriber, chunking, local embeddings, live status, and the Docs and Meetings screens with player, transcript and insights. Done when a PDF and a 30-minute recording both reach Ready with correct pages and timestamps.
- **Phase 5: Ask and search.** Hybrid retrieval with permission and sensitivity filters, streaming chat with citations that open the exact page or timestamp, ⌘K search and the retrieval eval set. Done when a Viewer can't retrieve from a collection they can't open and the eval set passes.
- **Phase 6: AI modes and billing.** The Private, BYOK and Managed gateway, key encryption, workspace AI policy, data-route badges, usage metering and Stripe test-mode billing. Done when Restricted sources are excluded for external models and the UI explains why.
- **Phase 7: Landing page.** Everything in section 10, including `IMAGES.md`. Done when Lighthouse mobile scores are 90 or above in every category.
- **Phase 8: Kubernetes locally.** Level 2 of section 12 plus the Level 5 observability stack, with a `LEARNING.md` and drills. Done when the whole app runs on kind, scales under a k6 load test, and dashboards show the traffic.
- **Phase 9: GitOps and CI/CD.** Level 3 of section 12. Done when a merge to main reaches the dev environment through Argo CD with no manual steps.
- **Phase 10: AWS.** Levels 4 and 5 of section 12: deploy staging with runbooks, SLO alerts and a `LEARNING.md`. Done when staging is live over HTTPS, an alert fires during a drill, and `terraform destroy` removes everything.
