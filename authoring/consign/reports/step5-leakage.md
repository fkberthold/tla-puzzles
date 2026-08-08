# P5 consign, step 5: leakage check and delivery-boundary audit

Agent D, bead `tla-exm1`, V2-PLAN §9.7. Author-only. The learner-facing
candidate set is `statement/PROBLEM.md` plus the six files under
`statement/traces/`.

**VERDICT: SHIP.** No leakage defect. Two screen verdicts recorded below,
both ACCEPT. One discrepancy against the step-4 record, on the §5.7
mechanism screen. I do not think it blocks. One watch item for step 6, and
no reword closes that one.

## One limitation, up front

`harness/PUZZLE-SCREEN.md:424` says to record your own answers before you
read the author's. I could not. My brief named the step-4 record as an input
and asked me to verify three of its claims. So I read
`reports/step4-screens.md` before running anything. My §5.7b answers below
are therefore a second opinion that already knew the first one. The rubric
warns about that at line 358. My agreement with the author's rows is worth
less because of it.

Three things I did run cold, and they have no answer column to pick from:
the two TLC probes in the ROUTE section, my own tiling, and the §5.7
phrasings. Those carry the weight here. Treat the eight rows as
corroboration and not as independent evidence.

## 1. Leakage, file by file

`authoring/consign/` held 17 files before this report. I read all of them,
then swept the 7 learner-facing ones for anything tracing back to the other
10.

**Reference identifiers.** I swept 20 of the 21 operator names in
`reference/Consign.tla` across the 7 learner files. The one I left out is
`Observe`, which the interface fixes on purpose, and the same goes for the
field name `standing`. One match, the word "Intake" at
`statement/PROBLEM.md:40`, and it is not a leak.
`HANDOFF.md:55` titles Rule 2 "Intake, and the floor", so the word reaches
the statement from the description that predates the reference, not from the
spec. The reference author named the action after the domain word.

The grep, and its result:

```
grep -rnE 'Standings|Listed|SoldOf|Init|Intake|Sell|GoHome|Settle|Next|Spec|
OneStandingEach|FloorCap|OpeningAllUnlisted|LawfulMove|LawfulPath|Changed|
Owed|SingleStep|SettlementStep|SingleStepOrSettlement' statement/
-> statement/PROBLEM.md:40 only
```

**Variant ids and variant vocabulary.** Zero hits for `C01` through `C24`,
and zero for "variant", "mutant", "seeded" (`grep -rnE` over `statement/`,
rc=1).

**Author-notes terms.** Zero hits for the vocabulary that carries the
author's rejected representations. I swept nine terms: ledger, partition,
quotient, event log, model value, `EXCEPT`, `UNCHANGED`, conjunct,
disjunct. One match, on the plain English word "except" at
`statement/traces/path.md:3`.

**Property classification.** Zero hits for "invariant" and for "action
property" anywhere in the learner set. `HANDOFF.md:111` carries the
classification sentence, and it did not travel. This is the single most
load-bearing absence in the whole delivery, for the reason section 3 gives.

**Trace over-determination.** I checked each pair for whether the satisfying
and violating traces jointly hand over a formula rather than a meaning. They
do not, and the reason is that they cannot: everything a pair illustrates is
already stated in the obligation it belongs to. `traces/till.md:34-37` names
the payout exclusion, and `statement/PROBLEM.md:120` already says "by a
lawful move that isn't a payout". `traces/path.md:31-33` names the sold to
returned jump, and `statement/PROBLEM.md:113-114` already lists the four
lawful pairs.

So the traces add no edge fact and no step rule. They make the rule hard to
miss, which I think is what §3.9 bought them for.

**Pre-answered judgments.** The R route says the till's batch form and the
kind-classification are what remain. Neither is answered in the learner set.
The till's batch form is stated as a system fact at
`statement/PROBLEM.md:55-58` and nowhere as a step encoding. The
classification is absent, per the grep above.

Two passages sit close to the line and I am recording both rather than
letting them pass silently.

