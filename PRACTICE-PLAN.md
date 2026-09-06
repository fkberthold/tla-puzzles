# Practice plan

This replaces `V2-PLAN.md` as the live plan. `V2-PLAN.md` stays in the repo as the
record of how we got here. Nothing in it is deleted, and nothing in it is being
rewritten. Where the two disagree, this one is current.

Written 2026-09-05, the day the direction changed.

## What changed

Batch 2 shipped seven problems. I worked the easiest one and found five defects in
an hour. Independent reviews of five more problems found the same shapes in each of
them. Three surveys ran after that, and this section is what they measured. Every
number below is from today.

**The load vector set the shape, not the material.** Six of six problems examined
had their shape set by a load-vector band. Property count is measured in reference
`.cfg` lines, and a line count doesn't change when you join two formulas with `/\`.
So an author who needs a smaller number joins two obligations, and the count comes
out legal. Measured on assay-office: the split version gives identical verdicts on
all 26 rows, and across 9 caught variants the shipped set names 2 causes where the
split names 5. The learner loses three labels and the number on the form stays the
same.

**Cold English-to-TLA+ is 16 correct in 100.** TLA+-Bench, arXiv:2607.23425, Claude
Opus 4.5. About 6 in 100 after screening out specs that never leave their initial
state and specs that check only a type invariant. The benchmark's authors say the
plain rate "overstates genuine capability by roughly 2.5 times".

**A model judging a learner's work over-validates at 69 to 71%.** It marks wrong
solutions valid. arXiv:2605.16207, over 10,836 solution-feedback pairs.

**Our own blind test agrees.** The holdout build's first five seeded mutants went 4
of 5 uncaught. The pilot went 5 of 11.

**`Observe` is unattested.** Building a record from the variables and stating
properties over it appears nowhere in published practice. 176 such records across
666 modules, and 0 of them declared as an `INVARIANT` or a `PROPERTY`.

Put the first three together and the machine-authored, machine-graded pipeline
doesn't hold up. A model authoring cold is right about 6 times in 100, and a model
checking that work calls wrong work right about 7 times in 10. Our own seeded-mutant
numbers land where those two would put them.

## What we have instead

The exercisable corpus is 67 systems. The funnel: 662 modules, 208 specs, 107
distinct systems, 99 describable, 68 fast enough to check, 67 after licence.

| tier | systems |
|---|---|
| 1 | 9 |
| 2 | 11 |
| 3 | 1 |
| 4 | 6 |
| 5 | 40 |

Prose ships with 50 of the 67, and with 34 of the 40 at tier 5. So the corpus is
top-heavy, tier 3 is close to empty, and the systems that come with an explanation
are mostly the hard ones. I come back to that under what's open.

## The decisions

These are locked as of today.

**No grader.** The seven delivered problems stand and get no rework. About 3,800
lines of grading, vacuity, refinement and seeded-bug harness stop being maintained.
Nothing is deleted. It sits in the repo and nobody feeds it.

**Curated, not authored.** Each problem starts from a published, human-authored
spec. That spec goes into a subfolder of the problem as one example of an
implementation. It is never an answer key, and the wording is load-bearing. A
learner who models the same system a different way hasn't made a mistake.

**The statement.** This is the only piece written fresh, and the rule on it is hard.
A statement describes the system and never the spec. No variable is named. No data
structure is implied. No decomposition is suggested. Having the spec open while
writing the statement is the hazard, and I check for that going in, not after.

**The choice note.** Each problem carries a note on what the shipped implementation
chose that the rules don't force. Without it a different and correct model reads as
wrong, and I think that's the failure this shape is most exposed to.

**The techniques.** Each problem lists 3 to 4 techniques that apply, derived by
reading the shipped implementation, so each one is an observation and not a
prediction. Technique level only, never a formula and never a count. The
counterfactual gets stated out loud, e.g. this one used refinement and could be done
without it at a larger state space. A technique is announced on its first appearance
and folded away on later ones.

**Difficulty.** One scale of 1 to 5, assigned after a problem exists, never a
target. No problem gets shaped to hit a level. The list is built by sorting problems
against each other and cutting the sorted list into five, because comparative
judgment beats absolute judgment.

**Directory names.** Directories are tier-prefixed. A number in a name is a
difficulty tier, which is stable, and not a position in an order, which isn't. My
existing seven stay where they are, untouched.

