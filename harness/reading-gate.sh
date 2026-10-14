#!/usr/bin/env bash
# reading-gate.sh — the four checks over the reading corpus.
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
#   --no-tlc        skip check 3's TLC runs. Checks 1, 2 and 4 still run.
#                   This mode can NEVER exit 0 — see EXIT CODES.
#   --timeout SECS  per-module TLC budget, passed to verdict.sh (default 120)
#   -q, --quiet     suppress the per-item PASS lines; findings still print
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
# landing. Same call as harness/drill-gate.sh:1622-1626.
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
# WHAT THIS GATE DELIBERATELY DOES NOT DO
#
# NO TELEGRAPH CHECK. harness/drill-gate.sh's check 1 fails an item whose
# PROMPT.md shows the construct it exercises, because a prompt that shows the
# answer is not a blank page. A READING item is the inverse: showing the
# construct IS the item. Porting that check would fail all six items for
# being correct. This is also why the corpus has its own root rather than
# living under drill/, whose item sweep is every depth-2 directory
# (drill-gate.sh:1315).
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

NO_TLC=0
TIMEOUT=120
QUIET=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-tlc)   NO_TLC=1 ;;
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

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-26s %-40s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-26s %-40s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

if [ ! -x "$VERDICT" ] && [ "$NO_TLC" = "0" ]; then
  echo "reading-gate.sh: ${VERDICT} is missing or not executable." >&2
  echo "  Check 3 could not run. Pass --no-tlc to say so deliberately." >&2
  exit 2
fi

echo "reading-gate.sh: ${ROOT}, bound ${MAX_LINES} lines x ${MAX_COLS} cols"

# ---------------------------------------------------------------------------
# The item sweep. Every depth-2 directory under the root, which is the same
# shape harness/drill-gate.sh:1315 uses, so <family>/<NN>-<slug> is an item
# and a family directory is not.
#
# The hidden-directory predicate is ANCHORED AT THE ROOT. A bare
# `! -path '*/.*'` would match the root itself, since every dispatched worker
# here runs under .claude/worktrees/agent-*, and the sweep would find nothing
# on any real tree. That bug is recorded in harness/test-drill.sh's part 3.
# ---------------------------------------------------------------------------
while IFS= read -r item; do
  rel="${item#"${ROOT}"/}"
  item_n=$((item_n + 1))

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
  # See CHECK 3 in the header, and harness/drill-gate.sh:1606-1626.
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
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "${ROOT}/.*" | sort)

if [ "$item_n" -eq 0 ]; then
  unchecked "items" "$ROOT" \
    "no item found; an item is <family>/<NN>-<slug> at depth 2 under the root"
fi

echo
echo "reading-gate.sh: ${item_n} item(s), ${finding_n} finding(s), ${unchecked_n} unchecked"

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
