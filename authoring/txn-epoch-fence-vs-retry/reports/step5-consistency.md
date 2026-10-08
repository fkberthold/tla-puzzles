# Step 5 consistency check: txn-epoch-fence-vs-retry

Bead `tla-pmm2.2`. Written 2026-10-08 against TLC2 Version 2026.07.31.184830,
the project's canonical build. One reader, three inputs, read in this order:
Apache JIRA KAFKA-20090 body and all 34 comments from the REST API, then
`sources/spikes/txn-epoch-fence-vs-retry/REPORT.md` and its modules, then
`authoring/txn-epoch-fence-vs-retry/statement/PROBLEM.md`.

Per decision D4 this report carries no difficulty number and no `VECTOR.md`.

Every claim carries a quotation, a `file:line`, a command with its result, or
the marker INFERRED.

---

## Verdict

**Not sufficient. One blocking change, and it is one clause in rule 4.**

Rule 4 says the desk does not read the gang's card when it raises a permit
(`PROBLEM.md:84`). That clause deletes the fence. With it in force, the entire
retry mechanism this problem is about carries no weight at all: rule 2, rule 5
rows 3 to 5, rule 6's card provisions, and requirements 5 and 6 can be deleted
from the system and every one of the eight verdicts stays the same.

Measured. The statement's own checking instance, `Leaves = 3`, each requirement
in its own `.cfg`, each as a formula over `Observe` alone, action properties
subscripted over the tuple of all four fields, `-deadlock`:

| model | Req1 | Req2 | Req3 to Req8 | distinct | depth |
|---|---|---|---|---|---|
| the statement as written | rc 12 | rc 13 | rc 0 | 22 | 6 |
| the statement with rule 5 row 4 deleted outright | rc 12 | rc 13 | rc 0 | 16 | 5 |

Same eight verdicts. The two counterexamples that carry them do not touch the
card: `card` reads 1 in every state of both traces, and rule 5 row 4 never
fires in either.

That is the `tla-n8oq` defect in this problem's idiom. The three siblings found
a requirement set that goes green over a model with no mechanism. This
statement escapes that shape, because two of its eight requirements are false
of the office and an all-green answer is therefore the wrong answer. It fails
the same underlying test anyway: **the answer is unchanged over a model with no
mechanism.**

**The blocking change.** Rule 4's second paragraph should read that the desk
reads the gang's card and refuses a gang whose card does not say the leaf the
desk holds, while still not counting the leaves the book has left. That is also
what the source does, and the statement's present wording is a misreading of
one sentence of the issue body. See the last section.

With that clause changed, the retry row becomes the mechanism:

| model | Req1 | Req2 | Req3 to Req8 | distinct | depth |
|---|---|---|---|---|---|
| card read at the raise, row 4 present | rc 12 | rc 13 | rc 0 | 17 | 6 |
| card read at the raise, row 4 deleted | rc 0 | rc 0 | rc 0 | 11 | 4 |

Deleting the retry row now turns both falses into trues, so the row is
load-bearing for both. The all-green model is not green because it is idle: in
it a permit is raised, a withdrawal happens, the last leaf is reached and the
book is taken back, each confirmed by a probe asserting the opposite and
exiting 12. And the requirement 1 counterexample becomes the JIRA's own
numbered steps in order, which it is not today:

```
State 1  clear                   leaf 1  card 1  withdrawn FALSE
State 2  Raise       open        leaf 1  card 1
State 3  Withdraw    abandoned   leaf 2  card 1  withdrawn TRUE   step 1
State 4  SecondCopy  abandoned   leaf 2  card 2                   step 2
State 5  Raise       open        leaf 2  card 2                   step 3
```

**A second change, strongly recommended and not blocking: add a ninth
requirement.** The statement's eight have no analogue of the spike's
`NoExhaustedEpochHeld`, and that is the one claim the retry row is load-bearing
for under either reading of rule 4. Over `Observe` it is one line:

> **The card never says a leaf the desk cannot close on.** At every moment, if
> the leaf on the card is the last leaf, the book has been taken back.
> `INVARIANT`. A claim about a single state.

Measured over the same instance:

| model | the ninth requirement | distinct | depth |
|---|---|---|---|
| the statement as written | rc 12 | 21 | 5 |
| the statement, row 4 deleted | rc 0 | 16 | 5 |
| card read at the raise, row 4 present | rc 12 | 16 | 5 |
| card read at the raise, row 4 deleted | rc 0 | 11 | 4 |

So it fires on the defect and goes quiet when the defect is removed, in both
readings. It is also the only formula I found over the frozen four-field
interface that does that.

Nothing else in the statement came back against it. The rules are tight
everywhere I probed them except at rule 4, the prose carries no other
hand-over, and the Checking section's 90-state bound and its deadlock
justification are both correct. Three further findings that are not changes to
the statement are in Q2 and Q4.

---

## The tla-n8oq check, in full

The brief asks, for every requirement, whether the rule set permits a model
that violates it. For six of the eight the answer is no and that is correct,
because this is a classify-the-claims problem rather than a
build-a-correct-model problem. `PROBLEM.md:18-20`: "Some of them are true of
it. Work out which, and for each one that isn't, produce a run that shows it."
So the deliverable is a verdict vector, and the test that matters is whether a
model lacking the mechanism produces the same vector.

Four degenerate models, each one a thing the rules arguably permit:

| the model | Req1 | Req2 | Req3 to Req8 | distinct | vector matches the faithful one |
|---|---|---|---|---|---|
| rule 5 row 4 deleted | 12 | 13 | 0 | 16 | **yes** |
| rule 8 deleted, no fire watch | 0 | 13 | 0 | 10 | no |
| rule 10 wins at the last leaf | 12 | 0 | 0 | 22 | no |
| no fairness conjunct at all | 12 | 13 | 0 | 22 | **yes** |

Two of the four match, and they fail in opposite directions.

**Row 4 deleted is the blocking one**, and it is the verdict above. The rules
nail three other doors shut and I checked each: rule 6's "That holds for a
close the gang brought and for a withdrawal alike" (`PROBLEM.md:117`) stops a
model whose withdrawal leaves the leaf alone, rule 4's "it doesn't count the
leaves the book has left" (`PROBLEM.md:85`) stops a model whose raise checks
the ceiling, and rule 7's "That is the only way a book is taken back"
(`PROBLEM.md:133`) stops a model whose withdrawal on the last leaf fills the
book. The one door left open is the one that matters.

**No fairness at all also matches, and the brief's hope that the liveness
requirement saves the problem does not survive it.** Requirement 2 comes back
violated whether the fairness conjunct is there or not:

| spec | Req2 | trace states | TLC's stuttering warning |
|---|---|---|---|
| `Init` and the box, no fairness | rc 13 | 4, then 6, then 4 over three runs | printed |
| weak fairness on the withdrawal | rc 13 | 7 | not printed |
| weak fairness on the whole next-state relation | rc 13 | 7 | not printed |

The trap state is a genuine terminal state, so weak fairness on anything is
satisfied there vacuously, and the verdict is the same under all three. A
learner who skips the whole "Requirement 2 needs fairness" section gets the
right answer to requirement 2. What they lose is the trace: without the
conjunct TLC's shortest counterexample is unstable run to run, measured at 4, 6
and 4 trace states across three identical invocations, and the deliverable asks
for "the shortest run you found" (`PROBLEM.md:316`).

One thing does catch it, and it is not in the statement. TLC v1.8.0 prints
"Warning: The stuttering counterexample above may be caused by the absence of a
fairness constraint" on the no-fairness run and does not print it on either
fairness run, measured by grep count 1 against 0. That warning is the gate the
fairness section wants. **Recommend the fairness section say to look for it and
to report whether it appeared**, which converts a page of advice into a check.

**The two that do not match are the statement working.** A model with no fire
watch reports requirement 1 as holding, which is wrong, so the vector catches
it. A model that lets the withdrawal happen at the last leaf with no entry
reports requirement 2 as holding. That second one is not a degenerate model. It
is a defensible reading of the rules, and it is Q2.

