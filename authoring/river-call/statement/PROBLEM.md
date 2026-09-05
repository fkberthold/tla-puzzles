# A call on the river

A modeling problem, then a diagnosis. Plan on 20 to 40 minutes if you've
read the learntla core chapters.

Water law across the American west runs on prior appropriation. A right to
take water out of a stream is a decree, and a decree carries an amount and
the date the right was first put to use. When the stream is short, the rule
is first in time, first in right. The older date takes its full amount and
the younger one goes without. That order is fixed long before anybody opens
a gate.

You don't need any water law beyond what's written here.

## What you get

- This statement. It fixes the system and the four things you must check.
- `traces/`: three pairs of runs. One run of each pair follows the rules
  and one breaks them.
- `RiverCall.cfg`: a config, and a run somebody already made with it.

No spec ships. The model is yours to write.

## Your task

1. Model the stretch of river below, in PlusCal or TLA+, in a module named
   `RiverCall`.
2. Define `Observe`, the operator described under the interface.
3. Write the four requirements as formulas over `Observe`, declare them in
   a `.cfg`, and run TLC on the checking instance until all four hold.
4. Hold your model against the traces. Every forbidden run must break at
   least one requirement. Every allowed run must be a run your model can
   produce.
5. Then read the last section and answer its two questions in writing.

## The system

**The parties.** One kind, and several of them. A fixed, finite set of
ditch owners, named by `Owners`. Each owns a headgate on the same stretch
of stream and turns their own wheel. Nothing else acts. There's no clock,
no season, no weather, and no official.

Nothing coordinates the owners. Any owner's act can land between any two
acts of another.

### Rule 1. The stream

One stream runs past every headgate on the stretch. It carries a fixed
amount of water, `Flow`, counted in whole units. That amount never changes.
A dry year and a wet year are two instances of this system, not two moments
in one.

### Rule 2. The register

Each owner holds one decree. A decree names an amount, `Decree`, in the
same whole units as the flow, and a priority date. The decrees sit on a
public register every owner can read. Each owner has one fixed priority
date and no two owners share one, so the register puts the owners in one
order with no ties. An owner is senior to another when their date is the
older of the two, and junior when it's the younger. Nothing in this system
ever changes a decree, a date, or the order.

### Rule 3. The headgate

Each owner sets their own headgate, and only their own. A setting is a
whole number of units, from shut up to that owner's decreed amount. An
owner can move their own gate up or down at any time, in one act, to any
setting in that range. Nobody else touches it and nobody asks first.

### Rule 4. The stream can't give what it hasn't got

The settings never total more than the flow. A setting and the water
actually running are the same thing here, because an owner checks what the
others are taking before they open. Water that isn't going down a ditch
stays in the stream.

### Rule 5. Short

An owner is short when the water they could take right now falls under
their decreed amount. Count it this way: what they're already taking, plus
the water nobody is taking, against their amount. So an owner who could
open up to their full decree out of the water sitting free in the stream
isn't short, whatever their gate reads at the moment. An owner who couldn't
is.

### Rule 6. The call

A short owner can put a call on the river. A call is a notice, not a
request, and nobody answers it. Only a short owner can put one out. It
stands until the owner who put it out takes it back, and they can take it
back whenever they like, short or not.

### Rule 7. What a call does

While a call stands, no owner junior to the caller opens their gate any
wider than it already is. That's the whole of it. A call reaches what a
junior may newly take, and it doesn't reach a gate that's already open. It
reaches a junior's rise if it was standing when the rise began, whatever
happens to the call in the same act. Nobody senior to the caller is
touched, and neither is the caller.

### Rule 8. Nobody enforces anything

There's no watermaster on this stretch. Every owner reads the same register
and applies the rule to themselves. Nobody grants water, nobody waits for a
grant, and nobody can shut another owner's gate. First in time, first in
right settles who may open. Who got to the wheel first settles who keeps
the water already running.

### Rule 9. Nothing has to happen

No owner is under any obligation. An owner can leave a gate shut forever,
leave it open forever, leave a call standing forever, or never call at all.
Nothing in this system must eventually happen.

### Rule 10. The opening

Every gate starts shut and no call stands.

## The interface

Your model defines one operator, `Observe`, a record with two fields.
Grading reads `Observe` and nothing else. Your variables never leave your
module. Pick whatever state you like, in whatever shape you like, and
render these two facts from it.

- **diverted**: for each owner, how much water is going down their ditch
  right now.
- **calling**: for each owner, whether a call of theirs stands on the river
  right now.

The shapes are fixed, because grading compares values:

- `Observe.diverted` is a function from owners to whole numbers.
- `Observe.calling` is a function from owners to `BOOLEAN`.

There's no marker for absent or unknown in either field. A shut gate reads
zero, and an owner with no call standing reads `FALSE`. A string sitting
beside a number in one of these fields will stop TLC dead.

