# The puzzle screen — V2-PLAN.md §5.7b

**A judgment rubric. Run it by hand. There is deliberately no script.**

This is the second of two independent screens over every candidate problem.

| | asks | shipped as |
|---|---|---|
| §5.7 | has someone already **solved** this? | `harness/screen.sh` — mechanized |
| §5.7b | is it even the right **kind** of thing? | this file — judgment |

**A candidate can pass §5.7 cleanly and still be useless.** Nobody has published
`RestaurantSeating.tla`; "seat this party optimally" is still bin-packing and still
worthless to us. Passing the other screen tells you nothing about this one.

### Why this is not a script

A script that returned a confident verdict on *"is this a system?"* would be worse than
this checklist, because it would be **believed**. The distinction it has to draw —
were the actions handed to you, or did you decide what an action *is* — lives in the
prose of the statement and in the intent of whoever wrote it. A regex over that prose
would be right often enough to stop being read, and wrong exactly on the interesting
cases. So the verdict is a person's, recorded in their own words.

What *is* mechanized is the reminder: every run of `harness/screen.sh` ends by saying
this screen was not run.

---

## The screen

> **The screen: if you hand the learner the legal moves, is there anything left to model?**
> If no, it is a puzzle. **Cut it, or add agents and failure until it isn't.**

That single question is the whole rubric. Everything below exists because the question
is easy to answer wrong about your own writing.

---

## Puzzle and system are two different things you can write in TLA⁺

They exercise different skills. Only one of them is what this project teaches.

| | Puzzle | System |
|---|---|---|
| The legal moves | **given by the domain** | **the thing you have to decide** |
| The question | "is the goal reachable?" | "is this design correct?" |
| Who does the work | TLC searches | you model, TLC checks |
| Where the difficulty lives | state-space size | abstraction choice |

**Why this is not pedantry.** Every puzzle in `tlaplus/Examples` — Die Hard, Tower of
Hanoi, N-Queens, missionaries and cannibals, the sliding block puzzle — is flagged
**Beginner**. Not because they are small. Because **the modeling was pre-done by whoever
wrote the rules.** The learner's remaining job is transcription, and TLC's job is the
search. And "puzzles where the state space is handed to you and the work is search" is
the **first of the four categories** the corpus survey found the entire public corpus
consists of. It is the category this project is defined against (§7.3).

---

## The checklist

Answer all eight in writing. Q1 *is* the screen; Q2–Q8 exist because Q1 is easy to
answer wrong about a statement you just wrote.

| # | Question | Puzzle answer | System answer |
|---|---|---|---|
| 1 | Hand the learner the legal moves. Is anything left to model? | nothing | the actions themselves |
| 2 | Are the actions given by the domain, or must the learner decide what an action *is*? | given | decided |
| 3 | What is being asked? | "is the goal reachable?" | "is this design correct?" |
| 4 | Who does the work once the spec compiles? | TLC searches | learner models, TLC checks |
| 5 | Where does the difficulty live? | state-space size | abstraction choice |
| 6 | How many agents act, and can any of them fail, stall, or interleave? | one, infallible | several, fallible |
| 7 | Delete TLC. Is there still a modeling decision the learner must defend? | no | yes |
| 8 | Does the statement name an optimum — *optimally*, *minimum*, *fewest*, *best*? | yes | no |

**Verdict rule.** Q1 decides. Q2–Q8 are how a wrong Q1 gets caught: if Q1 says "system"
but three of the rest say "puzzle", you answered Q1 about the domain you imagined and not
about the statement you wrote. Re-read the statement, not your intention.

**Then write one of these down, in your own words, and say why:**

- **REJECT — puzzle.** Cut the candidate, or apply the rescue pattern below and
  re-run this rubric on the rewrite.
- **ACCEPT — system.**

### Tells

Wordings that have reliably meant *puzzle*:

