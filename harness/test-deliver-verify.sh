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

# The drill channel, which is the one the bead was filed about. `./drill
# --style` came back "unknown option" on 2026-10-15 because the repo had
# carried that option for hours and his copy had not. These two rows are what
# would have said so, and they read the real trees exactly as the row above
# reads the real recall tree: compare, report, write nothing.
DELIVER_DRILL="scripts/deliver-drill.sh"

DRILL_OUT=$("$DELIVER_DRILL" --verify 2>&1)
DRILL_RC=$?
case "$DRILL_RC" in
  0)
    if grep -qF "Skipping." <<<"$DRILL_OUT"; then
      ok "no delivered drill tree on this box, so there is nothing to compare"
    else
      ok "the delivered drill tree matches the repo"
    fi
    ;;
  3)
    nope "THE DELIVERED DRILL TREE IS BEHIND THE REPO. Back up ~/tla-practice, then run $DELIVER_DRILL, and $DELIVER_DRILL --refresh-prompts for any STALE prompt."
    printf '%s\n' "$DRILL_OUT" | grep -E '^(DRIFT|STALE)|drifted' | sed 's/^/        /'
    ;;
  *)
    nope "$DELIVER_DRILL --verify failed with rc=$DRILL_RC rather than answering"
    printf '%s\n' "$DRILL_OUT" | tail -5 | sed 's/^/        /'
    ;;
esac

# The study root, which is where --style actually lives. It is a second tree
# under a root no practice-root argument reaches, so it needs its own row or
# the channel is half checked.
STUDY_OUT=$("$DELIVER_DRILL" --study --verify 2>&1)
STUDY_RC=$?
case "$STUDY_RC" in
  0)
    if grep -qF "Skipping." <<<"$STUDY_OUT"; then
      ok "no delivered study tree on this box, so there is nothing to compare"
    else
      ok "the delivered study tree matches the repo"
    fi
    ;;
  3)
    nope "THE DELIVERED STUDY TREE IS BEHIND THE REPO. Run $DELIVER_DRILL --study after backing it up."
    printf '%s\n' "$STUDY_OUT" | grep -E '^DRIFT|drifted' | sed 's/^/        /'
    ;;
  *)
    nope "$DELIVER_DRILL --study --verify failed with rc=$STUDY_RC rather than answering"
    printf '%s\n' "$STUDY_OUT" | tail -5 | sed 's/^/        /'
    ;;
esac

# --- part 4: the wrapper's channel table covers every delivery script -------
#
# scripts/verify-delivery.sh is the one command the wrap-up ritual names, and
# it refuses to run when a scripts/deliver-*.sh exists that its table does not
# know about. That refusal only fires when somebody runs it, which at wrap-up
# is hours after the new channel landed. Assert the same thing here so a new
# delivery channel cannot merge outside the ritual's reach in the first place.
#
# Frank ruled on 2026-10-18 (bead tla-mjvx) that the ritual, not cibuild, is
# where the delivery check lives. This row is the part of that ruling a gate
# can carry.

echo
echo "== part 4: every delivery channel is in the wrapper's table =="

WRAPPER="$REPO_ROOT/scripts/verify-delivery.sh"
if [ -x "$WRAPPER" ]; then
  ok "scripts/verify-delivery.sh exists and is executable"
else
  nope "scripts/verify-delivery.sh is missing or not executable"
fi

# Strip the assignment prefix off the first line and the closing quote off the
# last, or the first and last channel never match. Caught by this assertion on
# its first run, which is the only reason it is right now.
TABLE=$(sed -n "/^KNOWN_CHANNELS='/,/'\$/p" "$WRAPPER" \
        | sed -e "s/^KNOWN_CHANNELS='//" -e "s/'\$//")
