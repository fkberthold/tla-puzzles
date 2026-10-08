#!/usr/bin/env bash
# selftest.sh — Executable spec for harness/seeded-bugs.sh (V2-PLAN.md §5.5,
# bead tla-kl5.8).
#
# Pins the RED line from the bead:
#
#   GIVEN a reference spec, a seeded variant, and a learner property, WHEN
#   seeded-bugs.sh runs, THEN it passes only on rc==0-against-reference AND
#   rc==12-against-variant -- and `Inv == TRUE` fails the matrix.
#
# Four kinds of assertion:
#
#   Behavioural — drive seeded-bugs.sh over a fixture matrix and require both
#     the verdict token and the raw exit status. Asserting the rc as well as
#     the token keeps a renumbered table from relabelling itself silently, the
#     same discipline test-verdict.sh uses for §5.1 and selftest.sh for §5.4.
#
#   Attribution — the inert-mutant rows. The verdict for an inert variant set
#     must be the SAME whichever submission is graded against it, because the
#     defect is in the variant set and has nothing to do with the submission.
#     Two rows, one with a good property and one with `Inv == TRUE`, are what
#     make that a measurement instead of a claim.
#
#   Trace-signature — drive the comparator directly over hand-written traces
#     in traces/. This is the only way to show what the comparison IGNORES:
#     two traces with the same actions and different concrete values, in
#     different representations, must compare equal. A live fixture can only
#     ever show agreement or divergence, never the reason for it.
#
#   Structural — read seeded-bugs.sh itself for the constraints no fixture can
#     observe: that the caveat is in the file, that no verdict comes from TLC's
#     console text, and that no live pipe feeds an early-exiting consumer,
#     which loses a match to SIGPIPE under `set -o pipefail`.
#
# THE PIPE HAZARD APPLIES TO THIS FILE TOO, and capturing the producer first
# does NOT fix it. Measured on bash 5.2.21, 20k lines, match on line 1:
#
#   chatty | grep -qE MATCHME                              -> rc=141
#   out=$(chatty); printf '%s\n' "$out" | grep -qE MATCHME -> rc=141
#   out=$(chatty); grep -qE MATCHME <<<"$out"              -> rc=0
#
# The LIVE PIPE is the bug, not the producer: `printf` forks into the pipeline
# and takes the signal exactly as a command would. A here-string is
# materialised in full before the consumer is exec'd, so there is no writer
# left to signal. Every match below is therefore a here-string, and the one
# `head` this file used to take the first line of a report is now a parameter
# expansion. Bead tla-kr9; harness/test-pipefail.sh gates it repo-wide.
#
# Usage:  harness/fixtures/seeded-bugs/selftest.sh
# Exit:   0 if all assertions hold, 1 otherwise.
#
# Runtime is dominated by TLC start-up: ~40 invocations, a couple of seconds
# each. Every fixture state space is under six states on purpose.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SEEDED="harness/seeded-bugs.sh"
FIX="harness/fixtures/seeded-bugs"
MATRIX="$FIX/crossing"
PROPS="$FIX/properties"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# assert_matrix <label> <want-verdict> <want-rc> [seeded-bugs.sh args...]
assert_matrix() {
  local label="$1" want_verdict="$2" want_rc="$3"
  shift 3
  local out got_verdict got_rc
  out=$(bash "$SEEDED" "$@" 2>/dev/null)
  got_rc=$?
  got_verdict=${out%%$'\n'*}
  if [ "$got_verdict" = "$want_verdict" ] && [ "$got_rc" = "$want_rc" ]; then
    ok "$label — $want_verdict (rc=$want_rc)"
  else
    nope "$label — wanted $want_verdict/rc=$want_rc, got '${got_verdict}'/rc=${got_rc}"
  fi
}

# assert_report <label> <pattern> [seeded-bugs.sh args...]
# The report is learner-facing prose. These rows check that the diagnosis
# names the thing that is actually wrong; "too weak" without the variant is
# not feedback anyone can act on.
assert_report() {
  local label="$1" pattern="$2"
  shift 2
  local out
  out=$(bash "$SEEDED" "$@" 2>/dev/null)
  if grep -qE -- "$pattern" <<<"$out"; then
    ok "$label"
  else
    nope "$label — report did not match: $pattern"
  fi
}

