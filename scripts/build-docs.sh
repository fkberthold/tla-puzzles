#!/usr/bin/env bash
# Build the docs/ tree from puzzle READMEs and reference files.
# One page per puzzle. Inlines solution files as collapsed spoilers.
# Filesystem-only — no bd dependency for the structural part; concept tags
# are cached separately into /tmp/puzzle_concepts.json by a precursor step
# (or fall back to no chips).
set -euo pipefail
cd "$(dirname "$0")/.."

DOCS=docs
mkdir -p "$DOCS/curriculum" "$DOCS/reference" "$DOCS/reference/modules" "$DOCS/about" "$DOCS/stylesheets"

# ===========================================================================
# THE TLA+ RELEASE PIN — DERIVED, NOT COPIED
#
# The learner install instructions in getting-started.md must name the SAME
# tla2tools release the project's own CI and scripts/setup install. They did
# not, until bead tla-urv: this file hardcoded the `releases/latest/download/`
# form of the jar URL, and GitHub's `latest` SKIPS
# prereleases — v1.8.0 is flagged prerelease, so that URL resolved to v1.7.4,
# published 2024-08-05. The site therefore told learners to install a 2024
# toolchain while every V2-PLAN.md §5 constant that grades them was measured
# on a 2026 one. Same trap bead tla-5b4 removed from CI; it survived here.
#
# So the pin is READ FROM scripts/setup rather than written again. There is no
# fourth copy to drift. scripts/cibuild phase 1 cross-checks the copies that
# genuinely must exist (scripts/setup, the workflow, cibuild itself, README.md)
# and asserts that this file never re-hardcodes one.
# ===========================================================================
TLA_RELEASE="$(sed -n 's/^TLA_RELEASE="\(.*\)"$/\1/p' scripts/setup)"
if [ -z "$TLA_RELEASE" ]; then
  echo "build-docs.sh: could not read TLA_RELEASE from scripts/setup." >&2
  echo "  The learner install instructions derive the pin from there; refusing" >&2
  echo "  to emit docs with an unresolved toolchain URL." >&2
  exit 1
fi
TLA_JAR_URL="https://github.com/fkberthold/tla-puzzles/releases/download/${TLA_RELEASE}/tla2tools.jar"

