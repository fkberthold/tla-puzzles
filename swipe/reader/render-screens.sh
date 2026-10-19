#!/usr/bin/env bash
# render-screens.sh -- bakes every model screen the swipe reader serves into
# swipe/reader/SCREENS.tsv (bead tla-7xql.14, epic tla-7xql).
#
# A level 1 item pins a state and a level 2 item pins a step, so both put the
# model on screen. swipe/level1/render.sh and swipe/level2/render.sh build
# that screen, and this script runs them once per model and writes the result
# down.
#
# ===========================================================================
# WHY THE SCREENS ARE BAKED RATHER THAN RENDERED WHEN THE SITE IS BUILT
# ===========================================================================
#
# swipe/level1/render.sh calls harness/levels/levels.sh, which reads SANY's
# semantic tree, so one screen is one JVM. Measured on this box: 0.49 s per
# model, 24 models across the two rungs, so about 12 s a run.
#
# The cost is the smaller half of the argument. The deciding half is that
# .github/workflows/pages.yml installs Python and mkdocs-material and NOTHING
# ELSE. There is no Java on the deploy runner and no tla2tools.jar. A
# scripts/build-docs.sh that rendered a screen would fail there, and it would
# fail on the deploy rather than on the gate, which is the worst place in this
# repo to discover a missing dependency. scripts/cibuild does install the
# toolchain, so the failure would also be invisible to the suite that runs on
# the same push.
#
# So this script runs on a dev box, its output is committed, and
# swipe/reader/emit-items.sh reads bytes. harness/test-swipe-reader.sh
# re-renders every screen and compares, which is what keeps the committed copy
# from drifting away from the renderer it came from.
#
# ===========================================================================
# THE FORMAT, AND THE ONE BYTE THAT LOOKS LIKE NOISE
# ===========================================================================
#
# Rows are tab-delimited and carry a literal marker in field 1, the house
# style of every table in this tree, so prose in this file can never be read
# as data.
#
#   SCREENFMT <tab> 1
#   SCREEN <tab> <level> <tab> <model> <tab> <n> <tab> |<text>
#   EMPTY  <tab> <level> <tab> <model> <tab> <reason>
#
# FIELD 5 OF A SCREEN ROW STARTS WITH A PIPE AND THE PIPE IS NOT PART OF THE
# LINE. A model screen carries blank lines between definitions and they are
# part of its layout, so they have to survive the round trip. Without the pipe
# a blank line is a trailing tab, and an editor that strips trailing
# whitespace on save would delete it silently: the file would still parse,
# every definition would run into the next one, and no gate would have
# anything to compare against. One byte buys a row that cannot be damaged by
# saving the file.
#
# Trailing whitespace inside a line is stripped for the same reason. The
# renderers indent their whole screen by three spaces, so a blank line arrives
# here as three spaces and would be just as fragile.
#
# THE LEADING THREE SPACES ARE REMOVED. swipe/level1/render.sh indents its
# screen for a terminal. The page has padding of its own, and three columns of
# a 390 pixel phone is about 24 pixels that no reader gets anything for.
#
# AN EMPTY ROW IS A FINDING RATHER THAN AN ERROR. Of the 33 reading/ modules,
# Ring renders no screen at all: its actions live in the PlusCal translation
# block under names the shown-roots rule does not reach, so the module
# declares no action as far as the rule is concerned and render.sh exits 1.
# That follows from the rule rather than breaking it, and PlusCal screens are
# separate work. No shipped item is about Ring, so the row exists for the
# emitter to refuse an item about a model that cannot be posed, and for the
# gate's control to have something real to plant.
#
# A MODEL WITH NEITHER SCREEN ROWS NOR AN EMPTY ROW IS A STALE FILE, and
# swipe/reader/emit-items.sh dies on it rather than withholding the items. The
# two cases look the same from the data and must not behave the same: one is a
# model that cannot be drawn and the other is this script not having been run.
#
# USAGE
#   swipe/reader/render-screens.sh [--out FILE] [--check] [--all-models]
#
#   --out FILE     write here instead of swipe/reader/SCREENS.tsv
#   --check        render into a temporary file and diff it against the
#                  committed one. Writes nothing. Exit 0 in sync, 3 stale
#   --all-models   every reading/ module at both rungs rather than only the
#                  models the corpora use. For measuring, not for committing
#   -h, --help     this text
#
# EXIT
#   0  written, or in sync under --check
#   1  a renderer failed in a way that is not an empty screen
#   2  usage error
#   3  --check found a difference

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/swipe/reader/SCREENS.tsv"
MODE="write"
SCOPE="corpus"

usage() {
  awk 'NR == 1 { next } /^[^#]/ { exit } { print }' "${BASH_SOURCE[0]}"
}

die() { printf 'render-screens.sh: %s\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --out)         OUT="${2:-}"; shift 2 ;;
    --check)       MODE="check"; shift ;;
    --all-models)  SCOPE="all"; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

cd "$ROOT" || exit 1

SCREENFMT=1

# The levels that put a model on screen. Level 0 pins nothing and shows no
# model, which is why the epic built it first.
LEVELS="1 2"