# assert_signature_eq / _ne <label> <trace-a> <trace-b>
sig() { bash "$SEEDED" --trace-signature "$1" 2>/dev/null; }

assert_signature_eq() {
  local label="$1" a b
  a=$(sig "$2"); b=$(sig "$3")
  if [ -n "$a" ] && [ "$a" = "$b" ]; then ok "$label — both '$a'"
  else nope "$label — '$a' vs '$b'"; fi
}

assert_signature_ne() {
  local label="$1" a b
  a=$(sig "$2"); b=$(sig "$3")
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ]; then ok "$label — '$a' vs '$b'"
  else nope "$label — expected a difference, got '$a' vs '$b'"; fi
}

# seeded-bugs.sh with whole-line comments stripped, for the structural checks.
# The header names the very constructs those checks police, so matching the raw
# file would let a comment satisfy a must-be-present check and trip a
# must-be-absent one. Same trap test-verdict.sh documents for verdict.sh.
seeded_code() { sed 's/^[[:space:]]*#.*$//' "$SEEDED"; }

assert_code_present() {
  local label="$1" pattern="$2" out
  out=$(seeded_code) || true
  if grep -qE -- "$pattern" <<<"$out"; then ok "$label"
  else nope "$label — pattern not found: $pattern"; fi
}

assert_code_absent() {
  local label="$1" pattern="$2" out hits
  out=$(seeded_code) || true
  hits=$(grep -nE -- "$pattern" <<<"$out")
  if [ -z "$hits" ]; then ok "$label"
  else nope "$label — found: $(tr '\n' ' ' <<<"$hits")"; fi
}

# The caveat is IN THE COMMENTS, so this one reads the raw file.
assert_file_present() {
  local label="$1" pattern="$2" out
  out=$(cat "$SEEDED") || true
  if grep -qE -- "$pattern" <<<"$out"; then ok "$label"
  else nope "$label — pattern not found: $pattern"; fi
}

# The pipe ban applies to every shell file under harness/, this one included.
# Scanned here as well as by harness/test-pipefail.sh (tla-kr9) so that the
# component's own suite fails on a regression rather than waiting for the
# repo-wide gate.
assert_no_live_pipe() {
  local label="$1" file="$2" out hits
  out=$(sed 's/^[[:space:]]*#.*$//' "$file") || true
  hits=$(grep -nE '\|[[:space:]]*(grep[[:space:]]+-[A-Za-z]*[qm]|head)([[:space:]]|$)' <<<"$out")
  if [ -z "$hits" ]; then ok "$label"
  else nope "$label — found: $(tr '\n' ' ' <<<"$hits")"; fi
}

if [ ! -f "$SEEDED" ]; then
  echo "FATAL: $SEEDED does not exist" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
echo "== THE BEAD'S RED LINE: rc==0 on the reference AND rc==12 on every variant =="
# ---------------------------------------------------------------------------

assert_matrix "a property that catches every seeded bug" \
  "BUGS_CAUGHT" 0 \
  --matrix "$MATRIX" --alias Alias "$PROPS/Good.tla"

# THE ROW THE WHOLE COMPONENT EXISTS FOR. `Inv == TRUE` passes §5.3's vacuity
# probes, the comment gate, and every check that asks "does your property
# hold". This is the only one that asks whether it ever says no.
assert_matrix "Inv == TRUE" \
  "PROPERTY_TOO_WEAK" 40 \
  --matrix "$MATRIX" --alias Alias "$PROPS/AlwaysTrue.tla"

# Without these two rows "catches the seeded bugs" would be satisfiable by a
# single conjunct. Neither half of the oracle subsumes the other.
assert_matrix "mutual exclusion alone — misses amber-on-go" \
  "PROPERTY_TOO_WEAK" 40 \
  --matrix "$MATRIX" --alias Alias "$PROPS/MutexOnly.tla"

assert_matrix "a type invariant alone — misses both mutex variants" \
  "PROPERTY_TOO_WEAK" 40 \
  --matrix "$MATRIX" --alias Alias "$PROPS/TypeOnly.tla"

