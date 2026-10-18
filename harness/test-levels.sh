#!/usr/bin/env bash
# test-levels.sh: every definition in every reading/ model gets a TLA+ level,
# EXTENDS-imported definitions are dropped, and 01-nim reads exactly one way.
# Bead tla-7xql.3.
#
# WHAT THE SWIPE RUNG NEEDS THIS FOR. The level decides what an item pins: a
# level 1 state predicate pins a state, a level 2 action pins a step, a level 3
# formula pins a lasso. A generator that cannot read the level has to EXCLUDE
# whatever it cannot classify, and 364 of the corpus's 424 definitions are
# level 1, 2 or 3. harness/levels/levels.sh is the instrument and its header
# carries the contract and the route decision.
#
# THE INVARIANT, from the bead's RED line:
#
#   every definition in every reading/ model gets a level in {0,1,2,3},
#   EXTENDS-imported definitions are excluded, and the levels for
#   reading/core/01-nim match the table exactly.
#
# ONE DISCREPANCY WITH THE BEAD, RECORDED RATHER THAN SMOOTHED OVER. The RED
# table names nine definitions in 01-nim. The module declares ten. The tenth
# is ZeroIsOneMoveAway, a level 1 state predicate at reading/core/01-nim/Nim.tla:38,
# and it is declared as an INVARIANT in Nim.cfg, so it is not an obscure one.
# Part 1 asserts the bead's nine verbatim AND the tenth separately, so the
# omission cannot be mistaken for agreement.
#
# A SECOND DISCREPANCY, in part 5. The bead reads 101 of the 185 level 1
# definitions as free of any declared obligation. Measured here it is 103, and
# the difference is the join: the bead's number comes from matching a
# definition's NAME against every obligation name in the corpus, which calls
# Shelves!Held and Tickets!Waiting declared because some other model declares
# Held and Waiting. Neither is declared in its own model's .cfg, so both are
# generable items the name-only join drops. The per-module join is the one
# with a control here.
#
# WHY THE TOTALS ARE PINNED. A gate that only said "every level is in 0..3"
# would stay green over a corpus that stopped being parsed at all. The five
# counts the bead names are pinned so a corpus that moves goes red and somebody
# looks, which is the same reason harness/test-toolchain-pin.sh pins a digest
# and harness/test-refutation-coverage.sh pins a verdict per package. A model
# landing in reading/ is expected to move these; re-measure with
# `harness/levels/levels.sh --corpus --tally` and say which model moved it.
#
# Usage:  harness/test-levels.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

LEVELS="harness/levels/levels.sh"
DRIVER="harness/levels/Levels.java"
NIM="reading/core/01-nim/Nim.tla"

TAB=$'\t'

# --- the pins --------------------------------------------------------------
# Measured 2026-10-18 over the 33 reading models at main 202dfb6.
PIN_MODULES=33
PIN_DEFS=424
PIN_L0=49
PIN_L1=185
PIN_L2=113
PIN_L3=77
# The level 2 arity spread, which is why the bead cares: an arity-0 action can
# be pinned directly, one taking arguments needs them supplied.
PIN_L2_ARITY0=76
PIN_L2_ARITY1=28
PIN_L2_ARITY2=7
PIN_L2_ARITY3=2
# The generable set. A declared obligation is true everywhere the model
# reaches, so an item asking whether it holds has one answer by construction.
PIN_L1_OBLIGATION=82
PIN_L1_FREE=103
PIN_L3_OBLIGATION=33
PIN_L3_FREE=44

pass_count=0
fail_count=0

ok() {
  printf "  PASS  %s\n" "$1"
  pass_count=$((pass_count + 1))
}
nope() {
  printf "  FAIL  %s\n" "$1"
  fail_count=$((fail_count + 1))
}
note() { printf "  NOTE  %s\n" "$1"; }

TMP="$(mktemp -d -t tla_test_levels.XXXXXX)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# eq <label> <actual> <expected>
eq() {
  if [ "$2" = "$3" ]; then
    ok "$1 — $2"
  else
    nope "$1 — read '$2', wanted '$3'"
  fi
}

