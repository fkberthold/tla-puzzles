# Answer: liveness at the fence

Files in `verify/`. `Retransmit.tla` is the sender with the counter.
`MCRetransmit.tla` adds the cut and the give-up variant.
`RetransmitNoCounter.tla` is question 4.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.

## Question 1: what the clean verdict rests on

The cut is `CONSTRAINT AttemptsBound` with `AttemptsBound == attempts <=
MaxAttempts`. TLC generates the successor of the state with three
attempts and nothing in flight, sees the counter at 4, and drops it. So
that state has no successor in the graph TLC checks. It's a dead end
that the real system doesn't have.

For liveness, TLC treats a dead end as a state the behaviour stutters in
forever. Whether that stutter is a counterexample depends on the
fairness conjuncts. `Send` is enabled in that state (TLC evaluates
`ENABLED` on the spec, not on the cut graph), and the spec has
`WF_vars(Send)`, so a behaviour that sits there forever violates the
sender's fairness. It isn't a behaviour of the spec, and TLC doesn't
count it. No other dead end exists, so rc 0 at 10 states.

I'd ship it, and I'd say why. The verdict is right for the uncut system
as far as I can tell: with the sender weakly fair and delivery strongly
fair, the message gets through. What it rests on is that every dead end
the cut creates has a weakly fair action enabled in it. That's a fact
about this spec's fairness formula, not about constraints. Change the
formula and the same ten states give a different answer, which is row
three.

I tried to make the cut produce a wrong liveness verdict on this system
and couldn't, in the time I had. I'm not claiming one doesn't exist for
some other system. INFERRED: a cut whose dead end has no fair action
enabled in it would report a stutter there as a violation, whether or
not the real system moves on. The rule I'd carry is that a liveness
verdict under a constraint is a verdict about the fairness at the fence,
and it needs checking by hand every time.

## Question 2: row three

Real. `SpecNoSenderFairness` drops `WF_vars(Send)`, and the
counterexample is the initial state followed by stuttering: the sender
never sends. That's a behaviour of the uncut system too. TLC found the
same one on the uncut run, because it checks liveness on the graph so
far at intervals: `UnboundedNoSenderFairness.cfg` exits 13 after about
4 s with the identical trace. The state count at that point was
1,522,231 on one run and 1,989,973 on the next, since it depends on when
the interval fires. The cut didn't invent
this violation. It made it affordable.

## Question 3: row four

Real for the system it checks. `BoundedSpec` has `BoundedSend == Send /\
attempts < MaxAttempts`, so after three drops the sender stops, nothing
is enabled, and the behaviour stutters with `acked = FALSE`. A sender
that gives up can fail to deliver. That's the system now, so the
requirement has to say so:

```
AckedOrGaveUp == <>(acked \/ attempts = MaxAttempts)
```

`SpecBoundWeakened.cfg` exits 0 at 10 states. Whether a weaker claim is
the one you wanted is a question about the product, not the model.

## Question 4: delete the counter

Nothing reads it, so it's a variable whose only effect is to make the
graph infinite. `RetransmitNoCounter.tla` has two variables and four
reachable states, three distinct after the initial:

| run | rc | distinct | depth | wall |
|---|---|---|---|---|
| no counter, both fairness conjuncts | 0 | 3 | 3 | 0.3 s |
| no counter, sender's fairness dropped | 13 | 3 | 3 | 0.3 s |

Both verdicts are about the whole system, with no fence to reason about.
The clock in item 01 had the same shape: a number the decision never
read, bounding something that didn't need to exist.

## The whole table

| run | spec | rc | distinct | depth | wall |
|---|---|---|---|---|---|
| uncut | `Spec` | 124 | 1,563,059 at 30 s | | 30.2 s |
| cut at 3 | `Spec` | 0 | 10 | 7 | 0.4 s |
| cut at 3 | `SpecNoSenderFairness` | 13 | 10 | 7 | 0.3 s |
| uncut | `SpecNoSenderFairness` | 13 | 1,522,231 | | 3.8 s |
| gives up at 3 | `BoundedSpec` | 13 | 10 | 7 | 0.4 s |
| gives up at 3, weakened claim | `BoundedSpec` | 0 | 10 | 7 | 0.3 s |
| no counter | `Spec` | 0 | 3 | 3 | 0.3 s |
| no counter | `SpecNoSenderFairness` | 13 | 3 | 3 | 0.3 s |

## Variants worth running

Change `SF_vars(Deliver)` to `WF_vars(Deliver)`. The requirement is now
false on the real system, since the link can drop every time and
delivery is never continuously enabled. The counterless model reports
it at 3 states. The cut model reports it at 10. The uncut model never
finishes.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G06Cut.tla` | rc 0 | 10 | `Constraint.cfg`, the cut at 3 with both fairness conjuncts |
| `G06UnfairCut.tla` | rc 13 | 10 | `ConstraintNoSenderFairness.cfg`, the cut with the sender's fairness dropped |
| `G06GivesUp.tla` | rc 13 | 10 | `SpecBound.cfg`, the sender that gives up, original claim |
| `G06WeakGivesUp.tla` | rc 0 | 10 | `SpecBoundWeakened.cfg`, the sender that gives up, honest claim |
| `G06Lean.tla` | rc 0 | 3 | `NoCounter.cfg`, the counter deleted |
| `G06UnfairLean.tla` | rc 13 | 3 | `NoCounterNoSenderFairness.cfg`, the counter deleted, sender's fairness dropped |

## why-not-in-prompt

The prompt describes the cut in prose and says the counter is read by
nothing. The second of those is question 4's answer. I left it in
because a reader who has to discover that the counter is unread has to
read the module, and there's no module. It's the one fact about the
system the prompt can't withhold without withholding the system.

What the prompt withholds: the keyword, what TLC does at a dead end,
that `ENABLED` is evaluated on the spec and not the cut graph, that the
uncut run finds the same stutter by its periodic check, and the weakened
claim's shape. Question 1 does say to think about "what TLC does with a
state it isn't allowed to expand", which points at the mechanism. This
is the cold item, so I kept that pointer short.

The honest caveat on the whole item: on this system every verdict under
the cut was right, and the lesson is why, not that it was wrong. I'd
rather teach a correct verdict with a fragile reason than invent a
wrong one I couldn't measure.
