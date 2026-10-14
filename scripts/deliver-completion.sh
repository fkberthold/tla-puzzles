#!/usr/bin/env bash
# deliver-completion.sh: deliver a completion item into a practice tree (the
# brief, the machines that grade it, and the file the learner edits), without
# handing over the worked answer or the construct list.
#
# Usage:  scripts/deliver-completion.sh [--check] <item|family|all> [dest-root]
#
#   --check    resolve everything and print what would be delivered. Writes
#              nothing. --dry-run is an accepted alias. See WHY TWO NAMES below.
#   selector   `all`, a family name such as `sets`, or an item such as
#              `sets/01-clockface`. A leading completion/ and a trailing slash
#              are stripped, because the item's own PROMPT.md prints the
#              repo-relative form and that is what gets pasted.
#   dest-root  where to deliver into (default: $HOME/tla-practice/completion)
#
# Env:    DELIVER_COMPLETION_SRC_ROOT   override the source repo root (default:
#                                       the repo this script lives in)
#
# Exit:   0 on success, including a run that only skipped files already there
#         1 on a usage error, an unresolvable selector, a source tree holding
#           no item, an item missing a manifest part, or a failed copy
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# Three things land per item, at <dest-root>/<family>/<NN-slug>/:
#
#   PROMPT.md   the brief, including the table of machines and the code each
#               one must report
#   EXPECT      tab-delimited, one `stem<TAB>rc` row per machine. The file
#               completion/verify-item.sh reads to know what to run and what
#               each run must come back with.
#   work/       the whole tree, recursively. Claims.tla is the file the learner
#               edits, and the .tla/.cfg pairs beside it are the machines.
#
# Two stay behind, and every withheld entry is reported on stdout so a
# withholding is visible rather than silent:
#
#   ANSWER.md   the worked claims and the variants that count as correct
#   META.md     the constructs the item exercises, and the trap it sets
#
# ---------------------------------------------------------------------------
# WHERE THIS DIFFERS FROM scripts/deliver-drill.sh, AND WHY
#
# deliver-drill.sh is the model for this script, and the bead asks for every
# deviation to be named. There are five.
#
# ONE. THE MANIFEST IS TWO NAMES PLUS A TREE, not one name.
#
# A drill item hands over a single file, so its manifest is the string
# "PROMPT.md". A completion item cannot work that way: the learner edits
# work/Claims.tla and the three machines beside it are what grade the result,
# so all of work/ has to travel. The manifest here is therefore two filenames
# and one directory delivered recursively.
#
# This is the same bet scripts/deliver-problems.sh makes on its statement/
# tree, and it is worth stating plainly: ANY file placed inside work/ is
# delivered, including one added tomorrow. A file placed anywhere ELSE in the
# item is withheld, including one added tomorrow. So the failure direction
# differs by location. I think the rule to carry away is that work/ is the
# public half of the item and the item root is the private half. An
# answer-bearing file belongs at the item root, never under work/.
#
# The reason for splitting it that way rather than naming every machine: a
# completion item's machine count is not fixed. 01-clockface ships three, and
# an item that needed five would deliver three under a name list and report
# success. A tree manifest cannot miscount.
#
# TWO. THERE IS A SELECTOR ARGUMENT, where deliver-drill.sh has none.
#
# deliver-drill.sh delivers the whole corpus every time, and argues that the
# never-overwrite rule is what makes a repeat run the normal way a new item
# arrives. That argument still holds here and `all` is how you ask for it. The
# selector exists on top of it because a completion item is a sitting, not a
# page: the ramp hands them over one at a time, and delivering the next six
# alongside the one being worked turns a sitting into a menu. The shape of the
# argument list is scripts/deliver-problems.sh's, `[--check] <selector>
# [dest-root]`, since that is this repo's existing form for a delivery script
# that takes one.
#
# THREE. WHY TWO NAMES FOR THE SAME FLAG.
#
# Both sibling delivery scripts spell it --check, and the bead's brief asked
# for --dry-run. Rather than pick one and leave the other reading as a bug,
# both are accepted and they are the same flag. --check is the one this
# project's other scripts carry, so it is the one the usage line prints.
#
# FOUR. AN INCOMPLETE ITEM DELIVERS NOTHING, where a drill item without a
# PROMPT.md just has nothing to deliver.
#
# A completion item needs all three parts to be usable: verify-item.sh reads
# EXPECT to know what to run, and the machines live in work/. Half an item
# delivered is a learner reading a brief with nothing to run it against. So an
# item missing any part is named on stderr and delivers NONE of its parts,
# while its siblings still land, and the run exits 1.
#
# FIVE. THE COUNTS LINE COUNTS FILES, not prompts, because more than one file
# lands per item.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE, AND NEVER DELETE
#
# This matters more here than in either sibling script, and it is worth being
# exact about why. ~/tla-practice is not a git repo. work/Claims.tla is the
# file the learner writes their claims into, so after the first sitting the
# delivered copy and the learner's work are THE SAME FILE, and there is no
# second copy of it anywhere.
#
# So every file this script places is checked for existence first. An existing
# file is left alone and reported on stdout as "skipped (exists): <path>", and
# the run still exits 0, because a second delivery over a tree already
# carrying the item is the normal case rather than an error. The rule lives
# per file, so a learner who has edited Claims.tla still receives a machine
# added beside it.
#
# Nothing is removed, at any point, under any flag.
# This script has no delete path at all, and
# harness/test-deliver-completion.sh asserts it by scanning this file for a
# delete in command position, because the 2026-10-02 incident in the problems
# corpus was a deletion rather than a leak.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check] <item|family|all> [dest-root]

  --check    print what would be delivered, and write nothing
             (--dry-run is an accepted alias)
  selector   all, a family such as sets, or an item such as sets/01-clockface
  dest-root  where to deliver into (default: \$HOME/tla-practice/completion)

