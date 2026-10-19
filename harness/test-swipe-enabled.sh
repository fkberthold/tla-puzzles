#!/usr/bin/env bash
# Gate for the level 1 ENABLED swipe corpus (bead tla-7xql.4, epic tla-7xql).
#
# THE INVARIANT, in the bead's own words plus what rendering an item added:
# every shipped level 1 item has a TLC-computed verdict, a pin the model's own
# type invariant accepts, a declared state count the pin really admits, and a
# claim that names nothing the model screen withholds.
#
# The clauses are checked separately and reported separately, because they
# fail for different reasons and because three of them cost JVMs while the
# rest do not.
#
# WHAT RUNS TLC AND WHAT DOES NOT. The structural half is text and costs no
# JVM. swipe/level1/bake.sh --check costs about 100 JVMs per 48-item template:
# a level 1 claim cannot batch, because every item carries its own pin, so
# each item pays one run for its claim and one for the auxiliary
# type-and-count check, and each vacuous one pays a third for its witness. The
# strip sections cost one levels.sh parse per model. The TLC controls are
# scoped to one item each. Section 12 re-measures the five rows of the channel
# on five one-line fixtures.
#
# That count tracks the item total and not a batch count, which is the one
# place this rung is more expensive than level 0: there is nothing to batch.
# A run is the only authority on the number and this paragraph is a
# description rather than a check.
#
# ===========================================================================
# THE RUN SPLITS IN TWO, AND THAT IS WHAT KEEPS A REGISTRY ROW READABLE
# ===========================================================================
#
# Linear cost in items means one row over three templates is the second
# largest in the registry, and it also means a template's growth moves a
# budget that has nothing to do with it. So the sections divide:
#
#   --machinery      everything that is about the CHANNEL rather than about a
#                    template: the structural checker and its controls, the
#                    strip fixture in both directions, the TLC controls, the
#                    five channel rows, and the kind vocabulary. Run once.
#   --template ID    everything that is about ONE template's items: the
#                    structural pass over its rows, its mix, the strip over
#                    its own models, its claim-leak pass, its bake and its
#                    stem-blind probe. One row per template.
#
# With neither flag the whole thing runs, which is what a human wants and what
# any caller outside scripts/test gets by default. The two modes PARTITION the
# sections rather than overlapping, so the four registry rows together assert
# exactly what one unsplit run asserted and no section runs twice.
#
# Lineage: beads tla-7xql.4 and tla-7xql.13.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITEMS="$REPO_ROOT/swipe/level1/ITEMS.tsv"
TEMPLATES="$REPO_ROOT/swipe/level1/TEMPLATES.tsv"
BAKE="$REPO_ROOT/swipe/level1/bake.sh"
RENDER="$REPO_ROOT/swipe/level1/render.sh"
VERDICT="$REPO_ROOT/harness/verdict.sh"
SB="$REPO_ROOT/harness/swipe/stemblind.sh"
README="$REPO_ROOT/swipe/README.md"

# The surface the stem-blind instrument reads at this rung: the claim and the
# pin, which is what varies per item. The model is the premise and is
# withheld. See the --surface block in harness/swipe/stemblind.sh.
SURFACE="9,13"

# Which half of the gate to run. See THE RUN SPLITS IN TWO above.
MODE="all"
TEMPLATE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --machinery) MODE="machinery"; shift ;;
    --template)  MODE="template"; TEMPLATE="${2:-}"; shift 2 ;;
    -h|--help)
      printf 'usage: harness/test-swipe-enabled.sh [--machinery | --template ID]\n'
      exit 0 ;;
    *) printf 'test-swipe-enabled.sh: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done
if [ "$MODE" = "template" ] && [ -z "$TEMPLATE" ]; then
  printf 'test-swipe-enabled.sh: --template needs a template id\n' >&2
  exit 2
fi

# True when the section about a template's own items should run.
want_corpus() { [ "$MODE" != "machinery" ]; }
# True when the section about the channel itself should run.
want_machinery() { [ "$MODE" != "template" ]; }

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

SCRATCH="$(mktemp -d -t swipe_l1_gate.XXXXXX)"
# Reached only through the EXIT trap. shellcheck does not follow traps, so it
# reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

nonblank() { grep -c . <<<"$1" || true; }

case "$MODE" in
  machinery) printf 'swipe level 1 channel machinery\n' ;;
  template)  printf 'swipe level 1 corpus, template %s\n' "$TEMPLATE" ;;
  *)         printf 'swipe level 1 ENABLED corpus\n' ;;
esac

# ---------------------------------------------------------------------------
# 1. The files are there.
# ---------------------------------------------------------------------------
for f in "$ITEMS" "$TEMPLATES" "$BAKE" "$RENDER"; do
  if [ -f "$f" ]; then
    ok "present: ${f#"$REPO_ROOT/"}"
  else
    bad "missing: ${f#"$REPO_ROOT/"}"
  fi
done
for f in "$BAKE" "$RENDER"; do
  if [ -x "$f" ]; then
    ok "executable: ${f#"$REPO_ROOT/"}"
  else
    bad "not executable: ${f#"$REPO_ROOT/"}"
  fi
done
if [ ! -f "$ITEMS" ] || [ ! -f "$TEMPLATES" ]; then
  printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
  exit 1
fi

# The rows this run is about. In --template mode every corpus section reads
# this file rather than ITEMS, and the comment header is carried over so the
# structural pass sees exactly the shape it sees in the real table. ITEMS
# itself stays whole, because the controls damage a copy of the real corpus
# and a scoped one would make several of them no-ops.
SCOPED="$SCRATCH/scoped.tsv"
if [ "$MODE" = "template" ]; then
  awk -F'\t' -v t="$TEMPLATE" '$1 != "ITEM" || $3 == t' "$ITEMS" > "$SCOPED"
  if [ "$(awk -F'\t' '$1 == "ITEM"' "$SCOPED" | grep -c . || true)" -eq 0 ]; then
    bad "no item carries template $TEMPLATE, and an empty selection confirms nothing"
    printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
    exit 1
  fi
else
  cp "$ITEMS" "$SCOPED"
fi

# The template ids this run reports on, one per line.
if [ "$MODE" = "template" ]; then
  SEL_TPL="$TEMPLATE"
else
  SEL_TPL="$(awk -F'\t' '$1 == "TPL" { print $2 }' "$TEMPLATES")"
fi

