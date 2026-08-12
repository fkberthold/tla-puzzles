# Exercise set: learntla core chapter 5, Parameterizing Specs

Five exercises. Ten to fifteen minutes each once you have read the chapter.

Everything here uses constructs from chapters 2 to 5 only. No records, no
functions. Those belong to chapter 6.

## Before you start

Copy `exercises/templates/LOG.md` to `exercises/ch05/LOG.md` and fill in a row
per exercise as you go.

Two exercises below are marked predict-then-check. For those, write your
prediction into `LOG.md` BEFORE you run TLC. The prediction is the exercise.
Running first and writing the answer afterwards teaches you nothing.

## How verdicts work here

Every stated outcome is a verdict token from `harness/verdict.sh`. The token
comes from TLC's exit code and from nothing else. Do not judge a run by what
scrolled past on the console.

The tokens you will meet in this set:

- `OK` means TLC found no error.
- `ASSUMPTION_FAILED` means an `ASSUME` was false. The run stopped before any
  state was generated.
- `SAFETY_VIOLATION` means an invariant was refuted, and there is a trace.
- `SPEC_EVAL_FAILURE` means the spec could not be evaluated. Nothing is known
  about whether your invariant holds, because the check never ran.
- `CONFIG_ERROR` means the `.cfg` names something the module does not define,
  or leaves a declared constant unassigned.
- `TLC_EXCEPTION` means TLC refused the model outright.

Run everything from the repository root.

## A note on the `.cfg`

This chapter is the one where the `.cfg` stops being boilerplate. It is where
constant values land, so it is part of the lesson, not scaffolding around it.
Read the `.cfg` of every reference before you read its `.tla`.

One thing the chapter does not tell you, because it describes the toolbox: a
`.cfg` assigns a literal, never an expression. `CONSTANT N = 3` works.
`CONSTANT N = -1` and `CONSTANT N = 0 - 1` are both config syntax errors. The
toolbox can take an expression because it writes a generated module for you.
The `.cfg` route cannot.

---

## Exercise 1

- Title: `Lift a hardcoded number out of the spec`
- Format: `write-from-prompt`
- Task: Start from `starters/Allowance.tla`. It spends a credit balance two at
  a time and checks the balance never goes negative, with the starting balance
  welded in as `4`. Replace that `4` with a `CONSTANT` named `StartingCredit`
  and supply the value from the `.cfg` instead. Re-run `pcal Allowance.tla`
  after you edit. Then write two `.cfg` files, one that passes and one that
  finds the bug in the spend loop. You are looking for a starting credit that
  makes the loop step past zero.
- Time budget: `10 min`
- Uses: Constants defer concrete values to the model run, keeping the spec free
  of hardcoded settings.
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION`
- How to run:
  ```
  bash harness/verdict.sh exercises/ch05/references/ex1-allowance/Allowance.tla
  bash harness/verdict.sh \
    -c exercises/ch05/references/ex1-allowance/AllowanceOdd.cfg \
    exercises/ch05/references/ex1-allowance/Allowance.tla
  ```

The point is what did not change. One spec, two models, two verdicts. The bug
was always there. The small model just never reached it.

---

## Exercise 2

- Title: `What an ASSUME buys you`
- Format: `predict-then-check`
- Task: Read `references/ex2-kiln/Kiln.tla`. It has two constants and two
  `ASSUME` lines. Write down, in `LOG.md`, what verdict you expect from
  `KilnBackwards.cfg`, which sets a deadline earlier than the warmup. Then run
  it. Now comment out both `ASSUME` lines, predict again, and run again with
  the same `.cfg`.
- Time budget: `12 min`
- Uses: `ASSUME` documents and enforces valid constant values before a run
  starts.
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `ASSUMPTION_FAILED`
- How to run:
  ```
  bash harness/verdict.sh exercises/ch05/references/ex2-kiln/Kiln.tla
  bash harness/verdict.sh \
    -c exercises/ch05/references/ex2-kiln/KilnBackwards.cfg \
    exercises/ch05/references/ex2-kiln/Kiln.tla
  ```

With the guards commented out the same `.cfg` reports `SAFETY_VIOLATION`
instead. Both runs fail, so both catch the mistake. They do not cost the same
to read. `ASSUMPTION_FAILED` names a bad constant. `SAFETY_VIOLATION` hands you
a trace and lets you spend ten minutes hunting a bug that is not in the
algorithm.

Note which guard you can actually trip. `ASSUME Deadline > Warmup` and
`ASSUME Deadline <= 6` are both reachable from a `.cfg`. A guard like
`ASSUME Warmup >= 0` is not, because a `.cfg` cannot write a negative number.
A guard nobody can trip is documentation, not a check.

---

## Exercise 3

- Title: `A sentinel that cannot collide`
- Format: `complete-the-skeleton`
- Task: Start from `starters/Locker.tla`. A locker is held by a slot id or by
  nobody, and `Unclaimed` is the constant meaning nobody. `claimed` records the
  same fact a second way. Two holes. First, replace the body of
  `FreeIffSentinel`, which is `TRUE` and so checks nothing, with a predicate
  tying `claimed` to whether `holder` is still `Unclaimed`. Second, write the
  `.cfg` twice. Once assigning `Unclaimed` an ordinary integer of your choice.
  Once assigning it a model value. Run both.
- Time budget: `15 min`
- Uses: Model values give an opaque, self-only-equal type for sentinels and
  placeholders.
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION`
- How to run:
  ```
  bash harness/verdict.sh exercises/ch05/references/ex3-locker/Locker.tla
  bash harness/verdict.sh \
    -c exercises/ch05/references/ex3-locker/LockerCollide.cfg \
    exercises/ch05/references/ex3-locker/Locker.tla
  ```

