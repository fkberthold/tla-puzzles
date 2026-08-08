# P1 custody, step 4: both screens on the statement as worded

Statement under screen: `authoring/custody/statement/PROBLEM.md`, this branch.
Screened by its author (agent C, bead `tla-jjo7`), which is the worse-placed of
the two screeners. The step-5 checker re-runs both screens as an adversary, and
that run is the one that counts. Per `harness/PUZZLE-SCREEN.md`, I recorded
everything below before reading anyone else's screen. I have not read
`authoring/custody/screens.md`, central's step-0 record, at all.

The reference set was verified against the freeze before any of this ran:
`sha256sum -c FREEZE.sha256` in `authoring/custody/reference/`, all 10 files
`OK`.

The statement passed both screens on first wording. No rescue rewrite was
needed, so there is none to disclose.

## §5.7, the mechanism-collision screen

The command and its verdict:

```
harness/screen.sh --name 'Custody' 'shared custody of a child over a planning
window: two parents independently propose and accept one-day swaps against a
fixed schedule, capped, while days begin concurrently'

step 1: 'Custody language:tla'  hits: 37 -> BURNED (>3)
step 2: no mechanism derived from this phrasing
§5.7 VERDICT: BURNED   (name: BURNED | mechanism: CLEAR)
```

Two follow-ups, because a BURNED name and an underived mechanism both demand
one.

**The name collision is lexical, not mechanistic.** Sampling the hits
(`gh search code "Custody" --language=tla --limit 30`): five of the thirty are
this repository's own frozen reference. The rest are the other senses of the
word: chain-of-custody for evidence, credential custody, crypto asset custody
(`SASwap.tla`, `CredentialCustody.tla`, `chain-of-custody.tla`,
`DigitalForensics.tla`). None models shared child custody, a calendar, or
anything with this problem's shape. Nothing in the statement asks the learner
to name anything "Custody", so the collision never reaches them.

**The mechanism, named by hand since the tool derived none.** The mechanism is
a two-party propose/accept exchange: per-day one-shot swaps, expiry by a
monotone clock, a global cap, and a same-item race. Against the cached
Examples README the only "swap" row is CASPaxos, a compare-and-swap register,
which is unrelated (`grep -iE "swap|handshake|schedul|calendar|negotiat"
harness/fixtures/screen/examples-README.md`). The nearest real neighbor in the
name sample is the atomic-swap family, and it is a different mechanism:
adversarial asset exchange with cryptographic refund paths, where here nothing
compels acceptance and nothing is adversarial. I read this as mechanism CLEAR
with the derivation done by hand, as the tool's own output demands.

**A finding for central, outside my lane:** the frozen reference is publicly
indexed. The same code search that burned the name returns
`fkberthold/tla-puzzles authoring/custody/reference/Custody.tla` and its
companions, obligations included. A learner or a blind solver who searches
GitHub for this problem's nouns can pull the answer key. That is a delivery-
boundary fact for step 5 and for Stage 5 policy, not something a statement
wording can close.

## §5.7b, the puzzle screen: Q1 to Q8

Task shape A, so Q1 and Q2 are answered in their action-centric form.

| # | Question | Answer |
|---|---|---|
| 1 | anything left to model? | **The actions themselves.** The statement states outcomes and constraints, never a move list. What a step is remains undecided: whether voiding is its own step (it cannot be, and finding that out is the exercise), what acceptance does in the same-day race, where the cap binds, whether custody is derived or maintained. |
| 2 | actions given or decided? | **Decided.** Rule 8 names three fates for a proposal, but two of them are one observable event, and voiding folds into whichever step begins the day or lands the swap. Nobody handed over a decomposition. |
| 3 | what is asked? | **Is this design correct.** Ten properties to establish. No goal state, no reachability question. |
| 4 | who works? | **The learner models, TLC checks.** The Running-it section budgets TLC as a checker in minutes, and nothing asks TLC to find anything. |
| 5 | difficulty? | **Abstraction choice.** The atomicity of voiding, the race, derived against maintained custody, and what state to keep at all (the statement warns against remembering too much). |
| 6 | agents / failure? | **Several, fallible.** Two parents acting independently, plus days that begin without either's leave. Proposals are declined, withdrawn, voided, raced, and starved at the cap. Nothing compels acceptance. |
| 7 | delete TLC, decision left? | **Yes.** Voiding atomicity, race handling, and representation each need defending with no checker in the room. |
| 8 | names an optimum? | **No.** `grep -icE "optimal|optimally|minimum|fewest|best"` over the statement: 0. |

Zero puzzle answers of eight.

**KIND: ACCEPT, system.** The rules land in participant prose, the moves are
not enumerated, and the two modeling traps (voiding atomicity, the same-day
race) are stated as facts of the arrangement rather than as instructions.

## R: the route

