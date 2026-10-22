#!/usr/bin/env bash
# Run every snippet under this directory and check it produced the exit code
# the language reference claims it produces. A snippet whose rc drifts is a
# reference page that has started lying.
#
#   ./run-all.sh          run everything
#   ./run-all.sh -v       print full TLC output for failures
#
# ---------------------------------------------------------------------------
# THE CASE LIST IS DISCOVERED, NEVER WRITTEN HERE.
#
# One directory per reference page, each holding that page's modules, its cfgs
# and a CASES manifest. This runner globs */CASES and carries no list of its
# own, so a page author adds a directory and touches nothing shared.
#
# Bead tla-x1wr, and the reason was parallelism rather than taste. The first
# version held a single hardcoded CASES array, and the seven pages still to be
# authored under tla-9y4s would all have edited the same twelve lines. Under
# loom's splitting heuristic two beads can go in one wave only when their file
# sets are disjoint, so one shared array serialized the whole epic.
#
# It is also the third time this project has met the hand-kept list.
# scripts/build-docs.sh:697 already carries the lesson: "THE PAGE LIST IS
# DERIVED, NEVER WRITTEN ... a hand-kept list is right until somebody adds a
# chapter, and then it is silently wrong with every gate still green." Bead
# tla-llf5 is filed against chapter/snippets/check-blocks.py for the same
# defect, where its page list is a two-element tuple.
#
# Same shape as chapter/snippets/run-all.sh, and deliberately a separate copy.
# That file's cases carry the refinement chapter's claims and these carry the
# language reference's. A shared runner would make one tree's failure read as
# the other's.
#
# Exit codes TLC uses here:
#   0    all checks passed
#   12   an invariant was violated
#   13   a temporal or action property was violated
#   150  parse or semantic error in the module
#   151  the .cfg named something the module does not define
# ---------------------------------------------------------------------------
cd "$(dirname "$0")" || exit 1

verbose=0
[ "$1" = "-v" ] && verbose=1

# A GLOB THAT MATCHES NOTHING MUST REDDEN. An empty run exiting 0 is
# indistinguishable from a clean one, which is the hole bead tla-d64i closed in
# scripts/lint on the day this tree was named.
shopt -s nullglob
manifests=(*/CASES)
shopt -u nullglob

if [ "${#manifests[@]}" -eq 0 ]; then
  echo "run-all.sh: no */CASES manifest under $(pwd)" >&2
  echo "  Refusing to report success over an empty set." >&2
  exit 2
fi

pass=0
fail=0
families=0

for manifest in "${manifests[@]}"; do
  family="${manifest%/CASES}"
  families=$((families + 1))
  fam_cases=0

  echo "== ${family} =="

  # Read the manifest fully before running anything, so the loop body is free
  # to cd without disturbing the read.
  lines="$(cat "$manifest")"

  while IFS= read -r line; do
    # Trim both ends, then skip blanks and comments.
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac

    IFS='|' read -r mod cfg want states what <<< "$line"
    if [ -z "$mod" ] || [ -z "$cfg" ] || [ -z "$want" ]; then
      printf 'FAIL  malformed case in %s: %s\n' "$manifest" "$line"
      fail=$((fail + 1))
      continue
    fi
    fam_cases=$((fam_cases + 1))

    out=$(cd "$family" && tlc -workers 1 -config "$cfg" "$mod" 2>&1)
    got=$?
    rm -f "$family"/*_TTrace_*.tla "$family"/*_TTrace_*.bin 2>/dev/null

    if [ "$got" != "$want" ]; then
      printf 'FAIL  rc=%-3s (want %s) %-20s %-20s %s\n' "$got" "$want" "$mod" "$cfg" "$what"
      [ "$verbose" = 1 ] && echo "$out"
      fail=$((fail + 1))
      continue
    fi

    # THE FOURTH FIELD IS THE STATE COUNT, and it is not decoration. The
    # modules page quotes a distinct-state count in three places and in two of
    # them the count IS the finding: 16 states against 4 is the whole
    # difference between two tanks and one tank under two names. Both runs
    # exit 0, so an rc-only suite would stay green while the page went wrong.
    # An empty field means the page quotes no count for this case.
    if [ -n "$states" ]; then
      if ! grep -qE "(^|, )$states distinct states found" <<<"$out"; then
        printf 'FAIL  rc=%-3s states!=%-4s %-20s %-20s %s\n' "$got" "$states" "$mod" "$cfg" "$what"
        grep -E 'distinct states found' <<<"$out" || true
        [ "$verbose" = 1 ] && echo "$out"
        fail=$((fail + 1))
        continue
      fi
    fi

    printf 'ok    rc=%-3s %-6s %-20s %-20s %s\n' "$got" "${states:+$states st}" "$mod" "$cfg" "$what"
    pass=$((pass + 1))
  done <<<"$lines"

  # A MANIFEST WITH NO CASES IS THE SAME LIE ONE LEVEL DOWN. A page author who
  # adds a directory and leaves the manifest as comments would otherwise get a
  # green run over nothing.
  if [ "$fam_cases" -eq 0 ]; then
    echo "run-all.sh: ${manifest} declares no case." >&2
    fail=$((fail + 1))
  fi
done

echo
echo "$pass passed, $fail failed, over $families family manifest(s)"
[ "$fail" -eq 0 ] || exit 1
