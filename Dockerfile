# agent-sandbox: a throwaway Linux box for AI coding agents.
# Build with `sandbox build` (no build context: nothing from your machine is sent to Docker).

FROM node:22-bookworm

# zsh for the sandbox shell
RUN apt-get update && apt-get install -y --no-install-recommends zsh \
    && rm -rf /var/lib/apt/lists/*

# Run as the image's non-root user, so the agents' CLIs can update themselves
USER node

# Your host ~/.gitconfig is mounted read-only at ~/.gitconfig-host and included from here.
# Don't mount a single file straight onto ~/.gitconfig: git saves config by renaming a
# lock file over it, and a bind-mounted file can't be renamed ("Device or resource busy").
RUN git config --global include.path /home/node/.gitconfig-host

# A prompt, and no zsh first-run wizard
RUN echo "PROMPT='%F{green}%B%n%b%f@%F{blue}%B%2~%b%f%# '" > /home/node/.zshrc

# npm globals go in a folder node owns (the official image's /usr/local is root-only)
ENV NPM_CONFIG_PREFIX="/home/node/.npm-global"
ENV PATH="/home/node/.local/bin:/home/node/.npm-global/bin:${PATH}"

# Docker caches every RUN line that hasn't changed, so a plain rebuild can keep old CLI
# versions for ever. `sandbox build` passes today's date here, which re-runs the installs
# below once a day without redoing apt.
ARG CLI_REFRESH=none
RUN echo "CLI refresh: ${CLI_REFRESH}"

# Claude Code (native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Optional extras: delete any you don't use.
# OpenAI Codex CLI, and pnpm
RUN npm install -g @openai/codex pnpm
# Google Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

WORKDIR /workspaces
