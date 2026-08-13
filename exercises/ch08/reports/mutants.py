#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch08 exercise references.

Usage:  python3 exercises/ch08/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch08-mut`, which is scratch and
is not tracked. Each mutant lands in its own directory under OUT_DIR, so the
module name inside the file still matches the file name, which SANY needs.

Each entry is (id, module, literal-old, literal-new). One mutant is one literal
substring replacement. A pattern that does not occur exactly once is a seeding
error rather than a mutant, because a pattern matching twice would edit a line
nobody chose. The reference files carry the PlusCal block and its translation,
so most patterns below are indented on purpose to pin the PlusCal copy.

This chapter's specs are c-syntax PlusCal, so the patterns carry braces.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch08/references"

MUTANTS = [
    # --- SeatDesk (exercise 1) ---------------------------------------------
    # S1 is the fail run stated in EXERCISES.md: give the `if` its own label.
    ("S1", "SeatDesk",
     "      sawFree := (seats > 0);\n      if (sawFree) {",
     "      sawFree := (seats > 0);\n    Book:\n      if (sawFree) {"),
    ("S2", "SeatDesk",
     "        seats := seats - 1;",
     "        seats := seats - 2;"),
    ("S3", "SeatDesk",
     "    BooksBalance == seats + sold = Capacity",
     "    BooksBalance == seats + sold = Capacity + 1"),
    ("S4", "SeatDesk",
     "      sawFree := (seats > 0);",
     "      sawFree := (seats >= 0);"),

    # --- KitchenLocks (exercise 2) -----------------------------------------
    # Every KitchenLocks row is run with -d. See run-mutants.sh.
    # K1 is the fail run stated in EXERCISES.md: the cook reaches for the
    # whisk first, so the two of them take the utensils in opposite orders.
    ("K1", "KitchenLocks",
     "    CookTakesPan:\n"
     "      await pan = Nobody;\n"
     "      pan := \"cook\";\n"
     "    CookTakesWhisk:\n"
     "      await whisk = Nobody;\n"
     "      whisk := \"cook\";",
     "    CookTakesWhisk:\n"
     "      await whisk = Nobody;\n"
     "      whisk := \"cook\";\n"
     "    CookTakesPan:\n"
     "      await pan = Nobody;\n"
     "      pan := \"cook\";"),
    ("K2", "KitchenLocks",
     "    BakerPutsBack:\n      pan := Nobody;\n      whisk := Nobody;",
     "    BakerPutsBack:\n      whisk := Nobody;"),
    ("K3", "KitchenLocks",
     "    CookPutsBack:\n      pan := Nobody;\n      whisk := Nobody;",
     "    CookPutsBack:\n      skip;"),
    ("K4", "KitchenLocks",
     "    BakerTakesPan:\n"
     "      await pan = Nobody;\n"
     "      pan := \"baker\";\n"
     "    BakerTakesWhisk:\n"
     "      await whisk = Nobody;\n"
     "      whisk := \"baker\";",
     "    BakerTakesWhisk:\n"
     "      await whisk = Nobody;\n"
     "      whisk := \"baker\";\n"
     "    BakerTakesPan:\n"
     "      await pan = Nobody;\n"
     "      pan := \"baker\";"),

    # --- Cloakroom (exercise 3) --------------------------------------------
    # C1 is the fail run stated in EXERCISES.md: drop the guard.
    ("C1", "Cloakroom",
     "      if (free # {}) {\n"
     "        with (h = CHOOSE x \\in free : TRUE) {\n"
     "          coat[h] := self;\n"
     "          free := free \\ {h};\n"
     "        };\n"
     "      };",
     "      with (h = CHOOSE x \\in free : TRUE) {\n"
     "        coat[h] := self;\n"
     "        free := free \\ {h};\n"
     "      };"),
    ("C2", "Cloakroom",
     "          free := free \\ {h};",
     "          free := free \\ {};"),
    ("C3", "Cloakroom",
     "    CoatsAreGuests == \\A h \\in Hooks : coat[h] \\in {0} \\cup Guests",
     "    CoatsAreGuests == \\A h \\in Hooks : coat[h] \\in Guests"),
    ("C4", "Cloakroom",
     "    UsedHooksAreTaken == \\A h \\in Hooks : (coat[h] # 0) => (h \\notin free)",
     "    UsedHooksAreTaken == \\A h \\in Hooks : (coat[h] = 0) => (h \\notin free)"),

    # --- StampDesk (exercise 4) --------------------------------------------
    # T1 is the fail run stated in EXERCISES.md: ask for one copy too many.
    ("T1", "StampDesk",
     "      call Stamp(2);",
     "      call Stamp(3);"),
    # T2 is the documented INERT mutant. See authoring.md.
    ("T2", "StampDesk",
     "    Finish:\n      return;",
     "    Finish:\n      skip;"),
    ("T3", "StampDesk",
     "    LedgerBalances == stamped + ink = MaxInk",
     "    LedgerBalances == stamped + ink = MaxInk + 1"),
    ("T4", "StampDesk",
     "      while (made < copies) {",
     "      while (made <= copies) {"),
    ("T5", "StampDesk",
     "MaxInk == 4",
     "MaxInk == 3"),

    # --- BellTower (exercise 5) --------------------------------------------
    # B1 is the fail run stated in EXERCISES.md: add an operator to the
    # `define` block that reads a process-local variable.
    ("B1", "BellTower",
     "    RightTotal == AllRung => chimes = Quota * Cardinality(Ringers)",
     "    RightTotal == AllRung => chimes = Quota * Cardinality(Ringers)\n"
     "    EarlyTally == chimes + left[1] + left[2] = Quota * Cardinality(Ringers)"),
    ("B2", "BellTower",
     "      while (left > 0) {",
     "      while (left >= 0) {"),
    ("B3", "BellTower",
     "TallyMatches == chimes + left[1] + left[2] = Quota * Cardinality(Ringers)",
     "TallyMatches == chimes + left[1] + left[2] = Quota * Cardinality(Ringers) + 1"),
    ("B4", "BellTower",
     "    RightTotal == AllRung => chimes = Quota * Cardinality(Ringers)",
     "    RightTotal == chimes = Quota * Cardinality(Ringers)"),
    ("B5", "BellTower",
     "    variables left = Quota;",
     "    variables left = Quota + 1;"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch08-mut"
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
