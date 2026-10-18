#!/usr/bin/env bash
# test-deliver-verify.sh — the stale-delivery gate for bead tla-mjvx.
#
# THE FAILURE THIS EXISTS FOR. Frank ran `./drill --style` on 2026-10-15 and
# got "unknown option". The repo had carried that option for several hours and
# his copy did not: one delivery ran after the tla-rzvk wave, then three more
# waves merged and nobody delivered again. One of the three was a fix to a
# defect he had reported himself. Three waves of work were invisible to the
# only person who uses the tree.
#
# WHY NO EXISTING GATE COULD SEE IT. Every suite and every cibuild phase runs
# inside the repo. ~/tla-practice is not a git repo and no repo-level search
# reaches it, which CLAUDE.md already names as one of the two surfaces that
# get missed. The delivery scripts were gated for what they WOULD write, and
# nothing checked whether they had been RUN.
#
# AND --check DOES NOT ANSWER IT, which is worth saying because the two read
# alike. --check reports what a delivery would do, so it prints "66 to
# overwrite" on a tree that is already byte-identical. Only a content
# comparison tells a stale tree from a current one, and that is --verify.
#
# WHAT THIS GATE COVERS TODAY. The recall channel. Four more delivery scripts
# exist, drill, completion, problems and exercises, and bead tla-mjvx stays
# open for them. Recall came first because it is the channel moving this week
# and because every entry in its manifest is repo-owned, so a difference is
# drift and nothing else. drill has two file classes and a learner owns one of
# them, so a verify there has to read the policy before it calls a difference
# drift. That is design work rather than another loop.
#
# THE SKIP IS LOAD-BEARING. No box but Frank's has a delivered tree and a CI
# runner never will. A gate that failed on absence would be red everywhere it
# does not apply, which is how a gate gets switched off. Absence is exit 0 and
# the run says which case it was.
#
# Usage:  harness/test-deliver-verify.sh
# Exit:   0 if every assertion holds, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

DELIVER="scripts/deliver-recall.sh"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

