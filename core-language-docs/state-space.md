# The model configuration

A `.tla` file says what the system is. The `.cfg` beside it says which finite
model of that system TLC should run, and which claims to check while it runs.
This family is that file, plus the two module-side declarations it binds.

What pays for it is that you get to run anything at all. A spec with an
unbound `CONSTANT` has no model, and a spec whose state space is infinite has
no answer. The configuration is where both get fixed.

What it costs is the thing this page spends most of its words on. Of the
sixteen constructs below, two state a property and the other fourteen set up
the run. So a clean run is a claim about the model you configured, and four of
these keywords quietly change which model that is: `SYMMETRY`, `CONSTRAINT`,
`ACTION_CONSTRAINT` and `VIEW`.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-22.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| `INVARIANT` | `INVARIANT TypeOK`, pointing at `TypeOK == /\ var \in Set` | names a state predicate TLC checks at every reachable state | 713 declarations across 337 configs |
| `PROPERTY` | `PROPERTY Safety`, alongside but distinct from `INVARIANT` | names a temporal or action formula TLC checks over behaviors | 226 declarations, and 220 of 337 configs declare none |
| `SPECIFICATION` | `SPECIFICATION Spec` | names the behavior formula, which is the system TLC explores | 253 lines, 178 of them naming `Spec` |
| `INIT` and `NEXT` | `INIT Init` with `NEXT Next` | the same thing in two pieces, for a spec with no `Spec` definition | 53 configs, with no overlap with `SPECIFICATION` |
| `CONSTANT` | `CONSTANT S`, or `CONSTANT S, Length`, or `CONSTANT N <- Def` | binds a declared parameter to a literal, or points it at a definition | not counted |
| `ASSUME` | `ASSUME S # {}`, in the module rather than the cfg | a constant-level claim TLC checks once, before any state exists | not counted |
| model value | `CONSTANT Unclaimed = Unclaimed` in the cfg, a bare word with no quotes and no digits | an opaque value, equal to itself and unequal to everything else | not counted |
| set of model values | `CONSTANT Runners = {r1, r2, r3}`, bare words again, one per element | a set of them, and the thing a symmetry set is built from | not counted |
| `SYMMETRY` | `Perms == Permutations(Runners)` in the module, then `SYMMETRY Perms` in the cfg | keeps one state per permutation orbit, and asserts nothing | 49 configs |
| `CONSTRAINT` | `CONSTRAINT ClockBound`, over a state predicate | stops TLC expanding a state, and asserts nothing | 49 configs |
| `ACTION_CONSTRAINT` | `ACTION_CONSTRAINT TickWithin`, over a predicate that may prime | the same cut on steps rather than on states, and asserts nothing | 5 configs |
| `CHECK_DEADLOCK` | `CHECK_DEADLOCK FALSE` | stops TLC reporting a reachable state that has no successor | 82 configs, 79 of them setting it `FALSE` |
| `VIEW` | `VIEW LampOnly`, over a tuple of variables | changes which states TLC fingerprints, and asserts nothing | 25 configs, and all 15 resolvable targets are tuples |
| `ALIAS` | `ALIAS Board`, over a record built from the variables | rewrites the state shown in an error trace, and asserts nothing | 23 configs, and all 10 resolvable targets are records |
| `POSTCONDITION` | `POSTCONDITION Op` | runs an operator once the model finishes, reporting rather than checking | 5 configs |
| `TypeOK` | `TypeOK == /\ var \in Set`, then `INVARIANT TypeOK` | the conventional name for the invariant saying what each variable holds | 117 of 713 invariant declarations, and 164 begin with `Type` |

Twelve of the sixteen rows carry a figure, which is the best the fourth column
does on any page here. All twelve come from a survey of 666 modules and 337
configuration files drawn from 16 public repositories, read on 2026-09-05. The
four reading "not counted" are the four the survey had no pass for, and that
is not the same as the construct being rare. `CONSTANT` in particular is in
almost every config in that corpus, and nobody counted it.

## Only two of these keywords state a property