# The other half of the conjunction, and the mirror image of Inv == TRUE:
# asserting something FALSE catches every variant and is just as worthless.
assert_matrix "a property the reference itself violates" \
  "PROPERTY_UNSOUND" 41 \
  --matrix "$MATRIX" --alias Alias "$PROPS/Unsound.tla"

# "Too weak" on its own is not feedback. The failing variant has to be named.
assert_report "the too-weak diagnosis names the variant that got through" \
  'amber-on-go' \
  --matrix "$MATRIX" --alias Alias "$PROPS/MutexOnly.tla"

# ---------------------------------------------------------------------------
echo
echo "== ATTRIBUTION: an inert mutant is OUR bug, not the learner's =="
# ---------------------------------------------------------------------------
# variants-inert/ holds one live variant and one whose mutation changes
# nothing at all -- `ns # \"red\"` where the reference says `ns = \"green\"`,
# equivalent on every reachable state. No property can distinguish it, so
# blaming a submission for not catching it would be blaming it for our defect.
#
# The two rows below are the measurement: the verdict does not depend on which
# submission is graded. If the inert check ran after the grading, the second
# row would come back PROPERTY_TOO_WEAK and blame the learner.

assert_matrix "inert variant, graded against a GOOD property" \
  "VARIANT_INERT" 42 \
  --matrix "$MATRIX" --variants "$FIX/variants-inert" --alias Alias \
  "$PROPS/Good.tla"

assert_matrix "inert variant, graded against Inv == TRUE — SAME verdict" \
  "VARIANT_INERT" 42 \
  --matrix "$MATRIX" --variants "$FIX/variants-inert" --alias Alias \
  "$PROPS/AlwaysTrue.tla"

assert_report "the inert diagnosis names the variant set, not the submission" \
  'variant set' \
  --matrix "$MATRIX" --variants "$FIX/variants-inert" --alias Alias \
  "$PROPS/AlwaysTrue.tla"

assert_report "the inert diagnosis names the inert variant" \
  'inert-guard' \
  --matrix "$MATRIX" --variants "$FIX/variants-inert" --alias Alias \
  "$PROPS/Good.tla"

# ---------------------------------------------------------------------------
echo
echo "== the instrument checks itself before it grades anything =="
# ---------------------------------------------------------------------------

assert_matrix "an oracle the reference itself violates" \
  "ORACLE_UNSOUND" 45 \
  --matrix "$MATRIX" --oracle "$FIX/oracle-unsound/Oracle.tla" --alias Alias \
  "$PROPS/Good.tla"

# A variant directory that does not supply the reference module under its own
# name would stage the REFERENCE and report rc==0 -- indistinguishable from
# "the property failed to catch this bug".
assert_matrix "a variant directory missing the module it mutates" \
  "MATRIX_MALFORMED" 44 \
  --matrix "$MATRIX" --variants "$FIX/variants-malformed" --alias Alias \
  "$PROPS/Good.tla"

# ---------------------------------------------------------------------------
echo
echo "== TLC-level outcomes pass through with their own verdict.sh token =="
# ---------------------------------------------------------------------------

assert_matrix "missing property module" \
  "PARSE_ERROR" 150 \
  --matrix "$MATRIX" --alias Alias "$PROPS/NoSuchModule.tla"

# ---------------------------------------------------------------------------
echo
echo "== TRACE COMPARISON: action-name sequence + length, and nothing else =="
# ---------------------------------------------------------------------------
# Driven over hand-written traces, because this is the only place the
# comparison's BLINDNESS can be shown. A live fixture can show that two runs
# agree; it cannot show that they would still have agreed had the values
# differed. The two traces below carry different variable NAMES, different
# value DOMAINS (integers vs strings) and different concrete values, and they
# describe the same behaviour.

assert_signature_eq "different representation, same behaviour — no divergence" \
  "$FIX/traces/base.json" "$FIX/traces/same-actions-other-values.json"

assert_signature_ne "a different action name IS a divergence" \
  "$FIX/traces/base.json" "$FIX/traces/other-actions.json"

assert_signature_ne "a different trace length IS a divergence" \
  "$FIX/traces/base.json" "$FIX/traces/shorter.json"

