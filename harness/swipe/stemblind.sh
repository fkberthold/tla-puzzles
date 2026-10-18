#!/usr/bin/env bash
# stemblind.sh — the stem-blind instrument for the swipe corpus (bead
# tla-7xql.1, epic tla-7xql).
#
# ===========================================================================
# THE CONTRACT, so somebody can drive this without reading the code
# ===========================================================================
#
# A machine-generated false item leaves a signature in how it was generated,
# and a reader who detects the signature scores well without doing the work
# the item is for. The accuracy metric cannot tell the difference, so a corpus
# can pass expert review and still measure nothing. Gururangan, Swayamdipta,
# Levy, Schwartz, Bowman and Smith, 2018, NAACL: a classifier that never saw
# the premise scored 67% on SNLI and 53% on MultiNLI against a 34.3% majority
# baseline, and the giveaways were habits of the people writing the items.
#
# This script is the two halves of the measurement, plus a judge-free probe.
#
# ---------------------------------------------------------------------------
# emit — what a fresh judge sees
# ---------------------------------------------------------------------------
#
#   harness/swipe/stemblind.sh emit [--template TN] [--out PATH]
#
# Writes one STEM row per item. Tab-delimited, literal marker in field 1, the
# house style of every other table in this tree:
#
#   STEM <tab> <stem-id> <tab> <ask> <tab> <claim>
#
#   field 2  stem-id   S plus six hex digits. Opaque and stable.
#   field 3  ask       holds or implies. The tag the reader sees.
#   field 4  claim     the single line the reader answers.
#
# NOTHING ELSE IS EMITTED, and three of the omissions are load-bearing.
#
#   The item id is NOT emitted. swipe/README.md says the ids run in kind order
#   inside each template, so 01 to 06 are true, 07 to 12 are false, 13 and 14
#   are vacuous and 15 and 16 do not evaluate. L0-T1-09 hands over its own
#   answer. The stem id is a hash of the item id instead, and the rows are
#   sorted by it, so neither the token nor the order carries the ordinal.
#
#   The template id is NOT emitted. A reader at level 0 gets no family screen,
#   so handing a judge the grouping would give it a within-family pattern a
#   reader never has.
#
#   Fields 5 to 8, 10 and 11 are NOT emitted: kind, swipe, the two exit codes,
#   the vacuity witness and the correction. Each is the answer in a different
#   costume. recall/README.md:60-70 carries this project's own instance of the
#   hazard, where field 5 sat on the same tab-delimited line as field 6 and
#   reading the question handed over the answer.
#
# ---------------------------------------------------------------------------
# score — what comes back
# ---------------------------------------------------------------------------
#
#   harness/swipe/stemblind.sh score --predictions PATH [--alpha A]
#
# The predictions file is tab-delimited with its own literal marker. Blank
# lines and lines starting with # are ignored, and so is any other marker:
#
#   PRED <tab> <stem-id> <tab> <swipe>
#
# <swipe> is right, left or down. A judge answers every stem it was given.
# Scoring is PER TEMPLATE and a template must be answered in full: a partial
# answer set is refused rather than scored, because scoring a subset lets a
# judge keep the stems it liked.
#
# One SCORE line per template, then one SCORE-RESULT line:
#
#   SCORE <tab> T1 <tab> n=16 <tab> correct=7 <tab> acc=0.4375 ...
#
# Exit 0 when every template is clear, 1 when any template beat its floor, 2
# on a usage or input defect.
#
# ---------------------------------------------------------------------------
# probe — the number on every run, with no judge at all
# ---------------------------------------------------------------------------
#
#   harness/swipe/stemblind.sh probe [--template TN] [--perms N] [--seed S]
#
# A judge-only gate is an advisory script, because it only measures when
# somebody remembers to dispatch one. So the probe fits a trivial classifier
# over surface features of the stem and scores it by leave-one-out. See the
# two long comments further down for the feature set and the threshold.
#
# ---------------------------------------------------------------------------
# the rest
# ---------------------------------------------------------------------------
#
#   base   [--template TN]        the per-template label counts and base rate
#   power  [--items N] [--base B] what sample size the tolerance assumes
#   reveal [--template TN]        stem id to item id. THIS IS THE ANSWER KEY.
#   tokens [--template TN]        the tokenizer's bag, one row per token
#
# tokens exists so a SECOND instrument can agree with the probe on what a token
# is. The probe asks whether a judge could beat the base rate, and a rule
# covering three of forty-eight items is worth almost nothing to it however
# pure it is. "Does this template have a tell" is a different question, and
# harness/test-swipe-stemblind.sh part 7 asks it directly. Two tokenizers would
# make a disagreement between those two gates read as a finding about the
# corpus when it is a finding about the code, so there is one tokenizer and
# this prints what it produces.
#
# --items PATH points every subcommand at a different ITEMS.tsv, which is how
# harness/test-swipe-stemblind.sh plants an artifact without touching swipe/.
#
# Lineage: bead tla-7xql.1. The tokens subcommand is bead tla-7xql.9.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ITEMS="$REPO_ROOT/swipe/level0/ITEMS.tsv"

