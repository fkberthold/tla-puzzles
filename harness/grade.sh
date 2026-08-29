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
#     *RefObl.tla      variable-free. ObsDomain names the records the
#                      observation may take; Req_*(o) are the conjuncts phi_i;
#                      Step_*(o, p) are conjuncts over a PAIR of successive
#                      observations; Landmark_*(o) are observations PHI
#                      reaches.
#     constants.cfg    optional, CONSTANT assignments only, appended to every
#                      generated .cfg. A directive in it is refused.
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
#              PSI => step_k    judge EXTENDS <submission spec>, <ref obl>
#                               SPECIFICATION Spec / PROPERTY
#                                 [][step_k(Observe, Observe')]_Observe
#                               rc=0 met, rc=13 UNMET (too weak). A boxed
#                               action goes through TLC's implied-action
#                               channel, which is 13 and not 12. Same suite
#                               and same direction as phi_i -- an authored
#                               obligation over observations, checked against
#                               the SUBMISSION -- but over a PAIR of
#                               successive observations, which is what a
#                               single-state predicate cannot reach. See the
#                               long note at the loop itself for why the
#                               subscript is Observe and not vars, and for
#                               what a step obligation still does not close.
#
#              landmark         a problem stating any step_k must state two
#              disjointness     or more landmarks that no single observation
#                               satisfies together, because [][A]_Observe is
#                               satisfied vacuously by a frozen observation
#                               and the landmark suite is the only thing that
#                               refuses one. Checked, not merely documented:
#                               one run over the reference, and a failure is
#                               exit 2 against the PROBLEM PACKAGE.
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
# Every run also carries a postcondition guard: `Gate!InvariantConfigured` on
# the INVARIANT form, `Gate!ActionPropertyConfigured` on the PROPERTY form. The
# generated .cfg files are this script's own output, and a .cfg keyword with a
# missing operand is not an error -- TLC exits 0 having checked nothing at all
# (§5.3). Without the guard, a bug in the generator below would grade every
# submission a perfect pass. With it, that bug is rc=10 and a harness error.
# The two guards are not interchangeable; see the note at run_judge. Gate.tla
# is harness-owned and read-only here.
#
# Before any of that, the PACKAGE is checked. A reference whose obligations are
# all true of pure chaos over its own declared ObsDomain cannot grade at all,
# and is refused at exit 2 rather than used. See the chaos-probe block.
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

# THE HARNESS IS RESOLVED FROM THIS FILE, NEVER FROM THE CALLER'S CWD.
#
# This used to be `git rev-parse --show-toplevel`, which asks a question about
# whoever invoked grade.sh rather than about grade.sh. Outside a repository it
# failed loudly, and that case was fine. Run from inside a DIFFERENT
# repository that happens to have a harness/ directory, it silently loaded
# THAT repository's verdict channel and THAT repository's Gate.tla -- the two
# things every verdict below rests on, taken from somewhere nobody chose.
#
# Bead tla-u8on, and bead tla-1hf in the mirror direction: there
# scripts/gen-curriculum-map.sh hardcoded a `cd` to the repo root and wrote
# into the main checkout from a worktree. Same rule out of both: a script that
# resolves its own root resolves it from ${BASH_SOURCE[0]}, never from a
# literal path and never from the caller's cwd. scripts/cibuild:43 and
# harness/refinement.sh:186 are the other two sites that already do.
HARNESS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERDICT="$HARNESS_DIR/verdict.sh"
GATE="$HARNESS_DIR/Gate.tla"

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

# Same status as die_usage -- exit 2 already covers "a malformed problem
# package" -- and a different audience. A caller who mistyped a flag needs the
# usage text; a problem author whose package is wrong needs the explanation and
# is not helped by being shown the argument list. So the message stands alone.
die_package() { echo "grade.sh: $1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--reference)  REFDIR="${2:-}"; shift 2 ;;
    -s|--submission) SUBDIR="${2:-}"; shift 2 ;;
    -p|--problem-id) PROBLEM_ID="${2:-}"; shift 2 ;;
    -t|--timeout)    TIMEOUT="${2:-}"; shift 2 ;;
    --scratch)       SCRATCH="${2:-}"; shift 2 ;;
    --selftest)      exec "$HARNESS_DIR/fixtures/grade/selftest.sh" ;;
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
# Reached only through the EXIT trap below. shellcheck does not follow traps,
# so it reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { [ "$CLEAN_SCRATCH" = "1" ] && rm -rf "$SCRATCH"; }
trap cleanup EXIT

