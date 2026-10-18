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
#
# ---------------------------------------------------------------------------
# AND THE THIRD STATE (beads tla-oa0m and tla-mjvx)
#
# Never-overwrite froze every delivered item at its delivery date, so a repair
# to a PROMPT.md reached the repo and never reached the learner. The tension is
# real rather than a bug: protecting a half-written Claims.tla and propagating
# a fix want opposite things from the same directory. A --force flag does not
# resolve it, because the file most worth fixing is the file most likely to
# hold the answers.
#
# So delivery records what it wrote. With that record there are three states
# instead of two, and only one of them is ambiguous:
#
#   absent                      deliver, as before
#   present, matches record     the learner has not edited it, so a moved
#                               source is safe to land and this script lands it
#   present, differs from       the learner's work. Never touched, whatever the
#     record                    source says, and reported as a conflict to
#                               merge by hand
#   present, no record          provenance unknown. Treated as the learner's
#                               work, which is the safe reading
#
# THE RECORD IS .delivered.sha256 IN THE ITEM DIRECTORY, one "<digest>
# <path relative to the item>" line per file, and ONLY A DELIVERY WRITES AN
# ENTRY. That last clause is the whole safety argument: an entry means this
# script put those exact bytes there, so a file matching its entry is provably
# unedited. Infer an entry from anything else and the inference is what
# overwrites the learner's work.
#
# SO "NEVER OVERWRITE" ABOVE IS NOW EXACTLY "NEVER OVERWRITE THE LEARNER'S
# WORK". The one file this script will replace is one it can prove it wrote
# itself, byte for byte. scripts/deliver-exercises.sh made the same change for
# the same reason on 2026-10-18 and this is that pattern applied here.
#
# WHAT THIS CANNOT DO RETROACTIVELY. An item delivered before records existed
# has none, so it stays in the ambiguous state and nothing gets auto-updated.
# --adopt is the safe bootstrap: it records an entry for every delivered file
# that is BYTE-IDENTICAL to its source, which is provably unedited, and records
# nothing for the rest.
#
# ---------------------------------------------------------------------------
# --verify IS THE DRIFT REPORT AND --check IS THE DRY RUN
#
# The two read alike and they answer different questions, which is the whole of
# bead tla-mjvx. --check reports what a delivery WOULD do, so on a tree that is
# already byte-identical it prints "0 to land, 66 already there" and exits 0.
# It cannot tell a stale tree from a current one. --verify compares content
# against the record and reports only what drifted.
#
# --verify is the spelling scripts/deliver-recall.sh already uses, so
# scripts/verify-delivery.sh can call one flag on every channel.
#
# STALE EXITS 3 AND CONFLICTED DOES NOT. The two are not the same kind of
# finding. Stale means a delivery is owed and somebody can act on it tonight.
# Conflicted means the file differs from its record, so it is the learner's own
# work, and the only correct action is to leave it alone forever. Returning 3
# for both would put a permanent red on every item the learner had actually
# worked, and a gate that is red every night for a reason nobody can act on is
# worse than no gate. Measured on the exercises channel the same week: 10 of 12
# chapters red, every one of them red because Frank had done the exercises.
#
# AN ABSENT DESTINATION ROOT IS A SKIP AT EXIT 0. No box but Frank's has a
# delivered tree and a CI runner never will.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check | --verify | --adopt] <item|family|all> [dest-root]

  --check    print what would be delivered, and write nothing
             (--dry-run is an accepted alias)
  --verify   compare every delivered file against its source and its delivery
             record, name every path that is stale or conflicted, and exit 3
             if any is stale. Conflicts are the learner's work: they are
             counted and reported and never failed on. Writes nothing. An
             absent destination root is a skip at exit 0.
  --adopt    record a digest for every delivered file that is byte-identical
             to its source, so later repairs can reach an item delivered
             before this script kept records. Copies nothing.
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