**The all-safety declaration** at `statement/PROBLEM.md:125-128` uses the
word "fairness". That is TLA+ vocabulary standing in for a system fact, and
the system fact ("nobody must act") is already stated at lines 60 to 63. I
think the sentence is legitimate anyway. Dropping it under-specifies a
system whose whole character is that nothing is forced. Variant C22 is
uncatchable (`reports/step2-variants.md:46`), so the sentence also closes a
divergence the grader can never see. Worth knowing that it is the one place
the statement reaches for notation.

**The deadlock note** at `statement/PROBLEM.md:136-138` is tooling advice.
`HANDOFF.md:191-194` calls quiescence a config concern rather than a
modeling one, and I agree with that reading. Without the note a learner
reads a finished round as a bug. They may then add machinery to force a
step, which is modeling a different shop.

Neither is a representation leak and neither blocks.

## 2. The flagged call: the four fixed constants

The statement fixes `Owners`, `Items`, `OwnerOf` and `Floor` at
`statement/PROBLEM.md:70-75`, alongside `Observe`. The step-4 author read
this as §3.3 grading interface. I weighed it independently and I reach the
same answer, on a different argument.

**§3.2 governs state, and these are not state.** V2-PLAN.md:244 draws its
line at "Model `forks` as a function from fork-id to philosopher-or-null".
That sentence is about a variable. §3.3 at V2-PLAN.md:246 prohibits "a
variable vocabulary". A `CONSTANT` is a parameter of the system, and §3.2's
first half obliges the statement to fix the system completely. A fixed,
finite owner set with a fixed ownership map is the system.

**The grader cannot run without them.** `reference/Consign.tla:69` counts
listed items against `Floor`, and `:85` groups sold items by `OwnerOf`.
`reference/MCConsign.tla:12-16` substitutes all four by name. Obligations 3
and 5 are stated over these constants in the learner's own text. A harness
that evaluates them against a learner module has to name them. This is the
same conflict §3.3 exists to resolve, one level out from `Observe`.

**The decisive check: the constants close none of the declared open forks.**
`DESCRIPTION.md:196-208` lists five modeling choices the description leaves
open on purpose, and calls closing one a regression. I held the delivered
statement against all five.

| Open fork (`DESCRIPTION.md` §5) | Closed by the four constants? |
|---|---|
| the standing: one map, or event sets | no |
| the debt: read off standing, or a ledger beside it | no |
| the till: a scan at the step, or a running list | no |
| the parties: processes, or bare actions | no |
| the cap: a stored count, or the listed set's size | no |

Zero of five. Naming `Floor` fixes the bound a cap is compared against, and
it fixes nothing about whether the model stores a count or measures a set.
Naming `OwnerOf` fixes that ownership is total and unchanging, which Rule 1
already fixes in prose.

**Verdict: legitimate interface-fixing, not a representation leak.**

One honest cost, and it belongs to `Observe` rather than to the constants.
`statement/PROBLEM.md:83-88` fixes `Observe.standing` as a function from
`Items` to five spellings. That does close the one alternative the reference
author rejected in `author-notes/ALTERNATIVES.md:38-42`, folding `returned`
and `settled` into one done state. A learner cannot report five spellings
off a collapsed pair. That closure is §3.3's declared price, and it is paid
at the operator rather than at the constants. The author rejected the
alternative on its own merits anyway.

**Minor, and not a leak.** `statement/PROBLEM.md:92` says a different shape
"keeps them from ever running". As far as I can tell an extra field would
run fine, since every obligation in `reference/Consign.tla` reads
`Observe.standing` and nothing else. I have not read the grading engine, so
that is a guess. If it holds, one clause saying extra fields are harmless
would save a learner some worry. [INFERRED]

## 3. The ROUTE carry: closed, with a watch item

The step-4 record claims disposal at `reports/step4-screens.md:161-176`: no
verbatim must-be-trues, and the edge set appears once, inside obligation 4.
I checked both against the delivered text and both hold.

- `HANDOFF.md:140-146`, the event-signatures paragraph, did not travel.
- `HANDOFF.md:111`, the classification sentence, did not travel.
- The four edge pairs appear once, at `statement/PROBLEM.md:113-114`.

### My tiling probe, run against `statement/PROBLEM.md` alone

