# Drill prompts

Blank-page drills, one `PROMPT.md` per item. Every one asks you to write a
specification from an empty file, and every one ends with a way to tell whether
you got there.

## How to work one

Run `./drill` at the root of this tree. It picks the next item off the queue,
prints the prompt, and creates a working directory for it under
`~/Study/tla-drills/<slug>/`. That's where you write the module, not here.

1. Read the prompt. Open nothing else.
2. Write the module and its config from scratch, in the working directory.
3. Run `./check` there. It compares what TLC found against what the prompt claims.
4. Note what you got stuck on, while it's still annoying.

Most prompts name the state count a correct model finds, and `./check` is what
compares it. The rest end in a question instead, and the temporal items end in
one by design, because a liveness run's state count isn't the diagnosis. A
prompt with no count makes `./check` exit 2 and say UNCHECKED, which is a true
report rather than a failure.

A drill is meant to be about ten minutes. If one runs to forty, that's worth a
line in `../REACTIONS.md`.

## Asking Claude to check it

`~/Study/tla-drills/CLAUDE.md` configures a session for exactly this. Start
Claude in the study root and it has two commands:

- `/check`, which runs `./check` and then reads for what a count can't catch
- `/hint`, which gives one rung of a ladder, and refuses before there's an attempt

That configuration is a refusal contract before it's anything else. It forbids
the session from reading this repo's drill tree, from writing TLA+ for you in
any quantity, and from naming the construct you left out. What it reports is
which obligation your model fails to make true, as a behavior the model admits
or forbids. Finding the construct that rules the behavior out stays yours.

## What's missing, on purpose

Three things sit beside every prompt in the repo, and none of them came over.

- `ANSWER.md`, the worked answer and its variants
- `META.md`, the constructs the item drills, and its trap
- `verify/`, the modules that prove the answer checks

`META.md` is the one worth knowing about. It names every construct the item
exercises, so reading it answers the question the drill is asking. That's why
it stayed behind.

All three are at `~/repos/tla-puzzles/drill/<family>/<item>/` when you want
them. I'd read `ANSWER.md` after an attempt rather than during one, though
that's your call to make.

## The families

- `core`, the spec skeleton and its arithmetic
- `control-state`, program counters and terminal states
- `functions-records`, functions, records and their domains
- `modules`, instantiation, substitution and what crosses a module boundary
- `sequences`, order, indexing and the operators over it
- `sets`, set construction, filters and quantifiers
- `state-space`, what TLC explores and what bounds it
- `temporal`, liveness and fairness

The numbering inside a family is not a difficulty ramp, so take them in any
order. `./drill` has a queue if you'd rather not choose.

## What `state-space` is about

This family reads differently from the other seven, and the difference used to
be invisible. Three worked items weren't enough to say what it was about,
which is the defect this section fixes.

**The subject is the config file, not the module.** The eight items drill the
knobs you set outside the spec. Those are `CONSTANT` and the `ASSUME` that
constrains it, the model values a constant gets instantiated over, a set of
them, a symmetry claim across that set, whether deadlock gets checked, the
operator you name as an invariant, and the one you name as a property. Each
knob has its own way of lying to you, and catching the lie is the drill.

State blowup is not the subject. It motivates about three of the eight, so I
think it's the loudest thing you meet here rather than the thing you're
learning.

**A knob only shows up as a difference between two runs.** You can't see a
symmetry claim by reading a system, because the system is the same either
way. You see it when two runs over one unchanged system report different
state counts. So these items hand you prior runs instead of a world to model.

That's also why they run long. The family's median prompt is 431 words
against 347 for `modules`, the next longest, and 165 for `core`. It holds all
five of the longest prompts in the corpus. You're reading two runs plus a
system. A long one here isn't a harder one.

Those three numbers read 387, 346 and 162 until 2026-11-04, and the 387 was
wrong on the day it was written. It's item 07's own word count, so I think
somebody read along a row instead of down a column. The real median was 420
before item 07's rewrite moved it to 431, which also took the family from
four of the five longest prompts to all five. Counted with `wc -w` over
`drill/*/PROMPT.md`, 64 files, eight per family.

The other two moved by a point and by three, which I'd put down to a
different counting method rather than an error. Only the 387 is off by a
distance no method explains.

**Every item in the family goes in four moves.**

1. **The model.** What the system is, present tense, no history.
2. **The runs.** A table, one row per configuration difference. Each row
   names its difference in your terms and reports what the run found.
3. **The claim under test.** Which row misleads, or what the rows disagree
   about, stated as a given rather than recounted.
4. **The questions.** These diagnose. The first three moves don't.

Move 2 had a presupposition it never said out loud, and item 04 is where it
shows. A table works when the difference between the runs is handed to you
and the consequence is the puzzle. That's the other seven items here, and
every left column says so: `workers` 2 through 6, `cap on the clock` 3
through 48, "counter cut at 3", "named as the values that can be swapped".
04 runs the other way. Both of its runs use one config file, the verdicts
differ, and finding what differed is question 1. Name that difference in a
left column and you've printed the answer. Leave the column blank and the
table does nothing a sentence doesn't do better.

So 04 has no table and is the shortest prompt in the family, and I don't
think that's drift. A knob somebody tells you about goes in a table, because
the left column is where the telling happens. A knob you have to go and find
can't. `sequences/03` does the same thing in another family, so the
withheld-difference item is a shape rather than a one-off.

