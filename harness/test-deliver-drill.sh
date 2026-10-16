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
# ---------------------------------------------------------------------------
# THE STUDY HALF, added 2026-10-14 by bead tla-ytv2.3
#
# Everything above is about the PROMPT half: one name lands per item and every
# other entry is withheld. The sections at the bottom of this file are about a
# second mode of the same script, and the two have almost nothing in common
# beyond the file they live in.
#
#   scripts/deliver-drill.sh --study [--check] [study-root]
#
#   The study root resolves from the positional argument, else from
#   DRILL_STUDY_ROOT, else from $HOME/Study/tla-drills. It MUST already exist.
#   An absent root, or one that is not a directory, is refused on stderr with
#   exit 1 and nothing is created. drill/drill.sh creates the root when it
#   serves a drill, so a missing root means no drill has been served yet, and
#   guessing a tree into place is how a delivery script writes somewhere nobody
#   asked for.
#
#   Five classes land, and every one of them is ALWAYS overwritten:
#
#     drill/study/CLAUDE.md                  -> <root>/CLAUDE.md
#     drill/study/.claude/commands/*.md      -> <root>/.claude/commands/*.md
#     drill/study/check                      -> <root>/check, mode 0755
#     drill/study/STYLE.md                   -> <root>/STYLE.md
#     drill/study/style                      -> <root>/style, mode 0755
#
#   A source with no check script is NOT an error. Bead tla-ytv2.2 owns that
#   file and a tree that predates it was fine yesterday. The style pair,
#   added 2026-10-15 by bead tla-iiow.3, carries the same rule for the same
#   reason: beads tla-iiow.1 and tla-iiow.2 own those two files and this half
#   is the plumbing under them, so it ships before they land and says plainly
#   which of the two it did not find.
#
#   NOTHING under <root>/<slug>/ is ever written, read or removed. Those hold
#   Frank's attempts, that tree is not a git repo, and it is in no backup, so
#   it is the only artifact in this system with no copy anywhere.
#
#   --study with --refresh-prompts is a usage error. That flag is about prompts
#   and this mode delivers none.
#
#   A plain run additionally lands drill/README.md at <dest-root>/README.md,
#   always overwriting. It is tooling, in the runner's file class: the repo is
#   the source of truth for it and Frank never edits it. Until 2026-10-14 no
#   script delivered it at all, so the copy in the practice tree still read
#   "32 blank-page drills, four families" against 64 in eight (bead tla-nc6f).
#
# WHY THE COMMANDS LIVE UNDER A HIDDEN DIRECTORY IN THE SOURCE TREE. They land
# at <root>/.claude/commands/ because that is where Claude Code reads a project
# slash command from, and the source mirrors the destination so the delivery is
# a plain copy with no rename to get wrong.
#
# It also has to mirror it. An item is a directory two levels under drill/, and
# four scripts resolve one with the same find: this script, harness/drill-gate.sh,
# harness/test-drill.sh, and the count helpers in this file. A visible
# drill/study/commands/ reads as an item to all four. Measured on this tree
# before the layout moved: drill-gate.sh reported 65 items with 5 findings and
# returned rc 1, harness/test-drill.sh failed its shape row naming
# drill/study/commands, this script exited 1 calling it an item with no
# PROMPT.md, and this suite failed three rows on 65 against 64. Under a leading
# dot all four skip it on the `! -name '.*'` predicate they already carry, and
# none of them needed changing.
#
# That is a layout holding four gates up, so the row under "structural" asserts
# that drill/study/ still carries no visible subdirectory. Add one and this
# suite goes red here rather than in four other places at once.
#
# Usage:  harness/test-deliver-drill.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="scripts/deliver-drill.sh"
DRILL_SUITE="harness/test-drill.sh"
TEST_RUNNER="scripts/test"
GATE="harness/drill-gate.sh"

STUDY_SRC="drill/study"
STUDY_CONFIG="$STUDY_SRC/CLAUDE.md"
STUDY_CHECK_CMD="$STUDY_SRC/.claude/commands/check.md"
STUDY_HINT_CMD="$STUDY_SRC/.claude/commands/hint.md"
# The style pair. Beads tla-iiow.1 and tla-iiow.2 write these two and may not
# have landed, so every row below that reads the REAL tree asks whether the
# file is there and asserts a real fact either way. A row that only holds once
# a sibling lands is not green, and a row that holds whatever the tree looks
# like is asserting nothing.
STUDY_REGISTER="$STUDY_SRC/STYLE.md"
STUDY_STYLE="$STUDY_SRC/style"
DRILL_README="drill/README.md"

# The real practice tree, captured before anything is sandboxed. Used only to
# assert that no run ever names it. Nothing here reads or writes under it.
REAL_PRACTICE="$HOME/tla-practice"

# The real study tree, same rule and a sharper reason. It holds the only copy
# of the work done in it, so no row here names it as a destination and the last
# study row asserts that nothing created it.
REAL_STUDY="$HOME/Study"

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
# Study fixtures, for the --study sections at the bottom.
#
# mk_study <repo-root>: the study tree in the shape the real one has. Its
# contents are deliberately not the real file's, so a row that passed only
# against the real CLAUDE.md would be asserting content where it means to
# assert copying. The real files get their own rows further down.
# ---------------------------------------------------------------------------

mk_study() {
  local root="$1"
  local d="$root/drill/study"
  mkdir -p "$d/.claude/commands"
  printf 'fixture config, not the real one\n' >"$d/CLAUDE.md"
  printf 'fixture check command\n'            >"$d/.claude/commands/check.md"
  printf 'fixture hint command\n'             >"$d/.claude/commands/hint.md"
  printf '#!/bin/sh\nexit 2\n'                >"$d/check"
  chmod 0755 "$d/check"
  printf 'fixture style register, not the real one\n' >"$d/STYLE.md"
  printf '#!/bin/sh\nexit 3\n'                        >"$d/style"
  chmod 0755 "$d/style"
}

mk_study "$FIX_REPO"

