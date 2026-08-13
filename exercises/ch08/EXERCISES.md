# Exercises: learntla core ch.8, Concurrency

Five exercises. Budget 10 to 15 minutes each once you've read the chapter.

Every spec here is written in c-syntax PlusCal, the brace dialect, the same one
the chapter uses. Blocks are `{ }` and conditions are parenthesized.

Nothing here needs a construct from past chapter 8. If you find yourself
reaching for a temporal property, a fairness annotation, or `<>`, back up. The
answer is in chapters 2 through 8.

## Before you start

Write your answers into `starters/`, next to the `.cfg` that ships with each
one. That is what makes every command below true exactly as printed. Every
exercise ships its `.cfg`, so you leave the config alone. The config also pins
the invariant names, which is what makes your verdict match the one each
exercise states.

Fill in a line of `LOG.md` per exercise. For exercises 2 and 5 the prediction
is the whole point, so write it on that line, or as a comment in the spec,
**before** you run TLC.

## How to run anything here

Run from this chapter's directory, the one holding `EXERCISES.md` and
`LOG.md`. Two commands, always in this order:

```
pcal starters/YourSpec.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/YourSpec.tla -c starters/YourSpec.cfg
```

Each exercise's "how to run" line is those two commands with the spec name
filled in. Exercise 2 adds one flag, and says so.

Run `pcal` again after **every** edit. TLC reads only the translation that
`pcal` writes below your algorithm, never the algorithm itself, so an
untranslated edit changes nothing and you will be reading a stale verdict.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status, not from anything TLC printed, so read that token and ignore the
console noise above it.

- `OK` means the model check found nothing.
- `SAFETY_VIOLATION` means an invariant failed.
- `DEADLOCK` means TLC reached a state where no process could do anything.
- `SPEC_EVAL_FAILURE` means the spec could not be evaluated, so nothing at all
  was checked. This is not the same as a violation.
- `PARSE_ERROR` means the module did not parse.

State counts are not part of any expected outcome below. Two correct answers
can explore different numbers of states, and neither is wrong.

## Exercise 1

- Title: `Seat desk`
- Format: `complete-the-skeleton`
- Task: Fill the three `TODO` holes in `starters/SeatDesk.tla`. The file
  doesn't parse until you do. `pcal` refuses it first, pointing at `TODO_3`,
  so you will not even reach TLC on an unfilled file.
  - `TODO_1` is `NeverOversold`. The desk never sells a seat it doesn't have.
    Say it about `seats` alone.
  - `TODO_2` is `BooksBalance`. No seat is invented and none goes missing. One
    equation over `seats`, `sold` and `Capacity`.
  - `TODO_3` is the body of the `Look` label. Three statements, all inside that
    one label. Record in `sawFree` whether any seat is free, then, if it was,
    take one off `seats` and add one to `sold`.
  Two agents, one seat. Both agents run the same label, and TLC tries every
  order they can run in.
- Time budget: `15 min`
- Uses: process sets, one process per agent, process-local variables, and the
  fact that everything inside one label happens as a single indivisible step
- Expected outcome:
  - Pass run: `OK`
  - Fail run: give the `if` its own label. Put `Book:` on the line above it, so
    the label reads
    `Look: sawFree := (seats > 0);` and then `Book: if (sawFree) {...}`.
    Re-run `pcal` and re-run the model. `SAFETY_VIOLATION`. Both agents now
    look at the one free seat before either of them sells it, so both sell it.
    The split is the race. Nothing else about the spec changed.
- How to run: `pcal starters/SeatDesk.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/SeatDesk.tla -c starters/SeatDesk.cfg`

## Exercise 2

- Title: `Two cooks, one whisk`
- Format: `predict-then-check`
- Task: Read `starters/KitchenLocks.tla`. A baker and a cook share one pan and
  one whisk. Each takes both, one at a time, then puts both back. Right now
  both of them reach for the pan first.
  Answer two questions on your `LOG.md` line before you run anything.
  1. As written, can the two of them get stuck? Name the verdict you expect.
  2. Now suppose the cook reached for the whisk first instead, so the two of
     them take the utensils in opposite orders. Name the verdict you expect
     then.
  Then run it, make that one change, and run it again.
  Note the extra `-d` in the command. `verdict.sh` does not check for deadlock
  unless you ask, and this exercise is entirely about deadlock, so ask.
- Time budget: `12 min`
- Uses: singly-defined processes, `await` as a restriction on when a label may
  run, and deadlock as a verdict of its own
- How to run: `pcal starters/KitchenLocks.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh -d starters/KitchenLocks.tla -c starters/KitchenLocks.cfg`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Fail run: move the cook's `CookTakesWhisk` label above its `CookTakesPan`
    label, so the cook takes the whisk first. Re-run `pcal` and re-run with
    `-d`. `DEADLOCK`.

Both taking the pan first is safe for a reason worth naming. Whoever gets the
pan will also get the whisk, because the other one is still stuck at the pan
and cannot be holding the whisk. Reverse one of them and that argument breaks:
the baker can hold the pan while the cook holds the whisk, and then each is
waiting on the other forever.

The common wrong guess on question 1 is `SAFETY_VIOLATION`. There is no
invariant in this spec at all. Nothing is being asserted, so nothing can be
refuted. Deadlock is not an invariant failing, it is TLC running out of
anything to do, which is why it gets its own verdict and its own flag.

The other common guess is that the second run is safe because both of them do
eventually put everything back. They do. The trouble is that neither ever
reaches the label where it does so.

## Exercise 3

