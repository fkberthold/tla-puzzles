#!/usr/bin/env bash
# test-sequence.sh: harness/sequence.sh either orders the ramp or names the
# hole (bead tla-h2cg.3).
#
# THE INVARIANT (decision D4, V2-PLAN.md:355-364)
#
#   Over the delivered sequence P_1 .. P_n, with floor F and reading
#   checkpoints C_ch13 and C_ref at fixed positions,
#
#     (a)  no two neighbours share a situation or a task shape,
#     (b)  for every dimension d, level_d(P_i) <= 1 + max(level_d(F),
#          level_d(P_1) .. level_d(P_i-1)),
#     (b') at most one dimension d has level_d(P_i) strictly above that
#          running maximum,
#     (c)  a problem gated ch13 sits after C_ch13, and one gated refinement
#          sits after C_ref.
#
#   Drops and returns are free. Neighbours are consecutive problems, and a
#   checkpoint sitting between two problems leaves them neighbours. The floor
#   is never an item in the sequence. It is the initial running maximum, and
#   it is the prev-name at position 1.
#
# WHY IT IS WORTH A GATE
#
# The ramp is the one thing in v2 that no single artifact carries. A vector
# record says where one problem sits. Nothing but this script says whether the
# problems, taken in some order, climb at a rate a learner can walk. Order used
# to live in a directory name, where it was checked by nobody and moved by
# hand. The whole point of pulling it into an ORDER file is that a machine now
# reads it, so the machine has to be gated too.
#
# The second half matters more than the first. Finding an order is easy to spot
# check by eye. Reporting the hole is not, and the hole is what an author acts
# on. A script that quietly emitted a near miss would send someone off to write
# a problem for a rung that cannot exist.
#
# WHAT THE SUITE DRIVES
#
#   harness/sequence.sh --search [--out <path>]     over VECTOR_ROOT
#   harness/sequence.sh --check <order-file>        over VECTOR_ROOT
#
# Records are discovered the way harness/test-vector.sh discovers them: every
# VECTOR.md one level above a reference/FREEZE.sha256 under <root>/authoring
# and <root>/pilot, plus the floor at <root>/authoring/VECTOR-FLOOR.md.
#
# SCENARIO 1, THE REAL SEVEN, AND THE HAND CHECK BEHIND IT
#
# The floor is learntla ch11 exercise 5, Airlock, at
#
#   representation 0, property kind 2, property count 1, step sources 0,
#   state space 0, form left open 0.
#
# At position 1 the running maximum is the floor. So a candidate may sit at
# most one level above the floor on each dimension, and at most one dimension
# may rise at all. Here is every withdrawn record against that bar, read off
# the six VECTOR.md files by hand on 2026-09-05.
#
#   record    rep kind cnt src spc form   rises  (b) broken on
#   -------   --- ---- --- --- --- ----   -----  ------------------------------
#   pilot      1   2    2   2   0   3       4    step sources, form left open
#   custody    3   3    3   3   3   2       6    rep, count, sources, space, form
#   qsl        1   3    3   2   2   3       6    count, sources, space, form
#   buyclub    2   3    2   2   1   2       6    rep, sources, form
#   seedlib    1   3    3   3   0   3       5    count, sources, form
#   consign    2   2    2   2   0   2       4    rep, sources, form
#
# Every one of the six breaks (b) on at least three dimensions, and every one
# rises on four or more, so every one breaks (b') as well. Position 1 has no
# candidate at all. Nothing deeper is reachable, so the search reports the
# position-1 hole and nothing else. That is what makes the withdrawal in §2.5
# concrete: from this floor, the six delivered problems are not a ramp, they
# are a cliff.
#
# The seven files are copied by fixed path, never by scanning. A batch-2 record
# landing under authoring/ later must not walk into this scenario and change
# the answer.
#
# SCENARIO 2, A SYNTHETIC RAMP WITH A KNOWN GOOD ORDER
#
# Ten planted records over a floor of all zeros. Levels are in the fixed row
# order: representation, property kind, property count, step sources, state
# space, form left open.
#
#   name      levels          situ  shape  gate
#   -------   -------------   ----  -----  ----------
#   alpha     0 1 1 0 0 0     S3    A      ch11
#   beta      1 1 1 1 1 0     S2    A      ch11
#   delta     1 1 1 1 1 1     S3    B      refinement
#   epsilon   1 1 0 0 0 0     S2    B      ch11
#   gamma     1 0 0 0 0 0     S1    A      ch11
#   iota      1 1 1 1 1 1     S2    C      ch11
#   mu        1 1 0 0 0 0     S2    B      ch11
#   nu        0 2 0 0 0 0     S3    D      ch11
#   theta     1 2 1 1 1 1     S1    A      ch11
#   zeta      1 1 1 1 0 0     S1    B      ch13
#
# One order that satisfies all four clauses, worked out by hand:
#
#   gamma, epsilon, alpha, [ch13] zeta, beta, [refinement] delta, iota,
#   theta, mu, nu
#
# Each of the first six raises exactly one dimension by exactly one. iota and
# mu and nu sit at or under the running maximum, so they are free. theta takes
# property kind from 1 to 2, which is the one rise it is allowed.
#
# The drop and return is on representation. gamma and epsilon hold it at 1,
# alpha drops it to 0, zeta brings it back to 1. Both moves have to be free, or
# the ramp cannot interleave at all.
#
# zeta is gated ch13 and delta is gated refinement, so both checkpoints have to
# appear, each before the problem that needs it.
#
# This suite does NOT assert that the search prints this order. It asserts that
# whatever order the search prints satisfies the four clauses, recomputed here
# from the same table the fixtures were written from. Verifying the output by
# feeding it back through --check would be circular, and pinning one literal
# order would fail a correct implementation that broke a tie the other way.
#
# HOW THE CHECK IS KEPT HONEST
#
# Every --check control below breaks exactly ONE clause at exactly one
# position, and asserts on which clause the script named. A checker that
# rejected every order would otherwise collect a full row of green. The
# clause-by-clause isolation is the reason the fixture carries mu, nu and iota
# at all: without a record that is flat against the running maximum, an order
# that shares a situation also breaks (b'), and the control proves nothing.
#
# Each rejection has an accepting counterpart nearby, because a script that
# had stopped running would pass every rejection on its own.
#
# Usage:  harness/test-sequence.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="harness/sequence.sh"
TEST_RUNNER="scripts/test"

