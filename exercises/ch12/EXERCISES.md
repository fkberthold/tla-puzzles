# Exercises: learntla core ch.12, TLA+

Five exercises. Budget 10 to 15 minutes each once you've read the chapter.

**No PlusCal here, and no `pcal` step.** Every spec in this chapter is written
directly in TLA+, so there's no algorithm block, no `\* BEGIN TRANSLATION`, and
no second copy of anything to keep in step. If you catch yourself typing
`--algorithm`, back up. That's chapter 3, and this chapter is the one that
shows you what it becomes.

Nothing here needs a construct from beyond chapter 12. It also doesn't ask you
to produce one that an earlier chapter owns and this chapter only re-expresses.
`<>` and `[]` are chapter 9's, `pc` is chapter 4's, and `await` is chapter 8's.
All three turn up, because the chapter's whole method is showing you their TLA+
side, and where they turn up the exercise hands them to you already written.

## Before you start

Work inside this directory, the one holding this file. Your answers go in
`starters/`, next to the `.cfg` that ships with each one. Every exercise ships
its `.cfg`, so you write the `.tla` and leave the config alone. The config also
pins the names your module has to define, which is what makes your verdict match
the one each exercise states.

Three exercises ship a `.tla` as well as a `.cfg`. Exercise 3's has two holes in
it. Exercises 4 and 5 ship complete and run as they stand, and there the module
is the question rather than the answer.

Fill in a line of `LOG.md` per exercise. Exercises 4 and 5 are
predict-then-check, and there the prediction is the whole point. Write it on
that exercise's line, or as a comment in the spec, **before** you run TLC.

## How to run anything here

Run from this directory. The harness is named by its full path, so it resolves
from wherever you are, and the spec is named relative to here. Adjust that path
if you cloned tla-puzzles somewhere other than `~/repos`.

```
bash ~/repos/tla-puzzles/harness/verdict.sh starters/YourSpec.tla -c starters/YourSpec.cfg
```

One command, not two. The chapters up to here needed `pcal` first because TLC
reads the translation and never the algorithm. There's no translation in this
chapter, so what you edit is what runs.

The `-c` is spelled out so the pairing is visible. The harness would find the
matching `.cfg` on its own.

Each exercise's "how to run" line names the command with the spec name filled
in. They're true as printed. Exercise 3 adds one flag, and says why.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status, not from anything TLC printed, so that token is all that reaches your
screen. Six tokens come up in this chapter.

- `OK` (0) means the model check found nothing.
- `SAFETY_VIOLATION` (12) is what a failed `INVARIANT` gives you.
- `LIVENESS_VIOLATION` (13) is what a failed `<>` property gives you.
- `SPEC_EVAL_FAILURE` (75) means the spec couldn't be evaluated, so nothing at
  all was checked. This is the chapter's own trap, and it's not a violation.
- `DEADLOCK` (11) means TLC reached a state with no successor. `verdict.sh` only
  looks for it when you pass `-d`, which exercise 3 does.
- `PARSE_ERROR` (150) means the module never compiled. The exercise 3 starter
  begins here, because an unfilled `TODO` is an undefined operator.

`SPEC_EVAL_FAILURE` is the one to get straight before you start, because three
of the five land on it and it's the least familiar token in the set. It does
not mean your invariant failed. It means TLC gave up on the next-state relation
and never got as far as checking anything, so the run tells you nothing at all
about whether your invariant holds. Reading it as a violation is how people end
up believing a check ran when it didn't.

`verdict.sh` prints the token and nothing else. TLC's own output, error trace
included, goes to a scratch file that is deleted when the run ends. Pass
`--log` and it's kept instead:

```
bash ~/repos/tla-puzzles/harness/verdict.sh --log /tmp/tlc.log starters/YourSpec.tla -c starters/YourSpec.cfg
```

Two of the exercises below quote a message out of that file, and exercise 4
asks you to read a counterexample trace. The trace sits part way down that
file, under the two `Error:` lines. Each row is headed `State N:` and carries
one line per variable. TLC's coverage statistics come after it, so the trace is
not the last thing in the file.

State counts are not part of any expected outcome below. Two correct answers can
explore different numbers of states, and neither is wrong.

## Exercise 1

