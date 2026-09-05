# herbarium-sheet step 5: leakage check and delivery-boundary audit

Bead `tla-h2cg.12`, rung 6 of batch 2, shape D at form left open 1, kind 3. Run
2026-09-05 as the adversarial second pass over the statement the step 4 author
delivered. I didn't write the reference, the statement or the traces, and I've
rewritten nothing.

Part A below was written from the learner set alone, before I opened
`V2-PLAN.md`, `DESCRIPTION.md`, the reference, or either step 4 report. It says
so where it sits. Everything from section 2 on had the answers side in hand.

## 0. The delivery boundary

A blind panel seat gets exactly eight files:

```
statement/PROBLEM.md
statement/traces/pair-1.md  ...  statement/traces/pair-7.md
```

`find authoring/herbarium-sheet/statement -type f` lists those eight and nothing
else. No spec ships, so there's no learner copy of the reference, and the shape D
object is a formula inside `PROBLEM.md` rather than a file of its own.

The provenance grep over the learner set returned nothing:

```
grep -rn -E 'authoring/|reference/|author-notes|reports/|FREEZE|V2-PLAN|tla-' \
    authoring/herbarium-sheet/statement/     -> exit 1, no output
grep -rn '§' authoring/herbarium-sheet/statement/         -> exit 1, no output
```

A second sweep for harness vocabulary (`harness`, `verdict`, `vacuity`,
`Gate.tla`, `seeded`, `screen`, `grader`, `blind`, `rubric`, `step N`) returned
one hit, `PROBLEM.md:361`, "A check of your own, with its verdict, counts". That's
the ordinary English word in a sentence about the learner's own TLC run. The
harness is out of the learner's hands, so the vacuity probe's verdict isn't a
shortcut here.

The trace map records that sixteen validator modules landed under
`statement/traces/` during step 4 and were caught by reading the staged file list
rather than by the grep, because a `.tla` file carrying no forbidden word reads
clean (`author-notes/step4-trace-map.md:86-91`). The eight files above are what's
there now. I'd keep the staged-file read in the step 4 recipe on the strength of
that, since the grep can't see it.

## 1. Part A, the puzzle screen, written before the answers side

Shape D at representation 2 hands the learner no spec, so I ran Q1 and Q2 in
their first form. Q1 to Q8 all read **system**.

| # | reading | why |
|---|---|---|
| 1 | system | The English rules are given. Every action body, guard, `Observe` and `Spec` is the learner's. |
| 2 | decided | The state shape, the atomicity of file-and-close, and six of the seven formulas. |
| 3 | system | "Is this design correct", then a diagnosis of a green run. |
| 4 | system | The learner models, TLC checks. No search. |
| 5 | system | Abstraction choice. Whether the reading is state at all is the live one. |
| 6 | system | Several botanists, uncoordinated, and a determination can go stale between reading and landing. |
| 7 | system | Requirement 3's subscript and the last section's two questions both survive deleting TLC. |
| 8 | no | No optimum named. The "least that" lines at 307 to 311 size the instance. |

Two splits I'd rather write down than round off. Q1's action set arrives in prose
because §3.2 obliges it, and Q2 reads **given** on requirement 6's fairness, which
is named down to its target and its quantifiers at lines 263 to 268.

**KIND: ACCEPT, system.** Eight of eight.

**R, the route.** Intended: model the herbarium from prose, define `Observe`,
write six formulas, choose requirement 3's subscript, build `Spec` with fairness,
run TLC to 259 states, hold the model against the seven pairs, then diagnose the
handed formula.

Shortest route I found reaches the diagnosis half without the modeling half, by
inspection, in about two minutes. Read the paragraph under requirement 3 at lines
210 to 214, which says a step rule is only tested at steps that change what its
subscript watches and that subscripting over too little makes every other step
satisfy the rule for free. Then read requirement 4 at line 223, which declares its
subscript as the whole of `Observe`. Then read the shipped formula at line 341,
subscripted `_(Observe.slips)` on a rule whose antecedent is about `doubted`. One
requirement in the document carries a narrow subscript, it's the handed one, and
the mechanism has just been explained in bold.

The evidence bar doesn't close it either. The statement accepts "a behavior these
rules forbid that the formula above can't see, shown step by step" (line 361), and
pair 5's forbidden run is that behavior. States 3 to 4 of it clear a mark with
`slips` unchanged on both sheets, so the shipped subscript stutters past it. The
file is labeled "These two runs are about requirement 5".