# The six rows, in the order a record carries them.
DIMENSIONS=(
  "representation"
  "property kind"
  "property count"
  "step sources"
  "state space"
  "form left open"
)

# The seven real records scenario 1 copies, by fixed path. The floor is listed
# separately because it lands at a different place in the fixture.
REAL_FLOOR="authoring/VECTOR-FLOOR.md"
REAL_RECORDS=(
  "pilot"
  "authoring/custody"
  "authoring/qsl"
  "authoring/buyclub"
  "authoring/seedlib"
  "authoring/consign"
)

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

SCRIPT_PRESENT=0
[ -f "$SCRIPT" ] && SCRIPT_PRESENT=1

TMPROOT=$(mktemp -d -t tla_sequence.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

ERRFILE="$TMPROOT/stderr.txt"
FIX1="$TMPROOT/real"
FIX2="$TMPROOT/synthetic"
ORDERS="$TMPROOT/orders"
mkdir -p "$ORDERS"

# ---------------------------------------------------------------------------
# Small helpers.
# ---------------------------------------------------------------------------

TRIMMED=""

# trim <string> -> TRIMMED
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  TRIMMED="$s"
}

RUN_OUT=""
RUN_ERR=""
RUN_RC=0

# run_seq <vector-root> [args...]
#
# VECTOR_ROOT is set on every run, so a script that ignored it and read the
# real tree would answer the wrong question and fail loudly rather than pass
# by luck.
run_seq() {
  local root="$1"
  shift
  RUN_OUT=$(VECTOR_ROOT="$root" bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# says <regex> <body>
#
# Here-string, never a pipe. `producer | grep -q` returns 141 under pipefail
# and reports a present pattern as absent (bead tla-kr9).
says() {
  grep -qE -- "$1" <<<"$2"
}

# one_line <text>
one_line() {
  tr '\n' ' ' <<<"$1"
}

# ---------------------------------------------------------------------------
# The synthetic record table.
#
# One source of truth. The fixture writer reads it, and so does the
# independent order check, so the two cannot drift apart.
#
# Fields: name|rep|kind|count|sources|space|form|situation|shape|gate
# ---------------------------------------------------------------------------

SYNTH_FLOOR_SPEC="floor|0|0|0|0|0|0|floor|floor|ch11"
SYNTH_RECORDS=(
  "alpha|0|1|1|0|0|0|S3|A|ch11"
  "beta|1|1|1|1|1|0|S2|A|ch11"
  "delta|1|1|1|1|1|1|S3|B|refinement"
  "epsilon|1|1|0|0|0|0|S2|B|ch11"
  "gamma|1|0|0|0|0|0|S1|A|ch11"
  "iota|1|1|1|1|1|1|S2|C|ch11"
  "mu|1|1|0|0|0|0|S2|B|ch11"
  "nu|0|2|0|0|0|0|S3|D|ch11"
  "theta|1|2|1|1|1|1|S1|A|ch11"
  "zeta|1|1|1|1|0|0|S1|B|ch13"
)

REC_LEVELS=()
REC_SITU=""
REC_SHAPE=""
REC_GATE=""

# synth_lookup <name>
#
# Returns 1 for a name the table does not carry, which is how the independent
# check catches an order line naming a record that does not exist.
synth_lookup() {
  local want="$1" spec
  local -a f=()
  for spec in "${SYNTH_RECORDS[@]}"; do
    IFS='|' read -r -a f <<<"$spec"
    if [ "${f[0]}" = "$want" ]; then
      REC_LEVELS=("${f[1]}" "${f[2]}" "${f[3]}" "${f[4]}" "${f[5]}" "${f[6]}")
      REC_SITU="${f[7]}"
      REC_SHAPE="${f[8]}"
      REC_GATE="${f[9]}"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# Fixture writers.
# ---------------------------------------------------------------------------

# write_synth_record <path> <spec>
#
# The record shape harness/test-vector.sh validates: a level-1 heading, the
# six rows in order with a level and a citation each, then the three key
# lines after the table.
write_synth_record() {
  local path="$1" spec="$2" i
  local -a f=()
  IFS='|' read -r -a f <<<"$spec"
  {
    printf '# Vector record: %s\n' "${f[0]}"
    printf '\n'
    printf 'Written by harness/test-sequence.sh as a fixture. Not a real package.\n'
    printf '\n'
    printf '| dimension | level | citation |\n'
    printf '|---|---|---|\n'
    for i in 0 1 2 3 4 5; do
      printf '| %s | %s | synthetic fixture |\n' "${DIMENSIONS[$i]}" "${f[$((i + 1))]}"
    done
    printf '\n'
    printf 'situation: %s\n' "${f[7]}"
    printf 'task shape: %s\n' "${f[8]}"
    printf 'reading gate: %s\n' "${f[9]}"
  } >"$path"
}

# write_freeze <path>
write_freeze() {
  printf '%s  Spec.tla\n' \
    "0000000000000000000000000000000000000000000000000000000000000000" >"$1"
}

# ---------------------------------------------------------------------------
# Fixture 1: the real seven, by fixed path.
# ---------------------------------------------------------------------------

FIX1_OK=1

mkdir -p "$FIX1/authoring"
if [ -f "$REAL_FLOOR" ]; then
  cp "$REAL_FLOOR" "$FIX1/authoring/VECTOR-FLOOR.md"
else
  FIX1_OK=0
fi

for rel in "${REAL_RECORDS[@]}"; do
  name=$(basename "$rel")
  if [ -f "$rel/VECTOR.md" ]; then
    if [ "$rel" = "pilot" ]; then
      mkdir -p "$FIX1/pilot/reference"
      cp "$rel/VECTOR.md" "$FIX1/pilot/VECTOR.md"
      write_freeze "$FIX1/pilot/reference/FREEZE.sha256"
    else
      mkdir -p "$FIX1/authoring/$name/reference"
      cp "$rel/VECTOR.md" "$FIX1/authoring/$name/VECTOR.md"
      write_freeze "$FIX1/authoring/$name/reference/FREEZE.sha256"
    fi
  else
    FIX1_OK=0
  fi
done

# ---------------------------------------------------------------------------
# Fixture 2: the synthetic ramp.
# ---------------------------------------------------------------------------

mkdir -p "$FIX2/authoring"
write_synth_record "$FIX2/authoring/VECTOR-FLOOR.md" "$SYNTH_FLOOR_SPEC"

for spec in "${SYNTH_RECORDS[@]}"; do
  sname="${spec%%|*}"
  mkdir -p "$FIX2/authoring/$sname/reference"
  write_synth_record "$FIX2/authoring/$sname/VECTOR.md" "$spec"
  write_freeze "$FIX2/authoring/$sname/reference/FREEZE.sha256"
done

SYNTH_COUNT=${#SYNTH_RECORDS[@]}

# ---------------------------------------------------------------------------
# The independent order check.
#
# Recomputes the running maximum from the floor and applies the four clauses.
# It never calls the script under test, so it can judge the script's output.
# ---------------------------------------------------------------------------

ORDER_LINES=()

# extract_order <text> -> ORDER_LINES
#
# The ORDER runs until the first info: line. Blank lines and # comments are
# dropped, which is the format's own rule.
extract_order() {
  local text="$1" line
  ORDER_LINES=()
  while IFS= read -r line; do
    trim "$line"
    line="$TRIMMED"
    case "$line" in
    "") continue ;;
    "#"*) continue ;;
    info:*) break ;;
    esac
    ORDER_LINES+=("$line")
  done <<<"$text"
  return 0
}

VERIFY_WHY=""

# verify_order
#
# Reads ORDER_LINES and applies (a), (b), (b') and (c). Returns 1 with
# VERIFY_WHY set on the first breach.
verify_order() {
  local -a maxlv=(0 0 0 0 0 0)
  local -a floor_f=()
  local prev_name="floor" prev_situ="" prev_shape=""
  local seen_ch13=0 seen_ref=0 pos=0
  local entry i lvl rises rise_names

  IFS='|' read -r -a floor_f <<<"$SYNTH_FLOOR_SPEC"
  for i in 0 1 2 3 4 5; do
    maxlv[i]="${floor_f[$((i + 1))]}"
  done
  prev_situ="${floor_f[7]}"
  prev_shape="${floor_f[8]}"

  VERIFY_WHY=""

  if [ "${#ORDER_LINES[@]}" -eq 0 ]; then
    VERIFY_WHY="the order is empty"
    return 1
  fi

  for entry in "${ORDER_LINES[@]}"; do
    if [ "$entry" = "checkpoint: ch13" ]; then
      seen_ch13=1
      continue
    fi
    if [ "$entry" = "checkpoint: refinement" ]; then
      seen_ref=1
      continue
    fi
    case "$entry" in
    checkpoint:*)
      VERIFY_WHY="line '$entry' is neither a record name nor one of the two checkpoints"
      return 1
      ;;
    esac

    if ! synth_lookup "$entry"; then
      VERIFY_WHY="line '$entry' names no record in the fixture"
      return 1
    fi
    pos=$((pos + 1))

    # (a)
    if [ "$REC_SITU" = "$prev_situ" ]; then
      VERIFY_WHY="(a) at position $pos: $prev_name -> $entry both sit in situation $REC_SITU"
      return 1
    fi
    if [ "$REC_SHAPE" = "$prev_shape" ]; then
      VERIFY_WHY="(a) at position $pos: $prev_name -> $entry both use task shape $REC_SHAPE"
      return 1
    fi

    # (b) and (b')
    rises=0
    rise_names=""
    for i in 0 1 2 3 4 5; do
      lvl="${REC_LEVELS[$i]}"
      if [ "$lvl" -gt $((${maxlv[$i]} + 1)) ]; then
        VERIFY_WHY="(b) at position $pos ($entry): ${DIMENSIONS[$i]} is $lvl over a running maximum of ${maxlv[$i]}"
        return 1
      fi
      if [ "$lvl" -gt "${maxlv[$i]}" ]; then
        rises=$((rises + 1))
        rise_names="$rise_names ${DIMENSIONS[$i]}"
      fi
    done
    if [ "$rises" -gt 1 ]; then
      VERIFY_WHY="(b') at position $pos ($entry): $rises dimensions rise at once:$rise_names"
      return 1
    fi

    # (c)
    if [ "$REC_GATE" = "ch13" ] && [ "$seen_ch13" -eq 0 ]; then
      VERIFY_WHY="(c) at position $pos ($entry): gated ch13 with no ch13 checkpoint before it"
      return 1
    fi
    if [ "$REC_GATE" = "refinement" ] && [ "$seen_ref" -eq 0 ]; then
      VERIFY_WHY="(c) at position $pos ($entry): gated refinement with no refinement checkpoint before it"
      return 1
    fi

    for i in 0 1 2 3 4 5; do
      if [ "${REC_LEVELS[$i]}" -gt "${maxlv[$i]}" ]; then
        maxlv[i]="${REC_LEVELS[$i]}"
      fi
    done
    prev_name="$entry"
    prev_situ="$REC_SITU"
    prev_shape="$REC_SHAPE"
  done

  return 0
}

