# The puzzle screen — V2-PLAN.md §5.7b

**A judgment rubric. Run it by hand. There is deliberately no script.**

This is the second of two independent screens over every candidate problem.

| | asks | shipped as |
|---|---|---|
| §5.7 | has someone already **solved** this? | `harness/screen.sh` — mechanized |
| §5.7b | is it even the right **kind** of thing, and is it **hard**? | this file — judgment |

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

Answer all eight in writing, then answer **R**, below. Q1 *is* the screen. Q2–Q8 exist because
Q1 is easy to answer wrong about a statement you just wrote. R asks something none of the eight
asks, so it carries its own verdict and stays out of the tally.

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

### Q1 and Q2 have a second form, and the task shape picks which one you answer

Q1 and Q2 as written above are for a learner who **writes the spec**: task shapes **A**, **E**
and **F** (§2.1, axis 2). What gets handed over is a set of legal moves, and the question is how
much of it was left for the learner to decide.

**Shapes B, C and D hand the learner a spec.** A property problem ships one, a critique problem
ships a deficient one, a diagnosis problem ships a failing one. The actions are given by
construction, and no wording makes them otherwise. Answer Q1 and Q2 literally there and Q1's
system column ("the actions themselves") is unclaimable. Q2 reads "given" every time. That is
not the candidate being a puzzle. That is the rubric asking the wrong question of 24 of the 60
problems (§2.1, allocation).

Ask the same question about the other object:

| # | Question, for a learner holding a spec (**B** · **C** · **D**) | Puzzle answer | System answer |
|---|---|---|---|
| 1 | Hand the learner the spec **and** the rules it is measured against. Is anything left to model? | nothing, the answer is a diff | the requirements themselves |
| 2 | Are the requirements given as formal claims, or must the learner decide what a requirement *is*? | given | decided |

**What "decide what a requirement is" means.** Which stated rules are state predicates, which
are transition properties, and which the observation vocabulary cannot carry at all. That last
one is the modeling judgment these three shapes exist to teach, and the action-centric pair
cannot see it.

**Do not read the doubled action set as a puzzle tell.** §3.2 obliges the statement to fix the
system completely, so a spec-in-hand statement enumerates the actions in prose as well as
shipping them in the artifact. The learner gets the action set twice. That is mandatory rather
than a defect, and it is the whole reason these two questions have to be asked about
requirements here (`pilot/reports/agent-d.md:250-259`).

**A tell that does survive.** If every stated rule maps to one obvious formula in a vocabulary
the artifact already supplies, then Q2 reads *given* in requirement-centric form too, and that
is a real puzzle answer. The learner is transcribing again, one level up. That case is what the
second form is built to catch.

**How the Stage 3 pilot scores under this pair.** Q1 reads *system*: the author's own answer is
that rule 3 is a state predicate, rule 5 is a transition property, and the observation operator
carries the first and not the second (`pilot/screens.md:27-32`). Q2 reads *decided*, on the
strength of the same argument. So that problem's score goes from seven of eight to eight of
eight, and it still does not ship (`pilot/README.md:45-59`). Worth sitting with. Giving back the
row that column C could never earn makes this verdict cleaner and moves it further away from
what was actually wrong with the problem, which is why R is a separate verdict and not a ninth
row.

One qualification I do not want rounded off. Q2 reads *decided* on the back of the pilot's second
gap. For its first gap the answer form named the target and fixed the shape before the learner
had thought about the domain at all (`pilot/reports/agent-d.md:135-163`), so that half of the
problem hands the requirement over too. A split answer like that is a finding. Write both halves
down instead of collapsing them to one word.

**Verdict rule.** Q1 decides. Q2–Q8 are how a wrong Q1 gets caught: if Q1 says "system"
but three of the rest say "puzzle", you answered Q1 about the domain you imagined and not
about the statement you wrote. Re-read the statement, not your intention.

The threshold is three for every task shape. That is worth stating because it used not to hold
in practice. Before the second form above existed, a B, C or D problem opened with Q2 already
reading "puzzle" whatever it said, so three of seven meant two of six for a third of the grid.
The second form gives that row back rather than lowering the bar, and nothing in the pilot argues
for a different number. Its tally was one of seven before the fix (`pilot/reports/agent-d.md:243`)
and is zero of seven after, which was never near three either way
(`pilot/reports/agent-d.md:276`).

**Then write one of these down, in your own words, and say why:**

- **REJECT — puzzle.** Cut the candidate, or apply the rescue pattern below and
  re-run this rubric on the rewrite.
- **ACCEPT — system.**