OPT_TEMPLATE=""
OPT_OUT=""
OPT_PRED=""
OPT_ALPHA="0.05"
OPT_PERMS="1000"
OPT_SEED="20261018"
OPT_ITEMS_N="16"
OPT_BASE="0.375"
OPT_POWER="0.80"

# Prints the leading comment block, stopping at the first line of code. It read
# `sed -n '2,100p'` until bead tla-7xql.9 added a subcommand and its paragraph,
# which pushed the lineage footer past line 100 and out of the help. A line
# number in a help function is the same hardcoded-count defect the suite's own
# LIVE_N comment records, so the window is found rather than written down.
usage() {
  awk 'NR == 1 { next } /^[^#]/ { exit } { print }' "${BASH_SOURCE[0]}"
}

die() { printf 'stemblind: %s\n' "$1" >&2; exit 2; }

# ===========================================================================
# THE LABEL ORDER, and why it is fixed rather than discovered.
#
# Every tie-break and every array walk below uses this order, so the output is
# the same on gawk and on mawk. A tie broken by whichever key an awk
# implementation happens to hash first is a number that moves when the
# interpreter changes, which is the class of defect the toolchain pin in
# harness/test-toolchain-pin.sh exists to stop.
# ===========================================================================
LABELS="right left down"

# ===========================================================================
# THE SYMBOL TOKENS.
#
# The word tokenizer below matches names, backslash-names and numeric
# literals. It cannot see an operator written in punctuation, and the survey
# that shaped this feature set found three of those carrying real signal in
# the shipped corpus: a minus sign, a percent sign and a caret. So the symbols
# are a fixed list, checked by substring presence.
#
# The list is deliberately not derived from the corpus. Deriving it would
# allowlist whatever is already there and miss the operator a later template
# introduces, which is the same reasoning harness/test-swipe-level0.sh gives
# for hand-maintaining its identifier allowlist.
# ===========================================================================
SYMBOL_TOKENS='=> .. |-> << >> {} ~ # % ^ * + - @ ! : / { } [ ] ( ) ,'

