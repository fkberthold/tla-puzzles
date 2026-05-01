# T20: Cardinality and FiniteSets ⭐

## Lesson: Counting Elements in a Set

You've used `Cardinality` once already (T04 used it informally), but now we formalize. The operator is in the standard `FiniteSets` module:

```
EXTENDS Integers, FiniteSets, TLC
```

`Cardinality(S)` returns the number of elements in `S`:

```
Cardinality({})                    \* 0
Cardinality({1, 2, 3})             \* 3
Cardinality(0..5)                  \* 6
Cardinality({"a", "b", "a"})       \* 2 — sets absorb duplicates
```

`IsFiniteSet(S)` returns `TRUE` if `S` is finite. Useful for assertions:

```
IsFiniteSet(0..10)         \* TRUE
IsFiniteSet(Nat)           \* FALSE — TLC won't try; this is a logic operator
```

**Where you reach for `Cardinality`:**

- "at most 3 of these" → `Cardinality(busy) <= 3`
- "exactly half present" → `Cardinality(here) = Cardinality(roster) \div 2`
- "the running count of approved items" → `count = Cardinality({i \in items : approved[i]})`

`Cardinality` works on the result of any set expression — including filter and map comprehensions.

**Worked example — a parking lot occupancy.**

A parking lot has 5 spots. Each spot is either empty or occupied. The lot's display shows how many cars are inside.

```
(*--algorithm Lot {
  variables
    occupied = {},                    \* set of occupied spot numbers
    display = 0;

  define {
    Spots == 1..5
    NumOccupied == Cardinality(occupied)
    Full == NumOccupied = 5
    Empty == NumOccupied = 0
  }

  fair process (gate = "Gate") {
    update:
      with (next \in SUBSET Spots) {  \* arbitrarily set occupancy
        occupied := next;
      };
      display := NumOccupied;
  }
}*)
```

Sample invariants:

- `TypeOK == occupied \subseteq Spots /\ display \in 0..5`
- `DisplayMatches == display = NumOccupied`  \* AFTER update; can fail if you use it BEFORE display is set

Notice the small but important detail: `Cardinality(occupied)` is RECOMPUTED every time the operator `NumOccupied` is evaluated. Sets in TLA+ have no "stored" length — `Cardinality` traverses to count.

(For TypeOK, `display \in 0..5` describes the integer range. Combined with `Cardinality`-based invariants, this lets you say things like "the display always shows the truth.")

## Setup

A meeting room has chairs labelled 1 through 6. Some chairs are occupied; others are empty. The room's monitor reports:

- the SET of occupied chair numbers (`occupied`)
- the COUNT of occupied chairs (`count`)
- whether the room is "full" (count = 6)

You'll model a single update where the meeting fills a random subset of chairs, then the monitor reads the count.

## Task

Write a PlusCal spec with:

- A variable `occupied` initialized to `{}`
- A variable `count` starting at `0`
- A variable `phase` starting at `0`

In the `define` block:

- `Chairs == 1..6`
- `NumOccupied == Cardinality(occupied)`
- `IsFull == NumOccupied = 6`
- `TypeOK == occupied \subseteq Chairs /\ count \in 0..6 /\ phase \in 0..2`
- `CountAccurate == phase = 2 => count = NumOccupied`
- `Bound == NumOccupied <= 6`

Add `EXTENDS Integers, FiniteSets, TLC` (FiniteSets gives you `Cardinality`).

A single fair process runs two labels:

1. **fill**: use `with (s \in SUBSET Chairs)` to pick any subset; assign to `occupied`. Increment `phase`.
2. **read**: set `count := NumOccupied`. Increment `phase`.

## Check

1. **TypeOK** — see above.
2. **CountAccurate** — once both labels run, `count` equals the cardinality of the occupied set.
3. **Bound** — there are at most 6 chairs occupied (because `occupied \subseteq Chairs` and Chairs has 6 elements).

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution enumerates all 2^6 = 64 possible occupancy sets, totaling roughly 100+ states. Your label choices may affect the exact count, but invariant satisfaction is what matters.
- Notice that for some explored states, `IsFull` holds (the all-chairs-occupied subset).

**Bonus.** Add the invariant `count \neq NumOccupied`. Predict: does TLC violate it? Where in the trace? (Hint: ANY state before `read` runs has `count = 0` while `NumOccupied` could be anything.)

## Hints

??? hint "💡 Hint 1 — Cardinality counts elements in a set"
    `Cardinality(S)` returns an integer — the number of elements in `S`. So `Cardinality(occupied)` is the count of occupied chairs. Sets absorb duplicates, so `Cardinality({1, 1, 2})` is 2, not 3. Use `Cardinality` to derive a count from a set.

??? hint "💡 Hint 2 — Cardinality is recomputed, not stored"
    TLA+ has no "length" field on sets like some languages do. `Cardinality` traverses the set every time you use it. So `NumOccupied` is an operator that computes fresh each time — if `occupied` changes, `NumOccupied` automatically changes (no update needed).

??? hint "💡 Hint 3 — Two phases: fill, then read"
    The `fill` label uses `with (s \in SUBSET Chairs)` to nondeterministically pick a subset and assign it to `occupied`. This creates many branches (64, one per subset). The `read` label then reads the count into the `count` variable. The invariant `CountAccurate` checks that after `read`, count matches the cardinality.
