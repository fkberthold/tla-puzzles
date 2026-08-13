# Exercises: learntla core ch.9, Temporal Properties

Five exercises. Budget 10 to 15 minutes each once you've read the chapter.

PlusCal here uses c-syntax, braces not begin/end.

Nothing here needs a construct from past chapter 9. Processes, `await`, model
values and symmetry sets all come from chapters 5 and 8, and everything else
comes from chapters 2 to 6. If you find yourself reaching for a recursive
operator or `CASE`, back up.

## Before you start

Work in this directory. The starters are in `starters/`, and you write your
answers there too, next to the `.cfg` that goes with them. Every exercise ships
its `.cfg`, so you write or fill the `.tla` and leave the config alone unless an
exercise says otherwise. The config also pins the property names, which is what
makes your verdict match the one each exercise states.

Fill in a line of `LOG.md` per exercise. Exercises 4 and 5 are predict-then-check,
so write your prediction on that line, or as a comment in the spec, before you
run TLC.

## How to run anything here

Run from this directory. Both commands below are the whole shape, and every
exercise repeats them with its own module name filled in.

```
pcal starters/YourSpec.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/YourSpec.tla -c starters/YourSpec.cfg
```

The `pcal` step is only needed when you've changed something inside the PlusCal
comment. Exercise 1 has you write a module from scratch. The four starters for
exercises 2 to 5 all arrive already translated.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status, not from anything TLC printed, so read that token and ignore the console
noise above it.

- `OK` (0) means the model check found nothing.
- `SAFETY_VIOLATION` (12) means something refutable by a finite prefix broke. An
  invariant, or a property TLC could settle without looking at an infinite
  behavior.
- `LIVENESS_VIOLATION` (13) means a property that needs an infinite behavior
  broke.
- `PARSE_ERROR` (150) means the file did not parse. An unfilled `TODO` does
  this.

State counts are not part of any expected outcome below. Two correct answers can
explore different numbers of states, and neither is wrong.

## A warning that runs through the whole chapter

A liveness property with the wrong fairness under it doesn't fail loudly. It
passes. `OK` on a liveness check means one of two things, and TLC won't tell you
which: your system does the good thing, or your property was never in a position
to notice. Every liveness exercise below has a fail run for that reason. The
fail run is the proof that the pass run meant something, so don't skip it because
the pass run already went green.

## Exercise 1

- Title: `Condemned means condemned`
- Format: `write-from-prompt`
- Task: Write `starters/Footbridge.tla` from scratch, using
  `starters/Footbridge.cfg` unchanged.
  1. Define `States == {"shut", "open", "condemned"}`. One variable `state`,
     starting `"shut"`.
  2. One process, `Warden`, with a single label holding a `while (TRUE)` loop
     and an `either` with three branches. A shut bridge opens. An open bridge
     shuts. Any bridge that isn't already condemned gets condemned.
  3. In a `define` block, write `StateOK`, saying `state` stays in `States`.
  4. In the same block, write `CondemnedIsForever`, saying that once the bridge
     is condemned it stays condemned. You need two `[]`s, one inside the other,
     and an implication between them.
  The config puts `StateOK` under `INVARIANT` and `CondemnedIsForever` under
  `PROPERTY`. That split is the exercise. Ask yourself why the second one can't
  go where the first one goes.
- Time budget: `15 min`
- Uses: `[]` composed with `=>` rather than sitting on its own, `PROPERTY`
  alongside `INVARIANT`, a safety property that no single state can decide
- Expected outcome:
  - Pass run: `OK`
  - Fail run: add a fourth `either` branch that takes a condemned bridge back to
    `"shut"`, and re-run. `SAFETY_VIOLATION`. Now do the interesting part. Delete
    the `PROPERTY` block from the config, leaving `StateOK` on its own, and run
    the broken spec again. `OK`. The reopening bridge passes every state-by-state
    check you can write, because no single state is wrong. Only the pair of them
    is.
- How to run: `pcal starters/Footbridge.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Footbridge.tla -c starters/Footbridge.cfg`

## Exercise 2

- Title: `The kiln that never finishes`
- Format: `complete-the-skeleton`
- Task: Fill the two `TODO` holes in `starters/Kiln.tla`, in that order, one
  run each.
  This starter arrives already translated, so each hole sits in the file
  twice: once in the PlusCal comment and once again in the translated
  section below it. TLC reads only the translated copy. Always edit the
  copy in the PlusCal comment and run `pcal`, which rewrites the
  translation from it. Editing the translated copy appears to work, and
  the next `pcal` run throws it away.
  1. Fill `TODO 2` only, and leave `TODO 1` empty. It is `FiringFinishes`,
     saying the firing always reaches `stage = "cooled"`. One temporal
     operator over one state predicate. Run it. Until `TODO 2` is filled
     the module does not parse, so this is also the first run that gets as
     far as TLC, and it is the run worth having.
  2. Then fill `TODO 1`, the fairness modifier on the process: one word,
     immediately before `process`. Run it again.
