#!/usr/bin/env bash
# Gate for the level 0 swipe corpus (bead tla-7xql.2, epic tla-7xql).
#
# THE INVARIANT, in the bead's own words: every shipped level 0 item has a
# TLC-computed verdict, a declared kind tag, and no reference to any variable
# or primed expression.
#
# The three clauses are checked separately and reported separately, because
# they fail for different reasons. The third one gets two independent checks:
# a text scan over the claim, and the TLC run itself. A level 0 batch module
# declares no VARIABLES and no CONSTANTS, so a claim naming a variable is a
# free identifier and SANY refuses the module at rc 150. Measured: a prime in
# an ASSUME comes back PARSE_ERROR on this build. So the text scan is the fast
# half and TLC is the sound half, and the controls below redden each one.
#
# WHAT RUNS TLC AND WHAT DOES NOT. The structural half is text and costs no
# JVM. swipe/level0/bake.sh --check costs 33 JVMs over the 240 items, because
# the claims batch: 3 batch modules plus one run for each of the 30 items that
# do not evaluate. The four TLC controls are scoped to one template, 9 JVMs
# each. Section 10 adds 11 over a three-row fixture. So the suite starts about
# 90 JVMs rather than one per item.
#
# That count tracks the ill-formed total and not the item total, so it moves
# whenever the corpus grows and a run is the only authority on it. This
# paragraph read 13 and 33 until 2026-10-18, both measured at 80 items, and it
# outlived the corpus by two beads.
#
# Lineage: beads tla-7xql.2 and tla-7xql.10.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITEMS="$REPO_ROOT/swipe/level0/ITEMS.tsv"
TEMPLATES="$REPO_ROOT/swipe/level0/TEMPLATES.tsv"
BAKE="$REPO_ROOT/swipe/level0/bake.sh"
VERDICT="$REPO_ROOT/harness/verdict.sh"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

SCRATCH="$(mktemp -d -t swipe_gate.XXXXXX)"
# Reached only through the EXIT trap. shellcheck does not follow traps, so it
# reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# The identifier allowlist, and why it is written out rather than derived.
#
# A level 0 claim may name the operators the batch module's EXTENDS brings in,
# the TLA+ builtins, and nothing else. Deriving the list from the corpus would
# allowlist whatever is already there, including a planted variable, so the
# list is the standard-module export set and it is maintained by hand.
#
# A name bound inside the claim is fine and is collected separately: anything
# before \in, anything before |->, anything after a dot, and anything between
# LAMBDA and its colon.
# ---------------------------------------------------------------------------
ALLOWED='Nat Int Cardinality IsFiniteSet Seq Len Head Tail Append SubSeq
SelectSeq Print PrintT Assert Permutations SortSeq JavaTime Any
SUBSET UNION DOMAIN EXCEPT TRUE FALSE BOOLEAN STRING LAMBDA CHOOSE
IF THEN ELSE LET IN CASE OTHER'

