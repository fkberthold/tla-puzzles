#!/usr/bin/env python3
# Render a verdict.sh --trace JSON as a markdown table over the OBSERVATION
# fields only: today, custodian (days 1..14), pending per parent. Internal
# variable names and reference action names never reach the output; the
# narrative column speaks participant language.
import json
import pathlib
import sys


def repo_root():
    p = pathlib.Path(__file__).resolve().parent
    while not (p / "authoring" / "custody" / "reference" / "Custody.tla").exists():
        if p == p.parent:
            sys.exit("no repo root above this script")
        p = p.parent
    return p


ROOT = repo_root() / "tmp-variants"

BASE = {d: ("A" if d <= 7 else "B") for d in range(1, 15)}
HOL = {4: "B", 11: "A"}


def sched(d):
    return HOL.get(d, BASE[d])


def other(p):
    return "B" if p == "A" else "A"


def custody_string(swapped, nobody_on_swap=False):
    out = []
    for d in range(1, 15):
        if d in swapped:
            out.append("-" if nobody_on_swap else other(sched(d)))
        else:
            out.append(sched(d))
        if d == 7:
            out.append(" ")
    return "".join(out)


def pend(v):
    return "none" if v == 0 else f"day {v}"


def narrate(act, pre):
    name = act["name"]
    ctx = act.get("context", {})
    if name == "BeginDay":
        return f"day {pre['today'] + 1} begins"
    if name == "Propose":
        return f"{ctx['p']} proposes the swap of day {ctx['d']}"
    if name == "Accept":
        d = pre["pending"][ctx["p"]]
        return f"the swap of day {d} is agreed"
    if name == "Drop":
        d = pre["pending"][ctx["p"]]
        return f"{ctx['p']}'s proposal of day {d} is withdrawn or declined"
    return f"[{name} {ctx}]"


def render(path, nobody_on_swap=False):
    data = json.loads(path.read_text())
    cex = data["counterexample"]
    states = cex["state"]
    actions = {a[0][0]: a[1] for a in cex.get("action", [])}
    rows = []
    rows.append("| # | today | custody, days 1-14 | A proposes | B proposes | step |")
    rows.append("|---|---|---|---|---|---|")
    prev = None
    for idx, st in states:
        t = st["today"]
        tt = "none yet" if t == 0 else str(t)
        cs = custody_string(set(st["swapped"]), nobody_on_swap)
        pa = pend(st["pending"]["A"])
        pb = pend(st["pending"]["B"])
        if idx == 1:
            note = "the window opens"
        else:
            act = actions.get(idx - 1)
            note = narrate(act, prev) if act else ""
        rows.append(f"| {idx} | {tt} | `{cs}` | {pa} | {pb} | {note} |")
        prev = st
    return "\n".join(rows)


if __name__ == "__main__":
    for name in sys.argv[1:]:
        p = ROOT / name / "trace.json"
        print(f"==== {name} ====")
        print(render(p, nobody_on_swap=(name == "v07")))
        print()