- "optimally", "the minimum number of", "the fewest", "the best arrangement"
- "find a sequence of moves such that…"
- "is it possible to…"
- "given the rules below" followed by a complete action set
- a single actor, no clock, nothing that can go wrong

Wordings that have reliably meant *system*:

- two or more parties acting **concurrently**, arriving in any order
- something that can **fail**: a no-show, a timeout, a lost message, a retry, a mistake
- a **property to establish or refute**, rather than a goal state to reach
- an **observation operator** the learner must supply, whose shape is left open (§9.6)

---

## What does **not** rescue a puzzle

**Local representation choices.** A puzzle usually still offers real choices. Change-ringing
offers two good ones:

- model **bells→positions** or **positions→bells** — inverse functions, and picking the
  wrong one makes half the constraints awkward;
- track visited rows **explicitly**, or notice that a repeated row *is* a repeated state,
  so TLC's own deduplication enforces no-repeats for free.

Those are genuine and interesting. They are also **local** — about transcribing a *given*
action set tidily, not about deciding what the actions are. That is the difference between
**good taste and modeling judgment**, and only the second is what we are teaching. A
candidate does not survive this screen by offering good taste.

Also not a rescue: a bigger instance, a prettier invariant, a harder search, or a domain
nobody has specified before. §5.7 governs novelty; novelty is not the currency here.

---

## The rescue pattern: **add agents and fallibility**

This converts **search into specification**.

Change-ringing *as a puzzle* is "find a Hamiltonian path through the Cayley graph of Sₙ."
Change-ringing *as a system* is:

> Model a **band** — one ringer per bell, each with a reaction time, each able to mistime
> or lose their place, plus a conductor who can call corrections. The method they are
> attempting is the abstract spec. Does the band's actual behaviour refine it?

Now the actions are not given: you decide what a ringer's step is, what "losing your place"
means as state, and how much timing to model. It also lands naturally in **column F** — the
method is the abstract spec, the band is the concrete one, and the refinement question is
exactly "did they ring what they meant to ring."

The pattern generalizes: **who else is acting, and what can go wrong for them?** If the
answer is "nobody" and "nothing", you are holding a puzzle.

---

## Worked example — the same domain, both verdicts

This pair is the rubric's proof that it runs at **statement** time and not only at
domain-selection time. One domain, two statements, opposite verdicts.

### Statement A — REJECT

> **"Restaurant seating: seat this party optimally."**

| # | | Answer |
|---|---|---|
| 1 | anything left to model? | **No.** Tables, capacities, the party, and "a party may occupy combined adjacent tables" are the complete action set. |
| 2 | actions given or decided? | **Given.** `Seat(party, tables)` is the only move, and the domain names it. |
| 3 | what is asked? | **Is the goal reachable** — does a seating exist, and is it the best one. |
| 4 | who works? | **TLC searches** the assignment space. The learner transcribes constraints. |
| 5 | difficulty? | **State-space size.** More tables, longer search. |
| 6 | agents / failure? | **One** implicit optimizer. Nothing fails. Nothing arrives late. |
| 7 | delete TLC — decision left? | **No.** Without the search there is no exercise. |
| 8 | names an optimum? | **Yes — "optimally".** |

**VERDICT: REJECT — puzzle.** This is bin-packing wearing a tablecloth. It is also burned
on the other screen (§2.2 records 56 public `Knapsack` specs), and it would still be
rejected here if it were not, because the screens are independent. Cut it, or rescue it.

### Statement B — ACCEPT

> **"Model the host stand with walk-ins and reservations arriving concurrently."**

