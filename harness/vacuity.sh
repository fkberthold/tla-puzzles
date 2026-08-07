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
#   -n, --min-states N    NonVacuous threshold (default 4, Gate.tla's built-in)
#   -t, --timeout SECS    per-probe wall-clock budget (default 60)
#   -e, --expect KIND     which member of the configured-check guard family to
#                         run: invariant (default) | refinement | none
#       --no-dead-actions skip the dead-action probe
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
#
#   The codes are deliberately disjoint from TLC's own (0/10/11/12/13/124/
#   150/151/255) so a caller can never confuse a vacuity verdict with a
#   model-checking one.
#
# THREE VECTORS, AND WHY ONE VERDICT WOULD NOT DO
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
# THE THRESHOLD IS PER-PROBLEM
#
#   Gate.tla is CENTRALLY OWNED and hard-codes `>= 4`. This script does not
#   edit it. --min-states N other than 4 is served by generating a throwaway
#   VacuityGate module in the scratch directory, which is why TLA-Library
#   carries the scratch directory as well as harness/.

set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERDICT="$HERE/verdict.sh"
GATE_DIR="$HERE"

MODULE=""
CONFIG=""
MIN_STATES=4
TIMEOUT=60
EXPECT="invariant"
DEAD_ACTIONS=1
KEEP_LOGS=""
QUIET=0

usage() {
  cat <<'USAGE'
usage: harness/vacuity.sh [OPTIONS] <module.tla>

  -c, --config FILE     .cfg to use (default: <module>.cfg)
  -n, --min-states N    NonVacuous threshold (default 4)
  -t, --timeout SECS    per-probe wall-clock budget (default 60)
  -e, --expect KIND     invariant (default) | refinement | none
      --no-dead-actions skip the dead-action probe
      --keep-logs DIR   keep each probe's TLC log here
  -q, --quiet           verdict token only
  -h, --help            this text

Prints the verdict token on line 1; exits 0/3/4/5/6.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--config)      CONFIG="${2:-}"; shift 2 ;;
    -n|--min-states)  MIN_STATES="${2:-}"; shift 2 ;;
    -t|--timeout)     TIMEOUT="${2:-}"; shift 2 ;;
    -e|--expect)      EXPECT="${2:-}"; shift 2 ;;
    --no-dead-actions) DEAD_ACTIONS=0; shift ;;
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

case "$MIN_STATES" in
  ''|*[!0-9]*) echo "vacuity.sh: --min-states must be a non-negative integer" >&2; exit 2 ;;
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
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

[ -n "$KEEP_LOGS" ] && mkdir -p "$KEEP_LOGS"

# Gate.tla stays where central owns it; TLA-Library points at it. The scratch
# directory comes first so a generated VacuityGate is found.
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-DTLA-Library=$SCRATCH:$GATE_DIR"

# The NonVacuous operator to use. Gate!NonVacuous is the default; any other
# threshold gets a generated module, because Gate.tla is read-only here.
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
# PROBE 4 -- dead actions.
#
# Reuses probe 2's log rather than spending another TLC run, and only when
# that probe COMPLETED (rc=0). A run cut short by a violation has partial
# coverage, which would report live actions as dead.
# ===========================================================================
if [ "$DEAD_ACTIONS" = "1" ] && [ "$nv_rc" = "0" ]; then
  dead=$(scan_dead_actions "$nv_log")
  if [ -n "$dead" ]; then
    say "VECTOR 3: an action in your specification can never fire."
    say ""
    say "The state space is healthy and the model is configured, but part of"
    say "what you wrote is unreachable -- so the behaviour it describes was"
    say "never tested. TLC counts it as 0 total states generated."
    say ""
    while IFS=$'\t' read -r name aline amod loc lcount; do
      [ -z "$name" ] && continue
      say "  action $name (line $aline of module $amod) never fired."
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
    finish "VACUOUS_DEAD_ACTION" 5
  fi
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
if [ "$DEAD_ACTIONS" = "1" ] && [ "$nv_rc" = "0" ]; then
  say "Every action fired at least once."
else
  say "The dead-action probe did not run, so no action was proved live."
fi
finish "NON_VACUOUS" 0