---

## Q1. The three fix sites

**The question is mis-posed for the statement as shipped, and the measurement
that replaces it is worse news than the brief expects.**

The statement asks for no fix. Its deliverable is eight verdicts, eight traces
and a list of open cases (`PROBLEM.md:312-318`). The spike's best sub-problem,
which it calls "the three fix sites are the best sub-problem here and I'd use
all of them", is absent from the statement entirely. So central's resolution of
the maintainer dispute, "ship both requirements", does not do in the shipped
statement what the resolution says it does. Requirement 1 is not a contract the
learner's system must meet. It is a claim the learner reports as false.

Taking the question as literally as the artifact allows, I built all three fix
sites into the fire office and measured them against the full requirement set,
under both readings of rule 4.

| fix site | the spike's name | rule 4 as written: Req1, Req2 | card read at raise: Req1, Req2 | the ninth requirement |
|---|---|---|---|---|
| the withdrawal on the last leaf takes the book back | `TxnFenceRotates` | 12, 0 | 12, 0 | 0 |
| rule 4 counts the leaves left | `TxnBeginChecks` | 12, 0 | 12, 0 | 12 |
| row 4 counts the leaves left | `TxnRetryGuarded` | 12, **13** | 12, 0 | 0 |

**Requirement 1 is violated under all three fixes, in both readings, at rc 12
every time. It discriminates nothing.** It is not a property any fix can
restore, because rule 4 raises a permit from "abandoned" (`PROBLEM.md:81-82`)
and rule 8 says a withdrawal makes the standing "abandoned"
(`PROBLEM.md:140`). Those two sentences refute requirement 1 between them, with
no model and no ceiling involved. The measured counterexample is 4 states at
depth 3 and consists of a raise, a withdrawal and a raise.

So the pair of requirements 1 and 2 does **not** isolate `TxnFenceRotates`.
Under the card-checked reading all three fixes give the identical vector. Under
rule 4 as written, two of the three fix requirement 2 and the retry guard does
not, which is the same finding as the verdict from another angle: the retry
site is not on the trap's path.

**The missing requirement is the ninth one above**, and it reproduces the
spike's own three-fix table exactly: rotation 0, retry guard 0, entry check 12.
That matches `REPORT.md`'s row putting `TxnBeginChecks` at invariant 12 while
the other two read 0.

**It still does not isolate a unique fix, and no formula over this interface
can.** The spike separates rotation from the retry guard by "system stays
open", and the fire office has no such axis: rule 7 ends the book rather than
renewing it, "the next shift is outside this system" (`PROBLEM.md:134`), so
both fixes close the office down and the distinction the spike calls the real
one is not expressible over the four fields. Say so in the reference rather
than leaving step 6 to look for it.

---

## Q2. The ceiling

**A reader can reach the ceiling case from the rules as written. What they
cannot do is settle it, and the verdict on requirement 2 is what turns on it.**

Reaching it is forced. Rule 6's "Every entry the desk makes moves the gang's
authority on by one leaf, and the entry goes there" (`PROBLEM.md:116`) is
unconditional, and rule 1's "There's no leaf after the last one"
(`PROBLEM.md:56`) says where that leaf is not. A reader who models a withdrawal
at all has to decide what the desk does at the last leaf, because rule 8 makes
the withdrawal an entry. The general instruction at `PROBLEM.md:269-273` covers
it without pointing at it, and I agree with the author that a one-item callout
here would be the pre-clearing route probe in `harness/PUZZLE-SCREEN.md:307`.
The general instruction was the right call.

Settling it is the problem. The two readings are both faithful and they give
opposite answers:

| the ceiling reading | Req1 | Req2 | Req3 to Req8 | distinct |
|---|---|---|---|---|
| rules 1 and 6 win, so no entry is possible and the action is disabled | 12 | 13 | 0 | 22 |
| rule 10 wins, so the withdrawal happens and no entry is made | 12 | 0 | 0 | 22 |

