#!/usr/bin/env bash
# recall-gate.sh: the five checks over the recall rep corpus (bead
# tla-1sh7.4, epic tla-1sh7).
#
# WHY THIS EXISTS. 120 reps and 30 miss rows landed on 2026-10-16 and nothing
# checked either table. recall/recall.sh answers one question per submission,
# "is this answer right", and has no opinion about whether a rep is a good
# rep. The shape is harness/completion-gate.sh's and the reasoning is its:
# a corpus whose only reader is a person is a corpus checked by a person.
#
# WHAT A RECALL REP IS. A need stated in English and the notation that
# answers it, graded on one exit code. recall/REPS.tsv carries one tab-
# delimited REP row per rep: an id, a construct id that is a drill/INVENTORY.md
# row, an environment name resolving to <root>/env/<name>.tla, the English
# prompt, the canonical answer, and an optional field 7 holding an ERE the raw
# answer must match. recall/MISSES.tsv carries one MISS row per recorded wrong
# answer: a rep id, the wrong answer verbatim, and what that answer says.
#
# USAGE
#   harness/recall-gate.sh [OPTIONS] <recall-root>
#
# OPTIONS
#   --inventory FILE  the construct inventory check 3 resolves against
#                     (default: <repo>/drill/INVENTORY.md)
#   --no-tlc          skip checks 1 and 2's TLC runs. Checks 3, 4 and 5 still
#                     run. This mode can NEVER exit 0. See EXIT CODES.
#   --static-only     run checks 3, 4 and 5, and no TLC at all. A clean run
#                     exits 0. See THE TWO TIERS below for why this is not
#                     --no-tlc.
#   -q, --quiet       suppress the per-check OK lines, findings still print
#   -h, --help        this text
#
# THERE IS NO --timeout, AND THAT IS NOT AN OMISSION. Checks 1 and 2 go
# through recall/recall.sh rather than through harness/verdict.sh directly,
# and the runner carries a fixed 60-second budget with no flag in front of it
# (recall/recall.sh, TIMEOUT). A flag here would have nothing to pass it to,
# so it would be a knob that reports success while changing nothing. If the
# runner ever grows one, this gate can forward it.
#
# ===========================================================================
# THE TWO TIERS. Two questions, and the second is not a volume knob on the
# first. The shape is harness/completion-gate.sh's and the reasoning is its.
#
#   --static-only   is the corpus STRUCTURALLY sound?       clean run -> 0
#   (unflagged)     does every row still grade as it says?  clean run -> 0
#   --no-tlc        I asked you to measure and you did not.    always 99
#
# `--no-tlc` means the gate was asked whether every row still grades and did
# not find out, so it carries that forward as CHECK_DID_NOT_RUN and can never
# report success. `--static-only` means it was asked for the static checks
# ONLY, and a clean run answers that question completely, so it exits 0 and
# STATES the count it did not measure, because a mode that exits 0 without
# saying what it left out is the defect this distinction exists to avoid.
#
# Passing both is a usage error. Two different questions, two different exit
# codes, and the gate will not guess which one was meant.
#
# OUTPUT. Two machine-readable line shapes, then a human block.
#   FINDING   <code> <subject> <detail>     a defect. Exits 1.
#   UNCHECKED <check> <subject> <detail>    a check that could not run. 99.
#
# THERE IS NO WAIVER LINE HERE, unlike harness/drill-gate.sh and
# harness/completion-gate.sh, and the reason is that there is nowhere to put
# one. Both of those gates read a per-item META.md, which is a file with room
# in it for an argument. A rep is a row in a shared TSV with six fields and no
# room for a seventh that is prose. So check 5's token set has to be one no
# legitimate prompt trips, rather than one with an escape hatch, and the
# measurement under CHECK 5 is what that claim rests on. A row that genuinely
# needs an exemption is a reason to reopen the token set, not to add a column.
#
# EXIT CODES, the same three this project uses everywhere.
#     0  every check THIS RUN ASKED FOR ran and passed
#     1  at least one FINDING. Findings outrank unchecked
#    99  no findings, but at least one check COULD NOT RUN. The project-wide
#        CHECK_DID_NOT_RUN code (harness/verdict.sh, bead tla-hl96)
#     2  usage error
#
# THE CHECKS RUN IN DEPENDENCY ORDER, NOT IN THE ORDER THEY ARE NUMBERED.
# The numbers are the bead's and they are kept, because the bead, this header
# and the suite all have to name the same five things. The ORDER is 3, 4, 5,
# then 1 and 2, for the reason harness/reading-gate.sh checks its .cfg
# obligation before its rc reproduces: a missing environment file makes every
# row of check 1 come back rc 3, and 120 identical "could not run" lines say
# nothing that check 4's one line did not already say better.
#
# ===========================================================================
# CHECK 1. EVERY CANONICAL ANSWER SCORES rc 0 THROUGH THE RUNNER.
#
# WHAT THIS CHECK CANNOT DO, STATED FIRST SO NOBODY READS PAST IT.
#
# It submits each canonical answer AGAINST ITSELF. The grading scaffold is
# `ASSUME Answer = Canonical` with both sides filled from the same field 6, so
# a row that scores 0 has proved its canonical PARSES and EVALUATES against its
# environment, and NOTHING AT ALL about whether it computes what field 5
# describes. An expression can be flawless TLA+ and answer a different
# question, and this check passes it.
#
# THE CORRECTNESS PROPERTY IS OUT OF SCOPE HERE, DELIBERATELY, AND IT WAS
# VERIFIED ONCE BY HAND. Gating it needs a predicted-value column in
# recall/REPS.tsv written INDEPENDENTLY of field 6, which the gate would then
# compare against. That column does not exist. The bead that authored the
# table ran the pass instead: the tla-1sh7.2 worker evaluated every rep against
# a value it had written down before looking at the canonical, and recorded
# agreed=120, disagreed=0, at commit 552f09e. So the property is true of the
# corpus as it stood that day and nothing re-establishes it after an edit.
#
# A READER WHO ASSUMES THIS GATE COVERS CORRECTNESS IS WRONG, and that
# assumption is exactly what the bead's own first RED line invited. It read
# "every row scores rc 0 when its canonical answer is submitted through
# recall/recall.sh", which can only ever prove the canonical parses. The line
# is not copied here. What is written instead is this paragraph.
#
# WHAT CHECK 1 IS WORTH, which is not nothing. Six defect classes it catches
# and a reading pass would not:
#
#   - a canonical that does not parse                            rc 150
#   - a canonical naming something the environment never defines rc 150
#   - an environment that defines one of the three reserved names
#     (Answer, Canonical, Shown), which makes EVERY rep over that
#     environment fail to parse with a SANY multiple-declaration  rc 150
#   - a canonical its own field 7 refuses, so every correct answer
#     to that rep is turned away at the construct gate            rc 4
#   - a canonical whose value is not the value of itself, which is
#     what a non-deterministic or TLC-unevaluable expression does  rc 10
#   - a regression in recall.sh, verdict.sh or the scaffold that
#     stops the channel grading anything                     rc 2, 3, other
#
# HOW IT RUNS. One `recall.sh -q` per row. Quiet mode exits straight after the
# status line, so a wrong answer costs ONE TLC run rather than three: the two
# value probes live below the quiet exit (recall/recall.sh, the QUIET branch).
# At 120 rows and about 0.32 s a grading run that is the whole of this check's
# cost.
#
# ===========================================================================
# CHECK 2. EVERY MISS ROW'S WRONG ANSWER SCORES rc 10 AGAINST ITS OWN REP.
#
# Checks 1 and 2 together are the mutation bar applied to this channel. A
# canonical that scores anything but 0 is wrong, and a miss that scores 0 is
# not a miss. It is a correct form of the answer with an explanation attached
# saying it is a mistake, which is the worst thing this table can hold.
#
# rc 10 HOLDS THREE DIFFERENT THINGS AND THE NUMBER ALONE CANNOT TELL THEM
# APART. This is worth knowing before anybody reads a green run as "all 30
# rows are ordinary wrong answers":
#
#   1  an ordinary wrong answer. ASSUME Answer = Canonical came back FALSE
#      because the two values differ. A type mismatch is in this band too:
#      `7` against a set of functions is simply false, not an error.
#   2  a CASE with no true arm. TLC reports "Attempted to evaluate a CASE
#      with no conditions true", which is an EVALUATION FAILURE inside the
#      ASSUME and surfaces as rc 10 ASSUMPTION_FAILED, not as a code of its
#      own.
#   3  a non-function applied as a function. An EXCEPT whose `@` is indexed
#      gives "A non-function (an integer) was applied as a function", again
#      rc 10.
#
# Both measurements are the tla-1sh7.3 worker's, taken on two live rows on
# 2026-10-16. So the band holds misconceptions that produce a WRONG VALUE and
# misconceptions that produce NO VALUE AT ALL. For this rung that is the right
# place to draw the line, because both are a wrong answer from the learner's
# side and both get the same two-value block. It is stated here rather than
# left to be rediscovered, because the gate keys on the number.
#
# WHAT THE OTHER CODES MEAN WHEN A MISS ROW SCORES ONE:
#   0    the row's field 3 is a CORRECT form. The explanation under it is a
#        statement that a right answer is wrong.                MISS-NOT-WRONG
#   150  it never parsed, so nothing was graded and field 4 is a sentence
#        about text rather than about an idea.                  MISS-NOT-GRADED
#   3    the rep id in field 2 is not a row of the rep table.   MISS-NO-REP
#   4    the construct gate refused it, which means the value was RIGHT and
#        field 7 turned it away. Reported as MISS-NOT-WRONG, because the miss
#        table is about wrong values and this one is not wrong.
#
# ===========================================================================
# CHECK 3. EVERY CONSTRUCT ID RESOLVES TO A drill/INVENTORY.md ROW.
#
# Field 3 is the join between this corpus and the construct inventory, and it
# is also the key drill/SHEET.md is read on, so an id that resolves to no row
# costs the learner the sheet entry at the bottom of every wrong answer to
# that rep. The inventory is the authority on which ids exist: 105 ROW lines,
# K001 to K105.
#
# THE SHEET IS NOT CHECKED HERE and that is not a hole. harness/test-recall-
# runner.sh part 13 already asserts that every construct in the rep table has
# a drill/SHEET.md entry, over the real shipped files. Two gates asserting one
# property is how they drift apart.
#
# ===========================================================================
# CHECK 4. EVERY ROW CAN BE SUBMITTED AT ALL.
#
# The bead names the first of these three. The other two are the same
# question asked of field 7, and they are here because they are static,
# because they cost nothing, and because --static-only would otherwise answer
# "is the corpus structurally sound" while leaving a row that no answer can
# ever pass.
#
#   ENV-MISSING       the environment in field 4 resolves to no file under
#                     <root>/env/, so every submission to the rep is rc 3
#   ROW-BAD-SHAPE     fewer than six tab-separated fields, or an empty field
#                     where the runner requires one
#   ROW-DUPLICATE-ID  two REP rows share an id. The runner's lookup takes the
#                     first and exits, so the second row is unreachable: it
#                     can never be graded, and nothing else would ever say so
#   REQUIRES-UNREADABLE          field 7 is not an ERE grep will read, so
#                                every submission to that rep dies at rc 3
#   REQUIRES-REFUSES-CANONICAL   field 7 does not match the row's own
#                                canonical, so the rep's own answer is turned
#                                away at rc 4 and no correct answer can score 0
#
# THE LAST TWO ARE VACUOUS TODAY AND THAT IS THE POINT. Measured 2026-10-16:
# all 120 live rows carry exactly six fields, so no row has a field 7 at all.
# The checks are here for the row that lands tomorrow, which is the same
# posture harness/test-pipefail.sh takes when it selects files by shebang from
# the tree rather than from a list.
#
# ===========================================================================
# CHECK 5. NO PROMPT CONTAINS THE NOTATION IT IS ASKING FOR.
#
# This is the check that keeps a rep from being a transcription exercise, and
# it is harness/drill-gate.sh's layer B narrowed to one row at a time, the way
# harness/completion-gate.sh's check 3 narrows it. The rep table's own header
# states the rule it enforces: "FIELD 5 IS THE FIELD THAT DECIDES WHETHER A
# REP IS A REP. It states a need and names none of the notation that answers
# it." "The set of all the ways the wagons could be parked" asks for recall.
# "Write a function set" hands the construct over.
#
# PER ROW, NOT PER CORPUS. The token set is intersected with THIS ROW'S
# CANONICAL first, so a prompt is only ever flagged for notation its own
# answer uses. A prompt that happens to contain a token no answer of its own
# needs is not telegraphing anything.
#
# THE TOKEN SET IS WIDER THAN drill-gate.sh's DISTINCTIVE, AND THE WIDENING IS
# THE WHOLE DIFFERENCE BETWEEN THE TWO CORPORA. drill-gate.sh excludes the
# shared vocabulary (`/\ \/ \in \A \E =>`, LET IN IF THEN ELSE, DOMAIN, the
# sequence operators) because a drill prompt is ALLOWED TO SHOW A SPEC and
# ask for the missing piece, so flagging those would fail every item of that
# shape. A recall prompt shows nothing. It is one sentence of English, and any
# TLA+ at all in it is the give-away. So the exclusion list is not inherited:
# its reason does not hold here.
#
# MEASURED BEFORE IT WAS WRITTEN DOWN, over all 120 live rows on 2026-10-16:
# the set below fires on ZERO prompts. That is what the claim "no legitimate
# prompt trips this" rests on, and it is the measurement to re-take rather
# than the sentence to re-read if a row ever fires.
#
# FOUR THINGS IN THE SET ARE NOT WHAT THEY LOOK LIKE, and a reader who skips
# this paragraph will misread the list:
#
#   `[]` and `<>` are inherited from DISTINCTIVE as the temporal operators.
#   In THIS corpus they reach `<<>>`, the empty sequence (R040, R051), and the
#   CASE arm separator (R047, R048). Harmless either way, since no prompt
#   carries them, but they are not doing the job they were added for.
#
#   `\subseteq` contains `\subset`, `|->` contains `->`, and `<=>` contains
#   `=`. The redundancy is deliberate: a per-row intersection means the
#   narrower token simply fires on the same row, and dropping one to look tidy
#   would uncover the rows that use only the other form.
#
# THREE THINGS ARE EXCLUDED ON PURPOSE:
#
#   `'`  the prime. drill-gate.sh excludes it because it is an apostrophe in
#        English prose, and that reason holds here with a number on it: 14 of
#        the 120 prompts carry an apostrophe ("the yard's capacity") and ZERO
#        canonicals carry a prime, which is what a value rung with no actions
#        in it looks like.
#   `-`  the minus sign, which is a hyphen in prose.
#   `..` IS INCLUDED, and the hazard is named here rather than discovered: an
#        ellipsis in a prompt contains it. Zero prompts carry one today. If a
#        row ever fires on `..`, read the prompt before reaching for the set.
#
# WHAT THIS CHECK DOES NOT REACH, and these are holes rather than caveats:
#   - ENGLISH PARAPHRASE. "the set of all functions from wagons to tracks"
#     names no notation and hands over the construct completely. Only a reader
#     catches that. drill-gate.sh calls this the largest deliberate hole in
#     its own check 1 and it is the same hole here.
#   - A CONSTRUCT WITH NO SYMBOL. "Operator definition" has no token to scan
#     for, so K001's three reps are outside this check's reach exactly as they
#     are outside drill-gate.sh's layer A.
#   - THE MISS EXPLANATIONS. Field 4 of a miss row is printed UNDER both
#     values, so the right answer is already on screen before it speaks and
#     there is nothing left to telegraph.
#
# ===========================================================================
# ONE CHECK THAT IS DELIBERATELY NOT HERE, AND THE MEASUREMENT THAT KILLED IT
#
# "No miss explanation names a module or a variable from the drill verify
# tree" is the obvious sixth check, and recall/MISSES.tsv's own header says
# the rows were rewritten to satisfy it. The obvious way to build it is a
# whole-word match against the module basenames under drill/*/*/verify/ plus
# every declared VARIABLE name in them.
#
# THE tla-1sh7.3 WORKER BUILT THAT LIST AND RAN IT. Eight hits, every one an
# ordinary English word that happens to be declared somewhere in the tree:
#
#   a, b     drill/core/08-altimeter-approx/verify/Altimeters.tla
#   at       drill/functions-records/02-charging-bays/verify/BaysVanSide.tla
#   holds    drill/functions-records/05-tool-crib/verify/ToolCribByWorker.tla
#   level    drill/functions-records/03-ballast-tanks/verify/Ballast.tla
#   occupied drill/modules/03-the-bank-that-vouched/verify/PostOffice.tla
#   taken    drill/sequences/07-pneumatic-tube/verify/TubeDerived.tla
#   where    drill/sets/02-two-pools/verify/PoolsWhere.tla
#
# No wording survives a matcher that includes "a", "at" and "where". The names
# that actually matter came back with zero hits already: pos, out, unit, cover,
# board, line. So the check as stated would be 100% false positives and would
# flag nothing real.
#
# WHAT A WORKING VERSION WOULD MATCH is module basenames and multi-character
# identifiers that are not English words, which needs a word list this repo
# does not have, and is its own bead rather than a paragraph of this one. It
# is recorded here so the next author does not rebuild the matcher that was
# already measured and rejected.
#
# ===========================================================================
# WHAT THIS GATE DELIBERATELY DOES NOT DO
#
# NO CORRECTNESS CHECK. See CHECK 1 above, which is the longest section of
# this header for that reason.
#
# NO COVERAGE REPORT. 37 of the inventory's 105 constructs have a rep and 68
# do not, and nothing here has an opinion about which. K008 is deliberately
# absent and recall/REPS.tsv's own footer says why. harness/test-coverage-map.sh
# is the instrument for coverage questions.
#
# NO EXPLANATION QUALITY CHECK. Field 4 is taken at its word, exactly as
# META.md is by harness/drill-gate.sh's check 3.
#
# NO PROSE BUDGET. harness/test-recall-runner.sh already refuses a miss
# explanation or a sheet body that wraps past three lines, over the real
# files. Two gates asserting one property is how they drift apart.
#
# ===========================================================================
# OUTSTANDING: THIS INSTRUMENT IS NOT IN harness/test-indeterminate.sh's
# REGISTRY, AND THAT SUITE IS RED UNTIL IT IS.
#
# Its part 2 census selects every `harness/*.sh` that is not a test suite FROM
# THE TREE, so this file was covered the moment it landed. An instrument that
# can admit a skip has to be driven by a row of that suite, or its rc-0 skip
# admission is a success code carrying an admission nobody checks.
#
# MEASURED 2026-10-16, AND THE DIRECTION MATTERS. With this file moved aside,
# `harness/test-indeterminate.sh` reads 85 assertions passed, rc 0. With it in
# the tree, 84 passed and 1 failed, on one assertion:
#
#   FAIL  UNREGISTERED instrument(s) can admit a skip
#   harness/recall-gate.sh
#
# So the suite was GREEN on main and this file turned it red. That is not the
# state harness/completion-gate.sh's own header records for itself, where the
# suite was already red when that bead landed, and the difference is why this
# section carries the patch rather than only the problem.
#
# WHY IT IS NOT APPLIED HERE. Bead tla-1sh7.4 declares four files and
# `harness/test-indeterminate.sh` is not among them. The four admissions the
# census reaches are all honest and none should be reworded to quiet it, which
# is the rule harness/completion-gate.sh's own OUTSTANDING block states. One
# admission WAS reworded, and for the opposite reason: the MISS-NO-REP finding
# read "the runner could not run this row at all at rc 3", which matched
# SKIP_VOCAB while being a FINDING rather than a skip. It now reads "refused",
# which is both true and not an admission.
#
# THE PATCH, AND EVERY ASSERTION IN IT WAS RUN AGAINST THIS FILE BEFORE IT WAS
# WRITTEN DOWN. Add the instrument beside its six siblings:
#
#   QGATE="harness/recall-gate.sh"
#   REGISTERED=(... "$KGATE" "$QGATE")
#
# and two rows next to the completion gate's, which are the shape this
# instrument copies. Measured: `--no-tlc -q recall` returns 99 and carries
# both strings, `--static-only -q recall` returns 0 and carries both of its
# own, and neither claims OK.
#
#   run_row "$QGATE" "recall-gate.sh: --no-tlc was asked to grade 120 canonicals and did not" \
#     "$INDETERMINATE" -- \
#     bash "$QGATE" --no-tlc -q recall
#   assert_out "the recall gate names the check it did not run" "UNCHECKED every-canonical-scores-0"
#   assert_out "the recall gate reports the reserved token" "VERDICT $TOKEN"
#   assert_not_out "the recall gate does not claim OK over it" "VERDICT OK"
#
#   run_row "$QGATE" "recall-gate.sh: --static-only is a caller instruction, not a failure" \
#     0 -- \
#     bash "$QGATE" --static-only -q recall
#   assert_out "the static-only admission and its waiving flag are on one line" \
#     "were skipped (--static-only)"
#   assert_out "the static-only run still states what it did not measure" \
#     "whose grading was not measured"
#
# Both rows are cheap: neither starts a JVM, so the registration costs that
# suite about a second.
# ===========================================================================

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# TELEGRAPH_TOKENS. Check 5's token set. Read CHECK 5 above before changing
# it. Every line below is measured rather than reasoned.
#
# Rows 1 to 5 are harness/drill-gate.sh:305-311's DISTINCTIVE set VERBATIM, so
# the project has one floor rather than two.
# ---------------------------------------------------------------------------
TELEGRAPH_TOKENS=(
  '~>' '<>' '[]' ']_' 'WF_' 'SF_' 'ENABLED'
  'UNCHANGED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'INSTANCE' 'RECURSIVE'
  '|->' ':>' '@@' 'LAMBDA'
  'Cardinality' 'Permutations' 'SelectSeq' 'TLCGet' 'Assert'
  '\X' '\o' '\cup' '\cap' '\subseteq' '\notin'

  # The widening. Every one of these is shared vocabulary a DRILL prompt may
  # legitimately show and a RECALL prompt may not, because a recall prompt
  # shows no spec. See CHECK 5.
  # $'/\\' rather than '/\': both are the two bytes /\ , proven against a
  # running shell, but the single-quoted form raises SC1003 because \' reads
  # as an attempted quote escape. The spelling and the reason are
  # harness/drill-gate.sh:334-337's, so the project carries one idiom here
  # rather than two.
  $'/\\' '\/' '\in' '\A' '\E' '=>' '<=>' '~'
  '\union' '\intersect' '\subset' '\div' '\leq' '\geq'
  'LET' 'IN' 'IF' 'THEN' 'ELSE' 'CASE' 'OTHER' 'DOMAIN' 'TRUE' 'FALSE'
  'Len' 'Append' 'Head' 'Tail' 'SubSeq' 'Seq' 'Nat' 'Int' 'BOOLEAN'
  '->' '..' '#' '/=' '=' '{' '}' '<<' '>>' '%' '^'
)

