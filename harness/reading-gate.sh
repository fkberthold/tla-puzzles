#!/usr/bin/env bash
# reading-gate.sh — the checks over the reading corpus.
#
# The count is left out of that line on purpose. It read "the four checks"
# while the file carried six, which is what a hardcoded count in prose does
# when nothing gates it.
#
# WHAT THE READING CORPUS IS. One item is a COMPLETE, CORRECT, SMALL SPEC
# WITH REAL PROPERTIES, plus one line naming its constructs. There is no
# question and no answer key: Frank reads the model and moves on. Design
# drawer drawer_tla_puzzles_decisions_eb788dc4f6f90f072aced527, beads
# tla-fwkz and tla-fwkz.1.
#
# USAGE
#   harness/reading-gate.sh [OPTIONS] <reading-root>
#
# OPTIONS
#   --no-tlc        skip check 3's TLC runs. Every text check still runs.
#                   This mode can NEVER exit 0. See EXIT CODES.
#   --registry      print the landed subjects and slugs, run no check, exit 0.
#                   This is the list an authoring brief pastes. See CHECK 8.
#   --timeout SECS  per-module TLC budget, passed to verdict.sh (default 120)
#   -q, --quiet     suppress the per-item OK lines. Findings still print.
#   -h, --help      this text
#
# EXIT CODES, the same three this project uses everywhere.
#     0  every check this run asked for ran and passed
#     1  at least one FINDING. Findings outrank unchecked
#    99  no findings, but at least one check COULD NOT RUN. The project-wide
#        CHECK_DID_NOT_RUN code (harness/verdict.sh, bead tla-hl96)
#     2  usage error
#
# ===========================================================================
# CHECK 1 — SHAPE. Exactly three entries per item.
#
#   <Name>.tla   the complete spec, its properties defined in it
#   <Name>.cfg   the INVARIANT / PROPERTY lines, so they are checked
#   USES.md      the constructs, and the recorded rc
#
# Gated because the publishing step in scripts/build-docs.sh NAMES these
# files. A shape that can drift breaks publishing silently — the page would
# render with an empty code block and nothing would say so.
#
# ===========================================================================
# CHECK 2 — THE PHONE BOUND. Two numbers, and they are not equally solid.
#
# Frank's constraint is prose: "something that fits on a few scrolls of a
# phone screen" (2026-10-11), then "I'm ok with it having as many as 3
# screens of scroll on a phone, few enough so I can reasonably keep it in my
# head, but plenty enough to be interesting" (2026-10-12). Prose is not
# checkable and a line count is, so the prose is turned into the two
# constants below. Whether they are the RIGHT numbers is not something
# anybody on this side can answer, because nobody here can see his phone.
#
#   MAX_LINES=60 is DERIVED from the second quote. Three phone screens is
#   roughly 60 to 72 lines of monospace once the page's own heading and the
#   uses line are counted, so 60 lines of spec sits inside it. This replaced
#   a first guess of 40, which bead tla-fwkz.1 recorded and which measurement
#   killed: a PlusCal item with its translation committed has a FLOOR of
#   exactly 40 lines for one variable, one label, one property and no type
#   invariant, so 40 admitted no PlusCal item worth reading.
#
#   MAX_COLS=77 IS FRANK'S NUMBER, set 2026-10-13: "77 is fine, no stress."
#   It replaced a guess of 64 that this gate shipped with. That guess came
#   from the mkdocs-material code font size at a roughly 390px viewport,
#   never from the device.
#
#   77 IS WHAT PUBLISHED PRACTICE READS. Measured 2026-10-12 against the
#   Community Specifications on https://learning.tlapl.us, the calibration
#   target Frank named: CoffeeCan 77 columns, DieHard 78, Stones 77,
#   TeachingConcurrency/Simple 96, SimpleRegular 77. Not one of the five fit
#   the old 64, so every reading item was tighter than every spec on the site
#   it calibrates against. At 77 four of the five fit.
#
#   pcal's widest generated line is 74, the BEGIN TRANSLATION marker carrying
#   its checksums. That fits 77, so the translation exemption below is now
#   insurance rather than necessity. It stays: the author cannot narrow that
#   line, and three assertions hold the exemption to comment-only lines.
#
# AMEND EITHER BY EDITING ITS ONE LINE BELOW. That is the whole edit.
#
# THE ONE EXEMPTION, and it is forced rather than chosen. Comment-only lines
# INSIDE a generated PlusCal translation block are exempt from the COLUMN
# check. They are not exempt from the line count.
#
#   `pcal` writes two comment lines nobody can narrow. Measured on
#   pcal.trans 1.12 over reading/pluscal/01-euclid/Euclid.tla:
#
#     74 cols  \* BEGIN TRANSLATION (chksum(pcal) = "..." /\ chksum(tla) = "...")
#     67 cols  (* Allow infinite stuttering to prevent deadlock on termination. *)
#
#   `-lineWidth` governs the translated BODY and has a floor of 60, and it
#   does not touch either line. So without this exemption NO item with a
#   committed translation can ever pass, whatever its author does — and bead
#   tla-fwkz puts PlusCal in this corpus on purpose, because the 2026-10-12
#   read/write split made recognition the only channel where it is allowed.
#
#   The exemption is narrow for a reason. It covers COMMENT-ONLY lines, so a
#   long generated FORMULA still fails; and only BETWEEN the markers, so an
#   author cannot park a wide comment anywhere else. Every author-written
#   line in all six items is under the bound without it.
#
# ===========================================================================
# CHECK 3 — THE RECORDED rc REPRODUCES, through harness/verdict.sh.
#
# A reading model that does not check is WORSE than no model, because it
# teaches a shape that does not work. USES.md records one rc per item and
# this check reruns it.
#
# harness/verdict.sh IS CENTRALLY OWNED (.claude/rules/dispatched-agents.md).
# This gate calls it and never edits it.
#
# -d IS PASSED WHEN THE .cfg SAYS CHECK_DEADLOCK TRUE, and getting that wrong
# is how a recorded rc 11 fails to reproduce. TLC's deadlock checking is an
# AND across the .cfg keyword and verdict.sh's -d flag, verdict.sh defaults
# -d OFF (verdict.sh:25, :189-195), and it REFUSES a disagreement at rc 99
# rather than producing a verdict over a check that did not happen. Four
# control-state drill items hit exactly this within an hour of the drill gate
# landing. Same call as harness/drill-gate.sh:1947-1965.
#
# ===========================================================================
# CHECK 4 — THE .cfg DECLARES AT LEAST ONE INVARIANT OR PROPERTY.
#
# This is Frank's "there should be interesting PROPERTIES etc for them" made
# checkable. IT CANNOT TEST WHETHER A PROPERTY IS INTERESTING. It can refuse
# a model carrying none, which is the failure it exists for: a spec with no
# obligation is a state machine nobody asserted anything about, and TLC will
# exit 0 over it while checking nothing.
#
# ===========================================================================
# CHECK 5 — A CONSTRUCT IN THE MODULE TEXT IS DECLARED IN USES.md.
#
# THE RULE, settled by bead tla-fwkz.2.8: a construct a reader meets in the
# module text is exercised, so it gets declared. USES.md's second heading
# says "Constructs from other families, also exercised" rather than
# "constructs this item drills", and that wording is what decides it.
#
# The question came from a real divergence. On 2026-10-13 all 8 reading
# modules carried an EXTENDS line and only 2 USES.md files declared it, and
# the tla-fwkz.2.5 author reported that rather than quietly matching the six.
# At 25 items the split was 23 carrying it in the text against 10 declaring
# it. An unenforced convention drifts every wave, which is why this is a
# check and not a sentence in a style note.
#
# WHAT IT CHECKS, AND IN ONE DIRECTION ONLY. Text implies declaration. The
# reverse is deliberately not checked: an item may honestly declare a
# construct whose keyword this scan cannot see, and 7 files carry a prose
# note inside a Constructs section saying why a row is NOT claimed. Those
# notes are the author's judgment and the gate has no business overruling
# them.
#
# WHY THESE SEVEN AND NOT THE OTHER 98 ROWS. drill/INVENTORY.md's rows are
# coarser than operators, and a per-row text scan is only sound where the row
# and the keyword are one to one. K013 "Set relational and algebraic
# operators" covers \cup, \cap and \subseteq together, so no scan can tell
# which of the three a module uses, and a finding over that row would be true
# of the row and false of the module. The seven below have exactly one row
# each and exactly one spelling in the text:
#
#   EXTENDS      K004 (modules)         VARIABLES  K081 (temporal)
#   CONSTANT     K039 (state-space)     UNCHANGED  K085 (temporal)
#   ASSUME       K040 (state-space)     WF_        K095 (temporal)
#                                       SF_        K096 (temporal)
#
# WF_ AND SF_ ARE THE ONE PAIR WORTH ARGUING ABOUT, and they are included
# because K095 and K096 are separate rows, so the scan can tell weak from
# strong. The hazard is the PlusCal route: pcal turns a `fair process` into a
# generated `WF_vars(...)`, and K065 "fair process (weak fairness)" is a
# different row for the same text. That is not a reason to drop the check.
# The translation is committed and read, so a reader does meet the operator,
# and both pluscal items that carry `fair` declare K065 AND K095 together
# (reading/pluscal/02-interleave, 03-contend).
#
# WHERE A DECLARATION GOES is the row's own family column: `## Constructs`
# when the row's family is the item's family, and `## Constructs from other
# families, also exercised` otherwise. All 25 items follow it.
#
# ===========================================================================
# CHECK 6 — USES.md HAS ONE SHAPE, so the probe prose reaches the page.
#
# WHAT WENT WRONG. Most items carry a paragraph saying what to change to make
# the run go red, and that sentence is the only thing in an item that says
# which construct is carrying which property. Every one of the 25 items
# checks clean at rc 0, so without it the page shows a module that passes and
# gives no way to tell what would stop it passing.
#
# It had five placements and six heading names, and scripts/build-docs.sh
# published neither region on purpose and both by accident. reading_subject()
# took `Subject:` through the next blank line. reading_constructs() took the
# first `## ` to the end. So prose under a named heading published demoted
# INSIDE the block titled "Constructs, and the recorded exit code", where it
# is not constructs, and prose sitting between the `rc:` line and the first
# heading was dropped. Measured on main at fcd020c: `grep -c 'Swapping it
# for' docs/reading/temporal.md` returned 0 while the source file carried
# that sentence.
#
# THE ONE SHAPE. Three headings, no others, and nothing between the `rc:`
# line and the first of them:
#
#   ## What the properties rest on
#   ## Constructs
#   ## Constructs from other families, also exercised
#
# The name is the corpus's own. reading/functions-records/03-overlay already
# used it, and it says what the region holds rather than calling it a
# measurement. Prose INSIDE a Constructs section stays legal, because the 7
# notes that live there annotate the list they sit in.
#
# ===========================================================================
# CHECK 7 — NO TWO ITEMS SHARE A SLUG.
#
# An item directory is <NN>-<slug>, and the slug names the system. Two items
# with the same slug in different families are two models of one system, and
# at that point a reader meets the second one knowing everything it teaches.
#
# THIS IS THE CHECK THAT CATCHES THE REAL CASE. On 2026-10-13 the
# tla-fwkz.2.1 author wrote reading/pluscal/04-chameleons against a landed
# reading/core/02-chameleons, caught it by hand, and replaced it. The discard
# is at fbd5ae2 and the slug was `chameleons` in both. Nothing in the gate
# saw it, and the author found it by reading the landed six and then
# re-reading main. 04-ring is what sits in that slot now.
#
# The check is exact. Two directory names are equal or they are not, there is
# no threshold and nothing to tune, and no author can argue with the result.
# That is why it is first and why I would keep it even if check 8 went away.
#
# ===========================================================================
# CHECK 8 — NO TWO SUBJECTS RESTATE EACH OTHER.
#
# Check 7 misses a duplicate written under a different slug. This one reads
# the `Subject:` line of every item, reduces it to its distinctive words, and
# compares all pairs. A pair that shares enough words describes one system.
#
# A SUBJECT IS PROSE AND IT WRAPS, so it is read flattened from the
# `Subject:` line through the next blank line. A line-based scan of this
# corpus produced a plausible wrong count five times in one session, twice in
# the hour before bead tla-ldvw was filed, and every one of those was a
# multi-line declaration read one line at a time.
#
# THE TWO NUMBERS CAME FROM THE CORPUS, and here is the whole measurement so
# the next author can redo it rather than trust it. Over the 25 items that
# existed on 2026-10-15:
#
#   worst real pair       3 shared words, 27%   temporal/01-handover against
#                                               temporal/02-converge
#                                               (weak, fairness, step)
#   the real duplicate    5 shared words, 50%   core/02-chameleons against
#                                               the fbd5ae2 discard
#                                               (chameleons, different, meet,
#                                               take, third)
#   the pair central
#     keeps on purpose    1 shared word, 12%    pluscal/03-contend against
#                                               temporal/04-contention (lock)
#
# So the threshold sits in a gap one word wide on each side, and I would not
# describe that as comfortable. It is one real positive against 300 real
# negatives, which is the evidence there is. Both numbers have to clear at
# once, and the count is the discriminator while the percentage is only there
# to stop a long subject drifting over the count by sheer length.
#
# THE 5 IS A FLOOR RATHER THAN THE REAL FIGURE, because the discard spelled
# the color words the British way and two words that name the same thing do
# not match if they differ by a letter. The same pair scores 6 once the
# spelling agrees, which harness/test-reading.sh's 1g fixture holds. So the
# threshold was set against the pessimistic reading of the one real positive
# there is, which I think is the right direction to be wrong in.
#
# THE STOPWORD LIST IS PART OF THE MEASUREMENT. Change it and the three rows
# above are hypotheses again, because every one of them is a count of words
# that survived it. Number words are in it on purpose: five items open with a
# count of something, and `two processes` against `two chameleons` is not a
# shared subject.
#
# THE PAIR CENTRAL KEEPS IS THE REASON THIS CHECK IS NARROW. Bead
# tla-fwkz.2.9 argued against gating this class at all, on the grounds that
# pluscal/03-contend and temporal/04-contention both teach weak against
# strong fairness and both stay, so a subject check would flag a pair
# somebody chose. That pair shares one word, and the gap between 1 and 4 is
# the answer to the objection rather than a coincidence. Two items can teach
# one lesson and still describe different systems, and the Subject line is
# about the system.
#
# ===========================================================================
# WHAT CHECKS 7 AND 8 DO NOT GATE, SAID PLAINLY
#
# A DUPLICATED LEMMA INSIDE A DIFFERENT SYSTEM IS NOT GATED. The same author
# in the same hour wrote a coprime model that duplicated reading/pluscal/
# 01-euclid's own divisor lemma, two items along in its own family, and threw
# that one away too. Both checks here would pass it. The slugs differ, and a
# subject that describes one system does not restate a subject that describes
# another, whatever the two models end up teaching.
#
# This is out of mechanical reach as far as I can see, and the gate says so
# in its own output on every run rather than leaving a reader to work out
# which half it bought. An advisory half of a gate that presents itself as
# whole is worse than a gate that states its limit, because the next author
# trusts it.
#
# The coprime model was never committed, so no measurement of its Subject
# line is possible. tla-ldvw and tla-fwkz.2.9 both say both discards are in
# the reflog at fbd5ae2. Only the chameleons one is, and that commit is the
# five-item pluscal wave.
#
# WHAT TO DO INSTEAD, for now: `--registry` prints every landed subject in a
# form an authoring brief pastes verbatim. That puts the 25 subjects in front
# of an author before it writes a 26th, which is the half a human can do and
# this gate cannot.
#
# ===========================================================================
# WHAT THIS GATE DELIBERATELY DOES NOT DO
#
# NO TELEGRAPH CHECK. harness/drill-gate.sh's check 1 fails an item whose
# PROMPT.md shows the construct it exercises, because a prompt that shows the
# answer is not a blank page. A READING item is the inverse: showing the
# construct IS the item. Porting that check would fail all six items for
# being correct. This is also why the corpus has its own root rather than
# living under drill/, whose item sweep is every depth-2 directory
# (drill-gate.sh:1586).
#
# NO CONSTRUCT-COVERAGE REPORT. It needs drill/INVENTORY.md's tab parser,
# which lives inside drill-gate.sh together with `normalize` and the rc
# reader. Duplicating it drifts and extracting it into a shared library is
# its own bead. So USES.md names constructs as drill/INVENTORY.md field 4
# writes them BY CONVENTION, and this gate still does not read INVENTORY.md
# at all. Check 5 holds 7 construct names against the module text and knows
# nothing about the other 98 rows, so it cannot tell you whether a name in a
# USES.md is a real row, nor which rows no item has reached.
#
# NO CHECK THAT A CONSTRUCT LIST IS COMPLETE. Check 5 closes the 7 names
# whose keyword a scan can see. An item that under-declares one of the other
# 98 is still invisible here, as META.md is taken at its word by the drill
# gate's check 3.
# ===========================================================================

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERDICT="${REPO_ROOT}/harness/verdict.sh"

