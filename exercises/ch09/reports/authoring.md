# Chapter 09 authoring report

Written while the set was built, bead `tla-jb7f.21`. Source chapter is
`docs/core/temporal-logic.rst` at learntla-v2 SHA
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, read in full before anything was
written.

## What the chapter works through, and what this set avoids

The chapter carries five worked examples. This set reuses none of them.

- The orchestrator, with an `online` set of servers, `\E s \in Servers: [](s \in
  online)`, and `~[](...)` as its first liveness property.
- Threads competing for a lock, `await lock = NULL`, `AwaitLock:+`, and the
  weak-against-strong fairness comparison.
- The threads counter, `<>(counter = 2)` passing where `<>[](counter = 2)`
  fails.
- The inbound task pool handed out to workers, as the `~>` example.
- The hour clock, where `[]<>(time = midnight)` holds and `<>[](time =
  midnight)` doesn't.

Ex3 is the closest to the chapter, since a contested resource is what strong
fairness is for and there's no way around that. It's one bay and several
hauliers rather than a lock and several threads, and the property is `\A h:
[]<>(bay = h)` rather than the chapter's `<>`-per-thread shape.

Ex1 deliberately doesn't use the `\E x: [](P(x))` shape. `COVERAGE.md` records
why.

## Delivery seam

Every module a learner runs lives in `starters/`, including the two
predict-then-check modules, which are complete on arrival. `references/` holds
the solved copies and is never named in a printed command.

The command shape is stated once at the top of `EXERCISES.md`. Every how-to-run
line is true as printed from the delivered practice directory: the harness by
absolute repo path, the module by a path relative to the chapter directory.

Three starters ship already translated, which puts a `TODO_` stub in the file
twice for the two fill-in exercises. Both say so in the task text. `Kiln.tla`
and `LoadingBay.tla` carry the stub in the PlusCal comment and again in the
translated section, and TLC reads only the second one.

## A pcal trap worth recording

The first `Kiln.tla` starter wouldn't translate. `pcal` returned

```
Unrecoverable error:
 -- No line containing `END TRANSLATION.