# names_in_order -> newline-separated record names, checkpoints dropped
names_in_order() {
  local entry
  for entry in "${ORDER_LINES[@]}"; do
    case "$entry" in
    checkpoint:*) continue ;;
    esac
    printf '%s\n' "$entry"
  done
}

# index_of_entry <entry> -> echoes the 0-based index, or -1
index_of_entry() {
  local want="$1" i
  for i in "${!ORDER_LINES[@]}"; do
    if [ "${ORDER_LINES[$i]}" = "$want" ]; then
      printf '%s' "$i"
      return 0
    fi
  done
  printf '%s' "-1"
}

# ---------------------------------------------------------------------------
# ORDER files.
# ---------------------------------------------------------------------------

# The hand-checked good order. Deliberately NOT the order the search is
# expected to return, so --check is exercised on its own evidence. It carries
# a comment line and a blank line, which the format says to ignore.
{
  printf '# the hand-checked ramp, worked out in this file header\n'
  printf 'gamma\n'
  printf 'epsilon\n'
  printf 'alpha\n'
  printf '\n'
  printf 'checkpoint: ch13\n'
  printf 'zeta\n'
  printf 'beta\n'
  printf 'checkpoint: refinement\n'
  printf 'delta\n'
  printf 'iota\n'
  printf 'theta\n'
  printf 'mu\n'
  printf 'nu\n'
} >"$ORDERS/good.txt"

