ARG NODE_VERSION=26
FROM node:${NODE_VERSION}

ARG CLAUDE_CODE_VERSION=latest

# Link the GHCR package to this repo
LABEL org.opencontainers.image.source=https://github.com/kamilprzyb2/claude-devcontainer

# Basic development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  git-delta \
  jq \
  nano \
  vim \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist shell history across rebuilds
RUN mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# UTF-8 for every process, not just zsh. C.UTF-8 is built into glibc, so it
# needs no locales package. Projects that install one can override LANG.
ENV LANG=C.UTF-8

# Create Claude config directory and set permissions
RUN mkdir -p /home/node/.claude && \
  chown -R node:node /home/node/.claude

# Set up non-root user
USER node

# Global npm installs without sudo
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerlevel10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.1
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# zsh-in-docker's .zshrc exports LANG, LANGUAGE and LC_ALL as en_US.UTF-8, but
# -x skips the locales package that would generate it, leaving zsh on the plain
# C locale (non-ASCII input breaks). Drop them and use LANG from above.
RUN sed -i -E '/^export (LANG|LANGUAGE|LC_ALL)=/d' ~/.zshrc

# Install Claude
RUN npm install -g --allow-scripts=@anthropic-ai/claude-code @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
