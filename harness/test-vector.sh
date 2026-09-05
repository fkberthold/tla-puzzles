#!/usr/bin/env bash
# test-vector.sh: every frozen reference package carries a vector record, and
# every record says the same six things (bead tla-h2cg.2).
#
# THE INVARIANT
#
#   A directory holding reference/FREEZE.sha256 under authoring/ or pilot/ has
#   a VECTOR.md one level up. That record carries exactly six dimension rows,
#   in a fixed order, each with a level in 0..3 and a citation. After the table
#   it carries three key lines: a situation in S1..S9, a task shape in A..F,
#   and a reading gate reading ch11, ch13 or refinement.
#
#   authoring/VECTOR-FLOOR.md passes the same check with one relaxation. Its
#   situation and its task shape may read `floor`. The floor has no FREEZE
#   file, so the scan never reaches it, and this suite names it directly.
#
# WHY IT IS WORTH A GATE
#
# The vector is the only place a package says where it sits against the rest
# of the curriculum. Nothing else in the tree carries that, and a package can
# be authored, frozen and shipped without one, so the record is exactly the
# artifact that gets written for the first few packages and then quietly stops.
# By the time anyone notices, the packages with a record and the packages
# without it look the same from the outside. So the check runs every time
# instead of when somebody remembers.
#
# WHY THE GATE SCANS AND DOES NOT CARRY A LIST
#
# The scan looks for FREEZE.sha256 and derives the record path from where it
# found it. It holds no package names at all. A list would have to be edited by
# the same person adding the package, and a package added without that edit is
# then invisible to the one check meant to catch it. Scanning means a directory
# that gains a FREEZE file is covered the moment it lands.
#
# The record for a FREEZE file is its grandparent plus /VECTOR.md, which is one
# rule covering both shapes the bead names: authoring/<name>/reference/ and
# pilot/reference/. authoring/museum/ has no FREEZE file today, so the scan
# does not reach it and it draws no assertion either way.
#
# WHY PLACEHOLDER CITATIONS ARE REFUSED BY NAME
#
# A citation cell is non-empty after trimming and is not TODO, tbd, n/r, ? or
# a bare dash. Those five are how a record rots: the row survives, the shape
# still parses, and the claim behind it is gone. Checking only for a non-empty
# cell would pass every one of them.
#
# HOW THE CHECK IS KEPT HONEST
#
# Every assertion over the real tree has the shape "this record is well
# formed", which is also what a checker that stopped reading files reports. So
# the controls below plant records in a temp tree and require the checker to
# get each one wrong in the right way: five rows, a level of 4, an empty
# citation, a TODO citation, a reading gate of ch12, a missing situation line,
# two situation lines, a situation line above the table, a dimension out of
# order, and a floor value used where it does not belong.
# Each control asserts on WHICH clause failed, not just that something did, so
# a checker that failed everything for one reason would not pass them.
#
# VECTOR_ROOT overrides the tree the real-tree section reads, and it defaults
# to the repo root. Every scan goes through scan_freeze_records and every
# record goes through validate_record, planted and real alike, so a control
# proves something about the code the real assertions run.
#
# Usage:  harness/test-vector.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

VECTOR_ROOT="${VECTOR_ROOT:-$REPO_ROOT}"

TEST_RUNNER="scripts/test"
FLOOR_REL="authoring/VECTOR-FLOOR.md"

# The six rows, in the order they must appear. The order is part of the
# contract, so a record that carries all six shuffled is still wrong.
DIMENSIONS=(
  "representation"
  "property kind"
  "property count"
  "step sources"
  "state space"
  "form left open"
)

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

TMPROOT=$(mktemp -d -t tla_vector.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

# ---------------------------------------------------------------------------
# Small helpers.
# ---------------------------------------------------------------------------

TRIMMED=""

# trim <string> -> TRIMMED
#
# Whitespace around a cell and around a colon is tolerated by the contract, so
# nearly every comparison below runs through here first.
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  TRIMMED="$s"
}