# variants-divergent/two-bugs is broken twice over, at the same depth, by
# different actions. A mutual-exclusion property and a type property both
# exit 12 on it and catch different bugs.
assert_matrix "divergent trace is reported but does NOT fail by default" \
  "BUGS_CAUGHT" 0 \
  --matrix "$MATRIX" --variants "$FIX/variants-divergent" --alias Alias \
  "$PROPS/TypeOnly.tla"

assert_report "...and the report says so out loud" \
  'TRACE' \
  --matrix "$MATRIX" --variants "$FIX/variants-divergent" --alias Alias \
  "$PROPS/TypeOnly.tla"

assert_matrix "...and --strict-trace promotes it to a failure" \
  "TRACE_DIVERGED" 43 \
  --matrix "$MATRIX" --variants "$FIX/variants-divergent" --alias Alias \
  --strict-trace "$PROPS/TypeOnly.tla"

# The falsification row. Without it, --strict-trace failing above would be
# consistent with a comparator that reports divergence unconditionally.
assert_matrix "a property equivalent to the oracle agrees under --strict-trace" \
  "BUGS_CAUGHT" 0 \
  --matrix "$MATRIX" --variants "$FIX/variants-divergent" --alias Alias \
  --strict-trace "$PROPS/Good.tla"

# ---------------------------------------------------------------------------
echo
echo "== PARAMETERISED MATRIX: constants reach every generated .cfg =="
# ---------------------------------------------------------------------------
# crossing/ declares no CONSTANT, so every row above it can pass on a matrix
# that has no way to assign one. parameterized/ is the row that cannot: its
# reference, its oracle, its variant and both its properties all mention
# `Accounts` and `MaxBalance`, so a run with no constants channel dies at
# PHASE 1 with CONFIG_ERROR (rc=151) -- "The constant parameter MaxBalance is
# not assigned a value by the configuration file" -- before it grades
# anything. Bead tla-40y; found running the tla-kl5.11 pilot, whose reference
# declares `Departments` and `MaxAmendments`.
#
# The assignment lives in parameterized/reference/constants.cfg, beside the
# reference module, and seeded-bugs.sh appends it to every .cfg it generates.
# That is grade.sh's idiom, not a second one.

PMATRIX="$FIX/parameterized"
PPROPS="$PMATRIX/properties"
PKEPT=$(mktemp -d -t tla_seeded_param.XXXXXX)
rm -rf "$PKEPT"

assert_matrix "a matrix whose spec declares constants runs at all" \
  "BUGS_CAUGHT" 0 \
  --matrix "$PMATRIX" --keep "$PKEPT" "$PPROPS/LedgerGood.tla"

# The other direction. A channel that assigned the constants and then made
# every run pass would show up here as BUGS_CAUGHT. LedgerWeak names
# `Accounts` too, so its rc=0 against the variant is evidence about the
# grading rather than evidence that the property was trivially true.
assert_matrix "...and grading still discriminates once they are assigned" \
  "PROPERTY_TOO_WEAK" 40 \
  --matrix "$PMATRIX" "$PPROPS/LedgerWeak.tla"

# EVERY generated .cfg, not just the first. The oracle runs and the submission
# runs, the reference runs and the variant runs: a fragment that reached only
# some of them would fail one phase with CONFIG_ERROR and pass the rest, which
# is a harness fault wearing a verdict's clothes. Counted rather than sampled.
NCFG=$(find "$PKEPT" -name 'run.cfg' | wc -l)
NCONST=$(grep -rlE '^[[:space:]]*MaxBalance[[:space:]]*=' "$PKEPT" --include='run.cfg' | wc -l)
LBL="the constants fragment reached every generated .cfg ($NCONST of $NCFG)"
if [ "$NCFG" -gt 0 ] && [ "$NCFG" = "$NCONST" ]; then ok "$LBL"; else nope "$LBL"; fi

LBL="the fragment was APPENDED, not copied into the staging directory"
if [ -z "$(find "$PKEPT" -name '*.cfg' ! -name 'run.cfg' -print -quit)" ]; then
  ok "$LBL"; else nope "$LBL"; fi

# The fixture's own fragment carries the words INVARIANT and SYMMETRY inside
# `\*` comments. The BUGS_CAUGHT row above therefore also witnesses that
# comments are stripped before the refusal below runs -- but only for as long
# as those words are still in the file, so pin them.
LBL="the good fragment's comments do name the refused directives"
if grep -qE '\\\*.*(INVARIANT|SYMMETRY)' "$PMATRIX/reference/constants.cfg"; then
  ok "$LBL"; else nope "$LBL"; fi

