# Authoring report: chapter 02 exercise set

Bead `tla-jb7f.14`. Evidence file for `exercises/ch02/EXERCISES.md`, written as
the set was built.

Toolchain: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, which
is the build the pre-flight battery pins. Every verdict below comes from
`harness/verdict.sh`, so it's derived from TLC's exit status and never from its
console text.

Chapter source: `hwayne/learntla-v2` cloned shallow at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, confirmed by `git rev-parse HEAD`
against the pinned SHA. `docs/core/operators.rst` read in full, 532 lines.

## Stated outcomes

Ten runs, one pass and one fail per exercise. All ten reproduced on the pinned
build before the outcome went into `EXERCISES.md`, then re-run in one clean
sweep over the final tree. Every row came back `MATCH` against the token and
the rc the exercise claims.

| Exercise | Module | Token | rc |
|---|---|---|---|
| 1 pass | `references/Ex1Postage.tla` | `OK` | 0 |
| 1 fail | `references/Ex1PostageBroken.tla` | `SAFETY_VIOLATION` | 12 |
| 2 pass | `references/Ex2HoldPickup.tla` | `OK` | 0 |
| 2 fail | `references/Ex2HoldPickupBroken.tla` | `SAFETY_VIOLATION` | 12 |
| 3 pass | `references/Ex3SlotStatus.tla` | `OK` | 0 |
| 3 fail | `starters/Ex3SlotStatus.tla` | `SPEC_EVAL_FAILURE` | 75 |
| 4 pass | `references/Ex4FerryRoute.tla` | `OK` | 0 |
| 4 fail | `references/Ex4FerryRouteBroken.tla` | `SAFETY_VIOLATION` | 12 |
| 5 pass | `references/Ex5LockerBank.tla` | `OK` | 0 |
| 5 fail | `references/Ex5LockerBankBroken.tla` | `SAFETY_VIOLATION` | 12 |

Command shape for every row, run from the repo root:

```bash
bash harness/verdict.sh <path to module.tla>
```

## Starter outcomes

Five starters, all run on the pinned build in the same sweep.

| Starter | Token | rc | Why |
|---|---|---|---|
| `starters/Ex1Postage.tla` | `PARSE_ERROR` | 150 | `Postage` undefined until written |
| `starters/Ex2HoldPickup.tla` | `SAFETY_VIOLATION` | 12 | both stubs return `FALSE` |
| `starters/Ex3SlotStatus.tla` | `SPEC_EVAL_FAILURE` | 75 | ships with the cross-type line in it |
| `starters/Ex4FerryRoute.tla` | `PARSE_ERROR` | 150 | five operators undefined |
| `starters/Ex5LockerBank.tla` | `SAFETY_VIOLATION` | 12 | seven stubs return placeholders |

The split is deliberate. A write-from-prompt starter has an empty answer block
and can't parse, so the first run names the operator you owe it. A
complete-the-skeleton starter parses and fails, so the first run is a red test
you then drive to green.

## What the delivery contract forced

`scripts/deliver-exercises.sh` decides what a learner actually receives, and it
reshaped this set once I read it. For chapter 2 it delivers `EXERCISES.md`,
`LOG.md`, and `starters/` recursively. It never delivers `references/`,
`reports/`, `COVERAGE.md`, or the chapter's own cheat sheet.

Two consequences.

Every `How to run` line names a starter, not a reference. An earlier draft
pointed them at `references/`, which would have been a broken path in every
delivered practice tree.

Exercise 3 has no `Ex3SlotStatusBroken.tla`. It's a predict-then-check, so the
module the learner predicts against has to be delivered, and a broken variant
that sits in `references/` never is. The starter ships broken instead, and the
repair is the second half of the task. That also removes the copy of the same
content in two directories, which would have drifted.

The four remaining broken variants stay in `references/` on purpose. Each one
carries a complete correct answer next to its single seeded error, so
delivering one would hand over the exercise.

Checked by delivering the real chapter into a scratch destination:

```
$ bash scripts/deliver-exercises.sh 2 <scratch>
rc=0
```

Twelve files landed. `EXERCISES.md`, `LOG.md`, and ten starter files. No
`references/`, no `reports/`, no `COVERAGE.md`, no `CHEATSHEET.md`. A delivered
starter run through the harness returned `SAFETY_VIOLATION` rc=12, the same as
the one in the repo.

## Mutant pass

25 mutants, five per reference, each a single-edit copy driven through
`harness/verdict.sh`. The driver lived in `mutant-scratch/mutants.sh` and was
deleted with its output before the commit, since it's verification scratch and
not part of the shipped set.

