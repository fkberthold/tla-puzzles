# Determination slips on a herbarium sheet

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5, 6 and 7 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape D, in a situation of concurrent annotation with a derived
reading.

## 1. The system

A herbarium is a collection of pressed, dried plants. Each specimen is glued to
one sheet of card, and the sheet is the object of record. Naming the specimen is
called determining it, and a botanist who determines a sheet says so on a small
slip of paper attached to the sheet. The slip carries the name they believe it
is, their own name, and where in the sheet's history they read it. Nothing below
needs any botany that isn't stated here.

**The parties.** One kind. A fixed, finite set of **botanists**, named by
`Botanists`. Every step in this system is some botanist's. Nothing else acts.
There's no clock, no calendar, and no event that happens on its own. Nothing
coordinates the botanists, and any one of them can take a step between any two
steps of another.

### Rule 1. The sheets

`Sheets` is a fixed, finite set, named up front. One specimen to a sheet, glued
down. Sheets are never added, removed, split, or merged, and no specimen appears
on two of them.

The herbarium opens with every sheet bare. Nothing has been consulted, no slip
is attached to anything, no sheet has an accepted name, and no sheet stands
doubtful.

### Rule 2. Consultation, and the only order there is

A botanist consults a sheet by taking it to the bench and studying it. Every
sheet carries a consultation register, and the register's whole content is a
count: how many times this sheet has been consulted. A consultation adds one to
that count and hands the botanist that new number as the stamp of their
consultation.

That count is the only order this system has. Nothing here is dated. Two
botanists working the same sheet are ordered by which of them consulted it
first, and by nothing else.

Handling damages a pressed specimen, so the herbarium caps it. Each sheet has a
handling allowance, `Handling`, which is the number of consultations it can take
before it's withdrawn from consultation. Allowances differ by sheet, because a
bracken frond stands more handling than an orchid. A withdrawn sheet takes no
further consultations. Anyone who already holds an open consultation of it can
still file on it.

A botanist's consultation of a sheet stays open until they file a slip on that
sheet. Consulting the same sheet again replaces the stamp they hold with the new
one, and the old stamp is gone. A botanist can hold open consultations of
several sheets at once, one per sheet.

### Rule 3. Determination slips

A botanist who holds an open consultation of a sheet can file a determination
slip on it. The slip carries the name they believe the specimen is, drawn from a
fixed set `Names`, together with the stamp of the consultation it came from.
Filing closes that consultation.

A botanist who holds no open consultation of a sheet can't file on it. You
determine what you've looked at.

### Rule 4. The record is permanent

A slip once filed is never removed, never edited, and never re-stamped. Nothing
is expunged, and no sheet's consultation count ever falls. A herbarium sheet
accumulates its determination history and keeps every part of it, including the
determinations that later turn out wrong. The record only grows.

### Rule 5. The accepted name

The accepted name of a sheet is the name on its highest-stamped slip. A sheet
with no slips has no accepted name.

This is the fact the herbarium publishes. A flora, a loan request and a
conservation listing all key off the accepted name, so a wrong one travels a long
way before anyone catches it.

### Rule 6. Doubt

A botanist who holds an open consultation of a sheet can mark that sheet
doubtful. Marking a sheet doubtful says the accepted name needs looking at
again. It isn't itself a determination, so it doesn't close the consultation the
botanist holds.

A doubtful mark comes off when a slip is filed on that sheet, whoever files it.
That's the only way it comes off.

### Rule 7. What must happen, and what needn't

A botanist who has consulted a sheet eventually files a slip on it. That's the
one thing in this system that must happen, and it's what makes a doubtful mark
worth raising.

Nothing else is obliged. Nobody has to consult anything, nobody has to doubt
anything, and a sheet nobody has consulted can sit undetermined for as long as
the collection lasts.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **A sheet's record is well formed.** Every slip on a sheet carries a name from
   `Names` and a stamp from 1 up to that sheet's consultation count. No two slips
   on one sheet carry the same stamp. Every open consultation a botanist holds of
   a sheet carries a stamp in that same range. No sheet's consultation count is
   above that sheet's handling allowance.
