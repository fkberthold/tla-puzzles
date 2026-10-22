#!/usr/bin/env bash
# test-verdict.sh — Executable spec for harness/verdict.sh (bead tla-kl5.4).
#
# Pins the RED invariant from the bead:
#
#   for each rc in {0,10,11,12,13,150,151,255,124} a purpose-built fixture
#   spec drives verdict.sh to exactly that verdict, and no verdict is derived
#   from stdout text.
#
# AMENDED 2026-10-22 by bead tla-ry2y. Exit 151 was measured to carry three
# meanings, so it is the one code whose arm reads TLC's output to subdivide
# itself, and the structural check below scopes that permission to exactly
# two matcher sites over two measured needles instead of banning matchers
# outright. The RED invariant otherwise stands: text may never move a verdict
# between codes.
#
# Two kinds of assertion:
#
#   Behavioral — run verdict.sh against a fixture in harness/fixtures/verdict/
#     and require BOTH the verdict token and the raw exit status. Asserting the
#     raw rc as well as the token is what keeps the V2-PLAN.md 5.1 table honest:
#     a future TLC that renumbered its exit codes would still produce the right
#     token through a silently-patched map, and only the rc assertion catches it.
#
#   Structural — read verdict.sh itself and require -workers 1, a timeout
#     wrapper, and that every text matcher over TLC's output is one of the
#     two permitted 151 needles.
#
# Usage:  harness/test-verdict.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

VERDICT="harness/verdict.sh"
FIXTURES="harness/fixtures/verdict"

pass_count=0
fail_count=0

ok() {
  printf "  PASS  %s\n" "$1"
  pass_count=$((pass_count + 1))
}

nope() {
  printf "  FAIL  %s\n" "$1"
  fail_count=$((fail_count + 1))
}

# assert_verdict <label> <want-verdict> <want-rc> [verdict.sh args...]
assert_verdict() {
  local label="$1" want_verdict="$2" want_rc="$3"
  shift 3

  local got_verdict got_rc
  got_verdict=$(bash "$VERDICT" "$@" 2>/dev/null)
  got_rc=$?

  if [ "$got_verdict" = "$want_verdict" ] && [ "$got_rc" = "$want_rc" ]; then
    ok "$label — $want_verdict (rc=$want_rc)"
  else
    nope "$label — wanted $want_verdict/rc=$want_rc, got '${got_verdict}'/rc=${got_rc}"
  fi
}

if [ ! -f "$VERDICT" ]; then
  echo "FATAL: $VERDICT does not exist" >&2
  exit 1
fi

# verdict.sh with whole-line comments stripped. BOTH structural assertions read
# this rather than the raw file: the header documents the very constructs the
# checks police (it names -workers 8 as the thing not to do, and it explains why
# there is no grep), so matching raw text would let a comment satisfy a
# should-be-present check and a comment trip a must-be-absent one. Verified by
# mutation: with `-workers 1` changed to `-workers 8` in the code, the raw-file
# version of assert_present still passed off the header comment.
#
# CAPTURED ONCE INTO A VARIABLE, and matched below through a here-string rather
# than a pipe. This shape is mandatory, not stylistic -- see bead tla-kr9. The
# old shape was:
#
#     if verdict_code | grep -qE -- "$pattern"; then
#
# Under `set -o pipefail`, `grep -q` exits at its first match and closes the
# pipe; the producer on the left dies of SIGPIPE; the pipeline reports 141. In
# an `if`, 141 is merely falsy and `set -e` does not fire, so a PRESENT pattern
# is reported ABSENT. Measured 2026-08-07 on bash 5.2.21: a shell-function
# producer returns 141 from 1000 lines up, 0 at 10 lines -- the trigger is
# whether the consumer exits before the producer finishes flushing, so it is a
# race, not a size threshold, and the same suite can be green one run and red
# the next with no code change.
#
# Capturing first is NOT sufficient on its own. `printf '%s\n' "$out" | grep -q`
# was measured at rc=141 at exactly the same sizes: the printf builtin runs in a
# forked subshell and takes SIGPIPE just as a function does. Only removing the
# pipe removes the bug. A here-string is materialised in full before grep is
# exec'd, so there is no live writer to signal -- measured rc=0 at 21 MB.
VERDICT_CODE=$(sed 's/^[[:space:]]*#.*$//' "$VERDICT")

