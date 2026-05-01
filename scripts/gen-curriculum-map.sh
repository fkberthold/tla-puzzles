#!/bin/bash
# Generate CURRICULUM_MAP.md from bd state.
# Groups by tier label, shows status/style/difficulty/concept tags.
set -e
cd /home/frank/repos/tla-puzzles

OUT="CURRICULUM_MAP.md"

cat > "$OUT" <<'HEADER'
# Curriculum Map

Auto-generated from `bd list` queries. **Do not hand-edit** — regenerate via `/tmp/gen-curriculum-map.sh`.

Each row is one puzzle bead. Status icons: ✓ closed (done) · ○ open · ◐ in progress · ● blocked · ❄ deferred.

Style: PC = PlusCal · TLA = pure TLA+. Difficulty: 1=⭐ (~15 min) · 2=⭐⭐ (~30 min) · 3=⭐⭐⭐ (~60+ min).

`Kind` legend: puzzle / review / capstone / cross-capstone / judgment.

> **Note:** Within each tier, rows are sorted alphabetically by ID. The actual
> learner sequence is encoded in the `bd` dependency graph (see `bd ready`).
> One intentional reorder: in Tier 7, **T62 (Model Values) is the dep-chain
> successor of T60 (SYMMETRY)**, since T62 deepens model-value semantics that
> T60 introduces. T61 (VIEW) follows T62 in the dep chain even though it
> appears before T62 in this table.

HEADER

emit_tier() {
  local tier_label="$1" tier_title="$2"
  echo "" >> "$OUT"
  echo "## $tier_title" >> "$OUT"
  echo "" >> "$OUT"
  echo "| Status | ID | Title | Kind | Style | Diff | Concepts |" >> "$OUT"
  echo "|---|---|---|---|---|---|---|" >> "$OUT"
  bd list --label "$tier_label" --status all --limit 0 --json 2>/dev/null | \
    jq -r '.[] | [.id, .title, .status, (.labels | join(","))] | @tsv' | \
    sort -t$'\t' -k2 | \
    while IFS=$'\t' read -r id title status labels; do
      icon="○"
      [[ "$status" == "closed" ]] && icon="✓"
      [[ "$status" == "in_progress" ]] && icon="◐"
      [[ "$status" == "blocked" ]] && icon="●"
      [[ "$status" == "deferred" ]] && icon="❄"
      kind=$(echo "$labels" | tr ',' '\n' | grep '^kind:' | sed 's/kind://' | head -1)
      style=$(echo "$labels" | tr ',' '\n' | grep '^style:' | sed 's/style://' | head -1)
      [[ "$style" == "pluscal" ]] && style="PC"
      [[ "$style" == "tla" ]] && style="TLA"
      diff=$(echo "$labels" | tr ',' '\n' | grep '^difficulty:' | sed 's/difficulty://' | head -1)
      concepts=$(echo "$labels" | tr ',' '\n' | grep -E '^(concept|apa|workflow):' | tr '\n' ',' | sed 's/,$//')
      echo "| $icon | $id | $title | $kind | $style | $diff | $concepts |" >> "$OUT"
    done
}

emit_tier "tier:0" "Tier 0 — Prelude (Workflow Basics)"
emit_tier "tier:1" "Tier 1 — PlusCal Basics (Done)"
emit_tier "tier:2" "Tier 2 — PlusCal Data Structures"
emit_tier "tier:3" "Tier 3 — Pure TLA+ Pivot"
emit_tier "tier:4" "Tier 4 — Multi-Process & Synchronization"
emit_tier "tier:5" "Tier 5 — Temporal Logic & Fairness"
emit_tier "tier:6" "Tier 6 — Specification Structure & Refinement"
emit_tier "tier:7" "Tier 7 — Production Craft"
emit_tier "tier:apalache" "Apalache Track (parallel after Tier 3)"
emit_tier "tier:judgment" "Judgment Intersticials"
emit_tier "tier:final" "Final Capstone"

cat >> "$OUT" <<'FOOTER'

---

## Concept-Decay Query Examples

```bash
bd list -l concept:either-or --status closed --json | jq -r '.[].closed_at' | sort | tail -1   # Last time either/or was drilled
bd list -l concept:function-application --status all                                            # All puzzles touching function application
bd list --status open --label tier:2 --label kind:puzzle                                        # Tier 2 puzzles still to write
bd ready --label tier:2                                                                         # Next unblocked Tier 2 work
```

## Workflow

1. **Author next puzzle:** `bd ready` → pick the lowest-tier unblocked puzzle. `bd show <id>` for context.
2. **Mark in progress:** `bd update <id> --status in_progress`.
3. **Write puzzle directory:** `puzzles/T0N-the-x/{README.md, solution/Name.tla, solution/Name.cfg}`.
4. **Verify:** `pcal Name.tla && java tlc2.TLC Name.tla` (or whatever the local TLC invocation is).
5. **Close:** `bd close <id> --reason "Authored, verified by TLC"`.
6. **Regenerate this map:** `bash /tmp/gen-curriculum-map.sh`.
7. **At session end:** `bd sync`.

## Spaced-Repetition Selection

When picking the next review puzzle (`R0N`), use:

```bash
# Find the concept tag whose closed beads have the oldest most-recent close date
bd list --status closed --label kind:puzzle --json | \
  jq -r '.[] | .labels[] as $l | select($l | startswith("concept:")) | "\(.closed_at) \($l)"' | \
  sort | head -20
```

The concept that hasn't been touched longest is the next review's target.
FOOTER

echo "Wrote $OUT"
wc -l "$OUT"