# The accepting counterparts for the short rejecting orders below.
printf 'gamma\n' >"$ORDERS/good-one.txt"
printf 'gamma\nepsilon\nalpha\n' >"$ORDERS/good-three.txt"

# (a): mu is flat against the running maximum, so situation S2 shared with
# epsilon is the only thing wrong at position 3.
printf 'gamma\nepsilon\nmu\n' >"$ORDERS/break-a.txt"

# (b): nu takes property kind to 2 while the running maximum is 0. One
# dimension rises, so (b') holds and only (b) is broken.
printf 'gamma\nnu\n' >"$ORDERS/break-b.txt"

# (b'): iota raises step sources, state space and form left open together,
# none of them by more than one, so (b) holds and only (b') is broken.
printf 'gamma\nepsilon\nalpha\niota\n' >"$ORDERS/break-bp.txt"

# (c): zeta is legal on every other clause at position 4 and gated ch13.
printf 'gamma\nepsilon\nalpha\nzeta\n' >"$ORDERS/break-c.txt"

# (c) again, with the checkpoint present but late.
printf 'gamma\nepsilon\nalpha\nzeta\ncheckpoint: ch13\n' >"$ORDERS/break-c-late.txt"

# Position 1 against the floor, once for (b) and once for (b').
printf 'nu\n' >"$ORDERS/floor-b.txt"
printf 'epsilon\n' >"$ORDERS/floor-bp.txt"

