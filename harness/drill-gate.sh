#!/usr/bin/env bash
# drill-gate.sh — the three checks over a blank-page drill corpus.
#
# THE REASON THIS EXISTS. Six authors produce drill items in parallel and
# central cannot read forty to sixty of them by hand. So what this script
# checks is what the corpus is GUARANTEED to be, and everything it does not
# check is unguaranteed. The header below says which is which, per check,
# because a reader who assumes the wrong half is the failure this file is
# most likely to cause.
#
# USAGE
#   harness/drill-gate.sh [OPTIONS] <drill-root>
#
# OPTIONS
#   --inventory FILE   construct inventory (default: <drill-root>/INVENTORY.md)
#   --no-tlc           skip every TLC run in check 2. The static checks still
#                      run. This mode can NEVER exit 0 — see EXIT CODES.
#   --static-only      run check 1, check 3 and the STRUCTURAL half of check 2,
#                      and no TLC at all. A clean run exits 0 — see THE THREE
#                      TIERS below for why this is not --no-tlc.
#   -P N, --jobs N     run check 2's TLC queue N ways in parallel (default 1)
#   --changed-only     run only the queue jobs whose cache key is absent from
#                      the state file, and record a key for every job that ran
#                      and matched. With no resolvable TLC build it runs every
#                      job, records none, and says so without escalating
#   --state FILE       the --changed-only state file
#                      (default: <repo-root>/.drill-gate-state)
#   --timeout SECS     per-module TLC budget, passed to verdict.sh (default 60)
#   -q, --quiet        suppress the per-item PASS lines; findings still print
#   -h, --help         this text
#
# ===========================================================================
# THE THREE TIERS — three questions, three exit codes, and ONE of them is not
# a volume knob on the others.
#
#   --static-only   is the corpus STRUCTURALLY sound?          clean run -> 0
#   --changed-only  did anything I just changed stop
#                   reproducing?                               clean run -> 0
#   (unflagged)     does EVERY recorded rc still reproduce
#                   on this TLC build?                         clean run -> 0
#   --no-tlc        I asked you to verify and you could not.   always 99
#
# --static-only AND --no-tlc ARE DIFFERENT QUESTIONS, WHICH IS WHY THEY HAVE
# DIFFERENT EXIT CODES. DO NOT MERGE THEM.
#
# `--no-tlc` means the gate was asked to reproduce the recorded rcs and did
# not, so it carries that forward as CHECK_DID_NOT_RUN for every skipped run
# and can never report success. `--static-only` means it was asked for the
# static checks ONLY, and a clean run answers that question completely — so it
# emits no UNCHECKED line for the runs it never promised to make, and exits 0.
# It states the count it did not reproduce instead, because a mode that exits
# 0 without saying what it skipped is the defect this distinction exists to
# avoid. harness/test-drill.sh pins both halves: "--no-tlc: rc 99 even on the
# baseline that passes", and "--static-only: rc 0 on the baseline that
# passes".
#
# Passing both is a usage error. They are two different questions and the gate
# will not guess which one was meant.
#
# OUTPUT — three machine-readable line shapes, then a human block.
#   FINDING   <code> <item> <detail>      a defect. Exits 1.
#   UNCHECKED <check> <subject> <detail>  a check that could not run. Exits 99.
#   DECLARED  <kind> <where> <why>        a check outside what this gate can
#                                         run at all. Prints, and leaves the
#                                         exit code to the other lines.
#   COVERAGE  <count> <freq> <family> <construct>
#   WAIVER    <item> <token> <reason>     a per-item waiver, echoed so waivers
#                                         cannot accumulate unseen. The token
#                                         column reads `count:<module-stem>`
#                                         for a count waiver and the bare
#                                         token for a telegraph one.
#   RUBRIC    <item> power= envelope= ...  check 4's per-item accounting. Its
#                                         `power=` column is the number a
#                                         green fairness arm cannot imply.
#
# EXIT CODES
#     0  every check THIS RUN ASKED FOR ran and passed. Under --static-only
#        that is checks 1 and 3 plus check 2's structural half, and the run
#        prints the count of recorded rcs it did not reproduce
#     1  at least one FINDING. Findings outrank unchecked: a run with both
#        exits 1, because the finding is the actionable half
#    99  no findings, but at least one check COULD NOT RUN. The project-wide
#        CHECK_DID_NOT_RUN code (harness/verdict.sh, bead tla-hl96). An
#        instrument that was asked for a check it could not perform must not
#        report success, so this is not folded into 0
#     2  usage error
#
# CHECKS 1, 2 AND 4 CAN PRODUCE A FINDING. CHECK 3 PRINTS AND NEVER FAILS —
# no construct count can redden this gate. The reasoning is in CHECK 3's own
# section below, and it is worth reading before touching that block.
#
# ===========================================================================
# CHECK 1 — TELEGRAPH.  Is the answer recoverable from the prompt?
#
# This is the corpus's whole reason for existing. Frank's verdict on every
# prior attempt was "too rote, it was hard to make puzzles that didn't just
# have the answer built in", so an item that hands over its own answer is not
# a weak item, it is the defect the corpus was rebuilt to avoid.
#
# WHAT IS CHECKED, in two layers.
#
#   Layer A, the declared layer. For every construct META.md says the item
#   exercises, that construct's TOKEN must not appear in PROMPT.md. The token
#   comes from INVENTORY.md, so the thing being drilled is the thing the
#   prompt may not show. This layer is precise and it is the one that matters:
#   it flags `~>` in the prompt of a leads-to drill and ignores `~>` in the
#   prompt of a CHOOSE drill, where it would be scenery.
#
#   Layer B, the floor. Every DISTINCTIVE operator appearing inside a fenced
#   code block in ANSWER.md must be absent from PROMPT.md, whatever META.md
#   declared. This layer exists because layer A trusts a declaration, and an
#   item that under-declares would otherwise be unchecked.
#
#   A prompt carrying a TLC TRACE gets the same treatment as one carrying
#   code. This is a finding from the trial and it is the non-obvious half of
#   the check: the trace IS part of the prompt, and a LASSO trace is itself a
#   partial answer, because it shows exactly where an action was enabled and
#   skipped, which is half the diagnosis. So a prompt with a trace in it is
#   scanned for tokens like any other, and on top of that its ANSWER.md must
#   say in prose that the trace is there and what it gives away.
#
#   ANSWER.md must carry a non-empty why-not-in-prompt field. The format
#   requires it to hold an honest caveat where the item partly telegraphs.
#
# WHAT IS *NOT* CHECKED, and this list is the honest altitude of the check:
#
#   - DOMAIN SMELL. A prompt that telegraphs by familiarity is invisible
#     here. One trial author flagged exactly this failure in its own item:
#     "a reader who has met a request-served example before may recall `~>`
#     by the smell of the domain". No token appears, nothing fires, and the
#     item is as telegraphed as one that printed the operator. This gate does
#     not catch it and cannot. The why-not-in-prompt field is where that risk
#     is recorded, and only a human reading the field catches it.
#   - WHETHER THE CAVEAT IS TRUE. Presence and length are checked. Honesty is
#     not checkable and is not checked.
#   - ENGLISH PARAPHRASE, deliberately. A prompt saying "eventually the
#     request is served" is not flagged when the answer writes `<>`. That
#     phrasing is the PROBLEM STATEMENT: a drill has to state its
#     requirement in English, and flagging the English would forbid writing a
#     prompt at all. The gate flags the SYMBOL and never the gloss. This is
#     a deliberate hole and it is the largest one in the check.
#   - SHARED TLA+ VOCABULARY, by construction. See DISTINCTIVE below.
#   - WHETHER THE ANSWER IS DERIVABLE by reasoning that never touches the
#     answer's own tokens. That is the interesting case and it is unreachable
#     from here.
#
# ===========================================================================
# CHECK 2 — VERIFICATION.  Does verify/ actually run, and do the recorded
#                          rc AND the recorded state count reproduce?
#
# WHAT IS CHECKED. Every module under verify/ that is CHECKABLE — it has a
# .cfg and ANSWER.md records an rc for it — is run through
# harness/verdict.sh, and the rc TLC returns must equal the rc ANSWER.md
# claims. An item whose recorded rc does not reproduce is the defect; the
# number in the file is a measurement and a measurement that does not
# repeat is wrong.
#
# AND THE DISTINCT-STATE COUNT, where ANSWER.md records one. This half landed
# later than the rc half, and the gap it closed is worth stating: for 64 items
# the gate compared exit codes only, so every state count in the corpus was an
# unguarded claim. The count is the half a READER uses. An rc says which
# verdict TLC reached, where the count is the number a learner checks their
# own model against, and drill/sequences/07-pneumatic-tube/PROMPT.md publishes
# one as its only foreclosing row. They also drift differently: an rc is
# coarse and survives a small spec change, while a count moves on any change
# to the constants, the state space or the initial predicate, and it moves
# without saying so.
#
#   - A claim is read from the table column whose HEADER cell contains the
#     word `distinct`, by position and never by scanning for digits. See
#     COUNT_CLAIM_AWK for why a digit scan cannot tell the rc cell from the
#     one beside it.
#   - NO CLAIM IS NO CHECK. The whole temporal family records no count and
#     that is correct, because a liveness run's state count is not the
#     diagnosis. A measured count with no claim is nobody's finding either.
#   - A claim the run cannot reproduce is VERIFY-COUNT-ABSENT, unless the item
#     declares that case with a `count-waiver:` line in its META.md. Two real
#     rows need one: drill/sets/03-ballast's BallastAnyStart reports during
#     initial-state computation, and drill/core/04-lift-types's
#     NegativeInConfig fails in the config, so neither log carries a count.
#   - WHETHER A COUNT IS PRINTED IS NOT PREDICTABLE FROM THE rc, which is why
#     the waiver is a keyword rather than an inference. See count_waivers.
#
# Three structural checks sit on top of the per-module one:
#
#   - At least one checkable module must record rc 0. Otherwise the stated
#     answer was never shown to check.
#   - At least one must record a non-zero rc. Otherwise no stated wrong
#     answer was ever shown to fail, and the item proves only that something
#     passes.
#   - A recorded rc must be a row of verdict.sh's table. A recorded 1 or 2 is
#     almost always a mis-transcription of a shell exit, and it reproduces
#     against nothing.
#
# The rc rows that matter most here, from harness/verdict.sh's table:
#
#     11 DEADLOCK   12 SAFETY_VIOLATION   13 LIVENESS_VIOLATION
#    150 PARSE_ERROR  255 TLC_EXCEPTION (usually a cross-type comparison,
#                     a string marker sitting beside an integer)
#
#   12 AND 13 SPLIT ON THE SHAPE OF THE FORMULA, NOT THE .cfg KEYWORD
#   (verdict.sh:81-91). `[](P => []P)` and `~<>P` are safety written with
#   temporal operators and exit 12, not 13. An author who reasons from the
#   keyword will record 13 and the run will return 12. That is a real defect
#   in the item and this check is what finds it.
#
# WHAT IS *NOT* CHECKED:
#   - WHETHER THE STATED ANSWER IS THE RIGHT ANSWER. rc 0 proves the module
#     checks, not that it answers the prompt. A vacuous invariant over an
#     empty model exits 0 too. harness/vacuity.sh is the instrument for that
#     question and this gate does not run it.
#   - WHETHER A WRONG ANSWER FAILS FOR THE STATED REASON. rc 12 proves a
#     safety violation happened, not that it was the intended one.
#   - THE ACCEPTABLE VARIANTS. ANSWER.md lists them; nothing here checks that
#     a variant also passes unless it has its own module and rc.
#   - A HELPER MODULE with no cfg and no recorded rc. It is reported as
#     skipped rather than silently ignored, but it is not run.
#   - ANY OTHER NUMBER IN THE TABLE. The `generated` column, trace lengths and
#     depths are read by nobody here. Only the `distinct` column is compared,
#     because it is the one a prompt publishes and a reader lands on.
#   - WHETHER AN ITEM OUGHT TO RECORD A COUNT. A missing claim is silence and
#     this gate keeps it that way, on purpose. Making the claim mandatory
#     would push the eight temporal items into writing a number that is not
#     their diagnosis, which is the same back door CHECK 3 refuses to open.
#
# ===========================================================================
# CHECK 3 — CORPUS COVERAGE. IT REPORTS. IT NEVER FAILS.
#
# THE COVERAGE CHECK PRINTS PER-CONSTRUCT COUNTS AND PRINTS THE GAPS, AND IT
# DOES NOT CONTRIBUTE TO THIS SCRIPT'S EXIT CODE. NO CONSTRUCT COUNT CAN
# REDDEN THE GATE.
#
# WHY, because the next person to read this will want to add the failing arm
# back, and this paragraph is what stops them. V2-PLAN.md:459: "Coverage is
# an end-of-run AUDIT, never the problem-list generator. Organizing by
# construct produces problems whose purpose is 'this one exercises CHOOSE,'
# which is contrived by construction."
#
# The mechanism of harm is a back door. A gate that fails on an uncovered
# token pushes an author to add an artifact for that token, which is the
# forbidden inventory-to-artifact direction arriving by another route. The
# item then exists to satisfy the gate rather than to be worth doing, and a
# contrived item is exactly what this corpus was created to avoid: the
# reader's verdict on every prior attempt was that they were too rote.
#
# THREE THINGS, AND ONLY TWO OF THEM ARE GATEABLE. Whether an ITEM is honest
# is a property of the item, so check 1 gates. Whether an item's recorded
# verdict REPRODUCES is a property of the item, so check 2 gates. Whether the
# CORPUS covers the inventory is a property of a set that is still being
# written, and gating it would make the set's shape serve the gate. That is
# the whole distinction, and it is why this check has no failing arm at all
# rather than a disabled one.
#
# WHAT IT REPORTS. INVENTORY.md names every construct with a family and an
# expected frequency of high, medium or low. Each item's META.md declares the
# constructs it exercises. The gate counts items per construct, prints one
# COVERAGE line each, and prints every gap grouped by frequency with the high
# rows first. That printout is what aims the next authoring wave, which was
# always its real job.
#
# WHAT IT DOES *NOT* DO:
#   - IT DOES NOT FAIL. Not on an uncovered high construct, not on a
#     thin one, not on a frequency column holding a word it does not
#     recognize. All three print.
#   - IT DOES NOT CHECK WHETHER AN ITEM THAT DECLARES A CONSTRUCT ACTUALLY
#     EXERCISES IT. META.md is taken at its word.
#   - IT DOES NOT CHECK WHETHER THE INVENTORY IS COMPLETE. A construct nobody
#     listed is not a gap this gate can see.
#   - IT DOES NOT CHECK ORDERING, DEPENDENCY OR PREREQUISITES. Items are
#     NON-PROGRESSIVE by design (Frank, 2026-10-12). There is deliberately no
#     such check here, and wanting one is a signal of drift rather than a gap.
#
# ONE THING THE COUNTS FEED THAT *DOES* AFFECT THE EXIT CODE, and the
# distinction is worth being exact about. META.md's declaration is also what
# layer A of CHECK 1 scans for. An item that declares nothing, or declares a
# construct INVENTORY.md does not list, leaves layer A with no token to
# compare — so that is reported as UNCHECKED against check 1, which is rc 99.
# That is not a coverage count reddening the gate; it is the telegraph check
# honestly saying it could not run.
#
# ===========================================================================
# CHECK 4 — RUBRIC.  Does the declared envelope say anything?
#
# WHAT A RUBRIC IS. Each item declares what a reasonable model of it does, in
# four fields a prompt can carry without naming a construct: `runs`, `fault`,
# `states` and `obligations`. The checking model judges a learner's run against
# that declaration instead of pairing module names, so every representation
# stays valid. The schema and the rationale for each field are in
# `drill/study/CLAUDE.md`, and the design is
# drawer_tla_puzzles_decisions_6309edf48de99c7168cc221d.
#
# WHY IT IS GATED. Nothing else stops an author writing `states: 1..99999`.
# That satisfies every envelope and reddens nothing, so the field would read as
# a check while checking nothing, and loom's gate-don't-advise says a
# correctness invariant cannot rest on a reviewer's memory. It was open
# decision O3 in the design drawer.
#
# AN ITEM WITH NO `## Rubric` HEADING IS OUT OF SCOPE. 8 of 64 items carry one,
# all in `sets`, because only `core` and `sets` record an rc and a distinct
# count per machine. A check that read absence as a defect would redden on 56
# items. Bead tla-sqym.2 extends the corpus.
#
# WHAT IS CHECKED, in four arms.
#
#   WELL-FORMEDNESS. Each of the four fields is present and inside its
#   grammar, `states` is low..high with low no greater than high, and no
#   unknown key sits in the section. An unknown key is a finding rather than
#   silence, because a misspelled key is a field nobody reads and the rubric
#   still prints green without it.
#
#   TEETH. Every WRONG row of the item's own `## Verify` table, meaning one
#   whose recorded rc is not 0, is either outside the declared envelope OR
#   lands in a fault class a run MEETING the rubric would not produce. The
#   second clause is what admits the two known exceptions: sets/01 records a
#   wrong count of 190 inside 189..398 and sets/02 records 11 and 26 inside
#   9..49, and on both every wrong machine is rc 12 against a declared
#   `fault: none`, so the rc is what rejects them.
#
#   THAT CLAUSE MAKES THE ARM VACUOUS ON TODAY'S CORPUS, and saying so is the
#   point. All 8 rubrics declare `fault: none`, so every rc other than 0 is
#   itself a rejection and no envelope can fail this arm. It is live code for
#   the families tla-sqym.2 brings in, where an item asks for a violation and
#   declares `fault: invariant`, and there an rc 12 machine is NOT excused.
#
#   THE FLOOR. The envelope must exclude at least one of the item's own
#   recorded wrong counts. This is the arm that catches `1..99999`, and it
#   exists because neither of the two above can: teeth lets the rc excuse
#   everything, and fairness only asks that correct counts be inside, which a
#   wide envelope satisfies trivially. It is the per-root-floor pattern
#   harness/test-spelling.sh uses, where a root that selects nothing reddens
#   instead of passing.
#
#   FAIRNESS. Every CORRECT row's count lies inside the envelope. An item that
#   ships a correct model the envelope rejects has an envelope that rejects a
#   reasonable model, which is the one failure Frank's representation-freedom
#   constraint rules out.
#
# WHAT IS *NOT* CHECKED, and the first entry is the one that matters:
#
#   - WHETHER THE ENVELOPE IS FAIR. Every envelope in the corpus today is the
#     lowest and highest count among its item's own rc 0 rows, so the fairness
#     arm passes by construction and its green says nothing. The run prints
#     SOUNDNESS POWER for exactly this reason. See that block at the bottom.
#   - WHETHER THE ENVELOPE IS TIGHT. Deliberate. Bead tla-sqym.3 widens these
#     from reasons rather than from counts, and a reasoned envelope is supposed
#     to be wider than three machines justify. An arm penalizing width would
#     push the field back to the point count the design replaces.
#   - WHETHER `obligations` IS THE RIGHT NUMBER. The grammar is checked. The
#     count rests on the item's own answer config and nothing here resolves it.
#   - WHETHER THE TWO `-because` LINES OR THE FAULT LIST ARE PRESENT, let alone
#     true. They are withheld from the prompt and owed by tla-sqym.3. Making
#     them mandatory before they exist would redden all 8 items on work nobody
#     has done yet.
#   - ANYTHING A RUN SAYS. No TLC starts in this check. It compares two
#     sections of one file, so it runs in every tier including --static-only.
#
# ===========================================================================
# WHAT THIS CORPUS DELIBERATELY DOES NOT GET
#
# Private-first, not shippable (Frank, 2026-10-12). So there is NO novelty
# screen, NO comment gate and NO freeze digest in this gate:
# harness/screen.sh, harness/comment-gate.sh and FREEZE.sha256 are NOT wired
# here, on purpose. That apparatus is what makes authoring expensive, and
# expensive authoring is what stalled both prior attempts at ten items. If
# the corpus ever ships, it gets added then.
# ===========================================================================

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERDICT="${REPO_ROOT}/harness/verdict.sh"