2. **The accepted name is the top slip's name.** A sheet with slips on it has the
   name on its highest-stamped slip as its accepted name. A sheet with no slips
   has none.
3. **The record only grows.** From one moment to the next, no slip leaves a
   sheet, no slip on a sheet changes, and no sheet's consultation count falls.
4. **A slip comes from a consultation, and never from a later one.** At a step
   where a slip appears on a sheet, some botanist's open consultation of that
   sheet closes in the same step, and the new slip's stamp is at most the stamp
   that consultation carried.
5. **The accepted name moves only on a filing.** At a step where a sheet's
   accepted name changes, a slip appears on that sheet in the same step.
6. **A doubt clears only on a filing.** At a step where a sheet stops being
   doubtful, a slip appears on that sheet in the same step.
7. **A doubted sheet is eventually re-determined.** Whenever a sheet stands
   doubtful, it eventually stops standing doubtful.
8. **The opening.** At the opening every sheet has no slips, a consultation count
   of zero, and no accepted name. No sheet stands doubtful, and no botanist holds
   an open consultation of anything.

Items 1 and 2 are claims about a single state, so they're invariants. Items 3,
4, 5 and 6 each compare the record at two consecutive moments, so they constrain
steps and land as action properties. Item 7 is the one that needs "eventually",
and it's the only liveness obligation here. Item 8 is a condition on the opening
state, before any step runs.

The fairness that delivers item 7 sits on one botanist's filing step for one
sheet, and on no other action. A botanist who marks a sheet doubtful still holds
an open consultation of it, so their filing step is enabled from that moment and
stays enabled until they take it. Weak fairness on that one step is what forces
the mark off. Fairness over a disjunction of a botanist's actions would oblige
none of them, so the reference names the filing step alone. Consulting and
doubting carry no fairness, which is what leaves rule 7's second half true.

Every step rule above is a claim about the whole record from one moment to the
next, so items 3, 4, 5 and 6 are each subscripted over the whole of `Observe`
and never over one of its fields.

The type invariant is the reference author's. It's declared in the reference cfg
and it counts as one of the cfg lines. It's never a requirement the learner is
asked to produce, and nothing above stands in for it.

Each item breaks on a short finite trace over `Observe`, which is what §3.9
needs downstream. Item 1 falls in a single state, two slips on one sheet both
stamped 2. Item 2 falls in a single state, a sheet whose top slip carries one
name and whose accepted name is another. Item 3 falls on one step, a slip
vanishing off a sheet. Item 4 falls on one step, a slip stamped 2 appearing
where the only consultation that closed carried stamp 1. Item 5 falls on one
step, a consultation that moves the accepted name. Item 6 falls on one step, a
doubtful mark coming off with no slip appearing. Item 8 falls at the opening, a
sheet with a slip already on it. Item 7 is the one that needs a word about its
shape: its violating trace is a finite prefix, a botanist consults a sheet and
marks it doubtful, and then nothing more happens ever again. Each item is also
satisfied by an ordinary run of the system.

## 3. The observation operator

The operator is named `Observe`. Each field below is a fact about the collection
at the current moment, the kind a curator could read off the sheet and the
consultation register. The fields are given here as named facts, not as syntax.
The author renders them over whatever state they chose, one field per line, each
field an expression over the state.

**slips**: for each sheet, the slips filed on it, each slip a name and a stamp.
Needed for the record's shape (1), for what the accepted name has to agree with
(2), for permanence (3), for the way a slip gets onto a sheet (4), and as the
thing rules 5 and 6 look for in a step.

**consulted**: for each sheet, how many times it has been consulted so far.
Needed because it's the range every stamp lives in (1), because it never falls
(3), and because the opening starts it at zero (8).

**reading**: for each botanist and each sheet, the stamp of that botanist's open
consultation of that sheet, or a none marker when they hold none. Needed for the
stamp cap on a filing (4) and for the range clause (1).

**accepted**: for each sheet, the name the herbarium currently accepts, or a none
marker. Needed for the agreement rule (2) and for the rule about when it may move
(5).

