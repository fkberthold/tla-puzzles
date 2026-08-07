# Agent B: verification of `PermitReview.tla`

Bead `tla-kl5.11` step 2, plus the variant-authoring job from `tla-0kd`.

Toolchain: `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, `pcal.trans Version 1.12
of 01 July 2024`. Both match what the project pins, so the plan's measured constants
apply.

Paths below are shortened. `$H` is `/home/frank/repos/tla-puzzles/harness`, and `$P`
is `/tmp/claude-1000/-home-frank-repos-tla-puzzles/393a48ff-fda1-4d78-b40b-c03dd22af5ef/scratchpad/pilot`.
Every run went through `verdict.sh`. Nothing here reads TLC's prose for a verdict,
apart from the state counts and the coverage block, which are numbers in a fixed
positional format.

## 1. The six checks from V2-PLAN.md 9.5

**Check 1: run TLC, all properties pass.** PASS.

```
bash $H/verdict.sh --log verify/logs/01-reference.log \
     --scratch verify/scratch/01 $P/reference/PermitReview.tla
```

Token `OK`, rc=0.

**Check 2: `-inv FALSE` gives rc=12.** PASS.

```
bash $H/verdict.sh --log verify/logs/02-invfalse.log \
     --scratch verify/scratch/02 $P/reference/PermitReview.tla -- -inv FALSE
```

Token `SAFETY_VIOLATION`, rc=12. Reachable states exist.

**Check 3: `Gate!NonVacuous` passes.** PASS.

```
JAVA_TOOL_OPTIONS=-DTLA-Library=/home/frank/repos/tla-puzzles/harness \
bash $H/verdict.sh --log verify/logs/03-nonvacuous.log --scratch verify/scratch/03 \
     --postcondition Gate!NonVacuous $P/reference/PermitReview.tla
```

Token `OK`, rc=0. The threshold is 4 and the run found 220.

**Check 4: no action has `total == 0`.** PASS.

`verdict.sh` always passes `-coverage 1`, so the block is in check 1's log at
`verify/logs/01-reference.log:40-63`. Four action rows, all with a non-zero total.

| action | distinct:total |
|---|---|
| `Init` | 1:1 |
| `Reviewer` | 104:648 |
| `Applicant` | 111:189 |
| `City` | 4:4 |

The `Terminating` hazard the brief warns about does not arise here. Each process body
is a single-label `while (TRUE)` loop, so the translator drops `pc` and emits no
`Terminating` disjunct. That matches what `alternatives.md` section 6 claims.

The aggregate probe agrees:

```
bash $H/vacuity.sh --keep-logs verify/logs/vacuity reference/PermitReview.tla
```

Token `NON_VACUOUS`, rc=0.

**Check 5: rc=12 on each seeded variant.** PARTIAL. Six of eleven variants are caught,
and one of those six exits 13 rather than 12. Five are not caught at all. Section 3
carries the table.

**Check 6: state counts.** Recorded in section 2.

## 2. State counts

From `verify/logs/01-reference.log:131-133`.

- 842 states generated
- 220 distinct states
- diameter 8

The 220 is not an accident of exploration, and the arithmetic is worth writing down
because the rest of this report leans on it. Type-correct states number 27 position
vectors times 4 amendment values times 3 statuses, so 324. Of those, 104 have
`status = "issued"` with a non-unanimous position vector, and the reference cannot
reach any of them. 324 minus 104 is 220. So the reference reaches every type-correct
state except the ones where the permit issued without unanimity.

That has a consequence I did not expect going in, and it drives most of section 4. An
invariant can only separate a variant from the reference if the variant reaches a state
outside that set. Nothing else is available to a state predicate.

Two claims in `alternatives.md` check out against the same instrument.

Section 4 says 815 distinct at 4 departments and `MaxAmendments = 4`. Measured with
`verify/claims/Four.cfg`: 3975 generated, 815 distinct, diameter 10, rc=0.

Section 7 says the correct spec exits 11 without the `CHECK_DEADLOCK FALSE` line.
Measured with `verify/claims/NoDeadlockLine.cfg` and `verdict.sh -d`: rc=11, token
`DEADLOCK`. Without `-d`, the same config gives rc=0, which is the harness default the
note describes.

## 3. The variant table

Eleven variants, in `verify/variants/`. Each one is the reference with a literal
substitution in the PlusCal source, re-translated by `pcal`. The helper
`verify/xlate.sh` fails the build if a variant's TRANSLATION block still hashes to the
reference's, so no variant shipped without biting. All eleven moved.

`pcal` is a fixed point on the unmodified reference, which also says the author did not
hand-edit the committed translation.

Verdicts below come from one run per variant against the reference's own `.cfg`, so all
four invariants and all three properties were live.

```
bash $H/verdict.sh -c $P/reference/PermitReview.cfg -t 60 \
     --scratch verify/scratch/<name> --log verify/logs/var-<name>.log \
     $P/verify/variants/<name>/PermitReview.tla
