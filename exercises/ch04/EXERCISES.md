# Exercises: learntla core ch.4, Writing an Invariant

Four exercises. Budget 10 to 15 minutes each after you have read the chapter.

Work in `starters/`. Every starter parses and runs before you touch it, so
you can run TLC at any point and see where you stand. `references/` holds a
worked answer for each one. Open it after you finish, not before.

You need a `LOG.md`. A delivered practice tree already has one beside this
file. Working straight out of the repository, copy
`exercises/templates/LOG.md` into this directory yourself. For the
predict-then-check exercise, write your prediction into `LOG.md` **before**
you run TLC. A prediction typed after the fact isn't a prediction.

The verdict is the token `verdict.sh` prints, backed by the exit code. Don't
read TLC's console text for a pass or a fail.

```bash
bash harness/verdict.sh exercises/ch04/starters/<Module>.tla
```

Every command below runs from the repository root. `verdict.sh` lives in the
repository either way, so from a practice tree keep the path to it and swap
the module path for wherever your copy sits.

Add `-c <path to a .cfg>` when an exercise names a config that isn't the one
sitting beside the module.

Two runs matter for each exercise, a pass and a fail. The pass alone proves
nothing. An invariant that never fails is an invariant that isn't testing
anything, which is the whole point of this chapter.

## Exercise 1

- Title: `A type invariant that earns its keep`
- Format: `write-from-prompt`
- Task: `TokenMove.tla` moves tokens one at a time from a left tray to a
  right tray. Each tray holds at most `Capacity` tokens, and neither can hold
  a negative number. The `define` block has `TypeInvariant == TRUE` in it.
  Replace that with a real type invariant over `left` and `right`. Then paste
  the same text into `TokenMoveBroken.tla`, whose loop guard is wrong on
  purpose. Run both. `Conserved` is written for you as a worked example of a
  non-type invariant, so leave it alone. Read the failing trace and say which
  row first breaks your invariant, and which variable did it.
- Time budget: `10-15 min`
- Uses: an invariant is checked on every reachable state rather than being a
  check that the spec runs. Type invariants pin variable shape with `\in`.
  The error trace carries one state per row with `pc` on each.
- Expected outcome:
  - Pass run: `OK`, exit 0. The stub `TRUE` also gives you this, which is
    why the pass run on its own tells you nothing.
  - Fail run: `SAFETY_VIOLATION`, exit 12. TLC names `TypeInvariant` as the
    violated invariant. `Conserved` holds throughout this run, so a fail
    naming `Conserved` means you changed something you shouldn't have.
- How to run:
  ```bash
  bash harness/verdict.sh exercises/ch04/starters/TokenMove.tla
  bash harness/verdict.sh exercises/ch04/starters/TokenMoveBroken.tla
  ```

## Exercise 2

- Title: `Check it only at the end`
- Format: `complete-the-skeleton`
- Task: `MaxScan.tla` walks `Input` and leaves the largest element in `best`.
  Three definitions in the `define` block have `TRUE` where the real
  expression belongs. Fill in all three. `UpperBound` says no element of
  `Input` sits above `best`. `Attained` says some element of `Input` equals
  `best`. `BestIsMax` restricts the whole check to the point where the
  algorithm has finished, and chapter 4 tells you which variable carries
  that. Then paste the three completed definitions into `MaxScanBroken.tla`
  and run both. In the failing trace, find the row where `pc` changes and
  read off the value of `best` that TLC objected to.
- Time budget: `10-15 min`
- Uses: `pc` and `=>` together restrict a check to one point in the run.
  `\A` and `\E` over a set of indices. Reading `pc` out of the error trace.
- Expected outcome:
  - Pass run: `OK`, exit 0.
  - Fail run: `SAFETY_VIOLATION`, exit 12, naming `BestIsMax`. The trace runs
    to the end of the loop and its last row has `pc = "Done"`. That last row
    is the guard doing its job. Drop the guard and the same invariant fails
    on the very first row instead, before the algorithm has done any work.
- How to run:
  ```bash
  bash harness/verdict.sh exercises/ch04/starters/MaxScan.tla
  bash harness/verdict.sh exercises/ch04/starters/MaxScanBroken.tla
  ```

## Exercise 3

- Title: `Two invariants that look equally obvious`
- Format: `predict-then-check`
- Task: `DrainQueue.tla` starts with three job ids in `pending` and removes
  them one at a time in any order. Nothing to fill in. Read `AllPositive` and
  `SomePositive` in the `define` block. Both read as plainly true, since
  every job id is 1, 2, or 3. Write into `LOG.md`, before running anything,
  which of the two passes, which fails, and what `pending` holds on the last
  row of the failing trace. Then run both configs and check yourself. If your
  prediction was wrong, write down in one line what you had assumed.
- Time budget: `10-15 min`
- Uses: `\A` and `\E` on an empty set. `\A` is true there and `\E` is false
  there. An invariant is checked on every reachable state, including the
  states after the interesting work is over.
- Expected outcome:
  - Pass run: `AllPositive` gives `OK`, exit 0. It survives the empty set,
    because all zero of the remaining jobs are positive.
  - Fail run: `SomePositive` gives `SAFETY_VIOLATION`, exit 12, naming
    `SomePositive`. The trace ends on the state where `pending` is empty.
    Which job left first varies between rows. That the queue ends empty
    doesn't vary, and that's the state that kills it.
- How to run:
  ```bash
  bash harness/verdict.sh exercises/ch04/starters/DrainQueue.tla
  bash harness/verdict.sh exercises/ch04/starters/DrainQueue.tla \
    -c exercises/ch04/starters/DrainQueueExists.cfg
  ```

## Exercise 4

- Title: `Ruling out the pairs you don't care about`
- Format: `write-from-prompt`
- Task: two parts. First, `Ratchet.tla` appends a reading to `log` each step
  and the reading never goes down. Replace `Nondecreasing(s) == TRUE` with a
  real definition. Quantify over pairs of indices into `s` and use `=>` to
  rule out the pairs that would otherwise sink you. Run it against
  `Ratchet.cfg`. Second, `NoDropWrong` is written for you and is wrong on
  purpose. Run it against `RatchetNoDrop.cfg` and work out why it fails on a
  spec that has no drop in it. Write the fixed version of `NoDropWrong` in
  `LOG.md`. You should need to change one operator.
- Time budget: `10-15 min`
- Uses: `=>` inside `\A` rules out unwanted index combinations. `=>` paired
  with `\E` instead of `/\` makes the check trivially true, so the negation
  of it is trivially false.
- Expected outcome:
  - Pass run: `LogIsNondecreasing` gives `OK`, exit 0. Write it with `/\`
    instead of `=>` and it fails as soon as `log` has an entry, since the
    pairs where both indices are the same drag the whole `\A` down.
  - Fail run: `NoDropWrong` gives `SAFETY_VIOLATION`, exit 12, naming
    `NoDropWrong`. The trace ends as soon as `log` has one entry. Note what
    that means. The bug here is in the invariant, not in the algorithm, and
    a learner who trusts the invariant goes hunting in the wrong file.
  - The initial state is worth a second look. `NoDropWrong` holds there,
    because `log` is empty and an `\E` over an empty set is false. Exercise 3
    and exercise 4 are the same fact seen from two sides.
- How to run:
  ```bash
  bash harness/verdict.sh exercises/ch04/starters/Ratchet.tla
  bash harness/verdict.sh exercises/ch04/starters/Ratchet.tla \
    -c exercises/ch04/starters/RatchetNoDrop.cfg
  ```
