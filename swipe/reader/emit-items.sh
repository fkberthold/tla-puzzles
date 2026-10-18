#!/usr/bin/env bash
# emit-items.sh -- the published payload of the swipe reader (bead
# tla-7xql.12, epic tla-7xql).
#
# Reads swipe/level0/ITEMS.tsv and swipe/level0/TEMPLATES.tsv and writes one
# JSON document to stdout. scripts/build-docs.sh publishes it beside the
# reader page, and harness/test-swipe-reader.sh runs this script directly so
# the gate reads the real emitter rather than a copy of it.
#
# ===========================================================================
# SIX FIELDS SHIP AND FOUR DO NOT, AND THE FOUR ARE THE WHOLE POINT
# ===========================================================================
#
# ITEMS.tsv carries eleven fields. The page gets six of them:
#
#   2  id        the log needs it, so a swipe can be recorded against an item
#   3  template  the stats panel splits accuracy by family
#   4  ask       decision D5: the reader-visible tag, holds or implies
#   6  swipe     the baked verdict, which is what the page grades against
#   9  claim     the line the reader reads
#  11  flash     the correction or the reason, which L2 says is not optional
#
# The four that stay behind:
#
#   5  kind      true, false, vacuous, illformed or unparsed. Strictly more
#                than the page needs, because all three down kinds bake to one
#                swipe and the page grades on the swipe. It is also the answer
#                in a sharper form than field 6 gives it.
#   7  rc_claim  the exit code of ASSUME (claim). A bake artifact
#   8  rc_wf     the exit code of the well-formedness probe. The same
#  10  vacuity   the vacuity witness, which STATES THE ANSWER IN PROSE. For a
#                vacuous item it is an expression that holds exactly when the
#                item is vacuous, so shipping it hands over the down swipe
#
# Field 6 ships and it IS the answer, which looks like a contradiction and is
# not. A page with no server cannot grade without the verdict, so the answer
# is in the source whatever we do, and anybody who opens the developer tools
# can read it. harness/test-swipe-stemblind.sh asserts the same separation one
# level down: the stem file carries neither the witness nor the flash. The
# line is drawn at what the page SHOWS and at how much more than the verdict
# the payload carries, not at an unreachable secret.
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
# 100 of the 240 claims carry a backslash and 14 carry a double quote, so the
# escaper is load-bearing rather than defensive. Every escape below is emitted
# as a \uXXXX sequence, which means this script never has to write a lone
# backslash into an awk replacement and never has to reason about how many
# layers of awk, shell and JSON are peeling it. < and > are escaped too, so a
# claim can never close a script element in the published HTML.
#
# Usage:  swipe/reader/emit-items.sh [--items FILE] [--templates FILE]
# Exit:   0 on success, 1 when a source file is missing or malformed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ITEMS="$REPO_ROOT/swipe/level0/ITEMS.tsv"
TEMPLATES="$REPO_ROOT/swipe/level0/TEMPLATES.tsv"

while [ $# -gt 0 ]; do
  case "$1" in
    --items)     ITEMS="$2"; shift 2 ;;
    --templates) TEMPLATES="$2"; shift 2 ;;
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

for f in "$ITEMS" "$TEMPLATES"; do
  if [ ! -f "$f" ]; then
    echo "emit-items.sh: no such file: $f" >&2
    exit 1
  fi
done

# The format version of the PUBLISHED PAYLOAD, which is a different contract
# from the exported log's SWIPEFMT version. The page refuses a payload it does
# not know, so a later emitter that changes the field set has to move this and
# the reader together.
PAYLOAD_VERSION=1

emit() {
  awk -F'\t' \
    -v payload_version="$PAYLOAD_VERSION" \
    -v templates_file="$TEMPLATES" '
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
        else                out = out c
      }
      return out
    }

    function die(msg) {
      print "emit-items.sh: " msg > "/dev/stderr"
      bad = 1
      exit 1
    }

    BEGIN {
      # The template names come out of TEMPLATES.tsv rather than a map written
      # here, for the reason every derived list in this repo gives: a hand-kept
      # copy is right until somebody adds a template.
      tcount = 0
      while ((getline line < templates_file) > 0) {
        if (substr(line, 1, 4) != "TPL\t") continue
        split(line, tf, "\t")
        tcount++
        tid[tcount] = tf[2]
        tname[tcount] = tf[3]
      }
      close(templates_file)
      if (tcount == 0) die("no TPL rows in " templates_file)

      printf "{\n"
      printf "  \"payload_version\": %d,\n", payload_version
      printf "  \"source\": \"swipe/level0/ITEMS.tsv\",\n"
      printf "  \"fields\": [\"id\", \"template\", \"ask\", \"swipe\", \"claim\", \"flash\"],\n"
      printf "  \"templates\": {"
      for (i = 1; i <= tcount; i++) {
        printf "%s\n    \"%s\": \"%s\"", (i > 1 ? "," : ""), jesc(tid[i]), jesc(tname[i])
      }
      printf "\n  },\n"
      printf "  \"items\": ["
      n = 0
    }

    $1 != "ITEM" { next }

    {
      if (NF != 11) die("row " NR " has " NF " fields, expected 11")
      id = $2; template = $3; ask = $4; swipe = $6; claim = $9; flash = $11
      if (id == "" || template == "" || ask == "")
        die("row " NR " (" id ") has an empty id, template or ask")
      if (claim == "" || flash == "")
        die("row " NR " (" id ") has an empty claim or flash")
      if (swipe != "right" && swipe != "left" && swipe != "down")
        die("row " NR " (" id ") has swipe \"" swipe "\", expected right, left or down")
      n++
      printf "%s\n    {", (n > 1 ? "," : "")
      printf "\"id\": \"%s\", ", jesc(id)
      printf "\"template\": \"%s\", ", jesc(template)
      printf "\"ask\": \"%s\", ", jesc(ask)
      printf "\"swipe\": \"%s\", ", jesc(swipe)
      printf "\"claim\": \"%s\", ", jesc(claim)
      printf "\"flash\": \"%s\"}", jesc(flash)
    }

    END {
      if (bad) exit 1
      if (n == 0) {
        print "emit-items.sh: no ITEM rows found" > "/dev/stderr"
        exit 1
      }
      printf "\n  ],\n"
      printf "  \"count\": %d\n", n
      printf "}\n"
    }
  ' "$ITEMS"
}

emit
