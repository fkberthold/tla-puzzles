# A call on the river

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 to 7 are pipeline notes for central. Keep them
out of the author's brief and out of anything downstream of it.

Grid cell: task shape D, in a situation of resource allocation and contention.
This is rung 3 of batch 2, load vector 2 2 1 1 0 0, and several actors of one
kind is its single new high over the running maximum.

## 1. The system

Water law across the American west runs on prior appropriation. A right to take
water out of a stream is a **decree**, and a decree carries two things: an amount,
and the date the right was first put to use. When the stream is short, the rule is
first in time, first in right. The older date takes its full amount and the
younger one goes without. That order is fixed long before anybody opens a gate.
Nothing below needs any water law that isn't stated here.

**The parties.** One kind, and several of them. A fixed, finite set of **ditch
owners**, named by `Owners`. Each owns a headgate on the same stretch of stream
and turns their own wheel. Nothing else acts. There's no clock, no season, no
weather, and no official.

Nothing coordinates the owners. Any owner's act can land between any two acts of
another.

### Rule 1. The stream

One stream runs past every headgate on the stretch. It carries a fixed amount of
water, `Flow`, counted in whole units. That amount never changes. A dry year and a
wet year are two instances of this system, not two moments in one.

### Rule 2. The register

Each owner holds one decree. A decree names an amount, `Decree`, in the same whole
units as the flow, and a priority date. The decrees sit on a public register that
every owner can read. No two owners share a date, so the register puts them in one
order with no ties. An owner is **senior** to another when their date is the older
of the two, and **junior** when it's the younger. Nothing in this system ever
changes a decree, a date, or the order.

### Rule 3. The headgate

Each owner sets their own headgate, and only their own. A setting is a whole
number of units, from shut up to that owner's decreed amount. An owner can move
their own gate up or down at any time, in one act, to any setting in that range.
Nobody else touches it and nobody asks first.

### Rule 4. The stream can't give what it hasn't got

The settings never total more than the flow. A setting and the water actually
running are the same thing here, because an owner checks what the others are taking
before they open. Water that isn't going down a ditch stays in the stream.

### Rule 5. Short

An owner is **short** when the water they could take right now falls under their
decreed amount. Count it this way: what they're already taking, plus the water
nobody is taking, against their amount. So an owner who could open up to their
full decree out of the water sitting free in the stream isn't short, whatever
their gate reads at the moment. An owner who couldn't is.

### Rule 6. The call

A short owner can put a **call** on the river. A call is a notice, not a request,
and nobody answers it. Only a short owner can put one out. It stands until the
owner who put it out takes it back, and they can take it back whenever they like,
short or not.

### Rule 7. What a call does

While a call stands, no owner junior to the caller opens their gate any wider than
it already is. That's the whole of it. A call reaches what a junior may newly
take, and it doesn't reach a gate that's already open. It reaches a junior's rise
if it was standing when the rise began, whatever happens to the call in the same
act. Nobody senior to the caller is touched, and neither is the caller.

### Rule 8. Nobody enforces anything

There's no watermaster on this stretch. Every owner reads the same register and
applies the rule to themselves. Nobody grants water, nobody waits for a grant, and
nobody can shut another owner's gate. First in time, first in right settles who
may open. Who got to the wheel first settles who keeps the water already running.

### Rule 9. Nothing has to happen

No owner is under any obligation. An owner can leave a gate shut forever, leave it
open forever, leave a call standing forever, or never call at all. Nothing in this
system must eventually happen.

### Rule 10. The opening

Every gate starts shut and no call stands.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **The flow holds.** At every moment the owners' settings total no more than the
   flow.
2. **Nobody opens against a call.** At a step where an owner's setting rises, no
   owner senior to them had a call standing in the state the step ran from.
3. **A call is honest.** At a step where an owner's call goes out, that owner was
   short in the state the step ran from.

Item 1 is a claim about a single state, so it's an invariant. Items 2 and 3 each
compare a record at two consecutive moments, so they constrain steps and land as
action properties. Nothing here needs "eventually", so there's no liveness and no
fairness conjunct to decide.