This is the **KIND** verdict, and it is one of two. The other is **ROUTE**, below. Either one
rejects on its own.

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

## R: the route. Kind is not difficulty

Q1 to Q8 settle whether a candidate is the right **kind** of thing. Not one of them asks whether
it is **hard**, and the two come apart. A statement can read *system* on every row and still be
over in five minutes, by a route that touches none of the judgment it claims to teach.

**Q5 looks like it covers this and does not.** "Where does the difficulty live?" takes for
granted that there is difficulty, and asks only for its address. Both independent screens of the
Stage 3 pilot answered Q5 "abstraction choice" (`pilot/screens.md:22`,
`pilot/reports/agent-d.md:238`) on a problem whose primary gap turned out to be reachable
without opening a single action body.

**Why this row is not a nicety.** v1 died of triviality while its own quality gate returned
green. The post-mortem's verdict is that the gate **caused** the outcome it was written to
prevent, because its constraints mechanically produced a puzzle that was a small perturbation of
the worked example (`drawer_tla_puzzles_decisions_78e0afcd8f0f7bb925f61ef0`). The gate was
working as designed. The design was wrong. A screen that certifies kind and says nothing about
difficulty is that same instrument.

### The row

| # | Question | Answer |
|---|---|---|
| R | What is the shortest route from the statement to a complete correct answer, and does that route use the judgment the problem is for? | a route, written out in steps |

**The answer is a route, not a score.** No rating, no "difficulty: 3 of 5". A number invites
authoring toward the number, and nobody else can check it. A route is a claim somebody else can
walk and refute.

The same post-mortem left a heuristic in this shape: *if your answer key can be a string match,
your question is about syntax.* R asks that about the route instead of about the answer.

### Finding one

Start by writing down the route you **meant**. For the pilot that was "read each numbered rule
against the action body that implements it". Anything shorter than the intended route is the
finding, and until the intended route is on paper there is nothing to measure against.

Then run the probes. Each shortcut has a shape, and the shape has a probe, which is what makes
this row answerable on an ordinary screening pass rather than only on a flash of insight. All
six of these fired on the pilot during one routine adversarial pass
(`pilot/reports/agent-d.md` §2).

| probe | what you look for | what it found on the pilot |
|---|---|---|
| **Vocabulary absence** | a technical noun the statement repeats and the artifact never uses | "unanimity", 3 times in the prose, 0 in the `.tla` and 0 in the `.cfg` (`agent-d.md:165-170`) |
| **Tiling** | the artifact's own enumerated list set against the statement's own, and the holes between them | 6 declared checks against 7 numbered rules, 2 holes, and the 2 holes were the 2 seeded gaps (`agent-d.md:88-118`) |
| **Elimination** | the only candidate of its type, or the only one that nothing constrains | one observation field carried no behavioural check, and was the only field typed against the constant the answer form demanded generality over (`agent-d.md:135-163`) |
| **The answer form** | how far the answer instructions narrow the answer before the learner has thought about the domain | two lines fixed both the target and the shape (`agent-d.md:150-159`) |
| **Pre-clearing** | a passage saying "this looks wrong and it is fine", which advertises that its neighbourhood repays attention | two of them, one beside each gap (`agent-d.md:201-210`, `:339-342`) |
| **Recall** | if §5.7 came back BURNED, what the mechanism's prior hands over for free | 2 of the 3 blind critics named two-phase commit before opening the spec (`pilot/reports/step6-spread.md:18`) |

Run tiling first. It is the cheapest of the six, it needs no domain knowledge, and on the pilot
it was the route that found both gaps.

### Say where the shortcut lives

Record it, because it picks the remedy.

- **In the prose.** Send it back to step 4. A reword closes it.
- **In the artifact, or in the task shape.** A reword cannot close it.

On the pilot the tiling route lived in the `.cfg`, so deleting the sentence that pointed at the
check list would have left the route standing (`pilot/reports/agent-d.md:130-133`). Redesign the
problem, or cut it. This is the same distinction as *what does not rescue a puzzle*, above. A
local fix that leaves the route intact is good taste, not a rescue.

### R does not feed the tally

The tally counts puzzle answers as evidence that Q1 was answered wrong. A short route is no
evidence of that at all. A problem can be a real system and still be trivial, and folding R into
the tally would let seven system rows outvote it. So write two verdicts, and either one rejects:

- **KIND.** ACCEPT, system, or REJECT, puzzle. From Q1 to Q8.
- **ROUTE.** ACCEPT if the shortest route you found is the one the problem is for. REJECT if a
  shorter one reaches the answer without the judgment.

Name the route either way. A ROUTE ACCEPT with no route written out is not an answer.