| Rule paragraph | Constrained by |
|---|---|
| the round's scope, lines 17 to 19 | O4 |
| the parties, lines 21 to 25 | nothing, declared scope |
| the book, lines 27 to 38 | O1, O2, O4 |
| intake and the cap, lines 40 to 43 | O3, O4, O5 |
| sale, lines 45 to 48 | O4, O5 |
| going home, lines 50 to 53 | O4, O5 |
| the till, lines 55 to 58 | O5 |
| nobody must act, lines 60 to 63 | nothing, declared at line 126 |

No orphan obligation. Every one of the five traces back to a rule.

I find one hole the author's tiling missed. "There's no waiting list"
(`statement/PROBLEM.md:43`) is a system fact that no obligation constrains.
The statement does not declare it unconstrained, the way it does declare
the whose-hand hole at line 53. A learner who models a waiting list still
passes, because the interface cannot see one. It is the same class as the
ledger drift `HANDOFF.md:134-138` accepts on purpose. Informational. It
cannot mislead anyone and the interface's thinness is where it lives.

**The obligation list does not tile the `.cfg`.** This matters because §6's
column-C finding G1 is that a declared-check list names its own gaps
(V2-PLAN.md:1064). Here obligations 1, 4 and 5 are `PROPERTIES` and 2 and 3
are `INVARIANTS` (`reference/MCConsign.cfg:9-15`), so the statement's
numbering interleaves the two classes. Reading the list top to bottom
recovers nothing about the split.

### The shortest route I found, and two probes on it

1. Take the shape of `Observe.standing` as the state. One map.
2. Transcribe four actions from the four rule paragraphs. Every guard and
   every effect is in the prose.
3. Write `Observe` as the identity over that map.
4. Render obligations 1, 2 and 3. One-liners.
5. Render obligations 4 and 5. This is where the route stops.
6. Run TLC, deadlock off.

Steps 1 to 4 are transcription. I ran two probes on step 5 to find out
whether it is transcription too, and it is not. Both probes are a literal
reading of the statement, and TLC rejects both.

| Probe | What a literal reading writes | Token | rc |
|---|---|---|---|
| obligation 4 | the four pairs from lines 113 to 114, no reflexive case | `LIVENESS_VIOLATION` | 13 |
| obligation 1 | the opening condition as an `INVARIANT` | `SAFETY_VIOLATION` | 12 |

Both ran through `harness/verdict.sh -t 300` against a scratch module built
from the statement's own text, at the instance the statement names. The
obligation 4 counterexample is two states long. One item moves from
unlisted to listed and three stay put, and the relation as the statement
lists it rejects the three that stayed. The obligation 1 probe fails at the
second state.

So the statement hands over the edge set and still leaves two things to
discover. A step relation has to admit "did not move". The opening is not
an invariant. `PUZZLE-SCREEN.md:98-101` names that pair as the
modeling judgment worth teaching: which stated rules are state predicates
and which are transition properties.

**Can a learner holding only the learner set shortcut to the reference's
action decomposition?** For the model half, yes, and that is §3.2 working.
The four rule paragraphs give four guards and four effects, and a learner
who transcribes them lands on `reference/Consign.tla:21-36` in substance.
For the obligation half, no. The two probes above are the evidence. The
`Changed` and `Owed` set encodings, the subscript choice, and the
classification all sit ahead of a learner at step 5 of the route.

**ROUTE: ACCEPT.** The shortest route runs through the rendering of
obligations 4 and 5, which is the judgment this problem is for.

I read the route as narrower than the step-4 record does. That record puts
the till action in the load-bearing set at `reports/step4-screens.md:156`.
I think the till action is close to handed. `statement/PROBLEM.md:56-57`
says the shop "pays everything it owes that owner in one motion" and "every
sold item of theirs settles in that single step". What remains is finding a
function rebuild in place of a set-valued `EXCEPT`. That is encoding, and
`PUZZLE-SCREEN.md:171-182` calls that good taste rather than modeling
judgment. The two action properties carry this problem on their own, and I
think they are enough.

One consequence of the narrowing, worth saying plainly to whoever runs a
later pass. **Do not add the classification sentence to the statement.** One
helpful line saying obligations 2 and 3 are invariants and 4 and 5 constrain
steps would take this problem's difficulty out with it.

### The watch item for step 6