INVENTORY="${REPO_ROOT}/drill/INVENTORY.md"
NO_TLC=0
STATIC_ONLY=0
QUIET=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory)
      if [ "$#" -lt 2 ]; then
        echo "recall-gate.sh: --inventory wants a file" >&2
        exit 2
      fi
      INVENTORY="$2"
      shift
      ;;
    --no-tlc)      NO_TLC=1 ;;
    --static-only) STATIC_ONLY=1 ;;
    -q|--quiet)    QUIET=1 ;;
    -h|--help)
      awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "recall-gate.sh: unknown option '$1' (try --help)" >&2
      exit 2
      ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "recall-gate.sh: more than one recall root given ('$ROOT', '$1')" >&2
        exit 2
      fi
      ROOT="$1"
      ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  echo "recall-gate.sh: no recall root given (try --help)" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "recall-gate.sh: '$ROOT' is not a directory" >&2
  exit 2
fi

# Two different questions with two different exit codes. See THE TWO TIERS.
if [ "$NO_TLC" = "1" ] && [ "$STATIC_ONLY" = "1" ]; then
  echo "recall-gate.sh: --no-tlc and --static-only are different questions with different exit codes. Pass one" >&2
  exit 2
fi

RUN_TLC=1
if [ "$NO_TLC" = "1" ] || [ "$STATIC_ONLY" = "1" ]; then
  RUN_TLC=0
