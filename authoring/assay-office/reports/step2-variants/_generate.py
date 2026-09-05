#!/usr/bin/env python3
"""Materialise the frozen step 2 variant set for authoring/assay-office.

Every variant is stated here as a replacement against the reference PlusCal
text, so this file IS the diff the report's matrix describes. Run it from the
worktree root:

    python3 authoring/assay-office/reports/step2-variants/_generate.py

It writes <id>.tla and <id>.cfg beside itself and then runs the pinned PlusCal
translator over each module that carries an algorithm, so the TLA+ TLC reads is
a real translation rather than a hand-edited one.

The reference under authoring/assay-office/reference/ is read and never
written.
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
REF_DIR = os.path.join(ROOT, "authoring", "assay-office", "reference")
REF_TLA = os.path.join(REF_DIR, "AssayOffice.tla")
REF_CFG = os.path.join(REF_DIR, "AssayOffice.cfg")

# ---------------------------------------------------------------- base text

with open(REF_TLA) as fh:
    REF_LINES = fh.read().split("\n")

# lines 1..60 are the header plus the whole PlusCal algorithm block, and
# lines 118..128 are everything after END TRANSLATION. The translation between
# them is regenerated, never carried.
HEAD = "\n".join(REF_LINES[0:60])
TAIL = "\n".join(REF_LINES[117:])
BASE = HEAD + "\n\\* BEGIN TRANSLATION\n\\* END TRANSLATION\n" + TAIL

with open(REF_CFG) as fh:
    BASE_CFG = fh.read()

# ------------------------------------------------------------- text anchors

INIT = '''    book = [w \\in Wares |->
                [verdict |-> "none", struck |-> FALSE, damaged |-> FALSE]];'''

TEST_BRANCH = '''            await book[w].verdict = "none";
            with (f \\in Findings \\ {"none"}) {
              book[w].verdict := f;
            };'''

STRIKE_BRANCH = '''            await book[w].verdict = "atStandard";
            await ~book[w].struck;
            book[w].struck := TRUE;'''

DEFACE_BRANCH = '''            await book[w].verdict = "substandard";
            await ~book[w].damaged;
            book[w].damaged := TRUE;'''

DEFACE_TAIL = '''          } or {
            await book[w].verdict = "substandard";
            await ~book[w].damaged;
            book[w].damaged := TRUE;
          };'''

FAIR_CONJUNCT = "    /\\ \\A o \\in Officers, w \\in Wares : WF_vars(Deface(o, w))"

DEFACE_OP = '''Deface(o, w) ==
    /\\ book[w].verdict = "substandard"
    /\\ ~book[w].damaged
    /\\ book' = [book EXCEPT ![w].damaged = TRUE]'''

DEFINE_OPEN = "  define {\n"


def branch(body):
    return "          } or {\n" + body + "\n"


# ------------------------------------------------------------ the S family

S = {}

S["S01"] = [(STRIKE_BRANCH, '''            await ~book[w].struck;
            book[w].struck := TRUE;''')]

S["S02"] = [(DEFACE_BRANCH, '''            await book[w].verdict # "none";
            await ~book[w].damaged;
            book[w].damaged := TRUE;''')]

S["S03"] = [(STRIKE_BRANCH, '''            await book[w].verdict = "substandard";
            await ~book[w].struck;
            book[w].struck := TRUE;''')]

S["S04"] = [(TEST_BRANCH, '''            with (f \\in Findings \\ {"none"}) {
              book[w].verdict := f;
            };''')]

S["S05"] = [(DEFACE_TAIL, branch(DEFACE_BRANCH.rstrip("\n")) + branch(
    '''            await book[w].verdict = "atStandard";
            await ~book[w].struck;
            book[w].verdict := "none";''') + "          };")]

S["S06"] = [(DEFACE_TAIL, branch(DEFACE_BRANCH) + branch(
    '''            await book[w].struck;
            book[w].struck := FALSE;''') + "          };")]

S["S07"] = [(DEFACE_TAIL, branch(DEFACE_BRANCH) + branch(
    '''            await book[w].damaged;
            book[w].damaged := FALSE;''') + "          };")]

S["S08"] = [(DEFACE_TAIL, "          };")]

S["S09"] = [(FAIR_CONJUNCT,
             "    /\\ \\A o \\in Officers : WF_vars(Deface(o, CHOOSE w \\in Wares : TRUE))")]

S["S10"] = [
    (INIT, INIT + '\n    holder = [w \\in Wares |-> "free"];'),
    (TEST_BRANCH, '''            await holder[w] = "free";
            holder[w] := self;
          } or {
            await holder[w] = self;
            holder[w] := "free";
          } or {''' + "\n" + TEST_BRANCH),
    (DEFACE_BRANCH, '''            await holder[w] = self;''' + "\n" + DEFACE_BRANCH),
    (DEFACE_OP, '''Deface(o, w) ==
    /\\ holder[w] = o
    /\\ book[w].verdict = "substandard"
    /\\ ~book[w].damaged
    /\\ book' = [book EXCEPT ![w].damaged = TRUE]
    /\\ UNCHANGED holder'''),
]

S["S11"] = [(INIT, INIT.replace('verdict |-> "none"', 'verdict |-> "atStandard"'))]
S["S12"] = [(INIT, INIT.replace("struck |-> FALSE", "struck |-> TRUE"))]
S["S13"] = [(INIT, INIT.replace("damaged |-> FALSE", "damaged |-> TRUE"))]
S["S14"] = [(INIT, INIT.replace('verdict |-> "none"', 'verdict |-> "substandard"'))]

S["S15"] = [
    (TEST_BRANCH, '''            await book[w].verdict = "none";
            book[w].verdict := "atStandard";
          } or {
            await book[w].verdict = "none";
            book := [book EXCEPT ![w].verdict = "substandard",
                                 ![w].damaged = TRUE];'''),
    (DEFACE_TAIL, "          };"),
    (FAIR_CONJUNCT, "    /\\ TRUE"),
]

S["S16"] = [
    (TEST_BRANCH, '''            await book[w].verdict = "none";
            book := [book EXCEPT ![w].verdict = "atStandard",
                                 ![w].struck = TRUE];
          } or {
            await book[w].verdict = "none";
            book[w].verdict := "substandard";'''),
    (STRIKE_BRANCH + "\n          } or {\n", ""),
]

S["S17"] = [
    (INIT, INIT.replace("damaged |-> FALSE]", "damaged |-> FALSE, gone |-> FALSE]")),
    (DEFACE_TAIL, branch(DEFACE_BRANCH) + branch(
        '''            await ~book[w].gone;
            book[w].gone := TRUE;''') + "          };"),
]

S["S18"] = [
    (INIT, INIT + "\n    lodged = {};"),
    (TEST_BRANCH, '''            await w \\notin lodged;
            lodged := lodged \\union {w};
          } or {
            await w \\in lodged;''' + "\n" + TEST_BRANCH),
    (STRIKE_BRANCH, "            await w \\in lodged;\n" + STRIKE_BRANCH),
    (DEFACE_BRANCH, "            await w \\in lodged;\n" + DEFACE_BRANCH),
    (DEFACE_OP, '''Deface(o, w) ==
    /\\ w \\in lodged
    /\\ book[w].verdict = "substandard"
    /\\ ~book[w].damaged
    /\\ book' = [book EXCEPT ![w].damaged = TRUE]
    /\\ UNCHANGED lodged'''),
]

S["S19"] = [('Findings == {"none", "atStandard", "substandard"}',
             'Findings == {"none", "atStandard", "substandard", "britannia"}')]

S["S20"] = [(DEFACE_BRANCH,
             "            await self = CHOOSE o \\in Officers : TRUE;\n" + DEFACE_BRANCH)]

S["S21"] = [
    (DEFINE_OPEN, DEFINE_OPEN + '''    Pending(x) ==
        \\/ (book[x].verdict = "atStandard" /\\ ~book[x].struck)
        \\/ (book[x].verdict = "substandard" /\\ ~book[x].damaged)

'''),
    (TEST_BRANCH, "            await \\A x \\in Wares : ~Pending(x);\n" + TEST_BRANCH),
]

S["S22"] = [
    (DEFACE_OP, DEFACE_OP + '''

Test(o, w) ==
    /\\ book[w].verdict = "none"
    /\\ \\E f \\in Findings \\ {"none"} : book' = [book EXCEPT ![w].verdict = f]'''),
    (FAIR_CONJUNCT, FAIR_CONJUNCT +
     "\n    /\\ \\A o \\in Officers, w \\in Wares : WF_vars(Test(o, w))"),
]

# --------------------------------------------- the P family, fairness forms

S["P03"] = [(FAIR_CONJUNCT, "    /\\ TRUE")]
S["P04"] = [(FAIR_CONJUNCT, "    /\\ WF_vars(Next)")]
S["P05"] = [(FAIR_CONJUNCT, "    /\\ \\A o \\in Officers : WF_vars(officer(o))")]

# --------------------------------- the P family, property mutations by name
#
# These are small modules that EXTEND the system they probe, so the system
# text is shared with whatever they extend rather than copied.

GROWS_BODY = '''    [][\\A w \\in Wares :
          /\\ (Observe.finding[w] # "none")
                 => (Observe'.finding[w] = Observe.finding[w])
          /\\ Observe.marked[w] => Observe'.marked[w]
          /\\ Observe.defaced[w] => Observe'.defaced[w]]_%s'''

EXT = {
    "P01":    ("AssayOffice", "GrowsSub ==\n" + GROWS_BODY % "(Observe.finding)"),
    "P01S06": ("S06", "GrowsSub ==\n" + GROWS_BODY % "(Observe.finding)"),
    "P02":    ("AssayOffice", "GrowsSub ==\n" + GROWS_BODY % "(Observe.marked)"),
    "P02S05": ("S05", "GrowsSub ==\n" + GROWS_BODY % "(Observe.marked)"),
    "P06":    ("AssayOffice", 'MarksOneSided ==\n'
               '    \\A w \\in Wares :\n'
               '        Observe.marked[w] => Observe.finding[w] = "atStandard"'),
    "P06S02": ("S02", 'MarksOneSided ==\n'
               '    \\A w \\in Wares :\n'
               '        Observe.marked[w] => Observe.finding[w] = "atStandard"'),
}

EXT_CFG = {
    "P01": "GrowsSub", "P01S06": "GrowsSub",
    "P02": "GrowsSub", "P02S05": "GrowsSub",
}
EXT_INV_CFG = {"P06": "MarksOneSided", "P06S02": "MarksOneSided"}


# --------------------------------------------------------------- materialise

def apply(name, edits):
    text = BASE.replace("MODULE AssayOffice", "MODULE " + name)
    for old, new in edits:
        if old not in text:
            sys.exit("variant %s: anchor not found:\n%s" % (name, old))
        text = text.replace(old, new, 1)
    return text


def write(path, text):
    with open(path, "w") as fh:
        fh.write(text)


made = []
for name in sorted(S):
    path = os.path.join(HERE, name + ".tla")
    write(path, apply(name, S[name]))
    write(os.path.join(HERE, name + ".cfg"), BASE_CFG)
    made.append(name)

for name, (base, defn) in sorted(EXT.items()):
    body = ("---------------------------- MODULE %s ----------------------------\n"
            "EXTENDS %s\n\n%s\n\n"
            "=============================================================================\n"
            % (name, base, defn))
    write(os.path.join(HERE, name + ".tla"), body)
    cfg = BASE_CFG
    if name in EXT_CFG:
        cfg = cfg.replace("    TheRecordOnlyGrows", "    " + EXT_CFG[name])
    if name in EXT_INV_CFG:
        cfg = cfg.replace("    MarksFollowTheFinding", "    " + EXT_INV_CFG[name])
    write(os.path.join(HERE, name + ".cfg"), cfg)

# Translate every module that carries an algorithm.
fails = []
for name in made:
    path = os.path.join(HERE, name + ".tla")
    r = subprocess.run(["tlc", "-pcal", path], capture_output=True, text=True)
    if r.returncode != 0:
        fails.append((name, r.stdout[-900:] + r.stderr[-900:]))
    old = path[:-4] + ".old"
    if os.path.exists(old):
        os.remove(old)

for name, msg in fails:
    print("TRANSLATE FAILED %s\n%s\n" % (name, msg))
print("modules written: %d, translate failures: %d" % (len(made) + len(EXT), len(fails)))
