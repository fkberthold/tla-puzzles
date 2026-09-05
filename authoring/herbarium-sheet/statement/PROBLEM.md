# Determination slips on a herbarium sheet

A modeling problem, then a diagnosis. Plan on 20 to 40 minutes if you've read
the learntla core chapters.

A herbarium is a collection of pressed, dried plants. Each specimen is glued
to one sheet of card, and the sheet is the object of record. Naming the
specimen is called determining it, and a botanist who determines a sheet says
so on a small slip of paper attached to the sheet. The slip carries the name
they believe it is, and where in the sheet's history they read it.

You don't need any botany beyond what's written here.

## What you get

- This statement. It fixes the system and the seven things a correct model
  has to satisfy.
- `traces/`: seven pairs of runs. One run of each pair follows the rules and
  one breaks them.
- One of the seven requirements, already written as a formula, in the last
  section.

No spec ships. The model is yours to write.

## Your task

1. Model the herbarium below, in PlusCal or TLA+, in a module named
   `Herbarium`.
2. Define `Observe`, the operator described under the interface.
3. Write requirements 1 to 4, 6 and 7 as formulas over `Observe`, declare
   them in a `.cfg` under the keywords named with them, and run TLC on the
   checking instance until they all hold.
4. Add the formula from the last section, declare it too, and run again.
5. Hold your model against the traces. Every allowed run must be a run your
   model can produce. For each forbidden run, work out which of your
   requirements breaks on it, and say so if none does.
6. Then answer the last section's two questions in writing.

## The system

**The parties.** One kind, and several of them. A fixed, finite set of
botanists, named by `Botanists`. Every step in this system is some
botanist's. Nothing else acts. There's no clock, no calendar, and no event
that happens on its own.

Nothing coordinates the botanists. Any one of them can take a step between
any two steps of another.

### Rule 1. The sheets

`Sheets` is a fixed, finite set, named up front. One specimen to a sheet,
glued down. Sheets are never added, removed, split, or merged, and no
specimen appears on two of them.

The herbarium opens with every sheet bare. Nothing has been consulted, no
slip is attached to anything, no sheet has an accepted name, and no sheet
stands doubtful.

### Rule 2. Consultation, and the only order there is

A botanist consults a sheet by taking it to the bench and studying it. Every
sheet carries a consultation register, and the register's whole content is a
count of how many times this sheet has been consulted. A consultation adds
one to that count and hands the botanist that new number as the stamp of
their consultation.

That count is the only order this system has. Nothing here is dated. Two
botanists working the same sheet are ordered by which of them consulted it
first, and by nothing else.

Handling damages a pressed specimen, so the herbarium caps it. Each sheet has
a handling allowance, `Handling`, which is the number of consultations it can
take before it's withdrawn from consultation. Allowances differ by sheet,
because a bracken frond stands more handling than an orchid. A withdrawn
sheet takes no further consultations. Anyone who already holds an open
consultation of it can still file on it.

A botanist's consultation of a sheet stays open until they file a slip on
that sheet. Consulting the same sheet again replaces the stamp they hold with
the new one, and the old stamp is gone. A botanist can hold open
consultations of several sheets at once, one per sheet.

### Rule 3. Determination slips

A botanist who holds an open consultation of a sheet can file a determination
slip on it. The slip carries the name they believe the specimen is, drawn
from a fixed set `Names`, together with the stamp of the consultation it came
from. Filing closes that consultation.

A botanist who holds no open consultation of a sheet can't file on it. You
determine what you've looked at.

### Rule 4. The record is permanent

A slip once filed is never removed, never edited, and never re-stamped.
Nothing is expunged, and no sheet's consultation count ever falls. A sheet
accumulates its determination history and keeps every part of it, including
the determinations that later turn out wrong. The record only grows.

### Rule 5. The accepted name

The accepted name of a sheet is the name on its highest-stamped slip. A sheet
with no slips has no accepted name.

This is the fact the herbarium publishes. A flora, a loan request and a
conservation listing all key off the accepted name, so a wrong one travels a
long way before anyone catches it.

### Rule 6. Doubt

A botanist who holds an open consultation of a sheet can mark that sheet
doubtful. Marking a sheet doubtful says the accepted name needs looking at
again. It isn't itself a determination, so it doesn't close the consultation
the botanist holds.

A doubtful mark comes off when a slip is filed on that sheet, whoever files
it. That's the only way it comes off.

### Rule 7. What must happen, and what needn't

A botanist who has consulted a sheet eventually files a slip on it. That's
the one thing in this system that must happen, and it's what makes a doubtful
mark worth raising.

Nothing else is obliged. Nobody has to consult anything, nobody has to doubt
anything, and a sheet nobody has consulted can sit undetermined for as long
as the collection lasts.

