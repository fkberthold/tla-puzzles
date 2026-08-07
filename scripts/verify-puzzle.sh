#!/usr/bin/env bash
# verify-puzzle.sh — Verify a puzzle's solution by running pcal + the harness
# verdict channel in a scratch directory.
#
# Usage:  scripts/verify-puzzle.sh <puzzle-dir>
#         scripts/verify-puzzle.sh puzzles/T01-the-light-switch
#
# Env:    TIMEOUT=<secs>      wall-clock budget per module (default 60)
#         VERBOSE=1           print the model checker's log on a failure
#         CHECK_DEADLOCK=1    enable deadlock checking (default: OFF, see below)
#
# Exit:   0 if every (.tla, .cfg) pair in solution/ verified
#         1 if any pair failed
#         2 on usage error
#
# Output: one line per (.tla, .cfg) pair, format:
#           <verdict>  <puzzle>/<module>
#
# ---------------------------------------------------------------------------
# VERDICTS COME FROM THE EXIT CODE. NOTHING HERE READS THE CONSOLE.
#
# This script used to classify by matching an elif-chain of phrases against the
# model checker's stdout. That is the anti-pattern V2-PLAN.md §5.1 exists to
# kill, and it was not theoretical here: measured 2026-08-07 against the old
# chain, a spec with a failing ASSUME and a spec whose .cfg named an undefined
# operator BOTH came out as a PASS with exit 0, because no phrase in the chain
# matched and the catch-all fallback did. Console text is a presentation
# surface that overlaps and reworders between releases; the exit status is an
# API.
#
# So the whole model-checker invocation is delegated to harness/verdict.sh,
# which is the one place the exit-code table lives (bead tla-kl5.4, 21 pinned
# assertions in harness/test-verdict.sh). This script only maps that table onto
# the v1 verdict vocabulary below. Do not re-add a classification branch here;
# add the row to verdict.sh, where it is measured.
#
#   rc    verdict.sh token       this script reports
#   ----  ---------------------  ----------------------------------------------
#     0   OK                     PASS-CLEAN      clean model check
#    10   ASSUMPTION_FAILED      FAIL-ASSUME     ASSUME or -postCondition false
#    11   DEADLOCK               PASS-OTHER      deadlock-by-design puzzles
#    12   SAFETY_VIOLATION       PASS-VIOLATION  invariant counterexample
#    13   LIVENESS_VIOLATION     PASS-VIOLATION  temporal/action counterexample
#    75   (none — see below)     PASS-VIOLATION  under-constrained successor
#   124   TIMEOUT                FAIL-TIMEOUT    ran past $TIMEOUT
#   150   PARSE_ERROR            FAIL-TLC        parse/semantic, incl. missing .tla
#   151   CONFIG_ERROR           FAIL-TLC        .cfg names what the spec lacks
#   255   TLC_EXCEPTION          FAIL-TLC        unparseable .cfg, and other catch-all
#     *   UNKNOWN_<rc>           FAIL-TLC        never folded into a PASS row
#
# Plus two verdicts this script produces without ever reaching the model
# checker: FAIL-PCAL (the PlusCal translator refused the source) and SKIP.
#
# ---------------------------------------------------------------------------
# rc=75 IS NOT IN verdict.sh's TABLE, AND THAT IS A GAP, NOT A DECISION HERE.
#
# The pinned jar's own enum, read directly rather than inferred —
#   javap -cp ~/lib/tla2tools.jar -constants 'tlc2.output.EC$ExitStatus'
# — carries six codes §5.1 never enumerated: VIOLATION_ASSERT=14,
# FAILURE_SPEC_EVAL=75, FAILURE_SAFETY_EVAL=76, FAILURE_LIVENESS_EVAL=77,
# ERROR_STATESPACE_TOO_LARGE=152, ERROR_SYSTEM=153.
#
# 75 is not hypothetical: the v1 corpus hits it today. T29's Clock_buggy leaves
# minutes' unconstrained in one branch of an IF, so TLC cannot complete the
# successor state, prints a trace and exits 75. That is precisely the defect the
# puzzle is built to demonstrate, so v1's verdict for it is PASS-VIOLATION and
# this mapping keeps it.
#
# 76 and 77 are deliberately NOT mapped alongside it. Nothing in the corpus
# exercises them, and guessing a sibling code into a PASS row is the same error
# as guessing from console text. They fall through to FAIL-TLC until measured.
#
# ---------------------------------------------------------------------------
# -workers 1 IS PINNED, AND IT IS PINNED IN verdict.sh, NOT HERE.
#
# Counterexamples are nondeterministic above one worker: five runs at
# -workers 8 produced three different traces. State COUNTS are stable across
# worker counts — that is the distinction, and it is what tempts people to
# raise the worker count "for speed". Raising it is safe only for a caller that
# consumes counts and never traces. This script prints a verdict derived from a
# trace-producing run, so it is not that caller.
#
# The pin is inherited, and it is inherited only for as long as this script
# never launches the model checker itself. scripts/test-verify-puzzle.sh gates
# exactly that: a structural assertion that no direct invocation reappears here.
#
# ---------------------------------------------------------------------------
# DEADLOCK CHECKING IS OFF BY DEFAULT, as it has always been in this script.
#
# The v1 corpus contains specs that terminate, and terminating specs deadlock by
# definition. Turning the check on by default would fail them. CHECK_DEADLOCK=1
# opts in per run; harness/verdict.sh's --check-deadlock is what it maps to.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VERDICT_SH="$REPO_ROOT/harness/verdict.sh"

