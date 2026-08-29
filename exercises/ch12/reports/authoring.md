# Authoring notes: ch12 exercise set, TLA+

Bead `tla-jb7f.27`. Written as the set was built, not afterwards.

## Sources

- Coverage source: `exercises/ch12/CHEATSHEET.md`, 18 constructs and 12 major
  themes plus one `SOURCE GAP:` bullet.
- Cross-sheet review: `exercises/reports/sheet-review-ch12-13.md`, read in full
  before anything was written. Its one defect, the `ProcSet` for `Threads` slip
  at sheet line 109, is already repaired in the sheet I worked from
  [`exercises/ch12/CHEATSHEET.md:109` reads `\E self \in Threads`].
- Verdict tokens: `harness/verdict.sh`'s header table, and `V2-PLAN.md` §5.1.
- Chapter text: not read. No clone of `hwayne/learntla-v2` exists on this
  machine [`find / -name tla.rst -path '*core*'` returned nothing], so the sheet
  and the review are the whole of what this set was built from. Every claim
  below about what the chapter contains is a claim about the sheet.

## No PlusCal, and what that changed

The exercise track's standing dialect ruling is c-syntax PlusCal. It does not
apply here and nothing in this set uses it. Chapter 12 is the chapter that
writes TLA+ directly, so there's no `--algorithm` block anywhere, no
`\* BEGIN TRANSLATION`, and no `pcal` step in any how-to-run line.

Three things follow, and they're all simplifications of what ch11 had to do.

Every how-to-run line is one command instead of two. ch11's preamble spends a
paragraph warning that an edit to the PlusCal copy alone changes nothing,
because TLC reads only the translation. That whole hazard is absent here, and
the preamble says so in one line instead.

`reports/mutants.py` declares an expected occurrence count of 1 for every
mutant. ch11's declared 2 for every property edit, because a `define` block
sits in a translated file twice. Nothing in this chapter's references sits in
the file twice.

`reports/run-mutants.sh` has no `pcal` line, for the same reason.

## The chapter's worked examples, and what this set does instead

Taken from the sheet's syntax-shape fields, the chapter runs on five surfaces.

1. An hour clock. `hr`, `vars == << hr >>`, `Init == hr = 1`, and a `Next` built
   from `IF hr = 12 THEN hr' = 1 ELSE hr' = hr + 1`.
2. Threads and a shared counter. A `Threads` set, `counter`, `IncCounter`,
   `ProcSet == (Threads)`, `Trans(state, from, to)`, and a `lock` that starts at
   `NULL` with `await lock = NULL` guarding it.
3. A sequence `s` of booleans, for `EXCEPT`. `[s EXCEPT ![1] = FALSE]`,
   `[s EXCEPT ![1] = FALSE, ![2] = 17]`, and the nested `![1].x = ~@`.
4. A `status` variable, for fairness on a subaction.
   `Fairness == SF_status(Succeed) /\ WF_status(Retry)`, with
   `Succeed == Trans("start", "done")`.
5. `Next == x' >= x`, the valid-but-uncheckable spec.

No exercise here uses an hour, a clock, a `Threads` set, a thread, a `lock`, a
`NULL` model value, a `tmp` local, a variable named `counter` or `s` or
`status`, a `Succeed` or `Retry` action, an `IF-THEN-ELSE` wraparound, or a
sequence of booleans. The five surfaces are a seed drill, an apiary, a glazing
bench, a drawbridge, and a bottling line.

Two structural echoes I couldn't design away, both recorded rather than hidden.

**Exercise 3 stands close to the chapter's threads spec**, because
label-as-action, `Trans`, `ProcSet` and `Terminating` are four separate sheet
constructs and the chapter demonstrates all four on one spec. So exercise 3
shares a two-label process, a `pc` function over a process set, a `Trans`
helper, and a `Terminating` disjunct. What it doesn't share is what the
processes do. The chapter's threads take a lock, read a shared counter into a
local, and write it back, which is a data race. Exercise 3's glaziers take a
bench and give it back, with no local, no lock variable, and a mutual-exclusion
invariant instead of a lost-update one.

**Exercise 5's `Fairness` operator has the chapter's shape**, `WF` on one action
and `SF` on another, conjoined and named. That shape is the construct. The
chapter marks `SF` on the success branch and `WF` on the retry branch of one
`status` variable. Exercise 5 marks `WF` on the action that supplies work and
`SF` on one branch of the action that consumes it, and the prediction it asks
for is about weak against strong on the same action rather than about which
branch to mark.

## Measurements

Every row below was run in this worktree against TLC2 Version
2026.07.31.184830, the pinned build [battery step 5, `tlc` printed
`TLC2 Version 2026.07.31.184830 (rev: 30cc360)`]. The full re-runs live in
`reports/run-refs.sh` and `reports/run-mutants.sh`.

