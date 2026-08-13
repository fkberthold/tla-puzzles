# Authoring notes: ch11 exercise set, Action Properties

Bead `tla-jb7f.23`. Written as the set was built, not afterwards.

## Sources

- Coverage source: `exercises/ch11/CHEATSHEET.md`, 3 constructs and 6 major
  themes.
- Chapter text: `docs/core/action-properties.rst` from a shallow clone of
  `hwayne/learntla-v2` at SHA `09840bfc2ee9a88cdbedb672be77a6c73942fe16`, read
  in full, together with the nine `raw-specs/action_props/*.tla` worked
  examples the chapter renders.
- Verdict tokens: `harness/verdict.sh`'s header table, and `V2-PLAN.md` §5.1.

## The chapter's worked examples, and what this set does instead

The chapter has two running specs and reuses neither surface here.

1. `threads.tla`. Two threads, a `lock` that starts at `NULL`, and a `counter`
   incremented through a `tmp` local. Its three action properties are
   `CounterOnlyIncreases == [][counter' >= counter]_counter`,
   `LockCantBeStolen == [][lock # NULL => lock' = NULL]_lock`, and
   `LockNullBeforeAcquired == [][lock' # NULL => lock = NULL]_lock`. Its helper
   action is `BecomesNull(x) == x' = NULL`.
2. `counters.tla`. A `values` function over a `Counters` set, one process per
   counter, each incrementing twice through a macro. Its property is the
   quantified monotonicity one, shown first in the form TLC refuses and then
   commuted.

No exercise here uses a lock, a thread, a `tmp` local, a `NULL` model value, a
variable named `counter` or `values`, or a set named `Counters`. The five
surfaces are a delivery van's odometer, a ladder climb, a thermostat setpoint,
an incubator rack of culture plates, and an airlock.

Exercise 4 is the one that has to stand closest to `counters.tla`, because it
is the set's only coverage of theme 5 and `counters.tla` is the chapter's only
demonstration of it. So the two share a shape they cannot help sharing: a
function-valued variable, one process per index, and a quantified action
property. What they do not share is the property. The chapter asserts
monotonicity, `values[c]' >= values[c]`. Exercise 4 asserts a multiplicative
coupling, `colony[p]' \in {colony[p], 2 * colony[p]}`, which is not an order
relation at all and which a merely-increasing spec breaks. The learner has to
derive that action from a sentence of English, and the only thing the task text
hands over is the refused shape, written with the body elided as
`[][ ... ]_colony[p]`. See the 2026-08-12 repair note at the foot of this file
for why that matters and what it replaced.

The one structural echo I could not design away is exercise 5's helper action.
"Factor primed logic into a named operator and use it in more than one action
property" is theme 4, and any exercise for it has the shape
`Helper(v) == v' = <something>`. I widened it to two arguments,
`Moves(door, to) == door' = to`, and applied it to two different variables with
the same target, which is neither of the things the chapter does with
`BecomesNull`.

## Dialect

c-syntax braces, per central's ruling.

RECORDED CONFLICT, for central to reconcile rather than for me to resolve: the
brief I was dispatched with says "House PlusCal dialect is p-syntax", and
central's later course-correction message says "Dialect ruling stands: c-syntax
braces". I followed the later directive. Two pieces of evidence point the other
way and central should see them:

- `exercises/ch03/CHEATSHEET.md` line 12 records the `--algorithm` block's
  syntax shape as
  `(* --algorithm Name variables x = 0; begin Label: x := 1; end algorithm; *)`,
  which is p-syntax. ch03 is the chapter that teaches PlusCal, so that sheet is
  what a learner has been taught.
- Every shipped wave-1 starter is p-syntax, e.g.
  `exercises/ch06/starters/KnobPanel.tla`.

If the ruling was meant the other way, the fix is mechanical: five modules, one
dialect swap each.

## Measurements

Every row below was run in this worktree against TLC2 Version
2026.07.31.184830. The full re-runs live in `reports/run-refs.sh` and
`reports/run-mutants.sh`.

### Finding 1. A bare `[]` over an action is a PARSE_ERROR, not a false property

The chapter says `[](x' = x + 1)` is "trivially false" because a stutter step
can always be inserted. That is true of the mathematics and false of the
tooling. SANY rejects the module outright with

```
[] followed by action not of form [A]_v.
```

so `verdict.sh` reports `PARSE_ERROR`, rc=150. The check never runs, so nothing
at all is known about whether the property holds. That is the distinction
`verdict.sh`'s header draws between rows 12 and 13 on the one hand and the
evaluation-failure rows on the other, and it is the whole content of exercise 2.

Two further facts, both measured:

- The rejection is at the definition site, not at the use site. A module that
  merely *defines* a bare `[](action)` fails to parse even when the `.cfg` never
  names it.
