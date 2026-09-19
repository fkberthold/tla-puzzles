#!/usr/bin/env bash
# number-problems.sh: keep problem directory names in step with ORDER.
#
# Usage: scripts/number-problems.sh [--check] [<problems-root>]
#
# ORDER is the one source of truth for the ramp's sequence. A problem
# directory's numeric prefix is derived from its position in ORDER rather
# than maintained separately, so this script is what keeps the two from
# drifting apart.
#
# See .claude/rules/dispatched-agents.md and the bead tla-0lwx contract for
# the full behavioral spec. Summary:
#
#   - <problems-root> defaults to $HOME/tla-practice/problems.
#   - ORDER entries are non-blank, non-comment lines, except the two
#     `checkpoint: ch13` / `checkpoint: refinement` markers, which are
#     skipped and consume no position.
#   - Entry N (1-based) wants a directory named NN_name (zero-padded to 2).
#   - A directory not named by ORDER is fine unless it carries a numeric
#     prefix, which is always an error (a "numbered stranger").
#   - --check reports disagreements and changes nothing.
#   - A bare run renames, but fails closed: if anything is wrong, it
#     renames nothing at all and exits 1.
#   - A directory carrying the temp suffix is the residue of a run that
#     died mid-rename. Both modes name it and exit 1.
#   - A rename that cannot complete stops the run and exits 1. Nothing is
#     rolled back.
#
# Two-phase by design: the whole plan is resolved and validated before any
# rename happens, so a defect discovered late (e.g. the last ORDER entry)
# never leaves earlier entries renamed while it aborts.

set -uo pipefail

CHECK_ONLY=0
PROBLEMS_ROOT=""

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
      echo "number-problems.sh: unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [ -n "$PROBLEMS_ROOT" ]; then
        echo "number-problems.sh: unexpected extra argument: $1" >&2
        exit 2
      fi
      PROBLEMS_ROOT="$1"
      shift
      ;;
  esac
done

if [ "$#" -gt 0 ]; then
  echo "number-problems.sh: unexpected extra argument: $1" >&2
  exit 2
fi

if [ -z "$PROBLEMS_ROOT" ]; then
  PROBLEMS_ROOT="$HOME/tla-practice/problems"
fi

if [ ! -d "$PROBLEMS_ROOT" ]; then
  echo "number-problems.sh: no such directory: $PROBLEMS_ROOT" >&2
  exit 2
fi

ORDER_FILE="$PROBLEMS_ROOT/ORDER"
if [ ! -f "$ORDER_FILE" ]; then
  echo "number-problems.sh: no ORDER file: $ORDER_FILE" >&2
  exit 2
fi

# The name phase 3 parks a directory under between its two rename passes. One
# constant, because the applier and the sweep that finds its residue have to
# agree on it.
TMP_MARKER=".number-problems-tmp."

# matches_entry <dirname> <order-entry>
#
# True when the directory belongs to the entry: either the bare name, or
# <digits>_<name>. The entry is compared as text, never as a pattern.
#
# This used to be [[ $base =~ ^([0-9]+_)?${name}$ ]], which reads the entry as
# an extended regex. An entry carrying a dot then matched any character in that
# position, so ORDER naming two.phase claimed a directory called twoxphase and
# a bare run renamed it. Every name in the ramp is lowercase letters and
# hyphens, so the hole never opened, but what keeps it shut should be the
# matcher rather than the names.
matches_entry() {
  local base="$1" entry="$2" digits rest
  [ "$base" = "$entry" ] && return 0
  digits="${base%%_*}"
  [ "$digits" = "$base" ] && return 1
  [ -z "$digits" ] && return 1
  case "$digits" in
    *[!0-9]*) return 1 ;;
  esac
  rest="${base#*_}"
  [ "$rest" = "$entry" ]
}

# ---------------------------------------------------------------------------
# Phase 1: parse ORDER into an ordered list of problem names.
# ---------------------------------------------------------------------------

