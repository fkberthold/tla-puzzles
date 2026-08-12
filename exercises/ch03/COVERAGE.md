# Chapter 03 coverage audit

This is an audit of the shipped set against `CHEATSHEET.md`, run after the
exercises were written. It didn't generate them.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises |
|---|---|---|
| 1 | PlusCal compiles through a translation step, and TLC runs the translation | Ex2, Ex3 |
| 2 | A label marks one atomic step, and placement decides concurrency | Ex4, Ex3 |
| 3 | Every statement belongs to a label, one update per label, `\|\|` for the rest | Ex4, Ex1 |
| 4 | Each PlusCal construct carries its own labeling rule | Ex3, Ex5, Ex1 |
| 5 | `\in` on a declaration runs the model over a whole set | Ex1, Ex5 |
| 6 | Run stats show whether the check explored what you expected | Ex5, in part |

Every theme has at least one exercise. Theme 6 has one with a caveat, below.

## Theme 6 is covered by half

The sheet's sixth theme is diameter, states found, distinct states, and
per-label counts. This set covers the last of those and omits the other
three, on purpose.

The chapter's own use of the counts is a fingerprint: transcribe the spec,
compare your number against the author's, and suspect a typo if they differ.
That's a good reader's check and a bad exercise outcome. A state count is a
fact about one encoding of a model, so a learner who declares a variable in a
different order, or names a label differently, or runs a TLC that folds
initial states differently, gets a different number while being entirely
right. An exercise that grades on it would be grading the representation.
Every outcome in this set is a TLC verdict for that reason.

The part of theme 6 that survives the constraint is the chapter's own line
about per-label counts: if one label has 0 states, there's probably a bug.
Ex5 asks exactly that question and answers it with a verdict rather than a
number. Put `assert FALSE` in the label you're asking about. An `OK` means
the label never ran. That's the same finding the per-label count gives, and
it says the same thing on any machine.

What stays uncovered is the reader's habit of watching diameter and distinct
states grow as a model gets bigger. I think that belongs with the chapters
that make state spaces big enough to be worth watching, and it wants a
different kind of material than a pass-fail exercise.

## Constructs

All 12 constructs on the sheet appear in at least one reference.

| Construct | Exercises |
|---|---|
| `--algorithm` block | all five |
| `:=` assignment | all five |
| label | all five |
| `\|\|` simultaneous assignment | Ex4 |
| `skip` | Ex5 |
| `assert` | Ex1, Ex2, Ex4, Ex5 |
| `goto` | Ex3 |
| PlusCal `if` | Ex1, Ex5 |
| `macro` | Ex1 |
| `with` | Ex4 |
| `while` | Ex1 |
| `\in` on a variable declaration | Ex1, Ex5 |

## Scope

Nothing in this set uses a construct from above chapter 3. No `INVARIANT` or
`PROPERTY` appears in any `.cfg`, which is why every check runs through
`assert` (chapter 4 owns invariants). No `CONSTANT` (chapter 5). No structs
or function literals (chapter 6). Everything else comes from the chapter 2
sheet: `EXTENDS`, integers, strings, booleans, sequence literals with
indexing, and `a..b` as a set.

`Cardinality`, `Len`, and the `Sequences` operators are all available from
chapter 2 and go unused here. That's incidental rather than deliberate.

One caveat on the scope claim. The committed translations contain `EXCEPT`,
which belongs to chapter 6, because that's how `pcal` compiles an update to
one element of a sequence. The chapter's own duplication checker produces the
same thing. No learner writes it, and no exercise asks anyone to read it.

## Overlap with the chapter's worked examples

Checked, and listed in `reports/authoring.md`. No exercise reuses the
duplication checker, the two-label `pluscal.tla` warm-up, the sequence-sum
loop, the `inc` macro, the `tmp_x`/`tmp_y` swap, or the `x \in 1..1000`
collapse illustration.