# Copy hand-authored module reference pages from module-docs/
if [ -d module-docs ]; then
  cp module-docs/*.md "$DOCS/reference/modules/"
fi

# ---- index.md (top-level landing) ----
cp README.md "$DOCS/index.md"
sed -i \
  -e 's|](JUDGMENTS\.md)|](reference/judgments.md)|g' \
  -e 's|](CURRICULUM_MAP\.md)|](reference/curriculum-map.md)|g' \
  -e 's|](QUALITY_GATE\.md)|](reference/quality-gate.md)|g' \
  -e 's|](SCAFFOLDING_MAP\.md)|](reference/scaffolding-map.md)|g' \
  -e 's|](LICENSE)|](about/license.md)|g' \
  "$DOCS/index.md"

# ---- reference pages from canonical docs ----
cp QUALITY_GATE.md  "$DOCS/reference/quality-gate.md"
cp CURRICULUM_MAP.md "$DOCS/reference/curriculum-map.md"
cp JUDGMENTS.md     "$DOCS/reference/judgments.md"
cp SCAFFOLDING_MAP.md "$DOCS/reference/scaffolding-map.md"

# In the canonical root files, links use ALL_CAPS sibling filenames; in the
# rendered site they need lowercase sibling filenames. Rewrite cross-refs.
sed -i \
  -e 's|](SCAFFOLDING_MAP\.md\(#[a-z0-9-]*\)\?)|](scaffolding-map.md\1)|g' \
  -e 's|](CURRICULUM_MAP\.md\(#[a-z0-9-]*\)\?)|](curriculum-map.md\1)|g' \
  -e 's|](JUDGMENTS\.md\(#[a-z0-9-]*\)\?)|](judgments.md\1)|g' \
  -e 's|](QUALITY_GATE\.md\(#[a-z0-9-]*\)\?)|](quality-gate.md\1)|g' \
  "$DOCS/reference/quality-gate.md" \
  "$DOCS/reference/scaffolding-map.md"
{ echo "# License"; echo; cat LICENSE; } > "$DOCS/about/license.md"

# ---- concept index (built by separate Python script) ----
if command -v python3 >/dev/null && [ -f /tmp/puzzle_concepts.json ]; then
  python3 scripts/build-concept-index.py >/dev/null 2>&1 || true
fi

# Reference dir nav order (awesome-pages)
cat > "$DOCS/reference/.pages" <<'EOF'
title: Reference
nav:
  - Curriculum Map: curriculum-map.md
  - Quality Gate: quality-gate.md
  - Scaffolding Map: scaffolding-map.md
  - Judgment Decision Tree: judgments.md
  - Concept Index: concepts.md
  - Standard Modules: modules
EOF

# Modules dir nav order
cat > "$DOCS/reference/modules/.pages" <<'EOF'
title: Standard Modules
nav:
  - Integers.md
  - Naturals.md
  - Sequences.md
  - FiniteSets.md
  - TLC.md
  - Apalache.md
EOF

# ---- helper: classify prefix into tier slug ----
classify() {
  local prefix="$1"
  case "$prefix" in
    T0a|T0b|T0c|T0d|T0e) echo "tier-0" ;;
    T67)             echo "final" ;;
    A*)              echo "apalache" ;;
    J*)              echo "judgments" ;;
    R*)
      local n="${prefix#R}"; n="${n#0}"
      case "$n" in
        1|2|3)   echo "tier-2" ;;
        4|5)     echo "tier-3" ;;
        6|7)     echo "tier-4" ;;
        8|9)     echo "tier-5" ;;
        10|11)   echo "tier-6" ;;
        12|13)   echo "tier-7" ;;
        *)       echo "tier-?" ;;
      esac
      ;;
    C01)             echo "tier-4" ;;
    C02)             echo "tier-6" ;;
    T*)
      local n="${prefix#T}"; n="${n#0}"
      case "$n" in
        [1-8])           echo "tier-1" ;;
        9|1[0-9]|2[0-5]) echo "tier-2" ;;
        2[6-9]|3[0-4])   echo "tier-3" ;;
        3[5-9]|4[0-1])   echo "tier-4" ;;
        4[2-9])          echo "tier-5" ;;
        5[0-9])          echo "tier-6" ;;
        6[0-6])          echo "tier-7" ;;
        67)              echo "final" ;;
        *)
          if [[ "$prefix" =~ ^T([0-9]+)[a-z]$ ]]; then
            local base="${BASH_REMATCH[1]}"
            if   [ "$base" -ge 1 ]  && [ "$base" -le 8 ];  then echo "tier-1"
            elif [ "$base" -ge 9 ]  && [ "$base" -le 25 ]; then echo "tier-2"
            elif [ "$base" -ge 26 ] && [ "$base" -le 34 ]; then echo "tier-3"
            elif [ "$base" -ge 35 ] && [ "$base" -le 41 ]; then echo "tier-4"
            elif [ "$base" -ge 42 ] && [ "$base" -le 49 ]; then echo "tier-5"
            elif [ "$base" -ge 50 ] && [ "$base" -le 59 ]; then echo "tier-6"
            elif [ "$base" -ge 60 ] && [ "$base" -le 66 ]; then echo "tier-7"
            else echo "tier-?"
            fi
          else
            echo "tier-?"
          fi
          ;;
      esac
      ;;
    *) echo "tier-?" ;;
  esac
}

# ---- helper: tier label from slug ----
tier_label() {
  case "$1" in
    tier-0) echo "Tier 0 — Prelude" ;;
    tier-1) echo "Tier 1 — PlusCal Basics" ;;
    tier-2) echo "Tier 2 — Data Structures" ;;
    tier-3) echo "Tier 3 — Pure TLA+ Pivot" ;;
    tier-4) echo "Tier 4 — Multi-Process & Sync" ;;
    tier-5) echo "Tier 5 — Temporal & Fairness" ;;
    tier-6) echo "Tier 6 — Spec Structure & Refinement" ;;
    tier-7) echo "Tier 7 — Production Craft" ;;
    apalache) echo "Apalache Track" ;;
    judgments) echo "Judgment Intersticials" ;;
    final) echo "Final Capstone" ;;
    *) echo "" ;;
  esac
}

# ---- helper: pick the spoiler emoji for a solution file ----
solution_label() {
  local fname="$1"  # e.g., Tick.tla, Clock_buggy.tla, Apalache.tla
  case "$fname" in
    Apalache.tla)         echo "📖 Apalache library module — $fname" ;;
    *_buggy.tla|*_buggy.cfg) echo "🐛 Starter (buggy) — $fname" ;;
    *.cfg)                echo "⚙️  TLC config — $fname" ;;
    *)                    echo "🔒 Solution — $fname" ;;
  esac
}

# ---- helper: render concept chips from /tmp/puzzle_concepts.json ----
render_chips() {
  local prefix="$1"
  if [ ! -f /tmp/puzzle_concepts.json ]; then return; fi
  python3 - "$prefix" <<'PYEOF'
import json, sys
prefix = sys.argv[1]
data = json.load(open('/tmp/puzzle_concepts.json'))
labels = data.get(prefix, [])
if not labels: sys.exit(0)
chips = []
for l in labels:
    cls, _, name = l.partition(':')
    pretty = name.replace('-', ' ').replace('_', ' ')
    cls_emoji = {'concept':'•', 'apa':'⚡', 'workflow':'🛠'}.get(cls, '·')
    chips.append(f'`{cls_emoji} {pretty}`')
print(' '.join(chips))
PYEOF
}

# ---- helper: render "Useful Modules:" line from puzzle solution EXTENDS ----
# Parses the canonical solution .tla (the one matching the puzzle dir name),
# extracts EXTENDS, filters to stdlib modules, emits links to reference pages.
render_useful_modules() {
  local dir="$1"
  local prefix="$2"
  if [ ! -d "$dir/solution" ]; then return; fi
  python3 - "$dir" "$prefix" <<'PYEOF'
import re, sys, os, glob
dir_path, prefix = sys.argv[1], sys.argv[2]
sol = os.path.join(dir_path, 'solution')

# Find canonical .tla — prefer one whose name matches the dir's main module,
# otherwise take the first non-buggy non-Apalache file.
candidates = []
for f in sorted(glob.glob(os.path.join(sol, '*.tla'))):
    base = os.path.basename(f)
    if 'Apalache.tla' == base or '_buggy' in base or '_TTrace_' in base:
        continue
    candidates.append(f)
if not candidates: sys.exit(0)

stdlib = {'Integers', 'Naturals', 'Sequences', 'FiniteSets', 'TLC', 'Apalache'}
seen = set()
for f in candidates:
    try:
        text = open(f).read()
    except Exception:
        continue
    for m in re.finditer(r'^EXTENDS\s+([^\n]+)$', text, flags=re.MULTILINE):
        for name in m.group(1).split(','):
            name = name.strip()
            if name in stdlib:
                seen.add(name)

if not seen: sys.exit(0)
order = ['Integers', 'Naturals', 'Sequences', 'FiniteSets', 'TLC', 'Apalache']
chips = [f'[`{m}`](../../reference/modules/{m}.md)' for m in order if m in seen]
print(f"**Useful modules:** {' · '.join(chips)}")
PYEOF
}

# ---- helper: render "Builds on:" prereq links from /tmp/builds_on.json ----
render_builds_on() {
  local prefix="$1"
  if [ ! -f /tmp/builds_on.json ]; then return; fi
  python3 - "$prefix" <<'PYEOF'
import json, sys, re
prefix = sys.argv[1]
data = json.load(open('/tmp/builds_on.json'))
prereqs = data.get(prefix, [])
if not prereqs: sys.exit(0)

def tier_of(p):
    if re.match(r'^T0[a-d]$', p): return 'tier-0'
    if p == 'T67': return 'final'
    if p.startswith('A'): return 'apalache'
    if p.startswith('J'): return 'judgments'
    if p == 'C01': return 'tier-4'
    if p == 'C02': return 'tier-6'
    if p.startswith('R'):
        n = int(re.match(r'^R(\d+)', p).group(1))
        return ('tier-2' if 1<=n<=3 else 'tier-3' if 4<=n<=5 else 'tier-4' if 6<=n<=7
                else 'tier-5' if 8<=n<=9 else 'tier-6' if n in (10,11)
                else 'tier-7' if n in (12,13) else 'tier-?')
    if p.startswith('T'):
        m = re.match(r'^T(\d+)', p); n = int(m.group(1)) if m else 0
        return ('tier-1' if 1<=n<=8 else 'tier-2' if 9<=n<=25 else 'tier-3' if 26<=n<=34
                else 'tier-4' if 35<=n<=41 else 'tier-5' if 42<=n<=49
                else 'tier-6' if 50<=n<=59 else 'tier-7' if 60<=n<=66 else 'tier-?')
    return 'tier-?'

links = [f'[{p}](../{tier_of(p)}/{p}.md)' for p in prereqs]
print(f"**Builds on:** {', '.join(links)}")
PYEOF
}

# ---- helper: get prev/next puzzle prefixes for nav (within same tier) ----
# Note: MkDocs Material supplies cross-tier prev/next automatically once we
# have one-page-per-puzzle; we don't need to compute it here.

# ---- main: write one page per puzzle ----

# Collect all puzzles in (tier, sortkey, prefix, dir) tuples.
puzzle_index=$(mktemp)
for dir in puzzles/*/; do
  dir="${dir%/}"
  base=$(basename "$dir")
  prefix="${base%%-*}"
  [ -f "$dir/README.md" ] || continue
  tier=$(classify "$prefix")
  # Sort key: pad T0a-T0d so they sort before T01.
  case "$prefix" in
    T0a|T0b|T0c|T0d|T0e) sk="T00${prefix: -1}" ;;
    *)               sk="$prefix" ;;
  esac
  echo -e "${tier}\t${sk}\t${prefix}\t${dir}" >> "$puzzle_index"