**doubted**: for each sheet, whether it stands marked doubtful. Needed for when a
mark may come off (6) and for the obligation to answer it (7).

**Why the accepted name is its own field.** This is the one real decision in the
operator, so it gets said plainly. The accepted name has to be reportable as a
fact in its own right, and never as a reading of the slips. Derive it and
must-be-true 2 is true by construction, the learner writes `TRUE` in a costume,
and TLC passes it. So the accepted name is carried as a fact the filing step
sets, which means a step could in principle move it out of step with the slips.
Must-be-true 2 is what forbids that, and must-be-true 5 is what says which step
may move it at all.

**Why the reading is its own field, and it's the hard one.** What a botanist read
is a fact about the botanist, not about the sheet, and a model that skips it can
still report every other field correctly. It can't state must-be-true 4 at all.
It also can't express the failure this system is about, which is a botanist
filing a slip that was current when they read it and isn't current when it lands.
My read is that a learner who decides the reading isn't state builds a model that
passes everything and has nothing to say.

**What the fields do and don't constrain.** A field says what must be reportable
from the state, not what the state is. A model that keeps its books another way
must still be able to answer each question from its own state, and that's the
whole demand. Don't read `consulted` and `slips` as two structures the model must
store separately, and don't read the absence of a doubter field as a ban on
recording who raised a mark.

**Sufficiency walk.** The walk's test is which property constrains each rule,
never which field mentions it. A field can name a rule's subject while no
property grades the rule, and then the rule is loose. First, what each
must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 The record is well formed | slips, consulted, reading |
| 2 The accepted name is the top slip's | slips, accepted |
| 3 The record only grows | slips, consulted |
| 4 A slip comes from a consultation | slips, reading |
| 5 The accepted name moves only on a filing | slips, accepted |
| 6 A doubt clears only on a filing | slips, doubted |
| 7 A doubted sheet is re-determined | doubted |
| 8 The opening | all five |

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 The sheets | 8 for the opening. The fixed-set and one-specimen clauses ride the shape of every field, each of which is indexed by `Sheets`, so there's nowhere to record a sheet that isn't one |
| 2 Consultation | 1 for the stamp range and the handling allowance, 3 for the count never falling, 8 for the start at zero. The one-open-consultation clause rides `reading`'s shape, which holds one stamp per botanist and sheet and has nowhere to put a second |
| 3 Determination slips | 4 for the way in, in both halves. It forbids a slip appearing without a consultation closing, and it caps the stamp at what that consultation carried. 1's distinctness clause is what stops a second slip at a stamp already used |
| 4 The record is permanent | 3 |
| 5 The accepted name | 2 for what it is at every moment, 5 for the only step that may move it |
| 6 Doubt | 6 for the way out and 7 for the obligation. The precondition on raising a mark is graded by 7: a mark raised by a botanist holding no open consultation is one no fairness can answer, and 7 catches it |
| 7 What must happen | 7. What says nothing else must happen is that no other property here needs "eventually" |

One clause is ungraded and I'd rather name it than let a reader find it.
`Observe` shows the record, not the hands in it. "Every step is a botanist's"
can't be a property of any model, whatever fields you add, because the interface
has no place to report that a step had no author. Which botanist filed is
visible, since it's whose open consultation closed, and must-be-true 4 uses it.
Whether some step happened by itself is not.

Everything else is constrained. Every field earns its place through at least one
must-be-true, so nothing in the operator is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under a second. Every
bound below is a fact of the system first and a finiteness device second, and
each one already appears inside a rule the model must enforce as behavior.

- **`Sheets`**: the collection's own sheets. The config picks one instance.
- **`Botanists`**: the herbarium's own staff.
- **`Names`**: the names in play for these specimens. At least 2, or a
  re-determination can never change the accepted name.
- **`Handling`** (Rule 2): the conservation allowance per sheet. At least 2 on
  one sheet, or two botanists can't both hold a consultation of it and the lost
  determination this system is about can't happen.

**Suggested instance**: 2 sheets, 2 botanists, 2 names, with a handling allowance
of 2 on the first sheet and 1 on the second.