Both step rules are subscripted by the whole of `Observe`, never by one field of
it. Subscript item 2 by the settings alone and a step that only moves a call slips
out of the property's reach, which is the one step item 3 exists to catch.

The type invariant is the reference author's. It's declared in the cfg, it's the
fourth line there, and it isn't one of the three requirements above. It's also
where the setting's range lives: every owner's setting is a whole number from zero
up to their own decreed amount, and every owner's call is a yes or a no. A stated
range over a number is a predicate rather than a shape, so it earns a real cfg
line or it grades nothing.

Item 2 is a step rule and not a claim about single states, and that's forced
rather than chosen. A senior's own lawful act can leave a junior's standing
setting out of priority, and nothing in this system can shut the junior's gate. So
"no junior takes water while a senior is calling" is not something any model of
this system can hold as an invariant. Section 5 carries the trace.

Each item breaks on a short finite trace, which is what §3.9 needs downstream.
Take three owners, senior to junior, each decreed 2 units, on a flow of 3.

- Item 1 falls in a single state: every gate at 2, which totals 6 against a flow
  of 3. It's satisfied by 2, 1 and 0, which totals 3.
- Item 2 falls on one step. Start from the senior at 2, the other two shut, and
  the middle owner calling. The junior opens to 1. The settings total 3, so the
  flow rule is fine in both states, and the junior has still opened against a call
  from a senior. The same step is satisfied if the middle owner opens to 1
  instead, since nobody senior to them is calling.
- Item 3 falls on one step. Start from every gate shut and no call standing, and
  put the senior's call out. Three units sit free and their decree is 2, so they
  weren't short. It's satisfied from the senior at 2 with the others shut, where
  the middle owner has one free unit against a decree of 2, and their call goes
  out.

Three is the cap here, not a target I stopped short of. Don't add a fourth. I
considered one pinning the opening (every gate shut, no call standing) and left it
out, because the shipped spec's opening state already fixes it.

## 3. The observation operator

The operator is named `Observe`. Each field is a fact about the stretch right now,
the kind an owner could read off the register and the gate wheels. The fields are
given here as named facts, not as syntax. The author renders them over whatever
state they chose, one field per line.

**diverted**: for each owner, how much water is going down their ditch right now.
All three must-be-trues read it, and without it none of them can be stated.

**calling**: for each owner, whether a call of theirs stands on the river right
now. Needed for items 2 and 3.

**Why shortness isn't a field.** This is the one real decision in the operator, so
it gets said plainly. Shortness is worked out from `diverted`, the flow and the
decrees, and it's never reported as a fact in its own right. Expose it and item 3
grades a model against that model's own idea of shortness, so a model that gets
Rule 5 wrong and reports it consistently passes. Keeping it out means the property
computes it the one way Rule 5 states, and a wrong guard shows up as a step where
a call goes out from a state Rule 5 calls comfortable. The cost is real. It ties
the properties to the constants as well as to the fields, and the author should
expect that rather than reach for a third field.

**What the fields do and don't constrain.** A field says what has to be
reportable, not what the state is. A model that keeps its books another way must
still answer both questions off its own state, and that's the whole demand. Don't
read `diverted` and `calling` as two functions the model has to store.

**Sufficiency walk.** The test in each row is which property constrains the rule,
never which field mentions it. A rule a field names and no property constrains is
ungraded. First, what each must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 The flow holds | diverted |
| 2 Nobody opens against a call | diverted, calling, and the register's order |
| 3 A call is honest | diverted, calling |

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 The stream | The flow is a constant, so no step can move it, and there's nothing to grade. What it can give is graded by 1 |
| 2 The register | Amounts, dates and the order are all constants. Nothing can change them, so nothing grades them. The order itself is read by 2 |
| 3 The headgate | The range is the type invariant, a real cfg line and not a shape argument. The half about whose hand is on the wheel is ungraded on purpose, and the paragraph below says why |
| 4 The stream can't give what it hasn't got | 1, in every state |
| 5 Short | Nothing on its own. It's a definition, and 3 is where it bites |
| 6 The call | 3, for the half that says only a short owner can put one out. Taking a call back is free at any time, so there's nothing to forbid and nothing to grade |
| 7 What a call does | 2. The half that says a call doesn't reach an open gate is carried by 2 covering rises alone |
| 8 Nobody enforces anything | Nothing, and the paragraph below says why that's right |
| 9 Nothing has to happen | Nothing, and that's how it's graded. It's the absence of an obligation, and what carries it is that no property here is a liveness one |
| 10 The opening | The shipped spec's opening state, not a requirement. Section 2 says why |