Compare the two `.cfg` files in that directory. On the right of the `=`, a bare
word with no quotes is a model value. `2` is an integer and `"free"` is a
string, and both of those are values your spec might legitimately hold.

Try `"free"` as well. That run reports `SPEC_EVAL_FAILURE`, not a violation.
TLC did not decide your invariant was false. It could not evaluate it at all,
because comparing a string to an integer is an error rather than a `FALSE`.
That is the failure the chapter is warning you about, and a model value is the
thing that does not have it.

An `ASSUME Unclaimed \notin Slots` would have caught the integer case up front,
the way exercise 2 catches its bad pair. Worth adding once you have seen the
violation.

---

## Exercise 4

- Title: `Why a symmetry set needs model values`
- Format: `predict-then-check`
- Task: Read `references/ex4-relay/Relay.tla` and `Relay.cfg`. `Runners` is a
  set of three model values, and the `.cfg` hands it to TLC as a symmetry set
  through the `SYMMETRY` line. Write down, in `LOG.md`, what you expect to
  happen if the only change is that `Runners` becomes `{1, 2, 3}`, three
  ordinary integers, with the `SYMMETRY` line left exactly as it is. Then run
  `RelayOrdinary.cfg` and compare.
- Time budget: `10 min`
- Uses: Symmetry sets collapse states that only differ by relabeling model
  values.
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `TLC_EXCEPTION`
- How to run:
  ```
  bash harness/verdict.sh exercises/ch05/references/ex4-relay/Relay.tla
  bash harness/verdict.sh \
    -c exercises/ch05/references/ex4-relay/RelayOrdinary.cfg \
    exercises/ch05/references/ex4-relay/Relay.tla
  ```

The refusal is the lesson. Symmetry says relabeling the values leaves the spec
alone. That is true of model values, which support nothing but equality. It is
not true of integers, which you can add and order, so TLC declines rather than
quietly giving you a wrong answer.

`Perms == Permutations(Runners)` in the module is the command line spelling of
the toolbox symmetry checkbox. Outside the toolbox you have to name the
permutation set yourself and point the `SYMMETRY` keyword at it.

---

## Exercise 5

- Title: `A constant that picks a behaviour`
- Format: `write-from-prompt`
- Task: Start from `starters/Rehearsal.tla`. A counter climbs to a ceiling of
  `5`, and the invariant wants it to stop at `2`, so the starter fails. Add one
  boolean constant that selects between a strict ceiling of `2` and a loose one
  of `5`, so a `.cfg` can ask for either behaviour without touching the spec.
  Constrain it with an `ASSUME`. Re-run `pcal Rehearsal.tla`, then write both
  `.cfg` files and run each.
- Time budget: `12 min`
- Uses: Constants can also steer a spec's behavior, not just supply data, like
  a `DEBUG` flag.
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION`
- How to run:
  ```
  bash harness/verdict.sh exercises/ch05/references/ex5-rehearsal/Rehearsal.tla
  bash harness/verdict.sh \
    -c exercises/ch05/references/ex5-rehearsal/RehearsalLoose.cfg \
    exercises/ch05/references/ex5-rehearsal/Rehearsal.tla
  ```

The constant here carries no data at all. It names which of two specs you meant.
Check your `ASSUME` earns its place by putting a `7` in the `.cfg` where the
boolean goes. Without the guard, `IF StrictMode` on a non-boolean is a surprise
you get to debug later. With it, the run stops at once with
`ASSUMPTION_FAILED`.

---

## References

One runnable reference per exercise under `references/`, each a `.tla` plus a
passing `.cfg` and a failing `.cfg`. Read them after you have made your own
attempt, not before.

Every verdict stated above was reproduced through `harness/verdict.sh` on
TLC2 2026.07.31.184830. The runs are recorded in `reports/authoring.md`,
alongside the seeded mutants used to check that these references fail when
they should.