# --- THE PHONE BOUND. One constant each, and amending one is a one-line edit.
# Lines in the .tla, header and footer included. DERIVED from Frank's "3
# screens of scroll" (2026-10-12). Was 40, which measurement killed.
MAX_LINES=60
# Columns in the widest line of the .tla. FRANK'S NUMBER, 2026-10-13: "77 is
# fine, no stress." Was 64, a guess from the mkdocs-material code font size
# that nobody checked on a device. Four of the five calibration specs fit 77.
MAX_COLS=77

# --- CHECK 8's TWO NUMBERS. Both have to clear at once. Amending either is a
# one-line edit, and the measurement behind the pair is in CHECK 8's header
# section. Real corpus worst pair 3 words at 27%, real duplicate 5 at 50%.
#
# The count is what discriminates. The percentage is a drift guard, so that a
# pair of long subjects cannot reach 4 shared words by length alone.
SUBJECT_MIN_SHARED=4
SUBJECT_MIN_PCT=40

# Words thrown away before the comparison. THIS LIST IS PART OF THE
# MEASUREMENT above, so changing it reopens both numbers. Words under 3
# characters go whatever this says. Number words are here because five
# subjects open with a count of something.
#
# `the` IS THE ONE TO WATCH, and it is here because it was once missing. The
# first draft left out every word the length filter already covers, and `the`
# is 3 characters, so it survived both and counted as distinctive. The worst
# real pair then read as core/02-chameleons against state-space/02-tickets at
# `take, the, never`, which is a sentence about English rather than about
# either model. Any word of exactly 3 characters needs listing here on
# purpose, since nothing else drops it.
SUBJECT_STOPWORDS="the and are its that this with for from not only every
each two three four five six seven eight nine ten one both their them there
they when where which whose what has have had but then than more most all
any into over under out down back off again same other another"

