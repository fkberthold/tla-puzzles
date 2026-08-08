# Seedlib step 2 — reference verification and the frozen variant matrix

V2-PLAN §9.5, bead `tla-ngg5`, wave seat P4. Agent B. The reference is agent A's
(`authoring/seedlib/reference/`, landed at 75a2996) and I did not write it.

Downstream this problem is shape D, diagnose a vacuous pass. So the matrix below carries a
column the plan's template does not: for every variant that comes back green, whether
`harness/vacuity.sh` calls it vacuous. A mutant that passes and that the vacuity probes also
call clean is the sharpest thing this step can hand the statement author.

**Gate verdict: RED.** 36 of 47 caught, 11 uncaught. Four of the eleven are caught by the
vacuity probes instead. Seven pass everything the harness has. Section 5 says where each fix
lives, and I think only one of the eleven is a defect in the reference's property set.

Every run went through `harness/verdict.sh -t 300` against the shipped `MCSeedLib.cfg`
unchanged, with the module named by absolute path and
`JAVA_TOOL_OPTIONS=-DTLA-Library=<worktree>/harness`. TLC2 Version 2026.07.31.184830.

## 1. The reference

The four §9.5 checks, in order.

| check | command | result |
|---|---|---|
| 1 green | `verdict.sh -t 300 MCSeedLib.tla` | `OK`, rc=0 |
| 2 reachable | same, `-- -inv FALSE` | `SAFETY_VIOLATION`, rc=12 |
| 3 non-vacuous | same, `-p Gate!NonVacuous` | `OK`, rc=0 |
| 4 live actions | `-coverage 1`, `total == 0` on nothing | pass, table below |

Check 6, the counts: **311 states generated, 90 distinct, depth 7.** The temporal pass ran 3
branches over 270 total distinct states. That matches the hand count agent A recorded at
step 1, and it sits under the "fewer than two thousand" estimate in HANDOFF section 4.

Action coverage, distinct:total.

| action | coverage |
|---|---|
| `Init` | 1:1 |
| `Checkout` | 53:112 |
| `Return` | 0:188 |
| `Close` | 36:103 |

`Return` reads `0:188`, and it's worth pausing on. Zero distinct, 188 total. A return undoes
a checkout, so it lands back on a state the search already holds. This is §5.3's warning
standing up in live data: key the dead-action probe on `distinct` and you'd fail the
reference. `harness/vacuity.sh` keys on `total` and returns `NON_VACUOUS`.

`TLC` decomposes `Next` into the three named actions even though `Checkout` and `Return`
share one existential. That matters for the matrix, because it's what lets the dead-action
probe see a single starved action. Section 5 shows where it stops working.

## 2. The matrix, frozen

Authored before any TLC run, per §9.5 and §6's red-arrow rules. The mutation column did not
move after the first run.

Every mutation is against `authoring/seedlib/reference/SeedLib.tla` unless the row says
otherwise. `R` names a rule in HANDOFF section 1, `P` an item in section 2. **vac** is the
`harness/vacuity.sh` verdict, run only where the properties came back green.

