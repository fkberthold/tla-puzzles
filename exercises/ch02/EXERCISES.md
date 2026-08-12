# Chapter 02 exercises: Operators and Values

Five exercises over the constructs in the chapter 2 cheat sheet. Nothing here
needs PlusCal, structures, or functions. Everything is chapter 2.

Each exercise has a starter under `starters/`. That's the file you edit. Run it
through the harness, which prints one verdict token and exits with TLC's own
status.

```bash
bash harness/verdict.sh exercises/ch02/starters/Ex1Postage.tla
```

The commands below assume you're in a checkout of the puzzles repo. If you're
working in a delivered practice tree instead, run the same script out of the
repo and give it the full path to your file.

Fill in a row of `LOG.md` per exercise. For exercise 3, write the prediction
into the log **before** you run TLC. A prediction you write after the run is
not a prediction.

## Reading a verdict

Three tokens show up in this set.

- `OK`: TLC checked the invariant and found no state that breaks it.
- `SAFETY_VIOLATION`: TLC checked it and found one.
- `PARSE_ERROR`: the module didn't compile, so nothing ran.

A fourth shows up in exercise 3, and finding out which one is the exercise.

## Exercise 1

A courier prices a parcel by weight. The handling fee is 120 for every parcel.
On top of that, a parcel over 100 grams pays 90 more, and a parcel over 500
grams pays 250 more instead. The two surcharges don't stack.

Write `Postage(grams)`. Use `LET` to name the handling fee once, and
`IF-THEN-ELSE` for the bands. The starter has the scaffolding and an empty
answer block.

- Title: `Parcel postage bands`
- Format: `write-from-prompt`
- Task: `Write Postage(grams) so that PostageIsRight holds.`
- Time budget: `10 min`
- Uses: `operators defined with ==, IF-THEN-ELSE, LET-IN, EXTENDS Integers`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant PostageIsRight`
- How to run: `bash harness/verdict.sh exercises/ch02/starters/Ex1Postage.tla`

The starter reports `PARSE_ERROR` until you define `Postage`. That's your first
checkpoint, and it names the operator it can't find.

For the fail run, take your working answer and change the first band test from
`<=` to `<`. A parcel of exactly 100 grams then lands in the wrong band and
`PostageIsRight` goes red. Change it back afterwards.

## Exercise 2

A library hold shelf has a collection rule. A patron may collect when the card
is valid and the hold is ready. If the patron owes fines, a staff override is
needed as well. An override on a patron who owes nothing changes nothing.

Fill in `CanCollect` in the starter. Write it in bullet-point notation, one
`/\` per line, and say the fines clause with `=>` rather than with a nested
conditional.

Then fill in `TurnedAwayAtTheDesk(card_ok, hold_ready)`, which is true when the
patron is turned away for a reason that has nothing to do with fines. Write
that one on a single line with `~` and `\/`.

- Title: `The hold shelf rule`
- Format: `complete-the-skeleton`
- Task: `Replace both FALSE stubs so RuleIsRight holds over all ten rows.`
- Time budget: `12 min`
- Uses: `booleans, /\ and \/ and ~, bullet-point notation, implication`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant RuleIsRight`
- How to run: `bash harness/verdict.sh exercises/ch02/starters/Ex2HoldPickup.tla`

The starter returns `FALSE` from both operators, so it goes red before you
touch it. Run it first and watch it fail.

For the fail run, turn your implication around to
`staff_override => owes_fines` and run it again. The rule now says an override
means fines were owed, which is a different rule and a red one.

## Exercise 3

`starters/Ex3SlotStatus.tla` models a vending bank. Slots are named with
strings, stock levels are integers, and `Status` answers with a string. One
line of its invariant compares a string answer against the integer `0`.

Read the module and find that line. Then predict two things, and write both
into your log before you run anything.

1. What does `Status("a2") = 0` evaluate to, `FALSE` or something else?
2. Which verdict token comes back?

Run it. Then repair the line and run it again.

- Title: `What type is that answer`
- Format: `predict-then-check`
- Task: `Predict the verdict, run the starter, then repair the line.`
- Time budget: `10 min`
- Uses: `untyped values, = and # as the only cross-type operators, EXTENDS`
- How to run: `bash harness/verdict.sh exercises/ch02/starters/Ex3SlotStatus.tla`

To see the reason in words, keep the log and read it.

```bash
bash harness/verdict.sh exercises/ch02/starters/Ex3SlotStatus.tla --log /tmp/ex3.log
grep -n Error /tmp/ex3.log
```

