# Answer: the database you didn't need

Files in `verify/`. `MVCC.tla` is the mechanism, with `MCMVCC.tla`
adding the cut. `SnapshotOracle.tla` is the two rules and
`OnCallOracle.tla` is the roster written against them. The oracle pair
is adapted from `sources/spikes/isolation/`, where this shape was first
measured.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.
The 405,673,796 is cited, not reproduced: `sources/README.md:110` and
`sources/spikes/isolation/REPORT.md:321`, from the published spec's own
README.

## Question 1: the cut at 4

Not safe, and the clean is wrong. Every begin and every commit moves
the counter by one, so with three doctors the violation (all three
committed off) sits at counter 6. The cut was `CONSTRAINT TsBound` with
`TsBound == ts <= MaxTs`:

| `MaxTs` | rc | distinct | depth |
|---|---|---|---|
| 4 | **0** | 280 | 8 |
| 5 | 12 | 460 | 9 |
| none | 12 | 462 | 10 |

At 5 the state with the counter at 6 is generated as a successor,
checked, found violating, and reported, which is how a constraint
works: it stops expansion, not checking (item 01 measures that). At 4
the state at 5 is dropped, so the one at 6 is never generated. TLC
explored 280 states of a system whose bug needs a sixth tick of a
counter it was told to ignore past four, and said clean.

The cut was reached for because the counter was growing. The counter
was growing because the model counts commits. The requirement doesn't.

## Question 2: the two lists

The requirement reads one thing: the committed roster, whether each
doctor is on or off.

The six variables hold: the counter, the version chain per row with a
stamp per version, the start stamp per transaction, the write set per
transaction, the lifecycle state per transaction, and the program
counter per transaction.

Cross off what the requirement never mentions: the counter, the chains,
the stamps, and the start stamps. What's left is the write set, the
state and the pc, plus the newest committed value per row. That's the
oracle's state, give or take a copy.

## Question 3: the two rules

A transaction reads the store as it stood when it began, plus its own
writes. A transaction commits only if nobody who committed after it
began wrote a row it writes.

`SnapshotOracle.tla` says that and nothing else. `snap[t]` is a copy of
the store taken at `Begin`, `prior[t]` is the set of transactions
already committed at `Begin`, and `NoConflict(t)` is a set
intersection over the write sets of everybody committed and not prior.

```
Begin(t) ==
    /\ state[t] = "init"
    /\ state' = [state EXCEPT ![t] = "running"]
    /\ snap' = [snap EXCEPT ![t] = store]
    /\ prior' = [prior EXCEPT ![t] = {u \in Txn : state[u] = "committed"}]
    /\ UNCHANGED <<store, wset>>

NoConflict(t) ==
    \A u \in Txn :
        (state[u] = "committed" /\ u \notin prior[t])
            => (DOMAIN wset[u] \cap DOMAIN wset[t] = {})
```

No version is ever created and no stamp is ever compared.

`OnCallOracle.tla` is the roster against that API: `Begin`, `See`,
`Put`, `Finish`. It mentions none of the isolation machinery, so it
runs unchanged against a serialisable oracle or a read-committed one
(the spike has both).

| doctors | mechanism | oracle | ratio |
|---|---|---|---|
| 2 | 29 | 21 | 1.4 |
| 3 | 462 | 173 | 2.7 |
| 4 | 13,683 | 2,421 | 5.7 |
| 5 | 637,658 | 50,885 | 12.5 |

Same verdict, rc 12, same depth at every size.

## Question 4: the ratio

It roughly doubles each step, so it isn't a constant factor you could
buy back with hardware. The mechanism's extra state is the version
chains and the stamps, and both grow with the number of commits, which
grows with the number of doctors. The oracle's extra state is one
snapshot per transaction, which doesn't.

The 405 million is what the published model pays for being a model of
an engine rather than of an application: 619 lines, 58 definitions,
garbage collection, the lot (`sources/README.md:109`). It finds a
read-only anomaly at depth 13 in 64 minutes. The oracle finds write
skew at depth 7 in half a second. Those aren't the same anomaly, and
I'd not claim the oracle replaces the engine model for every question.
What I'd claim is narrower: for a requirement about what an application
sees, the engine's internals are state the requirement never reads, and
state the requirement never reads is what blows up.

The knob was the wrong move because the thing it bounded was the thing
that shouldn't have been there. Item 01 and item 06 have the same shape
with a clock and a counter. Here it's a whole database.

## Variants worth running

Change the application to lost update (two transactions each increment
a counter) and it passes under snapshot isolation. Change it to read
skew and it passes too. Write skew is the one anomaly snapshot
isolation permits that read committed also permits, so it can't show
the ladder on its own (`sources/README.md:131`).

Add a fourth doctor to the cut config with `MaxTs = 6`. The violation
needs 8, so it's clean again, and that's the same false clean one size
up.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G08Engine3.tla` | rc 12 | 462 | `Mechanism3.cfg`, the mechanism at three doctors, 462 states |
| `G08EngineCut4.tla` | rc 0 | 280 | `Mechanism3Ts4.cfg`, the counter cut at 4, the false clean |
| `G08EngineCut5.tla` | rc 12 | 460 | `Mechanism3Ts5.cfg`, the counter cut at 5, the anomaly generated and checked |
| `G08Rules2.tla` | rc 12 | 21 | `Oracle2.cfg`, the two rules at two doctors, 21 states |
| `G08Rules4.tla` | rc 12 | 2421 | `Oracle4.cfg`, the two rules at four doctors, 2,421 states |

## why-not-in-prompt

The prompt says the colleague's model "has no database in it", and
gives its numbers. That tells the reader the answer exists, that it's
smaller, and roughly what shape it has. I couldn't set the item without
it, because a reader who's only seen the mechanism model has no reason
to think the database is optional. The spike report that measured this
says the same: deleting the mechanism is the insight, and you can't
have the insight before you've paid for the thing.

What the prompt withholds: the two rules, that a snapshot is a copy of
a function and a conflict is a set intersection, where the violation
sits on the counter, that the cut checks states it won't expand, and
that the ratio grows. Question 1 says "in terms of the counter", which
points at the arithmetic.

The honest caveat: question 3 asks for the rules "without mentioning
versions or timestamps", which is a strong hint about what to delete.
I left it in because without it the reader is likely to write a smaller
mechanism rather than no mechanism, and the item is about the second
move.
