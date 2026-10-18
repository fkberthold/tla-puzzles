#!/usr/bin/env bash
# test-swipe-stemblind.sh — the stem-blind gate (bead tla-7xql.1, epic
# tla-7xql).
#
# THE INVARIANT, in the bead's own words: for every generator template, a
# label predicted from the claim alone scores no better than that template's
# own most-common-label base rate, within a stated tolerance, and the gate
# fails when it does better.
#
# WHY IT MATTERS, and it is measured rather than argued. Gururangan,
# Swayamdipta, Levy, Schwartz, Bowman and Smith, 2018, NAACL: on a task with
# this exact label set, a classifier that NEVER SAW THE PREMISE scored 67% on
# SNLI and 53% on MultiNLI against a 34.3% majority baseline. The giveaways
# were habits of the people writing the items. Poliak and others found the
# same across ten corpora the same year, all expert-reviewed, and concluded
# that reported progress on the task had been substantially overestimated. An
# accuracy number cannot tell a reader who did the work from a reader who read
# the authoring habit, so a corpus can pass review and measure nothing.
#
# ===========================================================================
# WHAT THE BEAD SAYS AND WHAT THIS GATE DOES INSTEAD
# ===========================================================================
#
# The bead says "hide the model, show only the claim and its tag, predict the
# label". AT LEVEL 0 THERE IS NO MODEL. A level 0 expression has no variable,
# no prime and no temporal operator, so Cardinality(SUBSET {1, 2, 3}) = 8 is
# self-contained and there is no premise to withhold. Read literally, the gate
# is vacuous on the only corpus that exists.
#
# So the adaptation, and the reasoning is the whole design. Gururangan's
# finding is not about premises. It is about a correlation between the label
# and the SURFACE FORM of the item, independent of what the item denotes. At
# level 0 the question becomes: can the label be predicted from the claim's
# surface without evaluating it? A reader who learns "a round number on the
# right means true" or "this family's false items are the ones with a nested
# operator" scores well while evaluating nothing, and that is the same
# failure wearing level 0's clothes.
#
# Two things follow that the bead's phrasing does not imply.
#
# ONE. The stem cannot be stripped of the expression, because the expression
# is the whole item. What CAN be stripped is everything around it, and at
# level 0 that turns out to matter more than it sounds: swipe/README.md says
# the item ids run in kind order inside each template, so 01 to 06 are true,
# 07 to 12 are false, 13 and 14 are vacuous and 15 and 16 do not evaluate.
# L0-T1-09 carries its own answer in its name. So the emitter hashes the id
# and sorts by the hash, and part 2 below asserts the result carries neither
# the token nor the ordinal.
#
# TWO. The measurement needs an instrument that runs with no judge, because a
# judge-only gate measures only when somebody remembers to dispatch one, and
# an advisory check nobody runs is how the drift comes back. So part 3 fits a
# decision stump over surface features of the stem, per template, scored by
# leave-one-out, with the threshold set by a permutation null.
#
# ===========================================================================
# WHAT 16 ITEMS PER TEMPLATE CAN AND CANNOT DECIDE
# ===========================================================================
#
# This is a finding, not a caveat, and part 6 computes it rather than
# asserting it. At n=16 with a 37.5% base rate and alpha 0.05, the exact
# binomial critical count is 10, so the tolerance is 25 PERCENTAGE POINTS and
# an artifact has to make the label 69% predictable before the gate fires 80%
# of the time. The signature part 3 already finds in T5 sits at 62.5% and
# does not fire.
#
# So the honest reading: this gate catches a blatant artifact and misses a
# moderate one, and the fix is items rather than a looser tolerance. At 48 per
# template the tolerance falls to 14.6 points, at 80 to 10.0. Pooling the five
# templates would get there too and is exactly what the bead forbids, because
# a pooled number hides a bad template behind good ones.
#
# WHAT RUNS AND WHAT IT COSTS. No JVM. Nothing here parses or checks a module,
# because the whole question is about text and labels. The cost is the
# permutation null, which is four probe runs at 200 to 1000 permutations.
#
# Lineage: bead tla-7xql.1. The corpus under test is bead tla-7xql.2.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

ITEMS="$REPO_ROOT/swipe/level0/ITEMS.tsv"

# The THINNEST template's item count, which is the n every power statement in
# this suite is about. Read off the corpus rather than written as a literal:
# bead tla-7xql.7 took every template from 16 to 48 and a literal 16 here then
# compared the power table at one size against a scorer running at another.
# The thinnest rather than the mean, because the gate runs per template and a
# thin one is what decides whether an artifact in IT is detectable.
LIVE_N="$(awk -F'\t' '$1 == "ITEM" { n[$3]++ } END { m = -1; for (t in n) if (m < 0 || n[t] < m) m = n[t]; print m }' "$ITEMS")"
TEMPLATES="$REPO_ROOT/swipe/level0/TEMPLATES.tsv"
SB="$REPO_ROOT/harness/swipe/stemblind.sh"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

SCRATCH="$(mktemp -d -t stemblind_gate.XXXXXX)"
# Reached only through the EXIT trap. shellcheck does not follow traps, so it
# reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

for f in "$ITEMS" "$TEMPLATES" "$SB"; do
  if [ ! -f "$f" ]; then
    printf 'test-swipe-stemblind.sh: missing %s\n' "$f" >&2
    exit 1
  fi
done

# ===========================================================================
# THE TEMPLATE LIST IS DERIVED FROM THE CORPUS, NEVER WRITTEN DOWN HERE.
#
# A hardcoded T1 T2 T3 T4 T5 would mean every later template is skipped in
# silence, and the count assertion in part 1 would still pass because it
# compares two files neither of which this list comes from. Bead tla-z4f3 hit
# the same shape from the other side: harness/recall-gate.sh keyed a check on
# a construct id, an id means whatever the inventory in use says it means, and
# the id-keyed version called the suite's own fixture a finding.
#
# So the list comes off ITEMS.tsv, the control targets below are drawn FROM
# that list rather than named, and part 1 asserts the two tables agree on
# which templates exist.
# ===========================================================================
TPL_IDS="$(awk -F'\t' '$1 == "ITEM" { print $3 }' "$ITEMS" | LC_ALL=C sort -u | tr '\n' ' ')"
TPL_IDS="${TPL_IDS% }"
# The control targets. Drawn from the derived list, so they follow a rename.
SKEW_TPL="${TPL_IDS##* }"      # the last template, for the mix-skew control
PLANT_TPL="${TPL_IDS%% *}"     # the first template, for the planted artifact

# ---------------------------------------------------------------------------
# Helpers. Each one captures and then reads, never pipes into a consumer that
# can exit early: under pipefail that returns 141 and a present pattern reads
# as absent. See harness/test-pipefail.sh, which bans the idiom across this
# tree and would catch it here.
# ---------------------------------------------------------------------------
field() { awk -F'\t' -v k="$2" '{ for (i = 1; i <= NF; i++) if ($i ~ "^" k "=") { sub("^" k "=", "", $i); print $i } }' <<<"$1"; }

row_for() { grep -E "^$2	$3	" <<<"$1" || true; }

# ===========================================================================
# PART 1 — the chance floor, recomputed from the corpus.
#
# The bead is explicit that the floor is not one third. It is the base rate of
# the most common label in THAT TEMPLATE's output. The epic's note records
# swipe/level0/bake.sh --stats reading 37.5% in all five and says plainly that
# the uniformity comes from authoring to a 6/6/2/2 mix rather than from a
# measurement, so it will not hold for a later template. This part recomputes
# it through a second code path and compares, which is the only way the number
# is a measurement rather than a copy.
# ===========================================================================
printf '== part 1: the chance floor, recomputed ==\n'