# Prints one line per free identifier found in the claim on stdin.
free_identifiers() {
  awk -v allowed="$ALLOWED" '
    BEGIN {
      n = split(allowed, a, /[ \n]+/)
      for (i = 1; i <= n; i++) if (a[i] != "") ok[a[i]] = 1
    }
    {
      line = $0
      # Strip string literals, so "a" is never read as an identifier.
      gsub(/"[^"]*"/, " ", line)

      # Collect the bound names first, while \in is still there to find.
      bound_src = line
      while (match(bound_src, /[A-Za-z_][A-Za-z0-9_]*[ ]*(\\in|\|->)/)) {
        tok = substr(bound_src, RSTART, RLENGTH)
        sub(/[ ]*(\\in|\|->)$/, "", tok)
        bound[tok] = 1
        bound_src = substr(bound_src, RSTART + RLENGTH)
      }
      # A RECORD-SET FORMER BINDS ITS FIELD NAMES TOO, and missing this
      # over-rejected three legal T3 claims (bead tla-7xql.7). In [a : S, b : T]
      # the names left of each colon are FIELD names, not free identifiers, and
      # the scan already knew the record-CONSTRUCTOR form [a |-> 1] through the
      # |-> clause above. TLC proves these are legal rather than it being a
      # judgment call: the generated modules declare no CONSTANT and no
      # VARIABLE, so a genuinely free identifier makes SANY refuse at rc 150,
      # and all three baked at 0 or 10.
      # The colon alone is ambiguous, since it also ends a quantifier bound and
      # a LAMBDA parameter list. The discriminator is what precedes the name: a
      # field name sits directly after [ or after a comma. \A r \in [a : {}] :
      # r.a = 1 carries both forms and only the first one binds here.
      bound_src = line
      while (match(bound_src, /(\[|,)[ ]*[A-Za-z_][A-Za-z0-9_]*[ ]*:/)) {
        tok = substr(bound_src, RSTART, RLENGTH)
        sub(/^(\[|,)[ ]*/, "", tok)
        sub(/[ ]*:$/, "", tok)
        bound[tok] = 1
        bound_src = substr(bound_src, RSTART + RLENGTH)
      }

      # A comma list shares one \in, as in \E p, q \in S.
      bound_src = line
      while (match(bound_src, /[A-Za-z_][A-Za-z0-9_]*[ ]*,/)) {
        tok = substr(bound_src, RSTART, RLENGTH)
        sub(/[ ]*,$/, "", tok)
        comma[tok] = 1
        bound_src = substr(bound_src, RSTART + RLENGTH)
      }
      bound_src = line
      while (match(bound_src, /\.[A-Za-z_][A-Za-z0-9_]*/)) {
        tok = substr(bound_src, RSTART + 1, RLENGTH - 1)
        bound[tok] = 1
        bound_src = substr(bound_src, RSTART + RLENGTH)
      }
      bound_src = line
      while (match(bound_src, /LAMBDA[ ]+[A-Za-z_][A-Za-z0-9_, ]*:/)) {
        tok = substr(bound_src, RSTART, RLENGTH)
        sub(/^LAMBDA[ ]+/, "", tok)
        sub(/[ ]*:$/, "", tok)
        m = split(tok, l, /[ ,]+/)
        for (i = 1; i <= m; i++) if (l[i] != "") bound[l[i]] = 1
        bound_src = substr(bound_src, RSTART + RLENGTH)
      }

      # Now drop the backslash operators, and only now. \cup, \in, \subseteq,
      # \X, \div, \o and \A are operators, not names, and a tokenizer that
      # runs before this step reads "cup" and "in" as free identifiers. It
      # did, on 20 of 80 claims, which is how this line got written.
      scan = line
      gsub(/\\[A-Za-z]+/, " ", scan)

      # Then report every identifier that is neither allowed nor bound. A
      # comma-listed name only counts as bound when some name in the claim is
      # bound by a \in, which is what makes \E p, q \in S work without letting
      # a bare comma launder a variable.
      src = scan
      while (match(src, /[A-Za-z_][A-Za-z0-9_]*/)) {
        tok = substr(src, RSTART, RLENGTH)
        if (!(tok in ok) && !(tok in bound)) {
          if ((tok in comma) && length(bound) > 0) {
            # bound through a shared \in
          } else {
            print tok
          }
        }
        src = substr(src, RSTART + RLENGTH)
      }
    }'
}

# ---------------------------------------------------------------------------
# The structural checker. Prints a defect count on stdout and the reasons on
# stderr, so a control can count without reading the prose. Runs over a
# here-string rather than a pipe: a pipeline into an early-exiting consumer
# returns 141 under pipefail and reads as a pass.
# ---------------------------------------------------------------------------
structural_defects() {
  local file="$1"
  local defects=0

  if [ ! -f "$file" ]; then
    printf 'missing\n'
    return 0
  fi

  local known_templates
  known_templates="$(awk -F'\t' '$1 == "TPL" { printf "|%s|", $2 }' "$TEMPLATES")"

  local seen_ids=""
  local line
  local -a F
  while IFS= read -r line; do
    case "$line" in
      ITEM*) ;;
      *) continue ;;
    esac

    mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$line")
    if [ "${#F[@]}" -ne 11 ]; then
      printf 'a row carries %s fields and an item row carries 11\n' "${#F[@]}" >&2
      defects=$((defects+1))
      continue
    fi

    local id="${F[1]}"    tpl="${F[2]}"   ask="${F[3]}"
    local kind="${F[4]}"  swipe="${F[5]}" rc_claim="${F[6]}"
    local rc_wf="${F[7]}" claim="${F[8]}" vacuity="${F[9]}"
    local correction="${F[10]}"

    if [ -z "$id" ]; then
      printf 'a row has no id\n' >&2
      defects=$((defects+1))
      continue
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

    # CLAUSE 2 of the invariant: a declared kind tag. Both tags, because field
    # 4 is what the reader is shown and field 5 is what the data keeps.
    case "$ask" in
      holds|implies) ;;
      *) printf '%s: ask reads %s and must be holds or implies\n' "$id" "$ask" >&2
         defects=$((defects+1)) ;;
    esac
    local want_swipe want_rc want_wf
    # Unparsed is the row bead tla-7xql.10 added, and it is the only kind whose
    # pair the other three cannot reach. SANY refuses the module at 150 before
    # either probe is evaluated, so both members move together.
    case "$kind" in
      true)      want_swipe=right; want_rc=0;   want_wf=0 ;;
      false)     want_swipe=left;  want_rc=10;  want_wf=0 ;;
      vacuous)   want_swipe=down;  want_rc=0;   want_wf=0 ;;
      illformed) want_swipe=down;  want_rc=10;  want_wf=10 ;;
      unparsed)  want_swipe=down;  want_rc=150; want_wf=150 ;;
      *) printf '%s: kind reads %s and must be true, false, vacuous, illformed or unparsed\n' \
           "$id" "$kind" >&2
         defects=$((defects+1))
         continue ;;
    esac
    if [ "$swipe" != "$want_swipe" ]; then
      printf '%s: swipe reads %s and kind %s earns %s\n' \
        "$id" "$swipe" "$kind" "$want_swipe" >&2
      defects=$((defects+1))
    fi

    # CLAUSE 1 of the invariant: a TLC-computed verdict. The pair must be
    # numbers that bake.sh wrote, never the - a hand-authored row starts with.
    if ! [[ "$rc_claim" =~ ^[0-9]+$ ]] || ! [[ "$rc_wf" =~ ^[0-9]+$ ]]; then
      printf '%s: the exit-code pair reads (%s, %s) and neither is a number, so nothing was baked\n' \
        "$id" "$rc_claim" "$rc_wf" >&2
      defects=$((defects+1))
    elif [ "$rc_claim" != "$want_rc" ] || [ "$rc_wf" != "$want_wf" ]; then
      printf '%s: the baked pair (%s, %s) and kind %s predicts (%s, %s)\n' \
        "$id" "$rc_claim" "$rc_wf" "$kind" "$want_rc" "$want_wf" >&2
      defects=$((defects+1))
    fi

    # CLAUSE 3 of the invariant, the text half. A prime, a temporal operator
    # or an action keyword puts the expression above level 0 on its own.
    #
    # The vacuity witness goes through the same scan as the claim. It is
    # another level 0 expression the bake hands to TLC, so a variable hiding
    # in a witness is the same defect one field over.
    local what expr probe kw frees
    for what in claim witness; do
      if [ "$what" = "claim" ]; then
        expr="$claim"
      else
        expr="$vacuity"
        [ "$expr" = "-" ] && continue
      fi
      case "$expr" in
        *"'"*)
          printf '%s: the %s carries a prime, so it is not level 0\n' "$id" "$what" >&2
          defects=$((defects+1)) ;;
      esac
      # The tuple brackets come out before the temporal scan, because the
      # empty tuple <<>> carries the substring <> and six claims tripped on
      # it. Strip << and >> and the empty tuple disappears, while a real
      # eventually operator stays where it is.
      probe="${expr//<</ }"
      probe="${probe//>>/ }"
      for kw in UNCHANGED ENABLED WF_ SF_ '[]' '<>' '~>'; do
        case "$probe" in
          *"$kw"*)
            printf '%s: the %s carries %s, so it is not level 0\n' "$id" "$what" "$kw" >&2
            defects=$((defects+1)) ;;
        esac
      done
      frees="$(free_identifiers <<<"$expr")"
      if [ -n "$frees" ]; then
        printf '%s: the %s names %s, which is neither a standard operator nor bound there\n' \
          "$id" "$what" "$(tr '\n' ' ' <<<"$frees")" >&2
        defects=$((defects+1))
      fi
    done

    # The correction is L2 on the epic and it is not optional. A bare verdict
    # sits on the measured floor of feedback effectiveness, so an item without
    # a correction is a defect and not a shortcut.
    if [ -z "$correction" ] || [ "$correction" = "-" ]; then
      printf '%s: no correction, and a bare verdict sits on the measured floor\n' "$id" >&2
      defects=$((defects+1))
    elif [ "${#correction}" -lt 20 ]; then
      printf '%s: the correction is %s characters, which is too short to correct anything\n' \
        "$id" "${#correction}" >&2
      defects=$((defects+1))
    fi

    # The vacuity witness makes vacuity a measurement. It belongs on exactly
    # the vacuous items.
    if [ "$kind" = "vacuous" ] && [ "$vacuity" = "-" ]; then
      printf '%s: vacuous with no witness, so the label has no TLC run behind it\n' "$id" >&2
      defects=$((defects+1))
    fi
    if [ "$kind" != "vacuous" ] && [ "$vacuity" != "-" ]; then
      printf '%s: kind %s carries a vacuity witness, which only a vacuous item has\n' \
        "$id" "$kind" >&2
      defects=$((defects+1))
    fi
  done <"$file"

  printf '%s\n' "$defects"
}

