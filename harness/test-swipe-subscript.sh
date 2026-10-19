#!/usr/bin/env bash
# Gate for the level 2 subscript swipe corpus (bead tla-7xql.5, epic
# tla-7xql).
#
# THE INVARIANT, in the bead's own words plus what pinning a step added: every
# shipped level 2 item has a TLC-computed verdict, a pin that is exactly one
# type-correct step, a claim that names nothing the model screen withholds,
# and a subscript that does not on its own predict the answer.
#
# The clauses are checked separately and reported separately, because they
# fail for different reasons and because three of them cost JVMs while the
# rest do not.
#
# WHAT RUNS TLC AND WHAT DOES NOT. The structural half is text and costs no
# JVM. swipe/level2/bake.sh --check costs 65 JVMs over the 48 items: 48 for
# the claims, 13 for the distinct pinned steps, and 4 for the vacuity
# witnesses. The TLC controls are scoped to one item each. Section 11
# re-measures the five rows of the channel on five one-line fixtures.
#
# THE PIN CHECK IS WHERE THIS RUNG IS CHEAPER THAN LEVEL 1, and it is the only
# place it is. Level 1 pays two runs per item because every item carries its
# own pin. Here the items are authored in groups that share one pinned step
# and vary only the claim, so the pin check is keyed on the step and 48 items
# cost 13 of them. A run is the only authority on the number and this
# paragraph is a description rather than a check.
#
# Lineage: bead tla-7xql.5.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITEMS="$REPO_ROOT/swipe/level2/ITEMS.tsv"
TEMPLATES="$REPO_ROOT/swipe/level2/TEMPLATES.tsv"
BAKE="$REPO_ROOT/swipe/level2/bake.sh"
RENDER="$REPO_ROOT/swipe/level2/render.sh"
L1RENDER="$REPO_ROOT/swipe/level1/render.sh"
VERDICT="$REPO_ROOT/harness/verdict.sh"
SB="$REPO_ROOT/harness/swipe/stemblind.sh"
README="$REPO_ROOT/swipe/README.md"

# The surface the stem-blind instrument reads at this rung: the claim, the two
# halves of the pinned step, and the pin's own constants. That is everything
# the reader is shown per item. The MODEL is the premise and is withheld, the
# same way level 1 withholds it, and section 13 says why both halves of the
# step belong here.
SURFACE="9,13,14,15"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

SCRATCH="$(mktemp -d -t swipe_l2_gate.XXXXXX)"
# Reached only through the EXIT trap. shellcheck does not follow traps, so it
# reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

