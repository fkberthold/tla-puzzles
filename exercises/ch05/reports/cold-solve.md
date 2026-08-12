# Cold-solve review: ch.5 exercise set

Bead `tla-jb7f.17`. Phase 1 solved the set blind, in a scratch directory
outside the repo, using only `EXERCISES.md`, `starters/`, and the ch02-ch04
cheat sheets. Phase 2 reviewed open-book against `references/`,
`reports/authoring.md`, `COVERAGE.md`, the ch05 sheet, and a shallow clone of
`hwayne/learntla-v2` pinned at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`,
verified with `git rev-parse HEAD` after checkout.

Toolchain used throughout: `tlc` reports `TLC2 Version 2026.07.31.184830`.

## Phase 1: solve log

All timestamps are `date +%s` around the active edit-and-run window for each
exercise, taken after the shared front matter (EXERCISES.md, starters,
cheat sheets) had already been read. As an LLM solver, this wall-clock time
covers writing the solution and running the harness. It is not a reliable
stand-in for a human's reading and thinking time, so treat the minutes below
as a lower bound, not a literal budget certification.

| ex | start | end | minutes | outcome | stuck on |
| --- | --- | --- | --- | --- | --- |
| 1 | 1786502362 | 1786502412 | 0.8 | solved, both verdicts matched | none |
| 2 | 1786502427 | 1786502482 | 0.9 | solved, both predictions confirmed | none |
| 3 | 1786502488 | 1786502530 | 0.7 | solved, both verdicts matched | none |
| 4 | 1786502532 | 1786502574 | 0.7 | solved, prediction confirmed | none |
| 5 | 1786502576 | 1786502607 | 0.5 | solved, both verdicts matched | none |

No exercise breached its 10-15 minute budget. No exercise left me stuck.

Exercise 1: copied `starters/Allowance.tla` to scratch, added
`CONSTANT StartingCredit`, replaced the welded `credit = 4` with
`credit = StartingCredit`, ran `pcal`, wrote `Allowance.cfg`
(`StartingCredit = 4`, pass) and `AllowanceOdd.cfg`
(`StartingCredit = 3`, fail). `OK` and `SAFETY_VIOLATION` as stated.

Exercise 2: read `references/ex2-kiln/Kiln.tla` as the exercise's own task
text directs (see AMBIGUITY finding on this below). Predicted
`ASSUMPTION_FAILED` for `KilnBackwards.cfg` before running, confirmed.
Commented out both `ASSUME` lines in a scratch copy, predicted
`SAFETY_VIOLATION` before running, confirmed. One self-inflicted friction
point: my first scratch copy was named `KilnNoAssume.tla` while the module
inside still declared `MODULE Kiln`, which TLC parses as a name mismatch and
reports `PARSE_ERROR`. Renaming the file to `Kiln.tla` fixed it. This is my
own scratch-file error, not a defect in the exercise.

Exercise 3: copied `starters/Locker.tla`, replaced
`FreeIffSentinel == TRUE` with `FreeIffSentinel == claimed = (holder # Unclaimed)`,
using `=` rather than `<=>` since biconditional is not in the ch02-04 cheat
sheets but plain equality between two booleans is. Wrote `Locker.cfg`
(`Unclaimed = Unclaimed`, a bare-word model value, pass) and
`LockerCollide.cfg` (`Unclaimed = 2`, an integer that collides with `Slots`,
fail). `OK` and `SAFETY_VIOLATION` as stated.

Exercise 4: read `references/ex4-relay/Relay.tla` and `Relay.cfg` as the
task directs. Predicted `TLC_EXCEPTION` for `RelayOrdinary.cfg` before
running (reasoning: `SYMMETRY` requires a set of model values, and ordinary
integers carry order and arithmetic that relabeling would not preserve), and
confirmed.

Exercise 5: copied `starters/Rehearsal.tla`, added
`CONSTANT StrictMode` with `ASSUME StrictMode \in BOOLEAN`, and
`Ceiling == IF StrictMode THEN 2 ELSE 5`. Wrote `Rehearsal.cfg`
(`StrictMode = TRUE`, pass) and `RehearsalLoose.cfg`
(`StrictMode = FALSE`, fail). `OK` and `SAFETY_VIOLATION` as stated. Also
ran the exercise's own suggested bonus check, `StrictMode = 7`, and got
`ASSUMPTION_FAILED` as the closing text promises.

## Phase 2: findings

### DEFECT: `How to run` invokes the reference, never the learner's own file

`exercises/ch05/EXERCISES.md:69-74` (exercise 1), `:135-140` (exercise 3),
and `:210-215` (exercise 5) each give a runnable `harness/verdict.sh`
command that hardcodes a path into `exercises/ch05/references/...`. These
are the three write-from-prompt / complete-the-skeleton exercises, where
the task is to copy a starter, edit it, and write your own `.cfg` files.
Followed literally, the shown commands never touch anything the learner
wrote. They re-verify the answer key's own files, which were already known
to produce the stated verdicts before the exercise shipped
(`exercises/ch05/reports/authoring.md:15-28`). A learner who runs exactly
what is printed walks away having confirmed the reference is correct, not
that their own solution is.

This is a real inconsistency, not a stylistic nit. The sibling set,
`exercises/ch03/EXERCISES.md:21-29`, establishes a different and workable
convention for the same exercise-set template: a generic front-matter
instruction, "`harness/verdict.sh` is a path into the `tla-puzzles`
checkout, so run it from there and give it the path to your module,"
paired with bare filenames (no directory) in each exercise's own
`How to run` line. That phrasing tells the learner to substitute their own
path. Chapter 5 has no equivalent generic instruction anywhere in
`EXERCISES.md`, and its per-exercise commands are fully qualified into the
shipped reference tree instead of bare filenames.

I resolved this myself in phase 1 by inference: I copied each starter to my
own scratch directory and pointed the shown commands at my own files
instead of the printed path. Nothing in the document told me to do this.
That is exactly the kind of guessed-at instruction the cold-solve process
exists to catch.

### NOTE: `Expected outcome` is visible before the predict-then-check step

`exercises/ch05/EXERCISES.md:93-95` (exercise 2) and `:171-173` (exercise 4)
state the verdict token directly under the task, immediately above the
`How to run` block, for both predict-then-check exercises. The task text
asks the learner to "write down, in `LOG.md`, what you expect to happen...
before you run it," but the same document already states the pass and fail
tokens a few lines earlier. A learner who reads straight through sees the
answer before writing a prediction. This appears to come from
`exercises/templates/EXERCISES.md:13-15`, which fixes "Expected outcome" as
a mandatory field for every format, not something ch05 introduced on its
own. Flagging it here since it does blunt the predict-then-check format in
this set, but it is a template-level pattern rather than a ch05-specific
authoring choice, and self-discipline (not reading ahead) closes the gap.
NOTE, not DEFECT.

### NOTE: `CONSTANT` declaration syntax has no in-sequence example before exercise 1

`exercises/ch02/CHEATSHEET.md` through `exercises/ch04/CHEATSHEET.md` do not
teach `CONSTANT`. `exercises/ch04/CHEATSHEET.md:46` explicitly places it in
chapter 5. `starters/Allowance.tla`, exercise 1's own starter, has no
`CONSTANT` line to model. The only in-repo example that precedes exercise 1
in file layout is `starters/Locker.tla:17` (`CONSTANT Unclaimed`), which
belongs to exercise 3 and is only informative if the learner happens to
read all three starters before attempting exercise 1. The set's own header
assumes the actual learntla chapter 5 text has already been read
(`EXERCISES.md:3`, "once you have read the chapter"), and that external
chapter is where `CONSTANT` syntax is properly taught. Given that stated
precondition, I judge this a NOTE rather than a DEFECT: the gap is real
inside this repo's four walls, but the exercise set is explicit that it is
not a substitute for the chapter.

### PREREQUISITE LEAK check: `Permutations` (COVERAGE.md's documented exception): sufficient

`exercises/ch05/COVERAGE.md:47-60` names `Permutations` as the one
deliberate out-of-sheet construct and sources it to learntla's
`docs/topics/optimization.rst`. I verified this independently against the
pinned clone: `docs/topics/optimization.rst:129-140` (section "Use symmetry
sets") describes the exact command-line pattern, defining a symmetry
operator with `Permutations` and naming it with `SYMMETRY` in the `.cfg`,
and the worked spec it points at,
`docs/specs/topics/optimization/3/optimization.tla:6`, reads
`Symmetry == Permutations(Workers)`, the same shape as
`references/ex4-relay/Relay.tla:11`'s `Perms == Permutations(Runners)`.
Exercise 4 is predict-then-check, so the learner only has to read and
predict, not produce, and the exercise's own closing text
(`EXERCISES.md:187-189`) explains what `Permutations(Runners)` is doing
before the learner needs it. No defect.

### NEAR-COPY check: independently verified against `docs/core/constants.rst`: no defect found

Read the actual chapter text at the pinned SHA
(`docs/core/constants.rst`) and compared its four worked examples against
all five exercises myself, rather than taking
`reports/authoring.md:130-156`'s claims on faith:

- The chapter's running example is a duplicate-checker spec with
  `CONSTANT S`, `ASSUME Cardinality(S) >= 4`, and operators named
  `IsUnique`/`IsCorrect`/`TypeInvariant` (`constants.rst:14-58`). No
  reference module in this set checks a sequence for duplicates or uses
  any of those names.
- The model-value motivation is a nullable `last_access_time` compared
  against `NULL` or `NotYetAccessed` (`constants.rst:85-87`). Exercise 3
  uses the same construct-level idea (a sentinel for "nothing yet") but a
  different domain (a locker holder) and a different name (`Unclaimed`).
  Same construct, different story: acceptable per the checklist's own
  wording.
- The symmetry-set example uses model values named `s1` through `s5`
  (`constants.rst:113`). Exercise 4 uses `r1`, `r2`, `r3`
  (`Relay.cfg:6`), a different count and different names, and the set
  documents on purpose that it drops the state-count claim
  (4,375 vs 715 states at `constants.rst:116,125`) since this project's
  house rule is verdicts only, never state counts
  (`COVERAGE.md:30-36`).
- The steering-constant example is `DEBUG`, gating a `print_if_debug`
  macro and an `Inputs` set (`constants.rst:152-173`). Exercise 5 uses
  `StrictMode` to pick a numeric ceiling, with no printing and no
  restricted-starting-states pattern. Same theme, different mechanism and
  story.

No exercise reproduces the chapter's names, numbers, or narrative. No
defect.

### COVERAGE check: theme map holds, omission is honest

`COVERAGE.md`'s theme table matches what the five exercises actually do,
confirmed while solving them in phase 1. The documented partial (theme 4,
the state-collapse itself, not exercised) is consistent with a rule I
independently confirmed by reading the whole of `EXERCISES.md`: no exercise
in this set asserts a state count anywhere. The reasoning given
(`COVERAGE.md:32-36`, TLC state counts move with worker settings and
fingerprinting and are not something this project wants to depend on) is
sound and matches how `harness/verdict.sh` is documented to work
(`harness/verdict.sh:9-15`, exit-code-only verdicts). No defect.

### EVIDENCE check: authoring.md's claims independently spot-checked

`reports/authoring.md:15-28` lists all ten primary outcomes. I reproduced
all ten myself in phase 1, all matching. `reports/authoring.md:41-73` lists
25 mutants, one per file edit, all stated to flip the `OK` verdict with none
inert. I independently reproduced two of them against the current reference
files, not against the table's own claims:

- Mutant A2 (delete the `CONSTANT` line from `Allowance.cfg`): re-created
  the edit myself and ran it through `harness/verdict.sh`. Got
  `CONFIG_ERROR` (rc 151), matching the table.
- Mutant R2 (`Perms == Permutations(Runners)` to `Perms == Runners` in
  `Relay.tla`): re-created the edit myself and ran it through
  `harness/verdict.sh`. Got `TLC_EXCEPTION` (rc 255), matching the table.

Combined with the ten primary-outcome reproductions, this is twelve
independent `harness/verdict.sh` runs against this set, six of them fail
runs, satisfying the spot-run requirement several times over. No
fabricated or stale evidence found.

## Verdict

SEND BACK

One DEFECT: the `How to run` blocks for exercises 1, 3, and 5 point at the
shipped reference files instead of the learner's own work, with no
generic instruction anywhere in `EXERCISES.md` telling the learner to
substitute their own path, unlike the working convention already
established in `exercises/ch03/EXERCISES.md:21-29`. Everything else
checked (budget, near-copy, coverage, the one out-of-sheet construct,
authoring evidence) held up under independent verification.
