#!/usr/bin/env bash
# emit-items.sh -- the published payload of the swipe reader (beads
# tla-7xql.12 and tla-7xql.14, epic tla-7xql).
#
# Reads the three swipe corpora and the baked model screens and writes one
# JSON document to stdout. scripts/build-docs.sh publishes it beside the
# reader page, and harness/test-swipe-reader.sh runs this script directly so
# the gate reads the real emitter rather than a copy of it.
#
# ===========================================================================
# THIS IS THE ONE PLACE THAT DECIDES WHICH FIELDS MAY SHIP
# ===========================================================================
#
# The rule is narrow rather than absent. The page has no server, so it cannot
# grade without the baked verdict, and the verdict is therefore in the source
# whatever we do. So: ship the verdict and nothing else that bears on the
# answer.
#
# LEVEL 0, eleven fields in the corpus and seven on the page:
#
#    2  id        the log needs it, so a swipe can be recorded against an item
#    3  template  the stats panel splits accuracy by family
#    4  ask       decision D5: the reader-visible tag
#    6  swipe     the baked verdict, which is what the page grades against
#    9  claim     the line the reader reads
#   11  flash     the correction or the reason, which L2 says is not optional
#
# plus `level`, which the corpus carries in its directory name rather than in
# a field, and which the page needs to know whether to draw a model screen.
#
# LEVEL 1 adds two, and both are the question rather than the premise:
#
#   12  model     the module the item is about, which keys its screen
#   13  pin       the pinned state, as a list of conjuncts
#
# LEVEL 2 adds three, which is level 1's pin split into the two halves a step
# has, plus the pin's own constants:
#
#   13  pre       the state the step starts from
#   14  post      the step's own formula, over primed variables
#   15  binds     the pin's constants, or an empty list
#
# WHY THE PIN SHIPS WHEN THE KIND DOES NOT. The reader cannot be asked
# whether `ENABLED Pop` holds without being told where. The pin is the
# question's subject, and harness/swipe/stemblind.sh already treats it that
# way: level 1 drives the stem-blind probe with `--surface 9,13` and level 2
# with `--surface 9,13,14,15`, so the pin is part of the surface a judge is
# allowed to see while the model stays the premise it withholds.
#
# WHAT STAYS BEHIND, at every level:
#
#    5  kind      true, false, vacuous, illformed, wronglevel or unparsed.
#                 Strictly more than the page needs, because every down kind
#                 bakes to one swipe and the page grades on the swipe. It is
#                 the answer in a sharper form than field 6 gives it
#    7  rc_claim  level 0's ASSUME exit code. A bake artifact
#    7  rc        the level 1 and 2 exit code. The same, and five-valued, so
#                 it splits the three down kinds the swipe merges
#    8  rc_wf     level 0's well-formedness probe. The same again
#    8  pin_states  how many states the pin admits. A bake artifact
#   10  vacuity   the vacuity witness, which STATES THE ANSWER IN PROSE. For a
#                 vacuous item it is an expression holding exactly when the
#                 item is vacuous, so shipping it hands over the down swipe
#
# ===========================================================================
# THE MODEL SCREEN IS READ, NOT RENDERED
# ===========================================================================
#
# swipe/reader/SCREENS.tsv holds every screen, baked by
# swipe/reader/render-screens.sh. This script runs no renderer and starts no
# JVM, because .github/workflows/pages.yml installs Python and nothing else
# and scripts/build-docs.sh calls this script on that runner. The generator's
# header carries the rest of that argument.
#
# A MODEL WHOSE SCREEN RENDERS EMPTY IS REPORTED RATHER THAN SERVED. Ring is
# the one of the 33 reading/ modules that does it: its actions live in the
# PlusCal translation block under names the shown-roots rule does not reach.
# An item about such a model would arrive as a pin and a claim with no premise
# under them, so its items are dropped, a line goes to stderr, and the payload
# carries a `withheld` block so the page can say so too. No shipped item is
# about Ring today, so this path is exercised by the gate's control rather
# than by the corpus.
#
# A MODEL WITH NO SCREEN ROWS AND NO EMPTY ROW IS A DIFFERENT CASE AND DIES.
# That is a stale SCREENS.tsv, not a model that cannot be drawn, and the two
# must not behave the same. Withholding items because the generator was not
# re-run would be a silent corpus shrink.
#
# ===========================================================================
# THE ID IS IN THE DATA AND MUST NOT REACH THE CARD
# ===========================================================================
#
# swipe/README.md records that ids ran in kind order inside each template for
# the first sixteen items: 01 to 06 true, 07 to 12 false, 13 and 14 vacuous,
# 15 and 16 do not evaluate. L0-T1-09 carries its own answer in its name.
# harness/swipe/stemblind.sh hashes the id rather than emitting it for exactly
# this reason.
#
# The log needs the id and the card must never print it. The emitter cannot
# enforce that, so swipe.js carries the rule beside the renderer and
# harness/test-swipe-reader.sh asserts the page source never writes an id into
# the card.
#
# ===========================================================================
# ESCAPING
# ===========================================================================
#
# 100 of the 240 level 0 claims carry a backslash and 14 carry a double quote,
# and a pin is TLA+ throughout, so the escaper is load-bearing rather than
# defensive. Every escape below is emitted as a \uXXXX sequence, which means
# this script never has to write a lone backslash into an awk replacement and
# never has to reason about how many layers of awk, shell and JSON are peeling
# it. < and > are escaped too, so a claim can never close a script element in
# the published HTML.
#
# Usage:  swipe/reader/emit-items.sh [--root DIR] [--screens FILE]
# Exit:   0 on success, 1 when a source file is missing or malformed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SWIPE_ROOT="$REPO_ROOT/swipe"
SCREENS="$REPO_ROOT/swipe/reader/SCREENS.tsv"

