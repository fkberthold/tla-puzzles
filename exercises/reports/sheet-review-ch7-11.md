# Cross-sheet review: cheat sheets for learntla core ch.7 to ch.11

Bead `tla-jb7f.13`. Review only, no repairs.

Source of truth is `hwayne/learntla-v2` at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`.
The clone's tip was already that commit, so no explicit checkout was needed.
Chapter numbering follows the toctree in `docs/core/index.rst:54` with `setup` as 1.
That gives ch7 `nondeterminism.rst`, ch8 `concurrency.rst`, ch9 `temporal-logic.rst`,
ch10 `advanced-operators.rst`, ch11 `action-properties.rst`.

`docs/core/advanced/procedures.rst` is chapter-8 content. It sits in no toctree and
reaches the reader only through the `.. include::` at `concurrency.rst:221`, so its
`procedure` label lands on the concurrency page.

Five checks ran: template completeness, construct boundaries across all ten sheets,
the ch.5 symmetry ruling the ch.8 author asked for, anchor resolution, and a syntax
spot-check on the three most load-bearing constructs per sheet.

## Verdicts

- ch07 (`exercises/ch07/CHEATSHEET.md`): PASS
- ch08 (`exercises/ch08/CHEATSHEET.md`): SEND BACK
- ch09 (`exercises/ch09/CHEATSHEET.md`): PASS
- ch10 (`exercises/ch10/CHEATSHEET.md`): PASS
- ch11 (`exercises/ch11/CHEATSHEET.md`): PASS

One send-back out of five, against four out of five in wave 1. The single defect is
one anchor on ch08 that points at a Sphinx rubric instead of a heading. Every other
anchor in the wave resolves, every syntax shape I checked held, and the boundary
partition came out with no duplicates across all 80 constructs.

## ch07 findings

No defects. Two notes.

**NOTE, two constructs is the right count.** This is the thinnest sheet in the wave and
I checked whether it was under-claiming. The chapter carries exactly two index
directives, `nondeterminism.rst:19` and `:69`, and its summary names exactly two
constructs at `nondeterminism.rst:240` and `:241`. The sheet claims both. Nothing is
missing.

**NOTE, `macro` and `assert` go uncited in the boundary notes.** Both appear in the
chapter's own examples, `macro` at `nondeterminism.rst:120` and `assert FALSE` at
`:162`, and both belong to ch3. The sheet has a boundary note for struct set at
`exercises/ch07/CHEATSHEET.md:33` and none for these two. I don't think it matters for
an exercise author, since ch3 already claims them, and I'm recording it because the
sheet was thorough enough elsewhere that the gap looks deliberate.

All four boundary notes check out. The quoted line at
`exercises/ch07/CHEATSHEET.md:30` matches `nondeterminism.rst:17` word for word, and
the three label citations land on `concurrency.rst:207`, `concurrency.rst:187` and
`functions.rst:35`.

## ch08 findings

**DEFECT, `concurrency § pc` is not a heading.** The entry at
`exercises/ch08/CHEATSHEET.md:17` uses the section-heading anchor form. There's no `pc`
heading in `concurrency.rst`. What's there is `.. rubric:: pc` at `concurrency.rst:95`,
and a Sphinx rubric renders as bold text with no link target. The eight real headings
in that file are Concurrency, Processes, local variables, Process Sets, await,
Example: Threads, Finding More Invariants, and Summary. The teaching itself is at
`concurrency.rst:97` and it's correct, so this is an anchor repair and not a content
one. The nearest target that resolves is `concurrency#process`, the label at
`concurrency.rst:13`, which is where the `pc` rubric's own section starts.

**NOTE, the `procedure` label lives in another file.** Three entries cite
`concurrency#procedure`, at `exercises/ch08/CHEATSHEET.md:41`, `:45` and `:49`. The
literal `.. _procedure:` line is at `advanced/procedures.rst:8`, not in
`concurrency.rst`. It resolves, because the include at `concurrency.rst:221` splices the
file in before Sphinx parses labels and `procedures.rst` is in no toctree. Worth
knowing if you write a checker that opens the named file and greps it.

**NOTE, `return` has its own target and doesn't use it.** `advanced/procedures.rst:31`
carries `.. index:: return` with `:name: return`, so `concurrency#return` would resolve
too. The sheet sends `return` to `concurrency#procedure` at
`exercises/ch08/CHEATSHEET.md:49`. Same shape as the wave-1 note about three ch06
entries sharing `functions#function`. Correct, and coarser than it needs to be.