done

# Sort by tier, then sortkey within tier.
LC_ALL=C sort -t$'\t' -k1,1 -k2,2 "$puzzle_index" > "${puzzle_index}.sorted"
mv "${puzzle_index}.sorted" "$puzzle_index"

# Write each puzzle as its own page.
while IFS=$'\t' read -r tier sk prefix dir; do
  out_dir="$DOCS/curriculum/${tier}"
  mkdir -p "$out_dir"
  out="$out_dir/${prefix}.md"

  # Frontmatter and concept-chip header
  {
    # Title comes from the puzzle's own README (its first H1)
    cp_chips=$(render_chips "$prefix")
    cp_modules=$(render_useful_modules "$dir" "$prefix")
    cp_builds_on=$(render_builds_on "$prefix")
    if [ -n "$cp_chips" ] || [ -n "$cp_modules" ] || [ -n "$cp_builds_on" ]; then
      # No `| head -1` here. `grep -m1` already yields at most one line, so the
      # head was pure redundancy — but under this file's `set -o pipefail` it
      # was also live: head closes the pipe the instant it has its line, grep
      # takes SIGPIPE, the pipeline reports 141, and `set -e` aborts the whole
      # docs build intermittently. Timing-dependent, so it fails on some runs
      # and not others (bead tla-kr9). grep reads the file directly, so there is
      # no pipe left to signal.
      h1=$(grep -m1 '^# ' "$dir/README.md")
      echo "$h1"
      echo ""
      [ -n "$cp_chips" ]    && { echo "$cp_chips"; echo ""; }
      [ -n "$cp_modules" ]  && { echo "$cp_modules"; echo ""; }
      [ -n "$cp_builds_on" ] && { echo "$cp_builds_on"; echo ""; }
      awk 'BEGIN{seen=0} /^# /{if(!seen){seen=1;next}} seen{print}' "$dir/README.md"
    else
      cat "$dir/README.md"
    fi
    echo ""
    echo "---"
    echo ""
    echo "## Inlined source"
    echo ""
    echo "*Reading on the web? Click each block below to reveal the file content.*"
    echo ""
  } > "$out"

  # Inline every solution file as a collapsed admonition.
  # Order: main .tla → main .cfg → buggy variants → cfg variants → Apalache.tla last
  if [ -d "$dir/solution" ]; then
    sol_dir="$dir/solution"

    # Build ordered file list.
    files=()
    # 1) Non-buggy, non-Apalache .tla files
    while IFS= read -r f; do files+=("$f"); done < <(
      find "$sol_dir" -maxdepth 1 -name "*.tla" \
        ! -name "*_buggy.tla" ! -name "Apalache.tla" ! -name "*_TTrace_*" 2>/dev/null \
        | LC_ALL=C sort
    )
    # 2) Their .cfg files (non-buggy)
    while IFS= read -r f; do files+=("$f"); done < <(
      find "$sol_dir" -maxdepth 1 -name "*.cfg" \
        ! -name "*_buggy.cfg" ! -name "*_test.cfg" 2>/dev/null \
        | LC_ALL=C sort
    )
    # 3) Buggy variants
    while IFS= read -r f; do files+=("$f"); done < <(
      find "$sol_dir" -maxdepth 1 \( -name "*_buggy.tla" -o -name "*_buggy.cfg" \) 2>/dev/null \
        | LC_ALL=C sort
    )
    # 4) Apalache.tla last (it's a library module, less interesting)
    if [ -f "$sol_dir/Apalache.tla" ]; then
      files+=("$sol_dir/Apalache.tla")
    fi

    for f in "${files[@]}"; do
      [ -f "$f" ] || continue
      fname=$(basename "$f")
      label=$(solution_label "$fname")
      ext="${fname##*.}"
      # Use 'tla' lexer for .tla; plain for .cfg
      lang="text"
      [ "$ext" = "tla" ] && lang="tla"

      {
        echo "??? note \"$label\""
        echo ""
        echo "    \`\`\`$lang"
        sed 's/^/    /' "$f"
        echo "    \`\`\`"
        echo ""
      } >> "$out"
    done
  fi

