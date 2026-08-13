# Exercises: learntla core ch.11, Action Properties

Five exercises. Budget 10 to 15 minutes each once you've read the chapter.

Nothing here needs a construct from past chapter 11. Every subscript in this set
is a single variable name. If you find yourself reaching for
`UNCHANGED <<x, y>>` or a tuple subscript `[A]_<<x, y>>`, back up. Those are
chapter 12, and chapter 11 does not need them.

## Before you start

Work inside this directory, the one holding this file. Your answers go in
`starters/`, next to the `.cfg` that ships with each one. Every exercise ships
its `.cfg`, so you write the `.tla` and leave the config alone. The config also
pins the property names, which is what makes your verdict match the one each
exercise states.

Three exercises ship a `.tla` as well as a `.cfg`. Those files ship
**translated**, which means the `define` block sits in each of them twice: once
inside the PlusCal comment, and once below `\* BEGIN TRANSLATION`. TLC reads
only the translated copy. So when an exercise asks you to change a property,
either change both copies or change the PlusCal copy and run `pcal` again. This
catches people. An edit to the PlusCal copy alone changes nothing at all, and
the run you get back is a run of the text you did not edit.

Fill in a line of `LOG.md` per exercise. Exercises 2 and 3 are
predict-then-check, and there the prediction is the whole point. Write it on
that exercise's line, or as a comment in the spec, **before** you run TLC.

## How to run anything here

Run from this directory. The harness is named by its full path, so it resolves
from wherever you are, and the spec is named relative to here.

```
pcal starters/YourSpec.tla                                             # PlusCal specs only
bash ~/repos/tla-puzzles/harness/verdict.sh starters/YourSpec.tla -c starters/YourSpec.cfg
```

Each exercise's "how to run" line names the commands with the spec name filled
in. They are true as printed.

The one line `verdict.sh` prints is your answer. It comes from TLC's exit
status, not from anything TLC printed, so read that token and ignore the console
noise above it. Four tokens come up in this chapter.

- `OK` means the model check found nothing.
- `SAFETY_VIOLATION` is what a failed `INVARIANT` gives you.
- `LIVENESS_VIOLATION` is what a failed `[][A]_v` gives you. An action property
  goes through TLC's implied-action channel, and that channel reports this token
  whatever the counterexample looks like.
- `PARSE_ERROR` means the module never compiled. Nothing was checked, so nothing
  at all is known about whether your property holds. That is a different thing
  from a property coming out false, and this chapter is where the difference
  starts to bite.

State counts are not part of any expected outcome below. Two correct answers can
explore different numbers of states, and neither is wrong.

## Exercise 1

- Title: `Delivery odometer`
- Format: `write-from-prompt`
- Task: Write `starters/Odometer.tla` from scratch, using
  `starters/Odometer.cfg` unchanged.
  1. `EXTENDS Integers`. Define `MaxLegs == 3` and `LegLength == 2`.
  2. Two variables, `miles` and `legs`, both starting at 0.
  3. In a `define` block, two action properties. `MilesNeverFall` says the
     odometer may hold still and may climb but may never drop.
     `LegsCountUpByOne` is stricter and says that when `legs` moves at all it
     moves by exactly one. Write both as box action formulas, each subscripted
     on its own variable.
  4. One label `Depot` running a `while` over `legs < MaxLegs`. Inside the loop,
     label `Roll` adds `LegLength` to `miles`, and label `Log` adds one to
     `legs`.
  Notice that no step in this spec changes both variables. `Roll` leaves `legs`
  alone and `Log` leaves `miles` alone, so each property meets steps where its
  own variable does not move. Getting the brackets right is what lets those
  steps through.
- Time budget: `15 min`
- Uses: action properties as restrictions on change, `'` as the value at the end
  of a step, `[P]_x` as `P \/ UNCHANGED x`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change `Roll` to subtract `LegLength` instead of adding it, and
    re-run. `LIVENESS_VIOLATION`. Every value `miles` reaches is still a
    perfectly ordinary number, and 0 is where it started. The illegal thing is
    the step.
- How to run: `pcal starters/Odometer.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Odometer.tla -c starters/Odometer.cfg`

## Exercise 2

