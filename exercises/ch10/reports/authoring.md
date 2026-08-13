# Authoring report: chapter 10 exercise set

Bead `tla-jb7f.22`. Evidence file for `exercises/ch10/EXERCISES.md`, written as
the set was built.

Toolchain: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, which
is the build the pre-flight battery pins. Every verdict below comes from
`harness/verdict.sh`, so it's derived from TLC's exit status and never from its
console text.

Chapter source: `hwayne/learntla-v2` cloned shallow, `git log -1 --format=%H`
returning `09840bfc2ee9a88cdbedb672be77a6c73942fe16` against the pinned SHA.
`docs/core/advanced-operators.rst` read in full, 170 lines. It's the shortest
chapter in the book and it introduces seven constructs, which is most of why
this set runs five exercises rather than three.

## Stated outcomes

Twelve runs against the tree as it stands. All of them reproduced on the pinned
build before the outcome went into `EXERCISES.md`.

| Exercise | Module | Token | rc |
|---|---|---|---|
| 1 pass | `references/Ex1TruckLoad.tla` | `OK` | 0 |
| 1 fail | `references/Ex1TruckLoadBroken.tla` | `SAFETY_VIOLATION` | 12 |
| 2 pass | `references/Ex2GaugePanel.tla` | `OK` | 0 |
| 2 fail | `references/Ex2GaugePanelBroken.tla` | `SAFETY_VIOLATION` | 12 |
| 2 extra | `references/Ex2GaugePanelRecursive.tla` | `PARSE_ERROR` | 150 |
| 3 pass | `references/Ex3SettlingTank.tla` | `OK` | 0 |
| 3 fail | `references/Ex3SettlingTankBroken.tla` | `SAFETY_VIOLATION` | 12 |
| 4 pass | `references/Ex4LiftBands.tla` | `OK` | 0 |
| 4 fail | `starters/Ex4LiftBands.tla` | `SPEC_EVAL_FAILURE` | 75 |
| 4 extra | `references/Ex4LiftBandsReordered.tla` | `SAFETY_VIOLATION` | 12 |
| 5 pass | `references/Ex5TapeFolds.tla` | `OK` | 0 |
| 5 fail | `references/Ex5TapeFoldsRunaway.tla` | `SPEC_EVAL_FAILURE` | 75 |

Command shape for every row, run from the repo root:

```bash
bash harness/verdict.sh <path to module.tla>
```

## Starter outcomes

Five starters, all run on the pinned build.

| Starter | Token | rc | Why |
|---|---|---|---|
| `starters/Ex1TruckLoad.tla` | `PARSE_ERROR` | 150 | `Loaded` undefined until written |
| `starters/Ex2GaugePanel.tla` | `SAFETY_VIOLATION` | 12 | six stubs return placeholders |
| `starters/Ex3SettlingTank.tla` | `PARSE_ERROR` | 150 | `\ominus` undefined until written |
| `starters/Ex4LiftBands.tla` | `SPEC_EVAL_FAILURE` | 75 | ships with a `CASE` missing `OTHER` |
| `starters/Ex5TapeFolds.tla` | `PARSE_ERROR` | 150 | ships with no `RECURSIVE` declaration |

The split follows the format. A write-from-prompt starter has an empty answer
block and can't parse, so the first run names what you owe it. The
complete-the-skeleton starter parses and fails, so the first run is a red test
you drive to green. The two predict-then-check starters ship broken in the
specific way the exercise asks you to predict.

## The delivery contract

`scripts/deliver-exercises.sh` decides what a learner actually receives. For
chapter 10 it delivers `EXERCISES.md`, `LOG.md`, `starters/` recursively, and
the cheat sheets for chapters 2 through 9. It never delivers `references/`,
`reports/`, `COVERAGE.md`, or chapter 10's own cheat sheet.

Two consequences shaped the set.

Both predict-then-check exercises keep their broken module in `starters/`. A
learner has to run the thing they're predicting about, and a module that lives
only in `references/` is never delivered. Ex4 and Ex5 ship broken for that
reason, and the repair is the second half of each task.

Every printed command names a starter. The harness is named by its absolute
path into the puzzles repo, because it isn't delivered. The module is named
relative to the chapter directory, because it is.

Checked by delivering the real chapter into a scratch destination:

