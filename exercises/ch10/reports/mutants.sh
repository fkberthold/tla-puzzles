#!/usr/bin/env bash
# mutants.sh — the mutant pass for the chapter 10 exercise set.
#
# Every reference under exercises/ch10/references/ claims a pass outcome in
# EXERCISES.md. This script tries to break that claim 25 times: five
# single-edit copies per reference, each driven through harness/verdict.sh.
# A reference that survives an edit which SHOULD have broken it is a
# reference whose invariant is not pinning what the exercise says it pins.
#
# Usage:  bash exercises/ch10/reports/mutants.sh
# Output: a markdown table on stdout, one row per mutant.
# Exit:   0 always. Reading the table is the point; there is no threshold to
#         fail against, because two of these mutants are inert BY DESIGN and
#         a script that exited nonzero on them would cry wolf every run.
#
# THE NOEDIT COLUMN IS THE LOAD-BEARING ONE. A `sed` pattern that silently
# matches nothing produces a mutant identical to its reference, which then
# comes back `OK` and looks exactly like a mutant the reference failed to
# catch. Every copy is compared against its source with `cmp -s` before TLC
# is invoked, and a copy that did not change is reported as NOEDIT rather
# than being run. A NOEDIT row is a bug in this script, never a finding
# about the reference.
#
# The repo root is resolved from BASH_SOURCE rather than hardcoded, so this
# runs correctly from a dispatched worker's worktree. A literal path here
# would write and read the MAIN checkout instead — the failure that bead
# tla-1hf fixed in scripts/gen-curriculum-map.sh.

# Every mutant label below is a markdown string bound for the table on stdout,
# and the backticks in it are markdown code spans rather than substitutions.
# Single quotes are the correct quoting for that and shellcheck flags all 24 of
# them as SC2016 anyway. This file is outside scripts/lint's roots today
# (LINT_ROOTS=(scripts harness)), so the directive is here to keep it green if
# anyone ever widens them.
# shellcheck disable=SC2016

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
REF_DIR="$SCRIPT_DIR/../references"
VERDICT="$REPO_ROOT/harness/verdict.sh"

if [ ! -x "$VERDICT" ] && [ ! -f "$VERDICT" ]; then
  echo "mutants.sh: cannot find harness/verdict.sh at $VERDICT" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

COUNT=0
CAUGHT=0
INERT=0
NOEDIT=0

# mut <reference-basename> <label> <sed-expression>
#
# Copies the reference and its .cfg into a scratch directory of their own,
# keeping the original filenames so the TLA+ module header still matches the
# file name, applies one edit, and reports the verdict.
mut() {
  local base="$1" label="$2" expr="$3"
  local dir out rc

  COUNT=$((COUNT + 1))
  dir="$WORK/m$COUNT"
  mkdir -p "$dir"
  cp "$REF_DIR/$base.tla" "$dir/$base.tla"
  cp "$REF_DIR/$base.cfg" "$dir/$base.cfg"

  sed -i "$expr" "$dir/$base.tla"

  if cmp -s "$REF_DIR/$base.tla" "$dir/$base.tla"; then
    NOEDIT=$((NOEDIT + 1))
    printf '| `%s` | %s | **NOEDIT** | - |\n' "$base" "$label"
    return
  fi

  rc=0
  out=$(bash "$VERDICT" -c "$dir/$base.cfg" "$dir/$base.tla" 2>/dev/null) || rc=$?

  if [ "$out" = "OK" ]; then
    INERT=$((INERT + 1))
  else
    CAUGHT=$((CAUGHT + 1))
  fi

  printf '| `%s` | %s | `%s` | %s |\n' "$base" "$label" "$out" "$rc"
}

echo '| Reference | Mutant | Token | rc |'
echo '|---|---|---|---|'

# ---------------- Ex1TruckLoad ----------------
mut Ex1TruckLoad 'selection predicate `>=` to `<=`, lightest crate first' \
  's/c >= d/c <= d/g'
mut Ex1TruckLoad 'fit test `w > room` to `w >= room`' \
  's/IF w > room/IF w >= room/g'
