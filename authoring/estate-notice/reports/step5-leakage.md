# estate-notice step 5: leakage check and delivery-boundary audit

Written under V2-PLAN §9.7 against the delivered learner set, which is
`authoring/estate-notice/statement/PROBLEM.md` and eight files under
`statement/traces/`. Bead `tla-h2cg.13`, rung 7 of batch 2, shape A, form left
open 1, property kind 3. I didn't write the reference, the statement or the
traces. This is the adversarial second pass, and I rewrite nothing.

Order of work, because it decides what the screen is worth. I read the learner
set first and nothing else, ran the §5.7b rubric on it, and wrote the verdict
down before opening `DESCRIPTION.md`, the reference, the step 2 report, the step
4 screen or `VECTOR.md`. Section 0 below is that record. Everything from section
1 on was written after.

## 0. The Part A screen, as written before the answers side

Shape A hands the learner no spec, so Q1 and Q2 get their first form.

| # | Question | My answer |
|---|---|---|
| 1 | Legal moves handed over. Anything left to model? | **System, narrowly.** Rules 1 to 8 name every act. What's left is the state behind `Observe`, which line 163 leaves open, and eight formulas nobody wrote. |
| 2 | Actions given, or decided? | **Given.** Rule 6 even fixes the atomicity: payment is its own act. I counted this as a puzzle row. |
| 3 | What's asked? | **Is this design correct.** Eight requirements to establish, no goal state. |
| 4 | Who works? | **Learner models, TLC checks.** 77 states isn't a search. |
| 5 | Difficulty? | **Abstraction choice.** Prose rules rendered over a fixed three-field observation. |
| 6 | Agents, failure, interleaving? | **Two kinds, uncoordinated.** Creditors need never act. The executor can stall. |
| 7 | Delete TLC, decision left? | **Yes.** What requirement 4's subscript has to watch. |
| 8 | An optimum named? | **No.** The grep returned rc=1. |

One puzzle row of eight, with Q1 read as a near thing. The threshold is three.

**KIND: ACCEPT, system.**

My route analysis, also from Part A. The intended route is to decide a state
shape, define `Observe`, write eight formulas, work out requirement 4's
subscript, write the fairness, run TLC, and hold the model against eight pairs.
The probes found three things.

The answer form hands over two decisions before the learner has thought about
the domain. The three interface fields with their shapes, and the four fairness
conjuncts at lines 228 to 231.

Elimination hands over a third. Requirement 4 is the only open subscript, and
six siblings all read "subscripted over the whole of `Observe`". Copying them is
correct.

Tiling gives eight worked targets. One pair per requirement, each naming its
requirement in its first line, each violating half showing one offending step.

I recorded ROUTE: ACCEPT, marginally, on the grounds that the modeling half
survives even when the requirement half is transcribed. Section 8 revises the
margin, not the verdict.

## 1. Does the statement give away the state representation?

This is §9.7's own question and it comes first. Three sentences carry structure
from the reference. I'll take them in order of how much they hand over.

**The interface, `PROBLEM.md:137-157`.** The three fields are `standing`,
`notice` and `distributed`. The reference's variables are `standing`, `notice`
and `distributed`, and it carries no fourth
(`reference/EstateNotice.tla:4`). So the field names are the variable names,
one for one, and `Observe` is the identity over them
(`reference/EstateNotice.tla:14`).

I don't think that's a leak, and the reason is which direction it runs.
§3.3 makes the interface fixed so grading can key off it, and this rung's
representation level is 2, which says in as many words that the reference's
variables are the `Observe` fields. The reference was narrowed to match the
interface, not the other way round. `DESCRIPTION.md:298` records central making
that call.

What survives is that the learner's own state stays open, and the statement says
so at line 163. `DESCRIPTION.md:286-295` lists six forks the rules don't decide,
and five of them are still live for a learner who wants them. A partition of
`Creditors` into named sets computes `standing` fine.

**The 77-state sentence, `PROBLEM.md:276-281`.** This is the one the brief asked
me to weigh, and it's conditioned on the learner's state rather than stated
flat. "A model whose state is exactly the three facts `Observe` reports finds 77
distinct states here." Then line 279 says larger counts aren't wrong by
themselves.

The condition does real work. It makes the number a tamper check on the rules
rather than a target for the state shape, which is the same job qsl's one
published number does (`authoring/qsl/reports/step5-leakage.md:257-262`). A
learner who keeps richer state loses the check and loses nothing else.