```

| variant | rule broken | rc | caught by |
|---|---|---|---|
| `v01-issue-without-unanimity` | city issues on any approval | 12 | `IssuedOnlyWhenUnanimous` |
| `v02-amend-keeps-positions` | amendment does not clear | 13 | `AmendmentClearsApprovals` |
| `v03-review-after-issuance` | reviewers move after issuance | 12 | `IssuedOnlyWhenUnanimous` |
| `v04-withdraw-after-issuance` | withdrawal after issuance | 12 | `IssuanceIsFinal` |
| `v05-issue-after-withdrawal` | issuance after withdrawal | 12 | `WithdrawalIsFinal` |
| `v06-unbounded-amendments` | amendment bound removed | 12 | `TypeOK` |
| `v07-review-after-withdrawal` | reviewers move after withdrawal | 0 | nothing |
| `v08-amend-after-withdrawal` | applicant amends after withdrawal | 0 | nothing |
| `v09-amend-uncounted` | amendment counter frozen | 0 | nothing |
| `v10-observe-fakes-unanimity` | `Observe` fakes unanimity | 0 | nothing |
| `v11-masked-issue-without-unanimity` | v01, with `Observe` masking it | 0 | nothing |

Attribution comes from a second sweep, one single-check `.cfg` per declared check, seven
runs per variant. The full grid is in `verify/logs/attrib/`. Every check is green on the
reference in isolation, so no attribution rests on a check that was already failing.

Counterexample signatures, via `seeded-bugs.sh --trace-signature`:

| variant | signature |
|---|---|
| `v01` | 3 steps: Reviewer, City |
| `v02` | 3 steps: Reviewer, Applicant |
| `v03` | 6 steps: Reviewer, Reviewer, Reviewer, City, Reviewer |
| `v04` | 6 steps: Reviewer, Reviewer, Reviewer, City, Applicant |
| `v05` | 6 steps: Reviewer, Reviewer, Reviewer, Applicant, City |
| `v06` | 5 steps: Applicant, Applicant, Applicant, Applicant |

Each one is the witness the mutation was aimed at, so the six catches are catching the
seeded bug and not some unrelated side effect.

### The five that got through are real bugs, not inert mutants

A variant nobody catches is only interesting if the variant is broken. I wrote a probe
module, `verify/probe/Probe.tla`, to make each brokenness claim falsifiable. It holds
five operators, none of which I am proposing for the reference.

- `TerminalAbsorbingRaw`: `[][ ~Pending => UNCHANGED vars ]_vars`
- `TerminalAbsorbingObs`: the same claim over `Observe`
- `AmendmentCounterNeverMoves`: passes only when no step moves `amendments`
- `RawUnanimityAtIssuance`: unanimity read off the variables, not off `Observe`
- `ObserveFaithful`: `Observe.approvedBy` equals the real approval set

Results across the reference and all eleven variants are in
`verify/logs/probe/`. The reference passes all four correctness probes at rc=0, and
fails `AmendmentCounterNeverMoves` at rc=13, which is what a live amend action should do.

`v07` fails `TerminalAbsorbingObs` at rc=13 on `Applicant, Reviewer`. The applicant
withdraws and a department then changes its position. `v08` fails the same probe at
rc=13 on `Reviewer, Applicant, Applicant`. The applicant withdraws and then amends.

`v09` passes `AmendmentCounterNeverMoves` at rc=0, and it is the only target that does.
The counter never moves, so `AmendmentClearsApprovals` has an antecedent that is never
true. Its whole state space is 55 states against the reference's 220.

`v11` fails `RawUnanimityAtIssuance` at rc=12 and `ObserveFaithful` at rc=12, both on
`Reviewer, City`. One department approves, the city issues, and `Observe` reports all
three as approved.

`v10` passes every probe, including `ObserveFaithful`. Section 4 says why.

### Reachable state sets, dumped and compared

I dumped every reachable state with `-dump` and compared whole records, not lines. My
first attempt compared line-wise and reported every variant identical, including the
ones I knew were not. The negative control caught it. Corrected results:

| variant | distinct | relation to the reference's 220 |
|---|---|---|
| `v01` | 292 | superset, 72 new states |
| `v02` | 220 | identical |
| `v03` | 248 | superset, 28 new states |
| `v04` | 220 | identical |
| `v05` | 220 | identical |
| `v07` | 220 | identical |
| `v08` | 220 | identical |
| `v09` | 55 | subset |
| `v10` | 220 | identical |
| `v11` | 292 | superset, 72 new states |

`v06` is infinite. It reached 945,074 distinct states in 20 seconds and was still
growing when the budget ran out.

### The seeded-bug matrix

`verify/matrix/` holds the matrix. The submitted property is the conjunction of the
reference's four declared invariants, in `.cfg` order. The oracle reads the state
variables instead of `Observe`, because a variant that mutates `Observe` would otherwise
be graded through the thing it broke.

| bucket | variants | rc | token |
|---|---|---|---|
| `variants-catchable` | v01, v03, v06 | 0 | `BUGS_CAUGHT` |
| `variants-masked` | v11 | 40 | `PROPERTY_TOO_WEAK` |
| `solo-*`, one each | v02, v04, v05, v07, v08, v09, v10 | 42 | `VARIANT_INERT` |

The 40 on `v11` is the headline. The oracle catches it, the reference's invariant set
does not, and the matrix says so in the one verdict it exists to produce.

The seven 42s need reading with care, and I would not report them to central as seven
defects in my variant set. Six of the seven are caught by something the reference
already declares, or by a probe. They are inert against the matrix's invariant channel
and nothing more. Section 4 covers why the channel is invariant-only.

## 4. Where measurement contradicts what I was told

**The 9.5 rc=12 expectation is wrong for one of the reference's own properties.**
Check 5 says confirm rc=12 for each variant. `v02` gives rc=13.

```
bash $H/verdict.sh -c $P/reference/PermitReview.cfg -t 60 \
     $P/verify/variants/v02-amend-keeps-positions/PermitReview.tla
