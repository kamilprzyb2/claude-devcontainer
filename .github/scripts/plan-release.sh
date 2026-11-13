#!/usr/bin/env bash
# Usage: plan-release.sh INVENTORY
#
# Decides whether INVENTORY (from inventory.sh) is a new release, and under
# which version. VERSION holds MAJOR.MINOR; CI owns the patch number.
#
#   no vMAJOR.MINOR.* tag yet          -> MAJOR.MINOR.0 (a manual bump always ships)
#   latest tag's inventory differs     -> next patch
#   latest tag's inventory is the same -> nothing to release
#
# Writes changed, version and previous to $GITHUB_OUTPUT and a summary with the
# diff to $GITHUB_STEP_SUMMARY. Needs GH_TOKEN for `gh release download`.
set -euo pipefail

inventory=$1
here=$(dirname "$0")

base=$(tr -d '[:space:]' < VERSION)
if ! [[ $base =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "::error file=VERSION::VERSION must be MAJOR.MINOR (CI assigns the patch), got '$base'"
  exit 1
fi

# Highest existing release tag, overall and within this MAJOR.MINOR
tags=$(git ls-remote --tags --refs origin 'v*' | sed 's#.*refs/tags/##' \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V || true)
latest_in_base=$(grep -E "^v${base//./\\.}\.[0-9]+$" <<<"$tags" | tail -1 || true)
previous=${latest_in_base:-$(tail -1 <<<"$tags")}

# Inventory of the previous release, for the comparison and the notes
have_previous=false
if [[ -n $previous ]] && gh release download "$previous" -p inventory.txt -O previous-inventory.txt --clobber 2>/dev/null; then
  have_previous=true
fi

if [[ -z $latest_in_base ]]; then
  changed=true
  version="$base.0"
  reason="first release of $base"
elif ! $have_previous; then
  # Release exists but its inventory is missing: safer to ship than to skip forever
  changed=true
  version="$base.$(( ${latest_in_base##*.} + 1 ))"
  reason="no inventory attached to $previous"
elif cmp -s previous-inventory.txt "$inventory"; then
  changed=false
  version=${latest_in_base#v}
  reason="identical to $previous"
else
  changed=true
  version="$base.$(( ${latest_in_base##*.} + 1 ))"
  reason="contents changed since $previous"
fi

echo "$version: $reason (changed=$changed)"
{
  echo "changed=$changed"
  echo "version=$version"
  echo "previous=$previous"
} >> "${GITHUB_OUTPUT:-/dev/null}"

{
  if $changed; then
    echo "### Would release $version"
  else
    echo "### No release"
  fi
  echo
  echo "${reason^}."
  if $have_previous && $changed; then
    echo
    "$here/inventory-diff.sh" previous-inventory.txt "$inventory"
  fi
} >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
