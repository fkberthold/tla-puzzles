#!/usr/bin/env bash
# Fill drill/INVENTORY.md's coverage fields from the two corpora that reach
# the 105 constructs. Regenerate with `bash scripts/gen-coverage.sh`, and
# prove the file still matches the corpora with `--check`.
#
# Lineage: bead tla-zhfc.
#
# ===========================================================================
# WHAT IT WRITES, AND WHY THERE ARE THREE FIELDS RATHER THAN ONE
#
# Fields 1 to 7 of every ROW line come back byte for byte. The script only
# ever rewrites field 8 onward:
#
#   8  items     drill item slugs, comma separated
#   9  reading   reading item slugs, comma separated
#   10 coverage  one of both, drill-only, reading-only, neither
#
# FIELD 10 IS THE ONE THAT CAN NEVER BE EMPTY, and it is the answer to the
# requirement that an empty cell never read as a coverage of zero. Fields 8
# and 9 are lists, and a list of nothing is empty. Field 10 is a verdict, so
# it says "neither" in a word. Nobody has to read emptiness as a claim any
# more, which is what made the old single-field shape ambiguous.
#
# THE OBVIOUS DESIGN WAS TO PUT THE MARKER IN FIELD 8, and I dropped it
# because field 8 already has a reader. harness/drill-gate.sh:815 pulls field
# 8 in, splits it on commas, and seeds its per-construct item count from the
# words it finds (drill-gate.sh:1452-1462). An empty field 8 is the only
# value that reader scores as zero. A marker word there would score as one
# item, so all 26 constructs the drill corpus does not reach would print
# COVERAGE 1 and drop out of drill-gate's CONSTRUCT GAPS block. That is the
# false-coverage direction, on the one report that lists the gaps, so field 8
# keeps its existing contract and field 10 carries the marker.
#
# THE SLUGS ARE BARE, not family-qualified, for the same reason. drill-gate's
# union test is `case " ${INV_SEEN[$idx]} " in *" ${base} "*)` at
# drill-gate.sh:1720, where `base` is the item directory's basename. A field
# 8 reading `core/01-box-office` would not match the pattern for
# `01-box-office`, so drill-gate would append the item again and count one
# item twice. Bare slugs are unambiguous here: all 64 drill slugs are
# distinct, all 25 reading slugs are distinct, and the two sets do not
# overlap. Field 9 uses the same spelling, because two fields in one file
# that both name an item should name it the same way.
#
# ===========================================================================
# WHERE READING COVERAGE COMES FROM
#
# From `## Constructs` and `## Constructs from other families, also
# exercised` in each reading/*/NN-slug/USES.md. The bead offered two routes,
# deriving the coverage from the .tla or adding a field to USES.md, and
# neither is needed. All 25 USES.md files already carry both sections, and
# they have since the files were written on 2026-10-13. The bead's premise
# that USES.md carries no construct list does not hold as of 2026-10-15.
#
# Three things make those sections the right source rather than a convenient
# one.
#
# They are already gated for shape. harness/reading-gate.sh check 6 allows
# exactly three headings in USES.md and nothing between the `rc:` line and
# the first of them, so a section cannot quietly move or get renamed.
#
# They are already gated in one direction against the module text. Check 5
# fails an item whose .tla carries one of seven keywords that USES.md does
# not declare, so under-declaration of those seven is caught at the source.
#
# They name constructs as drill/INVENTORY.md field 4 writes them, which
# reading-gate.sh:217-219 records as a convention rather than a check. This
# script is what turns the convention into a check. Every declared name has
# to resolve to a field 4 value or the run fails, which closes the gap
# reading-gate.sh:220-223 names outright: it cannot tell whether a name in a
# USES.md is a real row.
#
# WHAT DERIVING FROM THE .tla WOULD HAVE COST. A text scan cannot resolve a
# row like K013 "Set relational and algebraic operators", which covers \cup,
# \cap and \subseteq together. A finding over that row would be true of the
# row and false of the module, which is the reasoning reading-gate.sh's own
# check 5 gives for holding only seven of the 105 rows against module text.
# So a .tla-derived channel would have been honest about perhaps seven rows
# and guessing about the rest.
#
# ===========================================================================
# DECLARATION IS COVERAGE, AND THE THREE HEADINGS ARE THE WHOLE SURFACE
#
# Read: `## Constructs`, `## Constructs exercised`, and `## Constructs from
# other families, also exercised`. Not read: everything else, and two of
# those are worth naming because they look like coverage.
#
# `## Also exercised, not declared` says so in its own title. Two drill items
# carry it, for K064 and K076, and both explain why the author is not
# claiming the row. Counting it would overrule a judgment the author wrote
# down.
#
# `## Roles` in the temporal family lists neighbor constructs marked "killed
# by row 2, not declared". Those are the wrong answers the item rules out, so
# counting them would report coverage of a construct the item exists to
# exclude.
#
# The surface is closed rather than assumed. The gate's part 6 flattens the
# bullets under every OTHER heading in both corpora and asserts that none of
# them joins on a field 4 value. Measured 2026-10-15: 212 distinct such
# bullets, 0 joining. The gate prints the count on every run, so the number
# here is a description and the run is the authority.
#
# ===========================================================================
# THE TWO SCANNING HAZARDS THIS FILE IS BUILT AROUND
#
# HEADER STATE LEAKS ACROSS FILES unless it is reset. awk keeps a variable
# between input files, so a file whose last heading is a construct heading
# leaves the next file's front matter being read as construct bullets. It is
# live today: all 25 USES.md files end with `## Constructs from other
# families, also exercised`, and the drill corpus carries 299 front-matter
# bullets. The reset is `FNR == 1`, and the gate's part 6 has a fixture pair
# that reproduces the leak without it.
#
# ONE AWK PER CORPUS, not one per file. 105 rows against 64 plus 25 items is
# where this project has twice produced a per-row fork, once at 7,350 greps
# in drill-gate.sh. Each corpus is flattened by a single awk over the whole
# file list, and the join happens in one more awk over the two flat files.
# ===========================================================================