- Command and result: `.ch11-scratch/Smoke.tla` carried
  `Bare == [](miles' >= miles)` alongside a boxed property, and
  `bash harness/verdict.sh .ch11-scratch/Smoke.tla -c .ch11-scratch/Smoke.cfg`
  printed `PARSE_ERROR`, rc=150, with the log naming line 22, the `Bare`
  definition. Deleting `Bare` and rerunning printed `OK`, rc=0.

### Finding 2. The quantifier is not what TLC refuses. The subscript is.

The chapter's diagnosis of its `counters_2` failure is

> it happens whenever we put our action property inside a quantifier

Measured, that is not the trigger. Three probes, all on exercise 4's own spec.

The probes were first run on the two-tank spec this exercise used before the
2026-08-12 repair, and re-run unchanged on the `Incubator` spec that replaced
it. The table below is the re-run. Both surfaces gave the same four verdicts,
which is worth more than either run alone: the result is about the subscript,
not about the property that happened to sit inside the box.

| form | verdict |
|---|---|
| `\A p \in Plates: [][colony[p]' \in {colony[p], 2 * colony[p]}]_colony` | checked, `OK` on the reference and `LIVENESS_VIOLATION` rc=13 on the fail-run variant |
| `\A p \in Plates: [][colony[p]' \in {colony[p], 2 * colony[p]}]_colony[p]` | `PARSE_ERROR` rc=150 |
| `[][colony["left"]' \in {colony["left"], 2 * colony["left"]}]_colony["left"]`, no quantifier at all | `PARSE_ERROR` rc=150 |

The third row is the one that settles it. There is no quantifier anywhere and
SANY still refuses, so what it refuses is the subscript `colony["left"]`, which
is not a variable name. An outer `\A` over a whole-variable subscript is
accepted and genuinely checked, which the second column's `LIVENESS_VIOLATION`
proves rather than assumes.

The chapter's fix is still the right fix, because commuting the `\A` inside is
what forces the subscript back to the whole variable. Exercise 4 teaches the
fix and states the sharper rule.

### Finding 3. `[][A]_v` violations come out as rc=13, `LIVENESS_VIOLATION`

Confirms the `verdict.sh` header's `[][A]_vars 13` row on this build. Every
seeded transition bug in this set lands there, and exercise 3 is built on the
contrast with rc=12 from an `INVARIANT`.

### Finding 4. `BEGIN TRANSLATION` in a header comment breaks `pcal`

A delivery-seam defect found by the scratch-tree run, not by any reading of the
files.

All three shipped starter modules opened with a comment warning the learner that
the `define` block sits in the file twice, and that comment named the marker
literally as `BEGIN TRANSLATION`. `pcal` then refuses the module:

```
Unrecoverable error:
 -- Beginning of algorithm string --algorithm not found..
```

`pcal` scans for the translation markers before it looks for the algorithm, so a
mention of the marker string above the algorithm sends it looking in the wrong
place. The references were unaffected, because only the starters carry that
warning. So this is a defect that could only ever have shown up on the delivered
artifact, which is the whole reason the delivery step exists.

Fixed by naming it in prose instead, "below the translation marker near the foot
of the file". `EXERCISES.md` still writes the marker out literally, and that is
fine, because a `.md` file never goes through `pcal`.

Second defect from the same run: `pcal` leaves a `NAME.old` backup beside every
module it rewrites, and `scripts/deliver-exercises.sh` copies `starters/`
recursively, so three `.old` files were being delivered to the learner. Removed,
and worth knowing about for any chapter whose starters ship translated.

## Mutant pass

24 hand-seeded single-edit mutants, 4 to 5 per reference, seeded by
`reports/mutants.py` and run by `reports/run-mutants.sh`. 19 flip the reference's
`OK`. 5 are inert and each is accounted for below.

