# Sets

A set is an unordered collection with no repeats. This family holds nine
constructs in four groups. The literal. The operators that relate and combine
two sets. The four ways to build a set out of something that isn't one. And the
four that go the other way, handing back a single value or a smaller set.

Reach for a set when the state is a collection and the order isn't part of the
problem. What pays for it is exploration. A set on the right of `\in` is how
you say "any of these" and have the checker mean it. TLC opens one branch per
member and follows all of them.

What it costs is the same thing. The reachable state count tracks the
cardinality of the sets you drew the state from, and `SUBSET` doubles that for
each element you add.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-21.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| set literal | `{1, 2, 3}`, unordered and unique | a collection with no order, where writing a value twice does not add a second member | not counted |
| relational and algebraic operators | `x \in S`, `x \notin S`, `s1 \subseteq s2`, `s1 \union s2`, `s1 \intersect s2`, `s1 \ s2` | membership, containment, and the three ways to combine two sets | not counted |
| `Cardinality` | `Cardinality(set)`, needs `EXTENDS FiniteSets` | how many members the set has, defined only for a finite set | not counted |
| `BOOLEAN` and integer interval as sets | `BOOLEAN`, `a..b` | the two sets the language hands you: `{FALSE, TRUE}`, and every integer from `a` up to `b` | not counted |
| Cartesian product | `S \X T` | every pair whose first component is in `S` and whose second is in `T` | not counted |
| `SUBSET` (powerset) | `SUBSET S` | the set of every subset of `S`, including `S` itself and the empty set | not counted |
| set map | `{expr: x \in S}` | evaluate `expr` at each member and collect the answers | not counted |
| set filter | `{x \in S: P(x)}` | the members of `S` that satisfy `P` | not counted |
| `CHOOSE` | `CHOOSE x \in S: P(x)` | one member of `S` satisfying `P`, and the same one on every evaluation | not counted |

The fourth column reads "not counted" nine times out of nine, and that's the
honest entry rather than a gap. The survey behind the column read 666 modules
and 337 configuration files from 16 public repositories on 2026-09-05. Its
passes counted obligation decomposition, subscripts, naming, redundancy among
declared obligations, PlusCal uptake and the configuration keywords. None of
them counted a set operator. So "not counted" means the survey has no number
for it, not that the construct is rare. Each count below is one I measured on
this build.

Three spellings to know before you read anyone else's spec. `\cup` and `\cap`
are the same operators as `\union` and `\intersect`, and `\times` is the same
as `\X`. There's no `\subset` at all, so the one operator you have is
subset-or-equal:

```
tlc -repl '{1} \subset {1}'
Error evaluating expression: '{1} \subset {1}'
Could not find declaration or definition of symbol '\subset'.
```

`{1} \subseteq {1}` answers `TRUE`, which is the part of that to remember.
`\subseteq` holds between a set and itself.

## `CHOOSE` picks one member, and picks the same one every time

This trap comes first because the keyword reads like the opposite of what it
does. "Choose an element" sounds like a decision the system makes. It's a name
for a value, fixed by the set and the predicate, and the whole model gets one
of them.

Two modules, same system. A chute is selected out of three. The first draws
with membership and selects inside the action:

```tla
---- MODULE Quarry ----
EXTENDS Integers
VARIABLE atChute

Chutes == 1..3

Init == atChute \in Chutes
Next == \E c \in Chutes : atChute' = c
Spec == Init /\ [][Next]_<<atChute>>

OneChuteOnly == atChute = 1
=======================
```

The second asks for an element instead:

```tla
---- MODULE QuarryPick ----
EXTENDS Integers
VARIABLE atChute

Chutes == 1..3

Init == atChute = CHOOSE c \in Chutes : TRUE
Next == atChute' = CHOOSE c \in Chutes : TRUE
Spec == Init /\ [][Next]_<<atChute>>

OneChuteOnly == atChute = 1
===========================
```

`Quarry` finds 3 distinct states. `QuarryPick` finds 1. The second model has
one chute in it, and it's chute 1 forever.

Now add the invariant, which claims that chute 1 is the only one ever used.
That claim is false about the system. `Quarry` says so, exit 12:

```
Error: Invariant OneChuteOnly is violated by the initial state:
atChute = 2
```

`QuarryPick` exits 0 and reports no error. The claim came back true because
nothing in that model ever reached a second chute.

That's the shape to watch for. You get a confirmation where you wanted a
refutation, and a confirmation is the answer nobody double checks. The state
count is the other signal, and it moves first: 1 where you expected 3.

What to write instead depends on who is deciding.

Case one, the system is deciding and any member will do. Use membership in
`Init`, as `atChute \in Chutes`, or an existential in the action, as
`\E c \in Chutes : atChute' = c`. TLC follows each branch.