while [ $# -gt 0 ]; do
  case "$1" in
    --root)    SWIPE_ROOT="$2"; shift 2 ;;
    --screens) SCREENS="$2"; shift 2 ;;
    -h|--help)
      sed -n '1,8p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "emit-items.sh: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# The levels this emitter publishes, in the order the payload lists them. A
# level is a directory under swipe/, so adding one is adding a directory and
# a row here rather than editing the body below.
LEVELS="0 1 2"

for lvl in $LEVELS; do
  for f in "$SWIPE_ROOT/level$lvl/ITEMS.tsv" "$SWIPE_ROOT/level$lvl/TEMPLATES.tsv"; do
    if [ ! -f "$f" ]; then
      echo "emit-items.sh: no such file: $f" >&2
      exit 1
    fi
  done
done
if [ ! -f "$SCREENS" ]; then
  echo "emit-items.sh: no such file: $SCREENS" >&2
  echo "  Run swipe/reader/render-screens.sh to bake the model screens." >&2
  exit 1
fi

# The format version of the PUBLISHED PAYLOAD, which is a different contract
# from the exported log's SWIPEFMT version. The page refuses a payload it does
# not know, so a later emitter that changes the field set has to move this and
# the reader together.
#
# 1 was level 0 alone, six fields and no screens. 2 adds the level field, the
# two pinned rungs and the screens block.
PAYLOAD_VERSION=2

# ---------------------------------------------------------------------------
# One stream, with the level prepended as field 1, so one awk program reads
# all three corpora and the per-level field maps live in one place. The
# corpora differ in width (11, 13 and 15 fields) and in what fields 7 and 8
# mean, so a program that read them by filename would carry the same table
# anyway with the mapping further from the row.
# ---------------------------------------------------------------------------
levelled_items() {
  local lvl
  for lvl in $LEVELS; do
    awk -F'\t' -v OFS='\t' -v lvl="$lvl" \
      '$1 == "ITEM" { $1 = lvl OFS "ITEM"; print }' \
      "$SWIPE_ROOT/level$lvl/ITEMS.tsv"
  done
}

levelled_templates() {
  local lvl
  for lvl in $LEVELS; do
    awk -F'\t' -v OFS='\t' -v lvl="$lvl" \
      '$1 == "TPL" { print lvl, $2, $3 }' \
      "$SWIPE_ROOT/level$lvl/TEMPLATES.tsv"
  done
}

STREAM="$(mktemp)"
TPLSTREAM="$(mktemp)"
# shellcheck disable=SC2317
cleanup() { rm -f "$STREAM" "$TPLSTREAM"; }
trap cleanup EXIT

levelled_items > "$STREAM"
levelled_templates > "$TPLSTREAM"

if [ ! -s "$STREAM" ]; then
  echo "emit-items.sh: no ITEM rows in any corpus" >&2
  exit 1
fi
if [ ! -s "$TPLSTREAM" ]; then
  echo "emit-items.sh: no TPL rows in any TEMPLATES.tsv" >&2
  exit 1
fi

