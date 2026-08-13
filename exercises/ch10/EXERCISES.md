# Chapter 10 exercises: More Operators

Five exercises over the constructs in the chapter 10 cheat sheet. Everything
here is plain TLA+ operators. Nothing in this set needs PlusCal, so the
dialect question never comes up. If you reach for PlusCal anyway, this project
writes c-syntax with braces.

## How to run anything in this set

Every module in this set is a one-state spec. There's a `VARIABLE probe` that
never changes and an invariant that pins the answers you're supposed to
produce. That means one command shape covers the whole chapter, and it's this
one:

```bash
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex1TruckLoad.tla
```

Run it from your chapter directory. The harness lives in the puzzles repo, so
it's named by its full path. Your module is a starter you're editing, so it's
named relative to where you're standing.

The `.cfg` beside each starter is picked up for you. You never name it.

## Reading a verdict

The harness prints one token and exits with TLC's own status. Four tokens show
up in this set.

- `OK` (0): TLC checked the invariant and found no state that breaks it.
- `SAFETY_VIOLATION` (12): TLC checked it and found one.
- `PARSE_ERROR` (150): the module didn't compile, so nothing ran.
- `SPEC_EVAL_FAILURE` (75): the run fell over before TLC could check anything.

The last one is worth sitting with, because it's the token this chapter
produces most often and the one most people misread. It doesn't mean your
answer is wrong. It means TLC hit an error while working out the initial
state, so nothing at all is known about whether your invariant holds. Three of
the five exercises below can land on it.

## The log

Fill in a line of `LOG.md` per exercise. Exercises 4 and 5 are
predict-then-check, and for those the line has to be written **before** you
run TLC. Put it in `LOG.md` or as a comment in the spec, whichever you prefer.
A prediction you write after the run isn't a prediction.

## Exercise 1

A truck loader works off a set of crate weights and an axle limit. It loads
the heaviest crate that's left, then the next heaviest, and so on. It stops as
soon as the next crate won't fit in the room remaining. Everything from that
point on stays on the dock.

Write two operators.

1. `Loaded(crates, room)`: how many crates get on the truck.
2. `Dockside(crates, room)`: the set of crates left behind.

Both recurse on the set, and both need a `RECURSIVE` line of their own. Both
take two arguments, so the declaration is `Op(_, _)`.

The interesting part is picking the crate. `CHOOSE` is how you peel one
element off a set, and the predicate you give it decides which one. Write a
predicate that names exactly one crate.

- Title: `Loading the truck`
- Format: `write-from-prompt`
- Task: `Write Loaded and Dockside so that LoadIsRight holds.`
- Time budget: `15 min`
- Uses: `RECURSIVE, a two-argument recursive declaration, recursion on a set, CHOOSE with a unique selection predicate`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant LoadIsRight`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex1TruckLoad.tla`

The starter reports `PARSE_ERROR` until you define `Loaded`. That's your first
checkpoint, and it names the operator it can't find.

For the fail run, change both selection predicates to `TRUE` and run it again.
That compiles and it runs. Every crate satisfies `TRUE`, so the predicate
names no crate in particular, and TLC hands back the lowest value. The truck
now loads lightest first, which is a different loading rule and a red one.
Change it back afterwards.

That's the whole point of the exercise. An under-determined `CHOOSE` doesn't
fail. It answers, and it answers the same way every time, and the answer is a
fact about TLC rather than about your spec.

## Exercise 2

A pressure panel carries four gauges, `{12, 28, 41, 55}`. The panel software
wants a few generic tools for working over a set of readings rather than one
purpose-built operator per question.

Fill in the six stubs in the starter.

Three of them take another operator as an argument.

1. `Mapped(Op(_), set)`: apply `Op` to every element.
2. `Kept(Test(_), set)`: the elements `Test` says yes to.
3. `Chained(F(_), G(_), x)`: apply `G` first, then `F`.

Three of them are call sites. Build the operator argument on the spot with
`LAMBDA` rather than naming it somewhere else first.

4. `Trimmed`: every gauge with 12 taken off it.
5. `OverLine`: the gauges reading 40 or more.
6. `Rescaled`: gauge 28, with 12 taken off, then halved.

The parameter lists are already written for you. Read them before you start.
The `(_)` after a parameter name is what makes it an operator rather than a
value.

- Title: `The gauge panel`
- Format: `complete-the-skeleton`
- Task: `Replace all six stubs so PanelIsRight holds.`
- Time budget: `15 min`
- Uses: `higher-order operator parameters, LAMBDA at a call site, set map and set filter`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant PanelIsRight`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex2GaugePanel.tla`

Every stub returns a placeholder, so the module goes red before you touch it.
Run it first and watch it fail.

For the fail run, swap `Chained` to apply its arguments the other way round,
as `G(F(x))`. Both versions typecheck and both run. Only the arithmetic tells
them apart.

Once it's green, try the thing the chapter warns you about. Put this line
above `Mapped` and run again:

```
RECURSIVE Mapped(_(_), _)
```

You get `PARSE_ERROR`, and the message is worth reading. SANY rejects the
declaration and never reaches the definition. `RECURSIVE` takes bare `_`
placeholders only, so the moment it meets the `(` inside `_(_)` it stops and
says it wanted a comma or a closing bracket. Take the line out when you're
done.

## Exercise 3

A settling tank starts at 480 litres. Every hour it loses a fifth of what's in
it to settling, rounded down, and then a further 40 litres are drawn off. A
tank can't hold less than nothing, so the draw stops at empty.

Write three definitions.