printf 'swipe level 2 subscript corpus\n'

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
    if [ "${#F[@]}" -ne 15 ]; then
      printf 'a row carries %s fields and an item row carries 15\n' "${#F[@]}" >&2
      defects=$((defects+1))
      continue
    fi

    local id="${F[1]}"      tpl="${F[2]}"    ask="${F[3]}"
    local kind="${F[4]}"    swipe="${F[5]}"  rc="${F[6]}"
    local states="${F[7]}"  claim="${F[8]}"  vacuity="${F[9]}"
    local flash="${F[10]}"  model="${F[11]}" pre="${F[12]}"
    local post="${F[13]}"   binds="${F[14]}"

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
    # must not determine the answer, which section 13 is what actually tests.
    case "$ask" in
      step|always) ;;
      *) printf '%s: ask reads %s and must be step or always\n' "$id" "$ask" >&2
         defects=$((defects+1)) ;;
    esac

    local want_swipe want_rcs
    case "$kind" in
      true)       want_swipe=right; want_rcs="0" ;;
      false)      want_swipe=left;  want_rcs="12 13" ;;
      vacuous)    want_swipe=down;  want_rcs="0" ;;
      illformed)  want_swipe=down;  want_rcs="75" ;;
      unparsed)   want_swipe=down;  want_rcs="150" ;;
      wronglevel) want_swipe=down;  want_rcs="151" ;;
      *) printf '%s: kind reads %s and the channel names six\n' "$id" "$kind" >&2
         defects=$((defects+1)); continue ;;
    esac
    if [ "$swipe" != "$want_swipe" ]; then
      printf '%s: swipe reads %s and kind %s earns %s\n' "$id" "$swipe" "$kind" "$want_swipe" >&2
      defects=$((defects+1))
    fi
    # Membership rather than equality, because hazard H1 on the epic says
    # {12, 13} is ONE answer and a generator may never predict which. Both
    # codes are shipped in this corpus, so the set is load-bearing here and
    # not a precaution: 15 refuted items read 13 and 3 read 12.
    local hit=0 c
    for c in $want_rcs; do [ "$rc" = "$c" ] && hit=1; done
    if [ "$hit" -eq 0 ]; then
      printf '%s: rc reads %s and kind %s allows %s\n' "$id" "$rc" "$kind" "$want_rcs" >&2
      defects=$((defects+1))
    fi

    # A pinned step is one initial state and one successor. Hazard H3 on the
    # epic is exactly the statement that it had better be, and the bake's
    # postcondition is what measures it.
    if [ "$states" != "2" ]; then
      printf '%s: field 8 reads %s and a pinned step is always 2 states\n' "$id" "$states" >&2
      defects=$((defects+1))
    fi

    if [ -z "$claim" ] || [ "$claim" = "-" ]; then
      printf '%s: the claim is blank\n' "$id" >&2; defects=$((defects+1))
    fi

    # THE CLAIM GRAMMAR, AND IT IS A CORRECTNESS RULE RATHER THAN A STYLE ONE.
    # A pinned behavior carries no fairness, so the behavior that stutters at
    # the pre-state forever is admitted and every liveness claim is refuted
    # whatever it says. Measured: []<>(next = 1) reads 13 on a step that does
    # set next to 1, and WF_vars(Take(P1)) reads 13 on a step that takes it.
    # An item built on one of those is false for a reason the pin never had an
    # opinion about, which is hazard H2's shape one rung along.
    case "$claim" in
      *'<>'*)  printf '%s: the claim uses <>, and a pin with no fairness refutes every liveness claim\n' "$id" >&2
               defects=$((defects+1)) ;;
    esac
    case "$claim" in
      *'WF_'*|*'SF_'*)
        printf '%s: the claim names a fairness operator, which a pinned behavior cannot satisfy\n' "$id" >&2
        defects=$((defects+1)) ;;
    esac
    case "$claim" in
      *'~>'*) printf '%s: the claim uses ~>, which is liveness under another name\n' "$id" >&2
              defects=$((defects+1)) ;;
    esac
    # Bead tla-7n7e. TLC 2026.07.31.184830 breaks the contract its own
    # Naturals.tla states for a negative dividend, and \div 0 inside a step
    # formula reads rc 255 rather than the 75 every other evaluation failure
    # here reads, so it is not even a usable illformed item.
    case "$claim$pre$post" in
      *'\div'*) printf '%s: the item uses \\div, which bead tla-7n7e is open on\n' "$id" >&2
                defects=$((defects+1)) ;;
    esac

    # The ask and the claim have to agree about what is being asked. always
    # means a box over a state predicate, which carries no subscript, and step
    # means a formula over a step, which carries one. Neither tells the reader
    # the answer: both asks ship right, left and down items.
    local has_sub=0
    case "$claim" in *']_'*|*'>>_'*) has_sub=1 ;; esac
    if [ "$ask" = "always" ] && [ "$has_sub" -eq 1 ]; then
      printf '%s: ask reads always and the claim carries a subscript\n' "$id" >&2
      defects=$((defects+1))
    fi
    if [ "$ask" = "step" ] && [ "$has_sub" -eq 0 ]; then
      printf '%s: ask reads step and the claim carries no subscript\n' "$id" >&2
      defects=$((defects+1))
    fi

    # THE VACUITY WITNESS IS NOT FREE FORM AT THIS RUNG. A claim [][A]_v is
    # vacuous exactly when v does not move, so the witness replaces the action
    # with FALSE and keeps the subscript, which is the textbook vacuity test.
    # Fixing the shape here is what stops the label being an author's word.
    if [ "$kind" = "vacuous" ]; then
      if [ "$vacuity" = "-" ] || [ -z "$vacuity" ]; then
        printf '%s: a vacuous item needs a witness\n' "$id" >&2
        defects=$((defects+1))
      else
        local sub want_wit
        sub="${claim##*\]_}"
        want_wit="[][FALSE]_$sub"
        if [ "$vacuity" != "$want_wit" ]; then
          printf '%s: the witness reads %s and the claim subscript wants %s\n' \
            "$id" "$vacuity" "$want_wit" >&2
          defects=$((defects+1))
        fi
      fi
    elif [ "$vacuity" != "-" ]; then
      printf '%s: kind %s carries a vacuity witness, which only a vacuous item has\n' "$id" "$kind" >&2
      defects=$((defects+1))
    fi

    # L2 on the epic. A falsehood is reproduced later at .19 with no feedback,
    # .15 with a bare verdict and .04 with the verdict plus the correction.
    if [ -z "$flash" ] || [ "$flash" = "-" ]; then
      printf '%s: the flash is blank\n' "$id" >&2; defects=$((defects+1))
    elif [ "${#flash}" -lt 40 ]; then
      printf '%s: the flash is a stub at %s characters\n' "$id" "${#flash}" >&2
      defects=$((defects+1))
    fi

    if [ -z "$model" ] || [ "$model" = "-" ]; then
      printf '%s: the item names no model\n' "$id" >&2; defects=$((defects+1))
    fi

    # The two halves of the step. A pre-state is a state predicate and must
    # carry no prime, and a post is a step formula and must carry one.
    if [ -z "$pre" ] || [ "$pre" = "-" ]; then
      printf '%s: the pin has no pre-state\n' "$id" >&2; defects=$((defects+1))
    else
      case "$pre" in *"'"*) printf '%s: the pre-state carries a prime, so it is not a state predicate\n' "$id" >&2
                            defects=$((defects+1)) ;; esac
    fi
    if [ -z "$post" ] || [ "$post" = "-" ]; then
      printf '%s: the pin has no post, so no step is pinned at all\n' "$id" >&2
      defects=$((defects+1))
    else
      case "$post" in
        *"'"*|*UNCHANGED*) ;;
        *) printf '%s: the post carries neither a prime nor UNCHANGED, so it says nothing about a step\n' "$id" >&2
           defects=$((defects+1)) ;;
      esac
    fi

    # Field 15. A dash, or assignments a .cfg can take.
    if [ "$binds" != "-" ]; then
      local b
      while IFS= read -r b; do
        [ -n "$b" ] || continue
        case "$b" in
          *=*) ;;
          *) printf '%s: bind %s is not an assignment\n' "$id" "$b" >&2
             defects=$((defects+1)) ;;
        esac
      done < <(printf '%s\n' "$binds" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
  done <"$file"

  printf '%s\n' "$defects"
}

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
N_ITEMS="$(awk -F'\t' '$1 == "ITEM"' "$ITEMS" | grep -c . || true)"
N_TPL="$(awk -F'\t' '$1 == "TPL"' "$TEMPLATES" | grep -c . || true)"
SMALLEST_TPL="$(awk -F'\t' '$1 == "ITEM" { n[$3]++ } END { m = -1; for (t in n) if (m < 0 || n[t] < m) m = n[t]; print m }' "$ITEMS")"
if [ "$SMALLEST_TPL" -ge 32 ]; then
  ok "every template carries at least 32 items, the thinnest $SMALLEST_TPL and $N_ITEMS in all"
else
  bad "the thinnest template carries $SMALLEST_TPL items, under the 32 that makes a 0.67 artifact detectable"
fi
if [ "$N_TPL" -ge 1 ]; then
  ok "$N_TPL template, which is the pilot bead tla-7xql.5 scopes"
else
  bad "no template row at all"
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
done < <(awk -F'\t' '$1 == "TPL" {print $2}' "$TEMPLATES")
if [ "$TPL_DEFECTS" -eq 0 ]; then
  ok "every template carries items and states its generating idea"
else
  bad "$TPL_DEFECTS templates carry no items or state no idea"
fi

# ---------------------------------------------------------------------------
# 4. The structural half over the real corpus.
# ---------------------------------------------------------------------------
REAL_DEFECTS="$(structural_defects "$ITEMS" 2>"$SCRATCH/real.err")"
if [ "$REAL_DEFECTS" = "0" ]; then
  ok "every item carries a baked verdict, both tags, a one-step pin and a witness it is entitled to"
