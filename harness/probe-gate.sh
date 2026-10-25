#!/usr/bin/env bash
# probe-gate.sh: the gate on the transfer probe (bead tla-9bnj).
#
# WHAT IT IS FOR
#
# The probe measures whether Frank's drill practice reaches work outside the
# drill distribution. That measurement is worth nothing if a probe item cannot
# be passed, because his result would then read as his failure when it was the
# harness's. That is a false signal in the direction most likely to mislead,
# so it is worse than shipping no probe at all.
#
# So this suite asserts, per item, that a correct solution still grades
# REFINES, that a wrong one still grades REFINEMENT_VIOLATED, and that the
# frozen-mapping trapdoor is still shut on this probe's own material rather
# than only on harness/fixtures/refinement.
#
# IT ALSO GUARDS THE MODALITY GAP, which is the part most likely to rot.
# A drill item publishes the distinct-state count its answer reaches, and no
# real engagement does that. It is the single biggest format gap between the
# drills and real work, so a probe brief that grew a state count would quietly
# turn the probe back into a drill. There is an assertion for that.
#
# EVERY EXPECTATION LIVES IN THE FILENAME, so nothing in verify/ is silently
# unchecked:
#
#   the module GRADE.conf names   expect REFINES             (0)
#   Wrong*.tla                    expect REFINEMENT_VIOLATED (22)
#   Frozen*.tla                   expect FROZEN_MAPPING      (20)
#   anything else                 FAIL, as an unclaimed expectation
#
# A new verify/ module therefore arrives either with an expectation or as a
# red run that names itself. That is the shape harness/test-deliver-drill.sh
# uses for its fifth directory entry and it is the right one.
#
# ---------------------------------------------------------------------------
# THE ONE THING THIS GATE CANNOT ALWAYS CHECK, AND IT SAYS SO EVERY RUN
#
# The requirement modules are fetched rather than committed (bead tla-16je,
# ruled by tla-9bnj), so on a tree where nobody has run
# probe/scripts/fetch-oracles.sh there is nothing to grade against. Every
# grading assertion then has to stand down.
#
# That is a real hole and the run prints it rather than passing quietly. Three
# gates in this project were found green while reading none of the tree they
# were supposed to read, and all three looked exactly like a clean run. So an
# oracle-less run prints NOT CHECKED with the fetch command in it, and
# --require-oracles turns the same condition into a failure for a caller that
# can guarantee the fetch has happened.
#
# CI has no fetch, so CI gets the structural half. Frank's box has the fetch,
# so the box the measurement runs on gets both halves. I think that is the
# right split, and it is the same call Frank made on bead tla-mjvx when he
# kept scripts/verify-delivery.sh out of cibuild for want of a delivered tree.
#
# Usage:  harness/probe-gate.sh [--static] [--require-oracles]
#
#   --static           structural assertions only. Starts no JVM.
#   --require-oracles  a missing requirement module is a failure, not a skip.
#
# Exit: 0 if every assertion holds, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

PROBE_DIR="probe"
REFINEMENT="harness/refinement.sh"
TEST_RUNNER="scripts/test"
FETCH="$PROBE_DIR/scripts/fetch-oracles.sh"
RUNNER="$PROBE_DIR/probe.sh"

# A floor, so a glob that stops matching reddens instead of passing. Bead
# tla-9bnj ships two items. Raise this when a third lands.
MIN_ITEMS=2

STATIC=0
REQUIRE_ORACLES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --static)          STATIC=1; shift ;;
    --require-oracles) REQUIRE_ORACLES=1; shift ;;
    -h|--help)         sed -n '/^# Usage:/,/^# Exit:/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "$0: unknown option: $1" >&2; exit 2 ;;
  esac
done

pass_count=0
fail_count=0
skip_count=0
NOT_CHECKED=()

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
skip() { printf "  SKIP  %s\n" "$1"; skip_count=$((skip_count + 1)); }

