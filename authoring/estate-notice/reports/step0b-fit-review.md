Filed into the record by central after the harness refused the reviewer's own write.

# Fit review, the executor's notice to creditors, rung 7 of batch 2

Opus reviewer, read-only, 2026-09-05, against `authoring/estate-notice/DESCRIPTION.md` at `68f3b55`. Bead `tla-h2cg.13`. Filed by central because the harness refused the reviewer's own write.

**SEND BACK.** One blocking gap in the hand-off, five minor defects. No hole in the property set, which is the first description in this batch I can say that about. The domain, the weight and the arithmetic all hold, so this is neither a trim nor a domain change.

## The defects, dearest first

**D1, blocking. The opening state is only in section 6, and section 6 gets stripped.** `:7-9`, `:364-368`, item 5.

The hand-off is sections 1 to 4. The only opening fact in it is `:53`, "It stands open from the start", which covers the notice. Nothing in 1 to 4 says every creditor starts with nothing lodged, and nothing says the residue starts in her hands. Both facts sit at `:332` and `:364-366`, inside section 6, which `:7-9` keeps out of the author's brief. So the author writes `Init` from a guess. A wrong guess is ungraded too, since ambiguity 13 drops the opening property on purpose and I agree with that call.

The repair costs no cfg line. Add a clause to Rule 1 at `:44` saying every creditor starts with nothing lodged, and one to Rule 7 at `:86` saying the residue starts with the executor. Ambiguity 13's reasoning stands unchanged, and the count stays at 8. The museum does exactly this at its Rule 2 and then still spends a property on the opening, which this rung can't afford.

**D2, minor. A rejected system choice is filed twice as a representation fork.** `:270-271` and `:263-264`, items 8 and 17.

The Out of time fork offers "a fact derived from a closed notice and an empty file". Work that model through must-be-true 2. At the close step every creditor with nothing lodged flips to out of time in the observation. Item 2 fires on that step, the notice was open before it, so item 2 demands he move to lodged. The derived model violates its own property list on the very step that closes the notice. The Standing fork's "set of claim records the executor holds" side reaches the same place, because a creditor with no record is out of time only by the same derivation.

This isn't a representation choice at all. It's ambiguity 5 (`:340-342`), which the description already settled the other way, and it's re-offered here as free. Repair: restate both sides so the late creditor is recorded rather than derived. Something like "a standing the creditor reaches, or a separate came-forward marker read against a closed notice". The fork stays real in that form.

**D3, minor. One claim at a time is ungraded, and the walk claims a shape alibi for it.** `:211`, `:74-77`, `:352-355`, items 2 and 7.

`:211` says one at a time "rides the fact that a step changes one creditor's standing". That's a fact about the reference's actions, not about the operator's shape, so it fails item 7's test. A step that decides two creditors together satisfies items 2, 3 and 4 for both of them. Contrast `:207`, where one place at a time really does ride `standing`'s shape, since a function value is single. That one passes.

Name it ungraded rather than grade it. The description already carries a paragraph for the who-acts family at `:217-221`, and this belongs in it as a second sentence. The live alternative is an action property saying at most one creditor's standing changes at a step, which fits (count goes to 9, band is 5 to 9) and would catch a batch model. Take that if the variant pass turns out to want a batch mutant. For now the honest sentence is cheaper.

**D4, minor. Section 2 tells the author the fairness hunt is the substance, and section 5 knows it isn't.** `:138-140` against `:299-309`, items 2 and 12.

The author's finding at `:305-307` is right, worked independently. Every action permanently disables itself, `Creditors` is finite, so the graph is a finite DAG. A terminal state needs the notice closed, nobody lodged and nobody admitted, and at that point Distribute is enabled. So no terminal state holds the residue, `WF_vars(Next)` drives every behavior to a terminal state, and item 7 comes out true. The four-conjunct claim at `:134-138` is also right, all four drops checked. Both are true at once.

