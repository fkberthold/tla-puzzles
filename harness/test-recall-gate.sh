#!/usr/bin/env bash
# test-recall-gate.sh: executable spec for harness/recall-gate.sh and for
# scripts/deliver-recall.sh (beads tla-1sh7.4 and tla-03ep.1, epics tla-1sh7
# and tla-i7uz).
#
# WHAT IT PINS
#
#   Each of the gate's six checks goes RED on a corpus that breaks it, and
#   the finding carries the code that names which one broke. The bead's RED
#   line names three of those by hand (a corrupted canonical, a miss row
#   changed to a correct answer, and a prompt edited to contain its own answer
#   notation) and parts 2 and 3 run the first five.
#
#   Each of the SPEC row kind's own findings goes RED too, and part 7 is where
#   they are. The rep table carries two kinds and four of the six checks ask a
#   question whose ANSWER DIFFERS BY KIND, so part 7 exists because widening
#   the guards would have answered those four wrongly in silence rather than
#   leaving them unanswered.
#
#   The two tiers mean two different things. `--static-only` over a clean
#   corpus exits 0 and SAYS what it did not measure. `--no-tlc` over the same
#   corpus exits 99, because it was asked to measure and did not.
#
#   The shipped recall/ corpus passes all six checks, over the real 120 value
#   reps, 40 spec reps, 30 scaffolds and 90 miss rows, through the real model
#   checker. Part 4 also asserts the coverage claim the gate deliberately has
#   no opinion about: all 20 constructs of the temporal family carry a spec
#   rep, and none of them carries only one.
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
# lengths against the shipped drill/SHEET.md. So this suite writes a six-rep
# corpus -- four REP rows and two SPEC rows -- three scaffolds and a four-row
# inventory into its temp tree and owns them.
#
# THE TREE IS A BARE PRACTICE TREE, AND THAT IS NOW AN ASSERTION RATHER THAN
# A SETUP DETAIL. It carries recall/ and nothing else: no harness/ and no repo
# above it. Part 1 asserts that shape before it grades anything, so every row
# below runs in the shape a learner's tree actually has.
#
# IT USED TO BE A MIRROR ROOT and it had to be. recall/recall.sh resolved its
# verdict channel as ${REPO_ROOT}/harness/verdict.sh where REPO_ROOT is the
# PARENT of the directory it sits in, so this suite built a harness/ beside
# recall/ holding a symlink to the real channel, and without it every row died
# at exit 3 for a reason that had nothing to do with the corpus. Bead
# tla-1sh7.10 made the runner self-contained, and the symlink went with it.
# Deleting it is the point. A suite that kept propping the tree up would go on
# passing over a runner that still could not be delivered, which is what this
# one did between tla-1sh7.4 landing and this bead. Nothing is written into
# the repo.
#
# ---------------------------------------------------------------------------
# WHY THERE IS NO FAST ROW
#
# harness/recall-gate.sh has a `--static-only` tier that starts no JVM, so a
# fast registry row over it is available and is deliberately not taken: bead
# tla-1sh7.4 registers two suites and this is one of them. Part 4 is the
# expensive part and it is the part the bead exists for. It costs 160
# canonical answers and 90 wrong ones; the 120 value rows are one TLC run
# each, and the 40 spec rows are one run PER SCAFFOLD, which is between one
# and four.
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
# NO VERDICT PATH HERE, and that is a statement rather than an omission. This
# suite builds practice trees and grades in them, and since bead tla-1sh7.10
# neither the runner nor the delivery script reaches for harness/verdict.sh.
# A path held here would have to be propped into every tree below, which is
# what the suite used to do and what kept the defect green.
TEST_RUNNER="$REPO_ROOT/scripts/test"
LIVE_RECALL="$REPO_ROOT/recall"
LIVE_INVENTORY="$REPO_ROOT/drill/INVENTORY.md"