- Time budget: `12 min`
- Uses: `<>`, `fair process`, stuttering as a way for a spec to crash, and the
  fact that a stutter step breaks no invariant
- Expected outcome:
  - Pass run: `OK`, with both holes filled.
  - Fail run: two of them, and you want both. The first is step 1 above,
    before you filled `TODO 1`. `LIVENESS_VIOLATION`. Nothing about the kiln
    changed. The behavior that breaks it is the one where the kiln stops dead
    and stutters for ever.
    Second, keep `TODO 1` filled and change `soaks := soaks + 1` to
    `soaks := 0`. `LIVENESS_VIOLATION` again, this time with fairness in place
    and the soak looping for ever. That second run is the one that proves your
    `OK` was about the kiln rather than about a property too weak to fail.
- How to run: `pcal starters/Kiln.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Kiln.tla -c starters/Kiln.cfg`

## Exercise 3

- Title: `One bay, two hauliers`
- Format: `complete-the-skeleton`
- Task: Fill the one `TODO` hole in `starters/LoadingBay.tla`, then change one
  word.
  1. `TODO 1` is `EveryoneKeepsDocking`. Every haulier keeps getting the bay,
     for ever. Not "gets it once", and not "ends up holding it". Quantify over
     `Hauliers`, and put a two-operator temporal shape around `bay = h`.
  2. Run it. The starter ships with weak fairness, and the property doesn't
     hold under it. Work out which behavior breaks it before you read on.
  3. Change `fair` to `fair+` and run it again.
  This starter also arrives already translated, so `TODO_1` sits in the file
  twice, once in the PlusCal comment and once in the translated section below
  it. TLC reads only the translated copy, so fill the PlusCal comment and re-run
  `pcal`.
  One aside worth reading. `Perms` is defined in the module and deliberately
  isn't named in the config. The hauliers are interchangeable, so a symmetry set
  is exactly the optimization you'd reach for, and chapter 9 says you can't have
  one alongside a liveness property. I measured what happens if you try. TLC
  gives no warning and reports `LIVENESS_VIOLATION` on the `fair+` spec, which is
  the correct spec. Adding `SYMMETRY Perms` to the config turns a true property
  into a false alarm, in silence. The behavior it reports is one where a single
  haulier docks over and over and the other never does. Symmetry folded the two
  together, so TLC cannot tell that trace from a real one.
- Time budget: `15 min`
- Uses: `[]<>`, `fair` against `fair+`, a contested resource where a process is
  only intermittently able to move
- Expected outcome:
  - Pass run: `OK`, with `fair+`.
  - Fail run: `LIVENESS_VIOLATION`, with `fair`. That's step 2, and it's the
    same spec with one letter's difference. Then, keeping `fair+`, change the
    `Go` label to `bay := self` instead of `bay := NULL` and re-run.
    `LIVENESS_VIOLATION`. Strong fairness can't help a haulier who never lets
    go, which is the proof that your `OK` wasn't coming from a property too weak
    to break.
- How to run: `pcal starters/LoadingBay.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/LoadingBay.tla -c starters/LoadingBay.cfg`

### After the run

Run before you read on.

A haulier waiting at `Wait` can only move while the bay is free, so it is
not always able to move, and weak fairness promises nothing to a process
that is only intermittently able to act. That is the gap `fair+` closes.

## Exercise 4

- Title: `Three claims about one beacon`
- Format: `predict-then-check`
- Task: Read `starters/Beacon.tla`. A keeper flips a lamp between lit and dark,
  for ever, and the process is fair. The module defines three properties over
  that one variable, and each has its own config.
  - `EverLit == <>(lamp = "lit")`
  - `LitAgainAndAgain == []<>(lamp = "lit")`
  - `SettlesLit == <>[](lamp = "lit")`
  Write down which verdict each of the three runs gives, before running any of
  them. Three tokens on your `LOG.md` line. Then run all three.
  Don't reason from which operator looks stronger. Say out loud what each one
  demands of a behavior, then check the beacon against it.
- Time budget: `10 min`
- Uses: `<>`, `[]<>` and `<>[]` over the same predicate, and one property per
  config because TLC won't name the property that broke
