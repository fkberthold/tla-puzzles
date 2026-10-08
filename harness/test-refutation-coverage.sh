#!/usr/bin/env bash
# test-refutation-coverage.sh: gate for bead tla-n8oq.
#
# THE DEFECT. A statement's requirement set goes green over a model that does
# not contain the mechanism the problem is about. The learner finishes, every
# check passes, and they never meet the defect. Three of three step-5
# consistency checks on 2026-10-08 returned NOT SUFFICIENT for this reason, and
# the three statements were written by authors who had read the guidance.
#
# The pattern has two faces. A requirement satisfiable by DOING LESS: acme's
# nine requirements all hold at rc 0, 16 states, depth 5, over a model whose
# retry loop never turns, and progressive-sync's seven hold at rc 0, 14 states,
# depth 11, over a model with no board and no clerk. And a requirement NO
# PERMITTED MODEL CAN VIOLATE: imap-move's PROBLEM.md:96 removes the action
# instead of forbidding the outcome, so requirement 1 at :177 is true by
# construction. A reachability deliverable catches only the first face. The rule
# that catches both is in PRACTICE-PLAN.md, under the prose pipeline.
#
# WHAT IS GATED HERE, AND WHAT IS NOT. The rule itself is semantic and no shell
# script decides it. harness/refutation-coverage.sh checks the instrument the
# rule is enforced through, a violating run authored per requirement, and its
# header says in detail what it does not look at. This suite is that script's
# controls plus the pin below.
#
# WHY A PIN AND NOT "EVERY PACKAGE MUST BE OK". Eight of sixteen packages are
# not OK today and five of those are the open work this bead exists to block.
# A gate that simply went red would be a true report and a useless one: it says
# the same thing on the day somebody adds a ninth. So every package's verdict is
# pinned, one line each, with the reason it reads that way. A new package is not
# pinned and fails. A package whose verdict changes, by a fix, a regression, or a changed recognizer, fails. Nothing passes silently, and the
# pin cannot rot into a blanket exemption, because an entry that stops matching
# is itself a failure.
#
# Usage:  harness/test-refutation-coverage.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

CHECKER="${REPO_ROOT}/harness/refutation-coverage.sh"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

TMP="$(mktemp -d)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# PART 1: the mechanism, on fixtures.
#
# Each fixture is a statement package in the real shape, <name>/statement/.
# The three defect shapes are modelled from the three measured instances rather
# than invented, and each is named after the statement it comes from.
# ---------------------------------------------------------------------------

echo "== part 1: the checker's verdicts, on fixtures =="

# mk_pkg <root> <name> <count-line-or-empty> <n-trace-files> [extra-prose]
mk_pkg() {
  local root="$1" name="$2" countline="$3" ntraces="$4" extra="${5:-}"
  local sdir="${root}/${name}/statement"
  mkdir -p "$sdir"
  {
    printf '# The %s statement\n\n' "$name"
    printf '## The requirements\n\n'
    [ -n "$countline" ] && printf '%s\n\n' "$countline"
    [ -n "$extra" ] && printf '%s\n\n' "$extra"
    printf '1. **Something.** Declare it under INVARIANT.\n'
  } >"${sdir}/PROBLEM.md"
  if [ "$ntraces" != "-" ]; then
    mkdir -p "${sdir}/traces"
    printf '# Traces\n' >"${sdir}/traces/README.md"
    local i
    for ((i = 1; i <= ntraces; i++)); do
      printf '# Refutation %d\n' "$i" >"${sdir}/traces/requirement-${i}.md"
    done
  fi
}

# verdict_of <root> <name>: the checker's verdict token for one package.
verdict_of() {
  local out
  out="$(bash "$CHECKER" "$1" 2>&1)"
  awk -v pkg="$2" '$2 == pkg { print $1; exit }' <<<"$out"
}

