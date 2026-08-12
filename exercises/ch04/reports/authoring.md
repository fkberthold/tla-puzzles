# Authoring report: exercises for learntla core ch.4

Bead `tla-jb7f.16`. Written as the set was built.

Toolchain: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`,
which is the pinned build the exit-code table in `harness/verdict.sh` was
measured on. PlusCal translation is `pcal.trans Version 1.12 of 01 July
2024`, reached through `tlc -pcal`.

Chapter source: `hwayne/learntla-v2` at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, cloned to a scratch directory
outside the worktree. `git rev-parse HEAD` in the clone returned the pinned
SHA, so no explicit fetch of the SHA was needed. Chapter file
`docs/core/invariants.rst`, 380 lines, read in full.

Every verdict below comes from `harness/verdict.sh`, which derives its token
from TLC's process exit status. No console text was read for a verdict.

## Run counts

- 8 runs backing the stated pass and fail outcomes, on `references/`.
- 11 smoke runs on `starters/`, confirming each one parses and runs before
  the learner touches it.
- 20 mutant runs.
- 39 `verdict.sh` invocations in total.

## Stated outcomes, reproduced

All eight run from the repository root against `exercises/ch04/references/`.

| Exercise | Run | Command tail | Token | rc | Invariant named |
|---|---|---|---|---|---|
| 1 | pass | `TokenMove.tla` | `OK` | 0 | none |
| 1 | fail | `TokenMoveBroken.tla` | `SAFETY_VIOLATION` | 12 | `TypeInvariant` |
| 2 | pass | `MaxScan.tla` | `OK` | 0 | none |
| 2 | fail | `MaxScanBroken.tla` | `SAFETY_VIOLATION` | 12 | `BestIsMax` |
| 3 | pass | `DrainQueue.tla` | `OK` | 0 | none |
| 3 | fail | `DrainQueue.tla -c DrainQueueExists.cfg` | `SAFETY_VIOLATION` | 12 | `SomePositive` |
| 4 | pass | `Ratchet.tla` | `OK` | 0 | none |
| 4 | fail | `Ratchet.tla -c RatchetNoDrop.cfg` | `SAFETY_VIOLATION` | 12 | `NoDropWrong` |

Trace shapes on the four failing runs, taken from the `--log` file and
recorded here because the exercise text makes claims about them.

**Exercise 1**: `Error: Invariant TypeInvariant is violated.` The trace ends
on a row with `left = -1` and `right = 4`. `Conserved` holds on every row of
that run, including the last, since `-1 + 4 = 3`. That is why the exercise
can promise which invariant gets named. Both invariants are registered and
only one can fail.

**Exercise 2**: `Error: Invariant BestIsMax is violated.` The last row has
`pc = "Done"` and `best = 5`, which is `Input[5]`. The broken algorithm
assigns unconditionally, so it ends holding the last element rather than the
largest.

**Exercise 3**: `Error: Invariant SomePositive is violated.` The last row has
`pending = {}` and `cleared = {1, 2, 3}`.

**Exercise 4**: `Error: Invariant NoDropWrong is violated.` The last row has
`log = <<0>>`. The initial state, where `log = <<>>`, satisfies
`NoDropWrong`, because the `\E` inside it ranges over an empty set.

I kept every stated outcome to a token, an exit code, an invariant name, and
a variable value on the last row. No state counts, no diameters. Those move
when the search order moves.

## Mutants

Twenty single-edit mutants, five per pass-side reference. Each mutant is a
copy of the reference with one `sed` edit applied, re-run through
`tlc -pcal` so the translation matches the mutated algorithm, then through
`verdict.sh`. The driver refuses a no-op edit, so an inert result can't come
from a `sed` pattern that missed.

Driver: `.scratch/mutate.sh`, a throwaway that dies with the worktree.

| ID | Reference | Edit | Token | rc | Named | Verdict |
|---|---|---|---|---|---|---|
| M1.1 | `TokenMove` | `right + 1` to `right + 2` | `SAFETY_VIOLATION` | 12 | `Conserved` | flip |
| M1.2 | `TokenMove` | `left - 1` to `left + 1` | `SAFETY_VIOLATION` | 12 | `TypeInvariant` | flip |
| M1.3 | `TokenMove` | `right = 0` to `right = 1` | `SAFETY_VIOLATION` | 12 | `Conserved` | flip |
| M1.4 | `TokenMove` | `right \in 0..Capacity` to `1..Capacity` | `SAFETY_VIOLATION` | 12 | `TypeInvariant` | flip |
| M1.5 | `TokenMove` | `Capacity == 3` to `30` | `OK` | 0 | none | inert |
| M2.1 | `MaxScan` | drop the `pc = "Done" =>` guard | `SAFETY_VIOLATION` | 12 | `BestIsMax` | flip |
| M2.2 | `MaxScan` | `pc = "Done"` to `pc = "Scan"` | `SAFETY_VIOLATION` | 12 | `BestIsMax` | flip |
| M2.3 | `MaxScan` | `Input[i] > best` to `<` | `SAFETY_VIOLATION` | 12 | `BestIsMax` | flip |
| M2.4 | `MaxScan` | `Input[k] <= best` to `<` | `SAFETY_VIOLATION` | 12 | `BestIsMax` | flip |
| M2.5 | `MaxScan` | `Attained` body to `TRUE` | `OK` | 0 | none | inert |
| M3.1 | `DrainQueue` | `Jobs == {1, 2, 3}` to `{0, 1, 2}` | `SAFETY_VIOLATION` | 12 | `AllPositive` | flip |
| M3.2 | `DrainQueue` | `j > 0` to `j > 1` | `SAFETY_VIOLATION` | 12 | `AllPositive` | flip |
| M3.3 | `DrainQueue` | `pending = Jobs` to `Jobs \union {-1}` | `SAFETY_VIOLATION` | 12 | `AllPositive` | flip |
| M3.4 | `DrainQueue` | `while pending # {}` to `= {}` | `OK` | 0 | none | inert |
| M3.5 | `DrainQueue` | `\A j \in pending` to `\A j \in cleared` | `OK` | 0 | none | inert |
| M4.1 | `Ratchet` | `level..(level + 2)` to `(level - 1)..` | `SAFETY_VIOLATION` | 12 | `LogIsNondecreasing` | flip |
| M4.2 | `Ratchet` | `s[a] <= s[b]` to `s[a] < s[b]` | `SAFETY_VIOLATION` | 12 | `LogIsNondecreasing` | flip |
| M4.3 | `Ratchet` | `=>` to `\land` in `Nondecreasing` | `SAFETY_VIOLATION` | 12 | `LogIsNondecreasing` | flip |
| M4.4 | `Ratchet` | `Steps == 4` to `Steps == 0` | `OK` | 0 | none | inert |
| M4.5 | `Ratchet` | `Append(log, next)` to `Append(log, 0)` | `OK` | 0 | none | inert |

