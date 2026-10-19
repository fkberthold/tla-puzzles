#!/usr/bin/env bash
# test-swipe-reader.sh -- the gate over the published swipe reader (beads
# tla-7xql.12 and tla-7xql.14, epic tla-7xql).
#
# Pins the RED invariant from tla-7xql.14:
#
#   INVARIANT: the published reader serves an item from every shipped level, a
#   level 1 or 2 card shows its model screen with no stripped definition and
#   no obligation, and a model whose screen renders empty is reported rather
#   than served.
#
# and keeps tla-7xql.12's:
#
#   INVARIANT: the published swipe page serves an item from the shipped
#   corpus, records the reader's swipe against the baked verdict, and its
#   source carries neither field 5 nor field 10.
#
# and adds tla-7xql.15's:
#
#   INVARIANT: the resting view draws no premise, the premise is a stack built
#   from what the item carries, each of the five gestures keeps one meaning at
#   every depth, and the three answers are live on every step about the item in
#   the dock and dead on the one that is not.
#
# and tla-7xql.16's:
#
#   INVARIANT: the reader owns the viewport on its own page and gives it back
#   on every other page of the site, the document does not scroll under it, no
#   touch-action sits above either scroller, the contract prose is a page of
#   its own that the reader links to, and forget writes nothing when the reader
#   declines.
#
# and tla-7xql.18's:
#
#   INVARIANT: with v.depth > 0 the rendered root holds exactly one .swipe-step
#   and one .swipe-claim, and no .swipe-card, no .swipe-controls and no
#   .swipe-status.
#
# THAT ONE IS PINNED AS A PREDICATE RATHER THAN AS A COUNT OF ELEMENTS, and the
# difference is worth stating because the predicate is the stronger reading. No
# browser runs here, so nothing can count the elements a state renders. What
# can be driven is the decision: chromeAt() answers which of the three chrome
# slots a state draws, part 6 drives all 24 combinations of depth, panel and
# flash, and part 5 holds render() to obeying every slot the predicate answers.
#
# The claim half was read as text, because which element renderStep() appends
# is not a function.
#
# and tla-7xql.19's, WHICH REVERSES HALF OF THE ONE ABOVE:
#
#   INVARIANT: the step view renders no .swipe-step-claim and the model screen
#   renders no collapse control, and every model screen except 1:Shelves fits
#   its body without vertical overflow at 390x844.
#
# THE REVERSED ASSERTION IS FLIPPED RATHER THAN DELETED, and the one above it
# is left standing with this note beside it, because the pair is the record. D2
# of tla-7xql.18 and its reversal were ruled on the same day, the argument for
# keeping the claim was never refuted, and what beat it was a browser reading
# nobody had taken: the claim cost the model body 133.9 of its 613.9 pixels.
# A deleted assertion would leave the second ruling looking like the only one
# there had ever been.
#
# THE THIRD CONJUNCT IS A GATE OVER WHAT THE READER IS SHOWN rather than over
# what the code computes, and that distinction is the reason it exists. bd
# memory a-gate-over-what-the-code-computes-never-sees records three defects
# Frank found in the recall rung on 2026-10-17 that 339 assertions had not
# seen, all of them about what reached the reader. This suite had 214 and not
# one of them could say whether a model fits the screen it is drawn on.
#
# ===========================================================================
# WHY THIS SUITE EXISTS, AND IT IS NOT "A FILE IS MISSING"
# ===========================================================================
#
# The reader has to publish the baked verdict, because a page with no server
# cannot grade without it. That makes "do not ship the answer" the wrong rule
# and makes the real rule a narrow one: ship the verdict and NOTHING ELSE
# that bears on the answer. At level 0 four fields are out, at the pinned
# rungs five, and the one that matters most at every level is field 10, the
# vacuity witness, which states in TLA+ exactly when the item is vacuous and
# so hands over the down swipe in prose.
#
# The failure this catches is a later author widening the emit. Adding a
# field to swipe/reader/emit-items.sh is a two-word change that nothing else
# in the repo would notice, and the page would go on working perfectly while
# the corpus stopped measuring anything. That is the same shape
# harness/test-swipe-stemblind.sh guards one level down, where the stem file
# carries neither the witness nor the flash.
#
# ===========================================================================
# WHAT IS PERFORMED RATHER THAN ASSERTED
# ===========================================================================
#
# THE ITEM COUNT IS DERIVED TWICE, PER LEVEL. Part 1 counts ITEM rows in each
# corpus with its own scan and requires the payload to agree level by level.
# Nothing below writes 240, 144 or 48.
#
# THE LEAK SCAN HAS A NEGATIVE CONTROL AT EVERY LEVEL. "No witness appears in
# the payload" passes vacuously over a scanner that extracts nothing, which
# is tla-7xql.12's own defect wearing a green tick. So part 2 runs the same
# scan over a payload it has deliberately poisoned with the real witnesses
# and requires every one to be named.
#
# THE SHAPE CHECK HAS A NEGATIVE CONTROL AT EVERY LEVEL for the same reason:
# part 2 feeds each level's selector an item line carrying an extra key and
# requires a refusal.
#
# THE EMPTY-SCREEN RULE IS DRIVEN RATHER THAN READ. Part 2 builds a scratch
# corpus carrying one item about Ring, which is the one reading/ module of 33
# whose screen renders empty, and requires the emitter to drop it, to name it
# on stderr and to declare it in the payload's withheld block. It then runs
# the same corpus against a SCREENS.tsv with no Ring row at all and requires
# the emitter to DIE instead, because that is a stale cache rather than a
# model that cannot be drawn.
#
# THE PUBLISHER IS RUN, NOT READ. Part 3 drives scripts/build-docs.sh in a
# throwaway mini-repo of symlinks, the way harness/test-build-docs-reading.sh
# does, so the real docs/ tree is never touched and the 107-puzzle pass never
# runs. It then builds the SAME mini-repo with no swipe/ in it and requires
# the section to be absent, so part 3's assertions discriminate rather than
# agreeing with themselves.
#
# THE IMPORT CONTRACT AND THE PREMISE STACK ARE EXECUTED where a script
# runtime exists. swipe.js exports its pure halves when a module system is
# present, so part 6 drives the refusal paths and every depth transition
# directly rather than grepping for a message or a shape. Part 6 SKIPS loudly
# where no runtime exists, and part 8 prints the skip count.
#
# The stack is the half of tla-7xql.15 that CAN be executed. Which element
# carries the level tag, what the resting view draws and which hint reaches
# the card are not functions, so part 5 reads those as text and says so.
#
# THE SCREENS ARE RE-RENDERED, and that is the one part of this suite that
# starts a JVM. Part 7 drives swipe/level1/render.sh and swipe/level2/render.sh
# over every model the corpora use and requires swipe/reader/SCREENS.tsv to
# match byte for byte. It writes the normalization again rather than calling
# the generator's copy, so the committed file is compared against two
# independent readings of the same renderer.
#
# `--static` skips part 7 and nothing else. That is the split
# harness/test-drill.sh and harness/test-completion-gate.sh already use, and
# scripts/test registers both rows: the static one in the fast tier, the full
# one in the slow tier where a JVM belongs.
#
# WHAT THIS SUITE CANNOT SEE, and part 8 prints it on every run: nothing here
# runs a browser, so the rendering, the gestures and the navigation.instant
# subscription are checked as text. The LAYOUT is checked as text too, which
# is the weakest thing in this file and is called out in part 5.
#
# THE LAYOUT WAS READ IN A REAL BROWSER ON 2026-10-19, after tla-7xql.14
# merged and against the published site at a true 390x844 viewport. The
# author of that bead could not take the reading, because Chrome would not
# complete a headless load in its sandbox, so the numbers in its merge commit
# are computed from the shipped CSS and marked INFERRED. Two of them were
# wrong and the reading is what settles them.
#
#   the dock is never off screen. Fully visible at scroll 0 and at every
#   position where the premise is in view, at both pinned rungs. 298px at
#   level 1 and 269px at level 2, against a worst case of 384px.
#
#   the worst claim wraps to SIX lines, not the three the bead inferred.
#   Measured over all 432 claims at the shipped font: 156 wrap to 2 lines,
#   206 to 3, 58 to 4, 11 to 5, and L1-E3-37 to 6. So 70 of 432 run to four
#   lines or more where the bead said one did.
#
#   at level 2 the premise did not fit above the dock. The screen is 296px
#   and the pin 327px against 575px of room, so 198px of pin sat BEHIND the
#   dock when the item was drawn. Scrolling reached it, and the reader was not
#   told to. Filed and fixed as tla-7xql.15, which took the premise out of the
#   resting view altogether.
#
# AND THE SCROLL THAT REACHED IT WAS THE NEXT BUG. tla-7xql.16: the listeners
# are { passive: true }, so a vertical drag inside the reader scrolled the page
# AND fired gesture(). Down is "not a claim", so a scroll filed a vacuity
# verdict on a real claim. Driven as a real touch against the published page
# with the document parked at 200px, one downward stroke over the counts took it
# to 0 and wrote one row to the log. The reader owns the viewport now and the
# document has 0px of scroll room, which is read in a browser rather than
# argued, and the numbers are in swipe/README.md.
#
# The dock itself is what survived. It is sticky at the bottom, so where the
# question lands does not depend on anything above it, and that held at every
# item measured.
#
# A localhost run cannot reproduce the instant-navigation
# hazard: the theme matches a clicked link against its sitemap after
# overwriting only the protocol and the hostname, never the port, so instant
# navigation silently declines every link on any local server.
#
# Usage:  harness/test-swipe-reader.sh [--static]
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

STATIC=0
while [ $# -gt 0 ]; do
  case "$1" in
    --static) STATIC=1; shift ;;
    -h|--help) sed -n '/^# Usage:/,/^# Exit:/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "test-swipe-reader.sh: unknown option: $1" >&2; exit 2 ;;
  esac
done

# The levels the reader serves. Derived from the directories rather than
# written here, so a fourth rung is covered the day its corpus lands.
LEVELS="$(find swipe -maxdepth 1 -type d -name 'level*' -print \
  | sed 's#.*/level##' | LC_ALL=C sort -n | tr '\n' ' ')"

EMITTER="$REPO_ROOT/swipe/reader/emit-items.sh"
SCREENGEN="$REPO_ROOT/swipe/reader/render-screens.sh"
SCREENS="$REPO_ROOT/swipe/reader/SCREENS.tsv"
READER_JS="$REPO_ROOT/swipe/reader/swipe.js"
READER_CSS="$REPO_ROOT/swipe/reader/swipe.css"
GENERATOR="$REPO_ROOT/scripts/build-docs.sh"
MKDOCS="$REPO_ROOT/mkdocs.yml"

# The keys a level may publish, in the order emit-items.sh writes them. These
# are the whole contract this suite exists to hold, so they are spelled out
# here and the payload's own `fields` block is checked against them.
#
# A level with no case here prints nothing, and the check below reddens rather
# than skipping. A new rung has to declare what it publishes before it can
# pass, which is the point of the whole file.
keys_for() {
  case "$1" in
    0) printf '%s' "id level template ask swipe claim flash" ;;
    1) printf '%s' "id level template ask swipe claim flash model pin" ;;
    2) printf '%s' "id level template ask swipe claim flash model pre post binds" ;;
    *) printf '%s' "" ;;
  esac
}

# The keys no level may publish. kind is the answer in a sharper form than
# the swipe gives it, rc_claim and rc_wf are level 0's exit codes, rc and
# pin_states are the pinned rungs', and vacuity states the answer in TLA+.
FORBIDDEN_KEYS="kind rc_claim rc_wf rc pin_states vacuity"

