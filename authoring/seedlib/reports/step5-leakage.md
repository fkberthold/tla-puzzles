# Seedlib, step 5: leakage check and delivery-boundary audit

Adversarial pass over problem P4 per V2-PLAN §9.7, §6 step 5. Bead `tla-ngg5`.
Author-only. Nothing in this file goes to a blind panelist or into
`~/tla-practice/`.

I read everything under `authoring/seedlib/`. The learner-facing candidate set
is `statement/PROBLEM.md`, `statement/SeedLibrary.tla`, and
`statement/SeedLibrary.cfg`, three files. My job is to say whether those three
are clean of everything else.

**Verdict: SHIP AFTER D1.** One ship-blocking defect, and it isn't leakage. The
statement tells the learner to run a command that returns a red verdict. Fix is
one token, arrow to step 4, and section 9 has it.

On leakage itself I found nothing that points at either seeded defect. The two
findings worth a reader's time are D1 and the delivery hazard in section 8,
which is about a file that doesn't exist yet.

## 1. What the greps say

Shape D nearly empties §9.7's representation frame, the way the plan says it
does. The learner holds a spec, so every name in it is theirs already. The
question that survives is whether anything reaches outside those three files.

**Reference identifiers in the prose.** Every top-level name in
`reference/SeedLib.tla`, plus the artifact's own additions, run as a
word-boundary grep over `PROBLEM.md`:

```
$ grep -nwE 'Checkout|Close|...|NoDebts|AllGood|SeedLib' statement/PROBLEM.md
45:**Checkout.** While a season is in progress, a member may check out a packet
65:**Return.** While a season is in progress, a member who owes a return of a
78:**Close and default.** When a season closes, the librarian squares the book.
84:Default has one consequence: no checkouts. A member in default can still
121:7. **Default is never clean.** A member in default owes at least one return.
136:The requirements are read through one named operator, `Observe`.
```

Six hits. Five are English words that happen to be section headings, and the
sixth is `Observe`, which §3.3 obliges the statement to name. The prose names
none of the thirteen checks. That matters for the elimination probe below,
since a critic has to open the `.cfg` to run it.

**Variant ids.** `grep -rnE 'V[0-9]{2}' statement/` returns rc=1. The step-2
matrix is invisible from the learner set, including the V45 label the artifact
was built from.

**Internals and paths.** A sweep for `reference`, `SeedLib`, `authoring`,
`author-notes`, `HANDOFF`, `FREEZE`, `sha256`, `variant`, `harness`, `verdict`,
`V2-PLAN`, `pilot`, `bead`, `answer`, `key`, `oracle`, `solution`, `grader`,
`probe`, `matrix`, `seeded`, `mutation`. Five hits. Four are the English word
"answer" in the task section. The fifth is `PROBLEM.md:150`, "The pilot
instance", and it's the domain's own pilot program. It matches the artifact's
`PilotMembers` and `PilotStock`, so it reads as intended and points nowhere.

**Answer-key vocabulary.** The sharper sweep for shape D. Every token that
appears in `author-notes/ANSWER-KEY.md` and not in the statement's own
vocabulary: `Gate`, `NonVacuous`, `NON_VACUOUS`, `vacuity`, `-inv FALSE`, `m4`,
`tla-29m4`, `Probes`, `still image`, `stillness`, `raw state`, `restatement`,
`instrument`, `diagnosis`, `antecedent`, `quantifies`, `box-action`,
`projection`, `tracks`. All absent. The two answer-key names that do appear,
`NoDebts` and `AllGood`, are in the artifact by construction. They are the
disguise, and section 3 is about them.

**Deficiency vocabulary, wide net.** The step-4 author was banned from
"vacuous" and "frozen" and their neighbors, so I swept synonyms and near
misses too: `trivial`, `stale`, `dead`, `still`, `unchanging`, `snapshot`,
`image`, `projection`, `view`, `inert`, `hollow`, `deficient`, `defect`, `bug`,
`flaw`, `broken`, `missing`, `omitted`, `gap`, `hole`, `weak`, `blind`,
`invisible`, `hidden`, `masked`. Eleven hits, and every one is innocent.
`CONSTANTS` and `UNCHANGED` are TLA+ keywords in the artifact. "still owes"
and "can still return" are the English adverb. The other four are "fixed",
used about the member set, the variety set, and the four founding numbers.

That last one is worth a sentence. "Fixed" appears three times and never near
the observation. The statement uses it only about parts of the system that are
genuinely fixed, so it neither points at the freeze nor misdirects away from
it.