# ---------------------------------------------------------------------------
# DISTINCTIVE — layer B's token set, and the exclusions that make it usable.
#
# A drill prompt is often allowed to SHOW A SPEC and ask for the missing
# piece. That prompt legitimately contains `/\`, `\in`, `\A`, `=>` and the
# rest of the shared vocabulary of the language, and so does almost any
# answer. Flagging those would fail every item of that shape, so the floor
# set holds only tokens that pick out WHICH CONSTRUCT the answer is.
#
# DISTINCTIVE: in the prompt of an item whose answer uses it, this is a
# partial give-away.
DISTINCTIVE=(
  '~>' '<>' '[]' ']_' 'WF_' 'SF_' 'ENABLED'
  'UNCHANGED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'INSTANCE' 'RECURSIVE'
  '|->' ':>' '@@' 'LAMBDA'
  'Cardinality' 'Permutations' 'SelectSeq' 'TLCGet' 'Assert'
  '\X' '\o' '\cup' '\cap' '\subseteq' '\notin'
)
# EXCLUDED ON PURPOSE, and this is the list to read before widening the set:
#
#   /\  \/  \in  \A  \E  =>  <=>  ~  '  =  #  /=
#       the shared vocabulary. Present in any shown spec and in any answer.
#   LET IN IF THEN ELSE  TRUE FALSE  Nat Int Seq BOOLEAN
#   Len Append Head Tail SubSeq  DOMAIN  VARIABLE VARIABLES CONSTANT EXTENDS
#       structure and the standard modules. A prompt that shows a spec shows
#       these, and an answer that touches a sequence or a function uses them
#       without that being the point of the drill.
#   '   the prime. Excluded because it is an apostrophe in English prose and
#       a prompt is prose.
#
# Layer A still covers every one of these: if the inventory names `DOMAIN` as
# a construct and META.md declares it, the prompt may not show it. The
# exclusions weaken the FLOOR only, never the declared layer.

# LAYER_A_SYMBOLS — what construct_tokens scans an inventory cell for. WIDER
# than DISTINCTIVE on purpose, because layer A is not guessing which tokens
# matter: the author declared the construct, so its symbol is the subject of
# the answer. The prime is still out, since it is an apostrophe in prose and
# a prompt is prose.
LAYER_A_SYMBOLS=(
  '~>' '<>[]' '<>' '[][' '[]' ']_' 'WF_' 'SF_'
  # $'/\\' rather than '/\': both are the two bytes /\ , proven against a
  # running shell, but the single-quoted form raises SC1003 because \' reads
  # as an attempted quote escape.
  '|->' ':>' '@@' ':=' '||' $'/\\' '\/' '=>' '<=>' '<<' '>>' '..' '\X' '\o'
  '\A' '\E' '\AA' '\EE' '\in' '\notin' '\subseteq' '\cup' '\cap' '\div'
  '==' '/=' '#' '^' '%'
  'UNCHANGED' 'ENABLED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'DOMAIN'
  'INSTANCE' 'RECURSIVE' 'EXTENDS' 'LOCAL' 'ASSUME' 'THEOREM' 'LAMBDA'
  'VARIABLE' 'CONSTANT' 'LET' 'BOOLEAN'
  'Cardinality' 'Permutations' 'SelectSeq' 'SubSeq' 'Append' 'Head' 'Tail'
  'Len' 'Seq' 'TLCGet' 'Assert'
)

INVENTORY=""
NO_TLC=0
STATIC_ONLY=0
CHANGED_ONLY=0
JOBS=1
STATE_FILE=""
TIMEOUT=60
QUIET=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory)   INVENTORY="${2:-}"; shift ;;
    --no-tlc)      NO_TLC=1 ;;
    --static-only) STATIC_ONLY=1 ;;
    --changed-only) CHANGED_ONLY=1 ;;
    --state)       STATE_FILE="${2:-}"; shift ;;
    --jobs)        JOBS="${2:-1}"; shift ;;
    -P)            JOBS="${2:-1}"; shift ;;
    # `-P8` as well as `-P 8`. This arm must stay AHEAD of the `-*` catch-all
    # below, since a case statement takes the first matching pattern.
    -P*)           JOBS="${1#-P}" ;;
    --timeout)     TIMEOUT="${2:-60}"; shift ;;
    -q|--quiet)    QUIET=1 ;;
    -h|--help)
      awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "drill-gate.sh: unknown option '$1' (try --help)" >&2
      exit 2
      ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "drill-gate.sh: more than one drill root given ('$ROOT', '$1')" >&2
        exit 2
      fi
      ROOT="$1"
      ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  echo "drill-gate.sh: no drill root given (try --help)" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "drill-gate.sh: '$ROOT' is not a directory" >&2
  exit 2
fi
[ -n "$INVENTORY" ] || INVENTORY="${ROOT}/INVENTORY.md"
[ -n "$STATE_FILE" ] || STATE_FILE="${REPO_ROOT}/.drill-gate-state"

case "$JOBS" in
  ''|*[!0-9]*)
    echo "drill-gate.sh: --jobs/-P wants a positive integer, got '$JOBS'" >&2
    exit 2
    ;;
esac
if [ "$JOBS" -lt 1 ]; then
  echo "drill-gate.sh: --jobs/-P wants a positive integer, got '$JOBS'" >&2
  exit 2
fi

# The two modes answer different questions and have different exit codes, so
# the gate refuses to guess which one a caller meant. See THE THREE TIERS.
if [ "$NO_TLC" = "1" ] && [ "$STATIC_ONLY" = "1" ]; then
  echo "drill-gate.sh: --no-tlc and --static-only are different questions with different exit codes; pass one" >&2
  exit 2
fi

finding_n=0
unchecked_n=0
item_n=0
LAYERA_COVERED=0
LAYERA_NOTOK=0

# --static-only's honesty counter: how many recorded rcs this run reached and
# deliberately did not reproduce. A mode that exits 0 has to say this number.
static_n=0

# --changed-only's three counters, in the order its header reports them.
verified_n=0
cached_n=0
stale_n=0

# The distinct-state count's coverage, reported in one line at the end of
# every run. COVERAGE OF A CHECK IS ITSELF A CLAIM, and the whole reason this
# half of check 2 exists is that the counts were guarded by nothing while the
# rcs looked checked. A run that compared three counts out of two hundred and
# said only VERDICT OK would be the same silence wearing a green badge.
count_claim_n=0
count_checked_n=0
count_waived_n=0

# Check 4's counters. SOUNDNESS POWER IS THE ONE THAT HAS TO BE PRINTED, and
# the reason is in check 4's header: an envelope read off the counts it is then
# tested against passes the fairness arm by construction, so the arm's green
# says nothing on its own. The power is the number of cases where an item ships
# two correct models whose distinct counts differ, which is the only place the
# corpus can tell a fair envelope from a tight one.
rubric_item_n=0
rubric_power_n=0
rubric_zero_power=""
rubric_correct_n=0
rubric_wrong_n=0
rubric_excluded_n=0
rubric_by_rc_n=0
rubric_nocount_n=0

# One scratch dir for the whole run. SYMFILE holds LAYER_A_SYMBOLS one per
# line so construct_tokens can match them all in a single grep.
SCRATCH="$(mktemp -d)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
gate_cleanup() { rm -rf "$SCRATCH"; }
trap gate_cleanup EXIT
SYMFILE="${SCRATCH}/layer-a-symbols"
printf '%s\n' "${LAYER_A_SYMBOLS[@]}" >"$SYMFILE"

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-28s %-44s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-28s %-44s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

# declared <kind> <where> <why>: a check this gate CATEGORICALLY cannot run,
# as distinct from one that could not run TODAY.
#
# The difference is the whole point and it decides the exit code. UNCHECKED
# means the instrument failed and somebody should fix it, so it escalates to
# rc 99, CHECK_DID_NOT_RUN. DECLARED means the claim is not of a kind this
# gate can see, the item says so and carries its own measurement, and no
# amount of fixing the gate will change that. It prints and does not escalate.
#
# Conflating the two is the defect bead tla-hl96 is about, arriving from the
# other side: an instrument that cannot tell a permanent fact from today's
# breakage either cries wolf forever or goes quiet about a real failure. The
# refutation-coverage gate drew the same line this morning, between a
# traces/NONE.md that declares and explains an absence and a directory nobody
# has filled yet.
#
# THE SECOND CALLER IS NOT AN ITEM CLAIM AT ALL, and bead tla-dnwi is why it
# is here. --changed-only reports through this when it cannot resolve the TLC
# build out of the `tlc` wrapper on PATH. A wrapper is fixable, so that reads
# at first like today's breakage rather than a category. The category test is
# what claim went unanswered, and the answer is none: every job ran and every
# recorded rc was reproduced against the build on PATH. What the run declined
# was the cache, and no check named `verify-cache` exists whose failure leaves
# the corpus unverified. So the honest report is one that prints and counts
# without escalating, which is this one.
declared_n=0
declared() { printf 'DECLARED  %-28s %-44s %s\n' "$1" "$2" "$3"; declared_n=$((declared_n + 1)); }

# ===========================================================================
# CHECK 2's TLC QUEUE — two phases, and the split exists for ONE reason.
#
# A COUNTER INCREMENTED IN A SUBSHELL IS SILENTLY LOST. `finding()` and
# `unchecked()` both increment, and a parallel job runs in a child process, so
# a job that called either would print its line and lose the count. The run
# would then end with `finding_n` at 0 and exit 0 while FINDING lines sat in
# its own output. That is a FALSE PASS on this gate's only correctness check,
# and it is the whole reason check 2 is not simply wrapped in `xargs -P`.
#
# So PHASE A, inside the item sweep, does every static check exactly where it
# did before and ENQUEUES the TLC run instead of making it. PHASE B, after the
# sweep, dispatches the queue and then THE PARENT reads the outcomes and emits
# every FINDING and OK line itself. No child ever touches a counter.
#
# WHAT THIS CHANGES ABOUT THE OUTPUT, and it is deliberate. The OK lines used
# to interleave with each item. They now arrive as one block after the sweep,
# in item-then-module order, under their own header. The order is stable
# because the job files are named with a zero-padded sequence and the parent
# walks them in that order, whatever order the runs finished in.
#
# A JOB IS A FILE, ONE FIELD PER LINE, read back with `mapfile`. Fields, in
# order:
#
#   0 rel   1 modbase   2 module path   3 cfg path   4 want   5 deadlock 0|1
#   6 cache key, or the literal "-"
#
# ONE FIELD PER LINE AND NOT A TSV. `IFS=$'\t' read -r a b c` does not
# preserve an empty field: tab is an IFS *whitespace* character, so a run of
# tabs collapses into one delimiter and every later field shifts left. That
# has bitten this repo twice — see the note above parse_inventory_tab, where
# an empty field 8 slid the sentinel and made a 105-row inventory read as
# fully covered. A literal "-" stands in for an empty field here so that no
# line is lost either way.
# ===========================================================================
JOB_SEQ=0
declare -a JOB_FILES=() JOB_CACHED=()
JOBLIST="${SCRATCH}/joblist"
RUNLIST="${SCRATCH}/runlist"
RUNONE="${SCRATCH}/run-one.sh"
: >"$JOBLIST"
: >"$RUNLIST"

# Job files live directly in SCRATCH rather than in a subdirectory of it, so
# that enqueueing costs no `mkdir` fork. The static tiers never enqueue, and
# part 2b of harness/test-drill.sh holds the static pass to a fork ceiling.
enqueue_job() {
  JOB_SEQ=$((JOB_SEQ + 1))
  local jf
  # `printf -v` is a builtin, where `jf=$(printf ...)` would fork a subshell
  # per job. Same reasoning as normalize's.
  printf -v jf '%s/job-%06d' "$SCRATCH" "$JOB_SEQ"
  # F[7] is the claimed distinct-state count and may be EMPTY, which is the
  # no-claim case and has to survive the round trip. `printf '%s\n'` writes a
  # bare newline for it and `mapfile -t` reads that back as an empty element,
  # so the field keeps its position. F[8] is its waiver flag.
  printf '%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" >"$jf"
  printf '%s\n' "$jf" >>"$JOBLIST"
  JOB_FILES+=("$jf")
  JOB_CACHED+=(0)
}

# ---------------------------------------------------------------------------
# --changed-only's cache key.
#
#   sha256( jar_sha | verdict_sh_sha | rel | modbase | want | deadlock
#           | timeout | verify_tree_digest )
#
# EVERY ONE OF THOSE EIGHT CHANGES THE VERDICT, which is why none is dropped.
# A key over the module's own bytes alone would cache a verdict across a TLC
# upgrade, a verdict.sh change, a cfg edit or a different timeout, and report
# a stale number as verified.
#
# verify_tree_digest COVERS EVERY FILE UNDER THE ITEM'S verify/, not the
# module and its cfg. A module can EXTENDS a sibling helper, so a key over the
# pair alone misses a helper edit — and a helper edit changes what TLC checks
# while leaving the module byte-identical. That is one step further than the
# parent bead's caution against keying on the module hash, and it is the step
# that makes the cache sound rather than merely cheap.
#
# KEYS ARE COMPUTED ONLY UNDER --changed-only. The static tiers compute none,
# because a sha256 is a fork per job and the fork ceiling in part 2b of
# harness/test-drill.sh is what keeps the static pass off that path. If that
# row goes red, key computation has leaked onto the static path.
# ---------------------------------------------------------------------------
CACHE_BASE=""
declare -A STATE_KEY=() STATE_ID=()
declare -a NEW_KEYS=() NEW_IDS=()
STATE_PRESENT=0

# CACHE_ACTIVE — --changed-only has nothing to do when no job can reach the
# queue. --static-only and --no-tlc both stop before the enqueue, so under
# either of them the cache base is never resolved, no key is ever computed and
# the state file is never written. Found by the control in part 2e of
# harness/test-drill.sh, which caught `--static-only --changed-only` creating
# an empty state file: no key had been computed, but the writer ran anyway and
# left a file behind on a path that is supposed to touch nothing.
#
# The header still prints under --changed-only and says a static tier reached
# no job, because a run that silently consulted nothing is the thing these
# blocks exist to prevent.
CACHE_ACTIVE=0
if [ "$CHANGED_ONLY" = "1" ] && [ "$NO_TLC" = "0" ] && [ "$STATIC_ONLY" = "0" ]; then
  CACHE_ACTIVE=1
fi

# sha_of_string <s>: sets SHA to the sha256 of the string, with no trailing
# newline distinction that matters — a here-string always appends one, and it
# appends the same one every run.
SHA=""
sha_of_string() {
  SHA="$(sha256sum <<<"$1")"
  SHA="${SHA%% *}"
}

# sha_of_file <path>: sets SHA, or empty when the file is unreadable.
sha_of_file() {
  SHA=""
  [ -f "$1" ] || return 1
  SHA="$(sha256sum -- "$1")"
  SHA="${SHA%% *}"
}

