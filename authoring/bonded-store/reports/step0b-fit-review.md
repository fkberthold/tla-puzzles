> Filed into the record by central after the harness refused the reviewer's own write. Text unchanged.

# Fit review, the bonded store, rung 1 of batch 2

Opus reviewer, read-only, 2026-09-05, against `authoring/bonded-store/DESCRIPTION.md` at `411d7e9`. Filed by central because the harness refused the reviewer's own write.

**SEND BACK.** One blocking hole in the property set, five minor defects. The domain, the weight and the arithmetic are right, so this isn't a trim and it isn't a domain change.

## The defects, dearest first

**D1, blocking. A lot can skip the store, and no property grades it.** `DESCRIPTION.md:78-79`, items 2 and 8.

Must-be-true 2 fires only when a lot already in the store changes place. So a step taking a lot from not yet entered straight to released, paying duty in the same motion, satisfies all three. Rule 1 holds on both sides (released and paid). 2 doesn't fire, the lot wasn't in the store. 3 doesn't fire, the appositive at `:80` limits "out of the store" to released or moved on. Not yet entered straight to moved on goes through the same way. The rules forbid both (`:44` release needs a lot in the store, `:58` names the two exits) and nothing in section 2 does. The walk claims otherwise twice: `:139` says rule 2 is constrained by must-be-true 1, true of the duty half and not the transition half, and `:142` says "2 for the exits", true of exits from the store and not of a lot never in it. Section 5 at `:211-215` found the mirror-image hole and plugged it, so I read this as an oversight rather than a call.

The repair costs no cfg line. Split must-be-true 2 in two and renumber leaving-is-final to 4:

2. **The way in.** When a lot not yet entered changes place, its new place is in the store under bond.
3. **The two ways out.** When a lot in the store changes place, its new place is released for home consumption, or moved on under bond.

I checked the three for independence over `Observe`. New 2 alone catches not-yet-entered going to released. New 3 alone catches in-store going back to not yet entered. The renumbered 4 alone catches released turning into moved on. Count stays at three rendered rules plus the type invariant, so four cfg lines, kind stays 2.

The live alternative is one property: "when a lot's place changes, either it was not yet entered and is now in the store, or it was in the store and is now released or moved on". Same hole closed in one line, and it's what I'd take if the rung needed the slot back. It also makes leaving-is-final redundant, since 1 catches a duty flip with place held and the widened rule catches every place change, dropping the set to two rules and three cfg lines. That still sits in the band and matches the floor's line count. I'd go with the split, because it keeps three independent rules and the description's own argument at `:206-209` is against a redundant line.

Rule 2 at `:36-40` should also say entry applies to a lot not yet entered. It's inferable from rule 5 today, and once the new 2 grades that transition it shouldn't stay inferable.

**D2, minor. The subscript is never fixed, and it bites one rule.** `:83-86`, item 16. Both kinds are right and nothing says what the subscript is. The qsl matrix measured a step rule subscripted on one field going green against the mutant it was written to catch (`authoring/qsl/reports/step2-variants.md:273-281`). Here it hits leaving-is-final: under `_(Observe.place)` a released lot's duty flipping to unpaid with place held is exempted, and that's a trace the rule owns. Add a sentence at `:86` saying both action properties are subscripted over the whole of `Observe`, never a field.

**D3, minor. Nothing keeps the shipped spec off the field names.** `:188-195`, item 17. At form 0 the rendering defence is representation 1 and nothing else (`reports/step0-screens.md:66-72`). It holds only if the learner reads the spec to find how the rule's nouns are carried. The fields are `place` and `dutyPaid`, the statement's nouns will be place and duty, and if the author takes the flag-per-lot and status-per-lot side of both forks then `Observe` is the identity over state and every rule is transcription. The forks at `:188-189` already offer the other side. Add a line to section 5: the spec's own variables must not be the field names, so the learner reads a definition rather than a rename. Step 4 has to re-screen this.

**D4, minor. Whose type invariant isn't settled.** `:96` and `:138`, items 7 and 11. Section 2 says the author adds it, the walk leans on it to grade rule 1's four-places clause, and section 2's rendered list has three items. At shape B with form 0 the statement hands over a keyword and kind per requirement, so downstream needs to know whether it's a fourth requirement or ships in the cfg. Either answer keeps the count at four. One sentence at `:96`.