nonblank() { grep -c . <<<"$1" || true; }

printf 'swipe level 0 corpus\n'

# ---------------------------------------------------------------------------
# 1. The files are there.
# ---------------------------------------------------------------------------
for f in "$ITEMS" "$TEMPLATES" "$BAKE"; do
  if [ -f "$f" ]; then
    ok "present: ${f#"$REPO_ROOT/"}"
  else
    bad "missing: ${f#"$REPO_ROOT/"}"
  fi
done
if [ -x "$BAKE" ]; then
  ok "bake.sh is executable"
else
  bad "bake.sh is not executable"
fi

if [ ! -f "$ITEMS" ] || [ ! -f "$TEMPLATES" ]; then
  printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. The corpus is big enough to carry a base rate and small enough to review.
# ---------------------------------------------------------------------------
N_ITEMS="$(awk -F'\t' '$1 == "ITEM"' "$ITEMS" | grep -c . || true)"
N_TPL="$(awk -F'\t' '$1 == "TPL"' "$TEMPLATES" | grep -c . || true)"

# RE-BASED BY tla-7xql.7, from a 60-to-100 TOTAL band to a PER-TEMPLATE floor,
# because the total was never the quantity that mattered. The stem-blind gate
# runs per template, so a template's own item count is what sets whether an
# artifact in it is detectable, and a total band lets one thin template hide
# behind four fat ones.
#
# 32 IS THE FLOOR AND IT IS NOT ARBITRARY. harness/swipe/stemblind.sh power
# reads mindetect 0.6190 at n=32 and 0.6900 at n=16. Gururangan's premise-blind
# classifier scored 0.67, so at 16 the published finding this gate was copied
# from sits ABOVE the floor and cannot be called, and at 32 it sits below.
# The corpus ships 48, where mindetect is 0.5705.
SMALLEST_TPL="$(awk -F'\t' '$1 == "ITEM" { n[$3]++ } END { m = -1; for (t in n) if (m < 0 || n[t] < m) m = n[t]; print m }' "$ITEMS")"
if [ "$SMALLEST_TPL" -ge 32 ]; then
  ok "every template carries at least 32 items, the thinnest $SMALLEST_TPL and $N_ITEMS in all, so an artifact at Gururangan's 0.67 is detectable"
