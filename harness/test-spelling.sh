#!/usr/bin/env bash
# test-spelling.sh — the British-spelling gate for bead tla-nv5q.
#
# THE DRIFT. The v2 corpus went British while v1 and every project-level doc
# stayed American, and nobody decided that. Frank ruled American on
# 2026-10-14, for three reasons: the frank-writing skill says so, having been
# built by measuring 26,380 words of his own prose; v1 and the project docs
# already are; and the drill prose ships under his name. So the British forms
# in v2 are agent drift, and the job is to fix the drift rather than bless it.
#
# WHY A GATE AND NOT A SWEEP. The drift ran for two months before anyone
# measured it. A one-time sweep comes back, and this one would come back the
# same silent way, because no reader of a single file can see that the tree
# disagrees with itself. Gate-don't-advise.
#
# THIS CANNOT BE A WHOLE-WORD SCAN, and that is the one design constraint
# worth stating up front. The phase-1 pass counted 318 sites with `\b`
# anchors and the real number was 339. The 21 it missed came in three shapes:
#
#   1. a pair word inside a compound identifier -- `Neighbours` in
#      `NeighboursOnly`, `Colour` in `NeverOneColour`;
#   2. a subscript -- `_colour` in `[][Next]_colour`. The underscore is a word
#      character, so `\b` never matches there at all;
#   3. a form absent from the list -- `travelling` had no entry, so nothing
#      reached it.
#
# Shapes 1 and 2 are why PAT below matches substrings, and shape 3 is why the
# list carries `travelling` and `unlabelled`. The substring reading is safe
# for these particular words, which is a fact about the list rather than about
# substring matching: `analyse` does not appear inside `analysis`, and a stem
# match on `analys` was tried first and returned garbage. Add a pair only
# after checking it the same way.
#
# Usage:  harness/test-spelling.sh
# Exit:   0 if every assertion holds, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# ---------------------------------------------------------------------------
# THE PAIR LIST.
#
# Clean discriminating pairs only. A first pass that took `analysis`,
# `license` as a noun and `center` inside CSS returned noise rather than
# sites, so each entry here is a word whose two spellings mean the same thing
# and differ only by dialect.
#
# Longest first within a family, because POSIX ERE is leftmost-longest and
# the report should name `neighbours` rather than `neighbour` when both could
# match at one position.
# ---------------------------------------------------------------------------
PAIRS=(
  "neighbouring:neighboring"
  "neighbours:neighbors"
  "neighbour:neighbor"
  "recognisable:recognizable"
  "recognising:recognizing"
  "recognised:recognized"
  "recognise:recognize"
  "organisation:organization"
  "organised:organized"
  "organise:organize"
  "behaviours:behaviors"
  "behaviour:behavior"
  "coloured:colored"
  "colours:colors"
  "colour:color"
  "favours:favors"
  "favour:favor"
  "labour:labor"
  "centres:centers"
  "centre:center"
  "analysed:analyzed"
  "analyse:analyze"
  "modelling:modeling"
  "modelled:modeled"
  "cancelled:canceled"
  "unlabelled:unlabeled"
  "labelling:labeling"
  "labelled:labeled"
  "travelling:traveling"
)

# Derived, never hand-maintained. A literal pattern written out beside the
# array is the shape that drifts out of step with it.
PAT=""
for pair in "${PAIRS[@]}"; do
  PAT="${PAT}${PAT:+|}${pair%%:*}"
done

american_for() {
  local want="$1" pair
  for pair in "${PAIRS[@]}"; do
    if [ "${pair%%:*}" = "$want" ]; then
      printf '%s\n' "${pair#*:}"
      return 0
    fi
  done
  printf '?\n'
}

# ---------------------------------------------------------------------------
# THE ROOTS.
#
# Add a ROOT here, never an individual file. The whole point is that a file
# written tomorrow is covered without anyone remembering to enroll it, which
# is why selection runs over `git ls-files` rather than over a list.
#
# These seven roots read 0 British sites on 2026-10-14, measured after the
# phase-2 sweep landed. Each floor below sits well under the tracked-file
# count that day, so it asserts that a root is still being walked rather than
# how big it has grown.
# ---------------------------------------------------------------------------
SCAN_ROOTS=(drill completion reading harness exercises module-docs chapter)

# root:floor, measured 2026-10-14. Tracked file counts that day were
# drill 1255, completion 101, reading 75, harness 287, exercises 378,
# module-docs 6, chapter 47.
ROOT_FLOORS=(
  "drill:900"
  "completion:70"
  "reading:50"
  "harness:200"
  "exercises:250"
  "module-docs:4"
  "chapter:30"
)