| id | mutation | breaks | rc | caught by | vac |
|---|---|---|---|---|---|
| V01 | `Checkout` drops `standing[m] = Good` | R4b, P1 | 13 | StandingGatesTheShelf | |
| V02 | `Checkout` drops `shelf[v] > 0` | R4c, P2 | 12 | TypeOK, then ShelfFloor | |
| V03 | `Checkout` drops `owed[m][v] = 0` | R4d, P4 | 12 | OneDebtPerKind | |
| V04 | `Checkout` drops `InProgress` | R4a, P9 | 12 | TheReckoningComes, 2nd clause | |
| V05 | `Checkout` guard `shelf[v] > 99` | R4c | 0 | nothing | DEAD_ACTION |
| V06 | `Checkout` guard `standing[m] = Default` | R4b | 0 | nothing | DEAD_ACTION |
| V07 | `Checkout` guard `shelf[v] > 1` | R4c | 0 | nothing | NON_VACUOUS |
| V08 | `Checkout` leaves the shelf alone | R4e, P5 | 12 | ConservationInKind, then LedgerDiscipline | |
| V09 | `Checkout` raises the shelf count | R4e, P5 | 12 | ConservationInKind, then ShelfDiscipline | |
| V10 | `Checkout` takes the other variety off the shelf | R4e, P3 | 12 | ConservationInKind, then StandingGatesTheShelf | |
| V11 | `Checkout` writes no debt | R4f, P5 | 12 | ConservationInKind, then StandingGatesTheShelf | |
| V12 | `Checkout` bills the other member | R4f, P3 | 12 | OneDebtPerKind | |
| V13 | `Checkout` takes both varieties off the shelf | R4g, P2 | 12 | ConservationInKind, then StandingGatesTheShelf | |
| V14 | `Checkout` also puts the member in default | R3b, P6 | 13 | CloseSquaresTheBook | |
| V15 | `Return` drops `owed[m][v] > 0` | R5b, P3 | 12 | TypeOK, then DefaultIsNeverClean | |
| V16 | `Return` drops `InProgress` | R5a, P9 | 13 | TheEndIsTheEnd | |
| V17 | `Return` guard `owed[m][v] > 1` | R5b | 0 | nothing | DEAD_ACTION |
| V18 | `Return` also requires good standing | R6d | 0 | nothing | NON_VACUOUS |
| V19 | `Return` leaves the shelf alone | R5c, P5 | 12 | ConservationInKind, then LedgerDiscipline | |
| V20 | `Return` clears a debt of the other variety | R5d, P3 | 12 | TypeOK, then ConservationInKind | |
| V21 | `Return` leaves standing alone | R5e, P7 | 12 | DefaultIsNeverClean | |
| V22 | `Return` reads `owed` where it means `owed'` | R5e, P7 | 12 | DefaultIsNeverClean | |
| V23 | `Return` restores standing with debts still open | R5e, P6 | 13 | CloseSquaresTheBook | |
| V24 | `Close` leaves standing alone | R6a, P6 | 13 | CloseSquaresTheBook | |
| V25 | `Close` defaults everybody | R6b, P7 | 12 | DefaultIsNeverClean | |
| V26 | `Close` wipes the ledger | R6c, P10 | 12 | ConservationInKind, then DefaultIsNeverClean | |
| V27 | `Close` skips a season | R2a, P10 | 13 | TheCalendarMarches | |
| V28 | `Close` drops `InProgress` | R2d, P9 | 12 | TypeOK, then TheEndIsTheEnd | |
| V29 | `Close` restocks the shelf | R6c, P10 | 12 | ConservationInKind, then ShelfDiscipline | |
| V30 | `Close` waits for a clear book | R2b, P8 | 13 | TheReckoningComes | |
| V31 | `Spec` drops `WF_vars(Close)` | R2b, P8 | 13 | TheReckoningComes | |
| V32 | `NumSeasons == 4` | R2a | 0 | nothing | NON_VACUOUS |
| V33 | `Return` also moves the calendar | R2c, P10 | 13 | TheCalendarMarches | |
| V34 | `Init` opens in season 2 | R2, P11 | 13 | TheOpening, on the initial state | |
| V35 | `Init` opens everybody in default | R3a, P11 | 12 | DefaultIsNeverClean | |
| V36 | `Init` opens with an empty shelf | R1, P11 | 12 | ConservationInKind | |
| V37 | `Init` carries a contradiction | vacuity control | 0 | nothing | EMPTY_SPACE |
| V38 | `Observe` freezes `standing` | P3 interface | 13 | CloseSquaresTheBook | |
| V39 | `Observe` freezes `owed` | P3 interface | 12 | ConservationInKind, then StandingGatesTheShelf | |
| V40 | `Observe` freezes `shelf` | P3 interface | 12 | ConservationInKind, then LedgerDiscipline | |
| V41 | `Observe` freezes `season` | P3 interface | 13 | CloseSquaresTheBook | |
| V42 | `Observe` freezes `shelf` and `owed` | P3 interface | 12 | DefaultIsNeverClean | |
| V43 | `Observe` freezes all but `season` | P3 interface | 0 | nothing | NON_VACUOUS |
| V44 | `Observe` freezes every field | P3 interface | 13 | TheReckoningComes | |
| V45 | V43 plus V01 | P3 interface | 0 | nothing | NON_VACUOUS |
| V46 | `Next` drops `Return` | R5 | 0 | nothing | NON_VACUOUS |
| V47 | `Next` drops `Close` | R2b, P8 | 0 | nothing | NON_VACUOUS |

23 caught at rc=12, 13 at rc=13, 11 green.

A "then" in the caught-by column names a second obligation that also catches the variant
once the first is taken out of the `.cfg`. Section 4 has those runs. The shipped `.cfg` is
what the rc column reports, and nothing in it moved.

Rule coverage, so the gaps show rather than hide. Rule 1 goes to V08 to V13, V19, V20 and
V36. Rule 2 to V04, V16, V27 to V33 and V47. Rule 3 to V14, V21, V22 and V35. Rule 4 to V01
to V13. Rule 5 to V15 to V23 and V46. Rule 6 to V18 and V24 to V26. The step-1 author flags
go to V12 for the exists-a-member signature, V23 and V24 for item 6's three clauses, and V25
for the way out of default at a close.

