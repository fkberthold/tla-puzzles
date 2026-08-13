#!/usr/bin/env python3
"""Seed the hand-written ch09 mutants into a scratch directory.

Usage:  python3 exercises/ch09/reports/mutants.py [MUT_DIR]

Run it from the repo root. MUT_DIR defaults to `.ch09-mut`, which matches
reports/run-mutants.sh. The directory is wiped and rebuilt on every run.

Every mutant is ONE edit to one reference file. Most edit the `.tla`, a couple
edit the `.cfg`. A `.tla` edit lands inside the PlusCal comment, so
run-mutants.sh re-runs `pcal` before checking: TLC reads the translation, and
an edit above it changes nothing until the translator has run again.

A mutant whose `old` text is not found is a hard error rather than a silent
skip. A seeder that quietly seeds nothing produces a table of passing mutants
that proves the opposite of what it looks like it proves.
"""

import os
import shutil
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
REF_DIR = os.path.join(REPO_ROOT, "exercises", "ch09", "references")

# (id, module, [cfg, ...], target-file-suffix, old, new, note)
#
# target-file-suffix is ".tla" or the exact .cfg basename.
MUTANTS = [
    # ---- Ex1 Footbridge: safety, no fairness anywhere -------------------
    ("F1", "Footbridge", ["Footbridge.cfg"], ".tla",
     '''        } or {
          await state # "condemned";
          state := "condemned";
        }''',
     '''        } or {
          await state # "condemned";
          state := "condemned";
        } or {
          await state = "condemned";
          state := "shut";
        }''',
     "a condemned bridge reopens; this is the exercise's stated fail edit"),

    ("F2", "Footbridge", ["Footbridge.cfg"], ".tla",
     '[](state = "condemned" => [](state = "condemned"))',
     '[](state = "condemned" => state = "condemned")',
     "inner box dropped, leaving a tautology"),

    ("F3", "Footbridge", ["Footbridge.cfg"], "Footbridge.cfg",
     '''  StateOK

PROPERTY
  CondemnedIsForever''',
     '''  StateOK
  CondemnedIsForever''',
     "the temporal formula moved from PROPERTY to INVARIANT"),

    ("F4", "Footbridge", ["Footbridge.cfg"], ".tla",
     '''          await state # "condemned";
          state := "condemned";''',
     '''          await state # "condemned";
          state := "shut";''',
     "nothing is ever condemned, so the antecedent never fires"),

    ("F5", "Footbridge", ["Footbridge.cfg"], ".tla",
     '''          await state = "shut";
          state := "open";''',
     '''          await state = "open";
          state := "open";''',
     "the open branch is now unreachable from shut"),

    # ---- Ex2 Kiln: weak fairness ---------------------------------------
    ("K1", "Kiln", ["Kiln.cfg"], ".tla",
     "  fair process (Fire = \"fire\") {",
     "  process (Fire = \"fire\") {",
     "FAIRNESS-WEAKENING: fair deleted outright"),

    # The first draft of K2 was `while (soaks < MaxSoak)` -> `while (TRUE)`.
    # It came back TIMEOUT rc=124, not a liveness violation: `soaks` then grows
    # without bound and the state space is infinite, so TLC never gets far
    # enough to judge the property. Assigning 0 instead of incrementing keeps
    # the loop infinite and the state space finite, which is what the mutant
    # was actually trying to say.
    ("K2", "Kiln", ["Kiln.cfg"], ".tla",
     "        soaks := soaks + 1;",
     "        soaks := 0;",
     "fairness kept, the soak counter never advances"),

    ("K3", "Kiln", ["Kiln.cfg"], ".tla",
     'FiringFinishes == <>(stage = "cooled")',
     'FiringFinishes == [](stage = "cooled")',
     "eventually swapped for always"),

    ("K4", "Kiln", ["Kiln.cfg"], ".tla",
     'FiringFinishes == <>(stage = "cooled")',
     'FiringFinishes == <>(stage \\in Stages)',
     "the goal weakened to something true in the first state"),

    ("K5", "Kiln", ["Kiln.cfg"], ".tla",
     "MaxSoak == 2",
     "MaxSoak == 0",
     "the soak loop never runs a turn"),

    # ---- Ex3 LoadingBay: strong fairness --------------------------------
    ("L1", "LoadingBay", ["LoadingBay.cfg"], ".tla",
     "  fair+ process (H \\in Hauliers) {",
     "  fair process (H \\in Hauliers) {",
     "FAIRNESS-WEAKENING: strong downgraded to weak"),

    ("L2", "LoadingBay", ["LoadingBay.cfg"], ".tla",
     "  fair+ process (H \\in Hauliers) {",
     "  process (H \\in Hauliers) {",
     "FAIRNESS-WEAKENING: all fairness deleted"),

    ("L3", "LoadingBay", ["LoadingBay.cfg"], ".tla",
     '''        Go:
          bay := NULL;''',
     '''        Go:
          bay := self;''',
     "fairness kept, the bay is never released"),

    # The first draft of L4 inserted SYMMETRY in the middle of the CONSTANTS
    # block, which orphaned `NULL = NULL` behind the new keyword. That is a
    # config syntax error, and it returned TLC_EXCEPTION rc=255 for a reason
    # that had nothing to do with symmetry. Appending at the end asks the
    # question the mutant meant to ask.
    ("L4", "LoadingBay", ["LoadingBay.cfg"], "LoadingBay.cfg",
     '''PROPERTY
  EveryoneKeepsDocking''',
     '''PROPERTY
  EveryoneKeepsDocking

SYMMETRY
  Perms''',
     "a symmetry set declared alongside a liveness property"),

    ("L5", "LoadingBay", ["LoadingBay.cfg"], ".tla",
     "EveryoneKeepsDocking == \\A h \\in Hauliers: []<>(bay = h)",
     "EveryoneKeepsDocking == \\E h \\in Hauliers: []<>(bay = h)",
     "forall weakened to exists"),

    # ---- Ex4 Beacon: three properties, three configs ---------------------
    ("B1", "Beacon", ["BeaconEver.cfg", "BeaconAgain.cfg", "BeaconSettles.cfg"], ".tla",
     "  fair process (Keeper = \"keeper\") {",
     "  process (Keeper = \"keeper\") {",
     "FAIRNESS-WEAKENING: fair deleted outright"),

    ("B2", "Beacon", ["BeaconEver.cfg", "BeaconAgain.cfg", "BeaconSettles.cfg"], ".tla",
     '''        if (lamp = "dark") {
          lamp := "lit";''',
     '''        if (lamp = "dark") {
          lamp := "dark";''',
     "fairness kept, the lamp never lights"),

    ("B3", "Beacon", ["BeaconEver.cfg", "BeaconAgain.cfg", "BeaconSettles.cfg"], ".tla",
     'SettlesLit == <>[](lamp = "lit")',
     'SettlesLit == <>[](lamp \\in {"lit", "dark"})',
     "the settling target weakened to the type invariant"),

    ("B4", "Beacon", ["BeaconEver.cfg", "BeaconAgain.cfg", "BeaconSettles.cfg"], ".tla",
     '        if (lamp = "dark") {',
     '        if (TRUE) {',
     "fairness kept, the lamp lights once and stays lit"),

    ("B5", "Beacon", ["BeaconEver.cfg", "BeaconAgain.cfg", "BeaconSettles.cfg"], ".tla",
     '  variables lamp = "dark";',
     '  variables lamp = "lit";',
     "the beacon starts lit"),

    # ---- Ex5 Depot: leads-to under weak fairness --------------------------
    ("D1", "Depot", ["Depot.cfg", "DepotProbe.cfg"], ".tla",
     "MaxOpen == 2",
     "MaxOpen == 0",
     "the capacity constant that ships in the starter"),

    ("D2", "Depot", ["Depot.cfg", "DepotProbe.cfg"], ".tla",
     '''        } or {
          with (p \\in mended \\ collected) {
            collected := collected \\union {p};
          }
        }''',
     '''        }
        }''',
     "fairness kept, nothing is ever collected"),

    ("D3", "Depot", ["Depot.cfg", "DepotProbe.cfg"], ".tla",
     '  fair process (Clerk = "clerk") {',
     '  process (Clerk = "clerk") {',
     "FAIRNESS-WEAKENING: fair deleted outright"),

    ("D4", "Depot", ["Depot.cfg", "DepotProbe.cfg"], ".tla",
     "      /\\ \\A p \\in Parts: (p \\in booked ~> p \\in mended)",
     "      /\\ \\A p \\in Parts: (p \\in booked => p \\in mended)",
     "leads-to swapped for plain implication"),

    ("D5", "Depot", ["Depot.cfg", "DepotProbe.cfg"], ".tla",
     "          with (p \\in booked \\ mended) {",
     "          with (p \\in mended \\ booked) {",
     "fairness kept, the mend branch is never enabled"),
]


