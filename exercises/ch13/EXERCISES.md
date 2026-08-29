# Exercises: learntla core ch.13, Modules

Four exercises. Budget 10 to 15 minutes each once you've read the chapter.

This chapter is pure TLA+. There's no PlusCal in it and no translation step, so
`pcal` never runs here. You write the module, and the module is what TLC reads.

Nothing here needs a construct from beyond chapter 13. `EXCEPT` and `@` are
chapter 12's and both turn up in exercise 1, so that chapter has to be behind
you.

## Before you start

Work inside this directory, the one holding this file. Every `.tla` and every
`.cfg` in the set lives in `starters/`, side by side. That's the chapter's own
advice rather than a packaging convenience. Shared TLA+ files belong in the same
folder as the spec that uses them, and `starters/` is that folder.

Every exercise here spans more than one file. That's the subject, so each
exercise says which files ship finished and which one you work on. A file that
ships finished is not yours to edit unless the exercise tells you to edit it.

Fill in a line of `LOG.md` per exercise. Exercise 2 is predict-then-check, and
there the prediction is the whole point. Write it on that exercise's line, or as
a comment in the spec, **before** you run TLC.

## How to run anything here

Run from this directory. The harness is named by its full path, so it resolves
from wherever you are, and the spec is named relative to here. Adjust that path
if you cloned tla-puzzles somewhere other than `~/repos`.

```
bash ~/repos/tla-puzzles/harness/verdict.sh starters/YourSpec.tla -c starters/YourSpec.cfg
```

You never name the other modules. TLC finds them because they sit next to the
one you did name. Nothing on the command line and nothing in the `.cfg` mentions
a second file, and that's worth watching for on your first run. It's the thing
most people expect to have to configure.

The `-c` is spelled out so the pairing is visible. The harness would find the
matching `.cfg` on its own.

Each exercise's "how to run" line names the command with the spec name filled
in. They are true as printed.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status, not from anything TLC printed, so read that token and ignore the console
noise above it. Three tokens come up in this chapter.

- `OK` (0) means the model check found nothing.
- `SAFETY_VIOLATION` (12) is what a failed `INVARIANT` gives you.
- `PARSE_ERROR` (150) means the module never compiled, so nothing was checked.

`PARSE_ERROR` does more work here than it does in most chapters. Half of what
this chapter teaches is which names reach which file, and a name that doesn't
reach is a name SANY can't resolve. In this chapter it's often the answer rather
than a slip on the way to one.

State counts are not part of any expected outcome below. Two correct answers can
explore different numbers of states, and neither is wrong.

## Exercise 1

- Title: `Rules in their own file`
- Format: `complete-the-skeleton`
- Task: Fill the three holes in `starters/Dock.tla`, marked `TODO_1` through
  `TODO_3`. The file doesn't parse until all three are filled.
  `starters/DockRules.tla` and `starters/Dock.cfg` ship complete and you edit
  neither.
  A loading dock has one bay per name in `Bays`, and each bay holds a count of
  crates. `DockRules.tla` holds the two rules that count has to obey, and holds
  nothing else. Read it before you start. Notice that it never mentions a
  variable. Both of its public operators take the state they judge as an
  argument, which is what lets one rules file serve any spec that can hand it a
  function from bays to counts.
  1. `TODO_1` binds `DockRules` to the name `Rules`. Nothing out of that file
     should land in this file's namespace.
  2. `TODO_2` says no bay ever holds more crates than `Cap`. One call through
     `Rules!`, handing it `crates` and `Cap`.
  3. `TODO_3` says no bay ever holds a negative count. One call, one argument.
  Three operators are defined in the rules file and only two of them are
  reachable from here. The word that makes the difference sits on the line above
  the third one.
- Time budget: `12 min`
- Uses: a named instance, `!` lookup, `LOCAL` on a definition, invariants kept
  in a file of their own
- Expected outcome:
  - Pass run: `OK`
  - Fail run: rewrite `WithinCap` to reach for the private operator instead,
    `Rules!Level(crates, "north") <= Cap`, and re-run. `PARSE_ERROR`. SANY calls
    `Level` an unknown operator, and it says that about a definition you can
    read on screen in a file sitting right beside this one. `LOCAL` isn't a
    naming convention. The name is gone.
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Dock.tla -c starters/Dock.cfg`

## Exercise 2

- Title: `How far a name travels`
- Format: `predict-then-check`
- Task: Three files, one chain. `starters/Palette.tla` holds the colour
  vocabulary. `starters/Signal.tla` imports it and builds the escalation policy
  on top. `starters/Beacon.tla` extends `Signal`, and `Beacon` is the module you
  run. All three ship complete and the set runs as it stands.
  `Beacon.tla` carries two invariants. `EscalationIsRed` uses `Escalated`, which
  is defined one file down in `Signal`. `LampWarmOrCool` uses `IsWarm`, which is
  defined two files down in `Palette` and is never written out in `Signal.tla`
  at all.
  Make two predictions and write both on the exercise 2 line of `LOG.md` before
  you run anything.
  1. What verdict does the set give as it stands?
  2. Now put `LOCAL` in front of `Signal.tla`'s `INSTANCE Palette` line, and
     change nothing else anywhere. What verdict does that give?
  Predict the token this harness reports, not the meaning. And notice what
  you're about to do. You edit one word in one file, and it isn't the file you
  run.
- Time budget: `10 min`
- Uses: `LOCAL INSTANCE` against plain `INSTANCE`, transitive visibility through
  a chain, `EXTENDS` and `INSTANCE` reaching into the same namespace
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Beacon.tla -c starters/Beacon.cfg`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Fail run: `PARSE_ERROR`

