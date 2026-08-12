# Authoring evidence: chapter 5 exercise set

Bead `tla-jb7f.17`. Written as the set was built, not reconstructed afterwards.

Toolchain: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, the
pinned build. Translations produced by `pcal.trans` Version 1.12 of 01 July
2024. Chapter text read from a shallow clone of `hwayne/learntla-v2` at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, confirmed by `git rev-parse HEAD`.

Every verdict below is a token from `harness/verdict.sh`, which derives it from
TLC's exit status alone. No verdict in this file was read off a console line.

## Stated outcomes, reproduced

Confirmation sweep, all ten stated outcomes in one run:

```
ex1 Allowance pass         Allowance.cfg    OK (rc=0)
ex1 Allowance fail         AllowanceOdd.cfg SAFETY_VIOLATION (rc=12)
ex2 Kiln pass              Kiln.cfg         OK (rc=0)
ex2 Kiln fail              KilnBackwards.cfg ASSUMPTION_FAILED (rc=10)
ex3 Locker pass            Locker.cfg       OK (rc=0)
ex3 Locker fail            LockerCollide.cfg SAFETY_VIOLATION (rc=12)
ex4 Relay pass             Relay.cfg        OK (rc=0)
ex4 Relay fail             RelayOrdinary.cfg TLC_EXCEPTION (rc=255)
ex5 Rehearsal pass         Rehearsal.cfg    OK (rc=0)
ex5 Rehearsal fail         RehearsalLoose.cfg SAFETY_VIOLATION (rc=12)
```

Secondary outcomes named in the learner text, each also reproduced:

| Claim in `EXERCISES.md` | Run | Verdict |
| --- | --- | --- |
| Exercise 2, guards commented out, same backwards `.cfg` | `KilnNoAssume.tla` with `KilnBackwards.cfg` | `SAFETY_VIOLATION` (rc=12), log line `Invariant ClockInWindow is violated by the initial state` |
| Exercise 3, a string sentinel | `Unclaimed = "free"` | `SPEC_EVAL_FAILURE` (rc=75), log line `Attempted to check equality of integer 1 with non-integer: "free"` |
| Exercise 3 starter, constant left unassigned | `starters/Locker.tla` | `CONFIG_ERROR` (rc=151) |
| Exercise 5 starter, ceiling and invariant disagree | `starters/Rehearsal.tla` | `SAFETY_VIOLATION` (rc=12) |
| Exercise 5, a `7` where the boolean goes | mutant H1 | `ASSUMPTION_FAILED` (rc=10) |
| Exercise 1 starter runs as shipped | `starters/Allowance.tla` | `OK` (rc=0) |

## Mutant table

One single edit per mutant, applied on top of the passing configuration. A
`.cfg` edit counts as a mutant. Twenty-five mutants, five per reference. Every
one flipped the `OK` verdict. None inert.

