#!/usr/bin/env bash
# grade.sh — The v2 grading engine (V2-PLAN.md §5.2, bead tla-kl5.5).
#
# Grades a submission PSI against a reference PHI by CONJUNCT-WISE TWO-SIDED
# IMPLICATION plus NON-VACUITY, and reports the result as a verdict object.
#
#     1.  PSI => phi_i   for each REFERENCE conjunct   -> not too weak
#     2.  PHI => psi_j   for each SUBMISSION conjunct  -> not too strong
#     3.  PSI => FALSE   must FAIL                     -> not vacuous
#
# Obligation 1 is the Adequacy suite and is where per-conjunct partial credit
# comes from. Obligation 2 plus the landmark check is the Relational suite.
# Obligation 3 is the NonVacuity suite.
#
# ---------------------------------------------------------------------------
# WHAT THIS DELIBERATELY IS NOT: REFERENCE COMPARISON. (V2-PLAN.md §3.5)
# ---------------------------------------------------------------------------
#
# "Compare the submission to the reference" is the intuitive design, it will
# feel like the simple solution every time this file is touched, and it is
# invalid. Over ~96,000 Alloy submissions the instructor's oracle ranks #1
# among correct forms for only 33% of exercises and is ABSENT ENTIRELY in
# 18.6%. The reference is one correct spec, not the shape of correctness. So
# nothing below compares state counts, diffs text, or treats the reference's
# structure as authoritative -- the reference is used only as the source of
# the obligations phi_i and as the model that obligation 2 is checked against.
#
# Third-party corroboration, and the reason this is written down at the top of
# the file instead of in a drawer: TLAiBench, the only public TLA+ benchmark
# that grades against a gold reference, shipped a vacuity guard whose
# `Gold!Stats` postcondition demanded the submission's state space equal the
# reference's NUMERICALLY -- `generated = 97`, `distinct = 16`, exactly the
# gold spec's own figures -- and relaxed it in the field within hours, commit
# ba95443 "Validation: Relax state-space statistics". The benchmark author
# arrived at §3.5 empirically and in public.
#
# TLAiBench's whole-spec refinement check is also STRUCTURALLY BLIND TO
# OVER-CONSTRAINT, which is the failure this file exists to catch: an
# over-constrained spec still refines gold, and the maximally over-constrained
# spec -- an unsatisfiable Init -- refines EVERYTHING (verified rc=0 on both
# the plain check and `Gold!Refinement`). The `vacuous` fixture is that spec,
# and the Relational suite is the answer to it.
#
# ---------------------------------------------------------------------------
# OVER-CONSTRAINT AND UNDER-CONSTRAINT ARE REPORTED INDEPENDENTLY, AND BOTH
# ARE ALLOWED.
# ---------------------------------------------------------------------------
#
# 23.6% of wrong models are both at once, so a design that treats them as
# exclusive misgrades a quarter of the failures. `under_constrained` and
# `over_constrained` are separate booleans, each suite is scored on its own,
# and one witness of each kind is emitted. The `both-at-once` fixture pins it.
#
# ---------------------------------------------------------------------------
# THE OUTPUT IS A VERDICT OBJECT. NEVER A DIFF, NEVER REFERENCE TEXT.
# ---------------------------------------------------------------------------
#
# A grader that says "you are missing conjunct 3 of the reference" leaks the
# decomposition (§6b.1, §6b.2), and the Stage-4 isolation boundary only works
# if the leak is absent HERE -- the tutor directory cannot un-leak it later.
#
# So the two sides are treated asymmetrically, on purpose:
#
#   REFERENCE obligations are reported under an opaque digest, `R-xxxxxx` for
#     a conjunct and `L-xxxxxx` for a landmark, salted with the problem id.
#     The learner gets a stable handle they can track across attempts and no
#     text at all.
#
#   SUBMISSION obligations are reported VERBATIM, by name and by source line.
#     It is the learner's own code; quoting it back leaks nothing.
#
# What IS disclosed by design is the CARDINALITY of the reference
# decomposition -- "2 of 3 met" says there are three. That is what per-conjunct
# partial credit means; there is no version of §5.2 that hides it. The content
# is what is protected, and the leak gate at the bottom of this file enforces
# it as a whitelist: a string may leave here only if it is fixed schema
# vocabulary, an opaque digest, caller-supplied, or occurs verbatim in the
# submission's own files. Anything else and the object is never printed.
#
# ---------------------------------------------------------------------------
# FEEDBACK IS ERROR LOCATION ONLY. (V2-PLAN.md §3.7)
# ---------------------------------------------------------------------------
#
# The only RCT on the question: location hints 9.12 tasks against 5.67 for
# control; counterexample hints STATISTICALLY INDISTINGUISHABLE FROM NO HINT;
# natural-language description hints BELOW control, and the most demoralizing
# arm. Nothing improved retention.
#
# The counterexample trace is therefore read for ONE thing -- the module and
# line of the action that reached the violating state -- and its state values
# are never carried out. Prettifying that trace is not an improvement waiting
# to be made here. It is the arm that measured as worthless.
#
# ---------------------------------------------------------------------------
# THE PROBLEM PACKAGE
# ---------------------------------------------------------------------------
#
#   <reference-dir>/
#     *Ref.tla         PHI. Defines Spec and Observe.
#     *RefObl.tla      variable-free. Req_*(o) are the conjuncts phi_i;
#                      Landmark_*(o) are observations PHI reaches.
#     constants.cfg    optional, appended to every generated .cfg.
#
#   <submission-dir>/
#     *.tla            PSI. Defines Spec and Observe.
#     *Obl.tla         variable-free. Req_*(o) are the conjuncts psi_j.
#                      Optional: a submission may state no requirements, and
#                      then the Relational suite rests on landmarks alone.
#
# BOTH OBLIGATION MODULES ARE VARIABLE-FREE, and that is the load-bearing
# design choice, not a style preference. Representation is the learner's to
# choose (§3.2), so PHI's variables and PSI's variables have nothing to do
# with each other and neither module's predicates can be evaluated over the
# other's state. Phrasing every obligation over the OBSERVATION record (§3.3)
# is what makes a cross-check possible at all: a variable-free module can be
# EXTENDed beside either spec.
#
# Obligation operators must begin at column 1, which is how they are found.
# One inside a comment would be picked up, referenced by a generated judge
# module, and fail to parse -- loudly, as a harness error, never as a grade.
#
# ---------------------------------------------------------------------------
# MECHANISM
# ---------------------------------------------------------------------------
#
# Every obligation becomes one model-checking run over a GENERATED JUDGE
# module, and every run goes through harness/verdict.sh, so the §5.1 exit-code
# table lives in exactly one place and nothing here ever reads TLC's console
# output. This file does not even ask verdict.sh to keep it.
#
#   Adequacy   PSI => phi_i     judge EXTENDS <submission spec>, <ref obl>
#                               SPECIFICATION Spec / INVARIANT phi_i(Observe)
#                               rc=0 met, rc=12 UNMET (too weak)
#
#   Relational PHI => psi_j     judge EXTENDS <ref spec>, <submission obl>
#                               SPECIFICATION Spec / INVARIANT psi_j(Observe)
#                               rc=0 met, rc=12 UNMET (too strong)
#
#              landmarks        judge EXTENDS <submission spec>, <ref obl>
#                               INVARIANT ~Landmark_k(Observe), and the run
#                               must be VIOLATED: rc=12 met, rc=0 UNMET.
#                               Checking reachability by refutation is the
#                               §5.5 idiom, and it is what catches
#                               over-constraint BY OMISSION -- a submission
#                               that just leaves a transition out states no
#                               psi_j for obligation 2 to refute.
#
#   NonVacuity PSI => FALSE     judge EXTENDS both submission modules
#                               INVARIANT FALSE, and it must be VIOLATED:
#                               rc=12 non-vacuous, rc=0 VACUOUS.
#
# The NonVacuity run goes FIRST and doubles as the parse gate. It is the only
# run whose judge extends nothing but the submission, so a parse or config
# failure there is unambiguously the submission's fault and is reported as
# INVALID. After it has passed, the same failure on a reference-driven run can
# only be a harness fault, and is reported as one.
#
# Every run also carries `-postCondition Gate!InvariantConfigured`. The
# generated .cfg files are this script's own output, and a .cfg keyword with a
# missing operand is not an error -- TLC exits 0 having checked no invariant
# at all (§5.3). Without the guard, a bug in the generator below would grade
# every submission a perfect pass. With it, that bug is rc=10 and a harness
# error. Gate.tla is harness-owned and read-only here.
#
# The NonVacuity threshold gate, `Gate!NonVacuous` with a per-problem
# `TLCGet("distinct") >= N`, belongs to §5.3 and bead tla-kl5.6. This file
# uses the threshold-free refutation form, which needs no per-problem number.
#
# ---------------------------------------------------------------------------
# USAGE
#   harness/grade.sh --reference DIR --submission DIR [OPTIONS]
#
# OPTIONS
#   -r, --reference DIR    the reference package
#   -s, --submission DIR   the submission package
#   -p, --problem-id ID    label for the verdict object (default: reference
#                          directory's parent name) and digest salt
#   -t, --timeout SECS     per-run wall-clock budget (default: 60)
#       --scratch DIR      keep generated judges and traces here
#       --selftest         run the fixture-driven executable spec
#   -h, --help             this text
#
# OUTPUT
#   stdout: the verdict object, JSON, one object -- and NOTHING otherwise
#   stderr: diagnostics for humans
#   exit:   0 PASS           all three suites pass
#           1 FAIL           a graded failure
#           2 USAGE          bad arguments or a malformed problem package
#           3 INVALID        the submission does not parse, or times out
#           4 HARNESS_ERROR  a guard fired or a run gave an unexpected verdict
#           5 LEAK_GUARD     the object would have leaked; nothing was printed

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
VERDICT="$REPO_ROOT/harness/verdict.sh"
GATE="$REPO_ROOT/harness/Gate.tla"

