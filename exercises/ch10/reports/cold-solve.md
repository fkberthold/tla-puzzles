# Cold-solve review: chapter 10 exercise set

Bead `tla-jb7f.22`. Reviewer ran `bd list -n 1` and got `tla-wza0`, a different
bead, confirming this session shares the beads store but did not touch its
state. `bd` calls in this review are read only.

Toolchain: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`
[`tlc`, exit 1, stderr `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`], the
build the project pins.

## Process note, read this first

Phase 1 is supposed to be a blind solve. It mostly was not, for exercises 4
and 5.

The reviewer opened the full delivered `EXERCISES.md` in one read before
starting any exercise. That file carries the predictions and the answers for
the two predict-then-check exercises (Ex4, Ex5) inside "After the run"
sections gated by a "Run before you read on" line
[`EXERCISES.md:217-239` and `EXERCISES.md:264-285` in the repo copy, same
lines in the delivered copy]. Reading the whole file in one tool call means
the reviewer saw those sections before writing a single prediction.

Exercises 1 through 3 were genuinely blind. Nothing in this review's solve
log for those three should be discounted.

For Ex4 and Ex5, the reviewer did not fabricate blind predictions after the
fact. Instead this report states plainly that the PREDICT half of
predict-then-check could not be evaluated for those two exercises this run,
and focuses on the EVIDENCE half instead: every run, the pristine starter,
the repair, and both second-half mutations, was executed fresh against the
delivered tree and its own output recorded, none of it copied from
`reports/authoring.md`.

This is a reviewer-process finding, not a defect in the exercise set, and
it is written up as a NOTE below under its own heading because it bears on
how much weight the checklist's AMBIGUITY item can carry for Ex4 and Ex5.

## Phase 1: solve log

All work happened in a delivered tree from
`bash scripts/deliver-exercises.sh 10 <mktemp-dir>`
[`bash scripts/deliver-exercises.sh 10 /tmp/.../ch10-delivered.Hf78Xs`, exit
0, produced `ch10/EXERCISES.md`, `ch10/LOG.md`, `ch10/starters/` (5 `.tla` +
5 `.cfg`), `ch10/cheatsheets/` (ch02-ch09, 8 files)]. 20 files, matching the
count `reports/authoring.md` claims for its own delivery probe
[`exercises/ch10/reports/authoring.md:86-88`]. No `references/`, no
`reports/`, no `COVERAGE.md`, no ch10 `CHEATSHEET.md` present in the
delivered tree, confirmed by listing it.

Every run below used the printed command form
`bash ~/repos/tla-puzzles/harness/verdict.sh starters/<Module>.tla`, run
from the delivered `ch10/` directory, character for character as
`EXERCISES.md` prints it.

### Exercise 1, Loading the truck

Minutes: 1.5 (1786582535 to 1786582623 by `date +%s`).
Solved, first try, no re-reads.

Wrote `Loaded` and `Dockside` as a `RECURSIVE` two-argument recursion over
the crate set, peeling the heaviest crate with
`CHOOSE c \in crates : \A d \in crates : d <= c` each round. Ran
`starters/Ex1TruckLoad.tla`: `OK` [`bash ~/repos/tla-puzzles/harness/verdict.sh
starters/Ex1TruckLoad.tla`, stdout `OK`, exit 0].

Fail run reproduced: swapped both `CHOOSE` predicates to `TRUE` per the
exercise text, ran again: `SAFETY_VIOLATION`, exit 12 [same command, exit
12]. Matches the exercise's claimed fail outcome exactly. Reverted and
reconfirmed `OK` before moving on.

Nothing guessed at. The prompt's recursion shape and the truck-loading rule
were unambiguous.

### Exercise 2, The gauge panel

Minutes: 0.9 (1786582631 to 1786582687).
Solved, first try.

`Mapped` as a set map, `Kept` as a set filter, `Chained` as `F(G(x))`.
Three call sites built with `LAMBDA` at the point of use. Ran
`starters/Ex2GaugePanel.tla`: `OK` [exit 0].

Fail run reproduced: swapped `Chained` to `G(F(x))`, ran again:
`SAFETY_VIOLATION`, exit 12. Reverted.

Second experiment reproduced: added `RECURSIVE Mapped(_(_), _)` above the
definition, ran again: `PARSE_ERROR`, exit 150. Removed the line.

Both match the exercise's claims. Nothing guessed at, the stub signatures
were fully specified.

### Exercise 3, The settling tank

Minutes: 0.7 (1786582689 to 1786582730).
Solved, first try.

`x \ominus y == IF x >= y THEN x - y ELSE 0`, `Level[n \in 0..6]` as a
bracket-form recursive function, `Drop[n \in 1..6] == Level[n-1] \ominus
Level[n]`. Ran `starters/Ex3SettlingTank.tla`: `OK` [exit 0].

Fail run reproduced: made `\ominus` plain subtraction, ran again:
`SAFETY_VIOLATION`, exit 12, on hour 6 as the exercise says. Reverted.

Nothing guessed at.

### Exercise 4, The freight lift (predict-then-check, see process note)

Minutes: 0.6 (1786582737 to 1786582771). Not meaningful as blind-solve
evidence, see process note above.

Ran the pristine, unedited starter first: `SPEC_EVAL_FAILURE`, exit 75
[`starters/Ex4LiftBands.tla --log .../ex4.log`, exit 75; log line 27
`Error: Attempted to evaluate a CASE with no conditions true.`]. Matches
`EXERCISES.md`'s claim exactly, including the log text.

Repaired with an `OTHER -> "idle"` arm, ran: `OK`, exit 0.

Reordered the first two arms (`>= 600` before `>= 900`), ran a third time:
`SAFETY_VIOLATION`, exit 12. Matches. Reverted to the repaired, correctly
ordered version.

### Exercise 5, Folding the tape (predict-then-check, see process note)

Minutes: 0.7 (1786582774 to 1786582817). Not meaningful as blind-solve
evidence, see process note above.

Ran the pristine starter first: `PARSE_ERROR`, exit 150
[log line 27: `` Unknown operator: `Folds'. ``]. Matches.