Two rules go ungraded above and I'd rather name the reason than let a reader find
it. `Observe` shows the stretch, not the hands on it. Whose act moved a gate is
invisible at this interface, so "each owner sets only their own" can't be a
property of any model, whatever fields you add. Rule 8 is the same fact from the
other end. A watermaster would show up as a party with steps of its own, and its
absence is what says nobody can shut a gate for somebody else.

Now the transitions, since a rule that names one and no property catches it is a
hole. A gate rises: item 2 checks the register and item 1 checks the water it
lands in. A gate falls, shut included: legal at every setting, and Rule 3 says so.
A gate opens from shut: that's a rise, so it takes both checks. A call goes out:
item 3. A call comes back: free by Rule 6. A step that moves two owners at once
still lands on the same properties, since items 1, 2 and 3 all quantify over
owners rather than over whichever one acted. There's no other way for either field
to change.

Every field earns its place through at least one must-be-true, so nothing in the
operator is decoration.

## 4. Bounds

TLC has to check the suggested instance exhaustively in well under a second. Every
bound is a fact of the system first and a finiteness device second, and each one
already sits inside a rule the model has to enforce as behavior.

- **`Owners`**: the ditches on the stretch. The config picks one instance and the
  rules hold for any.
- **`Flow`** (Rule 1): the water in the stream. It's the stream, not a cap somebody
  chose for the model.
- **`Decree`** (Rule 2): each owner's decreed amount, off the register.
- **The priority order** (Rule 2): the register's dates. Fixed before anybody acts.
- **Whole units** (Rules 1 and 3): the unit the register is written in here.

**Suggested instance**: 3 owners, each decreed 2 units, on a flow of 3.

Three owners is the least that does any work. Two give a chain with one senior and
one junior, and each of them sits at an end of it. Three give a middle owner who's
senior to one and junior to another, which is where must-be-true 2's two
quantifiers earn their place.

A flow of 3 against decrees totalling 6 puts the stream under the paper right, so
shortage is reachable. It also sits above any single decree, so no owner can make
themselves short by their own draw. One owner at their full decree already leaves a
second short, and that's the contention this cell is for.

A decree of 2 rather than 1 matters. At 1 a gate is open or shut, and "rises"
collapses into "opens". At 2 an owner can rise twice, and a junior can hold a
setting that a call now forbids them to raise.

The arithmetic. Three settings from 0 to 2 is 27 combinations, of which 17 total 3
or less. Three yes-or-no calls is 8. So at most 136 states pass the type invariant
and the flow rule together, and fewer are reachable, since a call needs a short
owner behind it. Under 1,000 and sub-second with a lot of room. That's an
estimate. Nobody has run it.

**Quiescence.** I don't expect a deadlock report here, and the reason is worth
stating so the author doesn't reach for a stuttering action. Some owner can always
move. A fall is legal from any setting, and the most senior owner has nobody above
them to call, so their gate can rise whenever the water allows. The opening state
already allows it.

## 5. Open forks

The learner writes their own state at this rung, so the forks below are the
problem rather than a footnote to it. Each line is a choice the rules don't make,
and the wording above is meant to keep it open.

- **The settings**: a number per owner, a set of owner-and-amount pairs, or the
  owners in seniority order with their settings alongside.
- **The calls**: a yes or no per owner, or the set of owners whose call stands.
- **Shortness**: worked out from the settings each time it's needed, or carried
  and kept up to date as gates move.
- **Seniority**: a date per owner, a rank, or an order relation over the owners.
- **The gate**: one number, or an open-or-shut fact with an amount beside it.

The reference author's freedom is narrower than the learner's, and that's the
rung. The reference carries these two fields as its variables and nothing else.
The learner's model can hold whatever it likes, as long as it can answer both
questions off its own state.

