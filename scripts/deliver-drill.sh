#!/usr/bin/env bash
# deliver-drill.sh: deliver the blank-page drill prompts into a practice tree,
# without handing over the worked answer, the construct list, or the modules
# that prove the answer checks.
#
# Usage:  scripts/deliver-drill.sh [--check] [--refresh-prompts] [dest-root]
#
#   --check            resolve everything and print what would be delivered.
#                      Writes nothing.
#   --refresh-prompts  replace a delivered PROMPT.md whose content differs from
#                      the source. OFF BY DEFAULT. A run without it reaches no
#                      code that can overwrite a prompt, so a plain delivery
#                      cannot replace one. Read "WHY --refresh-prompts EXISTS"
#                      below before you reach for it.
#   dest-root          where to deliver into (default: $HOME/tla-practice/drill)
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
# NEVER OVERWRITE A PROMPT, AND NEVER DELETE ANYTHING
#
# ~/tla-practice is not a git repo and it holds the only copy of the work done
# in it, so a clobbered file does not come back. Every prompt this script
# places is checked for existence first. An existing one is left alone and
# reported on stdout as "skipped (exists): <path>", and the run still exits 0,
# because a second delivery over a tree already carrying the corpus is the
# normal case rather than an error.
#
# THE RULE IS PER FILE CLASS NOW, AND THE RUNNER IS THE EXCEPTION. Read the
# next section before you read this one as universal.
#
# A PROMPT CAN BE REPLACED, BUT ONLY WHEN THE RUN ASKS FOR IT BY NAME.
# --refresh-prompts is the one route, it is off by default, and the section
# after next is the whole argument for it.
#
# Nothing is removed, at any point, under any flag. This script has no delete
# path at all.
#
# ---------------------------------------------------------------------------
# THREE FILE CLASSES, THREE POLICIES
#
# Until 2026-10-14 this script placed PROMPT.md and nothing else, so one rule
# covered everything it wrote: never overwrite. The drill runner is the first
# non-item file it delivers, and one rule stopped fitting the moment there
# were two kinds of file. Frank ruled the split the same day, which is what
# bead tla-emzu was blocked on.
#
#   PROMPT.md      NEVER overwritten unless the run asks for it with
#                  --refresh-prompts. It is the learner's page. He works in
#                  the directory it sits in, and by the time a second delivery
#                  runs a prompt may carry his notes.
#
#   the runner     ALWAYS overwritten. It is tooling. The repo is the source
#                  of truth for it, nothing he does edits it, and a fix to it
#                  is worth nothing if it cannot reach him. A delivered copy
#                  that can never be refreshed is the stale-copy problem
#                  tla-emzu's own notes describe from the other end.
#
#   PROGRESS.tsv   NEVER written, read or touched here, under any flag. They
#   LAST-SERVED    are his record of what he has done, the runner owns them,
#                  and nothing in this script has any business near them. The
#                  practice tree holds the only copy.
#
# WHAT DECIDES WHICH CLASS A FILE IS IN: could the learner have edited it. If
# he could, refuse to overwrite. If the repo is the source of truth and he
# never edits it, refresh it. The never-overwrite rule exists to protect work
# that has no git behind it, and the runner carries none.
#
# SO AN ALWAYS-OVERWRITE PATH LIVES IN THIS SCRIPT NOW, and it is named rather
# than hidden. install_runner() below is the only place it is, deliver_file()
# still refuses, and they are separate functions so neither can be reached by
# accident. Anyone who reads deliver_file() and concludes that this script
# never overwrites would be right about that function and wrong about the
# script, which is why this section sits above both.
#
# A source tree with no drill.sh is NOT an error. The prompts still land and
# the run reports that no runner was found. A corpus that predates the runner
# is a tree that was fine yesterday, not a defect today.
#
# ---------------------------------------------------------------------------
# WHY --refresh-prompts EXISTS, AND WHY IT IS A FLAG
#
# Never-overwrite kept the practice tree safe, it also kept it stale, and until
# 2026-10-14 nobody had measured by how much. Against the repo that day: 15 of
# 64 delivered prompts differed, 49 were byte for byte.
#
# Most of the 15 were a spelling normalization. Two were content fixes, and
# they are why the flag exists:
#
#   sequences/07-pneumatic-tube          the delivered copy still carried a
#                                        sentence that gave away the item's
#                                        whole lesson, cut that morning and
#                                        replaced by a published state count.
#   modules/07-the-hoist-and-the-crates  the delivered copy still defined
#                                        RECURSIVE in question 1, with only
#                                        the keyword removed.
#
# So the tree served the telegraphed version of two drills whose telegraphs had
# been cut, and under never-overwrite it always would. A drill that tells you
# its own answer is not a blank page.
#
# WHY IT IS A FLAG RATHER THAN THE NEW DEFAULT. The never-overwrite rule is
# there to protect work that has no git behind it, and a prompt is the one
# delivered file he can annotate. The asymmetry the manifest section argues
# about leaks applies here in the same direction: a stale prompt costs one more
# run once somebody says so, and an annotation written over does not come back.
# So the default stays never-overwrite, and a refresh has to be asked for by
# name on the command line. I would not have taken this as a change in the
# default even with the 15 in hand.
#
# IT REPLACES ONLY A FILE THAT DIFFERS, which cmp -s decides. A file that is
# byte for byte is not opened at all, so its mtime does not move either. That
# is about the report rather than about the copying: a run that replaces 15 of
# 64 should say 15, and a run that rewrote all 64 to the same bytes would say
# nothing worth reading.
#
# WHAT THE FLAG DOES NOT CHANGE. ANSWER.md, META.md and verify/ are withheld
# under it exactly as they are without it. PROGRESS.tsv and LAST-SERVED are
# still never written. There is still no delete path. --check composes with it
# and reports what it would replace without writing anything.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check] [--refresh-prompts] [dest-root]

  --check            print what would be delivered, and write nothing
  --refresh-prompts  replace a delivered PROMPT.md that differs from the
                     source. Off by default, and nothing else is overwritten.
  dest-root          where to deliver into (default: \$HOME/tla-practice/drill)

