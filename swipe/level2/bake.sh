#!/usr/bin/env bash
# bake.sh -- the level 2 verdict channel (bead tla-7xql.5, epic tla-7xql).
#
# Every verdict in swipe/level2/ITEMS.tsv comes from a TLC exit code through
# harness/verdict.sh. Nothing here reads TLC's stdout, which is the rule
# V2-PLAN.md section 5.1 sets for the rest of the harness.
#
# ===========================================================================
# THE CHANNEL, AND WHY IT IS A PROPERTY RATHER THAN AN INVARIANT
# ===========================================================================
#
# Level 1 pins a STATE and asks a state predicate, so it declares INVARIANT.
# Level 2 pins a STEP and asks a step formula, which is not a state predicate
# at all, so it declares PROPERTY. The generated module EXTENDS the real model
# and the model stays the single source of truth:
#
#   ---- MODULE Pin_L2_S1_01 ----
#   EXTENDS Tickets
#
#   CONSTANT P1
#
#   Pre  == ticket = [q \in Player |-> Nil] /\ next = 0 /\ serving = 0
#   Post == ticket' = [ticket EXCEPT ![P1] = 0] /\ next' = 1 /\ UNCHANGED serving
#
#   Ini == Pre
#   Nxt == IF Pre THEN Post ELSE UNCHANGED vars
#
#   Claim == [][Take(P1)]_vars
#   ====
#
# with a .cfg of INIT Ini, NEXT Nxt, the model's own CONSTANT block plus the
# pin's own binds, and PROPERTY Claim. The .cfg names Claim and nothing else,
# which is decision D2 satisfied mechanically rather than visually: the model's
# own obligations are not declared, so they do not run, and neither does its
# CONSTRAINT or its CHECK_DEADLOCK line.
#
# `IF Pre THEN Post ELSE UNCHANGED vars` gives one real step and then a
# stuttering tail. The tail is harmless for a safety property, because every
# subscript is unchanged across a stuttering step, so [A]_v holds there by
# construction whatever A says. Measured: [][Take(P1)]_<<serving>> reads 0 on
# a step where serving never moves, and the tail contributes nothing either
# way.
#
# A PIN CONSTANT IS HOW A MODEL VALUE GETS NAMED. `Ini == holder = s1` fails
# at rc 150 with a semantic error, because s1 is a .cfg model value and not an
# identifier the module can name. Field 15 carries the binds, the module
# declares them as CONSTANT and the .cfg assigns them. Central measured this
# on 2026-10-18 and corrected the level 1 write-up at commit 8148330.
#
# ===========================================================================
# THE FIVE ROWS, every one measured on TLC 2026.07.31.184830 on 2026-10-18
# ===========================================================================
#
#   rc        kind        swipe  what happened
#   --------  ----------  -----  -------------------------------------------
#          0  true        right  the claim holds across the step
#   12 or 13  false       left   the claim is refuted
#         75  illformed   down   the claim does not evaluate
#        150  unparsed    down   SANY refuses the module
#        151  wronglevel  down   the claim is not a temporal formula at all
#
# A vacuous item also reads 0, so rc alone cannot tell it from a plainly true
# one. Field 10 carries a witness, exactly as level 0 and level 1 do.
#
# ROW false IS A PAIR OF CODES AND THAT IS HAZARD H1 ON THE EPIC, which says
# to read {12, 13} as ONE answer and never to predict which. Every refutation
# measured at this rung came back 13, because a step formula is checked in the
# temporal pass rather than lifted to an invariant. The channel still accepts
# both, because H1 is about what a generator may ASSUME rather than about what
# one build happened to print. rc_set_for() is where that lives, and it is the
# only kind in this channel that maps to more than one code.
#
# ROW 151 IS THIS RUNG'S OWN LESSON and it is the row level 1 does not have.
# swipe/README.md's level 1 section says "Row 151 does not appear here", and
# it comes back at level 2 for a completely different reason. TLC says:
#
#   The formula Claim ... is an action-level formula (i.e., it contains no
#   temporal operators). Only temporal-level (or state-level) formulas are
#   allowed under PROPERTY or PROPERTIES. To check that action Claim holds in
#   *every* step of the behavior, define a temporal property: ... rewrite A as
#   [][A]_v, where v is a state function (typically the tuple of variables)
#   (compare page 90 of Specifying Systems ...)
#
# `[Take(P1)]_vars` reads 151 and `[][Take(P1)]_vars` reads 0. The whole
# difference is the dropped box, and TLC names the fix and cites the page.
#
# ROW 150 IS THE SUBSCRIPT'S OWN PARSE TRAP. SANY says "[] followed by action
# not of form [A]_v", and it says it for `[]Take(P1)` and for
# `[][Take(P1)]_ticket[P1]` alike. The second one is the measured half of a
# claim .claude/rules/tla-practice.md section 2 makes from the corpus: an
# indexed element as a subscript "matches zero times" across 666 published
# modules. It is not merely unattested. It does not parse.
#
# ===========================================================================
# THE AUXILIARY RUN: ONE JVM PER PINNED STEP, NOT PER ITEM
# ===========================================================================
#
# A pinned step has to be exactly one step. Hazard H3 on the epic: a real
# branch means a SET of behaviors was pinned and TLC finds the member that
# refutes you. The module EXTENDS the model and TLC, defines
# PinStep == TLCGet("distinct") = 2, and the .cfg declares the model's own
# type invariant plus POSTCONDITION PinStep. Measured:
#
#   rc 0   the pin is type-correct at both states and is exactly one step
#   rc 12  a state breaks the model's own type invariant
#   rc 10  the pin is not one step: two initial states, or a branch
#   rc 75  the type invariant cannot be EVALUATED at the initial state
#   rc 76  the type invariant cannot be evaluated at the successor
#
# TWO IS THE WHOLE CONTRACT AND IT IS WHY FIELD 8 IS NOT AN AUTHORED NUMBER
# HERE. TLCGet("distinct") counts distinct states, and Nxt makes every state
# past the post state its own only successor, so 2 means one initial state and
# one successor and nothing else does. Measured: a Pre of `next \in {0, 1}`
# reads 10, and a Post of `next' \in {1, 2}` reads 10 against 2 and 0 against
# 3. One number catches both halves of H3, where level 1 needed the count to
# be an authored per-item field.
#
# THE TYPE CHECK IS FREE AT THIS RUNG, which it was not at level 1. TLC checks
# an invariant at every reachable state, and both pinned states are reachable
# here, so one INVARIANT line covers the before and the after. Level 1 had one
# state to check and this has two for the same run.
#
# AND THE AUXILIARY RUN IS DEDUPLICATED. Items are authored in groups that
# share one pinned step and vary only the claim, so the pin check is keyed on
# (model, pre, post, binds) and runs once per distinct step rather than once
# per item. Level 1 ran it per item and its corpus has repeated pins too, so
# the saving was available there and nobody took it.
#
# ===========================================================================
# THE VACUITY WITNESS IS THE SUBSCRIPT TEST
# ===========================================================================
#
# A claim [][A]_v is vacuous when v does not move across the step, because
# then [A]_v holds by its own second disjunct and the claim says nothing about
# A. The witness is [][FALSE]_v: replace the action with FALSE and see whether
# the truth value survives, which is the textbook vacuity test. Measured on a
# Tickets Take step: [][FALSE]_<<serving>> reads 0 and [][FALSE]_<<next>>
# reads 13.
#
# So the witness is not free-form here. harness/test-swipe-subscript.sh
# asserts that a vacuous item's field 10 is exactly [][FALSE]_ followed by the
# claim's own subscript, which makes the label mechanical rather than an
# author's word. A later template that needs another vacuity shape has to
# relax that assertion on purpose rather than by accident.
#
# ===========================================================================
# WHAT A CLAIM MAY NOT BE, AND IT IS NOT A STYLE RULE
# ===========================================================================
#
# A pinned behavior with no fairness admits the behavior that stutters at the
# initial state forever, so EVERY liveness claim is refuted whatever it says.
# Measured: []<>(next = 1) reads 13 on a step that does set next to 1, and
# WF_vars(Take(P1)) reads 13 on a step that takes it. An author who writes one
# of those gets a 13, writes `false` down, and ships an item that is false for
# a reason the pin never had an opinion about. The gate bans <>, WF_ and SF_
# in a claim for that reason, and the ban is a correctness gate rather than a
# taste one.
#
# USAGE
#   swipe/level2/bake.sh [--check | --write | --stats] [OPTIONS]
#
#   --check            confirm every stored verdict. The default
#   --write            measure every item from scratch and write fields 6-8
#   --stats            per-template counts, swipe mix and base rates
#   --template ID      scope --check and --stats to one template
#   --item ID          scope --check to one item
#   --emit DIR         keep the generated modules in DIR
#   --items FILE       read a different item table
#   -h, --help         this text
#
# EXIT
#   0  every stored verdict confirmed, or the table written
#   1  a stored verdict disagrees with TLC, or an authored kind does
#   2  usage error

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERDICT="$ROOT/harness/verdict.sh"
ITEMS="$ROOT/swipe/level2/ITEMS.tsv"

