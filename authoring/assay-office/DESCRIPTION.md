# An assay office

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape B, in a situation of verdict and compelled act (S5). This
is rung 4 of batch 2, load vector 1 3 1 1 0 0, and property kind 3 is its single
new high. It's the first rung in the batch with an "eventually" in it, so
everything else here is written to stay quiet.

## 1. The system

Silver and gold wares are made of alloy, not of the pure metal. **Fineness** is
how much precious metal the alloy holds, as a proportion of the whole. The law
fixes a minimum. Before a ware can be sold as silver or gold it goes to an
**assay office**, which tests it against that minimum and marks the result. A
ware that meets the standard is struck with the **hallmark**, a set of punches
that says so. A ware that falls short is **defaced**, which means the office
damages it so it can't be sold as it stands. The office gets no say in that
second one. Nothing below needs any knowledge of the trade that isn't stated
here.

**The parties.** One kind. A fixed, finite set of **assay officers** work at one
office. They're interchangeable, so any officer can do any of the office's work
on any ware. Every step in this system belongs to one of them. Nothing else
acts. There's no clock, no calendar, and no event that happens on its own. The
officers don't coordinate, so any officer's next step can land between any two
of another's.

The makers who lodged the wares are outside this system. They don't act in it.

### Rule 1. The wares

`Wares` is a fixed, finite set, named up front. Every ware is one article,
lodged at the office before the story opens. A ware is whole. It's never split,
never merged with another, and never renamed. Nothing arrives after the opening,
and nothing joins the set.

At the opening every ware is untested, unmarked and undefaced.

### Rule 2. Testing, and the finding

An officer can test a ware the office hasn't tested. The test yields a
**finding**, and there are two of them. The ware is at standard, or it's
substandard. The office writes the finding down against that ware.

A ware is tested once. The finding is the office's word on that ware and it
stands. There's no re-assay, no second opinion, and no appeal. This system never
asks whether the finding is right, so the finding is simply what the office
found.

### Rule 3. Striking the hallmark

An officer can strike the hallmark on a ware the office found at standard. Only
such a ware. An untested ware is never struck, and neither is one the office
found substandard. A struck ware carries the mark from then on, and there's no
way to take it off.

### Rule 4. Defacing

An officer defaces a ware the office found substandard. Only such a ware. A ware
found at standard is never defaced, and neither is an untested one. Defacing is
permanent, the same way the mark is.

Writing the finding down and acting on it are two motions. A ware can sit with a
substandard finding against it and its body still whole, and the office can leave
it there a while.

This is the one thing in the system that must happen. The office isn't allowed
to write down a substandard finding and then sit on the ware. Handing back a
substandard ware whole and unmarked is the thing the whole institution exists to
stop. So a ware the office found substandard gets defaced, sooner or later.

### Rule 5. Nothing else has to happen

The office is under no duty to test anything. An officer works when they choose.
A ware can lie untested for the whole story, and a ware found at standard can go
unstruck forever. The one obligation here is Rule 4's, and a finding creates it
rather than a deadline.

### Rule 6. Nothing leaves

The story is the office's own bench. What becomes of a ware after the office is
done with it sits outside this system. Nothing is collected, returned, or taken
away, and no step takes a ware out of the set.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **The mark and the defacing follow the finding.** A ware carries the hallmark
   only if the office found it at standard. A ware is defaced only if the office
   found it substandard. So no ware is both struck and defaced.
2. **The record only grows.** A finding once written down never changes and
   never clears. A struck ware stays struck. A defaced ware stays defaced.
3. **A substandard finding is discharged.** A ware the office found substandard
   is eventually defaced.

Item 1 is a claim about a single state, so it's an invariant, and it holds at the
opening as well as everywhere after. Item 2 compares a ware's record at two
consecutive moments, so it constrains steps and lands as an action property.
Item 3 needs "eventually". It's the one liveness obligation here, and everything
else in this description is written to stay out of its way.

Item 3 is true only because `Spec` carries a fairness conjunct, and where that
conjunct sits decides whether the reference is correct. It goes on the defacing
step, one conjunct per officer, over that officer's defacing action and nothing
else. Weak fairness over a disjunction of an officer's actions obliges none of
them, so an officer who tests wares forever and never defaces satisfies it, item
3 fails, and the reference is wrong. My read is that the safe form reaches the
individual ware as well as the individual officer. The coarser form, weak
fairness on "this officer defaces something", happens to work here, because
defacing is permanent and the set of wares is finite, so each step shrinks what's
pending. I'd not spend the argument. Write the conjunct per officer and per ware.

