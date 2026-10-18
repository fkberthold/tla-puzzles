#!/usr/bin/env bash
# test-deliver-practice-root.sh — the gate for bead tla-xbbb.
#
# Usage:  harness/test-deliver-practice-root.sh
# Exit:   0 if every assertion holds, 1 otherwise.
#
# ---------------------------------------------------------------------------
# THE TWO HALVES OF THE INVARIANT
#
# The bead states it as one line and it is two claims:
#
#   every claim ~/tla-practice/README.md makes about a directory name
#   resolves against the delivered tree, and the file has a source in this
#   repo that the spelling gate reads.
#
# The second half is a structural check and it is cheap: part 5 asserts that
# practice/README.md is tracked and that harness/test-spelling.sh walks the
# root it sits under. Before this bead the file had no source at all, so that
# assertion was red by construction.
#
# The first half is the real work and part 3 does it. The source README names
# directories in the practice tree, and a reader acts on those names. When the
# tree moves and the prose does not, the file lies to the one person using it.
# One read on 2026-10-18 found three stale claims at once, and the live batch
# name it carries, attempts/2026-10-02-fresh-start/, is a dated literal that
# WILL go stale the day batch 2 opens. That is the fourth stale claim this
# gate is built to catch.
#
# WHAT THE CHECK CAN AND CANNOT SEE, stated here rather than left for somebody
# to infer from a green run.
#
# IT CATCHES a path claim whose literal part no longer resolves: a renamed
# directory, a deleted one, a dated batch name that has rolled over, a file
# like problems/ORDER that moved. Each of those is a prose claim a reader
# would act on and find wrong.
#
# IT DOES NOT CATCH a prose claim with no path in it. Of the three stale
# claims that prompted the bead, this gate would have caught none of them as
# they were actually written: claim 1 wrote attempts/<name>/ where the tree
# has attempts/<batch>/<NN_name>/, and `attempts/` resolves either way; claim
# 2 said problems/ "stays empty" in prose while the same file's own
# problems/<NN_name>/ claim resolved fine; claim 3 was an em dash. Saying so
# is the point. A gate whose coverage is overstated is how the next reader
# concludes the file is checked when the part that went wrong is not.
#
# A PLACEHOLDER'S INSTANCE COUNT IS REPORTED AND NEVER FAILED ON. The source
# says a reference lands in released/<NN_name>/ and released/ is empty, which
# is a true statement about a procedure nobody has run yet. Failing on it
# would make the gate red for a reason whose only remedy is weakening the
# prose. Same shape as the conflict counts in the never-overwrite channels:
# counted, named on every run, out of the exit code.
#
# THE DIRECTORIES THE README NEVER NAMES ARE A NUDGE, NOT A GATE. The
# delivered tree holds drill, recall, exercises and completion and the README
# explains none of them. Whether it should is Frank's call, so this prints the
# list on every run and does not fail. Loom's conventions draw that line at
# "is a human supposed to weigh in".
#
# ---------------------------------------------------------------------------
# NOTHING IN THIS SUITE MAY EVER WRITE TO ~/tla-practice
#
# It is not a git repo and it holds the only copy of the work done in it.
# Every delivery here goes into a mktemp fixture root, and the two parts that
# read the real tree read it and nothing else. Parts that invoke a delivery
# sandbox HOME as well as passing an explicit root, so a script that dropped
# its argument still cannot reach the real tree.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

DELIVER="scripts/deliver-practice-root.sh"
SRC_README="practice/README.md"
REAL_ROOT="$HOME/tla-practice"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

WORK=$(mktemp -d -t tla_practice_root.XXXXXX)
SANDBOX_HOME="$WORK/sandbox-home"
mkdir -p "$SANDBOX_HOME"
trap 'rm -rf "$WORK"' EXIT

# Captured rather than piped. A pipeline into a consumer that can close early
# returns 141 under pipefail, and an `if` reads that as "no hits", so a present
# line reports as absent.
DOUT=""
DRC=0
run_deliver() {
  DOUT=$(HOME="$SANDBOX_HOME" "$DELIVER" "$@" 2>&1)
  DRC=$?
}

expect_rc() {
  local label="$1" want="$2"
  if [ "$DRC" = "$want" ]; then
    ok "$label, rc=$want"
  else
    nope "$label, wanted rc=$want and got rc=$DRC"
  fi
}

