# Pelican crossing: answer

## The answer

```tla
---- MODULE Pelican ----
EXTENDS Naturals

VARIABLES phase, timer, demand

vars == <<phase, timer, demand>>

Phases == {"go", "slow", "walk", "clear"}

Dwell(p) ==
  CASE p = "go"    -> 4
    [] p = "slow"  -> 3
    [] p = "walk"  -> 6
    [] p = "clear" -> 2

Succ(p) ==
  CASE p = "go"    -> "slow"
    [] p = "slow"  -> "walk"
    [] p = "walk"  -> "clear"
    [] p = "clear" -> "go"

TypeOK ==
  /\ phase \in Phases
  /\ timer \in 0..6
  /\ demand \in BOOLEAN

Init ==
  /\ phase = "go"
  /\ timer = 0
  /\ demand = FALSE

Press ==
  /\ ~demand
  /\ demand' = TRUE
  /\ UNCHANGED <<phase, timer>>

Tick ==
  /\ timer > 0
  /\ timer' = timer - 1
  /\ UNCHANGED <<phase, demand>>

Advance ==
  /\ timer = 0
  /\ phase = "go" => demand
  /\ LET next == Succ(phase) IN
       /\ phase' = next
       /\ timer' = Dwell(next)
       /\ demand' = IF next = "walk" THEN FALSE ELSE demand

Next == Press \/ Tick \/ Advance

Spec == Init /\ [][Next]_vars

TimerWithinDwell == timer <= Dwell(phase)

AmberOnlyOnDemand == phase = "slow" => demand
====
```

```
SPECIFICATION Spec
INVARIANTS
  TypeOK
  TimerWithinDwell
  AmberOnlyOnDemand
```

Two `CASE` expressions over the phase, one for the successor and one for the
dwell. `Advance` names the next phase once with `LET` and looks the dwell up on
it. That's the one place `LET` earns its keep here. Without it `Succ(phase)` is
written twice.

`demand' = IF next = "walk" THEN FALSE ELSE demand` is the `IF` in the item.
`next` is a name for an expression, not a variable, so there's nothing odd
about using it on the primed side.

## The missing arm

Drop the `"clear"` arm from `Succ` and TLC runs 26 states, then stops with
"Attempted to evaluate a CASE with no conditions true." A `CASE` with no true
arm has no value, and TLC finds that out the first time it's asked for one,
which is the first `Advance` out of "clear".

`OTHER` is the arm for the cases you didn't list. I'd leave it off a four-phase
cycle on purpose, so that a fifth phase added later fails loudly here rather
than going quietly to whatever `OTHER` said.

## Measurements

From `verify/`, `tlc -workers 1 -noGenerateSpecTE -metadir states/<name>
<Module>.tla -config <Module>.cfg`.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `Pelican` | reference | rc 0 | 49 | 34 | no error |
| `SuccMissingArm` | no `"clear"` arm in `Succ` | rc 75 | 35 | 26 | `Attempted to evaluate a CASE with no conditions true.` |

34 by hand. "go" has 5 clock values and 2 demand values, 10. "slow" has 4
clock values and demand is always on, 4. "walk" has 7 and 2, 14. "clear" has 3
and 2, 6.

## Acceptable variants

- A chain of `IF phase = "go" THEN ... ELSE IF ...`. Same values.
- A `CASE` with `[] OTHER -> ...` as its last arm. Same values.
- One `CASE` yielding a pair, taken apart in `Advance`. Tuples are another family.
- `demand' = demand /\ next /= "walk"`. The `IF` as a Boolean.
- The minimum green as a named constant. Same count if it's 4.

The first two can't fail the missing-arm way, because the last branch catches
everything. That's the same property seen from the other side: a fifth phase
goes silently to the last branch.

## Wrong neighbors

| neighbor | what kills it |
|---|---|
| a `CASE` with an arm missing | rc 75 at the first evaluation that needs it |
| `Succ(phase)` written twice instead of `LET` | nothing. Passes. The `LET` is for the reader. |
| `Advance` from "go" without the demand check | `AmberOnlyOnDemand` red, rc 12 (not measured) |
| `timer' = Dwell(phase)`, the phase being left | `TimerWithinDwell` red on the first slow after a go, since 4 is more than 3. rc 12 (not measured) |
| `Press` without the `~demand` guard | passes. Same states, more edges (not measured). |

## Why not in prompt

The table is the cycle, and a reader could build the cycle with four `IF`s or
with a `CASE`. The prompt doesn't push either way, so the `CASE` isn't forced,
and a reader who never reaches for it still passes. The honest caveat: this
item exercises `CASE` only for the reader who already knows it exists.

What the prompt does force is the dwell being looked up on the phase being
entered rather than the one being left, and that row of the table, "at least 4
s", is the one that kills the lazy clock.
