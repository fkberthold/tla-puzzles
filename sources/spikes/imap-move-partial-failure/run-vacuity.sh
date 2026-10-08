#!/usr/bin/env bash
# Run harness/vacuity.sh over all four servers and print the verdict table.
#
#   bash sources/spikes/imap-move-partial-failure/run-vacuity.sh
#
# This is a script and not four command lines for two reasons. The isolation
# harness refuses a command line carrying the token `Alias`, which it reads as
# the shell builtin, the same refusal that bites `--alias` on
# harness/seeded-bugs.sh. And the frozen-observation probe needs the
# normalising record named, so there is no way to ask for vector 5 without
# writing that token.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
OBS="Alias"

# VERBOSE=1 drops -q, so the remediation text comes through. That text is how
# you find out WHICH field a frozen-observation verdict is about, and the
# verdict token alone does not say.
QUIET="-q"
[ "${VERBOSE:-0}" = "1" ] && QUIET=""

run() {
  local module="$1" actions="$2" shift_obs="$3" cfg="${4:-}" token rc
  local -a extra=()
  [ -n "$cfg" ] && extra=(-c "$HERE/$cfg")
  [ "$shift_obs" = "observe" ] && extra+=(--observe "$OBS")
  set +e
  token="$(bash "$ROOT/harness/vacuity.sh" $QUIET -n 4 \
    --expect-actions "$actions" "${extra[@]}" "$HERE/$module.tla" 2>&1)"
  rc=$?
  set -e
  printf '%s\t%s\t%s\trc=%s\n%s\n' "$module" "$shift_obs" "${cfg:-default}" "$rc" "$token"
}

DEC='CopyOne,StoreOne,ExpungeOne,LeaveOne,Reply,Abort'
EXP='RemoveOne,AppendOne,LeaveOne,Reply,Abort'
STO='StoreOne,CopyOne,ExpungeOne,LeaveOne,Reply,Abort'
ATO='MoveOne,LeaveOne,Reply,Abort'

printf 'module\tobserve\tconfig\trc\n'

# Each server's own config, which for the three broken ones names an invariant
# the server violates.
run MCAtomic3       "$ATO" plain
run MCDecomposed3   "$DEC" plain
run MCExpungeFirst3 "$EXP" plain
run MCStoreFirst3   "$STO" plain

# THE SAME THREE SERVERS UNDER A CLAUSE THEY SATISFY.
#
# A run that stops at a counterexample never finishes exploring, so the
# satisfiability and dead-action probes cannot run and vacuity.sh says so in
# its remediation while still returning NON_VACUOUS at rc 0. The four runs
# above hit that on every broken server. Pointing the probe at a clause the
# server holds lets the exploration complete, and only then does
# `total == 0` have a full coverage block to read.
run MCDecomposed3   "$DEC" plain clause3-lost.cfg
run MCExpungeFirst3 "$EXP" plain clause3-both.cfg
run MCStoreFirst3   "$STO" plain clause3-lost.cfg

# Vector 5, the frozen observation.
run MCAtomic3     "$ATO" observe
run MCStoreFirst3 "$STO" observe clause3-lost.cfg
