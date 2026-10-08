#!/usr/bin/env bash
# Drive harness/vacuity.sh over the two primary models.
#
# This exists as a script rather than a command in REPORT.md for the same
# reason the seeded-bug runner does: the worktree-isolation harness refused
# the direct `bash harness/vacuity.sh -c ... -n ... <module>` command line as
# "too complex to verify", and a scratch script is the documented workaround
# (.claude/rules/dispatched-agents.md, the --alias hazard).
#
# The repo root is resolved from BASH_SOURCE, never from a literal path --
# harness/gen-curriculum-map.sh used to hardcode one and wrote into the main
# checkout from a worktree (bead tla-1hf).
#
# Run:  bash run-vacuity.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"

run() {
  local module="$1" minstates="$2" rc
  set +e
  ( cd "$ROOT" && bash harness/vacuity.sh \
      -c "sources/spikes/progressive-sync-stale-status/$module.cfg" \
      -n "$minstates" \
      --expect-actions Commit,Advance,SyncApp,Refresh \
      "sources/spikes/progressive-sync-stale-status/$module.tla" )
  rc=$?
  set -e
  printf '\n==== %s : vacuity.sh rc=%s ====\n\n' "$module" "$rc"
}

run MCFixed3 20
run MCBroken3 15

# Watch the dead-action probe FAIL.  DeadSyncProbe.tla is the same system with
# SyncApp's guard changed to `target > MaxRev`, which is never true.  Expect
# rc=5 VACUOUS_DEAD_ACTION.  A dead-action probe that has never fired is not
# evidence that the live models' "every action fired" means anything.
run DeadSyncProbe 5
