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

# Measured 2026-10-22, bead tla-6hrt. 48 of 64 items carry at least one machine
# this instrument can bind. The other 16 are the modules and state-space
# families entire.
#
# IT READ 40 AND 24 UNTIL THIS BEAD, and the history is the reason the number
# is pinned rather than described. The first wording said those families
# compose state away through INSTANCE or EXTENDS. That is true of the per-run
# wrapper modules and false of the module underneath them:
# drill/temporal/07-pipeline-halt/verify/Pipeline.tla:7 reads
# VARIABLES stage, artifact, retries. The state was declared one level down and
# the scan was reading the wrong file, so those items were out of reach because
# of where the instrument looked rather than because of how they are built.
#
# The temporal family was furthest from that wording. All 8 of its items ship
# verify/MATRIX and verify/MODULE, a manifest naming the base module and the
# SPECIFICATION each run uses, which no other family has. It is the best
# described family in the corpus, not the least, and it is now the one family
# whose machines refute.sh composes itself.
#
# MODULES AND STATE-SPACE ARE STILL 0 AND THAT IS A SCOPE LINE, not a finding
# about them. Measured the same day:
# drill/modules/01-*/verify/G01Pair.tla is two lines that EXTEND TankPair,
# exactly the shape refute.sh's vars_in_closure was written for. They stay out
# because widening the ANSWER.md path's state test would move this number again
# over machines nobody has run, and that is its own measurement.
# ONE PASS OVER ALL 64, AND EVERY LATER QUESTION READS ITS RESULT. Enumerating
# a temporal item is not free -- it walks each row's EXTENDS chain -- and this
# part used to ask the same question of the same items three times before part
# 4 asked a fourth. Measured 2026-10-22: 0.73 s for the 8 temporal items per
# pass, so four passes were 2.2 s of the suite spent re-deriving an answer it
# already had.
declare -A LIST_OUT=()
declare -A FAM_N=()
reach=0
for d in drill/*/*/; do
  it="${d#drill/}"; it="${it%/}"
  if lout="$(harness/refute.sh --list-machines --item "$it" 2>/dev/null)"; then
    reach=$((reach + 1))
    LIST_OUT[$it]="$lout"
    fam="${it%%/*}"
    FAM_N[$fam]=$(( ${FAM_N[$fam]:-0} + 1 ))
  fi
done
check "48 of 64 items are in reach" "$reach" "48"

for fam in modules state-space; do
  check "the $fam family is out of reach entirely" "${FAM_N[$fam]:-0}" "0"
done

# THE TEMPORAL FAMILY IS PINNED AT ALL 8, not at "more than none". A manifest
# reader that parsed 5 items and dropped 3 would pass a floor and fail here.
check "all 8 temporal items are in reach" "${FAM_N[temporal]:-0}" "8"

# AND THE PER-ITEM MACHINE COUNTS, because the count is where the manifest is
# actually read. Measured 2026-10-22. These are the distinct module,
# SPECIFICATION and Rows triples each MATRIX lists, which is fewer than its row
# count: 07-pipeline-halt lists 11 rows over 2 machines, because a row's own
# obligation is the row's business and the machine underneath it repeats.
#
# 07 reads 2 rather than 3 for a second reason worth keeping. Its n3-buggy row
# names PipelineRefused, a module the tools refuse outright, and
# PipelineRefused!Spec IS Pipeline!Spec, so resolving the SPECIFICATION to the
# module that defines it makes that row the machine it was always about. Before
# that it was a third column reading 150 on every obligation.
for pair in \
  "temporal/01-print-job|7" \
  "temporal/02-heartbeat|6" \
  "temporal/03-commit-sticks|9" \
  "temporal/04-revision-freeze|9" \
  "temporal/05-flaky-link|10" \
  "temporal/06-help-desk|7" \
  "temporal/07-pipeline-halt|2" \
  "temporal/08-turnstile-clock|6"
do
  item="${pair%%|*}"
  want="${pair#*|}"
  got="$(sed -e 's/^.*: //' -e 's/ runnable.*$//' <<<"${LIST_OUT[$item]:-}")"
  check "$item reads $want machine(s) off its manifest" "$got" "$want"
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
echo "== part 3b: the manifest path, and the four states it has to tell apart =="

