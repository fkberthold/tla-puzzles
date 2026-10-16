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
# OPTIONS, and every one of them goes BEFORE the rep id. Once the rep id is in
# hand the next argument is the answer, whatever it starts with.
#   --reps FILE       rep table (default: recall/REPS.tsv beside this script)
#   --env-dir DIR     constant environments (default: recall/env)
#   --full            print each value whole, however long it runs
#   -q, --quiet       the status line only, no prompt and no value block
#   -h, --help        this text
#
# AN ANSWER BEGINNING WITH A DASH NEEDS NOTHING IN FRONT OF IT. Negative
# integers are ordinary answers at this rung -- R012 is a thermometer reading
# below zero and R075 is a negative interval -- so `recall.sh R012 -4` grades.
# The `--` escape still works wherever it appears, and it was the only route
# until 2026-10-16, which cost a learner typing the right answer a usage dump.
#
# EXIT, and this is the contract the gate depends on: the exit code is the
# RAW CODE harness/verdict.sh RETURNED on the grading run, never a code
# inferred from anything TLC printed. Three codes are this script's own and
# none of them collides with a code of TLC's:
#
#     2   usage error -- a missing argument or an unknown flag
#     3   could not run -- no rep, no environment, no verdict.sh, no scratch
#     4   the value is right and the construct the rep drills is not in what
#         was typed. See THE CONSTRUCT GATE below
#
# 2 and 3 happen before TLC starts, so there is no verdict to be faithful to.
# 4 is the one that happens after a run, and it replaces a grading run that
# came back 0: the status line carries 4 and the runner's own token, and the
# line under it names the rc and token verdict.sh returned, so nothing the
# channel said is hidden. 4 sits in the 3-to-7 range harness/vacuity.sh:320
# reserves for statements about the submission.
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
# THE CONSTRUCT GATE, field 7 of the rep table.
#
# Value equality grades the value, so it cannot see how the value was reached.
# A learner who computes the right answer without writing the construct the rep
# drills has not done the rep. Field 7 carries an ERE matched against the RAW
# ANSWER TEXT, and a rep without one grades exactly as it did before the field
# existed, which is why nothing in recall/REPS.tsv had to change.
#
# THE PATTERN NAMES THE CONSTRUCT'S OWN KEYWORD AND NOTHING ELSE. Any correct
# form passing is what lets this rung grade without a model in the loop, and a
# pattern that reaches for the shape of the whole answer gives that away. All
# three of these are the same answer to a LET rep, and `\bLET\b` takes all
# three where `^LET [A-Za-z]+\(t\) ==` takes one:
#
#     LET Twice(t) == t * 2 IN [t \in Tracks |-> Twice(t)]
#     LET Doubled(n) == n + n IN [t \in Tracks |-> Doubled(t)]
#     LET F == [t \in Tracks |-> t * 2] IN F
#
# THE MATCH RUNS BEFORE TLC AND THE REFUSAL AFTER IT. Matching first means a
# pattern grep will not read is "could not run" at exit 3 rather than a grade,
# and a gate that fell open on a malformed pattern would be worse than no gate.
# Refusing afterwards means a WRONG value still gets the dual value block,
# which is the half of this script that teaches, and the gate only ever speaks
# about an answer the grading run already accepted.
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
# THE VALUE BLOCK IS CAPPED, because this rung is seconds a rep and a block
# that scrolls the terminal costs more attention than the mistake did. One
# wrong answer to the function-set rep ran to 40 lines, 27 of them the members
# of [Wagons -> Tracks] one per line, with the count that makes the point
# underneath them. `--full` prints the whole thing.
#
# The cap counts LINES rather than members, and the wording on the elision
# says so. TLC prints a small value on one line and breaks a large one at
# about 80 columns, one member per line, so on a flat set a line is a member
# and the two readings agree. They part company on a nested value, where
# `[ a |->` opens at one indent and the set under it sits at another, and a
# cap claiming to count members there would be counting something else. The
# member count survives either way: the probe prints it on a line of its own
# and that line is inside the tail the cap keeps.
#
# BOTH HALVES ARE CAPPED ON THE SAME RULE. The typed value is usually the
# small one, but it is not always: at R108 and R109 the characteristic mistake
# is to swap the domain and the range, and that produces a set of exactly the
# size of the right answer. Two members, the elision, the closing member and
# the count comes to five lines, which is still enough to recognize as yours.
#
# THE REP TABLE is tab-delimited with the literal first field REP, so prose in
# the file can never be read as data. Six fields, and an optional seventh:
#
#     1  REP          the literal marker
#     2  rep id       stable, never renumbered
#     3  construct    K001-K105, a drill/INVENTORY.md row
#     4  environment  resolves to <env-dir>/<name>.tla
#     5  prompt       English, naming none of the notation it asks for
#     6  canonical    the answer, as TLA+
#     7  requires     OPTIONAL. An ERE the raw answer has to match before a
#                     correct value is accepted. Absent or empty is no gate
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