**One step ahead.** Build one problem ahead of me, never thirty. Batch authoring
can't be validated by a reader who can only reach the first few, and that's what
batch 2 demonstrated.

**Validation.** It splits in two, and the split is about what I can actually judge.
I can tell whether the rules are clear, complete and consistent at any tier,
including problems I can't solve, because that part is reading. I can't judge
tiering until I arrive at a problem, and getting a tier wrong is cheap to fix. There
is a third check that needs nobody: read the statement and the spec together, then
list what the spec does that the statement never licensed, and what the statement
claims that the spec doesn't do. That's a consistency check between two artifacts
that already exist.

**The reaction log.** My reactions need somewhere to land. A dated file with a
sentence in it is enough. The old plan's door test kept saying a mis-ordered problem
is one I'd complain about, and it never built anywhere for the complaint to go.

**Chapter 12.** I'm at learntla section 11. Chapter 12 isn't a gate to clear. It's
the territory the work lives in, and it's worth inhabiting rather than passing
through.

## What a problem looks like

Four pieces, from two places.

- The statement, written fresh from the system.
- The choice note, on what the implementation picked freely.
- The techniques, 3 to 4, read off the implementation.
- The spec, in a subfolder, as one example.

Only the statement is authored from nothing. The other three get read off an
artifact that already exists, and that's the whole point. An observation can be
checked against its source. A prediction can't.

## The difficulty scale

One scale, anchored on state representation.

| tier | state representation |
|---|---|
| 1 | scalar or set state, an algorithm with invariants over it |
| 2 | one function as state, few entities |
| 3 | several functions, or a nested one, or rules relating entities |
| 4 | tier 3's state, and progress matters or the abstraction boundary is the question |
| 5 | refinement, or behaviour only visible from parties interacting |

State representation is the anchor because it drives counterexample width, and
counterexample width drives the debugging skill I'm getting the most out of. A wider
counterexample is a harder read, and reading them is where the practice actually
happens.

The learntla mapping falls out of that. Chapter 12, meaning `EXCEPT`, `@` and tuple
subscripts, spans tiers 2 through 4. Chapter 13, meaning `INSTANCE`, opens tier 5.
Only tier 1 sits below chapter 12.

## What is retired

Retired means nobody maintains it. Nothing is deleted, no history is rewritten, and
the seven delivered problems are not reworked.

- The grader and its verdict objects.
- The vacuity probes.
- The seeded-bug matrix.
- The domain and puzzle screens.
- The `Observe` interface.
- The load vector and the ramp rule.
- The shape taxonomy, columns A through D.
- The blind panel and its spread rule.
- The batch-authoring stages.

`Observe` is worth calling out on its own, because it dies twice over. The corpus
count above says it isn't a thing practitioners write. The statement rule says a
statement can't name a data structure, and `Observe` is a data structure, so a
statement can't reach it anyway.

The blind panel goes for a measured reason, not a budget one. Its job was to tell a
hard problem from an ambiguous one by reading the spread in the answers, and the
pilot returned byte-identical answers from three seats. A panel that agrees tells
you nothing about the problem.

## What is still open

Three things need me before authoring starts, and none of them is settled.

1. **The manifest.** Nothing about its contents is decided. What a problem entry
   carries, what's indexed and what's derived are all open.
2. **The first three problems.** Not picked. The corpus has 67 systems and the tier
   distribution above says the easy end is thin.
3. **Where the reaction log lives.** A dated file with a sentence in it, and no
   decision on the path, the format or whether it's one file or one per problem.

Two more I'd want to settle early, and these are my read, not a locked question.

Tier 3 has one system in it. I suspect the tiers need building against what the
corpus holds, not against a flat 1-to-5 shape, and that a tier-3 problem may have
to be made by cutting a tier-4 system down. That's a different move from curation,
and it deserves saying out loud before it happens by accident.

Prose ships with 50 of 67 systems, so 17 come with nothing but the spec. A statement
written for one of those 17 has no independent description to check against, and the
consistency check in the validation section has only one artifact to work with. I
think those 17 go last, or get dropped, but I'd rather decide it than discover it.

## Retired plan

`V2-PLAN.md` is the record. Read it for how the taxonomy, the load vector and the
harness were arrived at, and for the measurements that stand on their own. Don't
read it for what to build next.
