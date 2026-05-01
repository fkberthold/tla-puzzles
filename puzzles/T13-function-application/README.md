# T13: Functions — Application and DOMAIN ⭐

## Lesson: Reading from a Function

T12 BUILT a function with `[x \in S |-> e]`. T13 READS from one.

**Application uses square brackets, NOT parens:**

```
square == [n \in 0..3 |-> n * n]
square[2]      \* 4         (correct)
square(2)      \* SYNTAX ERROR — that's how OPERATORS are called, not functions
```

This trips up programmers used to `f(2)`. In TLA+, `f(2)` would mean "the operator `f` applied to argument 2." If `f` is a FUNCTION (a value), you write `f[2]`.

**`DOMAIN f` returns the domain set:**

```
DOMAIN square                  \* {0, 1, 2, 3}
DOMAIN [name |-> "Ada", age |-> 36]    \* {"name", "age"}   (records too — same machinery)
```

You can iterate over `DOMAIN f` to do something with every entry.

**Functions are VALUES, not procedures.** A function doesn't "run" or "compute" — it's a finite mapping that already exists. `f[x]` is "look up the value of `f` at `x`," not "call `f` with argument `x`."

**Worked example — a roster of jersey numbers.**

A coach has a function from each player's name to their jersey number. The coach inspects entries and sums all the numbers.

```
(*--algorithm Roster {
  variables
    jersey = [p \in {"alex", "blair", "casey"} |-> 0],
    total = 0;

  define {
    Players == DOMAIN jersey
    Sum(f) == \* sum of all values in the function f, over a fixed 3-player domain
      f["alex"] + f["blair"] + f["casey"]
  }

  fair process (coach = "Coach") {
    assign:
      jersey := [p \in {"alex", "blair", "casey"} |->
                  IF p = "alex" THEN 7 ELSE IF p = "blair" THEN 11 ELSE 23];
    tally:
      total := Sum(jersey);
  }
}*)
```

Sample invariants:

- `TypeOK == \A p \in Players : jersey[p] \in 0..30 /\ total \in 0..90`
- `TallyMatches == total > 0 => total = jersey["alex"] + jersey["blair"] + jersey["casey"]`

Three things to keep straight:

1. **`f[x]`** is application — square brackets.
2. **`DOMAIN f`** is the input set — useful for iterating, for typing invariants, for checking that two functions agree on their domain.
3. **Records are just functions over strings.** `r.name` and `r["name"]` both work. (TLA+'s record-dot is sugar for the second.)

(Note for the puzzle: the IF/THEN/ELSE expression appears here as a peek ahead — T22 will treat it formally. For now: `IF p THEN x ELSE y` evaluates to `x` when `p` holds, otherwise to `y`. Always mandatory ELSE.)

## Setup

A library has a function tracking how many copies of each book it owns. The librarian wants to:

1. Look up the count for one specific title.
2. Compute the total number of books across all titles.
3. Confirm that the set of titles tracked is the expected set.

You won't UPDATE the function in this puzzle (T14 introduces that). You'll only READ from it.

## Task

Write a PlusCal spec with:

- A variable `inventory` initialized to:
  ```
  [t \in {"alpha", "beta", "gamma"} |->
    IF t = "alpha" THEN 4 ELSE IF t = "beta" THEN 2 ELSE 7]
  ```
- A variable `looked_up` starting at `0` (will hold the count of one title)
- A variable `total` starting at `0` (will hold the sum)
- A variable `phase` starting at `0`

A single fair process runs three labels:

1. **lookOne**: set `looked_up := inventory["beta"]`. Increment `phase`.
2. **sumAll**: set `total := inventory["alpha"] + inventory["beta"] + inventory["gamma"]`. Increment `phase`.
3. **finish**: increment `phase`.

In the `define` block:

- `Titles == DOMAIN inventory`
- `Count(t) == inventory[t]` — small reusable wrapper (just function application)
- `TypeOK == Titles = {"alpha", "beta", "gamma"} /\ \A t \in Titles : inventory[t] \in 0..10 /\ phase \in 0..3 /\ looked_up \in 0..10 /\ total \in 0..30`
- `LookedUpCorrect == phase >= 1 => looked_up = 2`
- `TotalCorrect == phase >= 2 => total = 13`
- `TitlesStable == Titles = {"alpha", "beta", "gamma"}` — the domain doesn't change

## Check

1. **TypeOK** — see above.
2. **LookedUpCorrect** — once `lookOne` runs, `looked_up` is 2 (the value at `"beta"`).
3. **TotalCorrect** — once `sumAll` runs, `total` is 13 (4 + 2 + 7).
4. **TitlesStable** — the function's domain never changes.

## Expected Result

- TLC reports **4 distinct states** (one per phase value).
- All four invariants pass.

**Bonus.** What does `inventory["delta"]` evaluate to? Try writing `bad := inventory["delta"]` somewhere and see TLC's error message — it tells you the application is out of domain. This is a common bug.