Fourteen flips, six inert. Per reference: `TokenMove` 4 of 5, `MaxScan` 4 of
5, `DrainQueue` 3 of 5, `Ratchet` 3 of 5.

### The six inert mutants

Each one is inert for a reason worth writing down, and two of them are worth
a follow-up.

**M1.5, `Capacity == 3` to `30`.** The bound and the algorithm both read
`Capacity`, so widening it moves them together. The invariant is stated
relative to `Capacity` and can't see a change to `Capacity` itself.

**M2.5, `Attained` body to `TRUE`.** A weakening. A weaker invariant can't
fail where a stronger one passed, so weakenings are inert by construction.
I ran it to have one in the table.

**M3.4, loop guard inverted so the queue never drains.** `pending` keeps its
initial value and every element stays positive, so `AllPositive` holds.
`AllPositive` is a safety property. It says nothing about the algorithm
making progress, and progress is a later chapter. I'd call this the honest
limit of ch.4's toolkit rather than a hole in the exercise.

**M3.5, quantify over `cleared` instead of `pending`.** Still holds.
`cleared` starts empty, which makes the `\A` vacuous, and it only ever gains
positive ids. This is the same vacuity fact exercise 3 drills, arriving from
the passing side.

**M4.4, `Steps == 0`.** `log` stays empty forever, so `Nondecreasing(log)` is
vacuously true and the exercise checks nothing. This is the one inert result
I find uncomfortable. A badly chosen bound can hollow out a good invariant
and the run still comes back green. `harness/vacuity.sh` exists for exactly
this class, and wiring these references into it is worth a follow-up bead.