# ---------------------------------------------------------------------------
# WHAT IS DELIBERATELY NOT A ROOT, and why each one is out.
#
# A gate that passes by being narrow is worth less than no gate, so the
# uncovered areas are named here with the count each carried on 2026-10-14
# rather than left for somebody to rediscover.
#
# OUT OF SCOPE BY ERA. `puzzles/` (9 sites) and `authoring/` (141) are v1.
# v2 replaces the content and not the infrastructure, so v1 stays untouched by
# v2 beads, and both were already majority-American before any of this
# started. Excluding them keeps the gate honest about what it covers. Folding
# them in would turn a v2 consistency gate into a v1 rewrite.
#
# GENERATED. `docs/` is build output from `module-docs/`, gitignored and
# destroyed on the next build, so the root above it is the one that matters.
# `.beads/issues.jsonl` (80) is the tracker export, and most of its hits are
# this bead's own description quoting the pair list.
#
# STILL CARRYING THE DRIFT, which is the honest reason rather than a policy
# one. These are v2 and they belong in the gate. They are out only because
# phase 2's footprint did not reach them, and every one is a worklist entry:
#
#   sources/           242     problem sources
#   curated/            18     curated problems
#   pilot/              12
#   top-level files      7     was 24; central cleared 17 on 2026-10-14
#   corpus/              7
#   scripts/             1     build-docs.sh, in a comment
#   .github/             1     verify-puzzles.yml, in a comment
#
# That is 288 sites. Clear a root and move it up into SCAN_ROOTS with a floor,
# which is a two-line change and the point of the layout.
#
# THE TOP LEVEL IS THE EXCEPTION, and it needs a third kind of exemption this
# file does not have yet. Its 7 remaining sites are not drift and not a
# deferral. One is the ModelledFloor citation at V2-PLAN.md:977, already
# covered by the token exemption below. The other six are inside `>`
# blockquotes that reproduce earlier briefs and drawers verbatim, at
# V2-PLAN.md:1249, 1774, 1790, 1792, 1801 and 2044. Rewording a quotation
# makes it an inexact quotation, so those are correct as they stand.
#
# Both existing exemption kinds say in their own comments that they are a
# deferral rather than a judgment that the spelling is right. A verbatim
# quotation is the opposite: a standing judgment that it IS right. Promoting
# the top level means adding that third category rather than reusing either of
# these, which is why it did not happen in the same pass that cleared the 17.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# PART 1 — the tree is American across the scanned roots.
# ---------------------------------------------------------------------------

# Every tracked file under the roots. Tracked rather than found, so build
# output and scratch directories never enter, and the question the gate
# answers stays "what does this repo publish".
SELECTED=()
select_scan_files() {
  SELECTED=()
  local f
  # stderr is dropped because the control in part 2 hands this a path outside
  # the repository on purpose, and git says so loudly. The assertion there is
  # that nothing comes back, which is the property worth pinning.
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    SELECTED+=("$f")
  done < <(git ls-files -- "$@" 2>/dev/null | sort)
}

# Narrows a file list to the ones that could possibly report a finding, in ONE
# grep rather than one per file.
#
# This is a COST fix and worth a note, because the obvious loop is 20x slower.
# Reading each file and grepping it separately costs two forks per file, and
# over the 2149 tracked files under the roots that measured 10.2 to 10.5 s --
# which would have made this the most expensive row in the fast tier by more
# than 2x, for a suite that runs no TLC at all. One grep over the whole list
# narrows 2149 files to the handful that match, and only those pay for the
# detailed pass below. Measured after the change: 0.194 to 0.205 s over three
# back-to-back serial runs, so a 50x saving.
#
# `-I` skips binary files, which is right for a gate over prose: a pair word
# inside a compiled artifact is not a spelling anybody reads.
CANDIDATES=()
narrow_to_candidates() {
  CANDIDATES=()
  local f
  while IFS= read -r f; do
    [ -n "$f" ] && CANDIDATES+=("$f")
  done < <(grep -lIiE -- "$PAT" "$@" 2>/dev/null | sort)
}