# ---------------------------------------------------------------------------
# The scan.
# ---------------------------------------------------------------------------

FREEZE_LIST=()
RECORD_LIST=()

# scan_freeze_records <root>
#
# Sets FREEZE_LIST to every reference/FREEZE.sha256 under <root>/authoring and
# <root>/pilot, and RECORD_LIST to the VECTOR.md each one calls for, index for
# index. A root with neither subtree yields two empty lists rather than an
# error, which is what lets a control drive it over a tree that has no frozen
# package at all.
scan_freeze_records() {
  local root="$1" sub f dir
  FREEZE_LIST=()
  RECORD_LIST=()
  for sub in authoring pilot; do
    [ -d "$root/$sub" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      dir=$(dirname "$f")
      # The parent has to be reference/. A FREEZE.sha256 somewhere else is a
      # different artifact and this suite has nothing to say about it.
      [ "$(basename "$dir")" = "reference" ] || continue
      FREEZE_LIST+=("$f")
      RECORD_LIST+=("$(dirname "$dir")/VECTOR.md")
    done < <(find "$root/$sub" -type f -name FREEZE.sha256 -not -path '*/.git/*' | sort)
  done
  return 0
}

# record_list_has <path>
record_list_has() {
  local want="$1" p
  for p in "${RECORD_LIST[@]}"; do
    if [ "$p" = "$want" ]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# The record check.
# ---------------------------------------------------------------------------

REC_LINES=()
RECORD_WHY=""

HEADER_RE='^[[:space:]]*\|[[:space:]]*dimension[[:space:]]*\|[[:space:]]*level[[:space:]]*\|[[:space:]]*citation[[:space:]]*\|[[:space:]]*$'
SEP_RE='^[[:space:]]*\|[[:space:]]*:?-+:?[[:space:]]*\|[[:space:]]*:?-+:?[[:space:]]*\|[[:space:]]*:?-+:?[[:space:]]*\|[[:space:]]*$'
ROW_RE='^[[:space:]]*\|'
HEADING_RE='^#[[:space:]]+[^[:space:]]'

SITUATION_RE='^[[:space:]]*situation[[:space:]]*:[[:space:]]*(.*)$'
TASK_RE='^[[:space:]]*task[[:space:]]+shape[[:space:]]*:[[:space:]]*(.*)$'
GATE_RE='^[[:space:]]*reading[[:space:]]+gate[[:space:]]*:[[:space:]]*(.*)$'

KEY_COUNT=0
KEY_VALUE=""
KEY_INDEX=-1

# find_key <extended-regex with one capture group>
#
# Counts the lines of REC_LINES that carry the key and keeps the first one's
# value and index. The count is what catches a file naming a key twice, and
# the index is what catches a key line sitting above the table.
find_key() {
  local re="$1" i
  KEY_COUNT=0
  KEY_VALUE=""
  KEY_INDEX=-1
  for i in "${!REC_LINES[@]}"; do
    if [[ ${REC_LINES[$i]} =~ $re ]]; then
      KEY_COUNT=$((KEY_COUNT + 1))
      if [ "$KEY_INDEX" -lt 0 ]; then
        KEY_INDEX=$i
        KEY_VALUE="${BASH_REMATCH[1]}"
      fi
    fi
  done
  return 0
}

# validate_record <file> <mode>
#
# mode is `freeze` for a FREEZE sibling and `floor` for authoring/VECTOR-FLOOR.md,
# which may read `floor` for its situation and its task shape.
#
# First failure wins, and RECORD_WHY names the clause that broke. The
# implementer works from that line, so it says which row and what was wanted
# rather than only that the file is wrong.
validate_record() {
  local file="$1" mode="$2"
  RECORD_WHY=""
  REC_LINES=()

  if [ ! -f "$file" ]; then
    RECORD_WHY="missing file"
    return 1
  fi

  local line
  while IFS= read -r line || [ -n "$line" ]; do
    REC_LINES+=("$line")
  done <"$file"

  if [ "${#REC_LINES[@]}" -eq 0 ]; then
    RECORD_WHY="the file is empty"
    return 1
  fi

  if ! grep -qE -- "$HEADING_RE" <<<"${REC_LINES[0]}"; then
    RECORD_WHY="the first line is not a level-1 heading, it reads '${REC_LINES[0]}'"
    return 1
  fi

  # --- the table ---------------------------------------------------------

  local hdr=-1 i
  for i in "${!REC_LINES[@]}"; do
    if grep -qE -- "$HEADER_RE" <<<"${REC_LINES[$i]}"; then
      hdr=$i
      break
    fi
  done
  if [ "$hdr" -lt 0 ]; then
    RECORD_WHY="no table header row reading '| dimension | level | citation |'"
    return 1
  fi

  local sep=$((hdr + 1))
  if [ "$sep" -ge "${#REC_LINES[@]}" ]; then
    RECORD_WHY="the table header is the last line, so there is no separator and no rows"
    return 1
  fi
  if ! grep -qE -- "$SEP_RE" <<<"${REC_LINES[$sep]}"; then
    RECORD_WHY="the table header is not followed by a '|---|---|---|' separator"
    return 1
  fi

  local -a rows=()
  local j=$((sep + 1))
  while [ "$j" -lt "${#REC_LINES[@]}" ]; do
    grep -qE -- "$ROW_RE" <<<"${REC_LINES[$j]}" || break
    rows+=("${REC_LINES[$j]}")
    j=$((j + 1))
  done

  if [ "${#rows[@]}" -ne 6 ]; then
    RECORD_WHY="the table has ${#rows[@]} body rows, wanted exactly 6"
    return 1
  fi

  local last_row=$((sep + 6))

  # --- the six rows ------------------------------------------------------

  local -a cells=()
  local body want got level cite lc n
  for i in "${!rows[@]}"; do
    n=$((i + 1))
    want="${DIMENSIONS[$i]}"

    trim "${rows[$i]}"
    body="$TRIMMED"
    body="${body#|}"
    body="${body%|}"
    cells=()
    IFS='|' read -r -a cells <<<"$body"

    if [ "${#cells[@]}" -ne 3 ]; then
      RECORD_WHY="row $n has ${#cells[@]} cells, wanted 3 (dimension, level, citation)"
      return 1
    fi

    trim "${cells[0]}"
    got="$TRIMMED"
    if [ "$got" != "$want" ]; then
      RECORD_WHY="row $n names dimension '$got', wanted '$want' (the six rows are fixed and ordered)"
      return 1
    fi

    trim "${cells[1]}"
    level="$TRIMMED"
    case "$level" in
    0 | 1 | 2 | 3) ;;
    *)
      RECORD_WHY="row $n ($want) has level '$level', wanted one of 0 1 2 3"
      return 1
      ;;
    esac

    trim "${cells[2]}"
    cite="$TRIMMED"
    if [ -z "$cite" ]; then
      RECORD_WHY="row $n ($want) has an empty citation"
      return 1
    fi
    lc="${cite,,}"
    case "$lc" in
    todo | tbd | n/r | "?" | "-")
      RECORD_WHY="row $n ($want) has the placeholder citation '$cite'"
      return 1
      ;;
    esac
  done

  # --- the three key lines -----------------------------------------------

  local relax=""
  if [ "$mode" = "floor" ]; then
    relax=" or the literal floor"
  fi

  local v

  find_key "$SITUATION_RE"
  if [ "$KEY_COUNT" -eq 0 ]; then
    RECORD_WHY="no 'situation:' line"
    return 1
  fi
  if [ "$KEY_COUNT" -gt 1 ]; then
    RECORD_WHY="'situation:' appears $KEY_COUNT times, wanted exactly once"
    return 1
  fi
  if [ "$KEY_INDEX" -le "$last_row" ]; then
    RECORD_WHY="the 'situation:' line sits inside or above the table, wanted it after"
    return 1
  fi
  trim "$KEY_VALUE"
  v="$TRIMMED"
  if [ "$mode" = "floor" ] && [ "$v" = "floor" ]; then
    :
  elif ! grep -qE -- '^S[1-9]$' <<<"$v"; then
    RECORD_WHY="situation is '$v', wanted S1 through S9$relax"
    return 1
  fi

  find_key "$TASK_RE"
  if [ "$KEY_COUNT" -eq 0 ]; then
    RECORD_WHY="no 'task shape:' line"
    return 1
  fi
  if [ "$KEY_COUNT" -gt 1 ]; then
    RECORD_WHY="'task shape:' appears $KEY_COUNT times, wanted exactly once"
    return 1
  fi
  if [ "$KEY_INDEX" -le "$last_row" ]; then
    RECORD_WHY="the 'task shape:' line sits inside or above the table, wanted it after"
    return 1
  fi
  trim "$KEY_VALUE"
  v="$TRIMMED"
  if [ "$mode" = "floor" ] && [ "$v" = "floor" ]; then
    :
  elif ! grep -qE -- '^[A-F]$' <<<"$v"; then
    RECORD_WHY="task shape is '$v', wanted A through F$relax"
    return 1
  fi

  find_key "$GATE_RE"
  if [ "$KEY_COUNT" -eq 0 ]; then
    RECORD_WHY="no 'reading gate:' line"
    return 1
  fi
  if [ "$KEY_COUNT" -gt 1 ]; then
    RECORD_WHY="'reading gate:' appears $KEY_COUNT times, wanted exactly once"
    return 1
  fi
  if [ "$KEY_INDEX" -le "$last_row" ]; then
    RECORD_WHY="the 'reading gate:' line sits inside or above the table, wanted it after"
    return 1
  fi
  trim "$KEY_VALUE"
  v="$TRIMMED"
  case "$v" in
  ch11 | ch13 | refinement) ;;
  *)
    RECORD_WHY="reading gate is '$v', wanted ch11, ch13 or refinement"
    return 1
    ;;
  esac

  return 0
}