**NOTE, no boundary note for action properties.** The liveness note at
`exercises/ch08/CHEATSHEET.md:62` cites `concurrency.rst:313-317`. Line 315 and line 317
are the liveness material and the pointer to ch9. Line 313 is a different forward
reference: "violations wouldn't be invalid states, but rather invalid transitions
between valid states", which is ch11's subject. So the range holds one line that
belongs to a boundary note the sheet doesn't have. I'd add a ch11 note and trim the
citation to `:315-317`.

The three load-bearing shapes I checked all held, and they held against the fixture
specs rather than the prose, which is where ch8's syntax actually lives.
`process writer = 1` against `docs/specs/reader_writer/1/reader_writer.tla:10`,
`process writer \in Writers` against
`docs/specs/reader_writer/rw_many_1/reader_writer.tla:11`, and `await queue = <<>>;`
against `docs/specs/reader_writer/rw_await_1/reader_writer.tla:14`. The procedure block
at `exercises/ch08/CHEATSHEET.md:40` matches `advanced/procedures.rst:21-29` line for
line, and the `call` rule at `:44` matches `advanced/procedures.rst:36`.

## ch09 findings

No defects. Two notes.

**NOTE, three operators share one anchor.** `temporal-logic#eventually` carries `<>`,
`<>[]` and `[]<>`, at `exercises/ch09/CHEATSHEET.md:29`, `:33` and `:37`. The label is at
`temporal-logic.rst:156`. `<>[]` has an index directive and no label at
`temporal-logic.rst:190`, and `[]<>` is taught in a tip at `temporal-logic.rst:232`.
Both sit inside the eventually section, so the anchor is the nearest thing that
resolves. Same call the ch06 author made and I think it's the right one.

**NOTE, stuttering isn't listed as a construct.** It has its own index name at
`temporal-logic.rst:99` and it's first taught here. The sheet carries it as a theme at
`exercises/ch09/CHEATSHEET.md:47` instead. It's a property of the semantics rather than
syntax, so I'd leave it, and I'm logging it because it's the one named target in this
chapter that no entry claims.

The three shapes I checked held. `[]P` against `temporal-logic.rst:43`, `fair process`
against `docs/specs/liveness/4/orchestrator.tla:17`, and `fair+` plus the `Label:+`
action form against `docs/specs/threads/strong_fairness_2/threads.tla:16` and
`temporal-logic.rst:135`.

The boundary note at `exercises/ch09/CHEATSHEET.md:56` makes a "not used" claim about
five ch10 constructs. I checked it. `CASE`, `RECURSIVE` and `LAMBDA` appear zero times
in `temporal-logic.rst`. The claim holds.

## ch10 findings

No defects, no notes worth a repair. This is the cleanest sheet in the wave.

All seven anchors resolve. Two through labels, `advanced-operators.rst:24` and `:153`,
and five through headings at `:90`, `:117` and `:134`. All five heading strings match
the source text character for character.

The three shapes I checked held. `RECURSIVE Op(_)` against `advanced-operators.rst:33`
and the arity rule at `:35`, `LAMBDA x: expr` against `advanced-operators.rst:109`, and
the bracket function definition against `advanced-operators.rst:141-145`, where the
source gives both forms side by side.

One theme is worth calling out as checked rather than assumed, because it's the kind of
claim that usually turns out to be folklore. `exercises/ch10/CHEATSHEET.md:42` says TLC
always picks the lowest value when several elements satisfy a `CHOOSE` predicate. The
source says the same at `advanced-operators.rst:67`, and it's load-bearing for the
`SetToSeq` result printed at `advanced-operators.rst:79`.

## ch11 findings

No defects. Two notes.

**NOTE, template boilerplate survives.** The line "What this chapter does NOT cover,
because a neighbouring chapter does." sits at `exercises/ch11/CHEATSHEET.md:34`. It came
from `exercises/templates/CHEATSHEET.md:28`. Eight of the ten sheets dropped it. ch05 is
the other one that kept it, and wave 1 logged the same note.

**NOTE, `UNCHANGED` is claimed by nobody in ch.2 to ch.11.** The source carries
`.. index:: UNCHANGED` at `action-properties.rst:92`, so a mechanical sweep of index
directives will flag it as a ch11 orphan. I don't think it is one. The label
`.. _UNCHANGED:` is at `tla.rst:103`, the multi-variable form at `tla.rst:126`, and ch11
uses `UNCHANGED x` at `action-properties.rst:94` without ever defining it. So the
boundary note at `exercises/ch11/CHEATSHEET.md:38` routes it correctly. The cost is that
`[P]_x` expands, on this sheet, into a term the sheet won't explain. An author who wants
the expansion has to wait for the ch12 sheet.

