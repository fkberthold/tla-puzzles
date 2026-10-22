#!/usr/bin/env bash
# harness/test-refute.sh — gate harness/refute.sh.
#
# The instrument's whole claim is that an exit code beats a reading, so the
# assertions here are about the codes it reports and about the three ways it
# can report nothing. A run that silently drops an obligation, or prints 150
# for a machine this method cannot bind as though that were a measurement, is
# the failure the instrument exists to replace rather than a smaller version
# of it.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}" || exit 1

pass=0
fail=0
ok()   { pass=$((pass + 1)); echo "  PASS  $1"; }
bad()  { fail=$((fail + 1)); echo "  FAIL  $1" >&2; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }

WORK="$(mktemp -d)"
# Reached through the EXIT trap below, which shellcheck does not follow.
# shellcheck disable=SC2317
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "== part 1: it refuses rather than half-running =="

out="$(harness/refute.sh 2>&1)"; rc=$?
check "no --item is rc 2" "$rc" "2"
if grep -q -- "--item" <<<"$out"; then ok "and it names the missing argument"; else bad "it did not name --item"; fi

out="$(harness/refute.sh --item no-such/item 2>&1)"; rc=$?
check "an item with no verify/ is rc 2" "$rc" "2"

out="$(harness/refute.sh --item sequences/01-triage-board --attempt "$WORK" 2>&1)"; rc=$?
check "an attempt directory with no module is rc 2" "$rc" "2"

echo
echo "== part 2: it enumerates machines across all three ANSWER.md dialects =="

# Measured 2026-10-21. The rc table is written three ways across the corpus
# and nothing had ever read it, so these three items pin one dialect each.
for pair in \
  "core/01-box-office|backticked name, no extension" \
  "functions-records/02-charging-bays|backticked name carrying .tla" \
  "control-state/01-slip-on-the-spike|bare name, no backticks"
do
  item="${pair%%|*}"
  what="${pair#*|}"
  out="$(harness/refute.sh --list-machines --item "$item" 2>&1)"; rc=$?
  n="$(sed -e 's/^.*: //' -e 's/ runnable.*$//' <<<"$out")"
  if [ "$rc" = "0" ] && [ "${n:-0}" -gt 0 ] 2>/dev/null; then
    ok "$item parses ($what): $n machine(s)"
  else
    bad "$item found no machine ($what): $out"
  fi
done

echo
echo "== part 2b: the reach, pinned so a change cannot silently narrow it =="

# Measured 2026-10-21. 40 of 64 items carry at least one machine that declares
# its own state where this scan looks for it. The other 24 are the modules,
# state-space and temporal families entire.
#
# AMENDED THE SAME DAY, because the first wording of this comment was wrong
# about why. It said those families compose state away through INSTANCE or
# EXTENDS. That is true of the per-run wrapper modules and false of the module
# underneath them: drill/temporal/07-pipeline-halt/verify/Pipeline.tla:7 reads
# VARIABLES stage, artifact, retries. The state is declared one level down and
# this scan is reading the wrong file, so 24 items are out of reach because of
# where the instrument looks rather than because of how they are built.
#
# The temporal family is further from that wording still. All 8 of its items
# ship verify/MATRIX and verify/MODULE, a manifest naming the base module and
# the SPECIFICATION each run uses, which no other family has. It is the best
# described family in the corpus, not the least. Filed as tla-6hrt.
#
# The number stays pinned rather than described either way, because a
# description of a limit is what drifts, and this comment is the proof.
reach=0
for d in drill/*/*/; do
  it="${d#drill/}"; it="${it%/}"
  if harness/refute.sh --list-machines --item "$it" >/dev/null 2>&1; then
    reach=$((reach + 1))
  fi
done
check "40 of 64 items are in reach" "$reach" "40"

