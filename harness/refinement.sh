#!/usr/bin/env bash
# refinement.sh — Refinement checking with the frozen-mapping trapdoor closed
# (V2-PLAN.md §5.4, bead tla-kl5.7).
#
# THE ONE THING THIS FILE EXISTS FOR
#
#   A refinement check that passes proves nothing on its own. Define
#
#       Refines == Abstract!Spec
#
#   map every abstract variable to a constant, and TLC exits 0. The mechanism:
#   A!Spec expands to A!Init /\ [][A!Next]_(A!vars), and the action formula
#   unfolds to
#
#       A!Next \/ UNCHANGED (A!vars)
#
#   With the mapping frozen, A!vars is the same tuple in every state, so the
#   right disjunct is true at every step and A!Next is never evaluated once.
#   The submission is graded on a proof obligation that was discharged by
#   stuttering.
#
#   So: name the mapped expression, assert as an ORDINARY INVARIANT that it
#   never leaves its initial value, and require TLC to VIOLATE it.
#
#       A PASSING PROBE IS A FAILING REFINEMENT CHECK.
#
#   This is not a hypothetical hardening exercise. tlaplus/TLAiBench, the only
#   public benchmark that grades TLA+ refinement, has the trapdoor open: a
#   fully frozen mapping (WITH big <- 0, small <- 0) passes both its plain
#   refinement check and its Gold!Refinement postcondition at rc=0. Surveyed
#   under bead tla-kl5.3, 2026-08-06.
#
# USAGE
#   harness/refinement.sh [OPTIONS] <module.tla>
#
# OPTIONS
#       --spec NAME        concrete spec operator            (default: Spec)
#       --refines NAME     module's refinement operator      (default: Refines)
#       --instance NAME    module's INSTANCE name       (default: auto-detect)
#       --abstract-init N  abstract's init predicate         (default: Init)
#       --abstract-vars N  abstract's vars tuple             (default: vars)
#       --abstract NAME    abstract MODULE; switches to a harness-supplied
#                          mapping and ignores the module's own
#       --with 'v <- e'    one mapping clause; repeatable; needs --abstract
#       --initial EXPR     pin the probe to this value of the abstract's vars
#                          tuple instead of using the abstract's Init
#       --constants FILE   .cfg fragment spliced into the generated config;
#                          CONSTANT / CONSTANTS lines ONLY
#   -t, --timeout SECS     wall-clock budget per TLC run     (default: 60)
#       --allow-implicit-mapping   permit INSTANCE with no WITH
#       --keep DIR         keep the staged directory, configs, logs and traces
#   -q, --quiet            do not print the verdict token
#   -h, --help             this text
#
# OUTPUT
#   stdout: the verdict token, one line (unless --quiet)
#   exit:   the code beside that token in the table below
#
# VERDICT TABLE
#
#     0  REFINES              the refinement holds AND the mapping moves
#    20  FROZEN_MAPPING       the mapping never leaves its initial value, so
#                             the refinement check proved nothing
#    21  NOT_CONFIGURED       Gate!RefinementConfigured fired: the .cfg never
#                             declared the refinement PROPERTY
#    22  REFINEMENT_VIOLATED  the concrete spec does not refine the abstract
#    23  THEOREM_ONLY         the refinement claim lives only in a THEOREM
#    24  UNSOUND_REDUCTION    SYMMETRY or VIEW requested on a temporal check
#    25  IMPLICIT_MAPPING     INSTANCE with no WITH clause
#    26  PROBE_MISDECLARED    the probe is violated in the INITIAL state
#    27  GATE_SHADOWED        the problem directory ships its own Gate.tla
#    28  FRAGMENT_REFUSED     the constants fragment carries a directive
#    29  RESERVED_NAME        the module defines a name the harness generates
#    30  REFINES_UNDEFINED    the refinement operator is not defined
#     *  <verdict.sh token>   any other TLC outcome, passed through unchanged
#                             with verdict.sh's own token and raw exit status
#
# TWO RUNS, NOT ONE — MEASURED, NOT ASSUMED
#
#   V2-PLAN.md §5.4 draws the .cfg with all three lines together:
#
#       SPECIFICATION Spec
#       PROPERTY  Refines
#       INVARIANT Probe
#
#   That config cannot certify a refinement. Measured on TLC 2026.03.04.183147
#   against fixtures/refinement/correct: rc=12, "4 states generated, 4 distinct
#   states found", search depth 4 — against a reachable space of 7 states. The
#   invariant violation stops the run, so the temporal property was never
#   evaluated over the three states that were never generated. A combined run
#   reports that the probe fired and nothing else.
#
#   So the two channels are two TLC invocations:
#
#     run A   SPECIFICATION Spec + PROPERTY <refines>
#             with -postCondition Gate!RefinementConfigured
#             expects rc=0
#
#     run B   SPECIFICATION Spec + INVARIANT HarnessProbe
#             with NO postcondition
#             expects rc=12, at a trace depth of at least 2
#
#   The guard belongs to run A alone. Attached to run B it fires on run B's
#   missing PROPERTY and MASKS the frozen verdict — measured: fixtures/
#   refinement/frozen returns rc=10 instead of the rc=0 that means FROZEN.
#
# THE TWO GUARDS CATCH DISJOINT FAILURES
#
#   | failure                          | RefinementConfigured | INVARIANT Probe |
#   |----------------------------------|----------------------|-----------------|
#   | no PROPERTY in the cfg           | FIRES  (rc=10)       | silent          |
#   | PROPERTY present, mapping frozen | silent (rc=0)        | FIRES  (rc=0)   |
#
#   Neither substitutes for the other, and the guard alone discriminates
#   nothing about the mapping: measured, it returns rc=10 for the correct and
#   the frozen mapping alike on a PROPERTY-less cfg, and rc=0 for both once the
#   PROPERTY is there. TLAiBench has only that first half, which is exactly why
#   a constant mapping scores a pass on it.
#
# WHY THE HARNESS OWNS THE .cfg, THE PROBE AND Gate.tla
#
#   TLAiBench lets the subject under evaluation author its own .cfg, and that
#   is HOW its trapdoor stays open — a submission that writes its own oracle
#   configuration can weaken its own grading. Here the .cfg is generated, never
#   read from the problem directory; the probe operator is generated under a
#   reserved name, never named from the module (a module-supplied probe is a
#   forgeable probe — see fixtures/refinement/forged-probe); and harness/Gate.tla
#   is copied in at staging time, with a problem directory that ships its own
#   Gate.tla refused outright.
#
# WE SUPPLY THE MAPPING AND GRADE ONLY THE CONCRETE SPEC
#
#   §4.4 item 9, from Lamport's *Hiding* §5: for ANY two specs, suitable
#   auxiliary variables make a refinement mapping exist. "X refines Y" is
#   therefore a fact about X, Y AND the mapping, and grading a submission that
#   supplies its own mapping grades a proposition the harness did not choose.
#   --abstract plus --with makes the harness author the mapping and ignore the
#   module's. Where the mapping IS the exercise, run without them — but then
#   grade by probe plus inspection, NEVER by TLC's verdict alone.
#
# OTHER TRAPS HANDLED HERE, ALL VERIFIED ON TLC 2026.03.04.183147
#
#   - The .cfg accepts ONLY BARE IDENTIFIERS. `PROPERTY A!Spec` exits 151 with
#     "Error: The property A specified in the configuration file is not defined
#     in the specification" — a message about `A`, not about `A!Spec`. Every
#     name this script writes into a .cfg is a bare identifier.
#   - THEOREM Spec => A!Spec DOES NOTHING. TLC silently ignores THEOREM; it is
#     TLAPS documentation. Verified against fixtures/refinement/theorem-only,
#     whose concrete spec genuinely does not refine: with the THEOREM and no
#     PROPERTY, rc=0, "No error has been found".
#   - SYMMETRY and VIEW make temporal checking UNSOUND (Specifying Systems
#     p.244, p.246: may "miss errors, report an error that doesn't exist, or
#     report a real error with an incorrect counterexample"). Refinement IS a
#     temporal property, so both are refused. The refusal must be static: an
#     unsound run still exits 0, and there is no verdict afterwards that would
#     tell you the answer was wrong.
#   - Omitting WITH is SILENT. Implicit same-name substitution gives a
#     different, usually wrong mapping, and TLC never mentions it. Refused
#     unless --allow-implicit-mapping. State the mapping even when it is the
#     identity.
#   - The abstract's `vars` tuple is substituted too, which is what makes the
#     default probe work: <instance>!Init is the abstract's initial predicate
#     AFTER substitution, i.e. a predicate over the mapped expressions. That is
#     "the mapped expression has not left its initial value" without the
#     harness having to know what the mapping was — so it works identically
#     whether the module or the harness supplied it.
#
# VERDICTS COME FROM EXIT CODES. Every TLC outcome here is read through
# harness/verdict.sh (§5.1). Nothing below matches text in TLC's console
# output. The two things this script does parse are its own generated files and
# the SUBMITTED MODULE'S SOURCE, which is a grading input, not a TLC verdict.