done < "$puzzle_index"
rm -f "$puzzle_index"

# ---- per-tier index pages (linkable overviews) ----
for tier_slug in tier-0 tier-1 tier-2 tier-3 tier-4 tier-5 tier-6 tier-7 apalache judgments final; do
  tier_dir="$DOCS/curriculum/${tier_slug}"
  if [ ! -d "$tier_dir" ]; then continue; fi
  label=$(tier_label "$tier_slug")
  {
    echo "# $label"
    echo ""
    echo "Puzzles in this section, in curriculum order:"
    echo ""
  } > "$tier_dir/index.md"

  # List puzzles in their canonical order (re-derive sortkey for stable listing)
  for f in "$tier_dir"/*.md; do
    fname=$(basename "$f" .md)
    [ "$fname" = "index" ] && continue
    # Pull H1 title from the page
    title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
    echo "- [$title](${fname}.md)" >> "$tier_dir/index.md"
  done
done

# ===========================================================================
# THE EXERCISE SETS: ONE PAGE PER CHAPTER, DERIVED FROM THE TREE
#
# Bead tla-jaob.1. The ch02 through ch13 sets are the best-tested content in
# this repo, 221 assertions in harness/test-printed-commands.sh, and until now
# the site showed none of them. This section publishes the statements. It
# publishes no references/ and it changes nothing under curriculum/.
#
# THE CHAPTER LIST IS DERIVED, NEVER WRITTEN. A hand-kept list is right until
# somebody adds a chapter and forgets. Bead tla-i3zu found exactly that in
# harness/test-printed-commands.sh, which had stopped at ch.11 while ch.12 and
# ch.13 were live, so the gate was green because it was not looking.
#
# WHY THE GLOB IS DUPLICATED RATHER THAN SHARED. derive_exercise_chapters
# below is the same glob as derive_chapters in harness/test-printed-commands.sh
# :148-165, and harness/test-build-docs-exercises.sh carries a third copy.
# Nothing here is sourceable, and the bead that wrote this could not touch the
# other two files. The third copy is deliberate: a test that imported this
# function could not catch a narrowed glob, which is the mutation tla-i3zu
# planted. These two are duplication, and whoever gets to extract a shared
# derivation should take all three.
#
# THE NON-CHAPTER AUDIT IS NOT DUPLICATED. exercises/templates/ carries an
# EXERCISES.md and is not a chapter. The ch[0-9][0-9] shape drops it here, and
# the LOUD check for a new exercises/appendix/EXERCISES.md stays in
# audit_non_chapters in harness/test-printed-commands.sh, which fails the gate
# on one. Copying its exempt list into this file would give it somewhere to
# drift to, and the gate it needs already exists.
#
# THE LINK REWRITE IS THE PART THAT WILL BITE. An EXERCISES.md is written to
# be read in a DELIVERED tree, where starters/ and LOG.md sit beside it, so
# its relative links mean nothing on a website. The rewrite below resolves
# each one against the real chapter directory and sends it to GitHub, so a
# target that does not exist stays relative and
# harness/test-build-docs-exercises.sh fails on it. Nothing is guessed.
#
# WHAT IS DELIBERATELY LEFT ALONE. The printed shell commands stay byte for
# byte. They are correct for a delivered tree, harness/test-printed-commands.sh
# gates every one of them, and rewriting them here would put the site and that
# gate in disagreement. The banner at the top of each page says so instead.
# ===========================================================================

GH_REPO="https://github.com/fkberthold/tla-puzzles"
GH_BLOB="$GH_REPO/blob/main"
GH_TREE="$GH_REPO/tree/main"

# ---- helper: derive the exercise chapter list from the tree ----
# Sets EXERCISE_CHAPTERS to the chapter numbers under exercises/ that carry an
# EXERCISES.md, ascending. Glob expansion sorts, so nothing needs sorting.
#
# An unmatched glob stays literal rather than vanishing, and the -f test drops
# it, so a missing exercises/ gives an empty list rather than a bogus one.
EXERCISE_CHAPTERS=()
derive_exercise_chapters() {
  local dir n
  EXERCISE_CHAPTERS=()
  for dir in exercises/ch[0-9][0-9]/; do
    [ -f "$dir/EXERCISES.md" ] || continue
    n="${dir%/}"
    n="${n##*/ch}"
    EXERCISE_CHAPTERS+=("$n")
  done
  return 0
}

