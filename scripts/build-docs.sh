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
declare -A TIER_DIRS_SEEN
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
      h1=$(grep -m1 '^# ' "$dir/README.md" | head -1)
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

# ---- getting-started ----
cat > "$DOCS/getting-started.md" <<'EOF'
# Getting Started

This page walks you through installing the toolchain and running your first puzzle end-to-end.

!!! info "Reading online?"
    Each puzzle page inlines its solution files as collapsed 🔒 blocks — click to reveal. To actually verify a spec yourself, you'll want a local toolchain. Follow the install steps below, then `git clone https://github.com/fkberthold/tla-puzzles.git`.

## Install the toolchain

### TLC (required)

The TLA+ Toolbox ships TLC and PlusCal as a single jar. Two options:

**Option A: download the jar.**

```bash
mkdir -p ~/lib ~/bin
curl -L -o ~/lib/tla2tools.jar \
  https://github.com/tlaplus/tlaplus/releases/latest/download/tla2tools.jar
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
# Top-level docs/.pages — section ordering
cat > "$DOCS/.pages" <<'EOF'
nav:
  - index.md
  - getting-started.md
  - curriculum
  - reference
  - about
EOF

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