# detail <multi-line-text> — prints the first few offending lines indented,
# then says how many were held back. Capped because the uncapped form buried
# the summary line under 600 definitions when a filter mutant was run, and a
# gate nobody can read is a gate nobody reads.
DETAIL_CAP=8
detail() {
  local text="$1" n shown
  [ -n "$text" ] || return 0
  n="$(wc -l <<<"$text")"
  shown="$(sed -n "1,${DETAIL_CAP}p" <<<"$text")"
  while IFS= read -r line; do
    printf "          %s\n" "$line"
  done <<<"$shown"
  if [ "$n" -gt "$DETAIL_CAP" ]; then
    printf "          ... and %d more\n" "$((n - DETAIL_CAP))"
  fi
}

# ---------------------------------------------------------------------------
echo "== part 0: the instrument runs over the whole corpus =="
# ---------------------------------------------------------------------------

if [ ! -x "$LEVELS" ]; then
  nope "$LEVELS is executable"
  printf "\ntest-levels.sh: %d passed, %d failed\n" "$pass_count" "$fail_count"
  exit 1
fi
ok "$LEVELS is executable"

CORPUS=""
CORPUS_RC=0
CORPUS="$("$LEVELS" --corpus 2>"$TMP/corpus.err")"
CORPUS_RC=$?

if [ "$CORPUS_RC" -eq 99 ]; then
  # The toolchain is absent, which is not a verdict about any module. Say so
  # and stop rather than reporting 40 failures that all mean the same thing.
  nope "the TLA+ toolchain is available — levels.sh returned CHECK_DID_NOT_RUN"
  cat "$TMP/corpus.err" >&2
  printf "\ntest-levels.sh: %d passed, %d failed\n" "$pass_count" "$fail_count"
  exit 1
fi

eq "a corpus run exits 0" "$CORPUS_RC" "0"

printf '%s\n' "$CORPUS" >"$TMP/corpus.tsv"
MOD_ROWS="$(grep -E "^MOD${TAB}" <<<"$CORPUS" || true)"
DEF_ROWS="$(grep -E "^DEF${TAB}" <<<"$CORPUS" || true)"
printf '%s\n' "$DEF_ROWS" >"$TMP/defs.tsv"

n_mod=0
n_def=0
[ -n "$MOD_ROWS" ] && n_mod="$(wc -l <<<"$MOD_ROWS")"
[ -n "$DEF_ROWS" ] && n_def="$(wc -l <<<"$DEF_ROWS")"

eq "one MOD row per reading model" "$n_mod" "$PIN_MODULES"
eq "the corpus carries $PIN_DEFS definitions" "$n_def" "$PIN_DEFS"

bad_rc="$(awk -F'\t' '$1 == "MOD" && $4 != 0 { print $2 }' <<<"$CORPUS" || true)"
if [ -z "$bad_rc" ]; then
  ok "every reading model parsed, SANY rc 0 throughout"
else
  nope "a reading model did not parse"
  detail "$bad_rc"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 1: reading/core/01-nim reads exactly one way =="
# ---------------------------------------------------------------------------

# The bead's RED table, verbatim, nine entries.
NIM_RED=(
  "vars 1"
  "TypeOK 1"
  "NimSum 1"
  "Init 1"
  "Take 2"
  "Next 2"
  "Spec 3"
  "NoEscape 3"
  "\\oplus 0"
)

# The name arrives through the ENVIRONMENT, not through `awk -v`. awk expands
# escape sequences in a -v assignment, so `-v N='\oplus'` becomes `oplus` with
# a warning, and the lookup silently finds nothing. That cost one RED run and
# it is the only definition name in the corpus that trips it, so a reader is
# unlikely to guess why the form matters.
nim_level() {
  LEVELS_NAME="$1" awk -F'\t' \
    '$1 == "DEF" && $2 == "Nim" && $3 == ENVIRON["LEVELS_NAME"] { print $4 }' \
    "$TMP/corpus.tsv"
}

for entry in "${NIM_RED[@]}"; do
  name="${entry%% *}"
  want="${entry##* }"
  got="$(nim_level "$name")"
  if [ -z "$got" ]; then
    nope "01-nim: $name is reported at all"
  else
    eq "01-nim: $name" "$got" "$want"
  fi
done

# The tenth, which the bead's table omits. Asserted separately so the gap
# between the table and the module stays visible in the output.
got="$(nim_level ZeroIsOneMoveAway)"
eq "01-nim: ZeroIsOneMoveAway (NOT in the bead's table)" "$got" "1"
note "the bead's RED table names 9 definitions; Nim.tla declares 10"

