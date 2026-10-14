#!/usr/bin/env bash
# test-drill.sh — the gate for the blank-page drill corpus.
#
# THE DEFECT THIS EXISTS TO STOP. Six authors produce drill items in parallel
# and nobody reads forty to sixty of them by hand. So whatever
# harness/drill-gate.sh checks is what the corpus is guaranteed to be, and
# this suite is that instrument's controls: it proves the instrument still
# bites, in both directions, against fixtures built to be caught.
#
# Read harness/drill-gate.sh's header for what each of the three checks does
# and — the half that matters more — what each one deliberately does not.
# This file does not restate those boundaries; it would drift from them.
#
# TWO OF THE THREE CHECKS GATE. ONE ONLY REPORTS.
#
#   check 1, TELEGRAPH    — fails. Whether an ITEM is honest is a property of
#                           the item.
#   check 2, VERIFICATION — fails. Whether an item's recorded verdict
#                           REPRODUCES is a property of the item.
#   check 3, COVERAGE     — PRINTS, and never fails. Whether the CORPUS covers
#                           the inventory is a property of a set that is still
#                           being written, and gating it would make the set's
#                           shape serve the gate. Part 1d is the pin that
#                           keeps the failing arm removed.
#
# A FOURTH CHECK LIVES HERE AND NOT IN THE GATE: the delivery shape, which
# asserts that every item's top-level entry set is exactly ANSWER.md, META.md,
# PROMPT.md and verify. Do not go looking for it in harness/drill-gate.sh. It
# guards scripts/deliver-drill.sh's one-name manifest rather than anything
# about an item's honesty, it runs in all three invocations, and THE DELIVERY
# SHAPE section below says why it is gated rather than written down.
#
# PART 1  the checks, each against a fixture built to trip it
# PART 2  controls the other way: shapes that LOOK wrong and must not fire
# PART 3  the real drill/ tree, and the delivery shape
#
# Usage:  harness/test-drill.sh [--static | --full-sweep]
# Exit:   0 if all assertions hold, 1 otherwise.
#
# ---------------------------------------------------------------------------
# THREE INVOCATIONS, ONE PER TIER, AND EACH ANSWERS ITS OWN QUESTION.
#
#   invocation     parts run          part 3 asks the real tree          caller
#   -------------  -----------------  ---------------------------------  ------
#   --static       3 only             is the corpus STRUCTURALLY sound   test
#                                     (--static-only)                    --fast
#   (unflagged)    1, 2, 2b-2e, 3     did anything I just changed stop   test
#                                     reproducing (--changed-only -P8)   default
#   --full-sweep   3 only             does EVERY recorded rc still       cibuild
#                                     reproduce on this build (-P8)
#
# THE FLAGS ARE NOT A VOLUME KNOB ON ONE GATE. Each invocation exits 0 only if
# its own question is answered yes, and each states what it did not ask — the
# static arm asserts the gate printed the count of rcs it did not reproduce,
# and the changed-only arm asserts it printed what came from cache. A tier
# that is silent about its own altitude is the batch-1 grading defect arriving
# again (bd memory the-batch-1-grading-round-closed-2026-09): a capability
# that existed and was optional, so the gate's strength was whatever the
# caller happened to pass.
#
# WHAT --static DOES NOT COVER, and the row's comment in scripts/test says so
# too. Parts 1, 2, 2b and 2c to 2e are this INSTRUMENT's own controls, and
# four of their fixtures run real TLC, so they stay in the slow tier. The fast
# row therefore asserts a property of the corpus using an instrument whose
# controls ran elsewhere. That is not a weakening — the whole suite is slow
# today and the fast tier asserts nothing at all about drill/ — but it is the
# kind of thing that has to be written down rather than noticed later.
#
# AN UNKNOWN OPTION IS A USAGE ERROR, rc 2, and that matters more than it
# looks. This file took no arguments at all until bead tla-0eis.3, so a
# mistyped `--statc` in scripts/test would have been IGNORED and run the whole
# slow suite inside the fast tier, where the only symptom is a budget nudge
# nobody reads as a wiring bug.
#
# ---------------------------------------------------------------------------
# WHY THIS IS A SLOW-TIER SUITE, unflagged. It drives harness/verdict.sh
# against real fixtures, so it runs TLC's MODEL CHECKER. By the rule in
# scripts/test's header the boundary is the model checker and not the JVM, so
# this belongs in slow whatever it costs today. Four of its TLC runs are in
# part 1; every other fixture runs under --no-tlc, which is also what keeps
# the suite's cost flat as the fixture count grows.
#
# ITS COST TRACKS THE CORPUS, not this file. Part 3 verifies every checkable
# module of every real item, so the budget recorded in scripts/test grows as
# authors land items. That is the honest statement rather than a number that
# will be wrong next week.
# ---------------------------------------------------------------------------

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

GATE="${REPO_ROOT}/harness/drill-gate.sh"

# How many ways part 3 runs check 2's TLC queue in the two modes that have
# one. Eight, measured rather than picked: the tla-0eis.2 worker read 39.8 s
# at -P8 against 81.1 s serial over the 32-item tree, which is 2.0x and not
# 8x, because each TLC already runs about three cores wide. Raising it buys
# very little and costs the box.
JOBS=8

# SUITE_MODE picks which parts run and which question part 3 puts to the real
# tree. See THREE INVOCATIONS in the header. The default is the whole suite.
SUITE_MODE="controls"
case "${1:-}" in
  "") ;;
  --static)     SUITE_MODE="static" ;;
  --full-sweep) SUITE_MODE="full" ;;
  -h|--help)
    # Print the header block, stopping at the first line of code, the same way
    # scripts/test --help does rather than at a line number that drifts.
    awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *)
    echo "test-drill.sh: unknown option '$1' (try --help)" >&2
    echo "  Expected one of: --static, --full-sweep, or no argument." >&2
    exit 2
    ;;
esac
if [ "$#" -gt 1 ]; then
  echo "test-drill.sh: takes at most one option, got $# ($*)" >&2
  exit 2
fi

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

if [ ! -x "$GATE" ]; then
  echo "test-drill.sh: ${GATE} is missing or not executable — refusing to report success." >&2
  exit 2
fi

TMP="$(mktemp -d)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

GATE_OUT=""
GATE_RC=0

# run_gate <args...>: captures the instrument's combined output and its rc.
run_gate() {
  GATE_OUT="$(bash "$GATE" "$@" 2>&1)"
  GATE_RC=$?
}

# run_gate_with_tlc <bindir> <args...>: the same run with <bindir> ahead of
# PATH, so `command -v tlc` inside the gate finds the fixture wrapper there.
#
# harness/verdict.sh calls `tlc` by name too, so the fixture serves every TLC
# the corpus needs and not just the gate's key. That is why each fixture
# wrapper in part 2e has to work rather than only parse. A wrapper that
# refused to run would turn those rows into a question about findings.
run_gate_with_tlc() {
  local bindir="$1"
  shift
  GATE_OUT="$(PATH="${bindir}:${PATH}" bash "$GATE" "$@" 2>&1)"
  GATE_RC=$?
}

# Assertions read GATE_OUT through a HERE-STRING, never a pipe. A pipe into
# `grep -q` returns 141 under pipefail, which inside an `if` reads as "pattern
# absent" — so a present finding would report as missing and the control would
# pass on a broken instrument. That is the false-PASS direction, and
# harness/test-pipefail.sh bans the idiom outright (bead tla-kr9).
has() {
  if grep -qF -- "$2" <<<"$GATE_OUT"; then ok "$1"; else nope "$1 — expected in output: $2"; fi
}
hasnt() {
  if grep -qF -- "$2" <<<"$GATE_OUT"; then nope "$1 — must NOT be in output: $2"; else ok "$1"; fi
}
rc_is() {
  if [ "$GATE_RC" = "$2" ]; then ok "$1"; else nope "$1 — rc=${GATE_RC}, want $2"; fi
}

# ===========================================================================
# FIXTURE BUILDERS
#
# Every fixture starts from ONE baseline good item and is then mutated in
# exactly one place. That is deliberate: a fixture that differs from the
# passing one in two ways does not tell you which difference the instrument
# reacted to.
# ===========================================================================

# mk_inventory <root> [--with-gap]
#
# `~>` is the covered high construct. EXCEPT and CHOOSE sit at medium and low
# and are left empty on purpose, because an empty medium row must print as a
# gap and must NOT fail — that is the frequency weighting, and a fixture where
# every row is covered would not test it.
# Written through QUOTED heredocs rather than printf. The cells carry
# backticks, and a backtick inside a single-quoted printf format raises
# SC2016 at shellcheck's default severity, which scripts/lint runs at. A
# quoted heredoc carries the same bytes and is clean, so this is a real fix
# rather than eight per-site disables.
mk_inventory() {
  local root="$1" gap="${2:-}"
  cat >"${root}/INVENTORY.md" <<'INV'
# Drill construct inventory

| construct | family | expected frequency |
|---|---|---|
| `~>` leads-to | liveness | high |
| `<>` eventually | liveness | medium |
| `EXCEPT` function update | functions | medium |
| `CHOOSE` | logic | low |
INV
  if [ "$gap" = "--with-gap" ]; then
    cat >>"${root}/INVENTORY.md" <<'GAP'
| `WF_` weak fairness | liveness | high |
GAP
  fi
}

# mk_item <root> <family/NN-slug>: the baseline that must PASS everything.
mk_item() {
  # Separate assignments on purpose: a single `local a=$1 b=${a}/x` expands
  # every right-hand side BEFORE the builtin assigns any of them, so `b`
  # would be built from an empty `a`.
  local root="$1" rel="$2"
  local d="${root}/${rel}"
  mkdir -p "${d}/verify"

  # A prose prompt. It states the requirement in English and shows no code,
  # which is the format's usual shape.
  cat >"${d}/PROMPT.md" <<'PROMPT'
# The dispatcher

A dispatcher holds one ticket. Each turn it may close the ticket it is
holding. Once closed, it stays closed.

Write the requirement that says: a pending ticket is eventually closed.
PROMPT

  cat >"${d}/ANSWER.md" <<'ANSWER'
# Answer

```
Served == (s = 0) ~> (s = 1)
```

Acceptable variants: the equivalent `[]((s = 0) => <>(s = 1))`.

why-not-in-prompt: the prompt states the requirement in English and never
shows a temporal operator, so the symbol has to be recalled rather than read
off. The residual risk is domain smell — a reader who has met a
request-served example before may recall leads-to from the shape of the
domain rather than by deriving it. No gate catches that.

| module | cfg | rc |
|---|---|---|
| Good | Good.cfg | 0 |
| Wrong | Wrong.cfg | 13 |
ANSWER

  cat >"${d}/META.md" <<'META'
# Meta

Constructs: `~>` leads-to
Shape: 2
Time estimate: 6 min
META

  # The stated answer. Weak fairness on the one action makes leads-to hold.
  cat >"${d}/verify/Good.tla" <<'TLA'
---- MODULE Good ----
EXTENDS Naturals
VARIABLE s
Init == s = 0
Up == s = 0 /\ s' = 1
Next == Up
Spec == Init /\ [][Next]_s /\ WF_s(Up)
Served == (s = 0) ~> (s = 1)
====
TLA
  cat >"${d}/verify/Good.cfg" <<'CFG'
SPECIFICATION Spec
PROPERTY Served
CFG

  # A stated WRONG answer: the same property with the fairness dropped, so
  # stuttering refutes it. rc 13 — a liveness violation, measured.
  cat >"${d}/verify/Wrong.tla" <<'TLA'
---- MODULE Wrong ----
EXTENDS Naturals
VARIABLE s
Init == s = 0
Up == s = 0 /\ s' = 1
Next == Up
Spec == Init /\ [][Next]_s
Served == (s = 0) ~> (s = 1)
====
TLA
  cat >"${d}/verify/Wrong.cfg" <<'CFG'
SPECIFICATION Spec
PROPERTY Served
CFG
}

