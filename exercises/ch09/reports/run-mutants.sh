#!/usr/bin/env bash
# Run every seeded ch09 mutant through harness/verdict.sh and print one row per
# mutant per config: id, module, config, verdict token, raw exit status, note.
#
# Usage:  bash exercises/ch09/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch09-mut`, matching the seeder's default.
#
# Every mutant is re-translated first. TLC checks the translation and not the
# algorithm comment, so an edit inside the PlusCal block does nothing until
# pcal has run again. That matters more here than in a safety chapter: a
# `fair` deleted in the comment but not re-translated leaves WF_vars standing
# in the translation, and the mutant reports the unmutated verdict.
#
# The config list comes from the seeder's cfgs.txt rather than from a glob,
# because pcal writes a default <module>.cfg into any directory that lacks
# one, and a glob would then run that empty config as though it were ours.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch09-mut}"

if [ ! -d "$MUT_DIR" ]; then
  echo "$0: no such mutant directory: $MUT_DIR (run reports/mutants.py first)" >&2
  exit 1
fi

printf '%-4s %-12s %-20s %-22s %-6s %s\n' \
  ID MODULE CONFIG VERDICT RC NOTE

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  tla=$(find "$d" -maxdepth 1 -name '*.tla' -print -quit)
  module=$(basename "$tla" .tla)
  note=$(cat "$d/note.txt")

  head=$(head -n 60 "$tla")
  if grep -q -- "--algorithm" <<<"$head"; then
    pcal "$tla" >/dev/null 2>&1
  fi

  while IFS= read -r cfg; do
    [ -n "$cfg" ] || continue
    token=$(bash harness/verdict.sh "$tla" -c "$d$cfg" 2>/dev/null)
    rc=$?
    printf '%-4s %-12s %-20s %-22s rc=%-3s %s\n' \
      "$id" "$module" "$cfg" "$token" "$rc" "$note"
  done < "$d/cfgs.txt"
done