Item 2's subscript is the whole of `Observe`, never one of its fields. Any other
step rule the author reaches for takes the same subscript. Item 3 carries no
subscript at all, because it's a temporal formula and not an action property.

The type invariant is the reference author's. It's declared in the cfg, it's the
fourth of the four lines there, and it's never a requirement the learner is asked
to write.

Each item breaks on a short trace, which is what §3.9 needs downstream. Item 1
falls in a single state, an untested ware carrying the hallmark. Item 2 falls on
one step, a ware whose finding goes from substandard to at standard. Item 3
needs a prefix and a tail. A ware is tested, the finding is substandard, and from
that state on nothing more happens, ever. That last clause is the whole
violation, and it has to be said in so many words, because the prefix on its own
is an ordinary run of the system.

Three is the cap and not a target I stopped short of. With the type invariant
that's four cfg lines, and four is as many as this problem gets.

## 3. The observation operator

The operator is named `Observe`. Each field is a fact about a ware right now, the
kind an officer could read off the office's own book. The fields are given here
as named facts, not as syntax. The author renders them over whatever state they
chose, one field per line.

**finding**: for each ware, what the office found. At standard, substandard, or
none if the office hasn't tested it. All three must-be-trues read it, and without
it none of them can be stated at all.

**marked**: for each ware, whether the hallmark has been struck on it. Needed for
items 1 and 2.

**defaced**: for each ware, whether the ware has been defaced. Needed for items
1, 2 and 3.

**Why the mark and the defacing are two fields.** This is the one real decision
in the operator, so it gets said plainly. A model could carry one field with
values like unmarked, struck and defaced, and then item 1's no-both clause is
true by construction. The learner writes `TRUE` in a costume and TLC passes it.
So the mark and the defacing are two facts the officers' actions set on their
own, which means a step could in principle strike a ware that's already defaced.
Item 1 is what forbids that. The same trap catches any pair of facts where one
is a reading of the other.

**What the interface doesn't show.** Hands. Which officer tested a ware, and
which one struck or defaced it, is invisible here, and no property depends on it.
There's no field for the bench either, so a model that carries a per-officer work
queue and one that skips straight to the actions produce the same observations.
Under `Observe`, an officer picking a ware up is stutter.

**Sufficiency walk.** The test in each row is which property constrains the rule,
never which field mentions it. A rule a field names and no property constrains is
ungraded. First, what each must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 The mark and the defacing follow the finding | finding, marked, defaced |
| 2 The record only grows | finding, marked, defaced |
| 3 A substandard finding is discharged | finding, defaced |

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 The wares | 1 at the opening, which forbids a ware that starts marked or defaced with no finding. The fixed-set and whole-ware clauses ride `Wares` being a constant and `Observe` being total over it. The untested-at-the-opening clause is `Init`'s, and the prose under this table says why no property grades it |
| 2 Testing and the finding | 2. A finding goes from none to a verdict once and never moves again |
| 3 Striking the hallmark | 1 for which ware may be struck, 2 for the mark being permanent |
| 4 Defacing | 1 for which ware may be defaced, 2 for the permanence, 3 for the duty itself |
| 5 Nothing else has to happen | Nothing, and that's how it's graded. It's the absence of an obligation, and what carries it is that item 3 is the only liveness property here |
| 6 Nothing leaves | Nothing. There's no exit step to grade, and the field set has nowhere to record a departure |

Two things are ungraded above, and I'd rather name them than let a reader find
them.

The first is the rest of the opening. Item 1 catches a ware that starts marked or
defaced with no finding, and it catches nothing else. An `Init` that starts a
ware already tested satisfies all three items. The spec ships complete and the
learner reads `Init`, so the hole costs the learner nothing here. A fourth item
pinning the opening would make five cfg lines, and four is this problem's cap. I
took the cap over the coverage, and I think that's the right trade.

The second is the order of the test and the strike. Rule 3 says the office finds
a ware at standard before it strikes it. Item 1 is a state predicate, so one step
that writes the finding and strikes the mark together satisfies it, and the
in-between state simply never exists. A model that fuses the two produces the
same `Observe` traces as one that separates them, minus a state, so the fusion is
close to observationally vacuous.