Repaired with `RECURSIVE Folds(_)` above the definition, ran: `OK`, exit 0.

Changed the base case from `len < 3` to `len < 0`, ran a third time:
`SPEC_EVAL_FAILURE`, exit 75 [log line 27: `Error: This was a Java
StackOverflowError.`], total wall time about 4 seconds including TLC
startup. Matches the exercise's "well under a second" claim for TLC's own
evaluation time. Reverted to the repaired base case.

### Time budget caveat

Total solve time across all five exercises was about 4.4 minutes against a
stated 67-minute combined budget (15+15+15+12+10). This is not evidence
that the budgets are loose. The reviewer is a model with full TLA+ fluency
and no typing or reading friction, which is a different population than
the learner the budgets are set for. No exercise showed a structural sign
of taking longer than its budget (no re-reads, no false starts, no dead
ends), which is the most this reviewer's pace can honestly support.

## Phase 2: open-book review

Opened `exercises/ch10/references/`, `exercises/ch10/reports/authoring.md`,
`exercises/ch10/COVERAGE.md`, `exercises/ch10/CHEATSHEET.md`,
`exercises/templates/REVIEW-CHECKLIST.md`, and a shallow clone of
`hwayne/learntla-v2` checked out to `09840bfc2ee9a88cdbedb672be77a6c73942fe16`
[`git checkout 09840bfc2ee9a88cdbedb672be77a6c73942fe16 && git log -1
--format=%H`, output `09840bfc2ee9a88cdbedb672be77a6c73942fe16`, matches the
pinned SHA recorded in `exercises/ch10/CHEATSHEET.md:7`].

### BUDGET

NOTE. See the time budget caveat above. No breach found, but the
reviewer's evidence for this item is weak by construction (see process
note). No DEFECT.

### AMBIGUITY

NOTE, and a light one. For Ex1-3, genuinely blind, nothing had to be
guessed. The starters' stub signatures, the prompts, and the invariants
left one reading each. For Ex4-5, this reviewer's own read-ahead means the
AMBIGUITY item cannot be scored from this run. No DEFECT.

### PREREQUISITE LEAK

Checked `CHOOSE` against the delivered `ch02.md` cheat sheet
[`cheatsheets/ch02.md:87-89`, `CHOOSE x \in S: P(x)`], `\A` against
`ch04.md` [`cheatsheets/ch04.md:23-25`], `DOMAIN` and the bracket function
form against `ch06.md` [`cheatsheets/ch06.md:19-25, 43`], and
`Cardinality`/`FiniteSets` against `ch02.md`
[`cheatsheets/ch02.md:63-65`]. All four are present in the delivered
cheat sheets with matching syntax. This matches
`exercises/ch10/COVERAGE.md:76-90`'s own accounting, independently
confirmed rather than trusted.

