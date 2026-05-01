# T06: The Scoreboard ⭐

## Lesson: The `define` Block — Named Operators as Vocabulary

The `define` block lets you name expressions so your spec reads like prose instead of algebra. It sits between the `variables` declaration and the `process` body. Each operator becomes reusable vocabulary throughout the spec — used in invariants, in conditions, in other operators.

**Worked example — a weather station.**

A sensor tracks temperature and humidity. Instead of writing `temp > 85 \/ temp < 55 \/ humidity < 30 \/ humidity > 70` every time we want to know whether a reading is uncomfortable, we name the conditions once and build on them.

```
(*--algorithm Weather {
  variables temp = 70, humidity = 40, readings = 0;

  define {
    TooHot == temp > 85
    TooCold == temp < 55
    Dry == humidity < 30
    Muggy == humidity > 70
    Comfortable == ~TooHot /\ ~TooCold /\ ~Dry /\ ~Muggy
  }

  fair process (sensor = "Station") {
    measure:
      while (readings < 3) {
        with (t \in 50..90) { temp := t; };
        with (h \in 20..80) { humidity := h; };
        readings := readings + 1;
      }
  }
}*)
```

Sample invariants:

- `TypeOK == temp \in 50..90 /\ humidity \in 20..80`
- `SometimesUncomfortable == ~Comfortable` — TLC WILL violate this (70°F, 40% is comfortable)

Three gifts from `define`:

1. **READABILITY.** `Comfortable` explains itself at first read. `~(temp > 85) /\ ~(temp < 55) /\ ~(humidity < 30) /\ ~(humidity > 70)` does not.

2. **REUSABILITY.** `Comfortable` is built from four smaller operators. Change any one (a heat wave redefines `TooHot` as `temp > 82`), and every operator that depends on it updates automatically.

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

- TLC should find **27 distinct states**
- PointsConserved should PASS (it's a real invariant of the system)
- HomeAlwaysLeads should be violated by the INITIAL STATE — TLC catches it immediately because 0-0 is a tie, not a lead. Invariants check the initial state too!

## Hints

??? hint "💡 Hint 1 — Define is vocabulary, not state"
    A `define` block is pure logic — it defines operators (like functions) that return true or false. `HomeLeads == home > away` doesn't CHANGE state; it names a condition so you can reference it elsewhere. Use it in invariants, conditions, other operators.

??? hint "💡 Hint 2 — Operator composition builds understanding"
    `TotalPoints == home + away` is simple. `ValidScore(s) == s \in 0..5` is a parameterized helper. In TypeOK, use both: `ValidScore(home) /\ ValidScore(away)`. Each operator is one piece of the puzzle. Combine them to describe the full state.

??? hint "💡 Hint 3 — Invariants check EVERY state, including the start"
    `HomeAlwaysLeads` is violated in the INITIAL state where home = 0, away = 0 (a tie, not a lead). TLC checks invariants before ANY steps are taken. If an invariant fails at the start, TLC reports it immediately with a trace of length 1.
