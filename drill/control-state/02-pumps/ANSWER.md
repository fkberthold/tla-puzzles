# 02 pumps: answer

No control variable. A pump is its two switches, and the handbook's
ordering is already a guard on them. Anything that records "where in the
procedure" on top of the switches records a fact the switches already hold,
and pays for it in states.

## The answer: switches and guards

`verify/Switches.tla`.

```tla
EXTENDS Naturals, FiniteSets
CONSTANTS Pumps, Budget

VARIABLES inlet, motor
vars == <<inlet, motor>>

Running == {p \in Pumps : motor[p]}

Init == /\ inlet = [p \in Pumps |-> FALSE]
        /\ motor = [p \in Pumps |-> FALSE]

OpenInlet(p) == /\ ~inlet[p]
                /\ inlet' = [inlet EXCEPT ![p] = TRUE]
                /\ UNCHANGED motor

StartMotor(p) == /\ inlet[p]
                 /\ ~motor[p]
                 /\ Cardinality(Running) < Budget
                 /\ motor' = [motor EXCEPT ![p] = TRUE]
                 /\ UNCHANGED inlet

StopMotor(p) == /\ motor[p]
                /\ motor' = [motor EXCEPT ![p] = FALSE]
                /\ UNCHANGED inlet

CloseInlet(p) == /\ inlet[p]
                 /\ ~motor[p]
                 /\ inlet' = [inlet EXCEPT ![p] = FALSE]
                 /\ UNCHANGED motor

Next == \E p \in Pumps :
          OpenInlet(p) \/ StartMotor(p) \/ StopMotor(p) \/ CloseInlet(p)
Spec == Init /\ [][Next]_vars

NeverDry == \A p \in Pumps : motor[p] => inlet[p]
WithinBudget == Cardinality(Running) <= Budget
```

Config: `Pumps = {p1, p2, p3}`, `Budget = 2`, both invariants, deadlock
checking on (the machine never stops, and every state has a move).

**Measured: rc 0, 26 distinct states** (`verify-all.sh` row `02-Switches`,
where TLC printed "103 states generated, 26 distinct states found"). The hand count
agrees: three switch positions per pump that `NeverDry` allows, 3^3 = 27,
minus the one with all three motors running.

The two-sentence answer: the handbook's "then" is the guard `inlet[p]` on
`StartMotor` and the guard `~motor[p]` on `CloseInlet`, and the position of
the two switches is the only record of where in the procedure a pump is.
Nothing else about a pump needed recording, because a pump with its inlet
open and its motor off is the same pump whether the operator is on the way
up or on the way down.

## The neighbour answer: a label per pump

`verify/Phases.tla`. The handbook reads as four steps, so the first
instinct after a year of PlusCal is four labels. `Offline`, `GoingUp`,
`Online`, `GoingDown`, with the switches alongside. Every guard that was on
a switch moves onto the label.

```tla
OpenInlet(p) == /\ pc[p] = Offline
                /\ pc' = [pc EXCEPT ![p] = GoingUp]
                /\ inlet' = [inlet EXCEPT ![p] = TRUE]
                /\ UNCHANGED motor

StartMotor(p) == /\ pc[p] \in {GoingUp, GoingDown}
                 /\ Cardinality(Running) < Budget
                 /\ pc' = [pc EXCEPT ![p] = Online]
                 /\ motor' = [motor EXCEPT ![p] = TRUE]
                 /\ UNCHANGED inlet
```

and so on. It admits every row of the prompt's table, both rules hold, and
**measured: rc 0, 63 distinct states** (`verify-all.sh` row `02-Phases`,
where TLC printed "280 states generated, 63 distinct states found"). Hand count:
4 labels per pump, 4^3 =
64, minus the one with all three `Online`.

## Both encodings, side by side

| encoding | per-pump states | ceiling | reachable | rc | verdict |
|---|---|---|---|---|---|
| switches only | 3 | 3^3 = 27 | 26 | 0 | both hold |
| label per pump | 4 | 4^3 = 64 | 63 | 0 | both hold |

Same verdict, 2.4 times the states. The cost law is labels raised to the
number of processes, times the data. The coordinator's research round
measured it at 12, 48 and 192 states for 1, 2 and 3 processes of a 4-label
algorithm over 3 data values (relayed in the brief correction. Not a run of
mine). Here the data *is* the labels, so the multiplier is simply 4 against
3 per pump, and it compounds across the three pumps.

Where does the extra state come from? `GoingUp` and `GoingDown` are the
same switch positions. The label remembers which way the operator was
heading, and no rule in the handbook cares. That is the signature of a
`pc` that buys nothing: two labels with identical data under them, and no
property that can tell them apart.

The test to apply before writing a control variable: can every guard be
stated on the data? Here, yes. When the answer is no, which is item 06, the
label is carrying history the data does not, and it earns its place.

## Acceptable variants

- **One function of records**, `pump \in [Pumps -> [inlet: BOOLEAN,
  motor: BOOLEAN]]`. Same 26 states, same verdicts. A matter of taste.
- **A `Phase(p)` operator that derives the label** from the switches, for
  readability in traces, without storing it. This is the honest version of
  the neighbour: it gives you the handbook's words in the trace at no
  cost in states.
- **Two pumps instead of three.** 8 states against 15. The lesson is the
  same, but with three pumps the budget rule has something to do.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| one site-wide position in the procedure (the operator does one pump at a time) | row 2: two pumps mid-start at once. A single label cannot hold both. |
| a strict four-step cycle per pump, `Offline -> GoingUp -> Online -> GoingDown -> Offline` | row 3: open then close with no start. The cycle has no edge from `GoingUp` back to `Offline`. Row 4 kills it a second time: no edge from `GoingDown` to `Online`. |
| a label per pump with the backward edges added (`Phases.tla`) | not killed by the table, and TLC passes it. Killed only by the state count and by the question at the end of the prompt. 63 against 26 for the same verdicts. |
| switches only, but `CloseInlet` without the `~motor[p]` guard | `NeverDry` fails, rc 12 (INFERRED from the guard's role, not run). The handbook's "stop the motor, then close the inlet" is this guard. |
| switches only, but `StartMotor` without the budget guard | `WithinBudget` fails, rc 12 (INFERRED, not run). |

## why-not-in-prompt

The prompt shows no TLA+. Its honest caveat is the last paragraph: asking
"what records where in the procedure each pump is" and "whether anything
needed recording beyond the switches" points straight at the answer being
"nothing", and a reader who has met the question before will skip the
label-per-pump detour entirely. Without that paragraph the item has no
foreclosing content against `Phases.tla`, which TLC passes, so the
question has to be asked somewhere. It is asked after the model is
written, so he has already chosen by the time he reads it.

The table's rows 3 and 4 are there to kill the strict cycle, and they
read as "the procedure is not really a sequence", which is the lesson
stated sideways.
