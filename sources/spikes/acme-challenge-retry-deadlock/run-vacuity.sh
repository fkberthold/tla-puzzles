#!/usr/bin/env bash
# run-vacuity.sh — the harness's own vacuity component (V2-PLAN.md 5.3) over
# this spike's two headline models.
#
# The hand-written probes in run-probes.sh and this are not substitutes.
# run-probes.sh asserts named reachability facts a human chose. This runs the
# five vectors the harness knows about, including the two no hand-written
# probe catches: the dead-action predicate `total == 0`, and the DELETED
# action, which has no coverage row at all and is therefore invisible to any
# predicate over the rows that are present -- hence --expect-actions.
#
# The module is passed as an absolute path under the worktree, which is what
# harness/vacuity.sh:94 wants, and it is built from ${BASH_SOURCE[0]} rather
# than from a literal.
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../.." && pwd)"

run_one() {
  local module="$1" config="$2" minstates="$3" actions="$4" label="$5"
  printf '=== %s\n' "$label"
  bash "$ROOT/harness/vacuity.sh" \
    --config "$HERE/$config" \
    --min-states "$minstates" \
    --expect-actions "$actions" \
    --observe Obs \
    "$HERE/$module.tla"
  printf 'rc=%s\n\n' "$?"
}

# The prose-faithful model, fully explored. MCCleared.cfg rather than
# Challenge.cfg: a config that exits 12 stops at the first counterexample, so
# its coverage block is a fact about the search and not about the spec.
run_one Challenge MCCleared.cfg 10 \
  'Respond,SuccessfulQuery,FailedQuery,GiveUp,ClientRequestsRetry' \
  'prose-faithful model, five actions expected'

# The wedged model. Four actions: there is no GiveUp, because the collapse is
# what wedged it.
run_one Wedged Wedged.cfg 4 \
  'Respond,SuccessfulQuery,FailedQueryForcesInvalid,ClientRequestsRetry' \
  'wedged model, four actions expected'

# NEGATIVE CONTROL. Name an action the wedged model does not have. The probe
# must report it dead; a run that comes back clean here is not checking
# anything. GiveUp is the right name to use, because its ABSENCE is the whole
# difference between the two models above.
printf '=== negative control: an action that is not there\n'
bash "$ROOT/harness/vacuity.sh" \
  --config "$HERE/Wedged.cfg" \
  --min-states 4 \
  --expect-actions 'Respond,SuccessfulQuery,FailedQueryForcesInvalid,ClientRequestsRetry,GiveUp' \
  "$HERE/Wedged.tla"
printf 'rc=%s\n' "$?"
