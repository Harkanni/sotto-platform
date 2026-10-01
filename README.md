# sotto-platform

Infrastructure, deployment and the documentation hub for **Sotto** — private AI for your team's memos and meetings.

| Repo | What |
| --- | --- |
| [sotto-web](https://github.com/Harkanni/sotto-web) | Next.js app |
| [sotto-api](https://github.com/Harkanni/sotto-api) | API, worker, transcriber, database |
| **sotto-platform** | Compose stack, Terraform, deploys, docs |

## Start here

- **Where are we?** [`docs/STATUS.md`](docs/STATUS.md)
- **The plan:** [`docs/PLAN.md`](docs/PLAN.md) · **The brief:** [`docs/BRIEF.md`](docs/BRIEF.md) · **Decisions:** [`docs/adr/`](docs/adr)

## Resume the build in any new session

Paste this into a new chat or Claude Code session:

```text
I'm building Sotto. Clone harkanni/sotto-platform, sotto-api and sotto-web side by side.
Read sotto-platform/CLAUDE.md and sotto-platform/docs/STATUS.md, then continue from "Next step".
```

## Run the whole stack

```bash
task up        # builds ../sotto-api and ../sotto-web, starts everything, waits for health
open http://localhost:8080
```

Needs Docker and [Task](https://taskfile.dev). On a busy laptop, run it on the AWS workbench instead (see `terraform/README.md`).

## The always-on demo

Terraform in `terraform/` builds it; `terraform/README.md` has the first-time steps. After that, every merge to `main` in sotto-api or sotto-web builds arm64 images and deploys them automatically.

## Work on it in VS Code

```bash
mkdir -p ~/code/sotto && cd ~/code/sotto
git clone https://github.com/Harkanni/sotto-platform.git
git clone https://github.com/Harkanni/sotto-api.git
git clone https://github.com/Harkanni/sotto-web.git
code sotto-platform/sotto.code-workspace
```

Always `git pull` before you start, work on a branch, and open a pull request.
