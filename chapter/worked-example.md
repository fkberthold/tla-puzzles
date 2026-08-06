# Worked example: an observatory

One abstract spec, one concrete spec, one mapping, built end to end. Then the
part you're here for: a mapping that looks completely reasonable, that TLC
accepts, and that checks nothing at all.

Everything below is in [`snippets/`](snippets/). Run `./run-all.sh` there and
it will re-run all of it and check the exit codes.

## The system

A radio observatory has several dishes and a queue of observing proposals. To
observe a proposal, a dish slews onto it and integrates — collects signal —
for some number of minutes. When it has collected enough, the result goes
into the archive.

Weather ruins integrations. If cloud comes over partway through, the
accumulated signal is worthless: the dish gives up, the proposal goes back in
the queue, and the accumulator resets to zero. Several dishes work at once,
on different proposals, and cloud arrives independently over each of them.

That's the system. Now, what is it *for*?

## The abstract spec

It's for turning proposals into archived datasets. That's the whole job, and
it takes two variables' worth of nothing:

```tla
---------------------------- MODULE Almanac ----------------------------
CONSTANT Proposals

VARIABLE logged
vars == << logged >>

Init == logged = {}

Record(p) ==
  /\ p \notin logged
  /\ logged' = logged \cup {p}

Next == \E p \in Proposals : Record(p)

Spec == Init /\ [][Next]_vars

AppendOnly == [][logged \subseteq logged']_vars

NoDuplicates == [][\A p \in Proposals : p \in logged => p \in logged']_vars
========================================================================
```

Note what isn't here. No dishes. No weather. No integration. No time. An
astronomer reviewing this can tell you in ten seconds whether it says the
right thing, which is the only kind of correctness a specification ever
actually gets.

And note the two properties at the bottom. The archive only grows, and
nothing ever falls out of it. Both are trivially true of this module — that's
the point. They're cheap here and they will not be cheap later.

## The concrete spec

```tla
--------------------------- MODULE Observatory ---------------------------
EXTENDS Naturals

CONSTANTS Proposals, Dishes, Needed, Idle

VARIABLES status, onsky, acc
cvars == << status, onsky, acc >>

Init ==
  /\ status = [p \in Proposals |-> "queued"]
  /\ onsky  = [d \in Dishes    |-> Idle]
  /\ acc    = [p \in Proposals |-> 0]

Slew(d, p) ==
  /\ onsky[d] = Idle
  /\ status[p] = "queued"
  /\ onsky'  = [onsky  EXCEPT ![d] = p]
  /\ status' = [status EXCEPT ![p] = "observing"]
  /\ UNCHANGED acc

Integrate(d) ==
  /\ onsky[d] # Idle
  /\ acc[onsky[d]] < Needed
  /\ acc' = [acc EXCEPT ![onsky[d]] = @ + 1]
  /\ UNCHANGED << status, onsky >>

Cloud(d) ==
  /\ onsky[d] # Idle
  /\ acc[onsky[d]] < Needed
  /\ status' = [status EXCEPT ![onsky[d]] = "queued"]
  /\ acc'    = [acc    EXCEPT ![onsky[d]] = 0]
  /\ onsky'  = [onsky  EXCEPT ![d] = Idle]

Archive(d) ==
  /\ onsky[d] # Idle
  /\ acc[onsky[d]] = Needed
  /\ status' = [status EXCEPT ![onsky[d]] = "archived"]
  /\ onsky'  = [onsky  EXCEPT ![d] = Idle]
  /\ UNCHANGED acc

Next ==
  \E d \in Dishes :
    \/ \E p \in Proposals : Slew(d, p)
    \/ Integrate(d)
    \/ Cloud(d)
    \/ Archive(d)

Spec == Init /\ [][Next]_cvars
```

Four actions, three variables, two dishes' worth of interleaving. At
`Proposals = {p1, p2}`, `Dishes = {d1, d2}`, `Needed = 2` this has 46 distinct
reachable states, which is small enough to check instantly and big enough
that you would not want to eyeball it.

## The mapping

Now: which concrete steps are `Record` steps?

Only `Archive`. `Slew` moves a dish. `Integrate` moves a counter. `Cloud`
undoes an integration. None of those put anything in the archive, so all
three have to be invisible to `Almanac` — and they will be, automatically,
if the mapped expression doesn't change during them.

That tells you what the expression has to be:

```tla
Archived == { p \in Proposals : status[p] = "archived" }

A == INSTANCE Almanac WITH logged <- Archived

Refines == A!Spec
```

Check the invisibility claim by hand, because this is the part that actually
requires thought:

| concrete action | changes `Archived`? | abstract step |
| --- | --- | --- |
| `Slew(d, p)` | no — `p` goes `queued` → `observing` | stuttering |
| `Integrate(d)` | no — touches only `acc` | stuttering |
| `Cloud(d)` | no — `observing` → `queued` | stuttering |
| `Archive(d)` | yes — adds one proposal | `Record(p)` |

And `Record`'s guard is `p \notin logged`, which holds because `Archive`
requires `status[p] = "observing"`. Nothing gets archived twice.

Note that this is a mapping the concrete spec had to *earn*. If `Cloud` had
reset `status[p]` to `"archived"` by mistake, or if `Archive` could fire
twice, the mapping wouldn't work — and that's the useful thing about writing
one. The mapping is where you say out loud what your implementation's states
are supposed to mean.

## Running it

```
CONSTANTS
    Proposals = {p1, p2}
    Dishes    = {d1, d2}
    Needed    = 2
    Idle      = Idle

SPECIFICATION Spec
INVARIANT     TypeOK
PROPERTY      Refines
CHECK_DEADLOCK FALSE
```

```
$ ./run.sh Observatory.tla
Model checking completed. No error has been found.
121 states generated, 46 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 9.
=== Observatory.tla (Observatory.cfg) rc=0
```

## What that bought

The two properties from `Almanac` are now facts about the observatory. Not
"provable by a similar argument" — facts, already established, no further
work. You can point TLC at them directly to see it:

```tla
InheritedAppendOnly   == A!AppendOnly
InheritedNoDuplicates == A!NoDuplicates
```

```
$ ./run.sh Observatory.tla ObservatoryInherited.cfg
Model checking completed. No error has been found.
=== Observatory.tla (ObservatoryInherited.cfg) rc=0
```

(They need names because the config takes bare identifiers; you can't write
`PROPERTY A!AppendOnly`.)

Running them is a demonstration, not a requirement. They were true the
instant `Refines` passed. `A!AppendOnly` *is* `Almanac`'s `AppendOnly` with
`logged` replaced by `Archived`, and `Refines` says every behavior of the
observatory satisfies `Almanac`'s `Spec` under that replacement. Anything
implied by `Almanac!Spec` comes along.

That's the whole economic argument for refinement, and it scales the way you
want: the abstract spec has 4 reachable states, the concrete spec has 46, and
the abstract spec is where every property gets stated and reviewed.

## The trap

Now the part I promised.

Suppose the observatory's author didn't think of keying off `status`. There's
a perfectly natural alternative — a proposal is archived when it has
collected all the signal it needed:

```tla
ArchivedTypo == { p \in Proposals : acc[p] > Needed }
```

Read that. It is a real expression over real state, it computes something,
and the intent is transparent: *the proposals that got their integration
time*. It survives code review. I would sign off on it.

It should say `>=`.

`acc` is bounded above by `Needed` — `Integrate` is guarded by
`acc[onsky[d]] < Needed`, so it stops there. So `acc[p] > Needed` is false
for every proposal in every reachable state, and `ArchivedTypo` is the empty
set forever. The mapping is a constant. One character.

Here's TLC on it:

```
$ ./run.sh Observatory.tla ObservatoryTypo.cfg
Model checking completed. No error has been found.
121 states generated, 46 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 9.
=== Observatory.tla (ObservatoryTypo.cfg) rc=0
```

Put that next to the good run. Same 121 states generated. Same 46 distinct.
Same depth 9. Same message. Same exit code. **There is no observable
difference between the check that worked and the check that did nothing.**