# Hazard H3 on the epic, as one number. See the auxiliary-run block above.
PIN_STATES=2

MODE="check"
TEMPLATE=""
ONEITEM=""
EMIT=""

usage() {
  awk 'NR == 1 { next } /^[^#]/ { exit } { print }' "${BASH_SOURCE[0]}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check)    MODE="check"; shift ;;
    --write)    MODE="write"; shift ;;
    --stats)    MODE="stats"; shift ;;
    --template) TEMPLATE="${2:-}"; shift 2 ;;
    --item)     ONEITEM="${2:-}"; shift 2 ;;
    --emit)     EMIT="${2:-}"; shift 2 ;;
    --items)    ITEMS="${2:-}"; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    *) printf 'bake.sh: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -f "$ITEMS" ]; then
  printf 'bake.sh: no item table at %s\n' "$ITEMS" >&2
  exit 2
fi

SCRATCH=""
# Reached only through the EXIT trap. shellcheck does not follow traps, so it
# reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() {
  if [ -n "$SCRATCH" ] && [ -z "$EMIT" ]; then
    rm -rf "$SCRATCH"
  fi
}
trap cleanup EXIT

if [ -n "$EMIT" ]; then
  mkdir -p "$EMIT"
  SCRATCH="$EMIT"
else
  SCRATCH="$(mktemp -d -t swipe_level2.XXXXXX)"
