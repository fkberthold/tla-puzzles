#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch11 exercise references.

Usage:  python3 exercises/ch11/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch11-mut`, which is scratch and
is not tracked. Each mutant lands in its own directory under OUT_DIR, so the
module name inside the file still matches the file name, which SANY needs.

Each entry is (id, module, expected-count, literal-old, literal-new). One mutant
is one literal substring replacement, applied to every occurrence.

WHY AN EXPLICIT COUNT, AND WHY IT IS 2 FOR EVERY PROPERTY EDIT

The references carry the PlusCal block and its translation, so a line inside the
`define` block sits in the file TWICE: once indented inside the algorithm
comment, once unindented in the translation. TLC reads only the translated copy.
An edit that hit one copy and not the other would still model-check, would still
produce a verdict, and the verdict would be about the wrong text -- an inert
mutant that looks like a real one. So every property edit is written unindented,
matches both copies, and declares `2`. A count that comes out wrong is a seeding
error rather than a mutant, because it means the pattern moved.

`reports/run-mutants.sh` re-runs `pcal` over each seeded module anyway, which
puts the two copies back in agreement whichever one was edited. The count is the
belt to that braces: it catches a stale pattern at seed time instead of letting
`pcal` quietly paper over it.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch11/references"

MUTANTS = [
    # --- Odometer (exercise 1) ---------------------------------------------
    # O1 is the fail run EXERCISES.md states for exercise 1.
    ("O1", "Odometer", 1,
     "miles := miles + LegLength;",
     "miles := miles - LegLength;"),
    ("O2", "Odometer", 1,
     "legs := legs + 1;",
     "legs := legs + 2;"),
    ("O3", "Odometer", 2,
     "MilesNeverFall == [][miles' >= miles]_miles",
     "MilesNeverFall == [](miles' >= miles)"),
    ("O4", "Odometer", 2,
     "LegsCountUpByOne == [][legs' = legs + 1]_legs",
     "LegsCountUpByOne == [][legs' = legs + 1]_miles"),
    ("O5", "Odometer", 1,
     "MaxLegs == 3",
     "MaxLegs == 0"),

    # --- StepProbe (exercise 2) --------------------------------------------
    # S1 is the fail run EXERCISES.md states for exercise 2.
    ("S1", "StepProbe", 2,
     "RungGoesUpByOne == [][rung' = rung + 1]_rung",
     "RungGoesUpByOne == [](rung' = rung + 1)"),
    ("S2", "StepProbe", 2,
     "RungGoesUpByOne == [][rung' = rung + 1]_rung",
     "RungGoesUpByOne == [][rung' = rung + 1]_hand"),
    ("S3", "StepProbe", 1,
     "rung := rung + 1;",
     "rung := rung + 2;"),
    ("S4", "StepProbe", 2,
     "RungGoesUpByOne == [][rung' = rung + 1]_rung",
     "RungGoesUpByOne == [][rung' >= rung]_rung"),

    # --- Thermostat (exercise 3) -------------------------------------------
    # T1 is the fail run EXERCISES.md states for exercise 3.
    ("T1", "Thermostat", 1,
     "setpoint := setpoint + 1;",
     "setpoint := High;"),
    ("T2", "Thermostat", 2,
     "InRange == setpoint \\in Low..High",
     "InRange == setpoint \\in Low..High - 1"),
    ("T3", "Thermostat", 2,
     "MovesOneDegree == [][setpoint' - setpoint \\in {-1, 1}]_setpoint",
     "MovesOneDegree == [][setpoint' - setpoint \\in {-1, 0, 1}]_setpoint"),
    ("T4", "Thermostat", 1,
     "setpoint = 60,",
     "setpoint = 59,"),
    ("T5", "Thermostat", 2,
     "MovesOneDegree == [][setpoint' - setpoint \\in {-1, 1}]_setpoint",
     "MovesOneDegree == [][setpoint' - setpoint \\in {-1, 1}]_mode"),

    # --- TankFarm (exercise 4) ---------------------------------------------
    # K1 is the fail run EXERCISES.md states for exercise 4.
    ("K1", "TankFarm", 1,
     "level[self] := Cap;",
     "level[self] := 0;"),
    ("K2", "TankFarm", 2,
     "[][\\A t \\in Tanks: level[t]' >= level[t]]_level",
     "\\A t \\in Tanks: [][level[t]' >= level[t]]_level[t]"),
    ("K3", "TankFarm", 1,
     "level = [t \\in Tanks |-> 0];",
     "level = [t \\in Tanks |-> Cap];"),
    ("K4", "TankFarm", 2,
     "[][\\A t \\in Tanks: level[t]' >= level[t]]_level",
     "[][\\A t \\in Tanks: level[t]' > level[t]]_level"),
    ("K5", "TankFarm", 1,
     "level[self] := Cap;",
     "level[self] := Cap - 1;"),

    # --- Airlock (exercise 5) ----------------------------------------------
    # A1 is the fail run EXERCISES.md states for exercise 5.
    ("A1", "Airlock", 1,
     "          await outer = \"open\";\n          outer := \"shut\";",
     "          await outer = \"open\";\n          outer := \"ajar\";"),
    ("A2", "Airlock", 2,
     "Moves(door, to) == door' = to",
     "Moves(door, to) == door = to"),
    ("A3", "Airlock", 1,
     "await outer = \"shut\" /\\ inner = \"shut\";",
     "await outer = \"shut\";"),
    ("A4", "Airlock", 2,
     "InnerOnlyShuts == [][inner = \"open\" => Moves(inner, \"shut\")]_inner",
     "InnerOnlyShuts == [][inner = \"open\" => Moves(inner, \"shut\")]_outer"),
    ("A5", "Airlock", 1,
     "await inner = \"shut\" /\\ outer = \"shut\";",
     "await inner = \"shut\";"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch11-mut"
    if os.path.isdir(out):
        shutil.rmtree(out)
    failures = 0
    for mid, module, want, old, new in MUTANTS:
        d = os.path.join(out, mid)
        os.makedirs(d)
        with open(os.path.join(REF, module + ".tla"), encoding="utf-8") as fh:
            body = fh.read()
        count = body.count(old)
        if count != want:
            print("SEED-ERROR %s: pattern occurs %d times, wanted %d"
                  % (mid, count, want))
            failures += 1
            continue
        with open(os.path.join(d, module + ".tla"), "w", encoding="utf-8") as fh:
            fh.write(body.replace(old, new))
        shutil.copyfile(os.path.join(REF, module + ".cfg"),
                        os.path.join(d, module + ".cfg"))
        print("seeded %s %s" % (mid, module))
    sys.exit(1 if failures else 0)


main()
