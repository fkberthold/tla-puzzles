#!/usr/bin/env bash
#
# Usage:  scripts/verify-delivery.sh [practice-root]
#
# Report every delivered artifact under ~/tla-practice that has drifted from
# its source in this repo, across every delivery channel at once. Writes
# nothing anywhere. Exits 3 if any channel reports drift, 1 if a channel
# errors, 0 otherwise.
#
# WHY THIS EXISTS AS ONE COMMAND. Bead tla-mjvx: the repo carried drill
# --style for several hours and Frank's copy did not, because three waves
# merged without anybody re-delivering. ~/tla-practice is not a git repo and
# no repo-level search reaches it, so the gate cannot see this by
# construction. Frank ruled on 2026-10-18 that the check belongs in the
# wrap-up ritual rather than in cibuild, for the reason the bead gives:
# cibuild runs where no delivered tree exists, so the check would skip there
# every time and buy nothing.
#
# A ritual step has to be one command. Doing it by hand means remembering that
# deliver-recall.sh spells it --verify, that deliver-exercises.sh spells it
# --check and needs a chapter argument, that completion and problems take a
# selector, and that drill takes two calls over two roots. That is not a step
# somebody runs correctly at the end of a long session.
#
# IT NAMES WHAT IT DID NOT CHECK, every run, whether or not anything drifted.
# Three channels had no verify mode when this script was written, and a wrapper
# reporting "all clean" while silently skipping them would have been the exact
# failure tla-mjvx is about, wearing the uniform of its own fix. All five carry
# one now, so the line says that instead, which is a stronger claim about the
# same reach. CLAUDE.md states the rule both forms obey: a claim of absence or
# completeness names its search.
#
# THE TABLE BELOW IS A TRIPWIRE, not a convenience. A delivery channel that
# is not in it fails this script rather than being quietly left out, so a new
# scripts/deliver-*.sh cannot ship outside the ritual's reach.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [practice-root]

  practice-root  the delivered tree to compare (default: \$HOME/tla-practice)

Exits 3 if any channel reports drift, 1 on a channel error or an unknown
delivery script, 0 when everything that can be checked is in sync.
USAGE
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*) echo "$0: unknown option: $1" >&2; usage; exit 1 ;;
esac

PRACTICE_ROOT="${1:-$HOME/tla-practice}"

# Every delivery channel this repo has, and how to verify it.
#
# recall      --verify, landed in tla-mjvx at 693ee8f. Every manifest entry is
#             repo-owned and the delivery overwrites all of them, so there any
#             difference is drift and nothing else.
# exercises   --check per chapter, landed in tla-oa0m at 86faa11. --verify is
#             an accepted alias for the same mode.
# completion  --verify over the `all` selector, landed in tla-mjvx.
# problems    --verify over the reserved name `all`, landed in tla-mjvx.
# drill       --verify, landed in tla-mjvx and the last of the five. It is the
#             only channel with two file classes: the runner, the readme and
#             the construct sheet are the repo's and any difference there is
#             DRIFT, while every PROMPT.md and COLD-LIST.md is the learner's
#             page and is judged against a recorded digest, so a difference is
#             STALE only when the delivery can prove it wrote those bytes. It
#             is also read TWICE here, because its study configuration lives
#             under a root no argument of this script reaches.
#
# THE NEVER-OVERWRITE CHANNELS ALL EXIT 3 ON STALE ONLY. A conflict is the
# learner's own work and no delivery will ever touch it, so it is counted and
# reported and never failed on. Wiring a gate to an exit code that merged the
# two put a permanent red on 10 of 12 exercise chapters on 2026-10-18, every
# one of them red because Frank had done the exercises.
KNOWN_CHANNELS='recall
exercises
drill
completion
problems'

# Empty since 2026-10-18, when drill gained --verify. The report below says so
# in words rather than printing a heading over nothing: a block announcing
# unchecked channels with none listed under it reads as truncated output, which
# is the opposite of what naming the gap is for.
NO_VERIFY_YET=''

CLEAN_LIST=''
DRIFT_LIST=''
ERROR_LIST=''
DRIFT_DETAIL=''
RC=0

