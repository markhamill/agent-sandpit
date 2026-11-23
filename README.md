# agent-sandpit

A sandpit for AI coding agents: somewhere to learn, work and play, without giving them the run of your Mac.

`sandpit-claude` starts Claude Code (and `sandpit-agy` starts Antigravity) in a throwaway Linux container. The container is deleted when you exit, and the agent only sees the folder you give it. Codex is installed too if you want it.

I use this every day. The write-up of why, and what went wrong along the way, is in [Dropping VS Code: A Leaner Sandbox for AI Coding Agents](https://direction-matters.com/labs/notes).

## What it does

- **Agents run in Linux, not on your Mac.** They can't see your home folder, SSH keys, cloud credentials, browser or `~/Downloads`.
- **Only the folder you choose is mounted.** By default that's the folder you run it from. It refuses to mount your whole home folder.
- **Throwaway.** The container is removed on exit (`--rm`). Anything that matters is on disk in the mounted folder.
- **Your agent settings are shared, not copied.** `~/.claude` is mounted in, so skills, settings, memory and history are the same inside and out.
- **The agent can't rewrite its own global rules.** `~/.claude/CLAUDE.md` is mounted read-only.
- **No GitHub access inside.** Agents commit locally and you push from your Mac, after running `checkgit`.

## What it doesn't protect against

Be clear about this before you rely on it:

- **The agent can use your Claude login.** `~/.claude` holds it, and it's mounted read-write.
- **Anything in the mounted folder can be changed or deleted.** Commit before you start a session (or snapshot with `git add -A && git commit -m wip`).
- **The network is open.** The agent can reach the internet, and `host.docker.internal` reaches services on your Mac (for Ollama). Add your own firewall rules if you need tighter limits.
- **A repo can be booby-trapped for later.** An agent could add a git hook or change a remote, which would run or leak on your Mac when you next push. That's what `checkgit` is for.
- **The installers are `curl | bash`** from Anthropic and Google. Read the Dockerfile and decide whether you're happy with that.
- It's a container, not a VM. It's a sensible layer, not a guarantee.

## Requirements

- macOS or Linux with Docker. On a Mac, [OrbStack](https://orbstack.dev) (what I use) or Docker Desktop.
- `zsh` on the host for `checkgit` (the default shell on macOS).

## Install

```sh
git clone https://github.com/<you>/agent-sandpit.git ~/agent-sandpit
echo 'export PATH="$HOME/agent-sandpit/bin:$PATH"' >> ~/.zshrc   # then open a new terminal
sandpit build
sandpit check
```

Keep the clone **outside** any folder you mount into the sandpit, so an agent can't edit the scripts that guard it.

## Use

```sh
cd ~/code/my-project
sandpit-claude       # shell in the sandpit, with my-project mounted; then run: claude
sandpit-agy          # the same for Antigravity (mounts ~/.gemini instead of ~/.claude)
sandpit-claude 5173  # pick the dev port yourself
```

The first time, log in to Claude Code inside the sandpit. The login is saved in your mounted `~/.claude`, so you only do it once.

**Dev servers:** each sandpit publishes one port on `127.0.0.1` (first free from 3000, so two sandpits can run side by side) and sets `PORT` inside. Start your dev server on `$PORT` and open `http://localhost:<port>` on your Mac.

**One parent folder for everything:** if you keep all your projects under one folder, mount that and the sandpit starts in whichever project you're in:

```sh
export AGENT_WORKSPACE="$HOME/code"   # in ~/.zshrc
cd ~/code/website && sandpit-claude   # mounts all of ~/code, starts in website
```

| Setting | Default | What it does |
|---|---|---|
| `AGENT_WORKSPACE` | unset (current folder only) | Folder to mount |
| `SANDPIT_IMAGE` | `agent-sandpit` | Image name |
| `SANDPIT_DOCKERFILE` | the repo's `Dockerfile` | Build from your own copy |
| `OLLAMA_HOST` | unset | Passed in if set, e.g. `http://host.docker.internal:11434` |

## Before you push: checkgit

Run on your Mac, inside the repo, before every push of agent-written work:

```sh
export CHECKGIT_OWNER="your-github-user|your-org"   # in ~/.zshrc
checkgit && git push
```

It flags remotes that don't point at your GitHub accounts, any git hooks, repo-local settings that can run commands or redirect traffic (`core.hooksPath`, `core.fsmonitor`, `url.*.insteadOf`, filters, aliases and so on), and lists the commits you're about to push. It runs git with the risky settings switched off while it looks.

## Keeping it up to date

```sh
sandpit build          # daily refresh of the agent CLIs
sandpit build --fresh  # new base image and no cache: do this every few weeks for security patches
sandpit clean          # tidy stopped containers and old images
```

Each build tags the previous image as `agent-sandpit:backup`. To roll back: `docker tag agent-sandpit:backup agent-sandpit`. Running sandpits keep the image they started with.

## Things I learned the hard way

- **Don't mount a file onto `~/.gitconfig`.** Git saves its config by writing a lock file and renaming it over the original. A bind-mounted file can't be replaced, so every `git config --global` fails with "Device or resource busy". The image includes a read-only copy at `~/.gitconfig-host` instead.
- **Docker caches `RUN` lines that haven't changed**, so `curl ... | bash` installers never re-run and your CLIs fall behind. `sandpit build` passes the date as a build argument to refresh them daily.
- **Build without a context.** `docker build -f Dockerfile ~` sends your entire home folder to Docker on every build. `sandpit build` pipes the Dockerfile in with no context.
- **Two sandpits on one port fail** with "port is already allocated". Hence the free-port search.
- **Mounting a file that doesn't exist** makes Docker create an empty folder with that name on your Mac. The script only mounts `CLAUDE.md` and `.gitconfig` if they're there.
- **Voice mode won't work.** A Linux container on a Mac can't reach the microphone. Use macOS dictation instead.
- **The sandpit can't see `~/Downloads`.** Put files you want the agent to read in the mounted folder.

## Licence

MIT. See [LICENSE](LICENSE).