| id | file edited | edit | verdict |
| --- | --- | --- | --- |
| A1 | `Allowance.cfg` | `StartingCredit = 4` to `7` | `SAFETY_VIOLATION` (12) |
| A2 | `Allowance.cfg` | delete the `CONSTANT` line | `CONFIG_ERROR` (151) |
| A3 | `Allowance.tla` | `credit - 2` to `credit - 3` | `SAFETY_VIOLATION` (12) |
| A4 | `Allowance.tla` | `credit >= 0` to `credit >= 1` | `SAFETY_VIOLATION` (12) |
| A5 | `Allowance.cfg` | misspell the invariant name | `CONFIG_ERROR` (151) |
| K1 | `Kiln.cfg` | `Deadline = 4` to `0` | `ASSUMPTION_FAILED` (10) |
| K2 | `Kiln.cfg` | `Deadline = 4` to `99` | `ASSUMPTION_FAILED` (10) |
| K3 | `Kiln.tla` | `Warmup..Deadline` to `Warmup..Deadline-1` | `SAFETY_VIOLATION` (12) |
| K4 | `Kiln.tla` | `clock = Warmup` to `clock = Warmup - 1` | `SAFETY_VIOLATION` (12) |
| K5 | `Kiln.cfg` | delete the `CONSTANT Warmup` line | `CONFIG_ERROR` (151) |
| L1 | `Locker.cfg` | model value to the integer `3` | `SAFETY_VIOLATION` (12) |
| L2 | `Locker.cfg` | model value to the string `"free"` | `SPEC_EVAL_FAILURE` (75) |
| L3 | `Locker.tla` | `holder # Unclaimed` to `holder = Unclaimed` | `SAFETY_VIOLATION` (12) |
| L4 | `Locker.tla` | `claimed' = TRUE` to `FALSE` | `SAFETY_VIOLATION` (12) |
| L5 | `Locker.cfg` | delete the `CONSTANT` line | `CONFIG_ERROR` (151) |
| R1 | `Relay.cfg` | model values to strings | `TLC_EXCEPTION` (255) |
| R2 | `Relay.tla` | `Perms == Permutations(Runners)` to `Perms == Runners` | `TLC_EXCEPTION` (255) |
| R3 | `Relay.cfg` | `SYMMETRY Perms` to `SYMMETRY Perm` | `CONFIG_ERROR` (151) |
| R4 | `Relay.tla` | `touched \subseteq Runners` to `touched = Runners` | `SAFETY_VIOLATION` (12) |
| R5 | `Relay.tla` | `CarrierIsRunner` body to `carrier \notin Runners` | `SAFETY_VIOLATION` (12) |
| H1 | `Rehearsal.cfg` | `StrictMode = TRUE` to `7` | `ASSUMPTION_FAILED` (10) |
| H2 | `Rehearsal.tla` | `THEN 2 ELSE 5` to `THEN 3 ELSE 5` | `SAFETY_VIOLATION` (12) |
| H3 | `Rehearsal.tla` | `level <= 2` to `level <= 1` | `SAFETY_VIOLATION` (12) |
| H4 | `Rehearsal.cfg` | delete the `CONSTANT` line | `CONFIG_ERROR` (151) |
| H5 | `Rehearsal.cfg` | misspell the invariant name | `CONFIG_ERROR` (151) |

The sweep was driven by a hand-written script rather than
`harness/seeded-bugs.sh`, because that script's `--alias` flag makes the
worktree isolation harness refuse the command line.

### Three mutants that came back wrong, and what they found

The first sweep is not the sweep above. Three results contradicted the
prediction, and none of them was adapted to silently.

**A1 and K2, first attempt.** `StartingCredit = -2` and `Warmup = -1` were
predicted to reach the spec and be caught by the invariant and the `ASSUME`.
Both returned `TLC_EXCEPTION` (rc=255) instead. The log says
`tlc2.tool.ConfigFileException: TLC found an error in the configuration file at
line 4`. **A `.cfg` cannot express a negative integer.** The workaround
`Warmup = 0 - 1` was tried and also returns rc=255, so it is not a
negative-literal restriction but a general one: a `.cfg` assigns a value
literal, never an expression.

This contradicts `constants.rst:33`, which says ordinary assignment "lets you
assign any valid TLA+ expression to the constant". That sentence is true of the
toolbox, which generates a module and substitutes into it. It is not true of the
`.cfg` route this project uses. The divergence is now stated in `EXERCISES.md`
rather than left for a learner to trip over.

The finding changed a reference. `Kiln.tla` originally carried
`ASSUME Warmup >= 0`, which no `.cfg` can trip, so it was a guard that could
never fire. It was replaced with `ASSUME Deadline <= 6`, a size budget, which is
reachable. Both mutants were re-aimed at reachable edits and both now kill.

**R5, first attempt.** The sed intended to weaken only the invariant matched
`carrier \in Runners` at the end of a line, and the translated `Init` ends with
the same text. The edit hit two sites and produced `SPEC_EVAL_FAILURE` (75) from
an unenumerable initial predicate rather than the intended `SAFETY_VIOLATION`.
It killed, but it was not the mutant the table claimed. Re-aimed at
`CarrierIsRunner == carrier \in Runners` and it now returns rc=12 as predicted.