# assert_record_ok <label> <file> <mode>
assert_record_ok() {
  local label="$1" file="$2" mode="$3"
  if validate_record "$file" "$mode"; then
    ok "$label"
  else
    nope "$label. $file: $RECORD_WHY"
  fi
}

# assert_record_bad <label> <file> <mode> <why-regex>
#
# The control shape. It is not enough that the record failed: it has to fail on
# the clause the control was built to break, or a checker that rejects
# everything would collect a full row of green.
assert_record_bad() {
  local label="$1" file="$2" mode="$3" why_re="$4"
  if validate_record "$file" "$mode"; then
    nope "$label. It passed, so that clause of the record check is vacuous"
  elif grep -qE -- "$why_re" <<<"$RECORD_WHY"; then
    ok "$label"
  else
    nope "$label. It failed on the wrong clause: $RECORD_WHY"
  fi
}

# ---------------------------------------------------------------------------
# Fixture writers.
# ---------------------------------------------------------------------------

# write_record <path> <level> <citation> <situation-line> <task-line> <gate-line>
#
# Writes a record that is valid apart from whatever the caller varies. The
# level and the citation land on row 3, because one bad row has to fail the
# whole record. Passing an empty string for a key line writes a blank line,
# which is how the missing-key control is built.
write_record() {
  local path="$1" lvl="$2" cite="$3" situ="$4" task="$5" gate="$6"
  {
    printf '# Vector record\n'
    printf '\n'
    printf 'Written by harness/test-vector.sh as a control fixture.\n'
    printf '\n'
    printf '| dimension | level | citation |\n'
    printf '|---|---|---|\n'
    printf '| representation | 1 | ch06 p.61 |\n'
    printf '| property kind | 2 | ch07 p.75 |\n'
    printf '| property count | %s | %s |\n' "$lvl" "$cite"
    printf '| step sources | 1 | ch08 p.90 |\n'
    printf '| state space | 2 | ch14 p.220 |\n'
    printf '| form left open | 0 | ch05 p.51 |\n'
    printf '\n'
    printf '%s\n' "$situ"
    printf '%s\n' "$task"
    printf '%s\n' "$gate"
  } >"$path"
}