# ===========================================================================
# THE DELIVERY SHAPE, and why it is gated rather than written down.
#
# scripts/deliver-drill.sh delivers PROMPT.md BY NAME. Its sibling
# scripts/deliver-problems.sh refuses to name a single file and says why at
# length in its own header: on 2026-10-02 a guessed manifest deleted 39
# delivered files, among them bonded-store's BondedStore.tla. Naming a file is
# only safe here because the row below holds the shape still.
#
# An undeclared entry reddens this suite and names itself, so whoever adds one
# decides whether it is deliverable before it can land. The alternative design
# was an exclusion list, and it fails UNSAFE: the next answer-bearing file
# lands by default, and the list drifts from the tree the moment somebody adds
# one. So this row is the other half of a one-name manifest rather than a
# tidiness check. Drop it and deliver-drill.sh becomes the 2026-10-02 defect.
#
# HIDDEN ENTRIES COUNT, in both halves. deliver-drill.sh reads the item
# directory with dotfiles included and withholds any it finds, and this row
# reports one, so neither half tolerates what the other does not.
DRILL_ITEM_SHAPE="ANSWER.md META.md PROMPT.md verify"

# item_entries <item-dir>: the item's top-level entry names, sorted, one line,
# space separated. find and not ls, because find is what deliver-drill.sh reads
# the same set with.
item_entries() {
  local dir="$1" out
  out="$(find "$dir" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort | tr '\n' ' ')"
  printf '%s' "${out% }"
}

# shape_arm <drill-root> <item-count>
#
# One PASS when every item carries exactly the four entries, or one FAIL per
# item that does not, naming what it carries that the delivery script cannot
# classify and what it is missing.
#
# THE ITEM COUNT IS PASSED IN as the non-vacuity control. A row reporting that
# all 32 items carry the shape after looking at none is the false-PASS
# direction, and it is the one that matters here, because the thing on the
# other side of it is a script that names a filename.
shape_arm() {
  local root="$1" count="$2"
  local item rel got extras missing entry seen=0 bad=0
  local -a got_arr=() want_arr=()
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    seen=$((seen + 1))
    rel="${item#"$root/"}"
    got="$(item_entries "$item")"
    [ "$got" = "$DRILL_ITEM_SHAPE" ] && continue
    bad=$((bad + 1))
    extras=""
    missing=""
    read -r -a got_arr <<<"$got"
    read -r -a want_arr <<<"$DRILL_ITEM_SHAPE"
    for entry in "${got_arr[@]}"; do
      case " ${DRILL_ITEM_SHAPE} " in
        *" ${entry} "*) ;;
        *) extras="${extras} ${entry}" ;;
      esac
    done
    for entry in "${want_arr[@]}"; do
      case " ${got} " in
        *" ${entry} "*) ;;
        *) missing="${missing} ${entry}" ;;
      esac
    done
    nope "real tree, delivery shape: drill/${rel} carries undeclared [${extras# }] and is missing [${missing# }]"
    echo "        Every item's top-level entries must be exactly: ${DRILL_ITEM_SHAPE}"
    echo "        scripts/deliver-drill.sh delivers PROMPT.md by name and withholds"
    echo "        every other entry, so an undeclared one is an entry nobody has"
    echo "        classified. Decide whether it is deliverable, then say so here and"
    echo "        in that script. Read its WHY THIS SCRIPT NAMES A FILE section first."
  done < <(find "$root" -mindepth 2 -maxdepth 2 -type d \
    ! -name '.*' ! -path "$root/.*" | LC_ALL=C sort)

  if [ "$seen" -ne "$count" ]; then
    nope "real tree, delivery shape: looked at ${seen} item(s) out of ${count}, so the row proves nothing"
    return 0
  fi
  if [ "$bad" -eq 0 ]; then
    ok "real tree, delivery shape: all ${count} item(s) carry exactly ${DRILL_ITEM_SHAPE}"
  fi
}

# ===========================================================================
# PART 3, AS A FUNCTION, because two of the three invocations run it ALONE.
#
# It is defined up here and called at the bottom of the file, where part 3
# reads in sequence. The definition has to precede the --static and
# --full-sweep dispatch, which runs this arm and exits before part 1 builds a
# single fixture — that early exit is the whole reason the fast row is 1.4 s
# and not 106 s.
#
# THREE STATES, AND ONLY THE THIRD CAN FAIL, in every mode. The distinction is
# what keeps this suite from going red on a corpus that is simply not written
# yet, while still biting the moment a real item lands with a defect.
#
#   drill/ absent       — nothing to guarantee. Reported, never failed.
#   drill/ with 0 items — a corpus under construction. The inventory may
#                         already be there and the authors are mid-flight.
#                         The gate returns 99 over it, correctly, because it
#                         was asked to check items and found none. That is a
#                         true statement about the instrument and NOT a
#                         defect in the tree, so it is reported and not
#                         failed. The coverage audit still prints.
#   drill/ with items   — gated, hard. rc 0 or this suite is red.
#
# The middle state is the one worth being deliberate about. Six authors are
# writing into drill/ right now, so a suite that failed the moment the
# directory appeared would be red for every other agent in the repo over
# work that is proceeding normally. It is also why --static goes through this
# suite rather than straight at the gate from scripts/test: wired to the gate,
# the fast row would be red on every tree without items, since the gate
# correctly returns 99 over an empty root.
#
# STATES 1 AND 2 DO NOT VARY BY MODE. Neither can fail, so the question the
# mode asks has no answer to give there, and state 2 keeps --no-tlc because
# what it is for is printing the coverage audit.
real_tree_arm() {
  local DRILL_ITEMS=0
  if [ -d "${REPO_ROOT}/drill" ]; then
    # The hidden-dir predicate is anchored at the drill root. `-not -path
    # '*/.*'` would match REPO_ROOT itself, since every worker here runs under
    # .claude/worktrees/agent-*, and the count would be 0 on any real tree.
    DRILL_ITEMS="$(find "${REPO_ROOT}/drill" -mindepth 2 -maxdepth 2 -type d \
      ! -name '.*' ! -path "${REPO_ROOT}/drill/.*" | wc -l)"
  fi

  if [ ! -d "${REPO_ROOT}/drill" ]; then
    ok "real tree: drill/ does not exist yet — nothing to guarantee, and that is reported rather than passed over"
    echo "        The gate bites the moment an item lands. Until then this row is a"
    echo "        statement about the tree, not a check that ran."
    return 0
  fi

  if [ "$DRILL_ITEMS" -eq 0 ]; then
    run_gate --no-tlc "${REPO_ROOT}/drill"
    ok "real tree: drill/ exists and holds no item yet — the coverage audit below is the aim for the next wave"
    printf '%s\n' "$GATE_OUT" | sed 's/^/        /'
    echo "        rc=${GATE_RC} from the gate, and NOT a failure here. It was asked to check"
    echo "        items and found none, which is a fact about the instrument rather than a"
    echo "        defect in the tree. This row gates as soon as one item exists."
    return 0
  fi

  # State 3. The delivery shape runs first and in every mode, because it costs
  # one find per item and it is the row scripts/deliver-drill.sh's one-name
  # manifest rests on. See THE DELIVERY SHAPE above.
  shape_arm "${REPO_ROOT}/drill" "$DRILL_ITEMS"

  # And the mode decides WHICH question gets put to the tree.
  local -a gate_args=()
  local what=""
  case "$SUITE_MODE" in
    static)
      gate_args=(--static-only)
      what="static sweep"
      ;;
    full)
      gate_args=(-P "$JOBS")
      what="full sweep at -P${JOBS}"
      ;;
    *)
      gate_args=(--changed-only -P "$JOBS")
      what="changed-only at -P${JOBS}"
      ;;
  esac

  run_gate "${gate_args[@]}" "${REPO_ROOT}/drill"
  if [ "$GATE_RC" = "0" ]; then
    ok "real tree, ${what}: ${DRILL_ITEMS} item(s), clean"
  else
    nope "real tree, ${what}: drill-gate.sh returned rc=${GATE_RC} over drill/ (${DRILL_ITEMS} items)"
    printf '%s\n' "$GATE_OUT" | sed 's/^/        /'
    echo "        rc 1 is a finding to fix. rc 99 means a check COULD NOT RUN over an"
    echo "        item that exists — most likely drill/INVENTORY.md is missing, which"
    echo "        leaves check 3 unable to say anything about construct coverage."
  fi

  # THE COUNT CLAIM'S COVERAGE IS ASSERTED IN EVERY MODE, and it is asserted
  # over the real tree rather than over a fixture because the number only
  # means something against the corpus. Before bead tla-ywf4 the gate compared
  # exit codes and nothing else, so every recorded state count across 64 items
  # was an unguarded claim and no output said so. A gate that silently stopped
  # parsing those claims would print the same VERDICT OK it prints now, so the
  # line that names the number is what makes the regression visible.
  has "real tree: states how many distinct-state claims it parsed and compared" \
      "drill-gate.sh: count claims: "

  # THE MODE BLOCK IS PART OF THE CONTRACT, not decoration, so it is asserted
  # and not merely echoed. A tier that drops 237 TLC runs and then prints
  # VERDICT OK, saying nothing about the 237, reads as a full verification to
  # anyone who did not pass the flag. If the gate ever stops printing the
  # count, the row that relies on it goes red here rather than going quiet.
  case "$SUITE_MODE" in
    static)
      has "real tree, static sweep: names the count of recorded rcs it did not reproduce" \
          "recorded rc(s) not reproduced, no TLC ran."
      has "real tree, static sweep: and says what it did NOT check" \
          "NOT CHECKED HERE: whether any recorded rc still reproduces"
      ;;
    full)
      # A full sweep leaves no rc unasked, so it has no skipped count to
      # state. The one thing it still does not GATE is check 3, which reports
      # by design and can never redden the gate at any construct count, so
      # that is what this arm asserts it said. Without it the cibuild phase
      # would print one PASS line and nothing about its own altitude.
      has "real tree, full sweep: says that coverage is audited and never gated" \
          "AUDIT ONLY, never a failure"
      ;;
    *)
      has "real tree, changed-only: names what ran, what came from cache and what was stale" \
          "job(s) verified, "
      has "real tree, changed-only: and says that a cached job is verified rather than skipped" \
          "A CACHED JOB IS VERIFIED, not skipped"
      ;;
  esac

  # Echo the gate's own closing block into this suite's output, so the log a
  # reader reaches for carries the honesty statement rather than only the
  # assertion labels above. awk over a here-string, never a live pipe into an
  # early-exiting consumer (bead tla-kr9).
  awk '/^drill-gate\.sh: (--static-only|--changed-only)\./ { f = 1 } f { print "        " $0 }' \
    <<<"$GATE_OUT"
}