# Every assertion below is a plain if/else. The shorter
# `cond && ok "..." || nope "..."` form is SC2015 and shellcheck is right
# about it: the third branch runs when the second one fails, so a printf that
# failed would log a PASS and a FAIL for the same check.

# The published-state-count pattern, and its two controls. A drill prompt ends
# "A correct model finds 12 distinct states and reports no error", and that
# sentence is what must never appear in a probe brief.
COUNT_PATTERN='[0-9]+([[:space:]]+[a-z]+){0,2}[[:space:]]+states?[[:space:]>.,]'

echo "== controls =="

if grep -qiE -- "$COUNT_PATTERN" <<<"A correct model finds 12 distinct states and reports no error."; then
  ok "control: the state-count pattern catches a drill prompt's closing sentence"
else
  nope "control: the state-count pattern does NOT catch a drill prompt's closing sentence, so every brief below passes it for free"
fi

if grep -qiE -- "$COUNT_PATTERN" <<<"There is no state count to match, and no construct list."; then
  nope "control: the state-count pattern reddens on a brief SAYING there is no count, which is a false positive"
else
  ok "control: the state-count pattern leaves a brief saying there is no count alone"
fi

echo
echo "== structure =="

if [ -f "$RUNNER" ] && [ -x "$RUNNER" ]; then
  ok "$RUNNER is present and executable"
else
  nope "$RUNNER is missing or not executable"
fi

if [ -f "$FETCH" ] && [ -x "$FETCH" ]; then
  ok "$FETCH is present and executable"
else
  nope "$FETCH is missing or not executable"
fi

if [ -x "$REFINEMENT" ]; then
  ok "$REFINEMENT is present and executable"
else
  nope "$REFINEMENT is missing, so nothing here can be graded"
fi