# resolve_jar: sets JAR_PATH to the jar the pinned `tlc` wrapper runs.
#
# RESOLVED FROM THE WRAPPER, NEVER HARDCODED. Reading the wrapper is what
# makes the key follow a toolchain change rather than a path somebody typed
# here. The jar sits at the same place on both boxes today, so a typed path
# would work, and it would go on working while naming a build nobody runs.
#
# TWO WRAPPER SHAPES ARE IN USE AND BOTH ARE READ. scripts/setup:208 writes a
# `JAR=` line. The CI workflow writes its own wrapper inline at
# .github/workflows/verify-puzzles.yml:130-132 and puts the jar straight into
# `-cp`, with no `JAR=` line at all. Reading only the first shape is bead
# tla-dnwi: this returned 1 on every CI run, and the nine --changed-only rows
# of harness/test-drill.sh passed locally and returned 99 in CI.
#
# THE SHAPES ARE TRIED IN ORDER, `JAR=` first, and the first candidate that is
# a readable file wins. The order carries weight because the local wrapper
# holds both. Its `-cp "$JAR"` is a shell variable this function cannot
# expand, so a `-cp`-first pass would take `$JAR` for a path and decline.
#
# A CLASSPATH OF MORE THAN ONE ENTRY IS NOT SPLIT ON `:`. Which entry is then
# the TLC build is a question the key cannot answer, so a wrapper like that
# resolves to nothing and the caller declines to cache. That is the safe
# direction, and the caller says out loud that it took it.
#
# When nothing resolves, the caller reports DECLARED and runs every job.
# Caching against an unknown build is the one failure this cache must not
# have, and declining to cache is not a failure to check.
JAR_PATH=""
resolve_jar() {
  JAR_PATH=""
  local w line v
  local -a cands=()
  w="$(command -v tlc 2>/dev/null)" || return 1
  [ -n "$w" ] || return 1
  [ -f "$w" ] || return 1

  # PURE BASH, and two passes over a ten-line file rather than one pass into
  # two arrays. The two-array form needs `${a[@]+"${a[@]}"}` to survive an
  # empty array under `set -u`, and a second `read` loop is cheaper to read
  # than that is. Neither pass forks, where the awk this replaced forked once.
  while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*JAR=(.*)$ ]]; then
      cands+=("${BASH_REMATCH[1]}")
    fi
  done <"$w"
  while IFS= read -r line; do
    if [[ $line =~ (^|[[:space:]])-(cp|classpath)[[:space:]]+([^[:space:]]+) ]]; then
      cands+=("${BASH_REMATCH[3]}")
    fi
  done <"$w"

  [ "${#cands[@]}" -gt 0 ] || return 1
  for v in "${cands[@]}"; do
    v="${v%\"}"
    v="${v#\"}"
    v="${v%\'}"
    v="${v#\'}"
    v="${v/\$\{HOME\}/$HOME}"
    v="${v/\$HOME/$HOME}"
    v="${v/#\~/$HOME}"
    [ -n "$v" ] || continue
    [ -f "$v" ] || continue
    JAR_PATH="$v"
    return 0
  done
  return 1
}

# verify_tree_digest <dir>: sets TREE_DIGEST over every file under <dir>,
# content AND relative name, independent of where the repo is checked out.
#
# The `cd` makes find emit `./Good.tla` rather than an absolute path, so the
# digest does not change when the tree moves — a worktree would otherwise
# invalidate the whole cache on every dispatch. Sorting before the outer hash
# makes it independent of find's directory order too.
TREE_DIGEST=""
verify_tree_digest() {
  TREE_DIGEST=""
  [ -d "$1" ] || return 1
  local lines
  lines="$(cd -- "$1" && find . -type f -exec sha256sum -- {} + 2>/dev/null | LC_ALL=C sort)"
  sha_of_string "$lines"
  TREE_DIGEST="$SHA"
}

# ---------------------------------------------------------------------------
# normalize <text>: the form constructs are MATCHED in. Lowercased, backticks
# and surrounding punctuation stripped, whitespace collapsed. The RAW cell is
# kept separately, because that is where a token like `~>` survives.
#
# PURE BASH. This used to fork `tr` and then `sed` on every call, which was
# all 855 `tr` execs and most of the 795 `sed` execs bead tla-0eis.1 measured
# over the 32-item tree. The expansions below do the same work in-process.
#
# TWO CHOICES HERE ARE NOT INTERCHANGEABLE WITH THE OBVIOUS ONES.
#
# The lowercase pattern spells out A to Z rather than using a bare `${s,,}`.
# `${s,,}` is locale-aware and lowercases non-ASCII. The `tr` it replaces did
# not: in en_US.UTF-8, `tr '[:upper:]' '[:lower:]'` leaves an accented capital
# alone. So a construct cell holding one would normalize two ways and match
# two different inventory rows. `[A-Z]` is not the fix either, because a
# bracket RANGE follows collation order and can pull in accented letters.
#
# The function reads ONE LINE. A newline in the input collapses to a space
# here, where the old `sed` kept it and anchored `^` and `$` per line. No
# caller can reach that difference: every call site passes a single field
# that came out of `read -r`, and such a field cannot hold a newline.
#
# IT SETS NORM AND PRINTS NOTHING, so that no caller needs `$( )`. The
# inventory and the declared constructs call this 563 times over the 32-item
# tree, and a command substitution forks a subshell every time, which was
# 563 forks carrying a string back. See inv_index's own note further down for
# the other half of this: a global assigned INSIDE a `$( )` cannot escape it,
# so a function that returns through a global has to be called plainly.
# ---------------------------------------------------------------------------
NORM=""
normalize() {
  local s="${1//\`/}"
  s="${s,,[ABCDEFGHIJKLMNOPQRSTUVWXYZ]}"
  # Every whitespace character becomes a space, then runs of spaces collapse.
  # Each pass halves a run, so the loop ends after log2(run length) passes.
  s="${s//[[:space:]]/ }"
  while [[ "$s" == *"  "* ]]; do s="${s//  / }"; done
  # Strip the leading and trailing class one character per pass. `sed` took
  # each end greedily, and both forms converge on the same maximal prefix and
  # suffix of class characters.
  local prev=""
  while [ "$s" != "$prev" ]; do
    prev="$s"
    s="${s#[[:space:],.;:*_-]}"
    s="${s%[[:space:],.;:*_-]}"
  done
  NORM="$s"
}

# ---------------------------------------------------------------------------
# INVENTORY.md — TWO shapes are read, and the TAB shape is the real one.
#
# SHAPE 1, TAB-DELIMITED ROW LINES. This is what drill/INVENTORY.md actually
# ships, and its own "For the gate author" section specifies it: rows carry
# the literal first field `ROW` and are separated by single tabs, so prose in
# the file can never be read as data. Eight fields, in this order:
#
#   1 marker `ROW`   2 id K001-K105      3 family        4 construct
#   5 source f:line  6 weight hi/med/low 7 basis         8 items
#
# Field 8 is the coverage field and it is empty on every row today. This gate
# READS it and unions whatever it names into the per-construct count, so the
# documented contract is honoured. It does NOT WRITE it: drill/ belongs to the
# authors and the sibling that owns the inventory, and a report-only check has
# no business editing the file it reports on.
#
# SHAPE 2, A MARKDOWN PIPE TABLE. Read as a fallback, with the header located
# by CONTENT rather than by position — the columns are found by looking for
# `construct`, `family` and `freq`-or-`weight` in the header cells, so a table
# that reorders them still parses.
#
# Neither shape parsing means check 3 reports UNCHECKED rather than quietly
# counting nothing.
#
# A NOTE ON THE CONSTRUCT CELL, because it decides how much CHECK 1's layer A
# can do. The real inventory's field 4 is PROSE taken verbatim from a cheat
# sheet: "Operator definition", "EXTENDS (module import)", "IF-THEN-ELSE".
# Some of those carry a symbol a prompt could leak and most do not, which is
# why construct_tokens below works hard to find one and why a construct with
# none is reported as out of layer A's reach rather than as a failure.
# ---------------------------------------------------------------------------
declare -a INV_RAW=() INV_NORM=() INV_FAMILY=() INV_FREQ=() INV_ITEMS=()
INV_OK=0
INV_SHAPE=""

# NOTE ON THE DELIMITER, because the obvious version of this is broken.
#
# `IFS=$'\t' read -r a b c d e` DOES NOT preserve an empty field. Tab is an
# IFS *whitespace* character, so a run of tabs collapses into one delimiter
# and the empty cell simply disappears, shifting every later field left.
# Field 8 of the real inventory is empty on every row today, which is exactly
# the case that triggers it: the sentinel slid into `items` and every one of
# the 105 constructs reported a count of 1. A fully-covered inventory with
# zero items in the tree, which is the false-PASS direction on the audit.
#
# So awk re-emits the record delimited by ASCII US (0x1f), which is not a
# whitespace character, and empty fields survive. harness/test-drill.sh part
# 1g is what caught this and is what keeps it fixed.
parse_inventory_tab() {
  local rec id fam raw weight items itemsf sentinel norm
  local n=0
  while IFS=$'\037' read -r id fam raw weight items sentinel; do
    [ "$sentinel" = "END" ] || continue
    normalize "$raw"
    norm="$NORM"
    [ -n "$norm" ] || continue
    # The `*)` arm reads NORM straight back, since it is still the normalized
    # weight this case is branching on.
    normalize "$weight"
    case "$NORM" in
      high*) weight=high ;;
      med*)  weight=medium ;;
      low*)  weight=low ;;
      *)     weight="unrecognized:${NORM}" ;;
    esac
    INV_RAW+=("$raw")
    INV_NORM+=("$norm")
    INV_FAMILY+=("${fam:-?}")
    INV_FREQ+=("$weight")
    # Field 8 is comma-separated. Normalise to spaces for the union below.
    itemsf="${items:-}"
    INV_ITEMS+=("${itemsf//,/ }")
    n=$((n + 1))
    # id is read but not otherwise used; the construct text is the key.
    rec="$id"
  done < <(awk -F'\t' -v U=$'\037' \
    '$1 == "ROW" { printf "%s%s%s%s%s%s%s%s%s%sEND\n", $2, U, $3, U, $4, U, $6, U, $8, U }' \
    "$INVENTORY")
  [ -n "${rec:-}" ] || return 1
  [ "$n" -gt 0 ]
}

parse_inventory_pipe() {
  local c_construct=-1 c_family=-1 c_freq=-1
  local line cells i cell ncells
  local in_table=0

  while IFS= read -r line; do
    case "$line" in
      \|*) : ;;
      *) continue ;;
    esac
    local body="${line#\|}"
    body="${body%\|}"
    IFS='|' read -r -a cells <<<"$body"
    ncells=${#cells[@]}
    [ "$ncells" -ge 3 ] || continue

    if [ "$in_table" = "0" ]; then
      for ((i = 0; i < ncells; i++)); do
        normalize "${cells[$i]}"
        cell="$NORM"
        case "$cell" in
          *construct*)        c_construct=$i ;;
          *family*)           c_family=$i ;;
          *freq*|*weight*)    c_freq=$i ;;
        esac
      done
      if [ "$c_construct" -ge 0 ] && [ "$c_family" -ge 0 ] && [ "$c_freq" -ge 0 ]; then
        in_table=1
      fi
      continue
    fi

    # Skip the --- separator row.
    local sep="${cells[0]//-/}"
    sep="${sep// /}"
    sep="${sep//:/}"
    [ -n "$sep" ] || continue

    local raw="${cells[$c_construct]}"
    local norm; normalize "$raw"; norm="$NORM"
    [ -n "$norm" ] || continue
    local fam; normalize "${cells[$c_family]}"; fam="$NORM"
    local frq; normalize "${cells[$c_freq]}"; frq="$NORM"
    case "$frq" in
      high*)   frq=high ;;
      med*)    frq=medium ;;
      low*)    frq=low ;;
      *)       frq="unrecognized:${frq}" ;;
    esac

    local trimmed="$raw" tprev=""
    while [ "$trimmed" != "$tprev" ]; do
      tprev="$trimmed"
      trimmed="${trimmed#[[:space:]]}"
      trimmed="${trimmed%[[:space:]]}"
    done
    INV_RAW+=("$trimmed")
    INV_NORM+=("$norm")
    INV_FAMILY+=("${fam:-?}")
    INV_FREQ+=("$frq")
    INV_ITEMS+=("")
  done <"$INVENTORY"

  [ "${#INV_NORM[@]}" -gt 0 ]
}

if [ -f "$INVENTORY" ]; then
  if grep -qE '^ROW'$'\t' "$INVENTORY"; then
    if parse_inventory_tab; then INV_OK=1; INV_SHAPE="tab-delimited ROW lines"; fi
  elif parse_inventory_pipe; then
    INV_OK=1; INV_SHAPE="markdown pipe table"
  fi
fi

# ---------------------------------------------------------------------------
# build_inv_tokens: fills INV_TOKENS, one entry per inventory row, each
# holding the literal strings a prompt may not show for that construct,
# newline separated. Derived four ways, in order:
#
#   1. a backticked span in the cell          `~>`          -> ~>
#   2. a parenthesised symbol-ish span        leads-to (~>) -> ~>
#   3. the cell itself, when it looks like a token (pure symbols, ALL_CAPS,
#      or a trailing-underscore operator like WF_)
#   4. an alias table, for a cell written as prose
#
# A construct that yields NO token is reported UNCHECKED rather than passed
# over, because layer A silently covering nothing is the false-PASS
# direction. The remedy is one backtick pair in the inventory cell.
#
# FOUR GREPS FOR THE WHOLE INVENTORY, where this used to be a per-row
# function forking six. That cost 560 greps and 105 `sed` execs over the real
# 105-row inventory, which is the largest block left once bead tla-0eis.1's
# three named callers are fixed. Each "find every match" route now runs ONE
# grep over a file holding every raw cell, with `-n` so a match carries its
# row number back. The two membership tests became bash `=~` against the same
# ERE. Route 3c already worked this way, and its reasoning is this one.
#
# ORDER IS PART OF THE CONTRACT. Layer A walks a row's tokens in sequence and
# raises a FINDING per token the prompt shows, so re-ordering the routes
# re-orders the run's output. The routes append in the order above.
# ---------------------------------------------------------------------------

# TOKENISH — routes 2 and 3 ask whether a span is itself a token. bash `=~`
# reads POSIX ERE, which is the dialect `grep -E` read this pattern in.
TOKENISH='^[^A-Za-z0-9 ]+$|^[A-Z][A-Za-z]*_$|^[A-Z_]{2,}$'

build_inv_tokens() {
  INV_TOKENS=()
  local n="${#INV_RAW[@]}"
  [ "$n" -gt 0 ] || return 0

  # ONE LINE PER ROW, so grep's `-n` prefix IS the row number. A row that
  # matches nothing contributes no line and the numbering still holds.
  local rawfile="${SCRATCH}/inv-raw"
  printf '%s\n' "${INV_RAW[@]}" >"$rawfile"

  local -a BT=() PAR=() CAPS=() SYM=()
  local i ln tok
  for ((i = 0; i < n; i++)); do BT+=(""); PAR+=(""); CAPS+=(""); SYM+=(""); done

  # 1. backticked spans.
  # The pattern needs two LITERAL backticks and must not expand, which is
  # what single quotes are doing here. shellcheck reads the pair as a
  # command substitution it is warning me about.
  # shellcheck disable=SC2016
  grep -oEn -- '`[^`]+`' "$rawfile" >"${SCRATCH}/m-bt" || true
  while IFS=: read -r ln tok; do
    [ -n "$tok" ] || continue
    BT[ln - 1]="${BT[ln - 1]}${tok}"$'\n'
  done <"${SCRATCH}/m-bt"

  # 2. parenthesised spans. Whether each one is symbol-ish is decided below.
  grep -oEn -- '\([^)]+\)' "$rawfile" >"${SCRATCH}/m-par" || true
  while IFS=: read -r ln tok; do
    [ -n "$tok" ] || continue
    PAR[ln - 1]="${PAR[ln - 1]}${tok}"$'\n'
  done <"${SCRATCH}/m-par"

  # 3b. ALL-CAPS keywords sitting INSIDE a prose cell. This is what reaches
  # the real inventory, whose field 4 is prose from a cheat sheet:
  # "EXTENDS (module import)" yields EXTENDS, "IF-THEN-ELSE" yields IF, THEN
  # and ELSE. Two letters minimum, so an initial does not become a token.
  grep -oEn -- '[A-Z][A-Z_]+' "$rawfile" >"${SCRATCH}/m-caps" || true
  while IFS=: read -r ln tok; do
    [ -n "$tok" ] || continue
    CAPS[ln - 1]="${CAPS[ln - 1]}${tok}"$'\n'
  done <"${SCRATCH}/m-caps"

  # 3c. any TLA+ symbol or operator NAME appearing in the cell, against a
  # pattern file built once at startup. The obvious loop forks a grep per
  # symbol, which is 70 forks per construct and 7,350 for the real 105-row
  # inventory. That measured 25 s against 7 s for the whole suite.
  #
  # This scans LAYER_A_SYMBOLS, which is WIDER than DISTINCTIVE and includes
  # the shared vocabulary the floor excludes. The asymmetry is deliberate.
  # The floor has to guess which tokens matter, so it must not flag `\in` in
  # a prompt that merely shows a spec. Layer A is not guessing: the author
  # DECLARED this construct, so its symbol is the subject of the answer, and
  # a prompt showing it gives that away. The real inventory has rows named
  # `\A (universal quantifier, "forall")` and `:= assignment`, and layer A
  # would reach neither from DISTINCTIVE alone.
  grep -oFn -f "$SYMFILE" -- "$rawfile" >"${SCRATCH}/m-sym" || true
  while IFS=: read -r ln tok; do
    [ -n "$tok" ] || continue
    SYM[ln - 1]="${SYM[ln - 1]}${tok}"$'\n'
  done <"${SCRATCH}/m-sym"

  local raw toks got t bare prev alias
  for ((i = 0; i < n; i++)); do
    raw="${INV_RAW[i]}"
    toks=""
    got=0

    while IFS= read -r t; do
      t="${t//\`/}"
      [ -n "$t" ] || continue
      toks="${toks}${t}"$'\n'
      got=1
    done <<<"${BT[i]}"

    while IFS= read -r t; do
      [ -n "$t" ] || continue
      t="${t#(}"; t="${t%)}"
      [ -n "$t" ] || continue
      if [[ "$t" =~ $TOKENISH ]]; then
        toks="${toks}${t}"$'\n'
        got=1
      fi
    done <<<"${PAR[i]}"

    # 3. the bare cell, when it is itself a token.
    bare="$raw"
    prev=""
    while [ "$bare" != "$prev" ]; do
      prev="$bare"
      bare="${bare#[[:space:]]}"
      bare="${bare%[[:space:]]}"
    done
    if [[ "$bare" =~ $TOKENISH ]]; then
      toks="${toks}${bare}"$'\n'
      got=1
    fi

    while IFS= read -r t; do
      [ -n "$t" ] || continue
      toks="${toks}${t}"$'\n'
      got=1
    done <<<"${CAPS[i]}"

    if [ -n "${SYM[i]}" ]; then
      toks="${toks}${SYM[i]}"
      got=1
    fi

    # 4. the alias table. Modest on purpose: a prose cell that is not here is
    #    reported unchecked, which is a louder and more useful signal than a
    #    guess. It runs only when nothing above produced a token, so it
    #    assigns rather than appends.
    if [ "$got" = "0" ]; then
      normalize "$raw"
      alias="$NORM"
      case "$alias" in
        *"eventually always"*)                 toks='<>[]'$'\n' ;;
        *"leads to"*|*"leads-to"*|*"leadsto"*) toks='~>'$'\n' ;;
        *"weak fairness"*|*"weakly fair"*)     toks='WF_'$'\n' ;;
        *"strong fairness"*|*"strongly fair"*) toks='SF_'$'\n' ;;
        *eventually*)                          toks='<>'$'\n' ;;
        *"always"*|*"box operator"*)           toks='[]'$'\n' ;;
        *enabled*)                             toks='ENABLED'$'\n' ;;
        *unchanged*)                           toks='UNCHANGED'$'\n' ;;
        *choose*)                              toks='CHOOSE'$'\n' ;;
        *except*|*"function update"*)          toks='EXCEPT'$'\n' ;;
        *subset*|*powerset*)                   toks='SUBSET'$'\n' ;;
        *union*)                               toks='UNION'$'\n' ;;
        *instance*|*"refinement mapping"*)     toks='INSTANCE'$'\n' ;;
        *recursive*)                           toks='RECURSIVE'$'\n' ;;
        *cardinality*)                         toks='Cardinality'$'\n' ;;
        *"stuttering subscript"*|*subscript*)  toks=']_'$'\n' ;;
        *) : ;;
      esac
    fi

    # The per-row function this replaces printed its tokens and the caller
    # captured them through `$( )`, which strips every trailing newline.
    while [ "${toks: -1}" = $'\n' ]; do toks="${toks%$'\n'}"; done
    INV_TOKENS+=("$toks")
  done
}