# WHY A FIXTURE AND NOT A SHIPPED ITEM. Measured 2026-10-22 by driving every
# machine of all 8 temporal items with a tautological invariant, so that every
# cell came back 0 and every machine was probed: 56 machines, every one
# runnable, every one admitting a behavior. The shipped corpus cannot make the
# vacuity pairing fire, and a check nobody has watched fail is not evidence
# that it works. So the fixture carries the one shape that does fire.
#
# THE SHAPE IS THE ONE .claude/rules/tla-practice.md MEASURED on this TLC
# build: a fairness conjunct over an action [][Next]_vars forbids leaves no
# behavior at all, and TLC then exits 0 on every temporal property. SpecEmpty
# below is Init /\ [][Next]_vars /\ WF_vars(Jump) where Jump is s' = 99 and
# Next never allows it. SpecAdmits is the same system without the conjunct.
#
# Watched failing first, 2026-10-22, with the pairing switched off: the
# SpecEmpty column read 0 on both obligations, which is exactly what a correct
# obligation set reads. That is the failure this part closes.
#
# REFUTE_DRILL_ROOT is how the fixture is reached. refute.sh reads the repo's
# drill tree and nothing else sets this.
FX="$WORK/droot/temporal/00-pairing"
mkdir -p "$FX/verify" "$WORK/attempt"

cat >"$FX/verify/AdmitBox.tla" <<'TLA'
---- MODULE AdmitBox ----
EXTENDS Naturals
VARIABLES s
vars == << s >>
Init == s = 0
Up == s < 2 /\ s' = s + 1
Jump == s' = 99
Next == Up
SpecAdmits == Init /\ [][Next]_vars
SpecEmpty == Init /\ [][Next]_vars /\ WF_vars(Jump)
====
TLA
printf 'AdmitBox\n' >"$FX/verify/MODULE"
printf 'tag-admits\t-\tSPECIFICATION SpecAdmits\n' >"$FX/verify/MATRIX"
printf 'tag-empty\t-\tSPECIFICATION SpecEmpty\n' >>"$FX/verify/MATRIX"

# OutsideDomain IS THE FOURTH STATE AND IT IS THE LEARNER'S OWN MISTAKE. It
# indexes a function outside its domain, which TLC cannot evaluate, so nothing
# at all is established about it on any machine. The code is non-zero, so
# beside a 0 and a 13 it reads as a refutation unless the output says
# otherwise, and a learner who indexed a sequence the wrong way would be
# credited with catching every machine the item ships.
#
# Measured 2026-10-22 on this build, twice and independently: central read 75
# off core-language-docs/snippets/functions-records/Outside.tla, which that
# family's CASES pins at 75, and this obligation reads 75 through refute.sh's
# own probe path. The assertion below is about the BUCKET rather than the
# number, because the bucket is what must hold for a code nobody has met.
cat >"$WORK/attempt/Ob.tla" <<'TLA'
---- MODULE Ob ----
EXTENDS Naturals
VARIABLES s
NeverNegative == [](s >= 0)
ReachesJump == []<>(s = 99)
OneOnly == [x \in {1} |-> x]
OutsideDomain == [](OneOnly[s] = 1)
====
TLA
printf 'PROPERTY NeverNegative\nPROPERTY ReachesJump\nPROPERTY OutsideDomain\n' \
  >"$WORK/attempt/Ob.cfg"

export REFUTE_DRILL_ROOT="$WORK/droot"
fxlist="$(harness/refute.sh --list-machines --item temporal/00-pairing 2>&1)"
fxn="$(sed -e 's/^.*: //' -e 's/ runnable.*$//' <<<"$fxlist")"
check "the fixture's manifest reads 2 machines" "${fxn:-0}" "2"

fxout="$(harness/refute.sh --attempt "$WORK/attempt" --item temporal/00-pairing 2>&1)"
fxrc=$?
unset REFUTE_DRILL_ROOT
check "the fixture run exits 0" "$fxrc" "0"

# The n-th machine column of an obligation's row. The row is the obligation
# name, then its KIND, then one cell per machine.
cell() { awk -v r="$1" -v n="$2" '$1 == r { print $(2 + n) }' <<<"$fxout"; }

check "a live machine's 0 is reported as 0" "$(cell NeverNegative 1)" "0"
check "a machine admitting no behavior reads vac, never 0" "$(cell NeverNegative 2)" "vac"
check "the named SPECIFICATION really substitutes" "$(cell ReachesJump 1)" "13"
check "and its empty twin reports vac rather than that refutation" "$(cell ReachesJump 2)" "vac"

