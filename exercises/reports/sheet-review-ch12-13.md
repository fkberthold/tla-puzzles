# Cross-sheet review: cheat sheets for learntla core ch.12 and ch.13

Bead `tla-jb7f.26`. Review only, no repairs.

Source of truth is `hwayne/learntla-v2` at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`.
The clone was checked out at that SHA before anything else ran
[`git rev-parse HEAD` returned `09840bfc2ee9a88cdbedb672be77a6c73942fe16`].
Chapter numbering follows the toctree at `docs/core/index.rst:54`, with `setup` as 1.
That gives ch12 `tla.rst` and ch13 `modules.rst` [`setup` is at `index.rst:58`, `tla` at
`:69` and `modules` at `:70`, so `tla` is the twelfth entry and `modules` the thirteenth].

Four checks ran: template completeness, construct boundaries across all twelve sheets,
anchor resolution, and a syntax spot-check on the load-bearing constructs per sheet.
Both sheet authors reported zero collisions. I didn't take that on trust. The boundary
check below is a token sweep over the source tree and a mechanical duplicate hunt over
all 105 construct names, run independently of whatever the authors ran.

## Verdicts

- ch12 (`exercises/ch12/CHEATSHEET.md`): SEND BACK
- ch13 (`exercises/ch13/CHEATSHEET.md`): PASS

One defect, on ch12, and it's a one-token slip in a boundary note. Every anchor on both
sheets resolves, both sheets are template-complete, and the boundary partition is clean
across all 105 constructs. The wave came in cleaner than the ch.7-11 wave did on anchors
and dirtier on source-completeness, which I'll come back to in the todo ruling.

## ch12 findings

**DEFECT, boundary note :109 names the wrong set.** The note at
`exercises/ch12/CHEATSHEET.md:109` says this chapter puts `\E` to a new use, "process
interleaving expressed as `\E self \in ProcSet`". The source never writes that. It writes
`\E self \in Threads` [`tla.rst:279` and `tla.rst:320`], and `ProcSet` appears in only
four places, none of them a `\E` [`grep -nF 'ProcSet' tla.rst` returned `:263`, `:267`,
`:276`, `:290`]. `ProcSet == (Threads)` makes the two equal in value [`tla.rst:263`], so
nothing here is wrong about the semantics. It's wrong about the syntax, which is what a
cheat sheet is for.

What makes it a defect rather than a slip is that the same sheet gets it right twice
elsewhere. Theme :91 says "Concurrency is just `\E self \in Threads: thread(self)`"
[`exercises/ch12/CHEATSHEET.md:91`]. The `ProcSet` construct entry lists exactly two uses,
the domain of `pc` and the range of the `\A` in `Terminating`, and doesn't claim the `\E`
[`exercises/ch12/CHEATSHEET.md:44`]. So the sheet contradicts itself, and an exercise
author who writes a fill-in-the-blank on `Next` from the boundary note gets a blank the
source doesn't fill that way. One-word repair: `Threads` for `ProcSet` at :109.

**NOTE, `Next == hr' = hr + 1` isn't in the source.** The sheet uses that shape twice, in
the spec-skeleton entry and in the `action` entry
[`exercises/ch12/CHEATSHEET.md:20` and `:24`]. A literal search finds no `Next == hr`
anywhere in the file [`grep -n "Next == hr" tla.rst` returned nothing]. The hourclock's
real `Next` is the IF form [`tla.rst:37-39`], and `hr' = hr + 1` is its ELSE branch
[`tla.rst:39`]. The template asks for a "short form, one line"
[`exercises/templates/CHEATSHEET.md:17`], so a condensation is inside the field's contract
and the condensation here is faithful. I'm logging it because check 4 is a
character-for-character check, and this is the one shape on either sheet that doesn't
survive one.

**NOTE, the `Terminating` one-liner moves the quantifier's scope.** The sheet writes
`Terminating == /\ \A self \in ProcSet: pc[self] = "Done" /\ UNCHANGED vars`
[`exercises/ch12/CHEATSHEET.md:56`]. The source keeps the two conjuncts on separate
bulleted lines [`tla.rst:276-277`]. A TLA+ quantifier body runs as far right as it can, so
flattening pulls `UNCHANGED vars` inside the `\A`. For a non-empty `ProcSet` the two forms
agree, since `UNCHANGED vars` doesn't mention `self`. They part on the empty set, where the
flattened form goes vacuously true and drops the `UNCHANGED` [INFERRED, from the TLA+
scoping rule, not from a TLC run]. Parentheses fix it at no cost:
`/\ (\A self \in ProcSet: pc[self] = "Done") /\ UNCHANGED vars`.

