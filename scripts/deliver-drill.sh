#!/usr/bin/env bash
# deliver-drill.sh: deliver the blank-page drill prompts into a practice tree,
# without handing over the worked answer, the construct list, or the modules
# that prove the answer checks.
#
# Usage:  scripts/deliver-drill.sh [--check] [dest-root]
#
#   --check    resolve everything and print what would be delivered. Writes
#              nothing.
#   dest-root  where to deliver into (default: $HOME/tla-practice/drill)
#
# Env:    DELIVER_DRILL_SRC_ROOT   override the source repo root (default: the
#                                  repo this script lives in)
#
# Exit:   0 on success, including a run that only skipped prompts already there
#         1 on a usage error, a source tree holding no item, an item carrying
#           no PROMPT.md, or a failed copy
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# One file per item lands, at <dest-root>/<family>/<NN-slug>/PROMPT.md, under
# the item's own source name. Every other top-level entry of the item stays
# behind, and each one is reported on stdout, so a withholding is visible
# rather than silent.
#
# Three stay behind across the corpus as it stands:
#
#   ANSWER.md   the worked answer and the variants that count as correct
#   META.md     every construct the item drills, and the trap it sets
#   verify/     the modules and configs that prove the answer checks
#
# META.md is the one worth being deliberate about. It names the trap in a
# single line, so reading it answers the question the drill asks. An item
# delivered with its META.md beside it is not a blank page any more.
#
# A drill item has no position on a ramp, so there is no ORDER file here and no
# renumbering. scripts/deliver-problems.sh carries both and neither applies:
# the number inside a family is an authoring order rather than a difficulty
# ramp, so the destination directory name is the source directory name.
#
# ---------------------------------------------------------------------------
# WHY THIS SCRIPT NAMES A FILE, AND ITS SIBLING REFUSES TO
#
# Read scripts/deliver-problems.sh's header before this section. It says at
# length that its manifest is the <name>/statement/ tree and that a filename
# appears nowhere in it. On 2026-10-02 a guessed manifest deleted 39 delivered
# files, among them bonded-store's BondedStore.tla, river-call's RiverCall.cfg
# and assay-office's AssayOffice.tla. Two problems then got read as
# half-attempted when what was being read was the shipped starter.
#
# This script deviates from that rule, and the deviation is deliberate. A drill
# item has no statement/ subdirectory to use as a tree manifest, so the three
# ways to say what lands are these:
#
#   Deliver the item's whole tree. Hands over ANSWER.md. Not an option.
#
#   Deliver everything EXCEPT a withheld name list. Fails UNSAFE. A new
#   answer-bearing file lands by default, and the list drifts from the tree the
#   moment somebody adds one.
#
#   Deliver PROMPT.md by name. Fails SAFE. A new file is missed rather than
#   leaked, and a missed file surfaces as a prompt that reads short.
#
# The third is what this script does, and the failure direction is the whole
# reason. A leak cannot be taken back once the learner has read it. A miss
# costs one more run after somebody says so.
#
# THE GATE IS WHAT MAKES THE DEVIATION SAFE. harness/test-drill.sh asserts
# that every item's top-level entry set is exactly ANSWER.md, META.md,
# PROMPT.md and verify. A fifth entry reddens the suite and names itself, which
# forces whoever adds it to decide whether it is deliverable before it can
# land. So the convention cannot drift quietly, which is the one thing a
# filename in a script otherwise guarantees. In 2026-10 the problems corpus was
# non-uniform AND ungated. The drill corpus is uniform AND gated, and I would
# not name a file here without the second half.
#
# A hidden entry counts. Both this script and the gate read the item directory
# with the dotfiles included, so a stray one is withheld here and reported
# there rather than being quietly tolerated by one of the two.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE, AND NEVER DELETE
#
# ~/tla-practice is not a git repo and it holds the only copy of the work done
# in it, so a clobbered file does not come back. Every file this script places
# is checked for existence first. An existing file is left alone and reported
# on stdout as "skipped (exists): <path>", and the run still exits 0, because a
# second delivery over a tree already carrying the corpus is the normal case
# rather than an error.
#
# Nothing is removed, at any point, under any flag. This script has no delete
# path at all.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check] [dest-root]

  --check    print what would be delivered, and write nothing
  dest-root  where to deliver into (default: \$HOME/tla-practice/drill)

Env:
  DELIVER_DRILL_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
USAGE
}

SRC_ROOT="${DELIVER_DRILL_SRC_ROOT:-$REPO_ROOT}"

# The one file an item hands over. Read the manifest section above before
# changing this, and change harness/test-drill.sh in the same commit.
PROMPT_NAME="PROMPT.md"

CHECK_ONLY=0
DEST_ROOT=""
POSITIONAL=0

take_positional() {
  POSITIONAL=$((POSITIONAL + 1))
  case "$POSITIONAL" in
    1) DEST_ROOT="$1" ;;
    *)
      echo "$0: unexpected extra argument: $1" >&2
      usage
      exit 1
      ;;
  esac
}

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
      take_positional "$1"
      shift
      ;;
  esac