- Title: `The seed drill`
- Format: `write-from-prompt`
- Task: Write `starters/SeedDrill.tla` from scratch, using
  `starters/SeedDrill.cfg` unchanged.
  1. `EXTENDS Integers`. Define `Capacity == 4`, `SeedsPerRow == 2` and
     `MaxRows == 3`.
  2. Two variables, `hopper` and `rows`. The hopper starts full and no rows are
     planted yet. Tuple both into `vars`.
  3. Two actions. `Plant` needs a row still to plant and enough seed for one. It
     takes a row's worth out of the hopper and adds a row. `Refill` runs when
     there isn't enough seed left for a row. It fills the hopper back up, and it
     plants nothing.
  4. `Next` is either action. `Spec` is the chapter's blueprint, `Init` and a
     boxed `Next` subscripted on `vars`.
  5. Two invariants, `HopperInRange` and `RowsInRange`. Each says its variable
     stays inside the range it's supposed to. The `.cfg` pins both names.
  Nothing in this module is an assignment. `hopper' = hopper - SeedsPerRow` is a
  claim about a pair of states, true of exactly the steps that drop the hopper
  by one row's worth. That's the only kind of thing an action can be.
  `Refill` is where the exercise actually is. It says nothing about `rows`
  unless you make it, and an action that leaves a variable out is not a weaker
  claim about that variable. It's a broken one.
- Time budget: `15 min`
- Uses: `VARIABLES` and the `vars` tuple, the `Init` / `Next` / `Spec` skeleton,
  an action as a boolean operator over a pair of states, `UNCHANGED`, and a
  disjunction of two actions as `Next`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: delete `/\ UNCHANGED rows` from `Refill` and re-run.
    `SPEC_EVAL_FAILURE`. Not a violation. Neither invariant was checked at all.
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/SeedDrill.tla -c starters/SeedDrill.cfg`

### After the run

The message behind the fail run is worth reading once, because it names the
action rather than the variable you were thinking about.

```
Successor state is not completely specified by action Refill of the
next-state relation. The following variable is not defined: rows.
```

TLC is not complaining that `rows` is missing from the module. It's complaining
that one action failed to say what `rows` does. Every action has to describe
every variable, every time, and `UNCHANGED` is how you say "nothing".

One trap this exercise can't catch for you, and it's worth knowing before it
bites. If you leave a variable out of the `vars` tuple instead, say
`vars == << hopper >>`, TLC accepts the spec and reports `OK`. It does print a
warning about the subscript, and `verdict.sh` runs with `-nowarning`, so under
this harness you'll never see it. That failure is silent here. Count the names
in your tuple against the names on your `VARIABLES` line.

## Exercise 2

- Title: `The apiary`
- Format: `write-from-prompt`
- Task: Write `starters/Apiary.tla` from scratch, using `starters/Apiary.cfg`
  unchanged.
  1. `EXTENDS Integers`. Define `Hives == {"clover", "heather", "lime"}` and
     `MaxFrames == 3`.
  2. One variable, `frames`, a function from each hive to how many frames it
     holds. Every hive starts with one.
  3. `AddFrame(h)`. A hive below the limit gains a frame. Write the new value
     relative to the old one, so the old one appears as `@` and the hive's name
     appears once.
  4. `MoveFrame(a, b)`. Two different hives, the first with a frame to give and
     the second with room to take it. One frame leaves `a` and arrives at `b`,
     in one step. Both keys go in one `EXCEPT`.
  5. `Next` is either a hive gaining a frame or a frame moving, with the hive or
     the pair of hives chosen nondeterministically. Both use `\E`.
  6. `Spec`, and one invariant `FramesInRange` saying no hive holds a count
     outside `0..MaxFrames`. The `.cfg` pins the name.
  The obvious way to write `MoveFrame` is two lines, one per hive, each priming
  its own lookup. Try it if you like. The chapter says what happens and the
  After-the-run section says what token you get.
- Time budget: `12 min`
- Uses: `EXCEPT` on a function-valued variable, `@` as the old value, two keys
  in one `EXCEPT`, and `\E` as the nondeterministic form of an action
- Expected outcome:
  - Pass run: `OK`
  - Fail run: delete the conjunct that checks the receiving hive has room, and
    re-run. `SAFETY_VIOLATION`.
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Apiary.tla -c starters/Apiary.cfg`

### After the run

Two things this exercise is set up to teach, and only one of them is the pass
run.

Write `MoveFrame` as `frames[a]' = frames[a] - 1 /\ frames[b]' = frames[b] + 1`
and you get `SPEC_EVAL_FAILURE`, with

