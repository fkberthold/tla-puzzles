#!/usr/bin/env python3
"""
For each puzzle, parse its solution .tla file(s) and identify which earlier
puzzles' techniques the solution depends on.

Output: /tmp/builds_on.json — a mapping prefix → [list of prereq prefixes].

The mapping is regex-driven: each entry says "if the solution contains this
pattern, it builds on the puzzle that introduced this construct."

Direct prereqs only (not transitive). Capstones may show many prereqs;
that's expected — they compose techniques.
"""
import json, pathlib, re, sys

# Map regex pattern → introducing puzzle prefix.
# Order matters only insofar as duplicates dedupe at the end.
RULES = [
    # PlusCal core (Tier 1)
    (r"\(\*\s*--algorithm",                            "T01", "PlusCal"),
    (r"\bwith\s*\(",                                    "T02", "with"),
    (r"\beither\b\s*\{",                                "T03", "either/or"),
    (r"\bassert\s*\(",                                  "T05", "assert"),
    (r"\bdefine\s*\{",                                  "T06", "define block"),

    # Tier 1 process set with self (introduced in T03b before T04 layers
    # on the multi-label race).
    (r"\bprocess\s*\([^=]*\bin\s",                      "T03b", "process set"),
    (r"\bself\b",                                       "T03b", "self in process set"),

    # Tier 2 — records, sequences, functions
    (r"\[\s*\w+\s*\|->",                                "T09", "record / function literal"),
    (r"\bEXCEPT\s+!\.\w+\s*=",                          "T09", "record EXCEPT"),
    (r"<<[^<>]*>>",                                     "T10", "sequence literal"),
    (r"\bAppend\s*\(",                                  "T10", "Append"),
    (r"\bHead\s*\(",                                    "T10", "Head"),
    (r"\bTail\s*\(",                                    "T10", "Tail"),
    (r"\bLen\s*\(",                                     "T10", "Len"),
    (r"\\o\b",                                          "T11", "concat"),
    (r"\bSubSeq\s*\(",                                  "T11", "SubSeq"),
    (r"\bDOMAIN\s+\w",                                  "T13", "DOMAIN"),
    (r"\bEXCEPT\s+!\[",                                 "T14", "function EXCEPT"),
    (r"!\s*\[\w+\]\s*=\s*@",                            "T15", "EXCEPT with @"),
    (r"\[\s*\w+\s*->\s*\w+\s*\]",                       "T16", "function set [S -> T]"),
    (r"\{\s*\w+\s+\\in\s+\w+\s*:",                      "T17", "filter comprehension"),
    (r"\{\s*[^|]+\s*:\s*\w+\s+\\in",                    "T18", "map comprehension"),
    (r"\\subseteq\b",                                   "T19", "subseteq"),
    (r"\bSUBSET\b",                                     "T19", "SUBSET"),
    (r"\bCardinality\s*\(",                             "T20", "Cardinality"),
    (r"\bIsFiniteSet\s*\(",                             "T20", "IsFiniteSet"),
    (r"\bCHOOSE\b",                                     "T21", "CHOOSE"),
    (r"\bIF\b[^=]+\bTHEN\b",                            "T22", "IF/THEN/ELSE expr"),
    (r"\bCASE\b[^=]+->",                                "T22", "CASE"),
    (r"\bLET\b[^=]+\bIN\b",                             "T23", "LET-IN"),

    # Tier 3 — pure TLA+
    (r"\bUNCHANGED\b",                                  "T29", "UNCHANGED"),
    (r"\[\]\[Next\]_",                                  "T32", "Spec form [Next]_v"),
    (r"\bWF_vars\b",                                    "T32", "weak fairness"),

    # Tier 4 — multi-process & sync
    (r"\bawait\b",                                      "T36", "await"),
    (r"\bENABLED\b",                                    "T37", "ENABLED"),
    (r"\bprocedure\b",                                  "T40", "procedure"),
    (r"\bcall\b\s+\w",                                  "T40", "procedure call"),

    # Tier 5 — temporal & fairness
    (r"~>",                                             "T44", "leads-to"),
    (r"\[\]\s*<>",                                      "T45", "infinitely often"),
    (r"<>\s*\[\]",                                      "T46", "eventually always"),
    (r"\bSF_vars\b",                                    "T47", "strong fairness"),
    (r"\bfair\+\b",                                     "T47", "fair+ (PlusCal SF)"),

    # Tier 6 — spec structure & refinement
    (r"\bCONSTANTS?\b",                                 "T50", "CONSTANTS"),
    (r"\bASSUME\b",                                     "T50", "ASSUME"),
    (r"\bINSTANCE\b\s+\w+\s+WITH\b",                    "T55", "INSTANCE WITH"),
    (r"\bINSTANCE\b",                                   "T52", "INSTANCE"),

    # Apalache
    (r"\\\*\s*@type:",                                  "A01", "@type annotation"),
    (r"\\\*\s*@typeAlias:",                             "A03", "@typeAlias"),
    (r":=",                                             "A04", "Apalache := assignment"),
    (r"\bApaFoldSet\s*\(",                              "A05", "ApaFoldSet"),
    (r"\bApaFoldSeqLeft\s*\(",                          "A05", "ApaFoldSeqLeft"),
    (r"^ConstInit\s*==",                                "A07", "ConstInit"),
    (r"\bEXTENDS\b[^,\n]*\bApalache\b",                 "A04", "EXTENDS Apalache"),
]