else
  bad "the thinnest template carries $SMALLEST_TPL items, under the 32 that makes a 0.67 artifact detectable"
fi
if [ "$N_TPL" -ge 3 ] && [ "$N_TPL" -le 5 ]; then
  ok "$N_TPL templates, inside the 3 to 5 the bead asks for"
else
  bad "$N_TPL templates, and the bead asks for 3 to 5"
fi

# Every template carries items, and every template states its generating idea.
TPL_DEFECTS=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  n="$(awk -F'\t' -v t="$t" '$1 == "ITEM" && $3 == t' "$ITEMS" | grep -c . || true)"
  if [ "$n" -eq 0 ]; then
    printf '       template %s has no items\n' "$t"
    TPL_DEFECTS=$((TPL_DEFECTS+1))
  fi
  idea="$(awk -F'\t' -v t="$t" '$1 == "TPL" && $2 == t {print $4}' "$TEMPLATES")"
  if [ "${#idea}" -lt 40 ]; then
    printf '       template %s states no generating idea\n' "$t"
    TPL_DEFECTS=$((TPL_DEFECTS+1))
  fi
done < <(awk -F'\t' '$1 == "TPL" {print $2}' "$TEMPLATES")
if [ "$TPL_DEFECTS" -eq 0 ]; then
  ok "every template carries items and states its generating idea"
else
  bad "$TPL_DEFECTS templates carry no items or state no idea"
fi

# ---------------------------------------------------------------------------
# 3. The structural half of the invariant, over the real corpus.
# ---------------------------------------------------------------------------
REAL_DEFECTS="$(structural_defects "$ITEMS" 2>"$SCRATCH/real.err")"
if [ "$REAL_DEFECTS" = "0" ]; then
  ok "every item carries a baked verdict, both kind tags and a level 0 claim"
else
  bad "$REAL_DEFECTS structural defects"
  sed -n '1,20p' "$SCRATCH/real.err" | sed 's/^/       /'
