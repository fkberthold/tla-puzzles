#!/usr/bin/env bash
# Re-measure every verify/ module in drill/functions-records.
#
# One line per module that has a config of the same stem: item, module, the
# raw TLC exit code, the verdict token, and the distinct-state count. The rc
# comes from harness/verdict.sh, which reads nothing from TLC's console. The
# count is read from the log, which is why it sits in its own column and is
# never part of a verdict.
#
# -d is passed when the config asks for deadlock checking, which is the
# convention harness/drill-gate.sh uses, so a number printed here is the
# number the gate will reproduce.
#
# usage: bash drill/functions-records/verify-all.sh [-v] [PREFIX]
#   PREFIX limits the runs to those whose item/module starts with it: 03 for
#     one item, 03-ballast-tanks/BallastTwoStep for one module.
#   -v prints TLC's error block under every non-zero row, from its first Error
#      line to the end of the log, which is where the exact message and the
#      counterexample quoted in an ANSWER.md come from.
set -u

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$here/../.." && pwd)
verdict="$repo/harness/verdict.sh"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
verbose=0
if [ "${1:-}" = "-v" ]; then
  verbose=1
  shift
fi
filter=${1:-}

printf '%-22s %-30s %4s  %-22s %s\n' item module rc token distinct
for cfg in "$here"/[0-9][0-9]-*/verify/*.cfg; do
  vdir=$(dirname "$cfg")
  item=$(basename "$(dirname "$vdir")")
  stem=$(basename "$cfg" .cfg)
  case "$item/$stem" in
    "$filter"*) ;;
    *) continue ;;
  esac
  mod="$vdir/$stem.tla"
  [ -f "$mod" ] || continue
  flags=()
  if grep -qE '^[[:space:]]*CHECK_DEADLOCK[[:space:]]+TRUE' "$cfg"; then
    flags=(-d)
  fi
  log="$scratch/$item-$stem.log"
  rc=0
  token=$("$verdict" ${flags[@]+"${flags[@]}"} -c "$cfg" -t 120 \
            --scratch "$scratch/$item-$stem" --log "$log" "$mod") || rc=$?
  distinct=$(sed -n 's/.* \([0-9][0-9]*\) distinct states found.*/\1/p' "$log" | tail -n 1)
  printf '%-22s %-30s %4s  %-22s %s\n' "$item" "$stem" "$rc" "$token" "${distinct:--}"
  if [ "$verbose" = 1 ] && [ "$rc" != 0 ]; then
    sed -n '/^Error\|^\*\*\* Errors/,/^The coverage statistics/p' "$log" \
      | sed '/^The coverage statistics/d' | head -n 60 | sed 's/^/      /'
  fi
done