mut Ex1TruckLoad 'drop the `1 +`, stop counting the loaded crate' \
  's/ELSE 1 + Loaded/ELSE Loaded/'
mut Ex1TruckLoad 'recurse on `room` instead of `room - w`' \
  's/Loaded(crates \\ {w}, room - w)/Loaded(crates \\ {w}, room)/'
mut Ex1TruckLoad '`Dockside` empty-set base `{}` to `crates`' \
  's/^    THEN {}$/    THEN crates/'

# ---------------- Ex2GaugePanel ----------------
mut Ex2GaugePanel '`Mapped` ignores its operator argument' \
  's/{ Op(x) : x \\in set }/{ x : x \\in set }/'
mut Ex2GaugePanel '`Kept` negates its test' \
  's/{ x \\in set : Test(x) }/{ x \\in set : ~Test(x) }/'
mut Ex2GaugePanel '`Chained` applies `G(F(x))` instead of `F(G(x))`' \
  's/Chained(F(_), G(_), x) == F(G(x))/Chained(F(_), G(_), x) == G(F(x))/'
mut Ex2GaugePanel '`Trimmed` LAMBDA sign flipped, `g - 12` to `g + 12`' \
  's/LAMBDA g: g - 12/LAMBDA g: g + 12/'
mut Ex2GaugePanel '`OverLine` threshold `g >= 40` to `g > 40`' \
  's/LAMBDA g: g >= 40/LAMBDA g: g > 40/'

# ---------------- Ex3SettlingTank ----------------
mut Ex3SettlingTank '`\ominus` loses its floor at zero' \
  's/^x \\ominus y == IF x < y THEN 0 ELSE x - y$/x \\ominus y == x - y/'
mut Ex3SettlingTank 'starting level 480 to 400' \
  's/THEN 480/THEN 400/'
mut Ex3SettlingTank 'settling fraction `\div 5` to `\div 4`' \
  's/\\div 5/\\div 4/'
mut Ex3SettlingTank 'fixed draw `\ominus 40` to `\ominus 30`' \
  's/\\ominus 40/\\ominus 30/'
mut Ex3SettlingTank '`Drop` subtracts the two levels the other way round' \
  's/Drop\[n \\in 1..6\] == Level\[n - 1\] \\ominus Level\[n\]/Drop[n \\in 1..6] == Level[n] \\ominus Level[n - 1]/'

# ---------------- Ex4LiftBands ----------------
mut Ex4LiftBands 'delete the `OTHER` arm' \
  '/OTHER       -> "idle"/d'
mut Ex4LiftBands 'first two arms swapped' \
  's/CASE load >= 900 -> "refuse"/CASE load >= 600 -> "warn"/; s/^      \[\] load >= 600 -> "warn"$/      [] load >= 900 -> "refuse"/'
mut Ex4LiftBands 'top band `>= 900` to `> 900`' \
  's/load >= 900/load > 900/'
mut Ex4LiftBands '`OTHER` answers "carry" instead of "idle"' \
  's/OTHER       -> "idle"/OTHER       -> "carry"/'
mut Ex4LiftBands 'bottom band `>= 250` to `>= 80`' \
  's/load >= 250/load >= 80/'

# ---------------- Ex5TapeFolds ----------------
mut Ex5TapeFolds 'delete the `RECURSIVE` declaration' \
  '/^RECURSIVE Folds(_)$/d'
mut Ex5TapeFolds 'base case `len < 3` to `len < 0`, never reached' \
  's/IF len < 3/IF len < 0/'
mut Ex5TapeFolds 'base case `len < 3` to `len < 2`' \
  's/IF len < 3/IF len < 2/'
mut Ex5TapeFolds 'count 2 per fold instead of 1' \
  's/THEN 0 ELSE 1 +/THEN 0 ELSE 2 +/'
mut Ex5TapeFolds 'fold into thirds, `\div 2` to `\div 3`' \
  's/len \\div 2/len \\div 3/'

echo
printf 'Total %s. Caught %s, inert %s, NOEDIT %s.\n' \
  "$COUNT" "$CAUGHT" "$INERT" "$NOEDIT"
