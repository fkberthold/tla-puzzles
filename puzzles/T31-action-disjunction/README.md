# T31: Disjunction in Next — Multiple Actions ⭐⭐

## Lesson: Next == A \\/ B \\/ C

Real systems do more than one thing. The standard pattern in pure TLA+ is to write each kind of step as its own named action and combine them with **disjunction**:

```
Next == ActionA \/ ActionB \/ ActionC
```

This says: a `Next` step is *any one of* `ActionA`, `ActionB`, or `ActionC`. TLC explores all of them at every state — every action that is currently enabled (its guard is true) generates a successor, and the model checker walks the resulting branching state space exhaustively.

The non-negotiable rule: **every action must constrain every variable**. Either set `var'` to a value, or hold it steady with `UNCHANGED`. If `ActionA` updates `x` but doesn't mention `y'`, then taking `ActionA` leaves `y'` unconstrained — TLC will explore every possible value, almost certainly violating `TypeOK`.

This is where `UNCHANGED` earns its name. In `ActionA`, the variables that don't change are unchanged. List them.

A common pattern is to define `vars == <<x, y, z>>` once and use it both in `[][Next]_vars` and inside actions:

```
vars == <<x, y, z>>

ActionA ==
  /\ x' = x + 1
  /\ UNCHANGED <<y, z>>

ActionB ==
  /\ y' = y - 1
  /\ UNCHANGED <<x, z>>

Next == ActionA \/ ActionB

Spec == Init /\ [][Next]_vars
```

**Worked example — a recipe with two ingredients.**

A chef prepares a recipe with two ingredients: `flour` (cups) and `sugar` (cups). Each step the chef adds one cup of flour or one cup of sugar (chef's choice). The recipe caps at 5 cups total of either ingredient.

```
---- MODULE Recipe ----
EXTENDS Integers

VARIABLES flour, sugar

vars == <<flour, sugar>>

TypeOK == flour \in 0..5 /\ sugar \in 0..5

Init ==
  /\ flour = 0
  /\ sugar = 0

AddFlour ==
  /\ flour < 5
  /\ flour' = flour + 1
  /\ UNCHANGED sugar

AddSugar ==
  /\ sugar < 5
  /\ sugar' = sugar + 1
  /\ UNCHANGED flour

Next == AddFlour \/ AddSugar

Spec == Init /\ [][Next]_vars
====
```

What TLC does:

- At `<<0, 0>>`, both actions are enabled. Two successors: `<<1, 0>>` (AddFlour) and `<<0, 1>>` (AddSugar).
- At `<<5, 5>>`, neither is enabled. With `CHECK_DEADLOCK TRUE` (default), TLC reports deadlock; with `CHECK_DEADLOCK FALSE`, it accepts the stuttering.
- Total reachable states: 6 × 6 = 36 (every `(flour, sugar)` in `0..5 × 0..5`).

The two actions are completely symmetric. Each one mentions both variables — one with an arithmetic update, one with `UNCHANGED`. If you forgot `UNCHANGED sugar` in `AddFlour`, TLC would error with "Successor state is not completely specified by action AddFlour. Variable sugar is not defined."

## Setup

A **smart bulb** has two variables:

- `power` — `"on"` or `"off"`. Starts `"off"`.
- `brightness` — an integer in `0..3`. Starts `0`.

Three actions:

- **`PowerOn`**: turns the bulb on. Enabled when `power = "off"`. Sets `power' = "on"` and `brightness' = 1` (default brightness when turned on).
- **`PowerOff`**: turns the bulb off. Enabled when `power = "on"`. Sets `power' = "off"` and `brightness' = 0`.
- **`Dim`**: change brightness. Enabled when `power = "on"`. Sets `brightness' \in 0..3` (any value). Power stays on.

Note: `Dim` can set `brightness' = 0` while power stays `"on"`, creating state `<<"on", 0>>`. This is intentional — a bulb at zero brightness with power on is "on but not emitting." The puzzle's goal is composing three actions, not constraining the physics.

## Task

Author `solution/Bulb.tla` from scratch with:

- Module declaration, `EXTENDS Integers`
- `VARIABLES power, brightness`
- `vars == <<power, brightness>>`
- `TypeOK` covering both variables
- `Init` (single initial state: `<<"off", 0>>`)
- The three actions described above. Each must constrain BOTH variables. Use `UNCHANGED` where appropriate.
- `Next == PowerOn \/ PowerOff \/ Dim`
- `Spec == Init /\ [][Next]_vars`

Author `solution/Bulb.cfg` with `SPECIFICATION Spec` and `INVARIANT TypeOK`.

## Check

```bash
cd solution
tlc Bulb
```

## Expected Result

- TLC reports **5 distinct states**: `<<"off", 0>>`, plus `<<"on", b>>` for `b \in 0..3`.
- `TypeOK` passes.
- No deadlock — from `<<"off", 0>>` you can `PowerOn`; from any `<<"on", b>>` you can `PowerOff` or `Dim`.

If `Dim` forgets to mention `power'` (or `UNCHANGED power`), TLC throws "Successor state is not completely specified" the moment `Dim` fires. If `PowerOn` forgets `brightness'`, same error.

A subtler bug: writing `Dim` as `brightness' \in 0..3 /\ UNCHANGED power` *without* the `power = "on"` guard. TLC would accept it, but `Dim` would fire even when the bulb is off — every off state would have a transition to `<<"off", 0>>` (already known) and to `<<"off", b>>` for other `b`, except `<<"off", b>>` for `b > 0` doesn't satisfy the description "off means no brightness." Add the guard so the spec stays honest.

## Hints

??? hint "💡 Hint 1 — Next is a disjunction of actions"
    When there are multiple actions, write `Next == ActionA \/ ActionB \/ ActionC`. This says each step is *one* of those actions. TLC explores all enabled actions at every state. An action is enabled when its guard (the conjuncts before the primed assignments) is true. A step takes one of the enabled actions.

??? hint "💡 Hint 2 — Every action constrains both variables"
    Each action must mention both `power'` and `brightness'`, either with an assignment or `UNCHANGED`. If `PowerOn` sets `power' = "on"` but forgets about `brightness'`, TLC treats `brightness'` as unconstrained and explores every value, usually violating `TypeOK`. The pattern: write the guard, then updates for changed variables, then `UNCHANGED` for steady variables.

??? hint "💡 Hint 3 — Nondeterminism in assignments"
    `Dim` sets `brightness' \in 0..3`, which means "in the next state, brightness can be any value in 0..3." This is nondeterministic — TLC creates a successor for each choice. But the guard `power = "on"` ensures this only happens when the bulb is powered. Without that guard, `Dim` could fire even when off, and the spec would allow unintended behavior.