fi

# ---------------------------------------------------------------------------
# 4. The mix carries true and false substantively, which is L7 on the epic. A
#    true-heavy corpus transfers back to recognition and nowhere else. The base
#    rate reported here is the chance floor bead tla-7xql.1 measures against,
#    and it is computed from the corpus rather than assumed to be one third.
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
# 5. The TLC half. bake.sh --check confirms every stored verdict against the
#    exit-code channel, and it is the only thing here that decides whether a
#    verdict is right.
# ---------------------------------------------------------------------------
if out="$("$BAKE" --check 2>&1)"; then
  ok "bake.sh --check confirms every stored verdict"
else
  bad "bake.sh --check rejected the stored verdicts"
  sed -n '1,20p' <<<"$out" | sed 's/^/       /'
fi

# ---------------------------------------------------------------------------
# 6. The \div tripwire.
#
#    The jar's own Naturals.tla says a = b * (a \div b) + (a % b) holds for any
#    integers with b > 0. TLC 2026.07.31.184830 breaks it on a negative
#    dividend: the remainder follows the contract and the quotient truncates
#    toward zero instead of rounding down. No item depends on that, and this
#    assertion is what tells somebody the constraint can be lifted: a TLC that
#    fixes \div turns this line red on purpose.
# ---------------------------------------------------------------------------
cat > "$SCRATCH/DivTrip.tla" <<'TLA'
---- MODULE DivTrip ----
EXTENDS Integers

ASSUME 5 * (-17 \div 5) + (-17 % 5) # -17
====
TLA
printf '\\* no keywords needed\n' > "$SCRATCH/DivTrip.cfg"
rc=0
"$VERDICT" -q -c "$SCRATCH/DivTrip.cfg" "$SCRATCH/DivTrip.tla" >/dev/null 2>&1 || rc=$?
if [ "$rc" = "0" ]; then
  ok "TLC still breaks a = b * (a \\div b) + (a % b) on a negative dividend"
else
  bad "the \\div identity now holds (rc $rc). Re-read the note in ITEMS.tsv: the constraint on \\div items can be lifted"
fi

# ---------------------------------------------------------------------------
# 7. Structural controls. Each mutates a copy and the checker has to reject it.
#    A check that has never rejected anything is not evidence.
# ---------------------------------------------------------------------------
CTRL="$SCRATCH/ctrl"
mkdir -p "$CTRL"

# Each control damages exactly one row of a copy. The awk program sits at the
# call site rather than behind a helper, because a helper hides it from the
# linter, which then reads every $1 and $9 as a shell expansion that forgot
# its quotes. That was 25 SC2016 findings, and the fix is to put the awk where
# the linter can see it.
#
# No line of this comment may START with the word shellcheck, which is why it
# reads "linter" instead. A continuation line beginning with that word parses
# as a second directive and raised SC1072 and SC1073 on the first attempt.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $6 = "left"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/swipe-flip.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $7 = "10"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-flip.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $7 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/rc-unbaked.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $5 = "maybe"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/kind-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $4 = "reachable"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/ask-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $11 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/correction-blank.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $11 = "wrong"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/correction-stub.tsv"
# Targets the fifth row and not the first. Rewriting the first row's id to its
# own value is a no-op, and it read as a pass until the control was watched.
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $2 == "L0-T1-05" { $2 = "L0-T1-01" } { print }' \
  "$ITEMS" > "$CTRL/duplicate-id.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $3 = "T9"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/template-unknown.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { NF = 10; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/field-dropped.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "vacuous" && !d { $10 = "-"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-dropped.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "true" && !d { $10 = "1 = 1"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-spurious.tsv"
awk -F'\t' -v OFS='\t' -v p="tick' = 2" '$1 == "ITEM" && !d { $9 = p; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-primed.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $9 = "Cardinality(seen) = 3"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-variable.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $9 = "[]TRUE"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-temporal.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $9 = "ENABLED TRUE"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/claim-enabled.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && $5 == "vacuous" && !d { $10 = "seen = {}"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/witness-variable.tsv"
awk -F'\t' -v OFS='\t' '$1 == "ITEM" && !d { $9 = "Cardinality(seen, 1) = 3"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/comma-launder.tsv"

for c in swipe-flip rc-flip rc-unbaked kind-unknown ask-unknown correction-blank \
         correction-stub duplicate-id template-unknown field-dropped \
         witness-dropped witness-spurious claim-primed claim-variable \
         claim-temporal claim-enabled witness-variable comma-launder; do
  d="$(structural_defects "$CTRL/$c.tsv" 2>"$CTRL/$c.err")"
  if [ "$d" != "0" ]; then
    ok "control $c: rejected ($(sed -n '1p' "$CTRL/$c.err"))"
  else
    bad "control $c: accepted, so the check is blind to it"
  fi