# ---- helper: short nav label from a chapter's own H1 ----
# The twelve H1s do not agree on a shape. Four read "Chapter NN exercises:
# Topic" and the rest read "Exercises: learntla core ch.N, Topic". Both end in
# the topic after a comma or a colon, so the longest-match strip gives it. An
# H1 with neither separator falls through unchanged, which is a readable label
# rather than an empty one.
exercise_topic() {
  local ch="$1" h1
  h1=$(grep -m1 '^# ' "exercises/ch$ch/EXERCISES.md" || true)
  h1="${h1#\# }"
  if [ -z "$h1" ]; then
    echo "Chapter $ch"
    return 0
  fi
  echo "${h1##*[,:] }"
}

# ---- helper: everything after a markdown file's first H1 ----
# Prints the whole file when there is no H1, so a chapter missing one loses its
# heading rather than its content.
body_after_h1() {
  awk '!seen && /^# / { seen=1; next } { print }' "$1"
}

# ---- helper: escape a string for use as an ERE pattern ----
# Done character by character in bash rather than through sed, because the sed
# form needs a bracket expression holding the same metacharacters it is
# escaping, which is both hard to read and the one thing a reviewer cannot
# check by eye.
ere_escape() {
  local s="$1" c out=""
  while [ -n "$s" ]; do
    c="${s:0:1}"
    s="${s:1}"
    case "$c" in
    \\|'.'|'['|']'|'*'|'^'|'$'|'('|')'|'{'|'}'|'?'|'+'|'|') out="$out\\$c" ;;
    *) out="$out$c" ;;
    esac
  done
  printf '%s' "$out"
}