# ---------------------------------------------------------------------------
# Shared awk prelude: the ord table, the stem-id hash, and the tokenizer.
#
# The ord table is built from sprintf("%c", i) rather than from a literal
# alphabet string, because the printable range contains a single quote and the
# awk programs here live inside single quotes.
# ---------------------------------------------------------------------------
AWK_PRELUDE='
function init_ord(   i) {
  for (i = 32; i < 127; i++) ORD[sprintf("%c", i)] = i
}
function stem_id(s,   h, i, c) {
  # THE FIRST VERSION OF THIS WAS THE BUG IT EXISTS TO PREVENT, and the shape
  # is worth keeping. A plain h = h * 131 + ord accumulator takes the last
  # character additively, so two ids differing only in their final digit hash
  # one apart and land next to each other in the sorted output. The first run
  # emitted S100dc0 through S100dc8 in item order, which reproduced the kind
  # order exactly: six rights, then six lefts, then four downs. The hash was
  # there to break that order and it preserved it.
  #
  # So every character goes through a full Lehmer step, and three more run at
  # the end, which puts a unit change in the last character 16807^4 apart
  # modulo 2^31. MINSTD stays inside 2^53 at every step, so this is exact in
  # awk arithmetic rather than approximately exact.
  h = 7919
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    h = (16807 * ((h + ORD[c]) % 2147483647)) % 2147483647
  }
  h = (16807 * h) % 2147483647
  h = (16807 * h) % 2147483647
  h = (16807 * h) % 2147483647
  return sprintf("S%06x", h % 16777216)
}
function tokenize(claim, out,   s, t, m, i, sy) {
  s = claim
  gsub(/"[^"]*"/, " QUOTEDSTRING ", s)
  while (match(s, /\\?[A-Za-z_][A-Za-z0-9_]*|[0-9]+/)) {
    out["has:" substr(s, RSTART, RLENGTH)] = 1
    s = substr(s, RSTART + RLENGTH)
  }
  m = split(SYMS, sy, " ")
  for (i = 1; i <= m; i++) if (index(claim, sy[i]) > 0) out["has:" sy[i]] = 1
}
'

# ---------------------------------------------------------------------------
# emit
# ---------------------------------------------------------------------------
cmd_emit() {
  local body
  body="$(awk -F'\t' -v tpl="$OPT_TEMPLATE" "$AWK_PRELUDE"'
    BEGIN { init_ord() }
    $1 == "ITEM" {
      if (tpl != "" && $3 != tpl) next
      sid = stem_id($2)
      if (sid in seen) {
        printf("stem id collision: %s and %s both hash to %s\n", seen[sid], $2, sid) > "/dev/stderr"
        bad = 1
      }
      seen[sid] = $2
      printf("STEM\t%s\t%s\t%s\n", sid, $4, $9)
    }
    END { if (bad) exit 2 }
  ' "$ITEMS")" || die "emit failed"

  local sorted
  sorted="$(LC_ALL=C sort <<<"$body")"

  {
    printf '# Stem-blind stems for the level 0 swipe corpus (bead tla-7xql.1).\n'
    printf '#\n'
    printf '# One row per item. Tab-delimited, literal marker STEM in field 1:\n'
    printf '#\n'
    printf '#   1  marker   the literal STEM\n'
    printf '#   2  stem-id  S plus six hex digits, opaque and stable\n'
    printf '#   3  ask      holds or implies, the tag shown with the question\n'
    printf '#   4  claim    the single line to answer\n'
    printf '#\n'
    printf '# Read rows with awk -F\\t or cut, never with IFS=$\\t read: tab is IFS\n'
    printf '# whitespace, so a run of tabs collapses and an empty field vanishes.\n'
    printf '#\n'
    printf '# ANSWER EVERY ROW. For each one, decide whether the claim holds (right),\n'
    printf '# is false (left), or is not a true-or-false claim at all (down), and\n'
    printf '# write one line per stem to a predictions file:\n'
    printf '#\n'
    printf '#   PRED <tab> <stem-id> <tab> right|left|down\n'
    printf '#\n'
    printf '# The row order is a hash order, not the authoring order, so neighboring\n'
    printf '# rows carry no relation to each other.\n'
    printf '#\n'
    printf '# Rows: %s\n' "$(nonblank_count "$sorted")"
    printf '%s\n' "$sorted"
  } > "${OPT_OUT:-/dev/stdout}"
}

nonblank_count() {
  local s="$1" n
  n="$(grep -c . <<<"$s" || true)"
  printf '%s' "${n:-0}"
}

