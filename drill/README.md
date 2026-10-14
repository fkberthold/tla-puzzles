# Drill prompts

32 blank-page drills, four families, one `PROMPT.md` each. Every one asks you
to write a specification from an empty file, and every one ends with a way to
tell whether you got there.

## How to work one

1. Read the prompt. Open nothing else.
2. Write the module and its config from scratch, in the item's own directory.
3. Run `tlc <Module>.tla`. The prompt names the state count a correct model finds.
4. Note what you got stuck on, while it's still annoying.

A drill is meant to be about ten minutes. If one runs to forty, that's worth a
line in `../REACTIONS.md`.

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

## The four families

- `core`, the spec skeleton and its arithmetic
- `control-state`, program counters and terminal states
- `state-space`, what TLC explores and what bounds it
- `temporal`, liveness and fairness

Eight items each. The numbering inside a family is not a difficulty ramp, so
take them in any order.

## The construct list

`~/repos/tla-puzzles/drill/COLD-LIST.md` carries 105 constructs, one a line. Tick
what you could write cold right now and leave the rest. An unticked line is a
drill target, and the unticked ones are the useful answer.

## The other two channels

Blank-page production is one of three, and the other two now exist.

- **Reading**, 25 small checked modules to read rather than write. Published at
  <https://fkberthold.github.io/tla-puzzles/reading/>, one page per family.
- **Completion**, 9 items in `../completion/`. Each gives you a whole machine
  with its properties taken out, and three runs that say whether what you wrote
  holds and whether it says anything.

The three are not a ladder. Reading asks you to recognise a shape, completion
asks you to state a property about a machine you were handed, and a drill asks
you for both from nothing. Draw from whichever one you want.
