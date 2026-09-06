#!/usr/bin/env bash
# Gate for harness/spike-measure.sh.
#
# This exists because that tool's parsers produced two confident wrong numbers
# on the day it was written, and neither raised an error. This awk does not
# implement \b, so a VARIABLES scan anchored on it reported zero variables in a
# module declaring four. And a definition count that only matched a body
# starting on the next line reported zero on specs that plainly had some. A
# measurement tool that quietly reports the wrong number is worse than one that
# fails, because the number goes into a manifest and nobody rechecks it.
#
# So every column is pinned against a fixture whose text explains its own
# figures, and a control watches that the tool distinguishes its two fixtures
# rather than printing one answer regardless.
#
# Lineage: bead tla-frpu.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$REPO_ROOT/harness/spike-measure.sh"
FIX="$REPO_ROOT/harness/fixtures/spike"

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# Runs the tool and prints its data row. Captured first, then read from a
# here-string: a pipeline into a consumer that can close early returns 141
# under pipefail, and a present value then reads as absent.
row_for() {
  local module="$1" out
  out="$(bash "$TOOL" --dir "$FIX" --module "$module" --budget 30 --label "$module" 2>/dev/null || true)"
  tail -1 <<<"$out"
}

field() {
  local row="$1" name="$2"
  local hdr='label module rc verdict secs generated distinct depth vars defs fairness temporal instance modules lines'
  local idx
  idx="$(awk -v want="$name" '{for(i=1;i<=NF;i++) if($i==want) print i}' <<<"$hdr")"
  awk -F'\t' -v i="$idx" '{print $i}' <<<"$row"
}

expect() {
  local label="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    ok "$label is $want"
  else
    bad "$label is '$got', expected '$want'"
  fi
}

printf 'spike-measure gate\n'

if [ ! -x "$TOOL" ] && [ ! -f "$TOOL" ]; then
  bad "harness/spike-measure.sh exists"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

# 1. The clean fixture. Every figure below is a consequence of Tiny.tla's own
#    text: two variables climbing 0 to 2 independently is a 3 by 3 grid, and
#    the longest path through it is 4 steps.
TINY="$(row_for Tiny)"
expect "Tiny rc"        "$(field "$TINY" rc)"        "0"
expect "Tiny distinct"  "$(field "$TINY" distinct)"  "9"
expect "Tiny depth"     "$(field "$TINY" depth)"     "5"
expect "Tiny vars"      "$(field "$TINY" vars)"      "2"
expect "Tiny fairness"  "$(field "$TINY" fairness)"  "no"
expect "Tiny temporal"  "$(field "$TINY" temporal)"  "no"
expect "Tiny instance"  "$(field "$TINY" instance)"  "no"

# 2. The violating fixture, which also carries fairness and a temporal
#    property so those two columns have a case where yes is the honest answer.
BROKEN="$(row_for Broken)"
expect "Broken rc"        "$(field "$BROKEN" rc)"        "12"
expect "Broken vars"      "$(field "$BROKEN" vars)"      "2"
expect "Broken fairness"  "$(field "$BROKEN" fairness)"  "yes"
expect "Broken temporal"  "$(field "$BROKEN" temporal)"  "yes"

# 3. The multi-module fixture. Extender EXTENDS Scaffold, which declares two
#    variables, and adds a third of its own. This is the shape the isolation
#    spike used, where the scaffolding carries most of the state, and reading
#    only the named module reported one variable for a six-variable model.
EXTENDER="$(row_for Extender)"
expect "Extender rc"      "$(field "$EXTENDER" rc)"      "0"
expect "Extender vars"    "$(field "$EXTENDER" vars)"    "3"
expect "Extender modules" "$(field "$EXTENDER" modules)" "2"
expect "Tiny modules"     "$(field "$TINY" modules)"     "1"

# The control that names the defect. Extender.tla declares one VARIABLE line of
# its own, so a tool that read the file alone would report fewer than 3.
own_decl="$(grep -cE '^[[:space:]]*VARIABLES?' "$FIX/Extender.tla" || true)"
if [ "$(field "$EXTENDER" vars)" -gt "$own_decl" ]; then
  ok "control: variables are counted across EXTENDS, not from one file"
else
  bad "control: variable count did not follow EXTENDS, which is the isolation-spike defect"
fi

# 4. Controls. A tool that printed one answer regardless would satisfy several
#    assertions above by accident, so watch that the two fixtures differ where
#    they should.
if [ "$(field "$TINY" rc)" != "$(field "$BROKEN" rc)" ]; then
  ok "control: the two fixtures get different verdicts"
else
  bad "control: both fixtures report the same rc, so the verdict is not being read"
fi

if [ "$(field "$TINY" fairness)" != "$(field "$BROKEN" fairness)" ]; then
  ok "control: fairness is read from the module, not hardcoded"
else
  bad "control: fairness is the same on a module with WF_ and one without"
fi

if [ "$(field "$TINY" distinct)" != "$(field "$BROKEN" distinct)" ]; then
  ok "control: state counts differ between a full search and one cut short"
else
  bad "control: both fixtures report the same distinct count"
fi

# 5. The tool refuses what it cannot measure, rather than inventing a row.
set +e
bash "$TOOL" --dir "$FIX" --module NoSuchModule --budget 5 >/dev/null 2>&1
rc_missing_module=$?
bash "$TOOL" --dir "$FIX/no-such-dir" --module Tiny --budget 5 >/dev/null 2>&1
rc_missing_dir=$?
bash "$TOOL" --dir "$FIX" --budget 5 >/dev/null 2>&1
rc_missing_arg=$?
set -e

expect "a missing module exits 2"    "$rc_missing_module" "2"
expect "a missing directory exits 2" "$rc_missing_dir"    "2"
expect "a missing argument exits 2"  "$rc_missing_arg"    "2"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
