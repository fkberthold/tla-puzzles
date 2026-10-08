# No refutation traces, and the reason is a fact about the problem

This package ships no trace pairs. That is deliberate and it is not a gap in the
authoring. Two routes were tried and both were measured rather than argued.

## Requirement 1 cannot have a violating trace

A trace pair only catches a wrong property if its forbidden run reaches the state
that property is about. Here the allowed run needs a row with an applicant at
`"inspecting"` carrying an entry on the defect list, and requirement 1 forbids
exactly that row.

Measured: the allowed run built from rules 2 to 5, replayed one row per state with
requirement 1 declared as an `INVARIANT`, gives

```
Error: Invariant Requirement1 is violated
State 3:  inspecting / 1 / FALSE
rc = 12
```

So any allowed run authored to satisfy all nine requirements is a run of the
collapsed system, where the office gives up on its first failed query. The pairs
would certify the wedge instead of catching it.

## Inverting the pairs leaks the answer

The second route was to make the pairs about the collapse, with the collapsed
system as the forbidden run and a system that turns the retry loop as the allowed
one. That leaks both halves. Marking the loop-turning run allowed tells the reader
requirement 1 is the one to drop. Marking the collapse forbidden tells them the
collapse is wrong. Either one hands over the resolution this problem exists to make
the reader find.

## What carries the weight instead

The tenth formula in "What to deliver". Every one of the nine requirements is an
upper bound, and a system where nothing happens satisfies every upper bound there
is, so none of the nine asks whether the office ever goes back. The tenth asks.

Note what it does and does not do, because the difference was measured. A reader
whose model collapses the give-up into the error write still produces all three
artifacts and nothing rejects them: the nine hold at `rc 0` over 16 distinct states
at depth 5, and the probe holds too. The tenth formula does not make a wrong answer
fail. It makes a wrong answer **say so**, because the collapsed reader's own
submission has to carry the sentence that their office never goes back.

Rejecting that submission is a grader question rather than a statement question. No
model both satisfies the nine and refutes the probe, so a statement that demanded a
refutation would be demanding something unsolvable, and would announce the answer
by demanding it.

## One thing not to change without re-running both models

The probe's pin is load-bearing. Pinned to a second entry appearing on the defect
list, a known mutant refutes it at `rc 12` while satisfying all nine at `rc 0` with
the loop never turning, so that pin passes a wrong model. Pinned to the revisit, it
holds on the collapse and on that mutant, and is refuted only on the faithful
reading.

## Lineage

Bead `tla-pmm2.3`. Step 5 report at `../../reports/step5-consistency.md`. The
pattern this package is the hardest instance of is bead `tla-n8oq`.