- How to run: three runs, same module.
  The module ships translated, so `pcal starters/Beacon.tla` is only
  needed after you edit inside the PlusCal comment, which the fail run below
  asks you to do. Run it there, before the three verdict commands.
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Beacon.tla -c starters/BeaconEver.cfg`
  then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Beacon.tla -c starters/BeaconAgain.cfg`
  then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Beacon.tla -c starters/BeaconSettles.cfg`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK` for `BeaconEver.cfg`, and `OK` for `BeaconAgain.cfg`.
    `LIVENESS_VIOLATION` for `BeaconSettles.cfg`.
  - Fail run: delete the `fair`, run `pcal starters/Beacon.tla`, and run all
    three again. All three come back `LIVENESS_VIOLATION`. Put `fair` back,
    change `lamp := "lit"` to `lamp := "dark"` so the lamp never lights, run
    `pcal starters/Beacon.tla` again, and run all three again. All
    three break again, this time with fairness in place. That second sweep is
    what tells you the two `OK`s above were about the beacon.

The one people get backwards is `<>[]`. `[]<>` asks the lamp to keep coming
back, and a lamp that blinks for ever does that. `<>[]` asks it to settle, to
reach a point after which it's lit and stays lit, and a lamp that blinks for
ever never settles. So the blinking beacon satisfies the first and breaks the
second.

`EverLit` is the weakest of the three, and it needs `fair` all the same. Without
it the beacon is allowed to stutter in the dark for ever and never light at all.

Two more things you can try in a minute each. Change `SettlesLit` to
`<>[](lamp \in {"lit", "dark"})` and it passes, because it now asks for
something that was already true in the first state. Change the `if (lamp =
"dark")` test to `if (TRUE)` so the lamp lights once and stays lit, and
`SettlesLit` passes for a real reason. Same verdict, and only one of them is
worth having.

## Exercise 5

- Title: `A leads-to that was true about nothing`
- Format: `predict-then-check`
- Task: Read `starters/Depot.tla`. Parts get booked in, mended, then collected.
  `Chain` is two leads-to obligations stacked, and it's the property you'd
  actually want from a repair depot. `MaxOpen` caps how many parts the depot
  takes in.
  1. Predict the verdict for `Depot.cfg`, which checks `Chain`. Write it on your
     `LOG.md` line, then run it.
  2. `BookDeskIdle` is not a property of the depot. It's a probe, and it's meant
     to fail. `DepotProbe.cfg` checks it on its own. Predict that verdict too,
     then run it, then read its verdict backwards. What does it mean if a
     property saying "nothing was ever booked" passes?
  3. Now change `MaxOpen == 0` to `MaxOpen == 2` and run both configs again.
  Do all three steps before you read the next section.
- Time budget: `15 min`
- Uses: `~>` chained, weak fairness under a leads-to, and a hand-built
  non-vacuity probe
- How to run: two configs, same module.
  `MaxOpen` sits outside the PlusCal comment, so step 3 needs no `pcal`.
  The fail run below edits inside the comment, so that one does: run
  `pcal starters/Depot.tla` before the verdict commands.
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Depot.tla -c starters/Depot.cfg`
  then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Depot.tla -c starters/DepotProbe.cfg`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: as shipped, `Depot.cfg` gives `OK` and `DepotProbe.cfg` gives
    `OK`. With `MaxOpen == 2`, `Depot.cfg` gives `OK` and `DepotProbe.cfg` gives
    `SAFETY_VIOLATION`.
  - Fail run: keep `MaxOpen == 2`, delete the third `either` branch so nothing
    is ever collected, and re-run `Depot.cfg`. `LIVENESS_VIOLATION`. Keep
    `MaxOpen == 2`, put the branch back, delete the `fair` instead, and re-run.
    `LIVENESS_VIOLATION` again.

`MaxOpen == 0` means the Book branch is never enabled, so nothing is ever
booked. `P ~> Q` with a `P` that never happens is true, in the same way that
"every unicorn in this room is on fire" is true. Both halves of `Chain` were
true about nothing, and TLC said `OK`.

The two `OK`s from step 1 and step 2 are the same token and they carry opposite
news. The first says the depot is fine. The second says the first one was empty.
Nothing in TLC's output distinguishes them, which is why the probe exists.

The probe is the whole technique, and it's worth keeping. Write a property you
expect to fail, one that says the interesting thing never happens, and check that
it does fail. A passing probe means your real property was never asked a
question. There's no built-in version of this, so I think you have to build it by
hand every time, one probe per antecedent you care about.

Worth trying if you have a spare minute. Change the first `~>` in `Chain` to a
plain `=>` and run `Depot.cfg` with `MaxOpen == 2`. It comes back `OK`. A bare
implication with no box around it is checked in the first state only, where
`booked` is empty and the implication holds without effort. That's a second way
to write a property that can't fail, and it looks even more like the real thing.