I expect low representation spread on the panel, and I want the prediction
on record before any solver runs.

The interface pins the observable to one map from items to markers. The
cheapest state that carries it is that same map, which is the reference's
state. So I suspect three or more of the panel will return one variable that
is `Observe.standing` under another name.

§6's column-A rule reads near-identical structure as trivial or leaking and
sends it back to step 4 (V2-PLAN.md:1025). If step 6 confirms the
prediction, I do not think step 4 is where the fix lives. The pull comes
from the one-field interface, which `HANDOFF.md:128-138` argues for on
domain grounds and accepts the cost of by name. A reword cannot close it.
§6's own rule is that a red gate names where the fix lives, rather than
reflexively one step back (V2-PLAN.md:946). The address here is the
interface, one step further back than the statement.

Worth knowing that the pull cuts one trap out too. `reference/Consign.tla:60-64`
warns that `[][...]_Observe` turns every step into a stutter when `Observe`
never moves. A learner whose `Observe` is the identity over its state never
meets that trap, because the two subscripts agree for them.

## 4. §5.7b, the puzzle screen, run on the delivered statement

Action-centric form, task shape A per `HANDOFF.md:11`. Read "One limitation,
up front" before you weigh the agreement here.

| # | Question | Answer |
|---|---|---|
| 1 | anything left to model? | **Split, leaning system.** Four event kinds are given, as §3.2 obliges. What a step is, and what the obligations are as formulas, are open. |
| 2 | actions given or decided? | **Split.** Kinds given. Nobody hands over the till's set-valued update or the step boundaries. |
| 3 | what is asked? | **Is this design correct.** Five obligations, no goal state. System. |
| 4 | who works once it compiles? | **Learner models, TLC checks.** 608 distinct states, under a second. System. |
| 5 | difficulty? | **Abstraction choice.** Where the obligations live, and what one step is. System. |
| 6 | agents, failure, interleaving? | **Several, uncoordinated.** A sale races a fetch on the same listed item, a full floor refuses, anything can stall. System. |
| 7 | delete TLC, a decision to defend? | **Yes.** Is the opening an invariant. Is the till one step. System. |
| 8 | names an optimum? | **No.** Zero hits for optimal, minimum, fewest, best. |

Zero full puzzle rows against a threshold of three.

Row 4's numbers are measured rather than estimated. The frozen reference
runs at 608 distinct states from 1,791 generated, in under a second, at
`Floor = 2` with two owners and four items. `HANDOFF.md:187-189` records
the estimate and says nobody had run it, so this closes it. It also makes
`statement/PROBLEM.md:133` accurate as written.

One correction to a step-4 row. `reports/step4-screens.md:97` says nobody
hands over the fetch-and-send collapse into one action. I read
`statement/PROBLEM.md:51-52` ("Either hand, one step, the same outcome") as
making the two-action choice unobservable rather than open. A learner may
still write two actions with identical bodies, and variant C13 is recorded
uncaught for that reason (`reports/step2-variants.md:37`). So the choice is
free rather than defended. Q1 and Q2 still read system on the strength of
the till and the two action properties, so the verdict does not move.

**KIND: ACCEPT, system.**

## 5. §5.7, the mechanism screen, and one discrepancy

I ran `harness/screen.sh` on four phrasings of my own. Three behaved as the
step-4 record describes. The fourth did not, and I am reporting it rather
than adapting to the expected answer.

| Phrasing | Name | Mechanism | Verdict |
|---|---|---|---|
| per-owner batched settlement of a one-way item lifecycle | 2 hits, clear | none derived | CLEAR |
| goods held on deposit released or returned with deferred payout | 2 hits, clear | none derived | CLEAR |
| bounded capacity resource allocation with batch release | skipped, offline | none derived | CLEAR |
| secondhand shop inventory with deferred payout | 2 hits, clear | allocation, matching | **BURNED** |

The fourth phrasing derives its mechanism through the word "inventory",
which `harness/screen.sh:115` maps to allocation and matching by way of the
blood-bank row. Allocation then hits two README rows, Resource Allocator and
losa_ap, and Matching returns 1,368 code-search hits.

