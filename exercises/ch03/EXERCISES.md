# Chapter 03 exercises: Writing Specifications

Five exercises, 10 to 15 minutes each once you've read the chapter.

## Before you start

Every module here is PlusCal, so every module needs translating before TLC
sees anything. The translator is `pcal`:

```
pcal -nocfg MyModule.tla
```

`-nocfg` stops `pcal` rewriting your `.cfg`. Every `.cfg` in this set holds
one line:

```
SPECIFICATION Spec
```

Verdicts come from the harness, never from what TLC printed:

```
bash harness/verdict.sh -c MyModule.cfg MyModule.tla
```

That prints one token and exits with TLC's own status. `harness/verdict.sh`
is a path into the `tla-puzzles` checkout, so run it from there and give it
the path to your module.

The tokens you'll meet in this set:

- `OK` (0): TLC explored the whole state space and found nothing wrong.
- `ASSERT_VIOLATION` (14): an `assert` was false during exploration.
- `CONFIG_ERROR` (151): the `.cfg` names `Spec` and the module has no `Spec`.

`CONFIG_ERROR` almost always means you forgot to translate.

For the predict-then-check exercises, write your prediction in `LOG.md`
before you run anything. A prediction written after the fact isn't one.

## Exercise 1

- Title: `Change dispenser`
- Format: `write-from-prompt`
- Task: Write a module `Ex1Dispenser` from scratch. It owes a customer some
  amount between 0 and 12 cents, and it pays that amount out in nickels and
  pennies, largest coin first. Declare `owed` so that TLC runs the model once
  for every amount in the range rather than for one fixed amount. Pay the
  money out in a loop. Use a `macro` for the pay-one-coin step, since it
  happens twice. Finish with a label that asserts three things: nothing is
  still owed, the payout used fewer than 5 pennies, and the coins add up to
  what was owed at the start. That last assert needs a variable holding the
  original amount, so record it in a label of its own before the loop starts.
- Time budget: `15 min`
- Uses: `\in` on a variable declaration. `while`. PlusCal `if`. `macro`.
  `assert` with `EXTENDS TLC`. Every statement belongs to a label. Pick any
  label names you like except `Done`, which the translator reserves.
- Expected outcome:
  - Pass run: `OK` (rc 0) on `references/Ex1Dispenser.tla`.
  - Fail run: `ASSERT_VIOLATION` (rc 14) on
    `references/Ex1DispenserFail.tla`, which differs by one character. Its
    guard reads `owed > 5` where the working one reads `owed >= 5`, so an
    amount of exactly 5 comes out as five pennies.
- How to run:
  ```
  pcal -nocfg Ex1Dispenser.tla
  bash harness/verdict.sh -c Ex1Dispenser.cfg Ex1Dispenser.tla
  ```

The third assert is the one that earns its place. Drop it and a dispenser
that counts a nickel while handing over a penny still passes.

## Exercise 2

- Title: `The translation is what runs`
- Format: `predict-then-check`
- Task: Open `starters/Ex2Stale.tla`. It arrives already translated, which no
  other starter in this set does. Read the PlusCal, work out what `setpoint`
  should be at the `Check` label, and write that number and your predicted
  verdict in `LOG.md`. Then run TLC without touching the file. Then run
  `pcal` and run TLC again. Explain the difference before you read the
  references.
- Time budget: `10 min`
- Uses: PlusCal compiles to TLA+ through a translation step in a comment
  block, and TLC runs the translated output.
- Expected outcome:
  - Pass run: `OK` (rc 0) on `references/Ex2Fresh.tla`, which holds that same
    PlusCal with the translation regenerated.
  - Fail run: `ASSERT_VIOLATION` (rc 14) on `references/Ex2Stale.tla` as it
    ships. The translation is left over from an earlier draft where `Warmer`
    read `setpoint + 3`, so TLC checks 70 against an assert wanting 69.
- How to run:
  ```
  bash harness/verdict.sh -c Ex2Stale.cfg Ex2Stale.tla
  pcal -nocfg Ex2Stale.tla
  bash harness/verdict.sh -c Ex2Stale.cfg Ex2Stale.tla
  ```

Nobody edits a translation on purpose. Everybody forgets to retranslate.