# ---------------------------------------------------------------------------
# answer_code <answer.md>: the contents of every fenced code block. The
# telegraph floor reads THIS and not the whole file, because ANSWER.md's PROSE
# naturally names the operator it is explaining — "the answer is a leads-to,
# `~>`" is the explanation doing its job, and matching it would flag every
# well-written answer in the corpus.
# ---------------------------------------------------------------------------
answer_code() {
  awk '
    /^[[:space:]]*```/ { inblk = !inblk; next }
    inblk { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# caveat_text <answer.md>: the why-not-in-prompt field, tolerant about how it
# is written. Accepts a `key:` line or a markdown heading, in any case, with
# or without hyphens and with or without "the".
# ---------------------------------------------------------------------------
caveat_text() {
  awk '
    function iskey(s) {
      s = tolower(s)
      gsub(/[^a-z]/, "", s)
      return (index(s, "whynotinprompt") > 0 || index(s, "whyitisnotintheprompt") > 0)
    }
    {
      if (iskey($0)) { grabbing = 1; sub(/^[^:]*:/, ""); print; next }
      if (grabbing) {
        if ($0 ~ /^[[:space:]]*#/) { grabbing = 0; next }
        if ($0 ~ /^[[:space:]]*[A-Za-z][A-Za-z -]*:[[:space:]]/ && !iskey($0)) { grabbing = 0; next }
        print
      }
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# waivers <meta.md>: lines of the form
#     telegraph-waiver: <token> -- <reason>
# READ FROM THE ITEM'S META.md, never from ANSWER.md. META.md is where the
# item declares its constructs, and harness/completion-gate.sh reads the same
# keyword from the same file. A waiver covers one token for one item and is
# echoed on every run. One that carries no reason is itself a finding.
# ---------------------------------------------------------------------------
waivers() {
  grep -iE '^[[:space:]]*[*_ ]*telegraph-waiver[*_ ]*:' "$1" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# count_waivers <meta.md>: lines of the form
#     count-waiver: <module-stem> -- <reason>
#
# The same mechanism as the telegraph waiver above, for the same reason, and
# READ FROM THE SAME FILE. It covers one case and only one: a module whose rc
# reproduces while TLC prints no distinct count at all, so the number
# ANSWER.md records came from somewhere other than the run. drill/sets/03-ballast
# is the item that needs it. Its `BallastAnyStart` violates the invariant
# during initial-state computation, so the report arrives before any step and
# the log carries no count, and the author wrote 1 for the one state in the
# trace. That is a legitimate claim and a checker with no waiver would call it
# a mismatch.
#
# WHY A KEYWORD AND NOT AN INFERENCE FROM THE rc. Measured over 79 gate rows
# on 2026-10-14: a count is printed on rc 12 and on rc 75, and not printed on
# rc 10, 99, 150, 151 or 255. drill/state-space/05-summary-record's `G05Record`
# logs `1 distinct states found` AFTER its eval error. So a checker that
# predicted presence from the rc would be wrong on four classes out of six,
# and it would be wrong silently. The keyword makes the item say so.
# Also in bd memory a-tlc-exit-code-does-not-predict-whether.
#
# THE WAIVER EXCUSES ABSENCE AND NOTHING ELSE. A waived module whose run DOES
# print a count is still compared against the claim, so a waiver that has gone
# stale surfaces as a mismatch rather than hiding one.
# ---------------------------------------------------------------------------
count_waivers() {
  grep -iE '^[[:space:]]*[*_ ]*count-waiver[*_ ]*:' "$1" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# prompt_shows_code <prompt.md>: does the prompt carry code or a TLC trace?
#
# The trace half is the finding from the trial. A prompt that shows a trace is
# showing output of the model checker, and a LASSO trace shows exactly where
# an action was enabled and skipped, which is half the diagnosis. So it earns
# the same token scan as a prompt carrying a spec.
# ---------------------------------------------------------------------------
prompt_shows_code() {
  grep -qE '^[[:space:]]*```' "$1" && return 0
  prompt_shows_trace "$1"
}

prompt_shows_trace() {
  grep -qE '^[[:space:]]*State [0-9]+:|Back to state|<Initial predicate>|Behavior up to this point|Error: Deadlock|Stuttering' "$1"
}

prompt_shows_lasso() {
  grep -qE 'Back to state' "$1"
}

# ---------------------------------------------------------------------------
# meta_constructs <meta.md>: the constructs the item declares, one per line.
# Accepts a `Constructs:` line (comma separated) and/or a `## Constructs`
# section of bullets.
# ---------------------------------------------------------------------------
meta_constructs() {
  awk '
    function iskey(s) {
      s = tolower(s); gsub(/[^a-z]/, "", s)
      return (index(s, "construct") > 0)
    }
    /^[[:space:]]*#/ {
      insec = (iskey($0) ? 1 : 0); next
    }
    iskey($0) && $0 ~ /:/ && $0 !~ /^[[:space:]]*[-*]/ {
      sub(/^[^:]*:/, "")
      n = split($0, a, ",")
      for (i = 1; i <= n; i++) print a[i]
      next
    }
    # A BULLET IS ONE CONSTRUCT and is NOT comma-split. The real inventory
    # has rows whose names contain a comma, such as
    #   \A (universal quantifier, "forall")
    # and splitting those produces a fragment that matches the wrong row plus
    # a second fragment that matches nothing. Only the inline `Constructs:`
    # key form above is comma-separated, because there the comma is a
    # separator the author chose.
    #
    # NOTE no apostrophes in this comment. The whole awk program sits in
    # single quotes, so one would close the quote and break the script.
    insec && /^[[:space:]]*[-*][[:space:]]/ {
      sub(/^[[:space:]]*[-*][[:space:]]*/, "")
      print
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# rc_claims <answer.md> <module-stem>...: fills RC_CLAIM, keyed by stem, with
# the rc ANSWER.md records for that module, or the empty string.
#
# ONE AWK PASS PER ITEM. This used to be a chain of two to five greps plus a
# `tail` PER MODULE, which over the 32-item tree was roughly 950 greps and all
# 237 `tail` execs in bead tla-0eis.1's measurement. The awk below reads
# ANSWER.md once and answers for every module of the item at the same time.
#
# TOLERANT ON PURPOSE. Six authors are writing to a format that says
# "measured rc in ANSWER.md" and does not fix a line shape, so this reads a
# table cell, `rc=12`, `rc: 12` and `exit 12` alike. What it will NOT do is
# guess: a module with no recoverable rc is a FINDING, never a pass.
#
# WORD-BOUNDARY, not substring. A plain substring match on the stem matches
# any English word the name is a prefix of: a module called Commit.tla picked
# up the prose word "Committed" and the digit from that sentence became a
# phantom rc 1 claim. Found by the tla-pmm2 temporal author, which worked
# around it by renaming its module. A base name that is a prefix of an English
# word would have bitten every later author. The awk carries the same
# `(^|[^A-Za-z0-9_])STEM([^A-Za-z0-9_]|$)` the grep did, and the stem still
# goes in unescaped, which holds while module names stay alphanumeric.
#
# THE PRECEDENCE IS LOAD-BEARING and it is the grep chain's, unchanged. An
# `rc<digits>` hit anywhere in the module's lines wins. Failing that an
# `exit<digits>` hit. Failing that a bare pipe-delimited table cell of digits.
# Within each class the LAST hit wins, which is why lastmatch() scans a line
# to its end instead of stopping at the first match.
# ---------------------------------------------------------------------------
declare -A RC_CLAIM=()

# The awk program holds `$0`, and NOT expanding it is the whole point of the
# single quotes. shellcheck reads it as a shell variable I forgot to expand.
# shellcheck disable=SC2016
RC_CLAIM_AWK='
# lastmatch: the final non-overlapping match of pat in s, or "". This is what
# `grep -o PAT | tail -1` did. Advancing past RLENGTH rather than past RSTART
# is what keeps the matches non-overlapping the way grep -o does, and that
# matters for a row of table cells: `| 1 | 2 |` yields one match, not two.
function lastmatch(s, pat,   out) {
  out = ""
  while (match(s, pat) > 0) {
    if (RLENGTH <= 0) break
    out = substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
  }
  return out
}
BEGIN { nmod = split(mods, MOD, "\n") }
{
  # tolower() stands in for grep -i. Both rc patterns are ASCII literals, so
  # folding the whole line cannot move what they match.
  low = tolower($0)
  for (i = 1; i <= nmod; i++) {
    if (MOD[i] == "") continue
    if ($0 !~ ("(^|[^A-Za-z0-9_])" MOD[i] "([^A-Za-z0-9_]|$)")) continue
    m = lastmatch(low, "rc[^0-9A-Za-z]{0,3}[0-9]{1,3}")
    if (m != "") RCH[i] = m
    m = lastmatch(low, "exit[^0-9A-Za-z]{0,3}[0-9]{1,3}")
    if (m != "") EXH[i] = m
    m = lastmatch($0, "\\|[[:space:]]*[0-9]{1,3}[[:space:]]*\\|")
    if (m != "") CELL[i] = m
  }
}
END {
  for (i = 1; i <= nmod; i++) {
    if (MOD[i] == "") continue
    hit = (i in RCH) ? RCH[i] : ((i in EXH) ? EXH[i] : ((i in CELL) ? CELL[i] : ""))
    rc = ""
    if (hit != "" && match(hit, "[0-9]{1,3}")) rc = substr(hit, RSTART, RLENGTH)
    printf "%s\t%s\n", MOD[i], rc
  }
}'

rc_claims() {
  local ans="$1"; shift
  RC_CLAIM=()
  [ "$#" -gt 0 ] || return 0
  [ -f "$ans" ] || return 0
  local stems="" stem rc
  for stem in "$@"; do
    stems="${stems}${stem}"$'\n'
  done
  while IFS=$'\t' read -r stem rc; do
    [ -n "$stem" ] || continue
    RC_CLAIM["$stem"]="$rc"
  done < <(awk -v mods="$stems" "$RC_CLAIM_AWK" "$ans")
}

# ---------------------------------------------------------------------------
# COUNT_CLAIM_AWK / count_claims <answer.md> <stem>...
#
# The DISTINCT-STATE COUNT each module's row claims. One pass per item, the
# same shape as rc_claims above, and the same word-boundary guard. What it
# deliberately does NOT share is rc_claims' precedence.
#
# IT ANCHORS ON THE HEADER, NOT ON A DIGIT SCAN, and that is the whole design.
# rc_claims falls back to "a bare pipe-delimited cell of digits, last match
# wins" when it finds no `rc N` text. The distinct cells this reads are bare
# pipe-delimited digits sitting right beside the rc cell, so a count parser
# written on the same scan would be reading one of two adjacent numbers with
# nothing to say which. So: find the table header whose cells include one
# containing the word `distinct`, take that column's index, and read that
# column on each stem's row. Column position, never a digit scan.
#
# A HEADER IS A PIPE ROW WHOSE NEXT LINE IS THE SEPARATOR, which is what makes
# the anchor safe against data. drill/core/03-bakery-obligations:129 is a DATA
# row ending `rc 0, 78 generated, 40 distinct`, and
# drill/state-space/01-clock-never-stops:43 is a real header carrying the word
# twice, in `spec-side distinct` and `constraint distinct`. Reading any pipe
# row containing `distinct` as a header would take the first of those for a
# table that has none, and reading the last matching cell rather than the
# first would take the wrong column of the second. First cell, header rows
# only.
#
# EVERY CELL WITH NO INTEGER IN IT IS NO CLAIM. Measured over the 64-item tree
# on 2026-10-14: 23 checkable modules carry an explicit `-` or the bare word
# `parse` (drill/sets/03-ballast/ANSWER.md:86) in their distinct column, and
# that is the author saying there is no count to record. It is not a zero and
# it is not a defect. Commas are stripped first, because an author writes
# 3,531 where TLC prints 3531.
#
# LAST NON-EMPTY MATCH WINS, which is rc_claims' rule and it had to be checked
# rather than assumed. An item may carry several tables with a distinct column
# over the same stems: drill/modules/01-two-tanks-one-hose has a config-keyed
# one at :192 and the `## Gate rows` one at :207. A sweep over all 64 items
# found 3 stems hit in two tables and all 3 agreed, so no precedence rule is
# load-bearing on today's corpus. If one ever is, the later table is the one
# written for this gate.
#
# An escaped `\|` inside a cell is a real markdown spelling and it appears at
# drill/control-state/08-wrong-label/ANSWER.md:72. Splitting on it would shift
# every later column by one, so it is parked under \001 and restored. That
# table has no distinct column today, which is luck rather than a guarantee.
# ---------------------------------------------------------------------------
declare -A COUNT_CLAIM=()

# The awk program holds `$0`, and NOT expanding it is the whole point of the
# single quotes, exactly as in RC_CLAIM_AWK above.
# shellcheck disable=SC2016
COUNT_CLAIM_AWK='
# firstint: the first run of digits in s, with commas squeezed out first, or
# "". An empty return is NO CLAIM and the caller must not read it as a zero.
function firstint(s,   out) {
  gsub(/,/, "", s)
  out = ""
  if (match(s, /[0-9]+/)) out = substr(s, RSTART, RLENGTH)
  return out
}
# issep: a markdown table separator row. The hyphen test is what keeps a row
# of empty cells, `| | | |`, from being read as one.
function issep(s) {
  return (s ~ /^[[:space:]]*\|[-:|[:space:]]*$/ && s ~ /-/)
}
# cells: split a pipe row, parking the escaped \| spelling first. A row
# `| a | b |` yields A[1] empty, A[2] "a", A[3] "b", A[4] empty — so table
# column N is A[N+1], and the dcol this program carries is already an A index.
function cells(s, A,   n, i) {
  gsub(/\\\|/, "\001", s)
  n = split(s, A, "|")
  for (i = 1; i <= n; i++) gsub(/\001/, "|", A[i])
  return n
}
BEGIN { nmod = split(mods, MOD, "\n") }
{
  if (issep($0) && prevpipe) {
    nh = cells(prev, H)
    dcol = 0
    for (i = 1; i <= nh; i++) {
      h = tolower(H[i]); gsub(/[^a-z]/, "", h)
      if (index(h, "distinct") > 0) { dcol = i; break }
    }
    intable = 1
    prev = $0; prevpipe = 0
    next
  }
  if ($0 ~ /^[[:space:]]*\|/) {
    if (intable && dcol > 0) {
      nc = cells($0, C)
      if (nc >= dcol) {
        for (i = 1; i <= nmod; i++) {
          if (MOD[i] == "") continue
          if ($0 !~ ("(^|[^A-Za-z0-9_])" MOD[i] "([^A-Za-z0-9_]|$)")) continue
          v = firstint(C[dcol])
          if (v != "") CNT[i] = v
        }
      }
    }
    prev = $0; prevpipe = 1
    next
  }
  intable = 0; dcol = 0
  prev = $0; prevpipe = 0
}
END {
  for (i = 1; i <= nmod; i++) {
    if (MOD[i] == "") continue
    if (i in CNT) printf "%s\t%s\n", MOD[i], CNT[i]
  }
}'

count_claims() {
  local ans="$1"; shift
  COUNT_CLAIM=()
  [ "$#" -gt 0 ] || return 0
  [ -f "$ans" ] || return 0
  local stems="" stem cnt
  for stem in "$@"; do
    stems="${stems}${stem}"$'\n'
  done
  while IFS=$'\t' read -r stem cnt; do
    [ -n "$stem" ] || continue
    COUNT_CLAIM["$stem"]="$cnt"
  done < <(awk -v mods="$stems" "$COUNT_CLAIM_AWK" "$ans")
}

# verdict.sh's table. A recorded rc outside it is a mis-transcription.
rc_in_table() {
  case "$1" in
    0|10|11|12|13|14|75|76|77|99|124|150|151|255) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# VERIFY_ROW_AWK / verify_rows <meta.md>
#
# The (module, rc, distinct) triples of an item's `## Verify` table, one per
# line, tab separated. A distinct cell with no integer in it comes back as
# `-`, which is NO COUNT and never a zero.
#
# IT READS META.md AND NOT ANSWER.md, which departs from check 2 on purpose.
# The rubric lives in META.md, so the envelope and the counts it is tested
# against sit in the same file and cannot drift apart unseen. Both files carry
# the same table across the sets family today, and one file is one edit.
#
# A HEADER IS A PIPE ROW WHOSE NEXT LINE IS THE SEPARATOR. That is
# COUNT_CLAIM_AWK's discriminator and the reason it exists: a header can carry
# a column word twice, and a DATA row can contain the header word. bd memory
# `an-answer-md-markdown-table-is-not` names where each shape was measured. An
# escaped `\|` is parked under \001 and restored, because splitting on it
# shifts every later column by one.
#
# SCOPED TO THE `## Verify` SECTION rather than to the whole file. A second
# table carrying both an rc and a distinct column would otherwise pour its
# rows into the same set, and the envelope would then be tested against rows
# the item never meant as machines.
#
# THE rc COLUMN IS MATCHED EXACTLY and the distinct column by containment. In
# META.md the header reads `| file | rc | distinct states |`, so `rc` is a
# whole cell while the count column's word sits inside a phrase.
# ---------------------------------------------------------------------------

# The awk program holds `$0`, and NOT expanding it is the whole point of the
# single quotes, exactly as in COUNT_CLAIM_AWK above.
# shellcheck disable=SC2016
VERIFY_ROW_AWK='
function firstint(s,   out) {
  gsub(/,/, "", s)
  out = ""
  if (match(s, /[0-9]+/)) out = substr(s, RSTART, RLENGTH)
  return out
}
function issep(s) {
  return (s ~ /^[[:space:]]*\|[-:|[:space:]]*$/ && s ~ /-/)
}
function cells(s, A,   n, i) {
  gsub(/\\\|/, "\001", s)
  n = split(s, A, "|")
  for (i = 1; i <= n; i++) gsub(/\001/, "|", A[i])
  return n
}
/^##/ {
  insec = ($0 ~ /^##+[[:space:]]*Verify([[:space:]]|$)/)
  intable = 0; rccol = 0; dcol = 0
  prev = $0; prevpipe = 0
  next
}
{
  if (!insec) { prev = $0; prevpipe = 0; next }
  if (issep($0) && prevpipe) {
    nh = cells(prev, H)
    rccol = 0; dcol = 0
    for (i = 1; i <= nh; i++) {
      h = tolower(H[i]); gsub(/[^a-z]/, "", h)
      if (h == "rc" && rccol == 0) rccol = i
      if (index(h, "distinct") > 0 && dcol == 0) dcol = i
    }
    intable = (rccol > 0 && dcol > 0)
    prev = $0; prevpipe = 0
    next
  }
  if ($0 ~ /^[[:space:]]*\|/) {
    if (intable) {
      nc = cells($0, C)
      if (nc >= rccol && nc >= dcol) {
        rc = firstint(C[rccol])
        dv = firstint(C[dcol])
        name = C[2]
        gsub(/[^A-Za-z0-9_\/.-]/, "", name)
        if (name == "") name = "-"
        if (rc != "") printf "%s\t%s\t%s\n", name, rc, (dv == "" ? "-" : dv)
      }
    }
    prev = $0; prevpipe = 1
    next
  }
  intable = 0; rccol = 0; dcol = 0
  prev = $0; prevpipe = 0
}'

verify_rows() {
  [ -f "$1" ] || return 0
  awk "$VERIFY_ROW_AWK" "$1"
}

# ---------------------------------------------------------------------------
# rubric_read <meta.md>: the item's `## Rubric` fields, into globals.
#
# RB_PRESENT is the scope gate and it is the field that matters most. An item
# with no `## Rubric` heading is OUT OF SCOPE for check 4, not a failure. 8 of
# the 64 items carry one today, so a check that read absence as a defect would
# redden on 56 items this work does not touch.
#
# RB_EXTRA collects any `- key: value` line whose key is none of the four. An
# unknown key is a finding rather than silence, because the way a field gets
# misspelled is the way it stops being read, and a rubric that silently drops
# half of itself still prints green.
#
# The two `-because` keys and the `### Faults you should catch` list are owed
# by bead tla-sqym.3. They are WITHHELD from the prompt, so they are known
# keys here and are not reported as extras.
# ---------------------------------------------------------------------------
RB_PRESENT=0
RB_RUNS=""
RB_FAULT=""
RB_STATES=""
RB_OBL=""
RB_EXTRA=""
rubric_read() {
  RB_PRESENT=0
  RB_RUNS=""
  RB_FAULT=""
  RB_STATES=""
  RB_OBL=""
  RB_EXTRA=""
  [ -f "$1" ] || return 0
  local line insec=0 key val
  while IFS= read -r line; do
    case "$line" in
      '##'*)
        case "$line" in
          '## Rubric' | '## Rubric '*) insec=1; RB_PRESENT=1 ;;
          *) insec=0 ;;
        esac
        continue
        ;;
    esac
    [ "$insec" = "1" ] || continue
    case "$line" in
      '- '*:*) : ;;
      *) continue ;;
    esac
    key="${line#- }"
    key="${key%%:*}"
    val="${line#*:}"
    while [ "${val# }" != "$val" ]; do val="${val# }"; done
    while [ "${val% }" != "$val" ]; do val="${val% }"; done
    case "$key" in
      runs) RB_RUNS="$val" ;;
      fault) RB_FAULT="$val" ;;
      states) RB_STATES="$val" ;;
      obligations) RB_OBL="$val" ;;
      states-floor-because | states-ceiling-because) : ;;
      *) RB_EXTRA="${RB_EXTRA:+${RB_EXTRA}, }${key}" ;;
    esac
  done <"$1"
  return 0
}