# write_five_row_record <path>
write_five_row_record() {
  {
    printf '# Vector record, one row short\n'
    printf '\n'
    printf '| dimension | level | citation |\n'
    printf '|---|---|---|\n'
    printf '| representation | 1 | ch06 p.61 |\n'
    printf '| property kind | 2 | ch07 p.75 |\n'
    printf '| property count | 3 | ch09 p.117 |\n'
    printf '| step sources | 1 | ch08 p.90 |\n'
    printf '| state space | 2 | ch14 p.220 |\n'
    printf '\n'
    printf 'situation: S4\n'
    printf 'task shape: C\n'
    printf 'reading gate: ch13\n'
  } >"$1"
}

# write_shuffled_record <path>
#
# All six dimensions, first two swapped. Row count and every cell are fine, so
# this is the one control that can only be caught by checking the order.
write_shuffled_record() {
  {
    printf '# Vector record, rows out of order\n'
    printf '\n'
    printf '| dimension | level | citation |\n'
    printf '|---|---|---|\n'
    printf '| property kind | 2 | ch07 p.75 |\n'
    printf '| representation | 1 | ch06 p.61 |\n'
    printf '| property count | 3 | ch09 p.117 |\n'
    printf '| step sources | 1 | ch08 p.90 |\n'
    printf '| state space | 2 | ch14 p.220 |\n'
    printf '| form left open | 0 | ch05 p.51 |\n'
    printf '\n'
    printf 'situation: S4\n'
    printf 'task shape: C\n'
    printf 'reading gate: ch13\n'
  } >"$1"
}