The second half of the exercise is `EXTENDS`. Once the module is green, delete
the `EXTENDS Integers` line and run it again. `Restocked` needs `+`, so the
module stops parsing. Most operators in TLA+ arrive through a module, and `=`
and `#` are among the few that don't. Put the line back when you're done.

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SPEC_EVAL_FAILURE`

`SPEC_EVAL_FAILURE` means TLC never got as far as checking anything. It doesn't
say your invariant is false. It says the run fell over while TLC was working
out the initial state, so nothing at all is known about whether the invariant
holds.

Most people predict `SAFETY_VIOLATION` here. The chapter says values of
different types can't be tested for equality and that this throws an error, and
an error is not the same event as a false invariant. TLC stops rather than
answering `FALSE`.

## Exercise 4

A ferry line runs `Coast == <<"quay", "isle", "point", "harbour">>`. A spur
route starts where a main route ends, so `Spur == <<"harbour", "reef">>` shares
the harbour stop.

Write five operators over routes.

1. `FirstStop(route)`: the first stop.
2. `LastStop(route)`: the last stop, whatever the length.
3. `Between(route)`: everything except the first and last stops.
4. `Extend(route, stop)`: the route with one more stop on the end.
5. `Onward(route, spur)`: the two routes end to end, with the shared stop once.

`Between` on a two-stop route has to come back as `<<>>`. That's the case the
1-indexing will catch you on.

- Title: `The ferry route`
- Format: `write-from-prompt`
- Task: `Write the five route operators so RouteIsRight holds.`
- Time budget: `15 min`
- Uses: `sequences, 1-indexing, Head and Tail and Len and Append and SubSeq and \o`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant RouteIsRight`
- How to run: `bash harness/verdict.sh exercises/ch02/starters/Ex4FerryRoute.tla`

For the fail run, start the `Between` slice at index 1 instead of index 2. That
is what 0-indexed habits produce, and it's the single most common way to get
this wrong.

## Exercise 5

A locker bank has three rows of three lockers. A locker is a pair of row number
and column letter. Some are already taken.

The starter gives you `Rows`, `Cols` and `Taken`. Fill in seven definitions.

1. `Slot`: every locker in the bank.
2. `Free`: every locker that isn't taken.
3. `FreeInRow(r)`: the free lockers in one row.
4. `TakenRows`: the rows holding at least one taken locker.
5. `Clash(wanted)`: the lockers in `wanted` that are already taken.
6. `OnlyFreeIn(r)`: one free locker in row `r`.
7. `ColSets`: every set of columns you could pick, the empty one included.

Two of these want a set map, one wants a set filter, and one wants `CHOOSE`.
Work out which before you start typing.

- Title: `The locker bank`
- Format: `complete-the-skeleton`
- Task: `Fill in the seven definitions so BankIsRight holds.`
- Time budget: `15 min`
- Uses: `sets, \in and \notin and \subseteq, difference and union and intersect, a..b, \X, SUBSET, BOOLEAN, Cardinality, map, filter, CHOOSE`
- Expected outcome:
  - Pass run: `OK`
  - Fail run: `SAFETY_VIOLATION, invariant BankIsRight`
- How to run: `bash harness/verdict.sh exercises/ch02/starters/Ex5LockerBank.tla`

Every stub in the starter returns a placeholder, so it goes red before you
touch it. Run it first and watch it fail.

For the fail run, swap the operands of the set difference in `Free`. That
leaves it empty, and the locker counts go red.

## One thing about the scaffolding

Every starter carries a `VARIABLE probe` that never changes, and every
invariant opens with `/\ probe = 0`. That line is load bearing, and it's worth
knowing why before you write drills of your own.

Without it the invariant is a constant. TLC folds it away before the run
starts, and a wrong answer comes back as `CONFIG_ERROR` with the message "The
invariant of X is equal to FALSE". That's a true statement and a confusing one,
because the token means TLC never ran your model. Mentioning the variable makes
the invariant a state check, and a wrong answer becomes a plain
`SAFETY_VIOLATION` instead.

## Answers

`references/` in the puzzles repo holds a worked answer per exercise. Four of
them come with a ready-made broken copy, so you can see the fail run without
breaking your own file. Exercise 3 needs no such copy, since its starter is the
broken one.

`references/` isn't delivered into a practice tree, on purpose. Read it once
your own answer runs, not before.
