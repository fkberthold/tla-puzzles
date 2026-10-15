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
# ---------------------------------------------------------------------------
# WHY THE MUTANTS ARE HERE, AND WHY THEY ARE THE POINT
#
# Most of the rows below are of the form "the order came back the way the
# contract says", which is also what a suite driving a runner that silently
# stopped working would report if the comparison went slack. So part 5 copies
# the real runner, breaks ONE line of it, and requires the row that owns that
# line to go red. Four mutants, four rows:
#
#   family-major order   the index drops out of the sort key
#   shaky retires        shaky behaves like done and never comes back
#   truncating record    the log is written rather than appended to
#   a pointer outside    LAST-SERVED lands one directory up
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
echo "== part 5: the mutants, which is what makes part 1 and part 3 mean something =="
# ---------------------------------------------------------------------------

MUTANT_DIR="$TMPROOT/mutants"
mkdir -p "$MUTANT_DIR"

# mutate <name> <sed-script>: a copy of the real runner with one line changed.
#
# Three separate `local` statements, because `local a=$1 b=$MUTANT_DIR/$a`
# reads $a as unbound under `set -u` on this bash.
mutate() {
  local name="$1"
  local script="$2"
  local out="$MUTANT_DIR/$name"
  sed "$script" "$RUNNER" >"$out"
  chmod +x "$out"
  if [ "$(cat "$out")" = "$(cat "$RUNNER")" ]; then
    nope "mutant $name changed nothing, so its control below is vacuous"
    return 1
  fi
  printf '%s\n' "$out"
}

# Every sed script below is single-quoted on purpose. The whole point of a
# mutation is to put a literal line of the runner's source on both sides of
# the substitution, so an expansion here would replace the pattern with
# whatever this shell holds and the mutation would match nothing. mutate()
# fails loudly in that case, which is the other half of the guard.
#
# M1. the index drops out of the sort key, so the order goes family-major.
# shellcheck disable=SC2016
M1=$(mutate family-major 's|^    keyed+=("${idx}${TAB}${item}")$|    keyed+=("${item}${TAB}${item}")|')
if [ -n "$M1" ]; then
  T_M1="$TMPROOT/tree-m1"
  mk_tree "$T_M1" "$M1"
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
M2=$(mutate shaky-retires 's|^        shaky) shaky_keyed+=.*$|        shaky) continue ;;|')
if [ -n "$M2" ]; then
  T_M2="$TMPROOT/tree-m2"
  mk_tree "$T_M2" "$M2"
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
M3=$(mutate truncating-record 's|>>"\$PROGRESS"|>"$PROGRESS"|')
if [ -n "$M3" ]; then
  T_M3="$TMPROOT/tree-m3"
  mk_tree "$T_M3" "$M3"
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
M4=$(mutate pointer-escapes 's|^POINTER="\$HERE/LAST-SERVED"$|POINTER="$HERE/../LAST-SERVED"|')
if [ -n "$M4" ]; then
  mkdir -p "$TMPROOT/m4-outer"
  T_M4="$TMPROOT/m4-outer/tree"
  mk_tree "$T_M4" "$M4"
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
M5=$(mutate study-failure-is-fatal \
  's|^  echo "drill: cannot create the study directory at \$STUDY_ROOT/\$slug, so work" >&2$|  exit 9|')
if [ -n "$M5" ]; then
  T_M5="$TMPROOT/tree-m5"
  mk_tree "$T_M5" "$M5"
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
M6=$(mutate study-claims-every-serve 's|^  if \[ -d "\$STUDY_ROOT/\$slug" \]; then$|  if false; then|')
if [ -n "$M6" ]; then
  T_M6="$TMPROOT/tree-m6"
  mk_tree "$T_M6" "$M6"
  STUDY_M6="$TMPROOT/study-root-m6"
  mkdir -p "$STUDY_M6/$SLUG0"
  run_drill_study "$STUDY_M6" "$T_M6"
  if grep -qF -- "created" <<<"$RUN_OUT"; then
    ok "control: a runner claiming a creation over an existing directory is DETECTED"
  else
    nope "control: the false creation claim was NOT detected, so the no-claim row is vacuous"
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