NO_TLC=0
TIMEOUT=120
QUIET=0
REGISTRY=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-tlc)   NO_TLC=1 ;;
    --registry) REGISTRY=1 ;;
    --timeout)  TIMEOUT="${2:-120}"; shift ;;
    -q|--quiet) QUIET=1 ;;
    -h|--help)
      awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "reading-gate.sh: unknown option '$1' (try --help)" >&2
      exit 2
      ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "reading-gate.sh: more than one reading root given ('$ROOT', '$1')" >&2
        exit 2
      fi
      ROOT="$1"
      ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  echo "reading-gate.sh: no reading root given (try --help)" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "reading-gate.sh: '$ROOT' is not a directory" >&2
  exit 2
fi
case "$TIMEOUT" in
  ''|*[!0-9]*)
    echo "reading-gate.sh: --timeout wants a positive integer, got '$TIMEOUT'" >&2
    exit 2
    ;;
esac

finding_n=0
unchecked_n=0
item_n=0

# --- CHECK 5's TABLE. One row per construct, `<grep -E pattern>|<the exact
# bullet text USES.md writes>`. The split is on the LAST `|`, so a pattern
# may carry alternation. See CHECK 5 in the header for why these seven and
# not the other 98 inventory rows.
READING_CONSTRUCTS=(
  '^[[:space:]]*EXTENDS[[:space:]]|EXTENDS (module import)'
  '^[[:space:]]*CONSTANTS?[[:space:]]|CONSTANT'
  '^[[:space:]]*ASSUME[[:space:]]|ASSUME'
  '^[[:space:]]*VARIABLES?[[:space:]]|VARIABLE / VARIABLES'
  '(^|[^A-Za-z_])UNCHANGED([^A-Za-z_]|$)|UNCHANGED'
  '(^|[^A-Za-z_])WF_|WF_v(A) (weak fairness)'
  '(^|[^A-Za-z_])SF_|SF_v(A) (strong fairness)'
)

