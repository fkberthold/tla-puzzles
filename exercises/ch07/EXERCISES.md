# Exercises: learntla core ch.7, Nondeterminism

Five exercises. Budget 10 to 15 minutes each once you have read the chapter.

Nothing here needs a construct from past chapter 7. If you find yourself
reaching for a `process`, a fairness annotation, an `await`, or a temporal
property, back up. The answer is in chapters 2 through 7.

## Before you start

`scripts/deliver-exercises.sh` put this file, `LOG.md`, `starters/` and a
`cheatsheets/` folder in one directory. Work in that directory. Every command
below is written to run from it.

`starters/` holds a `.cfg` for every exercise, already written. Leave the
configs alone. They pin the constants and the invariant names, and that is what
makes your verdict match the one each exercise states.

Two of the starters are skeletons with `TODO` holes. Two are near-empty files
you fill from the prompt. One is complete and you only have to read it.

Write one free-form line per exercise in `LOG.md`. Exercise 3 is a
predict-then-check, so write your prediction on that line, or as a comment in
the spec, before you run TLC.

## How to run anything here

Two commands, and the first one is only for a file with a PlusCal block.

```
pcal starters/Thing.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Thing.tla -c starters/Thing.cfg
```

Swap `Thing` for the module the exercise names. The harness is named by an
absolute path, so it resolves wherever you put your practice directory. The
module and the config are named relative to this directory, which is where you
are running from.

Each exercise below repeats those lines with the name already filled in. Run
them as printed.

On the two write-from-prompt starters `pcal` refuses until you have written an
algorithm, with `Beginning of algorithm string --algorithm not found`. That is
the right answer to an empty file, not a broken starter.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status and not from anything TLC printed, so read that token and ignore the
console noise above it.

- `OK` means the model check found nothing.
- `SAFETY_VIOLATION` means an invariant failed.
- `ASSUMPTION_FAILED` means an `ASSUME` came out false.
- `PARSE_ERROR` means the file did not parse. An unfilled `TODO` does this.
- `CONFIG_ERROR` means the config names something your file does not define
  yet. Both write-from-prompt starters begin here.

State counts are not part of any expected outcome below. This is the chapter
where the state space starts to grow fast, and two correct answers can explore
different numbers of states. Neither is wrong.

## Exercise 1

- Title: `Depot`
- Format: `complete-the-skeleton`
- Task: Fill the three `TODO` holes in `starters/Depot.tla`. Crates wait on a
  quay and a loader takes them one at a time, writing each into the loading
  order. Nothing decides which crate goes next.
  - `TODO_1` is `Conserved`. No crate is lost. Every crate is either still
    waiting on the quay or already in the loading order, and between them they
    account for all of `Crates`. `NoRepeats` is written for you and is the
    model for the shape.
  - `TODO_2` is the set the `with` draws from. Read the chapter's second
    `with` example before you answer. What you draw from here is not a
    constant.
  - `TODO_3` is the new value of `waiting` once that crate has been taken.
  The starter ships already translated, so each `TODO_n` sits in the file
  twice. Once in the algorithm block, and once again below the
  `\* BEGIN TRANSLATION` line. TLC reads only the translated copy. Fill the
  algorithm block and re-run `pcal` to regenerate the translation, or fill both
  copies by hand. Filling only the algorithm block and skipping `pcal` leaves
  the stub in place and you get `PARSE_ERROR`.
  Leave the `while` guard alone. It counts picks rather than watching the quay,
  which is what keeps a wrong answer finite enough to get a verdict.
- Time budget: `12 min`
- Uses: nondeterministic `with` drawing from a variable set, invariants that
  have to hold whichever order the pick produces
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change `TODO_2` to draw from `Crates` instead, re-run `pcal`, and
    re-run. `SAFETY_VIOLATION`. Drawing from the constant lets the loader pick
    a crate it has already loaded, and `NoRepeats` catches it. The set you draw
    from is the whole content of this exercise.
- How to run:

```
pcal starters/Depot.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Depot.tla -c starters/Depot.cfg
```

## Exercise 2

- Title: `Sluice`
- Format: `complete-the-skeleton`
- Task: Fill the three `TODO` holes in `starters/Sluice.tla`. A canal sluice
  gate takes one of four actions each step and the spec does not get to say
  which, so all four sit in an `either`. The `either` is already written.
  - `TODO_1` is `FrozenIsShut`. A frozen gate is never open. Implication is
    the natural shape.
  - `TODO_2` guards the branch that winds the gate open. Ice holds it fast.
  - `TODO_3` guards the branch where the canal freezes over. Ice only takes
    hold on a gate that is already shut.
  Read all four branches before you write anything. Under `either` every branch
  is tried from every state, so a branch with no guard runs whenever it likes.
  Same note as exercise 1 about the translated copy. Each `TODO_n` sits in the
  file twice and TLC reads only the copy below `\* BEGIN TRANSLATION`.
- Time budget: `12 min`
- Uses: `either-or` as nondeterministic control flow, per-branch guards, the
  `or skip` branch that means nothing happened
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change `TODO_2` to `TRUE`, re-run `pcal`, and re-run.
    `SAFETY_VIOLATION`. A branch you did not guard is a branch TLC will take,
    and it takes it from the one state where it does damage.
- How to run:

```
pcal starters/Sluice.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Sluice.tla -c starters/Sluice.cfg
```

## Exercise 3