LIVENESS_VIOLATION
rc=13
```

This is central's `tla-94n` finding reproducing on this spec, and I claim no credit for
it. What I can add is that the split runs exactly where central said it would.
`IssuanceIsFinal` and `WithdrawalIsFinal` are `[](P => []P)` and give 12 on `v04` and
`v05`. `AmendmentClearsApprovals` and both `TerminalAbsorbing` probes are `[][A]_vars`
and give 13. The rule holds across six independent measurements.

The practical consequence is for `seeded-bugs.sh`, which requires rc==12 exactly. A
matrix can never certify an action property under it.

**`alternatives.md` section 1 overstates what `OutcomeExclusive` guards.** The note says
it "fires if the operator is ever misdefined". That holds for the `issued` and
`withdrawn` fields, and not for `approvedBy`.

I tested both readings. Rewriting `withdrawn |-> status # "open"` makes both outcome
booleans true at an issued state, and `OutcomeExclusive` fires at rc=12
(`verify/claims/observe-both-outcomes/`). Rewriting `approvedBy` is `v10`, and every
declared check returns 0.

`v10` turns out to be inert, which is a finding in its own right rather than a bad
variant. Its reachable state set is identical to the reference's, and `ObserveFaithful`
passes on it at rc=0. The mutated `approvedBy` only differs on issued states that are
not unanimous, and the reference never reaches one. So no property whatever can separate
`v10` from the reference. The `approvedBy` field of the graded interface has no guard,
and on the reference alone it cannot have one.

That is the door `v11` walks through. Combine the `v10` mask with a real break in the
state machine and the mask stops being inert. It hides a permit that issued on a single
approval, and all seven declared checks return 0.

**`alternatives.md` section 2 is right, and understates its own exposure.** The note
says the clearing mutation "runs to completion with every invariant satisfied" and that
`AmendmentClearsApprovals` fires at rc=13. Both reproduce on `v02`: four invariants at
rc=0, the property at rc=13.

