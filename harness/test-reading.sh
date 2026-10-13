#!/usr/bin/env bash
# test-reading.sh — the controls for harness/reading-gate.sh.
#
# WHAT THIS EXISTS TO STOP. The reading corpus is the only one of the three
# fluency channels whose artifact is READ rather than solved, so a model that
# does not check teaches a shape that does not work, and nobody would notice
# by reading it. reading-gate.sh is the instrument that catches that; this
# suite is the instrument's controls, and it proves the instrument still
# bites in both directions.
#
# Read harness/reading-gate.sh's header for what each of the four checks
# does and — the half that matters more — what it deliberately does not.
# This file does not restate those boundaries; it would drift from them.
#
# ALL FOUR CHECKS GATE. There is no report-only check here, unlike
# harness/drill-gate.sh's check 3: the construct-coverage report is
# deliberately absent from this gate, so there is nothing to pin open.
#
# PART 1  each check, against a fixture built to trip it
# PART 2  controls the other way: shapes that LOOK wrong and must not fire
# PART 3  the real reading/ tree
#
# Usage:  harness/test-reading.sh
# Exit:   0 if all assertions hold, 1 otherwise.
#
# ---------------------------------------------------------------------------
# WHY THIS IS A SLOW-TIER SUITE. Part 1c and part 3 drive harness/verdict.sh
# against real modules, so they run TLC's MODEL CHECKER. By the rule in
# scripts/test's header the boundary is the model checker and not the JVM, so
# this belongs in slow whatever it costs today. Every other fixture runs
# under --no-tlc, which is what keeps the cost flat as the corpus grows.
#
# ITS COST TRACKS THE CORPUS, not this file. Part 3 verifies every item of
# the real tree, so the budget grows as authors land items.
# ---------------------------------------------------------------------------

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

GATE="${REPO_ROOT}/harness/reading-gate.sh"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

if [ ! -f "$GATE" ]; then
  echo "test-reading.sh: ${GATE} is missing — refusing to report success." >&2
  exit 2
fi

TMP="$(mktemp -d)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

GATE_OUT=""
GATE_RC=0

run_gate() {
  GATE_OUT="$(bash "$GATE" "$@" 2>&1)"
  GATE_RC=$?
}

# Assertions read GATE_OUT through a HERE-STRING, never a pipe. A pipe into
# `grep -q` returns 141 under pipefail, which inside an `if` reads as
# "pattern absent" — so a present finding would report as missing and the
# control would pass on a broken instrument. That is the false-PASS
# direction, and harness/test-pipefail.sh bans the idiom outright (bead
# tla-kr9).
has() {
  if grep -qF -- "$2" <<<"$GATE_OUT"; then ok "$1"; else nope "$1 — expected in output: $2"; fi
}
hasnt() {
  if grep -qF -- "$2" <<<"$GATE_OUT"; then nope "$1 — must NOT be in output: $2"; else ok "$1"; fi
}
rc_is() {
  if [ "$GATE_RC" = "$2" ]; then ok "$1"; else nope "$1 — rc=${GATE_RC}, want $2"; fi
}