set -uo pipefail

REFINEMENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VERDICT_SH="$REFINEMENT_DIR/verdict.sh"
GATE_TLA="$REFINEMENT_DIR/Gate.tla"

# Names the harness generates. A module that defines one of these would have
# its definition win in the wrapper's EXTENDS, which is the forged-probe hole
# by another route, so defining one is refused rather than silently shadowed.
HARNESS_MODULE="RefHarness"
HARNESS_PROBE="HarnessProbe"
HARNESS_REFINES="HarnessRefines"
HARNESS_MAP="HarnessMap"

SPEC="Spec"
REFINES="Refines"
INSTANCE=""
ABSTRACT_INIT="Init"
ABSTRACT_VARS="vars"
ABSTRACT=""
WITHS=()
INITIAL=""
CONSTANTS=""
TIMEOUT=60
ALLOW_IMPLICIT=0
KEEP=""
QUIET=0
MODULE=""

usage() {
  cat <<'USAGE'
usage: harness/refinement.sh [OPTIONS] <module.tla>

      --spec NAME        concrete spec operator            (default: Spec)
      --refines NAME     module's refinement operator      (default: Refines)
      --instance NAME    module's INSTANCE name       (default: auto-detect)
      --abstract-init N  abstract's init predicate         (default: Init)
      --abstract-vars N  abstract's vars tuple             (default: vars)
      --abstract NAME    abstract MODULE; harness supplies the mapping
      --with 'v <- e'    one mapping clause; repeatable; needs --abstract
      --initial EXPR     pin the probe to this value of the vars tuple
      --constants FILE   .cfg fragment; CONSTANT / CONSTANTS lines ONLY
  -t, --timeout SECS     wall-clock budget per TLC run     (default: 60)
      --allow-implicit-mapping   permit INSTANCE with no WITH
      --keep DIR         keep the staged directory, configs, logs and traces
  -q, --quiet            do not print the verdict token
  -h, --help             this text

Prints one verdict token; exits with that token's code.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --spec)           SPEC="${2:-}"; shift 2 ;;
    --refines)        REFINES="${2:-}"; shift 2 ;;
    --instance)       INSTANCE="${2:-}"; shift 2 ;;
    --abstract-init)  ABSTRACT_INIT="${2:-}"; shift 2 ;;
    --abstract-vars)  ABSTRACT_VARS="${2:-}"; shift 2 ;;
    --abstract)       ABSTRACT="${2:-}"; shift 2 ;;
    --with)           WITHS+=("${2:-}"); shift 2 ;;
    --initial)        INITIAL="${2:-}"; shift 2 ;;
    --constants)      CONSTANTS="${2:-}"; shift 2 ;;
    -t|--timeout)     TIMEOUT="${2:-}"; shift 2 ;;
    --allow-implicit-mapping) ALLOW_IMPLICIT=1; shift ;;
    --keep)           KEEP="${2:-}"; shift 2 ;;
    -q|--quiet)       QUIET=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    -*)               echo "refinement.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$MODULE" ]; then
        echo "refinement.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      MODULE="$1"; shift ;;
  esac
