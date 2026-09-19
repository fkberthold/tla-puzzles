#!/usr/bin/env bash
# test-number-problems.sh: executable spec for scripts/number-problems.sh
# (bead tla-0lwx).
#
# Pins the RED invariant from the bead:
#
#   The delivered problem directory names stay in step with ORDER, so a
#   directory name carries its own position in the ramp. ORDER stays the one
#   source of truth, and the position is derived from it rather than written
#   into it twice.
#
# Usage:  harness/test-number-problems.sh
# Exit:   0 if all assertions hold, 1 otherwise.
#
# ---------------------------------------------------------------------------
# THE CONTRACT
#
#   scripts/number-problems.sh [--check] [<problems-root>]
#
#   <problems-root> defaults to $HOME/tla-practice/problems.
#
#   ORDER lives at <problems-root>/ORDER. Blank lines and lines whose first
#   non-space character is # are ignored. A line reading exactly
#   `checkpoint: ch13` or exactly `checkpoint: refinement` is ignored and does
#   not consume a position. Positions count the problem entries alone.
#
#   The entry at position N, 1-based, wants the directory named
#   printf '%02d_%s' N name. The directory that already belongs to an entry is
#   the one matching ^([0-9]+_)?<name>$, so a re-run finds what it numbered
#   last time.
#
#   With no flag the script renames. With --check it reports and changes
#   nothing.
#
#   A directory the ORDER does not name is allowed while it carries no
#   ^[0-9]+_ prefix. An unnumbered stranger is fine. A numbered stranger is an
#   error.
#
#   Exit 0 when the tree is clean or the renames all succeeded. Exit 1 on a
#   disagreement under --check, or a rename that could not complete. Exit 2 on
#   a usage error, a missing root, or a missing ORDER.
#
# ---------------------------------------------------------------------------
# TWO AMENDMENTS, 2026-09-18
#
# The first draft of this suite left two cases open because the contract didn't
# settle them. Central settled both, and they're pinned below.
#
# A. --check catches a FOURTH shape. An ORDER entry whose directory sits under
#    its bare name has no number, and that's a disagreement. --check exits 1
#    and names it. Without this the gate goes green on exactly the tree a bare
#    run would rewrite, which is the drift the gate exists to catch.
#
#    So --check exits 1 on four shapes. A numbered directory ORDER doesn't
#    name. A number that disagrees with its position. An entry with no
#    directory under either spelling. An entry whose directory is still bare.
#
# B. The bare run FAILS CLOSED. A numbered stranger, or an ORDER entry with no
#    directory under either spelling, stops the whole run. It renames nothing,
#    reports, and exits 1.
#
#    The reason is the tree it works on. ~/tla-practice is not a git repo and
#    holds live attempt state, so a rename the script can't account for is a
#    guess that doesn't come back. A partial application is worse than a
#    refusal, because it leaves a tree nobody can reason about. One name it
#    can't account for stops everything and tells the human.
#
#    An unnumbered stranger triggers none of this. scratch-pad in the happy
#    path stays exactly where it is.
#
# ---------------------------------------------------------------------------
# THREE RULINGS ON PHASE 3, AND ONE ON THE MATCH (bead tla-rgpe)
#
# Phase 3 applied its renames through two loops of bare mv with nothing reading
# a return code, so a rename that failed was skipped and the run still exited
# 0. That is the "a rename that could not complete" clause of the contract,
# unimplemented. Central settled how it should behave, and the three rulings
# are pinned in the two sections above the structural one.
#
# 1. Every mv is checked. A failure names the rename and exits 1.
#
# 2. No rollback. The renames already applied stay applied. Undoing them means
#    more code running on a tree that is already wrong, and this tree has no
#    history to fall back on. The run reports the exact state and stops, and it
#    names the temp suffix so a human can find what is parked.
#
# 3. A directory whose name carries .number-problems-tmp. is the residue of a
#    run that died between the two passes. --check names it and exits 1, and a
#    bare run refuses rather than renaming around it.
#
# The fourth change is smaller and has no ruling behind it. The ORDER entry was
# interpolated straight into an extended regex, so an entry carrying a dot or a
# plus matched more than itself. Nothing in the ramp does today, which is why
# the fixture for it has to be built rather than borrowed.
#
# ---------------------------------------------------------------------------
# WHY EVERY RUN IS SANDBOXED TWICE
#
# The real tree at ~/tla-practice is not a git repo, so a bad rename doesn't
# come back, and Frank has live attempt state in two of its directories. So
# this suite never names that path and never reads it. Every fixture is built
# under a fresh mktemp root, and every run also redirects HOME, which is where
# the default root resolves from. A script that drops its root argument then
# writes into the sandbox instead of into the real tree.
#
# The default-root section goes further, because the sandboxed HOME only helps
# a script that reads HOME at all. A hardcoded path would walk straight past
# it. So that section proves the sandbox was read before it runs anything that
# renames. See the guard there.
#
# ---------------------------------------------------------------------------
# WHAT THE ASSERTIONS ARE SHAPED AROUND
#
# Exit codes are matched exactly, never as "non-zero". A missing script exits
# 127, and 127 satisfies every non-zero test in the file. Exact matching is
# what keeps this suite red while the script is absent, and the contract hands
# us three distinct codes to match against anyway.
#
# The absence and no-change assertions carry the same control the sibling
# harness/test-deliver-exercises.sh uses. A run that never started leaves the
# tree exactly as it found it, so "nothing moved" only means something once the
# run it survived exited the code the contract promised.
#
# Each of the four --check fixtures carries exactly one defect. Four roots that
# each exit 1 for a different reason is what tells the shapes apart. A single
# root holding all four would go green on a script that caught one.
#
# The two fail-closed fixtures are built the other way round on purpose. Each
# holds a name the script can't account for AND two entries it could have
# renamed, because "it renamed nothing" only says something when there was
# something to rename.
#
# Message text is not pinned. The contract says --check reports and doesn't say
# what it prints, so the reports assertions require the offending name to
# appear somewhere across stdout and stderr, and nothing more.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="scripts/number-problems.sh"
TEST_RUNNER="scripts/test"

