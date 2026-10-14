#!/usr/bin/env bash
# completion-gate.sh — the five checks over the completion corpus.
#
# WHY THIS EXISTS. Nine completion items landed on 2026-10-13 and nothing
# checked the corpus. completion/verify-item.sh answers one question per item,
# "is this item solvable", by running that item's own EXPECT. It has no
# opinion about whether the item is a good item. Three defects appeared in
# drafts during the authoring wave and all three were caught by a person
# reading, which does not scale past the nine. Bead tla-4yit, part of
# tla-rmuf.
#
# WHAT A COMPLETION ITEM IS. A machine with its properties removed, plus the
# machines that grade what the learner writes back. work/Claims.tla carries
# one `<Name> == FILL_IN_CLAIM_<n>` line per HOLE. Beside it sit N+1 machines:
# one correct, and one BROKEN PER HOLE whose job is to be caught. EXPECT is
# tab-delimited, one `stem<TAB>rc` row per machine, the correct machine first.
# ANSWER.md carries the reference bodies and is WITHHELD from delivery.
#
# USAGE
#   harness/completion-gate.sh [OPTIONS] <completion-root>
#
# OPTIONS
#   --no-tlc        skip checks 1 and 2's TLC runs. Checks 3, 4 and 5 still
#                   run. This mode can NEVER exit 0 — see EXIT CODES.
#   --static-only   run checks 3, 4 and 5, and no TLC at all. A clean run
#                   exits 0 — see THE TWO TIERS below for why this is not
#                   --no-tlc.
#   --timeout SECS  per-module TLC budget, passed to verdict.sh (default 120)
#   -q, --quiet     suppress the per-item OK lines; findings still print
#   -h, --help      this text
#
# ===========================================================================
# THE TWO TIERS — two questions, and the second is not a volume knob on the
# first. The shape is harness/drill-gate.sh's and the reasoning is its.
#
#   --static-only   is the corpus STRUCTURALLY sound?    clean run -> 0
#   (unflagged)     does every hole still bite?          clean run -> 0
#   --no-tlc        I asked you to measure and you did not.  always 99
#
# `--no-tlc` means the gate was asked whether each hole bites and did not
# find out, so it carries that forward as CHECK_DID_NOT_RUN and can never
# report success. `--static-only` means it was asked for the static checks
# ONLY, and a clean run answers that question completely — so it exits 0 and
# STATES the count it did not measure, because a mode that exits 0 without
# saying what it left out is the defect this distinction exists to avoid.
#
# Passing both is a usage error. Two different questions, two different exit
# codes, and the gate will not guess which one was meant.
#
# OUTPUT — three machine-readable line shapes, then a human block.
#   FINDING   <code> <item> <detail>      a defect. Exits 1.
#   UNCHECKED <check> <subject> <detail>  a check that could not run. Exits 99.
#   WAIVER    <item> <token> <reason>     a per-item telegraph waiver, echoed
#                                         so waivers cannot accumulate unseen.
#
# EXIT CODES, the same three this project uses everywhere.
#     0  every check THIS RUN ASKED FOR ran and passed
#     1  at least one FINDING. Findings outrank unchecked
#    99  no findings, but at least one check COULD NOT RUN. The project-wide
#        CHECK_DID_NOT_RUN code (harness/verdict.sh, bead tla-hl96)
#     2  usage error
#
# ===========================================================================
# CHECK 1 — ONE MACHINE PER HOLE. This is the check that matters most.
#
# For an item with N holes, each broken machine must be caught by EXACTLY ONE
# hole. The reference item shipped a draft where a correct second claim caught
# the first mutant unaided, so `Walked == TRUE` scored the reference signature
# and the first hole was checked by nothing. A human reading caught it.
#
# HOW IT IS MEASURED, and it is a measurement rather than a reading. Build the
# item three-plus-one ways in a scratch copy of work/ and run every machine
# each time:
#
#   reference   every hole filled from ANSWER.md.  Signature must equal EXPECT
#   hole i      hole i filled with TRUE, the rest from ANSWER.md
#   all TRUE    every hole filled with TRUE                      (check 2)
#
# THE CORRESPONDENCE IS POSITIONAL, and it is checked rather than assumed.
# EXPECT row 1 is the correct machine and its recorded rc must be 0. EXPECT
# row i+1 is hole i's machine. So filling hole i with TRUE must move the
# signature at position i+1 AND NOWHERE ELSE:
#
#   position i+1 unmoved   HOLE-UNCHECKED  nothing catches this hole
#   another position moved HOLE-OVERLAP    two holes answer to one machine
#
# Measured on all nine landed items 2026-10-14, TLC2 2026.07.31.184830: every
# one scores `hole i TRUE moves exactly position i+1`, and 01-clockface's
# ANSWER.md table states the same two columns independently.
#
# THE REFERENCE RUN IS NOT OVERHEAD. Check 1 is a statement about a DELTA from
# the reference signature, so an unverified reference makes every delta a
# measurement against a number nobody checked. REFERENCE-SIGNATURE is the
# finding when ANSWER.md's own claims do not score what EXPECT records.
#
# THREE STRUCTURAL FINDINGS GUARD THE MEASUREMENT, and each is a FINDING
# rather than an unchecked, because in every case the item is wrong rather
# than the instrument short of information:
#
#   CLAIMS-UNPARSED-HOLE   a FILL_IN marker outside a `<Name> ==` line, so
#                          the gate cannot rewrite it
#   CLAIMS-HOLE-PREFILLED  ANSWER.md defines a claim that Claims.tla already
#                          fills in, so the item hands that hole over
#   HOLE-MACHINE-COUNT     the machine count is not one correct plus one per
#                          hole, so the positional correspondence has no
#                          meaning
#
# WHAT IS *NOT* CHECKED HERE:
#   - WHETHER THE REFERENCE ANSWER IS THE RIGHT ANSWER. Scoring the recorded
#     signature proves the three machines separate it from TRUE, not that it
#     says what PROMPT.md asked for. Only a reader gets that.
#   - THE ACCEPTED VARIANTS. ANSWER.md lists them in prose and later fenced
#     blocks; nothing here runs one. An item whose stated variant does not
#     score the reference signature is invisible to this gate.
#   - WHETHER A MACHINE FAILS FOR THE INTENDED REASON. rc 12 says a safety
#     violation happened, not that it was the one the author built.
#   - A HALF-RIGHT ANSWER THAT IS NOT `TRUE`. TRUE is the weakest claim there
#     is, so it is the right probe for "this hole is unchecked", and it is the
#     only probe run.
#
# ===========================================================================
# CHECK 2 — A HOLE MUST BE FALSIFIABLE. The all-TRUE signature must differ
# from the reference signature.
#
# Weaker than check 1 and kept separate on purpose. Check 1 can fail per hole
# while the all-TRUE run still moves, and an item where the two signatures
# MATCH has at least one hole nothing checks at all — the whole item then
# grades `TRUE, TRUE` as correct. One assertion, one name, so the output says
# which of the two failed.
#
# ===========================================================================
# CHECK 3 — NO TELEGRAPH, PER OPERATOR, OVER EVERY SHOWN FILE.
#
# An operator the reference answer uses must not appear in any file the
# learner sees, MACHINES INCLUDED. Two authors fixed a leak in a machine
# rather than in Claims.tla, which is why the scan is over the whole delivered
# surface and not over Claims.tla alone.
#
# EVERY FILE THE LEARNER SEES is the delivery manifest, taken from
# scripts/deliver-completion.sh's header rather than guessed: PROMPT.md,
# EXPECT, and work/ recursively. That header states the rule the manifest
# rests on — "work/ is the public half of the item and the item root is the
# private half" — so an item-root file is withheld BY LOCATION and ANSWER.md
# and META.md are safe places for an answer.
#
# PER OPERATOR, NOT PER drill/INVENTORY.md ROW, and this is the distinction
# the reference item was built to expose. Row K013 covers `\cup` as well as
# `\subseteq`. `completion/sets/01-clockface` shows `seen \cup {pos'}` in its
# machine and its answer uses `\subseteq`, so a row-granularity check flags it
# and a per-operator check does not. That item's META.md records the honest
# statement: "`\subseteq` does not appear in any shown file, and K013 does."
#
# SO THE OPERATOR SET COMES FROM THE REFERENCE ANSWER'S OWN TEXT, intersected
# with TELEGRAPH_TOKENS below. This is harness/drill-gate.sh's layer B (the
# floor) narrowed to one operator at a time, and it needs no inventory parser:
# reading-gate.sh's header records that duplicating drill-gate.sh's INVENTORY
# tab parser is its own bead, and this gate does not duplicate it either. The
# cost is that a construct with no symbol — "Operator definition" — is outside
# this check's reach, exactly as it is outside layer A's.
#
# WHAT IS *NOT* CHECKED, and these are holes rather than caveats:
#   - ENGLISH PARAPHRASE. PROMPT.md has to state the requirement in English;
#     flagging the gloss would forbid writing a prompt. drill-gate.sh calls
#     this the largest deliberate hole in its own check 1 and it is the same
#     hole here.
#   - DOMAIN SMELL. An item that telegraphs by familiarity shows no token.
#   - SHARED TLA+ VOCABULARY, by construction. See the exclusion list below.
#   - WHETHER A WAIVER'S REASON IS TRUE. Presence and length are checked.
#
# ===========================================================================
# THE PER-ITEM TELEGRAPH WAIVER — required, not optional, and it carries its
# reason INSIDE THE ITEM.
#
# A line in the item's META.md:
#
#     telegraph-waiver: <token> -- <reason>
#
# optionally bulleted or emphasised (`- **telegraph-waiver**: ...`). It
# suppresses EXACTLY ONE token for EXACTLY ONE item. This is
# harness/drill-gate.sh:1064-1073's line format unchanged, so the project has
# one waiver idiom rather than two; it is read from META.md here because
# META.md is where a completion item already argues about this rule — see the
# closing sections of 01-clockface's, 01-squares's and 01-roster's.
#
# A WAIVER WITH NO REASON IS ITSELF A FINDING, and so is one naming no token.
# Every waiver is echoed on a WAIVER line on every run, clean runs included,
# so a corpus cannot quietly fill up with them. It mirrors the per-site
# `# shellcheck disable` with its reason above it that scripts/lint requires.
#
# IT CANNOT BE SET BY ACCIDENT, and that is four things rather than one. The
# literal key has to START the line, past nothing but bullet and emphasis
# punctuation, so the string in a sentence waives nothing. A token AND a
# reason of at least 12 non-space characters are both required and either one
# missing is a finding rather than a pass. The waiver names ONE token, so it
# cannot widen to a family. And it is echoed in the output of every run, so
# nobody has to go looking. Measured 2026-10-14: no META.md in the corpus
# carries the key today, so no landed item is waived by accident.
#
# WHY A PER-ITEM WAIVER AND NOT A FAMILY PASS. The pluscal family needs one
# and the reason is structural: `pcal` writes
# `Terminating == pc = "Done" /\ UNCHANGED vars` into every translation that
# can finish, so a terminal-state hole's `pc` guard is in the shown code
# before the learner types anything. completion/pluscal/01-squares/META.md
# says exactly that. A blanket pass for `pluscal/*` would also waive the
# NEXT pluscal item's claim 1, which has no such excuse, and would waive a
# token nobody has argued about.
#
# ===========================================================================
# CHECK 4 — NO STRAY FILE UNDER work/.
#
# `pcal` writes a `<Module>.old` backup beside every module it rewrites, and
# scripts/deliver-completion.sh delivers work/ RECURSIVELY by design,
# including a file added tomorrow. One author's first --check run listed three
# .old files as about to land. So work/ may hold Claims.tla and, per EXPECT
# stem, `<stem>.tla` and `<stem>.cfg`. Nothing else, at any depth.
#
# A Claims.cfg is a finding too, and deliberately: no EXPECT stem is Claims,
# so it would be a config for a module that never runs.
#
# ===========================================================================
# CHECK 5 — EVERY EXPECT STEM RESOLVES to a .tla and a .cfg under work/.
#
# completion/verify-item.sh reads EXPECT to know what to run, so a stem that
# resolves to nothing is an item that cannot be graded. Checked before check 1
# for the same reason reading-gate.sh checks its .cfg obligation before its rc
# reproduces: the later check's result is meaningless without it.
#
# ===========================================================================
# WHAT THIS GATE DELIBERATELY DOES NOT DO
#
# NO VACUITY PROBE. harness/vacuity.sh is the instrument for "did this run
# check anything", and an item's correct machine exiting 0 over a claim that
# is true of nothing is invisible here. Checks 1 and 2 bound that from the
# other side — a hole nothing refutes is caught — but they do not establish
# that the reference answer is non-vacuous on the correct machine.
#
# NO PHONE BOUND. harness/reading-gate.sh's check 2 bounds a reading item's
# lines and columns because that corpus is read on a phone. A completion item
# is worked in an editor and nobody has set a bound for it.
#
# NO CONSTRUCT-COVERAGE REPORT, and no check that META.md's Roles table is
# honest or complete. META.md is taken at its word here exactly as it is by
# harness/drill-gate.sh's check 3.
#
# ===========================================================================
# OUTSTANDING: THIS INSTRUMENT IS NOT YET IN harness/test-indeterminate.sh's
# REGISTRY, AND THAT SUITE IS RED UNTIL IT IS.
#
# Its part 2 census selects every `harness/*.sh` that is not a test suite FROM
# THE TREE, so this file was covered the moment it landed, and an instrument
# that can admit a skip must be driven by a row of that suite. Measured
# 2026-10-14, `harness/test-indeterminate.sh` -> 74 passed, 1 failed:
#
#   FAIL  UNREGISTERED instrument(s) can admit a skip
#   harness/completion-gate.sh:
#     Checks 1 and 2 could not run. Pass --no-tlc to say so deliberately.
#     --no-tlc was asked for, so the check was not run
#
# Both lines are honest and neither should be reworded to quiet the census;
# the third admission, the --static-only block below, was reworded for the
# opposite reason and the note there says why.
#
# WHAT THE REGISTRATION NEEDS, and why it was not done with this bead. The
# drill and reading rows point their gate at the REAL corpus, and a row here
# would want `--no-tlc -q completion` to return 99 and `--static-only -q
# completion` to return 0. Both return 1 today, because two landed items
# carry a telegraph leak that cannot be fixed in the item and neither yet
# carries the waiver line this gate's own check 3 asks for. So the registry
# row and the two waivers are ONE piece of work, and it is central's:
# harness/test-indeterminate.sh is driven by a shared registry and
# completion/ is outside bead tla-4yit's footprint. The PENDING REGISTER in
# harness/test-completion-gate.sh's part 3 names the two items and the
# sections of their META.md where their authors already wrote the reasons.
# ===========================================================================

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERDICT="${REPO_ROOT}/harness/verdict.sh"

