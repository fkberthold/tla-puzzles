#!/usr/bin/env bash
# Print the counterexample for each clause each broken server breaks.
#
#   bash sources/spikes/imap-move-partial-failure/run-traces.sh
#
# The exit code is the verdict and the trace text is a description of a run
# that already ended, which is the same bargain harness/spike-measure.sh
# strikes over its state counts. Nothing here decides a pass or a fail from
# what TLC printed.
#
# TWO THINGS WORTH KNOWING BEFORE YOU READ A TRACE OUT OF THIS.
#
# `-config` overrides the module's own config, so the clause configs set the
# message count whatever the module name says. MCDecomposed2 run under
# clause3-both.cfg is a 3-message model, and the module name is then only
# telling you which server. Every run below uses a 1-message config so the
# traces stay short.
#
# `-noGenerateSpecTE` matters. Without it every violated run writes a
# <Module>_TTrace_<timestamp>.tla beside the module, and a spike directory
# collects one per run.
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

trace() {
  local module="$1" cfg="$2" note="$3" rc
  printf '\n### %s under %s\n%s\n\n' "$module" "$cfg" "$note"
  set +e
  tlc -workers 1 -cleanup -noGenerateSpecTE -metadir "$META" -config "$cfg" "$module" \
    > ".trace-out" 2>&1
  rc=$?
  set -e
  printf 'rc=%s\n' "$rc"
  sed -n '/^Error: /,/states generated/p' ".trace-out"
  rm -f ".trace-out"
}

trace MCDecomposed1 clause1-both.cfg \
  'The duplicate. Clause 3 breaks on the first COPY, and clause 2 holds
everywhere in this server, so the safety floor is intact while the
preference is gone. This is Thunderbird bug 610131.'

trace MCDecomposed1 clause1-moved.cfg \
  'The same state against clause 1. A non-atomic move breaks the MUST at the
same step it breaks the SHOULD NOT.'

trace MCExpungeFirst1 clause1-lost.cfg \
  'The loss. Clause 2 breaks when the source copy goes before the target copy
lands, and clause 3 holds everywhere in this server.'

trace ProbeStoreFirst1 probe1-ClauseOneIsNoStronger.cfg \
  'Clause 1 failing ALONE. Clauses 2 and 3 both hold in this state, so clause 1
is strictly stronger than their conjunction and is not a third name for the
same two things.'

# The next two run against the CONFORMING server, where all three clauses
# hold. They are refutations of claims about the model rather than violations
# of a requirement, which is why the server they run on is the correct one.
trace ProbeAtomic probe-NoMixedOutcome.cfg \
  'THE MODELLING CHOICE, refuted. One message finished and left behind while
another finished and moved. A model that stopped at the first failure could
not reach this, and its outcomes would be prefixes of the set.'

trace ProbeAtomic probe-NoMeansNothingHappened.cfg \
  'The tagged NO, refuted. The command answers NO with a message already
moved, which is what the paragraph means by "This is true even if the server
returns a tagged NO response to the command".'
