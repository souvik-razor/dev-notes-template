# Per-project settings for run.sh and setup-worktree.sh. Edit this file; the scripts stay generic.
# Sourced by both (bash 3.2 compatible: no associative arrays).

MAIN_CHECKOUT=myapp          # <workspace>/myapp is the main checkout
WORKTREE_PREFIX=myapp-       # `setup-worktree.sh new foo` creates <workspace>/myapp-foo
BASE_BRANCH=origin/main      # default base for new worktree branches
SERVICES=(api web)           # every service run.sh manages, in start order

# Port of <svc> in the main checkout.
main_port() { case "$1" in api) echo 8000 ;; web) echo 3000 ;; esac; }
# First port tried for <svc> in a worktree. Keep ranges apart so services never collide.
worktree_port() { case "$1" in api) echo 8010 ;; web) echo 3010 ;; esac; }

# Shell command that runs <svc> in the foreground on port <port>; $ROOT is the checkout.
service_cmd() {
  case "$1" in
    api) echo "cd '$ROOT/api' && PORT=$2 npm run dev" ;;
    web) echo "cd '$ROOT/web' && PORT=$2 npm run dev" ;;
  esac
}

# Install dependencies into checkout $1. Runs on every setup, so keep it idempotent.
install_deps() { (cd "$1" && npm install --silent); }

# Files copied from the main checkout into a new worktree, with every main port rewritten to the worktree's.
ENV_FILES=(api/.env web/.env)
