#!/usr/bin/env bash
# deliver-problems.sh: deliver one problem into a practice tree, under the
# directory name its position in the ramp calls for, without ever handing over
# the author's own copy and without ever overwriting work in progress.
#
# Usage:  scripts/deliver-problems.sh [--check] <name> [dest-root]
#
#   --check    resolve everything and print what would be delivered. Writes
#              nothing.
#   name       the bare problem name, e.g. river-call. Never the numbered
#              directory name.
#   dest-root  where to deliver into (default: $HOME/tla-practice/problems)
#
# Env:    DELIVER_PROBLEMS_SRC_ROOT   override the source repo root (default:
#                                     the repo this script lives in)
#
# Exit:   0 on success, including a run that only skipped files already there
#         1 on a usage error, an unresolvable or empty source, or a destination
#           that already holds this problem under a different number
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# Everything under <location>/<name>/statement/ lands, recursively. That tree is
# the manifest. This script does not know the name of a single file it delivers,
# and that is the whole point of it.
#
# The one thing it WITHHOLDS is a file whose name ends -with-author-notes.md.
# That is the author's annotated copy of the statement, and it carries the
# reasoning the problem exists to make the reader do. Every withheld file is
# reported on stdout, so a withholding is visible rather than silent.
#
# Nothing outside statement/ is delivered. reference/, reports/, author-notes/
# and VECTOR.md sit beside it and are the answer key, the grading history and
# the load vector.
#
# WHY THE MANIFEST IS A TREE AND NOT A LIST
#
# The shape is not uniform across the ramp. A problem whose load vector carries
# representation 1 HANDS the learner a spec, so it ships a .tla or a .cfg. A
# representation-2 problem makes the learner write one, so it ships neither.
# Three of the seven on the ramp ship a starter artifact and four do not.
#
# On 2026-10-02 that asymmetry was guessed rather than read. The guess was
# PROBLEM.md plus ATTEMPT-LOG.md plus traces/, which deleted bonded-store's
# BondedStore.tla, river-call's RiverCall.cfg and assay-office's
# AssayOffice.tla. Two problems then got reported as half-attempted when what
# was being read was the shipped artifact, and the wrong reading of a learner's
# progress cost more than the deletion did.
#
# So the manifest is the tree, and a filename appears nowhere in this script.
# A per-problem exclusion list was the other way to express the one
# withholding, and it is the same mistake one layer along: a list is a second
# manifest, and it drifts from the tree the moment somebody adds a file. The
# convention cannot drift, because there is only one place to read it from.
#
# ---------------------------------------------------------------------------
# THE NUMBER ON THE DIRECTORY
#
# A problem is delivered as NN_name, where NN is its 1-based position in
# <dest-root>/ORDER. ORDER is the one source of truth for the ramp's sequence,
# and scripts/number-problems.sh owns that convention. Blank lines, comment
# lines, and the two `checkpoint:` markers consume no position, so a position is
# not a line number.
#
# The parse below is DUPLICATED from scripts/number-problems.sh rather than
# shared with it, because sharing means editing that file. What keeps the copy
# honest is harness/test-deliver-problems.sh, which hands one ORDER to both
# scripts and requires the same directory names out of each. Extracting a
# shared parse is the better end state and wants its own bead.
#
# A name ORDER does not carry is off the ramp by convention, so it delivers
# under its bare name. A destination with no ORDER at all delivers the same way
# and says so on stderr: an unnumbered directory is a state
# scripts/number-problems.sh fixes the moment ORDER grows the entry, so a
# missing ORDER is worth reporting without being worth refusing.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE
#
# ~/tla-practice is not a git repo and it holds the only copy of a learner's
# work, so a clobbered file does not come back. Every file this script places is
# checked for existence first. An existing file is left untouched and reported
# on stdout as "skipped (exists): <path>", and its untouched siblings still
# land, because the rule lives per file rather than per directory.
#
# There is one refusal on top of that. If the destination already holds this
# problem under a DIFFERENT number, delivering alongside it would leave two
# directories for one ORDER entry, which scripts/number-problems.sh then
# reports as ambiguous forever. That run refuses and changes nothing.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check] <name> [dest-root]

  --check    print what would be delivered, and write nothing
  name       the bare problem name, e.g. river-call
  dest-root  where to deliver into (default: \$HOME/tla-practice/problems)

Env:
  DELIVER_PROBLEMS_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
USAGE
}