# ---------------------------------------------------------------------------
# rc_fault_class <rc>: which of the rubric's `fault` values this rc reports.
#
# 12 AND 13 SPLIT ON THE SHAPE OF THE FORMULA AND NOT ON THE .cfg KEYWORD,
# which check 2's header states and verdict.sh:81-91 implements. `[](P => []P)`
# is safety written with temporal operators and exits 12. So `fault: invariant`
# is the right declaration for an item whose requirement is safety however it
# is spelled, and an author reasoning from the keyword will write `property`
# and be wrong.
#
# EVERYTHING ELSE IS `error`, which is the `runs` dimension's territory rather
# than the fault dimension's. 75, 76 and 77 mean the check never happened, so
# nothing at all is known about whether the obligation holds.
# ---------------------------------------------------------------------------
rc_fault_class() {
  case "$1" in
    0) printf 'none' ;;
    11) printf 'deadlock' ;;
    12) printf 'invariant' ;;
    13) printf 'property' ;;
    *) printf 'error' ;;
  esac
}

# rubric_conformant_class <runs> <fault>: the class a run that MEETS the
# rubric would land in. `runs: no` collapses to `error`, because an item that
# expects TLC not to get off the ground has no fault to name.
rubric_conformant_class() {
  if [ "$1" = "no" ]; then
    printf 'error'
    return 0
  fi
  printf '%s' "$2"
}

