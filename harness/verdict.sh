#!/usr/bin/env bash
# verdict.sh — The harness's single verdict channel (V2-PLAN.md §5.1, bead tla-kl5.4).
#
# Runs TLC once and reports what happened as ONE TOKEN DERIVED SOLELY FROM THE
# PROCESS EXIT STATUS. Nothing in this file reads, matches, or reasons about
# TLC's stdout. Every other harness component (§5.2 grading, §5.3 vacuity
# probes, §5.4 refinement, §5.5 seeded bugs) branches on this token, so this
# is the one place the exit-code table lives.
#
# WHY NOT STDOUT: TLC's console text is a presentation surface, not an API. It
# changes between releases, it is localized by nothing and formatted by whim,
# and its phrases overlap (a spec can print "Finished in" after a fatal parse
# error). scripts/verify-puzzle.sh's elif-chain of greps is the cautionary
# tale: it matched "Finished in" on a spec that never parsed and reported a
# PASS. Exit codes do not have that failure mode.
#
# USAGE
#   harness/verdict.sh [OPTIONS] <module.tla> [-- <extra tlc args>...]
#
# OPTIONS
#   -c, --config FILE       .cfg to use (default: <module>.cfg beside the module)
#   -t, --timeout SECS      wall-clock budget (default: 60)
#   -p, --postcondition E   TLC -postCondition expression, e.g. Gate!NonVacuous
#   -d, --check-deadlock    check for deadlock (default: OFF -- see below)
#       --trace FILE        keep the JSON counterexample trace here
#       --log FILE          keep TLC's combined output here (for HUMANS and for
#                           witness extraction -- never for verdicts)
#       --scratch DIR       metadir parent; created if absent, kept if given
#   -q, --quiet             suppress the verdict token on stdout
#   -h, --help              this text
#
# OUTPUT
#   stdout: the verdict token, one line (unless --quiet)
#   exit:   TLC's RAW exit status, unmodified, so callers may branch on either
#           the token or the number. NOTE for callers under `set -e`: a
#           nonzero exit here is a VERDICT, not a crash; capture it with
#           `out=$(verdict.sh ...) || rc=$?` or disable errexit around it.
#
# VERDICT TABLE — every row measured on the TLC 2026.03.04.183147 nightly on
# 2026-08-06 by driving a purpose-built fixture in fixtures/verdict/, then
# re-measured unchanged on tla2tools v1.8.0 (TLC 2026.07.31.184830) on
# 2026-08-07. Two builds four months apart return the same numbers, so this
# table is a fact about TLC rather than about one jar. Do not edit a row
# without re-running harness/test-verdict.sh; the test asserts the raw
# numbers, not just the tokens, precisely so that a renumbered TLC breaks the
# build instead of quietly relabelling itself.
#
#     0  OK                  no error found
#    10  ASSUMPTION_FAILED   ASSUME false, or -postCondition false
#    11  DEADLOCK            reachable state with no successor
#    12  SAFETY_VIOLATION    INVARIANT violated
#    13  LIVENESS_VIOLATION  PROPERTY violated (incl. refinement, §5.4)
#   124  TIMEOUT             killed by timeout(1) -- its OWN verdict
#   150  PARSE_ERROR         parse or semantic failure, incl. a missing .tla
#   151  CONFIG_ERROR        .cfg names something the spec does not define
#   255  TLC_EXCEPTION       TLC's catch-all: missing/unparseable .cfg, etc.
#     *  UNKNOWN_<rc>        never silently folded into an existing row
#
# DEPARTURES FROM THE V2-PLAN.md §5.1 TABLE, all measured, all deliberate:
#
#   §5.1 lists 255 as "file not found". Measured, the two halves of "file not
#   found" split across two codes: a missing MODULE is 150 (SANY reports
#   "Cannot find source file"), while a missing CONFIG is 255. And 255 is not
#   specific to missing files at all -- a .cfg containing garbage tokens, or a
#   duplicated SPECIFICATION line, also exits 255 via the same
#   ConfigFileException catch-all. Naming that token FILE_NOT_FOUND would make
#   the tutor tell a learner with a typo'd .cfg that their file is missing, so
#   the token here is TLC_EXCEPTION and the §5.1 row is recorded as one
#   instance of it rather than as its definition.
#
#   §5.1 lists 151 as "config failure" without qualification. Measured, 151 is
#   only the SEMANTIC half: the .cfg parsed but names an operator the spec
#   does not define. Config SYNTAX failures are 255 (above), and a .cfg
#   keyword with a missing operand -- e.g. a bare `INVARIANT` line -- is not an
#   error at all: TLC exits 0 having silently checked no invariant. That last
#   one is a live vacuity hazard for §5.3, and DanglingKeyword.cfg pins it.
#
# WORKER COUNT — -workers 1 IS MANDATORY AND IS NOT AN OPTION HERE.
#
#   Counterexamples are nondeterministic above one worker: five runs at
#   -workers 8 produced three different traces. Any harness output that IS a
#   trace -- a grading witness, a seeded-bug counterexample, a refinement
#   failure -- is therefore unreproducible unless the worker count is pinned.
#
#   The distinction that matters, because it is what tempts people to "fix"
#   this: state COUNTS are stable. They were measured identical across workers
#   1/4/8, across three fingerprint polynomials, and across TLC 2.15 through
#   2026.03.04 -- and the counts this suite asserts were unchanged again on
#   2026.07.31. So the constraint bites ONLY where a trace is the output --
#   and since this script cannot know which caller wants a trace, it pins the
#   worker count for all of them. If you are here to raise it for speed:
#   raising it is correct only for a caller that consumes counts and never
#   traces, and that caller does not exist yet. Do not add a flag for it
#   without one.

