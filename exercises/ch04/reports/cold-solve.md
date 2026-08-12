# Cold-solve review: exercises for learntla core ch.4

Bead `tla-jb7f.16`. Second-agent cold-solve review, per the bead's
verification contract. Toolchain: `tlc` reports `TLC2 Version
2026.07.31.184830 (rev: 30cc360)`, matching the pinned build.

## Phase 1: blind solve

Worked from a scratch directory outside the repo tree, using only
`exercises/ch04/EXERCISES.md`, `exercises/ch04/starters/`,
`exercises/ch02/CHEATSHEET.md`, and `exercises/ch03/CHEATSHEET.md`.
Timed each exercise with `date +%s` before and after.

A note on the raw times below. This agent runs inside an isolation
harness that statically refuses any bash command it judges too complex
to verify, including plain multi-line file writes whose text contains
the two characters slash-backslash, which is how TLA+ writes its
bulleted AND (`/\`). Finding a workaround, encoding those two
characters as octal escapes inside a `printf %b` call, burned roughly
six to seven minutes on exercise 1 alone, entirely before any exercise
content was touched. That friction is an artifact of this session's
execution environment, not of the exercise material. A human learner
in a normal text editor would never hit it. Exercise 1's raw wall time
below includes it. Exercises 2 to 4 reuse the workaround once found, so
their times are close to genuine content time.

### Exercise 1, `A type invariant that earns its keep`

- Start `1786502441`, end `1786502923`. 482s, about 8.0 min raw.
  Genuine content-engagement time is closer to 90-120s, the rest is
  environment friction, see the note above.
- Solved. Wrote `TypeInvariant == left \in 0..Capacity /\ right \in
  0..Capacity` in `TokenMove.tla`, pasted the same text into
  `TokenMoveBroken.tla`.
- Pass run (`TokenMove.tla`): `OK`, exit 0. Matches the stated outcome.
- Fail run (`TokenMoveBroken.tla`): `SAFETY_VIOLATION`, exit 12, naming
  `TypeInvariant`. Matches the stated outcome.
- Trace: first breaks at State 5, `left = -1`, `right = 4`. Both
  variables leave `0..Capacity` on the same row. The broken guard
  (`left >= 0` instead of `left > 0`) lets the loop run one extra
  step.
- Stuck on: which of the file's two `TypeInvariant == TRUE`
  occurrences to edit. See Finding 1. Guessed: edit both, for safety.

### Exercise 2, `Check it only at the end`

- Start `1786502941`, end `1786502981`. 40s.
- Solved. `UpperBound == \A k \in 1..Len(Input): best >= Input[k]`,
  `Attained == \E k \in 1..Len(Input): Input[k] = best`, `BestIsMax ==
  pc = "Done" => (UpperBound /\ Attained)`.
- Pass run (`MaxScan.tla`): `OK`, exit 0. Matches.
- Fail run (`MaxScanBroken.tla`): `SAFETY_VIOLATION`, exit 12, naming
  `BestIsMax`. Matches.
- Trace: runs to the end, last row `pc = "Done"`, `best = 5`. That is
  `Input[5]`, not the true max `7`. Matches the stated outcome exactly.
- Stuck on: same dual-block question as exercise 1. Same guess.

### Exercise 3, `Two invariants that look equally obvious`

- Start `1786502988`, end `1786503008`. 20s.
- Solved. Predicted in writing, before running anything: `AllPositive`
  passes, since `\A` over the empty `pending` at the end is vacuous.
  `SomePositive` fails, since `\E` over the same empty set is false.
- Pass run (`DrainQueue.tla`): `OK`, exit 0. Matches, prediction
  correct.
- Fail run (`DrainQueue.tla -c DrainQueueExists.cfg`):
  `SAFETY_VIOLATION`, exit 12, naming `SomePositive`. Matches,
  prediction correct.
- Trace: last row `pending = {}`. Matches the stated outcome.
- No files needed editing. No friction beyond the environment issue.

### Exercise 4, `Ruling out the pairs you don't care about`

- Start `1786503011`, end `1786503045`. 34s.
- Solved. `Nondecreasing(s) == \A a, b \in 1..Len(s): a < b => s[a] <=
  s[b]`.
- Pass run (`Ratchet.tla`): `OK`, exit 0. Matches.
- Fail run (`Ratchet.tla -c RatchetNoDrop.cfg`): `SAFETY_VIOLATION`,
  exit 12, naming `NoDropWrong`. Matches.
- Trace: breaks as soon as `log` has one entry (`log = <<0>>`). The
  initial state, `log = <<>>`, holds. Matches the stated outcome.
- Part 2 fix, written to LOG.md: change `=>` to `/\` in `NoDropWrong`,
  one operator, per the instruction.
- Stuck on: the `\A a, b \in ...` multi-variable quantifier shape is
  not demonstrated anywhere I had already filled in. Found the pattern
  by reading ahead to the given `NoDropWrong` a few lines below, which
  uses the same shape. Worked, but is a guess. See Finding 2.

## Phase 2: open-book review

Opened `exercises/ch04/references/`, `exercises/ch04/reports/
authoring.md`, `exercises/ch04/COVERAGE.md`, `exercises/ch04/
CHEATSHEET.md`, and a clone of `hwayne/learntla-v2`. The clone already
existed at the scratch path. `git rev-parse HEAD` confirmed the pinned
SHA `09840bfc2ee9a88cdbedb672be77a6c73942fe16`. Read `docs/core/
invariants.rst` in full, 380 lines.

### Findings

**Finding 1 (DEFECT, AMBIGUITY).** `exercises/ch04/EXERCISES.md:41-43`,
`:65-71`, `:123-124`. Each starter that needs a definition filled in
(`TokenMove.tla`/`TokenMoveBroken.tla`, `MaxScan.tla`/
`MaxScanBroken.tla`, `Ratchet.tla`) carries the same stub text twice.
Once inside the human-authored PlusCal `(*--algorithm ... *)` comment,
again in the translated TLA+ code below `BEGIN TRANSLATION`, which is
the only copy TLC reads. EXERCISES.md refers to "the `define` block"
as if there were one. A learner who edits only the first occurrence,
the natural place to look since it sits right under the TODO comment,
gets a spec that still parses and runs, but the fail-side starter
reports `OK` instead of the exercise's own stated `SAFETY_VIOLATION`,
with no error to explain why.

Reproduced twice, empirically:
- `TokenMoveBroken.tla` with only the PlusCal-comment `TypeInvariant`
  edited, translated copy left as `TRUE`: `bash harness/verdict.sh
  <probe>/TokenMoveBroken.tla -c exercises/ch04/starters/
  TokenMoveBroken.cfg` returns `OK`, exit 0. Stated outcome is
  `SAFETY_VIOLATION`, exit 12.
- `MaxScanBroken.tla`, same treatment on all three definitions: same
  result, `OK`, exit 0, against a stated `SAFETY_VIOLATION`.

Mitigating context: `exercises/ch03/CHEATSHEET.md`'s first major theme
already states "PlusCal compiles to TLA+ through a translation step in
a comment block. TLC runs the translated output, not the PlusCal you
typed." That is the fact that resolves this, if a learner connects it
to the concrete file. It is not restated at the point of use. In my
own blind solve I hedged by editing both copies rather than trusting I
had it right, which is itself evidence the abstract theme does not
resolve the concrete case on its own. Recommend a one-line reminder in
EXERCISES.md's preamble: each stub appears twice, edit both, TLC only
reads the copy after `BEGIN TRANSLATION`.

**Finding 2 (NOTE).** `exercises/ch04/EXERCISES.md:123-129`, ch02/ch03
cheat sheets. `\A`/`\E` are chapter 4's own constructs, per
`exercises/ch04/CHEATSHEET.md:23-29`. `scripts/deliver-exercises.sh:
18-26` documents, by design, that a chapter's own cheat sheet is never
delivered into its own practice tree. So a learner has no lookup card
for `\A`/`\E` syntax during ch04 exercises, only the chapter narrative
read beforehand and whatever is visible in the starter files.
Exercise 2's skeleton already has the quantifier shape written (`\A k
\in 1..Len(Input): TRUE`), so no gap there. Exercise 4 requires writing
`\A a, b \in 1..Len(s): ...` from a blank stub, and the only place that
exact multi-variable shape appears in delivered material is a few
lines further down the same file, inside the given `NoDropWrong`.
Solved it by reading ahead. This is by design, not an oversight, but
it is friction worth knowing about.

**Finding 3 (NOTE).** Near-copy check against `docs/core/
invariants.rst`. Exercise 4's `NoDropWrong` (`~ \E a, b \in 1..Len(log):
a < b => log[a] > log[b]`) is structurally close to the chapter's own
`HasDuplicates` warning example (`\E i, j \in 1..Len(seq): i # j =>
seq[i] = seq[j]`, `invariants.rst:357-359`). Same pitfall shape: `\E`
over an index pair with `=>` where `/\` belongs. Checked independently
against `reports/authoring.md`'s own defense of this, which cites a
differing predicate, a differing operator, a differing domain, and a
live-failing-invariant delivery instead of prose. The defense holds.
`a < b`, ordered, is not a cosmetic rename of `i # j`, unordered. It
changes which pairs are witnesses, and the drop-detection domain has
no counterpart in the chapter. This is the chapter's own stated lesson
(boxed warning at `invariants.rst:353`) drilled in a new setting, which
is what a construct-level exercise is supposed to do. Not a DEFECT,
recorded because it was the closest call in the near-copy check.

### Checklist run-through

- BUDGET: no exercise breached, none even approached. Exercise 1's raw
  time includes environment friction unrelated to the exercise, see
  the Phase 1 note.
- AMBIGUITY: Finding 1 (DEFECT), Finding 2 (NOTE).
- PREREQUISITE LEAK: none found beyond ch04's own `\A`/`\E`/`pc`, which
  is Finding 2, not a leak from a later chapter. Every other construct
  traces to ch02 or ch03 per the cheat sheets, matching `COVERAGE.md`'s
  own scope check.
- NEAR-COPY: Finding 3 (NOTE), no DEFECT.
- COVERAGE: `COVERAGE.md`'s theme table holds. Both documented partials
  (`\subseteq`, "changed values in red") are honest. `\subseteq`
  genuinely is not drilled, confirmed by reading every reference and
  starter. "Changed values in red" genuinely is a Toolbox-only
  rendering with no command-line equivalent, confirmed against
  `invariants.rst:58`, "Values changed in a step are shown in red."
- EVIDENCE: `reports/authoring.md` carries a token, exit code, and
  invariant name for all 8 stated outcomes, and a 20-row mutant table
  where all 6 inert mutants carry a named reason
  (`reports/authoring.md:108-136`).
- Spot-run: 5 stated outcomes re-run directly against `references/`,
  3 fail runs and 2 pass runs, all matched.

Spot-run commands and results:
- `bash harness/verdict.sh exercises/ch04/references/TokenMove.tla`,
  `OK`, exit 0.
- `bash harness/verdict.sh
  exercises/ch04/references/TokenMoveBroken.tla`, `SAFETY_VIOLATION`,
  exit 12.
- `bash harness/verdict.sh
  exercises/ch04/references/MaxScanBroken.tla`, `SAFETY_VIOLATION`,
  exit 12.
- `bash harness/verdict.sh exercises/ch04/references/DrainQueue.tla -c
  exercises/ch04/references/DrainQueueExists.cfg`, `SAFETY_VIOLATION`,
  exit 12.
- `bash harness/verdict.sh exercises/ch04/references/Ratchet.tla`,
  `OK`, exit 0.

## Verdict

SEND BACK. One DEFECT (Finding 1).