pass_count=0
fail_count=0
skip_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

# skip <label> <reason>
#
# A row this box cannot run, printed rather than passed. Its one caller is the
# read-only-root section, which needs a permission bit root ignores. Counting a
# row like that as a pass would report coverage the run never had, and the
# suite would go green on a box that tested three fewer things.
skip() { printf "  SKIP  %s. %s\n" "$1" "$2"; skip_count=$((skip_count + 1)); }

SCRIPT_PRESENT=0
[ -f "$SCRIPT" ] && SCRIPT_PRESENT=1

# ---------------------------------------------------------------------------
# Fixtures.
# ---------------------------------------------------------------------------

TMPROOT=$(mktemp -d -t tla_number.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

SANDBOX_HOME="$TMPROOT/home"
ERRFILE="$TMPROOT/stderr.txt"
mkdir -p "$SANDBOX_HOME"

ROOT_HAPPY="$TMPROOT/happy"       # all bare, one comment, one blank, two checkpoints
ROOT_CLEAN="$TMPROOT/clean"       # already numbered and correct
ROOT_STRANGE="$TMPROOT/stranger"  # shape 1: a numbered directory ORDER doesn't name
ROOT_MISNUM="$TMPROOT/misnum"     # shape 2: a number that disagrees with its position
ROOT_MISSING="$TMPROOT/missing"   # shape 3: an entry with no directory behind it
ROOT_UNNUM="$TMPROOT/unnumbered"  # shape 4: an entry still under its bare name
ROOT_RENUM="$TMPROOT/renum"       # the rename side of shape 2
ROOT_NOORDER="$TMPROOT/noorder"   # a root with no ORDER file
ROOT_ABSENT="$TMPROOT/absent"     # never created, on purpose

# The phase-3 roots, added by bead tla-rgpe.
ROOT_REGEX="$TMPROOT/regex"             # an ORDER entry carrying a regex metacharacter
ROOT_MVFAIL="$TMPROOT/mvfail"           # a rename blocked by an occupied final name
ROOT_MVPERM="$TMPROOT/mvperm"           # a rename blocked by a read-only root
ROOT_STRAND="$TMPROOT/strand"           # the residue of a run that died mid-rename
ROOT_STRAND_BARE="$TMPROOT/strand-bare" # the same residue, under a bare run

# The suffix phase 3 parks a directory under between its two rename passes.
# The script appends its own PID. 31337 is a PID no run of this suite will
# carry, so a fixture built with it reads as residue left by an earlier run and
# never as something the run under test just made.
STRAND_SUFFIX=".number-problems-tmp.31337"

# Amendment B, the two trees a bare run has to refuse outright.
ROOT_SHUT_STRANGE="$TMPROOT/shut-stranger"
ROOT_SHUT_MISSING="$TMPROOT/shut-missing"

DEFAULT_ROOT="$SANDBOX_HOME/tla-practice/problems"

# make_problem <root> <dirname> <marker-text>
#
# The marker is what tells a rename from a delete plus a fresh mkdir. Frank's
# attempt state lives inside these directories, so moving the name while losing
# the contents is the failure that matters most and the one a directory listing
# won't show.
make_problem() {
  mkdir -p "$1/$2"
  printf '%s\n' "$3" >"$1/$2/MARK"
}

# --- the happy path --------------------------------------------------------
#
# The two checkpoint spellings sit between entries rather than at the end, so
# a script that counts lines instead of entries gets river-call and
# assay-office wrong by one and two.
mkdir -p "$ROOT_HAPPY"
{
  printf '# the ramp, in order\n'
  printf 'bonded-store\n'
  printf '\n'
  printf 'laytime\n'
  printf 'checkpoint: ch13\n'
  printf 'river-call\n'
  printf '   # an indented comment, still a comment\n'
  printf 'checkpoint: refinement\n'
  printf 'assay-office\n'
} >"$ROOT_HAPPY/ORDER"
make_problem "$ROOT_HAPPY" bonded-store "attempt state for bonded-store"
make_problem "$ROOT_HAPPY" laytime      "attempt state for laytime"
make_problem "$ROOT_HAPPY" river-call   "attempt state for river-call"
make_problem "$ROOT_HAPPY" assay-office "attempt state for assay-office"
make_problem "$ROOT_HAPPY" scratch-pad  "an unnumbered stranger, outside the ramp"

# --- a clean, already-numbered tree -----------------------------------------
mkdir -p "$ROOT_CLEAN"
{
  printf '# already in step\n'
  printf 'alpha\n'
  printf 'checkpoint: ch13\n'
  printf 'beta\n'
  printf 'gamma\n'
} >"$ROOT_CLEAN/ORDER"
make_problem "$ROOT_CLEAN" 01_alpha   "alpha"
make_problem "$ROOT_CLEAN" 02_beta    "beta"
make_problem "$ROOT_CLEAN" 03_gamma   "gamma"
make_problem "$ROOT_CLEAN" loose-notes "an unnumbered stranger, allowed"

# --- shape 1: a numbered directory ORDER does not name ----------------------
mkdir -p "$ROOT_STRANGE"
printf 'alpha\nbeta\n' >"$ROOT_STRANGE/ORDER"
make_problem "$ROOT_STRANGE" 01_alpha        "alpha"
make_problem "$ROOT_STRANGE" 02_beta         "beta"
make_problem "$ROOT_STRANGE" 07_ghost-tender "a numbered stranger, an error"

# --- shape 2: a number that disagrees with its ORDER position ---------------
mkdir -p "$ROOT_MISNUM"
printf 'alpha\nbeta\ngamma\n' >"$ROOT_MISNUM/ORDER"
make_problem "$ROOT_MISNUM" 01_alpha "alpha"
make_problem "$ROOT_MISNUM" 05_beta  "beta"
make_problem "$ROOT_MISNUM" 03_gamma "gamma"

# --- shape 3: an entry with no directory behind it --------------------------
#
# gamma is absent under both the bare and the numbered spelling, which is the
# case the contract names.
mkdir -p "$ROOT_MISSING"
printf 'alpha\nbeta\ngamma\n' >"$ROOT_MISSING/ORDER"
make_problem "$ROOT_MISSING" 01_alpha "alpha"
make_problem "$ROOT_MISSING" 02_beta  "beta"

# --- shape 4: an entry still sitting under its bare name ---------------------
#
# alpha is already correct, so beta carrying no number is the only defect in
# the root. This is the one --check fixture that isn't fully pre-numbered, and
# it has to be, because being bare is the shape under test.
mkdir -p "$ROOT_UNNUM"
printf 'alpha\nbeta\n' >"$ROOT_UNNUM/ORDER"
make_problem "$ROOT_UNNUM" 01_alpha "alpha"
make_problem "$ROOT_UNNUM" beta     "beta"

# --- amendment B: two trees the bare run has to refuse ----------------------
#
# Both hold two bare entries the script could number, plus one name it can't
# account for. The bare entries are the whole point. A run that numbers what it
# understands and then stops has left a half-applied tree, and that tree has no
# git history to come back from.
mkdir -p "$ROOT_SHUT_STRANGE"
printf 'alpha\nbeta\n' >"$ROOT_SHUT_STRANGE/ORDER"
make_problem "$ROOT_SHUT_STRANGE" alpha           "alpha"
make_problem "$ROOT_SHUT_STRANGE" beta            "beta"
make_problem "$ROOT_SHUT_STRANGE" 07_ghost-tender "a numbered stranger, an error"

mkdir -p "$ROOT_SHUT_MISSING"
printf 'alpha\nbeta\ngamma\n' >"$ROOT_SHUT_MISSING/ORDER"
make_problem "$ROOT_SHUT_MISSING" alpha "alpha"
make_problem "$ROOT_SHUT_MISSING" beta  "beta"

# --- the rename side of shape 2 ---------------------------------------------
mkdir -p "$ROOT_RENUM"
printf 'alpha\nbeta\ngamma\n' >"$ROOT_RENUM/ORDER"
make_problem "$ROOT_RENUM" 01_alpha "alpha"
make_problem "$ROOT_RENUM" 05_beta  "beta"
make_problem "$ROOT_RENUM" 03_gamma "gamma"

# --- an ORDER entry carrying a regex metacharacter --------------------------
#
# ORDER names two.phase and the tree holds twoxphase and nothing else. The two
# names differ, so the entry has no directory behind it and the run has to
# refuse. A script that builds ^([0-9]+_)?two.phase$ and matches on it reads
# the dot as "any character", finds twoxphase, and numbers a directory ORDER
# never named.
#
# Every name in the ramp today is lowercase letters and hyphens, so nothing in
# the real tree turns on this. That is the reason to pin it now rather than
# after a name with a dot in it lands.
mkdir -p "$ROOT_REGEX"
printf 'two.phase\n' >"$ROOT_REGEX/ORDER"
make_problem "$ROOT_REGEX" twoxphase "a name ORDER does not name"

# --- a rename blocked by an occupied final name -----------------------------
#
# 02_beta here is a plain file, not a directory, so both sweeps walk past it:
# they glob "$root"/*/ and a file does not match. The tree validates clean, the
# plan carries one rename, and phase 3 parks 05_beta under its temp suffix and
# then cannot move it onto the name a file already holds.
#
# The occupied name is what makes this fixture work as any user. The sibling
# below blocks the same rename with a permission bit, which root ignores.
mkdir -p "$ROOT_MVFAIL"
printf 'alpha\nbeta\n' >"$ROOT_MVFAIL/ORDER"
make_problem "$ROOT_MVFAIL" 01_alpha "alpha"
make_problem "$ROOT_MVFAIL" 05_beta  "beta"
printf 'a plain file wearing the name 05_beta has to take\n' >"$ROOT_MVFAIL/02_beta"

# --- a rename blocked by a read-only root -----------------------------------
#
# Both entries are bare and both need renaming, so the first mv of phase 3 is
# the one that fails and nothing gets as far as the temp suffix. The chmod
# lands in the section itself rather than here, so the root spends as little
# time unwritable as it can and the EXIT trap can always clean up.
mkdir -p "$ROOT_MVPERM"
printf 'alpha\nbeta\n' >"$ROOT_MVPERM/ORDER"
make_problem "$ROOT_MVPERM" alpha "alpha"
make_problem "$ROOT_MVPERM" beta  "beta"

# --- the residue of a run that died mid-rename ------------------------------
#
# Both roots are in step apart from the parked directory, so that name is the
# only thing either run has to object to. ROOT_STRAND_BARE carries one bare
# entry on top, because "it renamed nothing" says nothing unless there was
# something there to rename.
mkdir -p "$ROOT_STRAND"
printf 'alpha\nbeta\n' >"$ROOT_STRAND/ORDER"
make_problem "$ROOT_STRAND" 01_alpha "alpha"
make_problem "$ROOT_STRAND" 02_beta  "beta"
make_problem "$ROOT_STRAND" "02_beta$STRAND_SUFFIX" "beta, parked by a run that died"

mkdir -p "$ROOT_STRAND_BARE"
printf 'alpha\nbeta\n' >"$ROOT_STRAND_BARE/ORDER"
make_problem "$ROOT_STRAND_BARE" alpha   "alpha"
make_problem "$ROOT_STRAND_BARE" 02_beta "beta"
make_problem "$ROOT_STRAND_BARE" "02_beta$STRAND_SUFFIX" "beta, parked by a run that died"

# --- a root with no ORDER ---------------------------------------------------
mkdir -p "$ROOT_NOORDER"
make_problem "$ROOT_NOORDER" 01_alpha "alpha"

# --- the default root, under the sandboxed HOME -----------------------------
#
# beta-default is a name that exists in no other fixture and in no real tree.
# The default-root section uses it to prove which root got read.
mkdir -p "$DEFAULT_ROOT"
printf 'alpha-default\nbeta-default\n' >"$DEFAULT_ROOT/ORDER"
make_problem "$DEFAULT_ROOT" 01_alpha-default "alpha-default"
make_problem "$DEFAULT_ROOT" 09_beta-default  "beta-default"

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

RUN_OUT=""
RUN_ERR=""
RUN_ALL=""
RUN_RC=0

# run_np [args...]
#
# HOME is redirected on every run without exception, including the runs that
# pass an explicit root. A script that mishandles its argument and falls back
# to the default then lands in the sandbox.
run_np() {
  RUN_OUT=$(HOME="$SANDBOX_HOME" bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
  RUN_ALL="$RUN_OUT
$RUN_ERR"
}

# assert_rc <label> <wanted>
#
# Exact, never "non-zero". The contract gives three codes and a missing script
# gives a fourth, so an exact match is both the contract and the control.
assert_rc() {
  local label="$1" want="$2"
  if [ "$RUN_RC" -eq "$want" ]; then
    ok "$label"
  else
    nope "$label. rc=$RUN_RC, wanted $want. stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  fi
}

# snapshot <root> -> stdout
#
# Names and contents both. A --check that renamed nothing but rewrote a MARK
# would pass a names-only comparison, and the marks are the attempt state.
snapshot() {
  local root="$1"
  [ -d "$root" ] || { printf '<absent>\n'; return; }
  (cd "$root" && find . -mindepth 1 | LC_ALL=C sort)
  (cd "$root" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s :: %s\n' "$f" "$(cat "$f")"
  done)
}

# assert_unchanged <label> <root> <before> <rc-that-had-to-hold>
#
# The vacuity control. A run that never started changes nothing, so require the
# run to have exited the code the contract promised before reading anything
# into the tree standing still.
assert_unchanged() {
  local label="$1" root="$2" before="$3" want_rc="$4" after
  if [ "$RUN_RC" -ne "$want_rc" ]; then
    nope "$label. The run that had to leave the tree alone exited $RUN_RC, not $want_rc, so no change proves nothing"
    return
  fi
  after=$(snapshot "$root")
  if [ "$after" = "$before" ]; then
    ok "$label"
  else
    nope "$label. The tree moved under --check:$(printf '\n')$(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after"))"
  fi
}

