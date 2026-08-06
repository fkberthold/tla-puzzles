#!/usr/bin/env bash
#
# Self-test for harness/screen.sh — the §5.7 mechanism-collision screen.
#
# Runs entirely OFFLINE against the cached tlaplus/Examples README fixture in
# this directory plus two `gh` stubs, so a failure here means the screen is
# broken, never that GitHub was unreachable.
#
#   harness/screen.sh --selftest        # normal entry point
#   harness/fixtures/screen/selftest.sh # direct
#
# The last block is a DOCUMENT-INTEGRITY check on harness/PUZZLE-SCREEN.md.
# It asserts the §5.7b rubric still carries its worked example; it does NOT
# decide puzzle-versus-system. Nothing in this file returns a §5.7b verdict —
# see the header of PUZZLE-SCREEN.md for why that would be worse than useless.

set -uo pipefail

FIXTURES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="$(cd "$FIXTURES/../.." && pwd)"
SCREEN="$HARNESS/screen.sh"
RUBRIC="$HARNESS/PUZZLE-SCREEN.md"

PASS=0
FAIL=0
CASE=""
OUT=""
CODE=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- assertions -------------------------------------------------------------

fail() {
	FAIL=$((FAIL + 1))
	printf 'FAIL  %s\n        %s\n' "$CASE" "$1"
	if [ -n "${OUT:-}" ]; then
		printf '%s\n' "$OUT" | sed 's/^/        | /'
	fi
}

ok() {
	PASS=$((PASS + 1))
	printf 'ok    %s — %s\n' "$CASE" "$1"
}

assert_exit() {
	if [ "$CODE" = "$1" ]; then
		ok "exit $1"
	else
		fail "expected exit $1, got $CODE"
	fi
}

assert_contains() {
	if printf '%s' "$OUT" | grep -qF -- "$1"; then
		ok "contains '$1'"
	else
		fail "expected output to contain '$1'"
	fi
}

assert_not_contains() {
	if printf '%s' "$OUT" | grep -qF -- "$1"; then
		fail "expected output NOT to contain '$1'"
	else
		ok "lacks '$1'"
	fi
}

assert_file_contains() {
	if [ ! -f "$1" ]; then
		fail "missing file $1"
		return
	fi
	if grep -qF -- "$2" "$1"; then
		ok "$(basename "$1") contains '$2'"
	else
		fail "$1 does not contain '$2'"
	fi
}

# Run screen.sh offline. `gh` is pointed at a stub that fails loudly, so any
# network step that sneaks into the offline path turns the case red.
run_offline() {
	CASE="$1"
	shift
	OUT="$(SCREEN_GH="$FIXTURES/gh-must-not-run" \
		SCREEN_README="$FIXTURES/examples-README.md" \
		SCREEN_CACHE_DIR="$WORK/cache" \
		"$SCREEN" --offline "$@" 2>&1)"
	CODE=$?
}

# Run screen.sh with a stubbed `gh` that answers code-search from a fixture
# table. Exercises the >3 rule without touching the network.
run_stubbed() {
	CASE="$1"
	shift
	OUT="$(SCREEN_GH="$FIXTURES/gh-stub" \
		SCREEN_STUB_COUNTS="$FIXTURES/gh-stub-counts.txt" \
		SCREEN_README="$FIXTURES/examples-README.md" \
		SCREEN_CACHE_DIR="$WORK/cache" \
		SCREEN_SLEEP=0 \
		"$SCREEN" "$@" 2>&1)"
	CODE=$?
}

# --- preconditions ----------------------------------------------------------

CASE="preconditions"
[ -x "$SCREEN" ] && ok "screen.sh is executable" || fail "screen.sh missing or not executable at $SCREEN"
[ -f "$FIXTURES/examples-README.md" ] && ok "cached Examples README fixture present" ||
	fail "missing README cache fixture"
assert_file_contains "$FIXTURES/examples-README.md" "[Resource Allocator](specifications/allocator)"
assert_file_contains "$FIXTURES/examples-README.md" "[Misra Reachability Algorithm](specifications/MisraReachability)"

# --- §5.7 step 2: mechanism, not name ---------------------------------------

# The §2.2 headline case. Name novelty is total — nobody has a
# `RestaurantSeating.tla`. Mechanism novelty is nil.
run_offline "restaurant seating (offline)" "restaurant seating with party sizes and table combining"
assert_exit 2
assert_contains "BURNED"
assert_contains "Resource Allocator"
assert_contains "bin-packing"
assert_contains "knapsack"
assert_contains "§2.2"

# §2.2: the allocator in different dress.
run_offline "library hold queues (offline)" "library hold queues"
assert_exit 2
assert_contains "Resource Allocator"
assert_contains "the \`Resource Allocator\` spec in different dress"

run_offline "community garden (offline)" "community garden plot allocation"
assert_exit 2
assert_contains "Resource Allocator"

run_offline "airline standby (offline)" "airline standby and upgrade lists"
assert_exit 2
assert_contains "Resource Allocator"

# The plan's own two worked examples for "grep the mechanism, not the name"
# (V2-PLAN.md §5.7): warehouse robots are MisraReachability + mutual exclusion,
# leader failover is Paxos.
run_offline "warehouse robots (offline)" "warehouse robot coordination"
assert_exit 2
assert_contains "Misra Reachability"
assert_contains "Mutual Exclusion"