fi

RUNNER="${ROOT}/recall.sh"
REPS="${ROOT}/REPS.tsv"
MISSES="${ROOT}/MISSES.tsv"
ENV_DIR="${ROOT}/env"

if [ ! -x "$RUNNER" ] && [ "$RUN_TLC" = "1" ]; then
  echo "recall-gate.sh: ${RUNNER} is missing or not executable." >&2
  echo "  Checks 1 and 2 could not run. Pass --no-tlc to say so deliberately." >&2
  exit 2
fi

finding_n=0
unchecked_n=0
rep_n=0
miss_n=0

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-28s %-10s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-28s %-10s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

# ---------------------------------------------------------------------------
# token_shown <token> <text>: does the text use this operator?
#
# A token made only of word characters matches on a WORD BOUNDARY. Anything
# with a symbol in it matches as a substring. Lifted unchanged from
# harness/completion-gate.sh, which lifted the boundary from
# harness/drill-gate.sh's rc reader, where a module called Commit picked up the
# prose word "Committed".
#
# THE BOUNDARY IDIOM `(^|[^class])TOKEN` IS THE ONE .claude/rules/dispatched-
# agents.md records as LYING under the Bash tool's ugrep wrapper, which
# returned 0 where GNU returned 6. It is correct here because this file carries
# a bash shebang and gets GNU grep, which is the same ground every other gate
# in harness/ stands on. Do not re-run one of these lines interactively and
# believe the answer.
# ---------------------------------------------------------------------------
token_shown() {
  case "$1" in
    *[!A-Za-z0-9_]*) [[ "$2" == *"$1"* ]] ;;
    *) grep -qE "(^|[^A-Za-z0-9_])$1([^A-Za-z0-9_]|$)" <<<"$2" ;;
  esac
}

