# Which pub: answer

## The answer

```tla
---- MODULE PubAnswer ----
EXTENDS Naturals, FiniteSets

CONSTANTS Friends, Pubs

VARIABLE votes

vars == <<votes>>

TypeOK == votes \subseteq Friends \X Pubs

Voted == {v[1] : v \in votes}

VotesFor(p) == {v \in votes : v[2] = p}

Committed(p) == 2 * Cardinality(VotesFor(p)) > Cardinality(Friends)

Init == votes = {}

Vote ==
  \E f \in Friends \ Voted, p \in Pubs :
    votes' = votes \cup {<<f, p>>}

Next == Vote

Spec == Init /\ [][Next]_vars

OneVoteEach == \A v, w \in votes : v[1] = w[1] => v = w

OnePubAtMost == \A p, q \in Pubs : Committed(p) /\ Committed(q) => p = q
====
```

```
SPECIFICATION Spec
CONSTANTS
  Friends = {f1, f2, f3, f4}
  Pubs = {p1, p2, p3}
CHECK_DEADLOCK FALSE
INVARIANTS
  TypeOK
  OneVoteEach
  OnePubAtMost
```

A vote is a pair, friend and pub, and the state is the set of votes cast so far.
`Voted` maps the set of votes down to the friends in it, so `Vote` can draw from
the friends who haven't gone yet. `VotesFor` keeps the part of the set that's
about one pub.

Both of those build a set from a set and they are not the same operation.
`Voted` is a map: it replaces each member with something derived from it, and the
result holds friends where the input held pairs. `VotesFor` is a filter: it keeps
members unchanged and drops the ones that fail the test, so the result still holds
pairs. The two differ by where the colon sits and by which side of it the bound
variable is on.

`CHECK_DEADLOCK FALSE` is in the config because all four friends having voted is
a terminal state and it's meant to be one.

The threshold is doubled rather than halved so it stays in whole numbers. More
than half of four is three, and two pubs can't both reach three out of four
friends, so `OnePubAtMost` holds for a reason rather than by accident. A run that
votes all four friends for one pub does test it.

## The trap, and why the item exists

Swap the filter for a map in `VotesFor` and nothing complains:

```tla
VotesFor(p) == {v[2] = p : v \in votes}       \* a set of TRUE and FALSE
VotesFor(p) == {v \in votes : v[2] = p}       \* a set of votes
```

The first one builds the set of answers to "is this vote for p", which has at most
two members whatever the votes are. So the count that goes into the threshold is
capped at 2, three is never reached, no pub is ever committed, and rule 2 holds
because it's never tested.

This is the item's whole point, and it's the reason the item exists rather than
leaving map and filter to `05-leases`. **The state count does not catch it.** The
trap explores all 256 distinct states, the same 256 the answer explores, because
the two modules differ only in an invariant that can't fail. The family's usual
tell is a count that comes in short, and here there isn't one.

## What the break-it step is for

So the prompt asks for the break-it step instead. Drop the threshold to half and
two pubs can each hold two votes out of four, and rule 2 reports it. A reader who
wrote the filter sees that after 181 states.

A reader who wrote the map also sees a violation, and this is where it gets
useful. At half, two is enough: a set of two truth values has two members, so
`2 * 2 >= 4` holds. The moment one friend votes for one pub and another friend
votes for a different one, both pubs read as committed. The violation lands after
17 states on a three-state trace:

```
State 2: votes = {<<f1, p1>>}
State 3: votes = {<<f1, p1>>, <<f2, p2>>}
```

Two votes, one each, and the model says two pubs are committed. That's the
diagnosis, and it's the trace rather than the count that carries it. 181 states
and a trace where each pub has two votes is the filter. 17 states and a trace
where each pub has one is the map.

**AMENDED 2026-10-14.** The header comment in `verify/PubMapTrap.tla` says the
opposite. It reads "Two votes never look like half of four, nobody is ever
committed, and the rule holds for the wrong reason", and the measurement is
rc 12 on 17 distinct states with `OnePubAtMost` violated. The arithmetic above is
why: at the half threshold, two truth values are enough and the map is loud. I've
left the module alone and corrected the comment, since the module's behaviour is
the artifact and the comment was a claim about it. The pairing is sharper than
the original note expected, because the same error is silent on one threshold and
loud on the other.

## Variants

- `OnePubAtMost` as `Cardinality({p \in Pubs : Committed(p)}) <= 1`
- `Voted` as a filter over the friends, `{f \in Friends : \E p \in Pubs : <<f, p>> \in votes}`
- the threshold as `Cardinality(VotesFor(p)) * 2 > Cardinality(Friends)`
- `Vote` drawing from every friend with `f \notin Voted` as a separate conjunct

The second one is the interesting variant, because it reaches the same set the
map was trying to reach and it's a filter over the friends rather than a map over
the votes. A reader who writes it has the distinction already.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/07-which-pub` on
TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config of its
own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `PubAnswer` | rc 0 | 256 | the answer, two rules |
| `PubMapTrapStrict` | rc 0 | 256 | the map for the filter. Silent, and the count matches |
| `PubHalf` | rc 12 | 181 | the break-it step, committed at half |
| `PubDoubleVote` | rc 12 | 17 | every friend votes again. Rule 1 names it |
| `PubMapTrap` | rc 12 | 17 | the map at the half threshold. Loud, for the wrong reason |

256 is 4 to the 4th, which is every assignment of four friends to three pubs or
to nobody. So the answer explores the whole reachable space and the three rc 12
rows stop early, which is what their counts are measuring.

## Elimination table

| wrong neighbour | what kills it | rc |
|---|---|---|
| the map where the filter was meant | nothing. 256 states, same as the answer | 0 |
| the same map at the half threshold | rule 2 after two votes, one per pub | 12 |
| committed at half rather than more than half | rule 2 after 181 states | 12 |
| the vote drawn from every friend | rule 1 on the second vote | 12 |
| the threshold as a halved count (not measured) | integer division, 4 over 2 is 2 | 0 |

The last row is the other arithmetic error I'd expect. Writing the threshold as
a division rather than a doubling puts it in whole numbers, so "more than half of
four" becomes "more than 2", and a pub with 3 of 4 is still committed. It happens
to be right here and it stops being right at an odd number of friends.

## Why not in prompt

The prompt says a pub is settled when more than half the friends have voted for
it, and it never says how to count the votes for one pub. That's the whole item.
Neither the map nor the filter is on the page, and the prompt doesn't say that
one of them is a trap.

The caveat is bigger here than on the other items in this family, and it's the
reason the break-it step is phrased the way it is. The state count can't foreclose
this one, so the prompt's 256 does nothing against the map. A reader who writes
the map gets a clean exit on the right count and has no reason to look further.
The break-it step is the only thing standing between him and a finished-looking
answer, and it only works if he reads the trace rather than the exit code. I'd
say that's the honest state of this item: the prompt can set up the measurement
that catches the trap, and it can't make anybody look at it.

I thought about naming the number of votes the reader should expect to see in
that trace, which would close the gap. It would also say that the count of votes
for a pub is the thing under test, and I think that gives away more than it buys.