```
$ bash scripts/deliver-exercises.sh 10 probe-scratch/delivery
rc=0
```

20 files landed: `EXERCISES.md`, `LOG.md`, 10 starter files, and 8 cheat
sheets. No `references/`, no `reports/`, no `COVERAGE.md`, no chapter 10
`CHEATSHEET.md`.

## Every printed command, run from the delivered tree

`EXERCISES.md` prints seven commands. All seven were run from
`probe-scratch/delivery/ch10`, as printed, character for character.

| Command | Token | rc |
|---|---|---|
| `verdict.sh starters/Ex1TruckLoad.tla` | `PARSE_ERROR` | 150 |
| `verdict.sh starters/Ex2GaugePanel.tla` | `SAFETY_VIOLATION` | 12 |
| `verdict.sh starters/Ex3SettlingTank.tla` | `PARSE_ERROR` | 150 |
| `verdict.sh starters/Ex4LiftBands.tla` | `SPEC_EVAL_FAILURE` | 75 |
| `verdict.sh starters/Ex5TapeFolds.tla` | `PARSE_ERROR` | 150 |
| `verdict.sh starters/Ex4LiftBands.tla --log /tmp/ex4.log` | `SPEC_EVAL_FAILURE` | 75 |
| `grep -n Error /tmp/ex4.log` | 2 lines | 0 |

Each was prefixed `bash ~/repos/tla-puzzles/harness/` in the actual run, which
is the form `EXERCISES.md` prints. The table drops the prefix for width.

The `grep` returned:

```
27:Error: Attempted to evaluate a CASE with no conditions true.
32:Error: The error occurred when TLC was evaluating the nested
```

Then I walked two learner paths end to end inside the delivered tree, since a
starter that runs isn't the same claim as a starter that can be solved.

Exercise 5, both edits the task asks for:

```
$ sed -i 's/^Folds(len) ==/RECURSIVE Folds(_)\nFolds(len) ==/' starters/Ex5TapeFolds.tla
$ bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex5TapeFolds.tla
OK
rc=0
$ sed -i 's/IF len < 3/IF len < 0/' starters/Ex5TapeFolds.tla
$ bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex5TapeFolds.tla
SPEC_EVAL_FAILURE
rc=75
```

Exercise 4, the `OTHER` repair:

```
$ bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex4LiftBands.tla
OK
rc=0
```

## Mutant pass

25 mutants, five per reference, each a single-edit copy driven through
`harness/verdict.sh`. The runner is committed at `reports/mutants.sh` and
rebuilds the table below on demand.

The runner compares each copy against its reference with `cmp -s` before it
invokes TLC, and prints `NOEDIT` if the edit didn't apply. No row came back
`NOEDIT`, so all 25 edits landed. That check is there because a `sed` pattern
that silently misses looks exactly like a mutant the reference caught by being
inert.