# ---------------------------------------------------------------------------
# grade <rep-id> <answer>: the runner's raw exit code, into GRADE_RC.
#
# `-q` so the runner exits on the status line. That is not only quieter, it is
# THREE TIMES CHEAPER on a wrong answer: the two value probes sit below the
# quiet exit in recall/recall.sh, so every row of checks 1 and 2 costs exactly
# one TLC run whatever it scores.
#
# The three table paths are passed explicitly so the gate drives the root it
# was handed rather than the runner's own shipped defaults. --misses changes
# nothing under -q, since nothing reads it before the exit. It is passed
# anyway because a gate that drives one file from the root and another from
# the repo is a gate whose green run means two different things.
#
# --sheet is NOT passed. drill/SHEET.md is outside the recall root by design,
# the runner reads it only on the non-quiet path, and check 3 resolves
# construct ids against the inventory instead.
# ---------------------------------------------------------------------------
GRADE_RC=0
grade() {
  GRADE_RC=0
  "$RUNNER" -q --reps "$REPS" --env-dir "$ENV_DIR" --misses "$MISSES" \
    "$1" "$2" >/dev/null 2>&1 || GRADE_RC=$?
}

echo "recall-gate.sh: ${ROOT}"

# ---------------------------------------------------------------------------
# The shape. Everything below reads these, so a missing one is reported once
# rather than 120 times.
# ---------------------------------------------------------------------------
if [ ! -f "$REPS" ]; then
  finding "SHAPE-NO-REPS" "$ROOT" "no REPS.tsv. It is the corpus, and every check below reads it"
  echo
  echo "recall-gate.sh: 0 rep(s), 0 miss row(s), ${finding_n} finding(s), 0 unchecked"
  echo "VERDICT FINDINGS"
  exit 1
