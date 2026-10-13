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
#                      and matched
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
#   COVERAGE  <count> <freq> <family> <construct>
#   WAIVER    <item> <token> <reason>     a per-item telegraph waiver, echoed
#                                         so waivers cannot accumulate unseen.
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
# ONLY CHECKS 1 AND 2 CAN PRODUCE A FINDING. CHECK 3 PRINTS AND NEVER FAILS —
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
# CHECK 2 — VERIFICATION.  Does verify/ actually run, and does the recorded
#                          rc reproduce?
#
# WHAT IS CHECKED. Every module under verify/ that is CHECKABLE — it has a
# .cfg and ANSWER.md records an rc for it — is run through
# harness/verdict.sh, and the rc TLC returns must equal the rc ANSWER.md
# claims. An item whose recorded rc does not reproduce is the defect; the
# number in the file is a measurement and a measurement that does not
# repeat is wrong.
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
  printf '%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" >"$jf"
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
# RESOLVED FROM THE WRAPPER, NEVER HARDCODED. ~/bin/tlc is written by
# scripts/setup and names the jar in one `JAR=` line; reading it is what makes
# the key follow a toolchain change rather than a path somebody typed here. If
# the wrapper is not the pinned shape, or the jar it names is missing, the
# caller reports UNCHECKED and runs every job — caching against an unknown
# build is the one failure this cache must not have.
JAR_PATH=""
resolve_jar() {
  JAR_PATH=""
  local w v
  w="$(command -v tlc 2>/dev/null)" || return 1
  [ -n "$w" ] || return 1
  [ -f "$w" ] || return 1
  v="$(awk -F= '/^[[:space:]]*JAR=/ { sub(/^[^=]*=/, "", $0); print; exit }' "$w")"
  [ -n "$v" ] || return 1
  v="${v%\"}"
  v="${v#\"}"
  v="${v/\$\{HOME\}/$HOME}"
  v="${v/\$HOME/$HOME}"
  v="${v/#\~/$HOME}"
  [ -f "$v" ] || return 1
  JAR_PATH="$v"
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
# waivers <answer.md>: lines of the form
#     telegraph-waiver: <token> -- <reason>
# A waiver suppresses exactly one token for exactly one item. Every waiver is
# echoed in the output, so a corpus cannot quietly fill up with them; a waiver
# with no reason is itself a finding. This mirrors the per-site
# `# shellcheck disable` with its reason above it that scripts/lint requires.
# ---------------------------------------------------------------------------
waivers() {
  grep -iE '^[[:space:]]*[*_ ]*telegraph-waiver[*_ ]*:' "$1" 2>/dev/null || true
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

# verdict.sh's table. A recorded rc outside it is a mis-transcription.
rc_in_table() {
  case "$1" in
    0|10|11|12|13|14|75|76|77|99|124|150|151|255) return 0 ;;
    *) return 1 ;;
  esac
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
if [ "$CACHE_ACTIVE" = "1" ]; then
  if ! resolve_jar; then
    unchecked "verify-cache" "tlc" \
      "cannot resolve the jar the pinned tlc wrapper runs, so a key would be computed against an unknown build; every job will run and nothing will be cached"
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
  wv="$(waivers "$answer")"
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

    job_key="-"
    if [ -n "$item_tree" ]; then
      sha_of_string "${CACHE_BASE}|${rel}|${modbase}|${want}|${deadlock_flag}|${TIMEOUT}|${item_tree}"
      job_key="$SHA"
    fi

    enqueue_job "$rel" "$modbase" "$mod" "$cfg" "$want" "$deadlock_flag" "$job_key"
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

  unset WAIVED DECLARED MODS STEMS
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
# Generated by harness/drill-gate.sh. One TLC run, one rc, one file.
set -uo pipefail
job="$1"
mapfile -t F <"$job"
args=()
[ "${F[5]}" = "1" ] && args=(-d)
"$DG_VERDICT" --timeout "$DG_TIMEOUT" -q "${args[@]+"${args[@]}"}" -c "${F[3]}" "${F[2]}" >/dev/null 2>&1
rc=$?
printf '%s\n' "$rc" >"${job}.rc"
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
    _ident="${_rel}|${_modbase}"

    if [ "${JOB_CACHED[$_ji]}" = "1" ]; then
      say "  CACHED  ${_rel}  ${_modbase} rc=${_want}"
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

    if [ "$_got" != "$_want" ]; then
      finding "VERIFY-RC-MISMATCH" "$_rel" \
        "${_modbase}: ANSWER.md records rc ${_want}, TLC returned ${_got}"
    else
      say "  OK    ${_rel}  ${_modbase} rc=${_got}"
      verified_n=$((verified_n + 1))
      # A KEY IS RECORDED ONLY WHEN THE JOB RAN AND ITS rc MATCHED. A mismatch
      # records nothing, so the next --changed-only run re-runs it rather than
      # caching a failure as verified.
      if [ "$_key" != "-" ]; then
        NEW_KEYS+=("$_key")
        NEW_IDS+=("$_ident")
      fi
    fi
  done
  unset _ji _jf _F _rel _modbase _want _key _got _ident
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
    echo "and nothing was recorded. The UNCHECKED line above says why."
  elif [ "$STATE_PRESENT" = "0" ]; then
    echo "NO STATE FILE EXISTED at ${STATE_FILE}, so nothing was cached and every job ran."
    echo "That is correct for a fresh checkout. The next run reads what this one recorded."
  fi
  echo "A CACHED JOB IS VERIFIED, not skipped: same TLC build, same verdict.sh, same"
  echo "verify/ bytes, same flags, same timeout, same box. Any one of those changing"
  echo "changes the key, and the job runs again. 'stale' counts the jobs whose identity"
  echo "was in the state file under a different key, which is a change this run caught."
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