The driver runs `cmp -s` against the reference before it runs TLC and prints
`NOEDIT` if the edit didn't apply. No row came back `NOEDIT`, so all 25 edits
landed. That check is there because a `sed` pattern that silently misses looks
exactly like a mutant the reference caught by being inert.

| Reference | Mutant | Token | rc |
|---|---|---|---|
| `Ex1Postage` | handling fee 120 to 100 | `SAFETY_VIOLATION` | 12 |
| `Ex1Postage` | first band `<=` to `<` | `SAFETY_VIOLATION` | 12 |
| `Ex1Postage` | second band 500 to 5000 | `SAFETY_VIOLATION` | 12 |
| `Ex1Postage` | mid surcharge 90 to 190 | `SAFETY_VIOLATION` | 12 |
| `Ex1Postage` | heavy surcharge 250 to 90 | `SAFETY_VIOLATION` | 12 |
| `Ex2HoldPickup` | drop the card check | `SAFETY_VIOLATION` | 12 |
| `Ex2HoldPickup` | implication reversed | `SAFETY_VIOLATION` | 12 |
| `Ex2HoldPickup` | delete the `hold_ready` bullet | `SAFETY_VIOLATION` | 12 |
| `Ex2HoldPickup` | turned-away `\/` to `/\` | `SAFETY_VIOLATION` | 12 |
| `Ex2HoldPickup` | `A => B` to `~A \/ B` | `OK` | 0 |
| `Ex3SlotStatus` | a1 stock 4 to 5 | `SAFETY_VIOLATION` | 12 |
| `Ex3SlotStatus` | restock step 6 to 5 | `SAFETY_VIOLATION` | 12 |
| `Ex3SlotStatus` | status branches swapped | `SAFETY_VIOLATION` | 12 |
| `Ex3SlotStatus` | drop `EXTENDS Integers` | `PARSE_ERROR` | 150 |
| `Ex3SlotStatus` | default stock 7 to 8 | `SAFETY_VIOLATION` | 12 |
| `Ex4FerryRoute` | `Head` to index 0 | `SPEC_EVAL_FAILURE` | 75 |
| `Ex4FerryRoute` | last index off by one | `SAFETY_VIOLATION` | 12 |
| `Ex4FerryRoute` | `SubSeq` bound off by one | `SAFETY_VIOLATION` | 12 |
| `Ex4FerryRoute` | `Onward` keeps the shared stop | `SAFETY_VIOLATION` | 12 |
| `Ex4FerryRoute` | `Append` to prepend | `SAFETY_VIOLATION` | 12 |
| `Ex5LockerBank` | filter test `=` to `#` | `SAFETY_VIOLATION` | 12 |
| `Ex5LockerBank` | `TakenRows` maps over `Free` | `SAFETY_VIOLATION` | 12 |
| `Ex5LockerBank` | `\intersect` to `\union` | `SAFETY_VIOLATION` | 12 |
| `Ex5LockerBank` | `ColSets` drops a column | `SAFETY_VIOLATION` | 12 |
| `Ex5LockerBank` | `CHOOSE` predicate to `FALSE` | `SPEC_EVAL_FAILURE` | 75 |

Caught 24, inert 1.

The inert one is `~owes_fines \/ staff_override` in place of
`owes_fines => staff_override`. It's inert by construction and I seeded it on
purpose. That rewrite is the chapter's own answer to its contrapositive
exercise at `operators.rst:137`, so a reference that flagged it would be wrong
about TLA+. It also does a second job, which is why it's here rather than
dropped: it shows the pass can return `OK`, so the other 24 reds aren't the
harness saying no to everything.

Two mutants land on 75 rather than 12, and both are honest. Indexing a sequence
at 0 and a `CHOOSE` over an empty set are errors, not false invariants, so TLC
stops instead of answering.

## Two findings against the harness notes

Both were measured while building this set. Neither is a defect in the
exercises, and I'd rather record them than let the next author rediscover them.

### A constant invariant exits 151, not 12

`harness/verdict.sh`'s header says 151 is "only the SEMANTIC half: the .cfg
parsed but names an operator the spec does not define". I hit a second cause.

The first draft of `Ex1PostageBroken.tla` had an invariant made entirely of
constant conjuncts, with no variable mentioned anywhere in it. The `.cfg` named
`PostageIsRight`, which the spec does define. TLC still exited 151. That draft
is not in the tree, since the fix landed on it before anything was committed.

