#!/usr/bin/env bash
# test-deliver-problems.sh: executable spec for scripts/deliver-problems.sh
# (bead tla-6mrz).
#
# Pins the RED invariant from the bead:
#
#   A freshly delivered problem directory contains exactly the files under that
#   problem's <location>/<name>/statement/, and delivering over an existing
#   directory changes no file already there.
#
# ---------------------------------------------------------------------------
# WHY THIS SUITE EXISTS, AND WHAT IT IS SHAPED AGAINST
#
# On 2026-10-02 central reset the delivered problems to pristine against a
# guessed manifest. It kept PROBLEM.md, ATTEMPT-LOG.md and traces/ and deleted
# everything else, which deleted three SHIPPED files: 01's BondedStore.tla,
# 03's RiverCall.cfg and 04's AssayOffice.tla. It then reported two problems as
# half-attempted when what it was reading was the shipped artifact. The wrong
# manifest cost more as a wrong reading of Frank's progress than as a deletion.
#
# So the one thing this suite has to make impossible is a manifest expressed as
# a list of filenames. The authoritative manifest is the statement/ tree, and
# the tree is not uniform: three of the seven problems ship a starter artifact
# and four do not, because representation 1 on the load vector hands the learner
# a spec and representation 2 makes them write it.
#
# That is why the central fixture carries a PLANTED MUTATION. probe-bonded is a
# byte-for-byte copy of the real authoring/bonded-store/statement tree with
# three files added that no hardcoded list would ever name: SURPRISE.tla,
# extra/nested/DEEP.md, and a PROBLEM-with-author-notes.md. A script carrying
# the guessed manifest delivers the copy and drops all three. A script that
# copies the tree delivers the first two and withholds the third. The two are
# indistinguishable against the real seven problems, which is precisely how the
# original bug survived being looked at.
#
# Three rows exist only to keep that mutation honest, under "the fixture is not
# vacuous". A fixture whose mutation has drifted out of it would let every
# manifest assertion pass against a hardcoded list again, so the mutation is
# itself asserted rather than assumed.
#
# ---------------------------------------------------------------------------
# THE CONTRACT
#
#   scripts/deliver-problems.sh [--check] <name> [dest-root]
#
#   <name> is the bare problem name, never the numbered directory name.
#   <dest-root> defaults to $HOME/tla-practice/problems.
#
#   The source is <repo>/<location>/<name>/statement for exactly one of the
#   three locations authoring/, curated/ and sources/problems/. Zero matches is
#   fatal. Two or more is fatal. DELIVER_PROBLEMS_SRC_ROOT overrides <repo>.
#
#   Everything under statement/ is delivered, recursively, except any file whose
#   basename ends -with-author-notes.md, which is withheld and reported.
#
#   The delivered directory name is printf '%02d_%s' POS name, where POS is the
#   problem's 1-based position in <dest-root>/ORDER. A name ORDER does not carry
#   is off the ramp and delivers under its bare name. ORDER parsing matches
#   scripts/number-problems.sh exactly: blank lines and comment lines consume
#   no position, so a position is not a line number, and a line matching
#   ^[[:space:]]*checkpoint: is a parse error that refuses the run.
#
#   No file is ever overwritten. An existing file is left alone and reported on
#   stdout as "skipped (exists): <path>".
#
#   --check resolves everything and prints what it would deliver, writing
#   nothing.
#
#   Exit 0 on success, including a run that only skipped existing files.
#   Exit 1 on a usage error, an unresolvable or empty source, or a destination
#   that already holds this problem under a different number.
#
# ---------------------------------------------------------------------------
# WHY EVERY RUN IS SANDBOXED TWICE
#
# ~/tla-practice is not a git repo and holds a learner's in-progress work plus a
# pristine reset Frank is about to work from, so a write there does not come
# back. This suite never names that path as a destination and never writes
# under it. Every run passes an explicit dest-root under a fresh mktemp root,
# AND redirects HOME, which is where the default dest-root resolves from.
#
# The default-root section goes further, because a sandboxed HOME does nothing
# for a script that hardcodes a path. That section uses --check, which the
# contract says writes nothing, and it has to name a problem that exists only in
# the sandbox before the section concludes anything. Nothing mutating is ever
# run without a dest-root argument.
#
# The suite does read the real repo tree, once, to deliver the real
# bonded-store into a temp destination and diff it against its own statement/
# directory. That is the same instrument central used to verify the live tree,
# pointed somewhere safe.
#
# ---------------------------------------------------------------------------
# WHAT THE ASSERTIONS ARE SHAPED AROUND
#
# Absence and no-change rows carry the non-vacuity control the two sibling
# suites use. A run that never started leaves the tree exactly as it found it,
# so "nothing changed" only means something once the run it survived exited the
# code the contract promised, and "this file never landed" only means something
# once something else did land.
#
# The expected file set is derived independently of the script, and the
# withheld-file filter is written here with a different mechanism than the one
# the script uses, so a bug in one does not cancel a bug in the other.
#
# Usage:  harness/test-deliver-problems.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="scripts/deliver-problems.sh"
NUMBER_SCRIPT="scripts/number-problems.sh"
TEST_RUNNER="scripts/test"

# The real practice tree, captured before anything is sandboxed. Only used to
# assert that no run ever names it. Nothing in this suite reads or writes under
# it, and no run is ever given it as a destination.
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

