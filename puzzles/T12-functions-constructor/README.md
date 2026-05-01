# T12: Functions — Constructor ⭐

## Lesson: The Function Constructor `[x \in S |-> e]`

In T09 you met records — `[name |-> "Ada", age |-> 36]`. A record is just a special case of a more general thing: a FUNCTION. A function maps each value in some DOMAIN set to a value.

**The general function constructor:**

```
[x \in S |-> e]
```

Read this as: "the function whose domain is `S`, and which sends each `x` in `S` to `e` (the body, possibly mentioning `x`)."

```
square == [n \in 0..3 |-> n * n]
\* square[0] = 0, square[1] = 1, square[2] = 4, square[3] = 9
\* DOMAIN square = {0, 1, 2, 3}
```

Compare:

- **Operator definition:** `Square(n) == n * n`. A rule. Takes any input. Not a value you can store.
- **Function value:** `square == [n \in 0..3 |-> n * n]`. A finite mapping. A VALUE — assignable, comparable, with a fixed `DOMAIN`. TLC can fully enumerate it.

For TLC's sake, the domain `S` must be FINITE. (`Nat` won't fly. `0..3` will.)

**Records are functions over a string domain.** `[name |-> "Ada", age |-> 36]` is sugar for a function whose domain is `{"name", "age"}`. The record constructor and the function constructor are related — but the function constructor lets the domain be any set, not just strings.

**Worked example — a school's seating chart.**

A teacher assigns each student to a desk number. The class is `{"alex", "blair", "casey"}`. The teacher starts with everyone at desk 1, then re-seats them (every student gets a new desk, computed from their name length).

```
(*--algorithm Classroom {
  variables seating = [s \in {"alex", "blair", "casey"} |-> 1];

  define {
    Students == DOMAIN seating
    AllSame == \A s \in Students : seating[s] = seating["alex"]
  }

  fair process (teacher = "Teacher") {
    reseat:
      \* Build a new function from the same domain.
      seating := [s \in {"alex", "blair", "casey"} |-> Len(s)];
  }
}*)
```

Sample invariants:

- `TypeOK == DOMAIN seating = {"alex", "blair", "casey"} /\ \A s \in DOMAIN seating : seating[s] \in 1..10`
- After `reseat`, `seating["alex"] = 4`, `seating["blair"] = 5`, `seating["casey"] = 5`. Initially they're all 1.

What `[s \in S |-> e]` actually does:

1. The set `S` becomes the DOMAIN.
2. For each `s` in `S`, the function maps `s` to `e` (which can mention `s`).
3. The whole thing is a single VALUE — a function — that you assign to a variable.

You'll see `Len(s)` in the lesson. `Len` is from the `Sequences` module and treats a string like `"alex"` as a sequence of characters of length 4.

(NOTE: This puzzle introduces the function constructor `[x \in S |-> e]`. The `EXCEPT` operator for updating one entry comes in T14.)

## Setup

A weather station tracks the temperature reading at three stations: `"north"`, `"south"`, and `"east"`. Initially all readings are 50 (the calibration value). After taking measurements, every station's reading becomes the same constant — say 65.

You'll model this with a function whose domain is the set of station names.

## Task

Write a PlusCal spec with:

- A variable `readings` initialized via the function constructor:
  `[s \in {"north", "south", "east"} |-> 50]`
- A variable `calibrated` starting at `FALSE`

A single fair process runs one label:

1. **measure**: rebuild the whole reading function so every station reads 65, AND set `calibrated := TRUE`.

   ```
   readings := [s \in {"north", "south", "east"} |-> 65];
   calibrated := TRUE;
   ```

In the `define` block:

- `Stations == DOMAIN readings` — the domain of the function
- `AllSame == \A s \in Stations : readings[s] = readings["north"]`
- `TypeOK == \A s \in Stations : readings[s] \in 0..100`

(`\A x \in S : P` is "for all `x` in `S`, `P` holds." You'll meet quantifiers properly in T24; for now treat them as a way to say "every entry of the function satisfies P.")

## Check

1. **TypeOK** — every reading is in 0..100.
2. **AllSame** — every station has the same reading at every reachable state. Initially they're all 50. After `measure`, they're all 65.
3. **DomainStable**: `Stations = {"north", "south", "east"}` — the domain never changes (you replaced the function value, but the new one has the same domain).

## Expected Result

- TLC reports **2 distinct states** — one before `measure`, one after.
- All three invariants pass.

**Bonus.** Replace the `measure` body with a non-uniform rebuild, like:

```
readings := [s \in {"north", "south", "east"} |->
              IF s = "north" THEN 70 ELSE 65];
```

Predict whether `AllSame` still holds. Run TLC. Confirm the violation. (You'll see the IF/THEN/ELSE expression formally in T22.)