# An order naming a record the tree does not carry.
printf 'gamma\nnosuchproblem\n' >"$ORDERS/unknown-name.txt"

# ---------------------------------------------------------------------------
# Assertion helpers.
# ---------------------------------------------------------------------------

# assert_check_ok <label> <order-file>
assert_check_ok() {
  local label="$1" file="$2"
  run_seq "$FIX2" --check "$file"
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. rc=$RUN_RC, stdout: $(one_line "$RUN_OUT") stderr: $(one_line "$RUN_ERR")"
  elif says '^FAIL at position' "$RUN_OUT"; then
    nope "$label. Exited 0 but printed a FAIL line: $(one_line "$RUN_OUT")"
  else
    ok "$label"
  fi
}

# assert_check_fails <label> <order-file> <fail-line-regex>
#
# Both halves: exit 1, and the named clause at the named position. Guarded on
# the script existing, because a missing file exits 127 and that says nothing
# about the four clauses.
assert_check_fails() {
  local label="$1" file="$2" want="$3"
  if [ "$SCRIPT_PRESENT" -eq 0 ]; then
    nope "$label. $SCRIPT does not exist, so a non-zero exit proves nothing"
    return
  fi
  run_seq "$FIX2" --check "$file"
  if [ "$RUN_RC" -ne 1 ]; then
    nope "$label. rc=$RUN_RC, wanted 1. stdout: $(one_line "$RUN_OUT") stderr: $(one_line "$RUN_ERR")"
  elif says "$want" "$RUN_OUT"; then
    ok "$label"
  else
    nope "$label. No line matched '$want'. stdout: $(one_line "$RUN_OUT")"
  fi
}

