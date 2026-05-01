# T14: Functions — EXCEPT Update ⭐

## Lesson: Updating ONE Entry of a Function

T12 built functions; T13 read from them. T14 returns an UPDATED COPY with one (or more) entries changed.

```
f == [n \in 0..3 |-> n * n]    \* {0->0, 1->1, 2->4, 3->9}
[f EXCEPT ![2] = 99]           \* {0->0, 1->1, 2->99, 3->9}    (NEW function)
```

The shape:

```
[f EXCEPT ![key] = newValue]
```

Reads: "the function that's the SAME as `f`, EXCEPT at `key`, where it's `newValue`."

**`EXCEPT` does not mutate.** It RETURNS a new function. To "update" a variable, write:

```
f := [f EXCEPT ![2] = 99];
```

You can update multiple entries at once:

```
[f EXCEPT ![1] = 100, ![3] = 200]
```

This is the same syntax you saw with records in T9. Records are functions over strings, so `[r EXCEPT !.field = v]` is just sugar for `[r EXCEPT !["field"] = v]`. Same operator, different keys.

**Worked example — a vending machine refilling slots.**

A vending machine has slots `1..3`, each holding some inventory. The operator updates slot 2 directly to 10 units. Then they restock slot 1 to a configured level.

```
(*--algorithm Vending {
  variables stock = [s \in 1..3 |-> 0];

  define {
    Slots == DOMAIN stock
    EmptySlots == \A s \in Slots : stock[s] = 0
  }

  fair process (operator = "Operator") {
    refillTwo:
      stock := [stock EXCEPT ![2] = 10];
    refillOne:
      stock := [stock EXCEPT ![1] = 5];
  }
}*)
```

Sample invariants:

- `TypeOK == \A s \in Slots : stock[s] \in 0..20`
- `Slot3Untouched == stock[3] = 0` — passes; the operator never touched slot 3

The DOMAIN of the function does NOT change. `EXCEPT` rewrites VALUES in place; it never adds or removes keys. After the second update, `stock = [1 |-> 5, 2 |-> 10, 3 |-> 0]` — same domain `{1, 2, 3}`, two values changed.

(Note: the relative-update form `[f EXCEPT ![k] = @ + 1]` — using `@` to mean "the old value" — is in T15.)

## Setup

A scoreboard tracks how many goals each of three teams scored. Teams are named `"red"`, `"blue"`, and `"green"`. Initially every team has 0 goals. Across the match:

1. Red scores a goal — red goes from 0 to 1.
2. Blue scores two goals — blue goes from 0 to 2.
3. Red scores another goal — red goes from 1 to ... but T14 doesn't have `@` yet, so you'll write the new value as a fresh number 2.
4. Then green scores 3 — green goes from 0 to 3.

You'll model each goal-update with `EXCEPT`, writing the absolute new value each time.

## Task

Write a PlusCal spec with:

- A variable `goals` initialized to `[t \in {"red", "blue", "green"} |-> 0]`
- A variable `step` starting at `0`

A single fair process runs four labels in sequence:

1. **redOne**: `goals := [goals EXCEPT !["red"] = 1]`. Increment `step`.
2. **blueTwo**: `goals := [goals EXCEPT !["blue"] = 2]`. Increment `step`.
3. **redTwo**: `goals := [goals EXCEPT !["red"] = 2]`. Increment `step`.
4. **greenThree**: `goals := [goals EXCEPT !["green"] = 3]`. Increment `step`.

In the `define` block:

- `Teams == DOMAIN goals`
- `TypeOK == Teams = {"red", "blue", "green"} /\ \A t \in Teams : goals[t] \in 0..3 /\ step \in 0..4`
- `EndsCorrect == step = 4 => goals = [t \in {"red", "blue", "green"} |-> IF t = "red" THEN 2 ELSE IF t = "blue" THEN 2 ELSE 3]`
- `TeamsStable == Teams = {"red", "blue", "green"}`

## Check

1. **TypeOK** — see above.
2. **EndsCorrect** — once `step = 4`, the goals function equals the expected final state.
3. **TeamsStable** — `EXCEPT` never alters the domain.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **5 distinct states** (one per `step` value: 0, 1, 2, 3, 4). Your deterministic spec will likely match this count; state count depends on your label choices.

**Bonus.** Replace the `redTwo` label's body with `goals := [goals EXCEPT !["red"] = 1]` (idempotent). What happens to the state count? (Hint: a state where nothing actually changes is still a step in PlusCal — but the new state may be identical to the previous one if `step` weren't incremented.)

## Hints

??? hint "💡 Hint 1 — EXCEPT updates one entry at a time"
    `[goals EXCEPT ![key] = newValue]` returns a function identical to `goals` EXCEPT at `key`, where the value is `newValue`. The DOMAIN never changes. You're updating VALUES, not keys. Each label updates one team's score — red, blue, red again, then green.

??? hint "💡 Hint 2 — Absolute values, not relative"
    T14 doesn't have `@` yet (that's T15). Write the new values directly: `redOne` sets red to 1, `blueTwo` sets blue to 2, etc. No arithmetic inside EXCEPT — just hardcoded numbers. The point is learning the syntax; T15 will add relative updates with `@`.

??? hint "💡 Hint 3 — Four sequential labels with four goals"
    Red scores, blue scores, red scores again, green scores. Four labels, four EXCEPT updates. Each increments `step`. The final invariant `EndsCorrect` checks that the final state matches the expected goal tallies (red=2, blue=2, green=3).
