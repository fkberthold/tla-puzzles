# Agent F: commentary pass on `PermitReview.tla`

Bead `tla-kl5.11` step 7. The frozen spec, with comments added and nothing else changed.

`$P` below is
`/tmp/claude-1000/-home-frank-repos-tla-puzzles/393a48ff-fda1-4d78-b40b-c03dd22af5ef/scratchpad/pilot`
and `$H` is `/home/frank/repos/tla-puzzles/harness`.

Toolchain, checked before anything else. `pcal 2>&1 | head -5` gives
`pcal.trans Version 1.12 of 01 July 2024`. `tlc 2>&1 | head -5` gives
`TLC2 Version 2026.07.31.184830 (rev: 30cc360)`. Both are what the brief pins.

## Deliverables

- `$P/commented/PermitReview.tla`, md5 `c5e50ed7afab7c312d9cc805673cc419`
- `$P/commented/PermitReview.cfg`, md5 `a3c92eb63f1f92c168347bee0be153b6`

The `.cfg` is a byte copy of the frozen one. Same md5 on both sides of
`md5sum frozen/PermitReview.cfg commented/PermitReview.cfg`.

The frozen pair is untouched. `cd frozen && sha256sum -c FREEZE.sha256` gives
`PermitReview.tla: OK` and `PermitReview.cfg: OK`.

Evidence directories, both under `$P/commented/`: `.pcalcheck/` holds the pcal
fixed-point run and its log, `.run/` holds the TLC logs and metadirs.

## 1. The non-comment diff is empty

I made the check stronger than "strip comments and diff", because every line I added
starts with `\*`. That turns the gate into three mechanical questions.

**Does the frozen file come back out of the common lines?**

```
diff --old-line-format='' --new-line-format='' --unchanged-line-format='%L' \
     frozen/PermitReview.tla commented/PermitReview.tla | md5sum
481ce06d3c5175c1ce3f7a91dabe15bc
```

That's the frozen `.tla`'s own md5, from `md5sum frozen/PermitReview.tla`. So every
frozen line is present, in order, unmodified.

**Are there any deletions or modifications?**

```
diff frozen/PermitReview.tla commented/PermitReview.tla | grep '^<'
(no output)
```

**Is every added line a comment line?**

```
diff frozen/PermitReview.tla commented/PermitReview.tla | grep '^>' | grep -cv '^> *\\\*'
0
diff frozen/PermitReview.tla commented/PermitReview.tla | grep -c '^>'
372
```

372 comment lines added, 0 non-comment lines added, 0 lines removed or changed.

The gate caught two real defects on the way, which is the only reason I trust it.

The first was the trailing space on `\* END TRANSLATION `. I typed the line without it,
`grep '^<'` printed the line, and I put the space back. Nothing else would have found
that, and pcal wouldn't have either, since the trailing space sits outside the block it
regenerates.

The second was six blank lines. My first pass separated a comment block from the
definition under it with a blank line, so `grep -cv` returned 6 and `cat -A` showed six
bare `$`. A blank line adds no non-comment character, so I think it would have passed a
strip-and-diff gate. I converted all six to `\*` anyway, since "every added line is a
comment line" is a check with no judgment in it.

## 2. The TRANSLATION block did not move

pcal ran on a copy under `$P/commented/.pcalcheck/`, so the deliverable never had a
`.old` written beside it.

```
cd $P/commented/.pcalcheck && pcal PermitReview.tla
```

pcal exited 0 and reported "Translation completed".

| measurement | value |
|---|---|
| TRANSLATION md5, commented file, before pcal | `47ba2b5f2fb3c90e88e3fa1c9f138b7d` |
| TRANSLATION md5, commented file, after pcal | `47ba2b5f2fb3c90e88e3fa1c9f138b7d` |
| expected, from the brief | `47ba2b5f2fb3c90e88e3fa1c9f138b7d` |
| whole-file md5, before and after pcal | `c5e50ed7afab7c312d9cc805673cc419` |

Extraction is `sed -n '/BEGIN TRANSLATION/,/END TRANSLATION/p' | md5sum`, inclusive of
both marker lines. I recovered that form by trying three candidates against the frozen
file. The inclusive one reproduces agent A2's value and the two exclusive ones give
`b0fec8396a0ba9439bc215d48b12091a` and `222736d0794b4254c840edcb14ce7ddd`. Worth
recording, since the marker line carries the checksums and a gate that drops it is a
weaker gate.

The whole file is a pcal fixed point, so pcal left my comments alone as well.

**One thing I checked before writing a single comment**, because the whole pass turns on
it. The `BEGIN TRANSLATION` line carries `chksum(pcal)`, which is a checksum of the
algorithm text, so a comment inside the algorithm could in principle move it. It
doesn't. I put a `\*` comment and a `(* *)` comment inside the algorithm of a throwaway
copy at `scratchpad/pcaltest/`, ran pcal, and got
`47ba2b5f2fb3c90e88e3fa1c9f138b7d` back. pcal normalizes comments out of that checksum.
Both comment styles also survived the run intact, at lines 15 and 22 of the probe file.