**One fork the operator closes, on purpose.** Under must-be-true 2 only the most
senior caller matters. Everyone junior to them is blocked, and anybody junior to a
junior caller is junior to the senior one too. So a model could carry the most
senior caller alone and still get the rule right. `calling` closes that, because
it asks for a yes or a no per owner and the one-caller model can't answer for the
rest. I think that's the right trade. The alternative reports only what the rule
happens to need, and then a model that never learned the register's shape passes.

**Where I left the screener's sketch, and why.** Two places, and both are worth the
next reader's time.

The sketch had the priority rule as a claim about single states: if any owner is
short, every owner junior to them is shut. It doesn't hold. Take the three owners
of section 4. From every gate shut, the junior opens to 1. Nobody's short, since 2
units still sit free against decrees of 2. Now the senior opens to 2, which is
their own decree and their own right. The free water drops to nothing, the middle
owner is short at 0 against 2, and the junior is still taking 1. The invariant
broke on the senior's own lawful act. Guarding that act inverts priority, and
closing the junior's gate in the same step needs a coordination Rule 8 denies. So
the rule moves onto steps, and out-of-priority water already running is a legal
standing state. My read is that's the honest answer for a stretch with no
watermaster, and it's what Rule 8's second sentence is doing there.

The sketch also had shortness gating diversions directly, with no call in the
system. That needs the guard read on the post-state, and it's worth naming which
reading I'm refuting, because every other rule here reads its guard on the
pre-state. Under the pre-state reading the junior's rise from all shut is legal and
there's nothing to argue about. Under the post-state one a senior's shut gate caps
every junior at whatever it leaves spare, because the senior's unused decree still
counts against the free water. Work it on the three owners of section 4. The senior
sits at 0 and the junior takes 2. The free water drops to 1, the senior is short
against a decree of 2, and the rise was illegal. So the junior caps at 1.

The call earns its place under either reading, and what it buys is worth saying
straight. It puts a second piece of decidable state in the learner's hands, which
is the work this rung is for. It's also the domain's own mechanism and the reason
the spec is named for it. A short owner has to actually be short to put a call out,
and a senior with their gate shut on a full stream isn't.

**Why the count stops at three.** The reference author adds the type invariant, so
three requirements make four cfg lines, and four is the top of this rung's
property-count band. A fifth line would push the count to the next level and break
the rung. That's why section 2 turns down a fourth item pinning the opening, and
it's pipeline reasoning rather than anything the reference author needs.

## 6. Ambiguities resolved, and how they could have gone

1. **The flow is a constant.** A stream that rises and falls on its own is a step
   this description assigns to no party, which takes step sources from 1 to 3 and
   breaks the rung. A dry year is an instance here, not an event.
2. **No watermaster.** The alternative is an official who curtails, which is a
   second kind of actor and a coordinator that grants. That's step sources 2, and
   it drags in an allocator this cell is meant to avoid.
3. **What "short" means.** Fixed in Rule 5: what you're taking, plus what nobody
   is taking, against your amount. Two other readings were available. Short
   against what you're taking now makes every owner under their decree short, so a
   shut gate locks the river. Short against what seniors alone have taken ignores
   the junior who's already in the water, which is the case the whole domain is
   about.
4. **The call binds rises only.** It doesn't force a junior to close. Forcing one
   is either an obligation, which is liveness and a property kind above this rung,
   or a joint step, which needs the coordination Rule 8 denies.
5. **Only a short owner can call.** The alternative lets anyone call at any time,
   which the register can't tell from a real call and which turns the rule into a
   race to notice.
6. **A call comes back at will.** The alternative releases it only once the owner
   is no longer short, which is a fourth requirement and a cfg line this rung
   hasn't got.
7. **Capacity is fixed twice, and both are constants.** The stream's capacity is
   `Flow` and an owner's is their decreed amount. A gate can't be set above the
   amount, which is the type invariant, and the settings can't total above the
   flow, which is must-be-true 1. Neither number moves. Storage, a reservoir, or a
   right that grows with use would each need a clock.
8. **No two owners share a date.** Ties would need a tie-break rule and a fourth
   requirement to grade it.