I ran it. `tlc -workers 1 -deadlock EstateNotice.tla` over the frozen reference
and its frozen cfg reports 138 states generated, 77 distinct, depth 9, no error
found. So the sentence is true, which matters more than it sounds. A false
checksum would send a correct learner hunting a difference that isn't there.

Two of the three numbers shouldn't be there, though. qsl's pass kept the
generated count and the depth author-side by name, and this statement publishes
both. Depth 9 puts the longest run at 8 steps, and 8 factors as two lodgings, a
close, two decisions, two payments and a distribution. That's the reference's
action decomposition, readable off one integer. Rule 6 already says payment is
its own act, so the leak is redundant rather than new. It's still a decomposition
in a statement, which is the class §9.7 asks me to flag. See D2.

**The fairness sentence, `PROBLEM.md:228-231`.** Weak fairness on her closing the
notice, on her deciding a named creditor's lodged claim, on her paying a named
creditor's admitted claim, and on her distributing the residue. That is
`reference/EstateNotice.tla:70-73` in English, conjunct for conjunct, including
the per-creditor quantification carried by "a named creditor".

This one is a decomposition handed over in full, and I want to be careful about
what follows from that. Section 8 has my read.

Nothing else in the learner set names or implies a reference element. The
identifier sweep in section 4 is the evidence.

## 2. The `Observe` fields

Three fields, stated as facts, with the shapes pinned and nothing else.
`Observe.standing` is a function from `Creditors` to six spellings.
`Observe.notice` is `"open"` or `"closed"`. `Observe.distributed` is a boolean.

`"none"` is handled the way the brief asks. Line 159 says it's a standing like
the other five and not a missing value, so every creditor carries one of the six
at every moment. That's a model value in a set of model values, not a marker
with special status, and it closes the "is absence representable" question
before a learner can trip on it.

No field is named after something the learner has to discover. None of the three
shapes forces a side of a §5 fork. `standing` as a function per creditor is one
of the three shapes `DESCRIPTION.md:286-288` lists, and the other two compute it.

One thing the interface does close, and `DESCRIPTION.md:193-202` owns it rather
than hiding it. A single `standing` field makes "one place at a time"
unrepresentable, so no property has to grade it. That costs the learner a degree
of freedom and buys back a property that would have graded bookkeeping. I agree
with the trade, and it's an authoring decision rather than a leak.

## 3. The trace pairs

Eight pairs, rendered over the three `Observe` fields and nothing else. No action
name, no formula, no obligation name, no rc value. The identifier sweep confirms
it.

I walked every violating half against the eight requirements by hand, asking
whether it breaks its own requirement and nothing simpler.

| pair | violating step | breaks | anything simpler? |
|---|---|---|---|
| 1 | distribute with `c1` still lodged | req 1, in one state | no |
| 2 | `none` to `lodged` after the close | req 2 | no |
| 3 | `lodged` back to `none` | req 3 | no |
| 4 | `admitted` to `rejected` | req 4 | no |
| 5 | closed notice reopens | req 5 | no |
| 6 | distribution undone | req 6 | no |
| 7 | settled, notice open, nothing more happens | req 7 | no |
| 8 | both creditors decided in one step | req 8 | no |

Eight for eight. Each violating half is a violation of its own requirement, and
I couldn't find a second requirement that catches any of them. Pair 1's is a
state violation and the other seven are step violations, which matches the kinds
the statement declares.

The allowed halves all check out as behaviours the rules produce. Pair 6's is
worth naming, because it's the only one exercising Rule 8. A creditor comes
forward out of time after the residue has gone, which the rules permit and a
careless model forbids.

Pair 7 carries the one non-boilerplate line in the eight files. Line 74 says the
forbidden run doesn't end and nothing more ever happens from state 6. A liveness
counterexample can't be rendered as a finite list of states without that
sentence, so the shape requires it. It gives away no formula.

The tiling is one to one and the statement says so at line 242. Under shape A
there's no model for the pairs to tile against, and they carry no state shape,
no kind, no subscript and no fairness. I read that the way the step 4 screen
does. It's §3.9 by construction.

## 4. Standard sweeps

Four mechanical sweeps over the nine learner files. Commands recorded so they're
cheap to re-run after a reword.

**Reference internals.** Every top-level name in the frozen module that isn't
part of the declared interface, word-boundary:

