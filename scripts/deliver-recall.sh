#!/usr/bin/env bash
# deliver-recall.sh: deliver the recall channel into a practice tree: the
# runner, the rep table, the miss table, the environments and the README.
#
# Usage:  scripts/deliver-recall.sh [--check] [dest-root]
#
#   --check    resolve everything and print what would be delivered, and what
#              it would overwrite. Writes nothing. --dry-run is an accepted
#              alias, for the reason scripts/deliver-completion.sh gives.
#   dest-root  where to deliver into (default: $HOME/tla-practice/recall)
#
# Env:    DELIVER_RECALL_SRC_ROOT   override the source repo root (default:
#                                   the repo this script lives in)
#
# Exit:   0 on success
#         1 on a usage error, a source tree missing a manifest part, or a
#           failed copy
#
# ---------------------------------------------------------------------------
# THIS SCRIPT OVERWRITES EVERY FILE IT DELIVERS, AND NO SIBLING DOES
#
# Read this before anything else here. scripts/deliver-drill.sh,
# scripts/deliver-problems.sh and scripts/deliver-completion.sh all hold a
# never-overwrite rule, because each of them delivers a file the learner then
# WRITES INTO: a drill prompt he answers beneath, a problem statement, a
# completion item's work/Claims.tla. After the first sitting the delivered
# copy and his work are the same file, there is no second copy of it anywhere,
# and ~/tla-practice is not a git repo.
#
# THE RECALL CHANNEL HAS NO SUCH FILE. A rep is answered on the command line
# and graded on an exit code. recall/recall.sh writes nothing into its own
# directory at all: every write it makes is under a `mktemp -d` scratch in
# $TMPDIR that an EXIT trap removes (recall/recall.sh, SCRATCH and
# drop_scratch). There is no PROGRESS.tsv, no LAST-SERVED, and nothing the
# learner edits. So all five manifest entries are in the class
# scripts/deliver-drill.sh calls the runner's: repo-owned, always refreshed,
# because the repo is the source of truth for them and he never edits them.
#
# THAT IS A LOAD-BEARING CLAIM AND IT IS MEASURED RATHER THAN ASSERTED.
# harness/test-recall-gate.sh part 6 snapshots a recall tree, grades a wrong
# answer through the runner in it, and snapshots it again, so the day a rep
# starts recording progress, the claim above turns red instead of quietly
# becoming false and taking a learner's work with it. It is a separate claim
# from harness/test-recall-runner.sh part 5's, which snapshots the CALLER'S
# working directory. This one is about the runner's own tree.
#
# NOTHING IS REMOVED, at any point, under any flag. This script has no delete
# path at all, and harness/test-recall-gate.sh part 6 asserts it by scanning
# this file for a delete in command position, because the 2026-10-02 incident
# in the problems corpus was a deletion rather than a leak and a guessed
# manifest took 39 delivered files with it.
#
# ---------------------------------------------------------------------------
# NOTHING IS WITHHELD, AND THAT IS A PROPERTY OF THE CHANNEL
#
# Every sibling delivery script holds something back: ANSWER.md and META.md in
# drill and completion, the construct list in drill. There is nothing to hold
# back here. The canonical answers ARE recall/REPS.tsv field 6, and the runner
# reads that file to grade, so the answer key has to travel for the channel to
# work at all. A learner with the delivered tree can read every answer in it.
#
# That is sound at this rung and it is not an oversight. The grade is value
# equality against an expression the learner has in front of them, so the
# table is only a spoiler for somebody who chooses to open it, and the rung
# costs seconds a rep rather than minutes. It is worth stating plainly,
# because "the delivery withholds nothing" reads as a bug in every other
# script in this directory.
#
# The report still names every root entry that is NOT in the manifest, on
# every run. A corpus that grows a file nobody decided about is then one line
# of output rather than a silence.
#
# ---------------------------------------------------------------------------
# WHAT LANDS
#
# Five things, at <dest-root>/:
#
#   recall.sh     the runner, mode 0755. It resolves its own paths from
#                 ${BASH_SOURCE[0]}, so the delivered copy reads the delivered
#                 tables with no flags.
#   REPS.tsv      the 120 reps: id, construct, environment, prompt, canonical
#   MISSES.tsv    the 30 recorded wrong answers and what each one says
#   README.md     how to work a rep, and what the three layers under a wrong
#                 answer are
#   env/          the constant environments, recursively. Every .tla under it
#                 travels, including one added tomorrow, for the reason
#                 scripts/deliver-completion.sh gives about work/: a name list
#                 cannot be told that the corpus grew, and a tree manifest
#                 cannot miscount.
#
# ---------------------------------------------------------------------------
# ONE THING THE DELIVERED RUNNER REACHES FOR OUTSIDE THIS MANIFEST
#
# There were two until bead tla-1sh7.10, and the first one was a warning
# because without it the delivered tree graded nothing at all.
#
# WHAT IT WAS. recall/recall.sh resolved ${REPO_ROOT}/harness/verdict.sh, where
# REPO_ROOT is the PARENT of the directory the script sits in, and refused to
# start without it at exit 3, "could not run". Delivered to
# $HOME/tla-practice/recall/ it looked for $HOME/tla-practice/harness/
# verdict.sh, which nothing puts there. Measured 2026-10-16 against a delivered
# copy and again 2026-10-17 in a temp tree with no repo above it: the canonical
# answer to R107 came back rc 3. Every rep, every answer.
#
# WHAT WAS DONE ABOUT IT, and it was the third of the three ways out rather
# than the cheapest. The runner is self-contained now, the way
# drill/study/check already was: it runs TLC itself under the flags
# harness/verdict.sh runs it under, and names five exit codes. The slice was
# measured before it was absorbed: four of verdict.sh's ten options, and three
# of its thirteen mapped codes reachable from a scaffold that declares no
# SPECIFICATION and one ASSUME. The runner's own header carries the
# measurement and the gate that keeps the two tables agreeing.
#
# THE OTHER TWO WAYS OUT, and why neither won. Delivering harness/verdict.sh
# would have made this the first script to export repo harness, would have put
# a CENTRALLY OWNED file (.claude/rules/dispatched-agents.md) into a
# learner-facing delivery where every change to it gains a delivery
# consequence, and would have had this script write OUTSIDE its own dest-root
# into <parent>/harness/ -- the same second-destination problem that is the
# stated reason drill/SHEET.md is not delivered from here either. An
# environment override for the verdict path would have left the practice tree
# depending on a repo path, so the channel would work on one machine and only
# while the repo stayed where it was.
#
# AND THE ONE THAT IS LEFT: drill/SHEET.md, WITHOUT WHICH A WRONG ANSWER LOSES
# ONE LAYER OF THREE.
#
# recall/recall.sh resolves it from ${BASH_SOURCE[0]} the same way, so a copy
# delivered to $HOME/tla-practice/recall/ looks under $HOME/tla-practice/ for
# it. This script checks it AT THE PATH THIS DESTINATION RESOLVES TO and says
# so on every run, check runs included. It is not delivered.
#
# The runner looks for $HOME/tla-practice/drill/SHEET.md, which is exactly
# where scripts/deliver-drill.sh puts the drill corpus, so the path lines up
# on its own and no flag is needed. The file is simply not there: measured
# 2026-10-16, $HOME/tla-practice/drill/ holds the eight family directories,
# the runner, README.md, PROGRESS.tsv and LAST-SERVED, and none of SHEET.md,
# INVENTORY.md or COLD-LIST.md.
#
# A MISSING SHEET IS SILENCE, NOT A REFUSAL. recall/recall.sh's show_sheet
# returns without printing when the file is unreadable, so every rep in a
# tree that can grade still grades, and a wrong answer still gets both values
# and its miss row. That is why this one is a note and never was a warning.
#
# ---------------------------------------------------------------------------
# WHAT A DELIVERED TREE NEEDS THAT IS NOT A FILE: tlc ON THE PATH
#
# The runner's only remaining dependency outside its own directory, and the
# one thing that can still stop a delivered tree grading. An absent tlc is
# exit 3 with a message rather than a quiet pass (recall/recall.sh, the
# command -v check), so it cannot be mistaken for a wrong answer, but every
# rep stops.
#
# So this script reports it on every run, check runs included, the way it
# reports the sheet. It is a note rather than a warning for one reason: it is
# a fact about THIS machine at THIS moment, and the delivery is the last
# moment at which that fact is worth less than it looks. A tree delivered
# today on a box with tlc is a tree that stops grading the day the toolchain
# moves, and no delivery-time check can see that coming.
#
# WHY THIS SCRIPT DOES NOT JUST DELIVER IT. The sheet is a drill-root
# reference file, and scripts/deliver-drill.sh owns that directory.
# harness/test-deliver-drill.sh holds the shape, which is not one rule for all
# three: drill/INVENTORY.md is never delivered, and drill/COLD-LIST.md lands
# once and is never overwritten afterward, because the reader's ticks are in
# it. Delivering the sheet from here would put two scripts in charge of one
# destination directory, and deciding it properly means deciding about all
# three. It is filed rather than guessed.
#
# THE BEHAVIOR IS NAMED HERE AND THE LINE NUMBER IS NOT, on purpose. This
# cross-reference carried one and it was wrong twice: stale the day it was
# written, because a bead had already inverted both assertions, and wrong
# again afterward in the other direction, because the cold list now lands.
# A line number in another suite is a fact with a shelf life and nothing
# watches it.
#
# ---------------------------------------------------------------------------
# WHY THERE IS NO SELECTOR
#
# scripts/deliver-completion.sh takes one because a completion item is a
# sitting and handing over the next six turns a sitting into a menu. A recall
# rep is seconds, the runner picks the rep by id at the prompt, and the table
# is one file. There is nothing to select. scripts/deliver-drill.sh takes none
# for the same reason and this follows it.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check | --verify] [dest-root]

  --check    print what would be delivered and what it would overwrite,
             and write nothing (--dry-run is an accepted alias)
  --verify   compare every delivered file against its source, name every
             path that drifted, and exit 3 if any did. Writes nothing.
             An absent destination root is a skip at exit 0.
  dest-root  where to deliver into (default: \$HOME/tla-practice/recall)