# assert_absent <label> <extended-regex>
assert_absent() {
  local label="$1" pattern="$2"
  local hits
  # `--` is load-bearing: several of these patterns begin with a literal '-'
  # and grep would otherwise read them as options, fail, and report no hits —
  # a check that passes because it never ran.
  hits=$(grep -nE -- "$pattern" <<<"$VERDICT_CODE")
  if [ -z "$hits" ]; then
    ok "$label"
  else
    nope "$label — found: $(tr '\n' ' ' <<<"$hits")"
  fi
}

# assert_present <label> <extended-regex>
assert_present() {
  local label="$1" pattern="$2"
  if grep -qE -- "$pattern" <<<"$VERDICT_CODE"; then
    ok "$label"
  else
    nope "$label — pattern not found: $pattern (searched $(grep -c '' <<<"$VERDICT_CODE") lines of $VERDICT)"
  fi
}

echo "== behavioral: one fixture per row of the V2-PLAN.md 5.1 table =="

# rc=0 — trivially satisfied, run through the FULL canonical invocation
# including a -postCondition that holds (Ok has 5 distinct states >= 4).
assert_verdict "rc=0   trivially-satisfied spec" \
  "OK" 0 \
  --postcondition "Gate!NonVacuous" "$FIXTURES/Ok.tla"

# rc=10 — both arms of the assumption channel.
assert_verdict "rc=10  ASSUME FALSE" \
  "ASSUMPTION_FAILED" 10 \
  "$FIXTURES/AssumeFalse.tla"

assert_verdict "rc=10  -postCondition false (1 distinct state)" \
  "ASSUMPTION_FAILED" 10 \
  --postcondition "Gate!NonVacuous" "$FIXTURES/PostCondFalse.tla"

# rc=11 — genuine deadlock, and the control that proves the flag is real.
assert_verdict "rc=11  deadlock, checking ON" \
  "DEADLOCK" 11 \
  --check-deadlock "$FIXTURES/Deadlock.tla"

assert_verdict "rc=0   same spec, deadlock checking OFF (default)" \
  "OK" 0 \
  "$FIXTURES/Deadlock.tla"

# rc=12 / rc=13 — the two violation channels, kept distinct.
assert_verdict "rc=12  INVARIANT violated" \
  "SAFETY_VIOLATION" 12 \
  "$FIXTURES/SafetyViolation.tla"

assert_verdict "rc=13  PROPERTY violated" \
  "LIVENESS_VIOLATION" 13 \
  "$FIXTURES/LivenessViolation.tla"

# rc=150 / rc=151 — broken module vs broken config, deliberately separated.
assert_verdict "rc=150 unparseable module" \
  "PARSE_ERROR" 150 \
  "$FIXTURES/ParseError.tla"

assert_verdict "rc=151 .cfg names an operator the spec lacks" \
  "CONFIG_ERROR" 151 \
  "$FIXTURES/ConfigError.tla"

# THE OTHER TWO MEANINGS OF 151 (bead tla-ry2y). An obligation whose body
# mentions no variable is folded to a constant before any state is walked, so
# a FALSE one is reported with no state and no trace and still exits 151.
# Before this bead both arrived as CONFIG_ERROR, which told a caller the
# configuration was broken when the configuration was fine and the assertion
# was false. A gate reading that would discard a real refutation.
assert_verdict "rc=151 variable-free INVARIANT evaluated FALSE" \
  "INVARIANT_FALSE" 151 \
  -c "$FIXTURES/InvariantFalse.cfg" "$FIXTURES/InvariantFalse.tla"

assert_verdict "rc=151 variable-free PROPERTY evaluated FALSE" \
  "PROPERTY_FALSE" 151 \
  -c "$FIXTURES/PropFalse.cfg" "$FIXTURES/InvariantFalse.tla"