fi

DEFECTS=0
declare -A AUX_RC=()
AUX_N=0

# ---------------------------------------------------------------------------
# Reading the table. One awk call per row, emitting one field per line into an
# array: `IFS=$'\t' read` is wrong here, because tab is IFS whitespace, so a
# run of tabs collapses into one delimiter and an empty field disappears.
# ---------------------------------------------------------------------------
rows() {
  awk -F'\t' -v t="$TEMPLATE" -v one="$ONEITEM" '
    $1 == "ITEM" {
      if (t != "" && $3 != t) next
      if (one != "" && $2 != one) next
      print
    }' "$ITEMS"
}

# The swipe a kind earns. Four kinds land on down. Vacuous is decision D3 on
# the epic and is forced rather than chosen, unparsed is Frank's ruling of
# 2026-10-18 on bead tla-7xql.10, and wronglevel arrived at level 1 on the
# same reading. Each is a third thing a reader cannot call true or false, so
# none of them has another gesture available.
swipe_for() {
  case "$1" in
    true)       printf 'right\n' ;;
    false)      printf 'left\n' ;;
    vacuous)    printf 'down\n' ;;
    illformed)  printf 'down\n' ;;
    wronglevel) printf 'down\n' ;;
    unparsed)   printf 'down\n' ;;
    *)          printf 'UNKNOWN\n' ;;
  esac
}

