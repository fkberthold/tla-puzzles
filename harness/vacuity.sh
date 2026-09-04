#!/usr/bin/env bash
# vacuity.sh — The harness's vacuity probes (V2-PLAN.md §5.3, bead tla-kl5.6).
#
# Closes the trap where a spec that models NOTHING scores full marks. Every
# TLC run goes through harness/verdict.sh (§5.1), so this file never invokes
# tlc directly and never reads TLC's prose for a verdict.
#
# USAGE
#   harness/vacuity.sh [OPTIONS] <module.tla>
#
# OPTIONS
#   -c, --config FILE     .cfg to use (default: <module>.cfg beside the module)
#   -n, --min-states N    NonVacuous threshold (REQUIRED, no default)
#   -t, --timeout SECS    per-probe wall-clock budget (default 60)
#   -e, --expect KIND     which member of the configured-check guard family to
#                         run: invariant (default) | refinement | none
#       --expect-actions NAME[,NAME...]
#                         action names the problem requires. An action MISSING
#                         from the coverage block is reported as dead, which is
#                         the only way a DELETED action can be caught at all.
#       --no-dead-actions skip the dead-action probe
#       --observe NAME    an observation operator the problem defines. Every
#                         field of it that never changes anywhere in the
#                         reachable state space is reported. OPT-IN: with no
#                         --observe nothing is looked for, and the summary
#                         says so.
#       --keep-logs DIR   keep each probe's TLC log here
#   -q, --quiet           print the verdict token only, no remediation
#   -h, --help            this text
#
# OUTPUT
#   stdout line 1: the verdict token
#   stdout line 2+: learner-facing remediation (suppressed by --quiet)
#
# VERDICT TABLE
#     0  NON_VACUOUS            every probe passed
#     2  USAGE                  bad arguments
#     3  VACUOUS_EMPTY_SPACE    vector 1 — no reachable states, or too few
#     4  VACUOUS_UNCHECKED      vector 2 — healthy space, nothing checked
#     5  VACUOUS_DEAD_ACTION    vector 3 — an action never fired
#     6  PROBE_INCONCLUSIVE     the spec never ran; not a vacuity verdict
#     7  VACUOUS_UNSATISFIABLE  vector 4 — Spec admits no behaviour at all
#     8  VACUOUS_FROZEN_OBSERVE vector 5 — a field of the observation never
#                                          changes anywhere in the space
#
#   The codes are deliberately disjoint from TLC's own (0/10/11/12/13/124/
#   150/151/255) so a caller can never confuse a vacuity verdict with a
#   model-checking one.
#
# FIVE VECTORS, AND WHY ONE VERDICT WOULD NOT DO
#
#   They are not variants of each other. They have disjoint causes and need
#   disjoint remediation, so each gets its own token and its own message. All
#   three numbers below were measured on the TLC 2026.03.04.183147 nightly
#   against the fixtures in fixtures/vacuity/, and re-measured unchanged on
#   tla2tools v1.8.0 (TLC 2026.07.31.184830); test-vacuity.sh re-measures them
#   on whatever build you are running.
#
#   1. EMPTY STATE SPACE. An unsatisfiable Init yields "No error has been
#      found", "0 states generated", and rc=0. DEADLOCK CHECKING DOES NOT
#      CATCH IT -- there is no reachable state to deadlock in. Caught by the
#      -inv FALSE smoke test (rc=0 means the space is empty; rc=12 means
#      states exist) and by -postCondition Gate!NonVacuous, which fires
#      correctly even at 0 initial states.
#
#   2. EMPTY OBLIGATION OVER A HEALTHY STATE SPACE. A .cfg keyword with no
#      operand is not an error. `SPECIFICATION Spec` plus a bare `INVARIANT`
#      line makes TLC report success at rc=0 having checked no invariant at
#      all.
#
#      NonVacuous PASSES THIS. Measured: the dangling-keyword cfg over
#      Healthy.tla exits 0 under Gate!NonVacuous, because the state space is
#      perfectly healthy -- 5 distinct states. It is not the state space that
#      is empty, it is the CHECKING. Gate!InvariantConfigured is what catches
#      it (rc=10 on the dangling keyword, rc=0 on a real invariant).
#
#      The two guards are disjoint in BOTH directions, which is why both run:
#      InvariantConfigured exits 0 on the empty-Init fixture, because that
#      spec's .cfg does name a real invariant. Neither guard subsumes the
#      other; dropping either one opens a hole.
#
#   3. DEAD ACTIONS. Via -coverage 1, THE PREDICATE IS `total == 0`, NEVER
#      `distinct == 0`. An action can fire and discover nothing new. PlusCal
#      emits `Terminating == pc = "Done" /\ UNCHANGED vars` into every
#      terminating algorithm, and it reports 0:1 -- zero distinct, one total
#      -- because a stutter step re-finds the state it started in. Keying on
#      distinct therefore flags essentially every PlusCal submission.
#      fixtures/vacuity/TerminatingPcal.tla holds that line.
#
#      AND THE PREDICATE HAS A SECOND SHAPE IT CANNOT SEE ON ITS OWN. TLC
#      prints one coverage row per disjunct of Next. An action RESTRICTED by a
#      guard that is never true is still a disjunct, so it gets a row reading
#      0 total and `total == 0` matches it. An action DELETED from Next is not
#      a disjunct, so it gets NO ROW AT ALL and there is nothing to match --
#      the run ends reporting that every action fired, which is false.
#      Deletion is invisible to any predicate over the rows that are there,
#      however the predicate is written. The only way to notice something
#      absent is to know what to expect, so --expect-actions takes the names
#      and the probe reports any of them the block never mentions.
#      fixtures/vacuity/DeletedAction.tla holds that shape.
#
#   4. AN UNSATISFIABLE Spec. A fairness conjunct on an action Next does not
#      allow demands a step the next-state relation forbids, so NO behaviour
#      satisfies Spec and every temporal obligation holds over nothing.
#
#      THE FIRST THREE PROBES ARE ALL BLIND TO IT BY CONSTRUCTION. Fairness
#      does not touch the state graph -- it constrains the behaviours over
#      that graph -- so the space is healthy, NonVacuous passes,
#      InvariantConfigured passes, and every action that IS in Next reports a
#      non-zero total. Only the liveness half goes blind, and it goes blind at
#      rc=0 reporting success. fixtures/vacuity/UnsatFairness.tla holds it,
#      and LiveFairness.tla is the same module with the disjunct restored.
#
#   5. A FROZEN OBSERVATION. The specification is healthy and every action
#      fires, but the operator a problem's obligations are stated over holds
#      one value in a field for the whole run. The window is painted shut, and
#      an obligation read through it holds for the same reason an obligation
#      over an empty state space holds.
#
#      THE MODEL NEVER BREAKS HERE, WHICH IS WHY THE FIRST FOUR PROBES ARE ALL
#      BLIND. fixtures/vacuity/ObserveLattice.tla is the shape in miniature:
#      16 distinct states on every row, all four actions firing on every row,
#      Spec satisfiable on every row, and the only thing that varies is how
#      many of Observe's four fields pass the motion through.
#
#      AND THE FIELD IS THE ALTITUDE, NOT THE RECORD. 5.4 states the probe
#      idiom for a refinement mapping at harness/refinement.sh:22-25 -- assert
#      that the mapped expression never leaves its initial value, and require
#      TLC to refute it -- and that idiom is right for a mapping, which either
#      moves or does not. An observation record is a lattice of 2^n subsets,
#      and a whole-record probe sits at the top of it. Measured on v1.8.0:
#
#        one field frozen      whole-record probe rc=12  -> "moves", MISS
#        three fields frozen   whole-record probe rc=12  -> "moves", MISS
#        all four frozen       whole-record probe rc=0   -> FROZEN, caught
#
#      One of sixteen subsets, and it is the subset a learner is least likely
#      to write. Bead tla-29m4.
#
# HOW THE FROZEN-OBSERVE PROBE AVOIDS COMPARING ANYTHING
#
#   A per-field probe has to decide whether a field's values are all the same,
#   and the obvious way to ask is to compare the field against its initial
#   value. THAT IS UNSOUND ON A HETEROGENEOUS FIELD. TLC does not return FALSE
#   when the two sides of a comparison have different types, it ABORTS the
#   evaluation, and an aborted probe reports nothing about the field next to
#   the one that killed it. Measured at rc=76 SAFETY_EVAL_FAILURE on
#   fixtures/vacuity/ObserveMixedType.tla, whose `phase` field holds 0, 1 and
#   "closed" across the reachable space.
#
#   THE HAZARD IS LATENT RATHER THAN LOUD, so measuring once gives the wrong
#   answer. The same comparison against the initial value answers correctly on
#   that fixture, at rc=12, because `phase` leaves 0 for 1 before it ever
#   reaches "closed" and TLC stops at the first violation. Hand it a spec
#   whose heterogeneous field holds its initial value longest and it is the
#   rc=76 above.
#
#   So this probe COMPARES NOTHING IN TLA+. It prints one line per field per
#   state, as `<<"VACUITY_OBSERVE", field, value>>`, from an invariant that is
#   always true so exploration runs to completion, and the distinct-value
#   count is done in awk over the log. A field with one distinct printed value
#   never changed. Printing has no type discipline to violate, so the abort
#   above has nothing to fire on. Measured on ObserveMixedType: rc=0, `phase`
#   at three values, `ledger` at one.
#
#   VIEW plus a distinct-count postcondition would need no comparison either,
#   and it is the route NOT taken: VIEW prunes exploration, so it can
#   under-count a field's values and report a healthy submission FROZEN. A
#   false FROZEN is the one direction this gate must not fail in.
#
#   READING THE LOG IS THE SAME BARGAIN THE DEAD-ACTION PROBE STRUCK. What is
#   extracted is a marker this script printed itself, in a format it chose, and
#   the run's validity still comes from verdict.sh's rc. No TLC prose decides
#   anything.
#
#   THE COST IS ONE FULL EXPLORATION PLUS ONE PRINTED LINE PER FIELD PER STATE.
#   That is cheap on a submission the state-count floor will pass and expensive
#   on a large one, so the flag is opt-in and the probe runs last.
#
# HOW THE SATISFIABILITY PROBE IS INJECTED, AND WHY NOT THE WAY PROBE 1 IS
#
#   Probe 1 injects its invariant on the command line, as `-inv FALSE`. THE
#   SAME TRICK IS NOT AVAILABLE HERE: TLC has -inv but no -prop. Measured on
#   v1.8.0 -- `tlc -help` lists -inv, -invlevel and -postCondition, and no
#   flag that takes a temporal formula. So a temporal probe has to arrive
#   through a .cfg, and a .cfg PROPERTY names an operator rather than
#   carrying an expression, so the operator has to exist in the main module.
#
#   Hence a generated wrapper in the scratch directory that EXTENDS the
#   learner's module and defines one operator, run as the main module with a
#   copy of the learner's .cfg plus one appended PROPERTY line. The wrapper
#   pattern is grade.sh's (§5.2 run_judge); what differs is that the .cfg is
#   COPIED rather than rebuilt, so CONSTANTS, CONSTRAINT, SYMMETRY and the
#   learner's own obligations all survive into the probe run untouched.
#
#   THE PROBE BODY IS `[]<>FALSE`, AND ITS BEING TEMPORAL IS THE WHOLE POINT.
#   `[](counter # counter)` over a state predicate is not a weaker probe, it
#   is a different channel: TLC lifts a state-level formula into an INVARIANT
#   and refutes it against the state graph, which ignores fairness by
#   construction, so it exits 12 on a spec that has no behaviours at all --
#   the opposite of the signal wanted. Measured, on both fixtures:
#
#     rc=13  the formula was refuted, so a behaviour exists to refute it;
#     rc=0   nothing refuted it, because there is nothing to refute it WITH.
#
#   `FALSE` does NOT constant-fold out of the temporal channel here, which
#   was measured rather than assumed: TLC logs "Implied-temporal checking"
#   for this formula and returns 13 on the satisfiable twin. That check is
#   worth repeating on a new build before trusting the row, because a
#   constant-folded probe would silently move to the invariant channel and
#   report every healthy spec unsatisfiable.
#
#   The probe runs only after probe 2 completed at rc=0. That is the same
#   guard the dead-action probe uses and it is load-bearing for the same
#   reason: appending a PROPERTY to a .cfg whose INVARIANT is already
#   violated would exit 12 on the safety violation before liveness checking
#   began, and a safety violation says nothing either way about whether Spec
#   admits a behaviour.
#
# WHY THE DEAD-ACTION PROBE READS A LOG, AND WHY THAT IS NOT A §5.1 BREACH
#
#   §5.1 bans deriving a verdict from TLC's prose. The dead-action probe reads
#   TLC's -coverage 1 block, because per-action counts have no exit-code
#   channel at all -- there is no rc that means "some action never fired". The
#   distinction that keeps this honest:
#
#     - what is extracted is NUMBERS in a fixed positional format, never a
#       phrase. No English string decides anything here;
#     - the run's VALIDITY still comes from verdict.sh's rc. Coverage is read
#       only from a probe that verdict.sh reported as rc=0, i.e. a completed
#       run. A run cut short by a violation has partial coverage, so the probe
#       declines to judge rather than guessing.
#
#   Everything else in this file branches on rc alone.
#
# MODULE RESOLUTION -- A MEASURED TLC TRAP
#
#   -postCondition needs `Module!Operator`; a bare expression is rejected
#   (measured: `-postCondition 'TLCGet("distinct") >= 99'` exits 1). So Gate
#   must be resolvable, and how TLC looks for it depends on the form of the
#   MAIN module's path:
#
#     absolute main path -> auxiliary modules come from the main module's own
#                           directory and from the TLA-Library property. The
#                           CWD IS NOT SEARCHED -- verified by putting
#                           Gate.tla in the CWD and still getting rc=150.
#     relative main path -> the CWD is searched.
#
#   This script therefore always passes the module as an ABSOLUTE path and
#   sets TLA-Library, which is the combination that works from any CWD. The
#   `tlc` wrapper has no -D pass-through, so TLA-Library is delivered through
#   JAVA_TOOL_OPTIONS; the JVM's "Picked up JAVA_TOOL_OPTIONS" line lands in
#   the log and is ignored by everything here.
#
# THE THRESHOLD IS PER-PROBLEM, AND IT IS MANDATORY
#
#   Gate.tla is CENTRALLY OWNED and hard-codes `>= 4`. This script does not
#   edit it. --min-states N other than 4 is served by generating a throwaway
#   VacuityGate module in the scratch directory, which is why TLA-Library
#   carries the scratch directory as well as harness/.
#
#   --min-states has NO DEFAULT (bead tla-dk7w). It used to fall back on
#   Gate.tla's 4, and custody step 4 measured what that bought: a 24-state
#   deterministic script that replays the published satisfying trace passes
#   all 13 obligations at rc=0, and clears a floor of 4 six times over. The
#   witness probes cannot see it either, because 3.9 obliges every property to
#   ship a satisfying trace and any trace rich enough to teach also threads
#   the finite witness set. So the hole sits in every shape-A problem that
#   honours 3.9, and the floor is the one instrument that can see it.
#
#   The number is a fact about the problem, not about this script, so the
#   script has no honest number to pick. A missing --min-states is refused at
#   rc=2 USAGE. That is a statement about the CALLER, which is why it stays
#   out of the 3/4/5/6/7 range reserved for statements about the submission.

