# T33: Counter in Pure TLA+ ⭐⭐

## Lesson: Compose Everything You Have

This is your first **synthesis** puzzle in pure TLA+. No new mechanic; you reach for what you already know:

- `Init` predicate (T28)
- Multiple actions in `Next`, joined by `\/` (T31)
- `UNCHANGED` for stability (T29)
- Standard `Spec == Init /\ [][Next]_vars` shape (T32)
- An `INVARIANT` directive in the cfg (T0c, T26)

The recipe for a small spec from scratch:

1. Sketch the variables on paper. What does the system "know"?
2. Sketch the actions. What can happen, and under what conditions?
3. For each action, list every variable: is it updated, or `UNCHANGED`?
4. Pick an invariant — a property that should be true at every reachable state.
5. Pick the standard `Spec` shape.
6. Write the cfg with `SPECIFICATION` and `INVARIANT`.

**Worked example — a fuel meter.**

System: a fuel meter has a `level` (gallons, `0..10`) and a `pump_running` flag. Two actions:

- `StartPump` — enabled when `pump_running = FALSE` and `level < 10`. Sets `pump_running' = TRUE`.
- `StopPump` — enabled when `pump_running = TRUE`. Sets `pump_running' = FALSE`.
- `Pump` — enabled when `pump_running = TRUE` and `level < 10`. Increments `level` by 1, leaves `pump_running` alone.

Invariant: `level <= 10`. (Trivially holds because `TypeOK` already says so — but it's the kind of thing you'd write.)

```
---- MODULE Pump ----
EXTENDS Integers

VARIABLES level, pump_running

vars == <<level, pump_running>>

TypeOK == level \in 0..10 /\ pump_running \in BOOLEAN

Init == level = 0 /\ pump_running = FALSE

StartPump ==
  /\ pump_running = FALSE
  /\ level < 10
  /\ pump_running' = TRUE
  /\ UNCHANGED level

StopPump ==
  /\ pump_running = TRUE
  /\ pump_running' = FALSE
  /\ UNCHANGED level

Pump ==
  /\ pump_running = TRUE
  /\ level < 10
  /\ level' = level + 1
  /\ UNCHANGED pump_running

Next == StartPump \/ StopPump \/ Pump

NeverOverflows == level <= 10

Spec == Init /\ [][Next]_vars
====
```

Cfg:

```
SPECIFICATION Spec
INVARIANT TypeOK
INVARIANT NeverOverflows
```

TLC finds **22 reachable states** (`level \in 0..10` × `pump_running \in {TRUE, FALSE}`, minus the unreachable `<<10, TRUE>>` followed by-then-`Pump`-no-fire combinations — actually, all 22 are reachable; the action set covers every transition you'd want).

The structure is identical to what pcal would have generated for the equivalent PlusCal program, minus the `pc` variable. Without labels, you write the actions yourself.

## Setup

A **score-and-strikes counter** for a baseball-style mini-game:

- `score` — integer in `0..9`. Starts at `0`.
- `strikes` — integer in `0..3`. Starts at `0`.

Three actions:

- **`Hit`**: enabled when `strikes < 3` and `score < 9` (otherwise the score would overflow). Increments `score` by 1, resets `strikes` to 0.
- **`Strike`**: enabled when `strikes < 3`. Increments `strikes` by 1, leaves `score` alone.
- **`StrikeOut`**: enabled when `strikes = 3`. Sets `strikes' = 0` and `score' = 0` (the inning ends; everything resets).

Invariant: `ScoreInRange == score \in 0..9` and `StrikesInRange == strikes \in 0..3`. Both should hold (they're part of `TypeOK`, but list them as separate invariants to practice multi-invariant cfg).

A second invariant: **`NoScoreWhenStruckOut == strikes = 3 => score = 0`** — the idea being "you only ever get struck out at the start of an inning when no points have been scored." (This is naïve — let TLC tell you.)

## Task

Author `solution/Game.tla` with the variables, actions, and invariants described. Use the standard `Spec` shape (no fairness needed; this puzzle is about safety).

Author `solution/Game.cfg` with:

```
SPECIFICATION Spec
INVARIANT TypeOK
INVARIANT NoScoreWhenStruckOut
```

## Check

```bash
cd solution
tlc Game
```

## Expected Result

- `TypeOK` passes.
- `NoScoreWhenStruckOut` is **violated**. Counterexample (TLC reports the shortest): 1 Hit to score = 1, strikes = 0; then 3 Strikes (leaving score = 1, strikes = 3); the invariant fails because `strikes = 3 /\ score = 1 # 0`.
- Trace length: 5 states.

After you've seen the violation, change the invariant to `strikes = 3 => score <= 9` (always true) or comment it out, and re-run to confirm `TypeOK` still passes.

The takeaway: pure-TLA+ specs are written by composing the same five pieces every time. Once you internalize the shape, writing a spec is just naming actions and listing what each one constrains.
