# T18: Set Comprehension — Map ⭐

## Lesson: Transforming a Set Through an Expression

T17 introduced FILTER comprehension: `{x \in S : P(x)}` keeps elements that pass a predicate. T18 introduces the second form, MAP comprehension: produce a NEW set by applying an expression to each element.

The map shape:

```
{ E(x) : x \in S }
```

Read aloud: "the set of `E(x)` where `x` ranges over `S`." The expression comes BEFORE the colon; the binding AFTER. (Compare with filter: filter has the binding before, predicate after.)

```
{n * n : n \in 1..4}              \* {1, 4, 9, 16}
{Len(s) : s \in {"hi", "tla", ""}}  \* {0, 2, 3}
{[name |-> g, sleep |-> 8] : g \in {"alice", "bob"}}    \* a set of records, one per guest
```

The two comprehension shapes side by side:

```
\* FILTER: keep elements of S where predicate holds — same elements, fewer of them
{x \in S : P(x)}

\* MAP: transform each element of S with E — new elements
{E(x) : x \in S}
```

You can think of map as "apply this function to every element," and filter as "keep the elements that pass this test." (Programmers from other languages may recognize them as the standard `map` and `filter` operations.)

**Sets ABSORB DUPLICATES.** If two different `x`s produce the same `E(x)`, the result has only one copy. `{n*n : n \in {-2, -1, 1, 2}}` is `{1, 4}`, not `{1, 1, 4, 4}`.

**Worked example — generating a price list from a base value.**

A coffee shop offers three sizes — `"small"`, `"medium"`, `"large"` — each priced at `base * factor`. The factors live in a function. The shop manager wants the SET of all prices charged at the menu (regardless of which size).

```
(*--algorithm Coffee {
  variables base = 3, prices = {};

  define {
    Sizes == {"small", "medium", "large"}
    Factor(s) == IF s = "small" THEN 1 ELSE IF s = "medium" THEN 2 ELSE 3
    AllPrices == {base * Factor(s) : s \in Sizes}    \* MAP: compute each price
  }

  fair process (manager = "Mgr") {
    publish:
      prices := AllPrices;
  }
}*)
```

Sample invariants:

- `TypeOK == prices \subseteq 0..30 /\ base \in 1..10`
- `PricesSet == prices = {} \/ prices = {3, 6, 9}` — before publish, empty; after, the three multiples of 3

The map `{base * Factor(s) : s \in Sizes}` runs over `{"small", "medium", "large"}`, evaluates `base * Factor(s)` for each, and gathers the results into a set.

**Map and filter in one expression.** TLA+ doesn't directly support "filter then map" in one comprehension — but you can nest:

```
{n * n : n \in {k \in 1..10 : k > 5}}     \* squares of 6..10 → {36, 49, 64, 81, 100}
```

The inner `{k \in 1..10 : k > 5}` is the filter; the outer `{n*n : n \in ...}` is the map. T17's filter still comes in handy.

## Setup

A school maintains a function `level` that maps each student to a grade level. The principal wants the set of all grade levels currently represented — useful for planning classrooms. You'll produce this with a single map comprehension.

## Task

Write a PlusCal spec with:

- A variable `level` initialized to:
  ```
  [s \in {"sam", "tess", "uri", "val"} |->
    IF s = "sam" THEN 9 ELSE IF s = "tess" THEN 11 ELSE IF s = "uri" THEN 9 ELSE 12]
  ```
- A variable `gradesPresent` starting at `{}` (the set of level numbers in use)
- A variable `phase` starting at `0`

A single fair process runs two labels:

1. **derive**: set `gradesPresent := {level[s] : s \in DOMAIN level}`. Increment `phase`.
2. **finish**: increment `phase`.

In the `define` block:

- `Students == DOMAIN level`
- `TypeOK == Students = {"sam", "tess", "uri", "val"} /\ gradesPresent \subseteq 9..12 /\ phase \in 0..2`
- `EndsCorrect == phase = 2 => gradesPresent = {9, 11, 12}`
- `EveryGradeIsAStudentsGrade == \A g \in gradesPresent : \E s \in Students : level[s] = g`
  \* every value in `gradesPresent` is somebody's level — by construction.

## Check

1. **TypeOK** — see above.
2. **EndsCorrect** — after `derive`, `gradesPresent` has the three distinct levels (sam and uri are both 9 — the duplicate is absorbed).
3. **EveryGradeIsAStudentsGrade** — by construction of the map.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **3 distinct states** (one per `phase` value). Your deterministic spec will likely match this count.
- Notice: `level` has 4 students but `gradesPresent` ends up as a 3-element set. The map absorbs the duplicate level 9.

**Bonus.** What's `{level[s] : s \in {}}`? Predict (a map over an empty domain). Then write it as an operator and run TLC to confirm.

## Hints

??? hint "💡 Hint 1 — Map syntax: expression before colon"
    The map `{E(x) : x \in S}` puts the EXPRESSION (`E(x)`) BEFORE the colon, and the BINDING (`x \in S`) AFTER. Read it as "the set of E(x) for each x in S." You apply the expression to each element and collect the results. If two elements produce the same result, the set absorbs the duplicate.

??? hint "💡 Hint 2 — Transforming via function lookup"
    Your map is `{level[s] : s \in DOMAIN level}` — for each student `s`, look up `level[s]` (the grade level), and collect all those numbers into a set. Since `level` maps 4 students to grades, and two students are in grade 9, the result is a 3-element set `{9, 11, 12}` (no duplicate 9).

??? hint "💡 Hint 3 — One label to derive, one to finish"
    The `derive` label computes the map and assigns it to `gradesPresent`. The `finish` label just increments `phase`. The map is computed once and stored — no nondeterminism. The invariant `EndsCorrect` checks that after both labels run, `gradesPresent = {9, 11, 12}`.