mapfile -t ITEMS < <(
  for d in "$PROBE_DIR"/*/; do
    [ -f "$d/BRIEF.md" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
)

if [ "${#ITEMS[@]}" -ge "$MIN_ITEMS" ]; then
  ok "probe/ carries ${#ITEMS[@]} items, at or above the floor of $MIN_ITEMS"
else
  nope "probe/ carries ${#ITEMS[@]} items, below the floor of $MIN_ITEMS. A glob that stopped matching looks exactly like this."
fi

# ---------------------------------------------------------------------------
# Per-item structure.
# ---------------------------------------------------------------------------

# Parsed the same way probe.sh parses it, and for the same reason: a delivered
# file that gets sourced is a delivered file that can run anything.
read_conf() {   # read_conf <item>
  local conf="$PROBE_DIR/$1/GRADE.conf" line
  C_MODULE=""; C_REFINES="Refines"; C_ABSTRACT_INIT=""; C_CONSTANTS=""; C_TIMEOUT="120"; C_ORACLE=""
  [ -f "$conf" ] || return 1
  while IFS= read -r line; do
    case "$line" in
      \#*|'')          continue ;;
      MODULE=*)        C_MODULE="${line#MODULE=}" ;;
      REFINES=*)       C_REFINES="${line#REFINES=}" ;;
      ABSTRACT_INIT=*) C_ABSTRACT_INIT="${line#ABSTRACT_INIT=}" ;;
      CONSTANTS=*)     C_CONSTANTS="${line#CONSTANTS=}" ;;
      TIMEOUT=*)       C_TIMEOUT="${line#TIMEOUT=}" ;;
      ORACLE=*)        C_ORACLE="${line#ORACLE=}" ;;
      *) return 2 ;;
    esac
  done < "$conf"
  [ -n "$C_MODULE" ] && [ -n "$C_ORACLE" ]
}

for item in "${ITEMS[@]}"; do
  echo
  echo "== $item =="
  d="$PROBE_DIR/$item"

  words=$(wc -w < "$d/BRIEF.md")
  if [ "$words" -ge 600 ]; then
    ok "$item brief is $words words, at or above the 600 the modality gap needs"
  else
    nope "$item brief is $words words. Under 600 it is a long drill prompt rather than a probe."
  fi

  # THE MODALITY ASSERTION. A published state count is what a drill item has
  # and real work never has.
  #
  # It matches a NUMERAL next to the word, not the word on its own. A brief
  # saying there is no state count to match has to pass, and the first version
  # of this check reddened on exactly that sentence. The control below is what
  # keeps the narrowing honest.
  if grep -qiE -- "$COUNT_PATTERN" "$d/BRIEF.md"; then
    nope "$item brief publishes a state count. That is the drill format leaking back in."
  else
    ok "$item brief publishes no state count"
  fi

  if grep -qE 'There is no construct list' "$d/BRIEF.md"; then
    ok "$item brief says out loud that there is no construct list"
  else
    nope "$item brief does not say there is no construct list"
  fi

  # The capture surfaces. Both are recorded as a side effect of a command the
  # item needs anyway, which is the only reason to expect them to be filled.
  if grep -qE 'probe (grade|decide)' "$d/BRIEF.md"; then
    ok "$item brief names the command that records and grades"
  else
    nope "$item brief does not name the grading command, so he cannot grade himself"
  fi

  if [ -f "$d/META.md" ]; then
    ok "$item carries META.md, withheld from delivery"
  else
    nope "$item carries no META.md"
  fi

  if read_conf "$item"; then
    ok "$item GRADE.conf names a module and an oracle"
  else
    nope "$item GRADE.conf is missing, unparseable, or names no MODULE and ORACLE"
    continue
  fi

  if [ -f "$d/verify/$C_MODULE" ]; then
    ok "$item ships the reference solution at verify/$C_MODULE"
  else
    nope "$item ships no reference solution at verify/$C_MODULE"
  fi

  if [ -n "$C_CONSTANTS" ]; then
    if [ -f "$d/$C_CONSTANTS" ]; then
      ok "$item constants fragment $C_CONSTANTS is there"
    else
      nope "$item GRADE.conf names $C_CONSTANTS and there is no such file"
    fi
  fi

  # THE LICENSING GUARD. The oracle path has to stay ignored, or a later
  # `git add probe/` commits a corpus module nobody decided to redistribute.
  if git check-ignore -q "$d/$C_ORACLE"; then
    ok "$item oracle path $C_ORACLE is gitignored"
  else
    nope "$item oracle path $d/$C_ORACLE is NOT gitignored. Fetched corpus modules must not be committable."
  fi

  if grep -qE "$item" "$FETCH" && grep -qE '[0-9a-f]{64}' "$FETCH"; then
    ok "$item has a row in the fetch script, with a digest beside it"
  else
    nope "$item has no row in $FETCH, or the script records no digest"
  fi

  # Every verify/ module carries its expectation in its name, so a new one
  # arrives either claimed or red.
  mapfile -t MODULES < <(
    for m in "$d"/verify/*.tla; do
      [ -f "$m" ] || continue
      printf '%s\n' "${m##*/}"
    done
  )
  if [ "${#MODULES[@]}" -ge 2 ]; then
    ok "$item verify/ holds ${#MODULES[@]} modules, a reference and at least one wrong one"
  else
    nope "$item verify/ holds ${#MODULES[@]} modules. A reference with nothing to fail against measures nothing."
  fi

  have_wrong=0
  for m in "${MODULES[@]}"; do
    case "$m" in
      "$C_MODULE") ;;
      Wrong*.tla) have_wrong=1 ;;
      Frozen*.tla) ;;
      *) nope "$item verify/$m claims no expectation. Name it Wrong* or Frozen*, or make it the module GRADE.conf names." ;;
    esac
  done
  if [ "$have_wrong" -eq 1 ]; then
    ok "$item verify/ holds a deliberately wrong solution"
  else
    nope "$item verify/ holds no Wrong*.tla, so nothing proves the grader can fail"
  fi
done

