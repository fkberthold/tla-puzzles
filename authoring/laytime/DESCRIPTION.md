# Laytime and demurrage on a discharging ship

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape A, in a situation of allowance, lapse, and penalty. This is
rung 2 of batch 2, load vector 2 2 1 0 0 0, and representation 2 is its single
new high over rung 1. The learner writes the whole spec and its `Observe` from
prose, and the reference's variables are the `Observe` fields and nothing else.
So the weight of this rung is the abstraction choice, and the system below is
kept thin on purpose to leave room for it.

## 1. The system

A ship comes into port to discharge a cargo. The contract that put it there is a
charterparty, between the shipowner and the charterer. The charterparty gives the
charterer a fixed allowance of time to get the cargo off. That allowance is called
laytime. When it runs out the charterer keeps paying, at a different rate and
under a different name, and that payment is called demurrage. Nothing below needs
any shipping knowledge that isn't stated here.

**The parties.** One. The **ship's agent** keeps the written record of the
discharge, which is called the laytime statement. Every step in this system is
his. Nothing else acts, nothing arrives on its own, and there's no clock and no
calendar.

### Rule 1. The charter and the allowance

The charterparty names an allowance of laytime, `Allowance`, counted in whole
periods. A period is the unit the statement is written in. This system never asks
how long a period is, only how many of them have gone.

### Rule 2. The agent, and everyone outside

The agent writes the statement and nobody else touches it. The charterer and the
shipowner are outside this system. They settle the money later, on the strength of
what the statement says, and none of that settlement is modeled. Nobody disputes
the statement, nobody audits it, and nothing corrects it after the fact.

### Rule 3. The notice of readiness

Before anything is reckoned the agent tenders a notice of readiness. That's his
written declaration that the ship is at the berth and ready to work the cargo. The
reckoning starts when he tenders it. He tenders it once, and he never withdraws
it. Before he tenders it, nothing in the statement moves at all.

### Rule 4. Periods, and how time passes here

Time in this system moves only when the agent writes a period into the statement.
He writes it after the fact, so a period is a record of time already gone and
never a slot he books ahead. If he writes nothing, nothing has passed as far as
this system is concerned. There's no tick and nothing that runs while he isn't
looking.

### Rule 5. Working and excepted

The agent gives every period he logs one of two kinds, and he decides which as he
writes it.

- **Working**: the cargo time counted, and it draws the allowance down.
- **Excepted**: the charter names this kind of time as not counting. Bad weather,
  a port holiday, a strike on the quay.

The weather is the agent's reason for the classification. It's never a step. Rain
doesn't stop work in this system, because nothing here happens that the agent
didn't do. He looks at what happened, writes "excepted" against the period, and
notes why in a column nothing else reads.

### Rule 6. The allowance falls

While any of the allowance is left, a working period draws it down by one. An
excepted period draws nothing down. The allowance only ever falls. Nothing refills
it, no excepted period gives any of it back, and no later working period can
restore what an earlier one spent.

### Rule 7. Demurrage

Once the allowance is gone the ship is on demurrage, and the charterer pays the
owner by the period from then on. Each period the agent logs after the allowance
is spent accrues one period of demurrage. Accrued demurrage only ever rises.

A logged period does one thing, never two. It counts against the allowance, or it
accrues demurrage, and no period is split between them. A period that draws the
last of the allowance down accrues nothing, and the period after it accrues.

### Rule 8. Once on demurrage, always on demurrage

This is the rule of the trade and it's the one to read twice. Once the allowance
is spent, the charter's exceptions stop applying. A period the agent would have
written off as excepted an hour ago now counts, and it accrues demurrage like any
other. Rain that was free is now billed.

So after the allowance is spent the kind of a period changes nothing about what it
costs. Working or excepted, every logged period accrues one. The switch is
one-way. Nothing puts the ship back under laytime.

### Rule 9. The limit, and closing the statement

The charterparty caps the owner's demurrage claim at `Limit` periods. Once the
accrued demurrage reaches the cap, the agent logs nothing further. The only thing
left for him to do is close the statement.

The agent closes the statement by recording that the discharge is complete. He
does that once, only after he has tendered the notice, and never undoes it. After
he closes it, nothing in the statement changes again.

### Rule 10. The opening

The statement opens with the notice not yet tendered, the discharge not complete,
the whole allowance standing, and no demurrage accrued.

### Rule 11. Nothing has to happen