This is the column worth reading before anything else on the page. The survey
above went through the configuration surface asking one question of each
keyword, and the answers are lopsided.

| mechanism | what it does | states a property |
|---|---|---|
| `INVARIANT` and `PROPERTY` | names a formula to check | yes, and they're the only way |
| `SPECIFICATION` | names the behavior formula | it is the system model |
| `VIEW` | changes which states TLC fingerprints | no |
| `ALIAS` | rewrites the state shown in a trace | no |
| `SYMMETRY` | declares a permutation set | no |
| `CONSTRAINT` | bounds the state space | no |
| `POSTCONDITION` | runs an operator after the model | reports, doesn't check |

The counts beside those rows are `VIEW` 25 configs, `ALIAS` 23, `SYMMETRY` 49,
`CONSTRAINT` 49, `CHECK_DEADLOCK` 82, `ACTION_CONSTRAINT` 5 and
`POSTCONDITION` 5. So the no-column is where most of the configuration surface
lives. Three of its four plain-no rows change the set of states TLC looks at,
and `ALIAS` is the one that doesn't.

Two consequences follow and the rest of this page is mostly them. A `.cfg`
with no `INVARIANT` and no `PROPERTY` asserts nothing at all, however many
other lines it carries, and 220 of the 337 configs in that corpus declare no
`PROPERTY`. And a run that exits 0 is a claim about whichever model the other
keywords left behind.

## `VIEW` can stop TLC before it reaches the violation

A view is the state function TLC fingerprints to decide whether it has seen a
state before. The default is the tuple of every declared variable. Name
another one and two states that differ outside it become one state, which is
how the keyword saves memory.

`Gauge` flips a lamp and counts how long it has been doing it:

```tla
---- MODULE Gauge ----
EXTENDS Integers
VARIABLES lamp, ticks
vars == <<lamp, ticks>>

Init == lamp = 0 /\ ticks = 0
Flip == lamp' = 1 - lamp /\ ticks' = ticks + 1
Next == Flip
Spec == Init /\ [][Next]_vars

Budget == ticks <= 5
LampOnly == <<lamp>>
NotThree == ticks # 3
=======================
```

With `CONSTRAINT Budget` and nothing else, that's 6 distinct states, one per
value of the counter. Add `VIEW LampOnly` and it's 2, because every state is
either lamp-on or lamp-off and the counter is no longer part of the identity.

Now put the same invariant on both runs. `CONSTRAINT Budget` plus
`INVARIANT NotThree` exits 12 at 4 distinct states:

```
Error: Invariant NotThree is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ ticks = 0
/\ lamp = 0
State 2: <Flip line 7, col 9 to line 7, col 46 of module Gauge>
/\ ticks = 1
/\ lamp = 1
State 3: <Flip line 7, col 9 to line 7, col 46 of module Gauge>
/\ ticks = 2
/\ lamp = 0
State 4: <Flip line 7, col 9 to line 7, col 46 of module Gauge>
/\ ticks = 3
/\ lamp = 1
```

Add `VIEW LampOnly` to that same config and it exits 0:

```
Model checking completed. No error has been found.
3 states generated, 2 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 2.
```

Same spec, same invariant, same bound, and the violation is gone. The state at
`ticks = 2` has the same fingerprint as the initial state, so TLC treats it as
already seen and never asks what comes after it. The violating state is one
step past the point where the search stopped.

The book is explicit about this. Quoting §14.3.3, p. 244 of *Specifying
Systems* through the survey: with a view other than the default one "TLC may
stop before it has found all reachable states" and "it may incorrectly check
the `ImpliedTemporal` property". The 2-against-6 count is that first sentence
happening.

So read the state count on any run carrying a `VIEW`. It's the only signal
there is, since the exit code is the same 0 you'd get from a real pass. All 15
resolvable `VIEW` targets in the corpus are tuples of variables, usually the
full state minus one bookkeeping variable, and none is a record.

One thing worth separating out. There's also a `-view` flag on the command
line, which applies the config's `VIEW` when printing traces. That's a
different thing from the keyword, and it doesn't touch the search.

