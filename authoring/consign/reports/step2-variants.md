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

## How every run was driven

One command shape, through the harness's verdict channel, with the module
path absolute and the `.cfg` picked up beside it:

```
JAVA_TOOL_OPTIONS="-DTLA-Library=<worktree>/harness" \
  harness/verdict.sh -t 300 [-p "Gate!NonVacuous"] <abs>/MCConsign.tla
```

`Gate` needs `-DTLA-Library` to resolve, which is the pattern
`harness/vacuity.sh:208` uses. Deadlock checking stays off, which is
`verdict.sh`'s default and what HANDOFF §4's quiescence note asks for.

Variant runs carry no postcondition. The obligations in the shipped `.cfg`
are what's under test, so I wanted the verdict to come from them and nothing
else. Every variant that came back `rc=0` was then re-run with
`-p "Gate!NonVacuous"` to rule out an empty state space behind the green.

## The reference under test

§9.5's checks 1 to 4 and 6, in order.

| Check | Command | Token | rc |
|---|---|---|---|
| 1 all properties pass | the shape above, with `-p` | `OK` | 0 |
| 2 reachable states exist | `-- -inv FALSE` | `SAFETY_VIOLATION` | 12 |
| 3 non-vacuity gate | `-p "Gate!NonVacuous"` | `OK` | 0 |
| 4 no dead action | `-coverage 1`, on by default | see below | 0 |

Check 6, from the run log: **1791 states generated, 608 distinct states
found, 0 states left on queue**, and **the depth of the complete state graph
search is 11**. That matches the step-1 report's numbers exactly.

Check 4 needs a note, because §9.5's wording doesn't survive contact with an
instance module. TLC reports one action entry for the whole of `Next`,
`<Action line 12, col 1 to line 16, col 14 of module MCConsign>: 607:1790`,
named after the `INSTANCE` statement rather than after any action. So
"no action has `total == 0`" has exactly one row to look at, and reading it
would pass a spec with three dead actions out of four.

The per-action evidence is one level down, in the indented sub-counts §5.3
says to use. Each action's assignment line fired:

| Action | Line in `Consign.tla` | Total |
|---|---|---|
| `Intake` | 24 | 448 |
| `Sell` | 28 | 448 |
| `GoHome` | 32 | 448 |
| `Settle` | 36 | 446 |

None is zero, so check 4 passes on the evidence §5.3 names. I think §9.5's
check 4 should say so, because the top-level row it currently points at is
blind for any spec that reaches its `Spec` through an `INSTANCE`.

## The settlement path is not vacuously green

Two probes, each a scratch copy with one added obligation, per §5.3. The
step-1 report used `ProbeNeverTwoSold`, so these are different assertions.

**`ProbeNeverSettled == \A i \in Items : standing[i] # "settled"`**, added as
an `INVARIANT`. Token `SAFETY_VIOLATION`, **rc=12**, log line
`Error: Invariant ProbeNeverSettled is violated.` So `settled` is reachable,
and the till runs.

**`ProbeAtMostOneChanged == [][Cardinality(Changed) <= 1]_standing`**, added
as a `PROPERTY`. Token `LIVENESS_VIOLATION`, **rc=13**, log line
`Error: Action property ProbeAtMostOneChanged is violated.` This is the one I
wanted. Only `Settle` can move more than one item, so a violation is a
witnessed multi-item settlement. The trace ends:

```
State 5: standing = (i1 :> "sold" @@ i2 :> "sold" @@ i3 :> "unlisted" @@ i4 :> "unlisted")
State 6: standing = (i1 :> "settled" @@ i2 :> "settled" @@ i3 :> "unlisted" @@ i4 :> "unlisted")
```

`i1` and `i2` are both `o1`'s. Two items settle in one step, so
`SettlementStep` carries transitions that `SingleStep` rejects. The
settlement disjunct earns its place rather than riding along under a green
that `SingleStep` alone would have produced.

## Results, all 24

Every variant ran against `MCConsign.cfg` byte-identical to the shipped one,
checked by `cmp` across all 24 directories before the first run.