set -uo pipefail

TIMEOUT=60
CONFIG=""
POSTCOND=""
CHECK_DEADLOCK=0
TRACE=""
LOG=""
SCRATCH=""
QUIET=0
MODULE=""
EXTRA=()

usage() {
  cat <<'USAGE'
usage: harness/verdict.sh [OPTIONS] <module.tla> [-- <extra tlc args>...]

  -c, --config FILE        .cfg to use (default: <module>.cfg)
  -t, --timeout SECS       wall-clock budget (default: 60)
  -p, --postcondition EXPR TLC -postCondition expression
  -d, --check-deadlock     check for deadlock (default: off)
      --trace FILE         keep the JSON counterexample trace
      --log FILE           keep TLC's combined output
      --scratch DIR        metadir parent
  -q, --quiet              do not print the verdict token
  -h, --help               this text

Prints one verdict token; exits with TLC's raw status.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--config)         CONFIG="${2:-}"; shift 2 ;;
    -t|--timeout)        TIMEOUT="${2:-}"; shift 2 ;;
    -p|--postcondition)  POSTCOND="${2:-}"; shift 2 ;;
    -d|--check-deadlock) CHECK_DEADLOCK=1; shift ;;
    --trace)             TRACE="${2:-}"; shift 2 ;;
    --log)               LOG="${2:-}"; shift 2 ;;
    --scratch)           SCRATCH="${2:-}"; shift 2 ;;
    -q|--quiet)          QUIET=1; shift ;;
    -h|--help)           usage; exit 0 ;;
    --)                  shift; EXTRA=("$@"); break ;;
    -*)                  echo "verdict.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$MODULE" ]; then
        echo "verdict.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      MODULE="$1"; shift ;;
  esac
done

if [ -z "$MODULE" ]; then
  echo "verdict.sh: no module given" >&2
  usage >&2
  exit 2
fi

# Deliberately NO existence check on the module or the .cfg. "That file is not
# there" is a verdict TLC issues (150 and 255 respectively), and short-
# circuiting it here would substitute this script's opinion for the channel the
# whole harness is built on.
MODULE_DIR=$(dirname "$MODULE")
MODULE_BASE=$(basename "$MODULE" .tla)
if [ -z "$CONFIG" ]; then
  CONFIG="$MODULE_DIR/$MODULE_BASE.cfg"
fi

# Scratch holds the metadir (TLC's states/ tree) and, unless the caller asked
# to keep it, the trace and the log. Keeping all three out of the spec's own
# directory is what lets fixtures stay pristine across runs.
CLEAN_SCRATCH=0
if [ -z "$SCRATCH" ]; then
  SCRATCH=$(mktemp -d -t tla_verdict.XXXXXX)
  CLEAN_SCRATCH=1
else
  mkdir -p "$SCRATCH"
fi
cleanup() {
  if [ "$CLEAN_SCRATCH" = "1" ]; then
    rm -rf "$SCRATCH"
  fi
}
trap cleanup EXIT

[ -z "$TRACE" ] && TRACE="$SCRATCH/trace.json"
[ -z "$LOG" ]   && LOG="$SCRATCH/tlc.log"

# The canonical invocation of V2-PLAN.md §5.1.
#
#   -workers 1          pinned; see the WORKER COUNT note in the header
#   -noGenerateSpecTE   suppress the *_TTrace_*.tla spillage on violations
#   -nowarning          keep the log readable for humans
#   -coverage 1         §5.3 dead-action detection needs the per-action counts
#   -dumpTrace json     counterexamples as data, not as console text
#   -metadir            TLC's states/ tree, into scratch, never beside the spec
#
# TLC's -deadlock flag means "do NOT check for deadlock", so the flag is
# present by DEFAULT and --check-deadlock is what removes it. That inversion
# has bitten this project before; the flag name here is the one that reads
# correctly at the call site.
CMD=(tlc
  -workers 1
  -noGenerateSpecTE
  -nowarning
  -coverage 1
  -dumpTrace json "$TRACE"
  -metadir "$SCRATCH/states")

if [ "$CHECK_DEADLOCK" = "0" ]; then
  CMD+=(-deadlock)
fi
if [ -n "$POSTCOND" ]; then
  CMD+=(-postCondition "$POSTCOND")
fi
CMD+=("$MODULE" -config "$CONFIG")
if [ ${#EXTRA[@]} -gt 0 ]; then
  CMD+=("${EXTRA[@]}")
fi

# The one and only place the outcome is produced. TLC's output goes to a file
# and is never inspected; `rc` is the entire signal.
timeout "$TIMEOUT" "${CMD[@]}" >"$LOG" 2>&1
rc=$?

case "$rc" in
  0)   verdict="OK" ;;
  10)  verdict="ASSUMPTION_FAILED" ;;
  11)  verdict="DEADLOCK" ;;
  12)  verdict="SAFETY_VIOLATION" ;;
  13)  verdict="LIVENESS_VIOLATION" ;;
  124) verdict="TIMEOUT" ;;
  150) verdict="PARSE_ERROR" ;;
  151) verdict="CONFIG_ERROR" ;;
  255) verdict="TLC_EXCEPTION" ;;
  # An unmapped code is reported as itself rather than bucketed into the
  # nearest familiar row. A new TLC exit code should surface as a loud unknown,
  # not as a plausible-looking wrong answer.
  *)   verdict="UNKNOWN_$rc" ;;
esac

if [ "$QUIET" = "0" ]; then
  echo "$verdict"
fi

exit "$rc"
