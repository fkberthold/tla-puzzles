# Seedlib P4 answer key (shape D)

**Never ship this to a learner or a blind critic.** It lives under
`author-notes/` on purpose. The learner set is `statement/PROBLEM.md`,
`statement/SeedLibrary.tla`, `statement/SeedLibrary.cfg`, and nothing else.

The artifact is frozen-matrix V45: the reference plus V01 plus V43
(`authoring/seedlib/reports/step2-variants.md`). Module renamed, `Init`
helpers added as the disguise, constants inlined. Nothing else moved.

## The two defects

**The observation is a still image.** `SeedLibrary.tla:68-72`. `Observe`
reads `OpeningStock`, `NoDebts` (line 25), and `AllGood` (line 26) where it
should read `shelf`, `owed`, and `standing`. Only `season` reads a variable.
Every field but the calendar reports opening day forever.

**The checkout guard is broken.** `SeedLibrary.tla:34-40`. The prose names
three guards. The spec carries two: `standing[m] = Good` is missing. A member
in default can check out. This is the real behavioral defect the still image
hides.

## Why every check passes anyway

Twelve of the thirteen checks read state only through `Observe`. With three
fields constant:

- **The five invariants.** `ShelfFloor`: opening stock is nonnegative.
  `OneDebtPerKind`: a ledger of zeros never shows two. `ConservationInKind`:
  constant shelf plus constant zero debts equals opening stock, an identity.
  `DefaultIsNeverClean`: nobody is ever seen in default, so the antecedent
  never fires. `TypeOK` is the exception: it reads raw state and is real,
  but types can't see a missing guard.
- **The box-action properties.** All five are subscripted `_Observe`. A step
  that doesn't move `season` doesn't move `Observe`, so it's a stuttering
  step and the property ignores it. Every checkout and return in the model
  is invisible. Only `Close` steps are examined, and at a close the frozen
  fields make every consequent true: shelf holds still (as rule 10 wants),
  debts read zero, standings read good.
- **`TheOpening`.** The frozen values are the opening values. True at `Init`
  by construction.
- **`TheReckoningComes`.** The season field is live, `WF_vars(Close)` still
  forces closes, so the leads-to clauses hold honestly. The end-state clause
  quantifies over members who owe, and nobody is ever seen to owe. This is
  why the freeze stops at `season`: freezing it too goes red (matrix V44).

So the green run establishes types, the calendar's march, and nothing else.
The other ten requirements were measured against a library where nothing
ever happens.

## Why no instrument catches it

Measured on this artifact (step4-screens.md has the table): verdict `OK`
rc=0, `-inv FALSE` proves 90 reachable states, `Gate!NonVacuous` passes,
`vacuity.sh` returns `NON_VACUOUS`, every action fires, and the counts (335
generated, 90 distinct, depth 7) are the reference's counts. The state graph
is fully alive. Only the *view* of it is dead, and no §5.2 or §5.3 probe
reads the view. That hole is filed as `tla-29m4` and this problem is its
teaching instance.

## How to expose it (two worked demonstrations)

**The forbidden behavior.** m1 checks out beans in season 1, returns
nothing, the close marks m1 in default, m1 checks out lettuce in season 2.
Rule: checkout requires good standing (requirement 1). The shipped checks
cannot reject it: the run that admits it is the green run itself, and
`StandingGatesTheShelf` never sees the shelf move. TLC produced this exact
four-state trace as the counterexample to the raw restatement below.

**Instrument 1, stillness.** Add and check
`[][Observe.shelf' = Observe.shelf /\ Observe.owed' = Observe.owed /\
Observe.standing' = Observe.standing]_vars`. Verdict: `OK`, rc=0. A spec
with 90 distinct states satisfies "the visible library never changes". That
single green line is the diagnosis.

**Instrument 2, raw restatement.** Restate requirement 1 over raw state:
`[][\A v : shelf'[v] < shelf[v] => \E m : owed'[m][v] = owed[m][v] + 1 /\
standing[m] = Good]_vars`. Verdict: `LIVENESS_VIOLATION`, rc=13, with the
four-state trace above. The same formula shape over `Observe` is in the
shipped `.cfg` and passes.

Any learner instrument that separates raw movement from observed movement,
or restates one requirement over raw state, or exhibits the trace with the
cannot-reject argument, counts. The three above are worked examples, not the
only answers.

## What counts as an answer (for step 6)

Split per §6's spread rule:

- **(a) naming**: the checks as run measure a view that doesn't track the
  state, so the pass establishes types and calendar movement only. Bonus
  naming: the missing standing guard as the concrete hidden defect.
- **(b) establishing**: a run. Either a constructed instrument with its red
  or damning-green verdict, or the forbidden trace plus the argument that no
  shipped check rejects it. (a) without (b) is an assertion.

A critic who finds only the guard diff and never asks why the run stayed
green has answered neither question in the statement's task section.
