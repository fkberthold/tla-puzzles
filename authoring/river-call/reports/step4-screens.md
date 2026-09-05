# river-call step 4 — screens on the statement as worded

Written under V2-PLAN.md §9.6 against `authoring/river-call/statement/PROBLEM.md`.
Bead `tla-h2cg.9`, rung 3 of batch 2, shape D at form 0. The domain cleared step 0
before the reference was written. This run asks whether my wording kept it clear,
which passing once does not settle (§5.7b). Both screens ran on the statement as
delivered, not on a draft.

I wrote my own answers before re-reading step 0's. There is a prior screen of this
domain, so the order matters more here than it did for a first-time candidate.

## §5.7 — mechanism collision

Two runs of `harness/screen.sh --name RiverCall`, both phrasings lifted from the
statement's own words, verdicts pasted:

```
=== CANDIDATE: several ditch owners each setting their own headgate on one stream, with a call from a short senior stopping a junior from opening wider
--- step 1: NAME collision
    query: 'RiverCall language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: a fixed order of rights over one limited supply where every party applies the order to itself and nobody grants anything
--- step 1: NAME collision
    query: 'RiverCall language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing and says itself that isn't a
clean bill. Neither run fired on the word warehouse, and the statement doesn't use
it, so step 0's recorded reason for that row never came up.

Named by hand: **the mechanism is a static seniority order over self-served draws
from a shared limited flow, where a shortfall at any senior forbids a junior from
drawing.** The order is fixed before anybody acts, it never changes, and every
party applies it to themselves.

That's step 0's naming, and I reached the same words from the statement rather
than from the domain sketch, which is the thing this second run is for. Why the
nearest burned mechanisms don't fit is unchanged. A queue orders by arrival and
serves in that order, and here the order is fixed in advance and nobody is served.
The Resource Allocator has a coordinator that grants and clients that wait, and
there's neither. Priority scheduling is the closest neighbour I can name, and it
still needs a dispatcher choosing what runs next.

One thing the statement adds that the domain sketch didn't have. The call is a
second piece of state the learner has to decide the shape of, and it's what makes
requirement 4 a step rule with its own guard. I don't think it moves the mechanism
naming. It does mean a reader who searches for water rights alone will miss the
part of this problem that has any weight in it.

`gh api -X GET search/code -f q='prior appropriation language:tla'` returned 0 at
step 0. I didn't re-run the hand probes, since the corpus question is about the
domain and the domain hasn't changed.

## §5.7b — the puzzle screen

The rubric assigns shapes B, C and D to the requirement-centric second form of Q1
and Q2, on the stated grounds that all three hand the learner a spec
(`harness/PUZZLE-SCREEN.md:84`). **This problem is shape D and ships no spec.** The
learner writes the model from prose and then diagnoses a handed green run, which
is shape D at representation 2. So the rubric's grounds don't hold here, and I've
answered both forms rather than picking one and rounding the mismatch off. My brief
told me to use the spec-in-hand form, and I'm recording the mismatch instead of
adapting to it silently.

| # | Question | My answer |
|---|---|---|
| 1, action form | Legal moves in hand, anything left to model? | **The actions themselves.** No spec ships. The rules are prose about gates, decrees and calls, and the learner decides what a step is, what state carries it, and whether shortness is stored or worked out. |
| 1, requirement form | Rules and the green run in hand, anything left to model? | **The requirements and the run's reach.** The run is four green lines and a state count. What it establishes is the learner's to argue. |
| 2, action form | Actions given by the domain, or decided? | **Decided.** Rule 3 gives a range, not a step. Whether a gate move is one action or two, and whether two owners can move together, are the learner's calls. |
| 2, requirement form | Requirements given as formal claims, or decided? | **Given, and I'm not going to pretend otherwise.** Form 0 hands over keyword, kind and subscript for all four. This is the one puzzle row on the board, and the ramp put it there. |
| 3 | What is asked? | **Is this design correct.** Two questions in fact: is my model right, and did that green run check anything. No goal state, no reachability. |
| 4 | Who works once it compiles? | **The learner models and diagnoses. TLC checks.** TLC returns OK on the seeded instance, which is the whole problem. |
| 5 | Where does the difficulty live? | **Abstraction choice, then reading a green verdict.** 136 states is nothing. The work is what shortness ranges over and what a passing run is worth. |
| 6 | Agents, fallibility, interleaving? | **Several, of one kind, interleaving.** The order the owners open in decides who goes short. Nobody enforces anything, so a junior can sit in water a senior now wants. |
| 7 | Delete TLC, decision left? | **Yes.** Whether the priority rule can be an invariant at all is a paper argument, and it comes out no. So is whether a flow of 6 exercises anything. |
| 8 | Names an optimum? | **No.** |

**One puzzle row of eight**, and it's Q2 in requirement form. The threshold is
three for every task shape (`harness/PUZZLE-SCREEN.md:133`), so this is under it
with room.

The one row is worth sitting with rather than waving past. Form 0 is a rung
setting, not a wording accident. It's the lowest form level on the ramp and it
exists so the learner spends their judgment on the model and the diagnosis instead
of on keyword choice. That does hand the requirements over as formal claims, and
the rubric is right to score it a puzzle row. What keeps the problem a system is
that the formulas still have to be written over an interface the learner built,
against state the learner chose, and the last section asks a question no keyword
answers.

The transcription tell (`harness/PUZZLE-SCREEN.md:109-112`): does every stated rule
map to one obvious formula in a vocabulary the artifact already supplies? **No, and
that's the load-bearing answer.** The artifact supplies no vocabulary at all past
the two `Observe` fields. Requirement 4 reads shortness, which is not a field and
has to be built from the settings, the flow and the decrees before it can be
written. Rules 3 and 8 have no property form over the interface in any vocabulary,
and the statement says so without saying which formula to skip. A learner
transcribing here would have to transcribe from a model they haven't written yet.

**KIND: ACCEPT — system.**

## R — the route

**Intended route.** Read the ten rules. Decide what state carries a gate setting
and a call. Write `Observe` over it. Render the four requirements at the forms
given, run TLC at three owners on a flow of 3, and fix the model until all four
hold and every allowed run is producible. Then read the green run at a flow of 6,
notice that 27 is a long way under 136, ask why the space collapsed, and land on
shortage never happening.

**Probes.**

- **Tiling.** Three pairs against four requirements, and the statement names the
  one with no pair. The pairs are the oracle for what, not for how. They carry no
  formula, no keyword and no vocabulary, and every one of those is given in the
  requirements section anyway, so the pairs leak nothing the statement withholds.
- **Vocabulary absence.** Shortness appears in rule 5 and in requirement 4 and is
  not a field. That absence is the statement's one real modeling instruction, and
  it's stated as a decision with its cost rather than as a hint.
- **Elimination.** Rule 9 says nothing must eventually happen, and the requirements
  section carries no liveness. A learner hunting for a temporal property is told
  twice not to. That's a concession and I'd keep it. Rule 9 is a system fact, and
  withholding it makes the learner model a river that isn't this one.
- **Answer form.** Form 0 fixes keyword, kind and subscript for all four. It fixes
  no state, no operator past `Observe`, and no formula.
- **Pre-clearing.** Three passages: the ungraded-rules paragraph, the subscript
  warning, and the note that requirement 3 can't be an invariant. All three are
  required honesty. The third is the one I looked at hardest, since it hands over
  the conclusion of a real argument. I kept it because the alternative is a learner
  spending their whole budget proving a negative that the description already
  settled, and because the ramp puts the argument at a higher rung than this one.
- **The green run's own numbers.** The statement prints 27 distinct against a floor
  of 100 and a stated 136 on the real instance. That's the intended route made
  reachable rather than a leak. Without it the diagnosis rests on the learner
  reading a coverage block they were never told to ask for.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, no prior spec found
  to crib from at step 0.

**Shortest route found.** Skip the prose, read the traces, and write four formulas
that reject three runs. It fails, and that's the point of shape D at this
representation. You can't write a formula over `Observe` without first deciding
what state renders `Observe`, and the traces show values rather than a model. The
diagnosis half has a shorter cheat: run the shipped config, see 27, and say the
space is too small. A learner who does that has the right answer with half the
reason, and the statement asks for the why in question 2. I'd call that acceptable
leakage. It gets the learner to the door of the real answer, and the real answer is
that no owner can ever be short at a flow of 6.

**ROUTE: ACCEPT.** The shortest route I can find is the intended one.

## Judgment calls in the statement, and the step 2 constraints

**The owners are named 1, 2 and 3, and that hands over a representation.** The
checking instance needs a concrete `Owners`, and TLC's config format won't take a
function literal, so the seniority order has to live somewhere a config can name.
Numbers are what the reference uses. I named them in the statement as priority
dates with the smaller date the older right, which is a system fact about the
instance rather than a claim about state. The cost is real: the seniority fork that
the description left open (a date, a rank, or an order relation) is mostly closed by
the instance, since a learner holding numbers will compare numbers. The alternative
is model values plus a fourth constant for the order, and that changes the instance
away from the one step 2 measured, which takes the shipped green run's numbers with
it. I'd rather keep the measured instance and record the cost. Representation still
places at 2, because the dimension counts state variables against `Observe` fields
and constants aren't state.

**The wrong-subscript hazard** (step 2, finding 3: `ACallIsHonest` subscripted on
the settings alone lets S10 through at rc=0 over all 136 states). Form 0 gives the
subscript in requirement lines 3 and 4, and the paragraph under them names the
failure mode in interface terms. No formula is given.

**Requirement 3 can't be an invariant** (description §2, and step 2 left it
standing). The statement says so and gives the one-line reason: a senior's own
lawful act can strand a junior out of priority, and nothing here can shut the
junior's gate.

**"Fewer are reachable" is not repeated.** The description's bounds paragraph says
fewer than 136 states are reachable and step 2's finding 2 measured all 136 as
reachable. The statement carries 136 flat.

**S18 stays open** (step 2, finding 1). Nothing in the graded set constrains the
opening, and under shape D the learner writes their own. Step 2 recommended leaving
the gap rather than spending a fifth cfg line, since five lines breaks the rung's
property-count band. The statement carries rule 10 as a system rule with no
requirement behind it, and the trace map tells the grader not to read a wrong
opening as a property-set failure.

## Verification behind the shipped artifacts, in one block

- FREEZE check: `sha256sum` over `reference/RiverCall.tla` and `RiverCall.cfg`,
  both digests equal to `reference/FREEZE.sha256`, before anything was derived.
- No spec ships, so there's no strip to prove. What replaces it is that the shipped
  config runs: a scratch copy of the reference with its two invariants renamed to
  the statement's names, run under `statement/RiverCall.cfg` with the deadlock
  check on, came back OK at 163 generated, 27 distinct, depth 4. The three console
  lines quoted in the statement are that run's, verbatim.
- Reference gate, re-measured: OK, 757 generated, 136 distinct, depth 8, and OK
  again with the deadlock check on. So the statement's instruction to leave
  deadlock checking on is measured rather than assumed.
- Violating traces: S09, S05 and S10 from `reports/step2-variants/`, unmodified,
  rerun through `harness/verdict.sh`. All three rc and reported-obligation values
  match step 2's table.
- Satisfying traces: hand-built to mirror their twins, then machine-validated
  against the frozen reference by a trace-forcing scratch module. Three of three
  walked to their last state at rc=12, and a deliberately illegal control came back
  rc=0, so the check can fail.
- `harness/test-vector.sh` passes on `authoring/river-call/VECTOR.md`. Three
  assertions fail in that suite for sibling packages with no record yet
  (`estate-notice`, `floor-malting`, `laytime`), which are other rungs in flight.
