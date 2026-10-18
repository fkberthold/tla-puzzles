#!/usr/bin/env bash
# bake.sh -- the level 1 verdict channel (bead tla-7xql.4, epic tla-7xql).
#
# Every verdict in swipe/level1/ITEMS.tsv comes from a TLC exit code through
# harness/verdict.sh. Nothing here reads TLC's stdout, which is the rule
# V2-PLAN.md section 5.1 sets for the rest of the harness.
#
# ===========================================================================
# THE CHANNEL, AND WHY IT IS AN INVARIANT RATHER THAN A PAIR OF ASSUMES
# ===========================================================================
#
# Level 0 runs two ASSUMEs per claim because rc 10 covers both "false" and
# "did not evaluate". Level 1 needs neither the ASSUME nor the pair. A pinned
# item generates a module that EXTENDS the real model, so the model stays the
# single source of truth and a model edit propagates to every item on it:
#
#   ---- MODULE Pin_L1_E1_01 ----
#   EXTENDS Brackets
#   Ini == text = <<"(", "(", ")">> /\ open = 1
#   Nxt == UNCHANGED vars
#   Claim == ENABLED Pop
#   ====
#
# with a .cfg of INIT Ini, NEXT Nxt, the model's own CONSTANT block, and
# INVARIANT Claim. The .cfg names Claim and nothing else, which is decision D2
# satisfied mechanically rather than visually: the model's own obligations are
# not declared, so they do not run. Measured -- a pin of open = 5 violates
# Brackets' own Surplus invariant and ENABLED Pop still reads rc 0.
#
# THE INVARIANT ROUTE IS FORCED, not chosen. The epic's note records the same
# question reading three codes depending on how it is written: PROPERTY P
# reads 13, PROPERTY []P reads 12 and INVARIANT P reads 12. A generator has to
# fix one form and keep it, and the exploration's F1 picked this one.
#
# THE FIVE ROWS, every one measured on TLC 2026.07.31.184830 on 2026-10-18:
#
#   rc   kind        swipe  what happened
#   ---  ----------  -----  -----------------------------------------------
#     0  true        right  the claim holds at the pin
#    12  false       left   the claim is false at the pin
#    75  illformed   down   the claim does not evaluate at the pin
#    76  wronglevel  down   the claim is not a state predicate at all
#   150  unparsed    down   SANY refuses the module
#
# A vacuous item also reads 0, so rc alone cannot tell it from a plainly true
# one. Field 10 carries a witness, exactly as level 0 does.
#
# ROW 75 IS NOT ROW 76, AND THE DIFFERENCE IS THE WHOLE BEAD. 75 is
# SPEC_EVAL_FAILURE: TLC says "Attempted to access index 4 of tuple ... While
# working on the initial state", because the invariant is evaluated while the
# initial states are computed, so an evaluation error lands on the spec rather
# than on the invariant. 76 is SAFETY_EVAL_FAILURE and TLC says "The invariant
# Claim is not a state predicate (one with no primes or temporal operators)".
#
# That second message is the lesson this bead exists for. A reader who writes
# Pop where they mean ENABLED Pop has asked whether a STEP holds at a STATE,
# which is not a question. The bead's own words are that people conflate "the
# guard is true" with "the action can fire"; row 76 is the conflation one
# layer further out, and TLC names it exactly.
#
# ROW 150 IS THE ENABLED PRECEDENCE TRAP, which is this template's own parse
# failure rather than a borrowed one. ENABLED Pop = TRUE and ENABLED Pop' both
# come back "Precedence conflict between ops ENABLED ... and = / '". Level 0's
# rule is that a template's unparsed item is a trap in its own subject matter,
# and ENABLED binds tighter than a reader expects.
#
# ===========================================================================
# THE AUXILIARY RUN: ONE JVM, TWO MEASUREMENTS
# ===========================================================================
#
# THE PIN MUST SATISFY THE MODEL'S OWN TYPE INVARIANT, and it need not be
# reachable. Nothing in the mechanization constrains a pin, so a generator can
# pin a state the system can never be in. TypeOK is the model's own statement
# of what a well-formed state is, and ENABLED is a question about a state
# rather than about a history, so an unreachable but type-correct state still
# teaches the right lesson. Reachability would cost a model check and cut the
# item space hard. THIS IS CENTRAL'S RULE AND FRANK HAS NOT RULED ON IT.
#
# THE PIN'S STATE COUNT IS MEASURED TOO, and that one is a hazard rather than
# a policy. Ini is a predicate, not an assignment, so it may admit more than
# one state, and then INVARIANT Claim asks whether the claim holds at EVERY
# state it admits. Measured: text = <<>> /\ open \in 0..1 with ENABLED Pop
# reads 12, because the claim splits across the two states. The item is still
# well posed -- Handover's constants are model values the pin module cannot
# name, so holder \in Site is the only way to pin it at all -- but an author
# who thinks they pinned one state and pinned three has shipped a different
# question. So field 8 is the count and the bake measures it.
#
# Both ride one JVM. The module EXTENDS the model and TLC, defines
# PinStates == TLCGet("distinct") = <field 8>, and the .cfg declares
# INVARIANT TypeOK with POSTCONDITION PinStates. Measured:
#
#   rc 0   the pin is type-correct and admits exactly the declared count
#   rc 12  the pin violates the model's own type invariant
#   rc 10  the pin admits a different number of states
#
# TLCGet("distinct") counts distinct states rather than initial ones, and that
# is the same number here because Nxt is UNCHANGED vars, so the only successor
# of a state is itself.
#
# USAGE
#   swipe/level1/bake.sh [--check | --write | --stats] [OPTIONS]
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
ITEMS="$ROOT/swipe/level1/ITEMS.tsv"

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
  SCRATCH="$(mktemp -d -t swipe_level1.XXXXXX)"
