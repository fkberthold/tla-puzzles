# The laytime statement

A modeling problem. Plan on 20 to 40 minutes if you've read the learntla
core chapters.

## What you get

No spec. You write the whole thing: the state, the steps, the observation
operator, and the properties. What you get is the rules below, the four
facts the checker reads, three requirements to establish, one pair of runs
per requirement under `traces/`, and the instance to check at.

You don't need to know shipping. Every rule this system follows is stated
here.

## Your task

1. Model the system below, in PlusCal or TLA+, in whatever state you like.
2. Define `Observe`, the record described under "The interface".
3. Render the three requirements as TLA+ formulas over `Observe`, and
   declare each under the keyword given with it.
4. Run TLC at the checking instance. Your model must satisfy all three.
5. Hold your model against the traces. Every allowed run must be a run your
   model can produce. Every forbidden run must break at least one of your
   requirements.

Deliver your module and the `.cfg` you checked it with.

## The system

A ship comes into port to discharge a cargo. The contract that put it there
is a charterparty, between the shipowner and the charterer. The
charterparty gives the charterer a fixed allowance of time to get the cargo
off. That allowance is called laytime. When it runs out the charterer keeps
paying, at a different rate and under a different name, and that payment is
called demurrage.

**The parties.** One. The ship's agent keeps the written record of the
discharge, which is called the laytime statement. Every step in this system
is his. Nothing else acts, nothing arrives on its own, and there's no clock
and no calendar.

### Rule 1. The charter and the allowance

The charterparty names an allowance of laytime, `Allowance`, counted in
whole periods. A period is the unit the statement is written in. This
system never asks how long a period is, only how many of them have gone.

### Rule 2. The agent, and everyone outside

The agent writes the statement and nobody else touches it. The charterer
and the shipowner are outside this system. They settle the money later, on
the strength of what the statement says, and none of that settlement is
modeled. Nobody disputes the statement, nobody audits it, and nothing
corrects it after the fact.

### Rule 3. The notice of readiness

Before anything is reckoned the agent tenders a notice of readiness. That's
his written declaration that the ship is at the berth and ready to work the
cargo. The reckoning starts when he tenders it. He tenders it once, and he
never withdraws it. Before he tenders it, nothing in the statement moves at
all.

### Rule 4. Periods, and how time passes here

Time in this system moves only when the agent writes a period into the
statement. He writes it after the fact, so a period is a record of time
already gone and never a slot he books ahead. If he writes nothing, nothing
has passed as far as this system is concerned. There's no tick and nothing
that runs while he isn't looking.

### Rule 5. Working and excepted

The agent gives every period he logs one of two kinds, and he decides which
as he writes it.

- **Working**: the cargo time counted, and it draws the allowance down.
- **Excepted**: the charter names this kind of time as not counting. Bad
  weather, a port holiday, a strike on the quay.

The weather is the agent's reason for the classification. It's never a
step. Rain doesn't stop work in this system, because nothing here happens
that the agent didn't do. He looks at what happened, writes "excepted"
against the period, and notes why in a column nothing else reads.

### Rule 6. The allowance falls

While any of the allowance is left, a working period draws it down by one.
An excepted period draws nothing down. The allowance only ever falls.
Nothing refills it, no excepted period gives any of it back, and no later
working period can restore what an earlier one spent.

### Rule 7. Demurrage

Once the allowance is gone the ship is on demurrage, and the charterer pays
the owner by the period from then on. Each period the agent logs after the
allowance is spent accrues one period of demurrage. Accrued demurrage only
ever rises.

A logged period does one thing, never two. It counts against the allowance,
or it accrues demurrage, and no period is split between them. A period that
draws the last of the allowance down accrues nothing, and the period after
it accrues.

### Rule 8. Once on demurrage, always on demurrage

This is the rule of the trade and it's the one to read twice. Once the
allowance is spent, the charter's exceptions stop applying. A period the
agent would have written off as excepted an hour ago now counts, and it
accrues demurrage like any other. Rain that was free is now billed.

So after the allowance is spent the kind of a period changes nothing about
what it costs. Working or excepted, every logged period accrues one. The
switch is one-way. Nothing puts the ship back under laytime.

### Rule 9. The limit, and closing the statement

The charterparty caps the owner's demurrage claim at `Limit` periods. That
cap is a term of the charter, and what it caps is the claim. Once the
accrued demurrage reaches it there's nothing further for the statement to
record, so the agent logs no more periods. The only step still open to him
is closing the statement, and he needn't take it.

