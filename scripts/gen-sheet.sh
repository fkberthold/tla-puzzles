#!/usr/bin/env bash
# Flatten the twelve chapter cheat sheets into drill/SHEET.md, one entry per
# construct. Regenerate with `bash scripts/gen-sheet.sh`, and prove the file
# still matches the cheat sheets with `--check`.
#
# Lineage: bead tla-ucbs.
#
# ===========================================================================
# WHAT IT WRITES
#
# One entry per `- Construct:` line in `exercises/ch*/CHEATSHEET.md`, carrying
# the K id, the chapter, the construct name and the syntax shape:
#
#   - K001  ch02  Operator definition
#     `Name(a, b) == expr` (or `Name == expr` with no arguments)
#
# Sorted by the K id, so drill/SHEET.md, drill/INVENTORY.md and
# drill/COLD-LIST.md all read in the same order and the id joins them.
#
# ===========================================================================
# THE JOIN GOES THROUGH THE INVENTORY, NOT THROUGH A SECOND ORDERING
#
# drill/INVENTORY.md field 2 is the K id and field 5 is the `file:line` of the
# `- Construct:` line that row came from. That join already exists and is
# already gated, so this script consumes it rather than deriving an order of
# its own. A second ordering would be a second thing to keep in step.
#
# Field 5 is why there is no family grouping here and no per-chapter heading. A
# heading is a selector, and the bead's argument for the flat form is that it
# selects nothing.
#
# FIELD 4 IS NOT BYTE FOR BYTE WHAT THE CHEAT SHEET SAYS, so the agreement
# check strips backticks before it compares. The inventory header calls field 4
# "verbatim from the cheat sheet entry", and it is, modulo markup: the sheet
# writes `` - Construct: `pc` (PlusCal's label-tracking variable) `` and field
# 4 reads `pc (PlusCal's label-tracking variable)`. Measured 2026-10-16: 94 of
# the 105 rows differ from their source text byte for byte, and 0 differ after
# the backticks come off. A check that compared raw text would have reddened on
# 94 rows that are all correct.
#
# 43 IS THE ANSWER TO A DIFFERENT QUESTION and it is recorded here because the
# first draft of this comment used it. 43 is how many source texts are not
# simply the name wrapped in one pair of backticks, so it counts rows with
# INTERNAL markup. The number that bears on the check is 94, since any backtick
# anywhere makes a raw comparison fail. Two plausible readings of "differ",
# and only one of them is about the comparison this script runs.
#
# The shape keeps its backticks, because there the backticks are the code
# formatting rather than markup around a name.
#
# ===========================================================================
# THE BIJECTION IS CHECKED IN BOTH DIRECTIONS
#
# A sheet that gains a construct nobody filed an inventory row for is the drift
# this script exists to catch, and it is silent: the generated file would still
# carry 105 correct entries. So the run fails unless all four of these hold.
#
#   1. The inventory's ROW count equals the `- Construct:` count in the sheets.
#   2. No two rows name the same field 5.
#   3. Every row's field 5 resolves to a `- Construct:` line.
#   4. Every row's field 4 equals that line's backtick-stripped text.
#
# Together those force a bijection. 105 rows pointing at 105 distinct construct
# lines out of 105 lines leaves nothing unclaimed, so check 1 is what turns the
# other three into a two-way proof rather than a one-way lookup.
#
# Check 3 is also what catches a line-number shift. An edit that inserts a line
# above an entry moves every later field 5 off its target, and the text
# comparison in check 4 names the first row that slipped.
#
# ===========================================================================
# WHAT A SYNTAX SHAPE IS, AND THE FOUR THAT ARE NOT ONE LINE
#
# The shape runs from `  Syntax shape: ` to the next labeled field, so a shape
# that continues onto further lines comes across whole, folded onto one line
# with single spaces at the joins. Four constructs need that: K035, K041, K042
# and K043. Reading only the `  Syntax shape: ` line would have truncated
# ch05's model-value entry mid-sentence, and that is the entry a reader is most
# likely to come to this file for.
#
# The indented field vocabulary is closed and small. Measured 2026-10-16 across
# all twelve sheets: 105 `Syntax shape:`, 105 `Section anchor:`, 3 `Toolbox
# equivalent:` and nothing else. So the terminator list below is the whole
# surface rather than a sample of it.
#
# `Toolbox equivalent:` is NOT carried. Those three are instructions for a GUI
# dialog, which is not notation to recall at flow speed, and the bead asks for
# the construct, the shape and the chapter.
#
# ===========================================================================
# THREE HAZARDS THIS FILE IS BUILT AROUND
#
# AWK WRITES ITS FINDINGS WITH `>>`, NOT `>`. Two awk runs here report into one
# defects file, and awk's `>` truncates the file on its FIRST write in each
# run. So the join pass silently wiped everything the flatten pass had found.
# It cost a real finding on the first run of this script: a BADCHAPTER line was
# written and then deleted before anybody read it. Measured on this box:
#
#   two runs, both `>` : the file holds SECOND
#   two runs, both `>>`: the file holds FIRST and SECOND
#
# The shell truncates the file once with `: >` before either awk starts, so
# append is the correct mode and not merely the safe one. This is the failure
# direction that matters, since a lost finding reads exactly like a clean run.
#
# HEADER STATE LEAKS ACROSS FILES unless it is reset. awk keeps a variable
# between input files, so an entry left open at the end of one sheet would
# collect the next sheet's front matter as its shape. The reset is `FNR == 1`,
# which flushes the open entry before anything about the new file is read.
# scripts/gen-coverage.sh carries the same reset for the same reason.
#
# THE PREFIX STRIP IS LITERAL, not a regex. Field 5 is repo-relative, so
# FILENAME has to lose the root before it can be a join key, and every
# dispatched worker here runs under `.claude/worktrees/agent-*`. A `sub()` with
# the root interpolated into the pattern would read those dots as "any
# character". index() and substr() do not. (bead tla-1hf is the same hazard one
# level up: a literal repo path in a script writes across checkouts.)
# ===========================================================================