1. `x \ominus y`: subtraction with a floor at zero.
2. `Level[n \in 0..6]`: the level after `n` hours, written recursively.
3. `Drop[n \in 1..6]`: how far the level fell during hour `n`.

`\ominus` is a binary operator. You can't invent a name for one, so you pick
from the fixed set of symbols TLA+ reserves for the job. Use it inside `Level`
and inside `Drop`, and notice what it does to how they read.

`Level` and `Drop` are both functions, written in the bracket form. `Level`
calls itself. No `RECURSIVE` declaration belongs anywhere in this module, and
working out why is half the exercise.

- Title: `The settling tank`
- Format: `write-from-prompt`
- Task: `Write the binary operator and the two functions so TankIsRight holds.`
- Time budget: `15 min`
- Uses: `custom binary operator, bracket function definition, recursive function definition, DOMAIN`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant TankIsRight`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex3SettlingTank.tla`

The starter reports `PARSE_ERROR` until you define `\ominus`. That's your
first checkpoint.

For the fail run, drop the floor and make `\ominus` plain subtraction. The
tank drains past empty in the last hour and reports a negative level.

The hour that catches it is hour 6, and it's the only hour that does. Every
other hour has more than 40 litres to give. That's usually how a missing floor
behaves: it's invisible until the one case at the end.

## Exercise 4

`starters/Ex4LiftBands.tla` models a freight lift. `Band(load)` sorts a load
into a band with a `CASE`, and the invariant lists the answer the controller
is supposed to give for seven loads.

The module ships broken. Read it, then write down two predictions before you
run anything.

1. `Band(1200)` satisfies three of the arms. Which one answers, and why?
2. Which verdict token comes back?

Run it. Then repair the `CASE` and run it again.

Once it's green, do the second half. Swap the first two arms so the 600 test
comes before the 900 test, change nothing else, and run a third time. Predict
that verdict too.

- Title: `The freight lift`
- Format: `predict-then-check`
- Task: `Predict both answers, run the starter, repair the CASE, then reorder the arms.`
- Time budget: `12 min`
- Uses: `CASE, OTHER, first match wins, overlapping conditions`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex4LiftBands.tla`

To see the reason in words, keep the log and read it.

```bash
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex4LiftBands.tla --log /tmp/ex4.log
grep -n Error /tmp/ex4.log
```

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`, once the `CASE` has an `OTHER` arm.
  - Fail run: `SPEC_EVAL_FAILURE` on the starter as it ships.

The log line is `Attempted to evaluate a CASE with no conditions true`. A load
of 80 matches no arm, and there's no `OTHER` to catch it. A `CASE` without one
is a partial function, and TLC walks off the end of it.

Most people predict `SAFETY_VIOLATION` here. It isn't one. `Band(80)` never
returned a wrong answer, because `Band(80)` never returned. Nothing was
checked, so nothing is known about the other six rows either.

The reordered run comes back `SAFETY_VIOLATION`. Both arms are still there and
every load still matches something, so the module runs. It just answers
differently. A load of 1200 satisfies `load >= 600` and `load >= 900` both,
and the first arm written wins, so an overloaded lift now comes back `"warn"`.

The arms of a `CASE` aren't a set of independent rules. They're a list, and
reordering the list is editing the behaviour.

## Exercise 5

`starters/Ex5TapeFolds.tla` counts how many times a strip of tape can be
folded in half before it's under 3 units long. Folding halves the length, and
the halving rounds down.

The module ships broken, and then it breaks a second time after you fix it.
Predict each one before you meet it.

1. Read `Folds`. It's four lines and it looks right. Which token comes back?
2. Fix that, get an `OK`, then change the base case from `len < 3` to
   `len < 0`. One character. Which token comes back now, and how long does the
   run take?

Write both predictions down first.

- Title: `Folding the tape`
- Format: `predict-then-check`
- Task: `Predict the first verdict, repair the module, then break the base case and predict again.`
- Time budget: `10 min`
- Uses: `RECURSIVE, the declaration rule, recursion with no termination check`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex5TapeFolds.tla`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`, once `RECURSIVE Folds(_)` sits above the definition.
  - Fail run: `SPEC_EVAL_FAILURE` on the runaway base case.

The first token is `PARSE_ERROR`, and the message is `Unknown operator:
Folds`. An operator can't mention its own name until it's been declared. The
repair goes above the definition, not inside it, and that's the only place it
can go.

The second token is `SPEC_EVAL_FAILURE` again, and the log says
`Java StackOverflowError`. Halving 100 walks down through 50, 25, 12, 6, 3, 1,
0, and then it stops moving, because `0 \div 2` is 0 and `0 < 0` is false. The
base case is never reached.

Two things are worth taking from that. Nothing in TLA+ checks that a recursion
ends, so a base case you can't reach is a bug your tools will let you write.
And it lands in well under a second, which is a mercy. The stack runs out fast
and TLC reports it as an evaluation failure like any other.

## One thing about the scaffolding

Every module here carries a `VARIABLE probe` that never changes, and every
invariant opens with `/\ probe = 0`. That line is load bearing.

Without it the invariant is a constant. TLC folds it away before the run
starts, and a wrong answer comes back as `CONFIG_ERROR` with the message "The
invariant of X is equal to FALSE". That's a true statement and a confusing
one, because the token means TLC never ran your model. Mentioning the variable
makes the invariant a state check, and a wrong answer becomes a plain
`SAFETY_VIOLATION` instead.

## Answers

`references/` in the puzzles repo holds a worked answer per exercise, plus a
seeded-wrong copy for the fail runs and a copy of each second-half experiment.
It isn't delivered into a practice tree, on purpose. Read it once your own
answer runs, not before.