set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERDICT="$HERE/verdict.sh"
GATE_DIR="$HERE"

MODULE=""
CONFIG=""
# Unset on purpose, and it must stay a sentinel rather than a number. See THE
# THRESHOLD IS PER-PROBLEM above: a number here is a floor the caller never
# stated, and the one this used to carry is the one a transcription clears.
MIN_STATES=""
TIMEOUT=60
EXPECT="invariant"
EXPECT_ACTIONS=""
DEAD_ACTIONS=1
# Opt-in, and it stays opt-in. The state-count floor is mandatory because
# every problem has a state space. An observation operator is a thing a
# problem either defines or does not, so a mandatory flag here would refuse
# submissions that have no observation to look at. The honesty burden moves
# to the summary, which says when no operator was named. Bead tla-29m4.
OBSERVE=""
KEEP_LOGS=""
QUIET=0

usage() {
  cat <<'USAGE'
usage: harness/vacuity.sh [OPTIONS] <module.tla>

  -c, --config FILE     .cfg to use (default: <module>.cfg)
  -n, --min-states N    NonVacuous threshold (REQUIRED, no default)
  -t, --timeout SECS    per-probe wall-clock budget (default 60)
  -e, --expect KIND     invariant (default) | refinement | none
      --expect-actions NAME[,NAME...]
                        action names the problem requires; one absent from the
                        coverage block is reported as dead
      --no-dead-actions skip the dead-action probe
      --observe NAME    an observation operator the problem defines. Every
                        field of it that never changes is reported. Opt-in:
                        with no --observe, nothing is looked for
      --keep-logs DIR   keep each probe's TLC log here
  -q, --quiet           verdict token only
  -h, --help            this text

Prints the verdict token on line 1; exits 0/3/4/5/6/7/8.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--config)      CONFIG="${2:-}"; shift 2 ;;
    -n|--min-states)  MIN_STATES="${2:-}"; shift 2 ;;
    -t|--timeout)     TIMEOUT="${2:-}"; shift 2 ;;
    -e|--expect)      EXPECT="${2:-}"; shift 2 ;;
    --expect-actions) EXPECT_ACTIONS="${2:-}"; shift 2 ;;
    --no-dead-actions) DEAD_ACTIONS=0; shift ;;
    --observe)        OBSERVE="${2:-}"; shift 2 ;;
    --keep-logs)      KEEP_LOGS="${2:-}"; shift 2 ;;
    -q|--quiet)       QUIET=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    -*)               echo "vacuity.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$MODULE" ]; then
        echo "vacuity.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      MODULE="$1"; shift ;;
  esac