BASE_OUT="$("$SB" base 2>&1)"
base_rc=$?
if [ "$base_rc" -ne 0 ]; then
  bad "stemblind base exited $base_rc: $BASE_OUT"
else
  ok "stemblind base runs clean"
fi

n_base_rows="$(grep -c '^BASE	' <<<"$BASE_OUT" || true)"
n_tpl_rows="$(grep -c '^TPL	' "$TEMPLATES" || true)"
if [ "$n_base_rows" = "$n_tpl_rows" ]; then
  ok "base reports $n_base_rows templates, matching TEMPLATES.tsv"
else
  bad "base reports $n_base_rows templates against $n_tpl_rows in TEMPLATES.tsv"
fi

# The two tables have to agree on WHICH templates exist, not only on how many.
# A template with items and no TEMPLATES.tsv row has no generating idea
# recorded, and a row with no items is a family nothing was authored for.
# Either way the derived list above is reading a different set than part 1
# counted, and the per-template loops would skip or invent a template.
TPL_FROM_TABLE="$(awk -F'\t' '$1 == "TPL" { print $2 }' "$TEMPLATES" | LC_ALL=C sort -u | tr '\n' ' ')"
TPL_FROM_TABLE="${TPL_FROM_TABLE% }"
if [ "$TPL_IDS" = "$TPL_FROM_TABLE" ]; then
  ok "ITEMS.tsv and TEMPLATES.tsv name the same templates: $TPL_IDS"
else
  bad "the tables disagree on which templates exist: items [$TPL_IDS] against table [$TPL_FROM_TABLE]"
fi

# The second code path. Counts straight off the file, majority by hand.
INDEP="$(awk -F'\t' '
  $1 == "ITEM" { n[$3]++; c[$3, $6]++; seen[$3] = 1 }
  END {
    split("right left down", L, " ")
    for (t in seen) {
      top = 0
      for (j = 1; j <= 3; j++) { v = c[t, L[j]] + 0; if (v > top) top = v }
      printf("%s %d %.4f\n", t, n[t], top / n[t])
    }
  }' "$ITEMS")"

mismatch=""
onethird=""
for t in $TPL_IDS; do
  line="$(grep -E "^$t " <<<"$INDEP" || true)"
  if [ -z "$line" ]; then mismatch="$mismatch $t:absent"; continue; fi
  want_n="$(awk '{print $2}' <<<"$line")"
  want_r="$(awk '{print $3}' <<<"$line")"
  row="$(grep -E "^BASE	$t	" <<<"$BASE_OUT" || true)"
  got_n="$(field "$row" n)"
  got_r="$(field "$row" rate)"
  [ "$want_n" = "$got_n" ] || mismatch="$mismatch $t:n($want_n/$got_n)"
  [ "$want_r" = "$got_r" ] || mismatch="$mismatch $t:rate($want_r/$got_r)"
  [ "$got_r" = "0.3333" ] && onethird="$onethird $t"
done
if [ -z "$mismatch" ]; then
  ok "every template's base rate agrees with an independent count of ITEMS.tsv"
else
  bad "base rate disagrees with an independent count:$mismatch"
fi
if [ -z "$onethird" ]; then
  ok "no template's floor is 1/3, which is the assumption the bead rejects"
else
  bad "the floor came out at 1/3 for$onethird, so something is assuming a uniform mix"
fi

# Per-template label counts must sum to the item count, or the floor is being
# computed over a different denominator than the one it is divided by.
sumbad=""
for t in $TPL_IDS; do
  row="$(grep -E "^BASE	$t	" <<<"$BASE_OUT" || true)"
  r="$(field "$row" right)"; l="$(field "$row" left)"; d="$(field "$row" down)"
  nn="$(field "$row" n)"
  tot=$((r + l + d))
  [ "$tot" = "$nn" ] || sumbad="$sumbad $t($tot/$nn)"
done
if [ -z "$sumbad" ]; then
  ok "every template's label counts sum to its item count"
else
  bad "label counts do not sum to the item count for:$sumbad"
fi

# CONTROL. Skew one template's mix and the floor must move. Without this the
# three assertions above are consistent with a hardcoded 0.3750.
#
# The expected rate is computed from the skewed file rather than written here,
# for the same reason the template list is derived: a literal 0.6250 would be
# a fact about today's 6/6/4 mix pretending to be a fact about the skew.
SKEWED="$SCRATCH/ITEMS-skewed.tsv"
awk -F'\t' -v OFS='\t' -v t="$SKEW_TPL" '
  $1 == "ITEM" && $3 == t && $6 == "down" { $6 = "right" } { print }
' "$ITEMS" > "$SKEWED"
SKEW_WANT="$(awk -F'\t' -v t="$SKEW_TPL" '
  $1 == "ITEM" && $3 == t { n++; c[$6]++ }
  END { top = 0; for (k in c) if (c[k] > top) top = c[k]; printf("%.4f", top / n) }
' "$SKEWED")"
SKEW_OUT="$("$SB" base --items "$SKEWED" 2>&1)"
skew_r="$(field "$(grep -E "^BASE	$SKEW_TPL	" <<<"$SKEW_OUT" || true)" rate)"
skew_ship="$(field "$(grep -E "^BASE	$SKEW_TPL	" <<<"$BASE_OUT" || true)" rate)"
if [ "$skew_r" = "$SKEW_WANT" ] && [ "$skew_r" != "$skew_ship" ]; then
  ok "folding $SKEW_TPL's down items into right moves its floor from $skew_ship to $skew_r, so the rate is measured"
else
  bad "skewing $SKEW_TPL gave $skew_r, expected $SKEW_WANT and a move off $skew_ship — the rate may be hardcoded"
fi

# ===========================================================================
# PART 2 — the emitter hands over the claim and nothing else.
#
# recall/README.md:60-70 carries this project's own instance of the hazard:
# field 5 sat on the same tab-delimited line as field 6, so reading the
# question handed over the answer. A baked corpus is one step worse, because
# the verdict travels with the item.
# ===========================================================================
printf '\n== part 2: the stems carry no answer ==\n'

STEMS="$SCRATCH/stems.tsv"
"$SB" emit --out "$STEMS" 2>"$SCRATCH/emit.err"
emit_rc=$?
if [ "$emit_rc" -eq 0 ] && [ -s "$STEMS" ]; then
  ok "stemblind emit writes a stem file"
else
  bad "stemblind emit exited $emit_rc: $(cat "$SCRATCH/emit.err")"
fi

STEM_ROWS="$(grep '^STEM	' "$STEMS" || true)"
n_stems="$(grep -c . <<<"$STEM_ROWS" || true)"
n_items="$(grep -c '^ITEM	' "$ITEMS" || true)"
if [ "$n_stems" = "$n_items" ]; then
  ok "one stem per item, $n_stems of them"
else
  bad "$n_stems stems against $n_items items"
fi

# Four fields and no more. This is the assertion that forecloses a leaked
# column generically, rather than naming the six fields one at a time.
wrongwidth="$(awk -F'\t' '$1 == "STEM" && NF != 4 { print NR ":" NF }' "$STEMS")"
if [ -z "$wrongwidth" ]; then
  ok "every STEM row carries exactly four fields"
else
  bad "STEM rows with the wrong field count: $wrongwidth"
fi

badask="$(awk -F'\t' '$1 == "STEM" && $3 != "holds" && $3 != "implies" { print $2 }' "$STEMS")"
if [ -z "$badask" ]; then
  ok "field 3 is the ask tag and takes only holds or implies"
else
  bad "field 3 carries something other than an ask tag: $badask"
fi

