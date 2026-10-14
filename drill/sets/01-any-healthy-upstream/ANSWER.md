# Any healthy upstream: answer

## The answer

```tla
---- MODULE LbAnswer ----
CONSTANTS Upstreams, Ids

VARIABLES healthy, waiting, inflight

vars == <<healthy, waiting, inflight>>

InFlightIds == {p[1] : p \in inflight}

TypeOK ==
  /\ healthy \subseteq Upstreams
  /\ waiting \subseteq Ids
  /\ inflight \subseteq Ids \X Upstreams

Init ==
  /\ healthy \in SUBSET Upstreams
  /\ healthy /= {}
  /\ waiting = {}
  /\ inflight = {}

Arrive ==
  /\ \E r \in Ids \ (waiting \cup InFlightIds) :
       waiting' = waiting \cup {r}
  /\ UNCHANGED <<healthy, inflight>>

Forward ==
  /\ \E r \in waiting, u \in healthy :
       /\ waiting' = waiting \ {r}
       /\ inflight' = inflight \cup {<<r, u>>}
  /\ UNCHANGED healthy

Complete ==
  /\ \E p \in inflight : inflight' = inflight \ {p}
  /\ UNCHANGED <<healthy, waiting>>

Next == Arrive \/ Forward \/ Complete

Spec == Init /\ [][Next]_vars

OnlyHealthy == \A p \in inflight : p[2] \in healthy

NoDoubleBooking ==
  /\ waiting \cap InFlightIds = {}
  /\ \A p, q \in inflight : p[1] = q[1] => p = q

Claim == \A p, q \in inflight : p[2] = q[2]
====
```

```
SPECIFICATION Spec
CONSTANTS
  Upstreams = {u1, u2, u3}
  Ids = {r1, r2, r3}
INVARIANTS
  TypeOK
  OnlyHealthy
  NoDoubleBooking
  Claim
```

The health list is drawn from the powerset in `Init`, and the empty draw
is thrown out. In-flight requests are pairs, id and upstream. `Forward`
picks the upstream with an existential inside the action, and that's the
whole item: "any upstream on the list" is one branch per upstream, and TLC
follows every branch.

## What TLC should report for the claim

`Invariant Claim is violated.` with a trace of five states: two arrivals, a
forward to one upstream, a forward to another. The claim is false, and the
model says so at 190 distinct states.

## The trap, and why the item exists

There's another way to write "pick an upstream", and it reads better:

```tla
Forward ==
  /\ \E r \in waiting :
       LET u == CHOOSE x \in healthy : TRUE
       IN /\ waiting' = waiting \ {r}
          /\ inflight' = inflight \cup {<<r, u>>}
  /\ UNCHANGED healthy
```

It isn't a pick. The keyword names a value, and it's the same value every
time it's evaluated over the same set. The health list never changes, so
every forward in the whole run lands on the same upstream. The claim holds.
TLC reports nothing. The run finds 189 distinct states instead of 398, and
the colleague is confirmed by a model that can't disagree with him.

Two signals tell the two apart, and the prompt carries both. The count is
off by half. The claim comes back true when the description says it can't
be.

Where the keyword does belong is a lookup the state has already settled.
"The upstream a request is on" is one of those, since each in-flight id is
on exactly one:

```tla
On(r) == CHOOSE u \in Upstreams : <<r, u>> \in inflight
```

The rule of thumb I'd give: the existential when the system is deciding,
the keyword when the state already has.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/01-any-healthy-upstream`
on TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config
of its own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `LbAnswer` | rc 0 | 398 | the answer, two rules |
| `LbClaim` | rc 12 | 190 | the answer with the claim added. TLC refutes it |
| `LbChoose` | rc 0 | 189 | the trap with the claim added. TLC confirms it |
| `LbAnyUpstream` | rc 12 | 32 | forwards to any upstream at all. Rule 1 names it |
| `LbKeepWaiting` | rc 12 | 31 | forwards without leaving the waiting set. Rule 2 names it |
| `LbEmptyHealth` | rc 11 | 172 | the list may start empty, so the ids pile up. Config says `CHECK_DEADLOCK TRUE` |
| `LbSubseteqInit` | rc 0 | 398 | the subset relation in `Init` rather than a draw. Accepted, see below |

## Elimination table

| wrong neighbour | what kills it | rc |
|---|---|---|
| the upstream chosen with the keyword | the claim holds, 189 states | 0 |
| forward to any of the three | rule 1, first forward to a dead upstream | 12 |
| forward and keep the id waiting | rule 2, first forward | 12 |
| "at least one is" dropped from `Init` | deadlock once all three ids wait | 11 |
| the claim as rule 3, believed | the trace shows two upstreams | 12 |

## Variants

- the health list in `Init` as `healthy \subseteq Upstreams`, which TLC accepts
- the claim as `Cardinality({p[2] : p \in inflight}) <= 1`
- rule 1 as `{p[2] : p \in inflight} \subseteq healthy`
- `Arrive` and `Complete` merged, since completion returns the id anyway

The first one surprised me. I expected TLC to refuse a subset relation in
`Init`, since it's a sentence about a value TLC doesn't have yet. It takes
it as a draw from the powerset and finds the same 398 states. So the
misreading of the keyword as a subset test costs nothing here, and I've
recorded it as a variant rather than a defect.

## Why not in prompt

The prompt says "any upstream on the health list. Which one is not
specified." That's the existential in prose, and a reader who has made
the connection will never meet the trap. The item is for the reader whose
instinct for "pick one" is the keyword that picks a value, and the count
and the claim are there so that reader finds out on his own.

The honest caveat is about the claim. The prompt doesn't say it's false.
A reader who writes the trap sees the claim confirmed and 189 states, and
only the count tells him something is wrong, because he has no reason yet
to doubt the colleague. I think withholding the verdict is right, since
saying "TLC should refute this" hands over the shape of `Forward`. But it
means a reader who trusts the colleague can hand in the trap and feel
done, and the review has to catch it from the count.
