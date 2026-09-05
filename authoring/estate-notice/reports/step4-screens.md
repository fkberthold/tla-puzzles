# estate-notice step 4, screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/estate-notice/statement/PROBLEM.md`.
Bead `tla-h2cg.13`, rung 7 of batch 2, shape A, form left open 1. The domain
cleared step 0 before the reference was written. This run asks whether my
wording kept it clear, which passing once doesn't settle (§5.7b). Both screens
ran on the statement as delivered, not on a draft.

I wrote my answers down before reading step 0's. There's no prior screen of
this statement to have read, but the order is worth stating.

## §5.7, mechanism collision

Two runs of `harness/screen.sh --name EstateNotice`, both phrasings lifted from
the statement's own words. Verdicts pasted.

```
=== CANDIDATE: a public notice to creditors closed by the executor before the residue is distributed
--- step 1: NAME collision
    query: 'EstateNotice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: claims lodged inside a closing window and settled one at a time before an irreversible hand-over
--- step 1: NAME collision
    query: 'EstateNotice language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Step 0 predicted the tool would fire again here. Its follow-up says the `expiry`
alternative at `harness/screen.sh:115` catches the ordinary English word, and
that every S4 statement in batch 2 would hit it at step 4. Neither of my
phrasings uses it, and neither fired. That's a fact about my wording rather than
about the row, so the follow-up stands untouched.

The tool derived no mechanism from either phrasing, and its own output says a
`CLEAR` on that footing isn't a clean bill. So, named by hand: the mechanism is
**a one-way claims window followed by an irreversible transfer to a party
outside the system**. One party closes the window at a time of her choosing,
settles what came in through it one item at a time, and then hands the remainder
away. Nothing that missed the window can reach her afterwards, and nothing she
has done can be undone.

Why the nearest burned mechanisms don't fit:

- **Resource allocation.** Needs contention over something finite. Nothing here
  is scarce. No creditor waits on another, the residue is never divided, and the
  system carries no amounts at all.
- **Atomic commitment.** Needs a vote and an abort path. Every decision here is
  final on the step that makes it, and there is nothing to roll back.
- **Leases and expiry.** A lease is a term right, renewed before it runs out and
  reclaimed when it isn't. Nothing renews here, and there's no clock. The window
  closes by one party's act.

The honest neighbour is termination detection, because the guard on the transfer
is "everything I hold is settled". I think the resemblance stops at the guard.
Nothing here detects anything or asks anybody. The executor reads her own file,
and the guard is a state predicate over one party's records. I know of no
published TLA+ spec of a barring notice, and the name search returned zero hits.

CLEAR, with the mechanism named by hand rather than by the tool.

## §5.7b, the puzzle screen, spec-in-hand form

Shape A hands the learner no spec, so Q1 and Q2 get their first form, about
actions. Q3 to Q8 as written.

| # | Question | My answer |
|---|---|---|
| 1 | Hand the learner the legal moves. Anything left to model? | **The transition system, all of it.** No module ships. There's no `Init`, no `Next`, no `Spec` and no state until the learner writes them. Split on the interface, below. |
| 2 | Actions given, or decided? | **Named, decomposed by the learner.** §3.2 obliges the rules to say what each party may do, so the six acts are enumerated in prose. How many actions they become, and what state they run over, isn't. |
| 3 | What is asked? | **Is this design correct.** Eight requirements to establish. No goal state and no reachability question anywhere. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** The search space doesn't exist until the learner builds it. |
| 5 | Where does the difficulty live? | **Abstraction choice.** 77 states is nothing. The work is the state shape, the fairness, and one subscript. |
| 6 | Agents, fallibility, interleaving? | **Two kinds, fallible.** Creditors act uncoordinated and need never act at all. The executor can stall forever unless the learner's `Spec` says she can't. |
| 7 | Delete TLC, decision left? | **Yes.** Whether "she takes one claim at a time" is a property over the interface or a fact about her actions is defensible on paper, and it was argued both ways upstream. |
| 8 | Names an optimum? | **No.** |

**The Q1 split, written down rather than rounded off.** The interface pins three
fields, their shapes and six exact spellings, and a learner who takes those three
fields as their state has finished the representation decision without making
one. §3.3 makes that unavoidable, since grading has to key off a fixed interface.
It's also this rung's own level: representation 2 says the reference's variables
are the `Observe` fields and no others. So the shortest route through the
representation half is short by design here. What's left is still the whole
transition system, which is why Q1 reads system rather than split-to-puzzle.

**KIND: ACCEPT, system.** Zero puzzle rows of eight.

## R, the route

**Intended route.** Read the nine rules. Decide a state shape that makes "one
standing at a time" unrepresentable rather than merely forbidden. Render
`Observe` over it. Write the eight requirements, each under the keyword and kind
the statement names. Choose requirement 4's subscript. Render requirement 7's
fairness over your own decomposition. Run TLC, then hold the model against the
eight pairs, in both directions.

**Probes.**

- **Tiling.** The eight pairs tile the eight requirements one to one, and the
  statement says so. That's §3.9 by construction rather than a leak. Under
  shape A there's no model for them to tile, and they carry no state shape, no
  kind, no subscript and no fairness, which is where this problem grades.
- **Vocabulary absence.** "Beneficiaries" runs through the rules and has no
  field. So do "will", "debt" and "residue". Rule 8 is a consequence of Rules 1,
  2 and 7 and carries no requirement of its own. Those absences are the
  can't-carry set, and working out which rules the interface can carry is a
  judgment target here, not a seeded gap.
- **Elimination.** Requirement 7 is the only one naming no step and no standing.
  It's also the only one the statement calls a claim that something eventually
  happens, so nothing is eliminated that wasn't already given.
- **The answer form.** The live one. Two decisions are handed over before the
  learner has thought about the domain: the three interface fields with their
  shapes, and requirement 7's four fairness conjuncts. Both are obliged, the
  first by §3.3 and the second by the rung's kind-3 sentence.
- **Pre-clearing.** Two passages. The two-directions paragraph under "Your
  task", and the note that a forbidden run can break more than one requirement.
  Both are required honesty. Neither points at a neighbourhood.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, no prior spec
  found to crib a property list from.

**Shortest route found.** Take the three interface fields as the state.
Transcribe the six acts from the rules into six actions. Write the eight
requirements from their English, under the keywords and kinds the statement
names. Copy the four fairness conjuncts from the requirement 7 section. That
reaches a green run without deciding much, and it's shorter than the intended
route by two decisions: the representation and the fairness target.

**Does it use the judgment the problem is for?** Yes, for what's left. The
learner still writes a transition system from prose, with two kinds of party
interleaving and every guard chosen. A learner arriving from a shape B rung has
never written `Init`, `Next` or a `Spec` carrying fairness at all, and none of
that is transcribable from this statement. Requirement 4's subscript is a real
decision, and step 2's finding 4 measured that getting it wrong isn't caught by
anything else on this problem.

**Where the shortcut lives.** In the prose, on the fairness half. A reword closes
it: name the executor as the party whose stalling matters, and leave which of her
acts carry the conjuncts to the learner. That reword is forbidden here, because
the rung is form left open 1 and the kind-3 brief requires the four to be named.
So it's a rung finding rather than a wording slip, and I'd hand it to whoever
writes the first form-2 statement over a liveness requirement. That's the rung
where the fairness target is the thing being taught.

**ROUTE: ACCEPT.** The shortest route I can find is shorter than the intended
one at two points, and both are obliged by the rung rather than by my wording.
What remains is the whole transition system, which no wording of a shape A
statement can hand over.

## On transcription, and on the rewrite

I didn't have to rewrite the statement to pass either screen, so there's no
agents-and-fallibility pass to report. The two kinds of party, the free
creditors and the stalling executor were in the rules before I started, and
they're what carries the system verdict.

The learner's remaining job here isn't transcription. The complete set of legal
moves is in the statement, because §3.2 requires it, but a set of legal moves
stated in English isn't a spec. Nothing ships that TLC can run, so every action
body, every guard and the whole of `Spec` has to be decided and written before
the first check goes green.