This is the only flattening on the sheet that changes a parse. I checked the other five.
`Spec` at :76, `Fairness` at :76, `Trans` and `IncCounter` at :52, and the `\/` action at
:32 all flatten safely, either because they hold no quantifier or because the quantifier
already sits last [`tla.rst:367-368`, `:399-403`, `:310-316`, `:167-168`].

**NOTE, `topics/refinement.rst` is a stub.** Boundary note :115 sends the reader there for
refinement properties [`exercises/ch12/CHEATSHEET.md:115`]. The page is 12 lines and says
"I haven't written this one yet, but in the meantime you can find an introduction on my
blog" [`topics/refinement.rst:8`]. The note is right about where the toctree points and
right that it's outside `core`. It's just pointing at an empty room. Same shape as the ch05
symmetry note the last review ruled on, and I'd grade it the same way, a note rather than a
defect, since nothing an author writes from ch12 breaks.

The other half of :115 checks out exactly. `.. _action_refactoring:` is at `tips.rst:279`,
which is the line the note cites [`grep -n '_action_refactoring' tips.rst` returned `279`].

**NOTE, ch12 has three `.. todo::` markers and flags none of them.** They sit at
`tla.rst:87`, `:411` and `:459` [`grep -nE '^\.\. todo::' tla.rst`]. One is a graphic chore.
The other two are content. `:411` reserves a warning about machine closure and an example
of fairness in a temporal property, which lands inside the fairness material that five of
the sheet's eighteen constructs cover. `:459` is a bare `.. todo:: Summary`, so ch12 has no
summary section for an exercise author to lean on the way ch9 and ch11 have one. I'll take
this up properly in the todo ruling, because ch13 flagged the identical situation and ch12
didn't, and the two sheets shouldn't answer that question differently.

**NOTE, two PlusCal counterparts go without a boundary note.** The sheet carries 17
boundary notes and they're thorough, so the two gaps stand out. PlusCal's `variables`
declaration is folded into ch03's `--algorithm` entry
[`exercises/ch03/CHEATSHEET.md:12` shows `variables x = 0;`], and ch12's `VARIABLE` entry
routes to ch05's `CONSTANT` instead [`exercises/ch12/CHEATSHEET.md:114`]. That follows the
source, which introduces `VARIABLES` by analogy to `CONSTANTS` [`tla.rst:45`], so I think
the routing is right and the gap is only that nobody says where the PlusCal form went. The
second gap is PlusCal function assignment. The source says the translator converts function
assignments to `EXCEPT` [`tla.rst:241`], the sheet's `@` entry knows it
[`exercises/ch12/CHEATSHEET.md:40`], and ch03 shows the indexed form in its `||` entry
[`exercises/ch03/CHEATSHEET.md:24`]. No note connects them.

Of everything on this sheet, `EXCEPT` is the closest thing to the defect class this review
was sent to hunt, a PlusCal-era construct re-expressed in TLA+. I don't think it's one.
`EXCEPT` has its own index directive [`tla.rst:206`], its own section [`tla.rst:172`], and
no earlier sheet claims it.

**NOTE, `Spec` leans on ch09's `PROPERTY` without a note.** The entry says `Spec` "is what
you register as the temporal property to run" [`exercises/ch12/CHEATSHEET.md:20`], which
matches the source [`tla.rst:45`]. ch09 claims `PROPERTY` as a construct
[`exercises/ch09/CHEATSHEET.md:15`], and ch11 wrote itself a boundary note for exactly this
dependency [`exercises/ch11/CHEATSHEET.md:36`]. ch12 didn't. Small, and worth matching ch11.

The three load-bearing shapes I checked held. `EXCEPT` against `tla.rst:214`, `:216`, `:224`
and `:239`, all four verbatim including the nested `![1].x = ~@` form. `WF_v(A)` and
`SF_v(A)` against `tla.rst:356-357`, character for character. `ProcSet == (Threads)` against
`tla.rst:263`. The chapter title `TLA+` matches the source heading [`tla.rst:4`].

## ch13 findings

No defects. Three notes, none of them a repair I'd insist on.