# ---------------------------------------------------------------------------
# Registration. Read the SUITES array rather than the whole file, so a mention
# of this suite in a comment cannot stand in for a row that runs it.
# ---------------------------------------------------------------------------

echo
echo "== registration =="

SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"slow[|][^|]*[|][^|]*[|]\./harness/probe-gate\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a slow-tier row for ./harness/probe-gate.sh"
else
  nope "SUITES carries no slow-tier row for ./harness/probe-gate.sh"
fi

# ---------------------------------------------------------------------------
# Grading. The half that decides whether the probe is passable at all.
# ---------------------------------------------------------------------------

echo
echo "== grading =="

grade_one() {   # grade_one <item> <module> <expected-token> <expected-rc>
  local item="$1" module="$2" want_tok="$3" want_rc="$4"
  local d="$PROBE_DIR/$item" stage tok rc
  local args=()

  stage=$(mktemp -d -t probe_gate.XXXXXX) || { nope "$item/$module: cannot make a staging directory"; return; }
  cp "$d"/verify/*.tla "$stage"/ 2>/dev/null
  cp "$d/$C_ORACLE" "$stage"/ || { nope "$item/$module: cannot stage the oracle"; rm -rf "$stage"; return; }

  args=(--refines "$C_REFINES" -t "$C_TIMEOUT")
  [ -n "$C_ABSTRACT_INIT" ] && args+=(--abstract-init "$C_ABSTRACT_INIT")
  [ -n "$C_CONSTANTS" ] && args+=(--constants "$d/$C_CONSTANTS")

  tok=$("$REFINEMENT" "${args[@]}" "$stage/$module" 2>/dev/null); rc=$?
  rm -rf "$stage"

  if [ "$tok" = "$want_tok" ] && [ "$rc" = "$want_rc" ]; then
    ok "$item/$module grades $tok ($rc)"
  else
    nope "$item/$module graded $tok ($rc), expected $want_tok ($want_rc)"
  fi
}

if [ "$STATIC" -eq 1 ]; then
  skip "every grading assertion, because --static was passed"
  NOT_CHECKED+=("the grading half, because --static was passed. Drop the flag to run it.")
else
  for item in "${ITEMS[@]}"; do
    d="$PROBE_DIR/$item"
    read_conf "$item" || continue

    if [ ! -f "$d/$C_ORACLE" ]; then
      if [ "$REQUIRE_ORACLES" -eq 1 ]; then
        nope "$item has no $C_ORACLE and --require-oracles was passed"
      else
        skip "$item grading, because $d/$C_ORACLE is not fetched"
        NOT_CHECKED+=("every grading assertion for $item, because its requirement module is not fetched. Run $FETCH.")
      fi
      continue
    fi

    mapfile -t MODULES < <(
      for m in "$d"/verify/*.tla; do
        [ -f "$m" ] || continue
        printf '%s\n' "${m##*/}"
      done
    )
    for m in "${MODULES[@]}"; do
      case "$m" in
        "$C_MODULE")  grade_one "$item" "$m" REFINES 0 ;;
        Wrong*.tla)   grade_one "$item" "$m" REFINEMENT_VIOLATED 22 ;;
        Frozen*.tla)  grade_one "$item" "$m" FROZEN_MAPPING 20 ;;
      esac
    done
  done
fi

# ---------------------------------------------------------------------------
# What this run did not check. Printed every run, including a clean one.
# ---------------------------------------------------------------------------

echo
echo "NOT CHECKED"
if [ "${#NOT_CHECKED[@]}" -eq 0 ]; then
  echo "  nothing. Both halves ran, so a correct solution and a wrong one were both graded."
else
  for line in "${NOT_CHECKED[@]}"; do
    printf '  %s\n' "$line"
  done
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed, %d skipped\n" "$pass_count" "$fail_count" "$skip_count" >&2
  exit 1
fi
printf "OK: %d passed, %d skipped\n" "$pass_count" "$skip_count"
exit 0