done

if [ -z "$MODULE" ]; then
  echo "vacuity.sh: no module given" >&2
  usage >&2
  exit 2
fi

case "$EXPECT" in
  invariant|refinement|none) ;;
  *) echo "vacuity.sh: --expect must be invariant, refinement or none" >&2; exit 2 ;;
esac

# An ARGUMENT fault, so it lands here rather than after a probe. A floor
# checked later would let a whole TLC run happen on a number nobody supplied,
# and would report whatever that run found instead of the fault.
#
# Nothing goes to stdout on either arm. stdout line 1 is the verdict channel,
# and a refusal that printed a token would be indexed as a verdict by every
# caller that slices it.
if [ -z "$MIN_STATES" ]; then
  echo "vacuity.sh: --min-states is required and has no default" >&2
  echo "vacuity.sh: the state-count floor is per-problem, so pass the one this problem sets" >&2
  usage >&2
  exit 2
fi

case "$MIN_STATES" in
  *[!0-9]*) echo "vacuity.sh: --min-states must be a non-negative integer" >&2; exit 2 ;;
esac

# The name reaches TLC inside a GENERATED module, so anything that is not a
# TLA+ identifier would land as source text rather than as an operator. A name
# the module does not DEFINE is a different thing and is not refused here: it
# is a fact about the submission, and the probe reports it as inconclusive
# once TLC has said so. This arm is about the caller.
case "$OBSERVE" in
  "") ;;
  [!A-Za-z_]*|*[!A-Za-z0-9_]*)
    echo "vacuity.sh: --observe must name a TLA+ operator (letters, digits, underscore)" >&2
    exit 2 ;;