**Classification vocabulary.** Six hits for `invariant`, `property`,
`temporal`, `liveness`, `safety`, `fairness`, `stutter`. Two are the `.cfg`'s
own `INVARIANTS` and `PROPERTIES` keywords. Two are `PROBLEM.md:167-168`
narrating the `.cfg`, and two are inside the quoted TLC output. Nothing
classifies a check that the learner can't classify from the file in their hand.
This is the one place seedlib differs from P3 by task shape rather than by
care. On buyclub the classification was an author-side judgment that stayed
back. Here it's printed on the artifact, and no wording choice changes that.

**The run summary.** `PROBLEM.md:170-181` quotes TLC verbatim. I re-ran the
shipped package and the numbers hold: 335 generated, 90 distinct, depth 7, 3
branches over 270 (`harness/verdict.sh -t 300 SeedLibrary.tla`, `OK`, rc=0).
The elided lines cover the heap banner, the parse list, and "Computing initial
states". Nothing informative sits in the ellipsis.

The framing is right too. The block arrives under "The submission", it's
attributed to the submitter, and `PROBLEM.md:184` states the claim as a claim.
The counts are presented as the evidence under audit rather than as an
inventory of hints, which is what the brief asked me to confirm.

## 2. The R probes, run over the learner set

Six probes, tiling first, per the rubric.

**Tiling.** The `.cfg` declares 13 checks. The statement numbers 11
requirements. I built the cross-table by hand rather than take the step-4
claim:

| requirement | check |
|---|---|
| 1 standing gates the shelf | `StandingGatesTheShelf` |
| 2 shelf discipline | `ShelfFloor` and `ShelfDiscipline` |
| 3 ledger discipline | `LedgerDiscipline` |
| 4 one debt per kind | `OneDebtPerKind` |
| 5 conservation in kind | `ConservationInKind` |
| 6 a close squares the book | `CloseSquaresTheBook` |
| 7 default is never clean | `DefaultIsNeverClean` |
| 8 the reckoning comes | `TheReckoningComes` |
| 9 the end is the end | `TheEndIsTheEnd` |
| 10 the calendar marches | `TheCalendarMarches` |
| 11 the opening | `TheOpening` |
| (none) | `TypeOK` |

Zero holes, confirming the step-4 record. Eleven requirements cover twelve
checks, requirement 2 takes two, and the thirteenth is a surplus rather than a
hole. The pilot's cheapest route (`tla-035d`) is closed by construction here,
and it's closed the strong way. A critic who builds this table learns that
every rule has a check, which is true and useless, and the deficiency is
thirteen checks that don't bite.

**Vocabulary absence.** Clean, and the split is sharper than a null result. I
grepped the artifact for every noun the statement declares invisible (`packet`,
`librarian`, `garden`, `crop`, `harvest`, `generation`, `provenance`, `viable`,
`label`, `age`): rc=1, zero hits across both files. Then for every noun the
statement declares visible (`season`, `shelf`, `owed`, `standing`, `good`,
`default`, and the rest): 101 lines. So the absent nouns are exactly the ones
the statement announces as absent, and none of them is a load-bearing term
left hanging. No `unanimity`-class hit.

**Elimination.** The step-4 author ran this over the four observation fields
and found all four carry declared checks. I ran it over the thirteen checks
instead, and that framing finds something:

```
$ awk '/^[A-Za-z]/ {d=$1} /Observe/ {print d}' statement/SeedLibrary.tla | sort -u
```

Twelve of the thirteen reference `Observe`. `TypeOK` is the only one that reads
the raw variables. So an elimination probe over the checks lands on `TypeOK`,
and the thing that makes it the odd one out is the raw-versus-`Observe`
distinction, which is one hop from the diagnosis.

I don't think that's a leak, for two reasons. It lands the reader on step 3 of
the intended route rather than past it, since knowing the distinction exists
isn't yet knowing what `Observe` returns. And the asymmetry is inherited: the
diff against `reference/SeedLib.tla` shows `TypeOK` byte-identical, so it's the
reference author's own style and not a seeding artifact. I'd record it as an
accelerator onto the intended route.

**The answer form.** `PROBLEM.md:189-201` fixes the evidence genre, a trace or
a check with a verdict, and presupposes there's something to find. The
presupposition is shape D's floor. You can't pose "audit this claim" without
it.

