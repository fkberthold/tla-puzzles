# The choices behind the published specification

You've written your model. This note reads the published one as a set of decisions
somebody made. Your model reading differently shouldn't read as your model reading
wrong.

The rules in the statement force none of what follows. For each choice I say what it
picked, what else was on the table, and what the pick costs and buys. The alternatives
aren't worse. Several of them can state things this one can't.

The files are `Majority.tla` (the algorithm), plus `MCMajority.tla` and `MCMajority.cfg`
(the model-checking wrapper). `MajorityProof.tla` is a TLAPS proof and is out of scope
here, though I point at it once where it explains a decision.

Every number below came from a model-checker run. The commands and their exit codes are
listed at the end of the consistency note that ships with this one.

## Standing positions became a count and a value

This is the decision the problem exists for, so it gets the most room.

Rules 4 to 6 talk about positions. Every read position is cancelled or standing, a
cancellation pairs two of them, and all standing positions share a value. The
specification carries no positions at all. It carries `cnt`, the number standing, and
`cand`, the value they share (`Majority.tla:26-27`). The comment there calls `cnt` a
lower bound on the candidate's occurrences, which is a different true fact about the
same number. The step relation reads those two
and the value at the current position, and nothing else (`Majority.tla:46-54`).

That works by taking rule 6 as given. Once you believe it, the walk can ask only two
things about the standing set. Its size and its value are all that matter, so those two
carry everything the next step needs. The set itself becomes unobservable, and an
unobservable thing doesn't have to be in the state.

The pick costs you the ability to say rules 4 and 5 at all. There's no pairing to
record, no position that changes status, and no way to ask whether a position took part
in two cancellations. Rule 6 isn't checked here. It's assumed, and the assumption is
what shrinks the state to two variables. If you built a model that can check rule 6, you
have a model that can answer a question this one can't be asked.

It buys a step relation with no choices in it. The three branches carry mutually exclusive
guards, so exactly one fires. My baseline run reports a maximum
outdegree of 1 over the whole state graph, and 2733 distinct states at length 5 over 3
values. It also buys a tractable proof. That's why `MajorityProof.tla` sits in this
directory, and why the inductive invariant at `Majority.tla:73-77` is short enough to
read.

Three other representations, and what each one gets you:

- A set of standing positions. Rule 6 turns into something you check.
- A bag of standing values. Rule 6 turns into a statement about the bag's support.
- A list of cancellation pairs. Rule 4 turns into something you check directly.

The set and the bag both make rule 5's open choice of partner into real nondeterminism,
which you then have to model and show is irrelevant. That's more work and it's also more
of the algorithm's actual content. The pair list is the only one of the four that can
express "no position takes part in more than one cancellation" as written. All three
cost state that grows with the sequence length rather than with the count.

I don't think any of these is the right answer. The counter is the smallest state that
supports the correctness statement the author wanted. A bigger representation is the
right answer for a different statement.

## The input is a variable that never changes

The sequence is one of the four variables (`Majority.tla:23-24`), and the comment above
the declaration says why (`Majority.tla:18-22`). The initial predicate leaves it free
(`Majority.tla:38`) and every step pins it (`Majority.tla:45`).

The alternative is a constant. Then one run covers one input, and the model checker
walks a single path with no branching anywhere. Traces get sharper, since the input
stops being part of what varies. Covering the same ground takes one run per sequence, or
a script that generates them.

Making it a variable costs an initial-state count that grows as fast as the input space.
At length 0 to 5 over 3 values that's 364 sequences and 1092 initial states. It buys a
sweep of all of them in one run.

## There's always a candidate, even before anything is read

Rule 6 says that when nothing is standing there's no candidate. This model has no way to
say that. The candidate belongs to the value set in the initial predicate and in the
type invariant (`Majority.tla:34`, `Majority.tla:40`). So it always holds some value.
"Nothing is standing" lives entirely in `cnt = 0`.

Two costs, and one of them is bigger than it looks.