# ---------------------------------------------------------------------------
# reveal — the answer key. Never hand this to a judge.
# ---------------------------------------------------------------------------
cmd_reveal() {
  awk -F'\t' -v tpl="$OPT_TEMPLATE" "$AWK_PRELUDE"'
    BEGIN { init_ord() }
    $1 == "ITEM" {
      if (tpl != "" && $3 != tpl) next
      printf("KEY\t%s\t%s\t%s\t%s\t%s\n", stem_id($2), $2, $3, $5, $6)
    }
  ' "$ITEMS"
}

# ---------------------------------------------------------------------------
# tokens: the tokenizer's own bag, printed, and nothing else.
#
# READ-ONLY and label-free by construction. It calls tokenize() exactly as
# cmd_probe does, over the same field 9, so the two instruments cannot drift
# apart on what a token is.
#
#   TOKEN <tab> <item-id> <tab> <template> <tab> <token>
#
# One row per item and token, sorted, so the output is stable between gawk and
# mawk for the same reason cmd_base sorts: a bare `for (k in arr)` walk has no
# specified order and a gate whose output moves with the interpreter is not a
# gate.
#
# WHAT IS DELIBERATELY NOT HERE. cmd_probe's feature set is the bag PLUS three
# derived features: the ask tag, a length bucket and a token-count bucket.
# Those are not tokens of a claim, so they are the probe's business. The bead's
# invariant is about a token in three or more CLAIMS, and a length bucket
# covering half a template is a different animal that the probe is already the
# right instrument for.
#
# The item id is here because a caller has to join these rows to a label, and
# the label is not. Nothing in this output tells a reader the answer, which
# keeps it on the same side of the line as emit.
# ---------------------------------------------------------------------------
cmd_tokens() {
  awk -F'\t' -v tpl="$OPT_TEMPLATE" -v SYMS="$SYMBOL_TOKENS" "$AWK_PRELUDE"'
    $1 == "ITEM" {
      if (tpl != "" && $3 != tpl) next
      delete toks
      tokenize($9, toks)
      for (k in toks) printf("TOKEN\t%s\t%s\t%s\n", $2, $3, k)
    }
  ' "$ITEMS" | LC_ALL=C sort
}

# ---------------------------------------------------------------------------
# base — the chance floor, recomputed from the corpus.
#
# The bead is explicit that the floor is not one third. It is the share of the
# most common label in THAT TEMPLATE's own output. The epic's note records
# swipe/level0/bake.sh --stats reading 37.5% in all five templates and says
# plainly that the uniformity is a property of authoring to a 6/6/2/2 mix
# rather than a measurement, so this recomputes it rather than taking it.
# ---------------------------------------------------------------------------
cmd_base() {
  awk -F'\t' -v tpl="$OPT_TEMPLATE" -v labels="$LABELS" '
    $1 == "ITEM" {
      if (tpl != "" && $3 != tpl) next
      n[$3]++
      c[$3, $6]++
      if (!($3 in seenT)) { seenT[$3] = 1; order[++nt] = $3 }
    }
    END {
      nl = split(labels, L, " ")
      for (i = 1; i <= nt; i++) {
        t = order[i]
        top = 0; topl = ""; tied = 0
        for (j = 1; j <= nl; j++) {
          v = c[t, L[j]] + 0
          if (v > top) { top = v; topl = L[j]; tied = 1 }
          else if (v == top && v > 0) tied++
        }
        printf("BASE\t%s\tn=%d", t, n[t])
        for (j = 1; j <= nl; j++) printf("\t%s=%d", L[j], c[t, L[j]] + 0)
        printf("\ttop=%s\ttied=%d\trate=%.4f\n", topl, tied, top / n[t])
      }
    }
  ' "$ITEMS" | LC_ALL=C sort
}

