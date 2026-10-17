#!/usr/bin/env bash
# test-recall-runner.sh: executable spec for recall/recall.sh (bead tla-wekw).
#
# WHAT IT PINS
#
#   Every row of harness/fixtures/recall/CASES.tsv is graded the way the row
#   says, and the code the runner exits with is the RAW code
#   harness/verdict.sh returned -- which part 2 proves by building an
#   equivalent scaffold itself and running the verdict channel over it, so the
#   number is corroborated rather than taken from the thing under test.
#
#   Any correct form passes. C001 and C002 are two different expressions for
#   one value and both score 0, which is the property that keeps a rep from
#   being a spelling test.
#
#   A wrong answer prints BOTH values. A value that is not a set prints and
#   then has its count skipped, and the runner says the count was skipped.
#
#   A parse error is its own report rather than a wrong answer, because
#   telling somebody their answer is wrong when nothing was graded is a false
#   statement about a check that did not run.
#
#   A scratch directory the runner cannot make is a hard error, never a run in
#   the working directory, and a run leaves nothing behind anywhere.
#
#   A wrong answer also gets the two explanation layers that are not values
#   (bead tla-1sh7.6): the construct's entry from the sheet, keyed on the
#   rep's field 3, and the miss table's row for the answer, keyed on the text
#   that was typed and matched with whitespace normalised. A wrong answer the
#   table has no row for gets the sheet entry and no hole where a row would
#   have gone, which is the path 90 of the 120 real reps take.
#
# ---------------------------------------------------------------------------
# WHY THE FIXTURE CARRIES RAW CODES AND NOT ONLY GRADES
#
# Field 5 of every CASES row is a measured exit code. Asserting the number
# rather than the word is what makes a renumbered TLC break the build instead
# of quietly relabeling itself, and it is the same choice
# harness/test-verdict.sh made for the same reason.
#
# ---------------------------------------------------------------------------
# WHY THE MUTANTS ARE HERE
#
# Most rows below are of the shape "the runner said what the fixture says",
# which is also what a suite driving a runner that silently stopped working
# would report if a comparison went slack. So part 5 copies the real runner,
# breaks ONE line of it, and requires the row that owns that line to go red.
# Four mutants:
#
#   an inferred code     the reported code stops being verdict.sh's
#   a parse called wrong rc 150 is reported as a wrong answer
#   a lost value block   the canonical value is never shown
#   a count claimed      the skipped-count note never prints
#
# A mutant that passes means the row above it is vacuous. The mutant runs
# against a MIRROR ROOT under the temp tree -- recall/ holding the mutant and
# harness/verdict.sh symlinked to the real one -- because the runner resolves
# its root from BASH_SOURCE, so a copy somewhere else would fail to find the
# verdict channel and die at exit 3 for the wrong reason. Nothing is written
# into the repo.
#
# Usage:  harness/test-recall-runner.sh
# Exit:   0 if every assertion holds, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

assert_eq() {
  if [ "$2" = "$3" ]; then
    ok "$1"
  else
    nope "$1"
    printf '          want: %s\n' "$2"
    printf '          got:  %s\n' "$3"
  fi
}

assert_ne() {
  if [ "$2" != "$3" ]; then
    ok "$1"
  else
    nope "$1 (both: $2)"
  fi
}

# A here-string, never `producer | grep -q`. Under pipefail an early-exiting
# consumer closes the pipe, the producer takes SIGPIPE, the pipeline reports
# 141, and inside an `if` that is merely falsy -- so a PRESENT pattern reports
# as ABSENT. harness/test-pipefail.sh is the gate, and this is the blessed form.
has() { grep -qE -- "$2" <<<"$1"; }

RUNNER="$REPO_ROOT/recall/recall.sh"
VERDICT="$REPO_ROOT/harness/verdict.sh"
FIXTURE="$REPO_ROOT/harness/fixtures/recall"
REPS="$FIXTURE/REPS.tsv"
CASES="$FIXTURE/CASES.tsv"
ENV_DIR="$FIXTURE/env"
# The two explanation layers get fixture files of their own, and the block
# lengths below are pinned against those rather than against the shipped
# ones. drill/SHEET.md is generated from the chapter cheat sheets, so a
# sentence added to a cheat sheet would otherwise turn a length row red for a
# reason that has nothing to do with the runner. The shipped files are
# reached instead by part 13, which runs one live rep through the defaults.
MISSES="$FIXTURE/MISSES.tsv"
SHEET="$FIXTURE/SHEET.md"

for required in "$RUNNER" "$VERDICT" "$REPS" "$CASES" "$ENV_DIR" "$MISSES" "$SHEET"; do
  if [ ! -e "$required" ]; then
    printf 'test-recall-runner.sh: missing %s\n' "$required" >&2
    exit 1
  fi
done

if ! command -v tlc >/dev/null 2>&1; then
  echo "test-recall-runner.sh: tlc is not on the path, so nothing was checked." >&2
  exit 1
fi

TMPROOT=$(mktemp -d -t tla_recall_runner.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

# run_runner <runner-path> <rep> <answer> -> stdout+stderr in RUN_OUT, code in RUN_RC
RUN_OUT=""
RUN_RC=0
run_runner() {
  local script="$1" rep="$2" answer="$3"
  RUN_RC=0
  RUN_OUT=$("$script" --reps "$REPS" --env-dir "$ENV_DIR" \
    --misses "$MISSES" --sheet "$SHEET" -- "$rep" "$answer" 2>&1) || RUN_RC=$?
}

# Rows, read with awk -F'\t'. Never `IFS=$'\t' read`: tab is an IFS whitespace
# character, so read folds a run of tabs into one delimiter and drops a
# trailing empty field, silently shifting every field after it.
CASE_IDS=()
while IFS= read -r id; do
  [ -n "$id" ] && CASE_IDS+=("$id")
done < <(awk -F'\t' '$1 == "CASE" { print $2 }' "$CASES")

if [ "${#CASE_IDS[@]}" -eq 0 ]; then
  echo "test-recall-runner.sh: CASES.tsv yielded no rows. Refusing to report success over an empty set." >&2
  exit 1
fi

field_of() {
  awk -F'\t' -v id="$1" -v n="$2" '$1 == "CASE" && $2 == id { print $n; exit }' "$CASES"
}

# The three verdict.sh tokens a grading run can reach, and one that is the
# runner's own. Named here rather than scraped, so the suite asserts the
# pairing of code to token and not just the code. Anything else is a row this
# fixture does not carry.
#
# 4 is the odd one and it is deliberately not a verdict.sh code. It says the
# value was right and the construct the rep drills was not written, which is a
# statement about the submission that no exit code of TLC's could carry. It
# sits in the 3-to-7 range harness/vacuity.sh:320 already reserves for
# statements about the submission, and it collides with nothing in
# harness/verdict.sh's table. Part 10 asserts the non-collision.
token_for() {
  case "$1" in
    0)   printf 'OK\n' ;;
    4)   printf 'CONSTRUCT_NOT_WRITTEN\n' ;;
    10)  printf 'ASSUMPTION_FAILED\n' ;;
    150) printf 'PARSE_ERROR\n' ;;
    *)   printf 'UNKNOWN_%s\n' "$1" ;;
  esac
}

echo "== part 1: every fixture case, graded through the real runner =="
# ---------------------------------------------------------------------------
# Four of these rows are the epic's measured table. They are re-measured here
# rather than carried over, because a constant nobody re-ran is a hypothesis.
# ---------------------------------------------------------------------------

for id in "${CASE_IDS[@]}"; do
  rep=$(field_of "$id" 3)
  want_grade=$(field_of "$id" 4)
  want_rc=$(field_of "$id" 5)
  answer=$(field_of "$id" 6)

  run_runner "$RUNNER" "$rep" "$answer"

  status=$(awk '/^rep=/ { print; exit }' <<<"$RUN_OUT")
  assert_eq "$id $rep: status line" \
    "rep=$rep rc=$want_rc token=$(token_for "$want_rc") grade=$want_grade" \
    "$status"
  assert_eq "$id $rep: the runner exits with that same code" "$want_rc" "$RUN_RC"
done

echo
echo "== part 2: the code is verdict.sh's, corroborated independently =="
# ---------------------------------------------------------------------------
# This suite builds the scaffold itself and runs the verdict channel over it,
# so part 1's numbers are checked against the channel rather than against the
# script that reports them. The RED line on bead tla-wekw asks for exactly
# this: the rc the runner reports is the rc harness/verdict.sh returned, never
# one inferred from TLC's prose.
# ---------------------------------------------------------------------------

EXTENDS_LIST="Naturals, Integers, Sequences, FiniteSets, TLC"

independent_rc() {
  local rep="$1" answer="$2" dir canon env_name rc=0
  dir=$(mktemp -d "$TMPROOT/indep.XXXXXX")
  env_name=$(awk -F'\t' -v id="$rep" '$1 == "REP" && $2 == id { print $4; exit }' "$REPS")
  canon=$(awk -F'\t' -v id="$rep" '$1 == "REP" && $2 == id { print $6; exit }' "$REPS")
  {
    printf '%s\n' "---- MODULE Indep ----"
    printf 'EXTENDS %s\n' "$EXTENDS_LIST"
    cat -- "$ENV_DIR/$env_name.tla"
    printf 'Answer == %s\n' "$answer"
    printf 'Canonical == %s\n' "$canon"
    printf 'ASSUME Answer = Canonical\n'
    printf '%s\n' "===="
  } >"$dir/Indep.tla"
  : >"$dir/Indep.cfg"
  "$VERDICT" -q -c "$dir/Indep.cfg" --scratch "$dir/states" --log "$dir/log" "$dir/Indep.tla" >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}

for id in "${CASE_IDS[@]}"; do
  rep=$(field_of "$id" 3)
  want_rc=$(field_of "$id" 5)
  answer=$(field_of "$id" 6)
  assert_eq "$id: verdict.sh itself returns $want_rc over an equivalent scaffold" \
    "$want_rc" "$(independent_rc "$rep" "$answer")"
done

echo
echo "== part 3: any correct form passes, and both values are shown =="

run_runner "$RUNNER" R001 '[Wagons -> Tracks]'
C001_RC=$RUN_RC
run_runner "$RUNNER" R001 '{f \in [Wagons -> Tracks] : TRUE}'
C002_RC=$RUN_RC
assert_eq "two different expressions for one value both score 0" "0-0" "$C001_RC-$C002_RC"

run_runner "$RUNNER" R001 '[w \in Wagons |-> Tracks]'
WRONG_OUT="$RUN_OUT"

if has "$WRONG_OUT" '^you typed +\[w \\in Wagons \|-> Tracks\]$'; then
  ok "a wrong answer shows what was typed, labeled"
else
  nope "a wrong answer shows what was typed, labeled"
fi
if has "$WRONG_OUT" '^the answer +\[Wagons -> Tracks\]$'; then
  ok "a wrong answer shows the canonical answer, labeled"
else
  nope "a wrong answer shows the canonical answer, labeled"
fi
# The submitted value is a function and prints as a record of three ranges.
# The canonical value is the 27-member function set and its count comes back.
if has "$WRONG_OUT" '\[a \|-> 1\.\.3, b \|-> 1\.\.3, c \|-> 1\.\.3\]'; then
  ok "the submitted value is evaluated and printed"
else
  nope "the submitted value is evaluated and printed"
fi
if has "$WRONG_OUT" '^ +27$'; then
  ok "the canonical value is counted, since it is a set"
else
  nope "the canonical value is counted, since it is a set"
fi

echo
echo "== part 4: the cardinality skip, which is explanation and not failure =="
# ---------------------------------------------------------------------------
# Cardinality ERRORS on a value that is not a set, and there is no in-TLA+
# guard to reach for instead: IsFiniteSet answers TRUE, rc 0, on the very
# value whose Cardinality errors. That is asserted below rather than taken on
# trust, because the whole design of the value block rests on it.
# ---------------------------------------------------------------------------

