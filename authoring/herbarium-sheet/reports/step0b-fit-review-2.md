> Filed by central after the harness refused the reviewer's own write. The text below is the review as delivered, unchanged.

# Second-pass fit review, the herbarium sheet, rung 6 of batch 2

Opus reviewer, read-only, 2026-09-05, against `authoring/herbarium-sheet/DESCRIPTION.md` at `f5fac4b`. Bead `tla-h2cg.12`. Filed by central because the harness refused the reviewer's own write. All nine of the first review's repairs landed.

**SEND BACK.** No blocking defects. Four minor, all prose folded into items that already exist, none costing a cfg line and none closing a fork. Both blocking defects are closed.

The two blocking repairs check out. The accepted-name step rule is gone (`:359-364`), the seeded defect sits on the doubt rule subscripted on `Observe.slips` (`:433-434`), and `Observe.slips` is pinned as a set of pairs with the sequence and map forks left standing (`:187-190` against `:326`).

## The defects

**R1, minor. A botanist's reading has no provenance, and the slip's stamp is graded only as a cap.** `:60-61`, `:66-68`, `:123-127`, `:128-132`. Items 2 and 10.

Item 3 grades a reading only at a step where the count rises. Nothing grades a reading at any other step. A model where a botanist's reading goes from none to 1 with no consultation passes all seven, and then rule 2's "a consultation hands the botanist that new number" is true one way only. Separately, rule 3 says the slip carries "the stamp of the consultation it came from", an equality. Item 4 grades "at most". A botanist who files below the stamp they hold passes.

Repair, no cfg line. Add one clause to item 3: a botanist's open consultation of a sheet takes a stamp only at a step where that sheet's count rises to that stamp. Then name the second gap in the ungraded paragraph at `:269-274` rather than tightening item 4. The cap is load-bearing: close the provenance gap and tighten item 4 to equality together, and stamp 2 becomes reachable by one botanist once, so item 1's distinctness clause loses its violating trace and 3.9 fails for it.

**R2, minor. The none marker isn't pinned as a model value.** `:212-215`. Items 3 and 5.

Section 3 says the marker is "a single value that sits outside `Names` and outside the stamps". A string satisfies that. A string marker beside an integer aborts TLC at rc=255 instead of comparing false, and `reading` sits beside stamps in item 1's range clause and item 4's cap. Repair: one clause on `:215`: the marker is a declared constant taken as a model value in the reference, so a comparison against a stamp or a name answers false rather than aborting.

**R3, minor. The widened liveness isn't recorded, and two paragraphs still read against the old one.** `:349-380`, `:366-368`, `:455-456`. Items 2 and 17.

The repairer widened item 6 to carry the consultation obligation and kept the doubt clause under it. That's right, and the first review's D6 was wrong to say the wider clause implies the narrower one. A model where filing leaves the mark on satisfies clause 1 and item 5 both, and the mark never comes off. Clause 2 is what grades it. Two things didn't follow. Section 5's departure note never records the widening. And `:367` says "the liveness grades almost nothing" while `:455` says the seeded defect "takes the liveness with it". Under the wider item 6 a mark that comes off on any step hollows the second clause only. Repair: record the widening as a fifth change, and say "the doubt half of the liveness" in both places.

**R4, minor. Item 6's two clauses need a stated rendering.** `:136-138`, `:363-364`. Item 11.

Two leads-to clauses under one name. Section 5 counts eight cfg lines, which holds only if they conjoin into one operator. Repair: one sentence in the classification paragraph: item 6's two clauses conjoin into one property on one cfg line.

**Item 15's note.** Item 1's violating trace is loose as written: under the set-of-pairs shape two slips at one stamp must carry different names, and then item 2's top slip is a tie. Say "different names" at `:169-170`.

## The checklist

1 PASS. 2 R1. 3 R2. 4 PASS (two declared narrowings, `:344-347` and `:338-342`). 5 R2. 6 PASS. 7 PASS. 8 R3 for `:455`. 9 PASS. 10 R1. 11 R4 (eight lines, band five to nine). 12 PASS (kind 3, weak fairness on one botanist's filing step for one sheet, `:149-158`). 13 PASS (one kind, level 1). 14 PASS (37 times 7 is 259). 15 PASS with the note above. 16 PASS. 17 R3. 18 PASS with the first review's caveat standing. 19 PASS.

## Notes for the reference author's brief

- Nobody has run the instance. The 259 is arithmetic.
- Item 6's second clause has its own isolating trace: consult, doubt, file with the mark left on, then nothing.
- Item 6's violating trace needs the fairness conjunct off, so the 3.9 pair is built against the unfair spec.
- The seeded defect is fully vacuous only because a step touches one sheet. A step that filed on one sheet while clearing a mark on another would be caught.
- Marking a sheet already doubtful isn't resolved anywhere. A stuttering step, harmless, the author's call.
- The rung block pinned the open subscript on the accepted-name rule, and that rule is gone on the first review's instruction. Central decides whether the block moves or the pin was only ever about the sketch.
- `:338` caps the reference at five variables. Hold that line.
