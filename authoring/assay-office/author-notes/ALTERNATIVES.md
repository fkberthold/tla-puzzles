# Alternatives considered (assay-office reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

One variable, `book`. It maps each ware to a record with three columns,
`verdict`, `struck` and `damaged`. `Observe` projects that into three functions
over `Wares`, one per field. The state is the office's book and the interface is
a view of it.

## Three functions, one per field

The strongest rival, and the shape rung 1 uses. Three variables named `verdict`,
`struck` and `damaged`, with `Observe` renaming them field for field.

I went with `book` because shape B asks the learner to write properties over
`Observe`. Three renamed functions make `Observe` a rename and nothing else, so
the rule that the variables can't carry the field names is met on spelling
alone. With one book the projection does real work, and a reader can see where
the interface comes from. I think that's a legibility call rather than a
correctness one. Both forms reach 125 states and both satisfy all four
obligations.

## One status field per ware

A single column holding `unmarked`, `struck` or `defaced`. Item 1's no-both
clause then holds by construction and no action can break it.

Section 3 of the description rules this out by name, and I agree with the
reason. A learner who writes `TRUE` in a costume passes TLC and learns nothing.
So the mark and the defacing stay two facts that separate actions set, and a
step could in principle strike a ware that's already defaced. Item 1 is what
forbids it.

## Where the fairness sits

`FairSpec` carries one weak-fairness conjunct per officer and per ware, over
that pair's defacing action alone.

Two coarser forms were available. Weak fairness on "this officer takes a step"
obliges none of the disjuncts. An officer who tests wares forever satisfies it
while a substandard ware sits whole, item 3 fails, and the reference is wrong.
Weak fairness on "this officer defaces something" does work here, because
defacing is permanent and `Wares` is finite, so each defacing shrinks what's
pending. I'd rather not spend that argument on the rung whose one new high is
the fairness conjunct.

One wart, and I'd rather name it than let a reader find it. `Deface(o, w)`
doesn't use `o`. The translator elided `pc`, so an officer carries no state at
all, and every officer's defacing of a ware is the same action. I left the
parameter unused rather than write `o \in Officers`, which would look like a
guard and isn't one. The translator's own `officer(self)` carries the same
unused parameter ten lines up, so the shape at least matches what sits beside
it.

## The specification formula is called `FairSpec`

The translator writes `Spec == Init /\ [][Next]_vars` whether or not the
algorithm is fair, so a second definition of `Spec` isn't available. A `fair
process` annotation would give weak fairness on the whole process step, which is
the disjunction form above. The fairness has to go outside the translation, and
the formula carrying it needs its own name. The cfg names `FairSpec`.

## A process set against one process choosing an officer

A uniprocess algorithm with `with (o \in Officers)` reaches the same 125 states
and also drops `pc`. I kept the process set because the description's parties
list has officers as actors, and shape B ships the spec for the learner to read.
`process (officer \in Officers)` says who acts. A `with` inside one anonymous
process makes the officers look like a set of names.

## A per-officer bench

An officer picks a ware up, then acts on it in a second step. Section 3 says the
pick-up is stutter under `Observe`, so nothing forbids it. Section 4 prices it.
A local holding the chosen ware multiplies the count fourfold for each officer,
which is 2,000 states at three wares and two officers. State space 0 caps at
1,000, so this one is rejected on the count.

## Fusing the test and the strike

Section 3 licenses one step that writes an at-standard finding and strikes the
mark together. I kept them apart. The fusion saves one state per ware and buys
nothing else. Rule 4 has to keep its finding and its act apart, and writing rule
3 the other way round would read as an accident rather than a choice.