```
In evaluation, the identifier frames is either undefined or not an operator.
```

which is the message the chapter singles out as unhelpful, and it is. Nothing in
that sentence points at the line you wrote or at the key you left out.
The rule underneath it is the same one exercise 1 was about. An action describes
the whole variable in the next state or it describes nothing, and `frames[a]'`
describes one key. `EXCEPT` exists because the syntax for "the whole function,
except here" would otherwise be unbearable, and the chapter admits it's still
awkward.

The second thing is what `FramesInRange` doesn't buy you. Drop the `![b] = @ + 1`
half of the `EXCEPT` so a frame leaves `a` and arrives nowhere, and the run comes
back `OK`. Every count is still inside its range. A range invariant is a claim
about how big the numbers are, and losing a frame doesn't make a number too big.
Catching that one wants a conservation invariant instead, and this spec can't
carry one, because `AddFrame` creates frames on purpose.

## Exercise 3

- Title: `Two glaziers, one bench`
- Format: `complete-the-skeleton`
- Task: Fill the two holes in `starters/GlazingBench.tla`, marked `TODO_1` and
  `TODO_2`. The file doesn't compile until you do.
  Two glaziers share one cutting bench. Each one mounts a pane, then cuts it,
  then is done. Only one of them may hold the bench at a time. Everything except
  the two labels is already written: `Trans`, `Init`, `Terminating`, `Next`, and
  the two invariants.
  `TODO_1` is `Mount(self)`. The glazier moves from label `"Mount"` to label
  `"Cut"`, which is what `Trans` is for. It may only do so while the bench is
  free, and it comes away holding the bench. It cuts nothing.
  `TODO_2` is `Cut(self)`. The glazier moves from `"Cut"` to `"Done"`, gives the
  bench back, and adds one to the pane count.
  Two things to keep in mind. There's no `await` construct in TLA+ and there
  doesn't need to be. "Only while the bench is free" is the plain conjunct
  `bench = Free`, sitting in the action alongside everything else, and it simply
  fails to enable the action when it's false. And each action has to account for
  all three variables, `Trans` covering only `pc`.
  Note the `-d` in the command. `verdict.sh` doesn't look for deadlock unless
  you ask, and `Terminating` is in this file so there won't be one, so ask.
- Time budget: `15 min`
- Uses: a label encoded as a `pc` guard plus a `pc'` update, the `Trans` helper
  action, `ProcSet`, `\E self \in Glaziers` as the whole of the concurrency,
  `await` as a plain conjunct, and `Terminating`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: delete the conjunct that checks the bench is free, and re-run.
    `SAFETY_VIOLATION`.
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh -d starters/GlazingBench.tla -c starters/GlazingBench.cfg`

### After the run

This module is the shape `pcal` writes, and the point of writing it by hand is
that there's nothing in it you haven't seen. Sequence is a `pc` guard and a
`pc'` update. Concurrency is one `\E self`. There is no third thing.

`Terminating` is the piece with no PlusCal counterpart you'd recognize, because
the translator inserts it silently. Delete it from `Next` and re-run with `-d`
and you get `DEADLOCK`. The state where both glaziers are Done has no successor,
and `Terminating` is a self-loop bolted on to give it one. Without `-d` that
same edit reports `OK`, which tells you what the flag is worth.

If you left `UNCHANGED panes` out of `Mount`, you got `SPEC_EVAL_FAILURE` and
the message from exercise 1. Three variables now instead of two, and the rule
hasn't changed.

## Exercise 4

- Title: `Which winches are fair`
- Format: `predict-then-check`
- Task: Read `starters/Drawbridge.tla`. It's complete and runs as it stands. Two
  winches raise a drawbridge, each needs `Target` turns, and the property says
  the bridge eventually goes up.
  Make two predictions and write both on the exercise 4 line of `LOG.md` before
  you run anything.
  1. What verdict does the file give as shipped?
  2. Now change the one `\A` in `Spec` to `\E`, so the fairness conjunct reads
     `\E w \in Winches : WF_vars(Raise(w))`. What verdict does that give?
  This is the chapter's own comprehension test, and it asks you to read a
  quantifier over a temporal formula rather than over a set of values. Don't
  reason about which is conventional. Reason about what each one promises.