# The exit codes a kind allows. A SET rather than a number, which is hazard H1
# on the epic made mechanical: {12, 13} is one answer and a generator may
# never predict which. A vacuous item is true, so it shares rc 0 with a
# plainly true one and field 10 is what separates them.
rc_set_for() {
  case "$1" in
    true|vacuous) printf '0\n' ;;
    false)        printf '12 13\n' ;;
    illformed)    printf '75\n' ;;
    unparsed)     printf '150\n' ;;
    wronglevel)   printf '151\n' ;;
    *)            printf '\n' ;;
  esac
}

rc_allowed() {
  local rc="$1" set="$2" c
  for c in $set; do
    [ "$rc" = "$c" ] && return 0
  done
  return 1
}

# The kind an exit code names, used by --write to contradict the author. The
# refuted pair collapses to one kind here, which is the same H1 reading from
# the other direction.
kind_for_rc() {
  case "$1" in
    0)      printf 'true\n' ;;
    12|13)  printf 'false\n' ;;
    75)     printf 'illformed\n' ;;
    150)    printf 'unparsed\n' ;;
    151)    printf 'wronglevel\n' ;;
    *)      printf 'UNKNOWN_%s\n' "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
# The model beside the item. The .tla is copied into the scratch directory so
# EXTENDS resolves without a library path, and the CONSTANT block is lifted
# from the model's own .cfg so an item can never disagree with the model about
# what its constants are. D1 says the CONSTANTS stay visible, and this is the
# half that makes them the same ones the reader sees.
# ---------------------------------------------------------------------------
# The first line comes out by parameter expansion rather than by a pipe into
# head. A producer piped into an early-exiting consumer returns 141 under
# pipefail, which inside an `if` reads as a clean false rather than an error.
model_tla() {
  local name="$1" hits
  hits="$(find "$ROOT/reading" -name "$name.tla" -type f | LC_ALL=C sort)"
  printf '%s\n' "${hits%%$'\n'*}"
}

prepare_model() {
  local name="$1" src
  [ -f "$SCRATCH/$name.tla" ] && return 0
  src="$(model_tla "$name")"
  if [ -z "$src" ]; then
    printf '  no reading/ module called %s\n' "$name" >&2
    return 1
  fi
  cp "$src" "$SCRATCH/$name.tla"
}

# The model's constant assignments, one per line and without the keyword, so
# the pin's own binds can join them under a single CONSTANTS header. A model
# writes the block either as `CONSTANT Proc = {p1, p2}` on one line or as a
# CONSTANTS header with indented assignments under it, and both shapes are in
# reading/.
model_const_lines() {
  local name="$1" src
  src="$(model_tla "$name")"
  [ -n "$src" ] || return 0
  awk '
    /^[[:space:]]*CONSTANTS?([[:space:]]|$)/ {
      inb = 1
      rest = $0
      sub(/^[[:space:]]*CONSTANTS?[[:space:]]*/, "", rest)
      if (rest != "") print "  " rest
      next
    }
    inb && /^[[:space:]]+[^[:space:]]/ { sub(/^[[:space:]]+/, "  "); print; next }
    inb { inb = 0 }
  ' "${src%.tla}.cfg"
}

# Field 15, split on commas into one assignment per line. A dash means none.
bind_lines() {
  local binds="$1"
  [ "$binds" = "-" ] && return 0
  [ -n "$binds" ] || return 0
  printf '%s\n' "$binds" | tr ',' '\n' | sed 's/^[[:space:]]*/  /; s/[[:space:]]*$//' | grep -v '^[[:space:]]*$' || true
}

# The names on the left of each bind, which the pin module has to DECLARE
# before the .cfg can assign them.
bind_names() {
  bind_lines "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*=.*$//' | grep -v '^$' || true
}

cfg_constants() {
  local model="$1" binds="$2" all
  all="$(printf '%s\n%s\n' "$(model_const_lines "$model")" "$(bind_lines "$binds")" | grep -v '^[[:space:]]*$' || true)"
  [ -n "$all" ] || return 0
  printf 'CONSTANTS\n'
  printf '%s\n' "$all"
}

