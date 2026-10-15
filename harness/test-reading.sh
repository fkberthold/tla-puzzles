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
# Read harness/reading-gate.sh's header for what each check does and, the
# half that matters more, what it deliberately does not. This file does not
# restate those boundaries, because it would drift from them. The count of
# checks is left out of that sentence on purpose. It read "four" while the
# gate carried six.
#
# EVERY CHECK GATES. There is no report-only check here, unlike
# harness/drill-gate.sh's check 3: the construct-coverage report is
# deliberately absent from this gate, so there is nothing to pin open.
#
# PART 1  each check, against a fixture built to trip it
#         1a shape · 1b phone bound · 1c recorded rc · 1d obligation
#         1e construct declaration · 1f USES.md shape · 1g collisions
# PART 2  controls the other way: shapes that LOOK wrong and must not fire
# PART 3  the real reading/ tree
#
# CHECKS 5 AND 6 ARRIVED WITH BEAD tla-fwkz.2.8, and two of their controls
# are the ones worth keeping an eye on. Check 5 runs in ONE direction, so 2i
# pins that an over-declaration stays silent. Check 1 now skips TLC's own run
# artifacts, so 2h pins that the skip stays narrow enough to still catch a
# stray .bak.
#
# CHECKS 7 AND 8 ARRIVED WITH BEAD tla-ldvw, and 2k is the part of this file
# to read first. They are the only two checks here that compare items against
# EACH OTHER, so the thing that can go wrong is not a missed duplicate but a
# gate nobody can land work through. 2k names the two real pairs the
# thresholds were measured against, so a red row says which pair moved.
#
# 2l PINS A SENTENCE RATHER THAN A BEHAVIOR, which is unusual and deliberate.
# Checks 7 and 8 buy half of what tla-ldvw asked for, and the gate says which
# half in its own output. An advisory half of a gate that presents itself as
# whole is worse than a gate that states its limit, so the statement is a
# gated string.
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
  # THE BASELINE USES.md IS NORMALIZED, which checks 5 and 6 made load-
  # bearing. Before bead tla-fwkz.2.8 it carried no probe section and
  # declared neither EXTENDS nor VARIABLES, and the module text carries
  # both, so the old baseline now trips three findings. A baseline that
  # fails is not a baseline, and every fixture below is one mutation away
  # from this file.
  cat >"${d}/USES.md" <<'USES'
# USES: core/01-base

Subject: a counter that climbs to three and stops.

rc: 0

## What the properties rest on

`Bounded` rests on Step's `n < 3` guard. Raise it to `n < 4` and the run
gives rc 12.

## Constructs

- Operator definition
- Integers

## Constructs from other families, also exercised

- EXTENDS (module import)
- VARIABLE / VARIABLES
USES
  printf '%s\n' "$d"
}

