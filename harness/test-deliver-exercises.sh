#!/usr/bin/env bash
# test-deliver-exercises.sh: executable spec for scripts/deliver-exercises.sh
# (bead tla-jb7f.1).
#
# Pins the RED invariant from the bead:
#
#   deliver-exercises.sh for chapter N delivers EXERCISES.md, starters/, a
#   LOG.md scaffold, and CHEATSHEET.md for chapters below N only. references/,
#   reports/, COVERAGE.md, and chapter N's own sheet never land in the
#   destination.
#
# The invariant has two halves and the second one is the reason this suite
# exists. Delivering the right files is easy to check by eye. Not delivering
# the wrong ones is not, because the four forbidden paths are exactly the
# material a reader would use to shortcut the exercise. A sheet for chapter N
# hands over the answers to the chapter being practiced, and references/ and
# reports/ carry the graded history. Once one of them lands in the practice
# tree the exercise is spent and nobody finds out.
#
# Three kinds of assertion:
#
#   Behavioral: build a fixture chapter tree under a temp dir, point
#     DELIVER_SRC_ROOT at it, deliver into a temp dest-root, and read the
#     result off the filesystem. Every run passes an explicit dest-root and
#     a sandboxed HOME, so the real ~/tla-practice/exercises is never touched
#     even by a script that ignores its argument.
#
#   Negative: the absence checks, which all go through assert_not_delivered.
#     A bare `[ ! -e path ]` is satisfied by a script that delivered nothing
#     at all, so each one first requires the chapter directory to exist. That
#     control is what keeps this suite red for the right reason before the
#     script is written.
#
#   Structural: the four template files exist, and scripts/test carries a
#     fast-tier SUITES row for this file. Gate, don't advise: a suite nobody
#     registered is a check nobody runs.
#
# Usage:  harness/test-deliver-exercises.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="scripts/deliver-exercises.sh"
TEST_RUNNER="scripts/test"
TEMPLATE_DIR="exercises/templates"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# Read once. Several helpers below refuse to draw a conclusion from a non-zero
# exit status while the script is missing, because a missing script exits
# non-zero for a reason that says nothing about the contract.
SCRIPT_PRESENT=0
[ -f "$SCRIPT" ] && SCRIPT_PRESENT=1

# ---------------------------------------------------------------------------
# Fixture tree.
#
# ch02 through ch11 all exist and all carry an EXERCISES.md. ch04 is the one
# chapter with no CHEATSHEET.md, which is the missing-sheet case. ch05 carries
# the full set of extras (starters/ with a nested directory, references/,
# reports/, COVERAGE.md) and is the chapter the main run delivers. ch03 has no
# starters/ at all, which is the absence case.
# ---------------------------------------------------------------------------