What it doesn't do is what sank the pilot. There the answer form named the
target and fixed the shape before the learner had thought about the domain
(`pilot/reports/agent-d.md:150-159`). Here it names no operator, no check, no
rule number, and no location, which the identifier grep in section 1 confirms
from the other end. The one word I weighed is "unexamined" at line 201, since
it picks out non-examination over mis-statement. Question 2 at line 191 already
carries that, and question 2 is the shape, so I read it as no incremental
narrowing.

**Pre-clearing.** One literal pre-clearing passage exists, and I want it on
record rather than reported as a null. `PROBLEM.md:88` heads a list
"**Simplifications, all deliberate.**", which is exactly the "this looks wrong
and is fine" shape the probe hunts. It clears six domain elisions: stock
movement, annuals, viability, trust, fixed membership, and packet-counting
granularity.

None of the six sits near either defect. The closest is "the library counts
packets, nothing finer", and it clears the shelf's resolution rather than
whether the shelf reading is current. §3.2 obliges the statement to fix the
system, so the list has to be there. The artifact carries no comments at all
(`grep -nE '\(\*|\\\*'` returns rc=1 on both files), so nothing pre-clears
anything on that side either.

**Recall.** Section 6 has this one, since my screen run disagrees with the
step-4 record about what the two rows measure.

## 3. Style tells in the artifact

I read `SeedLibrary.tla` the way a suspicious learner would, then diffed it
against the frozen reference to see what the seeding actually moved. Five
edits: the module rename, the two `Init` helpers, the guard deletion, the
`Observe` rewrite, and the pilot constants at the bottom.

**No unused definitions.** Every operator in the file has a consumer. That
closes the loudest tell available to this kind of disguise.

**The packaging is honest.** The reference uses a two-module `MCSeedLib`
wrapper. The artifact inlines `PilotMembers`, `PilotVarieties` and `PilotStock`
below `TheReckoningComes`, which is a normal single-file submission idiom and
matches the statement's "The package is two files".

**One consistency tell, and I'd leave it alone.** `NoDebts` and `AllGood` are
defined at `SeedLibrary.tla:25-26` and used twice each, in `Init` and in
`Observe`. `TheOpening` at lines 105-106 spells out the same two expressions
longhand instead of using them. So a reader who asks why those two definitions
exist gets the answer "so `Observe` can name them", which is close to the
diagnosis.

The obvious tidy-up makes it worse, which is why I'm flagging it as a thing not
to fix. Point `TheOpening` at the helpers and its two conjuncts become
`Observe.owed = NoDebts` and `Observe.standing = AllGood`, sitting next to an
`Observe` whose fields are literally `NoDebts` and `AllGood`. That's a
syntactic tautology inside a check that passed, and it's louder than the
current inconsistency. Deleting the helpers is worse again: `Observe` then
carries a literal all-zeros function as a field value, which nobody writes by
accident. My read is that the helper disguise is doing real work and the
current placement is the quietest of the three.

**The other two tells are the defects themselves.** `Observe` at lines 68-72
shows three constants and one variable, and `Checkout` at lines 34-40 frames
`standing` without ever reading it. Both are findable by reading, both are the
intended entrances, and the step-4 record is right that no reword hides them.
Section 4 is about whether either one bypasses the work.

## 4. The routes, ranked

§9.7 asks for every route shorter than the intended one, ranked. The intended
route is the five-step one in `reports/step4-screens.md`, ending in a
demonstration.

**1. The `.cfg` against the numbered rules.** Closed. Section 2 has the table.
This is the pilot's killer and it returns nothing here.

**2. The prose diff on `Checkout`.** Reaches the guard in minutes, and does not
reach the deadness. I checked this rather than take it, since it's the claim
the whole design rests on. I rebuilt the artifact with the guard still missing
and `Observe` restored to the live reference form, then ran it:

```
$ harness/verdict.sh -t 300 SeedLibrary.tla
LIVENESS_VIOLATION
rc=13
Error: Action property StandingGatesTheShelf is violated.
```

Same deletion, live observation, red in seconds. Shipped, it's `OK` rc=0. So a
learner who stops at the diff holds a defect whose own "then why did it pass"
has no answer short of the observation layer. The diff is an entrance.

**3. Elimination over the thirteen checks.** Shorter than the intended route's
step 2, since one grep replaces reading each check. It lands on step 3 rather
than past it. Section 2 has the argument and the inheritance defense.

