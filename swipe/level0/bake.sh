#!/usr/bin/env bash
# bake.sh -- the level 0 verdict channel (bead tla-7xql.2, epic tla-7xql).
#
# Every verdict in swipe/level0/ITEMS.tsv comes from a TLC exit code through
# harness/verdict.sh. Nothing here reads TLC's stdout, which is the rule
# V2-PLAN.md section 5.1 sets for the rest of the harness.
#
# THE CHANNEL, AND WHY IT IS ASSUME RATHER THAN INVARIANT. Measured on
# TLC 2026.07.31.184830 (tla2tools v1.8.0) on 2026-10-17:
#
#   ASSUME (e)              e is true              rc 0
#   ASSUME (e)              e is false             rc 10  ASSUMPTION_FAILED
#   ASSUME (e)              e does not evaluate    rc 10  ASSUMPTION_FAILED
#   ASSUME ((e) \/ ~(e))    e is well formed       rc 0
#   ASSUME ((e) \/ ~(e))    e does not evaluate    rc 10  ASSUMPTION_FAILED
#
# The first channel on its own is two-valued, because rc 10 covers both "false"
# and "did not evaluate". The second splits them: a well-formed boolean
# satisfies e \/ ~e whatever its value, so only a claim that fails to evaluate
# can redden it. The PAIR is the three-way verdict, and reading it as a pair is
# the point. Never predict one member of it from the other.
#
#   rc_claim  rc_wf   verdict              swipe
#   --------  -----   ------------------   -----
#   0         0       the claim holds      right
#   10        0       the claim is false   left
#   10        10      it does not evaluate down
#
# A CONSTANT INVARIANT IS NOT THE CHANNEL, and this corrects the table this
# bead was briefed with. A level 0 expression declared as an INVARIANT and
# found false comes back rc 151 CONFIG_ERROR, not rc 12:
#
#   Error: The invariant of Refuted is equal to FALSE
#
# V2-PLAN.md already records the folding for the literal INVARIANT FALSE. What
# it does not say, and what this rung turns on, is that the literal is not the
# point: EVERY constant-level expression that evaluates to FALSE folds the same
# way, which is the whole refuted class here. Measured against
# Cardinality(SUBSET {1, 2, 3}) = 6.
#
# So an invariant channel would have labeled every false item a config defect.
# rc 12 needs an invariant TLC cannot fold, which means a state-dependent one,
# which means level 1 or above. The {12, 13} row belongs to the other rungs.
#
# BATCHING IS THE WHOLE REASON LEVEL 0 IS CHEAP. One module with N assumes
# costs one JVM. Measured, worst of three back-to-back runs:
#
#   N=1  382 ms     N=100  535 ms     N=1000  684 ms
#
# So --check runs three batches rather than 80 processes. The one class that
# cannot batch is the items that do not evaluate: the first evaluation error
# aborts the whole batch, so each of those gets its own run.
#
# USAGE
#   swipe/level0/bake.sh [--check | --write | --stats] [OPTIONS]
#
#   --check            confirm every stored verdict. The default
#   --write            measure every item from scratch and write fields 6-8
#   --stats            per-template counts, swipe mix and base rates
#   --template ID      scope --check and --stats to one template, T1 to T5
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
ITEMS="$ROOT/swipe/level0/ITEMS.tsv"

MODE="check"
TEMPLATE=""
EMIT=""

usage() {
  cat <<'USAGE'
usage: swipe/level0/bake.sh [--check | --write | --stats] [OPTIONS]

  --check          confirm every stored verdict against TLC. The default
  --write          measure every item from scratch and write fields 6-8
  --stats          per-template counts, swipe mix and base rates
  --template ID    scope --check and --stats to one template, T1 to T5
  --emit DIR       keep the generated modules in DIR
  --items FILE     read a different item table
  -h, --help       this text
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check)    MODE="check"; shift ;;
    --write)    MODE="write"; shift ;;
    --stats)    MODE="stats"; shift ;;
    --template) TEMPLATE="${2:-}"; shift 2 ;;
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
  SCRATCH="$(mktemp -d -t swipe_level0.XXXXXX)"
fi

