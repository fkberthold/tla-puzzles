# 05 crane-and-riggers: answer

Three things record where someone is: one label per rigger and one for
the crane. Two kinds of process, two label sets, and either two variables
or one function over the union. The first row of the table is what makes
it three and not one.

## The answer: a variable per kind

`verify/Crane.tla`.

```tla
CONSTANTS Riggers,
          Idle, Hooked, Clear,       \* rigger labels
          Parked, Lifting            \* crane labels

VARIABLES rig, crane
vars == <<rig, crane>>

Init == /\ rig = [r \in Riggers |-> Idle]
        /\ crane = Parked

Hook(r) == /\ rig[r] = Idle
           /\ crane = Parked
           /\ rig' = [rig EXCEPT ![r] = Hooked]
           /\ UNCHANGED crane

StepBack(r) == /\ rig[r] = Hooked
               /\ rig' = [rig EXCEPT ![r] = Clear]
               /\ UNCHANGED crane

Return(r) == /\ rig[r] = Clear
             /\ crane = Parked
             /\ rig' = [rig EXCEPT ![r] = Idle]
             /\ UNCHANGED crane

Lift == /\ crane = Parked
        /\ \E r \in Riggers : rig[r] = Clear
        /\ \A r \in Riggers : rig[r] /= Hooked
        /\ crane' = Lifting
        /\ UNCHANGED rig

Park == /\ crane = Lifting
        /\ crane' = Parked
        /\ UNCHANGED rig

Next == \/ \E r \in Riggers : Hook(r) \/ StepBack(r) \/ Return(r)
        \/ Lift \/ Park

Spec == Init /\ [][Next]_vars

NobodyUnderTheHook == crane = Lifting => \A r \in Riggers : rig[r] /= Hooked
```

Config: `Riggers = {r1, r2}`, labels as model values, deadlock checking
on (the yard runs all day, and every state has a move). **Measured: rc 0, 12
distinct states** (`verify-all.sh` row `05-Crane`).

The closing answer: three, one per rigger and one for the crane, because
the first row of the table has the two riggers at different points of the
same procedure at the same time, and the crane runs a different procedure
again. A rigger's label is a function from rigger to label because the
riggers are interchangeable and there are several. The crane's is a
scalar because there is one.

## The translator's shape: one function over everyone

`verify/CraneOnePc.tla`. PlusCal would give the crane a process identity
and put every label in one function over `ProcSet`.

```tla
CONSTANTS Riggers, TheCrane, Idle, Hooked, Clear, Parked, Lifting
ProcSet == Riggers \cup {TheCrane}

VARIABLE pc
Init == pc = [p \in ProcSet |-> IF p = TheCrane THEN Parked ELSE Idle]

Lift == /\ pc[TheCrane] = Parked
        /\ \E r \in Riggers : pc[r] = Clear
        /\ \A r \in Riggers : pc[r] /= Hooked
        /\ pc' = [pc EXCEPT ![TheCrane] = Lifting]
```

**Measured: rc 0, 12 distinct states** (`verify-all.sh` row
`05-CraneOnePc`). Identical count, identical verdict. The two encodings
are the same model with the state tuple drawn differently.

Which to write by hand: the first. The union-domain `pc` exists because
the translator has one `pc` and must put every process in it. Writing raw
TLA+ there is no such constraint, and `crane = Parked` reads better than
`pc[TheCrane] = Parked`. The union shape is worth recognising, since it is
what every translated multi-process spec he will read looks like, and
worth not reproducing.

## Both encodings, side by side

| encoding | control variables | reachable | rc |
|---|---|---|---|
| a variable per kind | `rig` (function), `crane` (scalar) | 12 | 0 |
| one `pc` over `ProcSet` | `pc` (function over riggers and crane) | 12 | 0 |
| one site-wide phase | `phase` (scalar) | 3 | 0, and cannot state the rule |

The third row is `verify/CraneLazy.tla`, the lazy neighbour measured for
completeness: `Rigging -> Rigged -> Lifting -> Rigging`. It passes TLC
because its config has no invariant, and it has no invariant because the
rule cannot be written: "a rigger is at the load" is not a state the model
has.

## The rule is real

`verify/CraneUnguarded.tla` is `Crane.tla` with the `\A r : rig[r] /=
Hooked` conjunct dropped from `Lift`. **Measured: rc 12,
`NobodyUnderTheHook` violated** (`verify-all.sh` row `05-CraneUnguarded`):

| state | action | r1 | r2 | crane |
|---|---|---|---|---|
| 1 | | Idle | Idle | Parked |
| 2 | Hook(r1) | Hooked | Idle | Parked |
| 3 | StepBack(r1) | Clear | Idle | Parked |
| 4 | Hook(r2) | Clear | Hooked | Parked |
| 5 | Lift | Clear | Hooked | Lifting |

State 4 is the first row of the prompt's table, and state 5 is the lift the
rule forbids. The guard that prevents it reads every rigger's control
state, which is the thing a per-process label is for.

## Acceptable variants

- **Label sets as constants** (`RiggerLabels`, `CraneLabels`) with a
  type invariant over them. Not required. Nothing checked here needs it.
- **Return guarded on `crane = Parked`** is in the answer because the
  prose says "once the crane has set the hook down again". Dropping the
  guard still passes the rule, since `Return` does not touch the hook. It
  is a fidelity difference, not a verdict difference.
- **`Lift` without the `\E r : rig[r] = Clear` conjunct.** The crane
  lifts nothing. Passes the rule. Loses the prose.
- **Strings for labels.** Measured clean during authoring on a scratch
  probe (rc 0).

## Elimination table

| neighbour answer | what kills it |
|---|---|
| one site-wide phase (`CraneLazy.tla`) | row 1 of the table, and the rule cannot be written at all. |
| one label per rigger, no crane state, `Lift` as a pure guard check | row 3: "the crane is lifting while both riggers stand clear" is a state, and `Hook` must be disabled in it. Without a crane label there is nothing to disable it on. |
| `Lift` without the Hooked guard (`CraneUnguarded.tla`) | the trace above, rc 12. |
| `Hook` without the `crane = Parked` guard | a rigger hooks on during a lift. The rule fails at the next state (INFERRED, not run). |

## why-not-in-prompt

The prompt shows no TLA+. The honest caveat is the last sentence, "how
many things in your model record where someone is in their own
procedure", which says "more than one" out loud and nudges "per
process". It is there because the site-wide-phase answer cannot be
caught by TLC, only by the table's first row and by that question, and
the first row alone has been read past before. The word "procedure" in
both the rigger's and the crane's description does the rest of the
telegraphing: it says they each have one.