# assert_usage_error <label> [args...]
assert_usage_error() {
  local label="$1"
  shift
  if [ "$SCRIPT_PRESENT" -eq 0 ]; then
    nope "$label. $SCRIPT does not exist, so a non-zero exit proves nothing"
    return
  fi
  run_seq "$FIX2" "$@"
  if [ "$RUN_RC" -eq 2 ]; then
    ok "$label"
  else
    nope "$label. rc=$RUN_RC, wanted 2. stdout: $(one_line "$RUN_OUT") stderr: $(one_line "$RUN_ERR")"
  fi
}

# ---------------------------------------------------------------------------
# PART 1: the real seven have no ramp, and the hole is at position 1.
# ---------------------------------------------------------------------------

echo "== part 1: the withdrawn six against the floor =="

HOLE_LINE='^hole at position 1: no problem within one new high of the floor$'

if [ "$FIX1_OK" -eq 0 ]; then
  nope "the seven real records copy into a fixture root. One or more is missing, so part 1 proves nothing"
  nope "--search over the real seven reports no valid order (fixture incomplete)"
  nope "--search over the real seven names the position-1 hole (fixture incomplete)"
elif [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "--search over the real seven exits 1. $SCRIPT does not exist, so a non-zero exit proves nothing"
  nope "--search over the real seven reports no valid order over 6 problems. $SCRIPT does not exist"
  nope "--search over the real seven names the position-1 hole. $SCRIPT does not exist"
else
  run_seq "$FIX1" --search
  if [ "$RUN_RC" -eq 1 ]; then
    ok "--search over the real seven exits 1"
  else
    nope "--search over the real seven exits $RUN_RC, wanted 1. stdout: $(one_line "$RUN_OUT") stderr: $(one_line "$RUN_ERR")"
  fi

  if says '^no valid order over 6 problems' "$RUN_OUT"; then
    ok "--search over the real seven reports no valid order over 6 problems"
  else
    nope "--search over the real seven printed no 'no valid order over 6 problems' line. stdout: $(one_line "$RUN_OUT")"
  fi

  if says "$HOLE_LINE" "$RUN_OUT"; then
    ok "--search over the real seven names the hole at position 1, exactly as §2.5 predicts"
  else
    nope "--search over the real seven printed no 'hole at position 1: no problem within one new high of the floor' line. stdout: $(one_line "$RUN_OUT")"
  fi
fi

# ---------------------------------------------------------------------------
# PART 2: the synthetic ramp has an order, and the search finds one.
# ---------------------------------------------------------------------------

echo
echo "== part 2: --search over a ramp that has an answer =="

SEARCH_OUT=""
SEARCH_RC=1

run_seq "$FIX2" --search
SEARCH_OUT="$RUN_OUT"
SEARCH_RC="$RUN_RC"

if [ "$SEARCH_RC" -eq 0 ]; then
  ok "--search over the synthetic ramp exits 0"
else
  nope "--search over the synthetic ramp exits $SEARCH_RC, wanted 0. stdout: $(one_line "$SEARCH_OUT") stderr: $(one_line "$RUN_ERR")"
fi

extract_order "$SEARCH_OUT"
SEARCH_ORDER=("${ORDER_LINES[@]+"${ORDER_LINES[@]}"}")

GOT_NAMES=$(names_in_order)
GOT_SORTED=$(sort <<<"$GOT_NAMES")
WANT_SORTED=$(sort <<<"$(printf '%s\n' "${SYNTH_RECORDS[@]%%|*}")")

if [ "$GOT_SORTED" = "$WANT_SORTED" ]; then
  ok "the printed order carries all $SYNTH_COUNT records, each exactly once"
else
  nope "the printed order is not the $SYNTH_COUNT records. Got: $(one_line "$GOT_NAMES")"
fi

if verify_order; then
  ok "every neighbour pair in the printed order satisfies (a), (b), (b') and (c), checked here and not by --check"
else
  nope "the printed order breaks a clause: $VERIFY_WHY"
fi

# The checkpoint placement clause on its own. verify_order already covers it,
# but the bead names it, and a script that emitted checkpoints in the wrong
# place is worth its own line in the output.
CP13=$(index_of_entry "checkpoint: ch13")
ZETA_AT=$(index_of_entry "zeta")
if [ "$CP13" -ge 0 ] && [ "$ZETA_AT" -ge 0 ] && [ "$CP13" -lt "$ZETA_AT" ]; then
  ok "the checkpoint: ch13 line sits before zeta, the one ch13-gated record"
else
  nope "checkpoint: ch13 at index $CP13, zeta at index $ZETA_AT. Wanted the checkpoint first, both present"
fi

CPREF=$(index_of_entry "checkpoint: refinement")
DELTA_AT=$(index_of_entry "delta")
if [ "$CPREF" -ge 0 ] && [ "$DELTA_AT" -ge 0 ] && [ "$CPREF" -lt "$DELTA_AT" ]; then
  ok "the checkpoint: refinement line sits before delta, the one refinement-gated record"
else
  nope "checkpoint: refinement at index $CPREF, delta at index $DELTA_AT. Wanted the checkpoint first, both present"
fi

# --out
OUTFILE="$TMPROOT/order-out.txt"
rm -f "$OUTFILE"
run_seq "$FIX2" --search --out "$OUTFILE"

if [ ! -f "$OUTFILE" ]; then
  nope "--out writes the order to the named file. Nothing was written to $OUTFILE (rc=$RUN_RC)"
elif [ "${#SEARCH_ORDER[@]}" -eq 0 ]; then
  nope "--out writes the same order as stdout. The plain --search run printed no order to compare against"
else
  OUT_TEXT=$(cat "$OUTFILE")
  extract_order "$OUT_TEXT"
  if [ "$(printf '%s\n' "${ORDER_LINES[@]+"${ORDER_LINES[@]}"}")" = "$(printf '%s\n' "${SEARCH_ORDER[@]}")" ]; then
    ok "--out writes the same order the plain --search run printed"
  else
    nope "--out wrote a different order. File: $(one_line "$OUT_TEXT")"
  fi
fi

if [ "$RUN_RC" -eq 0 ] && says '^info: ' "$RUN_OUT"; then
  ok "--out still prints the info: first-appearance lines to stdout"
else
  nope "--out run exited $RUN_RC and printed no info: line on stdout: $(one_line "$RUN_OUT")"
fi

# Determinism. Guarded on the first run having produced something, because two
# empty outputs are byte-identical and prove nothing.
run_seq "$FIX2" --search
SECOND_OUT="$RUN_OUT"
if [ "$SEARCH_RC" -ne 0 ] || [ -z "$SEARCH_OUT" ]; then
  nope "two --search runs agree byte for byte. The first run exited $SEARCH_RC with no output, so agreement proves nothing"
elif [ "$SEARCH_OUT" = "$SECOND_OUT" ]; then
  ok "two --search runs over the same tree agree byte for byte"
else
  nope "two --search runs over the same tree disagreed"
fi

# ---------------------------------------------------------------------------
# PART 3: --check accepts the hand-checked order and reports first appearances.
# ---------------------------------------------------------------------------

echo
echo "== part 3: --check on a good order =="

assert_check_ok "--check accepts the hand-checked order, blank lines and # comments and all" \
  "$ORDERS/good.txt"

run_seq "$FIX2" --check "$ORDERS/good.txt"
GOOD_OUT="$RUN_OUT"

if says '^info: S1 first appears at position 1 \(gamma\)$' "$GOOD_OUT"; then
  ok "--check reports S1 first appearing at position 1 (gamma)"
else
  nope "--check printed no 'info: S1 first appears at position 1 (gamma)' line. stdout: $(one_line "$GOOD_OUT")"
fi

if says '^info: S2 first appears at position 2 \(epsilon\)$' "$GOOD_OUT"; then
  ok "--check reports S2 first appearing at position 2 (epsilon)"
else
  nope "--check printed no 'info: S2 first appears at position 2 (epsilon)' line. stdout: $(one_line "$GOOD_OUT")"
fi

if says '^info: S3 first appears at position 3 \(alpha\)$' "$GOOD_OUT"; then
  ok "--check reports S3 first appearing at position 3 (alpha)"
else
  nope "--check printed no 'info: S3 first appears at position 3 (alpha)' line. stdout: $(one_line "$GOOD_OUT")"
fi

# One line per situation ON ITS FIRST APPEARANCE. S2 comes back four times and
# S1 three, so a script printing one line per problem fails here.
INFO_COUNT=0
while IFS= read -r line; do
  case "$line" in
  info:*) INFO_COUNT=$((INFO_COUNT + 1)) ;;
  esac
