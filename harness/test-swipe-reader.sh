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
# THE IMPORT CONTRACT IS EXECUTED where a script runtime exists. swipe.js
# exports its pure halves when a module system is present, so part 5 drives
# the refusal paths directly rather than grepping for a message. Part 5 SKIPS
# with a loud count where no runtime exists, and part 7 prints that count.
#
# THE SCREENS ARE RE-RENDERED, and that is the one part of this suite that
# starts a JVM. Part 6 drives swipe/level1/render.sh and swipe/level2/render.sh
# over every model the corpora use and requires swipe/reader/SCREENS.tsv to
# match byte for byte. It writes the normalization again rather than calling
# the generator's copy, so the committed file is compared against two
# independent readings of the same renderer.
#
# `--static` skips part 6 and nothing else. That is the split
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
#   at level 2 the premise does not fit above the dock. The screen is 296px
#   and the pin 327px against 575px of room, so 198px of pin sits BEHIND the
#   dock when the item is drawn. Scrolling reaches it, and the reader is not
#   told to. Filed as tla-7xql.15.
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
[ "$STATIC" = "1" ] && echo "  (--static: part 6, the screen re-render, is skipped)"
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
CODE="$TMP_ROOT/swipe.code.js"
sed 's#//.*##' "$READER_JS" | grep -vE '^[[:space:]]*(\*|/\*)' > "$CODE"

code_lines=$(wc -l < "$CODE")
if [ "$code_lines" -gt 200 ]; then
  ok "the comment strip left $code_lines lines of code to read"
else
  nope "stripping comments left only $code_lines lines, so the checks below read almost nothing"
fi

CSSCODE="$TMP_ROOT/swipe.code.css"
sed 's#/\*.*\*/##' "$READER_CSS" | grep -vE '^[[:space:]]*(\*|/\*)' > "$CSSCODE"
css_lines=$(wc -l < "$CSSCODE")
if [ "$css_lines" -gt 120 ]; then
  ok "the comment strip left $css_lines lines of style to read"
else
  nope "stripping comments left only $css_lines lines of CSS, so the checks below read almost nothing"
fi

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

echo ""

# ===========================================================================
# PART 6 -- the import contract, executed
# ===========================================================================
echo "Part 6: the import contract, executed"

JS_RUNTIME=""
for c in node nodejs; do
  if command -v "$c" > /dev/null 2>&1; then
    JS_RUNTIME="$c"
    break
  fi
done

if [ -z "$JS_RUNTIME" ]; then
  skip "no script runtime on this box, so the import refusals were NOT executed"
  note "that is 6 assertions not run. They are the ones that say a bad file is"
  note "refused rather than silently starting the record over."
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
note "and 198px of level 2 pin sitting behind the dock, which is tla-7xql.15."
note "A localhost run cannot reproduce the instant-navigation hazard: the"
note "theme normalizes its sitemap by protocol and hostname and never by"
note "port, so instant navigation declines every link on a local server."
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