# The runner's own code for "the value is right and the construct is not in
# what was typed". Bound to a name rather than written as a literal at the exit
# site, which is the convention harness/verdict.sh uses for its own 99.
EXIT_CONSTRUCT_MISSING=4
CONSTRUCT_TOKEN="CONSTRUCT_NOT_WRITTEN"

# How much of a value survives the cap: the first two lines and the last two.
# Two at the head because the second is what shows which position moves first,
# which is the whole content of a function set. Two at the tail because the
# last two lines of a set's block are the closing member, which carries the
# ` }`, and the count underneath it.
VALUE_HEAD=2
VALUE_TAIL=2

VERDICT="${REPO_ROOT}/harness/verdict.sh"
REPS="${SCRIPT_DIR}/REPS.tsv"
ENV_DIR="${SCRIPT_DIR}/env"
QUIET=0
FULL=0
REP_ID=""
ANSWER=""
HAVE_ANSWER=0

# Lines 2 to 19 of this file: what the script is, how it is called, and the
# flags. The range is a line number and nothing gates it, so moving the OPTIONS
# block means moving this too.
usage() { sed -n '2,19p' "${BASH_SOURCE[0]}"; }

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
  # `--` ends the options wherever it stands, so every call that already used
  # the escape keeps working. It is checked first for that reason: the rule
  # under it would otherwise swallow a `--` typed after the rep id.
  if [ "$1" = "--" ]; then shift; break; fi

  # ONCE THE REP ID IS IN HAND THE NEXT ARGUMENT IS THE ANSWER, whatever it
  # starts with. This is the whole fix for a negative-integer rep: `-4` is the
  # right answer to R012, and a learner who types it has no way to guess an
  # escape. The cost is that a flag goes before the rep id, which is where
  # every caller already puts it.
  if [ -n "$REP_ID" ] && [ "$HAVE_ANSWER" = "0" ]; then
    ANSWER="$1"; HAVE_ANSWER=1; shift; continue
  fi

  case "$1" in
    --reps)    [ "$#" -ge 2 ] || die_usage "--reps needs a file"; REPS="$2"; shift 2 ;;
    --env-dir) [ "$#" -ge 2 ] || die_usage "--env-dir needs a directory"; ENV_DIR="$2"; shift 2 ;;
    --full)     FULL=1; shift ;;
    -q|--quiet) QUIET=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    -*)         die_usage "unknown option: $1" ;;
    *)
      if [ -z "$REP_ID" ]; then
        REP_ID="$1"
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
# A six-field row has no field 7 and cut returns the empty string for it, which
# is the same thing an empty field 7 says: no gate.
REQUIRES="$(cut -f7 <<<"$ROW")"

[ -n "$ENV_NAME" ] || die_cannot_run "rep ${REP_ID} names no environment, so nothing was graded."
[ -n "$CANON" ]    || die_cannot_run "rep ${REP_ID} carries no canonical answer, so nothing was graded."

# The construct gate's match, run here rather than after the grading run so
# that a pattern grep will not read is "could not run" instead of a grade. A
# gate that fell open on a malformed pattern would be worse than no gate: the
# row would look gated and would not be. What the match DOES happens further
# down, after TLC has said whether the value is right.
#
# A here-string, never a pipe into a quiet grep. Under pipefail an
# early-exiting consumer closes the pipe, the producer takes SIGPIPE, the
# pipeline reports 141, and inside an `if` that is merely falsy. So a PRESENT
# pattern would report as ABSENT and the gate would fire on a correct answer.
REQUIRES_MET=1
if [ -n "$REQUIRES" ]; then
  MATCH_RC=0
  grep -qE -- "$REQUIRES" <<<"$ANSWER" || MATCH_RC=$?
  case "$MATCH_RC" in
    0) REQUIRES_MET=1 ;;
    1) REQUIRES_MET=0 ;;
    *) die_cannot_run "rep ${REP_ID} carries a field-7 pattern grep will not read as an expression, so nothing was graded." ;;
  esac