`LAMBDA` syntax itself is not re-taught in any delivered cheat sheet
(ch10's own sheet, which does teach it, is withheld by design). It is used
correctly in `advanced-operators.rst:109`
(`SeqMap(LAMBDA x: x + 1, <<1, 2, 3>>)`), which a learner reaching this
exercise set has just read as part of the chapter itself. No DEFECT: this
matches the project's own delivery contract (cheat sheets are refreshers
for prior chapters, not the current one), and the exercise text explains
`LAMBDA`'s role at the call site rather than assuming it.

### NEAR-COPY

Read `docs/core/advanced-operators.rst` in full from the pinned clone, 170
lines, matching the line count `reports/authoring.md:14` claims. Compared
against all five exercises independently rather than trusting
`reports/authoring.md`'s own overlap table.

Ex1's `CHOOSE`-based set recursion is the same construct shape as the
chapter's `SetSum`/`SetToSeq` (`advanced-operators.rst:61-75`), which is
forced by the construct itself, any set recursion looks like this. The
content and the point diverge: the chapter's example is deliberately
order-insensitive (`CHOOSE x \in set: TRUE`), Ex1 is a greedy loading rule
where the selection predicate changes the answer. Not a near-copy.

Ex2's `Mapped`/`Kept`/`Chained` extend past the chapter's single `SeqMap`
example (`advanced-operators.rst:93-110`) to three operators including a
composition (`Chained`) the chapter never shows. Not a near-copy.

Ex3's `\ominus` is a new symbol with new semantics (floored subtraction),
distinct from the chapter's `++`/`--` set operators
(`advanced-operators.rst:131-132`). `Level`/`Drop` are a decay simulation,
distinct from the chapter's `Double`/`Factorial`
(`advanced-operators.rst:141-149`). Not a near-copy.

Ex4's `Band` is a threshold `CASE`, structurally similar to `Fizzbuzz`
(`advanced-operators.rst:162-166`) only in that both are `CASE` examples.
`Band` deliberately overlaps its arms on every load above 900 (`Fizzbuzz`
overlaps on one input in fifteen) and keeps one type throughout (`Fizzbuzz`
returns a bare integer from `OTHER`, mixing types). Not a near-copy.

Ex5's `Folds` is shape-similar to `SumSeq`
(`advanced-operators.rst:40-41`, both a one-line `IF`/recursive-call), but
counts halvings of an integer rather than summing a sequence. Not a
near-copy.

No DEFECT.

### COVERAGE

`exercises/ch10/COVERAGE.md`'s theme table and construct table were checked
against the actual starters and references rather than taken on faith.
Both theme splits it documents hold up: Ex5 really does land `PARSE_ERROR`
on the pristine starter and `SPEC_EVAL_FAILURE` on the runaway base case
(reproduced above, Phase 1), and Ex4 really does carry all three pieces of
the `CASE` theme (`Band(1200)` exercises first-match-wins against three
satisfied arms, the pristine starter exercises the no-`OTHER` error, the
reorder exercises the bug). All 7 constructs on `CHEATSHEET.md` appear in
at least one reference, confirmed by reading each reference file. No
DEFECT.

### EVIDENCE

`reports/authoring.md` carries a verdict row for all 12 stated outcomes
across the five exercises (5 pass runs, 5 fail runs, 2 "extra" experiment
runs for Ex2 and Ex4), matched one for one against every "Expected outcome"
block in `EXERCISES.md`. No stated outcome without a row found.

Re-ran the mutant runner: `bash exercises/ch10/reports/mutants.sh`
[exit 0, final line `Total 25. Caught 23, inert 2, NOEDIT 0.`]. This
reproduces `reports/authoring.md:179`'s claimed `23 caught, 2 inert` and
the full 25-row table exactly, row for row, token for token, rc for rc.

Independently spot-ran 4 stated outcomes directly against the reference
modules, not through the mutant runner:

- `references/Ex1TruckLoad.tla`: `OK`, exit 0. Matches.
- `references/Ex1TruckLoadBroken.tla`: `SAFETY_VIOLATION`, exit 12. Matches
  (fail run).
- `references/Ex4LiftBands.tla`: `OK`, exit 0. Matches.
- `references/Ex5TapeFoldsRunaway.tla`: `SPEC_EVAL_FAILURE`, exit 75.
  Matches (fail run).

No DEFECT.

### The OverLine fixture gap

`reports/authoring.md:190-197` documents that the `OverLine` boundary
mutant (`g >= 40` to `g > 40`) is inert, because `Gauges = {12, 28, 41,
55}` has no gauge at exactly 40, so both thresholds pick the same subset.
Reproduced above under EVIDENCE, same result.

Judgment: the ruling to leave the fixture as is does not fully hold, and
this is worth a NOTE rather than a DEFECT.

The exercise prompt says, in `EXERCISES.md:108`, "`OverLine`: the gauges
reading 40 or more." That is a boundary-inclusive spec in the prompt's own
words. A learner who reads "40 or more" and writes `g > 40` by mistake,
excluding a hypothetical gauge sitting exactly on the line, currently gets
back `OK`. The invariant does not pin the one part of the spec that
explicitly names a boundary, because nothing in the fixture sits on it.
This is a narrow gap. It touches one call site out of six stubs, in an
exercise whose real teaching point is higher-order operators and `LAMBDA`,
not boundary arithmetic, and the gap is disclosed with its own reasoning
rather than hidden.

Recommendation, not a blocker: widen `Gauges` by one value at 40 (for
example `{12, 28, 40, 41, 55}`). `Trimmed`, `OverLine`, and both
`Cardinality` rows in the invariant would need updating to match, which
`reports/authoring.md` already flags as the cost of this change. Given the
narrow blast radius and the honest disclosure already in place, this
review treats it as a NOTE for the next repair round, not grounds for
SEND BACK on its own.

### The spoiler-discipline convention (process finding, not a checklist item)

`EXERCISES.md` gates the Ex4 and Ex5 answers behind a `### After the run`
header and a `Run before you read on.` line
[`EXERCISES.md:217-219`, `EXERCISES.md:264-266`]. This is a convention
enforced by the reader's own discipline, not by any mechanism the file
format provides. This review is itself the evidence: a single whole-file
read defeated it before Phase 1 began.

This is not specific to ch10 and is not something a ch10 repair round can
fix on its own, it is a property of delivering predict-then-check content
inside the same file as its answer key. Recorded here as a NOTE for the
project to weigh at the curriculum level, not as a defect in this
exercise set.

### Delivered-tree check (REVIEW-CHECKLIST item, done in Phase 1, cited here)

`bash scripts/deliver-exercises.sh 10 <mktemp-dir>` [exit 0]. All 7 printed
commands in `EXERCISES.md` were run from the delivered tree exactly as
printed, reproduced above per exercise. No command referenced an
undelivered file. Matches `REVIEW-CHECKLIST.md`'s last item and
`reports/authoring.md:90-113`'s own delivered-tree probe.

## Findings summary

- NOTE: BUDGET, weak evidence by construction, no breach found
  (`EXERCISES.md:70,118,168,206,260`).
- NOTE: AMBIGUITY, unscoreable for Ex4/Ex5 this run due to reviewer
  read-ahead, none found for Ex1-3.
- NOTE: the `OverLine` fixture gap, `reports/authoring.md:190-197` and
  `EXERCISES.md:108`, recommend widening `Gauges` in the next repair
  round.
- NOTE: spoiler-discipline convention is honor-system only,
  `EXERCISES.md:217-219,264-266`, a curriculum-level observation, not a
  ch10 defect.
- No DEFECT found under PREREQUISITE LEAK, NEAR-COPY, COVERAGE, or
  EVIDENCE.

## Verdict

PASS

No DEFECT was found. All four NOTEs are either disclosed-and-narrow
(OverLine), a property of the delivery format rather than this set
(spoiler discipline), or a limitation of this review's own method rather
than a finding about the material (BUDGET, AMBIGUITY for Ex4/Ex5). The
mutant table reproduced exactly, all 12 stated outcomes in `EXERCISES.md`
have matching evidence in `reports/authoring.md`, and 4 independent
spot-runs against the reference modules, including two fail runs, matched
their claims.