## 3. TLC

```
bash $H/verdict.sh -c $P/commented/PermitReview.cfg -t 180 \
     --scratch $P/commented/.run/scratch \
     --log $P/commented/.run/commented.log \
     $P/commented/PermitReview.tla
```

Token `OK`, rc=0.

| measurement | commented | frozen control | agent A2 |
|---|---|---|---|
| states generated | 842 | 842 | 842 |
| distinct states | 220 | 220 | 220 |
| diameter | 8 | 8 | 8 |

The frozen control is the same command against `$P/frozen/PermitReview.tla` with the
frozen `.cfg`, run in this session rather than quoted from a report. Log at
`$P/commented/.run/frozen-control.log`, token `OK`, rc=0.

Coverage rows match A2 to the digit: `Init` 1:1, `Reviewer` 104:648, `Applicant`
111:189, `City` 4:4. Temporal branches still 2, over 440 total distinct states.

The brief's warning about `--config` is real and I hit nothing, because I passed
absolute paths for both the module and the config from the start.

## 4. What I commented on

Grouped by where the comment sits.

**Module header**

- What the spec models, and that these comments are about modeling and not TLA+.
- That most of the property block is true by construction, so it can't be falsified by
  mutating this spec, and that it earns its keep against a competing spec instead.

**The two alphabets**

- Why `status` is one three-valued variable and not the two booleans `Observe` exposes.
- That the rejected two-boolean shape admits a state the process has no meaning for.
- That this is the clearest demonstration `Observe` is representation-neutral.
- Why `Positions` keeps three values when nothing reads "changes" against "none".

**The assumptions**

- Why non-emptiness is load-bearing: with no departments the unanimity rule has no content.
- That the disjointness conjunct is a PlusCal string-identifier artifact, not a process rule.
- Why model values plus SYMMETRY were rejected, and that temporal properties are the reason.

**State and the freshness decision**

- Why an amendment clears every position instead of version-stamping them.
- The three reasons version stamps lose: wrong sentence, phantom states, state-space cost.
- Why the auxiliary-variable hybrid fails too.
- The price of clearing: the freshness half of `IssuedOnlyWhenUnanimous` becomes true by
  construction rather than checked.
- Why position flips need no bound, with the 220 and 815 measurements.

**The observation interface**

- What `Observe` is for, and why answers are written over it rather than the variables.
- That it exposes no amendment count, with a forward pointer to what that costs.
- Why `Unanimous` is set equality rather than a cardinality test.

**Process structure and atomicity**

- Why three process groups instead of one process with a big `either`.
- That single-label bodies make the translator drop `pc`, which is what lets the action
  properties be subscripted `_vars` and mean what they say.
- Why `while (Pending)` was rejected, and why `CHECK_DEADLOCK FALSE` is the cheaper answer.
- Reviewer atomicity: the `await` and the assignment are one step.
- That a reviewer may re-record the position it holds, which is a stutter and harmless.
- That a reviewer can't reach "none", since only an amendment produces it.
- Applicant atomicity: the increment and the clearing land in the same step, and what
  an interleaved reviewer or an eager city could do if they didn't.
- Why the amendment bound is a guard in the action and not a `CONSTRAINT` in the config.
- City atomicity: unanimity can't lapse between the test and the assignment.
- Why unanimity doesn't force issuance, and that no fairness is declared anywhere.
- That authorization is the process partition rather than a guard.

**The property block, one entry each**

- `TypeOK`: not a process rule, and the conjunct with teeth is the one on `amendments`.
- `ObserveWellTyped`: guards the interface's shape, not the process.
- `IssuedOnlyWhenUnanimous`: what it captures, and that it deliberately doesn't capture
  freshness. Also that against a spec allowing post-issuance moves it says something
  stronger than the rule, and fires for the wrong reason.
- `OutcomeExclusive`: not falsifiable by any state-machine mutation, retained as a check
  on `Observe`, and guarding only two of the three fields.
- The `approvedBy` hole, and why no property over this spec can close it.
- `AmendmentClearsApprovals`: the long one. See below.
- `IssuanceIsFinal` and `WithdrawalIsFinal`: they pin the flags and not the world.
- `OutcomeIsAbsorbing`: the full form of the rule, why the two above are kept anyway,
  and that it too is true by construction here.

**The amendment rule, which is the entry the brief asked for**

- That it's the only formal witness the rule has, and the one check reaching past
  `Observe` into a raw variable.
- That deleting the clearing assignment leaves the reachable state set equal, as sets of
  whole records, so no state predicate whatever separates the two.
- The direction argument: the weakened spec loses a transition, not a state. Its amend
  step is an `Observe`-stutter, so failing to clear makes a spec observably smaller than
  a correct one, and an invariant can only rule states out.
- That the check therefore has to be an action property, and that an action property
  about amendments has to read `amendments`.
- What that costs: it doesn't survive a change of representation, and it goes vacuous
  against a spec that clears but never increments.
- The exit-code consequence for tooling, 13 against 12.
- The one `Observe`-only separator that exists, recorded so nobody mistakes it for the
  missing invariant.