**NOTE, one of the three todos is a chore, not a gap.** Theme :48 says the chapter is
unfinished in three places [`exercises/ch13/CHEATSHEET.md:48`]. Two of the three are
content. `:137` reserves the parameterize-over-a-variable technique and `:166` reserves
`{EXPAND} Using Modules` [`modules.rst:137-149` and `:166`]. The third is
`.. todo:: move into an xml` [`modules.rst:100`], which is a build chore about how the
`Point` listing is stored. Counting it with the other two overstates the gap by one. The
theme's specific claim about `:137` is exact, though. The body reserves using actions from a
module as regular actions [`modules.rst:139`], so the chapter does name a technique it never
teaches.

**NOTE, `modules#with_tla` is a valid target nobody uses.** The label is at
`modules.rst:120`, attached to a literal block rather than a section, and a search across
the whole `docs/` tree finds no reference to it [`grep -rnF 'with_tla' docs/` returned only
the definition line]. It resolves as an HTML id, so the anchor works. Compare `tla#trans`,
which sits on a `.. tip::` the same way but is dereferenced by the source itself
[`tla.rst:421`].

**NOTE, the chapter-01 boundary note is precedented.** Note :53 routes module boilerplate
to chapter 01 [`exercises/ch13/CHEATSHEET.md:53`], and the source backs it, since
`setup.rst:32` gives the four-dashes rule and the filename-match rule. There's no
`exercises/ch01/CHEATSHEET.md`, so the note points at a chapter with no sheet. Three earlier
sheets already do this [a sweep of boundary-note chapter targets found `chapter 01` on ch03
and ch04, and `chapter 1` on ch02], so it's established practice and I'd leave it.

Every syntax shape on this sheet is verbatim. `LOCAL Op == "definition"` against
`modules.rst:34`. `INSTANCE Sequences` against `:50`. `LOCAL INSTANCE Integers` against
`:105`. `Foo == INSTANCE Sequences` against `:68`. `Foo!Append(seq, 1)` against `:72`.
`Origin == INSTANCE Point WITH X <- 0, Y <- 0` against `:124`.
`XAxis(X) == INSTANCE Point WITH Y <- 0` and `XAxis(2)!Add(x, y)` against `:160` and `:162`.
Seven for seven, which is better than any sheet in either earlier wave managed.

The themes hold too. The 300-line claim against `modules.rst:7`, the shared-directory
preference against `:16`, the one-`EXTENDS`-many-`INSTANCE` rule against `:54`, the
`Sequences.tla` locally importing `Naturals` against `:57`, and
`Origin!Add(x, y) == <<0 + x, 0 + y>>` against `:126`. The chapter title `Modules` matches
the source heading [`modules.rst:4`].

No orphans. The chapter's index directives name EXTENDS, LOCAL, INSTANCE, `!`,
Parameterized Modules, WITH and `<-` [`modules.rst:20-23`, `:40`, `:70`, `:92-93`,
`:115-118`]. The sheet claims all of them except `EXTENDS`, which its own boundary note
routes to ch02 [`exercises/ch13/CHEATSHEET.md:52`].

## Anchors

All 25 anchors on the two new sheets resolve. 19 are heading-form and 6 are label-form.

The ch.7-11 wave's one defect was a heading-form anchor pointing at a Sphinx rubric, which
renders as bold text with no link target. It can't recur here. Neither file contains a
`.. rubric::` at all [`grep -nE '^\.\. rubric::'` returned nothing on either file, exit 1].

Every `§` anchor lands on a real section with an underline row. In `tla.rst` those are
Learning from PlusCal at `:18`, with at `:128`, EXCEPT at `:172`, Modeling Concurrency at
`:247`, and Fairness in TLA+ at `:346`. In `modules.rst` they're EXTENDS at `:25`,
Namespacing at `:61`, and Partial Parameterization at `:153`. All eight heading strings
match the source character for character, lowercase `with` included.

Every `#` anchor lands on an explicit label. `tla#UNCHANGED` at `tla.rst:103`, `tla#trans`
at `:303`, `tla#fairness_status_example` at `:376`, `modules#INSTANCE` at
`modules.rst:41`, `modules#with_tla` at `:120`.

Two labels sit on directives rather than sections, `trans` on a `.. tip::` and `with_tla`
on a literal block. Both still generate an id. I'd have called that a defect if either
anchor used the `§` form, since a `§` anchor asserts a section. Both use `#`, which asserts
a label, and both labels exist.

