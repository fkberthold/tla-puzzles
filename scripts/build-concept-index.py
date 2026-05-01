#!/usr/bin/env python3
"""
Build docs/reference/concepts.md — an index of every concept tag with
the puzzles that teach or use it.

Reads bead labels via /tmp/puzzle_concepts.json (cached upstream).
Output is a markdown page grouped by tag-class (concept:, apa:, workflow:).
"""
import json, pathlib, collections, re, sys

CONCEPTS_JSON = pathlib.Path("/tmp/puzzle_concepts.json")
OUT = pathlib.Path("docs/reference/concepts.md")

if not CONCEPTS_JSON.exists():
    print(f"missing {CONCEPTS_JSON}; run the cache step first", file=sys.stderr)
    sys.exit(1)

data = json.load(open(CONCEPTS_JSON))
# data: prefix -> [labels]; we want label -> [prefixes]

concept_to_puzzles = collections.defaultdict(list)
for prefix, labels in data.items():
    for label in labels:
        concept_to_puzzles[label].append(prefix)

# Sort puzzle list per concept by curriculum order (numeric where possible).
def puzzle_sort_key(p):
    # T0a, T0b, T0c, T0d → first; then T01..T67; then R, A, J, C
    if p.startswith("T0") and len(p) == 3 and p[2].isalpha():
        return (0, ord(p[2]), p)
    if p.startswith("T") and p[1:].isdigit():
        return (1, int(p[1:]), p)
    if p.startswith("R") and p[1:].isdigit():
        return (2, int(p[1:]), p)
    if p.startswith("A") and p[1:].isdigit():
        return (3, int(p[1:]), p)
    if p.startswith("J") and p[1:].isdigit():
        return (4, int(p[1:]), p)
    if p.startswith("C") and p[1:].isdigit():
        return (5, int(p[1:]), p)
    # T44b style (suffixed)
    m = re.match(r"^([TR])(\d+)([a-z])$", p)
    if m:
        kind = {"T": 1, "R": 2}[m.group(1)]
        return (kind, int(m.group(2)), p)
    return (99, 0, p)

# Group concepts by class.
by_class = collections.defaultdict(list)
for label, puzzles in concept_to_puzzles.items():
    cls, _, name = label.partition(":")
    by_class[cls].append((name, sorted(puzzles, key=puzzle_sort_key)))

# Sort entries within each class alphabetically.
for cls in by_class:
    by_class[cls].sort(key=lambda x: x[0])

CLASS_ORDER = ["concept", "apa", "workflow"]
CLASS_LABEL = {
    "concept": "Concepts (PlusCal & TLA+)",
    "apa":     "Apalache-specific concepts",
    "workflow": "Workflow concepts",
}
CLASS_EMOJI = {"concept": "•", "apa": "⚡", "workflow": "🛠"}

def puzzle_url(prefix: str) -> str:
    """Map prefix → /curriculum/<tier>/<prefix>/."""
    # Same classification as build-docs.sh — keep these in sync.
    if prefix.startswith("T0") and len(prefix) == 3 and prefix[2].isalpha():
        tier = "tier-0"
    elif prefix == "T67":
        tier = "final"
    elif prefix.startswith("A"):
        tier = "apalache"
    elif prefix.startswith("J"):
        tier = "judgments"
    elif prefix == "C01":
        tier = "tier-4"
    elif prefix == "C02":
        tier = "tier-6"
    elif prefix.startswith("R"):
        m = re.match(r"^R(\d+)", prefix)
        n = int(m.group(1)) if m else 0
        tier = ("tier-2" if 1 <= n <= 3 else
                "tier-3" if 4 <= n <= 5 else
                "tier-4" if 6 <= n <= 7 else
                "tier-5" if 8 <= n <= 9 else
                "tier-6" if n in (10, 11) else
                "tier-7" if n in (12, 13) else "tier-?")
    elif prefix.startswith("T"):
        m = re.match(r"^T(\d+)", prefix)
        n = int(m.group(1)) if m else 0
        tier = ("tier-1" if 1 <= n <= 8 else
                "tier-2" if 9 <= n <= 25 else
                "tier-3" if 26 <= n <= 34 else
                "tier-4" if 35 <= n <= 41 else
                "tier-5" if 42 <= n <= 49 else
                "tier-6" if 50 <= n <= 59 else
                "tier-7" if 60 <= n <= 66 else "tier-?")
    else:
        tier = "tier-?"
    return f"../curriculum/{tier}/{prefix}.md"

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("w") as f:
    f.write("# Concept Index\n\n")
    f.write("Every concept the curriculum teaches, with the puzzles that introduce or use it.\n")
    f.write("Auto-generated from bead labels.\n\n")
    f.write("---\n\n")
    for cls in CLASS_ORDER:
        if cls not in by_class:
            continue
        f.write(f"## {CLASS_LABEL[cls]}\n\n")
        f.write(f"| Concept | Puzzles |\n|---|---|\n")
        for name, puzzles in by_class[cls]:
            pretty = name.replace("-", " ").replace("_", " ")
            links = ", ".join(f"[{p}]({puzzle_url(p)})" for p in puzzles)
            f.write(f"| {CLASS_EMOJI[cls]} `{pretty}` | {links} |\n")
        f.write("\n")

n_concepts = sum(len(v) for v in by_class.values())
n_total = sum(len(puzzles) for cls in by_class.values() for _, puzzles in cls)
print(f"wrote {OUT} ({n_concepts} concepts across {n_total} puzzle-references)")
