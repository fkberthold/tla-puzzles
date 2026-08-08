# BuyClub, step 2: the frozen variant matrix

Reference verification and adversarial variant authoring for problem P3, per
V2-PLAN §9.5 and §6's red-arrow rules. Bead `tla-7fbx`. I did not write the
reference and I did not write the system description, and §9.5 tells me to
distrust both.

The matrix in section 2 was written before the first TLC run of this session.
It does not move again. If the gate comes back red, a repairer (§9.5b) works
against these rows and not against rows written to fit a repair.

Inputs read: `V2-PLAN.md` §5.1, §5.2, §5.5, §9.5, §6's red-arrow section,
`authoring/buyclub/HANDOFF.md`, `authoring/buyclub/reference/BuyClub.tla`,
`authoring/buyclub/reference/BuyClub.cfg`,
`authoring/buyclub/author-notes/ALTERNATIVES.md`, and the step-1 worker report.
Not read: `DESCRIPTION.md`, any other domain under `authoring/`, `pilot/`.

## 1. How a variant is built and run

Every variant is a copy of `reference/BuyClub.tla` with the module name changed
to the variant id and one mutation applied. Each one runs against the shipped
`reference/BuyClub.cfg`, unchanged, through `harness/verdict.sh`. The cfg names
operators only, so a renamed module takes it as it stands.

The shipped obligation set, which is what every row below is measured against:

- `INVARIANT TypeOK` covers item 9 and item 6's phase range.
- `INVARIANT SharesTellTheBook` covers item 7.
- `PROPERTY Opening` covers item 1, through TLC's implied-init channel.
- `PROPERTY OneHandAtATime` covers item 2.
- `PROPERTY Threshold` covers item 3.
- `PROPERTY Snapshot` covers item 4.
- `PROPERTY TwoWaysOnly` covers item 5.
- `PROPERTY ForwardPhases` covers item 6.
- `PROPERTY DeliveryComes` covers item 8.

Expected exit codes come from §5.1's measured table. An invariant violation is
12. A boxed action property goes through the implied-action channel and is 13
whatever its trace looks like, which is the wrinkle the step-1 author flagged.
A leads-to is 13. I expect an implied-init violation at 13 by analogy with
§5.4's refinement rows, and that expectation is a guess I mean to measure.

A variant is **caught** when the run exits nonzero and the log names an
obligation. It's **uncaught** at rc=0. An rc=124 is a TIMEOUT and gets reported
as one, never folded into either.

## 2. The matrix

Thirty variants. Twenty-three I expect caught, six I expect uncaught, and one
is a calibration control I expect to be inert. The "kind" column says what the
mutation does to the behavior set: **more** adds behaviors, **less** removes
them, **other** moves the model sideways.

### Item 1, the opening

| id | mutation | kind | expected |
|---|---|---|---|
| V01 | `Init` sets every book entry to 1 | other | caught, `Opening` |
| V02 | `Init` sets every phase to `"placed"` | other | caught, `Opening` |

### Item 9 and Rule 1, the `Cap` ceiling

| id | mutation | kind | expected |
|---|---|---|---|
| V03 | `Pledge` and `Next` range over `0..(Cap+1)`, `TypeOK` left alone | more | caught, `TypeOK`, rc 12 |

V03 is the over-cap pledge this problem's history names. The mutation has to
stay out of `PledgeAmounts`, because `TypeOK` reads that same operator and
would move with it.

### Item 2 and Rule 2, one hand on the book

| id | mutation | kind | expected |
|---|---|---|---|
| V04 | `Pledge` drops the `phase[p] = "open"` guard | more | caught, `OneHandAtATime` or `SharesTellTheBook` |
| V05 | `Pledge` writes the member's whole row, `book' = [book EXCEPT ![m] = [q \in Products \|-> n]]` | more | caught, `OneHandAtATime` |
| V06 | `Pledge` drops `UNCHANGED share` and sets `share'[m][p] = n` | more | caught, `OneHandAtATime` or `SharesTellTheBook` |
| V07 | a combined deliver-and-pledge disjunct joins `Next` | more | caught, `OneHandAtATime` or `ForwardPhases` |

V06 and V07 are the hold-still frame conditions the step-1 author flagged as
the attack surface. V04 is the one that tests the interaction the HANDOFF names
at its lines 131 to 134: item 7 only means something because item 2 closes the
book at placement, so a post-placement revision should trip one of them.

