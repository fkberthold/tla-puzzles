#!/usr/bin/env bash
# seeded-bugs.sh — The seeded-bug matrix (V2-PLAN.md §5.5, bead tla-kl5.8).
#
# THE ONE THING THIS FILE EXISTS FOR
#
#   Every other check in the harness asks a submitted property the same
#   question: DOES IT HOLD? §5.2 grades it, §5.3 proves the state space it
#   held over was not empty, §5.4 proves a refinement was not discharged by
#   stuttering. `Inv == TRUE` answers yes to all of them. It holds. The state
#   space is healthy, an INVARIANT really is configured, every action fires,
#   and TLC exits 0 every single time.
#
#   The seeded-bug matrix asks the other question: DOES IT EVER SAY NO?
#
#       rc == 0  against the reference   AND   rc == 12 against the variant.
#
#   Both halves are load-bearing and neither is sufficient. Drop the rc==12
#   half and `Inv == TRUE` passes. Drop the rc==0 half and `Inv == FALSE`
#   passes, which is the same worthlessness with the sign flipped. This is the
#   ONLY mechanical defense against either.
#
# ============================================================================
# CAVEAT — READ THIS BEFORE YOU TRUST A NUMBER THIS SCRIPT PRODUCES
# ============================================================================
#
#   THIS IS A BOOTSTRAP, NOT A PROXY FOR LEARNER BEHAVIOUR. The variants it
#   grades against are mutants of OUR OWN reference spec, and mutants of a
#   correct spec are systematically unlike the mistakes people actually make.
#
#   Two measured figures say why:
#
#     ~10.9%  of real faulty student specs are ONE mutation away from correct.
#             Real mistakes are MULTI-STEP -- a wrong model, carried through
#             consistently -- not a single flipped operator. So ~89% of the
#             fault space this instrument is supposed to stand in for is not
#             reachable by the construction it uses.
#
#     ~39.3%  of single mutations are SEMANTICALLY INERT: the mutated spec has
#             the same behaviour as the original, so no property can tell them
#             apart. Roughly two of every five variants a mutation tool emits
#             are not bugs at all.
#
#   What follows from that, concretely, and what this script does about it:
#
#     - A submission that passes this matrix has been shown to catch THESE
#       bugs. Nothing more. It has NOT been shown to catch the bug a learner
#       would actually have written, and no count of variants caught is
#       evidence about that.
#
#     - An inert variant must never be reported as the learner's failure. It
#       is a defect in OUR variant set. The oracle is therefore run against
#       every variant BEFORE any grading happens, and a variant the oracle
#       itself cannot catch stops the matrix with VARIANT_INERT (42) --
#       attributed to the variant set, in a verdict that does not depend on
#       which submission was being graded.
#
#     - Do not report a pass rate off this file as though it measured
#       instruction. It measures the variant set.
#
#   Say all of that out loud wherever this component's output is surfaced. A
#   bootstrap mistaken for a validated instrument is worse than no instrument,
#   because it comes with a number attached.
#
# ============================================================================
#
# USAGE
#   harness/seeded-bugs.sh [OPTIONS] <property.tla>
#   harness/seeded-bugs.sh --trace-signature <trace.json>
#
# THE SHAPE OF A MATRIX DIRECTORY
#
#   <matrix>/reference/<Spec>.tla        the reference spec, plus any modules
#                                        it needs
#   <matrix>/oracle/<Oracle>.tla         the AUTHOR'S property; EXTENDS <Spec>
#   <matrix>/variants/<name>/<Spec>.tla  one seeded variant per directory
#
#   Every variant supplies the reference module UNDER THE REFERENCE'S OWN
#   MODULE NAME, and may supply any subset of the other modules; whatever it
#   does not supply is taken from reference/. That is what lets one property
#   module be checked against the reference and against every variant without
#   being rewritten: it says `EXTENDS <Spec>` once, and staging decides which
#   <Spec> that is.
#
#   The submitted property module EXTENDS the reference module and defines the
#   invariant operator (default `Inv`). It cannot forge anything: TLA+ makes
#   redefining an EXTENDS-inherited name a SANY error rather than a shadowing,
#   so a submission cannot substitute its own `Spec`, and the .cfg is
#   generated here and never read from the problem directory.
#
# OPTIONS
#       --matrix DIR       matrix root; fills in the three paths above
#       --reference FILE   reference module, overriding <matrix>/reference
#       --oracle FILE      oracle property module, overriding <matrix>/oracle
#       --variants DIR     directory of variant directories
#       --spec NAME        the spec operator                 (default: Spec)
#       --property NAME    the invariant operator, in BOTH the submission and
#                          the oracle                        (default: Inv)
#       --alias NAME       normalising ALIAS operator, defined by the SPEC
#       --strict-trace     make a divergent counterexample a failure
#   -t, --timeout SECS     wall-clock budget per TLC run     (default: 60)
#       --keep DIR         keep the staged directories, configs, logs, traces
#   -q, --quiet            print the verdict token only
#       --trace-signature FILE   print one trace's signature and exit
#   -h, --help             this text
#
# OUTPUT
#   stdout line 1: the verdict token
#   stdout line 2+: the matrix table and the remediation (suppressed by -q)
#   exit:          the code beside that token below
#
# VERDICT TABLE
#     0  BUGS_CAUGHT          rc==0 on the reference, rc==12 on every variant
#     2  USAGE                bad arguments
#    40  PROPERTY_TOO_WEAK    a variant got through -- `Inv == TRUE` lands here
#    41  PROPERTY_UNSOUND     the reference itself violates the submission
#    42  VARIANT_INERT        a variant the ORACLE cannot catch either. OUR
#                             bug, not the submission's
#    43  TRACE_DIVERGED       caught, but by a different behaviour than the
#                             oracle's (--strict-trace only)
#    44  MATRIX_MALFORMED     the matrix directory is not the shape above
#    45  ORACLE_UNSOUND       the reference violates the ORACLE; the matrix
#                             cannot certify anything
#    46  PROBE_INCONCLUSIVE   a run exited 12 and left no readable trace; a
#                             harness fault, and never a verdict about the
#                             submission
#     *  <verdict.sh token>   any other TLC outcome, passed through unchanged
#                             with verdict.sh's own token and raw exit status
#
#   The codes are deliberately disjoint from TLC's own (0/10/11/12/13/124/
#   150/151/255) and from the sibling components' (§5.3 uses 3-6, §5.4 uses
#   20-30), so a caller can never confuse one component's verdict with
#   another's.
#
#   ANYTHING THAT IS NOT 0 OR 12 IS PASSED THROUGH, not folded into a verdict
#   of this file's own. A submission whose module does not parse should be
#   told PARSE_ERROR at rc=150, not "inconclusive": the code that names the
#   failure is the actionable one, and re-labelling it would throw away the
#   only thing the caller could act on. §5.4 passes through for the same
#   reason. (§5.3 does fold, and rightly -- its runs are harness-generated
#   probes rather than runs of the submitted artifact.)
#
# THE ORDER OF THE PHASES IS THE POINT
#
#   Each phase adds exactly one dependency, and the instrument is checked
#   before the submission is:
#
#     1  oracle    vs reference   expect 0    -- is our instrument sound?
#     2  submission vs reference  expect 0    -- is the submission sound?
#                                                (reference + property only;
#                                                 no variant is involved)
#     3  oracle    vs each variant expect 12  -- is our variant SET sound?
#     4  submission vs each variant expect 12 -- the grading
#
#   Phase 3 before phase 4 is what keeps an inert mutant from being billed to
#   the learner. Reverse them and a submission graded against an inert variant
#   comes back PROPERTY_TOO_WEAK -- a wrong verdict, about the right rc, on
#   the wrong party. Given ~39.3% inert, that is not a corner case.
#
# WHAT THE TRACE COMPARISON COMPARES, AND WHAT IT REFUSES TO
#
#   A submission and the oracle can both exit 12 on the same variant and be
#   catching DIFFERENT bugs -- a variant broken twice over surfaces both
#   defects, and each property finds its own. So the two counterexamples are
#   compared.
#
#   COMPARED:  the ACTION-NAME SEQUENCE and the TRACE LENGTH. Both are stable
#              across representations: they are properties of the spec's own
#              action structure, which the matrix supplies, not of the
#              submission.
#
#   NEVER COMPARED:  CONCRETE VALUES. They vary with the learner's
#              representation -- "red"/"green" against 0/1 against a record --
#              and diffing them would fail a correct submission for choosing a
#              different encoding. That is precisely the representational
#              freedom §3.2 exists to protect. The comparator reads the
#              `name` field of each action and the LENGTH of the state list.
#              It never opens a state record.
#
#   Normalisation happens BEFORE the dump, via `ALIAS` in the generated .cfg,
#   because -dumpTrace writes whatever the alias says the state is and there
#   is no second chance afterwards. The alias operator is defined by the SPEC,
#   not by the submission: the oracle run has to normalise identically or the
#   comparison means nothing, and a submission's module is not in scope there.
#
#   AND IT IS NOT A GATE BY DEFAULT. The rc obligations are correctness
#   invariants and are always fatal. Trace agreement is a JUDGEMENT about
#   which bug was caught, and a submission whose property is legitimately
#   STRONGER than the oracle's will fire somewhere else and still be right.
#   Failing it by default would be the value-diffing mistake by another route.
#   It is computed on every run, printed on every run, and promoted to fatal
#   only by --strict-trace.
#
# NOT IMPLEMENTED, DELIBERATELY: no --constants fragment. §5.4 has one because
# its abstract spec is parameterised; nothing here is, and an untested code
# path in a grading component is worse than an absent feature. Add it with a
# fixture when a problem needs it.
#
# VERDICTS COME FROM EXIT CODES. Every TLC run here goes through
# harness/verdict.sh (§5.1). Nothing in this file reads, matches, or reasons
# about TLC's console output. The one thing it parses is TLC's JSON trace
# dump, which is data.