n_nim="$(awk -F'\t' '$1 == "DEF" && $2 == "Nim"' "$TMP/corpus.tsv" | wc -l)"
eq "01-nim reports exactly 10 definitions" "$n_nim" "10"

# ---------------------------------------------------------------------------
echo
echo "== part 2: every level is one of TLA+'s four =="
# ---------------------------------------------------------------------------

# out_of_range <file> — prints the offending rows, if any.
out_of_range() {
  awk -F'\t' '$1 == "DEF" && ($4 !~ /^[0-9]+$/ || $4 < 0 || $4 > 3) { print }' "$1"
}

offenders="$(out_of_range "$TMP/corpus.tsv" || true)"
if [ -z "$offenders" ]; then
  ok "no definition reports a level outside 0..3"
else
  nope "a definition reports a level outside 0..3"
  detail "$offenders"
fi

# THE CONTROL. "Nothing is out of range" is also what a checker that stopped
# reading reports, so plant a row that must be caught.
cp "$TMP/corpus.tsv" "$TMP/planted.tsv"
printf 'DEF\tNim\tImpossible\t4\t0\tNim\texported\tfree\n' >>"$TMP/planted.tsv"
planted="$(out_of_range "$TMP/planted.tsv" || true)"
if [ -n "$planted" ]; then
  ok "control: a planted level 4 row is caught"
else
  nope "control: a planted level 4 row was NOT caught, so the range check above is vacuous"
fi

for lvl in 0 1 2 3; do
  n="$(awk -F'\t' -v L="$lvl" '$1 == "DEF" && $4 == L' "$TMP/corpus.tsv" | wc -l)"
  case "$lvl" in
  0) eq "level 0, constant expressions" "$n" "$PIN_L0" ;;
  1) eq "level 1, state predicates" "$n" "$PIN_L1" ;;
  2) eq "level 2, actions" "$n" "$PIN_L2" ;;
  3) eq "level 3, temporal formulas" "$n" "$PIN_L3" ;;
  esac
done

for ar in 0 1 2 3; do
  n="$(awk -F'\t' -v A="$ar" '$1 == "DEF" && $4 == 2 && $5 == A' "$TMP/corpus.tsv" | wc -l)"
  case "$ar" in
  0) eq "level 2 of arity 0" "$n" "$PIN_L2_ARITY0" ;;
  1) eq "level 2 of arity 1" "$n" "$PIN_L2_ARITY1" ;;
  2) eq "level 2 of arity 2" "$n" "$PIN_L2_ARITY2" ;;
  3) eq "level 2 of arity 3" "$n" "$PIN_L2_ARITY3" ;;
  esac
done

# ---------------------------------------------------------------------------
echo
echo "== part 3: an EXTENDS brings nothing into the output =="
# ---------------------------------------------------------------------------

leaked="$(awk -F'\t' '$1 == "DEF" && $2 != $6 { print $2 "!" $3 " from " $6 }' \
  "$TMP/corpus.tsv" || true)"
if [ -z "$leaked" ]; then
  ok "no definition in the output was originally defined elsewhere"
else
  nope "an imported definition leaked through the EXTENDS filter"
  detail "$leaked"
fi

# THE CONTROL, and part 3 is vacuous without it: --all must show that there
# WAS something to drop. 01-nim EXTENDS Integers, so Naturals contributes +.
ALL_NIM="$("$LEVELS" --all --defs-only "$NIM" 2>/dev/null || true)"
DEF_NIM="$(awk -F'\t' '$1 == "DEF" && $2 == "Nim"' "$TMP/corpus.tsv" || true)"

n_all=0
n_filtered=0
[ -n "$ALL_NIM" ] && n_all="$(wc -l <<<"$ALL_NIM")"
[ -n "$DEF_NIM" ] && n_filtered="$(wc -l <<<"$DEF_NIM")"

if [ "$n_all" -gt "$n_filtered" ]; then
  ok "control: --all on 01-nim reports $n_all definitions against $n_filtered filtered"
else
  nope "control: --all reported $n_all against $n_filtered filtered, so the filter drops nothing and part 3 is vacuous"
fi

if grep -qE "^DEF${TAB}Nim${TAB}\+${TAB}0${TAB}2${TAB}Naturals${TAB}" <<<"$ALL_NIM"; then
  ok "control: --all carries Naturals' + as a level 0 operator of arity 2"