- Title: `What the brackets buy`
- Format: `predict-then-check`
- Task: Read `starters/StepProbe.tla`. It is complete and runs as it stands. A
  climber goes up a ladder, and three of the four labels in the loop never touch
  `rung` at all. The property is `RungGoesUpByOne == [][rung' = rung + 1]_rung`.
  Make two predictions and write both on the exercise 2 line of `LOG.md` before
  you run anything.
  1. What verdict does the file give as shipped?
  2. Now take the brackets off, so the property reads
     `RungGoesUpByOne == [](rung' = rung + 1)`. What verdict does that give?
  The chapter tells you what the second one means. Predict the token this
  harness reports for it, not the meaning.
  The `define` block sits in this file twice. Change both copies, or change the
  PlusCal copy and run `pcal starters/StepProbe.tla` again.
- Time budget: `10 min`
- Uses: a bare next-state formula against a stutter step, `[P]_x` as the fix,
  `'` as the value at the end of a step
- How to run:
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/StepProbe.tla -c starters/StepProbe.cfg`
  and, after you edit the property,
  `pcal starters/StepProbe.tla` then the same command again

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Fail run: `PARSE_ERROR`

The first one is the easy half. `Grip`, `Release`, and the loop head all leave
`rung` alone, and `[P]_rung` is shorthand for `P \/ UNCHANGED rung`, so those
three steps satisfy the property by the right-hand side. Take the brackets off
and they have nothing to satisfy.

The second one is where most predictions go wrong, and they go wrong in a
believable way. The chapter says a bare next-state formula is trivially false,
because TLA+ can always insert a stutter step. True of the mathematics. So the
natural guess is `LIVENESS_VIOLATION`, a property that was checked and came out
false.

It never gets that far. SANY rejects the module with

```
[] followed by action not of form [A]_v.
```

and the module does not compile, so the verdict is `PARSE_ERROR`. Nothing was
checked. That distinction is worth more than the syntax rule it came from.
`LIVENESS_VIOLATION` tells you your property is false and there is a
counterexample. `PARSE_ERROR` tells you nothing about your property at all.
Reading the second as the first is how people end up believing a check passed
when it never ran.

Two smaller things worth keeping.

The rejection happens at the definition, not at the use. Define a bare
`[](action)` in a module and it fails to compile even when the `.cfg` never
names it.

`[][rung' >= rung]_rung` would also pass here, and it would be a weaker claim.
The brackets already tolerate a step that leaves `rung` alone, so you do not
need to write that tolerance into the action as well. The chapter's own advice
cuts the other way: if it is genuinely fine for the variable to hold still, say
so explicitly rather than leaning on the subscript.

## Exercise 3

- Title: `The jump the invariant cannot see`
- Format: `predict-then-check`
- Task: `starters/Thermostat.tla` is complete and runs as it stands. It carries
  two checks on the same spec. `InRange` is a state predicate and rides under
  `INVARIANT`. `MovesOneDegree` is an action and rides under `PROPERTY`.
  1. Run it once as shipped, to see what a clean run looks like.
  2. Now make the thermostat jump. Change `setpoint := setpoint + 1;` to
     `setpoint := High;` and leave everything else alone.
  3. Before you re-run, predict two things and write both on the exercise 3 line
     of `LOG.md`. Which of the two checks notices the jump? And what is the
     exact verdict token?
  The second prediction is the one that matters. This harness prints one token,
  and the token is enough to tell you which check fired.
  The `define` block sits in this file twice, but this edit is in the algorithm
  body, so one `pcal` run picks it up.
- Time budget: `12 min`
- Uses: action properties restricting how a system changes, against invariants
  restricting what one state may look like
- How to run:
  `pcal starters/Thermostat.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Thermostat.tla -c starters/Thermostat.cfg`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Fail run: `LIVENESS_VIOLATION`

`InRange` never fails. It cannot. `High` is a member of `Low..High`, and so is
every setpoint the broken spec can reach. The jump from 60 to 64 does not pass
through an illegal state, because it does not pass through any state. It is one
step, and both of its endpoints are fine.

That is the chapter's whole point in one run. An invariant is a claim about a
state. It gets to look at 60, and it gets to look at 64, and it never gets to
look at the arrow between them.

The token is the second half of the exercise. `SAFETY_VIOLATION` is what a
failed `INVARIANT` gives you and `LIVENESS_VIOLATION` is what a failed
`[][A]_v` gives you, so one token tells you which of the two checks fired
without reading a line of TLC's output. If you want to watch the other one, put
the spec back and narrow `InRange` to `setpoint \in Low..High - 1` instead. That
run comes out `SAFETY_VIOLATION`.

Do not read `LIVENESS_VIOLATION` as "something about liveness went wrong". The
token names the channel TLC checked the formula through, not the kind of
property you wrote. An action property is a safety property, and it still
reports here.

## Exercise 4

- Title: `Every plate, one property`
- Format: `complete-the-skeleton`
- Task: Fill the one hole in `starters/Incubator.tla`, marked `TODO_1`. The file
  does not parse until you do.
  Two culture plates sit in an incubator and grow on their own clocks. On any
  one step a plate's colony is allowed to do exactly two things. It can stay
  exactly where it is, or it can exactly double. Nothing else is legal, in
  either direction. `ColoniesDoubleOrHold` has to say that for every plate in
  `Plates`. Work the action out from that sentence rather than from a formula,
  and keep in mind that a step where one plate doubles is a step where the other
  plate does not move at all.
  Then there is the shape it has to be written in. The obvious first attempt
  writes the property for one plate, wraps a quantifier round the outside, and
  subscripts that one plate's entry, `\A p \in Plates: [][ ... ]_colony[p]`.
  That module does not compile. TLC checks a top-level box action formula, and
  the fix is that `[]` commutes with `\A`, so the quantifier can move inside the
  box. Moving it inside also puts the subscript back on the whole variable,
  which is the part that actually has to be right.
  **The stub sits in the file twice.** This file ships translated, so
  `ColoniesDoubleOrHold == TODO_1` appears once inside the PlusCal comment and
  once below `\* BEGIN TRANSLATION`, and TLC reads only the translated copy.
  Fill both, or fill the PlusCal copy and run `pcal` again.
- Time budget: `12 min`
- Uses: TLC checking only a top-level `[A]_v`, `[]` commuting with `\A`, a
  quantified action property over a function-valued variable
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change the loop body from `colony[self] := colony[self] * 2;` to
    `colony[self] := colony[self] + 1;` and re-run. `LIVENESS_VIOLATION`. That
    edit is in the algorithm body, so one `pcal` run picks it up. A colony that
    goes from 2 to 3 is still growing, and the property still catches it,
    because the property pins the shape of the step and not its direction. The
    quantifier inside the box is what makes it notice on whichever plate did it.
- How to run: `pcal starters/Incubator.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Incubator.tla -c starters/Incubator.cfg`

## Exercise 5

- Title: `Airlock`
- Format: `write-from-prompt`
- Task: Write `starters/Airlock.tla` from scratch, using `starters/Airlock.cfg`
  unchanged.
  1. Two variables, `outer` and `inner`, both starting at `"shut"`.
  2. In a `define` block, four definitions.
     `NeverBothOpen` is a state predicate saying the two doors are never open at
     the same time.
     `Moves(door, to)` is a helper action saying the door's value at the end of
     the step is `to`. It mentions a primed variable, so it is an action, and it
     can only appear inside an action property.
     `OuterOnlyShuts` and `InnerOnlyShuts` each say that an open door's only
     legal move is to shut. Build both of them out of `Moves`, rather than
     writing the primed expression out twice.
  3. One label `Cycle` running `while (TRUE)` over a four-branch `either`. Open
     the outer door, only when both doors are shut. Shut the outer door, only
     when it is open. Open the inner door, only when both are shut. Shut the
     inner door, only when it is open.
  Look at what the `.cfg` asks for. One `INVARIANT` and two `PROPERTY` lines on
  the same spec. The invariant is the thing that must hold, the safety claim the
  airlock exists to make. The two action properties are optional extras, and
  they pin down something the invariant has no way to say: not which states are
  legal, but which moves are.
- Time budget: `15 min`
- Uses: helper actions factoring primed logic into a named operator and reused
  in more than one action property, action properties as the optional third kind
  of check alongside invariants
- Expected outcome:
  - Pass run: `OK`
  - Fail run: change the branch that shuts the outer door so it sets `"ajar"`
    instead of `"shut"`, and re-run. `LIVENESS_VIOLATION`. `NeverBothOpen` still
    holds, because a door that is ajar is not open. Only `OuterOnlyShuts`
    notices, and it notices because it is the only one of the three looking at
    the move.
- How to run: `pcal starters/Airlock.tla` then
  `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Airlock.tla -c starters/Airlock.cfg`