esac

# The module goes to TLC as an ABSOLUTE path; see the MODULE RESOLUTION note.
# No existence check -- "that file is not there" is a verdict verdict.sh
# obtains from TLC (150), and short-circuiting it here would substitute this
# script's opinion for the channel the harness is built on.
MODULE_ABS=$(cd -- "$(dirname -- "$MODULE")" 2>/dev/null && pwd)/$(basename -- "$MODULE")
if [ -z "$CONFIG" ]; then
  CONFIG="${MODULE%.tla}.cfg"
fi
CONFIG_ABS=$(cd -- "$(dirname -- "$CONFIG")" 2>/dev/null && pwd)/$(basename -- "$CONFIG")

SCRATCH=$(mktemp -d -t tla_vacuity.XXXXXX)
# Reached only through the EXIT trap below. shellcheck does not follow traps,
# so it reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

[ -n "$KEEP_LOGS" ] && mkdir -p "$KEEP_LOGS"

# Gate.tla stays where central owns it; TLA-Library points at it. The scratch
# directory comes first so a generated VacuityGate is found.
#
# The learner's own directory is on the end, and only the satisfiability probe
# needs it: that probe's main module is a GENERATED wrapper living in the
# scratch directory, so the learner's module is an auxiliary one there and is
# no longer found by sitting beside the main module. It goes LAST so that a
# stray Gate.tla beside a submission cannot shadow the centrally-owned one.
MODULE_DIR=$(dirname -- "$MODULE_ABS")
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-DTLA-Library=$SCRATCH:$GATE_DIR:$MODULE_DIR"

# The NonVacuous operator to use. Gate!NonVacuous already says >= 4, so a
# floor of exactly 4 reuses it. Any other threshold gets a generated module,
# because Gate.tla is read-only here. A floor of 4 is still something the
# caller had to ask for, so this is a shortcut and not a fallback.
NONVACUOUS_OP="Gate!NonVacuous"
if [ "$MIN_STATES" != "4" ]; then
  cat >"$SCRATCH/VacuityGate.tla" <<TLA
---- MODULE VacuityGate ----
(* Generated by harness/vacuity.sh for --min-states $MIN_STATES.            *)
(* Gate.tla is centrally owned and hard-codes >= 4; the threshold is        *)
(* per-problem, so a different one is parameterised here instead.           *)
EXTENDS Naturals, TLC
NonVacuous == TLCGet("distinct") >= $MIN_STATES
====
TLA
  NONVACUOUS_OP="VacuityGate!NonVacuous"
fi

PROBE_N=0
PROBE_LOG=""

# run_probe <label> [verdict.sh args...] -> sets PROBE_LOG, returns verdict.sh's rc
run_probe() {
  local label="$1"; shift
  PROBE_N=$((PROBE_N + 1))
  PROBE_LOG="$SCRATCH/probe${PROBE_N}-${label}.log"
  # The module goes BEFORE the caller's arguments: verdict.sh treats `--` as
  # "everything after this is a raw tlc argument", so a module placed after a
  # `--` is consumed as one and never seen as the module.
  bash "$VERDICT" -q --timeout "$TIMEOUT" --log "$PROBE_LOG" \
    --config "$CONFIG_ABS" "$MODULE_ABS" "$@" >/dev/null 2>&1
  local rc=$?
  if [ -n "$KEEP_LOGS" ]; then
    cp "$PROBE_LOG" "$KEEP_LOGS/" 2>/dev/null
  fi
  return $rc
}

# Counts pulled out of a completed run's log for the PROSE only. Never a
# verdict; a missing number degrades to "?" rather than changing an outcome.
distinct_count() {
  sed -n 's/^.*, \([0-9][0-9]*\) distinct states found.*$/\1/p' "$1" | tail -1
}

