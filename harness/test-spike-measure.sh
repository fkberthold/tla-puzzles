#!/usr/bin/env bash
# Gate for harness/spike-measure.sh.
#
# This exists because that tool's parsers produced two confident wrong numbers
# on the day it was written, and neither raised an error. This awk does not
# implement \b, so a VARIABLES scan anchored on it reported zero variables in a
# module declaring four. And a definition count that only matched a body
# starting on the next line reported zero on specs that plainly had some. A
# measurement tool that quietly reports the wrong number is worse than one that
# fails, because the number goes into a manifest and nobody rechecks it.
#
# So every column is pinned against a fixture whose text explains its own
# figures, and a control watches that the tool distinguishes its two fixtures
# rather than printing one answer regardless.
#
# Lineage: bead tla-frpu.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$REPO_ROOT/harness/spike-measure.sh"
FIX="$REPO_ROOT/harness/fixtures/spike"

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# Runs the tool and prints its data row. Captured first, then read from a
# here-string: a pipeline into a consumer that can close early returns 141
# under pipefail, and a present value then reads as absent.
row_in() {
  local dir="$1" module="$2" out
  out="$(bash "$TOOL" --dir "$dir" --module "$module" --budget 30 --label "$module" 2>/dev/null || true)"
  tail -1 <<<"$out"
}

# The common case: a fixture that lives in harness/fixtures/spike.
row_for() { row_in "$FIX" "$1"; }

field() {
  local row="$1" name="$2"
  local hdr='label module rc verdict secs generated distinct depth vars defs fairness temporal instance modules lines'
  local idx
  idx="$(awk -v want="$name" '{for(i=1;i<=NF;i++) if($i==want) print i}' <<<"$hdr")"
  awk -F'\t' -v i="$idx" '{print $i}' <<<"$row"
}

expect() {
  local label="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    ok "$label is $want"
  else
    bad "$label is '$got', expected '$want'"
  fi
}

printf 'spike-measure gate\n'

if [ ! -x "$TOOL" ] && [ ! -f "$TOOL" ]; then
  bad "harness/spike-measure.sh exists"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

# 1. The clean fixture. Every figure below is a consequence of Tiny.tla's own
#    text: two variables climbing 0 to 2 independently is a 3 by 3 grid, and
#    the longest path through it is 4 steps.
TINY="$(row_for Tiny)"
expect "Tiny rc"        "$(field "$TINY" rc)"        "0"
expect "Tiny distinct"  "$(field "$TINY" distinct)"  "9"
expect "Tiny depth"     "$(field "$TINY" depth)"     "5"
expect "Tiny vars"      "$(field "$TINY" vars)"      "2"
expect "Tiny fairness"  "$(field "$TINY" fairness)"  "no"
expect "Tiny temporal"  "$(field "$TINY" temporal)"  "no"
expect "Tiny instance"  "$(field "$TINY" instance)"  "no"

# 2. The violating fixture, which also carries fairness and a temporal
#    property so those two columns have a case where yes is the honest answer.
BROKEN="$(row_for Broken)"
expect "Broken rc"        "$(field "$BROKEN" rc)"        "12"
expect "Broken vars"      "$(field "$BROKEN" vars)"      "2"
expect "Broken fairness"  "$(field "$BROKEN" fairness)"  "yes"
expect "Broken temporal"  "$(field "$BROKEN" temporal)"  "yes"

# 3. The multi-module fixture. Extender EXTENDS Scaffold, which declares two
#    variables, and adds a third of its own. This is the shape the isolation
#    spike used, where the scaffolding carries most of the state, and reading
#    only the named module reported one variable for a six-variable model.
EXTENDER="$(row_for Extender)"
expect "Extender rc"      "$(field "$EXTENDER" rc)"      "0"
expect "Extender vars"    "$(field "$EXTENDER" vars)"    "3"
expect "Extender modules" "$(field "$EXTENDER" modules)" "2"
expect "Tiny modules"     "$(field "$TINY" modules)"     "1"

# The control that names the defect. Extender.tla declares one VARIABLE line of
# its own, so a tool that read the file alone would report fewer than 3.
own_decl="$(grep -cE '^[[:space:]]*VARIABLES?' "$FIX/Extender.tla" || true)"
if [ "$(field "$EXTENDER" vars)" -gt "$own_decl" ]; then
  ok "control: variables are counted across EXTENDS, not from one file"
