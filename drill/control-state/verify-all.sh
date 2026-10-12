#!/usr/bin/env bash
# Re-measure every TLC run cited in drill/control-state/*/ANSWER.md.
#
# One line per run: name, the rc the answer claims, the rc measured now, and
# the distinct-state count TLC printed. Exits 1 if any measured rc differs
# from the claimed one, so the answers cannot drift from the specs quietly.
#
# usage: bash drill/control-state/verify-all.sh [NAME-PREFIX]
#   NAME-PREFIX limits the runs to those whose name starts with it, e.g. 03.
#
# Flags match harness/verdict.sh: one worker so traces are reproducible, no
# TTrace spillage, and TLC's states/ tree in a scratch directory that is
# removed on exit.
set -u

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
filter=${1:-}
fail=0

run() {
  local name=$1 dir=$2 mod=$3 cfg=$4 want=$5
  case $name in
    "$filter"*) ;;
    *) return ;;
  esac
  local log="$scratch/$name.log"
  ( cd "$root/$dir" && tlc -workers 1 -noGenerateSpecTE \
        -metadir "$scratch/$name" -config "$cfg" "$mod" ) > "$log" 2>&1
  local rc=$?
  local distinct
  # The count appears on the final summary line. Liveness runs print it on a
  # progress line too, with the same number, so the last match is the one.
  distinct=$(sed -n 's/.* \([0-9][0-9]*\) distinct states found.*/\1/p' "$log" | tail -n 1)
  local mark=ok
  if [ "$rc" != "$want" ]; then
    mark=MISMATCH
    fail=1
  fi
  printf '%-20s want %-3s got %-3s distinct %-5s %s\n' \
    "$name" "$want" "$rc" "${distinct:-?}" "$mark"
}

# name                 directory                        module              config               rc
run 01-TwoStep         01-slip-on-the-spike/verify      TwoStep.tla         TwoStep.cfg          12
run 01-Atomic          01-slip-on-the-spike/verify      Atomic.tla          Atomic.cfg           0
run 02-Switches        02-pumps/verify                  Switches.tla        Switches.cfg         0
run 02-Phases          02-pumps/verify                  Phases.tla          Phases.cfg           0
run 03-Agreed-Bare     03-two-tools/verify              Agreed.tla          Agreed-Bare.cfg      11
run 03-Agreed-Term     03-two-tools/verify              Agreed.tla          Agreed-Term.cfg      0
run 03-Agreed-NoDL     03-two-tools/verify              Agreed.tla          Agreed-NoDL.cfg      0
run 03-NewHire-Bare    03-two-tools/verify              NewHire.tla         NewHire-Bare.cfg     11
run 03-NewHire-Term    03-two-tools/verify              NewHire.tla         NewHire-Term.cfg     11
run 03-NewHire-NoDL    03-two-tools/verify              NewHire.tla         NewHire-NoDL.cfg     0
run 03-NewHire-Live    03-two-tools/verify              NewHire.tla         NewHire-Live.cfg     13
run 04-Patrol          04-night-patrol/verify           Patrol.tla          Patrol.cfg           0
run 04-PatrolSlip      04-night-patrol/verify           PatrolSlip.tla      PatrolSlip.cfg       13
run 05-Crane           05-crane-and-riggers/verify      Crane.tla           Crane.cfg            0
run 05-CraneOnePc      05-crane-and-riggers/verify      CraneOnePc.tla      CraneOnePc.cfg       0
run 05-CraneLazy       05-crane-and-riggers/verify      CraneLazy.tla       CraneLazy.cfg        0
run 05-CraneUnguarded  05-crane-and-riggers/verify      CraneUnguarded.tla  CraneUnguarded.cfg   12
run 06-Reboot          06-three-reds/verify             Reboot.tla          Reboot.cfg           0
run 06-Reboot-NoDL     06-three-reds/verify             Reboot.tla          Reboot-NoDL.cfg      0
run 06-Reboot-Bare     06-three-reds/verify             Reboot.tla          Reboot-Bare.cfg      11
run 06-RebootLate      06-three-reds/verify             RebootLate.tla      Reboot.cfg           12
run 07-Donors          07-donor-session/verify          Donors.tla          Donors.cfg           0
run 07-DonorsRush      07-donor-session/verify          DonorsRush.tla      Donors.cfg           12
run 08-CarWash         08-wrong-label/verify            CarWash.tla         CarWash.cfg          0
run 08-CarWashE        08-wrong-label/verify            CarWashE.tla        CarWash.cfg          12
run 08-CarWashA        08-wrong-label/verify            CarWashA.tla        CarWash.cfg          12
run 08-CarWashB        08-wrong-label/verify            CarWashB.tla        CarWash.cfg          12
run 08-CarWashC        08-wrong-label/verify            CarWashC.tla        CarWash.cfg          12

exit "$fail"