set -euo pipefail

# Resolve the repo root from THIS script's own location, never a literal path.
# scripts/gen-curriculum-map.sh used to open with
# `cd /home/frank/repos/tla-puzzles`, so running it from a worktree wrote its
# output into the MAIN checkout. No footprint check can see that, because it
# happens inside a script rather than in an agent's edits. (bead tla-1hf)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ROOT="$REPO_ROOT"
MODE="write"

usage() {
  cat <<'USAGE'
usage: gen-sheet.sh [--check|--stdout] [--root DIR]

  --check     regenerate into a temporary file and diff it against the live
              sheet. Exit 1 and print the diff on any drift.
  --stdout    print the regenerated sheet and change nothing.
  --root DIR  the tree holding exercises/ and drill/.

With no mode flag it rewrites drill/SHEET.md in place.

ONE ROOT RATHER THAN A PATH PER INPUT. drill/INVENTORY.md field 5 is spelled
relative to the root, so a cheat-sheet tree somewhere the inventory cannot name
is incoherent by construction. One flag re-bases every path at once and keeps
the join keys meaningful.
USAGE
}

# A FLAG WITH NO VALUE IS CHECKED BEFORE THE SHIFT, not after. The obvious
# spelling is `--root) ROOT="${2:-}"; shift ;;` with a `[ -n "$ROOT" ]` guard
# below, and it does not work: `shift` consumes the flag, the loop's trailing
# `shift` then runs with no arguments left, and under `set -e` that kills the
# script with rc 1 before the guard is ever reached. So `gen-sheet.sh --root`
# exited 1 and printed nothing.
#
# scripts/gen-coverage.sh carries the same shape on --inventory, --drill and
# --reading, and `scripts/gen-coverage.sh --inventory` exits 1 silently today.
# Reported rather than fixed, since that file is not this bead's to touch.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)   MODE="check" ;;
    --stdout)  MODE="stdout" ;;
    --root)
      if [ "$#" -lt 2 ]; then
        printf 'gen-sheet.sh: --root needs a directory\n' >&2
        exit 2
      fi
      ROOT="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'gen-sheet.sh: unknown argument %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Still guarded, because `--root ""` reaches here with a value and an empty one.
[ -n "$ROOT" ] || { printf 'gen-sheet.sh: --root needs a directory\n' >&2; exit 2; }
ROOT="${ROOT%/}"

EXERCISES="$ROOT/exercises"
INVENTORY="$ROOT/drill/INVENTORY.md"
SHEET="$ROOT/drill/SHEET.md"