# ---------------------------------------------------------------------------
# Dead-action scan over the -coverage 1 block.
#
# The action lines have a fixed positional shape:
#
#   <Overflow line 20, col 1 to line 20, col 8 of module DeadGuard>: 0:0
#                                                                    ^ ^
#                                                            distinct total
#
# and their sub-expression counts follow, indented, one per conjunct:
#
#     line 20, col 13 to line 20, col 25 of module DeadGuard: 5
#     line 20, col 30 to line 20, col 41 of module DeadGuard: 0
#
# The LAST indented line with a non-zero count is how far evaluation got
# before the action died, which is what turns the feedback into "your guard
# `counter > 100` is never true" instead of "unreachable". Error location is
# the only feedback form that measured as working (§3.7).
#
# Lines that carry a single count rather than distinct:total are variable and
# definition coverage, not actions, and are skipped by the ':' test.
# ---------------------------------------------------------------------------
scan_dead_actions() {
  awk '
    function flush() {
      if (name != "" && total == 0) {
        printf "%s\t%s\t%s\t%s\t%s\n", name, aline, amod, loc, lcount
      }
      name = ""; loc = ""; lcount = ""
    }
    # An action header. Indented lines are sub-expressions, handled below.
    /^</ {
      flush()
      n = split($0, f, " ")
      counts = f[n]
      if (counts !~ /^[0-9]+:[0-9]+$/) { next }
      split(counts, c, ":")
      distinct = c[1] + 0; total = c[2] + 0
      name = substr(f[1], 2)
      aline = f[3]; sub(/,$/, "", aline)
      amod = f[n-1]; sub(/>:$/, "", amod)
      next
    }
    # A sub-expression count belonging to the action above it.
    substr($0, 1, 1) == " " && name != "" {
      n = split($0, f, " ")
      head = f[1]; sub(/^\|+/, "", head)
      if (head != "line") { next }
      v = f[n]
      if (v ~ /:/) { split(v, vv, ":"); v = vv[2] }
      if (v !~ /^[0-9]+$/) { next }
      if (v + 0 > 0) {
        lcount = v
        # f[2] arrives as "20," -- strip the comma HERE, not off the end of
        # the joined string, or the line number keeps it and every later
        # sed/cut on that location silently produces nothing.
        lnum = f[2]; sub(/,$/, "", lnum)
        loc = lnum " " f[4] " " f[9]
      }
      next
    }
    { flush() }
    END { flush() }
  ' "$1"
}

# Every action name the coverage block mentions, one per line, whatever its
# counts. scan_dead_actions above answers "which rows read zero"; this answers
# "which rows are there at all", and only the second can see an action that
# was deleted rather than restricted.
scan_action_names() {
  awk '
    /^</ {
      n = split($0, f, " ")
      counts = f[n]
      # Same positional test as scan_dead_actions: a header without a
      # distinct:total pair is variable or definition coverage, not an action.
      if (counts !~ /^[0-9]+:[0-9]+$/) { next }
      print substr(f[1], 2)
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Per-field motion over the frozen-observe probe's log.
#
# The probe prints one line per field per state, in a format this script chose
# itself:
#
#   <<"VACUITY_OBSERVE", "shelf", 0>>
#
# Output is one row per field, in the order the fields were first seen, as
#
#   <name> <TAB> <distinct printed values> <TAB> <first value>
#
# so a count of 1 is a field that never changed. The regex guard is what makes
# the substring arithmetic below safe: a line that does not match the whole
# shape is dropped rather than half-parsed.
#
# TLC prints a value on one line, so a field whose value spanned lines would
# go unreported rather than misreported. Measured shapes: a number, a string,
# and a record all print inline.
# ---------------------------------------------------------------------------
scan_observe_motion() {
  awk '
    $0 ~ /^<<"VACUITY_OBSERVE", "[^"]*", .*>>$/ {
      rest = substr($0, 23)
      q = index(rest, "\"")
      name = substr(rest, 1, q - 1)
      val = substr(rest, q + 3)
      val = substr(val, 1, length(val) - 2)
      if (!(name in firstval)) { order[++n] = name; firstval[name] = val }
      key = name SUBSEP val
      if (!(key in seen)) { seen[key] = 1; values[name]++ }
    }
    END {
      for (i = 1; i <= n; i++) {
        nm = order[i]
        printf "%s\t%d\t%s\n", nm, values[nm], firstval[nm]
      }
    }
  ' "$1"
}

# Quote the source text a sub-expression location points at.
source_at() {
  local file="$1" line="$2" cola="$3" colb="$4"
  [ -r "$file" ] || return 0
  local text
  text=$(sed -n "${line}p" "$file" 2>/dev/null | cut -c "${cola}-${colb}" 2>/dev/null)
  printf '%s' "$text"
}

REPORT=""
say() { REPORT="${REPORT}$1
"; }

finish() {
  local token="$1" code="$2"
  echo "$token"
  if [ "$QUIET" = "0" ] && [ -n "$REPORT" ]; then
    printf '%s' "$REPORT"
  fi
  exit "$code"
}

# ===========================================================================
# PROBE 1 -- the cheap smoke test.
#
# `-inv FALSE` injects an invariant that no state can satisfy, so the first
# reachable state violates it. rc=12 means reachable states EXIST (good);
# rc=0 means there were none to violate it, i.e. the space is EMPTY.
#
# No file is edited and the expression evaluates in the learner's namespace.
# TLC auto-names the injected invariant __DebuggerExpr__<nanotime>; that name
# is never matched here, and must never be -- it carries a timestamp.
# ===========================================================================
run_probe "smoke" -- -inv FALSE
smoke_rc=$?

case "$smoke_rc" in
  12|13)
    : ;;   # reachable states exist
  0)
    say "VECTOR 1: your specification has no reachable states."
    say ""
    say "TLC generated 0 states, so every invariant in the model held"
    say "trivially and the run still exited 0 reporting success. Nothing was"
    say "checked, because there was nothing to check -- and deadlock checking"
    say "cannot catch this, since there is no reachable state to deadlock in."
    say ""
    say "Look at Init in $(basename "$MODULE_ABS"): one of its conjuncts"
    say "cannot be satisfied, so their conjunction has no solution. A bound"
    say "that contradicts a guard is the usual cause."
    finish "VACUOUS_EMPTY_SPACE" 3 ;;
  *)
    say "The specification did not run, so vacuity could not be assessed."
    say "verdict.sh reported rc=$smoke_rc on the smoke probe. Fix that first;"
    say "see harness/verdict.sh for what the code means."
    finish "PROBE_INCONCLUSIVE" 6 ;;
esac

# ===========================================================================
# PROBE 2 -- the real gate: is the state space big enough to be meaningful?
#
# rc=10 is -postCondition false. Probe 1 has already excluded the 0-state
# case, so reaching rc=10 here means the space is non-empty but smaller than
# the problem's threshold.
# ===========================================================================
run_probe "nonvacuous" --postcondition "$NONVACUOUS_OP"
nv_rc=$?
nv_log="$PROBE_LOG"