What the note does not say is that the property is defeated by freezing the counter it
reads. `v09` keeps the clearing and drops the increment. `AmendmentCounterNeverMoves`
passes on `v09` at rc=0 and on nothing else, so the antecedent
`amendments' # amendments` is never true and the property is vacuously satisfied. The
only formal witness rule 3 has is switched off by editing a variable that rule 3 never
mentions.

**`seeded-bugs.sh` cannot drive a module that declares constants.** Its generated
`.cfg` emits `SPECIFICATION` and `INVARIANT` only, and the header records the missing
`--constants` fragment as deliberate. `PermitReview` declares two constants, so the
matrix copies under `verify/matrix/` replace the declaration with definitions at the
values `reference/PermitReview.cfg` supplies. The specialized reference measures 842
generated, 220 distinct, diameter 8, identical to the declared one, so I think the
substitution is behavior-preserving here. It is still a gap worth a bead if v2 wants
parameterized specs in the matrix.

**`verdict.sh` needs an absolute `--config` when the module path is absolute.** A
relative one gives rc=255 and "File not found" on a file that is there:

```
bash $H/verdict.sh -c verify/cfgs/TypeOK.cfg $P/reference/PermitReview.tla
TLC_EXCEPTION
rc=255
```

`vacuity.sh` and `seeded-bugs.sh` both pass absolute config paths already, so nothing in
the harness is broken. Brief authors will hit it, though, and the token does not point
at the cause.

**One correction to my own work.** My first state-set comparison split the dumps
line-wise and reported all ten variants identical to the reference, including `v01`,
which has 72 states the reference cannot reach. A negative control is the only reason I
caught it. The corrected comparison is the table in section 3.

## 5. Is the reference fit to freeze

I think it is fit to freeze as a specification, and not yet fit to freeze as a graded
artifact. Those are different questions and the answers come apart.

The state machine is right, as far as I could break it. Eleven attempts found no state
the system should not reach and no transition it should not take. The three-valued
`status` does make the outcome exclusive by construction, the clearing on amendment does
keep `ApprovedBy` current, and every action is guarded by `Pending` so both terminal
outcomes are absorbing. `TerminalAbsorbingRaw` passes on the reference at rc=0, which
is the strongest single statement of that, and the reference does not declare it. Both
empirical claims in `alternatives.md` reproduce to the digit. The PlusCal and the
translation are in sync.

The declared property set is where I would hold off. Five of eleven single-rule breaks
went through untouched, and I don't think that ratio is an artifact of picking exotic
mutations. The gaps cluster in three places.

Post-terminal activity is unguarded in the property set. `IssuanceIsFinal` and
`WithdrawalIsFinal` pin the two booleans and nothing else, so a spec where the case
carries on after withdrawal satisfies both. One action property closes `v03`, `v04`,
`v05`, `v07` and `v08` at once:

```
[][ (Observe.issued \/ Observe.withdrawn) => (Observe' = Observe) ]_vars
```

I measured it on all five and it fires on each at rc=13, and passes the reference at
rc=0. It is stated in the observable vocabulary, so it survives a change of state
representation.

The amendment rule rests on a counter that nothing pins. `v09` freezes the counter and
`AmendmentClearsApprovals` goes vacuous. A vacuity guard on the antecedent would catch
it, and I don't have a clean formulation that stays inside the observable vocabulary.
The counter is not observable through `Observe`, which is the root of it.

The graded interface has no guard on `approvedBy`. `v10` shows the field can be
rewritten with no consequence at all on the reference, and `v11` shows what that buys an
adversary once a real break is present. An oracle that reads the state variables catches
`v11` at rc=12. An invariant written over `Observe` cannot, because `Observe` is what
was broken. If `Observe` is the grading interface, then something in the pipeline has to
check `Observe` against the variables rather than through them, and I don't think the
reference is the right place for that. It looks like a harness job.

My recommendation is to freeze the state machine, add the terminal-absorbing action
property before the blind agents see this, and file the `approvedBy` gap against the
harness rather than against the spec. The `v09` vacuity gap I would file and leave open,
since I have not found a fix that keeps the representation-neutrality the pipeline is
built on.
