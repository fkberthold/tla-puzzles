---
description: One rung of a hint, and only after there's an attempt in the directory
---

Give one rung of a hint about the attempt in the current directory. `CLAUDE.md`
in the study root governs this command, and the prohibition on naming the
missing construct applies here hardest, because this is the command most likely
to break it.

## The gate comes first

Before you say anything about the item, check that there's an attempt here.

An attempt is a `.tla` file in this directory, ignoring anything matching
`*_TTrace_*` and anything ending `.old`, carrying at least one definition of
its own. A module header with nothing under it isn't an attempt.

If there's no attempt, REFUSE. Say that there's nothing here yet and that the
hint is waiting on a module, and say nothing about the item. Do not describe
the problem. Do not restate the prompt in different words. Do not say which
part of TLA+ the item is about. Then stop.

The refusal isn't pedantry. Feedback with no attempt in front of it is a
lookup, and a lookup is what this corpus is built to replace. A failed attempt
followed by immediate feedback beats reading the answer (Kornell, Hays and
Bjork 2009), and the first half of that is the half this command can check.

## The ladder

Three rungs. Give ONE per invocation, the lowest he hasn't had yet in this
session. If he asks for all three at once, give him the first and say the other
two are there when he wants them.

**Rung 1, which obligation fails.** Name the obligation and say what the model
admits or forbids that it should not. "Your `Next` admits a step where the tube
empties from the wrong end." Nothing about the state, nothing about the fix.

**Rung 2, which part of the state it concerns.** Name the variable or the field
the failing behavior turns on. "It turns on how `tube` changes on a receive."
Still nothing about what the fix looks like.

**Rung 3, the shape of the fix.** Say what kind of thing is missing without
naming it. "The receive step says what the new sequence is but not where it
came from." Or "the property holds in every state your model can reach, so it
isn't being tested."

Never the text of the fix, at any rung. Not the operator's name, not the
keyword, not a conjunct, not a line he could paste. A rung that hands over the
construct has skipped every rung above it and ended the drill.

## When a question arrives with the flag

`./drill --hint "<text>"` passes what he typed through as a `QUESTION:` block,
word for word. Two kinds of question arrive in that block and the ladder only
rations one of them.

A mechanism he's forgotten about TLA+ itself isn't this item's work. "I have
the named value in my module, but don't remember what to put in the cfg file"
asks about a file format. Answering it in full says nothing about what his rule
should assert, so answer it flat and completely and don't spend a rung on it.

A question about what his rule should say is the ladder's business. "What am I
missing in my rule" is that one, and it gets a rung and no more.

The test is one question: would answering in full still leave him the item's
work? If yes, answer flat. If no, ladder it.

This isn't a hole in the prohibition. `NEVER name the construct that's missing`
is about the construct this item drills, the one that makes his rule say what
the prompt asked. A keyword he needs to run the model at all isn't that, and
withholding it costs him the session without teaching him anything. When you
can't tell which kind you're looking at, treat it as the item's content and
ladder it.

Classify before the first word. A one-shot run prints everything at once, so a
flat answer to the second kind is on screen before you'd catch it.

## If he's stuck past rung 3

Say so, and say what he could run to see the behavior for himself. A trace he
reads is a retrieval attempt. A line he pastes is not.

I think the honest move at that point is to tell him `ANSWER.md` exists in the
repo and that reading it is his call to make. Then stop, because reading it for
him and relaying what it says is the same leak with an extra step.
