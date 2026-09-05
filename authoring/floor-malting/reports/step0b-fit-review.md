Filed by central after the harness refused the reviewer's own write.

# Fit review, floor malting, rung 5 of batch 2

Opus reviewer, read-only, 2026-09-05, against `authoring/floor-malting/DESCRIPTION.md` at `a51938c`. Bead `tla-h2cg.11`. Filed by central because the harness refused the reviewer's own write.

**SEND BACK.** One blocking defect, four minor. The property set has no hole, the arithmetic is exact, and the domain holds. This isn't a trim and it isn't a domain change. The blocking one is two sentences of repair.

## The defects, dearest first

**D1, blocking. The fairness diagnostic is false, and it's inside the hand-off.** `DESCRIPTION.md:123-125`, checklist items 8 and 12.

The text says weak fairness on "a maltster acts" "obliges no removal at all", because turning is something a maltster does. Re-derive it. Rule 3 (`:57-58`) guards turning on `modification < UpperMark`, and modification only rises (must-be-true 4), so each piece takes at most `UpperMark` turnings and the whole floor takes at most `|Pieces| * UpperMark`. Now take `A` to be "maltster m acts". While any piece is on the floor, `A` is enabled, since kilning and throwing out are unguarded. `WF(A)` then forces `A` infinitely often on any behavior that leaves a piece down. Only finitely many of those occurrences can be turnings. So removals happen, and the floor clears. The coarse form obliges item 7 after all.

The prescription above it is still right, and it's the one the rung asks for. Kind 3 wants the fairness on a named step, and per-piece weak fairness on the removal of that piece is that. The repair is to swap the reason, not the shape: the coarse form happens to clear the floor here too, because Rule 3 caps the turnings a piece can take, but it names no step and it gets there by an argument the reader has to reconstruct. Take the per-piece form, and drop the sentence telling the author to check for the coarse form first. `:125` otherwise sends a reference author hunting a bug that isn't there, and the natural "fix" is to reach for strong fairness.

**D2, minor. Section 1 never says the count belongs to the floor.** `:43-44`, `:99`, `:161-162`, item 5.

Rule 2 says modification is "the number of times it's been turned", which reads as a fact that survives the kiln. Must-be-true 2's second clause and the `modification` field's none marker then arrive as news. Add a sentence to Rule 6 at `:79-82`: a piece off the floor has no modification, and the count goes when the bed does. The alternative is live and belongs in section 6 as item 15: keep the count after the kiln, which costs must-be-true 2 its second clause and leaves must-be-true 6 to freeze the count instead. Take the drop, because it's the reading that makes must-be-true 2 one rule rather than two.

**D3, minor. A note to the reviewer sits inside the hand-off.** `:223-225`, item 19. "I'd still put a reviewer's eye on it, because a way in nobody grades is the easiest thing in this form to leave open" is addressed past the reference author. Cut it. The claim before it stands on its own.

**D4, minor. The `screen.sh` citation is off by three.** `:370`, item 19. `grep -n "blood bank" harness/screen.sh` puts the row at 115, not 112. The screen report carries the same number, so the description inherited it.

**D5, minor. Section 5's stored "gone over" reads as a third reference variable.** `:298-301`, item 3. A learner who stores "gone over" as a fact is fine, since the level is measured on the reference. But that paragraph sits three lines above `:303-305`, which says the reference carries the two fields and no others, and a careless reader takes the first as licensing the second. Say whose choice it is. The fork list at `:290` should also carry the stored-flag arm.

## The checklist

1. Fields state-dependent. PASS. Two fields, both per-piece facts about now (`:157-162`).
2. Sufficiency at the obligation level. PASS. Every row re-derived. Rule 3's guard is graded by must-be-true 2 at `:213`. The two ungraded clauses at `:227-232` are correctly named.
3. Representation neutrality. PASS, with D5. All six forks survive both fields.
4. Section 3.2. PASS. One narrowing, modification as a count of turnings, declared at `:52-53` and section 6 item 4.
5. Self-contained under caveat 2. D2. The marks, the turning guard, the kilning guard and the interleaving all settle.
6. The declared ambiguities. D2 adds a fifteenth. The other fourteen hold up.
7. The shape alibi. PASS. One stage value per piece makes the two-places state unrepresentable, and `:313-317` applies the rule correctly. The count is kept at `Nat` (`:174-175`) and must-be-true 2 does the bounding.
8. Never-open cases. D1. The way-in argument at `:219-222` re-derives. Quiescence at `:273-277` re-derives.
9. Step kinds defined observationally. PASS.
10. Permission-shaped rules. PASS. Rule 5's free judgment is named as ungraded.
11. Count. PASS. Seven items plus the type invariant, 8 cfg lines. Whose type invariant is settled at `:132-134`.
12. Kinds. D1 on the reason. One invariant (2), one opening predicate (1), four action properties (3, 4, 5, 6), one liveness (7).
13. Parties. PASS. Several maltsters, one kind (`:28-32`). No clock, no unassigned step.
14. Bounds. PASS. Six records per piece, all reachable, pieces independent, so 216 exactly.
15. Section 3.9. PASS. All seven violating traces worked and each isolates.
16. Kind labels. PASS. The opening condition is a temporal formula, the subscript is fixed on the whole of `Observe` at `:127-130`.
17. What's left for the learner. PASS. Shape A, no fork closed by a field. The loss fork is unobservable by construction.
18. Section 3.10. PASS, with a caveat. Nothing here is control, cooling, sensing or plant, and section 6 item 12 holds that line. But strip the malting words and the mechanism is a value that has to sit inside a low and high limit before an irreversible disposition, not far from a hi/lo band on a batch in food and beverage processing. It clears because the count moves only by a discrete human act, no instrument reads it, and the learner's work is representation. Don't reuse this shape on a rung where the domain reasoning is the work.
19. Prose. D3 and D4. Zero em dashes, zero semicolons.

## Notes for the reference author's brief

- Whichever arm of the maltster fork the author takes, `Maltsters` has to appear in the reference. Bare actions that drop the quantifier leave the sources-1 row in `VECTOR.md` with nothing to cite.
- Central has ruled that the reference carries no `pc`. That makes 216 the number. A single-label non-looping PlusCal process set still carries `pc` at the label and at `Done`, which is the 864 case, so plain TLA+ for the system half is the safe route.
- Must-be-true 4's title says "Turning adds one" while its body grades every floor-to-floor step. The body is right.
- The way-in argument at `:221-222` credits `stage` being total over `Pieces`. The value set in the type invariant is what rules out a fourth place.
- Nobody has run the instance. The 216 is arithmetic.
- The preamble at `:11-13` carries the grid cell. Leave it behind when pasting.
