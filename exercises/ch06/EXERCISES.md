# Exercises: learntla core ch.6, Structured Data

Five exercises. Budget 10 to 15 minutes each once you've read the chapter.

PlusCal here uses c-syntax, braces not begin/end.

Nothing here needs a construct from past chapter 6. If you find yourself
reaching for `either`, `with x \in Set`, or a recursive operator, back up. The
answer is in chapters 2 through 6.

## Before you start

Copy the files from `starters/` next to wherever you're working. Every exercise
ships its `.cfg`, so you write the `.tla` and leave the config alone. The config
also pins the invariant names, which is what makes your verdict match the one
each exercise states.

Fill in a row of `LOG.md` per exercise. For exercise 2 the prediction column is
the whole point, so write your prediction down **before** you run TLC.

## How to run anything here

Run from the root of your `tla-puzzles` checkout, so `harness/verdict.sh`
resolves. `DIR` below is wherever you put your answer, and both paths are
relative to the checkout root.

```
pcal DIR/YourSpec.tla                                    # PlusCal specs only
bash harness/verdict.sh DIR/YourSpec.tla -c DIR/YourSpec.cfg
```

Each exercise's "how to run" line names the two commands with the spec name
filled in. Put your own `DIR` in front of both paths.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status, not from anything TLC printed, so read that token and ignore the
console noise above it. `OK` means the model check found nothing.
`SAFETY_VIOLATION` means an invariant failed. `ASSUMPTION_FAILED` means an
`ASSUME` came out false.

State counts are not part of any expected outcome below. Two correct answers
can explore different numbers of states, and neither is wrong.

## Exercise 1

- Title: `Parcel desk`
- Format: `write-from-prompt`
- Task: Write `ParcelDesk.tla` from scratch, using `starters/ParcelDesk.cfg`
  unchanged.
  1. A parcel is a struct with three fields. `kilos` is 1 to `MaxKilos`,
     `depot` is one of the `Depots`, and `express` is a boolean. Define
     `MaxKilos == 4`, take `Depots` as a `CONSTANT`, and define `ParcelType`
     as the set of all well formed parcels.
  2. Declare one variable `parcel`, ranging over `ParcelType` at startup, so
     the run covers every parcel shape.
  3. In a `define` block, write `TypeOK` saying `parcel` stays in
     `ParcelType`, and `KeysAreFixed` saying `parcel` always carries exactly
     the keys `kilos`, `depot`, and `express`. Get the second one from
     `DOMAIN`.
  4. Two labels. `Weigh` adds a kilo, but only while that stays under
     `MaxKilos`. `Upgrade` replaces `parcel` with a struct literal that copies
     `kilos` and `depot` across and sets `express` to `TRUE`.
- Time budget: `15 min`
- Uses: structs as functions from string keys to values, struct sets in a type
  invariant, `DOMAIN` on a struct
- Expected outcome:
  - Pass run: `OK`
  - Fail run: misspell one key in the `Upgrade` struct literal, `expres`
    instead of `express`, and re-run. `SAFETY_VIOLATION`. The lesson is that
    the key set is part of the struct's value, so a typo builds a different
    struct rather than a struct with a bad field.
- How to run: `pcal ParcelDesk.tla` then
  `bash harness/verdict.sh ParcelDesk.tla -c ParcelDesk.cfg`

## Exercise 2

- Title: `Six claims about DOMAIN`
- Format: `predict-then-check`
- Task: Read `starters/DomainProbe.tla`. It makes six claims and asserts all
  six. For each one, decide whether it's true, and write your six answers into
  the prediction column of `LOG.md`. Then run it and see whether the module as
  a whole passes.
  Do this without running anything first. The point isn't the answer, it's
  finding out where your model of `DOMAIN` is wrong.
- Time budget: `10 min`
- Uses: `DOMAIN` over sequences, structs, and function literals alike,
  `:>` and `@@`, including which side wins on a key both sides carry
- Expected outcome:
  - Pass run: `OK`, so all six claims hold
  - Fail run: change `Claim3` to read
    `[i \in 0..2 |-> i * i] = <<0, 1, 4>>` and re-run.
    `ASSUMPTION_FAILED`. A sequence's domain starts at 1, so a function over
    `0..2` isn't a sequence at all, whatever its values are.
- How to run:
  `bash harness/verdict.sh DomainProbe.tla -c DomainProbe.cfg`

## Exercise 3

