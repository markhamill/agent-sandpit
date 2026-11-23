# agent-sandpit

A sandpit for AI coding agents: somewhere to learn, work and play, without giving them the run of your Mac.

AI coding agents like Claude Code can read, write and run anything your user account can. That's what makes them useful, and it's also what makes running them directly on your Mac a bit of a gamble. agent-sandpit runs them inside a small, throwaway Linux box instead. The agent sees only the project folder you give it. When you exit, the box is deleted.

You type `sandpit-claude` instead of `claude`, and you're in.

> **Please read this first.** agent-sandpit is what I built for my own work, from my own experience. It's safer than running AI agents directly on your Mac, but it isn't a security product, it hasn't been independently audited, and it can't make an agent safe. Read what it [doesn't protect against](#what-it-doesnt-protect-against), do your own research and security checks before you rely on it, and use it at your own risk. Tested on an Apple Silicon (M1) Mac with OrbStack. Docker Desktop and Linux should work but haven't been tested.

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
| Your dev server doesn't load in the browser | It's listening on localhost, or on a different port | Start it with `--host 0.0.0.0 --port $PORT` and use the port the sandpit printed ([dev servers](#everyday-use)) |

## Everyday use

```sh
sandpit-claude       # start a Claude Code sandpit in the current folder
sandpit-agy          # the same for Google Antigravity (uses ~/.gemini instead of ~/.claude)
sandpit-claude 5173  # choose the dev server port yourself
```

**Running more than one session:** go ahead. Open another Terminal window and run `sandpit-claude` again, in the same project or a different one. Each session is its own container with its own port: the first gets 3000, the next 3001, and so on, and each prints its port when it starts. They don't interfere with each other, and when you exit one the others carry on. Each uses about 350 MB of memory, so two or three at once is fine on most Macs.

One thing to watch: two agents in the **same** project folder are editing the same files. That's no different from two people working in one folder, so give them separate tasks, or separate git branches in separate folders (`git worktree add ../my-project-b`).

**Dev servers:** to preview a site in your Mac's browser, two things need to line up.

1. **The port.** Each sandpit opens one port to your Mac (the first free one from 3000), prints it when it starts, and puts it in `PORT` inside.
2. **Listening on 0.0.0.0, not localhost.** Inside the sandpit, "localhost" means the sandpit itself, so a dev server listening only there can't be reached from your Mac. It needs to listen on `0.0.0.0` (every network connection the sandpit has).

Most dev servers default to localhost and their own port, so tell them both:

```sh
npm run dev -- --host 0.0.0.0 --port $PORT    # Vite (also works with pnpm dev)
npx next dev -H 0.0.0.0 -p $PORT              # Next.js
```

Then open `http://localhost:<port>` in your Mac's browser, using the port the sandpit printed. To make it automatic in a Vite project, set it once in `vite.config`:

```js
server: { host: "0.0.0.0", port: Number(process.env.PORT) || 3000 }
```

The port is only open to your own Mac (`127.0.0.1`), not to other machines on your network.

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
- **Agents can't leave code behind for your Mac to run.** In every repo it shares, the git hooks folder and git settings are locked read-only. Agents still edit and commit as normal. ([Why this matters](#why-git-hooks-are-locked).)

## What it doesn't protect against

Know this before you rely on it:

- **The agent can use your Claude login.** It's in `~/.claude`, which is shared.
- **Anything in the shared folder can be changed or deleted.** Commit before you start a session.
- **The network is open.** The agent can reach the internet, and `host.docker.internal` reaches apps on your Mac (used for Ollama).
- **A repo can be booby-trapped for later.** An agent could add a git hook or change where the repo pushes to, which would take effect on your Mac at your next push. That's what `checkgit` catches.
- **The agent installers are `curl | bash`** from Anthropic and Google. Read the Dockerfile and decide whether you're happy with that.
- **Your agent settings are writable.** An agent could add a hook or plugin to `~/.claude`. Inside the sandpit that's contained, but if you also run Claude Code directly on your Mac, the same settings run there too. Check `~/.claude/settings.json` now and then, or keep a separate settings folder for the sandpit.
- **Other files your Mac runs automatically aren't locked.** Git hooks and git settings are (see below), but not, for example, editor settings stored in the project, `.envrc` files, or npm scripts you later run on the Mac. Treat files an agent touched as untrusted until you've looked.
- It's a container, not a separate computer. It's a sensible layer of protection, not a guarantee.

## Check it yourself

Don't take the protections on trust. Start a session in a repo, then try the things an agent shouldn't be able to do. Each of these should **fail** with "Read-only file system" or a similar error:

```sh
touch .git/hooks/test                   # add a git hook
git config --local test.x 1             # change the repo's settings
git remote add test https://example.com # point the repo somewhere else
touch ~/.claude/CLAUDE.md               # edit your global rules
ls ~/.ssh                               # should say "No such file or directory"
```

And these should **work**:

```sh
git commit --allow-empty -m "test" && git reset --soft HEAD~1   # commit, then undo it
touch test.txt && rm test.txt                                    # edit project files
```

If anything in the first list succeeds, undo it (`rm .git/hooks/test`, `git config --local --unset test.x`, `git remote remove test`) and don't rely on the sandpit until you've found out why. A common cause: if you changed your shell setup, the Terminal window you started from may still have the old version. Open a new window and try again.

## Before you push: checkgit

Run it on your Mac, inside the repo, before every push of work an agent did:

```sh
checkgit && git push
```

It flags remotes that don't point at your GitHub account (set `CHECKGIT_OWNER`, e.g. `"me|my-org"` for several), any git hooks, repo settings that can run commands or redirect traffic (`core.hooksPath`, `core.fsmonitor`, `url.*.insteadOf`, filters, aliases and so on), and lists the commits you're about to push. It switches those risky settings off while it looks. If it says CHECK FAILED, read the WARN lines before pushing.

`checkgit` doesn't need the sandpit. It's useful with any AI agent.

## Why git hooks are locked

A **git hook** is a script that git runs automatically at certain moments, such as just before a commit. Hooks live in `.git/hooks` in each repo. They aren't part of what you commit, so they don't show up in `git status`, a diff or GitHub. And they run on whichever machine runs git.

That makes them a way out of the sandpit. An agent tricked by something it read (a web page, an email, a dependency) could write a hook into a repo. Nothing happens inside the sandpit. But the next time git runs on your Mac in that repo, whether that's you committing or a tool that commits for you (Obsidian Git, an editor's auto-commit, a scheduled backup), the hook runs **on your Mac**, with access to everything you have. `checkgit` can't help if a tool commits before you get the chance to run it.

So when a session starts, sandpit finds every repo in the shared folder and makes two things read-only inside the sandpit:

- `.git/hooks`, so no hook can be added.
- `.git/config`, because a repo's settings can tell git to look for hooks somewhere else.

Commits don't write to either, so agents commit exactly as before. Adding a remote or changing repo settings fails with "Read-only file system", which is the point. Make those changes from your Mac.

If you keep an Obsidian vault in the shared folder, its plugins are locked too, because Obsidian runs them on your Mac. Your notes stay editable.

Repos created during a session are locked from the next session.

**Also recommended: switch hooks off on your Mac.** If you don't use git hooks (no Husky, pre-commit or Git LFS), tell git on your Mac never to run them. Run this once:

```sh
mkdir -p ~/.config/git/hooks-off
git config --global core.hooksPath ~/.config/git/hooks-off
```

Git now looks for hooks in an empty folder outside anything the sandpit can see. The read-only `.git/config` matters here too: a repo's own settings override your global ones, and the lock stops an agent changing them.

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

- **Changing your git config on the Mac hides it from running sandpits.** `git config --global` replaces `~/.gitconfig` with a new file, and a sandpit that's already running keeps looking at the old one, which no longer exists. Your name and email are also passed in when a session starts, so commits keep working; other settings come back at the next session.
- **Don't share a single file onto `~/.gitconfig`.** Git saves its config by writing a new file and renaming it over the old one, and a shared file can't be replaced, so every `git config --global` fails with "Device or resource busy". The image reads a read-only copy at `~/.gitconfig-host` instead.
- **Docker caches build steps that haven't changed**, so `curl ... | bash` installers never re-run and the agent tools fall behind. `sandpit build` passes the date in to refresh them daily.
- **Build without a context.** `docker build -f Dockerfile ~` sends your entire home folder to Docker on every build. `sandpit build` sends only the Dockerfile.
- **Two sandpits on one port fail** with "port is already allocated". Hence the free-port search.
- **A dev server on localhost is invisible from your Mac.** Inside a container, localhost is the container. Listen on 0.0.0.0.
- **Sharing a file that doesn't exist** makes Docker create an empty folder with that name on your Mac. The script only shares `CLAUDE.md` and `.gitconfig` if they're there.
- **Voice mode won't work.** A Linux container on a Mac can't reach the microphone. Use macOS dictation instead.
- **The sandpit can't see `~/Downloads`.** Put files you want the agent to read in the project folder.

Longer write-up: [Dropping VS Code: A Leaner Sandbox for AI Coding Agents](https://direction-matters.com/labs/notes).

## Licence

MIT. See [LICENSE](LICENSE). Provided as is, with no warranty: see the licence for the full terms.
