#!/usr/bin/env bash
# Run the vacuity probes and print the exit-code table.
#
#   bash sources/spikes/imap-move-partial-failure/run-probes.sh
#
# Most of these are claims I expect TLC to refute, so rc 12 is the good
# outcome and rc 0 is the finding. Two are the other way round and the table
# says which. Nothing here reads TLC's prose.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

# TLC writes its metadata into ./states, which would otherwise collect in a
# directory somebody has to commit. -metadir puts it in a temp tree that goes
# away with the script.
META="$(mktemp -d)"
trap 'rm -rf "$META"' EXIT

MSGS='m1, m2, m3'

probe() {
  local module="$1" inv="$2" want="$3" cfg rc
  cfg="probe-$inv.cfg"
  {
    printf 'CONSTANTS\n'
    printf '  Msg = {%s}\n' "$MSGS"
    printf '\n'
    printf 'SPECIFICATION Spec\n'
    printf 'INVARIANT %s\n' "$inv"
    printf 'CHECK_DEADLOCK FALSE\n'
  } > "$cfg"
  set +e
  tlc -workers 1 -cleanup -noGenerateSpecTE -metadir "$META" -config "$cfg" "$module" >/dev/null 2>&1
  rc=$?
  set -e
  printf '%s\t%s\t%s\t%s\n' "$module" "$inv" "$want" "$rc"
}

printf 'module\tprobe\twant\trc\n'

probe ProbeAtomic AllStayInSource        12
probe ProbeAtomic NothingReachesTarget   12
probe ProbeAtomic CommandNeverReplies    12
probe ProbeAtomic NeverRepliesNo         12
probe ProbeAtomic NoMixedOutcome         12
probe ProbeAtomic NoMeansNothingHappened 12
probe ProbeAtomic NoDeletedFlagEverSet   0

probe ProbeStoreFirst  ClauseOneIsNoStronger 12
probe ProbeDecomposed  ClauseOneIsNoStronger 0

# The forward implications, which I expect to hold. Between these two servers
# every shape loc[m] can take is reachable.
probe ProbeStoreFirst   ClauseOneImpliesNotBoth 0
probe ProbeStoreFirst   ClauseOneImpliesNotLost 0
probe ProbeExpungeFirst ClauseOneImpliesNotBoth 0
probe ProbeExpungeFirst ClauseOneImpliesNotLost 0
probe ProbeExpungeFirst NothingEverVanishes     12