```
$ grep -rnwE 'vars|Standings|Decisions|Notices|Unsettled|Init|Lodge|ComeForward|
Close|Decide|DecideStep|Pay|Distribute|Next|TypeOK|SheDistributesOnlyWhenClear|
ClaimsStartWithTheCreditor|ALodgedClaimEndsInHerDecision|ADecisionStands|
TheNoticeNeverReopens|TheDistributionIsNeverUndone|
TheEstateIsEventuallyDistributed|SheTakesOneClaimAtATime' \
    authoring/estate-notice/statement
rc=1
```

No hits. Not one of the seven obligation names, not one of the six action names,
not `vars`, not `Init`, not `Next`. The learner-visible identifiers are
`Creditors`, `Observe`, its three fields, the six standings and `Spec`, and every
one of those is declared on purpose.

**Author-side ids and internals.** `S[0-9][0-9]`, `P0[0-9]`, `W1` to `W8`, `rc=`,
`variant`, `seeded`, `verdict.sh`, `harness`, `solution`, `answer key`, `grader`,
`reference model`, `EXCEPT`, `UNCHANGED`, `WF_`, `SF_`, `EXTENDS`. Two English
hits and nothing else. "Nothing here happens except by a party's own act" at line
59, and "chooses" three times against the `CHOOSE` pattern. The 36 rows of the
step 2 matrix are invisible from the learner set.

**Paths and plan references.** `authoring/`, `reference/`, `author-notes`,
`reports/`, `FREEZE`, `V2-PLAN`, `tla-`, and the section mark. rc=1. Nothing in
the learner set points outside itself, and PROBLEM.md's one path reference is
`traces/` at line 242, which points inward.

**Classification vocabulary.** This one has hits, and they're the rung. Every
requirement names its keyword and its kind, at lines 178, 185, 190, 196, 204,
209, 213 and 218. "Weak fairness" appears at 228 and 233.

buyclub and qsl both kept classification vocabulary entirely author-side, so the
contrast is worth explaining rather than filing. Those two sit at form left open
2 and 3 (`authoring/buyclub/VECTOR.md:14`, `authoring/qsl/VECTOR.md:14`). This
rung is form 1, which V2-PLAN.md:335 defines as the keyword or kind given and the
subscript target left open. Handing over the kind labels is what the level means,
not a slip.

## 5. The delivery boundary

**Step 6 blind panel set.** Exactly nine files, named. No directories, no globs.

1. `authoring/estate-notice/statement/PROBLEM.md`
2. `authoring/estate-notice/statement/traces/pair-1.md`
3. `authoring/estate-notice/statement/traces/pair-2.md`
4. `authoring/estate-notice/statement/traces/pair-3.md`
5. `authoring/estate-notice/statement/traces/pair-4.md`
6. `authoring/estate-notice/statement/traces/pair-5.md`
7. `authoring/estate-notice/statement/traces/pair-6.md`
8. `authoring/estate-notice/statement/traces/pair-7.md`
9. `authoring/estate-notice/statement/traces/pair-8.md`

Copy them into a per-panelist directory with `PROBLEM.md` at the root and the
eight pairs under `traces/`, so line 242's directory reference resolves. Give no
panelist a path to `authoring/estate-notice/`.

That reference carries the same condition buyclub's did. §6 says a blind agent
gets named files and never a directory, and here the statement names one. So the
panelist's `traces/` has to hold exactly those eight files and nothing else. It
does today. `find authoring/estate-notice/statement -type f` returns nine paths,
no hidden files, no stray notes.

**Author-only.** None of this may sit in a tree a panelist reads.

- `DESCRIPTION.md`, `VECTOR.md`
- `reference/EstateNotice.tla`, `.cfg`, `FREEZE.sha256`
- `reports/step0-screens.md`, `step0b-fit-review.md`
- `reports/step2-variants.md` and `reports/step2-variants/`
- `reports/step4-screens.md`, and this file
- `author-notes/ALTERNATIVES.md`, `author-notes/step4-trace-map.md`

Two of those are closer to an answer key than the reference is.
`step4-screens.md` carries the shortest-route analysis.
`author-notes/step4-trace-map.md` maps every pair to the obligation and the
variant behind it, and its last section names the graded subscript outright.

No file in the learner set mentions a reference, a solution, an answer key or a
grader. The sweep above is the evidence.

## 6. The vector citations

Six rows, each cited. I opened every line.

