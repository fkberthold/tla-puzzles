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
# idiom from coming back anywhere under the scanned roots (harness/, scripts/,
# chapter/ — see SCAN_ROOTS).
#
# Usage:  harness/test-pipefail.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

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
# This scans every shell file under the roots below and fails on any
# reintroduction, including in files that do not exist yet.
#
# THE ROOTS. This scanned harness/ alone until bead tla-4u0, which left every
# shell file in scripts/ and chapter/ ungated — and the widened scan found four
# live sites in scripts/ the moment it was turned on. Add a ROOT here, never an
# individual file: the whole point is that a file written tomorrow is covered
# without anyone remembering to enrol it.
# ---------------------------------------------------------------------------

SCAN_ROOTS=(harness scripts chapter)

echo
echo "== part 2: the idiom is banned across ${SCAN_ROOTS[*]} =="

# Self-exclusion, and why: part 1 above runs the broken shapes ON PURPOSE, so
# this file necessarily contains the very text the scan looks for. It is the one
# file in the tree allowed to.
#
# Every file that warns against a string necessarily contains that string, so
# this is a shape to watch rather than a one-off: the whole-line comment strip
# below covers the ordinary documentation case, and ALLOW_KEYS covers the rest.
SELF="harness/test-pipefail.sh"

# Every shell file under the roots, found by shebang rather than by extension —
# harness/fixtures/screen/ holds executable stubs with no .sh suffix, and a ban
# that skipped them would leave a hole exactly where the last bug was found.
#
# Selecting by shebang is also what keeps prose out of the scan. chapter/ is
# mostly .md and scripts/ holds three .py helpers; none carries a `sh` shebang
# or a .sh suffix, so the widened roots do not drag markdown or Python into a
# ban written for shell.
shell_files=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  [ "$f" = "$SELF" ] && continue
  first=$(head -n 1 "$f" 2>/dev/null)
  case "$first" in
  '#!'*sh*) shell_files+=("$f") ;;
  *) case "$f" in *.sh) shell_files+=("$f") ;; esac ;;
  esac
done < <(find "${SCAN_ROOTS[@]}" -type f -not -path '*/.git/*' | sort)