| Reference | Mutant | Token | rc |
|---|---|---|---|
| `Ex1TruckLoad` | selection predicate `>=` to `<=` | `SAFETY_VIOLATION` | 12 |
| `Ex1TruckLoad` | fit test `w > room` to `w >= room` | `SAFETY_VIOLATION` | 12 |
| `Ex1TruckLoad` | drop the `1 +` | `SAFETY_VIOLATION` | 12 |
| `Ex1TruckLoad` | recurse on `room`, not `room - w` | `SAFETY_VIOLATION` | 12 |
| `Ex1TruckLoad` | `Dockside` base `{}` to `crates` | `OK` | 0 |
| `Ex2GaugePanel` | `Mapped` ignores its operator argument | `SAFETY_VIOLATION` | 12 |
| `Ex2GaugePanel` | `Kept` negates its test | `SAFETY_VIOLATION` | 12 |
| `Ex2GaugePanel` | `Chained` applies `G(F(x))` | `SAFETY_VIOLATION` | 12 |
| `Ex2GaugePanel` | `Trimmed` LAMBDA sign flipped | `SAFETY_VIOLATION` | 12 |
| `Ex2GaugePanel` | `OverLine` threshold `>= 40` to `> 40` | `OK` | 0 |
| `Ex3SettlingTank` | `\ominus` loses its floor | `SAFETY_VIOLATION` | 12 |
| `Ex3SettlingTank` | starting level 480 to 400 | `SAFETY_VIOLATION` | 12 |
| `Ex3SettlingTank` | settling `\div 5` to `\div 4` | `SAFETY_VIOLATION` | 12 |
| `Ex3SettlingTank` | draw `\ominus 40` to `\ominus 30` | `SAFETY_VIOLATION` | 12 |
| `Ex3SettlingTank` | `Drop` subtracts the other way round | `SAFETY_VIOLATION` | 12 |
| `Ex4LiftBands` | delete the `OTHER` arm | `SPEC_EVAL_FAILURE` | 75 |
| `Ex4LiftBands` | first two arms swapped | `SAFETY_VIOLATION` | 12 |
| `Ex4LiftBands` | top band `>= 900` to `> 900` | `SAFETY_VIOLATION` | 12 |
| `Ex4LiftBands` | `OTHER` answers `"carry"` | `SAFETY_VIOLATION` | 12 |
| `Ex4LiftBands` | bottom band `>= 250` to `>= 80` | `SAFETY_VIOLATION` | 12 |
| `Ex5TapeFolds` | delete the `RECURSIVE` declaration | `PARSE_ERROR` | 150 |
| `Ex5TapeFolds` | base case `< 3` to `< 0` | `SPEC_EVAL_FAILURE` | 75 |
| `Ex5TapeFolds` | base case `< 3` to `< 2` | `SAFETY_VIOLATION` | 12 |
| `Ex5TapeFolds` | count 2 per fold | `SAFETY_VIOLATION` | 12 |
| `Ex5TapeFolds` | fold into thirds, `\div 2` to `\div 3` | `SAFETY_VIOLATION` | 12 |

Caught 23, inert 2, NOEDIT 0.

Both inert mutants are honest, and they're different kinds of honest.

`Dockside`'s base case is inert by construction. The mutant returns `crates`
where the reference returns `{}`, but the only way to reach that branch is the
guard `crates = {}`, so the two expressions are the same value. No invariant
could catch it. I seeded it to check that the pass can still come back `OK`,
which is what tells you the other 23 reds aren't the harness refusing
everything.

`OverLine`'s threshold is inert for a worse reason, and it's a real gap in the
fixture. Changing `g >= 40` to `g > 40` should be catchable, and it isn't,
because `Gauges` is `{12, 28, 41, 55}` and no gauge sits on 40. The boundary
the mutant moves is a boundary nothing tests. I've left it as it stands rather
than adding a fifth gauge, because adding one changes `Trimmed`, `OverLine`
and both `Cardinality` rows, and the exercise is about higher-order operators
rather than about off-by-one thresholds. It's worth knowing about if anyone
extends this set.

## Two findings against the chapter

Both were measured while building this set.

### Recursive and higher-order operators do combine on this build

The chapter states flatly, at `advanced-operators.rst:112`, "You can't combine
recursive and higher-order operators." The sheet's third theme repeats it.
Measured, the restriction is narrower than that.

What fails is the declaration. `RECURSIVE Mapped(_(_), _)` is a parse error:

```
$ bash harness/verdict.sh exercises/ch10/references/Ex2GaugePanelRecursive.tla
PARSE_ERROR
rc=150
```

The log says `Was expecting "comma or )"` and `Encountered "(" at line 19,
column 19 and token "_"`. SANY stops on the declaration and never reads the
definition. `RECURSIVE` accepts bare `_` placeholders only.

What works is declaring the arity without declaring the shape. This module ran
and returned `OK`:

```
RECURSIVE Folded(_, _)
Folded(Op(_), set) == IF set = {} THEN 0
    ELSE LET x == CHOOSE y \in set : TRUE
         IN Op(x) + Folded(Op, set \ {x})
```

`Folded(LAMBDA a: a, {1, 2}) = 3` came back `OK`, and flipping the expected
value to 4 came back `SAFETY_VIOLATION` rc=12, which is how I know the
invariant was evaluated rather than folded away. The operator recursed, it
passed its operator argument down, and it applied it.

I think the chapter's sentence is a simplification of the declaration rule
rather than a claim about the semantics, and I'd rather not guess further than
that. What the exercise teaches is the measured half: the `_(_)` declaration
form is a parse error. The other form stays out of the learner-facing text and
lives here instead.

### An unbounded recursion is fast, not slow

