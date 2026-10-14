#!/usr/bin/env bash
# test-deliver-drill.sh: executable spec for scripts/deliver-drill.sh
# (bead tla-s5iz).
#
# Pins the RED invariant from the bead:
#
#   A delivered drill item directory contains exactly one file, PROMPT.md, byte
#   for byte the source's. Every other top-level entry of the source item is
#   withheld and named on stdout. Delivering over a destination that already
#   holds an item changes no file there and exits 0.
#
# ---------------------------------------------------------------------------
# WHY THIS SUITE EXISTS, AND WHAT IT IS SHAPED AGAINST
#
# scripts/deliver-drill.sh names a file. Its sibling
# scripts/deliver-problems.sh refuses to, because on 2026-10-02 a guessed
# manifest deleted 39 delivered files, among them bonded-store's
# BondedStore.tla and river-call's RiverCall.cfg. The deviation is argued in
# deliver-drill.sh's own header and it rests on two things being true at once:
# the one name that lands fails SAFE, and harness/test-drill.sh holds the item
# shape still so the name cannot drift out of date quietly.
#
# This suite is the first half. It asserts that the one name is the ONLY thing
# that lands, that each withheld entry is reported rather than dropped
# silently, and that a second run over a started item leaves it alone.
#
# THE FIXTURES CARRY A PLANTED MUTATION, three entries no name list would
# guess: SURPRISE.tla, a notes/ directory, and a .hidden-draft dotfile. A
# script that delivered the item's whole tree hands all three over. A script
# that withheld only the three names of today's corpus hands all three over
# too, and that is the UNSAFE design the bead rejected. The one under test
# withholds them and says so. Against the real 32 items the three designs are
# indistinguishable, which is how a manifest bug survives being looked at.
#
# Two rows exist only to keep the mutation honest, under "the fixture is not
# vacuous". A fixture whose mutation drifted out of it would certify a script
# that leaks.
#
# ---------------------------------------------------------------------------
# THE CONTRACT
#
#   scripts/deliver-drill.sh [--check] [dest-root]
#
#   <dest-root> defaults to $HOME/tla-practice/drill. There is no item
#   argument: the corpus is the unit, and the never-overwrite rule is what
#   makes a second whole-corpus run the normal way to deliver a new item.
#
#   The source is <repo>/drill, and DELIVER_DRILL_SRC_ROOT overrides <repo>.
#   An item is a directory at drill/<family>/<NN-slug>. A source with no drill/
#   directory, or with no item under it, is fatal.
#
#   Each item delivers one file, to <dest-root>/<family>/<NN-slug>/PROMPT.md.
#   Every other top-level entry of the item is withheld and reported on stdout
#   as "withheld (not PROMPT.md): <source path>", one line per entry, dotfiles
#   included and a directory as one line rather than recursively.
#
#   No file is ever overwritten. An existing one is left alone and reported as
#   "skipped (exists): <path>", and the run still exits 0. Nothing is deleted.
#
#   An item carrying no PROMPT.md is named on stderr, its siblings still
#   deliver, and the run exits 1.
#
#   --check resolves everything, prints what it would deliver, and writes
#   nothing.
#
#   Both modes end on a counts line. --check prints
#   "<n> prompt(s) to land, <n> already there, <n> path(s) withheld" and a real
#   run prints "<n> prompt(s) landed, <n> skipped, <n> path(s) withheld".
#
# ---------------------------------------------------------------------------
# WHY EVERY RUN IS SANDBOXED TWICE
#
# ~/tla-practice is not a git repo, it holds the only copy of the work done in
# it, and on 2026-10-12 it took all 32 prompts by hand. A write there does not
# come back. So this suite never names that path as a destination and never
# writes under it. Every run passes an explicit dest-root under a fresh mktemp
# root, AND redirects HOME, which is where the default dest-root resolves from.
#
# The default-root section goes further, because a sandboxed HOME does nothing
# for a script that hardcodes a path. That section runs only --check, which the
# contract says writes nothing, and it reads a source that exists in the
# sandbox and nowhere else before it concludes anything.
#
# The suite reads the real repo tree twice, both times --check and both times
# with the counts derived from the tree rather than written down. 32 items and
# 96 withheld paths is what central measured on 2026-10-12, and it is not
# asserted as a number here: 29 more items are in flight in four worktrees, so
# a literal 32 in this file would be wrong within the week.
#
# ---------------------------------------------------------------------------
# WHAT THE ASSERTIONS ARE SHAPED AROUND
#
# The expected manifest is derived independently of the script. The script
# walks each item with find and skips the one name. This suite derives the same
# two sets with find's own -name predicate, so a bug in one does not cancel a
# bug in the other.
#
# Absence rows carry the non-vacuity control the sibling suites use. "This file
# never landed" only means something once something else did land, and
# "nothing changed" only means something once the run it survived exited the
# code the contract promised.
#
# Usage:  harness/test-deliver-drill.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="scripts/deliver-drill.sh"
DRILL_SUITE="harness/test-drill.sh"
TEST_RUNNER="scripts/test"

# The real practice tree, captured before anything is sandboxed. Used only to
# assert that no run ever names it. Nothing here reads or writes under it.
REAL_PRACTICE="$HOME/tla-practice"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# Read once. Several helpers refuse to draw a conclusion from a non-zero exit
# while the script is missing, because a missing script exits 127 and 127 says
# nothing about the contract.
SCRIPT_PRESENT=0
[ -f "$SCRIPT" ] && SCRIPT_PRESENT=1