Case two, the state has already settled it and you want to read it back.
`CHOOSE` is right here, and it's the normal way to write a lookup:

```tla
On(r) == CHOOSE u \in Upstreams : <<r, u>> \in inflight
```

That reads the one upstream a request is already on. It's a function of the
state, not a choice about it, and it's well defined because the state has made
the choice unique.

Keep the distinction in those words. The existential when the system is
deciding, `CHOOSE` when the state already has.

One more thing about which member you get. `QuarryPick` lands on 1, and
`CHOOSE x \in {"c","a","b"} : TRUE` answers `"a"` here. I'd treat both as facts
about this TLC build and not as rules of the language. What you can build on is
that the answer doesn't move between two evaluations over the same set and
predicate. Predicting it is a different thing. If a particular member matters,
say which one in the predicate.

## The colon means two things, and a set map can be smaller than the set it maps

`{x \in S : P(x)}` and `{expr : x \in S}` differ by which side of the colon the
`\in` sits on, and they do unrelated jobs. The first is a filter and keeps
members of `S`. The second is a map and keeps answers, which usually aren't
members of `S` at all.

The map is also free to shrink. Nine inputs, three outputs:

```
tlc -repl '{x % 3 : x \in 1..9}'
{0, 1, 2}
```

Collapsing is the normal case, not the edge case. A map lands in a set and a
set has no repeats. That bites hardest when you go on to count.

Three friends vote for one of two pubs. `FilterFor` keeps votes and `MapFor`
keeps answers to "is this vote for `p`":

```tla
---- MODULE Sieve ----
EXTENDS Integers, FiniteSets
VARIABLE votes

Pubs == {"anchor", "bell"}
Friends == 1..3

Init == votes = {}
Cast ==
  /\ \E f \in Friends, p \in Pubs :
       /\ \A v \in votes : v[1] /= f
       /\ votes' = votes \cup {<<f, p>>}
Next == Cast
Spec == Init /\ [][Next]_<<votes>>

FilterFor(p) == {v \in votes : v[2] = p}
MapFor(p) == {v[2] = p : v \in votes}

NoLandslideFilter == \A p \in Pubs : Cardinality(FilterFor(p)) < 3
NoLandslideMap == \A p \in Pubs : Cardinality(MapFor(p)) < 3
MapIsBoolean == \A p \in Pubs : MapFor(p) \subseteq BOOLEAN
======================
```

All three friends can vote for the anchor, so both claims are false about the
system. The filter version finds it, exit 12:

```
Error: Invariant NoLandslideFilter is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
votes = {}

State 2: <Cast line 10, col 3 to line 12, col 40 of module Sieve>
votes = {<<1, "anchor">>}

State 3: <Cast line 10, col 3 to line 12, col 40 of module Sieve>
votes = {<<1, "anchor">>, <<2, "anchor">>}

State 4: <Cast line 10, col 3 to line 12, col 40 of module Sieve>
votes = {<<1, "anchor">>, <<2, "anchor">>, <<3, "anchor">>}
```

The map version exits 0 over all 27 distinct states. `MapIsBoolean` is why, and
it passes on the same run. `MapFor(p)` is a set of truth values, so it's a
subset of `BOOLEAN` and holds at most 2 members whatever the votes are.
`Cardinality(MapFor(p)) < 3` isn't a claim about voting at all. It's arithmetic
that can't come out false.

Don't read the counts as the tell here. The filter run reports 20 distinct
states against the map run's 27, and that gap is only TLC stopping at the first
violation. The state space is the same either way, and a third run on this
module pins it: with no invariant declared, `Sieve` exits 0 at 27 distinct
states. An invariant never appears in `Next`, so it can't change which states
exist. Swap a filter for a map inside one and you change the verdict and leave
the space alone. Here the exit code is the signal and the count isn't, which
is the reverse of most of this page.

## A filter over a function set is the sort you were about to write by hand

This is the constructive half of the same two forms, and it replaces more code
than anything else on the page.

`[S -> T]` is a set, holding each function from `S` to `T`. Filter it and you
keep the functions you want. So "the sorted arrangement of these lengths" is a
filter, not a loop:

```tla
---- MODULE Lathe ----
EXTENDS Integers, FiniteSets
VARIABLE order

Lengths == {2, 5, 9}
Slots == 1..3

Arrangements == [Slots -> Lengths]
Ascending == {f \in Arrangements : \A i \in 1..2 : f[i] < f[i+1]}

Init == order \in Ascending
Next == UNCHANGED order
Spec == Init /\ [][Next]_<<order>>

Candidates == Cardinality(Arrangements) = 27
ExactlyOne == Cardinality(Ascending) = 1
Sorted == \A i \in 1..2 : order[i] < order[i+1]
======================
```

