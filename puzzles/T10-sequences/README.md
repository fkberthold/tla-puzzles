# T10: Sequences — Literal, Append, 1-Indexed Access ⭐

## Lesson: Sequences — Ordered Lists

A SEQUENCE is an ordered, finite list of values. You write a literal with double angle brackets:

```
<<7, 11, 13>>
```

The empty sequence is `<<>>`.

You access an element with **square brackets**, **1-indexed**:

```
s == <<7, 11, 13>>
s[1]      \* 7   (first element, NOT s[0]!)
s[2]      \* 11
s[3]      \* 13
```

**Sequences are functions.** Their domain is `1..Len(s)`. So `DOMAIN <<7, 11, 13>>` is `{1, 2, 3}`. Indexing is just function application.

The Sequences module provides operators (you must `EXTENDS Sequences`):

```
Len(<<7, 11, 13>>)         \* 3
Head(<<7, 11, 13>>)        \* 7      (first element)
Tail(<<7, 11, 13>>)        \* <<11, 13>>   (everything except the first)
Append(<<7, 11>>, 13)      \* <<7, 11, 13>>   (add one to the END)
```

**Worked example — a recipe ingredient log.**

A chef adds ingredients one at a time to a pot. The first one added gets sautéed (it sat in the hot pan longest). The chef wants the count and the latest addition.

```
(*--algorithm Recipe {
  variables ingredients = <<"oil">>, additions = 0;

  define {
    Total == Len(ingredients)
    First == Head(ingredients)
    Latest == ingredients[Len(ingredients)]
  }

  fair process (chef = "Chef") {
    cook:
      while (additions < 3) {
        with (i \in {"onion", "garlic", "tomato"}) {
          ingredients := Append(ingredients, i);
        };
        additions := additions + 1;
      }
  }
}*)
```

Sample invariants:

- `TypeOK == Len(ingredients) \in 1..4 /\ additions \in 0..3`
- `OilFirst == First = "oil"` — `Head` always returns the first ingredient added; that was "oil"
- `LatestIsRecent == additions > 0 => Latest \in {"onion", "garlic", "tomato"}` — the LATEST element changes; the FIRST one doesn't

Three things to internalize:

1. **1-indexed.** `s[1]` is the first element. `s[0]` is an error.
2. **`Append` adds to the END.** `Head` and `Tail` look at the FRONT. `Append(s, x)` is `s` followed by `x`.
3. **Sequences ARE functions.** `s[i]` is just function application. `Len(s)` and `DOMAIN s` together describe the structure: `DOMAIN s = 1..Len(s)`.

## Setup

A coffee shop's barista takes orders. Each order is a single string like `"latte"` or `"americano"`. Orders are added to a queue in arrival order. The barista wants:

- the queue's length,
- the FIRST order (the one that's waited longest),
- the LAST order (the most recent),
- a way to drop the first order off the front (Tail) when it's been served.

The shop receives 3 orders, then serves the first one off the front.

## Task

Write a PlusCal spec with:

- A variable `orders` initialized to `<<>>` (empty sequence)
- A variable `served` initialized to `<<>>` (orders that have been served — also a sequence)
- A variable `phase` starting at `0`

The fair process runs in two parts:

1. **take**: while `phase < 3`, append a new order chosen with `with (o \in {"latte", "mocha", "americano"})`, then increment `phase`. (Loop body, three iterations.)
2. **serve**: after the loop, if `Len(orders) > 0`, append `Head(orders)` to `served` and replace `orders` with `Tail(orders)`.

In the `define` block:

- `QueueLen == Len(orders)`
- `NextUp == IF orders = <<>> THEN "none" ELSE orders[1]`   \* uses 1-indexed access
- `MostRecent == IF orders = <<>> THEN "none" ELSE orders[Len(orders)]`
- `TypeOK == QueueLen \in 0..3 /\ Len(served) \in 0..1 /\ phase \in 0..3`

(Note: `Next` is reserved by the PlusCal translator for the next-state relation, so the front-of-queue operator is named `NextUp`.)

## Check

1. **TypeOK** — see above.
2. **ServedOnlyAfterAllTaken**: `Len(served) = 1 => phase = 3` — we only serve after taking all three orders
3. **NoExtraServing**: `Len(served) <= 1` — at most one served (we only serve once)

## Expected Result

- TLC explores every choice of order at each iteration. With 3 orders chosen from 3 options, that's 3^3 = 27 distinct queue contents.
- Total state count is on the order of a few hundred (each queue value × phase × served value).
- All invariants pass.
- Examine TLC's reported state count and depth. Notice how the depth equals the number of labels traversed.

**Bonus.** What is `DOMAIN <<>>`? What is `Len(<<>>)`? Try evaluating them in your head, then write `EmptyDom == DOMAIN orders` as an operator and trace what TLC reports for the initial state.

## Hints

??? hint "💡 Hint 1 — 1-indexed, not 0-indexed"
    Sequences in TLA+ use 1-based indexing. The first element is `s[1]`, not `s[0]`. Remember: `orders[1]` is the first order in the queue. When you refer to "the most recent," think `orders[Len(orders)]` — the element at index equal to the length.

??? hint "💡 Hint 2 — Append adds to the END"
    `Append(s, x)` produces a new sequence with `x` at the end. It does NOT prepend. Head/Tail look at the FRONT: `Head(s)` is the first, `Tail(s)` is everything except the first. `Append(s, x)` is equivalent to `s \o <<x>>` (concatenation).

??? hint "💡 Hint 3 — Two phases: take orders, then serve"
    The `take` label runs inside a `while (phase < 3)` loop, appending each order and incrementing `phase`. After the loop exits, the `serve` label runs exactly once (not in a loop). Check: does the `serve` body need to be inside the while, or AFTER it?
