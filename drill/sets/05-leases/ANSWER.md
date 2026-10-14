# Leases: answer

## The answer

```tla
---- MODULE LeaseAnswer ----
EXTENDS Naturals, FiniteSets

CONSTANTS Clients, Resources, MaxHeld

VARIABLE leases

vars == <<leases>>

TypeOK == leases \subseteq Clients \X Resources

Leased == {l[2] : l \in leases}

HeldBy(c) == {l \in leases : l[1] = c}

Init == leases = {}

Grant ==
  \E c \in Clients, r \in Resources :
    /\ r \notin Leased
    /\ Cardinality(HeldBy(c)) < MaxHeld
    /\ leases' = leases \cup {<<c, r>>}

Release ==
  \E l \in leases : leases' = leases \ {l}

Next == Grant \/ Release

Spec == Init /\ [][Next]_vars

OneHolderPerResource == Cardinality(Leased) = Cardinality(leases)

WithinQuota == \A c \in Clients : Cardinality(HeldBy(c)) <= MaxHeld
====
```

```
SPECIFICATION Spec
CONSTANTS
  Clients = {c1, c2, c3}
  Resources = {r1, r2, r3}
  MaxHeld = 2
INVARIANTS
  TypeOK
  OneHolderPerResource
  WithinQuota
```

A lease is a pair, client then resource, and the state is the set of them.
The two helpers are the two brace forms, and they're the item.

`Leased` builds a new set out of the old one: the second half of every
pair. That's the map, `{e : x \in S}`, and the result is a set of
resources. `HeldBy(c)` keeps part of the old set: the pairs whose first
half is `c`. That's the filter, `{x \in S : P(x)}`, and the result is a
set of pairs. Rule 1 counts the projection against the pairs. The counts
agree only when no resource appears twice.

## What TLC should report after the break

`Invariant OneHolderPerResource is violated.` with a trace of three
states: two grants of the same resource to two clients. Measured at 11
distinct states.

## The two traps

Swap the brace forms and nothing complains.

`Leased` as a filter, `{l \in leases : l[2] \in Resources}`, is the set of
pairs again. The free check then asks whether a resource is one of the
pairs, which it never is, so every grant goes through. Rule 1 compares a
count with itself. The broken model runs clean at 343 distinct states, and
the only symptom is that 343 isn't 61.

`HeldBy(c)` as a map, `{l[1] = c : l \in leases}`, is a set of truth
values with at most two members. The quota check counts it, so it blocks
a client only when the set reaches two members, which has nothing to do
with how many leases the client holds. Rule 2 counts it too, and two is
never more than two. One client takes all three resources and the run is
clean at 64 states.

Both traps pass both rules. The count in the prompt is what catches them.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/05-leases` on
TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config of
its own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `LeaseAnswer` | rc 0 | 61 | the answer |
| `LeaseNoFreeCheck` | rc 12 | 11 | the break-it step. Rule 1 names it |
| `LeaseFilterTrap` | rc 0 | 343 | `Leased` as a filter. Guard and rule 1 both blind |
| `LeaseNoQuotaCheck` | rc 12 | 38 | `Grant` without the quota check. Rule 2 names it |
| `LeaseMapTrap` | rc 0 | 64 | `HeldBy` as a map. Guard and rule 2 both blind |

The 61 is 4 to the power 3, every resource free or held by one of three
clients, minus the 3 states where one client holds all three. The 343 is
7 to the power 3, every client holding any two or fewer of the three
resources with no check that they're free. The 64 is 4 to the power 3
with no quota at all.

## Elimination table

| wrong neighbour | what kills it | rc |
|---|---|---|
| free check dropped | rule 1, two grants of one resource | 12 |
| quota check dropped | rule 2, three grants to one client | 12 |
| `Leased` as a filter | nothing in TLC. 343 states against 61 | 0 |
| `HeldBy` as a map | nothing in TLC. 64 states against 61 | 0 |
| rule 1 as `\A l, m \in leases : l[2] = m[2] => l = m` | nothing, it's a variant | 0 |

## Variants

- rule 1 as `\A l, m \in leases : l[2] = m[2] => l = m`, measured in passing at 61
- `HeldBy(c)` as `{r \in Resources : <<c, r>> \in leases}`, a filter over resources
- the state as a function from resource to holder or a free marker, not measured

The second variant is worth a look. It's still a filter, over a different
set, and it returns resources rather than pairs. Either shape counts the
same.

## Why not in prompt

The prompt names two things the reader has to build, the leased resources
and a client's leases, and never says which brace form each one is. The
first is a projection and the second a selection, and the reader has to
retrieve that from the shape of the question rather than from a hint. The
break-it step is where the lesson lands, since the trap on rule 1 reports
nothing on the broken model, and the reader who wrote it has a clean run
and the wrong count.

The honest caveat: a reader who gets both forms right first time has done
a plain exercise, and the two traps only bite a reader who confuses them.
I don't know how common that confusion is for this reader. I'd guess it's
common enough on a blank page, because the two forms differ by where the
colon sits and nothing else.