SRC_ROOT="${DELIVER_PROBLEMS_SRC_ROOT:-$REPO_ROOT}"

# The three places a problem can live, by pipeline. authoring/ holds the seven
# on the ramp, curated/ holds hand-curated ones, sources/problems/ holds the
# prose pipeline's output.
SRC_LOCATIONS=(authoring curated sources/problems)

CHECK_ONLY=0
NAME=""
DEST_ROOT=""
POSITIONAL=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "$0: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      POSITIONAL=$((POSITIONAL + 1))
      case "$POSITIONAL" in
        1) NAME="$1" ;;
        2) DEST_ROOT="$1" ;;
        *)
          echo "$0: unexpected extra argument: $1" >&2
          usage
          exit 1
          ;;
      esac
      shift
      ;;
  esac
done

# Anything left after a bare `--` is still an argument.
while [ "$#" -gt 0 ]; do
  POSITIONAL=$((POSITIONAL + 1))
  case "$POSITIONAL" in
    1) NAME="$1" ;;
    2) DEST_ROOT="$1" ;;
    *)
      echo "$0: unexpected extra argument: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if [ -z "$NAME" ]; then
  echo "$0: no problem name given" >&2
  usage
  exit 1
fi

if [ -z "$DEST_ROOT" ]; then
  DEST_ROOT="$HOME/tla-practice/problems"
fi

# ---------------------------------------------------------------------------
# Resolve the source. Exactly one of the three locations has to carry it.
#
# This happens BEFORE the destination is created, so every fatal path below
# leaves the filesystem exactly as it found it.
# ---------------------------------------------------------------------------

found_statements=()
found_dirs=()

for loc in "${SRC_LOCATIONS[@]}"; do
  if [ -d "$SRC_ROOT/$loc/$NAME/statement" ]; then
    found_statements+=("$SRC_ROOT/$loc/$NAME/statement")
  fi
  if [ -d "$SRC_ROOT/$loc/$NAME" ]; then
    found_dirs+=("$SRC_ROOT/$loc/$NAME")
  fi
done

if [ "${#found_statements[@]}" -gt 1 ]; then
  echo "$0: ambiguous: more than one location carries a problem called '$NAME'" >&2
  for s in "${found_statements[@]}"; do
    echo "$0:   $s" >&2
  done
  echo "$0: a problem belongs to one pipeline. Rename one of them, or deliver by hand." >&2
  exit 1
fi

if [ "${#found_statements[@]}" -eq 0 ]; then
  if [ "${#found_dirs[@]}" -gt 0 ]; then
    echo "$0: '$NAME' has no statement/ directory, so there is nothing to deliver:" >&2
    for d in "${found_dirs[@]}"; do
      echo "$0:   $d" >&2
    done
    echo "$0: statement/ is the delivered manifest. A problem without one is not ready." >&2
    exit 1
  fi
  echo "$0: no such problem: '$NAME'. Looked in:" >&2
  for loc in "${SRC_LOCATIONS[@]}"; do
    echo "$0:   $SRC_ROOT/$loc/$NAME/statement" >&2
  done
  echo "$0: the argument is the bare problem name, never the numbered directory name." >&2
  exit 1
fi

SRC_STATEMENT="${found_statements[0]}"

# ---------------------------------------------------------------------------
# Build the manifest from the tree, and split it into what lands and what is
# withheld.
#
# is_withheld <basename>
#
# The author's annotated copy of the statement. A name, not a list, so a problem
# that grows one tomorrow is covered without anybody remembering to say so.
is_withheld() {
  case "$1" in
    *-with-author-notes.md) return 0 ;;
  esac
  return 1
}

deliver_rel=()
withheld_rel=()

while IFS= read -r -d '' src_file; do
  rel="${src_file#"$SRC_STATEMENT/"}"
  if is_withheld "$(basename -- "$rel")"; then
    withheld_rel+=("$rel")
  else
    deliver_rel+=("$rel")
  fi
done < <(find "$SRC_STATEMENT" -type f -print0 | LC_ALL=C sort -z)

if [ "${#deliver_rel[@]}" -eq 0 ]; then
  echo "$0: nothing to deliver. $SRC_STATEMENT holds no deliverable file." >&2
  if [ "${#withheld_rel[@]}" -gt 0 ]; then
    echo "$0: it holds ${#withheld_rel[@]} file(s), and all of them are author notes." >&2
  else
    echo "$0: the statement/ directory is empty." >&2
  fi
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve the position in ORDER.
#
# DUPLICATED from scripts/number-problems.sh. See the header. The filter set and
# the width rule have to match that script exactly, and
# harness/test-deliver-problems.sh is what holds them to it.
# ---------------------------------------------------------------------------

