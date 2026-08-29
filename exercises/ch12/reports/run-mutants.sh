#!/usr/bin/env bash
# Run every seeded ch12 mutant through harness/verdict.sh and print one row per
# mutant: id, module, verdict token, raw exit status.
#
# Usage:  bash exercises/ch12/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch12-mut`, matching the seeder's default.
#
# Chapter 12 is pure TLA+, so there is no `pcal` step here. ch11's runner had
# one because every ch11 reference was a PlusCal module with a translation to
# keep in step. Nothing in this chapter has a translation at all.
#
# EACH MODULE IS RUN WITH THE FLAGS ITS OWN EXERCISE PRINTS. GlazingBench is
# the only one that differs: exercise 3 asks for deadlock checking, because
# `Terminating` is the construct being exercised and `Terminating` does
# nothing at all unless somebody is looking for a deadlock. Running the
# mutants without `-d` would make the mutant that deletes `Terminating` look
# inert, which is true of the flags and false of the exercise.
#
# A mutant that does not parse is still a mutant, and a mutant whose spec fails
# to evaluate is still a mutant. PARSE_ERROR and SPEC_EVAL_FAILURE are both
# verdicts this table is measuring, so nothing is filtered out on the way in.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch12-mut}"

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  tla=$(ls "$d"*.tla)
  module=$(basename "$tla" .tla)
  flags=()
  if [ "$module" = "GlazingBench" ]; then
    flags=(-d)
  fi
  token=$(bash harness/verdict.sh "${flags[@]+"${flags[@]}"}" "$tla" -c "$d$module.cfg" 2>/dev/null)
  rc=$?
  printf '%-4s %-14s %-22s rc=%s\n' "$id" "$module" "$token" "$rc"
done
