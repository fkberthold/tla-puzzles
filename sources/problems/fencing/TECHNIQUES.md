# What this problem exercises

Four techniques, read off the spike's models rather than predicted from the
statement. Each one names what a model that skipped it looks like, and what
skipping it costs.

State counts and exit codes come from this command, run from the repository root
on 2026-09-06:

```
bash harness/spike-measure.sh --dir sources/spikes/fencing --module <M> --budget 120 --label verify-<M>
```

## Choosing something the requirement can be stated about

The requirement in the statement's own English is about the moment of the write.
No state after the write carries the fact that the lease had lapsed, so there's
nothing later to look at.

The models get around that by keeping an ordered record of the accepted writes
(`Broken.tla:37`, `:96-99`), which turns the requirement into a claim about a
state. They also keep the literal wording, as a claim about a step
(`Broken.tla:106-108`), and check it separately.

**Skip it** and you're left with the claim about a step, checked over a model
with nothing recorded. That form works. It catches the bug in the broken system
at 34 states, reported with exit 13. The state form catches it at 62 states with
exit 12.

**What it costs** is the answer to the actual question. The step form is false
on the fenced system too, at the same 34 states and the same exit 13
(`MCFencedAction`, run above). A learner holding only that form concludes the
numbers changed nothing. Choosing what the model records is what buys you a
requirement that can tell the two systems apart.

## Deciding where one action ends

Getting the lease and writing are separate actions (`Broken.tla:63-71`,
`:74-78`), and the write is guarded only by the client's own state. Nothing in
either model represents the client pausing. The stall that causes the failure is
the interleaving between two actions, and TLA+ hands that over for nothing.

**Skip it** by folding the grant and the write into one step. No other component
can act in between, so the second client can never take the lease while the
first is mid-flight.

**What it costs** is a run that reports no violation and establishes nothing.
The spike has the same failure from a different cause, and measured it. With the
clock bound set to zero no lease can lapse, and the broken system comes back
clean at 5 states against 62 for the same module (`MCBrokenNoTick.cfg:5`, run
above, rc 0). The atomic-write version isn't built in the spike, so the shape of
its failure is INFERRED. I'd expect the output to read the same way. Clean, fast,
and worthless.

## Showing that a clean run isn't empty

The fenced module carries a claim that's meant to fail (`Fenced.tla:96-99`), and
one wrapper exists only to check it (`MCFencedWitness.cfg:7`). It fails at 60
states, rc 12, which is the evidence that two writes really do land.

**Skip it** and all you have left is the clean run itself, rc 0 at 74 states.

**What it costs** is your ability to tell that result apart from a storage
service that accepts nothing at all. A record that stays empty satisfies an
ordering requirement without doing any work, and the tool prints the same thing
either way. The no-tick control above is the same hazard from the other
direction, where a bound too small makes the bug unreachable. Between the two,
every clean run in this problem has a way of being clean for the wrong reason.

## Sizing a counter against the answer you want

The clock is bounded by a constant the config sets, and the tick action is
guarded by that bound (`Broken.tla:24`, `:81`). Sizing it is its own decision,
separate from whether to have a clock at all, which `CHOICES.md` covers.

**Skip it** by dropping the guard, which the spike also built.

**What it costs** depends on which answer you're after, and the split is sharp.
The broken system with an unbounded clock still returns its counterexample: 100
states, half a second, exit 12. The fenced one runs out a 120-second budget at
24,676,165 states and never answers (`measurements.tsv`, rows
`broken-clock-unbounded-2c` and `fenced-clock-unbounded-2c`). Search order is
why. Breadth-first reaches the bug at depth 7 and stops, while an absence has to
be shown everywhere. So an unbounded counter is free while you're hunting a
counterexample, and fatal the moment you want to prove there isn't one. I think
that asymmetry is the most transferable thing in the problem, since it holds
well outside this system.
