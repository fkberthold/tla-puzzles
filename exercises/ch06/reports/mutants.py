#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch06 exercise references.

Usage:  python3 exercises/ch06/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch06-mut`, which is scratch
and is not tracked. Each mutant lands in its own directory under OUT_DIR, so
the module name inside the file still matches the file name, which SANY needs.

Each entry is (id, module, literal-old, literal-new). One mutant is one literal
substring replacement. A pattern that does not occur exactly once is a seeding
error rather than a mutant, because a pattern matching twice would edit a line
nobody chose. The reference files carry the PlusCal block and its translation,
so several of the patterns below are indented on purpose to pin the PlusCal
copy.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch06/references"

MUTANTS = [
    # --- ParcelDesk (exercise 1) -------------------------------------------
    ("P1", "ParcelDesk",
     "express |-> TRUE];",
     "expres |-> TRUE];"),
    ("P2", "ParcelDesk",
     "if (parcel.kilos < MaxKilos) {",
     "if (parcel.kilos <= MaxKilos) {"),
    ("P3", "ParcelDesk",
     "ParcelType == [kilos: 1..MaxKilos,",
     "ParcelType == [kilos: 1..MaxKilos-1,"),
    ("P4", "ParcelDesk",
     "parcel := [kilos |-> parcel.kilos, depot |-> parcel.depot, express |-> TRUE];",
     "parcel := [kilos |-> parcel.kilos, express |-> TRUE];"),

    # --- DomainProbe (exercise 2) ------------------------------------------
    ("D1", "DomainProbe",
     "Claim3 == [i \\in 1..3 |-> i * i] = <<1, 4, 9>>",
     "Claim3 == [i \\in 0..2 |-> i * i] = <<0, 1, 4>>"),
    ("D2", "DomainProbe",
     "Claim1 == DOMAIN <<\"red\", \"green\", \"blue\">> = {1, 2, 3}",
     "Claim1 == DOMAIN <<\"red\", \"green\", \"blue\">> = {0, 1, 2}"),
    ("D3", "DomainProbe",
     "Claim2 == DOMAIN [hue |-> 3, sat |-> 7] = {\"hue\", \"sat\"}",
     "Claim2 == DOMAIN [hue |-> 3, sat |-> 7] = {\"hue\"}"),
    ("D4", "DomainProbe",
     "Claim6 == Cardinality(DOMAIN [i \\in 1..3, j \\in 1..2 |-> i]) = 6",
     "Claim6 == Cardinality(DOMAIN [i \\in 1..3, j \\in 1..2 |-> i]) = 5"),
    ("D5", "DomainProbe",
     "Claim5 == (\"hue\" :> 3 @@ \"hue\" :> 9)[\"hue\"] = 3",
     "Claim5 == (\"hue\" :> 3 @@ \"hue\" :> 9)[\"hue\"] = 9"),

    # --- KnobPanel (exercise 3) --------------------------------------------
    ("K1", "KnobPanel",
     "      dial[next] := ceiling;",
     "      dial[next] := MaxNotch;"),
    ("K2", "KnobPanel",
     "  DialType == [Knobs -> 0..ceiling]",
     "  DialType == [Knobs -> 1..ceiling]"),
    ("K3", "KnobPanel",
     "  dial = [k \\in Knobs |-> 0];",
     "  dial = [k \\in 1..NumKnobs+1 |-> 0];"),
    ("K4", "KnobPanel",
     "      dial[next] := ceiling;\n      next := next + 1;",
     "      dial[next] := ceiling + 1;\n      next := next + 1;"),
    ("K5", "KnobPanel",
     "  DialType == [Knobs -> 0..ceiling]",
     "  DialType == [Knobs -> 0..MaxNotch]"),

    # --- PatchDesk (exercise 4) --------------------------------------------
    ("T1", "PatchDesk",
     "    settings := settings @@ (\"retries\" :> 9);",
     "    settings := (\"retries\" :> 9) @@ settings;"),
    ("T2", "PatchDesk",
     "    settings := (\"retries\" :> 5) @@ settings;",
     "    settings := settings @@ (\"retries\" :> 5);"),
    ("T3", "PatchDesk",
     "    settings := settings @@ (\"retries\" :> 9);",
     "    settings := settings @@ (\"verbose\" :> 9);"),
    ("T4", "PatchDesk",
     "    settings := (\"retries\" :> 5) @@ settings;",
     "    settings := (\"retries\" :> 50) @@ settings;"),

    # --- FareTable (exercise 5) --------------------------------------------
    ("F1", "FareTable",
     "Fare == [a, b \\in Zones |-> IF a > b THEN a - b ELSE b - a]",
     "Fare == [a, b \\in Zones |-> a - b]"),
    ("F2", "FareTable",
     "Fare == [a, b \\in Zones |-> IF a > b THEN a - b ELSE b - a]",
     "Fare == [a, b \\in Zones |-> IF a > b THEN a - b ELSE b - a + 1]"),
    ("F3", "FareTable",
     "Zones == 1..3",
     "Zones == 1..4"),
    ("F4", "FareTable",
     "MaxFare == 2",
     "MaxFare == 1"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch06-mut"
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
