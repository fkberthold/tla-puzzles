# T29: UNCHANGED for Stability ⭐

## Lesson: If You Don't Constrain a Primed Variable, Anything Goes

In an action formula, every variable that appears in the spec needs to be **mentioned in primed form** — either set to a specific value, or explicitly held steady. If you forget one, TLC treats `var'` as unconstrained: it can take any value of any type. The result is usually a `TypeOK` violation that looks baffling until you spot the missing primed mention.

`UNCHANGED` is shorthand for "this variable does not change." It expands literally:

- `UNCHANGED x` is sugar for `x' = x`
- `UNCHANGED <<x, y>>` is sugar for `x' = x /\ y' = y`
- `UNCHANGED vars` (where `vars == <<x, y, z>>`) holds *all* of them steady at once.

You can mix and match. An action that updates `x` and holds `y, z` steady can be written either:

```
SomeAction == /\ x' = x + 1
              /\ UNCHANGED <<y, z>>
```

or:

```
SomeAction == /\ x' = x + 1
              /\ y' = y
              /\ z' = z
```

Both compile to identical TLA+. Style: use `UNCHANGED` when you have ≥2 unchanged variables; the explicit form is fine for one.

**Worked example — a fuel gauge with a forgotten variable.**

A car has `fuel` (gallons remaining) and `odometer` (miles driven). The car drives 1 mile per step, consuming 1 gallon every 30 miles.

```
---- MODULE Car ----
EXTENDS Integers

VARIABLES fuel, odometer

TypeOK == fuel \in 0..10 /\ odometer \in 0..30

Init ==
  /\ fuel = 10
  /\ odometer = 0

\* WRONG — does not mention odometer'
DriveBuggy ==
  /\ fuel' = IF odometer % 30 = 29 THEN fuel - 1 ELSE fuel

Next == DriveBuggy

Spec == Init /\ [][Next]_<<fuel, odometer>>
====
```

If you ran TLC on this, it would immediately report a `TypeOK` violation. Why? Because `DriveBuggy` does not mention `odometer'`. TLC reads that as: "after this step, `odometer'` can be anything in the universe — TRUE, the string `"hello"`, the set `{1,2,3}`, anything." The very first step picks some value, that value is not in `0..30`, and `TypeOK` fires.

The fix is one line:

```
DriveFixed ==
  /\ odometer' = odometer + 1
  /\ fuel'     = IF odometer' % 30 = 0 /\ odometer > 0 THEN fuel - 1 ELSE fuel
```

Now both variables are constrained. Or — if an action genuinely doesn't change one of them — use `UNCHANGED`:

```
Honk ==
  /\ \* the horn doesn't change fuel or odometer
  /\ UNCHANGED <<fuel, odometer>>
```

This is the "rule of always mention every variable." Every action constrains every variable, either with a new value or with `UNCHANGED`. Some specs define `vars == <<a, b, c>>` once and end every action with `... /\ UNCHANGED vars-minus-the-ones-this-action-touches` — but at this scale, listing variables explicitly is clearer.

## Setup

A pair of counters models a simple clock display: `minutes` (0..59) and `seconds` (0..59). Two actions:

- **Tick** — increments `seconds`. When `seconds` hits 59, the next tick rolls it to 0 and increments `minutes` (mod 60).
- **Reset** — sets `minutes` and `seconds` both to 0.

The first version of the spec already in `solution/Clock.tla` has a deliberate bug: one action forgets to mention one of the variables. You will run it, see the type violation, then **fix the spec** by adding the missing constraint (using `UNCHANGED` where appropriate).

## Task

1. Open `solution/Clock.tla`. Read both actions. Spot the missing primed variable.
2. Run TLC and confirm a `TypeOK` violation:
   ```bash
   cd solution
   tlc Clock
   ```
3. Edit `Clock.tla` to fix the bug. Use `UNCHANGED` for the held-steady variable.
4. Re-run TLC. Should now pass.

## Check

- Before fix: TLC reports an error like `Successor state is not completely specified by action Tick. The following variable is not defined: minutes.` 2-state trace.
- After fix: TLC reports no error.

## Expected Result

The buggy run produces exactly this trace:

```
State 1: minutes = 0, seconds = 0
State 2: minutes = null, seconds = 1
```

`null` is TLC's way of saying "this variable's primed value was never constrained." Read it as "I'm taking a step but I don't know what `minutes` should be."

After you add `/\ UNCHANGED minutes` to the `seconds < 59` branch of `Tick`, TLC reports **3600 distinct states** — every `(minutes, seconds)` pair in `0..59 × 0..59`, reachable by `Tick`-then-`Reset` cycling and the rollover branch. `TypeOK` passes; no deadlock.

The error message is the most important part of this puzzle. Anytime TLC says "variable is not defined" or "successor not completely specified," look for a primed variable that is missing from the action you just wrote.
