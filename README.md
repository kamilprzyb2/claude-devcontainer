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

`VERSION` holds `MAJOR.MINOR`; CI assigns the patch number. Releasing `2.1.3`
produces:

```
ghcr.io/kamilprzyb2/claude-dev:2        # follows all 2.x
ghcr.io/kamilprzyb2/claude-dev:2.1      # follows 2.1.x
ghcr.io/kamilprzyb2/claude-dev:2.1.3    # never changes
ghcr.io/kamilprzyb2/claude-dev:latest
```

Pin to `:2`. You get updates and stop at a breaking change. Pin to an exact
version like `:2.1.3` to freeze, or to roll back to an earlier image.

- **Patch**: automatic, whenever the image contents change (see below)
- **Minor**: bumped by hand for changes to the image's structure or tooling
- **Major**: bumped by hand for breaking changes, such as a new Node or Debian release

Each release is a [GitHub Release](https://github.com/kamilprzyb2/claude-devcontainer/releases)
listing what changed since the previous one, with the full contents attached as
`inventory.txt`.

Only the current major is rebuilt. Once `2.0.0` shipped, `:1` stopped receiving
updates; it still pulls, but its packages and Claude Code age from there.
`1.0.0` and `2.0.0` predate automatic releases, so they have no GitHub Release.

**2.0.0** moved the base from `node:24` (Debian bookworm) to `node:26`
(Debian trixie). Every apt package jumps a Debian release, hence the major bump.

## Weekly rebuilds

The Dockerfile floats on moving targets: `apt-get install` takes whatever Debian
currently ships, Claude Code installs at `@latest`, and oh-my-zsh and
powerlevel10k are cloned from their default branches. Without rebuilds, a
project pinned to `:2` would sit on months-old packages indefinitely.

So CI rebuilds every **Monday 05:00 UTC**, and on every push to `main`, without
layer cache, and lists what the image contains: Node and npm versions, global npm
packages, every Debian package with its version, the oh-my-zsh and powerlevel10k
commits, and a hash of `.devcontainer/`.

- **Same list as the latest release**: nothing is published.
- **Anything differs**: CI publishes the next patch version and creates its
  GitHub Release.

Image digests can't be compared directly: builds aren't reproducible, so two
builds from identical inputs never share a digest.

A cleanup job deletes untagged images weekly. Every release keeps its exact
version tag, so untagged images are only leftovers such as interrupted pushes.
The amd64 and arm64 images inside a tagged multi-arch image are never deleted.
A failed rebuild changes nothing — the previous image stays live.

## Releasing

Day to day there's nothing to do: package updates release themselves.

For a change to the image:

1. Edit `.devcontainer/Dockerfile` or `devcontainer.json`
2. For a structural or breaking change, bump `VERSION` (`2.1` → `2.2`, or `3.0`).
   Otherwise leave it, and the change ships as the next patch.
3. Merge to `main`

Pull requests build and smoke-test the amd64 image but don't publish. The run's
summary shows what merging would release and which packages changed. Merges
build for amd64 and arm64.

A new `VERSION` always publishes `MAJOR.MINOR.0`, even if the contents match the
previous release.

## Based on

Adapted from
[anthropics/claude-code/.devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer).
Differences:

- `node:20` → `node:26` (20 reached EOL in April 2026; 26 is the current LTS)
- Firewall script removed, along with its packages and `NET_ADMIN` capability
- Locale set to `C.UTF-8`; upstream's `.zshrc` exports `en_US.UTF-8`, which is
  never generated, so zsh falls back to the plain C locale
- git-delta installed from Debian (packaged since trixie) instead of a pinned
  GitHub release `.deb`
- `TZ` moved from a build arg to per-project `containerEnv`, since build args
  don't reach consumers of a prebuilt image
- Workspace left at the Dev Containers default (`/workspaces/<name>`) rather
  than `/workspace`
- JS-specific extensions and formatter settings moved to per-project config

Kept close enough to rebase onto upstream changes by eye.