else
  bad "$REAL_DEFECTS structural defects"
  sed -n '1,20p' "$SCRATCH/real.err" | sed 's/^/       /'
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
    }' "$ITEMS")"
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
done < <(awk -F'\t' '$1 == "TPL" {print $2}' "$TEMPLATES")
if [ "$MIX_DEFECTS" -eq 0 ]; then
  ok "every template carries right and left substantively, none above a 60% base rate"
else
  bad "$MIX_DEFECTS templates carry a degenerate mix"
fi

# ---------------------------------------------------------------------------
# 6. Structural controls. Each damages one row of a copy and the checker has
#    to reject it. A check that has never rejected anything is not evidence.
#
#    The awk programs sit at the call site rather than behind a helper,
#    because a helper hides them from the linter, which then reads every
#    positional as a shell expansion that forgot its quotes. No line of this
#    comment may START with the word shellcheck: a continuation line beginning
#    with that word parses as a second directive.
# ---------------------------------------------------------------------------
CTRL="$SCRATCH/ctrl"
mkdir -p "$CTRL"

awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $6 = "left"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/swipe-flip.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $7 = "12"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-flip.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $7 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-unbaked.tsv"
# The other half of hazard H1. 11 is a real TLC code and it is not one the
# refuted kind may wear, so the SET has to be a set and not a wildcard.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "false" && !d { $7 = "11"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-outside-set.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $5 = "maybe"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/kind-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $4 = "reachable"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/ask-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $4 == "step" && !d { $4 = "always"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/ask-mismatched.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $8 = "1"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/states-one.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $11 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/flash-blank.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $11 = "wrong"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/flash-stub.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $12 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/model-blank.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $13 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/pre-blank.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $14 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/post-blank.tsv"
# A post with no prime and no UNCHANGED pins no step at all, which is the
# level 1 item shape wearing a level 2 row.
awk -F'\t' -v OFS='\t' -v p='next = 0' \
  '$1 == "ITEM" && !d { $14 = p; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/post-not-a-step.tsv"
# A pre with a prime is a step rather than a state, so it is the same mistake
# from the other end.
awk -F'\t' -v OFS='\t' -v p="next' = 0" \
  '$1 == "ITEM" && !d { $13 = p; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/pre-primed.tsv"
# Targets the fifth row and not the first. Rewriting the first row's id to its
# own value is a no-op, and that read as a pass until the control was watched.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $2 == "L2-S1-05" { $2 = "L2-S1-01" } { print }' \
  "$ITEMS" > "$CTRL/duplicate-id.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $3 = "S9"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/template-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { NF = 14; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/field-dropped.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "vacuous" && !d { $10 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-dropped.tsv"
# A witness that is a perfectly good formula and is not the subscript test.
awk -F'\t' -v OFS='\t' -v w='[][FALSE]_vars' \
  '$1 == "ITEM" && $5 == "vacuous" && !d { $10 = w; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-wrong-subscript.tsv"
awk -F'\t' -v OFS='\t' -v w='[][FALSE]_vars' \
  '$1 == "ITEM" && $5 == "true" && !d { $10 = w; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-spurious.tsv"
# The claim grammar. Each of these is a claim a careful author would write and
# each one is false for a reason the pin never had an opinion about.
awk -F'\t' -v OFS='\t' -v c='[]<>(next = 1)' \
  '$1 == "ITEM" && !d { $9 = c; $4 = "always"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-eventually.tsv"
awk -F'\t' -v OFS='\t' -v c='WF_vars(Take(P1))' \
  '$1 == "ITEM" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-fairness.tsv"
awk -F'\t' -v OFS='\t' -v c='[][next \\div 0 = 1]_vars' \
  '$1 == "ITEM" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-div.tsv"

for c in swipe-flip rc-flip rc-unbaked rc-outside-set kind-unknown ask-unknown \
         ask-mismatched states-one flash-blank flash-stub model-blank \
         pre-blank post-blank post-not-a-step pre-primed duplicate-id \
         template-unknown field-dropped witness-dropped \
         witness-wrong-subscript witness-spurious claim-eventually \
         claim-fairness claim-div; do
  d="$(structural_defects "$CTRL/$c.tsv" 2>"$CTRL/$c.err")"
  if [ "$d" != "0" ]; then
    ok "control $c: rejected ($(sed -n '1p' "$CTRL/$c.err"))"
  else
    bad "control $c: accepted, so the check is blind to it"
  fi
done

# The other direction. A checker that rejects everything is not a checker, so
# a claim with a narrow but perfectly ordinary subscript has to be ACCEPTED.
# The backslashes are doubled because awk reads a -v value as a string
# literal, so a single backslash would be eaten before awk saw it.
awk -F'\t' -v OFS='\t' -v c='[][Take(P1)]_<<next>>' \
  '$1 == "ITEM" && $12 == "Tickets" && $5 == "true" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/accept-narrow.tsv"
d="$(structural_defects "$CTRL/accept-narrow.tsv" 2>"$CTRL/accept.err")"
if [ "$d" = "$REAL_DEFECTS" ]; then
  ok "control accept-narrow: accepted, so the grammar check does not over-reject"
else
  bad "control accept-narrow: added a defect ($(sed -n '1p' "$CTRL/accept.err"))"
fi

