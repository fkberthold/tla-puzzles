# floor malting step 4, screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/floor-malting/statement/PROBLEM.md`.
Bead `tla-h2cg.11`, rung 5 of batch 2, shape A. The domain cleared step 0 before
the reference was written. This run asks whether my wording kept it clear, which
passing once doesn't settle (§5.7b). Both screens ran on the statement as
delivered, not on a draft.

I recorded my answers before reading the step 0 screen's own §5.7b table for
this domain. The order matters, since that table exists and I could have copied
it.

## §5.7, mechanism collision

Two runs of `harness/screen.sh --name Maltings`, both phrasings taken from the
statement's own words, verdicts pasted. The standing trailer about §5.7b being a
separate screen is cut from the second block only.

```
=== CANDIDATE: a malting floor where a maltster turns a piece by hand and takes it off the floor as good malt or as a loss
--- step 1: NAME collision
    query: 'Maltings language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
--- §5.7b is a SEPARATE screen and is NOT run here.
    "Has someone already solved this?" is not "is it even the right KIND of
    thing?" A candidate can pass §5.7 cleanly and still be useless.
    Run the rubric by hand, at domain-selection time AND again at statement
    time (§6 step 4): harness/PUZZLE-SCREEN.md
```

```
=== CANDIDATE: a count raised only by the actors own work with a lower mark and an upper mark and one way off
--- step 1: NAME collision
    query: 'Maltings language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing, and it says itself that a
CLEAR on no derivation isn't a clean bill. That's eight no-derivations in a row
across step 0 and step 4, which I read as a fact about the map's coverage of
time vocabulary rather than a fact about this domain.

Named by hand: **the mechanism is a two-sided window advanced by the actor's own
work, where acting too early and acting too late both ruin the thing, and the
exit is one way.** The count moves on a human act and on nothing else, so the
window has no clock behind it.

Why the nearest burned mechanisms don't fit. Allocation needs contention over
something finite, and every piece has its own place on the floor with no cap on
the room. Scheduling needs an order over tasks to be decided, and the pieces are
independent. Atomic commitment needs a vote and an abort path, and there's
neither. A lease is the honest neighbour and it's one-sided: a lease has a
deadline and nothing goes wrong by acting too soon.

**The `expiry` row, and why it didn't fire here.** `harness/screen.sh:115`
carries a map row whose bare `expiry` alternative returns BURNED on any S4
phrasing. The step 0 report has the one-word probe that shows it, and the
follow-up to split the row. Neither phrasing above uses the word, and neither
does the statement. That's a workaround rather than a clearance, and it's the
step 0 finding standing rather than a new one.

## §5.7b, the puzzle screen

Shape A, so Q1 and Q2 in their action-centric form. The rubric is explicit that
the second form belongs to shapes B, C and D, and this rung ships no spec.

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes.** The rules give turning, kilning and throwing out as things a maltster does. They give nothing about how "gone over" is carried, and nothing about whether the two ways off are one act or two. |
| 2 | Actions given, or decided? | **Decided, with a push.** The trade names the turning and the kilning. It names nothing about the loss, and the loss is half the rules. |
| 3 | What is asked? | **Is this design correct.** Seven requirements to establish over the learner's own model. No goal state and no reachability question. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** 216 states is nothing to search. |
| 5 | Where does the difficulty live? | **Abstraction choice.** Where the two marks live, whether "gone over" is stored or read off the count, and what the marker does to a comparison. |
| 6 | Agents, fallibility, interleaving? | **Several maltsters of one kind, interleaving freely, and neglect is a real failure.** A piece nobody turns is as ruined as one turned once too often. Nobody owes anybody anything except rule 7. |
| 7 | Delete TLC, decision left? | **Yes.** The loss as an event or as a fact read off the count is arguable on paper, and the two give different step rules. |
| 8 | Names an optimum? | **No.** A case-insensitive grep over `PROBLEM.md` for the rubric's own six tells returns nothing. |

The Q8 grep, since it's the one row the rubric says a grep settles. The pattern
holds optimal, minimum, fewest, best, "is it possible", and "find a sequence",
run through `grep -n -i -E` over the statement. Zero hits.

Zero puzzle rows of eight.

**KIND: ACCEPT, system.** The statement passed as first worded. No rewrite for
agents and fallibility was needed, since the maltsters were several and
uncoordinated in the description and stayed that way.

## R, the route

**Intended route.** Decide how the count is carried and where the two marks
live. Decide whether "gone over" is a stored fact or a comparison. Decide
whether the exit is one act or two. Write the maltsters' steps. Define
`Observe` over whatever state that produced. Write the seven formulas under the
keywords the requirements name, add the per-piece fairness conjunct, run TLC,
then hand-check the pairs.

**Probes.**

- **Tiling.** Seven requirements against seven pairs, one to one, and that's
  §3.9 by construction rather than a leak. The pairs render over `Observe` only,
  so they carry no state, no action and no formula. No holes either way.
- **Vocabulary absence.** "Green", "ready" and "gone over" are repeated in the
  prose and are not fields. That's the intended judgment rather than a gap: the
  learner decides whether each is stored or derived. "Steeped", "rootlets" and
  "shovel" are scene and carry nothing.
- **Elimination.** Two fields, and both are read. Requirement 7 reads the place
  alone and the other six read both, so no field is the only one of its type and
  none sits unconstrained.
- **The answer form.** The task fixes `Observe`, both field shapes, the marker's
  encoding, and every requirement's keyword, kind and subscript. It fixes no
  state and no action. That's form 0 by design, and form 0 is this rung's
  lowest dimension.
- **Pre-clearing.** Three passages: the marker warning, the guard warning, and
  the paragraph saying not to type the count to the marks. The first two are
  required honesty about how TLC fails, and without them a learner reads an
  evaluation error as a property failing (step 2, finding 8). The third
  advertises that requirement 2 repays attention, and I'd rather pay that than
  ship the trap unmarked (step 2, finding 10).
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, and the hand
  search for malting returns 0, so there's no published property list to crib.

**Shortest route found.** Carry a count per piece and a place per piece. Read
"gone over" off the count. Write three steps. Write the seven formulas, whose
keyword, kind and subscript the statement all give. Add the fairness conjunct
the statement names. That reaches a passing answer, and it skips the loss fork
entirely.

**Does it use the judgment the problem is for?** Yes for the state, which is
what representation 2 grades and which the shortest route still has to design.
No for the loss fork, and that one is worth writing down. Step 2's finding 3
measured a one-exit model and a two-exit model reaching the same 216 states and
passing all eight obligations. So the fork the step 0 screen called "where
representation 2 earns its level" carries no grade at all. The level is earned
by the state design instead, which is a weaker claim than step 0 made and is
the one the measurement supports.

**Transcription, plainly.** At form 0 the seven formulas are close to
transcription once the state exists. The statement hands over every keyword,
every kind and every subscript, so nothing about the property half is a
decision. That's the rung's design rather than a defect in my wording, since
form 0 is the level the rung block asks for. It does mean the whole of this
problem's judgment sits in the state and the step rules, and a reword can't
move any of it back.

**Where the shortcut lives.** In the interface, not in the prose. `Observe`
carries where a piece went and not how it got there, so no property over it can
separate a kilning from a throwing out. `DESCRIPTION.md` says so in section 3
and again at ambiguity 10, and step 2 measured it twice. A reword can't close
it, and closing it would mean a third field that the description ruled out.

**ROUTE: ACCEPT.** The shortest route I can find is the intended one minus a
fork that nothing grades. The state design is the judgment this cell teaches,
and every route reaches it.

## Verification behind the shipped artifacts

- FREEZE check first: `sha256sum` over `reference/Maltings.tla` and
  `reference/Maltings.cfg` matched `reference/FREEZE.sha256` byte for byte
  before anything was derived.
- No strip proof. Shape A ships no spec, so there's no learner copy to prove
  equal. The reference's own count is 216 distinct from 2,377 generated, at
  rc=0 through `harness/verdict.sh`, which is what the statement's checking
  section quotes.
- Violating halves: the seven variants `reports/step2-variants.md` section 5
  names, run from a scratch copy against the frozen `.cfg` unchanged. All seven
  returned the rc and the reported obligation step 2 recorded.
- Satisfying halves: hand-built, then machine-validated against the frozen
  reference by a trace-forcing scratch module. Seven of seven walked to the last
  index at rc=12, and a deliberately illegal eighth came back rc=0, so the
  validator can fail.
- `harness/test-vector.sh` passes on this package's record. The suite's one
  failure is `authoring/laytime/VECTOR.md`, missing at the base I branched from.
  Rung 4's step 4 landed on `main` after that base, so the failure is a fact
  about my base and not about the tree.