Shortness is not a field, and that's deliberate. Work it out from
`diverted`, the flow and the decrees wherever you need it. Expose it and
requirement 4 below grades your model against your model's own idea of
shortness, so a model that reads rule 5 wrong and reports it consistently
passes. Keeping it out ties your properties to the constants as well as to
the fields. Expect that rather than reaching for a third field.

## What must be true

Four requirements. Each one names the TLC keyword it goes under and the
kind of formula it is, so no part of that is left for you to work out. They
must hold for any owner set, any decrees, and any flow.

1. **The gates are well formed.** At every moment each owner's setting is a
   whole number from zero up to that owner's own decreed amount, and each
   owner's call is a yes or a no. `INVARIANT`, a state predicate.
2. **The flow holds.** At every moment the owners' settings total no more
   than the flow. `INVARIANT`, a state predicate.
3. **Nobody opens against a call.** At a step where an owner's setting
   rises, no owner senior to them had a call standing in the state the step
   ran from. `PROPERTY`, an action property, subscripted over the whole of
   `Observe`.
4. **A call is honest.** At a step where an owner's call goes out, that
   owner was short in the state the step ran from. `PROPERTY`, an action
   property, subscripted over the whole of `Observe`.

Four is the whole list. Don't add a fifth.

Requirement 1 is your model's own typing rather than a rule about the
river, and it still gets a real check line of its own. A stated range over
a number grades nothing until something checks it.

Requirements 3 and 4 are step rules and not claims about single states, and
for 3 that's forced rather than chosen. A senior's own lawful act can leave
a junior's standing setting out of priority, and nothing in this system can
shut the junior's gate. So "no junior takes water while a senior is
calling" is not something any model of this system can hold as an
invariant. Water already running out of priority is a legal standing state
here, and rule 8's second sentence is what makes it one.

The subscript on 3 and 4 is the whole record, never one field of it.
Subscript 4 on the settings alone and a step that only moves a call slips
out of the property's reach, which is the one step 4 exists to catch. TLC
won't warn you. The property just stops seeing the steps it was written
about.

Two of the rules above go ungraded, and I'd rather name them than let you
hunt. `Observe` shows the stretch, not the hands on it. Whose act moved a
gate is invisible at this interface, so rule 3's "each owner sets only
their own" can't be a property of any model, whatever fields you add. Rule
8 is the same fact from the other end.

## The traces

The `traces/` directory holds one pair per requirement past the first. Each
state shows the two `Observe` fields, written owner by owner.

- **A run the river can produce.** Your model must allow it.
- **A run that breaks a requirement.** Your model must rule it out.

Each row of a trace is one moment. Consecutive rows are one step apart.
Every run shown is finite. A forbidden run can break more than one
requirement, and if your set rejects it for any rule it breaks, your set is
right about that run.

The well-formedness requirement gets no pair. It's your model's own typing
rather than a rule about the river.

## Checking

The checking instance is three owners, each decreed 2 units, on a flow of
3. The owners are named 1, 2 and 3, and the name is the priority date, so
owner 1 is the most senior and owner 3 the most junior.

Three owners is the least that does any work. Two give a chain with one
senior and one junior, and each of them sits at an end of it. Three give a
middle owner who's senior to one and junior to another, which is where
requirement 3's two quantifiers earn their place. A flow of 3 against
decrees totalling 6 puts the stream under the paper right, so shortage is
reachable. A decree of 2 rather than 1 matters too. At 1 a gate is open or
shut, and a rise collapses into an opening.

TLC's config format won't take a function written out, so `Decree` needs an
operator in your module to point at. Define one called `Decrees` that gives
every owner 2, and set the constant with `Decree <- Decrees`. The config
shipped with this problem uses that name.

Leave deadlock checking on. Some owner can always move on this stretch,
because a fall is legal from any setting and the most senior owner has
nobody above them to call. A deadlock report means your model has closed
off a move the rules allow.

A model that carries these two facts and nothing else finds 136 distinct
states here, and the search runs in well under a second. Carry extra
bookkeeping and your own count can come out higher, so treat 136 as the
number to compare against rather than one to hit. A run that finds fewer
than 100 distinct states isn't exploring this system, whatever verdict it
reports.

## The run somebody else made

`RiverCall.cfg` is a config for this same system at a different instance:
three owners, each decreed 2 units, on a flow of 6. It declares the same
four checks. The four names in it are placeholders for yours, so match your
module's names to them or edit the file.

Run against a correct model of this system, TLC returns OK on it. Every one
of the four checks passed:

```
Model checking completed. No error has been found.
163 states generated, 27 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 4.
```

The claim on the table is that all four checks passed, so the model is
correct.

Answer two questions in writing:

1. What does that green run establish about the model?
2. What does it fail to establish, and why?

Then make your answer stick with evidence. A run and its numbers count. A
check of your own, with its verdict, counts. So does a behavior the rules
above allow that no one of the four checks can see on that instance, shown
step by step. An answer with none of those is an opinion.