# THE CONTROL, AND IT IS WHAT MAKES THE TWO ABOVE WORTH ASSERTING. The same
# obligation shape, TRUE instead of FALSE, is an ordinary pass over 5 distinct
# states. Only the failure channel differs, which is why this went unnoticed
# for the life of the table: a corpus of passing fixtures never exercises it.
assert_verdict "rc=0   the same shape, TRUE, is an ordinary pass" \
  "OK" 0 \
  -c "$FIXTURES/InvariantTrue.cfg" "$FIXTURES/InvariantFalse.tla"

# rc=255 — the fixture is the ABSENCE of the file. Guard that first: if
# someone ever creates NoSuchModule.tla the assertions below would go green
# for the wrong reason.
if [ -e "$FIXTURES/NoSuchModule.tla" ] || [ -e "$FIXTURES/NoSuchModule.cfg" ]; then
  nope "rc=255 fixture integrity — no NoSuchModule.{tla,cfg} may exist"
else
  ok "rc=255 fixture integrity — NoSuchModule.{tla,cfg} absent as required"
fi

assert_verdict "rc=255 missing .cfg" \
  "TLC_EXCEPTION" 255 \
  "$FIXTURES/NoSuchModule.tla"

# rc=124 — its own verdict, not folded into failure.
assert_verdict "rc=124 unbounded state space under a short timeout" \
  "TIMEOUT" 124 \
  --timeout 5 "$FIXTURES/Unbounded.tla"

echo
echo "== the four codes 5.1 originally missed (bead tla-i9m) =="

# The original 5.1 table enumerated 8 codes. The pinned jar's own enum carries
# 14, and it is NOT the same channel as 10, 12 or 13.
#
#   javap -cp ~/lib/tla2tools.jar -constants 'tlc2.output.EC$ExitStatus'
#
# rc=14 does not mean "an Assert failed" — it means an Assert failed once TLC
# was already exploring behavior. The identical construct in Init is 75, and
# the next assertion is the control that proves it.
assert_verdict "rc=14  Assert FALSE during behavior exploration" \
  "ASSERT_VIOLATION" 14 \
  "$FIXTURES/AssertViolation.tla"

# rc=75, route 1 of 2 — the same Assert, moved into Init. The initial-state
# computation wraps the EvalException as EC.TLC_NESTED_EXPRESSION (2103) rather
# than letting the assertion's own code through, so the code changes with WHEN
# the failure happens and not with WHAT failed. Paired with the rc=14 case
# above so that a TLC which stopped distinguishing them breaks the build.
assert_verdict "rc=75  the same Assert, in Init instead" \
  "SPEC_EVAL_FAILURE" 75 \
  "$FIXTURES/AssertInInit.tla"

# rc=75, route 2 of 2 — and the one that is not hypothetical. This is the
# shape of puzzles/T29-unchanged/solution/Clock_buggy.tla: one branch of Tick
# leaves minutes' unconstrained, so TLC cannot complete the successor state
# (EC.TLC_STATE_NOT_COMPLETELY_SPECIFIED_NEXT = 2109).
#
# Before the tla-kl5.4 rewire the old grep chain classified this rc as
# PASS-VIOLATION only because it matched the `Trace exploration` line of the
# *_TTrace_*.tla file TLC writes beside the error — and the canonical
# invocation passes -noGenerateSpecTE, which suppresses that file. Adopting
# the canonical invocation while keeping the greps would have silently removed
# the sole basis for T29's verdict.
assert_verdict "rc=75  under-constrained successor (the T29 shape)" \
  "SPEC_EVAL_FAILURE" 75 \
  "$FIXTURES/SpecEvalFailure.tla"

# rc=76 — kept distinct from rc=12 on purpose. 12 means the invariant was
# evaluated and was FALSE; 76 means it could not be evaluated at all, so
# nothing whatsoever is known about whether it holds.
assert_verdict "rc=76  invariant cannot be evaluated (not a violation)" \
  "SAFETY_EVAL_FAILURE" 76 \
  "$FIXTURES/SafetyEvalFailure.tla"