# ---------------------------------------------------------------------------
# Per-construct state, parallel to the INV_* arrays.
#
# INV_TOKENS is computed ONCE per construct rather than once per
# (item, construct) pair. With 105 real rows and dozens of items that is the
# difference between a few hundred forks and a few thousand.
#
# INV_SEEN holds the item ids already counted for a construct, seeded from
# the inventory's own field 8, so the count is a count of DISTINCT items
# whichever source named them.
# ---------------------------------------------------------------------------
declare -a INV_COUNT=() INV_TOKENS=() INV_SEEN=()
build_inv_tokens
for ((_i = 0; _i < ${#INV_NORM[@]}; _i++)); do
  # Squeeze runs of spaces, then drop one leading and one trailing space,
  # which is what `tr -s ' '` into a two-expression `sed` did.
  _seed="${INV_ITEMS[$_i]}"
  while [[ "$_seed" == *"  "* ]]; do _seed="${_seed//  / }"; done
  _seed="${_seed# }"
  _seed="${_seed% }"
  INV_SEEN+=("$_seed")
  if [ -z "$_seed" ]; then
    INV_COUNT+=(0)
  else
    read -r -a _words <<<"$_seed"
    INV_COUNT+=("${#_words[@]}")
  fi
done
unset _i _seed _words

# inv_index <normalized-construct> -> echoes index, or fails.
#
# Exact match first. Then CONTAINMENT, in both directions, because the real
# inventory's construct names are prose from a cheat sheet and an author
# typing "operator definitions" for the row "Operator definition" has not
# made a mistake worth a finding. A containment hit is reported as such in
# the run's MATCH lines, so the looser match is visible rather than silent.
# It echoes "<index> <mode>" rather than setting a global. A caller reads it
# through `$( )`, which is a SUBSHELL, so a global assigned in here would
# never reach the caller — the first version did that and reported all 105
# real constructs as containment matches when every one of them was exact.
inv_index() {
  local want="$1" i
  for ((i = 0; i < ${#INV_NORM[@]}; i++)); do
    if [ "${INV_NORM[$i]}" = "$want" ]; then
      printf '%s exact' "$i"
      return 0
    fi
  done
  for ((i = 0; i < ${#INV_NORM[@]}; i++)); do
    case "${INV_NORM[$i]}" in
      *"$want"*) printf '%s contains' "$i"; return 0 ;;
    esac
    case "$want" in
      *"${INV_NORM[$i]}"*) printf '%s contains' "$i"; return 0 ;;
    esac
  done
  return 1
}

# ===========================================================================
# THE SWEEP
# ===========================================================================
MODE_TAG=""
[ "$NO_TLC" = "1" ] && MODE_TAG="${MODE_TAG} (--no-tlc)"
[ "$STATIC_ONLY" = "1" ] && MODE_TAG="${MODE_TAG} (--static-only)"
[ "$CHANGED_ONLY" = "1" ] && MODE_TAG="${MODE_TAG} (--changed-only)"
[ "$JOBS" = "1" ] || MODE_TAG="${MODE_TAG} (-P${JOBS})"
echo "drill-gate.sh: root=${ROOT} inventory=${INVENTORY}${MODE_TAG}"
echo

# --- the cache base, computed ONCE per run ---------------------------------
#
# The jar is 4.5 MB and hashing it costs 6 ms, so it is hashed once here and
# never per job. Same for verdict.sh. Neither is touched unless the caller
# asked for the cache.
#
# A WRAPPER THIS GATE CANNOT READ IS DECLARED, NOT UNCHECKED, and the whole of
# bead tla-dnwi's second defect is in that one word. UNCHECKED escalates to rc
# 99, CHECK_DID_NOT_RUN, which says the caller asked for a check and got
# nothing. On a run that cannot resolve the jar, every job still runs and
# every recorded rc is still reproduced. The one thing lost is the cache, and
# the cache is an optimization rather than a check, so there is no check here
# to have skipped. DECLARED prints the reason, counts, and lets the run's own
# findings pick the exit code.
if [ "$CACHE_ACTIVE" = "1" ]; then
  if ! resolve_jar; then
    declared "verify-cache" "tlc" \
      "the pinned tlc wrapper names no readable jar, so a key would be computed against an unknown build. Every job ran and nothing was cached, which is a cache this gate declined rather than a check it skipped."
  else
    jar_sha=""
    verdict_sha=""
    sha_of_file "$JAR_PATH" && jar_sha="$SHA"
    sha_of_file "$VERDICT" && verdict_sha="$SHA"
    if [ -z "$jar_sha" ] || [ -z "$verdict_sha" ]; then
      unchecked "verify-cache" "tlc" \
        "cannot hash ${JAR_PATH} or ${VERDICT}; every job will run and nothing will be cached"
    else
      CACHE_BASE="${jar_sha}|${verdict_sha}"
    fi
  fi

  # The state file is one line per verified job: the key, a space, then the
  # job's identity as `<rel>|<modbase>`. The identity is what makes "stale"
  # mean something: a job whose identity is in the file under a DIFFERENT key
  # was verified before and its inputs have since changed.
  #
  # The key is read with a plain `read -r k id`, so the identity takes the
  # whole rest of the line and a path with a space in it still round-trips.
  if [ -f "$STATE_FILE" ]; then
    STATE_PRESENT=1
    while read -r _k _id; do
      [ -n "$_k" ] || continue
      STATE_KEY["$_k"]=1
      [ -z "$_id" ] || STATE_ID["$_id"]="$_k"
    done <"$STATE_FILE"
    unset _k _id
  fi
fi

if [ "$INV_OK" = "1" ]; then
  say "inventory: ${#INV_NORM[@]} construct(s) parsed from ${INVENTORY} (${INV_SHAPE})"
else
  unchecked "coverage" "$INVENTORY" "no parseable construct table; check 3 cannot run"
  cat <<'SHAPE'
          The shape expected, a markdown table with a locatable header:

            | construct | family | expected frequency |
            |---|---|---|
            | `~>` leads-to | liveness | high |

          Column order is not assumed. The header is found by looking for
          `construct`, `family` and `freq` in its cells.
SHAPE
fi

# Items live at <root>/<family>/<NN>-<slug>/.
#
# THE HIDDEN-DIR PREDICATE IS ANCHORED AT $ROOT ON PURPOSE. The obvious
# `-not -path '*/.*'` matches the ROOT PATH ITSELF whenever any ancestor
# directory starts with a dot, and every dispatched worker in this project
# runs under .claude/worktrees/agent-*. So that form found ZERO items on the
# real tree while passing over fixtures in /tmp, which is a false PASS on the
# whole sweep: an empty item list reports "nothing to guarantee" rather than
# checking anything. Anchoring at $ROOT excludes a hidden family or item and
# nothing else.
declare -a ITEMS=()
while IFS= read -r d; do
  [ -n "$d" ] || continue
  ITEMS+=("$d")
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "${ROOT}/.*" | sort)

if [ "${#ITEMS[@]}" -eq 0 ]; then
  unchecked "corpus" "$ROOT" "no items found at <root>/<family>/<NN>-<slug>/; nothing to guarantee"
fi

for item in "${ITEMS[@]+"${ITEMS[@]}"}"; do
  rel="${item#"$ROOT"/}"
  # `${x##*/}` rather than basename. find never emits a trailing slash, so the
  # two agree on every path that reaches here, and basename was 303 execs.
  base="${item##*/}"
  item_n=$((item_n + 1))

  # --- shape -------------------------------------------------------------
  case "$base" in
    [0-9][0-9]-*) : ;;
    *) finding "ITEM-BAD-NAME" "$rel" "directory is not <NN>-<slug>; an item the gate cannot address is unguaranteed" ;;
  esac

  prompt="${item}/PROMPT.md"
  answer="${item}/ANSWER.md"
  meta="${item}/META.md"
  verify="${item}/verify"

  missing=0
  for f in PROMPT.md ANSWER.md META.md; do
    if [ ! -f "${item}/${f}" ]; then
      finding "ITEM-MISSING-FILE" "$rel" "no ${f}"
      missing=1
    fi
  done
  if [ ! -d "$verify" ]; then
    finding "ITEM-MISSING-FILE" "$rel" "no verify/ directory"
    missing=1
  fi
  [ "$missing" = "0" ] || continue

  # PROMPT.md read ONCE, because both telegraph layers ask the same question
  # of it over and over: does this token appear anywhere in the prompt? That
  # was a `grep -qF` per token, 297 of them over the 32-item tree, and a
  # substring test against the file's text answers it without a fork. A token
  # never holds a newline, so it cannot straddle two lines, which is the only
  # way the line-oriented grep and a whole-file test could disagree.
  prompt_text="$(<"$prompt")"

  # =======================================================================
  # CHECK 1 — TELEGRAPH
  # =======================================================================

  # Waivers first, so layers A and B can honour them. Echoed unconditionally.
  declare -a WAIVED=()
  wv="$(waivers "$meta")"
  if [ -n "$wv" ]; then
    while IFS= read -r wline; do
      [ -n "$wline" ] || continue
      wbody="${wline#*:}"
      wtok="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*\(--\|—\).*$//' -e 's/[[:space:]]*$//' <<<"$wbody")"
      wreason="$(sed -n 's/.*\(--\|—\)[[:space:]]*//p' <<<"$wbody")"
      if [ -z "$wtok" ]; then
        finding "TELEGRAPH-WAIVER-EMPTY" "$rel" "telegraph-waiver names no token"
        continue
      fi
      if [ "${#wreason}" -lt 12 ]; then
        finding "TELEGRAPH-WAIVER-NO-REASON" "$rel" "waiver for '${wtok}' carries no reason; a waiver without one is an exemption"
        continue
      fi
      WAIVED+=("$wtok")
      printf 'WAIVER    %-44s %-10s %s\n' "$rel" "$wtok" "$wreason"
    done <<<"$wv"
  fi

  is_waived() {
    local t="$1" w
    for w in "${WAIVED[@]+"${WAIVED[@]}"}"; do
      [ "$w" = "$t" ] && return 0
    done
    return 1
  }

  # --- the why-not-in-prompt field ---------------------------------------
  cav="$(caveat_text "$answer")"
  cav_squeezed="${cav//[[:space:]]/}"
  if [ "${#cav_squeezed}" -lt 20 ]; then
    finding "TELEGRAPH-NO-CAVEAT" "$rel" \
      "ANSWER.md has no why-not-in-prompt field with real content (${#cav_squeezed} non-space chars, 20 required)"
  fi

  # --- the trace clause --------------------------------------------------
  if prompt_shows_trace "$prompt"; then
    kind="trace"
    prompt_shows_lasso "$prompt" && kind="lasso trace"
    if ! grep -qi 'trace' <<<"$cav"; then
      finding "TELEGRAPH-TRACE-UNCAVEATED" "$rel" \
        "PROMPT.md carries a ${kind} and why-not-in-prompt never mentions it; a lasso trace is itself a partial answer"
    fi
  fi

  # --- layer A: the declared constructs ----------------------------------
  declare -a DECLARED=()
  mc="$(meta_constructs "$meta")"
  if [ -n "$mc" ]; then
    while IFS= read -r c; do
      normalize "$c"
      cn="$NORM"
      [ -n "$cn" ] || continue
      DECLARED+=("$cn")
    done <<<"$mc"
  fi

  # NOT a coverage failure. See the note at the end of CHECK 3's header: a
  # missing declaration leaves layer A with no token to compare, so the
  # TELEGRAPH check reports that it could not run. The corpus-level count is
  # never what reddens this gate.
  if [ "${#DECLARED[@]}" -eq 0 ]; then
    unchecked "telegraph-declared" "$rel" \
      "META.md declares no constructs; layer A has no token to compare against"
  fi

  for cn in "${DECLARED[@]+"${DECLARED[@]}"}"; do
    if [ "$INV_OK" != "1" ]; then
      continue
    fi
    if ! hit="$(inv_index "$cn")"; then
      unchecked "telegraph-declared" "$rel" \
        "META.md declares '${cn}', which INVENTORY.md does not list, so no token resolves"
      continue
    fi
    idx="${hit% *}"
    mode="${hit##* }"
    [ "$mode" = "exact" ] || \
      printf 'MATCH     %-44s %s\n' "$rel" "declared '${cn}' matched row '${INV_RAW[$idx]}' by containment, not exactly"

    # Count DISTINCT items. INV_SEEN is seeded from the inventory's field 8,
    # so an item already named there is not counted twice.
    case " ${INV_SEEN[$idx]} " in
      *" ${base} "*) : ;;
      *)
        INV_SEEN[idx]="${INV_SEEN[$idx]} ${base}"
        INV_COUNT[idx]=$(( INV_COUNT[idx] + 1 ))
        ;;
    esac

    toks="${INV_TOKENS[$idx]}"
    if [ -z "$toks" ]; then
      # NOT an unchecked check. A construct whose inventory cell carries no
      # symbol — "Operator definition", "Integers" — has no token a prompt
      # could leak, so layer A does not apply to it rather than failing to
      # run. Layer B still covers the item. The run prints how many
      # constructs sit outside layer A's reach, so the boundary is visible
      # instead of silent.
      LAYERA_NOTOK=$(( LAYERA_NOTOK + 1 ))
      continue
    fi
    LAYERA_COVERED=$(( LAYERA_COVERED + 1 ))
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      is_waived "$tok" && continue
      if [[ "$prompt_text" == *"$tok"* ]]; then
        finding "TELEGRAPH-DECLARED" "$rel" \
          "PROMPT.md shows '${tok}', the token of the declared construct '${INV_RAW[$idx]}'"
      fi
    done <<<"$toks"
  done

  # --- layer B: the floor over the answer's own code ---------------------
  code="$(answer_code "$answer")"
  if [ -z "${code//[[:space:]]/}" ]; then
    unchecked "telegraph-floor" "$rel" \
      "ANSWER.md has no fenced code block; the floor has no answer tokens to compare against"
  elif prompt_shows_code "$prompt"; then
    for tok in "${DISTINCTIVE[@]}"; do
      is_waived "$tok" && continue
      [[ "$code" == *"$tok"* ]] || continue
      if [[ "$prompt_text" == *"$tok"* ]]; then
        finding "TELEGRAPH-FLOOR" "$rel" \
          "ANSWER.md's code uses '${tok}' and PROMPT.md shows it too"
      fi
    done
  fi

  # =======================================================================
  # CHECK 2 — VERIFICATION
  # =======================================================================
  declare -a MODS=()
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    MODS+=("$m")
  done < <(find "$verify" -maxdepth 1 -type f -name '*.tla' | sort)

  if [ "${#MODS[@]}" -eq 0 ]; then
    finding "VERIFY-NO-MODULES" "$rel" "verify/ holds no .tla module"
  fi

  # Every recorded rc for this item, read out of ANSWER.md ONCE, before the
  # per-module loop that consumes them.
  declare -a STEMS=()
  for m in "${MODS[@]+"${MODS[@]}"}"; do
    m="${m##*/}"
    STEMS+=("${m%.tla}")
  done
  rc_claims "$answer" "${STEMS[@]+"${STEMS[@]}"}"
  count_claims "$answer" "${STEMS[@]+"${STEMS[@]}"}"

  # --- the count waivers, parsed and ECHOED in every tier ----------------
  #
  # THIS IS THE STRUCTURAL HALF of the count check, and it sits here rather
  # than beside the comparison because it needs no TLC. Whether a waiver names
  # a module of this item, and whether it carries a reason, are properties of
  # two files. So --static-only and --no-tlc check them and the unflagged run
  # checks them again, which is the same split check 2 already has between its
  # structural arm and its queue.
  declare -a COUNT_WAIVED=()
  cwv="$(count_waivers "$meta")"
  if [ -n "$cwv" ]; then
    while IFS= read -r cwline; do
      [ -n "$cwline" ] || continue
      cwbody="${cwline#*:}"
      cwtok="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*\(--\|—\).*$//' -e 's/[[:space:]]*$//' <<<"$cwbody")"
      cwreason="$(sed -n 's/.*\(--\|—\)[[:space:]]*//p' <<<"$cwbody")"
      if [ -z "$cwtok" ]; then
        finding "COUNT-WAIVER-EMPTY" "$rel" "count-waiver names no module"
        continue
      fi
      if [ "${#cwreason}" -lt 12 ]; then
        finding "COUNT-WAIVER-NO-REASON" "$rel" \
          "count-waiver for '${cwtok}' carries no reason; a waiver without one is an exemption"
        continue
      fi
      # A WAIVER FOR A MODULE THAT IS NOT THERE IS NOT HARMLESS. It reads as
      # cover and it covers nothing, and the way it arrives is a module being
      # renamed while the waiver keeps the old name. The telegraph waiver has
      # no analogue of this check because its tokens come from an inventory
      # the gate cannot close over; a module stem is a filename this gate has
      # already listed, so there is no excuse for not resolving it.
      cwknown=0
      for s in "${STEMS[@]+"${STEMS[@]}"}"; do
        [ "$s" = "$cwtok" ] && cwknown=1
      done
      if [ "$cwknown" = "0" ]; then
        finding "COUNT-WAIVER-UNKNOWN-MODULE" "$rel" \
          "count-waiver names '${cwtok}', which is not a module of this item's verify/"
        continue
      fi
      COUNT_WAIVED+=("$cwtok")
      # A WIDER TOKEN COLUMN THAN THE TELEGRAPH WAIVER'S %-10s, because what
      # goes in it is `count:` plus a module stem rather than an operator.
      # `count:NegativeInConfig` is 22 characters and ran straight into its
      # reason at the narrower width.
      printf 'WAIVER    %-44s %-26s %s\n' "$rel" "count:${cwtok}" "$cwreason"
    done <<<"$cwv"
  fi

  count_is_waived() {
    local t="$1" w
    for w in "${COUNT_WAIVED[@]+"${COUNT_WAIVED[@]}"}"; do
      [ "$w" = "$t" ] && return 0
    done
    return 1
  }

  # ONE DIGEST PER ITEM, not one per module. Every module of an item shares
  # the same verify/ tree, so hashing it per module would multiply the cost by
  # the module count — and temporal/05-flaky-link carries 27 of them.
  item_tree=""
  if [ "$CACHE_ACTIVE" = "1" ] && [ -n "$CACHE_BASE" ] && [ "${#MODS[@]}" -gt 0 ]; then
    verify_tree_digest "$verify" && item_tree="$TREE_DIGEST"
  fi

  saw_pass=0
  saw_refutation=0
  checkable=0

  for mod in "${MODS[@]+"${MODS[@]}"}"; do
    modbase="${mod##*/}"
    modstem="${modbase%.tla}"
    cfg="${verify}/${modstem}.cfg"
    want="${RC_CLAIM[$modstem]-}"
    wantc="${COUNT_CLAIM[$modstem]-}"
    cwaive=0
    count_is_waived "$modstem" && cwaive=1

    if [ ! -f "$cfg" ]; then
      # Exactly one .cfg in verify/ is taken as this module's config only
      # when there is also exactly one module; otherwise guessing would
      # silently check the wrong pair.
      ncfg="$(find "$verify" -maxdepth 1 -type f -name '*.cfg' | wc -l)"
      if [ "$ncfg" = "1" ] && [ "${#MODS[@]}" = "1" ]; then
        cfg="$(find "$verify" -maxdepth 1 -type f -name '*.cfg')"
      elif [ -z "$want" ]; then
        say "  SKIP  ${rel}  ${modbase}: no .cfg and no recorded rc — read as an EXTENDS helper"
        continue
      else
        finding "VERIFY-NO-CFG" "$rel" "${modbase} records rc ${want} but has no ${modstem}.cfg"
        continue
      fi
    fi

    if [ -z "$want" ]; then
      finding "VERIFY-NO-RC" "$rel" \
        "${modbase} has a .cfg but ANSWER.md records no rc for it; an unrecorded rc is unverifiable"
      continue
    fi
    if ! rc_in_table "$want"; then
      finding "VERIFY-RC-NOT-IN-TABLE" "$rel" \
        "${modbase} records rc ${want}, which is not a row of verdict.sh's table (likely a shell exit mis-transcribed)"
      continue
    fi

    checkable=$((checkable + 1))
    [ "$want" = "0" ] && saw_pass=1
    [ "$want" = "0" ] || saw_refutation=1

    # THE CLAIM IS TALLIED HERE, ABOVE EVERY TIER BRANCH, so the number the
    # closing line reports is the same in all four modes. What varies by tier
    # is how many of those claims were COMPARED, and that is the second
    # number. A claim count that moved with the flag would make the coverage
    # line unreadable against yesterday's run.
    [ -n "$wantc" ] && count_claim_n=$((count_claim_n + 1))
    [ "$cwaive" = "1" ] && count_waived_n=$((count_waived_n + 1))

    if [ "$NO_TLC" = "1" ]; then
      unchecked "verify-rc" "$rel" "${modbase}: --no-tlc, recorded rc ${want} not reproduced"
      continue
    fi

    # --static-only STOPS HERE, AND EMITS NOTHING. The recorded rc reached a
    # structural check and passed it; reproducing it was never asked for, so
    # there is no UNCHECKED line to carry and nothing to escalate. The count
    # is reported in one block at the end of the run, which is the whole
    # difference between this mode and a gate that exits 0 quietly.
    if [ "$STATIC_ONLY" = "1" ]; then
      static_n=$((static_n + 1))
      continue
    fi

    # A RECORDED rc 99 IS NOT A MODULE PROPERTY, so this gate cannot verify it.
    # 99 is CHECK_DID_NOT_RUN (bead tla-hl96): it means the caller asked for a
    # check its configuration did not permit, so it is a fact about an
    # INVOCATION rather than about a module. This gate runs every module under
    # ONE convention, and since the deadlock fix below it always agrees with
    # the .cfg, so it can never produce the disagreement a 99 reports.
    #
    # state-space/04-clean-run-colleague-deadlock is the item that needs this:
    # its six-cell table demonstrates the deadlock AND across the keyword and
    # the flag, and the 99 cell is the one where caller and .cfg disagree.
    # The item is right and the gate is right, so the gate says it cannot see
    # this one rather than calling a correct item a mismatch. The item carries
    # its own measurement for that cell.
    #
    # THIS CHECK USED TO SIT AFTER THE RUN, which ran TLC and then threw the
    # result away: the comparison below was never reached. Asking the question
    # before the enqueue produces identical output and saves one JVM start per
    # recorded 99. It stays BELOW the --no-tlc branch above, because under
    # --no-tlc the rc is unreproduced like every other and reporting it as
    # DECLARED instead would change that mode's output.
    if [ "$want" = "99" ]; then
      declared "verify-rc" "$rel" \
        "${modbase} records rc 99, CHECK_DID_NOT_RUN, which is a claim about an invocation rather than about the module. This gate uses one convention and cannot reproduce a refusal it never triggers."
      continue
    fi

    # TLC's deadlock checking is an AND across the .cfg's CHECK_DEADLOCK
    # keyword and verdict.sh's -d flag, and verdict.sh defaults -d OFF
    # (harness/verdict.sh:25, :189-195). So an item whose cfg says
    # CHECK_DEADLOCK TRUE and whose recorded rc is 11 cannot reproduce here
    # unless the gate asks for the check too: verdict.sh refuses the
    # disagreement at rc 99, CHECK_DID_NOT_RUN.
    #
    # That refusal is correct and it is how this bug was found, within an hour
    # of the gate landing: four control-state items recorded rc 11 and the
    # gate reported VERIFY-RC-MISMATCH ... TLC returned 99 rather than a
    # silent 0. Pass -d when the cfg asks for it, and never strip the keyword
    # from an item to make this green -- the keyword is the item's own
    # statement that its terminal state is the subject. Bead tla-eafx reserved
    # rc 99 for exactly this, and tla-pmm2's control-state author kept its
    # keywords on purpose.
    deadlock_flag=0
    if grep -qE '^[[:space:]]*CHECK_DEADLOCK[[:space:]]+TRUE' "$cfg"; then
      deadlock_flag=1
    fi

    # THE CLAIMED COUNT AND ITS WAIVER ARE IN THE KEY, and leaving either out
    # is the one way --changed-only could still report a stale verdict. An
    # author who edits nothing but the distinct cell changes what this gate
    # asserts and no other input to the hash moves: not the module bytes, not
    # the cfg, not the rc. A cached pass would then be served for a claim that
    # had never been compared, which is precisely the silent drift the count
    # half of check 2 exists to stop.
    job_key="-"
    if [ -n "$item_tree" ]; then
      sha_of_string "${CACHE_BASE}|${rel}|${modbase}|${want}|${wantc}|${cwaive}|${deadlock_flag}|${TIMEOUT}|${item_tree}"
      job_key="$SHA"
    fi

    # F[7] and F[8] are APPENDED rather than inserted. The runner reads F[5]
    # and F[3] by index and the outcome loop reads F[0], F[1], F[4] and F[6],
    # so renumbering to put the count beside the rc would be a change to five
    # call sites for a tidier file.
    enqueue_job "$rel" "$modbase" "$mod" "$cfg" "$want" "$deadlock_flag" "$job_key" "$wantc" "$cwaive"
  done

  if [ "$checkable" -gt 0 ]; then
    [ "$saw_pass" = "1" ] || finding "VERIFY-NO-PASS" "$rel" \
      "no verify module records rc 0; the stated answer was never shown to check"
    [ "$saw_refutation" = "1" ] || finding "VERIFY-NO-REFUTATION" "$rel" \
      "every recorded rc is 0; no stated wrong answer was shown to fail"
  elif [ "${#MODS[@]}" -gt 0 ]; then
    finding "VERIFY-NOTHING-CHECKABLE" "$rel" \
      "verify/ holds ${#MODS[@]} module(s) and not one is checkable (a .cfg plus a recorded rc)"
  fi

  # =======================================================================
  # CHECK 4 — RUBRIC
  #
  # LAST IN THE LOOP because it reads COUNT_WAIVED, which check 2 builds. The
  # unset below drops it, so moving this block above check 2 would leave the
  # waiver honored nowhere and silently tighten the envelope on one row of
  # drill/sets/03-ballast.
  #
  # NO TLC HERE, so this check runs in every tier including --static-only. The
  # whole of it is a comparison between two sections of one file.
  # =======================================================================
  rubric_read "$meta"
  if [ "$RB_PRESENT" = "1" ]; then
    rubric_item_n=$((rubric_item_n + 1))
    rb_wellformed=1

    if [ -z "$RB_RUNS" ]; then
      finding "RUBRIC-FIELD-MISSING" "$rel" "## Rubric carries no 'runs:' line"
      rb_wellformed=0
    elif [ "$RB_RUNS" != "yes" ] && [ "$RB_RUNS" != "no" ]; then
      finding "RUBRIC-FIELD-BAD" "$rel" "runs: '${RB_RUNS}' is not yes or no"
      rb_wellformed=0
    fi

    if [ -z "$RB_FAULT" ]; then
      finding "RUBRIC-FIELD-MISSING" "$rel" "## Rubric carries no 'fault:' line"
      rb_wellformed=0
    else
      case "$RB_FAULT" in
        none | invariant | property | deadlock) : ;;
        *)
          finding "RUBRIC-FIELD-BAD" "$rel" \
            "fault: '${RB_FAULT}' is not none, invariant, property or deadlock"
          rb_wellformed=0
          ;;
      esac
    fi

    # OBLIGATIONS IS A COUNT AND NOT A RANGE, and that is open decision O2 in
    # drawer_tla_puzzles_decisions_6309edf48de99c7168cc221d rather than a
    # settled one. An item may admit a model that splits one rule into two
    # sound conjuncts, which would want a range. Reddening on a range is the
    # deliberate choice: it makes widening the grammar an act somebody has to
    # take, where accepting one silently would settle O2 by accident.
    if [ -z "$RB_OBL" ]; then
      finding "RUBRIC-FIELD-MISSING" "$rel" "## Rubric carries no 'obligations:' line"
      rb_wellformed=0
    elif ! grep -qE '^[0-9]+$' <<<"$RB_OBL"; then
      finding "RUBRIC-FIELD-BAD" "$rel" \
        "obligations: '${RB_OBL}' is not a non-negative integer (O2 is open; a range is refused on purpose)"
      rb_wellformed=0
    fi

    rb_lo=""
    rb_hi=""
    if [ -z "$RB_STATES" ]; then
      finding "RUBRIC-FIELD-MISSING" "$rel" "## Rubric carries no 'states:' line"
      rb_wellformed=0
    elif ! grep -qE '^[0-9]+\.\.[0-9]+$' <<<"$RB_STATES"; then
      finding "RUBRIC-FIELD-BAD" "$rel" \
        "states: '${RB_STATES}' is not <low>..<high>"
      rb_wellformed=0
    else
      rb_lo="${RB_STATES%%..*}"
      rb_hi="${RB_STATES##*..}"
      if [ "$rb_lo" -gt "$rb_hi" ]; then
        finding "RUBRIC-STATES-INVERTED" "$rel" \
          "states: ${RB_STATES} has its low bound above its high one, so it admits nothing"
        rb_wellformed=0
        rb_lo=""
        rb_hi=""
      fi
    fi

    if [ -n "$RB_EXTRA" ]; then
      finding "RUBRIC-FIELD-UNKNOWN" "$rel" \
        "## Rubric carries unknown field(s): ${RB_EXTRA}. A misspelled key is a field nobody reads."
      rb_wellformed=0
    fi

    # --- the three arms over the item's own Verify table ------------------
    #
    # Every number below is READ from the same META.md the rubric sits in. No
    # TLC runs and nothing is measured here, so a row the gate cannot
    # reproduce is still a row this check uses. That is the right direction:
    # check 2 is what holds the table honest against a run, and check 4 asks
    # whether the envelope is consistent with the table as written.
    #
    # GATED ON THE WHOLE RUBRIC BEING WELL FORMED, not only on `states`
    # parsing. A bad `fault` value resolves to a conformant class no rc can
    # report, which would make the teeth arm excuse every admitted wrong
    # count by the rc. That is a false pass on the one arm this check exists
    # for, so a rubric that is malformed anywhere gets its findings and no
    # coverage claim.
    if [ "$rb_wellformed" = "1" ] && [ -n "$rb_lo" ]; then
      rb_correct=0
      rb_wrong=0
      rb_excluded=0
      rb_byrc=0
      rb_nocount=0
      rb_cmin=""
      rb_cmax=""
      rb_seen=" "
      rb_power=0
      rb_conform="$(rubric_conformant_class "$RB_RUNS" "$RB_FAULT")"

      while IFS=$'\t' read -r rb_name rb_rc rb_cnt; do
        [ -n "$rb_rc" ] || continue
        rb_stem="${rb_name##*/}"
        rb_stem="${rb_stem%.tla}"
        if [ "$rb_cnt" = "-" ]; then
          rb_nocount=$((rb_nocount + 1))
          continue
        fi
        # A COUNT-WAIVED ROW IS NOT A MEASUREMENT, so it is no case either
        # way. Its number came from the trace rather than from the log, and
        # demanding the envelope exclude it is a tightening pressure built on
        # something TLC never printed. drill/sets/03-ballast is the one row
        # this reaches today and its count falls outside anyway.
        if count_is_waived "$rb_stem"; then
          rb_nocount=$((rb_nocount + 1))
          continue
        fi

        rb_in=0
        if [ "$rb_cnt" -ge "$rb_lo" ] && [ "$rb_cnt" -le "$rb_hi" ]; then
          rb_in=1
        fi

        if [ "$rb_rc" = "0" ]; then
          # --- FAIRNESS -----------------------------------------------------
          rb_correct=$((rb_correct + 1))
          if [ "$rb_in" = "0" ]; then
            finding "RUBRIC-ENVELOPE-EXCLUDES-CORRECT" "$rel" \
              "${rb_stem} records rc 0 at ${rb_cnt} distinct, outside states: ${RB_STATES}. A correct model the item itself ships is not a reasonable model this envelope admits."
          fi
          [ -z "$rb_cmin" ] && rb_cmin="$rb_cnt"
          [ -z "$rb_cmax" ] && rb_cmax="$rb_cnt"
          [ "$rb_cnt" -lt "$rb_cmin" ] && rb_cmin="$rb_cnt"
          [ "$rb_cnt" -gt "$rb_cmax" ] && rb_cmax="$rb_cnt"
          case "$rb_seen" in
            *" ${rb_cnt} "*) : ;;
            *) rb_seen="${rb_seen}${rb_cnt} "; rb_power=$((rb_power + 1)) ;;
          esac
          continue
        fi

        # --- TEETH ---------------------------------------------------------
        rb_wrong=$((rb_wrong + 1))
        if [ "$rb_in" = "0" ]; then
          rb_excluded=$((rb_excluded + 1))
          continue
        fi
        if [ "$(rc_fault_class "$rb_rc")" != "$rb_conform" ]; then
          rb_byrc=$((rb_byrc + 1))
          continue
        fi
        finding "RUBRIC-ENVELOPE-ADMITS-WRONG" "$rel" \
          "${rb_stem} records rc ${rb_rc} at ${rb_cnt} distinct, inside states: ${RB_STATES}, and rc ${rb_rc} is what a run MEETING this rubric returns. Neither the envelope nor the fault dimension excludes it."
      done < <(verify_rows "$meta")

      # Power counts the EXTRA distinct correct counts, so one correct count
      # is power 0 and two are power 1.
      [ "$rb_power" -gt 0 ] && rb_power=$((rb_power - 1))

      if [ "$rb_correct" = "0" ] && [ "$rb_wrong" = "0" ]; then
        unchecked "rubric-envelope" "$rel" \
          "a ## Rubric declares states: ${RB_STATES} and the ## Verify table offers no row with both an rc and a count, so neither arm could run"
      else
        # --- THE FLOOR ----------------------------------------------------
        #
        # THIS IS THE ARM THAT CATCHES `states: 1..99999`, and it is here
        # because neither of the other two does. The teeth arm lets the rc
        # excuse an admitted wrong count, and on every item declaring
        # `fault: none` the rc excuses all of them, so teeth is satisfiable
        # by any envelope at all. Fairness only asks that correct counts be
        # INSIDE, which a wide envelope satisfies trivially. So an envelope
        # with no information passes both.
        #
        # WHAT IT ASKS is that the states dimension do SOME work: exclude at
        # least one of the item's own recorded wrong counts. That is the
        # 14-of-16 measurement in
        # drawer_tla_puzzles_findings_3459dbeb085693f200068fe9 turned into a
        # floor, and it is the per-root-floor pattern harness/lint and
        # harness/test-spelling.sh already use, where a root that selects
        # nothing reddens instead of passing.
        #
        # WHAT IT DELIBERATELY DOES NOT ASK is that the envelope be tight.
        # Bead tla-sqym.3 widens these envelopes from reasons rather than
        # from counts, and a reasoned envelope is SUPPOSED to be wider than
        # three machines justify. An arm that penalized width would push the
        # field back to the point count the whole design replaces.
        if [ "$rb_wrong" -gt 0 ] && [ "$rb_excluded" = "0" ]; then
          finding "RUBRIC-ENVELOPE-TOOTHLESS" "$rel" \
            "states: ${RB_STATES} excludes none of the ${rb_wrong} wrong count(s) this item records, so the states dimension is switched off and only fault is checking anything"
        fi

        printf 'RUBRIC    %-44s power=%-3s envelope=%-13s correct=%-3s wrong=%-3s excluded=%s/%s by-rc=%s nocount=%s\n' \
          "$rel" "$rb_power" "$RB_STATES" "$rb_correct" "$rb_wrong" \
          "$rb_excluded" "$rb_wrong" "$rb_byrc" "$rb_nocount"

        rubric_power_n=$((rubric_power_n + rb_power))
        rubric_correct_n=$((rubric_correct_n + rb_correct))
        rubric_wrong_n=$((rubric_wrong_n + rb_wrong))
        rubric_excluded_n=$((rubric_excluded_n + rb_excluded))
        rubric_by_rc_n=$((rubric_by_rc_n + rb_byrc))
        rubric_nocount_n=$((rubric_nocount_n + rb_nocount))
        # The `-` arm is for an item whose Verify table records wrong rows and
        # no correct one. The envelope then rests on nothing at all, which is
        # worse than resting on a single count, so it says so rather than
        # printing an empty number.
        if [ "$rb_power" = "0" ]; then
          if [ -n "$rb_cmin" ]; then
            rubric_zero_power="${rubric_zero_power}
  - ${rel}  one distinct correct count, at ${rb_cmin}"
          else
            rubric_zero_power="${rubric_zero_power}
  - ${rel}  NO correct count at all, so the envelope rests on nothing"
          fi
        fi
      fi
    fi
  fi

  unset WAIVED COUNT_WAIVED DECLARED MODS STEMS