# Heuristic detection: "<>" alone means eventually (introduced T03), but
# combined with [] or other ops covers temporal usages — ordering above
# matters since []<> is matched first.
EXTRA_RULES = [
    # Plain <> not in a temporal compound — eventually as property
    (r"<>(?!\s*\[\])",                                  "T03", "eventually"),
    # Fair process (PlusCal weak fairness)
    (r"\bfair\s+process\b",                             "T01", "fair process"),
]

PUZZLES_DIR = pathlib.Path("puzzles")
out = {}

def prefix_of_dir(d: pathlib.Path) -> str:
    return d.name.split("-", 1)[0]

def order_key(prefix: str):
    """Curriculum-order sort key for prereqs."""
    if re.match(r"^T0[a-e]$", prefix):
        return (0, ord(prefix[2]))
    if re.match(r"^T(\d+)$", prefix):
        return (1, int(prefix[1:]))
    if re.match(r"^T(\d+)[a-z]$", prefix):
        m = re.match(r"^T(\d+)([a-z])$", prefix)
        return (1, int(m.group(1)) + 0.5)
    if re.match(r"^R(\d+)$", prefix):
        return (2, int(prefix[1:]))
    if re.match(r"^A(\d+)$", prefix):
        return (3, int(prefix[1:]))
    if re.match(r"^J(\d+)$", prefix):
        return (4, int(prefix[1:]))
    if re.match(r"^C(\d+)$", prefix):
        return (5, int(prefix[1:]))
    return (99, 0)

for puzzle_dir in sorted(PUZZLES_DIR.iterdir()):
    if not puzzle_dir.is_dir():
        continue
    prefix = prefix_of_dir(puzzle_dir)
    sol = puzzle_dir / "solution"
    if not sol.is_dir():
        continue

    # Collect text from all .tla files (excluding Apalache.tla shim, _buggy variants)
    texts = []
    for f in sol.glob("*.tla"):
        if f.name == "Apalache.tla":
            continue
        if "_buggy" in f.name:
            continue
        if "_TTrace_" in f.name:
            continue
        try:
            texts.append(f.read_text())
        except Exception:
            pass
    blob = "\n".join(texts)
    if not blob:
        continue

    found = set()
    for pattern, intro, _name in RULES + EXTRA_RULES:
        if re.search(pattern, blob, flags=re.MULTILINE):
            found.add(intro)

    # Don't list self.
    found.discard(prefix)

    # Sort by curriculum order, drop anything that comes AFTER current puzzle.
    cur_key = order_key(prefix)
    ordered = sorted(
        [p for p in found if order_key(p) < cur_key],
        key=order_key,
    )

    if ordered:
        out[prefix] = ordered

OUT_PATH = pathlib.Path("/tmp/builds_on.json")
with OUT_PATH.open("w") as f:
    json.dump(out, f, indent=2)

# Stats
total_links = sum(len(v) for v in out.values())
print(f"Wrote {OUT_PATH}: {len(out)} puzzles with prereqs ({total_links} edges total)")
print("Sample:")
for p in ["T08", "T34", "T49", "T59", "T67", "A09", "A10"]:
    if p in out:
        print(f"  {p} builds on: {', '.join(out[p])}")