Rule 10 is not a permission. "A permit the gang doesn't bring back is withdrawn
in the end. That's the one thing in this system that must happen"
(`PROBLEM.md:156-157`). A reader who takes that as binding has to make the
withdrawal available at the last leaf, and then requirement 2 holds. A reader
who takes rules 1 and 6 as binding disables it, and then requirement 2 fails.
Both have followed the statement, both have written the decision down as
`PROBLEM.md:271` asks, and the grader cannot mark either wrong without
resolving the collision the author deliberately preserved.

**Recommendation, and it is for the reference rather than the statement.** Step
6 must record both readings and the verdict each produces, and the grader must
key requirement 2's verdict to the ceiling decision the learner declares.
Freezing one verdict as the answer would mark a correct submission wrong. Do
not close the collision in the statement, because the collision is the
candidate's best content.

**One small correction to the Checking section's reasoning, not to its
conclusion.** "Three is the least that lets a close land with the book still
open" (`PROBLEM.md:283`) is true, and the trap needs no close at all.
Requirement 2 comes back rc 13 at `Leaves = 2` over 8 distinct states, and at
`Leaves = 4` over 38. So three leaves is justified for the stated reason and is
not the minimum for the defect. Worth knowing before somebody argues the
instance down to two.

---

## Q3. Leakage and the preserved contradiction

### The collision is present and unflagged. Confirmed.

Rule 10 promises every open permit is withdrawn in the end (`PROBLEM.md:157`).
Rules 1 and 6 make that impossible at the last leaf (`PROBLEM.md:56`,
`PROBLEM.md:116`). Nothing in the statement says the two collide, and nothing
hedges either of them. I read all ten rules, the interface, the eight
requirements, the open-choices section, the Checking section and the
two-ways-to-be-wrong section looking for it. The nearest thing is the general
open-case instruction at `PROBLEM.md:269-273`, which says a reader will find
cases the rules do not reach and does not say this is one of them. That is the
right handling.

### What is withheld, checked item by item

- **The `!isEpochFence` clause.** Withheld as a clause and **present as a
  rule**, which is unavoidable. Rule 7's "That is the only way a book is taken
  back" (`PROBLEM.md:133`), read against rule 8, says a withdrawal does not
  fill the book where a close would. That is the asymmetry the issue is about,
  and the rules have to fix it or the system is underspecified. The statement
  does not say the asymmetry matters or that it is where the defect lives.
- **The ceiling-minus-one rotation.** Not withheld, and I do not think it could
  be. Rule 7 is the rotation: a close entered on the last leaf is a close
  brought from one leaf below it, which with `leaf = cEpoch + 1` and
  `Leaves = MaxEpoch + 1` is exactly the spike's `Exhausted` threshold at
  `TxnBroken.tla:77`. What is withheld is that the threshold is a threshold,
  and that the two paths treat it differently.
- **Artem's own invariant.** Withheld. Comment 20 asserts "abort completes and
  finishes producer id rotation (if initiated), thus we never have epoch==max
  in completed state". Its fire-office form is the ninth requirement
  recommended above, and no sentence of the statement states it, implies it, or
  points at the card as something to check. Confirmed by reading the eight
  requirements and the interface section.
- **Which two predicates disagree.** Nothing hands it over. The spike's pair is
  `CanBump`, the ceiling test at `TxnBroken.tla:76`, against `IsRetry`, the
  one-behind test at `TxnBroken.tla:78`. Their fire-office forms are rule 1's
  "no leaf after the last one" and rule 5 row 4's "one leaf behind the leaf the
  desk holds" (`PROBLEM.md:97`). Row 4 says nothing about the leaves left, and
  no sentence puts the two side by side. Confirmed.

### One leak, and it is the clause in the verdict

`PROBLEM.md:84-85` is the only sentence in the whole statement that says the
desk fails to check something. I swept for the shape with a grep over
"doesn't", "does not", "never", "isn't" and "can't", which returns 25 lines,
and every other one is either a party's freedom, a fact about the checker, or a
line of the Checking prose.