expect_says() {
  local label="$1" needle="$2"
  if grep -qF -- "$needle" <<<"$DOUT"; then
    ok "$label"
  else
    nope "$label, output carries no '$needle'"
  fi
}

expect_lacks() {
  local label="$1" needle="$2"
  if grep -qF -- "$needle" <<<"$DOUT"; then
    nope "$label, output carries '$needle' and should not"
  else
    ok "$label"
  fi
}

printf 'practice-root delivery gate\n'

# ---------------------------------------------------------------------------
echo
echo "== part 1: the source exists and the manifest is the whole of it =="
# ---------------------------------------------------------------------------

if [ -f "$SRC_README" ]; then
  ok "the practice tree's README has a source at $SRC_README"
else
  nope "no source at $SRC_README, which is the whole of bead tla-xbbb"
fi

if [ -x "$DELIVER" ]; then
  ok "$DELIVER exists and is executable"
else
  nope "$DELIVER is missing or not executable"
fi

# A delivery script that delivers nothing reports success and does nothing.
# Point it at an empty source and it has to refuse.
EMPTY_SRC="$WORK/empty-src"
mkdir -p "$EMPTY_SRC"
EMPTY_OUT=$(HOME="$SANDBOX_HOME" DELIVER_PRACTICE_ROOT_SRC_ROOT="$EMPTY_SRC" \
  "$DELIVER" --check "$WORK/nowhere" 2>&1)
EMPTY_RC=$?
if [ "$EMPTY_RC" -eq 1 ] && grep -qF "nothing to deliver" <<<"$EMPTY_OUT"; then
  ok "an empty source root is refused rather than delivered as a no-op"
else
  nope "an empty source root gave rc=$EMPTY_RC, wanted 1 and 'nothing to deliver'"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 2: the four states, each against its own fixture root =="
# ---------------------------------------------------------------------------

# Absence. Every box but Frank's is in this case, and all of CI, so it comes
# first. A gate that failed here would be red everywhere it does not apply.
run_deliver --verify "$WORK/never-delivered"
expect_rc    "an absent destination root skips" 0
expect_says  "the skip names the path it looked for" "$WORK/never-delivered"
expect_says  "the skip says it is skipping" "Skipping."
expect_lacks "the skip reports nothing stale" "STALE"

# Deliver into a fresh root, then verify. Without this control the drift rows
# below could all be passing because the comparison never ran.
CUR="$WORK/current"
run_deliver "$CUR"
expect_rc   "a first delivery lands the file" 0
expect_says "it says what it delivered" "delivered: $CUR/README.md"

if [ -f "$CUR/.delivered.sha256" ]; then
  ok "the delivery wrote a digest record"
else
  nope "no .delivered.sha256 at $CUR, so the third state has nothing to read"
fi

run_deliver --verify "$CUR"
expect_rc    "a current tree passes" 0
expect_says  "a current tree counts the file as in sync" "1 in sync, 0 stale, 0 conflicted"
expect_lacks "a current tree names nothing stale" "STALE"

# STALE: the source moved and the delivered copy is provably untouched. This
# is the case the whole channel exists for, and it is the only one that fails.
MOVED_SRC="$WORK/moved-src"
cp -r practice "$MOVED_SRC"
printf '\nA line the delivered copy does not have.\n' >>"$MOVED_SRC/README.md"

STALE_ROOT="$WORK/stale"
run_deliver "$STALE_ROOT"
DOUT=$(HOME="$SANDBOX_HOME" DELIVER_PRACTICE_ROOT_SRC_ROOT="$MOVED_SRC" \
  "$DELIVER" --verify "$STALE_ROOT" 2>&1)
DRC=$?
expect_rc   "a delivered copy behind a moved source is stale" 3
expect_says "it names the stale path" "STALE, you have not edited it"
expect_says "it names which file" "$STALE_ROOT/README.md"

# And a delivery closes it, because the record proves he never edited it.
DOUT=$(HOME="$SANDBOX_HOME" DELIVER_PRACTICE_ROOT_SRC_ROOT="$MOVED_SRC" \
  "$DELIVER" "$STALE_ROOT" 2>&1)
DRC=$?
expect_rc   "a delivery over a stale copy succeeds" 0
expect_says "it says it updated an unedited file" "updated, you had not edited it"