set -euo pipefail

# Resolve the repo root from THIS script's own location, never a literal
# path. scripts/gen-curriculum-map.sh used to open with
# `cd /home/frank/repos/tla-puzzles`, so running it from a worktree wrote its
# output into the MAIN checkout. No footprint check can see that, because it
# happens inside a script rather than in an agent's edits, and it surfaces
# later as unexplained dirty state in somebody else's bead. (bead tla-1hf)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INVENTORY="$REPO_ROOT/drill/INVENTORY.md"
DRILL_ROOT="$REPO_ROOT/drill"
READING_ROOT="$REPO_ROOT/reading"
MODE="write"

usage() {
  cat <<'USAGE'
usage: gen-coverage.sh [--check|--stdout] [--inventory FILE]
                       [--drill DIR] [--reading DIR]

  --check        regenerate into a temporary file and diff it against the
                 live inventory. Exit 1 and print the diff on any drift.
  --stdout       print the regenerated inventory and change nothing.
  --inventory F  the inventory to read and rewrite.
  --drill D      the drill corpus root, holding <family>/<item>/META.md.
  --reading D    the reading corpus root, holding <family>/<item>/USES.md.

With no mode flag it rewrites the inventory in place.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)     MODE="check" ;;
    --stdout)    MODE="stdout" ;;
    --inventory) INVENTORY="${2:-}"; shift ;;
    --drill)     DRILL_ROOT="${2:-}"; shift ;;
    --reading)   READING_ROOT="${2:-}"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) printf 'gen-coverage.sh: unknown argument %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[ -f "$INVENTORY" ] || { printf 'gen-coverage.sh: no inventory at %s\n' "$INVENTORY" >&2; exit 2; }
