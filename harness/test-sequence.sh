#!/usr/bin/env bash
# test-sequence.sh: harness/sequence.sh either orders the ramp or names the
# hole (bead tla-h2cg.3).
#
# THE INVARIANT (decision D4, V2-PLAN.md:355-364, narrowed by D6)
#
#   Over the delivered sequence P_1 .. P_n, with floor F,
#
#     (a)  no two neighbours share a situation or a task shape,
#     (b)  for every dimension d, level_d(P_i) <= 1 + max(level_d(F),
#          level_d(P_1) .. level_d(P_i-1)),
#     (b') at most one dimension d has level_d(P_i) strictly above that
#          running maximum.
#
#   Drops and returns are free. The floor is never an item in the sequence.
#   It is the initial running maximum, and it is the prev-name at position 1.
#
# CLAUSE (c) IS GONE (decision D6, drawer ...20ad6fe9661059e6d830b053)
#
# There used to be a fourth clause: a problem gated ch13 had to sit after a
# `checkpoint: ch13` line, and one gated refinement after `checkpoint:
# refinement`. The reading gate is now a per-problem label naming the learntla
# chapter a problem's constructs come from, and a label orders nothing. So no
# ORDER file carries a `checkpoint:` line and nothing under harness/ parses
# one.
#
# Both halves of that get gated here, because the clause and the placement were
# symmetrical: --search placed the two lines by construction and only --check
# enforced them. Part 2 asserts the search emits no `checkpoint:` line, into
# stdout or into --out. Part 4 asserts a `checkpoint:` line handed to --check is
# now an unknown name, which is a usage error rather than a line with a meaning.
#
# THE RAMP AND THE RESERVE (decision D7)
#
# The record set on disk is not the ramp. Thirteen vector records sit under
# authoring/ and pilot/, and D5 withdrew six of them on 2026-09-04 while
# keeping their records deliberately reachable for a per-rung draw. The ramp is
# the seven the ORDER file names. The other six are the reserve.
#
# So --search takes `--order <path>` and reads it for the ramp's MEMBERSHIP,
# never for its sequence. The search runs over the ramp set and the sequence it
# finds is its own. Judging ORDER's own sequence is --check's job, and keeping
# those two apart is why --search can report a different order from the file it
# read.
#
# This suite now forbids reporting the reserve as a failure of the ramp.
# --search over the real thirteen used to print "no valid order over 13
# problems, hole at position 8" and list all six withdrawn records as
# violations. Central read that as the ramp being wedged and acted on it for a
# day (F1 in the cycle-5 drawer). The ramp was complete at seven and position 8
# had nothing written for it yet.
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
#   harness/sequence.sh --search --order <path> [--out <path>]  over VECTOR_ROOT
#   harness/sequence.sh --check <order-file>                    over VECTOR_ROOT
#
# Records are discovered the way harness/test-vector.sh discovers them: every
# VECTOR.md one level above a reference/FREEZE.sha256 under <root>/authoring
# and <root>/pilot, plus the floor at <root>/authoring/VECTOR-FLOOR.md.
#
# Every --search run below passes --order, for the same reason every run sets
# VECTOR_ROOT: a script that fell back to the delivered ORDER under $HOME would
# answer a question about the learner's tree and pass or fail by luck of the
# host. --check takes no --order, because the file it is handed is the thing it
# judges.
#
# SCENARIO 1, THE WITHDRAWN SIX AS A RAMP, AND THE HAND CHECK BEHIND IT
#
# This fixture declares the six withdrawn records as the ramp, which the live
# tree does not. That is deliberate: it is the only way to drive the
# ramp-has-no-order path off real levels rather than planted ones. On the live
# tree these six are the reserve, which scenario 3 covers.
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
# The files are copied by fixed path, never by scanning. A batch-2 record
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
# The gate column is still written into each fixture record, because that is the
# record shape harness/test-vector.sh validates and this fixture has no business
# inventing a different one. It is no longer an input to any ordering question,
# which is D6.
#
# One order that satisfies the three clauses, worked out by hand:
#
#   gamma, epsilon, alpha, zeta, beta, delta, iota, theta, mu, nu
#
# Each of the first six raises exactly one dimension by exactly one. iota and
# mu and nu sit at or under the running maximum, so they are free. theta takes
# property kind from 1 to 2, which is the one rise it is allowed.
#
# The drop and return is on representation. gamma and epsilon hold it at 1,
# alpha drops it to 0, zeta brings it back to 1. Both moves have to be free, or
# the ramp cannot interleave at all.
#
# This suite does NOT assert that the search prints this order. It asserts that
# whatever order the search prints satisfies the three clauses, recomputed here
# from the same table the fixtures were written from. Verifying the output by
# feeding it back through --check would be circular, and pinning one literal
# order would fail a correct implementation that broke a tie the other way.
#
# SCENARIO 2b, THE SAME TEN WITH A THREE-RUNG RAMP
#
# The same fixture tree, run against an ORDER naming only gamma, epsilon and
# alpha. Ramp of three, reserve of seven. The hand check at position 4, against
# a running maximum of (1,1,1,0,0,0) and alpha (S3, shape A) as the previous
# problem:
#
#   record   why
#   ------   ----------------------------------------------------------------
#   beta     shape A, same as alpha. (a)
#   delta    situation S3, same as alpha. (a)
#   iota     step sources, state space and form left open all rise. (b')
#   mu       flat against the maximum, S2 and shape B. FITS
#   nu       situation S3, same as alpha. (a)
#   theta    shape A, same as alpha. (a)
#   zeta     step sources rises once, S1 and shape B. FITS
#
# So this scenario drives the branch scenario 3 cannot: a reserve record that
# would fit. D5 makes that an offer and not a placement, so the position stays
# unauthored and the run still exits 0.
#
# SCENARIO 3, THE RAMP AND THE RESERVE OVER THE REAL THIRTEEN
#
# The bead's RED scenario, and the one that reproduces F1. All thirteen real
# records plus the floor, copied by fixed path, with an ORDER naming the seven
# the live ~/tla-practice/problems/ORDER names:
#
#   bonded-store, laytime, river-call, assay-office, floor-malting,
#   herbarium-sheet, estate-notice
#
# The other six (buyclub, consign, custody, pilot, qsl, seedlib) are the
# reserve. The run has to report the ramp's found order over the seven, exit 0,
# name position 8 unauthored, and list the six as reserve candidates each with
# the clause it broke at position 8. The string "no valid order" must not
# appear, because the ramp is sound.
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
# WATCH THE PIPEFAIL HAZARD
#
# Every pattern match here goes through says(), which uses a here-string.
# `producer | grep -q` returns 141 under pipefail and reports a present pattern
# as absent, and harness/test-pipefail.sh gates the whole tree against it (bead
# tla-kr9).
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

