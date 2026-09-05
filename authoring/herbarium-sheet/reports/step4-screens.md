# herbarium-sheet step 4, screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/herbarium-sheet/statement/PROBLEM.md`.
Bead `tla-h2cg.12`, rung 6 of batch 2, shape D at form left open 1. The domain
cleared step 0 before the reference was written. This run asks whether my wording
kept it clear, which passing once doesn't settle (§5.7b). Both screens ran on the
statement as delivered, not on a draft.

I wrote my own answers down before re-reading step 0's. There's a prior screen of
this domain, so the order matters more here than it would for a first-time
candidate.

## §5.7, mechanism collision

Two runs of `harness/screen.sh --name Herbarium`, both phrasings lifted from the
statement's own words. Verdicts pasted.

```
=== CANDIDATE: botanists filing determination slips on a herbarium sheet whose accepted name is the highest stamped slip
--- step 1: NAME collision
    query: 'Herbarium language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: an append only record of determinations on one card where a doubtful mark comes off only when a new slip is filed
--- step 1: NAME collision
    query: 'Herbarium language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Neither run fired on the word warehouse, and the statement doesn't use it. My
brief said to record step 0's reason if that row fired. It didn't, and step 0's
report carries no warehouse note to cite either, so there's nothing to carry
forward on that.

The tool derived no mechanism from either phrasing, and says itself that a CLEAR
on that footing isn't a clean bill. Named by hand: **the mechanism is a grow-only
annotation set over one shared record, whose published value is a maximum over an
ordering key the writer supplies rather than over the order of writing.** The
write never conflicts. The reading does.

That's step 0's naming, and I reached the same words from the statement rather
than from the domain sketch, which is what this second run is for. Why the
nearest burned mechanisms don't fit is unchanged, and I'd add nothing to step 0's
argument except to say the statement doesn't drift toward any of them. A
last-writer-wins register exists to reconcile divergent replicas, and there's one
sheet with no copies and nothing to converge. Snapshot isolation keeps several
versions so a reader sees a consistent one, and here everybody sees the same card.
Optimistic concurrency needs a cell to compare and swap, and a slip that loses is
still on the sheet.

Step 0 recorded the plain reading of S6 as BURNED on the corpus, with the tool
silent because its `mechanism_map()` has no row from S6 vocabulary. That finding
is about the tool rather than about this wording, and my two runs reproduce the
same silence for the same reason.

CLEAR, with the mechanism named by hand rather than by the tool.

## §5.7b, the puzzle screen

The rubric assigns shapes B, C and D to the requirement-centric second form of Q1
and Q2, on the stated grounds that all three hand the learner a spec
(`harness/PUZZLE-SCREEN.md:84`). **This problem is shape D and ships no spec.**
The learner writes the model from prose and then diagnoses one handed formula and
its green run, which is shape D at representation 2. So the rubric's grounds don't
hold here. My brief told me to use the spec-in-hand form, and rather than round
the mismatch off I've answered both forms, the same way rung 3 did.

| # | Question | My answer |
|---|---|---|
| 1, action form | Legal moves in hand, anything left to model? | **The actions themselves.** No spec ships. The rules are prose about sheets, benches and slips, and the learner decides what a step is, what state carries it, and whether the slips are a set, a sequence or a map from stamp. |
| 1, requirement form | Rules and the green run in hand, anything left to model? | **The requirements and the run's reach.** Six of the seven have to be written from English over an interface that doesn't exist until the learner builds it. What the seventh's green run establishes is the learner's to argue. |
| 2, action form | Actions given by the domain, or decided? | **Decided.** Rule 2 says a consultation hands over a stamp and stays open. Whether that's one action or two, whether the register is a count or a run of events, and whether the doubter is recorded at all are the learner's calls. |
| 2, requirement form | Requirements given as formal claims, or decided? | **Mostly given, and I won't pretend otherwise.** Form 1 hands over keyword and kind for all seven, and two of the three action properties get their subscript as well. One subscript is withheld and one formula ships written. I score this a puzzle row. |
| 3 | What is asked? | **Is this design correct.** Two questions in fact: is my model right, and did that green line check anything. No goal state and no reachability. |
| 4 | Who works once it compiles? | **The learner models and diagnoses. TLC checks.** TLC returns OK on the shipped formula against a correct model, which is the whole problem. |
| 5 | Where does the difficulty live? | **Abstraction choice, then reading a green verdict.** 259 states is nothing. The work is whether the reading is state, whether the accepted name is stored, and what a passing action property watched. |
| 6 | Agents, fallibility, interleaving? | **Several, of one kind, interleaving.** The order two botanists consult in decides whose determination stands. Nobody coordinates, and a botanist can file a name that was current when they read the sheet and isn't when it lands. |
| 7 | Delete TLC, decision left? | **Yes.** Whether the accepted name can be derived from the slips is a paper argument and it comes out no. So is whether requirement 6's fairness can go on the whole next-state relation. |
| 8 | Names an optimum? | **No.** |

**One puzzle row of eight**, and it's Q2 in requirement form. The threshold is
three for every task shape (`harness/PUZZLE-SCREEN.md:133`), so this sits under it
with room.

The one row deserves more than a wave. Form 1 is a rung setting rather than a
wording accident, and it's the rung's single new high. Giving the keyword and the
kind for every requirement is what the level means, and it does hand the
requirements over as formal claims to that extent. What keeps the problem a system
is that the formulas still get written over an interface the learner built, against
state the learner chose, and that one subscript and the last section ask questions
no keyword answers.

The transcription tell (`harness/PUZZLE-SCREEN.md:109-112`): does every stated rule
map to one obvious formula in a vocabulary the artifact already supplies? **No, and
that's the load-bearing answer.** The artifact supplies no vocabulary past the five
`Observe` fields. Requirement 3's provenance clause reads a botanist's open
consultation across a step, which only exists if the learner decided the reading is
state. Rule 3's equality and "every step is a botanist's" have no property form over
the interface at all, and the statement says so without saying which formula to skip.
A learner transcribing here would be transcribing from a model they haven't written.

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Read the seven rules. Decide a state shape, and decide in
particular that what a botanist read is part of it and that the accepted name is
stored rather than derived. Render `Observe` over it. Write requirements 1 to 4, 6
and 7 under the keywords and kinds the statement names. Choose requirement 3's
subscript. Write requirement 6's fairness per botanist and per sheet on the filing
step. Run TLC, hold the model against the seven pairs in both directions, then add
the shipped formula and read what its subscript lets through.

**Probes.**

- **Tiling.** The seven pairs tile the seven requirements one to one, and the
  statement says so. That's §3.9 by construction rather than a leak. No model
  ships for them to tile, and they carry no state shape, no kind, no subscript
  and no fairness.
- **Vocabulary absence.** "Bench", "flora", "loan request" and "conservation
  listing" run through the rules and have no field. So does the filer's name.
  Working out which rules the interface can carry is a judgment target here rather
  than a seeded gap.
- **Elimination.** Requirement 6 is the only one the statement calls a claim that
  something eventually happens, and rule 7 already says it's the one thing that
  must happen. Nothing is eliminated that wasn't already given.
- **The answer form.** The live one, and I'll come back to it below. Three
  decisions arrive before the learner has thought about the domain: the five
  interface fields with their shapes, the instruction to store the accepted name,
  and requirement 6's fairness target. The first is obliged by §3.3, the second by
  §7 of the description, and the third by the rung's kind-3 sentence.
- **Pre-clearing.** Two passages. The two ungraded rules under the requirement
  list, and the note that a forbidden run can break more than one requirement.
  Both are required honesty. Neither points at a neighbourhood.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, no prior spec
  found to crib a property list from.

**Shortest route found.** Take the five interface fields as the state. Write six
actions from the rules. Write the six requirements from their English under the
keywords and kinds the statement names, copy requirement 6's fairness from the
paragraph that names it, and subscript requirement 3 over the whole of `Observe`
because that's what the two neighbouring requirements say. That reaches a green
run without deciding much, and it's shorter than the intended route by the
representation and the fairness target.

**Does it use the judgment the problem is for?** For what's left, yes. The learner
still writes a transition system from prose, with several botanists interleaving
and every guard chosen. Requirement 3's subscript is guessable from its
neighbours, and I'd rather say so than claim it isn't. What isn't guessable is the
last section, which asks about a formula whose subscript is the one thing the
statement never explains.

**The one I want on the record.** The subscript-semantics sentence under
requirement 3 is the same lens the diagnosis needs, and I put it there on purpose.
Withholding it makes the open subscript unfair, since form 1 asks the learner to
choose one and nothing else in the statement says what a subscript does. Writing it
down adds salience rather than capability, because a learner off learntla ch. 11
knows what `[][A]_v` means whether or not I repeat it. My read is that the salience
cost is worth paying, and the live alternative is to cut the sentence and let form
1 rest on the reading gate alone. That's the call I'd take on a rung where the
diagnosis object wasn't a subscript, and this is exactly the rung where it is.

**Where the residue lives.** Pair 5's forbidden run is a mark coming off with no
slip filed, which is the class of step the shipped formula can't see. The trace map
carries the argument. Short version: the pair puts the behaviour in front of the
learner and TLC never shows it to them, so the reading still has to happen by hand.
§3.9 obliges the pair, and I don't think a rewording removes the residue without
dropping a requirement's oracle.

**ROUTE: ACCEPT.** The shortest route I can find is shorter than the intended one
at three points, and all three are obliged by the rung rather than by my wording.
What remains is the whole transition system and a diagnosis no keyword answers.

## On transcription, and on the rewrite

I didn't have to rewrite the statement to pass either screen, so there's no
agents-and-fallibility pass to report. Several botanists, no coordination, and a
determination that can be current when it's read and stale when it lands were in
the rules before I started, and they're what carries the system verdict.

The learner's remaining job here isn't transcription. The complete set of legal
moves is in the statement, because §3.2 requires it, but a set of legal moves
stated in English isn't a spec. Nothing ships that TLC can run, so every action
body, every guard, `Observe` and the whole of `Spec` have to be decided and
written before the first check goes green.

## Verification behind the shipped artifacts, in one block

- FREEZE check: `sha256sum` over `reference/Herbarium.tla` and `Herbarium.cfg`,
  both matching `FREEZE.sha256` by eye, before anything was derived. Nothing under
  `reference/` was touched after.
- Reference run: `harness/verdict.sh -t 300 --config Herbarium.cfg Herbarium.tla
  -- -workers 1` over a scratch copy. `OK` rc=0, 1,103 generated, 259 distinct,
  depth 7, which reproduces step 2's counts exactly.
- The shipped formula: P01 from `reports/step2-variants/`, run the same way.
  `OK` rc=0, 1,103 generated, 259 distinct, depth 7. That run is the block pasted
  into the statement's last section.
- Violating halves: the seven shortlisted variants copied to scratch and run
  through `harness/verdict.sh -t 300 ... -- -workers 1`. All seven came back on
  the rc and the obligation step 2's results table records. Trace states are parsed
  out of those runs rather than retyped.
- Satisfying halves: hand-designed as mirrors of their twins, then machine-validated
  against the frozen reference by a trace-forcing scratch module. Seven of seven
  rc=12 at the full length. A control trace that files a slip with nobody holding a
  consultation came back rc=0, so the validator can fail.
- `harness/test-vector.sh`: `OK: 33 assertions passed`.

**One discrepancy, and I'm recording it rather than adapting to it.** Step 2
measured the reference at 0.97, 0.99 and 0.96 s wall around `verdict.sh`, with
TLC's own figure at `Finished in 00s`. Three runs on this box came back at 1.45,
1.65 and 1.59 s, with TLC's own figure at `Finished in 01s`. That straddles the
1 s boundary between state space 0 and 1. I've kept the level at 0 and cited step
2's measurement, because the distinct count is the rubric's check and 259 sits
well under the 1,000 ceiling, and because TLC's internal figure never reaches a
second of search. My hunch is the difference is load on this machine rather than
anything about the spec, and it's worth a second reading if the level is ever
questioned.
