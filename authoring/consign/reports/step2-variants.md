# P5 consign, step 2: the seeded-variant matrix

Agent B, bead `tla-exm1`, V2-PLAN §9.5. I did not write the reference and I
have not read `DESCRIPTION.md`, `screens.md`, or any other domain. The inputs
are `authoring/consign/HANDOFF.md`, the three reference files, the author's
`ALTERNATIVES.md`, and the step-1 report.

The section below is the frozen matrix. §9.5 says the variant set freezes
before the first TLC run, so this section landed in its own commit with no
run behind it. Nothing in it moves again, whoever ends up repairing.

## The frozen matrix

24 variants. Every one is a mutation of the model (`Init`, `Next`,
`Standings`, `Observe`, or `Spec`), never of a property, because the
properties are what's under test. Every one runs against `MCConsign.cfg`
unchanged.

The clause column names the sentence in `HANDOFF.md` sections 1 and 2 that
the mutation breaks. Where a clause has more than one failure direction I
seeded each direction, so the count runs ahead of the clause count.

| ID | Clause | The mutation | I expect |
|---|---|---|---|
| C01 | §2.1 opening | `Init` admits one item already listed | `OpeningAllUnlisted` |
| C02 | R2 floor cap | `Intake` drops the cardinality guard | `FloorCap` |
| C03 | R2 floor cap | `<` becomes `<=`, so `Floor + 1` fit | `FloorCap` |
| C04 | R1 returned stays home | `Intake` guard admits `returned` | `LawfulPath` |
| C05 | R1 settled is done | `Intake` guard admits `settled` | `LawfulPath` |
| C06 | R2 one step, one item | one intake lists two items | `SingleStepOrSettlement` |
| C07 | R3 sell only what's listed | `Sell` guard admits `unlisted` | `LawfulPath` |
| C08 | R3 sell only what's listed | `Sell` guard admits `returned` | `LawfulPath` |
| C09 | R3 one step, one item | one sale sells two items | `SingleStepOrSettlement` |
| C10 | R3 the payout is owed | `Sell` sets `settled` and skips owing | `LawfulPath` |
| C11 | R1 nothing moves backward | `GoHome` guard admits `sold` | `LawfulPath` |
| C12 | R4 the listing is spent | `GoHome` sets `unlisted` | `LawfulPath` |
| C13 | R4 one event, either hand | `GoHome` splits into two actions | nothing, declared |
| C14 | R5 pay everything at once | `Settle` settles one item per step | `SingleStepOrSettlement` |
| C15 | R5 pay everything at once | `Settle` settles a subset, some left owed | `SingleStepOrSettlement` |
| C16 | R5 exactly one owner | `Settle` settles every sold item, all owners | `SingleStepOrSettlement` |
| C17 | R5 nothing else moves | `Settle` also sells one listed item | `SingleStepOrSettlement` |
| C18 | R5 an empty visit isn't a step | `Settle` drops the nonempty guard | nothing, inert |
| C19 | R1 one of five standings | a sixth standing, `Standings` untouched | `OneStandingEach` |
| C20 | R1 one of five standings | a sixth standing, `Standings` widened | `LawfulPath` |
| C21 | R1 one fixed owner | `OwnerOf` becomes a variable a step re-maps | nothing, §3 thinness |
| C22 | R6 nobody must act | `Spec` conjoins `WF_standing(Next)` | nothing, declared |
| C23 | R2 a full floor refuses | the cap also counts sold items | nothing, all-safety |
| C24 | §3 the observation operator | `Observe` reports every item unlisted | nothing, unconstrained |

Six of the 24 I expect to come back uncaught, and I seeded them on purpose.
A matrix of only catchable mutations measures the properties against
themselves, which is the trap §9.5 hands the variant set to a second agent to
avoid. The six split three ways, and the split is the finding rather than the
count.

**Declared invisible.** C13 and C22 break a clause the HANDOFF already says
it will not grade. Rule 4 folds both hands into one event, and §3's first
honest note says a two-action model and a one-action model look the same
through `Observe`. Rule 6 declares the whole property list safety, so added
fairness cuts behaviors that no safety property misses. C23 is the same
mechanism as C22 without the fairness: a stricter intake guard only removes
behaviors, and safety alone can't see a behavior that stopped happening.

**Not a defect.** C18 leaves `Settle` with a disjunct that implies
`UNCHANGED standing`. TLA's box already allows stuttering, so the mutant
admits exactly the behaviors the reference admits. §5.5 puts 39.3% of single
mutations in this class, and I'd rather seed one and name it than pretend the
class isn't there.

**Neither.** C21 and C24 are the two I care about. Both hide state from the
observation operator, which §3 defends on purpose, and both would need
something the current five obligations don't do.

## What a red gate would mean here

An uncaught variant in the first two groups is a finding confirmed, not a
gate failure, and the pilot's precedent is that the gate still closes over
them (`pilot/reports/agent-a2.md`). An uncaught variant in the third group is
the red arrow, and the report has to say where the repair lives before
central can dispatch §9.5b.

Results, run logs, and the verdict follow in the sections below, added after
the matrix froze.