# write_duplicate_situation_record <path>
#
# Two situation lines, both after the table and both well formed. A checker
# that stops at the first one it finds reads this as valid.
write_duplicate_situation_record() {
  {
    printf '# Vector record, two situations\n'
    printf '\n'
    printf '| dimension | level | citation |\n'
    printf '|---|---|---|\n'
    printf '| representation | 1 | ch06 p.61 |\n'
    printf '| property kind | 2 | ch07 p.75 |\n'
    printf '| property count | 3 | ch09 p.117 |\n'
    printf '| step sources | 1 | ch08 p.90 |\n'
    printf '| state space | 2 | ch14 p.220 |\n'
    printf '| form left open | 0 | ch05 p.51 |\n'
    printf '\n'
    printf 'situation: S4\n'
    printf 'task shape: C\n'
    printf 'reading gate: ch13\n'
    printf 'situation: S5\n'
  } >"$1"
}

# write_early_situation_record <path>
#
# One situation line, well formed, sitting in the prose above the table. The
# count clause is satisfied, so only the placement clause can catch it.
write_early_situation_record() {
  {
    printf '# Vector record, situation above the table\n'
    printf '\n'
    printf 'situation: S4\n'
    printf '\n'
    printf '| dimension | level | citation |\n'
    printf '|---|---|---|\n'
    printf '| representation | 1 | ch06 p.61 |\n'
    printf '| property kind | 2 | ch07 p.75 |\n'
    printf '| property count | 3 | ch09 p.117 |\n'
    printf '| step sources | 1 | ch08 p.90 |\n'
    printf '| state space | 2 | ch14 p.220 |\n'
    printf '| form left open | 0 | ch05 p.51 |\n'
    printf '\n'
    printf 'task shape: C\n'
    printf 'reading gate: ch13\n'
  } >"$1"
}