That licence covers the test and the strike, and nothing else. Rule 4 keeps the
finding and the act apart, so a step that tests a ware and defaces it in the same
motion isn't a fusion this system allows. It makes item 3 true with the fairness
conjunct dropped, which turns the rung's one new high into decoration.

Every field earns its place through at least one must-be-true, so nothing in the
operator is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under a second, with
liveness on.

- **`Wares`**: the office's own lodged set, not a device for keeping the model
  finite. The config picks one instance and the rules hold for any.
- **`Officers`**: the office's staff. At least 2, so the interleaving is real.
- **Two findings** (Rule 2): fixed by the rules, not by the config.
- **The mark as a yes or no** (Rule 3): the system asks whether a ware is struck,
  never with how many punches.

**Suggested instance**: 3 wares, 2 officers. Three wares is the least that puts a
ware in each of three outcomes at once, one untested, one struck, one defaced.
That's the observation where item 1 bites in both of its directions at the same
time. Two officers is what the rung asks for. Step sources 1 is several actors of
one kind, read off the statement's parties list. No `Observe` field names an
officer, so a one-officer run and a two-officer run produce the same observations,
and the second officer is here for the load vector rather than for anything the
interface can see.

The arithmetic. A ware's record is a finding from three values, a mark from two,
and a defacing from two, so 12 records in the type space and 1,728 at three
wares. Item 1 cuts each ware to five live records: untested, at standard and
unstruck, at standard and struck, substandard and undefaced, substandard and
defaced. That's 125 combinations, and at bare actions 125 is the whole
reachable count. A `while TRUE` loop with one label each holds `pc` constant, so
a process set costs nothing on top of it. A per-officer local holding a chosen
ware does cost: it multiplies by four an officer, which is 2,000 at three wares
and two officers, over the 1,000 that state space 0 allows. So keep each officer
process to one label with no per-officer local, or record the measured count and
re-place the dimension. Under 1,000 and sub-second with room. That's an estimate.
Nobody has run it.

**Quiescence.** When every ware has been tested and dealt with, no action is
enabled and the system stops. That's the intended end of the story, not a fault.
It matters more here than in a system with only safety properties, because TLC
reports the deadlock before it ever gets to item 3. The reference author should
handle that in the config rather than by inventing a stuttering action this
system doesn't have.

## 5. Open forks

At representation 1 the learner writes no state, so the forks here are the
reference author's alone. Each line is a choice the rules don't make.

- **The finding**: a value per ware, or two sets of wares.
- **The mark**: a flag per ware, or the set of struck wares.
- **The defacing**: the same two shapes.
- **The officers**: a PlusCal process set with an `either`, or bare actions.
- **Ware names**: model values, or numbers.

The reading gate is ch11, so the reference ships as PlusCal in the c-syntax
dialect, and the Airlock drill is the shape to write at
(`exercises/ch11/references/Airlock.tla`).

**The spec's variables must not be the `Observe` field names.** §3.3 makes
`Observe` the graded interface, and the point of shape B is that the learner
reads a spec and writes properties over that interface. Name the variables
`finding`, `marked` and `defaced` and the learner never crosses from state to
interface, because the two are the same word. I'd name them differently and let
the `Observe` definition do the crossing.

**The fork I closed on purpose** is the one in section 3. The mark and the
defacing are two facts and never one three-valued stage. That's a real narrowing
of the author's freedom, and I think it's worth the cost, because the alternative
hands the learner a rule that can't be got wrong.

**What I changed from the screener's sketch.** Four things, with the reasons.

The screener proposed "no ware both struck and defaced" as the first rule. I
strengthened it to tie both facts to the finding. The weak form leaves the two
frauds this institution exists to stop entirely ungraded, an untested ware
carrying the hallmark and a ware found at standard destroyed. The strong form
catches both, and no-both falls out of it, since a ware has one finding.

The screener proposed "a finding once recorded never changes" as the second. I
widened it to the whole record. The narrow form doesn't catch an erased mark or
an undone defacing, and both are steps the rules forbid.

The screener's party sketch had officers take a ware up and give it back. I cut
both steps. Section 6 item 1 carries the reason, and it's the liveness.

