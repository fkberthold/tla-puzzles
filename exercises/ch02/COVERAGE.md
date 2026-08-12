# Chapter 02 coverage audit

An audit of the finished set in `exercises/ch02/EXERCISES.md` against
`exercises/ch02/CHEATSHEET.md`. The sheet claims 21 constructs under 6 major
themes. This document was written after the exercises, not before, so it can
only report what's there.

Source of truth for the sheet is `hwayne/learntla-v2` at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, `docs/core/operators.rst`.

## Major themes

| # | Theme | Exercises |
|---|---|---|
| 1 | Operators with `==`, fixed arity, `IF-THEN-ELSE`, `LET-IN` | 1, and 3 for the conditional |
| 2 | Boolean logic in math symbols, plus bullet-point layout | 2 |
| 3 | Untyped values, `=` and `#` across types, `EXTENDS` | 3 |
| 4 | Sequences, 1-indexed, and the `Sequences` module | 4 |
| 5 | Sets, membership and algebra, and the sets-of-values generators | 5 |
| 6 | `CHOOSE`, map, and filter | 5 |

All six map to at least one exercise. Nothing is omitted at theme level.

Themes 5 and 6 share exercise 5. They're the two halves of the same idea, since
map and filter are what you reach for once a set exists, so I think one
exercise carrying both reads better than two thin ones.

## Constructs

| Construct | Exercises | Written or read |
|---|---|---|
| Operator definition | 1, 2, 3, 4, 5 | written |
| `IF-THEN-ELSE` | 1, 3 | written in 1, read in 3 |
| Equality and inequality | 1, 2, 3, 4, 5 | written |
| `EXTENDS` | 1, 3, 4, 5 | read |
| Integers | 1, 3, 5 | written in 1, read in 3 and 5 |
| Strings | 3, 4, 5 | written |
| Booleans and logical operators | 2 | written |
| Bullet-point boolean notation | 2 | written |
| Implication | 2 | written |
| Sequences | 4, 5 | written |
| Sequence module operators | 4 | written |
| Sets | 5 | written |
| Set relational and algebraic operators | 5 | written, `\union` read |
| `Cardinality` | 5 | read |
| `BOOLEAN` and integer interval | 5 | read |
| Cartesian product | 5 | written |
| `SUBSET` | 5 | written |
| Set map | 5 | written |
| Set filter | 5 | written |
| `CHOOSE` | 5 | written |
| `LET-IN` | 1 | written |

21 of 21 constructs appear somewhere in the set.

## Where "read" is doing work

Five constructs land in the given section or in a pinned check rather than in
an answer block, so the learner reads them and never types them. That's a real
difference in strength and it's worth naming rather than hiding in a tick.

- `EXTENDS`: on every module header, and exercise 3 turns it into a task.
- `\union`: builds `Taken` in the given section of exercise 5.
- `Cardinality`: appears in three pinned checks in exercise 5.
- `BOOLEAN`: one pinned demonstration line in exercise 5.
- `1..3`: the given `Rows` in exercise 5.

`BOOLEAN` is the weakest of the five. It sits in a check the learner is told to
read and not fill in, and I couldn't find a way to make it a written answer
without a sixth exercise. If this set ever grows past five, that's the first
hole to close.

`EXTENDS` is the opposite case. Exercise 3 asks the learner to delete the
`EXTENDS Integers` line and run the result, so the construct gets exercised by
its absence.

## Boundaries held

The sheet sends five topics to other chapters. None of them appears here.

- No PlusCal algorithm blocks or state updates, which are chapter 3.
- No invariants as a taught idea, which is chapter 4. The invariants in these
  references are harness scaffolding, marked as such.
- No `CONSTANT` or model values, which are chapter 5.
- No structures or functions, which are chapter 6.
- No higher-order operators, recursion, or lambdas, which are chapter 10.

Function application syntax does show up, as `seq[n]` and `s[1]`. The sheet
puts sequence indexing in chapter 2 and I've kept to that reading, so no
reference defines a function or uses `DOMAIN`.

## What the chapter's own examples cover, and this set doesn't reuse

The chapter works one long example, a 24-hour clock, plus a handful of short
ones. None of that surface content is reused here. The list is in
`exercises/ch02/reports/authoring.md`.