**Intended route.** Read the nine rules. Decide what the state remembers and
what a step is, which is where the two traps live. Define `Observe` to the
contract. Render ten English properties into TLA+, four of which only make
sense as claims about steps and one of which needs fairness to come out true.
Run TLC on a minutes budget and debug against the published traces. I'd put a
prepared learner at 40 minutes and would not be surprised by more, which is
past the §9.6 target's top end. Central should know that going in.

**The probes, tiling first.**

1. **Tiling.** Nine rules against ten properties. Every rule is constrained by
   at least one property: 1 by 8 and 9, 2 by 1, 3 and 4 by 2 (through the
   scheduled parent), 5 by 3 and 4, 6 by 4, 7 by 6 and 10, 8 by 4, 6 and 10,
   9 by 3 and 7. The residue is the permission clauses (either parent may
   propose, the same day may be named twice, a resolved proposer may go
   again): no property can grade a model that quietly forbids them, which is
   the step-2 report's V17/V19 restriction class, owned by §5.2, invisible to
   any obligation set by construction. Not a wording hole. No reword closes
   it.
2. **Vocabulary absence.** "Swap" and "agreed" saturate the prose and no
   observation field carries them. The statement closes this itself: it names
   the absence and hands the learner the derivation (a swapped day is one
   whose custodian differs from its scheduled parent). Deliberate interface
   design, not a dangling noun.
3. **Elimination.** Every field carries load: `today` in properties 5, 6, 8,
   9; `custodian` in 1 through 5 and 7; `pending` in 4, 6, 10. No field is
   the unconstrained odd one out.
4. **The answer form.** The field shapes are fixed and contractual, which is
   §3.3 doing what it is for. The ten properties carry no TLA+ form hints:
   the handoff's own invariant-against-action-property classification was
   deliberately not carried into the statement.
5. **Pre-clearing.** Two passages qualify. Rule 4's "it still stands, it just
   changes nothing" and the timing note's "working, not hung". Neither sits
   beside a gap, since shape A ships none. The first settles a real modeling
   question, the second is the pipeline-mandated budget line.
6. **Recall.** The §5.7 name burn hands a pattern-matcher the wrong prior:
   chain-of-custody and asset-swap protocols, refund paths and adversaries,
   none of which this system has. If recognition fires on the name, it
   misleads. No published spec of this mechanism turned up.

**Shortest route found: transcription, and it is measured, not guessed.** Take
`traces/full-window.md`, hardcode its 24 states as a deterministic script with
weak fairness on the one scripted action, and submit that. I built it
(`tmp-variants/replay-sub/ReplaySubmission.tla`, scratch, not shipped) and ran
the shipped gate against it through `harness/verdict.sh`:

| Run | Token | rc |
|---|---|---|
| all 13 obligations, `obligations.cfg` | `OK` | 0 |
| `CapNotReached` witness probe | `SAFETY_VIOLATION` | 12 |
| `AKeepsEveryScheduledDay` witness probe | `SAFETY_VIOLATION` | 12 |
| `BKeepsEveryScheduledDay` witness probe | `SAFETY_VIOLATION` | 12 |

That is a full pass: every obligation green, every witness probe "reached". A
submission with no modeling in it clears everything the harness currently
checks, because the published satisfying trace threads all three witnesses (it
reaches the cap and flips one day each way, which is exactly what made it a
good teaching trace).

**Where this shortcut lives: the harness, not the prose.** §3.9 obliges every
property to ship a satisfying trace, and any satisfying trace rich enough to
teach also threads the finite witness set. Every shape-A problem that honors
§3.9 will have this hole until §5.3 closes it. Two closures, both cheap:

- Witness probes chosen off the published thread. The published traces never
  swap day 2, so "day 2 never differs from its schedule" as a must-fail probe
  passes the reference and refuses the transcription.
- A state-count floor. The statement itself tells the learner to expect about
  100,000 distinct states. The transcription has 24. Central already gets
  both numbers for free from check 6.

**ROUTE: ACCEPT, with that condition named.** For a correct model I found no
route shorter than the intended one: the traces show ten specific behaviors
and no property formula, the transition system still has to be invented, and
the two traps are not in any table. The transcription route reaches a passing
verdict, not a correct model, and its fix lives in §5.3. If central ships P1
before a counter-probe lands, the gate is transcribable and this record says
so in advance.

## Also worth central's eyes

- The statement asks for ten properties where the handoff's section 2 lists
  nine. Property 10 (a proposal holds its day) is the English of the
  obligation the step-2b repair added. A statement matching the graded set is
  the point of writing it from the frozen reference, but anyone diffing
  statement against handoff should expect the ten.
- The V16-family budget note from step 2 no longer bites at step 4: the same
  mutation now dies in 62 generated states, seconds, even at `-t 2400`.
- I suspect P1 runs past the 20 to 40 minute target for a first-contact
  learner. Ten properties is a lot of rendering. If that is wrong, the blind
  panel will say so cheaply.