WORK=$(mktemp -d -t tla_deliver_verify.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

# Runs --verify against a destination root and leaves its output in VOUT and
# its status in VRC. Captured rather than piped: a pipeline into a consumer
# that can close early returns 141 under pipefail, and a present line then
# reads as absent.
VOUT=""
VRC=0
verify_into() {
  VOUT=$("$DELIVER" --verify "$1" 2>&1)
  VRC=$?
}

expect_rc() {
  local label="$1" want="$2"
  if [ "$VRC" = "$want" ]; then
    ok "$label — rc=$want"
  else
    nope "$label — wanted rc=$want, got rc=$VRC"
  fi
}

expect_says() {
  local label="$1" needle="$2"
  if grep -qF -- "$needle" <<<"$VOUT"; then
    ok "$label"
  else
    nope "$label — output carries no '$needle'"
  fi
}

expect_lacks() {
  local label="$1" needle="$2"
  if grep -qF -- "$needle" <<<"$VOUT"; then
    nope "$label — output carries '$needle' and should not"
  else
    ok "$label"
  fi
}

# A delivered tree the script would call current. The runner's mode is set by
# the delivery rather than by cp, so set it here too.
plant() {
  local dest="$1"
  cp -r recall "$dest" || return 1
  chmod 0755 "$dest/recall.sh" || return 1
}

printf 'deliver --verify gate\n'
echo
echo "== part 1: the four drift shapes, each against its own planted tree =="

# ---------------------------------------------------------------------------
# Absence. This is the case every box but Frank's is in, so it comes first.
# ---------------------------------------------------------------------------
verify_into "$WORK/never-delivered"
expect_rc    "an absent destination root skips" 0
expect_says  "the skip names the path it looked for" "$WORK/never-delivered"
expect_says  "the skip says it is skipping" "Skipping."
expect_lacks "the skip reports no drift" "DRIFT"

# ---------------------------------------------------------------------------
# The control. Without this row the three drift rows below could all be
# passing because the comparison never ran.
# ---------------------------------------------------------------------------
plant "$WORK/current"
verify_into "$WORK/current"
expect_rc    "a current tree passes" 0
expect_says  "a current tree reports nothing drifted" "0 drifted"
expect_lacks "a current tree names no path" "DRIFT"

# ---------------------------------------------------------------------------
# Stale content. This is Frank's actual case: the file is there and it is the
# version from before the merge.
# ---------------------------------------------------------------------------
plant "$WORK/stale"
printf '\n# a line the repo does not have\n' >>"$WORK/stale/README.md"
verify_into "$WORK/stale"
expect_rc    "a stale file is drift" 3
expect_says  "it names the stale path" "DRIFT, differs from"
expect_says  "it names which file" "$WORK/stale/README.md"
expect_says  "it counts the rest as in sync" "65 file(s) in sync, 1 drifted"

# ---------------------------------------------------------------------------
# A manifest entry that never landed. Distinguished from stale content on
# purpose: the remedy is the same but the reader's question is not.
# ---------------------------------------------------------------------------
plant "$WORK/absent-file"
rm -f "$WORK/absent-file/MISSES.tsv"
verify_into "$WORK/absent-file"
expect_rc    "a missing manifest entry is drift" 3
expect_says  "it says never delivered rather than differs" "DRIFT, never delivered:"
expect_says  "it names which file" "$WORK/absent-file/MISSES.tsv"

# ---------------------------------------------------------------------------
# Mode. The delivery chmods the runner 0755 for a stated reason, and content
# compares equal whatever the mode is, so nothing else here would catch it. A
# runner delivered 0644 is a channel that reports success and cannot be run.
# ---------------------------------------------------------------------------
plant "$WORK/unreadable"
chmod 0644 "$WORK/unreadable/recall.sh"
verify_into "$WORK/unreadable"
expect_rc    "a non-executable runner is drift" 3
expect_says  "it says not executable" "DRIFT, not executable:"
expect_says  "the content count is untouched by the mode finding" "66 file(s) in sync, 1 drifted"

echo
echo "== part 2: --check and --verify are different questions =="

# --check on a byte-identical tree says "to overwrite" for every file, which
# is true about what a delivery would do and says nothing about drift. Pinned
# here because this is the confusion the bead is about, and a later hand that
# wires --check into a gate would reintroduce it.
CHECK_OUT=$("$DELIVER" --check "$WORK/current" 2>&1)
CHECK_RC=$?
if [ "$CHECK_RC" = "0" ] && grep -qF "66 to overwrite" <<<"$CHECK_OUT"; then
  ok "--check calls a current tree '66 to overwrite' and exits 0"
else
  nope "--check on a current tree gave rc=$CHECK_RC, expected 0 and '66 to overwrite'"
fi

BOTH_OUT=$("$DELIVER" --check --verify "$WORK/current" 2>&1)
BOTH_RC=$?
if [ "$BOTH_RC" = "1" ] && grep -qF "pick one" <<<"$BOTH_OUT"; then
  ok "asking for both at once is refused"
else
  nope "--check --verify gave rc=$BOTH_RC, expected 1 and 'pick one'"
fi

echo
echo "== part 3: the real delivered tree, which is the whole point =="

# Parts 1 and 2 prove the instrument. This part is the measurement, and it is
# the only row that can tell Frank his copy is behind. It reads and compares;
# it writes nothing. ~/tla-practice is not a git repo and has no backup of its
# own, so nothing in this suite may ever write there.
REAL_OUT=$("$DELIVER" --verify 2>&1)
REAL_RC=$?
case "$REAL_RC" in
  0)
    if grep -qF "Skipping." <<<"$REAL_OUT"; then
      ok "no delivered recall tree on this box, so there is nothing to compare"
    else
      ok "the delivered recall tree matches the repo"
    fi
    ;;
  3)
    nope "THE DELIVERED RECALL TREE IS BEHIND THE REPO. Run $DELIVER after backing up ~/tla-practice."
    printf '%s\n' "$REAL_OUT" | grep -E '^DRIFT|drifted' | sed 's/^/        /'
    ;;
  *)
    nope "$DELIVER --verify failed with rc=$REAL_RC rather than answering"
    printf '%s\n' "$REAL_OUT" | tail -5 | sed 's/^/        /'
    ;;
esac

echo
printf 'OK: %s assertions passed\n' "$pass_count"
if [ "$fail_count" -gt 0 ]; then
  printf 'FAILED: %s passed, %s failed\n' "$pass_count" "$fail_count"
  exit 1
fi