done

[ -n "$MODULE" ] || { echo "refinement.sh: no module given" >&2; usage >&2; exit 2; }

if [ ${#WITHS[@]} -gt 0 ] && [ -z "$ABSTRACT" ]; then
  echo "refinement.sh: --with needs --abstract" >&2
  exit 2
fi

# Needed to read the counterexample trace on the probe run. Checked up front so
# a missing interpreter is a loud startup error rather than a wrong verdict
# three TLC runs later.
command -v python3 >/dev/null 2>&1 || {
  echo "refinement.sh: python3 is required to read the counterexample trace" >&2
  exit 2
}

[ -f "$VERDICT_SH" ] || { echo "refinement.sh: missing $VERDICT_SH" >&2; exit 2; }
[ -f "$GATE_TLA"  ] || { echo "refinement.sh: missing $GATE_TLA" >&2; exit 2; }

MODULE_DIR=$(cd "$(dirname "$MODULE")" && pwd)
MODULE_BASE=$(basename "$MODULE" .tla)

emit() {   # emit <token> <rc>
  [ "$QUIET" = "0" ] && echo "$1"
  exit "$2"
}

# ---------------------------------------------------------------------------
# TLA+ comment stripping.
#
# Every pattern below is anchored at the start of a line, which already skips
# TLA+'s two comment forms — a `\*` line comment and a boxed `(* ... *)` block
# both put a non-identifier character first. Stripping as well catches the
# residual case: an UNBOXED block comment whose interior lines start in column
# one. Known limitation, documented rather than fixed: TLA+ block comments
# nest, and this stripper does not, so `(* a (* b *) c *)` leaves ` c *)`
# visible. That leftover would have to look like a definition to matter.
# ---------------------------------------------------------------------------
strip_tla_comments() {
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

# ---------------------------------------------------------------------------
# One logical definition per output line.
#
# A TLA+ definition may wrap, and the corpus does wrap it:
#
#     A ==
#       INSTANCE Abstract
#         WITH level <- (ticks \div 3)
#
# Matching raw lines misses that INSTANCE entirely and then reports the stated
# mapping as an implicit one -- a wrong verdict on a correct submission. So
# every pattern below runs over definitions, not lines: accumulate from one
# column-zero definition head to the next.
#
# Limitation, documented rather than fixed: a definition head is recognised at
# column zero only. An indented top-level definition would be swallowed into
# its predecessor. TLA+ writes top-level definitions flush left and the whole
# corpus does; indented `==` belongs to LET or to a proof.
# ---------------------------------------------------------------------------
logical_defs() {
  awk '
    /^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*==/ ||
    /^[[:space:]]*(THEOREM|ASSUME|AXIOM|VARIABLE|VARIABLES|CONSTANT|CONSTANTS|LOCAL|EXTENDS|RECURSIVE)([[:space:]]|$)/ ||
    /^====/ {
      if (buf != "") print buf
      buf = $0
      next
    }
    { buf = buf " " $0 }
    END { if (buf != "") print buf }
  '
}

# ---------------------------------------------------------------------------
# STATIC REFUSALS — the traps that must never reach TLC.
#
# These come first because for two of them an unsound run still exits 0, so
# there would be no verdict to read afterwards.
# ---------------------------------------------------------------------------

# The problem directory may not ship the guard module. TLA+ resolves EXTENDS
# and INSTANCE against the root module's directory, so a Gate.tla beside the
# submission is the Gate.tla TLC loads, and every postcondition guard the
# harness thought it was running becomes whatever that file says. Staging
# overwrites it anyway; refusing says out loud that something tried.
if [ -e "$MODULE_DIR/Gate.tla" ]; then
  emit "GATE_SHADOWED" 27
fi
if [ -e "$MODULE_DIR/$HARNESS_MODULE.tla" ]; then
  emit "RESERVED_NAME" 29
fi

# The constants fragment is the only caller-supplied text that reaches the
# generated .cfg. It carries data — CONSTANT assignments — and never
# directives. SYMMETRY and VIEW are called out separately because they are not
# merely out of scope: Specifying Systems p.244 and p.246 record that both make
# temporal checking unsound, and refinement is a temporal property.
if [ -n "$CONSTANTS" ]; then
  [ -f "$CONSTANTS" ] || { echo "refinement.sh: no such fragment: $CONSTANTS" >&2; exit 2; }
  frag=$(sed 's/\\\*.*$//' "$CONSTANTS")
  # Every match in this file is a here-string, never `echo "$x" | grep -q`.
  # Under `set -o pipefail` grep -q exits at its first match, the producer takes
  # SIGPIPE, and the pipeline reports 141 -- which an `if` reads as "no match"
  # and a NEGATED `if !` reads as "match". Both directions are wrong and both
  # are live here: a 141 on the SYMMETRY/VIEW guard below would let an unsound
  # reduction through unflagged, and a 141 on the negated REFINES check further
  # down would refuse a module that is perfectly well-formed. The trigger is
  # whether the consumer exits before the producer finishes writing, so it is a
  # race on file size, not a threshold. Bead tla-kr9.
  if grep -qE '^[[:space:]]*(SYMMETRY|VIEW)([[:space:]]|$)' <<<"$frag"; then
    emit "UNSOUND_REDUCTION" 24
  fi
  if grep -qE '^[[:space:]]*(SPECIFICATION|INIT|NEXT|PROPERTY|PROPERTIES|INVARIANT|INVARIANTS|CONSTRAINT|CONSTRAINTS|ACTION_CONSTRAINT|ALIAS|POSTCONDITION|CHECK_DEADLOCK)([[:space:]]|$)' <<<"$frag"; then
    emit "FRAGMENT_REFUSED" 28
  fi
fi

# Module-text checks. Skipped when the file is not there: "that module is
# missing" is a verdict TLC issues (150), and short-circuiting it here would
# substitute this script's opinion for the channel the harness is built on.
SRC=""
if [ -f "$MODULE" ]; then
  SRC=$(strip_tla_comments "$MODULE" | logical_defs)

  for reserved in "$HARNESS_PROBE" "$HARNESS_REFINES" "$HARNESS_MAP"; do
    if grep -qE "^[[:space:]]*$reserved[[:space:]]*==" <<<"$SRC"; then
      emit "RESERVED_NAME" 29
    fi
  done

  if [ -z "$ABSTRACT" ]; then
    # The module supplies the mapping. Find its INSTANCE.
    if [ -z "$INSTANCE" ]; then
      mapfile -t found < <(
        grep -oE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*==[[:space:]]*INSTANCE[[:space:]]' <<<"$SRC" |
        sed -E 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*).*/\1/')
      case ${#found[@]} in
        1) INSTANCE="${found[0]}" ;;
        0) echo "refinement.sh: no INSTANCE found in $MODULE; pass --instance" >&2; exit 2 ;;
        *) echo "refinement.sh: ${#found[@]} INSTANCEs in $MODULE; pass --instance" >&2; exit 2 ;;
      esac
    fi

    # Omitting WITH is silent, so the shape is refused rather than the mapping
    # judged. One grep suffices because the definition has already been
    # reassembled onto a single line, wrap and all.
    if [ "$ALLOW_IMPLICIT" = "0" ]; then
      stmt=$(grep -E "^[[:space:]]*$INSTANCE[[:space:]]*==[[:space:]]*INSTANCE[[:space:]]" <<<"$SRC")
      if ! grep -qE '(^|[^A-Za-z0-9_])WITH([^A-Za-z0-9_]|$)' <<<"$stmt"; then
        emit "IMPLICIT_MAPPING" 25
      fi
    fi

    # The refinement operator has to exist, because the .cfg accepts only bare
    # identifiers and `PROPERTY A!Spec` fails with a message about `A`.
    if ! grep -qE "^[[:space:]]*$REFINES[[:space:]]*==" <<<"$SRC"; then
      # §10: TLC silently ignores THEOREM. A submission whose refinement claim
      # lives only there has stated it to a reader and to nobody else.
      if grep -qE '^[[:space:]]*THEOREM([[:space:]]|$)' <<<"$SRC" &&
         grep -qE '=>' <<<"$SRC"; then
        emit "THEOREM_ONLY" 23
      fi
      emit "REFINES_UNDEFINED" 30
    fi
  else
    # The harness supplies the mapping. State it even when it is the identity.
    if [ ${#WITHS[@]} -eq 0 ] && [ "$ALLOW_IMPLICIT" = "0" ]; then
      emit "IMPLICIT_MAPPING" 25
    fi
  fi
fi

[ -n "$INSTANCE" ] || INSTANCE="A"
[ -z "$ABSTRACT" ] || INSTANCE="$HARNESS_MAP"

# ---------------------------------------------------------------------------
# STAGING — the harness's own copy of the world.
#
# The problem directory's modules are copied out and harness/Gate.tla is copied
# in on top, so the guard TLC loads is the harness's whichever way the problem
# directory is arranged. No .cfg is copied: the config is generated below and
# a stray one beside the submission is never read.
# ---------------------------------------------------------------------------
if [ -n "$KEEP" ]; then
  STAGE="$KEEP"; mkdir -p "$STAGE"; CLEAN=0
else
  STAGE=$(mktemp -d -t tla_refinement.XXXXXX); CLEAN=1
fi
cleanup() { [ "$CLEAN" = "1" ] && rm -rf "$STAGE"; }
trap cleanup EXIT

cp "$MODULE_DIR"/*.tla "$STAGE"/ 2>/dev/null
cp "$GATE_TLA" "$STAGE"/Gate.tla

# The wrapper. It EXTENDS the submission, so the concrete spec is reached
# unmodified and the probe is defined where the .cfg can name it as a bare
# identifier.
#
# The probe is <instance>!<abstract-init>: the abstract's initial predicate
# AFTER substitution, which is a predicate over the mapped expressions. It
# needs no per-problem data and it cannot be supplied by the module, so the
# probe is enforced on every invocation by construction rather than by a flag
# somebody could forget.
#
# --initial swaps in the exact-value form for an abstract with more than one
# initial state, where "still satisfies Init" is weaker than "has not moved".
# The default errs toward reporting FROZEN_MAPPING on a mapping that wanders
# among abstract initial states — a false FAIL, never a false PASS.
if [ -n "$INITIAL" ]; then
  PROBE_BODY="$INSTANCE!$ABSTRACT_VARS = ($INITIAL)"
else
  PROBE_BODY="$INSTANCE!$ABSTRACT_INIT"
fi

{
  printf -- '------------------------------ MODULE %s ------------------------------\n' "$HARNESS_MODULE"
  printf -- '\\* Generated by harness/refinement.sh. Not part of any submission.\n'
  printf -- 'EXTENDS %s\n' "$MODULE_BASE"
  if [ -n "$ABSTRACT" ]; then
    joined=$(printf '%s, ' "${WITHS[@]}"); joined=${joined%, }
    if [ -n "$joined" ]; then
      printf -- '%s == INSTANCE %s WITH %s\n' "$HARNESS_MAP" "$ABSTRACT" "$joined"
    else
      printf -- '%s == INSTANCE %s\n' "$HARNESS_MAP" "$ABSTRACT"
    fi
    printf -- '%s == %s!%s\n' "$HARNESS_REFINES" "$HARNESS_MAP" "$SPEC"
  fi
  printf -- '%s == %s\n' "$HARNESS_PROBE" "$PROBE_BODY"
  printf -- '=========================================================================\n'
} > "$STAGE/$HARNESS_MODULE.tla"

if [ -n "$ABSTRACT" ]; then PROP="$HARNESS_REFINES"; else PROP="$REFINES"; fi

CFG_A="$STAGE/run-a.cfg"
CFG_B="$STAGE/run-b.cfg"
printf 'SPECIFICATION %s\nPROPERTY %s\n' "$SPEC" "$PROP" > "$CFG_A"
printf 'SPECIFICATION %s\nINVARIANT HarnessProbe\n' "$SPEC" > "$CFG_B"

if [ -n "$CONSTANTS" ]; then
  cat "$CONSTANTS" >> "$CFG_A"
  cat "$CONSTANTS" >> "$CFG_B"
fi

ROOT="$STAGE/$HARNESS_MODULE.tla"

# ---------------------------------------------------------------------------
# RUN A — does it refine, and was the check configured at all?
# ---------------------------------------------------------------------------
va=$(bash "$VERDICT_SH" --config "$CFG_A" --timeout "$TIMEOUT" \
       --postcondition "Gate!RefinementConfigured" \
       --log "$STAGE/run-a.log" --trace "$STAGE/run-a.json" \
       --scratch "$STAGE/scratch-a" "$ROOT" 2>/dev/null)
rca=$?

case "$rca" in
  0)  ;;
  10) emit "NOT_CONFIGURED" 21 ;;
  13) emit "REFINEMENT_VIOLATED" 22 ;;
  *)  emit "$va" "$rca" ;;
esac

# ---------------------------------------------------------------------------
# RUN B — THE PROBE. Run A has already said the refinement holds; this run is
# what decides whether that meant anything.
#
# NO POSTCONDITION HERE. Run B's .cfg has no PROPERTY, so
# Gate!RefinementConfigured would fire by construction and mask the verdict —
# measured: fixtures/refinement/frozen returns rc=10 instead of rc=0.
# ---------------------------------------------------------------------------
vb=$(bash "$VERDICT_SH" --config "$CFG_B" --timeout "$TIMEOUT" \
       --log "$STAGE/run-b.log" --trace "$STAGE/run-b.json" \
       --scratch "$STAGE/scratch-b" "$ROOT" 2>/dev/null)
rcb=$?

case "$rcb" in
  # THE WHOLE POINT. TLC could not violate the probe, so the mapped expression
  # never left its initial value and run A's rc=0 was discharged by stuttering.
  0)  emit "FROZEN_MAPPING" 20 ;;
  12) ;;
  *)  emit "$vb" "$rcb" ;;
esac

# A violation at the initial state is not movement. It means the declared
# --initial value was never the initial value, and the rc=12 that looks exactly
# like a healthy moving mapping came from the probe being wrong. Unreachable on
# the default probe, where the abstract's own Init is used and run A has already
# checked the implied init; this guards the --initial override.
depth=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        print(len(json.load(f)["counterexample"]["state"]))
except Exception:
    print(-1)
' "$STAGE/run-b.json")

if [ "$depth" -lt 0 ]; then
  echo "refinement.sh: probe violated but no readable trace at $STAGE/run-b.json" >&2
  exit 2
fi
if [ "$depth" -le 1 ]; then
  emit "PROBE_MISDECLARED" 26
fi

emit "REFINES" 0