set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERDICT_SH="$HERE/verdict.sh"

MATRIX=""
REFERENCE=""
ORACLE=""
VARIANTS=""
SPEC="Spec"
PROPERTY="Inv"
ALIAS_OP=""
STRICT_TRACE=0
TIMEOUT=60
KEEP=""
QUIET=0
SIGNATURE_ONLY=""
PROP_MODULE=""

usage() {
  cat <<'USAGE'
usage: harness/seeded-bugs.sh [OPTIONS] <property.tla>
       harness/seeded-bugs.sh --trace-signature <trace.json>

      --matrix DIR       matrix root: reference/, oracle/, variants/
      --reference FILE   reference module, overriding <matrix>/reference
      --oracle FILE      oracle property module, overriding <matrix>/oracle
      --variants DIR     directory of variant directories
      --spec NAME        the spec operator                 (default: Spec)
      --property NAME    the invariant operator            (default: Inv)
      --alias NAME       normalising ALIAS operator, defined by the SPEC
      --strict-trace     make a divergent counterexample a failure
  -t, --timeout SECS     wall-clock budget per TLC run     (default: 60)
      --keep DIR         keep staged directories, configs, logs, traces
  -q, --quiet            verdict token only
      --trace-signature FILE   print one trace's signature and exit
  -h, --help             this text

Prints one verdict token; exits with that token's code.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --matrix)          MATRIX="${2:-}"; shift 2 ;;
    --reference)       REFERENCE="${2:-}"; shift 2 ;;
    --oracle)          ORACLE="${2:-}"; shift 2 ;;
    --variants)        VARIANTS="${2:-}"; shift 2 ;;
    --spec)            SPEC="${2:-}"; shift 2 ;;
    --property)        PROPERTY="${2:-}"; shift 2 ;;
    --alias)           ALIAS_OP="${2:-}"; shift 2 ;;
    --strict-trace)    STRICT_TRACE=1; shift ;;
    -t|--timeout)      TIMEOUT="${2:-}"; shift 2 ;;
    --keep)            KEEP="${2:-}"; shift 2 ;;
    -q|--quiet)        QUIET=1; shift ;;
    --trace-signature) SIGNATURE_ONLY="${2:-}"; shift 2 ;;
    -h|--help)         usage; exit 0 ;;
    -*)                echo "seeded-bugs.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$PROP_MODULE" ]; then
        echo "seeded-bugs.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      PROP_MODULE="$1"; shift ;;
  esac