# The delivery record. It lives in the DESTINATION item directory and is never
# source material, so it can never appear in the manifest above.
RECORD_NAME=".delivered.sha256"

CHECK_ONLY=0
VERIFY_ONLY=0
ADOPT_ONLY=0
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
    --verify)
      VERIFY_ONLY=1
      shift
      ;;
    --adopt)
      ADOPT_ONLY=1
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

# The three non-delivering modes ask three different questions and two of them
# write. Refusing the combination is cheaper than deciding which one wins.
if [ $((CHECK_ONLY + VERIFY_ONLY + ADOPT_ONLY)) -gt 1 ]; then
  echo "$0: --check, --verify and --adopt ask different questions, so pick one." >&2
  usage
  exit 1
fi

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

# deliver_rel, deliver_item and deliver_within are PARALLEL arrays, indexed
# together. The record is keyed on the path relative to the item directory, so
# that it stays valid if the whole practice tree moves, and splitting the
# relative path here is cheaper and less fragile than taking it apart again
# with a pattern at every use site.
deliver_rel=()
deliver_item=()
deliver_within=()
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
    deliver_item+=("$rel")
    deliver_within+=("$PROMPT_NAME")
    deliver_rel+=("$rel/$EXPECT_NAME")
    deliver_item+=("$rel")
    deliver_within+=("$EXPECT_NAME")
    while IFS= read -r -d '' src_file; do
      deliver_rel+=("$rel/${src_file#"$item/"}")
      deliver_item+=("$rel")
      deliver_within+=("${src_file#"$item/"}")
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

# ---------------------------------------------------------------------------
# The delivery record, and the one classifier every mode reads.
#
# digest_of <path>: the sha256 of a file, or a non-zero return and no output.
#
# recorded_digest <item-rel> <within>: the digest the record holds for that
# file, or a non-zero return. The comparison is on the WHOLE field after the
# two-space separator rather than on a substring, so an entry for
# work/Good.tla cannot answer a question about Good.tla. A later entry wins,
# which is what lets record_digest append instead of rewriting in place.
#
# classify sets CLASS and CLASS_SRC_D. Every mode below reads the same
# function, so --verify cannot report a state that a delivery would then treat
# differently; that agreement is the reason it is a function rather than three
# copies of an if-chain.
# ---------------------------------------------------------------------------

digest_of() {
  [ -f "$1" ] || return 1
  sha256sum -- "$1" | cut -d' ' -f1
}

