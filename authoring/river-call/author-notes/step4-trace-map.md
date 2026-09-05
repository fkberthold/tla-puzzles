# river-call step 4 — author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/river-call/statement/traces/` to the frozen reference obligation it
witnesses, with the provenance of both halves. Bead `tla-h2cg.9`, rung 3 of
batch 2, shape D at form 0.

The learner-visible artifact set is exactly: `statement/PROBLEM.md`,
`statement/RiverCall.cfg`, and the three files under `statement/traces/`.
Nothing in this file or in `reports/` is reachable from those.

## The map

| pair | obligation | violating half | rc | trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `FlowHolds` | S09 joint-open | 12 | 2 states | T1, rc=12 |
| 2 | `NobodyOpensAgainstACall` | S05 open-ignores-calls | 13 | 4 states | T2, rc=12 |
| 3 | `ACallIsHonest` | S10 call-ungated | 13 | 2 states | T3, rc=12 |

`TypeOK` has no pair. The statement carries it as requirement 1, well-formedness,
and it's the model's own typing rather than a rule about the river. The statement
says so in its traces section.

## Provenance, violating halves

Step 2 committed its variant modules under `reports/step2-variants/`, so nothing
was recreated. Each of the three ran through `harness/verdict.sh -t 300` with its
own frozen `.cfg` and `-workers 1`, keeping the log:

```
verdict.sh -c reports/step2-variants/S09.cfg reports/step2-variants/S09.tla
    SAFETY_VIOLATION       rc=12    FlowHolds, 2 states
verdict.sh -c reports/step2-variants/S05.cfg reports/step2-variants/S05.tla
    LIVENESS_VIOLATION     rc=13    NobodyOpensAgainstACall, 4 states
verdict.sh -c reports/step2-variants/S10.cfg reports/step2-variants/S10.tla
    LIVENESS_VIOLATION     rc=13    ACallIsHonest, 2 states
```

All three match step 2's results table on rc, reported obligation and trace
length. The picks are step 2's section 5 shortlist unchanged: S09 over S03 for
the flow rule, since S03 violates in the initial state and leaves a reader
nothing to walk. S05 over S06, S07 and S08, which all take 4 states by a
stranger route. S10 over S11, which is the same length and asks a reader to hold
two readings of shortness at once.

Traces render over the two `Observe` fields, states only. Action names, module
names and obligation names were stripped by hand. The variant action name
`OpenTwo` never appears.

## Provenance, satisfying halves

Hand-designed so each mirrors its violating twin, then machine-validated against
the frozen reference. There's no stripped learner spec at this shape, so the
reference is the thing the runs have to be behaviors of.

The validator is `TraceVal.tla`, built in a scratch directory and deleted
afterward. It extends a scratch copy of the reference, adds a step counter, and
forces the exact state sequence while conjoining `Next` on every step. The
invariant is `i < Len(Trace)`, so rc=12 means the walk reached the last state and
rc=0 means some step is not a `Next` step.

| trace | run | rc | states walked |
|---|---|---|---|
| T1 | `verdict.sh -c TV1.cfg TraceVal.tla` | 12 | 3 of 3 |
| T2 | `verdict.sh -c TV2.cfg TraceVal.tla` | 12 | 4 of 4 |
| T3 | `verdict.sh -c TV3.cfg TraceVal.tla` | 12 | 3 of 3 |
| T4, control | `verdict.sh -c TV4.cfg TraceVal.tla` | 0 | stalls at 1 of 2 |

T4 is a deliberately illegal control: a call goes out from the opening state,
where three units sit free against a decree of 2, so nobody is short. It came
back rc=0, so the validator can fail and the three passes mean something. T4 is
also pair 3's forbidden half, which makes the control and the pair the same fact
measured from both sides.

## Notes for step 5 and the grader

- Pair 2's two halves differ only in who opens at the last step. The middle
  owner opens to 1 in the allowed run, and the junior opens to 1 in the
  forbidden one. Both land the settings at a total of 3, so the flow rule holds
  in both and only the priority rule separates them. That's deliberate. A
  learner whose model is right about arithmetic and wrong about seniority fails
  exactly here.
- Pair 1's forbidden half is a joint step. Two owners rise in one act to 2 and 2
  against a flow of 3. Step 2's finding on joint steps is that the shipped
  obligations quantify over owners rather than over whichever one acted, so a
  joint step lands on the same properties a pair of separate steps would. Don't
  mark a learner wrong for a model that has no joint step at all. Their model
  can't produce the forbidden run either way, which is what the pair asks.
- Pair 3's forbidden half is the wrong-subscript trap made visible. Step 2's
  finding 3 measured it: `ACallIsHonest` subscripted on the settings alone lets
  S10 through at rc=0 over all 136 states, because a call-out step leaves the
  settings alone. The statement fixes the subscript in the requirement lines and
  says why in the paragraph under them, so a learner who follows form 0 can't
  hit it. The trap stays live for anyone who ignores the instruction.
- The statement names four requirements and says four is the whole list. The
  pair count is three, one short of the requirement count, and the statement
  says which one has no pair and why.
- S18 is an uncaught variant and it matters more at this shape than step 2 could
  say. It opens with every call standing, and nothing in the graded set
  constrains the opening. Under shape D the learner writes their own opening, so
  a learner whose model starts with calls standing passes all four checks. Step
  2's finding 1 recommends leaving the gap open at this rung rather than
  spending a fifth cfg line on it, and the statement carries rule 10 as a system
  rule with no requirement behind it. Grading should not read a wrong opening as
  a property-set failure.
