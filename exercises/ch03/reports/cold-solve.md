# Cold-solve review: chapter 3 exercise set

Bead `tla-jb7f.15`. Reviewer worked blind first, then reviewed open-book,
per the process the bead describes.

Solver note: phase 1 ran with only `exercises/ch03/EXERCISES.md`,
`exercises/ch03/starters/`, and `exercises/ch02/CHEATSHEET.md` open, plus
whatever PlusCal knowledge the reviewer's model carries from training. That
stands in for "having read chapter 3" since the chapter's own prose is not
delivered as a separate file in this repo. Treat the friction log below with
that in mind. A first-time human learner reading the real chapter 3 text
would arrive with the same taught constructs this review found in
`docs/core/pluscal.rst`, so the phase 1 findings should generalize, but the
reviewer is not a naive learner in every respect.

Scratch work for phase 1 lived at
`/tmp/claude-1000/-home-frank-repos-tla-puzzles/e0d61ae7-b1c8-4155-bdb8-764f303c66c6/scratchpad/ch03-coldsolve`,
outside the repo tree.

## Phase 1: solve log

### Exercise 1, Change dispenser (write-from-prompt, budget 15 min)

Start 1786502216, end 1786502270. About 1 minute.

Solved. Wrote `owed \in 0..12`, a `Record`-style label that saves the
starting amount, a `while` loop with a nested `if`, and a two-parameter
macro `PayCoin(coinValue, counter)` that assigns into whichever counter
variable is passed in. Translated clean on the second attempt.

Friction: the first attempt named the final label `Done`. `pcal` refused
with `Cannot use 'Done' as a label.` Renamed to `Result` and it translated.
See DEFECT-adjacent NOTE 1 below.

Outcome check: pass case reproduced, `OK` rc 0 on my own module. The fail
case in the exercise is defined against `references/Ex1DispenserFail.tla`,
which phase 1 forbids opening, and the exercise itself does not ask the
solver to author a broken variant. Not applicable in phase 1. Verified in
phase 2 instead (see Evidence spot-runs).

No instruction had to be guessed. The task statement fully specifies the
three asserts and where the starting-amount variable is captured.

### Exercise 2, The translation is what runs (predict-then-check, budget 10 min)

Start 1786502277, end 1786502309. About 32 seconds.

Solved. Read the PlusCal in `starters/Ex2Stale.tla`: `setpoint` starts 68,
`Warmer` adds 2, `Cooler` subtracts 1, so 69 at `Check`. Wrote that
prediction to a scratch `LOG.md` before running anything, along with a
predicted `ASSERT_VIOLATION` on the as-shipped translation, reasoning from
the exercise's own title.

Ran `harness/verdict.sh` on the delivered starter untouched: `ASSERT_VIOLATION`
rc 14, matching the stated fail outcome, and confirming the stale
translation's `setpoint + 3` line. Ran `pcal -nocfg` to retranslate, ran
again: `OK` rc 0, matching the stated pass outcome.

No friction, no guess.

### Exercise 3, Retry with goto (write-from-prompt, budget 12 min)

Start 1786502325, end 1786502355. About 30 seconds.

Solved. `attempts` and `linked`, one `Dial` label with a `goto Dial` inside
the `if` branch below 3 attempts, `linked := TRUE` otherwise, then a `Check`
label with the two asserts. Translated and ran clean: `OK` rc 0.

Then broke it on purpose, per the task's own instruction: added a statement
after the `goto` with no label between. `pcal` refused with
`Missing label` at the line holding the orphaned statement, exit 255,
matching the stated fail behavior. Ran the harness against the untranslated
module anyway: `CONFIG_ERROR` rc 151, also matching.

No guess. The task spells out the goto-then-statement trap explicitly, so
this was not a discovery, it was following the instructions.

### Exercise 4, One step, two tanks (complete-the-skeleton, budget 12 min)

Start 1786502360, end 1786502394. About 34 seconds.

Solved. Filled the `Pump` label in `starters/Ex4Tanks.tla` with
`with amount = 3 do tanks[1] := tanks[1] - amount || tanks[2] := tanks[2]
+ amount; end with;`. Translated and ran: `OK` rc 0, matching the stated
pass outcome.

Then wrote the split-label variant myself (`Drain` and `Fill` around
`Audit`), per the task's own second instruction. Ran it: `ASSERT_VIOLATION`
rc 14, matching the stated fail outcome, and matching the reason given
(`Audit` observes a moment with 3 litres in neither tank).