| row | level | resolves? |
|---|---|---|
| representation | 2 | Yes. `PROBLEM.md:30` says no model ships. `EstateNotice.tla:4,14` are the three variables and `Observe`. |
| property kind | 3 | Yes. `EstateNotice.tla:70-73` are the four `WF` conjuncts, `:112` is the `<>`, `cfg:14` declares it. |
| property count | 2 | Yes. `cfg:5-15` carries 2 invariants and 7 properties, 9 lines. |
| step sources | 2 | Partly. See below. |
| state space | 0 | Yes. `step2-variants.md:111` and `:150-151` both carry 77 distinct and 138 generated. `PROBLEM.md:276-277` matches. |
| form left open | 1 | Yes. Eight line numbers, one per requirement, and each carries a keyword and a kind. |

The step-sources row cites `PROBLEM.md:50-60` and
`EstateNotice.tla:70-73`. The prose citation is direct and says two kinds act
independently. The module citation is the fairness clause, which shows the
executor's steps named as a group and the creditors' absent. That supports the
claim by implication. The line that carries it directly is `Next` at
`EstateNotice.tla:59-65`, where both parties' actions appear as disjuncts. I'd
swap or add that reference. It's a soft citation rather than a wrong one, so it
doesn't gate anything.

`VECTOR.md:6-10` already carries the correction that the withheld subscript sits
on requirement 4 and not on item 7, against `DESCRIPTION.md` §5. I checked it and
it's right. Item 7 is `<>Observe.distributed`, which has no subscript to withhold.

`bash harness/test-vector.sh` returns `OK: 32 assertions passed`.

## 7. The grading split

§9.7 wants this before any blind agent runs. Per requirement:

**(a) A property that carries it.** It rejects that pair's forbidden run, admits
its allowed run, sits under the keyword the requirement names, and is subscripted
so TLC tests it at the step that matters.

**(b) A property that passes the shipped instance without carrying it.** The same
formula subscripted over a field the violating step leaves alone. It goes blind
through its own stuttering disjunct.

(b) isn't hypothetical here. Step 2's finding 4 measured it three ways
(`reports/step2-variants.md:339-360`). Two of the three still get caught, by
`SheDistributesOnlyWhenClear` sitting earlier in the search, so a learner with a
wrong subscript on requirements 2 or 5 passes for a reason unrelated to the
property they got wrong. Requirement 4 is the clean case. Subscripted on
`distributed` it misses its variant at rc=0 with all 77 states explored and
nothing else catching it.

**Requirement 4's subscript grades in three tiers, not two.** This is the one
place on the problem where the subscript decision is graded by the property it
belongs to, so it's worth splitting properly.

| answer | correct? | evidence of the judgment? |
|---|---|---|
| `_Observe` | Yes | No. Six siblings in the statement read the same. |
| anything containing `standing` | Yes | Yes. Nothing in the statement suggests it. |
| `_(Observe.notice)` or `_(Observe.distributed)` | No | Blind. Passes at rc=0. |

I checked the middle row rather than assuming it. A scratch module carrying the
S06 mutation (`Decide` guarding on `{"lodged", "admitted"}`) with
`ADecisionStands` subscripted `_(Observe.standing)` catches the violation in 4
states, which is the same trace length the reference's `_Observe` form produces
against S06 (`author-notes/step4-trace-map.md:22`). So a learner who reasons down
to the minimum is right, and a learner who copies is also right. Only the first
answer tells you anything.

**At kind 3, what counts as the fairness being right.** Four weak-fairness
conjuncts on named executor steps. One for closing, one per creditor for
deciding, one per creditor for paying, one for distributing. Requirement 7 is
false if any single conjunct goes (`DESCRIPTION.md:141-142`).

Two things pass without being right, and neither is catchable by the cfg.
Blanket `WF_vars(Next)` returns rc=0 with the reference's own 138 generated and
77 distinct, because every action here disables itself for good and the graph is
a finite DAG (`reports/step2-variants.md:369-374`). And a learner who deletes an
action while keeping its fairness conjunct passes everything
(`reports/step2-variants.md:335-336`).

So the fairness has to be graded by reading the learner's `Spec`, never by the
verdict. And because lines 228 to 231 hand the four conjuncts over, a correct
answer there isn't evidence of the judgment either. That pair of facts is what
step 6's spread rule most needs from this problem, and I'd put it in the panel
brief rather than leaving a grader to find it.

Three rules on top:

1. **Don't grade on the state count.** 77 holds only under the narrowest state
   shape, and line 279 tells the learner larger counts are fine.
2. **An invented property isn't a miss.** Score it sound-and-extra or unsound.
3. **Read the argument, not the column.** Two learners can reject all eight
   forbidden runs, one with eight properties TLC checks and one with three that
   are blind. Same (a) column. That's where the spread lives.

## 8. Defects