else
  bad "control: variable count did not follow EXTENDS, which is the isolation-spike defect"
fi

# 4. Controls. A tool that printed one answer regardless would satisfy several
#    assertions above by accident, so watch that the two fixtures differ where
#    they should.
if [ "$(field "$TINY" rc)" != "$(field "$BROKEN" rc)" ]; then
  ok "control: the two fixtures get different verdicts"
else
  bad "control: both fixtures report the same rc, so the verdict is not being read"
fi

if [ "$(field "$TINY" fairness)" != "$(field "$BROKEN" fairness)" ]; then
  ok "control: fairness is read from the module, not hardcoded"
else
  bad "control: fairness is the same on a module with WF_ and one without"
fi

if [ "$(field "$TINY" distinct)" != "$(field "$BROKEN" distinct)" ]; then
  ok "control: state counts differ between a full search and one cut short"
else
  bad "control: both fixtures report the same distinct count"
fi

# 5. The tool refuses what it cannot measure, rather than inventing a row.
set +e
bash "$TOOL" --dir "$FIX" --module NoSuchModule --budget 5 >/dev/null 2>&1
rc_missing_module=$?
bash "$TOOL" --dir "$FIX/no-such-dir" --module Tiny --budget 5 >/dev/null 2>&1
rc_missing_dir=$?
bash "$TOOL" --dir "$FIX" --budget 5 >/dev/null 2>&1
rc_missing_arg=$?
set -e

expect "a missing module exits 2"    "$rc_missing_module" "2"
expect "a missing directory exits 2" "$rc_missing_dir"    "2"
expect "a missing argument exits 2"  "$rc_missing_arg"    "2"

# 6. Comments are not variables. Bead tla-83lg.
#
# The tool stripped \* line comments and left (* *) block comments standing, so
# every English word inside a block comment that fell within a VARIABLES
# declaration block was tallied as a variable name. A spike's first measured
# row read 36 variables for a module declaring 5. The suite above did not
# catch it because none of its three fixtures carries a comment anywhere near
# a declaration, which is the shape the shipped references actually use.
#
# Every assertion below names the wrong answer the tool gave before the fix, so
# a future reader can tell which implementation mistake each shape rules out
# rather than taking "2" on faith. All of them should read 2: two variables
# declared, however the surrounding prose is punctuated.

# 6a. The committed probe. This is the fixture the tla-pmm2.1 spike author
#     built to isolate the defect, and it is used here rather than re-derived
#     so the gate pins the same artifact the finding was made on. If this
#     directory has moved, that is a real break and it should be loud.
PROBE="$REPO_ROOT/sources/spikes/progressive-sync-stale-status/probe-vars-comment"
if [ -d "$PROBE" ]; then
  # Before the fix: VarsCommented 8, VarsPlain 2.
  COMMENTED="$(row_in "$PROBE" VarsCommented)"
  PLAIN="$(row_in "$PROBE" VarsPlain)"
  expect "probe VarsCommented vars" "$(field "$COMMENTED" vars)" "2"
  expect "probe VarsPlain vars"     "$(field "$PLAIN" vars)"     "2"
  if [ "$(field "$COMMENTED" vars)" = "$(field "$PLAIN" vars)" ]; then
    ok "control: the comment does not change the count"
  else
    bad "control: commenting a declaration changed the variable count, which is the tla-83lg defect"
  fi
else
  bad "probe fixture is missing: $PROBE"
fi

# 6b. The shapes the probe does not reach. Written at run time rather than
#     committed, because this bead's footprint is the tool and its gate; a
#     fixture tree of its own would be a third file. They are real modules and
#     each one is asserted to check clean, so a shape that TLA+ does not
#     actually accept cannot sit here passing on a parse failure.
SHAPES="$(mktemp -d)"
trap 'rm -rf "$SHAPES"' EXIT

shape_cfg() {
  printf 'SPECIFICATION Spec\nINVARIANT TypeOK\nCHECK_DEADLOCK FALSE\n' >"$SHAPES/$1.cfg"
}

# Nested block comments are legal TLA+ and nest to a depth. Verified on this
# build: this module checks clean, rc 0. A non-greedy strip stops at the first
# *) and leaves "still outer" standing. Before the fix: 6.
cat >"$SHAPES/Nested.tla" <<'TLA'
----------------------------- MODULE Nested ----------------------------------
EXTENDS Naturals

