#!/usr/bin/env bash
# Usage: inventory-diff.sh OLD NEW
#
# Prints a Markdown table of entries added, removed or changed between two
# inventories produced by inventory.sh. Prints nothing if they're identical.
set -euo pipefail

awk '
  NR == FNR { old[$1] = $2; next }
            { new[$1] = $2 }
  END {
    for (k in old) keys[k]
    for (k in new) keys[k]
    n = 0
    for (k in keys) {
      # Test membership before reading: reading old[k] would create the key
      in_old = (k in old); in_new = (k in new)
      if (in_old && in_new && old[k] == new[k]) continue
      a = in_old ? old[k] : "—"
      b = in_new ? new[k] : "—"
      # Long hashes are noise in a table; 12 chars is plenty to compare
      if (length(a) >= 40) a = substr(a, 1, 12)
      if (length(b) >= 40) b = substr(b, 1, 12)
      rows[++n] = sprintf("| `%s` | %s | %s |", k, a, b)
    }
    if (n == 0) exit
    print "| | Before | After |"
    print "|---|---|---|"
    # Sort for stable output
    cmd = "LC_ALL=C sort"
    for (i = 1; i <= n; i++) print rows[i] | cmd
    close(cmd)
  }
' "$1" "$2"
