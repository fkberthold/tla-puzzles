# Actions and temporal properties

Everything else in TLA+ describes a state. This family is the only way to say
anything about how a state changes, or about what happens later on. It holds
priming, actions, the spec skeleton, the four temporal operators, the two
action formulas and the two fairness operators.

What pays for it is that a system has to be described somehow, and `Init` and
`Next` are the description. What it costs is that this is where the quiet
failures live. A formula here can be well formed, run clean, and assert
nothing at all. Three of the sections below are that failure wearing
different clothes.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-22.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| `VARIABLE` / `VARIABLES` | `VARIABLE hr`, or `VARIABLES counter, pc` | declares the state a behavior moves through | not counted |
| `'` | `x'` is the value of `x` at the end of the step | relates this state to the next one | not counted |
| action | any boolean body holding a primed variable, `hr' = hr + 1` | true of a pair of states rather than of one | 238 of 666 modules define `Next` |
| nondeterministic action | `\E x \in 1..2 : hr' = hr + x`, or `\/ hr' = hr + 1 \/ hr' = hr + 2` | more than one next state satisfies it | 105 of 238 `Next` definitions are a bulleted disjunction, 69 an existential |
| `UNCHANGED` | `UNCHANGED x`, or `UNCHANGED <<x, y, z>>` | `x' = x`, for one variable or for a tuple of them | not counted |
| `vars` | `vars == <<hr, counter>>` | one operator naming the tuple of every variable | 906 of 1,182 subscripts are the bare token `vars` |
| `Init` / `Next` / `Spec` | `Spec == Init /\ [][Next]_vars` | the skeleton every raw-TLA+ spec follows | 178 of 253 `SPECIFICATION` lines name `Spec` |
| `[]` | `[]P` | `P` holds in every state of the behavior | not counted |
| `<>` | `<>P` | `P` holds in at least one state | not counted |
| `<>[]` | `<>[]P` | `P` becomes true and then stays true | not counted |
| `[]<>` | `[]<>P` | `P` is true infinitely often, and may go false between times | not counted |
| `~>` | `P ~> Q` | wherever `P` holds, `Q` holds then or in a later state | not counted |
| `[P]_x` | `[P]_x`, the box action formula | `P \/ UNCHANGED x`, so a stuttering step satisfies it | 1,182 subscript sites across 334 modules |
| `<<A>>_v` | `<<A>>_v`, the angle action formula | `A` holds and `v` changes, the mirror of `[A]_v` | not counted |
| action property | `Name == [][action]_vars`, registered with `PROPERTY` | a rule every step of the behavior has to obey | not counted |
| `ENABLED` | `ENABLED A` | true in a state from which `A` can describe the next step | not counted |
| `WF_v(A)` | `WF_v(A)` | if `A` is eventually always possible, it happens | 456 `WF_` and `SF_` sites, the two counted together |
| `SF_v(A)` | `SF_v(A)` | if `A` is always eventually possible, it happens | 456 `WF_` and `SF_` sites, the two counted together |
| fairness conjunct on `Spec` | `Spec == Init /\ [][Next]_vars /\ Fairness` | where a fairness demand attaches to the system model | 83 of 337 configuration files |
| fairness on a subaction | `Succeed == Trans("start", "done")`, then `SF_status(Succeed)` | reaches one branch instead of covering all of `Next` | not counted |

Eight of the twenty carry a figure, and two of those eight share one, because
the survey counts `WF_` and `SF_` together rather than apart. All of them come
from a survey of 666 modules and 337 configuration files drawn from 16 public
repositories, read on 2026-09-05. That column is fuller here than on the other
pages in this section. The survey's longest section, 110 of its 497 lines, is
about the subscript on a box action, and I'd put the difference down to that.
"Not counted" means the survey has no number for the construct, which isn't
the same as the construct being rare.

## A step rule needs the box, and the three spellings without it fail three ways