The first one is the easy half. `Signal` imports `Palette` without
qualification, so `IsWarm` lands in `Signal`'s namespace, and `Beacon` extends
`Signal`, so it lands in `Beacon` too. Two hops, and nobody wrote `IsWarm` down
along the way.

`LOCAL` cuts the second hop. The operator is still available inside `Signal`, so
`Escalated` keeps working and `Signal.tla` still compiles on its own. It just
stops travelling on. `Beacon` gets `Escalated`, doesn't get `IsWarm`, and
`LampWarmOrCool` is left holding a name that means nothing.

I think the interesting part is where the error lands. You broke `Signal.tla`,
and SANY reports the failure in `Beacon.tla`, at a line you didn't touch, about
an operator that's still defined and still correct. That's the shape of every
`LOCAL INSTANCE` surprise you're going to have.

This is what `Sequences.tla` does with `Naturals`, and the chapter says so. The
reason `EXTENDS Sequences` doesn't quietly hand you `Nat` is one word in a file
you've never opened.

One more run if you have a minute. Put `Signal.tla` back, then narrow
`Palette.tla`'s `Warm` down to `{"red"}` and run again. That comes out
`SAFETY_VIOLATION`, because `LampWarmOrCool` is now a claim that was checked and
came out false, rather than a name that wouldn't resolve. The two are worth
seeing next to each other. One of them tells you your property is wrong. The
other tells you nothing at all about your property.

## Exercise 3

- Title: `Two rooms, one range`
- Format: `write-from-prompt`
- Task: Write `starters/Cellar.tla` from scratch, using `starters/Cellar.cfg`
  unchanged. `starters/Band.tla` ships complete and you don't edit it.
  `Band` is an abstract range with no idea what it's a range of. It carries two
  constants and two operators, and it does nothing at all until somebody fills
  the constants in. A wine room runs at 10 to 14 degrees and a beer room runs at
  2 to 6, and one `Band.tla` is going to serve both.
  1. `EXTENDS Integers`. You get one `EXTENDS` line and as many instance lines
     as you want.
  2. Two named instances of `Band`, called `WineBand` and `BeerBand`, each
     filling in its own room's bounds.
  3. Two variables, `wine` and `beer`, starting at 12 and 4, plus a `vars` tuple
     of the two.
  4. A step moves one room by one degree, up or down, and leaves the other
     alone. A room only moves to a value its own band holds, and you say that by
     calling into the band rather than by writing the numbers out again.
  5. `Spec == Init /\ [][Next]_vars`.
  6. Two invariants, named as the `.cfg` names them. `BothInBand` says each room
     sits inside its own band. `NeitherRoomOverfull` says neither room's
     headroom has gone below zero.
  The numbers 10, 14, 2 and 6 should each appear exactly once in your file, on
  the instance lines. If one of them turns up again further down, you've written
  a range twice, and the second copy is the one that drifts.
- Time budget: `15 min`
- Uses: `INSTANCE ... WITH` and `<-`, one module instantiated twice under two
  names, `!` lookup, an abstract library that pays for its own file
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change `WineBand`'s upper bound from 14 to 11 and re-run.
    `SAFETY_VIOLATION`. You edited one instance line, and the failure comes back
    from an invariant that names no numbers at all. That's what putting them on
    the instance line buys.
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Cellar.tla -c starters/Cellar.cfg`

## Exercise 4

- Title: `The rate arrives late`
- Format: `complete-the-skeleton`
- Task: Fill the three holes in `starters/Garage.tla`, marked `TODO_1` through
  `TODO_3`. The file doesn't parse until all three are filled.
  `starters/Tariff.tla` and `starters/Garage.cfg` ship complete and you edit
  neither.
  `Tariff` charges a fixed part plus a part that runs with the clock, and it
  takes both of them as constants. `Garage` wants it two ways at once.
  1. `TODO_1` is an instance named `Metered`. It fixes the fixed part at 0 and
     leaves the hourly rate open, so the rate arrives where the operator gets
     called rather than where the instance is written. That turns `Metered` into
     an operator instead of a plain name, and it's called as
     `Metered(r)!Charge(h)`.
  2. `TODO_2` is an instance named `Flat` whose hourly rate is 0. Its `WITH`
     clause must not name `Base` at all. Look at what `Garage` already declares
     before you decide that's a typo.
  3. `TODO_3` says the charge at a metered rate of 3 an hour never runs over
     `Budget`.
  `FlatIgnoresTheClock` is written for you and it's the check on `TODO_2`. It
  compares `Flat!Charge(hours)` against `Garage`'s own `Base`, and the `.cfg` is
  the only place any value for `Base` appears.
- Time budget: `12 min`
- Uses: partial parameterization, a constant passed through by name with no
  `WITH` clause, a `WITH` clause overriding that pass-through, `!` lookup on a
  parameterized instance
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change the metered rate at the call site from 3 to 5 and re-run.
    `SAFETY_VIOLATION`. Nothing on the instance line moved. The rate was never
    part of the instance, and the call site is where it lives.
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Garage.tla -c starters/Garage.cfg`

## One thing this set can't show you

`Band.tla` carries an `ASSUME` saying its lower bound sits at or below its upper
bound. Instantiate it with the bounds the wrong way round and TLC won't say a
word. I checked that on the pinned build by adding a third instance of `Band`
with `Lo <- 99` and `Hi <- 1` to a working `Cellar.tla`, and the run still came
back `OK`.

So an `ASSUME` in a module you instantiate isn't a guard on the instantiation.
Whatever it buys you, it isn't a check on your `WITH` clause. I don't know
whether that's deliberate or an artifact of this build, so take it as a fact
about the toolchain in front of you rather than a rule about TLA+.
