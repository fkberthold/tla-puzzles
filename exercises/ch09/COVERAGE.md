# Chapter 09 coverage audit

This is an audit of the shipped set against `CHEATSHEET.md`, run after the
exercises were written. It didn't generate them.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises |
|---|---|---|
| 1 | Invariants are one shape of temporal property, and `[]` composes | Ex1 |
| 2 | Safety and liveness, and safety properties that aren't invariants | Ex1 |
| 3 | Behaviors can stutter for ever, which breaks liveness and no invariant | Ex2, Ex4 |
| 4 | Fairness rules out infinite stuttering, weak against strong | Ex2, Ex3 |
| 5 | `<>`, `<>[]`, `[]<>` and `~>` built on top of `[]` | Ex4, Ex5 |
| 6 | Liveness costs more, and TLC restricts what you can pair it with | Ex3, Ex4, in part |

Themes 1 to 5 have at least one exercise each. Theme 6 is covered in two of its
four parts, and the reasoning is below.

## Theme 6 is covered in two parts of four

The sheet's sixth theme has four claims in it. Liveness checking is slower, it
can't use symmetry sets, TLC can't say which property failed, and the error
traces are longer.

Two of those are exercised.

**No symmetry sets** is Ex3's closing aside, and it's the one finding in this set
I'd call load-bearing. `LoadingBay.tla` defines `Perms == Permutations(Hauliers)`
and the config deliberately doesn't name it. Adding `SYMMETRY Perms` to the
config of the correct `fair+` spec, which passes, turns the verdict into
`LIVENESS_VIOLATION`. TLC prints no warning about the pairing. The counterexample
it offers is a behavior where one haulier loops for ever and the other never
docks, and that behavior isn't real. Symmetry folded the two hauliers together,
so the run explored 2 distinct states where the honest run explores 3, and
`bay = h1` and `bay = h2` became the same state. The chapter says you cannot use
symmetry sets with liveness properties. What it doesn't say, and what I think
matters more, is that the tool won't stop you and won't tell you afterwards.

**TLC can't say which property failed** shapes Ex4's structure rather than
appearing as a claim in it. One module defines three properties and ships three
configs, one property each, and the exercise text says why. A single config
naming all three would report that a temporal property broke and leave the
learner guessing which.

Two parts are omitted. That liveness checking is slower, and that its traces are
longer, are both true and neither is a pass-fail outcome. Every model in this set
is small enough that the slowness doesn't show, and every trace is short enough
to read. Building a model big enough to feel the cost would push each exercise
well past 15 minutes and would grade on wall-clock time, which varies by machine.
I think that part of the theme belongs with material that has a real state space
to shrink, and it wants a different kind of exercise than a verdict.

## The `\E x: [](P(x))` shape is omitted on purpose

Theme 1 says `[]` composes with `\/`, `=>` and quantifiers. Ex1 uses the `=>`
composition and doesn't use the other two. The chapter's own worked example for
this theme is `\E s \in Servers: [](s \in online)`, and the chapter closes by
saying you probably won't ever need to write a property of that form. Ex1 gets
the same lesson from `[](P => []P)`, which is a shape people do write, and which
carries the safety-but-not-an-invariant point just as cleanly. Reusing the
chapter's shape would also have meant reusing the chapter's example.

## Constructs

All 8 constructs on the sheet appear in at least one exercise.

| Construct | Exercises |
|---|---|
| `[]` (always) | Ex1, and inside the composites in Ex4 |
| `PROPERTY` | all five |
| `fair process` (weak fairness) | Ex2, Ex3, Ex4, Ex5 |
| `fair+` (strong fairness) | Ex3 |
| `<>` (eventually) | Ex2, Ex4 |
| `<>[]` (eventually always) | Ex4 |
| `[]<>` (always eventually) | Ex3, Ex4 |
| `~>` (leads-to) | Ex5 |

## Scope

Nothing in this set uses a construct from above chapter 9.

From chapter 8: `process`, process sets (`process (H \in Hauliers)`), `self`,
and `await`. From chapter 5: `CONSTANT`, model values, and `Permutations` for
the symmetry aside. From chapter 4: `define` blocks and invariants. From chapters
2 and 3: `either`, `with`, `while`, `if`, sets, `Cardinality`, and `\A`.

One caveat on the scope claim, the same one chapter 3's audit records. The
committed translations contain `EXCEPT`, which belongs to chapter 6, because
that's how `pcal` compiles an update to one element of `pc`. No learner writes
it and no exercise asks anyone to read it.

`Ex5` uses `\subseteq` and `\union` from chapter 2, and `Cardinality` from
chapter 2's `FiniteSets`.

## Overlap with the chapter's worked examples

Checked, and listed in `reports/authoring.md`. No exercise reuses the
orchestrator and its `online` server set, the threads competing for a lock, the
threads counter with `<>(counter = 2)`, the inbound task pool handed to workers,
or the hour clock striking midnight.