[ -d "$EXERCISES" ] || { printf 'gen-sheet.sh: no exercises tree at %s\n' "$EXERCISES" >&2; exit 2; }
[ -f "$INVENTORY" ] || { printf 'gen-sheet.sh: no inventory at %s\n' "$INVENTORY" >&2; exit 2; }

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

: > "$SCRATCH/defects"

# ---------------------------------------------------------------------------
# The cheat sheet file list.
#
# `ch*` RATHER THAN EVERY CHEATSHEET.md, because exercises/templates/ holds one
# too. It is the scaffold a new chapter gets copied from, and its one entry
# reads `- Construct: <name>`. A sweep by filename alone found it and reported
# 106 construct entries against 105 inventory rows, which is the right verdict
# on the wrong population: a placeholder is not a construct. The bead, the
# inventory header and drill/COLD-LIST.md all spell the population
# `exercises/ch*/CHEATSHEET.md`, so this matches that spelling.
#
# A THIRTEENTH CHAPTER STILL REDDENS. The count check below compares what the
# sweep found against the inventory's row count, so a real ch14 with no rows
# filed is caught. Narrowing the glob drops the scaffold without widening the
# hole.
#
# ANCHOR THE HIDDEN-PATH EXCLUSIONS AT $EXERCISES. An unanchored
# `! -path '*/.*'` matches the checkout's own directory name and excludes every
# file, since every dispatched worker runs from `.claude/worktrees/agent-*`.
# That failure comes back rc 0 with an empty sheet, which is a plausible wrong
# answer rather than a crash. scripts/gen-coverage.sh:236-242 anchors the same
# way after hitting it.
# ---------------------------------------------------------------------------
SHEETS=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  SHEETS+=("$f")
done < <(find "$EXERCISES" -mindepth 2 -maxdepth 2 -type f -name CHEATSHEET.md \
  -path "${EXERCISES}/ch*/CHEATSHEET.md" \
  ! -path "${EXERCISES}/.*" ! -path "${EXERCISES}/*/.*" | LC_ALL=C sort)

if [ "${#SHEETS[@]}" -eq 0 ]; then
  printf 'gen-sheet.sh: %s holds no exercises/ch*/CHEATSHEET.md\n' "$EXERCISES" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Flatten every cheat sheet into "<file:line>\t<chapter>\t<name>\t<shape>".
