# 01 slip-on-the-spike: answer

The whole content is where the control point goes. Seeing the slip and
taking it are two steps in the warehouse as described, so there is a state
in which a picker has seen it and not yet taken it, and that state is where
the rule dies. The supervisor's change makes them one step, and the state
disappears.

## The faithful encoding: two steps

`verify/TwoStep.tla`. Each picker's control state is a label, and the
function from picker to label is the hand-rolled `pc`.

```tla
CONSTANTS Pickers,
          Idle, Fetching, Done,       \* labels
          OnSpike, Taken              \* where the slip is

VARIABLES pc, slip
vars == <<pc, slip>>

Init == /\ pc = [p \in Pickers |-> Idle]
        /\ slip = OnSpike

Glance(p) == /\ pc[p] = Idle
             /\ slip = OnSpike
             /\ pc' = [pc EXCEPT ![p] = Fetching]
             /\ UNCHANGED slip

Fetch(p) == /\ pc[p] = Fetching
            /\ pc' = [pc EXCEPT ![p] = Done]
            /\ slip' = Taken

Next == \E p \in Pickers : Glance(p) \/ Fetch(p)
Spec == Init /\ [][Next]_vars

PickedOnce == \A p, q \in Pickers :
                 pc[p] = Done /\ pc[q] = Done => p = q
```

The config names the labels as model values and switches deadlock checking
off, because the prompt says the end of the shift is intended and there is
no other stuck state in this model.

```
SPECIFICATION Spec
INVARIANT PickedOnce
CHECK_DEADLOCK FALSE
CONSTANTS
  Pickers = {p1, p2}
  Idle = Idle  Fetching = Fetching  Done = Done
  OnSpike = OnSpike  Taken = Taken
```

**Measured: rc 12, invariant `PickedOnce` violated, 9 distinct states**
(`verify-all.sh` row `01-TwoStep`, and TLC printed "10 states generated, 9
distinct states found"). The trace is the foreclosing row and one more
step each:

| state | action | p1 | p2 | slip |
|---|---|---|---|---|
| 1 | | Idle | Idle | OnSpike |
| 2 | Glance(p1) | Fetching | Idle | OnSpike |
| 3 | Glance(p2) | Fetching | Fetching | OnSpike |
| 4 | Fetch(p1) | Done | Fetching | Taken |
| 5 | Fetch(p2) | Done | Done | Taken |

State 3 is the third row of the prompt's table. Once it is reachable, the
rule cannot hold: nothing in `Fetch` looks at the spike, because the picker
already looked.

## The supervisor's change: one step

`verify/Atomic.tla`. Seeing and taking are one action, so there is no label
between them. Two labels instead of three.

```tla
CONSTANTS Pickers, Idle, Done, OnSpike, Taken

SeeAndTake(p) == /\ pc[p] = Idle
                 /\ slip = OnSpike
                 /\ pc' = [pc EXCEPT ![p] = Done]
                 /\ slip' = Taken

Next == \E p \in Pickers : SeeAndTake(p)
```

Same config minus `Fetching`. **Measured: rc 0, 3 distinct states**
(`verify-all.sh` row `01-Atomic`).

The one-sentence answer: the guard on the spike and the taking of the slip
moved into the same action, so there is no longer a state in which a picker
has checked the spike and not yet acted on it, and that state was the only
way to reach two pickers with the item.

## Both encodings, side by side

| encoding | labels | ceiling (labels^pickers x slip) | reachable | rc | verdict |
|---|---|---|---|---|---|
| two-step | 3 | 3^2 x 2 = 18 | 9 | 12 | `PickedOnce` violated at depth 4 |
| atomic | 2 | 2^2 x 2 = 8 | 3 | 0 | holds |

The ceiling column is the cost law for a hand-rolled `pc`: labels raised to
the number of processes, times the data states. The coordinator's research
round measured it on a 4-label algorithm with 3 data values at 12, 48 and
192 distinct states for 1, 2 and 3 processes (relayed in the brief
correction, not a run of mine). The two-step model reaches half its ceiling
and the atomic model a third of a much smaller one. The extra label is not
the expensive part. The extra label is the bug.

## Acceptable variants

- **Strings for labels.** `"Idle"`, `"Fetching"`, `"Done"` in place of the
  model-value constants. Measured clean during authoring on a two-process,
  two-label probe of the same shape (rc 0, 4 states, and the probe was scratch
  and is not kept). Every one of the 59
  translated modules in the published corpus does this, since the
  translator emits strings. Model values are the raw-TLA+ author's choice,
  not a requirement.
- **A `pulled` set instead of the `Done` label.** `pulled \subseteq Pickers`
  with `PickedOnce == Cardinality(pulled) <= 1`. Same verdicts. It records
  the same fact twice if `Done` is also kept, which is the item 02 lesson.
- **`Cardinality` form of the rule.** `Cardinality({p \in Pickers : pc[p] =
  Done}) <= 1` with `EXTENDS FiniteSets`. Equivalent.
- **A stuttering disjunct instead of `CHECK_DEADLOCK FALSE`.** `ShiftOver ==
  slip = Taken /\ UNCHANGED vars` disjoined into `Next`. Same verdicts. It
  says which stuck state is intended rather than silencing all of them.
  Here there is only one, so nothing is lost either way.
- **Three steps.** Glance, pull the item, take the slip. Also faithful to
  the prose, also rc 12, more states. The prompt's table does not force a
  third label and the answer does not need one.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| atomic encoding offered as the model of the aisle as described | row 3 of the prompt's table: both have seen it, neither has reached the shelf. Unreachable in the atomic model (3 states, none with two pickers past Idle). |
| two-step encoding where `Glance` has no guard on the spike | not killed by the table. The prose kills it: a picker who sees the spike empty "does nothing with it". Admits a picker walking to the shelf for nothing. Verdict is still rc 12, so TLC will not tell him. |
| two-step encoding where `Fetch` re-checks the spike | passes, rc 0, and is wrong. The picker is at the shelf with the slip out of sight. Re-checking is the supervisor's change in disguise, done before the supervisor proposed it. |
| scalar `pc` for the whole aisle | row 2 and row 3 need two pickers at different points at once. A single label cannot hold both. |

## why-not-in-prompt

The prompt shows no TLA+. What it does show is a behaviour table whose
third row names "seen" and "reached the shelf" as separable, which is most
of the hint that there are two steps with a control point between them.
That row is also the only thing that stops the atomic encoding being an
acceptable first answer, so it stays.

What the prompt does not give: that the control point is the whole reason
the rule fails, that the supervisor's change is the atomic encoding, and
the verdict under either. The sentence "that is the end of the shift, not
an error" hints at deadlock handling, which is a different lesson and had
to be defused somehow in a ten-minute item.