# The item id is the sharpest leak in this corpus, because the ids run in kind
# order. Assert the token is nowhere in the file at all, comments included.
idleak="$(grep -oE 'L0-T[0-9]+-[0-9]+' "$STEMS" || true)"
if [ -z "$idleak" ]; then
  ok "no item id appears anywhere in the stem file"
else
  bad "item ids leaked into the stem file: $(tr '\n' ' ' <<<"$idleak")"
fi

tleak="$(awk -F'\t' '$1 == "STEM" { for (i = 2; i <= 3; i++) if ($i ~ /^T[0-9]+$/) print $2 }' "$STEMS")"
if [ -z "$tleak" ]; then
  ok "no STEM row carries a bare template id, so there is no family grouping to pattern on"
else
  bad "template ids leaked: $tleak"
fi

# Field 10 is the vacuity witness and field 11 the flash. Either one in a stem
# row hands over the answer in prose. Checked by exact text rather than by
# column position, since a leak would arrive as an extra column.
KEY="$("$SB" reveal 2>/dev/null)"
leaks=""
while IFS= read -r l; do
  [ -n "$l" ] || continue
  wit="$(cut -f10 <<<"$l")"
  fla="$(cut -f11 <<<"$l")"
  if [ "$wit" != "-" ] && [ -n "$wit" ]; then
    grep -Fq -- "$wit" "$STEMS" && leaks="$leaks witness"
  fi
  if [ -n "$fla" ]; then
    grep -Fq -- "$fla" "$STEMS" && leaks="$leaks flash"
  fi
done < <(grep '^ITEM	' "$ITEMS")
if [ -z "$leaks" ]; then
  ok "no vacuity witness and no flash text reaches the stem file"
else
  bad "the stem file carries:$leaks"
fi

# Stem ids have to be unique or two items share a prediction slot.
dupids="$(awk -F'\t' '$1 == "STEM" { c[$2]++ } END { for (k in c) if (c[k] > 1) print k }' "$STEMS")"
if [ -z "$dupids" ]; then
  ok "every stem id is unique"
else
  bad "stem id collision: $dupids"
fi

# The claim must survive intact, or the gate is measuring a mangled stem.
claimbad="$(awk -F'\t' -v OFS='\t' '
  FNR == NR { if ($1 == "STEM") seen[$4] = 1; next }
  $1 == "ITEM" { if (!($9 in seen)) print $2 }
' "$STEMS" "$ITEMS")"
if [ -z "$claimbad" ]; then
  ok "every item claim appears verbatim as a stem"
else
  bad "claims missing or altered for: $claimbad"
fi

# ---------------------------------------------------------------------------
# The emitted ORDER is the other half of the item-id leak, and it is the half
# that was live. The first hash here was h = h * 131 + ord, which takes the
# last character additively, so L0-T1-01 through L0-T1-09 hashed to S100dc0
# through S100dc8 and sorting by the hash reproduced the kind order exactly:
# six rights, then six lefts, then four downs. The token was gone and the
# answer was still in the file.
#
# So two checks, and the control below is the broken order itself.
# ---------------------------------------------------------------------------
order_stats() {
  awk -F'\t' '
    FNR == NR { if ($1 == "KEY") { itemid[$2] = $3; swipe[$2] = $6; tpl[$2] = $4 } ; next }
    $1 == "STEM" {
      t = tpl[$2]
      k = ++pos[t]
      ord = itemid[$2]; sub(/^L0-T[0-9]+-/, "", ord)
      seq[t, k] = ord + 0
      lab[t, k] = swipe[$2]
      if (!(t in seenT)) { seenT[t] = 1; order[++nt] = t }
      n[t] = k
    }
    END {
      for (i = 1; i <= nt; i++) {
        t = order[i]
        adj = 0; chg = 0
        for (k = 2; k <= n[t]; k++) {
          d = seq[t, k] - seq[t, k - 1]; if (d < 0) d = -d
          if (d == 1) adj++
          if (lab[t, k] != lab[t, k - 1]) chg++
        }
        printf("ORDER\t%s\tn=%d\tadjacent=%d\tchanges=%d\n", t, n[t], adj, chg)
      }
    }
  ' <(printf '%s\n' "$KEY") "$1"
}

ORD_OUT="$(order_stats "$STEMS")"
adjbad=""
chgbad=""
for t in $TPL_IDS; do
  row="$(grep -E "^ORDER	$t	" <<<"$ORD_OUT" || true)"
  a="$(field "$row" adjacent)"
  c="$(field "$row" changes)"
  [ "${a:-99}" -le 3 ] || adjbad="$adjbad $t($a)"
  [ "${c:-0}" -ge 6 ] || chgbad="$chgbad $t($c)"
done
if [ -z "$adjbad" ]; then
  ok "the emitted order carries no item ordinal: at most 3 adjacent-ordinal pairs per template"
else
  bad "the emitted order tracks the item ordinal for:$adjbad of 15 adjacent pairs"
fi
if [ -z "$chgbad" ]; then
  ok "the emitted order is not the kind-block order: at least 6 label changes per template"
else
  bad "the emitted label sequence is nearly blocked for:$chgbad changes"
fi

# CONTROL. A bad order must redden both checks above, or they are two numbers
# that have never been seen to fail.
#
# REBUILT BY tla-7xql.7, AND THE OLD ONE HAD GONE VACUOUS. It sorted on the
# item id, which reddened both checks only because ids happened to run in kind
# order inside a template. That bead appended ids 17 to 48 rather than
# renumbering, which is a real improvement, since the id no longer gives the
# kind away. It also left this control unable to produce a bad order at all:
# it read adjacent=47 changes=29 and passed both checks it exists to fail.
#
# So the control now sorts on the ANSWER KEY'S OWN LABEL, then on the item id
# within a label. That is the adversarial order directly rather than a proxy
# that happened to correlate with it: a label sort gives perfect kind blocks by
# construction, and the id sort inside each block gives runs of consecutive
# ordinals. Both checks have something to catch no matter how ids are assigned
# later.
BADORDER="$SCRATCH/stems-keyorder.tsv"
awk -F'\t' -v OFS='\t' '
  FNR == NR { if ($1 == "KEY") { itemid[$2] = $3; label[$2] = $6 } next }
  $1 == "STEM" { print label[$2], itemid[$2], $0 }
' <(printf '%s\n' "$KEY") "$STEMS" | LC_ALL=C sort > "$SCRATCH/keyorder.raw"
cut -f3- "$SCRATCH/keyorder.raw" > "$BADORDER"
CTRL_OUT="$(order_stats "$BADORDER")"
ctrl_a="$(field "$(grep -E '^ORDER	T1	' <<<"$CTRL_OUT" || true)" adjacent)"
ctrl_c="$(field "$(grep -E '^ORDER	T1	' <<<"$CTRL_OUT" || true)" changes)"
if [ "${ctrl_a:-0}" -gt 3 ] && [ "${ctrl_c:-9}" -lt 6 ]; then
  ok "the control order (sorted by the answer key) reddens both checks: adjacent=$ctrl_a changes=$ctrl_c"
else
  bad "the control order did not redden the order checks: adjacent=$ctrl_a changes=$ctrl_c"
fi

# A stem id must not depend on which templates were emitted, or a judge
# answering one template cannot be scored against the whole corpus.
ONE="$SCRATCH/stems-t2.tsv"
"$SB" emit --template T2 --out "$ONE" >/dev/null 2>&1
drift="$(awk -F'\t' '
  FNR == NR { if ($1 == "STEM") full[$2] = $4; next }
  $1 == "STEM" { if (!($2 in full) || full[$2] != $4) print $2 }
' "$STEMS" "$ONE")"
if [ -z "$drift" ]; then
  ok "a stem id is the same whether one template or all five are emitted"
