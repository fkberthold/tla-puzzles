# Coverage audit: ch06 exercise set

Audited against the six major themes and seven constructs in
`exercises/ch06/CHEATSHEET.md`. This file is an audit run after the set was
written. It's not the thing that generated the set.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises | Verdict |
|---|---|---|---|
| 1 | Structs are functions from string keys to values. `[a \|-> 1]` builds one, `.a` or `["a"]` reads one, `[key: set]` builds the set of them | 1, 2 | covered |
| 2 | `DOMAIN` is the one operation that works on sequences, structs, and functions alike. The reveal of the chapter | 1, 2, 4, 5 | covered |
| 3 | A function literal `[x \in S \|-> expr]`, called with `f[x]`, reaching past single-argument mappings | 2, 3, 4, 5 | covered |
| 4 | Function sets `[S -> T]` type a function the way `1..10` types a number | 3, 4, 5 | covered in part |
| 5 | `:>` and `@@` build and merge functions piece by piece | 2, 4 | covered |
| 6 | The chapter's closing worked examples: `Zip`, `Sort` via `CHOOSE`, and the duplicate-checker rewrite that buys state sweeping | 3 | covered in part |

Theme 2 carries the chapter, so it's exercised four different ways. Exercise 2
is the one built for it, and it's the predict-then-check, because the reveal
only lands if you commit to a wrong answer first.

## The two partial rows

**Theme 4, function sets.** Three exercises type a variable with `[S -> T]`,
and exercise 3 makes the type depend on a swept variable. Two sub-points from
the sheet's theme line aren't touched.

The first is building a function set from a filtered or mapped set, the sheet's
"narrow the type further". The chapter teaches it with the
`LeqTwoCPUs == {set \in SUBSET CPUs: Cardinality(set) <= 2}` example, and its
own advice one paragraph later is to keep the type invariant simple and write
the restriction as a second invariant instead. An exercise drilling the form the
chapter recommends against seemed like the wrong thing to teach, so I left it
out. I think it's the weakest omission here, and a sixth exercise could take it.

The second is the size rule, `#T` to the power of `#S`. It's arithmetic about a
function set rather than anything you write in a spec, and the harness reports
verdicts rather than state counts, so there's no honest way to check a learner's
answer through `verdict.sh`. It belongs in the cheat sheet, not in an exercise.

**Theme 6, the closing worked examples.** This row is the one place where full
coverage and a clean exercise set pull against each other.

`Zip` and `Sort` are the chapter's own worked code. Building an exercise around
either means handing back the chapter's answer with the variable names changed,
which teaches recall rather than the construct. So both are out on purpose, and
the review checklist item they'd have failed is "no exercise is a near-copy of
the chapter's running examples".

State sweeping is the part of that section that transfers, and exercise 3 takes
it. The chapter demonstrates sweeping over a sequence's length,
`n \in 1..Size` driving `seq \in [1..n -> S]`. Exercise 3 sweeps the other
parameter the chapter's tip names but never shows, the ceiling on a bounded
value, so `ceiling` drives the codomain of `dial` while the domain stays fixed.
Same technique, different half of it.

## Constructs

All seven constructs on the sheet appear in at least one exercise.

| Construct | Exercises |
|---|---|
| struct literal | 1, 2 |
| struct set | 1 |
| `DOMAIN` | 1, 2, 4, 5 |
| function literal | 2, 3, 4, 5 |
| `:>` | 2, 4 |
| `@@` | 2, 4 |
| function set | 3, 4, 5 |

`:>` and `@@` need `EXTENDS TLC`, which the sheet's own review flagged as a
defect in the sheet. Both exercises that use them extend `TLC`, and exercise 4
says so in the task text.

## Scope

Every construct used across the five exercises comes from chapters 2 to 6,
checked against the `ch02` through `ch06` sheets. The full check is in
`reports/authoring.md`.
