# 07 donor-session: answer

Six labels, three donors, every action a move along the visit. Six
actions each carry a `pc[d] = from` guard and a `pc' = [pc EXCEPT ![d] =
to]` update, so the two lines go into one helper and each action becomes
its guard plus a call. That helper is what the cheat sheet calls `Trans`.

## The spec

`verify/Donors.tla`.

```tla
EXTENDS Naturals, FiniteSets
CONSTANTS Donors, Chairs,
          Arrived, Screening, Cleared, Donating, Resting, Gone

ProcSet == Donors

VARIABLE pc
vars == <<pc>>

At(label) == {d \in ProcSet : pc[d] = label}

Trans(d, from, to) == /\ pc[d] = from
                      /\ pc' = [pc EXCEPT ![d] = to]

Init == pc = [d \in ProcSet |-> Arrived]

CallIn(d) == /\ At(Screening) = {}
             /\ Trans(d, Arrived, Screening)

Pass(d) == Trans(d, Screening, Cleared)
Defer(d) == Trans(d, Screening, Gone)

Sit(d) == /\ Cardinality(At(Donating)) < Chairs
          /\ Trans(d, Cleared, Donating)

Unhook(d) == Trans(d, Donating, Resting)
Leave(d) == Trans(d, Resting, Gone)

Terminating == /\ \A d \in ProcSet : pc[d] = Gone
               /\ UNCHANGED vars

Next == \/ \E d \in ProcSet :
             CallIn(d) \/ Pass(d) \/ Defer(d) \/ Sit(d) \/ Unhook(d) \/ Leave(d)
        \/ Terminating

Spec == Init /\ [][Next]_vars

OneAtTheDesk == Cardinality(At(Screening)) <= 1
NoStandingDonors == Cardinality(At(Donating)) <= Chairs
```

Config: `Donors = {d1, d2, d3}`, `Chairs = 2`, labels as model values, both
invariants, deadlock checking on with the `Terminating` disjunct covering
the intended end. **Measured: rc 0, 199 distinct states** (`verify-all.sh`
row `07-Donors`).

The closing answer: six actions move a donor along the visit, and all
six were the same two lines with different labels, so the two lines
became `Trans(d, from, to)` and each action became its own guard, if any,
conjoined with a `Trans`. `Pass`, `Defer`, `Unhook` and `Leave` have no
guard of their own and are a bare `Trans`.

## What is doing the work

**The state is nothing but control state.** `pc` is the only variable.
Every rule and every guard is a count over it. That is normal: once the
visit is the only thing happening, where each donor is in it is the whole
of the world.

**Two guards read other donors' labels.** `CallIn` fires only when nobody
is at `Screening`, and `Sit` only when fewer than `Chairs` are at
`Donating`. In PlusCal those are an `await` on a count over `pc`, and he
has read them. By hand they are a set-builder over `pc`, named once as
`At(label)` so the rules and the guards share it.

**`ProcSet` is the domain of `pc` and the range of the quantifier in
`Terminating`.** With one kind of process it equals `Donors`, and naming it
anyway is the idiom the translator uses. It is here so the shape is
recognizable, not because `Donors` would not do.

## The nurse guard is real

`verify/RushDesk.tla` drops `At(Screening) = {}` from `CallIn`.
**Measured: rc 12, `OneAtTheDesk` violated** (`verify-all.sh` row
`07-RushDesk`):

| state | action | d1 | d2 | d3 |
|---|---|---|---|---|
| 1 | | Arrived | Arrived | Arrived |
| 2 | Trans(d1, Arrived, Screening) | Screening | Arrived | Arrived |
| 3 | Trans(d2, Arrived, Screening) | Screening | Screening | Arrived |

Note the action name TLC prints: `Trans(d1, Arrived, Screening)`, not
`CallIn(d1)`. When an action is a bare call to the helper, the helper is
the innermost action TLC can name. If the trace should say `CallIn`, give
`CallIn` a conjunct of its own, or accept it. It is a cosmetic cost of the
helper and worth knowing before the first long trace.

## Acceptable variants

- **No helper**, the two lines written six times. Same verdicts, more
  typing, and the closing question of the prompt is then "I noticed and
  left it". Acceptable.
- **A `pc`-only `Trans` with the guard folded in**, `Trans(d, from, to,
  guard)`. Over-engineered for six actions. Not wrong.
- **A `Waiting` label between `Arrived` and `Screening`** for "called but
  not yet at the desk". Adds states for a distinction the rules cannot
  see. The item 02 cost.
- **`Cleared` dropped**, with `Pass` guarded on a free chair so the donor
  goes straight to a chair. Kills row 2 of the table: a cleared donor
  waiting for a chair is a state, and the model must have it. Not
  acceptable.
- **A `bags` counter** bumped in `Unhook`, with a rule `bags <=
  Cardinality(Donors)`. Harmless. Adds no verdict.
- **`CHECK_DEADLOCK FALSE`** instead of `Terminating`. Equivalent here
  (INFERRED from item 03's measurement on the same shape, not run on this
  spec).
- **Strings for labels.** Measured clean during authoring on a scratch
  probe (rc 0).

## Elimination table

| neighbor answer | what kills it |
|---|---|
| `CallIn` without the nurse guard (`RushDesk.tla`) | rc 12 at state 3, above. |
| `Sit` without the chair guard | `NoStandingDonors` fails once three donors are cleared and seated (INFERRED, not run). Row 2 is also unreachable, since nobody ever waits. |
| one session-wide phase | row 1: three donors at three different steps. |
| `Pass` straight to `Donating` with the chair guard | row 2 is unreachable: nobody is ever cleared and waiting. |
| no `Terminating` and no config switch | rc 11 at "everyone has left" (INFERRED from item 03 and 06 on the same shape, not run on this spec). |

## why-not-in-prompt

The prompt shows no TLA+. The honest caveat is the closing paragraph,
which all but names the helper: "the same two lines in each of them" is a
description of a `pc` guard and a `pc` update, and "what you did about
it" invites a definition. It is there because nothing TLC checks can tell
a spec with the helper from one without, so the only way to drill the
helper is to make him notice the repetition and ask what he did. A reader
who writes the six actions and does nothing has still answered the item.
The helper is a style retrieval and the prompt says so by asking rather
than requiring.

The table's first row, three donors at three different steps, telegraphs
"per donor" the way item 05's first row telegraphs "per rigger". That is
the price of foreclosing a single phase.

## Measured runs

Every row is a line of `drill/control-state/verify-all.sh`. One config per
module, run with one worker, no trace spillage.

| module | config | rc | distinct states |
|---|---|---|---|
| RushDesk.tla | RushDesk.cfg | rc 12 | 7 |
| Donors.tla | Donors.cfg | rc 0 | 199 |
