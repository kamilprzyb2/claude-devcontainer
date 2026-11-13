# claude-devcontainer

Prebuilt devcontainer base image for Claude Code — build once, reference from every project.

Published to GHCR as `ghcr.io/kamilprzyb2/claude-dev`.

## Usage

Add a `.devcontainer/devcontainer.json` to your project:

```jsonc
{
  "name": "my-project",
  "image": "ghcr.io/kamilprzyb2/claude-dev:2"
}
```

That's the whole file. Extensions, terminal profile, persistent volumes and
environment come from the image's `devcontainer.metadata` label.

Add per-project toolchains as features:

```jsonc
{
  "name": "my-csharp-thing",
  "image": "ghcr.io/kamilprzyb2/claude-dev:2",
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

Built on `node:26` (Debian trixie). Runs as the non-root `node` user; global npm installs work
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

Tags follow `VERSION`. Publishing `2.1.0` produces:

```
ghcr.io/kamilprzyb2/claude-dev:2        # follows all 2.x
ghcr.io/kamilprzyb2/claude-dev:2.1      # follows 2.1.x
ghcr.io/kamilprzyb2/claude-dev:2.1.0
ghcr.io/kamilprzyb2/claude-dev:latest
```

Pin to `:2`. You get updates and stop at a breaking change.

Only the current major is rebuilt. Once `2.0.0` shipped, `:1` stopped receiving
weekly refreshes; it still pulls, but its packages and Claude Code age from there.

**2.0.0** moved the base from `node:24` (Debian bookworm) to `node:26`
(Debian trixie). Every apt package jumps a Debian release, hence the major bump.

## Weekly rebuilds

CI rebuilds and republishes every **Monday 05:00 UTC** with the layer cache
disabled. Nothing in the repo changes — the same commit produces a new image.

This is deliberate. The Dockerfile floats on moving targets: `apt-get install`
takes whatever Debian currently ships, and Claude Code installs at `@latest`.
Without a cache-busting rebuild, a project pinned to `:2` would sit on
months-old packages indefinitely.

**Tags are mutable.** `:1.0.0` pulled in January and `:1.0.0` pulled in June
are not the same image. For a genuinely frozen reference, pull by digest:

```bash
docker pull ghcr.io/kamilprzyb2/claude-dev@sha256:...
```

A cleanup job prunes untagged images weekly, keeping the 10 most recent for
rollback. Each image is counted whole (its amd64 and arm64 manifests with it), and
manifests that a tagged image still references are never deleted.
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

- `node:20` → `node:26` (20 reached EOL in April 2026; 26 is the current LTS)
- Firewall script removed, along with its packages and `NET_ADMIN` capability
- git-delta installed from Debian (packaged since trixie) instead of a pinned
  GitHub release `.deb`
- `TZ` moved from a build arg to per-project `containerEnv`, since build args
  don't reach consumers of a prebuilt image
- Workspace left at the Dev Containers default (`/workspaces/<name>`) rather
  than `/workspace`
- JS-specific extensions and formatter settings moved to per-project config

Kept close enough to rebase onto upstream changes by eye.
