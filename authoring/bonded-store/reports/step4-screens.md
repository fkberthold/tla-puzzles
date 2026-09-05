# bonded-store step 4 — screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/bonded-store/statement/PROBLEM.md`.
Bead `tla-h2cg.7`, shape B, rung 1 of batch 2. The domain cleared step 0 before
the reference was written. This run asks whether my wording kept it clear, which
passing once does not settle (§5.7b). Both screens ran on the statement as
delivered, not on a draft.

I recorded my answers before reading qsl's. There is no prior screen of this
statement to have read, but the order is worth stating anyway.

## §5.7 — mechanism collision

Two runs of `harness/screen.sh --name BondedStore`, both phrasings taken from
the statement's own words. Verdicts pasted.

```
=== CANDIDATE: a bonded store where a keeper enters lots under bond and releases them for home consumption or moves them on
--- step 1: NAME collision
    query: 'BondedStore language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: duty is paid exactly on release and leaving is final, a one way transition where each lot is in exactly one of four situations
--- step 1: NAME collision
    query: 'BondedStore language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Neither run fired the `warehouse|robot` map row the step 0 report recorded
(`reports/step0-screens.md:276-286`). The statement uses "store" throughout, and
a grep for "warehouse" over the whole learner set returns nothing, so the row
has no word to fire on. The step 0 reason still stands for anyone who reaches
for the real term of art.

The tool derived no mechanism from either phrasing, and its own output says that
is not a clean bill. So, named by hand: **a one-way status transition over a
partitioned population, with a liability that tracks the status.** Every lot
holds exactly one of four positions, movement out of the store is irreversible,
and the duty flag is a biconditional on one of the two exits. That is the same
naming step 0 gave it, and my statement didn't move it.

Why the nearest burned mechanisms don't fit:

- **Resource allocator**: needs contention over something finite. Nothing here
  is scarce, and the store has no capacity.
- **Two-phase commit**: needs a vote and an abort path. There's one party and
  no abort.
- **Reachability**: nothing is searched for. The question is whether the
  keeper's moves are lawful, not whether a position is reachable.

CLEAR, with the mechanism named by hand rather than by the tool.

## §5.7b — the puzzle screen, spec-in-hand form

Shape B hands the learner a spec, so Q1 and Q2 are answered in their second
form, about requirements. Q3 to Q8 as written.

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The formulas and the vocabulary they range over.** Not a diff. The learner has to find how the module carries each noun, quantify over the lot set, and build an antecedent that compares a lot at two moments. |
| 2 | Requirements given as formal claims, or decided? | **Given, and I'm counting this as a puzzle row.** Form 0 hands over the keyword, the kind and the subscript, and the artifact supplies the whole vocabulary. Each stated rule maps to one fairly obvious formula. That's the rubric's own tell. |
| 3 | What is asked? | **Is this design correct.** State what must hold and check it. No goal position, no reachability. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** 64 states is nothing to search. |
| 5 | Where does the difficulty live? | **Rendering, which is the thin end of abstraction choice.** Not state-space size. The work is turning "when a lot in the store moves" into a primed comparison over the interface. |
| 6 | Agents, fallibility, interleaving? | **One, infallible, nothing interleaves. A puzzle row.** The keeper is the only party, no step happens on its own, and nothing can go wrong for him. |
| 7 | Delete TLC, decision left? | **Yes, thinly.** That requirement 2 needs a primed antecedent rather than a state predicate is defensible on paper, and so is the biconditional in requirement 1. |
| 8 | Names an optimum? | **No.** |

**KIND: ACCEPT — system.** Two puzzle rows of eight, against a threshold of
three. That's one row off the line and I'd rather say so than report a clean
pass. Both puzzle rows are the rung's design showing through rather than a
wording slip. Q6 is single-actor because step sources 0 is the floor's level and
this rung doesn't raise it. Q2 is given because form 0 is what makes this rung
rung 1. Raise either one and it's a different rung.

## R — the route

**Intended route.** Read the module to find how each noun the rules use is
carried. Write each of the three requirements as a formula over `Observe`,
under the keyword and in the kind the statement names. Run TLC. Then check the
four pairs by hand.

**Probes.**

- **Tiling.** The statement numbers three requirements and ships four pairs,
  and it says outright that requirement 2 gets two of them
  (`statement/PROBLEM.md:148-149`). So the pair count carries no arithmetic a
  learner can mine. The reference cfg's fourth line is `TypeOK`, which the
  learner never sees and is never asked for.
- **Vocabulary absence.** "Keeper", "bond", "duty point" and "home consumption"
  appear in the prose and nowhere in the module. Unlike qsl, those absences
  mark nothing the learner has to find. All three requirements are carriable
  over the interface, and the two ungraded rules (who acts, and rule 6's
  absence of an obligation) are ungraded by construction. So I left out qsl's
  "not everything the rules say can be written over the interface" sentence on
  purpose. Here it would send a learner hunting for a trap that isn't set.
- **Elimination.** Requirement 1 is the only `INVARIANT` and requirements 2 and
  3 are the only `PROPERTY` lines. At form 0 that's stated rather than
  inferable, so it isn't a route.
- **Answer form.** The task fixes the interface, the keyword, the kind and the
  subscript before the learner has read a rule. That is the largest narrowing
  in the artifact, and it's the rung's definition rather than a leak.
- **Pre-clearing.** One passage, the subscript warning at
  `statement/PROBLEM.md:124-127`. It does advertise its neighbourhood, and at
  form 0 there's nothing in that neighbourhood left to find, because the
  subscript is given two lines above it. The warning explains a given instead
  of hinting at a hidden one. Step 2 finding 4 measured what ignoring it costs,
  so I'd keep it.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, and no prior
  spec found to crib a property list from, as far as I searched.

**Shortest route found.** Look up `Observe`'s two field names and the four
strings in `Places`, then write each requirement's English straight into a
formula under the keyword the statement gives. Run TLC once. The pairs confirm.

**Does it use the judgment the problem is for?** Yes, and the margin is thin.
Rung 1's judgment is reading a real system and rendering stated rules over its
observation interface, and the shortest route is exactly that. There's no route
that skips the module, because the field names and the four strings live
nowhere else. What the route does not use is kind choice, subscript choice, or
deciding whether a rule is carriable at all. None of those is this rung's
business at form 0.

**Where the residue lives.** In the artifact, not the prose. The frozen
reference declares `variables place, dutyPaid` and defines `Observe` as the
identity over them, which step 2 finding 10 already recorded against
DESCRIPTION §5. A reword can't close it.

**ROUTE: ACCEPT**, thinly, and the one lever that would widen the margin is
form 1, which is the next rung's business rather than this one's.

## The transcription question, answered plainly

The step 0 record said rung 1's whole defence against transcription rests on
the shipped spec not being a transliteration of the English
(`reports/step0-screens.md:74-80`), and that step 4 is where it gets decided.
Here is my read.

**The spec's shape gives the learner very little to work out, and I don't think
dressing that up would help anyone.** `Observe` is the identity over the state,
field for field. The four values are `"notEntered"`, `"inStore"`, `"released"`
and `"movedOn"`, which spell rule 1's four situations in English. A learner who
reads the module finds one lookup, not a discovery.

What survives is smaller than a transliteration defence and worth naming
exactly. Three things.

First, duty is separate state rather than a reading of position, so requirement
1 is a claim the module could in principle break. The learner has to see that
from the release action setting both, which is the one place the module says
something the rules don't.

Second, the shipped module carries no property at all after the strip, so
neither action property has a model in the text to copy. Turning "when a lot in
the store moves" into a guarded comparison across a primed `Observe` is the
rung's real rendering step, and nothing in the artifact shows it.

Third, I withheld the four strings from the statement on purpose
(`statement/PROBLEM.md:100-101`), and the trace pairs print the positions in the
rules' English rather than in the module's own strings. That keeps the one
lookup a lookup the learner has to make rather than one already made for them.
It's a small thing and I won't claim it's more.

My honest verdict is that the rung ships, and that its defence against
transcription is the second point above rather than the spec's shape. If
central wants the shape defence too, the fix is the rename step 2 finding 10
describes, and that's a re-freeze rather than a reword.
