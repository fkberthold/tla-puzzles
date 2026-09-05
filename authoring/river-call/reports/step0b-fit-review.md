Filed by central, because the harness refused the reviewer's own write. Everything below is the reviewer's text, unchanged.

# Fit review, a call on the river, rung 3 of batch 2

Opus reviewer, read-only, 2026-09-05, against `authoring/river-call/DESCRIPTION.md` at `e2cee7c`. Bead `tla-h2cg.9`. Filed by central because the harness refused the reviewer's own write.

**SEND BACK.** Six defects, all cheap, none of them a fork closed. The domain, the weight, the property set and the arithmetic are all right, so this isn't a trim and it isn't a domain change. Rung 1's blocking hole (a forbidden transition no property grades) does not recur here, and the walk was re-derived to say so.

## The defects, dearest first

**D1, blocking for central. Section 7 misreports which property goes vacuous, and it misses the strongest signal it has.** `:380-381`, items 8 and 17.

The seed's arithmetic is sound. With `Flow >= sum(Decree)`, free water in any type-legal state is at least the summed shortfall, which is at least any one owner's own, so nobody is ever short. That holds over every type-legal state and not just the reachable ones, which is stronger than the section claims for it.

But "both step rules pass because their antecedents are never met" is false for must-be-true 2. Its antecedent is a setting rising, which fires on nearly every step of that run. It passes because its consequent holds everywhere, nobody being able to call. Item 3 is the one that's vacuous at the antecedent. The distinction decides what a probe reports and what a learner can see, so it can't stay wrong in the artifact that step 4 works from.

Three repairs, all in section 7. Replace the antecedent clause with the split above. Add the coverage signal to the two at `:392-395`: `-coverage 1` gives the call action a row reading 0 total, which is console-visible and stronger than either signal listed (INFERRED on the action decomposition, though any faithful reference guards a call-out on shortness, and shortness is unreachable). And soften `:392`, since reading `calling`'s value in every state does take a probe, while the state count and the coverage row don't.

Alongside: `harness/vacuity.sh` returns `VACUOUS_DEAD_ACTION` at rc=5 on this seed (V2-PLAN.md:873-889, the `total == 0` predicate). That's this project's own machinery answering the puzzle mechanically. It makes the seed better, not worse, but section 7 should say so and step 4 has to keep the harness out of the learner's hands.

**D2, minor. `diverted` and the settings are never identified, and as written that's a 3.3 hole.** `:161` against `:103` and `:106`, items 2, 5 and 6.

Section 3's field is how much water is going down the ditch. Sections 1 and 2 talk about settings. They're the same thing only if an owner never sets a gate the stream can't fill. Under the other reading, must-be-trues 1 and 2 range over settings that `Observe` doesn't carry, and neither is statable over the operator at all. One sentence in Rule 4 saying a setting and the water actually running are the same here, because an owner checks what the others are taking before they open. Then an entry in section 6 for the alternative, a physical cap where the stream just doesn't deliver, which makes must-be-true 1 unfalsifiable and breaks 3.9.

**D3, minor. Section 4 contradicts section 2 on when shortage starts.** `:249-250`, item 14.

"Shortage takes two owners drawing at once" is false on the suggested instance. The senior alone at 2 on a flow of 3 leaves one free unit, so the middle owner sits at 0 against a decree of 2 and is short. Section 2 uses exactly that state at `:144-146`. Repair both together: "It also sits above any single decree, so no owner can make themselves short by their own draw. One owner at their full decree already leaves a second short, and that's the contention this cell is for."

**D4, minor. Rule 7's timing is unsettled, and section 6 item 10 is what exercises it.** `:76-79`, item 5.

Must-be-true 2 reads the call in the state the step ran from. Rule 7 says "while a call stands", which doesn't settle a step where the caller withdraws and a junior rises together. Section 6 item 10 allows exactly that joint step. One clause in Rule 7: a call reaches a junior's rise if it was standing when the rise began, whatever happens to the call in the same act.

**D5, minor. Section 5's case against shortness-gating switches readings mid-argument, and "locks" overstates it.** `:313-317`, items 6 and 8.

"The moment they take it the senior is short and the rise was illegal" is a post-state reading of the guard. Every other rule is pre-state. Under the pre-state reading the junior's rise from all shut is legal. Under the post-state reading the argument works, but at flow 3 with three decrees of 2 the junior caps at 1 rather than locking at 0. The call still earns its place. Rewrite the paragraph around what the call actually buys: a second piece of decidable state in the learner's hands, and the domain's own mechanism. Say which reading is being refuted, and swap "locks the river" for capping every junior at what a shut senior leaves spare.

**D6, minor. Ramp vocabulary sits inside the hand-off.** `:148-152`, item 19.

"The top of this rung's property-count band" and "push the count to the next level and break the rung" are pipeline talk. Trim to: three is the cap, don't add a fourth, and the opening is covered by the shipped spec's opening state. Move the band reasoning to section 5.

## The checklist

1. Fields state-dependent. PASS. `diverted` and `calling`, both per-owner facts about now.
2. Sufficiency at the obligation level. PASS, re-derived over every way either field can change against the eight things the rules forbid. The two ungraded halves are the who-acts halves of Rules 3 and 8, named at `:207-212`.
3. Representation neutrality. PASS. Both fields survive every fork at `:274-280`.
4. Section 3.2. PASS. One fork closed on purpose, the most-senior-caller-only model, declared with its cost at `:287-293`.
5. Self-contained under caveat 2. D2, D4.
6. The declared ambiguities. D2, D5. The other twelve hold up.
7. The shape alibi. PASS, anticipated at `:122-124` and `:198`.
8. Never-open cases. D1, D5. Quiescence at `:262-266` re-derives.
9. Step kinds observational. PASS.
10. Permission-shaped rules. PASS. Rule 9's carrier is the absence of any liveness property and `:204` says so.
11. Count. PASS. Four cfg lines at the ceiling. The classification paragraph at `:110-113` agrees.
12. Kinds. PASS. One state invariant, two action properties, no eventually, no fairness. Kind 2.
13. Parties. PASS. Several ditch owners, one kind. Flow constant, no watermaster, no clock. Step sources 1.
14. Bounds. D3 on the justification. The arithmetic checks: 17 of 27 setting triples total 3 or less, times 8 call subsets is 136.
15. Section 3.9. PASS. All three pairs at `:135-146` isolate.
16. Kind labels. PASS. `:115-117` pins both step rules to the whole of `Observe`.
17. Shape D, section 7. D1. The seed itself is sound and the defence at `:384-390` is the strongest one available.
18. Section 3.10. PASS, carrying the screener's caveat forward: "flow", "gate" and "shortfall" are Frank's daily refrigeration words. The schema here is a static precedence order over a legal right with nobody arbitrating. For Frank.
19. Prose. D6. Zero em dashes, zero semicolons.

## Notes for the reference author's brief

- Section 7 doesn't pin the shipped instance's numbers. Flow 6 against decrees of 2, 2 and 2 makes the sum a one-glance match. Uneven decrees on a flow that clears them by a unit make the arithmetic less instant.
- The shipped vacuous instance holds 27 states, not 136. `VECTOR.md` should say which instance it cites for the space level.
- The property set is safety-only, so a model that never enables a rise, or whose shortness test is too strict, passes all four lines. Worth knowing before the seeded-bug matrix.
- Section 3's decision to keep shortness out of the operator (`:167-175`) is the best paragraph in the file, and it ties the properties to the constants.
- The preamble at `:11-13` carries the load vector. Leave it behind when pasting.