# Every generated module extends the same four. TLC is in the list although no
# item needs it yet, so an item reaching for @@ or :> lands as a wrong verdict
# the gate catches rather than as a parse error nobody expects.
EXTENDS_LINE='EXTENDS Integers, FiniteSets, Sequences, TLC'

printf '\\* bake.sh writes no keywords here. The ASSUME channel needs none.\n' \
  > "$SCRATCH/Empty.cfg"

DEFECTS=0

# ---------------------------------------------------------------------------
# Reading the table.
#
# One awk call per row, emitting one field per line into an array. That is the
# idiom harness/test-corpus-manifest.sh settled on, and the reason is in its
# comment: `IFS=$'\t' read` is wrong here, because tab is IFS whitespace, so a
# run of tabs collapses into one delimiter and an empty field disappears.
#
# One fork per row and not one per field. A per-call fork inside a per-item
# loop is this project's recurring performance defect, and harness/drill-gate.sh
# has produced it twice.
# ---------------------------------------------------------------------------
rows() {
  if [ -n "$TEMPLATE" ]; then
    awk -F'\t' -v t="$TEMPLATE" '$1 == "ITEM" && $3 == t' "$ITEMS"
  else
    awk -F'\t' '$1 == "ITEM"' "$ITEMS"
  fi
}

# The swipe a kind earns. Vacuous and ill-formed share the down swipe, which is
# decision D3 on the epic and is forced rather than chosen: without the merge a
# vacuous item has no correct swipe at all. The cost is that the swipe stops
# telling the two apart, which is why field 5 keeps the kind.
swipe_for() {
  case "$1" in
    true)      printf 'right\n' ;;
    false)     printf 'left\n' ;;
    vacuous)   printf 'down\n' ;;
    illformed) printf 'down\n' ;;
    *)         printf 'UNKNOWN\n' ;;
  esac
}

# The exit-code pair a kind predicts.
rc_pair_for() {
  case "$1" in
    true|vacuous) printf '0 0\n' ;;
    false)        printf '10 0\n' ;;
    illformed)    printf '10 10\n' ;;
    *)            printf '? ?\n' ;;
  esac
}

# ---------------------------------------------------------------------------
# Running TLC. The verdict is the raw exit status and nothing else.
# ---------------------------------------------------------------------------
tlc_rc() {
  local module="$1" rc=0
  "$VERDICT" -q -c "$SCRATCH/Empty.cfg" "$module" >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}

# Writes a module holding one ASSUME per line of stdin, and prints its path.
write_batch() {
  local name="$1"
  local file="$SCRATCH/$name.tla"
  {
    printf -- '---- MODULE %s ----\n' "$name"
    printf '%s\n\n' "$EXTENDS_LINE"
    cat
    printf -- '====\n'
  } > "$file"
  printf '%s\n' "$file"
}

# ---------------------------------------------------------------------------
# --stats. The base rate is the share of the most common swipe in a template's
# own output, which is the chance floor bead tla-7xql.1 measures against. It is
# not one third: computing it from the corpus rather than assuming a uniform
# mix is what that bead asks for.
# ---------------------------------------------------------------------------
stats() {
  printf '%-4s %6s %5s %6s %8s %10s %6s %5s %5s %10s\n' \
    tpl items true false vacuous illformed right left down 'base rate'
  local t
  for t in T1 T2 T3 T4 T5; do
    if [ -n "$TEMPLATE" ] && [ "$t" != "$TEMPLATE" ]; then
      continue
    fi
    local counts
    counts="$(awk -F'\t' -v t="$t" '
      $1 == "ITEM" && $3 == t {
        n++
        kind[$5]++
        swipe[$6]++
      }
      END {
        top = 0
        for (s in swipe) if (swipe[s] > top) top = swipe[s]
        rate = (n > 0) ? 100 * top / n : 0
        printf "%d %d %d %d %d %d %d %d %.1f", n,
          kind["true"], kind["false"], kind["vacuous"], kind["illformed"],
          swipe["right"], swipe["left"], swipe["down"], rate
      }' "$ITEMS")"
    local n n_true n_false n_vac n_ill n_right n_left n_down rate
    read -r n n_true n_false n_vac n_ill n_right n_left n_down rate <<<"$counts"
    if [ "$n" -eq 0 ]; then
      continue
    fi
    printf '%-4s %6s %5s %6s %8s %10s %6s %5s %5s %9s%%\n' \
      "$t" "$n" "$n_true" "$n_false" "$n_vac" "$n_ill" \
      "$n_right" "$n_left" "$n_down" "$rate"
  done
}