Exit 0 with all three invariants, over 1 distinct state. 27 arrangements go in,
one comes out, and it's the ascending one. The value itself:

```
tlc -repl '{f \in [1..3 -> {5,9,2}] : \A i \in 1..2 : f[i] < f[i+1]}'
{<<2, 5, 9>>}
```

Two things make this better than the recursive builder most people reach for
first. You never write the algorithm, so you can't get the algorithm wrong. And
the predicate says what sorted means instead of giving a procedure that
produces it.

The standard library writes it this way too. `Permutations`, in the `TLC`
module, is one filter over one function set:

```tla
Permutations(S) ==
   {f \in [S -> S] : \A w \in S : \E v \in S : f[v]=w}
```

That's `TLC.tla` lines 81 and 82 inside `tla2tools.jar`, and it's the operator
a `SYMMETRY` declaration is built from. 49 of the 337 configuration files in
the survey declare `SYMMETRY`.

`SortSeq`, at line 88 of the same file, then uses both halves of this page at
once. It filters a function set down to the permutations, then puts `CHOOSE`
over the result to name the ordered one.

The same move turns up as an `Init` instead of a definition, and that's the
form to recognize in somebody's spec. Membership in a function set, then a
conjunct narrowing it:

```tla
Init == /\ pos \in [Wagons -> Tracks]
        /\ NoShare
```

`pos` opens on each assignment of wagons to tracks, and the second conjunct
throws out the ones that share a track. A filter written as two lines of
`Init`.

## `SUBSET` is the powerset, and for a set-valued variable it is the state space

`SUBSET S` holds each subset of `S`, so its cardinality is 2 to the power of
the cardinality of `S`. For a variable whose value is a subset, that number
isn't a detail about an expression. It's the size of the reachable state space.

```tla
---- MODULE Silos ----
EXTENDS Integers, FiniteSets
VARIABLE open

Bins == 1..4

Init == open = {}
Fill == \E b \in Bins \ open : open' = open \cup {b}
Next == Fill
Spec == Init /\ [][Next]_<<open>>

Shape == open \in SUBSET Bins
Doubling == Cardinality(SUBSET Bins) = 16
OneMoreBin == Cardinality(SUBSET (1..5)) = 2 * Cardinality(SUBSET Bins)

Still == UNCHANGED open
SpecPower == open \in SUBSET Bins /\ [][Still]_<<open>>
SpecSubseteq == open \subseteq Bins /\ [][Still]_<<open>>
======================
```

Exit 0, 16 distinct states. `Doubling` asserts that `SUBSET Bins` has 16
members and passes on the same run, which is the point. The state count and the
cardinality are one number. `OneMoreBin` passes too, and one more bin is one
more doubling. At ten bins it's 1024:

```
tlc -repl 'Cardinality(SUBSET (1..10))'
1024
```

So a draw from a powerset in `Init` is the most expensive initial predicate you
can write, and it's worth knowing when you've written one. Two spellings do it
and they're the same draw. `SpecPower` opens with `open \in SUBSET Bins` and
`SpecSubseteq` with `open \subseteq Bins`. Both exit 0 at 16 distinct states.

The containment relation is the one that surprises people, because it reads
like a test. Put an unconstrained variable on its left and it's a draw from the
powerset anyway.

## `S \X T \X U` is not `(S \X T) \X U`

Cross three sets in one expression and you get triples. Cross two, then cross
the result, and you get pairs whose first component is a pair. They're
different sets, and the parentheses aren't redundant:

```tla
---- MODULE Girder ----
EXTENDS Integers, Sequences
VARIABLE cell

Rows == {1, 2}
Cols == {3}
Levels == {4}

Triples == Rows \X Cols \X Levels
Nested == (Rows \X Cols) \X Levels

Init == cell \in Triples
Next == UNCHANGED cell
Spec == Init /\ [][Next]_<<cell>>

SameSet == Triples = Nested
InNested == cell \in Nested
Arity == /\ \A c \in Triples : Len(c) = 3
         /\ \A c \in Nested : Len(c) = 2
=======================
```

`Arity` exits 0 over 2 distinct states, so the arities are 3 and 2 as written.
`InNested` exits 12, and the state TLC prints is the readable part:

```
Error: Invariant InNested is violated by the initial state:
cell = <<1, 3, 4>>
```

A triple, and `Nested` holds no triples. This bites when you index the tuple.
`cell[2]` is `3` for a member of `Triples` and `4` for a member of `Nested`.
Nothing in the error channel will mention tuples, since indexing is legal on
both.

## A claim with no variable in it is not an invariant violation

Ask the same difference about the two sets and you don't get exit 12. `SameSet`
is false, and with `INVARIANT SameSet` the run reports:

```
Error: The invariant of SameSet is equal to FALSE
```

Exit 151, with no state and no trace. There's no state in the formula to find
one for. My read is that TLC evaluates it once up front and reports it the way
it reports a bad configuration. That fits the message and the code, but I
haven't sourced the mechanism.

The passing side is what makes this worth a section. `Arity` has no variable in
it either, and it's true, so it exits 0 over 2 distinct states and reads like
any other invariant that held. Only the failure channel differs. So if you're
asserting a fact about two sets instead of about the state, expect 151 and
don't go hunting for the trace it never printed.

## An empty interval is a model with no behaviors, and it reports clean

`a..b` is empty whenever `a` is greater than `b`. That's not an error and
nothing warns you:

```
tlc -repl '1..0'
{}
```

Draw a variable out of one in `Init` and the model has no initial states. Each
invariant then holds, including one that no state could satisfy:

```tla
---- MODULE Caliper ----
EXTENDS Integers
VARIABLE gauge

Lo == 3
Hi == 1
Band == Lo..Hi

Init == gauge \in Band
Next == gauge' = gauge
Spec == Init /\ [][Next]_<<gauge>>

Impossible == gauge /= gauge
========================
```

With `INVARIANT Impossible` the run exits 0. Three lines out of that report,
with the fingerprint estimate between them left out:

```
Finished computing initial states: 0 distinct states generated at 2026-10-22 00:07:58.
Model checking completed. No error has been found.
0 states generated, 0 distinct states found, 0 states left on queue.
```

`gauge /= gauge` is false of any value there is. It passed because it was never
evaluated. There's no deadlock report either, since a model with no states has
no state to be stuck in.

The count is the whole signal here, and it's why the suite behind this page
checks state counts and not just exit codes. A run that finds 0 distinct states
has told you nothing about the system, whatever it says afterwards.

A bound that runs backwards is usually computed, not typed. So I'd expect this
one to show up after a constant changes, not when the spec is first drafted.

## `Cardinality` comes from a module, and the definition you get is exponential

`Cardinality` isn't part of the language. It lives in `FiniteSets`, and a
module that uses it without saying so fails before any state is computed:

```
*** Errors: 1

line 12, col 12 to line 12, col 22 of module Mandrel

Unknown operator: `Cardinality'.
```

Exit 150. `EXTENDS Integers, FiniteSets` is the fix, and `Integers` doesn't
supply it.

Read what you get once you do extend it. `FiniteSets.tla` lines 21 through 27
define it by recursion over the powerset, and with the comment block left out
it reads:

```tla
Cardinality(S) ==
  LET CS[T \in SUBSET S] == IF T = {} THEN 0
                                      ELSE 1 + CS[T \ {CHOOSE x : x \in T}]
  IN  CS[S]
```

The recursive function's domain is `SUBSET S`. Read literally, that builds a
function over 2 to the power of the cardinality of `S` entries in order to
count `S`. It doesn't cost that, because TLC doesn't run it. The module's own
header says both of its operators "are overridden by TLC in the Java class
tlc2.module.FiniteSets", so what executes is a Java method.

Two things follow. The definition isn't a cost model for `Cardinality`, and it
isn't a pattern to copy either. A set recursion you write yourself, peeling one
member off with `CHOOSE` at each step, gets no override and no help.

The `CHOOSE` in there is the unbounded form, `CHOOSE x : x \in T` with no set
after the bound variable. That's the one place the form earns its keep.

The comment above the definition is a real constraint and not a note.
"Cardinality is defined only for finite sets", and asking for an infinite one
stops the evaluation:

```
tlc -repl 'Cardinality(Nat)'
Error evaluating expression: 'Cardinality(Nat)'
tlc2.tool.EvalException: Attempted to compute cardinality of the value
Nat
```

## Where this is taught

learntla's operators chapter, which this project's chapter 2 exercise set
follows. All nine constructs arrive there together, and the cheat sheet for
that chapter is where the shapes in the table above come from.

One construct gets a second pass twice, and it's `CHOOSE`. Chapter 6 uses it to
pick a sorted arrangement out of a function set, which is this page's third
section with a `CHOOSE` put over it. That chapter's cheat sheet states the
determinism plainly: the keyword "always returns the same value for the same
set and predicate".

Chapter 10 uses it to peel one member off a set during a recursion, and says in
as many words that the keyword itself belongs to chapter 2. Chapter 10's cheat
sheet is also the one place that records which member you get, that TLC takes
the lowest when several satisfy the predicate. Read that as a TLC behavior, for
the reason the first section gives.

The function set sits on the boundary with the functions and records family,
since `[S -> T]` is a set of functions. I put it here because the move that
matters about it is the filter.