TMPROOT=$(mktemp -d -t tla_deliver.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

SRC="$TMPROOT/src"
SRC_NOCHAP="$TMPROOT/src-nochap"
SRC_NOEX="$TMPROOT/src-noex"
SANDBOX_HOME="$TMPROOT/home"
ERRFILE="$TMPROOT/stderr.txt"

DEST_MAIN="$TMPROOT/dest-main"     # chapter 5, the full happy path
DEST_BARE="$TMPROOT/dest-bare"     # chapter 3, no starters/ in the source
DEST_KEEP="$TMPROOT/dest-keep"     # pre-seeded, for the never-overwrite rule
DEST_LOW="$TMPROOT/dest-low"       # chapter 2, the bottom of the range
DEST_HIGH="$TMPROOT/dest-high"     # chapter 11, the top of the range
DEST_REJECT="$TMPROOT/dest-reject" # never written, the argument-error runs

mkdir -p "$SANDBOX_HOME"

# The dest-roots are deliberately NOT created here. The default dest-root does
# not exist on a fresh machine either, so making the tree is the script's job.
mkdir -p "$SRC/templates"
printf '# Practice log\n\n| exercise | cold or after-reread | minutes | stuck on |\n' \
  >"$SRC/templates/LOG.md"

for n in 02 03 04 05 06 07 08 09 10 11; do
  mkdir -p "$SRC/ch$n"
  printf 'EXERCISES for chapter %s\n' "$n" >"$SRC/ch$n/EXERCISES.md"
  if [ "$n" != "04" ]; then
    printf 'CHEATSHEET for chapter %s\n' "$n" >"$SRC/ch$n/CHEATSHEET.md"
  fi
done

mkdir -p "$SRC/ch05/starters/Nested" "$SRC/ch05/references" "$SRC/ch05/reports"
printf 'Ex1 starter\n' >"$SRC/ch05/starters/Ex1.tla"
printf 'Deep starter\n' >"$SRC/ch05/starters/Nested/Deep.tla"
printf 'reference material\n' >"$SRC/ch05/references/notes.md"
printf 'a graded report\n' >"$SRC/ch05/reports/2026-01-01.md"
printf 'coverage bookkeeping\n' >"$SRC/ch05/COVERAGE.md"

# Two broken source roots for the two source-error rows.
mkdir -p "$SRC_NOCHAP/templates"
cp "$SRC/templates/LOG.md" "$SRC_NOCHAP/templates/LOG.md"

mkdir -p "$SRC_NOEX/templates" "$SRC_NOEX/ch07"
cp "$SRC/templates/LOG.md" "$SRC_NOEX/templates/LOG.md"
printf 'CHEATSHEET for chapter 07\n' >"$SRC_NOEX/ch07/CHEATSHEET.md"

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

RUN_OUT=""
RUN_ERR=""
RUN_RC=0

# run_deliver <src-root> [args...]
#
# HOME is redirected for every run. The default dest-root lives under $HOME, so
# a script that drops its dest-root argument writes into the sandbox instead of
# into Frank's real practice tree.
run_deliver() {
  local src="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_SRC_ROOT="$src" bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# assert_rc0 <label>
assert_rc0() {
  if [ "$RUN_RC" -eq 0 ]; then
    ok "$1"
  else
    nope "$1 (rc=$RUN_RC), stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  fi
}

# assert_content <label> <path> <expected>
#
# Compares the whole file against a literal. The fixture files are one line
# each, so a partial match would not tell a copied file from a truncated one.
assert_content() {
  local label="$1" path="$2" want="$3" got
  if [ ! -f "$path" ]; then
    nope "$label. Not delivered: $path"
    return
  fi
  got=$(cat "$path")
  if [ "$got" = "$want" ]; then
    ok "$label"
  else
    nope "$label. Wanted '$want', got '$got'"
  fi
}

# assert_bytes <label> <path> <keeper>
#
# cmp rather than a string compare, because "survives byte-for-byte" is the
# claim and $(cat) drops trailing newlines on both sides of the comparison.
#
# The rc guard is the same non-vacuity control assert_not_delivered carries. A
# run that never started leaves every file exactly as it found it, so survival
# only means something once the run it survived exited 0.
assert_bytes() {
  local label="$1" path="$2" keeper="$3"
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The run that had to leave it alone failed (rc=$RUN_RC), so survival proves nothing"
  elif [ ! -f "$path" ]; then
    nope "$label. The file is gone: $path"
  elif cmp -s "$path" "$keeper"; then
    ok "$label"
  else
    nope "$label. Content changed: $path"
  fi
}

# assert_not_delivered <label> <chapter-dir> <relative-path>
#
# The non-vacuity control. A script that delivered nothing satisfies every
# absence check trivially, so require the chapter directory first. Without
# this, roughly a quarter of the suite would be green before the script exists.
assert_not_delivered() {
  local label="$1" chdir="$2" rel="$3"
  if [ ! -d "$chdir" ]; then
    nope "$label. Nothing landed at all ($chdir absent), so the absence proves nothing"
  elif [ -e "$chdir/$rel" ]; then
    nope "$label. Present: $chdir/$rel"
  else
    ok "$label"
  fi
}

# assert_says <label> <extended-regex> <captured-text>
#
# Here-string, never a pipe. `producer | grep -q` returns 141 under pipefail
# and reports a present pattern as absent (bead tla-kr9), and capturing into a
# printf pipe is just as broken. harness/test-pipefail.sh bans both forms
# across this tree.
assert_says() {
  local label="$1" pattern="$2" body="$3"
  if grep -qE -- "$pattern" <<<"$body"; then
    ok "$label"
  else
    nope "$label. No line matched: $pattern"
  fi
}

# assert_rejects <label> [args...]
#
# Both halves of the argument contract in one row: non-zero exit AND usage on
# stderr. Guarded on the script existing, because a missing file exits 127 and
# that is not evidence about argument handling.
assert_rejects() {
  local label="$1"
  shift
  if [ "$SCRIPT_PRESENT" -eq 0 ]; then
    nope "$label. $SCRIPT does not exist, so a non-zero exit proves nothing"
    return
  fi
  run_deliver "$SRC" "$@"
  if [ "$RUN_RC" -eq 0 ]; then
    nope "$label. Exited 0, wanted non-zero"
  elif ! grep -qE -- '[Uu]sage' <<<"$RUN_ERR"; then
    nope "$label. Exited $RUN_RC but printed no usage on stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  else
    ok "$label"
  fi
}

# assert_source_error <label> <src-root> [args...]
assert_source_error() {
  local label="$1" src="$2"
  shift 2
  if [ "$SCRIPT_PRESENT" -eq 0 ]; then
    nope "$label. $SCRIPT does not exist, so a non-zero exit proves nothing"
    return
  fi
  run_deliver "$src" "$@"
  if [ "$RUN_RC" -ne 0 ]; then
    ok "$label"
  else
    nope "$label. Exited 0, wanted non-zero"
  fi
}

# ---------------------------------------------------------------------------
echo "== the script itself =="
# ---------------------------------------------------------------------------

if [ "$SCRIPT_PRESENT" -eq 1 ]; then
  ok "$SCRIPT exists"
else
  nope "$SCRIPT does not exist"
fi

# ---------------------------------------------------------------------------
echo
echo "== chapter 5: the four things that land =="
# ---------------------------------------------------------------------------

run_deliver "$SRC" 5 "$DEST_MAIN"

assert_rc0 "chapter 5 delivery exits 0"

assert_content "EXERCISES.md is delivered" \
  "$DEST_MAIN/ch05/EXERCISES.md" "EXERCISES for chapter 05"

assert_content "starters/ is delivered" \
  "$DEST_MAIN/ch05/starters/Ex1.tla" "Ex1 starter"

# starters/ is copied recursively, not one level deep.
assert_content "starters/ is delivered recursively" \
  "$DEST_MAIN/ch05/starters/Nested/Deep.tla" "Deep starter"

assert_content "LOG.md comes from the template" \
  "$DEST_MAIN/ch05/LOG.md" \
  "$(cat "$SRC/templates/LOG.md")"

assert_content "cheatsheets/ch02.md is delivered" \
  "$DEST_MAIN/ch05/cheatsheets/ch02.md" "CHEATSHEET for chapter 02"

assert_content "cheatsheets/ch03.md is delivered" \
  "$DEST_MAIN/ch05/cheatsheets/ch03.md" "CHEATSHEET for chapter 03"

# ---------------------------------------------------------------------------
echo
echo "== chapter 5: the six things that never land =="
# ---------------------------------------------------------------------------

# The head of the invariant. A sheet for the chapter being practiced is the
# answer key, and it is the one file whose delivery would be invisible in a
# directory listing that otherwise looks right.
assert_not_delivered "chapter 5's own sheet never lands" \
  "$DEST_MAIN/ch05" "cheatsheets/ch05.md"

assert_not_delivered "a sheet from above chapter 5 never lands" \
  "$DEST_MAIN/ch05" "cheatsheets/ch06.md"

assert_not_delivered "the missing chapter 4 sheet leaves no file behind" \
  "$DEST_MAIN/ch05" "cheatsheets/ch04.md"

assert_not_delivered "references/ never lands" \
  "$DEST_MAIN/ch05" "references"

assert_not_delivered "reports/ never lands" \
  "$DEST_MAIN/ch05" "reports"

assert_not_delivered "COVERAGE.md never lands" \
  "$DEST_MAIN/ch05" "COVERAGE.md"

# ---------------------------------------------------------------------------
echo
echo "== a missing earlier sheet is reported, not fatal =="
# ---------------------------------------------------------------------------

# ch04 exists in range and carries no CHEATSHEET.md. The run above already
# exited 0, so this reads the message off the same run.
assert_says "missing sheet: ch04 goes to stderr" \
  '^[[:space:]]*missing sheet: ch04[[:space:]]*$' "$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== chapter 3: an absent starters/ is fine and silent =="
# ---------------------------------------------------------------------------

run_deliver "$SRC" 3 "$DEST_BARE"

assert_rc0 "chapter 3 delivery exits 0 with no starters/ in the source"

assert_not_delivered "no starters/ is invented in the destination" \
  "$DEST_BARE/ch03" "starters"

if [ "$RUN_RC" -ne 0 ]; then
  nope "an absent starters/ draws no warning. The run failed, rc=$RUN_RC"
elif grep -qE -- '(starters|[Ww]arning)' <<<"$RUN_ERR"; then
  nope "an absent starters/ draws no warning. Stderr said: $(tr '\n' ' ' <<<"$RUN_ERR")"
else
  ok "an absent starters/ draws no warning"
fi

# ---------------------------------------------------------------------------
echo
echo "== nothing in the destination is ever overwritten =="
# ---------------------------------------------------------------------------

# The practice tree is where the work happens, so a re-run that clobbers it
# destroys the only copy of the answers. Pre-seed a LOG.md with content no
# template would produce and require it back byte for byte.
mkdir -p "$DEST_KEEP/ch05"
printf 'my own notes, please do not clobber\n' >"$DEST_KEEP/ch05/LOG.md"
cp "$DEST_KEEP/ch05/LOG.md" "$TMPROOT/keeper-log.md"

run_deliver "$SRC" 5 "$DEST_KEEP"

assert_rc0 "a run over a pre-seeded LOG.md still exits 0"

assert_bytes "the pre-seeded LOG.md survives byte for byte" \
  "$DEST_KEEP/ch05/LOG.md" "$TMPROOT/keeper-log.md"

assert_says "the skipped LOG.md is reported on stdout" \
  '^[[:space:]]*skipped \(exists\): .*ch05/LOG\.md$' "$RUN_OUT"

# Now hand-edit two files the first run delivered and go round again. This is
# the shape of a real second run: the destination is already full.
#
# The mkdir is a no-op once the first run works. It is here so that a first run
# which delivered nothing gives this suite a clean red rather than a shell error
# from the setup, which reads as a broken test instead of a missing script.
mkdir -p "$DEST_KEEP/ch05/starters"
printf 'my answer to exercise 1\n' >"$DEST_KEEP/ch05/EXERCISES.md"
cp "$DEST_KEEP/ch05/EXERCISES.md" "$TMPROOT/keeper-exercises.md"
printf 'my work in progress\n' >"$DEST_KEEP/ch05/starters/Ex1.tla"
cp "$DEST_KEEP/ch05/starters/Ex1.tla" "$TMPROOT/keeper-starter.tla"

run_deliver "$SRC" 5 "$DEST_KEEP"

assert_rc0 "a second run over a full destination still exits 0"

assert_bytes "a hand-edited EXERCISES.md survives the second run" \
  "$DEST_KEEP/ch05/EXERCISES.md" "$TMPROOT/keeper-exercises.md"

assert_bytes "a hand-edited starter survives the second run" \
  "$DEST_KEEP/ch05/starters/Ex1.tla" "$TMPROOT/keeper-starter.tla"

assert_says "the skipped EXERCISES.md is reported on stdout" \
  '^[[:space:]]*skipped \(exists\): .*ch05/EXERCISES\.md$' "$RUN_OUT"

assert_says "the skipped starter is reported on stdout" \
  '^[[:space:]]*skipped \(exists\): .*ch05/starters/Ex1\.tla$' "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== both ends of the 2-11 range =="
# ---------------------------------------------------------------------------

run_deliver "$SRC" 2 "$DEST_LOW"

assert_rc0 "chapter 2 is in range"

assert_content "chapter 2 gets its EXERCISES.md" \
  "$DEST_LOW/ch02/EXERCISES.md" "EXERCISES for chapter 02"

# There is no chapter below 2, and 2's own sheet is still its own sheet.
assert_not_delivered "chapter 2 gets no sheet at all" \
  "$DEST_LOW/ch02" "cheatsheets/ch02.md"

run_deliver "$SRC" 11 "$DEST_HIGH"

assert_rc0 "chapter 11 is in range"

assert_content "chapter 11 gets the sheet from just below it" \
  "$DEST_HIGH/ch11/cheatsheets/ch10.md" "CHEATSHEET for chapter 10"

assert_not_delivered "chapter 11's own sheet never lands" \
  "$DEST_HIGH/ch11" "cheatsheets/ch11.md"

# ---------------------------------------------------------------------------
echo
echo "== a bad chapter argument is refused with usage =="
# ---------------------------------------------------------------------------

# No dest-root to pass here, which is why every run redirects HOME.
assert_rejects "no chapter argument at all"

assert_rejects "a non-integer chapter" abc "$DEST_REJECT"

assert_rejects "chapter 1, below the range" 1 "$DEST_REJECT"

assert_rejects "chapter 12, above the range" 12 "$DEST_REJECT"

# ---------------------------------------------------------------------------
echo
echo "== a broken source root is fatal =="
# ---------------------------------------------------------------------------

assert_source_error "a missing source chapter directory exits non-zero" \
  "$SRC_NOCHAP" 7 "$DEST_REJECT"

assert_source_error "a source chapter with no EXERCISES.md exits non-zero" \
  "$SRC_NOEX" 7 "$DEST_REJECT"

# ---------------------------------------------------------------------------
echo
echo "== structural: the templates and the suite registration =="
# ---------------------------------------------------------------------------

for t in CHEATSHEET EXERCISES LOG REVIEW-CHECKLIST; do
  if [ -f "$TEMPLATE_DIR/$t.md" ]; then
    ok "$TEMPLATE_DIR/$t.md exists"
  else
    nope "$TEMPLATE_DIR/$t.md does not exist"
  fi
done

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-deliver-exercises\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-deliver-exercises.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-deliver-exercises.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
