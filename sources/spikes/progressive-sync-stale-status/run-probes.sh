#!/usr/bin/env bash
# Run every vacuity probe and print its exit code.
#
# A verdict comes from the exit code, never from TLC's console text
# (V2-PLAN.md section 5.1).  Every probe below denies something the model had
# better be able to do, so the EXPECTED column is 12 throughout and a 0 is a
# finding about the model rather than a pass.
#
# Run from this directory:  bash run-probes.sh
#
# The probe invariant is injected with `tlc -inv`, which is why there are two
# .cfg files rather than sixteen: probe-broken.cfg and probe-fixed.cfg carry
# the constants and name no invariant of their own.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

probe() {
  local cfg="$1" inv="$2" expect="$3" rc
  set +e
  tlc -workers 1 -cleanup -noTE -config "$cfg" -inv "$inv" Probes \
      >"$TMPDIR_PROBE/$inv.$cfg.log" 2>&1
  rc=$?
  set -e
  local mark="OK"
  [ "$rc" = "$expect" ] || mark="UNEXPECTED"
  printf '%s\t%s\t%s\t%s\t%s\n' "$cfg" "$inv" "$expect" "$rc" "$mark"
}

TMPDIR_PROBE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_PROBE"' EXIT

printf 'config\tprobe\texpected_rc\trc\tresult\n'

# Against the broken system.
probe probe-broken.cfg NeverCommits            12
probe probe-broken.cfg NeverSyncs              12
probe probe-broken.cfg NeverAdvances           12
probe probe-broken.cfg NeverCompletes          12
probe probe-broken.cfg NeverStale              12
probe probe-broken.cfg NoMidCohortRefresh      12
probe probe-broken.cfg NeverAllConverged       12
probe probe-broken.cfg NeverObservedOutOfSync  12

# Against the fixed system, where rc=0 on the real obligations needs defending.
probe probe-fixed.cfg  NeverCommits            12
probe probe-fixed.cfg  NeverSyncs              12
probe probe-fixed.cfg  NeverAdvances           12
probe probe-fixed.cfg  NeverCompletes          12
probe probe-fixed.cfg  NeverStale              12
probe probe-fixed.cfg  NoMidCohortRefresh      12
probe probe-fixed.cfg  NeverAllConverged       12
probe probe-fixed.cfg  NeverObservedOutOfSync  12

# Negative controls.  Sixteen 12s is also what a channel stuck at 12 looks
# like, so these two are expected to exit 0 -- and StepPrefixConverged is the
# same text exiting 12 on the broken model and 0 on the fixed one.
probe probe-broken.cfg LiveNeverRunsAhead       0
probe probe-fixed.cfg  LiveNeverRunsAhead       0
probe probe-broken.cfg StepPrefixConverged     12
probe probe-fixed.cfg  StepPrefixConverged      0
