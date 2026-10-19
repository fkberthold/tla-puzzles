#!/usr/bin/env bash
# render.sh -- the model screen a level 2 swipe item shows (bead tla-7xql.5,
# epic tla-7xql).
#
# A level 2 item pins a STEP, so the screen carries two states where level 1
# carried one. Everything above that is level 1's and this file does not
# re-implement it: the model screen, the transitive strip and the shown-roots
# rule all come from swipe/level1/render.sh, which is driven here with
# --screen and --list-shown.
#
# TWO THINGS THIS RUNG ADDS, AND THE FIRST ONE IS A REAL GAP IN THE LEVEL 1
# RULE RATHER THAN A PREFERENCE.
#
# ONE. vars HAS TO BE ON THE SCREEN AND THE LEVEL 1 STRIP REMOVES IT.
# The level 1 kept set is every level 2 definition except Next and the
# SPECIFICATION formula, plus their transitive closure. `vars` is a state
# function, so it is level 1 and never a root, and an action reaches it only
# when the action happens to mention it. Measured over this rung's seven
# models: not one of them puts `vars` in the kept set, because every action
# writes `UNCHANGED <x>` rather than naming the tuple.
#
# That is correct at level 1, where no claim can name `vars`. At level 2 the
# subscript is the subject matter and `vars` is the subscript that 906 of
# 1,182 published sites write, which is 77 percent and is measured in
# .claude/rules/tla-practice.md section 2. A claim may only name a definition
# the screen shows, so either the screen shows `vars` or the corpus cannot
# drill the one habit it exists to drill.
#
# So the kept set here is level 1's plus `vars` when the module declares it,
# and that is the whole difference. It breaks neither decision: D2 strips the
# obligations and `vars` is not one, and D7 withholds Init, Next and Spec and
# `vars` is not one of those either. Level 1 strips it for a reason that stops
# being true one rung up.
#
# TWO. THE PIN IS A STEP, SO IT IS TWO BLOCKS. The pre-state is a state
# predicate and the post is a formula over primed variables, which is what a
# step IS in TLA+ and is what the generated module's Post operator holds byte
# for byte. Writing the post as concrete values of the primed variables was
# the alternative and it was rejected: `UNCHANGED serving` says the thing the
# subscript items turn on, and `serving' = 0` makes the reader derive it.
#
# The pin's own constants are shown too. A model value cannot be named by the
# pin module, so a pin that touches one declares a constant and binds it, and
# a reader who is shown `holder' = H2` without being shown `H2 = s2` has been
# handed a name they cannot evaluate.
#
# USAGE
#   swipe/level2/render.sh --model PATH [OPTIONS]
#   swipe/level2/render.sh --item ID [OPTIONS]
#
#   --model PATH      a reading/ module. Its .cfg is read from beside it
#   --item ID         render a whole item from swipe/level2/ITEMS.tsv
#   --items FILE      read a different item table
#   --list-shown      print the kept definition names, one per line
#   --screen          the model screen only, with no pin and no question
#   -h, --help        this text
#
# EXIT
#   0  rendered
#   1  the module declares no action, or the item id is not in the table
#   2  usage error

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
L1="$ROOT/swipe/level1/render.sh"
ITEMS="$ROOT/swipe/level2/ITEMS.tsv"

MODEL=""
ITEM=""
MODE="full"

usage() {
  awk 'NR == 1 { next } /^[^#]/ { exit } { print }' "${BASH_SOURCE[0]}"
}

die() { printf 'render.sh: %s\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --model)       MODEL="${2:-}"; shift 2 ;;
    --item)        ITEM="${2:-}"; shift 2 ;;
    --items)       ITEMS="${2:-}"; shift 2 ;;
    --list-shown)  MODE="shown"; shift ;;
    --screen)      MODE="screen"; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

ASK="" CLAIM="" PRE="" POST="" BINDS="" MODELNAME=""
if [ -n "$ITEM" ]; then
  row="$(awk -F'\t' -v id="$ITEM" '$1 == "ITEM" && $2 == id' "$ITEMS")"
  [ -n "$row" ] || { printf 'render.sh: no item %s in %s\n' "$ITEM" "$ITEMS" >&2; exit 1; }
  mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$row")
  ASK="${F[3]}"
  CLAIM="${F[8]}"
  MODELNAME="${F[11]}"
  PRE="${F[12]}"
  POST="${F[13]}"
  BINDS="${F[14]}"
  MODEL="$("$L1" --model-path "$MODELNAME")"
fi

[ -n "$MODEL" ] || die "need --model PATH or --item ID"
[ -f "$MODEL" ] || die "no such module: $MODEL"

# The state-tuple definition, if the module declares one. A top-level
# construct starts at a line whose first character is neither a space nor a
# tab, and it runs to the line before the next one, so the span is taken the
# same way swipe/level1/render.sh takes its spans.
vars_def() {
  awk '
    /^vars[ \t]*==/ { inb = 1; print; next }
    inb && /^[ \t]/  { print; next }
    inb             { exit }
  ' "$MODEL"
}

VARSDEF="$(vars_def)"

if [ "$MODE" = "shown" ]; then
  {
    "$L1" --model "$MODEL" --list-shown
    [ -n "$VARSDEF" ] && printf 'vars\n'
  } | LC_ALL=C sort -u
  exit 0
fi

# The model screen, from level 1, with the state tuple spliced in under the
# VARIABLES declaration it is built from. Splicing rather than appending puts
# it where a reader of the module itself would find it.
screen() {
  local text
  text="$("$L1" --model "$MODEL" --screen)"
  if [ -z "$VARSDEF" ]; then
    printf '%s\n' "$text"
    return 0
  fi
  awk -v def="$VARSDEF" '
    { print }
    !done && /^[ \t]*VARIABLES?[ \t]/ {
      n = split(def, L, "\n")
      for (i = 1; i <= n; i++) print "   " L[i]
      done = 1
    }
  ' <<<"$text"
}

screen

[ "$MODE" = "screen" ] && exit 0
[ -n "$ITEM" ] || exit 0

RULE='   ------------------------------'
indent() { sed 's/^/   /'; }
# A conjunction list, one conjunct per line. The separator is written as a
# character class so this sed never has to carry a TLA+ conjunction through a
# shell quoting layer.
split_conj() { sed 's/ *\/\\ */\n/g' | sed '/^$/d' | indent; }

printf '\n%s from\n' "$RULE"
printf '%s\n' "$PRE" | split_conj
printf '   ---------- steps to\n'
printf '%s\n' "$POST" | split_conj
if [ "$BINDS" != "-" ] && [ -n "$BINDS" ]; then
  printf '   ---------- where\n'
  printf '%s\n' "$BINDS" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed '/^$/d' | indent
fi
printf '%s\n' "$RULE"

case "$ASK" in
  step)   prompt="does this hold across the step" ;;
  always) prompt="does this hold all the way" ;;
  *)      prompt="$ASK" ;;
esac
printf '\n   %s\n\n' "$prompt"
printf '      %s\n' "$CLAIM"