if has "$WRONG_OUT" 'Attempted to compute cardinality of the value'; then
  ok "TLC's own sentence about the refused count is part of the explanation"
else
  nope "TLC's own sentence about the refused count is part of the explanation"
fi
if has "$WRONG_OUT" 'no count'; then
  ok "and the runner says the count was skipped"
else
  nope "and the runner says the count was skipped"
fi
# The line citing a line of a module in an already-deleted scratch directory
# is dropped, because it sends a reader somewhere they cannot go.
if has "$WRONG_OUT" '^ +Error: Evaluating assumption line'; then
  nope "the scratch module's line citation is not shown"
else
  ok "the scratch module's line citation is not shown"
fi

# C006: both values are functions, so the count is skipped on BOTH sides and
# neither side loses its value to the other's failure. That is the whole
# reason there is one probe per value rather than one probe with four
# assumptions.
run_runner "$RUNNER" R002 '[w \in Wagons |-> 2]'
BOTH_OUT="$RUN_OUT"
assert_eq "a non-set rep: the count is skipped on both sides" "2" \
  "$(grep -cE 'no count' <<<"$BOTH_OUT")"
if has "$BOTH_OUT" '\[a \|-> 2, b \|-> 2, c \|-> 2\]'; then
  ok "and the submitted value still prints"
else
  nope "and the submitted value still prints"
fi
if has "$BOTH_OUT" '\[a \|-> 1, b \|-> 1, c \|-> 1\]'; then
  ok "and so does the canonical one, which failed its own count"
else
  nope "and so does the canonical one, which failed its own count"
fi

# IsFiniteSet against Cardinality, on one value, measured here.
GUARD_DIR="$TMPROOT/guard"
mkdir -p "$GUARD_DIR"
{
  printf '%s\n' "---- MODULE Guard ----"
  printf 'EXTENDS %s\n' "$EXTENDS_LIST"
  printf '%s\n' 'Wagons == {"a", "b", "c"}'
  printf '%s\n' 'Shown == [w \in Wagons |-> 1]'
  printf 'ASSUME PrintT(IsFiniteSet(Shown))\n'
  printf '%s\n' "===="
} >"$GUARD_DIR/Guard.tla"
: >"$GUARD_DIR/Guard.cfg"
GUARD_RC=0
"$VERDICT" -q -c "$GUARD_DIR/Guard.cfg" --scratch "$GUARD_DIR/s" \
  --log "$GUARD_DIR/log" "$GUARD_DIR/Guard.tla" >/dev/null 2>&1 || GUARD_RC=$?
assert_eq "IsFiniteSet accepts a function, so it cannot guard the count" "0" "$GUARD_RC"
if has "$(cat "$GUARD_DIR/log")" '^TRUE$'; then
  ok "and it answers TRUE on the value whose Cardinality errors"
else
  nope "and it answers TRUE on the value whose Cardinality errors"
fi

echo
echo "== part 5: the scratch discipline =="
# ---------------------------------------------------------------------------
# drill/study/check lines 724 to 764 is the pattern: a scratch directory the
# script cannot make is a hard error, never a run in the working directory.
# Falling back would put TLC's states/ tree and a generated module into
# whatever directory the caller is standing in, which on a delivered practice
# tree holds the only copy of the work.
# ---------------------------------------------------------------------------

CWD_PROBE="$TMPROOT/cwd-probe"
mkdir -p "$CWD_PROBE"
BEFORE=$(cd "$CWD_PROBE" && ls -A)
RUN_RC=0
(cd "$CWD_PROBE" && "$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" -- R001 '[Tracks -> Wagons]') >/dev/null 2>&1 || RUN_RC=$?
AFTER=$(cd "$CWD_PROBE" && ls -A)
assert_eq "a full wrong-answer run leaves the working directory untouched" "$BEFORE" "$AFTER"
assert_eq "and still reports the verdict code" "10" "$RUN_RC"

# An unmakeable scratch directory. TMPDIR points at a path that is not there
# and cannot be created, so mktemp fails.
POISON="$TMPROOT/not-a-dir/nope"
RUN_RC=0
POISON_OUT=$(TMPDIR="$POISON" "$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" -- R001 '[Wagons -> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "an unmakeable scratch directory is exit 3, could-not-run" "3" "$RUN_RC"
if has "$POISON_OUT" 'nothing was graded'; then
  ok "and it says nothing was graded, rather than reporting a grade"
else
  nope "and it says nothing was graded, rather than reporting a grade"
fi
if has "$POISON_OUT" '^rep='; then
  nope "and it prints no status line, since there is no verdict to report"
else
  ok "and it prints no status line, since there is no verdict to report"
fi

echo
echo "== part 6: the mutants, which is what makes parts 1 to 4 mean something =="
# ---------------------------------------------------------------------------

MIRROR="$TMPROOT/mirror"
mkdir -p "$MIRROR/recall"

# mutate <name> <sed-script>: a copy of the real runner with one line changed,
# placed in a bare tree carrying recall/ and nothing else.
#
# IT USED TO NEED A harness/verdict.sh SYMLINK BESIDE IT. The runner resolved
# its verdict channel from its own root, so a mutant anywhere else died at
# exit 3 before the mutation could be seen. Bead tla-1sh7.10 made the runner
# self-contained and the symlink went with it, which means every mutant below
# now also runs in the shape a delivered tree has.
#
# Separate `local` statements, because `local a=$1 b=$a` reads $a as unbound
# under `set -u` on this bash.
#
# THE PATH LANDS IN MUTANT AND THE RETURN CODE SAYS WHETHER THERE IS ONE.
#
# IT USED TO RETURN THE PATH ON STDOUT, and that made this guard unable to
# fail the suite. Every call site read it through `M1=$(mutate ...) || M1=""`,
# which is a subshell, so a vacuous mutation called nope inside one. The FAIL
# row went into the variable, the `|| M1=""` then cleared it, and the
# fail_count increment died with the subshell. A mutation that stopped
# applying left nothing behind at all.
#
# Watched doing exactly that on 2026-10-17 while part 14 was being written:
# M9 and M10 both failed to apply, and the suite printed nothing between the
# mutant header and the tally. Bead tla-vo5l measured the same defect in
# harness/test-drill-runner.sh the day before, named this file as carrying it
# at eight call sites, and left it as follow-up because it was outside that
# bead's footprint. This is that follow-up, and the mechanism is tla-vo5l's
# so the two suites do not carry two fixes for one bug.
#
# So the call sites below are `if mutate ...; then`, not a capture. Keep them
# that way. A capture puts nope back in a subshell and the guard goes quiet
# again.
#
# Separate `local` statements, because `local a=$1 b=$a` reads $a as unbound
# under `set -u` on this bash.
MUTANT=""
mutate() {
  local name="$1"
  local script="$2"
  local out="$MIRROR/recall/$name.sh"
  MUTANT=""
  sed "$script" "$RUNNER" >"$out"
  chmod +x "$out"
  if [ "$(cat "$out")" = "$(cat "$RUNNER")" ]; then
    nope "mutant $name changed nothing, so its control below is vacuous"
    return 1
  fi
  MUTANT="$out"
  return 0
}

# Every sed script is single-quoted on purpose: both sides of the substitution
# are literal lines of the runner's source, so an expansion here would match
# nothing and the mutation would silently be a no-op. mutate() fails loudly in
# that case, which is the other half of the guard.

# M1. the reported code stops being the one verdict.sh returned.
# shellcheck disable=SC2016
if mutate inferred-code 's|^GRADE_RC="\$VERDICT_RC"$|GRADE_RC=0|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  assert_ne "control: a runner reporting its own code is DETECTED by part 1's code row" \
    "10" "$RUN_RC"
  assert_eq "and it fails the way the mutation says, a wrong answer exiting 0" "0" "$RUN_RC"
fi

# M2. rc 150 is reported as a wrong answer rather than as its own thing.
if mutate parse-called-wrong 's|^  150) GRADE="parse-error" ;;$|  150) GRADE="incorrect" ;;|'; then
  run_runner "$MUTANT" R001 '[Wagons ->'
  if has "$RUN_OUT" 'grade=parse-error'; then
    nope "control: a runner calling a parse error a wrong answer is DETECTED"
  else
    ok "control: a runner calling a parse error a wrong answer is DETECTED"
  fi
  if has "$RUN_OUT" 'grade=incorrect'; then
    ok "and it fails the way the mutation says, grade=incorrect on rc 150"
  else
    nope "and it fails the way the mutation says, grade=incorrect on rc 150"
  fi
fi

# M3. the canonical value is never shown, so the block stops being dual.
# The `$CANON` must stay literal: it is a character of the runner's source
# that the pattern has to match, not a variable of this suite's.
# shellcheck disable=SC2016
if mutate lost-value-block 's|^show_value "the answer" "Canon" "\$CANON"$|:|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  if has "$RUN_OUT" '^the answer '; then
    nope "control: a runner showing only one value is DETECTED by part 3"
  else
    ok "control: a runner showing only one value is DETECTED by part 3"
  fi
  if has "$RUN_OUT" '^you typed '; then
    ok "and it fails the way the mutation says, the typed value still shows"
  else
    nope "and it fails the way the mutation says, the typed value still shows"
  fi
fi

# M4. the skipped-count note never prints, so a refused count passes silently.
# shellcheck disable=SC2016
if mutate count-claimed 's|^  if \[ "\$VERDICT_RC" != "0" \]; then$|  if false; then|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  if has "$RUN_OUT" 'no count'; then
    nope "control: a runner silent about a refused count is DETECTED by part 4"
  else
    ok "control: a runner silent about a refused count is DETECTED by part 4"
  fi
  if has "$RUN_OUT" 'Attempted to compute cardinality'; then
    ok "and it fails the way the mutation says, TLC's sentence still shows"
  else
    nope "and it fails the way the mutation says, TLC's sentence still shows"
  fi
fi

echo
echo "== part 7: usage, and could-not-run =="

OUT=""
RUN_RC=0
OUT=$("$RUNNER" 2>&1) || RUN_RC=$?
assert_eq "no arguments is exit 2, a usage error" "2" "$RUN_RC"
if has "$OUT" 'no rep id given'; then
  ok "and it says which argument is missing"
else
  nope "and it says which argument is missing"
fi

RUN_RC=0
OUT=$("$RUNNER" R001 2>&1) || RUN_RC=$?
assert_eq "a rep with no answer is exit 2" "2" "$RUN_RC"

RUN_RC=0
OUT=$("$RUNNER" --bogus R001 x 2>&1) || RUN_RC=$?
assert_eq "an unknown flag is exit 2" "2" "$RUN_RC"

RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" -- R999 '1' 2>&1) || RUN_RC=$?
assert_eq "an unknown rep is exit 3, could-not-run, not a grade" "3" "$RUN_RC"
if has "$OUT" 'nothing was graded'; then
  ok "and it says so"
else
  nope "and it says so"
fi

RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$TMPROOT/no-such-env" -- R001 '1' 2>&1) || RUN_RC=$?
assert_eq "a missing environment file is exit 3, not a grade" "3" "$RUN_RC"
if has "$OUT" 'is not there'; then
  ok "and it names the file it looked for"
else
  nope "and it names the file it looked for"
fi

RUN_RC=0
OUT=$("$RUNNER" --reps "$TMPROOT/no-such-reps.tsv" -- R001 '1' 2>&1) || RUN_RC=$?
assert_eq "a missing rep table is exit 3, not a grade" "3" "$RUN_RC"

# ---------------------------------------------------------------------------
# AN ANSWER BEGINNING WITH A DASH, WITH NOTHING IN FRONT OF IT.
#
# Negative integers are ordinary answers at this rung. The `--` escape below
# works and still has to, but a learner typing the right answer to a
# thermometer rep has no way to guess it, and a usage dump in place of a grade
# costs more than the parser change does.
# ---------------------------------------------------------------------------
RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" R001 '-1' 2>&1) || RUN_RC=$?
assert_eq "an answer beginning with a dash needs no -- escape" "10" "$RUN_RC"
if has "$OUT" 'unknown option'; then
  nope "and it is never reported as an unknown option"
else
  ok "and it is never reported as an unknown option"
fi

# The escape still reaches the same grade, so nothing that already ran stops
# running. Every other call in this suite goes through it.
run_runner "$RUNNER" R001 '-1'
assert_eq "the -- escape still reaches the same grade" "10" "$RUN_RC"

# An answer that happens to spell one of this script's own flags is the answer.
# `-q` is not TLA+, so it reaches SANY and comes back 150, and that number is
# what proves the argument was consumed as an answer rather than as a flag.
RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" R001 '-q' 2>&1) || RUN_RC=$?
assert_eq "an answer that spells a flag is still the answer" "150" "$RUN_RC"

# The other half of the change, which is that a flag BEFORE the rep id is
# still a flag. Quiet prints the status line and nothing else, so one line out
# is the whole assertion.
RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" -q R001 '[Wagons -> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "a flag before the rep id still takes effect" "1" "$(wc -l <<<"$OUT")"

RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" R001 '-1' spare 2>&1) || RUN_RC=$?
assert_eq "a third positional argument is still a usage error" "2" "$RUN_RC"

echo
echo "== part 8: static, over the runner's own source =="

SRC=$(cat "$RUNNER")

if has "$SRC" 'BASH_SOURCE'; then
  ok "the runner resolves its root from BASH_SOURCE"
else
  nope "the runner resolves its root from BASH_SOURCE"
fi
# A hardcoded repo root is the leak the footprint check cannot see: it happens
# inside the script rather than in an Edit, so git reports a clean tree and
# the damage lands in somebody else's checkout. Bead tla-1hf is the precedent,
# where scripts/gen-curriculum-map.sh carried `cd /home/frank/repos/tla-puzzles`
# at line 5 and wrote CURRICULUM_MAP.md into the main tree from a worktree.
if has "$SRC" '/home/'; then
  nope "the runner hardcodes no absolute home path"
else
  ok "the runner hardcodes no absolute home path"
fi
if has "$SRC" 'trap .*EXIT'; then
  ok "the scratch directory is dropped on a trap"
else
  nope "the scratch directory is dropped on a trap"
fi
# The fallback this script must never grow. A scratch directory it cannot make
# is exit 3. A `|| SCRATCH=.` would put the generated module and TLC's states/
# tree into the caller's working directory.
if has "$SRC" 'SCRATCH="?\.'; then
  nope "no fallback from a failed scratch into the working directory"
else
  ok "no fallback from a failed scratch into the working directory"
fi
# The banned idiom, assembled from pieces so this suite does not itself carry
# the literal harness/test-pipefail.sh scans for. That gate strips whole-line
# comments before matching but not code, and a static check that trips the
# tree-wide ban would be its own bug.
BAR='[[:space:]]*\|[[:space:]]*'
for consumer in 'grep[[:space:]]+-[A-Za-z]*q' 'grep[[:space:]]+-[A-Za-z]*m[[:space:]]*[0-9]' 'head([[:space:]]|$)'; do
  if has "$SRC" "${BAR}${consumer}"; then
    nope "no pipe into an early-exiting consumer ($consumer)"
  else
    ok "no pipe into an early-exiting consumer ($consumer)"
  fi
done
# ---------------------------------------------------------------------------
# THE RUNNER GRADES WITH NOTHING BUT TLC (bead tla-1sh7.10).
#
# It used to resolve ${REPO_ROOT}/harness/verdict.sh and refuse to start
# without it, so a copy delivered to a practice tree answered rc 3 to every
# rep and every answer, right ones included. These rows are what stops that
# coming back from the other end.
#
# REPO_ROOT ITSELF IS STILL HERE and still legitimate: it is drill/SHEET.md's
# default, and a sheet that is not there is silence rather than a refusal. So
# the ban is on a REQUIRED path above the runner's own directory, which is a
# narrower thing than a ban on the variable.
# ---------------------------------------------------------------------------
# THE CODE, WITH WHOLE-LINE COMMENTS STRIPPED. The two rows under this are
# the only ones in part 8 that need it, and they need it badly: the runner's
# header NAMES the dependency it used to have, in order to say it is gone, so
# a scan of the whole file finds the string it is there to forbid and reports
# the fix as the defect. The idiom is harness/test-indeterminate.sh's census
# scan. Trailing comments survive it, which is why neither pattern below is
# anchored to one.
RUNNER_CODE=$(sed 's/^[[:space:]]*#.*$//' "$RUNNER")

if has "$RUNNER_CODE" 'REPO_ROOT.*harness'; then
  nope "the runner reaches for nothing under harness/, so a delivered tree can grade"
else
  ok "the runner reaches for nothing under harness/, so a delivered tree can grade"
fi
if has "$RUNNER_CODE" 'die_cannot_run.*verdict'; then
  nope "and refuses to start for no reason a delivered tree could not fix"
else
  ok "and refuses to start for no reason a delivered tree could not fix"
fi
if has "$RUNNER_CODE" 'command -v tlc'; then
  ok "an absent tlc is could-not-run rather than a shell code wearing a grade"
else
  nope "an absent tlc is could-not-run rather than a shell code wearing a grade"
fi

# ---------------------------------------------------------------------------
# THE COPIED TABLE AGREES WITH harness/verdict.sh's, ROW FOR ROW.
#
# This is the gate the self-contained route is only honest with. verdict.sh's
# header says it is the one place the exit-code table lives, and the runner
# now carries five of its rows. A second copy nobody checks is the rot surface
# that justifies "deliver verdict.sh alongside" instead, so the copy is
# checked here: every code the runner names has to map to the token
# verdict.sh maps it to.
#
# READ OUT OF BOTH FILES' CODE, never out of either header. A header is prose
# and can agree with a table that does not. The runner's verdict_token() and
# verdict.sh's own case arm are the two things a learner's grade actually
# passes through.
#
# WHAT IS *NOT* ASSERTED is that the runner names every row. It deliberately
# names five of verdict.sh's thirteen mapped codes -- the three a grading run
# can reach plus the two that are structural -- and everything else is
# UNKNOWN_<rc>, which is verdict.sh's own posture for an unmapped code.
# Requiring all thirteen would be requiring the duplication this bead spent
# its measurement avoiding.
# ---------------------------------------------------------------------------
# Each helper prints `<code> <TOKEN>` per mapped arm, one a line. Both read a
# case arm rather than a header row, for the reason above.
RUNNER_ROWS=$(awk '
  /^verdict_token\(\)/        { on = 1; next }
  on && /^\}/                 { exit }
  on && match($0, /^ *[0-9]+\)/) {
    code = $0
    sub(/^ */, "", code)
    sub(/\).*/, "", code)
    if (match($0, /[A-Z][A-Z_]+/)) {
      printf "%s %s\n", code, substr($0, RSTART, RLENGTH)
    }
  }