No friction, no guess. The task names both required constructs (`||`,
`with`) directly.

### Exercise 5, Does that label ever run? (predict-then-check, budget 12 min)

Start 1786502400, end 1786502437. About 37 seconds.

Solved. `temp \in 0..30` means `temp > 40` can never hold, so predicted
`Trip` dead and `Settle` always reached, written to scratch `LOG.md` before
running anything. Baseline run of the untouched starter: `OK` rc 0, matching
the exercise's own stated baseline.

Put `assert FALSE;` first in `Trip`, translated, ran: `OK` rc 0, meaning
`Trip` never fires the probe, confirming it is dead. Moved the probe to
`Settle`, translated, ran: `ASSERT_VIOLATION` rc 14, confirming `Settle` is
always reached. Both match the stated pass/fail pair.

No friction, no guess.

## Phase 2: findings

### DEFECT 1: mutant table undercounts its own stated total

`exercises/ch03/reports/authoring.md:82` states "23 mutants" and
`exercises/ch03/reports/authoring.md:111` states "23 caught, 0 inert,
0 skipped." The mutant table at `exercises/ch03/reports/authoring.md:88-109`
lists 22 rows: 5 for Ex1 (`Ex1M1`-`Ex1M5`), 4 for Ex2 (`Ex2M1`-`Ex2M4`), 5
for Ex3 (`Ex3M1`-`Ex3M5`), 4 for Ex4 (`Ex4M1`-`Ex4M4`), 4 for Ex5
(`Ex5M1`-`Ex5M4`). Counted directly from the table, twice.

The same document's run-count arithmetic at line 76 ("46 across two mutant
passes") is consistent with 23 mutants per pass, not 22, which points at a
row dropped from the final table rather than the prose figure being a typo
of an intended smaller number. Every row shown is caught (no `OK`), so the
"0 inert, 0 skipped" claim is not contradicted by what's there, but a reader
cannot verify it covers all 23, because only 22 rows exist to check.

This is exactly the evidence document the bead's acceptance criteria point
to for mutant coverage, so an internal count mismatch in it is a defect in
the deliverable, not a nitpick.

### NOTE 1: `Done` is a reserved PlusCal label name, undocumented anywhere delivered