- Title: `Two jugs and a tap`
- Format: `predict-then-check`
- Task: Read `starters/Jugs.tla`. Nothing is missing from it. Two unmarked jugs
  and a tap, six things you can do, and no rule about which to do next, so all
  six sit in an `either`. The only invariant is `NotYet`, which claims the big
  jug never holds exactly `Target`.
  Two configs ship with it. `Jugs.cfg` sets a 5 and a 3 and asks for 4.
  `JugsEven.cfg` sets a 6 and a 4 and asks for 5.
  Before you run anything, write two predictions in `LOG.md`. For each config,
  will `verdict.sh` say `OK` or `SAFETY_VIOLATION`? Then answer a third
  question in the same line: which of the two verdicts means you have found a
  way to measure out the target?
  You do not need `pcal` here. The file ships translated and you are not
  editing it.
- Time budget: `10 min`
- Uses: `either-or` over six branches, deterministic `with` nested inside a
  nondeterministic branch, an invariant deliberately written false at the goal
- How to run:

```
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Jugs.tla -c starters/Jugs.cfg
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Jugs.tla -c starters/JugsEven.cfg
```

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `JugsEven.cfg` comes back `OK`.
  - Fail run: `Jugs.cfg` comes back `SAFETY_VIOLATION`.

The words `pass` and `fail` are the wrong way round here, and that is the
exercise. `SAFETY_VIOLATION` on `Jugs.cfg` is the good news. It means TLC found
a state where the big jug holds 4, and the counterexample it printed is the
sequence of pours that gets you there. The invariant was written to be false at
the goal precisely so that reaching the goal would break it.

`OK` on `JugsEven.cfg` is the bad news. It means TLC checked every state the
six branches can reach and never found 5 in the big jug. With a 6 and a 4 every
amount you can produce is even, so there is no answer to find. A clean run is
the proof of impossibility.

Most people predict this pair backwards on the first read. Reaching for a
counterexample as a search result is the move the chapter's own worked example
makes, and it stays counterintuitive until you have run it once.

## Exercise 4

- Title: `Box office`
- Format: `write-from-prompt`
- Task: Write `starters/BoxOffice.tla`, using `starters/BoxOffice.cfg`
  unchanged. The starter file holds the module header and nothing else.
  1. Define `Tiers == {"stalls", "circle"}`, `MaxSeats == 2` and
     `MaxOrders == 2`. Take `Capacity` as a `CONSTANT`.
  2. Define `OrderType` as the set of all well formed orders. An order is a
     struct with `seats` from 1 to `MaxSeats` and `tier` one of the `Tiers`.
  3. Two variables. `sold` starts as a function putting every tier at 0.
     `served` starts at 0.
  4. In a `define` block write `TypeOK`, saying `sold` is always a function
     from `Tiers` to `0..Capacity`, and `NeverOversold`, saying no tier has
     sold more than `Capacity`.
  5. One label. While fewer than `MaxOrders` orders have been served, pull a
     whole order out of `OrderType` and cope with it. Sell the seats if that
     tier has room for them, and otherwise turn the order away. Then count the
     order as served.
  Do not pick a representative order and test that one. The point is that you
  cover every order the type allows in a single run, which is what the chapter
  means by modelling an outside action.
- Time budget: `15 min`
- Uses: nondeterministic `with` drawing a whole struct from a struct set,
  modelling requests that arrive from outside the system
- Expected outcome:
  - Pass run: `OK`
  - Fail run: replace the room check with `TRUE`, so every order is sold, and
    re-run. `SAFETY_VIOLATION`. Nondeterminism hands you the awkward order for
    free. You never have to think up the one that oversells.
- How to run:

```
pcal starters/BoxOffice.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/BoxOffice.tla -c starters/BoxOffice.cfg
```

## Exercise 5

- Title: `Ferry`
- Format: `write-from-prompt`
- Task: Write `starters/Ferry.tla`, using `starters/Ferry.cfg` unchanged. The
  starter file holds the module header and nothing else. A ferry moves crates
  from the near bank to the far bank.
  1. Take `Crates` as a `CONSTANT` and define `MaxTrips == 3`.
  2. Four variables. `near` starts at `Crates`. `aboard` and `far` and `trips`
     all start at 0.
  3. In a `define` block write `TypeOK`, saying each of `near`, `aboard` and
     `far` stays in `0..Crates`, and `NothingLost`, saying the three of them
     always add up to `Crates`.
  4. While fewer than `MaxTrips` trips have run, load and then cross.
     Loading takes one crate off the near bank and puts it aboard, if there is
     one to take. The crossing either lands, in which case everything aboard
     comes off onto the far bank, or it does not land, in which case nothing
     observable happens and the load is still aboard for the next trip.
     Then count the trip.
  Do not model why a crossing fails. Weather, engine trouble and a missing
  deckhand are all the same to this spec, and the whole sad path is worth two
  words.
  You will need two labels inside the loop. Working out why is part of the
  exercise. The message PlusCal gives you when you use one names the problem.
- Time budget: `15 min`
- Uses: the `either or skip` pattern as an abstraction over sad paths, an
  invariant that survives the abstraction
- Expected outcome:
  - Pass run: `OK`
  - Fail run: write `aboard := 0` in place of the `skip`, so a failed crossing
    tips the load overboard, and re-run. `SAFETY_VIOLATION`. `skip` means
    nothing observable happened. It does not mean the work went away, and
    `NothingLost` is what tells the two apart.
- How to run:

```
pcal starters/Ferry.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ferry.tla -c starters/Ferry.cfg
```