Env:
  DELIVER_RECALL_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
USAGE
}

SRC_ROOT="${DELIVER_RECALL_SRC_ROOT:-$REPO_ROOT}"

# The manifest. Read WHAT LANDS above before changing any of these, and change
# harness/test-recall-gate.sh in the same commit.
RUNNER_NAME="recall.sh"
REPS_NAME="REPS.tsv"
MISSES_NAME="MISSES.tsv"
README_NAME="README.md"
ENV_DIR_NAME="env"

CHECK_ONLY=0
VERIFY_ONLY=0
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
    --check|--dry-run) CHECK_ONLY=1; shift ;;
    --verify) VERIFY_ONLY=1; shift ;;
    --) shift; break ;;
    -*)
      echo "$0: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *) take_positional "$1"; shift ;;
  esac
done

# Anything after a bare `--` is still an argument.
while [ "$#" -gt 0 ]; do
  take_positional "$1"
  shift
done

if [ "$CHECK_ONLY" -eq 1 ] && [ "$VERIFY_ONLY" -eq 1 ]; then
  echo "$0: --check and --verify ask different questions, so pick one." >&2
  usage
  exit 1
fi

if [ -z "$DEST_ROOT" ]; then
  DEST_ROOT="$HOME/tla-practice/recall"
fi