# The model's own type invariant, read off its .cfg rather than assumed to be
# called TypeOK. 31 of the 33 reading/ models name one and both exceptions are
# PlusCal, so this returns empty only for a model this corpus does not use.
type_invariant() {
  local name="$1" src names
  src="$(model_tla "$name")"
  [ -n "$src" ] || return 0
  names="$(awk '
    /^[[:space:]]*INVARIANTS?([[:space:]]|$)/ { inb = 1; for (i = 2; i <= NF; i++) print $i; next }
    inb && /^[[:space:]]+[^[:space:]]/ { print $1; next }
    inb { inb = 0 }
  ' "${src%.tla}.cfg" | grep -E '^Type' || true)"
  printf '%s\n' "${names%%$'\n'*}"
}

# ---------------------------------------------------------------------------
# Running TLC. The verdict is the raw exit status and nothing else.
# ---------------------------------------------------------------------------
tlc_rc() {
  local module="$1" cfg="$2" rc=0
  "$VERDICT" -q -c "$cfg" "$module" >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}

# The shared body of both generated modules: the pin constants, the two halves
# of the step, and the machine that turns them into one step plus a stuttering
# tail. The pin text goes in as a printf ARGUMENT and never into the format
# string, because bash printf reads a backslash in a format and a TLA+
# conjunction would arrive as something else.
pin_body() {
  local pre="$1" post="$2" binds="$3" names
  names="$(bind_names "$binds" | tr '\n' ' ')"
  names="${names%% }"
  if [ -n "$names" ]; then
    printf 'CONSTANT %s\n\n' "$(printf '%s' "$names" | tr ' ' ',' | sed 's/,/, /g')"
  fi
  printf 'Pre  == %s\n\n' "$pre"
  printf 'Post == %s\n\n' "$post"
  printf 'Ini == Pre\n'
  printf 'Nxt == IF Pre THEN Post ELSE UNCHANGED vars\n\n'
}

# Writes the claim module and its .cfg, and prints the module path.
write_claim() {
  local safe="$1" model="$2" pre="$3" post="$4" binds="$5" claim="$6"
  local mod="Pin_$safe"
  {
    printf -- '---- MODULE %s ----\n' "$mod"
    printf 'EXTENDS %s\n\n' "$model"
    pin_body "$pre" "$post" "$binds"
    printf 'Claim == %s\n' "$claim"
    printf -- '====\n'
  } > "$SCRATCH/$mod.tla"
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    cfg_constants "$model" "$binds"
    printf 'PROPERTY Claim\n'
  } > "$SCRATCH/$mod.cfg"
  printf '%s\n' "$SCRATCH/$mod.tla"
}

# The auxiliary module. The model's own type invariant over both pinned states
# and the step count as a postcondition, so one JVM answers both.
write_aux() {
  local n="$1" model="$2" pre="$3" post="$4" binds="$5" tok="$6"
  local mod="Aux_$n"
  {
    printf -- '---- MODULE %s ----\n' "$mod"
    printf 'EXTENDS %s, TLC\n\n' "$model"
    pin_body "$pre" "$post" "$binds"
    printf 'PinStep == TLCGet("distinct") = %s\n' "$PIN_STATES"
    printf -- '====\n'
  } > "$SCRATCH/$mod.tla"
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    cfg_constants "$model" "$binds"
    if [ -n "$tok" ]; then printf 'INVARIANT %s\n' "$tok"; fi
    printf 'POSTCONDITION PinStep\n'
  } > "$SCRATCH/$mod.cfg"
  printf '%s\n' "$SCRATCH/$mod.tla"
}

# ---------------------------------------------------------------------------
# The pin pass. Every selected row names a pinned step, several rows name the
# SAME one, and the step check does not depend on the claim. So it runs here,
# once per distinct step, before any item is measured.
#
# IT HAS TO BE A SEPARATE PASS RATHER THAN A CACHE INSIDE measure(). measure()
# is called as `got="$(measure ...)"`, which is a subshell, so an associative
# array filled in there dies with it: the first version of this file cached
# nothing, ran the pin check 48 times, and reported "0 pinned steps checked"
# while every run was happening. The counter being visibly wrong is the only
# reason the lost cache was noticed at all.
# ---------------------------------------------------------------------------
step_key() {
  printf '%s|%s|%s|%s' "$1" "$2" "$3" "$4"
}