names=()
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

# ---------------------------------------------------------------------------
# Phase 2: build the rename plan and validate every entry AND every
# directory on disk before touching anything.
# ---------------------------------------------------------------------------

problems=0
[ "${#names[@]}" -gt 0 ] && problems=1

plan_src=()
plan_dst=()
errors=()

# ---------------------------------------------------------------------------
# Phase 2a: refuse outright on the residue of a run that died mid-rename.
#
# Phase 3 parks each directory under <final><TMP_MARKER><pid> and then moves it
# to <final>, so a run that died between the two passes left the parked name
# behind. Everything downstream reasons about a tree where each problem has one
# directory, and that is not this tree, so the check comes first and stops
# here.
#
# Both modes refuse. --check because the residue is a disagreement with ORDER
# the same way a wrong number is, and a bare run because renaming around a name
# it cannot account for is the half-applied tree the two-phase design exists to
# rule out.
# ---------------------------------------------------------------------------

stranded=()
for d in "$PROBLEMS_ROOT"/*/; do
  [ -d "$d" ] || continue
  base="${d%/}"
  base="${base##*/}"
  case "$base" in
    *"$TMP_MARKER"*) stranded+=("$base") ;;
  esac
done

if [ "${#stranded[@]}" -gt 0 ]; then
  for s in "${stranded[@]}"; do
    echo "number-problems.sh: stranded temp directory: '$s'" >&2
  done
  echo "number-problems.sh: a run died between its two rename passes and left these behind." >&2
  echo "number-problems.sh: move each one to its name without the '$TMP_MARKER<pid>' tail, then run again." >&2
  exit 1
fi

total=${#names[@]}
width=2
[ "$total" -gt 99 ] && width=3

pos=0
for name in "${names[@]}"; do
  pos=$((pos + 1))
  wanted=$(printf "%0${width}d_%s" "$pos" "$name")

  # Find the directory that already belongs to this entry: either its
  # numbered form (any number of digits) or its bare name.
  found=""
  for d in "$PROBLEMS_ROOT"/*/; do
    [ -d "$d" ] || continue
    base="${d%/}"
    base="${base##*/}"
    if matches_entry "$base" "$name"; then
      if [ -n "$found" ]; then
        errors+=("ambiguous: both '$found' and '$base' match ORDER entry '$name'")
      else
        found="$base"
      fi
    fi
  done

  if [ -z "$found" ]; then
    errors+=("no directory found for ORDER entry '$name' (looked for '$name' or a numbered form of it)")
    continue
  fi

  if [ "$found" = "$wanted" ]; then
    continue
  fi

  plan_src+=("$found")
  plan_dst+=("$wanted")
done

# ---------------------------------------------------------------------------
# Phase 2b: sweep the directory for numbered strangers ORDER does not name.
# ---------------------------------------------------------------------------

declare -A named_dirs=()
if [ "$problems" -eq 1 ]; then
  for name in "${names[@]}"; do
    for d in "$PROBLEMS_ROOT"/*/; do
      [ -d "$d" ] || continue
      base="${d%/}"
      base="${base##*/}"
      if matches_entry "$base" "$name"; then
        named_dirs["$base"]=1
      fi
    done
  done
fi

for d in "$PROBLEMS_ROOT"/*/; do
  [ -d "$d" ] || continue
  base="${d%/}"
  base="${base##*/}"
  [ "$base" = "ORDER" ] && continue
  if [[ "$base" =~ ^[0-9]+_ ]]; then
    if [ -z "${named_dirs[$base]:-}" ]; then
      errors+=("numbered stranger not named by ORDER: '$base'")
    fi
  fi
done

# ---------------------------------------------------------------------------
# Report / decide.
# ---------------------------------------------------------------------------

if [ "${#errors[@]}" -gt 0 ]; then
  for e in "${errors[@]}"; do
    echo "number-problems.sh: $e" >&2
  done
  exit 1
