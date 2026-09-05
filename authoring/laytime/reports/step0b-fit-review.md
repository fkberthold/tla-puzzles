> Filed into the record by central after the harness refused the reviewer's own write. The text below is the reviewer's, unchanged.

# Fit review, laytime and demurrage, rung 2 of batch 2

Opus reviewer, read-only, bead `tla-h2cg.8`, against `authoring/laytime/DESCRIPTION.md` at `7f38bfb`. Filed by central because the harness refused the reviewer's own write. All line cites are that file unless named otherwise.

**SEND BACK.** One blocking hole, five minor defects. The domain, the party count, the kinds and the arithmetic are all right, so this is neither a trim nor a domain change. The blocking defect is a claim about downstream grading that doesn't hold, and the repair is prose in sections 3 and 6.

## The defects, dearest first

**D1, blocking. Rule 8's second half is ungraded, and the thing the description says catches it doesn't.** `:235-243`, checklist items 2, 7 and 8.

The description names the hole itself at `:237-239`, which is good. What it does with it is the problem. It says a model that lets excepted periods run free on demurrage "admits a strict subset of the reference's behaviors", so 5.2's two-sided implication catches it. That's wrong twice. A model that permits an extra step admits a superset, not a subset, so even the direction is backwards. And the extra step changes no `Observe` field, which makes it a stuttering step, and TLA+ formulas can't see stuttering. So the wrong model's `Observe` behavior set is the reference's exactly. Both implications in 5.2 hold, both ways, and the learner passes. INFERRED, from 5.2 at `V2-PLAN.md:790-793` and stuttering-insensitivity. I didn't run TLC.

That matters more than one walk row, because `:243` puts the seeded bugs on this rule. A seeded bug built on Rule 8's second half passes every gate silently, which is the pilot failure this whole step exists to stop.

The same reasoning refutes `:197-198`, "There's no state of this system in which the kind is both live and invisible." On demurrage in a wrong model the kind is both. The paragraph argues from the reference's own behavior to justify not observing the thing that separates the reference from the mutant, and that's circular.

The repair. Rewrite `:235-243` to say Rule 8's second half has no property over this interface and nothing downstream sees it either, because the wrong model's extra step is an `Observe` stutter. Fix `:197-198` to say the kind stays out of the operator at the cost of leaving that half of Rule 8 unenforced. Then move the route defence and the seeded bugs onto must-be-true 3 and the loose-latch learner, which is where `:305-309` already points. No cfg line moves, no fork closes, no field is added.

The live alternative is to change the system so the cancellation has counter content. That needs a bounded count of logged periods in `Observe`, and excepted periods are unbounded while the allowance stands, so the bound has to come from somewhere. Every source I can find for it is a calendar wearing a hat, which is the one thing this rung can't have. So I'd trim. If Frank would rather keep Rule 8 as the graded centre, the domain changes instead.

**D2, minor. Pipeline talk sits inside the hand-off.** `:162`, `:190`, `:241-243`, `:278-279`, item 19.

Sections 1 to 4 get pasted into the 9.4 brief. Four sites there name the rung, the property-count band, or the seeded bugs. Rung 1's review cut one sentence for this. The museum house form keeps section 2 clean of it. Cut the rung references and keep the sufficiency reasoning, which the reference author does need.

**D3, minor. Rule 9's cap is two things, and section 4 leans on the invented one.** `:104-106`, `:253-257`, item 14.

Section 4 says every bound is a term of the charterparty first. The cap on the owner's claim is that. "The agent logs nothing further" isn't. A real agent keeps writing and the claim stops growing. Since `Limit` is what makes the demurrage counter finite, the guard is carrying the bound. Split the sentence: the charter caps the claim at `Limit`, and the statement stops there because there's nothing further to record. That answers the author's own flag at `:388-395`, and my read is the cap is fine once the two halves are separated.

**D4, minor. "The only thing left for him to do" reads as an obligation.** `:106` against `:119-122`, items 5 and 12.

Rule 11 settles it, but a reference author who reads Rule 9 first may write a liveness property and blow kind 2. One clause: the only step still open to him is closing, and he needn't take it.

