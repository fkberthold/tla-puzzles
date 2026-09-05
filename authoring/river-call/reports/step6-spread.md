# Step 6, the panel and the spread read on the argument

Rung 3 of batch 2, bead `tla-h2cg.9`, shape D at representation 2, form 0.
The three seats' reports are copied under `step6-panel/` so the record
outlives the staging directory. p3's spec travels with them as
`step6-panel/p3-RiverCall.tla`, because p3's report describes its spec in
prose instead of quoting it, and two of the findings below are readable
only off the module. p1 and p2 quote their own specs in full in section 1,
so nothing extra was needed for them.

## The panel

| seat | model | properties | attempts | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 4, all four correct | 1 | two-mode trace harness over six runs, `Probe.tla` with two invariants on both instances, five single-edit mutants across two cfgs, the trace harness re-run over the call-free mutant |
| p2 | claude-opus-5 | 4, all four correct | 1 | two-mode trace harness over six runs, two hand-built runs pinning rule 7's pre-state read, one mutant per requirement at flow 3, `Probe.tla` with three invariants over the flow-6 graph, two mutants against the shipped cfg |
| p3 | claude-haiku-4-5 | 4 shipped, 2 wrong and 1 missing its domain clause | 1 | none. Traces checked by reading, no verdicts, no mutants, no probe |

One instance each, 2026-09-05. Five staged files per seat, named:
`PROBLEM.md`, `RiverCall.cfg`, and the three pair files under `traces/`.

## Verdict: GREEN, under the shape-D reading

Rule 2 says property content converges by design where the four
requirements ship with their keyword and kind given, so convergence isn't
the leak signal here. It converged between p1 and p2, and it converged
hard. Their four formulas are the same formulas. `ACallIsHonest` differs
only in the order of the two conjuncts in its antecedent (`p1.md:40`
against `p2.md:49`), and the other three match term for term. Two families,
no spec shipped, and the same four lines.

The discrimination lives where the cell's design says it should: in the
kinds, the subscripts, the instruments, and for shape D in the diagnosis.
That's where the panel splits, and it splits two to one on every one of
them.

**The subscript and the pre-state read.** p2 built two runs, `T7` and
`T8`, for rule 7's last clause: a junior rising in the same act the caller
drops the call, and a junior rising in the same act the call goes out
(`p2.md:77-80`). p2 says outright that a property reading
`Observe'.calling` gets `T8` wrong. p3's requirement 3 reads
`calling'[s]` (`step6-panel/p3-RiverCall.tla:51`). So p2 built the
instrument, blind, for the defect p3 shipped. I ran the joint act rule 7
licenses against both readings, in a scratch module holding the two
formulas over one forced step. The step is owner 1's honest call going out
in the same act owner 3 rises 0 to 1, on a flow of 3 with owner 2 holding
2. The post-state form returns rc 13 and the pre-state form returns rc 0,
two states each. Nothing shipped catches this, because every pair moves
one field per step.

**Rule 5's arithmetic.** p3's shortness reads
`Available(o) + diverted[o] < Decree[o]`, where `Available(o)` already
adds the owner's own draw back in
(`step6-panel/p3-RiverCall.tla:17-19`). It counts the owner's diversion
twice, so an owner holding water is judged less short than the rules make
them. A probe conjoining p3's `IsShort` against the reference's `Short`
as an invariant over p3's own reachable graph is violated at depth 3, on
`(1, 2, 0)` at a flow of 3, where the reference calls owner 1 short and
p3 doesn't. This isn't the own-draw reading step 5 predicted and it isn't
the seniors-only reading. It's a third one, and everything shipped passes
it.

Two smaller things in the same module, for the table's sake. p3's
requirement 1 keeps the range and the boolean typing and drops the domain
clause (`step6-panel/p3-RiverCall.tla:43-45`), which is the hole step 5
predicted for requirement 1, arriving on a different clause than it
expected. And p3's `Total` sums owners 1, 2 and 3 by name rather than over
`Owners` (`:13-15`), so the model is right at the checking instance and
isn't a model of the system the statement describes. Neither is graded by
anything that ships.

**The numbers that should have caught it, and didn't.** p3 reports 721
generated, 136 distinct, depth 9 on the checking instance (`p3.md:16`).
p1 and p2 both report 757, 136, depth 8 (`p1.md:60`, `p2.md:68`), which
is what step 2 measured. I reran p3's spec on the checking instance and
got the same three numbers. The statement offers 136 as the number to
compare against (`PROBLEM.md:232-236`), and p3 hit it exactly. 136 is the whole
flow-legal, type-legal state set, so any model reaching all of it reports
136 whatever its transition relation does. The self-check the statement
gives can't see a wrong model. That's finding 4.

**The diagnosis.** This is the graded half and it's where the split
matters most. p1 and p2 both reached the mechanism and both proved it.

p1 named it in one line, that flow 6 equals the sum of the decrees so
nobody is ever short (`p1.md:95-96`), then ran five single-edit mutants
across both cfgs. Four of the five reproduce the shipped output byte for
byte on flow 6 and die at flow 3 (`p1.md:100-108`). One of those four,
`MutNoCall`, passes all four checks on every instance and is exposed only
by the state count and the allowed runs (`p1.md:109-110`). p1 closed with
the behavior the rules allow that flow 6 can't show, walked step by step
out of TLC's own counterexample (`p1.md:111-113`).

p2 reached the same mechanism by the same arithmetic (`p2.md:100-102`),
built a three-invariant probe over the complete flow-6 graph, and ran two
mutants against the shipped cfg for the digit-for-digit match
(`p2.md:106-109`). Then it did the thing nobody else on this panel did.
It argued against its own case: requirement 4 is not fully vacuous on
that instance, because deleting the honesty guard does fail there at rc
13, since with nobody ever short "a call goes out honestly" collapses
into "no call ever goes out" (`p2.md:110-112`). So the run establishes
that the model emits no call there, and nothing about which calls are
honest, that set being empty. That's the sharpest single observation on
the panel, and it separates an inert check from one satisfied by an empty
set of steps.

