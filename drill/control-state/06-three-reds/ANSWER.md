# 06 three-reds: answer

One technician, so the control state is a scalar label, and the procedure
has a loop and a branch, so the label is the thing PlusCal's `while` and
`if` would have hidden. The count of reds cannot stand in for it: the
count is 0 at the start, while waiting, and while watching the first
boot, and those are three different places in the procedure.

## The spec

`verify/Reboot.tla`.

```tla
EXTENDS Naturals
CONSTANTS Start, Waiting, Booting, Fixed, Escalated     \* labels

VARIABLES pc, reds
vars == <<pc, reds>>

Init == /\ pc = Start
        /\ reds = 0

CutPower == /\ pc = Start
            /\ pc' = Waiting
            /\ UNCHANGED reds

PowerUp == /\ pc = Waiting
           /\ pc' = Booting
           /\ UNCHANGED reds

SeeGreen == /\ pc = Booting
            /\ pc' = Fixed
            /\ UNCHANGED reds

SeeRed == /\ pc = Booting
          /\ reds' = reds + 1
          /\ pc' = IF reds' = 3 THEN Escalated ELSE Start

Terminating == /\ pc \in {Fixed, Escalated}
               /\ UNCHANGED vars

Work == CutPower \/ PowerUp \/ SeeGreen \/ SeeRed
Next == Work \/ Terminating
Spec == Init /\ [][Next]_vars

AtMostThreeReds == reds <= 3
ThreeRedsExactly == (pc = Escalated) <=> (reds = 3)
HandsOff == [][pc = Escalated => pc' = Escalated]_vars
```

Config: labels as model values, the two invariants, `HandsOff` as a
`PROPERTY`. **Measured: rc 0, 13 distinct states** (`verify-all.sh` row
`06-Reboot`).

Three things worth saying about what is not there.

**Amber has no action.** "Still booting, keep watching" changes nothing,
and a step that changes nothing is a stuttering step, which `[][Next]_vars`
already admits. The fourth row of the table is satisfied by a spec that
never mentions amber.

**The loop is `pc' = Start`.** PlusCal's `while` is a label you jump back
to. Raw TLA+ has no jump. The action that sees a red sets the label to the
one `CutPower` is guarded on, and the loop is closed.

**The branch is in the update, not in two actions.** `SeeRed` decides
between `Escalated` and `Start` with an `IF` on the primed count. Two
actions, `SeeThirdRed` and `SeeEarlyRed`, guarded on `reds = 2` and `reds <
2`, is the other acceptable shape, below.

The two-sentence answer: the label `pc` records which step the technician
is on, with five values for the five places the procedure can be. The
count of reds could not stand in for it, because `reds = 0` holds at
`Start`, at `Waiting` and at `Booting` alike, and the procedure allows
different next steps at each.

## The two ends

Both `Fixed` and `Escalated` are terminal. Without the `Terminating`
disjunct (`verify/EndsBare.cfg`, which checks `BareSpec == Init /\
[][Work]_vars`): **rc 11, deadlock reached, 5 distinct states**
(`verify-all.sh` row `06-EndsBare`). The trace is the first row of the
table, four states ending at `pc = Fixed`, reported as a fault.

With `CHECK_DEADLOCK FALSE` instead of the disjunct (`verify/EndsNoDL.cfg`):
**rc 0, 13 distinct states** (row `06-EndsNoDL`). Same verdict as the
disjunct here, because this procedure has no stuck state that is not an
intended end. Item 03 is the case where the two differ.

Note the state counts: 13 with `Terminating`, 13 with the config switch.
The disjunct adds a self-loop at the two end states, which generates
states TLC has already seen (17 generated against 13), and no new ones.

## The off-by-one neighbour

`verify/OffByOne.tla` tests the count before bumping it:

```tla
SeeRed == /\ pc = Booting
          /\ reds' = reds + 1
          /\ pc' = IF reds = 3 THEN Escalated ELSE Start     \* the slip
```

**Measured: rc 12, `ThreeRedsExactly` violated, 13 distinct states** (row
`06-OffByOne`). The trace runs ten states: three full power cycles, three
reds, and in state 10 `reds = 3` with `pc = Start`, which is a fourth
power cycle about to begin. The third row of the prompt's table together
with "never a fourth power cycle" is what forecloses it. `AtMostThreeReds`
would have caught it one cycle later. `ThreeRedsExactly` catches it in the
state where the decision was made, which is why the rule is stated as an
equivalence and not as an implication.

## Acceptable variants

- **Two actions for the branch**, `SeeEarlyRed` guarded on `reds < 2` and
  `SeeThirdRed` on `reds = 2`. Same verdicts (INFERRED, the two shapes are
  the same action split on the value of `reds`).
- **A `cycles` counter instead of `reds`**, bumped in `CutPower`. Then
  "never a fourth power cycle" is `cycles <= 3` and escalation is `cycles
  = 3 /\ red`. Same verdicts (INFERRED). It records the same history one
  step earlier.
- **`HandsOff` as an invariant** cannot be done. "never touches it again"
  is about steps, not states. The action property `[][...]_vars` is the
  shape, and it is the one place in this family where the box-action
  subscript is a `PROPERTY` rather than the spec.
- **`CHECK_DEADLOCK FALSE`** in place of the disjunct. Measured
  equivalent here.
- **Strings for labels.** Measured clean during authoring on a scratch
  probe (rc 0).

## Elimination table

| neighbour answer | what kills it |
|---|---|
| test-before-bump (`OffByOne.tla`) | rc 12, `ThreeRedsExactly` at state 10. Row 3 plus rule 1. |
| escalate when `reds` reaches 3 at `CutPower` | not killed by the table. It is the `cycles` variant with a different name and is acceptable (INFERRED). |
| no `Terminating` and no config switch | rc 11 on `pc = Fixed`, measured. An intended end reported as a fault. |
| an `Amber` action that moves the label somewhere | adds states for a step that changes nothing. Not wrong. The item 02 cost for no information. |
| `reds` as the only state, `pc` derived from it | cannot be done. `reds = 1` is both "about to cut the power" and "watching the second boot". The closing question asks for this. |
| `HandsOff` written as `pc = Escalated => UNCHANGED vars` in an invariant | parse error, rc 150 (INFERRED): primed variables in an invariant. The property is about steps. |

## why-not-in-prompt

The prompt shows no TLA+. The caveat is the closing question, "what
records which step the technician is on, and whether the count of reds
could have stood in for it", which says there is a thing recording the
step and that it is not the count. A reader who takes that in before
writing will reach for a label without the detour. The bullet list of
light colours with "keep watching" for amber is also a hint that amber is
a non-step, since it is the only outcome with no instruction attached.
The table's third row carries "and nothing happens after", which is the
`HandsOff` rule stated as a behaviour and a nudge toward an action
property.

## Measured runs

Every row is a line of `drill/control-state/verify-all.sh`. One config per
module, run with one worker, no trace spillage. `EndsBare` and `EndsNoDL`
are one-line `EXTENDS` wrappers so that each config has a module of its own.

| module | config | rc | distinct states |
|---|---|---|---|
| EndsBare.tla | EndsBare.cfg | rc 11 | 5 |
| EndsNoDL.tla | EndsNoDL.cfg | rc 0 | 13 |
| OffByOne.tla | OffByOne.cfg | rc 12 | 13 |
| Reboot.tla | Reboot.cfg | rc 0 | 13 |
