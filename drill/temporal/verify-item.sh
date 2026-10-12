#!/usr/bin/env bash
# Run every .cfg in an item's verify/ directory through the harness verdict
# channel and print one line per run: stem, raw TLC exit code, verdict token,
# distinct states.
#
# Usage: bash drill/temporal/verify-item.sh drill/temporal/<NN>-<slug> [SCRATCH]
#
# A cfg with a module of the same stem beside it runs that module, which is
# the pairing harness/drill-gate.sh uses. A cfg with no such module is one of
# the deadlock runs gen-cfgs.sh writes without a wrapper: it runs against the
# module named on its "\* MODULE:" line, or in verify/MODULE, with the -d
# flag the keyword needs. The exit code is TLC's own, taken from
# harness/verdict.sh, which reads nothing from TLC's console. The
# distinct-state count is read from the log, which is why it sits in a
# separate column from the verdict.
set -u

item="${1:?item directory}"
scratch="${2:-${TMPDIR:-/tmp}/drill-verify-$$}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
verdict="$here/harness/verdict.sh"
vdir="$item/verify"
default_module="$(cat "$vdir/MODULE")"
mkdir -p "$scratch"

printf '%-26s %4s  %-22s %s\n' stem rc token distinct
for cfg in "$vdir"/*.cfg; do
  stem="$(basename "$cfg" .cfg)"
  log="$scratch/$stem.log"
  rc=0
  mod="$stem"
  flags=()
  if [ ! -f "$vdir/$stem.tla" ]; then
    mod="$default_module"
    override="$(grep -oE '^\\\* MODULE: [A-Za-z0-9_]+' "$cfg" | tail -1)"
    if [ -n "$override" ]; then mod="${override##* }"; fi
    if grep -q '^CHECK_DEADLOCK TRUE' "$cfg"; then flags=(-d); fi
  fi
  token="$("$verdict" "${flags[@]}" -c "$cfg" -t 120 --scratch "$scratch/$stem" --log "$log" "$vdir/$mod.tla")" || rc=$?
  distinct="$(grep -oE '[0-9]+ distinct states' "$log" | tail -1 | cut -d' ' -f1)"
  printf '%-26s %4s  %-22s %s\n' "$stem" "$rc" "$token" "${distinct:--}"
done