# ---------------------------------------------------------------------------
# --check. Three batches plus one run per item that does not evaluate.
# ---------------------------------------------------------------------------
check() {
  local row id kind claim vacuity
  local -a holds=() refuted=() vacwit=() illid=() illclaim=()
  local -a F

  while IFS= read -r row; do
    [ -z "$row" ] && continue
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$row")
    if [ "${#F[@]}" -ne 11 ]; then
      printf '  a row carries %s fields and an item row carries 11\n' "${#F[@]}" >&2
      DEFECTS=$((DEFECTS+1))
      continue
    fi
    id="${F[1]}"
    kind="${F[4]}"
    claim="${F[8]}"
    vacuity="${F[9]}"

    # Fields 6, 7 and 8 are derived from field 5, so a hand edit that breaks
    # the derivation is a defect before TLC is started at all.
    local want_swipe pair want_rc want_wf
    want_swipe="$(swipe_for "$kind")"
    pair="$(rc_pair_for "$kind")"
    want_rc="${pair% *}"
    want_wf="${pair#* }"
    if [ "${F[5]}" != "$want_swipe" ]; then
      printf '  %s: swipe reads %s and kind %s earns %s\n' \
        "$id" "${F[5]}" "$kind" "$want_swipe" >&2
      DEFECTS=$((DEFECTS+1))
    fi
    if [ "${F[6]}" != "$want_rc" ] || [ "${F[7]}" != "$want_wf" ]; then
      printf '  %s: stored pair (%s, %s) and kind %s predicts (%s, %s)\n' \
        "$id" "${F[6]}" "${F[7]}" "$kind" "$want_rc" "$want_wf" >&2
      DEFECTS=$((DEFECTS+1))
    fi

    case "$kind" in
      true)
        holds+=("ASSUME ($claim)") ;;
      vacuous)
        holds+=("ASSUME ($claim)")
        vacwit+=("ASSUME ($vacuity)") ;;
      false)
        refuted+=("ASSUME ~($claim)") ;;
      illformed)
        illid+=("$id")
        illclaim+=("$claim") ;;
      *)
        printf '  %s: kind %s is not one of true, false, vacuous, illformed\n' \
          "$id" "$kind" >&2
        DEFECTS=$((DEFECTS+1)) ;;
    esac
  done < <(rows)

  # A batch of nothing exits 0 and would read as a confirmation. TLC has the
  # same hole one level up: a .cfg with a bare INVARIANT keyword exits 0 having
  # checked nothing. So an empty batch is a defect here and not a pass.
  if [ "${#holds[@]}" -eq 0 ] || [ "${#refuted[@]}" -eq 0 ]; then
    printf '  the holds batch has %s items and the refuted batch %s. An empty batch confirms nothing\n' \
      "${#holds[@]}" "${#refuted[@]}" >&2
    DEFECTS=$((DEFECTS+1))
    return 0
  fi

  local mod rc
  mod="$(printf '%s\n' "${holds[@]}" | write_batch SwipeHolds)"
  rc="$(tlc_rc "$mod")"
  if [ "$rc" != "0" ]; then
    printf '  the %s claims that should hold came back rc %s, so at least one does not\n' \
      "${#holds[@]}" "$rc" >&2
    DEFECTS=$((DEFECTS+1))
  fi

  mod="$(printf '%s\n' "${refuted[@]}" | write_batch SwipeRefuted)"
  rc="$(tlc_rc "$mod")"
  if [ "$rc" != "0" ]; then
    printf '  the %s claims that should be false came back rc %s, so at least one is not\n' \
      "${#refuted[@]}" "$rc" >&2
    DEFECTS=$((DEFECTS+1))
  fi

  if [ "${#vacwit[@]}" -gt 0 ]; then
    mod="$(printf '%s\n' "${vacwit[@]}" | write_batch SwipeVacuity)"
    rc="$(tlc_rc "$mod")"
    if [ "$rc" != "0" ]; then
      printf '  the %s vacuity witnesses came back rc %s, so at least one item is not vacuous\n' \
        "${#vacwit[@]}" "$rc" >&2
      DEFECTS=$((DEFECTS+1))
    fi
  fi

  # The one class that cannot batch. The first evaluation error aborts the
  # whole batch, so a batch of these says only that at least one failed.
  local i safe
  for i in "${!illid[@]}"; do
    safe="${illid[$i]//-/_}"
    mod="$(printf 'ASSUME ((%s) \\/ ~(%s))\n' "${illclaim[$i]}" "${illclaim[$i]}" \
      | write_batch "SwipeIll_$safe")"
    rc="$(tlc_rc "$mod")"
    if [ "$rc" != "10" ]; then
      printf '  %s: the well-formedness probe came back rc %s and it needs rc 10\n' \
        "${illid[$i]}" "$rc" >&2
      DEFECTS=$((DEFECTS+1))
    fi
  done
}