# --- CHECK 6's allowed headings, in the order a normalized file writes them.
READING_SECTIONS=(
  '## What the properties rest on'
  '## Constructs'
  '## Constructs from other families, also exercised'
)
READING_PROBE_SECTION='## What the properties rest on'

# The bullets of the two Constructs sections, one per line. Scoped to those
# two sections because the probe section also carries `- ` bullets, and a
# whole-file scan would read "- `Peak` tightened to `n <= 51` gives rc 12."
# as a declared construct.
reading_declared() {
  awk '
    /^## / {
      on = ($0 == "## Constructs" ||
            $0 == "## Constructs from other families, also exercised")
      next
    }
    on && /^- / { sub(/^- /, ""); print }
  ' "$1"
}

# --- THE ITEM SWEEP, in one place. Every depth-2 directory under the root,
# which is the shape harness/drill-gate.sh:1586 uses, so <family>/<NN>-<slug>
# is an item and a family directory is not.
#
# The hidden-directory predicate is ANCHORED AT THE ROOT. A bare
# `! -path '*/.*'` would match the root itself, since every dispatched worker
# here runs under .claude/worktrees/agent-*, and the sweep would find nothing
# on any real tree. That bug is recorded in harness/test-drill.sh's part 3.
#
# It is a function because --registry sweeps too, and two copies of this
# predicate would drift the moment somebody fixed one of them.
reading_items() {
  find "$1" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "${1}/.*" | sort
}

