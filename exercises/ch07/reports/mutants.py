#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch07 exercise references.

Usage:  python3 exercises/ch07/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch07-mut`, which is scratch
and is not tracked. Each mutant lands in its own directory under OUT_DIR, so
the module name inside the file still matches the file name, which SANY needs.

Each entry is (id, module, cfg, literal-old, literal-new). One mutant is one
literal substring replacement. A pattern that does not occur exactly once is a
seeding error rather than a mutant, because a pattern matching twice would edit
a line nobody chose.

The `cfg` field exists because `Jugs` ships two configs and its two stated
outcomes are one per config. Every other module names its own config.

The reference files carry the PlusCal block and its translation, so a pattern
that appears in both is pinned to the PlusCal copy by its indentation. The
runner re-translates before checking, which is what makes that safe.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch07/references"

MUTANTS = [
    # --- Depot (exercise 1) -------------------------------------------------
    ("D1", "Depot", "Depot",
     "with (crate \\in waiting) {",
     "with (crate \\in Crates) {"),
    ("D2", "Depot", "Depot",
     "    Conserved == Loaded \\union waiting = Crates",
     "    Conserved == Loaded = Crates"),
    ("D3", "Depot", "Depot",
     "waiting := waiting \\ {crate} || order := Append(order, crate);",
     "waiting := waiting || order := Append(order, crate);"),
    ("D4", "Depot", "Depot",
     "    NoRepeats == Cardinality(Loaded) = Len(order)",
     "    NoRepeats == Cardinality(Loaded) = Len(order) + 1"),
    ("D5", "Depot", "Depot",
     "ASSUME Crates # {}",
     "ASSUME Crates = {}"),

    # --- Sluice (exercise 2) ------------------------------------------------
    ("S1", "Sluice", "Sluice",
     "          if (~frozen) {",
     "          if (TRUE) {"),
    ("S2", "Sluice", "Sluice",
     "          if (~open) {",
     "          if (TRUE) {"),
    ("S3", "Sluice", "Sluice",
     "    FrozenIsShut == frozen => ~open",
     "    FrozenIsShut == frozen => open"),
    ("S4", "Sluice", "Sluice",
     "          open := FALSE;",
     "          open := TRUE;"),
    ("S5", "Sluice", "Sluice",
     "              /\\ steps \\in 0..MaxSteps",
     "              /\\ steps \\in 0..MaxSteps-1"),

    # --- Jugs (exercise 3) --------------------------------------------------
    # J1, J2 and J5 run against JugsEven.cfg, whose stated outcome is OK.
    # J3 and J4 run against Jugs.cfg, whose stated outcome is SAFETY_VIOLATION.
    ("J1", "Jugs", "JugsEven",
     "          small := SmallCap;",
     "          small := SmallCap - 1;"),
    ("J2", "Jugs", "JugsEven",
     "          big := BigCap;",
     "          big := BigCap - 1;"),
    ("J3", "Jugs", "Jugs",
     "          with (moved = Min(big, SmallCap - small)) {",
     "          with (moved = 0) {"),
    ("J4", "Jugs", "Jugs",
     "Min(a, b) == IF a < b THEN a ELSE b",
     "Min(a, b) == 0"),
    ("J5", "Jugs", "JugsEven",
     "            big := big + moved || small := small - moved;",
     "            big := big + moved + 1 || small := small - moved;"),

    # --- BoxOffice (exercise 4) ---------------------------------------------
    ("B1", "BoxOffice", "BoxOffice",
     "          if (sold[order.tier] + order.seats <= Capacity) {",
     "          if (TRUE) {"),
    ("B2", "BoxOffice", "BoxOffice",
     "          if (sold[order.tier] + order.seats <= Capacity) {",
     "          if (sold[order.tier] + order.seats <= Capacity + 1) {"),
    ("B3", "BoxOffice", "BoxOffice",
     "    NeverOversold == \\A t \\in Tiers : sold[t] <= Capacity",
     "    NeverOversold == \\A t \\in Tiers : sold[t] < Capacity"),
    ("B4", "BoxOffice", "BoxOffice",
     "    TypeOK == sold \\in [Tiers -> 0..Capacity]",
     "    TypeOK == sold \\in [Tiers -> 0..Capacity-1]"),
    ("B5", "BoxOffice", "BoxOffice",
     "            sold[order.tier] := sold[order.tier] + order.seats;",
     "            sold[order.tier] := sold[order.tier] + order.seats + 1;"),

    # --- Ferry (exercise 5) -------------------------------------------------
    ("F1", "Ferry", "Ferry",
     "            skip;",
     "            aboard := 0;"),
    ("F2", "Ferry", "Ferry",
     "            far := far + aboard || aboard := 0;",
     "            far := far + aboard;"),
    ("F3", "Ferry", "Ferry",
     "            near := near - 1 || aboard := aboard + 1;",
     "            near := near - 1;"),
    ("F4", "Ferry", "Ferry",
     "          if (near > 0) {",
     "          if (TRUE) {"),
    ("F5", "Ferry", "Ferry",
     "    NothingLost == near + aboard + far = Crates",
     "    NothingLost == near + far = Crates"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch07-mut"
    if os.path.isdir(out):
        shutil.rmtree(out)
    failures = 0
    for mid, module, cfg, old, new in MUTANTS:
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
        # The config keeps the MODULE's name in the mutant directory, so the
        # runner can find it beside the .tla. Which config it is a copy of is
        # what the `cfg` field decides.
        shutil.copyfile(os.path.join(REF, cfg + ".cfg"),
                        os.path.join(d, module + ".cfg"))
        print("seeded %s %s (cfg %s)" % (mid, module, cfg))
    sys.exit(1 if failures else 0)


main()
