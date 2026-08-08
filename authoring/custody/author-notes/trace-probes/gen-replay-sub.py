#!/usr/bin/env python3
# Generate the ReplaySubmission R-probe: a "submission" that is a pure
# transcription of the published satisfying trace, with no Next behind it.
import pathlib
import sys


def repo_root():
    p = pathlib.Path(__file__).resolve().parent
    while not (p / "authoring" / "custody" / "reference" / "Custody.tla").exists():
        if p == p.parent:
            sys.exit("no repo root above this script")
        p = p.parent
    return p


import shutil

root = repo_root() / "tmp-variants" / "replay-sub"
root.mkdir(parents=True, exist_ok=True)
ref = repo_root() / "authoring" / "custody" / "reference"
shutil.copy(ref / "Custody.tla", root / "Custody.tla")
shutil.copy(ref / "MCCustody.tla", root / "MCCustody.tla")
t = (pathlib.Path(__file__).resolve().parent / "TraceReplay.tla").read_text()
start = t.index("T == <<")
end = t.index(">>", start) + 2
tdef = t[start:end]

module = f"""------------------------- MODULE ReplaySubmission -------------------------
(* Author-side R-probe: a "submission" that is a pure 24-step transcription  *)
(* of the published satisfying trace. NO reference to Next: it replays the   *)
(* states as a deterministic script. Measures whether the shipped gate       *)
(* (13 obligations + 3 witness probes) refuses a model with no modeling in   *)
(* it. Obligations run: rc=0 means the gate cannot. Probes: rc=12 means the  *)
(* transcription passes the probe too.                                       *)
EXTENDS MCCustody, Sequences

VARIABLE i

{tdef}

St(k) == [p \\in Parents |-> IF p = A THEN T[k].pa ELSE T[k].pb]

SInit ==
    /\\ i = 1
    /\\ today = T[1].t
    /\\ swapped = T[1].sw
    /\\ pending = St(1)

SNext ==
    /\\ i < Len(T)
    /\\ i' = i + 1
    /\\ today' = T[i + 1].t
    /\\ swapped' = T[i + 1].sw
    /\\ pending' = St(i + 1)

SSpec == SInit /\\ [][SNext]_<<vars, i>> /\\ WF_<<vars, i>>(SNext)

CapNotReached ==
    Cardinality({{d \\in Days : Observe.custodian[d] # Sched(d)}}) < N

AKeepsEveryScheduledDay ==
    \\A d \\in Days : Sched(d) = A => Observe.custodian[d] = A

BKeepsEveryScheduledDay ==
    \\A d \\in Days : Sched(d) = B => Observe.custodian[d] = B

===========================================================================
"""
(root / "ReplaySubmission.tla").write_text(module)

consts = """CONSTANTS
    A = A
    B = B
    H = 14
    N = 2
    Base <- MCBase
    Hol <- MCHol
    Sched <- MCSched
"""
(root / "obligations.cfg").write_text(
    "SPECIFICATION SSpec\n" + consts + """INVARIANTS
    TypeOK
    TotalCustody
    PendingFresh
    CapRespected
PROPERTIES
    OpeningBaseline
    OpeningNoDayBegun
    FlipOnce
    FlipCause
    PastFixed
    OneOutstanding
    QuietAtEnd
    TodayMarches
    WindowCompletes
""")
for name, inv in [("cap", "CapNotReached"),
                  ("flipa", "AKeepsEveryScheduledDay"),
                  ("flipb", "BKeepsEveryScheduledDay")]:
    (root / f"{name}.cfg").write_text(
        "SPECIFICATION SSpec\n" + consts + f"INVARIANT {inv}\n")
print("written")
