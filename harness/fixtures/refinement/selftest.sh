#!/usr/bin/env bash
# selftest.sh — Executable spec for harness/refinement.sh (V2-PLAN.md §5.4,
# bead tla-kl5.7).
#
# Pins the RED invariant from the bead:
#
#   GIVEN a concrete spec with a FROZEN refinement mapping -- one that never
#   leaves its initial value -- WHEN refinement.sh runs, THEN it FAILS the
#   submission, even though TLC's own PROPERTY Refines check exits 0.
#
# Three kinds of assertion:
#
#   Behavioural — drive refinement.sh against a fixture directory and require
#     both the verdict token and the raw exit status. Asserting the rc as well
#     as the token keeps a renumbered table from relabelling itself silently,
#     the same discipline test-verdict.sh uses for §5.1.
#
#   Disjointness — drive verdict.sh DIRECTLY, bypassing refinement.sh, over the
#     hand-written .cfgs in cfg/. This is the load-bearing evidence that
#     Gate!RefinementConfigured and the probe catch disjoint failures, and it
#     has to bypass refinement.sh because refinement.sh is the thing that runs
#     them together. It is also the falsification test for the guard: if the
#     guard alone were sufficient, the frozen and correct rows would differ.
#
#   Structural — read refinement.sh itself for the constraints no fixture can
#     observe: that the probe operator it names is its own, that the two
#     channels are separate TLC runs, and that no verdict comes from TLC's
#     console text.
#
# Usage:  harness/fixtures/refinement/selftest.sh
# Exit:   0 if all assertions hold, 1 otherwise.
#
# Runtime is dominated by TLC start-up: ~30 invocations, a couple of seconds
# each. Every fixture state space is under ten states on purpose.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

REFINEMENT="harness/refinement.sh"
VERDICT="harness/verdict.sh"
FIX="harness/fixtures/refinement"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# assert_refinement <label> <want-verdict> <want-rc> [refinement.sh args...]
assert_refinement() {
  local label="$1" want_verdict="$2" want_rc="$3"
  shift 3
  local got_verdict got_rc
  got_verdict=$(bash "$REFINEMENT" "$@" 2>/dev/null)
  got_rc=$?
  if [ "$got_verdict" = "$want_verdict" ] && [ "$got_rc" = "$want_rc" ]; then
    ok "$label — $want_verdict (rc=$want_rc)"
  else
    nope "$label — wanted $want_verdict/rc=$want_rc, got '${got_verdict}'/rc=${got_rc}"
  fi
}