fi

DEFECTS=0

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
# the epic and is forced rather than chosen, and unparsed is Frank's ruling of
# 2026-10-18 on bead tla-7xql.10, taken on the same reading. wronglevel is new
# at this rung and arrives the same way: it is a third thing a reader cannot
# call true or false, so it has no other gesture available.
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

# The exit code a kind predicts. A vacuous item is true, so it shares rc 0
# with a plainly true one and field 10 is what separates them.
rc_for() {
  case "$1" in
    true|vacuous) printf '0\n' ;;
    false)        printf '12\n' ;;
    illformed)    printf '75\n' ;;
    wronglevel)   printf '76\n' ;;
    unparsed)     printf '150\n' ;;
    *)            printf '?\n' ;;
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

consts_block() {
  local name="$1" src
  src="$(model_tla "$name")"
  [ -n "$src" ] || return 0
  awk '
    /^[[:space:]]*CONSTANTS?([[:space:]]|$)/ { inb = 1; print; next }
    inb && /^[[:space:]]+[^[:space:]]/ { print; next }
    inb { exit }
  ' "${src%.tla}.cfg"
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

# Writes the claim module and its .cfg, and prints the module path. The claim
# goes in as a printf ARGUMENT and never into the format string, because bash
# printf reads a backslash in a format and a TLA+ conjunction would arrive as
# something else.
write_claim() {
  local safe="$1" model="$2" pin="$3" claim="$4"
  local mod="Pin_$safe"
  {
    printf -- '---- MODULE %s ----\n' "$mod"
    printf 'EXTENDS %s\n\n' "$model"
    printf 'Ini == %s\n\n' "$pin"
    printf 'Nxt == UNCHANGED vars\n\n'
    printf 'Claim == %s\n' "$claim"
    printf -- '====\n'
  } > "$SCRATCH/$mod.tla"
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    consts_block "$model"
    printf 'INVARIANT Claim\n'
  } > "$SCRATCH/$mod.cfg"
  printf '%s\n' "$SCRATCH/$mod.tla"
}