else
  nope "control: --all does not carry Naturals' +, so the EXTENDS control proves nothing"
fi

# An INSTANCE of an INNER module keeps the root's identity, so the prefixed
# name survives the filter. That is the behavior the generator wants: Below!Count
# is the name a learner reads. Without this the modules/ family would lose
# every definition the item is about.
FENCES="$(awk -F'\t' '$1 == "DEF" && $2 == "Fences" && $3 == "Below!Count" { print $4 }' \
  "$TMP/corpus.tsv" || true)"
eq "an inner module's instance survives the filter: Fences!Below!Count" "$FENCES" "1"

BITC="$(awk -F'\t' '$1 == "DEF" && $2 == "BitCounter" && $3 == "Abs!MFSpec" { print $4 }' \
  "$TMP/corpus.tsv" || true)"
eq "and carries its own level: BitCounter!Abs!MFSpec" "$BITC" "3"

# The LOCAL inside reading/modules/03-fences' inner module is hidden from the
# instance, so Below!Span must NOT appear. A generator offered a name that is
# not in scope would build an item that cannot be checked.
if awk -F'\t' '$3 == "Below!Span" { found = 1 } END { exit !found }' "$TMP/corpus.tsv"; then
  nope "Below!Span is reported, but LOCAL hides it from the instance"
else
  ok "a LOCAL definition inside an inner module is not surfaced through the instance"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 4: --tally agrees with the rows =="
# ---------------------------------------------------------------------------

TALLY="$("$LEVELS" --corpus --tally 2>/dev/null || true)"
for lvl in 0 1 2 3; do
  row="$(awk -F'\t' -v L="$lvl" '$1 == L { print $4 }' <<<"$TALLY" || true)"
  rows="$(awk -F'\t' -v L="$lvl" '$1 == "DEF" && $4 == L' "$TMP/corpus.tsv" | wc -l)"
  eq "--tally level $lvl total matches the DEF rows" "$row" "$rows"
done

# ---------------------------------------------------------------------------
echo
echo "== part 5: the obligation join is per module, not per name =="
# ---------------------------------------------------------------------------

for lvl in 1 3; do
  n_ob="$(awk -F'\t' -v L="$lvl" '$1 == "DEF" && $4 == L && $8 == "obligation"' \
    "$TMP/corpus.tsv" | wc -l)"
  n_free="$(awk -F'\t' -v L="$lvl" '$1 == "DEF" && $4 == L && $8 == "free"' \
    "$TMP/corpus.tsv" | wc -l)"
  if [ "$lvl" = "1" ]; then
    eq "level 1 declared as an obligation" "$n_ob" "$PIN_L1_OBLIGATION"
    eq "level 1 free, so generable" "$n_free" "$PIN_L1_FREE"
  else
    eq "level 3 declared as an obligation" "$n_ob" "$PIN_L3_OBLIGATION"
    eq "level 3 free, so generable" "$n_free" "$PIN_L3_FREE"
  fi
done

no_third="$(awk -F'\t' '$1 == "DEF" && $8 != "obligation" && $8 != "free" { print $8 }' \
  "$TMP/corpus.tsv" | sort -u || true)"
if [ -z "$no_third" ]; then
  ok "every reading model has a .cfg, so no definition reads no-cfg"
else
  nope "a definition reads '$(tr '\n' ' ' <<<"$no_third")', so a model is missing its .cfg"
fi

# THE CONTROL on the join. Held is declared as an INVARIANT in Contend.cfg and
# NOT in Shelves.cfg. A name-only join calls Shelves!Held declared; a
# per-module join calls it free, and free is the truth.
held="$(awk -F'\t' '$1 == "DEF" && $2 == "Shelves" && $3 == "Held" { print $8 }' \
  "$TMP/corpus.tsv" || true)"
eq "control: Shelves!Held is free although Contend declares Held" "$held" "free"

contend_held="$(awk -F'\t' '$1 == "DEF" && $2 == "Contend" && $3 == "Held" { print $8 }' \
  "$TMP/corpus.tsv" || true)"
eq "control: Contend!Held, the same name in its own model, is an obligation" \
  "$contend_held" "obligation"

waiting="$(awk -F'\t' '$1 == "DEF" && $2 == "Tickets" && $3 == "Waiting" { print $8 }' \
  "$TMP/corpus.tsv" || true)"