The agent closes the statement by recording that the discharge is complete.
He does that once, only after he has tendered the notice, and never undoes
it. After he closes it, nothing in the statement changes again.

### Rule 10. The opening

The statement opens with the notice not yet tendered, the discharge not
complete, the whole allowance standing, and no demurrage accrued.

### Rule 11. Nothing has to happen

The agent acts when he chooses and never on a deadline. He never has to
tender the notice, never has to log a period, and never has to close the
statement. He can leave the ship on demurrage forever. Nothing in this
system must eventually happen.

## The interface

Your state is your own. Keep whatever you like, in whatever shape you like,
and render these four facts from it. Each one is the kind of fact the agent
could read off the page.

Your module defines one operator, `Observe`, a record with exactly these
four fields, spelled this way:

- **noticeTendered**: whether the notice of readiness has been tendered.
- **laytimeLeft**: how many periods of the allowance are still unspent.
- **demurrage**: how many periods of demurrage have accrued so far.
- **finished**: whether the agent has recorded the discharge as complete.

The shapes are fixed, because the checker compares values:

- `Observe.noticeTendered` is a boolean.
- `Observe.laytimeLeft` is a natural number.
- `Observe.demurrage` is a natural number.
- `Observe.finished` is a boolean.

There's no absent marker anywhere in this record. Every field carries a
value in every state, from the opening onward. A string sitting where a
number belongs stops TLC dead rather than failing a check.

State every requirement over `Observe`. Grading reads `Observe` and nothing
else of yours.

## What to establish

Three requirements. Each is a claim about every run of the statement. They
must hold for any whole-period `Allowance` and any whole-period `Limit`.
The checking instance further down is one instance, not the specification.

**1. The reckoning opens once and closes once.** Until the notice is
tendered, the only field that ever changes is the notice itself. Once the
discharge is complete, nothing in the record changes again. The notice is
never withdrawn, and the completion is never undone.

Declare it under `PROPERTY`. It's an action property, and its subscript is
the whole of `Observe`.

**2. One period, one move.** At every step the allowance left either stays
put or falls by one, the demurrage accrued either stays put or rises by
one, and the two never move in the same step.

Declare it under `PROPERTY`. It's an action property, and its subscript is
the whole of `Observe`.

**3. Demurrage waits for the allowance.** Whenever any demurrage has
accrued, none of the allowance is left.

Declare it under `INVARIANT`. It's a state predicate.

That's the whole list, and all three are safety. Nothing here needs
"eventually", on purpose. Rule 11 says nobody has to act, so a model that
adds a fairness conjunct to force the discharge along is modeling a
different ship. A type invariant of your own is fine, and it isn't one of
the three.

**Subscript both step rules over the whole of `Observe`, never over one of
its fields.** A step rule watched over a single field is satisfied for free
by any step that moves only the other fields. TLC won't warn you. The
property just stops seeing the steps it was written about, and it goes on
reporting green.

**Rule 8 has two halves, and only one of them is watched.** The first half
is that the allowance never comes back, and requirement 2 carries it. The
second half is that an excepted period on demurrage still costs one.
Nothing in this interface can see that. The statement records what a period
cost, not what the agent called it, so a period's kind never reaches
`Observe`. Model Rule 8 whole, because it's the rule of the trade. Know
that no property you write is watching that second half.

## The traces

The `traces/` directory holds one pair per requirement. Each state shows
the four fields of `Observe`, and consecutive states are one step apart.

- **A run the agent could produce.** Your model must allow it.
- **A run that breaks the requirement.** Your model must rule it out.

Three notes:

- A forbidden run can break more than one requirement. If your set rejects
  it for any requirement it breaks, your set is right about that run.
- Every run shown is finite.
- If your model can't produce the allowed run of every pair, it's
  over-constrained, however green your checks are.

## Checking

Use the instance the traces use:

```
Allowance = 2
Limit = 2
```

Two is the least allowance that makes the drawdown happen more than once,
and the least limit that lets the demurrage counter rise twice. Both step
clauses of requirement 2 bite at that size and not below it.

Your `.cfg` declares your spec, the two constants, and your three
requirements under the keywords given above.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite
its name it turns the check off. Once the agent has closed the statement he
has no step left, and that's the end of the story rather than a fault.

Whatever else you declare, the run should find 11 distinct states. TLC
counts over every variable you declare, so that number checks your whole
model and not only the four facts. A different count means your model and
the system above have come apart, and the rules are where to look first.