### Item 3 and Rule 3, the threshold

| id | mutation | kind | expected |
|---|---|---|---|
| V08 | `Place` drops `Total(p) >= Min` | more | caught, `Threshold`, rc 13 |
| V09 | `Place` reads `Total(p) >= Min - 1` | more | caught, `Threshold`, rc 13 |

### Item 4 and Rule 3, the snapshot

| id | mutation | kind | expected |
|---|---|---|---|
| V10 | `Place` snapshots 0 into every share instead of the pledge | other | caught, `Snapshot` |
| V11 | `Place` zeroes every other product's shares | more | caught, `Snapshot` or `TwoWaysOnly` |
| V12 | `Place` also zeroes one member's book entry, so the book isn't frozen | more | caught, `OneHandAtATime` or `SharesTellTheBook` |

### Item 5 and Rule 5, shares move two ways only

| id | mutation | kind | expected |
|---|---|---|---|
| V13 | `Collect` accepts `phase[p] \in {"placed", "arrived"}` | more | caught, `TwoWaysOnly` |
| V14 | `Collect` takes one unit, `share' = share - 1` | more | caught, `TwoWaysOnly` or `SharesTellTheBook` |
| V15 | `Collect` zeroes every member's share of that product | more | caught, `TwoWaysOnly` |
| V16 | `Collect` also zeroes the collector's book entry | more | caught, `TwoWaysOnly` or `OneHandAtATime` |
| V17 | `Deliver` also zeroes one member's share | more | caught, `TwoWaysOnly` or `ForwardPhases` |

V17 is item 6's "a delivery moves its phase and nothing else", attacked from
the share side. V15 and V16 are item 5's own frame clauses.

### Item 6, phases run forward

| id | mutation | kind | expected |
|---|---|---|---|
| V18 | an `Unplace` disjunct joins `Next`, placed back to open | more | caught, `ForwardPhases` |
| V19 | `Place` jumps straight to `"arrived"` | other | caught, `ForwardPhases` |
| V20 | `Deliver` arrives every placed product in one step | more | caught, `ForwardPhases` |
| V21 | `Deliver` sets a fourth phase, `"lost"` | other | caught, `TypeOK`, rc 12 |

V19 is worth watching past its verdict. If placement skips `"placed"`, then
`Threshold` and `Snapshot` both go vacuous, because their antecedent
`phase[p] = "open" /\ phase'[p] = "placed"` never fires. A variant that dodges
two obligations by breaking a third is the kind of thing I want on the record.
`Deliver` should also go dead in the coverage table.

### Item 8 and Rule 4, delivery comes

| id | mutation | kind | expected |
|---|---|---|---|
| V22 | `Spec` drops `\A p \in Products : WF_vars(Deliver(p))` | more | caught, `DeliveryComes`, rc 13 |
| V23 | `Deliver` guards on `Total(p) >= Cap * 10`, fairness kept | less | caught, `DeliveryComes`, rc 13 |

Both carry liveness, so both get the full 300 second budget.

### Permissions, where I expect the properties to say nothing

| id | mutation | kind | expected |
|---|---|---|---|
| V24 | `Pledge` needs `Total(p) < Min`, so the book freezes at the minimum | less | uncaught, rc 0 |
| V25 | `Spec` adds `\A p \in Products : SF_vars(Place(p))` | less | uncaught, rc 0 |
| V26 | `Place` needs `Total(p) = Min` exactly | less | uncaught, rc 0 |
| V27 | `Pledge` needs `n > book[m][p]`, so nobody withdraws | less | uncaught, rc 0 |
| V28 | `Collect` waits for every product to arrive | less | uncaught, rc 0 |

V24 and V25 are the compelled-placement model this problem's history names, in
its two forms. V24 freezes revision once the book covers the minimum. V25 puts
strong fairness on placement, which forces the order rather than permitting it.
Rule 3 says reaching the minimum never forces a placement, and the HANDOFF's
own sufficiency walk says at its line 179 that no property carries that clause
and none can, because it's a permission. So I expect both uncaught, and the
job here is to confirm the declared class rather than to close it.

V27 is the one I'd argue matters most for the learner. Rule 3 calls the
withdrawal race the heart of the system, and a model without withdrawals still
satisfies every stated property, because removing behaviors can't break a
safety property and the one liveness obligation survives.

