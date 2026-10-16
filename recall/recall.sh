#!/usr/bin/env bash
# recall.sh: grade one recall rep, and explain a wrong answer with the two
# values side by side (bead tla-wekw, epic tla-1sh7).
#
# A rep states a need in English and asks for the notation. This script takes
# the rep id and what was typed, drops the answer into a scaffold module beside
# the rep's constant environment, and asserts value equality against the
# canonical answer. Correctness is ONE EXIT CODE from harness/verdict.sh.
#
# Usage:
#   recall/recall.sh [OPTIONS] <rep-id> <answer>
#
# OPTIONS
#   --reps FILE       rep table (default: recall/REPS.tsv beside this script)
#   --env-dir DIR     constant environments (default: recall/env)
#   -q, --quiet       the status line only, no prompt and no value block
#   -h, --help        this text
#
# EXIT, and this is the contract the gate depends on: the exit code is the
# RAW CODE harness/verdict.sh RETURNED on the grading run, never a code
# inferred from anything TLC printed. Two codes are this script's own, and
# neither collides with a TLC code because both happen before TLC starts:
#
#     2   usage error -- a missing argument or an unknown flag
#     3   could not run -- no rep, no environment, no verdict.sh, no scratch
#
# THE GRADING SCAFFOLD, measured on TLC2 2026.07.31.184830:
#
#     ---- MODULE Recall ----
#     EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
#     <the rep's constant environment, spliced verbatim>
#     Answer == <what was typed>
#     ASSUME Answer = <the canonical answer>
#     ====
#
# with an empty .cfg beside it. The four rows of the epic's table, re-measured
# here 2026-10-16 over Wagons == {"a","b","c"} and Tracks == 1..3:
#
#     [Wagons -> Tracks]                  rc   0  OK                 correct
#     {f \in [Wagons -> Tracks] : TRUE}   rc   0  OK                 correct
#     [w \in Wagons |-> Tracks]           rc  10  ASSUMPTION_FAILED  not
#     [Tracks -> Wagons]                  rc  10  ASSUMPTION_FAILED  not
#
# ANY CORRECT FORM PASSES, because the comparison is on values rather than on
# text. That is the whole reason the grade is an ASSUME rather than a diff.
#
# Three more codes were measured and each gets its own report, because telling
# somebody their answer is wrong when it never parsed is a false statement
# about a check that did not run:
#
#     Answer == [Wagons ->             rc 150  PARSE_ERROR   unbalanced
#     Answer == Bogosity               rc 150  PARSE_ERROR   unknown name
#     Answer == 7                      rc  10  ASSUMPTION_FAILED
#
# The last one is the useful surprise: comparing a number to a set of
# functions is not an evaluation failure, it is simply false, so a type
# mismatch grades as a wrong answer and gets the value block like any other.
#
# THE DUAL VALUE BLOCK. On a wrong answer the script runs one more module per
# value, each one
#
#     ASSUME PrintT("recall-value")
#     ASSUME PrintT(<the value>)
#     ASSUME PrintT(Cardinality(<the value>))
#
# and shows the printed region. The sentinel is there so the start of the
# region is a string this script chose rather than a TLC banner.
#
# THE COUNT IS ATTEMPTED, NOT GUARDED, AND THAT IS NOT LAZINESS. Cardinality
# ERRORS on a value that is not a set:
#
#     Error: Evaluating assumption line 7 ... failed.
#     Attempted to compute cardinality of the value
#     [a |-> 1..3, b |-> 1..3, c |-> 1..3]
#
# and that error is part of the explanation rather than a failure -- it is
# often the clearest statement of the mistake, which is that a function was
# written where a set was asked for. So the value prints, the count is skipped,
# and the script says the count was skipped.
#
# There is no in-TLA+ guard available, and it was measured rather than assumed.
# IsFiniteSet([w \in Wagons |-> 1]) returns TRUE, rc 0, on the very value whose
# Cardinality errors, so `IF IsFiniteSet(x) THEN Cardinality(x) ELSE ...` would
# not skip anything. One value probe PER VALUE is what keeps the skip keyed on
# an exit code: a probe that exits nonzero printed no count, and nothing has to
# read TLC's prose to find that out.
#
# WHY THE PROBE'S rc IS NEVER THE GRADE. A probe exits 10 on the cardinality
# error, which is the SAME code a wrong answer scores on the grading run. The
# two runs are separate modules for exactly that reason, and only the grading
# run's code leaves this script.
#
# THE FIXED EXTENDS LIST is the contract an environment author writes against.
# Measured to reach `:>` and `@@` (both live in TLC, not in a base module),
# Len and Seq, record-field access, intervals, and negative integers. A rep
# needing a module outside the list is a one-line change to EXTENDS_LIST below
# and is not something an environment file can ask for, because TLA+ allows one
# EXTENDS statement and it has to come first.
#
# AN ENVIRONMENT FILE IS A FRAGMENT, NOT A MODULE. recall/env/<name>.tla holds
# bare definitions and nothing else: no module header, no EXTENDS, no trailing
# `====`. It is spliced verbatim into the scaffold, so it cannot be run on its
# own, and the .tla suffix is there for the editor rather than for SANY.
#
#     \* shunting -- three wagons, three tracks.
#     Wagons == {"a", "b", "c"}
#     Tracks == 1..3
#
# THREE NAMES ARE RESERVED and an environment that defines one of them makes
# every rep over it fail to parse, with SANY reporting a multiple declaration
# rather than anything about the rep: `Answer` and `Canonical` in the grading
# scaffold, `Shown` in the value probe.
#
# THE REP TABLE is tab-delimited with the literal first field REP, so prose in
# the file can never be read as data. Six fields:
#
#     1  REP          the literal marker
#     2  rep id       stable, never renumbered
#     3  construct    K001-K105, a drill/INVENTORY.md row
#     4  environment  resolves to <env-dir>/<name>.tla
#     5  prompt       English, naming none of the notation it asks for
#     6  canonical    the answer, as TLA+
#
# Rows are read with awk -F'\t', never with `IFS=$'\t' read`. Tab is an IFS
# whitespace character, so read collapses a run of tabs into one delimiter and
# drops a trailing empty field, which silently shifts every later field.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