**Elisions, and why each is safe**

Time and deadlines, application content and version payload, reasons behind a "changes"
position, messages and delay, a second application, fairness and liveness, department
identity beyond a name, authorization guards, un-withdrawal and re-opening and appeal
and expiry. Plus the one thing that looks elidable and isn't: the amendment bound is a
rule the city runs, so it lives in the action.

The block closes on the two things the module knowingly doesn't check, both of which I
think belong against the pipeline rather than the module.

## 5. Where the source material is wrong

Beyond the two staleness items the brief already named.

**The rule numbering in `alternatives.md` is stale, and my brief inherited it.**
`alternatives.md:51` says "Rule 3 says an amendment *clears* every recorded position."
In the shipped statement, rule 3 is unanimity (`statement/PROBLEM.md:45-48`) and the
amendment reset is rule 5 (`statement/PROBLEM.md:60-70`). The answer key uses the
shipped numbering at `answer/ANSWER-KEY.md:27` and `:77`. My brief repeated
`alternatives.md`'s number twice. Nothing propagated into the commented file, since I
refer to rules by content and never by number.

**pcal rewrites the `.cfg` as a side effect, and no report mentions it.** Running
`pcal PermitReview.tla` prepends `\* Add statements after this line.` to
`PermitReview.cfg`. It happens on the frozen pair too, so it isn't caused by my
comments. Measured at `scratchpad/frozencfgcheck/`: a copy of the frozen pair, pcal run
in place, and `diff frozen/PermitReview.cfg PermitReview.cfg` gives `0a1 >
\* Add statements after this line.`. The frozen `.tla` is a pcal fixed point in the same
run at md5 `481ce06d3c5175c1ce3f7a91dabe15bc`.

The practical bite is for step 8 or anyone else re-running the §5.6 gate. A2's report
(`reports/agent-a2.md:60-72`) checks the `.tla` before and after and doesn't check the
`.cfg`, so a gate that runs pcal in place on `frozen/` will dirty a file the freeze
covers. Running pcal in a scratch copy avoids it, which is what A2 did for the `.tla`
and what I did here.

**A nuance `alternatives.md` section 2 doesn't draw, and I put in the comments.** The
note frames `IssuedOnlyWhenUnanimous` as unable to catch the non-clearing mutation,
which is right. What it doesn't say is that the invariant also fires for the wrong
reason on a different mutation. Against a spec letting reviewers move after issuance it
reads as "positions have to stay unanimous forever", which is not rule 3. It caught
that variant at rc=12 in agent B's table (`reports/agent-b.md:127`), and after the
repair `OutcomeIsAbsorbing` gets there first at rc=13
(`reports/agent-a2.md:172`), with the original attribution still firing in a
single-check run (`reports/agent-a2.md:200`). I read that as the invariant getting a
catch it isn't entitled to, and I said so in the comment.

**Two claims I re-measured rather than transcribed, both of which hold.**

`alternatives.md:113-115` says 815 distinct at 4 departments and `MaxAmendments = 4`,
"under one second". B confirmed the 815 and recorded no timing
(`reports/agent-b.md:96-97`). Run here with `verify/claims/Four.cfg`: 3,975 generated,
815 distinct, diameter 10, `Finished in 00s`, token `OK`, rc=0. Log at
`$P/commented/.run/four.log`. So the timing claim holds too, and my comment repeats it.

`reports/agent-a2.md:74` calls `verify/pcalcheck/PermitReview.old` "the unmodified
reference at 3784 bytes". `stat -c '%s'` gives 3784 for that file and 3884 for the
frozen `.tla`, and the 100-byte gap is the three lines `OutcomeIsAbsorbing` added. The
claim checks out.

**One thing I could not corroborate.** The brief says three blind critics independently
proved the amendment rule has no invariant form, by refinement check, projected
state-graph diff, and stuttering simulation. `$P/solves/` is empty (`ls solves/` returns
nothing), and I found no critic artifacts under `$P`. So I have no local citation for
the three-method claim. What I do have is `answer/ANSWER-KEY.md:101-107`, which shows
the two reachable state sets equal as sets of whole records, 220 against 220 with an
empty difference in both directions. That's the evidence the comment rests on. INFERRED,
for the three-critic provenance itself.

**Not a source-material error, but worth flagging.** `git status --porcelain` in
`/home/frank/repos/tla-puzzles` shows `M .beads/issues.jsonl`, and `git log --oneline -1`
shows `3c9683b bd: absorb re-export` where my session started at `83a10a4`. I ran no `bd`
command and wrote nothing into that repo, so another actor is committing there while
this pilot runs. Flagging rather than touching it.

## 6. Style note

The comments went through the `frank-writing` skill, since the project's global
instructions class code comments as prose. Self-lint on the finished file: 0 em dashes,
0 semicolons on comment lines, 0 banned-vocabulary hits, and one sentence over 25 words
at 30, which is a coordinated list the skill allows. The single line over 79 columns is
frozen line 119, `ObserveWellTyped`'s body at 85 characters, and not mine.
