---
description: Check the drill attempt in this directory against the prompt's own claims
---

Check the attempt in the current directory. `CLAUDE.md` in the study root is a
refusal contract and it governs every step below. It loads by itself from here,
and the part about never writing TLA+ is worth rereading before you report
anything.

Work in five passes. Two of them hand you a script's output. The other three
are the reason you're here, because a script can't do any of them.

Two ways in, and they differ in what you can reach rather than in what to do.
A typed `/check` has its tools. A `./drill --check` one-shot has none at all,
and this file arrives on its stdin because of that. Where a pass below tells
you to open something, the one-shot's copy is already in the prompt, so look
there rather than reaching for the path.

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
- no row at all, so the table settles nothing and pass 4 carries the weight

The middle one is a report about the rule rather than about the model. Say
which row it is and say that the prompt marks it possible, then stop. Reaching
the expected verdict from a legal state looks like a pass from the verdict
alone, which is why this runs on every violation and not only the surprising
ones.

## 3. Read the refutation table

A check run may hand you a block headed `REFUTATION`. It holds one TLC exit
code per pair of your obligations and the machines this item ships to be
wrong about something. The machines are numbered and nothing else about them
is said, on purpose, so there is nothing in the block to hand over.

If the block says the table was not produced, say that in one line and make no
claim from it. An absent table is a fact about this box or about this item, and
never a fact about his obligations. A typed session gets no block at all, so
this pass has nothing to work on and the right report is that it did not run.

What a cell means:

- 0, that obligation said nothing against that machine
- 12 or 13, it refuted that machine
- 150 or 255, the probe could not substitute, so nothing was measured
- anything else, the run did not get off the ground, so nothing was measured
  there either. A whole column of one value that is not in this list is a
  broken toolchain rather than eight findings.

Read the first machine's column first. It is the reference, and a cell there
that refutes is the one reading worth leading with, because it says one of his
obligations rejects the machine this item holds up as correct.

### What silence does not mean

A 0 is silent against THAT machine and nothing more. This is where a reading
of this table goes wrong, so it is worth being blunt about.

A type invariant reading 0 against every machine is correct rather than weak.
It is not about the rule the item drills, so a machine that breaks that rule
should leave it true, and a type invariant that refuted one would be the thing
worth reporting.

Most cells in a healthy table are 0. Measured on one item: eight obligations
against three machines, and six of the eight were silent on the second
machine. Two refuted it, and three machines is how you can tell those two
apart.

So never count refutations and never report a total. A count calls a correct
obligation a failure, which is the error the prose reading of this made and
the reason the table exists at all.

A column with no refutation in it is worth saying out loud, and worth saying
as a question rather than as a verdict. Nothing he wrote rejects that machine.
Whether the prompt asked him to is his to say, and if you name a behavior,
name the one that machine admits, never the construct that would forbid it.

## 4. Read for a right count reached by a wrong model

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

## 5. Read his prose answer

Many prompts end in a question rather than a count, and the temporal family
ends in one by design. Those answers are in whatever file or comment he wrote
them in, so look for them before you conclude the item has nothing to grade.

Read the prompt to find the question. In a one-shot it's already in front of
you, under its own `PROMPT.md` label. In a typed session it's at
`~/tla-practice/drill/*/<slug>/PROMPT.md`, where `<slug>` is this directory's
name, and the delivered prompt tree is the one place you're allowed to read.
Then judge the answer on whether it's true of the model he actually wrote, not
on whether it matches an answer you have in mind.

A question he didn't answer is worth saying out loud. A question he answered
wrongly gets the same treatment as a failed obligation: name what his model
does, and leave the construct to him.

## What to hand back

Six things, in this order:

1. The checker's exit code and its numbers, quoted.
2. Any violation that landed on a row the prompt marks possible, and which row.
3. The refutation table's reading: any machine column no obligation refuted, or
   one line saying the table was not produced. Never a count of refutations.
4. Each obligation that fails, as a behavior the model admits or forbids.
5. Each prose question, answered or not, and your read of the answer.
6. Nothing else.

If every pass comes back clean, say that, and say which of the five passes
actually had something to check. A green run over an item whose prompt
publishes no count, carries no table, ships no machine and asks no question is
a run that checked one thing.