- Title: `Cloakroom`
- Format: `write-from-prompt`
- Task: Write `starters/Cloakroom.tla` from scratch, using
  `starters/Cloakroom.cfg` unchanged.
  1. Define `Hooks == 1..2` and `Guests == 1..3`.
  2. Two variables. `free` starts as `Hooks`. `coat` starts as a function
     putting every hook at 0, meaning no coat on it.
  3. In a `define` block, write `CoatsAreGuests` saying every hook holds either
     0 or a guest, and `UsedHooksAreTaken` saying a hook with a coat on it is
     never still in `free`.
  4. A process set over `Guests`, one label. The guest picks a hook out of
     `free` with `CHOOSE`, hangs its own coat there, and takes that hook out of
     `free`. Use `self` for "its own".
  Three guests, two hooks. Somebody arrives to an empty `free`, and `CHOOSE`
  over an empty set has no answer to give. Deciding what happens instead is
  the exercise. Guard the whole thing with an `if` so the third guest simply
  keeps its coat.
- Time budget: `15 min`
- Uses: `self` inside a process set, and the fact that an action which only
  makes sense in some states needs the spec to say what happens in the others
- Expected outcome:
  - Pass run: `OK`
  - Fail run: drop the `if` guard, so the guest reaches for a hook whatever the
    state of `free`. Re-run `pcal` and re-run the model. `SPEC_EVAL_FAILURE`.
    Read that token carefully. It does not say an invariant failed. It says the
    spec could not be evaluated, so **nothing was checked at all**. You have
    learned nothing about your invariants from that run, which is a different
    and worse position than being told one of them is false.
- How to run: `pcal starters/Cloakroom.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Cloakroom.tla -c starters/Cloakroom.cfg`

## Exercise 4

- Title: `Stamp desk`
- Format: `write-from-prompt`
- Task: Write `starters/StampDesk.tla` from scratch, using
  `starters/StampDesk.cfg` unchanged. Start from
  `EXTENDS Integers, Sequences`. `Sequences` is not optional here even though
  nothing in the spec is a sequence, and working out why is part of the
  exercise.
  1. Define `Clerks == {"ann", "bo"}` and `MaxInk == 4`.
  2. Two variables. `ink` starts at `MaxInk`, `stamped` starts at 0.
  3. In a `define` block, write `InkNeverNegative` and `LedgerBalances`. The
     second says every unit of ink is either still in the pad or accounted for
     by a stamp.
  4. A `procedure Stamp(copies)` with one procedure variable `made` starting
     at 0. It loops while `made < copies`, and each turn of the loop spends a
     unit of ink, adds one to `stamped`, and adds one to `made`. Then it
     returns.
  5. A process set over `Clerks`, whose first label calls `Stamp(2)` and whose
     second label does `skip`.
  The second label is not decoration. A `call` has to be followed by a label, a
  `goto`, or another `return`, so the call needs somewhere to come back to.
  Watch where the procedure goes in the file, too. PlusCal wants it after any
  macros and before any processes.
- Time budget: `15 min`
- Uses: `procedure`, `call` and `return`, procedure-local variables, and why a
  spec with a procedure has to extend `Sequences`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change the call to `call Stamp(3);`. Re-run `pcal` and re-run the
    model. `SAFETY_VIOLATION`. Two clerks asking for three copies each is six
    units of ink out of a pad holding four.
- How to run: `pcal starters/StampDesk.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/StampDesk.tla -c starters/StampDesk.cfg`

## Exercise 5

- Title: `Bell tower`
- Format: `predict-then-check`
- Task: Read `starters/BellTower.tla`. Two ringers each pull a rope `Quota`
  times. `chimes` counts every pull by anybody, and `left` is each ringer's own
  countdown, declared as a process-local variable.
  The module has two invariants in two different places. `RightTotal` sits in
  the `define` block. `TallyMatches` sits at the very bottom of the file, below
  where `pcal` writes the translation.
  Answer two questions on your `LOG.md` line before you run anything.
  1. Does the module as shipped pass? Name the verdict.
  2. Now suppose you added this line to the `define` block, right under
     `RightTotal`:
     `EarlyTally == chimes + left[1] + left[2] = Quota * Cardinality(Ringers)`
     Name the verdict you expect then.
  Then run it, add that line, and run it again. Leave the `.cfg` alone both
  times.
- Time budget: `12 min`
- Uses: process-local variables and where they can and cannot be read,
  `pc[...]` as a function from process to label once a spec has more than one
  process
- How to run: `pcal starters/BellTower.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/BellTower.tla -c starters/BellTower.cfg`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Fail run: add the `EarlyTally` line to the `define` block. Re-run `pcal`
    and re-run the model. `PARSE_ERROR`.

Open the translated file and look at the order of what `pcal` wrote. The
`define` block's operators come out near the top, and the declaration of the
process-local `left` comes out **below** them. So an operator in the `define`
block that mentions `left` is reading a name that does not exist yet, and SANY
stops there. That is the whole of "local variables can't be used in a
`define`". It is not a rule anyone enforces on purpose, it falls out of the
order the translator emits things in.

`TallyMatches` says the same thing about the same variable and is fine, purely
because it sits after the translation instead of inside it.

`RightTotal` reads `pc`, and `pc` is fine in a `define` block because it is a
global that the translator declares early. Note it is `pc[r]` and not `pc`
here: once a spec has more than one process, `pc` is a function from a process
value to that process's current label.

The wrong guess worth naming is `SAFETY_VIOLATION`. `EarlyTally` is a true
statement about this system, so if it could be checked it would hold. It never
gets checked, because the module never parses.