```

The cause was in the header comment, which explained the duplication by naming
the marker `BEGIN TRANSLATION` in prose. `pcal` matches that string anywhere in
the file, found it above the algorithm, and then looked for a closing marker that
wasn't there. Rewording the comment to say "the translated section at the foot of
the file" fixed it. Worth knowing for any starter whose comments talk about the
translation step.

Separately, `pcal` leaves a `.old` backup next to every file it rewrites, and
writes a default `<module>.cfg` into any directory that lacks one. Both were
cleaned out of `starters/` and `references/` before the commit. The mutant runner
reads its config list from a file the seeder writes rather than from a glob, for
the same reason.

## Measurement

Every outcome in `EXERCISES.md` was run through `harness/verdict.sh` on TLC2
Version 2026.07.31.184830 before it was written down. Verdicts are exit-code
tokens, per `V2-PLAN.md` §5.1.

Reference pass runs:

| Module | Config | Verdict | rc |
|---|---|---|---|
| `Footbridge` | `Footbridge.cfg` | `OK` | 0 |
| `Kiln` | `Kiln.cfg` | `OK` | 0 |
| `LoadingBay` | `LoadingBay.cfg` | `OK` | 0 |
| `Beacon` | `BeaconEver.cfg` | `OK` | 0 |
| `Beacon` | `BeaconAgain.cfg` | `OK` | 0 |
| `Beacon` | `BeaconSettles.cfg` | `LIVENESS_VIOLATION` | 13 |
| `Depot` | `Depot.cfg` | `OK` | 0 |
| `Depot` | `DepotProbe.cfg` | `SAFETY_VIOLATION` | 12 |

Shipped-starter runs, which are what Ex4 and Ex5 ask a learner to predict:

| Module | Config | Verdict | rc |
|---|---|---|---|
| `starters/Beacon` | `BeaconEver.cfg` | `OK` | 0 |
| `starters/Beacon` | `BeaconAgain.cfg` | `OK` | 0 |
| `starters/Beacon` | `BeaconSettles.cfg` | `LIVENESS_VIOLATION` | 13 |
| `starters/Depot` | `Depot.cfg` | `OK` | 0 |
| `starters/Depot` | `DepotProbe.cfg` | `OK` | 0 |
| `starters/Kiln` (unfilled) | `Kiln.cfg` | `PARSE_ERROR` | 150 |

One more run backs Ex1's second fail step. The broken `Footbridge`, with the
`PROPERTY` line removed from the config so only `StateOK` is checked, comes back
`OK` at rc 0. That's the theme-2 point measured rather than asserted: a
state-by-state check can't see the violation at all.

## Mutant pass

25 hand-seeded single-edit mutants, 5 per reference, run against 40 config
pairings. `reports/mutants.py` seeds them and `reports/run-mutants.sh` runs them.
Both are committed, so the table below is reproducible:

```
python3 exercises/ch09/reports/mutants.py
bash exercises/ch09/reports/run-mutants.sh
```

| ID | Edit | Verdict | Disposition |
|---|---|---|---|
| F1 | a condemned bridge reopens | `SAFETY_VIOLATION` 12 | flips, and it's Ex1's stated fail edit |
| F2 | inner `[]` dropped, leaving a tautology | `OK` 0 | blinding |
| F3 | the temporal formula moved to `INVARIANT` | `SAFETY_EVAL_FAILURE` 76 | flips |
| F4 | nothing is ever condemned | `OK` 0 | blinding |
| F5 | the open branch made unreachable | `OK` 0 | inert |
| K1 | `fair` deleted | `LIVENESS_VIOLATION` 13 | flips, fairness-weakening |
| K2 | fairness kept, soak counter never advances | `LIVENESS_VIOLATION` 13 | flips |
| K3 | `<>` swapped for `[]` | `SAFETY_VIOLATION` 12 | flips |
| K4 | goal weakened to the type invariant | `OK` 0 | blinding |
| K5 | `MaxSoak` set to 0 | `OK` 0 | inert |
| L1 | `fair+` downgraded to `fair` | `LIVENESS_VIOLATION` 13 | flips, fairness-weakening |
| L2 | all fairness deleted | `LIVENESS_VIOLATION` 13 | flips, fairness-weakening |
| L3 | fairness kept, the bay is never released | `LIVENESS_VIOLATION` 13 | flips |
| L4 | `SYMMETRY Perms` added to the config | `LIVENESS_VIOLATION` 13 | flips, and it's wrong |
| L5 | `\A` weakened to `\E` | `OK` 0 | inert here, blinding elsewhere |
| B1 | `fair` deleted | `LIVENESS_VIOLATION` 13 on all three | flips, fairness-weakening |
| B2 | fairness kept, the lamp never lights | `LIVENESS_VIOLATION` 13 on all three | flips |
| B3 | `SettlesLit` target weakened to the type invariant | `OK` 0 on all three | blinding |
| B4 | fairness kept, the lamp lights once and stays lit | `OK` 0 on all three | flips `SettlesLit` the other way |
| B5 | the beacon starts lit | `OK`, `OK`, `LIVENESS_VIOLATION` 13 | inert |
| D1 | `MaxOpen` set to 0 | `OK` 0 on both configs | blinding, and it's what the starter ships |
| D2 | fairness kept, nothing is ever collected | `LIVENESS_VIOLATION` 13 | flips |
| D3 | `fair` deleted | `LIVENESS_VIOLATION` 13 | flips, fairness-weakening |
| D4 | `~>` swapped for `=>` | `OK` 0 | blinding |
| D5 | fairness kept, the mend branch never enabled | `LIVENESS_VIOLATION` 13 | flips |

Five mutants are fairness-weakening, one per liveness reference plus a second on
`LoadingBay`: K1, L1, L2, B1, D3. Every one of them flipped the stated pass
verdict to `LIVENESS_VIOLATION`. That's the loud direction, and it's the one this
chapter's material is built to produce, since each of these references states a
property that the spec satisfies only because of the fairness the mutant removed.

Six mutants are blinding rather than flipping, and those are the ones worth
reading. F2, F4, K4, B3, D1 and D4 all return `OK` on a spec that no longer
deserves it. Four different mechanisms:

- **The property is weakened until it can't fail.** F2 drops the inner box and
  leaves `[](P => P)`. K4 asks for `stage \in Stages`, true in the first state.
  B3 asks the lamp to settle on being either lit or dark. D4 turns `~>` into a
  bare `=>`, which with no box around it is checked in the first state only.
- **The antecedent stops firing.** F4 stops anything from being condemned, so
  `[](condemned => [] condemned)` is true about nothing.
- **The whole algorithm stops running.** D1 caps the depot at zero parts, so both
  halves of the leads-to chain are true about nothing.
- **The state space is folded.** L4, below.

No mechanism among those four announces itself. In every case TLC prints `OK` and
exits 0, and the only signal that anything is wrong is the one the author
deliberately went looking for. This is the shape of open bug `tla-hf39` at
learner altitude, and it's why Ex5 ships a hand-built non-vacuity probe as its
subject rather than as an aside.

## Two corrections found by measuring

Both mutants below were written down with an expected verdict, run, and came
back different. Both were wrong in the mutant rather than in the plan, and the
corrected text is in `mutants.py` next to the code.

**K2 was `while (soaks < MaxSoak)` changed to `while (TRUE)`.** Expected 13. Got
`TIMEOUT` rc 124. Making the soak loop unbounded makes `soaks` grow without
bound, the state space is infinite, and TLC never gets far enough to judge the
property. Assigning `soaks := 0` instead keeps the loop infinite and the state
space finite, and that returns 13. Ex2's stated fail run uses the corrected edit.
Anything that says "make this loop for ever" needs checking for whether it also
makes the state space grow.

**L4 inserted `SYMMETRY` in the middle of the `CONSTANTS` block.** Expected
either a refusal or a wrong answer. Got `TLC_EXCEPTION` rc 255, for the boring
reason that the insertion orphaned `NULL = NULL` behind the new keyword and the
config no longer parsed. Appending `SYMMETRY` at the end of the config asks the
question the mutant meant to ask, and the answer is worse than a refusal.

## The symmetry finding

`LoadingBay` with `fair+` passes `EveryoneKeepsDocking` at rc 0. Adding
`SYMMETRY Perms` to its config returns `LIVENESS_VIOLATION` rc 13 on the same
spec, with a counterexample where `h1` loops for ever and `h2` never docks.

TLC prints no warning about pairing a symmetry set with a liveness property. The
run log shows the mechanism plainly: the symmetric run reports 2 distinct states
where the honest run reports 3. The fold merged `bay = h1` with `bay = h2`, and
once those are the same state a behavior where one haulier is starved becomes
indistinguishable from one where nobody is.

The direction here is a false alarm on a correct spec, which is the survivable
direction. I don't think there's anything in the mechanism that guarantees it
always lands that way. The same fold that invents a starvation behavior can hide
one, and nothing in the output would say so. The chapter's line is "you cannot
use symmetry sets with liveness properties". On this build that reads as a
correctness rule with no enforcement behind it.

## Delivery check

`scripts/deliver-exercises.sh 9 <scratch>` was run before the commit, and every
how-to-run line printed in `EXERCISES.md` was executed from the delivered tree.
Results are in `reports/delivery-check.md`.