# ---------------------------------------------------------------------------
# TELEGRAPH_TOKENS — check 3's token set.
#
# The first five rows are harness/drill-gate.sh:269-275's DISTINCTIVE set
# VERBATIM, and its exclusion list applies here unchanged: `/\ \/ \in \A \E
# => <=> ~ ' = # /=`, the structural keywords and the standard-module names
# are all shared vocabulary that any shown machine carries and any answer
# uses. Flagging those would fail every item of this shape.
#
# TWO TOKENS ARE ADDED, and each one is measured rather than reasoned.
# Probed 2026-10-14 over all nine items: with DISTINCTIVE alone,
# `completion/pluscal/01-squares`'s reference bodies carry NO token at all, so
# check 3 would be vacuous over the whole pluscal family and the waiver the
# bead requires would have nothing to waive. `pc` is the operator its own
# META.md Roles table names for claim 2 (row K036), and `Terminating` is the
# name pcal writes for the guard (row K092).
TELEGRAPH_TOKENS=(
  '~>' '<>' '[]' ']_' 'WF_' 'SF_' 'ENABLED'
  'UNCHANGED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'INSTANCE' 'RECURSIVE'
  '|->' ':>' '@@' 'LAMBDA'
  'Cardinality' 'Permutations' 'SelectSeq' 'TLCGet' 'Assert'
  '\X' '\o' '\cup' '\cap' '\subseteq' '\notin'
  'pc' 'Terminating'
)

