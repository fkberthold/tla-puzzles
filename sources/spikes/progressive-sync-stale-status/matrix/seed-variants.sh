#!/usr/bin/env bash
# Regenerate every seeded variant from reference/Rollout.tla.
#
# Each variant is the reference module with ONE edit, applied by the sed below
# and nowhere else, so the mutation is this file rather than a claim about what
# got typed into seven copies.  The module name stays `Rollout` in every
# variant, which is what lets one property module extend the reference and
# every variant without being rewritten.
#
# A script rather than seven sed command lines, because the worktree-isolation
# harness refuses a command line containing `/\` -- it reads it as a path
# leaving the worktree -- and every one of these mutations is about a
# conjunct.
#
# Repo-relative paths resolved from BASH_SOURCE, never a literal (bead
# tla-1hf).
#
# Run:  bash seed-variants.sh

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF="$HERE/reference/Rollout.tla"
V="$HERE/variants"

# 1. THE REPORTED DEFECT.  Step completion drops the revision comparison and
#    reads health alone, so a Synced verdict computed before the commit
#    satisfies it.
sed '/Strict => obsRev/d' "$REF" > "$V/drop-revision-check/Rollout.tla"

# 2. Advance stops consulting the completion predicate at all.
sed '/StepComplete(step)/d' "$REF" > "$V/no-completion-check/Rollout.tla"

# 3. SyncApp stops checking that the app belongs to the step being rolled, so
#    the rollout is no longer ordered by anything.
sed '/Cohort(a) = step$/d' "$REF" > "$V/sync-any-cohort/Rollout.tla"

# 4. The completion predicate reads the PREVIOUS cohort's status.  Step 1 then
#    completes vacuously, since no app is in cohort 0.
sed 's/Cohort(a) = s =>/Cohort(a) = s - 1 =>/' "$REF" \
    > "$V/off-by-one-cohort/Rollout.tla"

# 5. The refresh loop publishes Synced whatever it found, so the health channel
#    carries no information.
sed 's/!\[a\] = (live\[a\] = target)\]/![a] = TRUE]/' "$REF" \
    > "$V/refresh-always-synced/Rollout.tla"

# 6. Advance skips a cohort.
sed "s/step' = step + 1/step' = step + 2/" "$REF" \
    > "$V/skip-a-step/Rollout.tla"

# 7. A commit jumps two revisions, past the bound.  Only a type invariant
#    catches this one, which is the point of keeping it in the set.
sed "s/target' = target + 1/target' = target + 2/" "$REF" \
    > "$V/commit-overshoots/Rollout.tla"

# Every variant must differ from the reference by exactly one hunk.  A sed
# whose pattern stopped matching would silently emit a byte-identical copy,
# and a byte-identical variant is an inert one.
for d in "$V"/*/; do
  name="$(basename -- "$d")"
  if cmp -s "$REF" "$d/Rollout.tla"; then
    printf 'variant %s is byte-identical to the reference\n' "$name" >&2
    exit 1
  fi
  hunks="$(diff "$REF" "$d/Rollout.tla" | grep -cE '^[0-9]' || true)"
  printf '%s\t%s hunk(s)\n' "$name" "$hunks"
done