# assert_raw <label> <want-verdict> <want-rc> [verdict.sh args...]
assert_raw() {
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

if [ ! -f "$REFINEMENT" ]; then
  echo "FATAL: $REFINEMENT does not exist" >&2
  exit 1
fi

# refinement.sh with whole-line comments stripped, for the structural checks.
# The header names the very constructs those checks police, so matching the raw
# file would let a comment satisfy a must-be-present check and trip a
# must-be-absent one. Same trap test-verdict.sh documents for verdict.sh.
#
# Captured once and matched through a here-string, never through a pipe: under
# `pipefail` an early-exiting `grep -q` SIGPIPEs its producer and the pipeline
# reports 141, which an `if` reads as "pattern absent". See bead tla-kr9 and the
# long note in test-verdict.sh. Capturing alone does not fix it -- a `printf`
# feeding a pipe SIGPIPEs too; the pipe itself has to go.
REFINEMENT_CODE=$(sed 's/^[[:space:]]*#.*$//' "$REFINEMENT")

assert_present() {
  local label="$1" pattern="$2"
  if grep -qE -- "$pattern" <<<"$REFINEMENT_CODE"; then ok "$label"
  else nope "$label — pattern not found: $pattern (searched $(grep -c '' <<<"$REFINEMENT_CODE") lines of $REFINEMENT)"; fi
}

assert_absent() {
  local label="$1" pattern="$2" hits
  hits=$(grep -nE -- "$pattern" <<<"$REFINEMENT_CODE")
  if [ -z "$hits" ]; then ok "$label"
  else nope "$label — found: $(tr '\n' ' ' <<<"$hits")"; fi
}

# ---------------------------------------------------------------------------
echo "== THE BEAD'S RED LINE: frozen mapping fails, correct mapping passes =="
# ---------------------------------------------------------------------------
# These two fixtures differ in exactly one line -- the WITH clause. Everything
# else, including the concrete spec being graded, is identical. So the split
# below is attributable to the mapping and to nothing else.

assert_refinement "correct mapping" \
  "REFINES" 0 \
  "$FIX/correct/Concrete.tla"

assert_refinement "FROZEN mapping (TLC's own PROPERTY check exits 0)" \
  "FROZEN_MAPPING" 20 \
  "$FIX/frozen/Concrete.tla"

# The submission forges a probe that watches the concrete variable, so it fires
# whatever the mapping does. The harness must ignore it and reach the same
# verdict as frozen/ -- the forgery may make no difference at all.
assert_refinement "frozen mapping + a forged module-supplied probe" \
  "FROZEN_MAPPING" 20 \
  "$FIX/forged-probe/Concrete.tla"

# Without this row "correct passes" is unfalsifiable: a harness that answered
# REFINES unconditionally would score full marks on every row above.
assert_refinement "concrete spec that genuinely does not refine" \
  "REFINEMENT_VIOLATED" 22 \
  "$FIX/broken/Concrete.tla"

# The same verdict reached through the OTHER exit code. broken/ fails the
# implied action and exits 13; this one fails a `[](P => []P)` conjunct in the
# abstract's own Spec, which TLC refutes with a finite prefix and reports as a
# SAFETY violation at 12. Both are the refinement failing, and run A has to say
# so either way -- before bead tla-nesz this row returned SAFETY_VIOLATION/12
# out of the catch-all, so a caller branching on the token saw a safety
# violation with no refinement in it.
assert_refinement "abstract Spec carrying a safety-shaped temporal conjunct" \
  "REFINEMENT_VIOLATED" 22 \
  "$FIX/safety-conjunct/Concrete.tla"

# ---------------------------------------------------------------------------
echo
echo "== WE supply the mapping and grade only the concrete spec (§4.4 item 9) =="
# ---------------------------------------------------------------------------
# Same submission both times -- correct/Concrete.tla, which ships a correct
# mapping of its own. The harness overrides it. The verdict follows the
# harness's mapping, not the module's, which is what "X refines Y is a fact
# about X, Y AND the mapping" means operationally.

assert_refinement "harness-supplied mapping, correct" \
  "REFINES" 0 \
  --abstract Abstract --with 'level <- (ticks \div 3)' \
  "$FIX/correct/Concrete.tla"

assert_refinement "harness-supplied mapping, frozen — same submission" \
  "FROZEN_MAPPING" 20 \
  --abstract Abstract --with 'level <- 0' \
  "$FIX/correct/Concrete.tla"

# ---------------------------------------------------------------------------
echo
echo "== static refusals: the traps that never reach TLC =="
# ---------------------------------------------------------------------------

# §10: TLC silently ignores THEOREM. The fixture's concrete spec genuinely does
# not refine, and with no PROPERTY in the .cfg TLC reports no error at all.
assert_refinement "refinement claim living only in a THEOREM" \
  "THEOREM_ONLY" 23 \
  "$FIX/theorem-only/Concrete.tla"

# §10 / Specifying Systems p.244,246: unsound for temporal checking, and
# refinement is a temporal property. The run would still exit 0, so there is no
# verdict to read afterwards -- the refusal has to be static.
assert_refinement "SYMMETRY requested on a refinement problem" \
  "UNSOUND_REDUCTION" 24 \
  --constants "$FIX/fragments/symmetry.cfg" "$FIX/correct/Concrete.tla"

assert_refinement "VIEW requested on a refinement problem" \
  "UNSOUND_REDUCTION" 24 \
  --constants "$FIX/fragments/view.cfg" "$FIX/correct/Concrete.tla"

# §5.4: omitting WITH is silent. The fixture's implicit mapping happens to be
# sound and passes at rc=0, which is what makes it dangerous.
assert_refinement "INSTANCE with no WITH clause" \
  "IMPLICIT_MAPPING" 25 \
  "$FIX/implicit-with/Concrete.tla"

assert_refinement "...and the escape hatch reaches a real verdict" \
  "REFINES" 0 \
  --allow-implicit-mapping "$FIX/implicit-with/Concrete.tla"

# The other side of the same check, and a real false positive found by running
# refinement.sh over the shipped corpus: a mapping that is fully stated but
# WRAPPED across lines must not be read as an implicit one.
assert_refinement "a stated WITH wrapped across lines is NOT implicit" \
  "REFINES" 0 \
  "$FIX/wrapped-with/Concrete.tla"

# The problem directory ships a Gate.tla that nails RefinementConfigured to
# TRUE. TLA+ resolves modules against the root module's directory, so without
# this refusal the submission chooses its own guard.
assert_refinement "problem directory shadowing harness/Gate.tla" \
  "GATE_SHADOWED" 27 \
  "$FIX/gate-shadow/Concrete.tla"

# The constants fragment is the only caller-supplied text that reaches the
# generated .cfg. It carries data, never directives -- letting the subject
# author part of its own oracle config is how TLAiBench's trapdoor stays open.
assert_refinement "checking directive smuggled into the constants fragment" \
  "FRAGMENT_REFUSED" 28 \
  --constants "$FIX/fragments/directive.cfg" "$FIX/correct/Concrete.tla"

# The two rows above put the directive at the start of its own line, which is
# where an anchored match can see it. TLC's .cfg parser does not work that way:
# measured on v1.8.0, `CONSTANT Unused = 6 INVARIANT Bad` and `(* c *) INVARIANT
# Bad` both check Bad and exit 12. So the guard has to match a token anywhere in
# the fragment, over text with BOTH comment forms stripped.
#
# These two rows are what run A's `12)` arm rests on. Run A's .cfg declares no
# INVARIANT, so a 12 there can only be the refinement PROPERTY -- and the
# fragment is the only text that could put an invariant in it. The first row
# below is that hole: measured before the guard was tightened, it returned
# SAFETY_VIOLATION/12 against correct/Concrete.tla, whose refinement is fine.
assert_refinement "a directive riding at the END of a CONSTANT line" \
  "FRAGMENT_REFUSED" 28 \
  --constants "$FIX/fragments/smuggled-trailing.cfg" "$FIX/correct/Concrete.tla"

# Same route against the SYMMETRY refusal, which is the worse half. A missed
# INVARIANT mislabels a verdict; a missed SYMMETRY runs an unsound temporal
# check that still exits 0, and there is no verdict afterwards that would tell
# you the answer was wrong.
assert_refinement "SYMMETRY hidden behind a block comment" \
  "UNSOUND_REDUCTION" 24 \
  --constants "$FIX/fragments/smuggled-block.cfg" "$FIX/correct/Concrete.tla"

assert_refinement "a legal (empty) constants fragment is accepted" \
  "REFINES" 0 \
  --constants "$FIX/fragments/ok.cfg" "$FIX/correct/Concrete.tla"

assert_refinement "a CONSTANT fragment is accepted" \
  "REFINES" 0 \
  --constants "$FIX/fragments/constant.cfg" "$FIX/correct/Concrete.tla"

# ---------------------------------------------------------------------------
echo
echo "== the probe's own soundness =="
# ---------------------------------------------------------------------------
# --initial pins the mapped tuple to a declared value instead of using the
# abstract's Init. Declare the wrong value and the probe is violated in the
# INITIAL state: rc=12, which looks exactly like a healthy moving mapping.
# The trace depth is what tells them apart.

assert_refinement "--initial declaring the true initial value" \
  "REFINES" 0 \
  --initial '<< 0 >>' "$FIX/correct/Concrete.tla"

assert_refinement "--initial declaring the WRONG initial value" \
  "PROBE_MISDECLARED" 26 \
  --initial '<< 1 >>' "$FIX/correct/Concrete.tla"

# ---------------------------------------------------------------------------
echo
echo "== TLC-level outcomes pass through with their own verdict.sh token =="
# ---------------------------------------------------------------------------

assert_refinement "missing module" \
  "PARSE_ERROR" 150 \
  "$FIX/correct/NoSuchModule.tla"

# ---------------------------------------------------------------------------
echo
echo "== DISJOINTNESS: the guard and the probe catch different failures =="
# ---------------------------------------------------------------------------
# Driven through verdict.sh directly, because refinement.sh is the thing that
# runs both and the point is to see each one alone. Staged into a scratch
# directory so harness/Gate.tla is resolvable without a copy in the repo.

DISJOINT=$(mktemp -d -t tla_refinement_disjoint.XXXXXX)
trap 'rm -rf "$DISJOINT"' EXIT
for f in correct frozen; do
  mkdir -p "$DISJOINT/$f"
  cp "$FIX/$f"/*.tla "$DISJOINT/$f"/
  cp harness/Gate.tla "$DISJOINT/$f"/
  cp "$FIX"/cfg/*.cfg "$DISJOINT/$f"/
done

echo "-- no PROPERTY in the cfg: the guard fires, the probe is not in play"
assert_raw "  correct mapping" "ASSUMPTION_FAILED" 10 \
  --config "$DISJOINT/correct/no-property.cfg" \
  --postcondition "Gate!RefinementConfigured" "$DISJOINT/correct/Concrete.tla"
assert_raw "  frozen mapping " "ASSUMPTION_FAILED" 10 \
  --config "$DISJOINT/frozen/no-property.cfg" \
  --postcondition "Gate!RefinementConfigured" "$DISJOINT/frozen/Concrete.tla"

echo "-- PROPERTY present: the guard is SILENT for both, correct and frozen alike"
assert_raw "  correct mapping" "OK" 0 \
  --config "$DISJOINT/correct/property.cfg" \
  --postcondition "Gate!RefinementConfigured" "$DISJOINT/correct/Concrete.tla"
assert_raw "  frozen mapping " "OK" 0 \
  --config "$DISJOINT/frozen/property.cfg" \
  --postcondition "Gate!RefinementConfigured" "$DISJOINT/frozen/Concrete.tla"

echo "-- the probe alone: the ONLY check that separates them"
assert_raw "  correct mapping (probe VIOLATED = good)" "SAFETY_VIOLATION" 12 \
  --config "$DISJOINT/correct/probe.cfg" "$DISJOINT/correct/Concrete.tla"
assert_raw "  frozen mapping  (probe PASSES = bad)" "OK" 0 \
  --config "$DISJOINT/frozen/probe.cfg" "$DISJOINT/frozen/Concrete.tla"

echo "-- and the combined .cfg cannot certify the refinement at all"
# The invariant violation preempts the property check and truncates the state
# space under it: 4 of the 7 reachable states, so the property was never
# evaluated over the other 3. This row is why refinement.sh uses two runs.
assert_raw "  correct mapping, all three cfg lines at once" "SAFETY_VIOLATION" 12 \
  --config "$DISJOINT/correct/combined.cfg" \
  --postcondition "Gate!RefinementConfigured" "$DISJOINT/correct/Concrete.tla"

# ---------------------------------------------------------------------------
echo
echo "== the artifacts the harness generates, read off disk =="
# ---------------------------------------------------------------------------
# Read from --keep rather than inferred from an exit code. Some of these have
# no exit code to infer from: TLC accepts a CONSTANT naming something no spec
# declares in total silence -- rc=0, no warning even without -nowarning -- so
# the only way to show the fragment was spliced is to look at the .cfg.

KEPT=$(mktemp -d -t tla_refinement_kept.XXXXXX)
rm -rf "$KEPT"
bash "$REFINEMENT" --keep "$KEPT" -q \
  --constants "$FIX/fragments/constant.cfg" "$FIX/correct/Concrete.tla" >/dev/null 2>&1
trap 'rm -rf "$DISJOINT" "$KEPT"' EXIT

has()    { [ -f "$1" ] && grep -qE -- "$2" "$1"; }
hasnt()  { [ -f "$1" ] && ! grep -qE -- "$2" "$1"; }
check()  { if "$@"; then ok "$LBL"; else nope "$LBL"; fi; }

# A directive the harness writes IS at the start of its own line, so the two
# must-be-present rows stay anchored. The two must-be-ABSENT rows cannot: a
# .cfg directive is a token to TLC wherever it sits, and an anchored match
# cannot see one riding at the end of another line. Those two rows are the
# by-construction evidence for run A's `12)` arm and run B's, so they go
# through cfg_declares, which strips both comment forms and then matches the
# keyword as a token anywhere.
#
# Stripping is what makes the rows survive the fragment spliced in below: it
# carries the words PROPERTY and INVARIANT inside a `\*` comment, which TLC
# ignores and so must these checks.
cfg_declares() {   # cfg_declares <cfg> <keyword>
  local body
  body=$(sed -e 's/\\\*.*$//' -e 's/(\*[^*]*\*)//g' "$1")
  grep -qE "(^|[^A-Za-z0-9_])$2([^A-Za-z0-9_]|\$)" <<<"$body"
}
undeclared() { ! cfg_declares "$1" "$2"; }

LBL="run-a.cfg carries the refinement PROPERTY";           check has        "$KEPT/run-a.cfg" '^[[:space:]]*PROPERTY'
LBL="run-a.cfg declares NO invariant — separate runs";     check undeclared "$KEPT/run-a.cfg" 'INVARIANT'
LBL="run-b.cfg carries the harness's own probe";           check has        "$KEPT/run-b.cfg" '^[[:space:]]*INVARIANT[[:space:]]+HarnessProbe'
LBL="run-b.cfg declares NO property — separate runs";      check undeclared "$KEPT/run-b.cfg" 'PROPERTY'
LBL="no generated .cfg names the module's own Probe";      check hasnt "$KEPT/run-b.cfg" '^[[:space:]]*INVARIANT[[:space:]]+Probe([^A-Za-z0-9_]|$)'
LBL="the constants fragment reached run-a.cfg";            check has   "$KEPT/run-a.cfg" '^CONSTANT Limit = 6'
LBL="the constants fragment reached run-b.cfg";            check has   "$KEPT/run-b.cfg" '^CONSTANT Limit = 6'
LBL="the probe is the SUBSTITUTED abstract Init";          check has   "$KEPT/RefHarness.tla" 'HarnessProbe == A!Init'

# The gate TLC loads is the harness's, byte for byte. gate-shadow/ covers the
# refusal; this covers the staging that makes the refusal belt-and-braces.
LBL="the staged Gate.tla is harness/Gate.tla, byte-identical"
check cmp -s "$KEPT/Gate.tla" harness/Gate.tla

# No .cfg is ever taken from the problem directory.
LBL="no .cfg was copied out of the problem directory"
if [ -z "$(find "$KEPT" -maxdepth 1 -name '*.cfg' ! -name 'run-a.cfg' ! -name 'run-b.cfg' -print -quit)" ]; then
  ok "$LBL"; else nope "$LBL"; fi

# ---------------------------------------------------------------------------
echo
echo "== structural: constraints no fixture can observe =="
# ---------------------------------------------------------------------------

# The probe operator refinement.sh names in its .cfg must be its own. Naming a
# module-supplied one is the forged-probe/ hole.
assert_present "the generated .cfg names the harness's own probe operator" \
  'INVARIANT[[:space:]]+HarnessProbe'

assert_absent "no .cfg line naming a module-supplied probe" \
  'INVARIANT[[:space:]]+Probe([^A-Za-z0-9_]|$)'

# Two channels, two TLC runs. A single printf writing both keywords would be a
# combined .cfg, which reports only that the probe fired -- measured: rc=12
# with the search truncated at 4 of the 7 reachable states.
assert_absent "no single printf writes both PROPERTY and INVARIANT" \
  'printf.*PROPERTY.*INVARIANT'

# The guard belongs to the refinement run only. Attached to the probe run it
# fires on the missing PROPERTY and masks the FROZEN_MAPPING verdict --
# measured: frozen/ returns rc=10 instead of rc=0.
assert_present "Gate!RefinementConfigured is used" \
  'Gate!RefinementConfigured'

# Verdicts come from exit codes. refinement.sh reads its own generated files and
# the submitted module's text, but never TLC's console output.
assert_absent "no TLC stdout phrases used as literals" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached|Finished in|unexpected exception)'

# §10 and §5.4 name these two by name; the refusals must be in the code.
assert_present "SYMMETRY is refused by name" 'SYMMETRY'
assert_present "VIEW is refused by name"     'VIEW'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
