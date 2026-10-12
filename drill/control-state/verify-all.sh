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
# removed on exit. One config per module, named after it, which is also the
# pairing harness/drill-gate.sh expects.
set -u

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
filter=${1:-}
fail=0

run() {
  local name=$1 dir=$2 mod=$3 want=$4
  case $name in
    "$filter"*) ;;
    *) return ;;
  esac
  local log="$scratch/$name.log"
  ( cd "$root/$dir" && tlc -workers 1 -noGenerateSpecTE \
        -metadir "$scratch/$name" -config "${mod%.tla}.cfg" "$mod" ) > "$log" 2>&1
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
  printf '%-16s want %-3s got %-3s distinct %-5s %s\n' \
    "$name" "$want" "$rc" "${distinct:-?}" "$mark"
}

# name             directory                        module            rc
run 01-TwoStep     01-slip-on-the-spike/verify      TwoStep.tla       12
run 01-Atomic      01-slip-on-the-spike/verify      Atomic.tla        0
run 02-Switches    02-pumps/verify                  Switches.tla      0
run 02-Phases      02-pumps/verify                  Phases.tla        0
run 02-DryMotor    02-pumps/verify                  DryMotor.tla      12
run 03-DayBare     03-two-tools/verify              DayBare.tla       11
run 03-Agreed      03-two-tools/verify              Agreed.tla        0
run 03-DayNoDL     03-two-tools/verify              DayNoDL.tla       0
run 03-RookieBare  03-two-tools/verify              RookieBare.tla    11
run 03-NewHire     03-two-tools/verify              NewHire.tla       11
run 03-RookieNoDL  03-two-tools/verify              RookieNoDL.tla    0
run 03-RookieLive  03-two-tools/verify              RookieLive.tla    13
run 04-Patrol      04-night-patrol/verify           Patrol.tla        0
run 04-SlipTuple   04-night-patrol/verify           SlipTuple.tla     13
run 05-Crane       05-crane-and-riggers/verify      Crane.tla         0
run 05-OnePc       05-crane-and-riggers/verify      OnePc.tla         0
run 05-SitePhase   05-crane-and-riggers/verify      SitePhase.tla     0
run 05-Unguarded   05-crane-and-riggers/verify      Unguarded.tla     12
run 06-Reboot      06-three-reds/verify             Reboot.tla        0
run 06-EndsNoDL    06-three-reds/verify             EndsNoDL.tla      0
run 06-EndsBare    06-three-reds/verify             EndsBare.tla      11
run 06-OffByOne    06-three-reds/verify             OffByOne.tla      12
run 07-Donors      07-donor-session/verify          Donors.tla        0
run 07-RushDesk    07-donor-session/verify          RushDesk.tla      12
run 08-CarWash     08-wrong-label/verify            CarWash.tla       0
run 08-WrongLabel  08-wrong-label/verify            WrongLabel.tla    12
run 08-NoGuard     08-wrong-label/verify            NoGuard.tla       12
run 08-Rebuilt     08-wrong-label/verify            Rebuilt.tla       12
run 08-BayFree     08-wrong-label/verify            BayFree.tla       12

exit "$fail"