# ---------------------------------------------------------------------------
# 2. The structural half, over a file. Prints a defect count on stdout and the
#    reasons on stderr, so a control can count without reading the prose.
#    Costs no JVM, which is why the strip and the TLC halves are elsewhere.
# ---------------------------------------------------------------------------
structural_defects() {
  local file="$1"
  local defects=0

  if [ ! -f "$file" ]; then printf 'missing\n'; return 0; fi

  local known_templates
  known_templates="$(awk -F'\t' '$1 == "TPL" { printf "|%s|", $2 }' "$TEMPLATES")"

  local seen_ids=""
  local line
  local -a F
  while IFS= read -r line; do
    case "$line" in ITEM*) ;; *) continue ;; esac

    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    if [ "${#F[@]}" -ne 13 ]; then
      printf 'a row carries %s fields and an item row carries 13\n' "${#F[@]}" >&2
      defects=$((defects+1))
      continue
    fi

    local id="${F[1]}"      tpl="${F[2]}"    ask="${F[3]}"
    local kind="${F[4]}"    swipe="${F[5]}"  rc="${F[6]}"
    local states="${F[7]}"  claim="${F[8]}"  vacuity="${F[9]}"
    local flash="${F[10]}"  model="${F[11]}" pin="${F[12]}"

    if [ -z "$id" ]; then
      printf 'a row has no id\n' >&2; defects=$((defects+1)); continue
    fi
    case "$seen_ids" in
      *"|$id|"*) printf '%s: the id appears twice\n' "$id" >&2; defects=$((defects+1)) ;;
      *) seen_ids="$seen_ids|$id|" ;;
    esac
    case "$known_templates" in
      *"|$tpl|"*) ;;
      *) printf '%s: template %s has no TEMPLATES.tsv row\n' "$id" "$tpl" >&2
         defects=$((defects+1)) ;;
    esac

    # The reader-visible tag. It names which question kind the line is and it
    # must not determine the answer, which section 11 is what actually tests.
    case "$ask" in
      enabled|terminal|implies) ;;
      *) printf '%s: ask reads %s and must be enabled, terminal or implies\n' "$id" "$ask" >&2
         defects=$((defects+1)) ;;
    esac

    local want_swipe want_rc
    case "$kind" in
      true)       want_swipe=right; want_rc=0 ;;
      false)      want_swipe=left;  want_rc=12 ;;
      vacuous)    want_swipe=down;  want_rc=0 ;;
      illformed)  want_swipe=down;  want_rc=75 ;;
      wronglevel) want_swipe=down;  want_rc=76 ;;
      unparsed)   want_swipe=down;  want_rc=150 ;;
      *) printf '%s: kind reads %s and the channel names six\n' "$id" "$kind" >&2
         defects=$((defects+1)); continue ;;
    esac
    if [ "$swipe" != "$want_swipe" ]; then
      printf '%s: swipe reads %s and kind %s earns %s\n' "$id" "$swipe" "$kind" "$want_swipe" >&2
      defects=$((defects+1))
    fi
    if ! [[ "$rc" =~ ^[0-9]+$ ]]; then
      printf '%s: the exit code reads %s, so nothing was baked\n' "$id" "$rc" >&2
      defects=$((defects+1))
    elif [ "$rc" != "$want_rc" ]; then
      printf '%s: the baked rc %s and kind %s predicts %s\n' "$id" "$rc" "$kind" "$want_rc" >&2
      defects=$((defects+1))
    fi

    # The pin's state count. A pin is a predicate rather than an assignment,
    # so it may admit several states, and then the question is whether the
    # claim holds at every one of them. That is a legitimate item and a
    # silent one is not, so the count is declared and the bake confirms it.
    if ! [[ "$states" =~ ^[0-9]+$ ]] || [ "$states" -lt 1 ]; then
      printf '%s: pin_states reads %s and must be a count of at least 1\n' "$id" "$states" >&2
      defects=$((defects+1))
    fi

    if [ -z "$model" ] || [ "$model" = "-" ]; then
      printf '%s: no model, and a pinned item is about one\n' "$id" >&2
      defects=$((defects+1))
    fi
    if [ -z "$pin" ] || [ "$pin" = "-" ]; then
      printf '%s: no pin, and that is the whole difference from level 0\n' "$id" >&2
      defects=$((defects+1))
    fi

    # CLAUSE: the item needs its model. A claim that names nothing the model
    # declares is a level 0 claim wearing a model screen, and it belongs in
    # swipe/level0 where it costs one shared JVM instead of two of its own.
    #
    # THREE THINGS COUNT AS NAMING THE MODEL, and the third was missing until
    # bead tla-7xql.13: ENABLED, a declared variable, or a definition the
    # module declares. A wronglevel item is the case that forced it. Its whole
    # point is to write a bare action where a state predicate was meant, so
    # ~(Meet(1, 2) \/ Meet(2, 3)) names no variable and no ENABLED and is as
    # level 1 as anything here. A claim naming a definition the screen
    # WITHHOLDS is caught separately, in section 9, so the two compose.
    #
    # THE MATCH IS WORD-BOUNDED NOW, AND IT WAS A SUBSTRING TEST BEFORE. That
    # is why E1 passed without the definition clause: L1-E1-43's claim is the
    # single word Take, which contains the letter a, and Nim declares a
    # variable called a. The item was accepted for a reason that had nothing
    # to do with it being a level 1 claim.
    case "$claim" in
      *ENABLED*) ;;
      *) local names
         names="$(awk -F'\t' -v m="$model" '($1 == "VARS" || $1 == "DEF") && $2 == m { print $3 }' \
                  "$SCRATCH/vars.tsv" 2>/dev/null || true)"
         local touched=0 v
         while IFS= read -r v; do
           [ -n "$v" ] || continue
           case " $claim " in *[^A-Za-z0-9_]"$v"[^A-Za-z0-9_]*) touched=1 ;; esac
         done <<<"$names"
         if [ "$touched" -eq 0 ]; then
           printf '%s: the claim names no variable, no definition and no ENABLED, so it is level 0\n' "$id" >&2
           defects=$((defects+1))
         fi ;;
    esac

    # The flash is L2 on the epic and it is not optional. A bare verdict sits
    # on the measured floor of feedback effectiveness.
    if [ -z "$flash" ] || [ "$flash" = "-" ]; then
      printf '%s: no flash, and a bare verdict sits on the measured floor\n' "$id" >&2
      defects=$((defects+1))
    elif [ "${#flash}" -lt 20 ]; then
      printf '%s: the flash is %s characters, which is too short to say anything\n' \
        "$id" "${#flash}" >&2
      defects=$((defects+1))
    fi

    if [ "$kind" = "vacuous" ] && [ "$vacuity" = "-" ]; then
      printf '%s: vacuous with no witness, so the label has no TLC run behind it\n' "$id" >&2
      defects=$((defects+1))
    fi
    if [ "$kind" != "vacuous" ] && [ "$vacuity" != "-" ]; then
      printf '%s: kind %s carries a vacuity witness, which only a vacuous item has\n' "$id" "$kind" >&2
      defects=$((defects+1))
    fi
  done <"$file"

  printf '%s\n' "$defects"
}

# The variable and definition names per model, written once so the structural
# half can read them without a parse per row. render.sh resolves the module
# name to a path, which is the lookup that must not be duplicated here.
#
# This is a TEXT scan and not a levels.sh run, on purpose: it costs no JVM and
# it only has to answer whether the module declares the name at all. Which
# names reach the screen is section 7's question and it pays a JVM for it.
: > "$SCRATCH/vars.tsv"
MODELS="$(awk -F'\t' '$1 == "ITEM" { print $12 }' "$SCOPED" | LC_ALL=C sort -u)"
while IFS= read -r m; do
  [ -n "$m" ] || continue
  p="$("$RENDER" --model-path "$m" 2>/dev/null || true)"
  [ -n "$p" ] || continue
  awk -v m="$m" '
    # CONSTANTS too, added 2026-10-18. The premise-leak check below needs the
    # full declared vocabulary, and Key is a CONSTANT of two models while also
    # being a module name, so a scan that knew only variables called it a leak.
    /^CONSTANTS?[ \t]/ {
      line = $0
      sub(/^CONSTANTS?[ \t]+/, "", line)
      n = split(line, c, /[ \t,]+/)
      for (i = 1; i <= n; i++) if (c[i] != "") printf("CONST\t%s\t%s\n", m, c[i])
      next
    }
    /^VARIABLES?[ \t]/ && !seenv {
      seenv = 1
      line = $0
      sub(/^VARIABLES?[ \t]+/, "", line)
      n = split(line, v, /[ \t,]+/)
      for (i = 1; i <= n; i++) if (v[i] != "") printf("VARS\t%s\t%s\n", m, v[i])
      next
    }
    /^[A-Za-z_][A-Za-z0-9_]*[ \t]*(\([^)]*\))?[ \t]*==/ {
      name = $0
      sub(/[ \t]*(\([^)]*\))?[ \t]*==.*$/, "", name)
      printf("DEF\t%s\t%s\n", m, name)
    }' "$p" >> "$SCRATCH/vars.tsv"
