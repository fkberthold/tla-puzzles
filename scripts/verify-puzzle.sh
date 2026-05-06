#!/usr/bin/env bash
# verify-puzzle.sh — Verify a puzzle's solution by running pcal+tlc in scratch.
#
# Usage:  scripts/verify-puzzle.sh <puzzle-dir>
#         scripts/verify-puzzle.sh puzzles/T01-the-light-switch
#
# Exit:   0 if every (.tla, .cfg) pair in solution/ runs successfully
#         1 if any pair fails (pcal error, TLC unexpected exception, or timeout)
#
# Output: one line per (.tla, .cfg) pair, format:
#           <verdict>  <puzzle>/<module>
#         where verdict is one of:
#           PASS-CLEAN              TLC reported "No error has been found"
#           PASS-VIOLATION          TLC reported a counterexample (deliberate-violation puzzle)
#           PASS-OTHER              TLC completed without crash (deadlock-by-design, etc.)
#           FAIL-PCAL               pcal could not translate the PlusCal source
#           FAIL-TLC                TLC threw an unexpected exception (parse error, etc.)
#           FAIL-TIMEOUT            TLC ran past the timeout
#         Set VERBOSE=1 to print full pcal+tlc output on failure.

set -uo pipefail

PUZZLE_DIR="${1:-}"
if [ -z "$PUZZLE_DIR" ] || [ ! -d "$PUZZLE_DIR/solution" ]; then
  echo "usage: $0 <puzzle-dir>  (must contain solution/)" >&2
  exit 2
fi

TIMEOUT="${TIMEOUT:-60}"
VERBOSE="${VERBOSE:-0}"

PUZZLE_NAME=$(basename "$PUZZLE_DIR")
SOLUTION_DIR="$PUZZLE_DIR/solution"

# Per-puzzle opt-out: presence of solution/.verify-skip means standard TLC
# verification isn't the right gate (e.g., T64 teaches -simulate mode for
# intractable state spaces). The file's first line is the skip reason.
if [ -f "$SOLUTION_DIR/.verify-skip" ]; then
  reason=$(head -1 "$SOLUTION_DIR/.verify-skip" 2>/dev/null)
  printf "%-18s %s  (%s)\n" "SKIP" "$PUZZLE_NAME" "${reason:-no reason given}"
  exit 0
fi

# Collect (.tla, .cfg) pairs to verify.
# Skip: Apalache.tla (shim, no cfg), _TTrace_*.tla (TLC trace dumps).
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
  # Without this, multi-module specs fail TLC parse with "Cannot find source
  # file ..." which the classifier below now catches as FAIL-TLC.
  cp "$SOLUTION_DIR"/*.tla "$scratch/"
  cp "$SOLUTION_DIR/$module.cfg" "$scratch/"

  verdict="UNKNOWN"

  # Run pcal only if the file contains --algorithm.
  if grep -q -- "--algorithm" "$scratch/$module.tla"; then
    pcal_out=$(cd "$scratch" && pcal "$module.tla" 2>&1)
    pcal_rc=$?
    if [ "$pcal_rc" -ne 0 ]; then
      verdict="FAIL-PCAL"
      [ "$VERBOSE" = "1" ] && echo "$pcal_out" >&2
    fi
  fi

  if [ "$verdict" = "UNKNOWN" ]; then
    tlc_out=$(cd "$scratch" && timeout "$TIMEOUT" tlc -deadlock "$module.tla" -config "$module.cfg" 2>&1)
    tlc_rc=$?
    if [ "$tlc_rc" = "124" ]; then
      verdict="FAIL-TIMEOUT"
    elif echo "$tlc_out" | grep -q "Error: TLC threw an unexpected exception"; then
      verdict="FAIL-TLC"
      [ "$VERBOSE" = "1" ] && echo "$tlc_out" >&2
    elif echo "$tlc_out" | grep -qE "Cannot find source file|Parsing or semantic analysis failed|Fatal errors while parsing"; then
      verdict="FAIL-TLC"
      [ "$VERBOSE" = "1" ] && echo "$tlc_out" >&2
    elif echo "$tlc_out" | grep -q "Model checking completed. No error has been found"; then
      verdict="PASS-CLEAN"
    elif echo "$tlc_out" | grep -qE "Trace exploration|Error: (Invariant|Temporal property|Action property)"; then
      verdict="PASS-VIOLATION"
    elif echo "$tlc_out" | grep -q "Finished in"; then
      verdict="PASS-OTHER"
    else
      verdict="FAIL-TLC"
      [ "$VERBOSE" = "1" ] && echo "$tlc_out" >&2
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