### The ledger nobody carries

| id | mutation | kind | expected |
|---|---|---|---|
| V29 | a fourth variable `ordered`, set to `Total(p) + 1` at placement | other | uncaught, rc 0 |

The HANDOFF's third honest note says no field carries the ordered total, and
Rule 3 says the order goes to the supplier for the book's total. So a model
that orders the wrong amount is wrong about a stated rule and invisible to
every property, which is the second declared class the brief names.

### Calibration control

| id | mutation | kind | expected |
|---|---|---|---|
| V30 | `Collect` guards on `share[m][p] >= 0` | more | uncaught, rc 0, inert |

Item 5 says a collection runs only from a positive share, so V30 breaks a
stated clause. I expect it to add no behavior at all, because zeroing a zero
share leaves every variable alone and the step is a stutter. §5.5 puts 39.3% of
single mutations in that class, and one row of it here keeps the caught count
honest. This row does not count against the gate.

## 3. Rules with nothing to mutate

Rule 6 rules out money and stock, and the reference carries neither, so there's
no mutation to make. Rule 6's "no second round" is V18. Rule 5's "no trades at
the table" has no state to move. The coordinator and the supplier never appear
as actors, per the HANDOFF's first honest note, so no variant attacks them.

## 4. Reference checks

The four §9.5 checks, run before the variants:

1. Full run through `verdict.sh`, expecting `OK` at rc 0.
2. `-inv FALSE`, expecting rc 12, which says reachable states exist.
3. `-postCondition "Gate!NonVacuous"`, expecting a pass.
4. The `-coverage 1` table, expecting no action at `total == 0`.

Distinct and generated state counts get recorded from the same runs.

## 5. Results

Everything below was written after the matrix froze. Every variant ran through
`harness/verdict.sh` with `-t 300`, from `harness/` as cwd so `Gate.tla`
resolves, against `-c ../authoring/buyclub/reference/BuyClub.cfg`. No run came
back 124, so no row is a TIMEOUT.

### 5.1 The reference

| check | rc | token |
|---|---|---|
| full run | 0 | `OK` |
| `-- -inv FALSE` | 12 | `SAFETY_VIOLATION` |
| `-p "Gate!NonVacuous"` | 0 | `OK` |
| `-p "Gate!InvariantConfigured"` | 0 | `OK` |
| `-p "Gate!ActionPropertyConfigured"` | 0 | `OK` |

Commands, in order:

```
cd harness
bash verdict.sh -t 300 --log ../variant-scratch/logs/reference.log \
    ../authoring/buyclub/reference/BuyClub.tla
bash verdict.sh -t 300 ../authoring/buyclub/reference/BuyClub.tla -- -inv FALSE
bash verdict.sh -t 300 -p "Gate!NonVacuous" ../authoring/buyclub/reference/BuyClub.tla
bash verdict.sh -t 300 -p "Gate!InvariantConfigured" ../authoring/buyclub/reference/BuyClub.tla
bash verdict.sh -t 300 -p "Gate!ActionPropertyConfigured" ../authoring/buyclub/reference/BuyClub.tla
```

State counts, from the full run: **94,465 generated, 20,736 distinct**, search
depth **17**. TLC checked 2 branches of temporal properties, so the liveness
obligation ran. Runtime was about one second.

The coverage table, `distinct:total` per action. No action sits at `total == 0`,
which is §9.5's check 4:

| action | distinct:total |
|---|---|
| `Init` | 1:1 |
| `Pledge` | 728:46860 |
| `Place` | 1207:4896 |
| `Deliver` | 1785:4930 |
| `Collect` | 17015:38016 |

The four action `distinct` counts plus `Init` sum to 20,736, which is the
distinct-state count exactly. I'm recording that because it's the check that
tells you which of the two numbers is which, and §5.3's dead-action predicate
reads the second one.

### 5.2 The variants

Twenty-three caught, seven at rc=0, no timeouts. The seven are the six declared
permissions plus the calibration control. The "named" column is what the log
says, never what I expected.

