# Techniques this problem exercises

Four of them, read off the published specification rather than guessed from the
statement. Each one is a technique the author used here. Numbers below came from
model-checker runs, listed with their commands and exit codes at the end of the
consistency note. The problem forces none of them. So each one carries its
counterfactual out loud: how a model that skipped it looks, and what skipping it costs.

## Turning the input into part of the state

The input sequence sits among the declared variables (`Majority.tla:23-24`). The comment
above the declaration says the author did it to get one run over all inputs
(`Majority.tla:18-22`). The initial predicate leaves it free (`Majority.tla:38`) and
every step holds it fixed (`Majority.tla:45`).

This is a general move. Anything a system takes as given can be lifted into the state,
left unconstrained at the start, and frozen thereafter. The checker then sweeps the
whole input space in one run, and the sweep is exhaustive over whatever bound you put on
the lifting.

Without it, the input is a parameter and a run covers one value of it. The state graph
becomes a single path. Traces get easier to read, since the input is no longer one of
the things that varies between states. The cost is coverage. 364 inputs takes 364 runs
or a harness that drives them, and nothing in the model says those were the right 364.
The published form pays for the sweep in initial states, which grow as fast as the input
space does.

## Replacing a collection with a summary of it

The set of standing positions never appears. Two variables stand in for it: how many are
standing and what value they share (`Majority.tla:26-27`). The step relation reads only
those two and the value at the current position (`Majority.tla:46-54`).

The technique is to find the part of a structure the system actually looks at, and carry
only that. It's sound as long as the discarded part can't affect a future step. Here it
can't, since the algorithm never asks which positions are standing.

A model that carries the collection can say things the summary can't. It can state the
uniformity of standing values as something checked rather than assumed. It can also
state the pairing constraints from rules 4 and 5, which the summary can't express. It
also gains a real choice at each cancellation, namely which standing position to pair
with. My run of the published model reports a maximum outdegree of 1 across the state
graph. The summary bought a step relation with no branching in it. The collection gives
that up and replaces it with an obligation to show the choice doesn't matter.

I think that trade is the whole content of this problem. The summary is smaller and says
less. Neither half of that is a defect.

## Carrying a strengthening alongside the property you care about

The module defines a second, stronger invariant next to the correctness statement
(`Majority.tla:73-77`), and the wrapper hands both to the checker
(`MCMajority.cfg:10-13`). The strengthening isn't a requirement anybody asked for. It
exists to be inductive, and the proof module consumes it at that point
(`MajorityProof.tla:64`). The proof itself is out of scope for this project.

Checking a strengthening you don't need is worth doing for two reasons. It fails at the
step where the reasoning breaks, not at the end state where the symptom shows. So a
counterexample points at a cause. And it's the artifact that carries over if you later
want a proof, since a model checker's verdict doesn't.

A model that checks only the correctness statement gets the same verdict at this bound.
[INFERRED: dropping an invariant that passes can't turn a pass into a failure.] It loses
the localisation and the portability. It saves the work of finding the strengthening,
and that work is most of the work of the proof. Skipping it is the reasonable default
for a model you only intend to check.

## Bounding an infinite domain from outside the module

The algorithm ranges over all finite sequences (`Majority.tla:32`, `Majority.tla:38`),
which no checker can enumerate. The wrapper defines a bounded replacement
(`MCMajority.tla:11`) and swaps it in from the configuration file (`MCMajority.cfg:8`).
The substitution happens at check time, and `Majority.tla` never learns about it.

The general move is to write the module at the altitude it belongs at. Push every
finiteness compromise into a layer the module doesn't import. It keeps one artifact
honest about what the algorithm is.

Writing the bound straight into the initial predicate gets you the same run and the same
numbers. It costs the separation. The module then carries a model-checking constant, so
it stops reading as the algorithm. Anything you later prove about it inherits the bound.
The published split costs a second module and a line of configuration.