eq "control: Tickets!Waiting is free although Peterson declares Waiting" "$waiting" "free"

# EVERY declared obligation resolves to a definition in its own model. This is
# the assertion that catches a join missing definitions rather than borrowing
# them: a .cfg naming something the driver never reported means the driver is
# not seeing the whole module.
unresolved=""
for cfg in reading/*/*/*.cfg; do
  tla="${cfg%.cfg}.tla"
  [ -f "$tla" ] || continue
  modname="$(basename "$tla" .tla)"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if ! awk -F'\t' -v M="$modname" -v N="$name" \
      '$1 == "DEF" && $2 == M && $3 == N { found = 1 } END { exit !found }' \
      "$TMP/corpus.tsv"; then
      unresolved="${unresolved} ${modname}!${name}"
    fi
  done < <(sed 's/\\\*.*$//' "$cfg" |
    awk '/^[[:space:]]*(INVARIANTS?|PROPERTIES|PROPERTY)[[:space:]]+[A-Za-z_]/ {
           for (i = 2; i <= NF; i++) { print $i }
         }')
done
if [ -z "$unresolved" ]; then
  ok "every obligation a reading .cfg declares resolves to a reported definition"
else
  nope "a declared obligation resolves to nothing reported:${unresolved}"
fi

# ---------------------------------------------------------------------------
echo
echo "== part 6: one JVM for the whole run =="
# ---------------------------------------------------------------------------

# STRUCTURAL, because the timing proxy is worthless on a contended box. A JVM
# per module costs 17.8 s against 1.0 s for one JVM, measured 2026-10-18, and
# a per-definition loop would be far worse. A fork inside a per-item loop is
# this project's recurring performance defect, so the shape is gated rather
# than the clock.
java_lines="$(grep -cE '^[^#]*java -cp' "$LEVELS" || true)"
eq "levels.sh starts java in exactly one place" "$java_lines" "1"

if grep -qE 'java -cp .*"\$\{MODULES\[@\]\}"' "$LEVELS"; then
  ok "that one invocation is handed every module at once"
else
  nope "the java invocation does not pass \${MODULES[@]}, so it may be inside a loop"
fi

# SOUNDNESS of the one-JVM design. SANY carries static state, so a level that
# depended on what was parsed before it would be a silent wrong answer. Three
# models in one process must read the same as three processes. The full
# 33-module version of this check was run by hand and was identical; three is
# what the suite can afford.
TRIO=(
  "reading/core/01-nim/Nim.tla"
  "reading/modules/03-fences/Fences.tla"
  "reading/temporal/01-handover/Handover.tla"
)
trio_ok=1
for m in "${TRIO[@]}"; do
  if [ ! -f "$m" ]; then
    nope "the soundness trio names a module that exists: $m"
    trio_ok=0
  fi
done

if [ "$trio_ok" -eq 1 ]; then
  "$LEVELS" --defs-only "${TRIO[@]}" >"$TMP/trio-one.tsv" 2>/dev/null
  : >"$TMP/trio-many.tsv"
  for m in "${TRIO[@]}"; do
    "$LEVELS" --defs-only "$m" >>"$TMP/trio-many.tsv" 2>/dev/null
  done
  if diff -q "$TMP/trio-one.tsv" "$TMP/trio-many.tsv" >/dev/null 2>&1; then
    ok "three models in one JVM read the same as three separate JVMs"
  else
    nope "one JVM and three disagree, so a level depends on what was parsed before it"
    diff -u "$TMP/trio-one.tsv" "$TMP/trio-many.tsv" >&2 || true
  fi
fi

# ---------------------------------------------------------------------------
echo
echo "== part 7: the refusals =="
# ---------------------------------------------------------------------------

# 99 is CHECK_DID_NOT_RUN, the project-wide reserved code for "the check could
# not be performed". A missing jar is not a verdict about any module.
out=""
rc=0
out="$(TLA_JAR="$TMP/there-is-no-jar-here.jar" "$LEVELS" "$NIM" 2>&1)"
rc=$?
eq "a missing tla2tools.jar exits 99" "$rc" "99"
if grep -qF "CHECK_DID_NOT_RUN" <<<"$out"; then
  ok "and names the CHECK_DID_NOT_RUN token"
