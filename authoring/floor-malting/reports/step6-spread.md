# Step 6: the panel, and the spread read on the representations

## The panel

| seat | model | properties | attempts | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 7 | 1 | a 126-cell trace matrix of 14 runs against 9 checks, 11 one-edit mutants each aimed at one property, two TLC probes on the marker |
| p2 | claude-opus-5 | 8 | 1 | 28 trace runs pairing the properties with a legality check, 9 mutants with an rc=0 control, a replay module that walks a run under weak fairness |
| p3 | claude-haiku-4-5 | 7 | 2 | a hand walk of all seven pairs in prose, and a python checker whose six check functions are never called |

One instance each, 2026-09-05, eight learner files staged by name. Shape A,
so no spec shipped and each seat wrote its own. Copies of the three
submissions sit under `step6-panel/`.

The attempt counts differ from what one seat claims. p1 and p2 were each
clean on the first run and then reflowed the module to fit their report
budget, which is one attempt. p3's report says "One attempt: model was green
on first run after fixing Requirement5". `p3/tlc.out` holds the run that fix
came from, `Error: Action property Requirement5 is violated`, with a
four-state counterexample. A fix implies the run before it, so p3 is two.

## Verdict: GREEN, the shape A target

Three different representations, all passing. That's column A's target
reading, and the discrimination sits in the state and the action structure
rather than in the properties.

The property content converged, and that's the statement working rather than
a leak. Step 5 §5 settled it before the panel ran. Form 0 hands over every
keyword, every formula kind and every subscript, so once the state exists the
seven formulas are close to transcription. All three seats put requirement 2
under `INVARIANT` and the other six under `PROPERTY`, which is what the
statement told them to do. Reading the kind decisions for spread at form 0
means reading a column the statement filled in.

So the spread has to be read on the state, and there it's real.

**The maltster fork**. p1 and p2 both bind `\E m \in Maltsters` in `Next`.
p3 doesn't, and its `Next` reads `\E p \in Pieces` with `Maltsters` declared
and never used. All three reach 216 distinct states, which the interface
forces and `PROBLEM.md:259` hands over anyway. What isn't handed over is the
generated count, and that splits. 2,377 for p1 (`p1/run-1.log:35`) and for p2
(`p2/run-main.log`), against 1,189 on a re-run of p3's module here. Every
successor generated twice, against every successor generated once. That's the
sixth fork of step 5 §1, taken blind, and it leaves no mark on the distinct
count.

**The projection**. p1's variables are `stage, turns`, p2's are
`place, turns`, p3's are `stage, modification`. So p1 and p2 each rename a
field on the way out through `Observe`, and only p3 lands on the reference's
identity operator. Step 5 §1 called the field-name test misfiring at
representation 2 and left the wording alone. Two seats of three renaming a
variable is the evidence for that call. The third picked the interface's own
names, which is a lawful choice, and it cost nothing.

**The marker**. p1 writes requirement 2 as the reference does, an `IF` with
`\in Nat` sitting to the left of the comparison. p2 writes
`\in 0..UpperMark`, set membership, so no comparison ever meets the marker.
p3 writes two implications with a bare `<=` under a floor guard. Three routes
past the hazard the statement warns about twice, and finding 1 is what the
third one costs.

**Two formula shapes**. p1 and p2 write requirement 3 as a pairwise
implication over `p` and `q`. p3 builds the changed set by comprehension and
asks `Cardinality(...) <= 1`, pulling in `FiniteSets` to do it. Requirement 7
splits on kind as well. p1 writes the leads-to,
`(stage = "floor") ~> (stage # "floor")`, and p2 and p3 both write
`\A p : <>(off the floor)`.

**The fork nobody took**. All three fairness conjuncts are per piece over a
disjunction of two exits. The one-exit shape stays open and untested by this
panel.

## Findings carried forward

**1. Requirement 2 has a second free pass, and it stops the run rather than
failing it.** p3's requirement 2 drops the "a piece down on the floor has a
modification" half and keeps only the ceiling and the off-floor marker. At
the shipped instance no floor piece ever carries `NoCount`, so it goes green
and sweeps all seven pairs. On the state that half exists to reject, it
doesn't fail. I put the three forms in one module as siblings, over an `Init`
that lays every piece on the floor at `NoCount` with `Next` frozen. p1's form
came back rc=12, p2's rc=12, and p3's rc=75,
`The first argument of <= should be an integer`. §5.1 line 700 reads 75 as
the check never happening. Row 2 of the grading split lists the ceiling
clause alone as its free pass, and I'd put this one beside it with the
failure direction named. A learner who ships it sees a stopped run rather
than a red check, and the statement's guard warning is written about step
rules rather than about properties.