### References

All five green [`bash exercises/ch12/reports/run-refs.sh`].

| Module | Exercise | Token | rc |
|---|---|---|---|
| `SeedDrill` | 1 | `OK` | 0 |
| `Apiary` | 2 | `OK` | 0 |
| `GlazingBench` | 3 | `OK` | 0 |
| `Drawbridge` | 4 | `OK` | 0 |
| `Capper` | 5 | `OK` | 0 |

`GlazingBench` is run with `-d`, which is the flag exercise 3's own how-to-run
line carries. Without it the run is also `OK`, and `Terminating` becomes
untestable, which is the reason for the flag.

### Starters, as delivered and before any answer is written

| Module | Token | rc | Why |
|---|---|---|---|
| `SeedDrill` | `PARSE_ERROR` | 150 | write-from-prompt, no `.tla` ships |
| `Apiary` | `PARSE_ERROR` | 150 | write-from-prompt, no `.tla` ships |
| `GlazingBench` | `PARSE_ERROR` | 150 | `TODO_1` and `TODO_2` are undefined operators |
| `Drawbridge` | `OK` | 0 | predict-then-check, ships complete |
| `Capper` | `OK` | 0 | predict-then-check, ships complete |

`GlazingBench`'s two holes are bare identifiers, so an unfilled starter can't
silently pass. That's the ch11 wave's double-stub defect class, and the check
for it is the `PARSE_ERROR` row above.

### Seeded mutants

25 mutants, 5 per reference, each one literal substring replacement
[`python3 exercises/ch12/reports/mutants.py` then
`bash exercises/ch12/reports/run-mutants.sh`]. 21 flip the reference's `OK`. 4
are inert and documented below.

| id | module | edit | token | rc |
|---|---|---|---|---|
| D1 | `SeedDrill` | drop `UNCHANGED rows` from `Refill` | `SPEC_EVAL_FAILURE` | 75 |
| D2 | `SeedDrill` | `rows' = rows + 1` becomes `+ 2` | `SAFETY_VIOLATION` | 12 |
| D3 | `SeedDrill` | `Init` starts the hopper one over `Capacity` | `SAFETY_VIOLATION` | 12 |
| D4 | `SeedDrill` | drop `rows` from the `vars` tuple | `OK` | 0 |
| D5 | `SeedDrill` | `Plant` guard becomes `rows < MaxRows + 1` | `SAFETY_VIOLATION` | 12 |
| A1 | `Apiary` | drop the receiving hive's room check | `SAFETY_VIOLATION` | 12 |
| A2 | `Apiary` | `EXCEPT` becomes two primed lookups | `SPEC_EVAL_FAILURE` | 75 |
| A3 | `Apiary` | drop the `![b] = @ + 1` half of the `EXCEPT` | `OK` | 0 |
| A4 | `Apiary` | `AddFrame` adds two frames | `SAFETY_VIOLATION` | 12 |
| A5 | `Apiary` | `Init` starts every hive over the limit | `SAFETY_VIOLATION` | 12 |
| G1 | `GlazingBench` | drop `bench = Free` from `Mount` | `SAFETY_VIOLATION` | 12 |
| G2 | `GlazingBench` | `Cut` keeps the bench instead of freeing it | `SAFETY_VIOLATION` | 12 |
| G3 | `GlazingBench` | `Trans` sets `pc'` to `from` instead of `to` | `SAFETY_VIOLATION` | 12 |
| G4 | `GlazingBench` | drop `UNCHANGED panes` from `Mount` | `SPEC_EVAL_FAILURE` | 75 |
| G5 | `GlazingBench` | drop `Terminating` from `Next` | `DEADLOCK` | 11 |
| W1 | `Drawbridge` | fairness `\A` becomes `\E` | `LIVENESS_VIOLATION` | 13 |
| W2 | `Drawbridge` | drop the fairness conjunct | `LIVENESS_VIOLATION` | 13 |
| W3 | `Drawbridge` | `WF_vars` becomes `WF_turns` | `OK` | 0 |
| W4 | `Drawbridge` | `Raise` guard becomes `< Target + 1` | `LIVENESS_VIOLATION` | 13 |
| W5 | `Drawbridge` | `BridgeRaised` becomes `[]` instead of `<>` | `SAFETY_VIOLATION` | 12 |
| C1 | `Capper` | `SF_vars(Cap)` becomes `WF_vars(Cap)` | `LIVENESS_VIOLATION` | 13 |
| C2 | `Capper` | `SF_vars(Cap)` becomes `SF_vars(Press)` | `LIVENESS_VIOLATION` | 13 |
| C3 | `Capper` | `WF_vars(Arrive)` becomes `WF_capped(Arrive)` | `LIVENESS_VIOLATION` | 13 |
| C4 | `Capper` | drop the `WF_vars(Arrive)` conjunct | `LIVENESS_VIOLATION` | 13 |
| C5 | `Capper` | `Press == Cap \/ Wave` becomes `Press == Cap` | `OK` | 0 |

