#!/usr/bin/env bash
# verdict.sh — The harness's single verdict channel (V2-PLAN.md §5.1, bead tla-kl5.4).
#
# Runs TLC once and reports what happened as ONE TOKEN DERIVED SOLELY FROM THE
# PROCESS EXIT STATUS. Nothing in this file reads, matches, or reasons about
# TLC's stdout. Every other harness component (§5.2 grading, §5.3 vacuity
# probes, §5.4 refinement, §5.5 seeded bugs) branches on this token, so this
# is the one place the exit-code table lives.
#
# WHY NOT STDOUT: TLC's console text is a presentation surface, not an API. It
# changes between releases, it is localized by nothing and formatted by whim,
# and its phrases overlap (a spec can print "Finished in" after a fatal parse
# error). scripts/verify-puzzle.sh's elif-chain of greps is the cautionary
# tale: it matched "Finished in" on a spec that never parsed and reported a
# PASS. Exit codes do not have that failure mode.
#
# USAGE
#   harness/verdict.sh [OPTIONS] <module.tla> [-- <extra tlc args>...]
#
# OPTIONS
#   -c, --config FILE       .cfg to use, relative paths taken from the caller's
#                           cwd (default: <module>.cfg beside the module)
#   -t, --timeout SECS      wall-clock budget (default: 60)
#   -p, --postcondition E   TLC -postCondition expression, e.g. Gate!NonVacuous
#   -d, --check-deadlock    check for deadlock (default: OFF -- see below)
#       --deadlock-override KEEP deadlock checking off even when the .cfg's
#                           CHECK_DEADLOCK keyword asks for it. Says "I know,
#                           and I mean it" -- see THE DEADLOCK CONFLICT below
#       --trace FILE        keep the JSON counterexample trace here
#       --log FILE          keep TLC's combined output here (for HUMANS and for
#                           witness extraction -- never for verdicts)
#       --scratch DIR       metadir parent; created if absent, kept if given
#   -q, --quiet             suppress the verdict token on stdout
#   -h, --help              this text
#
# OUTPUT
#   stdout: the verdict token, one line (unless --quiet)
#   exit:   TLC's RAW exit status, unmodified, so callers may branch on either
#           the token or the number. NOTE for callers under `set -e`: a
#           nonzero exit here is a VERDICT, not a crash; capture it with
#           `out=$(verdict.sh ...) || rc=$?` or disable errexit around it.
#
# VERDICT TABLE — every row measured on the TLC 2026.03.04.183147 nightly on
# 2026-08-06 by driving a purpose-built fixture in fixtures/verdict/, then
# re-measured unchanged on tla2tools v1.8.0 (TLC 2026.07.31.184830) on
# 2026-08-07. Two builds four months apart return the same numbers, so this
# table is a fact about TLC rather than about one jar. Do not edit a row
# without re-running harness/test-verdict.sh; the test asserts the raw
# numbers, not just the tokens, precisely so that a renumbered TLC breaks the
# build instead of quietly relabelling itself.
#
#      0  OK                     no error found
#     10  ASSUMPTION_FAILED      ASSUME false, or -postCondition false
#     11  DEADLOCK               reachable state with no successor
#     12  SAFETY_VIOLATION       something refutable by a finite prefix -- an
#                                INVARIANT, or a PROPERTY that is a safety
#                                property. NOT "an INVARIANT was violated"
#     13  LIVENESS_VIOLATION     a PROPERTY needing an infinite behaviour, or
#                                an implied action; incl. refinement, §5.4
#     14  ASSERT_VIOLATION       Assert(FALSE, ...) DURING BEHAVIOUR EXPLORATION
#     75  SPEC_EVAL_FAILURE      the spec could not be evaluated
#     76  SAFETY_EVAL_FAILURE    the INVARIANT could not be evaluated
#     77  LIVENESS_EVAL_FAILURE  the PROPERTY could not be checked
#    124  TIMEOUT                killed by timeout(1) -- its OWN verdict
#    150  PARSE_ERROR            parse or semantic failure, incl. a missing .tla
#    151  CONFIG_ERROR           .cfg names something the spec does not define
#    255  TLC_EXCEPTION          TLC's catch-all: missing/unparseable .cfg, etc.
#      *  UNKNOWN_<rc>           never silently folded into an existing row
#
# AND ONE ROW THAT IS NOT TLC'S (bead tla-hl96):
#
#     99  CHECK_DID_NOT_RUN      a check this script was asked for could not be
#                                performed, so TLC was never started. NOT a
#                                verdict about the spec. Project-wide reserved
#                                code; harness/test-indeterminate.sh is the
#                                gate, and it also asserts the non-collision.
#
#   This is the ONE departure from "exit with TLC's raw status", and it is a
#   departure only in the sense that `exit 2` for a usage error already was:
#   both happen BEFORE the run, so there is no TLC status to be faithful to.
#   The guarantee the OUTPUT section states is about runs that happened. 99
#   and 2 are the two ways this script declines to produce one.
#
# THE FOUR EVALUATION-FAILURE ROWS ARE NOT VIOLATION ROWS (bead tla-i9m). The
# distinction is the reason they have their own tokens rather than sharing 12's
# or 13's:
#
#   12 and 13 mean the property WAS CHECKED and came out false. There is a
#   counterexample; the spec itself is fine. A learner should hear "your
#   property does not hold, here is the trace".
#
#   75, 76 and 77 mean the check NEVER HAPPENED. The spec did not evaluate, or
#   the invariant blew up mid-evaluation, or TLC refused the temporal formula.
#   Nothing at all is known about whether the property holds. A learner should
#   hear "your spec did not evaluate", and telling them "your property was
#   violated" would be a false statement about a check that never ran.
#
# 12 AND 13 SPLIT ON THE SHAPE OF THE FORMULA, NOT ON THE .cfg KEYWORD THAT
# INTRODUCED IT (bead tla-94n). Row 13 used to read "PROPERTY violated", and a
# reader takes that as "a violated PROPERTY exits 13". It does not always.
# Measured on v1.8.0 over one two-state spec, each property declared ALONE with
# NO INVARIANT in the .cfg:
#
#     [](P => []P)    12        []<>P         13
#     [](P => []Q)    12        <>[]P         13
#     ~<>P            12        <>P           13
#     []P             12        P ~> Q        13
#                               [][A]_vars    13
#
#   The left column is what TLC can refute with a finite prefix. Those are
#   safety properties written with a temporal operator, so TLC reports a safety
#   violation and exits 12. The right column needs an infinite behaviour, and
#   on this spec every counterexample ended in a Stuttering step. []P over a
#   state predicate is a separate case in the same column: TLC lifts it into an
#   invariant outright and prints "Invariant P is violated".
#
#   [][A]_vars shows the rule is not simply about prefixes. Its counterexample
#   is finite too, but TLC checks a boxed action through the implied-action
#   channel, and that channel is 13 whatever the trace looks like.
#
#   THE SHARPER CONSEQUENCE RUNS THE OTHER WAY. rc=12 does not imply an
#   INVARIANT was violated, and the probe that showed it declared no invariant
#   anywhere. A caller reading 12 as "the invariant failed" is guessing.
#   grade.sh:391 reads it as "the refutation obligation was MET", which is a
#   live hazard for the temporal obligations tla-59s wants to add.
#
#   NOT AFFECTED: §5.4 refinement. The implied-init and the implied-action
#   obligation TLC derives from Abstract!Spec both exit 13, so refinement.sh's
#   lone `13)` arm routes correctly. It has one hole, and it is the one this
#   row predicts: an abstract spec whose own Spec formula carries a
#   safety-shaped temporal conjunct exits 12 and falls into that script's
#   catch-all. Measured, and filed rather than fixed here.
#
#   AND THE CONSOLE CANNOT TELL YOU EITHER. [](P => []P) and <>P both print
#   "Temporal property X was violated" under the same message code 2116, then
#   exit 12 and 13. TLC's status comes from what process() returns, not from
#   what it printed, so even -tool mode's structured codes get this one wrong.
#   The exit code is not just the best channel here. It is the only correct one.
#
# rc=14 IS A TIMING FACT, NOT A CONSTRUCT FACT. It does not mean "an Assert
# failed"; it means an Assert failed once TLC was already exploring behaviour.
# The identical Assert(FALSE, ...) in Init exits 75, because the initial-state
# computation wraps the EvalException as EC.TLC_NESTED_EXPRESSION instead of
# letting the assertion's own error code through. AssertViolation.tla and
# AssertInInit.tla are the measured pair, and test-verdict.sh pins both so that
# a TLC which stopped distinguishing them breaks the build.
#
# 75 IS A FAMILY, NOT A CONDITION. EC.errorConstantToExitStatus routes at least
# TLC_NESTED_EXPRESSION (2103), TLC_STATE_NOT_COMPLETELY_SPECIFIED_NEXT (2109),
# TLC_STATES_AND_NO_NEXT_ACTION (2115) and TLC_FINGERPRINT_EXCEPTION (2147) to
# it. That is no different in kind from 255, which already covers a missing
# .cfg and a garbage .cfg and a duplicated SPECIFICATION line: a token names
# the CHANNEL, not the cause. The cause is in the log, which is written for
# humans and never read for a verdict.
#
# WHAT IS DELIBERATELY MISSING: ERROR_STATESPACE_TOO_LARGE=152 and
# ERROR_SYSTEM=153. Both are declared in the jar's own EC$ExitStatus enum, and
# neither is mapped here, because no fixture provokes them and the reason is
# not "nobody tried". Disassembling every class in tla2tools v1.8.0 finds no
# bytecode anywhere that pushes 152 or 153 as an exit value -- the only
# `sipush 152/153` sites in the whole jar are parser token constants and
# bundled third-party libraries -- and both are absent from the enum's own
# `knownExitValues` set. They are dead constants in this build. A mapping
# nobody has measured is a guess wearing a table's authority, so if a future
# TLC starts emitting one it arrives as a loud UNKNOWN_152 and gets measured
# before it gets named. test-verdict.sh asserts the absence of those two arms.
#
# DEPARTURES FROM THE V2-PLAN.md §5.1 TABLE, all measured, all deliberate:
#
#   §5.1 lists 255 as "file not found". Measured, the two halves of "file not
#   found" split across two codes: a missing MODULE is 150 (SANY reports
#   "Cannot find source file"), while a missing CONFIG is 255. And 255 is not
#   specific to missing files at all -- a .cfg containing garbage tokens, or a
#   duplicated SPECIFICATION line, also exits 255 via the same
#   ConfigFileException catch-all. Naming that token FILE_NOT_FOUND would make
#   the tutor tell a learner with a typo'd .cfg that their file is missing, so
#   the token here is TLC_EXCEPTION and the §5.1 row is recorded as one
#   instance of it rather than as its definition.
#
#   §5.1 lists 151 as "config failure" without qualification. Measured, 151 is
#   only the SEMANTIC half: the .cfg parsed but names an operator the spec
#   does not define. Config SYNTAX failures are 255 (above), and a .cfg
#   keyword with a missing operand -- e.g. a bare `INVARIANT` line -- is not an
#   error at all: TLC exits 0 having silently checked no invariant. That last
#   one is a live vacuity hazard for §5.3, and DanglingKeyword.cfg pins it.
#
# THE DEADLOCK CONFLICT — WHY A .cfg KEYWORD CAN REFUSE THE RUN (bead tla-hl96)
#
#   TLC's deadlock checking is an AND across the .cfg's CHECK_DEADLOCK keyword
#   and the command line's -deadlock flag. Either side switches it off, and
#   NEITHER SIDE SAYS SO. Measured on TLC 2026.07.31.184830, all six cells,
#   against fixtures/indeterminate/DeadlockKeyword.tla, whose x = 2 state has
#   no successor:
#
#       cfg keyword   -deadlock on the command line   rc
#       -----------   -----------------------------   ----
#       absent        absent                            11
#       absent        present                            0
#       TRUE          absent                            11
#       TRUE          present                            0
#       FALSE         absent                             0
#       FALSE         present                            0
#
#   Rows 4 and 5 are the defect. In row 4 a learner writes the keyword that
#   checks for a deadlock, on a module that HAS one, and gets a clean run: the
#   keyword they wrote is overridden by a flag they never see. In row 5 the
#   caller's own --check-deadlock is discarded by the .cfg instead. Either way
#   a check that was asked for did not happen and nothing reported it.
#
#   82 of 337 configs in the published corpus carry a CHECK_DEADLOCK line
#   (.claude/rules/tla-practice.md §7), so this is ordinary practice rather
#   than an exotic path.
#
#   THE DESIGN CALL, between the two the bead named. This script does NOT stop
#   passing -deadlock and let the .cfg speak. TLC's default with no keyword
#   and no flag is checking ON (row 1), so honouring a silent .cfg would turn
#   every intended-terminal-state reference red -- and 79 of 337 corpus
#   configs write CHECK_DEADLOCK FALSE precisely because their terminal states
#   are intended. 334 of the .cfg files in this repo carry that line.
#
#   So the flag stays, and a DISAGREEMENT between the two sides refuses the
#   run at 99 rather than producing a verdict over a check that did not
#   happen. Agreement is not disagreement: CHECK_DEADLOCK FALSE with the
#   default flag, and CHECK_DEADLOCK TRUE with --check-deadlock, both run
#   exactly as they did before. That asymmetry is the whole point -- a refusal
#   keyed on the keyword's PRESENCE would break all 334.
#
#   --deadlock-override IS THE DECLARED OVERRIDE, and it exists because one
#   caller legitimately means it. harness/vacuity.sh runs every probe with
#   deadlock checking off on purpose: a terminal state would exit 11 before
#   the probe meant anything, and the probe's .cfg is a COPY of the learner's,
#   keyword and all. Before this flag that override was silent, which is the
#   same defect one level down. Now it is a word at the call site.
#
# WORKER COUNT — -workers 1 IS MANDATORY AND IS NOT AN OPTION HERE.
#
#   Counterexamples are nondeterministic above one worker: five runs at
#   -workers 8 produced three different traces. Any harness output that IS a
#   trace -- a grading witness, a seeded-bug counterexample, a refinement
#   failure -- is therefore unreproducible unless the worker count is pinned.
#
#   The distinction that matters, because it is what tempts people to "fix"
#   this: state COUNTS are stable. They were measured identical across workers
#   1/4/8, across three fingerprint polynomials, and across TLC 2.15 through
#   2026.03.04 -- and the counts this suite asserts were unchanged again on
#   2026.07.31. So the constraint bites ONLY where a trace is the output --
#   and since this script cannot know which caller wants a trace, it pins the
#   worker count for all of them. If you are here to raise it for speed:
#   raising it is correct only for a caller that consumes counts and never
#   traces, and that caller does not exist yet. Do not add a flag for it
#   without one.

