# State-representation alternatives considered and rejected

Reference spec: `PermitReview.tla`. This note covers what the state could have been
and why it is what it is. It is not commentary on the spec — that is a later pass.

The chosen state is three variables:

```
position   \in [Departments -> {"none", "approved", "changes"}]
amendments \in 0..MaxAmendments
status     \in {"open", "issued", "withdrawn"}
```

## 1. Outcome: one `status` variable vs. two booleans

**Rejected: `issued` and `withdrawn` as two separate boolean variables.**

The fixed observation operator exposes two booleans, which makes two boolean
variables the obvious move. It is the wrong move. Two booleans admit the state
`issued = TRUE /\ withdrawn = TRUE`, which the system has no meaning for, and the
spec would then need an invariant to rule out a state that should never have been
representable. A single three-valued `status` makes the outcome mutually exclusive
by construction, and `Pending == status = "open"` becomes the single guard that
every action shares.

The cost is that `OutcomeExclusive` is no longer falsifiable by any mutation of the
state machine — with one `status` variable, `Observe.issued` and `Observe.withdrawn`
cannot both be true. It is retained anyway, because it is no longer a check on the
state machine but a check on `Observe` itself, and `Observe` is the graded
interface. It fires if the operator is ever misdefined.

This choice is also the clearest demonstration that `Observe` is
representation-neutral: the interface promises two booleans and the state does not
have them.

## 2. Freshness: clear positions on amendment vs. version-stamp them

This is the substantive one.

**Chosen:** an amendment sets `position` to all-`"none"`. A recorded position
therefore always refers to the current version, and `ApprovedBy` is the set of
departments approving the current version by construction.

**Rejected: keep positions across an amendment and stamp each with the version it
refers to** — `reviewedVersion \in [Departments -> 0..MaxAmendments]` alongside a
`version` counter, with
`ApprovedBy == {d : position[d] = "approved" /\ reviewedVersion[d] = version}`.

Three reasons it loses:

- It contradicts the stated rule. Rule 3 says an amendment *clears* every recorded
  position. The version-stamp representation implements "an amendment makes every
  position stale", which is a different sentence that happens to be observationally
  equivalent. A spec should say what the rules say.
- It introduces states that are distinct but observationally identical. A
  department carrying a stale `"approved"` from version 0 and one carrying a stale
  `"changes"` from version 0 look the same through `Observe` and behave the same
  forever after. Junk distinctions are bad on their own terms and are worse here,
  because the grading interface is a behaviour comparison and phantom states inflate
  the graph without adding behaviour.
- It costs a factor of `(MaxAmendments+1)^|Departments|` in state space for
  information that the chosen representation encodes in `position` alone.

**A hybrid was also rejected**: keep clearing, but *additionally* carry
`approvedVersion` as an auxiliary variable purely so the version claim becomes
checkable. It does not work. After an amendment clears `position` to all-`"none"`,
`approvedVersion` retains arbitrary stale entries, so the same phantom-state problem
reappears — and resetting `approvedVersion` on amendment too makes it exactly
redundant with `position`, catching nothing.

### What this choice costs, stated plainly

Clearing on amendment makes the version clause of the required property *true by
construction rather than checked*. `IssuedOnlyWhenUnanimous` cannot falsify a spec
that bumps the amendment counter without clearing positions: in that variant the
stale approvals still read `"approved"`, `ApprovedBy` is still `Departments`, and
the invariant passes.

Measured, not assumed. The mutation that drops the clearing assignment runs to
completion with every invariant satisfied. The gap is closed instead by an action
property:

```
AmendmentClearsApprovals ==
    [][ (amendments' # amendments) => (Observe'.approvedBy = {}) ]_vars
```

which is the only formal witness rule 3 has, is stated in the observable
vocabulary, and costs no state. Against that mutation it fires at rc=13.

## 3. Bounding amendments: guard in the spec vs. `CONSTRAINT` in the config

**Chosen:** `await amendments < MaxAmendments` inside the amend action, so the bound
is part of the specified system.

**Rejected: leave the spec unbounded and cut the state space with
`CONSTRAINT amendments <= MaxAmendments` in the `.cfg`.** The idiomatic argument for
the constraint is real — the actual city imposes no amendment limit, and a spec
should not invent one. It loses here for two reasons specific to this pipeline.
First, a `CONSTRAINT` truncates behaviours, and TLC's temporal checking over
truncated behaviours is not sound in general; this spec declares three temporal
properties. Second, with the bound in the `.cfg`, the reachable graph is a property
of the config rather than of the module, so a competing spec has to replicate the
config exactly to be compared against this one. With the bound in the action, the
module alone determines the behaviour set.

## 4. Bounding position changes

**Not done, and no constant was added for it.** The brief anticipated that rule 2's
free flipping might need a bound. It does not. `position` ranges over a finite
function space (`3^|Departments|`) no matter how often departments flip, so free
flipping costs nothing in reachable states — it only adds edges. Measured: 220
distinct states at 3 departments and `MaxAmendments = 3`, 815 at 4 departments and
`MaxAmendments = 4`, both under one second. Adding a flip-count constant would have
bounded a quantity that was never unbounded, and would have put an artificial rule
into the learner's statement.

## 5. Departments as strings vs. model values

**Chosen:** plain strings in the `.cfg`.

**Rejected: TLC model values plus `SYMMETRY`.** Symmetry reduction is the usual
reason to reach for model values, and it is unavailable here: this spec declares
temporal properties, and `SYMMETRY` makes temporal checking unsound (Specifying
Systems p.244/246; the harness enforces this independently — `refinement.sh` exits
24 `UNSOUND_REDUCTION` on a config carrying `SYMMETRY` or `VIEW`). With symmetry off
the table, model values buy nothing and cost trace readability. Strings also survive
being handed to a separately-authored competing spec without a shared config.

The spec does carry `ASSUME Departments \cap {"applicant", "city"} = {}`, because the
applicant and the city are PlusCal processes with string identifiers and a department
named `"city"` would collide with one. The assumption holds trivially for model
values too, so the spec is not locked to strings.

## 6. Structure: three PlusCal process groups vs. one process with `either`

**Chosen:** `Reviewer \in Departments`, `Applicant = "applicant"`, `City = "city"`.

**Rejected: a single process whose body is one big `either`.** Under interleaving
semantics the two are equivalent, and the single-process version is shorter. Three
process groups win because the system description names three kinds of independent
actor moving at their own pace, and the process structure is the part of PlusCal
that says so. It also keeps issuance attributed to the city rather than smuggled
into the applicant's step.

The translation costs nothing for this: each process body is a single-label
`while (TRUE)` loop, so the translator elides `pc` entirely and `vars` is just the
three real variables.

## 7. Deadlock

Terminal states are real here — once `status` leaves `"open"`, no action is enabled.
That is what "final" means, so the config carries `CHECK_DEADLOCK FALSE` rather than
the spec carrying an artificial self-loop action to keep the state machine moving.

The line is load-bearing: with it removed the correct spec exits 11. It is
belt-and-braces against the harness, which already defaults deadlock checking off,
but it makes a bare `tlc PermitReview` run clean.

**Rejected: `while (Pending)` instead of `while (TRUE)`**, which would let each
process fall through to `Done` and let the translator emit its own `Terminating`
disjunct, removing the deadlock without a config line. It multiplies every terminal
state by the 2^5 combinations of which processes have noticed yet — pure `pc` noise
in the region of the graph the safety property is about.
