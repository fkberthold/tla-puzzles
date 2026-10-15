---
description: Check the drill attempt in this directory against the prompt's own claims
---

Check the attempt in the current directory. `CLAUDE.md` in the study root is a
refusal contract and it governs every step below. Read it first if you haven't
in this session, and reread the part about never writing TLA+ before you report
anything.

Work in four passes. The first is a script. The other three are the reason
you're here, because a script can't do any of them.

## 1. Run the checker

Run `../check`. The checker sits at the study root and you're in a slug
directory under it, so a plain `./check` reports that no such file exists. If
Frank came in through `./drill --check` the run has already happened and its
output is in your prompt, so quote what you were handed and don't try to run
anything.

Report its exit code and quote its numbers as printed. The number TLC found and
the number the prompt claimed both come out of that script, so take both from
there and derive neither yourself.

What each exit code means:

- 0, every count claim in the prompt was matched
- 1, a claim was not matched, and both numbers are in the output
- 2, UNCHECKED, because the prompt publishes no count
- 3, it could not run, so nothing was established

An exit 3 is a fact about the checker and not about his model. Say so plainly
and stop there, rather than reading TLC yourself to fill the gap.

## 2. Compare a violation against the prompt's table

Some prompts carry a table of states with a `possible?` column, and `CLAUDE.md`
has the rule. Do this pass before you read his obligations, because which way
it comes out changes what the rest of the report means.

If a module violated, take the state the checker stopped on and look for it in
the table.

- a row marked no, the ordinary case, and some items ask for it
- a row marked yes, where the rule forbids what the prompt requires
- no row at all, so the table settles nothing and pass 3 carries the weight

The middle one is a report about the rule rather than about the model. Say
which row it is and say that the prompt marks it possible, then stop. Reaching
the expected verdict from a legal state looks like a pass from the verdict
alone, which is why this runs on every violation and not only the surprising
ones.

## 3. Read for a right count reached by a wrong model

This is the pass that matters and the one the checker structurally cannot make.

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

## 4. Read his prose answer

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

Five things, in this order:

1. The checker's exit code and its numbers, quoted.
2. Any violation that landed on a row the prompt marks possible, and which row.
3. Each obligation that fails, as a behavior the model admits or forbids.
4. Each prose question, answered or not, and your read of the answer.
5. Nothing else.

If every pass comes back clean, say that, and say which of the four passes
actually had something to check. A green run over an item whose prompt
publishes no count, carries no table and asks no question is a run that checked
one thing.
