# Coverage audit: ch13 exercise set

Audited against the seven constructs and eight themes in
`exercises/ch13/CHEATSHEET.md`. This file is an audit run after the set was
written. It isn't the thing that generated the set.

Four exercises rather than five. Chapter 13 is 173 lines against chapter 12's
462, and its sheet is short to match. Stretching the set to the size of the
other chapters' would mean drilling material the chapter never delivered.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises | Verdict |
|---|---|---|---|
| 1 | Modules matter less for specs than for code. An abstract library, or invariants kept in their own file, are the cases that pay for a split | 1, 3, 4 | covered |
| 2 | Shared TLA+ files belong in the same folder as the spec that uses them. The toolbox can also read from one shared directory | 1, 2, 3, 4 | covered in part |
| 3 | `EXTENDS` and `INSTANCE` both drop a module into the file namespace. One `EXTENDS` line, as many `INSTANCE` lines as you like, and only `INSTANCE` can be made local, named, or parameterized | 1, 2, 3, 4 | covered |
| 4 | `LOCAL` makes a definition private. `LOCAL INSTANCE` makes a whole import private, so the operators stop at this module | 1, 2 | covered |
| 5 | Namespacing is what makes `INSTANCE` worth the trouble. Operators behind `Foo!`, an instance bound inside a `LET`, one module instantiated twice under two names | 1, 3, 4 | covered in part |
| 6 | Two names for one module earns its keep once the module has constants. `WITH` rewrites the operators, a shared constant name passes through by default, a `WITH` clause overrides that | 3, 4 | covered |
| 7 | Partial parameterization leaves a constant open and takes it at the call site | 4 | covered |
| 8 | SOURCE GAP | none | excluded by ruling |

Theme 1 is the chapter's reason for existing and it names two cases. Exercise 1
is the invariants-in-their-own-file case, built for it and for nothing else.
Exercises 3 and 4 are the abstract-library case, and neither library knows what
it's a library of.

Theme 4 gets the predict-then-check, exercise 2, because the reveal only lands
if you've committed to a wrong answer first.

## The two partial rows

**Theme 2, the toolbox's shared library path.** The half that's covered is the
one that matters here. Every module in the set sits in `starters/`, side by
side, and `EXERCISES.md` says up front that this is the chapter's advice rather
than a packaging convenience. Every how-to-run command names one module and
resolves the rest from the directory it sits in, so a learner sees the rule
work four times.

The half that isn't covered is the toolbox preference for a shared directory.
This project runs TLC from the command line, so there's no toolbox to set a
preference in, and a drill on it would be a drill on a program the learner isn't
running. I think that's a clean omission rather than a gap.

**Theme 5, the `LET`-bound instance.** The other two thirds of this theme are
drilled hard. `Foo!` lookup appears in every exercise, and exercise 3 is built
around instantiating one module twice under two names. What's missing is the
chapter's tip that an instance can be bound inside a `LET`.

I left it out because a `LET`-bound instance is a scoping move rather than a
module move, and `LET ... IN` is chapter 2's construct, routed there by this
sheet's own boundary note. A fifth exercise carrying it would spend its whole
budget re-teaching `LET` to make a one-line point. That's the weakest omission
in the set, and I'd close it by adding a `LET` binding to exercise 3's task
rather than by adding an exercise.

## The excluded row

Theme 8 is the sheet's `SOURCE GAP` note and nothing here drills it. Two
`.. todo::` markers in `modules.rst` reserve content the chapter never
delivers. `:137` holds the parameterize-over-a-variable technique, which is why
actions imported from a module get named and never taught, and `:166` reserves
an expansion of the Using Modules material. Material the chapter never gave the
reader isn't material to test the reader on.

That ruling is why no exercise here imports an action. Every operator these
libraries export takes the state it judges as an argument, and none of them
mentions a variable.

## Constructs

| Construct | Exercises |
|---|---|
| `LOCAL` (definition modifier) | 1 |
| `INSTANCE` | 2 |
| `LOCAL INSTANCE` | 2 |
| named instance | 1, 3, 4 |
| `!` (namespace lookup) | 1, 2, 3, 4 |
| `INSTANCE ... WITH` and `<-` | 3, 4 |
| partial parameterization | 4 |

All seven appear. `!` is in every exercise, which is what you'd expect from the
one construct that does the actual reaching.

`LOCAL` and `LOCAL INSTANCE` are drilled in opposite directions on purpose.
Exercise 1 hides a definition and asks you to notice the name is gone. Exercise
2 hides a whole import and asks you to predict where the failure gets reported.
The second is the harder half, because the file that breaks isn't the file you
edited.

## A finding worth carrying

An `ASSUME` in a module you instantiate is not checked. `Band.tla` assumes its
lower bound sits at or below its upper bound. Adding
`UnusedBand == INSTANCE Band WITH Lo <- 99, Hi <- 1` to a working `Cellar.tla`
and re-running gives `OK` on the pinned build. Mutant C4, which rewrites the
`ASSUME` to a contradiction, is inert for the same reason.

I don't know whether that's TLA+ semantics or an artifact of this build, so
`EXERCISES.md` states it as a fact about the toolchain rather than as a rule.
The full probe is in `reports/authoring.md`.

## Scope

Every construct used across the four exercises comes from chapters 2 to 13,
checked against the `ch02` through `ch13` sheets. `EXCEPT` and `@` are the
newest things in the set and both belong to chapter 12, which `EXERCISES.md`
names at the top.

There's no PlusCal anywhere here and no translation step, so `pcal` never runs.
Chapter 13 writes TLA+ directly, and the set follows it.
