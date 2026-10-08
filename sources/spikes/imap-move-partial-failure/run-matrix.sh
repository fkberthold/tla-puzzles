#!/usr/bin/env bash
# Run the seeded-bug matrix.
#
#   bash sources/spikes/imap-move-partial-failure/run-matrix.sh [submission.tla]
#
# With no argument it grades the author's own three-clause property, which is
# the one the rest of the spike checks. Pass a module to grade something else.
#
# THIS IS A SCRIPT BECAUSE OF --alias.
#
# The worktree-isolation harness reads the token `--alias` as the shell alias
# builtin and refuses the command line, so the invocation cannot be typed
# directly. The flag is named after the .cfg keyword and is not going to be
# renamed. Lineage: bead tla-kl5.8.
#
# AND BECAUSE --reference IS NOT OPTIONAL HERE.
#
# seeded-bugs.sh resolves a matrix's reference by finding the sole .tla in
# reference/, and this reference is two modules: MoveAtomic EXTENDS MoveBase.
# So --reference names the root and --matrix supplies the rest.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
M="$HERE/matrix"

SUBMISSION="${1:-$M/oracle/Oracle.tla}"

bash "$ROOT/harness/seeded-bugs.sh" \
  --matrix "$M" \
  --reference "$M/reference/MoveAtomic.tla" \
  --alias Alias \
  --property Inv \
  "$SUBMISSION"