awk -F'\t' \
  -v payload_version="$PAYLOAD_VERSION" \
  -v templates_file="$TPLSTREAM" \
  -v screens_file="$SCREENS" \
  -v levels="$LEVELS" '
  # Escape one field for JSON. Every escape is a \uXXXX sequence so that no
  # lone backslash ever has to survive awk string processing.
  function jesc(s,   i, n, c, out) {
    out = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
      c = substr(s, i, 1)
      if      (c == "\\") out = out "\\u005c"
      else if (c == "\"") out = out "\\u0022"
      else if (c == "<")  out = out "\\u003c"
      else if (c == ">")  out = out "\\u003e"
      else if (c == "&")  out = out "\\u0026"
      else if (c == "\t") out = out "\\u0009"
      # A model screen is many lines in one value, so the newline has to be
      # escaped as well. Level 0 never needed it, since a claim is one line.
      else if (c == "\n") out = out "\\u000a"
      else if (c == "\r") out = out "\\u000d"
      else                out = out c
    }
    return out
  }

  function die(msg) {
    print "emit-items.sh: " msg > "/dev/stderr"
    bad = 1
    exit 1
  }

  # A TLA+ conjunction list as a JSON array of its conjuncts. The separator is
  # written as a character class so this program never carries a conjunction
  # through a layer that reads it as a path. Splitting here rather than in the
  # page keeps the page free of TLA+ syntax, and it is the same split
  # swipe/level1/render.sh does for a terminal.
  function conj_array(s,   n, parts, i, out) {
    gsub(/[ \t]*\/[\\][ \t]*/, "\001", s)
    n = split(s, parts, "\001")
    out = "["
    for (i = 1; i <= n; i++) {
      if (parts[i] == "") continue
      out = out (out == "[" ? "" : ", ") "\"" jesc(parts[i]) "\""
    }
    return out "]"
  }

  # The pin constants of a level 2 item, which field 15 writes comma
  # separated. A dash means the pin names no constant.
  function bind_array(s,   n, parts, i, out) {
    if (s == "-" || s == "") return "[]"
    n = split(s, parts, ",")
    out = "["
    for (i = 1; i <= n; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", parts[i])
      if (parts[i] == "") continue
      out = out (out == "[" ? "" : ", ") "\"" jesc(parts[i]) "\""
    }
    return out "]"
  }

  BEGIN {
    # The template names come out of the TEMPLATES.tsv files rather than a map
    # written here, for the reason every derived list in this repo gives: a
    # hand-kept copy is right until somebody adds a template. The key is
    # level and id together, so two levels are free to reuse an id.
    tcount = 0
    while ((getline line < templates_file) > 0) {
      split(line, tf, "\t")
      key = tf[1] ":" tf[2]
      if (key in tname) die("two templates share the key " key)
      tname[key] = tf[3]
      tcount++
    }
    close(templates_file)
    if (tcount == 0) die("no templates were read")

    # The baked screens. screen[level ":" model] holds the whole screen with
    # newlines between lines, and empty[] marks a model the renderer could not
    # draw. A model in neither map is a stale SCREENS.tsv and dies below.
    nscreen = 0
    while ((getline line < screens_file) > 0) {
      if (substr(line, 1, 1) == "#") continue
      nf = split(line, sf, "\t")
      if (sf[1] == "SCREENFMT") { screenfmt = sf[2]; continue }
      if (sf[1] == "EMPTY") {
        empty[sf[2] ":" sf[3]] = (nf >= 4 && sf[4] != "") ? sf[4] : "the model screen renders empty"
        continue
      }
      if (sf[1] != "SCREEN") continue
      key = sf[2] ":" sf[3]
      # Field 5 opens with a pipe that is not part of the line. The generator
      # header says why: without it a blank screen line is a trailing tab,
      # which an editor that strips trailing whitespace deletes in silence.
      text = substr(sf[5], 2)
      if (key in screen) screen[key] = screen[key] "\n" text
      else { screen[key] = text; nscreen++ }
    }
    close(screens_file)
    if (screenfmt == "") die("no SCREENFMT row in " screens_file)
    if (screenfmt != "1") die("SCREENFMT is " screenfmt " and this emitter reads 1")

    printf "{\n"
    printf "  \"payload_version\": %d,\n", payload_version
    printf "  \"levels\": ["
    nl = split(levels, lv, " ")
    for (i = 1; i <= nl; i++) printf "%s%s", (i > 1 ? ", " : ""), lv[i]
    printf "],\n"
    printf "  \"sources\": {"
    for (i = 1; i <= nl; i++)
      printf "%s\n    \"%s\": \"swipe/level%s/ITEMS.tsv\"", (i > 1 ? "," : ""), lv[i], lv[i]
    printf "\n  },\n"
    # The field set PER LEVEL, declared in the payload so the page and the
    # gate read the same list rather than each carrying one.
    printf "  \"fields\": {\n"
    printf "    \"0\": [\"id\", \"level\", \"template\", \"ask\", \"swipe\", \"claim\", \"flash\"],\n"
    printf "    \"1\": [\"id\", \"level\", \"template\", \"ask\", \"swipe\", \"claim\", \"flash\", \"model\", \"pin\"],\n"
    printf "    \"2\": [\"id\", \"level\", \"template\", \"ask\", \"swipe\", \"claim\", \"flash\", \"model\", \"pre\", \"post\", \"binds\"]\n"
    printf "  },\n"
    printf "  \"templates\": {"
    first = 1
    for (k in tname) {
      printf "%s\n    \"%s\": \"%s\"", (first ? "" : ","), jesc(k), jesc(tname[k])
      first = 0
    }
    printf "\n  },\n"
    n = 0
    withheld_n = 0
  }

  # ---- pass 1: which screens are used, and which items have none ----
  FNR == NR {
    if ($2 != "ITEM") next
    lvl = $1
    if (lvl == "0") next
    model = $13
    if (model == "") die("row " FNR " (" $3 ") carries no model name")
    key = lvl ":" model
    if (key in screen) { used[key] = 1; next }
    if (key in empty) {
      drop[key] = (key in drop) ? drop[key] + 1 : 1
      next
    }
    die("SCREENS.tsv has no screen and no EMPTY row for " model " at level " lvl \
        ". Re-run swipe/reader/render-screens.sh.")
  }

  # ---- pass 2 opens with the screens the corpus reaches ----
  FNR == 1 {
    printf "  \"screens\": {"
    first = 1
    for (k in used) {
      printf "%s\n    \"%s\": \"%s\"", (first ? "" : ","), jesc(k), jesc(screen[k])
      first = 0
    }
    printf "\n  },\n"
    printf "  \"items\": ["
  }

  $2 != "ITEM" { next }

  {
    lvl = $1
    id = $3; template = $4; ask = $5; swipe = $7; claim = $10; flash = $12

    want = (lvl == "0") ? 12 : (lvl == "1") ? 14 : 16
    if (NF != want) die("level " lvl " row " FNR " has " (NF - 1) " fields, expected " (want - 1))
    if (id == "" || template == "" || ask == "")
      die("row " FNR " (" id ") has an empty id, template or ask")
    if (claim == "" || flash == "")
      die("row " FNR " (" id ") has an empty claim or flash")
    if (swipe != "right" && swipe != "left" && swipe != "down")
      die("row " FNR " (" id ") has swipe \"" swipe "\", expected right, left or down")
    if (!((lvl ":" template) in tname))
      die("row " FNR " (" id ") names template " template ", which level " lvl " does not declare")

    if (lvl != "0") {
      model = $13
      key = lvl ":" model
      if (!(key in screen)) {
        # Reported, not served. The reason sits in the withheld block below.
        withheld_n++
        next
      }
    }

    n++
    printf "%s\n    {", (n > 1 ? "," : "")
    printf "\"id\": \"%s\", ", jesc(id)
    printf "\"level\": %s, ", lvl
    printf "\"template\": \"%s\", ", jesc(template)
    printf "\"ask\": \"%s\", ", jesc(ask)
    printf "\"swipe\": \"%s\", ", jesc(swipe)
    printf "\"claim\": \"%s\", ", jesc(claim)
    printf "\"flash\": \"%s\"", jesc(flash)
    if (lvl == "1") {
      printf ", \"model\": \"%s\"", jesc($13)
      printf ", \"pin\": %s", conj_array($14)
    } else if (lvl == "2") {
      printf ", \"model\": \"%s\"", jesc($13)
      printf ", \"pre\": %s", conj_array($14)
      printf ", \"post\": %s", conj_array($15)
      printf ", \"binds\": %s", bind_array($16)
    }
    printf "}"
  }

  END {
    if (bad) exit 1
    if (n == 0) {
      print "emit-items.sh: no ITEM rows survived, so there is nothing to publish" > "/dev/stderr"
      exit 1
    }
    printf "\n  ],\n"
    printf "  \"withheld\": ["
    first = 1
    for (k in drop) {
      split(k, kp, ":")
      printf "%s\n    {\"level\": %s, \"model\": \"%s\", \"items\": %d, \"reason\": \"%s\"}",
        (first ? "" : ","), kp[1], jesc(kp[2]), drop[k], jesc(empty[k])
      printf "" > "/dev/stderr"
      print "emit-items.sh: WITHHELD " drop[k] " item(s) about " kp[2] \
            " at level " kp[1] ": " empty[k] > "/dev/stderr"
      first = 0
    }
    printf "\n  ],\n"
    printf "  \"withheld_items\": %d,\n", withheld_n
    printf "  \"count\": %d\n", n
    printf "}\n"
  }
' "$STREAM" "$STREAM"
