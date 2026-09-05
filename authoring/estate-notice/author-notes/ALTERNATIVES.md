# Alternatives considered (estate-notice reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

Three variables, `standing`, `notice` and `distributed`. `standing` maps a
creditor to one of six places. `notice` is `"open"` or `"closed"`.
`distributed` is a boolean. `Observe` renders as the identity over them, field
for field. The state is the interface.

## One stage variable instead of notice and distributed

The strongest rival. Carry `stage \in {"open", "closed", "distributed"}` and
drop the other two. The winding-up runs through those three in order and never
turns back, so one variable holds both facts and the one-way door falls out of
the shape.

I rejected it on the vector. This rung sits at representation 2, which asks
that the reference's variables be the `Observe` fields and nothing else.
`stage` is a fourth kind of thing that no field names, so shipping it moves the
rung to 3 and takes a level the ramp hasn't reached yet. There's a smaller
reason under that one. Folding the two facts together makes items 5 and 6 hold
by construction, and the two mutants I built for them would have had nowhere to
bite.

## Four sets of creditors

Keep `lodged`, `admitted`, `rejected` and `paid` as sets of creditors, with
nothing-lodged as the complement. Every obligation then reads as membership,
which I think a lot of readers find easier than a function into strings.

Rejected because a creditor can land in two of the four at once. The system
says he stands in one place, and I'd rather that be unrepresentable than be a
property I have to write. The description makes the same call for the same
reason, so this one wasn't close.

## A partition of Creditors into named sets

The honest version of the previous idea. Carry six sets, require them disjoint
and covering, then compute `standing` from them. Disjointness comes free from a
partition, so the one-place rule still costs no property.

I rejected it on the same clause of the vector. Six set variables aren't the
three `Observe` fields, so `standing` becomes a derived view and the reference
stops reading field for field. My hunch is it costs more than it buys anyway.
Six sets over two creditors is a lot of bookkeeping for a fact the function
form gets from its type.

## The notice as a boolean

`noticeOpen \in BOOLEAN` instead of a two-value string. It's shorter and it
saves a line in `TypeOK`.

I went with the strings because item 2 reads better. `Observe.notice =
"closed"` says what happened. The boolean says the same thing and makes the
reader carry a negation through the one obligation where the open case and the
closed case sit next to each other. Cheap call, and I could be talked out of
it.

## Amounts

No variable for what a creditor is owed and none for the size of the residue.
The system never asks how much, so an amount is state the interface can't show
and no obligation can constrain. It would take the instance out of space 0 and
buy nothing for it.

## Admitting and rejecting as two actions

`Admit(c)` and `Reject(c)` as separate operators, against the shipped
`Decide(c, d)` over a two-element set. The split reads a little closer to Rule
5, which names admitting and rejecting apart.

I kept the parameterized form because of where the fairness sits. Item 7 wants
a conjunct on deciding a named creditor's claim, and with the split that
conjunct becomes a disjunction of two actions. `DecideStep(c)` is one named
step, which is the shape `Bureau.tla` uses for its credit step. The description
asks for the four steps named one at a time, so I let that decide it.

## Fairness, and the blanket form

Blanket `WF_vars(Next)` would make item 7 true on its own. Every action here
disables itself for good and `Creditors` is finite, so the graph is a finite
DAG, and no terminal state holds the residue.

I shipped the four named conjuncts anyway. The blanket form obliges no step in
particular, and a learner who reads it takes away that liveness is something
you get by asking for it. The mutant that drops all four comes back rc=13 on
`TheEstateIsEventuallyDistributed`, so the obligation does lean on them.

## Quiescence

Nothing is enabled at the end of the story, so TLC calls it deadlock unless the
config says otherwise. The alternative is a stuttering action for the executor
once she's finished. I took `CHECK_DEADLOCK FALSE`, because inventing a step
this system doesn't have, to quiet a checker, puts a lie in the transition
relation.

## Coming forward after the distribution

Rule 8 lets a creditor who never lodged come forward once the residue has gone,
so `ComeForward` carries no guard on `distributed`. I checked that reading
against the arithmetic rather than trusting it. Barring the late step would cut
the distributed layer from four places per creditor to three, and the run came
back at 77 distinct states, which is the count the description works out with
the layer left open.