# summary_and_exit: the verdict line every invocation ends on.
summary_and_exit() {
  echo
  echo "test-drill.sh: ${pass_count} passed, ${fail_count} failed"
  [ "$fail_count" -eq 0 ]
  exit $?
}

# THE EARLY DISPATCH. --static and --full-sweep run the real-tree arm and
# nothing else, so no fixture is built and no control runs. Parts 1 and 2 are
# the instrument's controls and they belong to the unflagged invocation.
if [ "$SUITE_MODE" != "controls" ]; then
  echo "== part 3 only (${SUITE_MODE}): the real drill/ tree =="
  echo "   Parts 1, 2, 2b and 2c to 2e did NOT run here. They are this instrument's"
  echo "   own controls, four of their fixtures run real TLC, and the unflagged"
  echo "   invocation in scripts/test's slow tier is what runs them."
  real_tree_arm
  summary_and_exit
fi

# ===========================================================================
echo "== part 1a: the baseline item passes all three checks =="
# ===========================================================================
R_GOOD="${TMP}/good"
mkdir -p "$R_GOOD"
mk_inventory "$R_GOOD"
mk_item "$R_GOOD" "liveness/01-served"

run_gate "$R_GOOD"
rc_is "baseline: rc 0" 0
has   "baseline: verdict OK" "VERDICT OK"
hasnt "baseline: no finding of any kind" "FINDING"
has   "baseline: the covered high construct counts 1 item" "1  high"
has   "baseline: the empty medium row prints as a gap" "medium  functions  \`EXCEPT\` function update"
hasnt "baseline: an empty row at any frequency does not fail" "FINDING   COVERAGE"
has   "baseline: Good.tla reproduces rc 0" "Good.tla rc=0"
has   "baseline: Wrong.tla reproduces rc 13" "Wrong.tla rc=13"
# A verbatim declaration must match EXACTLY, not fall through to containment.
# inv_index is read through $( ), which is a subshell, so a first version that
# set a global reported all 105 real constructs as containment matches.
hasnt "baseline: a verbatim declaration matches exactly, not by containment" "MATCH"

# ===========================================================================
echo
echo "== part 1b: check 1 — an item that TELEGRAPHS is caught =="
# ===========================================================================
# THE DEFECT, in Frank's words about every prior attempt: "too rote, it was
# hard to make puzzles that didn't just have the answer built in". This
# fixture hands over the operator in a fenced block in the prompt. One
# mutation from the baseline: PROMPT.md.
R_TEL="${TMP}/telegraph"
mkdir -p "$R_TEL"
mk_inventory "$R_TEL"
mk_item "$R_TEL" "liveness/01-served"
cat >"${R_TEL}/liveness/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

Here is the shape of the requirement. Fill in the two state predicates.

```
Served == ___ ~> ___
```
PROMPT

run_gate --no-tlc "$R_TEL"
rc_is "telegraph: rc 1" 1
has   "telegraph: caught by the DECLARED layer" "TELEGRAPH-DECLARED"
has   "telegraph: names the token it found" "PROMPT.md shows '~>'"
has   "telegraph: also caught by the FLOOR layer" "TELEGRAPH-FLOOR"
has   "telegraph: verdict FINDINGS" "VERDICT FINDINGS"

# A prompt that shows the operator in PROSE rather than in a block is caught
# too — the scan is over the whole file, not only its fenced regions.
cat >"${R_TEL}/liveness/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

Write the requirement. You will want a leads-to, written `~>`.
PROMPT
run_gate --no-tlc "$R_TEL"
has "telegraph: the token is caught in prose, not only in a code block" "TELEGRAPH-DECLARED"

# ===========================================================================
echo
echo "== part 1b2: check 1 — a prompt carrying a TLC TRACE =="
# ===========================================================================
# THE FINDING FROM THE TRIAL. The trace IS part of the prompt, and a LASSO
# trace is itself a partial answer: it shows exactly where an action was
# enabled and skipped, which is half the diagnosis. So an item that shows one
# must say so in why-not-in-prompt, and the trace gets the same token scan as
# a prompt carrying code.
R_TRACE="${TMP}/trace"
mkdir -p "$R_TRACE"
mk_inventory "$R_TRACE"
mk_item "$R_TRACE" "liveness/01-served"
cat >"${R_TRACE}/liveness/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

TLC rejects this spec. Here is what it printed. Say which requirement failed
and why.

```
Error: Temporal properties were violated.

State 1: <Initial predicate>
/\ s = 0

Back to state 1: <Stuttering>
```
PROMPT

run_gate --no-tlc "$R_TRACE"
rc_is "trace: rc 1" 1
has   "trace: an uncaveated lasso trace is a finding" "TELEGRAPH-TRACE-UNCAVEATED"
has   "trace: the finding names it as a lasso" "carries a lasso trace"

# The remedy is prose, and it is accepted: a why-not-in-prompt that reckons
# with the trace clears THIS finding. Nothing else about the item changes.
A="${R_TRACE}/liveness/01-served/ANSWER.md"
sed -e 's/^why-not-in-prompt: the prompt states/why-not-in-prompt: the trace in the prompt is itself a partial answer, and that is accepted here deliberately: it shows where the action was skipped, so the drill is the diagnosis and not the detection. The prompt states/' \
  "$A" >"${A}.new" && mv "${A}.new" "$A"
run_gate --no-tlc "$R_TRACE"
hasnt "trace: a caveat that mentions the trace clears the finding" "TELEGRAPH-TRACE-UNCAVEATED"

# And a trace prompt is still token-scanned, so the caveat is not a blanket
# pardon. This trace prints the operator.
cat >"${R_TRACE}/liveness/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

TLC rejects this spec. Here is what it printed, including the property.

```
Error: Temporal property Served == (s = 0) ~> (s = 1) was violated.

State 1: <Initial predicate>
/\ s = 0

Back to state 1: <Stuttering>
```
PROMPT
run_gate --no-tlc "$R_TRACE"
has "trace: a caveated trace is STILL token-scanned" "TELEGRAPH-DECLARED"

# ===========================================================================
echo
echo "== part 1b3: check 1 — the why-not-in-prompt field =="
# ===========================================================================
R_CAV="${TMP}/caveat"
mkdir -p "$R_CAV"
mk_inventory "$R_CAV"
mk_item "$R_CAV" "liveness/01-served"
# Strip the field entirely.
grep -v 'why-not-in-prompt' "${R_CAV}/liveness/01-served/ANSWER.md" \
  >"${R_CAV}/liveness/01-served/ANSWER.new"
mv "${R_CAV}/liveness/01-served/ANSWER.new" "${R_CAV}/liveness/01-served/ANSWER.md"
run_gate --no-tlc "$R_CAV"
rc_is "caveat: rc 1" 1
has   "caveat: a missing why-not-in-prompt field is a finding" "TELEGRAPH-NO-CAVEAT"

# A field that exists and says nothing is the same defect. "n/a" must not buy
# a pass, because the field's whole job is to carry the risk the gate cannot
# see.
mk_item "$R_CAV" "liveness/02-served"
sed -e 's/^why-not-in-prompt: .*/why-not-in-prompt: n\/a/' \
  "${R_CAV}/liveness/02-served/ANSWER.md" >"${R_CAV}/liveness/02-served/A.new"
mv "${R_CAV}/liveness/02-served/A.new" "${R_CAV}/liveness/02-served/ANSWER.md"
run_gate --no-tlc "$R_CAV"
has "caveat: an empty field does not buy a pass either" "liveness/02-served"

# ===========================================================================
echo
echo "== part 1c: check 2 — an item whose recorded rc DOES NOT REPRODUCE =="
# ===========================================================================
# The defect: the number in ANSWER.md is a MEASUREMENT, and a measurement
# that does not repeat is wrong. This fixture records 12 where TLC returns
# 13, which is the exact mistake an author makes by reasoning from the .cfg
# keyword instead of the shape of the formula (harness/verdict.sh:81-91).
R_RC="${TMP}/badrc"
mkdir -p "$R_RC"
mk_inventory "$R_RC"
mk_item "$R_RC" "liveness/01-served"
sed -e 's/| Wrong | Wrong.cfg | 13 |/| Wrong | Wrong.cfg | 12 |/' \
  "${R_RC}/liveness/01-served/ANSWER.md" >"${R_RC}/liveness/01-served/A.new"
mv "${R_RC}/liveness/01-served/A.new" "${R_RC}/liveness/01-served/ANSWER.md"

run_gate "$R_RC"
rc_is "bad rc: rc 1" 1
has   "bad rc: the mismatch is caught" "VERIFY-RC-MISMATCH"
has   "bad rc: both numbers are reported" "records rc 12, TLC returned 13"
has   "bad rc: the module that reproduced is still reported OK" "Good.tla rc=0"

# ===========================================================================
echo
echo "== part 1c2: check 2 — the structural half =="
# ===========================================================================
R_V="${TMP}/verify"
mkdir -p "$R_V"
mk_inventory "$R_V"

# No refutation: every recorded rc is 0, so no stated wrong answer was ever
# shown to fail. The item proves only that something passes.
mk_item "$R_V" "liveness/01-norefut"
D="${R_V}/liveness/01-norefut"
rm -f "${D}/verify/Wrong.tla" "${D}/verify/Wrong.cfg"
grep -v '^| Wrong ' "${D}/ANSWER.md" >"${D}/A.new" && mv "${D}/A.new" "${D}/ANSWER.md"

# No pass: the stated answer was never shown to check.
mk_item "$R_V" "liveness/02-nopass"
D="${R_V}/liveness/02-nopass"
rm -f "${D}/verify/Good.tla" "${D}/verify/Good.cfg"
grep -v '^| Good ' "${D}/ANSWER.md" >"${D}/A.new" && mv "${D}/A.new" "${D}/ANSWER.md"

# A module with a .cfg and no recorded rc at all. An unrecorded rc is
# unverifiable, so it is a finding and never a quiet skip — the quiet skip is
# how an author would dodge check 2 altogether.
mk_item "$R_V" "liveness/03-norc"
D="${R_V}/liveness/03-norc"
grep -v '^| Wrong ' "${D}/ANSWER.md" >"${D}/A.new" && mv "${D}/A.new" "${D}/ANSWER.md"

# An rc that is not a row of verdict.sh's table. A recorded 1 reproduces
# against nothing and is almost always a shell exit mis-transcribed.
mk_item "$R_V" "liveness/04-offtable"
D="${R_V}/liveness/04-offtable"
sed -e 's/| Wrong | Wrong.cfg | 13 |/| Wrong | Wrong.cfg | 1 |/' \
  "${D}/ANSWER.md" >"${D}/A.new" && mv "${D}/A.new" "${D}/ANSWER.md"

