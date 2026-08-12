# Cold-solve review: chapter 02 exercise set

Bead `tla-jb7f.14`. Second-agent review of `exercises/ch02/EXERCISES.md`. Phase 1
solved blind against `EXERCISES.md` and `starters/` only, in a scratch tree
outside the repo. Phase 2 opened everything and checked the set against
`exercises/templates/REVIEW-CHECKLIST.md`.

Toolchain: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`.
Upstream source: `hwayne/learntla-v2` cloned shallow and checked out at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, confirmed with `git rev-parse HEAD`.

## Phase 1: solve log

All times are `date +%s` before and after, agent wall clock. Every stated pass
and fail outcome reproduced. No instruction needed a guess, except the
Exercise 3 note below.

### Exercise 1, Parcel postage bands

Start 1786502336, end 1786502374, 38 seconds. Budget 10 min.

Ran the unmodified starter first. Got `PARSE_ERROR` as the exercise's own
"first checkpoint" line said it would. Wrote
`Postage(grams) == LET handling == 120 IN IF grams <= 100 THEN handling ELSE
IF grams <= 500 THEN handling + 90 ELSE handling + 250`. Pass run: `OK`. Fail
run (first band `<=` to `<`): `SAFETY_VIOLATION`, matches. No friction.

### Exercise 2, The hold shelf rule

Start 1786502389, end 1786502430, 41 seconds. Budget 12 min.

Ran the unmodified starter first, got `SAFETY_VIOLATION` as promised (both
stubs return `FALSE`). Wrote `CanCollect == /\ card_ok /\ hold_ready /\
(owes_fines => staff_override)` and `TurnedAwayAtTheDesk == ~card_ok \/
~hold_ready`. Pass run: `OK`. Fail run (implication reversed to
`staff_override => owes_fines`): `SAFETY_VIOLATION`, matches. No friction.

### Exercise 3, What type is that answer (predict-then-check)

Start 1786502501, end 1786502535, 34 seconds. Budget 10 min.

Wrote the prediction to my scratch log before running anything, per the
exercise's own instruction. Predicted `Status("a2") = 0` does not evaluate to
`FALSE` (cross-type comparison, string against integer) and that the verdict
token would be `SPEC_EVAL_FAILURE`. Ran the unmodified starter, got
`SPEC_EVAL_FAILURE`, matches. Ran with `--log` and grepped `Error`, got
`Attempted to check equality of string "empty" with non-string`, matches the
reasoning. Repaired `Status("a2") = 0` to `Status("a2") = "empty"`, re-ran,
got `OK`, matches. Removed `EXTENDS Integers`, re-ran, got `PARSE_ERROR`,
matches the exercise's prose about `Restocked` needing `+`. Restored the
line, confirmed `OK` again.

One friction point here, covered as a finding below. I read all of
`EXERCISES.md` top to bottom before starting Exercise 1, since that is how a
single markdown file gets consumed. By the time I reached the prediction
prompt at Exercise 3, I had already read the paragraph a few lines further
down the same section that states the correct answer. I wrote the prediction
down anyway, as instructed, but it was not a blind guess by the time I wrote
it.

### Exercise 4, The ferry route

Start 1786502544, end 1786502570, 26 seconds. Budget 15 min.

Ran the unmodified starter first, got `PARSE_ERROR` as promised. Wrote
`FirstStop(route) == Head(route)`, `LastStop(route) == route[Len(route)]`,
`Between(route) == SubSeq(route, 2, Len(route) - 1)`,
`Extend(route, stop) == Append(route, stop)`,
`Onward(route, spur) == route \o Tail(spur)`. Pass run: `OK`. Fail run
(`Between` start index 1 instead of 2): `SAFETY_VIOLATION`, matches. No
friction.

### Exercise 5, The locker bank

Start 1786502583, end 1786502614, 31 seconds. Budget 15 min.

Ran the unmodified starter first, got `SAFETY_VIOLATION` as promised (all
seven stubs return placeholders). Wrote `Slot == Rows \X Cols`,
`Free == Slot \ Taken`, `FreeInRow(r) == {s \in Free : s[1] = r}`,
`TakenRows == {t[1] : t \in Taken}`, `Clash(wanted) == wanted \intersect
Taken`, `OnlyFreeIn(r) == CHOOSE s \in FreeInRow(r) : TRUE`,
`ColSets == SUBSET Cols`. Pass run: `OK`. Fail run (swapped the set
difference operands in `Free`, to `Taken \ Slot`): `SAFETY_VIOLATION`,
matches. No friction. Worked out before typing that `FreeInRow` and
`TakenRows` want a filter and a map, and `OnlyFreeIn` wants `CHOOSE`, per the
exercise's own hint.

## Phase 2: open-book review

Compared my five blind answers against `references/`. All five match, modulo
a bound variable name (`t[1]` in mine, `s[1]` in the reference, for
`TakenRows`) and a redundant paren around the implication in `CanCollect`.
Both are semantically identical, and both directions verify `OK` through the
harness. This on its own is strong evidence the exercises are solvable from
the delivered material with no unstated construct.

Ran `scripts/deliver-exercises.sh 2 <scratch>` to check what a learner
actually receives. It landed 12 files: `EXERCISES.md`, `LOG.md`, and 10
starter files. No `references/`, no `reports/`, no `COVERAGE.md`, no
`CHEATSHEET.md`. Matches `reports/authoring.md`'s own claim and matches the
files I was scoped to in phase 1.

Spot-ran 5 stated outcomes directly against the shipped files, 2 of them fail
runs:

- `references/Ex1Postage.tla`: `OK`, matches.
- `references/Ex1PostageBroken.tla`: `SAFETY_VIOLATION`, matches.
- `starters/Ex3SlotStatus.tla`: `SPEC_EVAL_FAILURE`, matches.
- `references/Ex5LockerBank.tla`: `OK`, matches.
- `references/Ex5LockerBankBroken.tla`: `SAFETY_VIOLATION`, matches.

Together with the 10 pass and fail runs from phase 1, that's 15 independent
`harness/verdict.sh` runs across both phases, all matching their claimed
token.

## Findings

### DEFECT: predict-then-check spoiler ordering

`exercises/ch02/EXERCISES.md:96-102` tells the learner to predict two things
and write them down "before you run anything", and separately says "A
prediction you write after the run is not a prediction" at line 20. But the
same Exercise 3 section states the answer to prediction 2 outright at line
111 (`Fail run: SPEC_EVAL_FAILURE`), and explains why the intuitive guess is
wrong at lines 119-122 ("Most people predict `SAFETY_VIOLATION` here..."),
both before the reader has run anything and both inside the same continuous
section a learner would read start to end.

I think this only matters for a specific reading pattern, reading the file
linearly rather than stopping exactly at the two prediction questions. But
it's an ordinary pattern for a document this size, and it's the pattern I
used, since the file was delivered to me whole. A learner working through the
set the same way loses the blind prediction before writing it down, which
defeats the point of a predict-then-check exercise.

This doesn't map cleanly onto one of `REVIEW-CHECKLIST.md`'s six bullets. I'm
filing it under the closest one, ambiguity in what the exercise actually asks
of the reader, since the instruction to predict blind assumes a fact about
the document (that the answer isn't visible yet) that the document itself
doesn't hold.

### NOTE: COVERAGE.md's Integers row is imprecise, not dishonest

`exercises/ch02/COVERAGE.md` around line 36 lists `Integers | 1, 3, 5 |
written`. In exercises 3 and 5, the learner's own edits never introduce a new
integer literal or a new arithmetic expression. Exercise 3's edit is a string
literal and a deleted `EXTENDS` line. Exercise 5's answer block never types
an integer at all, `Rows == 1..3` sits in the given section. The IF-THEN-ELSE
row two lines above gets this right ("written in 1, read in 3"), so the
Integers row could use the same per-exercise breakdown.

Not a coverage gap. Exercise 1 does exercise written integer arithmetic, and
the theme is covered. This is a label-precision note against COVERAGE.md's
own stated standard of being honest about "written" versus "read".

### No finding: BUDGET

All five exercises solved in under a minute of agent time, against 10-15
minute budgets. Agent time isn't a stand-in for a human learner's pace, so
this isn't evidence the budgets are loose. It's also not evidence of trouble.
No breach, no approach.

### No finding: AMBIGUITY

No statement needed a guess in phase 1. Every prompt mapped to one
construct, and the ten pass and fail runs all landed where `EXERCISES.md`
said they would.

### No finding: PREREQUISITE LEAK

Checked all five of my answers against `CHEATSHEET.md`'s 21-construct list.
Every construct I reached for is on it. Nested `IF-THEN-ELSE` in Exercise 3
and tuple indexing (`s[1]`) in Exercises 4 and 5 are both direct applications
of constructs the sheet already lists, not new ones.

### No finding: NEAR-COPY

Cross-checked `reports/authoring.md`'s 18-line citation table against
`docs/core/operators.rst` at the pinned SHA. All 18 line numbers match the
upstream text. Independently compared each of the five exercises against the
chapter's worked examples (the clock, `Abs`, `Xor`, the login-attempt
Cartesian product). None of the five reuse the chapter's surface content, the
domains (postage, a library desk, a vending bank, a ferry route, a locker
bank) are all original to this set.

### No finding: EVIDENCE

`reports/authoring.md` carries a `harness/verdict.sh` row for every stated
pass and fail outcome, plus a 25-mutant table (5 per reference) with the one
inert mutant named and explained. I reproduced 5 of those outcomes directly
against the shipped files above, 2 of them fail runs, and reproduced all 10
independently through my own blind solutions in phase 1.

## Verdict

SEND BACK
