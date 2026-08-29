#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch12 exercise references.

Usage:  python3 exercises/ch12/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch12-mut`, which is scratch
and is not tracked. Each mutant lands in its own directory under OUT_DIR, so
the module name inside the file still matches the file name, which SANY needs.

Each entry is (id, module, expected-count, literal-old, literal-new). One
mutant is one literal substring replacement, applied to every occurrence.

WHY AN EXPLICIT COUNT, AND WHY IT IS 1 EVERYWHERE HERE

Chapter 12 is pure TLA+. Nothing in `references/` carries a PlusCal block, so
no definition sits in the file twice and there is no translated copy to keep
in step. That is the whole reason ch11's seeder declared 2 for every property
edit and this one declares 1: the duplication ch11 was guarding against does
not exist in this chapter. The count is still declared, and still checked,
because a count that comes out wrong means the pattern moved rather than that
the mutant is interesting.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch12/references"

MUTANTS = [
    # --- SeedDrill (exercise 1) --------------------------------------------
    # D1 is the fail run EXERCISES.md states for exercise 1.
    ("D1", "SeedDrill", 1,
     "          /\\ UNCHANGED rows\n",
     ""),
    ("D2", "SeedDrill", 1,
     "         /\\ rows' = rows + 1",
     "         /\\ rows' = rows + 2"),
    ("D3", "SeedDrill", 1,
     "Init == /\\ hopper = Capacity",
     "Init == /\\ hopper = Capacity + 1"),
    ("D4", "SeedDrill", 1,
     "vars == << hopper, rows >>",
     "vars == << hopper >>"),
    ("D5", "SeedDrill", 1,
     "Plant == /\\ rows < MaxRows",
     "Plant == /\\ rows < MaxRows + 1"),

    # --- Apiary (exercise 2) -----------------------------------------------
    # A1 is the fail run EXERCISES.md states for exercise 2.
    ("A1", "Apiary", 1,
     "                   /\\ frames[b] < MaxFrames\n",
     ""),
    # A2 is the trap the task text warns about, and the verdict the
    # After-the-run section states for it.
    ("A2", "Apiary", 1,
     "                   /\\ frames' = [frames EXCEPT ![a] = @ - 1, ![b] = @ + 1]",
     "                   /\\ frames[a]' = frames[a] - 1\n"
     "                   /\\ frames[b]' = frames[b] + 1"),
    ("A3", "Apiary", 1,
     "[frames EXCEPT ![a] = @ - 1, ![b] = @ + 1]",
     "[frames EXCEPT ![a] = @ - 1]"),
    ("A4", "Apiary", 1,
     "[frames EXCEPT ![h] = @ + 1]",
     "[frames EXCEPT ![h] = @ + 2]"),
    ("A5", "Apiary", 1,
     "Init == frames = [h \\in Hives |-> 1]",
     "Init == frames = [h \\in Hives |-> 4]"),

    # --- GlazingBench (exercise 3) -----------------------------------------
    # G1 is the fail run EXERCISES.md states for exercise 3.
    ("G1", "GlazingBench", 1,
     "               /\\ bench = Free\n",
     ""),
    ("G2", "GlazingBench", 1,
     "             /\\ bench' = Free",
     "             /\\ UNCHANGED bench"),
    ("G3", "GlazingBench", 1,
     "pc' = [pc EXCEPT ![self] = to]",
     "pc' = [pc EXCEPT ![self] = from]"),
    ("G4", "GlazingBench", 1,
     "               /\\ UNCHANGED panes\n",
     ""),
    ("G5", "GlazingBench", 1,
     "Next == (\\E self \\in Glaziers : glazier(self))\n          \\/ Terminating",
     "Next == (\\E self \\in Glaziers : glazier(self))"),

    # --- Drawbridge (exercise 4) -------------------------------------------
    # W1 is the fail run EXERCISES.md states for exercise 4, and the whole
    # point of the chapter's own comprehension test.
    ("W1", "Drawbridge", 1,
     "        /\\ \\A w \\in Winches : WF_vars(Raise(w))",
     "        /\\ \\E w \\in Winches : WF_vars(Raise(w))"),
    ("W2", "Drawbridge", 1,
     "\n        /\\ \\A w \\in Winches : WF_vars(Raise(w))",
     ""),
    ("W3", "Drawbridge", 1,
     "WF_vars(Raise(w))",
     "WF_turns(Raise(w))"),
    ("W4", "Drawbridge", 1,
     "Raise(w) == /\\ turns[w] < Target",
     "Raise(w) == /\\ turns[w] < Target + 1"),
    ("W5", "Drawbridge", 1,
     "BridgeRaised == <>(\\A w \\in Winches : turns[w] = Target)",
     "BridgeRaised == [](\\A w \\in Winches : turns[w] = Target)"),

    # --- Capper (exercise 5) -----------------------------------------------
    # C1 is the fail run EXERCISES.md states for exercise 5. C2 and C3 are the
    # two extra runs the After-the-run section states verdicts for.
    ("C1", "Capper", 1,
     "            /\\ SF_vars(Cap)",
     "            /\\ WF_vars(Cap)"),
    ("C2", "Capper", 1,
     "            /\\ SF_vars(Cap)",
     "            /\\ SF_vars(Press)"),
    ("C3", "Capper", 1,
     "Fairness == /\\ WF_vars(Arrive)",
     "Fairness == /\\ WF_capped(Arrive)"),
    ("C4", "Capper", 1,
     "Fairness == /\\ WF_vars(Arrive)\n",
     "Fairness == "),
    ("C5", "Capper", 1,
     "Press == Cap \\/ Wave",
     "Press == Cap"),
]


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else ".ch12-mut"
    if os.path.isdir(out_dir):
        shutil.rmtree(out_dir)
    os.makedirs(out_dir)

    failures = []
    for mut_id, module, count, old, new in MUTANTS:
        src_tla = os.path.join(REF, module + ".tla")
        src_cfg = os.path.join(REF, module + ".cfg")
        dest = os.path.join(out_dir, mut_id)
        os.makedirs(dest)

        with open(src_tla, encoding="utf-8") as fh:
            text = fh.read()
        seen = text.count(old)
        if seen != count:
            failures.append(
                "%s: pattern occurs %d times, declared %d" % (mut_id, seen, count)
            )
            continue
        with open(os.path.join(dest, module + ".tla"), "w", encoding="utf-8") as fh:
            fh.write(text.replace(old, new))
        shutil.copyfile(src_cfg, os.path.join(dest, module + ".cfg"))
        print("seeded %s (%s)" % (mut_id, module))

    if failures:
        for line in failures:
            print("SEEDING ERROR " + line, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