cp "$REF_SPEC" "$REF_OBL" "$SUB_SPEC" "$GATE" "$SCRATCH/"
[ -n "$SUB_OBL" ] && cp "$SUB_OBL" "$SCRATCH/"

# ---------------------------------------------------------------------------
# THE CONSTANTS FRAGMENT. Optional, found by filename beside the reference
# modules, appended to every generated judge .cfg.
#
# IT CARRIES CONSTANT / CONSTANTS AND NOTHING ELSE. Every other line of those
# .cfg files is this script's own output, and §5.7's whole posture is that the
# .cfg stays harness-owned precisely so grading cannot be weakened. The
# fragment is the one text from a problem package that reaches it, so it is the
# one place that ownership can leak, and it is checked before anything is
# staged.
#
# WHAT IT COSTS HERE IS A MISATTRIBUTED GRADE, NOT AN ATTACK. The reference
# package is harness-owned rather than submission-owned, so this is an
# author-error trap. It is worth closing anyway, because the errors are silent
# and both directions are wrong:
#
#   A second INVARIANT fires and this script reads the rc=12 as "the obligation
#   under test was UNMET". A correct submission comes back under-constrained,
#   and the invariant that decided it appears nowhere in the report.
#
#   A CONSTRAINT truncates the reachable space, so an obligation that a full
#   search would refute is never reached and an UNMET turns into a MET.
#
# A DIRECTIVE IS A TOKEN, NOT A LINE, and that is the part worth getting right
# rather than copying. `CONSTANT Unused = 6 INVARIANT Bad` checks Bad, and so
# does `(* c *) INVARIANT Bad`; only `\*` makes the rest of a line a comment to
# TLC's .cfg parser. A guard anchored at the start of a line sees neither.
# That was measured on v1.8.0 under bead tla-nesz, which is where
# refinement.sh's guard was hardened into the form below.
#
# This is the THIRD site of the class -- refinement.sh --constants (tla-nesz)
# and seeded-bugs.sh constants.cfg (tla-40y) are the other two, and two
# independent agents found them on the same day without knowing about each
# other. Bead tla-j8yd.
#
# It will also refuse a CONSTANT whose VALUE contains one of these words, say
# `CONSTANT Msg = "INVARIANT"`. That is a false refusal of a legal fragment and
# it is the direction to err in: the alternative is letting a problem package
# author part of the configuration that grades it.
# ---------------------------------------------------------------------------
strip_cfg_comments() {
  awk '
    { line = $0; out = ""; i = 1; n = length(line)
      while (i <= n) {
        c2 = substr(line, i, 2)
        if (depth == 0 && c2 == "\\*") { break }
        if (c2 == "(*") { depth++; i += 2; continue }
        if (c2 == "*)" && depth > 0) { depth--; i += 2; continue }
        if (depth == 0) { out = out substr(line, i, 1) }
        i++
      }
      print out
    }
  ' "$1"
}

CONST_FRAG=""
if [ -f "$REFDIR/constants.cfg" ]; then
  CONST_FRAG="$REFDIR/constants.cfg"
  # A here-string, never a pipe. Under `pipefail` an early-exiting `grep -q`
  # SIGPIPEs the producer and the pipeline reports 141, which this `if` would
  # read as "no directive found" -- letting through the very line the check
  # exists to refuse. Bead tla-kr9.
  frag=$(strip_cfg_comments "$CONST_FRAG")
  if grep -qE '(^|[^A-Za-z0-9_])(SPECIFICATION|SPECIFICATIONS|INIT|NEXT|INVARIANT|INVARIANTS|PROPERTY|PROPERTIES|CONSTRAINT|CONSTRAINTS|ACTION_CONSTRAINT|ACTION_CONSTRAINTS|SYMMETRY|VIEW|ALIAS|POSTCONDITION|CHECK_DEADLOCK)([^A-Za-z0-9_]|$)' <<<"$frag"; then
    die_package "$CONST_FRAG carries a directive.

A constants fragment assigns CONSTANT / CONSTANTS and nothing else. Every
other line of a generated judge .cfg belongs to the harness, and a problem
package that could write one could weaken its own grading.