# ---------------------------------------------------------------------------
# power — exact binomial, so the tolerance is a critical value and not a knob.
# ---------------------------------------------------------------------------
cmd_power() {
  awk -v nn="$OPT_ITEMS_N" -v base="$OPT_BASE" -v alpha="$OPT_ALPHA" -v pw="$OPT_POWER" '
    function lfact(k,   i, s) {
      if (k in LF) return LF[k]
      s = 0
      for (i = 2; i <= k; i++) s += log(i)
      LF[k] = s
      return s
    }
    function lchoose(n, k) { return lfact(n) - lfact(k) - lfact(n - k) }
    function tail(n, k, p,   j, s, lp, lq) {
      if (k > n) return 0
      if (k <= 0) return 1
      if (p <= 0) return 0
      if (p >= 1) return 1
      lp = log(p); lq = log(1 - p)
      s = 0
      for (j = k; j <= n; j++) s += exp(lchoose(n, j) + j * lp + (n - j) * lq)
      if (s > 1) s = 1
      return s
    }
    BEGIN {
      crit = nn + 1
      for (k = 0; k <= nn; k++) { if (tail(nn, k, base) <= alpha) { crit = k; break } }
      mind = -1
      for (a = base; a <= 1.0001; a += 0.0005) {
        if (tail(nn, crit, a) >= pw) { mind = a; break }
      }
      printf("POWER\titems=%d\talpha=%.4f\tbase=%.4f\tcrit=%d\tcritacc=%.4f\ttol=%.4f",
             nn, alpha, base, crit, crit / nn, crit / nn - base)
      if (mind >= 0) printf("\tmindetect=%.4f\tatpower=%.2f\n", mind, pw)
      else printf("\tmindetect=unreachable\tatpower=%.2f\n", pw)
    }
  '
}