for required in "$GATE" "$DELIVER" "$RUNNER" "$TEST_RUNNER" \
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
# build_mirror <dir>: a bare practice tree at <dir> carrying recall/ and
# NOTHING ELSE. No harness/ is created and no verdict channel is linked in:
# see THE TREE IS A BARE PRACTICE TREE in the header for why its absence is
# the assertion.
#
# The corpus is four reps over one environment and two miss rows. Every row is
# written with printf and an explicit $TAB rather than through a heredoc, so a
# tab that an editor turned into spaces is a syntax error here rather than a
# field shift nobody sees.
# ---------------------------------------------------------------------------
build_mirror() {
  local root="$1"
  mkdir -p "$root/recall/env/spec"
  cp "$RUNNER" "$root/recall/recall.sh"
  chmod +x "$root/recall/recall.sh"

  # ------------------------------------------------------------------------
  # THE SPEC HALF OF THE FIXTURE. Three scaffolds and two SPEC rows, which is
  # the smallest corpus that gives every one of the gate's spec-only findings
  # a subject to be absent from:
  #
  #   gfix-near, gfix-far  a battery. The canonical has to HOLD on the first
  #                        and FAIL on the second, so field 8 is 0,13 and a
  #                        vector check 4 lets through unaligned would be
  #                        read against the wrong machine
  #   gfix-act             one scaffold with a __CHECK__ hole, so field 9 and
  #                        both of its findings have a subject
  #
  # EVERY NUMBER IN FIELD 8 AND FIELD 9 IS CONFIRMED BY THE CLEAN RUN rather
  # than written down from memory: check 1 submits each canonical and requires
  # rc 0, so part 1's green run over this tree IS the measurement.
  # ------------------------------------------------------------------------
  # A SINGLE-QUOTED HEREDOC, NOT printf, FOR THE SCAFFOLDS. The rep tables
  # above use printf with an explicit $TAB because a tab an editor turned into
  # spaces has to be a syntax error here rather than a silent field shift. A
  # scaffold carries no tabs and does carry primes and backslashes, both of
  # which a quoted heredoc passes through untouched and neither of which
  # survives a single-quoted printf argument without `'"'"'`.
  cat >"$root/recall/env/spec/gfix-near.tla" <<'NEAR'
\* a fixture machine: a counter driven up to two that then stays there, beside a flag that flips for ever.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES n, flag
vars == <<n, flag>>
Init == n = 0 /\ flag = 0
Step == n < 2 /\ n' = n + 1 /\ flag' = flag
Flip == flag' = 1 - flag /\ n' = n
Next == Step \/ Flip
Spec == Init /\ [][Next]_vars /\ WF_vars(Step) /\ WF_vars(Flip)
Checked ==
__ANSWER__
====
NEAR
  printf 'SPECIFICATION Spec\nPROPERTY Checked\n' >"$root/recall/env/spec/gfix-near.cfg"

  cat >"$root/recall/env/spec/gfix-far.tla" <<'FAR'
\* a fixture machine: a counter driven up to two, dropped back to nothing, and driven up again for ever, beside a flag that flips.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES n, flag
vars == <<n, flag>>
Init == n = 0 /\ flag = 0
Step == n < 2 /\ n' = n + 1 /\ flag' = flag
Fall == n = 2 /\ n' = 0 /\ flag' = flag
Flip == flag' = 1 - flag /\ n' = n
Next == Step \/ Fall \/ Flip
Spec == Init /\ [][Next]_vars /\ WF_vars(Step) /\ WF_vars(Fall) /\ WF_vars(Flip)
Checked ==
__ANSWER__
====
FAR
  printf 'SPECIFICATION Spec\nPROPERTY Checked\n' >"$root/recall/env/spec/gfix-far.cfg"

  cat >"$root/recall/env/spec/gfix-act.tla" <<'ACT'
\* a fixture machine: a counter and a flag held at nothing, so the flag cannot move. what one step does is the thing left out.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES n, flag
vars == <<n, flag>>
Init == n = 0 /\ flag = 0
Act ==
__ANSWER__
Next == Act
Spec == Init /\ [][Next]_vars
Guard == flag = 0
Shape ==
__CHECK__
====
ACT
  printf 'SPECIFICATION Spec\nINVARIANT Guard\nPOSTCONDITION Shape\n' >"$root/recall/env/spec/gfix-act.cfg"

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
    printf '%s\n' '# Two SPEC rows. F005 is the battery shape and F006 the action shape.'
    printf 'SPEC%sF005%sK004%sgfix-near,gfix-far%sthat the counter reaches two and from then on is never anywhere else%s<>[](n = 2)%s<>\\[\\]%s0,13\n' \
      "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
    printf 'SPEC%sF006%sK004%sgfix-act%sa step that takes the counter up one while it has room, leaving the flag alone%sn < 2 /\\ n'"'"' = n + 1 /\\ flag'"'"' = flag%s'"'"'%s0%sTLCGet("distinct") = 3 /\\ TLCGet("diameter") = 3\n' \
      "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  } >"$root/recall/REPS.tsv"

  # Row two is the rc-10 band's SECOND meaning, planted deliberately. See
  # part 3's rc-10 section.
  {
    printf '%s\n' '# A fixture miss table. Two rows.'
    printf 'MISS%sF003%s[w \\in Wagons |-> Tracks]%sThat is one standing, and what it gives back for every wagon is the whole set of tracks rather than one track.\n' \
      "$TAB" "$TAB" "$TAB"
    printf 'MISS%sF004%sCASE Parking.a = 1 -> "near" [] Parking.a = 2 -> "middle"%sThat leaves the yard with no word for anything but the first two tracks, and wagon a is on neither.\n' \
      "$TAB" "$TAB" "$TAB"
    # A SPEC rep's miss, whose wrong answer scores rc 5 rather than rc 10.
    # This is the row a check 2 that widened its guard instead of looking the
    # kind up would have reported as "not wrong".
    printf 'MISS%sF005%s[]<>(n = 2)%sThat asks for two again and again and lets the counter leave in between, which the machine that climbs and drops for ever satisfies.\n' \
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
  printf '%s\n' '# A fixture construct inventory. The gate reads field 1, field 2 and,'
  printf '%s\n' '# since bead tla-2s12, field 4: check 4 holds a REP row to a field-7'
  printf '%s\n' '# pattern when its construct NAME is one value equality cannot see.'
  printf '%s\n' '# None of these four names is on that list, deliberately, so the clean'
  printf '%s\n' '# run is silent about it and the rows below opt in by renaming a copy.'
  printf 'ROW%sK001%ssets%sSet literal%sfixture:1%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'ROW%sK002%score%sCardinality%sfixture:2%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'ROW%sK003%sfunctions%sFunction set%sfixture:3%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'ROW%sK004%stemporal%sTemporal fixture construct%sfixture:4%shigh\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
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

# THE TREE EVERY ROW BELOW RUNS IN, asserted rather than assumed. A setup that
# quietly grew a harness/ back would make every grading row below pass over a
# runner that still could not be delivered, which is the defect bead
# tla-1sh7.10 closed. Asserting the shape of the tree is what stops that
# coming back as a green suite.
assert_eq "the tree the gate runs in holds recall/ and nothing else" "recall" \
  "$(cd "$CLEAN" && ls -A)"
if [ -e "$CLEAN/harness" ]; then
  nope "no harness/ beside it, so the runner grades on its own or not at all"
else
  ok "no harness/ beside it, so the runner grades on its own or not at all"
fi

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
  '^UNCHECKED .*every-miss-scores-its-kinds-code' "$GATE_OUT"
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

# --- CHECK 4, THE PATTERN THAT IS MISSING (bead tla-2s12) ------------------
#
# Everything else check 4 says about field 7 validates a pattern that IS
# there. Measured by the tla-1sh7.7 author: strip R023, R045 and R110 of the
# shipped corpus back to six fields and the gate reported 0 findings and
# VERDICT OK. So nothing noticed 24 reps losing their construct gate, and
# nothing would notice a new rep in those families landing without one.
#
# THESE ROWS DRIVE THE GATE WITH THEIR OWN INVENTORY rather than through
# run_gate, because the requirement is keyed on the construct NAME and the
# shared fixture inventory deliberately carries none of the listed names. A
# row opts in by renaming a copy, which is also what proves the keying is on
# the name and not on the id: K001 is "Set literal" here and "Operator
# definition" in drill/INVENTORY.md, and only the second one is held to a
# pattern.
REQ_INV="$TMPROOT/INVENTORY-opdef.md"
sed "s/${TAB}Set literal${TAB}/${TAB}Operator definition${TAB}/" "$INVENTORY" >"$REQ_INV"

REQ_RC=0
REQ_OUT=$("$GATE" --inventory "$REQ_INV" --static-only -q "$CLEAN/recall" 2>&1) || REQ_RC=$?

# F001 is a K001 row with six fields. Under the live inventory's name for
# K001 that is a rep whose construct the grader cannot see.
assert_says "check 4: a rep whose construct needs a pattern and has none is a finding" \
  '^FINDING +REQUIRES-ABSENT +F001' "$REQ_OUT"
assert_says "and the detail names the construct by its inventory name" \
  "REQUIRES-ABSENT.*'Operator definition'" "$REQ_OUT"

# The same run exercises the rename tripwire, since eight of the nine listed
# names still resolve to nothing in this inventory and one now does. A
# PARTIAL match is drift in the inventory the list was written against.
assert_says "check 4: a listed name that stopped resolving is UNCHECKED, not a finding" \
  '^UNCHECKED +check-4-requires' "$REQ_OUT"
assert_says "and it says how many siblings did resolve, so a total miss reads differently" \
  'siblings resolve in' "$REQ_OUT"

# THE ACCEPT CONTROL. Same renamed inventory, and F001 given a field 7 its own
# canonical satisfies. Without this row the finding above could be firing on
# the rename rather than on the absent pattern.
REQ_OK=$(mutant c4-requires-ok)
sed -i "s|^REP${TAB}F001${TAB}K001${TAB}mini${TAB}the set of every wagon in the yard${TAB}Wagons\$|REP${TAB}F001${TAB}K001${TAB}mini${TAB}the set of every wagon in the yard${TAB}Wagons${TAB}\\\\bWagons\\\\b|" \
  "$REQ_OK/recall/REPS.tsv"
REQOK_RC=0
REQOK_OUT=$("$GATE" --inventory "$REQ_INV" --static-only -q "$REQ_OK/recall" 2>&1) || REQOK_RC=$?
if grep -qE '^FINDING +REQUIRES-ABSENT' <<<"$REQOK_OUT"; then
  nope "check 4: the same rep WITH a pattern is not a finding — it still fired"
else
  ok "check 4: the same rep WITH a pattern is not a finding"
fi

# And the shared inventory's own names are not on the list, so the clean run
# says nothing about any of this. Asserted rather than assumed, because the
# first version of this check was keyed on the id and called CLEAN a finding.
run_gate "$CLEAN" --static-only -q
if grep -qE 'REQUIRES-ABSENT|check-4-requires' <<<"$GATE_OUT"; then
  nope "check 4: the clean fixture is silent about field-7 requirements, and it was not"
else
  ok "check 4: the clean fixture is silent about field-7 requirements"
fi

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
# THE SCAFFOLDS GO WITH THE ROWS, because with no SPEC row left to name them
# all three are orphans and check 6 says so correctly. That is a different
# defect from the one this row is about, and leaving it in would have made
# this row assert "an empty table is 99" over a run that was 1 for a reason
# nobody asked about.
rm -rf "$M/recall/env/spec"
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
assert_eq "the clean fixture passes all six checks through TLC" "0" "$GATE_RC"
assert_says "and says every canonical scored rc 0" \
  'OK +check 1 +6 canonical' "$GATE_OUT"
assert_says "and every wrong answer scored its own row kind's code" \
  'OK +check 2 +3 wrong answer' "$GATE_OUT"
assert_silent "and claims no mode block, which belongs to --static-only" \
  'NOT COVERED HERE' "$GATE_OUT"
# THE TWO KINDS ARE COUNTED SEPARATELY on the line that reports the pass. One
# total would have let a corpus lose every SPEC row under a number that did
# not move, which is the shape of the defect the spec checks exist to close.
assert_says "and the summary names both row kinds and the scaffolds apart" \
  '4 rep\(s\), 2 spec rep\(s\), 3 scaffold\(s\), 3 miss row\(s\)' "$GATE_OUT"

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
# 160 canonical answers and 90 wrong ones through the real model checker,
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
assert_eq "the shipped recall/ corpus passes all six checks" "0" "$LIVE_RC"
# THE COUNTS MOVED ON 2026-10-17 AND THEY ARE STILL WRITTEN DOWN. Deriving
# them from the tables the gate just read would make this row assert that the
# gate agrees with itself. 120 value reps and 30 of their misses landed with
# bead tla-1sh7.2; 40 spec reps over 30 scaffolds and 60 of their misses
# landed with bead tla-03ep.1. A row that goes red because the corpus grew is
# a row somebody has to look at, which is the point of pinning it.
assert_says "and the count is the real one, not a fixture's" \
  '120 rep\(s\), 40 spec rep\(s\), 30 scaffold\(s\), 90 miss row\(s\), 0 finding\(s\), 0 unchecked' "$LIVE_OUT"
assert_says "every canonical in it scores rc 0" 'OK +check 1 +160 canonical' "$LIVE_OUT"
assert_says "and the OK line splits the two kinds, since the two mean different things" \
  '120 against themselves.*40 against the vector' "$LIVE_OUT"
assert_says "every recorded wrong answer scores its own row kind's code" \
  'OK +check 2 +90 wrong answer' "$LIVE_OUT"
assert_says "every construct id resolves to a drill/INVENTORY.md row" \
  'OK +check 3 +160 construct' "$LIVE_OUT"
assert_says "no prompt shows a token its own canonical uses" \
  'OK +check 5 +no prompt of 160' "$LIVE_OUT"
assert_says "every shipped scaffold is a whole module a row names" \
  'OK +check 6 +30 scaffold' "$LIVE_OUT"
# ALL 20 TEMPORAL CONSTRUCTS HAVE A REP, which is the coverage claim bead
# tla-03ep.1 exists to deliver and the one thing a green gate does not say.
# The gate has no opinion about coverage on purpose, so the claim is asserted
# here against drill/INVENTORY.md rather than left to a reader.
assert_eq "all 20 constructs of the temporal family carry a spec rep" "20" \
  "$(awk -F'\t' 'FNR == NR && $1 == "ROW" && $3 == "temporal" { fam[$2] = 1; next }
                 $1 == "SPEC" && ($3 in fam) { seen[$3] = 1 }
                 END { print length(seen) }' "$LIVE_INVENTORY" "$LIVE_RECALL/REPS.tsv")"
assert_eq "and none of them carries only one, so the fact is retrieved rather than the sentence" \
  "" "$(awk -F'\t' '$1 == "SPEC" { n[$3]++ } END { for (k in n) if (n[k] < 2) print k }' \
         "$LIVE_RECALL/REPS.tsv")"

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

# THE TWO THINGS A DELIVERED TREE NEEDS THAT ARE NOT IN THE MANIFEST: the
# construct sheet, reported at the destination's own resolved path, and tlc,
# reported from this machine. Neither stops a delivery and the first costs
# only one explanation layer of three.
assert_says "--check notes the absent construct sheet" \
  "no construct sheet at ${TMPROOT}/dest/drill/SHEET\.md" "$CHECK_OUT"
assert_says "and says reps still grade without it, which is why it is a note" \
  'Reps still grade' "$CHECK_OUT"
assert_says "--check reports tlc, which is the whole of what a delivered tree needs" \
  '^tlc: .* is on the path' "$CHECK_OUT"
assert_says "and says that is the whole of it" \
  'the whole of what the delivered runner needs to grade' "$CHECK_OUT"

# THE WARNING THAT MUST NO LONGER BE PRINTED (bead tla-1sh7.10). The runner is
# self-contained, so a line naming a verdict path a delivered tree would look
# for would be a report of a hazard that is not there. This is the row that
# goes red if the dependency is ever reintroduced from the other end.
assert_silent "no verdict-channel warning, because there is no verdict channel to want" \
  'WARNING: no verdict channel' "$CHECK_OUT"
assert_silent "and no claim that a delivered tree exits 3 on every rep" \
  'exits 3 on EVERY rep' "$CHECK_OUT"
# The strongest form of the same claim is further down this part: the tree the
# real delivery lands is graded in place, with no harness/ in it.

# The sheet note inverted, so it is not simply always printed.
mkdir -p "$TMPROOT/dest/drill"
cp "$REPO_ROOT/drill/SHEET.md" "$TMPROOT/dest/drill/SHEET.md"
WIRED_OUT=$("$DELIVER" --check "$DEST" 2>&1) || true
assert_says "with a sheet in place the note becomes a sheet confirmation" \
  'so a wrong answer gets its construct entry' "$WIRED_OUT"
assert_silent "and the absent-sheet note is gone" \
  'no construct sheet at' "$WIRED_OUT"

# The real delivery, into the temp tree. This is the only part of this suite
# that writes anything.
REAL_RC=0
REAL_OUT=$("$DELIVER" "$DEST" 2>&1) || REAL_RC=$?
assert_eq "a real delivery into an empty destination exits 0" "0" "$REAL_RC"
# THE EXPECTED COUNT IS COMPUTED FROM THE MANIFEST RATHER THAN WRITTEN DOWN.
# It read 6 until 2026-10-17 and then the spec scaffolds landed under env/, so
# a hardcoded number would have turned this row red for a corpus that grew by
# design. The manifest is four named files plus every file under env/, which
# the delivery script sweeps with `find -type f` for the stated reason that a
# name list cannot be told the corpus grew. So the same sweep is the
# expectation, and a row the script fails to deliver still goes red.
MANIFEST_N=$(( 4 + $(find "$REPO_ROOT/recall/env" -type f | wc -l) ))
assert_eq "and lands every file the manifest names, four plus the whole env/ tree" \
  "$MANIFEST_N" "$(find "$DEST" -type f | wc -l)"
assert_says "and counts them" "$MANIFEST_N file\\(s\\) landed, 0 refreshed" "$REAL_OUT"
if [ -x "$DEST/recall.sh" ]; then
  ok "the delivered runner is executable, which cp without -p does not guarantee"
else
  nope "the delivered runner is executable, which cp without -p does not guarantee"
fi

# ---------------------------------------------------------------------------
# THE TREE THAT WAS JUST DELIVERED IS GRADED IN PLACE (bead tla-1sh7.10).
#
# These are the rows the bead exists for, and they are the ones a green suite
# in the repo could never stand in for. The repo is the environment the defect
# hid in: until tla-1sh7.10 every row in this file ran a runner with a
# harness/ one directory up, and they all passed over a channel that answered
# rc 3 to every rep a learner could ever type.
#
# WHAT IS ASSERTED IS THE TREE, not a flag. $DEST is what scripts/
# deliver-recall.sh actually wrote, four lines ago, from its own manifest. Its
# parent carries that recall/ and the drill/SHEET.md the row above planted,
# and no harness/, no verdict channel and no repo. All three reachable codes
# are graded in it.
# ---------------------------------------------------------------------------
if [ -e "$TMPROOT/dest/harness" ]; then
  nope "the delivered tree has no harness/ above it, which is what makes this row mean something"
else
  ok "the delivered tree has no harness/ above it, which is what makes this row mean something"
fi

DELIVERED_RC=0
DELIVERED_OUT=$("$DEST/recall.sh" -q R107 '[Wagons -> Tracks]' 2>&1) || DELIVERED_RC=$?
assert_eq "a RIGHT answer in the delivered tree scores 0" "0" "$DELIVERED_RC"
assert_says "and says so, through the runner's own status line" \
  '^rep=R107 rc=0 token=OK grade=correct$' "$DELIVERED_OUT"
assert_silent "and never reports could-not-run, which is what it did before this bead" \
  'nothing was graded' "$DELIVERED_OUT"

DELIVERED_RC=0
DELIVERED_OUT=$("$DEST/recall.sh" -q R107 '[w \in Wagons |-> Tracks]' 2>&1) || DELIVERED_RC=$?
assert_eq "a WRONG answer in the delivered tree scores 10" "10" "$DELIVERED_RC"
assert_says "and is named a wrong answer rather than a failed run" \
  'token=ASSUMPTION_FAILED grade=incorrect' "$DELIVERED_OUT"

DELIVERED_RC=0
DELIVERED_OUT=$("$DEST/recall.sh" -q R107 '[Wagons ->' 2>&1) || DELIVERED_RC=$?
assert_eq "and a parse error is its own code there too" "150" "$DELIVERED_RC"
assert_says "and its own grade" 'token=PARSE_ERROR grade=parse-error' "$DELIVERED_OUT"

# EVERY FILE IS REPO-OWNED, SO EVERY FILE IS OVERWRITTEN. This is the one
# place this script inverts its three siblings, which all hold a
# never-overwrite rule because they deliver a file the learner writes into.
printf 'learner edit\n' >"$DEST/REPS.tsv"
AGAIN_OUT=$("$DELIVER" "$DEST" 2>&1) || true
assert_says "a second delivery refreshes rather than skipping" \
  "0 file\\(s\\) landed, $MANIFEST_N refreshed" "$AGAIN_OUT"
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
assert_says "and names the sheet it does not deliver" 'drill/SHEET\.md' "$DELIVER_HEAD"
# The header has to say what a delivered tree needs and what it does not. It
# names tlc as the whole of the first, and it records that the verdict channel
# stopped being the second rather than quietly dropping the subject: a reader
# who remembers the warning should find out here why it is gone.
assert_says "the header names tlc as what a delivered tree needs" \
  'tlc ON THE PATH' "$DELIVER_HEAD"
assert_says "and records that the runner is self-contained now" \
  'self-contained' "$DELIVER_HEAD"
assert_says "and names the bead that made it so" 'tla-1sh7\.10' "$DELIVER_HEAD"

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
echo "== part 7: the SPEC row kind, and the guards it needed rather than wider ones =="
# ---------------------------------------------------------------------------
# Every guard in the gate read `$1 == "REP"` until 2026-10-17, so the 40 spec
# rows that landed with bead tla-03ep.1 were invisible to all five checks
# rather than mishandled by them. The rows below are the half of that fix the
# header argues for: four of the checks ask a question whose ANSWER DIFFERS BY
# KIND, so a widened guard would have answered it wrongly in silence.
#
# EVERY ROW IS STATIC UNLESS IT SAYS OTHERWISE, so this part costs almost
# nothing. The two that need TLC are the check 1 and check 2 rows at the
# bottom, which are the ones that cannot be static.
# ---------------------------------------------------------------------------

# --- check 4, the spec-only findings ---------------------------------------
M=$(mutant c4-scaffold-gone)
rm "$M/recall/env/spec/gfix-far.tla"
run_gate "$M" --static-only -q
assert_eq "check 4: a scaffold module that is not on disk is a finding" "1" "$GATE_RC"
assert_says "and the detail says every submission would be rc 3" \
  '^FINDING +SCAFFOLD-MISSING +F005 .*rc 3' "$GATE_OUT"

# THE CONFIG IS THE HALF THAT IS EASY TO FORGET and it takes the whole rep out
# of service just as completely: TLC is handed a module with no obligations
# and says nothing about any answer.
M=$(mutant c4-cfg-gone)
rm "$M/recall/env/spec/gfix-far.cfg"
run_gate "$M" --static-only -q
assert_eq "check 4: a scaffold config that is not on disk is a finding too" "1" "$GATE_RC"
assert_says "and the detail says the module would have no obligations" \
  '^FINDING +SCAFFOLD-MISSING +F005 .*no obligations' "$GATE_OUT"

M=$(mutant c4-vector-short)
sed -i "s|${TAB}0,13\$|${TAB}0|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: two scaffolds and one expected code is a finding" "1" "$GATE_RC"
assert_says "and the detail says which code belongs to which scaffold is unknown" \
  '^FINDING +EXPECT-BAD +F005 .*2 scaffold' "$GATE_OUT"

M=$(mutant c4-vector-words)
sed -i "s|${TAB}0,13\$|${TAB}0,fails|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: a field 8 entry that is not an exit code is a finding" "1" "$GATE_RC"
assert_says "and the detail names the scaffold it was expected from" \
  '^FINDING +EXPECT-BAD +F005 .*gfix-far' "$GATE_OUT"

M=$(mutant c4-vector-empty)
sed -i "s|${TAB}<>\\\\\\[\\\\\\]${TAB}0,13\$|${TAB}<>\\\\[\\\\]${TAB}|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: an empty field 8 is a finding, since there is no key at all" "1" "$GATE_RC"
assert_says "and the detail says there is nothing to grade against" \
  '^FINDING +EXPECT-BAD +F005 .*no key' "$GATE_OUT"

# BOTH DIRECTIONS OF THE __CHECK__ HOLE. One does not parse; the other is dead
# weight that is delivered to every practice tree and read by nothing.
M=$(mutant c4-check-gone)
# DOUBLE-QUOTED so $TAB expands, which is the whole of what this substitution
# has to find: field 9 is the text after the last tab on F006's row. A
# single-quoted script would look for the literal string ${TAB} and match
# nothing, and the mutation would be a no-op the suite could not see.
sed -i "s|${TAB}TLCGet(\"distinct\") = 3 /\\\\ TLCGet(\"diameter\") = 3\$||" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: a scaffold with a check hole and an empty field 9 is a finding" "1" "$GATE_RC"
assert_says "and the detail says the hole fills with nothing" \
  '^FINDING +CHECK-MISSING +F006' "$GATE_OUT"

M=$(mutant c4-check-unused)
# F005's scaffolds have no __CHECK__ hole, so a field 9 on it goes nowhere.
sed -i "s|${TAB}0,13\$|${TAB}0,13${TAB}TLCGet(\"distinct\") = 9|" "$M/recall/REPS.tsv"
run_gate "$M" --static-only -q
assert_eq "check 4: a field 9 no scaffold has a hole for is a finding" "1" "$GATE_RC"
assert_says "and the detail says it is delivered and never read" \
  '^FINDING +CHECK-UNUSED +F005' "$GATE_OUT"

# --- check 6, which has no REP-corpus analogue at all ----------------------
# THE FIRST TWO ARE THE WORST KIND OF SCAFFOLD DEFECT, because they do not
# grade an answer wrongly: they grade every answer to every rep over that
# scaffold IDENTICALLY, so the rep stops discriminating and nothing else says
# so.
M=$(mutant c6-no-hole)
sed -i 's|^__ANSWER__$|TRUE|' "$M/recall/env/spec/gfix-near.tla"
run_gate "$M" --static-only -q
assert_eq "check 6: a scaffold with no answer hole is a finding" "1" "$GATE_RC"
assert_says "and the detail says every submission would grade the same" \
  '^FINDING +SCAFFOLD-NO-HOLE +gfix-near .*grades the same' "$GATE_OUT"

M=$(mutant c6-two-holes)
sed -i 's|^Checked ==$|Checked ==\n__ANSWER__\nOther ==|' "$M/recall/env/spec/gfix-near.tla"
run_gate "$M" --static-only -q
assert_eq "check 6: a scaffold with two answer holes is a finding" "1" "$GATE_RC"
assert_says "and the detail counts them" \
  '^FINDING +SCAFFOLD-TWO-HOLES +gfix-near .*2 __ANSWER__' "$GATE_OUT"

# THE HEADER HAS TO NAME `Scaffold` because the runner copies the file to
# Scaffold.tla and rewrites nothing, so a header naming anything else is
# rc 255 on every submission to every rep over it.
M=$(mutant c6-bad-header)
sed -i 's|^---- MODULE Scaffold ----$|---- MODULE Near ----|' "$M/recall/env/spec/gfix-near.tla"
run_gate "$M" --static-only -q
assert_eq "check 6: a header that does not name Scaffold is a finding" "1" "$GATE_RC"
assert_says "and the detail says the runner rewrites nothing" \
  '^FINDING +SCAFFOLD-BAD-SHAPE +gfix-near .*rewrites nothing' "$GATE_OUT"

M=$(mutant c6-no-end)
sed -i 's|^====$||' "$M/recall/env/spec/gfix-near.tla"
run_gate "$M" --static-only -q
assert_eq "check 6: a scaffold with no closing line is a finding" "1" "$GATE_RC"
assert_says "and the detail says the module never ends" \
  '^FINDING +SCAFFOLD-BAD-SHAPE +gfix-near .*never ends' "$GATE_OUT"

# THE FIRST LINE IS PRINTED TO A LEARNER under a wrong answer, which is why it
# is a shape requirement rather than a style one: it is the only thing a spec
# rep's report says about the machine the answer was put in.
M=$(mutant c6-no-about)
sed -i '1s|.*|VARIABLES unexpected|' "$M/recall/env/spec/gfix-near.tla"
run_gate "$M" --static-only -q
assert_eq "check 6: a first line that is not a comment is a finding" "1" "$GATE_RC"
assert_says "and the detail says it is what a wrong answer is told" \
  '^FINDING +SCAFFOLD-BAD-SHAPE +gfix-near .*wrong answer is told' "$GATE_OUT"

M=$(mutant c6-short-about)
sed -i '1s|.*|\\* a counter|' "$M/recall/env/spec/gfix-near.tla"
run_gate "$M" --static-only -q
assert_eq "check 6: a first line too short to describe a machine is a finding" "1" "$GATE_RC"
assert_says "and the detail counts the characters" \
  '^FINDING +SCAFFOLD-BAD-SHAPE +gfix-near .*characters' "$GATE_OUT"

# THE ORPHAN SWEEP RUNS OVER THE TREE, which is the only way it could find
# this: no row and no list mentions the file. It matters because
# scripts/deliver-recall.sh sweeps env/ with `find -type f`, so a scaffold no
# row reads still lands in every practice tree.
M=$(mutant c6-orphan)
cp "$M/recall/env/spec/gfix-near.tla" "$M/recall/env/spec/gfix-nobody.tla"
cp "$M/recall/env/spec/gfix-near.cfg" "$M/recall/env/spec/gfix-nobody.cfg"
run_gate "$M" --static-only -q
assert_eq "check 6: a scaffold no row names is a finding" "1" "$GATE_RC"
assert_says "and the detail says it is delivered and read by nothing" \
  '^FINDING +SCAFFOLD-ORPHAN +gfix-nobody' "$GATE_OUT"

# A .cfg with no .tla is NOT an orphan by this sweep, because the sweep walks
# the modules. It is reported through SCAFFOLD-MISSING at check 4 instead,
# which the c4-cfg-gone row above covers. Stated rather than left as a gap.

# --- check 1 and check 2, the two that cannot be static --------------------
# A SPEC CANONICAL THAT DOES NOT PRODUCE ITS VECTOR is check 1's spec arm, and
# it is strictly stronger than the REP arm: a REP row's canonical is compared
# against ITSELF, while this one is compared against a code written down
# separately. Breaking field 8 alone, with the canonical untouched, is what
# proves the two sides are independent.
M=$(mutant c1-spec-vector)
sed -i "s|${TAB}0,13\$|${TAB}0,0|" "$M/recall/REPS.tsv"
run_gate "$M"
assert_eq "check 1: a SPEC canonical that does not match its own field 8 is a finding" \
  "1" "$GATE_RC"
assert_says "and it reports the runner's vector code rather than a TLC code" \
  '^FINDING +CANONICAL-NOT-CORRECT +F005 .*rc 5' "$GATE_OUT"
assert_says "and says either the answer or the key is wrong, since one run cannot tell" \
  'either the answer or the key is wrong' "$GATE_OUT"

# A SPEC MISS THAT IS A CORRECT FORM. The worst thing either table can hold is
# an explanation saying a right answer is a mistake, and that is as true of a
# vector as of a value.
M=$(mutant c2-spec-right)
sed -i "s|${TAB}\\[\\]<>(n = 2)${TAB}|${TAB}<>[](n = 2)${TAB}|" "$M/recall/MISSES.tsv"
run_gate "$M"
assert_eq "check 2: a SPEC miss row that is a CORRECT form is a finding" "1" "$GATE_RC"
assert_says "and the code says a right answer is being called a mistake" \
  '^FINDING +MISS-NOT-WRONG +F005' "$GATE_OUT"

# THE CONTROL FOR THE TWO ROWS ABOVE. The clean run at the top of part 3
# already passed both, which is the gate ACCEPTING a spec rep's correct
# canonical and its recorded wrong answer, so neither row above is only
# proving that any spec row at all is refused.
run_gate "$CLEAN"
assert_eq "check 1 and 2 CONTROL: the clean spec rows stay green through TLC" "0" "$GATE_RC"

# WHAT A WIDENED GUARD WOULD HAVE DONE, measured rather than argued. A check 2
# that took rc 10 as the wrong-answer code for every row kind would report
# F005's miss as not-wrong, because a spec rep's wrong answer is rc 5. The
# runner is the authority on that number, so it is read from the runner here.
SPEC_MISS_RC=0
"$CLEAN/recall/recall.sh" -q --reps "$CLEAN/recall/REPS.tsv" \
  --env-dir "$CLEAN/recall/env" -- F005 '[]<>(n = 2)' >/dev/null 2>&1 || SPEC_MISS_RC=$?
assert_eq "a spec rep's recorded wrong answer scores 5 and not 10" "5" "$SPEC_MISS_RC"
REP_MISS_RC=0
"$CLEAN/recall/recall.sh" -q --reps "$CLEAN/recall/REPS.tsv" \
  --env-dir "$CLEAN/recall/env" -- F003 '[w \in Wagons |-> Tracks]' >/dev/null 2>&1 || REP_MISS_RC=$?
assert_eq "and a value rep's scores 10 and not 5, which is why the kind is looked up" \
  "10" "$REP_MISS_RC"

echo
echo "== part 8: the counts the prose writes, against what the tables hold =="
# ---------------------------------------------------------------------------
# WHY THIS PART EXISTS. One miss row for R024 on 2026-10-17 moved four numbers
# that about twenty sentences under recall/, harness/ and scripts/ write out by
# hand. One of those sentences was an assertion and it went red. The rest are
# prose and would have gone quietly wrong. The search meant to find them named
# three phrasings and missed a fourth, which was that assertion, so the only
# site that caught the change was the site nobody had found. Bead tla-z4f3.
#
# Frank's call was to keep the prose and gate it rather than cut the counts.
# Several of them are the argument rather than decoration: recall/recall.sh and
# recall/README.md both settle the ORDER of the report block from the ratio of
# reps with no row to reps with one, so a sentence with the number taken out
# says nothing.
#
# HOW IT WORKS. One awk pass over the two shipped tables derives every count
# the prose claims. The manifest then names each site as a file plus the exact
# sentence, with every count replaced by a placeholder. Each entry has to be
# present once the placeholders are expanded, so a count that moves reddens
# every site still spelling the old one and the failure list IS the edit list.
#
# NO COUNT IS WRITTEN ANYWHERE IN THIS PART, which is a rule rather than a
# coincidence. A literal here would be one more site to keep, and the scan at
# the bottom would flag it.
#
# TWO DISPOSITIONS, AND THE DIFFERENCE IS ITSELF GATED.
#
#   PIN   the number is derived. The entry carries at least one placeholder.
#   NOTE  the number is not derived. The entry carries none, and its `what`
#         field says why: a timeout, a line range, a dated claim about what
#         landed with a named bead, or a count this bead found stale in a file
#         outside its own footprint.
#
# A PIN with no placeholder is a frozen literal wearing a derived entry's
# name, and a NOTE with one is a derived count hiding in the waiver list, so
# the loop refuses both.
#
# EVERY ENTRY HAS TO MATCH SOMETHING. An entry matching nothing is a standing
# claim about a line that no longer exists, which is how a waiver list rots
# into a blanket waiver. harness/test-pipefail.sh makes the same rule about
# its own allowlist and for the same reason. It also means a NOTE on a stale
# count goes red the day somebody fixes the site, which is the day it wants
# promoting to a PIN.
#
# THE FILE SET IS FOUND RATHER THAN LISTED, so a file that lands later is
# covered the moment it does. test-pipefail.sh picks its scan set the same
# way. scripts/ is in it because scripts/deliver-recall.sh writes a count too,
# and that is one of the two surfaces the bead's own scan did not name.
# ---------------------------------------------------------------------------

P8_TMP="$TMPROOT/counts"
mkdir -p "$P8_TMP"

# --- the derivation -------------------------------------------------------
# ONE PASS, NO TLC. REPS.tsv comes first so a MISS row can be looked up by the
# kind of the rep it names, which is what splits the value side from the spec
# side. Field 4 of a SPEC row is a comma-separated scaffold list, so the
# scaffold total is a distinct count over it rather than a count of rows.
P8_LINE=$(awk -F'\t' '
  FNR == NR {
    if ($1 == "REP" || $1 == "SPEC") { kind[$2] = $1; con[$2] = $3 }
    if ($1 == "REP")  { reptot++;  repcon[$3] = 1 }
    if ($1 == "SPEC") {
      spectot++; speccon[$3] = 1
      n = split($4, s, ",")
      for (i = 1; i <= n; i++) { gsub(/^ +| +$/, "", s[i]); scaffold[s[i]] = 1 }
    }
    next
  }
  $1 == "MISS" {
    misstot++
    if (kind[$2] == "REP")  { repmiss++;  repwith[$2] = 1; repconhit[con[$2]] = 1 }
    if (kind[$2] == "SPEC") { specmiss++; specwith[$2] = 1; specconhit[con[$2]] = 1 }
  }
  END {
    printf "%d %d %d %d %d", misstot, reptot, spectot, reptot + spectot, length(scaffold)
    printf " %d %d %d", repmiss, length(repwith), reptot - length(repwith)
    printf " %d %d %d", specmiss, length(specwith), spectot - length(specwith)
    printf " %d %d %d", length(repcon), length(repconhit), length(repcon) - length(repconhit)
    printf " %d %d\n", length(speccon), length(specconhit)
  }
' "$LIVE_RECALL/REPS.tsv" "$LIVE_RECALL/MISSES.tsv")

read -r C_MISS C_REPTOT C_SPECTOT C_CANON C_SCAFFOLD \
        C_REPMISS C_REPWITH C_REPNONE \
        C_SPECMISS C_SPECWITH C_SPECNONE \
        C_REPCON C_REPCONHIT C_REPCONNONE \
        C_SPECCON C_SPECCONHIT <<<"$P8_LINE"

# THE DERIVATION GETS ITS OWN ROW SO A RED ROW BELOW READS RIGHT. Without it a
# mis-resolved path derives zero everywhere, every site goes red at once, and
# the run says the prose drifted when what broke was the scan.
if [ "${C_MISS:-0}" -gt 0 ] && [ "${C_REPTOT:-0}" -gt 0 ] && [ "${C_SPECTOT:-0}" -gt 0 ] \
   && [ "${C_REPWITH:-0}" -gt 0 ] && [ "${C_SPECWITH:-0}" -gt 0 ] \
   && [ "${C_SCAFFOLD:-0}" -gt 0 ] && [ "${C_REPCONHIT:-0}" -gt 0 ]; then
  ok "the derivation read both shipped tables, so a red row below is a stale sentence and not a broken scan"
else
  nope "the derivation read both shipped tables (got: $P8_LINE)"
fi

# A SECOND ROUTE TO THE SAME NUMBER. The gate counts miss rows itself and part
# 4 captured what it reported, so this row says the awk above and the gate's
# own counter agree. Two routes to one number is what makes either worth
# quoting anywhere else.
assert_says "and the gate's own run agrees with it on the miss-row total" \
  "${C_MISS} miss row\\(s\\)" "$LIVE_OUT"

# --- English for a count --------------------------------------------------
# One site opens a paragraph with the number spelled out, and no scan over
# digits reaches it. Spelling it here is what lets that site be a PIN rather
# than a waiver.
P8_ONES=(zero one two three four five six seven eight nine ten eleven twelve
         thirteen fourteen fifteen sixteen seventeen eighteen nineteen)
P8_TENS=("" "" twenty thirty forty fifty sixty seventy eighty ninety)

p8_spell() {
  local n="$1" t u
  if [ "$n" -lt 20 ]; then printf '%s' "${P8_ONES[n]}"; return 0; fi
  # Out of range is loud rather than silent. The PIN that wanted the word
  # fails and prints this, which beats a quiet mismatch nobody can see.
  if [ "$n" -gt 99 ]; then printf 'SPELL-OUT-OF-RANGE-%s' "$n"; return 0; fi
  t=$((n / 10)); u=$((n % 10))
  if [ "$u" -eq 0 ]; then printf '%s' "${P8_TENS[t]}"
  else printf '%s-%s' "${P8_TENS[t]}" "${P8_ONES[u]}"; fi
}

C_REPNONE_W=$(p8_spell "$C_REPNONE")
C_SPECNONE_W=$(p8_spell "$C_SPECNONE")
C_REPCONNONE_W=$(p8_spell "$C_REPCONNONE")

# --- the substitution table -----------------------------------------------
# Every name is delimited by @ at both ends, so no name is a prefix of another
# and the order of this table cannot change what a template expands to.
P8_SUBST=(
  "@MISS@=$C_MISS"
  "@REPTOT@=$C_REPTOT"
  "@SPECTOT@=$C_SPECTOT"
  "@CANON@=$C_CANON"
  "@SCAFFOLD@=$C_SCAFFOLD"
  "@REPMISS@=$C_REPMISS"
  "@REPWITH@=$C_REPWITH"
  "@REPNONE@=$C_REPNONE"
  "@SPECMISS@=$C_SPECMISS"
  "@SPECWITH@=$C_SPECWITH"
  "@SPECNONE@=$C_SPECNONE"
  "@REPCON@=$C_REPCON"
  "@REPCONHIT@=$C_REPCONHIT"
  "@REPCONNONE@=$C_REPCONNONE"
  "@SPECCON@=$C_SPECCON"
  "@SPECCONHIT@=$C_SPECCONHIT"
  "@REPNONE_U@=${C_REPNONE_W^^}"
  "@SPECNONE_W@=$C_SPECNONE_W"
  "@REPCONNONE_U@=${C_REPCONNONE_W^^}"
)

p8_expand() {
  local t="$1" pair name val
  for pair in "${P8_SUBST[@]}"; do
    name=${pair%%=*}; val=${pair#*=}
    t=${t//"$name"/$val}
  done
  printf '%s' "$t"
}

# --- the manifest ---------------------------------------------------------
# Four fields, bar separated: disposition, file, what the number is, and the
# text. No template needs a bar, and the loop refuses an entry that does not
# split into four, so the separator cannot go wrong in silence.
P8_SITES=(
  "PIN|recall/MISSES.tsv|the miss-row total|says. @MISS@ rows:"
  "PIN|recall/MISSES.tsv|the value side of the header|# @REPMISS@ over @REPWITH@ of the @REPTOT@ REP rows in recall/REPS.tsv, reaching @REPCONHIT@ of their @REPCON@"
  "PIN|recall/MISSES.tsv|the spec side of the header|# constructs, and @SPECMISS@ over @SPECWITH@ of the @SPECTOT@ SPEC rows, reaching @SPECCONHIT@ of their @SPECCON@."
  "PIN|recall/MISSES.tsv|no row being the normal case|RUNG. @REPNONE@ of the @REPTOT@ REP"
  "PIN|recall/MISSES.tsv|why the spec rows are denser|So @SPECWITH@ of the @SPECTOT@ SPEC rows carry a"
  "PIN|recall/MISSES.tsv|and the value side they are denser than|# row where @REPWITH@ of the @REPTOT@ REP rows do."
  "PIN|recall/MISSES.tsv|the constructs no row reaches, spelled out|# @REPCONNONE_U@ OF THE @REPCON@ CONSTRUCTS HAVE NO ROW"
  "PIN|recall/MISSES.tsv|the spec section's own count|@SPECMISS@ wrong answers over @SPECWITH@ of the @SPECTOT@ SPEC"
  "PIN|recall/MISSES.tsv|the spec rows with no row, spelled out|# written. The @SPECNONE_W@ with no row are S037 and S038"
  "PIN|recall/README.md|the ratio the block order rests on|the reason is the @REPNONE@ reps"
  "PIN|recall/README.md|and the other half of that ratio|with no row rather than the @REPWITH@ that have one."
  "PIN|recall/README.md|where the order the README rejects ends|entry at all @REPTOT@. The other order ends on the sheet at @REPNONE@ and on the"
  "PIN|recall/README.md|and what that order ends on instead|misconception at @REPWITH@, so the bottom of the block moves under you."
  "PIN|recall/README.md|why nothing announces an absence|@REPNONE@ of the @REPTOT@ reps carry no miss row,"
  "PIN|recall/README.md|the miss table's value side|first field \`MISS\`. @MISS@ rows: @REPMISS@ over @REPWITH@ of the @REPTOT@ value reps, reaching @REPCONHIT@ of"
  "PIN|recall/README.md|the miss table's spec side|their @REPCON@ constructs, and @SPECMISS@ over @SPECWITH@ of the @SPECTOT@ spec reps, reaching @SPECCONHIT@ of their"
  "NOTE|recall/README.md|the value family's construct total, which no miss row moves|not a survey of the 38 constructs."
  "NOTE|recall/README.md|STALE in the sentence about matching on tokens: the whole table, written as its value side. The twin is in recall/recall.sh, which this bead could not edit, so the two have to move together|nobody sees. 30 rows is small"
  "PIN|recall/recall.sh|the ratio the block order rests on|the reason is the @REPNONE@ reps that"
  "PIN|recall/recall.sh|and the other half of that ratio|# have no row rather than the @REPWITH@ that do."
  "PIN|recall/recall.sh|where the order it rejects ends|entry last at @REPNONE@ reps and the miss row last at @REPWITH@, so"
  "PIN|recall/recall.sh|no row being the common case, spelled out|# @REPNONE_U@ OF THE @REPTOT@ REPS CARRY NO MISS ROW"
  "PIN|recall/recall.sh|the layer that is silent|case at @REPNONE@ of the @REPTOT@ reps,"
  "NOTE|recall/recall.sh|STALE in the sentence about within-family confusions: the whole table, written as its value side|recall/MISSES.tsv's 30 rows are mostly"
  "NOTE|recall/recall.sh|STALE in the sentence about matching on tokens: the twin of the recall/README.md entry above, word for word, so the two have to move together|nobody sees. 30"
  "NOTE|recall/recall.sh|a TLC budget in seconds|TIMEOUT=60"
  "NOTE|recall/recall.sh|a line range in that file, which usage() reads|# Lines 2 to 30 of this file"
  "NOTE|recall/recall.sh|the same line range, in the command that reads it|sed -n '2,30p'"
  "NOTE|recall/REPS.tsv|the value family's construct total, which no miss row moves|of the 38 constructs in the four value-producing"
  "PIN|harness/fixtures/recall/MISSES.tsv|the live path the fixture stands in for|the path @REPNONE@ of the @REPTOT@ real reps take."
  "NOTE|harness/fixtures/recall/MISSES.tsv|STALE where the fixture says what the real table carries, and in a file outside this bead's footprint|carries 30 rows, and is reached by one"
  "PIN|harness/test-recall-gate.sh|what this suite pins over the shipped corpus|reps, @SPECTOT@ spec reps, @SCAFFOLD@ scaffolds and @MISS@ miss rows,"
  "PIN|harness/test-recall-gate.sh|what part 4 costs|canonical answers and @MISS@ wrong ones;"
  "PIN|harness/test-recall-gate.sh|what part 4 submits|# @CANON@ canonical answers and @MISS@ wrong ones through the real model checker,"
  "PIN|harness/test-recall-gate.sh|the live gate's own count line|scaffold\\(s\\), @MISS@ miss row\\(s\\)"
  "PIN|harness/test-recall-gate.sh|check 2's count of graded wrong answers|check 2 +@MISS@ wrong answer"
  "NOTE|harness/test-recall-gate.sh|a dated claim about what landed with bead tla-1sh7.2, true whatever the table now holds|value reps and 30 of their misses landed with"
  "NOTE|harness/test-recall-gate.sh|a dated claim about what landed with bead tla-03ep.1, true whatever the table now holds|spec reps over 30 scaffolds and 60 of their misses"
  "NOTE|harness/test-recall-gate.sh|the scaffold total, which no miss row moves|check 6 +30 scaffold"
  "PIN|harness/recall-gate.sh|what a kind-blind check 2 would have mislabeled|call all @SPECMISS@ spec misses"
  "PIN|harness/recall-gate.sh|the rows rc 10 cannot tell apart|a green run as \"all @REPMISS@"
  "NOTE|harness/recall-gate.sh|a dated claim about what landed on 2026-10-16, true whatever the table now holds|reps and 30 miss rows landed on"
  "NOTE|harness/recall-gate.sh|the runner's budget in seconds|a fixed 60-second budget"
  "NOTE|harness/recall-gate.sh|STALE where check 2 says what a lost miss table costs, and in a file outside this bead's footprint|has lost 30 explanations"
  "PIN|harness/test-recall-runner.sh|the path the fixture's no-row case reaches|the path @REPNONE@ of the @REPTOT@ real reps take."
  "PIN|harness/test-recall-runner.sh|why the silent row matters most|SILENT ONE. @REPNONE@ of the @REPTOT@ real reps"
  "PIN|harness/test-recall-runner.sh|what settles the block order|What settles it is the @REPNONE@ reps with no row:"
  "PIN|harness/test-recall-runner.sh|how many spec rows carry a miss row|the spec rows carry at @SPECWITH@ of @SPECTOT@"
  "NOTE|scripts/deliver-recall.sh|STALE in the delivery manifest's line for MISSES.tsv, and in a file outside this bead's footprint|the 30 recorded wrong answers"
  "NOTE|scripts/gen-misses.sh|a line range in that file, which usage() reads|sed -n '30,50p'"
)

# --- the file set ---------------------------------------------------------
P8_FOUND=$(
  find recall harness/fixtures/recall -type f \
       \( -name '*.md' -o -name '*.sh' -o -name '*.tsv' \)
  find harness scripts -maxdepth 1 -type f \
       \( -name '*recall*' -o -name '*misses*' \)
)
readarray -t P8_FILES <<<"$P8_FOUND"
assert_says "the found file set carries recall/MISSES.tsv, so the scan below reads something" \
  '^recall/MISSES\.tsv$' "$P8_FOUND"

# --- every entry, expanded and required present ---------------------------
# grep -F over the file rather than the suite's `has`, because a template is a
# sentence and not a pattern, and one of them carries a backslash the file
# holds literally. This reads a file instead of a pipe, so the 141 hazard
# `has` exists for is not in play.
P8_BAD=0
for p8_entry in "${P8_SITES[@]}"; do
  IFS='|' read -r p8_disp p8_file p8_what p8_text <<<"$p8_entry"
  if [ -z "$p8_disp" ] || [ -z "$p8_file" ] || [ -z "$p8_what" ] || [ -z "$p8_text" ]; then
    nope "a manifest entry does not split into four fields: $p8_entry"
    P8_BAD=$((P8_BAD + 1))
    continue
  fi
  p8_want=$(p8_expand "$p8_text")
  case "$p8_disp" in
    PIN)
      if [ "$p8_want" = "$p8_text" ]; then
        nope "$p8_file: a PIN with no placeholder is a frozen literal ($p8_what)"
        P8_BAD=$((P8_BAD + 1)); continue
      fi
      ;;
    NOTE)
      if [ "$p8_want" != "$p8_text" ]; then
        nope "$p8_file: a NOTE with a placeholder is a derived count in the waiver list ($p8_what)"
        P8_BAD=$((P8_BAD + 1)); continue
      fi
      ;;
    *)
      nope "a manifest entry carries the unknown disposition $p8_disp: $p8_entry"
      P8_BAD=$((P8_BAD + 1)); continue
      ;;
  esac
  case "$p8_want" in
    *@*)
      nope "$p8_file: the entry for $p8_what still holds an unexpanded placeholder: $p8_want"
      P8_BAD=$((P8_BAD + 1)); continue
      ;;
  esac
  printf '%s\n' "$p8_want" >>"$P8_TMP/${p8_file//\//_}"
  if grep -Fq -- "$p8_want" "$p8_file"; then
    ok "$p8_file carries $p8_what"
  else
    nope "$p8_file no longer carries $p8_what"
    printf '          wanted the text: %s\n' "$p8_want"
  fi
done
assert_eq "every manifest entry is well formed and carries the disposition its text earns" \
  "0" "$P8_BAD"

# --- the completeness scan ------------------------------------------------
# WHAT THIS CLOSES, and it is the half the manifest alone cannot. A site the
# manifest never named is a site a red run never names either, which is how
# the fourth phrasing survived the search that went looking for it. So every
# line in the found set that writes one of the counts a miss row MOVES has to
# be covered by an entry above.
#
# SIX COUNTS AND NOT ALL SIXTEEN. A miss row moves the miss total, both halves
# of the value side and both halves of the spec side. It does not move the rep,
# spec or construct totals. So the scan is over the digit form of the
# miss-derived counts, and the construct counts and the two spelled-out numbers
# are reached by their manifest entries alone.
#
# A DOT EITHER SIDE OF THE NUMBER DISQUALIFIES IT, and that came out of a
# mutation rather than out of a hunch. Adding one miss row moved the value side
# by one, and the scan then flagged three lines whose only crime was quoting
# the toolchain version `2026.07.31.184830`. A dotted numeric token is a
# version or a time and never a count of rows, so the boundary has to refuse a
# dot as well as a digit.
#
# That rule caught the sentence above as it was first written, which named the
# number the value side had moved to. The no-literals rule at the top of this
# part is gated by this scan and not left to anybody's care.
#
# A COUNT UNDER TEN IS NOT SCANNED, and the row below says so rather than
# letting it drop out quietly. Single figures match most of the arithmetic in
# these files, and a scan that flags every line of it gets read as broken.
#
# WHAT IT STILL CANNOT REACH. A site holding the OLD value of a count it never
# had an entry for stays invisible, since the scan looks for today's numbers.
# That hole is empty at the moment this manifest was written, because the scan
# over the shipped tables classified every line it found.
#
# THE MANIFEST BLOCK IS CUT OUT OF THIS FILE BEFORE IT IS SCANNED. A NOTE on a
# stale count has to carry that count in order to pin it, so the entry's own
# text would otherwise read as one more uncovered site.
P8_SCANNED=""
P8_DROPPED=""
for p8_n in "$C_MISS" "$C_REPMISS" "$C_REPWITH" "$C_REPNONE" "$C_SPECMISS" "$C_SPECWITH"; do
  if [ "$p8_n" -lt 10 ]; then
    P8_DROPPED="$P8_DROPPED $p8_n"
  elif [[ "|$P8_SCANNED|" != *"|$p8_n|"* ]]; then
    P8_SCANNED="${P8_SCANNED:+$P8_SCANNED|}$p8_n"
  fi
done
assert_eq "every miss-derived count is big enough for the scan to look for it" \
  "" "$P8_DROPPED"

# AN EMPTY ALTERNATION MATCHES EVERY LINE, so the scan is skipped rather than
# run on nothing. It only happens where the derivation already went red above,
# and a few thousand findings on top of that row would bury it.
P8_SCAN_RE="(^|[^0-9.])(${P8_SCANNED})([^0-9.]|\$)"
P8_UNCOVERED=0
for p8_file in "${P8_FILES[@]}"; do
  [ -n "$p8_file" ] || continue
  [ -n "$P8_SCANNED" ] || continue
  p8_wants="$P8_TMP/${p8_file//\//_}"
  [ -f "$p8_wants" ] || : >"$p8_wants"
  awk '/^P8_SITES=\(/ { skip = 1 } skip && /^\)$/ { skip = 0; next } !skip' \
    "$p8_file" >"$P8_TMP/body"
  p8_loose=$(awk -v re="$P8_SCAN_RE" '
    FNR == NR { want[++n] = $0; next }
    $0 ~ re {
      for (i = 1; i <= n; i++) if (index($0, want[i])) next
      printf "    %d: %s\n", FNR, $0
    }
  ' "$p8_wants" "$P8_TMP/body")
  if [ -n "$p8_loose" ]; then
    nope "$p8_file writes a miss count at a line the manifest does not name"
    printf '%s\n' "$p8_loose"
    P8_UNCOVERED=$((P8_UNCOVERED + 1))
  fi
done
assert_eq "every miss count in the found set is named by the manifest" "0" "$P8_UNCOVERED"

# THE CONTROL, because a scan that has never flagged anything is not evidence.
# A planted sentence has to come back matched, or the loop above is green
# because its pattern is dead.
P8_PLANT="$P8_TMP/planted"
printf '# a planted sentence: %s of the %s reps carry no miss row\n' \
  "$C_REPNONE" "$C_REPTOT" >"$P8_PLANT"
assert_eq "CONTROL: the scan's own pattern still matches a planted count" "1" \
  "$(awk -v re="$P8_SCAN_RE" '$0 ~ re { n++ } END { print n + 0 }' "$P8_PLANT")"

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
