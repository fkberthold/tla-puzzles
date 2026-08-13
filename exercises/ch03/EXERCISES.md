# Chapter 03 exercises: Writing Specifications

Five exercises, 10 to 15 minutes each once you've read the chapter.

PlusCal here uses c-syntax, braces not begin/end.

## Before you start

Run every command in this file from this chapter directory, the one holding
`starters/` and `LOG.md`. They're true as printed. The harness is a script in
the puzzles repo, so adjust `~/repos/tla-puzzles` to wherever you cloned it.

Every module here is PlusCal, so every module needs translating before TLC
sees anything. The translator is `pcal`:

```
pcal starters/MyModule.tla
```

Every `.cfg` in this set holds one line:

```
SPECIFICATION Spec
```

`pcal` writes the `.cfg` beside your module as well, but it won't replace a
`SPECIFICATION` line that's already there. Every `.cfg` here has one, so plain
`pcal` is safe on all of them.

Exercises 1 and 3 ship no starter: you write the module and its `.cfg`
yourself. Put both in `starters/`, named after the module, and give the `.cfg`
the one `SPECIFICATION Spec` line above. Then every command below is true as
printed.

Two exercises here ask for a module from scratch, so you pick your own label
names. `Done` is not one of them: the translator uses it for the value `pc`
takes when the algorithm finishes, and rejects it with
`Cannot use 'Done' as a label.`

Verdicts come from the harness, never from what TLC printed:

```
bash ~/repos/tla-puzzles/harness/verdict.sh starters/MyModule.tla -c starters/MyModule.cfg
```

That prints one token and exits with TLC's own status.

The tokens you'll meet in this set:

- `OK` (0): the model check found nothing.
- `ASSERT_VIOLATION` (14): an `assert` was false during exploration.
- `PARSE_ERROR` (150): the file did not parse. A module you're still writing
  spends time here.
- `CONFIG_ERROR` (151): the config names something your file does not define
  yet, such as a `Spec` that only the translation defines.

`CONFIG_ERROR` almost always means you forgot to translate.

Fill in a line of `LOG.md` per exercise. `LOG.md` is delivered beside this
file. For the predict-then-check exercises, write your prediction on that line,
or as a comment in your spec, before you run TLC. A prediction written after
the fact isn't one.

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
  `assert` with `EXTENDS TLC`. Every statement belongs to a label.
- Expected outcome:
  - Pass run: `OK` (rc 0) on your own `Ex1Dispenser.tla`, once it translates.
  - Fail run: `ASSERT_VIOLATION` (rc 14) once the guard reads `owed > 5` where
    the working one reads `owed >= 5`, so an amount of exactly 5 comes out as
    five pennies. Change it back afterwards.
- How to run:
  ```
  pcal starters/Ex1Dispenser.tla
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex1Dispenser.tla -c starters/Ex1Dispenser.cfg
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
- Uses: The translation comment block. `assert` with `EXTENDS TLC`. Labels.
- Expected outcome: the same file gives two different verdicts, and which one
  you get first is the exercise. See After the run below.
- How to run:
  ```
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex2Stale.tla -c starters/Ex2Stale.cfg
  pcal starters/Ex2Stale.tla
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex2Stale.tla -c starters/Ex2Stale.cfg
  ```

### After the run

Run before you read on.

- Expected outcome:
  - First run: `ASSERT_VIOLATION` (rc 14) on `starters/Ex2Stale.tla` as it
    ships. The translation is left over from an earlier draft where `Warmer`
    read `setpoint + 3`, so TLC checks 70 against an assert wanting 69.
  - Second run: `OK` (rc 0) on that same file, once `pcal` has regenerated the
    translation from the PlusCal you read.

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
  - Pass run: `OK` (rc 0) on your own `Ex3Retry.tla`, once it translates.
  - Fail run: once a statement follows the `goto` in the same label, `pcal`
    exits 255 and refuses to write a translation, reporting a missing label.
    Running the harness on the module anyway gives `CONFIG_ERROR` (rc 151),
    because a module with no translation has no `Spec` for the `.cfg` to name.
    Take the statement back out afterwards.
- How to run:
  ```
  pcal starters/Ex3Retry.tla
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex3Retry.tla -c starters/Ex3Retry.cfg
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
  - Pass run: `OK` (rc 0) on your own `starters/Ex4Tanks.tla`, once `Pump`
    moves the water in one label.
  - Fail run: `ASSERT_VIOLATION` (rc 14) once the move is split into a `Drain`
    label and a `Fill` label with `Audit` between them. Nothing changed but the
    labels. `Drain` and `Fill` are separate steps, so `Audit` sees a moment
    where 3 litres are in neither tank and the total reads 4.
- How to run:
  ```
  pcal starters/Ex4Tanks.tla
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex4Tanks.tla -c starters/Ex4Tanks.cfg
  ```

The starter as shipped gives `ASSERT_VIOLATION` once translated, since a
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
- Expected outcome: the same file gives two different verdicts, and which one
  you get first is the exercise. See After the run below.
- How to run:
  ```
  pcal starters/Ex5Sensor.tla
  bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex5Sensor.tla -c starters/Ex5Sensor.cfg
  ```

Retranslate after every move of the probe. The two commands go together.

### After the run

Run before you read on.

- Expected outcome:
  - Probe in `Trip`: `OK` (rc 0) on your own `starters/Ex5Sensor.tla`. `temp`
    never exceeds 30, so the guard `temp > 40` never holds and `Trip` is dead.
  - Probe in `Settle`: `ASSERT_VIOLATION` (rc 14) on that same file, the probe
    moved and nothing else changed.

Run both. An `OK` from a probe means one of two things, and only the second
run tells you which. Either the label is unreachable, or your probe never
worked at all.

## Answers

`references/` in the puzzles repo holds a worked answer per exercise, and a
broken copy for every fail run named above. It is not delivered into a
practice tree, on purpose. Read it once your own module runs, not before.