# write_freeze <path>
write_freeze() {
  printf '%s  Spec.tla\n' "0000000000000000000000000000000000000000000000000000000000000000" >"$1"
}

# ---------------------------------------------------------------------------
# PART 1: the real tree.
# ---------------------------------------------------------------------------

echo "== part 1: every frozen package carries a record =="

scan_freeze_records "$VECTOR_ROOT"

# The floor under part 1. Every assertion below it reads "this record is well
# formed", and a scan that found nothing satisfies all of them by finding
# nothing to check.
if [ "${#FREEZE_LIST[@]}" -ge 1 ]; then
  ok "the scan found ${#FREEZE_LIST[@]} frozen reference package(s) under $VECTOR_ROOT"
else
  nope "the scan found no reference/FREEZE.sha256 under $VECTOR_ROOT, so every record assertion below is vacuous"
fi

for i in "${!RECORD_LIST[@]}"; do
  rec="${RECORD_LIST[$i]}"
  frz="${FREEZE_LIST[$i]}"
  assert_record_ok "${rec#"$VECTOR_ROOT/"} records the package frozen at ${frz#"$VECTOR_ROOT/"}" \
    "$rec" freeze
done

echo
echo "== part 2: the floor =="

# The floor has no FREEZE file, so the scan cannot reach it. It is named here
# instead, and it is the one record allowed to read `floor` where a package
# reads a situation and a task shape.
assert_record_ok "$FLOOR_REL is the floor every package is placed against" \
  "$VECTOR_ROOT/$FLOOR_REL" floor

# ---------------------------------------------------------------------------
# PART 3: the controls.
# ---------------------------------------------------------------------------

echo
echo "== part 3: the checker still bites =="

CTRL="$TMPROOT/controls"
GOOD="$CTRL/good"
BARE="$CTRL/bare"
BAD="$CTRL/bad"

mkdir -p "$GOOD/authoring/newcomer/reference"
mkdir -p "$GOOD/authoring/orphan/reference"
mkdir -p "$GOOD/pilot/reference"
mkdir -p "$BARE/authoring/museum" "$BARE/pilot/reports"
mkdir -p "$BAD"

write_freeze "$GOOD/authoring/newcomer/reference/FREEZE.sha256"
write_freeze "$GOOD/authoring/orphan/reference/FREEZE.sha256"
write_freeze "$GOOD/pilot/reference/FREEZE.sha256"

write_record "$GOOD/authoring/newcomer/VECTOR.md" \
  3 "ch09 p.117" "situation: S4" "task shape: C" "reading gate: ch13"
write_record "$GOOD/pilot/VECTOR.md" \
  0 "ch03 p.24" "situation: S1" "task shape: A" "reading gate: refinement"
write_record "$GOOD/$FLOOR_REL" \
  0 "ch02 p.14" "situation: floor" "task shape: floor" "reading gate: ch11"

printf 'a package with no frozen reference yet\n' >"$BARE/authoring/museum/DESCRIPTION.md"
printf 'a report, not a freeze\n' >"$BARE/pilot/reports/2026-01-01.md"

# --- the scan ------------------------------------------------------------

scan_freeze_records "$GOOD"

if [ "${#FREEZE_LIST[@]}" -eq 3 ]; then
  ok "control: the scan finds all three planted FREEZE files"
else
  nope "control: the scan found ${#FREEZE_LIST[@]} planted FREEZE files, wanted 3"
fi

# The discovery half. `newcomer` appears nowhere in this file outside the
# fixture, so a checker carrying a hardcoded list of package names fails here.
if record_list_has "$GOOD/authoring/newcomer/VECTOR.md"; then
  ok "control: a package the gate has never heard of is covered the moment it gains a FREEZE file"
else
  nope "control: the scan did not derive authoring/newcomer/VECTOR.md from its FREEZE file"
fi