run_gate --no-tlc "$R_V"
rc_is "verify structure: rc 1" 1
has   "verify: every recorded rc 0 means no wrong answer was refuted" "VERIFY-NO-REFUTATION"
has   "verify: no recorded rc 0 means the answer never checked" "VERIFY-NO-PASS"
has   "verify: a .cfg with no recorded rc is a finding" "VERIFY-NO-RC"
has   "verify: an rc outside verdict.sh's table is a finding" "VERIFY-RC-NOT-IN-TABLE"

# An item with no verify/ at all, and one with no module in it.
mk_item "$R_V" "liveness/05-noverify"
rm -rf "${R_V}/liveness/05-noverify/verify"
mk_item "$R_V" "liveness/06-emptyverify"
rm -f "${R_V}"/liveness/06-emptyverify/verify/*
run_gate --no-tlc "$R_V"
has "verify: a missing verify/ directory is a finding" "no verify/ directory"
has "verify: a verify/ with no module is a finding" "VERIFY-NO-MODULES"

# ===========================================================================
echo
echo "== part 1d: check 3 — coverage REPORTS and must never FAIL =="
# ===========================================================================
# THE CORRECTION THIS PART PINS. An earlier draft of this gate failed on a
# high construct with zero items. That arm was REMOVED, not disabled, and
# these assertions are what keep it gone.
#
# V2-PLAN.md:459: "Coverage is an end-of-run AUDIT, never the problem-list
# generator. Organizing by construct produces problems whose purpose is 'this
# one exercises CHOOSE,' which is contrived by construction." A gate that
# fails on an uncovered token pushes an author to write an item FOR the
# token, which is the forbidden inventory-to-artifact direction arriving
# through the back door, and a contrived item is the one thing this corpus
# exists to avoid.
#
# So the fixture below leaves an expected-HIGH construct with no item at all,
# and the gate must come back CLEAN. This runs with real TLC on purpose: it
# is the only way to assert rc 0 rather than merely "not 1", and rc 0 is the
# claim that matters.
R_GAP="${TMP}/gap"
mkdir -p "$R_GAP"
mk_inventory "$R_GAP" --with-gap
mk_item "$R_GAP" "liveness/01-served"

run_gate "$R_GAP"
rc_is "coverage: an uncovered HIGH construct still exits 0" 0
has   "coverage: verdict OK despite the gap" "VERDICT OK"
hasnt "coverage: no finding of any kind" "FINDING"
hasnt "coverage: the failing arm is GONE, not disabled" "COVERAGE-HIGH-GAP"
has   "coverage: the gap block prints, to aim the next wave" "CONSTRUCT GAPS"
has   "coverage: the uncovered HIGH row is named" "high  liveness  \`WF_\` weak fairness"
has   "coverage: the uncovered MEDIUM row is printed too" "medium  functions  \`EXCEPT\` function update"
has   "coverage: a covered construct carries its count" "1  high         liveness"
has   "coverage: the block says it is an audit and not a failure" "AUDIT ONLY, never a failure"
has   "coverage: and says why an item written to close a row is wrong" "contrived by construction"

# THIN prints too, and also never fails.
has   "coverage: a high construct on a single item prints as THIN" "THIN"

# An item declaring a construct the inventory does not list leaves layer A of
# the TELEGRAPH check with no token to compare. That is reported as a check
# that could not run — rc 99 — and NOT as a coverage failure.
mk_item "$R_GAP" "liveness/02-unknown"
cat >"${R_GAP}/liveness/02-unknown/META.md" <<'META'
# Meta

Constructs: quantum entanglement
Shape: 2
META
run_gate --no-tlc "$R_GAP"
has   "coverage: an unlisted construct is UNCHECKED against telegraph, not a coverage failure" \
      "which INVENTORY.md does not list, so no token resolves"
hasnt "coverage: and carries no COVERAGE-* finding code" "COVERAGE-UNKNOWN-CONSTRUCT"

# A NEAR miss resolves by containment rather than failing. The real
# inventory's construct names are prose from a cheat sheet, so an author
# typing a plural or an extra word has not made a mistake worth reporting as
# unlisted. The looser match is PRINTED, so it stays visible.
cat >"${R_GAP}/liveness/02-unknown/META.md" <<'META'
# Meta

Constructs: leads-to
Shape: 2
META
run_gate --no-tlc "$R_GAP"
has   "coverage: a near-miss construct name resolves by containment" "matched row"
has   "coverage: and the looser match is printed rather than hidden" "by containment, not exactly"
hasnt "coverage: so it is not reported as unlisted" "INVENTORY.md does not list"

# Same for an item that declares nothing at all.
mk_item "$R_GAP" "liveness/03-silent"
printf '# Meta\n\nShape: 2\n' >"${R_GAP}/liveness/03-silent/META.md"
run_gate --no-tlc "$R_GAP"
has   "coverage: an item declaring nothing is UNCHECKED against telegraph" \
      "declares no constructs; layer A has no token to compare against"
hasnt "coverage: and carries no COVERAGE-* finding code" "COVERAGE-UNDECLARED-ITEM"

# The decisive control: no count, at any frequency, can produce a FINDING.
# This is the assertion that would go red if somebody restored the arm.
run_gate --no-tlc "$R_GAP"
hasnt "coverage: no construct count can redden the gate" "FINDING   COVERAGE"

# ===========================================================================
echo
echo "== part 1e: CHECK_DID_NOT_RUN — rc 99, and never 0 =="
# ===========================================================================
# rc 99 is the project-wide reserved code for a check that could not be
# performed (harness/verdict.sh, bead tla-hl96). An instrument asked for a
# check it cannot run must not report success, so these cases are 99 and are
# not folded into 0.
R_NOINV="${TMP}/noinv"
mkdir -p "$R_NOINV"
mk_item "$R_NOINV" "liveness/01-served"
run_gate --no-tlc "$R_NOINV"
rc_is "no inventory: rc 99, not 0" 99
has   "no inventory: coverage is reported UNCHECKED" "UNCHECKED coverage"
has   "no inventory: verdict CHECK_DID_NOT_RUN" "VERDICT CHECK_DID_NOT_RUN"
has   "no inventory: the expected table shape is printed" "| construct | family | expected frequency |"

# An empty root guarantees nothing, so it is 99 rather than a clean 0. A gate
# that reports OK over zero items is the emptiest kind of green lie.
R_EMPTY="${TMP}/empty"
mkdir -p "$R_EMPTY"
mk_inventory "$R_EMPTY"
run_gate "$R_EMPTY"
rc_is "empty root: rc 99, not 0" 99
has   "empty root: says it found no items" "no items found"

# --no-tlc can never exit 0. The mode leaves check 2 unreproduced by
# construction, so it must always carry that forward as 99 at best.
run_gate --no-tlc "$R_GOOD"
rc_is "--no-tlc: rc 99 even on the baseline that passes" 99
has   "--no-tlc: says which rc went unreproduced" "recorded rc 0 not reproduced"

# An inventory whose frequency column holds something that is not
# high/medium/low is PRINTED and not failed. INVENTORY.md is a file that is
# still being written and the gate does not get a vote on its shape.
R_FREQ="${TMP}/freq"
mkdir -p "$R_FREQ"
mk_item "$R_FREQ" "liveness/01-served"
cat >"${R_FREQ}/INVENTORY.md" <<'INV'
| construct | family | expected frequency |
|---|---|---|
| `~>` leads-to | liveness | often |
INV
run_gate --no-tlc "$R_FREQ"
has   "bad frequency: 'often' is reported rather than ignored" "INVENTORY FREQUENCY"
has   "bad frequency: the row is named" "has frequency 'often', not high/medium/low"
hasnt "bad frequency: it is not a finding" "INVENTORY-BAD-FREQUENCY"

# An inventory row whose construct carries no SYMBOL is outside layer A's
# reach, and that is reported as reach rather than as a check that could not
# run. The distinction is real: "Operator definition" has no token a prompt
# could leak, so layer A does not APPLY to it. The floor over the answer's own
# code still covers the item. The real inventory's field 4 is prose from a
# cheat sheet, so most of its 105 rows sit here.
R_TOK="${TMP}/notoken"
mkdir -p "$R_TOK"
mk_item "$R_TOK" "liveness/01-served"
cat >"${R_TOK}/liveness/01-served/META.md" <<'META'
# Meta

Constructs: the usual temporal thing
Shape: 2
META
cat >"${R_TOK}/INVENTORY.md" <<'INV'
| construct | family | expected frequency |
|---|---|---|
| the usual temporal thing | liveness | high |
INV
run_gate --no-tlc "$R_TOK"
has   "no token: a symbol-less construct is counted as outside layer A's reach" "LAYER A REACH"
has   "no token: and the count says so" "0 declared-construct scan(s) had a token"
hasnt "no token: it is not reported as a check that could not run" "UNCHECKED telegraph-declared"
has   "no token: the output says the floor is the only layer left" "the only telegraph"

# ===========================================================================
echo
echo "== part 1f: the waiver, and why it cannot accumulate unseen =="
# ===========================================================================
# A waiver suppresses exactly one token for exactly one item, and every
# waiver is ECHOED. This is the per-site `# shellcheck disable` with its
# reason above it that scripts/lint requires, in the same shape and for the
# same reason: a blanket exemption turns a red gate into a green lie.
#
# It lives in the item's META.md, which is the file harness/completion-gate.sh
# reads the same keyword from. The last fixture in this part is what holds the
# gate to that file rather than to the keyword alone.
R_W="${TMP}/waiver"
mkdir -p "$R_W"
mk_inventory "$R_W"
mk_item "$R_W" "liveness/01-served"
cat >"${R_W}/liveness/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

Write the requirement. You will want a leads-to, written `~>`.
PROMPT

run_gate --no-tlc "$R_W"
has "waiver: without one, the token is a finding" "TELEGRAPH-DECLARED"

M="${R_W}/liveness/01-served/META.md"
printf '\ntelegraph-waiver: ~> -- the operator is given on purpose here; this item drills the two state predicates, not the operator.\n' >>"$M"
run_gate --no-tlc "$R_W"
hasnt "waiver: with one, that token stops being a finding" "TELEGRAPH-DECLARED"
has   "waiver: the waiver is echoed, so it cannot accumulate unseen" "WAIVER"
has   "waiver: the echo carries the reason" "drills the two state predicates"

# A waiver with no reason is an exemption, and is itself a finding.
grep -v 'telegraph-waiver' "$M" >"${M}.new" && mv "${M}.new" "$M"
printf '\ntelegraph-waiver: ~>\n' >>"$M"
run_gate --no-tlc "$R_W"
has "waiver: one with no reason is itself a finding" "TELEGRAPH-WAIVER-NO-REASON"

# THE FILE IS HALF THE IDIOM, and nothing above pins that half. The fixtures
# prove the gate honours a waiver in whichever file it reads. Point it back
# at ANSWER.md and every one of them stays green. Bead tla-o14p found that
# split live: this gate read ANSWER.md while harness/completion-gate.sh read
# META.md, so an author working both channels could file a waiver one gate
# never saw. A waiver that is not found is silence rather than a finding, so
# the plant below goes in ANSWER.md and has to be ignored.
grep -v 'telegraph-waiver' "$M" >"${M}.new" && mv "${M}.new" "$M"
A="${R_W}/liveness/01-served/ANSWER.md"
printf '\ntelegraph-waiver: ~> -- planted in the answer file on purpose, because only META.md is the waiver file.\n' >>"$A"
run_gate --no-tlc "$R_W"
has   "waiver in ANSWER.md: not honoured, so the token is still a finding" "TELEGRAPH-DECLARED"
hasnt "waiver in ANSWER.md: and nothing is echoed as a waiver" "WAIVER    liveness"

# ===========================================================================
echo
echo "== part 1g: the TAB-delimited inventory, which is the real shape =="
# ===========================================================================
# drill/INVENTORY.md ships tab-delimited rows carrying the literal first
# field `ROW`, not a markdown table, and its own "For the gate author"
# section specifies that. Eight fields: marker, id, family, construct,
# source, weight, basis, items. The pipe table every fixture above uses is
# the FALLBACK shape, so without this part the real one would be untested.
R_TAB="${TMP}/tab"
mkdir -p "$R_TAB"
# The construct cell carries backticks, and a backtick inside a single-quoted
# printf format raises SC2016. A quoted heredoc carries the same bytes clean,
# so the cell is built here and passed as an argument.
BT_CELL="$(cat <<'CELL'
Leads-to (`~>`)
CELL
)"
{
  printf 'ROW\tK001\ttemporal\t%s\texercises/ch08/CHEATSHEET.md:11\thigh\tA12/12\t\n' "$BT_CELL"
  printf 'ROW\tK002\ttemporal\tWeak fairness\texercises/ch08/CHEATSHEET.md:15\thigh\tA8/12\t\n'
  printf 'ROW\tK003\tmodules\tEXTENDS (module import)\texercises/ch02/CHEATSHEET.md:23\tmedium\tA8/12\t\n'
  printf 'ROW\tK004\tcore\tOperator definition\texercises/ch02/CHEATSHEET.md:11\tlow\tA12/12\t\n'
} >"${R_TAB}/INVENTORY.md"
mk_item "$R_TAB" "temporal/01-served"
cat >"${R_TAB}/temporal/01-served/META.md" <<'META'
# Meta

Constructs: Leads-to (`~>`)
Shape: 2
META

run_gate --no-tlc "$R_TAB"
has "tab shape: the ROW form is recognized and named" "tab-delimited ROW lines"
has "tab shape: all four rows parse" "4 construct(s) parsed"
has "tab shape: the declared row is counted" "1  high         temporal             Leads-to (\`~>\`)"
has "tab shape: an undeclared row prints as a gap" "high  temporal  Weak fairness"
has "tab shape: the weight column feeds the frequency" "medium  modules  EXTENDS (module import)"
# THE EMPTY-FIELD-8 PIN. `IFS=$'\t' read` collapses consecutive tabs, because
# tab is an IFS whitespace character, so the empty field 8 vanished and the
# sentinel slid into it. Every row then counted 1 and a 105-row inventory
# read as fully covered over an empty tree. An UNDECLARED row must count 0.
has "tab shape: an undeclared row with empty field 8 counts 0, not 1" \
    "0  high         temporal             Weak fairness"

# Layer A must reach a token through the real shape too. The backticked
# symbol in field 4 is what gives it one.
cat >"${R_TAB}/temporal/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

Write the requirement. You want `~>` here.
PROMPT
run_gate --no-tlc "$R_TAB"
has "tab shape: layer A finds the backticked token in field 4" "TELEGRAPH-DECLARED"

# An ALL-CAPS keyword inside a PROSE cell is a token too. "EXTENDS (module
# import)" yields EXTENDS, which is how layer A reaches the many real rows
# that carry no backticks.
cat >"${R_TAB}/temporal/01-served/META.md" <<'META'
# Meta

Constructs: EXTENDS (module import)
Shape: 2
META
cat >"${R_TAB}/temporal/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

Here is the module header.

```
---- MODULE Dispatcher ----
EXTENDS Naturals
```
PROMPT
run_gate --no-tlc "$R_TAB"
has "tab shape: an ALL-CAPS keyword in a prose cell is a token" "PROMPT.md shows 'EXTENDS'"

# A BULLETED construct list is not comma-split. The real inventory carries
# rows whose names contain a comma, such as the universal quantifier row
# below, and splitting one produces a fragment that matches the wrong row
# plus a second that matches nothing.
{
  printf 'ROW\tK001\tcore\t\\A (universal quantifier, "forall")\tf:1\thigh\tA12/12\t\n'
} >"${R_TAB}/INVENTORY.md"
cat >"${R_TAB}/temporal/01-served/META.md" <<'META'
# Meta

## Constructs

- \A (universal quantifier, "forall")
META
cat >"${R_TAB}/temporal/01-served/PROMPT.md" <<'PROMPT'
# The dispatcher

Say that every ticket in the queue is closed.
PROMPT
run_gate --no-tlc "$R_TAB"
has   "tab shape: a bulleted name containing a comma is one construct" \
      "1  high         core                 \\A (universal quantifier, \"forall\")"
hasnt "tab shape: and is not reported as unlisted" "does not list"

# Field 8 is the inventory's own coverage field. It is empty on every real
# row today, and this gate READS it and never writes it.
{
  printf 'ROW\tK001\ttemporal\t%s\texercises/ch08/CHEATSHEET.md:11\thigh\tA12/12\t99-elsewhere,98-other\n' "$BT_CELL"
} >"${R_TAB}/INVENTORY.md"
run_gate --no-tlc "$R_TAB"
has "tab shape: field 8 ids are counted" "2  high         temporal             Leads-to (\`~>\`)"

# ===========================================================================
echo
echo "== part 1h: check 2 — the DISTINCT-STATE COUNT, not only the rc =="
# ===========================================================================
# WHY THE COUNT NEEDS ITS OWN ROWS. Check 2 compared exit codes and nothing
# else, so every recorded state count in the corpus was an unguarded claim.
# The count is the half a learner checks their answer against: a prompt that
# publishes "a correct model finds 129 distinct states" has handed the reader
# a number to land on, and nothing was holding it. The two numbers also drift
# differently. An rc is coarse and survives a small spec change, while a count
# moves on any change to the constants, the state space or the initial
# predicate, and it moves silently.
#
# THE FIXTURE ADDS ONE COLUMN AND CHANGES NOTHING ELSE. mk_item's table is
# `| module | cfg | rc |` with no count column at all, which is the shape the
# temporal family really has, so the baseline already covers "no claim". Each
# row below appends a `distinct` column to that one table and mutates one
# cell.
R_CNT="${TMP}/count"
mkdir -p "$R_CNT"
mk_inventory "$R_CNT"
mk_item "$R_CNT" "liveness/01-served"
D="${R_CNT}/liveness/01-served"

# A third module that CANNOT print a count: a parse error never reaches the
# state graph. Measured on this build — rc 150, and the log carries no
# `N distinct states` line at all.
cat >"${D}/verify/Broken.tla" <<'TLA'
---- MODULE Broken ----
EXTENDS Naturals
VARIABLE s
Init == s = 0
Up == s = 0 /\ s' = 1
Next == Up
Spec == Init /\ [][Next]_s
Bad == s \in 0..1 /\
====
TLA
cat >"${D}/verify/Broken.cfg" <<'CFG'
SPECIFICATION Spec
INVARIANT Bad
CFG

# The table, with a distinct column and the counts measured on this build:
# Good 2, Wrong 2, Broken none. `Good` is given 7 on purpose.
write_count_table() {
  local good="$1" wrong="$2" broken="$3"
  {
    grep -v '^| module | cfg | rc |' "${D}/ANSWER.md" \
      | grep -v '^|---|---|---|$' \
      | grep -v '^| Good | Good.cfg | 0 |$' \
      | grep -v '^| Wrong | Wrong.cfg | 13 |$'
    printf '| module | cfg | rc | distinct |\n'
    printf '|---|---|---|---|\n'
    printf '| Good | Good.cfg | 0 | %s |\n' "$good"
    printf '| Wrong | Wrong.cfg | 13 | %s |\n' "$wrong"
    printf '| Broken | Broken.cfg | 150 | %s |\n' "$broken"
  } >"${D}/A.new"
  mv "${D}/A.new" "${D}/ANSWER.md"
}

# --- RED 1: a claim that disagrees with what TLC printed ------------------
# Good's claim says 7 and the run prints 2. Broken is waived here so that
# this row isolates the mismatch.
write_count_table 7 2 1
printf '\ncount-waiver: Broken -- a parse error never reaches the state graph, so TLC prints no count for this module.\n' >>"${D}/META.md"
run_gate "$R_CNT"
rc_is "count mismatch: rc 1" 1
has   "count mismatch: the disagreement is caught" "VERIFY-COUNT-MISMATCH"
has   "count mismatch: both numbers are reported" "distinct column records 7, TLC printed 2"
has   "count mismatch: the module whose count agreed is reported OK" "Wrong.tla rc=13 distinct=2"
has   "count mismatch: the rc half still reports, so the two halves are separable" "Good.tla rc=0"

# --- RED 2: a claim whose run prints no count at all ---------------------
# Same table, waiver removed. Broken's rc 150 reproduces and its count cannot,
# so the claim is unverifiable and that is a finding rather than a quiet pass.
grep -v 'count-waiver' "${D}/META.md" >"${D}/M.new" && mv "${D}/M.new" "${D}/META.md"
write_count_table 2 2 1
run_gate "$R_CNT"
rc_is "count absent: rc 1" 1
has   "count absent: a claim the run cannot reproduce is a finding" "VERIFY-COUNT-ABSENT"
has   "count absent: the finding names the module and the claim" "Broken.tla: ANSWER.md's distinct column records 1"
has   "count absent: and the rc itself still reproduced" "Broken.tla rc=150"

# --- RED 3: the same item with a count-waiver in META.md -----------------
printf '\ncount-waiver: Broken -- a parse error never reaches the state graph, so TLC prints no count for this module.\n' >>"${D}/META.md"
run_gate "$R_CNT"
rc_is "count waiver: rc 0" 0
hasnt "count waiver: with one, the absent count stops being a finding" "VERIFY-COUNT-ABSENT"
has   "count waiver: the waiver is echoed, so waivers cannot accumulate unseen" "count:Broken"
has   "count waiver: the echo carries the reason" "never reaches the state graph"
has   "count waiver: the waived module is reported, not skipped silently" "Broken.tla rc=150 distinct=waived"

# --- RED 4: a count-waiver with no reason is itself a finding -------------
grep -v 'count-waiver' "${D}/META.md" >"${D}/M.new" && mv "${D}/M.new" "${D}/META.md"
printf '\ncount-waiver: Broken\n' >>"${D}/META.md"
run_gate "$R_CNT"
has "count waiver: one with no reason is itself a finding" "COUNT-WAIVER-NO-REASON"

# --- RED 5: no claim at all is no check and no finding -------------------
# The temporal family's case, and it must stay silent. The baseline item is
# rebuilt so its table carries no distinct column.
R_CNT0="${TMP}/count-none"
mkdir -p "$R_CNT0"
mk_inventory "$R_CNT0"
mk_item "$R_CNT0" "liveness/01-served"
run_gate "$R_CNT0"
rc_is "no count claimed: rc 0" 0
hasnt "no count claimed: no mismatch" "VERIFY-COUNT-MISMATCH"
hasnt "no count claimed: and no absent-count finding either" "VERIFY-COUNT-ABSENT"
has   "no count claimed: the coverage is stated rather than left silent" "count claims: 0 parsed"

# --- RED 6: THE FILE IS HALF THE IDIOM -----------------------------------
# A count-waiver planted in ANSWER.md must NOT be honoured. META.md is the
# waiver file for both gates, and bead tla-o14p found the telegraph waiver
# split live across the two: this gate read ANSWER.md while
# harness/completion-gate.sh read META.md, so an author working both channels
# could file a waiver one gate never saw. A waiver that is not found is
# silence rather than a finding, so the plant below has to be ignored.
grep -v 'count-waiver' "${D}/META.md" >"${D}/M.new" && mv "${D}/M.new" "${D}/META.md"
printf '\ncount-waiver: Broken -- planted in the answer file on purpose, because only META.md is the waiver file.\n' >>"${D}/ANSWER.md"
run_gate "$R_CNT"
has   "count waiver in ANSWER.md: not honoured, so the absent count is still a finding" "VERIFY-COUNT-ABSENT"
hasnt "count waiver in ANSWER.md: and nothing is echoed as a waiver" "count:Broken"

# --- the structural half runs in the static tiers -------------------------
# A waiver's reason floor is a property of the file, so it is checkable
# without TLC. The comparison is not, and the static tier says so.
printf '\ncount-waiver: Broken\n' >>"${D}/META.md"
run_gate --static-only "$R_CNT"
has "count waiver: the reason floor is checked with no TLC at all" "COUNT-WAIVER-NO-REASON"
has "count waiver: and the static tier states that no count was compared" "0 compared"

# ===========================================================================
echo
echo "== part 2: controls the other way — shapes that must NOT fire =="
# ===========================================================================
# A detector that fires on every deviation is worse than none. These two
# shapes are the ones the telegraph check is most likely to get wrong, and
# both are routine.
R_C="${TMP}/controls"
mkdir -p "$R_C"
mk_inventory "$R_C"

# CONTROL 1 — a prompt that SHOWS A SPEC and asks for the missing piece. That
# prompt legitimately carries the shared vocabulary of the language, and so
# does the answer. Flagging it would fail every item of this shape, which is
# why DISTINCTIVE excludes /\, \/, \in, \A, \E, =>, DOMAIN and the standard
# modules. See harness/drill-gate.sh's EXCLUDED ON PURPOSE list.
mk_item "$R_C" "liveness/01-shown-spec"
D="${R_C}/liveness/01-shown-spec"
cat >"${D}/PROMPT.md" <<'PROMPT'
# The dispatcher

Here is the spec. Write the requirement that says a pending ticket is
eventually closed.

```
VARIABLE s
Init == s \in {0}
Up == s = 0 /\ s' = 1
Next == Up \/ UNCHANGED s
TypeOK == s \in 0..1 /\ (s = 1 => Len(log) > 0)
```
PROMPT

# CONTROL 2 — an ENGLISH GLOSS. The prompt has to state its requirement in
# English, so "eventually" in prose is the problem statement and not a
# give-away. The gate flags the SYMBOL and never the gloss.
mk_item "$R_C" "liveness/02-gloss"
D="${R_C}/liveness/02-gloss"
cat >"${D}/PROMPT.md" <<'PROMPT'
# The dispatcher

Write the requirement that says the ticket is eventually closed, and that it
is always either pending or closed.
PROMPT
cat >"${D}/META.md" <<'META'
# Meta

Constructs: `<>` eventually
Shape: 2
META
sed -e 's/^Served == (s = 0) ~> (s = 1)$/Served == <>(s = 1)/' \
  "${D}/ANSWER.md" >"${D}/A.new" && mv "${D}/A.new" "${D}/ANSWER.md"

run_gate --no-tlc "$R_C"
hasnt "control: a prompt showing a spec does not telegraph on shared vocabulary" "TELEGRAPH-DECLARED"
hasnt "control: nor on the floor layer" "TELEGRAPH-FLOOR"
hasnt "control: an English gloss of the operator does not fire" "TELEGRAPH"

# CONTROL 3 — the instrument must still bite on this very root once the
# give-away is planted. Without this, the two hasnt() lines above are also
# what a dead scanner prints.
cat >>"${R_C}/liveness/01-shown-spec/PROMPT.md" <<'PLANT'

The answer has the shape `A ~> B`.
PLANT
run_gate --no-tlc "$R_C"
has "control: the SAME root goes red once the operator is planted" "TELEGRAPH-DECLARED"

# CONTROL 4 — an item directory that is not <NN>-<slug>. An item the gate
# cannot address is unguaranteed, so a malformed name is reported rather than
# skipped.
mk_item "$R_C" "liveness/served-no-number"
run_gate --no-tlc "$R_C"
has "control: a directory that is not <NN>-<slug> is reported" "ITEM-BAD-NAME"

# CONTROL 5 — A DRILL ROOT UNDER A DOT-PREFIXED ANCESTOR. Every dispatched
# worker in this project runs under .claude/worktrees/agent-*, so the real
# drill root always has a dot component above it. The first version of the
# item scan used `-not -path '*/.*'`, which matches the ROOT PATH ITSELF in
# that case and found zero items — reported as "nothing to guarantee", which
# is a false PASS over the entire sweep.
#
# The fixtures above never reproduced it, because mktemp gives /tmp/tmp.XXXX
# where the dot does not follow a slash. Only running against the real tree
# showed it. So this control puts the root under a genuinely hidden parent.
R_DOT="${TMP}/.hidden-parent/root"
mkdir -p "$R_DOT"
mk_inventory "$R_DOT"
mk_item "$R_DOT" "liveness/01-served"
run_gate --no-tlc "$R_DOT"
has   "control: items are found under a dot-prefixed ancestor directory" "liveness/01-served"
hasnt "control: and the sweep does not report an empty corpus" "no items found"

