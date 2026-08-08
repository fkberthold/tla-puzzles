# Alternatives considered (qsl reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

Two variables, `filed` and `credited`. Each maps an operator to a set of
`[station, band]` records. `Observe` renders as the identity over them, field
for field. The state is the interface.

## Credit as one set of pair-facts

The strongest rival. Drop per-operator credit and keep one set of facts, each
an unordered pair of operators plus a band. Mutuality then holds by
construction, and no action can break it.

I rejected it for two reasons. First, `Observe.credited` would need a
per-operator projection, and I wanted the observation operator to read as a
plain record over state, not as a derived view. Second, a representation where
mutuality can't break makes `CreditIsMutual` unfalsifiable inside the model,
and my mutant probe on the credit action leaned on breaking it. The handoff
says the properties don't care which fact the model maintains, so I think this
is a legibility call, not a correctness call.

## A flat claims relation

One variable holding `[owner, station, band]` triples, with an operator's file
as a selection by owner. Rejected because item 4 ("changes exactly one
operator's file") and the `filed` rendering both want the per-owner partition.
The function form gives the partition for free. The relation form re-derives
it inside every obligation that mentions a file.

## Tuples for claims

`<<station, band>>` pairs instead of records. Records won because `f.station`
reads at the interface without positional decoding. Cheap call.

## Envelope shape

Rule 2 lands a multi-claim envelope as one step, so single-claim mail was out
from the start. `Mail` draws from the nonempty powerset of the operator's
claim space. I excluded the empty envelope because under `Observe` it's
stutter, and it buys nothing but self-loop edges. An envelope of claims
already on file stays possible and stays harmless (the file records that a
claim stands, not how often it arrived).

## Fairness

Two candidates for Rule 5. WF on the existential credit step, or per-fact WF
quantified over pairs and bands. The existential form is the weaker
assumption, and it suffices here: facts are finite and credit is permanent, so
an endless run of credit steps can't dodge one pending fact forever. I think
the weaker form is also the truer reading of the charter. The bureau owes
work, not any particular order. Mutant C in my probes drops the WF conjunct
and `BureauKeepsUp` fails, so the obligation does lean on it.

## The a # c guard in CreditComesWhole

Without it, a one-sided self-credit step can satisfy the obligation through a
witness with `a = c`, where the two per-side conditions collapse onto one
operator. `CreditIsCorroborated` would still catch that step, since a
self-claim never reaches a file. I'd rather the step obligation stand on its
own than lean on a neighbor. One conjunct buys that.

## Station logs and truth

No variable for either. Private logging is stutter under `Observe`, and the
register never learns whether a claim describes a real contact. Modeling
either would add state the interface can't show.