A directive is a TOKEN and not a line, so it is refused wherever it appears --
riding the end of a CONSTANT assignment, or behind a (* block comment *),
both of which TLC reads as live directives. Only a \\* comment is a comment."
  fi
fi

# ---------------------------------------------------------------------------
# Obligation discovery. Column-1 operator definitions, by prefix.
# ---------------------------------------------------------------------------
ops_named() {  # $1 = file, $2 = prefix
  [ -f "$1" ] || return 0
  grep -oE "^$2[A-Za-z0-9_]*\(" "$1" | sed 's/($//;s/(//' | sort -u
}

mapfile -t REF_CONJUNCTS < <(ops_named "$REF_OBL" "Req_")
mapfile -t REF_LANDMARKS < <(ops_named "$REF_OBL" "Landmark_")
mapfile -t REF_STEPS     < <(ops_named "$REF_OBL" "Step_")
mapfile -t SUB_CONJUNCTS < <(ops_named "$SUB_OBL" "Req_")

[ "${#REF_CONJUNCTS[@]}" -gt 0 ] || \
  die_usage "the reference obligations module declares no Req_* conjunct: $REF_OBL"

# Opaque handle for a reference-side obligation. Salted with the problem id so
# the same operator name in two problems does not produce the same id, which
# would let a learner correlate decompositions across problems.
digest() { printf '%s|%s' "$PROBLEM_ID" "$1" | sha256sum | cut -c1-6; }

# ---------------------------------------------------------------------------
# One obligation, one run, through the §5.1 verdict channel.
#   run_judge <id> <EXTENDS list> <expression> [invariant|property]
# Leaves the raw status in RUN_RC and the trace, if any, in RUN_TRACE.
#
# The fourth argument picks the .cfg keyword, and the two forms are not
# interchangeable. A one-state predicate goes in as INVARIANT; a boxed action
# goes in as PROPERTY, which TLC checks through the implied-action channel and
# which exits 13 rather than 12 when it fails.
#
# BOTH FORMS CARRY A POSTCONDITION GUARD, AND THE TWO GUARDS DIFFER. Neither
# is interchangeable with the other, and that was measured rather than assumed.
# Against a well-formed `PROPERTY GRADE_OBLIGATION` cfg on v1.8.0, whose
# obligation is a satisfied boxed action:
#
#   TLCGet("spec") reports  impliedactions # {},  invariants = {},
#                           impliedinits = {},    temporals = {}
#   Gate!InvariantConfigured   rc=10  (invariants is empty)
#   Gate!RefinementConfigured  rc=10  (impliedinits is empty; it wants BOTH)
#
# so passing either of those to the PROPERTY form would turn every step
# obligation into a harness error. `Gate!ActionPropertyConfigured` is the
# operator that fits, and it closes the vector InvariantConfigured exists for
# one keyword over: a bare `PROPERTY` line with no operand is not an error to
# TLC's .cfg parser, so an unguarded generator bug that dropped the operand
# would grade every submission a pass on every step obligation the problem
# states. The operator sat in Gate.tla for a while with nothing naming it.
# Bead tla-x8s.
# ---------------------------------------------------------------------------
RUN_RC=0
RUN_TRACE=""

