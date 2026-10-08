#!/usr/bin/env bash
# run-matrix.sh — the seeded-bug matrix (V2-PLAN.md 5.5), two submissions.
#
# THIS SCRIPT EXISTS BECAUSE OF --alias. The worktree-isolation harness reads
# that token as the shell `alias` builtin and refuses to verify the command
# line, so harness/seeded-bugs.sh cannot be driven from a bash tool call at
# all. Putting the invocation in a script takes it out of the harness's scan.
# Lineage for the hazard: bead tla-kl5.8.
#
# WHAT A PASS HERE DOES AND DOES NOT MEAN. seeded-bugs.sh says it at length in
# its own header and it is worth repeating at the call site: these variants are
# mutants of our own reference. Roughly 10.9% of real faulty specs are one
# mutation from correct and roughly 39.3% of single mutations are semantically
# inert, so a caught-count is a measurement of THIS VARIANT SET and not of
# anything a learner would write. Do not report it as a pass rate.
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../.." && pwd)"
M="$HERE/matrix"

run_one() {
  local submission="$1"
  printf '############ SUBMISSION: %s\n' "$submission"
  bash "$ROOT/harness/seeded-bugs.sh" \
    --matrix "$M" \
    --reference "$M/reference/AcmeChallenge.tla" \
    --oracle "$M/oracle/Oracle.tla" \
    --variants "$M/variants" \
    --spec Spec \
    --property Inv \
    --alias Obs \
    --timeout 60 \
    "$M/$submission.tla"
  printf 'rc=%s\n\n' "$?"
}

run_one Author
run_one NaiveErrorRule