note_clean()  { CLEAN_LIST="${CLEAN_LIST}  $1
"; }
note_drift()  { DRIFT_LIST="${DRIFT_LIST}  $1
"; RC=3; }
note_error()  { ERROR_LIST="${ERROR_LIST}  $1: $2
"; [ "$RC" -lt 1 ] && RC=1; }

# A delivery script that is not in the table is a channel nobody is checking.
# Fail rather than ignore it: that is the whole point of the table.
for path in "$REPO_ROOT"/scripts/deliver-*.sh; do
  [ -e "$path" ] || continue
  base=${path##*/deliver-}
  base=${base%.sh}
  if ! grep -qx -- "$base" <<<"$KNOWN_CHANNELS"; then
    echo "$0: scripts/deliver-$base.sh is a delivery channel this script does not know about." >&2
    echo "$0: add it to KNOWN_CHANNELS, with a verify call or a recorded reason it has none." >&2
    exit 1
  fi
done

echo "comparing $PRACTICE_ROOT against $REPO_ROOT"

if [ ! -d "$PRACTICE_ROOT" ]; then
  echo "no delivered tree at $PRACTICE_ROOT, so there is nothing to compare. Skipping."
  exit 0
fi

# --- the two channel shapes -------------------------------------------------
#
# verify_overwriting is for a channel whose every delivered file is repo-owned,
# so a difference is drift and there is no third state to count.
#
# verify_never_overwrite is for a channel that protects the learner's work, so
# its report has a conflict column that is never a failure.
#
# BOTH DETAIL BLOCKS READ STALE AND DRIFT. The drill channel prints both words
# in one run, because it has both file classes, so a block grepping for one of
# them would come back empty on a real finding in the other.

verify_overwriting() {
  local channel="$1" out rc
  shift
  out=$("$@" 2>&1); rc=$?
  case "$rc" in
    0) note_clean "$channel" ;;
    3) note_drift "$channel"
       DRIFT_DETAIL="${DRIFT_DETAIL}
--- $channel
$(grep -E '^[[:space:]]*(STALE|DRIFT)' <<<"$out")
" ;;
    *) note_error "$channel" "exit $rc" ;;
  esac
}

verify_never_overwrite() {
  local channel="$1" out rc n
  shift
  out=$("$@" 2>&1); rc=$?
  n=$(grep -cE '^[[:space:]]*CONFLICT' <<<"$out")
  case "$rc" in
    0) note_clean "$channel ($n file(s) are your own work and were left alone)" ;;
    3) note_drift "$channel"
       DRIFT_DETAIL="${DRIFT_DETAIL}
--- $channel
$(grep -E '^[[:space:]]*(STALE|DRIFT)' <<<"$out")
" ;;
    *) note_error "$channel" "exit $rc" ;;
  esac
}

# --- recall ----------------------------------------------------------------

verify_overwriting "recall" \
  "$REPO_ROOT/scripts/deliver-recall.sh" --verify "$PRACTICE_ROOT/recall"

# --- exercises, one call per chapter ---------------------------------------
#
# The chapter list comes off the source tree rather than a literal range,
# because scripts/deliver-exercises.sh hardcodes an upper bound of 13 and bead
# tla-wzj1 is open about it. Reading the tree means this script does not
# acquire the same bug.

ex_stale=0
ex_conflict=0
ex_err=''
for chdir in "$REPO_ROOT"/exercises/ch*/; do
  [ -d "$chdir" ] || continue
  ch=${chdir%/}
  ch=${ch##*/ch}
  ch=$((10#$ch))
  out=$("$REPO_ROOT/scripts/deliver-exercises.sh" --check "$ch" "$PRACTICE_ROOT/exercises" 2>&1); rc=$?
  case "$rc" in
    0) : ;;
    3) ex_stale=1
       DRIFT_DETAIL="${DRIFT_DETAIL}
--- exercises ch$ch
$(grep -E '^[[:space:]]*STALE' <<<"$out")
" ;;
    *) ex_err="exit $rc on chapter $ch" ;;
  esac
  n=$(grep -cE '^[[:space:]]*CONFLICT' <<<"$out")
  ex_conflict=$((ex_conflict + n))
done

if [ -n "$ex_err" ]; then
  note_error "exercises" "$ex_err"