So the one negative-capability sentence in the document names the one gap the
trap runs through, which is the elimination route probe in
`harness/PUZZLE-SCREEN.md:305`. Under the blocking change it names one of two
gaps rather than the only one, which is a strictly better position. Under rule
4 as written it is close to handing over requirement 2.

And requirement 1 is refutable from the prose with no model at all, by reading
rule 8's standing of "abandoned" against rule 4's list of standings a permit
can be raised from, which includes "abandoned". Two adjacent rules, one
inference, no interleaving. Under the blocking change the same refutation needs
the row 4 step in between, which is the trace quoted in the verdict.

---

## Q4. The screen, step 1 re-run authenticated

`gh auth status` reports a live token for `fkberthold` with `repo` scope, so
step 1 ran for real this time.

**The self-match is confirmed and the real answer is zero.**

| query | total | what came back |
|---|---|---|
| `"MODULE TxnBroken" language:tla` | 1 | `fkberthold/tla-puzzles  sources/spikes/txn-epoch-fence-vs-retry/TxnBroken.tla` |
| the same with `-repo:fkberthold/tla-puzzles` | 0 | nothing |
| `isEpochFence language:tla -repo:fkberthold/tla-puzzles` | 0 | nothing |
| `"MODULE FireOffice" language:tla` | 0 | nothing |

`-repo:` negation works on the legacy `search/code` endpoint, so
`harness/screen.sh` can carry it. **Recommend it does**, as an unconditional
addition to the query built in `gh_count` at `harness/screen.sh:178`, because
every spike module this project publishes will otherwise self-match from now
on.

**Step 1's verdict is CLEAR on the name. Its arithmetic is not sound, and that
is a separate finding.** The name `derive_name` produces from this candidate is
`TxnEpoch`, and `TxnEpoch language:tla` returns 16, which is over
`BURNED_AT=3` at `harness/screen.sh:62`. The 16 are three distinct files: 14
forks of `cockroachdb/cockroach docs/tla-plus/ParallelCommits/ParallelCommits.tla`,
plus `sourcenetwork/defradb.rs proofs/tla/HeadSetCache.tla` and
`V-Sekai-fire/interactor-tla-game-networking-model parallel_commits/ParallelCommits.tla`.
So the count is fork-inflated and the threshold is applied to raw hits. A
BURNED verdict from this query would be about GitHub's fork graph rather than
about prior art. **Recommend step 1 deduplicate by path or by blob sha before
comparing against `BURNED_AT`.** Worth a bead.

**A mechanism finding that step 2 would want, and it strengthens the candidate
rather than burning it.** `Vanlightly/kafka-tlaplus` publishes a TLA+ model of
Kafka transactions that carries `PrepareEpochFence` as a state and
`producerEpoch` throughout, at
`transactions/diary/02_AddPartitionsToTxn/tlaplus/kafka_transactions.tla`. It
annotates four sites "(no exhaustion modeled)" and says why, in prose, at line
272 of that file:

> The alternative is to limit the producer epoch but this can actually result
> in failed liveness as a new epoch may be required in order for certain
> liveness properties to be fulfilled.

That is this problem's content, named in a published spec, and declined. So the
nearest prior art states that bounding the epoch produces a liveness failure
and then does not model it. Nobody has solved the problem. Somebody has
published the observation that it is there.

Two consequences. The candidate is not burned, because the learner never sees
Kafka and the statement carries no Kafka vocabulary. And the repository in
question is already one of the 16 in this project's own corpus, in the corpus
table of `.claude/rules/tla-practice.md`, so the finding was reachable without
GitHub at all. **Recommend the step 6 reference cite it**, as the strongest
available evidence that the mechanism is real and unmodelled.

Rate limiting: eight code-search requests across the session, one per call, no
403 observed.

---

## Things nobody asked about