done

# Needed to read the JSON trace dumps. Checked up front so a missing
# interpreter is a loud startup error rather than a wrong verdict several TLC
# runs later -- the same guard refinement.sh carries, for the same reason.
command -v python3 >/dev/null 2>&1 || {
  echo "seeded-bugs.sh: python3 is required to read counterexample traces" >&2
  exit 2
}

# ---------------------------------------------------------------------------
# THE TRACE SIGNATURE.
#
# The action-name sequence and the trace length, and NOTHING ELSE. The state
# records are counted, never opened: a submission that encodes its lights as
# 0 and 1 where the reference used "red" and "green" describes the same
# behaviour, and the whole reason this is a signature rather than a diff is so
# that it says so.
#
# An unreadable or absent trace is NO_TRACE rather than an error. Callers
# reach this only for runs that already exited 12, so a missing trace is a
# harness fault worth reporting, not a verdict about the submission.
# ---------------------------------------------------------------------------
trace_signature() {
  python3 - "$1" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as fh:
        ce = json.load(fh)["counterexample"]
except Exception:
    print("NO_TRACE")
    sys.exit(0)
steps = ce.get("action", [])
names = []
for step in steps:
    try:
        names.append(str(step[1]["name"]))
    except Exception:
        names.append("?")
print("%d steps: %s" % (len(ce.get("state", [])), " -> ".join(names)))
PY
}