9. **Decrees never change.** Real rights are abandoned, forfeited, sold and moved
   downstream. Every one of those is a second system on top of this one.
10. **Two owners can act at the same moment.** Nothing here forbids it, and I
    checked that nothing needs to. Items 1, 2 and 3 quantify over owners rather
    than over whichever one acted, so a joint step lands on the same properties a
    pair of separate steps would. The alternative is a one-act-per-step
    requirement, which is a fourth cfg line that grades nothing the other three
    miss.
11. **No return flow.** Water an owner doesn't consume runs back to the stream in
    real life, and a downstream ditch can take it again. Modeling that needs
    positions along the reach and a second accounting, and it's the largest thing
    I cut.
12. **Nothing has to happen.** No owner is obliged to divert, call, release or
    close. An obligation to curtail is the tempting one, and it's liveness.
13. **Whole units.** The alternative is cubic feet per second at whatever
    precision, which is either a much larger state space or a continuous one.
14. **A setting is the water going down the ditch.** Rule 4 makes the two the same
    fact, because an owner checks what the others are taking before they open. The
    alternative is a physical cap, where the stream just doesn't deliver what a
    gate is set to. Then `diverted` can never total above the flow whatever the
    owners set, so must-be-true 1 can't be falsified and §3.9 has nothing to break
    it on.

## 7. The diagnose object, central only

Shape D at this rung ships a vacuous pass rather than a failing trace, which is
the variant §2.1 says nothing public covers. The screener proposed the seed and
I'm taking it.

**The seed.** The shipped cfg sets the flow at or above the sum of the decrees.
The spec is otherwise the reference, and TLC returns green on all four lines.

**Why it's a defect.** With that much water nobody can ever be short. Take any
state passing the type invariant. Every setting is at or under its own decree, so
the water nobody is taking is at least the shortfall summed over everybody, which
is at least any one owner's own shortfall. So Rule 5 never fires. No call can go
out, and `calling` never leaves its opening value.

The two step rules then pass for different reasons, and the difference decides what
a probe reports. Must-be-true 2's antecedent is a setting rising, which fires on
nearly every step of this run. It passes because its consequent holds everywhere,
nobody being able to call. Must-be-true 3 is the one that's vacuous, and it's
vacuous at the antecedent, since no call ever goes out. The flow rule is implied by
the type invariant on that instance, so it never binds either. Only the type
invariant does any work, and the priority logic the spec exists to state is
untouched by the run.

**Why a learner who modelled the system right catches it.** Shortage is the engine.
Anybody who built this system knows a call needs a short owner behind it, and that
the priority rule bites only while a call stands. So the first question they ask of
a green run is whether anybody ever goes short, and that question is the flow
against the sum of the decrees. A learner who never worked out Rule 5's arithmetic
has no reason to look at that constant at all, since the spec reads correct on its
own terms and no trace points anywhere.

**Three corroborating signals**, in order of what they cost to get. The distinct
state count is a fraction of what the same spec gives on a lower flow. That's right
there on the console, and it's the kind of thing §5.1 lets a verdict read. Running
with `-coverage 1` gives the call action a row reading 0 total, which is
console-visible too and is the strongest of the three. That one holds for any
reference that guards its call-out on shortness, and I don't think a faithful one
can do otherwise. The `calling` field holding its opening value in every state is
the weakest, since reading it takes a probe the learner has to write, while the
count and the coverage row don't.

**Our own machinery answers this one.** `harness/vacuity.sh` returns
`VACUOUS_DEAD_ACTION` at rc=5 on this seed, off the `total == 0` predicate at
V2-PLAN.md:873-889. That makes the seed better rather than worse, since the defect
is the kind this project already knows how to name. Step 4 has to keep the harness
out of the learner's hands, or the puzzle answers itself in one command.

**The alternative the statement could seed instead** is a failing trace, and the
screener called it the weaker of the two here. The last state doesn't break the
flow rule, so a reader who only checks the arithmetic has to keep going and line
two owners' decrees up against their settings. That's better than most failing
traces and still shorter than the intended route. The vacuous variant is where
this domain is strongest, and it's what I'd ship.
