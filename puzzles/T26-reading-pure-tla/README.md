# T26: Reading a Pure TLA+ Spec ⭐

## Lesson: The Init/Next/Spec Triple

Every pure TLA+ spec — whether you wrote it by hand or pcal generated it — boils down to three named formulas:

- **`Init`** — a predicate on the current state that says which states are valid initial states.
- **`Next`** — a predicate on the current AND next state. It relates one step to the next. The unprimed names refer to "now"; primed names like `x'` refer to "after this step."
- **`Spec`** — the temporal formula `Init /\ [][Next]_vars` (sometimes plus fairness). This says: the system starts in `Init` and every step is a `Next` step (or a stutter — see T32).

Reading a spec means looking at three things in order: what variables exist, what `Init` constrains them to, and what `Next` lets change. Everything else is named helper.

**Worked example — a temperature monitor.**

Read this spec and trace it in your head:

```
---- MODULE Thermostat ----
EXTENDS Integers

VARIABLES temp, fan

TempRange == -10..40
FanStates == {"off", "low", "high"}

TypeOK == temp \in TempRange /\ fan \in FanStates

Init ==
  /\ temp = 20
  /\ fan = "off"

WarmUp ==
  /\ temp < 40
  /\ temp' = temp + 1
  /\ fan' = fan

CoolDown ==
  /\ temp > -10
  /\ temp' = temp - 1
  /\ fan' = fan

ToggleFan ==
  /\ fan' = IF fan = "off" THEN "low"
            ELSE IF fan = "low" THEN "high"
            ELSE "off"
  /\ temp' = temp

Next == WarmUp \/ CoolDown \/ ToggleFan

Spec == Init /\ [][Next]_<<temp, fan>>
====
```

Walk through it:

- **Variables**: `temp` and `fan`. Two pieces of state.
- **`Init`**: starts at `temp = 20, fan = "off"`. Exactly one initial state.
- **`Next`** disjuncts three actions. Each step is one of `WarmUp`, `CoolDown`, `ToggleFan`.
- Each action **mentions both variables in the primed form**. `WarmUp` says `temp' = temp + 1` and `fan' = fan` — the second conjunct is what holds `fan` steady. If you left it out, `fan'` would be unconstrained and TLC would explore every value of `fan` after a `WarmUp`. (T29 makes this explicit with `UNCHANGED`.)
- **Guards** appear as the leading conjuncts: `temp < 40` blocks `WarmUp` at the top of the range; `temp > -10` blocks `CoolDown` at the bottom. Without those, `temp'` could leave `TempRange` and `TypeOK` would fail.
- **`Spec`** wraps `Next` in `[]`-square-brackets-on-`<<temp, fan>>`. That allows stuttering steps (no change) at any time. T32 unpacks why that matters.

Reading reflex: you can describe the system in one sentence. *"The thermostat sits at 20° with the fan off; it can warm up, cool down within `[-10, 40]`, or cycle the fan through off → low → high → off."* If you can't summarize a spec in one sentence, you haven't read it yet.

## Setup

A pure-TLA+ spec for a **traffic light** is shown below as the file `TrafficLight.tla` (also in the 🔒 spoiler). It is short — about 20 lines of real content. There is no PlusCal block; the file is hand-written TLA+.

Your job is to **read** it and answer the questions below in your head (or on paper). Then run TLC and confirm the state count matches your reasoning.

## Task

Open `solution/TrafficLight.tla` (or click the 🔒 spoiler below). Without running TLC yet, answer these questions:

1. How many variables are there? Name them.
2. What are the initial values? (one initial state, or several?)
3. What actions are in `Next`? For each one, describe the guard (when it can fire) and the effect.
4. Roughly how many distinct states will TLC find? Try to compute it.
5. Is there any state where NO action is enabled? (If yes, TLC will report deadlock unless stuttering is allowed.)

Then run:

```bash
cd solution
tlc TrafficLight
```

(No `-pcal` — pure TLA+.)

## Check

Compare TLC's output to your prediction:

- Does the state count match what you reasoned out?
- Did `TypeOK` pass?
- Was there a deadlock? Why or why not?

## Expected Result

- The spec has **two variables** (`color` and `ticks`).
- `Init` admits **one initial state** (`color = "red", ticks = 0`).
- `Next` has **two actions**: `Tick` (advance `ticks` while staying on the same color) and `Change` (rotate red → green → yellow → red and reset `ticks`).
- TLC should find **12 distinct states** — 3 colors × 4 tick values (0..3).
- `TypeOK` should pass. No deadlock — at every state at least `Change` is enabled.

If your prediction was off, walk back through `Next` and check which actions are enabled at each color/tick combination. Reading specs accurately is the foundation for writing them in T28 and beyond.

## Hints

??? hint "💡 Hint 1 — Name the variables and initial state"
    Every spec starts with `VARIABLES`. List them. Then find `Init` — it tells you the starting values. For this spec, there are exactly two variables. Can you name them and their initial values? Once you've done that, count: how many initial states are there?

??? hint "💡 Hint 2 — Trace the actions"
    `Next` is a disjunction of actions. For each action, identify the guard (the condition that must hold) and the effect (what primes change). E.g., does `Tick` increment a counter? Does `Change` modify color? Write down the structure of each action, then ask: at each state, which actions can fire?

??? hint "💡 Hint 3 — Count the reachable states"
    The number of distinct states is the product of the ranges of the variables. If one variable has 3 values and another has 4, you expect 3 × 4 = 12 states. But check the guards: if a guard prevents certain combinations, the real count may be lower. Trace one action through a few states to build intuition.
