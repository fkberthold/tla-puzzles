# Screens run on the delivered statement

Both screens, run at statement time as §6 step 4 requires, on `PROBLEM.md` as written
rather than on the domain I had in my head.

## §5.7b, the puzzle screen

Worked in order from `harness/PUZZLE-SCREEN.md`. Q1 is the screen and Q2 to Q8 exist to
catch a wrong Q1.

**A note before the answers.** The rubric is calibrated for column A, where the learner
writes the spec. This is column C, where the learner is handed one. That changes Q1 and Q2
in a way I don't want to paper over, so I've answered them for the statement as written
and flagged the mismatch.

| # | Question | Answer |
|---|---|---|
| 1 | anything left to model? | **Yes, but not the actions.** See below. |
| 2 | actions given or decided? | **Given.** This is a puzzle answer and it's structural. |
| 3 | what is asked? | **Is this design correct.** Literally the task sentence. |
| 4 | who works? | **The learner.** TLC adjudicates, it doesn't search. |
| 5 | difficulty? | **Abstraction choice.** 292 states, sub-second. |
| 6 | agents / failure? | **Three kinds, concurrent, revisable.** |
| 7 | delete TLC, decision left? | **Yes**, and it's the strongest answer here. |
| 8 | names an optimum? | **No.** |

**Q1 in full.** The actions are handed over twice, in the rules and again in the attached
spec. What's left is deciding what each rule means as a formal claim, in a vocabulary that
wasn't built to carry all of them. Rule 3 is a state predicate. Rule 5 is a transition
property. `Observe` can express the first and cannot express the second, and working out
which is which is the modeling judgment the problem is made of. That's abstraction choice,
so I read Q1 as a system answer.

**Q2 in full, and the mismatch.** Given. A critique problem hands the learner an action
set by construction, so column C can never answer Q2 "decided". I don't think that's a
defect in my wording, and I don't think I can write it away. I'd flag it to central as a
rubric gap rather than claim a pass I didn't earn. A column-C reading of Q2 would ask
whether the learner has to decide what a *requirement* is, and the answer to that is yes.

**Q4 in full.** This is the one that most clearly separates the task from a puzzle. TLC
searches nothing on the learner's behalf. It checks a conjunct the learner already wrote,
and hand it nothing and it produces nothing. The counterexample only exists once the
learner has done the thinking.

**Q7 in full.** Delete TLC and gap 2 survives intact. Noticing that the amendment action
bumps a counter and touches nothing else, and then arguing that `Observe` gives you no
handle on it, is a pure modeling argument with no model checker in it. That argument is
the most interesting thing in the problem.

**Q6 in full.** Departments act concurrently and revise, and rule 2 makes a position a
current opinion rather than a promise. Rule 4 says the city can stall at unanimity while
approvals evaporate underneath it. Those two rules exist to keep fallibility in the
statement, and they're also the two that settle the atomicity ambiguity.

### Verdict

**ACCEPT, system.** Q1 reads system, and one of Q2 to Q8 reads puzzle. The rubric's tally
rule fires at three, so this clears it.

I did not have to rewrite the statement with agents and fallibility. Rules 2 and 4 carry
that already, and they were written that way from the start because the brief named the
atomicity of issuance as its highest-risk item.

The honest caveat: I'm the author, and the rubric says the author is the worst-placed
person to notice they wrote a puzzle. Q2 is where I'd look first if the leakage checker
disagrees.

## §5.7, the mechanism-collision screen

```
harness/screen.sh --name 'PermitReview' \
  'municipal building permit review with independent departments, applicant
   amendments and withdrawal, city issuance under unanimous approval'
```

Verdict, pasted:

```
--- step 1: NAME collision
    query: 'PermitReview language:tla'
    hits: 0 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    mechanism terms: atomic commitment,two-phase commit
      atomic commitment    3 README row(s) -> BURNED
                             Atomic Commitment Protocol (specifications/acp)
                             Asynchronous Non-Blocking Atomic Commit (specifications/nbacc_ray97)
                             Asynchronous Non-Blocking Atomic Commitment with Failure Detectors
      two-phase commit     2 README row(s) -> BURNED
                             Two-Phase Handshaking (specifications/TwoPhase)
                             Transaction Commit Models (specifications/transaction_commit)
--- §5.7 VERDICT: BURNED   (name: CLEAR | mechanism: BURNED)
```

Exit code 2, BURNED.

### This is not a phrasing accident

`screen.sh:112` maps `permit review` to atomic commitment directly, so the collision is
seeded in the tool's own table. Any honest phrasing of the domain trips it. I checked:

- A phrasing that keeps "permit review" and adds the retraction and reset returns BURNED.
- A phrasing that hides the domain word returns CLEAR, and the tool says that CLEAR isn't
  a clean bill because it may just mean a missing synonym.

I'm reporting the BURNED. Picking the phrasing that clears would be laundering it.

### How much of the collision is real

Real overlap, and it's the load-bearing part. A coordinator commits only when every
participant says yes, and the outcome is absorbing once reached. That's the atomic
commitment skeleton, and the city and departments sit in it exactly.

Where it comes apart:

- **Positions are retractable.** In ACP the prepared state binds, and that irrevocability
  is why 2PC blocks. Rule 2 and rule 4 make approval revisable and explicitly non-latching.
- **No failure model.** All three ACP rows are about crashes, asynchrony and failure
  detectors. This process has no messages, no crashes and no detectors.
- **The amendment reset has no ACP analogue.** A bounded operation that clears every vote
  and restarts the round isn't in that literature.
- **Unanimity reads current opinion**, not an accumulated vote tally. There's no
  collection phase and no coordinator state tracking who has answered.

My read: this is a failure-free atomic commitment with retractable votes and a reset. The
variation is real, and it still sits inside the burned mechanism's neighbourhood. I'd
rather hand central a BURNED with that analysis attached than argue my own domain out of a
tool verdict, since the screen exists precisely because the author is the wrong person to
make that call.

### The process finding underneath it

`V2-PLAN.md:158` lists "municipal permit review with parallel department sign-offs" among
the 17 candidates, and §2.2 says in play is not approved and every candidate must still
pass both screens. The domain isn't in the §2.2 suspicion table, so nobody pre-screened
it. `git log -S 'permit review' -- harness/screen.sh` returns only `d6c914c`, the commit
that created the screens, so the synonym was seeded by the tool author rather than by a
verdict on this candidate.

As far as I can tell this is the first §5.7 run on the pilot domain, and it happened after
the reference was written, verified, repaired and frozen. That ordering looks like the
finding worth central's attention, more than the verdict itself. The pilot is measuring
the pipeline rather than shipping this problem, so BURNED may well be acceptable here. I
don't think that's my call.