# --- CHECK 8's READER. One awk per item, never one per pair.
#
# Prints the normalized word list, a tab, then the flattened Subject. The
# flattened half is what --registry prints, so both halves come off one pass
# and an item is read once.
#
# A SUBJECT WRAPS, so the grab runs from the `Subject:` line through the next
# blank line and joins with spaces. Reading it one line at a time is the
# failure this corpus has produced five times in a session.
reading_subject() {
  awk -v stop="$SUBJECT_STOPWORDS" '
    BEGIN {
      n = split(stop, a, /[ \t\n]+/)
      for (i = 1; i <= n; i++) if (a[i] != "") S[a[i]] = 1
    }
    /^Subject:/ {
      if (got) next
      got = 1
      g = 1
      s = $0
      sub(/^Subject:[[:space:]]*/, "", s)
      acc = s
      next
    }
    g && /^[[:space:]]*$/ { g = 0 }
    g { acc = acc " " $0 }
    END {
      gsub(/[[:space:]]+/, " ", acc)
      sub(/^ /, "", acc)
      sub(/ $/, "", acc)
      line = tolower(acc)
      gsub(/[^a-z0-9]+/, " ", line)
      n = split(line, w, " ")
      out = ""
      for (i = 1; i <= n; i++) {
        t = w[i]
        if (t == "") continue
        if (length(t) < 3) continue
        if (t in S) continue
        if (t in seen) continue
        seen[t] = 1
        out = out t " "
      }
      sub(/ $/, "", out)
      print out "\t" acc
    }
  ' "$1"
}

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-26s %-40s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-26s %-40s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

# ---------------------------------------------------------------------------
# --registry. The list an authoring brief pastes, and no check runs.
#
# It comes before the verdict.sh guard because it drives no TLC run, so it
# works in a checkout where the toolchain is not set up.
# ---------------------------------------------------------------------------
if [ "$REGISTRY" = "1" ]; then
  reg_n=0
  reg_slugs=""
  echo "# The reading subjects that exist. Do not write one that restates one of"
  echo "# these, and do not reuse a slug. harness/reading-gate.sh checks both."
  echo "#"
  echo "# Generated by: harness/reading-gate.sh --registry ${ROOT}"
  echo
  while IFS= read -r item; do
    rel="${item#"${ROOT}"/}"
    reg_n=$((reg_n + 1))
    # The same `NN-` strip check 7 does, so the roster lists what that check
    # actually compares. Printing `02-chameleons` here would tell an author
    # the number is part of the slug, and it is not.
    reg_dir="${rel##*/}"
    reg_slugs="${reg_slugs}${reg_dir#*-} "
    printf -- '- %s\n' "$rel"
    if [ -f "${item}/USES.md" ]; then
      # The reader prints `<words><tab><subject>`, so the subject is
      # everything after the first tab and no second fork is needed.
      reg_pair="$(reading_subject "${item}/USES.md")"
      reg_subj="${reg_pair#*$'\t'}"
      if [ -n "$reg_subj" ]; then
        printf '  %s\n' "$reg_subj"
      else
        printf '  (no Subject: line, which harness/reading-gate.sh reports as a finding)\n'
      fi
    else
      printf '  (no USES.md, which harness/reading-gate.sh reports as a finding)\n'
    fi
  done < <(reading_items "$ROOT")
  echo
  printf '# %s item(s). Slugs in use, and check 7 refuses a second use of any:\n' "$reg_n"
  printf '# %s\n' "$reg_slugs"
  exit 0
fi

if [ ! -x "$VERDICT" ] && [ "$NO_TLC" = "0" ]; then
  echo "reading-gate.sh: ${VERDICT} is missing or not executable." >&2
  echo "  Check 3 could not run. Pass --no-tlc to say so deliberately." >&2
  exit 2
fi

echo "reading-gate.sh: ${ROOT}, bound ${MAX_LINES} lines x ${MAX_COLS} cols"

# ---------------------------------------------------------------------------
# The item sweep. See reading_items() above for the predicate and why it is
# a function.
#
# CHECKS 7 AND 8 ARE CORPUS-WIDE, so they cannot run inside this loop. The
# three arrays below collect what they need as the sweep goes, and the pair
# comparison runs once after it. Reading each USES.md here rather than in a
# second sweep is what keeps the cost at one read per item.
# ---------------------------------------------------------------------------
sub_rel=()
sub_slug=()
sub_words=()
sub_uses=()

