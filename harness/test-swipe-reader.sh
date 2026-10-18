#!/usr/bin/env bash
# test-swipe-reader.sh -- the gate over the published swipe reader (bead
# tla-7xql.12, epic tla-7xql).
#
# Pins the RED invariant from the bead:
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
# that bears on the answer. Four fields of ITEMS.tsv are out, and the one
# that matters most is field 10, the vacuity witness, which states in TLA+
# exactly when the item is vacuous and so hands over the down swipe in prose.
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
# THE ITEM COUNT IS DERIVED TWICE. Part 1 counts ITEM rows in the corpus with
# its own scan and requires the payload to agree. Nothing below writes 240.
#
# THE LEAK SCAN HAS A NEGATIVE CONTROL. "No witness appears in the payload"
# passes vacuously over a scanner that extracts nothing, which is this bead's
# own defect wearing a green tick. So part 2 runs the same scan over a
# payload it has deliberately poisoned with the real witnesses and requires
# every one to be named.
#
# THE SHAPE CHECK HAS A NEGATIVE CONTROL for the same reason: part 2 feeds it
# an item line carrying a fifth key and requires a refusal.
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
# with a loud count where no runtime exists, and part 6 prints that count.
#
# NO TLC, NO JVM, NO BROWSER. Every verdict in the corpus was baked once by
# swipe/level0/bake.sh. This suite reads bytes. The tier boundary in
# scripts/test's header is the model checker, so this is a fast row.
#
# WHAT THIS SUITE CANNOT SEE, and part 6 prints it on every run: nothing here
# runs a browser, so the rendering, the gestures and the navigation.instant
# subscription are checked as text. The author drove all three through a real
# headless Chromium once, at the site's own origin, and the measurement is in
# the bead's merge commit. A localhost run cannot reproduce it: the theme
# matches a clicked link against its sitemap after overwriting only the
# protocol and the hostname, never the port, so instant navigation silently
# declines every link on any local server.
#
# Usage:  harness/test-swipe-reader.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

ITEMS="$REPO_ROOT/swipe/level0/ITEMS.tsv"
TEMPLATES="$REPO_ROOT/swipe/level0/TEMPLATES.tsv"
EMITTER="$REPO_ROOT/swipe/reader/emit-items.sh"
READER_JS="$REPO_ROOT/swipe/reader/swipe.js"
READER_CSS="$REPO_ROOT/swipe/reader/swipe.css"
GENERATOR="$REPO_ROOT/scripts/build-docs.sh"
MKDOCS="$REPO_ROOT/mkdocs.yml"

# The six fields the page may carry, in the order emit-items.sh writes them.
ALLOWED_KEYS="id template ask swipe claim flash"

# The four it may not. Field 5 is the kind, 7 and 8 are the bake's exit
# codes, and 10 is the vacuity witness.
FORBIDDEN_KEYS="kind rc_claim rc_wf vacuity"

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
echo ""

for f in "$ITEMS" "$TEMPLATES" "$EMITTER" "$READER_JS" "$READER_CSS" "$GENERATOR" "$MKDOCS"; do
  if [ ! -f "$f" ]; then
    nope "a source the reader is built from is missing: ${f#"$REPO_ROOT"/}"
  fi
done
if [ "$fail_count" -gt 0 ]; then
  echo ""
  echo "  $pass_count passed, $fail_count failed"
  exit 1
fi

# ---------------------------------------------------------------------------
# shape_errors <payload>
#
# Prints one line per item line whose key set is not exactly ALLOWED_KEYS in
# order. The regex pins the ORDER as well as the SET, which is what lets one
# check stand in for both.
#
# IT SELECTS EVERY LINE BETWEEN "items": [ AND THE CLOSE, not every line that
# already looks like an item. The first version of this function selected on
# /^\s*\{"id":/ and its own negative control walked straight through it: an
# item that gained a `kind` key AHEAD of the id no longer matched the
# selector, so it was never examined and the run came back clean. A checker
# that only inspects what already looks right is the defect this suite exists
# to catch, wearing the uniform of its own fix.
#
# Values are matched with [^"]* rather than with an escape-aware pattern,
# which is sound because emit-items.sh writes every quote in a value as
# ". Part 1 proves that separately by round-tripping every value against
# the corpus, so the two checks are not resting on each other.
# ---------------------------------------------------------------------------
shape_errors() {
  awk '
    /^[[:space:]]*"items": \[/ { inside = 1; next }
    inside && /^[[:space:]]*\],?[[:space:]]*$/ { inside = 0; next }
    inside && /[^[:space:]]/ {
      n += 1
      if ($0 !~ /^[[:space:]]*\{"id": "[^"]*", "template": "[^"]*", "ask": "[^"]*", "swipe": "[^"]*", "claim": "[^"]*", "flash": "[^"]*"\},?$/) {
        print "line " NR ": " substr($0, 1, 90)
      }
    }
    END { if (n == 0) print "line 0: no item lines at all" }
  ' "$1"
}

