#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch04 exercise references.

Usage:  python3 exercises/ch04/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch04-mut`, which is scratch
and is not tracked. Each mutant lands in its own directory under OUT_DIR, so
the module name inside the file still matches the file name, which SANY needs.

Each entry is (id, module, literal-old, literal-new). One mutant is one literal
substring replacement. A pattern that does not occur exactly once is a seeding
error rather than a mutant, because a pattern matching twice would edit a line
nobody chose. The reference files carry the PlusCal block and its translation,
so several of the patterns below carry their exact indentation on purpose, to
pin the PlusCal copy rather than the translated copy that restates the same
text at a different indent.

This is the c-syntax counterpart of the original p-syntax mutant table in
reports/authoring.md (bead tla-wza0). Only M3.4 needed an adapted pattern: the
p-syntax `while pending # {} do` guard is not a standalone literal in c-syntax,
where the loop reads `while (pending # {}) {`. Every other pattern below
matches the same characters it matched before conversion, because the mutation
sites sit inside expressions or assignment statements that braces never touch.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch04/references"

MUTANTS = [
    # --- TokenMove (exercise 1) ---------------------------------------------
    ("M1.1", "TokenMove",
     "right := right + 1;",
     "right := right + 2;"),
    ("M1.2", "TokenMove",
     "left := left - 1;",
     "left := left + 1;"),
    ("M1.3", "TokenMove",
     "right = 0;",
     "right = 1;"),
    ("M1.4", "TokenMove",
     "    /\\ right \\in 0..Capacity",
     "    /\\ right \\in 1..Capacity"),
    ("M1.5", "TokenMove",
     "Capacity == 3",
     "Capacity == 30"),

    # --- MaxScan (exercise 2) -----------------------------------------------
    ("M2.1", "MaxScan",
     "  BestIsMax == pc = \"Done\" => (UpperBound /\\ Attained)",
     "  BestIsMax == (UpperBound /\\ Attained)"),
    ("M2.2", "MaxScan",
     "  BestIsMax == pc = \"Done\" => (UpperBound /\\ Attained)",
     "  BestIsMax == pc = \"Scan\" => (UpperBound /\\ Attained)"),
    ("M2.3", "MaxScan",
     "if (Input[i] > best) {",
     "if (Input[i] < best) {"),
    ("M2.4", "MaxScan",
     "  UpperBound == \\A k \\in 1..Len(Input): Input[k] <= best",
     "  UpperBound == \\A k \\in 1..Len(Input): Input[k] < best"),
    ("M2.5", "MaxScan",
     "  Attained == \\E k \\in 1..Len(Input): Input[k] = best",
     "  Attained == TRUE"),

    # --- DrainQueue (exercise 3) ---------------------------------------------
    ("M3.1", "DrainQueue",
     "Jobs == {1, 2, 3}",
     "Jobs == {0, 1, 2}"),
    ("M3.2", "DrainQueue",
     "  AllPositive == \\A j \\in pending: j > 0",
     "  AllPositive == \\A j \\in pending: j > 1"),
    ("M3.3", "DrainQueue",
     "pending = Jobs,",
     "pending = Jobs \\union {-1},"),
    ("M3.4", "DrainQueue",
     # p-syntax was `while pending # {} do`; the guard is not a standalone
     # literal in c-syntax, so the pattern carries the parens and brace.
     "while (pending # {}) {",
     "while (pending = {}) {"),
    ("M3.5", "DrainQueue",
     "  AllPositive == \\A j \\in pending: j > 0",
     "  AllPositive == \\A j \\in cleared: j > 0"),

    # --- Ratchet (exercise 4) -------------------------------------------------
    ("M4.1", "Ratchet",
     "with (next \\in level..(level + 2)) {",
     "with (next \\in (level - 1)..(level + 2)) {"),
    ("M4.2", "Ratchet",
     "      a < b => s[a] <= s[b]",
     "      a < b => s[a] < s[b]"),
    ("M4.3", "Ratchet",
     "      a < b => s[a] <= s[b]",
     "      a < b \\land s[a] <= s[b]"),
    ("M4.4", "Ratchet",
     "Steps == 4",
     "Steps == 0"),
    ("M4.5", "Ratchet",
     "log := Append(log, next);",
     "log := Append(log, 0);"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch04-mut"
    if os.path.isdir(out):
        shutil.rmtree(out)
    failures = 0
    for mid, module, old, new in MUTANTS:
        d = os.path.join(out, mid)
        os.makedirs(d)
        with open(os.path.join(REF, module + ".tla"), encoding="utf-8") as fh:
            body = fh.read()
        count = body.count(old)
        if count != 1:
            print("SEED-ERROR %s: pattern occurs %d times, wanted 1" % (mid, count))
            failures += 1
            continue
        with open(os.path.join(d, module + ".tla"), "w", encoding="utf-8") as fh:
            fh.write(body.replace(old, new))
        shutil.copyfile(os.path.join(REF, module + ".cfg"),
                        os.path.join(d, module + ".cfg"))
        print("seeded %s %s" % (mid, module))
    sys.exit(1 if failures else 0)


main()