else
  bad "stem ids move when the emit is scoped: $drift"
fi

# ===========================================================================
# PART 3 — the deterministic probe, which is what makes this a gate.
#
# THE FEATURE SET, and why this one. A feature is admissible iff a reader
# could read it off the stem WITHOUT working out what the expression denotes.
# That rules out anything that needs evaluation, which is the whole point:
# a feature that needs evaluation is the item doing its job.
#
# What is left is which tokens appear, how long the line is, and the ask tag.
# The bag-of-tokens half is deliberately not hand-picked. Gururangan's
# giveaways were lexical, and hand-picking would let the corpus pass by
# choosing features it happens to be clean on, so every token in a claim
# becomes a candidate and the corpus names its own signature. The symbol list
# is fixed rather than derived for the opposite reason: deriving it would miss
# the operator a later template introduces.
#
# THE CLASSIFIER is a decision stump scored by leave-one-out. Simplest thing
# that can exploit a lexical artifact, and the only one whose failure message
# names the artifact. Leave-one-out is what makes a rule that memorizes a
# single item worth nothing, which matters here because several tokens occur
# on exactly one item.
#
# THE THRESHOLD is the 95th percentile of the same statistic under label
# permutation, not a number anybody chose. It absorbs the binomial noise at
# n=16 and the best-of-35-features selection bias together, which no analytic
# tolerance can do. Fixed seed and a self-contained Lehmer generator, so the
# number does not move between gawk and mawk.
# ===========================================================================
printf '\n== part 3: the judge-free probe ==\n'

PROBE_A="$SCRATCH/probe-a.txt"
"$SB" probe > "$PROBE_A" 2>"$SCRATCH/probe.err"
probe_rc=$?
PROBE_OUT="$(cat "$PROBE_A")"

if [ "$probe_rc" -eq 0 ] || [ "$probe_rc" -eq 1 ]; then
  ok "stemblind probe runs and returns a verdict (rc=$probe_rc)"
else
  bad "stemblind probe exited $probe_rc: $(cat "$SCRATCH/probe.err")"
fi

n_probe="$(grep -c '^PROBE	' <<<"$PROBE_OUT" || true)"
if [ "$n_probe" = "$n_tpl_rows" ]; then
  ok "the probe reports a row for each of the $n_probe templates, never a pooled number"
else
  bad "the probe reports $n_probe rows against $n_tpl_rows templates"
fi

# A stump can always reproduce the majority-class predictor, so a best score
# under the base rate means the leave-one-out scorer is broken rather than
# that the corpus is clean.
underbase=""
for t in $TPL_IDS; do
  row="$(grep -E "^PROBE	$t	" <<<"$PROBE_OUT" || true)"
  b="$(field "$row" base)"
  s="$(field "$row" best)"
  awk -v a="$s" -v c="$b" 'BEGIN { exit !(a + 1e-9 < c) }' && underbase="$underbase $t($s<$b)"
done
if [ -z "$underbase" ]; then
  ok "every template's best stump scores at or above its own floor, so the scorer is sane"
else
  bad "a stump scored under the majority-class floor, so the LOO scorer is wrong:$underbase"
fi

# THE PROBE'S OWN VACUITY CHECK. A permutation null whose 95th percentile has
# reached 1.0 can never flag anything, so the gate would be green by
# construction. This project already gates vacuity on its TLC channel
# (harness/vacuity.sh); the same question applies to a statistical one.
sat="$(grep -c '^PROBE-SATURATED	' <<<"$PROBE_OUT" || true)"
if [ "$sat" = "0" ]; then
  ok "no template's permutation null is saturated, so the probe can still fire"
else
  bad "$sat template(s) have a saturated null, so the probe cannot detect anything there"
fi

# THE BEAD'S INVARIANT. This is the assertion that may legitimately go red
# one day, and when it does the finding is the corpus rather than the gate.
flagged="$(field "$(grep '^PROBE-RESULT	' <<<"$PROBE_OUT" || true)" flagged)"
if [ "${flagged:-1}" = "0" ]; then
  ok "no shipped template's label is predictable from the claim surface"
else
  bad "$flagged template(s) carry a surface artifact: $(grep 'verdict=ARTIFACT' <<<"$PROBE_OUT" | cut -f2,6,7,9 | tr '\n' ' ')"
fi

# Reproducible, because a gate whose number moves run to run cannot be read.
PROBE_B="$SCRATCH/probe-b.txt"
"$SB" probe --perms 200 > "$PROBE_B" 2>/dev/null
PROBE_C="$SCRATCH/probe-c.txt"
"$SB" probe --perms 200 > "$PROBE_C" 2>/dev/null
if cmp -s "$PROBE_B" "$PROBE_C"; then
  ok "two probe runs at the same seed are byte-identical"
else
  bad "the probe is not reproducible at a fixed seed"
fi

# ...and it must move with the seed, or the permutation is not happening and
# the threshold is a constant wearing a statistic's clothes.
#
# THE PROBE-RESULT LINE IS STRIPPED BEFORE THE COMPARISON, AND THE FIRST
# VERSION OF THIS ASSERTION COULD NOT FAIL WITHOUT IT. That line echoes the
# seed it was given, so two whole-file captures always differ on the seed
# field whatever the null did. Found by replacing the Fisher-Yates swap with
# a no-op, which leaves p at 1.0 for every seed: the whole-file comparison
# called that a pass.
PROBE_D="$SCRATCH/probe-d.txt"
"$SB" probe --perms 200 --seed 99991 > "$PROBE_D" 2>/dev/null
seed_b="$(grep '^PROBE	' "$PROBE_B" || true)"
seed_d="$(grep '^PROBE	' "$PROBE_D" || true)"
if [ -n "$seed_b" ] && [ "$seed_b" != "$seed_d" ]; then
  ok "a different seed moves the null, so the permutation is real"
else
  bad "a different seed gives the identical null, so no permutation is being done"
fi

# ===========================================================================
# PART 4 — the planted artifact.
#
# A gate that has never seen an artifact is a gate nobody tested. This plants
# one and watches the probe catch it.
#
# WHAT IS PLANTED, and the shape is Gururangan's own: a lexical token that
# correlates with one label. Every FALSE claim in the target template is
# rewritten as TRUE conjoined with the original, which is a real authoring
# habit and also MEANING-PRESERVING, so the mutant's baked verdicts would
# still hold if anybody ran swipe/level0/bake.sh over it. The mix is
# untouched, so the floor does not move and the only thing that changed is the
# alignment.
#
# THIS COMMENT USED TO END "neither the word TRUE nor a forward slash appears
# anywhere in the shipped claims, so the planted token is pure wherever it
# lands", AND THE CORPUS OUTGREW IT. Bead tla-7xql.9 measured five T2 claims
# carrying one or the other: L0-T2-22, -23, -33, -34 and -43, spread over all
# three labels. The plant is still pure, but for a narrower reason than the one
# written here. It lands in the FIRST template, the collisions are all in T2,
# and the count assertion below is scoped to the target template for exactly
# that case. A purity claim over the whole file was a fact about eighty items
# wearing the clothes of a fact about the corpus.
# ===========================================================================
printf '\n== part 4: a planted artifact, and whether the probe sees it ==\n'

MUTANT="$SCRATCH/ITEMS-planted.tsv"
awk -F'\t' -v OFS='\t' -v t="$PLANT_TPL" '
  $1 == "ITEM" && $3 == t && $6 == "left" { $9 = "TRUE /\\ (" $9 ")" }
  { print }
' "$ITEMS" > "$MUTANT"

