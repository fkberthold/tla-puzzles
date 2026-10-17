#!/usr/bin/env bash
# test-drill-runner.sh: executable spec for drill/drill.sh and for the runner
# half of scripts/deliver-drill.sh (bead tla-t9de).
#
# WHAT IT PINS
#
#   The queue is interleaved by index, alphabetical by family inside an index,
#   and derived from the tree rather than from a list. A first run with no
#   PROGRESS.tsv serves the first drill. done retires a drill. shaky retires it
#   from the current pass and returns it after every untried one, and not
#   before. shaky then done leaves it done, by recency. No line of the record
#   is ever rewritten. An explicit <family>/<item> beats the pointer. Nothing
#   is written outside the runner's own directory. And delivery places the
#   runner, refreshes a stale copy of it, leaves an existing PROMPT.md alone,
#   and never goes near PROGRESS.tsv.
#
#   Then, from bead tla-rzvk.2: --check and --hint ship a one-shot with no
#   tools at all. The invocation carries -p and --tools with an empty value,
#   the prompt arrives on STDIN rather than argv, the cwd is the slug directory
#   so the study config loads by itself, and the prompt carries the item's
#   PROMPT.md, the attempt's modules and configs, and the checker's output
#   verbatim. Which drill comes from LAST-SERVED, the way a mark's does, with
#   an optional explicit <family>/<item> on --check and none on --hint, whose
#   rest-of-line is the question. Every run prints the drill and the directory,
#   since that is the only thing between a stale pointer and a wasted read. The
#   cwd of the one-shot is the drill's own directory either way. Each of the
#   three new dependencies is refused with one message before anything is
#   executed, and the serve path works with none of them present.
#
#   Then, from bead tla-iiow.3: --style is a third coaching flag in the same
#   shape, and the two things that make it its own flag are pinned here. It
#   CATS THE REGISTER into the prompt, because a one-shot with no tools cannot
#   open drill/study/STYLE.md, and that makes the style prompt the largest of
#   the three. And it DOES NOT RUN THE CHECKER, so a style pass works over a
#   study root holding no checker at all. Its two new dependencies refuse the
#   same way the first three do, before the script is executed rather than
#   after, and the style script's own exit code never becomes the runner's.
#
#   Then, from bead tla-1sh7.1: --hint CATS ITS SHEET into the prompt, the way
#   --style cats the register and for the same reason. The ladder, the two
#   worked cases and the tiebreak live in
#   drill/study/.claude/commands/hint.md, which a one-shot under `--tools ""`
#   cannot open any more than it can open the register. The sheet is
#   hint-only, so neither a check prompt nor a style prompt carries it, and a
#   hint over a study root with no sheet in it refuses before the checker is
#   executed.
#
# ---------------------------------------------------------------------------
# WHY THE MUTANTS ARE HERE, AND WHY THEY ARE THE POINT
#
# Most of the rows below are of the form "the order came back the way the
# contract says", which is also what a suite driving a runner that silently
# stopped working would report if the comparison went slack. So part 5 copies
# the real runner, breaks ONE line of it, and requires the row that owns that
# line to go red. Ten mutants:
#
#   family-major order   the index drops out of the sort key
#   shaky retires        shaky behaves like done and never comes back
#   truncating record    the log is written rather than appended to
#   a pointer outside    LAST-SERVED lands one directory up
#   a fatal study mkdir  a creation that fails takes the serve with it
#   a claimed creation   every serve reports making the directory
#   a coached half-run   the checker gate drops out and it ships anyway
#   a prompt on argv     the prompt goes positional instead of on stdin
#   a styled half-run    the register gate drops out and it ships anyway
#   a hinted half-run    the sheet gate drops out and it ships anyway
#
# A mutant that passes means the row above it is vacuous. That is a stronger
# control than a planted fixture, because it exercises the real code path with
# one character changed rather than a stub that agrees to be caught.
#
# ---------------------------------------------------------------------------
# THE REAL PRACTICE TREE IS NEVER TOUCHED, AND THAT IS ASSERTED TWICE
#
# ~/tla-practice holds the only copy of the work done in it and has no git
# behind it. On 2026-10-02 a guessed manifest deleted 39 delivered files there.
# So this suite builds every tree it drives under a temp root, runs every
# invocation with HOME redirected into that root, and then asserts that the
# sandboxed HOME grew no tla-practice at all. The live assertion is backed by a
# static one: the runner's source resolves no HOME and names no practice tree,
# so it cannot reach the real one whatever a caller does.
#
# The real drill/ corpus IS read, under a view of symlinks, because the
# interleaving is worth asserting over the live tree and not only over a tidy
# fixture. The runner reads PROMPT.md and writes beside itself, so a symlink
# view puts its two writes in the temp root while its reads reach the repo.
#
# Usage:  harness/test-drill-runner.sh
# Exit:   0 if every assertion holds, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

RUNNER="$REPO_ROOT/drill/drill.sh"
DELIVER="$REPO_ROOT/scripts/deliver-drill.sh"
TEST_RUNNER_PRESENT=1
[ -f "$RUNNER" ] || TEST_RUNNER_PRESENT=0

