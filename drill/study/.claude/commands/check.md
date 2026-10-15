---
description: Check the drill attempt in this directory against the prompt's own claims
---

Check the attempt in the current directory. `CLAUDE.md` in the study root is a
refusal contract and it governs every step below. Read it first if you haven't
in this session, and reread the part about never writing TLA+ before you report
anything.

Work in three passes. The first is a script. The other two are the reason you're
here, because a script can't do either of them.

## 1. Run the checker

Run `./check` from this directory. Report its exit code and quote its numbers
as printed. The number TLC found and the number the prompt claimed both come
out of that script, so take both from there and derive neither yourself.

What each exit code means:

- 0, every count claim in the prompt was matched
- 1, a claim was not matched, and both numbers are in the output
- 2, UNCHECKED, because the prompt publishes no count
- 3, it could not run, so nothing was established

An exit 3 is a fact about the checker and not about his model. Say so plainly
and stop there, rather than reading TLC yourself to fill the gap.

## 2. Read for a right count reached by a wrong model

This is the pass that matters and the one `./check` structurally cannot make.

A distinct-state count is a property of `Init`, `Next` and the state
constraint. It isn't a property of the obligations. So a model that reaches the
published count exactly can still assert almost nothing, and TLC will report no
error over it, because the obligation that would have failed was never there to
fail. Measured on the reference module for one item: drop its ordering
invariant and TLC still reports no error at exactly the count the prompt
publishes.

So read what he wrote and ask whether the obligations rule out the behaviors
the prompt described, rather than whether the numbers line up. Two shapes I'd
look for first:

- a rule weak enough to be true of the wrong machine as well
- a rule that holds because nothing in `Next` can reach the state it bounds

The second is vacuity. A property nobody can violate is green and empty, and
the prompt's count will not notice.

When you find one, report the behavior his model admits or forbids. Never the
construct that would fix it.

## 3. Read his prose answer

Many prompts end in a question rather than a count, and the temporal family
ends in one by design. Those answers are in whatever file or comment he wrote
them in, so look for them before you conclude the item has nothing to grade.

Read the prompt to find the question. It's at
`~/tla-practice/drill/*/<slug>/PROMPT.md`, where `<slug>` is this directory's
name, and the delivered prompt tree is the one place you're allowed to read.
Then judge the answer on whether it's true of the model he actually wrote, not
on whether it matches an answer you have in mind.

A question he didn't answer is worth saying out loud. A question he answered
wrongly gets the same treatment as a failed obligation: name what his model
does, and leave the construct to him.

## What to hand back

Four things, in this order:

1. The checker's exit code and its numbers, quoted.
2. Each obligation that fails, as a behavior the model admits or forbids.
3. Each prose question, answered or not, and your read of the answer.
4. Nothing else.

If every pass comes back clean, say that, and say which of the three passes
actually had something to check. A green run over an item whose prompt
publishes no count and asks no question is a run that checked one thing.