while IFS= read -r item; do
  rel="${item#"${ROOT}"/}"
  item_n=$((item_n + 1))

  # The slug comes off the directory name, so check 7 sees an item whose
  # shape is broken. Two items can collide on a slug and one of them still
  # be missing its .cfg, and both facts are worth reporting.
  #
  # `${dir#*-}` DROPS THE `NN-`, which is what makes the real case collide:
  # the discard was 04-chameleons against a landed 02-chameleons, so
  # comparing whole directory names would have missed it. A slug carrying its
  # own dash keeps the rest, since only the first one goes.
  dir="${rel##*/}"
  sub_rel+=("$rel")
  sub_slug+=("${dir#*-}")
  if [ -f "${item}/USES.md" ]; then
    sub_pair="$(reading_subject "${item}/USES.md")"
    sub_words+=("${sub_pair%%$'\t'*}")
    sub_uses+=(1)
  else
    # A missing USES.md is already SHAPE-NO-USES. One cause, one finding, so
    # the no-Subject report below skips this item rather than adding a second.
    sub_words+=("")
    sub_uses+=(0)
  fi

  # --- check 1: shape ------------------------------------------------------
  # Read the directory ONCE into an array and compare counts, rather than
  # forking a find per expected name.
  entries=()
  while IFS= read -r e; do
    entries+=("$(basename "$e")")
  done < <(find "$item" -mindepth 1 -maxdepth 1 | sort)

  tla=""
  cfg=""
  uses=0
  extra=()
  for e in "${entries[@]+"${entries[@]}"}"; do
    case "$e" in
      # TLC RUN ARTIFACTS ARE SKIPPED, AND THIS ARM COMES FIRST ON PURPOSE.
      # A bare `tlc` run that finds an error drops <Name>_TTrace_<n>.tla and
      # .bin beside the module, and a -dump run leaves a states/ directory.
      # All three are gitignored at .gitignore:1-6, so none of them can ever
      # reach a commit and a finding over one is noise. The tla-fwkz.2.6
      # author hit it on both its items and deleted four files by hand.
      #
      # The arm is above `*.tla` because `Nim_TTrace_1.tla` matches both. It
      # sorts after `Nim.tla` today, so the module still wins on `find |
      # sort` order, but that is luck about ASCII rather than a rule.
      #
      # WHY A PATTERN AND NOT `git ls-files`. Reading the tracked set is the
      # exact answer and it kills the suite: harness/test-reading.sh builds
      # every fixture under `mktemp -d`, which is not a work tree, so
      # `git ls-files` there returns rc 128 and nothing. Each of the twenty
      # fixtures would then report SHAPE-NO-TLA. Measured 2026-10-13.
      #
      # The pattern is also the better rule on its own merits. .gitignore's
      # next block covers *.bak and *.old, and an author's scratch copy in an
      # item directory SHOULD be a finding. Only tool output is skipped here.
      *_TTrace_*.tla|*_TTrace_*.bin|states) ;;
      *.tla)   if [ -n "$tla" ]; then extra+=("$e"); else tla="$e"; fi ;;
      *.cfg)   if [ -n "$cfg" ]; then extra+=("$e"); else cfg="$e"; fi ;;
      USES.md) uses=1 ;;
      *)       extra+=("$e") ;;
    esac
  done

  shape_ok=1
  if [ -z "$tla" ]; then
    finding "SHAPE-NO-TLA" "$rel" "no .tla; an item is <Name>.tla, <Name>.cfg and USES.md"
    shape_ok=0
  fi
  if [ -z "$cfg" ]; then
    finding "SHAPE-NO-CFG" "$rel" "no .cfg; the properties defined in the module are then never checked"
    shape_ok=0
  fi
  if [ "$uses" = "0" ]; then
    finding "SHAPE-NO-USES" "$rel" "no USES.md; the constructs line and the recorded rc both live there"
    shape_ok=0
  fi
  if [ "${#extra[@]}" -gt 0 ]; then
    finding "SHAPE-EXTRA-ENTRY" "$rel" \
      "${#extra[@]} entry(ies) beyond the three: ${extra[*]}. An item is ONE module; put a library in a nested submodule inside the .tla, as reading/modules/ does. scripts/build-docs.sh names the three and ignores the rest"
    shape_ok=0
  fi
  # A .tla and a .cfg whose stems differ means TLC is being pointed at a
  # config that does not belong to the module. Reported separately from a
  # missing file, because the directory looks complete.
  if [ -n "$tla" ] && [ -n "$cfg" ] && [ "${tla%.tla}" != "${cfg%.cfg}" ]; then
    finding "SHAPE-STEM-MISMATCH" "$rel" \
      "'${tla}' and '${cfg}' do not share a stem"
    shape_ok=0
  fi

  if [ "$shape_ok" = "0" ]; then
    continue
  fi

  stem="${tla%.tla}"
  mod="${item}/${tla}"
  cfgp="${item}/${cfg}"

  # --- check 2: the phone bound -------------------------------------------
  # ONE awk pass reports the line count and the widest OFFENDING line, with
  # the translation-block exemption applied inside the pass. The shell then
  # reads those numbers, which keeps the comparison in the agent-readable
  # place and off a pipeline.
  #
  # `in_tr` tracks the generated block. The markers themselves are
  # comment-only lines inside it, which is why the flag is raised on the
  # BEGIN line rather than after it.
  bound="$(awk -v maxc="$MAX_COLS" '
    /^[[:space:]]*\\\*[[:space:]]*BEGIN TRANSLATION/ { in_tr = 1 }
    {
      len = length($0)
      exempt = 0
      if (in_tr) {
        # comment-only: a \* line, or a whole-line (* ... *)
        if ($0 ~ /^[[:space:]]*\\\*/) exempt = 1
        if ($0 ~ /^[[:space:]]*\(\*.*\*\)[[:space:]]*$/) exempt = 1
      }
      if (!exempt && len > maxc && len > worst) { worst = len; worstln = NR }
    }
    /^[[:space:]]*\\\*[[:space:]]*END TRANSLATION/ { in_tr = 0 }
    END { print NR, worst + 0, worstln + 0 }
  ' "$mod")"
  read -r nlines wcols wline <<<"$bound"

  if [ "$nlines" -gt "$MAX_LINES" ]; then
    finding "PHONE-TOO-LONG" "$rel" \
      "${tla} is ${nlines} lines, bound is ${MAX_LINES}"
  fi
  if [ "$wcols" -gt 0 ]; then
    finding "PHONE-TOO-WIDE" "$rel" \
      "${tla} line ${wline} is ${wcols} columns, bound is ${MAX_COLS}"
  fi

  # --- check 4: the .cfg declares an obligation ----------------------------
  # Run before check 3, because an item with no obligation makes check 3's
  # rc 0 meaningless: TLC exits 0 having checked nothing.
  #
  # The keyword must be at the start of a line and carry an operand. A
  # commented-out `\*INVARIANT Inv2` is ordinary practice in the published
  # corpus (.claude/rules/tla-practice.md §7) and must NOT count, which is
  # what anchoring the pattern buys. A BARE keyword with no operand must not
  # count either: TLC exits 0 having silently checked no invariant
  # (harness/verdict.sh:180-186), which is the vacuity hazard this check
  # exists to catch.
  if grep -qE '^[[:space:]]*(INVARIANTS?|PROPERTIES|PROPERTY)[[:space:]]+[A-Za-z_]' "$cfgp"; then
    say "  OK    ${rel}  ${cfg} declares an obligation"
  else
    finding "CFG-NO-OBLIGATION" "$rel" \
      "${cfg} declares neither an INVARIANT nor a PROPERTY with an operand; a model with no property is not a reading item"
  fi

  # --- check 6: USES.md has one shape --------------------------------------
  # Run before check 5, because check 5 reads the two Constructs sections by
  # name and a file with the wrong headings would report every construct as
  # undeclared. One cause, one finding.
  usesp="${item}/USES.md"

  # Every `## ` heading must be one of the three. This catches a renamed or
  # invented probe section without the gate having to enumerate the six names
  # the corpus used before it was normalized.
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    known=0
    for s in "${READING_SECTIONS[@]}"; do
      [ "$h" = "$s" ] && known=1
    done
    if [ "$known" = "0" ]; then
      finding "USES-UNKNOWN-SECTION" "$rel" \
        "USES.md has the section '${h}'; the three allowed are '${READING_SECTIONS[0]}', '${READING_SECTIONS[1]}' and '${READING_SECTIONS[2]}'"
    fi
  done < <(grep '^## ' "$usesp" || true)

  if ! grep -qxF -- "$READING_PROBE_SECTION" "$usesp"; then
    finding "USES-NO-PROBE-SECTION" "$rel" \
      "USES.md has no '${READING_PROBE_SECTION}' section; that region is the only thing in an item saying which construct carries which property"
  fi

  # Prose between the `rc:` line and the first `## ` is dropped by
  # scripts/build-docs.sh, which anchors on `Subject:` and on the first
  # heading and claims neither the gap between them.
  stray="$(awk '
    /^[-*[:space:]]*rc:[[:space:]]*[0-9]+[[:space:]]*$/ { seen = 1; next }
    /^## / { exit }
    seen && /[^[:space:]]/ { n += 1 }
    END { print n + 0 }
  ' "$usesp")"
  if [ "$stray" -gt 0 ]; then
    finding "USES-PROSE-MISPLACED" "$rel" \
      "${stray} line(s) sit between the rc: line and the first '## ' heading, where scripts/build-docs.sh drops them; move them under '${READING_PROBE_SECTION}'"
  fi

  # --- check 5: a construct in the text is declared ------------------------
  declared="$(reading_declared "$usesp")"
  for spec in "${READING_CONSTRUCTS[@]}"; do
    pat="${spec%|*}"
    label="${spec##*|}"
    grep -qE -- "$pat" "$mod" || continue
    if ! grep -qxF -- "$label" <<<"$declared"; then
      finding "USES-CONSTRUCT-UNDECLARED" "$rel" \
        "${tla} carries ${label} and USES.md does not declare it"
    fi
  done

  # --- check 3: the recorded rc reproduces ---------------------------------
  # Read the rc from USES.md. A line `rc: N`, optionally bulleted.
  want="$(sed -n 's/^[-*[:space:]]*rc:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' "${item}/USES.md" | sed -n 1p)"
  if [ -z "$want" ]; then
    unchecked "verify-rc" "$rel" \
      "USES.md records no rc; expected a line reading 'rc: <number>'"
    continue
  fi

  if [ "$NO_TLC" = "1" ]; then
    unchecked "verify-rc" "$rel" \
      "${stem} records rc ${want}: --no-tlc was asked for, so the check was not run"
    continue
  fi

  # TLC's deadlock checking is an AND across the .cfg keyword and this flag.
  # See CHECK 3 in the header, and harness/drill-gate.sh:1947-1965.
  args=()
  if grep -qE '^[[:space:]]*CHECK_DEADLOCK[[:space:]]+TRUE' "$cfgp"; then
    args=(-d)
  fi

  "$VERDICT" --timeout "$TIMEOUT" -q "${args[@]+"${args[@]}"}" \
    -c "$cfgp" "$mod" >/dev/null 2>&1
  got=$?

  if [ "$got" != "$want" ]; then
    finding "VERIFY-RC-MISMATCH" "$rel" \
      "${stem}: USES.md records rc ${want}, TLC returned ${got}"
  else
    say "  OK    ${rel}  ${stem} rc=${got}, ${nlines} lines"
  fi
