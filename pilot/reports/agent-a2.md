# Agent A2: repair of `PermitReview.tla`

Bead `tla-kl5.11` step 2, repair pass. Agent B found the state machine sound and the
property set too weak. This pass adds the one action property B specified and measures
what it closes.

Toolchain: `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, checked first, and
`pcal.trans` as bundled with it.

`$P` below is
`/tmp/claude-1000/-home-frank-repos-tla-puzzles/393a48ff-fda1-4d78-b40b-c03dd22af5ef/scratchpad/pilot`
and `$H` is `/home/frank/repos/tla-puzzles/harness`. Every run went through
`verdict.sh`, and every verdict in this report is a raw exit code. Prose from TLC gets
read for state counts and for the name of the violated check, never for a verdict.

## 1. The change

One property, named `OutcomeIsAbsorbing`, added to `reference/PermitReview.tla` after
`WithdrawalIsFinal`. It generalizes those two, so it sits with them.

```
OutcomeIsAbsorbing ==
    [][ (Observe.issued \/ Observe.withdrawn) => (Observe' = Observe) ]_vars
```

The body is B's text, unaltered. The name is mine. I kept it bare of comments to match
the other six definitions in that block, none of which carry one.

Diff to `reference/PermitReview.tla`, after line 134:

```
 WithdrawalIsFinal ==
     [](Observe.withdrawn => []Observe.withdrawn)

+OutcomeIsAbsorbing ==
+    [][ (Observe.issued \/ Observe.withdrawn) => (Observe' = Observe) ]_vars
+
 =============================================================================
```

Diff to `reference/PermitReview.cfg`:

```
 PROPERTIES
     AmendmentClearsApprovals
     IssuanceIsFinal
     WithdrawalIsFinal
+    OutcomeIsAbsorbing
```

Nothing else changed. The algorithm, `Observe`, the four invariants, the three existing
properties and the variants are all untouched.

## 2. The TRANSLATION block did not move

Both edits land after `\* END TRANSLATION`, so pcal should be a fixed point. It is.

I ran pcal on a copy rather than in place, to keep a `.old` backup out of `reference/`.

```
cp reference/PermitReview.tla verify/pcalcheck-repair/
cd verify/pcalcheck-repair && pcal PermitReview.tla
```

| measurement | before pcal | after pcal |
|---|---|---|
| TRANSLATION block md5 | `47ba2b5f2fb3c90e88e3fa1c9f138b7d` | `47ba2b5f2fb3c90e88e3fa1c9f138b7d` |
| whole-file md5 | `481ce06d3c5175c1ce3f7a91dabe15bc` | `481ce06d3c5175c1ce3f7a91dabe15bc` |

pcal exited 0 and reported "Translation completed". The whole file matched, so pcal left
the new property alone too.

That pins the block against itself. To pin it against the pre-repair reference I used
agent B's leftover `verify/pcalcheck/PermitReview.old`, which is the unmodified reference
at 3784 bytes, written 13:10, before this pass started. Its block hashes to
`47ba2b5f2fb3c90e88e3fa1c9f138b7d`, the same value. So step 8 has nothing to catch here.

## 3. The reference run

```
bash $H/verdict.sh -c $P/reference/PermitReview.cfg -t 120 \
     --scratch $P/verify/scratch-repair/reference \
     --log $P/verify/logs/repair/00-reference.log \
     $P/reference/PermitReview.tla
```

Token `OK`, rc=0.

| measurement | agent B | this pass |
|---|---|---|
| states generated | 842 | 842 |
| distinct states | 220 | 220 |
| diameter | 8 | 8 |

The two logs agree line for line on the whole progress header, timestamps aside, down to
"Checking 2 branches of temporal properties" and the 440 figure beside it. The count of
temporal branches staying at 2 is what I'd expect. `[][A]_vars` gets folded into the
action pass rather than becoming a branch, which is the same reason
`AmendmentClearsApprovals` never made it 3.

The coverage block still shows four action rows, all non-zero, matching B's numbers
exactly: `Init` 1:1, `Reviewer` 104:648, `Applicant` 111:189, `City` 4:4. So the check-4
dead-action predicate still passes.

I re-ran the other two gate checks that a new property could plausibly disturb. `-inv
FALSE` gives rc=12, so reachable states still exist. `Gate!NonVacuous` as a postcondition
gives token `OK`, rc=0. `$H/vacuity.sh` gives token `NON_VACUOUS`, rc=0.

### The property is not vacuous on the reference

A property whose antecedent is never reachable passes everywhere and buys nothing, so
this is worth a measurement rather than an argument. I dumped the reference's reachable
states with `-dump`:

```
bash $H/verdict.sh -q -c $P/reference/PermitReview.cfg -t 120 \
     $P/reference/PermitReview.tla -- -dump $P/verify/logs/repair/reference-states.dump
```

The dump carries 440 records, which is each of the 220 distinct states twice. Counting
records: 8 issued, 216 withdrawn, 216 open, so 4 and 108 and 108 as distinct states. The
antecedent `Observe.issued \/ Observe.withdrawn` holds on 112 of 220. There's plenty for
the property to bite on.

## 4. The variants

### How they were run, and why a run copy was needed

The variants were authored against the pre-repair reference, so none of them defines
`OutcomeIsAbsorbing`. Run one against the repaired `.cfg` as-is and TLC exits 151
`CONFIG_ERROR`, which is a verdict about a missing definition rather than about the
seeded bug.

I was told not to change the variants and I haven't. Instead `verify/repair-splice.sh`
builds a run copy of each under `verify/repair-runs/`, made of the variant's text up to
`\* END TRANSLATION` plus the repaired reference's tail from that line on.

The splice is safe because every variant's tail is already byte-identical to the
reference's. All eleven hash to `0ab6ad385856f38fdf7463c78d5c5103`. The script doesn't
rely on that holding, though. It diffs each run copy against its source and fails unless
the only change is an addition. All eleven came back `added_lines=3 removed_lines=0`, and
the three lines are the property and a blank. Here's v07:

```
$ diff verify/variants/v07-review-after-withdrawal/PermitReview.tla \
       verify/repair-runs/v07-review-after-withdrawal/PermitReview.tla
135a136,138
> OutcomeIsAbsorbing ==
>     [][ (Observe.issued \/ Observe.withdrawn) => (Observe' = Observe) ]_vars
>
```

Files under `verify/variants/` still carry their original mtimes, 13:11 for v01 to v10
and 13:16 for v11.

### Results

```
bash $H/verdict.sh -c $P/reference/PermitReview.cfg -t 120 \
     --scratch $P/verify/scratch-repair/<name> \
     --log $P/verify/logs/repair/<name>.log \
     $P/verify/repair-runs/<name>/PermitReview.tla
```

Full sweep in `verify/repair-sweep.sh`. Attribution is the `Error:` line at log line 29,
which names the check TLC stopped on.

| variant | rc | token | caught | caught by |
|---|---|---|---|---|
| `v01-issue-without-unanimity` | 12 | `SAFETY_VIOLATION` | yes | `IssuedOnlyWhenUnanimous` |
| `v02-amend-keeps-positions` | 13 | `LIVENESS_VIOLATION` | yes | `AmendmentClearsApprovals` |
| `v03-review-after-issuance` | 13 | `LIVENESS_VIOLATION` | yes | `OutcomeIsAbsorbing` |
| `v04-withdraw-after-issuance` | 13 | `LIVENESS_VIOLATION` | yes | `OutcomeIsAbsorbing` |
| `v05-issue-after-withdrawal` | 13 | `LIVENESS_VIOLATION` | yes | `OutcomeIsAbsorbing` |
| `v06-unbounded-amendments` | 12 | `SAFETY_VIOLATION` | yes | `TypeOK` |
| `v07-review-after-withdrawal` | 13 | `LIVENESS_VIOLATION` | yes | `OutcomeIsAbsorbing` |
| `v08-amend-after-withdrawal` | 13 | `LIVENESS_VIOLATION` | yes | `OutcomeIsAbsorbing` |
| `v09-amend-uncounted` | 0 | `OK` | no | nothing |
| `v10-observe-fakes-unanimity` | 0 | `OK` | no | nothing |
| `v11-masked-issue-without-unanimity` | 0 | `OK` | no | nothing |

Eight of eleven caught, against six before. v07 and v08 were the two real slips and both
are closed. The three that remain are the three the brief predicted, for the three
structural reasons it gave, and none of them is a surprise.

The three uncaught runs all explored a complete state space rather than timing out. v09
found 55 distinct at diameter 5, v10 found 220 at diameter 8, v11 found 292 at diameter
8. Those are B's numbers to the digit.

## 5. Where this contradicts what I was told

**v03, v04 and v05 changed exit code, and I don't think it's a regression.** B's table
records all three at rc=12. They now report 13. The cause is that TLC stops at the first
violation it hits, and the new action property gets there first.

Coverage didn't drop. I re-ran each against the single-check `.cfg` B left in
`verify/cfgs/` and the original attribution still fires:

```
v03 + IssuedOnlyWhenUnanimous.cfg -> rc=12
v04 + IssuanceIsFinal.cfg         -> rc=12
v05 + WithdrawalIsFinal.cfg       -> rc=12
```

So those three are now caught twice and reported once. It's worth flagging because
anything downstream that pins the expected rc per variant needs three rows updated, and
because `seeded-bugs.sh` requires rc==12 exactly. Three variants that used to satisfy
that no longer do.

**The brief's phrasing on what the property closes needs a small correction.** It says
the property closes v03, v04, v05, v07 and v08 "at once", and B's section 5 says the
same. Measured, it fires on all five, which is true. But only v07 and v08 were open. The
other three were already caught, so the property adds a second catcher there rather than
a first. The count of caught variants goes 6 to 8, not 6 to 11.

**Nothing else contradicted the brief.** rc=13 on the new property behaved as `tla-94n`
predicts. I did not drive `seeded-bugs.sh` for this property, per `tla-59s`. v09, v10 and
v11 stayed at rc=0, so no surprise catch to report.

## 6. One thing I did not do

`reference/alternatives.md` documents the property set and now under-describes it, since
it predates `OutcomeIsAbsorbing`. Section 1's claim about what `OutcomeExclusive` guards
is also the thing B corrected. Both look worth a paragraph, and both sit outside a brief
that says one property and nothing else, so I've left them. Flagging rather than fixing.

## 7. Files

Written this pass, all under `$P`:

- `reference/PermitReview.tla`, `reference/PermitReview.cfg`: the repair
- `verify/repair-splice.sh`, `verify/repair-sweep.sh`: the two scripts
- `verify/repair-runs/`: eleven spliced run copies
- `verify/pcalcheck-repair/`: the pcal fixed-point check
- `verify/logs/repair/`: all logs, including the state dump
- `verify/scratch-repair/`: TLC metadirs
- `reports/agent-a2.md`: this file

Nothing was written into `/home/frank/repos/tla-puzzles`, and no `bd` command ran.
