# Cross-sheet review: cheat sheets for learntla core ch.2 to ch.6

Bead `tla-jb7f.12`. Review only, no repairs.

Source of truth is `hwayne/learntla-v2` at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`.
The clone's tip was already that commit, so no explicit checkout was needed.
Chapter numbering follows the toctree in `docs/core/index.rst` with `setup` as 1.
That gives ch2 `operators.rst`, ch3 `pluscal.rst`, ch4 `invariants.rst`,
ch5 `constants.rst`, ch6 `functions.rst`.

Four checks ran over each sheet: template completeness, construct boundaries
across the five sheets, anchor resolution, and a syntax spot-check on the three
most load-bearing constructs.

## Verdicts

- ch02 (`exercises/ch02/CHEATSHEET.md`): PASS
- ch03 (`exercises/ch03/CHEATSHEET.md`): SEND BACK
- ch04 (`exercises/ch04/CHEATSHEET.md`): SEND BACK
- ch05 (`exercises/ch05/CHEATSHEET.md`): SEND BACK
- ch06 (`exercises/ch06/CHEATSHEET.md`): SEND BACK

Four send-backs looks harsh for a set this clean, so I want to be plain about
what drove them. Two sheets drop an `EXTENDS` line that their construct needs to
compile. Two more use an anchor form the template doesn't specify. Nothing here
is a wrong claim about what TLA+ does. Every anchor on every sheet resolves.

## ch02 findings

No defects. Two notes, neither needing repair.

**NOTE, anchor points away from the rule it labels.** The `EXTENDS` entry at
`exercises/ch02/CHEATSHEET.md:25` anchors to `operators#integer`, whose label sits at
`operators.rst:82`. That section mentions `EXTENDS Integers` in passing at
`operators.rst:87`. The chapter's actual rule, one `EXTENDS` line with modules
comma-separated, is the troubleshooting block at `operators.rst:217`. The anchor
resolves, it just lands short of the teaching.

**NOTE, two aliases go unrecorded.** `\cup` and `\cap` are introduced as alternate
spellings for `\union` and `\intersect` at `operators.rst:262`. No sheet carries
them. I think that's fine for an exercise author writing specs, and worth knowing
for one reading them.

## ch03 findings

**DEFECT, missing `EXTENDS TLC` on `assert`.** The entry at
`exercises/ch03/CHEATSHEET.md:31` gives the shape as `assert expr;` with no module
requirement. The chapter says otherwise at `pluscal.rst:141`: "To use ``assert``
you need to extend ``TLC``". An exercise authored straight from this entry won't
compile. ch02 records the same kind of requirement on every construct that has
one, at `exercises/ch02/CHEATSHEET.md:52` for `Sequences` and
`exercises/ch02/CHEATSHEET.md:64` for `FiniteSets`, so this is a gap against the
source and against the sheet family both.

**NOTE, `pluscal#with` resolves but not through a label.** The entry at
`exercises/ch03/CHEATSHEET.md:49` cites `pluscal#with`. There's no `.. _with:` line
anywhere in `docs/core`. The target exists as an index directive option instead,
`.. index:: ! with` with `:name: with`, at `pluscal.rst:208`. Sphinx resolves
`:ref:` against that name, so the anchor works in the built site. It's the only
anchor in the fifty that gets there by a route other than a plain label, and I'm
recording it as a note rather than a defect because the requirement is that an
anchor resolves and this one does. Overrule me if the checker you plan to write
matches on `.. _label:` only.

**NOTE, boundary citation off by two lines.** `exercises/ch03/CHEATSHEET.md:71`
cites `setup.rst:54` for the `running_models` target. The label is at
`setup.rst:52`. Line 54 is the heading under it.

Everything else on this sheet checked out. The five boundary notes all cite real
lines, and all five chapter numbers match the toctree.

## ch04 findings

**DEFECT, anchor form.** All five entries use a full repo path with the extension,
`docs/core/invariants.rst#invariant` and its four siblings, at
`exercises/ch04/CHEATSHEET.md:13`, `:17`, `:21`, `:25`, and `:29`. The template
specifies `<chapter#anchor>` at `exercises/templates/CHEATSHEET.md:19`, and ch02,
ch03 and ch06 all use the bare stem. Three anchor forms across five sheets means
anything that resolves them mechanically has to handle three. All five resolve, so
the repair is cosmetic and one line per entry.

**NOTE, five constructs is the right count.** This is the thinnest sheet, and I
checked whether it was under-claiming. The chapter's index directives sit at
`invariants.rst:7`, `:38`, `:113` and `:153`, which is exactly the five claimed.
The `=>` directives at `invariants.rst:129` and `:228` revisit the ch2 operator
rather than introducing it, and the sheet sends `=>` to ch2 at
`exercises/ch04/CHEATSHEET.md:43`. That's the right call.

## ch05 findings

**DEFECT, anchor form.** All five entries carry the `.rst` extension, as
`constants.rst#constant` and its siblings, at `exercises/ch05/CHEATSHEET.md:13`,
`:17`, `:21`, `:25`, and `:29`. Same repair as ch04, same reason. All five resolve.