**I do not think this blocks, and here is the argument.** The allocator's
mechanism is request, wait, grant, release, and its interest is liveness
under contention. This shop has none of that. Nothing requests and nothing
waits. `statement/PROBLEM.md:42-43` says a full floor refuses the intake and
keeps no waiting list. So the cap is a guard on a self-service action rather
than an allocation decision. The whole obligation set is safety
(`statement/PROBLEM.md:125`), so the property the allocator exists to carry
is absent by design. I read the BURNED as the synonym table firing on a
domain noun.

The finding changes what the step-4 CLEARs are worth. All three phrasings
the author ran returned "no mechanism derived", which §9.6 says is not a
clean bill (V2-PLAN.md:1420). The author did the required follow-through
and named the mechanism by hand at `reports/step4-screens.md:27-36`. So the
§5.7 verdict has always rested on human judgment rather than on the tool.
Now there is a tool reading that says BURNED. Both of those are true, and
the file should say both.

I suspect `harness/screen.sh:115` wants "inventory" split out of the
blood-bank row, since inventory is a domain noun that sits under several
different mechanisms. That is a harness observation and not this bead's
work.

## 6. Delivery boundary

Four checks, all clean.

**No path reference leaves the set.** I swept the seven files for eighteen
terms: reference, answer, solution, author, HANDOFF, DESCRIPTION, screen,
ALTERNATIVES, provenance, MCConsign, `.cfg`, FREEZE, sha256, `authoring/`,
`harness/`, `puzzles/`, V2-PLAN, and the bead-id pattern. Zero hits
(`grep -rniE` over `statement/`, rc=1). No relative path appears anywhere.

**Traces read `Observe` and constants only.** Every table column is an item
and every cell is one of the five spellings.
`statement/traces/README.md:10-11` says so and the six files hold to it. The
prose around the tables uses owner names and item names, which are the
constants `Owners`, `Items` and `OwnerOf` from the interface, introduced at
`statement/traces/README.md:5-8`.

**Author-only output sits outside the tree a blind agent reads.** The
statement tree is `statement/`. `reports/`, `author-notes/` and `reference/`
are siblings, not children. A brief that names the seven files reaches none
of them.

**The freeze holds.** `sha256sum -c FREEZE.sha256` in
`authoring/consign/reference/` returns OK for all three files, both before
and after my two TLC probes. My probes ran against scratch modules and
touched nothing under `reference/`.

One residual risk, named rather than fixed. Isolation at step 6 is by brief,
not by filesystem, and a dispatched agent can list the parent directory of
any file it is handed. §6b.1 says instruction isolation is not isolation
(V2-PLAN.md:1099). §6 accepts this for the pipeline because Stage 4 does not
exist yet, so the mitigation is that the brief names files and never a
directory. For the tla-practice delivery the split has to be structural, and
section 7 says how.

**Housekeeping.** `HANDOFF.md` is a strict prefix of `DESCRIPTION.md`.
Sections 1 to 4 are byte-identical and `DESCRIPTION.md` adds sections 5 and
6 (`diff HANDOFF.md DESCRIPTION.md`, 64 added lines, no other change). Two
files carrying the same text will drift. Both are author-only, so nothing
downstream is at risk, and I am recording it rather than acting on it.

## 7. The named file sets

### Step 6, the blind panel

Seven files, named one by one. This matches the step-4 delivery list at
`reports/step4-screens.md:180-188`, and I confirm it.

1. `authoring/consign/statement/PROBLEM.md`
2. `authoring/consign/statement/traces/README.md`
3. `authoring/consign/statement/traces/opening.md`
4. `authoring/consign/statement/traces/standings.md`
5. `authoring/consign/statement/traces/cap.md`
6. `authoring/consign/statement/traces/path.md`
7. `authoring/consign/statement/traces/till.md`

Withheld from every solver: `DESCRIPTION.md`, `HANDOFF.md`,
`reference/Consign.tla`, `reference/MCConsign.tla`,
`reference/MCConsign.cfg`, `reference/FREEZE.sha256`,
`reports/step2-variants.md`, `reports/step4-screens.md`, this file, and
`author-notes/`.

The brief names the seven paths. It must not name `statement/`, and it must
not name a glob.