## The interface

Your model defines one operator, `Observe`, a record with five fields.
Grading reads `Observe` and nothing else. Your variables never leave your
module. Pick whatever state you like, in whatever shape you like, and render
these five facts from it.

- **slips**: for each sheet, the slips filed on it.
- **consulted**: for each sheet, how many times it has been consulted so far.
- **reading**: for each botanist and each sheet, the stamp of that botanist's
  open consultation of that sheet.
- **accepted**: for each sheet, the name the herbarium currently accepts.
- **doubted**: for each sheet, whether it stands marked doubtful.

The shapes are fixed, because grading compares values. A renamed field, a
sixth field, or a different spelling doesn't fail a check. It keeps the check
from ever running.

- `Observe.slips` is a function from `Sheets` to sets of slips. A slip is a
  record with two fields, `name` and `stamp`, spelled that way. The set is
  the shape of this field whatever you store underneath, so a sequence or a
  map from stamp computes it and answers with that.
- `Observe.consulted` is a function from `Sheets` to naturals.
- `Observe.reading` is a function from `Botanists` to functions from `Sheets`
  to a stamp or the none marker.
- `Observe.accepted` is a function from `Sheets` to a name or the none
  marker.
- `Observe.doubted` is a function from `Sheets` to `BOOLEAN`.

**The none marker.** Three fields have an empty case. `slips` answers with
the empty set for a sheet nobody has determined. `reading` and `accepted`
answer with one marker, a single value that sits outside `Names` and outside
the stamps, and it's the same value in both. Declare it as a constant and set
it to a model value in your `.cfg`. That way a comparison against a stamp or
against a name answers false instead of stopping TLC dead. A string sitting
beside a number in one of these fields will stop it dead.

**The accepted name is a field and not a reading of the slips.** Carry it as
a fact your filing step sets. Derive it from the slips instead and
requirement 2 below is true by construction, so you'd have written `TRUE` in
a costume and TLC would pass it.

What a botanist read is a fact about the botanist rather than about the
sheet, and `reading` is where it lives. A model that leaves it out can still
report the other four fields correctly. It can't state requirement 4 at all,
and it can't express the failure this system is about, which is a botanist
filing a slip that was current when they read it and isn't current when it
lands.

## What must be true

Seven requirements. Each is a claim about every run of this herbarium, and a
correct model satisfies all seven. They must hold for any sheet set, any
botanist set, any name set, and any allowances.

Each requirement names the TLC keyword it goes under and what kind of formula
it is. Where a requirement constrains steps, it also says what its subscript
watches. One subscript is left to you, and it's marked.

1. **A sheet's record is well formed.** Every slip on a sheet carries a name
   from `Names` and a stamp from 1 up to that sheet's consultation count. No
   two slips on one sheet carry the same stamp. Every open consultation a
   botanist holds of a sheet carries a stamp in that same range. No sheet's
   consultation count is above that sheet's handling allowance.

   `INVARIANT`. A claim about a single state.

2. **The accepted name is the top slip's name.** A sheet with slips on it has
   the name on its highest-stamped slip as its accepted name. A sheet with no
   slips has none.

   `INVARIANT`. A claim about a single state.

3. **The record only grows, one consultation at a time.** From one moment to
   the next, no slip leaves a sheet, no slip on a sheet changes, and no
   sheet's consultation count falls. At a step where a sheet's consultation
   count rises, it rises by exactly one, and one botanist's open consultation
   of that sheet becomes that new number. A botanist's open consultation of a
   sheet takes a stamp only at a step where that sheet's count rises to that
   stamp.

   `PROPERTY`. An action property. **The subscript is yours to choose**, and
   it's worth choosing with care.

4. **A slip comes from a consultation, and never from a later one.** At a
   step where a slip appears on a sheet, one slip appears, some botanist's
   open consultation of that sheet closes in the same step, and the new
   slip's stamp is at most the stamp that consultation carried. At a step
   where a botanist's open consultation of a sheet closes, a slip appears on
   that sheet in the same step.

   `PROPERTY`. An action property, subscripted over the whole of `Observe`.

5. **A doubt clears only on a filing.** At a step where a sheet stops being
   doubtful, a slip appears on that sheet in the same step.

   `PROPERTY`. An action property. This one arrives written for you, in the
   last section. Don't write your own.

6. **An open consultation is eventually answered.** Whenever a botanist holds
   an open consultation of a sheet, that consultation eventually closes.
   Whenever a sheet stands doubtful, it eventually stops standing doubtful.

   `PROPERTY`. A claim that something eventually happens. The two clauses
   conjoin under one name and go on one line of your `.cfg`.