# assert_marker <label> <path> <wanted-text> <rc-that-had-to-hold>
#
# Presence and contents in one row. The directory arriving with the right name
# and the wrong insides is a rename that lost the work.
#
# The rc argument is the vacuity control, and it's here because half these rows
# are survival claims. "The stranger is still there" is satisfied by a run that
# never started, so the run has to have exited the code the contract promised
# before the file standing still says anything. Without it five rows in this
# suite go green against no script at all.
assert_marker() {
  local label="$1" path="$2" want="$3" want_rc="$4" got
  if [ "$RUN_RC" -ne "$want_rc" ]; then
    nope "$label. The run exited $RUN_RC, not $want_rc, so the state of the tree proves nothing"
    return
  fi
  if [ ! -d "${path%/*}" ]; then
    nope "$label. The directory does not exist: ${path%/*}"
    return
  fi
  if [ ! -f "$path" ]; then
    nope "$label. The directory exists but carries no MARK: $path"
    return
  fi
  got=$(cat "$path")
  if [ "$got" = "$want" ]; then
    ok "$label"
  else
    nope "$label. Wanted '$want', got '$got'"
  fi
}

# assert_gone <label> <root> <name> <rc-that-had-to-hold>
#
# Two absence controls, not one. The run has to have exited the code the
# contract promised, and the root has to still hold something. A run that never
# started and a script that emptied the tree both satisfy a bare `[ ! -e ]`.
assert_gone() {
  local label="$1" root="$2" name="$3" want_rc="$4"
  if [ "$RUN_RC" -ne "$want_rc" ]; then
    nope "$label. The run exited $RUN_RC, not $want_rc, so the absence proves nothing"
    return
  fi
  if [ ! -d "$root" ]; then
    nope "$label. The root itself is gone ($root), so the absence proves nothing"
  elif [ -z "$(ls -A "$root" 2>/dev/null)" ]; then
    nope "$label. The root is empty, so the absence proves nothing"
  elif [ -e "$root/$name" ]; then
    nope "$label. Still present: $root/$name"
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
    nope "$label. Nothing across stdout and stderr matched: $pattern"
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
echo "== the happy path: four bare names take their positions =="
# ---------------------------------------------------------------------------

run_np "$ROOT_HAPPY"

assert_rc "a first run over a bare tree exits 0" 0

assert_marker "bonded-store becomes 01_bonded-store" \
  "$ROOT_HAPPY/01_bonded-store/MARK" "attempt state for bonded-store" 0

assert_marker "laytime becomes 02_laytime" \
  "$ROOT_HAPPY/02_laytime/MARK" "attempt state for laytime" 0

# The two rows the checkpoint lines bear on. river-call follows
# `checkpoint: ch13` and is still 3, and assay-office follows a second
# checkpoint and is still 4.
assert_marker "a checkpoint: ch13 line consumes no position" \
  "$ROOT_HAPPY/03_river-call/MARK" "attempt state for river-call" 0

assert_marker "a checkpoint: refinement line consumes no position either" \
  "$ROOT_HAPPY/04_assay-office/MARK" "attempt state for assay-office" 0

assert_gone "the bare bonded-store is gone, not copied" "$ROOT_HAPPY" bonded-store 0
assert_gone "the bare laytime is gone, not copied"      "$ROOT_HAPPY" laytime      0
assert_gone "the bare river-call is gone, not copied"   "$ROOT_HAPPY" river-call   0
assert_gone "the bare assay-office is gone, not copied" "$ROOT_HAPPY" assay-office 0

assert_marker "an unnumbered stranger is left alone" \
  "$ROOT_HAPPY/scratch-pad/MARK" "an unnumbered stranger, outside the ramp" 0

if [ "$RUN_RC" -ne 0 ]; then
  nope "ORDER survives the run. The run exited $RUN_RC, not 0, so its survival proves nothing"
elif [ -f "$ROOT_HAPPY/ORDER" ]; then
  ok "ORDER survives the run"
else
  nope "ORDER does not survive the run"
fi

# ---------------------------------------------------------------------------
echo
echo "== the second run is a no-op =="
# ---------------------------------------------------------------------------

# This is the ^([0-9]+_)?<name>$ rule from the other side. A script that only
# looks for the bare name finds nothing on the second pass, and what it does
# then is anyone's guess.
HAPPY_BEFORE=$(snapshot "$ROOT_HAPPY")

run_np "$ROOT_HAPPY"

assert_rc "a second run over the same tree exits 0" 0

assert_unchanged "a second run moves nothing" "$ROOT_HAPPY" "$HAPPY_BEFORE" 0

run_np --check "$ROOT_HAPPY"

assert_rc "--check on the tree the script just numbered exits 0" 0

# ---------------------------------------------------------------------------
echo
echo "== --check is green on a clean tree, and touches nothing =="
# ---------------------------------------------------------------------------

CLEAN_BEFORE=$(snapshot "$ROOT_CLEAN")

run_np --check "$ROOT_CLEAN"

assert_rc "--check on a clean numbered tree exits 0" 0

assert_unchanged "--check changes nothing on a clean tree" \
  "$ROOT_CLEAN" "$CLEAN_BEFORE" 0

# A stranger with no ^[0-9]+_ prefix is allowed, and the row above already
# depends on it: loose-notes sits in this fixture, and --check went green with
# it there.
assert_marker "the unnumbered stranger survived --check" \
  "$ROOT_CLEAN/loose-notes/MARK" "an unnumbered stranger, allowed" 0

# The bare run agrees with --check on the same tree.
run_np "$ROOT_CLEAN"

assert_rc "a bare run on a clean tree exits 0" 0

assert_unchanged "a bare run on a clean tree moves nothing" \
  "$ROOT_CLEAN" "$CLEAN_BEFORE" 0

# ---------------------------------------------------------------------------
echo
echo "== shape 1: a numbered directory ORDER does not name =="
# ---------------------------------------------------------------------------

STRANGE_BEFORE=$(snapshot "$ROOT_STRANGE")

run_np --check "$ROOT_STRANGE"

assert_rc "--check exits 1 on a numbered stranger" 1

assert_says "--check names the numbered stranger" \
  'ghost-tender' "$RUN_ALL"

assert_unchanged "--check leaves the numbered stranger in place" \
  "$ROOT_STRANGE" "$STRANGE_BEFORE" 1

# ---------------------------------------------------------------------------
echo
echo "== shape 2: a number that disagrees with its ORDER position =="
# ---------------------------------------------------------------------------

MISNUM_BEFORE=$(snapshot "$ROOT_MISNUM")

run_np --check "$ROOT_MISNUM"

assert_rc "--check exits 1 when 05_beta sits at position 2" 1

assert_says "--check names the misnumbered entry" \
  'beta' "$RUN_ALL"

assert_unchanged "--check does not renumber anything" \
  "$ROOT_MISNUM" "$MISNUM_BEFORE" 1

# ---------------------------------------------------------------------------
echo
echo "== shape 3: an ORDER entry with no directory behind it =="
# ---------------------------------------------------------------------------

MISSING_BEFORE=$(snapshot "$ROOT_MISSING")

run_np --check "$ROOT_MISSING"

assert_rc "--check exits 1 when gamma has no directory under either name" 1

assert_says "--check names the entry with nothing behind it" \
  'gamma' "$RUN_ALL"

assert_unchanged "--check invents no directory for the missing entry" \
  "$ROOT_MISSING" "$MISSING_BEFORE" 1

# ---------------------------------------------------------------------------
echo
echo "== shape 4: an ORDER entry still sitting under its bare name =="
# ---------------------------------------------------------------------------

# Amendment A. This is the shape that makes --check worth running at all. A
# gate that passes here passes on precisely the tree a bare run would rewrite,
# so it would report "in step" about a tree that is out of step.
UNNUM_BEFORE=$(snapshot "$ROOT_UNNUM")

run_np --check "$ROOT_UNNUM"

assert_rc "--check exits 1 when beta still sits under its bare name" 1

assert_says "--check names the entry carrying no number" \
  'beta' "$RUN_ALL"

assert_unchanged "--check numbers nothing itself" \
  "$ROOT_UNNUM" "$UNNUM_BEFORE" 1

# ---------------------------------------------------------------------------
echo
echo "== a bare run renumbers a directory it numbered before =="
# ---------------------------------------------------------------------------

run_np "$ROOT_RENUM"

assert_rc "a bare run over a misnumbered tree exits 0" 0

assert_marker "05_beta is renumbered to 02_beta with its contents" \
  "$ROOT_RENUM/02_beta/MARK" "beta" 0

assert_gone "05_beta is gone afterwards" "$ROOT_RENUM" 05_beta 0

assert_marker "01_alpha is left where it already was" \
  "$ROOT_RENUM/01_alpha/MARK" "alpha" 0

assert_marker "03_gamma is left where it already was" \
  "$ROOT_RENUM/03_gamma/MARK" "gamma" 0

run_np --check "$ROOT_RENUM"

assert_rc "--check is green once the bare run has fixed the tree" 0

# ---------------------------------------------------------------------------
echo
echo "== the bare run fails closed, and renames nothing on the way out =="
# ---------------------------------------------------------------------------

# Amendment B, and the closed half of the section above. That one proves a bare
# run renames when every name is accountable. These two prove it renames
# nothing when one name isn't.
#
# The rows that carry the weight are the ones saying alpha stayed bare. Exit 1
# alone is satisfied by a script that numbered alpha and beta, hit the name it
# couldn't place, and gave up holding a half-applied tree. That tree is the
# outcome the refusal exists to prevent.
#
# Fresh roots rather than the --check ones above, so a script that mutates
# under --check fails that section instead of quietly poisoning this one.

SHUT_STRANGE_BEFORE=$(snapshot "$ROOT_SHUT_STRANGE")

run_np "$ROOT_SHUT_STRANGE"

assert_rc "a bare run exits 1 on a numbered stranger" 1

assert_says "the bare run names the numbered stranger" \
  'ghost-tender' "$RUN_ALL"

assert_unchanged "the bare run leaves the whole tree alone" \
  "$ROOT_SHUT_STRANGE" "$SHUT_STRANGE_BEFORE" 1

assert_marker "alpha is still bare, not numbered ahead of the refusal" \
  "$ROOT_SHUT_STRANGE/alpha/MARK" "alpha" 1

assert_gone "no 01_alpha was created before the run gave up" \
  "$ROOT_SHUT_STRANGE" 01_alpha 1

assert_gone "no 02_beta was created before the run gave up" \
  "$ROOT_SHUT_STRANGE" 02_beta 1

SHUT_MISSING_BEFORE=$(snapshot "$ROOT_SHUT_MISSING")

run_np "$ROOT_SHUT_MISSING"

assert_rc "a bare run exits 1 when gamma has no directory" 1

assert_says "the bare run names the entry with nothing behind it" \
  'gamma' "$RUN_ALL"

assert_unchanged "the bare run leaves the whole tree alone when an entry is missing" \
  "$ROOT_SHUT_MISSING" "$SHUT_MISSING_BEFORE" 1

# alpha and beta sit at positions 1 and 2 and are both accountable. Only gamma,
# at position 3, has nothing behind it. A script that works down the list
# renames these two before it ever reaches the problem.
assert_marker "alpha is still bare when a later entry is missing" \
  "$ROOT_SHUT_MISSING/alpha/MARK" "alpha" 1

assert_gone "no 01_alpha was created before the missing entry was found" \
  "$ROOT_SHUT_MISSING" 01_alpha 1

assert_gone "no 02_beta was created before the missing entry was found" \
  "$ROOT_SHUT_MISSING" 02_beta 1

# ---------------------------------------------------------------------------
echo
echo "== exit 2: usage, a missing root, a missing ORDER =="
# ---------------------------------------------------------------------------

run_np --bogus "$ROOT_CLEAN"
assert_rc "an unknown flag exits 2" 2

run_np "$ROOT_CLEAN" "$ROOT_HAPPY"
assert_rc "a second positional argument exits 2" 2

run_np "$ROOT_ABSENT"
assert_rc "a root that does not exist exits 2" 2

run_np --check "$ROOT_ABSENT"
assert_rc "a root that does not exist exits 2 under --check too" 2

run_np "$ROOT_NOORDER"
assert_rc "a root with no ORDER exits 2" 2

run_np --check "$ROOT_NOORDER"
assert_rc "a root with no ORDER exits 2 under --check too" 2

# ---------------------------------------------------------------------------
echo
echo "== the three exit codes are distinct =="
# ---------------------------------------------------------------------------

# One representative of each, read back together. Every row above matches its
# code exactly, so this is a summary rather than new coverage, and it's here
# because a suite that only ever sees "non-zero" can't tell a refusal from a
# disagreement.
run_np --check "$ROOT_CLEAN";   RC_CLEAN=$RUN_RC
run_np --check "$ROOT_MISNUM";  RC_DISAGREE=$RUN_RC
run_np "$ROOT_NOORDER";         RC_REFUSE=$RUN_RC

if [ "$RC_CLEAN" -eq 0 ] && [ "$RC_DISAGREE" -eq 1 ] && [ "$RC_REFUSE" -eq 2 ]; then
  ok "clean=0, disagreement=1, refusal=2 are three different codes"
else
  nope "the three codes are not 0/1/2. clean=$RC_CLEAN disagreement=$RC_DISAGREE refusal=$RC_REFUSE"
fi

# ---------------------------------------------------------------------------
echo
echo "== the default root, against a sandboxed HOME =="
# ---------------------------------------------------------------------------

# Read-only first, and the escalation below is guarded on it.
#
# A sandboxed HOME protects a script that resolves its default from HOME. It
# does nothing for one that hardcodes a path, and that script would rename
# Frank's live tree the moment this section ran without a flag. So the first
# run is --check, which the contract says changes nothing, and it has to name
# beta-default. That name exists in this fixture and nowhere else, so seeing it
# come back is the evidence that the sandbox is the root being read.
DEFAULT_BEFORE=$(snapshot "$DEFAULT_ROOT")

run_np --check

assert_rc "--check with no root argument exits 1 on the sandboxed default root" 1

assert_says "--check with no root argument reads the sandboxed default root" \
  'beta-default' "$RUN_ALL"

assert_unchanged "--check with no root argument changes nothing" \
  "$DEFAULT_ROOT" "$DEFAULT_BEFORE" 1

DEFAULT_PROVEN=0
if [ "$RUN_RC" -eq 1 ] && grep -qE -- 'beta-default' <<<"$RUN_ALL"; then
  DEFAULT_PROVEN=1
fi

if [ "$DEFAULT_PROVEN" -eq 1 ]; then
  run_np

  assert_rc "a bare run with no root argument exits 0" 0

  assert_marker "the default root is renumbered: 09_beta-default becomes 02_beta-default" \
    "$DEFAULT_ROOT/02_beta-default/MARK" "beta-default" 0

  assert_gone "09_beta-default is gone from the default root" \
    "$DEFAULT_ROOT" 09_beta-default 0
else
  nope "a bare run with no root argument exits 0. SKIPPED: the --check above did not prove the sandboxed default root was read, and running a rename against an unproven default would put the real tree at risk"
  nope "the default root is renumbered: 09_beta-default becomes 02_beta-default. SKIPPED for the same reason"
  nope "09_beta-default is gone from the default root. SKIPPED for the same reason"
fi

# ---------------------------------------------------------------------------
echo
echo "== an ORDER entry is matched literally, not as a regex =="
# ---------------------------------------------------------------------------

# The bare run rather than --check, because the bare run is where the damage
# is. Under --check a loose match and a missing entry both exit 1, so --check
# cannot tell the two apart. The bare run renames on one and refuses on the
# other, and the tree afterwards says which one happened.
REGEX_BEFORE=$(snapshot "$ROOT_REGEX")

run_np "$ROOT_REGEX"

assert_rc "a bare run exits 1 when two.phase has no directory of its own" 1

assert_says "the report names the entry nothing matched" \
  'two\.phase' "$RUN_ALL"

assert_unchanged "twoxphase is not renamed into the entry's place" \
  "$ROOT_REGEX" "$REGEX_BEFORE" 1

assert_marker "twoxphase keeps its name and its contents" \
  "$ROOT_REGEX/twoxphase/MARK" "a name ORDER does not name" 1

assert_gone "no 01_two.phase is invented out of a loose match" \
  "$ROOT_REGEX" "01_two.phase" 1

# ---------------------------------------------------------------------------
echo
echo "== a rename that cannot complete stops the run =="
# ---------------------------------------------------------------------------

# Phase 3 ran two loops of bare mv with nothing reading a return code, so a
# rename that failed was skipped and the run still exited 0. The contract has
# said exit 1 on a rename that could not complete since the first draft, and
# these rows are that clause.
#
# None of them asks for a rollback, and that is the ruling rather than an
# omission. Undoing a half-applied rename means more code running on a tree
# that is already wrong, and this tree has no history to fall back on. The run
# says where it stopped and stops.

run_np "$ROOT_MVFAIL"

assert_rc "a bare run exits 1 when a rename cannot complete" 1

# mv prints its own complaint, and that complaint carries the final name and
# the parked name. It does not carry 05_beta. So a row that matches 05_beta in
# the script's own voice stays red against a run that lets mv do all the
# talking, which is what the two bare loops did.
assert_says "the report names the directory whose rename could not complete" \
  'number-problems\.sh:.*05_beta' "$RUN_ALL"

assert_says "the report names the temp suffix the directory is parked under" \
  'number-problems\.sh:.*\.number-problems-tmp\.' "$RUN_ALL"

# The no-rollback ruling, read off the tree rather than off the report. The
# parked directory is still parked and still holds beta's attempt state.
#
# Globbed rather than piped into head. `find ... | head -1` returns 141 under
# pipefail (bead tla-kr9) and harness/test-pipefail.sh bans the form.
MVFAIL_PARKED=""
for d in "$ROOT_MVFAIL"/*.number-problems-tmp.*/; do
  [ -d "$d" ] || continue
  MVFAIL_PARKED="${d%/}"
  break
done

if [ "$RUN_RC" -ne 1 ]; then
  nope "the parked directory is left where it is. The run exited $RUN_RC, not 1, so the state of the tree proves nothing"
elif [ -z "$MVFAIL_PARKED" ]; then
  nope "the parked directory is left where it is. Nothing under the temp suffix survived the failure"
else
  assert_marker "the parked directory is left where it is, with its contents" \
    "$MVFAIL_PARKED/MARK" "beta" 1
fi

# The same clause reached through a permission bit instead of an occupied
# name. This one stops on the first rename, so nothing reaches the temp suffix
# and the tree comes out untouched.
#
# root ignores the bit, the renames then succeed, and all three rows would
# report a defect the script does not have. So they say so and do not run.
if [ "$(id -u)" -eq 0 ]; then
  skip "a bare run exits 1 when the root cannot be written" \
    "running as root, which ignores the permission bit this row is built on"
  skip "the report names the rename that could not start" \
    "running as root, which ignores the permission bit this row is built on"
  skip "a blocked first rename leaves the whole tree alone" \
    "running as root, which ignores the permission bit this row is built on"
else
  MVPERM_BEFORE=$(snapshot "$ROOT_MVPERM")

  chmod 555 "$ROOT_MVPERM"
  run_np "$ROOT_MVPERM"
  chmod 755 "$ROOT_MVPERM"

  assert_rc "a bare run exits 1 when the root cannot be written" 1

  assert_says "the report names the rename that could not start" \
    'number-problems\.sh:.*alpha' "$RUN_ALL"

  assert_unchanged "a blocked first rename leaves the whole tree alone" \
    "$ROOT_MVPERM" "$MVPERM_BEFORE" 1
fi

# ---------------------------------------------------------------------------
echo
echo "== the residue of a run that died mid-rename =="
# ---------------------------------------------------------------------------

# Phase 3 parks each directory under <final><suffix> and then moves it to
# <final>. A run that dies between the two passes leaves the parked name in
# the tree.
#
# Read the two exit codes here as regression pins rather than as new ground. A
# parked name opens with digits and an underscore, so it already trips the
# numbered-stranger sweep and both roots already exit 1. What the script gets
# wrong is the diagnosis. It tells the reader ORDER does not name the
# directory, which sends them to edit ORDER, when what happened is that a run
# died and left its own working name behind.
#
# So one row below pins message text, and it is the only row in this suite
# that does. Two diagnoses that both exit 1 cannot be told apart any other way,
# and which of the two a human reads is the whole value of the ruling.
STRAND_BEFORE=$(snapshot "$ROOT_STRAND")

run_np --check "$ROOT_STRAND"

assert_rc "--check exits 1 on a stranded temp directory" 1

assert_says "--check names the stranded directory" \
  '02_beta\.number-problems-tmp\.31337' "$RUN_ALL"

assert_says "--check calls it stranded residue and not a numbered stranger" \
  '[Ss]tranded temp director' "$RUN_ALL"

assert_unchanged "--check clears none of it away itself" \
  "$ROOT_STRAND" "$STRAND_BEFORE" 1

STRAND_BARE_BEFORE=$(snapshot "$ROOT_STRAND_BARE")

run_np "$ROOT_STRAND_BARE"

assert_rc "a bare run exits 1 on a stranded temp directory" 1

assert_says "the bare run names the stranded directory" \
  '02_beta\.number-problems-tmp\.31337' "$RUN_ALL"

assert_unchanged "the bare run renames nothing around the residue" \
  "$ROOT_STRAND_BARE" "$STRAND_BARE_BEFORE" 1

assert_marker "alpha is still bare, not numbered around the residue" \
  "$ROOT_STRAND_BARE/alpha/MARK" "alpha" 1

# ---------------------------------------------------------------------------
echo
echo "== structural: the suite registration =="
# ---------------------------------------------------------------------------

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-number-problems\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-number-problems.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-number-problems.sh"
fi

echo
if [ "$skip_count" -ne 0 ]; then
  printf "SKIPPED: %d assertions this box cannot run\n" "$skip_count"
fi
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