run_offline "leader failover (offline)" "leader failover"
assert_exit 2
assert_contains "Paxos"

run_offline "seat reservation (offline)" "seat reservation"
assert_exit 2
assert_contains "Resource Allocator"

# Parallel department sign-offs are atomic commitment in municipal dress.
run_offline "municipal permits (offline)" "municipal permit review with parallel department sign-offs"
assert_exit 2
assert_contains "Atomic Commitment"

# --- controls: the screen must be able to say CLEAR --------------------------

run_offline "ski pass (offline)" "ski pass validation with blackout dates"
assert_exit 0
assert_contains "CLEAR"

run_offline "shared custody (offline)" "shared-custody calendars with holiday overrides"
assert_exit 0
assert_contains "CLEAR"

# --- the two screens stay independent ---------------------------------------

# change-ringing fails §5.7b, NOT §5.7. screen.sh must still report CLEAR on
# its own screen and REFER the candidate rather than swallowing the verdict.
run_offline "change-ringing (offline)" "change-ringing method rules"
assert_exit 0
assert_contains "CLEAR"
assert_contains "§5.7b"
assert_contains "PUZZLE-SCREEN.md"
assert_contains "rescuable"

# beekeeping is a §3.2 crispness risk, again not a §5.7 collision.
run_offline "beekeeping (offline)" "beekeeping hive splits"
assert_exit 0
assert_contains "§3.2"
assert_contains "fuzzy"

# orchestra auditions collide with tournament brackets, so at most one survives.
run_offline "orchestra auditions (offline)" "orchestra audition rounds"
assert_contains "tournament"
assert_contains "at most one of the two survives"

# Every run, whatever the verdict, must say out loud that §5.7b was not run.
CASE="every run refers §5.7b"
assert_contains "NOT run here"

# --- offline really is offline ----------------------------------------------

run_offline "offline makes no network call" "ski pass validation with blackout dates"
assert_not_contains "gh-must-not-run WAS CALLED"
assert_contains "skipped (offline)"

# --- §5.7 step 1: the >3 name rule ------------------------------------------

run_stubbed "burned by name" --name RestaurantSeating "ski pass validation with blackout dates"
assert_exit 2
assert_contains "hits: 7"
assert_contains "BURNED"

run_stubbed "clear by name" --name SkiPassBlackout "ski pass validation with blackout dates"
assert_exit 0
assert_contains "hits: 1"
assert_contains "CLEAR"

# Boundary: exactly 3 is not burned; 4 is.
run_stubbed "3 hits is not burned" --name ThreeHitName "ski pass validation with blackout dates"
assert_exit 0
run_stubbed "4 hits is burned" --name FourHitName "ski pass validation with blackout dates"
assert_exit 2

# Mechanism code-search is the channel that catches Knapsack: the term is not
# in the Examples README at all, only in the wider corpus.
CASE="knapsack is absent from the README"
OUT=""
if grep -qiE 'knapsack|bin.?pack' "$FIXTURES/examples-README.md"; then
	fail "README fixture unexpectedly mentions knapsack/bin-packing"
else
	ok "README has no knapsack row — the 56 specs are a code-search find, not a README find"
fi

run_stubbed "burned by mechanism code-search" --name NovelSoundingName "restaurant seating with table combining"
assert_exit 2
assert_contains "Knapsack"
assert_contains "56"

# --- refresh is a SEPARATE path from the screen ------------------------------

CASE="--refresh writes the cache"
OUT="$(SCREEN_GH="$FIXTURES/gh-stub" \
	SCREEN_STUB_COUNTS="$FIXTURES/gh-stub-counts.txt" \
	SCREEN_README="$WORK/refreshed-README.md" \
	SCREEN_CACHE_DIR="$WORK/cache" \
	"$SCREEN" --refresh 2>&1)"
CODE=$?
assert_exit 0
if [ -s "$WORK/refreshed-README.md" ]; then
	ok "refresh wrote a non-empty README cache"
else
	fail "refresh did not write $WORK/refreshed-README.md"
fi

# --- the seeded §2.2 table is visible ---------------------------------------

CASE="--list-suspicions"
OUT="$(SCREEN_README="$FIXTURES/examples-README.md" "$SCREEN" --list-suspicions 2>&1)"
CODE=$?
assert_exit 0
assert_contains "restaurant seating"
assert_contains "library hold queues"
assert_contains "orchestra audition"
assert_contains "change-ringing"
assert_contains "beekeeping"

# --- document integrity: the §5.7b rubric ------------------------------------
#
# NOT a verdict. These assert only that the judgment rubric still ships its
# worked example — the same domain stated two ways, with opposite outcomes.

CASE="PUZZLE-SCREEN.md carries the RED pair"
OUT=""
assert_file_contains "$RUBRIC" "seat this party optimally"
assert_file_contains "$RUBRIC" "model the host stand with walk-ins and reservations arriving concurrently"
assert_file_contains "$RUBRIC" "if you hand the learner the legal moves, is there anything left to model?"
assert_file_contains "$RUBRIC" "REJECT"
assert_file_contains "$RUBRIC" "ACCEPT"
assert_file_contains "$RUBRIC" "add agents and fallibility"
assert_file_contains "$RUBRIC" "Beginner"

CASE="PUZZLE-SCREEN.md refuses to be a script"
assert_file_contains "$RUBRIC" "judgment"

# --- summary ----------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