# One assertion PER ROOT, never one over the total. A single total goes green on
# harness/ alone, so it cannot tell "chapter/ is covered" from "chapter/ silently
# dropped out of the find" — which is precisely the bug tla-4u0 fixed, one root
# up. The floors sit well under the measured counts (16 / 12 / 2 on 2026-08-07):
# this asserts that a root is still being walked, not how big it has grown.
check_root() {
  local root="$1" floor="$2" f n=0
  for f in "${shell_files[@]}"; do
    case "$f" in "$root"/*) n=$((n + 1)) ;; esac
  done
  if [ "$n" -ge "$floor" ]; then
    ok "scan covers $root/ — $n shell files"
  else
    nope "scan found only $n shell files under $root/ (floor $floor) — the ban is not covering that root"
  fi
}

check_root harness 8
check_root scripts 8
check_root chapter 1

# ---------------------------------------------------------------------------
# The allowlist — for a banned string that is DATA rather than code.
#
# Whole-line comments are stripped before matching (see collect_offenders), which
# covers the ordinary documentation case: every fixed site carries a comment
# explaining the idiom it replaced, and matching raw text would let those
# explanations trip the ban. It does NOT cover a here-doc BODY, which a script
# emits into a generated file and never executes.
#
# WHY AN ALLOWLIST AND NOT A HERE-DOC PARSER. Skipping here-doc bodies wholesale
# was considered and rejected. Detecting an opener means matching `<<WORD`, and
# harness/fixtures/refinement/selftest.sh:228 passes the TLA+ tuple
# `--initial '<< 0 >>'` on a command line. That one escapes only because `0` is
# not an identifier character — `'<< a >>'` is equally valid TLA+ and would open
# a phantom here-doc whose terminator never arrives, blanking the remainder of
# the file from the scan. The failure direction there is a FALSE PASS on a
# correctness gate, the worst outcome this suite has (cf. the SYMMETRY/VIEW
# guard in harness/refinement.sh, where a 141 lets an unsound reduction through
# unflagged). A parser can mask a site nobody named; an allowlist cannot mask
# anything it does not name.
#
# Each entry is "<file>:<matched line, verbatim>". Add one only for a line that
# provably cannot execute, and say why in ALLOW_WHY.
ALLOW_KEYS=(
  "scripts/gen-curriculum-map.sh:  sort | head -20"
)
ALLOW_WHY=(
  "inside the <<'FOOTER' here-doc opened at line 75 — markdown emitted into CURRICULUM_MAP.md documenting an interactive bd query, never executed"
)
# Derived, never hand-maintained: a literal that drifted out of step with
# ALLOW_KEYS would read an unset element under `set -u` and abort the suite.
ALLOW_HITS=()
for i in "${!ALLOW_KEYS[@]}"; do ALLOW_HITS[i]=0; done

allowed() {
  local key="$1" i
  for i in "${!ALLOW_KEYS[@]}"; do
    if [ "$key" = "${ALLOW_KEYS[$i]}" ]; then
      ALLOW_HITS[i]=$((ALLOW_HITS[i] + 1))
      return 0
    fi
  done
  return 1
}

# Sets the global OFFENDERS rather than echoing it. A command substitution would
# run the loop in a SUBSHELL and throw away every ALLOW_HITS increment, quietly
# defeating the staleness check below.
OFFENDERS=""
collect_offenders() {
  local pattern="$1"
  shift
  local f code hits h line
  OFFENDERS=""
  for f in "$@"; do
    code=$(sed 's/^[[:space:]]*#.*$//' "$f")
    hits=$(grep -nE -- "$pattern" <<<"$code")
    [ -n "$hits" ] || continue
    while IFS= read -r h; do
      [ -n "$h" ] || continue
      line=${h#*:}
      allowed "$f:$line" && continue
      OFFENDERS="$OFFENDERS
      $f:$h"
    done <<<"$hits"
  done
}

scan_for() {
  local label="$1" pattern="$2"
  collect_offenders "$pattern" "${shell_files[@]}"
  if [ -z "$OFFENDERS" ]; then
    ok "$label"
  else
    nope "$label — reintroduced at:$OFFENDERS"
  fi
}

# `grep -q` / `grep -m N` behind a pipe: exits on first match, SIGPIPEs the
# producer. Use `grep -q ... <<<"$captured"`.
PAT_GREP_Q='\|[[:space:]]*grep([[:space:]]+-[A-Za-z]*)*[[:space:]]+-[A-Za-z]*q'
PAT_GREP_M='\|[[:space:]]*grep([[:space:]]+-[A-Za-z]*)*[[:space:]]+-[A-Za-z]*m[[:space:]]*[0-9]'
# `head` behind a pipe: exits after N lines, SIGPIPEs the producer. Use
# `head -n N <<<"$captured"`.
PAT_HEAD='\|[[:space:]]*head([[:space:]]|$)'

scan_for "no '| grep -q' anywhere under ${SCAN_ROOTS[*]}" "$PAT_GREP_Q"
scan_for "no '| grep -m' anywhere under ${SCAN_ROOTS[*]}" "$PAT_GREP_M"
scan_for "no '| head' anywhere under ${SCAN_ROOTS[*]}" "$PAT_HEAD"

# An allowlist entry that matches nothing is a standing exemption for a line
# that no longer exists — the shape that lets an allowlist rot into a blanket
# waiver. Delete the entry rather than carrying it.
stale=""
for i in "${!ALLOW_KEYS[@]}"; do
  if [ "${ALLOW_HITS[$i]}" -eq 0 ]; then
    stale="$stale
      ${ALLOW_KEYS[$i]}  (${ALLOW_WHY[$i]})"
  fi
done
if [ -z "$stale" ]; then
  ok "all ${#ALLOW_KEYS[@]} allowlist entries still match a real line"
else
  nope "allowlist entry matches nothing — delete it rather than leaving a standing exemption:$stale"
fi

# ---------------------------------------------------------------------------
# PART 3 — controls on the scanner itself.
#
# Every assertion in part 2 is of the form "found nothing", which is exactly
# what a scanner that quietly stopped working also reports: one typo in a
# pattern, one root dropped from the find, and the whole ban goes green while
# covering nothing. These plant the banned shapes in synthetic files outside the
# roots and require the scanner to get both directions right.
# ---------------------------------------------------------------------------

echo
echo "== part 3: the scanner itself still bites =="

CONTROL_DIR=$(mktemp -d -t tla_pipefail_control.XXXXXX)
trap 'rm -rf "$CONTROL_DIR"' EXIT

PLANTED="$CONTROL_DIR/planted.sh"
{
  printf '#!/usr/bin/env bash\n'
  printf 'producer | grep -qE MATCHME\n'
  printf 'producer | grep -m1 MATCHME\n'
  printf 'producer | head -n 3\n'
} >"$PLANTED"

control_bites() {
  local label="$1" pattern="$2"
  collect_offenders "$pattern" "$PLANTED"
  if [ -n "$OFFENDERS" ]; then
    ok "control: a planted $label is DETECTED"
  else
    nope "control: a planted $label was NOT detected — the pattern is dead and its ban above is vacuous"
  fi
}

control_bites "'| grep -q'" "$PAT_GREP_Q"
control_bites "'| grep -m'" "$PAT_GREP_M"
control_bites "'| head'" "$PAT_HEAD"

# The other direction: a file whose only banned text is inside whole-line
# comments must come back clean. A gate that cries wolf on the documentation
# warning against the idiom gets switched off, which is worse than no gate.
COMMENTED="$CONTROL_DIR/commented.sh"
{
  printf '#!/usr/bin/env bash\n'
  printf '# never write producer | grep -qE PATTERN — it returns 141\n'
  printf '#   nor producer | grep -m1 PATTERN\n'
  printf '#   nor producer | head -n 3\n'
  printf 'true\n'
} >"$COMMENTED"

commented_clean=1
for pat in "$PAT_GREP_Q" "$PAT_GREP_M" "$PAT_HEAD"; do
  collect_offenders "$pat" "$COMMENTED"
  [ -n "$OFFENDERS" ] && commented_clean=0
done
if [ "$commented_clean" -eq 1 ]; then
  ok "control: banned text inside whole-line comments does NOT trip the ban"
else
  nope "control: a whole-line comment tripped the ban — the comment strip is broken and the gate now cries wolf on its own documentation"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