# CONFLICT: his edit against a moved source. Reported, never touched, and
# never in the exit code.
CONF_ROOT="$WORK/conflict"
run_deliver "$CONF_ROOT"
printf '\nFranks own annotation.\n' >>"$CONF_ROOT/README.md"
DOUT=$(HOME="$SANDBOX_HOME" DELIVER_PRACTICE_ROOT_SRC_ROOT="$MOVED_SRC" \
  "$DELIVER" --verify "$CONF_ROOT" 2>&1)
DRC=$?
expect_rc   "an edited delivered file is a conflict and not a failure" 0
expect_says "it says the edit is his" "CONFLICT, your edit and a moved source"
expect_says "it counts it as conflicted" "0 in sync, 0 stale, 1 conflicted"

DOUT=$(HOME="$SANDBOX_HOME" DELIVER_PRACTICE_ROOT_SRC_ROOT="$MOVED_SRC" \
  "$DELIVER" "$CONF_ROOT" 2>&1)
DRC=$?
expect_says "a delivery leaves a conflicted file alone" "left alone, it may be your work"
if grep -qF "Franks own annotation." "$CONF_ROOT/README.md"; then
  ok "his annotation survived the delivery"
else
  nope "the delivery overwrote his annotation, which is the one thing it may never do"
fi

# NEVER DELIVERED, inside a root that does exist. Distinguished from an absent
# root on purpose: there the answer is "nothing to compare", here it is "a
# delivery is owed".
GAP_ROOT="$WORK/gap"
mkdir -p "$GAP_ROOT"
run_deliver --verify "$GAP_ROOT"
expect_rc   "a file missing from a tree that exists is a delivery owed" 3
expect_says "it says never delivered rather than edited" "STALE, never delivered"

# NO RECORD. A delivered file nobody has a record for is treated as his work,
# which is the safe reading and the one --adopt exists to narrow.
NOREC="$WORK/norecord"
mkdir -p "$NOREC"
cp "$SRC_README" "$NOREC/README.md"
run_deliver --verify "$NOREC"
expect_rc   "an unrecorded file that equals its source is in sync" 0
run_deliver --adopt "$NOREC"
expect_rc   "--adopt records an unedited delivered file" 0
expect_says "it says it adopted one" "1 file(s) adopted, 0 left unrecorded"

NOREC2="$WORK/norecord2"
mkdir -p "$NOREC2"
printf 'something else entirely\n' >"$NOREC2/README.md"
run_deliver --adopt "$NOREC2"
expect_says "--adopt refuses to record a file that differs from its source" "not adopted"
expect_says "and it counts what it left out" "0 file(s) adopted, 1 left unrecorded"

# --check and --verify answer different questions and they read alike. This is
# the confusion scripts/verify-delivery.sh was written over, so pin it.
run_deliver --check "$CUR"
expect_rc    "--check on a current tree exits 0" 0
expect_says  "--check reports on the file without calling it drift" "already current"
expect_lacks "--check never prints a drift verdict" "STALE"

run_deliver --check --verify "$CUR"
expect_rc   "asking for two modes at once is refused" 1
expect_says "and it says to pick one" "pick one"

# ---------------------------------------------------------------------------
# THE PATH-CLAIM CHECK.
#
# A claim is a backtick span in the README that looks like a relative path. A
# token's LITERAL PREFIX is its leading segments that carry no <placeholder>,
# and that prefix has to resolve. Beyond it, the placeholder segments are
# turned into a glob and the instance count is reported rather than gated,
# for the reason the header gives.
#
# A token is resolved against the DELIVERED tree unless its first segment is
# in REPO_SIDE, in which case it is resolved against this repo. Every token is
# checked somewhere. An exclusion list would let a token be silently dropped,
# and `pilot/` existing in the repo is itself a claim worth checking.
# ---------------------------------------------------------------------------

# First segment -> the repo rather than the practice tree, with the reason the
# README gives for each.
REPO_SIDE=(
  "pilot"    # "References, commentary and answer keys live in the repo under pilot/"
  "scripts"  # "scripts/number-problems.sh --check <root> in the repo validates"
)

repo_side() {
  local first="$1" entry
  for entry in "${REPO_SIDE[@]}"; do
    [ "$first" = "$entry" ] && return 0
  done
  return 1
}

