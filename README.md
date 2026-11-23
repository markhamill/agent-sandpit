# agent-sandpit

A sandpit for AI coding agents: somewhere to learn, work and play, without giving them the run of your Mac.

AI coding agents like Claude Code can read, write and run anything your user account can. That's what makes them useful, and it's also what makes running them directly on your Mac a bit of a gamble. agent-sandpit runs them inside a small, throwaway Linux box instead. The agent sees only the project folder you give it. When you exit, the box is deleted.

You type `sandpit-claude` instead of `claude`, and you're in.

## How it fits together

```
 Your Mac                                  The sandpit (a Linux container)
 ────────                                  ───────────────────────────────
 ~/code/my-project   ── shared folder ──>  /workspaces/my-project   (the agent works here)
 ~/.claude           ── shared folder ──>  agent settings and login
 ~/.gitconfig        ── read-only ──────>  your name and email for commits

 Everything else on your Mac               not visible inside
 (home folder, SSH keys, passwords,
  Downloads, browser)
```

The container is the box. **OrbStack** (or Docker Desktop) is the app on your Mac that runs boxes like this. The **Dockerfile** is the recipe for what goes in the box, and `sandpit build` follows that recipe once to make an **image**, a ready-made box that each session starts from.

## Getting started

About 15 minutes the first time, most of it waiting for downloads. You'll need a Mac and the Terminal app (in Applications → Utilities). Each grey block below is something to paste into Terminal and run with Enter.

### 1. Install OrbStack and leave it running