## `ALIAS` dresses a trace and asserts nothing

`ALIAS` runs when TLC prints an error trace, and it prints a record in place
of the state. It arrived in TLC 1.8.0. `Marquee` is `Gauge` with a record
added:

```tla
Short == ticks <= 2
Board == [light |-> lamp, elapsed |-> ticks, warm |-> ticks > 0]
```

With `INVARIANT Short` and `ALIAS Board`, the run exits 12 and the trace reads
in the record's vocabulary rather than the module's:

```
Error: Invariant Short is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ light = 0
/\ elapsed = 0
/\ warm = FALSE
State 2: <Flip line 7, col 9 to line 7, col 46 of module Marquee>
/\ light = 1
/\ elapsed = 1
/\ warm = TRUE
```

`lamp` and `ticks` are nowhere in that output, and `warm` is in it although
it's no part of the state. That's the whole feature, and it's useful. A trace
over a derived quantity reads better than a trace over the variables it came
from.

The trap is reaching for it by accident. Build a record out of the variables,
hand it to `INVARIANT` instead, and TLC refuses at exit 75 on the initial
state:

```
Error: TLC expected a boolean value, but did not find one. line 15, col 10 to line 15, col 64 of module Marquee
While working on the initial state:
/\ ticks = 0
/\ lamp = 0
```

That one's a cheap mistake to catch, because the run stops. The survey found
the shape is not attested at all: 176 definitions in the corpus have a record
body with two or more `|->` fields, 10 are wired to `ALIAS`, 0 to `VIEW`, and
0 are declared as an `INVARIANT` or a `PROPERTY`. So building a record from
the variables and stating a property over it doesn't appear in 666 modules.
The record-building end of that finding is on the
[functions and records](functions-records.md) page.

## `SYMMETRY` with a liveness property is unsound, and TLC says so

A set of model values is interchangeable by construction, so a spec that only
ever compares its members for equality can't tell one permutation of them from
another. `SYMMETRY` tells TLC that, and TLC keeps one state per orbit.

`Livery` loads three cars:

```tla
---- MODULE Livery ----
EXTENDS TLC
CONSTANT Cars
VARIABLE loaded

Init == loaded = {}
Load == \E c \in Cars \ loaded : loaded' = loaded \cup {c}
Done == loaded = Cars /\ UNCHANGED loaded
Next == Load \/ Done
Spec == Init /\ [][Next]_<<loaded>>
FairSpec == Spec /\ WF_<<loaded>>(Load)

Perms == Permutations(Cars)

Fills == <>(loaded = Cars)
Grows == [][loaded \subseteq loaded']_<<loaded>>
Held == [](loaded \subseteq Cars)
=======================
```

With `CONSTANT Cars = {c1, c2, c3}` the reachable set is the powerset of the
three, 8 distinct states. Add `SYMMETRY Perms` and it's 4, one per cardinality,
because `{c1}` and `{c2}` are the same state once the labels stop mattering.

Now the question this page was filed to settle. The survey left it open, in
those words: 10 configs declare both `SYMMETRY` and a `PROPERTY`, and it
"neither calls it a defect nor calls it fine". On this build TLC answers it
itself. `SPECIFICATION FairSpec` with `SYMMETRY Perms` and `PROPERTY Fills`
exits 0 over 4 distinct states and prints this first:

```
Warning: Declaring symmetry during liveness checking is dangerous. It might cause TLC to miss violations of the stated liveness properties. Please check liveness without symmetry defined.
(Use the -nowarning option to disable this warning.)
```

So it's a defect, and the tool will tell you. Two things about that warning
matter more than its existence.

It goes to stdout and the exit code stays 0. Anything deciding a verdict from
the exit code alone sees a clean run, which I think is why this combination
survives in a corpus at all. The soundness problem has no failure channel.