Each bound bites at these values. Two botanists is the least that lets one file
under the other. An allowance of 2 on the first sheet is the least that gives
them a stamp each. Two names is the least that lets a second determination say
anything new. The second sheet is there so the per-sheet rules have something to
be wrong about: a filing on one sheet must not move the other's accepted name,
and must not take the other's doubtful mark off. Its allowance of 1 keeps it
cheap, and a fragile sheet with a short allowance is an ordinary thing in a
collection.

The arithmetic. On the first sheet the consultation count runs 0 to 2. At a count
of 2 the reachable records are, as I count them, about 50, once you rule out the
combinations no run reaches. Add the count-1 and count-0 cases and I make the
first sheet about 60. The second sheet, capped at 1, is about 8. The two sheets
move independently, so I make the reachable total about 500. Under 1,000 with
room, and sub-second. That's an estimate. Nobody has run it. If it runs over,
drop the second sheet first, which costs the per-sheet checks above and keeps
everything else.

**Quiescence.** When every consultation is closed and every sheet has reached its
allowance, no action is enabled and the system stops. That's the intended end of
the story, not a fault. A checker reporting deadlock there is reporting the
design working, and the reference author should handle it in the config rather
than by inventing a stuttering action this system doesn't have.

## 5. Open forks

The learner writes the state here, so the forks are the problem rather than a
side note. Each line below is a choice the rules don't make, and an edit that
closes one is a regression rather than a tightening.

- **The slips on a sheet**: a set of records, a sequence, or a map from stamp.
- **The consultation register**: a count, or a run of events whose length it is.
- **The open consultation**: a stamp with a none marker, or a set of pairs.
- **The doubtful mark**: a set of sheets, or a yes-or-no per sheet.
- **The doubter**: recorded, or not. No rule needs it and a model may carry it.
- **The botanists**: one PlusCal process each with an `either`, or bare actions.
- **Names and sheets**: model values, or numbers.

The reading gate is ch11, so the reference ships as PlusCal in the c-syntax
dialect, and the Airlock drill is the shape to write at
(`exercises/ch11/references/Airlock.tla`).

**The reference carries five variables and they are the five `Observe` fields.**
No others. A sixth variable, a derived cache or a history the operator doesn't
expose, takes this rung's representation level from 2 to 3 and breaks it. If the
author finds they need one, that's a finding about this description and it should
come back rather than get built.

One fork I closed on purpose, and it's the one in section 3. The accepted name is
its own fact and is never derived from the slips. That's a real narrowing of the
author's freedom, and I think it's worth the cost, because the alternative hands
the learner a rule that can't be got wrong.

**Where I departed from the screener's sketch** (`reports/step0-screens.md`).

The sketch listed seven rules and I've shipped eight. Three changes, and one of
them is a hole I think the sketch left open.

I folded "no two slips carry the same stamp" into must-be-true 1 rather than
giving it its own line. It's a well-formedness fact about one sheet's record,
like the rest of item 1, and the cfg count has a hard ceiling at nine lines.

I added "a doubt clears only on a filing". Without it the liveness grades almost
nothing, because a model that lets a mark come off on any step satisfies "a
doubted sheet is eventually re-determined" for free. That's the hole.

I added the opening. A slip present at the opening is a way a slip gets onto a
sheet that nothing else grades, since item 4 only sees slips that appear in a
step. Rung 1's review was blocked on exactly that shape of gap.

Two smaller ones. The sketch's rule 5 was "a botanist never files a stamp above
the one they read", and I've made it the fuller way-in rule, so it also forbids a
slip appearing with no consultation behind it. And the sketch suggested three
botanists and two sheets with a uniform cap. I make that a few thousand reachable
states, which is over this rung's ceiling, so I've taken two botanists and a
per-sheet allowance instead. The allowance is domain-true either way.

## 6. Ambiguities resolved, and how they could have gone

1. **No calendar.** Order comes from the sheet's own consultation count. Real
   determination slips are dated. A date is a step this description assigns to no
   party, which takes step sources from 1 to 3 and breaks the rung outright.