OrbStack runs the container. Download it from [orbstack.dev](https://orbstack.dev), or if you use Homebrew:

```sh
brew install --cask orbstack
```

Open OrbStack once and go through its setup. Then, so it's always there when you need it, turn on **Start at login** in OrbStack's settings. The sandpit only works while OrbStack is running. You'll see its icon in the menu bar.

Check it's working:

```sh
docker version
```

You should see a "Server" section. If you see "Cannot connect to the Docker daemon", OrbStack isn't running. Open it and try again.

OrbStack is free for personal use. For work use, check its licence. [Docker Desktop](https://www.docker.com/products/docker-desktop/) also works, with the same steps.

### 2. Download agent-sandpit

```sh
git clone https://github.com/<you>/agent-sandpit.git ~/agent-sandpit
```

If your Mac asks to install "command line developer tools", say yes, wait for it to finish and run the command again.

This puts everything in a folder called `agent-sandpit` in your home folder. Leave it there: it's deliberately **outside** your projects, so an agent working in a project can't edit the tools that keep it in the sandpit.

### 3. Make the commands available

```sh
echo 'export PATH="$HOME/agent-sandpit/bin:$PATH"' >> ~/.zshrc
```

This tells Terminal where to find `sandpit-claude` and the other commands. **Close Terminal and open a new window** so it takes effect.

### 4. Build the sandpit

```sh
sandpit build
```

You can run this from any folder. It uses the Dockerfile inside `~/agent-sandpit`, so there's nothing to copy or create. The first build takes a few minutes. When it says "Built agent-sandpit", check it:

```sh
sandpit check
```

You should see a Node version and a Claude Code version.

### 5. Start your first session

Go to the project folder you want the agent to work in, then start the sandpit:

```sh
cd ~/code/my-project
sandpit-claude
```

Your prompt changes to green `node@…`. You're now inside the sandpit. Start Claude Code as usual:

```sh
claude
```

The first time, it asks you to log in. The login is saved on your Mac, so you only do this once.

When you're finished, exit Claude Code, then type `exit` to leave the sandpit. The container is deleted. Your project files stay, because they live on your Mac.

### 6. Before you push to GitHub

The sandpit has no access to GitHub, on purpose. Agents can commit, but you push, from a normal Terminal window on your Mac. Before you do, run `checkgit` in the project to make sure nothing has been tampered with (more on this [below](#before-you-push-checkgit)):

```sh
export CHECKGIT_OWNER="your-github-username"   # once, in ~/.zshrc
checkgit && git push
```

That's it. From now on it's `cd` into a project, `sandpit-claude`, then `claude`.

## If something goes wrong

| What you see | What it means | What to do |
|---|---|---|
| `Cannot connect to the Docker daemon` | OrbStack isn't running | Open OrbStack, and turn on Start at login |
| `command not found: sandpit-claude` | Terminal can't find the commands | Open a new Terminal window. If it persists, repeat step 3 |
| `image agent-sandpit not built yet` | The build hasn't been done | Run `sandpit build` |
| `refusing to mount /Users/you` | You ran it from your home folder | `cd` into a project folder first |
| Your dev server doesn't load in the browser | It's on a different port | Use the port the sandpit printed when it started (see below) |

## Everyday use

```sh
sandpit-claude       # start a Claude Code sandpit in the current folder
sandpit-agy          # the same for Google Antigravity (uses ~/.gemini instead of ~/.claude)
sandpit-claude 5173  # choose the dev server port yourself
```

**Dev servers:** each sandpit opens one port to your Mac (the first free one from 3000, so two sandpits can run side by side) and sets `PORT` inside. Start your dev server on `$PORT` and open `http://localhost:<port>` in your Mac's browser.

**All your projects in one folder?** Share the whole folder instead, and the sandpit starts in whichever project you're in:

```sh
export AGENT_WORKSPACE="$HOME/code"     # once, in ~/.zshrc
cd ~/code/website && sandpit-claude     # shares all of ~/code, starts in website
```

Codex is installed in the image too. Run `codex` inside a sandpit if you use it.

## What it protects

- **Agents run in Linux, not on your Mac.** They can't see your home folder, SSH keys, cloud credentials, browser or `~/Downloads`.
- **Only the folder you choose is shared.** By default that's the folder you run it from. It refuses to share your whole home folder.
- **Throwaway.** The container is removed on exit. Anything that matters is in your project folder.
- **Your agent settings are shared, not copied.** `~/.claude` is shared, so skills, settings, memory and history are the same inside and out.
- **The agent can't rewrite its own global rules.** `~/.claude/CLAUDE.md` is shared read-only.
- **No GitHub access inside.** Agents commit locally and you push from your Mac, after `checkgit`.

## What it doesn't protect against

Know this before you rely on it:

- **The agent can use your Claude login.** It's in `~/.claude`, which is shared.
- **Anything in the shared folder can be changed or deleted.** Commit before you start a session.
- **The network is open.** The agent can reach the internet, and `host.docker.internal` reaches apps on your Mac (used for Ollama).
- **A repo can be booby-trapped for later.** An agent could add a git hook or change where the repo pushes to, which would take effect on your Mac at your next push. That's what `checkgit` catches.
- **The agent installers are `curl | bash`** from Anthropic and Google. Read the Dockerfile and decide whether you're happy with that.
- It's a container, not a separate computer. It's a sensible layer of protection, not a guarantee.

## Before you push: checkgit

Run it on your Mac, inside the repo, before every push of work an agent did:

```sh
checkgit && git push
```

It flags remotes that don't point at your GitHub account (set `CHECKGIT_OWNER`, e.g. `"me|my-org"` for several), any git hooks, repo settings that can run commands or redirect traffic (`core.hooksPath`, `core.fsmonitor`, `url.*.insteadOf`, filters, aliases and so on), and lists the commits you're about to push. It switches those risky settings off while it looks. If it says CHECK FAILED, read the WARN lines before pushing.

`checkgit` doesn't need the sandpit. It's useful with any AI agent.

## Keeping it up to date

```sh
sandpit build          # refreshes the agent tools (safe to run daily)
sandpit build --fresh  # rebuilds from scratch with the latest Linux patches: every few weeks
sandpit clean          # tidies away old containers and images
cd ~/agent-sandpit && git pull   # get the latest version of agent-sandpit itself
```

Each build keeps the previous image as `agent-sandpit:backup`. If a new build misbehaves: `docker tag agent-sandpit:backup agent-sandpit`. Sandpits that are already running keep the image they started with.

## Customising

To change what's in the box (add a tool, remove Codex), copy the Dockerfile somewhere outside the repo so `git pull` won't overwrite it, edit it, and point the build at it:

```sh
cp ~/agent-sandpit/Dockerfile ~/.Dockerfile.sandpit
export SANDPIT_DOCKERFILE="$HOME/.Dockerfile.sandpit"   # in ~/.zshrc
sandpit build
```

| Setting | Default | What it does |
|---|---|---|
| `AGENT_WORKSPACE` | unset (current folder only) | Folder to share |
| `SANDPIT_DOCKERFILE` | the repo's `Dockerfile` | Build from your own copy |
| `SANDPIT_IMAGE` | `agent-sandpit` | Image name |
| `OLLAMA_HOST` | unset | Passed in if set, e.g. `http://host.docker.internal:11434` |
| `CHECKGIT_OWNER` | unset | GitHub account(s) `checkgit` expects remotes to point at |

## Things I learned the hard way

- **Don't share a single file onto `~/.gitconfig`.** Git saves its config by writing a new file and renaming it over the old one, and a shared file can't be replaced, so every `git config --global` fails with "Device or resource busy". The image reads a read-only copy at `~/.gitconfig-host` instead.
- **Docker caches build steps that haven't changed**, so `curl ... | bash` installers never re-run and the agent tools fall behind. `sandpit build` passes the date in to refresh them daily.
- **Build without a context.** `docker build -f Dockerfile ~` sends your entire home folder to Docker on every build. `sandpit build` sends only the Dockerfile.
- **Two sandpits on one port fail** with "port is already allocated". Hence the free-port search.
- **Sharing a file that doesn't exist** makes Docker create an empty folder with that name on your Mac. The script only shares `CLAUDE.md` and `.gitconfig` if they're there.
- **Voice mode won't work.** A Linux container on a Mac can't reach the microphone. Use macOS dictation instead.
- **The sandpit can't see `~/Downloads`.** Put files you want the agent to read in the project folder.

Longer write-up: [Dropping VS Code: A Leaner Sandbox for AI Coding Agents](https://direction-matters.com/labs/notes).

## Licence

MIT. See [LICENSE](LICENSE).
