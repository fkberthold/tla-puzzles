# Exercises: learntla core ch.4, Writing an Invariant

Four exercises. Budget 10 to 15 minutes each after you have read the chapter.

## Before you start

`scripts/deliver-exercises.sh` put this file, `LOG.md`, `starters/` and a
`cheatsheets/` folder in one directory. Work in that directory. Every command
below is written to run from it, and every one of them is true as printed.

PlusCal here uses c-syntax, braces not begin/end.

Every starter parses and runs before you touch it, so you can run TLC at any
point and see where you stand.

Every stub you are asked to fill sits in the file twice, once inside the
PlusCal comment and once again below `BEGIN TRANSLATION`. TLC reads only the
translated copy, so edit both, or edit the PlusCal one and re-run `pcal`. Each
task below points back here rather than saying it again.

Fill in a line of `LOG.md` per exercise. For the predict-then-check exercise,
write your prediction on that line, or as a comment in your spec, before you
run TLC.

Two runs matter for each exercise, a pass and a fail. The pass alone proves
nothing. An invariant that never fails is an invariant that is not testing
anything, which is the whole point of this chapter.

## How to run anything here

One command. The module comes first and the config after it.

```
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Thing.tla -c starters/Thing.cfg
```

Swap `Thing` for the module the exercise names, and adjust the harness path to
wherever you cloned `tla-puzzles`. The module and the config are named relative
to this directory, which is where you are running from.

Each exercise below repeats that line with the names already filled in. Run
them as printed.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status and not from anything TLC printed, so read that token and ignore the
console noise above it.

- `OK` (0) means the model check found nothing.
- `SAFETY_VIOLATION` (12) means an invariant failed.

`verdict.sh` prints the token and nothing else. TLC's own output, error trace
included, goes to a scratch file that is deleted when the run ends. Every
exercise below asks you to read a trace, so keep one:

```
bash ~/repos/tla-puzzles/harness/verdict.sh --log /tmp/tlc.log starters/Thing.tla -c starters/Thing.cfg
```

The trace sits part way down that file, under the two `Error:` lines. Each row
is headed `State N:` and carries one line per variable. TLC's coverage
statistics come after it, so the trace is not the last thing in the file.

## Exercise 1

- Title: `A type invariant that earns its keep`
- Format: `write-from-prompt`
- Task: `TokenMove.tla` moves tokens one at a time from a left tray to a
  right tray. Each tray holds at most `Capacity` tokens, and neither can hold
  a negative number. The `define` block has `TypeInvariant == TRUE` in it.
  Replace that with a real type invariant over `left` and `right`.
  `Conserved` sits in the same block, written for you as a worked example of
  a non-type invariant, so leave it alone. That stub is doubled, see Before
  you start. Then paste the same text into `TokenMoveBroken.tla`, whose loop
  guard is wrong on purpose. Run both. Read the failing trace and write on
  your line of `LOG.md` which row first breaks your invariant, and which
  variable did it.
- Time budget: `12 min`
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
  ```
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/TokenMove.tla -c starters/TokenMove.cfg
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/TokenMoveBroken.tla -c starters/TokenMoveBroken.cfg
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
  that. Each of the three stubs is doubled, see Before you start. Then paste
  the three completed definitions into `MaxScanBroken.tla` and run both. In
  the failing trace, find the row where `pc` changes, and write the value of
  `best` that TLC objected to on your line of `LOG.md`.
- Time budget: `12 min`
- Uses: `pc` and `=>` together restrict a check to one point in the run.
  `\A` and `\E` over a set of indices. Reading `pc` out of the error trace.
- Expected outcome:
  - Pass run: `OK`, exit 0.
  - Fail run: `SAFETY_VIOLATION`, exit 12, naming `BestIsMax`. The trace runs
    to the end of the loop and its last row has `pc = "Done"`. That last row
    is the guard doing its job. Drop the guard and the same invariant fails
    on the very first row instead, before the algorithm has done any work.
- How to run:
  ```
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/MaxScan.tla -c starters/MaxScan.cfg
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/MaxScanBroken.tla -c starters/MaxScanBroken.cfg
  ```

## Exercise 3

- Title: `Two invariants that look equally obvious`
- Format: `predict-then-check`
- Task: `DrainQueue.tla` starts with three job ids in `pending` and removes
  them one at a time in any order. Nothing to fill in. Read `AllPositive` and
  `SomePositive` in the `define` block. Both read as plainly true, since
  every job id is 1, 2, or 3. Write on your line of `LOG.md`, before running
  anything, which of the two passes, which fails, and what `pending` holds on
  the last row of the failing trace. Then run both configs and check
  yourself. If your prediction was wrong, write down in one line what you had
  assumed.
- Time budget: `10 min`
- Uses: quantifiers over a set that can become empty. An invariant is checked
  on every reachable state, including the states after the interesting work is
  over.
- How to run:
  ```
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/DrainQueue.tla -c starters/DrainQueue.cfg
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/DrainQueue.tla -c starters/DrainQueueExists.cfg
  ```

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `AllPositive` gives `OK`, exit 0. It survives the empty set,
    because all zero of the remaining jobs are positive.
  - Fail run: `SomePositive` gives `SAFETY_VIOLATION`, exit 12, naming
    `SomePositive`. The trace ends on the state where `pending` is empty.
    Which job left first varies between rows. That the queue ends empty
    doesn't vary, and that's the state that kills it.

The moral is one line long. `\A` is true on an empty set and `\E` is false
on it.

## Exercise 4

- Title: `Ruling out the pairs you don't care about`
- Format: `write-from-prompt`
- Task: two parts. First, `Ratchet.tla` appends a reading to `log` each step
  and the reading never goes down. Replace `Nondecreasing(s) == TRUE` with a
  real definition. Quantify over pairs of indices into `s` and use `=>` to
  rule out the pairs that would otherwise sink you. That stub is doubled, see
  Before you start. Run it against `Ratchet.cfg`. Second, `NoDropWrong` is
  written for you and is wrong on purpose. Run it against `RatchetNoDrop.cfg`
  and work out why it fails on a spec that has no drop in it. Write the fixed
  version of `NoDropWrong` on your line of `LOG.md`. You should need to change
  one operator.
- Time budget: `15 min`
- Uses: `=>` inside `\A` rules out unwanted index combinations. What that
  same operator does inside an `\E` is part 2's question.
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
  - Part 2, once you have run it: `=>` paired with `\E` instead of `/\`
    makes the check trivially true, so its negation is trivially false. One
    operator is the whole distance between the two.
- How to run:
  ```
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ratchet.tla -c starters/Ratchet.cfg
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ratchet.tla -c starters/RatchetNoDrop.cfg
  ```

## References

A worked answer for each exercise lives in the `tla-puzzles` repository under
`exercises/ch04/references/`. It is deliberately not delivered here. Read it
after your own attempt, not before.
