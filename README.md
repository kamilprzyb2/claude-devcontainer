# claude-devcontainer

Prebuilt devcontainer base image for Claude Code — build once, reference from every project.

Published to GHCR as `ghcr.io/kamilprzyb2/claude-dev`.

## Usage

Add a `.devcontainer/devcontainer.json` to your project:

```jsonc
{
  "name": "my-project",
  "image": "ghcr.io/kamilprzyb2/claude-dev:1"
}
```

That's the whole file. Extensions, terminal profile, persistent volumes and
environment come from the image's `devcontainer.metadata` label.

Add per-project toolchains as features:

```jsonc
{
  "name": "my-csharp-thing",
  "image": "ghcr.io/kamilprzyb2/claude-dev:1",
  "features": {
    "ghcr.io/devcontainers/features/dotnet:2": { "version": "10.0" }
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-dotnettools.csdevkit"]
    }
  },
  "containerEnv": {
    "TZ": "${localEnv:TZ:Europe/Warsaw}"
  }
}
```

Anything in your own `devcontainer.json` overrides the image.

## What's in it

Built on `node:24`. Runs as the non-root `node` user; global npm installs work
without sudo.

- Claude Code CLI
- git, GitHub CLI, git-delta
- zsh with oh-my-zsh, fzf keybindings, persistent history
- jq, less, procps, man-db, nano, vim, unzip, gnupg2

Two named volumes, scoped per project via `${devcontainerId}`:
`/commandhistory` for shell history, `/home/node/.claude` for auth and sessions.

VS Code config carried in the image metadata:

- **`anthropic.claude-code`** extension, installed automatically
- zsh as the default integrated terminal, with bash available as a second profile

## What's deliberately not in it

Baked-in config can't be removed downstream, so anything a project might want
off stays out:

- **Egress firewall** — a feature, so it can be configured or skipped per project
- **Language toolchains** — .NET, Python, Go as features
- **Formatters and linters** — wrong defaults for a non-JS repo
- **Personal extensions** — use `dev.containers.defaultExtensions` locally

## Versioning

Tags follow `VERSION`. Publishing `1.2.0` produces:

```
ghcr.io/kamilprzyb2/claude-dev:1        # follows all 1.x
ghcr.io/kamilprzyb2/claude-dev:1.2      # follows 1.2.x
ghcr.io/kamilprzyb2/claude-dev:1.2.0
ghcr.io/kamilprzyb2/claude-dev:latest
```

Pin to `:1`. You get updates and stop at a breaking change.

## Weekly rebuilds

CI rebuilds and republishes every **Monday 05:00 UTC** with the layer cache
disabled. Nothing in the repo changes — the same commit produces a new image.

This is deliberate. The Dockerfile floats on moving targets: `apt-get install`
takes whatever Debian currently ships, and Claude Code installs at `@latest`.
Without a cache-busting rebuild, a project pinned to `:1` would sit on
months-old packages indefinitely.

**Tags are mutable.** `:1.0.0` pulled in January and `:1.0.0` pulled in June
are not the same image. For a genuinely frozen reference, pull by digest:

```bash
docker pull ghcr.io/kamilprzyb2/claude-dev@sha256:...
```

A cleanup job prunes untagged digests weekly, keeping the last 10 for rollback.
A failed rebuild changes nothing — the previous image stays live.

## Releasing

1. Edit `.devcontainer/Dockerfile` or `devcontainer.json`
2. Bump `VERSION`
3. Merge to `main`

CI builds for amd64 and arm64, smoke-tests, and publishes. Pull requests build
and test but don't publish. Pushing without bumping `VERSION` overwrites the
existing tags rather than creating new ones.

## Based on

Adapted from
[anthropics/claude-code/.devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer).
Differences:

- `node:20` → `node:24` (20 reached EOL in April 2026)
- Firewall script removed, along with its packages and `NET_ADMIN` capability
- `TZ` moved from a build arg to per-project `containerEnv`, since build args
  don't reach consumers of a prebuilt image
- Workspace left at the Dev Containers default (`/workspaces/<name>`) rather
  than `/workspace`
- JS-specific extensions and formatter settings moved to per-project config

Kept close enough to rebase onto upstream changes by eye.