| id | module | edit | verdict | rc |
|---|---|---|---|---|
| O1 | Odometer | `Roll` subtracts instead of adding | `LIVENESS_VIOLATION` | 13 |
| O2 | Odometer | `legs` counts up by 2 | `LIVENESS_VIOLATION` | 13 |
| O3 | Odometer | drop the brackets off `MilesNeverFall` | `PARSE_ERROR` | 150 |
| O4 | Odometer | subscript `LegsCountUpByOne` on `miles` | `LIVENESS_VIOLATION` | 13 |
| O5 | Odometer | `MaxLegs == 0` | `OK` | 0 |
| S1 | StepProbe | drop the brackets off `RungGoesUpByOne` | `PARSE_ERROR` | 150 |
| S2 | StepProbe | subscript on `hand` | `LIVENESS_VIOLATION` | 13 |
| S3 | StepProbe | `Pull` adds 2 | `LIVENESS_VIOLATION` | 13 |
| S4 | StepProbe | weaken `=` to `>=` | `OK` | 0 |
| T1 | Thermostat | `Adjust` jumps straight to `High` | `LIVENESS_VIOLATION` | 13 |
| T2 | Thermostat | narrow `InRange` to `Low..High - 1` | `SAFETY_VIOLATION` | 12 |
| T3 | Thermostat | widen the step set to `{-1, 0, 1}` | `OK` | 0 |
| T4 | Thermostat | start `setpoint` at 59 | `SAFETY_VIOLATION` | 12 |
| T5 | Thermostat | subscript `MovesOneDegree` on `mode` | `LIVENESS_VIOLATION` | 13 |
| I1 | Incubator | the loop adds 1 instead of doubling | `LIVENESS_VIOLATION` | 13 |
| I2 | Incubator | quantifier outside, `]_colony[p]` subscript | `PARSE_ERROR` | 150 |
| I3 | Incubator | plates start at `Limit` | `OK` | 0 |
| I4 | Incubator | drop the hold branch, `= 2 * colony[p]` | `LIVENESS_VIOLATION` | 13 |
| I5 | Incubator | the loop triples instead of doubling | `LIVENESS_VIOLATION` | 13 |
| A1 | Airlock | the outer door goes to `"ajar"` | `LIVENESS_VIOLATION` | 13 |
| A2 | Airlock | `Moves` drops its prime | `LIVENESS_VIOLATION` | 13 |
| A3 | Airlock | outer opens without checking inner | `SAFETY_VIOLATION` | 12 |
| A4 | Airlock | subscript `InnerOnlyShuts` on `outer` | `OK` | 0 |
| A5 | Airlock | inner opens without checking outer | `SAFETY_VIOLATION` | 12 |

Five of these are the fail runs `EXERCISES.md` states: O1, S1, T1, I1, A1. T2
backs the alternative run exercise 3 offers, and S4 backs the closing note in
exercise 2's after-the-run block.

### The five inert mutants

**S4 and T3 weaken the property.** A spec that satisfies `rung' = rung + 1`
satisfies `rung' >= rung` as well, and one that only ever moves the setpoint by
one satisfies a rule allowing it to move by 0 as well. Neither can fail, by
construction. T3 is worth keeping because it is the mistake the chapter warns
about from the other side: `]_setpoint` already tolerates a step that leaves the
setpoint alone, so writing 0 into the set adds nothing.

**O5 and I3 only shrink the reachable state space.** `MaxLegs == 0` means the
loop never runs, and starting the plates at `Limit` means the growth loop is
skipped. Both properties then hold over a smaller behaviour. Neither edit
touches the thing being asserted, which is what makes them a useful control: a
mutant pass where every mutant flips is not measuring the property, it is
measuring whether the spec still runs.

**I4 is the one to read next to A4.** It strengthens exercise 4's property by
deleting the hold branch, so the body reads `colony[p]' = 2 * colony[p]` and
demands that every plate doubles on every step. That flips, rc=13, and the
reason is the whole subtlety of a quantified action property. One plate
doubling is a step, and on that step the other plate does not move, and the
`\A` still has to hold for it. The subscript cannot help there, because
`UNCHANGED colony` is false on a step where some entry did change. So the
per-plate body has to permit holding still, in a way the un-quantified
properties in this set never have to.

**A4 is the interesting one.** It moves `InnerOnlyShuts`'s subscript from `inner`
to `outer`, which is straightforwardly the wrong variable, and the property still
holds. `[P]_outer` is discharged by `UNCHANGED outer` on every step that moves
only the inner door, and on the steps that do move the outer door the invariant
guarantees the inner door is shut, so the implication is vacuously true. The
mutant is inert because the spec's own safety property rescues it. The
symmetrical edit on the other property, O4 and S2 and T5, all flip. Worth
knowing that a wrong subscript is not reliably detectable, and worth not
teaching as if it were.

## Delivery-seam verification

`bash scripts/deliver-exercises.sh 11 .ch11-scratch/practice` delivers
`EXERCISES.md`, `LOG.md`, `starters/` and `cheatsheets/ch02.md` through
`ch10.md`. It does not deliver `references/`, `reports/`, `COVERAGE.md`, or
ch11's own cheat sheet. Verified by `find` over the delivered tree.

Every command printed in `EXERCISES.md` was then run from
`.ch11-scratch/practice/ch11`, verbatim, with the reference answers dropped into
`starters/` for the two write-from-prompt exercises. All ten pass and fail runs
reproduce there. The runs are listed in the return for this bead.

The harness is named by absolute path and the module by a path relative to the
practice directory. That combination is what `verdict.sh` supports: it resolves
a relative `-c` against the caller's cwd and leaves the module argument alone
(`harness/verdict.sh:279`).


