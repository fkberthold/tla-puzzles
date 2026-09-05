#!/usr/bin/env bash
# sequence.sh: order the ramp, or name the position nothing fills
# (bead tla-h2cg.3).
#
# WHAT IT DOES
#
#   harness/sequence.sh --search [--out <path>]
#   harness/sequence.sh --check <order-file>
#
# --search reads every vector record under VECTOR_ROOT and looks for an order
# the ramp can be delivered in. --check reads an order somebody already wrote
# and says whether it holds.
#
# THE RULE (decision D4, V2-PLAN.md:355-364)
#
# Over the delivered sequence P_1 .. P_n, with the floor F as the starting
# point:
#
#   (a)  no two neighbours share a situation or a task shape,
#   (b)  for every dimension d, level_d(P_i) is at most one over the running
#        maximum of level_d(F) and level_d(P_1) .. level_d(P_i-1),
#   (b') at most one dimension rises above that running maximum,
#   (c)  a problem gated ch13 sits after `checkpoint: ch13`, and one gated
#        refinement sits after `checkpoint: refinement`.
#
# Drops and returns are free, so a problem may sit under the running maximum on
# every dimension and still be legal. Neighbours are consecutive problems, so a
# checkpoint line between two of them leaves them neighbours. The floor is
# never an item in the sequence. It is the initial running maximum, and it is
# the prev-name at position 1.
#
# Positions count problems, not lines. A checkpoint consumes no position.
#
# WHY THE HOLE IS THE HALF THAT MATTERS
#
# A found order is easy to spot check by eye. A missing rung is not, and the
# missing rung is what an author acts on. So a failed search does not stop at
# "no". It names the position nothing fills, the problem before it, and what
# each remaining candidate broke. Without that the author goes off to write a
# problem for a rung that cannot exist.
#
# HOW THE SEARCH WORKS
#
# Depth first over the records, candidates tried in name order, backtracking on
# a dead end. The state at each step is the running maximum, the previous
# problem's situation and task shape, and the set already placed. That is
# enough, because the running maximum does not depend on the order the placed
# problems arrived in. A state the search has already refused is remembered, so
# the same set is not walked twice.
#
# The two checkpoints are placed rather than searched. The first problem gated
# ch13 gets `checkpoint: ch13` emitted right before it, and the same for
# refinement. Clause (c) is then true by construction, which is why it only
# bites under --check.
#
# WHERE THE RECORDS COME FROM
#
# The scan is harness/test-vector.sh's scan. Every VECTOR.md one level above a
# reference/FREEZE.sha256 under <root>/authoring and <root>/pilot, plus the
# floor at <root>/authoring/VECTOR-FLOOR.md. <root> is VECTOR_ROOT if it is
# set, and the repo root otherwise. A problem's name is the directory holding
# its VECTOR.md.
#
# This script reads a record for its six levels and its three key lines. It
# does not judge the record's shape. That is test-vector.sh's job, and running
# the check twice in two places is how the two answers drift apart.
#
# ORDER FORMAT
#
# One entry per line. Either a problem name, or exactly `checkpoint: ch13`, or
# exactly `checkpoint: refinement`. Blank lines and lines starting with # are
# ignored.
#
# Usage:  harness/sequence.sh --search [--out <path>]
#         harness/sequence.sh --check <order-file>
# Exit:   0 an order was found, or the order holds
#         1 no order exists, or the order breaks a clause
#         2 bad arguments, a missing file, or a record that will not parse

set -uo pipefail

# The six rows, in the order a record carries them. Row order is the contract,
# so the levels are read by position and not by the name in the first cell.
DIMENSIONS=(
  "representation"
  "property kind"
  "property count"
  "step sources"
  "state space"
  "form left open"
)

HEADER_RE='^[[:space:]]*\|[[:space:]]*dimension[[:space:]]*\|[[:space:]]*level[[:space:]]*\|[[:space:]]*citation[[:space:]]*\|[[:space:]]*$'
ROW_RE='^[[:space:]]*\|'
SITUATION_RE='^[[:space:]]*situation[[:space:]]*:[[:space:]]*(.*)$'
TASK_RE='^[[:space:]]*task[[:space:]]+shape[[:space:]]*:[[:space:]]*(.*)$'
GATE_RE='^[[:space:]]*reading[[:space:]]+gate[[:space:]]*:[[:space:]]*(.*)$'

die2() {
  printf 'sequence.sh: %s\n' "$1" >&2
  exit 2
}

TRIMMED=""

# trim <string> -> TRIMMED
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  TRIMMED="$s"
}