' "$RUNNER")

VERDICT_ROWS=$(awk '
  match($0, /^ *[0-9]+\) *verdict="[A-Z_]+"/) {
    code = $0
    sub(/^ */, "", code)
    sub(/\).*/, "", code)
    t = $0
    sub(/^.*verdict="/, "", t)
    sub(/".*$/, "", t)
    printf "%s %s\n", code, t
  }
' "$VERDICT")

assert_ne "the runner names codes of its own, so the rows below are not vacuous" \
  "" "$RUNNER_ROWS"
assert_eq "it names five: the three a grading run reaches, plus 124 and 255" \
  "5" "$(wc -l <<<"$RUNNER_ROWS")"
assert_ne "and verdict.sh's own arms were read, so the comparison has two sides" \
  "" "$VERDICT_ROWS"

TABLE_DRIFT=""
while IFS=' ' read -r code mine; do
  [ -n "$code" ] || continue
  theirs=$(awk -v c="$code" '$1 == c { print $2; exit }' <<<"$VERDICT_ROWS")
  if [ -z "$theirs" ]; then
    TABLE_DRIFT="${TABLE_DRIFT}${code}: verdict.sh maps no token, the runner says ${mine}. "
  elif [ "$mine" != "$theirs" ]; then
    TABLE_DRIFT="${TABLE_DRIFT}${code}: the runner says ${mine}, verdict.sh says ${theirs}. "
  fi
done <<<"$RUNNER_ROWS"
assert_eq "every code the runner names carries verdict.sh's own token for it" \
  "" "$TABLE_DRIFT"

# The three a grading run can actually reach, named rather than only counted,
# so a table that drifted to five other rows still goes red here.
for want in "0 OK" "10 ASSUMPTION_FAILED" "150 PARSE_ERROR"; do
  if grep -qxF -- "$want" <<<"$RUNNER_ROWS"; then
    ok "the runner maps ${want%% *} to ${want#* }, as verdict.sh does"
  else
    nope "the runner maps ${want%% *} to ${want#* }, as verdict.sh does"
  fi
done

# The catch-all, which is what makes copying five rows safe at all.
if has "$RUNNER_CODE" "UNKNOWN_%s"; then
  ok "an unmapped code is reported as itself rather than bucketed into a familiar row"
else
  nope "an unmapped code is reported as itself rather than bucketed into a familiar row"
fi

# ---------------------------------------------------------------------------
# THE FLAGS, BOTH SIDES READ WITH COMMENTS STRIPPED.
#
# The runner's invocation is verdict.sh's, and part 2 corroborates every code
# by running verdict.sh over an equivalent scaffold, which means nothing if
# the two run TLC differently.
#
# COMMENT-STRIPPING IS WHAT MAKES THIS ROW BITE, and it was found by watching
# it fail to. Both files carry a header that names every flag and says what it
# is for, so a scan of the whole text passes over a runner that has dropped
# the flag from its command line and kept the sentence about it. Measured on a
# mutant with `-coverage 1` deleted from the code: the row stayed green.
# ---------------------------------------------------------------------------
VERDICT_CODE=$(sed 's/^[[:space:]]*#.*$//' "$VERDICT")
for flag in '-workers 1' '-noGenerateSpecTE' '-nowarning' '-coverage 1' \
            '-dumpTrace json' '-metadir' '-deadlock'; do
  if has "$RUNNER_CODE" "$flag" && has "$VERDICT_CODE" "$flag"; then
    ok "the runner passes TLC ${flag}, as verdict.sh does"
  else
    nope "the runner passes TLC ${flag}, as verdict.sh does"
  fi
done
# ---------------------------------------------------------------------------
# THE GRADE IS AN EXIT CODE, ASSERTED STRUCTURALLY.
#
# scripts/verify-puzzle.sh is the cautionary tale this project keeps: its
# elif-chain of greps matched "Finished in" on a spec that never parsed and
# reported a PASS. So the grade's code has to come from the verdict channel
# and from nowhere else.
#
# The ban is on a grade ASSIGNED FROM A MATCHER, not on TLC phrases appearing
# in the source at all. The runner does carry `/^Finished in /`, as one of the
# boundaries of the region it prints for a human to read, and that is display
# rather than verdict -- the distinction verdict.sh's own header draws when it
# calls the log a channel "for HUMANS and for witness extraction, never for
# verdicts". A blanket ban on the phrase would forbid the honest use along
# with the dishonest one.
# ---------------------------------------------------------------------------
# The `$VERDICT_RC` is a literal to find in the runner's source. Expanding it
# here would search for whatever this suite happens to hold, which is nothing,
# and the row would pass over an empty pattern.
# shellcheck disable=SC2016
if has "$SRC" '^GRADE_RC="\$VERDICT_RC"$'; then
  ok "the reported code is assigned straight from the verdict channel's code"
else
  nope "the reported code is assigned straight from the verdict channel's code"
fi
if has "$SRC" 'GRADE[_A-Z]*=.*\$\((grep|awk|sed|cut)'; then
  nope "no grade is assigned from the output of a text matcher"
else
  ok "no grade is assigned from the output of a text matcher"
fi
if has "$SRC" 'No error has been found'; then
  nope "TLC's success phrase appears nowhere in the runner"
else
  ok "TLC's success phrase appears nowhere in the runner"
fi

echo
echo "== part 9: the fixture's own shape =="

# Six fields, or seven when the row carries a construct gate. Both shapes have
# to stay legal in one table: a six-field row is what "no pattern behaves
# exactly as it did before field 7 existed" means, and recall/REPS.tsv's 120
# live rows are all six.
assert_eq "every REP row has six or seven fields" "" \
  "$(awk -F'\t' '$1 == "REP" && (NF < 6 || NF > 7) { print $2 }' "$REPS")"
assert_eq "the fixture still carries a six-field row, so the no-gate path is covered" \
  "2" "$(awk -F'\t' '$1 == "REP" && NF == 6' "$REPS" | wc -l)"
assert_eq "and a seven-field row, so the gate path is covered" \
  "2" "$(awk -F'\t' '$1 == "REP" && NF == 7' "$REPS" | wc -l)"
assert_eq "every CASE row has six fields" "" \
  "$(awk -F'\t' '$1 == "CASE" && NF != 6 { print $2 }' "$CASES")"
assert_eq "every CASE names a REP that exists" "" \
  "$(awk -F'\t' 'NR == FNR && $1 == "REP" { have[$2] = 1; next } $1 == "CASE" && !($3 in have) { print $2 }' "$REPS" "$CASES")"
MISSING_ENV=""
while IFS= read -r pair; do
  [ -n "$pair" ] || continue
  rep_id=${pair%% *}
  env_name=${pair##* }
  [ -r "$ENV_DIR/$env_name.tla" ] || MISSING_ENV="$MISSING_ENV $rep_id"
done < <(awk -F'\t' '$1 == "REP" { print $2, $4 }' "$REPS")
assert_eq "every REP names an environment file that exists" "" "$MISSING_ENV"
# A construct id has to resolve to a drill/INVENTORY.md row, which is what
# keeps a rep anchored to the coverage inventory rather than floating.
assert_eq "every REP construct id resolves to a drill/INVENTORY.md row" "" \
  "$(awk -F'\t' 'NR == FNR && $1 == "ROW" { have[$2] = 1; next } $1 == "REP" && !($3 in have) { print $2 }' "$REPO_ROOT/drill/INVENTORY.md" "$REPS")"
# An environment that defines one of the scaffold's three names makes every
# rep over it fail to parse, with SANY reporting a multiple declaration.
assert_eq "no environment file defines a reserved scaffold name" "" \
  "$(awk '/^(Answer|Canonical|Shown) *==/ { print FILENAME }' "$ENV_DIR"/*.tla)"
# A prompt that contains the notation it asks for is a transcription exercise.
# The sibling gate (bead tla-1sh7.4) owns the real check; this is the floor,
# so the fixture cannot drift into the shape the gate exists to forbid.
assert_eq "no fixture prompt carries TLA+ notation" "" \
  "$(awk -F'\t' '$1 == "REP" && $5 ~ /[|<>\[\]{}\\]/ { print $2 }' "$REPS")"
assert_eq "both measured grades appear in the fixture" "correct incorrect parse-error" \
  "$(awk -F'\t' '$1 == "CASE" { print $4 }' "$CASES" | sort -u | tr '\n' ' ' | sed 's/ $//')"

echo
echo "== part 10: the construct gate, field 7 =="
# ---------------------------------------------------------------------------
# Value equality grades the value, so it cannot see how the value was reached.
# A rep that drills a construct rather than a result needs one more thing: the
# construct has to be in what was typed.
#
# THE TRAP THIS PART EXISTS TO CATCH. A pattern strict enough to require a LET
# is also strict enough to refuse a correct alternate spelling, and any correct
# form passing is the property that lets this rung grade without a model in the
# loop. So every gated row below is measured THREE ways: the canonical answer,
# a correct alternate that still carries the construct, and the right value
# written without it. The first two have to score 0 and the third has to be
# refused. A pattern that fails the middle row has taken the rung back to
# being a spelling test, and the row above it would not say so on its own.
# ---------------------------------------------------------------------------

gate_rc() {
  local rc=0
  "$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" -q "$1" "$2" >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}

# R003 gates on LET, over field 7 `\bLET\b`.
assert_eq "R003: the canonical answer, which carries a LET" \
  "0" "$(gate_rc R003 'LET Twice(t) == t * 2 IN [t \in Tracks |-> Twice(t)]')"
assert_eq "R003: a correct alternate with the operator renamed and its body changed" \
  "0" "$(gate_rc R003 'LET Doubled(n) == n + n IN [t \in Tracks |-> Doubled(t)]')"
assert_eq "R003: a correct alternate defining the whole function rather than the element" \
  "0" "$(gate_rc R003 'LET F == [t \in Tracks |-> t * 2] IN F')"
assert_eq "R003: the right value with no definition written at all is refused" \
  "4" "$(gate_rc R003 '[t \in Tracks |-> t * 2]')"
assert_eq "R003: a wrong value is a wrong value, and the gate does not reach it" \
  "10" "$(gate_rc R003 'Tracks')"

# R004 gates on EXCEPT, over field 7 `\bEXCEPT\b`. A second construct, so the
# rows above are not one keyword's accident.
assert_eq "R004: the canonical answer, which carries an EXCEPT" \
  "0" "$(gate_rc R004 '[[t \in Tracks |-> 0] EXCEPT ![1] = 9]')"
assert_eq "R004: a correct alternate with the new value written differently" \
  "0" "$(gate_rc R004 '[[t \in Tracks |-> 0] EXCEPT ![1] = 3 + 6]')"
assert_eq "R004: the right value built without EXCEPT is refused" \
  "4" "$(gate_rc R004 '[t \in Tracks |-> IF t = 1 THEN 9 ELSE 0]')"

# A row with no pattern behaves as it did before field 7 existed. R002's
# canonical carries neither keyword, so a gate leaking onto an ungated row
# would show up here as a 4.
assert_eq "R001 carries no pattern, so a correct answer is still 0" \
  "0" "$(gate_rc R001 '[Wagons -> Tracks]')"
assert_eq "R002 carries no pattern, so a correct answer with no keyword in it is still 0" \
  "0" "$(gate_rc R002 '[w \in Wagons |-> 1]')"

# What a refusal says. The grading run's own code and token stay on the page,
# because the runner's 4 replaces them on the status line and a reader should
# still be able to see that TLC said the value was right.
RUN_RC=0
OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" --sheet "$SHEET" \
  R003 '[t \in Tracks |-> t * 2]' 2>&1) || RUN_RC=$?
if has "$OUT" '^rep=R003 rc=4 token=CONSTRUCT_NOT_WRITTEN grade=construct-missing$'; then
  ok "a refusal reports the runner's own code and token on the status line"
else
  nope "a refusal reports the runner's own code and token on the status line"
fi
if has "$OUT" 'the grading run came back rc=0 token=OK'; then
  ok "and names the grading run's own code, which was 0"
else
  nope "and names the grading run's own code, which was 0"
fi
if has "$OUT" 'LET'; then
  ok "and echoes the pattern, so the construct that was wanted is on the page"
else
  nope "and echoes the pattern, so the construct that was wanted is on the page"
fi
# No value block. The two values are equal, so printing them twice says
# nothing, and the thing that IS wrong would be buried under them.
if has "$OUT" '^you typed '; then
  nope "and shows no value block, since the two values are equal"
else
  ok "and shows no value block, since the two values are equal"
fi

# A pattern grep will not read is could-not-run, never a pass. A gate that
# fell open on a malformed pattern would be worse than no gate, because the
# row would look gated and would not be.
BADREPS="$TMPROOT/bad-pattern.tsv"
printf 'REP\tR900\tK001\tshunting\tfor each track, twice its number\t[t \\in Tracks |-> t * 2]\t[\n' >"$BADREPS"
RUN_RC=0
OUT=$("$RUNNER" --reps "$BADREPS" --env-dir "$ENV_DIR" -q R900 '[t \in Tracks |-> t * 2]' 2>&1) || RUN_RC=$?
assert_eq "a field-7 pattern that is not a regex is exit 3, could-not-run" "3" "$RUN_RC"
if has "$OUT" 'nothing was graded'; then
  ok "and it says nothing was graded, rather than letting the answer through"
else
  nope "and it says nothing was graded, rather than letting the answer through"
fi

# 4 is the runner's own code and must not be a code verdict.sh documents,
# because a caller branching on the number has to be able to tell a statement
# about the submission from a verdict about the run.
assert_eq "4 appears in no row of harness/verdict.sh's exit-code table" "" \
  "$(grep -hE -- '^#[[:space:]]+4[[:space:]]+[A-Z_]{3,}' "$VERDICT")"

echo
echo "== part 11: the value block is capped, and --full lifts the cap =="
# ---------------------------------------------------------------------------
# One wrong answer to the function-set rep ran to 40 lines, 27 of them the
# members of [Wagons -> Tracks] one per line, with the count that makes the
# point underneath them. The contrast a learner needs is between a function
# and a set of 27 of them, and the enumeration pushes the two halves apart
# instead of putting them side by side.
#
# The numbers below are measured on TLC2 2026.07.31.184830 and pinned the way
# part 1 pins raw exit codes: a layout change that quietly stopped capping
# would otherwise pass.
# ---------------------------------------------------------------------------

run_runner "$RUNNER" R001 '[w \in Wagons |-> Tracks]'
CAPPED_OUT="$RUN_OUT"
FULL_OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" --sheet "$SHEET" \
  --full -- R001 '[w \in Wagons |-> Tracks]' 2>&1) || true

# 47 and 24 were 40 and 17 before bead tla-1sh7.6, and the 7 lines between
# them are the two explanation layers: a blank, a label and two wrapped lines
# of the miss row, then a blank, the sheet header and its one line. The cap
# itself is untouched -- the value block is the same 5 lines a side it was
# cut to -- and that is what the rows under these two check.
assert_eq "the whole block is 47 lines when --full asks for it" "47" "$(wc -l <<<"$FULL_OUT")"
assert_eq "and 24 by default" "24" "$(wc -l <<<"$CAPPED_OUT")"

# Two members, then the elision, then the closing member and the count. Two
# rather than one because the second is what shows which position moves first,
# which is the whole content of a function set.
assert_eq "two leading members survive the cap" "2" \
  "$(grep -cE '^ +\{? *\[a \|-> 1, b \|-> 1,' <<<"$CAPPED_OUT")"
if has "$CAPPED_OUT" '\[a \|-> 3, b \|-> 3, c \|-> 3\] \}$'; then
  ok "the closing member survives, so the block still reads as a set"
else
  nope "the closing member survives, so the block still reads as a set"
fi
if has "$CAPPED_OUT" '\.\.\. 24 more lines, and --full shows them all \.\.\.'; then
  ok "the elision says how many lines went and how to get them back"
else
  nope "the elision says how many lines went and how to get them back"
fi
assert_eq "the count is kept, which is the number the contrast turns on" "1" \
  "$(grep -cE '^ +27$' <<<"$CAPPED_OUT")"
# The middle is what went. A member from the interior must not be there.
if has "$CAPPED_OUT" '\[a \|-> 2, b \|-> 2, c \|-> 2\]'; then
  nope "an interior member is elided rather than shown"
else
  ok "an interior member is elided rather than shown"
fi
assert_eq "--full shows all 27 members" "27" \
  "$(grep -cE 'c \|-> [0-9]\]' <<<"$FULL_OUT")"

# A block already short enough to read is left alone, byte for byte. That is
# the half the bead warned about: the answer the learner typed is usually
# small, and it is the half they have to recognize as theirs.
run_runner "$RUNNER" R002 '[w \in Wagons |-> 2]'
SHORT_DEFAULT="$RUN_OUT"
SHORT_FULL=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" --sheet "$SHEET" \
  --full -- R002 '[w \in Wagons |-> 2]' 2>&1) || true
assert_eq "a short block is identical with and without --full" "$SHORT_DEFAULT" "$SHORT_FULL"

# AND THE WRONG ANSWER'S OWN BLOCK IS CAPPED TOO, which is a correction to the
# bead rather than an echo of it. The bead expected the typed value to be
# small. At R108 and R109 of recall/REPS.tsv the characteristic mistake is to
# swap the domain and the range, and that produces a set of exactly the same
# size, so "usually small" does not hold for the family this rung exists for.
run_runner "$RUNNER" R001 '[Tracks -> Wagons]'
SWAP_OUT="$RUN_OUT"
if has "$SWAP_OUT" '^you typed +\[Tracks -> Wagons\]$'; then
  ok "a swapped-domain answer is still labeled as what was typed"
else
  nope "a swapped-domain answer is still labeled as what was typed"
fi
assert_eq "and its own 27-member block is capped on the same rule" "2" \
  "$(grep -cE '\.\.\. 24 more lines' <<<"$SWAP_OUT")"

# The mutant for the cap. Lifting the head past any block disables the
# elision, and part 11's elision row has to go red when it does.
# shellcheck disable=SC2016
if mutate cap-disabled 's|^VALUE_HEAD=2$|VALUE_HEAD=9999|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  if has "$RUN_OUT" 'more lines'; then
    nope "control: a runner that stopped capping is DETECTED by part 11"
  else
    ok "control: a runner that stopped capping is DETECTED by part 11"
  fi
  assert_eq "and it fails the way the mutation says, the whole 47 lines" "47" \
    "$(wc -l <<<"$RUN_OUT")"
fi

echo
echo "== part 12: the sheet entry and the miss row, layers 2 and 3 =="
# ---------------------------------------------------------------------------
# The two values are the first layer of the explanation and were the only one
# the runner showed. Bead tla-1sh7.6 wires the other two: the construct's
# entry from the sheet, keyed on the rep's field 3, and the miss table's row
# for this answer, keyed on the text that was typed.
#
# THE ROW THAT MATTERS MOST HERE IS THE SILENT ONE. 90 of the 120 real reps
# carry no miss row, so no row is the ordinary case rather than the fallback,
# and a block that reads as though something went missing would be wrong 3
# times out of 4. The no-row rows below assert an absence of apology as well
# as an absence of a row.
# ---------------------------------------------------------------------------

run_runner "$RUNNER" R001 '[w \in Wagons |-> Tracks]'
LAYERS_OUT="$RUN_OUT"

if has "$LAYERS_OUT" '^K050  ch06  function set$'; then
  ok "the sheet entry's header carries the id, the chapter and the name"
else
  nope "the sheet entry's header carries the id, the chapter and the name"
fi
if has "$LAYERS_OUT" '^  \[S -> T\] is the set of all functions from S to T$'; then
  ok "and its syntax line, with the markdown backticks dropped for a terminal"
else
  nope "and its syntax line, with the markdown backticks dropped for a terminal"
fi
if has "$LAYERS_OUT" '`'; then
  nope "no backtick survives into the printed entry"
else
  ok "no backtick survives into the printed entry"
fi
if has "$LAYERS_OUT" 'what it gives back for every wagon is the whole set'; then
  ok "the miss row's explanation is printed for the answer that was typed"
else
  nope "the miss row's explanation is printed for the answer that was typed"
fi

# THE ORDER, which is a judgment and so is asserted rather than left to read
# well by accident. Values, then what this answer says, then what the
# construct is. What settles it is the 90 reps with no row: this order ends
# on the sheet entry at all 120, so the bottom of the block does not move
# under a learner working at seconds a rep.
MISS_LINE=$(awk '/^what you wrote says$/ { print NR; exit }' <<<"$LAYERS_OUT")
SHEET_LINE=$(awk '/^K050  ch06  function set$/ { print NR; exit }' <<<"$LAYERS_OUT")
if [ -n "$MISS_LINE" ] && [ -n "$SHEET_LINE" ] && [ "$MISS_LINE" -lt "$SHEET_LINE" ]; then
  ok "the miss row is above the sheet entry, so every block ends on the sheet"
else
  nope "the miss row is above the sheet entry, so every block ends on the sheet (miss=$MISS_LINE sheet=$SHEET_LINE)"
fi

# THE COMMON CASE. C004 is a wrong answer to R001 that the fixture table has
# no row for, which is the path 90 of the 120 real reps take.
run_runner "$RUNNER" R001 '[Tracks -> Wagons]'
NOROW_OUT="$RUN_OUT"
if has "$NOROW_OUT" '^K050  ch06  function set$'; then
  ok "a wrong answer with no miss row still gets the construct's entry"
else
  nope "a wrong answer with no miss row still gets the construct's entry"
fi
if has "$NOROW_OUT" 'what you wrote says'; then
  nope "and no misconception section, since the table has nothing to say"
else
  ok "and no misconception section, since the table has nothing to say"
fi
# Nothing announces the absence. A learner holding both values and a sheet
# entry has had a whole answer, and should not be told that a table they
# cannot see declined to speak.
if has "$NOROW_OUT" '(no (misconception|row|explanation))|not recorded|nothing known|no entry'; then
  nope "and says nothing about a row it did not find"
else
  ok "and says nothing about a row it did not find"
fi

# A construct the sheet does not carry. R004 drills K087 and the fixture
# sheet leaves it out on purpose, so this is the other silence.
run_runner "$RUNNER" R004 'Tracks'
NOENTRY_OUT="$RUN_OUT"
if has "$NOENTRY_OUT" '^K0[0-9][0-9]  ch'; then
  nope "a construct the sheet does not carry prints no entry"
else
  ok "a construct the sheet does not carry prints no entry"
fi
if has "$NOENTRY_OUT" '^the answer +\[\[t \\in Tracks \|-> 0\] EXCEPT'; then
  ok "and the values are untouched by either layer being absent"
else
  nope "and the values are untouched by either layer being absent"
fi

echo
echo "-- the match is normalised for whitespace, not exact --"
# ---------------------------------------------------------------------------
# The rule: a space is kept only where it stands between two word characters,
# and dropped everywhere else. That is the only place TLA+ needs one.
#
# Exact text was the other candidate. It loses on this script's own argument:
# the grade is value equality precisely so that any correct form passes, and
# keying the explanation on the byte-for-byte shape of a wrong answer puts
# the spelling test back one layer down, where it costs a row somebody wrote
# and nobody sees.
# ---------------------------------------------------------------------------

fires() {
  run_runner "$RUNNER" R001 "$1"
  if has "$RUN_OUT" 'what you wrote says'; then printf 'yes\n'; else printf 'no\n'; fi
}

assert_eq "the row's own spacing reaches it" "yes" \
  "$(fires '[w \in Wagons |-> Tracks]')"
assert_eq "the same mistake with the spaces taken out reaches it" "yes" \
  "$(fires '[w \in Wagons|->Tracks]')"
assert_eq "the same mistake with spaces doubled and the brackets padded" "yes" \
  "$(fires '[ w  \in  Wagons  |->  Tracks ]')"
# Built with printf rather than typed, so the tab cannot be read as an indent
# by anything that touches this file later.
TABBED=$(printf '[w \\in Wagons |->\tTracks]')
assert_eq "and with a tab in it, since a tab is whitespace like any other" "yes" \
  "$(fires "$TABBED")"
# The other half of the rule. `\in Wagons` is a space between two word
# characters, so it carries a token boundary and must NOT be dropped: the
# answer below is a different token sequence and reaches no row.
assert_eq "a space between two word characters is kept, so \\inWagons is not it" "no" \
  "$(fires '[w \inWagons |-> Tracks]')"
assert_eq "a different wrong answer reaches no row" "no" \
  "$(fires '[w \in Wagons |-> Wagons]')"
assert_eq "and neither does the one the fixture deliberately has no row for" "no" \
  "$(fires '[Tracks -> Wagons]')"

echo
echo "-- the construct gate's refusal gets the entry too --"
# The one grade whose entire content is that a construct was not written, and
# field 7 is an ERE rather than notation. No miss row there: the value was
# right, and that table is about wrong ones.
RUN_RC=0
GATE_OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" --sheet "$SHEET" \
  R003 '[t \in Tracks |-> t * 2]' 2>&1) || RUN_RC=$?
assert_eq "a refusal still exits 4" "4" "$RUN_RC"
if has "$GATE_OUT" '^K001  ch02  Operator definition$'; then
  ok "and carries the entry for the construct it says was not written"
else
  nope "and carries the entry for the construct it says was not written"
fi
if has "$GATE_OUT" 'what you wrote says'; then
  nope "and no miss row, since the value was right"
else
  ok "and no miss row, since the value was right"
fi

echo
echo "-- neither layer can refuse a grade --"
# A delivered practice tree can arrive without either file and every rep in
# it still grades, because an explanation is not a verdict. That is the same
# posture an absent field 7 has.
RUN_RC=0
GONE_OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" \
  --misses "$TMPROOT/no-such-misses.tsv" --sheet "$TMPROOT/no-such-sheet.md" \
  -- R001 '[w \in Wagons |-> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "both files missing is still the verdict channel's own code" "10" "$RUN_RC"
if has "$GONE_OUT" '^the answer +\[Wagons -> Tracks\]$'; then
  ok "and the value block is unaffected"
else
  nope "and the value block is unaffected"
fi
if has "$GONE_OUT" 'nothing was graded'; then
  nope "and a missing explanation file is never a could-not-run"
else
  ok "and a missing explanation file is never a could-not-run"
fi

# Quiet is the status line and nothing else, which has to keep holding now
# that there are two more sections below it.
RUN_RC=0
QUIET_OUT=$("$RUNNER" --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" --sheet "$SHEET" \
  -q R001 '[w \in Wagons |-> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "quiet is still one line with both layers wired" "1" "$(wc -l <<<"$QUIET_OUT")"

echo
echo "-- the mutants for the two layers --"

# M6. the sheet entry never prints. The column-0 call is the one on the wrong
# answer path; the indented one belongs to the construct-gate refusal.
# shellcheck disable=SC2016
if mutate sheet-dropped 's|^show_sheet "\$CONSTRUCT"$|:|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  if has "$RUN_OUT" '^K050  ch06'; then
    nope "control: a runner that stopped printing the sheet entry is DETECTED"
  else
    ok "control: a runner that stopped printing the sheet entry is DETECTED"
  fi
  if has "$RUN_OUT" 'what you wrote says'; then
    ok "and it fails the way the mutation says, the miss row still prints"
  else
    nope "and it fails the way the mutation says, the miss row still prints"
  fi
fi

# M7. the miss row never prints.
# shellcheck disable=SC2016
if mutate miss-dropped 's|^show_misconception "\$REP_ID"$|:|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  if has "$RUN_OUT" 'what you wrote says'; then
    nope "control: a runner that stopped printing the miss row is DETECTED"
  else
    ok "control: a runner that stopped printing the miss row is DETECTED"
  fi
  if has "$RUN_OUT" '^K050  ch06'; then
    ok "and it fails the way the mutation says, the sheet entry still prints"
  else
    nope "and it fails the way the mutation says, the sheet entry still prints"
  fi
fi

# M8. the normalisation stops normalising, so the match is back to text. The
# spaced-out answers have to stop reaching the row and the row's own spelling
# has to keep reaching it -- a mutant that broke BOTH would prove nothing
# about the rule, only that the lookup ran.
if mutate match-exact 's|^      return out$|      return s|'; then
  run_runner "$MUTANT" R001 '[w \in Wagons|->Tracks]'
  if has "$RUN_OUT" 'what you wrote says'; then
    nope "control: a runner matching text rather than tokens is DETECTED"
  else
    ok "control: a runner matching text rather than tokens is DETECTED"
  fi
  run_runner "$MUTANT" R001 '[w \in Wagons |-> Tracks]'
  if has "$RUN_OUT" 'what you wrote says'; then
    ok "and it fails the way the mutation says, the row's own spelling still hits"
  else
    nope "and it fails the way the mutation says, the row's own spelling still hits"
  fi
fi

echo
echo "== part 13: the shipped files, which the fixture deliberately stands in for =="
# ---------------------------------------------------------------------------
# Everything above runs against fixture copies, so a sheet or a miss table
# that stopped resolving at the path the runner ships with would pass every
# row of it. One live rep closes that, and the rest of this part is text over
# the real files.
#
# R107 is the rep the epic's measured table is taken over. Its construct is
# K050 and recall/MISSES.tsv carries a row for this answer, so one run proves
# both shipped defaults resolve.
# ---------------------------------------------------------------------------

LIVE_REPS="$REPO_ROOT/recall/REPS.tsv"
LIVE_MISSES="$REPO_ROOT/recall/MISSES.tsv"
LIVE_SHEET="$REPO_ROOT/drill/SHEET.md"

RUN_RC=0
LIVE_OUT=$("$RUNNER" R107 '[w \in Wagons |-> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "a live rep through the shipped defaults still grades" "10" "$RUN_RC"
if has "$LIVE_OUT" '^K050  ch06'; then
  ok "and drill/SHEET.md resolves at the path the runner ships with"
else
  nope "and drill/SHEET.md resolves at the path the runner ships with"
fi
if has "$LIVE_OUT" 'what you wrote says'; then
  ok "and so does recall/MISSES.tsv"
else
  nope "and so does recall/MISSES.tsv"
fi

# Every rep's construct has an entry, so no rep is quietly short a layer.
assert_eq "every construct in recall/REPS.tsv has a drill/SHEET.md entry" "" \
  "$(awk 'FNR == NR { if ($0 ~ /^- K[0-9][0-9][0-9]  /) { split($0, a, " "); have[a[2]] = 1 } next }
          { n = split($0, f, "\t"); if (f[1] == "REP" && !(f[3] in have)) print f[2] }' \
       "$LIVE_SHEET" "$LIVE_REPS")"
assert_eq "every rep id in recall/MISSES.tsv is a row of recall/REPS.tsv" "" \
  "$(awk -F'\t' 'NR == FNR && $1 == "REP" { have[$2] = 1; next }
                 $1 == "MISS" && !($2 in have) { print $2 }' "$LIVE_REPS" "$LIVE_MISSES")"
assert_eq "and the same holds inside the fixture" "" \
  "$(awk -F'\t' 'NR == FNR && $1 == "REP" { have[$2] = 1; next }
                 $1 == "MISS" && !($2 in have) { print $2 }' "$REPS" "$MISSES")"

# ---------------------------------------------------------------------------
# THE CONDITION UNDER WHICH NORMALISING IS SAFE, GATED RATHER THAN ASSERTED
# IN PROSE.
#
# Collapsing whitespace erases TLA+'s bullet-list alignment, which is the one
# place a run of spaces carries meaning: indentation groups a stacked /\ and
# \/ list. Re-grouping a list of ONE operator cannot change what it says,
# because both are associative. A row carrying BOTH is the shape where a
# learner's differently-grouped list could flatten onto it and be handed an
# explanation of something else, and there is no such row today.
# ---------------------------------------------------------------------------
assert_eq "no miss row mixes /\\ and \\/, which is what makes flattening safe" "" \
  "$(awk -F'\t' '$1 == "MISS" && index($3, "/\\") > 0 && index($3, "\\/") > 0 { print FILENAME ": " $2 }' \
       "$LIVE_MISSES" "$MISSES")"

# ---------------------------------------------------------------------------
# THE LENGTH BUDGET, held at the data rather than at the display.
#
# Bead tla-1sh7.5 cut a 40-line block to 17 and this bead adds two sections
# to it. Neither section is capped, because an explanation cut mid-sentence
# costs more than the line it saves, so what bounds the block instead is the
# length of what the two files carry. Measured over the shipped tables on
# 2026-10-16: the longest field 4 is R006's at 155 characters, which wraps to
# 3 lines, and the longest sheet body a rep reaches is K087's at 185, which
# wraps to 3. That puts the worst real block at 25 lines and the ordinary one
# at 21 to 24.
#
# 4 wrapped lines in either file would put a block past 26, so that is where
# the gate sits: close enough to today's worst to mean something, far enough
# not to fire on an ordinary rewrite.
# ---------------------------------------------------------------------------
# Read out of the runner rather than written down twice. A width that moved
# in one file and not the other would make this gate measure a block nobody
# is shown.
PROSE_WIDTH=$(awk -F= '/^PROSE_WIDTH=/ { print $2; exit }' "$RUNNER")
assert_ne "the runner still names a prose width for these two gates to use" "" "$PROSE_WIDTH"

# BOTH GATES BELOW ARE GUARDED ON THAT WIDTH, and the guard is not decoration.
# A runner with no PROSE_WIDTH leaves the variable empty, `fold` then refuses
# the column count and prints nothing, `wc -l` answers 0, and 0 is under
# every budget -- so both gates would report success over a measurement that
# never happened. Watched doing exactly that during this bead's red run.
wrapped_lines() { fold -s -w "$PROSE_WIDTH" <<<"$1" | wc -l; }

if [ -z "$PROSE_WIDTH" ]; then
  nope "no miss explanation wraps past 3 lines (not measured: no prose width)"
  nope "no sheet body a rep reaches wraps past 3 lines (not measured: no prose width)"
else
  LONG_MISS=""
  while IFS= read -r rep_id; do
    [ -n "$rep_id" ] || continue
    text=$(awk -F'\t' -v id="$rep_id" '$1 == "MISS" && $2 == id { print $4; exit }' "$LIVE_MISSES")
    n=$(wrapped_lines "$text")
    [ "$n" -ge 1 ] && [ "$n" -le 3 ] || LONG_MISS="$LONG_MISS $rep_id($n)"
  done < <(awk -F'\t' '$1 == "MISS" { print $2 }' "$LIVE_MISSES")
  assert_eq "no miss explanation wraps past 3 lines at the runner's prose width" "" "$LONG_MISS"

  LONG_SHEET=""
  while IFS= read -r k_id; do
    [ -n "$k_id" ] || continue
    body=$(awk -v want="$k_id" 'index($0, "- " want "  ") == 1 { getline b; sub(/^[ \t]+/, "", b); print b; exit }' "$LIVE_SHEET")
    n=$(wrapped_lines "$body")
    [ "$n" -ge 1 ] && [ "$n" -le 3 ] || LONG_SHEET="$LONG_SHEET $k_id($n)"
  done < <(awk -F'\t' '$1 == "REP" { print $3 }' "$LIVE_REPS" | sort -u)
  assert_eq "no sheet body a rep reaches wraps past 3 lines either" "" "$LONG_SHEET"
fi

echo
echo "== part 14: the session loop (bead tla-1sh7.11) =="
# ---------------------------------------------------------------------------
# WHAT THIS PART EXISTS FOR, and it is a defect rather than a feature.
#
# Until this bead the only invocation was `recall.sh <rep-id> <answer>`, and
# nothing printed a prompt. So finding out what a rep asked meant opening
# REPS.tsv, where field 5 sits on the same tab-delimited line as field 6, the
# canonical answer. Reading the question handed over the answer, which is the
# lookup this rung exists to replace: exposure without a retrieval attempt
# buys very little durability, and drill/study/CLAUDE.md cites the same
# finding for the same reason.
#
# The rows below are written against that, so each one names the half of the
# defect it closes rather than describing a feature.
#
# THE SESSION DRIVES THE SINGLE-REP INVOCATION RATHER THAN REPLACING IT. It
# re-enters the same script once per rep, so there is no second grading path
# to drift from the first, and every row of parts 1 to 13 still covers what a
# session grades. The only thing it suppresses is the prompt echo, because
# the session has already printed that line and read an answer under it.
# ---------------------------------------------------------------------------

SREPS="$FIXTURE/SESSION-REPS.tsv"
if [ ! -r "$SREPS" ]; then
  printf 'test-recall-runner.sh: missing %s\n' "$SREPS" >&2
  exit 1
fi

# An input file rather than a here-string, because a here-string appends a
# newline of its own and the number of lines a session reads is the thing
# several rows below count.
write_input() {
  local path="$1"; shift
  : >"$path"
  local line
  for line in "$@"; do printf '%s\n' "$line" >>"$path"; done
  printf '%s\n' "$path"
}

blank_input() {
  local n="$1" path="$TMPROOT/blanks-$1.txt" i
  : >"$path"
  for ((i = 0; i < n; i++)); do printf '\n' >>"$path"; done
  printf '%s\n' "$path"
}

# A SUB-TABLE rather than a flag that picks reps. The session needs no way to
# name one, and adding `--only` for the suite's convenience would put a rep
# selector in a learner's hands, which is one short step from the table dump
# this bead exists to close. `--reps` already points the runner at a table, so
# the suite writes the table it wants.
sub_reps() {
  local path="$1"; shift
  local want=" $* "
  awk -F'\t' -v want="$want" '$1 == "REP" && index(want, " " $2 " ") > 0' "$SREPS" >"$path"
  printf '%s\n' "$path"
}

SREPS_USE=""
SESS_OUT=""
SESS_RC=0
session() {
  local input="$1"; shift
  SESS_RC=0
  SESS_OUT=$("$RUNNER" --reps "${SREPS_USE:-$SREPS}" --env-dir "$ENV_DIR" --misses "$MISSES" \
    --sheet "$SHEET" --session "$@" <"$input" 2>&1) || SESS_RC=$?
}

# A prompt line is `<id>  <prompt>`. A graded rep leaves a `rep=` status line.
# They are counted separately because a skipped rep is prompted and not graded,
# and because a session with no --count prints one more prompt than it grades:
# the one the reader answered with EOF.
prompted_ids() { awk '/^S[0-9][0-9]  / { print $1 }' <<<"$1"; }
graded_ids()   { awk -F'[= ]' '/^rep=/ { print $2 }' <<<"$1"; }

k_index_of() {
  awk -F'\t' -v w="$1" '$1 == "REP" {
    if (!($3 in seen)) { seen[$3] = n++ }
    if ($2 == w) { print seen[$3]; exit }
  }' "$SREPS"
}
canon_of()   { awk -F'\t' -v w="$1" '$1 == "REP" && $2 == w { print $6; exit }' "$SREPS"; }

echo "-- a rep is served as a prompt, and its answer is not reachable from it --"
# ---------------------------------------------------------------------------
# THE RED LINE'S FIRST CLAUSE. The session prints the prompt and the canonical
# answer is not in anything it printed, and it names no file to open. A
# CORRECT answer is the sharp case: the feedback for one is the word
# "correct." and nothing else, so if the canonical appears anywhere in this
# transcript it was the serving that leaked it.
# ---------------------------------------------------------------------------
ONE=$(sub_reps "$TMPROOT/one.tsv" S15)
S15_CANON=$(canon_of S15)
S15_IN=$(write_input "$TMPROOT/s15.txt" "$S15_CANON")
SREPS_USE="$ONE"
session "$S15_IN" --count 1
assert_eq "a one-rep session exits 0, because a session is not a grade" "0" "$SESS_RC"
if has "$SESS_OUT" '^S15  every way the wagons could be parked, one track each$'; then
  ok "it prints the rep's prompt, which is the thing REPS.tsv was being opened for"
else
  nope "it prints the rep's prompt, which is the thing REPS.tsv was being opened for"
fi
# EVERYTHING PRINTED BEFORE THE READER HAD TO ANSWER, which is where the
# invariant lives. The whole transcript is the wrong surface and was watched
# being wrong: a piped session echoes the answer line, and a CORRECT answer
# is the canonical, so the canonical is in the transcript because the reader
# typed it. What must not happen is the canonical being on screen at the
# moment the answer is owed.
BEFORE_ANSWER=$(awk '/^> / { exit } { print }' <<<"$SESS_OUT")
assert_ne "the session printed something before asking for an answer" "" "$BEFORE_ANSWER"
if has "$BEFORE_ANSWER" '\[Wagons -> Tracks\]'; then
  nope "and the canonical answer is not among it, which is the whole defect"
else
  ok "and the canonical answer is not among it, which is the whole defect"
fi
if has "$SESS_OUT" 'REPS\.tsv|open the|look it up'; then
  nope "and it tells the reader no file to open, which is the other half of the leak"
else
  ok "and it tells the reader no file to open, which is the other half of the leak"
fi
assert_eq "and the typed answer is graded, through the same channel a single rep uses" \
  "rep=S15 rc=0 token=OK grade=correct" "$(awk '/^rep=/ { print; exit }' <<<"$SESS_OUT")"

echo
echo "-- a wrong answer gets the feedback block that already existed --"
WRONG_IN=$(write_input "$TMPROOT/wrong.txt" '[Tracks -> Wagons]')
session "$WRONG_IN" --count 1
assert_eq "a wrong answer in a session is the same grade a single rep gets" \
  "rep=S15 rc=10 token=ASSUMPTION_FAILED grade=incorrect" \
  "$(awk '/^rep=/ { print; exit }' <<<"$SESS_OUT")"
if has "$SESS_OUT" '^you typed +\[Tracks -> Wagons\]$'; then
  ok "and the dual value block, so nothing was reimplemented for the session"
else
  nope "and the dual value block, so nothing was reimplemented for the session"
fi
if has "$SESS_OUT" '^the answer +\[Wagons -> Tracks\]$'; then
  ok "and the canonical value, which is reachable only after an attempt"
else
  nope "and the canonical value, which is reachable only after an attempt"
fi
if has "$SESS_OUT" '^K050  ch06  function set$'; then
  ok "and the construct's sheet entry, layer 3, unchanged"
else
  nope "and the construct's sheet entry, layer 3, unchanged"
fi
assert_eq "and a wrong answer does not end the session either" "0" "$SESS_RC"

echo
echo "-- a further rep is served without the reader naming an id --"
# ---------------------------------------------------------------------------
# THE RED LINE'S LAST CLAUSE, and the whole of the flow-speed complaint. Three
# answers, three different reps, and the word that must not appear is a
# request for an id.
# ---------------------------------------------------------------------------
SREPS_USE=""
THREE_IN=$(write_input "$TMPROOT/three.txt" 'TRUE' 'FALSE' '3')
session "$THREE_IN" --count 3 --seed 11
assert_eq "three answers serve three reps" "3" "$(prompted_ids "$SESS_OUT" | wc -l)"
assert_eq "and all three are different reps" "3" \
  "$(prompted_ids "$SESS_OUT" | sort -u | wc -l)"
assert_eq "and three grades come back" "3" "$(graded_ids "$SESS_OUT" | wc -l)"
if has "$SESS_OUT" '[Rr]ep id|rep-id|which rep|enter an id'; then
  nope "and nothing in it asks the reader for an id"
else
  ok "and nothing in it asks the reader for an id"
fi

echo
echo "-- the walk: similar, never identical, and the same under one seed --"
# ---------------------------------------------------------------------------
# WHY NOT UNIFORM RANDOM. tla-1sh7.2 wrote two to six differently-phrased reps
# per construct so the FACT is retrieved rather than the sentence, and
# interleaving is stronger when consecutive items are similar enough to be
# confusable. Uniform random throws that away: it draws a set rep after a
# sequence rep as readily as after another set rep.
#
# WHY NOT BLOCKED EITHER. Two reps of one construct back to back is the lag-0
# case, where the second is recognition rather than retrieval, because the
# answer was typed a second ago.
#
# SO: NEAR, BUT NEVER THE SAME. The next rep comes from a construct within the
# window of the one just served and never from the construct itself. The
# remaining reps of a construct stay in the pool and are reached again after
# an intervening rep or two, which is the lag the blocked order has none of.
#
# recall/REPS.tsv is sorted by family, then construct, and the reps for one
# construct are contiguous, so file-order adjacency IS family adjacency at 33
# of the 36 adjacent construct pairs. That is what lets the window be computed
# from the delivered table alone, with no drill/INVENTORY.md in the tree.
# ---------------------------------------------------------------------------

walk_violations() {
  local out="$1" mode="$2" prev=-1 id ki d bad=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    ki=$(k_index_of "$id")
    if [ "$prev" -ge 0 ]; then
      d=$(( ki - prev ))
      [ "$d" -lt 0 ] && d=$(( -d ))
      if [ "$mode" = "same" ]; then
        [ "$d" -eq 0 ] && bad="$bad $id"
      else
        [ "$d" -gt 2 ] && bad="$bad $id(d=$d)"
      fi
    fi
    prev="$ki"
  done <<<"$(prompted_ids "$out")"
  printf '%s\n' "$bad"
}

SAME_RUN=""
for seed in 1 2 3 4 5 6; do
  session "$(blank_input 6)" --count 6 --seed "$seed"
  v=$(walk_violations "$SESS_OUT" same)
  [ -n "$v" ] && SAME_RUN="$SAME_RUN seed$seed:$v"
done
assert_eq "no two reps in a row drill the same construct, over six seeds" "" "$SAME_RUN"

# The window itself is pinned at ONE seed rather than asserted across them,
# the way part 1 pins a measured exit code. A walk that runs the pool of a
# construct's neighbours dry has to widen, and whether a given seed does that
# is a fact about that seed, not about the rule.
session "$(blank_input 6)" --count 6 --seed 11
assert_eq "at seed 11 every step stays inside the window of two constructs" "" \
  "$(walk_violations "$SESS_OUT" window)"
SEED11_ORDER=$(prompted_ids "$SESS_OUT" | tr '\n' ' ')
assert_ne "and the walk at that seed is not empty, so the row above is not vacuous" \
  "" "$SEED11_ORDER"

session "$(blank_input 6)" --count 6 --seed 11
assert_eq "the same seed gives the same order, so a session is reproducible" \
  "$SEED11_ORDER" "$(prompted_ids "$SESS_OUT" | tr '\n' ' ')"

DISTINCT_ORDERS=""
for seed in 1 2 3 4 5; do
  session "$(blank_input 6)" --count 6 --seed "$seed"
  DISTINCT_ORDERS="$DISTINCT_ORDERS$(prompted_ids "$SESS_OUT" | tr '\n' ' ')
"
done
assert_ne "and different seeds do not all give one order, so the draw is a draw" \
  "1" "$(sort -u <<<"$DISTINCT_ORDERS" | wc -l)"

# A rep is never served twice in one session, which is what makes the pool
# shrink and the session end.
session "$(blank_input 16)" --count 16 --seed 3
assert_eq "no rep is served twice in a session" "16" \
  "$(prompted_ids "$SESS_OUT" | sort -u | wc -l)"

echo
echo "-- how a session ends: a count, EOF, and the table running out --"
# ---------------------------------------------------------------------------
# A loop that cannot be left is worse than no loop, so there are three exits
# and all three are rows here.
# ---------------------------------------------------------------------------

session "$(blank_input 3)" --count 3 --seed 2
assert_eq "--count stops at the count" "3" "$(prompted_ids "$SESS_OUT" | wc -l)"
assert_eq "and exits 0" "0" "$SESS_RC"
if has "$SESS_OUT" '^3 reps?\b'; then
  ok "and the session ends on a tally rather than on silence"
else
  nope "and the session ends on a tally rather than on silence"
fi

# EOF with no count, over the whole table, so the pool cannot end the session
# first and EOF is what does. THE DANGLING PROMPT IS THE POINT: the session
# prints a rep and only then discovers there is nothing left to read, so a
# reader who answers with Ctrl-D has one question on screen they did not
# answer. Three prompts, two grades.
SREPS_USE=""
session "$(write_input "$TMPROOT/two.txt" 'TRUE' 'TRUE')" --seed 2
assert_eq "EOF ends a session cleanly, at 0" "0" "$SESS_RC"
assert_eq "and two answers graded two reps" "2" "$(graded_ids "$SESS_OUT" | wc -l)"
assert_eq "and the prompt the reader answered with EOF is on screen, unanswered" "3" \
  "$(prompted_ids "$SESS_OUT" | wc -l)"
if has "$SESS_OUT" '^2 reps?\b'; then
  ok "and the tally counts what was answered, not what was prompted"
else
  nope "and the tally counts what was answered, not what was prompted"
fi

# The tally's three numbers. S01 and S05 are both TRUE and S03 is 3, so
# answering TRUE twice and then declining gives one right, one wrong and one
# skip whichever order the walk takes -- EXCEPT when S03 comes last, which is
# why the seed is pinned and the tally is a measured constant rather than a
# property.
SREPS_USE=$(sub_reps "$TMPROOT/mixed.tsv" S01 S03 S05)
MIXED_IN=$(write_input "$TMPROOT/mixed.txt" 'TRUE' 'TRUE' '')
session "$MIXED_IN" --count 3 --seed 4
assert_eq "a session with a right, a wrong and a skip exits 0" "0" "$SESS_RC"
if has "$SESS_OUT" '1 right'; then
  ok "the tally names the right answers"
else
  nope "the tally names the right answers"
fi
if has "$SESS_OUT" '1 wrong'; then
  ok "and the wrong ones"
else
  nope "and the wrong ones"
fi
if has "$SESS_OUT" '1 skipped'; then
  ok "and the skipped ones, which are neither"
else
  nope "and the skipped ones, which are neither"
fi

# A blank line is a skip, and a skip SHOWS the answer. A reader who has
# declined to attempt is past the point the attempt was protecting, and
# withholding it there teaches nothing. It costs no TLC run.
SREPS_USE="$ONE"
SKIP_IN=$(write_input "$TMPROOT/skip.txt" '')
session "$SKIP_IN" --count 1
if has "$SESS_OUT" '\[Wagons -> Tracks\]'; then
  ok "a skipped rep shows its answer, since the reader declined the attempt"
else
  nope "a skipped rep shows its answer, since the reader declined the attempt"
fi
assert_eq "and a skip is not graded, so it runs no TLC at all" "0" \
  "$(graded_ids "$SESS_OUT" | wc -l)"

# The pool running out. 16 reps in the table, 99 asked for.
SREPS_USE=""
session "$(blank_input 99)" --count 99 --seed 5
assert_eq "a count past the table serves every rep once and stops" "16" \
  "$(prompted_ids "$SESS_OUT" | wc -l)"
if has "$SESS_OUT" 'no reps left|every rep|ran out'; then
  ok "and says the table ran out rather than ending on a count it did not reach"
else
  nope "and says the table ran out rather than ending on a count it did not reach"
fi

# Empty stdin. One prompt goes out before the read can discover there is
# nothing there, and that is the end of it.
RUN_RC=0
EMPTY_SESS=$("$RUNNER" --reps "$SREPS" --env-dir "$ENV_DIR" --misses "$MISSES" \
  --sheet "$SHEET" --session </dev/null 2>&1) || RUN_RC=$?
assert_eq "empty stdin ends the session at 0" "0" "$RUN_RC"
assert_eq "and serves one prompt, never a walk of the table" "1" \
  "$(prompted_ids "$EMPTY_SESS" | wc -l)"
assert_eq "and grades nothing" "0" "$(graded_ids "$EMPTY_SESS" | wc -l)"

echo
echo "-- the session is stateless, which is what the delivery rests on --"
# ---------------------------------------------------------------------------
# scripts/deliver-recall.sh overwrites every file it delivers, and the header
# justifying that says no file in this channel is learner-owned. A session
# that recorded progress would make that false, and the delivery would then
# overwrite a learner's own file in a tree that is not a git repo.
#
# harness/test-recall-gate.sh already snapshots a recall tree around a SINGLE
# rep. This row is the session's half of the same claim, and it belongs here
# because the session is this suite's subject.
# ---------------------------------------------------------------------------
STATE_TREE="$TMPROOT/stateless/recall"
mkdir -p "$STATE_TREE/env"
cp "$RUNNER" "$STATE_TREE/recall.sh"
chmod +x "$STATE_TREE/recall.sh"
cp "$SREPS" "$STATE_TREE/REPS.tsv"
cp "$MISSES" "$STATE_TREE/MISSES.tsv"
cp "$ENV_DIR"/*.tla "$STATE_TREE/env/"
STATE_BEFORE=$(find "$STATE_TREE" | LC_ALL=C sort)
"$STATE_TREE/recall.sh" --session --count 4 --seed 6 \
  <"$(write_input "$TMPROOT/state.txt" 'TRUE' '' 'FALSE' '1..3')" >/dev/null 2>&1 || true
STATE_AFTER=$(find "$STATE_TREE" | LC_ALL=C sort)
assert_eq "a whole session writes nothing into the runner's own tree" \
  "$STATE_BEFORE" "$STATE_AFTER"
assert_eq "and no progress file is named anywhere in the runner" "" \
  "$(grep -oE 'PROGRESS\.tsv|LAST-SERVED|\.recall-state' "$RUNNER" | sort -u | tr '\n' ' ' | sed 's/ $//')"

echo
echo "-- there is no mode that prints the table --"
# ---------------------------------------------------------------------------
# A flag that listed the reps would be the leak this bead closes, wearing a
# flag. The usage text is the surface somebody would reach for, so that is
# where the row sits.
# ---------------------------------------------------------------------------
# `has` already passes `--` to grep, so a second one here reaches it as the
# PATTERN. `--` matches every long flag in the usage text, which made the
# first row of this pair report a dump flag that is not there and the second
# report a session flag that was not there yet. Both were watched doing it.
HELP_OUT=$("$RUNNER" --help 2>&1) || true
if has "$HELP_OUT" '[-][-](list|reps-list|dump|table|show-reps|browse)'; then
  nope "no flag in the usage text lists or dumps the rep table"
else
  ok "no flag in the usage text lists or dumps the rep table"
fi
if has "$HELP_OUT" '[-][-]session'; then
  ok "and the session is named there, so the usage text is current"
else
  nope "and the session is named there, so the usage text is current"
fi
# THE USAGE TEXT IS A LINE RANGE AND NOTHING GATED IT. `usage()` is a
# `sed -n 'A,Bp'` over this script's own header, so a line added to the
# OPTIONS block silently truncates the help. These two rows pin the first and
# last line of what it prints, which is what the range is for.
if has "$HELP_OUT" '^# recall\.sh: grade'; then
  ok "the usage text still starts at the script's own first line"
else
  nope "the usage text still starts at the script's own first line"
fi
if has "$HELP_OUT" '^#   -h, --help'; then
  ok "and still ends on the last flag, so the range did not drift"
else
  nope "and still ends on the last flag, so the range did not drift"
fi

echo
echo "-- the single-rep invocation is untouched --"
RUN_RC=0
OUT=$("$RUNNER" --reps "$SREPS" --env-dir "$ENV_DIR" --session -- S15 '[Wagons -> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "--session with a rep id is a usage error, not a quiet half-mode" "2" "$RUN_RC"

RUN_RC=0
NOPROMPT_OUT=$("$RUNNER" --reps "$SREPS" --env-dir "$ENV_DIR" --misses "$MISSES" \
  --sheet "$SHEET" --no-prompt -- S15 '[Wagons -> Tracks]' 2>&1) || RUN_RC=$?
assert_eq "--no-prompt still grades, and with the same code" "0" "$RUN_RC"
if has "$NOPROMPT_OUT" '^S15  every way'; then
  nope "and it drops the prompt echo, which is the one line a session has already printed"
else
  ok "and it drops the prompt echo, which is the one line a session has already printed"
fi
RUN_RC=0
PROMPT_OUT=$("$RUNNER" --reps "$SREPS" --env-dir "$ENV_DIR" --misses "$MISSES" \
  --sheet "$SHEET" -- S15 '[Wagons -> Tracks]' 2>&1) || RUN_RC=$?
if has "$PROMPT_OUT" '^S15  every way'; then
  ok "and without it the prompt echo is still there, so nothing moved for single reps"
else
  nope "and without it the prompt echo is still there, so nothing moved for single reps"
fi
assert_eq "and the two differ by exactly that one line" "1" \
  "$(( $(wc -l <<<"$PROMPT_OUT") - $(wc -l <<<"$NOPROMPT_OUT") ))"

echo
echo "-- what a piped session and a terminal session differ by --"
# ---------------------------------------------------------------------------
# A terminal echoes what is typed and a pipe does not, so a piped transcript
# would read as a prompt character with the feedback jammed against it and no
# record of what was answered. The session echoes the answer when stdin is not
# a terminal, which is the only behaviour that is conditional on the terminal
# anywhere in this script.
# ---------------------------------------------------------------------------
SREPS_USE="$ONE"
session "$(write_input "$TMPROOT/echo.txt" '[Tracks -> Wagons]')" --count 1
SREPS_USE=""
if has "$SESS_OUT" '^> \[Tracks -> Wagons\]$'; then
  ok "a piped session echoes the answer, so the transcript reads as the terminal does"
else
  nope "a piped session echoes the answer, so the transcript reads as the terminal does"
fi
assert_eq "and the echo is the only thing keyed on a terminal" "1" \
  "$(grep -cE '\[ -t 0 \]|\[\[ -t 0 \]\]' "$RUNNER")"

echo
echo "-- the session fixture's own shape --"
assert_eq "every SESSION-REPS row has six fields" "" \
  "$(awk -F'\t' '$1 == "REP" && NF != 6 { print $2 }' "$SREPS")"
assert_eq "sixteen reps over eight constructs, two each" "16 8" \
  "$(awk -F'\t' '$1 == "REP" { n++; k[$3] = 1 } END { print n, length(k) }' "$SREPS")"
assert_eq "the reps for one construct are contiguous, as they are in the shipped table" "" \
  "$(awk -F'\t' '$1 == "REP" { if ($3 != prev) { runs[$3]++; prev = $3 } }
                 END { for (k in runs) if (runs[k] > 1) print k }' "$SREPS")"
assert_eq "every construct resolves to a drill/INVENTORY.md row" "" \
  "$(awk -F'\t' 'NR == FNR && $1 == "ROW" { have[$2] = 1; next }
                 $1 == "REP" && !($3 in have) { print $2 }' "$REPO_ROOT/drill/INVENTORY.md" "$SREPS")"
assert_eq "no prompt in it carries TLA+ notation" "" \
  "$(awk -F'\t' '$1 == "REP" && $5 ~ /[|<>\[\]{}\\]/ { print $2 }' "$SREPS")"
assert_eq "every rep names the fixture environment, which exists" "" \
  "$(awk -F'\t' '$1 == "REP" && $4 != "shunting" { print $2 }' "$SREPS")"

# THE SHIPPED TABLE'S OWN SHAPE, which is what makes file-order adjacency a
# family proxy. The walk reads no family anywhere, so this is the measurement
# the choice rests on rather than a check of the walk.
assert_eq "the shipped rep table keeps its constructs contiguous too" "" \
  "$(awk -F'\t' '$1 == "REP" { if ($3 != prev) { runs[$3]++; prev = $3 } }
                 END { for (k in runs) if (runs[k] > 1) print k }' "$LIVE_REPS")"
assert_eq "and its families are four unbroken runs, so adjacency is family adjacency" "4" \
  "$(awk -F'\t' 'FNR == NR && $1 == "ROW" { fam[$2] = $3; next }
                 $1 == "REP" { f = fam[$3]; if (f != prev) { n++; prev = f } }
                 END { print n }' "$REPO_ROOT/drill/INVENTORY.md" "$LIVE_REPS")"

echo
echo "-- the mutants for the walk and for the serving --"
# THE SED PATTERNS BELOW ARE NOT ANCHORED TO AN INDENT, unlike M1 to M8's.
# Both target lines sit several blocks deep inside a function, so an anchored
# pattern would be pinned to a nesting level that a later edit can move, and a
# mutation that stops applying is a control that silently goes missing rather
# than a row that goes red. See the sentinel row under the mutants.

# M9. the walk stops excluding the construct it just served, which is the
# blocked order the window exists to avoid.
#
# IT RUNS OVER A TWO-CONSTRUCT TABLE AND OVER TEN SEEDS, and both halves are
# the lesson. Over the full sixteen-rep table at one seed the mutant repeated
# nothing in six draws and the control passed over a mutation that had
# applied -- the candidate set simply did not happen to offer the repeat.
# Two constructs at two reps each makes the real walk a strict alternation
# whatever the seed, and makes the mutant's repeat a coin toss per step, so
# ten seeds settle it.
# shellcheck disable=SC2016
if mutate walk-blocked 's|\[ "\$WALK_KI" = "\$WALK_CUR_K" \] && continue|:|'; then
  M9_REPS=$(sub_reps "$TMPROOT/alternate.tsv" S01 S02 S03 S04)
  repeats_over_seeds() {
    local script="$1" seed out id ki prev found=""
    for seed in 1 2 3 4 5 6 7 8 9 10; do
      out=$("$script" --reps "$M9_REPS" --env-dir "$ENV_DIR" --misses "$MISSES" \
        --sheet "$SHEET" --session --count 4 --seed "$seed" <"$(blank_input 4)" 2>&1) || true
      prev=-1
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        ki=$(k_index_of "$id")
        [ "$prev" = "$ki" ] && found="$found seed$seed:$id"
        prev="$ki"
      done <<<"$(prompted_ids "$out")"
    done
    printf '%s\n' "$found"
  }
  assert_eq "the real walk alternates the two constructs at every one of ten seeds" \
    "" "$(repeats_over_seeds "$RUNNER")"
  assert_ne "control: a walk that stopped excluding the served construct is DETECTED" \
    "" "$(repeats_over_seeds "$MUTANT")"
fi

# M10. the prompt is never printed, so a session serves nothing a reader can
# answer. This is the mutant for the defect itself.
# shellcheck disable=SC2016
if mutate prompt-dropped 's|printf .%s  %s.n. "\$WALK_ID" "\$WALK_PROMPT"|:|'; then
  M10_OUT=$("$MUTANT" --reps "$SREPS" --env-dir "$ENV_DIR" --misses "$MISSES" --sheet "$SHEET" \
    --session --count 2 --seed 1 <"$(blank_input 2)" 2>&1) || true
  assert_eq "control: a session that stopped printing the prompt is DETECTED" "0" \
    "$(prompted_ids "$M10_OUT" | wc -l)"
fi

# A MUTATION THAT DID NOT APPLY NEEDS NO ROW OF ITS OWN HERE. mutate() calls
# nope from the main shell now, so its refusal is a FAIL row like any other
# and it names the mutant. See the function's own header.

echo
printf 'test-recall-runner.sh: %d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ] || exit 1
exit 0