I expected the runaway in exercise 5 to be a slow failure worth warning
learners away from. It isn't.

```
$ time bash harness/verdict.sh exercises/ch10/references/Ex5TapeFoldsRunaway.tla
SPEC_EVAL_FAILURE
rc=75
0.53s total
```

The log carries `Error: This was a Java StackOverflowError`. The stack runs
out in half a second, so the failure is a normal evaluation failure with a
normal token, and it's safe to ship as an exercise. The chapter's warning that
"TLC will throw a stack overflow error" is exactly right about the mechanism.

The token is worth flagging on its own. A stack overflow lands on 75, the same
row as a cross-type comparison and the same row as a `CASE` with no match.
`harness/verdict.sh`'s header already says 75 is a family rather than a
condition, and this is a third member of it.

## Chapter examples avoided

`advanced-operators.rst` is short and every construct arrives with one worked
example, so the overlap risk here is higher than usual. This set reuses none of
the surface content.

| Chapter example | Line | This set instead |
|---|---|---|
| `SumSeq(s)` over a sequence | 40 | no fold over a sequence anywhere |
| `SumSeq` with a `LET RECURSIVE` helper | 47 | two top-level `RECURSIVE` declarations |
| `SetSum(set)` with `CHOOSE x : TRUE` | 61 | a greedy load count, `CHOOSE` on the max |
| `SetToSeq(set)` | 71 | `Dockside`, a set in and a set out |
| `SeqMap(f, seq)` with a function | 97 | `Mapped` over a set with an operator |
| `SeqMap(Op(_), seq)` | 103 | `Mapped`, `Kept`, `Chained` |
| `LAMBDA x: x + 1` on `<<1, 2, 3>>` | 109 | `LAMBDA g: g - 12` on a set of gauges |
| `s \o t`, the `Sequences` definition | 124 | not reused |
| `set ++ x` and `set -- x` | 131 | `x \ominus y`, arithmetic not sets |
| `Double[x \in 1..10] == x * 2` | 145 | `Drop[n \in 1..6]`, a difference |
| `Factorial[x \in 0..10]` | 149 | `Level[n \in 0..6]`, a decay |
| `Fizzbuzz(x)` with `%` and `OTHER` | 162 | `Band(load)`, ordered thresholds |

The two worth commenting on are the ones where the construct forces the shape.

Recursion on a set has to use `CHOOSE`, so exercise 1 can't avoid the
chapter's shape there. It avoids the chapter's *point*: `SetSum` is
commutative and the chapter says the choice doesn't matter, so exercise 1 uses
a greedy loading rule where it matters completely, and the wrong predicate
gives a wrong answer rather than a lucky one.

`Fizzbuzz` and `Band` are both a `CASE` over integer thresholds, because
that's what `CASE` is for. `Fizzbuzz` has arms that overlap on one input out of
fifteen and returns `x` itself from `OTHER`, mixing an integer into a set of
strings. `Band` overlaps on every input above 900 and keeps one type
throughout, which is deliberate: a cross-type comparison aborts evaluation on
this build, and that would mask the `CASE` failure the exercise is about.

## Run count

63 `harness/verdict.sh` invocations over the session by my count, including the
drafts that got replaced and the seven probe modules built before any exercise
existed. 44 of them are runs against the tree as it stands: 12 reference
modules, 5 starters, 25 mutants, and 7 from the delivered scratch tree, less
the overlap where the same module was run twice.

The probe modules were scratch and are not committed. They pinned five
behaviours before a single exercise was written: `\ominus` is definable,
bracket functions recurse without a declaration, a `CASE` with no match exits
75, a missing `RECURSIVE` exits 150, and a runaway recursion exits 75 in half
a second.

## Scope

No PlusCal. No `CONSTANT`, no `PROPERTY`, no temporal operator. The boundary
check against the chapter 2 through 10 sheets is in `exercises/ch10/COVERAGE.md`.

One judgement call worth flagging, and it's the same one every chapter after
4 has to make. Exercise 1 uses `\A` inside its `CHOOSE` predicate, which is
chapter 4. The exercise exists to make the difference between a unique
selection predicate and `TRUE` bite, and I couldn't find a way to write "the
largest crate" without a quantifier. Chapter 4's sheet is delivered with this
set, so a learner has it to hand.