**D5, minor. The walk grades two rules by a line the learner is told not to write.** `:148-151`, `:214`, `:222`, items 2 and 7.

The type invariant is the author's and `:150` says it isn't a learner requirement. The walk then uses it to carry Rule 1's and Rule 9's ranges. For the reference that's a real cfg line. For the learner the carrier is 5.2, since a model whose demurrage passes `Limit` reaches `Observe` states the reference can't. One sentence saying so.

**D6, minor. Section 3.10 is never addressed, and D1 makes it tighter.** Item 18.

The screen report carries the argument (`reports/step0-screens.md:243-263`) and the description doesn't. I'd pass it on the domain. Frank holds no working model of laytime reckoning, and nothing in refrigeration or facility control has a consumable allowance that cancels its own exceptions. The pressure is on the mechanism. Strip the shipping words and what's left is a metered quota with overage billing, which is close to his commercial surface. Under D1's repair the gradeable residue is precisely that quota shape, so the two findings compound. Rung 1's review said not to reuse a domain at shape A without re-running 3.10, and that principle applies to the mechanism here. A paragraph in section 6 saying which half of the domain is unfamiliar and why.

## The checklist

1. Fields state-dependent. PASS. Four fields, all facts about the statement now (`:172-183`).
2. Sufficiency at the obligation level. D1, plus D5. Rules 4, 5, 6 and 7 are graded end to end by 5.2's under-approximation arm rather than by the properties `:217-220` names, which is a looser claim than the walk makes. Rule 8's second half is graded by nothing.
3. Representation neutrality. PASS. All six forks at `:293-303` worked against the four fields and none is closed. The no-latch-field argument at `:185-191` is right.
4. Section 3.2. PASS.
5. Self-contained under caveat 2. D4. Nine readings probed, the rules settle eight.
6. The declared ambiguities. D3 on item 7. The other eleven hold up.
7. The shape alibi. D5. The description avoids the alibi on its face at `:214` and `:222`, and it's right to send the ranges to a cfg line.
8. Never-open cases. D1. The rest re-derive, including the one untendered record and the quiescence call at `:283-287`.
9. Step kinds defined observationally. PASS.
10. Permission-shaped rules. PASS. Rule 11's carrier is the absence of a liveness property and `:224` says so. Rule 2 is named ungraded at `:229-231`.
11. Count. PASS. Four cfg lines: three rendered must-be-trues plus the author's type invariant. Top of the band, no slack.
12. Kinds match. PASS. 1 and 2 are action properties, 3 a state invariant, nothing needs eventually. Kind 2.
13. Parties. PASS. One, the ship's agent (`:27-30`). No clock, no unassigned step, and `Limit` is a guard rather than a forced step.
14. Bounds. D3 on the framing. The arithmetic checks: 36 records in the type space, 5 counter pairs under must-be-true 3, one untendered record, 10 tendered, 11 reachable, each worked and reachable, so 11 is exact.
15. Section 3.9. PASS. Each of the three breaks on a two-state trace and each is satisfied by an ordinary run.
16. Kind labels. PASS. Both step rules subscripted over the whole of `Observe` in prose at `:144-146`. Declining the opening as a fourth line (`:324-329`) is right.
17. What's left for the learner. PASS, weakly. The forks are real and the latch is the one with content. Section 5's `:311-316` pins the reference to four variables, which representation 2 demands and which removes the freedom the screen report parked the route defence on. Step 4 carries that load alone now.
18. Section 3.10. D6.
19. Prose. D2. Zero em dashes, zero semicolons.

## Notes for the reference author's brief

- The preamble at `:11-16` carries the load vector. Leave it behind when pasting.
- Nobody has run the instance. The 11 is arithmetic and `:276` says so.
- Five of the eleven reachable states are terminal, one per counter pair with the statement closed. Configure for that rather than inventing a stuttering action, as `:283-287` says.
- The three must-be-trues are one cfg line each. Must-be-true 1 is four clauses under one name, and splitting it would put the count at seven.
- `Allowance` 2 and `Limit` 2 are the least values that make both step-size clauses bite, a tighter justification than `:264-268` gives.