The agent acts when he chooses and never on a deadline. He never has to tender the
notice, never has to log a period, and never has to close the statement. He can
leave the ship on demurrage forever. Nothing in this system must eventually
happen.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **The reckoning opens once and closes once.** Until the notice is tendered, the
   only observable that ever changes is the notice itself. Once the discharge is
   complete, nothing observable changes again. The notice is never withdrawn, and
   the completion is never undone.
2. **One period, one move.** At every step the allowance left either stays put or
   falls by one, the demurrage accrued either stays put or rises by one, and the
   two never move in the same step.
3. **Demurrage waits for the allowance.** Whenever any demurrage has accrued, none
   of the allowance is left.

Item 3 is a claim about a single state, so it's an invariant. Items 1 and 2 each
compare the statement at two consecutive moments, so they constrain steps and land
as action properties. Nothing here needs "eventually", so there's no liveness in
this description and no fairness conjunct to decide.

Both step rules are subscripted over the whole of `Observe`, never over a single
field. A rule subscripted on `laytimeLeft` alone would let a step move the
demurrage and the notice together and never be looked at.

The type invariant is the reference author's. It's declared in the cfg alongside
these three, and it's not a learner requirement. It's what carries the ranges: the
allowance left sits between zero and `Allowance`, the demurrage accrued between
zero and `Limit`, and the notice and the completion are each a yes or a no.

Each item breaks on a short finite trace, which is what §3.9 needs downstream.
Item 1 falls on one step, the allowance dropping from two to one with the notice
still untendered on both sides. It falls a second way on a step that takes the
completion from recorded back to not recorded. Item 2 falls on one step, the
allowance dropping from two to zero. Item 3 falls in a single state, one period of
demurrage accrued with one period of the allowance still standing. None needs more
than two states to break, and each is satisfied by an ordinary run.

Three is the cap and not a target I stopped short of. The reference author's type
invariant is the fourth cfg line, and four is the top of this rung's
property-count band.

## 3. The observation operator

The operator is named `Observe`. Each field is a fact about the laytime statement
right now, the kind the agent could read off the page. The fields are given here as
named facts, not as syntax. The author renders them over whatever state they
chose, one field per line.

**noticeTendered**: whether the notice of readiness has been tendered. Needed for
must-be-true 1, which is the only thing standing between an untendered ship and a
reckoning that has already started.

**laytimeLeft**: how many periods of the allowance are still unspent. Read by
must-be-trues 2 and 3, and it's what makes a working period visible at all.

**demurrage**: how many periods of demurrage have accrued so far. Read by
must-be-trues 2 and 3.

**finished**: whether the agent has recorded the discharge as complete. Needed for
must-be-true 1's closing clause.

**Why there's no field for the latch.** This is the one real decision in the
operator, so it gets said plainly. Whether the ship is on demurrage is a fact
about the allowance being spent, and it's reportable from `laytimeLeft` alone. So
it doesn't get a field. My read is that a fifth field carrying the mode would be
the single most damaging thing this operator could do, because the whole abstraction
question at this rung is whether the learner sees that the mode is already there.
Give them a field for it and the question is answered on the page.

**Why the period's kind isn't reportable.** The statement records what a period
cost, not what the agent called it. While the allowance stands, an excepted period
costs nothing and moves nothing, so it's a stutter at this interface. Once the
allowance is spent, every period costs one whatever it's called, so the kind stops
mattering. There's no state of this system in which the kind is both live and
invisible, which is why it isn't a field.

**Sufficiency walk.** The test in each row is which property constrains the rule,
never which field mentions it. A rule a field names and no property constrains is
ungraded. First, what each must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 Opens once, closes once | noticeTendered, finished, and the record as a whole |
| 2 One period, one move | laytimeLeft, demurrage |
| 3 Demurrage waits | laytimeLeft, demurrage |

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 The charter and the allowance | The range of `laytimeLeft` is the type invariant, which is a real cfg line and not a shape argument. How big the allowance is, is a constant and not a claim about any run |
| 2 The agent, and everyone outside | Nothing, and on purpose. `Observe` shows the statement, not the hand writing it. The paragraph below says why |
| 3 The notice of readiness | 1, in both of its opening clauses. Nothing moves before the notice, and the notice is never withdrawn |
| 4 Periods, and how time passes | 2. A logged period moves one counter by one, and 2 is that demand stated as a property |
| 5 Working and excepted | 2 and 3 between them, for what a period of either kind is allowed to do to the counters. The classification itself is invisible, for the reason two paragraphs up |
| 6 The allowance falls | 2 for the direction and the step size, 3 for what a fall to zero lets happen next |
| 7 Demurrage | 3 for when it may start, 2 for the direction, the step size, and the no-split clause |
| 8 Once on demurrage, always | 2's no-rise clause, which is the half of the latch that lives in the counters. The other half isn't a cfg line, and the paragraph below says so |
| 9 The limit, and closing | The range of `demurrage` is the type invariant. The closing clauses are 1 |
| 10 The opening | Not a cfg line. The model's `Init` carries it, and section 5 says what that costs |
| 11 Nothing has to happen | Nothing, and that's how it's graded. It's the absence of an obligation, and what carries it is that no property here is a liveness one |

