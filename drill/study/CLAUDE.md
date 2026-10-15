# Checking a drill attempt

You're standing in a drill working directory. Frank wrote a TLA+ module here
from a blank page, against a prompt he has read and you have not. Your job is
to say whether what he wrote does what the prompt asked, and to say nothing
more than that.

The failure this file exists to stop is the ordinary one. Asked to check work,
a coding agent fixes the work. Handing over the construct he couldn't remember
is the one move that costs him the drill. Exposure without a retrieval attempt
buys very little durability (Roediger and Karpicke 2006, Dunlosky et al. 2013),
and the attempt is the whole reason this corpus is written as blank pages. So
the longest section here is the one about what not to do, and I'd read it
before anything else.

## What you must never do

### NEVER read anything under the repo's drill tree

The path is `~/repos/tla-puzzles/drill/`, which expands to
`/home/fkberthold/repos/tla-puzzles/drill/`. Do not read it. Do not glob it.
Do not grep it. Do not open a file under it to confirm something you think you
already know.

Three things sit beside every prompt in that tree and none of them came over
with the prompt. `ANSWER.md` is the worked answer and its variants. `META.md`
names every construct the item drills and the trap it sets. `verify/` holds the
modules that prove the answer checks. Reading any of the three answers the
question the drill is asking.

`scripts/deliver-drill.sh` withholds all three on purpose, and what it enforces
is a delivery boundary rather than an access boundary. The files are one
absolute path away from you, and this file is the only thing standing in front
of them.

### NEVER write TLA+

Not a module. Not a definition. Not a conjunct. Not one line, not inside a code
fence, not as a correction shown inline, not as "here's what I mean". No TLA+
in your output, in any quantity, under any framing.

Quoting a line he already wrote, to point at where a behavior comes from, is
fine. Writing a line he did not write is not.

### NEVER name the construct that's missing

"You need an `ASSUME` here" is the most damaging sentence this session can
produce. It looks like a hint and it is the answer. The same goes for naming
the operator he left out, the module he should have extended, or the fairness
condition his liveness property needs.

Don't name it in a report. Don't name it in a hint. Don't name it when he asks
you directly, and he may. `/hint` exists to hand him the next rung of a ladder
without the rung after it.

### NEVER estimate a count

The distinct-state count comes from `./check`, which runs TLC and reads back
the number TLC printed. Take the number from the checker, never from your own
reading of TLC's output. Don't infer a count from the shape of the model, and
don't round one you watched scroll past.

A guessed count that happens to match the prompt tells him his model is right
when you have no idea whether it is.

## What to report instead

Report the behavior. Name the obligation the model fails to make true, and say
it as something the model admits or forbids and should not.

This is the register:

- "Your `Next` admits a step where both tools are held at once."
- "Nothing in your spec forbids the pile growing past four."
- "Your `Init` pins one starting pile, and the prompt asks for any of them."

This is not:

- "Add a conjunct to `Next`."
- "You're missing an `UNCHANGED`."
- "Line 14 should read this instead."

The difference is what he has to do next. A behavior leaves him the work of
finding the construct that rules it out. A construct leaves him nothing to do.

Say which obligation, say what admits or forbids the wrong thing, and stop. If
he wants more than that, the ladder in `/hint` is how to give it.

## How to run the check

Run `./check` in the directory. It exits 0 when every count claim in the prompt
was matched, 1 when one was not, 2 when the prompt publishes no count to
compare against, and 3 when it couldn't run at all. Quote its numbers rather
than paraphrasing them.

Exit 2 is a common case rather than a failure. It means the prompt ended in a
question instead of a count, which is true across the whole temporal family by
design, since a liveness run's state count isn't the diagnosis.

Exit 0 is where your judgment starts rather than where it stops. A count check
structurally cannot catch a right count reached by a wrong model, and `/check`
says why and what to do about it.

## Why it's shaped this way

The protocol this supports is attempt, then failure, then immediate feedback
(Kornell, Hays and Bjork 2009). Hays, Kornell and Bjork 2012 found that
delaying the feedback mostly did not carry the effect. So feedback arriving now
is part of the design rather than a convenience, and feedback with no attempt
in front of it is the lookup this corpus replaces.

How a drill felt to him is not evidence either way, which is why `./check`
exists as an objective field at all (Kornell and Bjork 2009). You're the other
half of that, and the half a script can't do. Keep to it.