`Metronome` counts to three and then holds:

```tla
---- MODULE Metronome ----
EXTENDS Integers
VARIABLE tick
vars == <<tick>>

Init == tick = 0
Advance == tick < 3 /\ tick' = tick + 1
Done == tick = 3 /\ UNCHANGED vars
Next == Advance \/ Done
Spec == Init /\ [][Next]_vars

\* The step rule a reader would state first, with no box around it.
BareAct == tick' = tick + 1

\* The same rule with the box and the subscript.
Boxed == [][tick' = tick + 1]_vars

\* A state predicate, for the contrast with the two above.
Bounded == [](tick <= 3)
=========================
```

`PROPERTY Boxed` is a clean run, exit 0, 4 distinct states. The other three
spellings of the same rule each fail, and no two of them fail alike.

| what you wrote | where it fails | exit |
|---|---|---|
| `PROPERTY BareAct` | at run time, on the configuration | 151 |
| `PROPERTY BoxBare`, with `BoxBare == [](tick' = tick + 1)` | at semantic analysis, in the module | 150 |
| `INVARIANT Boxed` | at run time, on the invariant channel | 76 |

The run-time one is the message to know, because it tells you the fix and
cites the book:

```
Error: The formula BareAct at line 13, col 12 to line 13, col 27 of module
Metronome is an action-level formula (i.e., it contains no temporal
operators). Only temporal-level (or state-level) formulas are allowed under
PROPERTY or PROPERTIES. To check that action BareAct holds in *every* step of
the behavior, define a temporal property: Let A be the formula at line 13,
col 12 to line 13, col 27 of module Metronome; rewrite A as [][A]_v, where v
is a state function (typically the tuple of variables) (compare page 90 of
Specifying Systems at https://lamport.azurewebsites.net/tla/book.html).
```

Note the exit code. 151 usually means your configuration named an operator the
module doesn't define, so don't read this one as a typo in a name. The module
defines `BareAct` and TLC found it.

Reaching for the box without the subscript doesn't work either. That one is a
semantic error in the module, so it fires whether or not any configuration
names it. It also arrives as one line rather than the essay above:

```
line 14, col 12 to line 14, col 31 of module MetronomeBox
[] followed by action not of form [A]_v.
```

Going the other way and declaring the boxed formula as an invariant gets a
third code, 76, and no behavior printed:

```
Error: The invariant Boxed is not a state predicate (one with no primes or
temporal operators).
```

The reason all three exist is stuttering invariance. `[]P` isn't invariant
under stuttering, and TLA admits only formulas that are, which Lamport states
at *Specifying Systems* §8.1, p. 90. `[P]_v` is defined as `P \/ (v' = v)`, so
the subscript is what buys the tolerance. I'd read the second disjunct as
`UNCHANGED v` written out, which is what it is.

## `[]` takes a square bracket and `<>` takes an angle bracket

This is the rule I'd most want on a card, and the cheat sheets don't state it.
An action formula under a temporal operator has to use the bracket that
operator admits, and the two are not interchangeable.

`Chime` strikes forever, since weak fairness keeps it going:

```tla
---- MODULE Chime ----
EXTENDS Integers
VARIABLE strike
vars == <<strike>>

Init == strike = 0
Sound == strike' = (strike + 1) % 2
Next == Sound

\* Weak fairness keeps the bell going, so Sound recurs forever.
Spec == Init /\ [][Next]_vars /\ WF_vars(Sound)

\* The one-shot reading: the bell sounds at some point.
Once == <><<Sound>>_vars

\* The recurrence reading: the bell sounds again and again.
Again == []<><<Sound>>_vars

\* The settling reading: from some point on, every step is a Sound step. Note
\* the square bracket. An angle action here is a semantic error, because the
\* box admits only [A]_v.
Forever == <>[][Sound]_vars
======================
```

`Once` is refused outright, at exit 255:

```
Error: Temporal formulas containing actions must be of forms <>[]A or []<>A.
```

So an action formula reaches a checkable `PROPERTY` only under `[]<>` or
`<>[]`. There is no way to say "this action happens at some point" as a
property. A model that wants the construct needs an action that recurs
forever, and a one-shot eventuality has to be said over a state predicate
instead. `Again` and `Forever` both run clean, exit 0, 2 distinct states.

Now the part the message hides. `A` in `<>[]A` and `[]<>A` is not free. The
bracket is fixed by the operator directly above it. Getting it wrong is a
semantic error in the module rather than a refusal at run time:

| formula | exit | message |
|---|---|---|
| `[]<><<A>>_v` | 0 | checked |
| `<>[][A]_v` | 0 | checked |
| `[]<>[A]_v` | 150 | `<> followed by action not of form <<A>>_v.` |
| `<>[]<<A>>_v` | 150 | `[] followed by action not of form [A]_v.` |

The two failing rows live in `ChimeRecur` and `ChimeHold`, one module each,
because a module carrying either one never gets as far as a model. Read the
rule off the right-hand column: `[]` wants `[A]_v` and `<>` wants `<<A>>_v`.
That lines up with what the two formulas mean. `[A]_v` tolerates a stuttering
step and `<<A>>_v` demands a real one. Pairing each with the operator that
quantifies the other way is, I think, what makes the combination say
something.

## The subscript is the whole state tuple, and a narrower one changes what you said

Published practice is close to unanimous here. Of 1,182 subscript sites across
334 modules, 906 have the bare token `vars` as the subscript, which is 77%.
The survey also resolved each subscript against the module's declared
variables. 405 of the 421 resolvable box sites cover every variable, 96.2%,
and 300 of the 306 resolvable `WF_` and `SF_` sites do, 98.0%.

Lamport gives the reason at *Specifying Systems* §8.4, p. 96: "To avoid having
to think about which variables `A` actually changes, we generally take the
subscript `v` to be the tuple of all variables."

A narrower subscript isn't an error. It's sound whenever `v` covers every
variable the action mentions, which §9.2, p. 123 states for angle brackets. It
does change what the formula says, and that change is easy to miss. Every step
that leaves the subscript unchanged now satisfies the formula, whatever else
moved.

`Escapement` has two variables and two actions, each moving one of them:

```tla
---- MODULE Escapement ----
EXTENDS Integers
VARIABLES hand, bell
vars == <<hand, bell>>

Init == hand = 0 /\ bell = 0

Tick == /\ hand < 2
        /\ hand' = hand + 1
        /\ bell' = bell

Ring == /\ bell < 1
        /\ bell' = bell + 1
        /\ hand' = hand

Settle == hand = 2 /\ bell = 1 /\ UNCHANGED vars
Next == Tick \/ Ring \/ Settle
Spec == Init /\ [][Next]_vars

\* One claim, two subscripts. The body is the same text in both.
Wide == [][bell' = bell]_vars
Narrow == [][bell' = bell]_hand
===========================
```

`PROPERTY Wide` exits 13 on the first `Ring` step:

```
Error: Action property Wide is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ hand = 0
/\ bell = 0
State 2: <Ring line 12, col 9 to line 14, col 23 of module Escapement>
/\ hand = 0
/\ bell = 1
```

`PROPERTY Narrow` is a clean run, exit 0, 6 distinct states. Same body, same
model, opposite verdict. Under `_hand` a `Ring` step leaves `hand` alone, so
the second disjunct of `[P]_hand` carries it. The claim about `bell` never
gets tested on the one step that breaks it.

A narrow subscript turns up 16 times in the 421 box sites the survey could
resolve, and all 16 are classified there into four reasons:

| what the author was doing | sites | modules |
|---|---|---|
| a stability property over the variable it constrains | 6 | `Consistency`, `SingleNode`, `Paxos`, `ACP_SB_TLC`, `ACP_NB_TLC`, `EWD687a` |
| a real-time spec conjoined with a clock | 5 | `MCRealTimeHourClock`, `RTWriteThroughCache` |
| a component spec over its own variables | 3 | `InnerFIFOInstanced`, `CompositeFIFO` |
| an abstract spec under a refinement mapping | 2 | `WriteThroughCacheInstanced` |

Lamport writes one himself, in §9.1, p. 119:
`MinTime == [][HCnxt => (t >= 3600 - Rho)]_hr`, with the comment "We don't
care about steps that leave `hr` unchanged." So the narrow form is a thing you
choose and then say out loud, not a thing you reach for by accident. If you
can't name which of those four you're doing, write `vars`.

## A set as the subscript is accepted, and it will pass a claim that is false

The survey looked for three subscript shapes across 666 modules and found none
of them: a record literal, an indexed element like `x[i]`, and a derived state
function outside a refinement mapping. Zero sites each.

Unattested isn't the same as rejected, and that gap is worth a section,
because TLC takes all three. The subscript is any state function, which a
record, an index and a named set all are. A set is the shape that bites, since
it forgets order and it forgets multiplicity.

```tla
---- MODULE Seesaw ----
EXTENDS Integers
VARIABLES left, right
vars == <<left, right>>

\* Two state functions over the same two variables. The set forgets which
\* value sat on which side, and the record does not.
seen == {left, right}
pans == [l |-> left, r |-> right]

Init == left = 0 /\ right = 1
Swap == left' = right /\ right' = left
Next == Swap
Spec == Init /\ [][Next]_vars

\* One claim, which is false: the left pan never moves.
Tuple == [][left' = left]_vars
Set == [][left' = left]_seen
Record == [][left' = left]_pans

\* A fourth subscript, reached by indexing the tuple. vars[1] is left.
Index == [][left' = left]_(vars[1])
=======================
```

All four subscripts parse and run, so none of these is a syntax question.
`left` moves on every step, so the claim is false and three of the four say
so. `PROPERTY Tuple`, `PROPERTY Record` and `PROPERTY Index` each exit 13.
`PROPERTY Set` is a clean run, exit 0, 2 distinct states.

The arithmetic is the whole story. `seen` is `{0, 1}` before the swap and
`{1, 0}` after it, and those are the same set. So `UNCHANGED seen` holds on a
step that moved both variables, and the second disjunct of `[P]_seen` passes a
property nothing about the system supports. The record escapes it because
`[l |-> 0, r |-> 1]` and `[l |-> 1, r |-> 0]` are different values, and the
index escapes it because `left` is the thing that moved.

I think this is the worst case on the page, and the reason is the exit code
rather than the mistake. There's no message, no trace and no warning. A suite
that checks exit codes and not state counts stays green over it.

## A liveness property is false until a fairness conjunct arrives

`[][Next]_vars` always admits the behavior that does nothing. So any property
asking for something to happen is refuted by that behavior, and fails on a
spec with no fairness conjunct. 196 of the 337
configuration files the survey read declare no fairness anywhere. That's the
majority case rather than an omission, since most of those specs are pure
safety.

`Pawl` is a ratchet that climbs two notches:

```tla
---- MODULE Pawl ----
EXTENDS Integers
VARIABLE pos
vars == <<pos>>

Init == pos = 0
Climb == pos < 2 /\ pos' = pos + 1
Hold == pos = 2 /\ UNCHANGED vars
Next == Climb \/ Hold

\* The spec with no fairness, which admits the behavior that never moves.
Spec == Init /\ [][Next]_vars

\* The same spec with weak fairness on the one action that goes anywhere.
Fair == Init /\ [][Next]_vars /\ WF_vars(Climb)

\* The same spec without the Hold disjunct, so the top of the ratchet has no
\* successor and TLC finds a deadlock there.
Blocked == Init /\ [][Climb]_vars

Top == <>(pos = 2)
Rise == (pos = 0) ~> (pos = 2)

\* ENABLED as a state predicate. It is false at the top of the ratchet.
CanClimb == ENABLED Climb
=====================
```