done

# The other direction, which matters as much. A checker that rejects
# everything is not a checker, and the identifier scan is the part most likely
# to over-reject: it has to pass a comma-bound quantifier and every backslash
# operator in the language. These two must be ACCEPTED.
# The backslashes are doubled because awk reads a -v value as a string
# literal, so a single \E arrives as a bare E and the control then measures a
# claim with no operators in it. It did, and both controls read as failures
# until the warning on stderr was read.
awk -F'\t' -v OFS='\t' -v c='\\E p, q \\in 1..3 : p < q' \
  '$1 == "ITEM" && $5 == "true" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/accept-comma-bound.tsv"
awk -F'\t' -v OFS='\t' -v c='Cardinality({1} \\cup {2}) \\div 1 = 2' \
  '$1 == "ITEM" && $5 == "true" && !d { $9 = c; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/accept-operators.tsv"

# These compare against the real corpus's own count rather than against zero,
# so they say "this mutation added no defect" rather than "the whole file is
# clean", which is a different claim and already made above.
for c in accept-comma-bound accept-operators; do
  d="$(structural_defects "$CTRL/$c.tsv" 2>"$CTRL/$c.err")"
  if [ "$d" = "$REAL_DEFECTS" ]; then
    ok "control $c: accepted, so the identifier scan does not over-reject"
  else
    bad "control $c: added a defect ($(sed -n '1p' "$CTRL/$c.err"))"
  fi
done

# ---------------------------------------------------------------------------
# 8. TLC controls, scoped to one template so each costs 5 JVMs.
#
#    Every one of these keeps fields 4 to 8 self-consistent and damages the
#    CLAIM, so the structural checker passes and only the TLC half can catch
#    it. A control that reddens the structural half first proves nothing about
#    TLC, which is the trap the bead warns about: an assertion is weak whenever
#    the unchanged code already fails it for another reason.
# ---------------------------------------------------------------------------
# A claim labeled true that is in fact false. The holds batch has to redden.
awk -F'\t' -v OFS='\t' \
  '$1 == "ITEM" && $3 == "T1" && $5 == "true" && !d { $9 = "1 = 2"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/tlc-holds-false.tsv"
# A claim labeled false that is in fact true. The refuted batch has to redden.
awk -F'\t' -v OFS='\t' \
  '$1 == "ITEM" && $3 == "T1" && $5 == "false" && !d { $9 = "1 = 1"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/tlc-refuted-true.tsv"
# A vacuous item whose witness does not hold, so the item is true and not vacuous.
awk -F'\t' -v OFS='\t' \
  '$1 == "ITEM" && $3 == "T1" && $5 == "vacuous" && !d { $10 = "1 = 2"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/tlc-witness-false.tsv"
# An item labeled illformed whose claim evaluates fine. Its single probe has to redden.
awk -F'\t' -v OFS='\t' \
  '$1 == "ITEM" && $3 == "T1" && $5 == "illformed" && !d { $9 = "1 = 2"; d = 1 } { print }' \
  "$ITEMS" > "$CTRL/tlc-ill-wellformed.tsv"

for c in tlc-holds-false tlc-refuted-true tlc-witness-false tlc-ill-wellformed; do
  pre="$(structural_defects "$CTRL/$c.tsv" 2>/dev/null)"
  if [ "$pre" != "$REAL_DEFECTS" ]; then
    bad "control $c: the structural half rejected it first, so it proves nothing about TLC"
    continue
  fi
  if out="$("$BAKE" --check --items "$CTRL/$c.tsv" --template T1 2>&1)"; then
    bad "control $c: bake.sh --check accepted it, so TLC is not deciding the verdict"
  else
    ok "control $c: rejected by TLC ($(sed -n '1p' <<<"$out"))"
  fi
done