SRC_RECALL="$SRC_ROOT/recall"

# ---------------------------------------------------------------------------
# Resolve the source before the destination is touched, so every fatal path
# below leaves the filesystem exactly as it found it.
# ---------------------------------------------------------------------------

if [ ! -d "$SRC_RECALL" ]; then
  echo "$0: no recall channel at $SRC_RECALL" >&2
  echo "$0: set DELIVER_RECALL_SRC_ROOT to the repo root that carries recall/." >&2
  exit 1
fi

# An incomplete source delivers NOTHING, for the reason
# scripts/deliver-completion.sh gives about half an item: the parts are not
# independently useful. A tree with REPS.tsv and no runner is a table nobody
# can submit against. A runner with no env/ dies at rc 3 on every rep.
missing=()
[ -f "$SRC_RECALL/$RUNNER_NAME" ] || missing+=("$RUNNER_NAME")
[ -f "$SRC_RECALL/$REPS_NAME" ]   || missing+=("$REPS_NAME")
[ -f "$SRC_RECALL/$MISSES_NAME" ] || missing+=("$MISSES_NAME")
[ -f "$SRC_RECALL/$README_NAME" ] || missing+=("$README_NAME")
[ -d "$SRC_RECALL/$ENV_DIR_NAME" ] || missing+=("$ENV_DIR_NAME/")

if [ "${#missing[@]}" -ne 0 ]; then
  for part in "${missing[@]}"; do
    echo "$0: $SRC_RECALL carries no $part, so the channel is not deliverable." >&2
  done
  echo "$0: nothing was delivered. The channel needs $RUNNER_NAME, $REPS_NAME, $MISSES_NAME, $README_NAME and $ENV_DIR_NAME/." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Build the manifest: four names plus the env tree.
#
# Paths are relative to the recall root, so the same list drives the report,
# the check mode and the copy. The env sweep is `find -type f` so a
# subdirectory under env/ travels too, and it is sorted with LC_ALL=C so two
# runs over one tree print the same order.
# ---------------------------------------------------------------------------
deliver_rel=("$RUNNER_NAME" "$REPS_NAME" "$MISSES_NAME" "$README_NAME")
while IFS= read -r src_file; do
  [ -n "$src_file" ] || continue
  deliver_rel+=("${src_file#"$SRC_RECALL/"}")