recorded_digest() {
  local record="$DEST_ROOT/$1/$RECORD_NAME" within="$2" line found=''
  [ -f "$record" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    [ "${line#*  }" = "$within" ] || continue
    found="${line%%  *}"
  done <"$record"
  [ -n "$found" ] || return 1
  printf '%s' "$found"
}

record_digest() {
  local dir="$DEST_ROOT/$1"
  mkdir -p -- "$dir" || return 1
  printf '%s  %s\n' "$3" "$2" >>"$dir/$RECORD_NAME"
}

CLASS=""
CLASS_SRC_D=""

# classify <src> <dest> <item-rel> <within>
classify() {
  local src="$1" dest="$2" item="$3" within="$4" dest_d rec_d
  CLASS_SRC_D=$(digest_of "$src") || CLASS_SRC_D=""
  if [ ! -e "$dest" ]; then
    CLASS="absent"
    return
  fi
  dest_d=$(digest_of "$dest") || dest_d=""
  # Equal content first, and deliberately before the record is consulted. A
  # file that already carries the source's bytes needs no decision about who
  # wrote it, and reporting it would be noise on every run.
  if [ -n "$CLASS_SRC_D" ] && [ "$CLASS_SRC_D" = "$dest_d" ]; then
    CLASS="insync"
    return
  fi
  rec_d=$(recorded_digest "$item" "$within") || rec_d=""
  if [ -n "$rec_d" ] && [ "$rec_d" = "$dest_d" ]; then
    CLASS="stale"
    return
  fi
  if [ -n "$rec_d" ]; then
    CLASS="conflict_recorded"
  else
    CLASS="conflict_unrecorded"
  fi
}

# ---------------------------------------------------------------------------
# --verify. Writes nothing, including no record.
#
# An item the destination does not hold AT ALL is one line rather than one per
# file. The ramp hands items over one at a time, so most of the corpus is
# undelivered on any real tree at any moment, and a line per withheld file
# would bury the one finding somebody has to act on.
# ---------------------------------------------------------------------------

if [ "$VERIFY_ONLY" -eq 1 ]; then
  if [ ! -d "$DEST_ROOT" ]; then
    echo "no delivered tree at $DEST_ROOT, so there is nothing to compare. Skipping."
    exit 0
  fi

  v_sync=0
  v_stale=0
  v_conflict=0
  v_absent=0
  v_items_absent=0
  seen_item=''
  item_here=0

  for i in "${!deliver_rel[@]}"; do
    rel="${deliver_rel[$i]}"
    item="${deliver_item[$i]}"
    within="${deliver_within[$i]}"

    if [ "$item" != "$seen_item" ]; then
      seen_item="$item"
      if [ -d "$DEST_ROOT/$item" ]; then
        item_here=1
      else
        item_here=0
        v_items_absent=$((v_items_absent + 1))
        echo "not delivered, so there is nothing to compare: $DEST_ROOT/$item"
      fi
    fi

    if [ "$item_here" -eq 0 ]; then
      v_absent=$((v_absent + 1))
      continue
    fi

    classify "$SRC_COMPLETION/$rel" "$DEST_ROOT/$rel" "$item" "$within"
    case "$CLASS" in
      absent)
        v_absent=$((v_absent + 1))
        echo "not delivered, so there is nothing to compare: $DEST_ROOT/$rel"
        ;;
      insync)
        v_sync=$((v_sync + 1))
        ;;
      stale)
        v_stale=$((v_stale + 1))
        echo "STALE, you have not edited it so a delivery would update it: $DEST_ROOT/$rel"
        ;;
      conflict_recorded)
        v_conflict=$((v_conflict + 1))
        echo "CONFLICT, your edit and a moved source: $DEST_ROOT/$rel"
        ;;
      *)
        v_conflict=$((v_conflict + 1))
        echo "CONFLICT, differs from source and has no record, so it may be your work: $DEST_ROOT/$rel"
        ;;
    esac
  done

  echo "$v_sync in sync, $v_stale stale, $v_conflict conflicted, $v_absent not delivered ($v_items_absent whole item(s))"

  if [ "${#incomplete[@]}" -ne 0 ]; then
    exit 1
  fi
  # STALE IS THE FAILURE AND CONFLICTED IS NOT. See the header. A conflict is
  # the learner's own work and no run of this script will ever touch it, so it
  # can never be the thing a gate asks somebody to fix.
  if [ "$v_stale" -gt 0 ]; then
    echo "run $0 $SELECTOR $DEST_ROOT to bring the stale file(s) up to the repo." >&2
    exit 3
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# --adopt. The bootstrap for a tree delivered before records existed. It writes
# the record and copies nothing.
#
# The summary counts what it LEFT, because those files are the learner's and no
# later repair will reach them. That is the number somebody acts on.
# ---------------------------------------------------------------------------