ORDER_FILE="$DEST_ROOT/ORDER"
names=()

if [ -f "$ORDER_FILE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    [ -z "$trimmed" ] && continue
    case "$trimmed" in
      '#'*) continue ;;
      'checkpoint: ch13') continue ;;
      'checkpoint: refinement') continue ;;
    esac
    names+=("$trimmed")
  done <"$ORDER_FILE"
else
  echo "$0: no ORDER file at $ORDER_FILE, so '$NAME' cannot be numbered." >&2
  echo "$0: delivering under its bare name. Run scripts/number-problems.sh once ORDER names it." >&2
fi

total=${#names[@]}
width=2
[ "$total" -gt 99 ] && width=3

DEST_NAME="$NAME"
pos=0
for entry in "${names[@]}"; do
  pos=$((pos + 1))
  if [ "$entry" = "$NAME" ]; then
    DEST_NAME=$(printf "%0${width}d_%s" "$pos" "$NAME")
    break
  fi
done

if [ "$DEST_NAME" = "$NAME" ] && [ -f "$ORDER_FILE" ]; then
  echo "$0: ORDER does not name '$NAME', so it is off the ramp." >&2
  echo "$0: delivering under its bare name, which scripts/number-problems.sh leaves alone." >&2
fi

DEST_DIR="$DEST_ROOT/$DEST_NAME"

# ---------------------------------------------------------------------------
# Refuse a destination that already holds this problem under another name.
#
# The match is the one scripts/number-problems.sh uses to find the directory
# belonging to an ORDER entry: the bare name, or <digits>_<name>. Two of those
# for one entry is the "ambiguous" error that script reports, and delivering is
# how you create it.
# ---------------------------------------------------------------------------

matches_name() {
  local base="$1" digits rest
  [ "$base" = "$NAME" ] && return 0
  digits="${base%%_*}"
  [ "$digits" = "$base" ] && return 1
  [ -z "$digits" ] && return 1
  case "$digits" in
    *[!0-9]*) return 1 ;;
  esac
  rest="${base#*_}"
  [ "$rest" = "$NAME" ]
}

if [ -d "$DEST_ROOT" ]; then
  strangers=()
  for d in "$DEST_ROOT"/*/; do
    [ -d "$d" ] || continue
    base="${d%/}"
    base="${base##*/}"
    [ "$base" = "$DEST_NAME" ] && continue
    if matches_name "$base"; then
      strangers+=("$base")
    fi
  done

  if [ "${#strangers[@]}" -gt 0 ]; then
    echo "$0: $DEST_ROOT already holds '$NAME' under a different name:" >&2
    for s in "${strangers[@]}"; do
      echo "$0:   $s" >&2
    done
    echo "$0: wanted to deliver into '$DEST_NAME'. Two directories for one ORDER entry" >&2
    echo "$0: is the 'ambiguous' error scripts/number-problems.sh then reports forever." >&2
    echo "$0: run scripts/number-problems.sh '$DEST_ROOT' first, then deliver." >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Report the withholding either way, so it is never silent.
# ---------------------------------------------------------------------------

for rel in "${withheld_rel[@]}"; do
  echo "withheld (author notes): $SRC_STATEMENT/$rel"
done

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "source: $SRC_STATEMENT"
  echo "destination: $DEST_DIR"
  for rel in "${deliver_rel[@]}"; do
    if [ -e "$DEST_DIR/$rel" ]; then
      echo "would skip (exists): $DEST_DIR/$rel"
    else
      echo "would deliver: $DEST_DIR/$rel"
    fi
  done
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# deliver_file <src> <dest>
#
# The one place the never-overwrite rule lives. Every file goes through here one
# at a time, so a hand-edited file inside the tree is left alone without holding
# back its untouched siblings.
# ---------------------------------------------------------------------------

deliver_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    echo "skipped (exists): $dest"
    return 0
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
}

mkdir -p -- "$DEST_DIR" || exit 1

rc=0
for rel in "${deliver_rel[@]}"; do
  if ! deliver_file "$SRC_STATEMENT/$rel" "$DEST_DIR/$rel"; then
    echo "$0: failed to deliver: $DEST_DIR/$rel" >&2
    rc=1
  fi
done

exit "$rc"