elif [ "$ex_stale" -eq 1 ]; then
  note_drift "exercises"
else
  note_clean "exercises ($ex_conflict file(s) are your own work and were left alone)"
fi

# --- completion and problems, one whole-channel call each -------------------
#
# The argument shapes differ and that is why this is two blocks rather than a
# loop. deliver-completion.sh takes <item|family|all> and `all` was already its
# whole-corpus selector. deliver-problems.sh takes <name>, and `all` is a name
# it reserves for --verify and --adopt, because a delivery there is one problem
# at a time and the two questions should not share one argument.
#
# Both print the same STALE and CONFLICT lines as exercises, so the detail and
# the conflict count are read the same way.

verify_never_overwrite "completion" \
  "$REPO_ROOT/scripts/deliver-completion.sh" --verify all "$PRACTICE_ROOT/completion"

verify_never_overwrite "problems" \
  "$REPO_ROOT/scripts/deliver-problems.sh" --verify all "$PRACTICE_ROOT/problems"

# --- drill, which takes two calls over two roots ----------------------------
#
# The prompt tree sits at <practice-root>/drill like every other channel, and
# it goes through the never-overwrite helper because its prompts and its cold
# list are the learner's page. The conflict count it reports is his own
# annotations, and it is never a failure.
#
# THE STUDY ROOT IS THE ONE PATH NO ARGUMENT OF THIS SCRIPT SELECTS.
# drill/drill.sh creates it where he practices, which is $HOME/Study/tla-drills
# by default and DRILL_STUDY_ROOT when that is set, so this row resolves it the
# same way scripts/deliver-drill.sh does and PRINTS the root it read. A
# comparison against a path the reader cannot derive from the command line is a
# comparison nobody can check.
#
# It is also where `./drill --style` lives, which is the command that failed on
# 2026-10-15 and the reason this bead exists. A drill check that read only the
# prompt tree would have missed it.
#
# Every file under that root is always overwritten, so it takes the other
# helper. An absent study root is a skip inside the script, not a failure: no
# root means no drill has ever been served on this box.

verify_never_overwrite "drill" \
  "$REPO_ROOT/scripts/deliver-drill.sh" --verify "$PRACTICE_ROOT/drill"

DRILL_STUDY="${DRILL_STUDY_ROOT:-$HOME/Study/tla-drills}"
echo "drill study root: $DRILL_STUDY"
verify_overwriting "drill study" \
  "$REPO_ROOT/scripts/deliver-drill.sh" --study --verify "$DRILL_STUDY"

# --- the report ------------------------------------------------------------

echo
if [ -n "$CLEAN_LIST" ]; then
  echo "in sync:"
  printf '%s' "$CLEAN_LIST"
fi

if [ -n "$DRIFT_LIST" ]; then
  echo
  echo "DRIFTED, a delivery is owed:"
  printf '%s' "$DRIFT_LIST"
  printf '%s\n' "$DRIFT_DETAIL"
fi

if [ -n "$ERROR_LIST" ]; then
  echo
  echo "ERRORED, so these channels were not compared:"
  printf '%s' "$ERROR_LIST"
fi

# Always, whatever happened above. A run that printed only "in sync" would be
# claiming more than it checked.
#
# Since 2026-10-18 the list is empty, and the empty case gets a sentence rather
# than a heading with nothing under it. The claim it makes is the stronger one
# and it is still a claim about this script's own reach: every
# scripts/deliver-*.sh has a --verify mode and every one was called above. The
# loop at the top of this file is what keeps that true, by refusing to run at
# all when a delivery script appears that this table does not name.
echo
if [ -n "$NO_VERIFY_YET" ]; then
  echo "NOT CHECKED, because these channels have no verify mode yet (bead tla-mjvx):"
  while read -r ch; do
    [ -n "$ch" ] || continue
    echo "  $ch"
  done <<<"$NO_VERIFY_YET"
else
  echo "NOT CHECKED: no channel is left out. Every scripts/deliver-*.sh carries a verify mode and every one was called above."
fi

if [ "$RC" -eq 3 ]; then
  echo
  echo "Back up ~/tla-practice first, then run the delivery for each channel named above."
  echo "Never fix this by editing the source to match the delivered copy."
fi

exit "$RC"