Env:
  DELIVER_COMPLETION_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
USAGE
}

SRC_ROOT="${DELIVER_COMPLETION_SRC_ROOT:-$REPO_ROOT}"

# The manifest. Read the WHAT LANDS section above before changing any of these
# three, and change harness/test-deliver-completion.sh in the same commit.
PROMPT_NAME="PROMPT.md"
EXPECT_NAME="EXPECT"
WORK_NAME="work"

CHECK_ONLY=0
SELECTOR=""
DEST_ROOT=""
POSITIONAL=0

take_positional() {
  POSITIONAL=$((POSITIONAL + 1))
  case "$POSITIONAL" in
    1) SELECTOR="$1" ;;
    2) DEST_ROOT="$1" ;;
    *)
      echo "$0: unexpected extra argument: $1" >&2
      usage
      exit 1
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check|--dry-run)
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

if [ -z "$SELECTOR" ]; then
  echo "$0: no item, family or 'all' given" >&2
  usage
  exit 1
fi

if [ -z "$DEST_ROOT" ]; then
  DEST_ROOT="$HOME/tla-practice/completion"
fi

SRC_COMPLETION="$SRC_ROOT/completion"

# ---------------------------------------------------------------------------
# Normalise the selector.
#
# `completion/sets/01-clockface` is the form the item's own PROMPT.md prints,
# so it is the form that gets pasted. A trailing slash is what tab completion
# produces. Both are stripped rather than refused.
#
# A selector is a position inside the corpus and never a path out of it, so an
# absolute one or one carrying .. is refused rather than normalised. There is
# no sanitising here that could be got around: the refusal is the handling.
# ---------------------------------------------------------------------------

want="$SELECTOR"
want="${want#./}"
want="${want#completion/}"
while [ "$want" != "${want%/}" ]; do
  want="${want%/}"
done

case "$want" in
  /*|*..*)
    echo "$0: a selector names a position inside completion/, not a path: '$SELECTOR'" >&2
    usage
    exit 1
    ;;
esac

if [ -z "$want" ]; then
  echo "$0: no item, family or 'all' given" >&2
  usage
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve the source, before the destination is created, so every fatal path
# below leaves the filesystem exactly as it found it.
# ---------------------------------------------------------------------------

if [ ! -d "$SRC_COMPLETION" ]; then
  echo "$0: no completion corpus at $SRC_COMPLETION" >&2
  echo "$0: set DELIVER_COMPLETION_SRC_ROOT to the repo root that carries completion/." >&2
  exit 1
fi

# An item is a directory two levels under completion/, which makes completion/
# itself the manifest at the item level. completion/verify-item.sh sits one
# level up and is not a family.
#
# The hidden-directory predicate is ANCHORED at the completion root, the way
# scripts/deliver-drill.sh anchors its own. A bare `-not -path '*/.*'` matches
# REPO_ROOT itself for every agent working under .claude/worktrees/agent-*, and
# the item list comes back empty on a tree that is fine.
all_items=()
while IFS= read -r item_dir; do
  [ -n "$item_dir" ] || continue
  all_items+=("${item_dir#"$SRC_COMPLETION/"}")
done < <(find "$SRC_COMPLETION" -mindepth 2 -maxdepth 2 -type d \
  ! -name '.*' ! -path "$SRC_COMPLETION/.*" | LC_ALL=C sort)

if [ "${#all_items[@]}" -eq 0 ]; then
  echo "$0: $SRC_COMPLETION holds no item, so there is nothing to deliver." >&2
  echo "$0: an item is a directory at completion/<family>/<NN-slug>." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Apply the selector.