EXTENDS_LIST="Naturals, Integers, Sequences, FiniteSets, TLC"
SENTINEL='"recall-value"'
TIMEOUT=60

VERDICT="${REPO_ROOT}/harness/verdict.sh"
REPS="${SCRIPT_DIR}/REPS.tsv"
ENV_DIR="${SCRIPT_DIR}/env"
QUIET=0
REP_ID=""
ANSWER=""
HAVE_ANSWER=0

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}"; }

die_usage() {
  printf 'recall.sh: %s\n' "$1" >&2
  usage >&2
  exit 2
}

# Exit 3 is "could not run", and it is deliberately not a verdict. Copied from
# drill/study/check, which reserves 3 for the same thing and for the same
# reason: a run that did not happen must not report a grade.
die_cannot_run() {
  printf 'recall.sh: %s\n' "$1" >&2
  exit 3
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --reps)    [ "$#" -ge 2 ] || die_usage "--reps needs a file"; REPS="$2"; shift 2 ;;
    --env-dir) [ "$#" -ge 2 ] || die_usage "--env-dir needs a directory"; ENV_DIR="$2"; shift 2 ;;
    -q|--quiet) QUIET=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    --)         shift; break ;;
    -*)         die_usage "unknown option: $1" ;;
    *)
      if [ -z "$REP_ID" ]; then
        REP_ID="$1"
      elif [ "$HAVE_ANSWER" = "0" ]; then
        ANSWER="$1"; HAVE_ANSWER=1
      else
        die_usage "unexpected extra argument: $1"
      fi
      shift ;;
  esac
done

# The remainder after `--`, so an answer beginning with a dash is reachable.
while [ "$#" -gt 0 ]; do
  if [ -z "$REP_ID" ]; then
    REP_ID="$1"
  elif [ "$HAVE_ANSWER" = "0" ]; then
    ANSWER="$1"; HAVE_ANSWER=1
  else
    die_usage "unexpected extra argument: $1"
  fi
  shift
done

[ -n "$REP_ID" ]        || die_usage "no rep id given"
[ "$HAVE_ANSWER" = "1" ] || die_usage "no answer given"

[ -x "$VERDICT" ] || die_cannot_run "no harness/verdict.sh at ${VERDICT}, so nothing was graded."
[ -r "$REPS" ]    || die_cannot_run "no rep table at ${REPS}, so nothing was graded."