PUZZLE_DIR="${1:-}"
if [ -z "$PUZZLE_DIR" ] || [ ! -d "$PUZZLE_DIR/solution" ]; then
  echo "usage: $0 <puzzle-dir>  (must contain solution/)" >&2
  exit 2
fi

if [ ! -x "$VERDICT_SH" ]; then
  echo "$0: harness/verdict.sh missing or not executable at $VERDICT_SH" >&2
  exit 2
fi

TIMEOUT="${TIMEOUT:-60}"
VERBOSE="${VERBOSE:-0}"
CHECK_DEADLOCK="${CHECK_DEADLOCK:-0}"

PUZZLE_NAME=$(basename "$PUZZLE_DIR")
SOLUTION_DIR="$PUZZLE_DIR/solution"

# Per-puzzle opt-out: presence of solution/.verify-skip means standard
# verification isn't the right gate (e.g., T64 teaches -simulate mode for
# intractable state spaces). The file's first line is the skip reason.
if [ -f "$SOLUTION_DIR/.verify-skip" ]; then
  reason=$(head -1 "$SOLUTION_DIR/.verify-skip" 2>/dev/null)
  printf "%-18s %s  (%s)\n" "SKIP" "$PUZZLE_NAME" "${reason:-no reason given}"
  exit 0
fi

# Collect (.tla, .cfg) pairs to verify.
# Skip: Apalache.tla (shim, no cfg), _TTrace_*.tla (trace dumps).
PAIRS=()
while IFS= read -r tla; do
  base=$(basename "$tla" .tla)
  case "$base" in
    Apalache|*_TTrace_*) continue ;;
  esac
  cfg="$SOLUTION_DIR/$base.cfg"
  if [ -f "$cfg" ]; then
    PAIRS+=("$base")
  fi
done < <(find "$SOLUTION_DIR" -maxdepth 1 -name "*.tla" | sort)

if [ ${#PAIRS[@]} -eq 0 ]; then
  echo "SKIP            $PUZZLE_NAME  (no .tla/.cfg pairs found)"
  exit 0
fi

overall_rc=0

for module in "${PAIRS[@]}"; do
  scratch=$(mktemp -d -t verify_puzzle.XXXXXX)
  trap 'rm -rf "$scratch"' EXIT

  # Copy every .tla in solution/ so helper modules referenced via EXTENDS or
  # INSTANCE (e.g., OrderStates, Counter, AbstractCard, Apalache shim) resolve.
  # Without this, multi-module specs fail parse with "Cannot find source
  # file ...", which is rc=150 and lands in FAIL-TLC.
  cp "$SOLUTION_DIR"/*.tla "$scratch/"
  cp "$SOLUTION_DIR/$module.cfg" "$scratch/"

  verdict="UNKNOWN"

  # Run pcal only if the file contains --algorithm. This is a grep over a FILE,
  # not over a captured stream, so it is neither the banned SIGPIPE idiom nor a
  # verdict: it is a routing decision about which translator to run.
  if grep -q -- "--algorithm" "$scratch/$module.tla"; then
    pcal_out=$(cd "$scratch" && pcal "$module.tla" 2>&1)
    pcal_rc=$?
    if [ "$pcal_rc" -ne 0 ]; then
      verdict="FAIL-PCAL"
      [ "$VERBOSE" = "1" ] && echo "$pcal_out" >&2
    fi
  fi

  if [ "$verdict" = "UNKNOWN" ]; then
    VERDICT_ARGS=(--timeout "$TIMEOUT" --log "$scratch/model.log" --quiet)
    if [ "$CHECK_DEADLOCK" = "1" ]; then
      VERDICT_ARGS+=(--check-deadlock)
    fi

    # The log is written for humans and for VERBOSE below. It is never read to
    # decide anything: `rc` is the entire signal.
    (cd "$scratch" && "$VERDICT_SH" "${VERDICT_ARGS[@]}" "$module.tla" --config "$module.cfg")
    rc=$?

    case "$rc" in
      0)   verdict="PASS-CLEAN" ;;
      11)  verdict="PASS-OTHER" ;;
      12|13|75) verdict="PASS-VIOLATION" ;;
      10)  verdict="FAIL-ASSUME" ;;
      124) verdict="FAIL-TIMEOUT" ;;
      # 150 / 151 / 255 are the parse, semantic-config and catch-all rows. An
      # unmapped code joins them rather than being guessed into a PASS: a new
      # exit code must surface as a failure, not as a plausible-looking success.
      *)   verdict="FAIL-TLC" ;;
    esac

    if [ "$VERBOSE" = "1" ] && [ "${verdict#FAIL-}" != "$verdict" ]; then
      echo "--- $PUZZLE_NAME/$module: exit $rc ---" >&2
      cat "$scratch/model.log" >&2
    fi
  fi

  printf "%-18s %s/%s\n" "$verdict" "$PUZZLE_NAME" "$module"
  case "$verdict" in
    FAIL-*) overall_rc=1 ;;
  esac

  rm -rf "$scratch"
  trap - EXIT
done

exit "$overall_rc"