D1, A1, G1, W1 and C1 are the fail runs `EXERCISES.md` states. A2, G5, W2, C2
and C3 are the extra runs its After-the-run sections state verdicts for. The
remaining fifteen exist to find obligation gaps, and four of them found one.

### The four inert mutants

**D4, dropping a variable from `vars`.** TLC accepts the spec, warns, and
reports `OK`. The warning is

```
The subscript of the next-state relation specified by the specification
does not seem to contain the state variable rows
```

and `verdict.sh` passes `-nowarning`, so under this harness the warning never
reaches the learner [diagnostic run of `.ch12-mut/D4` with `tlc` directly, no
`-nowarning`]. This is the one silent failure mode in the set. It goes in
`EXERCISES.md` under exercise 1's After-the-run, because a learner will hit it
and get no signal at all.

**A3, losing a frame.** `FramesInRange` is a claim about how big each count is.
A frame that leaves one hive and arrives nowhere makes a count smaller, and
smaller counts are still in range. Catching it wants a conservation invariant,
and `Apiary` can't carry one because `AddFrame` creates frames on purpose. This
one is also in `EXERCISES.md`, because "what your invariant doesn't buy" is
worth as much as what it does.

**W3, `WF_turns` for `WF_vars`.** `vars == << turns >>` is a one-element tuple,
so the two subscripts denote the same formula. Inert here and not inert in
general, which is why exercise 5 has a spec with two variables and C3 is not
inert.

**C5, deleting the `Wave` branch.** A press that can only cap does cap, so the
liveness property holds without any help from the fairness operator. The
nondeterminism is what the fairness is for, and removing the nondeterminism
removes the need. That's a fact about the exercise being well-posed rather than
a gap.

### Delivery

Delivered with `bash scripts/deliver-exercises.sh 12 <scratch>` into a scratch
tree, twice, and every how-to-run command run from the delivered chapter
directory exactly as `EXERCISES.md` prints it, including the
`~/repos/tla-puzzles/harness/verdict.sh` path, which resolves to the main
checkout rather than to this worktree.

The delivered tree holds `EXERCISES.md`, `LOG.md`, eight files in `starters/`,
and ten earlier cheat sheets in `cheatsheets/` (`ch02` through `ch11`). It holds
no `references/`, no `reports/`, no `COVERAGE.md`, and not ch12's own cheat
sheet.

Pristine delivery, nothing solved:

| how-to-run, as printed | token | rc |
|---|---|---|
| ex1 `SeedDrill` | `PARSE_ERROR` | 150 |
| ex2 `Apiary` | `PARSE_ERROR` | 150 |
| ex3 `GlazingBench -d` | `PARSE_ERROR` | 150 |
| ex4 `Drawbridge` | `OK` | 0 |
| ex5 `Capper` | `OK` | 0 |

Second delivery, with the three reference answers copied into `starters/`, then
the same five commands:

| how-to-run, as printed | token | rc |
|---|---|---|
| ex1 `SeedDrill` | `OK` | 0 |
| ex2 `Apiary` | `OK` | 0 |
| ex3 `GlazingBench -d` | `OK` | 0 |
| ex4 `Drawbridge` | `OK` | 0 |
| ex5 `Capper` | `OK` | 0 |

Then each exercise's stated fail-run edit applied in the delivered tree, and the
same printed command again:

| edit, in the delivered tree | token | rc |
|---|---|---|
| ex1, drop `UNCHANGED rows` | `SPEC_EVAL_FAILURE` | 75 |
| ex2, drop the room check | `SAFETY_VIOLATION` | 12 |
| ex3, drop the bench guard | `SAFETY_VIOLATION` | 12 |
| ex4, `\A` becomes `\E` | `LIVENESS_VIOLATION` | 13 |
| ex5, `SF_vars(Cap)` becomes `WF_vars(Cap)` | `LIVENESS_VIOLATION` | 13 |

Fifteen commands, all true as printed, none of them naming a path under
`references/`.

## Scope check, chapters 2 to 12 only

Every construct a learner has to type, and the sheet that owns it.