n_left="$(awk -F'\t' -v t="$PLANT_TPL" '$1 == "ITEM" && $3 == t && $6 == "left" { n++ } END { print n + 0 }' "$ITEMS")"
# Scoped to the target template rather than counted over the file, so a corpus
# that already carries the token somewhere else does not read as over-planting.
n_planted="$(awk -F'\t' -v t="$PLANT_TPL" '$1 == "ITEM" && $3 == t && index($9, "TRUE /\\") > 0 { n++ } END { print n + 0 }' "$MUTANT")"
if [ "$n_planted" = "$n_left" ] && [ "$n_planted" -gt 0 ]; then
  ok "the mutant carries the planted token on exactly $n_planted claims, $PLANT_TPL's whole false class"
else
  bad "the mutant planted $n_planted tokens against $PLANT_TPL's $n_left false items"
fi

MUT_OUT="$("$SB" probe --items "$MUTANT" 2>/dev/null)"
mut_rc=$?
mut_flag="$(field "$(grep '^PROBE-RESULT	' <<<"$MUT_OUT" || true)" flagged)"
if [ "${mut_flag:-0}" = "1" ] && [ "$mut_rc" -eq 1 ]; then
  ok "the probe flags the planted artifact and exits 1"
else
  bad "the probe missed the planted artifact: flagged=${mut_flag:-?} rc=$mut_rc"
fi

mut_row="$(grep -E "^PROBE	$PLANT_TPL	" <<<"$MUT_OUT" || true)"
if [ "$(field "$mut_row" verdict)" = "ARTIFACT" ]; then
  ok "the flagged template is $PLANT_TPL, the one the artifact was planted in"
else
  bad "$PLANT_TPL is not the flagged template: $(field "$mut_row" verdict)"
fi

mut_best="$(field "$mut_row" best)"
ship_best="$(field "$(grep -E "^PROBE	$PLANT_TPL	" <<<"$PROBE_OUT" || true)" best)"
if awk -v m="$mut_best" -v s="$ship_best" 'BEGIN { exit !(m > s + 1e-9) }'; then
  ok "the planted token lifts $PLANT_TPL's best stump from $ship_best to $mut_best"
else
  bad "planting the token did not lift $PLANT_TPL's score: $ship_best to $mut_best"
fi

mut_feat="$(field "$mut_row" feature)"
if [ "$mut_feat" = "has:/" ] || [ "$mut_feat" = "has:TRUE" ]; then
  ok "the probe names the planted token as the signature: $mut_feat"
else
  bad "the probe flagged $PLANT_TPL on $mut_feat rather than on the planted token"
fi

# The artifact is template-local, which is why the bead forbids a pooled
# number. Every other template must read exactly as it did before.
others_pat="$(printf '%s' "$TPL_IDS" | tr ' ' '\n' | grep -vxF "$PLANT_TPL" | tr '\n' '|')"
others_pat="^PROBE	(${others_pat%|})	"
ship_others="$(grep -E "$others_pat" <<<"$PROBE_OUT" || true)"
mut_others="$(grep -E "$others_pat" <<<"$MUT_OUT" || true)"
if [ -n "$ship_others" ] && [ "$ship_others" = "$mut_others" ]; then
  ok "planting in $PLANT_TPL leaves every other template byte-identical"
else
  bad "planting in $PLANT_TPL moved another template's reading, so the probe is not template-local"
fi

# ===========================================================================
# PART 5 — the scorer, which is the half a fresh judge drives.
#
# Central emits stems, dispatches a judge that has not seen the items, and
# feeds the predictions back through here. The fixtures below stand in for the
# judge so the scorer has a number on every run.
# ===========================================================================
printf '\n== part 5: the scorer ==\n'

mkpred() {
  local mode="$1" arg="${2:-right}" out="$3"
  awk -F'\t' -v mode="$mode" -v arg="$arg" '
    $1 == "KEY" {
      if (mode == "oracle")   { print "PRED\t" $2 "\t" $6; next }
      if (mode == "constant") { print "PRED\t" $2 "\t" arg; next }
      if (mode == "nright") {
        k = ++seen[$4]
        if (k <= arg) print "PRED\t" $2 "\t" $6
        else print "PRED\t" $2 "\t" ($6 == "right" ? "down" : "right")
        next
      }
    }
  ' <<<"$KEY" > "$out"
}

P_FLOOR="$SCRATCH/pred-floor.tsv"; mkpred constant right "$P_FLOOR"
P_ORACLE="$SCRATCH/pred-oracle.tsv"; mkpred oracle right "$P_ORACLE"

FLOOR_OUT="$("$SB" score --predictions "$P_FLOOR" 2>&1)"
floor_rc=$?
floor_flag="$(field "$(grep '^SCORE-RESULT	' <<<"$FLOOR_OUT" || true)" flagged)"
floor_acc="$(field "$(grep -E '^SCORE	T1	' <<<"$FLOOR_OUT" || true)" acc)"
floor_base="$(field "$(grep -E '^SCORE	T1	' <<<"$FLOOR_OUT" || true)" base)"
if [ "$floor_rc" -eq 0 ] && [ "${floor_flag:-1}" = "0" ] && [ "$floor_acc" = "$floor_base" ]; then
  ok "answering one label for everything scores exactly the floor ($floor_acc) and is clear"
else
  bad "the floor predictor did not land on the floor: rc=$floor_rc flagged=$floor_flag acc=$floor_acc base=$floor_base"
fi

ORACLE_OUT="$("$SB" score --predictions "$P_ORACLE" 2>&1)"
oracle_rc=$?
oracle_flag="$(field "$(grep '^SCORE-RESULT	' <<<"$ORACLE_OUT" || true)" flagged)"
if [ "$oracle_rc" -eq 1 ] && [ "$oracle_flag" = "5" ]; then
  ok "a judge that gets every item right flags all five templates and exits 1"
else
  bad "the oracle was not flagged: rc=$oracle_rc flagged=$oracle_flag"
fi

# The boundary. crit comes out of the exact binomial, so crit-1 must be clear
# and crit must fire. A gate whose boundary was never walked is a gate with an
# off-by-one in it.
CRIT="$(field "$(grep -E '^SCORE	T1	' <<<"$ORACLE_OUT" || true)" crit)"
if [ -n "$CRIT" ] && [ "$CRIT" -gt 1 ]; then
  P_UNDER="$SCRATCH/pred-under.tsv"; mkpred nright "$((CRIT - 1))" "$P_UNDER"
  P_AT="$SCRATCH/pred-at.tsv"; mkpred nright "$CRIT" "$P_AT"
  u_out="$("$SB" score --predictions "$P_UNDER" 2>&1)"; u_rc=$?
  a_out="$("$SB" score --predictions "$P_AT" 2>&1)"; a_rc=$?
  u_flag="$(field "$(grep '^SCORE-RESULT	' <<<"$u_out" || true)" flagged)"
  a_flag="$(field "$(grep '^SCORE-RESULT	' <<<"$a_out" || true)" flagged)"
  if [ "$u_rc" -eq 0 ] && [ "${u_flag:-1}" = "0" ]; then
    ok "$((CRIT - 1)) of $LIVE_N correct is under the critical count and reads clear"
  else
    bad "$((CRIT - 1)) correct was flagged: rc=$u_rc flagged=$u_flag"
  fi
  if [ "$a_rc" -eq 1 ] && [ "${a_flag:-0}" = "5" ]; then
    ok "$CRIT of $LIVE_N correct is the critical count and fires on every template"
  else
    bad "$CRIT correct did not fire: rc=$a_rc flagged=$a_flag"
  fi
else
  skip "no critical count in the score output, so the boundary was not walked"
  skip "no critical count in the score output, so the boundary was not walked"
fi

