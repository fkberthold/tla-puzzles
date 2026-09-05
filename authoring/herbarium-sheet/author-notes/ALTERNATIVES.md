# Alternatives considered (herbarium-sheet reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

Five variables, one per `Observe` field, and `Observe` renders as the identity
over them. `slips` maps a sheet to a set of `[name, stamp]` records,
`consulted` maps a sheet to a count, `reading` maps a botanist and a sheet to a
stamp or the none marker, `accepted` maps a sheet to a name or the marker, and
`doubted` maps a sheet to a boolean. The state is the interface, which is what
this rung asks for.

## Slips as a sequence, or as a map from stamp to name

The strongest rival, and the one the description invites by saying a sequence
or a map computes the field. A map from stamp to name gives distinctness for
free, since a function has one value per point, and it makes the accepted name
a lookup at the largest key.

I rejected it because distinctness is a graded requirement here, not a
housekeeping detail. Must-be-true 1 says no two slips on one sheet carry the
same stamp, and under the map shape that clause can't fail inside the model. A
requirement the representation makes unfalsifiable is a requirement the
verifier can't seed a defect against, and the whole rung leans on seeded
defects. The set of pairs keeps the clause breakable, which is why the
description pins the field as a set and why I store it as one.

A sequence has the same problem from the other side. Position would carry the
order, so "the highest-stamped slip" turns into "the last one", and the stamp
stops doing any work.

## The accepted name derived rather than carried

Tempting, and wrong for the reason the description gives. Define `accepted` as
the top slip's name and must-be-true 2 becomes an identity. TLC passes it, the
learner has written `TRUE` in a costume, and nothing is graded.

So the filing step sets the name, and must-be-true 2 is what holds it to the
slips. The cost is real: a filing has to compute the top of the new slip set,
which is a `CHOOSE` over a set that's about to change. I think that cost is
worth paying to keep the property falsifiable. Mutant M3 files under the
filer's own name instead of the top slip's, and `AcceptedIsTopSlip` catches it,
so the property does lean on the choice.

## The reading as a per-botanist function, or as a set of open consultations

I kept `reading` as a function from botanist to sheet to stamp. The rival is
one set of `[botanist, sheet, stamp]` records, with an open consultation
present or absent rather than marked by the none marker.

The function won on two counts. Rule 2 caps a botanist at one open
consultation per sheet, and the function shape has nowhere to put a second, so
the clause rides the representation instead of needing a property. And the
none marker has to appear in `Observe` anyway for `accepted`, so the function
form costs nothing new at the interface. The set form would report an absent
consultation by absence, which reads differently from how `accepted` reports
one, and I'd rather the two empty cases look the same.

## The stamp a botanist holds, versus the stamp they read

Same field, two readings. I take `reading[b][s]` as the stamp of the
consultation that's still open, so filing clears it back to the marker and
re-consulting overwrites it. The rival keeps the last stamp forever and marks
openness with a separate boolean.

The rival loses because it splits one fact across two fields and the interface
only has room for one. Must-be-true 4 asks whether a consultation closed in a
step, which under the shipped shape is the field going to the marker. Under the
rival it's the boolean falling while the stamp sits still, and the stamp field
then reports history rather than the current moment. Every other field here
reports the current moment.

## Marking a sheet that's already doubtful

Unresolved in the description, so my call. `Doubt` is guarded on
`doubted[s] = FALSE`, so a second mark isn't a step.

The alternative is to let it fire and change nothing. That's a self-loop under
`Observe` with every variable unchanged, and it buys no reachable state and no
property. Neither reading is wrong about the herbarium, since marking a sheet
that's already marked is a no-op on paper too. I went with the guard because a
step that can't change the record is a step the model doesn't need, and
because the vacuity probe's dead-action check reads better when every action
in the module moves something. Anyone who wants the looser reading drops one
conjunct and nothing else moves.

## Handling as a per-sheet constant

Not a state question, but it forced a shape and it's worth recording. TLC's
config grammar takes model values, numbers, strings and sets of those. It won't
take a function literal, so `Handling = [s1 |-> 2, s2 |-> 1]` in the cfg dies
with a `ConfigFileException` at that line. I checked.

So `Handling` is a declared constant and the cfg overrides it with
`Allowances`, a definition in the module, which is the pattern
`authoring/river-call/reference/RiverCall.cfg` already uses for `Decree`.
Sheets are accession numbers rather than model values, because `Allowances`
has to tell them apart to give one an allowance of 2 and the other 1. A
herbarium sheet carries an accession number in real life, so I don't think
this reads as a modeling accident.

## Fairness

Weak fairness on `FileStep(b, s)`, quantified over every botanist and every
sheet. `FileStep(b, s)` is the existential over names, so the botanist has to
file something on that sheet, and which name they pick stays free.

The rival is one `WF_vars` over the whole filing step existentially quantified
over botanists too. That's the weaker assumption, and it's the one I took on
qsl. I expected it to be too weak here and wrote that down before I ran it.
It isn't. Probe M9 takes the single existential form and
`ConsultationIsAnswered` still passes, rc=0.

The reason is the handling allowance. It caps how many consultations a sheet
can take, so the whole run has finitely many filings in it. A botanist can't
file forever to starve another one out. Once every other action is disabled,
the single `WF` has only the pending filing left to fire, and it fires. Probe
M10 takes the middle form, per botanist but existential over sheets, and that
passes too, rc=0.

So at the suggested instance all three forms agree, and TLC can't tell them
apart. I kept the per-botanist-per-sheet form for two reasons. It's what the
description's classification paragraph names, and it's the reading that
survives a bigger instance: lift the allowance and the single-existential form
lets one botanist file forever while another's consultation sits open. I'd
rather the fairness say what the herbarium means than say the least that
passes here.

This is worth flagging on the way out. A seeded defect that weakens the
fairness form rather than removing it won't be caught at 2 sheets and 2
botanists. Only dropping the conjunct outright shows up, which is mutant M8,
and there `ConsultationIsAnswered` fails at rc=13.

Strong fairness would also work and would be a heavier assumption than the
system needs. Once a botanist holds an open consultation of a sheet, filing on
it stays enabled until they take it, so weak fairness already bites.

## Doubt as a set of doubters

No variable for who raised a mark. The description says the absence of a
doubter field isn't a ban on recording one, so I looked at it. Nothing grades
it: must-be-true 5 asks only when a mark may come off, and must-be-true 6 asks
only that it does. A doubter set would be state the interface can't show and
no property can constrain, which is the definition of decoration here.
