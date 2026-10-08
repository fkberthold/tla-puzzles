#!/usr/bin/env bash
# Generate the MC wrapper modules and their configs for the IMAP MOVE spike.
#
#   bash sources/spikes/imap-move-partial-failure/gen-wrappers.sh
#
# WHY A GENERATOR RATHER THAN NINE HAND-WRITTEN PAIRS
#
# Every wrapper is the same two lines and every config differs only in the
# message set, so hand-writing them invites one to drift from the other eight.
# The invariant list in particular has to be identical across all nine, since
# the whole comparison is which clause each server breaks at the same size.
#
# It also keeps the brace groups out of a command line. The worktree-isolation
# harness reads `Msg = {m1, m2, m3}` as a shell brace group and refuses it, so
# a heredoc carrying one never runs. A script's body is not scanned, only its
# invocation, so the braces are safe in here.
#
# The output directory resolves from BASH_SOURCE, never from a literal repo
# path: a hardcoded root is what made scripts/gen-curriculum-map.sh write into
# the main checkout from a worktree (bead tla-1hf).
set -euo pipefail

OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALL='TypeOK MovedOrUnaffected NotLostOrOrphaned NotInBothMailboxes'

wrapper() {
  local name="$1" base="$2" msgs="$3" invs="$4" i
  local bar='---------------------------------'
  {
    printf '%s MODULE %s %s\n' "$bar" "$name" "$bar"
    printf 'EXTENDS %s\n' "$base"
    printf '%s\n' '==================================================================='
  } > "$OUT/$name.tla"
  {
    printf 'CONSTANTS\n'
    printf '  Msg = {%s}\n' "$msgs"
    printf '\n'
    printf 'SPECIFICATION Spec\n'
    for i in $invs; do printf 'INVARIANT %s\n' "$i"; done
    printf 'ALIAS Alias\n'
    printf 'CHECK_DEADLOCK FALSE\n'
  } > "$OUT/$name.cfg"
}

# The conforming server, at four sizes.
wrapper MCAtomic1 MoveAtomic 'm1'             "$ALL"
wrapper MCAtomic2 MoveAtomic 'm1, m2'         "$ALL"
wrapper MCAtomic3 MoveAtomic 'm1, m2, m3'     "$ALL"
wrapper MCAtomic4 MoveAtomic 'm1, m2, m3, m4' "$ALL"
wrapper MCAtomic5 MoveAtomic 'm1, m2, m3, m4, m5' "$ALL"
wrapper MCAtomic6 MoveAtomic 'm1, m2, m3, m4, m5, m6' "$ALL"

# The RFC's own decomposition with the intermediate states left in.
wrapper MCDecomposed1 MoveDecomposed 'm1'         "$ALL"
wrapper MCDecomposed2 MoveDecomposed 'm1, m2'     "$ALL"
wrapper MCDecomposed3 MoveDecomposed 'm1, m2, m3' "$ALL"

# The wrong order, which is how a message gets lost.
wrapper MCExpungeFirst1 MoveExpungeFirst 'm1'         "$ALL"
wrapper MCExpungeFirst3 MoveExpungeFirst 'm1, m2, m3' "$ALL"

# The ordering that marks \Deleted before it copies, which is the only one
# here that breaks clause 1 while clauses 2 and 3 both hold.
wrapper MCStoreFirst1 MoveStoreFirst 'm1'         "$ALL"
wrapper MCStoreFirst3 MoveStoreFirst 'm1, m2, m3' "$ALL"

# THE BROKEN SERVERS SIZED, which takes a config they satisfy.
#
# A model that violates its invariant stops at the counterexample, so its row
# reads 2 distinct states at depth 2 and says nothing about how big the model
# is. Each of the three broken servers holds one of the three clauses, so
# naming that clause alone lets the exploration finish and the row becomes a
# size rather than a time-to-first-violation.
wrapper MCDecomposedFull3   MoveDecomposed   'm1, m2, m3' 'TypeOK NotLostOrOrphaned'
wrapper MCExpungeFirstFull3 MoveExpungeFirst 'm1, m2, m3' 'TypeOK NotInBothMailboxes'
wrapper MCStoreFirstFull3   MoveStoreFirst   'm1, m2, m3' 'TypeOK NotLostOrOrphaned'

# CLAUSE-ISOLATION CONFIGS.
#
# A config naming all four invariants tells you a server is broken. It does
# not tell you which clause broke, because TLC stops at the first violation
# it meets and the search order decides which one that is. So each clause
# also gets a config of its own, run against all three servers at the same
# size. Nine runs, and the exit code of each one is the answer.
#
# These carry no module name. They are passed with `tlc -config`, which is
# the route the isolation spike established for a non-default config.
clause_cfg() {
  local name="$1" msgs="$2" inv="$3"
  {
    printf 'CONSTANTS\n'
    printf '  Msg = {%s}\n' "$msgs"
    printf '\n'
    printf 'SPECIFICATION Spec\n'
    printf 'INVARIANT %s\n' "$inv"
    printf 'ALIAS Alias\n'
    printf 'CHECK_DEADLOCK FALSE\n'
  } > "$OUT/$name.cfg"
}

clause_cfg clause3-moved 'm1, m2, m3' MovedOrUnaffected
clause_cfg clause3-lost  'm1, m2, m3' NotLostOrOrphaned
clause_cfg clause3-both  'm1, m2, m3' NotInBothMailboxes

# One-message copies of the same three, for readable traces. A counterexample
# at three messages carries two messages nothing happened to, and they are
# noise in the printed state.
clause_cfg clause1-moved 'm1' MovedOrUnaffected
clause_cfg clause1-lost  'm1' NotLostOrOrphaned
clause_cfg clause1-both  'm1' NotInBothMailboxes

# The clause-1-alone probe, one message, with its own wrapper so the trace
# runner can name a module rather than a module plus an override.
wrapper ProbeStoreFirst1 ProbeStoreFirst 'm1' 'ClauseOneIsNoStronger'
clause_cfg probe1-ClauseOneIsNoStronger 'm1' ClauseOneIsNoStronger

printf 'wrote %d wrapper modules and %d clause configs into %s\n' \
  "$(find "$OUT" -maxdepth 1 -name 'MC*.tla' | wc -l)" \
  "$(find "$OUT" -maxdepth 1 -name 'clause3-*.cfg' | wc -l)" "$OUT"