# set_subject <USES.md> <first line> [more lines...]: replace the baseline's
# one-line Subject with the lines given.
#
# IT TAKES SEVERAL LINES ON PURPOSE. A real Subject is prose and it wraps, so
# the checks that read one have to read it flattened. Every fixture below that
# is meant to collide carries a Subject over two or three lines, because a
# one-line fixture would pass a line-based reader and prove nothing. This
# corpus has produced a plausible wrong count from a line-based scan five
# times in one session.
set_subject() {
  local f="$1"
  shift
  local first="$1"
  shift
  {
    printf '# USES: core/01-base\n\n'
    printf 'Subject: %s\n' "$first"
    local l
    for l in "$@"; do printf '%s\n' "$l"; done
    printf '\n'
    sed -n '/^rc: /,$p' "$f"
  } >"${f}.new"
  mv "${f}.new" "$f"
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
echo "PART 1 — each check, against a fixture built to trip it"
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
# clear of 77.
R="${TMP}/phone-edge"
D="$(mk_item "$R")"
wide_line 78 >>"${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1b phone: 78 columns, one over, fires" "PHONE-TOO-WIDE"
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

# --- 1e: check 5, THE CONSTRUCT DECLARATION -------------------------------
# The bead's RED line: a module whose text carries EXTENDS and whose USES.md
# omits it must produce a finding that NAMES the construct. Naming it is the
# half that makes the finding actionable, so each assertion below pins the
# name and not just the code.
R="${TMP}/decl-extends"
D="$(mk_item "$R")"
sed -i '/^- EXTENDS (module import)$/d' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1e decl: EXTENDS in the text and not declared is a finding" "USES-CONSTRUCT-UNDECLARED"
has   "1e decl: the finding names the construct" "carries EXTENDS (module import) and USES.md does not declare it"
rc_is "1e decl: rc 1" 1

R="${TMP}/decl-variables"
D="$(mk_item "$R")"
sed -i '/^- VARIABLE \/ VARIABLES$/d' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1e decl: VARIABLES in the text and not declared is a finding" "carries VARIABLE / VARIABLES and USES.md does not declare it"
rc_is "1e decl: rc 1 on an undeclared VARIABLES" 1

# THE OTHER FIVE, each added to the baseline's text and left undeclared. The
# first attempt at these fixtures deleted a bullet the baseline never had, so
# the sed was a no-op and the fixture proved nothing. Here the construct is
# ADDED to the module, which cannot silently miss.
R="${TMP}/decl-constant"
D="$(mk_item "$R")"
sed -i 's/^EXTENDS Naturals$/EXTENDS Naturals\nCONSTANT Cap/' "${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1e decl: an added CONSTANT is named" "carries CONSTANT and USES.md does not declare it"

R="${TMP}/decl-assume"
D="$(mk_item "$R")"
sed -i 's/^EXTENDS Naturals$/EXTENDS Naturals\nASSUME 1 < 2/' "${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1e decl: an added ASSUME is named" "carries ASSUME and USES.md does not declare it"

R="${TMP}/decl-unchanged"
D="$(mk_item "$R")"
sed -i 's/^Next == Step$/Hold == UNCHANGED vars\nNext == Step/' "${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1e decl: an added UNCHANGED is named" "carries UNCHANGED and USES.md does not declare it"

R="${TMP}/decl-wf"
D="$(mk_item "$R")"
sed -i 's/^Spec == Init \/\\ \[\]\[Next\]_vars$/Spec == Init \/\\ [][Next]_vars \/\\ WF_vars(Step)/' "${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1e decl: an added WF_ is named" "carries WF_v(A) (weak fairness) and USES.md does not declare it"

R="${TMP}/decl-sf"
D="$(mk_item "$R")"
sed -i 's/^Spec == Init \/\\ \[\]\[Next\]_vars$/Spec == Init \/\\ [][Next]_vars \/\\ SF_vars(Step)/' "${D}/Base.tla"
run_gate --no-tlc "$R"
has   "1e decl: an added SF_ is named" "carries SF_v(A) (strong fairness) and USES.md does not declare it"

# --- 1f: check 6, THE USES.md SHAPE ---------------------------------------
# Three ways a USES.md can put its probe prose somewhere the published page
# never shows it. See CHECK 6 in the gate's header for what each one did.
R="${TMP}/shape-no-probe"
D="$(mk_item "$R")"
sed -i '/^## What the properties rest on$/d' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1f uses: a missing probe section is a finding" "USES-NO-PROBE-SECTION"
rc_is "1f uses: rc 1 on a missing probe section" 1

# A RENAMED SECTION IS THE DRIFT THIS CHECK EXISTS FOR. The corpus carried
# six names for this one region before it was normalized, and
# `## What the measurements say` was one of them.
R="${TMP}/shape-variant"
D="$(mk_item "$R")"
sed -i 's/^## What the properties rest on$/## What the measurements say/' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1f uses: a renamed probe section is a finding" "USES-UNKNOWN-SECTION"
has   "1f uses: and the probe section then reads as missing too" "USES-NO-PROBE-SECTION"
rc_is "1f uses: rc 1 on a renamed section" 1

# PROSE IN THE DROPPED REGION. Between the rc: line and the first heading is
# where scripts/build-docs.sh claims nothing, so text there never publishes.
#
# The inserted line carries no backticks on purpose. A markdown backtick in a
# single-quoted sed replacement reads to shellcheck as a command substitution
# somebody forgot to make expandable (SC2016), and `a` sidesteps the question.
R="${TMP}/shape-stray"
D="$(mk_item "$R")"
sed -i '/^rc: 0$/a Raising the guard gives rc 12.' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1f uses: prose in the region build-docs drops is a finding" "USES-PROSE-MISPLACED"
has   "1f uses: the finding counts the lines" "1 line(s) sit between"
rc_is "1f uses: rc 1 on misplaced prose" 1

# --- 1g: checks 7 and 8, THE SUBJECT COLLISIONS ---------------------------
# THE FIXTURES BELOW ARE THE REAL CASE, not an invention. On 2026-10-13 the
# tla-fwkz.2.1 author wrote reading/pluscal/04-chameleons against a landed
# reading/core/02-chameleons and caught it by hand. The two Subject lines
# used here are copied from that commit and from main, so this is the
# historical regression rather than a shape somebody imagined.
#
# Both are also the first fixtures in this file with TWO items in one tree,
# which is what a corpus-wide check needs.
R="${TMP}/slug-reused"
D1="$(mk_item "$R" core 02-chameleons)"
D2="$(mk_item "$R" pluscal 04-chameleons)"
set_subject "${D1}/USES.md" \
  'Six chameleons in three colors, starting one, two and three.' \
  'Two of different colors meet and both take on the third, and they' \
  'never all end up matching.'
set_subject "${D2}/USES.md" 'a ring buffer with a head index and a tail index.'
run_gate --no-tlc "$R"
has   "1g slug: the same slug in two families is a finding" "SLUG-REUSED"
# ONE STRING CARRYING BOTH PATHS, which is what the bead's RED line asks for.
# Pinning the path column alone is not evidence: the gate prints every item's
# path on its own OK line, so a bare path assertion passes against a gate
# with no such check at all. Three rows here did exactly that on the first
# RED run, which is why the finding names the pair in its message.
has   "1g slug: the finding names both paths and the slug" \
  "pluscal/04-chameleons and core/02-chameleons share the slug 'chameleons'"
rc_is "1g slug: rc 1 on a reused slug" 1

# THE SUBJECTS ALONE, under slugs that do not collide, so this pins check 8
# on its own rather than riding on check 7. Both Subject lines wrap.
#
# THE DISCARD IS QUOTED WITH ITS SPELLING AMERICANIZED, and that is the one
# edit made to it. It spelled the color words the British way, which
# harness/test-spelling.sh bans in a tracked file and which is not this
# bead's file to add an exemption to. The edit moves the score, so both
# numbers are recorded rather than one:
#
#   as it was really written   5 shared words at 50%
#   with the spelling fixed    6 shared words at 60%
#
# The 5 is the measurement that set the threshold, and it is reproducible
# outside the index:
#
#   git show fbd5ae2:reading/pluscal/04-chameleons/USES.md > <scratch>/USES.md
#   harness/reading-gate.sh --no-tlc -q <scratch-root>
#
# So the 5 is a FLOOR rather than the real similarity of the two models. Two
# words that name the same thing were thrown away for differing by a letter,
# and the fixture below is what the same pair scores once they match.
R="${TMP}/subject-restated"
D1="$(mk_item "$R" core 02-chameleons)"
D2="$(mk_item "$R" pluscal 04-newts)"
set_subject "${D1}/USES.md" \
  'Six chameleons in three colors, starting one, two and three.' \
  'Two of different colors meet and both take on the third, and they' \
  'never all end up matching.'
set_subject "${D2}/USES.md" \
  'Chameleons in three colors. Two of different colors meet and' \
  'both turn the third color, so no color can ever take over the island.'
run_gate --no-tlc "$R"
has   "1g subject: two subjects describing one system is a finding" "SUBJECT-RESTATED"
has   "1g subject: the finding names both paths in one string" \
  "pluscal/04-newts and core/02-chameleons describe one system"
has   "1g subject: the finding counts the shared words" "6 shared words"
has   "1g subject: and names them, so a reader can judge it" "chameleons, colors, different, meet, take, third"
has   "1g subject: and states the bound it cleared" "against a bound of 4 words and 40%"
hasnt "1g subject: the slugs differ, so check 7 stays quiet" "SLUG-REUSED"
rc_is "1g subject: rc 1 on a restated subject" 1

# A USES.md WITH NO Subject: LINE. scripts/build-docs.sh anchors the page on
# that line, so the page loses the sentence saying what the model is about,
# and check 8 has nothing to compare.
R="${TMP}/subject-absent"
D="$(mk_item "$R")"
sed -i '/^Subject: /d' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1g subject: a USES.md with no Subject line is a finding" "USES-NO-SUBJECT"
rc_is "1g subject: rc 1 on a missing Subject line" 1

# AND IT IS ONE FINDING, NOT TWO. A missing USES.md is already SHAPE-NO-USES,
# so the no-Subject report must not pile a second finding onto one cause.
R="${TMP}/subject-no-uses"
D="$(mk_item "$R")"
rm "${D}/USES.md"
run_gate --no-tlc "$R"
has   "1g subject: a missing USES.md is still SHAPE-NO-USES" "SHAPE-NO-USES"
hasnt "1g subject: and is not also reported as a missing Subject line" "USES-NO-SUBJECT"

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
# a committed translation could pass a bound under 75. The 90-column line is
# why this test still discriminates: pcal's real widths are 74 and 67, which
# both FIT the 77 bound, so a fixture carrying only those two would pass with
# the exemption removed and prove nothing.
# See CHECK 2 in the gate's header.
R="${TMP}/tr-exempt"
D="$(mk_item "$R")"
{
  printf '\\* BEGIN TRANSLATION (chksum(pcal) = "b18ee4" /\\ chksum(tla) = "5c58e758")\n'
  printf '(* Allow infinite stuttering to prevent deadlock on termination. *)\n'
  wide_line 90
  printf '\\* END TRANSLATION \n'
} >>"${D}/Base.tla"
run_gate --no-tlc "$R"
hasnt "2c translation: a generated comment past the bound is exempt" "PHONE-TOO-WIDE"

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
  printf 'Widest == n = 0 \\/ n = 1 \\/ n = 2 \\/ n = 3 \\/ n = 4 \\/ n = 5 \\/ n = 6 \\/ n = 7 \\/ n = 8\n'
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

# --- 2h: check 1 ignores TLC's run artifacts ------------------------------
# A bare `tlc` run that finds an error drops <Name>_TTrace_<n>.tla and .bin
# beside the module, and a -dump run leaves states/. All three are gitignored
# so none can reach a commit, and a finding over one is noise the author then
# clears by hand. The tla-fwkz.2.6 author did exactly that, four times.
R="${TMP}/artifacts"
D="$(mk_item "$R")"
: >"${D}/Base_TTrace_1760000000000.tla"
: >"${D}/Base_TTrace_1760000000000.bin"
mkdir -p "${D}/states"
run_gate --no-tlc "$R"
hasnt "2h artifacts: a TTrace pair and a states/ dir are not a fourth entry" "SHAPE-EXTRA-ENTRY"

# AND THE SKIP IS NARROW. .gitignore's next block covers *.bak and *.old, and
# an author's scratch copy in an item directory IS a finding. Only tool output
# is skipped, which is why this is a pattern rather than a git query.
R="${TMP}/artifacts-narrow"
D="$(mk_item "$R")"
: >"${D}/Base.tla.bak"
run_gate --no-tlc "$R"
has   "2h artifacts: a .bak beside the module still fires" "SHAPE-EXTRA-ENTRY"

# A TTrace FILE MUST NOT BE MISTAKEN FOR THE MODULE either. Both end in .tla,
# and the artifact arm sits above the `*.tla` arm for that reason.
R="${TMP}/artifacts-stem"
D="$(mk_item "$R")"
: >"${D}/Base_TTrace_1760000000000.tla"
run_gate --no-tlc "$R"
hasnt "2h artifacts: a TTrace .tla is not read as a second module" "SHAPE-EXTRA-ENTRY"
hasnt "2h artifacts: nor as a stem mismatch against the .cfg" "SHAPE-STEM-MISMATCH"

# --- 2i: check 5 runs in ONE direction only -------------------------------
# Text implies declaration. The reverse is deliberately unchecked, because an
# item may honestly declare a construct whose keyword no scan can see, and 7
# files in the real corpus carry a prose note saying why a row is NOT claimed.
# Overruling the author there would make the gate wrong more often than right.
R="${TMP}/decl-extra"
D="$(mk_item "$R")"
cat >>"${D}/USES.md" <<'USES'
- CONSTANT
- ASSUME
- UNCHANGED
- SF_v(A) (strong fairness)
USES
run_gate --no-tlc "$R"
hasnt "2i decl: a construct declared and absent from the text is not a finding" "USES-CONSTRUCT-UNDECLARED"

# A CONSTRUCT IN NEITHER PLACE IS NOT A FINDING. That is the ordinary case for
# most of the seven in most items, and it must stay silent.
R="${TMP}/decl-neither"
mk_item "$R" >/dev/null
run_gate --no-tlc "$R"
hasnt "2i decl: a construct in neither the text nor the list is silent" "USES-CONSTRUCT-UNDECLARED"

# --- 2j: prose INSIDE a Constructs section is legal ------------------------
# Those notes annotate the list they sit in, which is where they belong. The
# shape check is about the region between the rc: line and the first heading,
# and about the heading names, not about prose in general.
R="${TMP}/decl-note"
D="$(mk_item "$R")"
cat >>"${D}/USES.md" <<'USES'

`UNION` is here twice and has no row in `drill/INVENTORY.md`, so it
isn't claimed above.
USES
run_gate --no-tlc "$R"
hasnt "2j uses: a declaration note inside a Constructs section is not misplaced prose" "USES-PROSE-MISPLACED"
hasnt "2j uses: and it is not an unknown section" "USES-UNKNOWN-SECTION"

# A BULLET IN THE PROBE SECTION IS NOT A DECLARED CONSTRUCT. The probe prose
# uses `- ` lists for its measured variants, and a whole-file bullet scan
# would read "- `Peak` tightened to `n <= 51` gives rc 12." as a construct.
# So the declaration reader is scoped to the two Constructs sections, and
# this control is what holds it there.
R="${TMP}/decl-scope"
D="$(mk_item "$R")"
sed -i '/^- EXTENDS (module import)$/d' "${D}/USES.md"
sed -i '/^## What the properties rest on$/a - EXTENDS (module import)' "${D}/USES.md"
run_gate --no-tlc "$R"
has   "2j uses: a construct bullet in the probe section does not count as declared" "carries EXTENDS (module import) and USES.md does not declare it"

# --- 2k: checks 7 and 8 must not fire on the corpus that exists ------------
# THIS IS THE HALF THAT DECIDES WHETHER THE GATE IS LANDABLE. A collision
# check that fires on the landed corpus is a check nobody can get work
# through, and part 3 would catch that at the aggregate. These rows name the
# two specific pairs the thresholds were measured against, so a failure says
# which pair moved rather than that something did.

# THE PAIR CENTRAL KEEPS ON PURPOSE. reading/pluscal/03-contend and
# reading/temporal/04-contention both teach weak against strong fairness, and
# both stay, because one shows why it is needed and the other shows the
# syntax for asking. Bead tla-fwkz.2.9 argued against gating this class at
# all on exactly that ground. The pair shares one word, so the gap between 1
# and 4 is the answer to the objection.
R="${TMP}/keep-contend"
D1="$(mk_item "$R" pluscal 03-contend)"
D2="$(mk_item "$R" temporal 04-contention)"
# The backticks are in the landed subject, and the whole worth of this
# control is that it is that subject verbatim rather than a paraphrase of it.
# They cost nothing: the word reader strips every non-alphanumeric character
# before it counts, so `fair` and fair reduce to the same token. shellcheck
# reads a markdown backtick in a single-quoted string as a command
# substitution somebody forgot to make expandable, which is the same finding
# the 1f shape-stray fixture sidesteps by carrying no backticks at all.
# shellcheck disable=SC2016
set_subject "${D1}/USES.md" \
  'Two processes run the same three statements against one lock, and' \
  'the only difference between them is `fair` against `fair+`.'
set_subject "${D2}/USES.md" \
  'A background poller that takes and releases a lock over and' \
  'over, and a one-shot task that needs the same lock once.'
run_gate --no-tlc "$R"
hasnt "2k collide: the fairness pair central keeps does not fire" "SUBJECT-RESTATED"
hasnt "2k collide: nor on the slug, since contend and contention differ" "SLUG-REUSED"
has   "2k collide: and the run reports what it measured" "1 word(s)"

# THE WORST REAL PAIR IN THE LANDED CORPUS, at 3 shared words. It is one word
# under the bound, which is the whole headroom there is, so this row is the
# one that goes red first if the stopword list or the threshold moves.
R="${TMP}/keep-worst"
D1="$(mk_item "$R" temporal 01-handover)"
D2="$(mk_item "$R" temporal 02-converge)"
set_subject "${D1}/USES.md" \
  'A baton that moves between sites only when somebody has asked' \
  'for it, with weak fairness on the granting step alone.'
set_subject "${D2}/USES.md" \
  'A ring of nodes where each one copies its left neighbor value' \
  'whenever that value is larger, with weak fairness on every copy step.'
run_gate --no-tlc "$R"
hasnt "2k collide: the worst real pair, at 3 words, does not fire" "SUBJECT-RESTATED"
has   "2k collide: and the run names it as the worst" "weak, fairness, step"

# --- the two thresholds, each from both sides -----------------------------
# Nonsense words, because a control about a threshold should not also be a
# claim about English. None of them is a stopword and all are over 2
# characters, so each one counts exactly once.
R="${TMP}/edge-count-under"
D1="$(mk_item "$R" core 01-aa)"
D2="$(mk_item "$R" core 02-bb)"
set_subject "${D1}/USES.md" 'alpha bravo charlie echo foxtrot golf.'
set_subject "${D2}/USES.md" 'alpha bravo charlie uniform victor whiskey.'
run_gate --no-tlc "$R"
hasnt "2k edge: 3 shared words at 50% does not fire" "SUBJECT-RESTATED"

R="${TMP}/edge-count-at"
D1="$(mk_item "$R" core 01-aa)"
D2="$(mk_item "$R" core 02-bb)"
set_subject "${D1}/USES.md" 'alpha bravo charlie delta echo foxtrot golf hotel.'
set_subject "${D2}/USES.md" 'alpha bravo charlie delta uniform victor whiskey xray.'
run_gate --no-tlc "$R"
has   "2k edge: 4 shared words at 50%, one over, fires" "SUBJECT-RESTATED"

# THE PERCENTAGE IS THE DRIFT GUARD, and this is the row that holds it. Two
# long subjects reach 4 shared words by length rather than by subject, and
# the count alone would call that a duplicate.
R="${TMP}/edge-pct-under"
D1="$(mk_item "$R" core 01-aa)"
D2="$(mk_item "$R" core 02-bb)"
set_subject "${D1}/USES.md" \
  'alpha bravo charlie delta echo foxtrot golf hotel india juliett' \
  'kilo lima mike november oscar papa quebec romeo sierra tango.'
set_subject "${D2}/USES.md" \
  'alpha bravo charlie delta uniform victor whiskey xray yankee zulu' \
  'zebra walrus vulture turtle squirrel rabbit possum otter newt marten.'
run_gate --no-tlc "$R"
hasnt "2k edge: 4 shared words at 20% does not fire" "SUBJECT-RESTATED"
has   "2k edge: and the run still reports the 4 it found" "4 word(s) at 20%"

# --- the slug check is exact, in both directions --------------------------
# A slug that CONTAINS another is a different slug. `base` and `based` are two
# systems, and a prefix match here would fire on half the corpus.
R="${TMP}/slug-substring"
mk_item "$R" core 01-base >/dev/null
mk_item "$R" temporal 02-based >/dev/null
run_gate --no-tlc "$R"
hasnt "2k slug: base and based are different slugs" "SLUG-REUSED"

# AND THE NN- PREFIX IS DROPPED BEFORE THE COMPARISON, which is what makes
# the real case collide: the discard was 04-chameleons against a landed
# 02-chameleons, so comparing whole directory names would have missed it.
R="${TMP}/slug-renumbered"
mk_item "$R" core 01-ring >/dev/null
mk_item "$R" temporal 07-ring >/dev/null
run_gate --no-tlc "$R"
has   "2k slug: a different number with the same slug still collides" "SLUG-REUSED"

# --- two honest items must be silent -------------------------------------
# The ordinary case, and it has to stay quiet or none of the above matters.
R="${TMP}/collide-silent"
D1="$(mk_item "$R" core 01-nim)"
D2="$(mk_item "$R" sets 01-clockface)"
set_subject "${D1}/USES.md" \
  'Three heaps of seven stones. A move takes any number of stones' \
  'from one heap, and the bitwise exclusive-or of the three sizes is what' \
  'the properties watch.'
set_subject "${D2}/USES.md" \
  'A clock hand that moves the same number of hours on every tick,' \
  'carrying the set of hours it has landed on. The step size is picked once.'
run_gate --no-tlc "$R"
hasnt "2k collide: two real unrelated subjects are silent" "SUBJECT-RESTATED"
hasnt "2k collide: and so are their slugs" "SLUG-REUSED"

# A ONE-ITEM TREE HAS NO PAIR TO COMPARE, and must not report one.
R="${TMP}/collide-single"
mk_item "$R" >/dev/null
run_gate --no-tlc "$R"
hasnt "2k collide: a single item reports no collision" "SUBJECT-RESTATED"
has   "2k collide: and says it compared 0 pairs" "over 0 pair(s)"

# --- 2l: the gate states its own limit on every run -----------------------
# THE LIMIT IS THE POINT OF THIS ROW. A duplicated lemma inside a different
# system is NOT gated here, and the same author in the same hour wrote one: a
# coprime model duplicating reading/pluscal/01-euclid's own divisor lemma,
# two items along in its own family. Both checks pass it.
#
# An advisory half of a gate that presents itself as whole is worse than a
# gate that states its limit, because the next author trusts it. So the
# statement is in the gate's output and this row holds it there.
R="${TMP}/limit"
mk_item "$R" >/dev/null
run_gate --no-tlc "$R"
has   "2l limit: the gate says the lemma case is not gated" "NOT GATED: a duplicated lemma inside a different system"
has   "2l limit: and points at the list a brief should paste" "--registry"

# --- 2m: --registry prints the list and checks nothing --------------------
# Every authoring brief above this bead needs the landed subjects, and
# deriving them by hand in each brief is how three copies of the smoke
# battery drifted before .claude/rules existed.
R="${TMP}/registry"
D1="$(mk_item "$R" core 02-chameleons)"
D2="$(mk_item "$R" pluscal 04-ring)"
set_subject "${D1}/USES.md" \
  'Six chameleons in three colors, starting one, two and three.' \
  'Two of different colors meet and both take on the third, and they' \
  'never all end up matching.'
set_subject "${D2}/USES.md" 'A ring buffer of four slots with a head index.'
run_gate --registry "$R"
rc_is "2m registry: rc 0, because it runs no check" 0
has   "2m registry: lists the first item by path" "- core/02-chameleons"
has   "2m registry: lists the second item by path" "- pluscal/04-ring"
has   "2m registry: counts the items" "2 item(s)"
has   "2m registry: lists the slugs an author may not reuse" "chameleons ring"
hasnt "2m registry: runs no check, so no verdict line" "VERDICT"

# THE SUBJECT IS PRINTED FLATTENED, on one line. A brief pastes it, and a
# three-line Subject pasted as three lines reads as three facts.
has   "2m registry: the wrapped subject is printed as one line" \
  "Six chameleons in three colors, starting one, two and three. Two of different colors meet and both take on the third, and they never all end up matching."

# AND IT WORKS OVER A TREE THAT WOULD FAIL THE GATE, because a brief author
# wants the list whatever state the corpus is in.
R="${TMP}/registry-broken"
D="$(mk_item "$R" core 01-nim)"
rm "${D}/Base.cfg"
run_gate --registry "$R"
rc_is "2m registry: rc 0 even over a tree with a broken item" 0
has   "2m registry: and still lists that item" "- core/01-nim"

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
    ok "real tree: ${READING_ITEMS} item(s), clean on every check"
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
