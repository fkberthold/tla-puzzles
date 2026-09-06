# Boyer-Moore majority vote

## The system

You're handed a finite sequence of values. At most one value can occupy a strict
majority of its positions, more than half of them, and plenty of sequences have
none at all. R.S. Boyer and J.S. Moore published an algorithm in 1981 that walks
such a sequence once, in order, and finishes holding the only value that could be
that majority.

It works by cancellation. Take two positions carrying different values and throw
both away. Whatever value held a strict majority of the whole sequence still holds
a strict majority of what's left. The pair took at most one position from it and at
least one from everybody else. So a value that survives every cancellation the walk
can make is the only value still in the running.

The walk does that one position at a time. Each position it reads either cancels
against something already read, or it stays standing. Everything left standing
carries the same value, and that value is the walk's candidate. When the sequence
runs out, the candidate is the answer.

The algorithm isn't a majority test. It says which value to check, not whether the
check passes. A sequence with no majority can leave the walk standing on a value
anyway, and that value is wrong. Settling it takes a second walk, and that second
walk isn't part of the system here.

## The rules

1. The sequence is fixed before the walk starts and doesn't change while it runs.
   It's finite, and it may be empty.

2. Nothing is known about the values except whether any two of them are equal.
   There's no ordering, no arithmetic, and no distinguished value.

3. The walk reads each position exactly once, in sequence order, and never returns
   to a position it has read.

4. Every position the walk has read is either cancelled or standing. A cancellation
   pairs exactly two read positions whose values differ. No position takes part in
   more than one cancellation, and a cancellation is never undone.

5. When the walk reads a position, that position's own fate is settled at once. It
   cancels if and only if some standing position carries a value different from its
   own, and otherwise it stands. A standing position can still be cancelled later,
   but only by being drawn as the partner of a position read after it. Which
   standing position gets drawn is left open, and rule 6 says why that choice makes
   no difference.

6. It follows that all standing positions carry one and the same value at every
   moment of the walk. When nothing is standing there's no candidate, and the rest
   of the walk behaves as though it were starting fresh on what remains.

7. When the walk reaches the end of the sequence, it reports the value left
   standing, or reports that it has no candidate.

8. If some value occupies a strict majority of the sequence's positions, that value
   is the one the walk reports. The converse fails. The walk can report a value that
   occupies no majority.

## What's out of scope

The second walk is out. The description this problem came from mentions a follow-up
pass that counts the candidate's occurrences and settles whether it really holds a
majority. Don't model that pass. Model the single walk above and nothing else.

Leaving it out is my call rather than the source's, and the reason is that a
counting pass is the easy half. With it in scope you could model the counting and
never touch the pairing, which is the part worth modelling.

Whether a majority exists is still yours to talk about. That's a fact about the
sequence you were handed, and stating it takes no walk at all. What's out of scope
is a second traversal, not the idea of a majority.

## What to produce

Write your own TLA+ model of this walk, and write whatever you think it takes to
establish that the walk is correct.

How you keep track of what's standing is the decision this problem is about, so
make it deliberately. Nothing above tells you, and nothing above should.

Afterwards you'll see one published specification of the same algorithm. Read it as
an example of a choice somebody made, not as the answer you were supposed to reach.

## Author notes

Not for the learner. This section records where the statement nearly leaked a
representation, and which rules I'm still unsure about.

Places I was tempted to name state:

| tempted to write | wrote instead |
|---|---|
| two integers and a candidate variable, straight from the README | cancelled and standing, as conditions on positions |
| the count drops to zero | when nothing is standing |
| the count goes up by one | it stays standing |
| the group of standing positions | standing kept as an adjective, so rules quantify over positions |
| index, cursor, pointer | in sequence order, which doesn't say what moves |
| the candidate variable | the value left standing, with candidate naming the value once |

The README's "two integer variables and one variable holding the current candidate"
never made it in. That sentence is the published implementation's state, and it's
the whole thing this problem is training the learner to choose for themselves. A
model can carry standing as a number, a set, a bag, or an explicit pairing.

Rules I'm unsure about:

Rule 8 is the headline guarantee, and stating it hands over one property the learner
would otherwise have had to find. I think it has to be there, because without it
"correct" has no content. What's left to find is still most of the work: the
standing-value invariant, the cancellation bookkeeping, and termination. So is
whatever they decide to say about the case where nothing stands.

Rule 6 is a consequence of rules 4 and 5 rather than an independent rule. I stated
it anyway, because rule 5 reads ambiguously without it and because it's the crux of
the algorithm. A learner may reasonably turn it into something they check rather
than something they assume, and I'd rather that than have them miss it.

Rule 4 says a cancellation pairs two positions. I think that's the mechanism rather
than a representation, since a model can record the pairing as a running difference
and never build a pair. It's still the sentence in the file closest to fixing a
structure. If a learner comes back having modelled a literal list of pairs and found
it painful, that's the one I'd rewrite first.

The second-pass boundary is a judgment call, and I said it twice on purpose. A
learner skimming the rules would otherwise add the counting pass without noticing
they'd been told not to.


Rule 5, repaired after the consistency check. The first draft opened "A position
cancels at the moment it's read, or never", which contradicts rule 4. On any sequence
whose second value differs from its first, position 1 stands when read and is cancelled
one step later as the partner of position 2. The word "cancels" was carrying a status
sense in rule 4 and an act sense in rule 5, and only the act reading made rule 5 true.
The published specification takes rule 4's side, decrementing its count at
`Majority.tla:52-54`. Rule 5 now scopes its claim to the arriving position and says
outright that a standing position can be drawn later. The learner's guess about which
sense was meant would have decided whether their model lets a standing position become
cancelled, which is a structural decision rather than a wording preference.

Provenance: I wrote this from the README paragraph in the brief plus my own
knowledge of the algorithm. I didn't look for a specification of it, and none was
in front of me.
