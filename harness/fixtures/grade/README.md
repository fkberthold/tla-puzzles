# Grading fixtures

Fixtures for `harness/grade.sh`, the v2 grading engine (V2-PLAN.md §5.2, bead
`tla-kl5.5`). `selftest.sh` in this directory is the executable spec; run it
with no arguments.

```bash
harness/grade.sh --selftest          # or run selftest.sh directly
```

Every fixture is a submission against the one reference package,
`lockbox/reference/`. The system is a box that holds between zero and three
parcels, one in or one out at a time.

## The fixture matrix

Every row was measured, not predicted. `Adequacy` is obligation 1,
`Relational` is obligation 2 plus the landmarks, `NonVacuity` is obligation 3.

| submission | Adequacy | Relational | NonVacuity | under | over | exit |
|---|---|---|---|---|---|---|
| `correct-different` | PASS 2/2 | PASS 2/2 | PASS | no | no | 0 |
| `too-weak` | FAIL 1/2 | PASS 2/2 | PASS | **yes** | no | 1 |
| `too-strong` | PASS 2/2 | FAIL 0/2 | PASS | no | **yes** | 1 |
| `strict-and-silent` | PASS 2/2 | FAIL 0/1 | PASS | no | **yes** | 1 |
| `both-at-once` | FAIL 1/2 | FAIL 0/2 | PASS | **yes** | **yes** | 1 |
| `vacuous` | PASS 2/2 | FAIL 1/2 | **FAIL** | no | yes | 1 |
| `unparseable` | — | — | — | — | — | 3 |

What each one is for:

- **`correct-different`** models the same system with a different variable, a
  different type and twice the states. It must PASS. This is the fixture that
  reference comparison gets wrong (§3.5), and if a change to `grade.sh` makes
  it fail, the change has re-introduced reference comparison.

- **`too-weak`** and **`too-strong`** raise one flag each. They exist so that
  `both-at-once` raising two flags is evidence of something, rather than the
  behaviour of a grader that always raises both.

- **`strict-and-silent`** is too strong and ships no obligations module at
  all, so obligation 2 has nothing to refute. Only the landmark member can
  catch it. Over-constraint by omission is the form learners actually produce
  — they leave a transition out rather than declaring a rule that is too
  tight. Deleting the landmark loop from `grade.sh` leaves every other
  assertion green and turns this one red; that was verified by doing it.

- **`both-at-once`** is the bead's RED line: too strong on one conjunct and
  too weak on another, at the same time. 23.6% of wrong models are this shape.

- **`vacuous`** has an unsatisfiable `Init`. Obligation 1 grades it PERFECT,
  because an empty state space satisfies every safety property there is, and
  the selftest asserts that alongside the vacuity failure so the consequence
  of deleting obligation 3 stays visible. It is also the maximally
  over-constrained spec — it refines everything, which is why whole-spec
  refinement against a gold reference passes it.

- **`unparseable`** must be reported INVALID and never graded. The danger it
  pins is one this repo actually shipped: `scripts/verify-puzzle.sh` reported
  a PASS on a spec that never parsed, because it read TLC's stdout instead of
  its exit status.

## The verdict object

One JSON object on stdout, and nothing else. Never a diff, never reference
text (§6b.2).

```json
{
  "schema": "tla-puzzles/grade/v1",
  "problem": "lockbox",
  "submission": "both-at-once",
  "verdict": "FAIL",
  "reasons": ["under-constrained", "over-constrained"],
  "under_constrained": true,
  "over_constrained": true,
  "vacuous": false,
  "suites": {
    "Adequacy":   {"status": "FAIL", "met": 1, "total": 2, "unmet": ["R-50f572"]},
    "Relational": {"status": "FAIL", "met": 0, "total": 2,
                   "unmet": ["Req_never_three", "L-ecc90f"]},
    "NonVacuity": {"status": "PASS"}
  },
  "witnesses": {
    "under_constraint": {
      "kind": "reference-obligation-unmet",
      "obligation": "R-50f572",
      "location": {"module": "Lockbox", "line": 32, "action": "Stuff"}
    },
    "over_constraint": {
      "kind": "stated-requirement-refuted",
      "obligation": "Req_never_three",
      "location": {"module": "LockboxObl", "line": 9, "action": null}
    }
  }
}
```

| field | meaning |
|---|---|
| `verdict` | `PASS`, `FAIL`, or `INVALID`. `INVALID` carries `reasons` and `witnesses` only. |
| `reasons` | any of `under-constrained`, `over-constrained`, `vacuous`; for `INVALID`, a §5.1 verdict token. |
| `under_constrained` / `over_constrained` | **independent booleans. Both may be true.** |
| `suites.*.met` / `.total` | per-conjunct partial credit. |
| `suites.*.unmet` | opaque ids for reference-side obligations, verbatim names for submission-side ones. |
| `witnesses` | at most one of each kind; a key is absent when there is no witness. |
| `witnesses.*.location` | module and line, or `null`. `action` is the action name from the trace, and is the only thing read out of a counterexample. |

Exit status: `0` pass, `1` graded failure, `2` usage, `3` invalid submission,
`4` harness error, `5` leak gate tripped and nothing printed.

## Two rules the schema exists to keep

**Reference-side handles are opaque, submission-side ones are verbatim.**
`R-xxxxxx` is a conjunct and `L-xxxxxx` is a landmark, each a digest salted
with the problem id so the same operator name in two problems does not produce
the same id. A learner gets a stable handle to track across attempts and no
text at all. Their own requirement names come back verbatim, because quoting a
learner's own code to them leaks nothing.

What *is* disclosed by design is the cardinality of the reference
decomposition — "1 of 2 met" says there are two. That is what per-conjunct
partial credit means; there is no version of §5.2 that hides it. The content
is what is protected.

**Feedback is error LOCATION.** The only RCT on the question measured location
hints at 9.12 tasks against 5.67 for control, counterexample hints as
statistically indistinguishable from no hint, and natural-language description
hints *below* control (§3.7). So the counterexample trace is read for the
module and line of the action that reached the violating state, and its state
values are never carried out. Prettifying that trace is not an improvement
waiting to be made here — it is the arm that measured as worthless.

## Adding a problem

```
<problem>/reference/*Ref.tla       PHI: Spec, Observe
<problem>/reference/*RefObl.tla    variable-free: Req_*(o), Landmark_*(o)
<problem>/reference/constants.cfg  optional, appended to every generated .cfg
<problem>/submissions/<name>/*.tla     PSI: Spec, Observe
<problem>/submissions/<name>/*Obl.tla  variable-free: Req_*(o), optional
```

Both obligation modules must be variable-free and phrase every predicate over
the observation record `o`. That is not style. Representation is the learner's
to choose (§3.2), so PHI's variables and PSI's variables have nothing to do
with each other, and a predicate over one cannot be evaluated over the other.
Phrasing obligations over the observation (§3.3) is what makes a cross-check
possible at all.

Obligation operators must begin at column 1; that is how `grade.sh` finds
them. One hidden inside a comment would be picked up, referenced by a
generated judge module, and fail to parse — loudly, as a harness error, never
as a grade.