The last three definitions belong to the two sections further down. With
`SPECIFICATION Spec`, both `Top` and `Rise` exit 13 on the same
counterexample:

```
Error: Temporal property Top was violated.
Error: The following behavior constitutes a counter-example:
State 1: <Initial predicate>
pos = 0
State 2: <Climb line 7, col 10 to line 7, col 34 of module Pawl>
pos = 1
State 3: Stuttering
```

With `SPECIFICATION Fair` both are clean runs, exit 0, 3 distinct states. One
conjunct is the whole difference. `Hold` is there so the top of the ratchet
has a successor, which keeps TLC's deadlock check quiet. The last section on
this page is what happens when you leave it out.

Read `State 3: Stuttering` as the diagnosis. It says the behavior stopped
rather than went wrong, and a behavior that stops is what a missing fairness
conjunct lets through.

One measured oddity, and I don't know the mechanism. TLC adds a hint to the
`~>` run that it leaves off the `<>` run, on the same spec and the same trace
shape:

```
Warning: The stuttering counterexample above may be caused by the absence of
a fairness constraint in the behavior specification Spec defined at line 12,
col 1 to line 12, col 29 of module Pawl. To rule out such counterexamples,
conjoin a suitable fairness constraint to Spec (compare Chapter 8, page 87ff
of Specifying Systems at https://lamport.azurewebsites.net/tla/book.html).
```

Each run was measured twice, and the hint landed on the `~>` run both times
and on the `<>` run neither time. So it's worth reading when it shows up, and
its absence isn't evidence that fairness isn't your problem.

## Weak fairness asks for less than you think, and fairness on `Next` asks for almost nothing

Three things get called "add a fairness conjunct" and they're not the same
thing. `Capstan` separates them:

```tla
---- MODULE Capstan ----
EXTENDS Integers
VARIABLES turn, hauled
vars == <<turn, hauled>>

Init == turn = 0 /\ hauled = FALSE

\* The capstan swings back and forth whether or not anybody takes the rope.
Swing == /\ turn' = 1 - turn
         /\ hauled' = hauled

\* The rope can only be taken at one end of the swing.
Haul == /\ turn = 1
        /\ ~hauled
        /\ hauled' = TRUE
        /\ turn' = turn

Next == Swing \/ Haul

\* Fairness on the whole next-state relation. It asks for some step.
Moving == Init /\ [][Next]_vars /\ WF_vars(Next)

\* Weak fairness on Haul, which asks for an action eventually always enabled.
Weak == Init /\ [][Next]_vars /\ WF_vars(Swing) /\ WF_vars(Haul)

\* Strong fairness on Haul, which asks for one always eventually enabled.
Strong == Init /\ [][Next]_vars /\ WF_vars(Swing) /\ SF_vars(Haul)

Taken == <>hauled
========================
```

`PROPERTY Taken` against each of the three specs, in order: exit 13, exit 13,
exit 0 with 4 distinct states. The two failures share a counterexample, and
it's a lasso rather than a stutter:

```
State 1: <Initial predicate>
/\ hauled = FALSE
/\ turn = 0
State 2: <Swing line 9, col 10 to line 10, col 28 of module Capstan>
/\ hauled = FALSE
/\ turn = 1
Back to state 1: <Swing line 9, col 10 to line 10, col 28 of module Capstan>
```

`WF_vars(Next)` fails because `Swing` is a step, so swinging forever satisfies
the demand and nobody ever takes the rope. Fairness on the whole next-state
relation asks that something happen, which on any spec with more than one
action is close to free. 83 of 337 configuration files name a specification
carrying a fairness conjunct. A conjunct on `Next` is the shape I'd check
first when one of them looks too easy to satisfy.