# The input defects. Each one would otherwise let a judge turn a bad score
# into a clean one by handing back a different set than it was given.
check_refusal() {
  local label="$1" file="$2" want="$3"
  local out rc
  out="$("$SB" score --predictions "$file" 2>&1)"
  rc=$?
  if [ "$rc" -eq 2 ] && grep -Fq -- "$want" <<<"$out"; then
    ok "$label"
  else
    bad "$label — rc=$rc, output: $(tr '\n' '; ' <<<"$out")"
  fi
}

P_PART="$SCRATCH/pred-partial.tsv"
awk 'NR <= 75' "$P_ORACLE" > "$P_PART"
check_refusal "a partial prediction set is refused rather than scored" "$P_PART" "cannot be scored"

P_UNK="$SCRATCH/pred-unknown.tsv"
cp "$P_ORACLE" "$P_UNK"
printf 'PRED\tSdeadbe\tright\n' >> "$P_UNK"
check_refusal "an unknown stem id is refused" "$P_UNK" "unknown stem id"

P_BADLAB="$SCRATCH/pred-badlabel.tsv"
awk -F'\t' -v OFS='\t' 'NR == 1 { $3 = "up" } { print }' "$P_ORACLE" > "$P_BADLAB"
check_refusal "the review swipe (up) is refused as a prediction, since a judge must commit" "$P_BADLAB" "not a swipe"

P_DUP="$SCRATCH/pred-dup.tsv"
cp "$P_ORACLE" "$P_DUP"
awk 'NR == 1' "$P_ORACLE" >> "$P_DUP"
check_refusal "a stem predicted twice is refused" "$P_DUP" "predicted twice"

P_EMPTY="$SCRATCH/pred-empty.tsv"
printf '# nothing but a comment\n' > "$P_EMPTY"
check_refusal "an empty prediction set is refused" "$P_EMPTY" "no PRED rows"

# ===========================================================================
# PART 6 — the tolerance is a critical value, and the power statement is
# computed rather than asserted.
#
# The bead asks for a STATED tolerance. Stating one as a round number would
# make it a knob, so it is the exact binomial one-sided critical value at the
# template's own floor and a declared alpha. That makes the sample-size
# question answerable instead of rhetorical, and the answer is in this part's
# output rather than in a comment.
# ===========================================================================
printf '\n== part 6: the tolerance, and what %s items buys ==\n' "$LIVE_N"

# THE LIVE PER-TEMPLATE n, NOT A LITERAL 16. This read `power --n 16` until
# bead tla-7xql.7 took every template from 16 items to 48, and then it compared
# the table at one size against a scorer running at another and went red for
# saying so. The number that matters is the n the scorer is actually working
# at, so it is read off the corpus. A literal here is the same defect twice:
# once as a wrong assertion, and again because a corpus that grows is exactly
# what this check exists to keep honest.
POWLIVE="$("$SB" power --n "$LIVE_N" --base 0.375 2>&1)"
pow_crit="$(field "$POWLIVE" crit)"
if [ "$pow_crit" = "$CRIT" ]; then
  ok "the power table and the scorer agree on the critical count ($pow_crit of $LIVE_N)"
else
  bad "the power table says crit=$pow_crit at n=$LIVE_N and the scorer says $CRIT"
fi

pow_tol="$(field "$POWLIVE" tol)"
pow_md="$(field "$POWLIVE" mindetect)"
printf '       at n=%s, base 0.3750, alpha 0.05: tolerance %s, detectable at 0.80 power from %s\n' "$LIVE_N" "$pow_tol" "$pow_md"
if awk -v t="$pow_tol" 'BEGIN { exit !(t > 0) }'; then
  ok "the tolerance is a positive critical margin, $pow_tol at n=$LIVE_N"
else
  bad "the tolerance came out non-positive: $pow_tol"
fi

# Monotonicity. The tolerance has to shrink as items are added, or the power
# statement in the header is arithmetic nobody checked.
prev=""
mono=""
for nn in 16 32 48 64 80; do
  row="$("$SB" power --n "$nn" --base 0.375 2>&1)"
  tol="$(field "$row" tol)"
  printf '       n=%-3s crit=%-3s critacc=%s tol=%s mindetect=%s\n' \
    "$nn" "$(field "$row" crit)" "$(field "$row" critacc)" "$tol" "$(field "$row" mindetect)"
  if [ -n "$prev" ]; then
    awk -v a="$tol" -v b="$prev" 'BEGIN { exit !(a < b) }' || mono="$mono n=$nn($tol>=$prev)"
  fi
  prev="$tol"
done
if [ -z "$mono" ]; then
  ok "the tolerance shrinks monotonically as items are added, 16 through 80"
else
  bad "the tolerance did not shrink:$mono"
fi

# WHERE THE SHIPPED CORPUS SITS RELATIVE TO THE DETECTION FLOOR. This part
# exists to make the gap visible rather than to hide it, so the branch below
# passes either way and the message is the output. The leakiest template is
# found rather than named, because which one it is is a fact about the corpus
# and it will move as templates are added.
LEAK_ROW="$(grep '^PROBE	' <<<"$PROBE_OUT" | LC_ALL=C sort -t'	' -k6,6r | awk 'NR == 1')"
leak_tpl="$(cut -f2 <<<"$LEAK_ROW")"
leak_best="$(field "$LEAK_ROW" best)"
leak_feat="$(field "$LEAK_ROW" feature)"
if awk -v b="$leak_best" -v m="$pow_md" 'BEGIN { exit !(b < m) }'; then
  ok "the leakiest template is $leak_tpl on $leak_feat at $leak_best, under the n=16 detection floor $pow_md, so 16 items cannot settle it"
else
  ok "the leakiest template is $leak_tpl on $leak_feat at $leak_best, at or above the n=16 detection floor $pow_md"
fi

# ===========================================================================
# PART 7: no token in three or more claims of one template is perfectly
# correlated with that template's label.
#
# THIS IS A SECOND INVARIANT, NOT A RESTATEMENT OF PART 3, and the gap between
# them is the whole reason this part exists. Bead tla-7xql.8 carried the line
# above as its RED spec. It was violated four times and the probe never saw
# any of it:
#
#   T5  the token 17, 4 items, all true              named on the bead
#   T2  the token 5, 3 items, all right              shipped, never recorded
#   T2  the universal quantifier, 3 claims, vacuous  first draft
#   T3  the empty set, 3 claims, all vacuous         first draft
#
# What found all four was an author checking the line by hand, which makes the
# corpus's cleanliness a property of one person having been careful.
#
# WHY PART 3 MISSES THEM, and it is not a defect in part 3. The probe fits a
# decision stump scored by leave-one-out against a permutation null, so a rule
# covering 3 of 48 items is worth almost nothing to it however pure the 3 are.
# That is the right answer to the probe's own question, which is whether a
# judge could beat the base rate. "Does this template have a tell" is a
# different question. A three-item tell cannot move an accuracy number and can
# still be the thing a reader learns, because a reader meets the items one at
# a time rather than in aggregate.
#
# So the two gates disagree at n=48, THIS ONE IS STRICTER, and until this part
# landed only the looser one ran.
#
# WHICH LABEL, and the choice changes what "perfectly correlated" means.
# Field 6, the swipe, for two reasons that point the same way. It is what a
# judge predicts: stemblind.sh scores a prediction against field 6 and the
# probe fits against field 6, so correlating against anything else would gate
# a signal no judge is being asked for. And it is the STRICTER of the two
# candidates, which is not obvious. The swipe is a function of the kind
# (vacuous and illformed both bake to down), so grouping by swipe merges two
# classes into one, which can only raise a token's purity. Every kind-pure
# token is therefore swipe-pure, and a token on three down items that splits
# two vacuous and one illformed is swipe-pure while the kind column calls it
# clean. Measured on today's corpus the two columns give the same five worst
# offenders at the same purities, so the choice costs nothing here and is
# right for when it does.
#
# THE TOKENIZER IS STEMBLIND.SH'S OWN, reached through its tokens subcommand,
# which bead tla-7xql.9 added for this. A second tokenizer would make any
# disagreement between the two gates read as a finding about the corpus when
# it is a finding about the code, so the first assertion below checks that the
# feature the probe names is a string this part can see.
#
# WHAT IS NOT GATED. The worst purity per template is PRINTED and never
# asserted. Writing today's 0.75 in here would be a fact about 240 items
# pretending to be a threshold, which is the defect LIVE_N above was created
# to remove and the one part 4's comment just outgrew.
# ===========================================================================
printf '\n== part 7: no token is perfectly correlated with a label ==\n'