def main():
    mut_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO_ROOT, ".ch09-mut")
    if os.path.isdir(mut_dir):
        shutil.rmtree(mut_dir)
    os.makedirs(mut_dir)

    failures = []
    for mid, module, cfgs, target, old, new, note in MUTANTS:
        dest = os.path.join(mut_dir, mid)
        os.makedirs(dest)
        shutil.copy(os.path.join(REF_DIR, module + ".tla"),
                    os.path.join(dest, module + ".tla"))
        for cfg in cfgs:
            shutil.copy(os.path.join(REF_DIR, cfg), os.path.join(dest, cfg))

        target_file = module + ".tla" if target == ".tla" else target
        path = os.path.join(dest, target_file)
        with open(path) as fh:
            text = fh.read()
        # A define-block operator sits in the file TWICE once pcal has run:
        # once in the PlusCal comment and once in the translation below it.
        # Both copies are replaced. Replacing only the comment copy would also
        # work, because run-mutants.sh re-translates, but leaving a stale
        # translation on disk between the two steps is how a reader ends up
        # believing the wrong text is what ran.
        count = text.count(old)
        if count not in (1, 2):
            failures.append("%s: pattern found %d times in %s" % (mid, count, target_file))
            continue
        with open(path, "w") as fh:
            fh.write(text.replace(old, new))

        with open(os.path.join(dest, "cfgs.txt"), "w") as fh:
            fh.write("\n".join(cfgs) + "\n")
        with open(os.path.join(dest, "note.txt"), "w") as fh:
            fh.write(note + "\n")

    if failures:
        for line in failures:
            sys.stderr.write("SEED FAILED  " + line + "\n")
        sys.exit(1)

    print("seeded %d mutants into %s" % (len(MUTANTS), mut_dir))


if __name__ == "__main__":
    main()