rm -rf "$PKEPT"

# ---------------------------------------------------------------------------
echo
echo "== LIVENESS: a temporal obligation is graded as a temporal obligation =="
# ---------------------------------------------------------------------------
# WHY THIS SECTION HAD TO EXIST BEFORE THE FIX COULD BE TRUSTED. Every row
# above this one has a STATE PREDICATE for its obligation, so every row above
# passes on a script that writes `INVARIANT` into the .cfg unconditionally and
# reads rc==12 as the only refutation. That is what seeded-bugs.sh did until
# bead tla-r2ih, and it is why the defect reached the field: the tla-pmm2.2
# spike author hit it on the first liveness problem the project attempted,
# wrote a state-predicate surrogate to get a number, and measured the
# surrogate firing exactly one `Begin` step later than the oracle. The matrix
# reported BUGS_CAUGHT either way.
#
# relay/ is the pair crossing/ cannot be. Its obligation is `[]<>(stage = 2)`,
# which no finite prefix refutes, so TLC checks it through the liveness
# channel and exits 13. Measured on v1.8.0, every refutation in this fixture:
# rc=13, never 12.
#
# The obligation is named `Live` rather than `Inv`, per
# `.claude/rules/tla-practice.md` §3 -- an `*Inv` name tells a reader the
# obligation is a state predicate and this one is not -- and the matrix is
# driven against `FairSpec`, because against `Spec` the stuttering behaviour
# refutes the correct property too.

RMATRIX="$FIX/relay"
RPROPS="$RMATRIX/properties"
relay=(--matrix "$RMATRIX" --spec FairSpec --property Live --alias Alias)

# THE ROW THE WHOLE BEAD IS ABOUT. Before the fix this was
# SAFETY_EVAL_FAILURE/rc=76 -- TLC handed a temporal formula under the
# INVARIANT keyword cannot evaluate it as a state predicate, so PHASE 1 died
# and nothing was graded at all.
assert_matrix "a temporal property that catches every seeded bug" \
  "BUGS_CAUGHT" 0 \
  "${relay[@]}" "$RPROPS/RelayGood.tla"

# `Inv == TRUE`'s temporal twin: true of the reference, true of both variants,
# and it has to be refused for the same reason. A trivially true STATE
# predicate would be graded by the invariant channel and would say nothing
# about whether the temporal channel grades at all.
assert_matrix "a trivially true temporal property" \
  "PROPERTY_TOO_WEAK" 40 \
  "${relay[@]}" "$RPROPS/RelayVacuous.tla"

# The discriminating row. RelayWeak catches advance-stalls and misses
# recycle-early, so it is the only evidence that rc=13 is read as a refutation
# PER VARIANT rather than anywhere.
assert_matrix "a temporal property that catches one variant of two" \
  "PROPERTY_TOO_WEAK" 40 \
  "${relay[@]}" "$RPROPS/RelayWeak.tla"

# Captured once and matched twice: assert_report re-runs the matrix, and six
# TLC invocations is not worth a second grep.
RWEAK=$(bash "$SEEDED" "${relay[@]}" "$RPROPS/RelayWeak.tla" 2>/dev/null)

LBL="the too-weak diagnosis names the temporal variant that got through"
if grep -qE -- 'recycle-early: not caught' <<<"$RWEAK"; then ok "$LBL"
else nope "$LBL"; fi

# THE REFUTATION CODE, PINNED. 13 and not 12, read off the matrix table the
# learner sees. A script that had been taught the PROPERTY keyword and not the
# code would report this variant as MISSED and bill it to the submission.
LBL="a liveness refutation is reported as rc=13"
if grep -qE -- 'advance-stalls: caught \(rc=13\)' <<<"$RWEAK"; then ok "$LBL"
else nope "$LBL"; fi

# PHASE 2 over the liveness channel. Without this row, rc=13 reaching
# PROPERTY_UNSOUND would be untested, and the learner would be told TLC's exit
# code where they could have been told their property is wrong.
assert_matrix "a temporal property the reference itself violates" \
  "PROPERTY_UNSOUND" 41 \
  "${relay[@]}" "$RPROPS/RelayUnsound.tla"