for fam in modules state-space temporal; do
  n=0
  for d in drill/"$fam"/*/; do
    it="${d#drill/}"; it="${it%/}"
    harness/refute.sh --list-machines --item "$it" >/dev/null 2>&1 && n=$((n + 1))
  done
  check "the $fam family is out of reach entirely" "$n" "0"
done

echo
echo "== part 3: the triage table, which is the measurement the bead rests on =="

ATTEMPT="${DRILL_STUDY_ROOT:-$HOME/Study/tla-drills}/01-triage-board"
if [ ! -f "${ATTEMPT}/Triage.tla" ]; then
  echo "  SKIP  no delivered attempt at ${ATTEMPT}; part 3 needs one"
else
  out="$(harness/refute.sh --attempt "$ATTEMPT" --item sequences/01-triage-board 2>&1)"; rc=$?
  check "the run exits 0" "$rc" "0"

  # ONE ROW PER DECLARED OBLIGATION. Frank's own cfg carries a trailing space
  # after BoardEitherGrowsOrShrinksByOne, and the first draft of the parser
  # dropped it and printed seven rows for eight obligations with nothing said.
  declared="$(sed -e 's/\\\*.*$//' "${ATTEMPT}/Triage.cfg" \
    | grep -cE '^[[:space:]]*(INVARIANTS?|PROPERTY|PROPERTIES)[[:space:]]' || true)"
  rows="$(grep -cE '^[A-Za-z][A-Za-z0-9_]*[[:space:]]+(INVARIANT|PROPERTY)' <<<"$out" || true)"
  check "every declared obligation got a row" "$rows" "$declared"

  for ob in TypeOK BoardDoesntExceedMaxSize GreatestSeverityAlwaysPicked \
            PatientAlwaysPickedFromBoard TreatedListOnlyGrowsByOne \
            BoardEitherGrowsOrShrinksByOne RemovedPatientIsAlwaysTreated \
            TreatedPatientIsAlwaysRemoved
  do
    if grep -qE "^${ob}[[:space:]]" <<<"$out"; then
      ok "$ob is in the table"
    else
      bad "$ob is missing from the table"
    fi
  done

  # THE ONE THAT CONTRADICTS THE CHECK. Nine ./drill --check runs reported
  # that GreatestSeverityAlwaysPicked would never catch a doctor who broke the
  # rule. It refutes one of the machines the item ships.
  row="$(grep -E '^GreatestSeverityAlwaysPicked[[:space:]]' <<<"$out" || true)"
  if grep -qE '(^| )13( |$)' <<<"$row"; then
    ok "GreatestSeverityAlwaysPicked refutes a machine at rc 13"
  else
    bad "GreatestSeverityAlwaysPicked refuted nothing: $row"
  fi

  row="$(grep -E '^BoardEitherGrowsOrShrinksByOne[[:space:]]' <<<"$out" || true)"
  if grep -qE '(^| )13( |$)' <<<"$row"; then
    ok "BoardEitherGrowsOrShrinksByOne refutes a machine at rc 13"
  else
    bad "BoardEitherGrowsOrShrinksByOne refuted nothing: $row"
  fi

  # NO COLUMN OF 150s. A machine declaring no state of its own cannot be bound
  # by this probe shape, and printing its 150 beside real codes reads like a
  # measurement. Those machines are skipped and counted instead.
  # SCAN THE OBLIGATION ROWS, NOT THE WHOLE OUTPUT. The first draft matched
  # the run's own legend line, which names 150 as one of the codes it would
  # report. An assertion that reads the explanation instead of the data is red
  # on a correct run, which is how a real gate gets weakened to make it pass.
  obrows="$(grep -E '^[A-Za-z][A-Za-z0-9_]*[[:space:]]+(INVARIANT|PROPERTY)' <<<"$out" || true)"
  if grep -qE '(^|[[:space:]])150([[:space:]]|$)' <<<"$obrows"; then
    bad "a 150 reached the table; a machine this method cannot bind must be skipped"
  else
    ok "no 150 in the table: unbindable machines are skipped, not reported"
  fi

  if grep -qE 'declare no state of their own' <<<"$out"; then
    ok "and the run says how many it left out"
  else
    bad "the run did not say what it left out"
  fi
fi

echo
echo "== part 4: it never prints a machine's name or what it is wrong about =="

if [ -f "${ATTEMPT}/Triage.tla" ]; then
  leaked=0
  for nm in TriageFifo TriageSelect TriageRef; do
    if grep -q "$nm" <<<"$out"; then
      bad "the output named the machine $nm, which states the item's trap"
      leaked=1
    fi
  done
  [ "$leaked" -eq 0 ] && ok "no machine name reached the output"

  if grep -qiE 'queue|filter|the answer' <<<"$out"; then
    bad "ANSWER.md prose about a variant reached the output"
  else
    ok "no ANSWER.md prose about a variant reached the output"
  fi
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "OK: $pass assertions passed"
  exit 0
fi
echo "FAILED: $fail of $((pass + fail)) assertions" >&2
exit 1
