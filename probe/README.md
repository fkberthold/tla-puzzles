# The transfer probe

Two items, graded on refinement, that sit outside the drill distribution on
purpose. This is probe 1 of four. The schedule is item 10, 32, 54 and 64 of
the 64-item drill run, and this one runs at item 10 because a pre-practice
baseline is the one reading that cannot be recovered later.

## What it measures, and what it does not

The question is whether the drills reach work that is not shaped like a drill.
Two readings fit "I feel like I'm learning" equally well. One is that
specification skill is going up. The other is that fluency with one item
format is going up. Those readings only come apart on items outside the
practiced distribution, measured more than once, on a channel that does not
care how anybody feels about it.

Four probe points will never be statistically significant, and this document
would rather say so than dress it up. What they give is a dissociation or the
absence of one, between the drill pass rate and the probe pass rate over the
same interval. That is a form of evidence a performance trend on the
acquisition items cannot provide at all.

## How a probe item differs from a drill item

| dimension | drill item | probe item |
|---|---|---|
| prose | about 150 words | 600 words and up |
| state count | published, and the answer reaches it | none, on purpose |
| construct list | adjacent | none |
| framing | an exercise | work somebody would review |
| machines | one | two, related by a mapping you write |
| specified | fully | at least one bound left open |

The missing state count is the biggest of those. No real engagement tells you
how many distinct states the right answer reaches, so the drills carry part of
their own answer and these items do not. There is no count for either item
here, and `harness/probe-gate.sh` asserts that one never grows back.

## Running an item

```bash
probe/scripts/fetch-oracles.sh     # once, before the first item
./probe list
./probe start p1-commit 60 percent first try, about 45 minutes
./probe decide p1-commit requirements 1 and 4, the abort right ends at the vote
./probe grade p1-commit
./probe status
```

`start` records the prediction and then prints the brief. It needs both, and
it refuses a prediction with no number in it. Kornell and Bjork 2009 found
actual performance rising sharply while predictions of it stayed flat, so
prediction accuracy is a second signal independent of the verdict, and it
costs one line.

`grade` refuses until a decision is recorded. Each item puts a pair of
requirements next to each other whose interaction the prose does not settle,
and the point is the reasoning as much as the verdict.

Everything lands in `RECORD.tsv`, append-only, one line per prediction,
decision and verdict. Nothing asks you to go and write something down
separately. Three capture surfaces in this project were specified, shipped,
and stayed empty for exactly that reason.

## The grader

`harness/refinement.sh`, in the repo. Point `PROBE_REPO_ROOT` or
`DRILL_REPO_ROOT` at a checkout before grading. It runs TLC twice, because one
run cannot certify a refinement.

The first run asks whether your specification refines the requirement. The
second asserts, as an ordinary invariant, that your mapped expression never
leaves its initial value, and then requires TLC to violate it. A mapping that
never moves discharges the whole refinement obligation by stuttering, which
means a check that passed read nothing. So a passing probe is a failing
invariant check, and both runs have to come out right.

That trapdoor is open in `tlaplus/TLAiBench`, the only public benchmark that
grades TLA+ refinement, and it is why this grader is worth using.

## Reading your own result

`REFINES` means the refinement holds and the mapping moves. It does not mean
the specification is good. Two things the grader cannot see:

- A module carrying state the described system does not have. For any two
  specifications, suitable auxiliary variables make a mapping exist, so a
  history variable can buy a pass. Check for one by eye.
- Whether anything in the system is left unsaid. Refinement bounds what your
  specification admits. It says nothing about what it forgot to model.

`REFINEMENT_VIOLATED` leaves a counterexample trace. It names the step your
specification took that the requirement has no answer for, and reading it is
most of the value of a failed run.

## Where the answers are

Each brief names the published module it is measured against and the commit it
is pinned to. Do not read one before grading. Afterwards, read it closely, and
pay more attention to where your structure and theirs disagree than to where
they match.

The requirement modules themselves are fetched rather than committed, which is
bead `tla-16je`. Both of these two are MIT licensed, so a committed copy with
its notice would have been allowed, but the fetch is the rule the design bead
wrote and it keeps the pin honest.