2. **No loans.** No sheet leaves the herbarium. Loans between institutions are
   the normal working life of a collection, and a borrowing curator is a second
   kind of actor, which takes step sources from 1 to 2.
3. **Nomenclature is one rule.** The accepted name is the name on the top slip,
   and that's all. Real nomenclature has priority, synonymy, basionyms and types.
   Any of those is a second system sitting on top of this one.
4. **Nothing comes off a sheet.** A slip is never removed and never edited. Real
   herbaria annotate a slip they think is wrong, and the annotation is another
   slip. Retraction would kill the append-only heart of the domain.
5. **Handling is capped.** A sheet is withdrawn from consultation once its
   allowance is used. Without a cap the consultation count is unbounded and there
   is no finite instance to check.
6. **Anyone who consulted can file.** No curator countersigns. A countersigning
   curator is a second kind of actor, and it's the same cost as the loans above.
7. **One open consultation per sheet.** Consulting a sheet again replaces the
   stamp held. The alternative lets a botanist accumulate open consultations and
   file against any of them, which multiplies the state and asks nothing new.
8. **Doubt needs a reading.** You can only doubt a sheet you've looked at. If
   anyone could mark any sheet at any time, nobody would be on the hook for it,
   and there's no fairness on a botanist's step that delivers the obligation.
9. **Anybody's filing clears a mark.** Not only the doubter's. The alternative
   binds the mark to whoever raised it, which is a stronger obligation and one
   more clause on rule 6 for no new modeling question.
10. **A sheet with no slips can be marked doubtful.** It reads a little oddly and
    it costs nothing. Requiring an accepted name first is one more precondition
    that no property grades.
11. **The opening is bare.** Every sheet unconsulted and undetermined. Sheets
    arriving with determination histories already on them would push those
    histories into the config as per-sheet inputs.
12. **One sheet per specimen.** No duplicates at sister institutions. Duplicates
    are real and common, and they turn this into a replication problem, which is
    the burned neighbourhood this domain was chosen to stay out of.

## 7. The diagnose object, central only

Shape D at representation 2. The learner models the system from the statement,
then is handed a green TLC run and has to say why the green is worth nothing.

**The seeded defect.** Must-be-true 5, the accepted-name rule, ships subscripted
over the doubtful marks instead of over the whole of `Observe`.

**Why it passes.** A consultation never touches a doubtful mark, so every
consultation is a stutter for that formula and the rule is true on it without
being looked at. The consultation is the step that moves the accepted name in a
wrong model, which makes it the step the rule was written for. A filing on a
sheet nobody has marked stutters past as well. What's left is the marking steps
and the filings that take a mark off, and none of that is where the rule bites.
TLC returns green and reports no violation, because there was nothing to violate.

**Why the wrong subscript looks right.** Must-be-true 6 sits next to it and is a
rule about the doubtful marks, where subscripting over the marks is sound. The
defect is the neighbour's subscript copied one rule up. I think that's what makes
it a fair thing to seed rather than a trick. It's the mistake the layout invites.

**Why a learner who modelled the system right catches it.** They know the accepted
name moves on a filing and on nothing else, so they know which steps rule 5 has
to see. Reading off which steps the shipped subscript lets through is then
mechanical. A learner who modelled it wrong has no way in. In particular, one who
derived the accepted name from the slips has a rule that's true by construction,
and for them the subscript never mattered in the first place. That's the same
decision section 3 closed, arriving a second time as the thing that decides
whether the diagnosis is reachable.

**The live alternative, and where it wins.** Ship a failing trace instead. Have
the filing step write the accepted name without keeping it in step with the
slips, so a botanist filing at stamp 1 after one who filed at stamp 2 drags the
accepted name backwards and breaks must-be-true 2. That's two botanists and about
six steps, and it's the more readable object by a distance. The world it wins in
is the one where the learner bounced off rung 3, which is the batch's other shape
D, and needs a diagnosis they can finish. It teaches less, because reading that
trace never requires thinking about a subscript. I'd take the vacuous pass, since
this rung's one new high is the open subscript and the defect and the new high
are then the same thing.
