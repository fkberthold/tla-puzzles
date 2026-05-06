# T06: The Scoreboard ⭐

## Lesson: The `define` Block — Named Operators as Vocabulary

The `define` block lets you name expressions so your spec reads like prose instead of algebra. It sits between the `variables` declaration and the `process` body. Each operator becomes reusable vocabulary throughout the spec — used in invariants, in conditions, in other operators.

**Worked example — naming a temperature reading.**

A sensor reads a temperature and stores whether it's hot. Instead of inlining the comparison `temp > 85`, we name it once with a `define` block and use the name as the value.

```
(*--algorithm TempName {
  variables temp = 90, hot = FALSE;

  define {
    TooHot == temp > 85
  }

  fair process (sensor = "Sensor") {
    label_it:
      hot := TooHot;
  }
}*)
```

The `define` block sits between `variables` and `fair process`. `TooHot == temp > 85` introduces the operator name; the body `temp > 85` is its definition. In the label, `hot := TooHot` reads the operator's current value and stores it. With `temp = 90`, `TooHot` evaluates to `TRUE`, so `hot` becomes `TRUE`. Change the initial `temp` to `70` and `TooHot` evaluates to `FALSE`. The operator is a *named expression*, not a function call — it has no arguments here, just a definition that depends on the current state.

Three gifts from `define`:

1. **READABILITY.** `hot := TooHot` reads as prose. `hot := temp > 85` reads as algebra.
2. **REUSABILITY.** Use the name everywhere — in invariants, in conditions, in other operators (`Comfortable == ~TooHot /\ ~TooCold` if you've also defined `TooCold`).
3. **PARAMETERS.** Operators can take arguments: `InRange(x, lo, hi) == x >= lo /\ x <= hi`. Then use `InRange(temp, 50, 90)` anywhere.

**Operators are pure expressions.** They describe values; they never change state. They're vocabulary, not verbs. Keep state change in the process body.

## Setup

Two teams — Home and Away — play a game. Each round, one team scores a point (chosen nondeterministically). The game ends after 5 rounds.

Instead of writing complex invariant expressions inline, define OPERATORS in the `define` block that give names to useful concepts.

## Task

Write a PlusCal spec with:

- Variables `home` and `away` starting at 0
- A variable `round` starting at 0
- A single process that loops 5 times, each time awarding a point to either home or away

In the `define` block, create these operators:

- `TotalPoints == home + away`
- `HomeLeads == home > away`
- `Tied == home = away`
- `GameOver == round = 5`
- `ValidScore(s) == s \in 0..5`

## Check

1. **TypeOK**: use your operators! `ValidScore(home) /\ ValidScore(away) /\ round \in 0..5`
2. **PointsConserved**: `TotalPoints = round` — total points always equals rounds played
3. **HomeAlwaysLeads**: `HomeLeads` — this SHOULD be violated

## Expected Result

- TLC should report `No error has been found` (TypeOK and PointsConserved pass; HomeAlwaysLeads is violated)
- PointsConserved should PASS (it's a real invariant of the system)
- HomeAlwaysLeads should be violated by the INITIAL STATE — TLC catches it immediately because 0-0 is a tie, not a lead. Invariants check the initial state too!
- The canonical solution reports **27 distinct states**; your label choices may yield different counts, but both the structure (5 scoring rounds with home/away choice) and the invariant outcomes remain

## Hints

??? hint "💡 Hint 1 — Define is vocabulary, not state"
    A `define` block is pure logic — it defines operators (like functions) that return true or false. `HomeLeads == home > away` doesn't CHANGE state; it names a condition so you can reference it elsewhere. Use it in invariants, conditions, other operators.

??? hint "💡 Hint 2 — Operator composition builds understanding"
    `TotalPoints == home + away` is simple. `ValidScore(s) == s \in 0..5` is a parameterized helper. In TypeOK, use both: `ValidScore(home) /\ ValidScore(away)`. Each operator is one piece of the puzzle. Combine them to describe the full state.

??? hint "💡 Hint 3 — Invariants check EVERY state, including the start"
    `HomeAlwaysLeads` is violated in the INITIAL state where home = 0, away = 0 (a tie, not a lead). TLC checks invariants before ANY steps are taken. If an invariant fails at the start, TLC reports it immediately with a trace of length 1.