missing=''
for path in "$REPO_ROOT"/scripts/deliver-*.sh; do
  [ -e "$path" ] || continue
  base=${path##*/deliver-}
  base=${base%.sh}
  if ! grep -qx -- "$base" <<<"$TABLE"; then
    missing="$missing $base"
  fi
done
if [ -z "$missing" ]; then
  ok "every scripts/deliver-*.sh appears in KNOWN_CHANNELS"
else
  nope "delivery channel(s) absent from the wrapper's table:$missing"
fi

# The other direction. A table entry naming a script that no longer exists is
# how a channel gets silently dropped from the ritual after a rename.
stale_entry=''
while read -r ch; do
  [ -n "$ch" ] || continue
  if [ ! -f "$REPO_ROOT/scripts/deliver-$ch.sh" ]; then
    stale_entry="$stale_entry $ch"
  fi
done <<<"$TABLE"
if [ -z "$stale_entry" ]; then
  ok "every KNOWN_CHANNELS entry names a script that exists"
else
  nope "table entr(ies) naming a script that is gone:$stale_entry"
fi

# And it degrades on a box with no delivered tree, which is every box but
# Frank's and all of CI. Absence is a skip and never a failure.
ABSENT_OUT=$("$WRAPPER" "$WORK/no-such-practice-root" 2>&1)
ABSENT_RC=$?
if [ "$ABSENT_RC" -eq 0 ] && grep -qF "Skipping." <<<"$ABSENT_OUT"; then
  ok "the wrapper skips and exits 0 when there is no delivered tree"
else
  nope "the wrapper gave rc=$ABSENT_RC on an absent practice root, wanted 0 with a skip"
fi

# It must name the unchecked channels on any run that actually compared
# something, or a green run claims more than it looked at. The absent-root
# path above exits before the report, so this needs a present-but-empty tree.
#
# The first version of this assertion was `grep NOT CHECKED || rc -eq 0`,
# which passed through the rc arm on every run and could not fail. Noted here
# because an or-ed fallback is the quiet way a control goes vacuous.
#
# AND EVERY CHANNEL THE WRAPPER CALLS HAS TO BE SATISFIED HERE, not only the
# one a row is about. This row asserts on the wrapper's AGGREGATE exit code,
# so any channel reporting a finding reddens it. practice-root delivers to the
# practice root itself rather than to a subdirectory, so a root that exists at
# all is one it will compare, and an empty root is one file owed. Delivering it
# leaves the root non-empty, which is what this row needed anyway: a run that
# compared something. Added 2026-10-18 with bead tla-xbbb.
EMPTY_ROOT="$WORK/empty-practice"
mkdir -p "$EMPTY_ROOT"
# Its own sandbox HOME rather than part 5's. That one is defined per-invocation
# on purpose, because part 3 wants the real HOME, so hoisting it to the top of
# the file would quietly change what part 3 tests.
EMPTY_SANDBOX_HOME="$WORK/empty-sandbox-home"
mkdir -p "$EMPTY_SANDBOX_HOME"
HOME="$EMPTY_SANDBOX_HOME" "$REPO_ROOT/scripts/deliver-practice-root.sh" \
  "$EMPTY_ROOT" >/dev/null 2>&1
EMPTY_OUT=$("$WRAPPER" "$EMPTY_ROOT" 2>&1)
EMPTY_RC=$?
if [ "$EMPTY_RC" -eq 0 ] && grep -qF "NOT CHECKED" <<<"$EMPTY_OUT"; then
  ok "a run that compared something still names the channels it did not check"
else
  nope "the wrapper gave rc=$EMPTY_RC on an empty tree and may not have named the unchecked channels"
fi

# The other direction, and it is the row that would catch a channel being
# listed as unchecked while a call for it sits right above. Until 2026-10-18
# this block read drill, completion and problems. All three gained a verify
# mode in bead tla-mjvx, so naming any of them here would now be a false
# report.
NOTCHECKED=$(sed -n '/^NOT CHECKED/,$p' <<<"$EMPTY_OUT")
still_listed=''
for ch in completion problems drill; do
  if grep -qE "^  $ch\$" <<<"$NOTCHECKED"; then
    still_listed="$still_listed $ch"
  fi
done
if [ -z "$still_listed" ]; then
  ok "a channel that has a verify mode is no longer listed as unchecked"
else
  nope "channel(s) listed as unchecked although they have a verify mode:$still_listed"
fi

# And the positive half: the wrapper actually CALLED them. Without this row the
# one above would pass just as well if the calls had been deleted rather than
# added, since a channel nobody calls is also a channel nobody lists.
#
# IT READS ONLY THE PART OF THE REPORT ABOVE "NOT CHECKED", and that is not
# tidiness. A name listed as unchecked sits two spaces in exactly like a result
# row, so a whole-output grep passed for drill on 2026-10-18 while the wrapper
# had never called it. A control that the thing it is checking for can satisfy
# from the wrong block is a control that cannot fail.
REPORTED=$(sed -n '1,/^NOT CHECKED/p' <<<"$EMPTY_OUT")
for ch in completion problems drill; do
  if grep -qE "^  $ch( |\$)" <<<"$REPORTED"; then
    ok "the wrapper reports a result for the $ch channel"
  else
    nope "the wrapper never reported on the $ch channel at all"
  fi
done

# The study tree is the one root this wrapper cannot derive from its argument.
# drill/drill.sh creates it where the learner practices, so it comes from
# DRILL_STUDY_ROOT or from $HOME/Study/tla-drills, and the run has to say which
# root it read or the reader cannot tell what was compared.
if grep -qE '^  drill study( |$)' <<<"$REPORTED"; then
  ok "the wrapper reports a result for the drill study root too"
else
  nope "the wrapper never reported on the drill study root"
fi

if grep -qF "drill study root:" <<<"$EMPTY_OUT"; then
  ok "and names the study root it read, which no argument of this script selects"
else
  nope "the wrapper never said which study root it compared"
fi

# The NOT CHECKED block still prints, and now it has to say that nothing is
# left out rather than printing a header over an empty list. A heading claiming
# unchecked channels with none under it reads as truncated output.
if grep -qE 'NOT CHECKED: no channel is left out' <<<"$EMPTY_OUT"; then
  ok "with every channel covered, the block says so rather than listing nothing"
else
  nope "the NOT CHECKED block does not state that every channel is covered"
fi

# --- part 5: a never-overwrite channel's drift reaches the wrapper's rc -----
#
# Parts 1 to 4 prove the wrapper's table and its skip. This part proves the one
# thing the ritual depends on: that a stale file in a never-overwrite channel
# turns the whole command red. It builds a tree that is stale against a source
# nobody may edit, which takes the record: deliver, change one delivered byte,
# then record THAT byte as the delivered digest. Disk now matches the record
# and differs from the source, which is exactly the state a merged repair
# leaves behind.
#
# Writing a record by hand is a thing only a fixture may do. The whole safety
# argument of the record is that only a delivery writes an entry, and this
# suite is standing in for one delivery that already happened.

echo
echo "== part 5: a stale never-overwrite channel turns the wrapper red =="

STALE_ROOT="$WORK/stale-practice"
mkdir -p "$STALE_ROOT"
DELIVER_COMPLETION="$REPO_ROOT/scripts/deliver-completion.sh"

# This part DELIVERS, where every part above only reads, so it is the one
# place in this suite that sandboxes HOME. Both runs already pass an explicit
# root under $WORK; the redirect is what covers a script that dropped its
# argument, because the default root resolves from HOME and the real one has
# no git behind it. Part 3 deliberately keeps the real HOME, which is why this
# is per-invocation rather than at the top of the file.
SANDBOX_HOME="$WORK/sandbox-home"
mkdir -p "$SANDBOX_HOME"

PLANT_OUT=$(HOME="$SANDBOX_HOME" "$DELIVER_COMPLETION" all "$STALE_ROOT/completion" 2>&1)
PLANT_RC=$?
# sort consumes its whole input, so this pipeline has no early-exiting
# consumer. The first line comes off the captured string instead of from a
# head, which under pipefail returns 141 and reports a found file as absent.
PLANT_LIST=$(find "$STALE_ROOT/completion" -name 'PROMPT.md' | LC_ALL=C sort)
PLANTED=${PLANT_LIST%%$'\n'*}
if [ "$PLANT_RC" -eq 0 ] && [ -n "$PLANTED" ]; then
  ok "the completion corpus delivers into a sandbox root, so part 5 has a tree to work on"
else
  nope "could not plant a completion tree (rc=$PLANT_RC): $(tr '\n' ' ' <<<"$PLANT_OUT")"
fi

if [ -n "$PLANTED" ]; then
  PLANTED_DIR=${PLANTED%/*}
  printf '\na line the repo does not have\n' >>"$PLANTED"
  printf '%s  %s\n' "$(sha256sum -- "$PLANTED" | cut -d' ' -f1)" "PROMPT.md" \
    >>"$PLANTED_DIR/.delivered.sha256"

  STALE_WRAP=$(HOME="$SANDBOX_HOME" "$WRAPPER" "$STALE_ROOT" 2>&1)
  STALE_WRAP_RC=$?
  if [ "$STALE_WRAP_RC" -eq 3 ]; then
    ok "a stale completion file makes the wrapper exit 3"
  else
    nope "the wrapper exited $STALE_WRAP_RC over a stale completion tree, wanted 3"
  fi

  if grep -qE '^  completion$' <<<"$(sed -n '/^DRIFTED/,$p' <<<"$STALE_WRAP")"; then
    ok "the wrapper names completion under DRIFTED"
  else
    nope "the wrapper exited $STALE_WRAP_RC without naming completion as drifted"
  fi

  if grep -qF -- "$PLANTED" <<<"$STALE_WRAP"; then
    ok "the wrapper's detail block carries the stale path itself"
  else
    nope "the wrapper reported drift without naming $PLANTED"
  fi

  # And it wrote nothing while doing it. The whole wrapper is a read.
  if grep -qF 'a line the repo does not have' "$PLANTED"; then
    ok "the wrapper left the planted file exactly as it found it"
  else
    nope "the wrapper rewrote $PLANTED, and it must never write anywhere"
  fi
fi

# --- part 6: the drill channel's two findings both reach the wrapper --------
#
# Part 5 proves one never-overwrite channel's drift turns the command red.
# Drill is the channel the bead was filed about and the only one with two file
# classes, so both of its findings need a row: a STALE prompt, which only
# --refresh-prompts can replace, and a DRIFT on an always-overwritten file,
# which a plain run lands. A wrapper that greps for one word would report the
# other as clean.
#
# THE CONFLICT ROW MATTERS AS MUCH AS THE TWO FAILURES. Frank annotates his
# prompts, and a wrapper that went red on an annotation would be red every
# night for a reason nobody can act on.

echo
echo "== part 6: the drill channel's stale and drifted findings both land =="

DRILL_ROOT="$WORK/drill-practice"
mkdir -p "$DRILL_ROOT"

# The rows below read the wrapper's AGGREGATE exit code to say something about
# drill, so every other channel it calls has to be in sync or the reading is
# about the wrong thing. Five of the seven skip here, because their trees are
# absent. practice-root does not: its destination IS this root, so it compares
# the moment the root exists and reports the README owed. Deliver it once and
# the rc these rows read is drill's alone. Added 2026-10-18 with bead tla-xbbb.
HOME="$SANDBOX_HOME" "$REPO_ROOT/scripts/deliver-practice-root.sh" \
  "$DRILL_ROOT" >/dev/null 2>&1

DRILL_PLANT=$(HOME="$SANDBOX_HOME" "$DELIVER_DRILL" "$DRILL_ROOT/drill" 2>&1)
DRILL_PLANT_RC=$?
DRILL_PROMPT_LIST=$(find "$DRILL_ROOT/drill" -name 'PROMPT.md' | LC_ALL=C sort)
DRILL_PROMPT=${DRILL_PROMPT_LIST%%$'\n'*}
if [ "$DRILL_PLANT_RC" -eq 0 ] && [ -n "$DRILL_PROMPT" ]; then
  ok "the drill corpus delivers into a sandbox root, so part 6 has a tree to work on"
else
  nope "could not plant a drill tree (rc=$DRILL_PLANT_RC): $(tr '\n' ' ' <<<"$DRILL_PLANT")"
fi

# A clean tree first, or the two red rows below could both be passing because
# the comparison never ran.
CLEAN_WRAP=$(HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$WORK/no-study-root" \
  "$WRAPPER" "$DRILL_ROOT" 2>&1)
CLEAN_WRAP_RC=$?
CLEAN_REPORTED=$(sed -n '1,/^NOT CHECKED/p' <<<"$CLEAN_WRAP")
if [ "$CLEAN_WRAP_RC" -eq 0 ] && grep -qE '^  drill( |$)' <<<"$CLEAN_REPORTED"; then
  ok "a freshly delivered drill tree reports in sync"
else
  nope "the wrapper exited $CLEAN_WRAP_RC over a fresh drill tree, wanted 0 with drill in sync"
fi

if [ -n "$DRILL_PROMPT" ]; then
  # A prompt the learner has annotated. It differs from the record, so it is
  # his and the wrapper must stay green over it.
  printf '\nmy own notes under the question\n' >>"$DRILL_PROMPT"

  HIS_WRAP=$(HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$WORK/no-study-root" \
    "$WRAPPER" "$DRILL_ROOT" 2>&1)
  HIS_WRAP_RC=$?
  if [ "$HIS_WRAP_RC" -eq 0 ]; then
    ok "a prompt he has annotated leaves the wrapper green"
  else
    nope "the wrapper exited $HIS_WRAP_RC over an annotated prompt, wanted 0"
  fi
  if grep -qF 'are your own work and were left alone' <<<"$HIS_WRAP"; then
    ok "and it is counted as his work in the drill row"
  else
    nope "the drill row never counted the annotated prompt as his own work"
  fi

  # Now the same file as a STALE one. Recording the byte on disk as the
  # delivered digest is standing in for a delivery that already happened, which
  # is a thing only a fixture may do: the whole safety argument of the record is
  # that only a delivery writes an entry.
  DRILL_PROMPT_DIR=${DRILL_PROMPT%/*}
  printf '%s  %s\n' "$(sha256sum -- "$DRILL_PROMPT" | cut -d' ' -f1)" "PROMPT.md" \
    >>"$DRILL_PROMPT_DIR/.delivered.sha256"

  STALE_DRILL=$(HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$WORK/no-study-root" \
    "$WRAPPER" "$DRILL_ROOT" 2>&1)
  STALE_DRILL_RC=$?
  if [ "$STALE_DRILL_RC" -eq 3 ]; then
    ok "a stale drill prompt makes the wrapper exit 3"
  else
    nope "the wrapper exited $STALE_DRILL_RC over a stale drill prompt, wanted 3"
  fi
  if grep -qE '^  drill$' <<<"$(sed -n '/^DRIFTED/,$p' <<<"$STALE_DRILL")"; then
    ok "the wrapper names drill under DRIFTED"
  else
    nope "the wrapper exited 3 without naming drill as drifted"
  fi
  if grep -qF -- "$DRILL_PROMPT" <<<"$STALE_DRILL"; then
    ok "and its detail block carries the stale prompt itself"
  else
    nope "the wrapper reported drill drift without naming $DRILL_PROMPT"
  fi

  # The other file class, and the reason this part has two halves. A DRIFT line
  # is a different word from a STALE one, so a detail block grepping for only
  # one of them would come back empty on a real finding.
  rm -f "$DRILL_ROOT/drill/SHEET.md"
  SHEET_DRILL=$(HOME="$SANDBOX_HOME" DRILL_STUDY_ROOT="$WORK/no-study-root" \
    "$WRAPPER" "$DRILL_ROOT" 2>&1)
  SHEET_DRILL_RC=$?
  if [ "$SHEET_DRILL_RC" -eq 3 ] &&
     grep -qF "DRIFT, never delivered: $DRILL_ROOT/drill/SHEET.md" <<<"$SHEET_DRILL"; then
    ok "an always-overwritten file that never landed reaches the detail block too"
  else
    nope "the wrapper gave rc=$SHEET_DRILL_RC and did not name the missing sheet"
  fi
fi

echo
printf 'OK: %s assertions passed\n' "$pass_count"
if [ "$fail_count" -gt 0 ]; then
  printf 'FAILED: %s passed, %s failed\n' "$pass_count" "$fail_count"
  exit 1
fi