done <<<"$MODELS"

N_VARS="$(grep -c '^VARS' "$SCRATCH/vars.tsv" || true)"
N_DEFS="$(grep -c '^DEF' "$SCRATCH/vars.tsv" || true)"
N_MODELS="$(nonblank "$MODELS")"
if [ "$N_VARS" -ge "$N_MODELS" ] && [ "$N_MODELS" -gt 0 ]; then
  ok "$N_MODELS models resolved, $N_VARS variables and $N_DEFS definitions read off their declarations"
else
  bad "$N_MODELS models and $N_VARS variables, so a model did not resolve"
fi

# ---------------------------------------------------------------------------
# 3. The corpus is big enough to carry a base rate.
#
#    32 IS THE FLOOR AND IT IS LEVEL 0'S FLOOR FOR LEVEL 0'S REASON.
#    harness/swipe/stemblind.sh power reads mindetect 0.6190 at n=32 and
#    0.6900 at n=16. Gururangan's premise-blind classifier scored 0.67, so at
#    16 the published finding this gate was copied from sits ABOVE the floor
#    and cannot be called, and at 32 it sits below. This rung ships 48, where
#    mindetect is 0.5705.
# ---------------------------------------------------------------------------
N_ITEMS="$(awk -F'\t' '$1 == "ITEM"' "$SCOPED" | grep -c . || true)"
N_TPL="$(awk -F'\t' '$1 == "TPL"' "$TEMPLATES" | grep -c . || true)"
SMALLEST_TPL="$(awk -F'\t' '$1 == "ITEM" { n[$3]++ } END { m = -1; for (t in n) if (m < 0 || n[t] < m) m = n[t]; print m }' "$SCOPED")"
if want_corpus; then
  if [ "$SMALLEST_TPL" -ge 32 ]; then
    ok "every template in scope carries at least 32 items, the thinnest $SMALLEST_TPL and $N_ITEMS in all"
  else
    bad "the thinnest template carries $SMALLEST_TPL items, under the 32 that makes a 0.67 artifact detectable"
  fi
fi
# THE COUNT IS A FLOOR AND NOT AN EQUALITY, deliberately. Frank sized the rung
# at three on 2026-10-18 and a fourth would be a decision rather than a bug, so
# this asserts that the table is populated and leaves the number to the bead.
if want_machinery; then
  if [ "$N_TPL" -ge 3 ]; then
    ok "$N_TPL templates, which is the full set bead tla-7xql.13 ships"
  else
    bad "$N_TPL template rows, and the rung ships three"
  fi
fi

TPL_DEFECTS=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  n="$(awk -F'\t' -v t="$t" '$1 == "ITEM" && $3 == t' "$ITEMS" | grep -c . || true)"
  if [ "$n" -eq 0 ]; then
    printf '       template %s has no items\n' "$t"; TPL_DEFECTS=$((TPL_DEFECTS+1))
  fi
  idea="$(awk -F'\t' -v t="$t" '$1 == "TPL" && $2 == t {print $4}' "$TEMPLATES")"
  if [ "${#idea}" -lt 40 ]; then
    printf '       template %s states no generating idea\n' "$t"; TPL_DEFECTS=$((TPL_DEFECTS+1))
  fi
done <<<"$SEL_TPL"
if [ "$TPL_DEFECTS" -eq 0 ]; then
  ok "every template in scope carries items and states its generating idea"
else
  bad "$TPL_DEFECTS templates carry no items or state no idea"
fi

# ---------------------------------------------------------------------------
# 4. The structural half over the real corpus.
# ---------------------------------------------------------------------------
REAL_DEFECTS="$(structural_defects "$SCOPED" 2>"$SCRATCH/real.err")"
if want_corpus; then
  if [ "$REAL_DEFECTS" = "0" ]; then
    ok "every item carries a baked verdict, both tags, a pin and a state count"
  else
    bad "$REAL_DEFECTS structural defects"
    sed -n '1,20p' "$SCRATCH/real.err" | sed 's/^/       /'
  fi
fi

# ---------------------------------------------------------------------------
# 5. The mix carries true and false substantively, which is L7 on the epic.
# ---------------------------------------------------------------------------
MIX_DEFECTS=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  read -r n n_right n_left n_down rate <<<"$(awk -F'\t' -v t="$t" '
    $1 == "ITEM" && $3 == t { n++; s[$6]++ }
    END {
      top = 0
      for (k in s) if (s[k] > top) top = s[k]
      printf "%d %d %d %d %.1f", n, s["right"], s["left"], s["down"],
        (n > 0) ? 100 * top / n : 0
    }' "$SCOPED")"
  printf '       %s  %s items  right %s  left %s  down %s  base rate %s%%\n' \
    "$t" "$n" "$n_right" "$n_left" "$n_down" "$rate"
  if [ "$n_right" -lt 3 ] || [ "$n_left" -lt 3 ]; then
    printf '       %s carries %s right and %s left, and L7 wants both substantively\n' \
      "$t" "$n_right" "$n_left"
    MIX_DEFECTS=$((MIX_DEFECTS+1))
  fi
  over="$(awk -v r="$rate" 'BEGIN { print (r > 60) ? "yes" : "no" }')"
  if [ "$over" = "yes" ]; then
    printf '       %s has a base rate of %s%%, so one label carries the template\n' "$t" "$rate"
    MIX_DEFECTS=$((MIX_DEFECTS+1))
  fi
done <<<"$SEL_TPL"
if want_corpus; then
  if [ "$MIX_DEFECTS" -eq 0 ]; then
    ok "every template in scope carries right and left substantively, none above a 60% base rate"
  else
    bad "$MIX_DEFECTS templates carry a degenerate mix"
  fi
fi

# ---------------------------------------------------------------------------
# 6. Structural controls. Each damages one row of a copy and the checker has
#    to reject it. A check that has never rejected anything is not evidence.
#
#    The awk programs sit at the call site rather than behind a helper,
#    because a helper hides them from the linter, which then reads every $1
#    and $9 as a shell expansion that forgot its quotes. No line of this
#    comment may START with the word shellcheck: a continuation line beginning
#    with that word parses as a second directive.
#
#    MACHINERY. These damage a copy of the WHOLE corpus rather than of one
#    template, because several of them target the first matching row and a
#    scoped copy would silently move which row that is.
# ---------------------------------------------------------------------------
CTRL="$SCRATCH/ctrl"
mkdir -p "$CTRL"

if want_machinery; then

awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $6 = "left"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/swipe-flip.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $7 = "12"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-flip.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $7 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-unbaked.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $5 = "maybe"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/kind-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $4 = "reachable"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/ask-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $8 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/states-unset.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $8 = "0"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/states-zero.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $11 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/flash-blank.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $11 = "wrong"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/flash-stub.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $12 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/model-blank.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $13 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/pin-blank.tsv"
# Targets the fifth row and not the first. Rewriting the first row's id to its
# own value is a no-op, and that read as a pass until the control was watched.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $2 == "L1-E1-05" { $2 = "L1-E1-01" } { print }' \
  "$ITEMS" > "$CTRL/duplicate-id.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $3 = "E9"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/template-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { NF = 12; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/field-dropped.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "vacuous" && !d { $10 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-dropped.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $10 = "1 = 1"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-spurious.tsv"