done < <(find "$SRC_RECALL/$ENV_DIR_NAME" -type f | LC_ALL=C sort)

if [ "${#deliver_rel[@]}" -eq 4 ]; then
  echo "$0: $SRC_RECALL/$ENV_DIR_NAME/ holds no file, so every rep would die at rc 3." >&2
  echo "$0: nothing was delivered." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# What is NOT in the manifest, reported either way so it is never silent.
#
# Built from the recall root's own top-level entries, dotfiles included. A
# directory is one line rather than its contents, because what the report is
# about is the decision not to deliver that entry. There are none today. The
# line exists for the file somebody adds tomorrow.
# ---------------------------------------------------------------------------
is_manifest_name() {
  case "$1" in
    "$RUNNER_NAME"|"$REPS_NAME"|"$MISSES_NAME"|"$README_NAME"|"$ENV_DIR_NAME") return 0 ;;
  esac
  return 1
}

withheld_paths=()
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  base="${entry##*/}"
  is_manifest_name "$base" && continue
  withheld_paths+=("$base")
done < <(find "$SRC_RECALL" -mindepth 1 -maxdepth 1 | LC_ALL=C sort)

for rel in "${withheld_paths[@]+"${withheld_paths[@]}"}"; do
  echo "withheld (not in the manifest): $SRC_RECALL/$rel"
done

echo "source: $SRC_RECALL"
echo "destination: $DEST_ROOT"

# ---------------------------------------------------------------------------
# The two things a delivered tree needs that are not in this manifest, both
# reported on every run rather than described in general. Neither is a
# refusal and neither ever was a reason to withhold a delivery: the first
# costs a wrong answer one explanation layer of three, and the second is a
# fact about this machine.
#
# WHAT IS NO LONGER CHECKED HERE, and why its absence is the fix rather than
# an omission: harness/verdict.sh. Until bead tla-1sh7.10 this script printed
# two WARNING lines naming the path a delivered runner would look for it at,
# because without it the tree graded nothing. The runner is self-contained
# now, so there is no such path to name, and a line still naming one would be
# a check that reports a hazard that is not there. See ONE THING THE DELIVERED
# RUNNER REACHES FOR above.
#
# DEST_PARENT is what recall/recall.sh will compute as its REPO_ROOT: the
# parent of the directory the delivered script sits in. Resolved textually
# rather than with `cd`, because the destination may not exist yet on a
# --check run and a `cd` into it would fail for a reason that is not the
# question being asked.
#
# BOTH PRINT UNCONDITIONALLY, which is the gate-don't-advise shape rather than
# a softening of it. What that rule forbids is leaving a check for somebody to
# remember. These run on every invocation, and harness/test-recall-gate.sh
# asserts that both lines are still printed.
#
# ONLY THE SHEET LINE IS ASSERTED TO INVERT, and the asymmetry is worth naming
# rather than leaving as an apparent oversight. The suite can put a SHEET.md
# where the line says there is none and watch the wording flip. It cannot take
# tlc off the path for one invocation without rebuilding PATH from a scratch
# bin, which is harness/test-drill-check.sh's trick and more machinery than
# one line of output is worth here. The runner's own absent-tlc path IS
# measured: it comes back exit 3 with "tlc is not on the path, so nothing was
# graded", which is the half that matters, since this line reports and the
# runner refuses.
# ---------------------------------------------------------------------------
DEST_PARENT="${DEST_ROOT%/}"
DEST_PARENT="${DEST_PARENT%/*}"
[ -n "$DEST_PARENT" ] || DEST_PARENT="/"

DEST_SHEET="$DEST_PARENT/drill/SHEET.md"

if [ -r "$DEST_SHEET" ]; then
  echo "construct sheet: $DEST_SHEET is there, so a wrong answer gets its construct entry."
else
  echo "note: no construct sheet at $DEST_SHEET, so a wrong answer gets both values and its miss row and no construct entry. Reps still grade."
fi

if command -v tlc >/dev/null 2>&1; then
  echo "tlc: $(command -v tlc) is on the path, which is the whole of what the delivered runner needs to grade."
else
  echo "note: tlc is not on the path here, so the delivered runner exits 3 on every rep until it is. It needs nothing else."
fi