| Construct | Owning sheet | Exercises |
|---|---|---|
| `EXTENDS Integers`, operator definition, arithmetic, `..` interval, `\in`, `#`, `/\`, `\/` | ch02 | all |
| strings as values | ch02 | 2, 3, 5 |
| `=>` | ch02 | 3 |
| `\A`, `\E` | ch04 | 2, 3, 4 |
| function literal `[x \in S \|-> e]`, function application | ch06 | 2, 3, 4 |
| `pc` as a function over a process set | ch04 and ch08 | 3 |
| `await`, as the thing the plain conjunct replaces | ch08 | 3 |
| `<>` | ch09 | 4, 5 |
| `PROPERTY`, `INVARIANT` | ch09 and earlier | shipped in every `.cfg` |
| everything else | ch12 | see `COVERAGE.md` |

Nothing from chapter 13. No `INSTANCE`, no `LOCAL`, no second module.

Two deliberate avoidances.

`<=>` appears on no sheet in the set [`grep -rn '<=>' exercises/ch0*/CHEATSHEET.md exercises/ch1*/CHEATSHEET.md` returned nothing], so exercise 3's mutual-exclusion
claim is two `=>` invariants rather than one `<=>`.

`IF-THEN-ELSE` is chapter 2's and would have been fine, but the chapter's hour
clock is an `IF` wraparound and using one in exercise 1 would have put this set
one rename away from the chapter's own example. No exercise uses it.

## Findings, and one correction to the sheet

**The sheet's quotation of the completeness error is close and not exact.**
Theme 4 says TLC reports "Successor state is not completely specified by the
next-state action". Measured, the message names the offending action and calls
it a relation:

```
Successor state is not completely specified by action Refill of the
next-state relation. The following variable is not defined: rows.
```

Both halves matter to a learner. It names the action, which is where to look,
and it names the variable, which is what's missing. I'd amend the sheet to the
measured text, and that's a job for whoever owns the sheet rather than for this
set. `EXERCISES.md` quotes the measured form.

**The sheet's other quoted error is exact.** Theme 5 says a per-key primed
update gives "the identifier s is either undefined or not an operator".
Measured on `Apiary`, with the variable renamed:

```
In evaluation, the identifier frames is either undefined or not an operator.
```

Same sentence.

**TLC accepts `\E` over a temporal formula.** The chapter poses
`\A self \in Threads : SF_vars(thread(self))` against the `\E` form as a
comprehension test, and the sheet doesn't say whether TLC will run the `\E`
form. It will. `\E w \in Winches : WF_vars(Raise(w))` model-checks and returns
`LIVENESS_VIOLATION` with a counterexample [mutant W1]. I flag it because the
exercise would have needed rebuilding if TLC had refused the formula, and an
author reading the sheet alone can't tell.

**W5 corroborates `verdict.sh`'s 12-against-13 split.** Changing `BridgeRaised`
from `<>(...)` to `[](...)` over a state predicate exits 12, not 13. That's the
"`[]P` over a state predicate is lifted into an invariant" row in
`harness/verdict.sh`'s header table, measured again here on a spec that has no
`INVARIANT` in its `.cfg` at all.

**`Terminating` is invisible without `-d`.** Deleting it changes nothing about
any invariant and nothing about any liveness property in this spec. It changes
whether the all-Done state has a successor, and only the deadlock check looks at
that. That's why exercise 3's how-to-run carries `-d` and why
`reports/run-mutants.sh` passes `-d` for `GlazingBench` alone. Running the G
mutants without it would have made G5 look inert, which would be true of the
flags and false of the exercise.

## One gap in the gate, reported rather than fixed

`harness/test-printed-commands.sh` is the suite that would otherwise catch a
how-to-run line that can't run as printed. It doesn't cover this chapter.
Its chapter list is hardcoded:

```
CHAPTERS=(02 03 04 05 06 07 08 09 10 11)
```

[`harness/test-printed-commands.sh:107`]. The suite passes with 188 assertions
and its last chapter section is ch11 [`bash harness/test-printed-commands.sh`
printed `== ch11: printed commands ... ==` as the last chapter block]. So ch12
and ch13 are outside the gate until somebody adds them to that array, and the
15 delivery runs in the table above are what stands in for it here.

It's a two-token edit and I haven't made it. `harness/` is outside this bead's
`Files:` line, and ch13 is being authored in parallel by another agent, so two
workers appending to the same array is a conflict on a shared file that neither
bead declared. It wants its own bead, adding `12` and `13` together once both
sets have landed.

What I did instead is run the gate against ch12 out of tree, by copying the
suite, setting `CHAPTERS=(12)` in the copy, and running it. All 16 assertions
pass, six of them resolving printed commands from the delivered chapter
directory. So the row is ready to go live the moment somebody widens the array.
The copy was scratch and isn't in this commit.

## What I'd change with more budget

A sixth exercise on an interruptible algorithm, the `\/ pc' = "Start"` disjunct
that PlusCal would need duplicated in every label. It's the largest unexercised
item on the sheet's why-TLA+ list and it's the one of the six that fits in a
module small enough to read. `COVERAGE.md` records the rest of that list as
partial.