One section on each sheet's chapter goes unclaimed by any construct. In `tla.rst` it's Why
use TLA+? at `:416`, whose content the sheet carries as a theme and a boundary note
[`exercises/ch12/CHEATSHEET.md:96` and `:115`]. In `modules.rst` it's the Modules section at
`:11` and Summary at `:168`. Neither introduces a construct, so I don't think either is a
gap.

## Boundaries

Zero duplicates across all twelve sheets and all 105 constructs.

I ran this two ways rather than reproducing either author's check. First, a token sweep of
the whole `docs/core` tree, `advanced/procedures.rst` included, for the twelve tokens that
carry ch.12 and ch.13's new material. `VARIABLE`, `vars ==`, `Spec ==`, `Next ==`,
`Init ==`, `EXCEPT`, `ProcSet`, `ENABLED`, `WF_`, `SF_`, `INSTANCE` and `LOCAL` all return
zero hits outside `tla.rst` and `modules.rst` [`grep -rnF --include=*.rst` over
`docs/core`, filtered to exclude those two files, returned nothing for all twelve tokens].
So every one of these constructs really is first taught where the sheet says.

Second, a mechanical duplicate hunt. I pulled every backticked token out of every
`- Construct:` line on all twelve sheets and looked for tokens appearing under two different
chapters. Six came back. Three are artifacts of multi-word names splitting on whitespace,
all inside a single sheet [`Set map` and `Set filter` on ch02, `function literal` and
`function set` and `struct literal` and `struct set` on ch06]. `with` is the ch03/ch07 pair
the wave-1 review already ruled follows the source's own split. That leaves two, and both
are ch04 against ch12.

Both are false positives, and it's worth saying why, because they're the exact shape this
review was told to hunt. `\E` shows up on ch12 only inside the name "nondeterministic
action (`\E` form and disjunction form)" [`exercises/ch12/CHEATSHEET.md:31`], and the sheet
routes `\E` itself to ch04 [`:109`]. `pc` shows up only inside "`Trans` helper action for
`pc` transitions" [`:51`], and the sheet routes `pc` to ch04 and its function form to ch08
[`:108`]. Neither is a claim. In both cases the ch12 entry names the new TLA+ shape and
hands the underlying construct back.

That's the pattern across the whole sheet, and it's why ch12 passes the boundary check
despite being the chapter most exposed to failing it. Eighteen constructs, seventeen
boundary notes, and I checked all seventeen chapter numbers. All seventeen are right.

### Reciprocity is one-sided

Only two of the ten earlier sheets carry a forward note into ch12. ch03 has "writing a spec
in pure TLA+ with no PlusCal at all is covered in chapter 12"
[`exercises/ch03/CHEATSHEET.md`, boundary notes], and ch11 has two, for the formal
definition of "action" and for the full `UNCHANGED` syntax
[`exercises/ch11/CHEATSHEET.md:37-38`]. Both reciprocate cleanly with ch12's side.