7. **The opening.** At the opening every sheet has no slips, a consultation
   count of zero, and no accepted name. No sheet stands doubtful, and no
   botanist holds an open consultation of anything.

   `PROPERTY`. A state predicate, declared as a property rather than as an
   invariant, so TLC reads it at the opening state alone. TLC prints a
   paragraph recommending `INVARIANT` when it reads one under `PROPERTIES`,
   and that's expected here rather than a fault of yours.

Seven is the whole list. Don't add an eighth. Your model's own typing is
yours and doesn't count against that, so declare a type invariant as well if
you want one.

Two of the rules above go ungraded, and I'd rather name them than let you
hunt. `Observe` shows the record, not the hands in it. Whether a step had an
author at all is invisible at this interface, so "every step is a botanist's"
can't be a property of any model, whatever fields you add. And rule 3 says a
slip carries the stamp of the consultation it came from, where requirement 4
grades only that it's at most that stamp. A botanist who files below the
stamp they hold passes the cap. That cap stays a cap on purpose.

### Requirement 6 needs fairness, and fairness needs a target

A formula saying every open consultation eventually closes is false over a
system that lets a botanist sit on one forever. It should be false there.
Rule 7 says they can't, so your `Spec` has to say it too, with fairness.

Which step carries the fairness is yours to work out. Start from the
obligation and find the step that meets it.

Weak fairness on your whole next-state relation isn't what rule 7 means.
Rule 7 names one thing that must happen and then says nothing else is
obliged. Blanket fairness obliges the lot.

## The traces

The `traces/` directory holds one pair per requirement, seven in all. Each
file carries two runs, rendered over the five `Observe` fields at the
checking instance.

- **A run the herbarium can produce.** Your model must be able to produce it.
- **A run the rules forbid.** Your model must rule it out, and your
  requirement set must break on it.

Each row of a trace is one moment, the value of `Observe`. Consecutive rows
are one step apart. Slips are written `n1 at 1`, meaning the name `n1`
stamped 1, and a sheet with no slips reads `{}`. The none marker is written
`none`.

Two notes on reading them. A forbidden run can break more than one
requirement, and if your set rejects it for any requirement it breaks, your
set is right about that run. And where a forbidden run's fault is that
nothing more ever happens, the trace says so under its last state.

## Checking

The checking instance is two sheets, two botanists and two names. The sheets
are numbered 1 and 2, and sheet 1 has a handling allowance of 2 against sheet
2's 1.

```
Sheets    = {1, 2}
Botanists = {b1, b2}
Names     = {n1, n2}
```

Two botanists is the least that lets one file under the other. An allowance
of 2 on sheet 1 is the least that gives them a stamp each. Two names is the
least that lets a second determination say anything new. Sheet 2 is there so
the per-sheet rules have something to be wrong about, since a filing on one
sheet must not move the other's accepted name and must not take the other's
mark off. Its allowance of 1 keeps it cheap.

TLC's config format won't take a function written out, so `Handling` needs an
operator in your module to point at. Define one that gives sheet 1 an
allowance of 2 and sheet 2 an allowance of 1, and set the constant with
`Handling <- <your operator>`.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite its
name it turns the check off. When every consultation is closed and every
sheet has reached its allowance, nothing is enabled and the system stops.
That's the intended end of the story rather than a fault.

A model whose state is exactly the five facts `Observe` reports finds 259
distinct states here, from 1,103 generated, at a search depth of 7. It runs
in well under a second. Keep state beyond those five facts and your counts
come out larger, which isn't wrong by itself. If your state is just the five
facts and your count isn't 259, your rules differ from the rules above, and
that difference is worth finding before you go on. The check runs one way
only. More than one wrong rule set lands on 259 exactly, so a match doesn't
tell you your rules agree with these. Check the 1,103 too. That's the sharper
of the two.

## The rule that came written for you

Requirement 5 arrives written. Put it in your module and declare it under
`PROPERTIES` in your `.cfg`, alongside the six you wrote yourself.

```tla
DoubtClearsOnlyOnFiling ==
    [][\A s \in Sheets :
          (/\ Observe.doubted[s] = TRUE
           /\ Observe'.doubted[s] = FALSE)
              => Observe'.slips[s] \ Observe.slips[s] # {}]_(Observe.slips)
```

Run against a correct model of this system at the checking instance, TLC
returns OK on it. No violation, nothing reported:

```
Model checking completed. No error has been found.
1103 states generated, 259 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 7.
```

The claim on the table is that requirement 5 is now checked.

Answer two questions in writing:

1. What does that green run establish about your model?
2. What does it fail to establish, and why?

Then make your answer stick with evidence. A run and its numbers count. A
check of your own, with its verdict, counts. So does a behavior these rules
forbid that the formula above can't see, shown step by step. An answer with
none of those is an opinion.