# ---------------------------------------------------------------------------
# 7. THE STATE TUPLE IS ON THE SCREEN, AND THE LEVEL 1 STRIP TAKES IT OFF.
#
#    The level 1 kept set is every level 2 definition except Next and the
#    SPECIFICATION formula, plus their transitive closure. `vars` is a state
#    function, so it is never a root, and an action reaches it only when the
#    action happens to name the tuple. None of this rung's models does.
#
#    That is right at level 1, where no claim can name `vars`. At level 2 the
#    subscript is the subject matter and `vars` is what 906 of 1,182 published
#    sites write, which is 77 percent and is measured in
#    .claude/rules/tla-practice.md section 2. So the kept set here is level
#    1's plus `vars`, and the two halves below are the measurement that the
#    difference is real rather than assumed.
# ---------------------------------------------------------------------------
MODELS="$(awk -F'\t' '$1 == "ITEM" { print $12 }' "$ITEMS" | LC_ALL=C sort -u)"
VARS_DEFECTS=0
VARS_L1_HAD=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  p="$("$L1RENDER" --model-path "$m")"
  "$L1RENDER" --model "$p" --list-stripped > "$SCRATCH/stripped.$m" 2>/dev/null || true
  "$RENDER" --model "$p" --list-shown > "$SCRATCH/shown2.$m" 2>/dev/null || true
  "$L1RENDER" --model "$p" --list-shown > "$SCRATCH/shown1.$m" 2>/dev/null || true
  if grep -qx 'vars' "$SCRATCH/shown2.$m"; then :; else
    printf '       %s: the level 2 screen does not show vars\n' "$m"
    VARS_DEFECTS=$((VARS_DEFECTS+1))
  fi
  if grep -qx 'vars' "$SCRATCH/shown1.$m"; then
    VARS_L1_HAD=$((VARS_L1_HAD+1))
  fi
  n2="$(grep -c . "$SCRATCH/shown2.$m" || true)"
  n1="$(grep -c . "$SCRATCH/shown1.$m" || true)"
  if [ "$n2" -ne $((n1 + 1)) ]; then
    printf '       %s: the level 2 kept set is %s against level 1 %s, and vars is the only difference there should be\n' \
      "$m" "$n2" "$n1"
    VARS_DEFECTS=$((VARS_DEFECTS+1))
  fi
done <<<"$MODELS"
if [ "$VARS_DEFECTS" -eq 0 ]; then
  ok "every model's level 2 screen shows vars and is otherwise level 1's kept set"
else
  bad "$VARS_DEFECTS models disagree about the state tuple"
fi
if [ "$VARS_L1_HAD" -eq 0 ]; then
  ok "level 1 shows vars on none of these models, so the addition is doing work rather than agreeing"
else
  skip "level 1 already shows vars on $VARS_L1_HAD of these models"
fi

# The screen is the thing the phone has to hold, so its size is worth a number
# rather than a belief. The predicate is '[^[:space:]]' and NOT '.': the
# screen is indented and its block separators are spaces and nothing else, so
# `grep -c .` counts every separator as content and reads about four lines
# high per model.
SCREEN_MIN=9999
SCREEN_MAX=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  p="$("$L1RENDER" --model-path "$m")"
  n="$("$RENDER" --model "$p" --screen 2>/dev/null | grep -c '[^[:space:]]' || true)"
  [ -n "$n" ] || n=0
  printf '       %-12s %s lines\n' "$m" "$n"
  [ "$n" -lt "$SCREEN_MIN" ] && SCREEN_MIN="$n"
  [ "$n" -gt "$SCREEN_MAX" ] && SCREEN_MAX="$n"
done <<<"$MODELS"
if [ "$SCREEN_MIN" -ge 1 ]; then
  ok "every model screen carries something, $SCREEN_MIN lines at the shortest and $SCREEN_MAX at the longest"
else
  bad "a model screen is empty, so the item shows the reader nothing to answer from"
fi

# ---------------------------------------------------------------------------
# 8. A CLAIM MAY ONLY NAME A DEFINITION THE SCREEN SHOWS.
#
#    D7 withholds Init, Next and Spec. A reader cannot evaluate a name they
#    have not been given, and an item that hands them one is asking a question
#    its own screen cannot answer. `vars` is removed from the stripped list
#    here for the reason section 7 measures.
# ---------------------------------------------------------------------------
claim_leaks() {
  local file="$1" leaks=0
  local id claim model line
  local -a F
  while IFS= read -r line; do
    case "$line" in ITEM*) ;; *) continue ;; esac
    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    [ "${#F[@]}" -ge 15 ] || continue
    id="${F[1]}"; claim="${F[8]}"; model="${F[11]}"
    local strip
    strip="$(awk -F'\t' '$1 != "vars" { print $1 }' "$SCRATCH/stripped.$model" 2>/dev/null || true)"
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

LEAKS="$(claim_leaks "$ITEMS" 2>"$SCRATCH/leak.err")"
if [ "$LEAKS" = "0" ]; then
  ok "no claim names a definition the screen withholds"
else
  bad "$LEAKS claims name a withheld definition"
  sed -n '1,8p' "$SCRATCH/leak.err" | sed 's/^/       /'
fi

awk -F'\t' -v OFS='\t' -v c='[][Next]_vars' \
  '$1 == "ITEM" && $12 == "Tickets" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-names-next.tsv"
n="$(claim_leaks "$CTRL/claim-names-next.tsv" 2>"$CTRL/claim-names-next.err")"
if [ "$n" != "0" ]; then
  ok "control claim-names-next: rejected ($(sed -n '1p' "$CTRL/claim-names-next.err"))"
else
  bad "control claim-names-next: accepted, so a claim may name what D7 withholds"
fi

awk -F'\t' -v OFS='\t' -v c='[][Leave(P1)]_vars' \
  '$1 == "ITEM" && $12 == "Tickets" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-names-shown.tsv"
n="$(claim_leaks "$CTRL/claim-names-shown.tsv" 2>/dev/null)"
if [ "$n" = "0" ]; then
  ok "control claim-names-shown: accepted, so vars and a shown action are not read as leaks"
else
  bad "control claim-names-shown: a shown name was read as a leak"
fi

# ---------------------------------------------------------------------------
# 9. The TLC half. bake.sh --check confirms every stored verdict against the
#    exit-code channel, and it is the only thing here that decides whether a
#    verdict is right.
# ---------------------------------------------------------------------------
if out="$("$BAKE" --check 2>&1)"; then
  ok "bake.sh --check confirms every stored verdict and every pinned step"
  printf '       %s\n' "$(grep '^checked' <<<"$out" || true)"
else
  bad "bake.sh --check rejected the stored verdicts"
  sed -n '1,20p' <<<"$out" | sed 's/^/       /'
fi

# ---------------------------------------------------------------------------
# 10. TLC controls, each scoped to ONE item so each costs two or three JVMs.
#
#     Every one keeps fields 4 to 8 self-consistent and damages the claim, the
#     pin or the witness, so the structural half passes and only the TLC half
#     can catch it. A control that reddens the structural half first proves
#     nothing about TLC, which is the trap the bead warns about.
# ---------------------------------------------------------------------------
# A claim labeled true that is in fact false.
awk -F'\t' -v OFS='\t' -v c='[][Leave(P1)]_vars' \
  '$1 == "ITEM" && $2 == "L2-S1-01" { $9 = c } { print }' \
  "$ITEMS" > "$CTRL/tlc-true-is-false.tsv"
