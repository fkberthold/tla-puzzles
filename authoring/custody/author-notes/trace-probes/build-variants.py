#!/usr/bin/env python3
# Rebuild the step-4 trace-source variants from the frozen "Exact mutations"
# section of authoring/custody/reports/step2-variants.md. Each swap must match
# exactly once, or the build refuses. A mutation that quietly did nothing
# would make its trace meaningless.
import pathlib
import shutil
import sys


def repo_root():
    p = pathlib.Path(__file__).resolve().parent
    while not (p / "authoring" / "custody" / "reference" / "Custody.tla").exists():
        if p == p.parent:
            sys.exit("no repo root above this script")
        p = p.parent
    return p


ROOT = repo_root()
REF = ROOT / "authoring" / "custody" / "reference"
OUT = ROOT / "tmp-variants"

ENDCHURN = """EndChurn ==
    /\\ today = H
    /\\ Cardinality(swapped) < N
    /\\ 1 \\notin swapped
    /\\ swapped' = swapped \\cup {1}
    /\\ UNCHANGED <<today, pending>>

Next ==
    \\/ BeginDay
    \\/ EndChurn"""

UNILATERAL = """Unilateral(d) ==
    /\\ d > today
    /\\ d \\notin swapped
    /\\ Cardinality(swapped) < N
    /\\ \\A q \\in Parents : pending[q] # d
    /\\ swapped' = swapped \\cup {d}
    /\\ UNCHANGED <<today, pending>>

Next ==
    \\/ BeginDay
    \\/ \\E d \\in Days : Unilateral(d)"""

UNSWAP = """Unswap(d) ==
    /\\ d \\in swapped
    /\\ d > today
    /\\ swapped' = swapped \\ {d}
    /\\ UNCHANGED <<today, pending>>

Next ==
    \\/ BeginDay
    \\/ \\E d \\in Days : Unswap(d)"""

NEXT_ANCHOR = "Next ==\n    \\/ BeginDay"

VARIANTS = {
    "v02": [
        ("/\\ today < H", "/\\ today + 2 <= H"),
        ("/\\ today' = today + 1", "/\\ today' = today + 2"),
        ("IF pending[p] = today + 1", "IF pending[p] <= today + 2"),
    ],
    "v05": [
        ("Spec == Init /\\ [][Next]_vars /\\ WF_vars(BeginDay)",
         "Spec == Init /\\ [][Next]_vars"),
    ],
    "v06": [(NEXT_ANCHOR, ENDCHURN)],
    "v07": [
        ("Custodian(d) == IF d \\in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)",
         "Custodian(d) == IF d \\in swapped THEN NoDay ELSE Scheduled(d)"),
    ],
    "v09": [("/\\ swapped = {}", "/\\ swapped = {1}")],
    "v13": [(NEXT_ANCHOR, UNILATERAL)],
    "v14": [("/\\ d > today", "/\\ d >= today")],
    "v16": [("    /\\ pending[p] = NoDay\n", "")],
    "v23": [(NEXT_ANCHOR, UNSWAP)],
    "v24": [
        ("/\\ Cardinality(swapped) < N\n    /\\ swapped' = swapped \\cup {pending[p]}",
         "/\\ Cardinality(swapped) <= N\n    /\\ swapped' = swapped \\cup {pending[p]}"),
    ],
}

src = (REF / "Custody.tla").read_text()
for name, swaps in VARIANTS.items():
    text = src
    for old, new in swaps:
        n = text.count(old)
        if n != 1:
            sys.exit(f"{name}: anchor matched {n} times, want 1: {old!r}")
        text = text.replace(old, new)
    d = OUT / name
    d.mkdir(parents=True, exist_ok=True)
    (d / "Custody.tla").write_text(text)
    shutil.copy(REF / "MCCustody.tla", d / "MCCustody.tla")
    shutil.copy(REF / "MCCustody.cfg", d / "MCCustody.cfg")
    print(f"{name}: built")
print("all variants built")
