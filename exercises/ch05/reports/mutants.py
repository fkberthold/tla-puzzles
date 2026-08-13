#!/usr/bin/env python3
"""Seed the hand-written single-edit mutants for the ch05 exercise references.

Usage:  python3 exercises/ch05/reports/mutants.py [OUT_DIR]

Run it from the repo root. OUT_DIR defaults to `.ch05-mut`, which is scratch
and is not tracked. Each mutant lands in its own directory under OUT_DIR,
carrying a copy of both the module's `.tla` and its `.cfg`, so the module name
inside the file still matches the file name (which SANY needs) regardless of
which of the two files the mutant actually edits.

Each entry is (id, subdir, module, target, literal-old, literal-new). `target`
is `"tla"` or `"cfg"`, naming which of the two copied files gets the literal
substring replacement; the other file is copied unmodified. A pattern that
does not occur exactly once in its target file is a seeding error rather than
a mutant, because a pattern matching twice would edit a line nobody chose.
Four mutants (A2, K5, L5, H4) delete a whole `CONSTANT` line by replacing that
line plus its newline with the empty string.

This is the c-syntax counterpart of the original p-syntax mutant table in
reports/authoring.md (bead tla-wza0). None of the 25 patterns needed an
adapted match: the 14 `.cfg` mutants are untouched by a PlusCal syntax change
(a `.cfg` carries no PlusCal), and every `.tla` mutation site sits inside a
`define` expression, a variable initializer, or a plain assignment statement,
none of which the p-to-c conversion altered textually.

Results are recorded in reports/authoring.md. Run reports/run-mutants.sh after
this to get the verdicts.
"""
import os
import shutil
import sys

REF = "exercises/ch05/references"

MUTANTS = [
    # --- Allowance (exercise 1) ---------------------------------------------
    ("A1", "ex1-allowance", "Allowance", "cfg",
     "CONSTANT StartingCredit = 4",
     "CONSTANT StartingCredit = 7"),
    ("A2", "ex1-allowance", "Allowance", "cfg",
     "CONSTANT StartingCredit = 4\n",
     ""),
    ("A3", "ex1-allowance", "Allowance", "tla",
     "credit := credit - 2;",
     "credit := credit - 3;"),
    ("A4", "ex1-allowance", "Allowance", "tla",
     "  CreditNeverNegative == credit >= 0",
     "  CreditNeverNegative == credit >= 1"),
    ("A5", "ex1-allowance", "Allowance", "cfg",
     "INVARIANT CreditNeverNegative",
     "INVARIANT CreditNeverNegativeX"),

    # --- Kiln (exercise 2) ---------------------------------------------------
    ("K1", "ex2-kiln", "Kiln", "cfg",
     "CONSTANT Deadline = 4",
     "CONSTANT Deadline = 0"),
    ("K2", "ex2-kiln", "Kiln", "cfg",
     "CONSTANT Deadline = 4",
     "CONSTANT Deadline = 99"),
    ("K3", "ex2-kiln", "Kiln", "tla",
     "  ClockInWindow == clock \\in Warmup..Deadline",
     "  ClockInWindow == clock \\in Warmup..Deadline-1"),
    ("K4", "ex2-kiln", "Kiln", "tla",
     "clock = Warmup;",
     "clock = Warmup - 1;"),
    ("K5", "ex2-kiln", "Kiln", "cfg",
     "CONSTANT Warmup = 1\n",
     ""),

    # --- Locker (exercise 3) --------------------------------------------------
    ("L1", "ex3-locker", "Locker", "cfg",
     "CONSTANT Unclaimed = Unclaimed",
     "CONSTANT Unclaimed = 3"),
    ("L2", "ex3-locker", "Locker", "cfg",
     "CONSTANT Unclaimed = Unclaimed",
     "CONSTANT Unclaimed = \"free\""),
    ("L3", "ex3-locker", "Locker", "tla",
     "  FreeIffSentinel == claimed = (holder # Unclaimed)",
     "  FreeIffSentinel == claimed = (holder = Unclaimed)"),
    ("L4", "ex3-locker", "Locker", "tla",
     "      claimed := TRUE;",
     "      claimed := FALSE;"),
    ("L5", "ex3-locker", "Locker", "cfg",
     "CONSTANT Unclaimed = Unclaimed\n",
     ""),

    # --- Relay (exercise 4) ---------------------------------------------------
    ("R1", "ex4-relay", "Relay", "cfg",
     "CONSTANT Runners = {r1, r2, r3}",
     "CONSTANT Runners = {\"r1\", \"r2\", \"r3\"}"),
    ("R2", "ex4-relay", "Relay", "tla",
     "Perms == Permutations(Runners)",
     "Perms == Runners"),
    ("R3", "ex4-relay", "Relay", "cfg",
     "SYMMETRY Perms",
     "SYMMETRY Perm"),
    ("R4", "ex4-relay", "Relay", "tla",
     "  TouchedAreRunners == touched \\subseteq Runners",
     "  TouchedAreRunners == touched = Runners"),
    ("R5", "ex4-relay", "Relay", "tla",
     "  CarrierIsRunner == carrier \\in Runners",
     "  CarrierIsRunner == carrier \\notin Runners"),

    # --- Rehearsal (exercise 5) ------------------------------------------------
    ("H1", "ex5-rehearsal", "Rehearsal", "cfg",
     "CONSTANT StrictMode = TRUE",
     "CONSTANT StrictMode = 7"),
    ("H2", "ex5-rehearsal", "Rehearsal", "tla",
     "Ceiling == IF StrictMode THEN 2 ELSE 5",
     "Ceiling == IF StrictMode THEN 3 ELSE 5"),
    ("H3", "ex5-rehearsal", "Rehearsal", "tla",
     "  LevelCapped == level <= 2",
     "  LevelCapped == level <= 1"),
    ("H4", "ex5-rehearsal", "Rehearsal", "cfg",
     "CONSTANT StrictMode = TRUE\n",
     ""),
    ("H5", "ex5-rehearsal", "Rehearsal", "cfg",
     "INVARIANT LevelCapped",
     "INVARIANT LevelCappedX"),
]


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else ".ch05-mut"
    if os.path.isdir(out):
        shutil.rmtree(out)
    failures = 0
    for mid, subdir, module, target, old, new in MUTANTS:
        d = os.path.join(out, mid)
        os.makedirs(d)
        src_dir = os.path.join(REF, subdir)
        tla_path = os.path.join(src_dir, module + ".tla")
        cfg_path = os.path.join(src_dir, module + ".cfg")

        with open(tla_path, encoding="utf-8") as fh:
            tla_body = fh.read()
        with open(cfg_path, encoding="utf-8") as fh:
            cfg_body = fh.read()

        body = tla_body if target == "tla" else cfg_body
        count = body.count(old)
        if count != 1:
            print("SEED-ERROR %s: pattern occurs %d times in .%s, wanted 1" %
                  (mid, count, target))
            failures += 1
            continue
        mutated = body.replace(old, new)
        if target == "tla":
            tla_body = mutated
        else:
            cfg_body = mutated

        with open(os.path.join(d, module + ".tla"), "w", encoding="utf-8") as fh:
            fh.write(tla_body)
        with open(os.path.join(d, module + ".cfg"), "w", encoding="utf-8") as fh:
            fh.write(cfg_body)
        print("seeded %s %s (%s)" % (mid, module, target))
    sys.exit(1 if failures else 0)


main()