# A genuinely hidden family or item IS still skipped, which is what the
# predicate is for once it is anchored at the root.
mk_item "$R_DOT" ".scratch/01-served"
run_gate --no-tlc "$R_DOT"
hasnt "control: a hidden family directory is still skipped" ".scratch/01-served"

# ===========================================================================
echo
echo "== part 2b: the static pass stays off the fork path =="
# ===========================================================================
# WHAT THIS PINS, and it is a budget rather than a measurement to match.
# Bead tla-0eis.1 found the static pass forking 8,371 processes over 32
# items, 262 per item, with 3.45 s of system time against 5.67 s of user.
# Four call sites did almost all of it, and each one forked PER CALL where a
# parameter expansion or one batched pass does the same work. The gap this
# closes is that nothing else in the suite can see a fork count at all, so
# the next author to reach for `$(grep ...)` inside a per-row loop gets no
# signal until somebody times the gate by hand.
#
# A FORK COUNT, NOT A WALL CLOCK. The count is deterministic for a fixed
# input, where elapsed time on a box running a TLC job next door is not, and
# a flaky timing gate teaches people to re-run it rather than read it.
#
# THE FIXTURE IS SIZED FOR SENSITIVITY, and the ceiling comes from planting
# each old call site back and reading the count. 60 inventory rows and 12
# items gives, on this box:
#
#   169   as it stands, and the same 169 on five consecutive runs
#   457   with the per-module rc grep chain planted back
#   1173  with the tr-and-sed normalize planted back
#
# So the ceiling catches either of those two. It does NOT catch a return to
# `basename`, which is 36 forks over this fixture and lands around 205. Say
# that rather than implying the budget covers all four sites equally.
#
# The 131 forks of headroom above 169 are there so that one new awk or grep
# on a per-item path does not redden the suite. A change that needs more
# than that is a change worth arguing about in review.
#
# IT DOES NOT PIN THE REAL TREE. drill/ grows as authors land items, so a
# count over it would need editing every wave and would read as noise.
R_FORK="${TMP}/forkbudget"
mkdir -p "$R_FORK"
mk_inventory "$R_FORK"
# 56 more rows on top of mk_inventory's 4. Plain prose cells, so no backtick
# lands in a single-quoted printf format and raises SC2016.
for ((fi = 1; fi <= 56; fi++)); do
  printf '| Operator definition %02d | core | medium |\n' "$fi" >>"${R_FORK}/INVENTORY.md"
