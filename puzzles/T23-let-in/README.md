# T23: LET-IN ⭐

## Lesson: Local Definitions Inside an Expression

The `define` block introduces operators that are visible across the WHOLE spec. Sometimes you want a definition that only matters INSIDE one expression. That's `LET-IN`.

```
LET name == expr IN body
```

The `name` is bound to `expr`, and is in scope ONLY in `body`. Outside the body, the name doesn't exist.

```
LET x == 7 IN x + x      \* evaluates to 14
```

You can declare MULTIPLE bindings, separated by whitespace (no semicolons or commas):

```
LET x == 7
    y == x + 1
IN x * y                 \* evaluates to 56
```

Notice: the second binding `y` can REFERENCE the first one (`x`). Bindings are visible to all subsequent bindings and to the body. (They don't see each other recursively unless you use the special `LET ... ==` recursive form, which we won't need.)

You can define operators with parameters inside `LET`, just like in `define`:

```
LET Square(n) == n * n IN Square(3) + Square(4)    \* 25
```

**Why bother?** Three reasons:

1. **Avoid repetition INSIDE one expression.** If a sub-expression appears three times, give it a name once with `LET`.
2. **Keep the `define` block clean.** If a helper is only needed by one operator, hide it inside that operator's `LET`.
3. **Improve readability.** `LET halfFull == Cardinality(s) / 2 IN halfFull > 5` reads better than the unnamed inline expression.

**Worked example — computing a tip on a restaurant bill.**

A diner computes the total bill. The total combines a subtotal, tax, and tip. Tax depends on the subtotal; tip depends on both subtotal and a service-quality factor.

```
(*--algorithm Dinner {
  variables subtotal = 0, total = 0;

  define {
    \* Helper: computes total given a subtotal and a service rating.
    Total(sub, rating) ==
      LET tax    == (sub * 7) \div 100             \* 7% sales tax
          tipPct == IF rating >= 4 THEN 20 ELSE 15
          tip    == (sub * tipPct) \div 100
      IN sub + tax + tip
  }

  fair process (waiter = "Waiter") {
    serve:
      with (s \in {0, 50, 100}) {
        subtotal := s;
      };
    ringUp:
      total := Total(subtotal, 5);    \* always-good service
  }
}*)
```

Sample invariants:

- `TypeOK == subtotal \in {0, 50, 100} /\ total \in 0..200`
- `TipNonneg == total >= subtotal` — tip and tax are non-negative

Inside `Total`, three local names — `tax`, `tipPct`, `tip` — make the formula readable. They go out of scope at `IN`. They never pollute the outer namespace.

**`LET` works everywhere an expression is expected:**

- inside an operator definition (as above)
- inside an invariant
- inside a function constructor body: `[x \in S |-> LET y == ... IN y * x]`
- inside an `IF` branch

That ubiquity is the point: TLA+'s `LET` is the universal "name a thing here" tool.

## Setup

A small e-commerce checkout computes the FINAL price for an item:

- `base` price (the variable, $50 for this puzzle)
- a `discount` percent (e.g. 10 means 10% off)
- a `shipping` cost (a flat number)

The final price is `base - discount_amount + shipping`, where `discount_amount = base * discount / 100`.

You'll write this with `LET` to name the discount amount once.

## Task

Write a PlusCal spec with:

- A variable `base` initialized to `50`
- A variable `discount` initialized to `10`
- A variable `shipping` initialized to `5`
- A variable `final` starting at `0`
- A variable `phase` starting at `0`

In the `define` block:

- `Final(b, d, s) ==`
  ```
  LET discountAmt == b * d \div 100
      subtotal    == b - discountAmt
  IN subtotal + s
  ```
- `TypeOK == base \in 0..100 /\ discount \in 0..100 /\ shipping \in 0..20 /\ final \in 0..200 /\ phase \in 0..2`
- `Correct == phase = 2 => final = Final(base, discount, shipping)`
- `BoundedFinal == final <= base + shipping`  \* discount can't make total negative

A single fair process runs two labels:

1. **compute**: set `final := Final(base, discount, shipping)`. Increment `phase`.
2. **finish**: increment `phase`.

## Check

1. **TypeOK** — see above.
2. **Correct** — once `compute` runs, `final` equals what `Final` returns.
3. **BoundedFinal** — at every state, `final <= base + shipping`. Initially `final = 0 <= 55`; after compute, `final = 50 - 5 + 5 = 50 <= 55`. Both fine.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **3 distinct states** (one per `phase` value). Your spec will be deterministic and likely match.
- The computed final value is **50** (50 base - 5 discount + 5 shipping).

**Bonus.** Move `Final`'s body to the top level of the `define` block (no `LET`). The result should be the same. Now move the helpers `discountAmt` and `subtotal` from inside `LET` to the top level. Why does that pollute the namespace? (Answer: any other operator in `define` could now reference them, even if they're only meaningful for `Final`. `LET` keeps helpers private.)

## Hints

??? hint "💡 Hint 1 — LET introduces local names"
    `LET name == expr IN body` binds `name` to `expr` within `body`. The name is ONLY visible inside `body`; outside, it doesn't exist. Use `LET` when you need a helper that's only used in one place — it keeps the namespace clean.

??? hint "💡 Hint 2 — Multiple bindings, order matters"
    You can write `LET x == 7 \n y == x + 1 IN x * y`. The second binding `y` can reference the first one `x`. Bindings are visible to all later bindings and to the body. Use this to build up complex results step by step.

??? hint "💡 Hint 3 — Compute discount, then subtract from base"
    The `Final` operator takes three arguments: base, discount percent, shipping. Inside `LET`, compute `discountAmt` as `b * d \div 100`, then compute `subtotal` as `b - discountAmt`. Finally, return `subtotal + s`. This builds the result step by step, with intermediate names for clarity.