# field_of <root> <name> <field-prefix>: e.g. requirements= or refutations=
field_of() {
  local out
  out="$(bash "$CHECKER" "$1" 2>&1)"
  awk -v pkg="$2" -v pre="$3" \
    '$2 == pkg { for (i = 3; i <= NF; i++) if (index($i, pre) == 1) { print substr($i, length(pre) + 1); exit } }' \
    <<<"$out"
}

FX="${TMP}/fixtures"

# The shape that passes. Three requirements, three refutations.
mk_pkg "$FX" good "Three requirements." 3

# acme-challenge-retry-deadlock and progressive-sync-stale-status: a full
# requirement set, no traces tree at all, so no refutation was ever attempted.
mk_pkg "$FX" acme-shape "Nine requirements." -

# imap-move-partial-failure: same absence, different cause. Requirement 1 has
# no violating run because the rules forbid the state that would refute it.
# From outside, the two are the same missing directory, which is exactly how
# far a mechanical check reaches, and why the header says so.
mk_pkg "$FX" imap-shape "Three requirements." -

# river-call: a traces tree that covers fewer requirements than the statement
# declares. Its PROBLEM.md:197 says so on purpose, "one pair per requirement
# past the first".
mk_pkg "$FX" under-shape "Four requirements." 3

# A traces directory holding nothing but its README.
mk_pkg "$FX" empty-shape "Two requirements." 0

# No count line anywhere.
mk_pkg "$FX" nocount-shape "" 2

# The anchor control. "a requirement" and "one requirement" appear mid-sentence
# in nine of this tree's statements, usually in the vacuity warning. A recogniser
# that matched anywhere in the line would read 1 here and pass a package that
# ships two refutations against five requirements.
mk_pkg "$FX" midline-shape "Five requirements." 2 \
  'A model can satisfy one requirement by doing nothing at all.'

# The first-match control. Two line-start counts. The first is the one the
# requirement list is introduced with.
mk_pkg "$FX" firstmatch-shape "Two requirements." 2 \
  'Nine requirements is what a longer statement would carry.'

declare -a FX_NAME=(good      acme-shape imap-shape under-shape   empty-shape   nocount-shape   midline-shape firstmatch-shape)
declare -a FX_WANT=(OK        NO_TRACES  NO_TRACES  UNDER_COVERED EMPTY_TRACES  NO_STATED_COUNT UNDER_COVERED OK)

for i in "${!FX_NAME[@]}"; do
  got="$(verdict_of "$FX" "${FX_NAME[$i]}")"
  if [ "$got" = "${FX_WANT[$i]}" ]; then
    ok "fixture ${FX_NAME[$i]} reads ${FX_WANT[$i]}"
  else
    nope "fixture ${FX_NAME[$i]} reads '${got:-<nothing>}', expected ${FX_WANT[$i]}"
  fi
done

# The two recogniser controls, on the count itself rather than the verdict.
got="$(field_of "$FX" midline-shape requirements=)"
if [ "$got" = "5" ]; then
  ok "a mid-line 'one requirement' does not displace the stated count (read 5)"
else
  nope "mid-line control read requirements=${got:-<nothing>}, expected 5"
fi

got="$(field_of "$FX" firstmatch-shape requirements=)"
if [ "$got" = "2" ]; then
  ok "the first line-start count is the one read (read 2)"
else
  nope "first-match control read requirements=${got:-<nothing>}, expected 2"
fi

# --- exit-code controls ----------------------------------------------------
#
# A checker that returned 0 unconditionally would satisfy every pin below, so
# its exit code is pinned in both directions and over the two refusal cases.

ONLYGOOD="${TMP}/onlygood"
mk_pkg "$ONLYGOOD" good "Three requirements." 3
bash "$CHECKER" "$ONLYGOOD" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  ok "checker exits 0 over a root where every package is OK"
else
  nope "checker exited $rc over an all-OK root"
fi

bash "$CHECKER" "$FX" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 1 ]; then
  ok "checker exits 1 over a root holding a defect shape"