# A reason shorter than this is an exemption wearing a waiver's clothes.
# Same floor as harness/drill-gate.sh:1442.
WAIVER_REASON_MIN=12

NO_TLC=0
STATIC_ONLY=0
TIMEOUT=120
QUIET=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-tlc)      NO_TLC=1 ;;
    --static-only) STATIC_ONLY=1 ;;
    --timeout)     TIMEOUT="${2:-120}"; shift ;;
    -q|--quiet)    QUIET=1 ;;
    -h|--help)
      awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "completion-gate.sh: unknown option '$1' (try --help)" >&2
      exit 2
      ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "completion-gate.sh: more than one completion root given ('$ROOT', '$1')" >&2
        exit 2
      fi
      ROOT="$1"
      ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  echo "completion-gate.sh: no completion root given (try --help)" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "completion-gate.sh: '$ROOT' is not a directory" >&2
  exit 2
fi
case "$TIMEOUT" in
  ''|*[!0-9]*)
    echo "completion-gate.sh: --timeout wants a positive integer, got '$TIMEOUT'" >&2
    exit 2
    ;;
esac

# Two different questions with two different exit codes. See THE TWO TIERS.
if [ "$NO_TLC" = "1" ] && [ "$STATIC_ONLY" = "1" ]; then
  echo "completion-gate.sh: --no-tlc and --static-only are different questions with different exit codes; pass one" >&2
  exit 2