# rc=77 — a PROPERTY that quantifies over the empty set is vacuously true, and
# TLC refuses it (EC.TLC_LIVE_FORMULA_TAUTOLOGY = 2253) rather than reporting
# a pass. The 5.3 vacuity hazard arriving through the temporal channel, and
# the loud counterpart to DanglingKeyword.cfg's silent one.
assert_verdict "rc=77  tautological PROPERTY is refused, not passed" \
  "LIVENESS_EVAL_FAILURE" 77 \
  "$FIXTURES/LivenessEvalFailure.tla"

echo
echo "== the three measured departures from the V2-PLAN.md 5.1 table =="
echo "== (each is pinned here so it cannot silently drift back)      =="

# 5.1 files "file not found" under 255. Measured, the missing-MODULE half is
# 150, not 255: SANY reports "Cannot find source file" and the run dies in the
# parse channel. Same absent file as the 255 case above; the only difference is
# that a readable .cfg lets TLC get as far as looking for the module.
assert_verdict "5.1 departure: missing .tla is 150, not 255" \
  "PARSE_ERROR" 150 \
  --config "$FIXTURES/Ok.cfg" "$FIXTURES/NoSuchModule.tla"

# 5.1 files "config failure" under 151 without qualification. Measured, 151 is
# only the SEMANTIC half; a .cfg that fails to PARSE lands in the 255 catch-all
# alongside genuinely missing files.
assert_verdict "5.1 departure: unparseable .cfg is 255, not 151" \
  "TLC_EXCEPTION" 255 \
  --config "$FIXTURES/BadCfgSyntax.cfg" "$FIXTURES/Ok.tla"

# Not in 5.1 at all, and the most dangerous of the three: a .cfg keyword with
# no operand is not an error. TLC exits 0 having silently checked no invariant
# whatsoever — a vacuous PASS that looks exactly like a real one, which is the
# 5.3 hazard class arriving through the config file instead of through Init.
assert_verdict "5.1 gap: bare INVARIANT keyword is silently ignored, rc=0" \
  "OK" 0 \
  --config "$FIXTURES/DanglingKeyword.cfg" "$FIXTURES/Ok.tla"

echo
echo "== rc=12 and rc=13 are two channels, not one (bead tla-94n) =="

# These four fixtures are GENERATED rather than committed beside the others,
# because here the formula IS the assertion: the exit code follows the shape of
# the temporal operator and nothing else, so the shape belongs where a reader
# can see it next to the number it produces.
SHAPES=$(mktemp -d -t tla_verdict_shapes.XXXXXX)
trap 'rm -rf "$SHAPES"' EXIT