Hit blind while solving Exercise 1: naming the closing label `Done` makes
`pcal` refuse with `Cannot use 'Done' as a label.` Checked both cheat sheets
(`exercises/ch02/CHEATSHEET.md`, `exercises/ch03/CHEATSHEET.md`) and the
chapter source at the pinned SHA
(`docs/core/pluscal.rst` in the `hwayne/learntla-v2` clone,
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`): none mentions that `Done` (the
value `pc` takes on termination) cannot be used as a label name.

Exercise 1 is the first write-from-prompt exercise in the set and is the
one exercise where a solver picks their own label names, so it is exactly
where a solver is likely to reach for `Done` as a natural name for a
closing label. The only place in the delivered materials that shows
`pc = "Done"` as a special value is the translated block in
`starters/Ex2Stale.tla`, which is Exercise 2's material and comes after
Exercise 1 in the set's own stated order.

Not filed as a DEFECT: the exercise never requires the label be named
`Done`, `pcal`'s error message names the exact problem and the exact line,
and the fix took seconds once seen. It did not touch the time budget in
this solve. Worth a line in `CHEATSHEET.md` or `EXERCISES.md`'s "Before you
start" section for the next author who hits it, since the failure mode
sits one label-name choice away from every write-from-prompt exercise in
the chapter.

### BUDGET: no exercise approached its stated budget

Ex1 about 1 min against 15. Ex2 about 0.5 min against 10. Ex3 about 0.5 min
against 12. Ex4 about 0.6 min against 12. Ex5 about 0.6 min against 12. No
DEFECT, no NOTE. Solver speed here is not comparable to a human learner's,
so this result says nothing about whether a human would fit the budget, only
that nothing in this review surfaced a reason to doubt it.

### AMBIGUITY: none found

Reread every task statement in `EXERCISES.md` against what phase 1 actually
built. Each one specifies its required constructs, its assert set, and its
label structure precisely enough that no interpretation choice was needed
beyond ordinary variable and label naming. No finding.

### PREREQUISITE LEAK: none found beyond NOTE 1

Checked every construct in all five phase 1 solutions against
`exercises/ch02/CHEATSHEET.md` and `exercises/ch03/CHEATSHEET.md`. Every
non-PlusCal construct used (`EXTENDS`, integers, strings, booleans,
sequence literals and indexing) is on the ch02 sheet. Every PlusCal
construct used (`--algorithm`, `:=`, label, `||`, `assert`, `goto`, `if`,
`macro`, `with`, `while`, `\in` on a declaration) is on the ch03 sheet and
is taught in `docs/core/pluscal.rst` at the pinned SHA, including the
macro-parameter-as-variable technique Exercise 1's macro relies on
(the chapter's own `inc(var)` example does the same substitution). The one
gap found is `Done` as a reserved label name, logged as NOTE 1, which is a
`pcal` tooling restriction rather than a taught construct the solve needed.

### NEAR-COPY: none found

Compared all five exercises against `docs/core/pluscal.rst`'s worked
examples in the clone at the pinned SHA: the `pluscal.tla` two-label
warm-up, the three-part duplication checker, the `Sum:` while loop, the
`inc` macro, the `tmp_x`/`tmp_y` swap, the bare `seq[1] := ... || seq[2] :=
...` snippet, the `A: if bool then B: skip else skip end if; x := 1;`
missing-label illustration, and the `x \in 1..1000` collapse illustration.

None of the five exercises reuses any of these in story or surface content.
Ex3 in particular cannot be a near-copy of a `goto` example because the
chapter states the `goto` rule in one line and never shows `goto` in code.
Same constructs recur by necessity (the sheet only has so many), but no
scenario, variable name, or story matches. This matches
`exercises/ch03/reports/authoring.md:161-193`'s own claim, and this review
independently confirms it against the actual chapter source rather than
taking the claim on faith.

### COVERAGE: theme map holds up, omission is honestly documented

`exercises/ch03/COVERAGE.md`'s six-theme table was checked against the
actual references. All six themes map to at least one exercise that
genuinely exercises it: translation-step awareness (Ex2, Ex3 via the
`CONFIG_ERROR` path), label placement and atomicity (Ex4, Ex3), one-update-
per-label and `||` (Ex4, and Ex1 respects the rule without needing `||`),
per-construct labeling rules (Ex1, Ex3, Ex5), `\in` over a whole set (Ex1,
Ex5), and run-stats-as-verdict (Ex5, documented as a partial cover).

The documented partial coverage of theme 6 (state counts) holds up on its
own terms: an exercise graded on a transcribed state count would be grading
one encoding of a model rather than the model, and Ex5's `assert FALSE`
probe gives the same "0 states at this label" finding as a verdict rather
than a number. Reasonable trade, and `COVERAGE.md` says so rather than
hiding it.

The constructs table (`exercises/ch03/COVERAGE.md:50-63`) was checked
against every reference read in phase 2: all 12 sheet constructs appear,
and the per-exercise attribution matches what is actually in each file.

### EVIDENCE

`reports/authoring.md` carries a `harness/verdict.sh` outcome for every
pass and fail case named in `EXERCISES.md`, for both references and
starters, before and after translation where relevant. See DEFECT 1 for the
one internal inconsistency found (mutant table count vs. stated total).

Spot-ran 5 outcomes directly against the committed `references/` tree
myself, independent of phase 1's own scratch solutions, copying each pair
to scratch first so the repo tree stayed clean:

- `references/Ex1Dispenser.tla` + `.cfg`: `OK` rc 0. Matches.
- `references/Ex1DispenserFail.tla` + `.cfg`: `ASSERT_VIOLATION` rc 14. Matches.
- `references/Ex3RetryFail.tla` + `.cfg`: `CONFIG_ERROR` rc 151. Matches.
- `references/Ex4TanksSplit.tla` + `.cfg`: `ASSERT_VIOLATION` rc 14. Matches.
- `references/Ex5LiveLabel.tla` + `.cfg`: `ASSERT_VIOLATION` rc 14. Matches.

One pass and four fail runs, all matching `EXERCISES.md`'s stated outcomes.
`git status --porcelain` after these runs showed only the pre-existing
`.beads/issues.jsonl` re-export, so the spot-runs left no stray artifacts in
the tracked tree.

## Verdict

SEND BACK

One DEFECT: the mutant table in `reports/authoring.md` shows 22 rows against
a stated total of 23, in two places. Everything else checked, including all
five stated pass/fail outcome pairs, the coverage map, the near-copy
comparison against the actual chapter source, and every construct against
the cheat sheets, held up. NOTE 1 is worth a follow-up line in the materials
but does not block on its own.