done < <(reading_items "$ROOT")

# ---------------------------------------------------------------------------
# CHECKS 7 AND 8 — the corpus-wide pair. They run here because no item can
# answer them alone, and they run under --no-tlc like every text check.
# ---------------------------------------------------------------------------
sub_n="${#sub_rel[@]}"
sub_pairs=0
if [ "$sub_n" -gt 1 ]; then
  sub_pairs=$((sub_n * (sub_n - 1) / 2))
fi

# A USES.md carrying no `Subject:` line. scripts/build-docs.sh anchors the
# published page on that line, so the page loses its one sentence saying what
# the model is about, and check 8 has nothing to compare. Reported only where
# the file exists, so a missing USES.md stays one finding.
for ((i = 0; i < sub_n; i++)); do
  if [ "${sub_uses[$i]}" = "1" ] && [ -z "${sub_words[$i]}" ]; then
    finding "USES-NO-SUBJECT" "${sub_rel[$i]}" \
      "USES.md has no 'Subject:' line carrying words of its own; scripts/build-docs.sh anchors the published page on it and check 8 cannot compare an item without one"
  fi
done

# --- check 7: no two items share a slug ------------------------------------
# The `NN-` came off in the sweep above. A slug that CONTAINS another is a
# different slug, so this compares whole strings and not prefixes: `base` and
# `based` are two systems.
for ((i = 0; i < sub_n; i++)); do
  for ((j = i + 1; j < sub_n; j++)); do
    if [ "${sub_slug[$i]}" = "${sub_slug[$j]}" ]; then
      # BOTH PATHS GO IN THE MESSAGE, not one in the path column and one
      # here. A reader fixing this needs the pair, and an assertion that
      # pins only the column is satisfied by the per-item OK lines too.
      finding "SLUG-REUSED" "${sub_rel[$j]}" \
        "${sub_rel[$j]} and ${sub_rel[$i]} share the slug '${sub_slug[$j]}'. A slug names the system, so two items under one slug are two models of one system"
    fi
  done