case "$nv_rc" in
  0)
    : ;;
  12|13)
    # A real violation stopped the run before the postcondition could be
    # evaluated. The spec is manifestly doing work, so this is not vacuity --
    # but coverage is partial, so the dead-action probe must not use this log.
    : ;;
  10)
    say "VECTOR 1: your specification reaches too few states to be meaningful."
    say ""
    say "TLC found $(distinct_count "$nv_log") distinct states; this problem"
    say "requires at least $MIN_STATES. The space is not empty, so Init has a"
    say "solution, but Next is not taking the system anywhere."
    say ""
    say "Check that each action's guard can actually become true, and that"
    say "the primed variables are assigned rather than left UNCHANGED."
    finish "VACUOUS_EMPTY_SPACE" 3 ;;
  *)
    say "The specification did not run, so vacuity could not be assessed."
    say "verdict.sh reported rc=$nv_rc on the non-vacuity probe."
    finish "PROBE_INCONCLUSIVE" 6 ;;
esac

# ===========================================================================
# PROBE 3 -- was the check actually configured?
#
# A DIFFERENT FAILURE from probe 2, over a state space probe 2 just declared
# healthy. Runs the member of the guard family the problem calls for.
# ===========================================================================
if [ "$EXPECT" != "none" ]; then
  if [ "$EXPECT" = "invariant" ]; then
    guard_op="Gate!InvariantConfigured"
    guard_kw="INVARIANT"
  else
    guard_op="Gate!RefinementConfigured"
    guard_kw="PROPERTY"
  fi

  run_probe "configured" --postcondition "$guard_op"
  cfg_rc=$?

  case "$cfg_rc" in
    0|12|13)
      : ;;
    10)
      say "VECTOR 2: nothing was checked, though your state space is fine."
      say ""
      say "TLC explored $(distinct_count "$nv_log") distinct states and exited"
      say "reporting success -- but it checked no $guard_kw at all, so that"
      say "success means nothing. This is NOT the same failure as an empty"
      say "state space: the specification is healthy, the obligation is"
      say "missing."
      say ""
      say "A .cfg keyword with no operand is not an error. TLC accepts a bare"
      say "$guard_kw line, silently checks nothing, and still exits 0."
      say ""
      say "Look at $(basename "$CONFIG_ABS"). The $guard_kw keyword is there,"
      say "but the operator name after it is missing."
      finish "VACUOUS_UNCHECKED" 4 ;;
    *)
      say "The specification did not run, so vacuity could not be assessed."
      say "verdict.sh reported rc=$cfg_rc on the configured-check probe."
      finish "PROBE_INCONCLUSIVE" 6 ;;
  esac
fi

# ===========================================================================
# PROBE 4 -- does Spec admit any behaviour at all?
#
# Ordered BEFORE dead actions deliberately. Both can be true of one module --
# an action dropped from Next while a fairness conjunct still names it is
# exactly how vector 4 arises -- and of the two descriptions the unsatisfiable
# one is the root cause. "This action never fired" invites the learner to
# weaken a guard; "no behaviour satisfies Spec" sends them to the mismatch
# that actually broke the run.
#
# Runs only after probe 2 completed at rc=0; see the injection note in the
# header for why that guard is load-bearing rather than merely tidy.
# ===========================================================================
if [ "$nv_rc" = "0" ]; then
  MODULE_NAME=$(basename -- "$MODULE_ABS" .tla)
  cat >"$SCRATCH/VacuitySatProbe.tla" <<TLA
---- MODULE VacuitySatProbe ----
(* Generated by harness/vacuity.sh. TLC has -inv but no -prop, so a temporal *)
(* probe cannot be injected on the command line the way probe 1's invariant  *)
(* is; it arrives as a .cfg PROPERTY, and a .cfg PROPERTY names an operator, *)
(* so the operator has to exist in the main module.                          *)
(*                                                                           *)
(* []<>FALSE is refuted by any behaviour whatsoever and by nothing else, so  *)
(* rc=13 means Spec admits a behaviour and rc=0 means it admits none. It has *)
(* to be TEMPORAL: the same falsehood as a state predicate is lifted into an *)
(* INVARIANT and checked against the state graph, which ignores fairness.    *)
EXTENDS $MODULE_NAME
VACUITY_SATISFIABLE == []<>FALSE
====
TLA
  # The learner's .cfg is COPIED rather than rebuilt, so CONSTANTS, CONSTRAINT,
  # SYMMETRY and the learner's own obligations reach the probe run unchanged.
  # Probe 1 has already established that this file is readable by TLC.
  cat "$CONFIG_ABS" >"$SCRATCH/VacuitySatProbe.cfg" 2>/dev/null
  printf 'PROPERTY VACUITY_SATISFIABLE\n' >>"$SCRATCH/VacuitySatProbe.cfg"

  # Not run_probe: this is the one probe whose main module and .cfg are
  # generated rather than the learner's, and run_probe exists to guarantee the
  # opposite. Deadlock checking stays off, as it is for every probe -- a
  # terminal state would otherwise exit 11 before the probe meant anything.
  PROBE_N=$((PROBE_N + 1))
  sat_log="$SCRATCH/probe${PROBE_N}-satisfiable.log"
  bash "$VERDICT" -q --timeout "$TIMEOUT" --log "$sat_log" \
    --config "$SCRATCH/VacuitySatProbe.cfg" "$SCRATCH/VacuitySatProbe.tla" \
    >/dev/null 2>&1
  sat_rc=$?
  if [ -n "$KEEP_LOGS" ]; then
    cp "$sat_log" "$KEEP_LOGS/" 2>/dev/null
  fi

  case "$sat_rc" in
    13)
      : ;;   # a behaviour exists, and it refuted the probe
    0)
      say "VECTOR 4: no behaviour satisfies your Spec."
      say ""
      say "The state space is healthy and the model is configured, but the"
      say "set of behaviours Spec admits is EMPTY. Every temporal obligation"
      say "you wrote then holds over nothing, and TLC still exits 0 reporting"
      say "success -- so a passing run means only that there was nothing to"
      say "fail."
      say ""
      say "This is NOT an empty state space: TLC reached"
      say "$(distinct_count "$nv_log") distinct states. Fairness never touches the state graph,"
      say "it constrains the behaviours over that graph, which is why every"
      say "earlier probe passed."
      say ""
      say "Look at Spec in $(basename "$MODULE_ABS"). A fairness conjunct is"
      say "the usual cause: WF_ or SF_ on an action that Next does not allow"
      say "demands a step the next-state relation forbids, so no behaviour"
      say "can satisfy both. Check that every action named in a fairness"
      say "conjunct is also a disjunct of Next."
      finish "VACUOUS_UNSATISFIABLE" 7 ;;
    *)
      say "The specification did not run, so vacuity could not be assessed."
      say "verdict.sh reported rc=$sat_rc on the satisfiability probe."
      finish "PROBE_INCONCLUSIVE" 6 ;;
  esac
