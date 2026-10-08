#!/usr/bin/env bash
# Drive harness/seeded-bugs.sh over this spike's matrix.
#
# WHY THIS IS A SCRIPT AND NOT A COMMAND LINE: the isolation harness refuses
# any command line containing the token `--alias`, reading it as the shell
# `alias` builtin, and seeded-bugs.sh takes `--alias NAME` after the .cfg
# keyword. Lineage: bead tla-kl5.8, which hit the same wall.
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../../.." && pwd)"

set +e
bash "$ROOT/harness/seeded-bugs.sh" \
    --matrix "$HERE" \
    --spec Spec \
    --property Inv \
    --alias Alias \
    --timeout 120 \
    "$HERE/submission/Submitted.tla"
rc=$?
set -e
printf '\nrc=%s\n' "$rc"