# The label order is stemblind.sh's LABELS, fixed rather than discovered for
# the reason given there: a tie broken by whichever key an awk implementation
# hashes first is a number that moves with the interpreter.
CORR_LABELS="right left down"

# Emits one CORR row per template, a CORR-PERFECT row for each template that
# carries one, and a CORR-RESULT line. Returns 1 when any template carries a
# perfect token, 0 when none does, 2 on an input defect.
corr_scan() {
  local items="$1" minc="$2" tk="$3"
  "$SB" tokens --items "$items" > "$tk" 2>/dev/null
  awk -F'\t' -v minc="$minc" -v labels="$CORR_LABELS" '
    FNR == NR {
      if ($1 == "ITEM") {
        lab[$2] = $6
        if (!($3 in tseen)) { tseen[$3] = 1; order[++nt] = $3 }
      }
      next
    }
    $1 == "TOKEN" {
      # An id in the token stream with no row in the items file would silently
      # land in a label bucket no label name matches, which UNDERSTATES purity
      # and quietly weakens the gate. Caught by name instead.
      if (!($2 in lab)) { unk = unk " " $2; next }
      key = $3 SUBSEP $4
      if (!(key in kn)) { kn[key] = 1; klist[++nk] = key }
      tot[key]++
      cnt[key, lab[$2]]++
    }
    END {
      if (unk != "") {
        printf("corr: token rows for items not in the corpus:%s\n", unk) > "/dev/stderr"
        exit 2
      }
      nl = split(labels, L, " ")
      # Sorted, so the token named when two tie on purity is the
      # lexicographically first one and not whichever awk hashed first.
      for (i = 2; i <= nk; i++) {
        v = klist[i]; j = i - 1
        while (j >= 1 && klist[j] > v) { klist[j + 1] = klist[j]; j-- }
        klist[j + 1] = v
      }
      for (i = 1; i <= nk; i++) {
        key = klist[i]
        if (tot[key] < minc) continue
        split(key, p, SUBSEP); t = p[1]; tok = p[2]
        top = 0; topl = "-"; acc = 0
        for (j = 1; j <= nl; j++) {
          v = cnt[key, L[j]] + 0
          acc += v
          if (v > top) { top = v; topl = L[j] }
        }
        # The same understatement from the other side: a label in the corpus
        # that this list does not name.
        if (acc != tot[key]) {
          printf("corr: %s %s has %d items but %d carry a known label\n", t, tok, tot[key], acc) > "/dev/stderr"
          bad = 1
        }
        elig[t]++
        if (top == tot[key]) {
          perf[t]++
          plist[t] = plist[t] (plist[t] == "" ? "" : " ") tok "(n=" tot[key] "," topl ")"
        }
        pur = top / tot[key]
        if (!(t in wseen) || pur > wpur[t] + 1e-12) {
          wseen[t] = 1; wpur[t] = pur; wtok[t] = tok; wn[t] = tot[key]; wl[t] = topl
        }
      }
      if (bad) exit 2
      tp = 0
      for (i = 1; i <= nt; i++) {
        t = order[i]
        printf("CORR\t%s\tmin=%d\teligible=%d\tperfect=%d\tworst=%s\tn=%d\tpurity=%.4f\tlabel=%s\n",
               t, minc, elig[t] + 0, perf[t] + 0,
               (t in wseen ? wtok[t] : "-"), (t in wseen ? wn[t] : 0),
               (t in wseen ? wpur[t] : 0), (t in wseen ? wl[t] : "-"))
        if (perf[t] + 0 > 0) printf("CORR-PERFECT\t%s\t%s\n", t, plist[t])
        tp += perf[t] + 0
      }
      printf("CORR-RESULT\t%s\ttemplates=%d\tperfect=%d\tmin=%d\n",
             (tp ? "ARTIFACT" : "holds"), nt, tp, minc)
      if (tp) exit 1
    }
  ' "$items" "$tk"
}

TOKENS_ALL="$SCRATCH/tokens.tsv"
"$SB" tokens > "$TOKENS_ALL" 2>"$SCRATCH/tokens.err"
tokens_rc=$?
tok_items="$(awk -F'\t' '$1 == "TOKEN" { seen[$2] = 1 } END { n = 0; for (k in seen) n++; print n }' "$TOKENS_ALL")"
if [ "$tokens_rc" -eq 0 ] && [ "$tok_items" = "$n_items" ]; then
  ok "stemblind tokens runs clean and carries a bag for each of the $tok_items items"
else
  bad "stemblind tokens exited $tokens_rc and covered $tok_items of $n_items items: $(cat "$SCRATCH/tokens.err")"
fi

# THE TWO INSTRUMENTS AGREE ON WHAT A TOKEN IS. The probe names its best
# feature by the same string this part reports, so whatever bag-of-tokens
# feature part 3 picked must be visible here, in the same template. The probe
# also has three derived features the bag does not carry (ask=, len>= and
# tok>=), so those are skipped rather than failed. They are not tokens of a
# claim, so the bead's invariant does not reach them.
TPL_TOKENS="$(awk -F'\t' -v OFS='\t' '$1 == "TOKEN" { print $3, $4 }' "$TOKENS_ALL" | LC_ALL=C sort -u)"
disagree=""
checked=0
for t in $TPL_IDS; do
  f="$(field "$(grep -E "^PROBE	$t	" <<<"$PROBE_OUT" || true)" feature)"
  case "$f" in
    has:*) : ;;
    *) continue ;;
  esac
  checked=$((checked + 1))
  grep -Fqx -- "$t	$f" <<<"$TPL_TOKENS" || disagree="$disagree $t($f)"
done
if [ "$checked" -gt 0 ] && [ -z "$disagree" ]; then
  ok "every bag feature the probe named is a token this part can see, $checked of them"
elif [ "$checked" -eq 0 ]; then
  skip "the probe named no bag feature, so the two tokenizers were not compared"
else
  bad "the probe named a feature the tokenizer here does not produce:$disagree"
fi

# ---------------------------------------------------------------------------
# THE INVARIANT.
# ---------------------------------------------------------------------------
CORR_OUT="$(corr_scan "$ITEMS" 3 "$SCRATCH/tok-ship.tsv")"
corr_rc=$?
printf '%s\n' "$CORR_OUT" | sed 's/^/       /'

corr_perfect="$(field "$(grep '^CORR-RESULT	' <<<"$CORR_OUT" || true)" perfect)"
if [ "$corr_rc" -eq 0 ] && [ "${corr_perfect:-1}" = "0" ]; then
  ok "no token in 3 or more claims of one template is perfectly correlated with its label"
else
  bad "$corr_perfect token(s) are perfectly correlated with a label: $(grep '^CORR-PERFECT	' <<<"$CORR_OUT" | tr '\n' ' ')"
fi

