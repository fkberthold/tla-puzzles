# P5 consign, step 4: the statement, and both screens on its wording

Agent C, bead `tla-exm1`, V2-PLAN §9.6. Author-only. I wrote the statement
from the frozen reference and nothing else: inputs were `HANDOFF.md`, the
three reference files (verified against `FREEZE.sha256` before reading, all
three OK), and `reports/step2-variants.md`. I did not read `DESCRIPTION.md`,
`screens.md`, any other domain, or anything under `pilot/`.

This problem carries a recorded ROUTE concern: after the Rule 1 reword, the
complete edge set still sits in the description's property list and event
signatures, so whether the must-be-trues travel verbatim into the statement
was my live decision. The section on the carry, below, says what I did with
it. The screens here ran on `statement/PROBLEM.md` as worded, after the
tiling probe ran against my own draft.

## §5.7, the mechanism screen

Three runs of `harness/screen.sh --name 'Consign'`, one domain phrasing and
two mechanism-forward phrasings:

- `'consignment shop counter'`: name 2 hits, CLEAR. No mechanism derived.
- `'per-item one-way lifecycle with batched per-owner settlement'`: CLEAR,
  no mechanism derived.
- `'bounded floor capacity with batch clearing at a till'`: CLEAR, no
  mechanism derived.

All three verdicts read `CLEAR (name: CLEAR | mechanism: CLEAR)`. §9.6 says
a CLEAR with no mechanism derived is not a clean bill, so here is the
mechanism named by hand: a per-item five-state one-way lifecycle, a shared
cap on one of the states, and a per-owner batched clearing step whose scope
the state determines at the moment it fires. I checked that against the
corpus mechanisms the README table carries. It is not the allocator (nothing
requests, waits, or gets granted), not two-phase commit (no vote, no
coordinator, nothing decides together), not producer-consumer (nothing hands
off). The batch-clearing step is the distinctive part, and I found no
published spec built on it. That judgment is mine, not the script's.

## §5.7b, the puzzle screen, action-centric form (shape A)

Run on the statement as worded. I ran the probes before answering the rows,
tiling first, per the carry.

### The tiling probe, against my own draft

The statement's rule paragraphs against its own obligation list.

| Rule paragraph | Constrained by |
|---|---|
| the parties | nothing (scope: whose hand is unobservable, the statement says so) |
| the book, five standings, one-way story | O1, O2, O4 |
| intake and the cap | O3, O4, O5 |
| sale | O4, O5 |
| going home | O4, O5 |
| the till | O5 |
| nobody must act | nothing, declared in the statement's own text |

Two holes, both declared on the face of the statement rather than latent:
the parties paragraph is scope, and the no-liveness hole is announced in the
obligations section. Every obligation traces back to a rule. No undeclared
hole, no orphan obligation. On shape A there's no artifact to tile against,
so this is the whole tiling surface.

### The other probes

**Vocabulary absence.** "Payout", "owed", "till" recur in the prose and the
interface has no field for money. The statement surfaces this itself: sold
means owed, settled means paid, the book never carries an amount. "Buyer"
appears and no obligation touches it, also declared (buyers aren't parties).
Nothing repeats that the obligations silently fail to carry.

**Elimination.** One field, so no orphan field. The one unconstrained rule
noun is whose hand carried an item home, and the statement declares the book
doesn't record it.

**The answer form.** The interface fixes four constant names, one operator
name, one field, five marker strings. All of that is §3.3's fixed grading
interface, and none of it narrows the model: notation open, state open,
action decomposition open. The honest cost: `Observe.standing`'s shape (a
function from items to markers) pulls the learner toward keeping exactly
that map as state. That pull is §3.3's price, paid on purpose, and the
HANDOFF's thinness defense is where it was accepted.

