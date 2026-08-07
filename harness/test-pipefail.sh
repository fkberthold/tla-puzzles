#!/usr/bin/env bash
# test-pipefail.sh — regression gate for bead tla-kr9.
#
# THE BUG. Under `set -o pipefail`, an early-exiting consumer closes the pipe
# the instant it is satisfied; the producer on the left dies of SIGPIPE; and the
# pipeline reports 141. Inside an `if`, 141 is merely falsy and `set -e` does not
# fire, so:
#
#     if producer | grep -qE -- "$pattern"; then    # WRONG
#
# reports a PRESENT pattern as ABSENT. Negate the test and it inverts instead:
#
#     if ! producer | grep -qE -- "$pattern"; then  # WRONG, and worse
#
# reports an ABSENT pattern as present. Both directions are live in this
# harness: a should-be-present structural assertion turns into a false FAIL, a
# must-be-absent one into a false PASS, and a guard clause in screen.sh or
# refinement.sh silently skips a check it was supposed to run.
#
# THE TRIGGER IS A RACE, NOT A SIZE. It depends on whether the consumer exits
# before the producer finishes flushing, so the same suite can be green on one
# run and red on the next with no code change. Two independent workers hit it
# with different producers (a shell function, and sed over a file) at different
# sizes. Do not go looking for a threshold; the shape is the bug.
#
# THE FIX IS TO REMOVE THE PIPE, not to capture the output first. Capturing and
# then piping the capture is measurably just as broken -- the `printf` builtin
# forks into the pipeline and takes SIGPIPE exactly as a function does. A
# here-string is materialised in full before the consumer is exec'd, so there is
# no live writer left to signal:
#
#     out=$(producer)
#     if grep -qE -- "$pattern" <<<"$out"; then     # RIGHT
#
# This suite pins both halves: part 1 demonstrates the mechanism on a
# deliberately chatty producer, and part 2 is the structural ban that keeps the
# idiom from coming back anywhere under harness/.
#
# Usage:  harness/test-pipefail.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# ---------------------------------------------------------------------------
# PART 1 — the mechanism, on a deliberately chatty producer.
# ---------------------------------------------------------------------------

# The pattern is on the FIRST line and ~1.2 MB follows it, so the consumer is
# satisfied immediately while the producer still has almost everything left to
# write. That is the worst case for SIGPIPE and the best case for a
# deterministic demonstration of it.
CHATTY_LINES=20000

chatty() {
  printf 'MATCHME the pattern under test is on the very first line\n'
  local i
  for ((i = 0; i < CHATTY_LINES; i++)); do
    printf 'filler line %d — padding padding padding padding padding padding\n' "$i"
  done
}

echo "== part 1: the mechanism, on a ${CHATTY_LINES}-line producer =="

CHATTY_OUT=$(chatty)

# --- the two broken shapes -------------------------------------------------
#
# These two assertions pin a fact about the PLATFORM, not about this repo's
# code: that the hazard is real here. They are what makes the rest of this
# suite worth running -- a ban on an idiom that could not misbehave would be
# cargo cult. If one of them ever fails, the failure is NOT a defect in
# whatever change you are making: it means bash or grep changed their SIGPIPE
# behaviour, and every "here-string, not a pipe" comment in harness/ needs
# re-verifying rather than trusting.

chatty | grep -qE MATCHME
rc=$?
if [ "$rc" -ne 0 ]; then
  ok "old shape (producer | grep -q) mis-reports a present pattern — rc=$rc"
else
  nope "old shape returned 0 — SIGPIPE-under-pipefail no longer reproduces; re-verify the tla-kr9 comments across harness/"
fi

# Capture-then-pipe. The obvious fix, and not a fix: measured at rc=141 at
# exactly the sizes the uncaptured form fails at. Pinned so nobody "simplifies"
# a here-string back into a printf pipe on the grounds that the capture already
# made it safe.
printf '%s\n' "$CHATTY_OUT" | grep -qE MATCHME
rc=$?
if [ "$rc" -ne 0 ]; then
  ok "capture-then-pipe (printf \"\$out\" | grep -q) is ALSO broken — rc=$rc"
else
  nope "capture-then-pipe returned 0 — the 'capture is enough' claim would need revisiting"
fi

# --- the fixed shape -------------------------------------------------------

if grep -qE MATCHME <<<"$CHATTY_OUT"; then
  ok "here-string shape reports a present pattern as PRESENT"
else
  nope "here-string shape reported a present pattern as absent — THE BUG IS BACK"
fi

# The non-vacuity control for the assertion above: if the here-string form
# returned 0 unconditionally it would pass that check for the wrong reason.
if grep -qE 'NOTHINGMATCHESTHIS' <<<"$CHATTY_OUT"; then
  nope "here-string shape reported an absent pattern as present"
else
  ok "here-string shape reports an absent pattern as ABSENT (control)"
fi

# --- the same, for slicing consumers ---------------------------------------