# Sets the global FINDINGS rather than echoing it, so the exemption counters
# below survive. A command substitution would run this in a subshell and throw
# every increment away.
FINDINGS=""
FINDING_COUNT=0
collect_findings() {
  local f content hits h form i tok pad occ n
  FINDINGS=""
  FINDING_COUNT=0
  for f in "$@"; do
    content=$(cat "$f" 2>/dev/null) || continue

    # Blank the protected names BEFORE matching rather than comparing against
    # the matched form afterwards, which is the shape that does not work: PAT
    # matches `Modelled` INSIDE `ModelledFloor`, so the form a match reports is
    # never the whole token. Each name goes to a run of underscores of its own
    # length, which keeps every line number and column where it was and cannot
    # itself match, since `_` is in no pair.
    for i in "${!EXEMPT_TOKENS[@]}"; do
      tok="${EXEMPT_TOKENS[$i]}"
      case "$content" in
      *"$tok"*) ;;
      *) continue ;;
      esac
      occ=$(grep -oF -- "$tok" <<<"$content")
      n=$(grep -c . <<<"$occ" || true)
      TOKEN_HITS[i]=$((TOKEN_HITS[i] + n))
      pad=$(printf '%*s' "${#tok}" '' | tr ' ' '_')
      content=${content//"$tok"/$pad}
    done

    # Here-string, not a pipe. The harness bans the live-pipe shape outright,
    # because an early-exiting consumer returns 141 under pipefail and an `if`
    # reads that as "no hits" -- a clean report from a check that never ran.
    # See harness/test-pipefail.sh.
    hits=$(grep -noiE -- "$PAT" <<<"$content")
    [ -n "$hits" ] || continue
    while IFS= read -r h; do
      [ -n "$h" ] || continue
      form=${h#*:}
      exempt "$f" "$form" && continue
      FINDINGS="$FINDINGS
      $f:${h%%:*}  $form -> $(american_for "$(printf '%s' "$form" | tr '[:upper:]' '[:lower:]')")"
      FINDING_COUNT=$((FINDING_COUNT + 1))
    done <<<"$hits"
  done
}

# ---------------------------------------------------------------------------
# THE EXEMPTIONS.
#
# Two kinds, and both are counted rather than open-ended, so an exemption
# cannot quietly grow to cover a site nobody named.
#
# EXEMPT_TOKENS holds a literal that is a NAME in this tree rather than a
# word. EXEMPT_FILES holds a path with the exact number of sites it is allowed
# to carry. Exact, not a ceiling: a site removed makes the entry stale and a
# site added is a new finding, and the gate says so either way.
# ---------------------------------------------------------------------------
# `ModelledFloor` is a MODULE name, so also a file name, and renaming it is
# not phase 2's to do. Its cross-reference lives at V2-PLAN.md:977, outside
# this bead's footprint, and leaving that reference dangling is worse than
# leaving the name British for now. The token is exempt everywhere rather than
# per file, because the two readers that cite it (the vacuity README and
# test-vacuity.sh) cite it correctly and should not each need an entry.
#
# Note what this exemption does NOT cover: the bare operator `Modelled`, which
# is the same name minus its suffix. That is why the two ModelledFloor files
# carry their own entries below.
EXEMPT_TOKENS=(
  "ModelledFloor"
)
TOKEN_WHY=(
  "a module name, hence a file name; its cross-reference at V2-PLAN.md:977 is outside bead tla-nv5q phase 2's footprint"
)

# Both entries are a deferral and neither is a judgment that the spelling is
# right. Each says who owns the file and what has to happen before the entry
# can go.
EXEMPT_FILES=(
  "harness/verdict.sh|6"
  "harness/fixtures/vacuity/ModelledFloor.tla|2"
  "harness/fixtures/vacuity/ModelledFloor.cfg|1"
)
FILE_WHY=(
  "centrally owned by bead tla-kl5.4 and read-only to dispatched workers, even for a comment. All 6 sites are comments, and central's own pass clears them"
  "renaming the module means renaming the file and the V2-PLAN.md:977 reference with it. The 2 counted here are the bare operator Modelled at line 28 and the word modelled in the line 7 comment"
  "the .cfg half of the same module, where INVARIANT Modelled names that operator"
)

TOKEN_HITS=()
FILE_HITS=()
for i in "${!EXEMPT_TOKENS[@]}"; do TOKEN_HITS[i]=0; done
for i in "${!EXEMPT_FILES[@]}"; do FILE_HITS[i]=0; done

# Files only. The token exemptions are spent in collect_findings, before
# matching, for the reason the comment there gives.
exempt() {
  local file="$1" form="$2" i key
  for i in "${!EXEMPT_FILES[@]}"; do
    key=${EXEMPT_FILES[$i]%%|*}
    if [ "$file" = "$key" ]; then
      FILE_HITS[i]=$((FILE_HITS[i] + 1))
      return 0
    fi
  done
  return 1
}

# Self-exclusion, and it is not a courtesy. This file carries the pair list,
# a header naming the three shapes a whole-word scan misses, and two planted
# control files, so it necessarily contains every British word the gate bans.
# It is the one file in the tree allowed to. Every file that warns against a
# string contains that string, which is why harness/test-pipefail.sh carries
# the same exclusion for the same reason.
#
# THE TRAP THIS WALKED INTO, worth keeping because the green was false rather
# than merely early. The suite passed its whole RED-to-GREEN cycle without
# this line, because selection reads the index and the file was still
# untracked. It went red on the first run after `git add`, at 69 self-hits. A
# gate that scans tracked files and names what it bans is green until the
# moment it is committed, so run it once more after staging.
SELF="harness/test-spelling.sh"

select_scan_files "${SCAN_ROOTS[@]}"

SCANNED=()
self_seen=0
for f in "${SELECTED[@]}"; do
  if [ "$f" = "$SELF" ]; then
    self_seen=1
    continue
  fi
  SCANNED+=("$f")
done

echo "== part 1: ${SCAN_ROOTS[*]} are American =="

# Pinned, because the exclusion is only sound while it covers exactly this
# file. If this suite is renamed and SELF is not, the gate starts scanning
# its own pair list and goes red for a reason that has nothing to do with the
# tree. The other direction matters as much: a SELF that matches nothing is
# an exclusion nobody is using, and the next person to add a second entry
# should have to notice that.
if [ "$self_seen" -eq 1 ]; then
  ok "self-exclusion covers $SELF, and it is tracked"
else
  nope "self-exclusion names $SELF, which is not in the scanned set — rename it in SELF or the gate will scan its own pair list"
fi

check_root() {
  local root="$1" floor="$2" f n=0
  for f in "${SELECTED[@]}"; do
    case "$f" in "$root"/*) n=$((n + 1)) ;; esac
  done
  if [ "$n" -ge "$floor" ]; then
    ok "scan covers $root/ — $n tracked files"
  else
    nope "scan found only $n tracked files under $root/ (floor $floor) — the gate is not covering that root"
  fi
}

# One assertion PER ROOT, never one over the total. A single total goes green
# on drill/ alone, so it could not tell "chapter/ is covered" from "chapter/
# silently dropped out of the listing". Every ban below reports "found
# nothing", and that reads the same whether the scan is clean or blind.
for entry in "${ROOT_FLOORS[@]}"; do
  check_root "${entry%%:*}" "${entry#*:}"
done

narrow_to_candidates "${SCANNED[@]}"
collect_findings "${CANDIDATES[@]}"
if [ "$FINDING_COUNT" -eq 0 ]; then
  ok "no British spelling under ${SCAN_ROOTS[*]}"
else
  nope "$FINDING_COUNT British spelling site(s) found:$FINDINGS"
fi

# An exemption that matches nothing is a standing waiver for a site that no
# longer exists, which is how an exemption list rots into a blanket one.
# Delete the entry rather than carrying it.
stale=""
for i in "${!EXEMPT_TOKENS[@]}"; do
  if [ "${TOKEN_HITS[$i]}" -eq 0 ]; then
    stale="$stale
      token ${EXEMPT_TOKENS[$i]}  (${TOKEN_WHY[$i]})"
  fi
done
for i in "${!EXEMPT_FILES[@]}"; do
  key=${EXEMPT_FILES[$i]%%|*}
  want=${EXEMPT_FILES[$i]#*|}
  got=${FILE_HITS[$i]}
  if [ "$got" -ne "$want" ]; then
    stale="$stale
      $key  expected $want site(s), found $got  (${FILE_WHY[$i]})"
  fi
done
if [ -z "$stale" ]; then
  ok "all ${#EXEMPT_TOKENS[@]} token and ${#EXEMPT_FILES[@]} file exemptions match their recorded counts"
else
  nope "an exemption no longer matches what it was written for:$stale"
fi

# ---------------------------------------------------------------------------
# PART 2 — controls on the scanner itself.
#
# Every assertion in part 1 is of the form "found nothing", which is what a
# scanner that quietly stopped working also reports. One typo in PAT, one root
# dropped from the listing, and the gate goes green while covering nothing.
# These plant both directions in synthetic files outside the roots and require
# the scanner to get each one right.
# ---------------------------------------------------------------------------

echo
echo "== part 2: the scanner itself still bites =="

CONTROL_DIR=$(mktemp -d -t tla_spelling_control.XXXXXX)
trap 'rm -rf "$CONTROL_DIR"' EXIT

# The negative control first, because without it the whole suite can pass by
# matching nothing at all.
#
# The two files are a MATCHED PAIR, 13 sites each, one dialect apiece. Reading
# them side by side is what makes the pair list auditable: a word that appears
# in one and not the other is a pair somebody half-added.
AMERICAN_FILE="$CONTROL_DIR/american.md"
{
  printf 'The color of the behavior is the neighbor of the center.\n'
  printf 'We organize, recognize and analyze the modeled labels.\n'
  printf 'An unlabeled canceled traveling favor, analyzed.\n'
} >"$AMERICAN_FILE"

collect_findings "$AMERICAN_FILE"
if [ "$FINDING_COUNT" -eq 0 ]; then
  ok "control: a planted AMERICAN file is clean (the gate is not matching everything)"
else
  nope "control: a planted American file reported $FINDING_COUNT finding(s) — PAT is over-matching:$FINDINGS"
fi

BRITISH_FILE="$CONTROL_DIR/british.md"
{
  printf 'The colour of the behaviour is the neighbour of the centre.\n'
  printf 'We organise, recognise and analyse the modelled labels.\n'
  printf 'An unlabelled cancelled travelling favour, analysed.\n'
} >"$BRITISH_FILE"

collect_findings "$BRITISH_FILE"
if [ "$FINDING_COUNT" -eq 13 ]; then
  ok "control: a planted BRITISH file yields all 13 planted sites"
else
  nope "control: a planted British file yielded $FINDING_COUNT of 13 planted sites — PAT is under-matching:$FINDINGS"
fi

# Shapes 1 and 2 from the header, pinned as their own controls. A whole-word
# scan passes every other assertion in this file and fails these two, so they
# are what stops somebody "tidying" PAT into a `\b`-anchored form.
COMPOUND_FILE="$CONTROL_DIR/compound.tla"
{
  printf -- '---- MODULE Compound ----\n'
  printf 'VARIABLE colour\n'
  printf 'NeighboursOnly == TRUE\n'
  printf 'NeverOneColour == TRUE\n'
  printf 'Spec == Init /\\ [][Next]_colour\n'
  printf '====\n'
} >"$COMPOUND_FILE"

collect_findings "$COMPOUND_FILE"
if [ "$FINDING_COUNT" -eq 4 ]; then
  ok "control: compound identifiers and a subscript are all 4 DETECTED"
else
  nope "control: found $FINDING_COUNT of 4 in compounds and a subscript — a whole-word scan scores 1 here:$FINDINGS"
fi

# The one shape that proves the list is a list of PAIRS and not a stem match.
# `analysis` is American and shares five letters with `analyse`, and a stem
# pass on `analys` was tried during phase 1 and had to be thrown away.
NEARMISS_FILE="$CONTROL_DIR/nearmiss.md"
{
  printf 'The analysis of the license and the central processor.\n'
  printf 'A laboratory organism, recognizance, and a labeled center.\n'
} >"$NEARMISS_FILE"

collect_findings "$NEARMISS_FILE"
if [ "$FINDING_COUNT" -eq 0 ]; then
  ok "control: analysis, license, central, laboratory and organism do NOT trip the gate"
else
  nope "control: a near-miss word tripped the gate — PAT has a stem in it:$FINDINGS"
fi

# Case is preserved by the report rather than flattened, and ALL-UPPER and
# Capitalized both appear in the real tree (`BEHAVIOUR` in a verdict table,
# `Colours` in a constant). A scan that only matched lowercase would pass
# part 1 and miss them.
CASE_FILE="$CONTROL_DIR/cases.md"
{
  printf 'BEHAVIOUR in caps, Behaviour capitalized, behaviour plain.\n'
} >"$CASE_FILE"

collect_findings "$CASE_FILE"
if [ "$FINDING_COUNT" -eq 3 ]; then
  ok "control: all three case forms are detected"
else
  nope "control: found $FINDING_COUNT of 3 case forms:$FINDINGS"
fi

# The selector, exercised the same way. A root that stops being listed makes
# every ban above report "found nothing", so the floors in part 1 are the real
# defense and this proves the function they call still works off a tree.
select_scan_files "$CONTROL_DIR"
if [ "${#SELECTED[@]}" -eq 0 ]; then
  ok "control: an untracked directory selects nothing (the gate reads git, not the filesystem)"
else
  nope "control: selection returned ${#SELECTED[@]} untracked file(s) — it is walking the filesystem rather than the index"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