- Title: `Knob panel`
- Format: `complete-the-skeleton`
- Task: Fill the three `TODO` holes in `starters/KnobPanel.tla`. The file
  doesn't parse until you do.
  - `TODO_1` is the starting `dial`, one function literal putting every knob
    at notch 0.
  - `TODO_2` is `DialType`, the set of every legal dial. Write it against this
    panel's `ceiling`, not against `MaxNotch`.
  - `TODO_3` turns knob `next` up to `ceiling`, updating one entry rather than
    replacing the whole function.
  Note what `ceiling` is doing. It's an ordinary variable picked at startup,
  and `DialType` is written in terms of it, so one run covers a 1-notch panel,
  a 2-notch panel, and a 3-notch panel. That's state sweeping.
- Time budget: `15 min`
- Uses: function sets `[S -> T]` as a type invariant, function literals,
  indexed update of a function, a swept variable parameterizing another
  variable's type
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change `TODO_3`'s answer to turn the knob to `MaxNotch` instead
    of `ceiling`, and re-run. `SAFETY_VIOLATION`. It passes on the 3-notch
    panel and fails on the other two, which is what the sweep bought you.
- How to run: `pcal KnobPanel.tla` then
  `bash harness/verdict.sh KnobPanel.tla -c KnobPanel.cfg`

## Exercise 4

- Title: `Patch desk`
- Format: `write-from-prompt`
- Task: Write `PatchDesk.tla` from scratch, using `starters/PatchDesk.cfg`
  unchanged. You need `EXTENDS TLC` for `:>` and `@@`.
  1. Define `Keys == {"retries", "timeout"}`.
  2. Two variables. `settings` starts as a function putting every key at 0.
     `overridden` starts `FALSE`.
  3. In a `define` block, write `TypeOK` saying `settings` is always a
     function from `Keys` to `0..9`, `KeysAreFixed` saying its domain is
     always exactly `Keys`, and `OverrideSticks` saying that once
     `overridden` is true, `settings["retries"]` is 5.
  4. Two labels. `Override` merges a single key function setting `retries` to
     5 into `settings`, and sets `overridden` to `TRUE`. `Remerge` then merges
     a single key function setting `retries` to 9 into `settings`.
  Build both merges with `:>` and `@@`. Put the operands in the order that
  keeps all three invariants true. Working out which order that is, is the
  exercise.
- Time budget: `12 min`
- Uses: `:>` and `@@` building and merging functions piece by piece,
  `DOMAIN` on a merged function, function sets as a type invariant
- Expected outcome:
  - Pass run: `OK`
  - Fail run: swap the two operands of the `Remerge` merge and re-run.
    `SAFETY_VIOLATION`. `@@` keeps the left side's value on a shared key, so
    operand order is the whole rule.
- How to run: `pcal PatchDesk.tla` then
  `bash harness/verdict.sh PatchDesk.tla -c PatchDesk.cfg`

## Exercise 5

- Title: `Fare table`
- Format: `write-from-prompt`
- Task: Write `FareTable.tla` from scratch, using `starters/FareTable.cfg`
  unchanged. No variables and no algorithm, this is a scratch file like
  exercise 2.
  1. Define `Zones == 1..3` and `MaxFare == 2`.
  2. Define `Fare` as a two-argument function over `Zones`, giving the number
     of zone boundaries a rider crosses. Between zone 1 and zone 3 that's 2,
     and it doesn't matter which way the rider is going.
  3. Assert four things about it. `Symmetric`, that `Fare[a, b]` equals
     `Fare[b, a]` everywhere. `FreeWithinZone`, that a trip inside one zone
     costs 0. `DomainIsPairs`, that `DOMAIN Fare` is `Zones \X Zones`.
     `FareIsTyped`, that `Fare` belongs to the function set from
     `Zones \X Zones` to `0..MaxFare`.
  `DomainIsPairs` is the surprise. A two-argument function isn't a special
  kind of thing, it's a one-argument function over pairs.
- Time budget: `12 min`
- Uses: multi-argument function literals and `f[a, b]`, `DOMAIN` on a
  multi-argument function, function sets as a type
- Expected outcome:
  - Pass run: `OK`
  - Fail run: define `Fare` as plain `a - b` and re-run. `ASSUMPTION_FAILED`.
    Subtraction one way isn't the same as subtraction the other way, and the
    fares go negative besides.
- How to run: `bash harness/verdict.sh FareTable.tla -c FareTable.cfg`