[ -d "$DRILL_ROOT" ] || { printf 'gen-coverage.sh: no drill corpus at %s\n' "$DRILL_ROOT" >&2; exit 2; }
[ -d "$READING_ROOT" ] || { printf 'gen-coverage.sh: no reading corpus at %s\n' "$READING_ROOT" >&2; exit 2; }

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# ---------------------------------------------------------------------------
# The inventory's field 4 values, one per line, in row order.
#
# awk with -F'\t' rather than `IFS=$'\t' read`. Tab is an IFS whitespace
# character, so a run of tabs collapses into one delimiter and an empty cell
# disappears, shifting every later field left. Field 8 is empty on every row
# of the file this script is replacing, which is exactly the case that
# triggers it. drill-gate.sh:779-791 records the same trap and the count of 1
# it produced on all 105 rows.
# ---------------------------------------------------------------------------
awk -F'\t' '$1 == "ROW" { print $4 }' "$INVENTORY" > "$SCRATCH/names"

ROWS="$(wc -l < "$SCRATCH/names")"
if [ "$ROWS" -eq 0 ]; then
  printf 'gen-coverage.sh: %s has no tab-delimited ROW lines\n' "$INVENTORY" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Flatten one corpus into "<construct>\t<slug>" lines.
#
# $1 is the corpus root, $2 the per-item metadata filename, $3 the output
# path. The file list is sorted, so <family>/<item> order decides the order
# slugs appear in a cell, and the generated file is stable across runs.
# ---------------------------------------------------------------------------
# The single quotes are load-bearing: `$0` is awk's whole record and must not
# expand in the shell.
# shellcheck disable=SC2016
FLATTEN_AWK='
# Reset at every new input file. Without this, a file whose last heading is a
# construct heading leaves the next file reading its own front matter as
# construct bullets.
FNR == 1 {
  inblock = 0
  dir = FILENAME
  sub(/\/[^\/]*$/, "", dir)
  slug = dir
  sub(/^.*\//, "", slug)
}
/^## / {
  hdr = substr($0, 4)
  sub(/[ \t]+$/, "", hdr)
  inblock = (hdr == "Constructs" ||
             hdr == "Constructs exercised" ||
             hdr == "Constructs from other families, also exercised")
  next
}
/^- / {
  if (!inblock) next
  b = substr($0, 3)
  # The temporal family backticks its bullets. Both spellings name the same
  # field 4 value, so the backticks come off before the join.
  gsub(/`/, "", b)
  sub(/^[ \t]+/, "", b)
  sub(/[ \t]+$/, "", b)
  if (b == "") next
  print b "\t" slug
}
'

flatten_corpus() {
  local root="$1" meta="$2" out="$3"
  local list="$SCRATCH/list-$meta"
  local -a files=()
  local f
  # ANCHOR THE HIDDEN-PATH EXCLUSIONS AT $root. An unanchored `! -path '*/.*'`
  # matched the checkout's own directory name and excluded all 64 items, since
  # every dispatched worker runs from `.claude/worktrees/agent-*`. The run came
  # back rc 0 with 105 rows reading "neither", which is a plausible wrong
  # answer rather than a crash. drill-gate.sh:1585 anchors the same way.
  find "$root" -mindepth 3 -maxdepth 3 -type f -name "$meta" \
    ! -path "${root}/.*" ! -path "${root}/*/.*" | sort > "$list"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    files+=("$f")
  done < "$list"
  : > "$out"
  # ONE awk over the whole list. A loop calling awk per file is the per-row
  # fork this project has produced twice, and at 64 plus 25 items it is the
  # whole wall clock.
  if [ "${#files[@]}" -gt 0 ]; then
    awk "$FLATTEN_AWK" "${files[@]}" > "$out"
  fi
}

flatten_corpus "$DRILL_ROOT" META.md "$SCRATCH/drill-pairs"
flatten_corpus "$READING_ROOT" USES.md "$SCRATCH/reading-pairs"

# ---------------------------------------------------------------------------
# Every declared construct has to resolve to a field 4 value.
#
# An unresolved name is a typo that would otherwise just lower the coverage
# count, silently and in the direction that looks like honest work. This is
# the check harness/reading-gate.sh:220-223 says it cannot run, because it
# does not read the inventory at all.
# ---------------------------------------------------------------------------
# The single quotes are load-bearing: `$0` and `$1` are awk field references
# and must not expand in the shell.
# shellcheck disable=SC2016
UNKNOWN_AWK='
NR == FNR { known[$0] = 1; next }
{ if (!($1 in known)) bad[$1] = 1 }
END { for (k in bad) print k }
'
awk -F'\t' "$UNKNOWN_AWK" "$SCRATCH/names" \
  "$SCRATCH/drill-pairs" "$SCRATCH/reading-pairs" | sort > "$SCRATCH/unknown"

if [ -s "$SCRATCH/unknown" ]; then
  printf 'gen-coverage.sh: %s declared construct name(s) match no field 4 value:\n' \
    "$(wc -l < "$SCRATCH/unknown")" >&2
  sed 's/^/  /' "$SCRATCH/unknown" >&2
  printf '\nA declared name has to be spelled as drill/INVENTORY.md field 4 spells it.\n' >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Rewrite. Non-ROW lines come back verbatim. A ROW line keeps fields 1 to 7
# and gets fields 8, 9 and 10 rebuilt from the two flat files.
# ---------------------------------------------------------------------------
# The single quotes are load-bearing: `$1` through `$10` are awk field
# references and must not expand in the shell.
# shellcheck disable=SC2016
REWRITE_AWK='
function add(store, key, slug) {
  if (index(FS_SEP store[key] FS_SEP, FS_SEP slug FS_SEP) > 0) return
  store[key] = (store[key] == "") ? slug : store[key] FS_SEP slug
}
BEGIN { FS_SEP = "," }
FILENAME == DRILLP   { add(d, $1, $2); next }
FILENAME == READINGP { add(r, $1, $2); next }
{
  if ($1 != "ROW") { print; next }
  name = $4
  di = (name in d) ? d[name] : ""
  ri = (name in r) ? r[name] : ""
  if (di != "" && ri != "")      cov = "both"
  else if (di != "")             cov = "drill-only"
  else if (ri != "")             cov = "reading-only"
  else                           cov = "neither"
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7, di, ri, cov
}
'

generate() {
  awk -F'\t' -v DRILLP="$SCRATCH/drill-pairs" -v READINGP="$SCRATCH/reading-pairs" \
    "$REWRITE_AWK" "$SCRATCH/drill-pairs" "$SCRATCH/reading-pairs" "$INVENTORY"
}

case "$MODE" in
  stdout)
    generate
    ;;
  check)
    generate > "$SCRATCH/regenerated"
    if diff -u "$INVENTORY" "$SCRATCH/regenerated" > "$SCRATCH/drift"; then
      printf 'gen-coverage.sh: %s matches the corpora (%s rows)\n' "$INVENTORY" "$ROWS"
    else
      printf 'gen-coverage.sh: %s has drifted from the corpora. Regenerate with\n' "$INVENTORY" >&2
      printf '  bash scripts/gen-coverage.sh\n\n' >&2
      cat "$SCRATCH/drift" >&2
      exit 1
    fi
    ;;
  write)
    generate > "$SCRATCH/regenerated"
    cat "$SCRATCH/regenerated" > "$INVENTORY"
    awk -F'\t' '$1 == "ROW" { print $10 }' "$INVENTORY" | sort | uniq -c | sed 's/^/  /'
    printf 'gen-coverage.sh: wrote %s rows of coverage into %s\n' "$ROWS" "$INVENTORY"
    ;;
esac