**The statement is a misreading of one sentence of the issue body, and the
spike read the same sentence correctly.** Issue step 3 is "The producer can
start a transaction since we don't check epochs on starting transactions". The
statement renders that literally, as a desk that does not read the card. The
spike renders it as a check on currency that does not ask about exhaustion,
with `Begin` carrying the conjunct `pEpoch = cEpoch` at `TxnBroken.tla:92`. The
thread settles it for the spike. Comment 7, sanghyeok An, 2026-01-24, proposes
as a new option "rejecting exhausted epochs(Short.MAX) on 'transaction entry'
requests that effectively transition a transactionalId back to ONGOING (e.g.,
AddPartitionsToTxn) when the epoch is exhausted". A proposal to add an
exhaustion check to that request presupposes that the currency check is already
there, and the scenario requires it, because in the defect the client's epoch
equals the coordinator's. **This is the spike-against-statement disagreement
the wave was built to find, and the spike is right.**

**The spike's claim that the source is silent about a bump from the ceiling is
verified over all 34 comments.** I grepped the full comment dump for overflow,
exhaust, Short.MaxValue, wrap, saturate and past-max. The nearest statements
are comment 20's "If epoch is max - 1, then rotate producer id, set epoch to 0"
and "thus we never have epoch==max in completed state", which assert that the
case does not arise rather than saying what happens in it. Nothing says what a
bump from max does. The spike's reading, making the bump unavailable, is the
only one that keeps both halves of issue step 4 true, and I would keep it.

**The Checking section's deadlock justification is correct, and incomplete in
the right direction.** It says "Once the book has been taken back nothing is
enabled, and that stall is the design working rather than an error"
(`PROBLEM.md:288-289`). There is a second terminal state, the trap, and it is
the answer to requirement 2. Measured: with `CHECK_DEADLOCK` left on, the
faithful model exits 11 with "Deadlock reached" on a 3-state trace ending at
standing "spent" and the last leaf, over 15 distinct states. Breadth-first
search reaches the benign stall first, so the deadlock check is a red herring
rather than a second detector, and turning it off is right. Saying there are
two stalls would give away requirement 2. Leave the section alone.

**The 90-state bound is right and the faithful count is 22.** Five standings,
three leaves, three cards and a boolean is 90, and a model holding exactly the
four facts reaches 22 distinct states at depth 6 under rule 4 as written and 17
under the card-checked reading. Both are comfortably inside the bound, so the
heuristic at `PROBLEM.md:291-294` works as advertised.

**Requirement 7's formula has a trap the statement does not warn about, and it
cost me a run.** Written as a bulleted conjunction list with the implication
indented under the last conjunct, TLA+'s junction-list syntax binds the
implication inside the final item, so the formula asserts its antecedent
unconditionally. It came back rc 13 at 2 states on the step from "clear" to
"open", which reads exactly like a real defect in the office. Explicit
parentheses fix it. Requirement 7 is the only one of the eight whose antecedent
is a conjunction, so it is the only one exposed, and the note about subscripts
at `PROBLEM.md:198-201` is the natural place for a sentence about it. A learner
who hits this will report requirement 7 as failing and will be confidently
wrong.

**Rule 5's fifth row is unmodellable and that is fine.** "The fifth row changes
nothing anywhere" (`PROBLEM.md:111`) is a stuttering step, so it cannot appear
in a next-state relation and cannot be observed. The statement says as much
without saying it is a stutter. No change wanted, but the reference should not
expect to see it.

**Method.** One parameterised module and seven runner scripts were built in this
worktree, run, and **not committed**, since this bead's footprint is the
report. The module holds the four `Observe` fields and nothing else, renders
all ten rules, and switches between readings on seven boolean constants. Each
requirement ran in its own `.cfg` at `Leaves = 3` with `-deadlock -cleanup
-noTE`, requirements 1 and 5 and the proposed ninth under `INVARIANT`, the rest
under `PROPERTY`, requirement 2 against a spec carrying weak fairness on the
withdrawal and the action properties against the plain spec. 153 TLC runs in all, every one under a second. Rebuilding it takes about forty
minutes and every rc in this report is in a table above.
