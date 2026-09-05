#!/usr/bin/env python3
"""Generate the frozen seeded-variant matrix for the herbarium-sheet reference.

Every variant is a copy of authoring/herbarium-sheet/reference/Herbarium.tla with
one named mutation applied and the module header renamed to the variant id. The
mutations are stated here as exact (old, new) text pairs, so this file IS the
matrix: a reader checks a row by reading the pair, not by diffing the output.

The matrix was frozen before any TLC run. Do not add rows to it.

Run from the repo root:  python3 authoring/herbarium-sheet/reports/step2-variants/generate.py
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
REF_TLA = os.path.join(ROOT, "authoring", "herbarium-sheet", "reference", "Herbarium.tla")
REF_CFG = os.path.join(ROOT, "authoring", "herbarium-sheet", "reference", "Herbarium.cfg")

# ---------------------------------------------------------------- anchors ---

CONSULT = r"""Consult(b, s) ==
    /\ consulted[s] < Handling[s]
    /\ consulted' = [consulted EXCEPT ![s] = @ + 1]
    /\ reading' = [reading EXCEPT ![b][s] = consulted[s] + 1]
    /\ UNCHANGED <<slips, accepted, doubted>>"""

FILE_GUARD = r"""File(b, s, n) ==
    /\ reading[b][s] # None
    /\ LET filed"""

SLIP_RECORD = r"[name |-> n, stamp |-> reading[b][s]]"

FILED_LET = r"    /\ LET filed == slips[s] \cup {[name |-> n, stamp |-> reading[b][s]]}"

FILE_TAIL = r"""           /\ doubted' = [doubted EXCEPT ![s] = FALSE]
    /\ UNCHANGED consulted"""

ACCEPTED_SET = r"           /\ accepted' = [accepted EXCEPT ![s] = TopName(filed)]"

DOUBT_GUARD = r"""    /\ reading[b][s] # None
    /\ doubted[s] = FALSE"""

NEXT = r"""Next ==
    \/ \E b \in Botanists, s \in Sheets : Consult(b, s)
    \/ \E b \in Botanists, s \in Sheets : FileStep(b, s)
    \/ \E b \in Botanists, s \in Sheets : Doubt(b, s)"""

FAIRNESS = r"    /\ \A b \in Botanists, s \in Sheets : WF_vars(FileStep(b, s))"

ALLOWANCES = r"Allowances == [s \in Sheets |-> IF s = 1 THEN 2 ELSE 1]"

TOPNAME = r"TopName(S) == (CHOOSE r \in S : \A q \in S : q.stamp =< r.stamp).name"

DOUBT_RULE = r"""DoubtClearsOnlyOnFiling ==
    [][\A s \in Sheets :
          (/\ Observe.doubted[s] = TRUE
           /\ Observe'.doubted[s] = FALSE)
              => Observe'.slips[s] \ Observe.slips[s] # {}]_Observe"""

COMES_FROM_TAIL = r"                    => Observe'.slips[s] \ Observe.slips[s] # {}]_Observe"

GROWS_TAIL = r"                       /\ Observe'.consulted[s] = Observe'.reading[b][s]]_Observe"


def sub(old, new):
    """One replacement, asserted unique."""
    def apply(text):
        if text.count(old) != 1:
            raise SystemExit("anchor is not unique: %r appears %d times"
                             % (old[:60], text.count(old)))
        return text.replace(old, new)
    return apply


def chain(*steps):
    def apply(text):
        for step in steps:
            text = step(text)
        return text
    return apply


def add_action(defn, disjunct):
    """Append an action definition before Next and add a Next disjunct."""
    return chain(sub(NEXT, defn + "\n\n" + NEXT),
                 sub(NEXT, NEXT + "\n    " + disjunct))


# ------------------------------------------------- family S, the system ---

VARIANTS = {}

# --- the opening (item 7) and the Init ---

VARIANTS["S01"] = ("opening-doubted", sub(
    r"    /\ doubted = [s \in Sheets |-> FALSE]",
    r"    /\ doubted = [s \in Sheets |-> TRUE]"))

VARIANTS["S02"] = ("opening-slip-seeded", chain(
    sub(ALLOWANCES, ALLOWANCES + "\n\n" + r"Seed == CHOOSE n \in Names : TRUE"),
    sub(r"    /\ slips = [s \in Sheets |-> {}]",
        r"    /\ slips = [s \in Sheets |-> {[name |-> Seed, stamp |-> 1]}]")))

VARIANTS["S03"] = ("opening-consulted-one", sub(
    r"    /\ consulted = [s \in Sheets |-> 0]",
    r"    /\ consulted = [s \in Sheets |-> 1]"))

VARIANTS["S04"] = ("opening-accepted-set", chain(
    sub(ALLOWANCES, ALLOWANCES + "\n\n" + r"Seed == CHOOSE n \in Names : TRUE"),
    sub(r"    /\ accepted = [s \in Sheets |-> None]",
        r"    /\ accepted = [s \in Sheets |-> Seed]")))

# --- the record is well formed (item 1) ---

VARIANTS["S05"] = ("consult-reads-ahead", sub(
    r"    /\ reading' = [reading EXCEPT ![b][s] = consulted[s] + 1]",
    r"    /\ reading' = [reading EXCEPT ![b][s] = Handling[s]]"))

VARIANTS["S06"] = ("handling-uncapped", sub(
    r"    /\ consulted[s] < Handling[s]",
    r"    /\ consulted[s] < Handling[s] + 1"))

VARIANTS["S07"] = ("slip-stamp-frozen", sub(
    SLIP_RECORD, r"[name |-> n, stamp |-> 1]"))

# --- the accepted name (item 2) ---

VARIANTS["S08"] = ("accepted-not-updated", sub(
    ACCEPTED_SET, r"           /\ accepted' = accepted"))

VARIANTS["S09"] = ("accepted-is-filers-name", sub(
    ACCEPTED_SET, r"           /\ accepted' = [accepted EXCEPT ![s] = n]"))

VARIANTS["S10"] = ("accepted-is-lowest-slip", chain(
    sub(TOPNAME, TOPNAME + "\n\n"
        + r"BottomName(S) == (CHOOSE r \in S : \A q \in S : r.stamp =< q.stamp).name"),
    sub(ACCEPTED_SET,
        r"           /\ accepted' = [accepted EXCEPT ![s] = BottomName(filed)]")))

# --- the record only grows (item 3) ---

VARIANTS["S11"] = ("slips-replaced", sub(
    FILED_LET,
    r"    /\ LET filed == {[name |-> n, stamp |-> reading[b][s]]}"))

VARIANTS["S12"] = ("sheet-withdrawn", add_action(
    r"""Withdraw(s) ==
    /\ slips[s] # {}
    /\ slips' = [slips EXCEPT ![s] = {}]
    /\ accepted' = [accepted EXCEPT ![s] = None]
    /\ UNCHANGED <<consulted, reading, doubted>>""",
    r"\/ \E s \in Sheets : Withdraw(s)"))

VARIANTS["S13"] = ("consult-without-stamping", sub(
    r"""    /\ reading' = [reading EXCEPT ![b][s] = consulted[s] + 1]
    /\ UNCHANGED <<slips, accepted, doubted>>""",
    r"    /\ UNCHANGED <<slips, reading, accepted, doubted>>"))

VARIANTS["S14"] = ("reread-without-consulting", add_action(
    r"""Reread(b, s) ==
    /\ consulted[s] > 0
    /\ reading[b][s] = None
    /\ reading' = [reading EXCEPT ![b][s] = consulted[s]]
    /\ UNCHANGED <<slips, consulted, accepted, doubted>>""",
    r"\/ \E b \in Botanists, s \in Sheets : Reread(b, s)"))

# --- a slip comes from a consultation (item 4) ---

VARIANTS["S15"] = ("file-above-the-reading", sub(
    SLIP_RECORD, r"[name |-> n, stamp |-> consulted[s]]"))

VARIANTS["S16"] = ("consultation-cancelled", add_action(
    r"""Cancel(b, s) ==
    /\ reading[b][s] # None
    /\ reading' = [reading EXCEPT ![b][s] = None]
    /\ UNCHANGED <<slips, consulted, accepted, doubted>>""",
    r"\/ \E b \in Botanists, s \in Sheets : Cancel(b, s)"))

VARIANTS["S17"] = ("file-carbon-copy", sub(
    FILED_LET,
    r"    /\ LET filed == slips[s] \cup {[name |-> n, stamp |-> reading[b][s]],"
    + "\n" + r"                                   [name |-> n, stamp |-> 1]}"))

VARIANTS["S18"] = ("file-without-a-reading", chain(
    sub(FILE_GUARD, "File(b, s, n) ==\n"
        + r"    /\ consulted[s] > 0" + "\n    /\\ LET filed"),
    sub(SLIP_RECORD, r"[name |-> n, stamp |-> consulted[s]]")))

# --- a doubt clears only on a filing (item 5) ---

VARIANTS["S19"] = ("doubt-clears-on-consult", sub(
    r"    /\ UNCHANGED <<slips, accepted, doubted>>",
    "    /\\ doubted' = [doubted EXCEPT ![s] = FALSE]\n"
    + r"    /\ UNCHANGED <<slips, accepted>>"))

# --- an open consultation is eventually answered (item 6) ---

VARIANTS["S20"] = ("file-keeps-the-mark", sub(
    FILE_TAIL, r"    /\ UNCHANGED <<consulted, doubted>>"))

VARIANTS["S21"] = ("doubt-unguarded", sub(
    DOUBT_GUARD, r"    /\ doubted[s] = FALSE"))

VARIANTS["S22"] = ("fairness-dropped", sub("\n" + FAIRNESS, ""))

# --- the ambiguity that tightens rather than breaks, and the floor cases ---

VARIANTS["S23"] = ("doubt-needs-an-accepted-name", sub(
    DOUBT_GUARD, DOUBT_GUARD + "\n" + r"    /\ accepted[s] # None"))

VARIANTS["S24"] = ("name-carries-a-stamp", sub(
    SLIP_RECORD, r"[name |-> reading[b][s], stamp |-> reading[b][s]]"))

VARIANTS["S25"] = ("nothing-happens", sub(NEXT, r"Next == UNCHANGED vars"))

# ---------------------------------- the shape D hidden model, and family P ---

CLEAR_ACTION = add_action(
    r"""Clear(s) ==
    /\ doubted[s] = TRUE
    /\ doubted' = [doubted EXCEPT ![s] = FALSE]
    /\ UNCHANGED <<slips, consulted, reading, accepted>>""",
    r"\/ \E s \in Sheets : Clear(s)")

WRONG_DOUBT_SUBSCRIPT = sub(
    DOUBT_RULE, DOUBT_RULE.replace(r"# {}]_Observe", r"# {}]_(Observe.slips)"))

WRONG_COMES_FROM_SUBSCRIPT = sub(
    COMES_FROM_TAIL, COMES_FROM_TAIL.replace(r"# {}]_Observe", r"# {}]_(Observe.slips)"))

WRONG_GROWS_SUBSCRIPT = sub(
    GROWS_TAIL, GROWS_TAIL.replace(r"]_Observe", r"]_(Observe.consulted)"))

VARIANTS["D01"] = ("mark-comes-off-freely", CLEAR_ACTION)

VARIANTS["P01"] = ("doubt-rule-wrong-subscript", WRONG_DOUBT_SUBSCRIPT)
VARIANTS["P01D01"] = ("the-shipped-green", chain(CLEAR_ACTION, WRONG_DOUBT_SUBSCRIPT))

VARIANTS["P02"] = ("comes-from-wrong-subscript", WRONG_COMES_FROM_SUBSCRIPT)
VARIANTS["P02S16"] = ("comes-from-blind-to-a-cancel",
                      chain(VARIANTS["S16"][1], WRONG_COMES_FROM_SUBSCRIPT))

VARIANTS["P03"] = ("only-grows-wrong-subscript", WRONG_GROWS_SUBSCRIPT)
VARIANTS["P03S11"] = ("only-grows-blind-to-a-replacement",
                      chain(VARIANTS["S11"][1], WRONG_GROWS_SUBSCRIPT))

VARIANTS["P04"] = ("fairness-single-existential", sub(
    FAIRNESS, r"    /\ WF_vars(\E b \in Botanists, s \in Sheets : FileStep(b, s))"))

VARIANTS["P05"] = ("fairness-per-botanist", sub(
    FAIRNESS, r"    /\ \A b \in Botanists : WF_vars(\E s \in Sheets : FileStep(b, s))"))

VARIANTS["P06"] = ("fairness-on-next", sub(FAIRNESS, r"    /\ WF_vars(Next)"))


def main():
    with open(REF_TLA) as fh:
        reference = fh.read()
    with open(REF_CFG) as fh:
        cfg = fh.read()

    with open(os.path.join(HERE, "variant.cfg"), "w") as fh:
        fh.write(cfg)

    for vid in sorted(VARIANTS):
        name, mutate = VARIANTS[vid]
        text = mutate(reference)
        text = text.replace("MODULE Herbarium", "MODULE " + vid, 1)
        marker = "EXTENDS Naturals\n"
        header = "\n\\* Variant %s (%s) of the herbarium-sheet reference.\n" % (vid, name)
        text = text.replace(marker, marker + header, 1)
        with open(os.path.join(HERE, vid + ".tla"), "w") as fh:
            fh.write(text)
        print("wrote %s.tla  %s" % (vid, name))

    print("%d variants, one shared config at variant.cfg" % len(VARIANTS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