The `Observe` block, V38 to V45, isn't in §9.5's template. I added it because shape D wants
a green run that means nothing, and a frozen observation is the one mutation class that can
satisfy every obligation without touching the model. §5.4 names the frozen-mapping hazard for
refinement. V38 to V45 ask whether the same hazard reaches §5.2's `Observe`, and V43 says it
does.

## 3. The eleven that got through

Counts first, because two of them are the whole finding.

| id | generated | distinct | depth | vacuity |
|---|---|---|---|---|
| V05 | 4 | 4 | 4 | DEAD_ACTION, rc=5 |
| V06 | 4 | 4 | 4 | DEAD_ACTION, rc=5 |
| V07 | 30 | 16 | 5 | NON_VACUOUS |
| V17 | 163 | 90 | 7 | DEAD_ACTION, rc=5 |
| V18 | 247 | 90 | 7 | NON_VACUOUS |
| V32 | 440 | 123 | 8 | NON_VACUOUS |
| V37 | 0 | 0 | 0 | EMPTY_SPACE, rc=3 |
| V43 | **311** | **90** | **7** | NON_VACUOUS |
| V45 | 335 | **90** | **7** | NON_VACUOUS |
| V46 | 163 | 90 | 7 | NON_VACUOUS |
| V47 | 41 | 12 | 4 | NON_VACUOUS |

V43's row is the reference's row. Same generated count, same distinct count, same depth, and
the same four coverage figures (`1:1`, `53:112`, `0:188`, `36:103`). I ran §9.5's checks 1 to
4 against it in full and it clears all four. So the whole of step 2, run by the book, waves
V43 through without a mark against it.

V45 is V43 with agent A's `Checkout` standing guard removed. V01 on its own is rc=13. With
the frozen `Observe` on top it's rc=0, and even the distinct count stays at 90, because the
extra transitions all land on states the search already holds. A real behavioral defect,
invisible in every number this step produces.

One threshold note for central. V05 and V06 have exactly 4 distinct states, and
`Gate!NonVacuous` is `TLCGet("distinct") >= 4`. Both clear it by one, measured directly at
rc=0. The reference has 90. Whatever gate this problem ships with should set `--min-states`
well above the placeholder, and I'd put it at 90 rather than at some round number under it.

## 4. Diagnostics outside the frozen set

Four runs I added after the matrix closed. None of them changes a row above.

**D1, the V47 mechanism.** V47 removes `Close` from `Next` and leaves `WF_vars(Close)` in
`Spec`. Fairness then demands a step `[][Next]_vars` forbids, so no behavior satisfies `Spec`
and every temporal obligation holds over nothing. Taking `WF_vars(Close)` out as well turns
it red: rc=13, `Temporal property TheReckoningComes was violated`. That's the confirmation.
The invariants still bite in V47, because TLC checks those over the state graph and fairness
never touches it. Only the liveness half goes blind.

**D2, the `TypeOK` question.** Four variants were caught by `TypeOK`, which isn't one of
HANDOFF section 2's eleven. Re-running them with `TypeOK` out of the `.cfg` catches all four
on a stated property: V02 on `ShelfFloor`, V15 on `DefaultIsNeverClean`, V20 on
`ConservationInKind`, V28 on `TheEndIsTheEnd`. So `TypeOK` fires first but carries nothing on
its own, and the eleven stand without it.

**D3**, the full §9.5 checklist against V43 and V45, is in section 3.

**D4, the shadowing question.** `ShelfDiscipline` and `LedgerDiscipline` were never the named
catcher of anything, which looks like dead weight. It isn't. With `ConservationInKind` and
`TypeOK` out of the `.cfg`, ten shelf and ledger variants all still go red, and
`LedgerDiscipline` picks up V08, V19 and V40 while `ShelfDiscipline` picks up V09 and V29.
They're shadowed by an invariant that fires earlier, not redundant.

## 5. Where each uncaught variant's fix lives

I'm not fixing anything, per §9.5. This is the repairer's map.

**V07, V18, V32 — not the reference's fault, as far as I can tell.**

Every obligation in HANDOFF section 2 says what must never happen. None of them says anything
must be possible. So an over-strong guard shrinks the behavior set, and a smaller behavior set
satisfies a safety obligation more easily, never less. V07 tightens `Checkout` to
`shelf[v] > 1` and V18 tightens `Return` to good standing only. Both leave every stated
property true.