pass_count=0
fail_count=0
skip_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
skip() { printf "  SKIP  %s\n" "$1"; skip_count=$((skip_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

TMP_ROOT=$(mktemp -d)
# Reached only through the EXIT trap below. shellcheck does not follow traps,
# so it reads the body as unreachable and raises SC2317.
# shellcheck disable=SC2317
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

echo "test-swipe-reader.sh"
[ "$STATIC" = "1" ] && echo "  (--static: part 7, the screen re-render, is skipped)"
echo ""

if [ -z "$LEVELS" ]; then
  nope "no swipe/level* directory was found, so this run read no corpus at all"
  echo "  $pass_count passed, $fail_count failed"
  exit 1
fi

for f in "$EMITTER" "$SCREENGEN" "$SCREENS" "$READER_JS" "$READER_CSS" "$GENERATOR" "$MKDOCS"; do
  if [ ! -f "$f" ]; then
    nope "a source the reader is built from is missing: ${f#"$REPO_ROOT"/}"
  fi
done
for lvl in $LEVELS; do
  for f in "swipe/level$lvl/ITEMS.tsv" "swipe/level$lvl/TEMPLATES.tsv"; do
    [ -f "$f" ] || nope "a corpus the reader serves is missing: $f"
  done
done
if [ "$fail_count" -gt 0 ]; then
  echo ""
  echo "  $pass_count passed, $fail_count failed"
  exit 1
fi

# ---------------------------------------------------------------------------
# item_lines <payload>
#
# Every line between "items": [ and the close, whatever it looks like.
#
# IT SELECTS ON POSITION RATHER THAN ON SHAPE, and that is a finding rather
# than a preference. The first version of this selector matched /^\s*\{"id":/
# and its own negative control walked straight through it: an item that gained
# a `kind` key AHEAD of the id no longer matched the selector, so it was never
# examined and the run came back clean. A checker that only inspects what
# already looks right is the defect this suite exists to catch, wearing the
# uniform of its own fix.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# find_one <name>
#
# The first path a find turns up, by parameter expansion rather than through
# `| head -1`. A producer piped into an early-exiting consumer returns 141
# under pipefail: head closes the pipe after one line, sort takes SIGPIPE, and
# inside an `if` that reads as a clean false rather than as an error.
# harness/test-pipefail.sh bans the idiom across the tree and caught four
# sites in this file.
# ---------------------------------------------------------------------------
find_one() {
  local hits
  hits="$(find reading -name "$1" -type f | LC_ALL=C sort)"
  [ -n "$hits" ] || return 0
  printf '%s\n' "${hits%%$'\n'*}"
}

item_lines() {
  awk '
    /^[[:space:]]*"items": \[/ { inside = 1; next }
    inside && /^[[:space:]]*\],?[[:space:]]*$/ { inside = 0; next }
    inside && /[^[:space:]]/ { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# shape_errors <payload>
#
# One line per item line whose key set is not exactly one level's, in order.
# The regex pins the ORDER as well as the SET, which is what lets one check
# stand in for both. The three level regexes are disjoint, because each one
# requires its own `"level": N` literal, so trying all three is not a
# weakening.
#
# Values are matched with [^"]* rather than with an escape-aware pattern,
# which is sound because emit-items.sh writes every quote in a value as a
# \u0022 escape. Part 1 proves that separately by round-tripping every value
# against the corpus, so the two checks are not resting on each other.
# ---------------------------------------------------------------------------
shape_errors() {
  item_lines "$1" | awk '
    BEGIN {
      arr = "\\[(\"[^\"]*\"(, \"[^\"]*\")*)?\\]"
      base = "^[[:space:]]*\\{\"id\": \"[^\"]*\", \"level\": %s, \"template\": \"[^\"]*\"" \
             ", \"ask\": \"[^\"]*\", \"swipe\": \"[^\"]*\", \"claim\": \"[^\"]*\"" \
             ", \"flash\": \"[^\"]*\""
      tail = "\\},?$"
      b0 = base; sub(/%s/, "0", b0)
      b1 = base; sub(/%s/, "1", b1)
      b2 = base; sub(/%s/, "2", b2)
      re[0] = b0 tail
      re[1] = b1 ", \"model\": \"[^\"]*\", \"pin\": " arr tail
      re[2] = b2 ", \"model\": \"[^\"]*\", \"pre\": " arr ", \"post\": " arr \
              ", \"binds\": " arr tail
      n = 0
    }
    {
      n += 1
      if ($0 ~ re[0] || $0 ~ re[1] || $0 ~ re[2]) next
      print "line " NR ": " substr($0, 1, 100)
    }
    END { if (n == 0) print "line 0: no item lines at all" }
  '
}

# ---------------------------------------------------------------------------
# strip_pins <payload>
#
# The payload with every pin block removed. pin, pre, post and binds are the
# last keys on an item line, so everything from `, "pin": ` or `, "pre": ` to
# the end of the line is the pin.
#
# THE LEAK SCAN NEEDS THIS AND THE REASON IS NOT TIDINESS. A vacuous level 1
# item is vacuous BECAUSE of its pin, so its witness is routinely a conjunct
# of the pin verbatim: L1-E1-44's witness is `a = 0` and its pin is
# `a = 0 /\ b = 0 /\ c = 2`. The pin ships by ruling, so a witness made of
# pin text gives nothing away that the question did not already give. Two of
# the 46 witnesses are in that position and both were measured, not assumed.
#
# Stripping by position keeps the negative control sharp. Exempting a witness
# because it is a substring of its own pin would exempt a PLANTED one too,
# and the control plants exactly those.
#
# This relies on the key order, which the shape check above pins
# independently. If the order moved, the shape check reddens first.
# ---------------------------------------------------------------------------
strip_pins() {
  sed -e 's/, "pin": .*$/}/' -e 's/, "pre": .*$/}/' "$1"
}

# ---------------------------------------------------------------------------
# witness_leaks <level> <payload>
#
# One line per vacuity witness from field 10 of that level's corpus that
# appears anywhere in the payload. A witness holds exactly when the item is
# vacuous, so one in the payload is the down swipe given away in TLA+.
#
# The scan reads the RAW payload rather than the unescaped values, so the
# witness is hunted in its escaped form as well.
# ---------------------------------------------------------------------------
witness_leaks() {
  local lvl="$1" payload="$2"
  awk -F'\t' -v payload="$payload" '
    function esc(s,   i, n, c, out) {
      out = ""
      n = length(s)
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if      (c == "\\") out = out "\\u005c"
        else if (c == "\"") out = out "\\u0022"
        else if (c == "<")  out = out "\\u003c"
        else if (c == ">")  out = out "\\u003e"
        else if (c == "&")  out = out "\\u0026"
        else                out = out c
      }
      return out
    }
    BEGIN {
      body = ""
      while ((getline line < payload) > 0) { body = body line "\n" }
      close(payload)
    }
    $1 == "ITEM" && $10 != "-" && $10 != "" {
      if (index(body, $10) > 0)           { print $2 " :: " $10 }
      else if (index(body, esc($10)) > 0) { print $2 " (escaped) :: " $10 }
    }
  ' "swipe/level$lvl/ITEMS.tsv"
}

# ---------------------------------------------------------------------------
# roundtrip_errors <level> <payload>
#
# One line per item whose claim or flash in the payload differs by one byte
# from the corpus, and one per id in one and not the other. The \uXXXX escapes
# emit-items.sh writes are undone here rather than read past, so an escaper
# that mangled a backslash shows up as a mismatch.
#
# 100 of the 240 level 0 claims carry a backslash and 14 carry a double quote,
# and a pin is TLA+ throughout, so this is the check that says the escaping is
# right rather than merely present.
# ---------------------------------------------------------------------------
roundtrip_errors() {
  local lvl="$1" payload="$2"
  awk -v payload="$payload" -v lvl="$lvl" '
    function unesc(s) {
      gsub(/\\u0022/, "\"", s)
      gsub(/\\u003c/, "<",  s)
      gsub(/\\u003e/, ">",  s)
      gsub(/\\u0026/, "&",  s)
      gsub(/\\u0009/, "\t", s)
      gsub(/\\u005c/, "\\", s)
      return s
    }
    function field(line, key,   v) {
      if (!match(line, "\"" key "\": \"[^\"]*\"")) return "\001missing"
      v = substr(line, RSTART, RLENGTH)
      sub("^\"" key "\": \"", "", v)
      sub("\"$", "", v)
      return unesc(v)
    }
    BEGIN { FS = "\t" }
    FNR == NR {
      if ($1 == "ITEM") { claim[$2] = $9; flash[$2] = $11; want[$2] = 1; nwant += 1 }
      next
    }
    $0 ~ ("\"level\": " lvl ",") {
      id = field($0, "id")
      got[id] = 1
      ngot += 1
      if (!(id in want)) { print "payload has an id level " lvl " does not: " id; next }
      c = field($0, "claim")
      f = field($0, "flash")
      if (c != claim[id]) { print id " claim differs:\n    payload: " c "\n    corpus:  " claim[id] }
      if (f != flash[id]) { print id " flash differs:\n    payload: " f "\n    corpus:  " flash[id] }
    }
    END {
      for (id in want) { if (!(id in got)) print "level " lvl " has an id the payload does not: " id }
      if (ngot == 0) print "the payload carried no level " lvl " items, so nothing was compared"
      if (nwant == 0) print "level " lvl " carried no ITEM rows, so nothing was compared"
    }
  ' "swipe/level$lvl/ITEMS.tsv" "$payload"
}

# ---------------------------------------------------------------------------
# pin_errors <level> <payload>
#
# One line per item whose pin arrays do not rejoin to the corpus field they
# came from. The splitter is written here rather than borrowed from the
# emitter, so the two are independent readings of the same rule: a conjunction
# list splits on /\ with any surrounding whitespace, and a bind list splits on
# a comma.
# ---------------------------------------------------------------------------
pin_errors() {
  local lvl="$1" payload="$2"
  awk -v payload="$payload" -v lvl="$lvl" '
    function unesc(s) {
      gsub(/\\u0022/, "\"", s)
      gsub(/\\u003c/, "<",  s)
      gsub(/\\u003e/, ">",  s)
      gsub(/\\u0026/, "&",  s)
      gsub(/\\u005c/, "\\", s)
      return s
    }
    # The JSON array under one key, rejoined with the separator its source
    # used.
    #
    # THE ARRAY IS CUT BY ITS CLOSING DELIMITER RATHER THAN BY [^]]*, and that
    # is a bug this function already had once. A level 2 pre-state reads
    # `ticket = [q \in Player |-> Nil]`, so the first `]` on the line is
    # INSIDE a value and a greedy-free pattern stops there. The delimiter that
    # works is the literal text that follows the array, which a TLA+ conjunct
    # can never contain.
    #
    # THE CLOSING DELIMITER IS SEARCHED FOR FROM THE ARRAY ONWARDS, which is
    # the second half of the same bug. The claim of L1-E1-23 reads
    # `\A p \in {q \in Player : playing[q]} : ENABLED Stop(p)`, so `]}` occurs
    # in the CLAIM, ahead of the pin, and a search from the start of the line
    # lands there.
    #
    # Note for a later editor: this whole program sits in a single-quoted
    # shell string, so an apostrophe anywhere in it, including in a comment,
    # ends the quote and the shell reports a syntax error 15 lines further
    # down. Write around it.
    function arr(line, key, nextkey, sep,   open, s, e, v, n, parts, i, out) {
      open = "\"" key "\": ["
      s = index(line, open)
      if (s == 0) return "\001missing"
      s += length(open)
      e = (nextkey == "") \
            ? index(substr(line, s), "]}") \
            : index(substr(line, s), "], \"" nextkey "\": [")
      if (e == 0) return "\001unterminated"
      e += s - 1
      v = substr(line, s, e - s)
      if (v == "") return ""
      n = split(v, parts, "\", \"")
      out = ""
      for (i = 1; i <= n; i++) {
        gsub(/^"|"$/, "", parts[i])
        out = out (i > 1 ? sep : "") unesc(parts[i])
      }
      return out
    }
    function norm_conj(s,   n, parts, i, out) {
      gsub(/[ \t]*\/[\\][ \t]*/, "\001", s)
      n = split(s, parts, "\001")
      out = ""
      for (i = 1; i <= n; i++) {
        if (parts[i] == "") continue
        out = out (out == "" ? "" : " /\\ ") parts[i]
      }
      return out
    }
    function norm_binds(s,   n, parts, i, out) {
      if (s == "-" || s == "") return ""
      n = split(s, parts, ",")
      out = ""
      for (i = 1; i <= n; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", parts[i])
        if (parts[i] == "") continue
        out = out (out == "" ? "" : ", ") parts[i]
      }
      return out
    }
    BEGIN { FS = "\t" }
    FNR == NR {
      if ($1 != "ITEM") next
      if (lvl == 1) { a[$2] = norm_conj($13); want[$2] = 1 }
      else          { a[$2] = norm_conj($13); b[$2] = norm_conj($14); c[$2] = norm_binds($15); want[$2] = 1 }
      next
    }
    $0 ~ ("\"level\": " lvl ",") {
      if (!match($0, "\"id\": \"[^\"]*\"")) next
      id = substr($0, RSTART + 7, RLENGTH - 8)
      seen[id] = 1
      if (lvl == 1) {
        got = arr($0, "pin", "", " /\\ ")
        if (got != a[id]) print id " pin differs:\n    payload: " got "\n    corpus:  " a[id]
      } else {
        got = arr($0, "pre", "post", " /\\ ")
        if (got != a[id]) print id " pre differs:\n    payload: " got "\n    corpus:  " a[id]
        got = arr($0, "post", "binds", " /\\ ")
        if (got != b[id]) print id " post differs:\n    payload: " got "\n    corpus:  " b[id]
        got = arr($0, "binds", "", ", ")
        if (got != c[id]) print id " binds differ:\n    payload: " got "\n    corpus:  " c[id]
      }
    }
    END {
      nseen = 0
      for (id in seen) nseen += 1
      if (nseen == 0) print "no level " lvl " item line was examined, so nothing was compared"
    }
  ' "swipe/level$lvl/ITEMS.tsv" "$payload"
}

# ---------------------------------------------------------------------------
# screens_of <payload>
#
# One line per published screen: <level>:<model> <tab> <line count>, with the
# text dropped. Used wherever a count is wanted rather than the screen.
# ---------------------------------------------------------------------------
screens_of() {
  awk '
    /^[[:space:]]*"screens": \{/ { inside = 1; next }
    inside && /^[[:space:]]*\},?[[:space:]]*$/ { inside = 0; next }
    inside && match($0, /"[0-9]+:[A-Za-z0-9_]+": "/) {
      key = substr($0, RSTART + 1, RLENGTH - 5)
      n = gsub(/\\u000a/, "&")
      print key "\t" (n + 1)
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# screen_text <payload> <level:model>
#
# One published screen, with the \u000a line breaks turned back into lines and
# the five value escapes undone.
# ---------------------------------------------------------------------------
screen_text() {
  awk -v want="$2" '
    function unesc(s) {
      gsub(/\\u0022/, "\"", s)
      gsub(/\\u003c/, "<",  s)
      gsub(/\\u003e/, ">",  s)
      gsub(/\\u0026/, "&",  s)
      gsub(/\\u0009/, "\t", s)
      gsub(/\\u005c/, "\\", s)
      return s
    }
    /^[[:space:]]*"screens": \{/ { inside = 1; next }
    inside && /^[[:space:]]*\},?[[:space:]]*$/ { inside = 0; next }
    inside && index($0, "\"" want "\": \"") > 0 {
      v = $0
      sub(/^[[:space:]]*"[^"]*": "/, "", v)
      sub(/",?$/, "", v)
      gsub(/\\u000a/, "\n", v)
      print unesc(v)
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# WHAT THE READER IS SHOWN AT 390x844, AND THE ONLY PLACE THESE PIXELS LIVE
#
# Every figure here was read in Chrome at a true 390x844 against the published
# build on 2026-10-19, under bead tla-7xql.19, with the model step open on
# 1:Fences. They are a browser reading rather than arithmetic off the
# stylesheet, and nothing in this suite can re-derive them, because no browser
# runs here.
#
#   SCREEN_LINE_PX           the line box of one line of .swipe-screen-body
#   SCREEN_PAD_PX            its bottom padding, 0.6rem at 20px to the rem
#   SCREEN_BODY_PX           the body's own height with no claim at the foot
#   SCREEN_BODY_CLAIMED_PX   the same height while the claim was still drawn
#
# WHAT INVALIDATES THEM, and this is the paragraph for whoever changes the type
# size: the font size or the line height on .swipe-screen-body, the padding on
# it, the theme's rem, anything that changes what a step draws around the body,
# and the viewport. Every one of those moves a number here, and none of them
# reddens an assertion on its own. Re-read them in a browser rather than
# recomputing them, because the chrome around the body is the theme's.
#
# THE TWO BODY HEIGHTS ARE A BEFORE AND AN AFTER, and both are kept on purpose.
# tla-7xql.18 drew the claim at the foot of the step and tla-7xql.19 took it
# back out, which returned 133.9 pixels to the model. The pair is what makes
# the fit scan below discriminate: a line count that came back wrong would
# report the same overflow set at either height, and the two differ by four
# screens.
# ---------------------------------------------------------------------------
SCREEN_LINE_PX=21.28
SCREEN_PAD_PX=12
SCREEN_BODY_PX=613.9
SCREEN_BODY_CLAIMED_PX=480.0

# The one screen Frank ruled stays scrolling, and its line count. 29 lines want
# 629.1 pixels against 613.9, so it is over by about 15 and scrolls a little.
# The line count is pinned because the heights above were read against THIS
# corpus: a shorter Shelves makes them a reading of something else.
SCREEN_TALLEST="1:Shelves"
SCREEN_TALLEST_LINES=29

# How many of the 24 published screens overflow at each height. Central's
# reading over the whole payload, not a number this file picked.
SCREEN_OVER_N=1
SCREEN_OVER_CLAIMED_N=5

# ---------------------------------------------------------------------------
# screens_over <payload> <body height in pixels>
#
# One line per screen whose rendered height exceeds that body height:
# <level:model> <tab> <lines> <tab> <height>, tallest first.
#
# THE HEIGHT IS THE LINE COUNT AND NOTHING ELSE, because .swipe-screen-body is
# `white-space: pre`. A line wider than the body scrolls sideways instead of
# wrapping, so no width can add a row, and that is the whole reason this is
# computable with no browser. A body that wrapped would need one.
# ---------------------------------------------------------------------------
screens_over() {
  screens_of "$1" | awk -F'\t' -v body="$2" -v lh="$SCREEN_LINE_PX" -v pad="$SCREEN_PAD_PX" '
    { h = $2 * lh + pad; if (h > body) printf "%s\t%d\t%.1f\n", $1, $2, h }
  ' | LC_ALL=C sort -k2,2nr
}

# ===========================================================================
# PART 1 -- the payload is the corpus, the published fields of it
# ===========================================================================
echo "Part 1: the payload is every corpus, the published fields of it"

PAYLOAD="$TMP_ROOT/items.json"
if "$EMITTER" > "$PAYLOAD" 2> "$TMP_ROOT/emit.err"; then
  ok "swipe/reader/emit-items.sh runs"
else
  nope "swipe/reader/emit-items.sh failed: $(head -2 "$TMP_ROOT/emit.err")"
fi

if [ "$(sed -n 's/^[[:space:]]*"payload_version": \([0-9][0-9]*\).*$/\1/p' "$PAYLOAD")" = "2" ]; then
  ok "the payload declares format version 2"
else
  nope "the payload does not declare payload_version 2, so the reader would refuse it"
fi

# THE LEVEL SET IS DERIVED FROM THE TREE. A corpus directory that no level of
# the payload serves is the failure tla-7xql.14 exists to close, so the check
# is over the directories rather than over a list in this file.
declared_levels="$(sed -n 's/^[[:space:]]*"levels": \[\(.*\)\],*$/\1/p' "$PAYLOAD" | tr -d ' ' | tr ',' ' ')"
want_levels="$(printf '%s' "$LEVELS" | tr -s ' ' | sed 's/ $//')"
got_levels="$(printf '%s' "$declared_levels" | tr -s ' ' | sed 's/ $//')"
if [ "$got_levels" = "$want_levels" ]; then
  ok "the payload serves every swipe/level* directory in the tree ($got_levels)"
else
  nope "swipe/ carries levels [$want_levels] and the payload declares [$got_levels]"
fi

total_corpus=0
for lvl in $LEVELS; do
  corpus_n=$(grep -c '^ITEM' "swipe/level$lvl/ITEMS.tsv")
  payload_n=$(grep -c "\"level\": $lvl," "$PAYLOAD")
  total_corpus=$((total_corpus + corpus_n))
  if [ "$payload_n" = "$corpus_n" ]; then
    ok "level $lvl: the payload carries one item per corpus row ($corpus_n)"
  else
    nope "level $lvl: the payload carries $payload_n items and the corpus has $corpus_n rows"
  fi
done

declared_n=$(sed -n 's/^[[:space:]]*"count": \([0-9][0-9]*\).*$/\1/p' "$PAYLOAD")
withheld_n=$(sed -n 's/^[[:space:]]*"withheld_items": \([0-9][0-9]*\).*$/\1/p' "$PAYLOAD")
if [ "$declared_n" = "$total_corpus" ] && [ "$withheld_n" = "0" ]; then
  ok "the payload's own count agrees across every level ($declared_n), with nothing withheld"
else
  nope "the payload declares count $declared_n and withheld_items $withheld_n against $total_corpus corpus rows"
fi

if [ "$total_corpus" -ge 400 ]; then
  ok "the corpora are at full size, so this run is not passing over a stub ($total_corpus)"
else
  nope "only $total_corpus ITEM rows were read across every level, below the floor of 400"
fi

shape_out=$(shape_errors "$PAYLOAD")
if [ -z "$shape_out" ]; then
  ok "every item carries exactly its level's published fields, in order"
else
  nope "item lines with the wrong field set:"
  head -5 <<<"$shape_out" | sed 's/^/          /'
fi

# The payload declares its own field list per level, and this is where that
# declaration is held to the contract spelled out at the top of this file.
for lvl in $LEVELS; do
  want_keys="$(keys_for "$lvl")"
  got_keys=$(sed -n "s/^[[:space:]]*\"$lvl\": \[\(.*\)\],*$/\1/p" "$PAYLOAD" | tr -d '", ')
  if [ -z "$want_keys" ]; then
    nope "level $lvl publishes items and keys_for() in this suite does not say what it may publish"
  elif [ "$got_keys" = "$(printf '%s' "$want_keys" | tr -d ' ')" ]; then
    ok "level $lvl: the payload's own fields header lists exactly its published keys"
  else
    nope "level $lvl: the fields header reads [$got_keys], wanted [$want_keys]"
  fi
done

for lvl in $LEVELS; do
  rt_out=$(roundtrip_errors "$lvl" "$PAYLOAD")
  if [ -z "$rt_out" ]; then
    ok "level $lvl: every claim and every flash round-trips byte for byte"
  else
    nope "level $lvl: claims or flashes that differ from the corpus:"
    head -6 <<<"$rt_out" | sed 's/^/          /'
  fi
done

for lvl in $LEVELS; do
  [ "$lvl" = "0" ] && continue
  pin_out=$(pin_errors "$lvl" "$PAYLOAD")
  if [ -z "$pin_out" ]; then
    ok "level $lvl: every pin rejoins to the corpus field it was split from"
  else
    nope "level $lvl: pins that differ from the corpus:"
    head -6 <<<"$pin_out" | sed 's/^/          /'
  fi
done

empty_n=$(grep -cE '"(claim|flash)": ""' "$PAYLOAD")
if [ "$empty_n" = "0" ]; then
  ok "no item ships with an empty claim or an empty flash"
else
  nope "$empty_n items ship with an empty claim or flash"
fi

bad_swipe=$(grep -c '"swipe": "' "$PAYLOAD")
good_swipe=$(grep -cE '"swipe": "(right|left|down)"' "$PAYLOAD")
if [ "$bad_swipe" = "$good_swipe" ] && [ "$good_swipe" = "$total_corpus" ]; then
  ok "every baked verdict is right, left or down ($good_swipe)"
else
  nope "$good_swipe of $bad_swipe swipes are right, left or down, over $total_corpus rows"
fi

dup_n=$(grep -o '{"id": "[^"]*"' "$PAYLOAD" | sort | uniq -d | wc -l)
if [ "$dup_n" = "0" ]; then
  ok "no id is published twice, across every level"
else
  nope "$dup_n ids are published more than once"
fi

echo ""

# ===========================================================================
# PART 2 -- the fields that may not ship, and the controls that say so
# ===========================================================================
echo "Part 2: the withheld fields, the empty screen, and the controls"

key_hits=""
for k in $FORBIDDEN_KEYS; do
  if grep -qE "\"$k\"[[:space:]]*:" "$PAYLOAD"; then
    key_hits="$key_hits $k"
  fi
done
if [ -z "$key_hits" ]; then
  ok "the payload carries no key named $(printf '%s' "$FORBIDDEN_KEYS" | tr ' ' ',')"
else
  nope "the payload carries a forbidden key:$key_hits"
fi

NOPIN="$TMP_ROOT/nopin.json"
strip_pins "$PAYLOAD" > "$NOPIN"
# The strip has to remove the pins and keep everything else, or the scan below
# reads a shorter file and finds less by construction.
if [ "$(grep -c '"claim"' "$NOPIN")" -ge "$total_corpus" ] && [ "$(grep -c '"pin": \[' "$NOPIN")" = "0" ]; then
  ok "the pin strip removed every pin block and kept every claim"
else
  nope "the pin strip left $(grep -c '"pin": \[' "$NOPIN") pin blocks and $(grep -c '"claim"' "$NOPIN") claims"
fi

for lvl in $LEVELS; do
  n_wit=$(awk -F'\t' '$1 == "ITEM" && $10 != "-" && $10 != "" { n += 1 } END { print n + 0 }' "swipe/level$lvl/ITEMS.tsv")
  leak_out=$(witness_leaks "$lvl" "$NOPIN")
  if [ -z "$leak_out" ]; then
    ok "level $lvl: none of its $n_wit vacuity witnesses reaches the payload"
  else
    nope "level $lvl: vacuity witnesses in the payload:"
    head -5 <<<"$leak_out" | sed 's/^/          /'
  fi

  # THE NEGATIVE CONTROL FOR THE LEAK SCAN. Poison a copy with the real
  # witnesses and require every one to be named. Without this the scan above
  # is "a scanner that finds nothing reports nothing wrong".
  POISON="$TMP_ROOT/poisoned-$lvl.json"
  cp "$NOPIN" "$POISON"
  awk -F'\t' '$1 == "ITEM" && $10 != "-" && $10 != "" { print "    {\"vacuity\": \"" $10 "\"}," }' \
    "swipe/level$lvl/ITEMS.tsv" >> "$POISON"
  poison_out=$(witness_leaks "$lvl" "$POISON")
  poison_n=$(grep -c '::' <<<"$poison_out")
  if [ "$n_wit" -gt 0 ] && [ "$poison_n" = "$n_wit" ]; then
    ok "level $lvl: the leak scan names all $n_wit witnesses when they are planted"
  else
    nope "level $lvl: the leak scan found $poison_n of $n_wit planted witnesses, so it does not discriminate"
  fi
done

# THE NEGATIVE CONTROL FOR THE SHAPE CHECK, ONE PER LEVEL. An item line that
# gained a key ahead of its id. The key is inserted first rather than last on
# purpose: that is the position the first version of the selector could not
# see.
for lvl in $LEVELS; do
  WIDENED="$TMP_ROOT/widened-$lvl.json"
  awk -v lvl="$lvl" '
    !done && $0 ~ ("\"level\": " lvl ",") {
      sub(/\{"id":/, "{\"kind\": \"vacuous\", \"id\":")
      done = 1
    }
    { print }
  ' "$PAYLOAD" > "$WIDENED"
  if [ -n "$(shape_errors "$WIDENED")" ]; then
    ok "level $lvl: the shape check refuses an item that gained a kind field"
  else
    nope "level $lvl: the shape check passed an item carrying a kind field, so it does not discriminate"
  fi
done

# ---------------------------------------------------------------------------
# THE EMPTY-SCREEN RULE, DRIVEN. Ring is the one reading/ module of 33 whose
# screen renders empty, because its actions live in the PlusCal translation
# block under names the shown-roots rule does not reach. No shipped item is
# about it, so the rule is exercised against a scratch corpus carrying one.
# ---------------------------------------------------------------------------
EMPTY_MODEL="$(awk -F'\t' '$1 == "EMPTY" && $2 == "1" { print $3; exit }' "$SCREENS")"
if [ -z "$EMPTY_MODEL" ]; then
  # The generator only writes an EMPTY row for a model the corpus uses, so the
  # committed file carries none today. Find one the renderer refuses.
  EMPTY_MODEL="Ring"
fi

SCRATCH="$TMP_ROOT/corpus"
for lvl in $LEVELS; do
  mkdir -p "$SCRATCH/level$lvl"
  cp "swipe/level$lvl/ITEMS.tsv" "$SCRATCH/level$lvl/ITEMS.tsv"
  cp "swipe/level$lvl/TEMPLATES.tsv" "$SCRATCH/level$lvl/TEMPLATES.tsv"
done
grep -m1 '^ITEM' "swipe/level1/ITEMS.tsv" \
  | awk -F'\t' -v OFS='\t' -v m="$EMPTY_MODEL" '{ $2 = "L1-XX-99"; $12 = m; print }' \
  >> "$SCRATCH/level1/ITEMS.tsv"

WITH_EMPTY="$TMP_ROOT/screens-with-empty.tsv"
grep -v "^EMPTY	1	$EMPTY_MODEL	" "$SCREENS" > "$WITH_EMPTY"
printf 'EMPTY\t1\t%s\tthe shown-roots rule reaches no definition, so the screen renders empty\n' \
  "$EMPTY_MODEL" >> "$WITH_EMPTY"

if "$EMITTER" --root "$SCRATCH" --screens "$WITH_EMPTY" \
     > "$TMP_ROOT/withheld.json" 2> "$TMP_ROOT/withheld.err"; then
  ok "the emitter still publishes when a model's screen renders empty"
else
  nope "the emitter failed outright on an empty screen: $(head -2 "$TMP_ROOT/withheld.err")"
fi
if grep -q 'L1-XX-99' "$TMP_ROOT/withheld.json"; then
  nope "an item about a model with no screen was SERVED, which is a pin and a claim with no premise"
else
  ok "an item about a model with no screen is not served"
fi
if grep -qE "WITHHELD 1 item\(s\) about $EMPTY_MODEL" "$TMP_ROOT/withheld.err"; then
  ok "the emitter reports the withheld item on stderr, naming the model"
else
  nope "stderr does not name the withheld item, so the build log would say nothing"
fi
if grep -q "\"model\": \"$EMPTY_MODEL\", \"items\": 1" "$TMP_ROOT/withheld.json" \
   && [ "$(sed -n 's/^[[:space:]]*"withheld_items": \([0-9][0-9]*\).*$/\1/p' "$TMP_ROOT/withheld.json")" = "1" ]; then
  ok "the payload's withheld block names the model and counts its items"
else
  nope "the payload carries no withheld entry for $EMPTY_MODEL, so the page could not say so"
fi

# THE STALE-CACHE CONTROL. The same corpus against a SCREENS.tsv with no row
# for the model at all. That is the generator not having been re-run, and
# withholding items for it would be a silent corpus shrink, so the emitter has
# to die instead.
if "$EMITTER" --root "$SCRATCH" --screens "$SCREENS" \
     > /dev/null 2> "$TMP_ROOT/stale.err"; then
  nope "the emitter published over a SCREENS.tsv with no row for $EMPTY_MODEL, so a stale cache shrinks the corpus in silence"
else
  if grep -q 'Re-run swipe/reader/render-screens.sh' "$TMP_ROOT/stale.err"; then
    ok "a model with neither a screen nor an EMPTY row kills the emit and names the fix"
  else
    nope "the emitter died on a stale cache without naming render-screens.sh: $(head -1 "$TMP_ROOT/stale.err")"
  fi
fi

echo ""

# ===========================================================================
# PART 3 -- the model screens carry no obligation and no machine
# ===========================================================================
echo "Part 3: the screens honor D2 and D7"

screen_rows="$(screens_of "$PAYLOAD")"
screen_count=$(grep -c . <<<"$screen_rows")

# Every model a pinned item names has a screen, and every screen is named by
# an item. The second half is what keeps the payload from carrying a screen
# nobody can reach, which is 10 KB of a phone's download for nothing.
want_keys_file="$TMP_ROOT/want-screens"
: > "$want_keys_file"
for lvl in $LEVELS; do
  [ "$lvl" = "0" ] && continue
  awk -F'\t' -v lvl="$lvl" '$1 == "ITEM" { print lvl ":" $12 }' "swipe/level$lvl/ITEMS.tsv" >> "$want_keys_file"
done
LC_ALL=C sort -u "$want_keys_file" -o "$want_keys_file"
got_keys_file="$TMP_ROOT/got-screens"
cut -f1 <<<"$screen_rows" | LC_ALL=C sort -u > "$got_keys_file"
if diff -q "$want_keys_file" "$got_keys_file" > /dev/null 2>&1; then
  ok "the payload publishes exactly the $screen_count screens the corpora reach"
else
  nope "the published screens do not match the models the corpora name:"
  diff "$want_keys_file" "$got_keys_file" > "$TMP_ROOT/screens.diff" 2>&1 || true
  sed -n "1,6p" "$TMP_ROOT/screens.diff" | sed "s/^/          /"
fi

blank_screens=$(awk -F'\t' '$2 + 0 < 1 { n += 1 } END { print n + 0 }' <<<"$screen_rows")
if [ "$screen_count" -gt 0 ] && [ "$blank_screens" = "0" ]; then
  ok "no published screen is empty, which is the rule the withheld block enforces"
else
  nope "$blank_screens of $screen_count published screens carry no line"
fi

# ---------------------------------------------------------------------------
# D2: the model is shown with its INVARIANT and PROPERTY declarations
# stripped. D7: it does not show Init, Next, Spec or the fairness conjunct.
#
# The obligation names come from the model's own .cfg, so this needs no JVM
# and no renderer. It is the half of the shown-roots rule that can be checked
# from text, and part 6 ties the committed screens to the renderer the other
# two swipe suites gate.
# ---------------------------------------------------------------------------
d2_out="$TMP_ROOT/d2.out"
: > "$d2_out"
while IFS=$'\t' read -r key _; do
  [ -n "$key" ] || continue
  model="${key#*:}"
  cfg="$(find_one "$model.cfg")"
  if [ -z "$cfg" ]; then
    printf '%s: no .cfg beside the module, so its obligations could not be read\n' "$key" >> "$d2_out"
    continue
  fi
  screen_text "$PAYLOAD" "$key" > "$TMP_ROOT/screen.txt"
  awk -v key="$key" -v cfg="$cfg" '
    # The obligation and specification names the .cfg declares. A keyword may
    # carry its names on the same line or on the lines under it, so the block
    # runs until the next keyword.
    BEGIN {
      while ((getline line < cfg) > 0) {
        sub(/\\\*.*$/, "", line)
        if (line ~ /^[[:space:]]*(INVARIANTS?|PROPERTIES|PROPERTY|SPECIFICATION)([[:space:]]|$)/) {
          sub(/^[[:space:]]*[A-Z]+[[:space:]]*/, "", line)
          inb = 1
        } else if (line ~ /^[[:space:]]*[A-Z_]+[[:space:]]/) {
          inb = 0
          continue
        }
        if (!inb) continue
        nf = split(line, w, /[[:space:]]+/)
        for (i = 1; i <= nf; i++) if (w[i] ~ /^[A-Za-z_][A-Za-z0-9_!]*$/) bad[w[i]] = 1
      }
      close(cfg)
      bad["Init"] = 1; bad["Next"] = 1; bad["Spec"] = 1
    }
    # A definition on the screen starts at column 0 and carries ==.
    /^[A-Za-z_][A-Za-z0-9_]*[ \t]*(\([^)]*\))?[ \t]*==/ {
      name = $0
      sub(/[ \t]*(\([^)]*\))?[ \t]*==.*$/, "", name)
      if (name in bad) print key ": the screen defines " name ", which D2 or D7 withholds"
    }
    /(WF_|SF_)/ { print key ": the screen carries a fairness conjunct, which D7 withholds" }
  ' "$TMP_ROOT/screen.txt" >> "$d2_out"
done <<<"$screen_rows"

if [ ! -s "$d2_out" ]; then
  ok "no screen defines an obligation its .cfg declares, nor Init, Next, Spec or a fairness conjunct"
else
  nope "screens carrying something D2 or D7 withholds:"
  head -6 "$d2_out" | sed 's/^/          /'
fi

# THE CONTROL. The same scan over the UNSTRIPPED modules has to find plenty,
# or "no obligation on the screen" is a scanner that reads nothing.
ctrl_hits=0
while IFS=$'\t' read -r key _; do
  [ -n "$key" ] || continue
  model="${key#*:}"
  tla="$(find_one "$model.tla")"
  cfg="${tla%.tla}.cfg"
  if [ ! -f "$tla" ] || [ ! -f "$cfg" ]; then
    continue
  fi
  hits=$(awk -v cfg="$cfg" '
    BEGIN {
      while ((getline line < cfg) > 0) {
        sub(/\\\*.*$/, "", line)
        if (line ~ /^[[:space:]]*(INVARIANTS?|PROPERTIES|PROPERTY|SPECIFICATION)([[:space:]]|$)/) {
          sub(/^[[:space:]]*[A-Z]+[[:space:]]*/, "", line); inb = 1
        } else if (line ~ /^[[:space:]]*[A-Z_]+[[:space:]]/) { inb = 0; continue }
        if (!inb) continue
        nf = split(line, w, /[[:space:]]+/)
        for (i = 1; i <= nf; i++) if (w[i] ~ /^[A-Za-z_][A-Za-z0-9_!]*$/) bad[w[i]] = 1
      }
      close(cfg)
      bad["Init"] = 1; bad["Next"] = 1; bad["Spec"] = 1
    }
    /^[A-Za-z_][A-Za-z0-9_]*[ \t]*(\([^)]*\))?[ \t]*==/ {
      name = $0
      sub(/[ \t]*(\([^)]*\))?[ \t]*==.*$/, "", name)
      if (name in bad) n += 1
    }
    END { print n + 0 }
  ' "$tla")
  ctrl_hits=$((ctrl_hits + hits))
done <<<"$screen_rows"
if [ "$ctrl_hits" -ge "$screen_count" ]; then
  ok "the same scan finds $ctrl_hits withheld definitions in the unstripped modules, so it discriminates"
else
  nope "the scan found only $ctrl_hits withheld definitions across $screen_count unstripped modules, so it reads too little to trust"
fi

echo ""

# ===========================================================================
# PART 4 -- the generator publishes the page, the data and the assets
# ===========================================================================
echo "Part 4: scripts/build-docs.sh publishes the reader"

# ---------------------------------------------------------------------------
# mk_minirepo <dest> <with-swipe: 1 or 0>
#
# The smallest tree scripts/build-docs.sh will run in, following
# harness/test-build-docs-reading.sh. puzzles/ is a real empty directory so
# the puzzle glob stays literal and its README guard drops it, and chapter/,
# exercises/ and reading/ are absent so their sections are skipped and the
# python3 concept pass never runs. That keeps this part in the fast tier and
# keeps a developer's own docs/ out of it entirely.
# ---------------------------------------------------------------------------
mk_minirepo() {
  local d="$1" with="$2" f
  mkdir -p "$d/scripts" "$d/puzzles"
  ln -s "$REPO_ROOT/scripts/build-docs.sh" "$d/scripts/build-docs.sh"
  ln -s "$REPO_ROOT/scripts/setup" "$d/scripts/setup"
  for f in README.md QUALITY_GATE.md CURRICULUM_MAP.md JUDGMENTS.md SCAFFOLDING_MAP.md LICENSE; do
    ln -s "$REPO_ROOT/$f" "$d/$f"
  done
  ln -s "$REPO_ROOT/module-docs" "$d/module-docs"
  if [ "$with" = "1" ]; then
    ln -s "$REPO_ROOT/swipe" "$d/swipe"
  fi
}

MINI="$TMP_ROOT/mini"
mk_minirepo "$MINI" 1
if (cd "$MINI" && bash scripts/build-docs.sh > "$TMP_ROOT/build.out" 2> "$TMP_ROOT/build.err"); then
  ok "the generator runs over a tree carrying swipe/"
else
  nope "the generator failed: $(tail -3 "$TMP_ROOT/build.err")"
fi

# ---------------------------------------------------------------------------
# THE GENERATOR MUST START NO JVM, AND THIS IS DRIVEN RATHER THAN GREPPED.
#
# .github/workflows/pages.yml installs Python and mkdocs-material and nothing
# else. There is no Java on the deploy runner, so a build-docs.sh that
# rendered a model screen would fail there, and scripts/cibuild would never
# see it because cibuild does install the toolchain. That is the reason the
# screens are baked into SCREENS.tsv in the first place.
#
# A grep was tried first and it is the wrong instrument. scripts/build-docs.sh
# PRINTS `java -version` and `tlc Tick` into the getting-started page, inside
# a heredoc, so a pattern over the file text reports three hits that are
# documentation. So the build runs again with java, tlc and sany shimmed to
# write a sentinel, and the assertion is that the sentinel is absent.
# ---------------------------------------------------------------------------
SHIM="$TMP_ROOT/shim"
mkdir -p "$SHIM"
SENTINEL="$TMP_ROOT/jvm-was-called"
for c in java tlc sany javac; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 127\n' "$c" "$SENTINEL" > "$SHIM/$c"
  chmod +x "$SHIM/$c"
done
MINI3="$TMP_ROOT/mini-nojvm"
mk_minirepo "$MINI3" 1
(cd "$MINI3" && PATH="$SHIM:$PATH" bash scripts/build-docs.sh > /dev/null 2> "$TMP_ROOT/nojvm.err")
nojvm_rc=$?
if [ ! -f "$SENTINEL" ] && [ "$nojvm_rc" = "0" ]; then
  ok "scripts/build-docs.sh starts no JVM, so the deploy runner can run it"
elif [ -f "$SENTINEL" ]; then
  nope "scripts/build-docs.sh ran the TLA+ toolchain, which the deploy runner does not have: $(head -1 "$SENTINEL")"
else
  nope "the build failed with the toolchain shimmed out, rc $nojvm_rc: $(tail -2 "$TMP_ROOT/nojvm.err")"
fi

PAGE="$MINI/docs/swipe/index.md"
if [ -f "$PAGE" ]; then
  ok "docs/swipe/index.md is published"
else
  nope "docs/swipe/index.md was not published"
fi

if [ -f "$PAGE" ] && grep -q 'id="swipe-app"' "$PAGE"; then
  ok "the page carries the root element the reader keys off"
else
  nope "the page carries no element with id swipe-app, so the reader would never boot"
fi

if [ -f "$PAGE" ] && grep -q 'data-items="items.json"' "$PAGE"; then
  ok "the page points the reader at its payload"
else
  nope "the page carries no data-items attribute"
fi

# ---------------------------------------------------------------------------
# THE CONTRACT PROSE IS A PAGE OF ITS OWN, bead tla-7xql.16 decision D3.
#
# A browser measured 1944 pixels of it under the controls on 2026-10-19, in a
# 3266-pixel document on an 844-pixel viewport. That prose is why the page
# scrolled, and a reader that owns the viewport cannot carry it. So one URL is
# the reader and one is the contract, and there is no mode to be in.
#
# The two halves are checked against each other rather than separately: the
# reader's page must NOT carry a heading the contract page does, or the split
# would pass over a generator that published the prose twice.
# ---------------------------------------------------------------------------
CONTRACT="$MINI/docs/swipe/contract.md"
if [ -f "$CONTRACT" ]; then
  ok "docs/swipe/contract.md is published beside the reader"
else
  nope "docs/swipe/contract.md was not published, so the prose has nowhere to go"
fi

if [ -f "$CONTRACT" ] && grep -q 'Where the answer comes from' "$CONTRACT"; then
  ok "the contract page carries the prose that used to sit under the reader"
else
  nope "the contract page does not carry the prose, so the split lost it rather than moving it"
fi

if [ -f "$PAGE" ] && grep -q 'Where the answer comes from' "$PAGE"; then
  nope "the reader's own page still carries the contract prose, which is what made the page scroll"
else
  ok "the reader's page carries none of the contract prose"
fi

# THE READER HAS TO BE ABLE TO REACH IT. With no Material header on the page
# there is no nav, so the menu link is the only route and the generator owns
# the URL.
if [ -f "$PAGE" ] && grep -q 'data-contract="contract/"' "$PAGE"; then
  ok "the page hands the reader the contract's URL, so the menu can link to it"
else
  nope "the page carries no data-contract attribute, so the contract page is unreachable from the reader"
fi

if [ -f "$MINI/docs/swipe/.pages" ] && grep -q '^  - contract\.md$' "$MINI/docs/swipe/.pages"; then
  ok "the contract page reaches the section nav"
else
  nope "docs/swipe/.pages does not list contract.md, so the page is unreachable from the site nav"
fi

# THE READER'S PAGE STAYS SHORT, and this is the measurement the bead turns on
# rather than a tidiness check. 1944 pixels of prose is what put the reader
# inside a 3266-pixel document. Markdown lines are not pixels, so the bound is
# deliberately loose: it catches a section coming back, not a sentence.
if [ -f "$PAGE" ]; then
  page_lines=$(grep -cE '[^[:space:]]' "$PAGE")
  if [ "$page_lines" -lt 20 ]; then
    ok "the reader's page is $page_lines lines of content, so there is nothing under it to scroll to"
  else
    nope "the reader's page is $page_lines lines, so prose has come back under a reader that owns the viewport"
  fi
fi

# THE PAGE MUST NOT NAME AN ITEM ID, at any level. swipe/README.md records
# that ids ran in kind order inside each template, so an id on the page is an
# answer on the page.
if [ -f "$PAGE" ] && grep -qE 'L[0-9]-[A-Z]+[0-9]*-[0-9]+' "$PAGE"; then
  nope "the page names an item id, which is the kind order given away"
else
  ok "the page names no item id"
fi

PUB_JSON="$MINI/docs/swipe/items.json"
if [ -f "$PUB_JSON" ] && cmp -s "$PUB_JSON" "$PAYLOAD"; then
  ok "the published payload is byte for byte what the emitter writes"
else
  nope "docs/swipe/items.json differs from a fresh emit-items.sh run, or is absent"
fi

if [ -f "$MINI/docs/javascripts/swipe.js" ] && cmp -s "$MINI/docs/javascripts/swipe.js" "$READER_JS"; then
  ok "the reader is published unmodified"
else
  nope "docs/javascripts/swipe.js differs from swipe/reader/swipe.js, or is absent"
fi

if [ -f "$MINI/docs/stylesheets/swipe.css" ] && cmp -s "$MINI/docs/stylesheets/swipe.css" "$READER_CSS"; then
  ok "the stylesheet is published unmodified"
else
  nope "docs/stylesheets/swipe.css differs from swipe/reader/swipe.css, or is absent"
fi

if [ -f "$MINI/docs/.pages" ] && grep -q '^  - swipe$' "$MINI/docs/.pages"; then
  ok "the section reaches the top-level nav"
else
  nope "docs/.pages carries no swipe entry, so the page would be unreachable"
fi

# THE NEGATIVE CONTROL. The same mini-repo with no swipe/ must publish no
# section. Without this, every assertion above would still pass over a
# generator that published the page unconditionally from a hardcoded string.
MINI2="$TMP_ROOT/mini-noswipe"
mk_minirepo "$MINI2" 0
(cd "$MINI2" && bash scripts/build-docs.sh > /dev/null 2>&1)
if [ -d "$MINI2/docs/swipe" ]; then
  nope "a tree with no swipe/ still published a swipe section"
else
  ok "a tree with no swipe/ publishes no swipe section"
fi
if [ -f "$MINI2/docs/.pages" ] && grep -q '^  - swipe$' "$MINI2/docs/.pages"; then
  nope "a tree with no swipe/ still put swipe in the nav"
else
  ok "a tree with no swipe/ puts no swipe entry in the nav"
fi

echo ""

# ===========================================================================
# PART 5 -- the reader's wiring, read as text
# ===========================================================================
echo "Part 5: the reader's wiring"

# EVERY CHECK IN THIS PART READS CODE WITH THE COMMENTS STRIPPED, and that is
# a finding rather than tidiness. The first version grepped the whole file
# for `document$`, and its own red run walked through it: the subscription
# was deleted from the code and the suite stayed green, because this file's
# header explains at length what document$ is for. A text gate over a
# well-commented file measures the comments.
#
# THE STRIP IS A REAL ONE SINCE BEAD tla-7xql.16. It used to be
# `sed 's#//.*##' | grep -v '^ *\*'`, which drops the opening line of a block
# comment and every continuation line that starts with a star, and keeps every
# continuation line that does not. So a sentence of prose still reached the
# patterns below, and this part's own notes said so. tla-7xql.16 had to grep
# for a property name that its CSS also writes in prose, which is the first
# time that hole cost anything. strip_comments() walks the file character by
# character and removes exactly the comments.
#
# strip_comments <file> [1 to treat // as a line comment]
strip_comments() {
  awk -v lc="${2:-}" '
    {
      line = $0
      out = ""
      i = 1
      n = length(line)
      while (i <= n) {
        two = substr(line, i, 2)
        if (block) {
          if (two == "*/") { block = 0; i += 2 } else { i += 1 }
          continue
        }
        if (two == "/*") { block = 1; i += 2; continue }
        if (lc != "" && two == "//") { break }
        out = out substr(line, i, 1)
        i += 1
      }
      print out
    }
  ' "$1"
}

CODE="$TMP_ROOT/swipe.code.js"
strip_comments "$READER_JS" 1 > "$CODE"

code_lines=$(grep -cE '[^[:space:]]' "$CODE")
if [ "$code_lines" -gt 200 ]; then
  ok "the comment strip left $code_lines lines of code to read"
else
  nope "stripping comments left only $code_lines lines, so the checks below read almost nothing"
fi

CSSCODE="$TMP_ROOT/swipe.code.css"
strip_comments "$READER_CSS" > "$CSSCODE"
css_lines=$(grep -cE '[^[:space:]]' "$CSSCODE")
if [ "$css_lines" -gt 120 ]; then
  ok "the comment strip left $css_lines lines of style to read"
else
  nope "stripping comments left only $css_lines lines of CSS, so the checks below read almost nothing"
fi

# THE STRIP IS ITS OWN NEGATIVE CONTROL, and the two phrases are chosen rather
# than picked. Each one sits on a block-comment CONTINUATION LINE that does not
# open with a star, which is exactly the shape the old strip kept: a line
# beginning `/*` or `*` was dropped and every other line of the same comment
# survived. A phrase from a starred line would pass under both strips and prove
# nothing.
if grep -q 'the property the whole design turns on' "$CODE"; then
  nope "the comment strip left the reader's comment prose in the code, so every pattern below can be answered by a sentence"
else
  ok "the comment strip removed the reader's comment prose, so the patterns below read code only"
fi
if grep -q 'is 219 pixels, which is 9 lines' "$CSSCODE"; then
  nope "the comment strip left the stylesheet's comment prose in the style, so a property can be matched out of a sentence about it"
else
  ok "the comment strip removed the stylesheet's comment prose"
fi

# One rule per line, as "SELECTOR { PROPERTIES", so a property check reads ONE
# rule rather than the whole file. @media wrappers are dropped so a rule
# inside one is read like any other.
CSSRULES="$TMP_ROOT/swipe.rules.css"
tr '\n' ' ' < "$CSSCODE" | sed 's/@media[^{]*{/ /g' | tr '}' '\n' > "$CSSRULES"

# THE navigation.instant SUBSCRIPTION IS NOT OPTIONAL. mkdocs.yml turns on
# SPA-style page loading, so a reader that ran on load would be dead for
# anybody who reached the page from the nav. Losing this line is the one
# regression that leaves every other check in this suite green.
if grep -q 'document\$\.subscribe(' "$CODE"; then
  ok "the reader subscribes to the theme's document observable"
else
  nope "no document\$.subscribe( call in the reader's code, so it would not survive an instant navigation"
fi

if grep -q 'getElementById("swipe-app")' "$CODE"; then
  ok "the reader guards on its own root element"
else
  nope "the reader has no root-element guard, so it would run on every page of the site"
fi

if grep -qE '^[[:space:]]*- javascripts/swipe\.js$' "$MKDOCS"; then
  ok "mkdocs.yml loads the reader through extra_javascript"
else
  nope "mkdocs.yml does not list javascripts/swipe.js, so nothing loads the reader"
fi

if grep -qE '^[[:space:]]*- stylesheets/swipe\.css$' "$MKDOCS"; then
  ok "mkdocs.yml loads the stylesheet through extra_css"
else
  nope "mkdocs.yml does not list stylesheets/swipe.css"
fi

if grep -q 'PAYLOAD_VERSION = 2' "$CODE"; then
  ok "the reader reads payload version 2, which is the one the emitter writes"
else
  nope "the reader does not read payload version 2, so it would refuse the published payload"
fi

# THE CARD RENDERER MUST NOT WRITE AN ITEM ID. Read the body of renderCard
# only, so a reference to the id elsewhere in the file, where the log needs
# it, is not mistaken for one on screen.
card_body=$(awk '/^  function renderCard\(\)/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$card_body" | tr -d '[:space:]')" ]; then
  nope "renderCard() was not found in the reader, so the id check read nothing"
elif grep -qE '\.id\b' <<<"$card_body"; then
  nope "renderCard() references an item id, which would put the kind order on screen"
else
  ok "renderCard() writes no item id"
fi

# THE CARD MUST DRAW THE MODEL SCREEN AND THE PIN, or a pinned item arrives as
# a claim with no premise and no subject.
if grep -qE 'renderScreen\(' "$CODE" && grep -q 'screens\[' "$CODE"; then
  ok "the reader draws the model screen from the payload's screens map"
else
  nope "the reader never reads the screens map, so a pinned item would show no model"
fi

if grep -qE 'renderPin\(' "$CODE" && grep -qE '\.pin\b' "$CODE" && grep -qE '\.pre\b' "$CODE"; then
  ok "the reader draws the pin at both pinned rungs"
else
  nope "the reader does not draw the pin, so the question would have no subject"
fi

if grep -q 'withheld' "$CODE"; then
  ok "the reader reads the withheld block, so a model it cannot draw is reported to the reader too"
else
  nope "the reader ignores the withheld block, so a dropped model would be invisible on the page"
fi

if grep -q 'SWIPEFMT' "$CODE"; then
  ok "the exported log carries a version marker"
else
  nope "the reader writes no SWIPEFMT row, so the format is a dump rather than a contract"
fi

# ---------------------------------------------------------------------------
# THE LAYOUT, AND THIS IS THE WEAKEST THING IN THIS FILE.
#
# No browser runs here, so these are text checks over the CSS. They are worth
# having anyway, because the regression they catch is the one that makes the
# channel unusable while every other check stays green: a reader who has to
# scroll to find the question does it on every single item.
#
# Two rules hold the budget, and neither is arithmetic. THE QUESTION IS
# DOCKED: .swipe-card carries the ask, the claim and the three buttons and is
# stuck to the bottom of the viewport, so its position does not depend on the
# theme's header, the h1, the lead-in or the model. THE PREMISE SCROLLS: the
# screen box is capped in viewport units and scrolls inside itself, so one
# long model cannot push another layout around.
#
# The dock is the reason the arithmetic is not here. mkdocs-material puts
# about 400 pixels of page above #swipe-app on a 390x844 phone, and that
# number is the theme's rather than ours.
# ---------------------------------------------------------------------------
screen_rule=$(awk '/^\.swipe-screen-body/, /^\}/' "$CSSCODE")
if grep -qE 'max-height:[^;]*vh' <<<"$screen_rule" && grep -qE 'overflow' <<<"$screen_rule"; then
  ok "the model screen is capped in viewport units and scrolls inside itself"
else
  nope "the model screen has no viewport-relative cap, so a long model pushes the question past the fold"
fi

dock_rule=$(awk '/^\.swipe-card \{/, /^\}/' "$CSSCODE")
if grep -q 'position: sticky' <<<"$dock_rule" && grep -q 'bottom: 0' <<<"$dock_rule"; then
  ok "the question is docked to the bottom of the viewport"
else
  nope "the card is not docked, so the claim and the buttons move with whatever is above them"
fi

# THE PIN MUST NOT BE IN THE DOCK. A level 2 pin is up to 7 rows under three
# labels, which is more than half the dock's own height, and a dock that tall
# is a dock that has eaten the premise it exists to leave room for.
card_body=$(awk '/^  function renderCard\(\)/, /^  }$/' "$CODE")
if grep -qE 'renderPin\(' <<<"$card_body"; then
  nope "renderCard() puts the pin in the dock, which makes the dock taller than the premise"
else
  ok "renderCard() keeps the pin out of the dock, so the dock is the question and nothing else"
fi

if grep -qE 'swipe-answers' <<<"$card_body"; then
  ok "the three answer buttons are inside the dock, beside the claim they answer"
else
  nope "the answer buttons are outside the dock, so they can be scrolled away from the claim"
fi

if grep -qE 'white-space:[[:space:]]*pre[^-]' <<<"$screen_rule"; then
  ok "the model screen does not wrap, which is what keeps a conjunction list aligned"
else
  nope "the model screen wraps, so an indented conjunction list loses its alignment"
fi

# A HORIZONTAL SCROLL INSIDE A SWIPE SURFACE IS TWO GESTURES ON ONE PIXEL.
# The widest screen line measured 73 characters, which does not fit 390 CSS
# pixels at any readable monospace size, so the box scrolls sideways and the
# gesture handler has to decline a touch that starts in it.
if grep -qE 'swipe-screen' "$CODE" && grep -qE '(closest|contains)\(' "$CODE"; then
  ok "the gesture handler declines a touch that starts inside the model screen"
else
  nope "a sideways scroll of the model would also read as a left or right swipe"
fi

# ---------------------------------------------------------------------------
# THE PREMISE STACK, bead tla-7xql.15. The step list and the depth transitions
# are functions, so part 6 DRIVES those and nothing here greps for them. What is
# left over is the half that is not a function: which element carries the tag,
# what the resting view draws, which hint reaches the card, and the two
# bindings tap and Escape need.
#
# A browser read 198 pixels of level 2 pin sitting behind the dock on
# 2026-10-19, so the regression these catch is the premise coming BACK into the
# resting view. That is a two-line change in render() and nothing else in this
# suite would notice it.
#
# Every pattern below is code-shaped rather than prose-shaped, which matters
# here more than usual: the comment strip above removes the FIRST line of a
# block comment and leaves its continuation lines, so a bare word like Escape
# can be matched out of a sentence about Escape.
# ---------------------------------------------------------------------------
render_body=$(awk '/^  function render\(\)/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$render_body" | tr -d '[:space:]')" ]; then
  nope "render() was not found in the reader, so the resting-view checks read nothing"
elif grep -qE 'renderPin\(|renderScreen\(' <<<"$render_body"; then
  nope "render() draws the pin or the model screen itself, so the premise is back in the resting view and can sit behind the dock"
else
  ok "render() draws neither the pin nor the model screen, so the resting view is the question alone"
fi

if grep -qE 'renderStep\(' <<<"$render_body" && grep -qE 'stepsFor\(' <<<"$render_body"; then
  ok "render() draws the premise through the step list rather than from the level"
else
  nope "render() does not go through stepsFor(), so the stack is not what decides the premise"
fi

# ---------------------------------------------------------------------------
# A STEP IS THE WHOLE PAGE, bead tla-7xql.18. The step was the only shrinkable
# child of #swipe-app, so it absorbed the whole deficit and the model got 66 of
# the 438 pixels its content wanted. Frank, on his phone: "It isn't showing the
# model."
#
# THE CHROME DECISION IS A FUNCTION AND PART 6 DRIVES IT over all 24 states.
# What is left here is that render() ASKS it, because three inline conditions
# would pass every assertion in part 6 while answering a different question.
# ---------------------------------------------------------------------------
if grep -qE 'chromeAt\(' <<<"$render_body"; then
  ok "render() asks one predicate what chrome this state draws, which is what part 6 can drive"
else
  nope "render() decides the chrome inline, so part 6's table is not what the reader obeys"
fi

# EVERY SLOT THE PREDICATE ANSWERS HAS TO BE READ. A render() that computes
# the table and then ignores one of its three answers passes every assertion
# in part 6 and draws the menu over the model anyway.
for slot in status card controls; do
  if grep -qE "chrome\.$slot" <<<"$render_body"; then
    ok "render() obeys the chrome predicate's $slot slot"
  else
    nope "render() ignores the predicate's $slot slot, so the table part 6 drives is not what the reader draws"
  fi
done

# AND NOTHING IS APPENDED OUTSIDE A BRANCH. This is the defect in its exact
# shape: the counts, the card and the menu each sat at render()'s own statement
# level, so a step got whatever the three of them left over, which was 276 of
# 844 pixels and 66 of them for the model.
bare=$(grep -nE '^    v\.root\.appendChild\(' <<<"$render_body" || true)
if [ -z "$bare" ]; then
  ok "render() appends nothing outside a branch, so no element is drawn whatever the state"
else
  nope "render() appends at its own statement level, so that element is drawn at every depth: $bare"
fi

step_body=$(awk '/^  function renderStep\(/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$step_body" | tr -d '[:space:]')" ]; then
  nope "renderStep() was not found, so the back-button check read nothing"
elif grep -q 'swipe-step-back' <<<"$step_body"; then
  ok "every stack step draws its own back button, which is the way out tap cannot guarantee"
else
  nope "a stack step draws no back button, and tap does not reach inside the model screen body"
fi

# THIS ONE WAS DECIDED TWICE IN ONE DAY, AND THE ASSERTION IS FLIPPED RATHER
# THAN DELETED SO THE FILE SAYS SO. Decision D2 of bead tla-7xql.18 put one
# line of the claim at the foot of the step view, on the argument that a reader
# checking a claim against a step in front of them should not be holding it in
# their head. tla-7xql.19 reversed it the same afternoon, after Frank read a
# model on his phone: "I think we will be better off having to flick back and
# forth for the problem."
#
# The argument for keeping it was not refuted. It lost to a measurement nobody
# had taken yet, which is the useful part. The claim cost the model body 133.9
# of its 613.9 pixels, and that is four of the 24 screens going from
# overflowing to fitting. See WHAT THE READER IS SHOWN below for the scan that
# holds the figure, and the constants block for where it was read.
if grep -qE '"swipe-claim swipe-step-claim"' <<<"$step_body"; then
  nope "renderStep() draws the claim at its foot, which tla-7xql.19 removed: it costs the model body 133.9 of its 613.9 pixels"
else
  ok "the step view carries no claim, so the model gets the whole body and the reader flicks back to the question"
fi

# AND IT IS THE CLAIM AND NOTHING ELSE. The dock's other three parts are what
# make the dock 304 pixels, and a step that grew them back would be the card
# under another name.
if grep -qE 'swipe-answers|swipe-tag|swipe-ask' <<<"$step_body"; then
  nope "renderStep() draws the tag, the ask or the answer buttons, which is the dock arriving in the step view"
else
  ok "the step view carries no tag, no ask prompt and no answer buttons"
fi

# THE THIRD DEFECT IN THIS FOOTPRINT. cardHint() names the FIRST step of the
# item's stack, so at the model step it read "up for the pinned state" with the
# pinned state one step below. D1 removes the card at depth, and the hint has
# to stay in the card rather than being carried into the step.
if grep -qE 'cardHint\(' <<<"$step_body"; then
  nope "renderStep() writes the resting card's hint, which names a step the reader has already passed"
else
  ok "the depth-0 hint stays in the card, so no step promises a step below it"
fi

# DECISION D3. Eight controls touched once a session against one touched every
# item. The third panel value is the cheap route and it inherits the rule that
# swipes are declined while a panel is open.
controls_body=$(awk '/^  function renderControls\(\)/, /^  }$/' "$CODE")
menu_body=$(awk '/^  function renderMenu\(\)/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$controls_body" | tr -d '[:space:]')" ]; then
  nope "renderControls() was not found, so the menu-collapse check read nothing"
elif [ -z "$(printf '%s' "$menu_body" | tr -d '[:space:]')" ]; then
  nope "renderMenu() was not found, so the eight controls are still in the resting view"
else
  resting=$(grep -cE 'menuButton\(|menuLink\(' <<<"$controls_body")
  behind=$(grep -cE 'menuButton\(|menuLink\(' <<<"$menu_body")
  if [ "$resting" = "1" ] && [ "$behind" -gt 5 ]; then
    ok "the resting view carries one control and the other $behind are behind it"
  else
    nope "the resting view carries $resting controls and the panel $behind, where the ruling is one at rest"
  fi
fi

if grep -qE 'panel = "menu"' <<<"$controls_body"; then
  ok "the one control opens the menu through v.panel, so it inherits the panel rules rather than inventing a mechanism"
else
  nope "the menu control does not set v.panel, so a swipe with the menu open would answer the item behind it"
fi

if grep -q '"swipe-tag"' <<<"$card_body" && grep -q 'TAGS\[item.level\]' <<<"$card_body"; then
  ok "the level tag reaches the dock, where the reader sees it before answering"
else
  nope "renderCard() writes no level tag, so the rung is never named in English"
fi

if grep -qE '0:[[:space:]]*"constant"' "$CODE" &&
   grep -qE '1:[[:space:]]*"state"' "$CODE" &&
   grep -qE '2:[[:space:]]*"action"' "$CODE"; then
  ok "the tags are constant, state and action, which is TLA+'s own level calculus"
else
  nope "the level tags are not constant, state and action, so the tag teaches a second vocabulary"
fi

if grep -q 'cardHint(item)' <<<"$card_body"; then
  ok "the card hint is derived per item, so it cannot promise a step the item does not have"
else
  nope "renderCard() writes a fixed hint, which stops being true at a rung where up 1 is the state"
fi

keys_body=$(awk '/^  function bindKeys\(\)/, /^  }$/' "$CODE")
if grep -qE 'Escape:[[:space:]]*"tap"' <<<"$keys_body"; then
  ok "Escape is bound to tap, so a keyboard can walk the stack back"
else
  nope "Escape is not bound, so a desktop reader has no key for step back"
fi
if grep -qE 'ArrowUp:[[:space:]]*"up"' <<<"$keys_body" &&
   grep -qE 'ArrowDown:[[:space:]]*"down"' <<<"$keys_body"; then
  ok "the four arrows are still bound as they were"
else
  nope "an arrow key binding moved, and this bead was not supposed to touch them"
fi

# THE TAP TARGET EXCLUSION. A tap on a button inside the card bubbles to the
# root listener, so at depth 1 a tap on "true" would answer the item AND step
# back out of the premise on one touch.
#
# THE SELECTOR IS READ RATHER THAN MATCHED WHOLE, since bead tla-7xql.16 added
# a fourth element to it. The anchor is the contract link in the menu, which is
# a control on the way out of the page like any other.
control_sel=$(sed -n 's/.*closest("\([a-z, ]*\)").*/\1/p' "$CODE")
control_missing=""
for e in a button label input; do
  if ! grep -qE "(^|[, ])$e([,]|$)" <<<"$control_sel"; then
    control_missing="$control_missing $e"
  fi
done
if [ -z "$control_sel" ]; then
  nope "isControl()'s selector was not found, so the tap-exclusion check read nothing"
elif [ -z "$control_missing" ]; then
  ok "a tap on a control is declined, over all four of a, button, label and input"
else
  nope "isControl() does not name:$control_missing, so a tap on one would answer or navigate AND step the stack back"
fi

# TAP IS HANDLED IN touchend AND NOWHERE ELSE. A touch produces a touchend and
# a synthesized click, and some browsers synthesize the click after a drag, so
# a second listener on click double-fires and a swipe also steps back.
tap_sites=$(grep -c 'gesture("tap")' "$CODE")
if [ "$tap_sites" = "1" ]; then
  ok "tap is raised from one place only, so one touch cannot fire it twice"
else
  nope "gesture(\"tap\") is raised from $tap_sites places, and a touch produces both a touchend and a click"
fi

# AND IT LEAVES THE FLASH ALONE. renderFlash() has owned a click handler since
# tla-7xql.12 and prints the hint that teaches the gesture, so a tap path that
# also fired there would advance twice on one touch.
end_body=$(awk '/addEventListener\("touchend"/, /^    \}, \{ passive: true \}\);$/' "$CODE")
if [ -z "$(printf '%s' "$end_body" | tr -d '[:space:]')" ]; then
  nope "the touchend listener was not found, so the flash check read nothing"
elif grep -qE 'view\.flash' <<<"$end_body"; then
  ok "the tap path ignores the flash, which already has its own click handler"
else
  nope "the tap path does not check the flash, so one tap on a correction advances twice"
fi

# THE REVIEW IS A STEP RATHER THAN A PANEL, which is what keeps the answers
# live on the two steps that are about the item in the dock.
if grep -qE 'panel = "review"' "$CODE"; then
  nope "the review is still a panel, so swipe up changes the subject instead of opening the premise"
else
  ok "the review is the top step of the stack rather than a panel"
fi

# Read the body of answerButton() rather than the whole file, since the
# expression wraps over two lines and `disabled = .*answersLive` on one line
# would be a pattern that depends on how the line happens to be broken.
button_body=$(awk '/^  function answerButton\(/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$button_body" | tr -d '[:space:]')" ]; then
  nope "answerButton() was not found, so the dead-dock check read nothing"
elif grep -qE 'disabled' <<<"$button_body" && grep -qE 'answersLive\(' <<<"$button_body"; then
  ok "the answer buttons read answersLive(), so the dock dies at the review step and nowhere else"
else
  nope "the answer buttons do not consult the stack, so they are live over a different item or dead over this one"
fi

# RULE THREE OF THE HEIGHT BUDGET. A step taller than the room above the dock
# would put its own tail behind it, which is the defect the stack removes.
step_rule=$(awk '/^\.swipe-step-body/, /^\}/' "$CSSCODE")
if grep -qE 'max-height:[^;]*vh' <<<"$step_rule" && grep -qE 'overflow' <<<"$step_rule"; then
  ok "a stack step is capped in viewport units and scrolls inside itself"
else
  nope "a stack step has no viewport-relative cap, so a tall step puts its own tail behind the dock"
fi

if grep -q 'swipe-step-body' "$CODE" && grep -qE 'scrollHeight' "$CODE"; then
  ok "a drag inside an overflowing step scrolls rather than moving the stack, which is R1"
else
  nope "a drag inside a scrolling step would move the stack instead of scrolling it"
fi

# AND ITS STYLE GOES WITH IT. tla-7xql.18 gave .swipe-step-claim `flex: 0 0
# auto` so the claim could not be the thing that shrank, and that rule has
# nothing left to style. A dead selector in a stylesheet is how the next author
# comes to believe the element is still drawn.
if grep -F -q '.swipe-step-claim' "$CSSRULES"; then
  nope "a rule still styles .swipe-step-claim, which no element carries since tla-7xql.19"
else
  ok "no rule styles .swipe-step-claim, so the stylesheet does not describe an element the reader never draws"
fi

# ---------------------------------------------------------------------------
# THE COLLAPSE CONTROL IS GONE AND THE MODEL'S NAME STAYED, bead tla-7xql.19.
#
# The head was a button toggling v.collapsed[key] and printing "hide" or
# "show". It earned that when the model shared the resting view with the card
# and the reader wanted the viewport back for the stream. THE STEP IS THE MODEL
# NOW, so collapsing it leaves the step with a head and nothing under it, which
# is very likely what Frank saw when he reported "It isn't showing the model".
#
# The NAME is the one thing that has to survive: it is the only label on screen
# saying which model is being read, and the stem-blind instrument withholds the
# module name from a judge for exactly the reason a reader has to be shown it.
# ---------------------------------------------------------------------------
screen_body=$(awk '/^  function renderScreen\(/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$screen_body" | tr -d '[:space:]')" ]; then
  nope "renderScreen() was not found, so the collapse checks read nothing"
else
  if grep -qE 'swipe-screen-toggle|collapsed' <<<"$screen_body"; then
    nope "renderScreen() still draws the collapse toggle, so the step can be collapsed to a head with nothing under it"
  else
    ok "renderScreen() draws no collapse toggle, so a step always has its model under its head"
  fi

  if grep -qE 'addEventListener\(' <<<"$screen_body"; then
    nope "renderScreen() binds a listener, so the head is still a control rather than a label"
  else
    ok "the model head is non-interactive, which is the shape a label has"
  fi

  if grep -q '"swipe-screen-head"' <<<"$screen_body" &&
     grep -q '"swipe-screen-name"' <<<"$screen_body" &&
     grep -qE 'item\.model' <<<"$screen_body"; then
    ok "the head still carries the model's name, which is the one label saying what is being read"
  else
    nope "renderScreen() does not write the model's name into its head, so the reader is not told which model this is"
  fi

  # AND THE BODY IS APPENDED UNCONDITIONALLY. A `collapsed` that was renamed
  # rather than removed would pass the toggle check above and still hand the
  # reader an empty step.
  #
  # THE INDENTATION IS THE WHOLE TEST, which is the same reading render()'s
  # bare-append check takes four screens up. Four spaces is renderScreen()'s
  # own statement level and six is inside a branch, so a pattern that tolerated
  # leading whitespace would agree with the defect it exists to catch.
  if grep -qE '^    box\.appendChild\(el\("pre", "swipe-screen-body"' <<<"$screen_body"; then
    ok "the model body is appended at renderScreen()'s own statement level, so no state can withhold it"
  else
    nope "the model body is not appended at statement level, so some state draws a screen box with no model in it"
  fi
fi

# THE STATE GOES TOO, in the view object and in forget. A key nothing reads is
# a key the next author wires back up.
if grep -qE '\bcollapsed\b' "$CODE"; then
  nope "the reader still carries collapse state: $(grep -nE '\bcollapsed\b' "$CODE" | tr '\n' ' ')"
else
  ok "no collapse state survives in the reader, so forget and the view object have nothing to reset"
fi

if grep -F -q '.swipe-screen-toggle' "$CSSRULES"; then
  nope "a rule still styles .swipe-screen-toggle, which no element carries since tla-7xql.19"
else
  ok "no rule styles .swipe-screen-toggle"
fi

head_rule=$(grep -F '.swipe-screen-head' "$CSSRULES" || true)
if [ -z "$head_rule" ]; then
  nope "no rule styles .swipe-screen-head, so the model's name draws as unstyled body text"
elif grep -qE 'cursor:[[:space:]]*pointer' <<<"$head_rule"; then
  nope ".swipe-screen-head still shows a pointer cursor, so it reads as a control the reader cannot press: $head_rule"
else
  ok "the model head is styled as a label and offers no pointer cursor"
fi

# ---------------------------------------------------------------------------
# WHAT THE READER IS SHOWN, WHICH IS NOT WHAT THE CODE COMPUTES
#
# Every other check in this part reads the reader's source. This one reads the
# PAYLOAD and asks how tall each model is on a phone, which is a different
# question and the one the reader meets.
#
# bd memory a-gate-over-what-the-code-computes-never-sees is why it is here.
# On 2026-10-17 Frank found three defects in the recall rung that 339
# assertions had not seen, and all three were about what reached the reader.
# This suite had the same hole in a smaller room: 214 assertions and not one of
# them could say whether a model fits the screen it is drawn on.
#
# The constants and what invalidates them are in one block above PART 1.
# ---------------------------------------------------------------------------
screen_n=$(grep -c . <<<"$(screens_of "$PAYLOAD")")
if [ "$screen_n" -ge 20 ]; then
  ok "the payload publishes $screen_n model screens, so the fit scan below read a corpus"
else
  nope "only $screen_n model screens came out of the payload, so the fit scan below would pass over almost nothing"
fi

over=$(screens_over "$PAYLOAD" "$SCREEN_BODY_PX")
over_n=$(grep -c . <<<"$over")
over_keys=$(cut -f1 <<<"$over" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
if [ "$over_n" = "$SCREEN_OVER_N" ] && [ "$over_keys" = "$SCREEN_TALLEST" ]; then
  ok "exactly $SCREEN_OVER_N model screen overflows the ${SCREEN_BODY_PX}px step body and it is $SCREEN_TALLEST, which Frank ruled stays scrolling"
else
  nope "$over_n model screens overflow the ${SCREEN_BODY_PX}px step body [$over_keys], where the ruling is $SCREEN_OVER_N and it is $SCREEN_TALLEST"
fi

# THE SAME SCAN AT THE HEIGHT THE CLAIM LEFT, which is the control rather than
# a second reading. A line count that came back wrong would report the same
# overflow set at both heights, and a scan that extracted nothing would report
# none at either. The two differ by four screens, so neither failure is quiet.
over_claimed_n=$(grep -c . <<<"$(screens_over "$PAYLOAD" "$SCREEN_BODY_CLAIMED_PX")")
if [ "$over_claimed_n" = "$SCREEN_OVER_CLAIMED_N" ]; then
  ok "the same scan names $SCREEN_OVER_CLAIMED_N overflowing screens at the ${SCREEN_BODY_CLAIMED_PX}px the claim left, which is what the claim cost"
else
  nope "the scan names $over_claimed_n overflowing screens at ${SCREEN_BODY_CLAIMED_PX}px where central measured $SCREEN_OVER_CLAIMED_N, so the line count is wrong rather than the layout"
fi

tallest_lines=$(awk -F'\t' -v k="$SCREEN_TALLEST" '$1 == k { print $2 }' <<<"$(screens_of "$PAYLOAD")")
if [ "$tallest_lines" = "$SCREEN_TALLEST_LINES" ]; then
  ok "$SCREEN_TALLEST is still $SCREEN_TALLEST_LINES lines, which is the corpus the pixel heights were read against"
else
  nope "$SCREEN_TALLEST is $tallest_lines lines and the heights above were read at $SCREEN_TALLEST_LINES, so re-read them in a browser before trusting the scan"
fi

# THE MENU PANEL GETS THE PANEL FRAME. It is the third value of v.panel, so it
# has to be in the four places the other two are, or it draws as bare buttons
# floating in the viewport.
menu_panel_missing=""
for rule in 'border-radius' 'min-height' 'overflow:' 'flex:'; do
  hit=$(grep -F '.swipe-menu-panel' "$CSSRULES" | grep -F "$rule" || true)
  [ -n "$hit" ] || menu_panel_missing="$menu_panel_missing $rule"
done
if [ -z "$menu_panel_missing" ]; then
  ok "the menu panel is framed, floored, scrollable and flexed like the other two panels"
else
  nope "the menu panel is missing:$menu_panel_missing, so it draws differently from stats and the messages"
fi

# ---------------------------------------------------------------------------
# THE READER OWNS THE VIEWPORT, bead tla-7xql.16.
#
# Frank hit the defect on his own phone on 2026-10-19, minutes after the stack
# shipped: "I'm not sure whether a swipe is going to scroll through the page or
# send a message. I've now accidentally sent multiple responses." The listeners
# are { passive: true } and so cannot cancel a scroll, which means a vertical
# drag inside the reader scrolled the page AND fired gesture(). Down is "not a
# claim", so a scroll filed a vacuity verdict on a real claim. His record holds
# answers he never gave.
#
# The fix is not a flag on the listener. The page stops scrolling: the reader
# fills the viewport on its own page and the prose that used to sit under it
# moved to a page of its own. A vertical drag then has nothing to scroll and
# the gesture is unambiguous at the root.
#
# THE CLASS DECISION IS A FUNCTION AND PART 6 DRIVES IT. What is left for text
# is the stylesheet, which is not a function, and the two call sites.
# ---------------------------------------------------------------------------
VIEWPORT_CLASS=$(sed -n 's/^[[:space:]]*var VIEWPORT_CLASS = "\([^"]*\)".*/\1/p' "$CODE")
if [ -n "$VIEWPORT_CLASS" ]; then
  ok "the reader names the class that gives it the viewport: $VIEWPORT_CLASS"
else
  nope "the reader declares no VIEWPORT_CLASS, so the stylesheet checks below have no selector to look for"
fi

# THE CLASS IS APPLIED FROM THE OBSERVABLE AND NOWHERE ELSE. A per-page
# template is not known to apply under navigation.instant, which replaces the
# document's content without reloading it. boot() is what the observable calls.
boot_body=$(awk '/^  function boot\(doc\)/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$boot_body" | tr -d '[:space:]')" ]; then
  nope "boot() was not found, so the viewport-class call site read nothing"
elif grep -qE 'applyViewport\(' <<<"$boot_body"; then
  ok "boot() drives the viewport class, so it rides the same observable the reader boots from"
else
  nope "boot() never applies the viewport class, so arriving from the nav would leave the reader inside a scrolling page"
fi

if [ -n "$VIEWPORT_CLASS" ]; then
  vp_scroll=$(grep -F "html.$VIEWPORT_CLASS" "$CSSRULES" | grep -F "body" || true)
  if [ -z "$vp_scroll" ]; then
    nope "no rule styles html.$VIEWPORT_CLASS together with body, so the document would still scroll under the reader"
  elif grep -qE 'overflow:[[:space:]]*hidden' <<<"$vp_scroll" &&
       grep -qE 'overscroll-behavior:[[:space:]]*none' <<<"$vp_scroll"; then
    ok "html and body stop scrolling and stop overscrolling under the class"
  else
    nope "the html and body rule under the class is missing overflow hidden or the overscroll ban, and the overscroll half is what kills Chrome Android's pull-to-refresh"
  fi

  vp_app=$(grep -F "html.$VIEWPORT_CLASS" "$CSSRULES" | grep -F "#swipe-app" || true)
  if [ -z "$vp_app" ]; then
    nope "no rule sizes #swipe-app under the class, so the reader is still a widget in a page"
  elif grep -qE 'position:[[:space:]]*fixed' <<<"$vp_app" && grep -qE '[0-9]dvh' <<<"$vp_app"; then
    ok "the reader is fixed to the viewport and measured in dvh, which is what accounts for mobile browser chrome"
  else
    nope "the reader is not fixed to a dvh-measured viewport; vh is the wrong unit here because it ignores the browser's own chrome"
  fi
fi

# ---------------------------------------------------------------------------
# touch-action, AND THE ONE VALUE THAT WOULD BE A REGRESSION.
#
# The property INTERSECTS up the ancestor chain, so a value on an ancestor
# takes panning away from every descendant. The widest model screen line is 73
# characters, which does not fit 390 CSS pixels at any readable monospace size,
# so .swipe-screen-body scrolls sideways and that scroll is shipped behavior.
# Forbidding pan-x anywhere above it kills it.
#
# So the rule is: set the property on the surfaces that are gestures, and never
# on #swipe-app or on either scroller.
# ---------------------------------------------------------------------------
for sel in '#swipe-app' '.swipe-screen-body'; do
  rule=$(grep -F "$sel " "$CSSRULES" | grep -F 'touch-action' || true)
  if [ -z "$rule" ]; then
    ok "$sel sets no touch-action, so it cannot take the sideways scroll away from the model screen"
  else
    nope "$sel sets touch-action, which intersects down the chain and would kill the model screen's sideways scroll: $rule"
  fi
done

ta_card=$(grep -F '.swipe-card' "$CSSRULES" | grep -F 'touch-action' || true)
if grep -qE 'touch-action:[[:space:]]*pinch-zoom' <<<"$ta_card"; then
  ok "the dock declares touch-action pinch-zoom, so a drag on it pans nothing and a reader can still zoom a line of TLA+"
else
  nope "the dock sets no touch-action, so a drag on the question is a pan before it is a gesture"
fi

# THE FLASH HAS TO KEEP pan-y, AND THAT IS A MEASUREMENT RATHER THAN A
# PREFERENCE. Measured in a real browser at 390x844 on 2026-10-19, over EVERY
# item of each pinned rung: 39 of the 48 level 2 corrections run past the
# flash's own height, worst case 111 pixels, against 0 of 144 at level 1. With
# the page no longer scrolling there is nowhere else for those pixels to be
# read, and touch-action pinch-zoom alone means touch cannot pan the flash to
# reach them.
#
# THE RUNG RATHER THAN A SAMPLE. An earlier reading answered 40 items drawn
# from the 48, and since the stream draws at random, three runs of one tree
# gave 35, 31 and 29. Nothing was changing but the draw. Answering until the
# done screen covers each item once and repeats exactly.
#
# Allowing pan-y is only half: the gesture handler has to decline a drag that
# starts in an OVERFLOWING flash, or the drag scrolls the correction and
# advances past it in the same stroke. That is R1 of the stack design applied
# to one more scroller, and the next check is the other half.
ta_flash=$(grep -F '.swipe-flash' "$CSSRULES" | grep -F 'touch-action' || true)
if [ -z "$ta_flash" ]; then
  nope ".swipe-flash sets no touch-action, so a drag on a correction pans whatever is behind it"
elif grep -qE 'pan-y' <<<"$ta_flash" && grep -qE 'pinch-zoom' <<<"$ta_flash"; then
  ok "the flash keeps pan-y, so a correction taller than the flash can still be read, and keeps pinch-zoom"
else
  nope "the flash refuses pan-y, and 39 of the 48 level 2 corrections are taller than it: $ta_flash"
fi

# THE THREE DECLINES MOVED OUT OF THE LISTENER IN BEAD tla-7xql.18, so part 6
# can drive the table in both directions. What is left here is the half a
# driver cannot see: that the listener goes through the one function rather
# than carrying a fourth condition of its own.
decline_body=$(awk '/^  function scrollerDeclining\(/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$decline_body" | tr -d '[:space:]')" ]; then
  nope "scrollerDeclining() was not found, so the scroller declines are back inside the listener where no driver reaches them"
elif grep -qE 'swipe-flash' <<<"$decline_body" && grep -qE 'scrollHeight' <<<"$decline_body"; then
  ok "a drag inside an overflowing flash scrolls the correction instead of advancing past it"
else
  nope "the decline table does not refuse an overflowing flash, so one stroke would scroll the correction AND advance off it"
fi

# R1 OF THIS BEAD. The screen-body decline was UNCONDITIONAL, which was almost
# free at 66 of 844 pixels and is most of the phone once a step is the whole
# page. The horizontal reading is what makes it conditional, and scrollWidth is
# the word that says so: scrollHeight on the screen body would be the wrong
# axis and would read as a fix.
screen_decline=$(grep -A2 -F 'swipe-screen-body' <<<"$decline_body" || true)
if [ -z "$(printf '%s' "$screen_decline" | tr -d '[:space:]')" ]; then
  nope "nothing in scrollerDeclining() names the model screen body, so a sideways scroll of the model is a left swipe again"
elif grep -qE 'scrollWidth' <<<"$screen_decline" && grep -qE 'clientWidth' <<<"$screen_decline"; then
  ok "the model screen is declined on the sideways axis only, so a model that fits keeps the whole page for tap and swipe"
else
  nope "the model screen decline does not read scrollWidth against clientWidth, so it is either unconditional or on the wrong axis: $screen_decline"
fi

start_body=$(awk '/addEventListener\("touchstart"/, /^    \}, \{ passive: true \}\);$/' "$CODE")
if [ -z "$(printf '%s' "$start_body" | tr -d '[:space:]')" ]; then
  nope "the touchstart listener was not found, so the one-route check read nothing"
elif grep -qE 'scrollerDeclining\(' <<<"$start_body" &&
     ! grep -qE 'scrollHeight|scrollWidth' <<<"$start_body"; then
  ok "touchstart asks the decline table and holds no scroll reading of its own"
else
  nope "touchstart reads a scroller directly, so part 6's table is not the whole rule any more"
fi

# THE STEP BODY HAS TO KEEP BOTH AXES. The model screen is inside it, so a
# value here that drops pan-x reaches the screen through the intersection.
ta_step=$(grep -F '.swipe-step-body' "$CSSRULES" | grep -F 'touch-action' || true)
if [ -z "$ta_step" ]; then
  ok ".swipe-step-body sets no touch-action, so the model screen inside it keeps both axes"
elif grep -qE 'pan-x' <<<"$ta_step" && grep -qE 'pan-y' <<<"$ta_step"; then
  ok ".swipe-step-body keeps both axes, so the model screen inside it still scrolls sideways"
else
  nope ".swipe-step-body restricts panning without naming both axes, and the model screen is inside it: $ta_step"
fi

# THE MENU REACHES THE CONTRACT, which is now a page of its own rather than
# 1944 pixels of prose under a reader that owns the viewport. The URL comes off
# the root element the way data-items already does, so the generator owns where
# the page lives and this file does not write a path.
if grep -q 'data-contract' "$CODE"; then
  ok "the reader reads the contract page's URL off its own root element"
else
  nope "the reader hardcodes or omits the contract link, so the prose it replaced is unreachable from the reader"
fi

# THE FORGET BUTTON, decision D5. There was no way to clear the record at all:
# clearing site data was the only route and it takes the theme preference with
# it. The confirm and the two keys are what part 6 cannot see, since the state
# transition is pure and the removal is not.
forget_body=$(awk '/^  function doForget\(\)/, /^  }$/' "$CODE")
if [ -z "$(printf '%s' "$forget_body" | tr -d '[:space:]')" ]; then
  nope "doForget() was not found, so there is still no way to clear the record"
elif grep -qE 'window\.confirm\(FORGET_PROMPT\)' <<<"$forget_body" &&
     grep -qE 'dropKey\(STORAGE_KEY\)' <<<"$forget_body" &&
     grep -qE 'dropKey\(LEGACY_STORAGE_KEY\)' <<<"$forget_body"; then
  ok "forget asks first and then drops both keys, the current one and the level 0 one it migrated from"
else
  nope "doForget() does not ask before it writes, or leaves one of the two storage keys behind"
fi

echo ""

# ===========================================================================
# PART 6 -- the import contract and the premise stack, executed
# ===========================================================================
echo "Part 6: the import contract and the premise stack, executed"

JS_RUNTIME=""
for c in node nodejs; do
  if command -v "$c" > /dev/null 2>&1; then
    JS_RUNTIME="$c"
    break
  fi
done

if [ -z "$JS_RUNTIME" ]; then
  skip "no script runtime on this box, so the reader's pure halves were NOT executed"
  note "that is every assertion in this part: the import refusals, the bucket"
  note "split, and the whole premise-stack transition table. They are the ones"
  note "that say a bad file is refused rather than silently starting the record"
  note "over, and that each of the five gestures keeps one meaning at every"
  note "depth. No count is written here, because a count in prose rots."
else
  DRIVER="$TMP_ROOT/drive.js"
  cat > "$DRIVER" <<'DRIVER_EOF'
// Drives swipe.js's pure halves. One line of output per case:
//   <name> <OK|BAD> <detail>
const path = process.argv[2];
const mod = require(path);
const byId = { "L0-T1-01": { id: "L0-T1-01", swipe: "right", template: "T1", level: 0 } };
const cases = [
  ["no-version",   "SWIPE\tL0-T1-01\t2026-01-01T00:00:00Z\tright\thit\n"],
  ["bad-version",  "SWIPEFMT\t99\nSWIPE\tL0-T1-01\t2026-01-01T00:00:00Z\tright\thit\n"],
  ["unknown-row",  "SWIPEFMT\t1\nNOPE\ta\tb\tc\td\n"],
  ["short-row",    "SWIPEFMT\t1\nSWIPE\tL0-T1-01\t2026-01-01T00:00:00Z\n"],
  ["spaces",       "SWIPEFMT\t1\nSWIPE L0-T1-01 2026-01-01T00:00:00Z right hit\n"],
  ["bad-dir",      "SWIPEFMT\t1\nSWIPE\tL0-T1-01\t2026-01-01T00:00:00Z\tsideways\thit\n"],
  ["empty-file",   ""]
];
for (const [name, text] of cases) {
  const r = mod.parseLog(text, byId);
  const refused = Boolean(r.error) && !r.rows;
  console.log(name + " " + (refused ? "OK" : "BAD") + " " + (r.error || "accepted"));
}
// A hand-edited but well formed file must be ACCEPTED, or "refuses" would
// just mean "refuses everything".
const good =
  "# a comment\n\n" +
  "SWIPEFMT\t1\n" +
  "SWIPE\tL0-T1-01\t2026-01-01T00:00:00Z\tleft\thit   \n";
const g = mod.parseLog(good, byId);
console.log("hand-edited " + (!g.error && g.rows.length === 1 ? "OK" : "BAD") +
  " " + (g.error || JSON.stringify(g.rows[0])));
console.log("recompute " + (!g.error && g.rows[0].v === "miss" ? "OK" : "BAD") +
  " verdict=" + (g.rows ? g.rows[0].v : "-") + " corrected=" + g.corrected);
// The merge must never drop a row that is already held.
const m = mod.mergeLog(
  [{ i: "L0-T1-01", t: "2026-01-01T00:00:00Z", s: "right", v: "hit" }],
  [{ i: "L0-T1-01", t: "2026-01-01T00:00:00Z", s: "right", v: "hit" },
   { i: "L0-T1-01", t: "2026-01-02T00:00:00Z", s: "left", v: "miss" }]);
console.log("merge " + (m.log.length === 2 && m.added === 1 ? "OK" : "BAD") +
  " kept=" + m.log.length + " added=" + m.added);
// What the export writes has to be what the import reads.
const text = mod.exportText(m.log, "https://example.invalid/swipe/");
const back = mod.parseLog(text, byId);
console.log("roundtrip " + (!back.error && back.rows.length === 2 ? "OK" : "BAD") +
  " " + (back.error || back.rows.length + " rows"));
// THE BUCKETS ARE WHAT MAKES A MODEL SCREEN WORTH DRAWING. The epic's
// mechanic is "a model, then a stream of single lines", so an unanswered pool
// is split by level and model and a run stays inside one bucket.
const items = [
  { id: "a", level: 0, swipe: "right" },
  { id: "b", level: 0, swipe: "left" },
  { id: "c", level: 1, model: "M", swipe: "right" },
  { id: "d", level: 1, model: "M", swipe: "left" },
  { id: "e", level: 1, model: "N", swipe: "down" },
  { id: "f", level: 2, model: "M", swipe: "right" }
];
const b = mod.bucketsOf(items);
const keys = Object.keys(b).sort().join(",");
console.log("buckets " + (keys === "0,1:M,1:N,2:M" ? "OK" : "BAD") + " " + keys);
console.log("bucket-sizes " + (b["0"].length === 2 && b["1:M"].length === 2 ? "OK" : "BAD") +
  " level0=" + b["0"].length + " 1:M=" + b["1:M"].length);
// A level filter has to be able to pick one rung and only that rung.
const only1 = mod.bucketsOf(items.filter(function (i) { return i.level === 1; }));
console.log("level-filter " + (Object.keys(only1).sort().join(",") === "1:M,1:N" ? "OK" : "BAD") +
  " " + Object.keys(only1).sort().join(","));

// ===========================================================================
// THE PREMISE STACK, bead tla-7xql.15.
//
// A level 2 item drew 623 pixels of premise into 575 pixels of room, so 198
// pixels of pin sat behind the dock the moment the item appeared. The fix
// takes the premise out of the resting view and makes it a stack the reader
// walks up, and the whole of that rule is four pure functions. They are
// DRIVEN here rather than asserted by grep, because the thing that has to be
// true is the transition table and a pattern over the source cannot see one.
// ===========================================================================
const l0 = { id: "s0", level: 0, swipe: "right" };
const l1 = { id: "s1", level: 1, model: "M", pin: ["a = 0"], swipe: "left" };
const l2 = { id: "s2", level: 2, model: "M", pre: ["a = 0"], post: ["a = 1"],
             binds: ["p = p1"], swipe: "down" };
// 18 of the 48 shipped level 2 items carry no bind list, so this is the live
// case rather than a theoretical one.
const l2nb = { id: "s3", level: 2, model: "M", pre: ["a = 0"], post: ["a = 1"],
               binds: [], swipe: "right" };
// Neither of these two exists in the corpus today: every shipped level 1 and
// level 2 item names a model and carries a pin. They are what says the list
// is built from the ITEM rather than from its level number.
const noScreen = { id: "s4", level: 1, pin: ["a = 0"], swipe: "right" };
const noPin = { id: "s5", level: 1, model: "M", pin: [], swipe: "right" };

function stepsOf(item) { return mod.stepsFor(item).join(","); }
const stepCases = [
  ["steps-level0", l0, "explain"],
  ["steps-level1", l1, "pin,screen,explain"],
  ["steps-level2", l2, "pin,screen,explain"],
  ["steps-level2-no-binds", l2nb, "pin,screen,explain"],
  ["steps-no-screen", noScreen, "pin,explain"],
  ["steps-no-pin", noPin, "screen,explain"],
  ["steps-no-item", null, "explain"]
];
for (const [name, item, want] of stepCases) {
  const got = stepsOf(item);
  console.log(name + " " + (got === want ? "OK" : "BAD") + " " + got + " (wanted " + want + ")");
}

// THE WHOLE GESTURE TABLE, every direction from every depth. up goes one
// deeper and stops at the top, tap comes one back and stops at rest, and the
// three answers never move the stack at all.
const s3 = mod.stepsFor(l1);
const s1 = mod.stepsFor(l0);
function walk(dir, steps) {
  const out = [];
  for (let d = 0; d <= steps.length; d++) { out.push(mod.depthAfter(dir, d, steps)); }
  return out.join(",");
}
const depthCases = [
  ["depth-up-3step", "up", s3, "1,2,3,3"],
  ["depth-tap-3step", "tap", s3, "0,0,1,2"],
  ["depth-right-3step", "right", s3, "0,1,2,3"],
  ["depth-left-3step", "left", s3, "0,1,2,3"],
  ["depth-down-3step", "down", s3, "0,1,2,3"],
  ["depth-up-1step", "up", s1, "1,1"],
  ["depth-tap-1step", "tap", s1, "0,0"],
  ["depth-down-1step", "down", s1, "0,1"]
];
for (const [name, dir, steps, want] of depthCases) {
  const got = walk(dir, steps);
  console.log(name + " " + (got === want ? "OK" : "BAD") + " " + got + " (wanted " + want + ")");
}

// THE ONE VISIBLE MODE CHANGE. Steps 1 and 2 are the item in the dock, so an
// answer there answers the question on screen. The last step is the last item
// answered WRONG, which is a different item, so the dock goes dead.
function liveness(steps) {
  const out = [];
  for (let d = 0; d <= steps.length; d++) { out.push(mod.answersLive(d, steps) ? "live" : "dead"); }
  return out.join(",");
}
const live3 = liveness(s3);
console.log("answers-3step " + (live3 === "live,live,live,dead" ? "OK" : "BAD") + " " + live3);
const live1 = liveness(s1);
console.log("answers-1step " + (live1 === "live,dead" ? "OK" : "BAD") + " " + live1);

// THE HINT IS HOW THE READER LEARNS THE PREMISE IS UP THERE AT ALL, so it has
// to name this item's own first step. Level 0 keeps the line it always had,
// which is right rather than a coincidence: the explanation is still all that
// rung has above the card.
const hintCases = [
  ["hint-level0", l0, "up for the last one you got wrong"],
  ["hint-level1", l1, "up for the pinned state"],
  ["hint-level2", l2, "up for the step"],
  ["hint-no-screen", noScreen, "up for the pinned state"],
  ["hint-no-pin", noPin, "up for the model"]
];
for (const [name, item, want] of hintCases) {
  const got = mod.cardHint(item);
  console.log(name + " " + (got === want ? "OK" : "BAD") + " \"" + got + "\"");
}

// The pin blocks, which are what stepsFor() reads to know whether the item
// has a pin step at all. The labels are the renderers' own words.
function labelsOf(item) {
  return mod.pinBlocks(item).map(function (b) { return b.label; }).join(",");
}
const pinCases = [
  ["pin-level0", l0, ""],
  ["pin-level1", l1, "pinned at"],
  ["pin-level2", l2, "from,steps to,where"],
  ["pin-level2-no-binds", l2nb, "from,steps to"],
  ["pin-no-pin", noPin, ""]
];
for (const [name, item, want] of pinCases) {
  const got = labelsOf(item);
  console.log(name + " " + (got === want ? "OK" : "BAD") + " [" + got + "]");
}

// ===========================================================================
// A STEP IS THE WHOLE PAGE, bead tla-7xql.18.
//
// Read by central in Chrome at a true 390x844 against the published build,
// with a record present and the model step open. Every child of #swipe-app is
// flex: 0 0 auto except .swipe-step, so the step is the only shrinkable thing
// and absorbs the whole deficit: the counts took 29.6 pixels, the card 304,
// the menu 172 and the padding and gaps 62, which left the step 276.4 of 844
// and the model screen inside it 66.3 against the 438 its content wanted.
// Frank, on his phone: "It isn't showing the model." The model was there.
//
// So at depth the counts, the card and the menu are not drawn at all, and
// THAT DECISION IS ONE PURE FUNCTION rather than three conditions inside
// render(). What has to be true is a table over every state the reader can be
// in, and a pattern over render()'s source cannot see a table.
// ===========================================================================
function chromeOf(depth, panel, flash) {
  const c = mod.chromeAt(depth, panel, flash);
  return [c.status ? "status" : "-", c.card ? "card" : "-",
          c.controls ? "controls" : "-"].join(",");
}
const flashOn = { verdict: "hit", item: l1, given: "left" };
// EVERY COMBINATION: three depths by four panel values by two flash values.
// The depths are rest, one step in, and the top of a three-step stack.
//
// Half of these 24 are unreachable through the reader today, because answer()
// closes the stack before it sets the flash and the menu is only reachable
// from the resting view. They are driven anyway: the function is total, and a
// later bead that makes one of them reachable should find it already answered
// rather than discover render() had no opinion.
const REST = "status,card,controls";
const PANEL = "status,-,controls";
const MENU = "status,-,-";
const STEPPED = "-,-,-";
const chromeCases = [
  ["chrome-rest", 0, null, null, REST],
  ["chrome-rest-flash", 0, null, flashOn, PANEL],
  ["chrome-rest-stats", 0, "stats", null, PANEL],
  ["chrome-rest-stats-flash", 0, "stats", flashOn, PANEL],
  ["chrome-rest-message", 0, "message", null, PANEL],
  ["chrome-rest-message-flash", 0, "message", flashOn, PANEL],
  ["chrome-rest-menu", 0, "menu", null, MENU],
  ["chrome-rest-menu-flash", 0, "menu", flashOn, MENU],
  ["chrome-step1", 1, null, null, STEPPED],
  ["chrome-step1-flash", 1, null, flashOn, PANEL],
  ["chrome-step1-stats", 1, "stats", null, PANEL],
  ["chrome-step1-stats-flash", 1, "stats", flashOn, PANEL],
  ["chrome-step1-message", 1, "message", null, PANEL],
  ["chrome-step1-message-flash", 1, "message", flashOn, PANEL],
  ["chrome-step1-menu", 1, "menu", null, MENU],
  ["chrome-step1-menu-flash", 1, "menu", flashOn, MENU],
  ["chrome-top", 3, null, null, STEPPED],
  ["chrome-top-flash", 3, null, flashOn, PANEL],
  ["chrome-top-stats", 3, "stats", null, PANEL],
  ["chrome-top-stats-flash", 3, "stats", flashOn, PANEL],
  ["chrome-top-message", 3, "message", null, PANEL],
  ["chrome-top-message-flash", 3, "message", flashOn, PANEL],
  ["chrome-top-menu", 3, "menu", null, MENU],
  ["chrome-top-menu-flash", 3, "menu", flashOn, MENU]
];
for (const [name, depth, panel, flash, want] of chromeCases) {
  const got = chromeOf(depth, panel, flash);
  console.log(name + " " + (got === want ? "OK" : "BAD") + " " + got +
    " (wanted " + want + ")");
}

// DECISION D4, AND IT IS THE ONE THIS BEAD COULD BREAK WITHOUT NOTICING. The
// buttons go away at the model step and the ANSWER does not: a swipe right
// there still files "true". So the two functions have to disagree, and this
// line is where that is written down rather than inferred from two tables on
// different pages.
const s3d4 = mod.stepsFor(l2);
const d4live = mod.answersLive(2, s3d4);
const d4card = mod.chromeAt(2, null, null).card;
console.log("d4-answer-without-button " + (d4live && !d4card ? "OK" : "BAD") +
  " live=" + d4live + " card=" + d4card);

// THE CARD HINT DEFECT, which is the third one in this bead's footprint. The
// hint is renderCard()'s and it reads "up for the pinned state" at the model
// step, where the pinned state is one step BELOW. D1 removes the card at
// depth, so the defect closes itself, and this is the line that says so
// rather than leaving it to inference.
let hintReach = "";
for (const d of [1, 2, 3]) {
  if (mod.chromeAt(d, null, null).card) { hintReach += " " + d; }
}
console.log("card-hint-unreachable-at-depth " + (hintReach === "" ? "OK" : "BAD") +
  " card drawn at depth:" + (hintReach || " none"));

// ===========================================================================
// R1, WHICH THIS BEAD CREATES AND HAS TO SOLVE.
//
// bindGestures() declined every touch starting inside .swipe-screen-body,
// unconditionally. At 66 of 844 pixels that was almost nothing. Full-page it
// is most of the screen, and the back button would be the only way out of a
// view filling the phone.
//
// Frank's mitigation: decline only when the line ACTUALLY overflows sideways.
// The pattern was already twelve lines below it, where the .swipe-step-body
// decline reads scrollHeight against clientHeight, so the screen body takes
// the horizontal form of the same reading.
//
// THE TABLE MATTERS IN BOTH DIRECTIONS. A decline that always fires and a
// decline that never fires both pass a one-sided check, and the first of those
// is the defect being removed here.
// ===========================================================================
function scroller(sel, overX, overY) {
  return { sel: sel,
           scrollWidth: 300 + overX, clientWidth: 300,
           scrollHeight: 400 + overY, clientHeight: 400 };
}
// closest() walks a declared chain, which is the only thing the function under
// test reads off the DOM.
function touchIn(chain) {
  return {
    closest: function (sel) {
      for (const n of chain) { if (n.sel === sel) { return n; } }
      return null;
    }
  };
}
const SCREEN = ".swipe-screen-body";
const STEPBODY = ".swipe-step-body";
const FLASHBOX = ".swipe-flash";
const declineCases = [
  // The screen body, on the sideways axis and nothing else.
  ["decline-screen-wide", [scroller(SCREEN, 120, 0)], "screen"],
  ["decline-screen-narrow", [scroller(SCREEN, 0, 0)], null],
  // The +1 is the same tolerance the step body has carried since tla-7xql.15.
  // A box one pixel over is a rounding artifact, not a scroll.
  ["decline-screen-by-one", [scroller(SCREEN, 1, 0)], null],
  // A MODEL TALLER THAN THE ROOM DOES NOT DECLINE, and that is the ruling
  // rather than an oversight: Frank named the sideways axis and only the
  // sideways axis.
  //
  // THIS CORPUS DOES REACH IT, on one screen of 24, and this comment used to
  // say the opposite off two wrong figures. It read 660 pixels of room against
  // 438 for the worst model. The body is 613.9 measured, the tallest is
  // 1:Shelves at 29 lines wanting 629.1, and the 438 was a correct reading of
  // 1:Alternation at 20 lines, which comes to 437.6 and was the model on
  // screen at the time rather than the worst one. So 1:Shelves scrolls
  // vertically and a drag in it moves the stack in one stroke. Frank ruled it
  // stays scrolling. The case below is still right and still what the ruling
  // asks for.
  ["decline-screen-tall-only", [scroller(SCREEN, 0, 200)], null],
  // The step body keeps the vertical form it already had, unchanged.
  ["decline-step-tall", [scroller(STEPBODY, 0, 50)], "step"],
  ["decline-step-fits", [scroller(STEPBODY, 0, 0)], null],
  ["decline-step-wide-only", [scroller(STEPBODY, 200, 0)], null],
  // And the flash keeps its own, which is what makes a tall correction
  // readable instead of advancing off it in one stroke.
  ["decline-flash-tall", [scroller(FLASHBOX, 0, 50)], "flash"],
  ["decline-flash-fits", [scroller(FLASHBOX, 0, 0)], null],
  // The real chain: the screen body is INSIDE the step body, so both answer
  // closest() and the screen is the one that has to be read first.
  ["decline-nested-wide", [scroller(SCREEN, 120, 0), scroller(STEPBODY, 0, 0)], "screen"],
  ["decline-nested-narrow", [scroller(SCREEN, 0, 0), scroller(STEPBODY, 0, 0)], null],
  ["decline-nested-step-scrolls", [scroller(SCREEN, 0, 0), scroller(STEPBODY, 0, 90)], "step"],
  // The dock, the counts and the menu are in no scroller at all.
  ["decline-bare-target", [], null]
];
for (const [name, chain, want] of declineCases) {
  const got = mod.scrollerDeclining(touchIn(chain));
  console.log(name + " " + (got === want ? "OK" : "BAD") + " " + String(got) +
    " (wanted " + String(want) + ")");
}
// The observable is the theme's and a touch target is the browser's, so
// neither is assumed to have what this function reads.
console.log("decline-no-target " +
  (mod.scrollerDeclining(null) === null ? "OK" : "BAD"));
console.log("decline-no-closest " +
  (mod.scrollerDeclining({}) === null ? "OK" : "BAD"));

// ===========================================================================
// THE VIEWPORT CLASS, bead tla-7xql.16, AND THE REMOVAL IS THE HALF THAT CAN
// BREAK THE WHOLE SITE.
//
// mkdocs.yml runs navigation.instant, so the document's content is replaced
// without a reload and the html element SURVIVES every navigation. A class
// left on it follows the reader to every other page of the site and takes the
// Material header with it. That is why the one stub below keeps a single html
// element and flips only whether the root is findable: that is exactly what an
// instant navigation does, and a stub with two documents would not reproduce
// it.
// ===========================================================================
function stubDoc() {
  const classes = new Set();
  const d = {
    hasRoot: true,
    documentElement: {
      classList: {
        add: function (c) { classes.add(c); },
        remove: function (c) { classes.delete(c); },
        contains: function (c) { return classes.has(c); }
      }
    },
    getElementById: function (id) {
      return (d.hasRoot && id === "swipe-app") ? { id: id } : null;
    },
    classes: classes
  };
  return d;
}
const VP = mod.VIEWPORT_CLASS;
console.log("viewport-name " + (typeof VP === "string" && VP.length > 0 ? "OK" : "BAD") +
  " " + String(VP));
const doc = stubDoc();
mod.applyViewport(doc);
console.log("viewport-on " + (doc.classes.has(VP) ? "OK" : "BAD") +
  " [" + Array.from(doc.classes).join(" ") + "]");
// Idempotent, because the observable can fire more than once over one page's
// life and boot() is already written for that.
mod.applyViewport(doc);
console.log("viewport-on-twice " + (doc.classes.size === 1 && doc.classes.has(VP) ? "OK" : "BAD") +
  " size=" + doc.classes.size);
// THE ONE THAT MATTERS. An instant navigation to any other page of the site
// replaces the content, so the root is gone and the class has to go with it.
doc.hasRoot = false;
mod.applyViewport(doc);
console.log("viewport-off " + (!doc.classes.has(VP) ? "OK" : "BAD") +
  " [" + Array.from(doc.classes).join(" ") + "]");
mod.applyViewport(doc);
console.log("viewport-off-twice " + (doc.classes.size === 0 ? "OK" : "BAD") +
  " size=" + doc.classes.size);
// And back again, because the nav reaches the reader from both directions.
doc.hasRoot = true;
mod.applyViewport(doc);
console.log("viewport-back " + (doc.classes.has(VP) ? "OK" : "BAD") +
  " [" + Array.from(doc.classes).join(" ") + "]");
// A class the reader did not put there is left alone, so the theme's own
// classes on html survive the removal.
const keep = stubDoc();
keep.classes.add("md-something");
keep.hasRoot = false;
mod.applyViewport(keep);
console.log("viewport-keeps-others " +
  (keep.classes.has("md-something") && !keep.classes.has(VP) ? "OK" : "BAD") +
  " [" + Array.from(keep.classes).join(" ") + "]");
// A document with no html element is not a crash. The observable is the
// theme's and this file does not get to assume what it hands over.
console.log("viewport-no-html " +
  (mod.applyViewport({ getElementById: function () { return null; } }) === false ? "OK" : "BAD"));
console.log("viewport-no-doc " + (mod.applyViewport(null) === false ? "OK" : "BAD"));

// ===========================================================================
// FORGET, decision D5. Frank needed it on 2026-10-19 and there was no reset
// path at all: the record lives under one localStorage key and clearing site
// data was the only route, which takes the theme preference with it.
//
// "WRITES NOTHING IF THE READER DECLINES" IS AN IDENTITY. forgetState returns
// the state it was GIVEN on a decline, and doForget() drops the keys only when
// it gets a different object back, so the decline path cannot reach a write.
// ===========================================================================
const held = { version: 1, log: [{ i: "L0-T1-01", t: "2026-01-01T00:00:00Z", s: "right", v: "hit" }],
               storable: true };
const declined = mod.forgetState(held, false);
console.log("forget-declined " + (declined === held && held.log.length === 1 ? "OK" : "BAD") +
  " same=" + (declined === held) + " rows=" + held.log.length);
const taken = mod.forgetState(held, true);
console.log("forget-taken " +
  (taken !== held && taken.log.length === 0 && held.log.length === 1 ? "OK" : "BAD") +
  " rows=" + taken.log.length + " original=" + held.log.length);
console.log("forget-keeps-storable " + (taken.storable === true ? "OK" : "BAD") +
  " storable=" + String(taken.storable));
const unstorable = mod.forgetState({ version: 1, log: [], storable: false }, true);
console.log("forget-unstorable " + (unstorable.storable === false ? "OK" : "BAD") +
  " storable=" + String(unstorable.storable));
DRIVER_EOF

  if "$JS_RUNTIME" "$DRIVER" "$READER_JS" > "$TMP_ROOT/drive.out" 2> "$TMP_ROOT/drive.err"; then
    while read -r name verdict detail; do
      if [ "$verdict" = "OK" ]; then
        ok "reader case $name: $detail"
      else
        nope "reader case $name: $detail"
      fi
    done < "$TMP_ROOT/drive.out"
  else
    nope "the reader driver did not run: $(tail -3 "$TMP_ROOT/drive.err")"
  fi
fi

echo ""

# ===========================================================================
# PART 7 -- the committed screens are what the renderers produce
# ===========================================================================
echo "Part 7: the baked screens against the renderers"

if [ "$STATIC" = "1" ]; then
  skip "--static was passed, so the screens were NOT re-rendered"
  note "that is 2 assertions not run, and they are the ones that tie"
  note "swipe/reader/SCREENS.tsv to swipe/level1/render.sh and"
  note "swipe/level2/render.sh. The slow row of scripts/test runs them."
else
  # The normalization is written here rather than called out of the generator,
  # so the committed file is compared against two independent readings of the
  # same renderer. Strip the renderers' three-space terminal indent, strip
  # trailing whitespace, prefix the pipe.
  FRESH="$TMP_ROOT/fresh-screens.tsv"
  : > "$FRESH"
  render_fail=0
  for lvl in $LEVELS; do
    [ "$lvl" = "0" ] && continue
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      path="$(swipe/level1/render.sh --model-path "$m" 2>/dev/null)"
      if [ -z "$path" ]; then
        printf 'no module called %s\n' "$m" >> "$TMP_ROOT/render.err"
        render_fail=1
        continue
      fi
      out="$("swipe/level$lvl/render.sh" --model "$path" --screen 2>/dev/null)"
      rc=$?
      if [ "$rc" -ne 0 ] || [ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ]; then
        printf 'EMPTY\t%s\t%s\n' "$lvl" "$m" >> "$FRESH"
        continue
      fi
      n=0
      while IFS= read -r line; do
        n=$((n + 1))
        printf 'SCREEN\t%s\t%s\t%s\t%s\n' "$lvl" "$m" "$n" "$line" >> "$FRESH"
      done < <(printf '%s\n' "$out" | sed -e 's/^   //' -e 's/[[:space:]]*$//' -e 's/^/|/')
    done < <(awk -F'\t' '$1 == "ITEM" { print $12 }' "swipe/level$lvl/ITEMS.tsv" | LC_ALL=C sort -u)
  done

  if [ "$render_fail" = "0" ]; then
    ok "every model the corpora name resolves to a reading/ module"
  else
    nope "a model named by the corpora has no module: $(head -2 "$TMP_ROOT/render.err")"
  fi

  COMMITTED="$TMP_ROOT/committed-screens.tsv"
  awk -F'\t' -v OFS='\t' '$1 == "SCREEN" { print $1, $2, $3, $4, $5 } $1 == "EMPTY" { print $1, $2, $3 }' \
    "$SCREENS" > "$COMMITTED"
  if diff -q "$COMMITTED" "$FRESH" > /dev/null 2>&1; then
    # awk on field 1, not grep on a prefix. The fresh file carries no
    # SCREENFMT row so a prefix grep is right here by accident, and the
    # generator was wrong the same way over the committed file, which does.
    fresh_n=$(awk -F'\t' '$1 == "SCREEN" { n++ } END { print n + 0 }' "$FRESH")
    ok "swipe/reader/SCREENS.tsv is byte for byte what the renderers produce ($fresh_n lines)"
  else
    nope "swipe/reader/SCREENS.tsv is stale. Run swipe/reader/render-screens.sh:"
    diff "$COMMITTED" "$FRESH" > "$TMP_ROOT/screens-fresh.diff" 2>&1 || true
    sed -n "1,8p" "$TMP_ROOT/screens-fresh.diff" | sed "s/^/          /"
  fi
fi

echo ""

# ===========================================================================
# PART 8 -- what this run did not check
# ===========================================================================
echo "Part 8: what this run did not check"
note "No browser ran. The rendering, the touch gestures, the document\$"
note "subscription and the LAYOUT are read as text here, never executed."
note "The layout checks in part 5 are the weakest thing in this file: they"
note "assert that the cap and the sticky row exist, not that the question"
note "lands above the fold. A REAL BROWSER READ IT ON 2026-10-19 at 390x844"
note "against the published site, and the dock held at every item measured:"
note "298px at level 1, 269px at level 2, 384px worst case, never off screen."
note "That reading also found 70 of 432 claims wrapping to four lines or more"
note "and 198px of level 2 pin sitting behind the dock, which was tla-7xql.15."
note "THE STACK AND THE VIEWPORT WERE READ IN A BROWSER on 2026-10-19 under"
note "tla-7xql.16, at a true 390x844 with touch emulation on, against a mirror"
note "of the published site carrying this tree's swipe.js and swipe.css. The"
note "document has 0px of scroll room at every rung, and the lowest element"
note "the reader draws lands 10px inside the bottom edge at every step and"
note "with the stats panel open. The touch-action chain from the model screen"
note "up to html reads auto at all 12 elements, and a real horizontal touch"
note "drag moved it 234px in a 593px screen. Nothing in THIS suite sees any"
note "of that: it is read as text here and the reading is in swipe/README.md."
note "A localhost run cannot reproduce the instant-navigation hazard on its"
note "own: the theme normalizes its sitemap by protocol and hostname and"
note "never by port, so instant navigation declines every link on a local"
note "server. Mapping the real hostname to the local port does reproduce it,"
note "and swipe/README.md carries the invocation. That is how the class"
note "removal was read, with a window sentinel saying the document was never"
note "replaced. Part 6 drives the same rule here with no browser at all."
note "A STEP IS THE WHOLE PAGE since tla-7xql.18, and the reading that forced"
note "it is central's rather than this suite's: Chrome at a true 390x844"
note "against the published build, model step open, where the counts took 29.6"
note "pixels, the card 304, the menu 172 and the padding and gaps 62, leaving"
note "the step 276.4 and the model screen inside it 66.3 against the 438 its"
note "content wanted. Nothing here can see a pixel. What IS driven is the"
note "chrome decision over all 24 states and the scroller-decline table in"
note "both directions, and the 120 pixels the menu collapse returns at rest is"
note "arithmetic off the stylesheet rather than a second browser reading."
note "THE CLAIM LEFT THE STEP under tla-7xql.19, on a second reading in the"
note "same browser the same afternoon: the model body went from 480.0 pixels"
note "to 613.9 when the claim was hidden. The fit scan in part 5 is the ONE"
note "check in this file about what the reader is shown rather than about what"
note "the code computes, and it is still not a browser reading: it is a scan"
note "over the payload against four numbers a browser gave us. It can tell you"
note "a model gained lines. It cannot tell you the stylesheet changed under it,"
note "which is why the constants block above PART 1 says what invalidates them."
note "The shown-roots rule itself is gated by harness/test-swipe-enabled.sh"
note "and harness/test-swipe-subscript.sh. This suite checks the obligations"
note "and the machine from each model's .cfg, and part 7 ties the committed"
note "screens to the renderers those two suites hold to the rule."
if [ "$skip_count" -gt 0 ]; then
  note "$skip_count checks were SKIPPED on this box, and the lines above say which."
fi

echo ""
if [ "$fail_count" -eq 0 ]; then
  echo "  $pass_count passed, $skip_count skipped"
  exit 0
fi
echo "  $pass_count passed, $fail_count FAILED, $skip_count skipped"
exit 1
