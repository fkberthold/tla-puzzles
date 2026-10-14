#!/usr/bin/env bash
# test-completion-gate.sh — the controls for harness/completion-gate.sh.
#
# WHAT THIS EXISTS TO STOP. The completion corpus's defects are not visible in
# a passing run. completion/verify-item.sh can report "every machine reported
# the code the item records" over an item one of whose holes is checked by
# nothing, which is the draft defect the reference item shipped and a person
# caught by reading. completion-gate.sh is the instrument that catches it;
# this suite is the instrument's controls, and it proves the instrument bites
# in both directions.
#
# Read harness/completion-gate.sh's header for what each of the five checks
# does and — the half that matters more — what it deliberately does not. This
# file does not restate those boundaries; it would drift from them.
#
# PART 1  each check, against a fixture built to trip it
# PART 2  controls the other way: shapes that LOOK wrong and must not fire
# PART 3  the real completion/ tree
#
# Usage:  harness/test-completion-gate.sh [--static]
#   --static   run only the parts that need no TLC: part 1's static fixtures,
#              part 2's static controls, and part 3 under --static-only. This
#              is the fast-tier row in scripts/test.
# Exit:   0 if all assertions hold, 1 otherwise.
#
# ---------------------------------------------------------------------------
# WHY THE DEFAULT IS A SLOW-TIER SUITE. Checks 1 and 2 run TLC's MODEL CHECKER
# twelve times per two-hole item — the reference signature, one signature per
# hole at TRUE, and the all-TRUE signature, each over three machines. By the
# rule in scripts/test's header the tier boundary is the model checker and not
# the JVM, so the default run belongs in slow whatever it costs today.
#
# ITS COST TRACKS THE CORPUS AND THE HOLE COUNT, not this file. Part 3 measures
# every item of the real tree, so the budget grows as authors land items, and
# an item with three holes costs four signatures rather than three. Divide by
# the item count before calling a budget overrun drift.
# ---------------------------------------------------------------------------

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

GATE="${REPO_ROOT}/harness/completion-gate.sh"

STATIC=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --static) STATIC=1 ;;
    -h|--help) sed -n '2,32p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "test-completion-gate.sh: unknown option '$1'" >&2; exit 2 ;;
  esac
  shift
done

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

if [ ! -f "$GATE" ]; then
  echo "test-completion-gate.sh: ${GATE} is missing — refusing to report success." >&2
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
# `grep -q` returns 141 under pipefail, which inside an `if` reads as "pattern
# absent" — so a present finding would report as missing and the control would
# pass over a broken instrument. That is the false-PASS direction, and
# harness/test-pipefail.sh bans the idiom outright (bead tla-kr9).
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
# THE BASELINE IS A REAL, CHECKING ITEM and not a stub, because checks 1 and 2
# run TLC over it twelve times. Two variables, two holes, three machines, and
# the recorded signature 0, 12, 12.
#
# THE TWO HOLES CATCH DISJOINT MACHINES BY CONSTRUCTION, which is what makes
# it a baseline for check 1 rather than a fixture for it:
#
#   Small  == n <= 3                    catches Over  (n climbs to 5)
#   Marked == Cardinality(seen) = n + 1 catches Dup   (seen gains a 6)
#
# TypeOK is DELIBERATELY LOOSE at 0..6. A tight type invariant would catch
# both mutants on its own, every hole would read as unchecked, and the
# baseline could never pass — which is a real defect shape and is fixture
# 1e's job, not the baseline's.
# ===========================================================================
mk_item() {
  local root="$1" fam="${2:-core}" slug="${3:-01-base}"
  local d="${root}/${fam}/${slug}"
  mkdir -p "${d}/work"

  cat >"${d}/work/Claims.tla" <<'TLA'
---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Replace each FILL_IN
\* marker with a TLA+ formula.
EXTENDS Naturals, FiniteSets

VARIABLES n, seen

TypeOK ==
  /\ n \in 0..6
  /\ seen \in SUBSET (0..6)

\* CLAIM 1. The counter never passes three.
Small == FILL_IN_CLAIM_1

\* CLAIM 2. One number has been marked per tick, and no more.
Marked == FILL_IN_CLAIM_2
====
TLA

  mk_machine "$d" Base 3 ""
  mk_machine "$d" Over 5 ""
  mk_machine "$d" Dup  3 ' \cup {6}'

  cat >"${d}/EXPECT" <<'EXPECT'
Base	0
Over	12
Dup	12
EXPECT

  cat >"${d}/PROMPT.md" <<'PROMPT'
# A counter that marks what it passes

A counter starts at zero and climbs. Every tick it marks the number it has
just reached. Two claims under `work/Claims.tla` are missing.

**Claim 1.** The counter never passes three.

**Claim 2.** Exactly one number has been marked per tick, and no more.

| machine | must report |
|---|---|
| `Base` | exit code 0 |
| `Over` | exit code 12 |
| `Dup` | exit code 12 |
PROMPT

  write_answer "$d" 'n <= 3' 'Cardinality(seen) = n + 1'

  cat >"${d}/META.md" <<'META'
# META

- **shape**: two missing invariants, one correct machine and two broken ones

## Constructs

- `Cardinality`
- `Set relational and algebraic operators`
META

  printf '%s\n' "$d"
}