Closing them needs a new obligation, not a repair to an existing one. Something of the shape
"in some reachable state a member in good standing with a stocked variety and no debt of it
takes it out". That's an addition to the description, so I think it belongs to whoever owns
HANDOFF section 2 rather than to the repairer. V18 in particular breaks Rule 6d, which the
prose states plainly and which section 2 then never turns into a property.

V32 is a different animal. `NumSeasons == 3` is a definition, `Ended` is `NumSeasons + 1`,
and `TheReckoningComes` quantifies over `1..NumSeasons`. Move the horizon and the whole
property set moves with it. HANDOFF section 4 says the properties don't read the program's
numbers, so this is the description working as written. Pinning it would mean making
`NumSeasons` a `CONSTANT` so the `.cfg` fixes it, and I'd leave that alone unless somebody
wants the horizon graded.

**V05, V06, V17, V37 — the vacuity probes already hold these.**

None is a property defect. All four are caught by `harness/vacuity.sh`, three as
`VACUOUS_DEAD_ACTION` and V37 as `VACUOUS_EMPTY_SPACE`. The fix is procedural: this problem's
gate has to run the vacuity component, not just the property set. V06 is worth keeping in
view for the statement anyway, because flipping `Good` to `Default` in one guard is the kind
of thing a learner really writes, and it collapses a 90-state model to 4.

**V43, V45 — a real gap, and it's in the grading engine.**

Freezing `Observe` on three of its four fields satisfies every obligation by making each
one's trigger unreachable. The identity in `ConservationInKind` is what makes it work: a
constant shelf plus a constant zero ledger balances exactly, so property 5 stays true while
seeing nothing. Freezing `standing` as well kills `DefaultIsNeverClean`'s antecedent, and
leaving `season` live keeps `TheReckoningComes` honest, which is what stops V44 from working.

The boundary is sharp and worth recording. Freeze one field and it's caught every time, at
V38 to V41. Freeze `shelf` and `owed` together and `DefaultIsNeverClean` still catches it, at
V42. Freeze all four and `TheReckoningComes` catches it, at V44. There's one hole in the
lattice, and V43 sits in it.

Fixing that inside the property set looks wrong to me. The obligations are all stated over
`Observe`, so any of them can be blinded the same way. §5.4 already carries the frozen-mapping
probe for refinement, and `Gate.tla`'s own comment says to run it alongside
`RefinementConfigured` because the two catch disjoint failures. §5.2's `Observe` has no
equivalent. That reads to me like the same hole one component over, and I'd file it against
the grading engine rather than against seedlib.

**V46, V47 — two holes in the vacuity component.**

V46 removes `Return` from `Next`. V17 restricts the same action to nothing. Same observable
behavior, and the probe catches one and not the other, because `total == 0` needs a coverage
row and a deleted action has none. I checked the logs: V46's coverage lists `Init`,
`Checkout` and `Close` and no `Return` at all.

V47 is the sharper of the two, and I think it's a vacuity vector nobody has written down.
`harness/vacuity.sh` covers three: an empty state space, an unchecked obligation over a
healthy one, and a dead action. V47 is a fourth. An unsatisfiable fairness conjunct empties
the set of *behaviors* while the state space stays healthy, so every temporal obligation
passes with nothing to check. `NonVacuous` sees 12 distinct states and passes.
`InvariantConfigured` passes. No action has `total == 0`. D1 is the evidence for the
mechanism.

Both are harness findings rather than seedlib findings. I'd file V47 as a bead against §5.3.

## 6. For the shape-D statement author

Ranked. All five are green under the shipped `.cfg`.

1. **V45.** A frozen `Observe` hiding a real broken guard. The learner has both questions to
   answer: why the run means nothing, and what it was covering up. The state counts match the
   reference, so there's no numeric tell.
2. **V43.** The same mechanism with no bug underneath. Cleaner if the statement wants the
   diagnosis alone. Its numbers are the reference's, figure for figure.
3. **V47.** Fairness that can't be met. A different mechanism from the two above, and it
   needs the learner to reason about `Spec` rather than about the properties.
4. **V46.** A deleted action. Good for teaching why `total == 0` isn't the whole story, and it
   pairs with V17 as a matched before and after.
5. **V06.** The most plausible learner mutation in the set, one word changed. Weaker as a D
   artifact because `vacuity.sh` does catch it, but it's the one that shows a 90-state model
   collapsing to 4 with a guard that reads fine.

V43 and V45 are the two I'd build the statement on. They're the only ones where every
instrument this pipeline owns says the spec is healthy.