# ---------------------------------------------------------------------------
# models_for <level>
#
# The models that level's corpus actually draws on, read from field 12 of its
# item table. Derived rather than listed: a hand-kept list here is right until
# somebody authors an item on a new model, and then it is wrong with the gate
# still green.
# ---------------------------------------------------------------------------
models_for() {
  local lvl="$1"
  if [ "$SCOPE" = "all" ]; then
    find reading -name '*.tla' -type f -print0 \
      | xargs -0 -n1 basename \
      | sed 's/\.tla$//' \
      | LC_ALL=C sort -u
    return 0
  fi
  awk -F'\t' '$1 == "ITEM" { print $12 }' "swipe/level$lvl/ITEMS.tsv" \
    | LC_ALL=C sort -u
}

# ---------------------------------------------------------------------------
# normalize
#
# Strip the renderers' three-space terminal indent, then strip trailing
# whitespace, then prefix the pipe. harness/test-swipe-reader.sh writes this
# transformation again rather than calling it, so the committed file is
# compared against two independent readings of the same renderer.
# ---------------------------------------------------------------------------
normalize() {
  sed -e 's/^   //' -e 's/[[:space:]]*$//' -e 's/^/|/'
}

generate() {
  printf '# The baked model screens of the swipe reader (bead tla-7xql.14,\n'
  printf '# epic tla-7xql). GENERATED by swipe/reader/render-screens.sh.\n'
  printf '#\n'
  printf '# Do not hand-edit. Re-run the generator, which reads the corpora and\n'
  printf '# drives swipe/level1/render.sh and swipe/level2/render.sh. The header\n'
  printf '# of that script says why these are baked rather than rendered when\n'
  printf '# the site is built, and the short answer is that the deploy runner\n'
  printf '# has no Java on it.\n'
  printf '#\n'
  printf '# A SCREEN row is one line of one screen. Field 5 starts with a pipe\n'
  printf '# that is not part of the line, so a blank line in a screen cannot be\n'
  printf '# destroyed by an editor that strips trailing whitespace. An EMPTY row\n'
  printf '# is a model whose screen renders nothing, which Ring does because its\n'
  printf '# actions live in a PlusCal translation block.\n'
  printf '#\n'
  printf '#   grep -c "^SCREEN" swipe/reader/SCREENS.tsv\n'
  printf "#   awk -F'\\\\t' '\$1 == \"SCREEN\" && \$3 == \"Brackets\"' swipe/reader/SCREENS.tsv\n"
  printf '#\n'
  printf 'SCREENFMT\t%s\n' "$SCREENFMT"

  local lvl m path out rc n line
  local failed=0
  for lvl in $LEVELS; do
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      path="$(swipe/level1/render.sh --model-path "$m" 2>/dev/null)"
      if [ -z "$path" ]; then
        printf 'render-screens.sh: no reading/ module called %s\n' "$m" >&2
        failed=1
        continue
      fi
      out="$("swipe/level$lvl/render.sh" --model "$path" --screen 2>/dev/null)"
      rc=$?
      if [ "$rc" -ne 0 ] || [ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ]; then
        printf 'EMPTY\t%s\t%s\t%s\n' "$lvl" "$m" \
          "the shown-roots rule reaches no definition, so the screen renders empty"
        printf 'render-screens.sh: level %s %s renders an empty screen (rc %s)\n' \
          "$lvl" "$m" "$rc" >&2
        continue
      fi
      n=0
      while IFS= read -r line; do
        n=$((n + 1))
        printf 'SCREEN\t%s\t%s\t%s\t%s\n' "$lvl" "$m" "$n" "$line"
      done < <(printf '%s\n' "$out" | normalize)
    done < <(models_for "$lvl")
  done
  return "$failed"
}

if [ "$MODE" = "check" ]; then
  TMP="$(mktemp)"
  # shellcheck disable=SC2317
  trap 'rm -f "$TMP"' EXIT
  if ! generate > "$TMP"; then
    exit 1
  fi
  if [ ! -f "$OUT" ]; then
    printf 'render-screens.sh: %s does not exist\n' "$OUT" >&2
    exit 3
  fi
  if cmp -s "$TMP" "$OUT"; then
    printf 'render-screens.sh: %s is in sync with the renderers\n' "${OUT#"$ROOT"/}"
    exit 0
  fi
  printf 'render-screens.sh: %s is STALE. Re-run the generator.\n' "${OUT#"$ROOT"/}" >&2
  diff -u "$OUT" "$TMP" | sed -n '1,40p' >&2
  exit 3
fi

TMP="$(mktemp)"
# shellcheck disable=SC2317
trap 'rm -f "$TMP"' EXIT
if ! generate > "$TMP"; then
  printf 'render-screens.sh: a model could not be resolved, so nothing was written\n' >&2
  exit 1
fi
mv "$TMP" "$OUT"
trap - EXIT
# awk on field 1 rather than grep on a prefix. `grep -c '^SCREEN'` counts the
# SCREENFMT row as well, which made this line report 374 against a real 373
# and put the wrong number into swipe/README.md before the gate printed its
# own count and the two disagreed.
printf 'render-screens.sh: wrote %s screen lines and %s empty models to %s\n' \
  "$(awk -F'\t' '$1 == "SCREEN" { n++ } END { print n + 0 }' "$OUT")" \
  "$(awk -F'\t' '$1 == "EMPTY" { n++ } END { print n + 0 }' "$OUT")" \
  "${OUT#"$ROOT"/}"