# ---------------------------------------------------------------------------
# --verify: has this channel actually been delivered since the repo moved?
#
# --check answers a different question and the two read alike, which is worth
# saying because the difference is the whole bead. --check reports what a
# delivery WOULD do, so it says "66 to overwrite" on a tree that is already
# byte-identical. It cannot tell a stale tree from a current one. --verify
# compares content and reports only what drifted.
#
# WHY THIS IS SOUND HERE AND NEEDS MORE THOUGHT ELSEWHERE. Every entry in this
# manifest is repo-owned and this script overwrites all of them, so a
# difference is drift and nothing else. scripts/deliver-drill.sh has two file
# classes and a learner owns one of them, so a verify there has to read the
# policy before it calls a difference drift. Bead tla-mjvx carries that.
#
# AN ABSENT DESTINATION IS A SKIP, NEVER A FAILURE. No box but Frank's has a
# delivered tree and a CI runner never will, so a gate that failed on absence
# would be red everywhere it does not apply. Exit 0 and say which case it was.
#
# Exit 3 on drift, matching install_file()'s "there was already a copy there
# and it is not this one". Exit 1 stays what it already is here, a failure.
# ---------------------------------------------------------------------------
if [ "$VERIFY_ONLY" -eq 1 ]; then
  if [ ! -d "$DEST_ROOT" ]; then
    echo "no delivered tree at $DEST_ROOT, so there is nothing to compare. Skipping."
    exit 0
  fi

  drifted=()
  in_sync=0
  for rel in "${deliver_rel[@]}"; do
    if [ ! -e "$DEST_ROOT/$rel" ]; then
      echo "DRIFT, never delivered: $DEST_ROOT/$rel"
      drifted+=("$rel")
    elif ! cmp -s -- "$SRC_RECALL/$rel" "$DEST_ROOT/$rel"; then
      echo "DRIFT, differs from $SRC_RECALL/$rel: $DEST_ROOT/$rel"
      drifted+=("$rel")
    else
      in_sync=$((in_sync + 1))
    fi
  done

  # The runner's mode is set explicitly by the delivery for a stated reason, so
  # the verify checks it. A runner delivered 0644 is a channel that reports
  # success and cannot be run, and its content compares equal either way.
  if [ -f "$DEST_ROOT/$RUNNER_NAME" ] && [ ! -x "$DEST_ROOT/$RUNNER_NAME" ]; then
    echo "DRIFT, not executable: $DEST_ROOT/$RUNNER_NAME"
    drifted+=("$RUNNER_NAME mode")
  fi

  echo "$in_sync file(s) in sync, ${#drifted[@]} drifted"
  if [ "${#drifted[@]}" -gt 0 ]; then
    echo "run $0 to bring the delivered tree up to the repo." >&2
    exit 3
  fi
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  to_land=0
  to_replace=0
  for rel in "${deliver_rel[@]}"; do
    if [ -e "$DEST_ROOT/$rel" ]; then
      echo "would deliver, OVERWRITING the copy already there: $DEST_ROOT/$rel"
      to_replace=$((to_replace + 1))
    else
      echo "would deliver: $DEST_ROOT/$rel"
      to_land=$((to_land + 1))
    fi
  done
  echo "$to_land file(s) to land, $to_replace to overwrite, ${#withheld_paths[@]} path(s) withheld"
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# install_file <src> <dest> -> 0 for a new file, 3 for one that replaced a
# copy already there, 1 for a failure. The codes are
# scripts/deliver-drill.sh's install_study_file()'s, and so is the shape: this
# is the always-overwrite path, and it is the ONLY path here because every
# manifest entry is repo-owned. See THIS SCRIPT OVERWRITES EVERY FILE above.
# ---------------------------------------------------------------------------
install_file() {
  local src="$1" dest="$2" existed=0
  if [ -e "$dest" ]; then
    existed=1
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
  if [ "$existed" -eq 1 ]; then
    echo "refreshed, overwriting the copy already there: $dest"
    return 3
  fi
  echo "delivered: $dest"
  return 0
}

rc=0
landed=0
replaced=0

for rel in "${deliver_rel[@]}"; do
  install_file "$SRC_RECALL/$rel" "$DEST_ROOT/$rel"
  case "$?" in
    0) landed=$((landed + 1)) ;;
    3) replaced=$((replaced + 1)) ;;
    *)
      echo "$0: failed to deliver: $DEST_ROOT/$rel" >&2
      rc=1
      ;;
  esac
done

# The runner has to be executable in the delivered tree, and `cp` without -p
# takes the source's mode through the umask. Set it explicitly rather than
# relying on that: a runner delivered 0644 is a channel that reports success
# and cannot be run.
if [ -e "$DEST_ROOT/$RUNNER_NAME" ]; then
  chmod 0755 -- "$DEST_ROOT/$RUNNER_NAME" || rc=1
fi

echo "$landed file(s) landed, $replaced refreshed, ${#withheld_paths[@]} path(s) withheld"

exit "$rc"