**And the prompts promise you five things.**

- No first-person narrator. Nobody says "I killed the run".
- A colleague appears as a claim to evaluate, or as a run that differed.
- Any global setting the published verdicts rest on is stated once.
- What you reproduce is counted in runs, never in files.
- Every figure you're asked to reproduce is reachable from the prompt.

The first promise is the one with a history. Six of these eight prompts had a
first-person narrator and the other 58 in the corpus had none, so this was
one family's local habit rather than a house style. A narrator is how
provenance for a table gets supplied, which I suspect is why it grew here and
nowhere else. `harness/drill-gate.sh` fails on a first-person singular in any
prompt now, and the five that are left are waived by name until each gets
rewritten.

Two promises were written narrower than the corpus and got widened on
2026-11-04, after 04, 07 and 08 were read against them.

The second one said a colleague may appear only as a claim to evaluate, and
cited `sequences/03` for it. `sequences/03` doesn't do that. Its colleague
wrote the same library, got a different state count, and both of you are
right, so you work out what the two of you chose differently. That's a run
that differed, not a claim, and 04 does the same thing with a deadlock
verdict. `sets/01` is the claim device: somebody says a thing and you add it
as a third check. Two devices, and the promise had them collapsed into one.
The withheld-difference item needs the second, because nothing in its files
tells its runs apart and the runner is all that's left to name them by.

The fifth said every published figure is reachable by a run the prompt asks
for. Item 08 publishes 405,673,796 distinct states at depth 13 in 64 minutes
and you aren't meant to go near it. It's cited from `sources/README.md:110`,
where a 619-line reference spec took that long, and question 4 asks what the
number says about that spec. A figure you reason about is a different thing
from a figure you reproduce, and the promise now covers the second kind only.

The fourth promise is about routes. A file count is route-dependent, and item
03 is the worked case. The constant route needs five configs and the
module-fork route needs four, and the prompt used to publish a count that
only one route hit.

**One trap, if you ever write one of these.** Anchoring an item on its knob
is structural and never nominal. The gate's telegraph check forbids a prompt
from showing the token of any construct the item drills, so a prompt may not
say "this one is about `VIEW`". Naming the keyword is the one move that's off
the table, and it's the first one an author reaches for. A table is the usual
way to make a knob visible: two runs that differ in one setting, with the
setting named in the reader's terms. Item 04 is the case where that route is
closed, for the reason above.

## Where the lesson is, when a family has one

Step 1 above says to open nothing else, and it means nothing else about the
item in front of you. A lesson on the technique is a different thing, and two
of them are published.

- **`modules`** rests on substituting for VARIABLES rather than constants, and
  that is taught at <https://fkberthold.github.io/tla-puzzles/chapter/refinement/>
  under "Substituting for variables". Read it before the family rather than
  during an item. It prints the SANY substitution error verbatim, so if you
  have met that error the section is where it is explained.
- **`modules` and `temporal`** both reach refinement, and the same page covers
  it end to end, including why `ENABLED` ruins a liveness property.

The other six families have no published lesson of their own yet. The twelve
chapter cheat sheets are the nearest thing, and `SHEET.md` beside this file is
their flat form.

Worth saying why this section exists. The refinement chapter has been published
since 2026-10-08 and nothing under this tree pointed at it, so a drill built on
that technique read as a drill with no lesson behind it. That was reported on
2026-10-20 as lacking an actual lesson on the thing being drilled, and the
lesson existed the whole time.

## The construct list and the sheet

Two files sit beside this one, and they read in the same order as a third that
stays in the repo. The `K` id is the join.

- `COLD-LIST.md`, around a hundred constructs, one a line, with a box to tick
- `SHEET.md`, the syntax shape of each one, flat, from the twelve cheat sheets

Start with the cold list. Tick what you could write cold right now and leave
the rest. An unticked line is a drill target, and the unticked ones are the
useful answer.

When a drill stops you on a construct you know the name of, `SHEET.md` has its
shape. It names no item, so reading it gives nothing away about the drill in
front of you.

Your ticks are safe. `COLD-LIST.md` lands once and no later delivery writes
over it, so a pass you make here stays made. The cost is that new rows don't
reach you either. A delivery that finds a cold list already here says so and
names the path. The repo's copy is yours to take when you want the new rows.

`SHEET.md` is the other way round. Every delivery refreshes it, because it's
generated and you never edit it.

The third file is `INVENTORY.md`, which says which drill and reading items
reach each construct. It stays at `~/repos/tla-puzzles/drill/INVENTORY.md` and
no delivery brings it here. Its field 8 is item slugs, so inverting it on a
slug gives you every construct that item drills. That's what `META.md` says,
and why `META.md` stayed behind. I'd keep it for between drills.

## The other two channels

Blank-page production is one of three, and the other two now exist.

- **Reading**, small checked modules to read rather than write. Published at
  <https://fkberthold.github.io/tla-puzzles/reading/>, one page per family.
- **Completion**, in `../completion/`. Each item gives you a whole machine with
  its properties taken out, and three runs that say whether what you wrote
  holds and whether it says anything.

The three are not a ladder. Reading asks you to recognize a shape, completion
asks you to state a property about a machine you were handed, and a drill asks
you for both from nothing. Draw from whichever one you want.
