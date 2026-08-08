# Grading fixtures

Fixtures for `harness/grade.sh`, the v2 grading engine (V2-PLAN.md §5.2, bead
`tla-kl5.5`). `selftest.sh` in this directory is the executable spec; run it
with no arguments.

```bash
harness/grade.sh --selftest          # or run selftest.sh directly
```

There are three problem packages, and the same system underlies all of them: a
box that holds between zero and three parcels, one in or one out at a time.

| package | what it is for |
|---|---|
| `lockbox/` | the state-predicate problem, every obligation over ONE observation |
| `stepwise/` | the same system with "one at a time" stated over a PAIR of successive observations |
| `smuggled-constants/` | a problem package whose `constants.cfg` carries a directive |

## The fixture matrix

Every row was measured, not predicted. `Adequacy` is obligation 1,
`Relational` is obligation 2 plus the landmarks, `NonVacuity` is obligation 3.

### `lockbox/`: one-state obligations

| submission | Adequacy | Relational | NonVacuity | under | over | exit |
|---|---|---|---|---|---|---|
| `correct-different` | PASS 2/2 | PASS 2/2 | PASS | no | no | 0 |
| `too-weak` | FAIL 1/2 | PASS 2/2 | PASS | **yes** | no | 1 |
| `too-strong` | PASS 2/2 | FAIL 0/2 | PASS | no | **yes** | 1 |
| `strict-and-silent` | PASS 2/2 | FAIL 0/1 | PASS | no | **yes** | 1 |
| `both-at-once` | FAIL 1/2 | FAIL 0/2 | PASS | **yes** | **yes** | 1 |
| `vacuous` | PASS 2/2 | FAIL 1/2 | **FAIL** | no | yes | 1 |
| `unparseable` | — | — | — | — | — | 3 |
| `wrong-shaped-observation` | — | — | — | — | — | 3 |

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

- **`wrong-shaped-observation`** parses and model-checks perfectly well. What
  it gets wrong is the graded interface: its record has a `hue` field where
  the reference reads `o.level`, so every obligation blows up mid-evaluation
  (rc=75) instead of coming out false. A check that never ran is not a
  violation, and it is not a harness fault either. Getting the interface
  wrong is a learner error, so it grades INVALID. It used to exit 4.

### `stepwise/`: one two-state obligation as well

Same lockbox, with "one at a time" stated as `Step_onestep(o, p)` over a pair
of successive observations and judged as
`[][Step_onestep(Observe, Observe')]_Observe`, declared `PROPERTY`.

| submission | Adequacy | Relational | NonVacuity | under | over | exit |
|---|---|---|---|---|---|---|
| `correct` | PASS 2/2 | PASS 2/2 | PASS | no | no | 0 |
| `correct-different` | PASS 2/2 | PASS 2/2 | PASS | no | no | 0 |
| `chaos-observations` | FAIL 1/2 | PASS 2/2 | PASS | **yes** | no | 1 |
| `frozen-observe` | PASS 2/2 | FAIL 1/2 | PASS | no | **yes** | 1 |

- **`chaos-observations`** is why the package exists, and the first thing to
  say about it is what it is not. Its observation operator is maximally
  *honest*. The variable **is** the observation. What it has no trace of is
  transition structure: every permitted observation is an initial state and
  any may follow any other. Against `lockbox/reference/` it grades a clean
  PASS with zero witnesses, and it is right to. Every single-state requirement
  a reference can state about this system is true of it, because its reachable
  observation set is exactly the admissible one. The maximally permissive spec
  passes obligation 1 **by construction**, for any reference, and needs no lie
  to do it. Only a two-state obligation refuses it. Beads `tla-59s` and
  `tla-x8s`.

- **`frozen-observe`** is the trapdoor inside that fix. `[][A]_Observe`
  unfolds to `A \/ UNCHANGED Observe`, so an observation that never moves
  satisfies every step obligation vacuously. That is the frozen-mapping hole
  from the TLAiBench survey §6, reappearing inside the answer to it. It
  passes both Adequacy members. The landmark suite is what catches it, which
  is why `grade.sh` **requires** two pairwise-unsatisfiable landmarks of any
  problem that states a `Step_*` rather than recommending them.

The two reference packages beside `stepwise/reference/` are malformed on
purpose and drive that requirement: `reference-one-landmark/` states a
`Step_*` with one landmark, and `reference-overlapping/` states two that
level 3 satisfies together. Both are exit 2 against any submission. The
defect is the problem author's, and no verdict about a submission is printed.

### `smuggled-constants/`

One reference whose `constants.cfg` carries `(* pad *) INVARIANT TypeOK`, and
one correct submission that happens to define a `TypeOK`. Exit 2.

A `.cfg` directive is a **token, not a line**: only `\*` comments out the rest
of a line, so a directive riding a block comment or the tail of a `CONSTANT`
assignment is live to TLC and invisible to a line-anchored guard. Without the
refusal the smuggled invariant fires, `grade.sh` reads the rc=12 as "the
reference obligation was unmet", and a correct submission is reported
under-constrained. Measured, and it grades PASS against the same reference
with the fragment removed. Bead `tla-j8yd`, the same class as `tla-nesz` in
`refinement.sh` and `tla-40y` in `seeded-bugs.sh`.

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
<problem>/reference/*RefObl.tla    variable-free: Req_*(o), Step_*(o, p),
                                   Landmark_*(o)
<problem>/reference/constants.cfg  optional, CONSTANT assignments ONLY
<problem>/submissions/<name>/*.tla     PSI: Spec, Observe
<problem>/submissions/<name>/*Obl.tla  variable-free: Req_*(o), optional
```

`constants.cfg` is appended verbatim to every generated judge `.cfg`, so it is
the one place a problem package could write part of the configuration that
grades it. It carries `CONSTANT` / `CONSTANTS` and nothing else, and a
directive anywhere in it is refused, including one behind a `(* block
comment *)` or riding the tail of an assignment, both of which TLC reads as
live directives.

**A `Step_*` obliges you to two landmarks.** `[][Step(Observe, Observe')]_Observe`
is satisfied vacuously by a submission whose observation never moves, and
nothing you write inside `Step` can change that. It is never the disjunct
that gets taken. The landmark suite is the only probe that refuses a frozen
observation, and it can only refuse one when no single observation satisfies
two landmarks at once. So `grade.sh` requires two or more, pairwise
unsatisfiable, and refuses the package otherwise. That is checked rather than
advised: the count is static and the unsatisfiability is one model-checking
run over the reference.

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