| id | token | rc | named obligation | distinct |
|---|---|---|---|---|
| V01 | `LIVENESS_VIOLATION` | 13 | `Opening`, by source location | 0 |
| V02 | `LIVENESS_VIOLATION` | 13 | `Opening`, by source location | 0 |
| V03 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 14 |
| V04 | `SAFETY_VIOLATION` | 12 | `SharesTellTheBook` | 347 |
| V05 | `LIVENESS_VIOLATION` | 13 | `OneHandAtATime` | 2 |
| V06 | `SAFETY_VIOLATION` | 12 | `SharesTellTheBook` | 2 |
| V07 | `LIVENESS_VIOLATION` | 13 | `OneHandAtATime` | 348 |
| V08 | `LIVENESS_VIOLATION` | 13 | `Threshold` | 14 |
| V09 | `LIVENESS_VIOLATION` | 13 | `Threshold` | 64 |
| V10 | `LIVENESS_VIOLATION` | 13 | `Snapshot` | 108 |
| V11 | `LIVENESS_VIOLATION` | 13 | `Snapshot` | 1478 |
| V12 | `SAFETY_VIOLATION` | 12 | `SharesTellTheBook` | 108 |
| V13 | `LIVENESS_VIOLATION` | 13 | `TwoWaysOnly` | 348 |
| V14 | `SAFETY_VIOLATION` | 12 | `SharesTellTheBook` | 818 |
| V15 | `LIVENESS_VIOLATION` | 13 | `TwoWaysOnly` | 817 |
| V16 | `LIVENESS_VIOLATION` | 13 | `OneHandAtATime` | 817 |
| V17 | `LIVENESS_VIOLATION` | 13 | `TwoWaysOnly` | 347 |
| V18 | `SAFETY_VIOLATION` | 12 | `SharesTellTheBook` | 348 |
| V19 | `LIVENESS_VIOLATION` | 13 | `TwoWaysOnly` | 108 |
| V20 | `LIVENESS_VIOLATION` | 13 | `ForwardPhases` | 2683 |
| V21 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 347 |
| V22 | `LIVENESS_VIOLATION` | 13 | `DeliveryComes` | 20736 |
| V23 | `LIVENESS_VIOLATION` | 13 | `DeliveryComes` | 1936 |
| V24 | `OK` | 0 | none | 10816 |
| V25 | `OK` | 0 | none | 20736 |
| V26 | `OK` | 0 | none | 4356 |
| V27 | `OK` | 0 | none | 20736 |
| V28 | `OK` | 0 | none | 13432 |
| V29 | `OK` | 0 | none | 20736 |
| V30 | `OK` | 0 | none | 20736 |

Every rc lines up with §5.1's table. Invariant catches are 12, action-property
and leads-to catches are 13, and the implied init is 13 as I guessed it would
be. Nothing here contradicts the plan.

Three rows deviated from my frozen expectation on **which** obligation fires,
though all three were caught:

- V04 named `SharesTellTheBook`, and I had `OneHandAtATime` first.
- V18 named `SharesTellTheBook`, and I expected `ForwardPhases`.
- V19 named `TwoWaysOnly`, and I expected `ForwardPhases`.

TLC reports the first violation it reaches, so a variant that breaks two
obligations gets named by one of them. I don't read any of the three as a gap.

One repair to my own scaffolding, recorded because it happened after the
freeze. V25's first generation put the two fairness conjuncts on separate
continuation lines, and the second `\A p` landed inside the first one's body.
That's a duplicate bound identifier, and TLC returned 150 `PARSE_ERROR` on my
variant rather than a verdict about the reference. I parenthesized both
quantifiers on one line and re-ran. The row's meaning didn't move.

### 5.3 What the shipped obligation set buys

Every one of the nine shipped obligations is the sole named catcher of at least
one variant:

- `TypeOK` catches V03 and V21.
- `SharesTellTheBook` catches V04, V06, V12, V14, V18.
- `Opening` catches V01 and V02.
- `OneHandAtATime` catches V05, V07, V16.
- `Threshold` catches V08 and V09.
- `Snapshot` catches V10 and V11.
- `TwoWaysOnly` catches V13, V15, V17, V19.
- `ForwardPhases` catches V20.
- `DeliveryComes` catches V22 and V23.

Nothing in the set is dead weight against this matrix. `ForwardPhases` is the
thinnest, holding one row on its own, which I'd expect from an obligation whose
neighbors overlap it on three sides.