**M4.5, `Append(log, next)` to `Append(log, 0)`.** A log of all zeros is
nondecreasing. `LogIsNondecreasing` constrains the shape of `log` and never
claims `log` records `level`, so this mutation sits outside what the
invariant asserts.

## Chapter worked examples, avoided

The chapter's own material, listed so the set can be checked against it. None
of the surface content below is reused.

- The `find_duplicates` PlusCal spec over `seq \in S \X S \X S \X S`, with
  `index`, `seen`, and `is_unique`. This is the chapter's spine and appears
  in five successive versions.
- `TypeInvariant == /\ is_unique \in BOOLEAN /\ seen \subseteq S /\ index
  \in 1..Len(seq)+1`.
- `IsCorrect == IF is_unique THEN IsUnique(seq) ELSE ~IsUnique(seq)`, and its
  collapse to `is_unique = IsUnique(seq)`.
- `IsUnique(s) == Cardinality(seen) = Len(s)`, the cardinality trick the
  chapter calls improper.
- `IsCorrect == IF pc = "Done" THEN ... ELSE TRUE`, and its rewrite as
  `pc = "Done" => is_unique = IsUnique(seq)`.
- `\A x \in {1, 2, 3}: x < 2` and `\E x \in {1, 2, 3}: x < 3`.
- `IsComposite(num) == \E m, n \in 2..num: m * n = num`.
- `Contains(seq, elem) == \E i \in 1..Len(seq): seq[i] = elem`.
- `IsUnique(s) == \A i, j \in 1..Len(s): s[i] # s[j]`, the version the
  chapter marks wrong.
- `IsUnique(s) == \A i, j \in 1..Len(s): i # j => s[i] # s[j]`, the fix, plus
  the two four-row truth tables over `<<"a", "b">>` and `<<"a", "a">>`.
- The `CHOOSE p \in s \X s` scratch probe that finds the `<<1, 1>>` pair.
- `HasDuplicates(seq) == \E i, j: i # j => seq[i] = seq[j]`, the `\E`-with-
  `=>` warning, and its `/\` fix.

The nearest approach is exercise 4 part 2. `NoDropWrong` is an `\E` over
index pairs with `=>` where `/\` belongs, which is the same pitfall shape as
the chapter's `HasDuplicates` warning. The domain differs (a monotone reading
log, not duplicate detection), the predicate differs, the operator differs,
and the exercise runs it as a live failing invariant rather than as prose.
The pitfall is the chapter's lesson and drilling it is the point. Reusing
`HasDuplicates` itself would not have been.

Sortedness deserves a note. The chapter mentions it twice as a direction it
does not take, at line 179 and in the `.. todo:: exercise for sortedness now`
at line 369. It supplies no code for it. Exercise 4's `Nondecreasing` lands
in that space, which I read as filling a gap the author left open rather
than copying anything.

## Two notes on the specs themselves

Both are things I checked rather than assumed, and either would have bitten
quietly.

**A `define` block can reference `pc`.** The translator emits
`VARIABLES pc, ...` ahead of the define statements, so an operator inside the
block resolves `pc` fine. learntla's own `docs/specs/duplicates/inv_4/
duplicates.tla` does the same thing, which is where I looked first.

**Every expression here is type-stable.** TLC aborts evaluation on a
cross-type comparison rather than returning `FALSE`, which would surface as
an eval-failure token instead of the safety violation an exercise promises.
Integers stay integers, sets stay sets of integers, and `log` stays a
sequence of integers on every path including the mutants.

## Files

- `EXERCISES.md`, four exercises across three formats.
- `starters/`, six modules and eight configs. Every one parses and runs.
- `references/`, six modules and eight configs, all translated and checked.
- `COVERAGE.md`, the theme audit.
- `reports/authoring.md`, this file.

No `LOG.md` sits here. `scripts/deliver-exercises.sh` scaffolds one into the
practice tree from `exercises/templates/LOG.md`, per the contract pinned in
`harness/test-deliver-exercises.sh`, so a copy in the source tree would be a
second source of truth for a file the delivery already owns. `EXERCISES.md`
covers the case where somebody works straight out of the repository.

The same contract is why `references/`, `reports/`, and `COVERAGE.md` sit
where they do. All three are on the never-delivered list, which is what keeps
the answers out of the practice tree.