# ---------------------------------------------------------------------------
echo
echo "== a liveness verdict against an unfair spec is refused, not counted =="
# ---------------------------------------------------------------------------
# `Spec == Init /\ [][Next]_vars` admits the behaviour that takes some steps
# and then stutters for ever, and that behaviour violates every liveness
# property anyone could write -- RelayGood included. Measured: against `Spec`
# the matrix's OWN oracle exits 13 on the reference, so without the gate the
# matrix reports ORACLE_UNSOUND and blames the instrument for the config.
#
# Attributed to the MATRIX, because the missing fairness conjunct is the
# matrix author's defect and not the submission's. Same party, same code, as
# every other way the matrix can be the wrong shape.
#
# The gate fires on three conditions together -- rc==13, a `<>` or `~>` in the
# obligation's closure, and no WF_/SF_ in the spec's. Each alone over-refuses:
# `[][A]_vars` exits 13 and needs no fairness, and `~<>P` carries a diamond
# and is safety. The crossing rows above are the falsification: their
# obligations are state predicates against an unfair `Spec`, and they pass.

assert_matrix "a liveness matrix driven against an UNFAIR spec operator" \
  "MATRIX_MALFORMED" 44 \
  --matrix "$RMATRIX" --spec Spec --property Live --alias Alias \
  "$RPROPS/RelayGood.tla"

assert_report "...and the refusal names fairness rather than the submission" \
  'no fairness conjunct' \
  --matrix "$RMATRIX" --spec Spec --property Live --alias Alias \
  "$RPROPS/RelayGood.tla"

# ---------------------------------------------------------------------------
echo
echo "== the .cfg keyword follows the obligation's SHAPE, read off disk =="
# ---------------------------------------------------------------------------
# The keyword is the defect's actual site. A matrix can come back BUGS_CAUGHT
# with the wrong keyword in cases where TLC happens to tolerate it, so the
# generated .cfg is read rather than inferred from the verdict -- and EVERY
# generated .cfg, counted rather than sampled, because a keyword that was
# right for the oracle run and wrong for a variant run is a verdict about two
# different formulas.

RKEPT=$(mktemp -d -t tla_seeded_relay.XXXXXX)
rm -rf "$RKEPT"
bash "$SEEDED" -q --keep "$RKEPT" "${relay[@]}" \
  "$RPROPS/RelayGood.tla" >/dev/null 2>&1

RNCFG=$(find "$RKEPT" -name 'run.cfg' | wc -l)
RNPROP=$(grep -rlE '^[[:space:]]*PROPERTY[[:space:]]+Live[[:space:]]*$' \
  "$RKEPT" --include='run.cfg' | wc -l)
LBL="the temporal obligation went in as PROPERTY in every .cfg ($RNPROP of $RNCFG)"
if [ "$RNCFG" -gt 0 ] && [ "$RNCFG" = "$RNPROP" ]; then ok "$LBL"; else nope "$LBL"; fi

# The must-be-absent half. This is the line that was there before tla-r2ih.
LBL="no .cfg wrote INVARIANT over the temporal obligation"
RNINV=$(grep -rlE '^[[:space:]]*INVARIANT' "$RKEPT" --include='run.cfg' | wc -l)
if [ "$RNINV" = "0" ]; then ok "$LBL"; else nope "$LBL — $RNINV of $RNCFG"; fi

# The generated SPECIFICATION line names the FAIR operator, so the fairness
# conjunct reaches TLC rather than merely existing in the module.
LBL="the generated .cfg names the fair spec operator"
RNFAIR=$(grep -rlE '^[[:space:]]*SPECIFICATION[[:space:]]+FairSpec[[:space:]]*$' \
  "$RKEPT" --include='run.cfg' | wc -l)
if [ "$RNCFG" -gt 0 ] && [ "$RNCFG" = "$RNFAIR" ]; then ok "$LBL"
else nope "$LBL — $RNFAIR of $RNCFG"; fi

rm -rf "$RKEPT"