# A claim labeled wronglevel that is a perfectly good step formula. This is
# the dropped box put back, so it is the bead's own lesson run backwards.
awk -F'\t' -v OFS='\t' -v c='[][Take(P1)]_vars' \
  '$1 == "ITEM" && $2 == "L2-S1-04" { $9 = c } { print }' \
  "$ITEMS" > "$CTRL/tlc-wronglevel-is-fine.tsv"
# A claim labeled unparsed that parses. It has to stay consistent with the
# item's own ask, which reads always here, so the replacement is a box over a
# state predicate and not [][Take]_vars: that one carries a subscript, and the
# structural half rejected it before TLC was reached. A control that reddens
# the structural half first proves nothing, and this one did until it ran.
awk -F'\t' -v OFS='\t' -v c='[](a <= 7)' \
  '$1 == "ITEM" && $2 == "L2-S1-12" { $9 = c } { print }' \
  "$ITEMS" > "$CTRL/tlc-unparsed-parses.tsv"
# THE CONTROL THIS BEAD EXISTS FOR. A vacuous item is vacuous because its
# subscript does not move, so moving the subscript to one that DOES makes the
# same action over the same step a plain refutation. The witness moves with
# the claim, so the structural half stays green and only TLC can call it.
awk -F'\t' -v OFS='\t' -v c='[][Leave(P1)]_<<ticket>>' -v w='[][FALSE]_<<ticket>>' \
  '$1 == "ITEM" && $2 == "L2-S1-03" { $9 = c; $10 = w } { print }' \
  "$ITEMS" > "$CTRL/tlc-vacuous-moves.tsv"
# A pin a model's own type invariant refuses.
awk -F'\t' -v OFS='\t' -v p='owner = "zz" /\\ served = FALSE' \
  '$1 == "ITEM" && $2 == "L2-S1-23" { $13 = p } { print }' \
  "$ITEMS" > "$CTRL/tlc-pin-untyped.tsv"
# HAZARD H3, MEASURED RATHER THAN NOTED. A post that admits two successors
# pins a SET of behaviors, and TLC finds the member that refutes you.
awk -F'\t' -v OFS='\t' -v p="owner' \\\\in {\"poller\", \"task\"} /\\\\ UNCHANGED served" \
  '$1 == "ITEM" && $2 == "L2-S1-23" { $14 = p } { print }' \
  "$ITEMS" > "$CTRL/tlc-pin-branches.tsv"
# The same hazard from the other end: a pre that admits two states.
awk -F'\t' -v OFS='\t' -v p='owner = "none" /\\ served \\in BOOLEAN' \
  '$1 == "ITEM" && $2 == "L2-S1-23" { $13 = p } { print }' \
  "$ITEMS" > "$CTRL/tlc-pin-multistate.tsv"
# A bind the .cfg cannot make sense of, which is how a model value gets named
# wrong rather than not at all.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $2 == "L2-S1-01" { $15 = "P1 = zz" } { print }' \
  "$ITEMS" > "$CTRL/tlc-bind-wrong.tsv"

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

run_tlc_control tlc-true-is-false       L2-S1-01
run_tlc_control tlc-wronglevel-is-fine  L2-S1-04
run_tlc_control tlc-unparsed-parses     L2-S1-12
run_tlc_control tlc-vacuous-moves       L2-S1-03
run_tlc_control tlc-pin-untyped         L2-S1-23
run_tlc_control tlc-pin-branches        L2-S1-23
run_tlc_control tlc-pin-multistate      L2-S1-23
run_tlc_control tlc-bind-wrong          L2-S1-01

# The report has to name WHICH half failed. A type failure reported as a step
# count failure sends the next author at the wrong half of the item.
out="$("$BAKE" --check --items "$CTRL/tlc-pin-untyped.tsv" --item L2-S1-23 2>&1 || true)"
if grep -q 'type invariant' <<<"$out"; then
  ok "the untyped-pin report names the type invariant rather than the step count"
else
  bad "the untyped-pin report does not say which half of the auxiliary run failed"
fi
out="$("$BAKE" --check --items "$CTRL/tlc-pin-branches.tsv" --item L2-S1-23 2>&1 || true)"
if grep -q 'not one step' <<<"$out"; then
  ok "the branching-pin report names the step count rather than the type"
else
  bad "the branching-pin report does not say which half of the auxiliary run failed"
fi

# An empty selection confirms nothing, and a --check that exits 0 over no item
# would read as a pass. TLC has the same hole one level up: a .cfg with a bare
# PROPERTY keyword exits 0 having checked nothing.
if "$BAKE" --check --item L2-S1-NOSUCH >/dev/null 2>&1; then
  bad "bake.sh --check over no item at all exited 0, so an empty run reads as a pass"
else
  ok "bake.sh --check refuses a selection that matched no item"
fi

# ---------------------------------------------------------------------------
# 11. THE CHANNEL ITSELF, re-measured. Five fixtures, one per row, driven
#     through verdict.sh without going near bake.sh.
#
#     The five numbers are what every stored verdict in the corpus means, so a
#     TLC that renumbers one of them has to turn this red rather than quietly
#     relabel 48 items. That is the same job the \div tripwire does for level
#     0 and the toolchain pin does for the registry.
#
#     TWO OF THESE ARE NOT LEVEL 1'S. 151 is the row level 1 says does not
#     appear at all, and it is this rung's own lesson. 150 is a different
#     message from level 1's precedence conflict: SANY says "[] followed by
#     action not of form [A]_v", which is the subscript's own parse rule.
# ---------------------------------------------------------------------------
FX="$SCRATCH/fx"
mkdir -p "$FX"

cat > "$FX/Chan.tla" <<'TLA'
---- MODULE Chan ----
EXTENDS Integers

VARIABLE y
vars == <<y>>

Pre  == y = 1
Post == y' = 2

Ini == Pre
Nxt == IF Pre THEN Post ELSE UNCHANGED vars

