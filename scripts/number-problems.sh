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
    if [[ "$base" =~ ^([0-9]+_)?${name}$ ]]; then
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
      if [[ "$base" =~ ^([0-9]+_)?${name}$ ]]; then
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
# ---------------------------------------------------------------------------

tmp_suffix=".number-problems-tmp.$$"
for i in "${!plan_src[@]}"; do
  mv -- "$PROBLEMS_ROOT/${plan_src[$i]}" "$PROBLEMS_ROOT/${plan_dst[$i]}$tmp_suffix"
done
for i in "${!plan_dst[@]}"; do
  mv -- "$PROBLEMS_ROOT/${plan_dst[$i]}$tmp_suffix" "$PROBLEMS_ROOT/${plan_dst[$i]}"
done

exit 0
