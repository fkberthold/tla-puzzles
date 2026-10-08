#!/usr/bin/env bash
# Run each clause against each server and print the exit-code matrix.
#
#   bash sources/spikes/imap-move-partial-failure/run-clauses.sh
#
# Three clauses by three servers is nine runs, and the exit code of each one
# is the whole answer: 0 means the clause held over the server's reachable
# states, 12 means it did not. Nothing here reads TLC's prose, which
# V2-PLAN.md section 5.1 forbids.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

# TLC writes its metadata into ./states, which would otherwise collect in a
# directory somebody has to commit. -metadir puts it in a temp tree that goes
# away with the script.
META="$(mktemp -d)"
trap 'rm -rf "$META"' EXIT

printf 'clause\tserver\trc\n'
for clause in moved lost both; do
  for server in MCAtomic3 MCDecomposed3 MCExpungeFirst3 MCStoreFirst3; do
    set +e
    tlc -workers 1 -cleanup -noGenerateSpecTE -metadir "$META" -config "clause3-$clause.cfg" "$server" >/dev/null 2>&1
    rc=$?
    set -e
    printf '%s\t%s\t%s\n' "$clause" "$server" "$rc"
  done
done