# ---------------------------------------------------------------------------
# The rep.
# ---------------------------------------------------------------------------
ROW="$(awk -F'\t' -v id="$REP_ID" '$1 == "REP" && $2 == id { print; exit }' "$REPS")"
if [ -z "$ROW" ]; then
  die_cannot_run "${REPS} has no REP row with id ${REP_ID}, so nothing was graded."
fi

ENV_NAME="$(cut -f4 <<<"$ROW")"
PROMPT="$(cut -f5 <<<"$ROW")"
CANON="$(cut -f6 <<<"$ROW")"

[ -n "$ENV_NAME" ] || die_cannot_run "rep ${REP_ID} names no environment, so nothing was graded."
[ -n "$CANON" ]    || die_cannot_run "rep ${REP_ID} carries no canonical answer, so nothing was graded."

ENV_FILE="${ENV_DIR}/${ENV_NAME}.tla"
[ -r "$ENV_FILE" ] || die_cannot_run "rep ${REP_ID} names environment ${ENV_NAME}, and ${ENV_FILE} is not there, so nothing was graded."

# ---------------------------------------------------------------------------
# The scratch directory TLC runs in.
#
# A scratch directory this script cannot make is a hard error rather than a
# run in the working directory. The pattern is drill/study/check lines 724 to
# 764, and the reason is the same one: falling back would put TLC's states/
# tree and a scaffold module into whatever directory the caller happened to be
# standing in, which on a delivered practice tree holds the only copy of the
# work. "Could not run" is both true and safe.
# ---------------------------------------------------------------------------
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/recall.XXXXXXXX" 2>/dev/null)"
if [ -z "$SCRATCH" ] || [ ! -d "$SCRATCH" ]; then
  die_cannot_run "could not make a scratch directory to run TLC in, so nothing was graded."
fi
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
drop_scratch() { rm -rf "$SCRATCH"; }
trap drop_scratch EXIT

# ---------------------------------------------------------------------------
# The modules. Written here rather than through a shell heredoc on a command
# line: the isolation harness reads a TLA+ conjunction as a path leaving the
# worktree and a set literal as a brace group, and refuses both.
#
# Every interpolated value goes in through printf '%s' as an argument, so a
# learner's answer is never shell text. It can still be bad TLA+, and that is
# what rc 150 is for.
# ---------------------------------------------------------------------------
write_grade_module() {
  local path="$1" name="$2"
  {
    printf '%s\n' "---- MODULE ${name} ----"
    printf 'EXTENDS %s\n' "$EXTENDS_LIST"
    cat -- "$ENV_FILE"
    printf 'Answer == %s\n' "$ANSWER"
    printf 'Canonical == %s\n' "$CANON"
    printf 'ASSUME Answer = Canonical\n'
    printf '%s\n' "===="
  } >"$path"
}

write_value_module() {
  local path="$1" name="$2" expr="$3"
  {
    printf '%s\n' "---- MODULE ${name} ----"
    printf 'EXTENDS %s\n' "$EXTENDS_LIST"
    cat -- "$ENV_FILE"
    printf 'Shown == %s\n' "$expr"
    printf 'ASSUME PrintT(%s)\n' "$SENTINEL"
    printf 'ASSUME PrintT(Shown)\n'
    printf 'ASSUME PrintT(Cardinality(Shown))\n'
    printf '%s\n' "===="
  } >"$path"
}

# The printed region of a probe log: everything after the sentinel this script
# planted, up to TLC's next structural line.
#
# READ FOR DISPLAY, NEVER FOR A VERDICT. harness/verdict.sh's own header draws
# that line -- the log is "for HUMANS and for witness extraction, never for
# verdicts" -- and the grade in this script comes from the exit code of a
# different run entirely.
# The one line dropped is TLC's `Error: Evaluating assumption line N, col M ...
# of module Yours failed.` It cites a line of a module in a scratch directory
# that is already gone by the time anybody reads this, so it sends a reader
# somewhere they cannot go. The sentence under it, "Attempted to compute
# cardinality of the value X", is the part that says what went wrong, and it
# stays.
printed_region() {
  awk -v sentinel="$SENTINEL" '
    $0 == sentinel { on = 1; next }
    on && /^Computing initial states/ { exit }
    on && /^Finished computing/ { exit }
    on && /^Finished in / { exit }
    on && /^Model checking completed/ { exit }
    on && /^Error: Evaluating assumption line/ { next }
    on { print }
  ' "$1"
}

