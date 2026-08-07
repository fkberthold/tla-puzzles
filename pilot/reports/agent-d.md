# Agent D: adversarial leakage pass on the `PermitReview` critique statement

Bead `tla-kl5.11` step 5, V2-PLAN.md §9.7. I did not rewrite anything. Nothing was written
into `/home/frank/repos/tla-puzzles`, nothing under `statement/` or `frozen/` was modified,
and no `bd` command ran.

Toolchain checked first: `tlc` reports `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`, the
pinned build.

`$P` is
`/tmp/claude-1000/-home-frank-repos-tla-puzzles/393a48ff-fda1-4d78-b40b-c03dd22af5ef/scratchpad/pilot`.
Every load-bearing claim below carries a command and its result, a `file:line`, or `INFERRED`.

---

## 0. Before anything else: the delivery boundary is not enforced

`ANSWER-KEY.md` line 3 says **"Never show this to a critic."** It sits in the directory a
critic reads.

```
$ ls -a $P/statement/
.  ..  ANSWER-KEY.md  PermitReview.cfg  PermitReview.tla  PROBLEM.md  screens.md  .verify
```

`.verify` is hidden. `ANSWER-KEY.md` and `screens.md` are not. A step-6 brief that says
"read `$P/statement/`" hands three blind critics the seeded gaps, the expected conjuncts,
the degenerate-answer family, and the two-sided measurements. `screens.md` alone names the
domain as atomic commitment and lists both gaps by rule number
(`statement/screens.md:29-30`).

This is not a wording defect and step 4 cannot fix it. It is the largest leakage risk in
the delivery and it is fixed by naming three files rather than a directory, or by moving
the two documents up a level. **Do this before step 6 dispatches.**

---

## 1. Representation leakage

§9.7 asks which sentences name or imply a variable, data structure, decomposition, or
atomicity boundary present in the reference. Applied literally to a column-C problem the
section comes out nearly empty, and the reason is worth stating because it generalizes.

**A critique statement cannot leak what the deficient spec already shows.** The learner is
handed `position`, `amendments`, `status`, `Positions`, `Statuses`, three process families,
single-label atomicity, `Observe`, and six named checks. The complete set of facts about the
frozen reference that `PROBLEM.md` could leak is therefore bounded by the diff:

```
$ diff frozen/PermitReview.tla statement/PermitReview.tla
23d22   <        Unanimous  == ApprovedBy = Departments
49d47   <              position   := [d \in Departments |-> "none"];
61c59   <            await Pending /\ Unanimous;   ->   await Pending /\ ApprovedBy # {}
...
121,123d117  < IssuedOnlyWhenUnanimous == Observe.issued => (Observe.approvedBy = Departments)
126,128d119  < AmendmentClearsApprovals == [][ (amendments' # amendments) => (Observe'.approvedBy = {}) ]_vars
```

Five edits, and they are the two gaps. **So representation leakage and gap leakage are the
same surface for this problem**, and everything real is in §2. Three findings survive here
in their own right:

| # | Sentence | Reference element leaked | Severity |
|---|---|---|---|
| R1 | L45 / L52 / L58 — "unanimity", three times | the deleted `Unanimous` operator (`frozen:23,73`). The word occurs **0 times** in `statement/PermitReview.tla` and **0 times** in `statement/PermitReview.cfg` (`grep -c -i unanim`), and **5 times** in `frozen/PermitReview.tla`. | High — see G3 |
| R2 | L47-48 — "The city can issue only while the application is open, and only when every department is holding an approval at that moment." | the reference's city guard `Pending /\ Unanimous` (`frozen:61,102`), conjunct for conjunct, with "at that moment" carrying the unlatched pre-state reading. | Unavoidable — this *is* rule 3 |
| R3 | L64 — "so right after an amendment no department holds an approval" | `AmendmentClearsApprovals == [][ (amendments' # amendments) => (Observe'.approvedBy = {}) ]_vars` (`frozen:127-128`), transliterated, including the primed-state framing. | Unavoidable content, avoidable shape — see G5 |

R2 and R3 are the requirements themselves. A statement that omitted them would not pose the
problem. I flag them for completeness, not as defects.

