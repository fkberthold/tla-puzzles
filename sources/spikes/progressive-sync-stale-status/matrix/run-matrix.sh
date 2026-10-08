#!/usr/bin/env bash
# Drive harness/seeded-bugs.sh over this matrix.
#
# A script rather than a command line because seeded-bugs.sh takes `--alias`
# and the worktree-isolation harness refuses any command line containing that
# token -- it reads it as the shell `alias` builtin.  The documented
# workaround is exactly this (.claude/rules/dispatched-agents.md, lineage bead
# tla-kl5.8).
#
# Repo root resolved from BASH_SOURCE, never a literal path (bead tla-1hf).
#
# Run:  bash run-matrix.sh [Submission|SubmissionNoTypeOK]
#       bash run-matrix.sh            # both, in that order

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"

grade() {
  local prop="$1" rc
  printf '\n######## submission: %s ########\n\n' "$prop"
  set +e
  ( cd "$ROOT" && bash harness/seeded-bugs.sh \
      --matrix "$HERE" \
      --oracle "$HERE/oracle/Oracle.tla" \
      --alias Alias \
      --timeout 60 \
      "$HERE/$prop.tla" )
  rc=$?
  set -e
  printf '\n######## %s : seeded-bugs.sh rc=%s ########\n' "$prop" "$rc"
}

if [ "$#" -gt 0 ]; then
  grade "$1"
else
  grade SubmissionNoTypeOK
  grade Submission
fi