fi

RUN_TLC=1
if [ "$NO_TLC" = "1" ] || [ "$STATIC_ONLY" = "1" ]; then
  RUN_TLC=0
fi

if [ ! -x "$VERDICT" ] && [ "$RUN_TLC" = "1" ]; then
  echo "completion-gate.sh: ${VERDICT} is missing or not executable." >&2
  echo "  Checks 1 and 2 could not run. Pass --no-tlc to say so deliberately." >&2
  exit 2
fi

finding_n=0
unchecked_n=0
item_n=0
static_n=0

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-26s %-34s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-26s %-34s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

SCRATCH="${TMPDIR:-/tmp}/completion-gate-$$"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# answer_block <answer.md>: the FIRST fenced code block, body only.
#
# The first block and not every block, because the later ones are the accepted
# variants. All nine items put both reference bodies in the first block, under
# a `## The two claims` heading; the gate anchors on the fence rather than the
# heading so a renamed heading does not silently empty the block.
# ---------------------------------------------------------------------------
answer_block() {
  awk '/^[[:space:]]*```/ { n++; next } n == 1 { print }' "$1"
}

# ---------------------------------------------------------------------------
# claim_body <name> <block>: the definition text for one hole.
#
# Runs from the `<Name> ==` line to the next definition at column 0, or to the
# end of the block. That is what carries a multi-line body: 01-rungs writes
# `Standing ==` with its quantifier on the next line.
#
# THE LIMIT, stated rather than discovered later: a body whose continuation
# line starts a definition at column 0 would be cut short. No landed item does
# that, and a body that lost a line scores the wrong signature, so check 1
# reports it as REFERENCE-SIGNATURE rather than passing.
# ---------------------------------------------------------------------------
claim_body() {
  awk -v want="$1" '
    $0 ~ "^"want"[ \t]*==" { grabbing = 1; print; next }
    grabbing && /^[A-Za-z][A-Za-z0-9_]*[ \t]*==/ { grabbing = 0 }
    grabbing { print }
  ' <<<"$2"
}