VARIABLES
    alpha,     (* outer (* inner *) still outer *)
    beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

==============================================================================
TLA
shape_cfg Nested

# Two separate comments with a declaration between them. This is the shape a
# greedy strip gets wrong: it runs from the first (* to the last *) and eats
# alpha with the prose. Before the fix: 4.
cat >"$SHAPES/Adjacent.tla" <<'TLA'
---------------------------- MODULE Adjacent ---------------------------------
EXTENDS Naturals

VARIABLES (* one *) alpha, (* two *) beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

==============================================================================
TLA
shape_cfg Adjacent

# A block comment spanning three lines inside the declaration list. This is
# the shape that punishes a strip which blanks a commented line instead of
# removing it: a blank line ends the declaration block, so beta goes
# uncounted. Before the fix: 28.
cat >"$SHAPES/Spanning.tla" <<'TLA'
---------------------------- MODULE Spanning ---------------------------------
EXTENDS Naturals

VARIABLES
    alpha,
    (* beta holds the second counter, and this prose runs
       across three source lines so that a line oriented
       strip has to carry its state between them *)
    beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

==============================================================================
TLA
shape_cfg Spanning

# A \* inside a block comment is ordinary comment text, not a line comment.
# Strip the line form first and the *) disappears with it, leaving an
# unterminated block that swallows the rest of the file. Before the fix: 5.
cat >"$SHAPES/LineInBlock.tla" <<'TLA'
--------------------------- MODULE LineInBlock -------------------------------
EXTENDS Naturals

VARIABLES
    alpha,     (* a note carrying \* inside the block *)
    beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

==============================================================================
TLA
shape_cfg LineInBlock

# And the other direction: a (* inside a line comment opens nothing. Strip the
# block form first and it opens a comment that never closes. Before the fix
# this read 1, which is an UNDERCOUNT the shipped tool already had before any
# block comment entered the picture: blanking the line ended the declaration
# block and beta was lost.
cat >"$SHAPES/BlockInLine.tla" <<'TLA'
--------------------------- MODULE BlockInLine -------------------------------
EXTENDS Naturals

VARIABLES
    alpha,
    \* a stray (* opener living inside a line comment
    beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

==============================================================================
TLA
shape_cfg BlockInLine

# A comment opener inside a string literal. This one read 2 BEFORE the fix,
# because nothing was looking for (* at all. It is here as a guard on the fix
# rather than on the defect: a comment scanner that does not know about
# strings opens a block here that never closes, deletes the declaration
# entirely, and reports 0. A regression in that direction is silent.
cat >"$SHAPES/StringOpener.tla" <<'TLA'
-------------------------- MODULE StringOpener -------------------------------
EXTENDS Naturals

Marker == "(*"

VARIABLES alpha, beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat /\ Marker /= ""

==============================================================================
TLA
shape_cfg StringOpener

for shape in Nested Adjacent Spanning LineInBlock BlockInLine StringOpener; do
  SHAPE_ROW="$(row_in "$SHAPES" "$shape")"
  expect "$shape checks clean" "$(field "$SHAPE_ROW" rc)"   "0"
  expect "$shape vars"         "$(field "$SHAPE_ROW" vars)" "2"
done

# 6c. The same strip feeds the fairness and temporal columns, which read the
#     module text. A module that only DISCUSSES fairness in prose must not
#     report it as declared.
cat >"$SHAPES/ProseOnly.tla" <<'TLA'
--------------------------- MODULE ProseOnly ---------------------------------
EXTENDS Naturals

(* This module has no fairness and no temporal operator. It only talks about
   them: WF_vars and SF_vars are what it would need, and a leads-to ~> is what
   it would state, if it stated anything at all. *)

VARIABLES alpha, beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

==============================================================================
TLA
shape_cfg ProseOnly

PROSE="$(row_in "$SHAPES" ProseOnly)"
expect "ProseOnly checks clean"  "$(field "$PROSE" rc)"       "0"
expect "ProseOnly vars"          "$(field "$PROSE" vars)"     "2"
expect "ProseOnly fairness"      "$(field "$PROSE" fairness)" "no"
expect "ProseOnly temporal"      "$(field "$PROSE" temporal)" "no"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
