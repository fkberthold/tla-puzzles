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

for required in "$RUNNER" "$VERDICT" "$REPS" "$CASES" "$ENV_DIR"; do
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
  RUN_OUT=$("$script" --reps "$REPS" --env-dir "$ENV_DIR" -- "$rep" "$answer" 2>&1) || RUN_RC=$?
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

# The three verdict.sh tokens a grading run can reach. Named here rather than
# scraped, so the suite asserts the pairing of code to token and not just the
# code. Anything else is a row this fixture does not carry.
token_for() {
  case "$1" in
    0)   printf 'OK\n' ;;
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
mkdir -p "$MIRROR/harness" "$MIRROR/recall"
ln -s "$VERDICT" "$MIRROR/harness/verdict.sh"

# mutate <name> <sed-script>: a copy of the real runner with one line changed,
# placed in a mirror root so it still resolves the verdict channel.
#
# Separate `local` statements, because `local a=$1 b=$a` reads $a as unbound
# under `set -u` on this bash.
mutate() {
  local name="$1"
  local script="$2"
  local out="$MIRROR/recall/$name.sh"
  sed "$script" "$RUNNER" >"$out"
  chmod +x "$out"
  if [ "$(cat "$out")" = "$(cat "$RUNNER")" ]; then
    nope "mutant $name changed nothing, so its control below is vacuous"
    return 1
  fi
  printf '%s\n' "$out"
}

# Every sed script is single-quoted on purpose: both sides of the substitution
# are literal lines of the runner's source, so an expansion here would match
# nothing and the mutation would silently be a no-op. mutate() fails loudly in
# that case, which is the other half of the guard.

# M1. the reported code stops being the one verdict.sh returned.
# shellcheck disable=SC2016
M1=$(mutate inferred-code 's|^GRADE_RC="\$VERDICT_RC"$|GRADE_RC=0|') || M1=""
if [ -n "$M1" ]; then
  run_runner "$M1" R001 '[w \in Wagons |-> Tracks]'
  assert_ne "control: a runner reporting its own code is DETECTED by part 1's code row" \
    "10" "$RUN_RC"
  assert_eq "and it fails the way the mutation says, a wrong answer exiting 0" "0" "$RUN_RC"
fi

# M2. rc 150 is reported as a wrong answer rather than as its own thing.
M2=$(mutate parse-called-wrong 's|^  150) GRADE="parse-error" ;;$|  150) GRADE="incorrect" ;;|') || M2=""
if [ -n "$M2" ]; then
  run_runner "$M2" R001 '[Wagons ->'
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
M3=$(mutate lost-value-block 's|^show_value "the answer" "Canon" "\$CANON"$|:|') || M3=""
if [ -n "$M3" ]; then
  run_runner "$M3" R001 '[w \in Wagons |-> Tracks]'
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
M4=$(mutate count-claimed 's|^  if \[ "\$VERDICT_RC" != "0" \]; then$|  if false; then|') || M4=""
if [ -n "$M4" ]; then
  run_runner "$M4" R001 '[w \in Wagons |-> Tracks]'
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

# An answer beginning with a dash is reachable through `--`, which is the only
# reason the argument loop has a second half.
run_runner "$RUNNER" R001 '-1'
assert_eq "an answer beginning with a dash is graded, not read as a flag" "10" "$RUN_RC"

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
# harness/verdict.sh is centrally owned. The runner calls it and must never
# write to it.
if has "$SRC" '> *"?\$\{?VERDICT'; then
  nope "the runner never writes to the verdict channel it calls"
else
  ok "the runner never writes to the verdict channel it calls"
fi
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

assert_eq "every REP row has six fields" "" \
  "$(awk -F'\t' '$1 == "REP" && NF != 6 { print $2 }' "$REPS")"
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
printf 'test-recall-runner.sh: %d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ] || exit 1
exit 0