# A level 0 claim in a level 1 table. It needs no model screen, so it costs
# two JVMs of its own where level 0 would batch it with 200 others.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $9 = "1 + 1 = 2"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-level0.tsv"

for c in swipe-flip rc-flip rc-unbaked kind-unknown ask-unknown states-unset \
         states-zero flash-blank flash-stub model-blank pin-blank duplicate-id \
         template-unknown field-dropped witness-dropped witness-spurious \
         claim-level0; do
  d="$(structural_defects "$CTRL/$c.tsv" 2>"$CTRL/$c.err")"
  if [ "$d" != "0" ]; then
    ok "control $c: rejected ($(sed -n '1p' "$CTRL/$c.err"))"
  else
    bad "control $c: accepted, so the check is blind to it"
  fi
done

# The other direction. A checker that rejects everything is not a checker, so
# a claim that names a variable rather than ENABLED has to be ACCEPTED.
# The backslashes are doubled because awk reads a -v value as a string
# literal, so a single \in would arrive as a bare in.
awk -F'\t' -v OFS='\t' -v c='open \\in 0..6' \
  '$1 == "ITEM" && $12 == "Brackets" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/accept-state-predicate.tsv"
d="$(structural_defects "$CTRL/accept-state-predicate.tsv" 2>"$CTRL/accept.err")"
if [ "$d" = "$REAL_DEFECTS" ]; then
  ok "control accept-state-predicate: accepted, so the level 0 check does not over-reject"
else
  bad "control accept-state-predicate: added a defect ($(sed -n '1p' "$CTRL/accept.err"))"
fi

# A claim that names a DEFINITION and nothing else has to be accepted too.
# That is the clause bead tla-7xql.13 added, and without a control on it the
# clause is just a wider hole. ~(Push \/ Pop) names no variable and no
# ENABLED, and it is exactly what a wronglevel item on Overlay looks like.
awk -F'\t' -v OFS='\t' -v c='~(Push \\/ Pop)' \
  '$1 == "ITEM" && $12 == "Overlay" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/accept-definition-only.tsv"
d="$(structural_defects "$CTRL/accept-definition-only.tsv" 2>"$CTRL/accept-def.err")"
if [ "$d" = "$REAL_DEFECTS" ]; then
  ok "control accept-definition-only: accepted, so a bare action still reads as level 1"
else
  bad "control accept-definition-only: added a defect ($(sed -n '1p' "$CTRL/accept-def.err"))"
fi

# And the other end of the same clause. A claim naming a word that is neither
# a variable nor a definition of ITS OWN model must still be rejected, so the
# widening did not turn the check into an allowlist of every identifier.
awk -F'\t' -v OFS='\t' -v c='~(Eliminate \\/ Push)' \
  '$1 == "ITEM" && $12 == "Chameleons" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-foreign-name.tsv"
d="$(structural_defects "$CTRL/claim-foreign-name.tsv" 2>"$CTRL/foreign.err")"
if [ "$d" != "$REAL_DEFECTS" ]; then
  ok "control claim-foreign-name: rejected ($(sed -n '1p' "$CTRL/foreign.err"))"
else
  bad "control claim-foreign-name: accepted, so the definition clause reads another model's names"
fi

fi  # want_machinery, section 6

# ---------------------------------------------------------------------------
# 7. THE TRANSITIVE STRIP, which is the rule rendering one item exposed.
#
#    Decision D2 strips the obligations. Obligations have helpers, and a
#    helper that only an obligation used is dead the moment the obligation
#    goes. Brackets defines Opens and Closes that way and Contention defines
#    Holder. Leaving them puts definitions on a phone screen that no question
#    can be about.
#
#    The property, stated so it cannot go stale: the shown set is CLOSED under
#    use, and every shown definition is reachable from an action. Closed means
#    no shown definition uses a stripped one, which is what makes the screen
#    self-contained. Reachable means nothing is shown that no action needs,
#    which is what makes the strip transitive rather than a list of names.
# ---------------------------------------------------------------------------
#    RENDER IS CALLED ONCE PER MODEL PER QUESTION AND THE ANSWERS ARE CACHED.
#    Each call runs levels.sh, which is a JVM, and the first draft of this
#    file asked the same three questions in four places: 56 JVMs where 21 do.
#    A per-call fork inside a per-item loop is this project's recurring
#    performance defect and harness/drill-gate.sh has produced it twice.
cache_model() {
  local m="$1" p
  p="$("$RENDER" --model-path "$m" 2>/dev/null || true)"
  [ -n "$p" ] || return 1
  printf '%s\n' "$p" > "$SCRATCH/path.$m"
  "$RENDER" --model "$p" --list-shown    2>/dev/null > "$SCRATCH/shown.$m"    || true
  "$RENDER" --model "$p" --list-stripped 2>/dev/null > "$SCRATCH/strip.$m"    || true
  "$RENDER" --model "$p" --screen        2>/dev/null > "$SCRATCH/screen.$m"   || true
  cut -f1 "$SCRATCH/strip.$m" > "$SCRATCH/stripped.$m"
  awk -F'\t' '$2 ~ /obligation/ { print $1 }' "$SCRATCH/strip.$m" > "$SCRATCH/obl.$m"
}

strip_defects() {
  local m="$1" path defects=0
  local shown stripped body
  path="$(cat "$SCRATCH/path.$m")"
  shown="$(cat "$SCRATCH/shown.$m")"
  stripped="$(cat "$SCRATCH/stripped.$m")"

  if [ -z "$shown" ]; then
    printf '%s: nothing shown at all\n' "$path" >&2
    printf '1\n'; return 0
  fi

  # Closed under use: no shown definition may name a stripped one.
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    body="$(awk -v n="$s" '
      $0 ~ "^" n "[ \t]*(\\(|==)" { on = 1; print; next }
      on && /^[ \t]/ { print; next }
      on { exit }
    ' "$path" | sed 's/\\\*.*$//' | sed 's/"[^"]*"/ /g')"
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      case $'\n'"$body"$'\n' in
        *[^A-Za-z0-9_]"$t"[^A-Za-z0-9_]*)
          printf '%s: shown %s uses stripped %s, so the screen is not self-contained\n' \
            "$(basename "$path" .tla)" "$s" "$t" >&2
          defects=$((defects+1)) ;;
      esac
    done <<<"$stripped"
  done <<<"$shown"

  printf '%s\n' "$defects"
}

# WHICH MODELS GET CACHED, AND WHY MACHINERY CACHES ONLY TWO. Each cached
# model costs three levels.sh parses, which is three JVMs. A corpus row pays
# for its own template's models and is the only mode that asserts anything
# about them. The machinery row still needs a cache, because section 9's two
# controls name a model each, so it caches exactly those and nothing else.
if want_corpus; then
  CACHE_MODELS="$MODELS"
else
  CACHE_MODELS="$(printf 'Brackets\nContention\n')"
fi

STRIP_DEFECTS=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  cache_model "$m" || continue
  d="$(strip_defects "$m" 2>"$SCRATCH/err.$m")"
  STRIP_DEFECTS=$((STRIP_DEFECTS + d))
  sh_n="$(grep -c . "$SCRATCH/shown.$m" || true)"
  st_n="$(grep -c . "$SCRATCH/stripped.$m" || true)"
  lines="$(grep -cE '[^[:space:]]' "$SCRATCH/screen.$m" || true)"
  printf '       %-12s shown %-3s stripped %-3s screen %s nonblank lines\n' \
    "$m" "$sh_n" "$st_n" "$lines"
