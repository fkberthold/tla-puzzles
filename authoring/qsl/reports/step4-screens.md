# qsl step 4 — screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/qsl/statement/PROBLEM.md`. Bead
`tla-kstb`, shape B. The domain cleared step 0 before the reference was
written. This run asks whether my wording kept it clear, which passing once
does not settle (§5.7b). Both screens ran on the statement as delivered, not
on a draft.

I recorded my answers before reading anyone else's, per
`harness/PUZZLE-SCREEN.md`. There is no prior screen of this statement to
have read, but the order is worth stating anyway.

## §5.7 — mechanism collision

Two runs of `harness/screen.sh --name Bureau`, verdicts pasted:

```
=== CANDIDATE: contact confirmation bureau with mailed claims and mutual credit
--- step 1: NAME collision
    query: 'Bureau language:tla'
    hits: 1 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: claim reconciliation and matching registry with grow-only logs
--- step 2: MECHANISM collision
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

The tool derived no mechanism from either phrasing, and its own output says
that is not a clean bill. So, named by hand: the mechanism is **mutual
corroboration with permanent joint credit**. Two parties independently
assert the same pair-fact into append-only logs, and a third party joins
the two one-sided assertions into a record neither side can lose.

Why the nearest burned mechanisms don't fit:

- **Atomic commitment (2PC)**: needs an all-or-nothing vote and an abort
  path. The bureau has no abort. A one-sided claim sits harmless forever.
- **Resource allocator**: needs contention over something finite. Credit
  is not scarce and no one waits on anyone.
- **Consensus / leader election**: no agreement on one value, no roles.

The honest neighbor is CRDT-flavored grow-only state, but nothing here
merges replicas or converges anything. I know of no published TLA+ spec of
claim-matching with mutual credit, and the name search returned one hit.
CLEAR, with the mechanism named by hand rather than by the tool.

## §5.7b — the puzzle screen, spec-in-hand form

Shape B hands the learner a spec, so Q1 and Q2 are answered in their second
form, about requirements. Q3 to Q8 as written.

| # | Question | My answer |
|---|---|---|
| 1 | Spec and rules in hand, anything left to model? | **The requirements themselves.** The rules arrive as prose about mail and paper. The learner decides which are one-state claims, which constrain steps, which need temporal force, and which the interface can't carry at all. The opening state is its own kind decision. |
| 2 | Requirements given as formal claims, or decided? | **Decided, with a split** (below). No rule arrives as a formula, no kind is marked, and several stated rules have no property form over `Observe` at all. |
| 3 | What is asked? | **Is this design correct.** State what must hold and check it. No goal state, no reachability. |
| 4 | Who works once it compiles? | **The learner models the property set. TLC checks it.** The search space is fixed by the given spec either way. |
| 5 | Where does the difficulty live? | **Kind and vocabulary choice.** 15,625 states is nothing. The work is invariant-versus-step-versus-eventually, the subscript target, and what `Observe` can't say. |
| 6 | Agents, fallibility, interleaving? | **Several, fallible.** Operators mail concurrently and uncoordinated, can lie, can botch a callsign, can go silent forever. The bureau interleaves and would stall if rule 5 didn't forbid it. |
| 7 | Delete TLC, decision left? | **Yes.** Which rules are checkable over the interface, and as what kind, is defensible on paper. |
| 8 | Names an optimum? | **No.** |

**The Q2 split, written down rather than rounded off.** The decided half:
kinds are unmarked, the subscript choice is live and measured (below), and
the can't-carry set is real, so deciding what a requirement *is* is most of
the work. The given-ish half: once a learner fresh off learntla ch. 11 has
chosen a kind, the growth and one-envelope formulas are close to
transcription. The judgment concentrates in the choosing, not the typing. I
think that's the right weighting for shape B, and I'd rather record it than
claim all eight rows at full strength.

**KIND: ACCEPT — system.** Zero puzzle rows of eight.

## R — the route

**Intended route.** Read the five rules. For each trace pair, diff the
forbidden run against its allowed twin and name the rule it breaks.
Classify the fault: wrong start, wrong step, or nothing-ever-happens. Write
the matching formula over `Observe`, declare its kind, run TLC, then
hand-check the pairs.

**Probes.**

- **Tiling.** The pairs tile the requirement set one-to-one, and that is
  §3.9 by construction, not a leak: the pairs are the oracle for WHAT. They
  don't carry kind, vocabulary, subscript, or formula, which is where the
  problem grades. The one overlap: pair 8's forbidden run also breaks the
  whole-credit rule (see the coupling note below).
- **Vocabulary absence.** "Station log", "callsign", "years and mail
  nothing" appear in prose and nowhere in the artifact. Those absences mark
  the can't-carry set, which is a judgment target here, not a seeded gap.
- **Elimination.** "The bureau is the one party with an obligation" points
  at rule 5 as the only temporal-force rule. Deliberate concession, kept:
  without it a learner hunts for liveness in operator behavior, and
  operators owing nothing is a stated system fact, not a withholdable hint.
  I did cut the handoff's "the one thing in this system that must happen"
  tail from rule 5 to keep the pointing down to that single line.
- **Answer form.** The task fixes the interface and the declare-your-kinds
  discipline (§3.3). It names no per-rule target and no formula shape.
- **Pre-clearing.** Two passages: "not everything the rules say can be
  written over the interface" and "a forbidden run can break more than one
  rule". Both are required honesty (the carrier gap and the coupling
  below). Neither points at a specific neighborhood, though the second does
  advertise that some pair overlaps.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, no prior
  spec found to crib a property list from, as far as I searched.

**Shortest route found.** Pattern-match the pairs and skip the prose. It
yields the formula targets but not the corroboration vocabulary rule 3
supplies, which the pair-5 rejection and the rule-5 property both need, so
the prose gets read anyway. Every formula still has to be chosen a kind and
written over the interface. I don't see a route that reaches a passing
answer without the kind decisions, and the kind decisions are what this
cell teaches.

**Where the residue lives.** The trace-shape hints (a one-state forbidden
run says "start", a last-step fault says "step", a says-so-forever tail
says "eventually") are in the artifact, inherent to shipping pairs at all.
A reword can't remove them and shouldn't.

**ROUTE: ACCEPT.** The shortest route I can find is the intended one.

## The two step-2 constraints, and how the statement handles them

**1. Permanence has no independent arrow** (step 2, finding 2: every run
that loses credit also breaks the whole-credit step rule, and both S09 and
S14 were reported against `CreditComesWhole`). Handled three ways:

- Pair 8 ships the S09 run, whose most natural reading is the one intended:
  credit held, then gone, both sides. It stays its own pair.
- The traces section says a forbidden run can break more than one rule, and
  that rejecting it for any rule it breaks is right about that run.
- So a learner whose step rule already rejects pair 8, and who writes no
  separate permanence property, is not marked wrong by the traces. And a
  learner who writes permanence as its own property is right too. The pair
  pretends no independence the measurement didn't show.

**2. The wrong-subscript hazard is real and measured** (step 2, finding 7:
S07 caught at rc=13 under `_Observe`, rc=0 under a wrong field subscript).
Handled in the interface section of `PROBLEM.md`: step rules must be
subscripted over the whole of `Observe`, never one of its fields, and the
failure mode is described (the property is satisfied for free by steps that
change only the other field). Interface terms only. No formula is given,
per §3.3, same class as the answer shapes.

## Verification behind the shipped artifacts, in one block

- FREEZE check: `sha256sum -c FREEZE.sha256` in `authoring/qsl/reference/`,
  both files OK, before anything was derived.
- Strip check: the learner spec is the frozen reference minus exactly the
  ten obligation operators (diff shows one deleted block, lines 41 to 92).
  Same trivial-TRUE-invariant cfg run against both: OK, 740,626 generated,
  15,625 distinct, depth 10, identical on both, matching step 2's counts.
- Violating traces: the nine ship-listed variants were recreated from the
  frozen matrix text (single-mutation diffs against the frozen reference,
  verified per variant), rerun through `harness/verdict.sh`. All nine rc
  and reported-obligation values match step 2's table. One recreation
  difference: my S10 counterexample is 4 states plus a self-loop where
  step 2 recorded 5 states then stuttering. Same story, different
  enumeration.
- Satisfying traces: hand-built, then machine-validated against the
  stripped learner spec by a trace-forcing scratch module. rc=12 means the
  full run was walked under `Next`. Nine of nine validated, and a
  deliberately illegal tenth trace came back rc=0, so the check can fail.