if record_list_has "$GOOD/pilot/VECTOR.md"; then
  ok "control: pilot/reference/FREEZE.sha256 asks for pilot/VECTOR.md"
else
  nope "control: the scan did not derive pilot/VECTOR.md from pilot/reference/FREEZE.sha256"
fi

scan_freeze_records "$BARE"

if [ "${#FREEZE_LIST[@]}" -eq 0 ]; then
  ok "control: a tree whose directories carry no FREEZE file yields no record assertions"
else
  nope "control: a tree with no FREEZE file yielded ${#FREEZE_LIST[@]} record assertions"
fi

# --- a good record, and a missing one ------------------------------------

assert_record_ok "control: a well-formed record passes" \
  "$GOOD/authoring/newcomer/VECTOR.md" freeze

assert_record_bad "control: a frozen package with no sibling record fails" \
  "$GOOD/authoring/orphan/VECTOR.md" freeze '^missing file$'

# --- the table -----------------------------------------------------------

write_five_row_record "$BAD/five-rows.md"
assert_record_bad "control: five dimension rows fails on the row count" \
  "$BAD/five-rows.md" freeze '^the table has 5 body rows'

write_shuffled_record "$BAD/shuffled.md"
assert_record_bad "control: the six dimensions out of order fails on the order" \
  "$BAD/shuffled.md" freeze "names dimension 'property kind'"

write_record "$BAD/level-4.md" 4 "ch09 p.117" "situation: S4" "task shape: C" "reading gate: ch13"
assert_record_bad "control: a level of 4 fails, so 0..3 is a range and not a suggestion" \
  "$BAD/level-4.md" freeze "has level '4'"

write_record "$BAD/empty-cite.md" 3 "" "situation: S4" "task shape: C" "reading gate: ch13"
assert_record_bad "control: an empty citation cell fails" \
  "$BAD/empty-cite.md" freeze 'has an empty citation$'

write_record "$BAD/todo-cite.md" 3 "TODO" "situation: S4" "task shape: C" "reading gate: ch13"
assert_record_bad "control: a TODO citation fails, so a placeholder cannot stand in for a reference" \
  "$BAD/todo-cite.md" freeze "placeholder citation 'TODO'"

# --- the three key lines -------------------------------------------------

write_record "$BAD/gate-ch12.md" 3 "ch09 p.117" "situation: S4" "task shape: C" "reading gate: ch12"
assert_record_bad "control: a reading gate of ch12 fails, so the three gates are a closed set" \
  "$BAD/gate-ch12.md" freeze "^reading gate is 'ch12'"

write_record "$BAD/no-situation.md" 3 "ch09 p.117" "" "task shape: C" "reading gate: ch13"
assert_record_bad "control: a record with no situation line fails" \
  "$BAD/no-situation.md" freeze "^no 'situation:' line$"

# The other two halves of "exactly once, after the table". Without these, a
# checker that read the first situation line it saw and stopped would pass
# every assertion in this suite.
write_duplicate_situation_record "$BAD/two-situations.md"
assert_record_bad "control: two situation lines fails, so 'exactly once' is counted" \
  "$BAD/two-situations.md" freeze "appears 2 times"

write_early_situation_record "$BAD/early-situation.md"
assert_record_bad "control: a situation line above the table fails, so the key lines come after it" \
  "$BAD/early-situation.md" freeze "sits inside or above the table"

# --- the floor relaxation, both directions -------------------------------

assert_record_bad "control: situation: floor fails in a package record" \
  "$GOOD/authoring/VECTOR-FLOOR.md" freeze "^situation is 'floor'"

assert_record_ok "control: situation: floor passes in the floor record" \
  "$GOOD/authoring/VECTOR-FLOOR.md" floor

# ---------------------------------------------------------------------------
# PART 4: registration.
# ---------------------------------------------------------------------------

echo
echo "== part 4: structural =="

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-vector\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-vector.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-vector.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
