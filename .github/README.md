# dev-notes

Design notes kept beside your code, in their own git repo, shared by every worktree, with rules an agent follows. Optional scripts run each worktree on its own ports.

```
~/work/<project>/
  <repo>/              # main checkout
  <repo>-<topic>/      # worktrees
  dev-notes/           # this scaffold; linked into each checkout as dev-notes
```

## Setup

Open Claude Code inside your repo's checkout and paste:

````
Set up dev-notes for this repo, using the dev-notes plugin from https://github.com/souvik-razor/dev-notes-template.

1. Install the plugin from the shell:
   claude plugin marketplace add souvik-razor/dev-notes-template
   claude plugin install dev-notes@dev-notes
   If it is already installed, run `claude plugin marketplace update dev-notes` and `claude plugin update dev-notes@dev-notes` instead.
2. The skill only loads after a restart, so read it directly from the marketplace clone:
   "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/marketplaces/dev-notes/skills/dev-notes/SKILL.md"
   If it is not there, `git clone --depth 1 https://github.com/souvik-razor/dev-notes-template` into a temp dir and use its skills/dev-notes/SKILL.md.
   Its base directory is the folder that holds that SKILL.md.
3. Follow the skill's "init" section for the git checkout I am in. Ask me the questions it says to ask before writing anything.
4. Finish with what you created, anything I still need to do, and that after restarting Claude Code I can use /dev-notes:dev-notes (init, merged <PR>, audit) or just ask.
````

## Manual install

```
/plugin marketplace add souvik-razor/dev-notes-template
/plugin install dev-notes@dev-notes
```

Then `/dev-notes:dev-notes init` from inside a checkout. Without Claude Code: copy this repo beside your checkout, delete `.github/`, `.claude-plugin/` and `skills/`, and follow [README.md](../README.md).

## What you get

- [README.md](../README.md): the notes layout and its rules; it becomes your notes' README.
- [local-run/](../local-run/README.md): `setup-worktree.sh new <topic>` creates a worktree with its own ports and `.env`; `run.sh start|stop|status` runs it.
- The `dev-notes` skill: `init`, notes written by the rules without asking, `merged <PR>` (status, archive, trackers), `audit`.