cat >"$SHAPES/PropShape.tla" <<'TLA'
---- MODULE PropShape ----
(* One spec, two PROPERTY shapes.  The runs below differ in nothing but the *)
(* formula the .cfg names, and both .cfgs declare no INVARIANT at all.      *)
EXTENDS Naturals
VARIABLE s
Init == s = 0
Next == \/ (s = 0 /\ s' = 1)
        \/ (s = 1 /\ s' = 0)
Spec == Init /\ [][Next]_s
Hot  == s = 1
StickyHot == [](Hot => []Hot)
NoMove    == [][ s' = s ]_s
====
TLA
printf 'SPECIFICATION Spec\nPROPERTY StickyHot\n' >"$SHAPES/Sticky.cfg"
printf 'SPECIFICATION Spec\nPROPERTY NoMove\n'    >"$SHAPES/Boxed.cfg"

# The row-13 gloss used to read "PROPERTY violated", which a reader takes as
# "a violated PROPERTY lands on 13". It does not. StickyHot is refuted by the
# finite prefix 0 -> 1 -> 0, so TLC calls it a safety violation and exits 12,
# with no INVARIANT anywhere in the .cfg to explain the 12.
#
# The consequence runs the other way too, and is the one that bites: rc=12 does
# not imply an INVARIANT failed. grade.sh:391 reads 12 as "the refutation
# obligation was MET", so a temporal obligation of this shape would be graded
# on the strength of a code that came from somewhere else entirely.
assert_verdict "rc=12  [](P => []P) violated, no INVARIANT in the .cfg" \
  "SAFETY_VIOLATION" 12 \
  --config "$SHAPES/Sticky.cfg" "$SHAPES/PropShape.tla"

# The control. Same spec, same channel keyword, a boxed action instead, and now
# the row-13 gloss is right. TLC checks this one as an implied action rather
# than through the liveness tableau, and the counterexample being finite makes
# no difference here.
assert_verdict "rc=13  [][A]_vars violated" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/Boxed.cfg" "$SHAPES/PropShape.tla"

# The refinement half of the row-13 gloss, pinned because refinement.sh:530 has
# a lone `13)` arm and routes everything else to a catch-all. Both obligations
# TLC derives from Abstract!ASpec have to land on 13 for that arm to be right.
cat >"$SHAPES/Abstract.tla" <<'TLA'
---- MODULE Abstract ----
EXTENDS Naturals
VARIABLE a
AInit == a = 5
ANext == a' = a
ASpec == AInit /\ [][ANext]_a
====
TLA
cat >"$SHAPES/BadInit.tla" <<'TLA'
---- MODULE BadInit ----
(* Implied-INIT failure only: c starts at 9 where the abstraction wants 5,  *)
(* and the step relation matches, so nothing else can fail.                 *)
EXTENDS Naturals
VARIABLE c
Init == c = 9
Next == c' = c
Spec == Init /\ [][Next]_c
A == INSTANCE Abstract WITH a <- c
Refines == A!ASpec
====
TLA
cat >"$SHAPES/BadAction.tla" <<'TLA'
---- MODULE BadAction ----
(* Implied-ACTION failure only: c starts at 5, which the abstraction accepts, *)
(* then moves, which its stuttering-only ANext forbids.                       *)
EXTENDS Naturals
VARIABLE c
Init == c = 5
Next == c < 7 /\ c' = c + 1
Spec == Init /\ [][Next]_c
A == INSTANCE Abstract WITH a <- c
Refines == A!ASpec
====
TLA
printf 'SPECIFICATION Spec\nPROPERTY Refines\n' >"$SHAPES/Refines.cfg"

assert_verdict "rc=13  refinement, implied-init obligation broken" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/Refines.cfg" "$SHAPES/BadInit.tla"

assert_verdict "rc=13  refinement, implied-action obligation broken" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/Refines.cfg" "$SHAPES/BadAction.tla"

echo
echo "== one claim, six spec formulas (beads tla-lj1n and tla-vzu3) =="

# Two beads each named a discriminator for the 12/13 split, and the two
# readings can't both be right. tla-lj1n measured a state predicate under
# PROPERTY coming back 13 when the initial state refuted it. That's the
# shortest finite prefix there is, so the bead proposed that 12 just means
# INVARIANT. tla-vzu3 measured one obligation moving from 12 to 13 when the
# spec gained a fairness conjunct, which says the keyword can't be the whole
# story.
#
# Measured 2026-10-18 over the grid below, 24 cells plus two INVARIANT
# controls. Neither reading survives it, and there are three channels rather
# than two.
#
#   1. The invariant channel. A box over a state predicate gets lifted
#      outright. It prints "Invariant Cold is violated" rather than naming
#      the property, and it exits 12. Nothing below moves it.
#   2. The safety channel. A temporal formula refutable by a finite prefix,
#      and not liftable to an invariant, exits 12. Only while the spec
#      formula carries no liveness conjunct.
#   3. The liveness channel. Everything else exits 13. That includes the
#      implied-action channel, and it includes a bare state predicate under
#      PROPERTY.
#
# So 12 and 13 name the channel that reported. A caller reads {0} as holds
# and {12, 13} as refuted, and never predicts which. Every pinned-behavior
# item in epic tla-7xql is a fair spec by construction, so that whole family
# sits in channel 3.
#
# I measured the effect in channel 2 and not TLC's reason for it. WF, SF and
# a bare []<> conjunct all flip the same formula the same way, so my hunch is
# that any liveness conjunct forces the tableau and the tableau owns the
# exit code from then on. The grid pins the behavior either way.

cat >"$SHAPES/FairShape.tla" <<'TLA'
---- MODULE FairShape ----
(* One system, six spec formulas, four claims. Every run below names one    *)
(* spec and one claim, and nothing else varies.                            *)
EXTENDS Naturals
VARIABLE s
vars == <<s>>

Init == s = 0
Move == s' = (s + 1) % 4
Idle == s' = s
Next == Move \/ Idle

Cold == s # 2
Hot  == s = 2

(* Outside is enabled at every state and [][Next]_vars forbids it, so       *)
(* requiring it to fire leaves no behavior at all.                          *)
Outside == s' = 99

NoFair    == Init /\ [][Next]_vars
WithWF    == Init /\ [][Next]_vars /\ WF_vars(Move)
WithBoxEv == Init /\ [][Next]_vars /\ []<>(s = 1)
Empty     == Init /\ [][Next]_vars /\ WF_vars(Outside)
BadConj   == Init /\ [][Next]_vars /\ [](s \in 0..3)

BoxCold   == []Cold
BareHot   == Hot
NeverHot  == ~<>Hot
NeverTrue == []<>(s # s)
====
TLA

shape_cfg () {
  printf 'SPECIFICATION %s\nPROPERTY %s\n' "$1" "$2" >"$SHAPES/$1-$2.cfg"
}
for shape_spec in NoFair WithWF WithBoxEv Empty BadConj; do
  for shape_claim in BoxCold BareHot NeverHot NeverTrue; do
    shape_cfg "$shape_spec" "$shape_claim"
  done
done

# Channel 1. The lifting is total, and the message says so by naming Cold
# instead of BoxCold.
assert_verdict "rc=12  []P over a state predicate is lifted to an invariant" \
  "SAFETY_VIOLATION" 12 \
  --config "$SHAPES/NoFair-BoxCold.cfg" "$SHAPES/FairShape.tla"

assert_verdict "rc=12  the lifting survives a fairness conjunct" \
  "SAFETY_VIOLATION" 12 \
  --config "$SHAPES/WithWF-BoxCold.cfg" "$SHAPES/FairShape.tla"

# Channel 3, and this is tla-lj1n's measured case. The initial state is as
# finite as a prefix gets and it still reports through the liveness channel,
# which is what refutes "12 means INVARIANT". Note the claim is a bare state
# predicate rather than a box over one, so channel 1 never sees it.
assert_verdict "rc=13  a bare state predicate refuted by the initial state" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/NoFair-BareHot.cfg" "$SHAPES/FairShape.tla"

assert_verdict "rc=13  the same claim, unmoved by a fairness conjunct" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/WithWF-BareHot.cfg" "$SHAPES/FairShape.tla"

# Channel 2, and this pair is tla-vzu3. One obligation, one system, and the
# code moves because the spec formula gained a conjunct the obligation never
# mentions.
assert_verdict "rc=12  ~<>P on a spec with no liveness conjunct" \
  "SAFETY_VIOLATION" 12 \
  --config "$SHAPES/NoFair-NeverHot.cfg" "$SHAPES/FairShape.tla"

assert_verdict "rc=13  the same ~<>P once the spec carries WF" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/WithWF-NeverHot.cfg" "$SHAPES/FairShape.tla"

# Fairness is not what does it. A bare []<> conjunct in the spec formula,
# with no fairness operator anywhere, moves the same claim the same way.
assert_verdict "rc=13  and again on a []<> conjunct, no fairness anywhere" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/WithBoxEv-NeverHot.cfg" "$SHAPES/FairShape.tla"

# The emptiness hazard, which epic tla-7xql carries as H2 and reached by a
# different route. WF over an action outside Next leaves no behavior, and a
# spec with no behaviors satisfies every temporal property. NeverTrue is
# refuted on any satisfiable spec here, so the pair is the probe.
assert_verdict "rc=13  a formula no behavior satisfies, on a live spec" \
  "LIVENESS_VIOLATION" 13 \
  --config "$SHAPES/NoFair-NeverTrue.cfg" "$SHAPES/FairShape.tla"

assert_verdict "rc=0   the same formula, on a spec with no behaviors" \
  "OK" 0 \
  --config "$SHAPES/Empty-NeverTrue.cfg" "$SHAPES/FairShape.tla"

# And the asymmetry that makes the hazard worth gating. The empty spec hides
# from the liveness channel and not from the invariant channel, so a corpus
# checked only through lifted invariants would never notice.
assert_verdict "rc=12  the empty spec still fails a lifted invariant" \
  "SAFETY_VIOLATION" 12 \
  --config "$SHAPES/Empty-BoxCold.cfg" "$SHAPES/FairShape.tla"

# A safety-shaped temporal conjunct in SPECIFICATION is refused outright,
# pointing at the conjunct's own source span. Worth pinning because it reads
# as a spec-author mistake and it is really TLC declining the shape.
assert_verdict "rc=255 a []P conjunct inside the spec formula is refused" \
  "TLC_EXCEPTION" 255 \
  --config "$SHAPES/BadConj-NeverHot.cfg" "$SHAPES/FairShape.tla"

echo
echo "== --config means the same file whatever the module path (bead tla-sn0h) =="

# TLC calls ToolIO.setUserDir(<module's directory>) when, and only when, the
# module argument is absolute, which silently moves the base every later
# relative path resolves against. A relative --config then stops resolving from
# the caller's cwd and TLC reports a .cfg that is sitting right there as
# missing, arriving as 255 TLC_EXCEPTION.
#
# All four combinations name the same two files, so all four have to agree.
assert_verdict "rel module, rel --config" \
  "OK" 0 \
  --config "$FIXTURES/Ok.cfg" "$FIXTURES/Ok.tla"

assert_verdict "rel module, abs --config" \
  "OK" 0 \
  --config "$REPO_ROOT/$FIXTURES/Ok.cfg" "$FIXTURES/Ok.tla"

assert_verdict "abs module, abs --config" \
  "OK" 0 \
  --config "$REPO_ROOT/$FIXTURES/Ok.cfg" "$REPO_ROOT/$FIXTURES/Ok.tla"

assert_verdict "abs module, rel --config" \
  "OK" 0 \
  --config "$FIXTURES/Ok.cfg" "$REPO_ROOT/$FIXTURES/Ok.tla"

echo
echo "== rc=99 — the one row that is not TLC's (bead tla-hl96) =="

# TLC's deadlock checking is an AND across the .cfg's CHECK_DEADLOCK keyword
# and the command line's -deadlock flag, and neither side mentions the other.
# This script passes -deadlock by default, so a learner's CHECK_DEADLOCK TRUE
# used to get no check and no notice: OK, rc=0, on a module that deadlocks.
#
# ONE ROW HERE, deliberately. This suite owns "verdict.sh's exit-code table is
# what it says it is", and 99 is now a row of that table. The six-cell
# measurement, both conflict directions, the agreement controls and the
# commented-keyword control live in harness/test-indeterminate.sh, which owns
# the convention across every instrument. A duplicate pair can only fail
# together, so it would buy no discriminating power and cost this suite's
# budget twice over.
assert_verdict "rc=99  CHECK_DEADLOCK TRUE would be discarded, so no run is made" \
  "CHECK_DID_NOT_RUN" 99 \
  --config "harness/fixtures/indeterminate/DeadlockKeywordTrue.cfg" \
  "harness/fixtures/indeterminate/DeadlockKeyword.tla"

# The control, and it is what stops the row above from being satisfied by
# refusing every .cfg that mentions the keyword. 334 of the .cfg files in this
# repo carry CHECK_DEADLOCK FALSE, which AGREES with the default flag.
assert_verdict "rc=0   CHECK_DEADLOCK FALSE agrees with the default flag and runs" \
  "OK" 0 \
  --config "harness/fixtures/indeterminate/DeadlockKeywordFalse.cfg" \
  "harness/fixtures/indeterminate/DeadlockKeyword.tla"

echo
echo "== structural: the constraints that no fixture can observe =="

# 99 IS DOCUMENTED IN THE TABLE, not just implemented. Every other row of the
# header table is pinned by a fixture above; this one is pinned both ways,
# because a reserved code the header does not carry is a code the next reader
# will reuse for something else.
#
# AGAINST THE RAW FILE, not VERDICT_CODE. The header table IS a comment block,
# and VERDICT_CODE exists precisely to strip those -- so the assertion that
# documentation is present is the one assertion here that must not use it.
if grep -qE -- '^#[[:space:]]+99[[:space:]]+CHECK_DID_NOT_RUN' "$VERDICT"; then
  ok "the 99 CHECK_DID_NOT_RUN row is in the header table"
else
  nope "the header table carries no 99 CHECK_DID_NOT_RUN row"
fi

# And the code is bound to a NAME rather than written as a literal at the exit
# site. A bare `exit 99` three instruments apart is three conventions;
# harness/test-indeterminate.sh asserts the same binding across all of them.
assert_present "99 is bound to EXIT_INDETERMINATE" \
  'EXIT_INDETERMINATE=99'

# -workers 1 is mandatory (V2-PLAN.md 5.1): counterexamples are
# nondeterministic above one worker.
assert_present "-workers 1 is pinned in the invocation" \
  '-workers[[:space:]]+1'

assert_absent "no worker count other than 1" \
  '-workers[[:space:]]+([02-9]|[0-9][0-9])'

# The timeout wrapper is what makes rc=124 reachable at all.
assert_present "TLC is wrapped in timeout(1)" \
  '(^|[^[:alnum:]_])timeout[[:space:]]'

# The whole point of the bead: verdicts come from the exit code, never from
# TLC's stdout. This used to ban text matchers outright, and that was right
# until exit 151 was measured to carry three meanings (bead tla-ry2y), which
# no exit status can separate. A blanket ban would have forced the file to
# keep calling a false obligation a config error.
#
# SO THE BAN IS NOW SCOPED RATHER THAN LIFTED, and these two assertions are
# what scope it. The first counts every matcher site in the code. The second
# counts the sites matching the one permitted shape: grep over the two
# measured needles, read from "$LOG" by redirect. Equal counts mean every
# matcher in the file is a permitted one, so a third matcher, a different
# needle, or one reading anything but the log breaks the pair.
#
# Checked as a pair on purpose. Either assertion alone is satisfiable by the
# wrong file: the count alone allows two arbitrary greps, and the shape alone
# allows ten more beside them.
matcher_total=$(grep -cE -- '(^|[^[:alnum:]_./-])(grep|sed|awk|rg|egrep|fgrep)[[:space:]]' <<<"$VERDICT_CODE")
matcher_allowed=$(grep -cE -- "grep -qE 'The (invariant|property) of \.\+ is equal to FALSE' <\"\\\$LOG\"" <<<"$VERDICT_CODE")

if [ "$matcher_total" = "2" ] && [ "$matcher_allowed" = "2" ]; then
  ok "text matching is confined to the two measured 151 needles over \$LOG"
else
  nope "text matching escaped the 151 arm — $matcher_total matcher site(s), $matcher_allowed of the permitted shape (both must be 2)"
fi

assert_absent "no bash regex match operator" \
  '=~'

# Belt and braces: none of TLC's own verdict strings appear as literals.
assert_absent "no TLC stdout phrases used as literals" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached|Finished in|unexpected exception)'

# ONLY MAP WHAT YOU MEASURED. ERROR_STATESPACE_TOO_LARGE=152 and ERROR_SYSTEM=153
# are declared in the jar's EC$ExitStatus enum but no fixture provokes them —
# and not because nobody tried hard enough. Disassembling every class in
# tla2tools v1.8.0 finds no bytecode anywhere that pushes 152 or 153 as an exit
# value (the only `sipush 152/153` sites in the jar are parser token constants
# and bundled third-party libraries), and both are absent from the enum's own
# `knownExitValues` set. They are dead constants in this build.
#
# So a case arm for either would be a mapping nobody has measured wearing the
# table's authority — the exact failure this suite exists to prevent. If a
# future TLC starts emitting one, it must arrive as a loud UNKNOWN_152 and be
# measured before it is named.
assert_absent "no case arm for the unprovokable 152 / 153" \
  '^[[:space:]]*15[23]\)'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
