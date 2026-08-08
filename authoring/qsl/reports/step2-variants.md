# qsl step 2 — reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/qsl/reference/Bureau.tla` and
`Bureau.cfg` at commit `5dba583`. I did not write the reference. Bead
`tla-kstb`.

The matrix in section 1 was authored and frozen before I ran TLC once. Section
2 records the reference's own gate. Section 3 records what each variant did.
Section 4 carries the findings, including the variants nothing caught and why.

Downstream this problem is shape B, so the learner writes the properties and
the statement ships one satisfying and one violating trace per property. Every
caught variant below is candidate material for the violating half, and section
3 records the trace length so the statement author can pick without re-running
anything.

## 1. The frozen matrix

Two families. Family S mutates the system (the `Init`, `Next`, action and
fairness half of the module) and leaves all ten obligations in the `.cfg`
untouched. That is the §5.5 shape: a broken bureau, graded by the properties
the learner is meant to write.

Family P mutates a property instead and asks whether the weakened form still
catches a system variant that the shipped form catches. Shape B puts the
properties in the learner's hands, so a property that passes while missing a
real break is the failure mode this problem grades on. Three probes, no more.

Every mutation below is stated against the reference text, so the matrix reads
as a diff without needing the files.

### Family S — system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | opening-seeded | item 1 | `Init`: `filed = [o \in Operators \|-> ClaimsBy(o)]` |
| S02 | mail-replaces | item 2 | `Mail`: `filed' = [filed EXCEPT ![o] = env]` |
| S03 | mail-allows-self | item 3 | `Mail` draws from `SUBSET [station : Operators, band : Bands]` |
| S04 | mail-carbon-copy | item 4 | extra `Next` disjunct filing one claim into each of two files in one step |
| S05 | credit-ungated | item 5 | `Credit`: drop the `Corroborated(a, c, b)` conjunct |
| S06 | credit-one-sided | item 6 | `Credit`: drop the `![c]` half of the `EXCEPT` |
| S07 | credit-batches-bands | item 7 | `Credit` takes a pair and credits every corroborated band at once |
| S08 | credit-files-its-own-proof | items 4 and 7 | extra disjunct that files the mirror claim and credits the fact in one step |
| S09 | credit-expires | item 8 | extra disjunct removing one credited fact from both sides |
| S10 | fairness-dropped | item 9 | `Spec`: drop `WF_vars(CreditStep)` |
| S11 | credit-self | step-1 flag, item 7's `a # c` | extra disjunct adding `[station \|-> a, band \|-> b]` to `credited[a]` |
| S12 | fairness-one-band | item 9 | `Spec`: `WF_vars` over `Credit(a, c, CHOOSE b \in Bands : TRUE)` only |
| S13 | credit-mirrors-wrong-band | item 6 | `Credit`: the `![c]` half records a band other than `b` |
| S14 | credit-overwrites-register | item 8 | `Credit`: `![a] = {fact}` and `![c] = {fact}`, replacing rather than adding |
| S15 | typeok-station-is-band | `TypeOK` | `Credit` records a band value in the `station` field |
| S16 | mail-empty-envelope | rule 2 | `Mail`: `\E env \in SUBSET ClaimsBy(o)`, keeping the empty envelope |
| S17 | mail-single-claim | rule 2 | `Mail` files one claim per step, never an envelope |
| S18 | credit-once-guard-dropped | rule 4 | `Credit`: drop the `\notin credited[a]` conjunct |
| S19 | credit-one-sided-corroboration | item 5 | `Credit` guards on `[station \|-> c, band \|-> b] \in filed[a]` alone |
| S20 | bureau-never-credits | item 9 | `Next == \E o \in Operators : Mail(o)` |
| S21 | bureau-does-nothing | vacuity | `Next == CreditStep`, so no file ever grows |
| S22 | init-credited-nonempty | items 1 and 5 | `Init`: `credited = [o \in Operators \|-> ClaimsBy(o)]` |

Four of those I expect to come back green, and I want the expectation on the
record before the runs rather than after. S16 and S18 should be uncatchable
because both mutations produce a step that leaves `Observe` unchanged, which
is stuttering and generates no state. `ALTERNATIVES.md` names the empty
envelope as stutter, and the brief names the credited-once guard's
observational vacuity as declared in advance, so a green result at either is a
finding confirmed and not a hole. S17 should be green because no stated item
constrains how many claims an envelope carries. S21 should be green against
the ten obligations and red only under `Gate!NonVacuous`.

### Family P — property mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | comes-whole-wrong-subscript | `CreditComesWhole` subscripted `_(Observe.filed)` | reference, then S07 |
| P02 | only-grow-wrong-subscript | `FilesOnlyGrow` subscripted `_(Observe.credited)` | reference, then S02 |
| P03 | comes-whole-no-a-not-c | `CreditComesWhole`: drop the `a # c` conjunct | reference, then S11 |

P01 and P02 test the step-1 flag about `Observe`-primed action properties going
vacuous under a wrong subscript. A credit step leaves `filed` alone, so
`[][P]_(Observe.filed)` is satisfied by its own stuttering disjunct on every
credit step, and the obligation stops seeing the action it was written for.
P02 is the same move one variable over.

P03 tests the other step-1 flag. `ALTERNATIVES.md` argues the `a # c` conjunct
keeps a self-credit from satisfying `CreditComesWhole` through a collapsed
witness, and concedes that `CreditIsCorroborated` would catch such a step
anyway. P03 measures which of those two claims the harness can see.

### What counts as caught

An invariant catches a variant at rc=12 and an action or temporal property at
rc=13, per §9.5 step 5 and bead `tla-94n`. rc=124 is `TIMEOUT` and is never
read as uncaught. Anything else gets recorded as itself.

For each variant I also name the obligation TLC reported. The verdict comes
from the exit code and only from the exit code. The name comes from the log,
which is where a name is allowed to come from.

## 2. The reference's own gate

Filled in after the runs. See section 3.

## 3. Results

Filled in after the runs.

## 4. Findings

Filled in after the runs.
