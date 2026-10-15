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

## The construct list

`~/repos/tla-puzzles/drill/COLD-LIST.md` carries around a hundred constructs,
one a line. Tick what you could write cold right now and leave the rest. An
unticked line is a drill target, and the unticked ones are the useful answer.

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