**Pre-clearing.** Two hits. The all-safety declaration ("there's no liveness
obligation, on purpose") and the deadlock-off note. Both are mandated: the
brief requires the all-safety expectation stated plainly, and without the
quiescence note a learner reads a finished round as a bug. I kept both and
I'm recording them as the probe hits they are.

**Recall.** §5.7 came back CLEAR (name: 2 hits). No mechanism prior hands
anything over.

### The eight rows

| # | Question | Answer |
|---|---|---|
| 1 | anything left to model? | **Split, leaning system.** The four event kinds are given by the domain prose, as §3.2 obliges. What a *step* is remains decided: going home is one event or two, the till is one atomic batch over a set the state picks, refusal and the empty visit are non-steps, and the state itself is open. |
| 2 | actions given or decided? | **Split, same line.** Kinds given, decomposition decided. Nobody hands over that fetch-and-send collapse into one action, or that the till updates a whole set at once. |
| 3 | what is asked? | **Is this design correct.** Five safety obligations to establish. No goal state, no reachability question. System. |
| 4 | who works once it compiles? | **Learner models, TLC checks.** Hundreds of states, seconds per run. TLC searches nothing worth the name. System. |
| 5 | difficulty? | **Abstraction choice.** The till's atomicity, the two-hands fold, and rendering obligations 4 and 5 as step constraints rather than state predicates. System. |
| 6 | agents, failure, interleaving? | **Several, uncoordinated.** Shop and owners interleave freely, sale races going-home on the same listed item, a full floor refuses, anything can stall forever. System. |
| 7 | delete TLC, a decision to defend? | **Yes.** Is the till one step. Is going home one event. Does the book need a ledger beside the standings. System. |
| 8 | names an optimum? | **No.** Zero hits for optimal, minimum, fewest, best. System. |

Q1 decides and reads system on the half that matters. Zero full puzzle rows
among Q2 to Q8, two recorded half-answers on the given side of Q1 and Q2,
which §3.2 makes mandatory rather than defective. The split answers are
written as splits on purpose, per the rubric's instruction not to collapse
them.

**KIND: ACCEPT, system.** The event vocabulary is handed over because a
complete system statement must hand it over. The actions as TLA+ steps, the
batch, and the step boundaries are the learner's.

### R, the route

**Intended route.**

1. Choose state that carries each item's standing.
2. Decide the actions: cap-guarded intake, sale, one going-home event, the
   till as an atomic per-owner batch. Decide refusal and the empty visit are
   not steps.
3. Write `Observe` over that state.
4. Render the five obligations, deciding which is an opening condition,
   which are state predicates, and which constrain steps (4 and 5 need
   action properties, primes and all).
5. Carry obligation 5's strength: the single-change disjunct excludes
   payouts, so a partial payout has nowhere to hide.
6. Run TLC at the small instance, deadlock off, green in seconds.

**Shortest route found.** Take the observable as the state, one map. The
four rule paragraphs hand the four actions' guards in prose. Obligations 1
to 3 are one-liners over the map. Obligation 4's edge set sits inside the
obligation with marker pairs, so its body is near-transcription. Obligation
5's two-disjunct shape, exclusion included, is in the obligation's two
sentences. What the shortest route still cannot transcribe: the till's
batch update as one action (no set-valued EXCEPT exists, so a function
rebuild), the recognition that obligations 4 and 5 need step form, and the
deadlock discipline. I put a fluent learner at 20 to 30 minutes, most of it
in the till action and the two action properties.

**Does that route use the judgment the problem is for?** Mostly. The step-1
author named the step-shape property as where a weaker form hides, and on
this route the learner doesn't discover the exclusion, the statement hands
it, because a statement that withholds it under-specifies the system. What
the route does exercise: batch atomicity, step granularity, action-property
rendering. What it doesn't: inventing the state (the interface pulls toward
the map) and discovering the exclusion. Both are §3.2/§3.3 costs, accepted
upstream, not accidents of my wording.

**Where the shortcut lives.** In the task shape and the interface, not in
removable prose. Deleting obligation 4's marker pairs adds one forced
derivation step (the rules prose determines all four pairs uniquely) and
buys nothing but ambiguity risk on a graded surface.

**ROUTE: ACCEPT.** The shortest route runs through the till action and the
two action properties, which is the judgment this problem is for. The
transcription pull is real and bounded, and I'd rather ship it named than
pretend the probes came back empty.

## The ROUTE carry, disposed

The carry asked whether the must-be-trues travel verbatim. They don't, and
the edge set does not travel as a move list:

- The obligations are stated as what the book must never show, in domain
  terms, numbered 1 to 5.
- The HANDOFF's event-signatures paragraph (§3) did not travel at all. No
  signatures table, no event-to-marker-pair listing outside obligation 4.
- The edge facts appear exactly once, inside obligation 4, as the four
  lawful moves with their marker pairs in parentheses. That's the one place
  an edge fact must appear, and it's inside an obligation, not a move list.
- The HANDOFF's classification sentence ("items 2 and 3 are invariants,
  items 4 and 5 constrain steps") did not travel. Deciding which obligation
  lands as which kind of property is left to the learner, and I think it's a
  real part of this problem's work.

## Delivery boundary

Learner-visible, named one by one, nothing else:

- `authoring/consign/statement/PROBLEM.md`
- `authoring/consign/statement/traces/README.md`
- `authoring/consign/statement/traces/opening.md`
- `authoring/consign/statement/traces/standings.md`
- `authoring/consign/statement/traces/cap.md`
- `authoring/consign/statement/traces/path.md`
- `authoring/consign/statement/traces/till.md`

Author-only, outside the statement tree:

- `authoring/consign/reports/step4-screens.md` (this file)
- `authoring/consign/author-notes/step4-trace-provenance.md` (commands, rcs,
  and variant sources for every trace)

The frozen reference stays where it is, and no path under `statement/`
reaches it.
