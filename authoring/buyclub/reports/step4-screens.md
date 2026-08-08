# BuyClub step 4: the screens, re-run on the statement as worded

Statement author's screen record, bead `tla-7fbx`, §6 step 4. Both screens
run against `authoring/buyclub/statement/PROBLEM.md` as delivered. This is
the second application: step 0 screened the domain, this run answers
whether my wording kept it clear (§9.6, §5.7b). Task shape A, so Q1 and Q2
are answered in their action-centric form.

## §5.7, mechanism collision

Command and verdict, pasted:

```
$ bash harness/screen.sh --name 'BuyClub' \
    'buying club group order book with pledge revision and minimum-quantity placement'
--- step 1: NAME collision
    query: 'BuyClub language:tla'
    hits: 1 -> clear (<=3)
--- step 2: MECHANISM collision
    no mechanism derived from this phrasing.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

No mechanism derived, and §9.6 says that's not a clean bill, so here is the
mechanism named by hand: **threshold-gated collective commitment with free
revision until an irreversible commit**, the assurance-contract shape a
crowdfunding campaign has. The two published mechanisms it brushes against,
and why I read both as different:

- **Two-phase commit** commits on unanimous votes. Nobody votes here.
  Pledges are counts, not yes/no, they revise freely, and the commit gate
  is a sum crossing a threshold, not agreement.
- **The resource allocator** rations scarce units among competitors.
  Nothing is scarce here. The order is the pledges' sum, whatever it is.

I find neither an assurance contract nor threshold pledging in the
Examples README cache the tool greps. Verdict stands **CLEAR**, with the
mechanism named.

## §5.7b, the puzzle screen

Answers recorded before reading anyone else's, per
`harness/PUZZLE-SCREEN.md`.

| # | Question | Answer |
|---|---|---|
| 1 | Anything left to model? | **Split, mostly system.** The rules name the four events and fix their atomicity, deliberately (§3.2). What's left: the guards' strength (may, never must, at placement), the frame discipline (what holds still at each step, which is most of requirements 2 through 6), and where the one liveness obligation lands (requirement 8 needs fairness on delivery and nothing else, and nothing hands that over). What's thin: the state itself. The observation interface names three facts that together are a workable state vector, so a learner can take them as variables and lose little. |
| 2 | Actions given or decided? | **Split.** The event vocabulary (pledge, place, deliver, collect) is given by the domain, and the statement's own atomicity clauses fix each event's step boundary. The rendering is decided: guards, frames, fairness, and whether anything beyond the three observed facts earns a place in the state (an ordered total, the hands that acted). Writing both halves down per the rubric rather than collapsing to one word. |
| 3 | What is being asked? | **Is this design correct.** Establish nine claims over every run. No goal state, no reachability question. System. |
| 4 | Who does the work? | **The learner models, TLC checks.** Roughly 20k distinct states at the instance. There's nothing for TLC to search for. System. |
| 5 | Where does the difficulty live? | **Faithful rendering, not state-space size.** The frames, the may/must call at placement, and fairness placement. Whether that counts as abstraction choice in full is arguable, since the interface pre-picks the observables. Recording the qualification rather than rounding up. |
| 6 | Agents, fallibility, interleaving? | **Several, fallible, free.** Two-plus members and a coordinator interleave without coordination. A member withdraws at the wrong moment, goods sit forever, nothing forces anybody's next step. System. |
| 7 | Delete TLC. A decision left to defend? | **Yes.** The permission at placement (may, never must) is a modeling decision no property can even see: an over-constrained model passes every check green. Defending it takes an argument about the club, not a checker. System. |
| 8 | Names an optimum? | **No.** Grep confirms: no optimally, minimum-as-goal, fewest, or best. `Min` is a domain constant, not an objective. System. |

**Tally.** Six system rows, two split (Q1, Q2), zero puzzle rows. The
threshold of three puzzle rows is nowhere near.

**KIND: ACCEPT, system.** With the split halves on record: the event set
and its atomicity are handed over because §3.2 obliges a complete system,
and the judgment that remains is rendering discipline rather than event
discovery.

## R: the route

**Intended route.** Read the six rules and nine requirements, choose state,
write one action per event with the hold-stills the requirements dictate,
put weak fairness on delivery alone, check at the instance, and iterate on
TLC's traces until all nine hold and the satisfying traces all replay.

**Shortest route found.** Take the three `Observe` fields as the variables,
verbatim. Transcribe rules 2 through 5 into four actions. Read the
violating traces to get each action's frame right the first time. Put weak
fairness on delivery because requirement 8 is the only "eventually" in the
statement. Check, done. I'd put it at the low end of 20 minutes for someone
who's read the core chapters.

**What the trace pairs give away, honestly.** Each violating trace exhibits
the step-shape of one wrong action: a whole row moving in one pledge, a
placement under the minimum, a share moving at delivery. A learner who
studies all nine pairs has the frame discipline half-dictated, and the
satisfying traces exhibit every legal event signature a second time (the
rules' atomicity clauses already fix them once). That's §3.2 and §3.9
working as designed, not a wording accident, and I don't think a reword
closes it without breaking the statement's own obligations.

**Probes run.**

- **Tiling.** Nine requirements against six rules: every rule constrained
  except rule 3's never-forces clause and rule 6's exclusions. Both are
  deliberate. The permission can't be a property (no property catches an
  over-constrained model), so the statement carries it in prose, in the
  two-directions warning, and in the satisfying traces as oracle.
- **Vocabulary absence.** Coordinator, supplier, and the order's total all
  appear in the prose, and no requirement constrains any of them. No field
  shows hands, no field shows the total. A learner who models them loses
  nothing and gains nothing gradable. Recorded, not fixed: the interface
  declares those absences on purpose.
- **Elimination.** share is the one field constrained against another
  (requirement 7 reads it against book). It's also where a wrong model
  shows first. Nothing narrows the answer by type alone.
- **The answer form.** The `Observe` shapes fix a workable state vector
  outright. Biggest giveaway in the problem, structural per §3.3, since
  grading needs a fixed interface. A learner still has to earn every
  action body.
- **Pre-clearing.** Searched my own prose for "this looks wrong and it's
  fine" passages. The one candidate is rule 3's "that share is zero, which
  is fine". It pre-clears a value, not a gap neighborhood. Left in.
- **Recall.** §5.7 came back CLEAR, so no burned mechanism hands anything
  over. The nearest prior a solver might reach for is two-phase commit,
  and it misleads more than it helps here (no votes, no unanimity).

**Does the shortest route use the judgment the problem is for?** Half of
it. Shape A's state-choice judgment is mostly pre-made by the grading
interface: that's the §3.3 trade, paid knowingly, and this problem pays it
more visibly than most because the three observed facts are so close to a
sufficient state. The discipline judgment is intact: guard strength, frame
completeness, the may/must call, and fairness placement are each a real
decision, each one the step-2 matrix shows a wrong model fails, and the
route can't skip any of them. The step-2 record has 23 of 30 seeded
mutations dying on those decisions and 5 of the other 7 being exactly the
over-constraint the prose and satisfying traces guard.

**Where the shortcut lives.** In the interface and in the rules' atomicity
clauses. Both structural, neither a wording accident, so per the rubric a
reword doesn't close it and redesign would mean abandoning §3.3's grading
interface. I think the honest reading is: this problem grades rendering
judgment, not state-invention judgment, and the cell is still worth
shipping on that reading.

**ROUTE: ACCEPT**, with the qualification above on record. The shortest
route found is the intended route minus state invention, and what it keeps
is what the problem grades.

## Verdicts

- **§5.7**: CLEAR, mechanism named by hand.
- **§5.7b KIND**: ACCEPT, system. Zero puzzle rows, two split rows recorded.
- **§5.7b ROUTE**: ACCEPT, qualified: state choice is pre-made by the
  interface, rendering discipline is what's left and what's graded.