**2. Weak fairness on the whole next-state relation is measured now, with a
reason under it.** Step 5 §6 named it as the free pass to catch. p1 built it
as mutant M7b and ran it: rc=0, 216 states, `FloorCleared` holds
(`p1/mutant-results.txt`, M7b row). p1 also says why, and the reason is worth
more to the grader than the verdict. Rule 3 caps turning at `UpperMark`, so a
fair run takes at most nine turns, and after that every enabled step takes a
piece off the floor. The distinction the statement draws only bites in a
model carrying some non-exit action that can stay enabled forever, and this
instance has none. p1's M7a (no fairness) and M7c (fairness per piece on the
turning) both come back rc=13, so the harness can fail and the M7b pass means
something.

**3. Requirement 7's kind is looser than the reference's, and two of three
read it the loose way.** The statement asks for a temporal formula over
`Observe` and calls it the one requirement that needs "eventually". The
reference writes the leads-to. p1 matched it, and p2 and p3 both wrote a
plain `<>`. All three reject pair 7's forbidden run, and at this instance the
two forms agree, because `Init` lays every piece on the floor and requirement
6 makes off-floor final. `<>` is the weaker formula in general. Two seats of
three reading it that way blind is enough that I think the grader should say
out loud that both count, rather than leave a tutor to settle it live.

**4. Pair 5's late side stayed untested, so the gap stands.** Step 5 §5 says
a property carrying only `modification >= LowerMark` passes the shipped
instance and still rejects pair 5's forbidden run, so the pair separates
nothing on that side. All three seats wrote both marks. The free pass went
untaken rather than closed, and row 5 still needs the grader to read the
property instead of the verdict.

**5. `Maltsters` is never said to be non-empty, and two seats noticed.** p1
worked out that an empty `Maltsters` enables nothing, makes the fairness
conjuncts vacuous, and fails requirement 7 while everything else holds. It
marked that INFERRED rather than running it, which is the right call for a
claim it didn't check. p2 wrote `ASSUME Pieces # {} /\ Maltsters # {}` into
its own module and never mentioned it. p3's model doesn't quantify over
`Maltsters` at all, so the question can't arise there. Two of three blind is
worth one clause in the statement.

**6. The typing paragraph reads as two opposite instructions.** p2 called it
the only place it had to guess. "Don't type the count to the marks" and "Type
the field as a range ending at `UpperMark`" sit next to each other, and only
the surrounding sentence marks the second as the consequence to avoid. p2
took the harder reading, left the count in `Nat`, and landed right. Neither
other seat raised it. I'd think about rewriting the second sentence as a
consequence clause rather than an imperative, but this is a wording finding
and not a defect.

**7. p3's record doesn't carry p3's claims.** Its `verify_traces.py` defines
six check functions between lines 49 and 98 and calls none of them. The
bottom loop parses each pair and prints two state counts. So every pair claim
in p3's report rests on `manual_check.txt`, which is a hand walk in prose.
Taken with the attempt count, p3 is the seat whose conclusions are sound and
whose instruments are assertion. That's the split the amended rule exists to
see, and it's the same shape qsl's p3 showed.

**8. Recognition.** No published-problem stop. p1 reports the mechanism it
named at rule 6 and the 216 remark, before it wrote any TLA+: independent
per-item lifecycle automata over a bounded monotone counter, two absorbing
exits, per-item weak fairness on the exit. p2 names the same skeleton from
rule 6 read against rule 2's two thresholds, a bounded counter with an
acceptance window and two absorbing terminal states. It puts a lease renewal
window and a cache entry between warm and stale in that family. Both kept
going, and both say the recognition changed nothing in the model. p3
recognized floor malting as a historical process, which is the domain rather
than the mechanism, and the domain is the statement's whole surface.
Recorded, none of it disqualifying.

## Rule 6

All three came back green on their own model at the shipped instance. Under
the amended rule the flag reads against instruments rather than against the
green run, and it splits two to one. p1 ran 126 trace cells and 11 targeted
mutants, p2 ran 37 TLC calls including a machine check that its own model
allows each allowed run, and p3 ran the model once and walked the pairs by
hand. Recorded, not fired.

**Step 6 closes GREEN.** Statement stands. Step 7 next.