# Prints one path token per line. Selection is deliberately narrow: a span
# with no slash is a file name or a bead id rather than a directory claim, and
# a span carrying $ or ~ or a leading / or . is not a tree-relative path.
extract_claims() {
  local file="$1" spans span tok
  # The backticks are the markdown delimiter this selects on, so they are a
  # literal pattern rather than command substitution. Single quotes are what
  # keeps them literal, which is the thing SC2016 is asking about.
  # shellcheck disable=SC2016
  spans=$(grep -o '`[^`]*`' "$file" | sed -e 's/^`//' -e 's/`$//')
  while IFS= read -r span; do
    tok=${span%% *}
    case "$tok" in
      */*) ;;
      *) continue ;;
    esac
    case "$tok" in
      *'$'*|'~'*|/*|.*|*'*'*) continue ;;
    esac
    case "$tok" in
      [A-Za-z0-9]*) ;;
      *) continue ;;
    esac
    printf '%s\n' "$tok"
  done <<<"$spans" | LC_ALL=C sort -u
}

# literal_prefix <token>: the leading segments with no placeholder in them.
literal_prefix() {
  local tok="$1" out="" seg
  local -a parts
  IFS='/' read -r -a parts <<<"$tok"
  for seg in "${parts[@]}"; do
    [ -n "$seg" ] || continue
    case "$seg" in *'<'*) break ;; esac
    out="$out/$seg"
  done
  printf '%s' "${out#/}"
}

# instance_glob <token>: the whole token with each placeholder turned into a
# glob. <NN_name> is typed, because the two-digit prefix is the one thing the
# README says about that segment and a bare * would assert nothing.
instance_glob() {
  local tok="$1" out="" seg
  local -a parts
  IFS='/' read -r -a parts <<<"$tok"
  for seg in "${parts[@]}"; do
    [ -n "$seg" ] || continue
    case "$seg" in
      '<NN'*) seg='[0-9][0-9]_*' ;;
      *'<'*)  seg='*' ;;
    esac
    out="$out/$seg"
  done
  printf '%s' "${out#/}"
}

CLAIM_TOKENS=0
CLAIM_RESOLVED=0
CLAIM_UNRESOLVED=""
CLAIM_NO_INSTANCE=""

# check_claims <readme> <delivered-root>
check_claims() {
  local readme="$1" root="$2" tok first base prefix glob n
  CLAIM_TOKENS=0
  CLAIM_RESOLVED=0
  CLAIM_UNRESOLVED=""
  CLAIM_NO_INSTANCE=""
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    CLAIM_TOKENS=$((CLAIM_TOKENS + 1))
    first=${tok%%/*}
    if repo_side "$first"; then
      base="$REPO_ROOT"
    else
      base="$root"
    fi
    prefix=$(literal_prefix "$tok")
    if [ -n "$prefix" ] && [ -e "$base/$prefix" ]; then
      CLAIM_RESOLVED=$((CLAIM_RESOLVED + 1))
    else
      CLAIM_UNRESOLVED="$CLAIM_UNRESOLVED $tok"
      continue
    fi
    case "$tok" in
      *'<'*) ;;
      *) continue ;;
    esac
    glob=$(instance_glob "$tok")
    n=$(compgen -G "$base/$glob" | wc -l) || true
    if [ "${n:-0}" -eq 0 ]; then
      CLAIM_NO_INSTANCE="$CLAIM_NO_INSTANCE $tok"
    fi
  done <<<"$(extract_claims "$readme")"
}

# ---------------------------------------------------------------------------
echo
echo "== part 3: the path-claim check, proved on fixtures first =="
# ---------------------------------------------------------------------------

# A fixture tree built to satisfy the real source README. Built by hand rather
# than copied, so the control below passes for a reason this file states.
FIX="$WORK/fixture-practice"
mkdir -p "$FIX/problems/01_bonded-store"
mkdir -p "$FIX/attempts/2026-10-02-fresh-start/01_bonded-store"
mkdir -p "$FIX/attempts/withdrawn-2026-09-04"
mkdir -p "$FIX/released"
: >"$FIX/problems/ORDER"

check_claims "$SRC_README" "$FIX"

# The floor. A selection rule that quietly stops matching would leave every
# assertion below green over an empty set, which is how a gate gets switched
# off by a typo. 8 sits under the 11 the source carried on 2026-10-18.
if [ "$CLAIM_TOKENS" -ge 8 ]; then
  ok "the extractor found $CLAIM_TOKENS path claims in $SRC_README (floor 8)"
else
  nope "the extractor found only $CLAIM_TOKENS path claims (floor 8), so it is not reading the file"
fi

if [ -z "$CLAIM_UNRESOLVED" ]; then
  ok "every path claim resolves against a tree built to satisfy them"
else
  nope "claims that did not resolve against the fixture:$CLAIM_UNRESOLVED"
fi

# The selection rule, pinned in both directions. A floor says the extractor
# matched enough, and says nothing about what it matched. These four spans are
# all in the source README and none of them is a path claim: two file names, a
# bead id, and a command line carrying a placeholder. A rule loose enough to
# take them would send the check hunting for a directory called PROBLEM.md.
SELECTED_CLAIMS=$(extract_claims "$SRC_README")
for span in "PROBLEM.md" "ATTEMPT-LOG.md" "tla-h2cg" "tlc"; do
  if grep -qF -- "$span" <<<"$SELECTED_CLAIMS"; then
    nope "the extractor took '$span', which is not a path claim"
  else
    ok "the extractor leaves '$span' alone"
  fi
done

# And the positive half of the same rule. Without this a selection that took
# nothing at all would pass every row above except the floor.
for want in "problems/<NN_name>/" "attempts/<batch>/<NN_name>/" "problems/ORDER"; do
  if grep -qxF -- "$want" <<<"$SELECTED_CLAIMS"; then
    ok "the extractor takes '$want'"
  else
    nope "the extractor missed '$want', which the README states as a path"
  fi
done

# The RED proof. Take the same README, take one directory away, and the check
# has to name it. Without this row the control above could be passing because
# the resolution never ran.
rmdir "$FIX/released"
check_claims "$SRC_README" "$FIX"
if grep -qF "released/" <<<"$CLAIM_UNRESOLVED"; then
  ok "removing released/ from the tree makes the check name it"
else
  nope "released/ was removed and the check still reported everything resolved"
fi
mkdir -p "$FIX/released"

# The second RED proof, and it is the shape a renamed batch takes. The live
# batch name is a dated literal in the prose, so it rolls over on its own.
mv "$FIX/attempts/2026-10-02-fresh-start" "$FIX/attempts/2026-12-01-batch-two"
check_claims "$SRC_README" "$FIX"
if grep -qF "attempts/2026-10-02-fresh-start/" <<<"$CLAIM_UNRESOLVED"; then
  ok "renaming the live batch makes the check name the stale literal"
else
  nope "the live batch was renamed and the check still reported everything resolved"
fi
mv "$FIX/attempts/2026-12-01-batch-two" "$FIX/attempts/2026-10-02-fresh-start"

# And a planted README naming a directory that was never there.
BAD="$WORK/bad-README.md"
{
  cat "$SRC_README"
  # The backticks are markdown, not command substitution. They have to be
  # literal and inside single quotes, because a backtick span is exactly what
  # the extractor selects on and the planted claim has to look like every
  # other claim in the file.
  # shellcheck disable=SC2016
  printf '\nYour graded work lands in `verdicts/<NN_name>/` once it is scored.\n'
} >"$BAD"
check_claims "$BAD" "$FIX"
if grep -qF "verdicts/" <<<"$CLAIM_UNRESOLVED"; then
  ok "a claim about a directory that does not exist is named"
else
  nope "a planted claim about verdicts/ passed, so the check is not reading new claims"
fi

# The instance count is reported and is not a failure. released/ is there and
# empty, which is a true statement about a procedure nobody has run yet.
check_claims "$SRC_README" "$FIX"
if grep -qF "released/<NN_name>/" <<<"$CLAIM_NO_INSTANCE"; then
  ok "an empty released/ is reported as having no instance yet"
else
  nope "released/ is empty and the instance report did not say so"
fi
if [ -z "$CLAIM_UNRESOLVED" ]; then
  ok "and an empty released/ is not an unresolved claim"
else
  nope "an empty released/ was counted as unresolved:$CLAIM_UNRESOLVED"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 4: the real delivered tree, which is the whole point =="
# ---------------------------------------------------------------------------

# Parts 1 to 3 prove the instrument. This part is the measurement. It reads
# and compares and it writes nothing, because ~/tla-practice is not a git repo
# and has no backup of its own.

if [ ! -d "$REAL_ROOT" ]; then
  ok "no delivered practice tree on this box, so there is nothing to compare"
else
  check_claims "$SRC_README" "$REAL_ROOT"
  if [ -z "$CLAIM_UNRESOLVED" ]; then
    ok "all $CLAIM_RESOLVED path claims in $SRC_README resolve against $REAL_ROOT"
  else
    nope "THE README NAMES DIRECTORIES THE DELIVERED TREE DOES NOT HAVE:$CLAIM_UNRESOLVED"
  fi

  if [ -n "$CLAIM_NO_INSTANCE" ]; then
    echo "        no instance yet, reported and not failed on:$CLAIM_NO_INSTANCE"
  fi

  # The other direction, and it is a nudge rather than a gate. A delivered
  # directory the README never names is a name a learner has to guess at,
  # which is the opposite of what this file is for. Whether each one belongs
  # in the prose is Frank's call, so it prints and never fails.
  unnamed=""
  readme_text=$(cat "$SRC_README")
  for d in "$REAL_ROOT"/*/; do
    [ -d "$d" ] || continue
    name=${d%/}
    name=${name##*/}
    if ! grep -qF -- "$name/" <<<"$readme_text"; then
      unnamed="$unnamed $name"
    fi
  done
  if [ -n "$unnamed" ]; then
    echo "        delivered director(ies) the README never names, which is a nudge and not a failure:$unnamed"
  fi
  ok "the unnamed-directory report ran over $REAL_ROOT"

  # And the delivered copy against the source, through the script's own
  # verify. Exit 3 here is Frank's copy being behind the repo.
  run_deliver --verify "$REAL_ROOT"
  case "$DRC" in
    0) ok "the delivered practice root matches the repo" ;;
    3) nope "THE DELIVERED PRACTICE ROOT IS BEHIND THE REPO. Back up ~/tla-practice, then run $DELIVER."
       printf '%s\n' "$DOUT" | grep -E '^STALE' | sed 's/^/        /'
       ;;
    *) nope "$DELIVER --verify failed with rc=$DRC rather than answering"
       printf '%s\n' "$DOUT" | tail -5 | sed 's/^/        /'
       ;;
  esac