fi

# ===========================================================================
# PROBE 5 -- dead actions.
#
# Reuses probe 2's log rather than spending another TLC run, and only when
# that probe COMPLETED (rc=0). A run cut short by a violation has partial
# coverage, which would report live actions as dead.
#
# TWO FAULTS, ONE VERDICT. A row reading `total == 0` is an action that could
# not fire; a name in --expect-actions with no row at all is an action Next
# never mentions. Same lesson -- something you wrote was never exercised --
# so they share the token, and the remediation below says which happened,
# because the fixes are not the same.
# ===========================================================================
if [ "$DEAD_ACTIONS" = "1" ] && [ "$nv_rc" = "0" ]; then
  dead=$(scan_dead_actions "$nv_log")

  # Absent actions. Without names there is nothing to compare against, so the
  # probe stays exactly as strong as it was and no stronger.
  absent=""
  if [ -n "$EXPECT_ACTIONS" ]; then
    seen=$(scan_action_names "$nv_log")
    IFS=',' read -r -a want_actions <<<"$EXPECT_ACTIONS"
    for want in ${want_actions[@]+"${want_actions[@]}"}; do
      [ -z "$want" ] && continue
      # A here-string, never a pipe into grep -q: -q exits on the first match
      # and SIGPIPEs the producer, which under `set -o pipefail` returns 141.
      # Inside this `if` a 141 is merely falsy, so a present action would be
      # reported ABSENT and the spec failed for a fault it does not have.
      # Bead tla-kr9.
      if ! grep -qxF -- "$want" <<<"$seen"; then
        absent="${absent}${want}"$'\n'
      fi
    done
  fi

  if [ -n "$dead" ] || [ -n "$absent" ]; then
    say "VECTOR 3: an action in your specification can never fire."
    say ""
    say "The state space is healthy and the model is configured, but part of"
    say "what you wrote is unreachable -- so the behaviour it describes was"
    say "never tested."
    say ""
    while IFS=$'\t' read -r name aline amod loc lcount; do
      [ -z "$name" ] && continue
      say "  action $name (line $aline of module $amod) never fired."
      say "    TLC counts it as 0 total states generated."
      if [ -n "$loc" ]; then
        # shellcheck disable=SC2086
        set -- $loc
        snippet=$(source_at "$MODULE_ABS" "$1" "$2" "$3")
        if [ -n "$snippet" ]; then
          say "    last expression still reached: line $1, col $2-$3"
          say "      $snippet"
          say "    evaluated $lcount times, never true. Everything after it in"
          say "    the action is dead."
        else
          say "    last expression still reached: line $1, col $2-$3,"
          say "    evaluated $lcount times, never true."
        fi
      fi
    done <<EOF
$dead
EOF
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      say "  action $name never fired: it has no coverage row at all."
      say "    This is the DELETED shape, not the restricted one, and the fix"
      say "    differs. TLC prints one coverage row per disjunct of Next: an"
      say "    action whose guard is never true still gets a row, reading 0"
      say "    total, and an action Next never mentions gets no row. $name"
      say "    got no row, so there is no guard here to weaken -- $name is"
      say "    missing from Next. Check that it is one of Next's disjuncts."
    done <<EOF
$absent
EOF
    finish "VACUOUS_DEAD_ACTION" 5
  fi
fi

# ===========================================================================
# PROBE 6 -- a field of the observation that never changes.
#
# LAST, AND AFTER DEAD ACTIONS ON PURPOSE. Nothing in the fixtures separates
# the two orders, so this is a choice rather than a measurement, and it is the
# same choice probe 4 makes over probe 5: report the root cause. An action
# that never fired is a plausible REASON a field never moves, since the step
# that would have moved it is the step that never ran. "Your guard is never
# true" sends a learner to the break. "This field never changes" sends them to
# a window that is doing exactly what the model told it to.
#
# The cheaper of the two also goes first, which is a happy accident rather
# than the argument. Probe 5 re-reads probe 2's log and costs nothing. This one
# costs a whole extra exploration, and a submission already failing on a dead
# action never pays for it.
#
# RUNS ONLY AFTER PROBE 2 COMPLETED AT rc=0, for the reason probe 5 does. This
# probe reads the WHOLE reachable space, and a run cut short by a violation
# has seen part of it. A field that moves late would then read as frozen,
# which is the one direction this gate must not fail in.
# ===========================================================================
OBSERVE_RAN=0
if [ -n "$OBSERVE" ] && [ "$nv_rc" = "0" ]; then
  OBSERVE_MODULE=$(basename -- "$MODULE_ABS" .tla)
  cat >"$SCRATCH/VacuityObserve.tla" <<TLA
---- MODULE VacuityObserve ----
(* Generated by harness/vacuity.sh for --observe $OBSERVE.                   *)
(*                                                                           *)
(* The invariant is ALWAYS TRUE, so exploration runs to completion and every *)
(* reachable state prints a line per field. Nothing is compared here: a       *)
(* field whose values span types would abort a comparison rather than answer  *)
(* one, and take the report on the field beside it down with it. The          *)
(* distinct-value count happens in awk over the log instead.                  *)
EXTENDS $OBSERVE_MODULE, TLC
VACUITY_OBSERVE_TRACE ==
    \A vacuity_field \in DOMAIN $OBSERVE :
        PrintT(<<"VACUITY_OBSERVE", vacuity_field, ${OBSERVE}[vacuity_field]>>)