**Not leakage, contrary to what a literal §9.7 pass would say.** L21 "One application is in
front of it" (no application index in the reference — but none in the deficient spec
either); L23-30, the three parties and the interleaving model (all three processes and
`Next` are visible at `statement/PermitReview.tla:86-104`); L26 backticking `Departments`
(`CONSTANTS Departments, MaxAmendments`, `statement/PermitReview.tla:4`); L42-43 "a current
opinion, not a promise" / "holds neither" (`Positions == {"none","approved","changes"}`,
line 6, and the initial `"none"`, line 16). Every one of these would be a real finding in a
column-A problem. None is here.

---

## 2. Gap leakage, ranked

The ranking metric: the intended route is *compare each numbered rule against the
corresponding action body*. Leakage is a route **shorter than that**.

### G1 — the `.cfg`'s declared check list tiles the rule set with exactly two holes, and L8-9 points at it. **Rank 1. This is the finding.**

> L8-9: "The spec parses, it runs, and TLC reports no error against the checks its own
> `.cfg` declares."

The statement numbers its rules 1 to 7. The `.cfg` names six checks
(`statement/PermitReview.cfg:7-15`). Building the cross-table is mechanical:

| Rule | Shape | Named check |
|---|---|---|
| 1 open until outcome, at most one | constraint | `OutcomeExclusive` |
| 2 department records / changes | permission | — correctly none |
| **3 issue only under unanimity** | **constraint** | **NONE ← gap 1** |
| 4 issuing is a step of its own | anti-constraint | — none in either spec |
| **5 amendment resets the review** | **constraint** | **NONE ← gap 2** |
| 6 applicant can withdraw | permission | — |
| 7 outcome is the end | constraint | `IssuanceIsFinal`, `WithdrawalIsFinal`, `OutcomeIsAbsorbing` |

Four constraint-shaped rules. Two carry checks. Two do not, and those two **are** the seeded
gaps. Confirmed against the reference:

```
$ diff frozen/PermitReview.cfg statement/PermitReview.cfg
10d9   <     IssuedOnlyWhenUnanimous
14d12   <     AmendmentClearsApprovals
```

**This route finds both gaps without reading a single action body.** The critic never has to
look at `City ==` or `Applicant ==`. Rule 4 is the only false positive the table produces,
and it clears in one glance (no fairness anywhere, the guard is an `await`).

The prose contribution is L8-9, which names *"the checks its own `.cfg` declares"* as an
object worth attention. A neutral phrasing — "the spec parses and runs clean" — would say
the same true, time-saving thing without nominating the check list. I verified the claim
itself is true, so the sentence is honest, and its benefit is real:

```
$ bash harness/verdict.sh -c $P/statement/PermitReview.cfg $P/statement/PermitReview.tla
OK
rc=0
```

**But note what this means for the remedy.** The route lives in the `.cfg`, not in
`PROBLEM.md`. Delete L8-9 entirely and a critic still opens the `.cfg` and still builds the
table. **Sending the statement back to step 4 cannot close G1.** That fact drives my overall
verdict in §6.

### G2 — `approvedBy` is the only `Observe` field with no behavioural check, and both answer-form instructions aim at it. **Rank 2.**

> L95: "Write your answers over `Observe` and over `Departments`."
> L99: "Write conjuncts that hold for any `Departments` and any amendment bound."

`Observe` has three fields. Across all six retained check definitions, `approvedBy` appears
exactly once, and only as a type:

```
$ sed -n '110,129p' statement/PermitReview.tla | grep -n "approvedBy"
7:    Observe \in [issued: BOOLEAN, withdrawn: BOOLEAN, approvedBy: SUBSET Departments]
```

`OutcomeExclusive` relates `issued` to `withdrawn`. The three temporal properties pin
`issued` and `withdrawn`. Nothing constrains `approvedBy` behaviourally. So the derivation
runs:

1. L95 licenses `Departments` in an answer — so the answer names it.
2. L99 demands generality over `Departments` — so it is a statement about the whole set, not
   a member.
3. `approvedBy` is the unconstrained field, and it is the only field typed against
   `Departments`.
4. `issued` is the only other field carrying a rule.

→ `Observe.issued => Observe.approvedBy = Departments`, which is `IssuedOnlyWhenUnanimous`
verbatim (`frozen:121-122`).