if grep -qE 'vacuity: 1 machine\(s\) admit no behavior, 1 do, 0 could not be probed' <<<"$fxout"; then
  ok "the summary counts both machines and claims nothing it did not probe"
else
  bad "the vacuity summary did not count 1 and 1: $(grep -E '^vacuity:' <<<"$fxout" || true)"
fi

# THE FOURTH STATE. A code this script does not interpret must be reported as
# a run that established nothing, never left to read as a refutation.
check "an obligation TLC cannot evaluate reads the same on both machines" \
  "$(cell OutsideDomain 1)" "$(cell OutsideDomain 2)"
if grep -qE '^cells: 1 refute a machine, 1 are silent, 2 are vacuous, 2 established nothing$' <<<"$fxout"; then
  ok "all four states are counted and the unevaluable pair is in neither finding"
else
  bad "the cell counts are wrong: $(grep -E '^cells:' <<<"$fxout" || true)"
fi

# AND THE LEGEND CLOSES RATHER THAN ENUMERATES. The failure this guards is a
# new TLC code arriving and printing bare, which no list of codes can catch.
if grep -qE 'ANY OTHER CODE' <<<"$fxout" \
   && grep -qE 'falls in' <<<"$fxout"; then
  ok "the legend buckets every code it does not interpret"
else
  bad "the legend enumerates codes without a bucket for the rest"
fi

# THE PAIRING MUST NOT FIRE WHERE IT WAS NOT ASKED FOR. The ANSWER.md path's
# machines are pairs the item already ran and recorded an rc for, and 24 TLC
# runs per table is already the cost. A vac appearing there would be three runs
# per silent cell that nobody asked for.
if [ -f "${ATTEMPT}/Triage.tla" ]; then
  if grep -qE '(^|[[:space:]])vac\??([[:space:]]|$)' <<<"$out"; then
    bad "the vacuity pairing fired on the ANSWER.md path, which never asked for it"
  else
    ok "the ANSWER.md path reports no vac, so the pairing stayed where it was asked"
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

# A MATRIX TAG IS THE SAME HAZARD AS A MODULE NAME, and on this family it is
# worse. 07-pipeline-halt's tags include answer-prop-buggy and n3-buggy, so a
# tag says which spec is the answer and which neighbor is the trap. A
# SPECIFICATION name does it too: SpecFixed against Spec is the whole item.
# The machines are numbered m1 upward and nothing else about them is printed.
leaked=0
for nm in AdmitBox SpecAdmits SpecEmpty tag-admits tag-empty; do
  if grep -q -- "$nm" <<<"$fxout"; then
    bad "the output named $nm, which the manifest path must withhold"
    leaked=1
  fi
done
[ "$leaked" -eq 0 ] && ok "no manifest tag, module or SPECIFICATION name reached the full run"

# The same question of --list-machines, over every shipped temporal item, which
# costs no TLC run. The tags and spec names come out of the manifests rather
# than out of a list written here, so an item gaining a row is covered the day
# it lands.
leaked=0
for d in drill/temporal/*/; do
  it="${d#drill/}"; it="${it%/}"
  lout="$(harness/refute.sh --list-machines --item "$it" 2>&1)"
  names="$(sed -e 's/^#.*$//' -e 's/\r$//' "${d}verify/MATRIX" \
    | sed -e 's/\t/ /g' -e 's/\\\* MODULE: */ /' -e 's/SPECIFICATION  */ /' \
    | tr ' ;' '\n' | grep -E '^[A-Za-z][A-Za-z0-9_-]*$' | sort -u)"
  names="$names
$(tr -d '[:space:]' <"${d}verify/MODULE")"
  while IFS= read -r nm; do
    [ -n "$nm" ] || continue
    case "$nm" in INVARIANT|PROPERTY|CHECK_DEADLOCK|TRUE|FALSE) continue ;; esac
    if grep -q -- "$nm" <<<"$lout"; then
      bad "--list-machines on $it named $nm"
      leaked=1
    fi
  done <<<"$names"
done
[ "$leaked" -eq 0 ] && ok "and --list-machines names none of them on any of the 8 items"

echo
if [ "$fail" -eq 0 ]; then
  echo "OK: $pass assertions passed"
  exit 0
fi
echo "FAILED: $fail of $((pass + fail)) assertions" >&2
exit 1
