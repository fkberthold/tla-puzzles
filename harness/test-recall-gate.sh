#!/usr/bin/env bash
# test-recall-gate.sh: executable spec for harness/recall-gate.sh and for
# scripts/deliver-recall.sh (bead tla-1sh7.4, epic tla-1sh7).
#
# WHAT IT PINS
#
#   Each of the gate's five checks goes RED on a corpus that breaks it, and
#   the finding carries the code that names which one broke. The bead's RED
#   line names three of those by hand (a corrupted canonical, a miss row
#   changed to a correct answer, and a prompt edited to contain its own answer
#   notation) and parts 2 and 3 run all five.
#
#   The two tiers mean two different things. `--static-only` over a clean
#   corpus exits 0 and SAYS what it did not measure. `--no-tlc` over the same
#   corpus exits 99, because it was asked to measure and did not.
#
#   The shipped recall/ corpus passes all five checks, over the real 120 reps
#   and 30 miss rows, through the real model checker.
#
#   scripts/deliver-recall.sh under --check writes nothing, names every path a
#   real delivery would write, and says at the destination's own resolved
#   paths whether the delivered runner could grade at all.
#
#   recall/recall.sh writes nothing into its own tree, which is the claim the
#   delivery script's always-overwrite rule rests on.
#
# ---------------------------------------------------------------------------
# WHY THE DELIVERY SCRIPT IS IN THIS SUITE RATHER THAN IN ONE OF ITS OWN
#
# Every sibling delivery script has a suite named after it:
# harness/test-deliver-drill.sh, -problems, -completion, -exercises. This one
# does not, and the reason is a footprint rather than a judgment. Bead
# tla-1sh7.4 declares four files and `harness/test-deliver-recall.sh` is not
# among them. Shipping the script with NO suite was the other option and it is
# worse: a delivery script with nothing gating it is the exact shape that
# deleted 39 delivered files on 2026-10-02.
#
# So part 6 lives here, named for what it covers rather than folded into the
# gate parts, and splitting it into a suite of its own is follow-up work.
#
# ---------------------------------------------------------------------------
# THE FIXTURE IS BUILT HERE, NOT UNDER harness/fixtures/
#
# harness/fixtures/recall/ exists and belongs to harness/test-recall-runner.sh.
# Reusing it would couple two suites to one set of rows, which is what that
# suite's own header warns about where it explains why it does not pin block
# lengths against the shipped drill/SHEET.md. So this suite writes a four-rep
# corpus and a three-row inventory into its temp tree and owns them.
#
# THE TREE IS A MIRROR ROOT, and it has to be. recall/recall.sh resolves its
# verdict channel as ${REPO_ROOT}/harness/verdict.sh where REPO_ROOT is the
# PARENT of the directory it sits in, so a copy anywhere else dies at exit 3
# for a reason that has nothing to do with the corpus. The mirror carries
# recall/ beside a harness/ holding a symlink to the real verdict channel.
# Nothing is written into the repo.
#
# ---------------------------------------------------------------------------
# WHY THERE IS NO FAST ROW
#
# harness/recall-gate.sh has a `--static-only` tier that starts no JVM, so a
# fast registry row over it is available and is deliberately not taken: bead
# tla-1sh7.4 registers two suites and this is one of them. Part 4 is the
# expensive part (the real corpus is 120 canonical answers and 30 wrong ones,
# one TLC grading run each) and it is the part the bead exists for.
#
# Usage:  harness/test-recall-gate.sh
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

# A here-string, never `producer | grep -q`. Under pipefail an early-exiting
# consumer closes the pipe, the producer takes SIGPIPE, the pipeline reports
# 141, and inside an `if` that is merely falsy -- so a PRESENT pattern reports
# as ABSENT. harness/test-pipefail.sh is the gate, and this is the blessed form.
has() { grep -qE -- "$2" <<<"$1"; }

assert_says() {
  if has "$3" "$2"; then
    ok "$1"
  else
    nope "$1"
    printf '          wanted a line matching: %s\n' "$2"
  fi
}

assert_silent() {
  if has "$3" "$2"; then
    nope "$1"
    printf '          did not want a line matching: %s\n' "$2"
  else
    ok "$1"
  fi
}

GATE="$REPO_ROOT/harness/recall-gate.sh"
DELIVER="$REPO_ROOT/scripts/deliver-recall.sh"
RUNNER="$REPO_ROOT/recall/recall.sh"
VERDICT="$REPO_ROOT/harness/verdict.sh"
TEST_RUNNER="$REPO_ROOT/scripts/test"
LIVE_RECALL="$REPO_ROOT/recall"
LIVE_INVENTORY="$REPO_ROOT/drill/INVENTORY.md"

for required in "$GATE" "$DELIVER" "$RUNNER" "$VERDICT" "$TEST_RUNNER" \
                "$LIVE_RECALL" "$LIVE_INVENTORY"; do
  if [ ! -e "$required" ]; then
    printf 'test-recall-gate.sh: missing %s\n' "$required" >&2
    exit 1
  fi
done

if ! command -v tlc >/dev/null 2>&1; then
  echo "test-recall-gate.sh: tlc is not on the path, so nothing was checked." >&2
  exit 1
fi