Two handoffs have no note on the earlier sheet. ch09 teaches PlusCal fairness and never
mentions that `WF_`/`SF_` arrive in ch12, even though ch09's own themes describe weak and
strong fairness in words the TLA+ operators formalize
[`exercises/ch09/CHEATSHEET.md:48`, and the sheet's boundary notes name only ch08 and ch10].
ch02 claims `EXTENDS` and never mentions `INSTANCE` or ch13
[`exercises/ch02/CHEATSHEET.md`, boundary notes name chapters 1, 3, 4, 5, 6 and 10].

Neither is a ch12 or ch13 defect, so neither changes a verdict. Both are repair-round items
on the earlier sheets, and I'd take the ch09 one first. Fairness is the single place in the
curriculum where a PlusCal construct and its pure-TLA+ form are separated by three chapters,
and it's the handoff an exercise author is most likely to walk into from the wrong side.

## Format

Both sheets are template-complete. All four sections are present and in the template's
order, Header, Constructs introduced, Major themes, Boundary notes
[`grep -n '^#'` on both files]. Every construct entry carries all three fields
[`grep -c '^  Syntax shape:'` and `'^  Section anchor:'` returned 18 and 18 on ch12, 7 and 7
on ch13, matching the construct counts]. Both headers carry the chapter number, the title
and the pinned SHA.

Both sheets dropped the template's boilerplate "What this chapter does NOT cover, because a
neighbouring chapter does." line [`exercises/templates/CHEATSHEET.md:28`]. Ten of the twelve
now drop it, so that's the settled convention.

**NOTE, the H1 line has never been standardized.** Seven sheets use
`# Chapter NN cheat sheet: Title`, ch13 among them. Five use some form of
`# Cheat sheet: ...`, ch12 among them [`head -1` across all twelve]. The template says
nothing about the H1 [`exercises/templates/CHEATSHEET.md` specifies only the four `##`
sections], so neither sheet broke a rule. It's now 7 to 5, which is close enough that a
repair round could pick one and normalize all twelve for the cost of twelve edits. I'd pick
the seven, since it puts the chapter number and the title in the first line.

## Ruling: `pc` deliberately not claimed by ch.12

The ch.12 author is right, and this is the call I'd have been most worried about if it had
gone the other way.

ch08 claims `pc[...]` with the syntax shape "`pc[0]`, `pc` becomes a function from process
values to labels once a spec has more than one process"
[`exercises/ch08/CHEATSHEET.md:16`]. The source line the ch.12 author pointed at says "`pc`
is defined as a function from process values to labels" [`tla.rst:292`]. Those are the same
sentence. If ch12 had claimed `pc`, that would be a duplicate under any reading, and it
would be the exact defect class this review was sent to find.

What ch12 claims instead is three shapes that are genuinely new here. `ProcSet` has no
counterpart before ch12 and appears nowhere else in `core` [the token sweep above].
Label-as-action is the `pc` guard plus the `pc'` update taken together as an encoding
[`tla.rst:296-301`], which is a fact about the translation rather than about `pc`.
`Terminating` I rule on next. The boundary note that carries the split is accurate on both
halves, ch04 for `pc` and ch08 for the function form [`exercises/ch12/CHEATSHEET.md:108`].

Ruling: correct as it stands. No repair.

## Ruling: `Terminating` claimed by ch.12

Also correct, and I checked the premise rather than the claim.

`concurrency.rst:219` is a `.. note::` saying the translator inserts an extra action and
"you can see it in the translation as `Terminating`". That's a name-drop inside a note about
deadlock, with no body and no syntax. ch08's sheet doesn't claim `Terminating`, and I
verified that by reading all ten of its construct entries rather than searching for the word
[`exercises/ch08/CHEATSHEET.md:11-49` claims process, `pc[...]`, process-local variable,
process set, `self`, `await`, deadlock, `procedure`, `call`, `return`].

The body appears once in `core`, at `tla.rst:276-277`, which is ch12. So ch12 is the only
sheet that can carry a syntax shape for it, and a construct entry with no syntax shape would
fail the template. ch12's boundary note hands the deadlock framing back to ch08 and says
what it's keeping [`exercises/ch12/CHEATSHEET.md:106`], which is the right division.

Ruling: correct as it stands. The one repair I'd make is the parenthesis fix from the notes
above, which is about the flattening and not about the claim.

## Ruling: `Trans` and helper actions claimed by ch.12

Correct, and this is the finest of the three splits.

ch11 teaches helper actions in one sentence about action properties, "you *can* use helper
actions in your action properties", with `BecomesNull(x) == x' = NULL` as the example
[`action-properties.rst:141-147`]. ch11's sheet carries that as theme :28 and claims no
construct for it [`exercises/ch11/CHEATSHEET.md:28`, and the sheet's three constructs are
`action property`, `'`, and `[P]_x`]. A theme isn't a claim, so there's nothing for ch12 to
collide with.

ch12's `Trans` is the spec-side use. It factors the `pc` guard and the `pc'` update out of
the actions themselves [`tla.rst:310-316`], it has its own label [`.. _trans:` at
`tla.rst:303`], and the source dereferences that label from its own why-TLA+ list
[`tla.rst:421`]. So the source treats it as a thing worth pointing at, which is about as
strong a signal as a cheat sheet gets that a construct is real.

The two uses also differ in what they're for. ch11's helper action factors a property.
ch12's factors a spec. Same technique, two sides of the checker, and the boundary note says
so [`exercises/ch12/CHEATSHEET.md:102`].

Ruling: correct as it stands. No repair.

## Ruling: the ch.13 todo question

The ch.13 author asked whether themes should stay to taught content. My answer is that the
theme stays where it is, but the ruling is bigger than ch13, because ch12 has the same
situation and handled it differently.

The theme doesn't belong in boundary notes. The template defines that section as "what this
chapter does NOT cover, because a neighbouring chapter does"
[`exercises/templates/CHEATSHEET.md:28`], and the author's reason for keeping it out is
exactly right. A todo gap is what nobody covers. Filing it as a boundary note would send an
exercise author looking for a neighbouring chapter that doesn't exist, which is a worse
failure than the ch05 symmetry note the last review ruled on.

Themes are the right home. The template puts no restriction on them at all, it just says
`<theme N>` three times, and the twelve sheets already use themes for things that aren't
taught syntax. ch09 carries the cost of liveness checking [`exercises/ch09/CHEATSHEET.md:50`],
ch10 carries TLC's lowest-value `CHOOSE` behavior [`exercises/ch10/CHEATSHEET.md:42`], and
ch12 carries the whole why-TLA+ list [`exercises/ch12/CHEATSHEET.md:96`]. Themes are already
"what an author should know about this chapter", not "what this chapter teaches".

So the answer to the question as asked is no, themes shouldn't stay to taught content, and
ch13 put it in the right section.

The problem is that ch12 didn't. `tla.rst` carries three todos, two of them content, and one
of those two reserves material inside the fairness section that five ch12 constructs cover
[`tla.rst:411`]. The chapter also has no summary, because that's a todo too [`tla.rst:459`].
ch12's sheet says none of this. It also sends a reader to `topics/refinement.rst`, which is a
stub, without saying so [`exercises/ch12/CHEATSHEET.md:115`]. Two sheets written in the same
wave, the same situation, and one flags it while the other doesn't.

I'd fix that by making the warning findable rather than by adding a section. A fifth `##`
section on two of twelve sheets breaks the template symmetry that makes these sheets worth
having. A fixed prefix inside Major themes costs nothing and a mechanical sweep can find it.
Something like `SOURCE GAP:` leading the bullet, applied to ch13's existing theme and to a
new one on ch12 covering `tla.rst:411`, `:459` and the refinement stub.

The alternative is a fifth section, `## Source gaps`, and it's what I'd take if more than
half the sheets turned out to need one. Two of twelve doesn't clear that bar. I'd also
accept doing nothing to ch12 if the repair round is tight, since the ch12 defect above
matters more, but then ch13's theme should stay untouched rather than be trimmed for
consistency with a sheet that's missing the warning.

On where the ch.13 exercise author learns this: the sheet is the wrong place to rely on. It
should carry the warning, and it does. But an exercise author reads the bead first, and
`tla-jb7f.28` is the bead [`bd list --limit 0` shows `tla-jb7f.28  Exercise set: learntla
core ch.13`]. The gap belongs in that bead's description, in the words the sheet already
uses, so nobody has to notice the eighth theme on a sheet with eight themes. The same goes
for `tla-jb7f.27` and ch12's todos once ch12 carries them.

## Cross-sheet summary

- Constructs claimed across ch.2 to ch.13, total: 105
- By sheet: ch02 21, ch03 12, ch04 5, ch05 5, ch06 7, ch07 2, ch08 10, ch09 8, ch10 7,
  ch11 3, ch12 18, ch13 7
- Duplicates, one construct claimed by two sheets: 0
- Near-duplicate token pairs surfaced mechanically: 6, of which 3 are within-sheet
  artifacts, 1 is the ch03/ch07 `with` split the source itself makes, and 2 resolve to
  ch12 entries that route the token back to ch04
- Anchors checked on the two new sheets: 25, all resolve
- Heading form: 19, all landing on a real section with an underline row
- Label form: 6, all landing on an explicit target
- Sphinx rubrics in either source file: 0
- Boundary notes: 17 on ch12, 5 on ch13, all 22 chapter numbers correct
- Themes: 12 on ch12, 8 on ch13
- Defects: 1, on ch12
- Notes: 10, plus the four rulings

Both new sheets are template-complete, both chapter titles match their source headings, and
the SHA on both matches the ten that came before.

The thing I went in expecting to find is a ch.12 entry that re-claims a PlusCal-era
construct under a TLA+ name. I didn't find one. I checked all eighteen entries against the
earlier sheets by hand after the mechanical sweep came back clean, and every entry that
sits near an earlier construct has a boundary note handing the earlier one back. Seventeen
notes for eighteen constructs is a high ratio, and I think it's why the sheet survives the
check. The two gaps I found are both notes rather than claims, PlusCal `variables` and
PlusCal function assignment, and in both cases the sheet routes the TLA+ side correctly and
just doesn't say where the PlusCal side lives.

If you only fix one thing, fix `ProcSet` to `Threads` at `exercises/ch12/CHEATSHEET.md:109`.
It's the only line in either sheet that tells an exercise author to write something the
source doesn't write.