**Derived from the instructions and the check list alone, with no rule-reading and no
action-reading.** Ranked below G1 only because G1 also delivers gap 2.

### G3 — "unanimity" is the statement's most-repeated technical noun and is absent from the artifact. **Rank 3.**

Three occurrences (L45, L52, L58); zero in the `.tla` and zero in the `.cfg`. One grep, or
one attentive read, closes gap 1. I rank this third rather than first because it is a
*faster version of the intended route* rather than a bypass of it — the critic is still
comparing rule 3 to the spec. It compounds badly with the burned mechanism (§5).

Asymmetry worth recording: the same test does **not** fire for gap 2. "amend"/"amendment"
appears 7 times in `PROBLEM.md` and `amendments`/`MaxAmendments` are present in the spec, so
a vocabulary-absence sweep finds gap 1 and misses gap 2. This is part of why the two gaps
are not comparably hard.

### G4 — the statement supplies half of the inexpressibility argument. **Rank 4.**

> L96-97: "Don't reach for the spec's own variables. The point of the operator is that it
> survives a change of representation, and an answer that reads the variables underneath
> doesn't."

The author calls the inexpressibility argument "the most interesting thing in the problem"
(`statement/screens.md:45-48`), and I agree. But L96-97 hands the critic the constraint,
states it emphatically, and explains *why* it holds. The critic no longer has to discover
that `Observe` is a representation-independence boundary; they only have to notice that rule
5 needs `amendments` and `amendments` is not in `Observe`. That is one step of application,
not an insight.

Unavoidable — without L96-97 the answer form is undefined. But central should not read a
critic's inexpressibility note as evidence of deep modeling judgment. The statement did the
hard half.

### G5 — L64's phrasing is formula-shaped. **Rank 5.**

"…so right after an amendment no department holds an approval" maps token for token onto
`(amendments' # amendments) => (Observe'.approvedBy = {})`. "Right after" is the primed
state. The *content* is mandatory; the *shape* is not. "An amendment starts the review over"
carries the same requirement with less of the formula's silhouette.

### G6 — rule 5's second paragraph pre-clears itself, spotlighting the first. **Rank 6.**

> L67-69: "The applicant can amend at most a fixed number of times… The bound is part of the
> process the city runs. It isn't a device for keeping the model finite."

36 of rule 5's 85 words are spent telling the critic that this part of rule 5 is fine. By
elimination, the live part of rule 5 is the 49-word first paragraph — which is gap 2. A
pre-clearing note adjacent to a gap advertises that its neighbourhood is subtle. Rule 4 does
the same thing at larger scale (§4, item 2).

### G7 — the Notes section. **Rank 7 for discovery, rank 1 for measurement distortion.** See §4 item 1.

### G8 — offsetting, biases gap-2 reporting DOWN.

> L9: "**The gap** between what the process requires and what the spec says is the whole
> exercise."
> L104: "For each thing the spec fails to say…"

L9 uses the singular. A critic who reads it as a count stops after gap 1 and never opens
Notes. L104 corrects it 95 lines later. This is the one place the statement makes the
measurement *worse in the conservative direction*, and it partially cancels the Notes
inflation — which means the two errors do not cancel cleanly and central cannot net them
out. One-word fix ("The distance between…"), no step-4 round trip needed.

---

## 3. My PUZZLE-SCREEN, and the diff against the author's

Worked Q1–Q8 in order and recorded before opening `statement/screens.md`; the record is at
`$P/.agentd/my-screen.md`.

| # | My answer | Basis |
|---|---|---|
| 1 | **System** — the requirement-as-formula is what is left to model | Q1's system column ("the actions themselves") is unavailable to column C, so I answered the substance |
| 2 | **Puzzle (given)** — and aggravated | forced by column C (`tla-g2ap`); see below |
| 3 | **System** — "is this design correct" | L14-15, L17, verbatim |
| 4 | **System** — learner models, TLC checks | L117-124; L8-10 removes TLC as a discovery tool outright |
| 5 | **System** — abstraction choice | 292 states, `ANSWER-KEY.md:24`; search is free |
| 6 | **System** — several, fallible | `|Departments|+2` agents, arbitrary interleaving (L29-30), stall (rule 4), regress (rule 2), abort (rule 6), reset (rule 5) |
| 7 | **System** — strongest row | the degenerate-answer disqualification is human-graded by construction (`ANSWER-KEY.md:70-73`) |
| 8 | **System (no)** | `grep -iE "optimal\|optimum\|minim\|maxim\|fewest\|best\|shortest\|largest\|smallest"` on `PROBLEM.md` → no matches |