fi
if [ ! -d "$ENV_DIR" ]; then
  finding "SHAPE-NO-ENV-DIR" "$ROOT" "no env/. Every rep names an environment that resolves under it"
fi

# ---------------------------------------------------------------------------
# Read the rep rows once.
#
# awk -F'\t' and cut, never `IFS=$'\t' read`. Tab is an IFS whitespace
# character, so read folds a run of tabs into one delimiter and drops a
# trailing empty field, which shifts every field after it without saying so.
# recall/REPS.tsv's own header says the same thing.
# ---------------------------------------------------------------------------
IDS=()
CONSTRUCTS=()
ENVS=()
PROMPTS=()
CANONS=()
REQUIRES=()

while IFS= read -r row; do
  rep_n=$((rep_n + 1))
  IDS+=("$(cut -f2 <<<"$row")")
  CONSTRUCTS+=("$(cut -f3 <<<"$row")")
  ENVS+=("$(cut -f4 <<<"$row")")
  PROMPTS+=("$(cut -f5 <<<"$row")")
  CANONS+=("$(cut -f6 <<<"$row")")
  # A six-field row has no field 7 and cut returns the empty string, which is
  # the same thing an empty field 7 says: no gate.
  REQUIRES+=("$(cut -f7 <<<"$row")")