set -uo pipefail

# The reserved project-wide code for "a check this instrument was asked for
# could not be performed". Bound to a name here rather than written as a
# literal at the exit site; harness/test-indeterminate.sh asserts the binding,
# the token, and that nothing else in the tree documents 99 as anything else.
EXIT_INDETERMINATE=99
INDETERMINATE_TOKEN="CHECK_DID_NOT_RUN"

TIMEOUT=60
CONFIG=""
POSTCOND=""
CHECK_DEADLOCK=0
DEADLOCK_OVERRIDE=0
TRACE=""
LOG=""
SCRATCH=""
QUIET=0
MODULE=""
EXTRA=()

usage() {
  cat <<'USAGE'
usage: harness/verdict.sh [OPTIONS] <module.tla> [-- <extra tlc args>...]

  -c, --config FILE        .cfg to use, relative to your cwd
                           (default: <module>.cfg beside the module)
  -t, --timeout SECS       wall-clock budget (default: 60)
  -p, --postcondition EXPR TLC -postCondition expression
  -d, --check-deadlock     check for deadlock (default: off)
      --deadlock-override  keep deadlock checking off even when the .cfg's
                           CHECK_DEADLOCK keyword asks for it
      --trace FILE         keep the JSON counterexample trace
      --log FILE           keep TLC's combined output
      --scratch DIR        metadir parent
  -q, --quiet              do not print the verdict token
  -h, --help               this text

Prints one verdict token; exits with TLC's raw status.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--config)         CONFIG="${2:-}"; shift 2 ;;
    -t|--timeout)        TIMEOUT="${2:-}"; shift 2 ;;
    -p|--postcondition)  POSTCOND="${2:-}"; shift 2 ;;
    -d|--check-deadlock) CHECK_DEADLOCK=1; shift ;;
    --deadlock-override) DEADLOCK_OVERRIDE=1; shift ;;
    --trace)             TRACE="${2:-}"; shift 2 ;;
    --log)               LOG="${2:-}"; shift 2 ;;
    --scratch)           SCRATCH="${2:-}"; shift 2 ;;
    -q|--quiet)          QUIET=1; shift ;;
    -h|--help)           usage; exit 0 ;;
    --)                  shift; EXTRA=("$@"); break ;;
    -*)                  echo "verdict.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$MODULE" ]; then
        echo "verdict.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      MODULE="$1"; shift ;;
  esac
