# Chapter 09 cold-solve review

Reviewer is a second agent from a different model family than the exercise
author, per bead `tla-jb7f.21`. Phase 1 solved blind from a delivered tree.
Phase 2 reviewed open-book against references, reports, COVERAGE.md, the
ch09 sheet, and a shallow clone of `hwayne/learntla-v2` at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`.

Clone SHA verified: `git -C /tmp/learntla-v2-review.WOZ6Fv rev-parse HEAD`
returned `09840bfc2ee9a88cdbedb672be77a6c73942fe16`, matching the pin.

## Methodology caveat on timing

Every per-exercise time below is agent wall-clock (tool calls plus
reasoning), measured with `date +%s` before and after each exercise. It is
not comparable to a human learner's cognitive time reading PlusCal for the
first time, and the BUDGET check below is written with that limit stated
plainly rather than papered over.

A second caveat on the two predict-then-check exercises. I read the whole
`EXERCISES.md` file, including the "After the run" answer sections, in one
pass before starting the timed exercise work, because planning phase 1
required knowing the document's structure. I could not stop short of the
"Run before you read on" lines the way a human reader physically could. My
Ex4 and Ex5 predictions below were reasoned from first principles rather
than recalled, and they came out the same as what I had already read, so I
cannot claim they are blind in the way the exercise design intends. This is
a structural limit of a full-file Read tool, not a finding about the
exercise text.

## Phase 1 solve log

Delivered with `bash scripts/deliver-exercises.sh 9 <mktemp-dir>`, worked
only inside `starters/`, `EXERCISES.md`, `cheatsheets/`.

### Exercise 1, Footbridge

- Start `1786582826`, end `1786582931`. 105s.
- Solved on first attempt. Wrote `States`, one `state` variable, a
  `Warden` process with an `either` of three `await`-guarded branches, and
  `StateOK` / `CondemnedIsForever` in a `define` block.
- Pass run: `OK`. Reproduced.
- Fail run 1 (reopening branch added): `SAFETY_VIOLATION` rc=12.
  Reproduced.
- Fail run 2 (`PROPERTY` removed from the config, `StateOK` alone): `OK`
  rc=0. Reproduced.
- Nothing guessed at. No stuck points.

### Exercise 2, Kiln

- Start `1786582944`, end `1786583019`. 75s.
- Solved on first attempt. Filled `FiringFinishes == <>(stage = "cooled")`
  first, ran it with `fair` still absent (`LIVENESS_VIOLATION` rc=13, "the
  run worth having"), then added `fair` for the pass run (`OK` rc=0).
- Fail run 2 (fairness kept, `soaks := soaks + 1` changed to
  `soaks := 0`): `LIVENESS_VIOLATION` rc=13. Reproduced.
- The instruction ordering ("Then do it in the other order. Fill TODO 2
  first, leave TODO 1 alone, and run it.") took a careful second read to
  parse correctly. See AMBIGUITY finding below.

### Exercise 3, LoadingBay

- Start `1786583021`, end `1786583072`. 51s.
- Solved on first attempt. Filled
  `EveryoneKeepsDocking == \A h \in Hauliers: []<>(bay = h)`.
- Weak-fairness run (as shipped): `LIVENESS_VIOLATION` rc=13. Reproduced.
- `fair+` run: `OK` rc=0. Reproduced.
- Fail run (`fair+` kept, `Go` changed to `bay := self`):
  `LIVENESS_VIOLATION` rc=13. Reproduced.
- Nothing guessed at.

### Exercise 4, Beacon (predict-then-check)

- Start `1786583090`, end `1786583188`. 98s.
- Prediction written to `LOG.md` before running: `EverLit=OK`,
  `LitAgainAndAgain=OK`, `SettlesLit=LIVENESS_VIOLATION`.
- Result: `OK`, `OK`, `LIVENESS_VIOLATION` rc=13. Matched exactly.
- Fail sweep 1 (`fair` deleted): all three `LIVENESS_VIOLATION` rc=13.
  Reproduced.
- Fail sweep 2 (fairness kept, lamp never lights): all three
  `LIVENESS_VIOLATION` rc=13. Reproduced.
- Side note: running `pcal starters/Beacon.tla` (needed to remove/restore
  `fair` in the PlusCal comment) auto-created a `starters/Beacon.cfg` and a
  `starters/Beacon.old` backup, neither of which any printed command
  touches, since Ex4 uses three separately-named `.cfg` files instead of a
  default `Beacon.cfg`. See NOTE finding below.

### Exercise 5, Depot (predict-then-check)

- Start `1786583191`, end `1786583282`. 91s.
- Prediction written to `LOG.md` before running: `Depot.cfg` with
  `MaxOpen == 0` gives `OK` because the Book branch is never enabled and
  both `~>` halves are vacuously true. `DepotProbe.cfg` also `OK`, the tell
  that the first `OK` was vacuous. With `MaxOpen == 2`: `Depot.cfg` stays
  `OK`, `DepotProbe.cfg` flips to `SAFETY_VIOLATION`.
- Result: all four matched exactly (`OK`, `OK`, then `OK`,
  `SAFETY_VIOLATION` rc=12).
- Fail run 1 (`MaxOpen == 2`, collect branch deleted): `LIVENESS_VIOLATION`
  rc=13 on `Depot.cfg`. Reproduced.
- Fail run 2 (`MaxOpen == 2`, `fair` deleted instead): `LIVENESS_VIOLATION`
  rc=13 on `Depot.cfg`. Reproduced.
- Nothing guessed at.

Total solve time across all five: 420s (7 minutes), against a stated
budget total of 67 minutes. See BUDGET finding below for why this number
is reported but not used as evidence either way.

## Phase 2 open-book review

### BUDGET

No DEFECT. My own times (105s, 75s, 51s, 98s, 91s) are agent-paced and not
meaningful evidence for or against a human 10-15 minute budget, per the
methodology caveat above. Structurally: no exercise required backtracking,
re-reading beyond normal instruction parsing, or produced a wrong first
attempt, so I have no signal of a breach either. Ex5 is the most
conceptually dense (four separate TLC runs, plus the vacuity-probe
technique, which is new material relative to the chapter itself) and is
the one I'd want a real human timing on if one becomes available, but I
have no finding to record against it.

### AMBIGUITY

NOTE. `exercises/ch09/EXERCISES.md:106` ("Then do it in the other order.
Fill `TODO 2` first, leave `TODO 1` alone, and run it. That's the run
worth having.") took a careful second read to parse correctly: it is easy
to misread as "fill both, then separately re-run with TODO 1 removed"
rather than "leave TODO 1 unfilled from the start and run once before
adding it." I parsed it correctly and reproduced the intended run, and the
"Expected outcome" section a few lines below restates the same two runs
explicitly, so a learner gets a second chance even on a misread. Not a
DEFECT, but worth a rewrite for clarity, e.g. "leave the fairness modifier
out for this first run."

No other exercise required a guess.

### PREREQUISITE LEAK

No DEFECT. Checked every construct COVERAGE.md's Scope section claims
against the actual ch02-08 cheat sheets rather than trusting the claim:

- `Cardinality`, `FiniteSets`, `\subseteq`, `\union`: confirmed in
  `exercises/ch02/CHEATSHEET.md:60,63-65`.
- `await`, process sets, `self`: confirmed in
  `exercises/ch08/CHEATSHEET.md:23-33`.
- `define` blocks, invariants: chapter 4, not independently re-checked
  beyond COVERAGE.md's claim, since Ex1-Ex5 all use `define` the same way
  earlier chapters' exercises already do.
- `Permutations` / `SYMMETRY` (the Ex3 aside): this one worried me
  initially, because `exercises/ch05/CHEATSHEET.md:27-29`'s "Constructs
  introduced" entry for "symmetry set" describes only the TLC Toolbox GUI
  ("mark a model-value set 'symmetry' in the constant assignment
  dialog"), and the source chapter it summarizes,
  `docs/core/constants.rst:118-142`, never names the `Permutations`
  operator or the `.cfg` `SYMMETRY` keyword either, only the GUI. Neither
  of those is what a learner needs to read `Perms == Permutations(Hauliers)`
  in `LoadingBay.tla` or the aside's `SYMMETRY Perms` line. But
  `exercises/ch05/EXERCISES.md:211-213` (Exercise 4, "Relay") already
  spells out exactly this: "`Perms == Permutations(Runners)` in the module
  is the command line spelling of the toolbox symmetry checkbox. Outside
  the toolbox you have to name the permutation set yourself and point the
  `SYMMETRY` keyword at it." So the CLI syntax is taught by ch05's own
  exercise prose, not by its cheat sheet's "Constructs introduced" bullet,
  and COVERAGE.md's citation is accurate once you look at the right part
  of ch05's set. No leak.

### NEAR-COPY

No DEFECT, one NOTE.

Ex1's avoidance of the chapter's `\E x: [](P(x))` shape is confirmed:
`docs/core/temporal-logic.rst:49` (`Safety == \E s \in Servers: [](s \in
online)`) and line 276 ("You probably won't need to ever write a property
of form `\E x: [](P(x))`.") both check out against `COVERAGE.md:54-62`'s
citation of them. `Footbridge`'s `CondemnedIsForever` uses `[](P => []P)`
instead, a genuinely different formal shape, and gets the same lesson
(safety-but-not-invariant) without the quantified-box form.

NOTE: `starters/Beacon.tla`'s `LitAgainAndAgain` / `SettlesLit` pair
(`[]<>(lamp = "lit")` holds, `<>[](lamp = "lit")` fails) is the same shape
as the chapter's own hour-clock illustration at
`docs/core/temporal-logic.rst:232` (`[]<>(time = midnight)` is true,
`<>[](time = midnight)` is false), just with `lamp`/`keeper` standing in
for `time`/clock. `reports/authoring.md:10-25` documents deliberately
avoiding the orchestrator, lock-threads, counter-threads, and task-pool
worked examples, and does list the hour clock among the "five worked
examples," but doesn't separately address this parallel. I don't think it
clears the bar for a DEFECT: the hour clock is a one-sentence aside inside
a `.. tip::` block with no shown code, unlike the four `.. spec::`-anchored
worked examples the chapter actually walks through, and the periodic/
oscillating shape may simply be what any `[]<>` vs `<>[]` illustration
has to look like, since that's the operator pair's own defining
distinction. Flagging for the author's judgment rather than calling it a
finding I'm confident in.

### COVERAGE

Confirmed. `COVERAGE.md`'s theme table, construct table, and scope claims
all check out against the cheat sheets (see PREREQUISITE LEAK above) and
against my own Phase 1 solutions, which independently used every
construct the table claims. Theme 6's two omitted parts (liveness is
slower, longer traces) are documented with a stated reason
(`COVERAGE.md:46-52`) rather than silently dropped, which is what the
checklist item asks for.

### EVIDENCE

Confirmed, with one completeness NOTE.

Re-ran the mutant pass fresh:

```
python3 exercises/ch09/reports/mutants.py
bash exercises/ch09/reports/run-mutants.sh
```

Seeded 25 mutants, ran 40 (mutant, config) rows. All 40 rows matched
`reports/authoring.md`'s table exactly on verdict and rc, including:

- The 5 fairness-weakening mutants (K1, L1, L2, B1, D3) all flipped their
  primary config to `LIVENESS_VIOLATION` rc=13, as claimed.
- The 6 documented blinding cases (F2, F4, K4, B3, D1, D4) all returned
  `OK` rc=0 on their primary config, as claimed.

NOTE: `reports/authoring.md:135-139`'s summary table gives a single
verdict for mutants D2, D3, D4, D5, but each of those runs two configs
(`Depot.cfg` and `DepotProbe.cfg`), and my reproduction shows
`DepotProbe.cfg` returns `SAFETY_VIOLATION` rc=12 for all four, distinct
from the `Depot.cfg` verdict the table states. D1's row explicitly says
"on both configs," which by contrast makes D2-D5's single, unqualified
verdict read as if it covers both configs too, when it doesn't. Nothing
stated in the table is false, and the cause is unsurprising (every mutant
but D1 keeps the reference's `MaxOpen == 2`, so parts always get booked
and `BookDeskIdle` predictably fails), but the table is incomplete
relative to what the committed runner actually reproduces.

Also independently confirmed the F3 exit code:
`Footbridge` with the `PROPERTY` line moved to `INVARIANT` gives
`SAFETY_EVAL_FAILURE` rc=76, matching `reports/authoring.md:117`, since a
temporal formula can't be evaluated as a plain invariant.

### Symmetry finding

Reproduced directly against the reference files, not just through the
mutant table. Copied `exercises/ch09/references/LoadingBay.tla` and
`.cfg` to scratch, ran the honest `fair+` spec, then ran it again with a
second config carrying an appended `SYMMETRY Perms` line.

- Honest run: `OK` rc=0. Log: `5 states generated, 3 distinct states
  found`.
- Symmetric run: `LIVENESS_VIOLATION` rc=13. Log: `4 states generated, 2
  distinct states found`.
- Counterexample trace in the symmetric run's log shows `Wait(h1)`,
  `Go(h1)`, `Wait(h1)` repeating, with `h2` never appearing, confirming
  "one haulier loops for ever and the other never docks."

All three numbers (`3` vs `2` distinct states, the verdict flip, the
starved-haulier trace shape) match `reports/authoring.md:189-197` exactly.
This is the load-bearing finding the harness bead references, and it
reproduces clean.

### Spot-runs through harness/verdict.sh

Four direct runs against `exercises/ch09/references/`, independent of the
mutant runner, including one `LIVENESS_VIOLATION` fail run as required:

| Module | Config | Verdict | rc |
|---|---|---|---|
| `Footbridge` | `Footbridge.cfg` | `OK` | 0 |
| `Kiln` | `Kiln.cfg` | `OK` | 0 |
| `Beacon` | `BeaconSettles.cfg` | `LIVENESS_VIOLATION` | 13 |
| `Depot` | `DepotProbe.cfg` | `SAFETY_VIOLATION` | 12 |

All four match `reports/authoring.md`'s "Reference pass runs" table.

### Delivery check

Not independently re-run beyond my own Phase 1 delivery, which used the
same command (`bash scripts/deliver-exercises.sh 9 <mktemp-dir>`) and
landed the same 12 `starters/` files, `EXERCISES.md`, and `cheatsheets/`
ch02-08 that `reports/delivery-check.md:9-16` describes, with no
`references/`, `COVERAGE.md`, `reports/`, or ch09 cheat sheet present.
Confirms the delivery seam holds from a second, independent delivery.

## Findings summary

| # | Severity | Item | Location |
|---|---|---|---|
| 1 | NOTE | `pcal` auto-creates a stray `Beacon.cfg` + `.old` backup in `starters/` when translating Ex4's module, since it uses three non-default `.cfg` names | observed during Phase 1, `starters/Beacon.tla` |
| 2 | NOTE | Ex2's "fill TODO 2 first, leave TODO 1 alone" ordering is densely worded, though unambiguous once parsed and reinforced later in the same exercise | `exercises/ch09/EXERCISES.md:106` |
| 3 | NOTE | Beacon's `[]<>`/`<>[]` pair structurally parallels the chapter's hour-clock aside; flagged for author judgment, not confident enough to call a DEFECT | `docs/core/temporal-logic.rst:232`, `exercises/ch09/starters/Beacon.tla`, `reports/authoring.md:10-25` |
| 4 | NOTE | `reports/authoring.md`'s mutant table omits the `DepotProbe.cfg` verdict for D2-D5, which reproducibly differs from the stated `Depot.cfg` verdict | `reports/authoring.md:135-139` |

No DEFECT found in any checklist category.

## Verdict

PASS
