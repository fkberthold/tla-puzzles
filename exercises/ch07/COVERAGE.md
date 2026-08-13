# Coverage audit: ch07 exercise set

Audited against the six major themes and two constructs in
`exercises/ch07/CHEATSHEET.md`. This file is an audit run after the set was
written. It is not the thing that generated the set.

## Major themes

| # | Theme (abbreviated from the sheet) | Exercises | Verdict |
|---|---|---|---|
| 1 | Nondeterminism breaks the deterministic pattern. Randomness, user input, sensor readings and independent parts all need more than one possible next step | 1, 4 | covered |
| 2 | `with x \in set` and `either-or` are the two constructs. Both nest inside each other and combine with the deterministic forms | 1, 2, 3, 4 | covered |
| 3 | Nondeterminism as an abstraction tool. `either or skip` says "this succeeds, or something went wrong" without spelling out the causes | 2, 5 | covered |
| 4 | The same idea models outside actions. `with request \in RequestType` pulls any possible request instead of hand-picking one | 4 | covered |
| 5 | The calculator flips the usual pattern. An invariant false at the target turns TLC's counterexample into a search result | 3 | covered |
| 6 | More nondeterminism means a bigger state space, tracked by seen-to-distinct ratios | none | omitted, argued below |

Theme 2 carries the chapter, so it is exercised four different ways. Exercise 3
is the predict-then-check, because theme 5 only lands if you commit to a wrong
answer first, and most people do.

## The omitted row

**Theme 6, state-space growth.** This is the one theme the harness cannot
check, and the reason is structural rather than an oversight.

Every outcome in this set is a verdict token from `harness/verdict.sh`, which
derives its answer from TLC's exit status and never from TLC's console text.
Seen-state and distinct-state counts live only in that console text. There is
no exit code for "the state space got bigger", so an exercise whose answer is a
ratio has no honest way to be graded here. Inventing one would mean going back
to scraping stdout, which is exactly the practice `verdict.sh` exists to end.

The theme is not lost, it is just placed elsewhere. The cheat sheet carries it,
and `EXERCISES.md` says up front that state counts are not part of any expected
outcome and that two correct answers can explore different numbers of states.
That warning is doing the theme's teaching work.

One measurement from the authoring run is worth reading as evidence for the
theme, and it is recorded in `reports/authoring.md`. A single-character edit to
exercise 3, turning `Min` into a maximum, changed the jug spec from a
25-state check finishing in under a second into a run that never terminated and
came back `TIMEOUT`. The state space is one edit away from unbounded. That is
theme 6 as a lived fact rather than a ratio, but it is an authoring finding and
not something a learner is asked to reproduce.

## Constructs

Both constructs on the sheet appear in several exercises.

| Construct | Exercises |
|---|---|
| nondeterministic `with` | 1, 4 |
| `either-or` | 2, 3, 5 |

The two are covered at different depths on purpose.

Nondeterministic `with` gets both of its shapes. Exercise 1 draws from a
**variable** set, which is the sheet's `with thread \in sleeping` sub-point and
the one learners miss. Exercise 4 draws from a **defined type**, a struct set,
which is theme 4.

`either-or` gets three shapes. Exercise 2 is a state machine with a guard on
each branch, which is what the chapter means when it says `either` suits state
machines. Exercise 3 is six branches with no guards at all, plus a
deterministic `with` nested inside two of them, which is the combining the
sheet's theme 2 calls for. Exercise 5 is the two-branch `either or skip`.

## Scope

Every construct used across the five exercises comes from chapters 2 to 7,
checked against the `ch02` through `ch07` sheets. The full table is in
`reports/authoring.md`.

Nothing reaches into chapter 8, which is where the sheet's boundary notes put
concurrency, `await`, and deadlock. Exercise 1 is the one that could have
drifted there, because a nondeterministic `with` over an empty set blocks and
that is the chapter 8 material. Its loop guard counts picks rather than testing
the quay, so the draw set is never empty and deadlock never enters the
exercise. The starter says to leave that guard alone.