Step       == y' = y + 1
Holds      == [][Step]_vars
Refuted    == [][y' = y + 9]_vars
NoDenote   == [][y' = CHOOSE k \in {} : TRUE]_vars
WrongLevel == [Step]_vars
====
TLA

chan_rc() {
  local name="$1" rc=0
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    printf 'PROPERTY %s\n' "$name"
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

check_row Holds      0   "a step formula that holds across the pinned step"
check_row NoDenote   75  "a step formula that does not evaluate"
check_row WrongLevel 151 "an action declared under PROPERTY, which is not a temporal formula"

# The refuted row is a PAIR and hazard H1 says never to predict which. So the
# fixture asserts membership, which is the same thing the bake does.
rc="$(chan_rc Refuted)"
if [ "$rc" = "12" ] || [ "$rc" = "13" ]; then
  ok "channel row {12, 13}: a refuted step formula reads rc $rc, inside the pair H1 names"
else
  bad "a refuted step formula came back rc $rc, outside the {12, 13} pair every left item rests on"
fi

cat > "$FX/NoParse.tla" <<'TLA'
---- MODULE NoParse ----
EXTENDS Integers

VARIABLE y
vars == <<y>>

Pre  == y = 1
Post == y' = 2

Ini == Pre
Nxt == IF Pre THEN Post ELSE UNCHANGED vars

Step  == y' = y + 1
Claim == []Step
====
TLA
{
  printf 'INIT Ini\n'
  printf 'NEXT Nxt\n'
  printf 'PROPERTY Claim\n'
} > "$FX/NoParse.cfg"
rc=0
"$VERDICT" -q -c "$FX/NoParse.cfg" "$FX/NoParse.tla" >/dev/null 2>&1 || rc=$?
if [ "$rc" = "150" ]; then
  ok "channel row 150: SANY still refuses a box in front of a bare action"
else
  bad "a box over a bare action came back rc $rc rather than 150, so the unparsed items no longer test one"
fi

# AND THE ONE MEASUREMENT THE WHOLE TEMPLATE RESTS ON. A subscript that does
# not move satisfies the claim whatever the action says, and a subscript that
# does move puts the action on the hook. Two runs on one fixture, one action,
# two subscripts, opposite answers.
cat > "$FX/Sub.tla" <<'TLA'
---- MODULE Sub ----
EXTENDS Integers

VARIABLES y, z
vars == <<y, z>>

Pre  == y = 1 /\ z = 1
Post == y' = 2 /\ UNCHANGED z

Ini == Pre
Nxt == IF Pre THEN Post ELSE UNCHANGED vars

Wrong    == y' = y + 9
Stutters == [][Wrong]_<<z>>
Tested   == [][Wrong]_<<y>>
Witness  == [][FALSE]_<<z>>
====
TLA
sub_rc() {
  local name="$1" rc=0
  {
    printf 'INIT Ini\n'
    printf 'NEXT Nxt\n'
    printf 'PROPERTY %s\n' "$name"
  } > "$FX/Sub.cfg"
  "$VERDICT" -q -c "$FX/Sub.cfg" "$FX/Sub.tla" >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}
rc_stutter="$(sub_rc Stutters)"
rc_tested="$(sub_rc Tested)"
rc_witness="$(sub_rc Witness)"
if [ "$rc_stutter" = "0" ] && { [ "$rc_tested" = "12" ] || [ "$rc_tested" = "13" ]; }; then
  ok "the same false action reads rc $rc_stutter under a stuttering subscript and rc $rc_tested under a moving one"
else
  bad "the subscript no longer decides the answer: stuttering read $rc_stutter and moving read $rc_tested"
fi
if [ "$rc_witness" = "0" ]; then
  ok "the vacuity witness [][FALSE]_v reads 0 on exactly the subscript that stutters"
else
  bad "the vacuity witness read rc $rc_witness on a stuttering subscript, so the vacuous label rests on nothing"
fi

# ---------------------------------------------------------------------------
# 12. Every kind the channel names is shipped, or recorded as unshipped.
#
#     THE VOCABULARY COMES FROM swipe_for() IN bake.sh and not from a list
#     written here. A list written here would allowlist whatever it already
#     knows. A seventh kind added to the bake reddens this until the table and
#     the corpus both catch up.
# ---------------------------------------------------------------------------
KIND_DEFECTS=0
BAKE_KINDS="$(awk '
  /^swipe_for\(\) \{/ { inb = 1; next }
  inb && /^\}/        { inb = 0 }
  inb && $1 ~ /\)$/   { k = $1; sub(/\)$/, "", k); if (k != "*") print k }
' "$BAKE" | LC_ALL=C sort)"

table_rows() {
  awk -F'|' -v OFS='\t' -v anchor='<!-- KIND TABLE L2' '
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
  ok "the level 2 channel table names every kind bake.sh can map, and no others"
else
  bad "the level 2 channel table and bake.sh disagree about the kind vocabulary"
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
  ok "every kind in the level 2 channel table ships an item, or is recorded as unshipped"
else
  bad "$KIND_DEFECTS kinds are neither shipped nor recorded"
fi

# ---------------------------------------------------------------------------
# 13. THE STEM-BLIND INSTRUMENT REACHES THIS RUNG, AND IT MATTERS MORE HERE.
#
#     Four items share one pinned step and differ only in the subscript. If
#     the subscript alone predicted the label the corpus would measure
#     nothing, so the probe runs twice: once over the whole surface, and once
#     over a derived table where the claim has been cut down to its subscript
#     and nothing else.
#
#     THE SURFACE IS THE CLAIM, BOTH HALVES OF THE STEP, AND THE BINDS.
#     Level 1's surface is the claim and the pin, and this rung's pin is two
#     states rather than one. Both halves belong, because the question is
#     whether the action describes THAT step and a judge handed only the
#     pre-state has been handed half a question. The binds belong for the same
#     reason: a reader shown holder' = H2 without being shown H2 = s2 has a
#     name they cannot evaluate. The MODEL is the premise and stays withheld,
#     which is Gururangan's hypothesis-only classifier.
# ---------------------------------------------------------------------------
STEMS="$SCRATCH/stems.tsv"
if "$SB" emit --items "$ITEMS" --surface "$SURFACE" --out "$STEMS" 2>"$SCRATCH/emit.err"; then
  ok "stemblind emit writes a stem file for the level 2 corpus"
else
  bad "stemblind emit refused the level 2 corpus: $(cat "$SCRATCH/emit.err")"
fi

n_stems="$(grep -c '^STEM	' "$STEMS" || true)"
if [ "$n_stems" = "$N_ITEMS" ]; then
  ok "one stem per item, $n_stems of them"
else
  bad "$n_stems stems against $N_ITEMS items"
fi

# Three plus the surface width and no more. This forecloses a leaked column
# generically rather than naming the withheld fields one at a time.
WANT_W=$(( 3 + $(tr ',' '\n' <<<"$SURFACE" | grep -c .) ))
wrongwidth="$(awk -F'\t' -v w="$WANT_W" '$1 == "STEM" && NF != w { print NR ":" NF }' "$STEMS")"
if [ -z "$wrongwidth" ]; then
  ok "every STEM row carries exactly $WANT_W fields, the marker, the id, the ask and the surface"
else
  bad "STEM rows with the wrong field count: $wrongwidth"
fi

idleak="$(grep -oE 'L2-S1-[0-9]+' "$STEMS" || true)"
if [ -z "$idleak" ]; then
  ok "no item id appears anywhere in the stem file"
else
  bad "item ids leaked into the stem file: $(tr '\n' ' ' <<<"$idleak")"
fi

# The kind, the swipe, the exit code, the step count, the witness and the
# model are each the answer in a different costume. The statement that
# forecloses all of them at once is that the emitted columns ARE the surface,
# byte for byte.
KEY="$SCRATCH/key.tsv"
"$SB" reveal --items "$ITEMS" > "$KEY" 2>/dev/null || true
mismatch=0
while IFS= read -r l; do
  case "$l" in STEM*) ;; *) continue ;; esac
  sid="$(cut -f2 <<<"$l")"
  c_claim="$(cut -f4 <<<"$l")"
  c_pre="$(cut -f5 <<<"$l")"
  c_post="$(cut -f6 <<<"$l")"
  c_binds="$(cut -f7 <<<"$l")"
  iid="$(awk -F'\t' -v s="$sid" '$1 == "KEY" && $2 == s { print $3; exit }' "$KEY")"
  if [ -z "$iid" ]; then
    printf '       stem %s maps to no item\n' "$sid"
    mismatch=$((mismatch+1)); continue
  fi
  want_claim="$(awk -F'\t' -v i="$iid" '$1 == "ITEM" && $2 == i { print $9; exit }' "$ITEMS")"
  want_pre="$(awk -F'\t' -v i="$iid" '$1 == "ITEM" && $2 == i { print $13; exit }' "$ITEMS")"
  want_post="$(awk -F'\t' -v i="$iid" '$1 == "ITEM" && $2 == i { print $14; exit }' "$ITEMS")"
  want_binds="$(awk -F'\t' -v i="$iid" '$1 == "ITEM" && $2 == i { print $15; exit }' "$ITEMS")"
  if [ "$c_claim" != "$want_claim" ] || [ "$c_pre" != "$want_pre" ] ||
     [ "$c_post" != "$want_post" ] || [ "$c_binds" != "$want_binds" ]; then
    printf '       stem %s carries something outside fields 9, 13, 14 and 15\n' "$sid"
    mismatch=$((mismatch+1))
  fi