| ID | Token | rc | Obligation the log names | As frozen |
|---|---|---|---|---|
| C01 | `LIVENESS_VIOLATION` | 13 | `OpeningAllUnlisted`, by the initial state | yes |
| C02 | `SAFETY_VIOLATION` | 12 | `FloorCap` | yes |
| C03 | `SAFETY_VIOLATION` | 12 | `FloorCap` | yes |
| C04 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C05 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C06 | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` | yes |
| C07 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C08 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C09 | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` | yes |
| C10 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C11 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C12 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C13 | `OK` | 0 | none | yes, uncaught |
| C14 | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` | yes |
| C15 | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` | yes |
| C16 | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` | yes |
| C17 | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` | yes |
| C18 | `OK` | 0 | none | yes, uncaught |
| C19 | `SAFETY_VIOLATION` | 12 | `OneStandingEach` | yes |
| C20 | `LIVENESS_VIOLATION` | 13 | `LawfulPath` | yes |
| C21 | `OK` | 0 | none | yes, uncaught |
| C22 | `OK` | 0 | none | yes, uncaught |
| C23 | `OK` | 0 | none | yes, uncaught |
| C24 | `OK` | 0 | none | yes, uncaught |

**18 caught, 6 uncaught.** Every catch named the obligation the frozen matrix
predicted, and the six green ones are the six the matrix seeded green.

All five obligations in the `.cfg` fire on at least one variant. Nothing in
that file is dead weight, which I did not take for granted going in.

## The six that came back green

Each was re-run with `-p "Gate!NonVacuous"`, so none of these greens is an
empty state space.

| ID | Distinct | Disposition |
|---|---|---|
| C13 | 608 | declared invisible, `HANDOFF.md:69-74` and `:164-167` |
| C18 | 608 | not a defect, stuttering-equivalent |
| C21 | 9728 | declared invisible, `HANDOFF.md:132-138` |
| C22 | 608 | declared invisible, `HANDOFF.md:83-89` |
| C23 | 513 | declared invisible, all-safety, `HANDOFF.md:111-114` |
| C24 | 608 | **not declared, and the repair is available** |

The distinct counts carry more than they look like they do. C13, C18, C22 and
C24 all land on 608, the reference's own count, so their reachable state
graphs are the reference's graph. C23 drops to 513, which is behavior removal
showing up as a number. C21 lands on 9728, and 9728 is 608 times the 16 ways
four items can be owned by two owners.

**C13, the two hands.** Rule 4 folds the owner's fetch and the shop's send
into one event, and §3's first honest note says a two-action model and a
one-action model look the same through `Observe`. The variant confirms the
claim rather than refuting it. No fix, and asking for one would contradict
the hand-off.

**C18, the empty till visit.** Dropping `SoldOf(o) # {}` leaves a disjunct
that implies `UNCHANGED standing`, and TLA's box already allows stuttering.
The mutant admits exactly the reference's behaviors, at the same 608 states.
This is §5.5's inert class, not an uncaught defect. No fix exists because
there's nothing to catch.

**C21, drifting ownership.** The variant makes `OwnerOf` a variable a step can
re-map, so a settlement can group by an ownership that changed since intake.
Nothing sees it. `Observe` has one field and it isn't ownership, so no
obligation stated over the observable can reach it. An obligation stated over
the spec's own internals can't either, because the mutant moves those
internals and stays self-consistent with them. Both routes are closed. §3
names this cause for a drifting payable ledger, and I think ownership drift is
the same cause one field over. No fix without widening `Observe`, which §3
rejects on purpose.

**C22 and C23, the behavior-removal pair.** C22 adds `WF_standing(Next)` and
C23 tightens the intake guard to count sold items against the cap. Both only
remove behaviors, and safety alone can't see a behavior that stopped
happening. C22 leaves the state graph untouched at 608, which is why no
safety property could have caught it even in principle. Rule 6 declares the
whole list safety, so this class was uncatchable before I wrote it. C22 is
declared by name. C23 isn't, and I'm counting it as declared anyway, because
its mechanism is the one Rule 6 rules out rather than a second mechanism.
No fix without a liveness obligation the hand-off forbids.