# The real records the fixtures copy, by fixed path. The floor is listed
# separately because it lands at a different place in the fixture.
REAL_FLOOR="authoring/VECTOR-FLOOR.md"

# The six D5 withdrew on 2026-09-04. Scenario 1 declares them as a ramp, and
# scenario 3 leaves them as the reserve they now are.
RESERVE_RECORDS=(
  "pilot"
  "authoring/custody"
  "authoring/qsl"
  "authoring/buyclub"
  "authoring/seedlib"
  "authoring/consign"
)

# The seven the live ~/tla-practice/problems/ORDER names, in its order. That
# order matters only to the ORDER file scenario 3 writes, since the search is
# free to find its own.
RAMP_RECORDS=(
  "authoring/bonded-store"
  "authoring/laytime"
  "authoring/river-call"
  "authoring/assay-office"
  "authoring/floor-malting"
  "authoring/herbarium-sheet"
  "authoring/estate-notice"
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
FIX3="$TMPROOT/thirteen"
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

# HOME for a run. --search defaults its ORDER path to
# $HOME/tla-practice/problems/ORDER, the way scripts/number-problems.sh and
# scripts/deliver-problems.sh default their problems root, so HOME is an input
# to the script's answer and gets pinned like one.
#
# The default points at an empty tree. A run that forgot --order then fails
# loudly instead of reading the learner's delivered ORDER and passing by luck
# of the host. One assertion in part 5 overrides it to drive the default on
# purpose.
HOME_EMPTY="$TMPROOT/home-empty"
HOME_DELIVERED="$TMPROOT/home-delivered"
SEQ_HOME="$HOME_EMPTY"

mkdir -p "$HOME_EMPTY"

# run_seq <vector-root> [args...]
#
# VECTOR_ROOT and HOME are set on every run, so a script that ignored either
# and read the real tree would answer the wrong question and fail loudly rather
# than pass by luck. The same goes for --order, which every --search call site
# but one passes by name.
run_seq() {
  local root="$1"
  shift
  RUN_OUT=$(VECTOR_ROOT="$root" HOME="$SEQ_HOME" bash "$SCRIPT" "$@" 2>"$ERRFILE")
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

# synth_lookup <name>
#
# Returns 1 for a name the table does not carry, which is how the independent
# check catches an order line naming a record that does not exist. The gate
# column is not returned, because nothing orders on it any more.
synth_lookup() {
  local want="$1" spec
  local -a f=()
  for spec in "${SYNTH_RECORDS[@]}"; do
    IFS='|' read -r -a f <<<"$spec"
    if [ "${f[0]}" = "$want" ]; then
      REC_LEVELS=("${f[1]}" "${f[2]}" "${f[3]}" "${f[4]}" "${f[5]}" "${f[6]}")
      REC_SITU="${f[7]}"
      REC_SHAPE="${f[8]}"
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

# copy_real_record <fixture-root> <repo-relative-record-dir>
#
# Returns 1 when the record is not there, so the caller can mark its whole
# scenario unproven rather than quietly testing a smaller tree. pilot is the
# one record that does not live under authoring/.
copy_real_record() {
  local fix="$1" rel="$2" rname
  rname=$(basename "$rel")
  [ -f "$rel/VECTOR.md" ] || return 1
  if [ "$rel" = "pilot" ]; then
    mkdir -p "$fix/pilot/reference"
    cp "$rel/VECTOR.md" "$fix/pilot/VECTOR.md"
    write_freeze "$fix/pilot/reference/FREEZE.sha256"
  else
    mkdir -p "$fix/authoring/$rname/reference"
    cp "$rel/VECTOR.md" "$fix/authoring/$rname/VECTOR.md"
    write_freeze "$fix/authoring/$rname/reference/FREEZE.sha256"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Fixture 1: the withdrawn six, by fixed path, declared as a ramp.
# ---------------------------------------------------------------------------

FIX1_OK=1

mkdir -p "$FIX1/authoring"
if [ -f "$REAL_FLOOR" ]; then
  cp "$REAL_FLOOR" "$FIX1/authoring/VECTOR-FLOOR.md"
else
  FIX1_OK=0
fi

for rel in "${RESERVE_RECORDS[@]}"; do
  copy_real_record "$FIX1" "$rel" || FIX1_OK=0
done

# ---------------------------------------------------------------------------
# Fixture 3: all thirteen real records, the ramp's seven and the reserve's six.
# ---------------------------------------------------------------------------

FIX3_OK=1

mkdir -p "$FIX3/authoring"
if [ -f "$REAL_FLOOR" ]; then
  cp "$REAL_FLOOR" "$FIX3/authoring/VECTOR-FLOOR.md"
else
  FIX3_OK=0
fi

for rel in "${RAMP_RECORDS[@]}" "${RESERVE_RECORDS[@]}"; do
  copy_real_record "$FIX3" "$rel" || FIX3_OK=0
done

RAMP_NAMES=()
for rel in "${RAMP_RECORDS[@]}"; do
  RAMP_NAMES+=("$(basename "$rel")")
done

RESERVE_NAMES=()
for rel in "${RESERVE_RECORDS[@]}"; do
  RESERVE_NAMES+=("$(basename "$rel")")
done

printf '%s\n' "${RAMP_NAMES[@]}" >"$ORDERS/real-ramp.txt"
printf '%s\n' "${RESERVE_NAMES[@]}" >"$ORDERS/real-reserve-as-ramp.txt"

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

# The ten as a ramp with nothing left over, and the same ten with a three-rung
# ramp and a seven-record reserve.
printf '%s\n' "${SYNTH_RECORDS[@]%%|*}" >"$ORDERS/synth-all.txt"
printf 'gamma\nepsilon\nalpha\n' >"$ORDERS/synth-three.txt"

# A home tree holding a delivered ORDER where --search looks for one by
# default. Same ten names, so a bare run over FIX2 has to agree with the
# explicit one.
mkdir -p "$HOME_DELIVERED/tla-practice/problems"
cp "$ORDERS/synth-all.txt" "$HOME_DELIVERED/tla-practice/problems/ORDER"

# ---------------------------------------------------------------------------
# The independent order check.
#
# Recomputes the running maximum from the floor and applies the three clauses.
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
# Reads ORDER_LINES and applies (a), (b) and (b'). Returns 1 with VERIFY_WHY
# set on the first breach. A `checkpoint:` line is a breach in itself now:
# D6 took the two markers out, so an order carrying one is an order the script
# should never have emitted.
verify_order() {
  local -a maxlv=(0 0 0 0 0 0)
  local -a floor_f=()
  local prev_name="floor" prev_situ="" prev_shape=""
  local pos=0
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
    case "$entry" in
    checkpoint:*)
      VERIFY_WHY="line '$entry' is a checkpoint marker, which D6 removed"
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
  printf 'zeta\n'
  printf 'beta\n'
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

# zeta is gated ch13 and sits at position 4 with no checkpoint anywhere. Under
# the old clause (c) this was a FAIL. It is now an accepted order, and that is
# the clearest single statement that the clause is gone.
printf 'gamma\nepsilon\nalpha\nzeta\n' >"$ORDERS/was-break-c.txt"

# A checkpoint marker is no longer a line with a meaning, so it is a name the
# tree does not carry. That is the "nothing under harness/ parses one" half of
# D6's invariant.
printf 'gamma\ncheckpoint: ch13\n' >"$ORDERS/has-checkpoint.txt"

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
  nope "the six withdrawn records copy into a fixture root. One or more is missing, so part 1 proves nothing"
  nope "--search over the withdrawn six reports no valid order (fixture incomplete)"
  nope "--search over the withdrawn six names the position-1 hole (fixture incomplete)"
elif [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "--search over the withdrawn six exits 1. $SCRIPT does not exist, so a non-zero exit proves nothing"
  nope "--search over the withdrawn six reports no valid order over a 6-rung ramp. $SCRIPT does not exist"
  nope "--search over the withdrawn six names the position-1 hole. $SCRIPT does not exist"
else
  run_seq "$FIX1" --search --order "$ORDERS/real-reserve-as-ramp.txt"
  if [ "$RUN_RC" -eq 1 ]; then
    ok "--search over the withdrawn six exits 1"
  else
    nope "--search over the withdrawn six exits $RUN_RC, wanted 1. stdout: $(one_line "$RUN_OUT") stderr: $(one_line "$RUN_ERR")"
  fi

  if says '^no valid order over the 6-rung ramp$' "$RUN_OUT"; then
    ok "--search over the withdrawn six reports no valid order over the 6-rung ramp"
  else
    nope "--search over the withdrawn six printed no 'no valid order over the 6-rung ramp' line. stdout: $(one_line "$RUN_OUT")"
  fi

  if says "$HOLE_LINE" "$RUN_OUT"; then
    ok "--search over the withdrawn six names the hole at position 1, exactly as §2.5 predicts"
  else
    nope "--search over the withdrawn six printed no 'hole at position 1: no problem within one new high of the floor' line. stdout: $(one_line "$RUN_OUT")"
  fi
fi

# ---------------------------------------------------------------------------
# PART 2: the synthetic ramp has an order, and the search finds one.
# ---------------------------------------------------------------------------

echo
echo "== part 2: --search over a ramp that has an answer =="

SEARCH_OUT=""
SEARCH_RC=1

run_seq "$FIX2" --search --order "$ORDERS/synth-all.txt"
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
  ok "every neighbour pair in the printed order satisfies (a), (b) and (b'), checked here and not by --check"
else
  nope "the printed order breaks a clause: $VERIFY_WHY"
fi

# D6, the placement half. zeta is gated ch13 and delta refinement, so the old
# script emitted a marker before each of them. Both records are in this order,
# which is what makes the absence evidence rather than vacuity.
if [ "$SEARCH_RC" -ne 0 ] || [ -z "$SEARCH_OUT" ]; then
  nope "the search emits no checkpoint: line. The run exited $SEARCH_RC with no output, so its absence proves nothing"
elif says '^checkpoint:' "$SEARCH_OUT"; then
  nope "the search still emits a checkpoint: line, which D6 removed. stdout: $(one_line "$SEARCH_OUT")"
else
  ok "the search emits no checkpoint: line, over a ramp holding both a ch13-gated and a refinement-gated record"
fi

# Nothing is left over, so there is no reserve to report on.
if [ "$SEARCH_RC" -ne 0 ] || [ -z "$SEARCH_OUT" ]; then
  nope "an ORDER naming every record leaves no reserve. The run exited $SEARCH_RC with no output, so its absence proves nothing"
elif says '^reserve:' "$SEARCH_OUT"; then
  nope "the search reported a reserve over an ORDER naming all $SYNTH_COUNT records. stdout: $(one_line "$SEARCH_OUT")"
else
  ok "an ORDER naming every record leaves no reserve, and the report says nothing about one"
fi

if says "^info: position $((SYNTH_COUNT + 1)) is unauthored" "$SEARCH_OUT"; then
  ok "the search names position $((SYNTH_COUNT + 1)) as unauthored once the ramp is placed"
else
  nope "the search named no unauthored position after a $SYNTH_COUNT-rung ramp. stdout: $(one_line "$SEARCH_OUT")"
fi

# --out
OUTFILE="$TMPROOT/order-out.txt"
rm -f "$OUTFILE"
run_seq "$FIX2" --search --order "$ORDERS/synth-all.txt" --out "$OUTFILE"

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

# The written file is the one D6's invariant is about: "No ORDER file contains
# a line matching ^checkpoint:". Checked against the file, not against stdout,
# because the file is what a later --check and scripts/number-problems.sh read.
if [ ! -f "$OUTFILE" ]; then
  nope "the ORDER file --out writes carries no checkpoint: line. Nothing was written to $OUTFILE"
elif says '^checkpoint:' "$(cat "$OUTFILE")"; then
  nope "the ORDER file --out wrote carries a checkpoint: line: $(one_line "$(cat "$OUTFILE")")"
else
  ok "the ORDER file --out writes carries no checkpoint: line"
fi

if [ "$RUN_RC" -eq 0 ] && says '^info: ' "$RUN_OUT"; then
  ok "--out still prints the info: first-appearance lines to stdout"
else
  nope "--out run exited $RUN_RC and printed no info: line on stdout: $(one_line "$RUN_OUT")"
fi

# Determinism. Guarded on the first run having produced something, because two
# empty outputs are byte-identical and prove nothing.
run_seq "$FIX2" --search --order "$ORDERS/synth-all.txt"
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

# D6, the enforcement half. This exact order was a (c) FAIL until 2026-10-08.
assert_check_ok "clause (c) is gone: a ch13-gated problem with no checkpoint anywhere is accepted" \
  "$ORDERS/was-break-c.txt"

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
# PART 5: the ramp and the reserve are reported as different things (D7).
# ---------------------------------------------------------------------------

echo
echo "== part 5: a sound ramp with a reserve left over =="

# Scenario 2b. Three rungs, seven in reserve, two of them placeable.
run_seq "$FIX2" --search --order "$ORDERS/synth-three.txt"
SUB_OUT="$RUN_OUT"
SUB_RC="$RUN_RC"

if [ "$SUB_RC" -eq 0 ]; then
  ok "a three-rung ramp with seven records in reserve exits 0"
else
  nope "a three-rung ramp exits $SUB_RC, wanted 0. stdout: $(one_line "$SUB_OUT") stderr: $(one_line "$RUN_ERR")"
fi

extract_order "$SUB_OUT"
SUB_NAMES=$(names_in_order)
if [ "$SUB_NAMES" = "$(printf 'gamma\nepsilon\nalpha')" ]; then
  ok "the printed order is the three rungs ORDER names, and none of the seven reserve records"
else
  nope "the printed order is not the three ORDER-named rungs. Got: $(one_line "$SUB_NAMES")"
fi

if says '^info: position 4 is unauthored' "$SUB_OUT"; then
  ok "position 4 is named as unauthored rather than as a hole"
else
  nope "no 'info: position 4 is unauthored' line. stdout: $(one_line "$SUB_OUT")"
fi

if says '^reserve: 7 of 10 records off the ramp\. 2 placeable at position 4' "$SUB_OUT"; then
  ok "the reserve heading counts 7 off the ramp and 2 placeable at position 4"
else
  nope "no reserve heading counting 7 off the ramp and 2 placeable. stdout: $(one_line "$SUB_OUT")"
fi

for want in mu zeta; do
  if says "^  $want: fits at position 4\$" "$SUB_OUT"; then
    ok "$want is reported as a reserve record that fits at position 4"
  else
    nope "$want is not reported as fitting at position 4. stdout: $(one_line "$SUB_OUT")"
  fi
done

if says "^  iota: breaks \\(b'\\) at position 4: " "$SUB_OUT"; then
  ok "iota is reported as a reserve record breaking (b') at position 4"
else
  nope "iota is not reported as breaking (b') at position 4. stdout: $(one_line "$SUB_OUT")"
fi

if says '^  beta: breaks \(a\) at position 4: ' "$SUB_OUT"; then
  ok "beta is reported as a reserve record breaking (a) at position 4"
else
  nope "beta is not reported as breaking (a) at position 4. stdout: $(one_line "$SUB_OUT")"
fi

echo
echo "== part 5b: the real thirteen, seven on the ramp and six in reserve =="

# Scenario 3, the bead's RED. This is F1 reproduced: the run used to print
# "no valid order over 13 problems, hole at position 8" and name all six
# withdrawn records as violations.
RESERVE_HEAD='^reserve: 6 of 13 records off the ramp\. None is placeable at position 8'

if [ "$FIX3_OK" -eq 0 ]; then
  nope "all thirteen real records copy into a fixture root. One or more is missing, so part 5b proves nothing"
elif [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "--search over the real thirteen. $SCRIPT does not exist, so nothing below proves anything"
else
  R13_OUTFILE="$TMPROOT/real-order-out.txt"
  rm -f "$R13_OUTFILE"
  run_seq "$FIX3" --search --order "$ORDERS/real-ramp.txt" --out "$R13_OUTFILE"
  R13_OUT="$RUN_OUT"
  R13_RC="$RUN_RC"

  if [ "$R13_RC" -eq 0 ]; then
    ok "--search over the real thirteen exits 0, because the ramp itself is sound"
  else
    nope "--search over the real thirteen exits $R13_RC, wanted 0. stdout: $(one_line "$R13_OUT") stderr: $(one_line "$RUN_ERR")"
  fi

  # The string that carried the wrong conclusion for a day. Guarded on the run
  # having said anything at all, because empty output contains no string.
  if [ "$R13_RC" -ne 0 ] || [ -z "$R13_OUT" ]; then
    nope "'no valid order' does not appear while the ramp is sound. The run exited $R13_RC with no output, so its absence proves nothing"
  elif says 'no valid order' "$R13_OUT"; then
    nope "--search over the real thirteen still says 'no valid order' while the ramp is sound. stdout: $(one_line "$R13_OUT")"
  else
    ok "'no valid order' does not appear while the ramp is sound"
  fi

  if [ ! -f "$R13_OUTFILE" ]; then
    nope "the found order over the seven rungs is written to --out. Nothing was written"
  else
    R13_ORDER=$(cat "$R13_OUTFILE")
    R13_SORTED=$(sort <<<"$R13_ORDER")
    RAMP_SORTED_WANT=$(sort <<<"$(printf '%s\n' "${RAMP_NAMES[@]}")")
    if [ "$R13_SORTED" = "$RAMP_SORTED_WANT" ]; then
      ok "the found order is the seven ORDER-named rungs, each exactly once, and no reserve record"
    else
      nope "the found order is not the seven ORDER-named rungs. Got: $(one_line "$R13_ORDER")"
    fi

    if says '^checkpoint:' "$R13_ORDER"; then
      nope "the ORDER file written over the real thirteen carries a checkpoint: line"
    else
      ok "the ORDER file written over the real thirteen carries no checkpoint: line"
    fi
  fi

  if says '^info: position 8 is unauthored' "$R13_OUT"; then
    ok "position 8 is named as unauthored, which is the honest statement of the ramp's state"
  else
    nope "no 'info: position 8 is unauthored' line. stdout: $(one_line "$R13_OUT")"
  fi

  if says "$RESERVE_HEAD" "$R13_OUT"; then
    ok "the reserve heading counts 6 of 13 off the ramp with none placeable at position 8"
  else
    nope "no reserve heading counting 6 of 13 off the ramp. stdout: $(one_line "$R13_OUT")"
  fi

  # Each withdrawn record, by name, under the reserve heading and with a
  # clause. A heading alone would let the six vanish from the report, and
  # D5 keeps them reachable on purpose.
  R13_LISTED=0
  for want in "${RESERVE_NAMES[@]}"; do
    if says "^  $want: breaks \\((a|b|b')\\) at position 8: ." "$R13_OUT"; then
      R13_LISTED=$((R13_LISTED + 1))
    fi
  done
  if [ "$R13_LISTED" -eq "${#RESERVE_NAMES[@]}" ]; then
    ok "all ${#RESERVE_NAMES[@]} withdrawn records are listed as reserve candidates, each with the clause it broke at position 8"
  else
    nope "$R13_LISTED of ${#RESERVE_NAMES[@]} withdrawn records are listed with a clause at position 8. stdout: $(one_line "$R13_OUT")"
  fi

  # The six must not be reported the old way. 'violates' is the verb the
  # ramp-failure path uses, and a reserve record is not a ramp failure.
  if [ "$R13_RC" -ne 0 ] || [ -z "$R13_OUT" ]; then
    nope "no withdrawn record is reported as a violation of the ramp. The run exited $R13_RC with no output, so their absence proves nothing"
  elif says '^  (buyclub|consign|custody|pilot|qsl|seedlib): violates ' "$R13_OUT"; then
    nope "a withdrawn record is still reported as a ramp violation. stdout: $(one_line "$R13_OUT")"
  else
    ok "no withdrawn record is reported as a violation of the ramp"
  fi
fi

# ---------------------------------------------------------------------------
# PART 6: usage errors.
# ---------------------------------------------------------------------------

echo
echo "== part 6: usage errors =="

assert_usage_error "an ORDER file naming a record the tree does not carry exits 2" \
  --check "$ORDERS/unknown-name.txt"

assert_usage_error "an ORDER file that does not exist exits 2" \
  --check "$TMPROOT/no-such-order.txt"

assert_usage_error "an unknown flag exits 2" --frobnicate

# D6 again. A checkpoint marker used to be one of two lines --check gave a
# meaning to. Nothing parses one now, so it falls through to the name
# resolution that every other unrecognised entry hits.
assert_usage_error "a checkpoint: line in an order file is an unknown name, so it exits 2" \
  --check "$ORDERS/has-checkpoint.txt"

assert_usage_error "--search with no --order and no delivered ORDER exits 2 rather than guessing the ramp" \
  --search

assert_usage_error "--order naming a file that does not exist exits 2" \
  --search --order "$TMPROOT/no-such-ramp.txt"

assert_usage_error "--order without --search exits 2" \
  --check "$ORDERS/good.txt" --order "$ORDERS/synth-all.txt"

# The accepting counterpart. Without it the two refusals above are consistent
# with a script that refuses every --search.
SEQ_HOME="$HOME_DELIVERED"
run_seq "$FIX2" --search
SEQ_HOME="$HOME_EMPTY"

if [ "$RUN_RC" -ne 0 ]; then
  nope "--search with no --order reads \$HOME/tla-practice/problems/ORDER. rc=$RUN_RC, stderr: $(one_line "$RUN_ERR")"
elif says "$ORDERS/synth-all.txt" "$RUN_OUT"; then
  nope "--search with no --order read the explicit path rather than the delivered one. stdout: $(one_line "$RUN_OUT")"
elif says 'tla-practice/problems/ORDER' "$RUN_OUT"; then
  ok "--search with no --order reads \$HOME/tla-practice/problems/ORDER and says which file it read"
else
  nope "--search with no --order exited 0 but named no ORDER file. stdout: $(one_line "$RUN_OUT")"
fi

# ---------------------------------------------------------------------------
# PART 7: registration.
# ---------------------------------------------------------------------------

echo
echo "== part 7: structural =="

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