if [ "$ADOPT_ONLY" -eq 1 ]; then
  adopted=0
  left=0
  for i in "${!deliver_rel[@]}"; do
    rel="${deliver_rel[$i]}"
    item="${deliver_item[$i]}"
    within="${deliver_within[$i]}"
    classify "$SRC_COMPLETION/$rel" "$DEST_ROOT/$rel" "$item" "$within"
    if [ "$CLASS" = "absent" ]; then
      echo "not delivered, so nothing to adopt: $DEST_ROOT/$rel"
    elif recorded_digest "$item" "$within" >/dev/null; then
      echo "already recorded: $DEST_ROOT/$rel"
    elif [ "$CLASS" = "insync" ]; then
      record_digest "$item" "$within" "$CLASS_SRC_D" || exit 1
      adopted=$((adopted + 1))
      echo "adopted, byte-identical to its source: $DEST_ROOT/$rel"
    else
      left=$((left + 1))
      echo "not adopted, it differs from its source so it may be your work: $DEST_ROOT/$rel"
    fi
  done
  echo "$adopted file(s) adopted, $left left unrecorded"
  [ "${#incomplete[@]}" -eq 0 ] || exit 1
  exit 0
fi

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
# deliver_file <src> <dest> <item-rel> <within>
#
# The one place the never-overwrite rule lives, copied in shape from
# scripts/deliver-drill.sh. Every file goes through here one at a time, so an
# item whose Claims.tla the learner has already written is left alone without
# holding back a machine added beside it.
#
# THE MESSAGES FOR EVERY CASE THAT EXISTED BEFORE THE RECORD ARE UNCHANGED, on
# purpose. "skipped (exists): <path>" still means what it meant and
# harness/test-deliver-completion.sh pins that string. The record adds one new
# outcome, a file the learner has not touched being brought up to a moved
# source, and one new line on a conflict, which prints AFTER the skip line
# rather than instead of it.
#
# Return codes: 0 landed, 2 skipped, 4 updated, anything else a failure.
# ---------------------------------------------------------------------------

deliver_file() {
  local src="$1" dest="$2" item="$3" within="$4"
  classify "$src" "$dest" "$item" "$within"
  case "$CLASS" in
    absent)
      mkdir -p -- "$(dirname -- "$dest")" || return 1
      cp -- "$src" "$dest" || return 1
      if [ -n "$CLASS_SRC_D" ]; then
        record_digest "$item" "$within" "$CLASS_SRC_D" || return 1
      fi
      return 0
      ;;
    stale)
      # Provably unedited: the bytes on disk are the bytes this script wrote,
      # and the source has moved. This is the one case bead tla-mjvx exists
      # for, and the record is the only thing that makes it safe.
      cp -- "$src" "$dest" || return 1
      record_digest "$item" "$within" "$CLASS_SRC_D" || return 1
      echo "updated, you had not edited it: $dest"
      return 4
      ;;
    insync)
      echo "skipped (exists): $dest"
      return 2
      ;;
    conflict_recorded)
      echo "skipped (exists): $dest"
      echo "  and the source has moved since you edited it, so merge $src by hand" >&2
      return 2
      ;;
    *)
      echo "skipped (exists): $dest"
      echo "  and it differs from $src with no record of delivery, so merge by hand if it is not yours" >&2
      return 2
      ;;
  esac
}

rc=0
landed=0
skipped=0
updated=0

for i in "${!deliver_rel[@]}"; do
  rel="${deliver_rel[$i]}"
  deliver_file "$SRC_COMPLETION/$rel" "$DEST_ROOT/$rel" \
    "${deliver_item[$i]}" "${deliver_within[$i]}"
  case "$?" in
    0) landed=$((landed + 1)) ;;
    2) skipped=$((skipped + 1)) ;;
    4) updated=$((updated + 1)) ;;
    *)
      echo "$0: failed to deliver: $DEST_ROOT/$rel" >&2
      rc=1
      ;;
  esac
done

# The new count goes on the END of the line rather than beside the other two,
# so that every reader and every assertion pinned to the three-field form keeps
# matching. "updated" is a different claim from "landed" and must not be folded
# into it: one of them wrote over bytes that were already there.
echo "$landed file(s) landed, $skipped skipped, ${#withheld_paths[@]} path(s) withheld, $updated updated"

[ "${#incomplete[@]}" -eq 0 ] || rc=1

exit "$rc"