# The auxiliary module. TypeOK as the invariant and the pin's own state count
# as a postcondition, so one JVM answers both.
write_aux() {
  local safe="$1" model="$2" pin="$3" want="$4" tok="$5"
  local mod="Aux_$safe"
  {
    printf -- '---- MODULE %s ----\n' "$mod"
    printf 'EXTENDS %s, TLC\n\n' "$model"
    printf 'Ini == %s\n\n' "$pin"
    printf 'Nxt == UNCHANGED vars\n\n'
    printf 'PinStates == TLCGet("distinct") = %s\n' "$want"
    printf -- '====\n'
  } > "$SCRATCH/$mod.tla"
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    consts_block "$model"
    if [ -n "$tok" ]; then printf 'INVARIANT %s\n' "$tok"; fi
    printf 'POSTCONDITION PinStates\n'
  } > "$SCRATCH/$mod.cfg"
  printf '%s\n' "$SCRATCH/$mod.tla"
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
# One item, measured. Prints "<rc_claim> <rc_aux> <rc_witness>" on stdout and
# the reasons on stderr. The witness slot reads - when the item declares none.
# ---------------------------------------------------------------------------
measure() {
  local id="$1" model="$2" pin="$3" claim="$4" witness="$5" want_states="$6"
  local safe="${id//-/_}"
  local mod rc_claim rc_aux rc_wit tok

  prepare_model "$model" || { printf '? ? ?\n'; return 0; }

  mod="$(write_claim "$safe" "$model" "$pin" "$claim")"
  rc_claim="$(tlc_rc "$mod" "${mod%.tla}.cfg")"

  tok="$(type_invariant "$model")"
  if [ -z "$tok" ]; then
    printf '  %s: %s names no type invariant, so the pin was checked for its state count only\n' \
      "$id" "$model" >&2
  fi
  mod="$(write_aux "$safe" "$model" "$pin" "$want_states" "$tok")"
  rc_aux="$(tlc_rc "$mod" "${mod%.tla}.cfg")"

  rc_wit="-"
  if [ "$witness" != "-" ]; then
    mod="$(write_claim "W_$safe" "$model" "$pin" "$witness")"
    rc_wit="$(tlc_rc "$mod" "${mod%.tla}.cfg")"
  fi

  printf '%s %s %s\n' "$rc_claim" "$rc_aux" "$rc_wit"
}

# The auxiliary run's three readings, named. A number with no name here is how
# a type-invariant failure gets reported as a state-count failure, which sends
# the next author at the wrong half of the item.
aux_note() {
  local id="$1" rc="$2" want="$3" model="$4"
  case "$rc" in
    0)  return 0 ;;
    12) printf '  %s: the pin violates %s own type invariant\n' "$id" "$model" >&2 ;;
    10) printf '  %s: the pin does not admit %s states\n' "$id" "$want" >&2 ;;
    *)  printf '  %s: the auxiliary run came back rc %s, which is neither the type nor the count\n' \
          "$id" "$rc" >&2 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# --check
# ---------------------------------------------------------------------------
check() {
  local row id kind claim vacuity model pin states
  local -a F
  local n=0

  while IFS= read -r row; do
    [ -z "$row" ] && continue
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$row")
    if [ "${#F[@]}" -ne 13 ]; then
      printf '  a row carries %s fields and an item row carries 13\n' "${#F[@]}" >&2
      DEFECTS=$((DEFECTS+1))
      continue
    fi
    id="${F[1]}"; kind="${F[4]}"; claim="${F[8]}"; vacuity="${F[9]}"
    model="${F[11]}"; pin="${F[12]}"; states="${F[7]}"
    n=$((n+1))

    local want_swipe want_rc
    want_swipe="$(swipe_for "$kind")"
    want_rc="$(rc_for "$kind")"
    if [ "$want_swipe" = "UNKNOWN" ]; then
      printf '  %s: kind %s is not one the channel names\n' "$id" "$kind" >&2
      DEFECTS=$((DEFECTS+1))
      continue
    fi
    if [ "${F[5]}" != "$want_swipe" ]; then
      printf '  %s: swipe reads %s and kind %s earns %s\n' "$id" "${F[5]}" "$kind" "$want_swipe" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    if [ "${F[6]}" != "$want_rc" ]; then
      printf '  %s: stored rc %s and kind %s predicts %s\n' "$id" "${F[6]}" "$kind" "$want_rc" >&2
      DEFECTS=$((DEFECTS+1))
    fi

    local got
    got="$(measure "$id" "$model" "$pin" "$claim" "$vacuity" "$states")"
    local rc_claim rc_aux rc_wit
    read -r rc_claim rc_aux rc_wit <<<"$got"

    if [ "$rc_claim" != "$want_rc" ]; then
      printf '  %s: TLC reads rc %s and kind %s predicts %s\n' "$id" "$rc_claim" "$kind" "$want_rc" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    aux_note "$id" "$rc_aux" "$states" "$model" || DEFECTS=$((DEFECTS+1))
    if [ "$kind" = "vacuous" ]; then
      if [ "$rc_wit" != "0" ]; then
        printf '  %s: the vacuity witness came back rc %s, so the item is true but not vacuous\n' \
          "$id" "$rc_wit" >&2
        DEFECTS=$((DEFECTS+1))
      fi
    elif [ "$rc_wit" != "-" ]; then
      printf '  %s: kind %s carries a vacuity witness, which only a vacuous item has\n' "$id" "$kind" >&2
      DEFECTS=$((DEFECTS+1))
    fi
  done < <(rows)

  # A run over nothing exits 0 and reads as a confirmation. TLC has the same
  # hole one level up: a .cfg with a bare INVARIANT keyword exits 0 having
  # checked nothing. So an empty selection is a defect here and not a pass.
  if [ "$n" -eq 0 ]; then
    printf '  the selection matched no item at all, and an empty run confirms nothing\n' >&2
    DEFECTS=$((DEFECTS+1))
  fi
}