done < <(awk -F'\t' '$1 == "REP"' "$REPS")

if [ "$rep_n" -eq 0 ]; then
  unchecked "reps" "$ROOT" "REPS.tsv holds no REP row. A row is tab-delimited with the literal first field REP"
fi

# ===========================================================================
# CHECK 3. every construct id resolves to an inventory row.
# ===========================================================================
if [ ! -f "$INVENTORY" ]; then
  unchecked "check-3" "$ROOT" \
    "no inventory at ${INVENTORY}, so no construct id was resolved. Pass --inventory"
else
  INV_IDS="$(awk -F'\t' '$1 == "ROW" { print $2 }' "$INVENTORY")"
  c3_ok=1
  for i in "${!IDS[@]}"; do
    k="${CONSTRUCTS[$i]}"
    if [ -z "$k" ]; then
      finding "CONSTRUCT-EMPTY" "${IDS[$i]}" \
        "field 3 is empty, so the rep joins to no inventory row and reaches no sheet entry"
      c3_ok=0
      continue
    fi
    if ! grep -qxF -- "$k" <<<"$INV_IDS"; then
      finding "CONSTRUCT-NOT-IN-INVENTORY" "${IDS[$i]}" \
        "field 3 is '${k}', and ${INVENTORY} carries no ROW with that id"
      c3_ok=0
    fi
  done
  [ "$c3_ok" = "1" ] && [ "$rep_n" -gt 0 ] && \
    say "  OK    check 3  ${rep_n} construct id(s) resolve to a row of ${INVENTORY}"
fi

# ===========================================================================
# CHECK 4. every row can be submitted at all.
# ===========================================================================
c4_ok=1

# Duplicate ids. The runner's lookup is `$1 == "REP" && $2 == id { print; exit }`,
# so a second row with the same id is unreachable: it can never be graded and
# nothing else in this corpus would ever notice it is there.
while IFS= read -r dup; do
  [ -n "$dup" ] || continue
  finding "ROW-DUPLICATE-ID" "$dup" \
    "two or more REP rows carry this id. The runner takes the first and exits, so the rest can never be graded"
  c4_ok=0
done < <(awk -F'\t' '$1 == "REP" { seen[$2]++ } END { for (k in seen) if (seen[k] > 1) print k }' "$REPS" | LC_ALL=C sort)