# ===========================================================================
# FIXTURE BUILDER
#
# Every fixture starts from ONE baseline good item and is then mutated in
# exactly one place. A fixture that differs from the passing one in two ways
# does not tell you which difference the instrument reacted to.
#
# THE BASELINE IS A REAL, CHECKING MODULE and not a stub, because check 3
# runs TLC over it. Two variables, one invariant, one property, rc 0.
# ===========================================================================
mk_item() {
  local root="$1" fam="${2:-core}" slug="${3:-01-base}"
  local d="${root}/${fam}/${slug}"
  mkdir -p "$d"
  cat >"${d}/Base.tla" <<'TLA'
---- MODULE Base ----
EXTENDS Naturals

VARIABLES n, up
vars == <<n, up>>

TypeOK ==
  /\ n \in 0..3
  /\ up \in BOOLEAN

Init == n = 0 /\ up = TRUE

Step ==
  /\ n < 3
  /\ n' = n + 1
  /\ up' = TRUE

Next == Step

Spec == Init /\ [][Next]_vars

Bounded == n <= 3

NeverFalls == [][n' >= n]_vars
====
TLA
  cat >"${d}/Base.cfg" <<'CFG'
SPECIFICATION Spec

INVARIANT TypeOK
INVARIANT Bounded

PROPERTY NeverFalls

CHECK_DEADLOCK FALSE
CFG
  cat >"${d}/USES.md" <<'USES'
# USES: core/01-base

Subject: a counter that climbs to three and stops.

rc: 0

## Constructs

- Operator definition
- Integers
USES
  printf '%s\n' "$d"
}

# wide_line <n>: a comment line of exactly n columns, for the column check.
wide_line() {
  local n="$1" s=""
  while [ "${#s}" -lt "$((n - 3))" ]; do s="${s}x"; done
  printf '\\* %s\n' "$s"
}

echo "test-reading.sh: controls for harness/reading-gate.sh"
echo

# ===========================================================================
# PART 1 — each check, against a fixture built to trip it
# ===========================================================================
echo "PART 1 — the four checks, each against a fixture built to trip it"
echo

# --- 1a: check 1, SHAPE ----------------------------------------------------
R="${TMP}/shape-extra"
D="$(mk_item "$R")"
: >"${D}/NOTES.md"
run_gate --no-tlc "$R"
has   "1a shape: a fourth entry is a finding" "SHAPE-EXTRA-ENTRY"
has   "1a shape: the finding names the entry" "NOTES.md"
rc_is "1a shape: rc 1" 1

R="${TMP}/shape-no-cfg"
D="$(mk_item "$R")"
rm "${D}/Base.cfg"
run_gate --no-tlc "$R"
has   "1a shape: a missing .cfg is a finding" "SHAPE-NO-CFG"
rc_is "1a shape: rc 1 on a missing .cfg" 1

R="${TMP}/shape-no-uses"
D="$(mk_item "$R")"
rm "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1a shape: a missing USES.md is a finding" "SHAPE-NO-USES"
rc_is "1a shape: rc 1 on a missing USES.md" 1

# A stem mismatch is its own finding, because the directory LOOKS complete:
# three entries, one of each kind, and TLC would be pointed at a config that
# does not belong to the module.
R="${TMP}/shape-stem"
D="$(mk_item "$R")"
mv "${D}/Base.cfg" "${D}/Other.cfg"
run_gate --no-tlc "$R"
has   "1a shape: a .tla/.cfg stem mismatch is its own finding" "SHAPE-STEM-MISMATCH"
hasnt "1a shape: a stem mismatch is NOT reported as a missing file" "SHAPE-NO-CFG"
rc_is "1a shape: rc 1 on a stem mismatch" 1

# --- 1b: check 2, THE PHONE BOUND -----------------------------------------
# Both halves, and both must name the number. A bound that fails without
# saying which line is over is not actionable, and the bead's RED spec asks
# for the line by name.
R="${TMP}/phone-long"
D="$(mk_item "$R")"
i=0
while [ "$i" -lt 60 ]; do printf '\\* filler\n' >>"${D}/Base.tla"; i=$((i + 1)); done
run_gate --no-tlc "$R"
has   "1b phone: a module past the line bound is a finding" "PHONE-TOO-LONG"
has   "1b phone: the finding states the bound" "bound is 60"
rc_is "1b phone: rc 1 on too many lines" 1

R="${TMP}/phone-wide"
D="$(mk_item "$R")"
wide_line 80 >>"${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1b phone: a module past the column bound is a finding" "PHONE-TOO-WIDE"
has   "1b phone: the finding names the column count" "80 columns"
rc_is "1b phone: rc 1 on too wide" 1

# ONE COLUMN OVER MUST FIRE. A bound checked with `>=` somewhere would pass
# this and nobody would see it on the six real items, which are all well
# clear of 64.
R="${TMP}/phone-edge"
D="$(mk_item "$R")"
wide_line 65 >>"${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1b phone: 65 columns, one over, fires" "PHONE-TOO-WIDE"
rc_is "1b phone: rc 1 at one column over" 1

# --- 1c: check 3, THE RECORDED rc -----------------------------------------
# THIS ONE RUNS TLC. The baseline records rc 0 and checks; the fixture
# records an rc the module does not produce.
R="${TMP}/rc-mismatch"
D="$(mk_item "$R")"
sed -i 's/^rc: 0$/rc: 12/' "${D}/USES.md"
run_gate "$R"
has   "1c rc: a recorded rc the module does not produce is a finding" "VERIFY-RC-MISMATCH"
has   "1c rc: the finding states both numbers" "records rc 12, TLC returned 0"
rc_is "1c rc: rc 1 on a mismatch" 1

# No rc recorded at all is UNCHECKED, not a finding. The instrument could
# not run; the item is not thereby wrong. That distinction decides the exit
# code, and conflating the two is the defect bead tla-hl96 is about.
R="${TMP}/rc-absent"
D="$(mk_item "$R")"
sed -i '/^rc: 0$/d' "${D}/USES.md"
run_gate "$R"
has   "1c rc: no recorded rc is UNCHECKED rather than a finding" "UNCHECKED"
hasnt "1c rc: no recorded rc does NOT report a mismatch" "VERIFY-RC-MISMATCH"
rc_is "1c rc: rc 99 when no rc is recorded" 99

# --- 1d: check 4, THE .cfg DECLARES AN OBLIGATION -------------------------
R="${TMP}/cfg-none"
D="$(mk_item "$R")"
cat >"${D}/Base.cfg" <<'CFG'
SPECIFICATION Spec
CHECK_DEADLOCK FALSE
CFG
run_gate --no-tlc "$R"
has   "1d cfg: a .cfg with no obligation is a finding" "CFG-NO-OBLIGATION"
rc_is "1d cfg: rc 1 on no obligation" 1

# A COMMENTED-OUT OBLIGATION MUST NOT COUNT. `\*INVARIANT Inv2` is ordinary
# published practice (.claude/rules/tla-practice.md §7) and it is a pointer,
# not a declaration — TLC never sees it.
R="${TMP}/cfg-commented"
D="$(mk_item "$R")"
cat >"${D}/Base.cfg" <<'CFG'
SPECIFICATION Spec
\*INVARIANT TypeOK
CHECK_DEADLOCK FALSE
CFG
run_gate --no-tlc "$R"
has   "1d cfg: a commented-out INVARIANT does not count as one" "CFG-NO-OBLIGATION"
rc_is "1d cfg: rc 1 on a commented-out obligation" 1

# A BARE KEYWORD WITH NO OPERAND MUST NOT COUNT. TLC exits 0 having silently
# checked no invariant (harness/verdict.sh:180-186), so a gate that accepted
# this would hand back a green run over a module nothing was asserted about.
# That is the vacuity direction and it is the worse failure.
R="${TMP}/cfg-bare"
D="$(mk_item "$R")"
cat >"${D}/Base.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT
CHECK_DEADLOCK FALSE
CFG
run_gate --no-tlc "$R"
has   "1d cfg: a bare INVARIANT keyword does not count as one" "CFG-NO-OBLIGATION"
rc_is "1d cfg: rc 1 on a bare keyword" 1

echo

# ===========================================================================
# PART 2 — controls the other way. Shapes that LOOK wrong and must not fire.
#
# These are the half that keeps the gate usable. An instrument that fires on
# every deviation is worse than no instrument, and
# .claude/rules/tla-practice.md §7 lists the published shapes that look like
# defects and are routine.
# ===========================================================================
echo "PART 2 — shapes that look wrong and must NOT fire"
echo

# --- 2a: the baseline passes ----------------------------------------------
R="${TMP}/baseline"
mk_item "$R" >/dev/null
run_gate "$R"
hasnt "2a baseline: no finding on the good item" "FINDING"
has   "2a baseline: reports VERDICT OK" "VERDICT OK"
rc_is "2a baseline: rc 0" 0

# --- 2b: a model SHOWING its constructs is correct, not a finding ---------
# This is the inversion the channel turns on. drill-gate.sh's check 1 fails
# an item that shows the construct it exercises; a reading item shows its
# constructs BY DEFINITION. The marker is a construct token in both the
# module and the USES.md list, which is exactly what the drill gate's layer A
# scans for.
R="${TMP}/telegraph"
D="$(mk_item "$R")"
cat >>"${D}/USES.md" <<'USES'
- UNCHANGED
- WF_v(A) (weak fairness)
- ~> (leads-to)
- [P]_x (box action formula)
USES
run_gate "$R"
hasnt "2b telegraph: a declared construct shown in the module is NOT a finding" "FINDING"
hasnt "2b telegraph: no telegraph check was ported" "TELEGRAPH"
rc_is "2b telegraph: rc 0" 0

# --- 2c: the generated translation block's wide comments are exempt -------
# pcal writes two comment lines nobody can narrow, and `-lineWidth` has a
# floor of 60 and does not touch either. Without the exemption no item with
# a committed translation can ever pass. See CHECK 2 in the gate's header.
R="${TMP}/tr-exempt"
D="$(mk_item "$R")"
{
  printf '\\* BEGIN TRANSLATION (chksum(pcal) = "b18ee4" /\\ chksum(tla) = "5c58e758")\n'
  printf '(* Allow infinite stuttering to prevent deadlock on termination. *)\n'
  printf '\\* END TRANSLATION \n'
} >>"${D}/Base.tla"
run_gate --no-tlc "$R"
hasnt "2c translation: pcal's wide generated comments are exempt" "PHONE-TOO-WIDE"

# AND THE EXEMPTION IS NARROW. A wide comment OUTSIDE the block still fires,
# so an author cannot park one anywhere and call it generated.
R="${TMP}/tr-narrow-outside"
D="$(mk_item "$R")"
{
  printf '\\* BEGIN TRANSLATION (chksum(pcal) = "b18ee4")\n'
  printf '\\* END TRANSLATION \n'
} >>"${D}/Base.tla"
wide_line 80 >>"${D}/Base.tla"
run_gate --no-tlc "$R"
has   "2c translation: a wide comment AFTER the block still fires" "PHONE-TOO-WIDE"

# AND A WIDE FORMULA INSIDE THE BLOCK STILL FIRES. The exemption covers
# comment-only lines, never spec text, which is the part a reader reads.
R="${TMP}/tr-narrow-formula"
D="$(mk_item "$R")"
{
  printf '\\* BEGIN TRANSLATION (chksum(pcal) = "b18ee4")\n'
  printf 'Widest == n = 0 \\/ n = 1 \\/ n = 2 \\/ n = 3 \\/ n = 4 \\/ n = 5 \\/ n = 6\n'
  printf '\\* END TRANSLATION \n'
} >>"${D}/Base.tla"
run_gate --no-tlc "$R"
has   "2c translation: a wide FORMULA inside the block still fires" "PHONE-TOO-WIDE"

# --- 2d: the line count is NOT exempted inside the block -----------------
# The exemption is about columns only. A translation that pushes an item past
# the line bound is still a finding, because those lines are still scrolled
# past on the phone.
R="${TMP}/tr-lines"
D="$(mk_item "$R")"
{
  printf '\\* BEGIN TRANSLATION (chksum(pcal) = "b18ee4")\n'
  i=0
  while [ "$i" -lt 60 ]; do printf '\\* generated filler\n'; i=$((i + 1)); done
  printf '\\* END TRANSLATION \n'
} >>"${D}/Base.tla"
run_gate --no-tlc "$R"
has   "2d translation: generated lines still count toward the LINE bound" "PHONE-TOO-LONG"
hasnt "2d translation: and they are still exempt from the COLUMN bound" "PHONE-TOO-WIDE"

# --- 2e: a family directory is not an item -------------------------------
# The sweep takes depth-2 directories. A stray file at depth 1 must not be
# read as an item, and must not make the gate miss the real one.
R="${TMP}/depth"
mk_item "$R" >/dev/null
: >"${R}/README.md"
mkdir -p "${R}/core/01-base/verify"
run_gate --no-tlc "$R"
has   "2e sweep: a depth-3 directory inside an item is a fourth entry" "SHAPE-EXTRA-ENTRY"
rmdir "${R}/core/01-base/verify"
run_gate --no-tlc "$R"
hasnt "2e sweep: a file at the root is not swept as an item" "README.md"
has   "2e sweep: exactly one item found beside it" "1 item(s)"

# --- 2f: --no-tlc can never exit 0 ---------------------------------------
# It was asked to reproduce the recorded rcs and did not, so it carries that
# forward as CHECK_DID_NOT_RUN. Same distinction drill-gate.sh draws between
# --no-tlc and --static-only.
R="${TMP}/notlc"
mk_item "$R" >/dev/null
run_gate --no-tlc "$R"
rc_is "2f --no-tlc: rc 99 even on the baseline that passes" 99
has   "2f --no-tlc: says the check was not run" "the check was not run"

# --- 2g: usage errors ----------------------------------------------------
run_gate
rc_is "2g usage: no root given is rc 2" 2
run_gate "${TMP}/does-not-exist"
rc_is "2g usage: a missing root is rc 2" 2
run_gate --what "$R"
rc_is "2g usage: an unknown option is rc 2" 2
run_gate "$R" "$R"
rc_is "2g usage: two roots is rc 2" 2

# An EMPTY root is UNCHECKED, not rc 0. A gate asked to check items that
# finds none has not answered the question it was asked.
R="${TMP}/empty"
mkdir -p "$R"
run_gate --no-tlc "$R"
rc_is "2g usage: an empty root is rc 99, not 0" 99
has   "2g usage: and says no item was found" "no item found"

echo

# ===========================================================================
# PART 3 — the real reading/ tree
#
# Not conditional on the tree being clean: this row is the one that fails
# when an authored model stops checking. It IS conditional on the tree
# existing, so the suite is not red in a checkout where the corpus has not
# landed yet.
# ===========================================================================
echo "PART 3 — the real reading/ tree"
echo

READING_ITEMS=0
if [ -d "${REPO_ROOT}/reading" ]; then
  # The hidden-dir predicate is anchored at the reading root. `! -path '*/.*'`
  # would match REPO_ROOT itself, since every dispatched worker here runs
  # under .claude/worktrees/agent-*, and the count would be 0 on any real
  # tree. Recorded in harness/test-drill.sh's part 3.
  READING_ITEMS="$(find "${REPO_ROOT}/reading" -mindepth 2 -maxdepth 2 -type d \
    ! -name '.*' ! -path "${REPO_ROOT}/reading/.*" | wc -l)"
fi

if [ ! -d "${REPO_ROOT}/reading" ]; then
  ok "real tree: reading/ does not exist yet — nothing to guarantee, and that is reported rather than passed over"
  echo "        The gate bites the moment an item lands. Until then this row is a"
  echo "        statement about the tree, not a check that ran."
elif [ "$READING_ITEMS" -eq 0 ]; then
  ok "real tree: reading/ exists and holds no item yet"
  echo "        This row gates as soon as one item exists."
else
  run_gate "${REPO_ROOT}/reading"
  if [ "$GATE_RC" = "0" ]; then
    ok "real tree: ${READING_ITEMS} item(s), clean on all four checks"
  else
    nope "real tree: reading-gate.sh returned rc=${GATE_RC} over reading/ (${READING_ITEMS} items)"
    printf '%s\n' "$GATE_OUT" | sed 's/^/        /'
    echo "        rc 1 is a finding to fix. rc 99 means a check COULD NOT RUN over an"
    echo "        item that exists — most likely a USES.md with no 'rc: <number>' line."
  fi
fi

# ===========================================================================
echo
echo "test-reading.sh: ${pass_count} passed, ${fail_count} failed"
[ "$fail_count" -eq 0 ]
