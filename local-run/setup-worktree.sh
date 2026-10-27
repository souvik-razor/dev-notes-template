#!/bin/bash
# Make a checkout (main or worktree) runnable on its own, beside every other checkout.
#
#   dev-notes/local-run/setup-worktree.sh <checkout path>
#   dev-notes/local-run/setup-worktree.sh new <topic> [branch] [base]
#
# `new` first creates the worktree <workspace>/<WORKTREE_PREFIX><topic> from the main checkout
# (<workspace>/<MAIN_CHECKOUT>): branch defaults to feat/<topic>, base to BASE_BRANCH (fetched).
# An existing branch is checked out as is, base ignored. Settings live in project.sh.
#
# - links <checkout>/dev-notes -> ../dev-notes, so agents working in the checkout see the notes
# - excludes dev-notes and .run/ in .git/info/exclude (one file for all worktrees)
# - install_deps from project.sh (per checkout: branches pin different dependencies)
# - .run/ports: main checkout gets main_port; worktrees the first free port from worktree_port
# - ENV_FILES copied from the main checkout, main ports rewritten to this checkout's
# Idempotent: existing .env files and .run/ports are kept.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
. "$HERE/project.sh"
WS="$(dirname "$(dirname "$HERE")")"   # dev-notes/local-run -> workspace

if [ "${1:-}" = "new" ]; then
  TOPIC="${2:?usage: setup-worktree.sh new <topic> [branch] [base]}"
  SRC="$WS/$MAIN_CHECKOUT"
  BRANCH="${3:-feat/$TOPIC}"
  BASE="${4:-$BASE_BRANCH}"
  WT="$WS/$WORKTREE_PREFIX$TOPIC"
  if [ -e "$WT" ]; then echo "$WT already exists" >&2; exit 1; fi
  if git -C "$SRC" show-ref -q --verify "refs/heads/$BRANCH"; then
    git -C "$SRC" worktree add "$WT" "$BRANCH"
  else
    if [[ "$BASE" == origin/* ]]; then git -C "$SRC" fetch -q origin "${BASE#origin/}"; fi
    git -C "$SRC" worktree add --no-track -b "$BRANCH" "$WT" "$BASE"
  fi
  set -- "$WT"
fi

DEST="$(cd "${1:?usage: setup-worktree.sh <checkout path>}" && pwd)"
COMMON="$(git -C "$DEST" rev-parse --path-format=absolute --git-common-dir)"
MAIN="$(dirname "$COMMON")"   # main checkout: the one holding .git

# dev-notes link
if [ -L "$DEST/dev-notes" ] || [ ! -e "$DEST/dev-notes" ]; then   # -sfn also repoints a dangling link
  ln -sfn ../dev-notes "$DEST/dev-notes" && echo "linked dev-notes -> ../dev-notes"
fi

# A symlink is not a directory, so a .gitignore `dev-notes/` would miss it.
mkdir -p "$COMMON/info"
for p in dev-notes .run/; do
  grep -qxF "$p" "$COMMON/info/exclude" 2>/dev/null || echo "$p" >>"$COMMON/info/exclude"
done

install_deps "$DEST"

# Ports. Each port is appended as soon as it is picked, so the scan over every checkout's
# .run/ports also sees this checkout's earlier picks.
free_port() {
  local p=$1
  while lsof -ti "tcp:$p" -sTCP:LISTEN >/dev/null 2>&1 || grep -qs "=$p\$" "$WS"/*/.run/ports; do p=$((p + 1)); done
  echo "$p"
}
mkdir -p "$DEST/.run"
if [ ! -f "$DEST/.run/ports" ]; then
  for s in "${SERVICES[@]}"; do
    if [ "$DEST" = "$MAIN" ]; then p=$(main_port "$s"); else p=$(free_port "$(worktree_port "$s")"); fi
    echo "$s=$p" >>"$DEST/.run/ports"
  done
fi
echo "ports: $(tr '\n' ' ' <"$DEST/.run/ports")"

# .env files, main ports rewritten for this checkout
if [ "$DEST" != "$MAIN" ]; then
  subs=()
  for s in "${SERVICES[@]}"; do
    subs+=(-e "s#localhost:$(main_port "$s")#localhost:$(grep "^$s=" "$DEST/.run/ports" | cut -d= -f2)#g")
  done
  for f in ${ENV_FILES[@]+"${ENV_FILES[@]}"}; do
    if [ ! -f "$DEST/$f" ] && [ -f "$MAIN/$f" ]; then
      sed "${subs[@]}" "$MAIN/$f" >"$DEST/$f.tmp" && mv "$DEST/$f.tmp" "$DEST/$f" && echo "wrote $f"   # no half-written file left to keep
    fi
  done
fi
echo "done: $DEST (run: dev-notes/local-run/run.sh start from inside it)"