# ---------------------------------------------------------------------------
# waiver_lines <meta.md>: the per-item telegraph waivers, one per line.
# Same pattern as harness/drill-gate.sh:1071-1073, plus a leading `-` so a
# markdown bullet is accepted.
# ---------------------------------------------------------------------------
waiver_lines() {
  grep -iE '^[[:space:]]*[-*_ ]*telegraph-waiver[*_ ]*:' "$1" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# token_shown <token> <text>: does the text use this operator?
#
# A token made only of word characters matches on a WORD BOUNDARY; anything
# with a symbol in it matches as a substring. The boundary is not decoration:
# `pc` as a substring matches `pcal` in the `chksum(pcal)` marker pcal itself
# writes into every translation, so a substring test reports a leak in every
# PlusCal item whether or not its answer touches `pc`. The same bug bit
# drill-gate.sh's rc reader, where a module called Commit picked up the prose
# word "Committed" (drill-gate.sh:1147-1155).
# ---------------------------------------------------------------------------
token_shown() {
  case "$1" in
    *[!A-Za-z0-9_]*) [[ "$2" == *"$1"* ]] ;;
    *) grep -qE "(^|[^A-Za-z0-9_])$1([^A-Za-z0-9_]|$)" <<<"$2" ;;
  esac
}

# ---------------------------------------------------------------------------
# run_signature <dir> <stem>...: the comma-joined rc of every machine, run in
# order, out of <dir>.
#
# Straight through harness/verdict.sh, which is CENTRALLY OWNED
# (.claude/rules/dispatched-agents.md) and never edited here. No TLC console
# text is read, which is V2-PLAN.md §5.1.
#
# -d WHEN THE .cfg SAYS CHECK_DEADLOCK TRUE. TLC's deadlock checking is an AND
# across the keyword and the flag, and verdict.sh REFUSES a disagreement at
# rc 99 rather than producing a verdict over a check that did not happen. Same
# call as completion/verify-item.sh and harness/reading-gate.sh:362-365. No
# landed item carries the keyword today, which is why this is insurance.
# ---------------------------------------------------------------------------
SIGNATURE=""
run_signature() {
  local dir="$1"; shift
  local stem rc args
  SIGNATURE=""
  for stem in "$@"; do
    args=()
    if grep -qE '^[[:space:]]*CHECK_DEADLOCK[[:space:]]+TRUE' "${dir}/${stem}.cfg"; then
      args=(-d)
    fi
    rc=0
    "$VERDICT" --timeout "$TIMEOUT" -q "${args[@]+"${args[@]}"}" \
      -c "${dir}/${stem}.cfg" "${dir}/${stem}.tla" >/dev/null 2>&1 || rc=$?
    SIGNATURE="${SIGNATURE}${SIGNATURE:+, }${rc}"
  done
}

echo "completion-gate.sh: ${ROOT}"