# Field count, before anything reads a field that may not be there.
while IFS= read -r bad; do
  [ -n "$bad" ] || continue
  finding "ROW-BAD-SHAPE" "$bad" \
    "fewer than six tab-separated fields. A REP row is marker, id, construct, environment, prompt, canonical"
  c4_ok=0
done < <(awk -F'\t' '$1 == "REP" && NF < 6 { print ($2 == "" ? "(no id)" : $2) }' "$REPS")

for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"

  if [ -z "$id" ]; then
    finding "ROW-BAD-SHAPE" "(no id)" "a REP row carries no id in field 2, so nothing can name it"
    c4_ok=0
    continue
  fi

  if [ -z "${CANONS[$i]}" ]; then
    finding "ROW-BAD-SHAPE" "$id" "field 6 is empty, so the rep carries no canonical answer and nothing can be graded"
    c4_ok=0
  fi

  if [ -z "${ENVS[$i]}" ]; then
    finding "ENV-MISSING" "$id" "field 4 is empty, so the rep names no environment"
    c4_ok=0
  elif [ ! -r "${ENV_DIR}/${ENVS[$i]}.tla" ]; then
    finding "ENV-MISSING" "$id" \
      "field 4 names '${ENVS[$i]}' and ${ENV_DIR}/${ENVS[$i]}.tla is not readable, so every submission is rc 3"
    c4_ok=0
  fi

  req="${REQUIRES[$i]}"
  [ -n "$req" ] || continue

  # Is it an ERE grep will read? The runner treats a grep rc above 1 as "could
  # not run" and dies at exit 3, so an unreadable pattern takes the rep out of
  # service entirely. A here-string, never a pipe: under pipefail an
  # early-exiting consumer makes the producer take SIGPIPE and the pipeline
  # report 141, which inside an `if` is merely falsy.
  probe_rc=0
  grep -qE -- "$req" <<<"recall-gate-ere-probe" || probe_rc=$?
  if [ "$probe_rc" -gt 1 ]; then
    finding "REQUIRES-UNREADABLE" "$id" \
      "field 7 is '${req}', which grep -E will not read as an expression, so every submission to this rep dies at rc 3"
    c4_ok=0
    continue
  fi

  # Does the row's own canonical satisfy it? If not, the construct gate turns
  # the rep's own answer away at rc 4 and NO correct answer can ever score 0.
  if ! grep -qE -- "$req" <<<"${CANONS[$i]}"; then
    finding "REQUIRES-REFUSES-CANONICAL" "$id" \
      "field 7 is '${req}' and the row's own canonical does not match it, so the construct gate refuses the rep's own answer at rc 4"
    c4_ok=0
  fi
done

[ "$c4_ok" = "1" ] && [ "$rep_n" -gt 0 ] && \
  say "  OK    check 4  ${rep_n} row(s) are submittable: an id of their own, an environment on disk, and a field 7 that takes their canonical"

# ===========================================================================
# CHECK 5. no prompt contains the notation it is asking for.
# ===========================================================================
c5_ok=1
for i in "${!IDS[@]}"; do
  prompt="${PROMPTS[$i]}"
  canon="${CANONS[$i]}"
  if [ -z "$prompt" ]; then
    finding "PROMPT-EMPTY" "${IDS[$i]}" \
      "field 5 is empty, so the rep states no need and there is nothing to recall"
    c5_ok=0
    continue
  fi
  for tok in "${TELEGRAPH_TOKENS[@]}"; do
    token_shown "$tok" "$canon" || continue
    if token_shown "$tok" "$prompt"; then
      finding "TELEGRAPH-IN-PROMPT" "${IDS[$i]}" \
        "the canonical uses '${tok}' and the prompt shows it, so the rep is a transcription rather than a recall"
      c5_ok=0
    fi
  done
done

[ "$c5_ok" = "1" ] && [ "$rep_n" -gt 0 ] && \
  say "  OK    check 5  no prompt of ${rep_n} shows a token its own canonical uses"

# ===========================================================================
# CHECKS 1 and 2. The TLC half.
# ===========================================================================
if [ "$STATIC_ONLY" = "1" ]; then
  :
elif [ "$NO_TLC" = "1" ]; then
  unchecked "every-canonical-scores-0" "$ROOT" \
    "${rep_n} canonical answer(s) to grade: --no-tlc was asked for, so the check was not run"
  unchecked "every-miss-scores-10" "$ROOT" \
    "the miss table was not read either: --no-tlc was asked for, so the check was not run"
