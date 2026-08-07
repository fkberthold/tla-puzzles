# Step 6 — the blind-critique spread

Three critics, dispatched concurrently, each in its own directory holding exactly three files
(`PROBLEM.md`, `PermitReview.tla`, `PermitReview.cfg`) and no path to the reference. None saw the
others' work.

## Result

| | E1 | E2 | E3 |
|---|---|---|---|
| Gap 1, unanimity | found | found | found |
| Conjunct submitted | `Observe.issued => Observe.approvedBy = Departments` | identical | identical |
| Route to gap 1 | Rule 3 against line 99 | Rule 3 against line 99 | Rule 3 against line 99 |
| Gap 2, amendment reset | found | found | found |
| Proved gap 2 inexpressible | yes | yes | yes |
| Method for that proof | refinement under a mapping, with a negative control | projected state-graph diff, plus a second correct spec at a different representation | stuttering simulation, plus exhaustive `Observe` state and edge enumeration |
| Attempts to a clean answer | 1 | 1 | 1 |
| Recognized two-phase commit | yes, at Rule 3 | yes, before opening the spec | yes, before opening the spec |
| Time | ~15 min | ~25 min | ~15 min |

## Reading it against the §6 rule

The column-C form of the rule, fixed before dispatch: all three returning the same gap list with
the same witnesses is the leak signal, and it is a failure.

**By that rule, step 6 fails.** Byte-identical conjuncts, one route, seconds to the answer.

## Why, and it is not the route the leakage pass predicted

Agent D predicted the shortcut would be the `.cfg` tiling: six declared checks against seven
numbered rules, two rules carrying no check, and those two being the seeded gaps. That route is
real and E1 and E2 both used it, but only to *confirm*. The route all three took first was
simpler: Rule 3 says "only when every department is holding an approval", line 99 says
`ApprovedBy # {}`. A one-token mismatch.

That is structural. §3.2 obliges the statement to fix the system completely, a critique problem
asks what the spec fails to say about that system, so the answer is a diff between a complete
prose spec and an incomplete formal one. There is nowhere for a gap to hide.

## What the pilot found instead, and it is the useful half

All three spent roughly 80% of their time on gap 2 — not finding it, but establishing that it
cannot be expressed over the observation operator at all. They reached the same conclusion by
three genuinely different instruments, listed in the table above.

That is the diversity §6's spread rule is looking for. It appeared in the verification method
rather than in the answer, and the rule as written cannot see it.

## The mechanism control fired, and the stop-control did not

§9.8 says to stop on a recognized published problem. E2 answered it explicitly — "I do not
recognize this as a known published problem, it reads as a synthetic puzzle, so I proceeded" —
and then named two-phase commit at the end. All three recognized the mechanism, all three at
Rule 3, and two before opening the spec. None was wrong to continue: the problem is synthetic.
The control asks about provenance when the risk is mechanism. The §5.7 screen had already
returned BURNED for this domain, so the screen was right and was run four agent-runs too late.

## One finding that came only from a critic disobeying its own conclusion

E2 built a candidate for gap 2 (a stutter-at-unanimity action property), and it **passes** the
two-sided check against E2's own correct spec while **failing** against a second correct spec E2
wrote at a different representation. It was detecting step granularity, not a missing
requirement.

So "holds against a correct spec" is not a property of the answer. It is a property of the answer
paired with whichever reference the grader happens to hold. E2 caught it only because it wrote a
second correct spec unprompted. A learner would not, and neither would the harness.

Recorded on bead `tla-nyrb`.