And it's about liveness specifically, not about `PROPERTY`. I ran the other
two shapes a `PROPERTY` line can carry, under the same symmetry, and neither
draws a warning. `PROPERTY Grows`, an action formula, exits 0 at 4 distinct
states silently, and it's genuinely being checked rather than skipped: the
false twin `[][loaded' \subseteq loaded]_<<loaded>>` exits 13 under the same
symmetry with the counterexample printed. `PROPERTY Held`, a state predicate
under a box, also exits 0 silently, and TLC lifts that one to the invariant
channel where symmetry is sound.

So the reading I'd take is that the three `PROPERTY` shapes split, and only the
liveness one is in trouble. This project's refinement harness refuses both
`SYMMETRY` and `VIEW` statically on any temporal check, citing *Specifying
Systems* p. 244 and p. 246 for the claim that both may "miss errors, report an
error that doesn't exist, or report a real error with an incorrect
counterexample". A refinement claim is a liveness-shaped temporal property, so
that refusal sits on the warned side of the split.

What's still open, and I couldn't close it here, is how the corpus's 10 configs
divide. Classifying each one's property as liveness, action or lifted box would
say whether the published practice is in trouble or merely adjacent to it.

This project's own chapter 9 cheat sheet had the answer the whole time, in a
line about what liveness checking costs: TLC "can't use symmetry sets, can't
say which property failed, and produces longer error traces". So the
measurement above mostly confirms a thing already written down one directory
over, which is its own small lesson about where to look first.

## A `CONSTRAINT` checks the state it refuses to expand, and hides the one past it

A state constraint bounds the search. TLC generates every successor as usual,
checks each one, and expands only the ones inside the bound. `Tollgate` counts
upward forever, with the same cap written in both places it can go:

```tla
---- MODULE Tollgate ----
EXTENDS Integers
CONSTANT Cap
VARIABLE paid

Init == paid = 0
Pay == paid' = paid + 1
Next == Pay
Spec == Init /\ [][Next]_<<paid>>

Inside == paid <= Cap
Bounded == Next /\ paid' <= Cap
BoundedSpec == Init /\ [][Bounded]_<<paid>>

NotSeven == paid # 7
=========================
```

At `Cap = 5` both routes find 6 distinct states, and they report differently.
`SPECIFICATION Spec` with `CONSTRAINT Inside` exits 0. `SPECIFICATION
BoundedSpec`, where the bound is a conjunct of the next-state action, exits 11:

```
Error: Deadlock reached.
Error: The behavior up to this point is:
State 1: <Initial predicate>
paid = 0
...
State 6: <Bounded line 13, col 12 to line 13, col 31 of module Tollgate>
paid = 5
```

That's the practical difference. The spec-side bound removes the step, so the
state at the cap is a genuine dead end and the deadlock check says so. The
constraint leaves `Pay` enabled there and drops the successor afterwards, so
nothing looks stuck. One route tells you the cap created a dead end and the
other hides it.

Checking and expanding come apart under a constraint, and it's easy to get
this backwards. Declaring the constraint as an invariant too, at the same cap,
exits 12:

```
Error: Invariant Inside is violated.
...
State 7: <Pay line 7, col 8 to line 7, col 23 of module Tollgate>
paid = 6
```

`paid = 6` is outside the bound and TLC checked it anyway. The distinct count
stays at 6, so the state was checked and then not counted as found. A
constraint stops expansion, not checking.

Which means the hiding starts one step further out than you'd guess. With
`CONSTRAINT Inside` at `Cap = 5` and `INVARIANT NotSeven`, the run is clean at
6 distinct states: `paid = 6` is generated and passes, and `paid = 7` is never
generated because its only predecessor was dropped. Raise the cap by one and
the same invariant on the same spec exits 12 at 7 distinct states, with
`paid = 7` as the last line of the trace.

So a bound buys termination and charges coverage, and the charge is invisible.
If you want to know what a cap cost, the thing to do is run it at two caps and
compare, which is what those two configs are.

## An `ACTION_CONSTRAINT` reads the step

A state constraint reads one state. An action constraint reads the pair, so it
can say things about a step that no state predicate can express. `Wicket`
moves forward by one or two:

```tla
---- MODULE Wicket ----
EXTENDS Integers
CONSTANT Lim
VARIABLE pos

Init == pos = 0
Step == pos' \in {pos + 1, pos + 2}
Next == Step
Spec == Init /\ [][Next]_<<pos>>

Inside == pos <= Lim
EvenStride == pos' - pos = 2
=======================
```

`CONSTRAINT Inside` at `Lim = 6` reaches every position up to the bound, 7
distinct states from 15 generated. Adding `ACTION_CONSTRAINT EvenStride` keeps
only the steps of two, which leaves 4 distinct states from 9 generated. Both
runs exit 0.

`pos' - pos = 2` is the point. It mentions two states, so there's no state
predicate that says it, and a `CONSTRAINT` line can't carry it. Where a step
predicate is a function of the successor alone, the two keywords do the same
thing and give the same numbers.

The corpus barely uses it: 5 configs out of 337, against 49 for `CONSTRAINT`.
My hunch is that most bounds are naturally about a state, and the ones that
aren't get written into the next-state action instead.

## A negative number is not a value a `.cfg` can write

This one bites anybody bounding a counter below zero, and the error message
names the wrong thing. `Plumbline` wants a floor:

```tla
---- MODULE Plumbline ----
EXTENDS Integers
CONSTANT Floor
VARIABLE depth

NegTwo == -2

Init == depth = 0
Sink == depth > Floor /\ depth' = depth - 1
Rest == depth = Floor /\ UNCHANGED depth
Next == Sink \/ Rest
Spec == Init /\ [][Next]_<<depth>>

AboveFloor == depth >= Floor
==========================
```

`CONSTANT Floor = -2` in the cfg exits 255:

```
Error: TLC threw an unexpected exception.
This was probably caused by an error in the spec or model.
See the User Output or TLC Console for clues to what happened.
The exception was a tlc2.tool.ConfigFileException
: TLC found an error in the configuration file at line 5
It was expecting = or <-, but did not find it.
```

Nothing is wrong with the module and nothing was parsed from it. The failure
is in the config grammar, which is why the usual reading of a parse error
doesn't apply here. Writing the subtraction out as `CONSTANT Floor = 0 - 2`
gets the same exception, because a cfg assigns a literal and never an
expression.

The line number is worth distrusting. The bad assignment is on line 4 of that
file and the message says line 5. Move it to the last line of the cfg and the
message moves with the next token rather than with the mistake. I read that as
the parser taking `-2` for the start of another assignment and then looking
for the operator that should follow it, but I haven't checked the parser and
would treat that as a guess.

The fix is in the message. `<-` points a constant at a definition instead of
at a literal, and a definition can hold anything:

```
CONSTANT Floor <- NegTwo
```

That runs clean at 3 distinct states, `depth` going 0, -1, -2. It's also why
the Toolbox lets you type an expression where the `.cfg` won't: the Toolbox
writes a generated module to hold it, and a hand-written cfg has nowhere to
put one.

## A model value equals itself and nothing else

A model value is a bare word on the right of `=` in the cfg, with no quotes
and no digits. It's an opaque value whose only property is being unequal to
everything that isn't it. That's what makes a set of them symmetric, and it's
what makes the comparison below silent.

```tla
---- MODULE Placard ----
EXTENDS Integers
CONSTANTS Vacant, Taken
VARIABLE slot

Init == slot = Vacant
Claim == slot = Vacant /\ slot' = Taken
Held == slot = Taken /\ UNCHANGED slot
Next == Claim \/ Held
Spec == Init /\ [][Next]_<<slot>>

Opaque == slot # "Taken"
Honest == slot # Taken
Ranked == Vacant < Taken
========================
```

With `CONSTANT Vacant = Vacant` and `CONSTANT Taken = Taken`, the two claims
that look alike don't behave alike. `INVARIANT Honest` exits 12 on the second
state, as you'd want. `INVARIANT Opaque` exits 0 over the same 2 states, and
it can't ever do anything else. The string `"Taken"` is a different value from
the model value `Taken`, the comparison is FALSE rather than an error, and
nothing in the output mentions it.

