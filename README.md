# dev-notes

Local design notes for `<project>`. Own git repo, kept beside the code checkout, never inside it.

| Area | Answers |
| --- | --- |
| [architecture/](architecture/README.md) | How does it work now |
| [features/](features/README.md) | What are we building and why |
| [explorations/](explorations/README.md) | What did we find in the code (or outside it) |
| [decisions/](decisions/README.md) | Why we chose X |
| [plans/](plans/README.md) | Cross-cutting open plans |
| [trackers/](trackers/README.md) | Living lists |
| [runbooks/](runbooks/README.md) | How to run things |
| [local-run/](local-run/README.md) | Run the app per checkout: each worktree on its own ports |
| [qa/](qa/README.md) | Test reports and short-lived screenshots |
| [archive/](archive/README.md) | Finished or superseded work |

Add an area only when a project needs one (e.g. `entities/` for one doc per domain model, `integrations/` for third-party systems), and list it here.

## Rules

1. **Every doc starts with a status line**: `Status: draft | active | implemented (PR #N) | superseded (by X) · Updated: YYYY-MM-DD · Code: <paths>`. A doc without one is treated as unknown.
2. **Place by question**: architecture (how it works now), features/ (what and why we build), explorations (what we found, dated in the file name: `YYYY-MM-DD-<topic>.md`), decisions (one record per choice: context, options, choice, date), trackers (living lists), plans (cross-cutting work not owned by one feature).
3. **When a PR merges**: mark its design `implemented (PR #N)`, update the architecture doc to match the code, move the plan to `archive/<topic>/` (the archive README says where the current truth is), tick the tracker.
4. **Superseded means moved**: nothing stale stays in a live folder; archive it with a one-line pointer.
5. **No generated output in dev-notes**: logs, browser profiles, `node_modules`, telemetry live in scratch or the checkout. Screenshots only under `qa/<date>-<topic>/`, deleted once the PR merges.
6. **One index**: each area has a README listing its docs with status; this README lists areas.
7. **Paths cited from code** point at `architecture/` docs only, so moves elsewhere never break code references.

Templates: [_templates/doc.md](_templates/doc.md), [_templates/decision.md](_templates/decision.md).

## Setup for a new project

1. Copy this repo next to the code, not inside it:
   ```
   ~/work/<project>/
     <repo>/              # main checkout
     <repo>-<branch>/     # worktrees, if you use them
     dev-notes/           # this repo; every checkout shares it
   ```
2. Replace `<project>` above, then `git init && git add -A && git commit -m "dev-notes: scaffold"`. Keep it local (no remote) if notes may hold internal or personal data.
3. Point the code repo's agent at it with an uncommitted file such as `<repo>/CLAUDE.local.md` (or your personal agent config):
   ```
   Design notes live in ../dev-notes. Read ../dev-notes/README.md rules before creating or moving any doc there.
   ```
4. To run each worktree independently, edit [local-run/project.sh](local-run/project.sh), then `local-run/setup-worktree.sh ../<repo>`. New worktrees: `local-run/setup-worktree.sh new <topic>`. See [local-run/README.md](local-run/README.md).