`WF_vars(Haul)` fails for a sharper reason, and it's the definition. Weak
fairness is `<>[](ENABLED <<A>>_v) => []<><<A>>_v`, so it only asks for
anything once the action is **eventually always** enabled. `Haul` is enabled
at `turn = 1` and disabled at `turn = 0`, and `Swing` keeps flipping between
them. So the antecedent never becomes true and the whole implication is
satisfied for free.

`SF_vars(Haul)` is the same formula with `[]<>` in the antecedent instead,
which is exactly the case here: `Haul` is **always eventually** enabled.
`Swing` has to be forced too, or the behavior that stutters at `turn = 0`
never enables `Haul` and satisfies the strong demand the same vacuous way.

So the rule I'd carry out of this: weak fairness fits an action whose guard,
once true, stays true. An action behind a guard that comes and goes needs
strong fairness.

## A fairness conjunct outside `Next` empties the spec, and TLC exits 0

I'd call this the most expensive single mistake in the family, and the reason
is that it has no error channel at all.

Lamport's condition is at *Specifying Systems* §8.9.2, p. 112. A spec "is
guaranteed to be machine closed if `Liveness` is the conjunction of weak
and/or strong fairness properties for subactions of `Next`." The phrase that
does the work is "subactions of `Next`". Break it and you lose more than
machine closure, because the set of behaviors satisfying `Spec` goes empty.

`Detent` is a two-notch dial with an action that `Next` forbids:

```tla
---- MODULE Detent ----
EXTENDS Integers
VARIABLE notch
vars == <<notch>>

Init == notch = 0
Turn == notch < 2 /\ notch' = notch + 1
Hold == notch = 2 /\ UNCHANGED vars
Next == Turn \/ Hold

\* Slip is not a disjunct of Next, so [][Next]_vars forbids every Slip step.
Slip == notch' = 99

\* Fairness on a subaction of Next. This is the sound shape.
Live == Init /\ [][Next]_vars /\ WF_vars(Turn)

\* Fairness on an action Next does not allow. No behavior satisfies this.
Dead == Init /\ [][Next]_vars /\ WF_vars(Slip)

\* A liveness obligation no behavior can satisfy, whatever the spec.
Moves == []<>(notch # notch)

\* The same falsehood said over a state, which TLC lifts to an invariant.
Stuck == [](notch = 99)
=======================
```

`Moves` is false of every behavior, since `notch # notch` is false in every
state. Against `Live` it exits 13, with a counterexample, which is the answer
you want. Against `Dead` it is a clean run, exit 0, 3 distinct states, and
TLC prints no warning of any kind about `Slip`.

The pair is the finding. The same impossible property reads 13 on one spec and
0 on the other, and the one it passes on is the broken one. `WF_vars(Slip)`
demands a `Slip` step and `[][Next]_vars` forbids every `Slip` step, so no
behavior satisfies both conjuncts. Every liveness obligation then holds over
nothing, and holding over nothing is what TLC reports as success.

Three things make this hard to catch. The state space is healthy, so a state
count tells you nothing. Fairness never touches the state graph, it constrains
the behaviors over that graph, so a coverage report shows every action firing.
And the exit code is the one you were hoping for.

The invariant channel still fires, and that's the part worth knowing. The same
dead spec exits 12 on `Stuck`, which is a `[]` over a state predicate:

```
Error: Invariant Stuck is violated by the initial state:
notch = 0
```

The configuration said `PROPERTY Stuck` and TLC's message says "Invariant". It
lifted the formula to an invariant and walked the state graph, which ignores
the fairness conjunct entirely. So a spec checked only through lifted
invariants looks healthy while every liveness obligation on it is vacuous.
That's the combination to watch for: safety green, liveness green, and nothing
on the liveness side meaning anything.

Check that every action named in a fairness conjunct is also a disjunct of
`Next`. It's a two-minute read of one definition and I don't know of a cheaper
way to rule this out.