run_judge() {
  local id="$1" ext="$2" expr="$3" kind="${4:-invariant}"
  local mod="GJ_$id"
  local keyword=INVARIANT
  local -a guard=(--postcondition "Gate!InvariantConfigured")
  if [ "$kind" = "property" ]; then
    keyword=PROPERTY
    guard=(--postcondition "Gate!ActionPropertyConfigured")
  fi
  {
    printf -- '---- MODULE %s ----\n' "$mod"
    printf 'EXTENDS %s\n' "$ext"
    printf 'GRADE_OBLIGATION == %s\n' "$expr"
    printf '====\n'
  } >"$SCRATCH/$mod.tla"
  {
    printf 'SPECIFICATION Spec\n'
    printf '%s GRADE_OBLIGATION\n' "$keyword"
    [ -n "$CONST_FRAG" ] && cat "$CONST_FRAG"
  } >"$SCRATCH/$mod.cfg"

  RUN_TRACE="$SCRATCH/$mod.trace.json"
  bash "$VERDICT" --quiet \
       --timeout "$TIMEOUT" \
       ${guard[@]+"${guard[@]}"} \
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
    # 13 is the implied-action channel, which is how a boxed step obligation
    # fails. It used to fall through to the catch-all below and exit 4.
    #
    # 12 AND 13 SPLIT ON THE SHAPE OF THE FORMULA, NOT ON THE .cfg KEYWORD
    # (bead tla-94n), so neither number identifies which obligation was being
    # checked and no arm here may assume one. A step obligation is asked for
    # with `want` 0, and both 12 and 13 land on UNMET from there -- a boxed
    # action exits 13 on this build, and a step obligation TLC could refute
    # from a finite prefix would exit 12, and either way the obligation was
    # checked and did not hold. The refutation form asks for 12 and is
    # unaffected; nothing in this file asks for 13.
    13) if [ "$want" = "13" ]; then CLASS=MET; else CLASS=UNMET; fi; return ;;
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
    # The evaluation-failure rows. THESE ARE NOT VIOLATION ROWS: 12 and 13 mean
    # the obligation was checked and came out false, while 75, 76 and 77 mean
    # the check never happened -- the spec did not evaluate, the invariant blew
    # up mid-evaluation, or TLC refused the temporal formula. Nothing at all is
    # known about whether the obligation holds.
    #
    # They are learner-facing all the same. A submission whose observation
    # record has the wrong shape -- `[hue |-> colour]` against obligations that
    # read `o.level` -- lands here, and getting the graded interface wrong is a
    # learner error, not a harness fault. They used to fall through to the
    # catch-all below and exit 4, which tells a learner nothing and tells
    # whoever is running the batch that the harness is broken when it is not.
    # Bead tla-tkzt.
    #
    # 75 is a FAMILY rather than a condition -- at least four EC constants route
    # to it -- so the INVALID object says the spec did not evaluate and never
    # guesses which of them it was. The cause is in the log, which is written
    # for humans and never read for a verdict.
    75|76|77)
        if [ "$phase" = "submission" ]; then
          INVALID_REASON="$RUN_RC"; CLASS=INVALID; return
        fi
        die_harness "$label: the reference package could not be evaluated (rc=$RUN_RC)" ;;
    *)  die_harness "$label: unexpected verdict rc=$RUN_RC" ;;
  esac
}

# The §5.1 token for a raw status, so the INVALID object reports the channel's
# own word rather than a number this file invented.
token_for() {
  case "$1" in
    75)  echo SPEC_EVAL_FAILURE ;;
    76)  echo SAFETY_EVAL_FAILURE ;;
    77)  echo LIVENESS_EVAL_FAILURE ;;
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
# THE LANDMARK SUITE IS THE FROZEN-MAPPING PROBE, SO A PROBLEM THAT STATES A
# STEP OBLIGATION MUST CARRY ONE THAT WORKS. A CHECK, NOT A HEADER NOTE.
#
# `[][A]_Observe` unfolds to `A \/ UNCHANGED Observe`, so a submission whose
# observation operator NEVER MOVES satisfies every step obligation there is,
# vacuously and at rc=0. That is the frozen-mapping trapdoor from the TLAiBench
# survey §6 reappearing inside the fix for it, and the step obligation cannot
# close it from the inside -- no amount of care in writing A helps, because A
# is never the disjunct that is taken.
#
# What closes it is the landmark suite, which is already the harness's
# frozen-mapping probe: a frozen observation is ONE value, and one value cannot
# satisfy two requirements that no single observation satisfies together. So
# the guard is a property of the OBLIGATION MODULE, and it is cheap:
#
#   An obligation module stating any Step_* must state two or more landmarks
#   whose observations are pairwise unsatisfiable.
#
# Both halves are checked here rather than written down and hoped for. The
# count is static. The unsatisfiability is one TLC run whose invariant is every
# pair at once, and a violation of it is a defect in the PROBLEM PACKAGE --
# exit 2, attributed to the author, never a verdict about a submission.
#
# TWO DEVIATIONS FROM THE DESIGN, BOTH MEASURED, NEITHER SILENT.
#
# The design said "one TLC run over the obligation module alone". That is not
# runnable: an obligation module is variable-free by construction, so it has no
# state space for TLC to search and no domain to quantify a record over. The
# run below extends the REFERENCE SPEC as well, which is the natural domain --
# a landmark is by definition an observation PHI reaches.
#
# The residual hole that leaves: disjointness is proven over the observations
# the REFERENCE reaches, not over every record. Two landmarks that overlap only
# at an observation the reference cannot reach would pass this check, and a
# submission frozen at that observation would then satisfy both.
#
# THE HOLE IS STILL OPEN, and what changed under bead tla-x8s is that the
# obligations module now declares an ObsDomain. Quantifying disjointness over
# the domain rather than over the reference's reachable set is therefore
# available, and it would close the hole. It was left alone because no fixture
# separates the two readings: `reference-overlapping` overlaps at level 3,
# which the reference reaches, so both quantifications refuse it and the change
# would land with nothing watching it. Worth doing behind a fixture that tells
# them apart.
# ===========================================================================
if [ "${#REF_STEPS[@]}" -gt 0 ]; then
  if [ "${#REF_LANDMARKS[@]}" -lt 2 ]; then
    die_package "$REF_OBL states a Step_* obligation and ${#REF_LANDMARKS[@]} landmark(s).