done

# Anything after a bare `--` is still an argument.
while [ "$#" -gt 0 ]; do
  take_positional "$1"
  shift
done

if [ -z "$DEST_ROOT" ]; then
  DEST_ROOT="$HOME/tla-practice/drill"
fi

SRC_DRILL="$SRC_ROOT/drill"

# ---------------------------------------------------------------------------
# Resolve the source, before the destination is created, so every fatal path
# below leaves the filesystem exactly as it found it.
# ---------------------------------------------------------------------------

if [ ! -d "$SRC_DRILL" ]; then
  echo "$0: no drill corpus at $SRC_DRILL" >&2
  echo "$0: set DELIVER_DRILL_SRC_ROOT to the repo root that carries drill/." >&2
  exit 1
fi

# An item is a directory two levels under drill/, which makes drill/ itself the
# manifest at the item level. drill/INVENTORY.md and drill/COLD-LIST.md sit one
# level up and are not families.
#
# The hidden-directory predicate is ANCHORED at the drill root, the way
# harness/test-drill.sh anchors its own. A bare `-not -path '*/.*'` matches
# REPO_ROOT itself for every agent working under .claude/worktrees/agent-*, and
# the item list comes back empty on a tree that is fine.
items=()
while IFS= read -r item_dir; do
  [ -n "$item_dir" ] || continue
  items+=("${item_dir#"$SRC_DRILL/"}")
done < <(find "$SRC_DRILL" -mindepth 2 -maxdepth 2 -type d \
  ! -name '.*' ! -path "$SRC_DRILL/.*" | LC_ALL=C sort)

if [ "${#items[@]}" -eq 0 ]; then
  echo "$0: $SRC_DRILL holds no item, so there is nothing to deliver." >&2
  echo "$0: an item is a directory at drill/<family>/<NN-slug>." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Split every item's top-level entries into the prompt and the withholding.
#
# An item with no prompt is a defect in the item rather than in the run, so it
# is named on stderr and its siblings still land. The run exits 1 all the same:
# a delivery that quietly handed over 31 prompts out of 32 and reported success
# is the failure this bead exists to make loud.
# ---------------------------------------------------------------------------

deliver_items=()
withheld_paths=()
missing_prompt=()

for rel in "${items[@]}"; do
  if [ -f "$SRC_DRILL/$rel/$PROMPT_NAME" ]; then
    deliver_items+=("$rel")
  else
    missing_prompt+=("$rel")
  fi
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    base="${entry##*/}"
    [ "$base" = "$PROMPT_NAME" ] && continue
    withheld_paths+=("$rel/$base")
  done < <(find "$SRC_DRILL/$rel" -mindepth 1 -maxdepth 1 | LC_ALL=C sort)
done

# ---------------------------------------------------------------------------
# Report the withholding either way, so it is never silent.
# ---------------------------------------------------------------------------

for rel in "${withheld_paths[@]}"; do
  echo "withheld (not $PROMPT_NAME): $SRC_DRILL/$rel"
done

for rel in "${missing_prompt[@]}"; do
  echo "$0: $SRC_DRILL/$rel carries no $PROMPT_NAME, so it has nothing to deliver." >&2
done

echo "source: $SRC_DRILL"
echo "destination: $DEST_ROOT"

if [ "$CHECK_ONLY" -eq 1 ]; then
  to_land=0
  already=0
  for rel in "${deliver_items[@]}"; do
    if [ -e "$DEST_ROOT/$rel/$PROMPT_NAME" ]; then
      echo "would skip (exists): $DEST_ROOT/$rel/$PROMPT_NAME"
      already=$((already + 1))
    else
      echo "would deliver: $DEST_ROOT/$rel/$PROMPT_NAME"
      to_land=$((to_land + 1))
    fi
  done
  echo "$to_land prompt(s) to land, $already already there, ${#withheld_paths[@]} path(s) withheld"
  [ "${#missing_prompt[@]}" -eq 0 ] || exit 1
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# deliver_file <src> <dest>
#
# The one place the never-overwrite rule lives. Every file goes through here
# one at a time, so an item the learner has already started is left alone
# without holding back the items beside it.
# ---------------------------------------------------------------------------

deliver_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    echo "skipped (exists): $dest"
    return 2
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
}

rc=0
landed=0
skipped=0

for rel in "${deliver_items[@]}"; do
  deliver_file "$SRC_DRILL/$rel/$PROMPT_NAME" "$DEST_ROOT/$rel/$PROMPT_NAME"
  case "$?" in
    0) landed=$((landed + 1)) ;;
    2) skipped=$((skipped + 1)) ;;
    *)
      echo "$0: failed to deliver: $DEST_ROOT/$rel/$PROMPT_NAME" >&2
      rc=1
      ;;
  esac
done

echo "$landed prompt(s) landed, $skipped skipped, ${#withheld_paths[@]} path(s) withheld"

[ "${#missing_prompt[@]}" -eq 0 ] || rc=1

exit "$rc"