## Scope check, ch02 to ch11

Constructs used across the five exercises, each traced to the sheet that
introduces it.

| construct | first taught | used by |
|---|---|---|
| operator definition, `==` | ch02 | all |
| `EXTENDS Integers`, arithmetic | ch02 | 1, 2, 3, 4 |
| strings | ch02 | 2, 3, 4, 5 |
| `=>` implication | ch02 | 5 |
| `~` negation, `/\`, `\/` | ch02 | 3, 5 |
| set literal, `\in`, `a..b` | ch02 | 3, 4 |
| `--algorithm`, labels, `:=`, `while` | ch03 | all |
| `define` block | ch04 | all |
| `\A` | ch04 | 4 |
| function literal `[x \in S \|-> e]`, `f[x]` | ch06 | 4 |
| `either` / `or` | ch07 | 3, 5 |
| process set, `self` | ch08 | 4 |
| `await` | ch08 | 3, 5 |
| `PROPERTY` config directive | ch09 | all |
| action property, `'`, `[P]_x` | ch11 | all |

Nothing from ch12 or later. In particular no exercise uses the multi-variable
`UNCHANGED <<x, y>>` form or a tuple subscript `[A]_<<x, y>>`, both of which the
ch11 sheet's boundary notes place in chapter 12. Every subscript in this set is
a single variable name, which the sheet's own `[P]_x` construct line permits and
which finding 2 shows is required anyway.

## Repair note, 2026-08-12

One repair round, against the single DEFECT in `reports/cold-solve.md`. The
review is left as it was written. This note records what moved under it.

### What the review found

Exercise 4's `LevelsNeverFall` was a rename-only match of the chapter's
`counters_3` worked example. Same `>=`, same quantifier form, same subscript
placement, with `c`/`Counters`/`values` swapped for `t`/`Tanks`/`level`. Worse,
`EXERCISES.md` printed the near-identical predicate itself, as the stated first
attempt. The learner wasn't deriving the action. They were handed it and asked
to move a subscript.

### What changed

The surface. The lesson is untouched.

- Story: an incubator rack of two culture plates, not a tank farm.
- Module: `Incubator`, was `TankFarm`.
- Variable: `colony` over `Plates`, was `level` over `Tanks`.
- Property: `ColoniesDoubleOrHold`, was `LevelsNeverFall`.
- Mutant ids: `I1` to `I5`, were `K1` to `K5`.

The action is now `colony[p]' \in {colony[p], 2 * colony[p]}`. A colony holds
still or doubles, and nothing else is legal in either direction. That's not an
order relation, so it isn't the chapter's claim with new names on it. A spec
that climbs by one breaks it, which no monotonicity property would catch.

The task text no longer prints the body of the refused attempt. It prints
`\A p \in Plates: [][ ... ]_colony[p]` with the body elided, so the shape lesson
still lands and the action has to come out of a sentence of English.

### What the lesson still is

Unchanged, all three parts.

1. TLC refuses a subscript on an indexed variable inside an action property.
2. The fix is commuting the `\A` inside, which puts the subscript on the whole
   variable.
3. Finding 2's sharper rule holds. The subscript is the trigger, not the
   quantifier's position.

Format stays `complete-the-skeleton`, budget stays 12 minutes, and the exercise
keeps its number. The brief for this round described exercise 4 as
predict-then-check with an after-the-run block. It has never been either. I kept
the format it has, because changing it would move exercise 4 out of theme 5's
sole coverage slot and break `COVERAGE.md`'s accounting of which two exercises
are the predict-then-checks. Flagging it rather than adapting to it.

### What was re-run

- Finding 2's three probes, on the new spec. Same four verdicts as the old one.
- All five references through `reports/run-refs.sh`. Five `OK`, rc=0.
- All 24 mutants. Still 19 flip and 5 inert, with the same five ids inert.
- Exercise 4's stated pass and fail runs, through `harness/verdict.sh`.
- A scratch delivery, with every printed exercise-4 command run as printed.

Running the probes twice on two unrelated surfaces is worth more than running
them once. The old result could have been about `>=`. This one can't be, since
the property inside the box changed completely and the verdicts didn't.

### One correction picked up on the way

The scope table's `strings` row read `2, 3, 5`. Exercise 4 has always used
string members, `{"east", "west"}` then and `{"left", "right"}` now, so the row
was understating. Now `2, 3, 4, 5`.

### The new mutant that earns its place

`I4` deletes the hold branch and demands every plate double on every step. It
flips, and the reason is the point of a quantified action property. One plate
doubling is a step where the other plate sits still, the `\A` still has to hold
for that plate, and the subscript can't rescue it because some entry did change.
The old `K4` made a thinner version of the same point by tightening `>=` to `>`.