What's wrong is `:139-140`, "working out which four they are is the substance of this problem". Section 5 refutes that and the author never sees section 5. Repair: cut the sentence and put the finding in the hand-off, said plainly. The reference ships the four named conjuncts because the statement is written from the frozen spec, and blanket fairness would carry a lesson the system can't defend.

The rung survives this. The screener's case for the domain leaned on rule 8, but the vector's new high is step sources 2, and two kinds of party pay for that directly. The fairness question is now a step 4 job, which is where `:308-309` already puts it.

**D5, minor. Under form 1 no rule's subscript is named.** `:309`, item 16.

`:309` says "the subscript is withheld" and stops. Form 1 is one property's subscript target left open, and the description should say which. `:142-144` is otherwise the best handling of the qsl hazard in this batch. One sentence in section 5 naming the property finishes it.

**D6, minor. The sets paragraph reads as a ban inside the hand-off.** `:181-187`, items 3 and 4.

"I closed that here, at the cost of one degree of the author's freedom" is true of the reference, which section 5 pins to three variables anyway. Read cold by an author who has only sections 1 to 4, it reads as a ban on set-shaped models. A partition is disjoint by definition and computes `standing` fine. Add the clause, and the fork at `:263-264` stops contradicting section 3.

## The checklist

1. Fields state-dependent. PASS. Three fields, all facts about now (`:171-179`).
2. Sufficiency at the obligation level. D3, D4. The standing transition graph is fully graded: item 2 owns every move off nothing lodged, item 3 every move off lodged, item 4 the three terminal standings and admitted. Rung 1's D1 hole has no analogue here.
3. Representation neutrality. D6.
4. Section 3.2. D6. The one declared narrowing is at `:274-280` and it's the rung, not a choice.
5. Self-contained under caveat 2. D1. One thin spot, not a defect: `:19-20` says she can't know who's owed, and `:44` names `Creditors` up front. No rule lets her act on an un-lodged creditor, so it doesn't bite.
6. The declared ambiguities. PASS. All fourteen hold up.
7. The shape alibi. D3. `:207`'s one-place argument passes.
8. Never-open cases. D2. The rest re-derive. Quiescence at `:252-256` is right.
9. Step kinds observational. PASS.
10. Permission-shaped rules. PASS. `:215` names the absence of creditor fairness as the carrier for Rule 9.
11. Count. PASS. Eight cfg lines: TypeOK and item 1 as `INVARIANT`, items 2 to 7 as `PROPERTY`. Band is 5 to 9.
12. Kinds match the rung. D4. One eventually (item 7), five action properties, one state invariant, fairness named on four executor steps and none on the creditors. Kind 3 is met.
13. Parties. PASS. Executor plus creditors is two kinds, level 2. `:38-40` rules out a clock. No step belongs to nobody.
14. Bounds. PASS, and the arithmetic is exact: 5^2 + 6^2 + 4^2 is 77, every state reachable. Three creditors is 405, four is 2,177.
15. Section 3.9. PASS. Items 1 through 6 each have an isolating short trace. Item 7's witness is a stuttering lasso and `:155-158` says so.
16. Kind labels. D5. `:142-144` fixes the subscript in prose.
17. What's left for the learner. D2. Six forks, four of which survive as written.
18. Section 3.10. PASS. Estate administration isn't IoT, facility management, control systems or software. Gather-then-commit is familiar shape, but the late claim re-pointing at a third party has no software analogue. That clause carries 3.10 here, so don't let step 4 write it out.
19. Prose. PASS. Zero em dashes, zero semicolons.

## Notes for the reference author's brief

- `authoring/buyclub/reference/BuyClub.tla:11` is `VARIABLES phase, book, share`, and line 61 is `Spec == Init /\ [][Next]_vars /\ \A p \in Products : WF_vars(Deliver(p))`. That's the fairness shape this description wants, at the same ch11 gate, so the no-PlusCal narrowing has a precedent.
- The narrowing at `:274-280` is addressed to the reference author but filed in section 5. Central carries it into the brief by hand.
- Nobody has run the instance. The 77 is arithmetic.
- The preamble at `:11-12` carries the grid cell. Leave it behind when pasting.
