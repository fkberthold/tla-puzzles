#!/usr/bin/env bash
# deliver-exercises.sh: deliver one chapter's exercise set into a practice
# tree, without ever handing over the answers.
#
# Usage:  scripts/deliver-exercises.sh <chapter> [dest-root]
#
#   chapter    integer 2-13, the chapter to deliver exercises for
#   dest-root  where to deliver into (default: $HOME/tla-practice/exercises)
#
# Env:    DELIVER_SRC_ROOT   override the source root (default: exercises/
#                             under the repo root)
#
# Exit:   0 on success (including a partial delivery that only skipped an
#           already-present file, or logged a missing earlier cheat sheet)
#         1 on a usage error or a broken source tree
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# For chapter N this delivers EXERCISES.md, starters/ (recursively), a
# LOG.md scaffold from the shared template, and cheatsheets/chMM.md for every
# chapter MM below N that has one. It never delivers chapter N's own cheat
# sheet, any cheat sheet at or above N, references/, reports/, or
# COVERAGE.md. Those are exactly the material that would hand over the
# answer to the chapter being practiced, or the graded history of a previous
# attempt.
#
# A cheat sheet missing for an earlier chapter is reported on stderr and
# skipped; it is not fatal, because a chapter can legitimately have nothing
# to condense yet. A missing source chapter, or a source chapter with no
# EXERCISES.md, is fatal: there is nothing to deliver.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE
#
# The destination is where the work happens, so a second run over a
# half-solved set must not clobber it. Every file this script places is
# checked for existence first; an existing file is left untouched and
# reported on stdout as "skipped (exists): <path>", never touched again.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 <chapter> [dest-root]

  chapter    integer 2-13, the chapter to deliver exercises for
  dest-root  where to deliver into (default: \$HOME/tla-practice/exercises)

Env:
  DELIVER_SRC_ROOT   override the source root (default: $REPO_ROOT/exercises)
USAGE
}

SRC_ROOT="${DELIVER_SRC_ROOT:-$REPO_ROOT/exercises}"

CHAPTER="${1:-}"
if [ -z "$CHAPTER" ] || ! [[ "$CHAPTER" =~ ^[0-9]+$ ]]; then
  usage
  exit 1
fi

# Strip any leading zero with the explicit base-10 prefix, so "02" and "2"
# compare equal instead of one of them being read as an (invalid) octal
# literal.
CHAPTER_NUM=$((10#$CHAPTER))

if [ "$CHAPTER_NUM" -lt 2 ] || [ "$CHAPTER_NUM" -gt 13 ]; then
  usage
  exit 1
fi

DEST_ROOT="${2:-$HOME/tla-practice/exercises}"

CHAPTER_PADDED=$(printf 'ch%02d' "$CHAPTER_NUM")
SRC_CHAPTER_DIR="$SRC_ROOT/$CHAPTER_PADDED"
DEST_CHAPTER_DIR="$DEST_ROOT/$CHAPTER_PADDED"

if [ ! -d "$SRC_CHAPTER_DIR" ]; then
  echo "$0: source chapter directory not found: $SRC_CHAPTER_DIR" >&2
  exit 1
fi

if [ ! -f "$SRC_CHAPTER_DIR/EXERCISES.md" ]; then
  echo "$0: source chapter has no EXERCISES.md: $SRC_CHAPTER_DIR/EXERCISES.md" >&2
  exit 1
fi

mkdir -p "$DEST_CHAPTER_DIR"

# deliver_file <src> <dest>
#
# The one place the never-overwrite rule lives. Every file this script places
# goes through here, one file at a time, so a hand-edited file inside a
# recursively-delivered directory (e.g. one starter out of several) is left
# alone without holding back its untouched siblings.
deliver_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    echo "skipped (exists): $dest"
    return
  fi
  mkdir -p "$(dirname -- "$dest")"
  cp "$src" "$dest"
}

deliver_file "$SRC_CHAPTER_DIR/EXERCISES.md" "$DEST_CHAPTER_DIR/EXERCISES.md"
deliver_file "$SRC_ROOT/templates/LOG.md" "$DEST_CHAPTER_DIR/LOG.md"

if [ -d "$SRC_CHAPTER_DIR/starters" ]; then
  while IFS= read -r -d '' src_file; do
    rel="${src_file#"$SRC_CHAPTER_DIR/starters/"}"
    deliver_file "$src_file" "$DEST_CHAPTER_DIR/starters/$rel"
  done < <(find "$SRC_CHAPTER_DIR/starters" -type f -print0)
fi

m=2
while [ "$m" -lt "$CHAPTER_NUM" ]; do
  m_padded=$(printf 'ch%02d' "$m")
  src_sheet="$SRC_ROOT/$m_padded/CHEATSHEET.md"
  if [ -f "$src_sheet" ]; then
    deliver_file "$src_sheet" "$DEST_CHAPTER_DIR/cheatsheets/$m_padded.md"
  else
    echo "missing sheet: $m_padded" >&2
  fi
  m=$((m + 1))
done

exit 0