The small one is the extra assumption at `Majority.tla:16` that the value set isn't
empty. Without it the initial predicate is unsatisfiable and the specification has no
behaviors.

The larger one is that the initial candidate is picked from the whole value set and
means nothing. Every non-empty sequence gets three initial states that differ only in a
value nothing has read. They merge after one step. That merge is the 726-state gap
between the 3459 states generated and the 2733 distinct ones in my baseline run. Two
thirds of the initial states are noise.

The alternative is a marker outside the value set, so that "no candidate" is a value the
candidate variable can hold. That costs a type invariant that has to admit the marker,
and every comparison against the candidate has to be safe when the marker is there. It
buys a state that says what it means, and it removes the two thirds.

## Three cases in one action

The step is a single action with three branches (`Majority.tla:43-54`). The end-of-walk
guard, the advance, and the pinning of the input are factored out above the branches, so
each branch carries only the candidate and the count.

The alternative is three named actions with a disjunction over them. Naming them costs
repetition of the three factored conjuncts, or a fourth definition to hold them.

What the fold costs shows up in traces. Every step in every counterexample I generated
is labelled with the line of the instantiation in the wrapper, not with a branch name. A
trace tells you the count went from 1 to 0. It doesn't tell you the cancel branch fired,
and you infer that from the numbers.

## The type invariant carries more than types

`TypeOK` at `Majority.tla:31-35` says four things, and two of them aren't typing. That
the position index stays within one past the end is a fact about the walk stopping. That
the count is a natural number is a fact about the guard on the cancel branch doing its
job, since the branch subtracts.

Folding them in buys one name to check and one name in a failure report. It costs the
distinction. When this breaks, the report names the type invariant, and you go looking
for which of the four conjuncts it was. Splitting the two behavioral facts out under
their own names is the other option, and it's what makes the model checker name the
specific fact.

## What the wrapper fixes that the algorithm leaves open

| the algorithm leaves open | the wrapper fixes it at |
|---|---|
| the value set, any non-empty set | three model values (`MCMajority.tla:10`) |
| all finite sequences | length 0 to 5 (`MCMajority.tla:11`, `MCMajority.cfg:7-8`) |
| terminal states | deadlock checking off (`MCMajority.cfg:15`) |

The bound arrives by replacing the library's sequence constructor from the config file
(`MCMajority.cfg:8`) rather than by editing the initial predicate. So `Majority.tla`
never mentions a bound and still reads as the algorithm. The alternative is a bounded
initial predicate in the wrapper module. That's shorter to write, and it puts a
model-checking number one module closer to the algorithm.

Deadlock checking is off since the walk's terminal states are the whole point. Leaving
it on would report every end-of-sequence state as a deadlock [INFERRED]. The other route
is an explicit self-loop at the end, which keeps deadlock checking meaningful at the
cost of a fourth branch that does nothing.

The wrapper declares no symmetry, and the three model values are permutable. I ran it
both ways. Adding the permutation set takes 2733 distinct states down to 466, and all
three obligations still pass. At this size the reduction buys nothing you'd notice.
Leaving it out means nobody has to argue the reduction is sound against what's being
checked. Both calls are defensible at 2733 states, and I'd want the option on the table
before the state count gets interesting.

## Correctness is a guarded invariant

The main property at `Majority.tla:69-71` is an implication. Its antecedent is "the walk
has passed the end", and the wrapper checks the whole thing as a state predicate
(`MCMajority.cfg:12`). In 2367 of the 2733 reachable states the antecedent is false and
the property holds for that reason alone. Only 366 states say anything.

The alternatives are a done flag with a liveness property, or a temporal formula. Either
one makes the reaching of the end part of what's checked. The guarded invariant declines
that and gets a safety check, which a model checker gets through more cheaply than a
liveness check [INFERRED].

There's a loose end that goes with the choice. The specification's behavior formula
carries a weak fairness conjunct (`Majority.tla:56`), and the config names no temporal
property. So fairness is declared and nothing consumes it. Termination is true here for
structural reasons and isn't checked anywhere.