done <<<"$CACHE_MODELS"
if want_corpus; then
  if [ "$STRIP_DEFECTS" -eq 0 ]; then
    ok "every model screen is closed under use: no shown definition names a stripped one"
  else
    bad "$STRIP_DEFECTS shown definitions name a stripped one"
    cat "$SCRATCH"/err.* 2>/dev/null | sed -n '1,10p' | sed 's/^/       /'
  fi
fi

# No obligation, and none of Init, Next or Spec, may be on a screen. That is
# D2 and D7 read off the real corpus rather than off the fixture below. The
# obligation list comes from render.sh's own reason column rather than from a
# second levels.sh run, so the two cannot disagree about what an obligation is.
D27_DEFECTS=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  [ -f "$SCRATCH/shown.$m" ] || continue
  shown="$(cat "$SCRATCH/shown.$m")"
  obl="$(cat "$SCRATCH/obl.$m")"
  while IFS= read -r o; do
    [ -n "$o" ] || continue
    case $'\n'"$shown"$'\n' in
      *$'\n'"$o"$'\n'*)
        printf '       %s shows the obligation %s, which D2 strips\n' "$m" "$o"
        D27_DEFECTS=$((D27_DEFECTS+1)) ;;
    esac
  done <<<"$obl"
  for machine in Init Next Spec; do
    case $'\n'"$shown"$'\n' in
      *$'\n'"$machine"$'\n'*)
        printf '       %s shows %s, which D7 withholds\n' "$m" "$machine"
        D27_DEFECTS=$((D27_DEFECTS+1)) ;;
    esac
  done
done <<<"$CACHE_MODELS"
if want_corpus; then
  if [ "$D27_DEFECTS" -eq 0 ]; then
    ok "no screen shows an obligation, an Init, a Next or a Spec"
  else
    bad "$D27_DEFECTS screens show something D2 or D7 withholds"
  fi
fi

# ---------------------------------------------------------------------------
# 8. The strip, controlled on a fixture, in both directions. MACHINERY.
#
#    A model whose helper only an obligation uses, and a model whose helper an
#    action uses. The first must be stripped and the second kept, and the two
#    differ by one character in the action's body. That is the assertion the
#    FINDING is: the strip is transitive, so a free definition is kept when an
#    action reaches it and dropped when only an obligation did.
# ---------------------------------------------------------------------------
FX="$SCRATCH/fx"
mkdir -p "$FX"

if want_machinery; then

cat > "$FX/StripA.tla" <<'TLA'
---- MODULE StripA ----
EXTENDS Integers

CONSTANT Cap
VARIABLE x
vars == <<x>>

Reach == Cap - 1
Helper == 2 * Cap
Dead == 99

TypeOK == x \in 0..Helper

Init == x = 0
Go == x < Cap /\ x' = x + 1
Next == Go
Spec == Init /\ [][Next]_vars
====
TLA
cat > "$FX/StripA.cfg" <<'CFG'
SPECIFICATION Spec
CONSTANT Cap = 3
INVARIANT TypeOK
CFG

cat > "$FX/StripB.tla" <<'TLA'
---- MODULE StripB ----
EXTENDS Integers

CONSTANT Cap
VARIABLE x
vars == <<x>>

Reach == Cap - 1
Helper == 2 * Cap
Dead == 99

TypeOK == x \in 0..Helper

Init == x = 0
Go == x < Reach /\ x' = x + 1
Next == Go
Spec == Init /\ [][Next]_vars
====
TLA
cat > "$FX/StripB.cfg" <<'CFG'
SPECIFICATION Spec
CONSTANT Cap = 3
INVARIANT TypeOK
CFG

A_SHOWN="$("$RENDER" --model "$FX/StripA.tla" --list-shown 2>/dev/null | tr '\n' ' ')"
B_SHOWN="$("$RENDER" --model "$FX/StripB.tla" --list-shown 2>/dev/null | tr '\n' ' ')"

if [ "$A_SHOWN" = "Go " ]; then
  ok "fixture A shows only the action, so Helper, Reach, Dead and vars are all stripped"
else
  bad "fixture A shows [$A_SHOWN] and the action alone is what it needs"
fi
if [ "$B_SHOWN" = "Go Reach " ]; then
  ok "fixture B keeps Reach, because the action reaches it, while Helper and Dead still go"
else
  bad "fixture B shows [$B_SHOWN] and it needs Go and Reach"
fi
case " $A_SHOWN$B_SHOWN " in
  *" Helper "*) bad "Helper is shown somewhere, and only the stripped TypeOK uses it" ;;
  *) ok "Helper is shown nowhere: an obligation's helper goes with the obligation" ;;
esac
case " $A_SHOWN$B_SHOWN " in
  *" Dead "*) bad "Dead is shown somewhere, and nothing uses it at all" ;;
  *) ok "Dead is shown nowhere: a definition no action reaches is not on the screen" ;;
esac

fi  # want_machinery, section 8

# ---------------------------------------------------------------------------
# 9. A CLAIM MAY ONLY NAME A DEFINITION THE SCREEN SHOWS.
#
#    D7 withholds Init, Next and Spec, so a terminal item asks
#    ~ENABLED (Push \/ Pop) and never ~ENABLED Next. A reader cannot evaluate
#    a name they have not been given, and an item that hands them one is
#    asking a question its own screen cannot answer.
# ---------------------------------------------------------------------------
claim_leaks() {
  local file="$1" leaks=0
  local id claim model line
  local -a F
  while IFS= read -r line; do
    case "$line" in ITEM*) ;; *) continue ;; esac
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    [ "${#F[@]}" -ge 13 ] || continue
    id="${F[1]}"; claim="${F[8]}"; model="${F[11]}"
    local strip
    strip="$(cat "$SCRATCH/stripped.$model" 2>/dev/null || true)"
    [ -n "$strip" ] || continue
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case " $claim " in
        *[^A-Za-z0-9_]"$s"[^A-Za-z0-9_]*)
          printf '%s: the claim names %s, which the screen does not show\n' "$id" "$s" >&2
          leaks=$((leaks+1)) ;;
      esac
    done <<<"$strip"
  done <"$file"
  printf '%s\n' "$leaks"
}

if want_corpus; then
LEAKS="$(claim_leaks "$SCOPED" 2>"$SCRATCH/leak.err")"
if [ "$LEAKS" = "0" ]; then
  ok "no claim names a definition the screen withholds"
else
  bad "$LEAKS claims name a withheld definition"
  sed -n '1,8p' "$SCRATCH/leak.err" | sed 's/^/       /'
fi
fi

# The two controls below name a model each, which is why the machinery run
# caches Brackets and Contention and nothing else. claim_leaks skips a row
# whose model has no cached strip list, so the other rows cost nothing here.
if want_machinery; then

awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $12 == "Brackets" && !d { $9 = "~ENABLED Next"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-names-next.tsv"
n="$(claim_leaks "$CTRL/claim-names-next.tsv" 2>"$CTRL/claim-names-next.err")"
if [ "$n" != "0" ]; then
  ok "control claim-names-next: rejected ($(sed -n '1p' "$CTRL/claim-names-next.err"))"
else
  bad "control claim-names-next: accepted, so a claim may name what D7 withholds"
fi

awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $12 == "Contention" && !d { $9 = "ENABLED TaskDrop"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-names-shown.tsv"
n="$(claim_leaks "$CTRL/claim-names-shown.tsv" 2>/dev/null)"
if [ "$n" = "0" ]; then
  ok "control claim-names-shown: accepted, so the check does not refuse a shown action"
else
  bad "control claim-names-shown: a shown action was read as a leak"
fi

fi  # want_machinery, section 9 controls

# ---------------------------------------------------------------------------
# 10. The TLC half. bake.sh --check confirms every stored verdict against the
#     exit-code channel, and it is the only thing here that decides whether a
#     verdict is right.
#
#     THIS IS WHERE THE ROW'S WALL CLOCK GOES, and it is the reason the run
#     splits. The bake is scoped to the template in --template mode, so each
#     registry row pays for its own 48 items and for nobody else's.
# ---------------------------------------------------------------------------
if want_corpus; then
  BAKE_ARGS=(--check)
  if [ "$MODE" = "template" ]; then BAKE_ARGS+=(--template "$TEMPLATE"); fi
  if out="$("$BAKE" "${BAKE_ARGS[@]}" 2>&1)"; then
    ok "bake.sh --check confirms every stored verdict, every pin's type and every state count"
  else
    bad "bake.sh --check rejected the stored verdicts"
    sed -n '1,20p' <<<"$out" | sed 's/^/       /'
  fi
fi

# ---------------------------------------------------------------------------
# 11. TLC controls, each scoped to ONE item so each costs two or three JVMs.
#
#     Every one keeps fields 4 to 8 self-consistent and damages the claim, the
#     pin or the witness, so the structural half passes and only the TLC half
#     can catch it. A control that reddens the structural half first proves
#     nothing about TLC, which is the trap the bead warns about.
#
#     MACHINERY, and every control names an E1 item. That is deliberate: the
#     controls assert that the CHANNEL decides, not that any one template is
#     right, so pinning them to one template keeps them stable while the
#     corpus grows.
# ---------------------------------------------------------------------------
if want_machinery; then

# A claim labeled true that is in fact false.
awk -F'\t' -v OFS='\t' -v c='open > 99' \
  '$1 == "ITEM" && $2 == "L1-E1-01" { $9 = c } { print }' \
  "$ITEMS" > "$CTRL/tlc-true-is-false.tsv"
# A claim labeled wronglevel that is a perfectly good state predicate.
awk -F'\t' -v OFS='\t' -v c='open > 0' \
  '$1 == "ITEM" && $2 == "L1-E1-04" { $9 = c } { print }' \
  "$ITEMS" > "$CTRL/tlc-wronglevel-is-fine.tsv"
# A claim labeled unparsed that parses.
awk -F'\t' -v OFS='\t' -v c='ENABLED Pop' \
  '$1 == "ITEM" && $2 == "L1-E1-08" { $9 = c } { print }' \
  "$ITEMS" > "$CTRL/tlc-unparsed-parses.tsv"
# A vacuous item whose witness does not hold, so the item is true and not
# vacuous. The first attempt at this control used Len(text) = 3, which is TRUE
# at that pin, so the control passed and proved nothing. A control has to be
# watched failing before it is believed, and this one was not until it ran.
awk -F'\t' -v OFS='\t' -v w='Len(text) = 99' \
  '$1 == "ITEM" && $2 == "L1-E1-03" { $10 = w } { print }' \
  "$ITEMS" > "$CTRL/tlc-witness-false.tsv"
# A pin the model's own type invariant refuses. THIS IS THE TypeOK RULE, and
# the rule is central's rather than Frank's, so the control is what makes it
# a measurement rather than an assertion in a comment.
awk -F'\t' -v OFS='\t' -v p='text = <<"(">> /\\ open = 99' \
  '$1 == "ITEM" && $2 == "L1-E1-09" { $13 = p } { print }' \
  "$ITEMS" > "$CTRL/tlc-pin-untyped.tsv"
# A pin that admits more states than it declares.
awk -F'\t' -v OFS='\t' -v p='text = <<>> /\\ open \\in 0..1' \
  '$1 == "ITEM" && $2 == "L1-E1-05" { $13 = p } { print }' \
  "$ITEMS" > "$CTRL/tlc-pin-multistate.tsv"
# The other direction on the same hazard: a pin that really does admit three
# states, declared as one. Four shipped items pin three on purpose.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $2 == "L1-E1-31" { $8 = "1" } { print }' \
  "$ITEMS" > "$CTRL/tlc-states-understated.tsv"

run_tlc_control() {
  local c="$1" id="$2"
  local pre out
  pre="$(structural_defects "$CTRL/$c.tsv" 2>/dev/null)"
  if [ "$pre" != "$REAL_DEFECTS" ]; then
    bad "control $c: the structural half rejected it first, so it proves nothing about TLC"
    return
  fi
  if out="$("$BAKE" --check --items "$CTRL/$c.tsv" --item "$id" 2>&1)"; then
    bad "control $c: bake.sh --check accepted it, so TLC is not deciding"
  else
    ok "control $c: rejected by TLC ($(sed -n '1p' <<<"$out"))"
  fi
}

run_tlc_control tlc-true-is-false         L1-E1-01
run_tlc_control tlc-wronglevel-is-fine    L1-E1-04
run_tlc_control tlc-unparsed-parses       L1-E1-08
run_tlc_control tlc-witness-false         L1-E1-03
run_tlc_control tlc-pin-untyped           L1-E1-09
run_tlc_control tlc-pin-multistate        L1-E1-05
run_tlc_control tlc-states-understated    L1-E1-31

# The report has to name WHICH half failed. A type-invariant failure reported
# as a state-count failure sends the next author at the wrong half of the item.
out="$("$BAKE" --check --items "$CTRL/tlc-pin-untyped.tsv" --item L1-E1-09 2>&1 || true)"
if grep -q 'type invariant' <<<"$out"; then
  ok "the untyped-pin report names the type invariant rather than the state count"
else
  bad "the untyped-pin report does not say which half of the auxiliary run failed"
fi
out="$("$BAKE" --check --items "$CTRL/tlc-states-understated.tsv" --item L1-E1-31 2>&1 || true)"
if grep -q 'does not admit' <<<"$out"; then
  ok "the understated-count report names the state count rather than the type"
else
  bad "the understated-count report does not say which half of the auxiliary run failed"
fi

# An empty selection confirms nothing, and a --check that exits 0 over no item
# would read as a pass. TLC has the same hole one level up: a .cfg with a bare
# INVARIANT keyword exits 0 having checked nothing.
if "$BAKE" --check --item L1-E1-NOSUCH >/dev/null 2>&1; then
  bad "bake.sh --check over no item at all exited 0, so an empty run reads as a pass"
else
  ok "bake.sh --check refuses a selection that matched no item"
fi

fi  # want_machinery, section 11

# ---------------------------------------------------------------------------
# 12. THE CHANNEL ITSELF, re-measured. Five fixtures, one per row, driven
#     through verdict.sh without going near bake.sh.
#
#     The five numbers are what every stored verdict in the corpus means, so a
#     TLC that renumbers one of them has to turn this red rather than quietly
#     relabel 144 items. That is the same job the \div tripwire does for level
#     0 and the toolchain pin does for the registry. MACHINERY.
# ---------------------------------------------------------------------------
if want_machinery; then

cat > "$FX/Chan.tla" <<'TLA'
---- MODULE Chan ----
EXTENDS Integers

VARIABLE y
vars == <<y>>

Ini == y = 1
Nxt == UNCHANGED vars

Step == y < 3 /\ y' = y + 1

Holds      == y = 1
Refuted    == y = 2
NoDenote   == y \div 0 = 1
WrongLevel == Step
====
TLA
chan_rc() {
  local name="$1" rc=0
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    printf 'INVARIANT %s\n' "$name"
  } > "$FX/Chan.cfg"
  "$VERDICT" -q -c "$FX/Chan.cfg" "$FX/Chan.tla" >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}

check_row() {
  local name="$1" want="$2" why="$3" got
  got="$(chan_rc "$name")"
  if [ "$got" = "$want" ]; then
    ok "channel row $want: $why"
  else
    bad "channel row $want came back rc $got, so every item of that kind is now mislabeled: $why"
  fi
}

check_row Holds      0  "a state predicate that holds at the pin"
check_row Refuted    12 "a state predicate that is false at the pin"
check_row NoDenote   75 "a claim that does not evaluate, reported against the spec"
check_row WrongLevel 76 "an action declared as the invariant, which is not a state predicate"

cat > "$FX/NoParse.tla" <<'TLA'
---- MODULE NoParse ----
EXTENDS Integers

VARIABLE y
vars == <<y>>

Ini == y = 1
Nxt == UNCHANGED vars

Step == y < 3 /\ y' = y + 1

Claim == ENABLED Step = TRUE
====
TLA
{
  printf 'INIT Ini\n'
  printf 'NEXT Nxt\n'
  printf 'INVARIANT Claim\n'
} > "$FX/NoParse.cfg"
rc=0
"$VERDICT" -q -c "$FX/NoParse.cfg" "$FX/NoParse.tla" >/dev/null 2>&1 || rc=$?
if [ "$rc" = "150" ]; then
  ok "channel row 150: SANY still refuses ENABLED Step = TRUE on a precedence conflict"
else
  bad "ENABLED Step = TRUE came back rc $rc rather than 150, so the unparsed items no longer test one"
fi

fi  # want_machinery, section 12

# ---------------------------------------------------------------------------
# 13. Every kind the channel names is shipped, or recorded as unshipped.
#
#     THE VOCABULARY COMES FROM swipe_for() IN bake.sh and not from a list
#     written here. A list written here would allowlist whatever it already
#     knows. A seventh kind added to the bake reddens this until the table and
#     the corpus both catch up.
#
#     MACHINERY, because "shipped" is a statement about the whole corpus. A
#     per-template run would read every kind the OTHER templates carry as
#     unshipped, and the three rungs do not each have to carry all six.
# ---------------------------------------------------------------------------
if want_machinery; then

KIND_DEFECTS=0
BAKE_KINDS="$(awk '
  /^swipe_for\(\) \{/ { inb = 1; next }
  inb && /^\}/        { inb = 0 }
  inb && $1 ~ /\)$/   { k = $1; sub(/\)$/, "", k); if (k != "*") print k }