if [ -n "$SIGNATURE_ONLY" ]; then
  trace_signature "$SIGNATURE_ONLY"
  exit 0
fi

[ -n "$PROP_MODULE" ] || { echo "seeded-bugs.sh: no property module given" >&2; usage >&2; exit 2; }
[ -f "$VERDICT_SH" ] || { echo "seeded-bugs.sh: missing $VERDICT_SH" >&2; exit 2; }

case "$TIMEOUT" in
  ''|*[!0-9]*) echo "seeded-bugs.sh: --timeout must be a positive integer" >&2; exit 2 ;;
esac

REPORT=""
say() { REPORT="${REPORT}$1
"; }

finish() {   # finish <token> <rc>
  echo "$1"
  if [ "$QUIET" = "0" ] && [ -n "$REPORT" ]; then
    printf '%s' "$REPORT"
  fi
  exit "$2"
}

# ---------------------------------------------------------------------------
# RESOLVING THE MATRIX.
#
# --matrix fills in the three paths by convention; each may be overridden
# individually, which is what lets one reference and one oracle serve several
# variant sets. Anything that does not resolve is MATRIX_MALFORMED rather than
# a shell error, because a matrix that is quietly the wrong shape produces
# rc==0 rows that read exactly like "the submission failed to catch this bug".
# ---------------------------------------------------------------------------
malformed() {
  say "The matrix directory is not the shape seeded-bugs.sh expects."
  say ""
  say "$1"
  say ""
  say "Expected layout:"
  say "  <matrix>/reference/<Spec>.tla"
  say "  <matrix>/oracle/<Oracle>.tla"
  say "  <matrix>/variants/<name>/<Spec>.tla"
  finish "MATRIX_MALFORMED" 44
}

# sole_tla <dir> -> echoes the single .tla in <dir>, or nothing
sole_tla() {
  local d="$1" n
  [ -d "$d" ] || return 0
  n=$(find "$d" -maxdepth 1 -name '*.tla' -type f | wc -l)
  [ "$n" = "1" ] || return 0
  find "$d" -maxdepth 1 -name '*.tla' -type f
}

if [ -z "$REFERENCE" ]; then
  [ -n "$MATRIX" ] || malformed "No --reference and no --matrix."
  REFERENCE=$(sole_tla "$MATRIX/reference")
  [ -n "$REFERENCE" ] || malformed "$MATRIX/reference/ must hold exactly one .tla, or pass --reference."
fi
[ -f "$REFERENCE" ] || malformed "No such reference module: $REFERENCE"

if [ -z "$ORACLE" ]; then
  [ -n "$MATRIX" ] || malformed "No --oracle and no --matrix."
  ORACLE=$(sole_tla "$MATRIX/oracle")
  [ -n "$ORACLE" ] || malformed "$MATRIX/oracle/ must hold exactly one .tla, or pass --oracle."
fi
[ -f "$ORACLE" ] || malformed "No such oracle module: $ORACLE"

if [ -z "$VARIANTS" ]; then
  [ -n "$MATRIX" ] || malformed "No --variants and no --matrix."
  VARIANTS="$MATRIX/variants"
fi
[ -d "$VARIANTS" ] || malformed "No such variants directory: $VARIANTS"

REFERENCE_DIR=$(cd -- "$(dirname -- "$REFERENCE")" && pwd)
REFERENCE_FILE=$(basename -- "$REFERENCE")

mapfile -t VARIANT_DIRS < <(find "$VARIANTS" -mindepth 1 -maxdepth 1 -type d | sort)
[ "${#VARIANT_DIRS[@]}" -gt 0 ] || malformed "$VARIANTS/ holds no variant directories."

# Every variant must supply the reference module under the reference's own
# module name. One that does not would stage the REFERENCE and exit 0, which
# is indistinguishable from a submission that missed the bug.
for vd in "${VARIANT_DIRS[@]}"; do
  [ -f "$vd/$REFERENCE_FILE" ] || \
    malformed "Variant $(basename -- "$vd")/ has no $REFERENCE_FILE. Every variant supplies the module it mutates, under the reference's own module name."
done

# ---------------------------------------------------------------------------
# STAGING. The harness owns the world each run sees: reference modules copied
# out, the variant's modules copied over them, the submission's module copied
# in, and a GENERATED .cfg. No .cfg is ever read from the matrix directory --
# a subject that writes its own oracle configuration can weaken its own
# grading, which is the hole §5.4 documents in TLAiBench.
# ---------------------------------------------------------------------------
if [ -n "$KEEP" ]; then
  WORK="$KEEP"; mkdir -p "$WORK"; CLEAN=0
else
  WORK=$(mktemp -d -t tla_seeded.XXXXXX); CLEAN=1
fi
cleanup() { [ "$CLEAN" = "1" ] && rm -rf "$WORK"; }
trap cleanup EXIT

CASE_RC=0
CASE_TOKEN=""
CASE_TRACE=""

# run_case <tag> <variant-dir-or-empty> <property-module>
#
# No existence check on the property module. "That file is not there" is a
# verdict TLC issues (150), and short-circuiting it here would substitute this
# script's opinion for the channel the harness is built on -- the same
# discipline verdict.sh, vacuity.sh and refinement.sh each document. Hence the
# silenced cp: it is expected to fail in that case.
run_case() {
  local tag="$1" vdir="$2" prop="$3"
  local stage="$WORK/$tag"
  rm -rf "$stage"
  mkdir -p "$stage"

  cp "$REFERENCE_DIR"/*.tla "$stage"/ 2>/dev/null
  if [ -n "$vdir" ]; then
    cp "$vdir"/*.tla "$stage"/ 2>/dev/null
  fi
  cp "$prop" "$stage"/ 2>/dev/null

  local cfg="$stage/run.cfg"
  {
    printf 'SPECIFICATION %s\n' "$SPEC"
    printf 'INVARIANT %s\n' "$PROPERTY"
    [ -n "$ALIAS_OP" ] && printf 'ALIAS %s\n' "$ALIAS_OP"
  } > "$cfg"

  CASE_TRACE="$stage/trace.json"
  # The root module goes to TLC as an ABSOLUTE path, so auxiliary modules
  # resolve out of the staging directory from any CWD -- the resolution rule
  # vacuity.sh measured and documents.
  CASE_TOKEN=$(bash "$VERDICT_SH" --config "$cfg" --timeout "$TIMEOUT" \
    --trace "$CASE_TRACE" --log "$stage/tlc.log" --scratch "$stage/scratch" \
    "$stage/$(basename -- "$prop")" 2>/dev/null)
  CASE_RC=$?
}

# Any TLC outcome that is neither 0 nor 12 goes back to the caller as
# verdict.sh reported it. The prose says WHICH run produced it, because that
# is the part the exit code cannot carry.
passthrough() {   # passthrough <what>
  say "The matrix stopped early, so nothing here is a verdict about the"
  say "submitted property."
  say ""
  say "$1 exited $CASE_TOKEN (rc=$CASE_RC). See harness/verdict.sh for what"
  say "that code means."
  finish "$CASE_TOKEN" "$CASE_RC"
}

# A violation with no readable counterexample. Not a verdict about anything
# submitted -- verdict.sh was asked for a trace and did not leave one, which
# is a fault in the harness.
inconclusive() {   # inconclusive <what>
  say "A run was violated but left no readable counterexample, so the"
  say "counterexample comparison could not be made."
  say ""
  say "$1 exited rc=12 and $CASE_TRACE is missing or unreadable. This is a"
  say "harness fault, not a verdict about the submitted property."
  finish "PROBE_INCONCLUSIVE" 46
}

ORACLE_NAME=$(basename -- "$ORACLE" .tla)
PROP_NAME=$(basename -- "$PROP_MODULE" .tla)

# ===========================================================================
# PHASE 1 -- is OUR INSTRUMENT sound? The oracle must hold of the reference.
# ===========================================================================
run_case "oracle-reference" "" "$ORACLE"
case "$CASE_RC" in
  0) ;;
  12)
    say "The reference specification violates the matrix's OWN oracle."
    say ""
    say "$ORACLE_NAME!$PROPERTY is what every variant is certified against, so"
    say "an oracle the correct spec already breaks would 'catch' every variant"
    say "for the wrong reason and certify nothing at all."
    say ""
    say "NOTHING HERE IS A VERDICT ABOUT THE SUBMISSION. Fix the oracle or the"
    say "reference, then re-run."
    finish "ORACLE_UNSOUND" 45 ;;
  *) passthrough "The oracle against the reference" ;;
esac

# ===========================================================================
# PHASE 2 -- is the SUBMISSION sound? It must hold of the reference.
#
# No variant is involved, so this diagnosis stands on its own and is reached
# before the variant set is touched.
# ===========================================================================
run_case "property-reference" "" "$PROP_MODULE"
case "$CASE_RC" in
  0) ;;
  12)
    say "Your property is violated by the reference solution itself."
    say ""
    say "TLC found a behaviour of the correct specification in which"
    say "$PROP_NAME!$PROPERTY is false. A property that the intended answer"
    say "breaks is not a strong property, it is a wrong one -- and 'catches"
    say "every seeded bug' is trivial to satisfy that way, which is why this"
    say "half of the matrix exists."
    say ""
    say "The counterexample is a run of the reference the property should have"
    say "allowed. Read it and decide which of the two you meant."
    finish "PROPERTY_UNSOUND" 41 ;;
  *) passthrough "Your property against the reference" ;;
esac

# ===========================================================================
# PHASE 3 -- is our VARIANT SET sound? The oracle must catch every variant.
#
# BEFORE any grading. A variant the oracle cannot catch is one the harness has
# no witness for, and with ~39.3% of single mutations semantically inert that
# is the common case rather than the exotic one. Charging it to the learner
# would be charging them for our defect.
# ===========================================================================
declare -a LIVE_DIRS=()
declare -a LIVE_NAMES=()
declare -a LIVE_ORACLE_SIG=()
declare -a INERT_NAMES=()

for vd in "${VARIANT_DIRS[@]}"; do
  vname=$(basename -- "$vd")
  run_case "oracle-$vname" "$vd" "$ORACLE"
  case "$CASE_RC" in
    12)
      osig=$(trace_signature "$CASE_TRACE")
      [ "$osig" = "NO_TRACE" ] && inconclusive "The oracle against variant $vname"
      LIVE_DIRS+=("$vd")
      LIVE_NAMES+=("$vname")
      LIVE_ORACLE_SIG+=("$osig")
      ;;
    0)
      INERT_NAMES+=("$vname")
      ;;
    *) passthrough "The oracle against variant $vname" ;;
  esac
done

if [ "${#INERT_NAMES[@]}" -gt 0 ]; then
  say "A seeded variant is SEMANTICALLY INERT. The defect is in OUR variant set,"
  say "not in the submitted property."
  say ""
  for n in "${INERT_NAMES[@]}"; do
    say "  variant $n was not caught by the oracle either."
  done
  say ""
  say "The oracle is the strongest witness this matrix has. A variant it"
  say "cannot distinguish from the reference is one no property can"
  say "distinguish from the reference, because there is nothing there to"
  say "distinguish: the mutation left the behaviour unchanged."
  say ""
  say "~39.3% of single mutations are inert, so expect this. Repair or drop"
  say "the variant, then re-run. Until then the matrix cannot grade, and this"
  say "verdict would be the same for any submission at all."
  finish "VARIANT_INERT" 42
fi

# ===========================================================================
# PHASE 4 -- THE GRADING. The submission must catch every live variant.
#
# `Inv == TRUE` lands here: it exits 0 where 12 was required, on the first
# variant it meets.
# ===========================================================================
declare -a MISSED=()
declare -a DIVERGED=()
ROWS=""

i=0
while [ "$i" -lt "${#LIVE_DIRS[@]}" ]; do
  vd="${LIVE_DIRS[$i]}"
  vname="${LIVE_NAMES[$i]}"
  osig="${LIVE_ORACLE_SIG[$i]}"

  run_case "property-$vname" "$vd" "$PROP_MODULE"
  case "$CASE_RC" in
    12)
      psig=$(trace_signature "$CASE_TRACE")
      [ "$psig" = "NO_TRACE" ] && inconclusive "Your property against variant $vname"
      if [ "$psig" = "$osig" ]; then
        ROWS="${ROWS}  $vname: caught (rc=12), same counterexample as the oracle
"
      else
        DIVERGED+=("$vname")
        ROWS="${ROWS}  $vname: caught (rc=12), DIFFERENT counterexample
      oracle: $osig
      yours:  $psig
"
      fi
      ;;
    0)
      MISSED+=("$vname")
      ROWS="${ROWS}  $vname: MISSED (rc=0, wanted rc=12)
"
      ;;
    *) passthrough "Your property against variant $vname" ;;
  esac
  i=$((i + 1))
done

if [ "${#MISSED[@]}" -gt 0 ]; then
  say "Your property does not catch every seeded bug."
  say ""
  say "Each variant below is the reference specification with one definition"
  say "broken on purpose. Your property held anyway -- TLC exited 0 where 12"
  say "was required -- so it would have said the broken spec was fine."
  say ""
  for n in "${MISSED[@]}"; do
    say "  $n: not caught."
  done
  say ""
  say "The full matrix:"
  say "$ROWS"
  say "This is the check \`Inv == TRUE\` fails. Every other check in the"
  say "harness asks whether your property HOLDS; this one asks whether it ever"
  say "says no. Strengthen it until each variant above is rejected -- without"
  say "breaking the reference, which is the other half of the obligation."
  finish "PROPERTY_TOO_WEAK" 40
fi

# ===========================================================================
# PHASE 5 -- WHICH bug was caught. Reported always; fatal only on request.
# ===========================================================================
if [ "${#DIVERGED[@]}" -gt 0 ]; then
  say "TRACE: your property caught every variant, but on some of them it"
  say "caught a DIFFERENT behaviour than the oracle did."
  say ""
  say "$ROWS"
  say "Only the action-name sequence and the trace length are compared;"
  say "concrete values never are, so this is not about how you represented"
  say "anything. A variant can be broken in more than one way, and a property"
  say "stronger than the oracle can legitimately fire somewhere else -- which"
  say "is why this is reported rather than failed by default."
  if [ "$STRICT_TRACE" = "1" ]; then
    say ""
    say "--strict-trace was given, so it is a failure here."
    finish "TRACE_DIVERGED" 43
  fi
  say ""
  say "Reference: rc=0. Every variant: rc=12."
  finish "BUGS_CAUGHT" 0
fi

say "Your property holds of the reference (rc=0) and is violated by every"
say "seeded variant (rc=12), on the same counterexample the oracle found."
say ""
say "$ROWS"
say "WHAT THIS DOES NOT SAY: the variants above are mutants of the reference,"
say "and mutants of a correct spec are not the mistakes people make -- only"
say "~10.9% of real faulty specs are one mutation from correct. This is a"
say "bootstrap. It is evidence your property catches THESE bugs, and it is"
say "not evidence about the bug you would have written."
finish "BUGS_CAUGHT" 0