# ---------------------------------------------------------------------------
# 9. The generated modules declare no CONSTANT and no VARIABLE, which is what
#    makes the third clause of the invariant true by construction rather than
#    by text scan. It is also decision D1 on the epic answered for this rung:
#    the CONSTANTS stay visible, and at level 0 there are none to show.
# ---------------------------------------------------------------------------
EMIT="$SCRATCH/emit"
"$BAKE" --check --template T1 --emit "$EMIT" >/dev/null 2>&1 || true
if [ -f "$EMIT/SwipeHolds.tla" ]; then
  decls="$(grep -hE '^[[:space:]]*(CONSTANTS?|VARIABLES?)[[:space:]]' "$EMIT"/*.tla || true)"
  n_decls="$(nonblank "$decls")"
  if [ "$n_decls" -eq 0 ]; then
    ok "no generated module declares a CONSTANT or a VARIABLE"
  else
    bad "$n_decls declaration lines in the generated modules, so a claim could reach a variable"
  fi
  n_assume="$(grep -c '^ASSUME' "$EMIT/SwipeHolds.tla" || true)"
  if [ "$n_assume" -gt 1 ]; then
    ok "the holds batch carries $n_assume assumes in one module, so one JVM covers them"
  else
    bad "the holds batch carries $n_assume assumes, so the batching is not happening"
  fi
else
  bad "bake.sh --emit wrote no SwipeHolds.tla"
fi

# ---------------------------------------------------------------------------
# 10. rc 150 is a row in the channel and not an authoring error.
#
#     THE INVARIANT, in bead tla-7xql.10's words: every exit code the bake can
#     observe maps to a declared verdict and a declared swipe, and rc 150 is
#     among them. Frank ruled on 2026-10-18 that a parse failure is a
#     down-swipe item under its own kind, so the gesture stays a three-way
#     partition while field 5 keeps the distinction.
#
#     THE COST OF THAT RULING IS THAT A TYPO NOW HAS A HOME, and the controls
#     below are what stop it moving in. Before the ruling, a claim that did not
#     parse failed loudly wherever it sat. After it, 150 is a legitimate
#     outcome, and the only thing between a real item and a slip of the keyboard
#     is that a kind has to earn the pair it predicts. Both directions are
#     controlled: a typo inside an item declared true, and an item declared
#     unparsed whose claim parses fine.
#
#     NOTHING HERE TOUCHES ITEMS.tsv. The corpus ships 18 true, 18 false, 6
#     vacuous and 6 ill-formed per template, and that mix is what holds the
#     base rate at 0.3750. The power table in swipe/README.md is computed from
#     it, so an added item moves the mix, the base rate and the detection
#     floor together. These assertions run over a three-row fixture instead.
# ---------------------------------------------------------------------------
FX="$SCRATCH/fx"
mkdir -p "$FX"

# Two operators from one precedence band that SANY will not associate. That is
# the shape all six of the tla-7xql.7 refusals had.
BAD_CLAIM='12 \div 2 * 3 = 18'
BAD_FIX='Parenthesize it. SANY refuses this line rather than picking an order for the two operators.'

# The claim goes in as a printf argument and never into the format string,
# because bash printf reads a backslash in a format and \div would arrive as
# something else.
{
  printf 'ITEM\tL0-FX-01\tT1\tholds\ttrue\tright\t0\t0\t%s\t-\t%s\n' \
    '1 = 1' 'One is one, so the line holds and the swipe is right.'
  printf 'ITEM\tL0-FX-02\tT1\tholds\tfalse\tleft\t10\t0\t%s\t-\t%s\n' \
    '1 = 2' 'One is not two, so the line is false and the swipe is left.'
  printf 'ITEM\tL0-FX-03\tT1\tholds\tunparsed\tdown\t150\t150\t%s\t-\t%s\n' \
    "$BAD_CLAIM" "$BAD_FIX"
} > "$FX/accept.tsv"

# The constant itself, measured without going through bake.sh at all. If a
# later SANY accepts this line, the fixture quietly stops testing a parse
# failure, and this assertion is what says so.
cat > "$SCRATCH/NoParse.tla" <<'TLA'
---- MODULE NoParse ----
EXTENDS Integers

ASSUME 12 \div 2 * 3 = 18
====
TLA
printf '\\* no keywords needed\n' > "$SCRATCH/NoParse.cfg"
rc=0
"$VERDICT" -q -c "$SCRATCH/NoParse.cfg" "$SCRATCH/NoParse.tla" >/dev/null 2>&1 || rc=$?
if [ "$rc" = "150" ]; then
  ok "SANY still refuses 12 \\div 2 * 3 at rc 150, so the fixture tests a parse failure"
else
  bad "the claim came back rc $rc rather than 150, so the fixture no longer tests one"
fi

FX_DEFECTS="$(structural_defects "$FX/accept.tsv" 2>"$FX/accept.err")"
if [ "$FX_DEFECTS" = "0" ]; then
  ok "kind unparsed carries a declared swipe and a declared pair"
else
  bad "the structural half rejected a well-formed unparsed item"
  sed -n '1,5p' "$FX/accept.err" | sed 's/^/       /'