# ---------------------------------------------------------------------------
# The item sweep. Every depth-2 directory under the root, the same shape
# harness/reading-gate.sh:377 and harness/drill-gate.sh:1315 use, so
# <family>/<NN>-<slug> is an item and a family directory is not.
#
# The hidden-directory predicate is ANCHORED AT THE ROOT. A bare
# `! -path '*/.*'` matches the root itself, since every dispatched worker here
# runs under .claude/worktrees/agent-*, and the sweep would then find nothing
# on any real tree. Recorded in harness/test-drill.sh's part 3.
# ---------------------------------------------------------------------------
while IFS= read -r item; do
  rel="${item#"${ROOT}"/}"
  item_n=$((item_n + 1))

  expect="${item}/EXPECT"
  answer="${item}/ANSWER.md"
  meta="${item}/META.md"
  prompt="${item}/PROMPT.md"
  work="${item}/work"
  claims="${work}/Claims.tla"

  # --- shape: the five parts every later check reads ----------------------
  shape_ok=1
  if [ ! -f "$expect" ]; then
    finding "SHAPE-NO-EXPECT" "$rel" "no EXPECT; completion/verify-item.sh reads it to know what to run"
    shape_ok=0
  fi
  if [ ! -f "$answer" ]; then
    finding "SHAPE-NO-ANSWER" "$rel" "no ANSWER.md; checks 1 and 2 need the reference bodies"
    shape_ok=0
  fi
  if [ ! -f "$meta" ]; then
    finding "SHAPE-NO-META" "$rel" "no META.md; it is where a telegraph-waiver lives and where the constructs are declared"
    shape_ok=0
  fi
  if [ ! -f "$prompt" ]; then
    finding "SHAPE-NO-PROMPT" "$rel" "no PROMPT.md; it is the brief, and check 3 scans it"
    shape_ok=0
  fi
  if [ ! -d "$work" ]; then
    finding "SHAPE-NO-WORK" "$rel" "no work/; the machines and the file the learner edits both live there"
    shape_ok=0
  elif [ ! -f "$claims" ]; then
    finding "SHAPE-NO-CLAIMS" "$rel" "no work/Claims.tla; that is the file the learner edits"
    shape_ok=0
  fi
  if [ "$shape_ok" = "0" ]; then
    continue
  fi

  # --- EXPECT rows --------------------------------------------------------
  STEMS=()
  WANTS=()
  rows_ok=1
  while IFS= read -r row; do
    case "$row" in ""|\#*) continue ;; esac
    case "$row" in
      *$'\t'*) : ;;
      *)
        finding "EXPECT-BAD-ROW" "$rel" "row '${row}' is not <stem><TAB><rc>"
        rows_ok=0
        continue
        ;;
    esac
    s="${row%%$'\t'*}"
    w="${row##*$'\t'}"
    case "$w" in
      ''|*[!0-9]*)
        finding "EXPECT-BAD-ROW" "$rel" "row '${row}' records '${w}', which is not an exit code"
        rows_ok=0
        continue
        ;;
    esac
    STEMS+=("$s")
    WANTS+=("$w")
  done < "$expect"

  if [ "${#STEMS[@]}" -eq 0 ]; then
    finding "EXPECT-EMPTY" "$rel" "EXPECT names no machine"
    continue
  fi
  if [ "$rows_ok" = "0" ]; then
    continue
  fi
  if [ "${WANTS[0]}" != "0" ]; then
    finding "EXPECT-FIRST-NOT-ZERO" "$rel" \
      "row 1 is '${STEMS[0]}' at rc ${WANTS[0]}; row 1 is the CORRECT machine and must record 0"
    continue
  fi

  # --- check 5: every EXPECT stem resolves --------------------------------
  resolve_ok=1
  for s in "${STEMS[@]}"; do
    if [ ! -f "${work}/${s}.tla" ]; then
      finding "EXPECT-NO-TLA" "$rel" "EXPECT names '${s}' and work/${s}.tla does not exist"
      resolve_ok=0
    fi
    if [ ! -f "${work}/${s}.cfg" ]; then
      finding "EXPECT-NO-CFG" "$rel" "EXPECT names '${s}' and work/${s}.cfg does not exist"
      resolve_ok=0
    fi
  done
  [ "$resolve_ok" = "1" ] && say "  OK    ${rel}  ${#STEMS[@]} EXPECT stem(s) resolve"

  # --- check 4: no stray file under work/ ---------------------------------
  # The accounted set is Claims.tla plus <stem>.tla and <stem>.cfg per row.
  # Built as a padded string and matched with a case glob, so one pass over
  # the tree answers for every entry without a fork each time.
  accounted=" Claims.tla "
  for s in "${STEMS[@]}"; do
    accounted="${accounted}${s}.tla ${s}.cfg "
  done
  stray_ok=1
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    sub="${entry#"${work}"/}"
    if [ -d "$entry" ]; then
      finding "WORK-STRAY-DIR" "$rel" \
        "work/${sub}/ is a directory; scripts/deliver-completion.sh delivers work/ recursively"
      stray_ok=0
      continue
    fi
    case "$accounted" in
      *" ${sub} "*) ;;
      *)
        finding "WORK-STRAY-FILE" "$rel" \
          "work/${sub} is accounted for by no EXPECT stem; it would be delivered to the learner"
        stray_ok=0
        ;;
    esac
  done < <(find "$work" -mindepth 1 | sort)
  [ "$stray_ok" = "1" ] && say "  OK    ${rel}  work/ holds nothing EXPECT does not account for"

  # --- the holes, and the format check over ANSWER.md ---------------------
  HOLES=()
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    HOLES+=("$h")
  done < <(sed -n 's/^\([A-Za-z][A-Za-z0-9_]*\)[[:space:]]*==[[:space:]]*FILL_IN.*$/\1/p' "$claims")

  if [ "${#HOLES[@]}" -eq 0 ]; then
    finding "CLAIMS-NO-HOLE" "$rel" \
      "work/Claims.tla has no '<Name> == FILL_IN...' line, so the item asks for nothing"
    continue
  fi

  # A FILL_IN marker the gate cannot rewrite is a FINDING and never a pass.
  # Comments are stripped first: every Claims.tla's own header says "Replace
  # each FILL_IN marker", and completion/verify-item.sh records that a raw
  # grep matches the instruction.
  uncommented="$(sed 's/\\[*].*//' "$claims")"
  marker_n="$(grep -c 'FILL_IN' <<<"$uncommented")"
  if [ "$marker_n" != "${#HOLES[@]}" ]; then
    finding "CLAIMS-UNPARSED-HOLE" "$rel" \
      "${marker_n} FILL_IN marker(s) outside a comment, ${#HOLES[@]} of them on a '<Name> ==' line"
    continue
  fi

  block="$(answer_block "$answer")"
  if [ -z "${block//[[:space:]]/}" ]; then
    finding "ANSWER-NO-BLOCK" "$rel" \
      "ANSWER.md carries no fenced code block; the reference bodies are read from the first one"
    continue
  fi

  # A HOLE THE ITEM SHIPPED ALREADY FILLED. ANSWER.md defines a body for every
  # hole, so a name defined there with no FILL_IN line beside it in Claims.tla
  # is a hole the learner is handed rather than asked for. This is the second
  # half of bead tla-4yit's RED spec, and it is reported BEFORE the machine
  # count below because that count would otherwise report the same defect
  # without naming the hole.
  prefilled_ok=1
  while IFS= read -r anm; do
    [ -n "$anm" ] || continue
    is_hole=0
    for h in "${HOLES[@]}"; do
      [ "$h" = "$anm" ] && is_hole=1
    done
    [ "$is_hole" = "1" ] && continue
    shipped="$(sed -n "s/^${anm}[[:space:]]*==[[:space:]]*\(.*\)$/\1/p" "$claims" | sed -n 1p)"
    detail="ANSWER.md defines '${anm}' and work/Claims.tla carries no '${anm} == FILL_IN' line"
    if [ -n "$shipped" ]; then
      detail="${detail}; it already reads '${anm} == ${shipped}'"
    fi
    finding "CLAIMS-HOLE-PREFILLED" "$rel" \
      "${detail}, so that hole is handed over rather than asked for"
    prefilled_ok=0
  done < <(sed -n 's/^\([A-Za-z][A-Za-z0-9_]*\)[[:space:]]*==.*$/\1/p' <<<"$block")
  if [ "$prefilled_ok" = "0" ]; then
    continue
  fi

  # The POSITIONAL correspondence, checked rather than assumed: one correct
  # machine plus one broken machine per hole.
  if [ "${#STEMS[@]}" -ne "$(( ${#HOLES[@]} + 1 ))" ]; then
    finding "HOLE-MACHINE-COUNT" "$rel" \
      "${#HOLES[@]} hole(s) and ${#STEMS[@]} machine(s); EXPECT must hold one correct machine plus one per hole"
    continue
  fi

  BODIES=()
  bodies_ok=1
  for h in "${HOLES[@]}"; do
    b="$(claim_body "$h" "$block")"
    if [ -z "${b//[[:space:]]/}" ]; then
      finding "ANSWER-NO-BODY" "$rel" \
        "ANSWER.md's first fenced block carries no '${h} ==' definition, so the reference answer for that hole cannot be read"
      bodies_ok=0
      b=""
    fi
    BODIES+=("$b")
  done
  if [ "$bodies_ok" = "0" ]; then
    continue
  fi
  say "  OK    ${rel}  ${#HOLES[@]} reference body(ies) read from ANSWER.md"

  # --- check 3: no telegraph, per operator, over every shown file ---------
  # Waivers first, so the scan can honour them. Echoed unconditionally.
  WAIVED=()
  wv="$(waiver_lines "$meta")"
  if [ -n "$wv" ]; then
    while IFS= read -r wline; do
      [ -n "$wline" ] || continue
      wbody="${wline#*:}"
      wtok="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*\(--\|—\).*$//' \
                  -e 's/[[:space:]]*$//' -e 's/^`//' -e 's/`$//' <<<"$wbody")"
      wreason="$(sed -n 's/.*\(--\|—\)[[:space:]]*//p' <<<"$wbody")"
      if [ -z "$wtok" ]; then
        finding "TELEGRAPH-WAIVER-EMPTY" "$rel" "telegraph-waiver names no token"
        continue
      fi
      if [ "${#wreason}" -lt "$WAIVER_REASON_MIN" ]; then
        finding "TELEGRAPH-WAIVER-NO-REASON" "$rel" \
          "waiver for '${wtok}' carries no reason; a waiver without one is an exemption"
        continue
      fi
      WAIVED+=("$wtok")
      printf 'WAIVER    %-34s %-12s %s\n' "$rel" "$wtok" "$wreason"
    done <<<"$wv"
  fi

  # EVERY FILE THE LEARNER SEES. The delivery manifest, read off
  # scripts/deliver-completion.sh's header: PROMPT.md, EXPECT, work/ whole.
  shown=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    shown="${shown}$(cat "$f")"$'\n'
  done < <(printf '%s\n%s\n' "$prompt" "$expect"; find "$work" -mindepth 1 -type f | sort)

  answer_text="$(printf '%s\n' "${BODIES[@]}")"
  tele_ok=1
  for tok in "${TELEGRAPH_TOKENS[@]}"; do
    token_shown "$tok" "$answer_text" || continue
    is_waived=0
    for w in "${WAIVED[@]+"${WAIVED[@]}"}"; do
      [ "$w" = "$tok" ] && is_waived=1
    done
    [ "$is_waived" = "1" ] && continue
    if token_shown "$tok" "$shown"; then
      finding "TELEGRAPH-SHOWN" "$rel" \
        "the reference answer uses '${tok}' and a delivered file shows it; waive it in META.md with 'telegraph-waiver: ${tok} -- <reason>' if it cannot be hidden"
      tele_ok=0
    fi
  done
  [ "$tele_ok" = "1" ] && say "  OK    ${rel}  no operator of the reference answer appears in a delivered file"

  # --- checks 1 and 2: the TLC half ---------------------------------------
  if [ "$STATIC_ONLY" = "1" ]; then
    static_n=$((static_n + 1))
    continue
  fi
  if [ "$NO_TLC" = "1" ]; then
    unchecked "one-machine-per-hole" "$rel" \
      "${#HOLES[@]} hole(s) to measure: --no-tlc was asked for, so the check was not run"
    continue
  fi

  w="${SCRATCH}/${rel//\//-}"

  # build <TRUE hole name>... : a scratch copy of work/ whose Claims.tla has
  # every hole filled from ANSWER.md except the named ones, which get TRUE.
  build() {
    local trues=" $* " out="" line name i
    rm -rf "$w"
    mkdir -p "$w"
    cp -R "${work}/." "${w}/"
    while IFS= read -r line; do
      name="$(sed -n 's/^\([A-Za-z][A-Za-z0-9_]*\)[[:space:]]*==[[:space:]]*FILL_IN.*$/\1/p' <<<"$line")"
      if [ -z "$name" ]; then
        out="${out}${line}"$'\n'
        continue
      fi
      case "$trues" in
        *" ${name} "*) out="${out}${name} == TRUE"$'\n' ;;
        *)
          for i in "${!HOLES[@]}"; do
            [ "${HOLES[$i]}" = "$name" ] && out="${out}${BODIES[$i]}"$'\n'
          done
          ;;
      esac
    done < "$claims"
    printf '%s' "$out" >"${w}/Claims.tla"
  }

  recorded=""
  for want in "${WANTS[@]}"; do
    recorded="${recorded}${recorded:+, }${want}"
  done

  build
  run_signature "$w" "${STEMS[@]}"
  reference="$SIGNATURE"

  if [ "$reference" != "$recorded" ]; then
    finding "REFERENCE-SIGNATURE" "$rel" \
      "ANSWER.md's claims score '${reference}' and EXPECT records '${recorded}'; every delta below would be measured against a number nobody checked"
    continue
  fi
  say "  OK    ${rel}  the reference answer scores EXPECT's '${recorded}'"

  # Check 1, one hole at a time.
  for i in "${!HOLES[@]}"; do
    h="${HOLES[$i]}"
    build "$h"
    run_signature "$w" "${STEMS[@]}"
    mutant="$SIGNATURE"

    # The positions that moved, 1-based over EXPECT rows.
    moved=""
    IFS=', ' read -r -a MUT <<<"$mutant"
    for j in "${!WANTS[@]}"; do
      if [ "${MUT[$j]:-}" != "${WANTS[$j]}" ]; then
        moved="${moved}${moved:+ }$((j + 1))"
      fi
    done

    own="$(( i + 2 ))"
    if [ "$moved" = "$own" ]; then
      say "  OK    ${rel}  hole ${h} is caught by '${STEMS[$own - 1]}' and by nothing else"
      continue
    fi
    case " $moved " in
      *" $own "*)
        finding "HOLE-OVERLAP" "$rel" \
          "${h} == TRUE scores '${mutant}' against '${reference}', moving position(s) ${moved}; only ${own} (${STEMS[$own - 1]}) answers to this hole"
        ;;
      *)
        finding "HOLE-UNCHECKED" "$rel" \
          "${h} == TRUE scores '${mutant}', unmoved at position ${own} (${STEMS[$own - 1]}), so nothing catches this hole"
        ;;
    esac
  done

  # Check 2.
  build "${HOLES[@]}"
  run_signature "$w" "${STEMS[@]}"
  if [ "$SIGNATURE" = "$reference" ]; then
    finding "HOLES-NOT-FALSIFIABLE" "$rel" \
      "every hole at TRUE scores the reference '${reference}', so the item grades a claim that says nothing as correct"
  else
    say "  OK    ${rel}  every hole at TRUE scores '${SIGNATURE}', not the reference"
  fi
  rm -rf "$w"
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "${ROOT}/.*" | sort)