# THE README FIXTURE IS ITS OWN SOURCE ROOT, and that is deliberate rather than
# tidiness. $FIX_REPO is what the manifest and write-footprint rows above read,
# and they assert an exact file set and an exact count of files written. A
# drill/README.md in there lands a fourth file in $DEST_MAIN and those rows go
# red over a delivery that is working correctly. Measured: three rows, two of
# them the touched-count controls. So the readme rows get a source of their own
# and the rows above keep meaning what they meant.
README_REPO="$TMPROOT/repo-readme"
mk_item  "$README_REPO" "core/01-alpha"
mk_study "$README_REPO"
printf 'the fixture readme\n' >"$README_REPO/drill/README.md"

# A source whose study tree carries no check script. Bead tla-ytv2.2 owns that
# file, so a source without it still has to deliver the rest.
NOCHECK_REPO="$TMPROOT/repo-nocheck"
mk_item  "$NOCHECK_REPO" "core/01-alpha"
mk_study "$NOCHECK_REPO"
rm -f "$NOCHECK_REPO/drill/study/check"

# A source whose study tree carries neither the register nor the style script.
# Beads tla-iiow.1 and tla-iiow.2 own those two files, so a source without
# them still has to deliver the rest, and this is also the shape the repo
# itself has until both land.
NOSTYLE_REPO="$TMPROOT/repo-nostyle"
mk_item  "$NOSTYLE_REPO" "core/01-alpha"
mk_study "$NOSTYLE_REPO"
rm -f "$NOSTYLE_REPO/drill/study/STYLE.md" "$NOSTYLE_REPO/drill/study/style"

# A source with no study tree at all, and one with no readme.
NOSTUDY_REPO="$TMPROOT/repo-nostudy"
mk_item "$NOSTUDY_REPO" "core/01-alpha"
NOREADME_REPO="$TMPROOT/repo-noreadme"
mk_item "$NOREADME_REPO" "core/01-alpha"

# Study destination roots. Each is created here when the row wants an existing
# root, and deliberately left absent when the row is about the refusal.
STUDY_MAIN="$TMPROOT/study-main"       # the happy path
STUDY_TWICE="$TMPROOT/study-twice"     # delivered, then delivered again
STUDY_WORK="$TMPROOT/study-work"       # carries a per-slug work directory
STUDY_CHECKONLY="$TMPROOT/study-check" # --check only, never written
STUDY_NOCHECK="$TMPROOT/study-nochk"   # source carries no check script
STUDY_NOSTYLE="$TMPROOT/study-nosty"   # source carries neither style file
STUDY_ENV="$TMPROOT/study-env"         # resolved from DRILL_STUDY_ROOT
STUDY_POS="$TMPROOT/study-pos"         # positional, overriding the env var
STUDY_REAL="$TMPROOT/study-real"       # the real repo's study tree
STUDY_ABSENT="$TMPROOT/study-absent"   # never created, on purpose
STUDY_FILE="$TMPROOT/study-is-a-file"  # a regular file where a root should be

mkdir -p "$STUDY_MAIN" "$STUDY_TWICE" "$STUDY_WORK" "$STUDY_CHECKONLY" \
  "$STUDY_NOCHECK" "$STUDY_NOSTYLE" "$STUDY_ENV" "$STUDY_POS" "$STUDY_REAL"
printf 'not a directory\n' >"$STUDY_FILE"

DEST_README="$TMPROOT/dest-readme"     # a plain run, for the readme rows
DEST_README2="$TMPROOT/dest-readme2"   # delivered, then delivered again
DEST_NOREADME="$TMPROOT/dest-noreadme" # source carries no readme

# Frank's work, in the shape it has on his machine: a per-slug directory
# holding an attempt. 01-slip-on-the-spike is the one that exists there.
WORK_SLUG="01-slip-on-the-spike"
mkdir -p "$STUDY_WORK/$WORK_SLUG"
printf 'my attempt, such as it is\n' >"$STUDY_WORK/$WORK_SLUG/pickers.tla"
printf 'SPECIFICATION Spec\n'        >"$STUDY_WORK/$WORK_SLUG/pickers.cfg"

# Every study and readme run appends here, so the two rows that matter most can
# be asked of the whole suite's output at once rather than one run at a time.
STUDY_SEEN="$TMPROOT/study-seen.txt"
: >"$STUDY_SEEN"

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

# --- the study runners ------------------------------------------------------
#
# DRILL_STUDY_ROOT is set on every one of them, empty unless the row is about
# the environment. A run that inherited the real variable would resolve Frank's
# own study tree as its destination, and that tree holds the only copy of the
# work in it.

# run_study [args...]: the fixture source, a sandboxed HOME, no root in the
# environment.
run_study() {
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$FIX_REPO" \
    DRILL_STUDY_ROOT="" bash "$SCRIPT" --study "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
  printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"
}

# run_study_from <src-root> [args...]
run_study_from() {
  local src="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$src" \
    DRILL_STUDY_ROOT="" bash "$SCRIPT" --study "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
  printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"
}

# run_study_env <root> [args...]: the root comes from the environment and the
# command line carries none.
run_study_env() {
  local root="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$FIX_REPO" \
    DRILL_STUDY_ROOT="$root" bash "$SCRIPT" --study "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
  printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"
}

# run_study_realrepo <root> [args...]: the real repo as the source, a temp
# directory as the destination. The source side is safe to read and the
# destination side is the half that needs sandboxing.
run_study_realrepo() {
  local root="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="" \
    bash "$SCRIPT" --study "$@" "$root" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
  printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"
}

# run_readme [args...]: a plain prompt-mode run against the readme fixture.
# Separate from run_deliver for the reason $README_REPO exists, and it also
# routes the output into STUDY_SEEN.
run_readme() {
  run_deliver_from "$README_REPO" "$@"
  printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"
}