TMPROOT=$(mktemp -d -t tla_deliver_drill.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

FIX_REPO="$TMPROOT/repo"
SANDBOX_HOME="$TMPROOT/home"
DEFAULT_ROOT="$SANDBOX_HOME/tla-practice/drill"
ERRFILE="$TMPROOT/stderr.txt"

DEST_MAIN="$TMPROOT/dest-main"         # the happy path
DEST_KEEP="$TMPROOT/dest-keep"         # pre-seeded, for the never-overwrite rule
DEST_CHECK="$TMPROOT/dest-check"       # --check only, never written
DEST_STRAY="$TMPROOT/dest-stray"       # carries learner work beside the prompt
DEST_NOPROMPT="$TMPROOT/dest-noprompt" # an item with nothing to deliver
DEST_REAL="$TMPROOT/dest-real"         # the real corpus, read from the repo
DEST_TWICE="$TMPROOT/dest-twice"       # delivered, then delivered again
DEST_PLAINDIFF="$TMPROOT/dest-plaindiff" # a stale prompt, and no refresh flag
DEST_REFRESH="$TMPROOT/dest-refresh"   # --refresh-prompts, the whole mixed case
DEST_RCHECK="$TMPROOT/dest-rcheck"     # --check --refresh-prompts, never created
DEST_RCHECK2="$TMPROOT/dest-rcheck2"   # --check --refresh-prompts over a real tree

# The reference mtime every refresh fixture is pre-dated to, as an epoch second
# so no timezone enters the comparison. A file still carrying it was not
# written, and that is the only way to tell an identical file that was left
# alone from an identical file that was copied over itself: cp truncates in
# place, so the inode does not move and the contents cannot tell you either.
REF_EPOCH=981173106

mkdir -p "$SANDBOX_HOME"

# ---------------------------------------------------------------------------
# Fixture source tree.
#
# mk_item <repo-root> <family/NN-slug>: the four-entry shape the real corpus
# has, with verify/ holding two files so a recursive delivery would be visible
# as a count rather than as one name.
# ---------------------------------------------------------------------------

mk_item() {
  local root="$1" rel="$2"
  local d="$root/drill/$rel"
  mkdir -p "$d/verify"
  printf 'prompt for %s\n' "$rel"  >"$d/PROMPT.md"
  printf 'answer for %s\n' "$rel"  >"$d/ANSWER.md"
  printf 'trap for %s\n' "$rel"    >"$d/META.md"
  printf 'module for %s\n' "$rel"  >"$d/verify/Good.tla"
  printf 'config for %s\n' "$rel"  >"$d/verify/Good.cfg"
}

mk_item "$FIX_REPO" "core/01-alpha"
mk_item "$FIX_REPO" "core/02-beta"
mk_item "$FIX_REPO" "temporal/01-gamma"

# THE PLANTED MUTATION, on core/02-beta. Three entries no name list would
# guess, one of them a dotfile and one of them a directory.
printf 'a starter no list would name\n' >"$FIX_REPO/drill/core/02-beta/SURPRISE.tla"
mkdir -p "$FIX_REPO/drill/core/02-beta/notes/deep"
printf 'two levels down\n' >"$FIX_REPO/drill/core/02-beta/notes/deep/DEEP.md"
printf 'an unfinished thought\n' >"$FIX_REPO/drill/core/02-beta/.hidden-draft"

# Files one level up from an item. drill/INVENTORY.md and drill/COLD-LIST.md
# live here in the real tree, so a run that treated them as families would
# break on the live corpus and not on a tidy fixture.
printf 'the construct inventory\n' >"$FIX_REPO/drill/INVENTORY.md"
printf 'the cold list\n'           >"$FIX_REPO/drill/COLD-LIST.md"

# A second source root whose one item has no prompt. Kept apart from the main
# fixture so every other row runs against a corpus that is whole.
NOPROMPT_REPO="$TMPROOT/repo-noprompt"
mk_item "$NOPROMPT_REPO" "core/01-alpha"
mkdir -p "$NOPROMPT_REPO/drill/core/02-headless/verify"
printf 'the answer with no question\n' >"$NOPROMPT_REPO/drill/core/02-headless/ANSWER.md"
printf 'a trap with no question\n'     >"$NOPROMPT_REPO/drill/core/02-headless/META.md"

# A source root with a drill/ directory and no item in it.
EMPTY_REPO="$TMPROOT/repo-empty"
mkdir -p "$EMPTY_REPO/drill"
printf 'an inventory and nothing else\n' >"$EMPTY_REPO/drill/INVENTORY.md"

# A source root with no drill/ directory at all.
NODRILL_REPO="$TMPROOT/repo-nodrill"
mkdir -p "$NODRILL_REPO/puzzles"

# The sandboxed default root's source. omega-sandbox-only exists here and in no
# other fixture and in no real tree, so seeing it come back is the evidence
# that the sandbox is what got read.
SANDBOX_REPO="$TMPROOT/repo-sandbox"
mk_item "$SANDBOX_REPO" "core/01-omega-sandbox-only"

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

RUN_OUT=""
RUN_ERR=""
RUN_RC=0

# run_deliver [args...]
#
# HOME is redirected on every run, and every caller below also passes an
# explicit dest-root, so a script that dropped its argument would still write
# into the sandbox rather than into Frank's practice tree.
run_deliver() {
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$FIX_REPO" \
    bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_deliver_from <src-root> [args...]: the same, against another fixture
# source root.
run_deliver_from() {
  local src="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$src" \
    bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_deliver_realrepo [args...]
#
# The one runner reading the real repo as its source. The destination is still
# a temp directory, and every caller passes --check.
run_deliver_realrepo() {
  RUN_OUT=$(HOME="$SANDBOX_HOME" bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# relfiles <dir>: every file under a directory, sorted, relative to it.
relfiles() {
  local dir="$1"
  [ -d "$dir" ] || { printf '<absent>\n'; return; }
  (cd "$dir" && find . -type f | LC_ALL=C sort)
}

# expected_prompts <src-root>
#
# The expected manifest, derived from the tree with find's -name predicate.
# The script walks each item's entries and compares a basename, so the two
# mechanisms differ on purpose.
expected_prompts() {
  local root="$1/drill"
  [ -d "$root" ] || { printf '<absent>\n'; return; }
  (cd "$root" && find . -mindepth 3 -maxdepth 3 -name PROMPT.md | LC_ALL=C sort)
}

# count_items <src-root>: items, counted independently of the script.
count_items() {
  local root="$1/drill"
  [ -d "$root" ] || { printf '0\n'; return; }
  find "$root" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "$root/.*" | wc -l
}

# count_withheld <src-root>
#
# Every top-level entry of every item that is not the prompt. Dotfiles counted,
# a directory counted once. This is the number the contract's counts line has
# to agree with, and deriving it is what keeps a literal out of this file.
count_withheld() {
  local root="$1/drill" item total=0 n
  [ -d "$root" ] || { printf '0\n'; return; }
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    n=$(find "$item" -mindepth 1 -maxdepth 1 ! -name PROMPT.md | wc -l)
    total=$((total + n))
  done < <(find "$root" -mindepth 2 -maxdepth 2 -type d \
    ! -name '.*' ! -path "$root/.*" | LC_ALL=C sort)
  printf '%s\n' "$total"
}

# snapshot <dir>: names and contents, for the "changed nothing" rows.
snapshot() {
  local root="$1"
  [ -d "$root" ] || { printf '<absent>\n'; return; }
  (cd "$root" && find . -mindepth 1 | LC_ALL=C sort)
  (cd "$root" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s :: %s\n' "$f" "$(cat "$f")"
  done)
}

# predate_tree <dir>: set every regular file's mtime to the reference second.
predate_tree() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    touch -d "@$REF_EPOCH" -- "$f"
  done < <(find "$1" -type f | LC_ALL=C sort)
}

# mtime_of <path>
mtime_of() {
  [ -e "$1" ] || { printf 'missing\n'; return; }
  stat -c %Y -- "$1"
}

# touched_files <dir>: every regular file whose mtime has moved off the
# reference second, which is every file the run under test wrote.
touched_files() {
  local root="$1" f
  [ -d "$root" ] || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$(stat -c %Y -- "$f")" = "$REF_EPOCH" ] && continue
    printf '%s\n' "${f#"$root/"}"
  done < <(find "$root" -type f | LC_ALL=C sort)
}

# assert_touched_count <label> <dir> <wanted>
#
# The whole-tree form of "it wrote what it said it wrote". Every file is
# pre-dated before the run, so the count below is the run's write footprint
# over files that already existed, plus every file it created.
assert_touched_count() {
  local label="$1" dir="$2" want="$3" got names
  names=$(touched_files "$dir")
  got=$(grep -c . <<<"$names")
  [ -n "$names" ] || got=0
  if [ "$got" = "$want" ]; then
    ok "$label"
  else
    nope "$label. Wanted $want file(s) written, got $got: $(tr '\n' ' ' <<<"$names")"
  fi
}

# assert_mtime_is <label> <path> <wanted>
assert_mtime_is() {
  local label="$1" path="$2" want="$3" got
  got=$(mtime_of "$path")
  if [ "$got" = "$want" ]; then
    ok "$label"
  else
    nope "$label. Wanted mtime $want, got $got: $path"
  fi
}

# assert_mtime_moved <label> <path> <reference>
#
# The positive control for the two rows above. If stat came back constant, or
# the pre-dating never happened, this row and its sibling cannot both hold.
assert_mtime_moved() {
  local label="$1" path="$2" ref="$3" got
  got=$(mtime_of "$path")
  if [ "$got" = "missing" ]; then
    nope "$label. No file at $path"
  elif [ "$got" != "$ref" ]; then
    ok "$label"
  else
    nope "$label. The mtime is still the reference $ref, so the file was never written: $path"
  fi
}

# assert_rc0 <label>
assert_rc0() {
  if [ "$RUN_RC" -eq 0 ]; then
    ok "$1"
  else
    nope "$1 (rc=$RUN_RC), stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  fi
}

# assert_rc <label> <wanted>
#
# Exact, never "non-zero". A missing script exits 127, and 127 satisfies every
# non-zero test anybody writes.
assert_rc() {
  if [ "$RUN_RC" -eq "$2" ]; then
    ok "$1"
  else
    nope "$1 (rc=$RUN_RC, wanted $2), stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  fi
}

# assert_says <label> <extended-regex> <captured-text>
#
# Here-string, never a pipe. `producer | grep -q` returns 141 under pipefail and
# reports a present pattern as absent (bead tla-kr9).
assert_says() {
  local label="$1" pattern="$2" body="$3"
  if grep -qE -- "$pattern" <<<"$body"; then
    ok "$label"
  else
    nope "$label. No line matched: $pattern"
  fi
}

# assert_says_literal <label> <literal> <captured-text>
assert_says_literal() {
  local label="$1" needle="$2" body="$3"
  if grep -qF -- "$needle" <<<"$body"; then
    ok "$label"
  else
    nope "$label. The output never said: $needle"
  fi
}

# assert_never_names <label> <literal> <captured-text>
#
# Fixed-string, because what is being looked for is a filesystem path, and a
# path read as a regex matches more than itself.
assert_never_names() {
  local label="$1" needle="$2" body="$3"
  if grep -qF -- "$needle" <<<"$body"; then
    nope "$label. The output named it: $needle"
  else
    ok "$label"
  fi
}

# assert_manifest <label> <src-root> <dest-root>
#
# The head of the invariant. The delivered file set has to equal the set of
# PROMPT.md paths under the source, exactly, both ways.
assert_manifest() {
  local label="$1" src="$2" dest="$3" want got
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The delivery failed (rc=$RUN_RC), so the manifest proves nothing"
    return
  fi
  want=$(expected_prompts "$src")
  got=$(relfiles "$dest")
  if [ -z "$want" ] || [ "$want" = "<absent>" ]; then
    nope "$label. The fixture source carries no prompt, so the comparison is vacuous: $src"
  elif [ "$got" = "<absent>" ]; then
    nope "$label. Nothing landed at all: $dest"
  elif [ "$want" = "$got" ]; then
    ok "$label"
  else
    nope "$label. Wanted [$(tr '\n' ' ' <<<"$want")] got [$(tr '\n' ' ' <<<"$got")]"
  fi
}

# assert_absent <label> <path>
assert_absent() {
  if [ -e "$2" ]; then
    nope "$1. It landed: $2"
  else
    ok "$1"
  fi
}

# assert_file_is <label> <path> <wanted-contents>
assert_file_is() {
  local label="$1" path="$2" want="$3" got
  if [ ! -f "$path" ]; then
    nope "$label. No file at $path"
    return
  fi
  got=$(cat "$path")
  if [ "$got" = "$want" ]; then
    ok "$label"
  else
    nope "$label. Wanted [$want] got [$got]"
  fi
}

# assert_unchanged <label> <dir> <before-snapshot> <wanted-rc>
#
# The non-vacuity control is the rc. A run that never started leaves the tree
# exactly as it found it, so "nothing changed" only means something once the
# run it survived exited the code the contract promised.
assert_unchanged() {
  local label="$1" dir="$2" before="$3" want_rc="$4" after
  after=$(snapshot "$dir")
  if [ "$RUN_RC" -ne "$want_rc" ]; then
    nope "$label. The run exited $RUN_RC rather than $want_rc, so no-change proves nothing"
    return
  fi
  if [ "$before" = "$after" ]; then
    ok "$label"
  else
    nope "$label. The tree changed under $dir"
  fi
}

# ---------------------------------------------------------------------------
echo "== the manifest: one name lands, every other entry is withheld =="
# ---------------------------------------------------------------------------

run_deliver "$DEST_MAIN"

assert_rc0 "a whole-corpus delivery exits 0"

assert_manifest "the delivered tree holds exactly the source's PROMPT.md files" \
  "$FIX_REPO" "$DEST_MAIN"

assert_file_is "the prompt lands byte for byte" \
  "$DEST_MAIN/core/01-alpha/PROMPT.md" "$(cat "$FIX_REPO/drill/core/01-alpha/PROMPT.md")"

assert_says_literal "the counts line names what landed, what was skipped and what was withheld" \
  "3 prompt(s) landed, 0 skipped, $(count_withheld "$FIX_REPO") path(s) withheld" "$RUN_OUT"

assert_absent "ANSWER.md never lands" "$DEST_MAIN/core/01-alpha/ANSWER.md"
assert_absent "META.md never lands, which is the one that telegraphs" \
  "$DEST_MAIN/core/01-alpha/META.md"
assert_absent "verify/ never lands" "$DEST_MAIN/core/01-alpha/verify"

# The mutation. A script delivering the tree hands these over, and so does one
# withholding only today's three names.
assert_absent "a starter no name list would guess never lands" \
  "$DEST_MAIN/core/02-beta/SURPRISE.tla"
assert_absent "a directory no name list would guess never lands" \
  "$DEST_MAIN/core/02-beta/notes"
assert_absent "a dotfile no name list would guess never lands" \
  "$DEST_MAIN/core/02-beta/.hidden-draft"

# The withheld report, per entry. A directory is one line rather than its
# contents, which is why the count can be compared against count_withheld.
assert_says_literal "the withheld report names ANSWER.md" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/01-alpha/ANSWER.md" "$RUN_OUT"
assert_says_literal "the withheld report names META.md" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/01-alpha/META.md" "$RUN_OUT"
assert_says_literal "the withheld report names verify as one entry" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/01-alpha/verify" "$RUN_OUT"
assert_says_literal "the withheld report names the planted starter" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/02-beta/SURPRISE.tla" "$RUN_OUT"
assert_says_literal "the withheld report names the planted dotfile" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/02-beta/.hidden-draft" "$RUN_OUT"

WITHHELD_LINES=$(grep -cF -- "withheld (not PROMPT.md): " <<<"$RUN_OUT")
WITHHELD_WANT=$(count_withheld "$FIX_REPO")
if [ "$WITHHELD_LINES" = "$WITHHELD_WANT" ]; then
  ok "the withheld report is complete: ${WITHHELD_LINES} lines against ${WITHHELD_WANT} non-prompt entries"
else
  nope "the withheld report is incomplete: ${WITHHELD_LINES} lines against ${WITHHELD_WANT} non-prompt entries"
fi

assert_says_literal "the run says which source it read" "source: $FIX_REPO/drill" "$RUN_OUT"
assert_says_literal "the run says which destination it wrote" \
  "destination: $DEST_MAIN" "$RUN_OUT"

# The family-level files one directory up are not items and are not delivered.
assert_absent "drill/INVENTORY.md is not an item and never lands" "$DEST_MAIN/INVENTORY.md"
assert_absent "drill/COLD-LIST.md is not an item and never lands" "$DEST_MAIN/COLD-LIST.md"

# ---------------------------------------------------------------------------
echo
echo "== the fixture is not vacuous =="
# ---------------------------------------------------------------------------

# A mutation that drifted out of the fixture would let a leaking script pass
# every absence row above.
if [ -f "$FIX_REPO/drill/core/02-beta/SURPRISE.tla" ] &&
   [ -f "$FIX_REPO/drill/core/02-beta/notes/deep/DEEP.md" ] &&
   [ -f "$FIX_REPO/drill/core/02-beta/.hidden-draft" ]; then
  ok "the source still carries all three planted entries"
else
  nope "the planted mutation has drifted out of the fixture, so the absence rows prove nothing"
fi

if [ "$WITHHELD_WANT" -ge 9 ]; then
  ok "the source carries ${WITHHELD_WANT} non-prompt entries, so there is something to withhold"
else
  nope "the source carries only ${WITHHELD_WANT} non-prompt entries, which is fewer than the fixture builds"
fi

# ---------------------------------------------------------------------------
echo
echo "== never overwrite: the path central exercises first =="
# ---------------------------------------------------------------------------

# The real tree already holds all 32 prompts, delivered by hand on 2026-10-12,
# so the first real run of this script skips every one of them. A clobber here
# would land on work that has no second copy anywhere.
mkdir -p "$DEST_KEEP/core/01-alpha" "$DEST_KEEP/core/02-beta"
printf 'my own notes on this one\n' >"$DEST_KEEP/core/01-alpha/PROMPT.md"
printf 'half a module\n'            >"$DEST_KEEP/core/01-alpha/Alpha.tla"
printf 'the prompt as delivered\n'  >"$DEST_KEEP/core/02-beta/PROMPT.md"
KEEP_BEFORE_ALPHA=$(snapshot "$DEST_KEEP/core/01-alpha")

run_deliver "$DEST_KEEP"

assert_rc0 "a destination that already holds an item exits 0"

assert_file_is "an edited prompt is left exactly as it was" \
  "$DEST_KEEP/core/01-alpha/PROMPT.md" "my own notes on this one"

assert_says_literal "the skip is reported rather than silent" \
  "skipped (exists): $DEST_KEEP/core/01-alpha/PROMPT.md" "$RUN_OUT"

assert_says_literal "the counts line separates what landed from what was skipped" \
  "1 prompt(s) landed, 2 skipped," "$RUN_OUT"

assert_file_is "an untouched sibling item still lands" \
  "$DEST_KEEP/temporal/01-gamma/PROMPT.md" \
  "$(cat "$FIX_REPO/drill/temporal/01-gamma/PROMPT.md")"

assert_unchanged "the started item's directory is untouched, work and all" \
  "$DEST_KEEP/core/01-alpha" "$KEEP_BEFORE_ALPHA" 0

# ---------------------------------------------------------------------------
echo
echo "== nothing is ever deleted =="
# ---------------------------------------------------------------------------

# The 2026-10-02 incident was a deletion, not a leak. This script has no delete
# path, and the row that would catch one growing is a destination carrying work
# the source knows nothing about.
mkdir -p "$DEST_STRAY/core/01-alpha" "$DEST_STRAY/core/09-mine" "$DEST_STRAY/traces"
printf 'my attempt\n'       >"$DEST_STRAY/core/01-alpha/Alpha.tla"
printf 'a drill of my own\n' >"$DEST_STRAY/core/09-mine/PROMPT.md"
printf 'a trace I kept\n'   >"$DEST_STRAY/traces/one.txt"
STRAY_BEFORE=$(snapshot "$DEST_STRAY/core/09-mine")
STRAY_TRACES_BEFORE=$(snapshot "$DEST_STRAY/traces")

run_deliver "$DEST_STRAY"

assert_rc0 "a destination carrying its own work exits 0"

assert_file_is "a learner's own module beside the prompt survives" \
  "$DEST_STRAY/core/01-alpha/Alpha.tla" "my attempt"

assert_unchanged "an item the source does not have survives whole" \
  "$DEST_STRAY/core/09-mine" "$STRAY_BEFORE" 0

assert_unchanged "a directory the source does not have survives whole" \
  "$DEST_STRAY/traces" "$STRAY_TRACES_BEFORE" 0

# ---------------------------------------------------------------------------
echo
echo "== --refresh-prompts, and the default that stays never-overwrite =="
# ---------------------------------------------------------------------------

# On 2026-10-14 central measured the practice tree against the repo: 15 of 64
# delivered prompts differed, 49 were byte for byte. Two of the 15 were content
# fixes, and under never-overwrite the tree would have served the telegraphed
# version of those two drills for good. So the flag exists. What it must not do
# is arrive as a change in the default, which is why the first rows here run
# the same fixture WITHOUT it.
#
# seed_refresh_dest <dest-root>: one prompt that differs, one byte for byte,
# one item the source does not have, the learner's record, and work beside a
# prompt. Every file is pre-dated, so the run's write footprint is readable off
# the mtimes afterwards.
seed_refresh_dest() {
  local dest="$1"
  mkdir -p "$dest/core/01-alpha" "$dest/core/02-beta" "$dest/core/09-mine" \
    "$dest/traces"
  printf 'the old telegraphed prompt\n' >"$dest/core/01-alpha/PROMPT.md"
  printf 'half a module\n'             >"$dest/core/01-alpha/Alpha.tla"
  cp -- "$FIX_REPO/drill/core/02-beta/PROMPT.md" "$dest/core/02-beta/PROMPT.md"
  printf 'a drill of my own\n'         >"$dest/core/09-mine/PROMPT.md"
  printf 'a trace I kept\n'            >"$dest/traces/one.txt"
  printf 'core/01-alpha\t1\n'          >"$dest/PROGRESS.tsv"
  printf 'core/01-alpha\n'             >"$dest/LAST-SERVED"
  predate_tree "$dest"
}

# --- the default, which is the regression that matters most ----------------

seed_refresh_dest "$DEST_PLAINDIFF"

run_deliver "$DEST_PLAINDIFF"

assert_rc0 "a plain run over a stale prompt exits 0"

assert_file_is "a plain run leaves a prompt that differs from the source exactly as it was" \
  "$DEST_PLAINDIFF/core/01-alpha/PROMPT.md" "the old telegraphed prompt"

assert_mtime_is "and does not even open it" \
  "$DEST_PLAINDIFF/core/01-alpha/PROMPT.md" "$REF_EPOCH"

assert_says_literal "a plain run reports the stale prompt as a skip" \
  "skipped (exists): $DEST_PLAINDIFF/core/01-alpha/PROMPT.md" "$RUN_OUT"

assert_never_names "a plain run never says it replaced anything" \
  "replaced" "$RUN_OUT"

assert_says_literal "a plain run's counts line is the one it has always printed" \
  "1 prompt(s) landed, 2 skipped, $(count_withheld "$FIX_REPO") path(s) withheld" "$RUN_OUT"

assert_touched_count "a plain run writes exactly the one file it says it landed" \
  "$DEST_PLAINDIFF" 1

# --- the flag --------------------------------------------------------------

seed_refresh_dest "$DEST_REFRESH"
REFRESH_STRAY_BEFORE=$(snapshot "$DEST_REFRESH/core/09-mine")
REFRESH_TRACES_BEFORE=$(snapshot "$DEST_REFRESH/traces")

run_deliver --refresh-prompts "$DEST_REFRESH"

assert_rc0 "--refresh-prompts exits 0"

assert_file_is "a prompt that differs is replaced with the source's" \
  "$DEST_REFRESH/core/01-alpha/PROMPT.md" \
  "$(cat "$FIX_REPO/drill/core/01-alpha/PROMPT.md")"

assert_mtime_moved "and the replacement is a real write" \
  "$DEST_REFRESH/core/01-alpha/PROMPT.md" "$REF_EPOCH"

assert_says_literal "every replacement names its path" \
  "replaced (the source differs): $DEST_REFRESH/core/01-alpha/PROMPT.md" "$RUN_OUT"

assert_mtime_is "a prompt that is byte for byte is not touched at all" \
  "$DEST_REFRESH/core/02-beta/PROMPT.md" "$REF_EPOCH"

assert_says_literal "and the run says it left that one alone" \
  "left alone (identical to the source): $DEST_REFRESH/core/02-beta/PROMPT.md" "$RUN_OUT"

assert_file_is "an item the destination did not have still lands" \
  "$DEST_REFRESH/temporal/01-gamma/PROMPT.md" \
  "$(cat "$FIX_REPO/drill/temporal/01-gamma/PROMPT.md")"

assert_says_literal "the counts line separates landed, replaced and left alone" \
  "1 prompt(s) landed, 1 replaced, 1 left alone, $(count_withheld "$FIX_REPO") path(s) withheld" \
  "$RUN_OUT"

# The counts line is only worth something if it agrees with the filesystem.
# One landed and one replaced is two files written, and nothing else in the
# tree may have moved.
assert_touched_count "--refresh-prompts writes exactly the files its counts line claims" \
  "$DEST_REFRESH" 2

# The withholding is unchanged by the flag. ANSWER.md is the one that hands
# over the answer and META.md is the one that names the trap in a line.
assert_absent "ANSWER.md never lands under --refresh-prompts either" \
  "$DEST_REFRESH/core/01-alpha/ANSWER.md"
assert_absent "META.md never lands under --refresh-prompts either" \
  "$DEST_REFRESH/core/01-alpha/META.md"
assert_absent "verify/ never lands under --refresh-prompts either" \
  "$DEST_REFRESH/core/01-alpha/verify"
assert_absent "the planted starter never lands under --refresh-prompts either" \
  "$DEST_REFRESH/core/02-beta/SURPRISE.tla"

assert_says_literal "the withholding is still reported under the flag" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/01-alpha/ANSWER.md" "$RUN_OUT"

# The learner's record. The runner owns both files and the practice tree holds
# the only copy, so nothing here goes near them under any flag.
assert_mtime_is "PROGRESS.tsv is not touched under --refresh-prompts" \
  "$DEST_REFRESH/PROGRESS.tsv" "$REF_EPOCH"
assert_file_is "PROGRESS.tsv keeps its contents" \
  "$DEST_REFRESH/PROGRESS.tsv" "$(printf 'core/01-alpha\t1')"
assert_mtime_is "the runner's pointer file is not touched under --refresh-prompts" \
  "$DEST_REFRESH/LAST-SERVED" "$REF_EPOCH"
assert_file_is "the pointer file keeps its contents" \
  "$DEST_REFRESH/LAST-SERVED" "core/01-alpha"
assert_says_literal "and the run still says it leaves the record alone" \
  "left alone (the learner's record, never written here): $DEST_REFRESH/PROGRESS.tsv" "$RUN_OUT"

# Still no delete path. The 2026-10-02 incident was a deletion, and a refresh
# flag is exactly where one would grow: the shortest route to "the destination
# matches the source" is to remove what the source does not have.
assert_unchanged "an item the source does not have survives --refresh-prompts" \
  "$DEST_REFRESH/core/09-mine" "$REFRESH_STRAY_BEFORE" 0
assert_unchanged "a directory the source does not have survives --refresh-prompts" \
  "$DEST_REFRESH/traces" "$REFRESH_TRACES_BEFORE" 0
assert_file_is "the learner's own module beside a replaced prompt survives" \
  "$DEST_REFRESH/core/01-alpha/Alpha.tla" "half a module"
assert_mtime_is "and is not rewritten either" \
  "$DEST_REFRESH/core/01-alpha/Alpha.tla" "$REF_EPOCH"

assert_never_names "a refresh run never names the real practice tree" \
  "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

# --- --check composed with the flag ---------------------------------------

RCHECK_BEFORE=$(snapshot "$DEST_RCHECK")

run_deliver --check --refresh-prompts "$DEST_RCHECK"

assert_rc0 "--check --refresh-prompts exits 0"

assert_absent "--check --refresh-prompts creates no destination directory" "$DEST_RCHECK"

assert_unchanged "--check --refresh-prompts over an absent destination writes nothing" \
  "$DEST_RCHECK" "$RCHECK_BEFORE" 0

assert_says_literal "--check --refresh-prompts names what it would deliver fresh" \
  "would deliver: $DEST_RCHECK/core/01-alpha/PROMPT.md" "$RUN_OUT"

# The flag order is reversed here on purpose. Both are options, so neither may
# depend on coming first.
seed_refresh_dest "$DEST_RCHECK2"
RCHECK2_BEFORE=$(snapshot "$DEST_RCHECK2")

run_deliver --refresh-prompts --check "$DEST_RCHECK2"

assert_rc0 "--refresh-prompts --check exits 0, whichever order the flags come in"

assert_says_literal "--check names the prompt it would replace" \
  "would replace (the source differs): $DEST_RCHECK2/core/01-alpha/PROMPT.md" "$RUN_OUT"

assert_says_literal "--check names the prompt it would leave alone" \
  "would leave alone (identical to the source): $DEST_RCHECK2/core/02-beta/PROMPT.md" "$RUN_OUT"

assert_says_literal "--check under the flag ends on its own counts line" \
  "1 prompt(s) to land, 1 to replace, 1 left alone, $(count_withheld "$FIX_REPO") path(s) withheld" \
  "$RUN_OUT"

assert_unchanged "--check --refresh-prompts over a populated destination changes nothing" \
  "$DEST_RCHECK2" "$RCHECK2_BEFORE" 0

assert_touched_count "--check --refresh-prompts writes no file at all" \
  "$DEST_RCHECK2" 0

# ---------------------------------------------------------------------------
echo
echo "== --check resolves everything and writes nothing =="
# ---------------------------------------------------------------------------

CHECK_BEFORE=$(snapshot "$DEST_CHECK")

run_deliver --check "$DEST_CHECK"

assert_rc0 "--check exits 0"

assert_unchanged "--check creates no destination at all" \
  "$DEST_CHECK" "$CHECK_BEFORE" 0

assert_says_literal "--check names each prompt it would deliver" \
  "would deliver: $DEST_CHECK/core/01-alpha/PROMPT.md" "$RUN_OUT"

assert_says_literal "--check reports the withholding too" \
  "withheld (not PROMPT.md): $FIX_REPO/drill/core/01-alpha/ANSWER.md" "$RUN_OUT"

assert_says_literal "--check ends on its own counts line" \
  "3 prompt(s) to land, 0 already there, $(count_withheld "$FIX_REPO") path(s) withheld" "$RUN_OUT"

# --check over a destination that already holds the corpus is the shape central
# reads before a re-delivery, so it has to separate the two.
run_deliver --check "$DEST_MAIN"
assert_rc0 "--check over a delivered destination exits 0"
assert_says_literal "--check names what is already there" \
  "would skip (exists): $DEST_MAIN/core/01-alpha/PROMPT.md" "$RUN_OUT"
assert_says_literal "--check counts the already-there separately from the to-land" \
  "0 prompt(s) to land, 3 already there," "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== a second delivery is the normal way a new item arrives =="
# ---------------------------------------------------------------------------

# 29 more items are in flight in four worktrees. The way they reach the tree is
# a whole-corpus run over a destination holding the old ones, so that run has
# to be boring.
run_deliver "$DEST_TWICE"
assert_rc0 "the first delivery exits 0"
FIRST=$(relfiles "$DEST_TWICE")

mk_item "$FIX_REPO" "temporal/02-delta"
run_deliver "$DEST_TWICE"
assert_rc0 "the second delivery exits 0"

assert_says_literal "the second delivery lands only the new item" \
  "1 prompt(s) landed, 3 skipped," "$RUN_OUT"

assert_file_is "the new item's prompt lands" \
  "$DEST_TWICE/temporal/02-delta/PROMPT.md" \
  "$(cat "$FIX_REPO/drill/temporal/02-delta/PROMPT.md")"

SECOND=$(relfiles "$DEST_TWICE")
if [ "$FIRST" != "$SECOND" ]; then
  ok "the second delivery grew the tree rather than rewriting it"
else
  nope "the second delivery changed nothing, so the new item never arrived"
fi

rm -rf "$FIX_REPO/drill/temporal/02-delta"

# ---------------------------------------------------------------------------
echo
echo "== an item with no prompt is loud, and its siblings still land =="
# ---------------------------------------------------------------------------

run_deliver_from "$NOPROMPT_REPO" "$DEST_NOPROMPT"

assert_rc "an item carrying no PROMPT.md exits 1" 1

assert_says "the run names the item that has nothing to deliver" \
  "core/02-headless carries no PROMPT.md" "$RUN_ERR"

assert_file_is "the sibling item still landed" \
  "$DEST_NOPROMPT/core/01-alpha/PROMPT.md" \
  "$(cat "$NOPROMPT_REPO/drill/core/01-alpha/PROMPT.md")"

assert_absent "the headless item's answer never lands" \
  "$DEST_NOPROMPT/core/02-headless/ANSWER.md"

assert_says_literal "the headless item's own entries are still reported as withheld" \
  "withheld (not PROMPT.md): $NOPROMPT_REPO/drill/core/02-headless/ANSWER.md" "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== the fatal sources, which create nothing =="
# ---------------------------------------------------------------------------

DEST_FATAL="$TMPROOT/dest-fatal"
FATAL_BEFORE=$(snapshot "$DEST_FATAL")

run_deliver_from "$EMPTY_REPO" "$DEST_FATAL"
assert_rc "a drill/ directory with no item in it exits 1" 1
assert_says "and says that there is nothing to deliver" \
  "holds no item" "$RUN_ERR"
assert_unchanged "a source with no item creates no destination" \
  "$DEST_FATAL" "$FATAL_BEFORE" 1

run_deliver_from "$NODRILL_REPO" "$DEST_FATAL"
assert_rc "a source root with no drill/ directory exits 1" 1
assert_says "and names the directory it looked for" \
  "no drill corpus at $NODRILL_REPO/drill" "$RUN_ERR"
assert_says "and names the override that fixes it" \
  "DELIVER_DRILL_SRC_ROOT" "$RUN_ERR"
assert_unchanged "a source with no drill/ creates no destination" \
  "$DEST_FATAL" "$FATAL_BEFORE" 1

run_deliver --bogus "$DEST_FATAL"
assert_rc "an unknown option exits 1" 1
assert_says "and prints usage" "Usage: " "$RUN_ERR"
assert_unchanged "an unknown option creates no destination" \
  "$DEST_FATAL" "$FATAL_BEFORE" 1

run_deliver "$DEST_FATAL" "extra"
assert_rc "a second positional argument exits 1" 1
assert_says "and says which argument it did not expect" \
  "unexpected extra argument: extra" "$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== the default root, against a sandboxed HOME =="
# ---------------------------------------------------------------------------

# A sandboxed HOME protects a script that resolves its default from HOME. It
# does nothing for one that hardcodes a path, and that script would write into
# Frank's live tree the moment this section ran. So this section runs ONLY
# --check, and it reads a source that exists in the sandbox and nowhere else.
mkdir -p "$DEFAULT_ROOT"
DEFAULT_BEFORE=$(snapshot "$DEFAULT_ROOT")

run_deliver_from "$SANDBOX_REPO" --check

assert_rc0 "--check with no dest-root argument exits 0"

assert_says_literal "--check with no dest-root reads the sandboxed default root" \
  "destination: $DEFAULT_ROOT" "$RUN_OUT"

assert_says_literal "--check with no dest-root resolves the item under it" \
  "would deliver: $DEFAULT_ROOT/core/01-omega-sandbox-only/PROMPT.md" "$RUN_OUT"

assert_unchanged "--check with no dest-root writes nothing" \
  "$DEFAULT_ROOT" "$DEFAULT_BEFORE" 0

# The sandbox path ends in tla-practice/drill too, so this has to name the REAL
# path rather than the shape of it.
assert_never_names "--check with no dest-root never names the real practice tree" \
  "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== the real drill/ tree, read through --check into a temp destination =="
# ---------------------------------------------------------------------------

# The counts are DERIVED, not written down. Central measured 32 and 96 on
# 2026-10-12, and 29 more items are in flight, so a literal here would be wrong
# within the week. What this row pins is that the script and an independent walk
# of the tree agree.
REAL_ITEMS=$(count_items "$REPO_ROOT")
REAL_WITHHELD=$(count_withheld "$REPO_ROOT")

if [ "$REAL_ITEMS" -gt 0 ]; then
  run_deliver_realrepo --check "$DEST_REAL"

  assert_rc0 "--check over the real corpus exits 0"

  assert_says_literal "--check over the real corpus agrees with an independent walk of the tree" \
    "$REAL_ITEMS prompt(s) to land, 0 already there, $REAL_WITHHELD path(s) withheld" "$RUN_OUT"

  assert_absent "--check over the real corpus creates no destination" "$DEST_REAL"

  assert_says_literal "the real corpus withholds core/01-box-office's META.md, which names its trap" \
    "withheld (not PROMPT.md): $REPO_ROOT/drill/core/01-box-office/META.md" "$RUN_OUT"

  assert_never_names "--check over the real corpus never names the real practice tree" \
    "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

  # Three times the item count is what today's four-entry shape gives, and
  # harness/test-drill.sh is what holds the shape there. The row states the
  # relation rather than the number.
  if [ "$REAL_WITHHELD" -eq $((REAL_ITEMS * 3)) ]; then
    ok "the real corpus withholds 3 entries per item (${REAL_ITEMS} items, ${REAL_WITHHELD} paths)"
  else
    nope "the real corpus withholds ${REAL_WITHHELD} paths over ${REAL_ITEMS} items, which is not 3 per item — harness/test-drill.sh's delivery shape row should have caught this first"
  fi
else
  nope "the real drill/ tree holds no item, so the corpus rows did not run"
fi

# ---------------------------------------------------------------------------
echo
echo "== structural: the deviation is argued, the shape is gated, the suite runs =="
# ---------------------------------------------------------------------------

# Naming a file in a delivery script is the 2026-10-02 defect unless two things
# hold. The script has to say why it deviates, and the shape it depends on has
# to be gated somewhere. Both are part of the contract rather than a courtesy,
# so both are asserted.
if [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "the script argues the deviation. $SCRIPT does not exist"
  nope "the script names the gate behind it. $SCRIPT does not exist"
  nope "the script states the never-overwrite rule. $SCRIPT does not exist"
else
  SCRIPT_HEAD=$(sed -n '1,100p' "$SCRIPT")
  assert_says "the script argues why it names a file where its sibling refuses to" \
    'deliver-problems\.sh' "$SCRIPT_HEAD"
  assert_says "the script says the gate is what makes the deviation safe" \
    'GATE IS WHAT MAKES THE DEVIATION SAFE' "$SCRIPT_HEAD"
  assert_says "the script names the suite that holds the shape" \
    'harness/test-drill\.sh' "$SCRIPT_HEAD"
  assert_says "the script states what it withholds" \
    '[Ww]ithhold|NEVER DELIVER|never delivers' "$SCRIPT_HEAD"
  assert_says "the script states the never-overwrite rule" \
    'NEVER OVERWRITE|never overwrit' "$SCRIPT_HEAD"
  # A reader who gets as far as the usage block and no further has to come away
  # knowing that a plain run cannot replace a prompt. That is the one thing
  # about this script somebody could act on wrongly.
  assert_says "the usage block names --refresh-prompts and says it is off by default" \
    '--refresh-prompts' "$SCRIPT_HEAD"
  assert_says "and says plainly that the default does not overwrite" \
    'OFF BY DEFAULT|[Oo]ff by default' "$SCRIPT_HEAD"
fi

# Gate, don't advise. The shape assertion is the other half of this script's
# manifest, so a tree where it has gone missing is one where a filename in a
# script is unbacked again.
if [ ! -f "$DRILL_SUITE" ]; then
  nope "the delivery shape is gated. $DRILL_SUITE does not exist"
else
  DRILL_SUITE_BODY=$(cat "$DRILL_SUITE")
  assert_says "harness/test-drill.sh declares the four-entry shape" \
    'DRILL_ITEM_SHAPE="ANSWER\.md META\.md PROMPT\.md verify"' "$DRILL_SUITE_BODY"
  assert_says "and runs the shape arm over the real tree" \
    'shape_arm "\$\{REPO_ROOT\}/drill"' "$DRILL_SUITE_BODY"
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-deliver-drill\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-deliver-drill.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-deliver-drill.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