p3 didn't answer the two questions. Its report has no section on the
green run at all. Section 7 is recognition and the report ends. What it
has instead is `p3.md:17`, which records the flow-6 run as "All
requirements pass", and `p3.md:53`, which closes: "All four properties
pass on both configurations (136 and 27 distinct states respectively).
Traces validate correctly. Spec correctly encodes water law prior
appropriation rules." That is the claim the statement puts on the table
at `PROBLEM.md:254-255`, adopted as the seat's own verdict. One seat took
the run as confirmation, which is the failure the rung exists to measure.

So the statement isn't underspecified, since two of three solved the
whole thing first try. It isn't trivial or leaking, since the third
seat missed the graded half entirely and its model is broken in four
ways nothing shipped catches. **Step 6 closes GREEN. The statement
stands.**

I'd add one bound on that. The panel measures the statement, and p3's
miss is a seat result, not a statement defect. But I can't fully separate
the two, because I never saw the brief the seats ran under, and section 7
of both p1 and p2 is recognition while their green-run answer sits in an
improvised slot (`p1.md:91`, and `p2.md:97`, which isn't numbered at
all). If the section list handed to the seats ran 1 to 7 with recognition
last and no slot for the two questions, then a seat following the
template literally drops the graded half, and p3 did exactly that
[INFERRED, from the three reports' section numbering].

## Findings carried forward

1. **The console block settles the atomicity decision by arithmetic.**
Step 5's screen called the unit of one act the decision the problem turns
on, and said nothing in the statement settles it. Both p1 and p2 settled
it before opening TLC, off the shipped run's numbers. 163 generated over
27 distinct is 27 times 6 plus 1, which forces one owner per step and
forces a same-setting step to be excluded. Allowing that step would read
27 times 9 plus 1 (`p1.md:76-78`, `p2.md:85-87`). Same number, same
route, two families, independently. This doesn't leak the graded answer,
because step 2 found a joint step lands on the same properties either
way. It does mean the modeling judgment step 5 named as central gets read
off a page rather than reasoned. Worth knowing before the next shape-D
rung quotes a generated count.

2. **p3's post-state read on requirement 3 is a grading hole, and p2
built the instrument for it.** Rule 7's last clause says the call reaches
the rise if it was standing when the rise began, whatever happens to the
call in the same act. A property subscripted correctly but reading
`Observe'.calling` gets that backwards, and passes every pair, because
every shipped pair moves one field per step. p2's `T7` and `T8` are the
two runs that separate the readings, and it built them blind. The
grading split should carry the pre-state read as a formula-read item
alongside requirement 3's second quantifier, and if a fourth pair is ever
worth spending, the joint-act pair is the one to spend it on.

3. **Rule 5 admits a third wrong reading nobody predicted.** Step 5's
grading split named the own-draw reading (caught by pair 3) and the
seniors-only reading (uncaught, measured at step 2 as S12). p3 shipped a
fourth: adding the owner's own diversion back on top of a quantity that
already includes it. It's stricter than the rules, so it emits fewer
calls, and every shipped check passes. Rule 5 is graded by nothing that
ships except pair 3's honest-call antecedent, and pair 3 only fires when
the caller sits at zero. Read rule 5 off the formula, the way step 5
already says to read requirement 1's range off the formula.

4. **136 alone can't tell a right model from a wrong one.** The statement
offers 136 as the number to compare against, and warns that a count well
under 136 is worth a look back (`PROBLEM.md:232-236`). p3 reported 136
and was wrong twice over. 136 is the full type-legal, flow-legal state
set, so it says nothing about the transition relation. The numbers that
did separate p3 from the other two are the generated count and the depth.
I'd hold off on adding those to the statement, though, because
finding 1 is the cost of quoting them: every extra number pins more of
the action decomposition. The honest fix is a sentence saying that
hitting 136 says the model reaches the right states and says nothing
about how it gets there. That costs no information and closes the false
comfort.

5. **Recognition.** p1 and p2 both named the mechanism family on first
read, p1 as a no-preemption priority lock with a hold flag (`p1.md:118`)
and p2 as a priority-ordered advisory lock with no lock manager
(`p2.md:117-118`). Both say it shaped the state and nothing else. Neither
recognized a published problem, and p1 says so outright (`p1.md:119`).
p3's section 7 names prior appropriation water law (`p3.md:49`), which
the statement's own first paragraph hands over at `PROBLEM.md:6`, so I'd
record that as reading the statement rather than as recognition. No stops
and no disqualifications. Recorded, not fired.

6. **D1 and D2 landed and the route they opened is closed.** The step 5
report rejected the statement on the route and asked for two rewords.
`PROBLEM.md:218-219` now reads that a flow of 3 against three decrees of
2 makes shortage reachable, with the generalizing arithmetic gone, and
the 100-state sentence is now a comparison against 136 with the
downstream clause gone (`PROBLEM.md:232-236`). Step 5 asked whether a
path to "shortage never happens" survives that doesn't go through the
learner's own model. On this panel it didn't. Both seats that reached
the mechanism reached it by their own arithmetic and then proved it with
mutants, and the seat that didn't build a model of the rules didn't
reach it at all.

## Rule 6

All three seats came back first-try clean on their own spec and none
revised mid-way, which under this shape says little on its own. The flag
reads against the instruments and the diagnosis instead, and there the
panel splits two to one rather than three to nothing. Recorded, not
fired.

**Step 6 closes GREEN. Statement stands. Step 7 next.**