# ---------------------------------------------------------------------------
# witness_leaks <payload>
#
# Prints one line per vacuity witness from field 10 of the corpus that
# appears anywhere in the payload. A witness is a level 0 expression holding
# exactly when the item is vacuous, so one in the payload is the down swipe
# given away in TLA+.
#
# The scan reads the RAW payload rather than the unescaped values, so the
# witness is also hunted in its escaped form.
# ---------------------------------------------------------------------------
witness_leaks() {
  local payload="$1"
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
      if (index(body, $10) > 0)      { print $2 " :: " $10 }
      else if (index(body, esc($10)) > 0) { print $2 " (escaped) :: " $10 }
    }
  ' "$ITEMS"
}

# ---------------------------------------------------------------------------
# roundtrip_errors <payload>
#
# Prints one line per item whose claim or flash in the payload differs by one
# byte from the corpus, and one per id that is in one and not the other. The
# five \uXXXX escapes emit-items.sh writes are undone here rather than read
# past, so an escaper that mangled a backslash shows up as a mismatch.
#
# 100 of the 240 claims carry a backslash and 14 carry a double quote, so
# this is the check that says the escaping is right rather than merely
# present.
# ---------------------------------------------------------------------------
roundtrip_errors() {
  local payload="$1"
  awk -v payload="$payload" '
    function unesc(s) {
      gsub(/\\u0022/, "\"", s)
      gsub(/\\u003c/, "<",  s)
      gsub(/\\u003e/, ">",  s)
      gsub(/\\u0026/, "&",  s)
      gsub(/\\u005c/, "\\", s)
      return s
    }
    function field(line, key,   m, v) {
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
    /^[[:space:]]*\{"id":/ {
      id = field($0, "id")
      got[id] = 1
      ngot += 1
      if (!(id in want)) { print "payload has an id the corpus does not: " id; next }
      c = field($0, "claim")
      f = field($0, "flash")
      if (c != claim[id]) { print id " claim differs:\n    payload: " c "\n    corpus:  " claim[id] }
      if (f != flash[id]) { print id " flash differs:\n    payload: " f "\n    corpus:  " flash[id] }
    }
    END {
      for (id in want) { if (!(id in got)) print "corpus has an id the payload does not: " id }
      if (ngot == 0) print "the payload carried no item lines, so nothing was compared"
      if (nwant == 0) print "the corpus carried no ITEM rows, so nothing was compared"
    }
  ' "$ITEMS" "$payload"
}

# ===========================================================================
# PART 1 -- the payload against the corpus
# ===========================================================================
echo "Part 1: the payload is the corpus, six fields of it"

PAYLOAD="$TMP_ROOT/items.json"
if "$EMITTER" > "$PAYLOAD" 2> "$TMP_ROOT/emit.err"; then
  ok "swipe/reader/emit-items.sh runs"
else
  nope "swipe/reader/emit-items.sh failed: $(head -2 "$TMP_ROOT/emit.err")"
fi

# The count is derived here with this suite's own scan. The corpus is the
# oracle and nothing below writes the number.
corpus_n=$(grep -c '^ITEM' "$ITEMS")
payload_n=$(grep -c '^[[:space:]]*{"id":' "$PAYLOAD")
declared_n=$(sed -n 's/^[[:space:]]*"count": \([0-9][0-9]*\).*$/\1/p' "$PAYLOAD")

if [ "$payload_n" = "$corpus_n" ]; then
  ok "the payload carries one item per corpus row ($corpus_n)"
else
  nope "the payload carries $payload_n items and the corpus has $corpus_n rows"
fi

if [ "$declared_n" = "$corpus_n" ]; then
  ok "the payload's own count agrees ($declared_n)"
else
  nope "the payload declares count $declared_n against $corpus_n corpus rows"
fi

if [ "$corpus_n" -ge 200 ]; then
  ok "the corpus is at full size, so this run is not passing over a stub ($corpus_n)"
else
  nope "only $corpus_n ITEM rows were read, which is below the floor of 200"
fi

shape_out=$(shape_errors "$PAYLOAD")
if [ -z "$shape_out" ]; then
  ok "every item carries exactly the six published fields, in order"
else
  nope "item lines with the wrong field set:"
  head -5 <<<"$shape_out" | sed 's/^/          /'
fi

declared_fields=$(sed -n 's/^[[:space:]]*"fields": \[\(.*\)\],*$/\1/p' "$PAYLOAD" | tr -d '", ')
if [ "$declared_fields" = "$(printf '%s' "$ALLOWED_KEYS" | tr -d ' ')" ]; then
  ok "the payload's own fields header lists the six and only the six"
else
  nope "the fields header reads [$declared_fields]"
fi

rt_out=$(roundtrip_errors "$PAYLOAD")
if [ -z "$rt_out" ]; then
  ok "every claim and every flash round-trips byte for byte"
else
  nope "claims or flashes that differ from the corpus:"
  head -8 <<<"$rt_out" | sed 's/^/          /'
fi

empty_n=$(grep -cE '"(claim|flash)": ""' "$PAYLOAD")
if [ "$empty_n" = "0" ]; then
  ok "no item ships with an empty claim or an empty flash"
else
  nope "$empty_n items ship with an empty claim or flash"
fi

bad_swipe=$(grep -c '"swipe": "' "$PAYLOAD")
good_swipe=$(grep -cE '"swipe": "(right|left|down)"' "$PAYLOAD")
if [ "$bad_swipe" = "$good_swipe" ] && [ "$good_swipe" = "$corpus_n" ]; then
  ok "every baked verdict is right, left or down ($good_swipe)"
else
  nope "$good_swipe of $bad_swipe swipes are right, left or down, over $corpus_n rows"
fi

dup_n=$(grep -o '{"id": "[^"]*"' "$PAYLOAD" | sort | uniq -d | wc -l)
if [ "$dup_n" = "0" ]; then
  ok "no id is published twice"
else
  nope "$dup_n ids are published more than once"
fi

echo ""

# ===========================================================================
# PART 2 -- the four fields that may not ship, and the controls that say so
# ===========================================================================
echo "Part 2: the four withheld fields, and the controls"

key_hits=""
for k in $FORBIDDEN_KEYS; do
  if grep -qE "\"$k\"[[:space:]]*:" "$PAYLOAD"; then
    key_hits="$key_hits $k"
  fi
done
if [ -z "$key_hits" ]; then
  ok "the payload carries no key named kind, rc_claim, rc_wf or vacuity"
else
  nope "the payload carries a forbidden key:$key_hits"
fi

leak_out=$(witness_leaks "$PAYLOAD")
if [ -z "$leak_out" ]; then
  ok "no vacuity witness reaches the payload"
else
  nope "vacuity witnesses in the payload:"
  head -5 <<<"$leak_out" | sed 's/^/          /'
fi

# THE NEGATIVE CONTROL FOR THE LEAK SCAN. Poison a copy with the real
# witnesses and require every one to be named. Without this the scan above
# is "a scanner that finds nothing reports nothing wrong".
POISON="$TMP_ROOT/poisoned.json"
cp "$PAYLOAD" "$POISON"
awk -F'\t' '$1 == "ITEM" && $10 != "-" && $10 != "" { print "    {\"vacuity\": \"" $10 "\"}," }' \
  "$ITEMS" >> "$POISON"
expected_witnesses=$(awk -F'\t' '$1 == "ITEM" && $10 != "-" && $10 != "" { n += 1 } END { print n + 0 }' "$ITEMS")
poison_out=$(witness_leaks "$POISON")
poison_n=$(grep -c '::' <<<"$poison_out")
if [ "$expected_witnesses" -gt 0 ] && [ "$poison_n" = "$expected_witnesses" ]; then
  ok "the leak scan names all $expected_witnesses witnesses when they are planted"
else
  nope "the leak scan found $poison_n of $expected_witnesses planted witnesses, so it does not discriminate"
fi

# THE NEGATIVE CONTROL FOR THE SHAPE CHECK. One item line with a fifth key.
WIDENED="$TMP_ROOT/widened.json"
sed '0,/^[[:space:]]*{"id":/s//    {"kind": "vacuous", "id":/' "$PAYLOAD" > "$WIDENED"
widened_out=$(shape_errors "$WIDENED")
if [ -n "$widened_out" ]; then
  ok "the shape check refuses an item that gained a fifth key"
else
  nope "the shape check passed an item carrying a kind field, so it does not discriminate"
fi

echo ""

# ===========================================================================
# PART 3 -- the generator publishes the page, the data and the assets
# ===========================================================================
echo "Part 3: scripts/build-docs.sh publishes the reader"

# ---------------------------------------------------------------------------
# mk_minirepo <dest> <with-swipe: 1 or 0>
#
# The smallest tree scripts/build-docs.sh will run in, following
# harness/test-build-docs-reading.sh. puzzles/ is a real empty directory so
# the puzzle glob stays literal and its README guard drops it, and chapter/,
# exercises/ and reading/ are absent so their sections are skipped and the
# python3 concept pass never runs. That keeps this suite in the fast tier and
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

# THE PAGE MUST NOT NAME AN ITEM ID. swipe/README.md records that ids ran in
# kind order inside each template, so an id on the page is an answer on the
# page.
if [ -f "$PAGE" ] && grep -qE 'L0-T[0-9]+-[0-9]+' "$PAGE"; then
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
# PART 4 -- the reader's structural invariants, read as text
# ===========================================================================
echo "Part 4: the reader's wiring"

# EVERY CHECK IN THIS PART READS CODE WITH THE COMMENTS STRIPPED, and that is
# a finding rather than tidiness. The first version grepped the whole file
# for `document$`, and its own red run walked through it: the subscription
# was deleted from the code and the suite stayed green, because this file's
# header explains at length what document$ is for. A text gate over a
# well-commented file measures the comments.
#
# Line comments go first, then any line whose first non-blank character
# opens or continues a block comment. That covers the two comment styles
# swipe/reader/swipe.js actually uses, and a check below would go red rather
# than silently pass if a third style ever hid a line from it.
CODE="$TMP_ROOT/swipe.code.js"
sed 's#//.*##' "$READER_JS" | grep -vE '^[[:space:]]*(\*|/\*)' > "$CODE"

code_lines=$(wc -l < "$CODE")
if [ "$code_lines" -gt 200 ]; then
  ok "the comment strip left $code_lines lines of code to read"
else
  nope "stripping comments left only $code_lines lines, so the checks below read almost nothing"
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

if grep -q 'SWIPEFMT' "$CODE"; then
  ok "the exported log carries a version marker"
else
  nope "the reader writes no SWIPEFMT row, so the format is a dump rather than a contract"
fi

echo ""

# ===========================================================================
# PART 5 -- the import refuses what it cannot read
# ===========================================================================
echo "Part 5: the import contract, executed"

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
const byId = { "L0-T1-01": { id: "L0-T1-01", swipe: "right", template: "T1" } };
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
DRIVER_EOF

  if "$JS_RUNTIME" "$DRIVER" "$READER_JS" > "$TMP_ROOT/drive.out" 2> "$TMP_ROOT/drive.err"; then
    while read -r name verdict detail; do
      if [ "$verdict" = "OK" ]; then
        ok "import case $name: $detail"
      else
        nope "import case $name: $detail"
      fi
    done < "$TMP_ROOT/drive.out"
  else
    nope "the import driver did not run: $(tail -3 "$TMP_ROOT/drive.err")"
  fi
fi

echo ""

# ===========================================================================
# PART 6 -- what this suite did not check
# ===========================================================================
echo "Part 6: what this run did not check"
note "No browser ran. The rendering, the touch gestures and the document\$"
note "subscription are read as text here, never executed."
note "The author drove all three through headless Chromium once, at the site's"
note "own origin. A localhost run cannot: the theme normalizes its sitemap by"
note "protocol and hostname and never by port, so instant navigation declines"
note "every link on a local server and the hazard cannot reproduce there."
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