done

# --- check 8: no two subjects restate each other ---------------------------
# ONE ASSOCIATIVE ARRAY, BUILT ONCE. The pair loop then does lookups and
# forks nothing. 25 items is 300 pairs and 100 items would be 4,950, which is
# where a grep per pair becomes this project's recurring performance defect.
# harness/drill-gate.sh produced it twice, once at 7,350 greps.
declare -A sub_set=()
sub_count=()
for ((i = 0; i < sub_n; i++)); do
  read -ra ws <<<"${sub_words[$i]}"
  sub_count+=("${#ws[@]}")
  for w in ${ws[@]+"${ws[@]}"}; do
    sub_set["${i}|${w}"]=1
  done
done

# The worst real pair is printed on every run whatever the verdict, because a
# corpus creeping toward the bound is the thing an author wants to know
# before it writes the pair that trips it.
worst_c=0
worst_pair="none"
for ((i = 0; i < sub_n; i++)); do
  [ "${sub_count[$i]}" -gt 0 ] || continue
  read -ra ws <<<"${sub_words[$i]}"
  for ((j = i + 1; j < sub_n; j++)); do
    [ "${sub_count[$j]}" -gt 0 ] || continue
    shared=0
    shared_w=""
    for w in ${ws[@]+"${ws[@]}"}; do
      if [ -n "${sub_set["${j}|${w}"]:-}" ]; then
        shared=$((shared + 1))
        shared_w="${shared_w}${w}, "
      fi
    done
    small="${sub_count[$i]}"
    if [ "${sub_count[$j]}" -lt "$small" ]; then
      small="${sub_count[$j]}"
    fi
    pct=$((100 * shared / small))
    if [ "$shared" -gt "$worst_c" ]; then
      worst_c="$shared"
      worst_pair="${sub_rel[$i]} and ${sub_rel[$j]}, ${shared} word(s) at ${pct}% (${shared_w%, })"
    fi
    if [ "$shared" -ge "$SUBJECT_MIN_SHARED" ] && [ "$pct" -ge "$SUBJECT_MIN_PCT" ]; then
      finding "SUBJECT-RESTATED" "${sub_rel[$j]}" \
        "${sub_rel[$j]} and ${sub_rel[$i]} describe one system. ${shared} shared words (${shared_w%, }), ${pct}% of the shorter subject, against a bound of ${SUBJECT_MIN_SHARED} words and ${SUBJECT_MIN_PCT}%. One of the two is the one to keep, and the other wants a different system"
    fi
  done
done

if [ "$item_n" -eq 0 ]; then
  unchecked "items" "$ROOT" \
    "no item found; an item is <family>/<NN>-<slug> at depth 2 under the root"
fi

echo
echo "reading-gate.sh: ${item_n} item(s), ${finding_n} finding(s), ${unchecked_n} unchecked"
echo "  collisions: ${sub_n} subject(s) over ${sub_pairs} pair(s), worst ${worst_pair}"
echo "  NOT GATED: a duplicated lemma inside a different system. Checks 7 and 8"
echo "  read the slug and the Subject wording, so two items that teach one fact"
echo "  under two different subjects both pass. Run --registry and read the list."

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
