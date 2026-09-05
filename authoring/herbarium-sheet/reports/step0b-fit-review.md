> Filed by central after the harness refused the reviewer's own write. The text below is the review as delivered, unchanged.

# Fit review, the herbarium sheet, rung 6 of batch 2

Opus reviewer, read-only, 2026-09-05, against `authoring/herbarium-sheet/DESCRIPTION.md` at `7679dbc`. Bead `tla-h2cg.12`. Filed by central because the harness refused the reviewer's own write. All line cites are into that file unless another path is given.

**SEND BACK.** Two blocking defects and seven minor ones. The domain, the parties, the weight and the voice are right, so this isn't a trim and it isn't a domain change. Both blocking defects land on the diagnose object.

## The defects, dearest first

**D1, blocking. Must-be-true 5 is implied by 1 and 2, and it's the line the seeded defect sits on.** `:128-129`, `:114-121`, `:400-402`. Items 2, 11 and 15.

Item 2 pins the accepted name to the name on the highest-stamped slip in every state, and item 1's distinctness clause makes that a well defined function of the slips. So if the accepted name changes across a step, the slips changed. That's item 5, in full. It follows from item 2 alone.

Two consequences. The count is nine cfg lines, the top of the band, and one of the nine grades nothing. And no violating trace isolates item 5: the trace offered at `:165-166`, a consultation that moves the accepted name, breaks item 2 in the same state.

The cost lands in section 7. The seeded defect is a vacuous pass on a rule that was already surplus, so the sharp learner's answer is not the intended one. They can say the check never fires and that it wouldn't have mattered, because item 2 catches every state item 5 was written for. `:406-407` is also wrong on its own terms: item 5 only ever catches an accepted name moving with no slip appearing, and a consultation is one candidate step for that, not "the step the rule was written for".

The vacuity mechanics hold. Under `_(Observe.doubted)` the only steps evaluated are a marking and a filing that clears a mark, and the body is true on both. The mechanism is real. The rule under it isn't.

Repair. Drop must-be-true 5 and move the seeded defect onto must-be-true 6, subscripted on `Observe.slips` instead of the whole of `Observe`. Then the stuttering steps are exactly the counterexamples, since a doubt clearing with no slip filed leaves `slips` untouched. The hidden model is the one the description already names as the hole at `:342-344`, a mark that comes off on any step, and it takes item 7 hollow with it. The neighbour story at `:411-414` survives with the sign flipped: item 5's own subject is the slips, and copying its subscript one rule down is the same invited mistake. The count drops to eight, and section 5's departure note at `:336-355` needs a fourth change recorded.

The live alternative is to keep item 5 and weaken item 2 so the accepted name isn't pinned at every state. Don't take it. Item 2 is what the derived-accepted-name argument at `:201-208` exists to protect.

**D2, blocking. `Observe.slips` has no pinned shape, and a formula ships over it.** `:181`, `:310`, `:400-402`. Items 3 and 17.

This is the first rung where the state is the learner's and a property ships rather than a spec. A shipped formula has to read against every conforming learner's operator, so every field it touches needs one shape. Section 3 pins four of five. `slips` says only "the slips filed on it, each slip a name and a stamp", and section 5 at `:310` offers a set, a sequence, or a map from stamp. Under a set "a slip appears" is a superset test. Under a sequence it's a length test. Those are different formulas.

Repair, closing no fork. Add to the `slips` paragraph that as a field, `Observe.slips` is for each sheet the set of pairs of a name and a stamp, whatever the model stores. Say what the none marker is, since three fields use one. `:218-223` already says a field is what must be reportable and not what the state is, so a sequence model computes the set and `:310` stands.

**D3, minor. Three clauses of section 1 have no property, and the walk claims two of them do.** Items 2 and 10.

A consultation adds one to the count and hands the botanist that new number (`:43-45`). Nothing makes the rise exactly one, and nothing ties the botanist's resulting reading to the new count. A model whose consultation bumps the count by two passes all eight.

A consultation stays open until the botanist files (`:58-59`). Item 4 runs one way only. A model with an abandon step, setting a reading back to none with no slip, passes all eight, and then the stamp a botanist carried need never reach a slip.

One slip per filing (`:65-68`). Item 4 caps the new slip's stamp and doesn't say one slip appears.

Repair, no cfg line. Fold the first into item 3 and the other two into item 4:

3. The record only grows, one consultation at a time. From one moment to the next, no slip leaves a sheet, no slip on a sheet changes, and no sheet's consultation count falls. At a step where a sheet's consultation count rises, it rises by exactly one, and one botanist's open consultation of that sheet becomes that new number.