if [ "$item_n" -eq 0 ]; then
  unchecked "items" "$ROOT" \
    "no item found; an item is <family>/<NN>-<slug> at depth 2 under the root"
fi

# ===========================================================================
# THE MODE BLOCK — what a tier that exits 0 did NOT measure.
#
# A MODE THAT EXITS 0 WITHOUT SAYING WHAT IT LEFT OUT IS THE DEFECT. The
# count does not exist until the sweep has walked every item, so the block
# sits here rather than in the banner, and it prints through `echo` so `-q`
# cannot suppress it: an honesty statement is not a per-item OK line.
#
# THE ADMISSION IS SPELLED IN harness/test-indeterminate.sh's VOCABULARY, ON
# PURPOSE, and the waiving flag is NAMED IN PARENTHESES. That suite's
# PARENTHETICAL RULE makes a voluntary skip tellable from an involuntary one:
# an admission naming the caller flag behind it is legitimate at rc 0, one
# that names no flag must carry 99. Phrasing this line to dodge the nine
# phrases would hide a skip admission from the only gate that looks for it,
# which is the defect that suite exists for one level up. Keep both halves on
# ONE line; the suite tests the waiver per line.
#
# THE WORD IS `skipped` AND IT WAS `were not run`, which is worth recording
# because the first version dodged the vocabulary by GRAMMAR rather than by
# intent. SKIP_VOCAB carries `was not run`, singular; this line's subject is
# two checks, so "Checks 1 and 2 were not run" matched nothing and the census
# could not see an admission riding an rc 0. Measured 2026-10-14: the census
# reached this file through lines 339 and 723 and not through this one.
# ===========================================================================
if [ "$STATIC_ONLY" = "1" ]; then
  echo
  echo "completion-gate.sh: --static-only. ${static_n} item(s) whose holes were not measured, no TLC ran."
  echo "Checks 1 and 2 were skipped (--static-only), which is the scope the caller asked for."
  echo "NOT COVERED HERE: whether each hole is still caught by exactly one machine."
  echo "The slow row of harness/test-completion-gate.sh and scripts/cibuild run that."
  echo "This run answers whether the corpus is STRUCTURALLY sound and nothing more."
fi

# ===========================================================================
echo
echo "completion-gate.sh: ${item_n} item(s), ${finding_n} finding(s), ${unchecked_n} unchecked"

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
