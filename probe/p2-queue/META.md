# p2-queue, the item record

Withheld from every delivery route, the same way a drill item's `ANSWER.md`
and `verify/` are. Do not read this before attempting the item.

## The system

A bounded blocking queue whose implementation splits one wait set into two,
one per kind of thread.

| field | value |
|---|---|
| requirement module | `BlockingQueue.tla` |
| requirement source | `lemmy/BlockingQueue` |
| pinned commit | `68715979666344cbcc66fa621b27039f281bdd5c` |
| licence | MIT |
| published answer | `BlockingQueueSplit.tla` |
| grading model | `Producers = {p1, p2}`, `Consumers = {c1, c2}`, `BufCapacity = 1` |
| abstract init | `Init`, the grader's default |
| abstract spec | `Spec` |

The pinned commit is the one `corpus/manifest.tsv` and
`.claude/rules/tla-practice.md` both record for this repository, so this item
reads the same snapshot the corpus survey read.

## The decision the brief forces

Requirement 3 says a producer that adds an entry hands off to a sleeping
consumer, singular. Requirement 6 says no sleeping consumer stays asleep while
the queue holds an entry, which pushes the other way.

- **One thread per hand-off.** `waitSetC' = waitSetC \ {t}` for some `t`. This
  one refines.
- **Every sleeping consumer wakes.** `waitSetC' = {}`. This one does not.

`BlockingQueue`'s `NotifyOther` removes at most one thread from the wait set.
So a step that removes two is a step the requirement has no counterpart for.
It takes two sleeping consumers at once to see it, which is why the grading
model carries two consumers and a capacity of one. At one consumer both
readings pass and the item would measure nothing.

This is `notify` against `notifyAll` in Java, and the requirement module's
comment points at `java.lang.Object#wait` itself.

## Expected verdicts

| module | verdict | exit |
|---|---|---|
| `verify/SplitWaitSets.tla` | `REFINES` | 0 |
| `verify/WrongNotifyAll.tla` | `REFINEMENT_VIOLATED` | 22 |

## How this item differs from a drill item

Named on Barnett & Ceci 2002 dimensions, which do not combine into one scalar,
so each one stands on its own.

- **Modality**: 936 words, no state count, no construct list.
- **Functional context**: framed as a replacement under review.
- **Memory demands**: two machines, `BlockingQueue`'s and his own.
- **Ill-structured**: four bounds the prose leaves open, and the pair above.

## Why this item is the stronger of the two on the mapping

The mapping here is `waitSet <- (waitSetP \cup waitSetC)`, which is a derived
state function rather than a renaming. He has to notice that his state and the
requirement's state are different shapes, and that the two wait sets are
disjoint because no thread is both a producer and a consumer. p1-commit's
mapping is close to an identity, so if only one item survives, keep this one.

## The one thing the prose has to give away, and why

The requirement module's `buffer` is a sequence of producer identities, and
its `Next` reads `\E p \in Producers : Put(p, p)`. So the datum a producer
appends has to be the producer itself. A submission that appends anything else
cannot refine, however well written it is, so the brief states it and points
at the module. That is a fair giveaway rather than a hint: reading the
requirement module carefully is the skill, and the brief is telling him where
to look rather than what he will find.