**My verdict: ACCEPT — system.** Seven of eight read system; the single puzzle row is Q2 and
it is structurally forced.

### Where I differ from the author

We reach the same verdict and the same per-row answers. Three differences of substance:

**D1 — Q2 is worse than "structural", and the author's framing lets the statement off.**
`statement/screens.md:34-36` says a critique problem hands over an action set by
construction and "I don't think that's a defect in my wording." Half right. Column C forces
*an* action set to be handed over — in the spec. It does not force `PROBLEM.md` to hand it
over **again, independently, in prose**. L23-30 plus rules 1 to 7 enumerate every action —
record approval, record changes, issue, amend, withdraw — in domain terms. **Delete the
attached spec and `PROBLEM.md` alone is still a complete action set.** For a critique
problem this is necessary, since you cannot critique against a process you have not stated.
But the honest reading of Q2 here is *doubly* given, not *structurally* given, and the
author's phrasing loses that. It does not change the verdict.

**D2 — Q5's basis is right and its implication is unflattering.** We both answer
"abstraction choice." I record what neither the author nor the rubric asks: given G1 and G2,
gap 1's difficulty may be near zero. The screen has no triviality row, so this passes
cleanly while being partly trivial. **Passing §5.7b is not evidence the problem is hard.**
Central should not let the ACCEPT stand in for that.

**D3 — Q1 shares Q2's rubric defect, and only Q2 is filed.** Q1's system column reads "the
actions themselves." That answer is as unavailable to column C as Q2's "decided", and for
the same reason. Both of us answered Q1 on substance rather than on the column, which is
right, but `tla-g2ap` as described covers only Q2. **Recommend widening `tla-g2ap` to Q1 and
Q2**: the rubric's Q1/Q2 answer columns are action-centric and column C needs a
requirement-centric pair.

Agreements worth recording because they were reached independently: Q7 is the strongest row
on the card, for the same reason (the human-graded disqualification); rule 4 is load-bearing
for Q6; and the tally rule (three puzzle rows) is nowhere near firing.

---

## 4. The six self-flagged items

The author was candid. On four of six the candour is well-aimed; on two the stated facts are
wrong.

### 1. The `Notes` section — **AGREE it is the sharpest item, but the distortion runs the other way from the author's framing.**

The author frames Notes as possibly *inflating* the apparent discovery rate versus a critic
who would otherwise have stayed silent. True, but it undersells the section. Given G1 and
G2, **gap 1 is close to over-determined, so gap-2 handling is the only thing in this problem
that separates one critic from another.** Notes is not decorating a marginal measurement; it
is the channel carrying the *primary* one.

How much it distorts, concretely:

- **Direction and size.** It converts discovery into report at close to 100%. The recorded
  gap-2 rate is therefore an upper bound on discovery, with no control arm. There is no way,
  from three critics all given Notes, to recover what the silent rate would have been.
- **The real hazard is a false positive, not inflation.** "Notes don't score. Write them
  anyway" (L111) invites laundry-listing. A critic who dumps "the amend action only touches
  the counter" among ten observations has not found gap 2 in the sense that matters; they
  have described an action body. Scoring that as a discovery is the failure mode.
- **G8 pushes the other way**, so the two biases do not net out cleanly.

**Recommendation, and it is a step-6 grading rule rather than a statement change.**
`ANSWER-KEY.md:154-159` currently specifies one thing to record — whether the critic *names*
the amendment gap. Split it:

- (a) names the amendment gap; and
- (b) argues that it cannot be written over `Observe`, because `Observe` exposes no amendment
  count.

(b) is the discriminator. (a) alone is reachable from the G1 table with no insight, and per
G4 the statement supplies half of (b) as well. Report the pair, not the union.

### 2. Rule 4's length — **DISAGREE on the facts, AGREE with a different concern, and keep it anyway.**