pin_pass() {
  local row key model pre post binds tok mod rc
  local -a F
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$row")
    [ "${#F[@]}" -eq 15 ] || continue
    model="${F[11]}"; pre="${F[12]}"; post="${F[13]}"; binds="${F[14]}"
    key="$(step_key "$model" "$pre" "$post" "$binds")"
    [ -n "${AUX_RC[$key]:-}" ] && continue
    prepare_model "$model" || { AUX_RC["$key"]="?"; continue; }
    tok="$(type_invariant "$model")"
    if [ -z "$tok" ]; then
      printf '  %s names no type invariant, so its pins were checked for the step count only\n' \
        "$model" >&2
    fi
    AUX_N=$((AUX_N+1))
    mod="$(write_aux "$AUX_N" "$model" "$pre" "$post" "$binds" "$tok")"
    rc="$(tlc_rc "$mod" "${mod%.tla}.cfg")"
    AUX_RC["$key"]="$rc"
  done < <(rows)
}

aux_rc_of() {
  local key
  key="$(step_key "$1" "$2" "$3" "$4")"
  printf '%s\n' "${AUX_RC[$key]:-?}"
}

# ---------------------------------------------------------------------------
# --stats. The base rate is the share of the most common SWIPE in a template's
# own output, which is the chance floor bead tla-7xql.1 measures against. It
# is computed from the corpus rather than assumed.
# ---------------------------------------------------------------------------
stats() {
  printf '%-4s %6s %5s %6s %8s %10s %11s %9s %6s %5s %5s %10s\n' \
    tpl items true false vacuous illformed wronglevel unparsed \
    right left down 'base rate'
  local t
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    if [ -n "$TEMPLATE" ] && [ "$t" != "$TEMPLATE" ]; then continue; fi
    local counts
    counts="$(awk -F'\t' -v t="$t" '
      $1 == "ITEM" && $3 == t { n++; kind[$5]++; swipe[$6]++ }
      END {
        top = 0
        for (s in swipe) if (swipe[s] > top) top = swipe[s]
        rate = (n > 0) ? 100 * top / n : 0
        printf "%d %d %d %d %d %d %d %d %d %d %.1f", n,
          kind["true"], kind["false"], kind["vacuous"], kind["illformed"],
          kind["wronglevel"], kind["unparsed"],
          swipe["right"], swipe["left"], swipe["down"], rate
      }' "$ITEMS")"
    local n a b c d e f g h i rate
    read -r n a b c d e f g h i rate <<<"$counts"
    [ "$n" -eq 0 ] && continue
    printf '%-4s %6s %5s %6s %8s %10s %11s %9s %6s %5s %5s %9s%%\n' \
      "$t" "$n" "$a" "$b" "$c" "$d" "$e" "$f" "$g" "$h" "$i" "$rate"
  done < <(awk -F'\t' '$1 == "ITEM" { print $3 }' "$ITEMS" | LC_ALL=C sort -u)
}

# ---------------------------------------------------------------------------
# One item, measured. Prints "<rc_claim> <rc_witness>" on stdout and the
# reasons on stderr. The witness slot reads - when the item declares none, and
# the pin's own reading comes from the pass above rather than from here.
# ---------------------------------------------------------------------------
measure() {
  local id="$1" model="$2" pre="$3" post="$4" binds="$5" claim="$6" witness="$7"
  local safe="${id//-/_}"
  local mod rc_claim rc_wit

  prepare_model "$model" || { printf '? ?\n'; return 0; }

  mod="$(write_claim "$safe" "$model" "$pre" "$post" "$binds" "$claim")"
  rc_claim="$(tlc_rc "$mod" "${mod%.tla}.cfg")"

  rc_wit="-"
  if [ "$witness" != "-" ]; then
    mod="$(write_claim "W_$safe" "$model" "$pre" "$post" "$binds" "$witness")"
    rc_wit="$(tlc_rc "$mod" "${mod%.tla}.cfg")"
  fi

  printf '%s %s\n' "$rc_claim" "$rc_wit"
}