Three things above are ungraded and I'd rather name them than let a reader find
them.

Rule 2 first. `Observe` shows the statement and not the hands in it, so who took a
step can't be a property of any model, whatever fields you add. Rung 1 hit the same
wall and the reasoning carries over. Rule 11 is the same shape from the other end.
An obligation would show up as a liveness property, and its absence is what says
there's no obligation.

Rule 8 is the interesting one. The half that says the allowance never comes back
is must-be-true 2's no-rise clause. The half that says an excepted period on
demurrage still costs one has no property over this interface, because the model
that gets it wrong has a step that changes nothing, and a step that changes nothing
is a stutter. My read is that this is caught downstream rather than by a cfg line:
a model that lets excepted periods run free on demurrage admits a strict subset of
the reference's behaviors, and §5.2's two-sided implication is where that lands. I
want the reference author to know that's where the weight sits, because it's the
one rule here worth building the seeded bugs on.

Everything else is constrained. Every field earns its place through at least one
must-be-true, so nothing in the operator is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under a second. Every
bound below is a term of the charterparty first and a finiteness device second.

- **`Allowance`** (Rule 1): the laytime the charter gives, in whole periods. The
  config picks one value and the rules hold for any.
- **`Limit`** (Rule 9): the charter's cap on the demurrage claim. Real charters cap
  the owner's exposure, and here the cap is also what makes the statement a finite
  document. Without it the demurrage counter has no ceiling the domain supplies.
- **Whole periods** (Rule 4): the statement reckons in whole periods and never in
  fractions of one. That's what makes Rule 7's no-split clause true rather than an
  approximation.
- **One ship, one cargo, one charter** (Rule 2): the statement is about one
  discharge. There's no second berth and no second parcel.

**Suggested instance**: `Allowance` 2, `Limit` 2. Two is the least allowance that
makes the drawdown happen more than once, so a model that empties the allowance in
one step is caught rather than indistinguishable. Two is the least limit that lets
the demurrage counter rise twice, which is what makes must-be-true 2's step-size
clause bite on the demurrage side as well as the laytime side.

The arithmetic. Four observables give 2 times 2 times 3 times 3, which is 36
records in the type space. Must-be-true 3 cuts the counter pairs from 9 to 5,
since a positive demurrage forces the allowance to zero. Nothing moves before the
notice, so exactly one untendered record is reachable, and the agent can't close
the statement before he opens it. That leaves about 1 plus 5 times 2, so I make the
reachable count around 11. Well under 1,000 and sub-second with room to spare.
That's an estimate. Nobody has run it.

The count is small even for this rung, and I think that's right rather than
worrying. The rung's difficulty is the abstraction choice and not the search. If
the reference author wants more room for the trace sets, raise `Allowance` first,
then `Limit`.

**Quiescence.** Once the agent has closed the statement, no action is enabled and
the system stops. That's the intended end of the story and not a fault. A checker
reporting deadlock there is reporting the design working, and the reference author
should handle it in the config rather than by inventing a stuttering action this
system doesn't have.

## 5. Open forks

At representation 2 the learner picks the state, so the forks are the problem
rather than a note about it. Each line below is a choice the rules don't make, and
the statement has to keep every one of them open.

- **The allowance**: what's left, or what's been used against a constant.
- **The latch**: derived from the allowance being spent, or carried as a status.
- **The two stages**: two independent facts, or one status running from untendered
  through open to closed.
- **Demurrage**: a running count, or a record of the periods that accrued it.
- **The logging action**: one action carrying a kind, or two actions, or one action
  that does whatever the allowance says.
- **The opening**: an `Init` that pins all four facts, or one that pins the
  counters and lets the flags fall out.

The latch is the one that decides this rung. The screen report's shortest route is
a learner who carries the allowance and the mode as two loose variables and writes
every property without noticing they're coupled
(`authoring/laytime/reports/step0-screens.md:192-196`). Section 3 closes that at
the interface rather than in the prose, which is where I want it closed.