# ---------------------------------------------------------------------------
# --write. Two runs per item, both measured, neither inferred from the other.
# The authored kind in field 5 is the author's PREDICTION, so a disagreement is
# reported against the author rather than written over.
# ---------------------------------------------------------------------------
write_table() {
  local line id kind claim safe rc_claim rc_wf got_kind mod
  local out="$ITEMS.new"
  local -a F
  : > "$out"

  while IFS= read -r line; do
    case "$line" in
      ITEM*) ;;
      *) printf '%s\n' "$line" >> "$out"; continue ;;
    esac
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    id="${F[1]}"
    kind="${F[4]}"
    claim="${F[8]}"
    safe="${id//-/_}"

    mod="$(printf 'ASSUME (%s)\n' "$claim" | write_batch "One_$safe")"
    rc_claim="$(tlc_rc "$mod")"
    mod="$(printf 'ASSUME ((%s) \\/ ~(%s))\n' "$claim" "$claim" \
      | write_batch "Wf_$safe")"
    rc_wf="$(tlc_rc "$mod")"

    case "$rc_claim/$rc_wf" in
      0/0)   got_kind="true" ;;
      10/0)  got_kind="false" ;;
      10/10) got_kind="illformed" ;;
      *)     got_kind="UNKNOWN_${rc_claim}_${rc_wf}" ;;
    esac

    # A vacuous item is true, so TLC cannot tell it from a plainly true one.
    # The witness is what settles it, and it runs here too.
    if [ "$kind" = "vacuous" ] && [ "$got_kind" = "true" ]; then
      local rc_vac
      mod="$(printf 'ASSUME (%s)\n' "${F[9]}" | write_batch "Vac_$safe")"
      rc_vac="$(tlc_rc "$mod")"
      if [ "$rc_vac" = "0" ]; then
        got_kind="vacuous"
      else
        printf '  %s: witness came back rc %s, so the item is true but not vacuous\n' \
          "$id" "$rc_vac" >&2
        DEFECTS=$((DEFECTS+1))
      fi
    fi

    if [ "$got_kind" != "$kind" ]; then
      printf '  %s: authored kind %s and TLC says %s, pair (%s, %s)\n' \
        "$id" "$kind" "$got_kind" "$rc_claim" "$rc_wf" >&2
      DEFECTS=$((DEFECTS+1))
    fi

    awk -F'\t' -v OFS='\t' -v s="$(swipe_for "$kind")" \
      -v a="$rc_claim" -v b="$rc_wf" \
      '{ $6 = s; $7 = a; $8 = b; print }' <<<"$line" >> "$out"
    printf '  %-12s %-10s pair (%s, %s)\n' "$id" "$got_kind" "$rc_claim" "$rc_wf"
  done < "$ITEMS"

  mv "$out" "$ITEMS"
  if [ "$DEFECTS" -gt 0 ]; then
    printf '\n%s items disagree with their authored kind. Fix the item or the kind, then re-run\n' \
      "$DEFECTS" >&2
    return 1
  fi
  printf '\nwrote fields 6 to 8 for every item in %s\n' "$ITEMS"
}

case "$MODE" in
  stats)
    stats
    ;;
  write)
    write_table
    ;;
  check)
    check
    if [ "$DEFECTS" -ne 0 ]; then
      printf '\n%s defects\n' "$DEFECTS" >&2
      exit 1
    fi
    printf 'every stored verdict confirmed\n'
    ;;
esac