done

# ===========================================================================
# CHECK 2, PHASE B — dispatch the queue, then READ THE OUTCOMES IN THE PARENT.
#
# Two rules here and the second is the one that matters.
#
# READ THE JOB LIST FROM A FILE, not from a pipe. `xargs` consumes all of its
# input so it is not an early-exiting consumer, but the file form does not
# raise the question at all. harness/test-pipefail.sh bans `| grep -q`,
# `| grep -m` and `| head` outright, and the reasoning there (bead tla-kr9) is
# why no pipe feeds a consumer in this block.
#
# EVERY FINDING AND OK LINE IS PRINTED BY THE PARENT. A child that called
# `finding()` would print its line and lose the increment with the subshell,
# so the run would end at `finding_n` 0 and exit 0 with FINDING lines in its
# own output — a false PASS on this gate's only correctness check. So a job
# writes one rc to one file and nothing else, and the loop below is what turns
# those into output. harness/test-drill.sh part 2c is the control: -P8 must
# produce the same findings, the same count and the same rc as -P1 over a
# fixture with a planted mismatch.
#
# NO LOCKING AND NO PER-JOB DIRECTORY COPIES, checked before this was built.
# harness/verdict.sh isolates every invocation on its own: a fresh mktemp
# scratch per call unless the caller passes --scratch (verdict.sh:491-493),
# -metadir under that scratch (:529), -noGenerateSpecTE to suppress the
# *_TTrace_*.tla spillage (:513), and TRACE and LOG both under it (:507-508).
# So two TLC runs over two modules in the SAME verify/ directory write nothing
# into it and cannot collide. DO NOT pass --scratch from here: that would hand
# every parallel job one shared directory and create the collision this note
# says does not exist.
# ===========================================================================
if [ "${#JOB_FILES[@]}" -gt 0 ]; then
  run_n=0
  for ((_ji = 0; _ji < ${#JOB_FILES[@]}; _ji++)); do
    _jf="${JOB_FILES[$_ji]}"
    mapfile -t _F <"$_jf"
    _key="${_F[6]}"
    _ident="${_F[0]}|${_F[1]}"
    if [ "$CACHE_ACTIVE" = "1" ] && [ "$_key" != "-" ] && [ -n "${STATE_KEY[$_key]-}" ]; then
      JOB_CACHED[_ji]=1
      cached_n=$((cached_n + 1))
      continue
    fi
    # A job whose identity is in the state file under a DIFFERENT key was
    # verified before and one of its eight inputs has since changed. That is
    # what --changed-only exists to catch, and counting it is what makes the
    # header's third number mean something.
    if [ "$CACHE_ACTIVE" = "1" ] && [ -n "${STATE_ID[$_ident]-}" ]; then
      stale_n=$((stale_n + 1))
    fi
    printf '%s\n' "$_jf" >>"$RUNLIST"
    run_n=$((run_n + 1))
  done

  if [ "$run_n" -gt 0 ]; then
    # The runner, written here rather than shipped as a file, so that the
    # static tiers never read it and it cannot drift from its one caller. It
    # runs verdict.sh and writes ONE rc to ONE file. It exits 0 whatever TLC
    # returned, because a non-zero exit would make xargs report 123 and say
    # nothing about which job it was.
    cat >"$RUNONE" <<'RUNONE_SH'
#!/usr/bin/env bash
# Generated by harness/drill-gate.sh. One TLC run, one rc and one count, two
# files beside the job.
set -uo pipefail
job="$1"
mapfile -t F <"$job"
args=()
[ "${F[5]}" = "1" ] && args=(-d)
"$DG_VERDICT" --timeout "$DG_TIMEOUT" -q "${args[@]+"${args[@]}"}" \
  --log "${job}.log" -c "${F[3]}" "${F[2]}" >/dev/null 2>&1
rc=$?
printf '%s\n' "$rc" >"${job}.rc"
# THE COUNT IS EXTRACTED HERE RATHER THAN IN THE PARENT, so it stays parallel
# and so the parent reads it the same way it already reads the rc, out of a
# file beside the job.
#
# THE LAST MATCH, ON PURPOSE. TLC prints the same number twice on a run that
# reports progress, and on a liveness run it prints it again after the
# temporal pass. harness/drill/temporal/verify-item.sh:40 reads the last match
# for the same reason and this is the same pipeline.
#
# SAFE UNDER pipefail, measured rather than assumed. The rule in
# .claude/rules/dispatched-agents.md is that a consumer which can close the
# pipe early SIGPIPEs the producer and the pipeline returns 141, so a present
# pattern reports as absent. `tail -1` and `cut` both read to end of input, so
# neither closes it. Probed on 2026-10-14 over a 14 MB log with 200,001
# matches: this pipeline returned 0 on six consecutive runs, 1 on a log with
# no match, and 2 on an absent file, while `| head -1` over the SAME log
# returned 141. So the probe was sensitive and this form is not the hazard.
# The 1 and the 2 both yield an empty string, which is the no-measurement
# reading the parent wants, and `|| true` keeps that true if this runner ever
# grows a `set -e`.
cnt="$(grep -oE '[0-9]+ distinct states' "${job}.log" 2>/dev/null | tail -1 | cut -d' ' -f1)" || true
printf '%s\n' "$cnt" >"${job}.count"
exit 0
RUNONE_SH
    export DG_VERDICT="$VERDICT"
    export DG_TIMEOUT="$TIMEOUT"
    # `-d '\n'` so one line is one argument. The default splitting also treats
    # quotes and backslashes as syntax, which a scratch path cannot carry
    # today and which nothing in the format promises it never will.
    #
    # `|| true` because xargs reports 123 when any child exited non-zero, and
    # a 123 here says nothing about which job it was. The runner exits 0
    # whatever TLC returned, so the rc that matters is in the outcome file,
    # and a job with no outcome file is reported as UNCHECKED below.
    xargs -d '\n' -P "$JOBS" -n 1 bash "$RUNONE" <"$RUNLIST" || true
  fi

  echo
  echo "== check 2: the TLC queue — ${#JOB_FILES[@]} job(s), ${run_n} run at -P${JOBS} =="
  echo "   These lines arrive after the item sweep rather than interleaved with it,"
  echo "   because every run is dispatched as one batch. The order is item-then-module"
  echo "   whatever order the runs finished in."
  for ((_ji = 0; _ji < ${#JOB_FILES[@]}; _ji++)); do
    _jf="${JOB_FILES[$_ji]}"
    mapfile -t _F <"$_jf"
    _rel="${_F[0]}"
    _modbase="${_F[1]}"
    _want="${_F[4]}"
    _key="${_F[6]}"
    _wantc="${_F[7]-}"
    _cwaive="${_F[8]-0}"
    _ident="${_rel}|${_modbase}"

    # The claim is on the CACHED line too, because the cache key covers it. A
    # cache line that named only the rc would read as standing for less than
    # it does.
    _wantnote=""
    [ -n "$_wantc" ] && _wantnote=" distinct=${_wantc}"

    if [ "${JOB_CACHED[$_ji]}" = "1" ]; then
      say "  CACHED  ${_rel}  ${_modbase} rc=${_want}${_wantnote}"
      NEW_KEYS+=("$_key")
      NEW_IDS+=("$_ident")
      continue
    fi

    # No outcome file means the runner never completed for this job. That is
    # the instrument failing rather than the item, so it is UNCHECKED and
    # escalates — never a quiet pass.
    if [ ! -f "${_jf}.rc" ]; then
      unchecked "verify-rc" "$_rel" \
        "${_modbase}: the TLC runner wrote no outcome, so the recorded rc ${_want} was not reproduced"
      continue
    fi
    _got="$(<"${_jf}.rc")"
    _gotc=""
    [ -f "${_jf}.count" ] && _gotc="$(<"${_jf}.count")"

    # --- the count half, and the five cases it has to tell apart -----------
    #
    # THE COUNT MATTERS MORE THAN THE rc HERE, and the reason is the reader
    # rather than the gate. An rc says which verdict TLC reached; the count is
    # the number a learner checks their own model against.
    # drill/sequences/07-pneumatic-tube/PROMPT.md publishes "a correct model
    # finds 129 distinct states" as its only foreclosing row, and that number
    # is load-bearing content. The two also drift differently: an rc is coarse
    # and survives a small spec change, while a count moves on any change to
    # the constants, the state space or the initial predicate, silently.
    #
    # NO CLAIM IS NO CHECK, AND IT IS NOT A GAP. The whole temporal family
    # records no count, and that is correct rather than missing: a liveness
    # run's state count is not the diagnosis. Requiring a claim would push
    # eight items into writing a number nobody reads. Equally, a measured
    # count with no claim is nobody's finding.
    _cntok=1
    _cntnote=""
    if [ -z "$_wantc" ]; then
      :
    elif [ -n "$_gotc" ]; then
      count_checked_n=$((count_checked_n + 1))
      if [ "$_gotc" = "$_wantc" ]; then
        _cntnote=" distinct=${_gotc}"
      else
        _cntok=0
        _cntnote=" distinct=MISMATCH"
        finding "VERIFY-COUNT-MISMATCH" "$_rel" \
          "${_modbase}: ANSWER.md's distinct column records ${_wantc}, TLC printed ${_gotc}"
      fi
    elif [ "$_cwaive" = "1" ]; then
      # The waiver excuses ABSENCE and nothing else, which is why this arm sits
      # BELOW the comparison rather than above it. A waived module whose run
      # starts printing a count is compared like any other, so a waiver that
      # has gone stale surfaces rather than standing in for a check.
      _cntnote=" distinct=waived"
    else
      _cntok=0
      _cntnote=" distinct=ABSENT"
      finding "VERIFY-COUNT-ABSENT" "$_rel" \
        "${_modbase}: ANSWER.md's distinct column records ${_wantc} and this run printed no count at all, so the claim is unverifiable. A module whose run cannot print one declares that with a count-waiver line in META.md."
    fi

    if [ "$_got" != "$_want" ]; then
      finding "VERIFY-RC-MISMATCH" "$_rel" \
        "${_modbase}: ANSWER.md records rc ${_want}, TLC returned ${_got}"
    else
      # THE OK LINE PRINTS ON THE rc HALF ALONE, and it carries the count
      # half's verdict beside it. A module whose rc reproduced and whose count
      # did not is two separate facts and the line says both, where a silent
      # OK would let the finding below look like somebody else's row.
      say "  OK    ${_rel}  ${_modbase} rc=${_got}${_cntnote}"
      # A KEY IS RECORDED ONLY WHEN THE JOB RAN AND BOTH HALVES MATCHED. A
      # mismatch of either records nothing, so the next --changed-only run
      # re-runs it rather than caching a failure as verified.
      if [ "$_cntok" = "1" ]; then
        verified_n=$((verified_n + 1))
        if [ "$_key" != "-" ]; then
          NEW_KEYS+=("$_key")
          NEW_IDS+=("$_ident")
        fi
      fi
    fi
  done
  unset _ji _jf _F _rel _modbase _want _key _got _ident
  unset _wantc _cwaive _wantnote _gotc _cntok _cntnote
fi

# --- the state file is written only by the mode that was asked to cache ----
#
# A run that was not asked for the cache does not write one. That keeps the
# default and static tiers free of a side effect in the repo root, and it
# keeps the first --changed-only run honest: it finds nothing cached, runs
# everything, and records what it verified.
if [ "$CACHE_ACTIVE" = "1" ] && [ -n "$CACHE_BASE" ] && [ "${#JOB_FILES[@]}" -gt 0 ]; then
  _tmpstate="${SCRATCH}/state.new"
  : >"$_tmpstate"
  # The identities this run spoke for, so an identity's superseded key is
  # replaced rather than accumulated. Every other line of the old file is
  # carried through untouched — the state file is shared across drill roots,
  # and pruning a key this run never saw would delete another root's work.
  declare -A _MINE=()
  for ((_i = 0; _i < ${#NEW_IDS[@]}; _i++)); do _MINE["${NEW_IDS[$_i]}"]=1; done
  if [ -f "$STATE_FILE" ]; then
    while read -r _k _id; do
      [ -n "$_k" ] || continue
      [ -z "${_MINE[$_id]-}" ] || continue
      printf '%s %s\n' "$_k" "$_id" >>"$_tmpstate"
    done <"$STATE_FILE"
  fi
  for ((_i = 0; _i < ${#NEW_KEYS[@]}; _i++)); do
    printf '%s %s\n' "${NEW_KEYS[$_i]}" "${NEW_IDS[$_i]}" >>"$_tmpstate"
  done
  if ! mv -f "$_tmpstate" "$STATE_FILE" 2>/dev/null; then
    unchecked "verify-cache" "$STATE_FILE" \
      "cannot write the state file, so this run verified ${verified_n} job(s) and recorded none of them"
  fi
  unset _tmpstate _MINE _i _k _id
fi

# ===========================================================================
# CHECK 3 — the corpus-level AUDIT. It prints. It never fails.
#
# There is no `finding` call anywhere in this block, and that is the point. If
# you are here to add one, read CHECK 3 in the header first: a gate that fails
# on an uncovered token pushes an author to write an item FOR the token, which
# is the inventory-to-artifact direction V2-PLAN.md:459 forbids, arriving
# through the back door. The item would then exist to satisfy the gate rather
# than to be worth doing.
# ===========================================================================
if [ "$INV_OK" = "1" ]; then
  echo
  echo "== check 3: construct coverage over ${item_n} item(s) — AUDIT ONLY, never a failure =="
  gaps_high=0
  gap_block=""
  thin_block=""
  badfreq_block=""
  for ((i = 0; i < ${#INV_NORM[@]}; i++)); do
    printf 'COVERAGE  %5d  %-12s %-20s %s\n' \
      "${INV_COUNT[$i]}" "${INV_FREQ[$i]}" "${INV_FAMILY[$i]}" "${INV_RAW[$i]}"
    case "${INV_FREQ[$i]}" in
      unrecognized:*)
        badfreq_block="${badfreq_block}
  - ${INV_RAW[$i]}  has frequency '${INV_FREQ[$i]#unrecognized:}', not high/medium/low"
        ;;
    esac
    if [ "${INV_COUNT[$i]}" -eq 0 ]; then
      gap_block="${gap_block}
  - ${INV_FREQ[$i]}  ${INV_FAMILY[$i]}  ${INV_RAW[$i]}"
      [ "${INV_FREQ[$i]}" = "high" ] && gaps_high=$((gaps_high + 1))
    elif [ "${INV_FREQ[$i]}" = "high" ] && [ "${INV_COUNT[$i]}" -eq 1 ]; then
      thin_block="${thin_block}
  - ${INV_FAMILY[$i]}  ${INV_RAW[$i]}  (1 item)"
    fi
  done

  echo
  echo "LAYER A REACH: ${LAYERA_COVERED} declared-construct scan(s) had a token to look for,"
  echo "  ${LAYERA_NOTOK} did not. A construct whose inventory cell carries no symbol —"
  echo "  \"Operator definition\", \"Integers\" — has no token a prompt could leak, so layer A"
  echo "  does not apply and the floor over the answer's own code is the only telegraph"
  echo "  layer covering those items. Backticking a symbol in the inventory cell is what"
  echo "  brings a row into layer A's reach."

  if [ -n "$gap_block" ]; then
    echo
    echo "CONSTRUCT GAPS — constructs with no item, ${gaps_high} of them expected-high.$gap_block"
    echo
    echo "  Every row's count is on the COVERAGE lines above, including the covered ones."
    echo "  This block is the aim for the next authoring wave, and that is ALL it is."
    echo "  It does not fail the gate at any frequency. Frank's requirement is"
    echo "  corpus-level — 'sooner or later everything gets hit and the common ones get"
    echo "  hit frequently' — so read it as a pointer to where the next item would be"
    echo "  worth writing, never as a list of items somebody now owes. An item written"
    echo "  to close a row here is contrived by construction, which is the thing this"
    echo "  corpus exists to avoid."
  fi

  if [ -n "$thin_block" ]; then
    echo
    echo "THIN — expected-high constructs carried by a single item.$thin_block"
  fi

  if [ -n "$badfreq_block" ]; then
    echo
    echo "INVENTORY FREQUENCY — rows whose frequency column is not high/medium/low.$badfreq_block"
    echo
    echo "  Printed, not failed. INVENTORY.md is a file that is still being written, and"
    echo "  the gate does not get a vote on its shape."
  fi
fi

# ===========================================================================
# THE COUNT CLAIM'S OWN COVERAGE LINE.
#
# TWO NUMBERS, BECAUSE ONE OF THEM WOULD LIE. "parsed" is how many modules
# record a distinct count, and it does not move with the tier. "compared" is
# how many of those were put against a measurement, and it is 0 in both
# static tiers because neither ran TLC. A run that printed only the first
# would read as coverage it had not achieved, and a run that printed only the
# second would say nothing about what it had to work with.
#
# IT PRINTS THROUGH `echo` RATHER THAN `say`, like the mode blocks below and
# for the same reason: `-q` suppresses per-item PASS lines, and a statement
# about how much of the corpus this run actually checked is not one of those.
echo
echo "drill-gate.sh: count claims: ${count_claim_n} parsed, ${count_checked_n} compared against a measured count, ${count_waived_n} waived."
if [ "$count_claim_n" -gt 0 ] && [ "$count_checked_n" = "0" ] \
   && [ "$NO_TLC" = "0" ] && [ "$STATIC_ONLY" = "0" ] && [ "$cached_n" = "0" ]; then
  # Not a finding, and deliberately not. A tier that runs TLC, reaches a claim
  # and compares none has either an empty queue or an instrument that stopped
  # extracting, and the UNCHECKED lines above already carry the second case.
  # What would be wrong is passing over it in silence.
  #
  # A WARM CACHE IS EXCLUDED BY THE LAST CLAUSE, because there the zero is the
  # right answer rather than a symptom. A cached job's claim is in its key, so
  # the claim it stands for is byte-identical to the one that was compared
  # when the key was recorded, and a key is recorded only when both halves
  # matched. The --changed-only block below states that.
  echo "NO COUNT WAS COMPARED although ${count_claim_n} were parsed, in a tier that runs TLC"
  echo "and served nothing from cache. Read the queue block above: most likely no job"
  echo "reached the queue at all."
fi

# ===========================================================================
# CHECK 4'S OWN COVERAGE, AND THE NUMBER A GREEN RUN CANNOT IMPLY.
#
# A GREEN FAIRNESS ARM IS NOT EVIDENCE THE ENVELOPES ARE FAIR, and this block
# is the whole reason the arm is allowed to be green at all. Every envelope in
# the corpus today is the lowest and highest count among its item's own rc 0
# rows, so "every correct count is inside" holds by construction. The arm
# bites only on an envelope somebody narrowed by hand.
#
# SOUNDNESS POWER is what the corpus can actually discriminate: the number of
# extra distinct counts among an item's correct models. An item shipping one
# correct count proves nothing about fairness at all, because any envelope
# containing that one number passes. Measured 2026-10-24 over the 16 items
# whose META.md records counts, the whole-corpus power was 6, contributed by
# five items and zero by the other eleven
# (drawer_tla_puzzles_findings_3459dbeb085693f200068fe9).
#
# ITS SHAPE IS harness/test-spelling.sh's HABIT of naming what stays outside
# its root list, beside the list. The count is printed rather than waived,
# because a number here is one authored envelope away from moving and nothing
# else would catch it.
#
# THE FIX FOR THE GAP IS THE RUNNER AND IT COSTS NO AUTHORING. When Frank
# solves an item his model is a correct alternate of a representation the item
# does not ship. `./drill done` recording the distinct count his run produced
# would raise this number with use, and an out-of-envelope count on an item he
# marked done is direct evidence the envelope is too tight. That signal exists
# nowhere else in the design.
# ===========================================================================
echo
if [ "$rubric_item_n" = "0" ]; then
  echo "drill-gate.sh: check 4, the rubric. 0 of ${item_n} item(s) carry a ## Rubric, so nothing was compared."
  echo "An item with no rubric is OUT OF SCOPE for check 4 and not a defect. Bead tla-sqym.2"
  echo "is what extends the rubric past the two families whose META.md records counts."
else
  echo "drill-gate.sh: check 4, the rubric. ${rubric_item_n} of ${item_n} item(s) carry one."
  echo "  ${rubric_correct_n} correct machine(s), ${rubric_wrong_n} wrong, ${rubric_excluded_n} of the wrong excluded by the envelope"
  echo "  and ${rubric_by_rc_n} by the recorded rc. ${rubric_nocount_n} row(s) record no usable count and are no case either way."
  echo "SOUNDNESS POWER ${rubric_power_n} over ${rubric_item_n} item(s) carrying a rubric."
  if [ -n "$rubric_zero_power" ]; then
    echo "AT POWER 0, so this run cannot tell a fair envelope from a tight one there:${rubric_zero_power}"
  fi
  echo "  Power counts an item's EXTRA distinct correct counts. One correct count is 0."
  echo "  A rubric can pass every arm above and still reject a reasonable model, which is"
  echo "  the failure the whole design exists to prevent and the one no arm here can see."
fi

# ===========================================================================
# THE MODE BLOCKS — what a tier that exits 0 did NOT check.
#
# A MODE THAT EXITS 0 WITHOUT SAYING WHAT IT SKIPPED IS THE DEFECT. These
# blocks are the half of --static-only and --changed-only that makes a clean
# run readable rather than merely green.
#
# PRINTED AT THE END AND NOT AT THE TOP, and the brief called this a header.
# The count is the whole point of the block, and it does not exist until the
# sweep has walked every item — so a block at the top would either carry no
# number or carry a guess. The mode is announced in the banner at the top,
# where a reader looks for it, and the count is stated here, where it is true.
# These print through `echo` rather than `say`, so `-q` cannot suppress them:
# the honesty statement is not a per-item PASS line.
# ===========================================================================
if [ "$STATIC_ONLY" = "1" ]; then
  echo
  echo "drill-gate.sh: --static-only. ${static_n} recorded rc(s) not reproduced, no TLC ran."
  # THE LINE BELOW IS WRITTEN FOR THE CENSUS AS WELL AS FOR A READER, and it
  # looks redundant against the count above until you know why.
  #
  # harness/test-indeterminate.sh part 2 scans every instrument's source for a
  # fixed vocabulary of phrases that admit a skip, and an instrument that can
  # admit one without being driven by a row of that suite fails the census.
  # The count line above states a number and dodges all nine phrases, so this
  # mode exited 0 carrying a skip admission that no gate could see. That is
  # the defect the reserved-indeterminate gate exists for, one level up.
  #
  # So the admission is spelled in the vocabulary, and the waiving flag is
  # named IN PARENTHESES, which is the PARENTHETICAL RULE in that suite's
  # header: an admission that names the caller flag behind it is voluntary and
  # its rc 0 is legitimate, while one that names no flag is involuntary and
  # must carry 99. Dropping the parenthetical turns this run into a failure,
  # correctly. Keep both halves on ONE line: the suite tests the waiver per
  # line, so a parenthetical on the next line waives nothing.
  echo "Check 2's TLC half was not run (--static-only), which is the scope the caller asked for."
  echo "NOT CHECKED HERE: whether any recorded rc still reproduces on this TLC build."
  echo "The slow row of harness/test-drill.sh and scripts/cibuild run that."
  echo "This run answers whether the corpus is STRUCTURALLY sound and nothing more."
fi

if [ "$CHANGED_ONLY" = "1" ]; then
  echo
  echo "drill-gate.sh: --changed-only. ${verified_n} job(s) verified, ${cached_n} from cache, ${stale_n} stale."
  if [ "$CACHE_ACTIVE" = "0" ]; then
    echo "NO JOB REACHED THE QUEUE: a static tier was asked for as well, so no TLC ran,"
    echo "no key was computed and the state file was neither read nor written. The cache"
    echo "is a record of runs that happened, so a tier that runs nothing records nothing."
  elif [ -z "$CACHE_BASE" ]; then
    echo "NO CACHE WAS CONSULTED: the TLC build could not be resolved, so every job ran"
    echo "and nothing was recorded. The verify-cache line above says why. Every job in"
    echo "this run was verified against the build on PATH, so the run's own findings"
    echo "decide its exit code and a missing cache escalates nothing."
  elif [ "$STATE_PRESENT" = "0" ]; then
    echo "NO STATE FILE EXISTED at ${STATE_FILE}, so nothing was cached and every job ran."
    echo "That is correct for a fresh checkout. The next run reads what this one recorded."
  fi
  echo "A CACHED JOB IS VERIFIED, not skipped: same TLC build, same verdict.sh, same"
  echo "verify/ bytes, same flags, same timeout, same box. Any one of those changing"
  echo "changes the key, and the job runs again. 'stale' counts the jobs whose identity"
  echo "was in the state file under a different key, which is a change this run caught."
  echo "THE CLAIMED DISTINCT COUNT IS IN THE KEY TOO, so a cached job stands for its"
  echo "count as well as its rc. Editing nothing but a distinct cell moves no other"
  echo "input to the hash, so leaving it out is the one way this cache could still"
  echo "serve a pass for a claim nobody had compared. That is why 'compared' above"
  echo "reads 0 on a warm cache rather than reading as a check that stopped running."
fi

# ===========================================================================
echo
echo "drill-gate.sh: ${item_n} item(s), ${finding_n} finding(s), ${unchecked_n} unchecked, ${declared_n} declared"

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