# run_readme_from <src-root> [args...]: the same, against another source.
run_readme_from() {
  run_deliver_from "$@"
  printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"
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

# --- helpers the study sections add -----------------------------------------

assert_executable() {
  if [ ! -e "$2" ]; then
    nope "$1. No file at $2"
  elif [ -x "$2" ]; then
    ok "$1"
  else
    nope "$1. It landed without the executable bit: $2"
  fi
}

# assert_tree_is <label> <dest> <wanted-newline-list>
#
# The study half's manifest. It takes the wanted list rather than deriving it,
# because three source names map to three destination names and one of the
# three moves into a subdirectory, so there is nothing to derive it from.
assert_tree_is() {
  local label="$1" dest="$2" want="$3" got
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The delivery failed (rc=$RUN_RC), so the manifest proves nothing"
    return
  fi
  got=$(relfiles "$dest")
  if [ "$want" = "$got" ]; then
    ok "$label"
  else
    nope "$label. Wanted [$(tr '\n' ' ' <<<"$want")] got [$(tr '\n' ' ' <<<"$got")]"
  fi
}

# assert_contains <label> <file> <literal>
#
# A structural row over a tracked file. The prohibition rows below use it, and
# they are shaped against SOFTENING rather than against deletion: a refusal
# contract somebody has reworded into advice reads fine and gates nothing.
assert_contains() {
  local label="$1" file="$2" needle="$3"
  if [ ! -f "$file" ]; then
    nope "$label. $file does not exist"
  elif grep -qF -- "$needle" "$file"; then
    ok "$label"
  else
    nope "$label. $file never says: $needle"
  fi
}

# assert_matches <label> <file> <extended-regex>
assert_matches() {
  local label="$1" file="$2" pattern="$3"
  if [ ! -f "$file" ]; then
    nope "$label. $file does not exist"
  elif grep -qE -- "$pattern" "$file"; then
    ok "$label"
  else
    nope "$label. Nothing in $file matched: $pattern"
  fi
}

# flatten <file>: the file as one line, every run of whitespace a single space.
#
# WHY THE PROSE ROWS GO THROUGH THIS. drill/study/ holds prose that wraps at
# about 79 columns, so a phrase a row looks for can sit across a line break and
# read as absent to a line-based grep. That is the same instrument error the
# 43/21 count split hit, where a line-based scan got 36/28 because the claim
# wrapped in 7 prompts.
#
# Measured 2026-10-15 while building bead tla-rzvk.3: "leave him the item's
# work" wrapped after the apostrophe, and two rows went red against two files
# that both said it. Nothing was wrong with either file, and reflowing the
# paragraph to suit the gate would have left the gate just as brittle for the
# next reword.
#
# A row anchored to a line must NOT flatten, since flattening destroys the only
# thing `^` can anchor to. So the line-based helpers above stay, the flat ones
# are separate, and a row picks the one that matches what it is asserting: a
# heading is a line, a claim is a phrase.
flatten() {
  tr -s '[:space:]' ' ' <"$1"
}

# assert_contains_flat <label> <file> <literal>
assert_contains_flat() {
  local label="$1" file="$2" needle="$3"
  if [ ! -f "$file" ]; then
    nope "$label. $file does not exist"
  elif grep -qF -- "$needle" <<<"$(flatten "$file")"; then
    ok "$label"
  else
    nope "$label. $file never says: $needle"
  fi
}

# assert_matches_flat <label> <file> <extended-regex>
assert_matches_flat() {
  local label="$1" file="$2" pattern="$3"
  if [ ! -f "$file" ]; then
    nope "$label. $file does not exist"
  elif grep -qE -- "$pattern" <<<"$(flatten "$file")"; then
    ok "$label"
  else
    nope "$label. Nothing in $file matched: $pattern"
  fi
}

# assert_lacks_flat <label> <file> <extended-regex>
assert_lacks_flat() {
  local label="$1" file="$2" pattern="$3"
  if [ ! -f "$file" ]; then
    nope "$label. $file does not exist"
  elif grep -qE -- "$pattern" <<<"$(flatten "$file")"; then
    nope "$label. $file still matches: $pattern"
  else
    ok "$label"
  fi
}

# assert_lacks <label> <file> <extended-regex>
assert_lacks() {
  local label="$1" file="$2" pattern="$3"
  if [ ! -f "$file" ]; then
    nope "$label. $file does not exist"
  elif grep -qE -- "$pattern" "$file"; then
    nope "$label. $file still matches: $pattern"
  else
    ok "$label"
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
echo "== --study lands the configuration and the two commands =="
# ---------------------------------------------------------------------------

STUDY_WANT=$(printf './.claude/commands/check.md\n./.claude/commands/hint.md\n./CLAUDE.md\n./STYLE.md\n./check\n./style\n')

run_study "$STUDY_MAIN"

assert_rc0 "a study delivery into an existing root exits 0"

assert_tree_is "the study root holds exactly the configuration, both commands, the checker and the style pair" \
  "$STUDY_MAIN" "$STUDY_WANT"

assert_file_is "the configuration lands byte for byte" \
  "$STUDY_MAIN/CLAUDE.md" "$(cat "$FIX_REPO/drill/study/CLAUDE.md")"

assert_file_is "the check command lands under .claude/commands/, where Claude Code reads one" \
  "$STUDY_MAIN/.claude/commands/check.md" "$(cat "$FIX_REPO/drill/study/.claude/commands/check.md")"

assert_file_is "the hint command lands beside it" \
  "$STUDY_MAIN/.claude/commands/hint.md" "$(cat "$FIX_REPO/drill/study/.claude/commands/hint.md")"

assert_executable "the checker lands executable, because he runs it as ./check" \
  "$STUDY_MAIN/check"

# The style pair, bead tla-iiow.3. The register is prose the one-shot cannot
# read off disk, since it runs with no tools, so drill.sh cats it into the
# prompt. The script measures. Both have to arrive for --style to mean
# anything, and the delivery is the only thing that puts them there.
assert_file_is "the style register lands byte for byte" \
  "$STUDY_MAIN/STYLE.md" "$(cat "$FIX_REPO/drill/study/STYLE.md")"

assert_file_is "the style script lands byte for byte" \
  "$STUDY_MAIN/style" "$(cat "$FIX_REPO/drill/study/style")"

assert_executable "the style script lands executable, the way the checker does" \
  "$STUDY_MAIN/style"

# And the register does NOT, which is the half a chmod on the wrong name of
# the pair would get backwards. drill.sh reads the register and execs the
# script, so the two modes are not interchangeable.
if [ ! -f "$STUDY_MAIN/STYLE.md" ]; then
  nope "the register lands as prose rather than as a program. No file at $STUDY_MAIN/STYLE.md"
elif [ -x "$STUDY_MAIN/STYLE.md" ]; then
  nope "the register landed executable, so the chmod went on the wrong half of the pair"
else
  ok "the register lands as prose rather than as a program"
fi

# Its own verb, so a run says which of the five classes landed rather than
# counting to five. The register is not a script and the script is not prose,
# and a reader of the output should not have to work out which is which.
assert_says_literal "the run names the register with its own verb" \
  "style register delivered: $STUDY_MAIN/STYLE.md" "$RUN_OUT"

assert_says_literal "and the style script with its own" \
  "style script delivered: $STUDY_MAIN/style" "$RUN_OUT"

assert_says_literal "the run names the study source" \
  "study source: $FIX_REPO/drill/study" "$RUN_OUT"

assert_says_literal "and the destination it resolved" \
  "study destination: $STUDY_MAIN" "$RUN_OUT"

assert_says "the run ends on a counts line" \
  'study file\(s\) landed' "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== every study file is ALWAYS overwritten =="
# ---------------------------------------------------------------------------

# The runner's file class, and for the same reason: the repo is the source of
# truth, he never edits these, and a fix to a refusal contract is worth nothing
# if it cannot reach him.

run_study "$STUDY_TWICE"
STUDY_FIRST_RC=$RUN_RC
printf 'he edited this, or something did\n' >"$STUDY_TWICE/CLAUDE.md"
printf 'and this, which is a register nothing refreshed\n' >"$STUDY_TWICE/STYLE.md"
# The executable bit cleared on a delivered copy. `cp` onto an existing file
# keeps the DESTINATION's mode rather than the source's, so a delivery that
# copies and never chmods leaves a style script he cannot run and says it
# delivered one. Measured as the shape the checker's own chmod exists for.
chmod 0644 "$STUDY_TWICE/style"
predate_tree "$STUDY_TWICE"
run_study "$STUDY_TWICE"

if [ "$STUDY_FIRST_RC" -ne 0 ]; then
  nope "a second study delivery exits 0. The first one exited $STUDY_FIRST_RC, so the row proves nothing"
else
  assert_rc0 "a second study delivery exits 0"
fi

assert_file_is "a changed configuration is replaced, not skipped" \
  "$STUDY_TWICE/CLAUDE.md" "$(cat "$FIX_REPO/drill/study/CLAUDE.md")"

assert_mtime_moved "the configuration was written rather than left alone" \
  "$STUDY_TWICE/CLAUDE.md" "$REF_EPOCH"

assert_file_is "a stale style register is replaced too" \
  "$STUDY_TWICE/STYLE.md" "$(cat "$FIX_REPO/drill/study/STYLE.md")"

assert_mtime_moved "and it was written rather than skipped" \
  "$STUDY_TWICE/STYLE.md" "$REF_EPOCH"

assert_executable "and a style script whose bit was cleared gets it back" \
  "$STUDY_TWICE/style"

assert_says "the output says it overwrote rather than claiming a first delivery" \
  'overwriting the copy already there' "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== a per-slug work directory is never written =="
# ---------------------------------------------------------------------------

WORK_BEFORE=$(snapshot "$STUDY_WORK/$WORK_SLUG")
predate_tree "$STUDY_WORK"
run_study "$STUDY_WORK"

assert_rc0 "a study delivery over a root holding work exits 0"

assert_unchanged "the work directory is byte for byte what it was" \
  "$STUDY_WORK/$WORK_SLUG" "$WORK_BEFORE" 0

assert_mtime_is "and his attempt was not even opened" \
  "$STUDY_WORK/$WORK_SLUG/pickers.tla" "$REF_EPOCH"

# The non-vacuity control. "It wrote nothing there" is worth nothing unless the
# same run wrote something somewhere.
assert_mtime_moved "the same run did land the configuration, so the row above is not vacuous" \
  "$STUDY_WORK/CLAUDE.md" "$REF_EPOCH"

assert_says_literal "the run says which work directory it left alone" \
  "left alone (your work, never written here): $STUDY_WORK/$WORK_SLUG" "$RUN_OUT"

# .claude/ is this script's own, so calling it his work would be a lie the
# second time the delivery runs. The first run creates it, so this row reads
# the SECOND run's output.
run_study "$STUDY_WORK"
assert_never_names "and does not call its own .claude/ directory his work" \
  "left alone (your work, never written here): $STUDY_WORK/.claude" "$RUN_OUT"
assert_says_literal "while still naming the real one on that second run" \
  "left alone (your work, never written here): $STUDY_WORK/$WORK_SLUG" "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== a missing study root is REFUSED, and nothing is created =="
# ---------------------------------------------------------------------------

# drill/drill.sh creates the root when it serves a drill. A missing one means
# no drill has been served yet, so guessing a tree into place would put the
# configuration somewhere he never asked for and would not think to look.

run_study "$STUDY_ABSENT"

assert_rc "an absent study root exits 1" 1

assert_absent "and no tree was created at it" "$STUDY_ABSENT"

assert_says_literal "stderr names the root it refused" "$STUDY_ABSENT" "$RUN_ERR"

assert_says "and says plainly that it does not create one" \
  'does not create|will not create' "$RUN_ERR"

run_study_env "$STUDY_ABSENT"
assert_rc "the same refusal when the root came from DRILL_STUDY_ROOT" 1
assert_absent "and still nothing was created" "$STUDY_ABSENT"

run_study "$STUDY_FILE"
assert_rc "a regular file where a root should be exits 1" 1
assert_file_is "and the file is untouched" "$STUDY_FILE" "not a directory"

run_study_from "$NOSTUDY_REPO" "$STUDY_MAIN"
assert_rc "a source with no study tree at all exits 1" 1
assert_says_literal "and names the directory it wanted" \
  "$NOSTUDY_REPO/drill/study" "$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== --study --check writes nothing =="
# ---------------------------------------------------------------------------

STUDY_CHECK_BEFORE=$(snapshot "$STUDY_CHECKONLY")
run_study --check "$STUDY_CHECKONLY"

assert_rc0 "--study --check exits 0"

assert_unchanged "--check created no file in the study root" \
  "$STUDY_CHECKONLY" "$STUDY_CHECK_BEFORE" 0

assert_absent "--check did not even create .claude/" "$STUDY_CHECKONLY/.claude"

assert_says_literal "--check says what it would deliver" \
  "would deliver: $STUDY_CHECKONLY/CLAUDE.md" "$RUN_OUT"

assert_says_literal "--check names the register it would deliver" \
  "would deliver: $STUDY_CHECKONLY/STYLE.md" "$RUN_OUT"

assert_says_literal "and the style script" \
  "would deliver: $STUDY_CHECKONLY/style" "$RUN_OUT"

assert_absent "--check placed no register either" "$STUDY_CHECKONLY/STYLE.md"

assert_says "--check ends on its own counts line" \
  'study file\(s\) to land' "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== the study root resolves from the argument, then the environment =="
# ---------------------------------------------------------------------------

run_study_env "$STUDY_ENV"
assert_rc0 "DRILL_STUDY_ROOT alone resolves a root"
assert_file_is "and the configuration landed under it" \
  "$STUDY_ENV/CLAUDE.md" "$(cat "$FIX_REPO/drill/study/CLAUDE.md")"

RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_DRILL_SRC_ROOT="$FIX_REPO" \
  DRILL_STUDY_ROOT="$STUDY_ENV" bash "$SCRIPT" --study "$STUDY_POS" 2>"$ERRFILE")
RUN_RC=$?
RUN_ERR=$(cat "$ERRFILE")
printf '%s\n%s\n' "$RUN_OUT" "$RUN_ERR" >>"$STUDY_SEEN"

assert_rc0 "a positional root is accepted alongside the environment"
assert_file_is "and the positional one is what got written" \
  "$STUDY_POS/CLAUDE.md" "$(cat "$FIX_REPO/drill/study/CLAUDE.md")"

# ---------------------------------------------------------------------------
echo
echo "== a source with no checker still delivers the rest =="
# ---------------------------------------------------------------------------

run_study_from "$NOCHECK_REPO" "$STUDY_NOCHECK"

assert_rc0 "a source carrying no check script is not an error"

assert_tree_is "the configuration, both commands and the style pair still land" \
  "$STUDY_NOCHECK" "$(printf './.claude/commands/check.md\n./.claude/commands/hint.md\n./CLAUDE.md\n./STYLE.md\n./style\n')"

assert_says "and the run says no checker was found" \
  'no checker at' "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== a source with neither style file still delivers the rest =="
# ---------------------------------------------------------------------------

# Bead tla-iiow.3. This is the shape the repo itself has until tla-iiow.1 and
# tla-iiow.2 land, so it is the ordinary case rather than an edge one, and the
# run has to say which of the two it did not find rather than counting one
# short and leaving a reader to work out why.

run_study_from "$NOSTYLE_REPO" "$STUDY_NOSTYLE"

assert_rc0 "a source carrying neither style file is not an error"

assert_tree_is "the configuration, both commands and the checker still land" \
  "$STUDY_NOSTYLE" "$(printf './.claude/commands/check.md\n./.claude/commands/hint.md\n./CLAUDE.md\n./check\n')"

assert_says_literal "and the run names the register it did not find" \
  "no style register at $NOSTYLE_REPO/drill/study/STYLE.md" "$RUN_OUT"

assert_says_literal "and the style script it did not find" \
  "no style script at $NOSTYLE_REPO/drill/study/style" "$RUN_OUT"

assert_absent "nothing was invented where the register would have gone" \
  "$STUDY_NOSTYLE/STYLE.md"

assert_absent "nor where the style script would have gone" "$STUDY_NOSTYLE/style"

# ---------------------------------------------------------------------------
echo
echo "== --study and --refresh-prompts do not compose =="
# ---------------------------------------------------------------------------

run_study --refresh-prompts "$STUDY_MAIN"
assert_rc "--study --refresh-prompts is a usage error" 1
assert_says "and says which flag it refused rather than only printing usage" \
  'refresh-prompts' "$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== the real study tree delivers =="
# ---------------------------------------------------------------------------

if [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "the real study tree delivers. $SCRIPT does not exist"
else
  run_study_realrepo "$STUDY_REAL"
  assert_rc0 "the repo's own drill/study/ delivers into an existing root"
  assert_file_is "the real configuration lands byte for byte" \
    "$STUDY_REAL/CLAUDE.md" "$(cat "$STUDY_CONFIG")"
  assert_file_is "the real check command lands byte for byte" \
    "$STUDY_REAL/.claude/commands/check.md" "$(cat "$STUDY_CHECK_CMD")"
  assert_file_is "the real hint command lands byte for byte" \
    "$STUDY_REAL/.claude/commands/hint.md" "$(cat "$STUDY_HINT_CMD")"

  # THE STYLE PAIR IS ANOTHER BEAD'S, SO THIS ROW ASKS THE TREE FIRST. Both
  # branches assert a real fact. With the file there, that it lands byte for
  # byte. Without it, that the run said so and placed nothing. Neither branch
  # is vacuous and neither waits on a sibling. Delete the branch, not the
  # section, once both files are permanent.
  if [ -f "$STUDY_REGISTER" ]; then
    assert_file_is "the real style register lands byte for byte" \
      "$STUDY_REAL/STYLE.md" "$(cat "$STUDY_REGISTER")"
  else
    assert_says_literal "the repo carries no register yet, and the run says so" \
      "no style register at" "$RUN_OUT"
    assert_absent "and nothing was placed where it will go" "$STUDY_REAL/STYLE.md"
  fi

  if [ -f "$STUDY_STYLE" ]; then
    assert_file_is "the real style script lands byte for byte" \
      "$STUDY_REAL/style" "$(cat "$STUDY_STYLE")"
    assert_executable "and lands executable, because drill.sh execs it" \
      "$STUDY_REAL/style"
  else
    assert_says_literal "the repo carries no style script yet, and the run says so" \
      "no style script at" "$RUN_OUT"
    assert_absent "and nothing was placed where it will go" "$STUDY_REAL/style"
  fi
fi

# ---------------------------------------------------------------------------
echo
echo "== the readme is delivered, and always overwritten =="
# ---------------------------------------------------------------------------

# Bead tla-nc6f. No script delivered it until 2026-10-14, so the copy in the
# practice tree was the one Frank read when he sat down and it told him he had
# half the corpus he has.

run_readme "$DEST_README"

assert_rc0 "a plain delivery exits 0"

assert_file_is "the readme lands at the root of the practice tree" \
  "$DEST_README/README.md" "$(cat "$README_REPO/drill/README.md")"

assert_says_literal "the run says the readme landed" \
  "readme delivered: $DEST_README/README.md" "$RUN_OUT"

run_readme "$DEST_README2"
printf 'a stale readme\n' >"$DEST_README2/README.md"
predate_tree "$DEST_README2"
run_readme "$DEST_README2"

assert_rc0 "a second plain delivery exits 0"

assert_file_is "a stale readme is replaced" \
  "$DEST_README2/README.md" "$(cat "$README_REPO/drill/README.md")"

assert_mtime_moved "and it was written rather than skipped" \
  "$DEST_README2/README.md" "$REF_EPOCH"

# The control that makes the row above mean what it says. One file class is
# always overwritten and another is never, in the same run.
assert_mtime_is "while the prompt beside it was left alone" \
  "$DEST_README2/core/01-alpha/PROMPT.md" "$REF_EPOCH"

run_readme_from "$NOREADME_REPO" "$DEST_NOREADME"
assert_rc0 "a source carrying no readme is not an error"
assert_says "and the run says none landed" 'no readme at' "$RUN_OUT"
assert_absent "nothing was invented in its place" "$DEST_NOREADME/README.md"

# ---------------------------------------------------------------------------
echo
echo "== the refusal contract, asserted structurally =="
# ---------------------------------------------------------------------------

# drill/study/CLAUDE.md is the only thing standing between a session in the
# study root and ANSWER.md. The withholding in this script is a delivery
# boundary rather than an access boundary, and the withheld files sit one
# absolute path away. So the prohibitions are gated here, against the softening
# that would leave the file reading fine and gating nothing.

# The tilde here is DATA, not a path this suite resolves. What the row asserts
# is that drill/study/CLAUDE.md still carries that exact string, tilde and all,
# because the tilde form is the one the house style writes and the one a reader
# of the delivered file sees. Expanding it to $HOME would make the row assert a
# string the file does not contain and has no reason to.
# shellcheck disable=SC2088
assert_contains "CLAUDE.md names the literal path it forbids reading" \
  "$STUDY_CONFIG" "~/repos/tla-puzzles/drill/"

assert_contains "and spells that path out, so no expansion is left to guess" \
  "$STUDY_CONFIG" "/home/fkberthold/repos/tla-puzzles/drill/"

assert_contains "and names the withheld files, so the boundary is concrete" \
  "$STUDY_CONFIG" "ANSWER.md"

assert_matches_flat "the prohibition on reading is in the NEVER register" \
  "$STUDY_CONFIG" 'NEVER read'

assert_matches_flat "the prohibition on writing TLA+ is in the NEVER register" \
  "$STUDY_CONFIG" 'NEVER write'

assert_matches_flat "and closes the one-line and the code-fence loopholes by name" \
  "$STUDY_CONFIG" 'one line|single line'

assert_matches_flat "the prohibition on naming the missing construct is in the NEVER register" \
  "$STUDY_CONFIG" 'NEVER name'

assert_matches "CLAUDE.md says the count comes from the checker" \
  "$STUDY_CONFIG" './check'

assert_matches_flat "and forbids reaching one any other way" \
  "$STUDY_CONFIG" 'never from|not from'

assert_matches "CLAUDE.md gives the register a report is allowed to use" \
  "$STUDY_CONFIG" 'admits|forbids'

assert_matches_flat "the prohibition on estimating a count is in the NEVER register" \
  "$STUDY_CONFIG" 'NEVER estimate'

# ---------------------------------------------------------------------------
echo
echo "== the path to the checker, from where the session actually stands =="
# ---------------------------------------------------------------------------

# Bead tla-rzvk.3. The file said "Run `./check` in the directory" until
# 2026-10-15 and the checker is delivered to the study ROOT, one level up from
# the slug directory a session works in. Frank's session on 2026-10-14 got
# "./check doesn't exist in this directory" and worked the path out for itself.
#
# So the positive row asserts the form that reaches it from the cwd, and the
# negative row is what catches the old sentence coming back. Both are needed:
# a file carrying `../check` in one paragraph and the old instruction in
# another reads fine and still sends a session to a path that is not there.
#
# The pattern lives in a variable because both the config and the command row
# want it, and because it needs one justification rather than two.
#
# THE SINGLE QUOTES ARE LOAD-BEARING AND THE SC2016 IS A FALSE POSITIVE, shown
# rather than assumed. The backtick is a character of the regex, matching the
# code span a markdown file writes the command in. Take shellcheck's advice and
# double-quote it, and the shell runs ./check and substitutes its output:
# measured 2026-10-15, the pattern comes back as " (in|from) (the|this)
# directory" with the whole head gone, which matches nothing and makes the row
# pass over the defect it exists to catch. Same shape as the SC1087 finding in
# harness/refinement.sh, where the checker was also reading shell syntax into a
# string that is not shell.
# shellcheck disable=SC2016
CHECK_IN_CWD='`\./check` (in|from) (the|this) directory'

assert_contains "CLAUDE.md reaches the checker from the slug directory the session stands in" \
  "$STUDY_CONFIG" "../check"

assert_contains_flat "and names the runner flag that makes the path moot from the shell" \
  "$STUDY_CONFIG" "./drill --check"

assert_lacks_flat "CLAUDE.md no longer puts the checker in the working directory" \
  "$STUDY_CONFIG" "$CHECK_IN_CWD"

# ---------------------------------------------------------------------------
echo
echo "== a violation at a state the prompt blesses is a report about the rule =="
# ---------------------------------------------------------------------------

# Bead tla-rzvk.3, and this is the diagnosis the config was silent on rather
# than wrong about. A prompt's `possible?` table is a constraint on the model
# and nothing verifies it. So a rule that forbids a row marked yes gives the
# expected verdict from a legal state, which reads as a pass.
#
# Worked instance, 2026-10-14: a control-state attempt reported a violation one
# step before any pick, at a state the prompt's third row marks possible. The
# verdict was the one the item asks for and the rule was still wrong. The
# reasoning behind that instance is author-side and these rows do not cite the
# item's META.md or verify/, because a citation inside the file that forbids
# reading them is the leak wearing a footnote.
assert_matches "CLAUDE.md carries the table comparison as a named step" \
  "$STUDY_CONFIG" '^## .*possible'

assert_contains "and names the column by the heading a prompt prints it under" \
  "$STUDY_CONFIG" "possible?"

assert_matches_flat "and says a violation on a blessed row is about the rule, not the model" \
  "$STUDY_CONFIG" 'report about the rule'

assert_matches_flat "and says which way that points, so the diagnosis is not left to be inferred" \
  "$STUDY_CONFIG" 'forbids something the prompt requires'

assert_matches_flat "and keeps the register, naming the row where a construct would go" \
  "$STUDY_CONFIG" 'the prompt marks (it )?possible'

# NON-VACUITY, against the live corpus rather than against a count written
# here. The step is worth gating only while prompts carrying the table exist.
#
# The scan FLATTENS each prompt first. A line-based grep over this corpus gives
# wrong counts, because the prompts are prose and wrap: core/06-can-pyramid,
# core/08-altimeter-approx and sets/05-leases all publish a count that spans
# two lines and read as publishing nothing to a line-based pass. The column
# header does sit on one line today, and flattening costs nothing and removes
# the question.
#
# Measured 2026-10-15 over this tree: 8 prompts carry a `possible?` column,
# and they are the 8 the bead names. The lead-in sentence "must be possible in
# your model" catches only 6 of them, which is why the column is what gets
# counted here. The floor is 5 rather than 8 on purpose, the same way the
# family row above floors 8 families at 5: a hardcoded corpus count in a gate
# is the staleness shape this project has hit three times.
POSSIBLE_PROMPTS=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  PROMPT_FLAT=$(tr '\n' ' ' <"$p")
  if grep -qE -- '\| *possible\? *\|' <<<"$PROMPT_FLAT"; then
    POSSIBLE_PROMPTS=$((POSSIBLE_PROMPTS + 1))
  fi
done < <(find drill -mindepth 3 -maxdepth 3 -name PROMPT.md | LC_ALL=C sort)

if [ "$POSSIBLE_PROMPTS" -ge 5 ]; then
  ok "$POSSIBLE_PROMPTS prompt(s) carry the table those rows are about"
else
  nope "only $POSSIBLE_PROMPTS prompt(s) carry a possible? column, so the rows above gate a shape the corpus no longer has"
fi

# ---------------------------------------------------------------------------
echo
echo "== the two modes the runner writes, and the budget a steered hint needs =="
# ---------------------------------------------------------------------------

# Bead tla-rzvk.3. drill.sh writes `MODE: check` or `MODE: hint` and, on a
# steered hint, a `QUESTION:` block carrying Frank's text verbatim. This file
# owns what the three mean and drill.sh owns none of it, so a reader who only
# has the runner cannot tell what either mode is for.
assert_contains_flat "CLAUDE.md defines the check mode the runner writes" \
  "$STUDY_CONFIG" "MODE: check"

assert_contains_flat "and the hint mode" \
  "$STUDY_CONFIG" "MODE: hint"

assert_contains "and the block a steered question arrives in" \
  "$STUDY_CONFIG" "QUESTION:"

assert_matches_flat "and says a one-shot runs with no tools at all" \
  "$STUDY_CONFIG" 'no tools'

assert_matches_flat "CLAUDE.md rations a steered question by whether answering it leaves the work" \
  "$STUDY_CONFIG" "leave him the item's work"

# ---------------------------------------------------------------------------
echo
echo "== the two commands =="
# ---------------------------------------------------------------------------

assert_matches "check.md runs the checker rather than re-deriving its number" \
  "$STUDY_CHECK_CMD" './check'

# The wrong-model pass is the half a count check structurally cannot make, and
# the mechanism is why: a distinct-state count is a property of Init, Next and
# the state constraint, and not of the obligations. Measured 2026-10-14 on
# drill/sequences/07-pneumatic-tube/verify/TubeRef.tla, whose prompt publishes
# 129: drop InOrder from its config and TLC still reports no error at exactly
# 129 distinct states. The file this cites is author-side and the command does
# NOT name it, because naming a path under the withheld tree inside the file
# that forbids reading it would be the leak wearing a citation.
assert_matches_flat "check.md says a matching count is not sufficient" \
  "$STUDY_CHECK_CMD" 'not sufficient|cannot catch|structurally cannot'

assert_matches "and names the mechanism rather than asserting it" \
  "$STUDY_CHECK_CMD" 'Init'

assert_matches "check.md reads his prose answers, for the prompts that end in a question" \
  "$STUDY_CHECK_CMD" 'question|prose'

# Bead tla-rzvk.3. The same wrong path the config carried, in the command that
# actually tells a session what to type first.
assert_contains "check.md reaches the checker from the slug directory, not from the study root" \
  "$STUDY_CHECK_CMD" "../check"

assert_lacks_flat "check.md no longer puts the checker in the working directory" \
  "$STUDY_CHECK_CMD" "$CHECK_IN_CWD"

assert_matches "check.md compares a violation against the prompt's table, as its own pass" \
  "$STUDY_CHECK_CMD" '^## [0-9]+\. .*table'

assert_contains_flat "and says which way a row marked possible points" \
  "$STUDY_CHECK_CMD" "the prompt requires"

assert_matches "hint.md refuses before it has seen an attempt" \
  "$STUDY_HINT_CMD" 'REFUSE|[Rr]efuse'

assert_matches_flat "hint.md ladders rather than answering at once" \
  "$STUDY_HINT_CMD" '[Rr]ung 1'

assert_matches_flat "and never hands over the text of the fix" \
  "$STUDY_HINT_CMD" '[Nn]ever the text|not the text'

# Bead tla-rzvk.3. A steered hint is two kinds of question under one flag, and
# the ladder rations only one of them. A mechanism he has forgotten about TLA+
# itself can be answered in full and still leave the item's work untouched.
# The rows below pin the test, the flat answer, and the fallback, because the
# fallback is what decides the ambiguous case and is the easiest of the three
# to drop in a reword.
assert_contains "hint.md says a steered question arrives in its own block" \
  "$STUDY_HINT_CMD" "QUESTION:"

assert_matches_flat "and sorts it by whether answering in full leaves the item's work" \
  "$STUDY_HINT_CMD" "leave him the item's work"

assert_matches_flat "and answers a mechanism question flat rather than spending a rung on it" \
  "$STUDY_HINT_CMD" '[Aa]nswer it flat|[Aa]nswer flat'

assert_matches_flat "and rules on the ambiguous case, which tla-1sh7.1 reversed to flat" \
  "$STUDY_HINT_CMD" "can't tell which kind"

# ---------------------------------------------------------------------------
echo
echo "== the readme is no longer the one that said 32 drills and four families =="
# ---------------------------------------------------------------------------

# The counts are NOT asserted as literals, and that is the whole point of bead
# tla-nc6f. A hardcoded corpus count in prose is the failure shape
# .claude/rules/dispatched-agents.md records twice, where a suite count in that
# file went out of date three times running. So these rows assert that the
# family list still matches the tree and that the sentence carrying the old
# count has not come back.

README_FAMILIES_OK=1
README_FAMILIES_MISSING=""
FAMILY_COUNT=0
while IFS= read -r fam; do
  [ -n "$fam" ] || continue
  [ "$fam" = "study" ] && continue
  FAMILY_COUNT=$((FAMILY_COUNT + 1))
  if ! grep -qF -- "$fam" "$DRILL_README"; then
    README_FAMILIES_OK=0
    README_FAMILIES_MISSING="$README_FAMILIES_MISSING $fam"
  fi
done < <(find drill -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\n' | LC_ALL=C sort)

if [ ! -f "$DRILL_README" ]; then
  nope "the readme names every family. $DRILL_README does not exist"
elif [ "$FAMILY_COUNT" -lt 5 ]; then
  nope "the readme names every family. Only $FAMILY_COUNT family dir(s) found, so the row proves nothing"
elif [ "$README_FAMILIES_OK" -eq 1 ]; then
  ok "the readme names all $FAMILY_COUNT families found under drill/"
else
  nope "the readme names all $FAMILY_COUNT families found under drill/. Missing:$README_FAMILIES_MISSING"
fi

assert_lacks "the readme no longer claims a hardcoded drill count" \
  "$DRILL_README" '[0-9]+ blank-page drills'

assert_lacks "and no longer claims a hardcoded family count" \
  "$DRILL_README" '(four|eight|[0-9]+) families'

assert_matches "the readme tells him about the runner" \
  "$DRILL_README" './drill'

assert_matches "and about the study-side session that checks an attempt" \
  "$DRILL_README" '/check|/hint'

assert_matches "the readme still says the withheld files stay behind" \
  "$DRILL_README" 'ANSWER\.md'

# ---------------------------------------------------------------------------
echo
echo "== the study layout is what keeps four item walks clean =="
# ---------------------------------------------------------------------------

# drill/study/ sits where an item family sits, so a VISIBLE subdirectory under
# it reads as an item to this script, harness/drill-gate.sh, harness/test-drill.sh
# and the count helpers above. Measured before the layout moved: 65 items, 5
# gate findings, rc 1 from three of the four. Under a leading dot all four skip
# it on the `! -name '.*'` predicate they already carry.
#
# So this row is load-bearing for four files, and it is the reason none of them
# needed an exclusion added. Put a visible directory under drill/study/ and the
# tree goes red HERE, with the reason, rather than in four places at once.
STUDY_VISIBLE=$(find "$STUDY_SRC" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)
if [ ! -d "$STUDY_SRC" ]; then
  nope "drill/study/ carries no visible subdirectory. $STUDY_SRC does not exist"
elif [ -z "$STUDY_VISIBLE" ]; then
  ok "drill/study/ carries no visible subdirectory, so four item walks still see 64 items"
else
  nope "drill/study/ carries a visible subdirectory, which reads as an item at drill/<family>/<item>: $(tr '\n' ' ' <<<"$STUDY_VISIBLE")"
fi

# The live proof the row above is a proxy for, for THIS script's own walk.
run_deliver_realrepo --check "$TMPROOT/dest-real-study-check"
assert_rc0 "--check over the real corpus exits 0 with drill/study/ in the tree"
assert_never_names "and no part of the study tree reads as an item" \
  "drill/study" "$RUN_OUT"

# THE OTHER THREE WALKS ARE NOT RE-PROVED HERE, and that is a cost decision
# rather than an omission. harness/drill-gate.sh over the real tree is 3.1 s
# measured, and harness/test-drill.sh --static already runs it in this same
# fast tier at a 3.0 s budget, with harness/test-indeterminate.sh running it
# twice more on the slow tier. A fourth invocation would have been two thirds
# of this suite's wall time to re-establish what a sibling row establishes a
# second later. So the layout row above is what carries the other three, and
# what a reader should trust is that red here means red there.
if [ ! -f "$GATE" ]; then
  nope "the corpus gate exists to be run by its own suite. $GATE does not exist"
else
  ok "harness/drill-gate.sh exists, and harness/test-drill.sh --static is what runs it"
fi

# ---------------------------------------------------------------------------
echo
echo "== the two real trees no study row may name =="
# ---------------------------------------------------------------------------

STUDY_ALL_SEEN=$(cat "$STUDY_SEEN")

assert_never_names "no study or readme run ever named the real practice tree" \
  "$REAL_PRACTICE" "$STUDY_ALL_SEEN"

assert_never_names "and none ever named the real study tree" \
  "$REAL_STUDY" "$STUDY_ALL_SEEN"

assert_absent "nothing in this suite created a study tree under the sandboxed HOME" \
  "$SANDBOX_HOME/Study"

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
  # The study mode's two load-bearing arguments. Both are the kind a later
  # reader would otherwise undo as an inconsistency: a delivery script that
  # refuses a missing destination, and a source path carrying a leading dot
  # for no reason visible from the source tree.
  SCRIPT_BODY=$(cat "$SCRIPT")
  assert_says "the script argues why --study refuses a root it could create" \
    'WHY THE REFUSAL' "$SCRIPT_BODY"
  assert_says "and why the study source carries a hidden directory" \
    'WHY THE SOURCE MIRRORS THE DESTINATION' "$SCRIPT_BODY"
  assert_says "the script names the readme's file class rather than leaving it to be inferred" \
    'A FOURTH FILE CLASS' "$SCRIPT_BODY"
  # The study-mode manifest in the header is what a reader trusts over reading
  # the resolution loop, so a class delivered and absent from it is worse than
  # one that is not delivered at all.
  assert_says_literal "the study-mode manifest in the header names the register" \
    'drill/study/STYLE.md' "$SCRIPT_BODY"
  assert_says_literal "and names the style script with its mode" \
    'drill/study/style' "$SCRIPT_BODY"
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