TMPROOT=$(mktemp -d -t tla_recall_gate.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

TAB=$'\t'

# ---------------------------------------------------------------------------
# build_mirror <dir>: a mirror root at <dir> carrying recall/ and a harness/
# holding a symlink to the real verdict channel.
#
# The corpus is four reps over one environment and two miss rows. Every row is
# written with printf and an explicit $TAB rather than through a heredoc, so a
# tab that an editor turned into spaces is a syntax error here rather than a
# field shift nobody sees.
# ---------------------------------------------------------------------------
build_mirror() {
  local root="$1"
  mkdir -p "$root/harness" "$root/recall/env"
  ln -sf "$VERDICT" "$root/harness/verdict.sh"
  cp "$RUNNER" "$root/recall/recall.sh"
  chmod +x "$root/recall/recall.sh"

  {
    printf '%s\n' '\* mini -- the fixture environment for harness/test-recall-gate.sh.'
    printf '%s\n' '\* A FRAGMENT: no header, no EXTENDS, no trailing ====.'
    printf '%s\n' 'Wagons == {"a", "b", "c"}'
    printf '%s\n' 'Tracks == 1..3'
    printf '%s\n' 'Parking == [a |-> 3, b |-> 3, c |-> 3]'
  } >"$root/recall/env/mini.tla"

  {
    printf '%s\n' '# A fixture rep table. Four rows over one environment.'
    printf 'REP%sF001%sK001%smini%sthe set of every wagon in the yard%sWagons\n' \
      "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
    printf 'REP%sF002%sK002%smini%show many wagons the yard holds%sCardinality(Wagons)\n' \
      "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
    printf 'REP%sF003%sK003%smini%severy way of standing each wagon on one track%s[Wagons -> Tracks]\n' \
      "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
    printf 'REP%sF004%sK002%smini%sa word for where wagon a stands: near on the first track, middle on the second, far on anything else%sCASE Parking.a = 1 -> "near" [] Parking.a = 2 -> "middle" [] OTHER -> "far"\n' \
      "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  } >"$root/recall/REPS.tsv"

  # Row two is the rc-10 band's SECOND meaning, planted deliberately. See
  # part 3's rc-10 section.
  {
    printf '%s\n' '# A fixture miss table. Two rows.'
    printf 'MISS%sF003%s[w \\in Wagons |-> Tracks]%sThat is one standing, and what it gives back for every wagon is the whole set of tracks rather than one track.\n' \
      "$TAB" "$TAB" "$TAB"
    printf 'MISS%sF004%sCASE Parking.a = 1 -> "near" [] Parking.a = 2 -> "middle"%sThat leaves the yard with no word for anything but the first two tracks, and wagon a is on neither.\n' \
      "$TAB" "$TAB" "$TAB"
  } >"$root/recall/MISSES.tsv"

  # THE ROW ABOVE SHIPPED ONE $TAB SHORT ON ITS FIRST DRAFT, and the gate is
  # what found it: a three-field row reads as an empty field 4 with the
  # explanation glued onto the end of the wrong answer, so it came back
  # MISS-NO-EXPLANATION and MISS-NOT-GRADED at rc 150. Worth keeping as a note
  # because it is the exact failure recall/REPS.tsv's own header warns about,
  # arriving in the suite that checks for it.
}

INVENTORY="$TMPROOT/INVENTORY.md"
{
  printf '%s\n' '# A fixture construct inventory. The gate reads field 1 and field 2.'
  printf 'ROW%sK001%ssets%sSet literal%sfixture:1%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'ROW%sK002%score%sCardinality%sfixture:2%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'ROW%sK003%sfunctions%sFunction set%sfixture:3%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
} >"$INVENTORY"

# ---------------------------------------------------------------------------
# mutant <name>: a fresh mirror at $TMPROOT/<name>, echoed. The caller breaks
# one thing in it.
# ---------------------------------------------------------------------------
mutant() {
  local d="$TMPROOT/$1"
  rm -rf "$d"
  build_mirror "$d"
  printf '%s\n' "$d"
}

# run_gate <root> [args...] -> GATE_OUT, GATE_RC
GATE_OUT=""
GATE_RC=0
run_gate() {
  local root="$1"; shift
  GATE_RC=0
  GATE_OUT=$("$GATE" --inventory "$INVENTORY" "$@" "$root/recall" 2>&1) || GATE_RC=$?
}

echo "== part 1: the two tiers, and the flags that pick them =="
# ---------------------------------------------------------------------------
# THE TWO TIERS ARE TWO QUESTIONS, NOT A VOLUME KNOB. --static-only was asked
# for the static checks only and a clean run answers that completely, so it
# exits 0. --no-tlc was asked whether every row still grades and did not find
# out, so it can never exit 0. Asking both is a usage error rather than a
# guess. The shape is harness/completion-gate.sh's.
# ---------------------------------------------------------------------------
CLEAN=$(mutant clean)

run_gate "$CLEAN" --static-only -q
assert_eq "--static-only over a clean corpus exits 0" "0" "$GATE_RC"
assert_says "and says so" 'VERDICT OK' "$GATE_OUT"
assert_says "and STATES what it did not measure" \
  'NOT COVERED HERE' "$GATE_OUT"
assert_says "and names the flag that waived it, on the same line as the skip" \
  'skipped \(--static-only\)' "$GATE_OUT"

run_gate "$CLEAN" --no-tlc -q
assert_eq "--no-tlc over the same clean corpus exits 99, never 0" "99" "$GATE_RC"
assert_says "and says CHECK_DID_NOT_RUN" 'VERDICT CHECK_DID_NOT_RUN' "$GATE_OUT"
assert_says "and names the canonical check it did not run" \
  '^UNCHECKED .*every-canonical-scores-0' "$GATE_OUT"
assert_says "and the miss check too" \
  '^UNCHECKED .*every-miss-scores-10' "$GATE_OUT"
assert_silent "and claims no mode block, which belongs to --static-only" \
  'NOT COVERED HERE' "$GATE_OUT"

BOTH_RC=0
BOTH_OUT=$("$GATE" --no-tlc --static-only "$CLEAN/recall" 2>&1) || BOTH_RC=$?
assert_eq "the two tiers together are a usage error" "2" "$BOTH_RC"
assert_says "and the message says they are different questions" \
  'different questions' "$BOTH_OUT"

NOROOT_RC=0
NOROOT_OUT=$("$GATE" 2>&1) || NOROOT_RC=$?
assert_eq "no root at all is a usage error" "2" "$NOROOT_RC"
assert_says "and it says so" 'no recall root given' "$NOROOT_OUT"

TWO_RC=0
TWO_OUT=$("$GATE" "$CLEAN/recall" "$LIVE_RECALL" 2>&1) || TWO_RC=$?
assert_eq "two roots is a usage error rather than a guess" "2" "$TWO_RC"
assert_says "and it names both" 'more than one recall root' "$TWO_OUT"

BADFLAG_RC=0
BADFLAG_OUT=$("$GATE" --nope "$CLEAN/recall" 2>&1) || BADFLAG_RC=$?
assert_eq "an unknown flag is a usage error" "2" "$BADFLAG_RC"
assert_says "and it names the flag" "unknown option '--nope'" "$BADFLAG_OUT"

NODIR_RC=0
"$GATE" "$TMPROOT/not-there" >/dev/null 2>&1 || NODIR_RC=$?
assert_eq "a root that is not a directory is a usage error" "2" "$NODIR_RC"

HELP_RC=0
HELP_OUT=$("$GATE" --help 2>&1) || HELP_RC=$?
assert_eq "--help exits 0" "0" "$HELP_RC"
assert_says "and prints the five checks" 'CHECK 5\. NO PROMPT CONTAINS' "$HELP_OUT"
assert_silent "and stops before the code" '^set -uo pipefail$' "$HELP_OUT"

echo
echo "== part 2: the three static checks, each watched going red =="
# ---------------------------------------------------------------------------
# EVERY ROW BELOW IS A MUTANT THAT MUST GO RED. A check that has never failed
# is not evidence it works, and two suites in this repo were found passing
# vacuously on 2026-10-16. Each assertion pins the FINDING CODE as well as the
# exit, so a gate that went red for an unrelated reason does not read as a
# pass for this one.
#
# Every mutant runs under --static-only, so part 2 starts no JVM at all.
# ---------------------------------------------------------------------------

# --- CHECK 3 ---------------------------------------------------------------
M=$(mutant c3-unknown)
sed -i "s/${TAB}K001${TAB}/${TAB}K999${TAB}/" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 3: a construct id in no inventory row is a finding" "1" "$GATE_RC"
assert_says "and the code names the inventory" \
  '^FINDING +CONSTRUCT-NOT-IN-INVENTORY +F001' "$GATE_OUT"

M=$(mutant c3-empty)
sed -i "s/${TAB}K001${TAB}/${TAB}${TAB}/" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 3: an empty field 3 is a finding" "1" "$GATE_RC"
assert_says "and the code says the field is empty" \
  '^FINDING +CONSTRUCT-EMPTY +F001' "$GATE_OUT"

NOINV_RC=0
NOINV_OUT=$("$GATE" --inventory "$TMPROOT/no-such-inventory.md" --static-only -q \
  "$CLEAN/recall" 2>&1) || NOINV_RC=$?
assert_eq "check 3: no inventory to resolve against is 99, not a pass" "99" "$NOINV_RC"
assert_says "and it is an UNCHECKED rather than a finding" \
  '^UNCHECKED +check-3' "$NOINV_OUT"

# --- CHECK 4 ---------------------------------------------------------------
M=$(mutant c4-env)
sed -i "s/${TAB}mini${TAB}/${TAB}gone${TAB}/" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: an environment that is not on disk is a finding" "1" "$GATE_RC"
assert_says "and the detail says every submission would be rc 3" \
  '^FINDING +ENV-MISSING +F001 .*rc 3' "$GATE_OUT"

M=$(mutant c4-dup)
sed -i "s/${TAB}F002${TAB}/${TAB}F001${TAB}/" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: two rows sharing an id is a finding" "1" "$GATE_RC"
assert_says "and the detail says the second can never be graded" \
  '^FINDING +ROW-DUPLICATE-ID +F001' "$GATE_OUT"

M=$(mutant c4-shape)
printf 'REP%sF005%sK001%smini\n' "$TAB" "$TAB" "$TAB" >>"$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: a row short of six fields is a finding" "1" "$GATE_RC"
assert_says "and the code says so" '^FINDING +ROW-BAD-SHAPE +F005' "$GATE_OUT"

# Field 7 is absent from all 120 live rows, so these two are vacuous against
# the real corpus by construction and are covered here instead.
M=$(mutant c4-ere)
sed -i "s|${TAB}Wagons\$|${TAB}Wagons${TAB}LET(|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: a field 7 grep will not read is a finding" "1" "$GATE_RC"
assert_says "and the detail says the rep would die at rc 3" \
  '^FINDING +REQUIRES-UNREADABLE +F001 .*rc 3' "$GATE_OUT"

M=$(mutant c4-refuses)
sed -i "s|${TAB}Wagons\$|${TAB}Wagons${TAB}NEVERMATCHES|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: a field 7 that refuses its own canonical is a finding" "1" "$GATE_RC"
assert_says "and the detail says no correct answer could score 0" \
  '^FINDING +REQUIRES-REFUSES-CANONICAL +F001' "$GATE_OUT"

# The control that makes the two rows above mean something: a field 7 that
# DOES take its canonical has to stay green, or the two findings only prove
# that any field 7 at all is refused.
M=$(mutant c4-ok)
sed -i "s|${TAB}Wagons\$|${TAB}Wagons${TAB}\\\\bWagons\\\\b|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4 CONTROL: a field 7 that takes its canonical stays green" "0" "$GATE_RC"

# --- CHECK 5 ---------------------------------------------------------------
# The bead's RED line, third clause: a prompt edited to contain its own answer
# notation.
M=$(mutant c5-keyword)
sed -i "s|far on anything else|far on anything else, written with CASE and OTHER|" \
  "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 5: a prompt naming its own keyword is a finding" "1" "$GATE_RC"
assert_says "and the code names the token" \
  "^FINDING +TELEGRAPH-IN-PROMPT +F004 .*'CASE'" "$GATE_OUT"
assert_says "and finds the second keyword too, rather than stopping at the first" \
  "^FINDING +TELEGRAPH-IN-PROMPT +F004 .*'OTHER'" "$GATE_OUT"

M=$(mutant c5-symbol)
sed -i "s|standing each wagon on one track|standing each wagon on one track, as a -> between the two|" \
  "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 5: a symbol telegraphs as well as a keyword" "1" "$GATE_RC"
assert_says "and the code names the symbol" \
  "^FINDING +TELEGRAPH-IN-PROMPT +F003 .*'->'" "$GATE_OUT"

# THE INTERSECTION IS PER ROW. A token no row's own canonical uses is not a
# telegraph, and a check that flagged it would forbid writing a prompt.
M=$(mutant c5-other-row)
sed -i "s|the set of every wagon in the yard|the set of every wagon in the yard, and nothing here says CASE|" \
  "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 5 CONTROL: a token F001's own canonical never uses is not a telegraph" \
  "0" "$GATE_RC"

M=$(mutant c5-empty)
sed -i "s|the set of every wagon in the yard||" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 5: an empty prompt is a finding" "1" "$GATE_RC"
assert_says "and the code says the rep states no need" \
  '^FINDING +PROMPT-EMPTY +F001' "$GATE_OUT"

# --- the shape under all three --------------------------------------------
M=$(mutant shape-no-reps)
rm "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "no REPS.tsv at all is a finding, not an empty pass" "1" "$GATE_RC"
assert_says "and it says the file is the corpus" '^FINDING +SHAPE-NO-REPS' "$GATE_OUT"

M=$(mutant shape-no-env)
rm -rf "$M/recall/env"
run_gate "$M" --static-only -q
assert_eq "no env/ at all is a finding" "1" "$GATE_RC"
assert_says "and it says so once, at the root" '^FINDING +SHAPE-NO-ENV-DIR' "$GATE_OUT"

M=$(mutant shape-no-rows)
printf '%s\n' '# prose and nothing else' >"$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "a REPS.tsv with no REP row is 99, never a clean 0 over an empty set" \
  "99" "$GATE_RC"
assert_says "and it says what a row looks like" '^UNCHECKED +reps' "$GATE_OUT"

echo
echo "== part 3: checks 1 and 2, which are the mutation bar and need TLC =="
# ---------------------------------------------------------------------------
# The other two clauses of the bead's RED line. Every run below grades four
# canonical answers and two wrong ones against the fixture, so the whole part
# is twelve TLC runs rather than the 150 part 4 costs.
# ---------------------------------------------------------------------------

run_gate "$CLEAN"
assert_eq "the clean fixture passes all five checks through TLC" "0" "$GATE_RC"
assert_says "and says every canonical scored rc 0" \
  'OK +check 1 +4 canonical' "$GATE_OUT"
assert_says "and every wrong answer scored rc 10" \
  'OK +check 2 +2 wrong answer' "$GATE_OUT"
assert_silent "and claims no mode block, which belongs to --static-only" \
  'NOT COVERED HERE' "$GATE_OUT"

# --- CHECK 1 ---------------------------------------------------------------
# The bead's RED line, first clause: a corrupted canonical.
M=$(mutant c1-typo)
sed -i "s|${TAB}Wagons\$|${TAB}Wagonz|" "$M/recall/REPS.tsv"
run_gate "$M"
assert_eq "check 1: a canonical naming something the environment never defines is a finding" \
  "1" "$GATE_RC"
assert_says "and it reports the raw code rather than a word for it" \
  '^FINDING +CANONICAL-NOT-CORRECT +F001 .*rc 150' "$GATE_OUT"
assert_says "and says a typo or an undefined name is what that code means" \
  'did not parse' "$GATE_OUT"

M=$(mutant c1-unbalanced)
sed -i "s|${TAB}\\[Wagons -> Tracks\\]\$|${TAB}[Wagons -> Tracks|" "$M/recall/REPS.tsv"
run_gate "$M"
assert_eq "check 1: a canonical that does not parse is a finding" "1" "$GATE_RC"
assert_says "and it names the row" \
  '^FINDING +CANONICAL-NOT-CORRECT +F003' "$GATE_OUT"

# A canonical its own field 7 refuses scores rc 4 through the runner, which is
# a DIFFERENT finding from check 4's static one and reaches it a different
# way. Both are kept: check 4 catches it with no JVM, check 1 catches it if
# the static reading ever drifts from what the runner does.
M=$(mutant c1-construct-gate)
sed -i "s|${TAB}Wagons\$|${TAB}Wagons${TAB}\\\\bLET\\\\b|" "$M/recall/REPS.tsv"
run_gate "$M" --no-tlc -q
assert_says "a field 7 refusing its canonical is caught statically, with no TLC" \
  '^FINDING +REQUIRES-REFUSES-CANONICAL +F001' "$GATE_OUT"

# --- CHECK 2 ---------------------------------------------------------------
# The bead's RED line, second clause: a miss row changed to a correct answer.
#
# The row is REWRITTEN with printf rather than patched with sed. A TLA+ wrong
# answer carries `|->`, and `|` is sed's own delimiter in every form this file
# would reach for, so a substitution over one of these rows is a quoting
# puzzle with a silent wrong answer at the end of it.
rewrite_miss() {
  local root="$1" wrong="$2"
  {
    printf '%s\n' '# A fixture miss table, rewritten by the suite.'
    printf 'MISS%sF003%s%s%sThe explanation this row carries does not matter to check 2.\n' \
      "$TAB" "$TAB" "$wrong" "$TAB"
  } >"$root/recall/MISSES.tsv"
}

M=$(mutant c2-correct)
rewrite_miss "$M" '[Wagons -> Tracks]'
run_gate "$M"
assert_eq "check 2: a miss row that is a CORRECT form is a finding" "1" "$GATE_RC"
assert_says "and the detail says field 4 calls a right answer a mistake" \
  '^FINDING +MISS-NOT-WRONG +F003' "$GATE_OUT"

M=$(mutant c2-unparsed)
rewrite_miss "$M" '[Wagons ->'
run_gate "$M"
assert_eq "check 2: a miss row that never parsed is a finding" "1" "$GATE_RC"
assert_says "and it is told apart from a wrong answer" \
  '^FINDING +MISS-NOT-GRADED +F003 .*rc 150' "$GATE_OUT"

# The control that makes the two rows above mean something: the fixture's own
# wrong answer has to stay green, or the two findings only prove that any miss
# row at all is refused.
M=$(mutant c2-ok)
rewrite_miss "$M" '[Tracks -> Wagons]'
run_gate "$M"
assert_eq "check 2 CONTROL: an ordinary wrong answer stays green" "0" "$GATE_RC"

M=$(mutant c2-no-rep)
{
  printf 'MISS%sF999%s[Tracks -> Wagons]%sA row naming a rep that is not in the table.\n' \
    "$TAB" "$TAB" "$TAB"
} >"$M/recall/MISSES.tsv"
run_gate "$M"
assert_eq "check 2: a miss row naming no rep is a finding" "1" "$GATE_RC"
assert_says "and the code says which" '^FINDING +MISS-NO-REP +F999' "$GATE_OUT"

M=$(mutant c2-no-why)
{
  printf 'MISS%sF003%s[Tracks -> Wagons]%s\n' "$TAB" "$TAB" "$TAB"
} >"$M/recall/MISSES.tsv"
run_gate "$M" --static-only -q
GATE_RC_STATIC="$GATE_RC"
run_gate "$M"
assert_eq "check 2: a miss row with an empty field 4 is a finding" "1" "$GATE_RC"
assert_says "and it says the row costs a run and says nothing" \
  '^FINDING +MISS-NO-EXPLANATION +F003' "$GATE_OUT"
assert_eq "and --static-only does NOT claim to have caught it" "0" "$GATE_RC_STATIC"

M=$(mutant c2-no-table)
rm "$M/recall/MISSES.tsv"
run_gate "$M"
assert_eq "no miss table at all is 99, not a clean pass over zero rows" "99" "$GATE_RC"
assert_says "and it is an UNCHECKED, since the runner's own contract is that a missing table is silence" \
  '^UNCHECKED +check-2' "$GATE_OUT"

# --- rc 10 HOLDS THREE THINGS ----------------------------------------------
# Measured on this build 2026-10-16, against the live corpus, and planted into
# the fixture so the gate's own comment rests on a run:
#
#   an ordinary wrong value           R107 '[Tracks -> Wagons]'       rc 10
#   a CASE with no true arm           R047 (both arms dropped)        rc 10
#   a non-function applied            R118 '@["a"] + 1'               rc 10
#
# All three come back `rc=10 token=ASSUMPTION_FAILED`, so an EVALUATION
# FAILURE inside the ASSUME is indistinguishable from a false assumption by
# the number alone. The fixture's second miss row is the CASE case, and the
# clean run above already passed it at check 2, which is the gate ACCEPTING
# a row whose answer produces no value at all. That is the right call at this
# rung, since both are a wrong answer from the learner's side, and this part
# is here so the next reader meets it as a measurement rather than a claim.
MISS_RC=0
"$CLEAN/recall/recall.sh" -q --reps "$CLEAN/recall/REPS.tsv" \
  --env-dir "$CLEAN/recall/env" -- F004 \
  'CASE Parking.a = 1 -> "near" [] Parking.a = 2 -> "middle"' >/dev/null 2>&1 || MISS_RC=$?
assert_eq "a CASE with no true arm scores rc 10, the same code as a wrong value" \
  "10" "$MISS_RC"

WRONG_RC=0
"$CLEAN/recall/recall.sh" -q --reps "$CLEAN/recall/REPS.tsv" \
  --env-dir "$CLEAN/recall/env" -- F003 '[Tracks -> Wagons]' >/dev/null 2>&1 || WRONG_RC=$?
assert_eq "and so does an ordinary wrong value, which is why the number cannot tell them apart" \
  "10" "$WRONG_RC"

echo
echo "== part 4: the shipped corpus, which the fixture stands in for =="
# ---------------------------------------------------------------------------
# Everything above runs against four fixture rows, so a real corpus that broke
# would pass every one of them. This part is the gate doing its actual job:
# 120 canonical answers and 30 wrong ones through the real model checker,
# against the real drill/INVENTORY.md.
#
# IT IS THE EXPENSIVE PART AND IT IS THE POINT. harness/test-coverage-map.sh
# was written and registered nowhere on 2026-10-15 and ran nowhere until
# somebody noticed. harness/test-recall-runner.sh was in the same state when
# this bead opened. A gate that only ever sees its own fixture is the same
# failure wearing a green suite.
# ---------------------------------------------------------------------------
LIVE_RC=0
LIVE_OUT=$("$GATE" "$LIVE_RECALL" 2>&1) || LIVE_RC=$?
assert_eq "the shipped recall/ corpus passes all five checks" "0" "$LIVE_RC"
assert_says "and the count is the real one, not a fixture's" \
  '120 rep\(s\), 30 miss row\(s\), 0 finding\(s\), 0 unchecked' "$LIVE_OUT"
assert_says "every canonical in it scores rc 0" 'OK +check 1 +120 canonical' "$LIVE_OUT"
assert_says "every recorded wrong answer scores rc 10" \
  'OK +check 2 +30 wrong answer' "$LIVE_OUT"
assert_says "every construct id resolves to a drill/INVENTORY.md row" \
  'OK +check 3 +120 construct' "$LIVE_OUT"
assert_says "no prompt shows a token its own canonical uses" \
  'OK +check 5 +no prompt of 120' "$LIVE_OUT"

# THE CHECK-1 CAVEAT, GATED RATHER THAN LEFT IN A COMMENT. Check 1 submits
# each canonical against itself, so a green run says the canonicals parse and
# evaluate and says nothing about whether they answer their prompts. The gate
# has to keep saying so on the line that reports the pass, or the next reader
# takes 120 green rows for a correctness result.
assert_says "and the OK line itself says what check 1 does NOT prove" \
  'parse and evaluation only' "$LIVE_OUT"
GATE_HEAD=$(awk '/^set -uo pipefail$/ { exit } { print }' "$GATE")
assert_says "the gate's header records where the correctness property WAS verified" \
  '552f09e' "$GATE_HEAD"
assert_says "and records the result of that pass" \
  'agreed=120, disagreed=0' "$GATE_HEAD"

echo
echo "== part 5: registration, so neither suite runs nowhere =="
# ---------------------------------------------------------------------------
# Read the SUITES array rather than the whole file, so a mention of a suite in
# a comment cannot stand in for a row that actually runs it. The pattern is
# harness/test-deliver-completion.sh's.
#
# BOTH SUITES, not just this one. harness/test-recall-runner.sh landed on
# 2026-10-16 and was registered nowhere, so the 37-suite gate green at 420.3 s
# never exercised recall.sh at all. That is the defect this part closes, and
# it closes it for the sibling as well as for itself.
# ---------------------------------------------------------------------------
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
else
  for suite in test-recall-gate test-recall-runner; do
    row="^[[:space:]]*\"slow[|][^|]*[|][^|]*[|]\./harness/${suite}\.sh\""
    if has "$SUITES_BLOCK" "$row"; then
      ok "SUITES carries a slow-tier row for ./harness/${suite}.sh"
    else
      nope "SUITES carries no slow-tier row for ./harness/${suite}.sh"
    fi
  done
fi

# --list is the project's authority on what runs, and the bead's RED line
# names it rather than the array, so it is asserted through the command.
LIST_OUT=$(bash "$TEST_RUNNER" --list 2>&1) || true
assert_says "bash scripts/test --list shows the recall gate" \
  'harness/test-recall-gate\.sh' "$LIST_OUT"
assert_says "bash scripts/test --list shows the recall runner" \
  'harness/test-recall-runner\.sh' "$LIST_OUT"

echo
echo "== part 6: scripts/deliver-recall.sh, which has no suite of its own =="
# ---------------------------------------------------------------------------
# See WHY THE DELIVERY SCRIPT IS IN THIS SUITE at the top of this file.
#
# NOTHING BELOW NAMES ~/tla-practice OR ~/Study. Every destination is under
# the temp tree, because neither of those is a git repo and a guessed manifest
# deleted 39 delivered files on 2026-10-02.
# ---------------------------------------------------------------------------
DEST="$TMPROOT/dest/recall"

CHECK_RC=0
CHECK_OUT=$("$DELIVER" --check "$DEST" 2>&1) || CHECK_RC=$?
assert_eq "--check exits 0" "0" "$CHECK_RC"
assert_eq "--check writes nothing at all" "0" \
  "$(find "$TMPROOT/dest" -type f 2>/dev/null | wc -l)"

for part in recall.sh REPS.tsv MISSES.tsv README.md env/shunting.tla env/ledger.tla; do
  assert_says "--check names ${part} as a path it would write" \
    "would deliver: ${DEST}/${part//./\\.}" "$CHECK_OUT"
done
assert_says "--check counts the six" '6 file\(s\) to land' "$CHECK_OUT"
assert_says "--dry-run is the same flag" '6 file\(s\) to land' \
  "$("$DELIVER" --dry-run "$DEST" 2>&1)"

# THE TWO THINGS THE DELIVERED RUNNER REACHES FOR OUTSIDE THE MANIFEST, both
# reported at the destination's own resolved path. Without the first, the
# delivered tree grades NOTHING. Without the second it loses one explanation
# layer of three. A delivery that silently produced a tree that cannot grade
# is the defect these two lines exist to stop.
assert_says "--check warns that the destination has no verdict channel" \
  "WARNING: no verdict channel at ${TMPROOT}/dest/harness/verdict\.sh" "$CHECK_OUT"
assert_says "and says what that costs: every rep, not some of them" \
  'exits 3 on EVERY rep' "$CHECK_OUT"
assert_says "--check notes the absent construct sheet separately" \
  "no construct sheet at ${TMPROOT}/dest/drill/SHEET\.md" "$CHECK_OUT"
assert_says "and says reps still grade without it, which is why it is a note" \
  'Reps still grade' "$CHECK_OUT"

# The same two lines inverted, so the warning is not simply always printed.
mkdir -p "$TMPROOT/dest/harness" "$TMPROOT/dest/drill"
ln -sf "$VERDICT" "$TMPROOT/dest/harness/verdict.sh"
cp "$REPO_ROOT/drill/SHEET.md" "$TMPROOT/dest/drill/SHEET.md"
WIRED_OUT=$("$DELIVER" --check "$DEST" 2>&1) || true
assert_silent "with a verdict channel in place the warning is gone" \
  'WARNING: no verdict channel' "$WIRED_OUT"
assert_says "and it says the delivered runner can grade" \
  'so the delivered runner can grade' "$WIRED_OUT"
assert_says "and the sheet note becomes a sheet confirmation" \
  'so a wrong answer gets its construct entry' "$WIRED_OUT"

# The real delivery, into the temp tree. This is the only part of this suite
# that writes anything.
REAL_RC=0
REAL_OUT=$("$DELIVER" "$DEST" 2>&1) || REAL_RC=$?
assert_eq "a real delivery into an empty destination exits 0" "0" "$REAL_RC"
assert_eq "and lands exactly six files" "6" "$(find "$DEST" -type f | wc -l)"
assert_says "and counts them" '6 file\(s\) landed, 0 refreshed' "$REAL_OUT"
if [ -x "$DEST/recall.sh" ]; then
  ok "the delivered runner is executable, which cp without -p does not guarantee"
else
  nope "the delivered runner is executable, which cp without -p does not guarantee"
fi

# EVERY FILE IS REPO-OWNED, SO EVERY FILE IS OVERWRITTEN. This is the one
# place this script inverts its three siblings, which all hold a
# never-overwrite rule because they deliver a file the learner writes into.
printf 'learner edit\n' >"$DEST/REPS.tsv"
AGAIN_OUT=$("$DELIVER" "$DEST" 2>&1) || true
assert_says "a second delivery refreshes rather than skipping" \
  '0 file\(s\) landed, 6 refreshed' "$AGAIN_OUT"
assert_silent "and never reports a skip, which is the sibling scripts' word" \
  'skipped \(exists\)' "$AGAIN_OUT"
if cmp -s "$REPO_ROOT/recall/REPS.tsv" "$DEST/REPS.tsv"; then
  ok "and the refreshed copy is the repo's, byte for byte"
else
  nope "and the refreshed copy is the repo's, byte for byte"
fi

# THE CLAIM THE ALWAYS-OVERWRITE RULE RESTS ON, measured rather than asserted:
# recall/recall.sh writes nothing into its own tree, so there is no learner
# work in it to overwrite. Snapshot, grade a WRONG answer (the expensive path,
# which runs three TLC jobs and both value probes), snapshot again.
#
# This is a different claim from harness/test-recall-runner.sh part 5's, which
# snapshots the CALLER'S working directory. This one is about the runner's own
# tree, which is the directory a delivery would overwrite.
SNAP_BEFORE=$(find "$CLEAN/recall" | LC_ALL=C sort)
"$CLEAN/recall/recall.sh" --reps "$CLEAN/recall/REPS.tsv" \
  --env-dir "$CLEAN/recall/env" --misses "$CLEAN/recall/MISSES.tsv" \
  -- F003 '[w \in Wagons |-> Tracks]' >/dev/null 2>&1 || true
SNAP_AFTER=$(find "$CLEAN/recall" | LC_ALL=C sort)
assert_eq "the runner writes nothing into its own tree, which is why every file may be overwritten" \
  "$SNAP_BEFORE" "$SNAP_AFTER"

# An incomplete source delivers NOTHING rather than half a channel.
INC="$TMPROOT/incomplete"
mkdir -p "$INC/recall/env"
cp "$RUNNER" "$INC/recall/recall.sh"
INC_RC=0
INC_OUT=$(DELIVER_RECALL_SRC_ROOT="$INC" "$DELIVER" --check "$TMPROOT/dest2" 2>&1) || INC_RC=$?
assert_eq "a source missing a manifest part delivers nothing, at rc 1" "1" "$INC_RC"
assert_says "and names each missing part" 'carries no REPS\.tsv' "$INC_OUT"
assert_eq "and wrote nothing" "0" "$(find "$TMPROOT/dest2" -type f 2>/dev/null | wc -l)"

cp "$REPO_ROOT/recall/REPS.tsv" "$REPO_ROOT/recall/MISSES.tsv" \
   "$REPO_ROOT/recall/README.md" "$INC/recall/"
EMPTY_RC=0
EMPTY_OUT=$(DELIVER_RECALL_SRC_ROOT="$INC" "$DELIVER" --check "$TMPROOT/dest2" 2>&1) || EMPTY_RC=$?
assert_eq "an env/ with no file in it delivers nothing either" "1" "$EMPTY_RC"
assert_says "and says why: every rep would die at rc 3" 'die at rc 3' "$EMPTY_OUT"

# A root entry outside the manifest is REPORTED rather than tolerated. There
# is none today. The line exists for the file somebody adds tomorrow.
cp "$REPO_ROOT/recall/env/shunting.tla" "$INC/recall/env/"
printf 'not in the manifest\n' >"$INC/recall/STRAY.md"
STRAY_OUT=$(DELIVER_RECALL_SRC_ROOT="$INC" "$DELIVER" --check "$TMPROOT/dest2" 2>&1) || true
assert_says "a root entry outside the manifest is reported as withheld" \
  'withheld \(not in the manifest\): .*STRAY\.md' "$STRAY_OUT"
assert_silent "and is not delivered" 'would deliver: .*STRAY\.md' "$STRAY_OUT"
assert_says "the live channel withholds nothing, which is a property of this rung" \
  '0 path\(s\) withheld' "$CHECK_OUT"

# --- the delivery script's own contract, read off its source ---------------
# The header is everything above `set -uo pipefail`, taken from the file
# rather than from a line number, so a section added to it cannot push a
# contract sentence out of range. The first draft of this suite read lines 1
# to 140 and went red when the header grew by 25 lines.
DELIVER_HEAD=$(awk '/^set -uo pipefail$/ { exit } { print }' "$DELIVER")
assert_says "the script states that it overwrites every file it delivers" \
  'OVERWRITES EVERY FILE' "$DELIVER_HEAD"
assert_says "and says why, naming the siblings' rule it inverts" \
  'never-overwrite' "$DELIVER_HEAD"
assert_says "and says it has no delete path" 'no delete' "$DELIVER_HEAD"
assert_says "and names the verdict channel it does not deliver" \
  'harness/verdict\.sh' "$DELIVER_HEAD"
assert_says "and names the sheet it does not deliver" 'drill/SHEET\.md' "$DELIVER_HEAD"

DELIVER_BODY=$(cat "$DELIVER")
assert_says "the script resolves its root from BASH_SOURCE rather than a literal path" \
  'BASH_SOURCE' "$DELIVER_BODY"
assert_says "the script sets -uo pipefail" '^set -uo pipefail$' "$DELIVER_BODY"
# Anchored at a command position rather than anywhere in the text. A bare
# `rm ` substring also matches the tail of "perform" and "confirm", and a check
# that fires on an English word is one somebody turns off. The pattern is
# harness/test-deliver-completion.sh:1131's.
if has "$DELIVER_BODY" '(^|[;&|(][[:space:]]*)(rm|rmdir|unlink|mv|truncate)[[:space:]]'; then
  nope "the script runs a delete or a move, and the contract says it has no delete path"
else
  ok "the script runs no rm, rmdir, unlink, mv or truncate anywhere"
fi

GATE_BODY=$(cat "$GATE")
assert_says "the gate sets -uo pipefail" '^set -uo pipefail$' "$GATE_BODY"
assert_says "the gate resolves its root from BASH_SOURCE" 'BASH_SOURCE' "$GATE_BODY"
# CHECKS 1 AND 2 GO THROUGH THE RUNNER AND NEVER PAST IT. That is what makes
# them the mutation bar for THIS CHANNEL rather than a second measurement of
# TLC, and it keeps the gate off harness/verdict.sh, which is centrally owned
# (.claude/rules/dispatched-agents.md). The gate holds no verdict path at all,
# so the absence of the assignment is the thing to assert.
# The [$] is a one-character class matching a literal dollar sign. Written as
# \$ it is the same regex, and shellcheck reads the pattern as a variable
# somebody forgot to expand (SC2016). The class says the same thing and says
# it without a false finding. The idiom is
# harness/test-deliver-completion.sh:1122-1125's.
assert_says "the gate grades through recall.sh" '"[$]RUNNER" -q' "$GATE_BODY"
assert_silent "and holds no verdict path of its own, so it never reaches past the runner" \
  '^[[:space:]]*VERDICT=' "$GATE_BODY"

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