#
# `all` is every item. A selector carrying a slash is one item, matched
# exactly. Anything else is a family, matched as a path prefix. A bare item
# slug is NOT resolved across families on purpose: two families are free to
# both hold an 01-something, and a selector that picked one of them without
# saying so would deliver the wrong sitting.
# ---------------------------------------------------------------------------

items=()
if [ "$want" = "all" ]; then
  items=("${all_items[@]}")
else
  for rel in "${all_items[@]}"; do
    case "$want" in
      */*) [ "$rel" = "$want" ] && items+=("$rel") ;;
      *)   [ "${rel%%/*}" = "$want" ] && items+=("$rel") ;;
    esac
  done
fi

if [ "${#items[@]}" -eq 0 ]; then
  echo "$0: no such item or family: '$SELECTOR'" >&2
  echo "$0: looked under $SRC_COMPLETION. The corpus holds:" >&2
  for rel in "${all_items[@]}"; do
    echo "$0:   $rel" >&2
  done
  echo "$0: a selector is 'all', a family, or <family>/<NN-slug>." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Split every selected item into what lands and what is withheld.
#
# The withheld report is built from the item's own top-level entries, dotfiles
# included, so a stray one is reported rather than quietly tolerated. A
# directory is one line rather than its contents, because what the report is
# about is the decision not to deliver that entry.
# ---------------------------------------------------------------------------

is_manifest_name() {
  case "$1" in
    "$PROMPT_NAME"|"$EXPECT_NAME"|"$WORK_NAME") return 0 ;;
  esac
  return 1
}

deliver_rel=()
withheld_paths=()
incomplete=()

for rel in "${items[@]}"; do
  item="$SRC_COMPLETION/$rel"
  missing=()
  [ -f "$item/$PROMPT_NAME" ] || missing+=("$PROMPT_NAME")
  [ -f "$item/$EXPECT_NAME" ] || missing+=("$EXPECT_NAME")
  [ -d "$item/$WORK_NAME" ]   || missing+=("$WORK_NAME/")

  if [ "${#missing[@]}" -eq 0 ]; then
    deliver_rel+=("$rel/$PROMPT_NAME")
    deliver_rel+=("$rel/$EXPECT_NAME")
    while IFS= read -r -d '' src_file; do
      deliver_rel+=("$rel/${src_file#"$item/"}")
    done < <(find "$item/$WORK_NAME" -type f -print0 | LC_ALL=C sort -z)
  else
    incomplete+=("$rel: ${missing[*]}")
  fi

  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    base="${entry##*/}"
    is_manifest_name "$base" && continue
    withheld_paths+=("$rel/$base")
  done < <(find "$item" -mindepth 1 -maxdepth 1 | LC_ALL=C sort)
done

# ---------------------------------------------------------------------------
# Report the withholding either way, so it is never silent.
# ---------------------------------------------------------------------------

for rel in "${withheld_paths[@]}"; do
  echo "withheld (not in the manifest): $SRC_COMPLETION/$rel"
done

for entry in "${incomplete[@]}"; do
  item_rel="${entry%%: *}"
  parts="${entry#*: }"
  for part in $parts; do
    echo "$0: $SRC_COMPLETION/$item_rel carries no $part, so the item is not deliverable." >&2
  done
  echo "$0: $item_rel delivers nothing. An item needs $PROMPT_NAME, $EXPECT_NAME and $WORK_NAME/ to be usable." >&2
done

echo "source: $SRC_COMPLETION"
echo "destination: $DEST_ROOT"

if [ "$CHECK_ONLY" -eq 1 ]; then
  to_land=0
  already=0
  for rel in "${deliver_rel[@]}"; do
    if [ -e "$DEST_ROOT/$rel" ]; then
      echo "would skip (exists): $DEST_ROOT/$rel"
      already=$((already + 1))
    else
      echo "would deliver: $DEST_ROOT/$rel"
      to_land=$((to_land + 1))
    fi
  done
  echo "$to_land file(s) to land, $already already there, ${#withheld_paths[@]} path(s) withheld"
  [ "${#incomplete[@]}" -eq 0 ] || exit 1
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# deliver_file <src> <dest>
#
# The one place the never-overwrite rule lives, copied in shape from
# scripts/deliver-drill.sh. Every file goes through here one at a time, so an
# item whose Claims.tla the learner has already written is left alone without
# holding back a machine added beside it.
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

for rel in "${deliver_rel[@]}"; do
  deliver_file "$SRC_COMPLETION/$rel" "$DEST_ROOT/$rel"
  case "$?" in
    0) landed=$((landed + 1)) ;;
    2) skipped=$((skipped + 1)) ;;
    *)
      echo "$0: failed to deliver: $DEST_ROOT/$rel" >&2
      rc=1
      ;;
  esac
done

echo "$landed file(s) landed, $skipped skipped, ${#withheld_paths[@]} path(s) withheld"

[ "${#incomplete[@]}" -eq 0 ] || rc=1

exit "$rc"