Env:
  DELIVER_DRILL_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
USAGE
}

SRC_ROOT="${DELIVER_DRILL_SRC_ROOT:-$REPO_ROOT}"

# The one file an item hands over. Read the manifest section above before
# changing this, and change harness/test-drill.sh in the same commit.
PROMPT_NAME="PROMPT.md"

# The runner, which is the one thing this script delivers that is not an item.
# It lands without its extension so the command reads `./drill`, and it is
# ALWAYS overwritten. Read "THREE FILE CLASSES, THREE POLICIES" above before
# changing either name.
RUNNER_SRC_NAME="drill.sh"
RUNNER_DEST_NAME="drill"

# The learner's record. Named so the run can say what it leaves alone, and
# never opened.
LEARNER_RECORD_NAMES=("PROGRESS.tsv" "LAST-SERVED")

CHECK_ONLY=0
REFRESH_PROMPTS=0
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
    --refresh-prompts)
      REFRESH_PROMPTS=1
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

# ---------------------------------------------------------------------------
# The runner, resolved beside the items and reported either way.
#
# It sits at the drill root rather than inside an item, so none of the item
# walking above sees it and it is not a withheld path. harness/drill-gate.sh
# and harness/test-drill.sh both read items at depth two, so a file here is
# outside the four-entry shape assertion as well.
# ---------------------------------------------------------------------------

RUNNER_SRC="$SRC_DRILL/$RUNNER_SRC_NAME"
RUNNER_DEST="$DEST_ROOT/$RUNNER_DEST_NAME"

HAVE_RUNNER=0
if [ -f "$RUNNER_SRC" ]; then
  HAVE_RUNNER=1
  echo "runner source: $RUNNER_SRC"
else
  echo "no runner at $RUNNER_SRC, so none lands"
fi

for record_name in "${LEARNER_RECORD_NAMES[@]}"; do
  echo "left alone (the learner's record, never written here): $DEST_ROOT/$record_name"
done

if [ "$CHECK_ONLY" -eq 1 ]; then
  to_land=0
  to_replace=0
  already=0
  # Under --refresh-prompts this reads the destination's prompts to compare
  # them. Reading is all it does: every arm below prints and counts, and the
  # only two writing calls in this script sit past the exit at the bottom of
  # this block.
  for rel in "${deliver_items[@]}"; do
    dest_prompt="$DEST_ROOT/$rel/$PROMPT_NAME"
    if [ ! -e "$dest_prompt" ]; then
      echo "would deliver: $dest_prompt"
      to_land=$((to_land + 1))
    elif [ "$REFRESH_PROMPTS" -eq 0 ]; then
      echo "would skip (exists): $dest_prompt"
      already=$((already + 1))
    elif [ ! -f "$dest_prompt" ]; then
      echo "would leave alone (exists and is not a regular file): $dest_prompt"
      already=$((already + 1))
    elif cmp -s -- "$SRC_DRILL/$rel/$PROMPT_NAME" "$dest_prompt"; then
      echo "would leave alone (identical to the source): $dest_prompt"
      already=$((already + 1))
    else
      echo "would replace (the source differs): $dest_prompt"
      to_replace=$((to_replace + 1))
    fi
  done
  # Says whether it would overwrite, because that is the one thing about the
  # runner a reader cannot infer from the prompt policy above it.
  if [ "$HAVE_RUNNER" -eq 1 ]; then
    if [ -e "$RUNNER_DEST" ]; then
      echo "would deliver runner, OVERWRITING the copy already there: $RUNNER_DEST"
    else
      echo "would deliver runner: $RUNNER_DEST"
    fi
  fi
  # Two counts lines, because the refresh has a third outcome and a plain run
  # does not. A plain run that printed "0 replaced" would read as a run that
  # considered replacing something, which is the one thing it cannot do.
  if [ "$REFRESH_PROMPTS" -eq 1 ]; then
    echo "$to_land prompt(s) to land, $to_replace to replace, $already left alone, ${#withheld_paths[@]} path(s) withheld"
  else
    echo "$to_land prompt(s) to land, $already already there, ${#withheld_paths[@]} path(s) withheld"
  fi
  [ "${#missing_prompt[@]}" -eq 0 ] || exit 1
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# deliver_file <src> <dest>
#
# The default path, and the one place the never-overwrite rule lives. Every
# file goes through here one at a time, so an item the learner has already
# started is left alone without holding back the items beside it.
#
# Returns 0 for a file that landed and 2 for one left alone. The caller counts
# off those two codes, so a third outcome needs a third code rather than a
# flag on either function.
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