else
  nope "checker exited $rc over a root holding six defect shapes, expected 1"
fi

EMPTYROOT="${TMP}/emptyroot"
mkdir -p "$EMPTYROOT"
bash "$CHECKER" "$EMPTYROOT" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 2 ]; then
  ok "checker exits 2 over a root with no statement package, rather than reporting success"
else
  nope "checker exited $rc over an empty root, expected 2"
fi

bash "$CHECKER" "${TMP}/does-not-exist" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 2 ]; then
  ok "checker exits 2 on a missing root"
else
  nope "checker exited $rc on a missing root, expected 2"
fi

# ---------------------------------------------------------------------------
# PART 2: the real tree, pinned package by package.
#
# PIN_VERDICT[i] is what harness/refutation-coverage.sh must say about
# PIN_PKG[i]. PIN_WHY[i] is why it says that and what has to happen for the pin
# to change. Measured 2026-10-08 against the tree at that date.
#
# TO UPDATE A PIN: run harness/refutation-coverage.sh, read the line, and change
# the verdict here only once you have read the package and agree with it. A pin
# edited to make this suite green is the gate switched off.
# ---------------------------------------------------------------------------

echo
echo "== part 2: authoring/, pinned package by package =="

declare -a PIN_PKG=()
declare -a PIN_VERDICT=()
declare -a PIN_WHY=()

pin() { PIN_PKG+=("$1"); PIN_VERDICT+=("$2"); PIN_WHY+=("$3"); }

pin acme-challenge-retry-deadlock NO_TRACES \
  "bead tla-n8oq: all nine requirements hold at rc 0, 16 states, depth 5, over a model whose retry loop never turns. No refutation was authored for any of them."
pin assay-office                  OK        ""
pin bonded-store                  OK        ""
pin buyclub                       OK        ""
pin consign                       OK        ""
pin custody                       NO_STATED_COUNT \
  "custody states its count as 'ten properties' mid-sentence at PROBLEM.md:190, which the line-start recogniser does not read. Its eleven trace files cover the ten, so this is the recogniser's limit rather than a coverage gap. Fix by stating the count at the head of the requirements section."
pin estate-notice                 OK        ""
pin floor-malting                 OK        ""
pin herbarium-sheet               OK        ""
pin imap-move-partial-failure     NO_TRACES \
  "bead tla-n8oq: requirement 1 at PROBLEM.md:177 is unfalsifiable, because PROBLEM.md:96 removes the action rather than forbidding the outcome. The refutation cannot be written until rule 3 is fixed, which is the point."
pin laytime                       OK        ""
pin progressive-sync-stale-status NO_TRACES \
  "bead tla-n8oq: all seven requirements hold at rc 0, 14 states, depth 11, over a model with no board and no clerk. No refutation was authored for any of them."
pin qsl                           NO_STATED_COUNT \
  "qsl has no requirements section at all; its PROBLEM.md goes from the interface straight to the traces. Nine trace files, no stated count to compare them against."
pin river-call                    UNDER_COVERED \
  "river-call declares four requirements and ships three pairs on purpose: PROBLEM.md:197 says 'one pair per requirement past the first', the first being the model's own type invariant. A type invariant IS refutable, so this is a convention question for central rather than an unfalsifiable requirement. Found by this gate, not reported to it."
pin seedlib                       NO_TRACES \
  "seedlib ships SeedLibrary.tla and SeedLibrary.cfg and no traces tree. Predates the per-requirement trace convention; not one of the three tla-n8oq instances."
pin txn-epoch-fence-vs-retry      NO_TRACES \
  "txn-epoch-fence-vs-retry ships PROBLEM.md alone. Not yet through step 5; not one of the three tla-n8oq instances."

REAL_OUT="$(bash "$CHECKER" "${REPO_ROOT}/authoring" 2>&1)"
real_rc=$?