**A constraint on the reference author, not a fork.** Representation 2 pins the
reference to four variables, one per `Observe` field, and no fifth. So the author's
own freedom here is narrower than the learner's: it's in what each variable holds
and how the actions move it, never in adding a carrier for the mode. If the author
finds they want a fifth variable, that's a finding about this description and it
should come back rather than get written.

**The dropped candidate rules.** The screen report offered four
(`authoring/laytime/reports/step0-screens.md:220-229`): the type invariant, the
allowance never rising, the demurrage never falling, and demurrage only when the
allowance is spent. I've folded the two monotonicity rules into one must-be-true
and spent the freed slot on the boundary rule, and section 6 says why.

**The opening, and why it isn't a fourth line.** At representation 2 no spec ships,
so nothing outside the learner's own `Init` fixes the opening. Rule 10 states it,
and the model's `Init` is what carries it. A fourth must-be-true pinning it would
be a fifth cfg line, which is the next property-count level and breaks the rung. I
think the right handling is for the reference author to write an exact `Init`
rather than a permissive one, and for the trace sets to start from it.

## 6. Ambiguities resolved, and how they could have gone

1. **The weather.** The agent classifies a period. Rain never acts. The
   alternative is an environmental step, which belongs to no party and takes step
   sources from 0 straight to 3. The screen report flagged this as the dangerous
   one of two boundaries and I agree with it.
2. **The charterer and the owner.** Outside the system, stated in Rule 2. The
   alternative models the settlement, which is a second party and a payment
   protocol. §3.2 obliges this to be fixed rather than implied, so it gets a
   sentence.
3. **No calendar.** Time moves only when the agent logs a period. A clock is the
   cheapest way to write a domain about time running out, and it's the one thing
   this rung can't have.
4. **Whole periods.** No fractions and no straddling. Real laytime is reckoned in
   hours and a period does straddle the moment the allowance runs out. Modeling
   that needs arithmetic on part-periods, which is a bigger state space for no new
   modeling question.
5. **No despatch.** The charterer earns nothing back for finishing early. Despatch
   is the real reverse payment and it's the most tempting addition here. It's a
   third counter and a fourth rule, which pushes the property count past this
   rung's level.
6. **One notice, never withdrawn.** Real practice re-tenders when a notice turns
   out to be invalid. A withdrawal step kills must-be-true 1 outright, and 1 is
   the rule doing the boundary work.
7. **The demurrage cap.** The charter caps the claim at `Limit`, and the statement
   closes there. The alternative leaves demurrage uncapped, which is an unbounded
   counter with no ceiling the domain supplies. My read is that the cap is the
   more honest fix, because a charter clause is a real thing and an invented
   horizon isn't.
8. **Closing is final.** Nothing resumes after the agent closes the statement. The
   alternative reopens it, which is a real thing in a dispute and which kills
   must-be-true 1's closing clause.
9. **The excepted list.** The charter's exceptions aren't modeled item by item. The
   alternative names weather, holidays and strikes as separate kinds, which is
   three words of vocabulary and no new property.
10. **The opening.** Untendered, unclosed, full allowance, nothing accrued. The
    alternative opens the statement mid-discharge, which pushes the opening into
    the config as per-instance inputs.
11. **One cargo.** No per-parcel reckoning and no second hold. Parcels turn the
    counters into functions and make this a different problem.
12. **Nothing must happen.** The agent is under no obligation to finish. An
    obligation is liveness, and this rung's property kind stops at action
    properties.

**Where I departed from the screen report.** One place, and it's the shape of
section 2. The report proposed four cfg lines as the type invariant plus three
rules, with the allowance never rising and the demurrage never falling as two
separate lines (`authoring/laytime/reports/step0-screens.md:220-229`). Those two
say the same kind of thing about the same pair of counters, and neither of them
grades the boundary. Nothing in the report's set stops a model from drawing the
allowance down before the notice is tendered, or from moving a counter after the
statement is closed. That's a way into the system that no property watches, and
it's the defect rung 1's review found blocking. So I folded the two monotonicity
clauses into must-be-true 2, added the step-size and no-split clauses that Rules 4
and 7 need, and spent the freed slot on must-be-true 1. The count is unchanged at
four cfg lines.

**One thing I'd flag for the reviewer.** Rule 9's demurrage cap is the piece of
this description I'm least sure of. I've written it as a term of the charterparty
because that's what it has to be for the bounds in section 4 to be facts of the
system, and real charters do cap the owner's exposure. But I don't hold a working
model of how common the clause is, and if it reads as invented then section 4 is
resting on a device wearing a charter's clothes. The alternative I'd take is to
bound the statement itself rather than the claim, which is worse, because a
statement that runs for a fixed number of periods is a calendar in all but name.
