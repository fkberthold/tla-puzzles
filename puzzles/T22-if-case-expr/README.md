# T22: IF/THEN/ELSE Expressions and CASE ⭐

## Lesson: Conditional EXPRESSIONS (Not Statements)

T01 used `if`/`else` as a STATEMENT in PlusCal — branching the execution flow:

```
if (light = "off") {
  light := "on";
} else {
  light := "off";
}
```

T22 introduces conditional EXPRESSIONS, which evaluate to a value:

```
IF p THEN e1 ELSE e2
```

Used inside an expression, not as a statement. The `ELSE` is **mandatory** — every IF expression must have one. (Unlike statement form, where `else` is optional.)

```
size == IF Cardinality(s) > 5 THEN "big" ELSE "small"     \* a string-valued expression
factor == IF n > 0 THEN n ELSE -n                          \* an integer-valued expression: |n|
status == [color |-> "blue", height |-> IF tall THEN 6 ELSE 5]   \* inside a record value
```

You'll use `IF/THEN/ELSE` constantly inside `define` bodies, function constructors, and record fields.

**`CASE` for multi-branch.** When you have many cases, nested `IF`s get ugly. `CASE` cleans them up:

```
CASE p1 -> e1
  [] p2 -> e2
  [] p3 -> e3
  [] OTHER -> default
```

The `[]` separates branches (read it as "or"). `OTHER` is the catch-all, like `else`. The branches are checked in order; the first matching one wins.

```
classification ==
  CASE temp < 32 -> "freezing"
    [] temp < 65 -> "cold"
    [] temp < 80 -> "warm"
    [] OTHER -> "hot"
```

If you omit `OTHER` and no branch matches, the result is undefined — TLC will error. So when in doubt, include `OTHER`.

**Statement vs. expression — keep them straight:**

```
\* PlusCal statement (T01-style): branches CONTROL FLOW, optional else
if (cond) { x := 1; } else { x := 2; };

\* TLA+ expression: evaluates to a VALUE, mandatory ELSE
y := IF cond THEN 1 ELSE 2;
```

Both are useful. The expression form is simpler when you just want to compute a value; the statement form is needed when the branches do different SIDE EFFECTS (assigning different variables, jumping with `goto`, etc.).

**Worked example — a paint mixing recipe.**

A paint shop computes how much pigment to add based on the color category. The recipe is a single expression (multiple branches → use `CASE`).

```
(*--algorithm Paint {
  variables base = 100, color = "red", pigment = 0;

  define {
    \* Pigment per liter of base, computed from the color category.
    DropsPerLiter ==
      CASE color = "red"   -> 5
        [] color = "blue"  -> 3
        [] color = "green" -> 4
        [] OTHER           -> 2     \* fallback for any other color

    Total == base * DropsPerLiter

    \* IF expression for a binary classification:
    Strength == IF DropsPerLiter >= 4 THEN "vibrant" ELSE "subtle"
  }

  fair process (mixer = "Mixer") {
    mix:
      pigment := Total;
  }
}*)
```

Sample invariants:

- `TypeOK == base \in 0..1000 /\ color \in {"red", "blue", "green", "yellow"} /\ pigment \in 0..5000`
- `RedIsVibrant == color = "red" => Strength = "vibrant"` — passes; red has 5 drops/liter, which is >= 4

`CASE` makes the recipe table-like and easy to extend. `IF/THEN/ELSE` shines for the binary "yes/no" classification.

## Setup

A traffic light controller computes its display state based on a simple counter that ticks 0..5. The mapping:

- ticks 0–1: light is `"red"`
- tick 2: light is `"yellow"`
- ticks 3–5: light is `"green"`

The display also reports a binary flag — whether the light is currently `"go"` (green) or not.

You'll express the mapping in two ways:

1. The light color via a `CASE` expression.
2. The "go" flag via an `IF/THEN/ELSE` expression.

## Task

Write a PlusCal spec with:

- A variable `tick` starting at `0`
- A variable `display` starting at `"red"`
- A variable `goFlag` starting at `FALSE`

In the `define` block:

- `Color(t) ==`
  ```
  CASE t \in {0, 1} -> "red"
    [] t = 2        -> "yellow"
    [] t \in {3, 4, 5} -> "green"
    [] OTHER        -> "off"
  ```
- `IsGo(t) == IF Color(t) = "green" THEN TRUE ELSE FALSE`
- `TypeOK == tick \in 0..5 /\ display \in {"red", "yellow", "green", "off"} /\ goFlag \in BOOLEAN`
- `DisplayMatches == display = Color(tick)`
- `GoMatches == goFlag = IsGo(tick)`

A single fair process:

1. **advance**: while `tick < 5`, set `display := Color(tick + 1)`, `goFlag := IsGo(tick + 1)`, then `tick := tick + 1`.

## Check

1. **TypeOK** — see above.
2. **DisplayMatches** — at every reachable state, `display` agrees with `Color(tick)`.
3. **GoMatches** — `goFlag` agrees with `IsGo(tick)`.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **7 distinct states** (one per `tick` value 0–5, plus a terminal "Done" state). Your deterministic spec will likely match.
- Trace through by hand: at tick 2, `display = "yellow"` and `goFlag = FALSE`. At tick 4, `display = "green"` and `goFlag = TRUE`.

**Bonus.** Replace the `CASE` with a nested `IF/THEN/ELSE`. Confirm TLC still gets the same answers. The `CASE` is just sugar for nested `IF`s — same semantics, prettier with many branches.

## Hints

??? hint "💡 Hint 1 — IF/THEN/ELSE evaluates to a value"
    `IF p THEN e1 ELSE e2` is an EXPRESSION that returns either `e1` or `e2` depending on whether `p` holds. The ELSE is MANDATORY. So `display := IF tick = 0 THEN "red" ELSE "green"` assigns a color based on the tick. Use this inside assignments, operators, records — anywhere you need a computed value.

??? hint "💡 Hint 2 — CASE for multi-way branches"
    `CASE cond1 -> result1 [] cond2 -> result2 [] OTHER -> default` evaluates conditions in order and returns the FIRST result whose condition holds. `OTHER` is the catch-all, like `else`. Use `CASE` when you have many cases; use `IF` when you have two.

??? hint "💡 Hint 3 — Two phases: define operators, then use in loop"
    The `define` block sets up `Color(t)` and `IsGo(t)` as operators that compute the light color and go-flag from a tick value. The `advance` loop sets `display`, `goFlag`, and `tick` all in one label — PlusCal evaluates all right-hand sides using the OLD values simultaneously, so using `tick + 1` as the argument to `Color` and `IsGo` correctly computes the next-tick display before tick advances.
