#!/usr/bin/env bash
# Run every snippet in this directory and check it produced the exit code the
# chapter claims it produces.  A snippet whose rc drifts is a chapter that has
# started lying.
#
#   ./run-all.sh          run everything
#   ./run-all.sh -v       print full TLC output for failures
#
# Exit codes TLC uses here:
#   0    all checks passed
#   12   an invariant was violated
#   13   a temporal or action property was violated
#   150  parse or semantic error in the module
#   151  the .cfg named something the module does not define
cd "$(dirname "$0")" || exit 1

verbose=0
[ "$1" = "-v" ] && verbose=1

# module  cfg  expected-rc  what it shows
CASES=(
  "Almanac.tla|Almanac.cfg|0|abstract spec, and its two facts"
  "Till.tla|Till.cfg|0|abstract one-number shop"
  "TwoTills.tla|TwoTills.cfg|0|two tills implement one number"
  "TwoTills.tla|TwoTillsFrozen.cfg|0|THE HOLE: frozen mapping passes"
  "MissingSub.tla|MissingSub.cfg|150|forgetting to substitute for a variable"
  "Observatory.tla|Observatory.cfg|0|the refinement we mean"
  "Observatory.tla|ObservatoryIProp.cfg|0|the rung below: action inclusion only"
  "Observatory.tla|ObservatoryInherited.cfg|0|abstract facts, inherited"
  "Observatory.tla|ObservatoryTypo.cfg|0|THE TRAP: one character, mapping frozen"
  "Observatory.tla|ObservatoryProbe.cfg|12|probe on a live mapping (12 is the pass)"
  "Observatory.tla|ObservatoryTypoProbe.cfg|0|probe on the frozen mapping (0 is the fail)"
  "Observatory.tla|ObservatoryAlias.cfg|13|a real refinement failure, read through ALIAS"
  "Observatory.tla|ObservatoryCfgTrap.cfg|151|.cfg takes bare identifiers only"
  "Ledger.tla|Ledger.cfg|0|abstract spec that keeps everything"
  "Running.tla|Running.cfg|0|implementation that keeps a count and a total"
  "RunningH.tla|RunningH.cfg|0|history variable: mapping exists, nothing added"
  "RunningH.tla|RunningHAllOnes.cfg|0|a moving mapping that tracks nothing"
  "RunningH.tla|RunningHAllOnesProbe.cfg|12|and the probe is satisfied by it"
  "Oracle.tla|Oracle.cfg|0|abstract spec that decides early"
  "Late.tla|Late.cfg|13|no mapping over the concrete state can work"
  "LateProph.tla|LateProph.cfg|0|prophecy variable: mapping exists, nothing added"
  "LateProphMC.tla|LateProphMC.cfg|0|with fairness, done always eventually holds"
  "LateProphMC.tla|LateProphMCReach.cfg|12|and yet Init/Next reach the impossible prediction"
  "EnabledSubst.tla|EnabledSubst.cfg|0|substitution does not reach inside ENABLED"
  "Localize.tla|Localize.cfg|12|Inv!n names the conjunct that failed"
  "Localize.tla|LocalizeFat.cfg|12|and without it, TLC names the whole conjunction"
)

pass=0
fail=0
for case in "${CASES[@]}"; do
  IFS='|' read -r mod cfg want what <<< "$case"
  out=$(tlc -workers 1 -config "$cfg" "$mod" 2>&1)
  got=$?
  rm -f ./*_TTrace_*.tla ./*_TTrace_*.bin 2>/dev/null
  if [ "$got" = "$want" ]; then
    printf 'ok    rc=%-3s %-24s %-28s %s\n' "$got" "$mod" "$cfg" "$what"
    pass=$((pass + 1))
  else
    printf 'FAIL  rc=%-3s (want %s) %-24s %-28s %s\n' "$got" "$want" "$mod" "$cfg" "$what"
    [ "$verbose" = 1 ] && echo "$out"
    fail=$((fail + 1))
  fi
done

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