# refresh_prompt <src> <dest>
#
# What --refresh-prompts runs instead of deliver_file(), and the second of the
# two overwriting paths in this script. Read "WHY --refresh-prompts EXISTS"
# above for why it is a flag.
#
# It is a separate function for the same reason install_runner() is: a flag on
# the function holding the never-overwrite rule is one typo away from
# clobbering a prompt on an ordinary run, and two functions cannot be confused
# that way. deliver_file() above still refuses, unconditionally, and nothing
# below reaches it.
#
# Returns 0 for a file that landed, 2 for one left alone, 3 for one replaced.
#
# The cmp -s is what makes the report worth reading, and it is also the reason
# an untouched file's mtime does not move. A destination entry that exists and
# is not a regular file is left alone rather than copied onto: cp onto a
# directory writes inside it, which would put a prompt somewhere nobody asked
# for and report success.
refresh_prompt() {
  local src="$1" dest="$2"
  if [ ! -e "$dest" ]; then
    mkdir -p -- "$(dirname -- "$dest")" || return 1
    cp -- "$src" "$dest" || return 1
    return 0
  fi
  if [ ! -f "$dest" ]; then
    echo "left alone (exists and is not a regular file): $dest"
    return 2
  fi
  if cmp -s -- "$src" "$dest"; then
    echo "left alone (identical to the source): $dest"
    return 2
  fi
  cp -- "$src" "$dest" || return 1
  echo "replaced (the source differs): $dest"
  return 3
}

# install_runner <src> <dest>
#
# The one always-overwrite path in this script, and the only one there will
# ever be unless somebody argues another file class into the section above.
# It is deliberately NOT deliver_file() with a flag: a flag on the function
# that holds the never-overwrite rule is one typo away from clobbering a
# prompt, and two functions cannot be confused that way.
#
# It says which of the two things it did, because a refresh and a first
# delivery are different events and he should be able to tell them apart in
# the output.
install_runner() {
  local src="$1" dest="$2" existed=0
  if [ -e "$dest" ]; then
    existed=1
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
  chmod 0755 -- "$dest" || return 1
  if [ "$existed" -eq 1 ]; then
    echo "runner refreshed, overwriting the copy already there: $dest"
  else
    echo "runner delivered: $dest"
  fi
}

rc=0
landed=0
skipped=0
replaced=0

# The outcome is captured into a variable rather than read off $? after the
# fi, so which function ran and what it returned are two separate things a
# reader can see.
for rel in "${deliver_items[@]}"; do
  if [ "$REFRESH_PROMPTS" -eq 1 ]; then
    refresh_prompt "$SRC_DRILL/$rel/$PROMPT_NAME" "$DEST_ROOT/$rel/$PROMPT_NAME"
    outcome=$?
  else
    deliver_file "$SRC_DRILL/$rel/$PROMPT_NAME" "$DEST_ROOT/$rel/$PROMPT_NAME"
    outcome=$?
  fi
  case "$outcome" in
    0) landed=$((landed + 1)) ;;
    2) skipped=$((skipped + 1)) ;;
    3) replaced=$((replaced + 1)) ;;
    *)
      echo "$0: failed to deliver: $DEST_ROOT/$rel/$PROMPT_NAME" >&2
      rc=1
      ;;
  esac
done

if [ "$HAVE_RUNNER" -eq 1 ]; then
  if ! install_runner "$RUNNER_SRC" "$RUNNER_DEST"; then
    echo "$0: failed to deliver the runner: $RUNNER_DEST" >&2
    rc=1
  fi
fi

if [ "$REFRESH_PROMPTS" -eq 1 ]; then
  echo "$landed prompt(s) landed, $replaced replaced, $skipped left alone, ${#withheld_paths[@]} path(s) withheld"
else
  echo "$landed prompt(s) landed, $skipped skipped, ${#withheld_paths[@]} path(s) withheld"
fi

[ "${#missing_prompt[@]}" -eq 0 ] || rc=1

exit "$rc"