**D1. The one graded subscript is copyable from its siblings.**
`PROBLEM.md:185,190,196,204,209,218`. Six of the seven action properties are told
they're subscripted over the whole of `Observe`. The seventh says the subscript
is the learner's to choose, and the right answer is the whole of `Observe`. A
learner who copies the pattern is correct without opening the question.

The statement's hint at lines 197 to 200 advertises the trap and doesn't close
the copy route. Neither the step 4 screen nor the trace map records this one.
The trace map's own note at line 112 covers the adjacent fact, that a
standings-only subscript is a wrong-but-not-blind answer, which is a different
observation.

The fix is in the prose, and I think it's cheap. Withhold the subscript on all
six action properties instead of one, and move the hint paragraph up into the
requirements preamble. Five of the six are ungraded whichever way the learner
answers, which `author-notes/step4-trace-map.md:82-89` already measured, so
withholding them costs nothing. Form stays at 1, because V2-PLAN.md:335 doesn't
count how many subscripts are open.

The live alternative is to ship as written and let the grading split in section 7
carry the load. That's what I'd take if step 6 were dispatching tonight, since
the three-tier table makes a copied answer readable in the panel data. I'd still
rather close it in the statement, because the rung's form dimension buys nothing
if the answer it withholds is sitting six lines up.

**D2. The statement publishes the generated count and the search depth.**
`PROBLEM.md:276-277`. 77 distinct is the tamper check and it earns its place. 138
generated and depth 9 are author-side numbers by qsl's precedent
(`authoring/qsl/reports/step5-leakage.md:259-260`), and depth 9 encodes the
reference's longest run at 8 steps.

Low severity, because Rule 6 already tells the learner payment is a separate act,
so the decomposition the depth confirms is one they already hold. The fix is a
one-line trim that leaves the checksum working. I wouldn't hold the ship for it.

## 9. Not defects, but central's call

**The fairness handover at `PROBLEM.md:228-231`.** The step 4 screen records this
as a shortcut that can't be reworded, "because the rung is form left open 1 and
the kind-3 brief requires the four to be named"
(`reports/step4-screens.md:145-151`). I agree it's a shortcut. I don't think the
necessity holds, and the mechanism is worth writing down.

Form left open governs which keyword a property goes under, what kind of formula
it is, the subscript, and whether the rule can be stated over the interface at
all (`V2-PLAN.md:339-341`). Fairness on `Spec` is none of those. Requirement 7's
form under level 1 is satisfied by line 213, which gives the keyword and the
kind. And property kind 3 is a level read off the reference, which `VECTOR.md:15`
cites to `EstateNotice.tla:70-73`. It says what the reference carries, not what
the statement has to print.

So the statement could keep lines 233 to 238, which are the argument against
blanket fairness and do the teaching, and drop lines 228 to 231, which are the
answer. The vector wouldn't move on any row, because no row measures the fairness
target.

I'm flagging rather than filing it for two reasons. Cutting those four lines
makes the problem harder on a dimension nothing measures, and that's a batch
decision about difficulty rather than a wording slip in one statement. And the
author already escalated it as a rung finding for whoever writes the first form-2
statement over a liveness requirement, which is the right place for it. My
disagreement is with the word "forbidden", not with shipping.

**The soft step-sources citation.** Covered in section 6. Add
`EstateNotice.tla:59-65`.

## 10. Verdict

**SHIP after D1.**

The statement doesn't give away the state representation in the sense §9.7 asks
about. The interface fixes three fields because §3.3 requires it and because this
rung's representation level says so, the reference was narrowed to match rather
than the reverse, and five of the six forks `DESCRIPTION.md` §5 lists are still
open to a learner who wants them. The 77-state sentence is conditioned on the
learner's state, it says larger counts are fine, and I ran the reference and it's
true.

The delivery boundary is clean. Nine files, no path leaving the set, no reference
identifier, no variant id, no obligation name, rc=1 on every author-side sweep.

The pairs are clean. Eight for eight, each violating half a violation of its own
requirement and nothing simpler, rendered over the interface and carrying no
formula.

Both screens accept. KIND at one puzzle row of eight, and ROUTE on the reading
that the whole transition system survives every shortcut I found.

What I'd want carried past the verdict is the pair of facts in section 7. The
fairness can't be graded by the verdict on this problem, and it can't be graded
by the answer either, because the answer is printed. Requirement 4's subscript is
the one place the rung's form dimension bites, and D1 is what keeps it biting.
Neither of those closes by looking at a TLC exit code, so both belong in the step
6 panel brief rather than in a grader's checklist.