# The auxiliary run's readings, named. A number with no name here is how a
# type failure gets reported as a step-count failure, which sends the next
# author at the wrong half of the item.
aux_note() {
  local id="$1" rc="$2" model="$3"
  case "$rc" in
    0)  return 0 ;;
    12) printf '  %s: a pinned state violates %s own type invariant\n' "$id" "$model" >&2 ;;
    10) printf '  %s: the pin is not one step, so it does not admit %s states\n' "$id" "$PIN_STATES" >&2 ;;
    75) printf '  %s: %s type invariant does not evaluate at the pinned pre-state\n' "$id" "$model" >&2 ;;
    76) printf '  %s: %s type invariant does not evaluate at the pinned post-state\n' "$id" "$model" >&2 ;;
    *)  printf '  %s: the auxiliary run came back rc %s, which is neither the type nor the step count\n' \
          "$id" "$rc" >&2 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# --check
# ---------------------------------------------------------------------------
check() {
  local row id kind claim vacuity model pre post binds
  local -a F
  local n=0

  pin_pass

  while IFS= read -r row; do
    [ -z "$row" ] && continue
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$row")
    if [ "${#F[@]}" -ne 15 ]; then
      printf '  a row carries %s fields and an item row carries 15\n' "${#F[@]}" >&2
      DEFECTS=$((DEFECTS+1))
      continue
    fi
    id="${F[1]}"; kind="${F[4]}"; claim="${F[8]}"; vacuity="${F[9]}"
    model="${F[11]}"; pre="${F[12]}"; post="${F[13]}"; binds="${F[14]}"
    n=$((n+1))

    local want_swipe want_rcs
    want_swipe="$(swipe_for "$kind")"
    want_rcs="$(rc_set_for "$kind")"
    if [ "$want_swipe" = "UNKNOWN" ]; then
      printf '  %s: kind %s is not one the channel names\n' "$id" "$kind" >&2
      DEFECTS=$((DEFECTS+1))
      continue
    fi
    if [ "${F[5]}" != "$want_swipe" ]; then
      printf '  %s: swipe reads %s and kind %s earns %s\n' "$id" "${F[5]}" "$kind" "$want_swipe" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    if ! rc_allowed "${F[6]}" "$want_rcs"; then
      printf '  %s: stored rc %s and kind %s allows %s\n' "$id" "${F[6]}" "$kind" "$want_rcs" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    if [ "${F[7]}" != "$PIN_STATES" ]; then
      printf '  %s: field 8 reads %s and a pinned step is always %s states\n' \
        "$id" "${F[7]}" "$PIN_STATES" >&2
      DEFECTS=$((DEFECTS+1))
    fi

    local got
    got="$(measure "$id" "$model" "$pre" "$post" "$binds" "$claim" "$vacuity")"
    local rc_claim rc_aux rc_wit
    read -r rc_claim rc_wit <<<"$got"
    rc_aux="$(aux_rc_of "$model" "$pre" "$post" "$binds")"

    if ! rc_allowed "$rc_claim" "$want_rcs"; then
      printf '  %s: TLC reads rc %s and kind %s allows %s\n' "$id" "$rc_claim" "$kind" "$want_rcs" >&2
      DEFECTS=$((DEFECTS+1))
    elif [ "$rc_claim" != "${F[6]}" ]; then
      printf '  %s: TLC reads rc %s and the table stored rc %s, both inside kind %s\n' \
        "$id" "$rc_claim" "${F[6]}" "$kind" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    aux_note "$id" "$rc_aux" "$model" || DEFECTS=$((DEFECTS+1))
    if [ "$kind" = "vacuous" ]; then
      if [ "$rc_wit" != "0" ]; then
        printf '  %s: the vacuity witness came back rc %s, so the subscript moved and the item is true rather than vacuous\n' \
          "$id" "$rc_wit" >&2
        DEFECTS=$((DEFECTS+1))
      fi
    elif [ "$rc_wit" != "-" ]; then
      printf '  %s: kind %s carries a vacuity witness, which only a vacuous item has\n' "$id" "$kind" >&2
      DEFECTS=$((DEFECTS+1))
    fi
  done < <(rows)

  # A run over nothing exits 0 and reads as a confirmation. TLC has the same
  # hole one level up: a .cfg with a bare PROPERTY keyword exits 0 having
  # checked nothing. So an empty selection is a defect here and not a pass.
  if [ "$n" -eq 0 ]; then
    printf '  the selection matched no item at all, and an empty run confirms nothing\n' >&2
    DEFECTS=$((DEFECTS+1))
  fi
  printf 'checked %s items over %s pinned steps\n' "$n" "$AUX_N"
}