done
for ((fi = 1; fi <= 12; fi++)); do
  mk_item "$R_FORK" "liveness/$(printf '%02d' "$fi")-served"
done

FORK_CEILING=300
if ! command -v strace >/dev/null 2>&1; then
  echo "  SKIP  fork budget: strace is not on PATH, so the fork count was not measured"
  echo "        This is a statement about the box, not about the gate. Install strace"
  echo "        to re-arm it."
else
  strace -f -c -e trace=clone,clone3,vfork -o "${TMP}/forks.txt" \
    bash "$GATE" --no-tlc -q "$R_FORK" >/dev/null 2>&1
  # strace -c puts the call count in column 4 and the syscall name last. The
  # errors column is present on some rows and absent on others, which is why
  # the name is read from $NF rather than from a fixed position.
  FORKS="$(awk '$NF == "clone" || $NF == "clone3" || $NF == "vfork" { n += $4 } END { print n + 0 }' \
    "${TMP}/forks.txt" 2>/dev/null || echo 0)"
  if [ "${FORKS:-0}" -eq 0 ]; then
    echo "  SKIP  fork budget: strace ran but reported no clone calls, so it could not"
    echo "        trace the gate here (ptrace is often restricted in a container)."
  elif [ "$FORKS" -le "$FORK_CEILING" ]; then
    ok "fork budget: the static pass forked ${FORKS} process(es) over 60 rows and 12 items, ceiling ${FORK_CEILING}"
  else
    nope "fork budget: the static pass forked ${FORKS} process(es) over 60 rows and 12 items, ceiling ${FORK_CEILING}"
    echo "        Something on a per-row or per-module path is forking again. The four"
    echo "        sites bead tla-0eis.1 closed are normalize, the rc reader, basename"
    echo "        and the inventory token builder. Compare against:"
    echo "          strace -f -c -e trace=execve ./harness/drill-gate.sh --no-tlc -q drill"
  fi
fi