| # | | Answer |
|---|---|---|
| 1 | anything left to model? | **Yes — nearly everything.** Is a reservation a held table or a promise? Is a walk-in queued, quoted a wait, or turned away? When does a no-show release a table? Is seating atomic with the party being greeted? |
| 2 | actions given or decided? | **Decided.** Nobody handed you `Arrive`, `Quote`, `Seat`, `Renege`, `NoShow`, `Release` — you chose that decomposition and must defend it. |
| 3 | what is asked? | **Is this design correct** — e.g. no table double-seated, no reservation starved by walk-ins. |
| 4 | who works? | **You model, TLC checks.** |
| 5 | difficulty? | **Abstraction choice** — what counts as one step, and what state a promise is. |
| 6 | agents / failure? | **Several, fallible.** Two arrival streams interleave; parties renege, no-show, and arrive short or over. |
| 7 | delete TLC — decision left? | **Yes.** The interesting argument is about the model; TLC only adjudicates it. |
| 8 | names an optimum? | **No.** It names concurrency and a property. |

**VERDICT: ACCEPT — system.**

**Read the pair, not the rows.** Same tables, same parties, same restaurant. The only thing
that changed is the sentence — which is why **the screen runs at statement time (§6 step 4)
as well as at domain-selection time. Passing once does not immunize a domain.** A domain
approved in §2.2 can still yield a puzzle on Tuesday because of how someone worded it.

---

## Seeded §2.2 pre-screen suspicions

Recorded so this screen, like §5.7, is never run blind. These are **suspicions to test,
not verdicts** — the rubric above is what settles them, candidate by candidate.

| Domain | Suspicion | Screen that owns it |
|---|---|---|
| restaurant seating with table combining | bin-packing / knapsack — 56 public `Knapsack` specs | §5.7 **and** §5.7b (see the pair above) |
| library hold queues · community garden plots · airline standby | the `Resource Allocator` spec in different dress | §5.7 |
| orchestra audition rounds | tournament ranking — same mechanism as brackets, so **at most one of the two survives** | §5.7 |
| tournament brackets with byes and forfeits | **borderline.** Advancement rules are given, but byes interacting with forfeits create genuine state questions | §5.7b |
| change-ringing method rules | **fails §5.7b, not §5.7.** The rules — permutation, adjacent-swap only, no repeats, start and end on rounds — are the complete action set, stated in the domain's own terms before you write a line. Also does not scale: a full extent on 7 bells is 5,040 rows, on 8 it is 40,320. **Rescuable** by the agents-and-fallibility pattern above, **but not in batch one** | §5.7b |
| beekeeping hive splits | rules may be too biologically fuzzy to state crisply enough for §3.2 | neither — a §3.2 statement risk |

`harness/screen.sh --list-suspicions` prints the same table from the tool's own copy.

---

## Who runs this, and when

| Who | When | What they do |
|---|---|---|
| Domain selector | before a domain enters the pool (§2.2) | run the rubric on the domain's *likely* statement; record the verdict |
| **Statement author (§9.6)** | **before delivering the statement (§6 step 4)** | run the rubric on **the statement as written**; if it fails, rewrite with agents and fallibility and **say in the delivery that you did** |
| **Leakage checker (§9.7)** | on the delivered statement | run the rubric **independently**, as an adversary — the author is the worst-placed person to notice they wrote a puzzle |

The author and the checker both run it because the failure mode is invisible from the
inside: writing a statement from a frozen reference solution makes handing over the action
set nearly automatic, and the author reads their own intent back into their own prose.

### Drop-in text for the two briefs

> Apply the §5.7b puzzle screen — `harness/PUZZLE-SCREEN.md` — to the statement, and
> report the verdict with your delivery. If you have handed the learner the complete set of
> legal moves, you have written a puzzle and TLC will do all the remaining work. The same
> domain yields a puzzle or a system depending purely on how you word it.
> *"seat this party optimally"* is bin-packing.
> *"model the host stand with walk-ins and reservations arriving concurrently"* is a system.
> Rewrite with agents and fallibility until it passes.

---

## See also

- `harness/screen.sh` — §5.7, the mechanism-collision screen. Independent of this one.
- `V2-PLAN.md` §5.7b — the source this rubric is transcribed from; §2.2 for the domain
  pool and its suspicions; §6 step 4 for where the statement-time run sits; §9.6/§9.7 for
  the two briefs that must cite this file.