**4. Reading `Observe` directly.** Four lines, three of them naming opening
values. Fastest route to the deadness, and I agree with the step-4 record that
it isn't a bypass. What the task grades is what the text means and a
demonstration built to show it, and the grading split in section 7 enforces
exactly that.

**5. The statement's own reproduce command.** Not a route to either defect. It
is a false lead, it is the first thing the statement tells the learner to do,
and it is D1. Section 9.

**ROUTE: ACCEPT.** The shortest complete route runs through the judgment the
problem is for. I tried to build one that finishes the task without the
observation argument and couldn't. Tiling is closed by hand, the guard diff
dead-ends at rc=13 under a live observation, and the run summary carries no
numeric tell, since I reproduced the reference's own counts off the shipped
package.

## 5. The independent puzzle screen

**Disclosure first, and it's the same one P3's checker had to make.** My brief
told me to audit everything under `authoring/seedlib/`, and `step4-screens.md`
is in there. I read it before I knew the screen was mine to run, so my Q1 to Q8
are contaminated and their agreement with the author's is worth close to
nothing. P3's report proposed a brief-ordering fix, naming the screen before
the directory sweep. I'd second it. Two waves have now hit it, so I think it's
the brief and not the agent.

R is different, and section 4 is my own. The author's route is a claim I could
walk, and two of its load-bearing steps I checked with runs rather than
readings.

Shape D, so Q1 and Q2 in their requirement-centric form.

| # | answer |
|---|---|
| 1 | **System.** Deciding what thirteen green claims established isn't a diff. |
| 2 | **Decided.** The claims are given, and whether they say what the prose says is the task. |
| 3 | **System.** Is this design correct, on the evidence. |
| 4 | **Learner models, TLC checks.** The search is spent before the learner arrives. |
| 5 | **Abstraction.** What a property subscripted by a still projection quantifies over. |
| 6 | **Several, fallible.** Two members, silent crop failure, debts lapsing into default. |
| 7 | **Yes.** The diagnosis argument stands on paper. TLC adjudicates the demonstration. |
| 8 | **No.** Grep for optimal, minimum, fewest, best: rc=1. |

**Tally: 8 of 8 system rows. KIND: ACCEPT, system.**

One qualification I'd keep rather than round off, and it's the author's own
split. Half of Q1 is a diff, since holding requirement 1 against `Checkout`
finds the guard in minutes. That half can't complete the task, which is what
section 4 establishes with a run.

## 6. The mechanism screen, and what the author's two rows measure

The step-4 record carries two §5.7 rows, BURNED and CLEAR, and asks central to
read the BURNED one before step 5 dispatches. I ran the screen myself on the
statement's actual opening wording:

```
$ harness/screen.sh --offline --name SeedLibrary "A neighborhood seed library
  lends seed to its members. ... The loan is a debt in kind ..."
--- §5.7 VERDICT: BURNED   (name: SKIPPED | mechanism: BURNED)
    mechanism terms: allocation,queue
```

BURNED on the statement as worded. I then went looking for what derived those
two terms, and it's `harness/screen.sh:116`:

```
seed library|return obligation~allocation,queue
```

The phrase "seed library" is a hard-coded §2.2 suspicion row. So the tool
burns any candidate text containing the domain's own name, by table lookup, and
derives nothing structural.

That changes what the author's two rows mean. They aren't two readings of the
wording. They're one run with the domain name in the probe text and one run
without it. The CLEAR row omitted the phrase, so the table had nothing to hit
and no mechanism came back, which is the case §9.6 says to distrust. The author
said as much and named the mechanism by hand, which was the right move. I'd
just correct the record: "the debt-in-kind vocabulary doesn't collide" is
weaker than it reads, since the tool never had an entry that could have fired
on it.

None of that moves the disposition. The domain cleared step 0 and central
proceeded. What I'd add is that the Recall probe is worth less on shape D than
it would be on the same domain in column A. An allocator prior tells a critic
what a lending spec usually checks. It says nothing about whether the operator
those checks read tracks the state, and there's no public prior anywhere for a
green run that means nothing.

## 7. The grading split

§9.7 makes this a deliverable, before any critic runs. Two seeded gaps, and the
pair per §6's spread rule.

**Gap 1, the observation reports opening-day values on three of four fields.**

- **(a) naming**: the checks read state through `Observe`, `Observe` returns
  constants for shelf, owed and standing, so the pass establishes types and the
  calendar's march and nothing else.