The stated facts are measurably wrong. Rule 4 is neither the longest rule nor three
sentences:

| Rule | words | sentences |
|---|---|---|
| 1 | 35 | 3 |
| 2 | 50 | 4 |
| **3 — gap 1 lives here** | **31** | **2** |
| 4 | 83 | 7 |
| **5 — gap 2 lives here** | **85** | **8** |
| 6 | 10 | 1 |
| 7 | 40 | 5 |

Rule 5 is longer on both metrics. Rule 4 is seven sentences, not three. And **rule 3, where
the primary gap actually lives, is the second-shortest rule in the document** — only rule 6
is shorter. On raw emphasis the statement *de-emphasizes* gap 1's rule. The author's
self-flag is aimed at the wrong rule.

One thing does survive: rule 4 is the **longest single-purpose block** in the document — 83
words in one paragraph on one topic (`sed -n '52,58p' | wc -w` → 83), where rule 5's 85 split
49/36 across two topics. So the instinct was sound even though every stated fact was not.

The real concern is not length, it is **kind**: rule 4 is a pre-clearing note — "this looks
wrong and is not" — sitting immediately beside a gap, and rule 5's second paragraph is
another (G6). Two of them, both adjacent to gaps. A pre-clearing note advertises that its
neighbourhood repays attention.

**Keep it regardless, and the reason is not the one in `screens.md`.** Rule 4 is load-bearing
for PUZZLE-SCREEN Q6, and it is the statement's principal defence against the burned 2PC
prior that votes latch (§5). Shortening it would weaken the screen verdict *and* make the
burned-mechanism pattern-match more damaging. The emphasis costs less than its absence would.

### 3. "no error against the checks its own `.cfg` declares" — **AGREE, and it is much worse than the author thought. This is the top gap-leakage finding.**

The author frames the cost as "it points at the `.cfg` as a place to look, and diffing
declared checks against the seven rules finds the primary gap fast." Three understatements:

1. It finds **both** gaps, not just the primary one.
2. It finds them **without reading any action body** — the critic never opens `City ==`.
3. It compounds with G2: the same `.cfg` shows `approvedBy` is the sole unconstrained
   `Observe` field, which fixes the answer's *shape* as well as its target.

See G1 for the table and the diff. The honest mitigation is small: the sentence's benefit
(saving wasted TLC runs) survives a phrasing that does not nominate the declaration list.
But per G1 the route survives the edit, so this is a nicety, not a fix.

### 4. "hold for any `Departments`" — **AGREE it nudges, DISAGREE that it should worry anyone.**

It buys the disqualification of the degenerate family — `Observe.issued => "fire" \in
Observe.approvedBy` passes the two-sided check at 12 and 0 (`ANSWER-KEY.md:63-73`) and is
disqualified only by this line. That is the difference between a gradable problem and an
ungradable one. The hint it costs is real and it is strictly subordinate to G1, which gives
gap 1 away more cheaply and cannot be edited out of the prose. **Keep. Do not trade a
grading defence for a hint you have already lost elsewhere.**

### 5. "position" appearing four times — **DISAGREE. Non-issue.**

The deficient spec names the variable `position` itself: `grep -c "position"
statement/PermitReview.tla` → **11**. A statement cannot leak an identifier the learner is
already reading on line 16 of the artifact in their hand. Backticking would change nothing.

This is the cleanest illustration of the §1 point: §9.7's representation-leakage frame
misfires on column C, and an author applying it faithfully will spend attention on
non-findings. Worth feeding back into the §9.7 brief.

### 6. Answer-shape vagueness — **AGREE with the decision, DISAGREE that it is neutral.**

The decision is right: saying "an invariant" would point at the ungradable gap. But the
statement is not actually silent on shape, it is silent *in words* and loud *by example*:

- The one worked candidate is `~Observe.issued` (L123) — a state predicate.
- `Observe'` appears **nowhere** in `PROBLEM.md` (`grep -n "Observe'"` → no matches). Every
  occurrence across L86-L104 is unprimed.

So a critic wanting to submit an action property has no syntactic precedent anywhere in the
document. The statement silently models the invariant shape.