# The mirror of the two keyword rows above, on the SAFETY matrix. Without it,
# a script that wrote PROPERTY unconditionally would pass every row in this
# section — the inverse of the bug, and just as wrong.
SKEPT=$(mktemp -d -t tla_seeded_safety.XXXXXX)
rm -rf "$SKEPT"
bash "$SEEDED" -q --keep "$SKEPT" --matrix "$MATRIX" --alias Alias \
  "$PROPS/Good.tla" >/dev/null 2>&1

SNCFG=$(find "$SKEPT" -name 'run.cfg' | wc -l)
SNINV=$(grep -rlE '^[[:space:]]*INVARIANT[[:space:]]+Inv[[:space:]]*$' \
  "$SKEPT" --include='run.cfg' | wc -l)
LBL="a state predicate still goes in as INVARIANT in every .cfg ($SNINV of $SNCFG)"
if [ "$SNCFG" -gt 0 ] && [ "$SNCFG" = "$SNINV" ]; then ok "$LBL"; else nope "$LBL"; fi

LBL="no .cfg wrote PROPERTY over the state predicate"
SNPROP=$(grep -rlE '^[[:space:]]*PROPERTY' "$SKEPT" --include='run.cfg' | wc -l)
if [ "$SNPROP" = "0" ]; then ok "$LBL"; else nope "$LBL — $SNPROP of $SNCFG"; fi

rm -rf "$SKEPT"

# ---------------------------------------------------------------------------
echo
echo "== a constants fragment carries CONSTANTS, and nothing else =="
# ---------------------------------------------------------------------------
# The fragment is the only text from the matrix directory that reaches a
# generated .cfg, so it is the one place the harness's ownership of that .cfg
# can leak. Refused before anything is staged, and attributed to the matrix.
#
# Both classes are in constants-refused/constants.cfg. SYMMETRY is the
# soundness one: symmetry reduction is sound only for a symmetric property,
# the submitted property is not the author's to vouch for, and a violation
# missed on a variant comes back as rc=0 -- billing PROPERTY_TOO_WEAK to the
# learner for the author's config. INVARIANT is the ownership one: a second
# invariant checked alongside the generated one decides the verdict without
# appearing in the report.

assert_matrix "a fragment carrying directives is refused" \
  "MATRIX_MALFORMED" 44 \
  --matrix "$PMATRIX" --reference "$FIX/constants-refused/Ledger.tla" \
  "$PPROPS/LedgerGood.tla"

assert_report "...and the refusal quotes the SYMMETRY line" \
  'SYMMETRY Perms' \
  --matrix "$PMATRIX" --reference "$FIX/constants-refused/Ledger.tla" \
  "$PPROPS/LedgerGood.tla"

assert_report "...and the INVARIANT line" \
  'INVARIANT SneakyInv' \
  --matrix "$PMATRIX" --reference "$FIX/constants-refused/Ledger.tla" \
  "$PPROPS/LedgerGood.tla"

# ---------------------------------------------------------------------------
echo
echo "== the artifacts the harness generates, read off disk =="
# ---------------------------------------------------------------------------

KEPT=$(mktemp -d -t tla_seeded_kept.XXXXXX)
rm -rf "$KEPT"
bash "$SEEDED" --keep "$KEPT" -q --matrix "$MATRIX" --alias Alias \
  "$PROPS/Good.tla" >/dev/null 2>&1
trap 'rm -rf "$KEPT"' EXIT

check() { if "$@"; then ok "$LBL"; else nope "$LBL"; fi; }

LBL="the generated .cfg carries the ALIAS line"
check grep -rqE '^[[:space:]]*ALIAS[[:space:]]+Alias' "$KEPT"

LBL="the generated .cfg names the learner's property as the INVARIANT"
check grep -rqE '^[[:space:]]*INVARIANT[[:space:]]+Inv' "$KEPT"

LBL="no .cfg was copied out of the matrix directory"
if [ -z "$(find "$KEPT" -name '*.cfg' ! -name 'run.cfg' -print -quit)" ]; then
  ok "$LBL"; else nope "$LBL"; fi

# NORMALISATION HAPPENS BEFORE THE DUMP. The trace on disk carries the alias
# record's field names and never the spec's own variables -- which is the only
# way to show the ordering, since a normalisation applied afterwards would
# leave the raw names in the dumped file.
TRACES=$(find "$KEPT" -name 'trace.json' -size +0 -print -quit 2>/dev/null)
LBL="a dumped counterexample exists to inspect"
if [ -n "$TRACES" ]; then ok "$LBL"; else nope "$LBL"; fi