- **(b) establishing**: a run. Three forms count, and I verified two of them
  against the shipped artifact myself.

A constructed property that's green and damning. I built "the visible library
never changes" over the artifact's own `Observe` and ran it: `OK`, rc=0, on a
90-state model. One line, and it's the diagnosis.

One requirement restated over the raw variables. I restated requirement 1 and
ran it: `LIVENESS_VIOLATION`, rc=13, with a four-state counterexample. Checkout
beans, close into default, checkout lettuce while in default. That's the
forbidden behavior the answer key describes, produced by TLC.

The forbidden trace exhibited step by step, plus the argument that no shipped
check rejects it.

What isn't (b): asserting the checks are empty with no run, and citing the
state counts. The counts are the reference's own, so they prove nothing.

**Gap 2, `Checkout` is missing the standing guard.**

- **(a) naming**: requirement 1 names three conditions and `Checkout` carries
  two.
- **(b) establishing**: a defaulted member checking out, as a trace or as a red
  verdict from requirement 1 restated over raw state.

**The cross-term is where the discrimination lives, and it runs against the
surface reading.** Gap 2 is concrete and gap 1 is abstract, so the instinct is
to score gap 2 as the floor. It's the reverse. A critic who names gap 1 and
never mentions the guard has answered both of the statement's questions and is
complete. A critic who names gap 2 and never asks why the run stayed green has
answered neither. I'd put that asymmetry in front of whoever grades, in those
words.

**One more row the grader needs if D1 ships unfixed.** A critic reporting
"deadlock" has found a checking-configuration artifact, not a seeded gap. Score
it as neither, and treat it as evidence about the statement rather than about
the critic.

## 8. The delivery boundary

Nothing in the three files points outside itself. The only path-shaped
reference is `PROBLEM.md:183`, and it names `SeedLibrary.tla`, which is in the
set. There's no directory reference and no glob, so this problem doesn't carry
P3's condition about a directory having to hold exactly the right files.

`grep -rniE 'solution|answer|key|grader|oracle|reference model'` over the set
returns four hits, all the English "answer" in the task section.

### Step-6 blind panel set

Exactly three files, named. For shape D the panel solves the diagnosis task, so
this is the same set the learner gets.

1. `authoring/seedlib/statement/PROBLEM.md`
2. `authoring/seedlib/statement/SeedLibrary.tla`
3. `authoring/seedlib/statement/SeedLibrary.cfg`

Copy them into a per-panelist directory with all three at the root, since the
statement's reproduce command expects the `.cfg` beside the module. Give no
panelist a path to `authoring/seedlib/`.

Author-only, and none of it may sit in a tree a panelist reads:
`author-notes/ANSWER-KEY.md`, `author-notes/ALTERNATIVES.md`,
`reference/SeedLib.tla`, `reference/MCSeedLib.tla`, `reference/MCSeedLib.cfg`,
`reference/FREEZE.sha256`, `reports/step2-variants.md`,
`reports/step4-screens.md`, this file, `DESCRIPTION.md`, `HANDOFF.md`.

Two of those are sharper than the rest. `ANSWER-KEY.md` names both defects with
line numbers in its first section. `step4-screens.md` carries the R route and
the exposure-instrument table, so it's an answer key wearing a screen record's
title.

### Delivery to `~/tla-practice/problems/seedlib/`

The same three files and nothing else. The directory already in use is named
`00-permit-review-critique`, so central may want a numbered kebab name here
too. The `tla-answers` side takes the reference and the variant matrix per
§6b.2.

**The hazard is a file that doesn't exist yet, and I'd flag it hard.** The
pilot's directory ships a `READ-ME-FIRST.md`, and that file says the main gap
is known to be too easy, that six critics found it by comparing one prose rule
against one line of spec, and that the interesting half is the second thing the
spec gets wrong. Written for the pilot, that's calibration. Written for seedlib
by the same pattern, it's the answer key. A note saying "the guard diff isn't
the real answer" hands over the entire diagnosis in eleven words.

So: seedlib ships with no `READ-ME-FIRST.md`, or with one that says nothing
about where the difficulty lives. I think the honest version is a line about
which learntla chapters it assumes and nothing else.

### What the attempt-log template must ask

`~/tla-practice/attempts/LOG-TEMPLATE.md` exists and carries the §6b.4 fields.
It asks for started and finished, minutes, outcome, the impasse kind, what was
tried and dropped, and what read as broken rather than hard. The impasse
question is already asked directly rather than inferred, which §6b.4 requires.