One finding about the channel rather than the spec. An implied-init violation
gets reported by **source location, not by name**. V01's log reads `Error:
Property line 78, col 43 to line 78, col 56 of module V01 is violated by the
initial state`, and line 78 is the second conjunct of `Opening`. An invariant
gets `Error: Invariant TypeOK is violated` and a boxed action gets `Error:
Action property Threshold is violated`, both carrying the operator name. So a
tutor that reads back "which obligation failed" has a hole at exactly the
opening condition, and closing it means mapping a line number to an operator.
I'd file that against the tutor work rather than against this problem.

### 5.4 The seven uncaught variants

All seven fall into three named structural causes, and none of them is a defect
in the reference or its properties.

**Cause A, a strict restriction of the behavior set. V24, V25, V26, V27, V28.**

Every obligation in the shipped set is universally quantified over behaviors,
which is what an invariant, an action property and a leads-to all are. Removing
behaviors can't falsify one. So no strengthening of this property set can catch
an over-constrained model, and trying to add one would be bending the reference
to manufacture a catch.

Fix location: §5.2's over-constraint direction, `Φ => ψⱼ` over student
conjuncts. That's the graded channel these belong to, and V2-PLAN calls it the
sin reference-comparison grading actively teaches. A statement clause helps too,
since step 4 can word Rule 3's permission so a learner doesn't over-constrain by
accident.

V24 and V25 are the compelled-placement model, in the two forms I could see.
V24 freezes revision once the book covers the minimum, and V25 puts strong
fairness on placement. Both come back rc=0. This confirms the class the HANDOFF
declares at its line 179 rather than closing it, which is what the brief asked
for.

**V27 is the sharpest row in the whole matrix, and I want it on the record.**
It removes withdrawals, which Rule 3 calls the heart of the system. It runs
20,736 distinct states, the same number as the reference, because every book
configuration is still reachable by monotone increases. Only the transition
count moves, `Pledge` going 46,860 to 23,532. So a state-count fingerprint
misses it, `Gate!NonVacuous` misses it, and the whole property set misses it.
I think that makes it the best single argument in this problem for grading
transitions rather than reachable states.

**Cause B, state the observation operator doesn't carry. V29.**

V29 adds an `ordered` variable and sets it to `Total(p) + 1` at placement, so
the club orders one unit more than the book says. Rule 3 fixes that amount and
no property can see it, because every obligation is stated over `phase`, `book`
and `share`. The HANDOFF's third honest note declares this: no field carries the
ordered total, and adding one would push the model toward a stored-order
representation.

Fix location: a named structural cause, no repair. Worth noting that V29 runs
94,465 generated and 20,736 distinct, both identical to the reference. The
`ordered` value is a function of the frozen book, so it adds no distinguishing
power at all. That's the same argument `ALTERNATIVES.md` gives for dropping a
stored order total, arriving from the other direction.

**Cause C, the mutation is inert. V30.**

V30 lets a member collect a zero share, which breaks item 5's "only from a
positive share". Zeroing a zero share leaves every variable alone, so the step
is a stutter. Measured: `Collect` total goes 38,016 to 86,400 while distinct
holds at 17,015, and the whole run holds at 20,736 distinct states. The
mutation generates transitions and discovers nothing.

Fix location: none, and none wanted. §5.5 puts 39.3% of single mutations in
this class, and this row is the calibration control the matrix declared it to
be. It does not count against the gate.

### 5.5 Verdict

**The step-2 gate is GREEN.** The reference passes all five checks, no action is
dead, and all 23 variants the matrix expected caught were caught, each with a
named obligation in the log. The seven uncaught rows are the seven the matrix
expected uncaught, each with a named structural cause, which §6's red-arrow
rules count as a finding rather than a failure.

I don't see a repair for a §9.5b agent to make. Nothing in the reference or the
`.cfg` needs to change on the strength of this matrix, and I'd argue against
adding an obligation to chase cause A, because a property set can't catch an
over-constraint and the attempt would only distort the reference.

Two things I'd carry forward rather than fix here:

1. V27 belongs in the §5.2 grading fixtures. It's over-constraint that leaves
   the reachable state set untouched.
2. The implied-init channel names a source location instead of an operator.
   That's a tutor-side gap, filed against §6b rather than against this problem.

## 6. Reproducing this

The variants aren't committed. They're generated from the reference, and the
generator asserts every anchor matches exactly once, so a mutation that misses
its anchor fails loudly instead of producing a green run. Regenerate with the
mutation table in section 2 against
`authoring/buyclub/reference/BuyClub.tla` at the SHA this report lands on.