## Fairness quantified over a set is accepted, and `\E` is almost never what you want

TLC takes a quantifier over a temporal formula, which the cheat sheets don't
mention. That matters as soon as you have a set of processes rather than one.

```tla
---- MODULE Tumbler ----
CONSTANT Pins
VARIABLE lifted
vars == <<lifted>>

Init == lifted = {}
Drop(p) == p \notin lifted /\ lifted' = lifted \cup {p}
Settled == lifted = Pins /\ UNCHANGED vars
Next == (\E p \in Pins : Drop(p)) \/ Settled

\* Weak fairness on every pin.
All == Init /\ [][Next]_vars /\ \A p \in Pins : WF_vars(Drop(p))

\* Weak fairness on some pin, which leaves the rest of them free to hang.
Some == Init /\ [][Next]_vars /\ \E p \in Pins : WF_vars(Drop(p))

Full == <>(lifted = Pins)
========================
```

With `Pins = {p1, p2}`, `PROPERTY Full` against `All` is a clean run, exit 0,
4 distinct states. Against `Some` it exits 13:

```
Error: Temporal property Full was violated.
Error: The following behavior constitutes a counter-example:
State 1: <Initial predicate>
lifted = {}
State 2: <Drop(p1) line 7, col 12 to line 7, col 55 of module Tumbler>
lifted = {p1}
State 3: Stuttering
```

So `\E` over a fairness formula is a formula TLC checks rather than refuses,
and it means what it says: somebody gets treated fairly. The counterexample
names `Drop(p1)` with its argument, which is how you tell which pin was the
lucky one.

`\A` is the shape you almost always want, and the `\E` inside `Next` is a
different decision from the one in the conjunct. `Next` says some pin can
drop, and the fairness conjunct says which pins eventually do.

## An action that leaves a variable out is an error, not a free `UNCHANGED`

An action has to describe a whole step. Leave a variable out and the action
doesn't say what that variable becomes, and TLC will not guess `x' = x` for
you. `Mainspring` has two variables and one action that mentions one of them:

```tla
---- MODULE Mainspring ----
EXTENDS Integers
VARIABLES coil, locked
vars == <<coil, locked>>

Init == coil = 0 /\ locked = FALSE

\* Wind says nothing about locked, so it does not describe a whole step.
Wind == coil < 2 /\ coil' = coil + 1

\* The same action with the missing half supplied.
WindOk == Wind /\ UNCHANGED locked

Stop == coil = 2 /\ UNCHANGED vars

\* Two next-state relations over the same action, one of them incomplete.
Loose == Init /\ [][Wind \/ Stop]_vars
Tight == Init /\ [][WindOk \/ Stop]_vars

Bounded == coil <= 2
===========================
```

`SPECIFICATION Loose` exits 75 on the first step, and the whole message is two
sentences, so a search for a shortened version of it finds nothing:

```
Error: Successor state is not completely specified by action Wind of the
next-state relation. The following variable is not defined: locked.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ coil = 0
/\ locked = FALSE
State 2: <Wind line 9, col 9 to line 9, col 36 of module Mainspring>
/\ coil = 1
/\ locked = null
```

Read the trace's second state. `locked = null` is TLC showing you the hole it
found, and `null` isn't a TLA+ value. `SPECIFICATION Tight` is a clean run,
exit 0, 3 distinct states.

The PlusCal translator writes `x' = x` for a variable an action doesn't touch.
That's why this never bites you there, and bites you on the first raw-TLA+
spec you write by hand. `UNCHANGED <<a, b, c>>` covers several at once, and
`UNCHANGED vars` in a terminal disjunct covers the lot. `Stop` above is that
idiom, and it's the same shape as the `Terminating` action PlusCal emits into
every algorithm that ends.

## `ENABLED` is an ordinary state predicate here, and a trap under refinement