' "$BAKE" | LC_ALL=C sort)"

table_rows() {
  awk -F'|' -v OFS='\t' -v anchor='<!-- KIND TABLE L1' '
    index($0, anchor) == 1 { seen = 1; next }
    seen == 0 { next }
    NF >= 4 {
      inb = 1
      k = $2; s = $3; r = $4
      gsub(/^[ \t]+/, "", k); gsub(/[ \t]+$/, "", k); gsub(/`/, "", k)
      gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); gsub(/`/, "", s)
      gsub(/^[ \t]+/, "", r); gsub(/[ \t]+$/, "", r)
      if (k == "kind") next
      if (k ~ /^-+$/) next
      print k, s, r
      next
    }
    inb == 1 { exit }
  ' "$README"
}

mapfile -t KIND_ROWS < <(table_rows)
TABLE_KINDS="$(printf '%s\n' "${KIND_ROWS[@]}" | cut -f1 | LC_ALL=C sort)"
if [ "$TABLE_KINDS" = "$BAKE_KINDS" ]; then
  ok "the level 1 channel table names every kind bake.sh can map, and no others"
else
  bad "the level 1 channel table and bake.sh disagree about the kind vocabulary"
  printf '       bake.sh:   %s\n' "$(tr '\n' ' ' <<<"$BAKE_KINDS")"
  printf '       the table: %s\n' "$(tr '\n' ' ' <<<"$TABLE_KINDS")"
fi

for row in "${KIND_ROWS[@]}"; do
  # Parameter expansion rather than `IFS=$'\t' read`: tab is IFS whitespace,
  # so a run of tabs collapses and an empty field vanishes. The separator is
  # written as $'\t' so a later editor cannot retype it as spaces.
  kind="${row%%$'\t'*}"
  rest="${row#*$'\t'}"
  swipe="${rest%%$'\t'*}"
  reason="${rest#*$'\t'}"
  n_kind="$(awk -F'\t' -v k="$kind" '$1 == "ITEM" && $5 == k' "$ITEMS" | grep -c . || true)"
  printf '       %-10s %s swipe, %3s shipped\n' "$kind" "$swipe" "$n_kind"
  if [ "$n_kind" -eq 0 ] && [ "$reason" = "-" ]; then
    printf '       kind %s ships no item and the table records no reason\n' "$kind"
    KIND_DEFECTS=$((KIND_DEFECTS+1))
  elif [ "$n_kind" -eq 0 ] && [ "${#reason}" -lt 24 ]; then
    printf '       kind %s ships no item and its reason is a stub\n' "$kind"
    KIND_DEFECTS=$((KIND_DEFECTS+1))
  elif [ "$n_kind" -gt 0 ] && [ "$reason" != "-" ]; then
    printf '       kind %s ships %s items and the table records it as unshipped\n' "$kind" "$n_kind"
    KIND_DEFECTS=$((KIND_DEFECTS+1))
  fi
  wrong="$(awk -F'\t' -v k="$kind" -v s="$swipe" '$1 == "ITEM" && $5 == k && $6 != s' "$ITEMS" | grep -c . || true)"
  if [ "$wrong" -ne 0 ]; then
    printf '       kind %s earns the %s swipe and %s shipped items read otherwise\n' "$kind" "$swipe" "$wrong"
    KIND_DEFECTS=$((KIND_DEFECTS+1))
  fi
done
if [ "$KIND_DEFECTS" -eq 0 ]; then
  ok "every kind in the level 1 channel table ships an item, or is recorded as unshipped"
else
  bad "$KIND_DEFECTS kinds are neither shipped nor recorded"
fi

fi  # want_machinery, section 13

# ---------------------------------------------------------------------------
# 14. THE STEM-BLIND INSTRUMENT REACHES THIS RUNG.
#
#     A level 1 corpus that no stem-blind gate reads is
#     harness/test-spelling.sh missing scripts/ all over again, and
#     .claude/rules/dispatched-agents.md carries that pattern at four
#     instances. The question it says to ask is which surface the gate does
#     not read, so this section asks it of the stem-blind gate.
#
#     The surface here is the claim AND the pin, which is what varies per
#     item. ENABLED Pop says nothing without the pin under it, and the model
#     is the premise Gururangan's hypothesis-only classifier withholds.
#
#     THE PROBE IS PER TEMPLATE AND ALWAYS WAS, inside stemblind.sh's own awk.
#     What the --template flag changes here is only which templates a row
#     reports on, so the three corpus rows together print the three PROBE
#     lines one unsplit run printed.
# ---------------------------------------------------------------------------
if want_corpus; then

STEMS="$SCRATCH/stems.tsv"
if "$SB" emit --items "$SCOPED" --surface "$SURFACE" --out "$STEMS" 2>"$SCRATCH/emit.err"; then
  ok "stemblind emit writes a stem file for the level 1 corpus"
else
  bad "stemblind emit refused the level 1 corpus: $(cat "$SCRATCH/emit.err")"
fi

n_stems="$(grep -c '^STEM	' "$STEMS" || true)"
if [ "$n_stems" = "$N_ITEMS" ]; then
  ok "one stem per item, $n_stems of them"
else
  bad "$n_stems stems against $N_ITEMS items"
fi

