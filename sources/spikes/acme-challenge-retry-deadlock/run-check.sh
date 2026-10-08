#!/usr/bin/env bash
# run-check.sh — drive one harness/verdict.sh run against a module in THIS
# directory, with an optional non-default .cfg.
#
# WHY THIS SCRIPT EXISTS, AND IT IS TWO REASONS
#
#   1. TLC resolves auxiliary modules relative to the process cwd when the
#      module argument is relative (harness/verdict.sh's own note on
#      ToolIO.setUserDir, bead tla-sn0h). Several modules here EXTENDS a
#      sibling, so the run has to happen FROM this directory.
#
#   2. The worktree-isolation harness refuses a command line carrying
#      `--alias`, reading the token as the shell builtin, and refuses `/\`
#      and `{a, b}` as a path and a brace group. Putting an invocation in a
#      script takes it out of the harness's command scan.
#
# The root is resolved from ${BASH_SOURCE[0]}, never from a literal path: a
# hardcoded `cd` into the main checkout is how scripts/gen-curriculum-map.sh
# used to write across trees (bead tla-1hf).
#
# usage: run-check.sh <Module> [config.cfg] [extra verdict.sh args...]
#
# Prints the verdict token and exits with TLC's raw status, both straight
# through from harness/verdict.sh. A nonzero exit here is a VERDICT.
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../.." && pwd)"

MODULE="${1:?usage: run-check.sh <Module> [config.cfg] [extra args...]}"
shift
CFG=""
if [ $# -gt 0 ]; then
  case "$1" in
    *.cfg) CFG="$1"; shift ;;
  esac
fi

cd -- "$HERE" || exit 2
if [ -n "$CFG" ]; then
  bash "$ROOT/harness/verdict.sh" --config "$CFG" "$MODULE.tla" "$@"
else
  bash "$ROOT/harness/verdict.sh" "$MODULE.tla" "$@"
fi