**D5, minor. Section 6 doesn't resolve capacity.** `:219-266`, items 5 and 6. Twelve ambiguities and a real store's capacity isn't one. An author who adds one adds a guard and an invariant, spending the last cfg line. The resolution is that the store holds any number of lots, and it belongs in the list.

**D6, minor. A pipeline citation sits inside the hand-off.** `:121-122`, item 19. Sections 1 to 4 get pasted into the brief. "The screener flagged this and I'm taking it" plus a report path is central's note, and section 5 at `:197-200` already carries the same fork with the same reasoning. Cut the sentence from section 3.

## The checklist

1. Fields state-dependent. PASS. Both are per-lot facts about now (`:108-114`).
2. Sufficiency at the obligation level. D1.
3. Representation neutrality. PASS. Both fields survive both sides of the duty and place forks, since a set model computes them.
4. Section 3.2. PASS. One narrowing, duty as its own state, declared at `:197-200` with its cost. I think it's forced rather than chosen, because a derived duty leaves must-be-true 1 with no violating trace and 3.9 unsatisfiable.
5. Self-contained under caveat 2. D5, plus the entry-source clause folded into D1.
6. The declared ambiguities. D5. The other eleven hold up. Item 3's biconditional argument and item 11's shape argument are both sound.
7. The shape alibi. PASS. One place per lot rides a function's shape, which does make the two-place observation unrepresentable. The four-places clause is correctly sent to a cfg line instead.
8. Never-open cases. D1. The other nine re-derive. Quiescence at `:176-180` is right, and so is the dropped-candidate reasoning at `:206-209`.
9. Step kinds defined observationally. PASS. No property names a step kind.
10. Permission-shaped rules. PASS. Rule 6 is graded by the absence of a liveness property and `:143` says so. Rule 2's who-acts half is named as ungraded at `:145-151`.
11. Count. PASS. Four cfg lines, three rendered rules plus the type invariant. See D4.
12. One step rule, none eventual. PASS. 1 is a state invariant, 2 and 3 are action properties, and `:83-86` agrees.
13. One acting party. PASS. `:24-27`. No clock, no unassigned step.
14. Bounds. PASS. The arithmetic checks. 8 records per lot, 512 at three lots, 4 live records per lot under must-be-true 1, 64 reachable. All 64 are reachable, since the lots move independently, so 64 is exact rather than a ceiling.
15. Section 3.9. PASS. Each of the three has an isolating two-state violating trace. I worked all three and none trips another rule, which is worth more than the description claims for it.
16. Kind labels. D2. Both kinds are right. Dropping the opening condition at `:97-99` is the correct call for this rung.
17. The rendering is real work. D3. Must-be-true 1 is the one rule that can't be pattern-matched off a field name, and it's the whole route defence.
18. Section 3.10. PASS, with a caveat I'd rather state than bury. Frank holds no working model of duty suspension, and the domain isn't IoT, facility management or software. But strip the customs words and the mechanism is a per-entity status field moving one way through a small machine with a flag tied to one terminal status, which is the commonest shape in enterprise software. That's the same objection the screen used to reject the breed registry (`step0-screens.md:509-512`). My read is it's tolerable here and only here, because at shape B the learner writes no state, so a matching schema buys them nothing. Don't reuse this domain at shape A without re-running 3.10.
19. Prose. D6. `grep -n` over the file returned nothing for em dashes and nothing for semicolons.

## Notes for the reference author's brief

- The description's `:264` correction is right. `grep -n warehouse harness/screen.sh` puts the map row at 110, not the 112 the screen report cites.
- The instance justification at `:166-169` is looser than it reads. Two lots already bite must-be-true 1 both ways. Three is the least that holds one lot in each of the three store outcomes at once, which is a fine reason, just not the one given.
- Section 6 item 6 calls a deficiency exit "a fourth must-be-true". Under the D1 repair it's a third arm on the way-out rule plus a restatement of must-be-true 1. Leaving it out still holds, since the count is at the top of the band.
- Nobody has run the instance. The 64 is arithmetic, and `:174` says so.
- The preamble at `:11-14` carries the load vector. Whoever pastes sections 1 to 4 has to leave it behind.
