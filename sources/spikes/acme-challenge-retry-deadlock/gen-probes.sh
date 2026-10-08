#!/usr/bin/env bash
# gen-probes.sh — write one .cfg per vacuity probe.
#
# A probe asserts something the model should refute. Each file here names ONE
# invariant, so a refutation is attributable: a probe .cfg with two invariants
# tells you only that one of them failed.
#
# Generated rather than hand-written because the CONSTANTS block is identical
# in all of them and a hand-copied constant that drifts is a probe measuring a
# different model from the one it claims to.
#
# The root is resolved from ${BASH_SOURCE[0]}, never from a literal path.
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# The Challenge and Minimal families take ClearOnSuccess; Wedged does not,
# because a failed query is terminal there and a success can never follow one.
emit() {
  local name="$1" inv="$2" note="$3" family="${4:-challenge}" maxq="${5:-2}"
  {
    printf '\\* PROBE: %s\n' "$note"
    printf 'SPECIFICATION Spec\n'
    printf 'INVARIANT %s\n' "$inv"
    printf 'CHECK_DEADLOCK FALSE\n\n'
    printf 'CONSTANTS\n'
    printf '    Pending = Pending\n'
    printf '    Processing = Processing\n'
    printf '    Valid = Valid\n'
    printf '    Invalid = Invalid\n'
    printf '    MaxQueries = %s\n' "$maxq"
    if [ "$family" = "challenge" ]; then
      printf '    ClearOnSuccess = FALSE\n'
    fi
  } > "$HERE/$name"
}

# Probes against Challenge.tla. Every one should be refuted.
emit probe-processing.cfg  NeverProcessing  'the client can respond and validation can begin'
emit probe-valid.cfg       NeverValid       'a successful validation query is reachable'
emit probe-invalid.cfg     NeverInvalid     'the give-up decision is reachable'
emit probe-gaveup.cfg      NeverGaveUp      'the gaveUp flag is actually set by something'
emit probe-clientasks.cfg  ClientNeverAsks  'the client-initiated retry action fires'
emit probe-error.cfg       NoErrorEver      'section 8.2 error-writing fires at all'
emit probe-twoerrors.cfg   ErrorsNeverTwo   'errors accumulate, one per failed query'
emit probe-query.cfg       NoQueryEver      'a first validation query happens'

# Probes against Wedged.tla, where the headline verdict is an rc=0. These are
# the ones that matter most: a model that moved nowhere would satisfy
# NeverTwoQueries too.
emit wedged-probe-processing.cfg NeverProcessing 'the wedged model does leave pending' wedged
emit wedged-probe-invalid.cfg    NeverInvalid    'the wedged model does reach invalid' wedged
emit wedged-probe-query.cfg      NoQueryEver     'a FIRST query happens; the wedge is on the SECOND' wedged
emit wedged-probe-error.cfg      NoErrorEver     'section 8.2 error-writing fires in the wedged model' wedged
emit wedged-probe-valid.cfg      NeverValid      'the success path is still open in the wedged model' wedged
emit wedged-probe-clientasks.cfg ClientNeverAsks 'the client-retry action is not dead' wedged

count="$(find "$HERE" -maxdepth 1 -name 'probe-*.cfg' -o -maxdepth 1 -name 'wedged-probe-*.cfg' | wc -l)"
printf 'wrote %s probe configs\n' "$count"