- Time budget: `10 min`
- Uses: a fairness conjunct on `Spec`, `WF_v(A)`, and `\A` against `\E` over a
  set of processes
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Drawbridge.tla -c starters/Drawbridge.cfg`
  and, after you edit `Spec`,
  `bash ~/repos/tla-puzzles/harness/verdict.sh --log /tmp/drawbridge.log starters/Drawbridge.tla -c starters/Drawbridge.cfg`.
  The second run is the one whose counterexample you need, so keep its log.

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Second run: `LIVENESS_VIOLATION`

Neither run is a `PARSE_ERROR`, because TLC accepts a quantifier over a
temporal formula, and `\E` here is a spec with a meaning rather than a typo.

`\A` promises that every winch keeps turning while it still can, so both of them
reach `Target` and the bridge goes up.

`\E` promises that some winch does. One is enough to satisfy the whole
conjunct, and TLC's counterexample is a behavior where one winch reaches
`Target` and the other stops short and stays there. Read the trace in
`/tmp/drawbridge.log` and check which winch stalled, because the fairness
conjunct is still satisfied in that behavior and the reason is worth sitting
with. The winch that finished has `Raise` disabled from then on, and weak
fairness on a permanently disabled action is vacuously true. The `\E` is
satisfied by a winch that has nothing left to do.

Two smaller things worth keeping.

Delete the fairness conjunct altogether and you also get `LIVENESS_VIOLATION`.
The token doesn't distinguish "I quantified the wrong way" from "I forgot
fairness entirely", so it tells you the property failed and nothing about why.

The subscript is doing no work in this particular spec. `vars` is the one-element
tuple `<< turns >>`, so `WF_turns(Raise(w))` and `WF_vars(Raise(w))` are the same
formula and swapping them changes nothing. That's a fact about this spec having
one variable, not a general one, and exercise 5 has the case where it bites.

## Exercise 5

- Title: `One label, two branches`
- Format: `predict-then-check`
- Task: Read `starters/Capper.tla`. It's complete and runs as it stands. A
  bottle arrives at a capping station and the press then either caps it or waves
  it through bare. Those two are branches of one press stroke, so `Press` is
  their disjunction and `Next` never mentions them separately.
  Make two predictions and write both on the exercise 5 line of `LOG.md` before
  you run anything.
  1. What verdict does the file give as shipped?
  2. Now weaken the second fairness conjunct from `SF_vars(Cap)` to
     `WF_vars(Cap)`, changing nothing else. What verdict does that give?
  For the second one, work from the definitions the chapter gives rather than
  from a feeling about which is stronger. `WF_v(A)` has `<>[](ENABLED <<A>>_v)`
  on its left, and `SF_v(A)` has `[]<>(ENABLED <<A>>_v)`. Ask when `Cap` is
  enabled and when it isn't.
- Time budget: `15 min`
- Uses: `WF_v(A)` against `SF_v(A)`, `ENABLED` and `<<A>>_v` inside their
  definitions, and fairness on a named branch rather than on a whole label
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Capper.tla -c starters/Capper.cfg`
  and, after you edit `Fairness`, the same command again

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Second run: `LIVENESS_VIOLATION`

`Cap` is disabled at every state where the station is empty, and every press
stroke empties the station. So `Cap` is infinitely often enabled and never
eventually always enabled. `[]<>(ENABLED ...)` is true of that and
`<>[](ENABLED ...)` is false, which is the whole difference between the two
runs. Weak fairness on `Cap` promises nothing here, because its precondition
never comes true.

The common wrong guess is that strong and weak differ only in how hard TLC
looks. They don't. They're two different formulas with two different left-hand
sides, and on an action that keeps switching off, one of them is vacuous.

Two more edits worth making while the file is open. Both are one word.

Change `SF_vars(Cap)` to `SF_vars(Press)` and you get `LIVENESS_VIOLATION`.
Marking the whole label fair says the press stroke keeps happening, and a press
that waves every bottle through is a press stroke that keeps happening. Naming
the branch is the only way to say the thing you meant, and reaching inside a
label like that is one of the things PlusCal can't do.

Change `WF_vars(Arrive)` to `WF_capped(Arrive)` and you get
`LIVENESS_VIOLATION` again. `Arrive` never touches `capped`, so
`<<Arrive>>_capped` is never enabled, so that conjunct promises nothing at all.
Then no bottle ever arrives, `Cap` is never enabled, and the strong fairness on
it goes vacuous too. This is what the subscript on a fairness operator is for,
and it's the case exercise 4 didn't have.