## Exercise 3

- Title: `Retry with goto`
- Format: `write-from-prompt`
- Task: Write a module `Ex3Retry` from scratch. A dialer counts its attempts
  and gives up trying after the third one. Use one label for the dial step.
  While the count is below 3, jump back to that label with `goto`. Otherwise
  set a `linked` flag. Finish with a second label that asserts the flag is
  set and the count is exactly 3. Then break it on purpose: put one more
  statement after the `goto`, with no label between them, and translate
  again.
- Time budget: `12 min`
- Uses: `goto` and its labeling rule. Labels as atomic steps. `assert`.
- Expected outcome:
  - Pass run: `OK` (rc 0) on `references/Ex3Retry.tla`.
  - Fail run: `pcal` exits 255 on `references/Ex3RetryFail.tla` and refuses
    to write a translation, reporting a missing label. Running the harness on
    the module anyway gives `CONFIG_ERROR` (rc 151), because a module with no
    translation has no `Spec` for the `.cfg` to name.
- How to run:
  ```
  pcal -nocfg Ex3Retry.tla
  bash harness/verdict.sh -c Ex3Retry.cfg Ex3Retry.tla
  ```

A `goto` at the end of a branch is fine. The rule bites when a statement
follows the `goto` in the same label, because that statement can never run.

## Exercise 4

- Title: `One step, two tanks`
- Format: `complete-the-skeleton`
- Task: Open `starters/Ex4Tanks.tla`. Two tanks hold 7 litres between them,
  all of it in tank 1. Fill in the `Pump` label so that 3 litres move from
  tank 1 to tank 2. Both halves of the move belong to that one label, and
  `tanks` may only be updated once in it, so you need the simultaneous
  assignment operator. Bind the 3 to a name with `with` instead of writing
  the literal twice. Leave `Audit` and `Settle` alone. Then try the other
  way: split the move into a `Drain` label and a `Fill` label with `Audit`
  between them, and run it again.
- Time budget: `12 min`
- Uses: `||`. `with`. A variable updates once per label. Label placement
  decides what is atomic.
- Expected outcome:
  - Pass run: `OK` (rc 0) on `references/Ex4Tanks.tla`.
  - Fail run: `ASSERT_VIOLATION` (rc 14) on `references/Ex4TanksSplit.tla`.
    Nothing changed but the labels. `Drain` and `Fill` are separate steps, so
    `Audit` sees a moment where 3 litres are in neither tank and the total
    reads 4.
- How to run:
  ```
  pcal -nocfg Ex4Tanks.tla
  bash harness/verdict.sh -c Ex4Tanks.cfg Ex4Tanks.tla
  ```

The skeleton as shipped gives `ASSERT_VIOLATION` once translated, since a
`skip` moves no water. That's your starting red.

## Exercise 5

- Title: `Does that label ever run?`
- Format: `predict-then-check`
- Task: Open `starters/Ex5Sensor.tla`. Translate it and run it. It reports
  `OK`. Now answer the question that `OK` doesn't: which of `Sense`, `Trip`
  and `Settle` does TLC actually reach? Write your answer in `LOG.md` first.
  Then find out without reading any state counts. Put `assert FALSE;` as the
  first statement of the label you're asking about and run it again. A label
  that never runs never fires its assert. Do it for `Trip`, then move the
  probe to `Settle` and run once more.
- Time budget: `12 min`
- Uses: `assert` as a reachability probe. `\in` on a variable declaration.
  A label inside an `if` branch forces a label after the block. `skip`.
- Expected outcome:
  - Pass run: `OK` (rc 0) on `references/Ex5DeadLabel.tla`, which carries the
    probe in `Trip`. `temp` never exceeds 30, so the guard `temp > 40` never
    holds and `Trip` is dead.
  - Fail run: `ASSERT_VIOLATION` (rc 14) on `references/Ex5LiveLabel.tla`,
    the same module with the probe moved to `Settle`.
- How to run:
  ```
  pcal -nocfg Ex5Sensor.tla
  bash harness/verdict.sh -c Ex5Sensor.cfg Ex5Sensor.tla
  ```

Run both. An `OK` from a probe means one of two things, and only the second
run tells you which. Either the label is unreachable, or your probe never
worked at all.