Two things it needs for this problem.

**The outcome row is too coarse for shape D.** Solved, partial, stuck,
abandoned can't tell apart the two ways of being partial here, and the
difference is the whole measurement. Add a seedlib row with four values: found
the deadness, found the guard, found both, found neither. Section 7 says why
"guard only" is the low outcome and not the middle one.

**Naming and establishing need separate boxes.** §6's spread rule splits every
load-bearing claim into the conclusion and the instrument, and the log should
record them apart. One field for what was named, one for whether a run backed
it, and one naming the instrument if there was one. On the pilot the instrument
column carried all the discrimination, five of six, and a log that collapses
the pair loses exactly that.

I'd also keep a line for whether the reproduce command came back red, since
that's the D1 tell and it's the one thing in the log that measures the
statement rather than the solver.

## 9. Defects

**D1, ship-blocking, arrow to step 4. The reproduce command returns a red
verdict.**

`PROBLEM.md:183` says:

> You can reproduce the run: `tlc SeedLibrary.tla` with the config beside it.

Run verbatim, that's rc=11:

```
$ tlc SeedLibrary.tla
Error: Deadlock reached.
State 4: <Close ...>  season = 4
203 states generated, 75 distinct states found, 28 states left on queue.
rc=11
```

The end state has no successor, by design. `InProgress` goes false at
`season = Ended` and all three actions are disabled, which is requirement 9
working. `harness/verdict.sh` turns TLC's deadlock check off by default, so
every run in the step-4 record and in the answer key was clean. Bare `tlc` has
it on, and the statement is the first place a bare invocation gets promised.

With the flag, the quoted block reproduces exactly:

```
$ tlc -deadlock SeedLibrary.tla
335 states generated, 90 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 7.
rc=0
```

Three reasons I'd block on it rather than note it. The statement's whole
premise is that every check passed, and a learner following its one command
sees otherwise. The trace they get is a false lead pointing at neither seeded
defect, and it arrives before they've read anything. And it costs a panelist
budget I'd rather not spend, since a blind critic can't tell a configuration
artifact from a submission defect without the reference.

The fix is `tlc -deadlock SeedLibrary.tla`. There's no `.cfg` keyword for it,
so it has to live in the prose. I'd leave the reason unstated or give it half a
clause, since "the program's end has no successor" is already implied by
requirement 9 and leaks nothing about the observation.

**N1, not a defect, recorded so nobody fixes it.** The `TheOpening` helper
inconsistency at `SeedLibrary.tla:105-106`. Section 3 has the argument. Both
obvious tidy-ups make the disguise louder.

**N2, not a defect, recorded as investigated.** `PROBLEM.md:138-144` says
"right now" four times in one short section, and the three fields it says it
about are exactly the three that got frozen. That looked like over-insistence
to me, so I checked the provenance:

```
$ git log --oneline --diff-filter=A -- authoring/seedlib/HANDOFF.md \
    authoring/seedlib/statement/PROBLEM.md \
    authoring/seedlib/statement/SeedLibrary.tla
57fb142 seedlib: the deficient artifact, green on every instrument
9dcb649 seedlib: the P4 statement, screened as worded
e46668b seedlib: stage the section 1-4 hand-off
```

`HANDOFF.md:189-200` already carries "right now" on shelf, owed and standing
and not on season, two commits before the artifact existed. The statement
author copied a pattern from the common ancestor. It's an artifact of `season`
carrying its own tense in "the season now in progress", not a pointer somebody
sharpened.

The content has to stay either way. Without the currency contract there's no
defect to find, and a critic could argue the operator is a legitimate
opening-day record.

## 10. Verdict

**SHIP AFTER D1.**

On leakage the three files are clean. No variant ids, no paths, no internals,
no answer-key vocabulary, no deficiency vocabulary, and no check named in the
prose. Both R probes that could have found a shortcut came back closed, and I
checked the load-bearing one with a run rather than a reading: the guard
deletion goes red at rc=13 the moment the observation is live, which is what
makes the diff an entrance instead of an answer.

D1 is the one thing I'd hold the panel for. It's a one-token reword and it
costs nothing to make, and shipping without it spends blind-panelist budget on
a deadlock that isn't in the answer key.

The two things I'd want travelling alongside are the grading split's
cross-term, since it inverts the reading a grader will reach for first, and the
`READ-ME-FIRST.md` hazard in section 8, which is a leak waiting in a file
nobody has written yet.
