#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch13 exercise references.

Usage:  python3 exercises/ch13/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch13-mut`, which is scratch and
is not tracked.

WHY EACH MUTANT DIRECTORY GETS THE WHOLE GROUP

Chapter 13 is the multi-file chapter, so no reference here is one file. TLC finds
an INSTANCEd or EXTENDed module because it sits beside the module you named, and
that is exactly the property these exercises teach. A mutant directory therefore
carries every module in its group plus the .cfg, and SANY resolves the group the
same way it resolves the delivered starters directory.

The edited file is named per mutant and is often NOT the module TLC is pointed
at. Half of this chapter's failures are reported in a file the author never
touched, so the seeder has to be able to break Signal.tla and run Beacon.tla.

Each entry is (id, group, edited-file, expected-count, literal-old,
literal-new). One mutant is one literal substring replacement, applied to every
occurrence. An explicit count catches a pattern that has moved: a count that
comes out wrong is a seeding error, not a mutant.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch13/references"

# group name -> (root module TLC is pointed at, every file the group needs)
GROUPS = {
    "Dock":   ("Dock",   ["DockRules.tla", "Dock.tla", "Dock.cfg"]),
    "Beacon": ("Beacon", ["Palette.tla", "Signal.tla", "Beacon.tla",
                          "Beacon.cfg"]),
    "Cellar": ("Cellar", ["Band.tla", "Cellar.tla", "Cellar.cfg"]),
    "Garage": ("Garage", ["Tariff.tla", "Garage.tla", "Garage.cfg"]),
}

MUTANTS = [
    # --- Dock (exercise 1) -------------------------------------------------
    # D1 is the fail run EXERCISES.md states for exercise 1.
    ("D1", "Dock", "Dock.tla", 1,
     "WithinCap == Rules!NoBayOver(crates, Cap)",
     "WithinCap == Rules!Level(crates, \"north\") <= Cap"),
    ("D2", "Dock", "DockRules.tla", 1,
     "LOCAL Level(bays, b)",
     "Level(bays, b)"),
    ("D3", "Dock", "Dock.tla", 1,
     "Rules == INSTANCE DockRules",
     "INSTANCE DockRules"),
    ("D4", "Dock", "DockRules.tla", 1,
     "Level(bays, b) <= cap",
     "Level(bays, b) < cap"),
    ("D5", "Dock", "Dock.tla", 1,
     "crates[b] < Cap",
     "crates[b] <= Cap"),

    # --- Beacon (exercise 2) -----------------------------------------------
    # B1 is the fail run EXERCISES.md states for exercise 2.
    ("B1", "Beacon", "Signal.tla", 1,
     "INSTANCE Palette",
     "LOCAL INSTANCE Palette"),
    ("B2", "Beacon", "Palette.tla", 1,
     "\"red\", \"amber\"",
     "\"red\""),
    ("B3", "Beacon", "Signal.tla", 1,
     "c # \"amber\"",
     "TRUE"),
    ("B4", "Beacon", "Beacon.tla", 1,
     "EXTENDS Signal",
     "EXTENDS Palette"),
    ("B5", "Beacon", "Palette.tla", 1,
     "Cool == ",
     "LOCAL Cool == "),

    # --- Cellar (exercise 3) -----------------------------------------------
    # C1 is the fail run EXERCISES.md states for exercise 3.
    ("C1", "Cellar", "Cellar.tla", 1,
     "Lo <- 10, Hi <- 14",
     "Lo <- 10, Hi <- 11"),
    ("C2", "Cellar", "Cellar.tla", 1,
     "BeerBand == INSTANCE Band WITH Lo <- 2, Hi <- 6",
     "BeerBand == INSTANCE Band"),
    ("C3", "Cellar", "Band.tla", 1,
     "Holds(v) == v \\in Lo..Hi",
     "Holds(v) == v \\in Lo..Hi + 1"),
    ("C4", "Cellar", "Band.tla", 1,
     "Lo <= Hi",
     "Lo > Hi"),
    ("C5", "Cellar", "Band.tla", 1,
     "Headroom(v) == Hi - v",
     "Headroom(v) == v - Hi"),

    # --- Garage (exercise 4) -----------------------------------------------
    # G1 is the fail run EXERCISES.md states for exercise 4.
    ("G1", "Garage", "Garage.tla", 1,
     "Metered(3)",
     "Metered(5)"),
    ("G2", "Garage", "Garage.tla", 1,
     "Flat == INSTANCE Tariff WITH PerHour <- 0",
     "Flat == INSTANCE Tariff WITH PerHour <- 0, Base <- 0"),
    ("G3", "Garage", "Garage.tla", 1,
     "Metered(PerHour) == INSTANCE Tariff WITH Base <- 0",
     "Metered(PerHour) == INSTANCE Tariff WITH Base <- 100"),
    ("G4", "Garage", "Tariff.tla", 1,
     "Charge(hours) == Base + PerHour * hours",
     "Charge(hours) == Base + PerHour + hours"),
    ("G5", "Garage", "Garage.tla", 1,
     "CONSTANTS Base, MaxHours, Budget",
     "CONSTANTS MaxHours, Budget"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch13-mut"
    if os.path.isdir(out):
        shutil.rmtree(out)
    failures = 0
    for mid, group, edited, want, old, new in MUTANTS:
        root, files = GROUPS[group]
        d = os.path.join(out, mid)
        os.makedirs(d)
        for name in files:
            shutil.copyfile(os.path.join(REF, name), os.path.join(d, name))
        target = os.path.join(d, edited)
        with open(target, encoding="utf-8") as fh:
            body = fh.read()
        count = body.count(old)
        if count != want:
            print("SEED-ERROR " + mid + ": pattern occurs "
                  + str(count) + " times, wanted " + str(want))
            failures += 1
            continue
        with open(target, "w", encoding="utf-8") as fh:
            fh.write(body.replace(old, new))
        with open(os.path.join(d, "ROOT"), "w", encoding="utf-8") as fh:
            fh.write(root + "\n")
        print("seeded " + mid + " " + group + " (" + edited + ")")
    sys.exit(1 if failures else 0)


main()