A step obligation is judged as [][Step(Observe, Observe')]_Observe, which is
satisfied by a submission whose observation never moves -- the UNCHANGED
disjunct is always available. The landmark suite is what refuses that, and it
can only refuse it with two or more landmarks that no single observation
satisfies together. State them, or state no Step_*."
  fi

  # Pairwise, joined infix. A leading `/\` would open a junction list, whose
  # members are delimited by COLUMN, and every member here is on one line.
  disjoint=""
  li=0
  while [ "$li" -lt "${#REF_LANDMARKS[@]}" ]; do
    lj=$((li + 1))
    while [ "$lj" -lt "${#REF_LANDMARKS[@]}" ]; do
      [ -n "$disjoint" ] && disjoint="$disjoint /\\ "
      disjoint="$disjoint~(${REF_LANDMARKS[$li]}(Observe) /\\ ${REF_LANDMARKS[$lj]}(Observe))"
      lj=$((lj + 1))
    done
    li=$((li + 1))
  done

  run_judge "D" "$M_REF_SPEC, $M_REF_OBL" "$disjoint"
  classify 0 reference "landmark disjointness"
  if [ "$CLASS" != "MET" ]; then
    die_package "$REF_OBL states a Step_* obligation, and two of its landmarks
are satisfied by the same observation.

Landmarks are what refuse a frozen observation operator, and they only refuse
one when no single observation satisfies two of them. A pair that overlaps is
a pair a frozen submission can reach at once, and the step obligation it would
then satisfy vacuously is the one this problem exists to check."
  fi
fi

# ===========================================================================
# THE CHAOS PROBE. A REFERENCE THAT CANNOT TELL CHAOS FROM THE SYSTEM CANNOT
# GRADE, SO ITS PACKAGE IS REFUSED. Beads tla-59s and tla-x8s.
#
# Everything below this point grades a SUBMISSION. Nothing below asks whether
# the reference says enough to grade against, and the Adequacy denominator is
# whatever the author happened to write -- so a package whose obligations are
# all true of a spec with no transition structure grades that spec a clean
# PASS and reports a full score doing it.
#
# The probe is the maximally permissive spec over the reference's own declared
# observation domain: every record in the domain is an initial state, and any
# record may follow any other. No ordering, no causality, nothing that could
# be called a system. If every obligation the package states is true of that,
# the obligations describe the domain rather than the system.
#
# WHY A PROBE RATHER THAN "EVERY REFERENCE MUST STATE A Step_*". The syntactic
# form is a stand-in for the property actually wanted, and it fails in both
# directions. A vacuous Step_* satisfies it while refusing nothing, and a
# problem with no concurrency in it would have to fabricate a transition
# obligation to get past it. The `chaos-probe/reference-state-refuses` fixture
# states no Step_* at all, refuses chaos on a single requirement relating two
# fields of one observation, and is required to be ACCEPTED.
#
# ObsDomain IS A NEW AUTHORING REQUIREMENT, and there is nothing to probe over
# without it. An obligations module is variable-free by construction, so it
# carries no state space of its own and no domain to quantify a record over.
# A module that declares none is refused rather than having the gate quietly
# switch itself off for that package.
#
# WHAT THE PROBE ASKS AND WHAT IT LEAVES ALONE. It runs the Adequacy members,
# Req_* and Step_*, and nothing else. Landmark reachability is not asked,
# because chaos reaches every record in the domain and so reaches every
# landmark the domain contains; a landmark it missed would be a landmark
# outside the declared domain, which is a different defect and deserves its
# own message rather than this one.
# ===========================================================================
grep -qE '^ObsDomain[[:space:]]*==' "$REF_OBL" || die_package \
  "$REF_OBL declares no ObsDomain.

An obligations module owes one line naming the records its observation may
take, in the shape ObsDomain == [level: 0..3, full: BOOLEAN]. It is what the
chaos probe ranges over, and the requirements below it are what carve it.

The module is variable-free by construction, so there is no other domain to
quantify a record over and no way to ask whether these obligations describe
the system or merely restate the domain."

CHAOS_MOD="GJ_Chaos"
cat >"$SCRATCH/$CHAOS_MOD.tla" <<CHAOS_END
---- MODULE $CHAOS_MOD ----
EXTENDS $M_REF_OBL
VARIABLE obs
Init == obs \\in ObsDomain
Next == obs' \\in ObsDomain
Spec == Init /\\ [][Next]_obs
Observe == obs
====
CHAOS_END

# One UNMET obligation is the whole answer, so the loops stop at the first one.
# The probe runs on every grading, and a package that survives it survives it
# for the same reason every time.
CHAOS_ALL_MET=1
x=0
for conj in "${REF_CONJUNCTS[@]}"; do
  [ "$CHAOS_ALL_MET" = "1" ] || break
  x=$((x + 1))
  run_judge "X$x" "$CHAOS_MOD" "$conj(Observe)"
  classify 0 reference "chaos probe, reference obligation $x"
  [ "$CLASS" = "MET" ] || CHAOS_ALL_MET=0
done

for st in ${REF_STEPS[@]+"${REF_STEPS[@]}"}; do
  [ -z "$st" ] && continue
  [ "$CHAOS_ALL_MET" = "1" ] || break
  x=$((x + 1))
  run_judge "X$x" "$CHAOS_MOD" "[][$st(Observe, Observe')]_Observe" property
  classify 0 reference "chaos probe, reference step obligation $x"
  [ "$CLASS" = "MET" ] || CHAOS_ALL_MET=0
done

if [ "$CHAOS_ALL_MET" = "1" ]; then
  die_package "$REF_OBL is satisfied by pure chaos over its own ObsDomain.

Every obligation this module states is true of a spec that has no transitions
at all -- one that starts at any record in the domain and jumps to any other.
A box whose contents teleport from empty to full satisfies this set entire, so
the set cannot tell a system from the space its observations live in, and a
submission with no structure would grade a clean PASS against it.

The defect is the problem author's and no verdict about a submission is
printed for it. Two ways out, and neither is a rule about what you must write:
state an obligation over a PAIR of successive observations, or state one that
relates two fields of a single observation. Either gives the probe something
to break."
fi

# ===========================================================================
# Obligation 3 first among the submission-driven runs: non-vacuity, and the
# parse gate. Every run above is reference-only -- the landmark-disjointness
# run and the chaos probe both extend nothing the submission wrote -- so
# neither disturbs the attribution argument below.
# ===========================================================================
vac_ext="$M_SUB_SPEC"
[ -n "$M_SUB_OBL" ] && vac_ext="$M_SUB_SPEC, $M_SUB_OBL"

# `PSI => FALSE` is written `Observe # Observe`, not `FALSE`, and the detour
# is forced. A literal `INVARIANT` of constant FALSE is refused by TLC before
# the search starts -- "The invariant of GRADE_OBLIGATION is equal to FALSE",
# rc=151, measured on TLC 2026.03.04.183147 and again on tla2tools v1.8.0
# (TLC 2026.07.31.184830) -- so the vacuity probe would come back as a config
# error on every submission alike, vacuous or not. Phrasing it over `Observe`
# makes it state-dependent, which TLC cannot constant-fold,
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

# ---------------------------------------------------------------------------
# Obligation 1 continued: the STEP obligations, over a PAIR of successive
# observations. Same suite, same direction, same class of object -- an
# authored requirement over observations, checked against the SUBMISSION. The
# reference spec is not involved, so this is not §3.5 reference comparison.
#
# WHY THE SUITE NEEDED THEM. Every obligation above is a single-state
# predicate, and no single-state predicate can constrain a transition
# relation. The maximally permissive spec whose reachable observation set
# equals the invariant-admissible set therefore passes obligation 1 BY
# CONSTRUCTION, for any reference -- and it does not have to lie to do it. A
# spec that is pure chaos over an entirely honest observation space (`Init ==
# obs \in 0..3`, `Next == obs' \in 0..3`, `Observe` the identity) has no
# transitions, no ordering and no causality, and it graded PASS with zero
# witnesses against the `lockbox` reference fixture as it stood before
# tla-x8s, which is the same reference the chaos probe above now refuses.
# Beads tla-59s and tla-x8s, which are one defect: the first says a transition
# obligation cannot be expressed, the second is the consequence.
#
# THE `_Observe` SUBSCRIPT IS LOAD-BEARING AND IS NOT A STYLE CHOICE.
# Subscripting on `vars` makes the obligation depend on how finely the
# submission slices its own steps: a decide-then-commit spec fails a strict
# step obligation that a coarser spec satisfies, which is bead tla-nyrb's
# spec-dependence exactly. Measured on the lockbox pair:
#
#     coarse spec, [][A]_vars     rc=0     fine spec, [][A]_vars     rc=13
#     coarse spec, [][A]_Observe  rc=0     fine spec, [][A]_Observe  rc=0
#
# Under `_Observe` a step that moves internal state without moving the
# observation IS a stutter on the observation, and is excluded by
# construction. Representation stays the learner's (§3.2), which is the whole
# point of grading at the observation (§3.3).
#
# WHAT IT STILL DOES NOT CLOSE, and it is not a rounding error: Step_k
# constrains CONSECUTIVE observations, so a submission can get the multi-step
# structure wrong while every single step is legal. Smaller hole, not no hole.
# The vacuous-satisfaction hole -- a frozen observation -- is closed by the
# landmark check above rather than here.
# ---------------------------------------------------------------------------
s=0
for st in ${REF_STEPS[@]+"${REF_STEPS[@]}"}; do
  [ -z "$st" ] && continue
  s=$((s + 1))
  run_judge "S$s" "$M_SUB_SPEC, $M_REF_OBL" \
            "[][$st(Observe, Observe')]_Observe" property
  classify 0 submission "reference step obligation $s"
  if [ "$CLASS" = "INVALID" ]; then emit_invalid; exit 3; fi
  if [ "$CLASS" = "MET" ]; then
    ADEQ_MET=$((ADEQ_MET + 1))
  else
    # The SAME `R-` prefix a one-state conjunct gets. A separate prefix would
    # tell the learner which of their obligations is about transitions, and
    # the shape of the decomposition is content -- §6b.2 protects it. The
    # digest is over the operator name, so the two never collide.
    id="R-$(digest "$st")"
    ADEQ_UNMET+=("$id")
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
      # Sliced with a parameter expansion rather than `| head -1`: head closes
      # the pipe after its first line and grep dies of SIGPIPE, which under
      # `pipefail` makes the pipeline 141. Bead tla-kr9. `cut` reads to EOF, so
      # nothing early-exits here.
      line=$(grep -nE "^$conj\(" "$SUB_OBL" | cut -d: -f1)
      line=${line%%$'\n'*}
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
ADEQ_TOTAL=$(( ${#REF_CONJUNCTS[@]} + ${#REF_STEPS[@]} ))
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
SPEC_EVAL_FAILURE
SAFETY_EVAL_FAILURE
LIVENESS_EVAL_FAILURE
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
  # Every match below is a here-string, never a pipe. `$SUB_TOKENS` is every
  # identifier in the submission and `$VOCAB` the whole fixed vocabulary, so
  # both are chatty producers; under `pipefail` an early-exiting `grep -q`
  # SIGPIPEs the producer and the pipeline reports 141. Here that would read as
  # "token not accounted for", so a perfectly legitimate token would trip the
  # leak gate and grade.sh would refuse to print a correct verdict object --
  # intermittently, on submission size. Bead tla-kr9.
  if grep -qxF -- "$value" <<<"$VOCAB"; then continue; fi
  if grep -qE '^[RL]-[0-9a-f]{6}$' <<<"$value"; then continue; fi
  bad=""
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    grep -qxF -- "$tok" <<<"$SUB_TOKENS" && continue
    grep -qxF -- "$tok" <<<"$VOCAB" && continue
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