**NOTE, the `ASSUME` shape is invented.** `exercises/ch05/CHEATSHEET.md:16` gives
`ASSUME S # {}`. The chapter teaches `ASSUME` through
`ASSUME Cardinality(S) >= 4`, which lives at
`docs/specs/duplicates/constant_2/duplicates.tla:4` and is discussed at
`constants.rst:49`. The sheet's version is well formed, and it sidesteps the
`EXTENDS FiniteSets` the real one needs. I'd rather see the chapter's own example,
but I don't think this one is wrong.

**NOTE, template boilerplate survives.** The line "What this chapter does NOT
cover, because a neighbouring chapter does." sits at
`exercises/ch05/CHEATSHEET.md:41`. The other four sheets dropped it.

**NOTE, themes are backticked.** The five theme lines at
`exercises/ch05/CHEATSHEET.md:33` to `:37` are wrapped in backticks, which copies
the template's `<theme 1>` placeholder markup. The other four sheets use plain
prose. Backticks read as identifiers everywhere else in these sheets.

**NOTE, the ch6 constant has two names.** `exercises/ch05/CHEATSHEET.md:43` calls it
`Length`, taken verbatim from `constants.rst:21`. What ch6 actually ships is
`CONSTANT S, Size`, at `docs/specs/duplicates/fs_2/duplicates.tla:3`, and that's
the name ch6's own boundary note uses at `exercises/ch06/CHEATSHEET.md:51`. The
source contradicts itself here and the two sheets inherit the split. An author
following the boundary note will hunt for a `Length` that isn't there.

**NOTE, ordinary assignment is claimed by nobody.** `constants.rst:33` names three
ways to assign a constant: ordinary assignments, model values, and sets of model
values. The sheet claims the last two. The `S <- 1..10` notation for the first is
defined in that same line and used for the rest of the book. It shows up on the
sheet only inside the model-value shape at `exercises/ch05/CHEATSHEET.md:20`. I
lean toward it being a construct, so I'm logging it as the closest thing to an
orphan I found.

## ch06 findings

**DEFECT, missing `EXTENDS TLC` on `:>` and `@@`.** The two entries at
`exercises/ch06/CHEATSHEET.md:27` and `:31` give no module requirement. The chapter
says at `functions.rst:142` that "``@@`` and ``:>`` are only available in your spec
if you extend ``TLC``". Same shape of gap as ch03's `assert`, and I suspect the two
came from the same habit of reading the syntax line and skipping the note under it.

**NOTE, three entries share one anchor.** `functions#function` carries the function
literal, `:>`, and `@@`, at `exercises/ch06/CHEATSHEET.md:25`, `:29` and `:33`. The
label is at `functions.rst:89`. `:>` and `@@` are taught at `functions.rst:138`,
which has an index directive and no label, so `functions#function` is the nearest
target that resolves. Correct, and coarser than the rest of the sheet.

**NOTE, state sweeping isn't listed.** It has its own label at `functions.rst:370`
and is first taught here. The sheet mentions it inside a theme at
`exercises/ch06/CHEATSHEET.md:46` and not as a construct. It's a technique rather
than syntax, so I don't think it needs an entry. Recording it because it's a named,
labeled idea that no sheet claims.

The three load-bearing shapes I spot-checked all held. `DOMAIN` against
`functions.rst:68`, the function literal against `functions.rst:98`, and the
function set against `functions.rst:235`.

## Cross-sheet summary

- Constructs claimed, total: 50
- By sheet: ch02 21, ch03 12, ch04 5, ch05 5, ch06 7
- Duplicates, one construct claimed by two sheets: 0
- Orphans, defect grade: 0
- Orphans, note grade: 3
- Anchors checked: 50
- Anchors that fail to resolve: 0
- Anchors resolving by something other than a plain label: 1
- Defects: 4, spread over 4 sheets
- Notes: 12

Every sheet is template-complete. All 50 construct entries carry both a syntax
shape and a section anchor, and all five headers carry the chapter number, the
title, and the pinned SHA.

The boundary partition came out clean, which is the result I was least expecting.
Zero duplicates across 50 constructs, and the two near-collisions are both split
the way the source splits them. `IF-THEN-ELSE` goes to ch2 with `operators#if_tla`
and PlusCal's `if` goes to ch3 with `pluscal#if_pluscal`, matching the source's own
separate index entries at `operators.rst:44` and `pluscal.rst:153`. `x \in set` as
an operator goes to ch2 and `\in` on a variable declaration goes to ch3, matching
`operators.rst:242` against `pluscal.rst:319`.

The three note-grade orphans are `\cup` and `\cap` from ch2, the `<-` ordinary
assignment from ch5, and state sweeping from ch6. None of them is a syntax
construct an exercise would be built on, so I'd leave all three alone.

If you only fix two things, fix the missing `EXTENDS TLC` on ch03's `assert` and on
ch06's `:>` and `@@`. Those are the ones that break a spec.
