---
name: dev-notes
description: Use when writing, moving or archiving design notes, plans, explorations or decisions for a repo, or when asked to init, audit, or post-merge update its dev-notes
argument-hint: "[init [checkout] | merged <PR> | audit]"
---

# dev-notes

A dev-notes folder is its own git repo beside the code checkout (`<workspace>/dev-notes`), shared by every worktree and linked into each one as `dev-notes`. Its `README.md` rules are the authority; this skill applies them. The notes repo is separate from the code repo: never write notes into the code repo, and commit notes only in the notes repo.

**Find the notes:** `<git toplevel>/dev-notes` (symlink), else `<git toplevel>/../dev-notes`. Neither exists and the task is not `init`: say so and offer `/dev-notes init`.

| Argument | Mode |
| --- | --- |
| none, or triggered by a notes task | Write notes |
| `init [checkout]` | Scaffold notes beside a repo |
| `merged <PR>` | Post-merge update (README rule 3) |
| `audit` | Read-only rule check |

## Write notes

1. Read the notes `README.md` (areas and rules) and `AGENTS.md`. A project may have added areas; use them.
2. Start new docs from `_templates/`; place, name and index them as the README says, in the same change. Index rows are edits to the existing area README, never a rewrite of it.
3. Write only what the user said or the code shows. Template sections with nothing real go as `TBD`, never filled with invented options, reasons or questions.

## init [checkout]

1. Checkout = the argument, else the git toplevel. Target = `<checkout>/../dev-notes`. Show the user the layout (`<workspace>/<repo>`, `<workspace>/dev-notes`) and confirm before writing. If the checkout's parent holds unrelated projects (e.g. `~/work` itself), propose a project folder first. Target exists: stop and report.
2. Template root = this skill's base directory, two levels up. No `_templates/` there: `git clone --depth 1 https://github.com/souvik-razor/dev-notes-template` into a temp dir and use that.
3. `rsync -a --exclude .git --exclude .claude-plugin --exclude skills <template root>/ <target>/`. Replace `<project>` in `README.md` with the repo name. `git init`, commit `dev-notes: scaffold`.
4. Append to `<checkout>/CLAUDE.local.md` (create if missing, skip if present): `Design notes live in ../dev-notes. Read ../dev-notes/README.md rules before creating or moving any doc there.` Add `CLAUDE.local.md` to `.git/info/exclude`.
5. Ask whether they run worktrees side by side. No: delete `local-run/` and its README row. Yes: fill `local-run/project.sh` from the repo (package.json scripts, Makefile, Procfile, docker-compose, `.env*`): checkout name, `WORKTREE_PREFIX=<repo>-`, `BASE_BRANCH=origin/<default branch>`, each service's start command, main port and a worktree range 10 above, `install_deps`, `ENV_FILES`. A service with a hardcoded port: report it, do not patch the code repo. Show the file, then run `local-run/setup-worktree.sh <checkout>`.
6. Report paths, commit, and anything left for the user.

## merged <PR>

1. In the code checkout: `gh pr view <N> --json state,title,headRefName,files,mergedAt`. Not merged: stop.
2. Find affected docs: grep the notes for `#<N>`, `PR <N>`, the branch name, and the changed paths in `Code:` lines.
3. Per README rule 3: design doc `Status: implemented (PR #N)` with today's `Updated`; architecture docs updated to match the merged code (read `gh pr diff <N>`); finished plans and build logs `git mv`'d to `archive/<topic>/` with an archive README row (why, where the truth is now); tracker items ticked; every touched area index row updated.
4. List each change. Commit in the notes repo only when asked.

## audit

Read-only; report, then offer fixes. Skip `README.md` and `_templates/`.

- Docs without `Status:` in their first 5 lines (rule 1)
- Exploration files not named `YYYY-MM-DD-<topic>.md` (rule 2)
- `implemented` or `superseded` docs outside `archive/` (rule 4)
- Logs, `node_modules`, images or other generated files; screenshots outside `qa/<date>-<topic>/` (rule 5)
- Docs missing from their area README, and README rows linking to missing files (rule 6)
- `draft` or `active` docs with `Updated` older than 30 days (likely stale)

Output one line per finding, grouped by rule: `path: problem. fix.`

## Common mistakes

- Notes written into the code repo (`docs/`, `PLAN.md`) because `dev-notes` was not looked for.
- A new doc with no index row, or a moved doc whose old index row stays.
- A superseded doc edited in place instead of archived with a pointer.
- Notes committed in the code repo, or the code repo committed from the notes.