done <<<"$GOOD_OUT"

if [ "$INFO_COUNT" -eq 3 ]; then
  ok "--check prints exactly 3 info: lines, one per situation and not one per problem"
else
  nope "--check printed $INFO_COUNT info: lines over an order using 3 situations across 10 problems"
fi

# ---------------------------------------------------------------------------
# PART 4: --check still bites, one clause at a time.
# ---------------------------------------------------------------------------

echo
echo "== part 4: one broken order per clause =="

assert_check_ok "control: the first three entries of the good order are accepted on their own" \
  "$ORDERS/good-three.txt"

assert_check_ok "control: a one-problem order is accepted, so a short order is not rejected on length" \
  "$ORDERS/good-one.txt"

assert_check_fails "control: (a) two neighbours in situation S2 fails at position 3" \
  "$ORDERS/break-a.txt" \
  '^FAIL at position 3: epsilon -> mu violates \(a\)'

assert_check_fails "control: (b) property kind two levels over the running maximum fails at position 2" \
  "$ORDERS/break-b.txt" \
  '^FAIL at position 2: gamma -> nu violates \(b\)'

assert_check_fails "control: (b') three dimensions rising at once fails at position 4" \
  "$ORDERS/break-bp.txt" \
  "^FAIL at position 4: alpha -> iota violates \\(b'\\)"

