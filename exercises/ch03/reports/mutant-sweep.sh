#!/usr/bin/env bash
# mutant-sweep.sh -- reproduces the 22-mutant confirmation pass for the
# c-syntax ch.3 exercise set (bead tla-s7hw).
#
# For each row in this directory's authoring.md mutant table, this script:
#   1. takes the committed, translated reference module,
#   2. strips its translation block (everything from BEGIN TRANSLATION on),
#   3. applies the ONE documented edit to the PlusCal source,
#   4. retranslates with pcal,
#   5. runs the result through harness/verdict.sh,
# and prints one PASS/FAIL line per mutant. Exits nonzero if any mutant's
# verdict does not match the table.
#
# WHY STEP 2 IS NOT OPTIONAL: pcal leaves a file UNTOUCHED on translation
# failure -- it does not blank or delete an existing translation block. Three
# mutants in this table (Ex2M4, Ex3M5, Ex4M1) are supposed to break
# translation and land on CONFIG_ERROR. Mutating a copy that still carries
# its old, valid translation would leave that stale Spec in place after pcal
# refuses, and TLC would happily check the UNMUTATED module -- silently
# grading the wrong thing. Stripping first means a failed retranslation
# leaves no Spec at all, which is what CONFIG_ERROR actually measures.
#
# Usage: bash exercises/ch03/reports/mutant-sweep.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REFS="$REPO_ROOT/exercises/ch03/references"
VERDICT="$REPO_ROOT/harness/verdict.sh"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

FAIL_COUNT=0
TOTAL=0

# strip_source SRC DST -- copy SRC to DST with everything from the BEGIN
# TRANSLATION marker onward replaced by a bare "====", so a fresh pcal run
# is the only possible source of a Spec.
strip_source() {
  awk '
    /^\\\* BEGIN TRANSLATION/ { print "===="; exit }
    { print }
  ' "$1" > "$2"
}

# apply_edit FILE OLDFILE NEWFILE -- replace the exact one occurrence of
# OLDFILE's content with NEWFILE's content in FILE, in place. Fails loudly
# (nonzero exit, no write) if the count is not exactly 1, so a mutant can
# never silently apply to the wrong spot or apply twice.
apply_edit() {
  python3 - "$1" "$2" "$3" <<'PYEOF'
import sys
path, oldf, newf = sys.argv[1:4]
with open(path) as f:
    content = f.read()
with open(oldf) as f:
    old = f.read()
with open(newf) as f:
    new = f.read()
n = content.count(old)
if n != 1:
    sys.stderr.write("apply_edit: expected 1 occurrence, found %d\n" % n)
    sys.exit(1)
content = content.replace(old, new, 1)
with open(path, "w") as f:
    f.write(content)
PYEOF
}

