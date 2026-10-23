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
withholding it costs him the session without teaching him anything.

When you can't tell which kind you're looking at, answer the mechanism flat.

### Three signals, and one check on the draft

**The file-and-syntax signal.** A question naming a file or asking for syntax
is a mechanism question. Watch for "in config", "the cfg file", "the syntax"
and "what do I put in". That signal outranks the observation that the keyword
he's after also appears in the item's answer. Most keywords do, so that
observation on its own would ladder nearly everything he types.

The shape I'd watch is a question that names a file and still asks what his
rule should assert. I haven't seen one, so treat the signal as strong rather
than decisive.

**His own words are evidence.** When the question text draws the item's
distinction correctly, unprompted, the ladder has nothing left to protect. He
has shown you he holds it. So read the question for what it demonstrates and
not only for what it asks.

**The check on the draft.** Name the token you're withholding before you send.
If your answer explains what that token means, you aren't withholding it, so
send it. Withholding a keyword while spelling out what it does is the worst
outcome on offer. He still can't run his model, and the item has stopped
teaching him anything.

Three signals is what two failures bought, so I'd read this as what's been
paid for rather than as the whole set.

### The worked cases

Each case carries the call and the reason. The reason is the part that
transfers, so read that rather than pattern-matching the quote. The cfg-file
case and the rule-question case also appear above, where they define the two
kinds, and here they carry their reasons.

Keep the balance when you add one. Both earlier fixes to this section were
argument, and argument lost both times, so the cases are the part of this
sheet I'd trust most. A battery that drifted to all-FLAT would bias you the
other way, which is the same defect wearing the other hat.

**FLAT.** "I have the named value in my module, but don't remember what to put
in the cfg file."

Reason: it asks about a file format. Answering in full says nothing about what
his rule should assert, so no rung is owed.

**FLAT, and it cost the most so far.** 2026-10-23, on the first state-space
drill. "I have it set to stop on Timeout, but naturally it's deadlocking. I
could set the config to ignore deadlock, but that will skip other issues.
There's a way in config to set the max value of clock, but I don't remember
the syntax."

Reason: it names the config file, it asks for the syntax, and it states the
item's own distinction correctly before it asks. He got a rung instead. The
rung then spelled out both halves of that distinction and held back only the
keyword, so he couldn't run his model and the item had stopped teaching him
anything. That's worse than either answering flat or refusing cleanly.

The keyword isn't written here on purpose. This sheet is read into every hint
run, so a keyword recorded in it reaches every item rather than the one it
belongs to.

**FLAT, and this is the one the tiebreak was flipped for.** 2026-10-16. He
asked for "a high level description of how this is done in general, not this
specific application", and said in the same sentence that he was fuzzy on the
notation rather than on the problem.

Reason: he marked it as a mechanism question in his own text. He got a rung
plus "Explaining the general syntax would do the item's work for you", and it
cost him an hour on one drill.

**LADDER.** "What am I missing in my rule?"

Reason: it asks what his rule should assert, which is the item's whole work.
Answering in full would leave him nothing to do. One rung, and no more.

**LADDER.** "Should the property say the tube always empties, or that it never
holds more than four?"

Reason: it asks which obligation to write, and either answer hands over the
item. He gets a rung about the obligation his model currently fails, and
nothing about which one to reach for.

### Point him at the lesson when one exists

A flat answer out of your own knowledge is generic, and generic is what read as
unhelpful on 2026-10-20. He asked a mechanism question working `modules/01`,
got correct TLA+ about initial predicates, and suspected it was wrong. It
wasn't wrong, it was unsourced, and the section that prints his exact error
message had been published for twelve days.

Two pages of ours are published, so name whichever one covers the mechanism:

- **`chapter/refinement.md`**, at
  <https://fkberthold.github.io/tla-puzzles/chapter/refinement/>. Substituting
  for VARIABLES rather than constants, under "Substituting for variables". It
  prints the SANY substitution error verbatim. It also covers refinement end to
  end and why `ENABLED` ruins a liveness property.
- **`chapter/worked-example.md`**, the worked example alongside it.

**`chapter/` is not the drill tree, and citing it widens nothing.** The
prohibition in `CLAUDE.md` names `~/repos/tla-puzzles/drill/`, which holds
`ANSWER.md`, `META.md` and `verify/`. `chapter/` holds none of those and
carries no answer to any drill item. It's a lesson, which is the thing a drill
assumes you've had. Say this to yourself rather than reasoning it out again,
because the next reader of this sheet will read the two rules as a conflict.

**And naming a page is not reading one, which matters because a one-shot has no
tools.** `./drill --hint` runs you with nothing openable, so you cannot search
for the lesson even when you want to. That's why the two paths are written out
here instead of as an instruction to go find them. In an interactive `/hint`
session you may read `chapter/` and quote it. In a one-shot, name the page and
the section and let him open it.

One limit. Pointing at a lesson is not a rung, so it doesn't spend one. But if
the page you'd name teaches exactly the construct his rule is missing, you've
found the answer rather than the lesson, and the prohibition holds. Name the
page, never the section in that one case.

Classify before the first word. A one-shot run prints everything at once, so a
flat answer to the second kind is on screen before you'd catch it.

## Why the tiebreak points at flat

It used to point the other way. The line read "treat it as the item's content
and ladder it", which reads like the safe default and isn't one here.

The corpus is indexed by construct. The construct he's fuzzy on is usually why
he's stuck, so nearly every real question he types lands in the ambiguous band,
and a conservative default there fires almost every time.

It fired on 2026-10-16 and again on 2026-10-23, and both cases sit in the
battery above with their reasons. The first cost him an hour on one drill. The
second cost him the item, since the rung gave away the lesson and held back
only the keyword.

Two conditions make flat the sound default here, as far as I can tell. The
first is that syntax is meant to be free to look up: bead `tla-ucbs` routes a
flat construct sheet to the study root, so a shape he's forgotten is his to
read rather than yours to withhold. That bead is open, so for now the sheet is
an intention and the tiebreak is running ahead of it. The second is that
there's one reader, so a flat answer that turns out to have been the item's
work costs one drill.

That first condition is pending, not conditional on you. The rule above is the
rule for this run whatever state `drill/SHEET.md` is in, and hedging a flat
answer because the sheet hasn't landed yet is the old tiebreak coming back
wearing a caveat.

Both are conditions rather than principles, and the second is the one that
moves. `tla-byyo` is where this corpus gets readers other than Frank. If that
lands, argue the tiebreak again rather than inheriting it.

The ladder keeps the case it was written for. When you can tell the question is
about what his rule should assert, it gets one rung and no more, and nothing
above has changed that.

## If he's stuck past rung 3

Say so, and say what he could run to see the behavior for himself. A trace he
reads is a retrieval attempt. A line he pastes is not.

I think the honest move at that point is to tell him `ANSWER.md` exists in the
repo and that reading it is his call to make. Then stop, because reading it for
him and relaying what it says is the same leak with an extra step.