else
  nope "a missing jar does not name CHECK_DID_NOT_RUN: $out"
fi

out="$("$LEVELS" 2>&1)"
rc=$?
eq "no module given exits 2" "$rc" "2"

out="$("$LEVELS" --no-such-flag "$NIM" 2>&1)"
rc=$?
eq "an unknown option exits 2" "$rc" "2"

# A module that does not parse is a verdict about that module, so rc 1 and a
# MOD row carrying a nonzero SANY code. The fixture lives in the temp tree, so
# nothing untracked is left behind and no other suite's tree walk sees it.
mkdir -p "$TMP/broken"
{
  printf -- '---- MODULE Broken ----\n'
  printf 'EXTENDS Naturals\n'
  printf 'VARIABLE x\n'
  printf 'Oops == x + NoSuchOperatorAnywhere\n'
  printf '====\n'
} >"$TMP/broken/Broken.tla"

out="$("$LEVELS" "$TMP/broken/Broken.tla" 2>/dev/null)"
rc=$?
eq "a module that does not parse exits 1" "$rc" "1"

broken_rc="$(awk -F'\t' '$1 == "MOD" { print $4 }' <<<"$out" || true)"
if [ -n "$broken_rc" ] && [ "$broken_rc" != "0" ]; then
  ok "and its MOD row carries a nonzero SANY code ($broken_rc)"
else
  nope "a broken module's MOD row reports SANY rc '$broken_rc', wanted nonzero"
fi

# A BROKEN MODULE MUST NOT TAKE THE RUN DOWN. getLevel() throws
# `WrongInvocationException: getLevel called before levelCheck` when semantic
# analysis failed, and that throw used to escape per-module handling: the first
# unparseable module ended the process and every module after it went
# unreported, with rc 1 and a plausible-looking partial output. Watched on
# 2026-10-18 before the guard in Levels.java went in.
out="$("$LEVELS" "$TMP/broken/Broken.tla" "$NIM" 2>/dev/null)"
after="$(awk -F'\t' '$1 == "DEF" && $2 == "Nim"' <<<"$out" | wc -l)"
eq "a module after a broken one is still reported in full" "$after" "10"

# The control: the same shape, repaired, must pass. Without it the assertion
# above is satisfied by an instrument that calls everything broken.
mkdir -p "$TMP/fixed"
{
  printf -- '---- MODULE Fixed ----\n'
  printf 'EXTENDS Naturals\n'
  printf 'VARIABLE x\n'
  printf 'Oops == x + 1\n'
  printf '====\n'
} >"$TMP/fixed/Fixed.tla"

out="$("$LEVELS" "$TMP/fixed/Fixed.tla" 2>/dev/null)"
rc=$?
eq "control: the same module, repaired, exits 0" "$rc" "0"
fixed_level="$(awk -F'\t' '$1 == "DEF" && $3 == "Oops" { print $4 }' <<<"$out" || true)"
eq "control: and reports Oops as a level 1 state predicate" "$fixed_level" "1"
fixed_cfg="$(awk -F'\t' '$1 == "DEF" && $3 == "Oops" { print $8 }' <<<"$out" || true)"
eq "control: a module with no .cfg beside it reads no-cfg" "$fixed_cfg" "no-cfg"

# ---------------------------------------------------------------------------
echo
echo "== part 8: the driver is reachable without a build step =="
# ---------------------------------------------------------------------------

if [ -f "$DRIVER" ]; then
  ok "$DRIVER is present"
else
  nope "$DRIVER is missing"
fi

# No compiled artifact may be committed or left behind. There is no javac call
# anywhere, on purpose: the JVM compiles the driver in memory, so there is no
# .class to gitignore and nothing for scripts/setup or CI to install.
stray="$(find harness/levels -type f \( -name '*.class' -o -name '*.jar' \) || true)"
if [ -z "$stray" ]; then
  ok "no compiled artifact under harness/levels"
else
  nope "a compiled artifact sits under harness/levels: $(tr '\n' ' ' <<<"$stray")"
fi

if grep -qE '^[^#]*javac' "$LEVELS"; then
  nope "levels.sh calls javac, so it has a build step after all"
else
  ok "levels.sh calls no javac, so there is no build step to wire into CI"
fi

# ---------------------------------------------------------------------------
echo
printf "test-levels.sh: %d passed, %d failed\n" "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