done <"$STEMS"
if [ "$mismatch" -eq 0 ]; then
  ok "every emitted column is exactly field 9, 13, 14 or 15, so no withheld field reaches a judge"
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

modelleak=""
while IFS= read -r m; do
  [ -n "$m" ] || continue
  if grep -Fq -- "$m" "$STEMS"; then modelleak="$modelleak $m"; fi
done <<<"$MODELS"
if [ -z "$modelleak" ]; then
  ok "no model name reaches the stem file, so the premise really is withheld"
else
  bad "the stem file names the model, which is the premise:$modelleak"
fi

# The probe itself. It runs on every full gate, which is what makes this a
# gate rather than an advisory script somebody has to remember to dispatch.
if out="$("$SB" probe --items "$ITEMS" --surface "$SURFACE" 2>&1)"; then
  probe_line="$(grep '^PROBE	' <<<"$out" || true)"
  ok "the stem-blind probe finds no surface artifact: ${probe_line%%$'\n'*}"
else
  bad "the stem-blind probe flagged the level 2 corpus"
  sed -n '1,6p' <<<"$out" | sed 's/^/       /'
fi

# THE SUBSCRIPT-ALONE CONTROL, which is this rung's own question rather than a
# borrowed one. Cut every claim down to its subscript and ask the probe
# whether that alone beats the base rate. If it does, four items on one step
# are four copies of one item and the template measures nothing.
#
# The cut takes the text after the LAST ]_ or >>_, so a claim carrying a
# function application inside its subscript keeps the whole subscript and a
# claim built from angle brackets is attributed to its subscript rather than
# to nothing.
SUBCUT='
  function subscript_of(c,   s) {
    s = c
    if (s ~ /\]_|>>_/) { sub(/^.*(\]_|>>_)/, "", s); return s }
    return "NOSUBSCRIPT"
  }'
awk -F'\t' -v OFS='\t' "$SUBCUT"'
  $1 != "ITEM" { print; next }
  { $9 = subscript_of($9); print }' "$ITEMS" > "$CTRL/subscript-only.tsv"
if out="$("$SB" probe --items "$CTRL/subscript-only.tsv" --surface 9 2>&1)"; then
  probe_line="$(grep '^PROBE	' <<<"$out" || true)"
  ok "the subscript alone carries no artifact: ${probe_line%%$'\n'*}"
else
  bad "THE SUBSCRIPT ALONE PREDICTS THE LABEL, so the items on one step are not four questions"
  sed -n '1,6p' <<<"$out" | sed 's/^/       /'
fi

# WATCH IT FAIL. Plant a token on the pre-state of every false item and the
# probe has to call it. A probe that has never flagged anything is not
# evidence that the corpus is clean, it is evidence that nothing was measured.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "false" { $13 = $13 " /\\ zzmarker = 1" } { print }' \
  "$ITEMS" > "$CTRL/planted.tsv"