if [ -n "$TRACES" ]; then
  LBL="the dumped trace carries the NORMALISED field names"
  check grep -q 'north' "$TRACES"

  LBL="the dumped trace carries no raw variable name — normalised BEFORE dumping"
  if grep -qE '"(ns|ew)"' "$TRACES"; then nope "$LBL"; else ok "$LBL"; fi

  LBL="the dumped trace still carries action names — the thing that IS diffed"
  check grep -q '"name"' "$TRACES"
fi

# ---------------------------------------------------------------------------
echo
echo "== structural: constraints no fixture can observe =="
# ---------------------------------------------------------------------------

# The bead requires the caveat in the CODE, not only in the plan. Without it
# the next reader takes a bootstrap for a validated instrument.
assert_file_present "the 10.9% single-mutation figure is in the file" '10\.9'
assert_file_present "the 39.3% inert-mutation figure is in the file"  '39\.3'
assert_file_present "the file calls itself a bootstrap"               '[Bb]ootstrap'

# The constants channel is discovered by filename and never named on the
# command line, so a reader who does not find it in the header has no way to
# learn it exists. Bead tla-40y.
assert_file_present "the header names the constants fragment by filename" \
  'constants\.cfg'

# THE DEFECT'S OWN SITE, as a structural row. `printf 'INVARIANT %s\n'` is the
# line bead tla-r2ih removed, and a fixture cannot see it come back in the one
# case TLC tolerates both keywords. The keyword has to be a variable.
assert_code_absent "the .cfg keyword is not hardcoded" \
  "printf 'INVARIANT"

# And it must be chosen by the obligation's shape rather than by a flag. A
# flag defaulting to the old behaviour reproduces the defect for every caller
# who does not know to pass it.
assert_code_present "the keyword comes from a shape classifier" \
  'tla_shape'
assert_code_absent "no flag selects the keyword" \
  '--(property-kind|temporal|liveness|invariant|keyword)\)'

# The classifier follows NAMES. `Live == Reaches2Again` has no temporal
# operator on its own line, and RelayGood.tla is written that way on purpose,
# so the closure is the thing that makes that row pass.
assert_code_present "the classifier walks the definition closure" \
  'tla_closure'

# rc=13 has to appear in the refutation test. Before tla-r2ih the only
# refutation code in the file was 12, and a matrix that knew the PROPERTY
# keyword and not the code reports every liveness mutant as uncaught.
assert_code_present "13 is a refutation code" \
  'CASE_RC" = "13"'

# Verdicts come from exit codes (§5.1). This script reads its own generated
# files and TLC's JSON trace dump, never TLC's console prose.
assert_code_absent "no TLC stdout phrases used as literals" \
  '(No error has been found|Invariant .* is violated|Temporal properties were violated|Deadlock reached|Finished in|unexpected exception)'

# Hazard swept under tla-kr9: a live pipe into an early-exiting consumer
# returns 141 under `set -o pipefail` when the consumer closes the pipe and the
# producer takes SIGPIPE, so a PRESENT pattern reports as ABSENT --
# intermittently, because it is a race. Capturing the producer first does NOT
# fix it; the fix is a here-string. Checked on both files, not just the one
# under test, because this suite is a shell file under harness/ too.
assert_no_live_pipe "seeded-bugs.sh: no live pipe into grep -q/-m or head" \
  "$SEEDED"
assert_no_live_pipe "selftest.sh: no live pipe into grep -q/-m or head" \
  "$FIX/selftest.sh"

# §5.1: every TLC run goes through the verdict channel.
assert_code_present "TLC is reached only through verdict.sh" 'verdict\.sh'
assert_code_absent  "no direct tlc invocation" '^[[:space:]]*tlc[[:space:]]'

# The comparison must never look at values. A comparator that read the state
# records would penalise the representational freedom §3.2 protects.
assert_code_present "the comparator reads action names" '\["name"\]|name'
assert_code_absent  "the comparator never reads a state record's fields" \
  'counterexample"\]\["state"\]\[[0-9]+\]\[1\]'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
