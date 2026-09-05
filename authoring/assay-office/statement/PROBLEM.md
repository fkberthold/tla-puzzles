# The assay office

Silver and gold wares are made of alloy, not of the pure metal. Fineness is
how much precious metal the alloy holds, as a proportion of the whole. The
law fixes a minimum, and a ware has to be tested against it before anyone can
sell the ware as silver or gold. The place that does the testing is an assay
office. You have the model of one office, finished and working. What it
doesn't have is properties. Nothing in it says what must be true. Your job is
to say it, in TLA+, and check it.

You don't need to know the trade. Every rule the office follows is stated
below.

## What you get

- `AssayOffice.tla`: the model. The constants, the algorithm, the
  translation, `Observe`, and two definitions of the spec.
- `traces/`: pairs of runs. In each pair, one run follows the rules and one
  breaks them.

## Your task

Write three properties over `Observe`, in `AssayOffice.tla`, and a `.cfg`
that declares them. The requirements below name all three. Each one tells you
the TLC keyword to declare it under, what kind of formula it is, and what to
subscript it over where that applies. The formula itself is yours.

1. Read the module. Work out how it carries the nouns the rules use.
2. Write each requirement as a formula over `Observe`.
3. Declare each one under the keyword its requirement names.
4. Run TLC. The model must satisfy all three.
5. Hold your three against the traces. Every forbidden run must break at
   least one. Every allowed run must break none.

## The system

**The parties.** One kind. A fixed, finite set of **assay officers** work at
one office. They're interchangeable, so any officer can do any of the
office's work on any ware. Every step in this system belongs to one of them.
Nothing else acts. There's no clock, no calendar, and no event that happens
on its own. The officers don't coordinate, so any officer's next step can
land between any two of another's.

The makers who lodged the wares are outside this system. They don't act in
it.

### Rule 1: the wares

The set of wares is fixed and finite, named up front. Every ware is one
article, lodged at the office before the story opens. A ware is whole. It's
never split, never merged with another, and never renamed. Nothing arrives
after the opening, and nothing joins the set.

At the opening every ware is untested, unmarked and undefaced.

### Rule 2: testing, and the finding

An officer can test a ware the office hasn't tested. The test yields a
**finding**, and there are two of them. The ware is at standard, or it's
substandard. The office writes the finding down against that ware.

A ware is tested once. The finding is the office's word on that ware and it
stands. There's no re-assay, no second opinion, and no appeal. This system
never asks whether the finding is right, so the finding is simply what the
office found.

### Rule 3: striking the hallmark

A ware that meets the standard is struck with the **hallmark**, a set of
punches that says so. An officer can strike the hallmark on a ware the office
found at standard. Only such a ware. An untested ware is never struck, and
neither is one the office found substandard. A struck ware carries the mark
from then on, and there's no way to take it off.

### Rule 4: defacing

A ware that falls short is **defaced**, which means the office damages it so
it can't be sold as it stands. An officer defaces a ware the office found
substandard. Only such a ware. A ware found at standard is never defaced, and
neither is an untested one. Defacing is permanent, the same way the mark is.

Writing the finding down and acting on it are two motions. A ware can sit
with a substandard finding against it and its body still whole, and the
office can leave it there a while.

This is the one thing in the system that must happen. The office isn't
allowed to write down a substandard finding and then sit on the ware.
Handing back a substandard ware whole and unmarked is the thing the whole
institution exists to stop. So a ware the office found substandard gets
defaced, sooner or later.

### Rule 5: nothing else has to happen

The office is under no duty to test anything. An officer works when they
choose. A ware can lie untested for the whole story, and a ware found at
standard can go unstruck forever. Rule 4's is the only obligation here, and a
finding creates it rather than a deadline.

### Rule 6: nothing leaves

The story is the office's own bench. What becomes of a ware after the office
is done with it sits outside this system. Nothing is collected, returned, or
taken away, and no step takes a ware out of the set.

## The interface

`AssayOffice.tla` defines `Observe`, and `Observe` is the office's whole
public face:

- **finding**: for each ware, what the office found. At standard,
  substandard, or nothing yet if the office hasn't tested it.
- **marked**: for each ware, whether the hallmark has been struck on it.
- **defaced**: for each ware, whether the ware has been defaced.

The module has its own name for each of the three findings, and the field
holds that name rather than the English above. Read the module to find out
what it calls them.

State every property over `Observe`. Grading reads `Observe` and nothing
else.

## The requirements

Three of them. Each one says which keyword to declare it under and what kind
of formula it is. Write the formula yourself.

### Requirement 1: the mark and the defacing follow the finding

A ware carries the hallmark only if the office found it at standard. A ware
is defaced only if the office found it substandard. So no ware is both struck
and defaced.

This is a claim about a single state, so write it as a state predicate.
Declare it under `INVARIANT`.

### Requirement 2: the record only grows

A finding once written down never changes and never clears. A struck ware
stays struck. A defaced ware stays defaced.

This compares a ware's record at two consecutive moments, so it's an action
property. Write it in the form `[][A]_Observe` and declare it under
`PROPERTY`.

Subscript it over the whole of `Observe`, never over one of its fields. A
step rule watched over a single field is satisfied for free by any step that
changes only the other fields. TLC won't warn you. The property just stops
seeing the steps it was written about.

### Requirement 3: a substandard finding is discharged

A ware the office found substandard is eventually defaced.

This one needs "eventually". It's a temporal formula rather than an action
property, so it carries no subscript at all. Declare it under `PROPERTY`.

**Where the obligation comes from.** A next-state relation says which steps
are allowed. It never says which have to be taken, so nothing in `Next` can
carry rule 4's duty. That's why the module defines the spec twice. `Spec` is
the office that may act. `FairSpec` is `Spec` and a fairness conjunct on top,
and the conjunct is what makes the office act. Read `FairSpec` to see which
step it obliges and what the obligation is quantified over.

Your `.cfg` declares `SPECIFICATION FairSpec`. Name `Spec` there instead and
requirement 3 fails, because without the conjunct a run where an officer
writes a substandard finding and then the office stops forever is a run of
the model. That failure is real. It isn't a fault in your formula.

## The traces

The runs under `traces/` witness the requirements. Six pairs, and the mapping
isn't one to one. Requirement 1 gets two, requirement 2 gets three, and
requirement 3 gets one. Each state shows the three `Observe` fields. Four
notes:

- A forbidden run can break more than one requirement. If your set rejects it
  for any requirement it breaks, your set is right about that run.
- Every run shown is finite. Requirement 3's forbidden run breaks its rule by
  what never happens after the last state, and the trace says so under it.
- The findings print in the rules' English, not in the module's own names.
- The allowed runs are behaviors of `AssayOffice.tla`. The forbidden runs are
  not. They exist to pin down what your properties must reject.

## Checking

Use the instance the traces use:

```
Wares = {w1, w2, w3}
Officers = {o1, o2}
```

Your `.cfg` declares `SPECIFICATION FairSpec`, the two constants, and your
three properties under the keywords the requirements name.

Turn deadlock checking off. Put `CHECK_DEADLOCK FALSE` in your `.cfg`, or
pass TLC the `-deadlock` flag, which despite its name turns the check off.
Once every ware has been tested, every at-standard ware struck and every
substandard ware defaced, no action is enabled and the run stops. That's the
story ending, not a fault.

Whatever properties you declare, the run should find 125 distinct states. A
different count means the system half of the module changed, and that half
isn't yours to change.