The three shapes I checked held. `Name == [][action]_vars` with `PROPERTY` and not
`INVARIANT` against `action-properties.rst:42` and the formula at `:77`, `x'` against
`action-properties.rst:88`, and `[P]_x` as `P \/ UNCHANGED x` against
`action-properties.rst:187`.

Both ch12 boundary notes are right, which I checked because they're the only forward
references in the wave that point past the ten sheets. The formal definition of "action"
is at `tla.rst:72`. `UNCHANGED <<x, y, z>>` is at `tla.rst:126`.

## Ruling: the ch05 symmetry boundary note

The ch.8 author flagged this and the flag is good. Here's what I found.

`exercises/ch05/CHEATSHEET.md:45` says symmetry sets' payoff for concurrent systems is
covered in chapter 8. A case-insensitive search for `symmetr` across `concurrency.rst`
and `advanced/procedures.rst` returns zero matches. Chapter 8 doesn't mention symmetry
at all, so the note sends the reader somewhere the topic isn't.

The payoff isn't deferred anywhere in `core`. Chapter 5 teaches it itself.
`constants.rst:125` gives the state-count drop from the optimization, and
`constants.rst:142` gives the warning that it doesn't always pay off. Those two lines are
the payoff, and they're already on the same page as the boundary note.

Symmetry appears once more in `core`, at `temporal-logic.rst:284`, and it's a
restriction rather than a payoff: you can't use symmetry sets with liveness properties.
That's chapter 9.

The concurrency payoff the note is reaching for does exist. It's outside `core`, at
`docs/topics/optimization.rst:129-132`, where making a `Workers` process set into a
symmetry set cuts the state space by a factor of about `n!`. That page is in `topics`,
which the ten sheets don't cover.

So the note is wrong on the chapter and wrong on the premise that anything was deferred.
It's a NOTE rather than a DEFECT, since nothing an author writes from ch05 breaks
because of it. The reader just hunts through chapter 8 for a word that isn't there.

Proposed one-line correction, to replace `exercises/ch05/CHEATSHEET.md:45`:

```
- Symmetry sets' payoff for concurrent systems is covered in `topics/optimization.rst` instead, outside `core`. Chapter `09` covers the one `core` follow-up, that symmetry sets can't be used with liveness properties.
```

That runs long for a boundary line. If you'd rather keep it to one clause, drop the
first sentence and keep the ch09 half, which is the only forward reference in `core`
that's real.

## Cross-sheet summary

- Constructs claimed across ch.2 to ch.11, total: 80
- By sheet: ch02 21, ch03 12, ch04 5, ch05 5, ch06 7, ch07 2, ch08 10, ch09 8, ch10 7, ch11 3
- Duplicates, one construct claimed by two sheets: 0
- Orphans, defect grade: 0
- Orphans, note grade, ch.7 to ch.11: 2
- Anchors checked on the five new sheets: 30
- Anchors that fail to resolve: 1
- Anchors on the five new sheets in heading form: 8, of which 7 resolve
- Anchors on the five new sheets in label form: 22, all resolve
- Anchors that resolve through a file other than the one named: 3
- Defects: 1, on one sheet
- Notes: 9, plus the ch05 ruling

Every sheet in the wave is template-complete. All 30 construct entries carry both a
syntax shape and a section anchor, and all five headers carry the chapter number, the
title, and the pinned SHA. All five chapter titles match the source heading text.

The boundary partition is clean across all ten sheets, and after wave 1 came out the
same way I went looking harder for the collision. The closest is `pc`. ch04 claims it as
`pc = "LabelName"` at `exercises/ch04/CHEATSHEET.md:19` and ch08 claims the lifted
function form as `pc[0]` at `exercises/ch08/CHEATSHEET.md:15`. The source splits it too,
with an indexed label at `invariants.rst:113` and the rubric at `concurrency.rst:95`, so
the two sheets are following the split rather than making one. Same story for `with`.
ch03 has the local-binding form at `pluscal.rst:208` and ch07 has the nondeterministic
form at `nondeterminism.rst:21`, and `nondeterminism.rst:26` opens by saying we've
already seen the first one. The source knows they're two things.

Fifteen boundary notes across the five sheets, and all fifteen chapter numbers are
right. That's the number I was least sure of going in, since a forward reference is easy
to get one off.

If you only fix one thing, fix the ch08 `pc` anchor. It's the only entry in the wave
that sends a reader to a target that doesn't exist.