# ---- helper: build the per-chapter link-rewrite sed program ----
# Writes one `s@...@...@g` line per relative link that actually appears in the
# chapter's own markdown. The set is usually empty, which is why this resolves
# the links it finds rather than pattern-matching shapes it imagines.
#
# A target that resolves to nothing in the source tree gets a warning and no
# rewrite. It stays relative, and the suite fails on it. That is the right
# direction for the error to run: a dead link in the content is a content bug,
# and this generator inventing a plausible destination for it would hide one.
#
# Two guards keep TLA+ out of the scan. A candidate needs non-empty link text
# and a whitespace-free target, so `RungUp == [](rung' = rung + 1)` and
# `<>[](ENABLED <<A>>_v)` are both out on both counts. The guards are not a
# markdown parser: a genuine link shape inside backticks would be rewritten.
build_link_program() {
  local ch="$1" prog="$2"
  local src="exercises/ch$ch"
  local raw targets t path anchor repl pat

  # This chapter's own two files are pages, not downloads, so they get named
  # destinations before any path lookup runs.
  {
    printf 's@\\]\\(EXERCISES\\.md@](ch%s.md@g\n' "$ch"
    printf 's@\\]\\(CHEATSHEET\\.md(#[^)]*)?\\)@](#cheat-sheet)@g\n'
    printf 's@\\]\\(\\.\\./ch([0-9][0-9])/EXERCISES\\.md@](ch\\1.md@g\n'
    printf 's@\\]\\(\\.\\./ch([0-9][0-9])/CHEATSHEET\\.md(#[^)]*)?\\)@](ch\\1.md#cheat-sheet)@g\n'
  } > "$prog"

  raw=$(grep -ohE '\[[^]]+\]\([^) 	]+\)' "$src/EXERCISES.md" "$src/CHEATSHEET.md" 2>/dev/null || true)
  [ -n "$raw" ] || return 0
  targets=$(sed -E 's/^.*\]\(//; s/\)$//' <<<"$raw" | LC_ALL=C sort -u)

  while IFS= read -r t; do
    [ -n "$t" ] || continue
    case "$t" in
    http://*|https://*|mailto:*|'#'*|/*) continue ;;
    EXERCISES.md|EXERCISES.md'#'*|CHEATSHEET.md|CHEATSHEET.md'#'*) continue ;;
    ../ch[0-9][0-9]/EXERCISES.md*|../ch[0-9][0-9]/CHEATSHEET.md*) continue ;;
    esac
    path="${t%%#*}"
    anchor=""
    case "$t" in
    *'#'*) anchor="#${t#*#}" ;;
    esac
    if [ -d "$src/$path" ]; then
      repl="$GH_TREE/exercises/ch$ch/$path$anchor"
    elif [ -f "$src/$path" ]; then
      repl="$GH_BLOB/exercises/ch$ch/$path$anchor"
    else
      echo "build-docs.sh: exercises/ch$ch links to [$t], which is not in the chapter directory." >&2
      echo "  Left as written. harness/test-build-docs-exercises.sh fails on it." >&2
      continue
    fi
    # The parentheses have to be escaped. sed -E reads a bare ( as the start
    # of a capture group, so an unescaped form matches `]starters/Ex1.tla`
    # rather than `](starters/Ex1.tla)` and silently rewrites nothing.
    pat=$(ere_escape "$t")
    printf 's@\\]\\(%s\\)@](%s)@g\n' "$pat" "$repl" >> "$prog"
  done <<<"$targets"
  return 0
}

derive_exercise_chapters

if [ "${#EXERCISE_CHAPTERS[@]}" -gt 0 ]; then
  mkdir -p "$DOCS/exercises"

  for ch in "${EXERCISE_CHAPTERS[@]}"; do
    src="exercises/ch$ch"
    out="$DOCS/exercises/ch$ch.md"
    link_prog=$(mktemp)
    build_link_program "$ch" "$link_prog"

    {
      h1=$(grep -m1 '^# ' "$src/EXERCISES.md" || true)
      if [ -n "$h1" ]; then
        echo "$h1"
      else
        echo "# Chapter $ch exercises"
      fi
      echo ""
      echo "!!! info \"Reading this on the web\""
      echo ""
      echo "    Every command below is printed for a delivered practice tree, where"
      echo "    \`starters/\` and \`LOG.md\` sit beside this page. Clone the repo and run"
      echo "    \`scripts/deliver-exercises.sh $((10#$ch))\` to get that tree."
      if [ -d "$src/starters" ]; then
        echo "    The starters are also readable on GitHub under"
        echo "    [\`exercises/ch$ch/starters/\`]($GH_TREE/exercises/ch$ch/starters)."
      fi
      echo ""
      body_after_h1 "$src/EXERCISES.md"

      # The cheat sheet goes behind a click. scripts/deliver-exercises.sh
      # withholds a chapter's own sheet on purpose, because it names the
      # constructs the exercises are asking you to reach for. A collapsed
      # block keeps the bead's "carry the CHEATSHEET.md" and keeps that
      # reason, since the reader chooses to open it.
      if [ -f "$src/CHEATSHEET.md" ]; then
        echo ""
        echo "---"
        echo ""
        echo "## Cheat sheet"
        echo ""
        echo "??? note \"The chapter $ch cheat sheet names the constructs. Open it when you want it.\""
        echo ""
        # The sheets use # and ## only. Demote ## to #### so it nests under
        # this page's "## Cheat sheet" instead of competing with the exercise
        # headings in the sidebar.
        body_after_h1 "$src/CHEATSHEET.md" | sed -e 's/^##/####/' -e 's/^/    /'
      fi
    } | sed -E -f "$link_prog" > "$out"

    rm -f "$link_prog"
  done

  # ---- exercises index page ----
  {
    echo "# Exercises"
    echo ""
    echo "These sets track the chapters of learntla. Each one takes the constructs"
    echo "its chapter introduces and asks you to write three to six specs against"
    echo "them. You get a starter file to edit and one command that prints a"
    echo "verdict."
    echo ""
    echo "They assume you've read the chapter. They don't replace it."
    echo ""
    echo "Nothing here runs in a browser, so working a set means getting the files"
    echo "onto disk:"
    echo ""
    echo '```bash'
    echo "git clone $GH_REPO"
    echo "cd tla-puzzles"
    echo "scripts/deliver-exercises.sh 2"
    echo '```'
    echo ""
    echo "That drops chapter 2's statement, its starters and a log scaffold into"
    echo "\`~/tla-practice/exercises/ch02/\`. Pass another chapter number for"
    echo "another set."
    echo ""
    echo "## The sets"
    echo ""
    for ch in "${EXERCISE_CHAPTERS[@]}"; do
      echo "- [Chapter $ch: $(exercise_topic "$ch")](ch$ch.md)"
    done
  } > "$DOCS/exercises/index.md"

  # ---- exercises dir nav order (awesome-pages) ----
  # Titles are quoted so a topic carrying a colon stays one YAML key.
  {
    echo "title: Exercises"
    echo "nav:"
    echo "  - index.md"
    for ch in "${EXERCISE_CHAPTERS[@]}"; do
      echo "  - \"Chapter $ch: $(exercise_topic "$ch")\": ch$ch.md"
    done
  } > "$DOCS/exercises/.pages"