done

if [ -z "$MODULE" ]; then
  echo "verdict.sh: no module given" >&2
  usage >&2
  exit 2
fi

# Deliberately NO existence check on the module or the .cfg. "That file is not
# there" is a verdict TLC issues (150 and 255 respectively), and short-
# circuiting it here would substitute this script's opinion for the channel the
# whole harness is built on.
MODULE_DIR=$(dirname "$MODULE")
MODULE_BASE=$(basename "$MODULE" .tla)
if [ -z "$CONFIG" ]; then
  CONFIG="$MODULE_DIR/$MODULE_BASE.cfg"
fi

# THE .cfg PATH IS RESOLVED HERE, NOT BY TLC (bead tla-sn0h).
#
# TLC calls ToolIO.setUserDir(<the module's directory>) when, and only when,
# the module argument is absolute -- `File.isAbsolute()` at bytecode 4708 of
# tlc2.TLC.process, guarding the setUserDir at 4740. That moves the base every
# later relative path resolves against, so the SAME --config string names two
# different files depending on the form of an unrelated argument. Measured on
# tla2tools v1.8.0 with one .cfg and one module: rel/rel, rel/abs and abs/abs
# all exit 0, while abs module + rel --config exits 255 TLC_EXCEPTION on a file
# the caller can see from where they stand. A missing-file verdict for a file
# that is present is exactly the mislabelling §5.1 exists to stop.
#
# So a relative --config means what it means everywhere else in a shell:
# relative to the caller's cwd, whatever the module argument looks like. A
# caller who wants the .cfg beside the module omits -c and gets it by default,
# which is the line above.
#
# THIS IS NOT AN EXISTENCE CHECK. Nothing here asks whether the file is there.
# Point -c at nothing and TLC still says so, still through 255, and now it says
# so about the path you actually named.
#
# The MODULE is deliberately left alone. Absolutising it would move TLC's
# search for auxiliary modules off the cwd as well, and Gate.tla reaches
# several callers that way. harness/vacuity.sh:94 measured that half of the
# same trap and wants the absolute form; it passes both paths absolute already,
# so it is untouched by this.
case "$CONFIG" in
  /*) ;;
  *)  CONFIG="$PWD/$CONFIG" ;;
esac

# ---------------------------------------------------------------------------
# THE .cfg's CHECK_DEADLOCK KEYWORD, read with shell builtins ONLY.
#
# No external matcher is used here, and that is a constraint rather than a
# preference. harness/test-verdict.sh asserts structurally that this file
# contains no text matcher at all, because the one thing it must never do is
# read a VERDICT out of text. A .cfg is an INPUT and scanning it is a
# different act from scanning TLC's output -- but the structural ban cannot
# tell the two apart, and weakening a ban that has already caught one real
# regression would cost more than writing the scan by hand.
#
# COMMENT HANDLING, both forms, because a .cfg may mention the keyword in
# prose and a gate that fires on prose is worse than no gate:
#
#   \*          to end of line
#   (*  ...  *) nesting, and spanning lines
#
# The tokens accumulate across the WHOLE file rather than line by line. TLC's
# config parser is token-based, so `CHECK_DEADLOCK` may sit on one line with
# its value on the next, and a line-wise scan would miss it.
#
# TLC REFUSES A DUPLICATE KEYWORD -- "The keyword CHECK_DEADLOCK appeared
# twice", ConfigFileException, rc 255, measured. So there is at most one legal
# occurrence; taking the last is defensive rather than meaningful.
# ---------------------------------------------------------------------------
CFG_DEADLOCK=""
scan_cfg_deadlock() {
  local file="$1"
  [ -r "$file" ] || return 0

  local line stripped ch two i n depth=0 all=""
  while IFS= read -r line || [ -n "$line" ]; do
    stripped=""
    n=${#line}
    i=0
    while [ "$i" -lt "$n" ]; do
      two=${line:i:2}
      ch=${line:i:1}
      if [ "$depth" -gt 0 ]; then
        case "$two" in
          '*)') depth=$((depth - 1)); i=$((i + 2)); continue ;;
          '(*') depth=$((depth + 1)); i=$((i + 2)); continue ;;
        esac
        i=$((i + 1))
        continue
      fi
      case "$two" in
        '(*') depth=$((depth + 1)); i=$((i + 2)); continue ;;
        '\*') break ;;
      esac
      stripped="$stripped$ch"
      i=$((i + 1))
    done
    all="$all$stripped
"
  done <"$file"

  # -d '' reads the whole accumulated text in one go, and -a splits it on IFS,
  # which includes the newline. It returns 1 because there is no NUL to stop
  # at; the array is populated all the same, and nothing here reads the status.
  local -a toks=()
  read -r -d '' -a toks <<<"$all"

  local j last=""
  for ((j = 0; j < ${#toks[@]}; j++)); do
    if [ "${toks[$j]}" = "CHECK_DEADLOCK" ]; then
      last="${toks[$((j + 1))]:-}"
    fi
  done
  case "${last^^}" in
    TRUE)  CFG_DEADLOCK="TRUE" ;;
    FALSE) CFG_DEADLOCK="FALSE" ;;
  esac
}

scan_cfg_deadlock "$CONFIG"

# The AND lives in TLC; the refusal lives here. See THE DEADLOCK CONFLICT in
# the header for the measured six-cell table, for why AGREEMENT is let
# through, and for why --deadlock-override exists.
DEADLOCK_CONFLICT=""
if [ "$DEADLOCK_OVERRIDE" = "0" ]; then
  if [ "$CFG_DEADLOCK" = "TRUE" ] && [ "$CHECK_DEADLOCK" = "0" ]; then
    DEADLOCK_CONFLICT="cfg"
  elif [ "$CFG_DEADLOCK" = "FALSE" ] && [ "$CHECK_DEADLOCK" = "1" ]; then
    DEADLOCK_CONFLICT="flag"
  fi
fi

# THE REFUSAL PRECEDES THE RUN, and that ordering is the point rather than
# tidiness: a conflict noticed afterwards would have a TLC status to report,
# and reporting it is exactly the lie this arm removes.
if [ -n "$DEADLOCK_CONFLICT" ]; then
  if [ "$QUIET" = "0" ]; then
    echo "$INDETERMINATE_TOKEN"
  fi
  {
    printf 'verdict.sh: deadlock checking was asked for and would not have happened.\n'
    printf '\n'
    printf '  %s says CHECK_DEADLOCK %s\n' "$CONFIG" "$CFG_DEADLOCK"
    if [ "$DEADLOCK_CONFLICT" = "cfg" ]; then
      printf '  this run passes TLC -deadlock, which means "do NOT check"\n'
      printf '\n'
      printf 'TLC ANDs the two sides, so the keyword in your .cfg would have been\n'
      printf 'discarded without a word and the run would have come back clean.\n'
      printf 'The deadlock check did not run, and no other check did either.\n'
      printf '\n'
      printf 'Pass --check-deadlock to honour the keyword, --deadlock-override to\n'
      printf 'discard it on purpose, or take the keyword out of the .cfg.\n'
    else
      printf '  this run was given --check-deadlock, which means "DO check"\n'
      printf '\n'
      printf 'TLC ANDs the two sides, so the .cfg would have discarded your flag\n'
      printf 'without a word and the run would have come back clean.\n'
      printf 'The deadlock check did not run, and no other check did either.\n'
      printf '\n'
      printf 'Drop --check-deadlock, or set the .cfg keyword to TRUE.\n'
    fi
  } >&2
  exit "$EXIT_INDETERMINATE"
fi

# Scratch holds the metadir (TLC's states/ tree) and, unless the caller asked
# to keep it, the trace and the log. Keeping all three out of the spec's own
# directory is what lets fixtures stay pristine across runs.
CLEAN_SCRATCH=0
if [ -z "$SCRATCH" ]; then
  SCRATCH=$(mktemp -d -t tla_verdict.XXXXXX)
  CLEAN_SCRATCH=1
else
  mkdir -p "$SCRATCH"
fi
# Reached only through the EXIT trap below. shellcheck does not follow traps,
# so it reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() {
  if [ "$CLEAN_SCRATCH" = "1" ]; then
    rm -rf "$SCRATCH"
  fi
}
trap cleanup EXIT

[ -z "$TRACE" ] && TRACE="$SCRATCH/trace.json"
[ -z "$LOG" ]   && LOG="$SCRATCH/tlc.log"

# The canonical invocation of V2-PLAN.md §5.1.
#
#   -workers 1          pinned; see the WORKER COUNT note in the header
#   -noGenerateSpecTE   suppress the *_TTrace_*.tla spillage on violations
#   -nowarning          keep the log readable for humans
#   -coverage 1         §5.3 dead-action detection needs the per-action counts
#   -dumpTrace json     counterexamples as data, not as console text
#   -metadir            TLC's states/ tree, into scratch, never beside the spec
#
# TLC's -deadlock flag means "do NOT check for deadlock", so the flag is
# present by DEFAULT and --check-deadlock is what removes it. That inversion
# has bitten this project before; the flag name here is the one that reads
# correctly at the call site.
CMD=(tlc
  -workers 1
  -noGenerateSpecTE
  -nowarning
  -coverage 1
  -dumpTrace json "$TRACE"
  -metadir "$SCRATCH/states")

if [ "$CHECK_DEADLOCK" = "0" ]; then
  CMD+=(-deadlock)
fi
if [ -n "$POSTCOND" ]; then
  CMD+=(-postCondition "$POSTCOND")
fi
CMD+=("$MODULE" -config "$CONFIG")
if [ ${#EXTRA[@]} -gt 0 ]; then
  CMD+=("${EXTRA[@]}")
fi

# The one and only place the outcome is produced. TLC's output goes to a file
# and is never inspected; `rc` is the entire signal.
timeout "$TIMEOUT" "${CMD[@]}" >"$LOG" 2>&1
rc=$?

case "$rc" in
  0)   verdict="OK" ;;
  10)  verdict="ASSUMPTION_FAILED" ;;
  11)  verdict="DEADLOCK" ;;
  12)  verdict="SAFETY_VIOLATION" ;;
  13)  verdict="LIVENESS_VIOLATION" ;;
  # The evaluation-failure rows. Kept separate from 12/13 because "the check
  # came out false" and "the check never ran" are different facts; see the
  # header. 14 is a timing fact, not a construct fact.
  14)  verdict="ASSERT_VIOLATION" ;;
  75)  verdict="SPEC_EVAL_FAILURE" ;;
  76)  verdict="SAFETY_EVAL_FAILURE" ;;
  77)  verdict="LIVENESS_EVAL_FAILURE" ;;
  124) verdict="TIMEOUT" ;;
  150) verdict="PARSE_ERROR" ;;
  151) verdict="CONFIG_ERROR" ;;
  255) verdict="TLC_EXCEPTION" ;;
  # An unmapped code is reported as itself rather than bucketed into the
  # nearest familiar row. A new TLC exit code should surface as a loud unknown,
  # not as a plausible-looking wrong answer.
  *)   verdict="UNKNOWN_$rc" ;;
esac

if [ "$QUIET" = "0" ]; then
  echo "$verdict"
fi

exit "$rc"