4. A slip comes from a consultation, and never from a later one. At a step where a slip appears on a sheet, one slip appears, some botanist's open consultation of that sheet closes in the same step, and the new slip's stamp is at most the stamp that consultation carried. At a step where a botanist's open consultation of a sheet closes, a slip appears on that sheet in the same step.

**D4, minor. Section 7 never says what ships, and form 1 says the learner picks the subscripts.** `:396-402`. Item 17.

Form 1 means the learner produces the properties and chooses each subscript. The seeded defect arrives with a subscript already chosen. Both can hold, but only if section 7 says which properties the learner writes and which one is handed over green. One paragraph closes it. Section 7 answers the question the screener left open: the diagnose object is neither a spec nor a trace, it's a formula, and a formula over `Observe` gives away no state, so representation 2 and shape D hold together. Say that out loud.

**D5, minor. The state estimate is about double the reachable count.** `:288-296`. Item 14.

The accepted name isn't a free coordinate. First sheet, allowance 2: count 0 is one state, count 1 is six, count 2 is thirty, thirty-seven for the sheet. Second sheet, allowance 1: seven. Nothing couples the sheets, so 37 times 7 is 259. Under 1,000 either way. Replace the numbers. The fallback at `:294-296` now costs a factor of seven.

**D6, minor. The walk's row for rule 7 overclaims.** `:251`, `:101-103`.

Rule 7 says a botanist who has consulted a sheet eventually files on it. Item 7 says only that a doubted sheet stops being doubtful. Repair: widen item 7 to the obligation itself, that an open consultation is eventually closed. Still one leads-to, no line, and it implies the current item 7.

**D7, minor. The slip's contents disagree with themselves.** `:19-20` against `:65-67` and `:181`. Item 5.

The opening paragraph says the slip carries the name, the botanist's own name, and the stamp. Rule 3 and the `slips` field both say name and stamp. Cut "their own name" from `:19-20`, or say the filer's name is on the paper and isn't part of the record this system keeps.

**D8, minor. Item 8's keyword is never named.** `:142`. Item 16. An opening condition ships under `PROPERTY`. One sentence.

**D9, minor. A plan citation sits inside the hand-off.** `:160`. Item 19. Cut "which is what 3.9 needs downstream".

## The checklist

1. Fields state-dependent. PASS. All five vary with the run (`:181-199`).
2. Sufficiency at the obligation level. D1, D3, D6. Rule 6's row at `:250` is right and is the best argument in the file.
3. Representation neutrality. D2.
4. Section 3.2. PASS. One narrowing, the accepted name as its own fact, declared at `:328-331`.
5. Self-contained under caveat 2. D7.
6. The declared ambiguities. PASS. Twelve resolutions, all with a live alternative and a stated cost.
7. The shape alibi. PASS. Two shape citations and both are real.
8. Never-open cases. D1's `:406-407`. The other eight re-derive.
9. Step kinds defined observationally. PASS.
10. Permission-shaped rules. PASS. The one ungraded clause is named at `:253-258` and it's inherent.
11. Count. D1. Nine as drafted, eight after the repair. No two items share a property.
12. Kinds match the rung. PASS. Kind 3. Fairness is weak fairness on one botanist's filing step for one sheet (`:144-150`).
13. Parties. PASS. One kind, botanists. No clock. Level 1.
14. Bounds. D5.
15. Section 3.9. D1 for item 5. The other seven each have an isolating finite violating trace.
16. Kind labels. D8. Every step rule is subscripted over the whole of `Observe` and `:152-154` says so.
17. Shape D specifics. D2, D4.
18. Section 3.10. PASS, with a caveat. Strip the botany and the mechanism is an append-only record with a derived head, closer to Frank's schema, and at representation 2 that schema reaches the state design. Two things hold it: section 3 closes the derived-head fork by fiat, and the reading being state is the part the reflex doesn't hand over.
19. Prose. D9. Zero em dashes, zero semicolons.

## Notes for the reference author's brief

- Nobody has run the instance. The 259 is arithmetic.
- Item 7's violating trace needs the fairness conjunct off, so the 3.9 pair is built against the unfair spec.
- The "comes off on a filing" half of `:96-97` is graded by item 7, since a model where filing leaves the mark on has no other way to clear it.
- Flagging a sheet already marked doubtful isn't resolved anywhere. A stuttering step, harmless, the author's call.
- `:322` caps the reference at five variables. Hold that line. `slips` is a computed field.
