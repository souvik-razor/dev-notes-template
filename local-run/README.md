# Local run

Every checkout (main or worktree) runs the whole app on its own ports, so several branches run side by side. Logs, PIDs and ports live in `<checkout>/.run/`, never here.

| File | What |
| --- | --- |
| [project.sh](project.sh) | The only file to edit: services, ports, start commands, dependency install, `.env` files |
| [setup-worktree.sh](setup-worktree.sh) | Create a worktree (`new <topic>`) or prepare an existing checkout: dev-notes link, dependencies, free ports, `.env` copies |
| [run.sh](run.sh) | `start|stop|restart|status [service...]` for the checkout you run it from |

```
dev-notes/local-run/setup-worktree.sh ../myapp          # once, for the main checkout
dev-notes/local-run/setup-worktree.sh new login-fix     # ../myapp-login-fix on feat/login-fix, ports 8010/3010
cd ../myapp-login-fix && dev-notes/local-run/run.sh start
dev-notes/local-run/run.sh status
```

Each service must take its port from the command in `service_cmd` (an env var or flag), not a hardcoded value. Shared infra (database, queues) stays one stack started separately. Needs git 2.31+ and `lsof`.