## C24, the red arrow

`Observe` appears exactly once in the whole reference triple, at its own
definition on `Consign.tla:17`. Nothing else references it. It never appears
in TLC's coverage statistics either, so it isn't evaluated on any run.

That makes the variant free. C24 rewrites `Observe` to report every item
`unlisted` no matter what the shop is doing, and the run comes back `OK` at
608 distinct states, unchanged from the reference. The declared interface can
say anything at all and every configured obligation still passes.

The cause is where the obligations are stated. `HANDOFF.md:93` says they're
stated over the observable of section 3, and the reference states them over
the raw variable instead (`Consign.tla:44-71`). On the reference those two
readings agree, because `Observe.standing` is `standing`. On any model where
they disagree, the obligations follow the variable and the observable goes
unchecked.

I think the fix belongs in the step-shaped obligations, and the smallest one
is a single definition:

```
Changed == {i \in Items : Observe'.standing[i] # Observe.standing[i]}
```

Keep the `_standing` subscript on `SingleStepOrSettlement`. Under C24 every
step then shows `Changed = {}`, which `SingleStep` rejects for wanting a
singleton and `SettlementStep` rejects for wanting a non-empty `SoldOf(o)`,
while the real variable still moves so the box isn't satisfied by stuttering.
That's my read of the mechanism, and §9.5b owns the measurement.

One argument could flip this verdict, and central should weigh it rather than
take my word. C24 doesn't break a rule of the shop. It breaks the interface
contract in §3, and a strict reading of §5.5 seeds bugs in the system. My
answer is that §3 shipped inside the author's brief, and that §5.2 builds
every learner's grade on `Observe`, so a lying one corrupts grading with
nothing upstream to catch it. I'd rather close it here than find it there.

## Which clause does the catching

The step-1 report flags the sold-to-settled exclusion in `SingleStep` as
where a weaker form hides. I measured it by ablation, on three copies with
the exclusion stripped and nothing else changed.

| Spec | With the exclusion | Without it |
|---|---|---|
| reference | `OK`, rc=0 | `OK`, rc=0 |
| C14, per-item till | rc=13 | `OK`, rc=0 |
| C15, partial payout | rc=13 | `OK`, rc=0 |

The weaker property passes the reference, so an author who wrote it would
have seen green and shipped. It then misses both till mutants, because a
one-item settlement reads as a lawful single move once the exclusion is gone.
The author's flag is correct, and the clause is load-bearing for two of the
six catches that `SingleStepOrSettlement` makes.

This is the clearest case I've seen for §9.5 handing variant authorship to a
second agent. The author cannot tell the two forms apart by running their own
spec, because both are green on it. Only a mutant separates them.

## Two notes on §9.5's checklist

Check 4's wording is blind on an instance module, for the reason in the
reference section above. The per-action counts are there, one level down.

Check 5 says rc=12 where an invariant catches it and rc=13 where an action
property does. C01 is neither. A state predicate under `PROPERTIES` lands as
an implied init, and violating it exits **13** with the log line
`Error: Property OpeningAllUnlisted is violated by the initial state`. That's
a third route, and it's how HANDOFF §2's opening item gets graded at all. I'd
add the row rather than let the next verifier read rc=13 as an action
property.

## Verdict

**Red, one arrow.**

Five of the six uncaught variants are findings confirmed. C13, C21, C22 and
C23 each match a class the hand-off declares uncatchable in advance, and C18
is inert rather than uncaught. On the pilot's precedent an uncatchable variant
with a named cause doesn't hold a gate open, and I'd close over all five.

C24 is the arrow. `Observe` is unconstrained by every obligation in the
`.cfg`, the repair is one definition, and the target is
`Consign.tla:58` where `Changed` is defined. Dispatch §9.5b there. The matrix
above does not move.
