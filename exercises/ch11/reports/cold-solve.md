# Cold-solve review: ch.11 exercise set, Action Properties

Bead `tla-jb7f.23`. Reviewer worked in an isolated worktree, model family
distinct from the authoring session.

## How this run was done

Phase 1 solved blind from a delivered tree:
`bash scripts/deliver-exercises.sh 11 <scratch-dir>`
[cmd: `bash scripts/deliver-exercises.sh 11 cold-solve-tmp.artIit`, exit 0, `find` over
the result showed `EXERCISES.md`, `LOG.md`, `starters/` (5 files), and
`cheatsheets/ch02.md` through `ch10.md`, and nothing from `references/`,
`reports/`, `COVERAGE.md`, or ch11's own `CHEATSHEET.md`].

Phase 2 reviewed open-book: `exercises/ch11/references/`,
`exercises/ch11/reports/authoring.md`, `exercises/ch11/COVERAGE.md`,
`exercises/ch11/CHEATSHEET.md`, and a shallow clone of `hwayne/learntla-v2`
already checked out at the pinned SHA
[cmd: `git -C <clone> log -1 --format='%H'` → `09840bfc2ee9a88cdbedb672be77a6c73942fe16`,
matches the SHA recorded in `exercises/ch11/CHEATSHEET.md:7` and
`exercises/ch11/reports/authoring.md:10`].

Timings below are `date +%s` deltas around an agent tool-call loop, not a
human stopwatch. They are not comparable to the 10-15 minute budgets on their
own. What they do show honestly: every exercise solved correctly with no
backtracking, no re-reads, and no failed TLC run along the way. Process
complexity, not raw seconds, is what the BUDGET judgment below rests on.

## Process note: predict-then-check blindness was compromised

Before phase 1 began in earnest, I read the full delivered `EXERCISES.md` in
one pass to plan the scratch-tree workflow, including the "After the run"
answer sections for exercises 2 and 3
[file: the Read tool call against the delivered `EXERCISES.md` early in this
session, before the phase-1 clock started on exercise 1]. That means my
Ex2/Ex3 predictions were informed, not blind. I disclose this rather than
fabricate a blind log.

This does not touch the parts of phase 1 that matter most for review: whether
the printed commands work, whether the stated pass/fail tokens reproduce, and
whether any instruction required a guess. Those are reported faithfully
below. What is lost is only the genuine "did I predict wrong" signal the
predict-then-check format is designed to produce. This is a limitation of
this review run, not a defect of the exercise set.

## Phase 1 solve log

### Exercise 1, Delivery odometer (write-from-prompt, budget 15 min)

Start `1786582743`, end `1786582770` (27s agent time)
[cmd: `date +%s` x2 around the write, translate, and both runs].

Wrote `starters/Odometer.tla` from the task text alone: `EXTENDS Integers`,
`MaxLegs == 3`, `LegLength == 2`, two variables, `MilesNeverFall ==
[][miles' >= miles]_miles`, `LegsCountUpByOne == [][legs' = legs + 1]_legs`,
one `Depot: while` loop with `Roll` and `Log` labels.

Pass run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Odometer.tla
-c starters/Odometer.cfg` printed `OK`, matching the stated pass outcome
[cmd: exact printed command, exit 0, token `OK`].

Fail run: changed `Roll` to `miles := miles - LegLength;`, re-ran `pcal`,
re-ran the same verdict command. Printed `LIVENESS_VIOLATION`, exit 13,
matching the stated fail outcome exactly
[cmd: exact printed command after the edit, exit 13, token `LIVENESS_VIOLATION`].

Solved on the first attempt, no guessing, no stuck points. My solution is
byte-identical in the `define` block to `exercises/ch11/references/Odometer.tla:20-25`
(read afterward, in phase 2).

### Exercise 2, What the brackets buy (predict-then-check, budget 10 min)

Start `1786582805`, end `1786582833` (28s agent time).

Predictions compromised per the process note above. As shipped: ran
`starters/StepProbe.tla` unmodified, printed `OK`, matching the stated pass
outcome [cmd: printed command verbatim, exit 0, token `OK`]. Removed the
brackets from `RungGoesUpByOne` (`[](rung' = rung + 1)`), re-ran `pcal`
(translation succeeded, no error), re-ran `verdict.sh`. Printed
`PARSE_ERROR`, exit 150, matching the stated fail outcome exactly
[cmd: printed command after the edit, exit 150, token `PARSE_ERROR`].

Worth recording for a genuinely blind learner: `pcal` itself does not catch
this. The bad form only fails at SANY/TLC's semantic check inside
`verdict.sh`, one command later than a learner might expect "the module
does not compile" to bite.

### Exercise 3, The jump the invariant cannot see (predict-then-check, budget 12 min)

Start `1786582835`, end `1786582858` (23s agent time).

Predictions compromised per the process note above. As shipped: ran
`starters/Thermostat.tla` unmodified, printed `OK`, matching the stated pass
outcome [cmd: printed command verbatim, exit 0, token `OK`]. Changed
`setpoint := setpoint + 1;` to `setpoint := High;` in the `Adjust` either
branch, re-ran `pcal` (the edit is in the algorithm body, one `pcal` run
picked up both copies as the task text promised), re-ran `verdict.sh`.
Printed `LIVENESS_VIOLATION`, exit 13, matching the stated fail outcome
exactly [cmd: printed command after the edit, exit 13, token
`LIVENESS_VIOLATION`].

Solved on the first attempt, no guessing.

### Exercise 4, Two tanks, one property (complete-the-skeleton, budget 12 min)

Start `1786582864`, end `1786582884` (20s agent time).

Filled `TODO_1` as `LevelsNeverFall == [][\A t \in Tanks: level[t]' >=
level[t]]_level`, following the task text's own worked explanation of why
the quantifier has to move inside the box. Re-ran `pcal` (define-block-only
edit, one run updated both copies). Pass run printed `OK`, matching the
stated pass outcome [cmd: printed command verbatim, exit 0, token `OK`].
Changed the `Top` label from `level[self] := Cap;` to `level[self] := 0;`,
re-ran `pcal`, re-ran `verdict.sh`. Printed `LIVENESS_VIOLATION`, exit 13,
matching the stated fail outcome exactly [cmd: printed command after the
edit, exit 13, token `LIVENESS_VIOLATION`].

Solved on the first attempt. My fill is byte-identical to
`exercises/ch11/references/TankFarm.tla:18-19` (read afterward, in phase 2).
See the NEAR-COPY finding below: the task text hands the learner most of
this formula already, in the "obvious first attempt" it walks through.

### Exercise 5, Airlock (write-from-prompt, budget 15 min)

Start `1786582924`, end `1786582963` (39s agent time, the longest of the
five, consistent with it being the densest write-from-scratch exercise).

Wrote `starters/Airlock.tla` from the task text: two variables at `"shut"`,
`NeverBothOpen == ~(outer = "open" /\ inner = "open")`, `Moves(door, to) ==
door' = to`, `OuterOnlyShuts` and `InnerOnlyShuts` each built from `Moves`
guarded on the door's own open state, one `Cycle: while (TRUE)` label over a
four-branch `either`.

Pass run printed `OK`, matching the stated pass outcome [cmd: printed
command verbatim, exit 0, token `OK`]. Changed the branch that shuts the
outer door to `outer := "ajar";`, re-ran `pcal`, re-ran `verdict.sh`.
Printed `LIVENESS_VIOLATION`, exit 13, matching the stated fail outcome
exactly [cmd: printed command after the edit, exit 13, token
`LIVENESS_VIOLATION`].

Solved on the first attempt. My solution matches
`exercises/ch11/references/Airlock.tla` line for line, modulo the order of
the two conjuncts in one `await` guard. The one thing I had to reason
through rather than transcribe: whether `Moves(outer, "shut")` (priming a
formal parameter bound to a plain variable) is legal TLA+ and is something a
first-time-through-this-exercise learner could be expected to know. See the
AMBIGUITY finding below: checked, and it is pre-taught.

## Phase 2 findings

### EVIDENCE, checked, no discrepancy

`bash exercises/ch11/reports/run-refs.sh` reproduced exactly: all 5
references `OK`, rc=0 [cmd: `bash exercises/ch11/reports/run-refs.sh`,
output `Odometer OK rc=0`, `StepProbe OK rc=0`, `Thermostat OK rc=0`,
`TankFarm OK rc=0`, `Airlock OK rc=0`].

`python3 exercises/ch11/reports/mutants.py` seeded all 24 mutants with no
`SEED-ERROR` line [cmd: ran from repo root, 24 `seeded <id> <module>` lines,
no failure line, matching the script's own exit-1-on-failure contract].

`bash exercises/ch11/reports/run-mutants.sh` reproduced
`exercises/ch11/reports/authoring.md`'s 24-row table exactly, id for id,
token for token, rc for rc: 19 flip (every id except O5, S4, T3, K3, A4),
5 inert, matching "19 flip, 5 documented inert of 24" precisely [cmd:
`bash exercises/ch11/reports/run-mutants.sh`, 24 output rows compared
line by line against `exercises/ch11/reports/authoring.md:161-186`].

Every stated pass/fail outcome in `EXERCISES.md` traces to a specific row in
this table (O1, S1, T1, K1, A1 for the five stated fail runs) or to my own
phase-1 run of the same edit, and both agree.

### The two documented findings, spot-verified

Finding 1 (`exercises/ch11/reports/authoring.md:70-95`), a bare `[](action)`
is `PARSE_ERROR` at the definition site, not a false property. Spot-verified
twice: once live in exercise 2's fail run above, and again structurally via
mutant S1 and O3 in the reproduced table. Confirmed [cmd: exercise 2's fail
run, exit 150, token `PARSE_ERROR`].

Finding 2 (`exercises/ch11/reports/authoring.md:96-118`), the subscript, not
the quantifier position, is what TLC refuses. The mutant table's K2
confirms the refused half (quantifier outside, per-element subscript
`level[t]`, `PARSE_ERROR`). I ran a dedicated probe for the other half the
finding depends on, that a quantifier OUTSIDE the box with the subscript
correctly on the WHOLE variable still parses and is genuinely checked:
`\A t \in Tanks: [][level[t]' >= level[t]]_level` against a monotone
TankFarm variant [cmd: wrote a probe module in worktree-local scratch, `pcal`
succeeded, `bash ~/repos/tla-puzzles/harness/verdict.sh` printed `OK`, exit
0]. Confirmed: it is the subscript shape, not the quantifier's position,
that SANY refuses.

### BUDGET, not breached

All 5 exercises solved on the first attempt with no re-reads, no dead ends,
and no failed intermediate run. That is the strongest signal available
without a human timer: nothing in any exercise required backtracking that
would eat into a 10-15 minute allowance. Exercise 5 is the densest (four
`define` entries plus a four-branch `either`, 15 min budget) and is where I
would expect a real first-time learner to spend the most of their budget,
consistent with it also being my own longest agent-timed exercise. Not a
defect, noting it as the one to watch if the budget ever gets tightened.

### AMBIGUITY, checked, one candidate resolved as pre-taught

Candidate: exercise 5's `Moves(door, to) == door' = to`, called as
`Moves(outer, "shut")`, primes a formal parameter bound to a plain variable.
Nothing in the ch02-ch10 cheat sheets or in the other ch11 starters
demonstrates this pattern, so at first pass it read as something a learner
might not know is legal.

Checked against the actual chapter text via the pinned clone:
`docs/core/action-properties.rst:141-148` teaches exactly this pattern,
`BecomesNull(x) == x' = NULL` called as `BecomesNull(lock)` inside
`LockCantBeStolen == [][lock # NULL => BecomesNull(lock)]_lock`
[file: `<clone>/docs/core/action-properties.rst:145-148`]. `exercises/ch11/CHEATSHEET.md:28`
also states the theme in prose ("Helper actions let you factor
primed-variable logic into named operators... and reuse it inside more than
one action property"). Not an ambiguity: the exercise set's own design
assumes the chapter has been read (`EXERCISES.md:3`, "once you've read the
chapter"), and the chapter covers this exact call shape.

No other guess was required anywhere in phase 1.

### PREREQUISITE LEAK, none found

Cross-checked all 5 solutions against the delivered `cheatsheets/ch02.md`
through `ch10.md`. Every construct used traces to a chapter at or before 11:
`EXTENDS Integers`/arithmetic/strings/`/\`/`\/`/`~`/`=>` (ch02), `while`,
labels, `:=` (ch03), `define` block, `\A` (ch04), function literal
`[x \in S |-> e]` (ch06), `either`/`or` (ch07), process set and `self`,
`await` (ch08), `PROPERTY` (ch09). This matches
`exercises/ch11/reports/authoring.md:236-263`'s own scope table, verified
independently rather than taken on trust, since phase 1 was solved with only
the delivered cheat sheets available.

The one documented partial: `exercises/ch11/COVERAGE.md:24-46` states theme
6's liveness half ("unlike liveness properties, where every spec needs at
least one") is not drilled, because doing so honestly would need a `fair
process` and a `<>` property, both chapter 9 constructs, and the author
judged that a bad trade against the time budget. Judged: honest. It names
the exact gap, names the exact chapter the missing material would come from,
states the trade-off reasoning rather than hiding it, and explicitly invites
correction ("I think this is the weakest omission in the set"). No hedge, no
minimization.

### NEAR-COPY

**Exercise 4, DEFECT.** `LevelsNeverFall` in
`exercises/ch11/references/TankFarm.tla:18-19`:

```
LevelsNeverFall ==
  [][\A t \in Tanks: level[t]' >= level[t]]_level
```

is a rename-only match of the chapter's own `counters_3` worked example,
which is the chapter's sole demonstration of the exact theme this exercise
is the sole coverage for (COVERAGE.md's theme 5 row lists only exercise 4):

```
CounterOnlyIncreases ==
  [][
    \A c \in Counters:
      values[c]' >= values[c]
    ]_values
```

[file: `<clone>/raw-specs/action_props/counters__3.tla:14-18`]. Same
relation (`>=`), same quantifier form, same whole-variable subscript
placement, same box-then-subscript shape. Only `c`/`Counters`/`values`
became `t`/`Tanks`/`level`.

This is not confined to the reference answer. `EXERCISES.md:222` hands the
learner the near-identical predicate directly, as the stated "obvious first
attempt": `` \A t \in Tanks: [][level[t]' >= level[t]]_level[t] ``. A
learner is not deriving `level[t]' >= level[t]` themselves. They are given
it and asked only to relocate the subscript, which is precisely the
transformation the chapter's own counters_2-to-counters_3 diff performs on
the identical relation.

`exercises/ch11/reports/authoring.md:35-41` shows the author consciously
worked this exact risk for exercise 5's helper action and reasoned through
a real difference (two-argument generalization, reused across two
variables, neither of which the chapter's `BecomesNull` does). No parallel
reasoning appears anywhere for exercise 4. The gap looks like an oversight,
not a considered trade-off, because unlike exercise 5's case, a
differentiated predicate was available within scope: any relation other
than plain `>=` (e.g., an exact per-step bound) would still force the same
quantifier-commuting fix while not reusing the chapter's specific formula.
I am not prescribing that fix. I am noting one exists, which is what makes
the current form a choice rather than a necessity.

**Exercise 1, NOTE, not a defect.** `MilesNeverFall == [][miles' >=
miles]_miles` (`exercises/ch11/references/Odometer.tla:20`) echoes the
chapter's un-quantified `CounterOnlyIncreases == [][counter' >=
counter]_counter` [file: `<clone>/raw-specs/action_props/threads__2.tla:19-20`]
in the same rename-only way. Weighed lighter than exercise 4's case for two
reasons: `x' >= x` is close to the only sensible way to state "may hold
still, may climb, may never drop" at all, so some echo across any chapter
teaching the same idiom is close to unavoidable, and `MilesNeverFall` is one
of two properties in the exercise, with the exercise's own stated point
being about brackets tolerating steps that leave a property's variable
untouched (`EXERCISES.md:76-79`), not about the monotonicity idea in
isolation.

**Exercise 5, checked, not a defect.** The helper-action pattern echoes
`docs/core/action-properties.rst:141-148`'s `BecomesNull`/`LockCantBeStolen`
structurally (guarded implication feeding a helper action, subscripted on
the guarded variable), but the author's own differentiation
(`exercises/ch11/reports/authoring.md:35-41`) holds up under my own check:
two arguments instead of one, reused across two variables with the same
target rather than once, different domain and different guard operator
(`=` on strings vs `#` on a model value). This is the necessary minimal
echo of teaching the technique the chapter itself defines, not a copy of
the chapter's specific spec.

**Exercise 2 and Exercise 3, checked, not near-copies.** `StepProbe`'s
`RungGoesUpByOne == [][rung' = rung + 1]_rung` matches the chapter's own
abstract syntax illustration for what `[P]_x` sugar means, `[][x' = x +
1]_x` (`<clone>/docs/core/action-properties.rst:99`), not a concrete named
running example. Every correct use of the box-action-formula construct
looks like some instantiation of that line: it is the definition, not a
running example, so instantiating it is expected use rather than
duplication. `Thermostat` has no chapter-side analogue I could find. It is
original.

### COVERAGE, holds

`exercises/ch11/COVERAGE.md`'s theme and construct tables hold against what
the five exercises actually exercise, cross-checked exercise by exercise
during phase 1 and phase 2 rather than taken on the file's word. The one
partial (theme 6) is addressed above and judged honestly documented.

### Delivery-seam check, holds

`scripts/deliver-exercises.sh 11 <dest>` delivered exactly `EXERCISES.md`,
`LOG.md`, `starters/` (5 files: 3 `.tla`+`.cfg` pairs, 2 `.cfg`-only for the
write-from-prompt exercises), and `cheatsheets/ch02.md` through `ch10.md`.
Nothing from `references/`, `reports/`, `COVERAGE.md`, or ch11's own
`CHEATSHEET.md` was present [cmd: `find <dest> -type f`, compared against
the never-delivers list in `scripts/deliver-exercises.sh`'s header comment].
Every how-to-run command in `EXERCISES.md` worked verbatim from inside the
delivered tree, all ten pass/fail runs across the five exercises.

## Verdict

**SEND BACK.** One DEFECT: NEAR-COPY on exercise 4's `LevelsNeverFall`
against the chapter's `counters_3` worked example
(`exercises/ch11/references/TankFarm.tla:18-19`,
`exercises/ch11/EXERCISES.md:222`, `<clone>/raw-specs/action_props/counters__3.tla:14-18`).
Everything else checked in this pass holds without a defect: budget,
ambiguity, the other four near-copy candidates, prerequisite leak,
coverage, and evidence. One repair round should be enough. The fix is
scoped to one predicate in one exercise and does not touch the
quantifier-placement lesson the exercise exists to teach.