printf '%s\n' "$CHATTY_OUT" | head -n 3 >/dev/null
rc=$?
if [ "$rc" -ne 0 ]; then
  ok "old shape (producer | head -n N) mis-reports too — rc=$rc"
else
  nope "producer | head returned 0 — re-verify the tla-kr9 comments across harness/"
fi

sliced=$(head -n 3 <<<"$CHATTY_OUT")
rc=$?
sliced_n=$(grep -c '' <<<"$sliced")
if [ "$rc" -eq 0 ] && [ "$sliced_n" -eq 3 ]; then
  ok "here-string slicing (head -n 3 <<<) succeeds and yields 3 lines"
else
  nope "here-string slicing — rc=$rc, lines=$sliced_n, wanted rc=0 and 3"
fi

# --- an assertion built the way the harness builds them ---------------------
#
# The end-to-end shape: exactly the helper every structural suite in harness/
# defines, driven by a chatty producer. This is the assertion that would have
# caught tla-kr9 in the first place.

harness_assert_present() {
  local pattern="$1" body="$2"
  if grep -qE -- "$pattern" <<<"$body"; then printf 'PRESENT\n'; else printf 'ABSENT\n'; fi
}

verdict=$(harness_assert_present 'MATCHME' "$CHATTY_OUT")
if [ "$verdict" = "PRESENT" ]; then
  ok "a harness-shaped assert_present says PRESENT on a chatty producer"
else
  nope "a harness-shaped assert_present said $verdict on a chatty producer"
fi

# Patterns opening with a literal '-' are the reason every harness matcher
# passes `--`. Without it grep reads the pattern as options, errors, and reports
# no hits -- a check that passes because it never ran. Pinned here because it is
# the same failure class: an assertion that silently stops running.
verdict=$(harness_assert_present '-workers[[:space:]]+1' "prefix -workers 1 suffix")
if [ "$verdict" = "PRESENT" ]; then
  ok "a leading-dash pattern still matches (the '--' guard holds)"
else
  nope "a leading-dash pattern reported $verdict — the '--' guard is missing somewhere"
fi

# ---------------------------------------------------------------------------
# PART 2 — the structural ban.
#
# Gate, don't advise: the fix above is worthless if the idiom can walk back in.
# This scans every shell file under harness/ and fails on any reintroduction,
# including in files that do not exist yet.
# ---------------------------------------------------------------------------

echo
echo "== part 2: the idiom is banned across harness/ =="

# Self-exclusion, and why: part 1 above runs the broken shapes ON PURPOSE, so
# this file necessarily contains the very text the scan looks for. It is the one
# file in the tree allowed to.
SELF="harness/test-pipefail.sh"

# Every shell file under harness/, found by shebang rather than by extension —
# harness/fixtures/screen/ holds executable stubs with no .sh suffix, and a ban
# that skipped them would leave a hole exactly where the last bug was found.
shell_files=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  [ "$f" = "$SELF" ] && continue
  first=$(head -n 1 "$f" 2>/dev/null)
  case "$first" in
  '#!'*sh*) shell_files+=("$f") ;;
  *) case "$f" in *.sh) shell_files+=("$f") ;; esac ;;
  esac
done < <(find harness -type f -not -path '*/.git/*' | sort)

if [ "${#shell_files[@]}" -ge 8 ]; then
  ok "scan found ${#shell_files[@]} shell files under harness/"
else
  nope "scan found only ${#shell_files[@]} shell files under harness/ — the ban is not covering the tree"
fi

# Whole-line comments are stripped before matching, exactly as the structural
# suites do it: every fixed site carries a comment explaining the idiom it
# replaced, and matching raw text would let those explanations trip the ban.
scan_for() {
  local label="$1" pattern="$2" offenders="" f code hits
  for f in "${shell_files[@]}"; do
    code=$(sed 's/^[[:space:]]*#.*$//' "$f")
    hits=$(grep -nE -- "$pattern" <<<"$code")
    if [ -n "$hits" ]; then
      while IFS= read -r h; do
        [ -n "$h" ] && offenders="$offenders
      $f:$h"
      done <<<"$hits"
    fi
  done
  if [ -z "$offenders" ]; then
    ok "$label"
  else
    nope "$label — reintroduced at:$offenders"
  fi
}

# `grep -q` / `grep -m N` behind a pipe: exits on first match, SIGPIPEs the
# producer. Use `grep -q ... <<<"$captured"`.
scan_for "no '| grep -q' anywhere under harness/" \
  '\|[[:space:]]*grep([[:space:]]+-[A-Za-z]*)*[[:space:]]+-[A-Za-z]*q'

scan_for "no '| grep -m' anywhere under harness/" \
  '\|[[:space:]]*grep([[:space:]]+-[A-Za-z]*)*[[:space:]]+-[A-Za-z]*m[[:space:]]*[0-9]'

# `head` behind a pipe: exits after N lines, SIGPIPEs the producer. Use
# `head -n N <<<"$captured"`.
scan_for "no '| head' anywhere under harness/" \
  '\|[[:space:]]*head([[:space:]]|$)'

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