So an invariant written with quotes around a model value's name is a claim that
passes forever. There's no exit code for that and no warning. If a quoted name
appears anywhere near a `CONSTANT X = X` line, I'd check it by hand.

Equality is where the opacity stops. An order comparison on a model value
exits 75 and says so plainly:

```
Error: The first argument of < should be an integer, but instead it is:
Vacant
```

Which is the useful half of the design. Equality on a model value is total and
every other operator on one is a runtime error, so a spec that does arithmetic
on a value you meant as a label stops instead of guessing.

## An `ASSUME` stops guarding once somebody instantiates the module

`ASSUME` is a constant-level claim, checked once before TLC computes an
initial state. In the root module it works exactly as advertised. `Warrant`
assumes it has at least one seat:

```tla
---- MODULE Warrant ----
EXTENDS Integers
CONSTANT Seats
ASSUME Seats \in Nat /\ Seats > 0
...
```

`CONSTANT Seats = 3` runs clean at 4 distinct states and never mentions the
assumption. `CONSTANT Seats = 0` exits 10 before any state exists:

```
Error: Assumption line 4, col 8 to line 4, col 33 of module Warrant is false.
```

Reached through `INSTANCE`, it does nothing. `Charter` is a library that
guards its own two parameters:

```tla
---- MODULE Charter ----
EXTENDS Integers
CONSTANTS Lo, Hi
ASSUME Lo <= Hi
Width == Hi - Lo
========================
```

and `Roundhouse` instantiates it with the bounds reversed:

```tla
Inverted == INSTANCE Charter WITH Lo <- 9, Hi <- 1
```

That run exits 0 over 3 distinct states, and prints nothing at all about the
assumption it breaks. The assumption really is violated, which the module can
be made to say by asking about the library's own arithmetic: `Sane ==
Inverted!Width >= 0` is false, since the width is -8.

So a library that guards its constants with `ASSUME` guards nothing once
anybody imports it. I think that's the most expensive thing on this page,
because the guard reads like a contract and the import silently drops it. If
a module is meant to be instantiated, the constraint belongs somewhere TLC
checks on the instantiating side, which in practice means an invariant over
the substituted expressions. This project measured both halves of it on this
build and doesn't know whether it's TLA+ semantics or a TLC behavior, so treat
it as a fact about the toolchain until somebody sources it.

## `CHECK_DEADLOCK FALSE` turns off more than the dead end you meant

TLC reports a reachable state with no successor as a deadlock. Often that
state is the system finishing, and the usual move is to turn the check off.
`Siding` empties a yard:

```tla
---- MODULE Siding ----
EXTENDS Integers
VARIABLE wagons

Init == wagons = 3
Shunt == wagons > 0 /\ wagons' = wagons - 1
Next == Shunt
Spec == Init /\ [][Next]_<<wagons>>

Parked == wagons = 0 /\ UNCHANGED wagons
QuietNext == Shunt \/ Parked
QuietSpec == Init /\ [][QuietNext]_<<wagons>>

Emptied == wagons >= 0
=======================
```

Three routes, one state count, three exit codes. `SPECIFICATION Spec` with the
check at its default exits 11 at 4 distinct states, naming `wagons = 0` as the
dead end. Adding `CHECK_DEADLOCK FALSE` exits 0 over the same 4 states.
`SPECIFICATION QuietSpec`, where the finish is written in as a step that
changes nothing, also exits 0 over the same 4 states.

The two zeroes are not the same answer. `CHECK_DEADLOCK FALSE` switches the
check off for the whole run, so it accepts every other dead end in the spec
along with the one you meant. The stutter step accepts this one and leaves the
check live for the rest. That matters most on a spec with processes in it,
where an unintended dead end is the bug you were looking for.

Either way it's normal practice rather than a smell. 79 of the 337
configuration files in the survey set `CHECK_DEADLOCK FALSE`, which is just
under a quarter of them, so a config carrying it isn't cutting a corner.

## What the `INVARIANT` slot accepts, and the two codes that mislead

`INVARIANT` takes a state predicate. `PROPERTY` takes a temporal or action
formula. They look like interchangeable slots and they aren't, and the three
ways of getting this wrong report through three different channels.

`Semaphore` carries one of each:

```tla
---- MODULE Semaphore ----
EXTENDS Integers
VARIABLE aspect