====
TLA
  # The learner's .cfg is copied unchanged, as probe 4 copies it: CONSTANTS,
  # CONSTRAINT, SYMMETRY and the learner's own obligations all have to reach
  # this run, or it explores a different state space from the one probe 2
  # measured. The probe arrives on the command line as -inv, the way probe 1's
  # does, which leaves the copied file untouched.
  cat "$CONFIG_ABS" >"$SCRATCH/VacuityObserve.cfg" 2>/dev/null

  PROBE_N=$((PROBE_N + 1))
  obs_log="$SCRATCH/probe${PROBE_N}-observe.log"
  bash "$VERDICT" -q --timeout "$TIMEOUT" --log "$obs_log" \
    --config "$SCRATCH/VacuityObserve.cfg" "$SCRATCH/VacuityObserve.tla" \
    -- -inv VACUITY_OBSERVE_TRACE >/dev/null 2>&1
  obs_rc=$?
  if [ -n "$KEEP_LOGS" ]; then
    cp "$obs_log" "$KEEP_LOGS/" 2>/dev/null
  fi

  # An operator the module does not define lands at rc=150, measured. An
  # operator that has no DOMAIN lands at rc=76. Both mean the same thing to a
  # caller -- the observation was never looked at -- and neither is a verdict
  # about the submission's vacuity. Reporting NON_VACUOUS here would be a
  # false pass reachable by misspelling a flag.
  if [ "$obs_rc" != "0" ]; then
    say "The observation $OBSERVE could not be probed, so vacuity could not"
    say "be assessed. verdict.sh reported rc=$obs_rc on the frozen-observation"
    say "probe."
    say ""
    say "Check that $(basename "$MODULE_ABS") defines $OBSERVE, that the name"
    say "is spelled the way the module spells it, and that $OBSERVE is a"
    say "record or a function rather than a single value."
    finish "PROBE_INCONCLUSIVE" 6
  fi

  obs_motion=$(scan_observe_motion "$obs_log")
  if [ -z "$obs_motion" ]; then
    say "The observation $OBSERVE ran but reported no fields at all, so"
    say "nothing is known about it. An observation with an empty domain is"
    say "the usual cause."
    finish "PROBE_INCONCLUSIVE" 6
  fi

  obs_frozen=""
  obs_moving=""
  while IFS=$'\t' read -r obs_name obs_count obs_val; do
    [ -z "$obs_name" ] && continue
    if [ "$obs_count" = "1" ]; then
      obs_frozen="${obs_frozen}${obs_name}	${obs_val}"$'\n'
    else
      obs_moving="${obs_moving}${obs_name}	${obs_count}"$'\n'
    fi
  done <<EOF
$obs_motion
EOF

  if [ -n "$obs_frozen" ]; then
    say "VECTOR 5: part of your observation never changes."
    say ""
    say "The state space is healthy, the obligation is configured, and every"
    say "action fired. What is stuck is the WINDOW. $OBSERVE is what the"
    say "problem reads your model through, and a field of it holds one value"
    say "in every reachable state, so nothing your model does reaches that"
    say "field. An obligation stated over it holds for the same reason an"
    say "obligation over an empty state space holds."
    say ""
    while IFS=$'\t' read -r obs_name obs_val; do
      [ -z "$obs_name" ] && continue
      say "  field $obs_name never changes."
      say "    It is $obs_val in all $(distinct_count "$nv_log") distinct states TLC reached."
    done <<EOF
$obs_frozen
EOF
    if [ -n "$obs_moving" ]; then
      say ""
      say "The record as a whole DOES move, which is why a probe at the record"
      say "altitude cannot see this: such a probe is refuted the moment any"
      say "one field moves, so it catches one subset out of the 2^n a record"
      say "has. These fields do change:"
      while IFS=$'\t' read -r obs_name obs_count; do
        [ -z "$obs_name" ] && continue
        say "  field $obs_name takes $obs_count distinct values."
      done <<EOF
$obs_moving
EOF
    fi
    say ""
    say "Look at $OBSERVE in $(basename "$MODULE_ABS"). A field wired to a"
    say "literal, or reading a variable no action ever assigns, is the usual"
    say "cause."
    finish "VACUOUS_FROZEN_OBSERVE" 8
  fi
  OBSERVE_RAN=1
fi

# The summary names only the probes that actually ran. Saying "a configured
# check" after --expect none skipped that probe would claim a guarantee this
# run did not obtain.
say "The specification has a non-empty state space (at least $MIN_STATES"
say "distinct states)."
if [ "$EXPECT" != "none" ]; then
  say "A $guard_kw is configured, so the run checked something real."
else
  say "The configured-check probe was skipped (--expect none), so nothing"
  say "here says an obligation was actually checked."
fi
if [ "$nv_rc" = "0" ]; then
  say "Spec admits at least one behaviour, so the temporal obligations in"
  say "the model were checked over something."
else
  say "The satisfiability probe did not run, so nothing here says Spec"
  say "admits a behaviour."
fi
if [ "$DEAD_ACTIONS" = "1" ] && [ "$nv_rc" = "0" ]; then
  if [ -n "$EXPECT_ACTIONS" ]; then
    say "Every action fired at least once, and every expected action"
    say "($EXPECT_ACTIONS) reached the coverage block."
  else
    # No names were given, so an action DELETED from Next leaves no row and
    # cannot have been checked for. Claiming "every action" would overstate
    # what this run actually saw.
    say "Every action Next mentions fired at least once. No action names"
    say "were expected, so an action missing from Next was not looked for."
  fi
else
  say "The dead-action probe did not run, so no action was proved live."
fi
# The opt-in flag's whole honesty burden sits here. A run that never looked
# for a frozen field must not read like a run that looked and found none.
if [ -z "$OBSERVE" ]; then
  say "No frozen-observation probe ran, because no observation operator was named."
  say "A field of an observation that never changes was not looked for."
elif [ "$OBSERVE_RAN" = "1" ]; then
  say "Every field of $OBSERVE takes more than one value across the reachable"
  say "states, so the observation passes the model's motion through."
else
  say "The frozen-observation probe did not run, so no field of $OBSERVE was"
  say "shown to move."
fi
finish "NON_VACUOUS" 0