#
# ONE awk over the whole list, not one per file. 105 entries over 12 files is
# small, but a per-entry fork is the shape this project has produced twice,
# once at 7,350 greps in harness/drill-gate.sh.
# ---------------------------------------------------------------------------
# The single quotes are load-bearing: `$0` is awk's whole record and must not
# expand in the shell.
# shellcheck disable=SC2016
FLATTEN_AWK='
function emit() {
  if (src == "") return
  if (shape == "") {
    printf("NOSHAPE %s carries no Syntax shape line\n", src) >> DEFECTS
  } else {
    printf("%s\t%s\t%s\t%s\n", src, chap, name, shape)
  }
  src = ""
  name = ""
  shape = ""
}
# Flush the open entry BEFORE anything about the new file is read, so a sheet
# that ends mid-entry cannot collect the next sheet front matter as its shape.
FNR == 1 {
  emit()
  inshape = 0
  rel = FILENAME
  if (index(rel, ROOT "/") == 1) rel = substr(rel, length(ROOT) + 2)
  np = split(rel, parts, "/")
  chap = (np >= 2) ? parts[np - 1] : ""
  if (chap !~ /^ch[0-9][0-9]$/) {
    printf("BADCHAPTER %s is not exercises/chNN/CHEATSHEET.md\n", rel) >> DEFECTS
  }
}
/^- Construct: / {
  emit()
  src = rel ":" FNR
  name = substr($0, 14)
  gsub(/`/, "", name)
  sub(/[ \t]+$/, "", name)
  inshape = 0
  next
}
/^  Syntax shape: / {
  if (src == "") {
    printf("ORPHANSHAPE %s:%s sits outside a Construct entry\n", rel, FNR) >> DEFECTS
    next
  }
  shape = substr($0, 17)
  sub(/[ \t]+$/, "", shape)
  inshape = 1
  next
}
# The closed terminator list. Measured: these two labels and Syntax shape are
# the whole indented vocabulary across all twelve sheets.
/^  (Section anchor|Toolbox equivalent): / { inshape = 0; next }
/^- / { emit(); inshape = 0; next }
/^## / { emit(); inshape = 0; next }
/^[ \t]*$/ { inshape = 0; next }
inshape {
  cont = $0
  sub(/^[ \t]+/, "", cont)
  sub(/[ \t]+$/, "", cont)
  if (cont != "") shape = shape " " cont
  next
}
END { emit() }
'

awk -v ROOT="$ROOT" -v DEFECTS="$SCRATCH/defects" "$FLATTEN_AWK" "${SHEETS[@]}" \
  > "$SCRATCH/pairs"

# ---------------------------------------------------------------------------
# Join the flattened entries onto the inventory rows and check the bijection.
#
# awk with -F'\t' rather than `IFS=$'\t' read`. Tab is an IFS whitespace
# character, so a run of tabs collapses into one delimiter and an empty cell
# disappears, shifting every later field left. Fields 8 and 9 of the inventory
# are empty on 29 rows between them, which is exactly the case that triggers
# it. harness/drill-gate.sh:779-791 records the same trap.
# ---------------------------------------------------------------------------
# The single quotes are load-bearing: `$1` through `$5` are awk field
# references and must not expand in the shell.
# shellcheck disable=SC2016
JOIN_AWK='
BEGIN { FS = "\t" }
FILENAME == PAIRS {
  pchap[$1] = $2
  pname[$1] = $3
  pshape[$1] = $4
  npairs++
  next
}
$1 != "ROW" { next }
{
  nrows++
  # The id shape is what makes a plain sort the right sort. Three digits sort
  # lexicographically in numeric order, and a wider id would not, so the gate
  # names it rather than mis-ordering the file in silence.
  if ($2 !~ /^K[0-9][0-9][0-9]$/) {
    printf("BADID %s is not KNNN\n", $2) >> DEFECTS
    next
  }
  if ($5 in seen) {
    printf("DUPSOURCE %s and %s both name %s\n", seen[$5], $2, $5) >> DEFECTS
    next
  }
  seen[$5] = $2
  if (!($5 in pname)) {
    printf("UNRESOLVED %s field 5 %s names no Construct line\n", $2, $5) >> DEFECTS
    next
  }
  if (pname[$5] != $4) {
    printf("DISAGREE %s field 4 reads [%s], %s reads [%s]\n", $2, $4, $5, pname[$5]) >> DEFECTS
    next
  }
  claimed[$5] = 1
  printf("%s\t%s\t%s\t%s\n", $2, pchap[$5], $4, pshape[$5])
}
END {
  if (nrows != npairs) {
    printf("COUNT %d inventory row(s) against %d construct entr(ies)\n", nrows, npairs) >> DEFECTS
  }
  for (k in pname) {
    if (!(k in claimed)) {
      printf("UNCLAIMED %s is in no inventory row\n", k) >> DEFECTS
    }
  }
}
'

awk -v PAIRS="$SCRATCH/pairs" -v DEFECTS="$SCRATCH/defects" "$JOIN_AWK" \
  "$SCRATCH/pairs" "$INVENTORY" | LC_ALL=C sort > "$SCRATCH/entries"

if [ -s "$SCRATCH/defects" ]; then
  n_defects="$(wc -l < "$SCRATCH/defects")"
  printf 'gen-sheet.sh: the cheat sheets and %s do not agree. %s finding(s):\n' \
    "$INVENTORY" "$n_defects" >&2
  LC_ALL=C sort "$SCRATCH/defects" | sed 's/^/  /' >&2
  printf '\n' >&2
  printf 'Every construct entry needs exactly one inventory row, and that row needs\n' >&2
  printf 'field 5 pointing at its own Construct line. Fix the pair, then run again.\n' >&2
  exit 1
fi

ENTRIES="$(wc -l < "$SCRATCH/entries")"
if [ "$ENTRIES" -eq 0 ]; then
  printf 'gen-sheet.sh: the join produced no entries\n' >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Render. The header's counts are emitted rather than written, so no figure in
# the generated file can go stale. The suite count in
# .claude/rules/dispatched-agents.md went three out of date twice by being a
# literal in prose, which is the failure this avoids.
#
# THE SINGLE QUOTES ARE RIGHT AND SHELLCHECK DISAGREES, at five sites. Every
# backtick below is literal markdown, so SC2016's "expressions don't expand in
# single quotes" is reporting the behavior this code wants. Double quotes would
# hand the shell a command substitution to run, which is the actual defect the
# check exists to find. One directive covers the whole function rather than
# five, because every site is the same prose.
#
# The reason goes ABOVE the directive. A continuation line that starts with the
# word "shellcheck" parses as a second directive, which raised 10 new
# SC1072/SC1073 errors when bead tla-5r7 tried it the other way round.
# ---------------------------------------------------------------------------
# shellcheck disable=SC2016
generate() {
  printf '# Construct sheet\n'
  printf '\n'
  printf 'The %s cheat sheets at `exercises/ch*/CHEATSHEET.md` carry the syntax shape\n' "${#SHEETS[@]}"
  printf 'of every construct this curriculum introduces. A study session has no reason\n'
  printf 'to open %s files, so this is all of them, flat, one entry per construct.\n' "${#SHEETS[@]}"
  printf '\n'
  printf '%s entries, sorted by the `K` id, so this file, `drill/INVENTORY.md` and\n' "$ENTRIES"
  printf '`drill/COLD-LIST.md` all read in the same order. The id is the join. Find a\n'
  printf 'construct here, then read its coverage in the inventory.\n'
  printf '\n'
  printf 'Flat rather than per-family on purpose. A per-family sheet names the answer\n'
  printf 'shape for the family you are working. It gets read cold once, and after that\n'
  printf 'it is the answer key. This form selects nothing, so it leaks nothing, and I\n'
  printf 'think it is the only form that puts the ch03 PlusCal assignment beside the\n'
  printf 'ch12 `VARIABLE` declaration, with their chapters visible.\n'
  printf '\n'
  printf 'GENERATED. Do not hand-edit. The next run drops your change.\n'
  printf '\n'
  printf '    bash scripts/gen-sheet.sh            # rewrite it from the cheat sheets\n'
  printf '    bash scripts/gen-sheet.sh --check    # fail if it has drifted\n'
  printf '\n'
  printf '`harness/test-sheet.sh` runs the second form.\n'
  printf '\n'
  # THE BLANK LINE GOES BEFORE EACH ENTRY BUT THE FIRST, not after each one, so
  # the file ends with a single newline the way drill/COLD-LIST.md does. The
  # other spelling left a trailing blank line, which nothing here gates and
  # which a sibling file does not have.
  #
  # Two lines per entry rather than one. The id line is what a reader scans and
  # the shape is what they came for, so the shape gets its own line and the
  # blank line between entries is what makes 105 of them scannable at all.
  # shellcheck disable=SC2016
  awk -F'\t' '
    { if (NR > 1) printf "\n" }
    { printf "- %s  %s  %s\n  %s\n", $1, $2, $3, $4 }
  ' "$SCRATCH/entries"
}

case "$MODE" in
  stdout)
    generate
    ;;
  check)
    if [ ! -f "$SHEET" ]; then
      printf 'gen-sheet.sh: no sheet at %s. Write it with\n' "$SHEET" >&2
      printf '  bash scripts/gen-sheet.sh\n' >&2
      exit 1
    fi
    generate > "$SCRATCH/regenerated"
    if diff -u "$SHEET" "$SCRATCH/regenerated" > "$SCRATCH/drift"; then
      printf 'gen-sheet.sh: %s matches the cheat sheets (%s entries)\n' "$SHEET" "$ENTRIES"
    else
      printf 'gen-sheet.sh: %s has drifted from the cheat sheets. Regenerate with\n' "$SHEET" >&2
      printf '  bash scripts/gen-sheet.sh\n\n' >&2
      cat "$SCRATCH/drift" >&2
      exit 1
    fi
    ;;
  write)
    generate > "$SCRATCH/regenerated"
    mkdir -p "$(dirname "$SHEET")"
    cat "$SCRATCH/regenerated" > "$SHEET"
    awk -F'\t' '{ print $2 }' "$SCRATCH/entries" | LC_ALL=C sort | uniq -c | sed 's/^/  /'
    printf 'gen-sheet.sh: wrote %s entries from %s cheat sheet(s) into %s\n' \
      "$ENTRIES" "${#SHEETS[@]}" "$SHEET"
    ;;
esac