fi

# The mapping itself, both halves of it. Neither control costs a JVM.
awk -F'\t' -v OFS='\t' '$5 == "unparsed" { $6 = "right" } { print }' \
  "$FX/accept.tsv" > "$FX/swipe-not-down.tsv"
awk -F'\t' -v OFS='\t' '$5 == "unparsed" { $7 = "10"; $8 = "10" } { print }' \
  "$FX/accept.tsv" > "$FX/pair-not-150.tsv"

for c in swipe-not-down pair-not-150; do
  d="$(structural_defects "$FX/$c.tsv" 2>"$FX/$c.err")"
  if [ "$d" != "0" ]; then
    ok "control $c: rejected ($(sed -n '1p' "$FX/$c.err"))"
  else
    bad "control $c: accepted, so the unparsed mapping is not enforced"
  fi
done

if out="$("$BAKE" --check --items "$FX/accept.tsv" 2>&1)"; then
  ok "bake.sh --check confirms an unparsed item against TLC"
else
  bad "bake.sh --check rejected the unparsed fixture"
  sed -n '1,10p' <<<"$out" | sed 's/^/       /'
fi

# THE SAFETY CONTROL. A typo inside an item declared true still has to fail,
# or the ruling above bought a down swipe at the price of silent corruption.
# Fields 5 to 8 stay self-consistent, so the structural half passes and only
# TLC can catch it.
awk -F'\t' -v OFS='\t' \
  '$5 == "unparsed" { $5 = "true"; $6 = "right"; $7 = "0"; $8 = "0" } { print }' \
  "$FX/accept.tsv" > "$FX/typo-as-true.tsv"
pre="$(structural_defects "$FX/typo-as-true.tsv" 2>/dev/null)"
if [ "$pre" != "0" ]; then
  bad "control typo-as-true: the structural half rejected it first, so it proves nothing about TLC"
elif out="$("$BAKE" --check --items "$FX/typo-as-true.tsv" 2>&1)"; then
  bad "control typo-as-true: a claim that does not parse baked as true, so a typo now ships"
else
  ok "control typo-as-true: rejected by TLC ($(sed -n '1p' <<<"$out"))"
  # The report has to say WHICH failure it is. A batch that comes back 150 and
  # reads as "at least one does not hold" invites a relabel where the fix is a
  # pair of parentheses. Read from a here-string: a pipe into an early-exiting
  # consumer returns 141 under pipefail and reads as a pass.
  if grep -q 'does not parse' <<<"$out"; then
    ok "control typo-as-true: the report names the parse failure rather than a wrong kind"
  else
    bad "control typo-as-true: the report blames the kind, so a typo reads as a mislabeled item"
  fi
fi

# The other direction. Parking a claim under unparsed does not make it so.
awk -F'\t' -v OFS='\t' '$5 == "unparsed" { $9 = "1 = 1" } { print }' \
  "$FX/accept.tsv" > "$FX/unparsed-parses.tsv"
pre="$(structural_defects "$FX/unparsed-parses.tsv" 2>/dev/null)"
if [ "$pre" != "0" ]; then
  bad "control unparsed-parses: the structural half rejected it first, so it proves nothing about TLC"
elif out="$("$BAKE" --check --items "$FX/unparsed-parses.tsv" 2>&1)"; then
  bad "control unparsed-parses: a claim that parses baked as unparsed"
else
  ok "control unparsed-parses: rejected by TLC ($(sed -n '1p' <<<"$out"))"
fi

# --write is the half that reads a verdict OFF the exit codes rather than
# confirming a stored one, so it is where the mapping either exists or does
# not. The pair goes in unbaked and the bake has to fill it.
awk -F'\t' -v OFS='\t' \
  '$5 == "unparsed" { $6 = "-"; $7 = "-"; $8 = "-"; print }' \
  "$FX/accept.tsv" > "$FX/write.tsv"
if "$BAKE" --write --items "$FX/write.tsv" >"$FX/write.out" 2>&1; then
  baked="$(awk -F'\t' '$1 == "ITEM" { print $6, $7, $8 }' "$FX/write.tsv")"
  if [ "$baked" = "down 150 150" ]; then
    ok "bake.sh --write reads (150, 150) off TLC and files it as down"
  else
    bad "bake.sh --write filed the unparsed item as [$baked] and not down 150 150"
  fi
else
  bad "bake.sh --write rejected an item whose authored kind is unparsed"
  sed -n '1,10p' "$FX/write.out" | sed 's/^/       /'
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