# ---------------------------------------------------------------------------
# score
# ---------------------------------------------------------------------------
cmd_score() {
  [ -n "$OPT_PRED" ] || die "score needs --predictions PATH"
  [ -f "$OPT_PRED" ] || die "no such predictions file: $OPT_PRED"

  local out rc
  set +e
  out="$(awk -F'\t' -v tpl="$OPT_TEMPLATE" -v labels="$LABELS" -v alpha="$OPT_ALPHA" \
            -v predfile="$OPT_PRED" "$AWK_PRELUDE"'
    function lfact(k,   i, s) {
      if (k in LF) return LF[k]
      s = 0
      for (i = 2; i <= k; i++) s += log(i)
      LF[k] = s
      return s
    }
    function lchoose(n, k) { return lfact(n) - lfact(k) - lfact(n - k) }
    function tail(n, k, p,   j, s, lp, lq) {
      if (k > n) return 0
      if (k <= 0) return 1
      lp = log(p); lq = log(1 - p)
      s = 0
      for (j = k; j <= n; j++) s += exp(lchoose(n, j) + j * lp + (n - j) * lq)
      if (s > 1) s = 1
      return s
    }
    BEGIN {
      init_ord()
      nl = split(labels, L, " ")
      for (i = 1; i <= nl; i++) valid[L[i]] = 1

      # Pass 1: the predictions. Read first so an unknown id is caught by name.
      while ((getline line < predfile) > 0) {
        if (line ~ /^[[:space:]]*#/) continue
        if (line ~ /^[[:space:]]*$/) continue
        nf = split(line, f, "\t")
        if (f[1] != "PRED") continue
        if (nf < 3) { err = err sprintf("  malformed PRED row: %s\n", line); continue }
        sid = f[2]; sw = f[3]
        if (!(sw in valid)) { err = err sprintf("  %s: not a swipe: %s\n", sid, sw); continue }
        if (sid in pred) { err = err sprintf("  %s: predicted twice\n", sid); continue }
        pred[sid] = sw
        npred++
      }
      close(predfile)
      if (npred == 0) err = err "  no PRED rows at all\n"
    }
    $1 == "ITEM" {
      if (tpl != "" && $3 != tpl) next
      sid = stem_id($2)
      key[sid] = $6
      item[sid] = $2
      tmpl[sid] = $3
      n[$3]++
      cnt[$3, $6]++
      if (!($3 in seenT)) { seenT[$3] = 1; order[++nt] = $3 }
      if (sid in pred) {
        answered[$3]++
        if (pred[sid] == $6) correct[$3]++
        matched[sid] = 1
      }
    }
    END {
      for (sid in pred) if (!(sid in matched)) err = err sprintf("  unknown stem id: %s\n", sid)
      for (i = 1; i <= nt; i++) {
        t = order[i]
        if (answered[t] + 0 != n[t]) {
          err = err sprintf("  %s: answered %d of %d stems, so it cannot be scored\n", t, answered[t] + 0, n[t])
        }
      }
      if (err != "") {
        printf("stemblind score: the predictions file does not line up with the corpus\n%s", err) > "/dev/stderr"
        exit 2
      }
      flagged = 0
      for (i = 1; i <= nt; i++) {
        t = order[i]
        top = 0
        for (j = 1; j <= nl; j++) { v = cnt[t, L[j]] + 0; if (v > top) top = v }
        b = top / n[t]
        crit = n[t] + 1
        for (k = 0; k <= n[t]; k++) { if (tail(n[t], k, b) <= alpha) { crit = k; break } }
        c = correct[t] + 0
        verdict = (c >= crit) ? "ARTIFACT" : "clear"
        if (c >= crit) flagged++
        printf("SCORE\t%s\tn=%d\tcorrect=%d\tacc=%.4f\tbase=%.4f\tcrit=%d\tcritacc=%.4f\tp=%.4g\tverdict=%s\n",
               t, n[t], c, c / n[t], b, crit, crit / n[t], tail(n[t], c, b), verdict)
      }
      printf("SCORE-RESULT\t%s\ttemplates=%d\tflagged=%d\talpha=%.4f\n",
             (flagged ? "ARTIFACT" : "clear"), nt, flagged, alpha)
      if (flagged) exit 1
    }
  ' "$ITEMS")"
  rc=$?
  set -e
  [ -n "$out" ] && printf '%s\n' "$out"
  return "$rc"
}

# ---------------------------------------------------------------------------
# probe
# ---------------------------------------------------------------------------
cmd_probe() {
  local out rc
  set +e
  out="$(awk -F'\t' -v tpl="$OPT_TEMPLATE" -v labels="$LABELS" -v SYMS="$SYMBOL_TOKENS" \
            -v perms="$OPT_PERMS" -v seed="$OPT_SEED" -v alpha="$OPT_ALPHA" "$AWK_PRELUDE"'
    # --- a self-contained Lehmer generator -------------------------------
    # srand/rand differ between gawk and mawk for the same seed, so the
    # permutation null would move with the interpreter. MINSTD stays inside
    # 2^53 at every step, so it is exact in awk arithmetic.
    function lcg_seed(s) { RSTATE = s % 2147483647; if (RSTATE <= 0) RSTATE += 2147483646 }
    function lcg() { RSTATE = (16807 * RSTATE) % 2147483647; return RSTATE / 2147483647 }

    # --- the leave-one-out score of one decision stump -------------------
    #
    # Items sharing a bucket AND a label share a leave-one-out prediction, so
    # the whole score comes out of the 2-by-3 contingency table rather than
    # from an explicit fold loop. A bucket holding one item falls back to the
    # global majority, which is what makes a rule that memorizes a single item
    # worth nothing.
    #
    # A k-way tie among the maxima scores 1/k, the expected accuracy of
    # breaking it at random. That convention is what makes the majority-class
    # predictor score exactly the base rate, tie or no tie, so the comparison
    # the bead asks for is against a floor and not against an artifact of how
    # ties were resolved.
    function bucket_credit(cv, gv, s, gn,   j, m, tied, cr, use, un) {
      cr = 0
      for (j = 1; j <= nl; j++) {
        if (cv[j] == 0) continue
        if (s - 1 <= 0) { for (k = 1; k <= nl; k++) use[k] = gv[k] - (k == j ? 1 : 0); un = gn - 1 }
        else            { for (k = 1; k <= nl; k++) use[k] = cv[k] - (k == j ? 1 : 0); un = s - 1 }
        m = -1; tied = 0
        for (k = 1; k <= nl; k++) { if (use[k] > m) { m = use[k]; tied = 1 } else if (use[k] == m) tied++ }
        if (use[j] == m) cr += cv[j] / tied
      }
      return cr
    }
    function stump_loo(t, f, lb,   i, idx, cp, ca, gv, j, s, cr) {
      for (j = 1; j <= nl; j++) { cp[j] = 0; gv[j] = 0 }
      for (i = 1; i <= n[t]; i++) gv[labidx[lb[i]]]++
      s = 0
      for (i = 1; i <= npres[t, f]; i++) {
        idx = pres[t, f, i]
        cp[labidx[lb[idx]]]++
        s++
      }
      for (j = 1; j <= nl; j++) ca[j] = gv[j] - cp[j]
      cr  = bucket_credit(cp, gv, s, n[t])
      cr += bucket_credit(ca, gv, n[t] - s, n[t])
      return cr / n[t]
    }
    function best_stump(t, lb, which,   i, f, a, best) {
      best = -1
      for (i = 1; i <= nfeat[t]; i++) {
        f = feat[t, i]
        a = stump_loo(t, f, lb)
        if (a > best + 1e-12) { best = a; which[1] = f }
      }
      return best
    }

    BEGIN {
      nl = split(labels, L, " ")
      for (i = 1; i <= nl; i++) labidx[L[i]] = i
    }
    $1 == "ITEM" {
      if (tpl != "" && $3 != tpl) next
      t = $3
      if (!(t in seenT)) { seenT[t] = 1; order[++nt] = t }
      i = ++n[t]
      lab[t, i] = $6
      delete toks
      tokenize($9, toks)
      toks["ask=" $4] = 1
      # Length and token-count buckets. Cut points are fixed rather than
      # per-template quantiles, so no label information reaches the bucketing.
      nt_tok = 0
      for (k in toks) if (k ~ /^has:/) nt_tok++
      for (c = 20; c <= 80; c += 20) if (length($9) >= c) toks["len>=" c] = 1
      for (c = 8; c <= 32; c += 8)   if (nt_tok >= c)     toks["tok>=" c] = 1
      for (k in toks) {
        cnt[t, k]++
        pres[t, k, cnt[t, k]] = i
        npres[t, k] = cnt[t, k]
        if (!((t, k) in known)) { known[t, k] = 1 }
      }
    }
    END {
      # Features constant inside a template carry no information under any
      # classifier. Dropping them is label-independent and it is the whole
      # runtime saving, since = and ( sit in nearly every claim.
      for (key in known) {
        split(key, p, SUBSEP)
        t = p[1]; f = p[2]
        if (npres[t, f] >= n[t]) continue
        feat[t, ++nfeat[t]] = f
      }
      # THE FEATURE LIST IS SORTED, AND IT HAS TO BE. The loop above walks an
      # awk array, whose order is unspecified and differs between gawk and
      # mawk. The best accuracy would come out the same either way, but the
      # NAME the gate reports when two features tie would not, and a gate
      # whose failure message moves with the interpreter is not a gate. Sorted
      # here, the tie goes to the lexicographically first feature.
      for (oi = 1; oi <= nt; oi++) {
        t = order[oi]
        for (i = 2; i <= nfeat[t]; i++) {
          v = feat[t, i]; j = i - 1
          while (j >= 1 && feat[t, j] > v) { feat[t, j + 1] = feat[t, j]; j-- }
          feat[t, j + 1] = v
        }
      }
      flagged = 0
      for (oi = 1; oi <= nt; oi++) {
        t = order[oi]
        if (nfeat[t] + 0 == 0) {
          printf("probe: %s has no usable surface feature at all\n", t) > "/dev/stderr"
          exit 2
        }
        for (i = 1; i <= n[t]; i++) obs[i] = lab[t, i]
        top = 0
        for (j = 1; j <= nl; j++) { v = 0; for (i = 1; i <= n[t]; i++) if (obs[i] == L[j]) v++; if (v > top) top = v }
        b = top / n[t]

        delete which
        o = best_stump(t, obs, which)
        ofeat = which[1]

        # --- the permutation null ------------------------------------------
        lcg_seed(seed + oi * 7919)
        ge = 0
        nullv_n = 0
        for (pp = 1; pp <= perms; pp++) {
          for (i = 1; i <= n[t]; i++) sh[i] = obs[i]
          for (i = n[t]; i > 1; i--) {
            j = int(lcg() * i) + 1
            tmp = sh[i]; sh[i] = sh[j]; sh[j] = tmp
          }
          delete w2
          s = best_stump(t, sh, w2)
          nullv[++nullv_n] = s
          if (s >= o - 1e-12) ge++
        }
        # insertion sort, 1000 elements, so no gawk-only asort
        for (i = 2; i <= nullv_n; i++) {
          v = nullv[i]; j = i - 1
          while (j >= 1 && nullv[j] > v) { nullv[j + 1] = nullv[j]; j-- }
          nullv[j + 1] = v
        }
        k95 = int(0.95 * nullv_n + 0.9999); if (k95 < 1) k95 = 1; if (k95 > nullv_n) k95 = nullv_n
        n95 = nullv[k95]
        pval = (1 + ge) / (perms + 1)
        verdict = (pval <= alpha) ? "ARTIFACT" : "clear"
        if (pval <= alpha) flagged++
        printf("PROBE\t%s\tn=%d\tfeatures=%d\tbase=%.4f\tbest=%.4f\tfeature=%s\tnull95=%.4f\tp=%.4f\tverdict=%s\n",
               t, n[t], nfeat[t], b, o, ofeat, n95, pval, verdict)
        # The probe is only worth running while its own null leaves room for a
        # signal to stand out. A null whose 95th percentile has reached 1.0
        # cannot ever flag anything, which would make this gate vacuous.
        if (n95 >= 0.99999) {
          printf("PROBE-SATURATED\t%s\tnull95=%.4f\n", t, n95)
          sat++
        }
      }
      printf("PROBE-RESULT\t%s\ttemplates=%d\tflagged=%d\tsaturated=%d\tperms=%d\tseed=%d\talpha=%.4f\n",
             (flagged ? "ARTIFACT" : (sat ? "SATURATED" : "clear")), nt, flagged, sat + 0, perms, seed, alpha)
      if (flagged || sat) exit 1
    }
  ' "$ITEMS")"
  rc=$?
  set -e
  [ -n "$out" ] && printf '%s\n' "$out"
  return "$rc"
}

# ---------------------------------------------------------------------------
# argument handling
# ---------------------------------------------------------------------------
[ $# -ge 1 ] || { usage; exit 2; }
SUB="$1"; shift

while [ $# -gt 0 ]; do
  case "$1" in
    --template)    OPT_TEMPLATE="${2:-}"; shift 2 ;;
    --out)         OPT_OUT="${2:-}"; shift 2 ;;
    --predictions) OPT_PRED="${2:-}"; shift 2 ;;
    --items)       ITEMS="${2:-}"; shift 2 ;;
    --alpha)       OPT_ALPHA="${2:-}"; shift 2 ;;
    --perms)       OPT_PERMS="${2:-}"; shift 2 ;;
    --seed)        OPT_SEED="${2:-}"; shift 2 ;;
    --n|--items-n) OPT_ITEMS_N="${2:-}"; shift 2 ;;
    --base)        OPT_BASE="${2:-}"; shift 2 ;;
    --at-power)    OPT_POWER="${2:-}"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *)             die "unknown option: $1" ;;
  esac
done

[ -f "$ITEMS" ] || die "no such items file: $ITEMS"

case "$SUB" in
  emit)   cmd_emit ;;
  reveal) cmd_reveal ;;
  tokens) cmd_tokens ;;
  base)   cmd_base ;;
  power)  cmd_power ;;
  score)  cmd_score ;;
  probe)  cmd_probe ;;
  -h|--help) usage ;;
  *)      die "unknown subcommand: $SUB" ;;
esac