REFDIR=""
SUBDIR=""
PROBLEM_ID=""
TIMEOUT=60
SCRATCH=""

usage() {
  cat <<'USAGE'
usage: harness/grade.sh --reference DIR --submission DIR [OPTIONS]

  -r, --reference DIR    the reference package  (*Ref.tla + *RefObl.tla)
  -s, --submission DIR   the submission package (*.tla + optional *Obl.tla)
  -p, --problem-id ID    label for the verdict object and digest salt
  -t, --timeout SECS     per-run wall-clock budget (default: 60)
      --scratch DIR      keep generated judge modules and traces here
      --selftest         run the fixture-driven executable spec
  -h, --help             this text

Prints one verdict object on stdout. 0 pass, 1 fail, 2 usage, 3 invalid
submission, 4 harness error, 5 leak gate tripped.
USAGE
}

die_usage() { echo "grade.sh: $1" >&2; usage >&2; exit 2; }
die_harness() { echo "grade.sh: HARNESS ERROR: $1" >&2; exit 4; }

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--reference)  REFDIR="${2:-}"; shift 2 ;;
    -s|--submission) SUBDIR="${2:-}"; shift 2 ;;
    -p|--problem-id) PROBLEM_ID="${2:-}"; shift 2 ;;
    -t|--timeout)    TIMEOUT="${2:-}"; shift 2 ;;
    --scratch)       SCRATCH="${2:-}"; shift 2 ;;
    --selftest)      exec "$REPO_ROOT/harness/fixtures/grade/selftest.sh" ;;
    -h|--help)       usage; exit 0 ;;
    *)               die_usage "unknown argument: $1" ;;
  esac