# mk_machine <itemdir> <Name> <ceiling> <extra-seen-term>
mk_machine() {
  local d="$1" name="$2" ceiling="$3" extra="$4"
  cat >"${d}/work/${name}.tla" <<TLA
---- MODULE ${name} ----
EXTENDS Claims

vars == <<n, seen>>

Init == n = 0 /\\ seen = {0}

Step ==
  /\\ n < ${ceiling}
  /\\ n' = n + 1
  /\\ seen' = seen \\cup {n'}${extra}

Next == Step

Spec == Init /\\ [][Next]_vars
====
TLA
  cat >"${d}/work/${name}.cfg" <<'CFG'
SPECIFICATION Spec

INVARIANT TypeOK
INVARIANT Small
INVARIANT Marked

CHECK_DEADLOCK FALSE
CFG
}

# write_answer <itemdir> <claim-1 body> <claim-2 body>: the whole ANSWER.md.
#
# WHOLE FILE AND NOT A sed SUBSTITUTION, and this is a finding rather than a
# preference. The first version of this suite rewrote one body with
# `sed -i "s|^Small == .*$|Small == ${body}|"`, and sed's REPLACEMENT eats a
# backslash it does not recognise: `\cup` reached the file as `cup` and
# `/\` as `/`. Every TLA+ body in this file carries a backslash, so the
# fixtures were silently writing something other than what they said. Part
# 2b's positive control is what caught it — the fixture whose answer uses the
# shown `\cup` did not fire, because its answer did not contain `\cup`. The
# negative control beside it had been passing for the wrong reason.
#
# A quoted variable inside an unquoted heredoc has no such rule: the value
# goes in byte for byte.
write_answer() {
  local d="$1" b1="$2" b2="$3"
  cat >"${d}/ANSWER.md" <<ANSWER
# ANSWER: the baseline

## The two claims

\`\`\`tla
Small == ${b1}

Marked == ${b2}
\`\`\`

## Accepted variants

A spelled-out form of claim 1 counts too.
ANSWER
}

echo "test-completion-gate.sh: controls for harness/completion-gate.sh"
if [ "$STATIC" = "1" ]; then
  echo "  --static: only the parts that need no TLC. The default run is the whole suite."
fi
echo

# ===========================================================================
# PART 1 — each check, against a fixture built to trip it
# ===========================================================================
echo "PART 1 — the five checks, each against a fixture built to trip it"
echo

# --- 1a: check 1, HOLE-UNCHECKED ------------------------------------------
# THE DEFECT THE BEAD WAS FILED OVER. Claim 2 is strengthened so that it
# catches Over on its own. Hole 1 then contributes nothing: Small == TRUE
# still scores the reference signature, and the item grades it correct.
if [ "$STATIC" = "0" ]; then
  R="${TMP}/hole-unchecked"
  D="$(mk_item "$R")"
  write_answer "$D" 'n <= 3' 'Cardinality(seen) = n + 1 /\ n <= 3'
  run_gate "$R"
  has   "1a check 1: a hole nothing catches is a finding" "HOLE-UNCHECKED"
  has   "1a check 1: the finding names the hole" "Small == TRUE"
  has   "1a check 1: and names the machine that should have answered" "(Over)"
  rc_is "1a check 1: rc 1" 1

  # --- 1b: check 1, HOLE-OVERLAP ------------------------------------------
  # Claim 1 catches BOTH mutants and claim 2 catches neither, so Small == TRUE
  # moves two positions rather than one. Two holes, one of them doing all the
  # work: the item looks like it separates them and does not.
  R="${TMP}/hole-overlap"
  D="$(mk_item "$R")"
  write_answer "$D" 'n <= 3 /\ Cardinality(seen) = n + 1' 'seen \subseteq 0..6'
  run_gate "$R"
  has   "1b check 1: a hole that catches another hole's machine is a finding" "HOLE-OVERLAP"
  has   "1b check 1: the finding names the positions that moved" "moving position(s) 2 3"
  rc_is "1b check 1: rc 1" 1

  # --- 1c: check 1, REFERENCE-SIGNATURE -----------------------------------
  # ANSWER.md's own claims do not score what EXPECT records. Every delta check
  # 1 measures would otherwise be measured against a number nobody checked.
  R="${TMP}/reference-signature"
  D="$(mk_item "$R")"
  write_answer "$D" 'n <= 9' 'Cardinality(seen) = n + 1'
  run_gate "$R"
  has   "1c check 1: a reference answer that does not score EXPECT is a finding" "REFERENCE-SIGNATURE"
  has   "1c check 1: the finding states both signatures" "EXPECT records '0, 12, 12'"
  hasnt "1c check 1: and the hole deltas are not reported against it" "HOLE-UNCHECKED"
  rc_is "1c check 1: rc 1" 1

  # --- 1e: check 2, HOLES-NOT-FALSIFIABLE ---------------------------------
  # TypeOK is tightened to 0..3, so it catches both mutants on its own and the
  # all-TRUE signature matches the reference. The item grades `TRUE, TRUE` as
  # correct, which is the failure completion/verify-item.sh's own header warns
  # about and cannot detect.
  R="${TMP}/not-falsifiable"
  D="$(mk_item "$R")"
  sed -i 's|^  /\\ n \\in 0\.\.6$|  /\\ n \\in 0..3|' "${D}/work/Claims.tla"
  sed -i 's|^  /\\ seen \\in SUBSET (0\.\.6)$|  /\\ seen \\in SUBSET (0..3)|' "${D}/work/Claims.tla"
  run_gate "$R"
  has   "1e check 2: an item whose holes are all vacuous is a finding" "HOLES-NOT-FALSIFIABLE"
  has   "1e check 2: the finding says what the item would grade as correct" "grades a claim that says nothing as correct"
  rc_is "1e check 2: rc 1" 1
fi

# --- 1d: the bead's RED, a hole shipped already filled --------------------
# "GIVEN an item whose second hole is filled with TRUE in its committed
# Claims.tla ... THEN it reports a finding naming that hole."
R="${TMP}/prefilled"
D="$(mk_item "$R")"
sed -i 's|^Marked == FILL_IN_CLAIM_2$|Marked == TRUE|' "${D}/work/Claims.tla"
run_gate --static-only "$R"
has   "1d RED: a hole filled in the committed Claims.tla is a finding" "CLAIMS-HOLE-PREFILLED"
has   "1d RED: the finding names the hole" "'Marked'"
has   "1d RED: and says what the item shipped instead" "it already reads 'Marked == TRUE'"
rc_is "1d RED: rc 1" 1

# A marker the gate cannot rewrite is its own finding, reported rather than
# silently dropped. The count is over comment-stripped text, because every
# Claims.tla's own header carries the word FILL_IN in prose.
R="${TMP}/unparsed-hole"
D="$(mk_item "$R")"
sed -i 's|^Small == FILL_IN_CLAIM_1$|Small == IF TRUE THEN FILL_IN_CLAIM_1 ELSE FALSE|' "${D}/work/Claims.tla"
run_gate --static-only "$R"
has   "1d RED: a FILL_IN the gate cannot rewrite is a finding" "CLAIMS-UNPARSED-HOLE"
rc_is "1d RED: rc 1 on an unrewritable marker" 1

# --- 1f: check 3, a leak in PROMPT.md ------------------------------------
R="${TMP}/telegraph-prompt"
D="$(mk_item "$R")"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
run_gate --static-only "$R"
has   "1f check 3: an answer operator shown in PROMPT.md is a finding" "TELEGRAPH-SHOWN"
has   "1f check 3: the finding names the operator" "uses 'Cardinality'"
has   "1f check 3: and says how to waive it if it cannot be hidden" "telegraph-waiver: Cardinality --"
rc_is "1f check 3: rc 1" 1

# --- 1g: check 3, a leak in a MACHINE ------------------------------------
# THE DEFECT NAMED ON THE BEAD: two authors fixed a leak in a machine rather
# than in Claims.tla. A check that scanned PROMPT.md alone, or PROMPT.md and
# Claims.tla, would pass this.
R="${TMP}/telegraph-machine"
D="$(mk_item "$R")"
printf 'Size == Cardinality(seen)\n' >>"${D}/work/Dup.tla"
run_gate --static-only "$R"
has   "1g check 3: an answer operator shown in a MACHINE is a finding" "TELEGRAPH-SHOWN"
rc_is "1g check 3: rc 1 on a leak in a machine" 1

# And in Claims.tla itself, which is the file the learner edits.
R="${TMP}/telegraph-claims"
D="$(mk_item "$R")"
printf 'Size == Cardinality(seen)\n' >>"${D}/work/Claims.tla"
run_gate --static-only "$R"
has   "1g check 3: an answer operator shown in Claims.tla is a finding" "TELEGRAPH-SHOWN"
rc_is "1g check 3: rc 1 on a leak in Claims.tla" 1

# --- 1h: check 4, a stray file under work/ -------------------------------
# "GIVEN an item with a stray .old file under work/ THEN it reports a finding
# naming the file." pcal writes one beside every module it rewrites, and
# scripts/deliver-completion.sh delivers work/ recursively.
R="${TMP}/stray-old"
D="$(mk_item "$R")"
: >"${D}/work/Base.old"
run_gate --static-only "$R"
has   "1h check 4: a pcal .old backup under work/ is a finding" "WORK-STRAY-FILE"
has   "1h check 4: the finding names the file" "work/Base.old"
rc_is "1h check 4: rc 1" 1

# A Claims.cfg is a stray too, and deliberately: no EXPECT stem is Claims, so
# it is a config for a module that never runs.
R="${TMP}/stray-claims-cfg"
D="$(mk_item "$R")"
: >"${D}/work/Claims.cfg"
run_gate --static-only "$R"
has   "1h check 4: a work/Claims.cfg is a stray" "work/Claims.cfg"
rc_is "1h check 4: rc 1 on a Claims.cfg" 1

# A SUBDIRECTORY is its own finding, because the delivery is recursive and the
# name can never match an EXPECT stem.
R="${TMP}/stray-dir"
D="$(mk_item "$R")"
mkdir -p "${D}/work/states"
run_gate --static-only "$R"
has   "1h check 4: a subdirectory under work/ is a finding" "WORK-STRAY-DIR"
has   "1h check 4: the finding names the directory" "work/states/"
rc_is "1h check 4: rc 1 on a subdirectory" 1

# --- 1i: check 5, an EXPECT stem that resolves to nothing ----------------
R="${TMP}/expect-no-tla"
D="$(mk_item "$R")"
rm "${D}/work/Dup.tla"
run_gate --static-only "$R"
has   "1i check 5: an EXPECT stem with no .tla is a finding" "EXPECT-NO-TLA"
has   "1i check 5: the finding names the stem" "EXPECT names 'Dup'"
rc_is "1i check 5: rc 1" 1

R="${TMP}/expect-no-cfg"
D="$(mk_item "$R")"
rm "${D}/work/Dup.cfg"
run_gate --static-only "$R"
has   "1i check 5: an EXPECT stem with no .cfg is a finding" "EXPECT-NO-CFG"
rc_is "1i check 5: rc 1 on a missing .cfg" 1

# The row shapes EXPECT itself can get wrong.
R="${TMP}/expect-bad-row"
D="$(mk_item "$R")"
printf 'Extra 12\n' >>"${D}/EXPECT"
run_gate --static-only "$R"
has   "1i check 5: a row that is not <stem><TAB><rc> is a finding" "EXPECT-BAD-ROW"
rc_is "1i check 5: rc 1 on a tab-less row" 1

R="${TMP}/expect-first-not-zero"
D="$(mk_item "$R")"
sed -i '1s/\t0$/\t12/' "${D}/EXPECT"
run_gate --static-only "$R"
has   "1i check 5: row 1 not recording rc 0 is a finding" "EXPECT-FIRST-NOT-ZERO"
rc_is "1i check 5: rc 1 when row 1 is not the correct machine" 1

# And the shape findings, so a half-authored item is named rather than swept.
R="${TMP}/no-answer"
D="$(mk_item "$R")"
rm "${D}/ANSWER.md"
run_gate --static-only "$R"
has   "1i shape: a missing ANSWER.md is a finding" "SHAPE-NO-ANSWER"
rc_is "1i shape: rc 1 on a missing ANSWER.md" 1

R="${TMP}/no-block"
D="$(mk_item "$R")"
printf '# ANSWER\n\nNo fenced block here.\n' >"${D}/ANSWER.md"
run_gate --static-only "$R"
has   "1i format: an ANSWER.md with no fenced block is a finding" "ANSWER-NO-BLOCK"
rc_is "1i format: rc 1 on no fenced block" 1

# THE FORMAT IS CHECKED, NOT GUESSED. An ANSWER.md whose first block does not
# define a hole is a finding naming the item and the hole — never a silent
# pass over an item the gate cannot address.
R="${TMP}/no-body"
D="$(mk_item "$R")"
sed -i '/^Marked == /d' "${D}/ANSWER.md"
run_gate --static-only "$R"
has   "1i format: a hole with no body in the first block is a finding" "ANSWER-NO-BODY"
has   "1i format: the finding names the hole" "no 'Marked ==' definition"
rc_is "1i format: rc 1 on a missing reference body" 1

# And the inverse: a name defined in the first block that is NOT a hole. The
# gate reports the EXTRA definition rather than the missing one, because that
# is the item defect — a block defining something Claims.tla does not ask for
# means a hole was handed over. Asserted so the ordering is pinned rather
# than incidental; the fixture above is the only one that reaches
# ANSWER-NO-BODY, and it reaches it because it deletes rather than renames.
R="${TMP}/answer-extra-name"
D="$(mk_item "$R")"
sed -i 's|^Marked == .*$|Nonsense == TRUE|' "${D}/ANSWER.md"
run_gate --static-only "$R"
has   "1i format: an ANSWER definition that is not a hole is reported" "CLAIMS-HOLE-PREFILLED"
has   "1i format: and it names the definition" "defines 'Nonsense'"
rc_is "1i format: rc 1 on an extra ANSWER definition" 1

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
if [ "$STATIC" = "0" ]; then
  R="${TMP}/baseline"
  mk_item "$R" >/dev/null
  run_gate "$R"
  hasnt "2a baseline: no finding on the good item" "FINDING"
  has   "2a baseline: reports VERDICT OK" "VERDICT OK"
  has   "2a baseline: the reference answer scored EXPECT" "scores EXPECT's '0, 12, 12'"
  has   "2a baseline: hole 1 is caught by exactly one machine" "hole Small is caught by 'Over' and by nothing else"
  has   "2a baseline: hole 2 is caught by exactly one machine" "hole Marked is caught by 'Dup' and by nothing else"
  rc_is "2a baseline: rc 0" 0
fi

R="${TMP}/baseline-static"
mk_item "$R" >/dev/null
run_gate --static-only "$R"
hasnt "2a baseline: no finding under --static-only either" "FINDING"
rc_is "2a baseline: --static-only exits 0 on the good item" 0

# --- 2b: 01-clockface's exact shape must NOT fire -------------------------
# THE FALSE POSITIVE THE PER-OPERATOR RULE EXISTS TO AVOID. drill/INVENTORY.md
# row K013 covers `\cup` as well as `\subseteq`. The reference item shows
# `seen \cup {pos'}` in its machine and its answer uses `\subseteq`, so a
# ROW-granularity check flags it and a PER-OPERATOR check does not. The
# fixture reproduces exactly that: one operator of the row in the answer,
# a different operator of the same row in a machine.
#
# BOTH FIXTURES ARE TLC-CORRECT ITEMS, which is why the pair is a statement
# about check 3 and not about an item that happens to be broken elsewhere.
# `seen \subseteq 0..n` and `seen \cup (0..n) = 0..n` are the same claim
# spelled with the two operators of one row, and each catches Dup alone.
R="${TMP}/row-vs-operator"
D="$(mk_item "$R")"
write_answer "$D" 'n <= 3' 'seen \subseteq 0..n'
run_gate --static-only "$R"
hasnt "2b per-operator: an answer using \\subseteq is not flagged by a shown \\cup" "TELEGRAPH-SHOWN"
rc_is "2b per-operator: rc 0" 0

# The SAME fixture with the SAME row's other operator in the answer MUST fire,
# so the control above is a narrowing rather than a hole. Without this pair,
# a check 3 that had stopped scanning altogether would satisfy 2b.
R="${TMP}/row-vs-operator-bites"
D="$(mk_item "$R")"
write_answer "$D" 'n <= 3' 'seen \cup (0..n) = 0..n'
run_gate --static-only "$R"
has   "2b per-operator: an answer using the SHOWN operator of the same row does fire" "uses '\\cup'"
rc_is "2b per-operator: rc 1 when the answer uses the shown operator" 1

# And a token shown in the item while the answer does not use it is not a
# finding. The baseline's TypeOK shows SUBSET throughout and no answer touches
# it, which is the second instance of the same narrowing.
R="${TMP}/shown-unused"
mk_item "$R" >/dev/null
run_gate --static-only "$R"
hasnt "2b per-operator: SUBSET shown in TypeOK and unused by the answer does not fire" "uses 'SUBSET'"

# --- 2c: the per-item waiver ---------------------------------------------
# It suppresses EXACTLY ONE token for EXACTLY ONE item, and it is echoed.
R="${TMP}/waiver"
D="$(mk_item "$R")"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
printf '\ntelegraph-waiver: Cardinality -- the prompt has to name the count it asks about, and no shorter gloss exists\n' >>"${D}/META.md"
run_gate --static-only "$R"
hasnt "2c waiver: a waived token is not a finding" "TELEGRAPH-SHOWN"
has   "2c waiver: and the waiver is echoed so it cannot accumulate unseen" "WAIVER "
has   "2c waiver: the echo carries the reason" "no shorter gloss exists"
rc_is "2c waiver: rc 0" 0

# A BULLETED, EMPHASISED waiver is accepted, because that is how a META.md
# writes a field.
R="${TMP}/waiver-bullet"
D="$(mk_item "$R")"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
# The backticks are the point of this fixture: a META.md writes a token in
# code spans, and the parser has to strip them. They must reach the file as
# literal backticks rather than as a command substitution, which is how the
# checker reads them inside single quotes.
# shellcheck disable=SC2016
printf '\n- **telegraph-waiver**: `Cardinality` -- the prompt has to name the count it asks about\n' >>"${D}/META.md"
run_gate --static-only "$R"
hasnt "2c waiver: a bulleted, emphasised, backticked waiver is accepted" "TELEGRAPH-SHOWN"
rc_is "2c waiver: rc 0 on the bulleted form" 0

# --- 2d: a waiver with no reason is a finding ----------------------------
# "An exemption with no reason is itself a finding." Same floor as
# harness/drill-gate.sh:1442.
R="${TMP}/waiver-no-reason"
D="$(mk_item "$R")"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
printf '\ntelegraph-waiver: Cardinality\n' >>"${D}/META.md"
run_gate --static-only "$R"
has   "2d waiver: a waiver with no reason is a finding" "TELEGRAPH-WAIVER-NO-REASON"
has   "2d waiver: and it does NOT suppress the token" "TELEGRAPH-SHOWN"
rc_is "2d waiver: rc 1" 1

# A reason too short to be one is the same finding. The floor is what stops a
# waiver from being written as `-- yes`.
R="${TMP}/waiver-short-reason"
D="$(mk_item "$R")"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
printf '\ntelegraph-waiver: Cardinality -- yes\n' >>"${D}/META.md"
run_gate --static-only "$R"
has   "2d waiver: a reason under the floor is a finding" "TELEGRAPH-WAIVER-NO-REASON"
rc_is "2d waiver: rc 1 on a too-short reason" 1

# --- 2e: a waiver naming no token is a finding ---------------------------
R="${TMP}/waiver-no-token"
D="$(mk_item "$R")"
printf '\ntelegraph-waiver: -- the reason is here but the token is not\n' >>"${D}/META.md"
run_gate --static-only "$R"
has   "2e waiver: a waiver naming no token is a finding" "TELEGRAPH-WAIVER-EMPTY"
rc_is "2e waiver: rc 1" 1

# --- 2f: THE WAIVER CANNOT BE SET BY ACCIDENT ----------------------------
# The key has to START the line. The same string mid-sentence is prose about
# the mechanism, and a META.md that discusses the rule — three of the nine
# real items do — must not thereby waive anything.
R="${TMP}/waiver-in-prose"
D="$(mk_item "$R")"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
printf '\nA telegraph-waiver: would be wrong here, since the leak is avoidable and should be fixed in the prompt instead.\n' >>"${D}/META.md"
run_gate --static-only "$R"
has   "2f waiver: the key mid-sentence waives nothing" "TELEGRAPH-SHOWN"
hasnt "2f waiver: and no WAIVER line is echoed for it" "WAIVER "
rc_is "2f waiver: rc 1" 1

# --- 2g: a waiver is PER ITEM -------------------------------------------
# A waiver in one item must not reach its sibling. This is what makes it a
# per-item exemption rather than a family pass.
R="${TMP}/waiver-per-item"
D="$(mk_item "$R" core 01-waived)"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D}/PROMPT.md"
printf '\ntelegraph-waiver: Cardinality -- this item cannot avoid naming the count in its prompt\n' >>"${D}/META.md"
D2="$(mk_item "$R" core 02-unwaived)"
printf '\nClaim 2 is about the Cardinality of seen.\n' >>"${D2}/PROMPT.md"
run_gate --static-only "$R"
has   "2g waiver: the sibling item with no waiver is still a finding" "core/02-unwaived"
has   "2g waiver: and the waived item is echoed rather than flagged" "core/01-waived"
rc_is "2g waiver: rc 1 with one of two items waived" 1
if grep -qE '^FINDING .*core/01-waived' <<<"$GATE_OUT"; then
  nope "2g waiver: the waived item must not carry a TELEGRAPH finding"
else
  ok "2g waiver: the waived item carries no TELEGRAPH finding"
fi

# --- 2h: --no-tlc can never exit 0 --------------------------------------
# It was asked whether each hole bites and did not find out, so it carries
# that forward as CHECK_DID_NOT_RUN. Same distinction drill-gate.sh draws.
R="${TMP}/notlc"
mk_item "$R" >/dev/null
run_gate --no-tlc "$R"
rc_is "2h --no-tlc: rc 99 even on the baseline that passes" 99
has   "2h --no-tlc: says the check was not run" "the check was not run"

# AND --static-only IS NOT A LOUDER --no-tlc. It exits 0 on the same tree and
# states the count it left out, naming the flag in parentheses so
# harness/test-indeterminate.sh's parenthetical rule can tell a voluntary
# scope from an involuntary non-run.
run_gate --static-only "$R"
rc_is "2h --static-only: rc 0 on the baseline that passes" 0
has   "2h --static-only: states the count it did not measure" "1 item(s) whose holes were not measured"
# ONE SUBSTRING AND NOT TWO, because the waiver is a per-LINE property.
# harness/test-indeterminate.sh's involuntary_admissions() matches its skip
# vocabulary line by line and asks each matching line for a parenthetical, so
# an admission on one line and a flag on the next waives nothing. The two
# halves are pinned adjacent here for the same reason that suite pins
# drill-gate's at its line 644.
has   "2h --static-only: the admission and its waiving flag are on one line" "skipped (--static-only)"
hasnt "2h --static-only: emits no UNCHECKED line for runs it never promised" "UNCHECKED"

# --- 2i: usage errors ----------------------------------------------------
run_gate
rc_is "2i usage: no root given is rc 2" 2
run_gate "${TMP}/does-not-exist"
rc_is "2i usage: a missing root is rc 2" 2
run_gate --what "$R"
rc_is "2i usage: an unknown option is rc 2" 2
run_gate "$R" "$R"
rc_is "2i usage: two roots is rc 2" 2
run_gate --no-tlc --static-only "$R"
rc_is "2i usage: --no-tlc with --static-only is rc 2" 2
run_gate --timeout nine --static-only "$R"
rc_is "2i usage: a non-numeric --timeout is rc 2" 2

# An EMPTY root is UNCHECKED, not rc 0. A gate asked to check items that finds
# none has not answered the question it was asked.
R="${TMP}/empty"
mkdir -p "$R"
run_gate --static-only "$R"
rc_is "2i usage: an empty root is rc 99, not 0" 99
has   "2i usage: and says no item was found" "no item found"

# --- 2j: a family directory is not an item ------------------------------
# The sweep takes depth-2 directories, so a file at the root must not be read
# as an item and must not make the gate miss the real one.
R="${TMP}/depth"
mk_item "$R" >/dev/null
: >"${R}/README.md"
run_gate --static-only "$R"
hasnt "2j sweep: a file at the root is not swept as an item" "README.md"
has   "2j sweep: exactly one item found beside it" "1 item(s)"

echo

# ===========================================================================
# PART 3 — the real completion/ tree
#
# Not conditional on the tree being clean: this is the row that fails when a
# landed item stops separating its holes. It IS conditional on the tree
# existing, so the suite is not red in a checkout where the corpus has not
# landed.
#
# THE PENDING REGISTER, and why this is not a known-failures list that quietly
# goes green over red.
#
# Two landed items carry a telegraph leak that CANNOT be fixed in the item,
# and both items' own META.md already argue the case in prose. Bead tla-4yit
# grants this worker harness/ and scripts/test and NOT completion/, so the
# one-line machine-readable waiver each item needs is central's edit rather
# than this worker's. Until it is made, the gate correctly reports three
# findings over the real tree.
#
# So the register below names those three EXACTLY, with the file in the item
# where the author already stated the reason. The assertion fails in BOTH
# directions:
#
#   a finding outside the register        -> FAIL. A new leak, or a new defect
#                                           of any other kind, reddens this.
#   a register entry no longer produced   -> FAIL, saying to delete the line.
#                                           So the register cannot rot into a
#                                           blanket pass as items are fixed.
#
# IT IS PRINTED ON EVERY RUN, clean runs included, for the same reason the
# gate echoes every WAIVER line: an exemption nobody sees accumulates.
#
# THE REGISTER GOES AWAY ENTIRELY once each item carries
# `telegraph-waiver: <token> -- <reason>` in its META.md. That is two lines in
# two files, and the reasons are already written in those files.
# ===========================================================================
echo "PART 3 — the real completion/ tree"
echo

# <code>|<item>|<a substring of the finding's detail>|<where the item argues it>
# EMPTIED 2026-10-14. Central added the three telegraph-waiver lines the
# register asked for: `pc` on pluscal/01-squares, `[]` and `]_` on
# temporal/01-roster. The gate then read 9 items, 0 findings, VERDICT OK, and
# echoes all three waivers on every run.
#
# THE ARRAY STAYS, EMPTY, rather than being deleted with its consumer. An empty
# register asserts the stronger thing: the real tree produces NO finding of any
# kind. The both-directions check below is what makes that true, so a new leak
# reddens this row rather than being absorbed. Refill it only to park a finding
# somebody has read and decided to leave, never to make a red tree green.
CORPUS_PENDING=()

if [ "${#CORPUS_PENDING[@]}" -eq 0 ]; then
  echo "        PENDING REGISTER — empty. The real tree must produce no finding."
else
  echo "        PENDING REGISTER — findings central has not yet dispositioned."
  echo "        Each needs one 'telegraph-waiver:' line in the item's own META.md,"
  echo "        and the reason is already written there. Any finding OUTSIDE this"
  echo "        register fails this suite; so does an entry it no longer produces."
  for p in "${CORPUS_PENDING[@]}"; do
    printf '          %s  %s\n' "${p%%|*}" "$(cut -d'|' -f2,3 <<<"$p" | tr '|' ' ')"
  done
fi
echo

COMPLETION_ITEMS=0
if [ -d "${REPO_ROOT}/completion" ]; then
  # The hidden-dir predicate is anchored at the completion root. `! -path
  # '*/.*'` would match REPO_ROOT itself, since every dispatched worker here
  # runs under .claude/worktrees/agent-*, and the count would be 0 on any real
  # tree. Recorded in harness/test-drill.sh's part 3.
  COMPLETION_ITEMS="$(find "${REPO_ROOT}/completion" -mindepth 2 -maxdepth 2 -type d \
    ! -name '.*' ! -path "${REPO_ROOT}/completion/.*" | wc -l)"
fi

# assert_corpus <label-prefix>: run the gate over the real tree in whichever
# tier this invocation is, then hold its findings against the register.
assert_corpus() {
  local label="$1" line matched p n_unmatched=0
  for p in "${CORPUS_PENDING[@]}"; do
    if grep -qF -- "$(cut -d'|' -f3 <<<"$p")" <<<"$GATE_OUT" &&
       grep -qF -- "$(cut -d'|' -f2 <<<"$p")" <<<"$GATE_OUT"; then
      ok "${label}: register entry still produced — ${p%%|*} on $(cut -d'|' -f2 <<<"$p")"
    else
      nope "${label}: register entry NO LONGER produced — ${p%%|*} on $(cut -d'|' -f2 <<<"$p"). The item was fixed or waived; DELETE that CORPUS_PENDING line."
    fi
  done

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    matched=0
    for p in "${CORPUS_PENDING[@]}"; do
      if grep -qF -- "$(cut -d'|' -f3 <<<"$p")" <<<"$line" &&
         grep -qF -- "$(cut -d'|' -f2 <<<"$p")" <<<"$line"; then
        matched=1
      fi
    done
    if [ "$matched" = "0" ]; then
      nope "${label}: UNREGISTERED finding over the real tree — ${line}"
      n_unmatched=$((n_unmatched + 1))
    fi
  done <<<"$(grep '^FINDING' <<<"$GATE_OUT" || true)"

  if [ "$n_unmatched" = "0" ]; then
    ok "${label}: every finding over the real tree is in the register"
  fi

  if grep -qE '^UNCHECKED' <<<"$GATE_OUT"; then
    nope "${label}: a check COULD NOT RUN over an item that exists"
    printf '%s\n' "$GATE_OUT" | sed -n '/^UNCHECKED/s/^/        /p'
  else
    ok "${label}: no check was left unable to run"
  fi
}

if [ ! -d "${REPO_ROOT}/completion" ]; then
  ok "real tree: completion/ does not exist yet — nothing to guarantee, and that is reported rather than passed over"
  echo "        The gate bites the moment an item lands. Until then this row is a"
  echo "        statement about the tree, not a check that ran."
elif [ "$COMPLETION_ITEMS" -eq 0 ]; then
  ok "real tree: completion/ exists and holds no item yet"
  echo "        This row gates as soon as one item exists."
else
  run_gate --static-only -q "${REPO_ROOT}/completion"
  has "real tree, static: the sweep found every item" "${COMPLETION_ITEMS} item(s)"
  assert_corpus "real tree, static"

  if [ "$STATIC" = "0" ]; then
    run_gate -q "${REPO_ROOT}/completion"
    has "real tree, full: the sweep found every item" "${COMPLETION_ITEMS} item(s)"
    assert_corpus "real tree, full"
    echo "        ${COMPLETION_ITEMS} item(s) measured through TLC: the reference signature,"
    echo "        one signature per hole at TRUE, and the all-TRUE signature."
  fi
fi

# ===========================================================================
echo
echo "test-completion-gate.sh: ${pass_count} passed, ${fail_count} failed"
[ "$fail_count" -eq 0 ]