`ENABLED A` is true in a state from which `A` can describe the next step.
That's a predicate over one state, so it goes anywhere a predicate goes,
including an `INVARIANT`. `Pawl` above carries one:

```tla
\* ENABLED as a state predicate. It is false at the top of the ratchet.
CanClimb == ENABLED Climb
```

`INVARIANT CanClimb` exits 12 at the top of the ratchet, which is the right
answer, since `Climb` is guarded by `pos < 2`:

```
Error: Invariant CanClimb is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
pos = 0
State 2: <Climb line 7, col 10 to line 7, col 34 of module Pawl>
pos = 1
State 3: <Climb line 7, col 10 to line 7, col 34 of module Pawl>
pos = 2
```

So nothing goes wrong until you instantiate a module. Substitution distributes
over almost every operator and it does **not** distribute over `ENABLED`. It
therefore doesn't distribute over `WF_` or `SF_` either, since both are
defined in terms of it. That is the one fact about `ENABLED` worth carrying.
This project treats it at length, with Lamport's own two-variable example,
under [Refinement](../../chapter/refinement.md) at "Liveness, and why ENABLED
ruins it".

The practical consequence is about fairness rather than about `ENABLED`. A
fairness condition on a concrete spec does not hand you the abstract spec's
fairness condition under a mapping. You have to argue it.

## A deadlock is reported instead of the liveness violation, not alongside it

Both can be true of one run and you only hear about one. `Pawl`'s third spec
is the same system with `Hold` dropped, so the top of the ratchet has no
successor:

```tla
\* The same spec without the Hold disjunct, so the top of the ratchet has no
\* successor and TLC finds a deadlock there.
Blocked == Init /\ [][Climb]_vars
```

`SPECIFICATION Blocked` with `PROPERTY Top` exits 11:

```
Error: Deadlock reached.
Error: The behavior up to this point is:
State 1: <Initial predicate>
pos = 0
State 2: <Climb line 7, col 10 to line 7, col 34 of module Pawl>
pos = 1
State 3: <Climb line 7, col 10 to line 7, col 34 of module Pawl>
pos = 2
```

`Blocked` carries no fairness conjunct, so `Top` is violated by the stuttering
behavior exactly as it is under `Spec`. TLC says nothing about it. The
deadlock aborts the state-graph walk before the temporal pass runs, and the
temporal pass is where a liveness verdict comes from.

So fixing a deadlock can uncover a second failure you had no way to see. I
wouldn't read a deadlock as the only thing wrong with a spec. 79 of the 337
configuration files the survey read set `CHECK_DEADLOCK FALSE`, usually
because the terminal state is intended. A `Hold` or `Terminating` disjunct is
the other way to say the same thing.

## Where this is taught

Three chapters, in an order that doesn't match the dependencies. learntla's
temporal-properties chapter, which this project's chapter 9 exercise set
follows, introduces `[]`, `<>`, `<>[]`, `[]<>` and `~>`. It also introduces
fairness, but in its PlusCal spelling, as `fair process` and `fair+`. The
`WF_` and `SF_` operators those translate into don't arrive until chapter 12.

Chapter 11 is action properties, and it covers three of the rows above:
priming, `[P]_x` and the action property itself. Its cheat sheet already warns
that a quantifier wrapped around the whole `[]` fails to check. Since `[]`
commutes with `\A`, the fix is to move the quantifier inside.

Chapter 12 bootstraps raw TLA+ by reading the PlusCal translator's output, so
it carries most of this page: `VARIABLE`, `vars`, the `Init` / `Next` / `Spec`
skeleton, the formal definition of an action, `UNCHANGED`, nondeterministic
actions, `ENABLED`, `<<A>>_v`, both fairness operators, and both places a
fairness conjunct can attach.

For `ENABLED` under a substitution, and for liveness refinement generally, see
[Refinement](../../chapter/refinement.md). That chapter is this project's own
work rather than a learntla mirror, and it's the only place here that treats
the interaction at length.