TMPROOT=$(mktemp -d -t tla_deliver_problems.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

FIX_REPO="$TMPROOT/repo"
SANDBOX_HOME="$TMPROOT/home"
DEFAULT_ROOT="$SANDBOX_HOME/tla-practice/problems"
ERRFILE="$TMPROOT/stderr.txt"

DEST_MAIN="$TMPROOT/dest-main"       # the happy path, numbered from ORDER
DEST_BARE="$TMPROOT/dest-bare"       # a name ORDER does not carry
DEST_NOORDER="$TMPROOT/dest-noorder" # no ORDER file at all
DEST_KEEP="$TMPROOT/dest-keep"       # pre-seeded, for the never-overwrite rule
DEST_CONFLICT="$TMPROOT/dest-conflict"
DEST_REAL="$TMPROOT/dest-real"       # the real bonded-store, read from the repo
DEST_AGREE="$TMPROOT/dest-agree"     # cross-check against number-problems.sh
DEST_NP="$TMPROOT/dest-np"           # the same ORDER, renamed by the sibling
DEST_REJECT="$TMPROOT/dest-reject"   # never written, the error runs

# The D6 destinations, added by bead tla-5zgr.2. One per retired spelling plus
# one arbitrary tail, because the markers were two separate case arms and the
# invariant is over the pattern rather than over the two literals.
DEST_CP13="$TMPROOT/dest-cp-ch13"
DEST_CPREF="$TMPROOT/dest-cp-refinement"
DEST_CPINDENT="$TMPROOT/dest-cp-indented"

mkdir -p "$SANDBOX_HOME" "$DEFAULT_ROOT"

# ---------------------------------------------------------------------------
# Fixture source tree: all three locations, each with something in it.
# ---------------------------------------------------------------------------

mkdir -p "$FIX_REPO/authoring" "$FIX_REPO/curated" "$FIX_REPO/sources/problems"

# alpha-fixture: the plain representation-2 shape. Statement, log, traces.
mkdir -p "$FIX_REPO/authoring/alpha-fixture/statement/traces"
printf 'alpha problem statement\n' >"$FIX_REPO/authoring/alpha-fixture/statement/PROBLEM.md"
printf 'alpha attempt log\n'       >"$FIX_REPO/authoring/alpha-fixture/statement/ATTEMPT-LOG.md"
printf 'alpha pair 1\n'            >"$FIX_REPO/authoring/alpha-fixture/statement/traces/pair-1.md"
printf 'alpha pair 2\n'            >"$FIX_REPO/authoring/alpha-fixture/statement/traces/pair-2.md"

# Material OUTSIDE statement/ that must never be delivered. This is the other
# half of the manifest: statement/ is authoritative, so its siblings are not.
mkdir -p "$FIX_REPO/authoring/alpha-fixture/reference" \
         "$FIX_REPO/authoring/alpha-fixture/reports" \
         "$FIX_REPO/authoring/alpha-fixture/author-notes"
printf 'the answer\n'        >"$FIX_REPO/authoring/alpha-fixture/reference/Alpha-commented.tla"
printf 'a graded report\n'   >"$FIX_REPO/authoring/alpha-fixture/reports/step5-leakage.md"
printf 'the answer key\n'    >"$FIX_REPO/authoring/alpha-fixture/author-notes/ANSWER-KEY.md"
printf 'the load vector\n'   >"$FIX_REPO/authoring/alpha-fixture/VECTOR.md"

# probe-bonded: THE PLANTED MUTATION. A copy of the real bonded-store statement
# tree, which is a representation-1 problem and so ships BondedStore.tla, plus
# three files the guessed manifest would never name.
mkdir -p "$FIX_REPO/authoring/probe-bonded"
cp -R "authoring/bonded-store/statement" "$FIX_REPO/authoring/probe-bonded/statement"
printf 'a starter no list would name\n' \
  >"$FIX_REPO/authoring/probe-bonded/statement/SURPRISE.tla"
mkdir -p "$FIX_REPO/authoring/probe-bonded/statement/extra/nested"
printf 'two levels down\n' \
  >"$FIX_REPO/authoring/probe-bonded/statement/extra/nested/DEEP.md"
printf 'the author copy, never delivered\n' \
  >"$FIX_REPO/authoring/probe-bonded/statement/PROBLEM-with-author-notes.md"

# gamma-fixture: author notes in authoring/, so the exclusion is not keyed on a
# location either.
mkdir -p "$FIX_REPO/authoring/gamma-fixture/statement"
printf 'gamma problem statement\n' >"$FIX_REPO/authoring/gamma-fixture/statement/PROBLEM.md"
printf 'gamma annotated copy\n' \
  >"$FIX_REPO/authoring/gamma-fixture/statement/PROBLEM-with-author-notes.md"

# delta-fixture: curated/, the majority-vote shape.
mkdir -p "$FIX_REPO/curated/delta-fixture/statement"
printf 'delta problem statement\n' >"$FIX_REPO/curated/delta-fixture/statement/PROBLEM.md"
printf 'delta attempt log\n'       >"$FIX_REPO/curated/delta-fixture/statement/ATTEMPT-LOG.md"
printf 'delta annotated copy\n' \
  >"$FIX_REPO/curated/delta-fixture/statement/PROBLEM-with-author-notes.md"

# epsilon-fixture: sources/problems/, the prose pipeline, with a nested dir.
mkdir -p "$FIX_REPO/sources/problems/epsilon-fixture/statement/notes/deep"
printf 'epsilon problem statement\n' \
  >"$FIX_REPO/sources/problems/epsilon-fixture/statement/PROBLEM.md"
printf 'epsilon deep note\n' \
  >"$FIX_REPO/sources/problems/epsilon-fixture/statement/notes/deep/EXTRA.md"

# zeta-fixture: never in any ORDER, so it is off the ramp.
mkdir -p "$FIX_REPO/authoring/zeta-fixture/statement"
printf 'zeta problem statement\n' >"$FIX_REPO/authoring/zeta-fixture/statement/PROBLEM.md"

# dup-fixture: present in TWO locations, which is the ambiguous case.
mkdir -p "$FIX_REPO/authoring/dup-fixture/statement" \
         "$FIX_REPO/curated/dup-fixture/statement"
printf 'from authoring\n' >"$FIX_REPO/authoring/dup-fixture/statement/PROBLEM.md"
printf 'from curated\n'   >"$FIX_REPO/curated/dup-fixture/statement/PROBLEM.md"

# museum-fixture: the live shape of authoring/museum. A problem directory with
# no statement/ at all, which is a different error from no directory.
mkdir -p "$FIX_REPO/authoring/museum-fixture"
printf 'just a description\n' >"$FIX_REPO/authoring/museum-fixture/DESCRIPTION.md"

# empty-fixture: statement/ exists and is empty. Nothing to deliver.
mkdir -p "$FIX_REPO/authoring/empty-fixture/statement"

# notesonly-fixture: statement/ holds only withheld material, so after the
# exclusion there is still nothing to deliver.
mkdir -p "$FIX_REPO/authoring/notesonly-fixture/statement"
printf 'only the author copy\n' \
  >"$FIX_REPO/authoring/notesonly-fixture/statement/PROBLEM-with-author-notes.md"

# ---------------------------------------------------------------------------
# ORDER files.
#
# DEST_MAIN's ORDER carries every shape the parser has to skip, so no entry sits
# on the line number matching its position. A script that read the line number
# instead of the position would number alpha-fixture 3 and probe-bonded 5.
#
# D6, bead tla-5zgr.2: the two `checkpoint:` markers used to hold lines 4 and 7
# here. They are gone, and a comment and a blank hold those two lines instead,
# which keeps every (position, raw line) pair below exactly as it was:
#
#   line 3 -> position 1, line 5 -> 2, line 6 -> 3, line 8 -> 4, line 9 -> 5.
#
# The pairs are what the position rows assert against, and they were never
# about the markers. A skipped line is a skipped line, and the two that remain
# skip just as well as the two that went.
# ---------------------------------------------------------------------------

write_main_order() {
  local root="$1"
  mkdir -p "$root"
  {
    printf '# the ramp, with shapes the parser has to skip\n'
    printf '\n'
    printf 'alpha-fixture\n'
    printf '# a comment between two entries\n'
    printf 'probe-bonded\n'
    printf '   gamma-fixture\n'
    printf '\n'
    printf 'delta-fixture\n'
    printf 'epsilon-fixture\n'
  } >"$root/ORDER"
}

write_main_order "$DEST_MAIN"
write_main_order "$DEST_KEEP"
write_main_order "$DEST_CONFLICT"
write_main_order "$DEST_AGREE"
write_main_order "$DEST_NP"

mkdir -p "$DEST_BARE"
printf 'alpha-fixture\n' >"$DEST_BARE/ORDER"

# --- D6: destinations whose ORDER still carries a retired marker ------------
#
# alpha-fixture is named by each of these ORDERs, so the run has real work to
# do and refuses anyway. A refusal against a destination that had nothing to
# deliver would prove only that there was nothing to deliver.
mkdir -p "$DEST_CP13"
{
  printf 'alpha-fixture\n'
  printf 'checkpoint: ch13\n'
  printf 'probe-bonded\n'
} >"$DEST_CP13/ORDER"

mkdir -p "$DEST_CPREF"
{
  printf 'alpha-fixture\n'
  printf 'checkpoint: refinement\n'
  printf 'probe-bonded\n'
} >"$DEST_CPREF/ORDER"

mkdir -p "$DEST_CPINDENT"
{
  printf 'alpha-fixture\n'
  printf '  checkpoint: anything-at-all\n'
  printf 'probe-bonded\n'
} >"$DEST_CPINDENT/ORDER"

mkdir -p "$DEST_NOORDER"

# The sandboxed default root. omega-sandbox-only exists in this ORDER and in no
# other fixture and in no real tree, so seeing it come back is the evidence that
# the sandbox is the root being read.
printf 'alpha-fixture\nomega-sandbox-only\n' >"$DEFAULT_ROOT/ORDER"

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

RUN_OUT=""
RUN_ERR=""
RUN_RC=0

# run_deliver [args...]
#
# HOME is redirected on every run, and every caller below also passes an
# explicit dest-root, so a script that drops its argument still writes into the
# sandbox rather than into Frank's practice tree.
run_deliver() {
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_PROBLEMS_SRC_ROOT="$FIX_REPO" \
    bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_deliver_realrepo [args...]
#
# The one runner that reads the real repo as its source, for the probe that
# reproduces central's live verification. The destination is still a temp dir.
run_deliver_realrepo() {
  RUN_OUT=$(HOME="$SANDBOX_HOME" bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# relfiles <dir>
#
# Every file under a directory, as a sorted list of paths relative to it.
relfiles() {
  local dir="$1"
  [ -d "$dir" ] || { printf '<absent>\n'; return; }
  (cd "$dir" && find . -type f | LC_ALL=C sort)
}

# deliverable_relfiles <statement-dir>
#
# The expected manifest, derived from the tree and nothing else.
#
# The withheld-file filter is find's -name here, against a case statement on the
# basename in the script. Two mechanisms on purpose: if both were the same code
# a bug in it would cancel itself out and this suite would certify it.
deliverable_relfiles() {
  local dir="$1"
  [ -d "$dir" ] || { printf '<absent>\n'; return; }
  (cd "$dir" && find . -type f ! -name '*-with-author-notes.md' | LC_ALL=C sort)
}

# snapshot <dir>
#
# Names and contents, for the "changed nothing" rows.
snapshot() {
  local root="$1"
  [ -d "$root" ] || { printf '<absent>\n'; return; }
  (cd "$root" && find . -mindepth 1 | LC_ALL=C sort)
  (cd "$root" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s :: %s\n' "$f" "$(cat "$f")"
  done)
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
# Exact, never "non-zero". A missing script exits 127 and 127 satisfies every
# non-zero test in the file.
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
# reports a present pattern as absent (bead tla-kr9). harness/test-pipefail.sh
# bans the pipe forms across this tree.
assert_says() {
  local label="$1" pattern="$2" body="$3"
  if grep -qE -- "$pattern" <<<"$body"; then
    ok "$label"
  else
    nope "$label. No line matched: $pattern"
  fi
}

# assert_never_names <label> <literal-string> <captured-text>
#
# Fixed-string, because the thing being looked for is a filesystem path and a
# path read as a regex matches more than itself.
assert_never_names() {
  local label="$1" needle="$2" body="$3"
  if grep -qF -- "$needle" <<<"$body"; then
    nope "$label. The output named it: $needle"
  else
    ok "$label"
  fi
}

# assert_manifest <label> <statement-dir> <delivered-dir>
#
# The head of the invariant. The delivered set has to equal the deliverable set
# under statement/, exactly, both ways.
#
# The non-vacuity control is the emptiness check. A script that delivered
# nothing would otherwise compare <absent> against <absent> for a source tree
# that was itself missing, and a source tree that is really empty is covered by
# its own fatal row below.
assert_manifest() {
  local label="$1" src="$2" dest="$3" want got
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The delivery failed (rc=$RUN_RC), so the manifest proves nothing"
    return
  fi
  want=$(deliverable_relfiles "$src")
  got=$(relfiles "$dest")
  if [ -z "$want" ] || [ "$want" = "<absent>" ]; then
    nope "$label. The fixture source has no deliverable files, so the comparison is vacuous: $src"
  elif [ "$got" = "<absent>" ]; then
    nope "$label. Nothing landed at all: $dest"
  elif [ "$want" = "$got" ]; then
    ok "$label"
  else
    nope "$label. Wanted [$(tr '\n' ' ' <<<"$want")] got [$(tr '\n' ' ' <<<"$got")]"
  fi
}

# assert_identical <label> <statement-dir> <delivered-dir>
#
# Stronger than the set comparison and deliberately redundant with it: diff -r
# catches a file delivered under the right name with the wrong bytes. This is
# the exact instrument central used on the live tree.
assert_identical() {
  local label="$1" src="$2" dest="$3" out
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The delivery failed (rc=$RUN_RC), so the comparison proves nothing"
    return
  fi
  if [ ! -d "$dest" ]; then
    nope "$label. Nothing landed at all: $dest"
    return
  fi
  out=$(diff -r "$src" "$dest" 2>&1)
  if [ -z "$out" ]; then
    ok "$label"
  else
    nope "$label. diff -r reported: $(tr '\n' ' ' <<<"$out")"
  fi
}

# assert_delivered <label> <dir> <relative-path> <expected-content>
assert_delivered() {
  local label="$1" dir="$2" rel="$3" want="$4" got
  if [ ! -f "$dir/$rel" ]; then
    nope "$label. Not delivered: $dir/$rel"
    return
  fi
  got=$(cat "$dir/$rel")
  if [ "$got" = "$want" ]; then
    ok "$label"
  else
    nope "$label. Wanted '$want', got '$got'"
  fi
}

# assert_not_delivered <label> <dir> <relative-path>
#
# The non-vacuity control. A script that delivered nothing satisfies every
# absence check trivially, so require the directory first.
assert_not_delivered() {
  local label="$1" dir="$2" rel="$3"
  if [ ! -d "$dir" ]; then
    nope "$label. Nothing landed at all ($dir absent), so the absence proves nothing"
  elif [ -e "$dir/$rel" ]; then
    nope "$label. Present: $dir/$rel"
  else
    ok "$label"
  fi
}

# assert_bytes <label> <path> <keeper>
#
# cmp rather than a string compare, because "survives byte for byte" is the
# claim and $(cat) drops trailing newlines on both sides. The rc guard is the
# same control: a run that never started left the file alone for the wrong
# reason.
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

# assert_unchanged <label> <root> <before> <rc-that-had-to-hold>
assert_unchanged() {
  local label="$1" root="$2" before="$3" want_rc="$4" after
  if [ "$RUN_RC" -ne "$want_rc" ]; then
    nope "$label. The run exited $RUN_RC, wanted $want_rc, so no-change proves nothing"
    return
  fi
  after=$(snapshot "$root")
  if [ "$before" = "$after" ]; then
    ok "$label"
  else
    nope "$label. The tree changed under $root"
  fi
}

# assert_rejects <label> [args...]
#
# Both halves of the argument contract in one row: exit 1 AND usage on stderr.
assert_rejects() {
  local label="$1"
  shift
  if [ "$SCRIPT_PRESENT" -eq 0 ]; then
    nope "$label. $SCRIPT does not exist, so a non-zero exit proves nothing"
    return
  fi
  run_deliver "$@"
  if [ "$RUN_RC" -ne 1 ]; then
    nope "$label. Exited $RUN_RC, wanted 1"
  elif ! grep -qE -- '[Uu]sage' <<<"$RUN_ERR"; then
    nope "$label. Exited 1 but printed no usage on stderr: $(tr '\n' ' ' <<<"$RUN_ERR")"
  else
    ok "$label"
  fi
}

# assert_source_error <label> <stderr-regex> [args...]
#
# Exit 1 and a message that says which of the source failures it was. The
# message matters: "no such problem" and "this problem has no statement/" send a
# reader to different places.
assert_source_error() {
  local label="$1" pattern="$2"
  shift 2
  if [ "$SCRIPT_PRESENT" -eq 0 ]; then
    nope "$label. $SCRIPT does not exist, so a non-zero exit proves nothing"
    return
  fi
  run_deliver "$@"
  if [ "$RUN_RC" -ne 1 ]; then
    nope "$label. Exited $RUN_RC, wanted 1"
  elif ! grep -qE -- "$pattern" <<<"$RUN_ERR"; then
    nope "$label. Exited 1 but stderr matched no $pattern: $(tr '\n' ' ' <<<"$RUN_ERR")"
  else
    ok "$label"
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

if [ -x "$SCRIPT" ]; then
  ok "$SCRIPT is executable"
else
  nope "$SCRIPT is not executable"
fi

# ---------------------------------------------------------------------------
echo
echo "== the fixture is not vacuous =="
# ---------------------------------------------------------------------------

# These three rows assert the planted mutation rather than assuming it. Without
# them a fixture that had quietly lost its mutation would let every manifest row
# below pass against a hardcoded list of filenames, which is the bug.

PROBE_SRC="$FIX_REPO/authoring/probe-bonded/statement"

if [ -f "$PROBE_SRC/SURPRISE.tla" ]; then
  ok "the probe fixture carries a planted file no hardcoded list would name"
else
  nope "the probe fixture lost its planted SURPRISE.tla, so the manifest rows below are vacuous"
fi

if [ -f "$PROBE_SRC/extra/nested/DEEP.md" ]; then
  ok "the probe fixture carries a planted file two directories down"
else
  nope "the probe fixture lost its planted extra/nested/DEEP.md"
fi

if [ -f "$PROBE_SRC/PROBLEM-with-author-notes.md" ]; then
  ok "the probe fixture carries a planted author-notes file to withhold"
else
  nope "the probe fixture lost its planted PROBLEM-with-author-notes.md"
fi

# And the planted file is genuinely outside the shape the guessed manifest
# assumed, which is what makes it discriminating.
if [ "$(basename "$PROBE_SRC/SURPRISE.tla")" = "PROBLEM.md" ] ||
   [ "$(basename "$PROBE_SRC/SURPRISE.tla")" = "ATTEMPT-LOG.md" ]; then
  nope "the planted file is one of the names the guessed manifest kept, so it discriminates nothing"
else
  ok "the planted file is outside PROBLEM.md / ATTEMPT-LOG.md / traces/"
fi

# The real tree the probe is a copy of ships a .tla, which is the asymmetry the
# guessed manifest deleted. If this ever stops holding the bead's premise moved.
if [ -f "authoring/bonded-store/statement/BondedStore.tla" ]; then
  ok "the real bonded-store statement/ still ships BondedStore.tla"
else
  nope "authoring/bonded-store/statement/BondedStore.tla is gone, so this suite's premise has moved"
fi

# ---------------------------------------------------------------------------
echo
echo "== the manifest comes from the tree, not from a list =="
# ---------------------------------------------------------------------------

run_deliver probe-bonded "$DEST_MAIN"

assert_rc0 "delivering the probe fixture exits 0"

# probe-bonded is ORDER entry 2, on raw line 5.
PROBE_DEST="$DEST_MAIN/02_probe-bonded"

assert_manifest "the delivered set equals statement/ minus the author notes" \
  "$PROBE_SRC" "$PROBE_DEST"

assert_delivered "the planted SURPRISE.tla lands" \
  "$PROBE_DEST" "SURPRISE.tla" "a starter no list would name"

assert_delivered "the planted file two directories down lands" \
  "$PROBE_DEST" "extra/nested/DEEP.md" "two levels down"

assert_delivered "the representation-1 starter lands" \
  "$PROBE_DEST" "BondedStore.tla" \
  "$(cat authoring/bonded-store/statement/BondedStore.tla)"

assert_delivered "traces/ lands recursively" \
  "$PROBE_DEST" "traces/pair-5.md" \
  "$(cat authoring/bonded-store/statement/traces/pair-5.md)"

assert_not_delivered "the author-notes copy never lands" \
  "$PROBE_DEST" "PROBLEM-with-author-notes.md"

assert_says "the withheld author-notes file is reported" \
  'withheld.*PROBLEM-with-author-notes\.md' "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== statement/ is the whole manifest, and its siblings are not =="
# ---------------------------------------------------------------------------

run_deliver alpha-fixture "$DEST_MAIN"

assert_rc0 "delivering alpha-fixture exits 0"

ALPHA_DEST="$DEST_MAIN/01_alpha-fixture"
ALPHA_SRC="$FIX_REPO/authoring/alpha-fixture/statement"

assert_manifest "alpha-fixture delivers exactly its statement/ tree" \
  "$ALPHA_SRC" "$ALPHA_DEST"

assert_identical "alpha-fixture's delivery diffs clean against statement/" \
  "$ALPHA_SRC" "$ALPHA_DEST"

assert_not_delivered "reference/ never lands"    "$ALPHA_DEST" "reference"
assert_not_delivered "reports/ never lands"      "$ALPHA_DEST" "reports"
assert_not_delivered "author-notes/ never lands" "$ALPHA_DEST" "author-notes"
assert_not_delivered "VECTOR.md never lands"     "$ALPHA_DEST" "VECTOR.md"

# ---------------------------------------------------------------------------
echo
echo "== all three source locations resolve =="
# ---------------------------------------------------------------------------

run_deliver gamma-fixture "$DEST_MAIN"
assert_rc0 "authoring/ resolves"
assert_manifest "gamma-fixture from authoring/ delivers its tree" \
  "$FIX_REPO/authoring/gamma-fixture/statement" "$DEST_MAIN/03_gamma-fixture"

run_deliver delta-fixture "$DEST_MAIN"
assert_rc0 "curated/ resolves"
assert_manifest "delta-fixture from curated/ delivers its tree" \
  "$FIX_REPO/curated/delta-fixture/statement" "$DEST_MAIN/04_delta-fixture"

run_deliver epsilon-fixture "$DEST_MAIN"
assert_rc0 "sources/problems/ resolves"
assert_manifest "epsilon-fixture from sources/problems/ delivers its tree" \
  "$FIX_REPO/sources/problems/epsilon-fixture/statement" \
  "$DEST_MAIN/05_epsilon-fixture"

assert_delivered "a nested directory from sources/problems/ lands" \
  "$DEST_MAIN/05_epsilon-fixture" "notes/deep/EXTRA.md" "epsilon deep note"

# ---------------------------------------------------------------------------
echo
echo "== the author-notes exclusion is a convention, not a list =="
# ---------------------------------------------------------------------------

# Three different locations, three different problem names, one rule. A
# per-problem exclusion list keyed on the names the bead happened to mention
# would ship two of these three.

assert_not_delivered "gamma-fixture's author notes are withheld from authoring/" \
  "$DEST_MAIN/03_gamma-fixture" "PROBLEM-with-author-notes.md"

assert_not_delivered "delta-fixture's author notes are withheld from curated/" \
  "$DEST_MAIN/04_delta-fixture" "PROBLEM-with-author-notes.md"

assert_delivered "the ordinary PROBLEM.md still lands beside the withheld copy" \
  "$DEST_MAIN/03_gamma-fixture" "PROBLEM.md" "gamma problem statement"

# ---------------------------------------------------------------------------
echo
echo "== the delivered name carries its ORDER position =="
# ---------------------------------------------------------------------------

# Every directory above was asserted at its numbered path, so this section reads
# the result of those runs rather than re-delivering. The point of each row is
# the arithmetic: no entry's position equals its line number in ORDER.

for pair in "01_alpha-fixture:3" "02_probe-bonded:5" "03_gamma-fixture:6" \
            "04_delta-fixture:8" "05_epsilon-fixture:9"; do
  dirname_want="${pair%%:*}"
  rawline="${pair##*:}"
  if [ -d "$DEST_MAIN/$dirname_want" ]; then
    ok "$dirname_want is numbered by ORDER position, not by its line number ($rawline)"
  else
    nope "$dirname_want does not exist, so the position was not derived from ORDER"
  fi
done

# And nothing landed under the line-number spelling, which is the mistake this
# section exists to rule out.
assert_not_delivered "no directory landed under alpha-fixture's line number" \
  "$DEST_MAIN" "03_alpha-fixture"

assert_not_delivered "no directory landed under probe-bonded's line number" \
  "$DEST_MAIN" "05_probe-bonded"

assert_not_delivered "the bare name is not used for a problem ORDER carries" \
  "$DEST_MAIN" "alpha-fixture"

# ---------------------------------------------------------------------------
echo
echo "== a problem ORDER does not carry is off the ramp =="
# ---------------------------------------------------------------------------

run_deliver zeta-fixture "$DEST_BARE"

assert_rc0 "an unnumbered problem delivers and exits 0"

assert_manifest "an off-ramp problem delivers its tree under its bare name" \
  "$FIX_REPO/authoring/zeta-fixture/statement" "$DEST_BARE/zeta-fixture"

assert_not_delivered "an off-ramp problem gets no number" \
  "$DEST_BARE" "01_zeta-fixture"

# A missing ORDER is the degenerate case of the same thing. It is reported,
# because a missing ORDER is more often a mistyped dest-root than a deliberate
# state, and it is not fatal, because an unnumbered directory is a legal state
# that scripts/number-problems.sh fixes the moment ORDER grows the entry.
run_deliver zeta-fixture "$DEST_NOORDER"

assert_rc0 "a destination with no ORDER still delivers"

assert_manifest "a destination with no ORDER delivers under the bare name" \
  "$FIX_REPO/authoring/zeta-fixture/statement" "$DEST_NOORDER/zeta-fixture"

assert_says "a missing ORDER is reported on stderr" \
  'ORDER' "$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== the position agrees with scripts/number-problems.sh =="
# ---------------------------------------------------------------------------

# The ORDER parse is duplicated from scripts/number-problems.sh, which owns the
# convention. This section is what keeps the duplicate from drifting: it hands
# the same ORDER to both scripts and requires the same names out. If the sibling
# changes how it skips a comment or a blank, or how it pads a number, this goes
# red.
#
# The agreement is the reason the two scripts can carry a duplicated parse at
# all, so D6 narrows what the shared ORDER contains and leaves this gate
# exactly where it was. The refusal half gets its own section below, and it is
# checked against both scripts for the same reason: a refusal in one and a skip
# in the other is the drift this section exists to catch.

if [ ! -f "$NUMBER_SCRIPT" ]; then
  nope "the ORDER convention agrees with $NUMBER_SCRIPT. The sibling script is missing"
else
  # Deliver all five under the shared ORDER.
  AGREE_RC=0
  for n in alpha-fixture probe-bonded gamma-fixture delta-fixture epsilon-fixture; do
    run_deliver "$n" "$DEST_AGREE"
    [ "$RUN_RC" -eq 0 ] || AGREE_RC=1
  done

  # Build the same tree under bare names and let the sibling number it.
  for n in alpha-fixture probe-bonded gamma-fixture delta-fixture epsilon-fixture; do
    mkdir -p "$DEST_NP/$n"
    printf 'placeholder\n' >"$DEST_NP/$n/MARK"
  done
  NP_ERR=$(HOME="$SANDBOX_HOME" bash "$NUMBER_SCRIPT" "$DEST_NP" 2>&1)
  NP_RC=$?

  AGREE_NAMES=$(cd "$DEST_AGREE" && find . -mindepth 1 -maxdepth 1 -type d \
    -printf '%f\n' | LC_ALL=C sort)
  NP_NAMES=$(cd "$DEST_NP" && find . -mindepth 1 -maxdepth 1 -type d \
    -printf '%f\n' | LC_ALL=C sort)

  if [ "$AGREE_RC" -ne 0 ]; then
    nope "the ORDER convention agrees with $NUMBER_SCRIPT. A delivery failed, so the comparison proves nothing"
  elif [ "$NP_RC" -ne 0 ]; then
    nope "the ORDER convention agrees with $NUMBER_SCRIPT. The sibling exited $NP_RC: $(tr '\n' ' ' <<<"$NP_ERR")"
  elif [ -z "$NP_NAMES" ]; then
    nope "the ORDER convention agrees with $NUMBER_SCRIPT. The sibling produced no directories, so the comparison is vacuous"
  elif [ "$AGREE_NAMES" = "$NP_NAMES" ]; then
    ok "the ORDER convention agrees with $NUMBER_SCRIPT over comments and blanks"
  else
    nope "the ORDER convention disagrees with $NUMBER_SCRIPT. deliver=[$(tr '\n' ' ' <<<"$AGREE_NAMES")] number=[$(tr '\n' ' ' <<<"$NP_NAMES")]"
  fi
fi

# ---------------------------------------------------------------------------
echo
echo "== D6: a checkpoint: line in ORDER refuses the delivery =="
# ---------------------------------------------------------------------------

# The RED invariant from bead tla-5zgr.2, this script's half. The two
# positional markers stopped existing when the reading gate became a label, so
# a destination ORDER still carrying one is stale rather than merely verbose.
#
# Exit 1, because that is the only failure code this script has. Its sibling
# uses 2 for the same refusal, since that script separates "the input is
# unusable" from "ORDER and the tree disagree" and this one does not. The two
# codes differ and the two refusals do not, which is the part that matters:
# neither script numbers a position out of an ORDER it cannot parse.
#
# Nothing delivered is asserted alongside every refusal. ~/tla-practice is not
# a git repo, so a run that writes half a problem into a destination it then
# refuses has left a tree nobody can reason about.

run_deliver alpha-fixture "$DEST_CP13"

assert_rc "a destination ORDER carrying checkpoint: ch13 exits 1" 1

assert_says "the refusal names the offending line" \
  'checkpoint: ch13' "$RUN_ERR"

assert_not_delivered "nothing lands under the numbered name on a stale ORDER" \
  "$DEST_CP13" "01_alpha-fixture"

assert_not_delivered "nothing lands under the bare name either" \
  "$DEST_CP13" "alpha-fixture"

run_deliver --check alpha-fixture "$DEST_CP13"

assert_rc "--check exits 1 on the same ORDER" 1

run_deliver alpha-fixture "$DEST_CPREF"

assert_rc "a destination ORDER carrying checkpoint: refinement exits 1" 1

assert_says "the refusal names the refinement line too" \
  'checkpoint: refinement' "$RUN_ERR"

assert_not_delivered "the refinement marker delivers nothing" \
  "$DEST_CPREF" "01_alpha-fixture"

# The generalisation row, for the same reason as in the sibling suite: a script
# that swapped two equality tests for two inequality tests passes every row
# above and fails this one.
run_deliver alpha-fixture "$DEST_CPINDENT"

assert_rc "an indented checkpoint: line with an unknown tail exits 1" 1

assert_says "the refusal names the unknown-tail line" \
  'checkpoint: anything-at-all' "$RUN_ERR"

assert_not_delivered "an unknown checkpoint: tail delivers nothing" \
  "$DEST_CPINDENT" "01_alpha-fixture"

# The row that rules out the quiet wrong answer, and it is the worst case in
# this suite.
#
# Dropping the two case arms and nothing else makes the marker an ORDER ENTRY
# rather than a skipped line, and in THIS script that failure is silent. The
# marker takes position 2, so probe-bonded is pushed to 3 and the run exits 0
# having delivered it under 03_probe-bonded. Its sibling at least reports
# something, because it goes looking for a directory named after the marker and
# cannot find one. Here there is nothing to report: a position was computed
# from a line nobody can parse and the delivery succeeded.
#
# So exit 0 is the shape to rule out, and the numbered name it would have used
# is ruled out beside it.
run_deliver probe-bonded "$DEST_CP13"

if [ "$RUN_RC" -eq 0 ]; then
  nope "a stale marker is refused rather than silently consuming a position. The run exited 0, so probe-bonded was numbered out of an ORDER nobody could parse"
else
  ok "a stale marker is refused rather than silently consuming a position"
fi

assert_not_delivered "probe-bonded does not land at the marker-shifted position" \
  "$DEST_CP13" "03_probe-bonded"

# ---------------------------------------------------------------------------
echo
echo "== nothing in the destination is ever overwritten =="
# ---------------------------------------------------------------------------

# ~/tla-practice is not a git repo and holds the only copy of a learner's work,
# so a re-run that clobbers it destroys work that does not come back. Pre-seed
# three files with content no source would produce and require them back byte
# for byte.

mkdir -p "$DEST_KEEP/01_alpha-fixture/traces"
printf 'my own answer, please do not clobber\n' \
  >"$DEST_KEEP/01_alpha-fixture/PROBLEM.md"
cp "$DEST_KEEP/01_alpha-fixture/PROBLEM.md" "$TMPROOT/keeper-problem.md"
printf 'my working notes on pair 1\n' \
  >"$DEST_KEEP/01_alpha-fixture/traces/pair-1.md"
cp "$DEST_KEEP/01_alpha-fixture/traces/pair-1.md" "$TMPROOT/keeper-trace.md"

run_deliver alpha-fixture "$DEST_KEEP"

assert_rc0 "a run over a pre-seeded directory still exits 0"

assert_bytes "a pre-seeded PROBLEM.md survives byte for byte" \
  "$DEST_KEEP/01_alpha-fixture/PROBLEM.md" "$TMPROOT/keeper-problem.md"

assert_bytes "a pre-seeded file inside traces/ survives byte for byte" \
  "$DEST_KEEP/01_alpha-fixture/traces/pair-1.md" "$TMPROOT/keeper-trace.md"

assert_says "the skipped PROBLEM.md is reported on stdout" \
  '^[[:space:]]*skipped \(exists\): .*01_alpha-fixture/PROBLEM\.md$' "$RUN_OUT"

assert_says "the skipped trace is reported on stdout" \
  '^[[:space:]]*skipped \(exists\): .*01_alpha-fixture/traces/pair-1\.md$' "$RUN_OUT"

# A skipped file must not hold back its untouched siblings, which is why the
# rule lives per-file rather than per-directory.
assert_delivered "an untouched sibling still lands beside the skipped files" \
  "$DEST_KEEP/01_alpha-fixture" "traces/pair-2.md" "alpha pair 2"

assert_delivered "ATTEMPT-LOG.md lands beside the skipped files" \
  "$DEST_KEEP/01_alpha-fixture" "ATTEMPT-LOG.md" "alpha attempt log"

# Now the shape of a real second run: the destination is already full. Edit two
# of the files the first run delivered and go round again.
printf 'my answer in progress\n' >"$DEST_KEEP/01_alpha-fixture/ATTEMPT-LOG.md"
cp "$DEST_KEEP/01_alpha-fixture/ATTEMPT-LOG.md" "$TMPROOT/keeper-log.md"
printf 'my second trace\n' >"$DEST_KEEP/01_alpha-fixture/traces/pair-2.md"
cp "$DEST_KEEP/01_alpha-fixture/traces/pair-2.md" "$TMPROOT/keeper-trace2.md"

KEEP_BEFORE=$(snapshot "$DEST_KEEP")

run_deliver alpha-fixture "$DEST_KEEP"

assert_rc0 "a second run over a full destination still exits 0"

assert_bytes "a hand-edited ATTEMPT-LOG.md survives the second run" \
  "$DEST_KEEP/01_alpha-fixture/ATTEMPT-LOG.md" "$TMPROOT/keeper-log.md"

assert_bytes "a hand-edited trace survives the second run" \
  "$DEST_KEEP/01_alpha-fixture/traces/pair-2.md" "$TMPROOT/keeper-trace2.md"

# The tail of the invariant, stated whole: a second delivery over a full
# destination changes no file at all.
assert_unchanged "a second run over a full destination changes nothing" \
  "$DEST_KEEP" "$KEEP_BEFORE" 0

# ---------------------------------------------------------------------------
echo
echo "== a destination already holding this problem elsewhere is refused =="
# ---------------------------------------------------------------------------

# alpha-fixture is ORDER entry 1, so it wants 01_alpha-fixture. A directory
# called 09_alpha-fixture is the same problem under a stale number, and
# delivering alongside it makes two directories for one ORDER entry, which is
# the "ambiguous" error scripts/number-problems.sh then reports forever. Refuse
# and send the reader to the script that renumbers.
mkdir -p "$DEST_CONFLICT/09_alpha-fixture"
printf 'work under the old number\n' >"$DEST_CONFLICT/09_alpha-fixture/PROBLEM.md"

CONFLICT_BEFORE=$(snapshot "$DEST_CONFLICT")

run_deliver alpha-fixture "$DEST_CONFLICT"

assert_rc "a stale numbered directory for the same problem is refused" 1

assert_unchanged "the refused run changes nothing" \
  "$DEST_CONFLICT" "$CONFLICT_BEFORE" 1

assert_says "the refusal names the directory it found" \
  '09_alpha-fixture' "$RUN_ERR"

assert_says "the refusal points at number-problems.sh" \
  'number-problems' "$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== --check resolves everything and writes nothing =="
# ---------------------------------------------------------------------------

CHECK_ROOT="$TMPROOT/dest-check"
write_main_order "$CHECK_ROOT"
CHECK_BEFORE=$(snapshot "$CHECK_ROOT")

run_deliver --check alpha-fixture "$CHECK_ROOT"

assert_rc0 "--check exits 0"

assert_unchanged "--check writes nothing" "$CHECK_ROOT" "$CHECK_BEFORE" 0

assert_says "--check names the numbered destination it would use" \
  '01_alpha-fixture' "$RUN_OUT"

assert_says "--check names a file it would deliver" \
  'ATTEMPT-LOG\.md' "$RUN_OUT"

assert_says "--check names the file it would withhold" \
  'withheld' "$(HOME="$SANDBOX_HOME" DELIVER_PROBLEMS_SRC_ROOT="$FIX_REPO" \
    bash "$SCRIPT" --check gamma-fixture "$CHECK_ROOT" 2>/dev/null)"

# ---------------------------------------------------------------------------
echo
echo "== an unresolvable or empty source is fatal, and says which =="
# ---------------------------------------------------------------------------

assert_source_error "a name in no location at all is fatal" \
  'no such problem|not found' nosuchproblem "$DEST_REJECT"

assert_source_error "a name in two locations is fatal" \
  'ambiguous|two|multiple|more than one' dup-fixture "$DEST_REJECT"

assert_source_error "the ambiguous error names both locations" \
  'authoring' dup-fixture "$DEST_REJECT"

assert_source_error "a problem directory with no statement/ is fatal" \
  'statement' museum-fixture "$DEST_REJECT"

assert_source_error "an empty statement/ is fatal" \
  'empty|nothing to deliver' empty-fixture "$DEST_REJECT"

assert_source_error "a statement/ holding only author notes is fatal" \
  'empty|nothing to deliver|withheld' notesonly-fixture "$DEST_REJECT"

# None of the six fatal runs may leave a directory behind. The source is
# resolved before the destination is created, which is also what makes the
# default-root probe below safe.
if [ -e "$DEST_REJECT" ]; then
  nope "a fatal run created its destination anyway: $DEST_REJECT"
else
  ok "a fatal run creates no destination directory"
fi

# ---------------------------------------------------------------------------
echo
echo "== a bad argument is refused with usage =="
# ---------------------------------------------------------------------------

assert_rejects "no problem name at all"

assert_rejects "an unknown option" --wat alpha-fixture "$DEST_REJECT"

assert_rejects "a third positional argument" \
  alpha-fixture "$DEST_REJECT" extra

# A numbered directory name is not a problem name. Passing 01_alpha-fixture
# would otherwise deliver 01_01_alpha-fixture into an off-ramp directory.
assert_source_error "a numbered directory name is not a problem name" \
  'no such problem|not found' 01_alpha-fixture "$DEST_REJECT"

# ---------------------------------------------------------------------------
echo
echo "== the real repo reproduces the live manifest =="
# ---------------------------------------------------------------------------

# Reads the real repo as its source and writes into a temp destination, so this
# is central's live verification pointed somewhere safe:
#
#   diff -r authoring/bonded-store/statement ~/tla-practice/problems/01_bonded-store
#
# bonded-store is not in this destination's ORDER, so it lands under its bare
# name. What is being checked here is the manifest, not the number.
mkdir -p "$DEST_REAL"

run_deliver_realrepo bonded-store "$DEST_REAL"

assert_rc0 "the real bonded-store delivers from the repo tree"

assert_identical "the real bonded-store delivery diffs clean against statement/" \
  "authoring/bonded-store/statement" "$DEST_REAL/bonded-store"

assert_delivered "the real delivery carries BondedStore.tla, the file central deleted" \
  "$DEST_REAL/bonded-store" "BondedStore.tla" \
  "$(cat authoring/bonded-store/statement/BondedStore.tla)"

# ---------------------------------------------------------------------------
echo
echo "== the default root, against a sandboxed HOME =="
# ---------------------------------------------------------------------------

# A sandboxed HOME protects a script that resolves its default from HOME. It
# does nothing for one that hardcodes a path, and that script would write into
# Frank's live tree the moment this section ran. So this section runs ONLY
# --check, which the contract says writes nothing, and it asks for a problem
# whose ORDER entry exists in the sandbox and nowhere else.
#
# omega-sandbox-only is ORDER entry 2 in the sandbox. It has no source, so the
# run is fatal before anything is created either way. What the run has to prove
# is which ORDER file it read, and the stderr naming the sandbox path is that.
DEFAULT_BEFORE=$(snapshot "$DEFAULT_ROOT")

run_deliver --check alpha-fixture

assert_rc0 "--check with no dest-root argument exits 0"

assert_says "--check with no dest-root reads the sandboxed default root" \
  "$DEFAULT_ROOT" "$RUN_OUT"

assert_unchanged "--check with no dest-root writes nothing" \
  "$DEFAULT_ROOT" "$DEFAULT_BEFORE" 0

# The sandbox root ends in tla-practice/problems too, so the check has to name
# the REAL path rather than the shape of it. An earlier draft matched
# 'tla-practice/problems/0[0-9]_' and fired on the sandbox's own
# 01_alpha-fixture, which is a true report of the wrong thing.
assert_never_names "--check with no dest-root never names the real practice tree" \
  "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== structural: the script documents itself, and the suite is registered =="
# ---------------------------------------------------------------------------

# The bead asks for the exercises script's posture, which is that the file says
# what it delivers and what it withholds. A delivery script whose manifest lives
# only in its code is how this bug happened, so the prose is part of the
# contract rather than a courtesy.
if [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "the script states what it withholds. $SCRIPT does not exist"
  nope "the script states the never-overwrite rule. $SCRIPT does not exist"
else
  SCRIPT_HEAD=$(sed -n '1,80p' "$SCRIPT")
  assert_says "the script states what it withholds" \
    '[Ww]ithhold|NEVER DELIVER|never delivers' "$SCRIPT_HEAD"
  assert_says "the script states the never-overwrite rule" \
    'NEVER OVERWRITE|never overwrit' "$SCRIPT_HEAD"
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it. Gate, don't
# advise: a suite nobody registered is a check nobody runs.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-deliver-problems\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-deliver-problems.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-deliver-problems.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
