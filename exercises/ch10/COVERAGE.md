# Chapter 10 coverage audit

This is an audit of the shipped set against `CHEATSHEET.md`, run after the
exercises were written. It didn't generate them.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises |
|---|---|---|
| 1 | `RECURSIVE` must be declared up front, and nothing checks that the recursion ends | Ex5, Ex1 |
| 2 | Recursion on a set needs `CHOOSE`, and that choice is deterministic | Ex1 |
| 3 | Higher-order parameters and `LAMBDA`, which don't combine with recursion | Ex2 |
| 4 | Binary operators come from a fixed symbol set, and cost readability | Ex3 |
| 5 | Bracket functions, which recurse without a `RECURSIVE` keyword | Ex3 |
| 6 | `CASE` tests in order, errors with no match, takes the first of several | Ex4 |

Every theme has at least one exercise, and nothing on the sheet is omitted.
Two themes get an exercise apiece that carries both halves of the theme rather
than one, which is worth spelling out.

Theme 1 splits into a declaration rule and a termination warning, and Ex5 is
built on the split. The starter ships without the declaration, so the first
run is `PARSE_ERROR`. The repair is one line. Then a one-character edit to the
base case makes the recursion unbounded, and the second run is
`SPEC_EVAL_FAILURE` carrying a `Java StackOverflowError`. Both halves land as
measured verdicts rather than as prose.

Theme 6 splits three ways, and Ex4 covers all three. The `Band(1200)` row
tests first-match-wins, since 1200 satisfies three arms. The starter ships
with no `OTHER` and one load that matches nothing, which is the error case.
The second half of the exercise reorders two overlapping arms, which turns the
first-match rule from a fact into a bug you can watch happen.

## Constructs

All 7 constructs on the sheet appear in at least one reference.

| Construct | Exercises |
|---|---|
| `RECURSIVE` | Ex1, Ex5 |
| Higher-order operator parameter | Ex2 |
| `LAMBDA` | Ex2 |
| Custom binary operator | Ex3 |
| Bracket function definition | Ex3 |
| Recursive function definition | Ex3 |
| `CASE` | Ex4 |

## Where the chapter and this build disagree

The sheet says, following the chapter, that a recursive operator and a
higher-order operator don't combine. Measured on the pinned build, that's
narrower than it sounds, and Ex2 teaches the narrow version.

What SANY rejects is the declaration. `RECURSIVE Mapped(_(_), _)` is a parse
error, because `RECURSIVE` accepts bare `_` placeholders only. The failure
arrives at the `(` inside `_(_)` and never reaches the definition.

What SANY accepts is `RECURSIVE Folded(_, _)` above a definition reading
`Folded(Op(_), set)`. That runs, and it recurses, and it applies its operator
argument. The evidence is in `reports/authoring.md`.

So Ex2's side experiment asks for the declaration form, which fails the way
the chapter says. I've left the other form out of the learner-facing text. A
learner who tries it and gets an `OK` has found a real thing, and the
authoring report is where the next author will find it written down.

## Scope

Nothing in this set uses a construct from above chapter 10. `puzzles/` and
chapter 11's action properties, prime, and box action formulas are all absent,
and no `.cfg` in the set names a `PROPERTY`.

Constructs borrowed from earlier chapters, all of them on a sheet at or below
chapter 10:

| Construct | Sheet | Where |
|---|---|---|
| `EXTENDS`, `Integers`, `IF-THEN-ELSE`, `LET-IN` | ch02 | throughout |
| sets, set difference, set map, set filter | ch02 | Ex1, Ex2 |
| `CHOOSE` | ch02 | Ex1 |
| `Cardinality` and `FiniteSets` | ch02 | Ex2 |
| `\A` (universal quantifier) | ch04 | Ex1 |
| `DOMAIN` | ch06 | Ex3 |

`\A` is the one worth flagging. Ex1's whole point is a `CHOOSE` predicate that
names exactly one element, and the natural way to say "the largest" is
`\A d \in crates : c >= d`. The chapter's own example uses the bare `TRUE`
predicate it then warns against, so a set-recursion exercise that never
reaches for a quantifier can't make the warning bite. Chapter 4 is six
chapters back and its sheet is delivered alongside this set, so I've taken it.

No PlusCal appears anywhere in this set. That's not a deliberate exclusion so
much as a consequence of the chapter: these are pure operators, and a
one-state spec is enough to check every one of them.

## Overlap with the chapter's worked examples

Checked, and listed in `reports/authoring.md`. No exercise reuses `SumSeq`,
`SetSum`, `SetToSeq`, `SeqMap`, the `LAMBDA x: x + 1` call, the `++` and `--`
set operators, `Double`, `Factorial`, or `Fizzbuzz`.
