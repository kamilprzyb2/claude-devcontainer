#!/usr/bin/env bash
# Usage: inventory.sh IMAGE
#
# Prints a sorted "key value" list of what IMAGE contains. Two images with the
# same inventory count as the same release, whatever their digests say (builds
# aren't reproducible, so digests always differ). Run from the repo root.
set -euo pipefail

image=$1

{
  # Catches Dockerfile/devcontainer.json edits that don't change any package
  # (ENV, metadata label, extensions, mounts).
  echo "config $(cat .devcontainer/Dockerfile .devcontainer/devcontainer.json | sha256sum | cut -d' ' -f1)"

  docker run --rm -i --entrypoint bash "$image" -s <<'EOF'
set -euo pipefail
echo "node $(node --version)"
echo "npm $(npm --version)"
command -v yarn     >/dev/null && echo "yarn $(yarn --version)"
command -v corepack >/dev/null && echo "corepack $(corepack --version)"

# Global npm installs (Claude Code)
npm ls -g --depth=0 --json \
  | jq -r '.dependencies // {} | to_entries[] | "npm:\(.key) \(.value.version)"'

# Fetched from git at build time by zsh-in-docker
echo "git:oh-my-zsh $(git -C ~/.oh-my-zsh rev-parse HEAD)"
echo "git:powerlevel10k $(git -C ~/.oh-my-zsh/custom/themes/powerlevel10k rev-parse HEAD)"

dpkg-query -W -f='deb:${Package} ${Version}\n'
EOF
} | LC_ALL=C sort