if "$SB" probe --items "$CTRL/planted.tsv" --surface "$SURFACE" >"$CTRL/planted.out" 2>&1; then
  bad "control planted: the probe missed a token planted on every false item"
  sed -n '1,4p' "$CTRL/planted.out" | sed 's/^/       /'
else
  planted_feat="$(grep -o 'feature=[^	]*' "$CTRL/planted.out" || true)"
  ok "control planted: the probe calls a token on every false item (${planted_feat%%$'\n'*})"
fi

# AND WATCH THE SUBSCRIPT CONTROL FAIL TOO, which is the half that would
# otherwise be a formality. Give every refuted item a subscript nothing else
# uses and the subscript alone becomes a perfect rule for the left swipe.
#
# THE PLANT IS ON 18 ITEMS AND THE FIRST VERSION PUT IT ON 4. Four vacuous
# items with a subscript nothing else used came back clear at p=0.9950,
# because the probe is scored by leave-one-out accuracy over the whole
# template and a rule covering 4 of 48 moves that number by almost nothing
# however pure it is. Section 14 is the instrument for a tell that small, and
# this one is sized so the probe really is what calls it.
awk -F'\t' -v OFS='\t' "$SUBCUT"'
  $1 != "ITEM" { print; next }
  {
    s = subscript_of($9)
    if ($5 == "false") s = "<<zzmoved>>"
    $9 = s
    print
  }' "$ITEMS" > "$CTRL/subscript-tell.tsv"
if "$SB" probe --items "$CTRL/subscript-tell.tsv" --surface 9 >"$CTRL/subtell.out" 2>&1; then
  bad "control subscript-tell: a subscript used by the refuted items and nothing else went uncalled"
  sed -n '1,4p' "$CTRL/subtell.out" | sed 's/^/       /'
else
  tell_feat="$(grep -o 'feature=[^	]*' "$CTRL/subtell.out" || true)"
  ok "control subscript-tell: a subscript-only tell is called (${tell_feat%%$'\n'*})"
fi

# AND WATCH THE SURFACE MATTER. The plant sits in field 13, so a probe run at
# the level 0 default surface of field 9 alone cannot see it. That is the
# argument for --surface being a list, measured rather than argued.
if "$SB" probe --items "$CTRL/planted.tsv" >/dev/null 2>&1; then
  ok "the same plant is invisible at the default surface, so --surface is what reaches the pin"
else
  bad "the default surface flagged a plant that only sits in field 13"
fi

# ---------------------------------------------------------------------------
# 14. SUBSCRIPT PURITY, which is the question the probe is the wrong
#     instrument for.
#
#     THE PROBE MISSED A PLANT AND THAT IS NOT A BUG IN IT. The first version
#     of the control above gave the four vacuous items a subscript nothing
#     else used, a perfectly pure rule for the down swipe, and the probe came
#     back clear at p=0.9950. It is scored by leave-one-out accuracy over the
#     whole template, so a rule covering 4 of 48 items moves the number by
#     almost nothing however pure it is. harness/swipe/stemblind.sh says so in
#     its own header, where it separates "could a judge beat the base rate"
#     from "does this template have a tell". This is that paragraph arriving
#     as a measurement rather than as advice.
#
#     So purity gets its own check, which is text and costs nothing. The floor
#     is THREE items. At two a pure subscript is a matched pair built from one
#     idea, which is how this corpus is authored, and <<ticket>> really is two
#     refuted items and nothing else. At three it is a rule a reader can
#     learn. Measured over the shipped corpus: every subscript on three or
#     more items carries two or three different swipes.
# ---------------------------------------------------------------------------
PURITY_FLOOR=3

subscript_purity() {
  local file="$1"
  awk -F'\t' -v floor="$PURITY_FLOOR" "$SUBCUT"'
    $1 != "ITEM" { next }
    {
      s = subscript_of($9)
      n[s]++
      if (!((s SUBSEP $6) in seen)) { seen[s SUBSEP $6] = 1; k[s]++ }
      only[s] = $6
    }
    END {
      nbad = 0
      for (s in n) {
        if (n[s] >= floor && k[s] == 1) {
          printf("the subscript %s carries %d items and every one of them swipes %s\n",
                 s, n[s], only[s]) > "/dev/stderr"
          nbad++
        }
      }
      print nbad
    }' "$file"
}

PURE="$(subscript_purity "$ITEMS" 2>"$SCRATCH/pure.err")"
if [ "$PURE" = "0" ]; then
  ok "no subscript on $PURITY_FLOOR or more items is pure in one swipe"
else
  bad "$PURE subscripts predict the swipe on their own"
  sed -n '1,6p' "$SCRATCH/pure.err" | sed 's/^/       /'
fi

# The 4-item plant the probe could not see. This is what the check is for.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "vacuous" { $9 = "[][FALSE]_<<zzstutter>>" } { print }' \
  "$ITEMS" > "$CTRL/purity-tell.tsv"
n="$(subscript_purity "$CTRL/purity-tell.tsv" 2>"$CTRL/purity.err")"
if [ "$n" != "0" ]; then
  ok "control purity-tell: a 4-item pure subscript is called ($(sed -n '1p' "$CTRL/purity.err"))"
else
  bad "control purity-tell: a subscript used by the vacuous items and nothing else went uncalled"
fi

# And the same plant through the probe, so the two instruments are measured
# against each other rather than assumed to differ.
if "$SB" probe --items "$CTRL/purity-tell.tsv" --surface 9 >/dev/null 2>&1; then
  ok "the probe reads that same 4-item plant as clear, which is why section 14 exists"
else
  skip "the probe now calls a 4-item plant, so section 14 may be redundant"
fi

# The other direction, so the floor is not simply zero. Two refuted items
# already share <<ticket>> in the shipped corpus and that has to stay legal.
n="$(awk -F'\t' "$SUBCUT"'
  $1 != "ITEM" { next }
  { s = subscript_of($9); n[s]++; if (!((s SUBSEP $6) in seen)) { seen[s SUBSEP $6] = 1; k[s]++ } }
  END { c = 0; for (s in n) if (n[s] == 2 && k[s] == 1) c++; print c }' "$ITEMS")"
if [ "$n" -ge 1 ]; then
  ok "$n subscript pair is pure at two items and allowed, so the floor is doing work from below"
else
  skip "no subscript is pure even at two items, so the floor is untested from below"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