# ===========================================================================
echo
echo "== part 2c: --static-only — a tier that exits 0 and says what it skipped =="
# ===========================================================================
# WHY THIS MODE EXISTS AND --no-tlc DOES NOT COVER IT. --no-tlc can never exit
# 0, by construction and on purpose: it means the gate was asked to reproduce
# the recorded rcs and did not, so it carries CHECK_DID_NOT_RUN forward for
# every skipped run. Wiring that into a fast tier gives a tier that is red on
# every run. --static-only asks a DIFFERENT question — is the corpus
# structurally sound — and a clean run answers it completely.
#
# THE DEFECT THIS PART GUARDS AGAINST is a mode that exits 0 quietly. A tier
# that drops 237 TLC runs and then says VERDICT OK, with nothing about the 237,
# reads as a full verification to anyone who did not pass the flag. So the
# count is part of the contract and is asserted here, not just the exit code.
run_gate --static-only "$R_GOOD"
rc_is "--static-only: rc 0 on the baseline that passes" 0
has   "--static-only: verdict OK" "VERDICT OK"
has   "--static-only: names the count of recorded rcs it did not reproduce" \
      "--static-only. 2 recorded rc(s) not reproduced, no TLC ran."
has   "--static-only: and says what it did NOT check" \
      "NOT CHECKED HERE: whether any recorded rc still reproduces"
has   "--static-only: and names who does run that" "scripts/cibuild run that"
hasnt "--static-only: emits no UNCHECKED line for a run it never promised to make" \
      "UNCHECKED verify-rc"
hasnt "--static-only: so it does not escalate to CHECK_DID_NOT_RUN" "VERDICT CHECK_DID_NOT_RUN"
hasnt "--static-only: and runs no TLC, so there is no queue" "the TLC queue"

# THE CONTRAST, asserted side by side on purpose. The same root, the same
# clean item, two modes, two exit codes. The standalone form of this is the
# "--no-tlc: rc 99 even on the baseline that passes" row in part 1e; this
# duplicate is here because the pair is the thing worth reading, and a reader
# who sees only the rc 0 above would have no reason to keep the two modes
# apart.
run_gate --no-tlc "$R_GOOD"
rc_is "--no-tlc on the SAME baseline is still 99 — the modes are not merged" 99

# Passing both is a usage error. Two different questions with two different
# exit codes, and the gate does not guess which was meant.
#
# THE rc ALONE IS NOT DISCRIMINATING HERE, and the message is. Any unknown
# option exits 2, so a gate that had never heard of --static-only would pass
# the rc check for the wrong reason. The second assertion is what distinguishes
# "refused because the pair is incoherent" from "refused because the flag does
# not exist".
run_gate --no-tlc --static-only "$R_GOOD"
rc_is "--no-tlc with --static-only is a usage error, not a quiet merge" 2
has   "--no-tlc with --static-only: refused for the pair, not for an unknown flag" \
      "different questions with different exit codes"

# The structural half of check 2 still bites, which is the half --static-only
# keeps. Without these the mode would be indistinguishable from skipping
# check 2 altogether.
run_gate --static-only "$R_V"
rc_is "--static-only: rc 1 on the structural check-2 fixture" 1
has   "--static-only: a .cfg with no recorded rc is still a finding" "VERIFY-NO-RC"
has   "--static-only: an rc outside verdict.sh's table is still a finding" "VERIFY-RC-NOT-IN-TABLE"
has   "--static-only: no recorded rc 0 is still a finding" "VERIFY-NO-PASS"
has   "--static-only: every recorded rc 0 is still a finding" "VERIFY-NO-REFUTATION"
has   "--static-only: a verify/ with no module is still a finding" "VERIFY-NO-MODULES"

# And check 1 still bites, so a planted telegraph reddens the fast tier.
run_gate --static-only "$R_TEL"
rc_is "--static-only: rc 1 on a planted telegraph finding" 1
has   "--static-only: the telegraph finding still fires" "TELEGRAPH-DECLARED"

# ===========================================================================
echo
echo "== part 2d: -P N — the parallel queue, and the counter that could be lost =="
# ===========================================================================
# THE FAILURE THIS CATCHES, and it is a FALSE PASS on this gate's only
# correctness check. `finding()` increments `finding_n`. A parallel job runs in
# a child process, so a job that called it would print its FINDING line and
# lose the increment with the subshell. The run would then end at `finding_n`
# 0 and exit 0 with FINDING lines sitting in its own output — and the caller
# that reads the exit code, which is every caller, would see a pass.
#
# So the assertion is not "-P8 finds something". It is that -P8 produces the
# SAME finding lines, the SAME count in the summary, and the SAME exit code as
# -P1 over a fixture with planted mismatches. The count is the discriminating
# one: a lost increment leaves the lines intact and the number wrong.
#
# FOUR ITEMS AND TWO PLANTED MISMATCHES, not one of each. A single job cannot
# tell a queue that dispatches in order from one that drops everything after
# the first, and a single finding cannot tell a count of 1 from a count that
# happened to survive once.
R_PAR="${TMP}/parallel"
mkdir -p "$R_PAR"
mk_inventory "$R_PAR"
for pi in 1 2 3 4; do
  mk_item "$R_PAR" "liveness/0${pi}-served"
done
# ANSWER.md records 12 where TLC returns 13 — the exact mistake an author
# makes by reasoning from the .cfg keyword instead of the shape of the
# formula (harness/verdict.sh:81-91).
for pi in 2 4; do
  D="${R_PAR}/liveness/0${pi}-served"
  sed -e 's/| Wrong | Wrong.cfg | 13 |/| Wrong | Wrong.cfg | 12 |/' \
    "${D}/ANSWER.md" >"${D}/A.new" && mv "${D}/A.new" "${D}/ANSWER.md"
done

# Captured through here-strings, never a pipe into an early-exiting consumer.
# `sort` reads all of its input so it is safe behind one, and the `|| true`
# is there because grep exits 1 on no match (bead tla-kr9).
run_gate -P 1 "$R_PAR"
P1_RC="$GATE_RC"
P1_FINDINGS="$(grep -F 'FINDING' <<<"$GATE_OUT" | LC_ALL=C sort || true)"
P1_OK="$(grep -F '  OK  ' <<<"$GATE_OUT" | LC_ALL=C sort || true)"
P1_SUMMARY="$(grep -F 'item(s),' <<<"$GATE_OUT" || true)"

run_gate -P8 "$R_PAR"
P8_RC="$GATE_RC"
P8_FINDINGS="$(grep -F 'FINDING' <<<"$GATE_OUT" | LC_ALL=C sort || true)"
P8_OK="$(grep -F '  OK  ' <<<"$GATE_OUT" | LC_ALL=C sort || true)"
P8_SUMMARY="$(grep -F 'item(s),' <<<"$GATE_OUT" || true)"

has "-P8: the whole queue is dispatched" "8 job(s), 8 run at -P8"

if [ -n "$P1_FINDINGS" ] && [ "$P1_FINDINGS" = "$P8_FINDINGS" ]; then
  ok "-P8 produces the same FINDING lines as -P1 over two planted mismatches"
else
  nope "-P8 and -P1 disagree on the findings"
  printf '        -P1:\n%s\n        -P8:\n%s\n' "$P1_FINDINGS" "$P8_FINDINGS"
fi

# THE DISCRIMINATING ASSERTION. A counter lost in a child leaves every FINDING
# line in place and reports the count as 0.
if [ -n "$P1_SUMMARY" ] && [ "$P1_SUMMARY" = "$P8_SUMMARY" ]; then
  ok "-P8 reports the same finding COUNT as -P1 — no counter was lost in a child"
else
  nope "-P8 and -P1 disagree on the summary counts"
  printf '        -P1: %s\n        -P8: %s\n' "$P1_SUMMARY" "$P8_SUMMARY"
fi

if [ "$P1_RC" = "1" ] && [ "$P8_RC" = "1" ]; then
  ok "-P8 exits 1 like -P1, so the parallel run is still gating"
else
  nope "-P1 rc=${P1_RC}, -P8 rc=${P8_RC}, wanted 1 and 1"
fi

if [ -n "$P1_OK" ] && [ "$P1_OK" = "$P8_OK" ]; then
  ok "-P8 reports the same OK lines as -P1 — no job's outcome went missing"
else
  nope "-P8 and -P1 disagree on the OK lines"
  printf '        -P1:\n%s\n        -P8:\n%s\n' "$P1_OK" "$P8_OK"
fi

# ===========================================================================
echo
echo "== part 2e: --changed-only — a cache that cannot report a stale verdict =="
# ===========================================================================
# THE WORSE OF THE TWO DEFECTS, in the parent bead's words: a mode that exits 0
# without saying what it did not verify is the defect, and a mode that caches a
# verdict across a TLC build change is the worse one. So the key covers all
# eight inputs that decide a verdict — the jar, verdict.sh, the item, the
# module, the recorded rc, the deadlock flag, the timeout, and the item's whole
# verify/ tree — and these controls pin the two that an obvious implementation
# would drop.
#
# EVERY RUN HERE PASSES --state. The default is <repo-root>/.drill-gate-state,
# and a suite that wrote there would leave a file behind on every invocation
# and share one cache with the real tree.
R_CH="${TMP}/changed"
mkdir -p "$R_CH"
mk_inventory "$R_CH"
mk_item "$R_CH" "liveness/01-served"
ST_CH="${TMP}/changed.state"

run_gate --changed-only --state "$ST_CH" "$R_CH"
rc_is "--changed-only: rc 0 on the first run" 0
has   "--changed-only: with no state file every job runs" \
      "2 job(s) verified, 0 from cache, 0 stale"
has   "--changed-only: and the run says the state file did not exist" "NO STATE FILE EXISTED"
has   "--changed-only: the first run actually ran the job" "Good.tla rc=0"

run_gate --changed-only --state "$ST_CH" "$R_CH"
rc_is "--changed-only: rc 0 on the second run" 0
has   "--changed-only: the second run takes both jobs from cache" \
      "0 job(s) verified, 2 from cache, 0 stale"
has   "--changed-only: and names each cached job" "CACHED  liveness/01-served  Good.tla rc=0"
hasnt "--changed-only: a cached job runs no TLC, so it prints no OK line" \
      "  OK    liveness/01-served  Good.tla"
has   "--changed-only: and the header says a cached job is verified, not skipped" \
      "A CACHED JOB IS VERIFIED, not skipped"

# The module's bytes change and the verdict does not. The job must run again
# anyway: the cache answers "has anything that decides this verdict changed",
# never "did the answer change", which it cannot know without running.
printf '\\* a comment: new bytes, same verdict\n' >>"${R_CH}/liveness/01-served/verify/Good.tla"
run_gate --changed-only --state "$ST_CH" "$R_CH"
has   "--changed-only: a module byte change re-runs that item's jobs" \
      "2 job(s) verified, 0 from cache, 2 stale"
has   "--changed-only: and the re-run reports OK rather than cached" "Good.tla rc=0"

# THE TREE-DIGEST DECISION, and this is the control that pins it. The file
# below is neither a module nor a .cfg, so a key over the module-and-cfg pair
# would report this run as fully cached. A module can EXTENDS a sibling
# helper, so a helper edit changes what TLC checks while leaving the module
# byte-identical — and a cache that missed it would report a stale verdict as
# verified, which is the one failure this cache must not have.
printf 'Helper == TRUE\n' >"${R_CH}/liveness/01-served/verify/sibling.txt"
run_gate --changed-only --state "$ST_CH" "$R_CH"
has "--changed-only: a change to a NON-module file under verify/ re-runs the jobs" \
    "2 job(s) verified, 0 from cache, 2 stale"