```
$ bash harness/verdict.sh exercises/ch02/references/Ex1PostageBroken.tla
CONFIG_ERROR
rc=151
```

The log line is `Error: The invariant of PostageIsRight is equal to FALSE`. My
reading is that TLC folds a variable-free invariant at config time and reports
the constant `FALSE` through the config channel, so the run never starts. That
mechanism is INFERRED. The exit code and the log line are measured.

Adding `/\ probe = 0` as the first conjunct moved it to `SAFETY_VIOLATION` and
rc=12 with no other change. Every reference in this set carries that line, and
`EXERCISES.md` explains why in its closing section.

I think the header sentence wants a qualification. As written it says 151 has
one cause, and on this build it has at least two.

### Cross-type equality in an invariant exits 75, not 76

The project's own note says cross-type comparison aborts evaluation rather than
returning `FALSE`, and that held. What I didn't expect was the channel.

```
$ bash harness/verdict.sh exercises/ch02/starters/Ex3SlotStatus.tla
SPEC_EVAL_FAILURE
rc=75
```

The log carries `Error: Attempted to check equality of string "empty" with
non-string:` followed by `Error: The error occurred when TLC was evaluating the
nested`. So the invariant blew up during initial-state computation and came
back through 75, not through 76, which is the row the header describes as "the
invariant blew up mid-evaluation".

This is the same shape as the header's own `AssertViolation` against
`AssertInInit` pair, where the identical assertion exits 14 or 75 depending on
when it fires. I'd call it consistent with the table rather than a
contradiction of it. It's still a trap for anyone writing a one-state operator
drill, because every invariant in that shape is evaluated in the initial state
and so every evaluation failure in one lands on 75.

The exercise now states 75 as its fail outcome, and predicting that token is
part of exercise 3.

## Chapter examples avoided

`operators.rst` works one long example and several short ones. This set reuses
none of the surface content, so a learner can't pattern-match an answer out of
the chapter text.

| Chapter example | Line | This set instead |
|---|---|---|
| `MinutesToSeconds(m) == m * 60` | 21 | postage bands, no unit conversion |
| `SecondsPerMinute == 60` | 36 | `LET handling == 120` |
| `Abs(x) == IF x < 0 THEN -x ELSE x` | 54 | a three-band price, not a sign flip |
| `Xor(A, B) == A = ~B` | 121 | a hold shelf rule |
| Contrapositive exercise `~B => ~A` | 139 | fines imply an override |
| The `A /\ (B \/ C)` bullet block | 146 | a four-argument collection rule |
| `S == <<"a">>` and the module table | 186 | a named ferry route |
| `ToSeconds` and `Earlier` over a clock | 225 | `FirstStop` and `LastStop` |
| `AddTimes` and `ClockType` | 295 | a locker bank of row and column pairs |
| `LoginAttempt == Person \X Time \X BOOLEAN` | 320 | `Slot == Rows \X Cols` |
| `SUBSET ClockType` | 351 | `SUBSET Cols`, small enough to run |
| `Squares == {x*x: x \in 1..4}` | 369 | `TakenRows`, a map over pairs |
| `Evens == {x \in 1..4: x % 2 = 0}` | 372 | `FreeInRow`, a filter over pairs |
| `{t \in ClockType: t[2] >= 30 ...}` | 380 | same |
| `Range(seq)` | 387 | not reused |
| `ToClock` with `CHOOSE` | 414 | `OnlyFreeIn`, a `CHOOSE` over one row |
| `ThreeMax` and `Max` in a `LET` | 466 | `LET handling == 120` |
| `ToClock2` with five `LET` bindings | 489 | one `LET` binding |

The clock runs through nine of those, which is why nothing in this set has an
hour, a minute, or a second in it.

## Run count

74 `harness/verdict.sh` invocations over the session by my count, including the
drafts that got replaced. 40 of them are runs against the tree as it stands: 9
reference modules, 5 starters, 25 mutants, and one delivered starter.

The mutant pass ran twice. The second run followed the `TurnedAwayAtTheDesk`
addition to exercise 2, which changed a reference and so invalidated its first
five results. The table above is the second run.

## Scope

No PlusCal, no `CONSTANT`, no structures, no functions, no recursion. The
boundary check is in `exercises/ch02/COVERAGE.md`.

The one judgement call worth flagging: `seq[n]` and `s[1]` are function
application, and the sheet puts sequence indexing in chapter 2. I've kept to
the sheet, so indexing appears and no reference defines a function or reaches
for `DOMAIN`.