fi

if [ "${#plan_src[@]}" -eq 0 ]; then
  # Already in step. Clean under --check and a no-op bare run.
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  for i in "${!plan_src[@]}"; do
    echo "would rename '${plan_src[$i]}' to '${plan_dst[$i]}'"
  done
  exit 1
fi

# ---------------------------------------------------------------------------
# Phase 3: apply the renames. Two-step through a temp suffix so a rename
# whose destination is currently occupied by another entry awaiting its own
# rename (e.g. 05_beta -> 02_beta when nothing else currently holds 02_beta,
# but the reverse ordering could collide in other trees) never clobbers a
# directory that still needs to move.
#
# Every mv is checked. The two loops used to run bare under `set -uo pipefail`
# with no -e, so a rename that failed was skipped and the run went on to exit
# 0, which is the one outcome the fail-closed design was built to rule out.
#
# NOTHING IS ROLLED BACK. That is a decision, not a gap. A rollback is more
# code running at the moment the tree is already wrong, and this tree has no
# git history behind it, so a rollback that goes wrong takes work that does not
# come back. The run says where it stopped, in enough detail to finish the job
# by hand, and stops.
# ---------------------------------------------------------------------------

tmp_suffix="$TMP_MARKER$$"

# fail_mid_rename <from> <to> <parked-through> <landed-through>
#
# Report the failed rename and the state of every planned entry, then exit 1.
# `parked` and `landed` are the counts the two loops had reached, so an entry's
# index says which of the three states it is in.
fail_mid_rename() {
  local from="$1" to="$2" parked="$3" landed="$4" i
  echo "number-problems.sh: rename failed: '$from' -> '$to'" >&2
  echo "number-problems.sh: stopping here, and rolling nothing back. The plan now stands as:" >&2
  for i in "${!plan_dst[@]}"; do
    if [ "$i" -lt "$landed" ]; then
      echo "number-problems.sh:   done: '${plan_src[$i]}' is now '${plan_dst[$i]}'" >&2
    elif [ "$i" -lt "$parked" ]; then
      echo "number-problems.sh:   parked: '${plan_src[$i]}' sits at '${plan_dst[$i]}$tmp_suffix' and still has to become '${plan_dst[$i]}'" >&2
    else
      echo "number-problems.sh:   not moved: '${plan_src[$i]}' still has to become '${plan_dst[$i]}'" >&2
    fi
  done
  # Only when something is actually parked. A first rename that never started
  # leaves the tree as it was, and sending a reader to look for a tail that is
  # not there costs them the one thing this report is for.
  if [ "$parked" -gt "$landed" ]; then
    echo "number-problems.sh: the parked directories carry the tail '$tmp_suffix'." >&2
    echo "number-problems.sh: move each one to its final name by hand, then run again." >&2
  else
    echo "number-problems.sh: nothing is parked under '$tmp_suffix'. The tree is as it was." >&2
  fi
  exit 1
}

parked_through=0
for i in "${!plan_src[@]}"; do
  if ! mv -- "$PROBLEMS_ROOT/${plan_src[$i]}" "$PROBLEMS_ROOT/${plan_dst[$i]}$tmp_suffix"; then
    fail_mid_rename "${plan_src[$i]}" "${plan_dst[$i]}$tmp_suffix" "$parked_through" 0
  fi
  parked_through=$((parked_through + 1))
done

landed_through=0
for i in "${!plan_dst[@]}"; do
  if ! mv -- "$PROBLEMS_ROOT/${plan_dst[$i]}$tmp_suffix" "$PROBLEMS_ROOT/${plan_dst[$i]}"; then
    fail_mid_rename "${plan_dst[$i]}$tmp_suffix" "${plan_dst[$i]}" "${#plan_src[@]}" "$landed_through"
  fi
  landed_through=$((landed_through + 1))
done

exit 0