# Field 8 is purity=, field 7 is n=. The first draft of this line sorted on 7
# and reported the token on the MOST items rather than the most correlated
# one, which read plausibly and was wrong: has:5 in T2 at 0.6250 over has:6 in
# T3 at 0.7500. A fixed %.4f with a constant prefix sorts lexically, so the
# string compare is the numeric one here.
CORR_WORST="$(grep '^CORR	' <<<"$CORR_OUT" | LC_ALL=C sort -t'	' -k8,8r | awk 'NR == 1')"
printf '       the worst correlated token in the corpus is %s in %s, %s on %s items\n' \
  "$(field "$CORR_WORST" worst)" "$(cut -f2 <<<"$CORR_WORST")" \
  "$(field "$CORR_WORST" purity)" "$(field "$CORR_WORST" n)"

# ---------------------------------------------------------------------------
# CONTROL A: a planted perfect token must fire and name itself.
#
# Same plant as part 4 and for the same reason it is meaning-preserving, but
# scoped to exactly three items of one label rather than to a whole class,
# because three is the number the invariant turns on.
# ---------------------------------------------------------------------------
# The label to plant on is the target template's own most common one, read off
# part 1's output rather than written here. Any label with three items would
# do, and the majority one is the only choice that stays true however the mix
# is rebalanced later.
CORR_LABEL="$(field "$(grep -E "^BASE	$PLANT_TPL	" <<<"$BASE_OUT" || true)" top)"
PLANT3="$SCRATCH/ITEMS-corr3.tsv"
awk -F'\t' -v OFS='\t' -v t="$PLANT_TPL" -v lb="$CORR_LABEL" -v want=3 '
  $1 == "ITEM" && $3 == t && $6 == lb && k < want { k++; $9 = "TRUE /\\ (" $9 ")" }
  { print }
' "$ITEMS" > "$PLANT3"

# THE CONTROL'S OWN CAPABILITY CHECK, and it is the assertion that stops this
# going the way part 4's comment went. The plant is only a perfect 3-item
# token while PLANT_TPL carries no TRUE of its own. Five T2 claims already do,
# so this is a live hazard rather than a hypothetical: count the carriers in
# the target template before and after, and go red if the plant is diluted.
pre_true="$(awk -F'\t' -v t="$PLANT_TPL" '$1 == "ITEM" && $3 == t && index($9, "TRUE") > 0 { n++ } END { print n + 0 }' "$ITEMS")"
post_true="$(awk -F'\t' -v t="$PLANT_TPL" '$1 == "ITEM" && $3 == t && index($9, "TRUE") > 0 { n++ } END { print n + 0 }' "$PLANT3")"
if [ "$pre_true" = "0" ] && [ "$post_true" = "3" ]; then
  ok "the 3-item plant is the only TRUE in $PLANT_TPL, so the control can still produce a perfect token"
else
  bad "$PLANT_TPL already carries $pre_true TRUE claims and the plant made it $post_true, so the control is diluted"
fi

C3_OUT="$(corr_scan "$PLANT3" 3 "$SCRATCH/tok-c3.tsv")"
c3_rc=$?
c3_perf="$(field "$(grep '^CORR-RESULT	' <<<"$C3_OUT" || true)" perfect)"
c3_row="$(grep -E "^CORR-PERFECT	$PLANT_TPL	" <<<"$C3_OUT" || true)"
if [ "$c3_rc" -eq 1 ] && [ "${c3_perf:-0}" -ge 1 ] && [ -n "$c3_row" ]; then
  ok "a token planted on 3 same-label claims fires the gate and names $PLANT_TPL (rc=$c3_rc)"
else
  bad "the 3-item plant did not fire: rc=$c3_rc perfect=${c3_perf:-?} row=[$c3_row]"
fi
if grep -Fq 'has:TRUE(n=3,' <<<"$c3_row"; then
  ok "the gate names the planted token and its count: $(cut -f3 <<<"$c3_row")"
else
  bad "the gate fired on $PLANT_TPL without naming the planted token: $(cut -f3 <<<"$c3_row")"
fi

# Template-local, the same property part 4 asserts for the probe. A perfect
# token in one family must not move another family's reading.
c3_others="$(grep -E '^CORR	' <<<"$C3_OUT" | grep -vE "^CORR	$PLANT_TPL	" || true)"
ship_others_c="$(grep -E '^CORR	' <<<"$CORR_OUT" | grep -vE "^CORR	$PLANT_TPL	" || true)"
if [ -n "$ship_others_c" ] && [ "$c3_others" = "$ship_others_c" ]; then
  ok "planting in $PLANT_TPL leaves every other template's correlation reading identical"
else
  bad "planting in $PLANT_TPL moved another template's reading, so the scan is not template-local"
fi

# ---------------------------------------------------------------------------
# CONTROL B: two is not three. A gate too eager is as broken as a blind one.
#
# THE SECOND HALF IS WHAT MAKES THE FIRST HALF MEAN ANYTHING. "It did not
# fire" is also what a scan that reads nothing at all reports, so the same
# mutant is run at min=2, where the planted token must appear as perfect on
# exactly 2 items. That is the check that the quiet reading above is the
# threshold doing its job rather than the instrument being asleep.
# ---------------------------------------------------------------------------
PLANT2="$SCRATCH/ITEMS-corr2.tsv"
awk -F'\t' -v OFS='\t' -v t="$PLANT_TPL" -v lb="$CORR_LABEL" -v want=2 '
  $1 == "ITEM" && $3 == t && $6 == lb && k < want { k++; $9 = "TRUE /\\ (" $9 ")" }
  { print }
' "$ITEMS" > "$PLANT2"

# Scoped to the planted template rather than read off CORR-RESULT. The global
# count answers "is the whole corpus clean", which the invariant above already
# asked; this control is asking the narrower question of whether a 2-item
# token in THIS template fired, and a count over every template would make the
# control's verdict depend on families it never touched.
C2_OUT="$(corr_scan "$PLANT2" 3 "$SCRATCH/tok-c2.tsv")"
c2_perf="$(field "$(grep -E "^CORR	$PLANT_TPL	" <<<"$C2_OUT" || true)" perfect)"
if [ "${c2_perf:-1}" = "0" ]; then
  ok "a perfect token on only 2 claims does not fire, since the invariant says three"
else
  bad "the 2-item plant fired at min=3 in $PLANT_TPL, so the gate is too eager: perfect=${c2_perf:-?}"
fi

# Sharper than the count: the whole row for the planted template must read
# exactly as the shipped one does, worst offender included.
c2_tpl_row="$(grep -E "^CORR	$PLANT_TPL	" <<<"$C2_OUT" || true)"
ship_tpl_row="$(grep -E "^CORR	$PLANT_TPL	" <<<"$CORR_OUT" || true)"
if [ -n "$ship_tpl_row" ] && [ "$c2_tpl_row" = "$ship_tpl_row" ]; then
  ok "$PLANT_TPL's reading under the 2-item plant is identical to the shipped one"
else
  bad "the 2-item plant moved $PLANT_TPL's reading: [$c2_tpl_row] against [$ship_tpl_row]"
fi

C2LOW_OUT="$(corr_scan "$PLANT2" 2 "$SCRATCH/tok-c2low.tsv")"
c2low_rc=$?
c2low_row="$(grep -E "^CORR-PERFECT	$PLANT_TPL	" <<<"$C2LOW_OUT" || true)"
if [ "$c2low_rc" -eq 1 ] && grep -Fq 'has:TRUE(n=2,' <<<"$c2low_row"; then
  ok "the same 2-item plant DOES fire at min=2, so the quiet reading above is the threshold and not a blind scan"
else
  bad "the 2-item plant is invisible even at min=2, so control B proves nothing: rc=$c2low_rc row=[$c2low_row]"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