# Three plus the surface width and no more. This forecloses a leaked column
# generically rather than naming the ten withheld fields one at a time.
WANT_W=$(( 3 + $(tr ',' '\n' <<<"$SURFACE" | grep -c .) ))
wrongwidth="$(awk -F'\t' -v w="$WANT_W" '$1 == "STEM" && NF != w { print NR ":" NF }' "$STEMS")"
if [ -z "$wrongwidth" ]; then
  ok "every STEM row carries exactly $WANT_W fields, the marker, the id, the ask and the surface"
else
  bad "STEM rows with the wrong field count: $wrongwidth"
fi

# The pattern reads every template rather than E1, so a fourth one is covered
# the day it lands instead of the day somebody remembers this line.
idleak="$(grep -oE 'L1-E[0-9]+-[0-9]+' "$STEMS" || true)"
if [ -z "$idleak" ]; then
  ok "no item id appears anywhere in the stem file"
else
  bad "item ids leaked into the stem file: $(tr '\n' ' ' <<<"$idleak")"
fi

# The kind, the swipe, the exit code, the state count, the witness, the flash
# and the model are each the answer in a different costume. The statement that
# forecloses all seven at once is that the emitted columns ARE the surface:
# column 4 is field 9 byte for byte and column 5 is field 13.
#
# A SUBSTRING TEST IS THE WRONG INSTRUMENT AT THIS RUNG and the level 0 gate's
# one would be a permanent false red here. L1-E1-44's witness is `a = 0` and
# its pin is `a = 0 /\ b = 0 /\ c = 2`, so the witness text is inside the pin
# and the pin is shown to the reader on purpose. A vacuity witness at level 1
# is a predicate ABOUT the pin, so overlap is the normal case rather than a
# leak. At level 0 the stem was the claim alone and a witness appearing in it
# really was one.
KEY="$SCRATCH/key.tsv"
"$SB" reveal --items "$ITEMS" > "$KEY" 2>/dev/null || true
mismatch=0
while IFS= read -r l; do
  case "$l" in STEM*) ;; *) continue ;; esac
  sid="$(cut -f2 <<<"$l")"
  c_claim="$(cut -f4 <<<"$l")"
  c_pin="$(cut -f5 <<<"$l")"
  iid="$(awk -F'\t' -v s="$sid" '$1 == "KEY" && $2 == s { print $3; exit }' "$KEY")"
  if [ -z "$iid" ]; then
    printf '       stem %s maps to no item\n' "$sid"
    mismatch=$((mismatch+1)); continue
  fi
  want_claim="$(awk -F'\t' -v i="$iid" '$1 == "ITEM" && $2 == i { print $9; exit }' "$ITEMS")"
  want_pin="$(awk -F'\t' -v i="$iid" '$1 == "ITEM" && $2 == i { print $13; exit }' "$ITEMS")"
  if [ "$c_claim" != "$want_claim" ] || [ "$c_pin" != "$want_pin" ]; then
    printf '       stem %s carries something that is neither field 9 nor field 13\n' "$sid"
    mismatch=$((mismatch+1))
  fi
done <"$STEMS"
if [ "$mismatch" -eq 0 ]; then
  ok "every emitted column is exactly field 9 or field 13, so no withheld field reaches a judge"
else
  bad "$mismatch stem rows carry something outside the surface"
fi

# The flash is long free prose, so a coincidence is not the explanation if it
# turns up, and that makes a text search the right instrument for this one.
flashleak=""
while IFS= read -r l; do
  case "$l" in ITEM*) ;; *) continue ;; esac
  fla="$(cut -f11 <<<"$l")"
  if [ -n "$fla" ] && grep -Fq -- "$fla" "$STEMS"; then
    flashleak="$flashleak $(cut -f2 <<<"$l")"
  fi
done <"$ITEMS"
if [ -z "$flashleak" ]; then
  ok "no flash reaches the stem file"
else
  bad "the stem file carries the flash of:$flashleak"
fi

# A MODEL NAME THAT IS ALSO SOMEBODY'S DECLARED IDENTIFIER CANNOT BE SCANNED
# FOR, and this check reported a leak that was not one until 2026-10-18.
#
# The corpus holds reading/state-space/04-key/Key.tla, so Key is a module
# name. It is ALSO a CONSTANT declared by Overlay.tla and by Ledger.tla, and
# seven E2 and E3 items quantify over it: \A k \in Key : ~ENABLED Hit(k).
# A fixed-string scan for "Key" matches that and calls it a premise leak.
#
# It is not one. A level 1 claim cannot be written without naming its own
# model's vocabulary, so an identifier appearing in a stem is necessary rather
# than gratuitous. Key.tla declares CONSTANT Staff and no constant of its own
# name, so nothing about Key.tla reaches a judge here.
#
# So the scan skips a model name that any corpus model DECLARES, and PRINTS
# the names it skipped. A silent exclusion is how this check would stop
# covering the one thing it is for.
declared_ids="$(awk -F'\t' '{ print $3 }' "$SCRATCH/vars.tsv" | LC_ALL=C sort -u)"
modelleak=""
modelskip=""
while IFS= read -r m; do
  [ -n "$m" ] || continue
  if grep -qx -- "$m" <<<"$declared_ids"; then
    modelskip="$modelskip $m"
    continue
  fi
  if grep -Fq -- "$m" "$STEMS"; then modelleak="$modelleak $m"; fi
done <<<"$MODELS"
if [ -z "$modelleak" ]; then
  ok "no model name reaches the stem file, so the premise really is withheld"
else
  bad "the stem file names the model, which is the premise:$modelleak"
fi
if [ -n "$modelskip" ]; then
  printf '  NOTE  not scanned, the name is a declared identifier of some model:%s\n' "$modelskip"
fi

# The probe itself. It runs on every full gate, which is what makes this a
# gate rather than an advisory script somebody has to remember to dispatch.
if out="$("$SB" probe --items "$ITEMS" --surface "$SURFACE" 2>&1)"; then
  # First line taken by parameter expansion rather than by a pipe into head.
  # A producer piped into an early-exiting consumer returns 141 under
  # pipefail, and harness/test-pipefail.sh bans the idiom across this tree.
  probe_line="$(grep '^PROBE	' <<<"$out" || true)"
  ok "the stem-blind probe finds no surface artifact: ${probe_line%%$'\n'*}"
else
  bad "the stem-blind probe flagged the level 1 corpus"
  sed -n '1,6p' <<<"$out" | sed 's/^/       /'
fi

# WATCH IT FAIL. Plant a token on the pin of every false item and the probe
# has to call it. A probe that has never flagged anything is not evidence that
# the corpus is clean, it is evidence that nothing was measured.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "false" { $13 = $13 " /\\ zzmarker = 1" } { print }' \
  "$ITEMS" > "$CTRL/planted.tsv"
if "$SB" probe --items "$CTRL/planted.tsv" --surface "$SURFACE" >"$CTRL/planted.out" 2>&1; then
  bad "control planted: the probe missed a token planted on every false item"
  sed -n '1,4p' "$CTRL/planted.out" | sed 's/^/       /'
else
  planted_feat="$(grep -o 'feature=[^	]*' "$CTRL/planted.out" || true)"
  ok "control planted: the probe calls a token on every false item (${planted_feat%%$'\n'*})"
fi

# AND WATCH THE SURFACE MATTER. The same plant sits in field 13, so a probe
# run at the level 0 default surface of field 9 alone cannot see it. That is
# the whole argument for --surface being a list, measured rather than argued.
if "$SB" probe --items "$CTRL/planted.tsv" >/dev/null 2>&1; then
  ok "the same plant is invisible at the default surface, so --surface is what reaches the pin"
else
  bad "the default surface flagged a plant that only sits in field 13"
fi

fi  # want_corpus, section 14

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
