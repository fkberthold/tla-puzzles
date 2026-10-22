#!/usr/bin/env bash
# Run every snippet in this directory and check it produced the exit code the
# language reference claims it produces. A snippet whose rc drifts is a
# reference page that has started lying.
#
#   ./run-all.sh          run everything
#   ./run-all.sh -v       print full TLC output for failures
#
# Same shape as chapter/snippets/run-all.sh, and deliberately a separate copy.
# That file's CASES list carries the refinement chapter's claims and this one
# carries the language reference's. A shared runner would make one tree's
# failure read as the other's.
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

# THE FIFTH FIELD IS THE STATE COUNT, and it is not decoration.
#
# The page quotes a distinct-state count in three places, and in two of them
# the count IS the finding: 16 states against 4 is the whole difference
# between two tanks and one tank under two names. An rc check cannot see that.
# Both runs exit 0, so a change that collapsed the pair into one variable
# would leave this suite green and the page wrong. Leave the field empty where
# the page quotes no count.
#
# module  cfg  expected-rc  distinct-states  what it shows
CASES=(
  "Tank.tla|Tank.cfg|0|4|the imported module on its own"
  "TwoTanks.tla|TwoTanks.cfg|150||forgetting to substitute for a variable"
  "TwoTanksOk.tla|TwoTanksOk.cfg|0|16|both substitutions supplied: two tanks"
  "NameInner.tla|NameInner.cfg|150||a module variable cannot be named from outside"
  "OneTank.tla|OneTank.cfg|0|4|two instances on one variable: one tank"
  "TankPlusClock.tla|TankPlusClock.cfg|0|8|a bare INSTANCE matches parameters by name"
  "NoArith.tla|NoArith.cfg|150||EXTENDS Sequences does not bring arithmetic"
  "TwoExtends.tla|TwoExtends.cfg|150||one EXTENDS line per module"
  "Split.tla|Split.cfg|0|9|substitution is on the parse tree"
  "Split.tla|SplitText.cfg|13||and the text-macro reading is a different formula"
)

pass=0
fail=0
for case in "${CASES[@]}"; do
  IFS='|' read -r mod cfg want states what <<< "$case"
  out=$(tlc -workers 1 -config "$cfg" "$mod" 2>&1)
  got=$?
  rm -f ./*_TTrace_*.tla ./*_TTrace_*.bin 2>/dev/null
  if [ "$got" != "$want" ]; then
    printf 'FAIL  rc=%-3s (want %s) %-20s %-20s %s\n' "$got" "$want" "$mod" "$cfg" "$what"
    [ "$verbose" = 1 ] && echo "$out"
    fail=$((fail + 1))
    continue
  fi
  # An empty states field means the page quotes no count for this case, so
  # there is nothing to check beyond the exit code.
  if [ -n "$states" ]; then
    if ! grep -qE "(^|, )$states distinct states found" <<<"$out"; then
      printf 'FAIL  rc=%-3s states!=%-4s %-20s %-20s %s\n' "$got" "$states" "$mod" "$cfg" "$what"
      grep -E 'distinct states found' <<<"$out"
      [ "$verbose" = 1 ] && echo "$out"
      fail=$((fail + 1))
      continue
    fi
  fi
  printf 'ok    rc=%-3s %-6s %-20s %-20s %s\n' "$got" "${states:+$states st}" "$mod" "$cfg" "$what"
  pass=$((pass + 1))
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