### Delivery to `~/tla-practice/problems/consign/`

The same seven files, flattened, with the traces kept in their own
subdirectory so the README's table still resolves.

```
~/tla-practice/problems/consign/PROBLEM.md
~/tla-practice/problems/consign/traces/README.md
~/tla-practice/problems/consign/traces/opening.md
~/tla-practice/problems/consign/traces/standings.md
~/tla-practice/problems/consign/traces/cap.md
~/tla-practice/problems/consign/traces/path.md
~/tla-practice/problems/consign/traces/till.md
```

Everything else in `authoring/consign/` goes to `tla-answers/`, in a
separate repo that is never co-located and never co-committed
(V2-PLAN.md:1117). The grader reads it. The tutor cannot.

A note for whoever builds the grader invocation. It returns pass or fail
per obligation plus an error location, and never a conjunct from
`reference/Consign.tla`. A diff here would hand over the reflexive case in
`LawfulMove` and the `Changed` set encoding. Section 3 shows both of those
are things this problem measures.

### What the attempt log must ask (§6b.4)

Per V2-PLAN.md:1147, each attempt records seven fields: timestamp, problem
id, the spec submitted, the verdict object, questions asked, prompts given,
and whether the unlock was strategic or specific.

The impasse kind is the load-bearing field (V2-PLAN.md:1150), and it is
asked rather than inferred. The question is whether the rules of the system
are unclear, or how to model them. For this problem the two look like this:

| Impasse kind | What it sounds like here | What it means |
|---|---|---|
| domain | can a returned item go back on the floor, is an empty till visit a step, does a full floor queue | the statement is broken, fix it |
| modeling | how do I say this about a step, how do I settle a whole set in one action, which subscript | the problem is hard, leave it alone |

I think the domain column is worth pre-seeding into the log's prompt for
this problem. All three of those questions have answers in
`statement/PROBLEM.md`, so a hit on any of them is a wording defect with a
known address.

## 8. The grading split, proposed before any solver runs

§9.7 asks for the split per seeded gap. This is task shape A and there are
no seeded gaps, so the seeded-gap form does not apply here. §6's rule 1
generalizes it and that is the form I am using: split every load-bearing
claim into the conclusion and the instrument (V2-PLAN.md:1014).

For a shape-A solver the load-bearing claims are the five obligation
renderings plus the representation choice.

| Claim | (a) naming it | (b) establishing it |
|---|---|---|
| obligation 1 | says the opening is a condition on the start, not an always-claim | renders it so that TLC accepts it, and says what an `INVARIANT` would have done |
| obligation 2 | says every item carries one of the five spellings | a check that fails on a sixth spelling |
| obligation 3 | counts listed items against `Floor` | a check that fails when the cap is dropped |
| obligation 4 | lists the four edges | admits the no-move case, and says why it is needed |
| obligation 5 | two shapes, single change and settlement | the exclusion of payouts from the single-change shape, shown to reject a partial payout |
| representation | names the state chosen | names an alternative considered and says where it lost |

Row 4's (b) and row 5's (b) are where the discrimination should live. A
solver who writes the reflexive case without comment has probably hit it
through a TLC failure. That is fine, and it is worth telling apart from a
solver who saw it coming. §9.8 already asks whether TLC caught a bug in the
first draft, so the telemetry answers this.

Row 6 is the one I am least sure carries anything. If the low-spread
prediction in section 3 holds, every solver's (a) will read the same and (b)
will be the only place they differ. That is the measurement, so it is worth
collecting either way.

## 9. Verdict

**SHIP.** Seven files, as named in section 7.

- **Leakage**: none found. Section 1.
- **The four constants**: legitimate interface-fixing. Section 2.
- **KIND**: ACCEPT, system. Zero puzzle rows. Section 4.
- **ROUTE**: ACCEPT, narrower than step 4 read it. Section 3.
- **§5.7**: CLEAR on human judgment, with one tool BURNED reported. Section 5.
- **Delivery boundary**: clean, four checks. Section 6.

Two things travel forward rather than closing here. The missing
classification carries this problem's difficulty, so a later pass must not
helpfully restore it. And I expect low representation spread at step 6, with
the cause sitting in the one-field interface where no reword reaches it.