fi

# ---- getting-started ----
cat > "$DOCS/getting-started.md" <<'EOF'
# Getting Started

This page walks you through installing the toolchain and running your first puzzle end-to-end.

!!! info "Reading online?"
    Each puzzle page inlines its solution files as collapsed 🔒 blocks — click to reveal. To actually verify a spec yourself, you'll want a local toolchain. Follow the install steps below, then `git clone https://github.com/fkberthold/tla-puzzles.git`.

## Install the toolchain

### TLC (required)

The TLA+ Toolbox ships TLC and PlusCal as a single jar. Two options:

**Option A: download the jar.** This is the release the puzzles are verified
against — pinned on purpose. Do not substitute `releases/latest/download/`:
GitHub's `latest` skips prereleases, so it hands you a 2024 build whose exit
codes and messages differ from the ones every puzzle's "Expected Result" was
measured on.

```bash
mkdir -p ~/lib ~/bin
curl -L -o ~/lib/tla2tools.jar \
  @TLA_JAR_URL@
cat > ~/bin/tlc <<'WRAPPER'
#!/usr/bin/env bash
JAR="$HOME/lib/tla2tools.jar"
JVM_OPTS="-XX:+UseParallelGC"
if [ "$1" = "-pcal" ]; then
    shift
    exec java $JVM_OPTS -cp "$JAR" pcal.trans "$@"
else
    exec java $JVM_OPTS -cp "$JAR" tlc2.TLC "$@"
fi
WRAPPER
chmod +x ~/bin/tlc
```

**Option B: nix profile.**

```bash
nix profile install nixpkgs#tlaplus
```

### Apalache (optional — required for the Apalache track)

```bash
mkdir -p ~/lib ~/bin
cd /tmp
curl -L -o apalache.tgz \
  https://github.com/apalache-mc/apalache/releases/download/v0.57.0/apalache.tgz
tar -xzf apalache.tgz -C ~/lib/
ln -sf ~/lib/apalache/bin/apalache-mc ~/bin/apalache
ln -sf ~/lib/apalache/bin/apalache-mc ~/bin/apalache-mc
apalache version
```

### Verify

```bash
which tlc apalache java
java -version    # should be 17+
```

## Your first puzzle

```bash
git clone https://github.com/fkberthold/tla-puzzles.git
cd tla-puzzles/puzzles/T0a-first-run-hello-tlc/solution
tlc -pcal Tick.tla
tlc Tick
```

Expected output (snippet):

```
Model checking completed. No error has been found.
6 states generated, 5 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 5.
```

Three things to recognize:

1. **"5 distinct states found"** — TLC explored the full reachable state space.
2. **"No error has been found"** — every invariant in the `.cfg` held in every state.
3. **"0 states left on queue"** — TLC finished; the result is exhaustive, not truncated.

You're set up. Continue through the curriculum in order via the [Curriculum Map](reference/curriculum-map.md).

## Where to write your attempts

The repository's `puzzles/<id>/solution/` directory contains the **reference solution**. To preserve the puzzle for yourself, write your attempts in a separate location:

```bash
mkdir -p ~/tla-attempts
# write your spec in ~/tla-attempts/T01-mine.tla
# verify there
# THEN compare to puzzles/T01-the-light-switch/solution/
```
EOF

# The heredoc above is single-quoted on purpose — it contains `$HOME`, `$1`,
# `$JAR` and `$@` that must reach the page literally — so the pin goes in
# through a placeholder rather than through shell expansion.
sed -i "s|@TLA_JAR_URL@|${TLA_JAR_URL}|g" "$DOCS/getting-started.md"

# Post-condition, not a hope. This is the gate: build-docs.sh runs in
# pages.yml on every push to main, in scripts/cibuild phase 4, and in
# scripts/server, so a page that names the wrong toolchain never gets built,
# let alone published.
if grep -q '@TLA_JAR_URL@' "$DOCS/getting-started.md"; then
  echo "build-docs.sh: the toolchain URL placeholder survived substitution." >&2
  exit 1
fi
if ! grep -qF "$TLA_JAR_URL" "$DOCS/getting-started.md"; then
  echo "build-docs.sh: getting-started.md does not name the pinned jar URL:" >&2
  echo "  expected: $TLA_JAR_URL" >&2
  exit 1
