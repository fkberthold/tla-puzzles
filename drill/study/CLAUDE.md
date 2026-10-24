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

The distinct-state count comes from the checker, which runs TLC and reads back
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

## When the prompt marks a state possible

Some prompts carry a table of states with a `possible?` column, and every row
of it is a constraint on the model rather than a note about it. A row marked
yes has to be reachable. A row marked no is what the rule is there to forbid.
Nothing in the checker reads that table, so if you don't make the comparison
nobody does.

So when a module violated, take the state it stopped on and find it in the
table before you say anything about the rule.

A violation landing on a row marked yes is a report about the rule, not about
the model. The rule forbids something the prompt requires, and the model was
right to reach the state. Name the row and say that the prompt marks it
possible. "Your rule forbids the row where both operators have looked and
neither has acted, which the prompt marks possible" names no construct and
leaves him the whole fix.

A violation landing on a row marked no is the ordinary case. The rule caught
what it was written to catch, and some items ask for exactly that verdict.

This runs on every violation and not only the ones that surprised you. An item
can ask for a violation and get it from a legal state, and that looks like a
pass from the verdict alone. I think it's the easiest defect in the corpus to
miss, which is why the step is here rather than in the register above.

## How to run the check

The checker sits at the study root. You're standing in a slug directory under
it, so the command is `../check` and a plain `./check` reports that no such
file exists. Frank's session hit that on 2026-10-14 and had to work the path
out for itself.

He also has a shorter route from the shell, `./drill --check` at the root of
the practice tree, which runs the checker for you. The section on the two modes
says what that route looks like from where you're sitting.

The checker exits 0 when every count claim in the prompt was matched, 1 when
one was not, 2 when the prompt publishes no count to compare against, and 3
when it couldn't run at all. Quote its numbers rather than paraphrasing them.

Exit 2 is a common case rather than a failure. It means the prompt ended in a
question instead of a count, which is true across the whole temporal family by
design, since a liveness run's state count isn't the diagnosis.

Exit 0 is where your judgment starts rather than where it stops. A count check
structurally cannot catch a right count reached by a wrong model, and `/check`
says why and what to do about it.

## The rubric, and the three dimensions the checker prints

Exit 0 means the count matched and nothing more, which the section above
already says. The rubric is what gives your reading a fixed point without
naming a single one of Frank's variables. Each item declares what a reasonable
model of it does, and the checker compares his run against that declaration.

Nothing in a rubric names a construct, a variable or a type. That is the whole
reason it exists. `harness/refute.sh` needs his names to match because it pairs
his module against the item's, so it can only work on the items where the
names happen to coincide. A rubric judges his run on its own terms, so every
representation he might reach for stays valid and the binding question stops
being asked.

### The four fields

```
## Rubric

- runs: yes
- fault: none
- states: 9..49
- obligations: 3
```

**runs**: `yes` or `no`. Whether TLC gets off the ground at all.

**fault**: `none`, `invariant`, `property` or `deadlock`. What fires.

**states**: `<low>..<high>`, inclusive. The envelope the distinct count sits in.

**obligations**: a non-negative integer. How many separately named requirements.

`runs` separates a mechanical failure from a modeling one, and those two want
different sentences from you. On an item declaring `runs: yes`, an rc of 150,
151, 255, 75, 76 or 10 means the attempt never started, so there is nothing to
say yet about his rules. Read it from the log rather than from the exit code,
which is bd memory `a-tlc-exit-code-does-not-predict-whether`.

`fault` is the dimension that survives without binding. A declared `fault: none`
plus his own obligations rejects a model whose rules are wrong, whatever he
called the state. It is also what makes an item checkable when it publishes no
count, which is every one of the eight control-state items.

`states` catches the two failures that don't depend on how the state is spelled.
Too small means a variable never moves, `Init` is over-constrained, or a guard
is never true. Too big means something is unbounded, a domain is too wide, or a
guard is missing.

`obligations` counts the item's separately named requirements and leaves the
type layer out. A type invariant is bookkeeping rather than a requirement, and
not every reasonable model writes one. Bundling three requirements under one
name throws away the label TLC would have printed, which is Lamport section
14.5.3 p.259 and `.claude/rules/tla-practice.md` section 1.

### What the checker prints, and what it still refuses to decide

```
rubric=meta runs=yes fault=none states=9..49 obligations=3
module=Pools config=pools.cfg rc=0 distinct=49 claimed=9,49 count=MATCH run=CLEAN invariant=- rubric-runs=MET rubric-fault=MET rubric-states=IN
```

The first line is the declaration, read back so you can see what the comparison
was against. The three `rubric-` fields on each module line are the comparison.

- `rubric-runs` is `MET`, `UNMET` or `-`
- `rubric-fault` is `MET`, `UNMET`, `UNKNOWN` or `-`
- `rubric-states` is `IN`, `OUT` or `-`