# A mismatch records nothing, so the next run re-runs it rather than caching a
# failure as verified.
sed -e 's/| Wrong | Wrong.cfg | 13 |/| Wrong | Wrong.cfg | 12 |/' \
  "${R_CH}/liveness/01-served/ANSWER.md" >"${R_CH}/liveness/01-served/A.new"
mv "${R_CH}/liveness/01-served/A.new" "${R_CH}/liveness/01-served/ANSWER.md"
run_gate --changed-only --state "$ST_CH" "$R_CH"
rc_is "--changed-only: a mismatch still exits 1" 1
run_gate --changed-only --state "$ST_CH" "$R_CH"
has "--changed-only: a job that did NOT match is not cached as verified" \
    "Wrong.tla: ANSWER.md records rc 12, TLC returned 13"

# ONLY the mode that was asked to cache writes the state file. Otherwise the
# default and static tiers would leave a file in the repo root on every run.
rm -f "$ST_CH"
run_gate --state "$ST_CH" "$R_CH"
if [ ! -f "$ST_CH" ]; then
  ok "a run without --changed-only writes no state file"
else
  nope "a run without --changed-only wrote ${ST_CH}"
fi

# AND THE STATIC TIERS COMPUTE NO KEY AT ALL. This is the fork-budget
# guarantee made visible: a sha256 is a fork per job, and part 2b holds the
# static pass to a ceiling. If this row goes red, key computation has moved
# onto the static path.
#
# rc 0 AND NOT 1 HERE, which is the mode doing its job rather than missing
# the mismatch. The fixture above records rc 12 for Wrong.tla where TLC
# returns 13, and 12 IS a row of verdict.sh's table — so there is nothing
# structurally wrong with the item and the only way to catch it is to run TLC.
# That is precisely what --static-only says it did not do, and the count in
# its block is where it says so.
rm -f "$ST_CH"
run_gate --static-only --changed-only --state "$ST_CH" "$R_CH"
rc_is "--static-only with --changed-only: rc 0, since an in-table rc is structurally sound" 0
has "--static-only with --changed-only verifies and caches nothing" \
    "0 job(s) verified, 0 from cache, 0 stale"
has "--static-only with --changed-only says why nothing was consulted" \
    "NO JOB REACHED THE QUEUE"
has "--static-only still names the rcs it did not reproduce" \
    "2 recorded rc(s) not reproduced, no TLC ran."
if [ ! -f "$ST_CH" ]; then
  ok "--static-only computes no cache key and writes no state file"
else
  nope "--static-only wrote ${ST_CH}, so it computed keys on the static path"
fi

# ---------------------------------------------------------------------------
# THE WRAPPER SHAPE THE JAR IS READ OUT OF, and the four rows under it.
#
# The key covers the TLC build, and the build comes out of the `tlc` wrapper on
# PATH. TWO WRAPPER SHAPES ARE IN USE and the gate read one of them.
# scripts/setup:208 writes a `JAR=` line. The CI workflow writes its own
# wrapper inline at .github/workflows/verify-puzzles.yml:130-132, puts the jar
# straight into `-cp`, and carries no `JAR=` line at all. Its heredoc is
# unquoted, so `$HOME` is already expanded in the file.
#
# So every --changed-only row above passed on the author's box and returned 99
# in CI. Nine rows, twice in one session, which is bead tla-dnwi.
#
# THE SECOND DEFECT IS THE ONE ROWS 2 AND 3 PIN. Failing to resolve the jar
# used to report UNCHECKED, and UNCHECKED escalates to rc 99,
# CHECK_DID_NOT_RUN. Declining to cache is not a failure to check: every job
# ran and every recorded rc reproduced. So those rows want rc 0 and a DECLARED
# line, which prints and does not escalate.
#
# ROW 4 IS WHAT STOPS THE FIX FROM TURNING THE CACHE'S SOUNDNESS OFF. The jar
# still has to enter the key, or the gate carries a verdict across a build
# change, and that is the worse of the two failures here.
R_JAR="${TMP}/jarshape"
mkdir -p "$R_JAR"
mk_inventory "$R_JAR"
mk_item "$R_JAR" "liveness/01-served"
ST_JAR="${TMP}/jarshape.state"

# The jar every pinned wrapper names, at the one path scripts/setup:70-72 and
# .github/workflows/verify-puzzles.yml:121 both write it to. The rows below
# need a working jar to point a fixture `-cp` at, and reading the path out of
# the live wrapper would test resolve_jar with resolve_jar.
REAL_JAR="${HOME}/lib/tla2tools.jar"
REAL_TLC="$(command -v tlc 2>/dev/null || true)"

if [ ! -f "$REAL_JAR" ] || [ ! -x "$REAL_TLC" ]; then
  nope "wrapper shapes: ${REAL_JAR} or the pinned tlc wrapper is missing, so the four wrapper rows did not run"
else
  # ROW 1. The CI workflow's line, with $HOME expanded the way its unquoted
  # heredoc expands it, and no `JAR=` line anywhere in the file.
  mkdir -p "${TMP}/bin-cp"
  cat >"${TMP}/bin-cp/tlc" <<EOF
#!/usr/bin/env bash
exec java -XX:+UseParallelGC -cp "${REAL_JAR}" tlc2.TLC "\$@"
EOF
  chmod +x "${TMP}/bin-cp/tlc"

  run_gate_with_tlc "${TMP}/bin-cp" --changed-only --state "$ST_JAR" "$R_JAR"
  rc_is "a wrapper with the jar in -cp and no JAR= line: rc 0" 0
  has   "a wrapper with the jar in -cp and no JAR= line: the jar resolved, so the run cached" \
        "2 job(s) verified, 0 from cache, 0 stale"
  hasnt "a wrapper with the jar in -cp and no JAR= line: nothing reports a check that could not run" \
        "UNCHECKED verify-cache"
  run_gate_with_tlc "${TMP}/bin-cp" --changed-only --state "$ST_JAR" "$R_JAR"
  has   "a wrapper with the jar in -cp and no JAR= line: the next run reads the key back" \
        "0 job(s) verified, 2 from cache, 0 stale"

  # ROW 4, run here because it needs row 1's state file. Same corpus, same
  # wrapper shape, same state file, and only the jar's bytes differ. Without
  # the jar in the key this reads as fully cached, which is a verdict carried
  # across a build change. One appended byte is enough and the copy still
  # runs: a jar is a zip, and java finds the central directory by scanning
  # back from the end.
  mkdir -p "${TMP}/altjar" "${TMP}/bin-altjar"
  cp "$REAL_JAR" "${TMP}/altjar/tla2tools.jar"
  printf 'x' >>"${TMP}/altjar/tla2tools.jar"
  cat >"${TMP}/bin-altjar/tlc" <<EOF
#!/usr/bin/env bash
exec java -XX:+UseParallelGC -cp "${TMP}/altjar/tla2tools.jar" tlc2.TLC "\$@"
EOF
  chmod +x "${TMP}/bin-altjar/tlc"

  run_gate_with_tlc "${TMP}/bin-altjar" --changed-only --state "$ST_JAR" "$R_JAR"
  rc_is "a different jar: rc 0" 0
  has   "a different jar changes the key, so the jobs run again rather than coming from cache" \
        "2 job(s) verified, 0 from cache, 2 stale"

  # ROW 2. A wrapper that names no jar this gate can read. It delegates to the
  # pinned wrapper, so the corpus still verifies and the key is the only thing
  # missing.
  mkdir -p "${TMP}/bin-nojar"
  cat >"${TMP}/bin-nojar/tlc" <<EOF
#!/usr/bin/env bash
exec "${REAL_TLC}" "\$@"
EOF
  chmod +x "${TMP}/bin-nojar/tlc"

  rm -f "$ST_JAR"
  run_gate_with_tlc "${TMP}/bin-nojar" --changed-only --state "$ST_JAR" "$R_JAR"
  rc_is "a wrapper naming no jar: rc 0 over a clean corpus" 0
  has   "a wrapper naming no jar: the run says the cache is off" \
        "NO CACHE WAS CONSULTED"
  has   "a wrapper naming no jar: and says why as a DECLARED line, which does not escalate" \
        "DECLARED  verify-cache"
  hasnt "a wrapper naming no jar: never as UNCHECKED, which exits 99" \
        "UNCHECKED verify-cache"
  has   "a wrapper naming no jar: every job still ran" \
        "2 job(s) verified, 0 from cache, 0 stale"
  if [ ! -f "$ST_JAR" ]; then
    ok "a wrapper naming no jar writes no state file"
  else
    nope "a wrapper naming no jar wrote ${ST_JAR}, so it cached against an unknown build"
  fi

  # ROW 3. Both shapes resolve_jar reads, both naming a jar that is not there.
  # The `-cp` repeats the path rather than using `$JAR`, so the row covers the
  # shape CI writes as well as the one scripts/setup writes. The guard keeps
  # the branch live code: resolve_jar reads text and would parse a commented
  # line just the same.
  mkdir -p "${TMP}/bin-gonejar"
  cat >"${TMP}/bin-gonejar/tlc" <<EOF
#!/usr/bin/env bash
JAR="${TMP}/gone/tla2tools.jar"
if [ -f "\$JAR" ]; then
  exec java -XX:+UseParallelGC -cp "${TMP}/gone/tla2tools.jar" tlc2.TLC "\$@"
fi
exec "${REAL_TLC}" "\$@"
EOF
  chmod +x "${TMP}/bin-gonejar/tlc"

  rm -f "$ST_JAR"
  run_gate_with_tlc "${TMP}/bin-gonejar" --changed-only --state "$ST_JAR" "$R_JAR"
  rc_is "a wrapper naming a jar that is not there: rc 0 over a clean corpus" 0
  has   "a wrapper naming a jar that is not there: the run says the cache is off" \
        "NO CACHE WAS CONSULTED"
  has   "a wrapper naming a jar that is not there: and says why as a DECLARED line" \
        "DECLARED  verify-cache"
  hasnt "a wrapper naming a jar that is not there: never as UNCHECKED" \
        "UNCHECKED verify-cache"
  has   "a wrapper naming a jar that is not there: every job still ran" \
        "2 job(s) verified, 0 from cache, 0 stale"
  if [ ! -f "$ST_JAR" ]; then
    ok "a wrapper naming a jar that is not there writes no state file"
  else
    nope "a wrapper naming a jar that is not there wrote ${ST_JAR}"
  fi
fi

# ===========================================================================
echo
echo "== part 3: the real drill/ tree =="
# ===========================================================================
# The arm itself, and the three states it handles, are defined as
# real_tree_arm() above the fixture section, because --static and --full-sweep
# call it on its own. Unflagged, it puts the --changed-only question to the
# tree, so the per-commit cost is proportional to what changed rather than to
# the size of the corpus. scripts/cibuild runs --full-sweep.
real_tree_arm

# ===========================================================================
summary_and_exit