The modeling half is untouched by that shortcut and it's the bulk of the work.
**ROUTE: ACCEPT**, on a narrower margin than I'd like, and the residue is in
section 5.

## 2. The representation frame, §9.7's own question

The reference carries five variables named `slips`, `consulted`, `reading`,
`accepted` and `doubted` (`reference/Herbarium.tla:9`), and `Observe` is the
identity over them (`:13-18`). The statement names the same five as `Observe`
fields. So the statement gives the reference's variables away one for one.

I don't think that's a step 4 defect. §3.3 pins the interface so grading can
compare values, and the reference author chose an identity `Observe`, which
`DESCRIPTION.md:353` fixes as a hard requirement of the rung ("The reference
carries five variables and they are the five `Observe` fields"). Any statement
over that interface leaks those five names. The statement mitigates it where it
can, at lines 132 to 134: "Your variables never leave your module. Pick whatever
state you like, in whatever shape you like."

If central wants that closed, it's upstream in the reference, not in the
statement. A step 4 rewrite can't reach it.

Three sentences go past the interface into the reference's decomposition. I'm
flagging them under §9.7's instruction to flag rather than to judge, and my read
on each follows.

- **`PROBLEM.md:166-169`**, "The accepted name is a field and not a reading of the
  slips. Carry it as a fact your filing step sets." This names both a variable and
  the action that writes it (`Herbarium.tla:45`). `DESCRIPTION.md:224-232` closes
  this fork on purpose, since deriving it makes requirement 2 true by
  construction. Worth the leak, and the statement gives the reason.
- **`PROBLEM.md:171-176`**, "`reading` is where it lives". Restates the interface
  shape already pinned at line 152. Mild.
- **`PROBLEM.md:88`**, "Filing closes that consultation", and **`:112-114`**, doubt
  not closing one. Both are atomicity boundaries in `File` and `Doubt`
  (`Herbarium.tla:46,56`). §3.2 obliges the statement to fix them.

Nothing else in the statement implies a data structure the section 5 forks leave
open. The forks at `DESCRIPTION.md:341-347` all survive the statement's wording:
slips as a set, a sequence or a map from stamp, the register as a count or a run
of events, the mark as a set of sheets or a flag per sheet.

## 3. The fields

The five `Observe` fields are stated as facts with their shapes pinned, and the
none marker is a declared constant set to a model value with the reason given
(lines 158 to 164). Field names match the reference's variables, which section 2
covers. No sixth field, no shape that forces a side of a section 5 fork.

One thing the statement adds that the description doesn't: the sentence at lines 143 to
145, "A renamed field, a sixth field, or a different spelling doesn't fail a
check. It keeps the check from ever running." That's honest about the grading
mechanism without naming it.

## 4. The pairs

Each pair reveals a target and not a representation. Traces render the five
fields and nothing else. No action name, no formula, no obligation name.

I worked each forbidden half against the seven requirements by hand, from the
learner set:

| pair | breaks | anything simpler |
|---|---|---|
| 1 | 1, range clause. A reading of stamp 2 at count 1 | also 3, since the count rose to 1 |
| 2 | 2. A slip on the sheet and no accepted name | no |
| 3 | 3. The count rises and nobody takes the stamp | no |
| 4 | 4. A consultation closes with nothing filed | no |
| 5 | 5. A mark comes off with no slip filed | no |
| 6 | 6. Two obligations left open forever | no |
| 7 | 7. Counts of 1 at the opening | no |

Six of the seven break their own requirement and nothing simpler. Pair 1 breaks
requirements 1 and 3 both, which the statement covers at lines 291 to 293. The
trace map already records that pair 1 witnesses the range clause and not
distinctness (`step4-trace-map.md:97-112`), so a learner whose requirement 1 misses
distinctness passes it. That's a gap in the oracle and it's carried forward on
purpose. I agree with carrying it.

## 5. The shape D object

The object ships what `DESCRIPTION.md` section 7 says: requirement 5 rendered with
its subscript narrowed from `_Observe` (`Herbarium.tla:132`) to `_(Observe.slips)`
(`PROBLEM.md:341`), plus the green run's four lines and two questions. Its wording
names no variable of anybody's model. It's a formula over `Observe` and nothing
else.

The rung block I was handed describes a different seed, the accepted-name rule
subscripted on the flag map. `DESCRIPTION.md:456-457` supersedes it with the doubt
rule on `Observe.slips`. I take the description as the authority, and the shipped
object matches it.

The defect is live. A step clearing a mark with no filing leaves `slips` alone on
every sheet, so the step stutters and the formula holds without looking. It isn't
blind everywhere, and that's worth the grader knowing: a step where sheet 2 gets a
filing while sheet 1's mark comes off without one does fire the subscript, and the
consequent then fails at sheet 1. The blindness is exactly the steps where no
sheet is filed on.

**The finding the author's own screen didn't make.** `DESCRIPTION.md:466-470`
argues the seed is fair because requirement 4 sits one line up and opens on a step
where a slip appears, "so watching `Observe.slips` reads as the natural thing to do
there. The defect is that subscript copied one line down." That camouflage isn't
in the shipped statement. `PROBLEM.md:223` declares requirement 4's subscript as
the whole of `Observe`, so the learner has no line-above precedent for a narrow
one. The design's stated cover is gone, and what's left in its place is a contrast
that points at the seed.

I don't think a reword closes it. Form 1 leaves one subscript open and gives the
rest, so requirement 4's has to be stated. The tell is structural, and it belongs
to the pairing of form 1 with a subscript-shaped diagnosis object rather than to
anybody's wording. That pairing is the same one `DESCRIPTION.md:488-491` picks on
purpose, since the rung's one new high and its seeded defect are meant to be the
same thing. My read is that the cost of that choice landed here and nobody costed
it.

The step 4 report is where I'd put the second half of this. `step4-screens.md:161-163`
says "What isn't guessable is the last section, which asks about a formula whose
subscript is the one thing the statement never explains." Four lines further
down, the same report says the subscript-semantics sentence under requirement 3 is
"the same lens the diagnosis needs, and I put it there on purpose"
(`:165-167`). Both can't be right. The statement does explain what a subscript
does, in the paragraph that argues for keeping it.

## 6. Defects

**D1. The fairness target is handed over, and it wasn't obliged.**
`PROBLEM.md:263-268` names weak fairness, per botanist, per sheet, on the filing
step, and then rules out the two wrong forms at 270 to 273. That's
`Herbarium.tla:66` in prose, quantifiers and all. `step4-screens.md:142-143` calls
it obliged by "the rung's kind-3 sentence", and I read that sentence differently.
`V2-PLAN.md:302` defines kind 3 as "At least one `<>` or `~>` formula, plus a
fairness conjunct in `Spec`", which is a counting rule over the reference. It says
nothing about what the statement discloses.

Nor does form left open move. `V2-PLAN.md:341-342` scopes form to the keyword, the
kind, the subscript, and whether the rule can be stated over the interface at all.
A fairness conjunct in `Spec` is none of those, so withholding the target leaves
the vector at 1.

Rule 7 at lines 121 to 127 already fixes the system's fairness semantics for §3.2.
The paragraph at 257 to 273 goes past that into the TLA+ construct. Cutting it
back to "requirement 6 is false over a system that lets a botanist sit on a
consultation forever, and rule 7 says they can't, so your `Spec` has to say so
too" leaves §3.2 discharged and puts kind 3 back in the learner's hands.

Where the fix lives: the statement. A reword closes it.

The live alternative is to keep the paragraph. `step4-trace-map.md:156-161` records
that every weakening of the fairness form passes at this instance, `WF_vars(Next)`
included, because the handling allowance makes every behavior finite. So a learner
who guesses wrong gets a green run and no signal. That's the world where keeping
it wins, and it's a real one for a learner who bounced off an earlier rung. I'd
still cut it, because the same argument applies to requirement 3's subscript and
the rung withholds that one anyway. Green meaning nothing is the lesson this rung
is built on.

**D2. The subscript-semantics paragraph pre-clears the diagnosis.**
`PROBLEM.md:210-214`. Named as deliberate at `step4-screens.md:165-171`, so this is
a disagreement rather than an oversight. The author's case is that a learner off
learntla ch. 11 knows what `[][A]_v` means, so the sentence adds salience and not
capability. I think salience is the whole of what the diagnosis costs here. The
learner isn't being asked to derive subscript semantics. They're being asked to
notice that one formula's subscript is too narrow, and this paragraph tells them
that too-narrow subscripts are the thing to look for.

Where the fix lives: the statement. Cut from "A step rule is only tested" to "TLC
won't warn you", which is lines 210 to 213, and keep "The subscript is yours to
choose" with "Work out what this rule has to watch". That leaves form 1 resting on
the reading gate, which is the author's own named alternative.

**D3. Pair 5's forbidden run is the diagnosis evidence, pre-labeled.** Not a
defect I'd send back, and I'm recording it because it compounds D1 and D2 rather
than standing alone. `step4-trace-map.md:135-148` and `step4-screens.md:175-180`
both reach it first and both argue the reading still has to happen by hand. I
agree with that as far as it goes. §3.9 obliges the pair, TLC never shows the run
to the learner, and their own model rules it out. What I'd add is that the
statement names pair 5 as being about requirement 5, so the learner doesn't have
to find the pairing either.

## 7. The grading split

For each requirement, what carries it against what passes this instance without
carrying it. Step 6's spread rule consumes this.

| req | carries it | passes without carrying it |
|---|---|---|
| 1 | Range, distinctness, the reading's range, and the allowance cap, all four | Range plus allowance and no distinctness clause. Pair 1 can't tell them apart |
| 2 | Top slip by stamp, with the empty case answering `None` | Anything derived from the slips inside `Observe` itself. That's `TRUE` in a costume |
| 3 | Subscripted over `Observe`, or over `slips`, `consulted` and `reading` together | Subscripted on `Observe.slips` alone. Still catches pair 3's twin, since a filing moves the slips, so it's wrong without being blind |
| 4 | Both directions, the way in and the way out, over the whole of `Observe` | The way in alone. Pair 4's twin is a way-out violation and catches it, so this one is graded |
| 5 | Not the learner's. Handed | n/a |
| 6 | Both clauses under one name, on one cfg line | Either clause alone. The first passes a model where filing leaves the mark on |
| 7 | Under `PROPERTIES`, read at the opening state | Under `INVARIANTS`. Passes here and means something else |

**At kind 3, what counts as the fairness being right.** `\A b \in Botanists, s \in
Sheets : WF_vars(FileStep(b, s))`, with the name quantified inside the fairness
and not outside it. Three ways to fall short, and none of them shows up in a run:

- `WF_vars(Next)`, or fairness over a disjunction of one botanist's actions.
- `\A b, s, n : WF_vars(File(b, s, n))`, which obliges each name separately.
- No fairness conjunct at all, which is the only one requirement 6 catches.

`step4-trace-map.md:156-161` measured the first two passing at this instance. So
the fairness has to be graded off the submitted `Spec` text, never off a verdict.

**On the diagnosis object.** Naming it is saying the subscript is too narrow to
see a mark clearing without a filing. Establishing it is exhibiting the step,
either as pair 5's states 3 to 4 read against the formula by hand, or as the
learner's own check with a verdict. Given D2, I'd weight the naming half at close
to nothing on this rung and put the marks on the establishing half.

## 8. The vector citations

Six rows, all resolving. `bash harness/test-vector.sh` ends `OK: 33 assertions
passed`.

- representation 2: `PROBLEM.md:23` ("No spec ships"), `:131`, `:147-156`, and
  `Herbarium.tla:9`. Resolves.
- property kind 3: `Herbarium.tla:66,136,138`, `Herbarium.cfg:22`. Resolves.
  `V2-PLAN.md:302` is the band.
- property count 2: `Herbarium.cfg:12-22` holds three `INVARIANTS` lines and five
  `PROPERTIES` lines, so eight. `V2-PLAN.md:308` bands five to nine at 2. Resolves.
- step sources 1: `PROBLEM.md:41-48`, `Herbarium.tla:58-61`. All three disjuncts
  quantify over `Botanists` and nothing else acts. Resolves.
- state space 0: `step2-variants.md:140` reads 1,103 generated and 259 distinct at
  depth 7, and `:144` reads 0.97 s, 0.99 s and 0.96 s over three runs.
  `PROBLEM.md:324-325` carries the same numbers. Resolves.
- form left open 1: `PROBLEM.md:194,200,210,223,228,235,242` are the seven
  keyword-and-kind lines. One subscript open at 210, one given at 223, one shipped
  at 228. Resolves.

## 9. Verdict

**SHIP after D1.**

D1 is a reword inside `PROBLEM.md` and it gives the rung back one of the two
things kind 3 is for. I'd take D2 with it, since the two paragraphs cost the same
kind of thing and the fix is the same size, but D2 is a disagreement with a call
the author made on the record and central may prefer to keep it.

D3 needs no action.

The finding in section 5 needs no action at step 4 and can't get one. It belongs
in the step 6 brief and in the grader's notes: the seed is findable by inspection
on this statement, so weight the establishing half.