## Two behaviors worth recording

**A constant-only invariant is decided before the state search, and reports
`CONFIG_ERROR`.** The first draft of `Locker.tla` checked
`SentinelIsDistinct == Cardinality(Tags) = Cardinality(Slots) + 1`, which
mentions no variable. With a colliding sentinel the run returned rc=151 with
`Error: The invariant of SentinelIsDistinct is equal to FALSE`, not rc=12.

That verdict is accurate but it is bad teaching. `CONFIG_ERROR` sends a learner
hunting for a typo in a `.cfg` that has none. `Locker.tla` was restructured so
the collision is detected through a variable, and the fail run is now a plain
`SAFETY_VIOLATION` with a trace.

**A symmetry set over non-model values is refused, not silently accepted.**
`SYMMETRY Perms` with `Runners = {1, 2, 3}` returns rc=255 with
`java.lang.RuntimeException: Symmetry function must have model values as domain
and range`. This is what makes exercise 4 possible: it is the only part of the
symmetry theme that has a verdict rather than a state count.

## Chapter worked examples avoided

Recorded while reading `docs/core/constants.rst`. Nothing below appears in this
exercise set.

- **The duplicate checker.** The chapter's running example across chapters 3 to
  5. `CONSTANT S`, `ASSUME Cardinality(S) >= 4`,
  `seq \in S \X S \X S \X S`, and the operators `IsUnique`, `IsCorrect`,
  `TypeInvariant`, with variables `seq`, `index`, `seen`, `is_unique`. No
  reference here checks a sequence for duplicates, and no constant is named `S`.
- **`Length`.** Promised at `constants.rst:21` as the second constant. The
  chapter's own `fs_2` spec ships `Size` instead, so the text and the code
  disagree. Neither name is used here, and neither is the idea of a constant
  controlling sequence length, which is chapter 6's material.
- **The nullable timestamp.** `last_access_time` compared against `NULL` or
  `NotYetAccessed`, the chapter's motivation for model values. Exercise 3 uses
  the same idea with a locker holder and a constant named `Unclaimed`.
- **`X`, `Y`, `Set`.** The identifiers in the model value equality snippet at
  `constants.rst:74` and the note at `constants.rst:93`.
- **`s1` through `s5`.** The model value names in the sets-of-model-values and
  symmetry sections. Exercise 4 uses `r1`, `r2`, `r3`.
- **`DEBUG`.** The steering constant at `constants.rst:156`, with
  `macro print_if_debug` and
  `Inputs == IF DEBUG THEN {<<1, 2, 3, 4>>} ELSE S \X S \X S \X S`. Exercise 5
  keeps the theme with a constant named `StrictMode` selecting between two
  numeric ceilings, and prints nothing.

## Name collision discipline

No two reference modules share a constant name, so no `.cfg` written for one can
be pointed at another and quietly bind. `StartingCredit`, `Warmup` with
`Deadline`, `Unclaimed`, `Runners`, `StrictMode`. None of them is a name a
learner would arrive at from the chapter, which rules out `S`, `Length`, `Size`,
`DEBUG` and `NULL`.

Each reference also sits in its own directory, so the module names cannot
collide either.

## Formats

| Exercise | Format | Budget |
| --- | --- | --- |
| 1 Lift a hardcoded number out of the spec | write-from-prompt | 10 min |
| 2 What an `ASSUME` buys you | predict-then-check | 12 min |
| 3 A sentinel that cannot collide | complete-the-skeleton | 15 min |
| 4 Why a symmetry set needs model values | predict-then-check | 10 min |
| 5 A constant that picks a behaviour | write-from-prompt | 12 min |

Both predict-then-check exercises instruct the learner to write the prediction
into `LOG.md` before running TLC.
