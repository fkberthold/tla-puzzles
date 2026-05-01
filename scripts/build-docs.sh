#!/usr/bin/env bash
# Build the docs/ tree from puzzle READMEs and reference files.
# Run before `mkdocs build` (or in the GH Action workflow).
# Filesystem-only — no bd dependency.
set -euo pipefail
cd "$(dirname "$0")/.."

DOCS=docs
mkdir -p "$DOCS/curriculum" "$DOCS/reference" "$DOCS/about" "$DOCS/stylesheets"

# ---- index.md (top-level landing) ----
cp README.md "$DOCS/index.md"
sed -i \
  -e 's|](JUDGMENTS\.md)|](reference/judgments.md)|g' \
  -e 's|](CURRICULUM_MAP\.md)|](reference/curriculum-map.md)|g' \
  -e 's|](QUALITY_GATE\.md)|](reference/quality-gate.md)|g' \
  -e 's|](LICENSE)|](about/license.md)|g' \
  "$DOCS/index.md"

# ---- reference pages from canonical docs ----
cp QUALITY_GATE.md  "$DOCS/reference/quality-gate.md"
cp CURRICULUM_MAP.md "$DOCS/reference/curriculum-map.md"
cp JUDGMENTS.md     "$DOCS/reference/judgments.md"
{ echo "# License"; echo; cat LICENSE; } > "$DOCS/about/license.md"

# ---- per-tier curriculum pages ----
# Classify a puzzle dir by its prefix (T0a, T01, R01, A01, J01, C01, T67) into a tier.
classify() {
  local prefix="$1"
  case "$prefix" in
    T0a|T0b|T0c|T0d) echo "tier-0" ;;
    T67)             echo "final" ;;
    A*)              echo "apalache" ;;
    J*)              echo "judgments" ;;
    R*)
      local n="${prefix#R}"
      n="${n#0}"  # strip leading zero so 04 → 4
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
      local n="${prefix#T}"
      n="${n#0}"
      case "$n" in
        [1-8])           echo "tier-1" ;;
        9|1[0-9]|2[0-5]) echo "tier-2" ;;
        2[6-9]|3[0-4])   echo "tier-3" ;;
        3[5-9]|4[0-1])   echo "tier-4" ;;
        4[2-9])          echo "tier-5" ;;            # T42-T49
        4[2-9]b)         echo "tier-5" ;;
        5[0-9])          echo "tier-6" ;;            # T50-T59
        6[0-6])          echo "tier-7" ;;
        67)              echo "final" ;;
        *)
          # Handle suffixed puzzle ids like T44b, T47b
          if [[ "$prefix" =~ ^T([0-9]+)[a-z]$ ]]; then
            local base="${BASH_REMATCH[1]}"
            if   [ "$base" -ge 42 ] && [ "$base" -le 49 ]; then echo "tier-5"
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

# Sort key for puzzles within a tier: numeric where possible, lex otherwise.
sortkey() {
  local prefix="$1"
  # Pad numeric portion so T0a, T01, T44b sort cleanly.
  case "$prefix" in
    T0a|T0b|T0c|T0d) echo "T00${prefix: -1}" ;;
    *)               echo "$prefix" ;;
  esac
}

# Initialize tier files with H1 + intro.
declare -A TIER_TITLES=(
  [tier-0]="Tier 0 — Prelude (Workflow Basics)"
  [tier-1]="Tier 1 — PlusCal Basics"
  [tier-2]="Tier 2 — PlusCal Data Structures"
  [tier-3]="Tier 3 — Pure TLA+ Pivot"
  [tier-4]="Tier 4 — Multi-Process & Synchronization"
  [tier-5]="Tier 5 — Temporal Logic & Fairness"
  [tier-6]="Tier 6 — Specification Structure & Refinement"
  [tier-7]="Tier 7 — Production Craft"
  [apalache]="Apalache Track"
  [judgments]="Judgment Intersticials"
  [final]="Final Capstone"
)
for tier in "${!TIER_TITLES[@]}"; do
  echo "# ${TIER_TITLES[$tier]}" > "$DOCS/curriculum/${tier}.md"
  echo "" >> "$DOCS/curriculum/${tier}.md"
done

# Build a sorted list of (sortkey, prefix, dir) and emit each puzzle into its tier file.
{
  for dir in puzzles/*/; do
    dir="${dir%/}"
    base=$(basename "$dir")
    # Prefix is the first hyphenated token (T01, R01, A01, T44b, etc.)
    prefix="${base%%-*}"
    [ -f "$dir/README.md" ] || continue
    sk=$(sortkey "$prefix")
    echo -e "${sk}\t${prefix}\t${dir}"
  done
} | LC_ALL=C sort | while IFS=$'\t' read -r sk prefix dir; do
  tier=$(classify "$prefix")
  out="$DOCS/curriculum/${tier}.md"
  echo "" >> "$out"
  echo "---" >> "$out"
  echo "" >> "$out"
  # Demote the puzzle's H1 to H2 in the tier page.
  sed -E 's/^# /## /' "$dir/README.md" >> "$out"
done

# ---- getting-started ----
cat > "$DOCS/getting-started.md" <<'EOF'
# Getting Started

This page walks you through installing the toolchain and running your first puzzle end-to-end.

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
apalache version  # confirm install
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

You should see something like:

```
Model checking completed. No error has been found.
6 states generated, 5 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 5.
```

Three things to recognize:

1. **"5 distinct states found"** — TLC explored the full reachable state space.
2. **"No error has been found"** — every invariant in the `.cfg` held in every state.
3. **"0 states left on queue"** — TLC finished; the result is exhaustive, not truncated.

You're set up. The puzzle's README explains what each line of the spec does. Continue through the curriculum in order via the [Curriculum Map](reference/curriculum-map.md).

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
- For deliberate violations: counterexample under 10 states, ideally ≤ 5. Long traces obscure the lesson.
- Don't telegraph the puzzle in the lesson. The strip test (Quality Gate #3) is the canonical check.

## Reordering or modifying existing puzzles

The curriculum sequence is built on a `bd` (beads) dependency chain. To change the learner sequence, edit dependencies via `bd dep add` / `bd dep remove`. Re-run `scripts/gen-curriculum-map.sh` after any structural change.
EOF

# ---- extra css ----
cat > "$DOCS/stylesheets/extra.css" <<'EOF'
.md-content article h2 + p > code {
  background-color: var(--md-code-bg-color);
  padding: 0 0.3em;
}
h1, h2 {
  white-space: normal;
}
EOF

echo "Docs built into $DOCS/"
echo "Run \`mkdocs serve\` to preview at http://localhost:8000"
