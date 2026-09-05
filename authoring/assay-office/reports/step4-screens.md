# assay-office step 4, screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/assay-office/statement/PROBLEM.md`.
Bead `tla-h2cg.10`, shape B at form 0, rung 4 of batch 2. The domain cleared
step 0 before the reference was written. This run asks whether my wording kept
it clear, which passing once does not settle (§5.7b). Both screens ran on the
statement as delivered, not on a draft.

I recorded my answers before reading rung 1's. There is no prior screen of this
statement to have read, but the order is worth stating anyway.

## §5.7, mechanism collision

Two runs of `harness/screen.sh --name AssayOffice`, both phrasings taken from
the statement's own words. Verdicts pasted.

```
=== CANDIDATE: an assay office where officers test lodged wares against a fineness standard and strike or deface each one
--- step 1: NAME collision
    query: 'AssayOffice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: a finding once written down never changes, and a ware found substandard is eventually defaced because the office is obliged to act
--- step 1: NAME collision
    query: 'AssayOffice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Neither run fired the `warehouse|robot` map row that rung 1's step 0 report
recorded (`authoring/bonded-store/reports/step0-screens.md:276-286`). That row
belongs to the bonded store's domain and not to this one. A grep for
"warehouse" over the whole learner set returns nothing, so the row has no word
to fire on here.

The tool derived no mechanism from either phrasing, and its own output says
that is not a clean bill. So, named by hand: **a verdict against a fixed
standard that compels an irreversible act on the thing judged.** The ware's
identity survives the whole lifecycle and its physical form doesn't. The duty
runs one way, from the finding to the act, and the office can't record a
failure and then sit on it. That is the same naming step 0 gave it
(`reports/step0-screens.md:124-128`), and my statement didn't move it.

Why the nearest burned mechanisms don't fit:

- **Resource allocator**: needs contention over something finite. Nothing here
  is scarce, and no officer waits on another.
- **Two-phase commit**: needs a vote across parties and an abort path. One
  officer's finding is neither, and there's no way to abort a finding.
- **Reachability**: nothing is searched for. The question is whether the
  office's moves are lawful and its duty discharged, not whether a state is
  reachable.

CLEAR, with the mechanism named by hand rather than by the tool.

## §5.7b, the puzzle screen, spec-in-hand form

Shape B hands the learner a spec, so Q1 and Q2 are answered in their second
form, about requirements. Q3 to Q8 as written.

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The formulas, the vocabulary they range over, and one reading of the spec.** The learner has to find the module's three names for the finding, quantify over the ware set, build an antecedent that compares a ware at two moments, and read `FairSpec` to see what carries rule 4's duty. |
| 2 | Requirements given as formal claims, or decided? | **Given, and I'm counting this as a puzzle row.** Form 0 hands over the keyword, the kind and the subscript. Each stated rule maps to one fairly obvious formula in a vocabulary the artifact supplies. That's the rubric's own tell. |
| 3 | What is asked? | **Is this design correct.** State what must hold and check it. No goal state, no reachability. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** 125 states is nothing to search. |
| 5 | Where does the difficulty live? | **Rendering, plus one reading the earlier rungs don't have.** Turning "a substandard finding is discharged" into a leads-to, and knowing why the cfg has to name `FairSpec`, is where the work sits. |
| 6 | Agents, fallibility, interleaving? | **Several of one kind, and they interleave.** Two officers, uncoordinated, either one able to act on any ware. Nothing can go wrong for them, so I claim half this row rather than all of it. |
| 7 | Delete TLC, decision left? | **Yes.** That rule 4 needs a temporal formula rather than an invariant, and that the obligation lives in the fairness conjunct rather than in `Next`, is defensible on paper. |
| 8 | Names an optimum? | **No.** |

**KIND: ACCEPT, system.** One puzzle row of eight, against a threshold of
three. Rung 1 scored two, and the row this rung gets back is Q6. Step sources
1 puts two interleaving officers in the room where rung 1 had one keeper.

Q2 stays a puzzle row for the same reason it did at rung 1. Form 0 is what
makes this a rung rather than the next one, and raising it is rung 5's
business.

Q5 and Q6 both moved, and I want to be careful about how much I claim for
that. Q6 is a real change in the artifact. Q5 is a change in what the learner
has to read, not in what they have to invent, and I'd not call it abstraction
choice in the sense the rubric means.

## R, the route

**Intended route.** Read the module to find the three names it gives the
finding. Write requirements 1 and 2 as formulas over `Observe`, under the
keyword and in the kind the statement names. Read `FairSpec`, see the fairness
conjunct on the defacing step, write requirement 3 as a leads-to, and declare
`SPECIFICATION FairSpec`. Run TLC. Then check the three pairs by hand.

**Probes.**

- **Tiling.** The statement numbers three requirements and ships three pairs,
  one to one, and it says the pair count outright
  (`statement/PROBLEM.md:171-172`). So the pair count carries no arithmetic a
  learner can mine. The reference cfg's fourth line is `TypeOK`, which the
  learner never sees and is never asked for.
- **Vocabulary absence.** "Hallmark", "fineness", "alloy", "maker" and
  "lodged" appear in the prose and nowhere in the module
  (`grep -o -i` over `statement/AssayOffice.tla` returns none of the five).
  Unlike qsl, those absences mark nothing the learner has to find. All three
  requirements are carriable over the interface, and the two ungraded rules
  (who acts, and rule 5's absence of an obligation) are ungraded by
  construction. So I left out qsl's "not everything the rules say can be
  written over the interface" sentence on purpose, as rung 1 did.
- **Elimination.** Requirement 1 is the only `INVARIANT` and requirements 2
  and 3 are the only `PROPERTY` lines. At form 0 that's stated rather than
  inferable, so it isn't a route.
- **Answer form.** The task fixes the interface, the keyword, the kind and the
  subscript before the learner has read a rule. That is the largest narrowing
  in the artifact, and it's the rung's definition rather than a leak.
- **Pre-clearing.** Two passages. The subscript warning under requirement 2
  explains a given rather than hinting at a hidden one, since the subscript is
  stated two lines above it. The `SPECIFICATION Spec` warning under
  requirement 3 does the same for the cfg. Both advertise their neighbourhood,
  and at form 0 there's nothing left in either neighbourhood to find. Step 2
  finding 5 measured what ignoring the first one costs.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, and no prior
  spec found to crib a property list from, as far as I searched.

**Shortest route found.** Look up the three finding names, write requirements
1 and 2 straight from their English, write requirement 3 as a leads-to from
its English, and declare `SPECIFICATION FairSpec` because the statement says
to. Run TLC once. The pairs confirm.

**Does it use the judgment the problem is for?** Yes, thinly, and thinner than
I'd like on the liveness. Rung 4's judgment is meant to be reading a shipped
spec for where an obligation lives. My statement names the specification line
outright, so a learner can get a green run without ever opening `FairSpec`.
What they can't skip is the leads-to itself. A blanket "every ware is
eventually defaced" is false at this instance, so the antecedent has to come
from the requirement's English, and getting there is the kind decision the
rung teaches.

I thought about withholding the specification line and leaving the learner to
find that `Spec` fails. I'd not take that trade. Form 0 says every requirement
names its keyword and kind, and a cfg line the learner has to guess is a form
decision wearing a different hat. It would also make the first run fail for a
reason that looks like a bad formula, which is the feedback shape §3.7 rules
out. So the line stays, and rung 5 or later is where the fairness read gets
put to work.

**Where the residue lives.** In the artifact. The three finding names live in
the module and nowhere else, so the one lookup can't be worded away, and it
shouldn't be.

**ROUTE: ACCEPT**, thinly. The lever that would widen the margin is form 1,
which is a different rung.

## The transcription question, answered plainly

The rung block asks for this explicitly: shape B means the learner gets the
spec, so the description's section 5 required the spec's own variables not to
be the field names. Here is my read of whether that held.

**It held, and it's a real defence rather than a formality.** The module
declares one variable, `book`, a function from ware to a record of `verdict`,
`struck` and `damaged` (`statement/AssayOffice.tla:41,45-48`). `Observe`
renames all three and reshapes the record-of-fields into a
field-of-functions. So a learner writing `Observe.finding[w]` has crossed from
the spec's state to the graded interface, and the crossing is visible work
rather than an identity.

That is stronger than rung 1 had. There `Observe` was the identity over the
state, field for field, and the step 4 author said so plainly
(`authoring/bonded-store/reports/step4-screens.md`, the transcription
section). This rung's separation is what the description asked for and what
the reference author delivered, and step 2 read it the same way
(`reports/step2-variants.md:154-157`).

Two smaller things survive alongside it. The shipped module carries no
property at all after the strip, so neither the action property nor the
leads-to has a model in the text to copy. And the three finding names are
withheld from the statement on purpose, with the trace pairs printing the
findings in the rules' English, so the one lookup stays a lookup the learner
has to make.

## Two places where my statement departs from its brief

Both are cases where the brief and the measurement disagreed, and I went with
the measurement. Recording them rather than quietly adapting.

**1. I left out the "fairness on the whole next-state relation is not what the
rule means" sentence.** The kind-3 boilerplate asks for it. It's measured
false at this instance. Step 2 ran `FairSpec == Spec /\ WF_vars(Next)` as P04
and the per-officer disjunction as P05, and both came back rc=0
(`reports/step2-variants.md:288-289`). Step 2 finding 4 says the same thing
and recommends cutting the clause from the description. The learner writes no
fairness here in any case, so the sentence would have been a claim about this
instance that the instance refutes. What the statement says instead is why a
next-state relation can't carry an obligation at all, which is the teaching
content the boilerplate was after and is true.

**2. The quiescence sentence.** The brief's note says the statement should say
the office goes quiet before every at-standard ware is struck, since striking
is optional. That's wrong about the model. While an at-standard unstruck ware
exists the strike branch is enabled, so there's no deadlock there. I ran the
stripped module with deadlock checking on and no `CHECK_DEADLOCK` line, and
TLC reported the deadlock at a state with all three wares at standard and
struck (`harness/verdict.sh -t 300 -d`, rc=11, `DEADLOCK`). So the statement
says quiescence arrives once every ware is tested, every at-standard ware
struck and every substandard ware defaced. An unstruck at-standard ware can
still sit forever, but that's a stuttering behaviour rather than a deadlock,
and it isn't what the cfg line is for.

## Verification behind the shipped artifacts, in one block

- FREEZE check: `sha256sum` over `reference/AssayOffice.tla` and
  `reference/AssayOffice.cfg`, both matching `reference/FREEZE.sha256` by eye,
  before anything was derived.
- Strip: the learner spec is the frozen reference minus exactly the four
  obligation operators. `diff` against the reference shows three hunks, the
  define-block copy at lines 16 to 36, the two translation checksums, and the
  translated copy at lines 71 to 91. Nothing else moved. The strip was made on
  a staged copy outside `reference/`, with `pcal` re-run there.
- Count: the same `SPECIFICATION Spec` cfg run against a scratch copy of the
  reference and against the stripped module, both through
  `harness/verdict.sh -t 300 ... -- -workers 1`. Both `OK` at rc=0, both 601
  states generated, 125 distinct, depth 7. That matches step 2's counts
  (`reports/step2-variants.md:180`).
- The learner's route: the stripped module with the reference's three graded
  obligations appended below the translation, under a cfg naming
  `SPECIFICATION FairSpec` and declaring them, comes back `OK` at rc=0 with
  601 generated and 125 distinct. The same module under `SPECIFICATION Spec`
  comes back `LIVENESS_VIOLATION` at rc=13 on `SubstandardIsDefaced`, which is
  what the statement's warning describes.
- Violating traces: S12, S04 and P03 re-run from the committed variant
  modules through `harness/verdict.sh -t 300` with `-workers 1`. rc 12, 13 and
  13, and the obligation and trace length each match step 2's table.
- Satisfying traces: hand-built, then machine-validated against the stripped
  learner spec by a trace-forcing scratch module. Three of three came back
  rc=12. An illegal control came back rc=0, so the check can fail.
- `harness/test-vector.sh`: this package's record passes. Four sibling records
  fail as missing files, which are rungs whose `VECTOR.md` isn't written yet
  and aren't mine.