And nothing went wrong. `Almanac!Spec` under the mapping is this (an
expansion, not something you'd type):

```
(ArchivedTypo = {}) /\ [][ Record-substituted ]_<< ArchivedTypo >>
```

which expands to

```
(ArchivedTypo = {}) /\ [] ( Record-substituted \/ UNCHANGED << ArchivedTypo >> )
```

The initial conjunct holds. Then at every one of those 46 states, the right
disjunct is `TRUE`, so the disjunction is satisfied, so TLC moves on.
`Record` was never evaluated. Not once, in a state space of 46 states with
four interleaving actions across two dishes.

This is not a hypothetical. `tlaplus/TLAiBench` — the TLA+ Foundation's
benchmark for grading machine-written specs — checks refinement in two
separate stages, and runs each stage three ways: plain, then under two
`TLCGet` postconditions. A frozen mapping and a correct mapping produce
*identical* results on all three: the first two pass for both, and the third
fails for both. Not one of them tells the two apart.

## The probe

The check that catches it is one line and does not require you to be clever:

```tla
Frozen     == Archived     = {}
FrozenTypo == ArchivedTypo = {}
```

Run each as an `INVARIANT`, on the concrete spec, and **read a violation as a
pass**.

On the mapping we mean:

```
$ ./run.sh Observatory.tla ObservatoryProbe.cfg
Error: Invariant Frozen is violated.
State 1: <Initial predicate>
...
State 5: <Archive(d1) line 47, col 3 to line 51, col 18 of module Observatory>
=== Observatory.tla (ObservatoryProbe.cfg) rc=12
```

Five states in, an `Archive` step moved the mapped abstract state off `{}`.
The mapping is alive. The refinement check above it had something to
evaluate.

On the typo:

```
$ ./run.sh Observatory.tla ObservatoryTypoProbe.cfg
Model checking completed. No error has been found.
121 states generated, 46 distinct states found, 0 states left on queue.
=== Observatory.tla (ObservatoryTypoProbe.cfg) rc=0
```

Whole state space, mapping never moved. The refinement result you got is
worth nothing.

The four runs together:

| config | check | rc | verdict |
| --- | --- | --- | --- |
| `Observatory.cfg` | `PROPERTY Refines` | 0 | passes |
| `ObservatoryTypo.cfg` | `PROPERTY RefinesTypo` | 0 | passes |
| `ObservatoryProbe.cfg` | `INVARIANT Frozen` | 12 | **mapping is live** |
| `ObservatoryTypoProbe.cfg` | `INVARIANT FrozenTypo` | 0 | **mapping is frozen** |

The refinement check cannot tell the two mappings apart. The probe can. Run
both, always, and put a comment next to the probe explaining that 12 is the
good number, because someone will eventually "fix" it.

**What the probe does not do.** It rules out the degenerate mapping and
nothing more. `RunningH.tla` in the snippets has a mapping that moves on
every step, satisfies the probe at rc=12, passes the refinement check at
rc=0, and tracks nothing about the implementation at all. There's no
mechanical substitute for reading the mapping and asking whether the
expression means what its name says.

## When it really does fail

For contrast, here's a mapping that's wrong in a way TLC *can* see. Suppose
you decide a proposal counts as archived as soon as a dish is on it:

```tla
ArchivedEager == { p \in Proposals : status[p] # "queued" }
```

That's not frozen — it moves on `Slew`. And it fails, because `Cloud` puts
the proposal back in the queue, which takes it *out* of the abstract archive,
and `Almanac` says the archive only grows.

The error message points at the abstract module, which is not where you're
looking:

```
Error: Action property line 21, col 17 to line 21, col 29 of module Almanac
is violated.
```

Line 21 of `Almanac` is `Spec == Init /\ [][Next]_vars`, columns 17–29 being
`[][Next]_vars`. Accurate, and no help.

Add an `ALIAS` that prints the mapped abstract state alongside the concrete
one:

```tla
Alias ==
  [ status |-> status,
    onsky  |-> onsky,
    acc    |-> acc,
    logged |-> ArchivedEager ]
```

```
State 2: <Slew(d1,p1) line 27, col 3 to line 31, col 18 of module Observatory>
/\ status = (p1 :> "observing" @@ p2 :> "queued")
/\ onsky = (d1 :> p1 @@ d2 :> Idle)
/\ acc = (p1 :> 0 @@ p2 :> 0)
/\ logged = {p1}

State 3: <Cloud(d1) line 40, col 3 to line 44, col 42 of module Observatory>
/\ status = (p1 :> "queued" @@ p2 :> "queued")
/\ onsky = (d1 :> Idle @@ d2 :> Idle)
/\ acc = (p1 :> 0 @@ p2 :> 0)
/\ logged = {}
```

`logged = {p1}`, then `logged = {}`. That is the entire diagnosis, visible
without thinking. Put the mapping in an `ALIAS` before you start debugging a
refinement failure, not after.

One more note on that trace: the failure is a *temporal* violation, and TLC
exits **13** for those, where a violated `INVARIANT` gives **12**. If you're
scripting these checks, don't test for 12 alone.

## The checklist

For any refinement you set up:

1. Define `Refines == Abstract!Spec` and name it in the config under
   `PROPERTY`. The config takes bare identifiers, so it has to be a named
   operator.
2. Write out, action by action, which concrete steps you expect to be
   visible. If you can't, you don't have a mapping yet, you have a guess.
3. Add the frozen-mapping probe as an `INVARIANT`, and label the inverted
   exit code loudly.
4. Add an `ALIAS` carrying the mapped abstract state, before you need it.
5. If it fails and you can't see why, drop to `IProp == [][A!Next]_<<mapped>>`
   to find out whether the problem is in the actions or in `Init`.
6. Read the mapping and ask, out loud, whether the expression means what its
   name claims. Nothing above this line does that for you, and the answer is
   the whole content of the claim.