### Who can answer R

The author cannot time a route, because the author cannot unknow the answer. The author **can**
run all six probes, because a grep for a noun that is missing from the artifact returns the same
thing whether or not you already know why it matters. That is the reason R is built out of
probes instead of an estimate.

The checker's R is the one that counts. On the pilot the adversarial pass produced the route
analysis without being asked for it, and the author's own screen did not
(`pilot/reports/agent-d.md:261-265`, `pilot/screens.md:16-26`).

### The other thing R is for: two screens agreed on everything

Two agents ran Q1 to Q8 over the pilot independently and returned the same verdict, row for row
(`pilot/reports/agent-d.md:248`). Some of that is the rubric working. Q3 is answered by the
statement's own task sentence, and Q8 by a grep. A screen people can disagree about is a bad
screen, so agreement on those rows is the instrument behaving.

The rest of it, I suspect, is the answer columns. Every row ships its two answers, so a screener
picks from a menu instead of writing something down. That is what makes a second run cheap, and
it is also what makes a second run tell you nothing. §9.7 spends an adversary on this rubric to
buy a second opinion, and on the pilot the second opinion was the first one again.

What the second pass did add came from going off the card
(`pilot/reports/agent-d.md:250-272`), and the route analysis was the largest piece of it. R has
no answer column on purpose.

### Worked R: the Stage 3 pilot

Grid cell (S5, C). Both screens returned **ACCEPT, system** at seven of eight rows
(`pilot/screens.md:57`, `pilot/reports/agent-d.md:243`). Three blind critics then returned
byte-identical answers, one attempt each, in 15 to 25 minutes
(`pilot/reports/step6-spread.md:9-19`).

> **Intended route.** Read each of the seven numbered rules against the action body that
> implements it, and name what the spec fails to say.
>
> **Shortest route found.** The `.cfg` declares 6 checks. The statement numbers 7 rules. Build
> the cross-table. Four rules are constraint-shaped, two of those carry no check, and those two
> are the gaps. No action body opened, no domain understanding used.
>
> **Does it use the judgment the problem is for?** Not for locating the gaps, which is
> table-building. Yes for half of one gap: arguing that the second gap cannot be written over the
> observation operator at all is not reachable from the table, and it is where all three critics
> spent about 80% of their time (`pilot/reports/step6-spread.md:41-44`).
>
> **Where the shortcut lives.** In the `.cfg`, not in the prose. No reword closes it.
>
> **ROUTE: REJECT.** The gradable half is trivial to locate. The half that uses the judgment is
> the half this problem cannot grade.

Everything in that box was available at step 5. It sat in a leakage report four agent-runs before
the blind critics confirmed it, and a leakage report gates nothing. The rubric had no row to put
it in, so the problem went to step 6 carrying an ACCEPT.

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

Record your own answers before you read the other's. The pilot's checker did that
(`pilot/reports/agent-d.md:229`), which is why its agreement with the author is worth anything.

### Drop-in text for the two briefs

> Apply the §5.7b puzzle screen — `harness/PUZZLE-SCREEN.md` — to the statement, and
> report the verdict with your delivery. If you have handed the learner the complete set of
> legal moves, you have written a puzzle and TLC will do all the remaining work. The same
> domain yields a puzzle or a system depending purely on how you word it.
> *"seat this party optimally"* is bin-packing.
> *"model the host stand with walk-ins and reservations arriving concurrently"* is a system.
> Rewrite with agents and fallibility until it passes.
>
> If your task shape hands the learner a spec (**B**, **C**, **D**), answer Q1 and Q2 in their
> second form, about requirements rather than actions. The action-centric pair cannot be passed
> by those three shapes and tells you nothing about them.
>
> Then answer **R** and report both verdicts. R asks for the shortest route from your statement
> to a complete correct answer, and whether that route uses the judgment the problem is for. A
> problem can read system on all eight rows and still be over in five minutes.

---

## See also

- `harness/screen.sh` — §5.7, the mechanism-collision screen. Independent of this one.
- `V2-PLAN.md` §5.7b — the source this rubric is transcribed from; §2.2 for the domain
  pool and its suspicions; §6 step 4 for where the statement-time run sits; §9.6/§9.7 for
  the two briefs that must cite this file.
- `pilot/` — the Stage 3 pilot, which is where the second form of Q1/Q2 and the whole of R come
  from. `pilot/README.md` says why that problem does not ship.

**This file has run ahead of `V2-PLAN.md`.** §9.6 still describes an "8-question checklist", and
neither §9.6 nor §9.7 knows about the requirement-centric pair or about R. The drop-in text above
is current. Sync the plan to it.