That bias happens to point the right way — gap 2 is not gradable as a conjunct
(`ANSWER-KEY.md:75-152`), and pushing gap-2 findings toward Notes is where we want them. So
the vagueness costs less than it saves. **But it is safe by luck, not by the reasoning
given**, and if a future column-C problem has a gradable action-property gap this same
silence will suppress it. Worth a note in the §9.6 brief.

---

## 5. Burned-mechanism vocabulary

The §5.7 screen returned BURNED on atomic commitment / two-phase commit
(`statement/screens.md:79-94`). My question is narrower: does the *wording* make the 2PC
pattern-match easier than the domain alone would?

**Surface tokens: clean.** `grep -iE "commit|abort|prepare|prepared|coordinator|participant|
vote|two-phase|transaction|resource manager"` over `PROBLEM.md` → **no matches**. The author
avoided every 2PC surface word.

**Structure and roles: not clean.** The AC skeleton is reproduced with the roles named
explicitly:

| Statement | AC / 2PC |
|---|---|
| L45/L52/L58 "unanimity" ×3 | the load-bearing word of the atomic-commitment literature |
| L27 "The **city**, the only party that can issue a permit" | single coordinator, stated as an exclusivity property |
| L26 "A fixed, finite set of **review departments**" | the participant set |
| L40-41 "record an approval" / "record that it wants changes" | vote-yes / vote-no |
| rule 1, rule 7 | commit/abort exclusive, and the outcome absorbing |

"Unanimity" is the leak. It is the one AC term the statement keeps, it is kept three times,
and per G3 it is absent from the artifact. A reader who knows `TwoPhase.tla` maps this in one
pass.

**The effect is asymmetric, and that is the finding.**

- **On gap 1 it helps a lot.** The AC prior is "the coordinator commits iff every participant
  voted yes." A primed reader checks the city's guard *first* and finds `ApprovedBy # {}`.
  This lands on the gap that is already the most over-signposted, so it compounds G1, G2 and
  G3 rather than diversifying the routes.
- **On gap 2 it does not help, and may hurt.** I agree with `statement/screens.md:119-120`
  that the amendment reset has no ACP analogue. In 2PC votes latch and there is no reset
  round, so a primed reader has no prior that predicts a clearing rule. Rule 4 exists
  precisely to disable the latching prior — which is a genuine defence of item 2 above.

Net: the burned mechanism **widens the difficulty gulf between the two gaps** rather than
lowering the floor evenly. Not a reason to reject.

**Cheap instrumentation this buys, and I recommend it:** step 6 should ask each critic, after
they submit, whether they recognized the domain as atomic commitment. A critic who did and a
critic who did not are not running the same experiment, and with n=3 that confound is large
enough to swamp the result. One question, asked after the fact so it leaks nothing.

---

## 6. Overall verdict

**Fit to put in front of three blind critics. Ship it — after the §0 fix. Do not send it
back to step 4.**

The dominant finding is G1: the `.cfg`'s six declared checks tile the seven numbered rules
with exactly two holes, and the holes are the two seeded gaps, so both are reachable without
reading an action body. That route is compounded by G2 (`approvedBy` is the only
behaviourally unconstrained `Observe` field, and L95/L99 aim the answer straight at it) and
G3 ("unanimity" is the statement's most-repeated technical noun and appears zero times in the
artifact). Together these make gap 1 close to over-determined, and I expect 3/3 critics to
find it. **But G1 lives in the deficient spec's `.cfg`, not in `PROBLEM.md`** — delete L8-9
and a critic still opens the `.cfg` and still builds the table — so a step-4 rewrite cannot
close the thing most worth closing, and would spend a round trip to buy back a courtesy
sentence and a singular article. The statement itself is sound: it passes §5.7b on my
independent reading at seven of eight rows, its only puzzle row is forced by column C, it
leaks nothing about the frozen reference beyond the two requirements it is obliged to state,
and its three most-criticized lines (rule 4, the `Departments` generality clause, the Notes
block) are each load-bearing for something that would cost more to lose than the hint costs
to keep. What must change is not the prose but the surrounding measurement: fix the delivery
boundary in §0, read a 3/3 result on gap 1 as a ceiling effect and not as pipeline success,
and split the gap-2 grading rule into *named it* and *argued its inexpressibility* — because
after G1, G4 and the Notes block, only the second half still measures anything.