done

[ -n "$REFDIR" ] || die_usage "no --reference given"
[ -n "$SUBDIR" ] || die_usage "no --submission given"
[ -d "$REFDIR" ] || die_usage "--reference is not a directory: $REFDIR"
[ -d "$SUBDIR" ] || die_usage "--submission is not a directory: $SUBDIR"
[ -f "$VERDICT" ] || die_harness "missing the verdict channel: $VERDICT"
[ -f "$GATE" ] || die_harness "missing the postcondition guards: $GATE"

SUB_LABEL=$(basename "$SUBDIR")
[ -n "$PROBLEM_ID" ] || PROBLEM_ID=$(basename "$(dirname "$(dirname "$REFDIR/x")")")

# ---------------------------------------------------------------------------
# Discover the package. Names are matched by suffix, so a problem is free to
# call itself anything as long as the four roles are distinguishable.
# ---------------------------------------------------------------------------
only_one() {
  local role="$1"; shift
  if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    die_usage "expected exactly one $role, found: $*"
  fi
  printf '%s' "$1"
}

shopt -s nullglob
ref_spec_glob=("$REFDIR"/*Ref.tla)
ref_obl_glob=("$REFDIR"/*RefObl.tla)
sub_obl_glob=("$SUBDIR"/*Obl.tla)
sub_all_glob=("$SUBDIR"/*.tla)
shopt -u nullglob

REF_SPEC=$(only_one "reference spec (*Ref.tla)" "${ref_spec_glob[@]:-}")
REF_OBL=$(only_one "reference obligations module (*RefObl.tla)" "${ref_obl_glob[@]:-}")

SUB_SPEC=""
for f in "${sub_all_glob[@]:-}"; do
  case "$f" in
    *Obl.tla) ;;
    *) [ -n "$SUB_SPEC" ] && die_usage "more than one submission spec module in $SUBDIR"
       SUB_SPEC="$f" ;;
  esac
done
[ -n "$SUB_SPEC" ] || die_usage "no submission spec module (a *.tla that is not *Obl.tla) in $SUBDIR"

SUB_OBL=""
if [ "${#sub_obl_glob[@]}" -gt 1 ]; then
  die_usage "more than one submission obligations module in $SUBDIR"
elif [ "${#sub_obl_glob[@]}" -eq 1 ]; then
  SUB_OBL="${sub_obl_glob[0]}"
fi

modname() { basename "$1" .tla; }
M_REF_SPEC=$(modname "$REF_SPEC")
M_REF_OBL=$(modname "$REF_OBL")
M_SUB_SPEC=$(modname "$SUB_SPEC")
M_SUB_OBL=""
[ -n "$SUB_OBL" ] && M_SUB_OBL=$(modname "$SUB_OBL")

if [ "$M_REF_SPEC" = "$M_SUB_SPEC" ] || [ "$M_REF_OBL" = "$M_SUB_OBL" ]; then
  die_usage "reference and submission module names collide; a judge module cannot EXTEND both"
fi

# ---------------------------------------------------------------------------
# Stage. Everything lands flat in one directory so SANY resolves EXTENDS
# without a search path, and the submission's own directory stays pristine.
# ---------------------------------------------------------------------------
CLEAN_SCRATCH=0
if [ -z "$SCRATCH" ]; then
  SCRATCH=$(mktemp -d -t tla_grade.XXXXXX)
  CLEAN_SCRATCH=1
else
  mkdir -p "$SCRATCH"
fi
cleanup() { [ "$CLEAN_SCRATCH" = "1" ] && rm -rf "$SCRATCH"; }
trap cleanup EXIT

cp "$REF_SPEC" "$REF_OBL" "$SUB_SPEC" "$GATE" "$SCRATCH/"
[ -n "$SUB_OBL" ] && cp "$SUB_OBL" "$SCRATCH/"

CONST_FRAG=""
[ -f "$REFDIR/constants.cfg" ] && CONST_FRAG="$REFDIR/constants.cfg"

# ---------------------------------------------------------------------------
# Obligation discovery. Column-1 operator definitions, by prefix.
# ---------------------------------------------------------------------------
ops_named() {  # $1 = file, $2 = prefix
  [ -f "$1" ] || return 0
  grep -oE "^$2[A-Za-z0-9_]*\(" "$1" | sed 's/($//;s/(//' | sort -u
}

mapfile -t REF_CONJUNCTS < <(ops_named "$REF_OBL" "Req_")
mapfile -t REF_LANDMARKS < <(ops_named "$REF_OBL" "Landmark_")
mapfile -t SUB_CONJUNCTS < <(ops_named "$SUB_OBL" "Req_")

[ "${#REF_CONJUNCTS[@]}" -gt 0 ] || \
  die_usage "the reference obligations module declares no Req_* conjunct: $REF_OBL"

# Opaque handle for a reference-side obligation. Salted with the problem id so
# the same operator name in two problems does not produce the same id, which
# would let a learner correlate decompositions across problems.
digest() { printf '%s|%s' "$PROBLEM_ID" "$1" | sha256sum | cut -c1-6; }

# ---------------------------------------------------------------------------
# One obligation, one run, through the §5.1 verdict channel.
#   run_judge <id> <EXTENDS list> <expression>
# Leaves the raw status in RUN_RC and the trace, if any, in RUN_TRACE.
# ---------------------------------------------------------------------------
RUN_RC=0
RUN_TRACE=""

run_judge() {
  local id="$1" ext="$2" expr="$3"
  local mod="GJ_$id"
  {
    printf -- '---- MODULE %s ----\n' "$mod"
    printf 'EXTENDS %s\n' "$ext"
    printf 'GRADE_OBLIGATION == %s\n' "$expr"
    printf '====\n'
  } >"$SCRATCH/$mod.tla"
  {
    printf 'SPECIFICATION Spec\n'
    printf 'INVARIANT GRADE_OBLIGATION\n'
    [ -n "$CONST_FRAG" ] && cat "$CONST_FRAG"
  } >"$SCRATCH/$mod.cfg"

  RUN_TRACE="$SCRATCH/$mod.trace.json"
  bash "$VERDICT" --quiet \
       --timeout "$TIMEOUT" \
       --postcondition "Gate!InvariantConfigured" \
       --trace "$RUN_TRACE" \
       --scratch "$SCRATCH/run_$id" \
       "$SCRATCH/$mod.tla"
  RUN_RC=$?
}

# Turn a raw status into MET / UNMET, or refuse. `want` is the status that
# means MET: 0 for an obligation that must hold, 12 for one checked by
# refutation. Anything not in the table is a harness error and says so --
# never folded into the nearest familiar answer.
#   classify <want-rc> <phase> <label>   ->  sets CLASS
#
# The answer comes back in a GLOBAL and never on stdout, because this function
# refuses as well as answers. Called as `$(classify ...)` it would run in a
# subshell, where `exit 4` ends the subshell and the script carries on with a
# harness error swallowed and an empty reason in its place. That is not a
# hypothetical: it is what the first draft did.
CLASS=""
INVALID_REASON=""
classify() {
  local want="$1" phase="$2" label="$3"
  case "$RUN_RC" in
    0)  if [ "$want" = "0" ]; then CLASS=MET; else CLASS=UNMET; fi; return ;;
    12) if [ "$want" = "12" ]; then CLASS=MET; else CLASS=UNMET; fi; return ;;
    10) die_harness "$label: Gate!InvariantConfigured is false -- the generated .cfg configured no invariant" ;;
    150|151|255)
        if [ "$phase" = "submission" ]; then
          INVALID_REASON="$RUN_RC"; CLASS=INVALID; return
        fi
        die_harness "$label: the reference package failed to parse or configure (rc=$RUN_RC)" ;;
    124)
        if [ "$phase" = "submission" ]; then
          INVALID_REASON=124; CLASS=INVALID; return
        fi
        die_harness "$label: the reference model exceeded the ${TIMEOUT}s budget" ;;
    *)  die_harness "$label: unexpected verdict rc=$RUN_RC" ;;
  esac
}

# The §5.1 token for a raw status, so the INVALID object reports the channel's
# own word rather than a number this file invented.
token_for() {
  case "$1" in
    124) echo TIMEOUT ;;
    150) echo PARSE_ERROR ;;
    151) echo CONFIG_ERROR ;;
    255) echo TLC_EXCEPTION ;;
    *)   echo "UNKNOWN_$1" ;;
  esac
}

# A JSON array of the arguments, each a string.
#
# Call sites pass `${arr[@]+"${arr[@]}"}`, never `${arr[@]:-}`. Under `set -u`
# the second form expands an EMPTY array to one empty-string argument, so an
# empty list of unmet obligations came out as `[""]` -- an array of length one
# whose single element is nothing, which reads as a failure to anything
# counting entries. The `+` form expands to no arguments at all.
json_array() {
  if [ "$#" -eq 0 ]; then printf '[]'; else printf '%s\n' "$@" | jq -R . | jq -cs .; fi
}

emit_invalid() {
  jq -n -c \
    --arg schema "tla-puzzles/grade/v1" \
    --arg problem "$PROBLEM_ID" \
    --arg submission "$SUB_LABEL" \
    --argjson reasons "$(json_array "$(token_for "$INVALID_REASON")")" \
    '{schema:$schema, problem:$problem, submission:$submission,
      verdict:"INVALID", reasons:$reasons, witnesses:{}}'
}

# ---------------------------------------------------------------------------
# The location of a failure, from the trace, and NOTHING else from the trace.
# The last action of the counterexample is the step that reached the violating
# state, so its module and line are where the learner should look. A violation
# in an initial state has no action and yields no location rather than an
# invented one.
# ---------------------------------------------------------------------------
location_of() {
  local trace="$1"
  if [ ! -s "$trace" ]; then printf 'null'; return; fi
  jq -c '
    (.counterexample.action // []) as $a
    | if ($a | length) == 0 then null
      else ($a | last | .[1])
        | {module: .location.module, line: .location.beginLine, action: .name}
      end' "$trace" 2>/dev/null || printf 'null'
}

# ===========================================================================
# Obligation 3 first: non-vacuity, and the parse gate.
# ===========================================================================
vac_ext="$M_SUB_SPEC"
[ -n "$M_SUB_OBL" ] && vac_ext="$M_SUB_SPEC, $M_SUB_OBL"

# `PSI => FALSE` is written `Observe # Observe`, not `FALSE`, and the detour
# is forced. A literal `INVARIANT` of constant FALSE is refused by TLC before
# the search starts -- "The invariant of GRADE_OBLIGATION is equal to FALSE",
# rc=151, measured on TLC 2026.03.04.183147 -- so the vacuity probe would come
# back as a config error on every submission alike, vacuous or not. Phrasing
# it over `Observe` makes it state-dependent, which TLC cannot constant-fold,
# and it is false in every state that exists. So it is violated exactly when a
# state exists, which is the question being asked. It also fails loudly if the
# submission never defined the observation operator the statement named.
run_judge "V" "$vac_ext" "Observe # Observe"
classify 12 submission "non-vacuity"

if [ "$CLASS" = "INVALID" ]; then
  emit_invalid
  exit 3
fi

VACUOUS=false
NONVACUITY_STATUS=PASS
if [ "$CLASS" = "UNMET" ]; then
  VACUOUS=true
  NONVACUITY_STATUS=FAIL
fi

# ===========================================================================
# Obligation 1: the Adequacy suite. PSI => phi_i, per reference conjunct.
# ===========================================================================
ADEQ_MET=0
ADEQ_UNMET=()
UNDER_WITNESS=""

i=0
for conj in "${REF_CONJUNCTS[@]}"; do
  i=$((i + 1))
  run_judge "A$i" "$M_SUB_SPEC, $M_REF_OBL" "$conj(Observe)"
  classify 0 submission "reference obligation $i"
  if [ "$CLASS" = "INVALID" ]; then emit_invalid; exit 3; fi
  if [ "$CLASS" = "MET" ]; then
    ADEQ_MET=$((ADEQ_MET + 1))
  else
    id="R-$(digest "$conj")"
    ADEQ_UNMET+=("$id")
    # One witness of each kind, so the first refutation is kept and the rest
    # are counted. A learner fixing a spec is fixing one thing at a time.
    if [ -z "$UNDER_WITNESS" ]; then
      UNDER_WITNESS=$(jq -n -c --arg ob "$id" --argjson loc "$(location_of "$RUN_TRACE")" \
        '{kind:"reference-obligation-unmet", obligation:$ob, location:$loc}')
    fi
  fi
done

# ===========================================================================
# Obligation 2 and the landmarks: the Relational suite. This is the half that
# rejects specs which are TOO STRICT -- the sin reference-comparison grading
# actively teaches, and the one that dominates the measured data.
# ===========================================================================
REL_MET=0
REL_TOTAL=0
REL_UNMET=()
OVER_WITNESS=""

j=0
for conj in ${SUB_CONJUNCTS[@]+"${SUB_CONJUNCTS[@]}"}; do
  [ -z "$conj" ] && continue
  j=$((j + 1))
  REL_TOTAL=$((REL_TOTAL + 1))
  run_judge "R$j" "$M_REF_SPEC, $M_SUB_OBL" "$conj(Observe)"
  classify 0 reference "submission requirement $conj"
  if [ "$CLASS" = "MET" ]; then
    REL_MET=$((REL_MET + 1))
  else
    REL_UNMET+=("$conj")
    # The submission's own name and its own line. Quoting a learner's code
    # back to them leaks nothing, and it is the only witness in this file that
    # can carry a precise location the learner can act on.
    if [ -z "$OVER_WITNESS" ]; then
      line=$(grep -nE "^$conj\(" "$SUB_OBL" | head -1 | cut -d: -f1)
      OVER_WITNESS=$(jq -n -c --arg ob "$conj" --arg mod "$M_SUB_OBL" \
                              --argjson line "${line:-null}" \
        '{kind:"stated-requirement-refuted", obligation:$ob,
          location:{module:$mod, line:$line, action:null}}')
    fi
  fi
done

k=0
for lm in ${REF_LANDMARKS[@]+"${REF_LANDMARKS[@]}"}; do
  [ -z "$lm" ] && continue
  k=$((k + 1))
  REL_TOTAL=$((REL_TOTAL + 1))
  run_judge "L$k" "$M_SUB_SPEC, $M_REF_OBL" "~$lm(Observe)"
  classify 12 submission "landmark $k"
  if [ "$CLASS" = "INVALID" ]; then emit_invalid; exit 3; fi
  if [ "$CLASS" = "MET" ]; then
    REL_MET=$((REL_MET + 1))
  else
    id="L-$(digest "$lm")"
    REL_UNMET+=("$id")
    # A stated requirement that was refuted is a better witness than an
    # unreachable landmark, because it has a location in the submission. So a
    # landmark only becomes the witness when nothing better was found.
    if [ -z "$OVER_WITNESS" ]; then
      OVER_WITNESS=$(jq -n -c --arg ob "$id" \
        '{kind:"reference-observation-unreachable", obligation:$ob, location:null}')
    fi
  fi
done

# ===========================================================================
# Assemble.
# ===========================================================================
ADEQ_TOTAL=${#REF_CONJUNCTS[@]}
ADEQ_STATUS=PASS
[ "${#ADEQ_UNMET[@]}" -gt 0 ] && ADEQ_STATUS=FAIL
REL_STATUS=PASS
[ "${#REL_UNMET[@]}" -gt 0 ] && REL_STATUS=FAIL

UNDER=false
[ "$ADEQ_STATUS" = "FAIL" ] && UNDER=true
OVER=false
[ "$REL_STATUS" = "FAIL" ] && OVER=true

REASONS=()
[ "$UNDER" = "true" ] && REASONS+=("under-constrained")
[ "$OVER" = "true" ] && REASONS+=("over-constrained")
[ "$VACUOUS" = "true" ] && REASONS+=("vacuous")

VERDICT_WORD=PASS
EXIT_CODE=0
if [ "${#REASONS[@]}" -gt 0 ]; then
  VERDICT_WORD=FAIL
  EXIT_CODE=1
fi

SUITES=$(jq -n -c \
  --arg as "$ADEQ_STATUS" --argjson am "$ADEQ_MET" --argjson at "$ADEQ_TOTAL" \
  --argjson au "$(json_array ${ADEQ_UNMET[@]+"${ADEQ_UNMET[@]}"})" \
  --arg rs "$REL_STATUS" --argjson rm "$REL_MET" --argjson rt "$REL_TOTAL" \
  --argjson ru "$(json_array ${REL_UNMET[@]+"${REL_UNMET[@]}"})" \
  --arg vs "$NONVACUITY_STATUS" \
  '{Adequacy:   {status:$as, met:$am, total:$at, unmet:$au},
    Relational: {status:$rs, met:$rm, total:$rt, unmet:$ru},
    NonVacuity: {status:$vs}}')

WITNESSES=$(jq -n -c \
  --argjson u "${UNDER_WITNESS:-null}" \
  --argjson o "${OVER_WITNESS:-null}" \
  '{under_constraint:$u, over_constraint:$o}
   | with_entries(select(.value != null))')

OBJ=$(jq -n \
  --arg schema "tla-puzzles/grade/v1" \
  --arg problem "$PROBLEM_ID" \
  --arg submission "$SUB_LABEL" \
  --arg verdict "$VERDICT_WORD" \
  --argjson reasons "$(json_array ${REASONS[@]+"${REASONS[@]}"})" \
  --argjson under "$UNDER" \
  --argjson over "$OVER" \
  --argjson vacuous "$VACUOUS" \
  --argjson suites "$SUITES" \
  --argjson witnesses "$WITNESSES" \
  '{schema:$schema, problem:$problem, submission:$submission,
    verdict:$verdict, reasons:$reasons,
    under_constrained:$under, over_constrained:$over, vacuous:$vacuous,
    suites:$suites, witnesses:$witnesses}')

# The canary, and the only reason it exists: a fail-closed guard that has
# never been observed to fire is not evidence of anything. The selftest sets
# this to inject a reference-side operator name into the object and require
# that nothing reaches stdout.
if [ "${GRADE_LEAK_CANARY:-0}" = "1" ]; then
  OBJ=$(printf '%s' "$OBJ" | jq -c --arg c "${REF_CONJUNCTS[0]}" '. + {canary:$c}')
fi

# ===========================================================================
# THE LEAK GATE. A WHITELIST, DELIBERATELY.
#
# A blacklist -- "no reference identifier may appear" -- has to decide what
# counts as a reference identifier, and a reference module's prose is full of
# ordinary English that is also legitimate schema vocabulary. This asks the
# opposite question, which has an exact answer: every string leaving here must
# be fixed schema vocabulary, an opaque digest, caller-supplied, or a token
# that occurs verbatim in the submission's own files. Nothing else is
# printable, and an unrecognized string is a refusal rather than a warning.
# ===========================================================================
VOCAB=$(cat <<VOCAB_END
tla-puzzles/grade/v1
PASS
FAIL
INVALID
Adequacy
Relational
NonVacuity
under-constrained
over-constrained
vacuous
reference-obligation-unmet
stated-requirement-refuted
reference-observation-unreachable
TIMEOUT
PARSE_ERROR
CONFIG_ERROR
TLC_EXCEPTION
$PROBLEM_ID
$SUB_LABEL
VOCAB_END
)

SUB_TOKENS=$( { cat "$SUB_SPEC"; [ -n "$SUB_OBL" ] && cat "$SUB_OBL"
                printf '%s\n%s\n' "$M_SUB_SPEC" "$M_SUB_OBL"
              } | grep -oE '[A-Za-z][A-Za-z0-9_]*' | sort -u )

leaked=""
while IFS= read -r value; do
  [ -z "$value" ] && continue
  # An exact match against the fixed vocabulary, or an opaque digest, passes
  # whole. Everything else is broken into identifier tokens and each token has
  # to be accounted for.
  if printf '%s\n' "$VOCAB" | grep -qxF -- "$value"; then continue; fi
  if printf '%s' "$value" | grep -qE '^[RL]-[0-9a-f]{6}$'; then continue; fi
  bad=""
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    printf '%s\n' "$SUB_TOKENS" | grep -qxF -- "$tok" && continue
    printf '%s\n' "$VOCAB" | grep -qxF -- "$tok" && continue
    bad="$bad $tok"
  done < <(printf '%s' "$value" | grep -oE '[A-Za-z][A-Za-z0-9_]*')
  [ -n "$bad" ] && leaked="$leaked$value ->$bad; "
done < <(printf '%s' "$OBJ" | jq -r '.. | strings')

if [ -n "$leaked" ]; then
  echo "grade.sh: LEAK GATE: the verdict object was not printed. Unaccounted strings: $leaked" >&2
  exit 5
fi

printf '%s\n' "$OBJ"
exit "$EXIT_CODE"