if [ "$real_rc" -eq 2 ]; then
  nope "checker refused to read authoring/. Output follows"
  printf '%s\n' "$REAL_OUT" | sed 's/^/        /'
fi

declare -a PIN_HITS=()
for i in "${!PIN_PKG[@]}"; do PIN_HITS[i]=0; done

unpinned=""
mismatched=""
seen=0

while IFS= read -r line; do
  [ -n "$line" ] || continue
  verdict="${line%% *}"
  rest="${line#* }"
  pkg="${rest%% *}"
  # The checker pads with spaces, so strip what is left of the leading run.
  while [ "${pkg}" = "" ] && [ "$rest" != "" ]; do
    rest="${rest# }"
    pkg="${rest%% *}"
  done
  [ -n "$pkg" ] || continue
  seen=$((seen + 1))

  idx=-1
  for i in "${!PIN_PKG[@]}"; do
    if [ "${PIN_PKG[$i]}" = "$pkg" ]; then idx=$i; break; fi
  done

  if [ "$idx" -lt 0 ]; then
    unpinned="$unpinned
      $pkg  (reads $verdict)"
    continue
  fi

  PIN_HITS[idx]=$((PIN_HITS[idx] + 1))
  if [ "$verdict" != "${PIN_VERDICT[$idx]}" ]; then
    mismatched="$mismatched
      $pkg  pinned ${PIN_VERDICT[$idx]}, reads $verdict"
  fi
done <<<"$REAL_OUT"

if [ "$seen" -gt 0 ]; then
  ok "read $seen statement package(s) out of authoring/"
else
  nope "read no statement package out of authoring/. The sweep is vacuous"
fi

# A package nobody pinned is a package nobody looked at. This is the assertion
# that makes the gate bite on the NEXT statement rather than only on these.
if [ -z "$unpinned" ]; then
  ok "every package in authoring/ carries a pin"
else
  nope "package not pinned. Read it, decide, and add a pin line:$unpinned"
fi

if [ -z "$mismatched" ]; then
  ok "every package reads exactly as pinned"
else
  nope "verdict moved away from its pin, by a fix, a regression, or a changed recogniser:$mismatched"
fi

# A pin matching nothing is a standing claim about a package that is gone or
# renamed. Same shape as the allowlist-staleness assertion in test-pipefail.sh.
stale=""
for i in "${!PIN_PKG[@]}"; do
  if [ "${PIN_HITS[$i]}" -eq 0 ]; then
    stale="$stale
      ${PIN_PKG[$i]}  (pinned ${PIN_VERDICT[$i]})"
  fi
done
if [ -z "$stale" ]; then
  ok "all ${#PIN_PKG[@]} pins still match a package in authoring/"
else
  nope "pin matches no package. Delete it rather than leaving a standing claim:$stale"
fi

# ---------------------------------------------------------------------------
# The unconditional report. CLAUDE.md's gate-don't-advise rule forbids leaving a
# correctness check as something a human has to remember to run. Printing the
# open set in the normal output, every run, is what satisfies it for the part
# that needs a human decision, which statement to fix, and how.
# ---------------------------------------------------------------------------

open_block=""
open_n=0
for i in "${!PIN_PKG[@]}"; do
  if [ "${PIN_VERDICT[$i]}" != "OK" ]; then
    open_n=$((open_n + 1))
    open_block="$open_block
  - ${PIN_PKG[$i]}  [${PIN_VERDICT[$i]}]
      ${PIN_WHY[$i]}"
  fi
done

if [ "$open_n" -gt 0 ]; then
  echo
  echo "REFUTATION COVERAGE: ${open_n} of ${#PIN_PKG[@]} statement package(s) do not cover every requirement with a refutation.$open_block"
  echo
  echo "  None of these may be frozen. Bead tla-n8oq holds the rule and PRACTICE-PLAN.md states it."
fi

echo
echo "test-refutation-coverage.sh: ${pass_count} passed, ${fail_count} failed"
[ "$fail_count" -eq 0 ]