The screener folded "only a struck ware carries a mark" into the type invariant.
I moved it into item 1. A type invariant says what shape a value has. A stated
relation between two facts is a predicate, and a predicate is a property or it's
nothing.

**A note for the variant pass.** Both of section 3's ungraded items are mutants
nobody can catch. A spec that writes the finding and strikes the mark in one step
produces the same `Observe` traces as one that separates them, minus a state, so
no property over this interface tells them apart. An `Init` that starts a ware
already tested is green under all three items and the type invariant. Item 1 is
vacuous on an unmarked undefaced ware, item 2 holds from that state on, and item
3 has no obligation without a substandard finding. That's the same situation
qsl's re-credit guard sits in, and this is the record naming the cause in advance
rather than after a variant comes back green.

**The rule I left out.** "Every lodged ware is eventually tested" is the obvious
fourth item, and I think it's the wrong one. It needs its own fairness conjunct
on the testing step, which doubles the fairness decision at the rung where
fairness first shows up. It's also a duty this domain doesn't carry. The office
works on what's in front of it and owes nobody a deadline, and Rule 5 says so.

## 6. Ambiguities resolved, and how they could have gone

1. **No custody.** Any officer can act on any ware the rules allow, and nobody
   holds anything. The alternative is a take-up step and a holder per ware, which
   is what the screener sketched, and it breaks the liveness. Put the defacing
   step behind a holder and an officer can take a ware up, test it, find it
   substandard, put it down and walk away. Nobody holds it, so no officer's
   defacing step is enabled, so weak fairness obliges nothing and item 3 is false
   in a reachable state. Fixing that needs a guard on the putting-down, which is
   machinery this rung has no room for.
2. **No give-back.** Nothing leaves the office. A give-back needs no maker, since
   an officer can put a finished ware in an outward tray and step sources stays at
   1. What an exit costs is a property. Once wares can leave, "only a struck or
   defaced ware leaves" has to be graded, and that's a fifth cfg line at a rung
   capped at four.
3. **The finding is the office's word.** There's no true fineness sitting behind
   it that the test could get wrong. The alternative gives each ware a real
   fineness and lets the assay err. That's fallibility, and fallibility is a
   different problem in a different column.
4. **One test per ware.** No re-assay and no appeal. Real offices do reassay on a
   challenge. Modeling it reopens the finding and kills item 2, which carries
   most of the safety weight here.
5. **No duty to test.** A ware can lie untested forever. The alternative obliges
   the office to work through what's lodged, which is a second liveness rule and
   a second fairness conjunct at the rung where fairness first appears.
6. **One mark, and no cycle.** A real hallmark carries a sponsor's mark, a
   fineness mark, an office mark and a date letter, and the date letter turns
   over each year. A year is a step no party takes, so it's step sources 3, and
   it breaks the rung outright.
7. **Two findings.** At standard, or below it. Real offices test against several
   standards at once, sterling and Britannia for silver among them. More
   standards multiply the config and ask no new modeling question.
8. **Wares are lodged at the opening.** The alternative is a lodging step, and
   the maker who takes it is a second kind of actor. Same cost as 2. This is the
   one the statement has to say in a sentence rather than leave to be inferred.
9. **Whole wares.** One article, tested and marked as one. Batches and parts
   would turn every field into a vector and bring arithmetic to a rung that isn't
   about arithmetic.
10. **Officers are interchangeable.** No seniority, no assignment, no supervisor.
    The alternative distinguishes one officer, and a named party under `WF` places
    step sources at 2 (V2-PLAN.md:321).
11. **Defacing, not destruction.** The office damages the ware so it can't pass
    as standard. Whether the pieces go back to the maker or into the melt sits
    outside this system, and modeling it needs Rule 6 to grow an exit.
12. **No bench limit.** The office holds every lodged ware at once. There's no
    queue, no cap on how many wares sit tested and not yet dealt with, and no
    limit on how many an officer can have in progress, because nothing is in
    progress. The alternative caps the bench, which needs a guard on the testing
    step and a cfg line to grade it, and this problem has no line to spare.
13. **The finding is written down, not just acted on.** The office records the
    finding, so it's a fact the interface reports before anything is done about
    it. The alternative tests and acts in one motion. That deletes the state
    where the duty exists and is unmet, and item 3's whole content lives in that
    state.