fi

# ---------------------------------------------------------------------------
echo
echo "== part 5: the source is tracked and the prose gates reach it =="
# ---------------------------------------------------------------------------

# This is the half of the invariant that is structural. Before bead tla-xbbb
# the file had no source, so both rows below were red by construction.

TRACKED=$(git ls-files -- "$SRC_README")
if [ -n "$TRACKED" ]; then
  ok "$SRC_README is tracked, so a diff of it exists"
else
  nope "$SRC_README is not tracked, so no gate that selects from git can read it"
fi

# harness/test-spelling.sh selects from tracked files under a root list, so a
# source outside that list is a source the spelling gate reads none of. That
# hole has been found three times in this tree on other roots, always as a
# green run over nothing.
SPELL="harness/test-spelling.sh"
SPELL_ROOTS=$(sed -n 's/^SCAN_ROOTS=(\(.*\))$/\1/p' "$SPELL")
SRC_DIR=${SRC_README%%/*}
if grep -qE "(^| )$SRC_DIR( |\$)" <<<"$SPELL_ROOTS"; then
  ok "$SPELL walks $SRC_DIR/, so it reads the source"
else
  nope "$SPELL's SCAN_ROOTS does not carry $SRC_DIR/, so the spelling gate reads none of it"
fi

# A root with no floor can be switched off by a typo, which is why every other
# root here carries one.
if grep -qE "^  \"$SRC_DIR:[0-9]+\"" "$SPELL"; then
  ok "$SRC_DIR/ carries a per-root floor, so a root that selects nothing reddens"
else
  nope "$SRC_DIR/ has no entry in ROOT_FLOORS, so the root could select nothing and still pass"
fi

echo
printf 'OK: %s assertions passed\n' "$pass_count"
if [ "$fail_count" -gt 0 ]; then
  printf 'FAILED: %s passed, %s failed\n' "$pass_count" "$fail_count"
  exit 1
fi