Init == aspect = 2
Up == aspect > 0 /\ aspect' = aspect - 1
Down == aspect < 2 /\ aspect' = aspect + 1
Next == Up \/ Down
Spec == Init /\ [][Next]_<<aspect>>

Valid == aspect \in 0..2
NeverSkips == [][aspect' - aspect \in {-1, 1}]_<<aspect>>
Arithmetic == 2 > 1
Backwards == 1 > 2
=========================
```

`INVARIANT Valid` and `PROPERTY NeverSkips` each exit 0 at 3 distinct states,
which is the pair working as intended. Put the action formula in the other
slot and TLC refuses at exit 76:

```
Error: The invariant NeverSkips is not a state predicate (one with no primes or temporal operators).
```

That's a good message and the code is worth noting, because 76 is otherwise an
invariant that failed to evaluate partway through a behavior, printed with the
behavior attached. Here there's no behavior and no state count. The refusal
happens before the first state, so the same code covers a static rejection and
a runtime failure.

The harder case is an invariant with no variable in it, and it has no failure
channel of its own either. `INVARIANT Arithmetic` exits 0 at 3 distinct states
and warns:

```
Warning: The invariant Arithmetic is a constant-level formula (i.e., it contains no variables, primes, or temporal operators) and evaluates to TRUE. To assert constant-level formulas in your spec, use ASSUME ConstInv.
```

`INVARIANT Backwards`, the same shape and false, exits 151:

```
Error: The invariant of Backwards is equal to FALSE
```

No state, no trace, and 151 is the code this project records for a cfg naming
a symbol the spec doesn't define. Every name in that config resolves, so the
usual reading is wrong for this run. It comes up more easily than it sounds,
because a claim about a library's constants has no variable in it by
construction. `Roundhouse`'s `Sane` above is exactly that shape, and it's why
that case exits 151 rather than 12.

TLC names the fix in its own warning: a claim with no variable in it belongs
in an `ASSUME`, where it's checked once and reports at exit 10 with the line
number. That's the `Warrant` case two sections up. So the three slots line up
by what the formula mentions. No variables goes to `ASSUME`, one state goes to
`INVARIANT`, and a pair of states or a temporal operator goes to `PROPERTY`.

Worth knowing the naming practice too, since a name here is a label in TLC's
failure report. The corpus declares 713 invariants under 229 distinct names,
and `TypeOK` is 117 of them with 164 beginning with `Type`. Lamport's reason
for separate names is at §14.5.3, p. 259: "If you give separate names to the
conjuncts of your invariant and list them separately in the configuration
file's `INVARIANT` statement, TLC will tell you which conjunct is false." A
merged conjunction throws that label away.

## Where this is taught

learntla's constants chapter, which this project's chapter 5 exercise set
follows, covers `CONSTANT`, `ASSUME`, model values, sets of model values and
symmetry sets. That chapter's cheat sheet is where five of the shapes in the
table above come from, and it already carries the negative-literal trap in one
line: "a `.cfg` assigns a literal, never an expression".

The rest is scattered. `Invariant` as a declaration form arrives in chapter 4,
with the invariants material. `PROPERTY` arrives in chapter 9 alongside the
temporal operators, which is also where symmetry and liveness get their one
line in the core chapters. Deadlock checking arrives in chapter 8, with
concurrency, where it's introduced as a thing you turn off from the model
configuration rather than from spec text.

Four of the sixteen constructs above are taught nowhere in that sequence.
`CONSTRAINT`, `ACTION_CONSTRAINT`, `VIEW` and `ALIAS` have no entry in any of
the twelve chapter cheat sheets, which is where I looked, and none of the
twelve mentions any of the four words at all. The reason is that the exercise
sets never reached the model-configuration surface. Symmetry's payoff for
concurrent systems is in learntla's optimization topic, outside the core
chapters, and I'd read that topic as the likely home for all four.