TMPROOT=$(mktemp -d -t tla_drill_runner.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

SANDBOX_HOME="$TMPROOT/home"
mkdir -p "$SANDBOX_HOME"

# The literal to look for, built the way harness/test-deliver-drill.sh builds
# it. Nothing below reads this path. It exists so the rows can assert that no
# output and no source line names it.
REAL_PRACTICE="$HOME/tla-practice"

# ---------------------------------------------------------------------------
# Fixtures.
#
# Three families whose alphabetical order is NOT their creation order, so a
# row asserting alphabetical families inside an index fails on a runner that
# returns whatever the filesystem handed it. Three indices, so the
# interleaving has somewhere to go wrong.
# ---------------------------------------------------------------------------

FAM_CREATE_ORDER=(zeta mid alpha)
INDICES=(01 02 03)

# mk_tree <dir> <runner-source>
#
# A practice tree: nine drills and a runner, and nothing else. The runner is
# installed under the name it is delivered as, so every invocation below runs
# the same command Frank runs.
mk_tree() {
  local dir="$1" runner_src="$2" fam idx
  mkdir -p "$dir"
  for fam in "${FAM_CREATE_ORDER[@]}"; do
    for idx in "${INDICES[@]}"; do
      mkdir -p "$dir/$fam/$idx-$fam-drill"
      printf 'PROMPT BODY for %s/%s-%s-drill\n' "$fam" "$idx" "$fam" \
        >"$dir/$fam/$idx-$fam-drill/PROMPT.md"
    done
  done
  cp -- "$runner_src" "$dir/drill"
  chmod +x "$dir/drill"
}

# The canonical order the contract asks for, written out rather than computed,
# because a fixture expectation derived by the same rule the code uses proves
# nothing. Nine lines: 01 of every family, then 02, then 03.
CANONICAL=(
  "alpha/01-alpha-drill"
  "mid/01-mid-drill"
  "zeta/01-zeta-drill"
  "alpha/02-alpha-drill"
  "mid/02-mid-drill"
  "zeta/02-zeta-drill"
  "alpha/03-alpha-drill"
  "mid/03-mid-drill"
  "zeta/03-zeta-drill"
)

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

RUN_OUT=""
RUN_ERR=""
RUN_RC=0
ERRFILE="$TMPROOT/stderr"

# run_drill <tree> [args...]
#
# HOME is redirected on every single invocation. The runner resolves HOME for
# exactly one thing, the study root, and part 4 asserts that the lookup stays
# there. The redirection is the belt to that braces: the study directories a
# serve creates land in the sandbox rather than in Frank's own tree, whatever
# the resolution does.
run_drill() {
  local tree="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" "$tree/drill" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_drill_study <study-root> <tree> [args...]
#
# The same invocation with DRILL_STUDY_ROOT named explicitly, which is what
# part 4b drives. HOME stays redirected as well, so a run that ignored the
# variable would still miss the real tree rather than write into it.
run_drill_study() {
  local root="$1" tree="$2"
  shift 2
  RUN_OUT=$(HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$root" "$tree/drill" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_drill_rootless <tree> [args...]
#
# Neither DRILL_STUDY_ROOT nor HOME set, which is the case where no study root
# can be resolved at all. `env -u` rather than an assignment, because an empty
# HOME and an unset HOME are different things and this row wants unset.
run_drill_rootless() {
  local tree="$1"
  shift
  RUN_OUT=$(env -u HOME -u DRILL_STUDY_ROOT "$tree/drill" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# queue_of <tree>: the queue, one item per line, read out of `list`.
#
# The numbered rows carry three fields. The trailing summary carries four and
# the empty-queue sentence carries more, so a field count plus a numeric first
# field selects the rows and nothing else.
queue_of() {
  local tree="$1" out
  out=$(HOME="$SANDBOX_HOME" "$tree/drill" list 2>/dev/null)
  awk 'NF == 3 && $1 ~ /^[0-9]+$/ { print $2 }' <<<"$out"
}

# served_item <tree>: the item the last run served, read off its header line.
served_of() {
  local out="$1"
  awk '$1 == "==" { print $2; exit }' <<<"$out"
}

# snapshot <dir>: every path under a directory, with file contents, so a row
# can say that nothing changed rather than that no name changed.
snapshot() {
  local root="$1"
  [ -d "$root" ] || { printf '<absent>\n'; return; }
  (cd "$root" && find . -mindepth 1 | LC_ALL=C sort)
  (cd "$root" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s :: %s\n' "$f" "$(cat "$f")"
  done)
}

assert_eq() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    ok "$label"
  else
    nope "$label. Wanted [$(tr '\n' ' ' <<<"$want")] got [$(tr '\n' ' ' <<<"$got")]"
  fi
}

assert_ne() {
  local label="$1" a="$2" b="$3"
  if [ "$a" != "$b" ]; then
    ok "$label"
  else
    nope "$label. Both sides read [$(tr '\n' ' ' <<<"$a")], so the row above it is vacuous"
  fi
}

assert_rc() {
  local label="$1" want="$2"
  if [ "$RUN_RC" -eq "$want" ]; then
    ok "$label"
  else
    nope "$label (rc=$RUN_RC, wanted $want), stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  fi
}

assert_says_literal() {
  local label="$1" needle="$2" body="$3"
  if grep -qF -- "$needle" <<<"$body"; then
    ok "$label"
  else
    nope "$label. The output never said: $needle"
  fi
}

assert_never_names() {
  local label="$1" needle="$2" body="$3"
  if grep -qF -- "$needle" <<<"$body"; then
    nope "$label. It named: $needle"
  else
    ok "$label"
  fi
}

assert_absent() {
  if [ -e "$2" ]; then
    nope "$1. It exists: $2"
  else
    ok "$1"
  fi
}

if [ "$TEST_RUNNER_PRESENT" -eq 0 ]; then
  nope "drill/drill.sh exists. There is no runner at $RUNNER, so nothing below can run"
  printf "\nFAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
echo "== part 1: the queue is derived, interleaved by index, alphabetical inside one =="
# ---------------------------------------------------------------------------

T_ORDER="$TMPROOT/tree-order"
mk_tree "$T_ORDER" "$RUNNER"

assert_eq "the queue is 01 of every family, then 02, then 03" \
  "$(printf '%s\n' "${CANONICAL[@]}")" "$(queue_of "$T_ORDER")"

# The non-vacuity control for the row above. Creation order is zeta, mid,
# alpha, so a runner echoing the filesystem would agree with the expectation
# by accident only if the two happened to coincide.
assert_ne "the fixture's creation order is not the expected order" \
  "$(printf '%s\n' "${FAM_CREATE_ORDER[@]}")" "alpha
mid
zeta"

# Derived, never hardcoded: a tenth drill appears mid-suite and the queue has
# to grow by one without anything here being edited.
mkdir -p "$T_ORDER/alpha/04-alpha-late"
printf 'PROMPT BODY for a drill that landed mid-run\n' \
  >"$T_ORDER/alpha/04-alpha-late/PROMPT.md"
assert_eq "a drill that lands mid-run joins the queue at its index" \
  "$(printf '%s\n' "${CANONICAL[@]}" ; printf 'alpha/04-alpha-late\n')" \
  "$(queue_of "$T_ORDER")"
rm -rf "$T_ORDER/alpha/04-alpha-late"

# A directory that is not an item shape must not become one. The glob is
# */[0-9][0-9]-*/PROMPT.md, so neither of these qualifies, and asserting it
# here is what stops a future widening of the glob from swallowing the
# channel's own files.
mkdir -p "$T_ORDER/alpha/notes"
printf 'scratch\n' >"$T_ORDER/alpha/notes/PROMPT.md"
printf 'the channel README\n' >"$T_ORDER/README.md"
assert_eq "a directory with no NN- prefix is not a drill, and a root file is not either" \
  "$(printf '%s\n' "${CANONICAL[@]}")" "$(queue_of "$T_ORDER")"
rm -rf "$T_ORDER/alpha/notes" "$T_ORDER/README.md"

# ---------------------------------------------------------------------------
echo
echo "== part 1b: the same interleaving over the real drill/ corpus =="
# ---------------------------------------------------------------------------

# A view of symlinks, one per family. The runner's reads reach the repo and
# its two writes land in the temp root, so the real corpus is read and nothing
# in the repo is written.
REAL_VIEW="$TMPROOT/real-view"
mkdir -p "$REAL_VIEW"
while IFS= read -r fam_dir; do
  [ -n "$fam_dir" ] || continue
  ln -s -- "$fam_dir" "$REAL_VIEW/$(basename -- "$fam_dir")"
done < <(find "$REPO_ROOT/drill" -mindepth 1 -maxdepth 1 -type d \
  ! -name '.*' | LC_ALL=C sort)
cp -- "$RUNNER" "$REAL_VIEW/drill"
chmod +x "$REAL_VIEW/drill"

# The expectation comes from an independent walk, sorted on a key built a
# different way: find plus a sed that moves the index to the front. The runner
# sorts a tab-joined key it builds in bash, so the two mechanisms differ.
REAL_WANT=$(find "$REPO_ROOT/drill" -mindepth 3 -maxdepth 3 -name PROMPT.md \
  -printf '%P\n' |
  sed 's|^\([^/]*\)/\([0-9][0-9]\)-\([^/]*\)/PROMPT.md$|\2 \1/\2-\3|' |
  LC_ALL=C sort |
  cut -d' ' -f2)
REAL_GOT=$(queue_of "$REAL_VIEW")

assert_eq "the real corpus comes back interleaved by index" "$REAL_WANT" "$REAL_GOT"

REAL_N=$(grep -c '' <<<"$REAL_GOT")
if [ "$REAL_N" -ge 32 ]; then
  ok "the real corpus arm read $REAL_N drills, so it is not vacuous"
else
  nope "the real corpus arm read only $REAL_N drills, so the row above proves little"
fi

echo
echo "  the first 12 of the real queue:"
awk 'NR <= 12 { printf "    %2d  %s\n", NR, $0 }' <<<"$REAL_GOT"
echo

# ---------------------------------------------------------------------------
echo "== part 2: a first run with no record serves the first drill =="
# ---------------------------------------------------------------------------

T_FIRST="$TMPROOT/tree-first"
mk_tree "$T_FIRST" "$RUNNER"

assert_absent "the fixture starts with no record at all" "$T_FIRST/PROGRESS.tsv"
assert_absent "the fixture starts with no pointer either" "$T_FIRST/LAST-SERVED"

run_drill "$T_FIRST"
assert_rc "a first run exits 0 rather than complaining about a missing record" 0
assert_eq "a first run serves the head of the queue" "${CANONICAL[0]}" "$(served_of "$RUN_OUT")"
assert_says_literal "a first run prints the drill's own prompt" \
  "PROMPT BODY for alpha/01-alpha-drill" "$RUN_OUT"
assert_says_literal "a first run says how to mark it" "./drill done" "$RUN_OUT"
assert_absent "serving writes no record, because serving is not a mark" "$T_FIRST/PROGRESS.tsv"

run_drill "$T_FIRST"
assert_eq "serving twice without a mark serves the same drill" \
  "${CANONICAL[0]}" "$(served_of "$RUN_OUT")"

# ---------------------------------------------------------------------------
echo
echo "== part 3: the two marks, the resurfacing, and recency =="
# ---------------------------------------------------------------------------

T_MARK="$TMPROOT/tree-mark"
mk_tree "$T_MARK" "$RUNNER"

run_drill "$T_MARK"
run_drill "$T_MARK" "done"
assert_rc "done exits 0" 0
assert_says_literal "done names what it retired" "done: ${CANONICAL[0]}" "$RUN_OUT"
assert_eq "done serves the next drill in the same breath" \
  "${CANONICAL[1]}" "$(served_of "$RUN_OUT")"

Q_AFTER_DONE=$(queue_of "$T_MARK")
assert_never_names "a done drill is out of the queue" "${CANONICAL[0]}" "$Q_AFTER_DONE"
assert_eq "and the rest of the queue is unchanged" \
  "$(printf '%s\n' "${CANONICAL[@]:1}")" "$Q_AFTER_DONE"

run_drill "$T_MARK" shaky
assert_rc "shaky exits 0" 0
assert_says_literal "shaky names what it set aside" "shaky: ${CANONICAL[1]}" "$RUN_OUT"
assert_eq "shaky serves the next drill too" "${CANONICAL[2]}" "$(served_of "$RUN_OUT")"

Q_AFTER_SHAKY=$(queue_of "$T_MARK")
assert_eq "a shaky drill is out of the current pass and back at the end of the queue" \
  "$(printf '%s\n' "${CANONICAL[@]:2}" ; printf '%s\n' "${CANONICAL[1]}")" \
  "$Q_AFTER_SHAKY"

# THE RESURFACING ROW. The brief calls this the one most likely to be written
# wrong, so it is driven rather than inspected: every untried drill is marked
# done, and the shaky one has to be what comes back, on the run after the LAST
# untried one and not before.
RESURFACED_EARLY=0
SERVED_LOG=""
for _ in "${CANONICAL[@]:2}"; do
  run_drill "$T_MARK" "done"
  SERVED_LOG="$SERVED_LOG$(served_of "$RUN_OUT")
"
done
# Seven untried drills remained when the loop started, so the first six runs
# serve untried ones and the seventh serves the shaky one.
SERVED_EARLY=$(awk 'NR <= 6' <<<"$SERVED_LOG")
SERVED_LAST=$(awk 'NR == 7' <<<"$SERVED_LOG")
if grep -qF -- "${CANONICAL[1]}" <<<"$SERVED_EARLY"; then
  RESURFACED_EARLY=1
fi
if [ "$RESURFACED_EARLY" -eq 0 ]; then
  ok "the shaky drill does not come back while an untried one is left"
else
  nope "the shaky drill came back before the untried ones ran out: $(tr '\n' ' ' <<<"$SERVED_EARLY")"
fi
assert_eq "the shaky drill comes back on the run after the last untried one" \
  "${CANONICAL[1]}" "$SERVED_LAST"
assert_says_literal "and the run says why it is back" "You marked this one shaky" "$RUN_OUT"

# RECENCY. shaky then done leaves it done, with no line rewritten.
run_drill "$T_MARK" "done"
assert_rc "done over a shaky drill exits 0" 0
assert_eq "the queue is empty once the shaky drill is got" "" "$(queue_of "$T_MARK")"
assert_says_literal "and the run says so" "The queue is empty" "$RUN_OUT"

MARK_LINES=$(grep -cF -- "${CANONICAL[1]}" "$T_MARK/PROGRESS.tsv")
if [ "$MARK_LINES" -eq 2 ]; then
  ok "the shaky drill carries two lines in the record, not one rewritten line"
else
  nope "the shaky drill carries $MARK_LINES line(s) in the record, wanted 2"
fi
assert_says_literal "the earlier shaky line is still there, byte for byte" \
  "	shaky	${CANONICAL[1]}" "$(cat "$T_MARK/PROGRESS.tsv")"
assert_says_literal "and the later done line sits after it" \
  "	done	${CANONICAL[1]}" "$(cat "$T_MARK/PROGRESS.tsv")"

# Every line carries a timestamp, whether or not anything reads it yet.
STAMPED=$(awk -F'\t' '$1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/' \
  "$T_MARK/PROGRESS.tsv" | grep -c '')
ALL_LINES=$(grep -c '' "$T_MARK/PROGRESS.tsv")
if [ "$STAMPED" -eq "$ALL_LINES" ] && [ "$ALL_LINES" -gt 0 ]; then
  ok "all $ALL_LINES record lines carry an ISO 8601 timestamp"
else
  nope "$STAMPED of $ALL_LINES record lines carry an ISO 8601 timestamp"
fi

# APPEND-ONLY, asserted as a prefix rather than as a line count. A run that
# rewrote an early line while adding a late one keeps the count right.
T_APPEND="$TMPROOT/tree-append"
mk_tree "$T_APPEND" "$RUNNER"
run_drill "$T_APPEND"
run_drill "$T_APPEND" shaky
APPEND_FIRST=$(cat "$T_APPEND/PROGRESS.tsv")
run_drill "$T_APPEND" "done"
run_drill "$T_APPEND" shaky
APPEND_LATER=$(cat "$T_APPEND/PROGRESS.tsv")
APPEND_PREFIX=$(awk -v n="$(grep -c '' <<<"$APPEND_FIRST")" 'NR <= n' <<<"$APPEND_LATER")
assert_eq "every earlier line survives a later mark, byte for byte" \
  "$APPEND_FIRST" "$APPEND_PREFIX"
if [ "$(grep -c '' <<<"$APPEND_LATER")" -eq 3 ]; then
  ok "and the record grew to 3 lines, so the comparison above is not vacuous"
else
  nope "the record holds $(grep -c '' <<<"$APPEND_LATER") line(s) after three marks, wanted 3"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 3b: an explicit drill name beats the pointer =="
# ---------------------------------------------------------------------------

T_ARG="$TMPROOT/tree-arg"
mk_tree "$T_ARG" "$RUNNER"
run_drill "$T_ARG"
assert_eq "the pointer holds the drill that was served" \
  "${CANONICAL[0]}" "$(cat "$T_ARG/LAST-SERVED")"

run_drill "$T_ARG" "done" "${CANONICAL[4]}"
assert_rc "done with an explicit drill name exits 0" 0
assert_says_literal "it marks the drill it was handed" "done: ${CANONICAL[4]}" "$RUN_OUT"
assert_never_names "and not the one the pointer named" "done: ${CANONICAL[0]}" "$RUN_OUT"
assert_never_names "so the pointed-at drill is still in the queue" \
  "${CANONICAL[4]}" "$(queue_of "$T_ARG")"
assert_says_literal "while the pointed-at drill is untouched" \
  "${CANONICAL[0]}" "$(queue_of "$T_ARG")"

# A name that is not a drill is refused rather than written, so the record
# never holds an entry for something that does not exist.
T_BAD="$TMPROOT/tree-bad"
mk_tree "$T_BAD" "$RUNNER"
run_drill "$T_BAD" "done" "alpha/99-not-a-drill"
assert_rc "a drill name that is not in the tree is refused" 1
assert_absent "and nothing is written for it" "$T_BAD/PROGRESS.tsv"
assert_says_literal "the refusal says what to run instead" "./drill list" "$RUN_ERR"

# A mark before anything has been served has nothing to attach to.
run_drill "$T_BAD" "done"
assert_rc "a mark with no pointer and no argument is refused" 1
assert_absent "and still nothing is written" "$T_BAD/PROGRESS.tsv"

# status and list take no argument, and neither writes.
STATUS_BEFORE=$(snapshot "$T_BAD")
run_drill "$T_BAD" status
assert_rc "status exits 0 over a tree with no record" 0
assert_says_literal "status counts the untried ones" "untried  9" "$RUN_OUT"
run_drill "$T_BAD" list
assert_rc "list exits 0 over a tree with no record" 0
assert_eq "neither status nor list writes anything" "$STATUS_BEFORE" "$(snapshot "$T_BAD")"

run_drill "$T_BAD" status "alpha/01-alpha-drill"
assert_rc "status refuses an argument" 1
run_drill "$T_BAD" wibble
assert_rc "an unknown command is refused" 1

# ---------------------------------------------------------------------------
echo
echo "== part 4: the runner writes two paths, both beside itself =="
# ---------------------------------------------------------------------------

mkdir -p "$TMPROOT/foot-outer"
mk_tree "$TMPROOT/foot-outer/tree" "$RUNNER"
T_FOOT="$TMPROOT/foot-outer/tree"
printf 'a sibling file the runner has no business touching\n' \
  >"$TMPROOT/foot-outer/SIBLING.md"

# paths_of <dir>: every path under a directory, relative and sorted, which is
# what comm needs. snapshot() interleaves two sorted sections and comm reads
# that as unsorted.
paths_of() {
  (cd "$1" && find . -mindepth 1 | LC_ALL=C sort)
}

FOOT_PATHS_BEFORE=$(paths_of "$TMPROOT/foot-outer")

run_drill "$T_FOOT"
run_drill "$T_FOOT" shaky
run_drill "$T_FOOT" "done"
run_drill "$T_FOOT" status
run_drill "$T_FOOT" list

# LC_ALL=C on comm as well as on the sorts, because comm checks sortedness
# against LC_COLLATE and a UTF-8 locale orders these differently from the C
# locale the lists were sorted in. Without it comm warns and drops lines.
FOOT_NEW_PATHS=$(LC_ALL=C comm -13 <(printf '%s\n' "$FOOT_PATHS_BEFORE") \
  <(paths_of "$TMPROOT/foot-outer"))
assert_eq "five runs create exactly PROGRESS.tsv and LAST-SERVED, both inside the tree" \
  "./tree/LAST-SERVED
./tree/PROGRESS.tsv" "$FOOT_NEW_PATHS"

assert_says_literal "the sibling file one directory up is still there" \
  "./SIBLING.md" "$(snapshot "$TMPROOT/foot-outer")"
assert_absent "nothing landed one directory up" "$TMPROOT/foot-outer/PROGRESS.tsv"
assert_absent "and no pointer landed there either" "$TMPROOT/foot-outer/LAST-SERVED"

# The prompts are read and never written. A runner that rewrote one would be
# writing over the learner's page.
PROMPT_NOW=$(cat "$T_FOOT/alpha/01-alpha-drill/PROMPT.md")
assert_eq "a served prompt is unchanged after being served" \
  "PROMPT BODY for alpha/01-alpha-drill" "$PROMPT_NOW"

# THE REAL TREE, live and static. The sandboxed HOME has to be untouched, and
# the runner's HOME lookups have to stay in the one place that needs them.
assert_absent "the sandboxed HOME grew no practice tree, over every run above" \
  "$SANDBOX_HOME/tla-practice"

# CODE, not prose. The runner's header explains at length where it writes and
# that ~/tla-practice has no git behind it, so matching raw text would flag
# the explanation. Whole-line comments come out first, the same way
# harness/test-pipefail.sh strips them before its own ban.
RUNNER_CODE=$(sed 's/^[[:space:]]*#.*$//' "$RUNNER")

# THIS ROW WAS NARROWED, AND THE OLD FORM IS WHY IT NEEDS SAYING. It used to
# read "the runner resolves no HOME" and required zero lookups, which was true
# until bead tla-ytv2.1 gave a serve one write outside the runner's own
# directory: the study directory, under a root defaulting to
# $HOME/Study/tla-drills. Deleting the row with the invariant would have left
# the file with no static guard on HOME at all.
#
# So the question changed from "are there none" to "are they all in the one
# place". Every code line naming HOME must also name the study root, which is
# what stops a HOME lookup from spreading to the record, the pointer or the
# prompt reads, which are the three paths the header still confines to $HERE.
HOME_LINES=$(grep -E -- '\$\{?HOME' <<<"$RUNNER_CODE")
HOME_STRAY=$(grep -vE -- 'STUDY_ROOT' <<<"$HOME_LINES")
if [ -z "$HOME_STRAY" ]; then
  ok "every HOME lookup in the runner sits in the study-root resolution"
else
  nope "the runner resolves HOME away from the study root: $(tr '\n' ' ' <<<"$HOME_STRAY")"
fi

# And the narrowing is pinned to the thing that caused it. A runner that
# stopped resolving HOME for the study root would pass the row above
# vacuously, since a stray set is empty when the whole set is.
if grep -qE -- 'STUDY_ROOT.*\$\{?HOME' <<<"$HOME_LINES"; then
  ok "and the lookup that is there resolves the study root, so the row above is not empty"
else
  nope "the runner resolves no HOME for a study root, so the narrowed row above holds over nothing"
fi

assert_never_names "and no code line of it names a practice tree path" \
  "tla-practice" "$RUNNER_CODE"

# The controls for the rows above. Both patterns have to bite real code and
# neither may bite a comment, or the rows are green over nothing.
#
# The single quotes are load-bearing in both fixtures. Each one is a line of
# SOURCE TEXT that the scan reads back, so expanding it here would write
# whatever this shell holds in HOME into the fixture and blank the thing being
# detected.
# shellcheck disable=SC2016
CTRL_CODE='DEST="$HOME/tla-practice/drill"'
# shellcheck disable=SC2016
CTRL_COMMENT='  # the default comes from $HOME'

if grep -qE -- '\$\{?HOME' <<<"$CTRL_CODE"; then
  ok "control: the HOME pattern detects a HOME lookup in code"
else
  nope "control: the HOME pattern matched nothing, so the row above it is vacuous"
fi

# The control for the narrowing itself: a HOME lookup that is NOT in the
# study-root resolution has to come back as a stray. Without this the stray
# row passes over any runner at all, since a filter that matches everything
# leaves nothing behind.
CTRL_STRAY=$(grep -vE -- 'STUDY_ROOT' <<<"$(grep -E -- '\$\{?HOME' <<<"$CTRL_CODE")")
if [ -n "$CTRL_STRAY" ]; then
  ok "control: a HOME lookup outside the study root is DETECTED as a stray"
else
  nope "control: a stray HOME lookup was not detected, so the stray row above is vacuous"
fi

# The strip runs over a FILE, the way it does against the real runner above. A
# sed over a here-string would be a different mechanism from the one under
# test, and shellcheck reads it as a string substitution besides.
printf '%s\n' "$CTRL_COMMENT" >"$TMPROOT/ctrl-comment.sh"
if grep -qE -- '\$\{?HOME' <<<"$(sed 's/^[[:space:]]*#.*$//' "$TMPROOT/ctrl-comment.sh")"; then
  nope "control: a commented HOME tripped the strip, so the row above cries wolf on its own header"
else
  ok "control: a commented HOME does not trip the strip"
fi

assert_never_names "no run has named the real practice tree" \
  "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== part 4b: the study directory, which is the one write outside the tree =="
# ---------------------------------------------------------------------------
#
# WHY THIS IS ITS OWN PART rather than more rows in part 4. Part 4's question
# is what the runner writes BESIDE ITSELF, and its comm against the fixture's
# parent directory answers it. The study directory is the deliberate exception
# to that confinement, so asserting it there would read as part 4 contradicting
# itself. Here the root is named explicitly on every run and starts empty, so
# each row sees only what the run under it created.
#
# THE SLUG IS THE ITEM WITH THE FAMILY STRIPPED, and the tree is flat. All 64
# delivered slugs are distinct across the eight families, so a flat per-slug
# directory cannot collide and the name needs no family to disambiguate it.
#
# THREE BEHAVIORS, AND THE THIRD IS THE ONE WORTH BEING DELIBERATE ABOUT.
# Creating the directory is a convenience and serving the drill is the job, so
# a creation that fails warns and serves anyway. A serve that exited non-zero
# because a directory could not be made would cost Frank the prompt he asked
# for, over something he can fix with one mkdir.

T_STUDY="$TMPROOT/study-tree"
mk_tree "$T_STUDY" "$RUNNER"

SLUG0="${CANONICAL[0]##*/}"
assert_eq "the slug under test is the item with its family stripped" \
  "01-alpha-drill" "$SLUG0"

# --- a new directory is created, and the served block names it --------------

STUDY_A="$TMPROOT/study-root-a"
mkdir -p "$STUDY_A"
assert_absent "the study root starts with no directory for the queue head" \
  "$STUDY_A/$SLUG0"

run_drill_study "$STUDY_A" "$T_STUDY"
assert_rc "a serve into an empty study root exits 0" 0
if [ -d "$STUDY_A/$SLUG0" ]; then
  ok "the serve created the study directory for the drill it served"
else
  nope "the serve created no directory at $STUDY_A/$SLUG0"
fi
assert_says_literal "and the served block names the path to work in" \
  "$STUDY_A/$SLUG0" "$RUN_OUT"
assert_says_literal "and says it created it, the first time" "created" "$RUN_OUT"
assert_says_literal "and the prompt is still served alongside it" \
  "PROMPT BODY for ${CANONICAL[0]}" "$RUN_OUT"

# The tree is flat, so the family must not appear as a directory of its own.
# This is the row that goes red on a slug built from the whole item name.
assert_eq "the study root holds exactly the one slug directory, with no family above it" \
  "./$SLUG0" "$(paths_of "$STUDY_A")"

# --- an existing directory is left completely alone -------------------------
#
# Frank already has real work in 01-slip-on-the-spike. A second serve of the
# same head must not touch a byte of it, and must not claim a creation it did
# not perform.

printf 'CONSTANT N\nVARIABLE x\n' >"$STUDY_A/$SLUG0/pickers.tla"
printf 'SPECIFICATION Spec\n' >"$STUDY_A/$SLUG0/pickers.cfg"
STUDY_BEFORE=$(snapshot "$STUDY_A/$SLUG0")

# The non-vacuity control for the byte-for-byte row below. snapshot() of a
# directory that is not there reads `<absent>`, and `<absent>` compares equal
# to itself, so without this row the comparison is green over a directory the
# runner never made.
assert_says_literal "the existing-directory fixture really holds a file to leave alone" \
  "./pickers.tla :: CONSTANT N" "$STUDY_BEFORE"

run_drill_study "$STUDY_A" "$T_STUDY"
assert_rc "a second serve over an existing study directory exits 0" 0
assert_eq "it serves the same head, so the row below is about the same directory" \
  "${CANONICAL[0]}" "$(served_of "$RUN_OUT")"
assert_eq "every file in the existing study directory is untouched, byte for byte" \
  "$STUDY_BEFORE" "$(snapshot "$STUDY_A/$SLUG0")"
assert_says_literal "it still names the path to work in" \
  "$STUDY_A/$SLUG0" "$RUN_OUT"
assert_never_names "and it does not claim to have created anything" \
  "created" "$RUN_OUT"

# --- a root that cannot hold a directory warns and serves anyway ------------

STUDY_FILE="$TMPROOT/study-root-is-a-file"
printf 'a regular file where a study root was expected\n' >"$STUDY_FILE"
POINTER_BEFORE=$(cat "$T_STUDY/LAST-SERVED")

run_drill_study "$STUDY_FILE" "$T_STUDY"
assert_rc "a study root that is a regular file still exits 0" 0
assert_says_literal "the prompt is still printed" \
  "PROMPT BODY for ${CANONICAL[0]}" "$RUN_OUT"
assert_says_literal "the pointer is still written" \
  "${CANONICAL[0]}" "$(cat "$T_STUDY/LAST-SERVED")"
assert_eq "and the pointer holds the item, not a diagnostic" \
  "$POINTER_BEFORE" "$(cat "$T_STUDY/LAST-SERVED")"
if [ -n "$RUN_ERR" ]; then
  ok "the failure to create warns on stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
else
  nope "the failure to create said nothing on stderr, so the serve looks clean when it is not"
fi
assert_says_literal "and the warning on stderr names the path it could not make" \
  "$STUDY_FILE/$SLUG0" "$RUN_ERR"
assert_never_names "a failed creation is not reported on stdout as a success" \
  "created" "$RUN_OUT"
if [ -f "$STUDY_FILE" ]; then
  ok "the regular file standing in for a root is still a regular file"
else
  nope "the run replaced the regular file at $STUDY_FILE"
fi

# --- no root resolvable at all: no DRILL_STUDY_ROOT and no HOME -------------
#
# The default root comes off HOME, so an unset HOME leaves nothing to default
# to. Guessing at / would be worse than saying so.

run_drill_rootless "$T_STUDY"
assert_rc "a serve with neither DRILL_STUDY_ROOT nor HOME set still exits 0" 0
assert_says_literal "and still prints the prompt" \
  "PROMPT BODY for ${CANONICAL[0]}" "$RUN_OUT"
if [ -n "$RUN_ERR" ]; then
  ok "and says on stderr that it has no study root: $(tr '\n' ' ' <<<"$RUN_ERR")"
else
  nope "it resolved no study root and said nothing about it"
fi
assert_says_literal "the warning names the variable that would fix it" \
  "DRILL_STUDY_ROOT" "$RUN_ERR"

# --- the default root, which is the form Frank actually runs ----------------
#
# HOME is the sandbox on every run_drill call, so this asserts the default
# over a redirected HOME rather than over Frank's own.

T_DEFAULT="$TMPROOT/study-tree-default"
mk_tree "$T_DEFAULT" "$RUNNER"
run_drill "$T_DEFAULT"
assert_rc "a serve with no DRILL_STUDY_ROOT exits 0" 0
if [ -d "$SANDBOX_HOME/Study/tla-drills/$SLUG0" ]; then
  ok "it defaults the root to \$HOME/Study/tla-drills"
else
  nope "no directory at $SANDBOX_HOME/Study/tla-drills/$SLUG0, so the default root is somewhere else"
fi
assert_says_literal "and names that default path in the served block" \
  "$SANDBOX_HOME/Study/tla-drills/$SLUG0" "$RUN_OUT"

# --- the header carries the narrowed invariant ------------------------------
#
# Gate, don't advise. The runner's header is its contract with its next
# reader, and a header promising it writes nothing outside its own directory
# while a serve creates a directory elsewhere is a trap rather than a
# document. These rows are over the header block alone, cut at the first line
# of code the way part 7 cuts it.

STUDY_RUNNER_HEAD=$(awk '/^set -uo pipefail/ { exit } { print }' "$RUNNER")
assert_says_literal "the runner's header names the study root variable" \
  "DRILL_STUDY_ROOT" "$STUDY_RUNNER_HEAD"
assert_says_literal "and names the default the variable overrides" \
  "Study/tla-drills" "$STUDY_RUNNER_HEAD"
# Single-quoted: this is a line of the runner's SOURCE TEXT read back, so an
# expansion here would put this suite's own path into the needle and the row
# would be asserting nothing about the runner.
# shellcheck disable=SC2016
STUDY_HEAD_NEEDLE='${BASH_SOURCE[0]}'
assert_says_literal "and the header still argues the confinement it narrows" \
  "$STUDY_HEAD_NEEDLE" "$STUDY_RUNNER_HEAD"

# ---------------------------------------------------------------------------
echo
echo "== part 4c: --check and --hint, a one-shot with no tools =="
# ---------------------------------------------------------------------------
#
# NO ROW BELOW CALLS A REAL MODEL, AND NO ROW RUNS TLC. Two stubs stand in: a
# `claude` first on PATH that records its argv, its stdin and the directory it
# ran from, and a `check` at the study root that prints two known lines and
# exits with a code this suite picks. Every gate here runs offline, and a suite
# that reached out to a model would be neither offline nor repeatable.
#
# THE RECORDER FILES ARE WHAT KEEPS THE STUB HONEST. Each row that expects the
# model to be called asserts that the recording landed, so an invocation that
# somehow reached a different binary reddens the row rather than passing
# quietly. Each row that expects NO call asserts the recording is absent, and
# the rows above it are the control for that: the same stub, the same path, one
# file that appears when claude runs and does not when it does not.
#
# WHY ARGV IS RECORDED ONE BRACKETED ELEMENT PER LINE. `--tools ""` ends the
# command line with an EMPTY argument, and a bare newline for it would be eaten
# by the command substitution that reads the file back. `ARG[]` survives, so
# the row can assert the empty value is there as its own element rather than
# absent.

STUB_BIN="$TMPROOT/stub-bin"
mkdir -p "$STUB_BIN"
STUB_REC="$TMPROOT/stub-rec"
mkdir -p "$STUB_REC"

cat >"$STUB_BIN/claude" <<'CLAUDE_STUB'
#!/usr/bin/env bash
# The stand-in for the model. It reads no file of its own and reaches no
# network. CLAUDE_STUB_REC is required rather than defaulted, so a run that
# forgot to set it fails loudly instead of recording into nowhere.
rec="${CLAUDE_STUB_REC:?the claude stub needs CLAUDE_STUB_REC}"
: >"$rec.argv"
for a in "$@"; do printf 'ARG[%s]\n' "$a" >>"$rec.argv"; done
printf '%s\n' "$#" >"$rec.argc"
printf '%s\n' "$PWD" >"$rec.cwd"
cat >"$rec.stdin"
printf 'STUB MODEL SPOKE\n'
exit "${CLAUDE_STUB_RC:-0}"
CLAUDE_STUB
chmod +x "$STUB_BIN/claude"

# The checker stub. It writes on BOTH streams, because the runner joins them
# and a row below asserts the stderr line reached the model.
#
# TWO MODULE LINES, AND THE SECOND ONE IS THE POINT. It carries the absent
# marker in three fields, which is `-` and not `none`: the contract locked on
# bead tla-rzvk uses one marker everywhere, and tla-rzvk.1 brought the
# checker's old spelling into line with it. A stub printing the old spelling
# would be a fixture the real checker no longer matches.
write_check_stub() {
  cat >"$1" <<'CHECK_STUB'
#!/usr/bin/env bash
rec="${CHECK_STUB_REC:?the check stub needs CHECK_STUB_REC}"
: >"$rec.argv"
for a in "$@"; do printf 'ARG[%s]\n' "$a" >>"$rec.argv"; done
printf '%s\n' "$PWD" >"$rec.cwd"
printf '%s\n' "${DRILL_PROMPT_ROOT:-<unset>}" >"$rec.promptroot"
printf 'module=Pickers rc=0 distinct=12 claimed=12 count=MATCH run=CLEAN invariant=-\n'
printf 'module=Hoist rc=3 distinct=- claimed=- count=NONE run=NOCOUNT invariant=-\n'
printf 'MATCHED: 1 of 1 module(s) reached a count the prompt publishes.\n'
printf 'a line the checker wrote on stderr\n' >&2
exit "${CHECK_STUB_RC:-0}"
CHECK_STUB
  chmod +x "$1"
}

# The style stub, in the checker's shape and for the same reasons. It writes
# on both streams, because the runner joins them and a row below asserts the
# stderr line reached the model.
#
# ONE FACT LINE PER AXIS, which is the contract bead tla-iiow.2 locks: the
# script measures and the model interprets, so every line carries a measured
# value and the survey count beside it and no verdict at all. Two lines, so a
# row can say every line arrived rather than only the first.
write_style_stub() {
  cat >"$1" <<'STYLE_STUB'
#!/usr/bin/env bash
rec="${STYLE_STUB_REC:?the style stub needs STYLE_STUB_REC}"
: >"$rec.argv"
for a in "$@"; do printf 'ARG[%s]\n' "$a" >>"$rec.argv"; done
printf '%s\n' "$PWD" >"$rec.cwd"
printf '%s\n' "${DRILL_PROMPT_ROOT:-<unset>}" >"$rec.promptroot"
printf 'axis=constant-case module=Pickers camel=0 snake=2 lower=0 corpus=126of132\n'
printf 'axis=spec-name module=Pickers measured=Spec corpus=170of205\n'
printf 'a line the style script wrote on stderr\n' >&2
exit "${STYLE_STUB_RC:-0}"
STYLE_STUB
  chmod +x "$1"
}

# The register, which is PROSE the one-shot cannot read off disk, since it
# runs with no tools. Its sentinel is a whole sentence rather than a token, so
# a row asserting it arrived is asserting the file's body and not a filename
# the runner could have printed on its own.
STYLE_REGISTER_SENTINEL="C1: 405 of 421 resolvable box sites cover every variable."
write_style_register() {
  printf '%s\n' \
    '# The style register, fixture copy' \
    "$STYLE_REGISTER_SENTINEL" \
    'C2: Specifying Systems 14.5.3 p. 259, so TLC names the conjunct.' >"$1"
}

# The hint sheet, which is the register's shape with one file swapped: prose
# the one-shot cannot read off disk, because it runs with no tools. Bead
# tla-1sh7.1.
#
# THE PATH IS HIDDEN, and that is where Claude Code reads a project command
# from and where scripts/deliver-drill.sh puts it. The writer makes the
# directory, since a fixture root that has never been delivered to has no
# .claude in it at all.
#
# Its sentinel is a whole sentence rather than a token, so a row asserting it
# arrived is asserting the file's body and not a path the runner could have
# printed on its own.
HINT_SHEET_REL=".claude/commands/hint.md"
HINT_SHEET_SENTINEL="Would answering in full still leave him the item's work?"
write_hint_sheet() {
  mkdir -p "${1%/*}"
  printf '%s\n' \
    '# The hint sheet, fixture copy' \
    "$HINT_SHEET_SENTINEL" \
    "When you cannot tell which kind it is, answer the mechanism flat." >"$1"
}

# run_coach_path <path> <study-root> <cwd> <tree> [args...]
#
# The recorder is cleared first, so every "no model was called" row below is
# about the run under it rather than about a file an earlier run left behind.
# COACH_CHECK_RC is what the checker stub will exit with. It is a global rather
# than a parameter because exactly one row varies it, and the runner is not
# supposed to care either way.
COACH_CHECK_RC=0
# What the style stub will exit with. Style has no pass and no fail by
# contract (bead tla-iiow.2: 0 when it measured anything, 3 when it could not
# run, and no 1 at all), so the runner is not supposed to care either way and
# one row varies this to say so.
COACH_STYLE_RC=0

run_coach_path() {
  local path="$1" root="$2" dir="$3" tree="$4"
  shift 4
  rm -f "$STUB_REC"/*
  RUN_OUT=$(cd "$dir" && HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$root" \
    PATH="$path" CLAUDE_STUB_REC="$STUB_REC/claude" \
    CHECK_STUB_REC="$STUB_REC/check" CHECK_STUB_RC="$COACH_CHECK_RC" \
    STYLE_STUB_REC="$STUB_REC/style" STYLE_STUB_RC="$COACH_STYLE_RC" \
    "$tree/drill" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_coach <study-root> <cwd> <tree> [args...]: the ordinary form, with the
# stub directory first on PATH and the real one behind it, so the runner still
# finds cat, sort, date and mkdir.
run_coach() {
  local root="$1" dir="$2" tree="$3"
  shift 3
  run_coach_path "$STUB_BIN:$PATH" "$root" "$dir" "$tree" "$@"
}

# run_coach_rootless <cwd> <tree> [args...]: no DRILL_STUDY_ROOT and no HOME,
# which is the case where no study root can be resolved at all. `env -u`
# rather than an assignment, because an empty HOME and an unset HOME are
# different things and this row wants unset.
run_coach_rootless() {
  local dir="$1" tree="$2"
  shift 2
  rm -f "$STUB_REC"/*
  RUN_OUT=$(cd "$dir" && env -u HOME -u DRILL_STUDY_ROOT \
    PATH="$STUB_BIN:$PATH" CLAUDE_STUB_REC="$STUB_REC/claude" \
    CHECK_STUB_REC="$STUB_REC/check" STYLE_STUB_REC="$STUB_REC/style" \
    "$tree/drill" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

T_COACH="$TMPROOT/coach-tree"
mk_tree "$T_COACH" "$RUNNER"

STUDY_COACH="$TMPROOT/coach-study"
ATTEMPT_DIR="$STUDY_COACH/$SLUG0"
mkdir -p "$ATTEMPT_DIR"
write_check_stub "$STUDY_COACH/check"
write_style_stub "$STUDY_COACH/style"
write_style_register "$STUDY_COACH/STYLE.md"
write_hint_sheet "$STUDY_COACH/$HINT_SHEET_REL"

printf '%s\n' '---- MODULE Pickers ----' 'VARIABLE held' 'Init == held = 0' '====' \
  >"$ATTEMPT_DIR/Pickers.tla"
printf 'SPECIFICATION Spec\nINVARIANT TypeOK\n' >"$ATTEMPT_DIR/Pickers.cfg"
# Three files that are NOT the attempt. The first is TLC's own output, the
# second is a superseded go, the third is neither a module nor a config.
printf 'a trace dump TLC wrote\n' >"$ATTEMPT_DIR/Pickers_TTrace_1760000000.tla"
printf 'an earlier go at it\n' >"$ATTEMPT_DIR/Pickers.tla.old"
printf 'scratch notes to himself\n' >"$ATTEMPT_DIR/NOTES.md"

# A second drill with an attempt of its own, which is what the explicit
# override below is aimed at.
OVERRIDE_ITEM="${CANONICAL[2]}"
OVERRIDE_DIR="$STUDY_COACH/${OVERRIDE_ITEM##*/}"
mkdir -p "$OVERRIDE_DIR"
printf '%s\n' '---- MODULE Ballast ----' 'VARIABLE n' 'Init == n = 0' '====' \
  >"$OVERRIDE_DIR/Ballast.tla"

# Somewhere to stand that is not a drill directory. Nothing below depends on
# the cwd deciding anything, and two rows depend on it deciding nothing.
OUTSIDE="$TMPROOT/coach-elsewhere"
mkdir -p "$OUTSIDE"

# --- LAST-SERVED IS THE RESOLUTION, so a serve comes first ------------------
#
# This mirrors `done` and `shaky` exactly, and the argument that it should not
# was mine and was wrong. The two-terminal drift case is why a MARK takes an
# explicit name, and a mark writes the record, so being wrong corrupts the log.
# A check only reads, so being wrong costs ten seconds and the printed drill
# name shows it. Frank also lands at the study ROOT rather than inside a slug
# directory, so resolving off the cwd would have forced a cd he does not need.

run_drill_study "$STUDY_COACH" "$T_COACH"
assert_eq "a serve points LAST-SERVED at the queue head" \
  "${CANONICAL[0]}" "$(cat "$T_COACH/LAST-SERVED")"

# --- the invocation, which is the measured part -----------------------------
#
# All three of these were measured on 2026-10-14 against claude 2.1.300 and
# recorded on bead tla-rzvk: --tools "" removes file access, the prompt has to
# arrive on stdin because --tools is variadic and swallows a positional one,
# and the cwd decides which CLAUDE.md loads.

ATTEMPT_SNAP_BEFORE=$(snapshot "$ATTEMPT_DIR")
# The non-vacuity control for the untouched-ness row at the end of this part.
# snapshot() of a directory that is not there reads `<absent>`, which compares
# equal to itself, so without this the comparison is green over a directory
# holding nothing.
assert_says_literal "the attempt fixture really holds a module and a config to leave alone" \
  "./Pickers.cfg :: SPECIFICATION Spec" "$ATTEMPT_SNAP_BEFORE"

COACH_TREE_SNAP=$(snapshot "$T_COACH")

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check
assert_rc "--check exits 0" 0

if [ -f "$STUB_REC/claude.argv" ]; then
  ok "the stub model was the thing called, so the rows below read a real invocation"
else
  nope "no invocation was recorded at $STUB_REC/claude.argv, so nothing below is evidence"
fi

assert_eq "the invocation is -p and --tools with an empty value, and nothing else" \
  "ARG[-p]
ARG[--tools]
ARG[]" "$(cat "$STUB_REC/claude.argv" 2>/dev/null)"
assert_eq "the model was handed exactly three arguments" \
  "3" "$(cat "$STUB_REC/claude.argc" 2>/dev/null)"
assert_eq "it ran from the slug directory, so the study config above it loads by itself" \
  "$ATTEMPT_DIR" "$(cat "$STUB_REC/claude.cwd" 2>/dev/null)"

COACH_STDIN=$(cat "$STUB_REC/claude.stdin" 2>/dev/null)
assert_eq "the mode is the very first line of what arrived on stdin" \
  "MODE: check" "$(awk 'NR == 1' <<<"$COACH_STDIN")"
assert_never_names "and the prompt is not on argv, which --tools would swallow" \
  "MODE: check" "$(cat "$STUB_REC/claude.argv" 2>/dev/null)"

# --- what the prompt carries ------------------------------------------------

assert_says_literal "stdin carries the item's own PROMPT.md text" \
  "PROMPT BODY for ${CANONICAL[0]}" "$COACH_STDIN"
assert_says_literal "stdin names which drill it is about" \
  "${CANONICAL[0]}" "$COACH_STDIN"
assert_says_literal "stdin carries the attempt's module" "MODULE Pickers" "$COACH_STDIN"
assert_says_literal "and the attempt's config" "SPECIFICATION Spec" "$COACH_STDIN"
assert_says_literal "stdin carries the checker's output verbatim" \
  "module=Pickers rc=0 distinct=12 claimed=12 count=MATCH run=CLEAN invariant=-" "$COACH_STDIN"
assert_says_literal "every line of it, not just the first" \
  "module=Hoist rc=3 distinct=- claimed=- count=NONE run=NOCOUNT invariant=-" "$COACH_STDIN"
assert_never_names "and the absent marker reaches the model as the dash, never as a word" \
  "distinct=none" "$COACH_STDIN"
assert_says_literal "and the checker's summary line with it" \
  "MATCHED: 1 of 1 module(s)" "$COACH_STDIN"
assert_says_literal "and what the checker said on stderr, so a silent failure is not read as a clean run" \
  "a line the checker wrote on stderr" "$COACH_STDIN"
assert_says_literal "and the checker's exit code, which the model has no way to derive" \
  "exit 0" "$COACH_STDIN"

assert_never_names "a TLC trace dump is not part of the attempt" \
  "a trace dump TLC wrote" "$COACH_STDIN"
assert_never_names "nor is a superseded .old module" "an earlier go at it" "$COACH_STDIN"
assert_never_names "nor a file that is neither a module nor a config" \
  "scratch notes to himself" "$COACH_STDIN"

# --- the checker call -------------------------------------------------------

assert_eq "the checker was handed the attempt directory" \
  "ARG[$ATTEMPT_DIR]" "$(cat "$STUB_REC/check.argv" 2>/dev/null)"
assert_eq "and told where the prompts are, so it reads the same prompt the runner read" \
  "$T_COACH" "$(cat "$STUB_REC/check.promptroot" 2>/dev/null)"

# --- what the run says for itself -------------------------------------------

# NOT OPTIONAL OUTPUT. With the cwd out of the resolution, the printed name and
# directory are the only thing between Frank and a stale pointer.
assert_says_literal "the run says which drill it used" "${CANONICAL[0]}" "$RUN_OUT"
assert_says_literal "and says it came off the pointer" "LAST-SERVED" "$RUN_OUT"
assert_says_literal "and names the directory it read" "$ATTEMPT_DIR" "$RUN_OUT"
assert_says_literal "and the model's own answer reaches stdout" "STUB MODEL SPOKE" "$RUN_OUT"

assert_eq "a coaching run writes nothing into the attempt directory" \
  "$ATTEMPT_SNAP_BEFORE" "$(snapshot "$ATTEMPT_DIR")"
assert_eq "and nothing beside the runner either, so coaching is not a serve" \
  "$COACH_TREE_SNAP" "$(snapshot "$T_COACH")"

# --- --hint, plain and steered ----------------------------------------------

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --hint
assert_rc "--hint exits 0" 0
HINT_STDIN=$(cat "$STUB_REC/claude.stdin" 2>/dev/null)
assert_eq "the mode reads hint, on the first line" \
  "MODE: hint" "$(awk 'NR == 1' <<<"$HINT_STDIN")"
assert_never_names "an unsteered hint carries no QUESTION block" "QUESTION:" "$HINT_STDIN"
assert_eq "the invocation does not change with the mode" \
  "ARG[-p]
ARG[--tools]
ARG[]" "$(cat "$STUB_REC/claude.argv" 2>/dev/null)"
assert_says_literal "and a hint gets the checker's numbers too" \
  "module=Pickers rc=0 distinct=12 claimed=12 count=MATCH run=CLEAN invariant=-" "$HINT_STDIN"

# THE SHEET, WHICH IS THE WHOLE OF BEAD tla-1sh7.1. What separates a mechanism
# question from a question about his rule lives in
# drill/study/.claude/commands/hint.md, with the ladder, the two worked cases
# and the tiebreak. A one-shot under `--tools ""` cannot open it, exactly as
# it cannot open the register, so for as long as --hint existed the model
# classified on the study config's four-sentence summary with no example under
# it. On 2026-10-16 that laddered a question Frank had marked in his own text
# as a mechanism question, and it cost him the hour this bead was filed over.
#
# The needle is a sentence of the file's BODY rather than its path, so the row
# cannot pass on a runner that merely names the sheet in its banner.
assert_says_literal "a hint carries the sheet's own text, since the model cannot open it" \
  "$HINT_SHEET_SENTINEL" "$HINT_STDIN"
# The sheet is prose from a sixth file and the one input a reader cannot
# otherwise account for, which is the argument the register's banner line
# already carries.
assert_says_literal "and the run names the sheet it shipped" \
  "$STUDY_COACH/$HINT_SHEET_REL" "$RUN_OUT"
# HINT-ONLY, and the check prompt is where that is asserted. A check hands
# back the whole report, so rationing it would be the ladder reaching a mode
# it has no business in.
assert_never_names "and a check prompt carries no sheet, since only a hint is rationed" \
  "$HINT_SHEET_SENTINEL" "$COACH_STDIN"

# The free text is the reason the prompt goes on stdin at all: a heredoc
# sidesteps every quoting question a command line would raise, so the row
# carries a double quote and a question mark on purpose.
HINT_Q='why does my Next admit an empty pile, and what does "fairness" buy here?'
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --hint "$HINT_Q"
assert_rc "a steered hint exits 0" 0
HINT2_STDIN=$(cat "$STUB_REC/claude.stdin" 2>/dev/null)
assert_says_literal "a steered hint carries a QUESTION block" "QUESTION:" "$HINT2_STDIN"
assert_says_literal "and his text arrives verbatim, quotes and all" "$HINT_Q" "$HINT2_STDIN"
assert_never_names "and the question is not on argv either" \
  "$HINT_Q" "$(cat "$STUB_REC/claude.argv" 2>/dev/null)"
assert_eq "the invocation still carries three arguments" \
  "3" "$(cat "$STUB_REC/claude.argc" 2>/dev/null)"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --hint why is this one shaky
assert_rc "a question typed without quotes is taken whole rather than refused" 0
assert_says_literal "and arrives as one line of question" \
  "why is this one shaky" "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"

# --- the cwd decides nothing about WHICH drill ------------------------------
#
# The row that would catch a regression to resolving off the cwd. It stands in
# a real drill's directory, 01-mid-drill, while the pointer names another, and
# the pointer has to win. Under cwd-first this run would have coached
# mid/01-mid-drill and then died on the attempt gate, because that directory
# holds no module.

CWD_DECOY="$STUDY_COACH/${CANONICAL[1]##*/}"
mkdir -p "$CWD_DECOY"
run_coach "$STUDY_COACH" "$CWD_DECOY" "$T_COACH" --check
assert_rc "standing in another drill's directory changes nothing" 0
assert_says_literal "the pointer's drill is the one coached" "${CANONICAL[0]}" "$RUN_OUT"
assert_never_names "and not the one whose directory he happened to be in" \
  "${CANONICAL[1]}" "$RUN_OUT"
assert_eq "and the model ran from the pointer's directory, not from his cwd" \
  "$ATTEMPT_DIR" "$(cat "$STUB_REC/claude.cwd" 2>/dev/null)"

# --- --check takes an explicit drill, the way the marks do ------------------
#
# The documented override for a drifted pointer, and the same sentence usage()
# already carries for done and shaky.

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "$OVERRIDE_ITEM"
assert_rc "--check with an explicit drill name exits 0" 0
assert_says_literal "it coaches the drill it was handed" "$OVERRIDE_ITEM" "$RUN_OUT"
assert_never_names "and not the one the pointer named" "${CANONICAL[0]}" "$RUN_OUT"
assert_says_literal "and says the name came off the command line" \
  "the name you gave" "$RUN_OUT"
assert_eq "the model ran from the named drill's own directory" \
  "$OVERRIDE_DIR" "$(cat "$STUB_REC/claude.cwd" 2>/dev/null)"
assert_says_literal "and stdin carries the named drill's prompt" \
  "PROMPT BODY for $OVERRIDE_ITEM" "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"
assert_eq "an override does not move the pointer, because coaching is not a mark" \
  "${CANONICAL[0]}" "$(cat "$T_COACH/LAST-SERVED")"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "alpha/99-not-a-drill"
assert_rc "--check with a name that is not a drill is refused" 1
assert_says_literal "and the refusal says what to run instead, the way a mark does" \
  "./drill list" "$RUN_ERR"
assert_absent "and no model was called over it" "$STUB_REC/claude.argv"

# The spelling rule is the marks' spelling rule, so a bare slug is refused by
# both. The control is the mark itself rather than a planted fixture, because
# "the same as the marks" is the claim.
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "${OVERRIDE_ITEM##*/}"
assert_rc "a bare slug is refused, since the marks take <family>/<item>" 1
run_drill "$T_COACH" "done" "${OVERRIDE_ITEM##*/}"
assert_rc "control: done refuses a bare slug too, so --check matches the marks" 1

# --hint has NO drill override. The rest of the line is the question, and a
# drill name typed there is a question about that text.
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --hint "$OVERRIDE_ITEM"
assert_rc "--hint with something that looks like a drill name exits 0" 0
HINT4_STDIN=$(cat "$STUB_REC/claude.stdin" 2>/dev/null)
assert_says_literal "the text goes into the question block" "QUESTION:" "$HINT4_STDIN"
assert_says_literal "carrying what he typed" "$OVERRIDE_ITEM" "$HINT4_STDIN"
assert_eq "and the drill is still the one that was served" \
  "$ATTEMPT_DIR" "$(cat "$STUB_REC/claude.cwd" 2>/dev/null)"
assert_says_literal "and the run still says which drill that is" \
  "${CANONICAL[0]}" "$RUN_OUT"

# --- an absent or empty pointer says what a mark says -----------------------

T_NOPTR="$TMPROOT/coach-no-pointer"
mk_tree "$T_NOPTR" "$RUNNER"
assert_absent "the fixture starts with no pointer" "$T_NOPTR/LAST-SERVED"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_NOPTR" --check
assert_rc "--check with nothing served yet is refused" 1
assert_says_literal "and says nothing has been served yet" \
  "nothing has been served yet" "$RUN_ERR"
assert_says_literal "and points at the override that exists" \
  "./drill --check <family>/<item>" "$RUN_ERR"
assert_absent "and no model was called" "$STUB_REC/claude.argv"

# The control for "reuse its wording": the mark hits the same condition and has
# to produce the same sentence, or the two have forked.
run_drill "$T_NOPTR" "done"
assert_says_literal "control: a mark with no pointer says the same sentence" \
  "nothing has been served yet" "$RUN_ERR"

: >"$T_NOPTR/LAST-SERVED"
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_NOPTR" --hint
assert_rc "--hint over an empty pointer is refused" 1
assert_says_literal "and says the pointer is empty, the way a mark does" \
  "is empty" "$RUN_ERR"
assert_never_names "and offers no drill name, because --hint has no override" \
  "./drill --hint <family>/<item>" "$RUN_ERR"
run_drill "$T_NOPTR" shaky
assert_says_literal "control: a mark over an empty pointer says the same sentence" \
  "is empty" "$RUN_ERR"

# --- the checker's exit code is not the runner's ----------------------------
#
# tla-rzvk.1 moved a no-claim prompt with no tlc from exit 2 to exit 3. The
# runner exits with the one-shot's status and relays neither, so this is a
# no-op, and the row is here because that was worth checking rather than
# assuming.

COACH_CHECK_RC=3
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check
COACH_CHECK_RC=0
assert_rc "a checker exiting 3 does not become the runner's exit code" 0
assert_says_literal "and the code reaches the model on the label instead" \
  "== CHECKER, exit 3," "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"

# --- the three gates, each one message and a nonzero exit -------------------
#
# EVERY GATE RUNS BEFORE ANYTHING IS EXECUTED, so a missing dependency never
# costs a TLC run and never leaves a half-run: a prompt shipped with an
# unrun checker in it would be worse than no prompt, because the model cannot
# tell an empty block from a clean one.

# The decoy directory from the cwd rows is this drill's study directory, and it
# holds no module. The override names it, so the gate fires on a directory that
# really is the resolved one.
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "${CANONICAL[1]}"
assert_rc "a drill whose directory holds no module is refused" 1
assert_says_literal "and says there is no attempt to read" "no attempt" "$RUN_ERR"
assert_says_literal "and names the directory it looked in" "$CWD_DECOY" "$RUN_ERR"
assert_absent "and no model was called over nothing" "$STUB_REC/claude.argv"
assert_absent "and the checker was not run either" "$STUB_REC/check.argv"

printf 'SPECIFICATION Spec\n' >"$CWD_DECOY/Lonely.cfg"
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "${CANONICAL[1]}"
assert_rc "a config with no module beside it is not an attempt" 1
assert_absent "and still no model was called" "$STUB_REC/claude.argv"
rm -f "$CWD_DECOY/Lonely.cfg"

# A drill that has never been served has no study directory at all, which is a
# different thing from one holding no module.
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "${CANONICAL[5]}"
assert_rc "a drill with no study directory yet is refused" 1
assert_says_literal "and the refusal names the directory that is not there" \
  "$STUDY_COACH/${CANONICAL[5]##*/}" "$RUN_ERR"
assert_absent "and no model was called" "$STUB_REC/claude.argv"

STUDY_NOCHECK="$TMPROOT/coach-study-nocheck"
mkdir -p "$STUDY_NOCHECK/$SLUG0"
cp -- "$ATTEMPT_DIR/Pickers.tla" "$STUDY_NOCHECK/$SLUG0/Pickers.tla"
assert_absent "the no-checker study root really has no checker in it" "$STUDY_NOCHECK/check"
run_coach "$STUDY_NOCHECK" "$OUTSIDE" "$T_COACH" --check
assert_rc "a study root with no checker in it is refused" 1
assert_says_literal "and the refusal names the path the checker should be at" \
  "$STUDY_NOCHECK/check" "$RUN_ERR"
assert_absent "and no model was called, so nothing half-ran" "$STUB_REC/claude.argv"

write_check_stub "$STUDY_NOCHECK/check"
chmod -x "$STUDY_NOCHECK/check"
run_coach "$STUDY_NOCHECK" "$OUTSIDE" "$T_COACH" --check
assert_rc "a checker that is there but not executable is refused too" 1
assert_absent "and still no model was called" "$STUB_REC/claude.argv"
chmod +x "$STUDY_NOCHECK/check"

# --- THE SHEET GATE, WHICH IS THE REGISTER GATE IN THE HINT'S SHAPE ---------
#
# Bead tla-1sh7.1. A hint over a study root with no sheet in it is refused
# before the checker is executed, for the register's reason exactly: with no
# tools the model cannot tell an absent sheet from an empty one, so it would
# classify the question on a four-sentence summary and sound just as sure.
# That is the run that cost the hour.
#
# The root carries a WORKING CHECKER and no sheet, so the refusal is about the
# file it names and not about anything else the root is missing.

STUDY_NOSHEET="$TMPROOT/coach-study-nosheet"
mkdir -p "$STUDY_NOSHEET/$SLUG0"
cp -- "$ATTEMPT_DIR/Pickers.tla" "$STUDY_NOSHEET/$SLUG0/Pickers.tla"
write_check_stub "$STUDY_NOSHEET/check"
assert_absent "the no-sheet study root really has no hint sheet in it" \
  "$STUDY_NOSHEET/$HINT_SHEET_REL"

run_coach "$STUDY_NOSHEET" "$OUTSIDE" "$T_COACH" --hint
assert_rc "a hint over a study root with no sheet is refused" 1
assert_says_literal "and the refusal names the path the sheet should be at" \
  "$STUDY_NOSHEET/$HINT_SHEET_REL" "$RUN_ERR"
assert_says_literal "and says why a model with no tools cannot be sent to read it" \
  "no tools" "$RUN_ERR"
assert_absent "and no model was called, so nothing half-ran" "$STUB_REC/claude.argv"
# THE HALF-RUN GUARD, and the direction it is wrong in is the expensive one. A
# refusal decided after the checker ran would have spent a TLC run and thrown
# the numbers away.
assert_absent "and the checker was not run either, so nothing was checked for nothing" \
  "$STUB_REC/check.argv"

# THE GATE IS THE HINT'S ALONE, and without this row the one above it is
# indistinguishable from a root that is broken for every mode.
run_coach "$STUDY_NOSHEET" "$OUTSIDE" "$T_COACH" --check
assert_rc "the same root checks fine with no sheet in it, since --check reads none" 0
assert_says_literal "and the model was handed the checker's numbers over it" \
  "module=Pickers rc=0" "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"

write_hint_sheet "$STUDY_NOSHEET/$HINT_SHEET_REL"
run_coach "$STUDY_NOSHEET" "$OUTSIDE" "$T_COACH" --hint
assert_rc "with the sheet delivered, the hint runs" 0
assert_says_literal "and the sheet it shipped is that root's" \
  "$STUDY_NOSHEET/$HINT_SHEET_REL" "$RUN_OUT"
assert_says_literal "and its text reached the model" \
  "$HINT_SHEET_SENTINEL" "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"

# A PATH carrying what the runner needs and no claude. Built by resolving the
# real ones rather than by guessing at /bin, so the row is about the absence of
# claude and not about a broken PATH.
#
# `bash` IS ON THE LIST, and leaving it off is how the first run of this part
# went red for the wrong reason: the runner's own `#!/usr/bin/env bash` line
# resolves through PATH, so a shim without bash fails the runner at exec with
# rc 127 and `env: 'bash': No such file or directory`, which looks like a
# refusal the runner issued and is not one.
NOCLAUDE_BIN="$TMPROOT/bin-no-claude"
mkdir -p "$NOCLAUDE_BIN"
for coach_util in bash cat sort date mkdir dirname env; do
  coach_util_path=$(command -v "$coach_util") || continue
  ln -s -- "$coach_util_path" "$NOCLAUDE_BIN/$coach_util"
done
assert_absent "the no-claude PATH holds no claude" "$NOCLAUDE_BIN/claude"
if [ -e "$NOCLAUDE_BIN/bash" ] && [ -e "$NOCLAUDE_BIN/cat" ] && [ -e "$NOCLAUDE_BIN/sort" ]; then
  ok "and it does hold what the runner needs, so the rows below are about claude alone"
else
  nope "the no-claude PATH is missing bash, cat or sort, so a refusal there proves nothing"
fi

run_coach_path "$NOCLAUDE_BIN" "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check
assert_rc "no claude on the path is refused" 1
assert_says_literal "and the refusal names what is missing" "no claude on the path" "$RUN_ERR"
assert_absent "and the checker was not run, so a missing model costs no TLC run" \
  "$STUB_REC/check.argv"

run_coach_rootless "$OUTSIDE" "$T_COACH" --check
assert_rc "a coaching run with neither DRILL_STUDY_ROOT nor HOME is refused" 1
assert_says_literal "and the refusal names the variable that would fix it" \
  "DRILL_STUDY_ROOT" "$RUN_ERR"
assert_never_names "and it is a message rather than a crash under set -u" \
  "unbound variable" "$RUN_ERR"
assert_absent "and no model was called" "$STUB_REC/claude.argv"

# --- THE SERVE PATH KEEPS WORKING WITH NONE OF THEM PRESENT -----------------
#
# This is the half of the fail-soft rule that matters most. Serving is the job
# and coaching is the convenience, so a box with no claude and no study tree
# delivered still hands over the prompt.

T_BARE="$TMPROOT/coach-serve-bare"
mk_tree "$T_BARE" "$RUNNER"
STUDY_BARE="$TMPROOT/coach-study-bare"
mkdir -p "$STUDY_BARE"
assert_absent "the bare study root has no checker in it" "$STUDY_BARE/check"
RUN_OUT=$(cd "$OUTSIDE" && HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$STUDY_BARE" \
  PATH="$NOCLAUDE_BIN" "$T_BARE/drill" 2>"$ERRFILE")
RUN_RC=$?
RUN_ERR=$(cat "$ERRFILE")
assert_rc "a serve exits 0 with no claude on the path and no checker delivered" 0
assert_says_literal "and still prints the prompt" \
  "PROMPT BODY for ${CANONICAL[0]}" "$RUN_OUT"
assert_says_literal "and still names the directory to work in" \
  "$STUDY_BARE/$SLUG0" "$RUN_OUT"

# --- usage -------------------------------------------------------------------

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check "${CANONICAL[0]}" extra
assert_rc "--check refuses a second argument" 1
assert_says_literal "and says which one it did not expect" \
  "unexpected extra argument" "$RUN_ERR"
assert_absent "and no model was called over a usage error" "$STUB_REC/claude.argv"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" help
assert_says_literal "help names --check and its optional drill" \
  "./drill --check [<family>/<item>]" "$RUN_OUT"
assert_says_literal "and names --hint" "./drill --hint" "$RUN_OUT"
assert_says_literal "and says --hint takes no drill name, since the text owns that slot" \
  "--hint takes no drill name" "$RUN_OUT"
assert_says_literal "and names --style with the same optional drill --check takes" \
  "./drill --style [<family>/<item>]" "$RUN_OUT"
# A reader who runs --style on a box with the script and no register gets a
# refusal, so the two things it needs are named where he will look first.
assert_says_literal "and says --style needs the register as well as the script" \
  "the register" "$RUN_OUT"

# --- the header carries the SECOND narrowing --------------------------------
#
# Gate, don't advise. The header argued at length that the script reads nothing
# outside the directory it sits in, and the two coaching flags read three
# things outside it. An invariant narrowed twice in one day without saying so
# stops meaning anything, so the narrowing is a row rather than a note.

COACH_HEAD=$(awk '/^set -uo pipefail/ { exit } { print }' "$RUNNER")
assert_says_literal "the header still says it sources nothing and resolves no repo root" \
  "sources nothing, resolves no repo root" "$COACH_HEAD"
assert_says_literal "and the second narrowing is named rather than slipped in" \
  "NARROWED AGAIN" "$COACH_HEAD"
assert_says_literal "and it says the confinement is now about a serve" \
  "a serve reads nothing outside" "$COACH_HEAD"
# Single-quoted: these are lines of the runner's SOURCE TEXT read back, so an
# expansion here would put this suite's own environment into the needle and the
# rows would be asserting nothing about the runner.
# shellcheck disable=SC2016
COACH_HEAD_CHECKER='$STUDY_ROOT/check'
assert_says_literal "and names the checker it executes outside this tree" \
  "$COACH_HEAD_CHECKER" "$COACH_HEAD"
assert_says_literal "and names the invocation it ships, flags and all" \
  "claude -p --tools" "$COACH_HEAD"
assert_says_literal "and argues why a missing dependency is refused rather than half-run" \
  "never a half-run" "$COACH_HEAD"
assert_says_literal "and says the resolution is the pointer, the way a mark's is" \
  "LAST-SERVED" "$COACH_HEAD"
assert_never_names "and no longer claims the cwd decides which drill" \
  "the directory you are standing in" "$COACH_HEAD"

# THE INVARIANT IS NOT WIDENED AGAIN, AND THAT IS THE POINT OF THESE TWO ROWS.
# Bead tla-iiow.3 adds --style, which reads two more paths under the SAME
# study root the three above already resolve from, so the argument that buys
# the narrowing is the one already written: the one-shot has no tools, so
# either this script fetches the material or the coaching is worthless. What
# changes is the enumeration, because a list that says three while the code
# reads five is a header that lies. So the rows below check the two new
# entries are IN the list, and that the argument was not restated beside them.
# shellcheck disable=SC2016
COACH_HEAD_STYLE='$STUDY_ROOT/style'
assert_says_literal "the narrowed list names the style script it executes" \
  "$COACH_HEAD_STYLE" "$COACH_HEAD"
# shellcheck disable=SC2016
COACH_HEAD_REGISTER='$STUDY_ROOT/STYLE.md'
assert_says_literal "and the register it reads, which no other flag reads" \
  "$COACH_HEAD_REGISTER" "$COACH_HEAD"
assert_never_names "and the list no longer says there are three of them" \
  "read three things outside it" "$COACH_HEAD"

# THE SIXTH ENTRY, same reasoning one bead later. tla-1sh7.1 adds the hint
# sheet, under the SAME study root the other five resolve from, so the
# argument that buys the narrowing is the one already written and the list is
# what has to grow.
# shellcheck disable=SC2016
COACH_HEAD_SHEET='$STUDY_ROOT/.claude/commands/hint.md'
assert_says_literal "and the sheet a hint ships, which no other flag ships" \
  "$COACH_HEAD_SHEET" "$COACH_HEAD"
assert_never_names "and the list no longer says there are five of them either" \
  "read five things outside it" "$COACH_HEAD"

# ONE SOURCE FOR THE REGISTER RULES, AND IT IS NOT THE RUNNER.
#
# drill/study/CLAUDE.md is the single source of what the model must not do, and
# it loads by itself because the one-shot runs from the attempt directory. A
# runner that restated one of those prohibitions would have forked the file
# that holds them, and a fork drifts from the moment it is written.
#
# Checked over the WHOLE runner rather than over code alone, because a header
# paragraph restating the rules forks them exactly as a string would. The
# control is a PLANTED line rather than the study config itself: the config is
# another bead's file, and a control that read it would go red on an edit there
# that is none of this row's business.
CTRL_RESTATE='# NEVER read ANSWER.md or META.md, and never hand over the construct.'
RUNNER_RAW=$(cat "$RUNNER")
for coach_needle in "ANSWER.md" "META.md"; do
  if grep -qF -- "$coach_needle" <<<"$CTRL_RESTATE"; then
    ok "control: a restated prohibition naming $coach_needle is DETECTED"
  else
    nope "control: the needle $coach_needle matched nothing, so the row below is vacuous"
  fi
  assert_never_names "the runner restates no prohibition naming $coach_needle" \
    "$coach_needle" "$RUNNER_RAW"
done
assert_never_names "and the prompt it ships restates none either" \
  "ANSWER.md" "$COACH_STDIN"

# ---------------------------------------------------------------------------
echo
echo "== part 4d: --style, the register and the measuring script =="
# ---------------------------------------------------------------------------
#
# Bead tla-iiow.3. A third coaching flag, resolved exactly as --check is, and
# the differences from --check are the whole of what these rows are about.
#
# IT CATS THE REGISTER INTO THE PROMPT, which --check has no equivalent of.
# AMENDED by bead tla-1sh7.1: --hint now has one, so the clause is about
# --check rather than about the other two flags.
# The one-shot runs with no tools, so the model cannot open drill/study/STYLE.md
# however plainly it is told to, and a register it cannot read is a register
# that is not there. So the runner ships it, and that makes the style prompt
# the largest of the three. One row below measures that rather than asserting
# it.
#
# IT DOES NOT RUN THE CHECKER. Correctness and style are different questions,
# and folding them together would make every check pay for a style pass. So a
# style run over a study root with no checker in it still works, which is the
# last row of the gate progression below.
#
# THE STYLE SCRIPT'S EXIT CODE IS NOT A VERDICT. Bead tla-iiow.2 locks 0 for
# measured-something and 3 for could-not-run, with no 1 at all, because a
# style pass that can fail becomes a gate on Frank's own work. The runner
# relays the one-shot's status and never the script's, same as for the
# checker, and one row varies the stub's code to say so.

STYLE_TREE_SNAP=$(snapshot "$T_COACH")
STYLE_ATTEMPT_SNAP=$(snapshot "$ATTEMPT_DIR")
# The non-vacuity control for the untouched-ness rows at the end of this part.
# snapshot() of a directory that is not there reads `<absent>`, which compares
# equal to itself, so without this the comparison is green over a directory
# holding nothing.
assert_says_literal "the attempt fixture really holds a module and a config to leave alone" \
  "./Pickers.cfg :: SPECIFICATION Spec" "$STYLE_ATTEMPT_SNAP"

if [ -x "$STUDY_COACH/style" ] && [ -f "$STUDY_COACH/STYLE.md" ]; then
  ok "the style fixture is a runnable script and a register beside it"
else
  nope "the style fixture is missing its script or its register, so nothing below is evidence"
fi

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style
assert_rc "--style exits 0" 0

if [ -f "$STUB_REC/claude.argv" ]; then
  ok "the stub model was the thing called, so the rows below read a real invocation"
else
  nope "no invocation was recorded at $STUB_REC/claude.argv, so nothing below is evidence"
fi

assert_eq "--style ships the same invocation, with no tool added back" \
  "ARG[-p]
ARG[--tools]
ARG[]" "$(cat "$STUB_REC/claude.argv" 2>/dev/null)"
assert_eq "the model was handed exactly three arguments" \
  "3" "$(cat "$STUB_REC/claude.argc" 2>/dev/null)"
assert_eq "it ran from the slug directory, so the study config above it loads by itself" \
  "$ATTEMPT_DIR" "$(cat "$STUB_REC/claude.cwd" 2>/dev/null)"

STYLE_STDIN=$(cat "$STUB_REC/claude.stdin" 2>/dev/null)
assert_eq "the mode is the very first line of what arrived on stdin" \
  "MODE: style" "$(awk 'NR == 1' <<<"$STYLE_STDIN")"
assert_never_names "and the prompt is not on argv, which --tools would swallow" \
  "MODE: style" "$(cat "$STUB_REC/claude.argv" 2>/dev/null)"

# --- what the style prompt carries that the other two do not -----------------

assert_says_literal "stdin carries the register's own text, since the model cannot open it" \
  "$STYLE_REGISTER_SENTINEL" "$STYLE_STDIN"
assert_says_literal "stdin carries the style script's measurements verbatim" \
  "axis=constant-case module=Pickers camel=0 snake=2 lower=0 corpus=126of132" "$STYLE_STDIN"
assert_says_literal "every line of them, not just the first" \
  "axis=spec-name module=Pickers measured=Spec corpus=170of205" "$STYLE_STDIN"
assert_says_literal "and what the style script said on stderr, so a silent failure is not read as a clean pass" \
  "a line the style script wrote on stderr" "$STYLE_STDIN"
assert_says_literal "and its exit code, which the model has no way to derive" \
  "exit 0" "$STYLE_STDIN"

assert_says_literal "stdin carries the item's own PROMPT.md text" \
  "PROMPT BODY for ${CANONICAL[0]}" "$STYLE_STDIN"
assert_says_literal "stdin names which drill it is about" \
  "${CANONICAL[0]}" "$STYLE_STDIN"
assert_says_literal "stdin carries the attempt's module" "MODULE Pickers" "$STYLE_STDIN"
assert_says_literal "and the attempt's config" "SPECIFICATION Spec" "$STYLE_STDIN"
assert_never_names "a TLC trace dump is no more part of a style attempt than of a check one" \
  "a trace dump TLC wrote" "$STYLE_STDIN"
assert_never_names "nor is a superseded .old module" "an earlier go at it" "$STYLE_STDIN"

# --- the checker is not run, and that is the separation of the two flags -----

assert_absent "the checker was not run, because style is a different question" \
  "$STUB_REC/check.argv"
assert_never_names "and no checker block reaches the model" "== CHECKER" "$STYLE_STDIN"
assert_never_names "nor any of its numbers" "count=MATCH" "$STYLE_STDIN"
# Nor the hint's sheet, which is the third mode's own prose. The fixture root
# carries one, so this row is about what --style ships rather than about what
# the root holds.
assert_never_names "nor the hint sheet, since a style pass rations nothing" \
  "$HINT_SHEET_SENTINEL" "$STYLE_STDIN"

# --- the style call ---------------------------------------------------------

assert_eq "the style script was handed the attempt directory" \
  "ARG[$ATTEMPT_DIR]" "$(cat "$STUB_REC/style.argv" 2>/dev/null)"
assert_eq "and told where the prompts are, so it reads the same prompt the runner read" \
  "$T_COACH" "$(cat "$STUB_REC/style.promptroot" 2>/dev/null)"

# --- what the run says for itself -------------------------------------------

assert_says_literal "the run says which drill it used" "${CANONICAL[0]}" "$RUN_OUT"
assert_says_literal "and says it came off the pointer" "LAST-SERVED" "$RUN_OUT"
assert_says_literal "and names the directory it read" "$ATTEMPT_DIR" "$RUN_OUT"
# The register is the one input a reader cannot otherwise account for: it is
# prose from a third file, and it is most of the prompt by volume.
assert_says_literal "and names the register it shipped, which is most of the prompt" \
  "$STUDY_COACH/STYLE.md" "$RUN_OUT"
assert_says_literal "and the model's own answer reaches stdout" "STUB MODEL SPOKE" "$RUN_OUT"

assert_eq "a style run writes nothing into the attempt directory" \
  "$STYLE_ATTEMPT_SNAP" "$(snapshot "$ATTEMPT_DIR")"
assert_eq "and nothing beside the runner either, so a style run is not a serve" \
  "$STYLE_TREE_SNAP" "$(snapshot "$T_COACH")"

# --- the style prompt is the biggest of the three, measured ------------------
#
# Not an aesthetic point. The register is the reason --style exists as its own
# flag rather than as an addition to --check, and the size is what that costs.
# Measured here rather than written down, so the row stays true as the files
# move.

# Both read off the recorder FILE rather than off a captured variable, because
# a command substitution strips trailing newlines and the two prompts do not
# end the same way. A byte count taken through one is not a byte count.
STYLE_PROMPT_BYTES=0
[ -f "$STUB_REC/claude.stdin" ] && STYLE_PROMPT_BYTES=$(wc -c <"$STUB_REC/claude.stdin")
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --check
CHECK_PROMPT_BYTES=0
[ -f "$STUB_REC/claude.stdin" ] && CHECK_PROMPT_BYTES=$(wc -c <"$STUB_REC/claude.stdin")
printf '  NOTE  style prompt %s bytes, check prompt %s bytes over the same attempt\n' \
  "$STYLE_PROMPT_BYTES" "$CHECK_PROMPT_BYTES"
if [ "$STYLE_PROMPT_BYTES" -gt "$CHECK_PROMPT_BYTES" ]; then
  ok "the style prompt is larger than the check prompt over the same attempt, which is the register's weight"
else
  nope "the style prompt is $STYLE_PROMPT_BYTES bytes against the check prompt's $CHECK_PROMPT_BYTES, so the register is not being shipped"
fi

# --- the style script's exit code is not the runner's -----------------------

COACH_STYLE_RC=3
run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style
COACH_STYLE_RC=0
assert_rc "a style script exiting 3 does not become the runner's exit code" 0
assert_says_literal "and the code reaches the model on the label instead" \
  "exit 3" "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"

# --- an explicit drill, the way --check takes one ---------------------------

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style "$OVERRIDE_ITEM"
assert_rc "--style with an explicit drill name exits 0" 0
assert_says_literal "it styles the drill it was handed" "$OVERRIDE_ITEM" "$RUN_OUT"
assert_never_names "and not the one the pointer named" "${CANONICAL[0]}" "$RUN_OUT"
assert_eq "the model ran from the named drill's own directory" \
  "$OVERRIDE_DIR" "$(cat "$STUB_REC/claude.cwd" 2>/dev/null)"
# A module with no config beside it is still worth measuring for style, since
# measuring style needs no config at all. The override fixture is exactly that
# shape, so this row is also the one that would catch --style inheriting the
# checker's pairing requirement.
assert_says_literal "a module with no config beside it is still styled" \
  "MODULE Ballast" "$(cat "$STUB_REC/claude.stdin" 2>/dev/null)"
assert_eq "an override does not move the pointer, because styling is not a mark" \
  "${CANONICAL[0]}" "$(cat "$T_COACH/LAST-SERVED")"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style "alpha/99-not-a-drill"
assert_rc "--style with a name that is not a drill is refused" 1
# THE WHOLE SENTENCE, not the command inside it. `./drill list` on its own is
# carried by the usage block, so a needle that short passed against the runner
# before --style existed at all: the unknown-option path prints usage on
# stderr and the row read as green over a flag that was refused for a
# completely different reason. Measured 2026-10-15 on the RED run of this part.
assert_says_literal "and the refusal says what to run instead, the way --check does" \
  "Run ./drill list to see what there is." "$RUN_ERR"
assert_absent "and no model was called over it" "$STUB_REC/claude.argv"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style "${OVERRIDE_ITEM##*/}"
assert_rc "a bare slug is refused, since --style takes <family>/<item> like the marks" 1
assert_says_literal "and the refusal names what it could not find" \
  "no drill at" "$RUN_ERR"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style "${CANONICAL[0]}" extra
assert_rc "--style refuses a second argument" 1
assert_says_literal "and says which one it did not expect" \
  "unexpected extra argument" "$RUN_ERR"
assert_absent "and no model was called over a usage error" "$STUB_REC/claude.argv"

# --- an absent pointer says what --check says -------------------------------

T_STYLE_NOPTR="$TMPROOT/style-no-pointer"
mk_tree "$T_STYLE_NOPTR" "$RUNNER"
assert_absent "the fixture starts with no pointer" "$T_STYLE_NOPTR/LAST-SERVED"

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_STYLE_NOPTR" --style
assert_rc "--style with nothing served yet is refused" 1
assert_says_literal "and says nothing has been served yet" \
  "nothing has been served yet" "$RUN_ERR"
assert_says_literal "and points at the override that exists, since --style has one" \
  "./drill --style <family>/<item>" "$RUN_ERR"
assert_absent "and no model was called" "$STUB_REC/claude.argv"

# --- THE GATES, ONE DEPENDENCY AT A TIME ------------------------------------
#
# One root, built up a file at a time, so each step adds exactly what the
# previous refusal asked for and nothing else. That is a stronger reading than
# four separate roots: it shows the refusals are about the file each one names
# rather than about anything else the root happens to be missing.
#
# The root carries NO CHECKER at any point, which is why the last row of the
# progression is the independence row.

STYLE_BUILD="$TMPROOT/style-build-up"
mkdir -p "$STYLE_BUILD/$SLUG0"
cp -- "$ATTEMPT_DIR/Pickers.tla" "$STYLE_BUILD/$SLUG0/Pickers.tla"
assert_absent "the build-up root starts with no checker in it at all" "$STYLE_BUILD/check"

run_coach "$STYLE_BUILD" "$OUTSIDE" "$T_COACH" --style
assert_rc "a study root with no style script is refused" 1
assert_says_literal "and the refusal names the path the script should be at" \
  "$STYLE_BUILD/style" "$RUN_ERR"
assert_absent "and no model was called, so nothing half-ran" "$STUB_REC/claude.argv"

write_style_stub "$STYLE_BUILD/style"
chmod -x "$STYLE_BUILD/style"
run_coach "$STYLE_BUILD" "$OUTSIDE" "$T_COACH" --style
assert_rc "a style script that is there but not executable is refused too" 1
assert_says_literal "and the refusal still names it" "$STYLE_BUILD/style" "$RUN_ERR"
assert_absent "and still no model was called" "$STUB_REC/claude.argv"

chmod +x "$STYLE_BUILD/style"
assert_absent "the root now has a runnable script and still no register" \
  "$STYLE_BUILD/STYLE.md"
run_coach "$STYLE_BUILD" "$OUTSIDE" "$T_COACH" --style
assert_rc "a study root with the script and no register is refused" 1
assert_says_literal "and the refusal names the register's path" \
  "$STYLE_BUILD/STYLE.md" "$RUN_ERR"
assert_says_literal "and says why a model with no tools cannot be sent to read it" \
  "no tools" "$RUN_ERR"
assert_absent "and no model was called" "$STUB_REC/claude.argv"
# THE HALF-RUN GUARD. A refusal decided after the script ran would have
# measured the attempt and thrown the measurements away, and a measuring pass
# that runs when its output has nowhere to go is the shape the checker gate
# was written against.
assert_absent "and the style script was not run either, so nothing was measured for nothing" \
  "$STUB_REC/style.argv"

write_style_register "$STYLE_BUILD/STYLE.md"
run_coach "$STYLE_BUILD" "$OUTSIDE" "$T_COACH" --style
assert_rc "with the script and the register there, --style runs over a root holding no checker" 0
assert_says_literal "and the register it shipped is that root's" \
  "$STYLE_BUILD/STYLE.md" "$RUN_OUT"
if [ -f "$STUB_REC/claude.argv" ]; then
  ok "so --style needs no checker at all, which is the separation the two flags are for"
else
  nope "no model was called over a root with the style pair and no checker"
fi

# --- an attempt with no module, no claude, no root --------------------------

run_coach "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style "${CANONICAL[1]}"
assert_rc "a drill whose directory holds no module is refused" 1
assert_says_literal "and says there is no attempt to read" "no attempt" "$RUN_ERR"
assert_absent "and no model was called over nothing" "$STUB_REC/claude.argv"
assert_absent "and the style script was not run either" "$STUB_REC/style.argv"

run_coach_path "$NOCLAUDE_BIN" "$STUDY_COACH" "$OUTSIDE" "$T_COACH" --style
assert_rc "no claude on the path is refused" 1
assert_says_literal "and the refusal names what is missing" "no claude on the path" "$RUN_ERR"
assert_absent "and the style script was not run, so a missing model costs no measurement" \
  "$STUB_REC/style.argv"

run_coach_rootless "$OUTSIDE" "$T_COACH" --style
assert_rc "a style run with neither DRILL_STUDY_ROOT nor HOME is refused" 1
# The variable NAME alone is in the usage block, so the needle is the clause
# that only the refusal carries. Same measurement as the `./drill list` row
# above: the short needle was green before --style existed.
assert_says_literal "and the refusal names the variable that would fix it" \
  "DRILL_STUDY_ROOT is unset and so is HOME" "$RUN_ERR"
assert_never_names "and it is a message rather than a crash under set -u" \
  "unbound variable" "$RUN_ERR"
assert_absent "and no model was called" "$STUB_REC/claude.argv"

# --- THE SERVE PATH KEEPS WORKING WITH NONE OF THEM PRESENT -----------------
#
# The half of the fail-soft rule that matters most, now with two more things
# absent. Serving is the job and coaching is the convenience.

assert_absent "the bare study root has no style script in it" "$STUDY_BARE/style"
assert_absent "and no register either" "$STUDY_BARE/STYLE.md"
RUN_OUT=$(cd "$OUTSIDE" && HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$STUDY_BARE" \
  PATH="$NOCLAUDE_BIN" "$T_BARE/drill" 2>"$ERRFILE")
RUN_RC=$?
RUN_ERR=$(cat "$ERRFILE")
assert_rc "a serve exits 0 with no claude, no checker and no style pair" 0
assert_says_literal "and still prints the prompt" \
  "PROMPT BODY for ${CANONICAL[0]}" "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== part 5: the mutants, which is what makes part 1 and part 3 mean something =="
# ---------------------------------------------------------------------------

MUTANT_DIR="$TMPROOT/mutants"
mkdir -p "$MUTANT_DIR"

# mutate <name> <sed-script>: a copy of the real runner with one line changed.
#
# The path lands in MUTANT, and the return code says whether there is one. A
# nameref would work too. I went with the global because run_drill,
# run_drill_study, run_coach_path and run_coach_rootless all report back the
# same way, so this is the file's existing idiom rather than a new one.
#
# IT USED TO RETURN THE PATH ON STDOUT, and that made this guard unable to
# fail the suite. Every call site read it through `M1=$(mutate ...)`, which is
# a subshell, so a vacuous mutation called nope inside one. The FAIL row went
# into the variable instead of the report, and the fail_count increment died
# with the subshell. The caller then handed mk_tree a failure message where a
# path belonged.
#
# Measured 2026-10-16 on bead tla-vo5l, with M5's script broken so it matched
# nothing. The suite printed a `cp: cannot stat` error naming the FAIL text on
# stderr. It then passed both of M5's control rows over a mutant that was
# never built, one of them reading rc=127 for a mutation that exits 9. The run
# exited 0 with 378 assertions green.
#
# So the call sites below are `if mutate ...; then`, not a capture. Keep them
# that way. A capture puts nope back in a subshell and the guard goes quiet
# again.
#
# Three separate `local` statements, because `local a=$1 b=$MUTANT_DIR/$a`
# reads $a as unbound under `set -u` on this bash.
MUTANT=""
mutate() {
  local name="$1"
  local script="$2"
  local out="$MUTANT_DIR/$name"
  MUTANT=""
  sed "$script" "$RUNNER" >"$out"
  chmod +x "$out"
  if [ "$(cat "$out")" = "$(cat "$RUNNER")" ]; then
    nope "mutant $name changed nothing, so its control below is vacuous"
    return 1
  fi
  MUTANT="$out"
}

# Every sed script below is single-quoted on purpose. The whole point of a
# mutation is to put a literal line of the runner's source on both sides of
# the substitution, so an expansion here would replace the pattern with
# whatever this shell holds and the mutation would match nothing. mutate()
# fails loudly in that case, which is the other half of the guard.
#
# M1. the index drops out of the sort key, so the order goes family-major.
# shellcheck disable=SC2016
if mutate family-major 's|^    keyed+=("${idx}${TAB}${item}")$|    keyed+=("${item}${TAB}${item}")|'; then
  T_M1="$TMPROOT/tree-m1"
  mk_tree "$T_M1" "$MUTANT"
  M1_Q=$(queue_of "$T_M1")
  assert_ne "control: a family-major runner is DETECTED by the interleaving row" \
    "$(printf '%s\n' "${CANONICAL[@]}")" "$M1_Q"
  assert_eq "and it fails the way the mutation says, family-major" \
    "alpha/01-alpha-drill
alpha/02-alpha-drill
alpha/03-alpha-drill
mid/01-mid-drill
mid/02-mid-drill
mid/03-mid-drill
zeta/01-zeta-drill
zeta/02-zeta-drill
zeta/03-zeta-drill" "$M1_Q"
fi

# M2. shaky retires a drill instead of putting it back.
if mutate shaky-retires 's|^        shaky) shaky_keyed+=.*$|        shaky) continue ;;|'; then
  T_M2="$TMPROOT/tree-m2"
  mk_tree "$T_M2" "$MUTANT"
  run_drill "$T_M2"
  run_drill "$T_M2" shaky
  M2_Q=$(queue_of "$T_M2")
  if grep -qF -- "${CANONICAL[0]}" <<<"$M2_Q"; then
    nope "control: a runner where shaky retires was NOT detected, so the resurfacing rows are vacuous"
  else
    ok "control: a runner where shaky retires is DETECTED, the drill never comes back"
  fi
fi

# M3. the record is written rather than appended to.
# shellcheck disable=SC2016
if mutate truncating-record 's|>>"\$PROGRESS"|>"$PROGRESS"|'; then
  T_M3="$TMPROOT/tree-m3"
  mk_tree "$T_M3" "$MUTANT"
  run_drill "$T_M3"
  run_drill "$T_M3" "done"
  run_drill "$T_M3" "done"
  M3_LINES=$(grep -c '' "$T_M3/PROGRESS.tsv")
  if [ "$M3_LINES" -eq 1 ]; then
    ok "control: a truncating runner is DETECTED, two marks leave one line"
  else
    nope "control: a truncating runner left $M3_LINES line(s), so the append-only rows are vacuous"
  fi
fi

# M4. the pointer lands one directory up.
# shellcheck disable=SC2016
if mutate pointer-escapes 's|^POINTER="\$HERE/LAST-SERVED"$|POINTER="$HERE/../LAST-SERVED"|'; then
  mkdir -p "$TMPROOT/m4-outer"
  T_M4="$TMPROOT/m4-outer/tree"
  mk_tree "$T_M4" "$MUTANT"
  run_drill "$T_M4"
  if [ -e "$TMPROOT/m4-outer/LAST-SERVED" ]; then
    ok "control: a runner writing outside its directory is DETECTED"
  else
    nope "control: a runner writing outside its directory was NOT detected, so part 4 is vacuous"
  fi
fi

# M5 AND M6 EXIST FOR A REASON THE OTHER FOUR DO NOT HAVE. Two of part 4b's
# rows are NEGATIVE: a failed creation still exits 0, and a serve over an
# existing directory does not claim to have created it. Both of those hold
# over a runner with no study directory at all, which is exactly what they
# held over the day before this feature landed. A negative row needs a runner
# that gets it wrong, or it is green over nothing for the rest of the file's
# life.
#
# M5. a creation that fails takes the serve down with it.
# shellcheck disable=SC2016
if mutate study-failure-is-fatal \
  's|^  echo "drill: cannot create the study directory at \$STUDY_ROOT/\$slug, so work" >&2$|  exit 9|'; then
  T_M5="$TMPROOT/tree-m5"
  mk_tree "$T_M5" "$MUTANT"
  M5_FILE="$TMPROOT/m5-root-is-a-file"
  printf 'a regular file where a study root was expected\n' >"$M5_FILE"
  run_drill_study "$M5_FILE" "$T_M5"
  if [ "$RUN_RC" -ne 0 ]; then
    ok "control: a runner that fails a serve over the study directory is DETECTED, rc=$RUN_RC"
  else
    nope "control: a fatal creation failure was NOT detected, so the still-exits-0 rows are vacuous"
  fi
  if grep -qF -- "PROMPT BODY for ${CANONICAL[0]}" <<<"$RUN_OUT"; then
    nope "control: the fatal mutant still printed the prompt, so the prompt row is vacuous"
  else
    ok "and it withheld the prompt, which is the cost the rows above price"
  fi
fi

# M6. the existing-directory guard drops out, so every serve runs mkdir and
# reports a creation. `mkdir -p` over a directory that is already there
# succeeds, which is why this mutation is silent on the filesystem and shows
# up only in what the serve claims.
# shellcheck disable=SC2016
if mutate study-claims-every-serve 's|^  if \[ -d "\$STUDY_ROOT/\$slug" \]; then$|  if false; then|'; then
  T_M6="$TMPROOT/tree-m6"
  mk_tree "$T_M6" "$MUTANT"
  STUDY_M6="$TMPROOT/study-root-m6"
  mkdir -p "$STUDY_M6/$SLUG0"
  run_drill_study "$STUDY_M6" "$T_M6"
  if grep -qF -- "created" <<<"$RUN_OUT"; then
    ok "control: a runner claiming a creation over an existing directory is DETECTED"
  else
    nope "control: the false creation claim was NOT detected, so the no-claim row is vacuous"
  fi
fi

# M7 AND M8 BACK PART 4c'S TWO NEGATIVE ROWS, for the reason M5 and M6 exist.
# "No model was called" and "the prompt is not on argv" both hold over a runner
# with no coaching path at all, which is what they held over the day before
# this feature landed. A negative row needs a runner that gets it wrong.
#
# M7. the checker gate drops out, so a run with no checker ships anyway and the
# model gets a block from a command that never ran. That is the half-run the
# header argues against, and part 4c's "nothing half-ran" rows are what catch
# it.
#
# THE PATTERN FOLLOWED THE LINE, 2026-10-15. Bead tla-iiow.3 made the checker
# gate the `elif` of the style gate's `if`, so the old `^  if [ ! -x ...` no
# longer matched and this mutation silently became a copy of the runner.
# mutate() caught it and said so, which is the half of that function worth
# knowing about: a mutation that matches nothing is reported as a vacuous
# control rather than passing as a mutant that was not detected.
#
# AMENDED 2026-10-16, bead tla-vo5l. That last sentence describes what
# mutate() does now, not what it did when the line above was written. Back
# then the report went into a command substitution and the loud part was a cp
# error on stderr. M7 happened to redden anyway, because its own row fails
# over a tree with no runner in it. M5's row passes over the same tree, so
# whether a vacuous mutation reached the tally was luck. The note above
# mutate() carries the measurement.
# shellcheck disable=SC2016
if mutate coach-ships-without-checker 's|^  elif \[ ! -x "\$STUDY_ROOT/check" \]; then$|  elif false; then|'; then
  T_M7="$TMPROOT/tree-m7"
  mk_tree "$T_M7" "$MUTANT"
  # A mutant tree starts with no pointer, and the resolution reads one, so the
  # run would be refused before it ever reached the gate under test.
  printf '%s\n' "${CANONICAL[0]}" >"$T_M7/LAST-SERVED"
  STUDY_M7="$TMPROOT/study-root-m7"
  mkdir -p "$STUDY_M7/$SLUG0"
  cp -- "$ATTEMPT_DIR/Pickers.tla" "$STUDY_M7/$SLUG0/Pickers.tla"
  run_coach "$STUDY_M7" "$OUTSIDE" "$T_M7" --check
  if [ -e "$STUB_REC/claude.argv" ]; then
    ok "control: a runner shipping with no checker run is DETECTED as a half-run"
  else
    nope "control: a half-run was NOT detected, so part 4c's no-model-called rows are vacuous"
  fi
fi

# M8. the prompt goes on argv instead of stdin, which is the one thing F3
# measured as fatal: --tools is variadic and eats a positional prompt. The row
# that says the prompt is absent from argv is green over any runner that never
# builds a prompt, so it needs this.
# shellcheck disable=SC2016
if mutate coach-prompt-on-argv \
  's|^  ( cd -- "\$COACH_DIR" && claude -p --tools "" ) <<<"\$PROMPT_TEXT"$|  ( cd -- "$COACH_DIR" \&\& claude -p --tools "" "$PROMPT_TEXT" ) </dev/null|'; then
  T_M8="$TMPROOT/tree-m8"
  mk_tree "$T_M8" "$MUTANT"
  printf '%s\n' "${CANONICAL[0]}" >"$T_M8/LAST-SERVED"
  run_coach "$STUDY_COACH" "$OUTSIDE" "$T_M8" --check
  if grep -qF -- "MODE: check" "$STUB_REC/claude.argv"; then
    ok "control: a runner putting the prompt on argv is DETECTED"
  else
    nope "control: the prompt on argv was NOT detected, so part 4c's stdin rows are vacuous"
  fi
fi

# M9 BACKS PART 4d'S REGISTER GATE, for the reason M7 backs the checker's. "No
# model was called" and "the style script was not run" both hold over a runner
# with no --style at all, which is what they held over the day before this
# feature landed: `./drill --style` was an unknown option exiting 1. So the rc
# and the absence agreed with the contract while nothing implemented it, and
# only the message rows reddened. A negative row needs a runner that gets it
# wrong, and this is that runner.
#
# M9. the register gate drops out, so a run with no STYLE.md measures the
# attempt and ships a prompt with no register in it. The model then reads
# measurements against a register it was never given, which is the one failure
# this flag cannot tolerate: with no tools it cannot tell an absent register
# from an empty one, so it would interpret counts against nothing and sound
# just as certain.
# shellcheck disable=SC2016
if mutate style-ships-without-register 's|^    if \[ ! -r "\$STUDY_ROOT/STYLE\.md" \]; then$|    if false; then|'; then
  T_M9="$TMPROOT/tree-m9"
  mk_tree "$T_M9" "$MUTANT"
  printf '%s\n' "${CANONICAL[0]}" >"$T_M9/LAST-SERVED"
  STUDY_M9="$TMPROOT/study-root-m9"
  mkdir -p "$STUDY_M9/$SLUG0"
  cp -- "$ATTEMPT_DIR/Pickers.tla" "$STUDY_M9/$SLUG0/Pickers.tla"
  write_style_stub "$STUDY_M9/style"
  run_coach "$STUDY_M9" "$OUTSIDE" "$T_M9" --style
  if [ -e "$STUB_REC/claude.argv" ]; then
    ok "control: a runner shipping a style prompt with no register is DETECTED as a half-run"
  else
    nope "control: the register half-run was NOT detected, so part 4d's no-model-called rows are vacuous"
  fi
fi

# M10 BACKS THE SHEET GATE, for the reason M9 backs the register's, and the
# day before is sharper here than it was there. `./drill --hint` over a root
# with no sheet in it RAN, exited 0 and shipped a prompt, so part 4c's rc and
# no-model-called rows held over a runner that injected nothing at all. A
# negative row needs a runner that gets it wrong.
#
# M10. the sheet gate drops out, so a hint with no sheet ships a prompt
# carrying no ladder and no worked case. The model then classifies the
# question on the study config's four-sentence summary, which is the run that
# laddered a question Frank had marked as a mechanism question and cost him
# the hour.
# shellcheck disable=SC2016
if mutate hint-ships-without-sheet \
  's|^  if \[ "\$mode" = "hint" \] && \[ ! -r "\$STUDY_ROOT/\.claude/commands/hint\.md" \]; then$|  if false; then|'; then
  T_M10="$TMPROOT/tree-m10"
  mk_tree "$T_M10" "$MUTANT"
  printf '%s\n' "${CANONICAL[0]}" >"$T_M10/LAST-SERVED"
  STUDY_M10="$TMPROOT/study-root-m10"
  mkdir -p "$STUDY_M10/$SLUG0"
  cp -- "$ATTEMPT_DIR/Pickers.tla" "$STUDY_M10/$SLUG0/Pickers.tla"
  write_check_stub "$STUDY_M10/check"
  assert_absent "the M10 root has no sheet in it" "$STUDY_M10/$HINT_SHEET_REL"
  run_coach "$STUDY_M10" "$OUTSIDE" "$T_M10" --hint
  if [ -e "$STUB_REC/claude.argv" ]; then
    ok "control: a runner shipping a hint prompt with no sheet is DETECTED as a half-run"
  else
    nope "control: the sheet half-run was NOT detected, so part 4c's no-model-called rows are vacuous"
  fi
fi

# M11 BACKS THE OTHER HALF OF tla-1sh7.1, which is that the sheet is the
# HINT'S. Two rows say a check prompt and a style prompt carry none, and both
# were green the day before this bead, over a runner that shipped the sheet
# nowhere. So they need a runner that ships it everywhere.
#
# M11. the mode test in the prompt builder goes true, so every check prompt
# carries the ladder. That is the ladder reaching a mode that hands back the
# whole report, which is the direction the rations were never meant to run in.
#
# THE SUBSTITUTION IS ADDRESSED TO build_prompt, because the same test spells
# the same way in the banner block and an unaddressed script would change two
# lines. A mutant is one line by convention, and two of them cannot say which
# one the row below caught.
# shellcheck disable=SC2016
if mutate check-ships-the-sheet \
  '/^build_prompt() {$/,/^}$/ s|^    if \[ "\$mode" = "hint" \]; then$|    if true; then|'; then
  T_M11="$TMPROOT/tree-m11"
  mk_tree "$T_M11" "$MUTANT"
  printf '%s\n' "${CANONICAL[0]}" >"$T_M11/LAST-SERVED"
  run_coach "$STUDY_COACH" "$OUTSIDE" "$T_M11" --check
  if grep -qF -- "$HINT_SHEET_SENTINEL" "$STUB_REC/claude.stdin"; then
    ok "control: a runner shipping the sheet to --check is DETECTED"
  else
    nope "control: the sheet in a check prompt was NOT detected, so the hint-only rows are vacuous"
  fi
fi

# ---------------------------------------------------------------------------
echo
echo "== part 6: delivery, three file classes, three policies =="
# ---------------------------------------------------------------------------

if [ ! -f "$DELIVER" ]; then
  nope "scripts/deliver-drill.sh exists. There is none at $DELIVER"
else
  # A fixture source repo carrying two drills and a runner, so the real
  # corpus is not what gets delivered anywhere.
  SRC_REPO="$TMPROOT/src-repo"
  mkdir -p "$SRC_REPO/drill/core/01-alpha/verify" "$SRC_REPO/drill/sets/01-beta/verify"
  printf 'the alpha prompt\n' >"$SRC_REPO/drill/core/01-alpha/PROMPT.md"
  printf 'the alpha answer\n' >"$SRC_REPO/drill/core/01-alpha/ANSWER.md"
  printf 'the alpha trap\n'   >"$SRC_REPO/drill/core/01-alpha/META.md"
  printf 'a module\n'         >"$SRC_REPO/drill/core/01-alpha/verify/Good.tla"
  printf 'the beta prompt\n'  >"$SRC_REPO/drill/sets/01-beta/PROMPT.md"
  printf 'the beta answer\n'  >"$SRC_REPO/drill/sets/01-beta/ANSWER.md"
  printf 'the beta trap\n'    >"$SRC_REPO/drill/sets/01-beta/META.md"
  printf 'a module\n'         >"$SRC_REPO/drill/sets/01-beta/verify/Good.tla"
  cp -- "$RUNNER" "$SRC_REPO/drill/drill.sh"

  run_deliver() {
    RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$SRC_REPO" \
      bash "$DELIVER" "$@" 2>"$ERRFILE")
    RUN_RC=$?
    RUN_ERR=$(cat "$ERRFILE")
  }

  # --- a first delivery into an empty destination -------------------------
  D_NEW="$TMPROOT/dest-new"
  run_deliver "$D_NEW"
  assert_rc "a first delivery exits 0" 0
  assert_says_literal "it says it delivered the runner" \
    "runner delivered: $D_NEW/drill" "$RUN_OUT"
  assert_eq "the runner lands byte for byte" "$(cat "$RUNNER")" "$(cat "$D_NEW/drill")"
  if [ -x "$D_NEW/drill" ]; then
    ok "the runner lands executable, so ./drill works"
  else
    nope "the runner landed without the executable bit, so ./drill does not work"
  fi
  assert_absent "it lands without its extension" "$D_NEW/drill.sh"
  assert_absent "and the delivery writes no record" "$D_NEW/PROGRESS.tsv"
  assert_absent "and no pointer either" "$D_NEW/LAST-SERVED"
  assert_says_literal "the run says it leaves the record alone" \
    "left alone (the learner's record, never written here): $D_NEW/PROGRESS.tsv" "$RUN_OUT"

  # The delivered tree is a working practice tree, end to end. This is the
  # row that would have caught a runner delivered without its bit, or a
  # delivery that put it somewhere the glob cannot see from.
  run_drill "$D_NEW"
  assert_rc "the delivered runner serves a drill in the delivered tree" 0
  assert_eq "and it serves the interleaved head" "core/01-alpha" "$(served_of "$RUN_OUT")"

  # --- a second delivery over a started tree ------------------------------
  #
  # The three policies all in one run: the prompt he has written in is left
  # alone, the stale runner is refreshed, and his record is untouched.
  printf 'the alpha prompt\nAND MY OWN NOTES, WHICH MUST SURVIVE\n' \
    >"$D_NEW/core/01-alpha/PROMPT.md"
  printf '#!/usr/bin/env bash\necho a stale runner\n' >"$D_NEW/drill"
  chmod +x "$D_NEW/drill"
  printf '2026-10-13T09:00:00Z\tdone\tcore/01-alpha\n' >"$D_NEW/PROGRESS.tsv"
  RECORD_BEFORE=$(cat "$D_NEW/PROGRESS.tsv")
  PROMPT_WITH_NOTES=$(cat "$D_NEW/core/01-alpha/PROMPT.md")

  run_deliver "$D_NEW"
  assert_rc "a second delivery over a started tree exits 0" 0
  assert_says_literal "it says it refreshed the runner, and that it overwrote" \
    "runner refreshed, overwriting the copy already there: $D_NEW/drill" "$RUN_OUT"
  assert_eq "the runner is the repo's copy again" "$(cat "$RUNNER")" "$(cat "$D_NEW/drill")"
  assert_eq "the prompt he wrote in is left exactly as it was" \
    "$PROMPT_WITH_NOTES" "$(cat "$D_NEW/core/01-alpha/PROMPT.md")"
  assert_says_literal "and the run says it skipped it" \
    "skipped (exists): $D_NEW/core/01-alpha/PROMPT.md" "$RUN_OUT"
  assert_eq "his record is untouched, byte for byte" \
    "$RECORD_BEFORE" "$(cat "$D_NEW/PROGRESS.tsv")"

  # --- --check reports all three ------------------------------------------
  CHECK_BEFORE=$(snapshot "$D_NEW")
  run_deliver --check "$D_NEW"
  assert_rc "--check over a started tree exits 0" 0
  assert_says_literal "--check says it would overwrite the runner" \
    "would deliver runner, OVERWRITING the copy already there: $D_NEW/drill" "$RUN_OUT"
  assert_says_literal "--check says it would skip the prompt" \
    "would skip (exists): $D_NEW/core/01-alpha/PROMPT.md" "$RUN_OUT"
  assert_says_literal "--check says the record is never written here" \
    "left alone (the learner's record, never written here): $D_NEW/PROGRESS.tsv" "$RUN_OUT"
  assert_eq "--check writes nothing at all" "$CHECK_BEFORE" "$(snapshot "$D_NEW")"

  D_FRESH="$TMPROOT/dest-fresh"
  run_deliver --check "$D_FRESH"
  assert_says_literal "--check into an empty tree says it would deliver the runner" \
    "would deliver runner: $D_FRESH/drill" "$RUN_OUT"
  assert_never_names "and does not claim it would overwrite anything" \
    "OVERWRITING" "$RUN_OUT"
  assert_absent "--check creates no destination" "$D_FRESH"

  # --- a source with no runner is not an error ----------------------------
  NORUNNER_REPO="$TMPROOT/src-norunner"
  mkdir -p "$NORUNNER_REPO/drill/core/01-alpha"
  printf 'the alpha prompt\n' >"$NORUNNER_REPO/drill/core/01-alpha/PROMPT.md"
  D_NORUNNER="$TMPROOT/dest-norunner"
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$NORUNNER_REPO" \
    bash "$DELIVER" "$D_NORUNNER" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
  assert_rc "a source carrying no runner still exits 0" 0
  assert_says_literal "and says no runner was found" \
    "no runner at $NORUNNER_REPO/drill/drill.sh, so none lands" "$RUN_OUT"
  assert_says_literal "while the prompts still land" \
    "1 prompt(s) landed, 0 skipped," "$RUN_OUT"
  assert_absent "and nothing is placed where the runner would have gone" "$D_NORUNNER/drill"

  assert_never_names "no delivery run named the real practice tree" \
    "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 7: the pieces are where the rest of the tree expects them =="
# ---------------------------------------------------------------------------

# Gate, don't advise. A suite in the tree and absent from the registry is
# worse than a missing suite, because `scripts/test --list` reads as the
# authority on what is gated.
TEST_SCRIPT="$REPO_ROOT/scripts/test"
if [ ! -f "$TEST_SCRIPT" ]; then
  nope "scripts/test exists. There is none at $TEST_SCRIPT"
else
  assert_says_literal "scripts/test carries a fast-tier row for this suite" \
    'fast|' "$(grep -F -- 'harness/test-drill-runner.sh' "$TEST_SCRIPT")"
fi

# The header of the delivery script has to say that never-overwrite is per
# class now, because an always-overwrite path in a script whose header says
# otherwise is a trap.
if [ ! -f "$DELIVER" ]; then
  nope "the delivery script argues the per-class rule. There is no script"
else
  # The whole leading comment block, cut at the first line of code, so the
  # rows below do not go red the next time the header grows a paragraph.
  DELIVER_HEAD=$(awk '/^set -uo pipefail/ { exit } { print }' "$DELIVER")
  assert_says_literal "the delivery header names the three classes" \
    "THREE FILE CLASSES, THREE POLICIES" "$DELIVER_HEAD"
  assert_says_literal "and says the runner is always overwritten" \
    "ALWAYS overwritten" "$DELIVER_HEAD"
  assert_says_literal "and says the record is never written there" \
    "NEVER written, read or touched here" "$DELIVER_HEAD"
fi

# The runner's own header has to argue the shaky ordering, because canonical
# order is the obvious reading and it starves.
RUNNER_HEAD=$(awk '/^set -uo pipefail/ { exit } { print }' "$RUNNER")
assert_says_literal "the runner argues why the shaky tail is ordered by mark time" \
  "oldest mark first" "$RUNNER_HEAD"
assert_says_literal "and names the starvation it avoids" "would starve" "$RUNNER_HEAD"

# The banned TSV read, which strips a leading and a trailing empty field and
# collapses runs of the separator, so it loses data without saying so. Checked
# over code rather than raw text, because the runner's header explains the ban
# and would trip a raw match.
BANNED_TSV_READ="IFS=\$'\t' read"
if grep -qF -- "$BANNED_TSV_READ" <<<"$RUNNER_CODE"; then
  nope "the runner field-splits a TSV with the banned read, which loses data without saying so"
else
  ok "the runner does not field-split a TSV with the banned read"
fi
# The control. A pattern that stopped matching would pass the row above over
# a runner that does field-split.
if grep -qF -- "$BANNED_TSV_READ" <<<'  while IFS=$'"'"'\t'"'"' read -r a b c; do'; then
  ok "control: the banned read is DETECTED when it is there"
else
  nope "control: the banned read pattern matched nothing, so the row above it is vacuous"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