else
  # --- check 1 ----------------------------------------------------------
  c1_ok=1
  for i in "${!IDS[@]}"; do
    [ -n "${IDS[$i]}" ] || continue
    [ -n "${CANONS[$i]}" ] || continue
    grade "${IDS[$i]}" "${CANONS[$i]}"
    [ "$GRADE_RC" = "0" ] && continue
    case "$GRADE_RC" in
      4)   detail="the construct gate refused the rep's own canonical, so no correct answer can score 0" ;;
      10)  detail="the canonical is not equal to itself, which is what a TLC-unevaluable expression does" ;;
      150) detail="the canonical did not parse, so nothing was graded. A typo, or a name the environment never defines" ;;
      3)   detail="the run could not happen at all: no environment file, no verdict channel, or no scratch directory" ;;
      *)   detail="the grading run came back ${GRADE_RC}, which is a report about the run rather than about the answer" ;;
    esac
    finding "CANONICAL-NOT-CORRECT" "${IDS[$i]}" "rc ${GRADE_RC}: ${detail}"
    c1_ok=0
  done
  [ "$c1_ok" = "1" ] && [ "$rep_n" -gt 0 ] && \
    say "  OK    check 1  ${rep_n} canonical answer(s) scored rc 0 (parse and evaluation only, see CHECK 1 in this file's header)"

  # --- check 2 ----------------------------------------------------------
  if [ ! -f "$MISSES" ]; then
    # Not a finding: the runner's own contract is that a missing miss table is
    # silence rather than a refusal, and a tree delivered without one still
    # grades every rep in it. It IS an unchecked, because a corpus that lost
    # its miss table has lost 30 explanations and nothing else would say so.
    unchecked "check-2" "$ROOT" \
      "no MISSES.tsv under the root, so no wrong answer was graded"
  else
    c2_ok=1
    while IFS= read -r row; do
      miss_n=$((miss_n + 1))
      m_rep="$(cut -f2 <<<"$row")"
      m_wrong="$(cut -f3 <<<"$row")"
      m_why="$(cut -f4 <<<"$row")"

      if [ -z "$m_rep" ] || [ -z "$m_wrong" ]; then
        finding "MISS-BAD-SHAPE" "${m_rep:-(no id)}" \
          "a MISS row is marker, rep id, wrong answer, explanation, and one of the first three is empty"
        c2_ok=0
        continue
      fi
      if [ -z "$m_why" ]; then
        finding "MISS-NO-EXPLANATION" "$m_rep" \
          "field 4 is empty, so the row costs a grading run and says nothing under the two values"
        c2_ok=0
      fi

      grade "$m_rep" "$m_wrong"
      [ "$GRADE_RC" = "10" ] && continue
      case "$GRADE_RC" in
        0)
          finding "MISS-NOT-WRONG" "$m_rep" \
            "'${m_wrong}' scores rc 0, so it is a CORRECT form of the answer and field 4 calls a right answer a mistake"
          ;;
        4)
          finding "MISS-NOT-WRONG" "$m_rep" \
            "'${m_wrong}' scores rc 4, so its VALUE was right and only the construct gate turned it away. The miss table is about wrong values"
          ;;
        150)
          finding "MISS-NOT-GRADED" "$m_rep" \
            "'${m_wrong}' scores rc 150, so it never parsed and field 4 is a sentence about text rather than about an idea"
          ;;
        3)
          finding "MISS-NO-REP" "$m_rep" \
            "the runner refused this row at rc 3. Field 2 names no REP row, or its environment is gone"
          ;;
        *)
          finding "MISS-NOT-GRADED" "$m_rep" \
            "'${m_wrong}' scores rc ${GRADE_RC}, which is a report about the run rather than about the answer"
          ;;
      esac
      c2_ok=0
    done < <(awk -F'\t' '$1 == "MISS"' "$MISSES")

    if [ "$miss_n" -eq 0 ]; then
      unchecked "check-2" "$MISSES" \
        "the file is there and holds no MISS row. A row is tab-delimited with the literal first field MISS"
    elif [ "$c2_ok" = "1" ]; then
      say "  OK    check 2  ${miss_n} wrong answer(s) scored rc 10 against their own rep"
    fi
  fi
fi

# ===========================================================================
# THE MODE BLOCK. What a tier that exits 0 did NOT measure.
#
# A MODE THAT EXITS 0 WITHOUT SAYING WHAT IT LEFT OUT IS THE DEFECT. The
# counts do not exist until the rows have been read, so the block sits here
# rather than in the banner, and it prints through `echo` so `-q` cannot
# suppress it: an honesty statement is not a per-check OK line.
#
# THE ADMISSION IS SPELLED IN harness/test-indeterminate.sh's VOCABULARY, ON
# PURPOSE, AND THE WAIVING FLAG IS NAMED IN PARENTHESES ON THE SAME LINE.
# That suite's parenthetical rule is what makes a voluntary skip tellable from
# an involuntary one: an admission naming the caller flag behind it is
# legitimate at rc 0, and one that names no flag must carry 99. Phrasing this
# to dodge the skip vocabulary would hide the admission from the only gate
# that looks for it. The word is `skipped` and the flag is in brackets after
# it, which is the form harness/completion-gate.sh landed on after a first
# version dodged the vocabulary by grammar.
# ===========================================================================
if [ "$STATIC_ONLY" = "1" ]; then
  echo
  echo "recall-gate.sh: --static-only. ${rep_n} rep(s) whose grading was not measured, no TLC ran."
  echo "Checks 1 and 2 were skipped (--static-only), which is the scope the caller asked for."
  echo "NOT COVERED HERE: whether every canonical still scores rc 0 and every miss still scores rc 10."
  echo "The slow row of harness/test-recall-gate.sh runs those."
  echo "This run answers whether the corpus is STRUCTURALLY sound and nothing more."
fi

# ===========================================================================
echo
echo "recall-gate.sh: ${rep_n} rep(s), ${miss_n} miss row(s), ${finding_n} finding(s), ${unchecked_n} unchecked"

if [ "$finding_n" -gt 0 ]; then
  echo "VERDICT FINDINGS"
  exit 1
fi
if [ "$unchecked_n" -gt 0 ]; then
  echo "VERDICT CHECK_DID_NOT_RUN"
  exit 99
fi
echo "VERDICT OK"
exit 0