# ---------------------------------------------------------------------------
# Reading one record.
# ---------------------------------------------------------------------------

PR_LV=()
PR_SITU=""
PR_SHAPE=""
PR_GATE=""
PARSE_WHY=""

# parse_record <file>
#
# Sets PR_LV to the six levels in row order, and PR_SITU, PR_SHAPE and PR_GATE
# to the three key lines. Returns 1 with PARSE_WHY set on anything it cannot
# read.
parse_record() {
  local file="$1"
  local -a lines=()
  local -a rows=()
  local -a cells=()
  local line body lvl
  local hdr=-1 i j
  local got_situ=0 got_shape=0 got_gate=0

  PR_LV=()
  PR_SITU=""
  PR_SHAPE=""
  PR_GATE=""
  PARSE_WHY=""

  if [ ! -f "$file" ]; then
    PARSE_WHY="the file is not there"
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    lines+=("$line")
  done <"$file"

  if [ "${#lines[@]}" -eq 0 ]; then
    PARSE_WHY="the file is empty"
    return 1
  fi

  for i in "${!lines[@]}"; do
    if [[ ${lines[$i]} =~ $HEADER_RE ]]; then
      hdr=$i
      break
    fi
  done
  if [ "$hdr" -lt 0 ]; then
    PARSE_WHY="no '| dimension | level | citation |' header row"
    return 1
  fi

  # hdr + 1 is the separator row. The body runs from there to the first line
  # that is not a table row.
  j=$((hdr + 2))
  while [ "$j" -lt "${#lines[@]}" ]; do
    if [[ ${lines[$j]} =~ $ROW_RE ]]; then
      rows+=("${lines[$j]}")
    else
      break
    fi
    j=$((j + 1))
  done

  if [ "${#rows[@]}" -ne 6 ]; then
    PARSE_WHY="the table has ${#rows[@]} body rows, wanted 6"
    return 1
  fi

  for i in 0 1 2 3 4 5; do
    trim "${rows[$i]}"
    body="$TRIMMED"
    body="${body#|}"
    body="${body%|}"
    cells=()
    IFS='|' read -r -a cells <<<"$body"
    if [ "${#cells[@]}" -lt 2 ]; then
      PARSE_WHY="row $((i + 1)) (${DIMENSIONS[$i]}) has no level cell"
      return 1
    fi
    trim "${cells[1]}"
    lvl="$TRIMMED"
    case "$lvl" in
    '' | *[!0-9]*)
      PARSE_WHY="row $((i + 1)) (${DIMENSIONS[$i]}) has level '$lvl', wanted a number"
      return 1
      ;;
    esac
    PR_LV+=("$lvl")
  done

  for i in "${!lines[@]}"; do
    if [ "$got_situ" -eq 0 ] && [[ ${lines[$i]} =~ $SITUATION_RE ]]; then
      trim "${BASH_REMATCH[1]}"
      PR_SITU="$TRIMMED"
      got_situ=1
    fi
    if [ "$got_shape" -eq 0 ] && [[ ${lines[$i]} =~ $TASK_RE ]]; then
      trim "${BASH_REMATCH[1]}"
      PR_SHAPE="$TRIMMED"
      got_shape=1
    fi
    if [ "$got_gate" -eq 0 ] && [[ ${lines[$i]} =~ $GATE_RE ]]; then
      trim "${BASH_REMATCH[1]}"
      PR_GATE="$TRIMMED"
      got_gate=1
    fi
  done

  if [ "$got_situ" -eq 0 ] || [ -z "$PR_SITU" ]; then
    PARSE_WHY="no 'situation:' line"
    return 1
  fi
  if [ "$got_shape" -eq 0 ] || [ -z "$PR_SHAPE" ]; then
    PARSE_WHY="no 'task shape:' line"
    return 1
  fi
  if [ "$got_gate" -eq 0 ] || [ -z "$PR_GATE" ]; then
    PARSE_WHY="no 'reading gate:' line"
    return 1
  fi

  return 0
}

# ---------------------------------------------------------------------------
# The record set.
#
# Parallel arrays over one index per problem. LV is flat, six entries per
# record, so LV[idx * 6 + d] is the level of dimension d.
# ---------------------------------------------------------------------------

NAMES=()
PATHS=()
LV=()
SITU=()
SHAPE=()
GATE=()
declare -A IDX=()

FLOOR_LV=()
FLOOR_SITU=""
FLOOR_SHAPE=""
N=0
SORTED_NAMES=()