# ---------------------------------------------------------------------------
# --write. The authored kind in field 5 is the author's PREDICTION, so a
# disagreement is reported against the author rather than written over.
# ---------------------------------------------------------------------------
write_table() {
  local line id kind claim vacuity model pin states got rc_claim rc_aux rc_wit got_kind
  local out="$ITEMS.new"
  local -a F
  : > "$out"

  while IFS= read -r line; do
    case "$line" in
      ITEM*) ;;
      *) printf '%s\n' "$line" >> "$out"; continue ;;
    esac
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    id="${F[1]}"; kind="${F[4]}"; claim="${F[8]}"; vacuity="${F[9]}"
    model="${F[11]}"; pin="${F[12]}"; states="${F[7]}"
    [ "$states" = "-" ] && states=1

    got="$(measure "$id" "$model" "$pin" "$claim" "$vacuity" "$states")"
    read -r rc_claim rc_aux rc_wit <<<"$got"

    case "$rc_claim" in
      0)   got_kind="true" ;;
      12)  got_kind="false" ;;
      75)  got_kind="illformed" ;;
      76)  got_kind="wronglevel" ;;
      150) got_kind="unparsed" ;;
      *)   got_kind="UNKNOWN_$rc_claim" ;;
    esac
    if [ "$kind" = "vacuous" ] && [ "$got_kind" = "true" ]; then
      if [ "$rc_wit" = "0" ]; then
        got_kind="vacuous"
      else
        printf '  %s: witness came back rc %s, so the item is true but not vacuous\n' \
          "$id" "$rc_wit" >&2
        DEFECTS=$((DEFECTS+1))
      fi
    fi
    if [ "$got_kind" != "$kind" ]; then
      printf '  %s: authored kind %s and TLC says %s, rc %s\n' \
        "$id" "$kind" "$got_kind" "$rc_claim" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    aux_note "$id" "$rc_aux" "$states" "$model" || DEFECTS=$((DEFECTS+1))

    awk -F'\t' -v OFS='\t' -v s="$(swipe_for "$kind")" -v a="$rc_claim" -v b="$states" \
      '{ $6 = s; $7 = a; $8 = b; print }' <<<"$line" >> "$out"
    printf '  %-12s %-11s rc %-4s pin %s states\n' "$id" "$got_kind" "$rc_claim" "$states"
  done < "$ITEMS"

  mv "$out" "$ITEMS"
  if [ "$DEFECTS" -gt 0 ]; then
    printf '\n%s items disagree with their authored kind or their pin. Fix the item, then re-run\n' \
      "$DEFECTS" >&2
    return 1
  fi
  printf '\nwrote fields 6 to 8 for every item in %s\n' "$ITEMS"
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