fi
# Matched as a full URL, not as the bare fragment: the page deliberately NAMES
# `releases/latest/download/` in the warning above the curl, and a check that
# cannot tell the warning from the mistake fires on its own documentation.
if grep -qF 'tlaplus/tlaplus/releases/latest' "$DOCS/getting-started.md"; then
  echo "build-docs.sh: getting-started.md still points learners at the" >&2
  echo "  releases/latest/ URL — that resolves to v1.7.4 (2024-08-05)," >&2
  echo "  because GitHub's \`latest\` skips prereleases (beads tla-5b4, tla-urv)." >&2
  exit 1
fi

# ---- contributing ----
cat > "$DOCS/about/contributing.md" <<'EOF'
# Contributing

## Adding a new puzzle

1. Read the [Quality Gate](../reference/quality-gate.md) — every puzzle must pass all seven checks.
2. Pick a single concept the curriculum doesn't already teach. Check the [Curriculum Map](../reference/curriculum-map.md) for current coverage.
3. Author `puzzles/<id>-<slug>/`:
   - `README.md` with lesson (worked example in a different domain), setup, task, check, expected result
   - `solution/<Name>.tla` — PlusCal preferred for Tier 1-2; pure TLA+ from Tier 3 onward
   - `solution/<Name>.cfg`
4. Verify: `tlc -pcal <Name>.tla && tlc <Name>` (or just `tlc <Name>` for pure TLA+).
5. Make sure your README's "Expected Result" exactly matches what TLC produces — state counts, trace lengths.
6. If your puzzle uses Apalache, also run `apalache check --inv=<Inv> [--cinit=ConstInit] <Name>.tla` and confirm `NoError`.
7. Open a PR. CI runs TLC on every changed puzzle.

## Authoring conventions

- One concept per puzzle. Don't sneak in two.
- Worked example in a domain different from the puzzle setting. A learner who copy-renamed your example into the puzzle should not pass.
- Difficulty: ⭐ for ~15 min, ⭐⭐ for ~30 min, ⭐⭐⭐ for ~60+. Calibrate against a learner who just solved the immediately preceding puzzle.
- For deliberate violations: counterexample under 10 states, ideally ≤ 5.
- Don't telegraph the puzzle in the lesson. The strip test (Quality Gate #3) is the canonical check.

## Reordering or modifying existing puzzles

The curriculum sequence is built on a `bd` (beads) dependency chain. Edit dependencies via `bd dep add` / `bd dep remove`. Re-run `scripts/gen-curriculum-map.sh` after any structural change.
EOF

# ---- extra css ----
cat > "$DOCS/stylesheets/extra.css" <<'EOF'
/* Concept chips */
.md-content article p > code {
  font-size: 0.78em;
  padding: 0.05em 0.5em;
}
/* Compact admonitions for inlined source */
.md-content article details.note {
  margin: 0.6em 0;
}
h1, h2 {
  white-space: normal;
}
EOF

# ---- awesome-pages config (.pages files for nav order) ----
# Top-level docs/.pages, section ordering.
#
# The exercises entry is conditional because awesome-pages resolves every nav
# entry against a real directory, and naming one that was not built is an
# error rather than a skipped line.
#
# It sits AFTER curriculum on purpose. Bead tla-jaob.1 is additive and answers
# neither open question on tla-jaob, and where the best content sits in the nav
# is one of them. Moving this line above curriculum is a one-line change and
# Frank's call.
{
  echo "nav:"
  echo "  - index.md"
  echo "  - getting-started.md"
  echo "  - curriculum"
  if [ -d "$DOCS/exercises" ]; then
    echo "  - exercises"
  fi
  echo "  - reference"
  echo "  - about"
} > "$DOCS/.pages"

# Curriculum directory ordering (tier order)
cat > "$DOCS/curriculum/.pages" <<'EOF'
title: Curriculum
nav:
  - tier-0
  - tier-1
  - tier-2
  - tier-3
  - tier-4
  - tier-5
  - tier-6
  - tier-7
  - apalache
  - judgments
  - final
EOF

# Per-tier ordering (puzzles within tier)
for tier_slug in tier-0 tier-1 tier-2 tier-3 tier-4 tier-5 tier-6 tier-7 apalache judgments final; do
  tier_dir="$DOCS/curriculum/${tier_slug}"
  [ -d "$tier_dir" ] || continue
  label=$(tier_label "$tier_slug")
  {
    echo "title: $label"
    echo "nav:"
    echo "  - index.md"
    # List puzzles in canonical order — same sort as the main pass
    for f in "$tier_dir"/*.md; do
      fname=$(basename "$f" .md)
      [ "$fname" = "index" ] && continue
      # Pad T0a-T0d for sorting
      case "$fname" in T0a|T0b|T0c|T0d|T0e) sk="T00${fname: -1}";; *) sk="$fname";; esac
      echo -e "${sk}\t${fname}.md"
    done | LC_ALL=C sort | cut -f2 | sed 's/^/  - /'
  } > "$tier_dir/.pages"
done

echo "Docs built into $DOCS/"
echo "Run \`mkdocs serve\` to preview at http://localhost:8000"