`UNKNOWN` on the fault dimension is the honest answer when the run errored
before any obligation was evaluated. A `-` on any of them means the item ships
no rubric, so there was no declaration to compare against.

**None of the three moves the exit code.** `count=` still owns it, for the
reason the two-dimension section gives. A rubric verdict is a report in the
sense `run=` is, and folding one into the exit would be the checker ruling on
intent it can't see.

### Where it comes from, and the prohibition it does not touch

The checker looks in `PROMPT.md` first, then in the item's `META.md` under
`$DRILL_REPO_ROOT`. It prints `rubric=prompt`, `rubric=meta` or `rubric=none`
so you can tell which. An unset `DRILL_REPO_ROOT` is `rubric=none` and not a
failure, the same way a missing refutation table is.

**The checker reads `META.md`. You still do not.** The first prohibition in this
file stands exactly where it was. Take the three verdicts off the checker's
output and quote them. Reading the file yourself hands you the fault list and
both envelope reasons, which are withheld from the prompt on purpose, and an
item's fault list names the break that is coming.

### What the rubric does not yet establish

8 of the 64 items carry a rubric, all of them in `sets`. On those eight the
`states` envelope is the lowest and highest distinct count among the item's own
rc 0 machines, so it was read off the `## Verify` table rather than reasoned
from what a model of the item has to do. Two consequences, and I think the
second is the one worth holding on to.

The two `-because` lines and the `### Faults you should catch` list are owed by
bead `tla-sqym.3`. Until they land, a count outside the envelope tells you the
direction he went and nothing about what that direction usually means.

An envelope built from the counts it would be tested against can't be shown to
be fair by those counts. `harness/drill-gate.sh` prints the soundness power it
had, per item and in total, which is the number of cases where an item ships
two correct models whose distinct counts differ. Read that number before you
read a correct model's count as evidence the envelope admits every reasonable
one.

## The two modes a one-shot arrives in

`./drill --check` and `./drill --hint` run you with no tools at all. Everything
you would have opened arrives on stdin instead: the checker's output, the
module he wrote, and the prompt. You can't reach `ANSWER.md`, `META.md` or
`verify/` because you can't reach anything.

That doesn't retire the first prohibition above. An interactive `/check`
session has every tool it ever had, and in that session this file is the only
thing standing in front of those three. The one-shot narrows the opportunity
and leaves the rule where it was.

The runner says which mode you're in on a line of its own, and the two want
different output.

**`MODE: check`**: the whole report. Work the passes in `/check` in the order
they're written, and hand back everything its last section asks for. The
runner cats `/check`'s own file into a check prompt, so the passes and that
last section are in front of you rather than at a path you can't open.

**`MODE: hint`**: one rung, with the gate in `/hint` first. A one-shot carries
no history of the session, so the rung is the first one unless what he typed
says he's had it. Say the other two are there when he wants them.

A `MODE: hint` run may also carry a `QUESTION:` block holding what Frank typed
after the flag, word for word. Two kinds of question arrive in that block and
the ladder only rations one of them.

A mechanism he's forgotten about TLA+ itself is not this item's work. Answer it
flat and in full. A question about what his rule should assert is the ladder's
business and gets one rung.

One question sorts them: would answering in full still leave him the item's
work? If yes, answer flat, with no rung and no coyness. If no, ladder it. When
you can't tell which kind it is, answer the mechanism flat.

The runner cats `/hint`'s own file into a hint prompt. So the worked cases and
the argument for that tiebreak arrive with the question, rather than sitting at
a path the one-shot can't open.

They sat at that path until 2026-10-16. A hint classified on this summary alone
laddered a question Frank had marked as a mechanism question in his own text.
That cost him an hour.

`/check`'s file sat there a day longer, and what it risked is quieter. A check
working from the four sentences above it reports a clean run without making the
pass that catches a right count reached by a wrong model, and a report with a
pass missing from it reads like a report with nothing to say.

None of this touches the third prohibition above. The construct that's missing
from his rule stays unnamed whatever he asks, and a flat answer is about
notation he needs to run the model at all.

Classify before the first word. A one-shot has printed everything before he
can look away, so there's no walking a flat answer back.

## Why it's shaped this way

The protocol this supports is attempt, then failure, then immediate feedback
(Kornell, Hays and Bjork 2009). Hays, Kornell and Bjork 2012 found that
delaying the feedback mostly did not carry the effect. So feedback arriving now
is part of the design rather than a convenience, and feedback with no attempt
in front of it is the lookup this corpus replaces.

How a drill felt to him is not evidence either way, which is why the checker
exists as an objective field at all (Kornell and Bjork 2009). You're the other
half of that, and the half a script can't do. Keep to it.