assert_check_fails "control: (c) a ch13-gated problem with no checkpoint at all fails at position 4" \
  "$ORDERS/break-c.txt" \
  '^FAIL at position 4: alpha -> zeta violates \(c\)'

assert_check_fails "control: (c) a ch13 checkpoint sitting after its problem fails at the same position" \
  "$ORDERS/break-c-late.txt" \
  '^FAIL at position 4: alpha -> zeta violates \(c\)'

# Position 1 names the floor as the previous entry. Both clauses that can
# break there get a control, so a script that hardcoded 'floor' into one
# message and not the other is caught.
assert_check_fails "control: at position 1 the floor is the previous entry, and (b) can break against it" \
  "$ORDERS/floor-b.txt" \
  '^FAIL at position 1: floor -> nu violates \(b\)'

assert_check_fails "control: at position 1 two dimensions rising off the floor breaks (b')" \
  "$ORDERS/floor-bp.txt" \
  "^FAIL at position 1: floor -> epsilon violates \\(b'\\)"

# ---------------------------------------------------------------------------
# PART 5: usage errors.
# ---------------------------------------------------------------------------

echo
echo "== part 5: usage errors =="

assert_usage_error "an ORDER file naming a record the tree does not carry exits 2" \
  --check "$ORDERS/unknown-name.txt"

assert_usage_error "an ORDER file that does not exist exits 2" \
  --check "$TMPROOT/no-such-order.txt"

assert_usage_error "an unknown flag exits 2" --frobnicate

# ---------------------------------------------------------------------------
# PART 6: registration.
# ---------------------------------------------------------------------------

echo
echo "== part 6: structural =="

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-sequence\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif says "$SUITE_ROW" "$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-sequence.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-sequence.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