# ---------------------------------------------------------------------------
# --write. The authored kind in field 5 is the author's PREDICTION, so a
# disagreement is reported against the author rather than written over.
# ---------------------------------------------------------------------------
write_table() {
  local line id kind claim vacuity model pre post binds got rc_claim rc_aux rc_wit got_kind
  local out="$ITEMS.new"
  local -a F
  : > "$out"

  pin_pass

  while IFS= read -r line; do
    case "$line" in
      ITEM*) ;;
      *) printf '%s\n' "$line" >> "$out"; continue ;;
    esac
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    if [ "${#F[@]}" -ne 15 ]; then
      printf '  a row carries %s fields and an item row carries 15\n' "${#F[@]}" >&2
      DEFECTS=$((DEFECTS+1))
      printf '%s\n' "$line" >> "$out"
      continue
    fi
    id="${F[1]}"; kind="${F[4]}"; claim="${F[8]}"; vacuity="${F[9]}"
    model="${F[11]}"; pre="${F[12]}"; post="${F[13]}"; binds="${F[14]}"

    got="$(measure "$id" "$model" "$pre" "$post" "$binds" "$claim" "$vacuity")"
    read -r rc_claim rc_wit <<<"$got"
    rc_aux="$(aux_rc_of "$model" "$pre" "$post" "$binds")"

    got_kind="$(kind_for_rc "$rc_claim")"
    if [ "$kind" = "vacuous" ] && [ "$got_kind" = "true" ]; then
      if [ "$rc_wit" = "0" ]; then
        got_kind="vacuous"
      else
        printf '  %s: witness came back rc %s, so the subscript moved and the item is true rather than vacuous\n' \
          "$id" "$rc_wit" >&2
        DEFECTS=$((DEFECTS+1))
      fi
    fi
    if [ "$got_kind" != "$kind" ]; then
      printf '  %s: authored kind %s and TLC says %s, rc %s\n' \
        "$id" "$kind" "$got_kind" "$rc_claim" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    aux_note "$id" "$rc_aux" "$model" || DEFECTS=$((DEFECTS+1))

    awk -F'\t' -v OFS='\t' -v s="$(swipe_for "$kind")" -v a="$rc_claim" -v b="$PIN_STATES" \
      '{ $6 = s; $7 = a; $8 = b; print }' <<<"$line" >> "$out"
    printf '  %-13s %-11s rc %-4s\n' "$id" "$got_kind" "$rc_claim"
  done < "$ITEMS"

  mv "$out" "$ITEMS"
  printf '\n%s pinned steps checked\n' "$AUX_N"
  if [ "$DEFECTS" -gt 0 ]; then
    printf '\n%s items disagree with their authored kind or their pin. Fix the item, then re-run\n' \
      "$DEFECTS" >&2
    return 1
  fi
  printf 'wrote fields 6 to 8 for every item in %s\n' "$ITEMS"
}

case "$MODE" in
  stats) stats ;;
  write) write_table ;;
  check)
    check
    if [ "$DEFECTS" -ne 0 ]; then
      printf '\n%s defects\n' "$DEFECTS" >&2
      exit 1
    fi
    printf 'every stored verdict confirmed\n'
    ;;
esac