# One TLC run, through the one verdict channel. The token comes back on
# verdict.sh's stdout and the code comes back as its exit status, so neither is
# this script's opinion: verdict.sh owns the exit-code table, including the
# UNKNOWN_<rc> row that makes a renumbered TLC surface loudly instead of
# quietly matching a familiar name.
run_verdict() {
  local module="$1" cfg="$2" log="$3" stem rc=0
  stem="$(basename -- "$module" .tla)"
  VERDICT_TOKEN="$("$VERDICT" -t "$TIMEOUT" -c "$cfg" \
    --scratch "${SCRATCH}/states-${stem}" --log "$log" "$module" 2>/dev/null)" || rc=$?
  VERDICT_RC="$rc"
  [ -n "$VERDICT_TOKEN" ] || VERDICT_TOKEN="NO_TOKEN"
}

# ---------------------------------------------------------------------------
# The grading run. One TLC invocation, about 0.32 s measured over three runs
# on 2026-10-16 (316 / 388 / 351 ms), which is what makes this a drill rather
# than a quiz.
# ---------------------------------------------------------------------------
: >"${SCRATCH}/Recall.cfg"
write_grade_module "${SCRATCH}/Recall.tla" "Recall"
run_verdict "${SCRATCH}/Recall.tla" "${SCRATCH}/Recall.cfg" "${SCRATCH}/Recall.log"
GRADE_RC="$VERDICT_RC"
GRADE_TOKEN="$VERDICT_TOKEN"

case "$GRADE_RC" in
  0)   GRADE="correct" ;;
  10)  GRADE="incorrect" ;;
  150) GRADE="parse-error" ;;
  *)   GRADE="other" ;;
esac

if [ "$QUIET" = "0" ]; then
  printf '%s  %s\n' "$REP_ID" "$PROMPT"
fi
printf 'rep=%s rc=%s token=%s grade=%s\n' "$REP_ID" "$GRADE_RC" "$GRADE_TOKEN" "$GRADE"

if [ "$QUIET" = "1" ]; then
  exit "$GRADE_RC"
fi

echo

if [ "$GRADE" = "correct" ]; then
  echo "correct."
  exit "$GRADE_RC"
fi

if [ "$GRADE" = "parse-error" ]; then
  echo "that did not parse, so nothing was graded about whether it is right."
  echo
  # SANY's own sentence, which names the line and the operator. Display only.
  grep -hE 'was not declared|Encountered|Unknown operator|Precedence conflict|Lexical error|Was expecting' \
    "${SCRATCH}/Recall.log" 2>/dev/null | sed -n 's/^[[:space:]]*/  /p' | sort -u
  exit "$GRADE_RC"
fi

if [ "$GRADE" = "other" ]; then
  printf 'the grading run came back %s, which is neither correct nor a wrong answer.\n' "$GRADE_RC"
  printf 'that is a report about the run rather than about the answer.\n'
  exit "$GRADE_RC"
fi

# ---------------------------------------------------------------------------
# The dual value block. One probe per value, so a count skipped on one side
# cannot cost the other side its value.
# ---------------------------------------------------------------------------
echo "not correct. what you typed, then the answer."

show_value() {
  local label="$1" name="$2" expr="$3"
  : >"${SCRATCH}/${name}.cfg"
  write_value_module "${SCRATCH}/${name}.tla" "$name" "$expr"
  run_verdict "${SCRATCH}/${name}.tla" "${SCRATCH}/${name}.cfg" "${SCRATCH}/${name}.log"
  echo
  printf '%-11s %s\n' "$label" "$expr"
  local region
  region="$(printed_region "${SCRATCH}/${name}.log")"
  if [ -z "$region" ]; then
    echo "  that value could not be evaluated at all, so there is nothing to show."
    return
  fi
  sed -n 's/^/  /p' <<<"$region"
  # The count is skipped exactly when the probe exited nonzero. Keyed on the
  # code, not on the error text above it.
  if [ "$VERDICT_RC" != "0" ]; then
    echo "  (no count: TLC will not count that value, so it is not a set)"
  fi
}

show_value "you typed" "Yours" "$ANSWER"
show_value "the answer" "Canon" "$CANON"

exit "$GRADE_RC"