fi

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

# The construct gate's refusal. It only ever replaces a grading run that came
# back 0, so a wrong value keeps its value block and the gate has nothing to
# say about it. REPORT_RC is what leaves this script; GRADE_RC stays the
# verdict channel's own number and is printed under the refusal.
REPORT_RC="$GRADE_RC"
REPORT_TOKEN="$GRADE_TOKEN"
if [ "$GRADE" = "correct" ] && [ "$REQUIRES_MET" = "0" ]; then
  GRADE="construct-missing"
  REPORT_RC="$EXIT_CONSTRUCT_MISSING"
  REPORT_TOKEN="$CONSTRUCT_TOKEN"
fi

if [ "$QUIET" = "0" ]; then
  printf '%s  %s\n' "$REP_ID" "$PROMPT"
fi
printf 'rep=%s rc=%s token=%s grade=%s\n' "$REP_ID" "$REPORT_RC" "$REPORT_TOKEN" "$GRADE"

if [ "$QUIET" = "1" ]; then
  exit "$REPORT_RC"
fi

echo

if [ "$GRADE" = "correct" ]; then
  echo "correct."
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "construct-missing" ]; then
  echo "the value is right. the construct this rep drills is not in what you typed."
  echo
  printf '  wanted somewhere in the answer:  %s\n' "$REQUIRES"
  printf '  the grading run came back rc=%s token=%s, so only the form is at issue.\n' \
    "$GRADE_RC" "$GRADE_TOKEN"
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "parse-error" ]; then
  echo "that did not parse, so nothing was graded about whether it is right."
  echo
  # SANY's own sentence, which names the line and the operator. Display only.
  grep -hE 'was not declared|Encountered|Unknown operator|Precedence conflict|Lexical error|Was expecting' \
    "${SCRATCH}/Recall.log" 2>/dev/null | sed -n 's/^[[:space:]]*/  /p' | sort -u
  exit "$REPORT_RC"
fi

if [ "$GRADE" = "other" ]; then
  printf 'the grading run came back %s, which is neither correct nor a wrong answer.\n' "$GRADE_RC"
  printf 'that is a report about the run rather than about the answer.\n'
  exit "$REPORT_RC"
fi

# ---------------------------------------------------------------------------
# The dual value block. One probe per value, so a count skipped on one side
# cannot cost the other side its value.
# ---------------------------------------------------------------------------
echo "not correct. what you typed, then the answer."

# The cap. A region short enough to read comes back untouched, byte for byte,
# and so does every region under --full.
#
# head and tail take a HERE-STRING rather than a pipe. The region is already
# in a variable, and piping a printf into either one would hand an
# early-exiting consumer a live pipe: the consumer closes it on its last line,
# the producer takes SIGPIPE, and under pipefail the whole thing comes back
# 141. A here-string is materialised before the consumer is exec'd, so there
# is no writer left to signal.
#
# The elision carries two leading spaces because the region's own continuation
# lines do, and show_value indents the lot by two more. That puts the three
# dots under the members rather than under the opening brace.
cap_region() {
  local region="$1" n elided
  n="$(wc -l <<<"$region")"
  if [ "$FULL" = "1" ] || [ "$n" -le "$((VALUE_HEAD + VALUE_TAIL + 1))" ]; then
    printf '%s\n' "$region"
    return
  fi
  elided="$((n - VALUE_HEAD - VALUE_TAIL))"
  head -n "$VALUE_HEAD" <<<"$region"
  printf '  ... %s more lines, and --full shows them all ...\n' "$elided"
  tail -n "$VALUE_TAIL" <<<"$region"
}

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
  region="$(cap_region "$region")"
  sed -n 's/^/  /p' <<<"$region"
  # The count is skipped exactly when the probe exited nonzero. Keyed on the
  # code, not on the error text above it.
  if [ "$VERDICT_RC" != "0" ]; then
    echo "  (no count: TLC will not count that value, so it is not a set)"
  fi
}

show_value "you typed" "Yours" "$ANSWER"
show_value "the answer" "Canon" "$CANON"

exit "$REPORT_RC"