load_records() {
  local sub f dir recdir name i
  local floor="$ROOT/authoring/VECTOR-FLOOR.md"

  if ! parse_record "$floor"; then
    die2 "cannot read the floor record $floor: $PARSE_WHY"
  fi
  FLOOR_LV=("${PR_LV[@]}")
  FLOOR_SITU="$PR_SITU"
  FLOOR_SHAPE="$PR_SHAPE"

  for sub in authoring pilot; do
    [ -d "$ROOT/$sub" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      dir=$(dirname "$f")
      # The parent has to be reference/. A FREEZE.sha256 anywhere else belongs
      # to something this script has nothing to say about.
      [ "$(basename "$dir")" = "reference" ] || continue
      recdir=$(dirname "$dir")
      name=$(basename "$recdir")
      if [ -n "${IDX[$name]:-}" ]; then
        die2 "two records answer to the name '$name': ${PATHS[${IDX[$name]}]} and $recdir/VECTOR.md"
      fi
      if ! parse_record "$recdir/VECTOR.md"; then
        die2 "cannot read $recdir/VECTOR.md: $PARSE_WHY"
      fi
      IDX[$name]=$N
      NAMES+=("$name")
      PATHS+=("$recdir/VECTOR.md")
      for i in 0 1 2 3 4 5; do
        LV+=("${PR_LV[$i]}")
      done
      SITU+=("$PR_SITU")
      SHAPE+=("$PR_SHAPE")
      GATE+=("$PR_GATE")
      N=$((N + 1))
    done < <(find "$ROOT/$sub" -type f -name FREEZE.sha256 -not -path '*/.git/*' | LC_ALL=C sort)
  done

  if [ "$N" -gt 0 ]; then
    mapfile -t SORTED_NAMES < <(printf '%s\n' "${NAMES[@]}" | LC_ALL=C sort)
  fi
}

# ---------------------------------------------------------------------------
# The clauses.
#
# MAXLV is the running maximum. Both the checker and the search read it, and
# the search saves and restores it around each placement.
# ---------------------------------------------------------------------------

MAXLV=()
CV_CLAUSE=""
CV_DETAIL=""

# clause_abbp <idx> <prev-situation> <prev-shape>
#
# Applies (a), (b) and (b') to one candidate against MAXLV. Returns 1 with
# CV_CLAUSE and CV_DETAIL set on the first breach. Clause (c) is not here,
# because the search satisfies it by placing the checkpoint and the checker
# has to see the ORDER to judge it.
clause_abbp() {
  local idx="$1" psitu="$2" pshape="$3"
  local base=$((idx * 6))
  local i lvl mx
  local rises=0 rise_names=""

  CV_CLAUSE=""
  CV_DETAIL=""

  if [ "${SITU[$idx]}" = "$psitu" ]; then
    CV_CLAUSE="a"
    CV_DETAIL="both sit in situation ${SITU[$idx]}"
    return 1
  fi
  if [ "${SHAPE[$idx]}" = "$pshape" ]; then
    CV_CLAUSE="a"
    CV_DETAIL="both use task shape ${SHAPE[$idx]}"
    return 1
  fi

  for i in 0 1 2 3 4 5; do
    lvl="${LV[$((base + i))]}"
    mx="${MAXLV[$i]}"
    if [ "$lvl" -gt $((mx + 1)) ]; then
      CV_CLAUSE="b"
      CV_DETAIL="${DIMENSIONS[$i]} is $lvl over a running maximum of $mx"
      return 1
    fi
    if [ "$lvl" -gt "$mx" ]; then
      rises=$((rises + 1))
      rise_names="$rise_names, ${DIMENSIONS[$i]}"
    fi
  done

  if [ "$rises" -gt 1 ]; then
    CV_CLAUSE="b'"
    CV_DETAIL="$rises dimensions rise at once: ${rise_names#, }"
    return 1
  fi

  return 0
}

# raise_max <idx>
raise_max() {
  local idx="$1"
  local base=$((idx * 6))
  local i
  for i in 0 1 2 3 4 5; do
    if [ "${LV[$((base + i))]}" -gt "${MAXLV[$i]}" ]; then
      MAXLV[i]="${LV[$((base + i))]}"
    fi
  done
}

# ---------------------------------------------------------------------------
# The search.
# ---------------------------------------------------------------------------

PLACED=()
ORDER_IDX=()
declare -A MEMO=()
BEST_POS=0
BEST_PREV="floor"
BEST_REJ=()

# placed_key
#
# One character per record, so a state the search already refused is one string
# lookup away. The running maximum is left out on purpose: it is the
# componentwise maximum of the floor and the placed set, so the placed set
# already determines it.
placed_key() {
  local s="" i
  for ((i = 0; i < N; i++)); do
    s="$s${PLACED[$i]}"
  done
  printf '%s' "$s"
}

# search_from <depth> <prev-index>
#
# prev-index is -1 at position 1, which is how the floor gets to be the
# previous entry. Returns 0 with ORDER_IDX holding a full order.
search_from() {
  local depth="$1" prev_idx="$2"
  local psitu pshape key name idx accepted=0
  local -a rejects=()
  local -a saved=()

  if [ "$depth" -ge "$N" ]; then
    return 0
  fi

  if [ "$prev_idx" -lt 0 ]; then
    psitu="$FLOOR_SITU"
    pshape="$FLOOR_SHAPE"
  else
    psitu="${SITU[$prev_idx]}"
    pshape="${SHAPE[$prev_idx]}"
  fi

  key=$(placed_key)
  key="$key:$prev_idx"
  if [ -n "${MEMO[$key]:-}" ]; then
    return 1
  fi

  for name in "${SORTED_NAMES[@]}"; do
    idx="${IDX[$name]}"
    [ "${PLACED[$idx]}" -eq 0 ] || continue
    if ! clause_abbp "$idx" "$psitu" "$pshape"; then
      rejects+=("$name|$CV_CLAUSE|$CV_DETAIL")
      continue
    fi
    accepted=1

    saved=("${MAXLV[@]}")
    raise_max "$idx"
    PLACED[idx]=1
    ORDER_IDX+=("$idx")

    if search_from $((depth + 1)) "$idx"; then
      return 0
    fi

    ORDER_IDX=("${ORDER_IDX[@]:0:$depth}")
    PLACED[idx]=0
    MAXLV=("${saved[@]}")
  done

  # A node that accepted nothing is a position the search could not fill. The
  # deepest such node is the shallowest unfillable position, because every
  # position above it was filled on the way down.
  if [ "$accepted" -eq 0 ] && [ $((depth + 1)) -gt "$BEST_POS" ]; then
    BEST_POS=$((depth + 1))
    if [ "$prev_idx" -lt 0 ]; then
      BEST_PREV="floor"
    else
      BEST_PREV="${NAMES[$prev_idx]}"
    fi
    BEST_REJ=()
    if [ "${#rejects[@]}" -gt 0 ]; then
      BEST_REJ=("${rejects[@]}")
    fi
  fi

  MEMO[$key]=1
  return 1
}

ORDER_OUT=()
INFO_OUT=()

# build_output
#
# Turns ORDER_IDX into the ORDER lines, with each checkpoint sitting right
# before the first problem that needs it, and into the first-appearance lines.
build_output() {
  local seen13=0 seenref=0 pos=0 idx s
  local -A first=()

  ORDER_OUT=()
  INFO_OUT=()
  [ "${#ORDER_IDX[@]}" -gt 0 ] || return 0

  for idx in "${ORDER_IDX[@]}"; do
    if [ "${GATE[$idx]}" = "ch13" ] && [ "$seen13" -eq 0 ]; then
      ORDER_OUT+=("checkpoint: ch13")
      seen13=1
    fi
    if [ "${GATE[$idx]}" = "refinement" ] && [ "$seenref" -eq 0 ]; then
      ORDER_OUT+=("checkpoint: refinement")
      seenref=1
    fi
    ORDER_OUT+=("${NAMES[$idx]}")

    pos=$((pos + 1))
    s="${SITU[$idx]}"
    if [ -z "${first[$s]:-}" ]; then
      first[$s]=1
      INFO_OUT+=("info: $s first appears at position $pos (${NAMES[$idx]})")
    fi
  done
  return 0
}

run_search() {
  local i line rej name clause detail rest

  MAXLV=("${FLOOR_LV[@]}")
  PLACED=()
  for ((i = 0; i < N; i++)); do
    PLACED[i]=0
  done
  ORDER_IDX=()

  if search_from 0 -1; then
    build_output
    if [ -n "$OUT_PATH" ]; then
      : >"$OUT_PATH" || die2 "cannot write $OUT_PATH"
      for line in ${ORDER_OUT[@]+"${ORDER_OUT[@]}"}; do
        printf '%s\n' "$line" >>"$OUT_PATH"
      done
    else
      for line in ${ORDER_OUT[@]+"${ORDER_OUT[@]}"}; do
        printf '%s\n' "$line"
      done
    fi
    for line in ${INFO_OUT[@]+"${INFO_OUT[@]}"}; do
      printf '%s\n' "$line"
    done
    return 0
  fi

  printf 'no valid order over %d problems\n' "$N"
  if [ "$BEST_POS" -le 1 ]; then
    printf 'hole at position 1: no problem within one new high of the floor\n'
  else
    printf 'hole at position %d after %s: every problem left breaks a clause\n' \
      "$BEST_POS" "$BEST_PREV"
  fi
  for rej in ${BEST_REJ[@]+"${BEST_REJ[@]}"}; do
    name="${rej%%|*}"
    rest="${rej#*|}"
    clause="${rest%%|*}"
    detail="${rest#*|}"
    printf '  %s: violates (%s): %s\n' "$name" "$clause" "$detail"
  done
  return 1
}

# ---------------------------------------------------------------------------
# The check.
# ---------------------------------------------------------------------------

run_check() {
  local file="$1"
  local -a entries=()
  local -a info=()
  local -A first=()
  local line e idx s
  local prev="floor" psitu pshape
  local seen13=0 seenref=0 pos=0
  local failline=""

  [ -f "$file" ] || die2 "no such order file: $file"

  while IFS= read -r line || [ -n "$line" ]; do
    trim "$line"
    line="$TRIMMED"
    case "$line" in
    "") continue ;;
    "#"*) continue ;;
    esac
    entries+=("$line")
  done <"$file"

  # Resolve every entry before judging any of them. A name the tree does not
  # carry is a usage error, and a usage error must not come back dressed as a
  # verdict on the ramp.
  for e in ${entries[@]+"${entries[@]}"}; do
    case "$e" in
    "checkpoint: ch13" | "checkpoint: refinement") continue ;;
    esac
    if [ -z "${IDX[$e]:-}" ]; then
      die2 "$file names '$e', which is no record under $ROOT"
    fi
  done

  MAXLV=("${FLOOR_LV[@]}")
  psitu="$FLOOR_SITU"
  pshape="$FLOOR_SHAPE"

  for e in ${entries[@]+"${entries[@]}"}; do
    if [ "$e" = "checkpoint: ch13" ]; then
      seen13=1
      continue
    fi
    if [ "$e" = "checkpoint: refinement" ]; then
      seenref=1
      continue
    fi

    idx="${IDX[$e]}"
    pos=$((pos + 1))

    if ! clause_abbp "$idx" "$psitu" "$pshape"; then
      failline="FAIL at position $pos: $prev -> $e violates ($CV_CLAUSE): $CV_DETAIL"
      break
    fi
    if [ "${GATE[$idx]}" = "ch13" ] && [ "$seen13" -eq 0 ]; then
      failline="FAIL at position $pos: $prev -> $e violates (c): gated ch13 with no 'checkpoint: ch13' line before it"
      break
    fi
    if [ "${GATE[$idx]}" = "refinement" ] && [ "$seenref" -eq 0 ]; then
      failline="FAIL at position $pos: $prev -> $e violates (c): gated refinement with no 'checkpoint: refinement' line before it"
      break
    fi

    s="${SITU[$idx]}"
    if [ -z "${first[$s]:-}" ]; then
      first[$s]=1
      info+=("info: $s first appears at position $pos ($e)")
    fi

    raise_max "$idx"
    prev="$e"
    psitu="${SITU[$idx]}"
    pshape="${SHAPE[$idx]}"
  done

  for line in ${info[@]+"${info[@]}"}; do
    printf '%s\n' "$line"
  done

  if [ -n "$failline" ]; then
    printf '%s\n' "$failline"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Arguments.
# ---------------------------------------------------------------------------

MODE=""
ORDER_FILE=""
OUT_PATH=""

while [ "$#" -gt 0 ]; do
  case "$1" in
  --search)
    MODE="search"
    shift
    ;;
  --check)
    [ "$#" -ge 2 ] || die2 "--check wants an order file"
    MODE="check"
    ORDER_FILE="$2"
    shift 2
    ;;
  --out)
    [ "$#" -ge 2 ] || die2 "--out wants a path"
    OUT_PATH="$2"
    shift 2
    ;;
  *)
    die2 "unknown argument '$1'. Usage: sequence.sh --search [--out <path>] | --check <order-file>"
    ;;
  esac
done

[ -n "$MODE" ] || die2 "wanted --search or --check <order-file>"
if [ -n "$OUT_PATH" ] && [ "$MODE" != "search" ]; then
  die2 "--out only goes with --search"
fi

ROOT="${VECTOR_ROOT:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel) || die2 "no VECTOR_ROOT and this is no git checkout"
fi
[ -d "$ROOT" ] || die2 "no such vector root: $ROOT"

load_records

if [ "$MODE" = "search" ]; then
  run_search
  exit $?
fi

run_check "$ORDER_FILE"
exit $?