# run_mutant ID BASE EXPECT_TOKEN EXPECT_RC -- OLD and NEW must already hold
# the mutation text (set by the caller just before this runs).
run_mutant() {
  local id="$1" base="$2" expect_token="$3" expect_rc="$4"
  local work="$SCRATCH/$id"
  mkdir -p "$work"
  local tla="$work/$base.tla"
  local cfg="$work/$base.cfg"

  strip_source "$REFS/$base.tla" "$tla"
  cp "$REFS/$base.cfg" "$cfg"

  printf '%s' "$OLD" > "$work/old.txt"
  printf '%s' "$NEW" > "$work/new.txt"

  TOTAL=$((TOTAL + 1))

  if ! apply_edit "$tla" "$work/old.txt" "$work/new.txt"; then
    echo "FAIL $id: edit did not apply cleanly (base $base)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  pcal -nocfg "$tla" > "$work/pcal.log" 2>&1
  # pcal's own exit status is not graded here -- a mutant that is SUPPOSED to
  # break translation is graded on verdict.sh's CONFIG_ERROR, same as every
  # other row. See the file header for why step 2 (strip first) makes that
  # grading trustworthy.

  local out rc
  out=$(bash "$VERDICT" -c "$cfg" "$tla")
  rc=$?

  if [ "$out" = "$expect_token" ] && [ "$rc" = "$expect_rc" ]; then
    echo "PASS $id: $out rc=$rc"
  else
    echo "FAIL $id: got $out rc=$rc, expected $expect_token rc=$expect_rc"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# ---------------------------------------------------------------- Ex1Dispenser

OLD='if (owed >= 5)'
NEW='if (owed > 5)'
run_mutant Ex1M1 Ex1Dispenser ASSERT_VIOLATION 14

OLD='while (owed > 0)'
NEW='while (owed > 1)'
run_mutant Ex1M2 Ex1Dispenser ASSERT_VIOLATION 14

OLD='owed := owed - value;'
NEW='owed := owed - 1;'
run_mutant Ex1M3 Ex1Dispenser ASSERT_VIOLATION 14

OLD='Give(pennies, 1);'
NEW='Give(pennies, 2);'
run_mutant Ex1M4 Ex1Dispenser ASSERT_VIOLATION 14

OLD='count := count + 1;'
NEW='count := count + 2;'
run_mutant Ex1M5 Ex1Dispenser ASSERT_VIOLATION 14

# -------------------------------------------------------------------- Ex2Fresh

OLD='setpoint := setpoint + 2;'
NEW='setpoint := setpoint + 3;'
run_mutant Ex2M1 Ex2Fresh ASSERT_VIOLATION 14

OLD='setpoint := setpoint - 1;'
NEW='setpoint := setpoint - 2;'
run_mutant Ex2M2 Ex2Fresh ASSERT_VIOLATION 14

OLD='setpoint = 68,'
NEW='setpoint = 70,'
run_mutant Ex2M3 Ex2Fresh ASSERT_VIOLATION 14

OLD='    Warmer:
      setpoint := setpoint + 2;
      bumps := bumps + 1;
    Cooler:
      setpoint := setpoint - 1;
      bumps := bumps + 1;
    Check:'
NEW='    Warmer:
      setpoint := setpoint + 2;
      bumps := bumps + 1;
      setpoint := setpoint - 1;
      bumps := bumps + 1;
    Check:'
run_mutant Ex2M4 Ex2Fresh CONFIG_ERROR 151

# -------------------------------------------------------------------- Ex3Retry

OLD='if (attempts < 3)'
NEW='if (attempts < 2)'
run_mutant Ex3M1 Ex3Retry ASSERT_VIOLATION 14

OLD='attempts := attempts + 1;'
NEW='attempts := attempts + 2;'
run_mutant Ex3M2 Ex3Retry ASSERT_VIOLATION 14

OLD='goto Dial;'
NEW='goto Report;'
run_mutant Ex3M3 Ex3Retry ASSERT_VIOLATION 14

OLD='linked := TRUE;'
NEW='linked := FALSE;'
run_mutant Ex3M4 Ex3Retry ASSERT_VIOLATION 14

OLD='      if (attempts < 3) {
        goto Dial;
      } else {'
NEW='      if (attempts < 3) {
        goto Dial;
        linked := FALSE;
      } else {'
run_mutant Ex3M5 Ex3Retry CONFIG_ERROR 151

# -------------------------------------------------------------------- Ex4Tanks

OLD='        tanks[1] := tanks[1] - amount ||
        tanks[2] := tanks[2] + amount;'
NEW='        tanks[1] := tanks[1] - amount;
        tanks[2] := tanks[2] + amount;'
run_mutant Ex4M1 Ex4Tanks CONFIG_ERROR 151

OLD='tanks[2] := tanks[2] + amount;'
NEW='tanks[2] := tanks[2] + 2;'
run_mutant Ex4M2 Ex4Tanks ASSERT_VIOLATION 14

OLD='with (amount = 3)'
NEW='with (amount = 4)'
run_mutant Ex4M3 Ex4Tanks ASSERT_VIOLATION 14

OLD='tanks = <<7, 0>>;'
NEW='tanks = <<7, 1>>;'
run_mutant Ex4M4 Ex4Tanks ASSERT_VIOLATION 14

# --------------------------------------------------------------- Ex5DeadLabel

OLD='temp \in 0..30,'
NEW='temp \in 0..50,'
run_mutant Ex5M1 Ex5DeadLabel ASSERT_VIOLATION 14

OLD='if (temp > 40)'
NEW='if (temp > 20)'
run_mutant Ex5M2 Ex5DeadLabel ASSERT_VIOLATION 14

OLD='if (temp > 40)'
NEW='if (temp > -1)'
run_mutant Ex5M3 Ex5DeadLabel ASSERT_VIOLATION 14

OLD='    Settle:
      skip;'
NEW='    Settle:
      assert FALSE;'
run_mutant Ex5M4 Ex5DeadLabel ASSERT_VIOLATION 14

# ------------------------------------------------------------------- summary

echo "----"
echo "$TOTAL mutants run, $((TOTAL - FAIL_COUNT)) passed, $FAIL_COUNT failed"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi
