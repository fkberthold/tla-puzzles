#!/usr/bin/env bash
# test-deliver-completion.sh: executable spec for scripts/deliver-completion.sh
# (bead tla-z3ks).
#
# Pins the RED invariant from the bead:
#
#   GIVEN a completion item tree WHEN scripts/deliver-completion.sh runs THEN
#   PROMPT.md, work/ and EXPECT appear under the destination, ANSWER.md and
#   META.md do not, and a second run over the same destination overwrites
#   nothing.
#
# ---------------------------------------------------------------------------
# WHY THIS SUITE EXISTS, AND WHERE IT DIVERGES FROM ITS SIBLING
#
# harness/test-deliver-drill.sh is the model. It asserts that ONE name lands
# and that every other top-level entry is withheld, because a drill item hands
# over a single file. A completion item hands over three things, one of which
# is a whole directory the learner then edits, so the manifest here is two
# names plus a tree and the suite has to pin all three parts.
#
# The part that carries the risk is work/. work/Claims.tla is the file the
# learner writes their claims into, and once delivered it is the only copy of
# that work anywhere: ~/tla-practice is not a git repo. So the never-overwrite
# rows below are not a politeness check. They are the whole reason the script
# has a per-file existence test rather than a cp -R.
#
# THE FIXTURES CARRY A PLANTED MUTATION, three top-level entries no name list
# would guess: SECRET.md, a notes/ directory, and a .hidden-draft dotfile. A
# script that delivered the item's whole tree hands all three over, and so does
# one that withheld only ANSWER.md and META.md by name. The one under test
# delivers a manifest and withholds everything outside it, which is the SAFE
# failure direction: a new answer-bearing file is missed rather than leaked.
#
# The mutation also plants work/deep/Deep.tla, two levels inside work/, because
# the tree half of the manifest has to be recursive and a one-level copy would
# pass every other row.
#
# Against the real corpus the three designs are indistinguishable today, since
# the one item that exists carries only the two withheld names a list would
# carry. I suspect that is how a manifest bug would survive being looked at
# here, the same way it did in the problems corpus in 2026-10. The mutation is
# the part of this suite that does not go stale as items land.
#
# ---------------------------------------------------------------------------
# THE CONTRACT
#
#   scripts/deliver-completion.sh [--check|--dry-run] <selector> [dest-root]
#
#   <selector> is `all`, a family name, or <family>/<NN-slug>. A leading
#   completion/ and a trailing slash are tolerated, because the item's own
#   PROMPT.md prints the repo-relative form and that is what gets pasted.
#
#   <dest-root> defaults to $HOME/tla-practice/completion.
#
#   The source is <repo>/completion, and DELIVER_COMPLETION_SRC_ROOT overrides
#   <repo>. An item is a directory at completion/<family>/<NN-slug>.
#
#   Each item delivers PROMPT.md, EXPECT, and every file under work/
#   recursively, to <dest-root>/<family>/<NN-slug>/. Every other top-level
#   entry of the item is withheld and reported on stdout as
#   "withheld (not in the manifest): <source path>", one line per entry,
#   dotfiles included and a directory as one line rather than recursively.
#
#   No file is ever overwritten. An existing one is left alone and reported as
#   "skipped (exists): <path>", and the run still exits 0. Nothing is deleted.
#
#   An item missing any of the three manifest parts delivers nothing, is named
#   on stderr, its siblings still deliver, and the run exits 1.
#
#   --check, and its alias --dry-run, resolve everything, print what would be
#   delivered, and write nothing.
#
#   Both modes end on a counts line. --check prints
#   "<n> file(s) to land, <n> already there, <n> path(s) withheld" and a real
#   run prints "<n> file(s) landed, <n> skipped, <n> path(s) withheld".
#
# ---------------------------------------------------------------------------
# WHY EVERY RUN IS SANDBOXED TWICE
#
# ~/tla-practice is not a git repo and it holds the only copy of the work done
# in it. A write there does not come back. So this suite never names that path
# as a destination and never writes under it. Every run passes an explicit
# dest-root under a fresh mktemp root, AND redirects HOME, which is where the
# default dest-root resolves from.
#
# The default-root section goes further, because a sandboxed HOME does nothing
# for a script that hardcodes a path. That section runs only --check, which the
# contract says writes nothing, and it reads a source that exists in the
# sandbox and nowhere else before it concludes anything.
#
# ---------------------------------------------------------------------------
# THE NEGATIVE CONTROLS
#
# Two assertion families here are ABSENCE claims: the withheld file never
# landed, and the sentinel was not overwritten. Both are satisfied by a script
# that does nothing at all, so both get a control that proves the check is
# capable of failing. control_absence_bites and control_bytes_bite run the real
# assertion against a tree built by hand to violate it, and PASS only when the
# assertion fails. That is the shape harness/test-pipefail.sh uses for its
# planted-violation controls.
#
# Usage:  harness/test-deliver-completion.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SCRIPT="scripts/deliver-completion.sh"
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

TMPROOT=$(mktemp -d -t tla_deliver_completion.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

FIX_REPO="$TMPROOT/repo"
SANDBOX_HOME="$TMPROOT/home"
DEFAULT_ROOT="$SANDBOX_HOME/tla-practice/completion"
ERRFILE="$TMPROOT/stderr.txt"

DEST_MAIN="$TMPROOT/dest-main"         # the happy path, selector `all`
DEST_KEEP="$TMPROOT/dest-keep"         # pre-seeded, for the never-overwrite rule
DEST_CHECK="$TMPROOT/dest-check"       # --check only, never written
DEST_DRYRUN="$TMPROOT/dest-dryrun"     # --dry-run only, never written
DEST_STRAY="$TMPROOT/dest-stray"       # carries learner work beside the item
DEST_PARTIAL="$TMPROOT/dest-partial"   # an item missing a manifest part
DEST_ONE="$TMPROOT/dest-one"           # a single-item selector
DEST_FAMILY="$TMPROOT/dest-family"     # a family selector
DEST_PREFIX="$TMPROOT/dest-prefix"     # a completion/-prefixed selector
DEST_HIDDEN="$TMPROOT/dest-hidden"     # source under a dot-segment path
DEST_REAL="$TMPROOT/dest-real"         # the real corpus, read from the repo
DEST_TWICE="$TMPROOT/dest-twice"       # delivered, then delivered again
DEST_LEAK="$TMPROOT/dest-leak"         # built by hand to violate the rules

mkdir -p "$SANDBOX_HOME"

# ---------------------------------------------------------------------------
# Fixture source tree.
#
# mk_item <repo-root> <family/NN-slug>: the shape the real corpus has. work/
# holds a Claims.tla plus one machine pair, so a one-level or name-based copy
# would be visible as a missing file rather than as a count.
# ---------------------------------------------------------------------------

mk_item() {
  local root="$1" rel="$2"
  local d="$root/completion/$rel"
  mkdir -p "$d/work"
  printf 'prompt for %s\n' "$rel"      >"$d/PROMPT.md"
  printf 'Good\t0\nBad\t12\n'          >"$d/EXPECT"
  printf 'answer for %s\n' "$rel"      >"$d/ANSWER.md"
  printf 'constructs for %s\n' "$rel"  >"$d/META.md"
  printf 'claims for %s\n' "$rel"      >"$d/work/Claims.tla"
  printf 'machine for %s\n' "$rel"     >"$d/work/Good.tla"
  printf 'config for %s\n' "$rel"      >"$d/work/Good.cfg"
}

mk_item "$FIX_REPO" "sets/01-alpha"
mk_item "$FIX_REPO" "sets/02-beta"
mk_item "$FIX_REPO" "modal/01-gamma"

# THE PLANTED MUTATION, on sets/02-beta. Three top-level entries no name list
# would guess, one of them a dotfile and one of them a directory, plus one file
# two levels inside work/ that the tree half of the manifest has to reach.
printf 'an answer by another name\n' >"$FIX_REPO/completion/sets/02-beta/SECRET.md"
mkdir -p "$FIX_REPO/completion/sets/02-beta/notes/deep"
printf 'two levels down\n' >"$FIX_REPO/completion/sets/02-beta/notes/deep/DEEP.md"
printf 'an unfinished thought\n' >"$FIX_REPO/completion/sets/02-beta/.hidden-draft"
mkdir -p "$FIX_REPO/completion/sets/02-beta/work/deep"
printf 'a machine in a subdirectory\n' \
  >"$FIX_REPO/completion/sets/02-beta/work/deep/Deep.tla"

# Entries one level up from an item. completion/verify-item.sh lives here in
# the real tree, so a run that treated it as a family would break on the live
# corpus and not on a tidy fixture.
printf '#!/usr/bin/env bash\n' >"$FIX_REPO/completion/verify-item.sh"
printf 'the item inventory\n'  >"$FIX_REPO/completion/INVENTORY.md"

# A second source root whose second item is missing EXPECT. Kept apart from the
# main fixture so every other row runs against a corpus that is whole.
PARTIAL_REPO="$TMPROOT/repo-partial"
mk_item "$PARTIAL_REPO" "sets/01-alpha"
mk_item "$PARTIAL_REPO" "sets/02-headless"
rm -f "$PARTIAL_REPO/completion/sets/02-headless/EXPECT"

# A source root with a completion/ directory and no item in it.
EMPTY_REPO="$TMPROOT/repo-empty"
mkdir -p "$EMPTY_REPO/completion"
printf 'an inventory and nothing else\n' >"$EMPTY_REPO/completion/INVENTORY.md"

# A source root with no completion/ directory at all.
NOCOMP_REPO="$TMPROOT/repo-nocomp"
mkdir -p "$NOCOMP_REPO/puzzles"

# The sandboxed default root's source. omega-sandbox-only exists here and in no
# other fixture and in no real tree, so seeing it come back is the evidence
# that the sandbox is what got read.
SANDBOX_REPO="$TMPROOT/repo-sandbox"
mk_item "$SANDBOX_REPO" "sets/01-omega-sandbox-only"

# A source root whose path carries a DOT SEGMENT, the way every agent worktree
# under .claude/worktrees/agent-* does. A bare `-not -path '*/.*'` in the item
# finder matches the root itself here and the item list comes back empty on a
# tree that is fine. The predicate has to be anchored at the completion root.
HIDDEN_REPO="$TMPROOT/.claude/worktrees/agent-x/repo"
mk_item "$HIDDEN_REPO" "sets/01-anchored"

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
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_COMPLETION_SRC_ROOT="$FIX_REPO" \
    bash "$SCRIPT" "$@" 2>"$ERRFILE")
  RUN_RC=$?
  RUN_ERR=$(cat "$ERRFILE")
}

# run_deliver_from <src-root> [args...]: the same, against another fixture
# source root.
run_deliver_from() {
  local src="$1"
  shift
  RUN_OUT=$(HOME="$SANDBOX_HOME" DELIVER_COMPLETION_SRC_ROOT="$src" \
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

# expected_manifest <src-root> <rel>...
#
# The expected manifest, derived from the tree with find's own -name predicate
# for the two named parts and a full walk for the tree part. The script walks
# each item's entries and compares basenames against its manifest, so the two
# mechanisms differ on purpose.
expected_manifest() {
  local root="$1"
  shift
  local rel
  {
    for rel in "$@"; do
      [ -d "$root/completion/$rel" ] || continue
      (cd "$root/completion" && find "./$rel" -mindepth 1 -maxdepth 1 -type f \
        \( -name PROMPT.md -o -name EXPECT \))
      if [ -d "$root/completion/$rel/work" ]; then
        (cd "$root/completion" && find "./$rel/work" -type f)
      fi
    done
  } | LC_ALL=C sort
}

# count_items <src-root>: items, counted independently of the script.
count_items() {
  local root="$1/completion"
  [ -d "$root" ] || { printf '0\n'; return; }
  find "$root" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "$root/.*" | wc -l
}

# count_withheld <src-root> <rel>...
#
# Every top-level entry of every named item that is not a manifest part.
# Dotfiles counted, a directory counted once. This is the number the contract's
# counts line has to agree with, and deriving it is what keeps a literal out of
# this file.
count_withheld() {
  local root="$1"
  shift
  local rel total=0 n
  for rel in "$@"; do
    [ -d "$root/completion/$rel" ] || continue
    n=$(find "$root/completion/$rel" -mindepth 1 -maxdepth 1 \
      ! -name PROMPT.md ! -name EXPECT ! -name work | wc -l)
    total=$((total + n))
  done
  printf '%s\n' "$total"
}

# all_items <src-root>: every item rel, sorted, derived from the tree.
all_items() {
  local root="$1/completion" item
  [ -d "$root" ] || return
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    printf '%s\n' "${item#"$root/"}"
  done < <(find "$root" -mindepth 2 -maxdepth 2 -type d \
    ! -name '.*' ! -path "$root/.*" | LC_ALL=C sort)
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

# assert_manifest <label> <src-root> <dest-root> <rel>...
#
# The head of the invariant. The delivered file set has to equal the manifest
# derived from the source, exactly, both ways.
assert_manifest() {
  local label="$1" src="$2" dest="$3"
  shift 3
  local want got
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The delivery failed (rc=$RUN_RC), so the manifest proves nothing"
    return
  fi
  want=$(expected_manifest "$src" "$@")
  got=$(relfiles "$dest")
  if [ -z "$want" ]; then
    nope "$label. The fixture source carries no manifest, so the comparison is vacuous: $src"
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

# assert_bytes <label> <path> <reference-path>
#
# cmp, not a $(cat) comparison. The never-overwrite rule is about the learner's
# own file surviving BYTE FOR BYTE, and command substitution strips trailing
# newlines off both sides, so a run that rewrote a file's last byte would pass
# a content comparison.
assert_bytes() {
  local label="$1" path="$2" ref="$3"
  if [ ! -f "$path" ]; then
    nope "$label. No file at $path"
    return
  fi
  if cmp -s -- "$path" "$ref"; then
    ok "$label"
  else
    nope "$label. $path differs from $ref byte for byte"
  fi
}

# assert_survived <label> <path> <reference-path> <witness-path>
#
# The never-overwrite rule with its non-vacuity control attached. A sentinel
# survives a script that does nothing at all, so a bare byte comparison here
# would pass on a tree where the script is missing. It did, on the first red
# run of this suite. So this row requires three things at once: the run exited
# 0, the witness file DID land, and only then that the sentinel is unchanged.
assert_survived() {
  local label="$1" path="$2" ref="$3" witness="$4"
  if [ "$RUN_RC" -ne 0 ]; then
    nope "$label. The run exited $RUN_RC rather than 0, so survival proves nothing"
    return
  fi
  if [ ! -f "$witness" ]; then
    nope "$label. Nothing landed at all ($witness is absent), so survival proves nothing"
    return
  fi
  assert_bytes "$label" "$path" "$ref"
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

# control_absence_bites <label> <path>
#
# The negative control for the absence family. It runs the REAL assert_absent
# against a path that is there on purpose, and passes only when the assertion
# fails. An absence row is satisfied by a script that delivers nothing, so
# without this the whole withholding section could be vacuous.
control_absence_bites() {
  local label="$1" path="$2" before=$fail_count
  assert_absent "control (expected to fail): $label" "$path" >/dev/null
  if [ "$fail_count" -gt "$before" ]; then
    fail_count=$before
    ok "the absence check fails when the file IS there: $label"
  else
    pass_count=$((pass_count - 1))
    nope "the absence check PASSED over a tree that holds the file, so every absence row above proves nothing: $label"
  fi
}

# control_bytes_bite <label> <path> <reference-path>
#
# The negative control for the never-overwrite family, same shape.
control_bytes_bite() {
  local label="$1" path="$2" ref="$3" before=$fail_count
  assert_bytes "control (expected to fail): $label" "$path" "$ref" >/dev/null
  if [ "$fail_count" -gt "$before" ]; then
    fail_count=$before
    ok "the byte comparison fails when the file HAS been rewritten: $label"
  else
    pass_count=$((pass_count - 1))
    nope "the byte comparison PASSED over a rewritten file, so the sentinel rows prove nothing: $label"
  fi
}

ALL_RELS=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  ALL_RELS+=("$line")
done < <(all_items "$FIX_REPO")

# ---------------------------------------------------------------------------
echo "== the manifest: two names and a tree land, every other entry is withheld =="
# ---------------------------------------------------------------------------

run_deliver all "$DEST_MAIN"

assert_rc0 "a whole-corpus delivery exits 0"

assert_manifest "the delivered tree holds exactly PROMPT.md, EXPECT and work/" \
  "$FIX_REPO" "$DEST_MAIN" "${ALL_RELS[@]}"

assert_file_is "PROMPT.md lands byte for byte" \
  "$DEST_MAIN/sets/01-alpha/PROMPT.md" \
  "$(cat "$FIX_REPO/completion/sets/01-alpha/PROMPT.md")"

assert_bytes "EXPECT lands byte for byte, tabs and all" \
  "$DEST_MAIN/sets/01-alpha/EXPECT" "$FIX_REPO/completion/sets/01-alpha/EXPECT"

assert_bytes "work/Claims.tla lands, which is the file the learner edits" \
  "$DEST_MAIN/sets/01-alpha/work/Claims.tla" \
  "$FIX_REPO/completion/sets/01-alpha/work/Claims.tla"

assert_bytes "a machine module lands" \
  "$DEST_MAIN/sets/01-alpha/work/Good.tla" \
  "$FIX_REPO/completion/sets/01-alpha/work/Good.tla"

assert_bytes "a machine config lands" \
  "$DEST_MAIN/sets/01-alpha/work/Good.cfg" \
  "$FIX_REPO/completion/sets/01-alpha/work/Good.cfg"

assert_bytes "work/ is delivered RECURSIVELY, two levels down" \
  "$DEST_MAIN/sets/02-beta/work/deep/Deep.tla" \
  "$FIX_REPO/completion/sets/02-beta/work/deep/Deep.tla"

# The withheld names, asserted ONE AT A TIME rather than by counting. A count
# is satisfied by withholding the wrong two files.
assert_absent "ANSWER.md never lands" "$DEST_MAIN/sets/01-alpha/ANSWER.md"
assert_absent "META.md never lands" "$DEST_MAIN/sets/01-alpha/META.md"
assert_absent "ANSWER.md never lands for the second item either" \
  "$DEST_MAIN/sets/02-beta/ANSWER.md"
assert_absent "META.md never lands for the second item either" \
  "$DEST_MAIN/sets/02-beta/META.md"
assert_absent "ANSWER.md never lands for the second family either" \
  "$DEST_MAIN/modal/01-gamma/ANSWER.md"
assert_absent "META.md never lands for the second family either" \
  "$DEST_MAIN/modal/01-gamma/META.md"

# The mutation. A script delivering the tree hands these over, and so does one
# withholding only ANSWER.md and META.md by name.
assert_absent "an answer-bearing file no name list would guess never lands" \
  "$DEST_MAIN/sets/02-beta/SECRET.md"
assert_absent "a directory no name list would guess never lands" \
  "$DEST_MAIN/sets/02-beta/notes"
assert_absent "a dotfile no name list would guess never lands" \
  "$DEST_MAIN/sets/02-beta/.hidden-draft"

# The withheld report, per entry. A directory is one line rather than its
# contents, which is why the count can be compared against count_withheld.
assert_says_literal "the withheld report names ANSWER.md" \
  "withheld (not in the manifest): $FIX_REPO/completion/sets/01-alpha/ANSWER.md" "$RUN_OUT"
assert_says_literal "the withheld report names META.md" \
  "withheld (not in the manifest): $FIX_REPO/completion/sets/01-alpha/META.md" "$RUN_OUT"
assert_says_literal "the withheld report names the planted file" \
  "withheld (not in the manifest): $FIX_REPO/completion/sets/02-beta/SECRET.md" "$RUN_OUT"
assert_says_literal "the withheld report names the planted directory as one entry" \
  "withheld (not in the manifest): $FIX_REPO/completion/sets/02-beta/notes" "$RUN_OUT"
assert_says_literal "the withheld report names the planted dotfile" \
  "withheld (not in the manifest): $FIX_REPO/completion/sets/02-beta/.hidden-draft" "$RUN_OUT"

WITHHELD_LINES=$(grep -cF -- "withheld (not in the manifest): " <<<"$RUN_OUT")
WITHHELD_WANT=$(count_withheld "$FIX_REPO" "${ALL_RELS[@]}")
if [ "$WITHHELD_LINES" = "$WITHHELD_WANT" ]; then
  ok "the withheld report is complete: ${WITHHELD_LINES} lines against ${WITHHELD_WANT} non-manifest entries"
else
  nope "the withheld report is incomplete: ${WITHHELD_LINES} lines against ${WITHHELD_WANT} non-manifest entries"
fi

MANIFEST_COUNT=$(expected_manifest "$FIX_REPO" "${ALL_RELS[@]}" | wc -l)
assert_says_literal "the counts line names what landed, what was skipped and what was withheld" \
  "$MANIFEST_COUNT file(s) landed, 0 skipped, $WITHHELD_WANT path(s) withheld" "$RUN_OUT"

assert_says_literal "the run says which source it read" \
  "source: $FIX_REPO/completion" "$RUN_OUT"
assert_says_literal "the run says which destination it wrote" \
  "destination: $DEST_MAIN" "$RUN_OUT"

# The entries one directory up are not items and are not delivered.
assert_absent "completion/verify-item.sh is not an item and never lands" \
  "$DEST_MAIN/verify-item.sh"
assert_absent "completion/INVENTORY.md is not an item and never lands" \
  "$DEST_MAIN/INVENTORY.md"

# ---------------------------------------------------------------------------
echo
echo "== the fixture is not vacuous =="
# ---------------------------------------------------------------------------

# A mutation that drifted out of the fixture would let a leaking script pass
# every absence row above.
if [ -f "$FIX_REPO/completion/sets/02-beta/SECRET.md" ] &&
   [ -f "$FIX_REPO/completion/sets/02-beta/notes/deep/DEEP.md" ] &&
   [ -f "$FIX_REPO/completion/sets/02-beta/.hidden-draft" ] &&
   [ -f "$FIX_REPO/completion/sets/02-beta/work/deep/Deep.tla" ]; then
  ok "the source still carries all four planted entries"
else
  nope "the planted mutation has drifted out of the fixture, so the absence rows prove nothing"
fi

if [ "$WITHHELD_WANT" -ge 9 ]; then
  ok "the source carries ${WITHHELD_WANT} non-manifest entries, so there is something to withhold"
else
  nope "the source carries only ${WITHHELD_WANT} non-manifest entries, which is fewer than the fixture builds"
fi

if [ "${#ALL_RELS[@]}" -eq 3 ]; then
  ok "the fixture carries the three items the sections below assume"
else
  nope "the fixture carries ${#ALL_RELS[@]} items rather than 3, so the counts rows are reading something else"
fi

# ---------------------------------------------------------------------------
echo
echo "== the negative controls: the absence checks are capable of failing =="
# ---------------------------------------------------------------------------

# A leaky delivery, done by hand with cp -R, is what the script must never be.
# Running the real assertions against it is the only way to know they bite.
mkdir -p "$DEST_LEAK/sets"
cp -R "$FIX_REPO/completion/sets/01-alpha" "$DEST_LEAK/sets/01-alpha"

control_absence_bites "ANSWER.md" "$DEST_LEAK/sets/01-alpha/ANSWER.md"
control_absence_bites "META.md" "$DEST_LEAK/sets/01-alpha/META.md"

# And the sentinel family. A clobbered file has to read as clobbered.
SENTINEL_REF="$TMPROOT/sentinel-ref.txt"
printf 'my own claims, the only copy anywhere\n' >"$SENTINEL_REF"
printf 'my own claims, the only copy anywhere\n' >"$DEST_LEAK/sets/01-alpha/work/Claims.tla"
assert_bytes "the control sentinel starts out matching its reference" \
  "$DEST_LEAK/sets/01-alpha/work/Claims.tla" "$SENTINEL_REF"
cp -- "$FIX_REPO/completion/sets/01-alpha/work/Claims.tla" \
  "$DEST_LEAK/sets/01-alpha/work/Claims.tla"
control_bytes_bite "a hand-clobbered Claims.tla" \
  "$DEST_LEAK/sets/01-alpha/work/Claims.tla" "$SENTINEL_REF"

# ---------------------------------------------------------------------------
echo
echo "== never overwrite: the learner's Claims.tla is the only copy there is =="
# ---------------------------------------------------------------------------

# This is the row the bead was filed over. work/Claims.tla is where the learner
# writes their two claims, ~/tla-practice has no git behind it, and a clobber
# here is unrecoverable.
mkdir -p "$DEST_KEEP/sets/01-alpha/work" "$DEST_KEEP/sets/02-beta/work"
KEEP_SENTINEL="$TMPROOT/keep-sentinel.tla"
printf 'Walked == my own answer\nCloses == my other one\n' >"$KEEP_SENTINEL"
cp -- "$KEEP_SENTINEL" "$DEST_KEEP/sets/01-alpha/work/Claims.tla"
printf 'the prompt as delivered\n' >"$DEST_KEEP/sets/01-alpha/PROMPT.md"
printf 'Good\t0\nBad\t12\n'        >"$DEST_KEEP/sets/01-alpha/EXPECT"
printf 'a trace I kept\n'          >"$DEST_KEEP/sets/01-alpha/work/one.out"
printf 'the prompt as delivered\n' >"$DEST_KEEP/sets/02-beta/PROMPT.md"

run_deliver all "$DEST_KEEP"

assert_rc0 "a destination that already holds an item exits 0"

assert_survived "THE SENTINEL SURVIVES BYTE FOR BYTE: the learner's Claims.tla is untouched" \
  "$DEST_KEEP/sets/01-alpha/work/Claims.tla" "$KEEP_SENTINEL" \
  "$DEST_KEEP/modal/01-gamma/work/Claims.tla"

assert_says_literal "the skip is reported rather than silent" \
  "skipped (exists): $DEST_KEEP/sets/01-alpha/work/Claims.tla" "$RUN_OUT"

assert_says_literal "an already-delivered PROMPT.md is skipped and said so" \
  "skipped (exists): $DEST_KEEP/sets/01-alpha/PROMPT.md" "$RUN_OUT"

assert_says_literal "an already-delivered EXPECT is skipped and said so" \
  "skipped (exists): $DEST_KEEP/sets/01-alpha/EXPECT" "$RUN_OUT"

assert_bytes "a machine beside the edited Claims.tla still lands" \
  "$DEST_KEEP/sets/01-alpha/work/Good.tla" \
  "$FIX_REPO/completion/sets/01-alpha/work/Good.tla"

assert_bytes "an untouched sibling item lands whole" \
  "$DEST_KEEP/modal/01-gamma/work/Claims.tla" \
  "$FIX_REPO/completion/modal/01-gamma/work/Claims.tla"

assert_says "the counts line separates what landed from what was skipped" \
  "[0-9]+ file\(s\) landed, 4 skipped," "$RUN_OUT"

assert_absent "a re-delivery still never lands ANSWER.md" \
  "$DEST_KEEP/sets/01-alpha/ANSWER.md"

# ---------------------------------------------------------------------------
echo
echo "== nothing is ever deleted =="
# ---------------------------------------------------------------------------

# The 2026-10-02 incident in the problems corpus was a DELETION, not a leak.
# This script has no delete path, and the row that would catch one growing is a
# destination carrying work the source knows nothing about.
mkdir -p "$DEST_STRAY/sets/01-alpha/work" "$DEST_STRAY/sets/09-mine" "$DEST_STRAY/traces"
printf 'my attempt\n'        >"$DEST_STRAY/sets/01-alpha/work/Scratch.tla"
printf 'an item of my own\n' >"$DEST_STRAY/sets/09-mine/PROMPT.md"
printf 'a trace I kept\n'    >"$DEST_STRAY/traces/one.txt"
STRAY_BEFORE=$(snapshot "$DEST_STRAY/sets/09-mine")
STRAY_TRACES_BEFORE=$(snapshot "$DEST_STRAY/traces")

run_deliver all "$DEST_STRAY"

assert_rc0 "a destination carrying its own work exits 0"

assert_file_is "a learner's own module inside work/ survives" \
  "$DEST_STRAY/sets/01-alpha/work/Scratch.tla" "my attempt"

assert_unchanged "an item the source does not have survives whole" \
  "$DEST_STRAY/sets/09-mine" "$STRAY_BEFORE" 0

assert_unchanged "a directory the source does not have survives whole" \
  "$DEST_STRAY/traces" "$STRAY_TRACES_BEFORE" 0

# ---------------------------------------------------------------------------
echo
echo "== --check and --dry-run resolve everything and write nothing =="
# ---------------------------------------------------------------------------

CHECK_BEFORE=$(snapshot "$DEST_CHECK")

run_deliver --check all "$DEST_CHECK"

assert_rc0 "--check exits 0"

assert_unchanged "--check creates no destination at all" \
  "$DEST_CHECK" "$CHECK_BEFORE" 0

assert_says_literal "--check names the prompt it would deliver" \
  "would deliver: $DEST_CHECK/sets/01-alpha/PROMPT.md" "$RUN_OUT"

assert_says_literal "--check names the EXPECT it would deliver" \
  "would deliver: $DEST_CHECK/sets/01-alpha/EXPECT" "$RUN_OUT"

assert_says_literal "--check names the work/ file it would deliver" \
  "would deliver: $DEST_CHECK/sets/01-alpha/work/Claims.tla" "$RUN_OUT"

assert_never_names "--check never names ANSWER.md as something it would deliver" \
  "would deliver: $DEST_CHECK/sets/01-alpha/ANSWER.md" "$RUN_OUT"

assert_says_literal "--check reports the withholding too" \
  "withheld (not in the manifest): $FIX_REPO/completion/sets/01-alpha/ANSWER.md" "$RUN_OUT"

assert_says_literal "--check ends on its own counts line" \
  "$MANIFEST_COUNT file(s) to land, 0 already there, $WITHHELD_WANT path(s) withheld" "$RUN_OUT"

# --dry-run is the flag the bead's brief named, and --check is the one both
# sibling delivery scripts carry. They are the same flag.
DRYRUN_BEFORE=$(snapshot "$DEST_DRYRUN")

run_deliver --dry-run all "$DEST_DRYRUN"

assert_rc0 "--dry-run exits 0"
assert_unchanged "--dry-run creates no destination at all" \
  "$DEST_DRYRUN" "$DRYRUN_BEFORE" 0
assert_says_literal "--dry-run is an alias for --check, same counts line" \
  "$MANIFEST_COUNT file(s) to land, 0 already there, $WITHHELD_WANT path(s) withheld" "$RUN_OUT"

# --check over a destination that already holds the corpus is the shape central
# reads before a re-delivery, so it has to separate the two.
run_deliver --check all "$DEST_MAIN"
assert_rc0 "--check over a delivered destination exits 0"
assert_says_literal "--check names what is already there" \
  "would skip (exists): $DEST_MAIN/sets/01-alpha/work/Claims.tla" "$RUN_OUT"
assert_says_literal "--check counts the already-there separately from the to-land" \
  "0 file(s) to land, $MANIFEST_COUNT already there," "$RUN_OUT"

# ---------------------------------------------------------------------------
echo
echo "== the selector: an item, a family, all, and the forms that get pasted =="
# ---------------------------------------------------------------------------

run_deliver "sets/01-alpha" "$DEST_ONE"
assert_rc0 "a single-item selector exits 0"
assert_manifest "a single-item selector delivers exactly that item" \
  "$FIX_REPO" "$DEST_ONE" "sets/01-alpha"
assert_absent "a single-item selector delivers no sibling" "$DEST_ONE/sets/02-beta"
assert_absent "a single-item selector delivers no other family" "$DEST_ONE/modal"
assert_absent "a single-item selector still withholds ANSWER.md" \
  "$DEST_ONE/sets/01-alpha/ANSWER.md"

run_deliver "sets" "$DEST_FAMILY"
assert_rc0 "a family selector exits 0"
assert_manifest "a family selector delivers every item in that family and no other" \
  "$FIX_REPO" "$DEST_FAMILY" "sets/01-alpha" "sets/02-beta"
assert_absent "a family selector delivers no other family" "$DEST_FAMILY/modal"

# The item's own PROMPT.md prints `completion/sets/01-clockface`, so that is the
# string that gets pasted. A trailing slash is what tab completion produces.
run_deliver "completion/sets/01-alpha/" "$DEST_PREFIX"
assert_rc0 "a completion/-prefixed selector with a trailing slash exits 0"
assert_manifest "the pasted form resolves to the same one item" \
  "$FIX_REPO" "$DEST_PREFIX" "sets/01-alpha"

run_deliver "sets/99-nosuch" "$TMPROOT/dest-nosuch"
assert_rc "a selector naming nothing exits 1" 1
assert_says "and says what it could not resolve" "no such item or family" "$RUN_ERR"
assert_absent "a selector naming nothing creates no destination" "$TMPROOT/dest-nosuch"

# ---------------------------------------------------------------------------
echo
echo "== the anchored hidden-directory predicate =="
# ---------------------------------------------------------------------------

# Every agent in this repo works under .claude/worktrees/agent-*, so the item
# finder's hidden-directory predicate has to be anchored at the completion root.
# A bare `-not -path '*/.*'` matches the repo root itself here and the item list
# comes back empty on a tree that is fine.
case "$HIDDEN_REPO" in
  */.claude/worktrees/*)
    ok "the fixture source root really does carry a dot segment, so the row below is not vacuous" ;;
  *)
    nope "the fixture source root carries no dot segment, so the anchoring row proves nothing: $HIDDEN_REPO" ;;
esac

run_deliver_from "$HIDDEN_REPO" all "$DEST_HIDDEN"
assert_rc0 "a source under a .claude/worktrees/agent-x path exits 0"
assert_says_literal "the item under a dot-segment path is found and delivered" \
  "destination: $DEST_HIDDEN" "$RUN_OUT"
assert_manifest "the item under a dot-segment path lands whole" \
  "$HIDDEN_REPO" "$DEST_HIDDEN" "sets/01-anchored"
assert_bytes "and its Claims.tla is there" \
  "$DEST_HIDDEN/sets/01-anchored/work/Claims.tla" \
  "$HIDDEN_REPO/completion/sets/01-anchored/work/Claims.tla"

# ---------------------------------------------------------------------------
echo
echo "== a second delivery is the normal way a new item arrives =="
# ---------------------------------------------------------------------------

run_deliver all "$DEST_TWICE"
assert_rc0 "the first delivery exits 0"
FIRST=$(relfiles "$DEST_TWICE")

mk_item "$FIX_REPO" "modal/02-delta"
run_deliver all "$DEST_TWICE"
assert_rc0 "the second delivery exits 0"

assert_says_literal "the second delivery lands only the new item" \
  "5 file(s) landed, $MANIFEST_COUNT skipped," "$RUN_OUT"

assert_bytes "the new item's Claims.tla lands" \
  "$DEST_TWICE/modal/02-delta/work/Claims.tla" \
  "$FIX_REPO/completion/modal/02-delta/work/Claims.tla"

SECOND=$(relfiles "$DEST_TWICE")
if [ "$FIRST" != "$SECOND" ]; then
  ok "the second delivery grew the tree rather than rewriting it"
else
  nope "the second delivery changed nothing, so the new item never arrived"
fi

rm -rf "$FIX_REPO/completion/modal/02-delta"

# ---------------------------------------------------------------------------
echo
echo "== an incomplete item is loud, and its siblings still land =="
# ---------------------------------------------------------------------------

run_deliver_from "$PARTIAL_REPO" all "$DEST_PARTIAL"

assert_rc "an item missing EXPECT exits 1" 1

assert_says "the run names the item that is not deliverable" \
  "sets/02-headless" "$RUN_ERR"

assert_says "and names the part it is missing" "carries no EXPECT" "$RUN_ERR"

assert_bytes "the sibling item still landed" \
  "$DEST_PARTIAL/sets/01-alpha/work/Claims.tla" \
  "$PARTIAL_REPO/completion/sets/01-alpha/work/Claims.tla"

assert_absent "the incomplete item delivers nothing at all" \
  "$DEST_PARTIAL/sets/02-headless/PROMPT.md"

assert_absent "and its answer never lands" \
  "$DEST_PARTIAL/sets/02-headless/ANSWER.md"

# ---------------------------------------------------------------------------
echo
echo "== the fatal sources, which create nothing =="
# ---------------------------------------------------------------------------

DEST_FATAL="$TMPROOT/dest-fatal"
FATAL_BEFORE=$(snapshot "$DEST_FATAL")

run_deliver_from "$EMPTY_REPO" all "$DEST_FATAL"
assert_rc "a completion/ directory with no item in it exits 1" 1
assert_says "and says that there is nothing to deliver" "holds no item" "$RUN_ERR"
assert_unchanged "a source with no item creates no destination" \
  "$DEST_FATAL" "$FATAL_BEFORE" 1

run_deliver_from "$NOCOMP_REPO" all "$DEST_FATAL"
assert_rc "a source root with no completion/ directory exits 1" 1
assert_says "and names the directory it looked for" \
  "no completion corpus at $NOCOMP_REPO/completion" "$RUN_ERR"
assert_says "and names the override that fixes it" \
  "DELIVER_COMPLETION_SRC_ROOT" "$RUN_ERR"
assert_unchanged "a source with no completion/ creates no destination" \
  "$DEST_FATAL" "$FATAL_BEFORE" 1

run_deliver --bogus all "$DEST_FATAL"
assert_rc "an unknown option exits 1" 1
assert_says "and prints usage" "Usage: " "$RUN_ERR"
assert_unchanged "an unknown option creates no destination" \
  "$DEST_FATAL" "$FATAL_BEFORE" 1

run_deliver
assert_rc "no selector at all exits 1" 1
assert_says "and says a selector is required" "no item, family or 'all' given" "$RUN_ERR"

run_deliver all "$DEST_FATAL" "extra"
assert_rc "a third positional argument exits 1" 1
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

run_deliver_from "$SANDBOX_REPO" --check all

assert_rc0 "--check with no dest-root argument exits 0"

assert_says_literal "--check with no dest-root reads the sandboxed default root" \
  "destination: $DEFAULT_ROOT" "$RUN_OUT"

assert_says_literal "--check with no dest-root resolves the item under it" \
  "would deliver: $DEFAULT_ROOT/sets/01-omega-sandbox-only/work/Claims.tla" "$RUN_OUT"

assert_unchanged "--check with no dest-root writes nothing" \
  "$DEFAULT_ROOT" "$DEFAULT_BEFORE" 0

# The sandbox path ends in tla-practice/completion too, so this has to name the
# REAL path rather than the shape of it.
assert_never_names "--check with no dest-root never names the real practice tree" \
  "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

# ---------------------------------------------------------------------------
echo
echo "== the real completion/ tree, read through --check into a temp destination =="
# ---------------------------------------------------------------------------

# The counts are DERIVED, not written down. One item exists today and more are
# coming, so a literal here would be wrong within the week. What this row pins
# is that the script and an independent walk of the tree agree.
REAL_ITEMS=$(count_items "$REPO_ROOT")

REAL_RELS=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  REAL_RELS+=("$line")
done < <(all_items "$REPO_ROOT")

if [ "$REAL_ITEMS" -gt 0 ]; then
  REAL_MANIFEST=$(expected_manifest "$REPO_ROOT" "${REAL_RELS[@]}" | wc -l)
  REAL_WITHHELD=$(count_withheld "$REPO_ROOT" "${REAL_RELS[@]}")

  run_deliver_realrepo --check all "$DEST_REAL"

  assert_rc0 "--check over the real corpus exits 0"

  assert_says_literal "--check over the real corpus agrees with an independent walk of the tree" \
    "$REAL_MANIFEST file(s) to land, 0 already there, $REAL_WITHHELD path(s) withheld" "$RUN_OUT"

  assert_absent "--check over the real corpus creates no destination" "$DEST_REAL"

  assert_says_literal "the real corpus withholds 01-clockface's ANSWER.md" \
    "withheld (not in the manifest): $REPO_ROOT/completion/sets/01-clockface/ANSWER.md" "$RUN_OUT"

  assert_says_literal "the real corpus withholds 01-clockface's META.md" \
    "withheld (not in the manifest): $REPO_ROOT/completion/sets/01-clockface/META.md" "$RUN_OUT"

  assert_says_literal "the real corpus would deliver 01-clockface's Claims.tla" \
    "would deliver: $DEST_REAL/sets/01-clockface/work/Claims.tla" "$RUN_OUT"

  assert_says_literal "the real corpus would deliver 01-clockface's EXPECT" \
    "would deliver: $DEST_REAL/sets/01-clockface/EXPECT" "$RUN_OUT"

  assert_never_names "--check over the real corpus never names the real practice tree" \
    "$REAL_PRACTICE" "$RUN_OUT$RUN_ERR"

  # THE MANIFEST HAS TO BE COMPLETE FOR THE GRADER, and this is the row that
  # says so without running TLC. completion/verify-item.sh reads EXPECT, takes
  # each stem, and runs work/<stem>.tla against work/<stem>.cfg. So every stem
  # EXPECT names has to resolve to two delivered files. An item whose machines
  # lived anywhere but work/ would deliver, read clean on every other row here,
  # and then fail in the learner's hands at "no such file".
  #
  # Checked live rather than only here: the real item delivered into a temp
  # root ran all three of its machines through verify-item.sh and came back
  # 150, 150, 150, which is the untouched-Claims.tla signature its own
  # PROMPT.md documents. That run costs three TLC invocations, which is why
  # this suite asserts the resolvability instead and stays in the fast tier.
  stem_misses=0
  stem_total=0
  for rel in "${REAL_RELS[@]}"; do
    expect_file="$REPO_ROOT/completion/$rel/EXPECT"
    [ -f "$expect_file" ] || continue
    while IFS= read -r row || [ -n "$row" ]; do
      case "$row" in ""|\#*) continue ;; esac
      stem="${row%%	*}"
      [ -n "$stem" ] || continue
      stem_total=$((stem_total + 1))
      for ext in tla cfg; do
        if ! grep -qF -- "would deliver: $DEST_REAL/$rel/work/$stem.$ext" <<<"$RUN_OUT"; then
          nope "EXPECT names the machine $stem in $rel, and $stem.$ext is not in the manifest"
          stem_misses=$((stem_misses + 1))
        fi
      done
    done <"$expect_file"
  done

  if [ "$stem_total" -eq 0 ]; then
    nope "no EXPECT row carried a machine stem, so the grader-completeness row is vacuous"
  elif [ "$stem_misses" -eq 0 ]; then
    ok "every machine the real corpus's EXPECT names resolves to a delivered .tla and .cfg (${stem_total} stem(s))"
  fi

  # Two withheld entries per item is today's shape. The row states the relation
  # rather than the number, so it tracks the corpus instead of going stale.
  if [ "$REAL_WITHHELD" -eq $((REAL_ITEMS * 2)) ]; then
    ok "the real corpus withholds 2 entries per item (${REAL_ITEMS} items, ${REAL_WITHHELD} paths)"
  else
    nope "the real corpus withholds ${REAL_WITHHELD} paths over ${REAL_ITEMS} items, which is not 2 per item. An item has grown a top-level entry, and somebody has to decide whether it is deliverable"
  fi
else
  nope "the real completion/ tree holds no item, so the corpus rows did not run"
fi

# ---------------------------------------------------------------------------
echo
echo "== structural: the deviations are argued, and the suite runs =="
# ---------------------------------------------------------------------------

# The bead asks the script to follow scripts/deliver-drill.sh and to say at
# every point where it differs and why. That is part of the contract rather
# than a courtesy, so it is asserted.
if [ "$SCRIPT_PRESENT" -eq 0 ]; then
  nope "the script names its model. $SCRIPT does not exist"
  nope "the script states what it withholds. $SCRIPT does not exist"
  nope "the script states the never-overwrite rule. $SCRIPT does not exist"
  nope "the script says why work/ is a tree manifest. $SCRIPT does not exist"
  nope "the script says it has no delete path. $SCRIPT does not exist"
else
  SCRIPT_HEAD=$(sed -n '1,140p' "$SCRIPT")
  assert_says "the script names scripts/deliver-drill.sh as its model" \
    'deliver-drill\.sh' "$SCRIPT_HEAD"
  assert_says "the script states what it withholds" \
    'ANSWER\.md' "$SCRIPT_HEAD"
  assert_says "and names the other withheld file" \
    'META\.md' "$SCRIPT_HEAD"
  assert_says "the script states the never-overwrite rule" \
    'NEVER OVERWRITE|never overwrit' "$SCRIPT_HEAD"
  assert_says "the script says it has no delete path" \
    'no delete path' "$SCRIPT_HEAD"
  assert_says "the script says why work/ is delivered as a tree" \
    'work/' "$SCRIPT_HEAD"

  SCRIPT_BODY=$(cat "$SCRIPT")
  assert_says "the script resolves its root from BASH_SOURCE rather than a literal path" \
    'BASH_SOURCE' "$SCRIPT_BODY"
  assert_says "the script sets -uo pipefail" \
    '^set -uo pipefail$' "$SCRIPT_BODY"
  # The [$] is a one-character class matching a literal dollar sign. Written
  # as \$ it is the same regex, and shellcheck reads the pattern as a variable
  # somebody forgot to expand (SC2016). The class says the same thing and says
  # it without a false finding.
  assert_says "the item finder anchors its hidden-directory predicate" \
    '! -path "[$]SRC_COMPLETION/\.\*"' "$SCRIPT_BODY"
  # Anchored at a command position rather than anywhere in the text. A bare
  # `rm ` substring also matches the tail of "perform" and "confirm", and a
  # check that fires on an English word is one somebody turns off.
  if grep -qE -- '(^|[;&|(][[:space:]]*)(rm|rmdir|unlink|mv|truncate)[[:space:]]' <<<"$SCRIPT_BODY"; then
    nope "the script runs a delete or a move, and the contract says it has no delete path"
  else
    ok "the script runs no rm, rmdir, unlink, mv or truncate anywhere"
  fi
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-deliver-completion\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-deliver-completion.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-deliver-completion.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
