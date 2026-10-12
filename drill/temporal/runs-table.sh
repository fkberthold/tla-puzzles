#!/usr/bin/env bash
# Print the "## Runs" table for an item's ANSWER.md from a verify-item.sh
# result file. One row per cfg: the module stem, what the cfg binds, and the
# measured rc written as "rc N", which is the form harness/drill-gate.sh
# reads back when it reproduces the number.
#
# Usage: bash drill/temporal/runs-table.sh drill/temporal/<NN>-<slug> RESULTS
set -eu
item="${1:?item directory}"
results="${2:?verify-item.sh output file}"
vdir="$item/verify"

printf '| module | spec | rows | checks | rc |\n'
printf '|---|---|---|---|---|\n'
while read -r stem rc _token _distinct; do
  case "$stem" in stem|'') continue ;; esac
  cfg="$vdir/$stem.cfg"
  spec="$(sed -n 's/^SPECIFICATION //p' "$cfg")"
  rows="$(sed -n 's/^CONSTANT Rows = //p' "$cfg" | tr -d '{}' | sed 's/,/, /g')"
  checks="$(grep -E '^(PROPERTY|INVARIANT|CHECK_DEADLOCK) ' "$cfg" | tr '\n' ' ' | sed 's/ $//')"
  printf '| `%s` | `%s` | %s | `%s` | rc %s |\n' "$stem" "$spec" "${rows:--}" "$checks" "$rc"
done < "$results"
