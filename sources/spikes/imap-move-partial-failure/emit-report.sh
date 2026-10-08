#!/usr/bin/env bash
# Write REPORT.md.
#
#   bash sources/spikes/imap-move-partial-failure/emit-report.sh
#
# The report quotes TLA+ and TLC output, so it carries set literals like
# {m1, m2} throughout. The worktree-isolation harness reads a brace group on a
# command line and refuses it, so a heredoc carrying this text cannot be typed
# directly. A script's body is never scanned, only its invocation.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat > "$HERE/REPORT.md" <<'REPORT_EOF'
# Spike: IMAP MOVE partial failure

Built 2026-10-08 against TLC 2026.07.31.184830 (`tlc`, rev 30cc360). Every row
came from `harness/spike-measure.sh` run from the repository root. Raw rows are
in `measurements.tsv`, and every table below comes back from one of the seven
`run-*.sh` scripts beside it.

Two headlines. The three clauses really are three, and the evidence is that each
one fails where another holds. And the brief's account of the RFC diff is right
about the word and overstates the rest of the paragraph, which I measured rather
than took.

## The diff, measured

I fetched both texts and diffed them. Commands and results, in order.

```
curl https://www.rfc-editor.org/rfc/rfc6851.txt   # 451 lines
curl https://www.rfc-editor.org/rfc/rfc9051.txt   # 8659 lines
grep -n "unaffected" rfc6851.txt rfc9051.txt
  rfc6851.txt:178, rfc9051.txt:4688
```

The paragraph is 9 lines in each, bounded by blank lines at `rfc6851.txt:174`
and `:184`, and at `rfc9051.txt:4684` and `:4694`. Section headings are
`rfc6851.txt:140` "3.3.  Semantics of MOVE and UID MOVE" and
`rfc9051.txt:4650` "6.4.8.  MOVE Command".

`diff -u` over those two 9-line blocks reports **two changed lines, not one**.

**The word the brief names, and it is there.** `rfc6851.txt:177` against
`rfc9051.txt:4687`:

> RFC 6851: "Regardless of whether the command is successful in moving the
> entire set, each individual message **SHOULD either be** moved or unaffected."

> RFC 9051: "Regardless of whether the command is successful in moving the
> entire set, each individual message **MUST be either** moved or unaffected."

A word-level diff shows the adverb moved as well. "SHOULD either be" became
"MUST be either", so the edit is `SHOULD` to `MUST` plus `either` crossing `be`.
I read that as copy-editing around the real change rather than a second
normative move.

**The change the brief does not mention.** `rfc6851.txt:175` against
`rfc9051.txt:4685`, the sentence that opens the paragraph:

> RFC 6851: "**Because a MOVE applies to a set of messages, it** might fail
> partway through the set."

> RFC 9051: "**Unlike the COPY command, MOVE of a set of messages** might fail
> partway through the set."

So the paragraph gained an explicit contrast with COPY in the same revision that
strengthened the per-message clause. That contrast is the asymmetry this
candidate is about, and in 2021 the working group wrote it into the first
sentence.

**Is the rest byte-identical?** Six of the nine lines are, and so are sentences
2, 3 and 4 in full: the at-least-one-mailbox MUST, the both-mailboxes SHOULD
NOT, and the tagged-NO sentence. The brief says "with the rest of the paragraph
byte-identical", and that holds from sentence 2 onward. It overstates by one
sentence, since the first sentence carries two changes and neither is the
keyword.

**Appendix E does not record the strengthening.** `rfc9051.txt:8039` is the item
the surveyor's extract quotes, and the full text is:

> "Tightened requirements about COPY/MOVE commands not creating a target
> mailbox.  Also required them to return the TRYCREATE response code, if the
> target mailbox doesn't exist and can be created."

That is a different tightening in the same section. A grep over Appendix E
(lines 7900 to 8300) for `move`, `partial`, `orphan` and `duplicate` turns up no
item about the per-message clause. So the change log corroborates a neighbour
and is silent on the SHOULD-to-MUST. I think that makes the ground truth a
little weaker than the surveyor's note reads, and the diff itself a little
stronger, since the diff is the only record there is.

## The three neighbouring commands, and what each is atomic about

Worth pinning, because "two different failure models" undersells it. The three
commands differ in their unit of atomicity, not only in whether they have one.

| command | text | the unit |
|---|---|---|
| COPY | `rfc9051.txt:4630` "partial copy MUST NOT be done" | the destination mailbox |
| APPEND | `rfc9051.txt:3446` "no partial appending is permitted" | the destination mailbox |
| MOVE | `rfc9051.txt:4687` "each individual message MUST be either moved or unaffected" | one message, across two mailboxes |

COPY and APPEND both say to restore the destination mailbox to its state before
the attempt, with a UIDNEXT carve-out. MOVE says nothing about restoring a
mailbox and everything about where each message ends up. A client that reads all
three as all-or-nothing gets COPY and APPEND right and MOVE wrong.

## How big it is

Four variables, and every anomaly is two states deep.

| label | rc | verdict | secs | distinct | depth | vars |
|---|---|---|---|---|---|---|
| atomic-1msg | 0 | checked, no violation | 0.4 | 7 | 3 | 4 |
| atomic-2msg | 0 | checked, no violation | 0.4 | 17 | 4 | 4 |
| atomic-3msg | 0 | checked, no violation | 0.4 | 43 | 5 | 4 |
| atomic-4msg | 0 | checked, no violation | 0.3 | 113 | 6 | 4 |
| atomic-5msg | 0 | checked, no violation | 0.3 | 307 | 7 | 4 |
| atomic-6msg | 0 | checked, no violation | 0.3 | 857 | 8 | 4 |
| decomposed-1msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| decomposed-2msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| decomposed-3msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| expungefirst-1msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| expungefirst-3msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| storefirst-1msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| storefirst-3msg | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| probe-clause1-alone | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| decomposed-3msg-sized | 0 | checked, no violation | 0.3 | 197 | 11 | 4 |
| expungefirst-3msg-sized | 0 | checked, no violation | 0.3 | 99 | 8 | 4 |
| storefirst-3msg-sized | 0 | checked, no violation | 0.3 | 197 | 11 | 4 |

The `vars` column reads 4 on every row and 4 is what `MoveBase.tla` declares.
The `fairness`, `temporal` and `instance` columns read `no` on every row.

**Variable count is a fact about my modelling choices.** Four is `loc`,
`flagged`, `pending` and `resp`. The surveyor's estimate in `sources/rfcs.md`
was 4 to 5 and the model landed at the bottom of it, which I read as the
estimate being good rather than as a result about the problem.

**The 2-state rows are not sizes.** A model that violates its invariant stops at
the counterexample, so those rows measure time-to-first-violation. The three
`-sized` rows re-run the same servers under a clause each one satisfies, which
lets the exploration finish. The real sizes are 197, 99 and 197 distinct states.
Nothing here needs a budget, a constraint, a symmetry set or a view, and the
whole sweep of 17 rows is about 5 seconds of wall clock.

Scaling on the conforming server runs 7, 17, 43, 113, 307, 857 for one through
six messages, a ratio approaching 2.8 and still under half a second at six.

## Modelling the application, not the mechanism

A message here is a model value with a location and a flag. No UID, no sequence
number, no body, no internal date, no UIDNEXT, no response-code stream. All of
that is IMAP's mechanism and none of it is in the requirement, which is a claim
about which of two mailboxes each message is in.

I did not build the mechanism version, so I have no state count for the road not
taken. The brief's figures for the isolation spike were 405,673,796 distinct
states against 21, and I took that as settled rather than re-deriving it on a
different system.

**Message identifiers are model values.** `Msg = {m1, m2, m3}` in every config,
and the two mailbox names are defined inside `MoveBase.tla` as `Source == "src"`
and `Target == "tgt"` so no configuration can assign them. That keeps the model
values and the strings in separate domains, and a comparison across those two
domains is what aborts TLC at rc 255.

## Where the RFC is silent, and what I chose

**The RFC says nothing about what the server does with the rest of the set after
one message fails.** RFC 9051 section 6.4.8 says the command "might fail partway
through the set" and then constrains each individual message. It never says
whether the attempt continues.

I chose that it may. `pending` is a set and not an index, and `LeaveOne(m)`
removes one element exactly as `MoveOne(m)` does, so a failure on one message
says nothing about the others.

The alternative is the prefix model, where the server stops at the first failure
and every reachable outcome is some prefix of the set. It's sound, it's a
legitimate reading of the same silence, and it's what a learner gets by walking
an index. What it costs is the only interesting reachable state: with a prefix
model you can never have a later message moved while an earlier one was left
behind.

That claim is measured rather than asserted. Probe `NoMixedOutcome` says no
reachable state has one message finished-and-left and another
finished-and-moved. TLC refutes it at rc 12:

```
State 2: <MoveOne(m1)>    loc = (m1 :> {"tgt"} @@ m2 :> {"src"} @@ m3 :> {"src"})
State 3: <LeaveOne(m2)>   pending = {m3}
```

So m1 moved, m2 was left, and the command is still going. A prefix model cannot
produce that trace.

## Which clause a non-atomic move breaks

Three clauses by four servers, twelve runs, exit codes only. `bash
run-clauses.sh` prints it.

| clause | sentence | keyword | atomic | copy-first | expunge-first | store-first |
|---|---|---|---|---|---|---|
| `MovedOrUnaffected` | 1 | MUST (9051), SHOULD (6851) | 0 | **12** | **12** | **12** |
| `NotLostOrOrphaned` | 2 | MUST in both | 0 | 0 | **12** | 0 |
| `NotInBothMailboxes` | 3 | SHOULD NOT in both | 0 | **12** | 0 | **12** |

`TypeOK` is the fourth name in each full config and is the type layer, bundled
per `.claude/rules/tla-practice.md` section 1.

Read down the columns and each server has its own signature. The
copy-then-expunge server duplicates and never loses. The expunge-first server
loses and never duplicates. Read across and clause 2 and clause 3 each fail
where the other holds, which is the evidence that they are two requirements and
not one.

**The answer to "which clause does a non-atomic move break" is: the MUST, at the
same step as the SHOULD NOT.** The copy-then-expunge server breaks clause 1 and
clause 3 on the very first COPY, at `rfc9051.txt:4687` and `:4690`. It never
touches clause 2.

## The duplicate, which is the conforming-but-unwanted case

`bash run-traces.sh`, first block. Clause 3 against the copy-then-expunge
server, one message:

```
rc=12
Error: Invariant NotInBothMailboxes is violated.
State 1: <Initial predicate>
  inSource = {m1}   inTarget = {}     deleted = {}   left = {m1}   reply = "open"
State 2: <CopyOne(m1) of module MoveDecomposed>
  inSource = {m1}   inTarget = {m1}   deleted = {}   left = {m1}   reply = "open"
```

m1 is in both mailboxes after one step. The safety floor holds at that state and
everywhere else in this server, which the matrix above shows as rc 0 for
`NotLostOrOrphaned` on `MCDecomposed3`. So this is a server that satisfies every
MUST in RFC 6851 and breaks only a SHOULD NOT, which is Thunderbird bug 610131:
bulk move implemented as bulk copy then bulk delete, interrupted, leaving
messages in both folders.

The loss trace is the same shape with the order reversed, and it reaches the
state the field has no bug report for:

```
rc=12
Error: Invariant NotLostOrOrphaned is violated.
State 2: <RemoveOne(m1) of module MoveExpungeFirst>
  inSource = {}     inTarget = {}     deleted = {}   left = {m1}   reply = "open"
```

## The tagged NO has teeth

Probe `NoMeansNothingHappened` asserts that a NO means every message is still in
the source mailbox. TLC refutes it at rc 12:

```
State 2: <MoveOne(m1)>   loc = (m1 :> {"tgt"} @@ m2 :> {"src"} @@ m3 :> {"src"})
State 3: <Abort>         resp = "no"
```

The command answered NO with m1 already moved. That's what the paragraph's last
sentence buys, and a client that treats NO as "nothing happened" would
re-download m1 or leave it orphaned in its own view.

I gave this its own variable, and `resp` is the one of the four I'd argue about.
Without it the model is three variables and the last sentence of the paragraph
is unstatable. I think that sentence is a third of the client-side interest here,
so it earns the variable, but a smaller model that dropped it would still reach
every clause violation above.

## Vacuity probes

Fourteen refutation probes, each a claim I expected TLC to settle one way.
**Every one matched its prediction.** `bash run-probes.sh`.

| module | probe | wanted | rc |
|---|---|---|---|
| `ProbeAtomic` | `AllStayInSource` | 12 | 12 |
| `ProbeAtomic` | `NothingReachesTarget` | 12 | 12 |
| `ProbeAtomic` | `CommandNeverReplies` | 12 | 12 |
| `ProbeAtomic` | `NeverRepliesNo` | 12 | 12 |
| `ProbeAtomic` | `NoMixedOutcome` | 12 | 12 |
| `ProbeAtomic` | `NoMeansNothingHappened` | 12 | 12 |
| `ProbeAtomic` | `NoDeletedFlagEverSet` | 0 | 0 |
| `ProbeStoreFirst` | `ClauseOneIsNoStronger` | 12 | 12 |
| `ProbeDecomposed` | `ClauseOneIsNoStronger` | 0 | 0 |
| `ProbeStoreFirst` | `ClauseOneImpliesNotBoth` | 0 | 0 |
| `ProbeStoreFirst` | `ClauseOneImpliesNotLost` | 0 | 0 |
| `ProbeExpungeFirst` | `ClauseOneImpliesNotBoth` | 0 | 0 |
| `ProbeExpungeFirst` | `ClauseOneImpliesNotLost` | 0 | 0 |
| `ProbeExpungeFirst` | `NothingEverVanishes` | 12 | 12 |

The five rows I wanted at rc 0 are the ones a reader should be suspicious of,
since rc 0 is also what an unchecked invariant returns. Two things answer that.
`ClauseOneIsNoStronger` is the same operator text in both probe modules and it
exits 12 in one of them, so the operator really is being evaluated. And
`harness/vacuity.sh` runs the `TLCGet("spec").invariants # {}` guard on every
model below and reports "A INVARIANT is configured" each time.

## Can the three clauses fail independently

Three obligations that always fail together are one obligation wearing three
names, so this is the check the decomposition stands on. The answer is yes, and
it took measuring rather than reasoning.

**Clause 2 and clause 3 are easy.** The clause matrix settles both. Clause 2
fails on the expunge-first server where clause 3 holds everywhere, and clause 3
fails on the copy-first server where clause 2 holds everywhere.

**Clause 1 is the interesting one, and it nearly isn't independent at all.**
Clause 1 says each message is moved or unaffected. Read as a fact about the
location set alone, that means `loc[m]` is exactly `{tgt}` or exactly `{src}`,
which rules out the empty set clause 2 rules out and the full set clause 3 rules
out. So clause 1 would be exactly the conjunction of the other two, and naming
it separately would be the redundancy shape
`.claude/rules/tla-practice.md` section 4 found in 3 configs out of 899.

It escapes that because **unaffected carries the \Deleted flag and not only the
location**. RFC 9051 section 6.4.8 says so a few lines above the paragraph: "the
\Deleted flag MUST NOT be set for any message". A message still in the source
mailbox with \Deleted set is in exactly one mailbox and is not as it was.

Whether that state is reachable is a fact about the server, not about the clause,
and it splits:

| server | `ClauseOneIsNoStronger` | what that says |
|---|---|---|
| copy, store, expunge | rc 0 | clause 1 adds nothing over clauses 2 and 3 |
| store, copy, expunge | rc 12 | clause 1 is strictly stronger |

The copy-then-expunge server can only set the flag on a message that already has
its target copy, because that's the order the RFC lists the steps in. So every
flagged state there is also a both-mailboxes state. Mark the flag before you
copy and the state separates:

```
rc=12
Error: Invariant ClauseOneIsNoStronger is violated.
State 2: <StoreOne(m1) of module MoveStoreFirst>
  inSource = {m1}   inTarget = {}   deleted = {m1}   left = {m1}   reply = "open"
```

In one mailbox, carrying \Deleted. Clauses 2 and 3 both hold and clause 1 fails,
so all three can fail independently. The seeded-bug matrix confirms it from the
other side, and that's below.

**The forward implications hold.** `ClauseOneImpliesNotBoth` and
`ClauseOneImpliesNotLost` both exit 0 on two servers that between them reach
every shape `loc[m]` can take: `{src}` initially, `{src,tgt}` after a copy,
`{tgt}` after an expunge, and `{}` only on the expunge-first server, which
`NothingEverVanishes` refutes at rc 12.

That has a normative consequence worth stating. Clause 1 implies clause 3, so
**a server that satisfies RFC 9051's MUST cannot leave a duplicate**, and the
SHOULD NOT has nothing left to permit. Under RFC 6851 clause 1 was a SHOULD and
the duplicate was permitted by every MUST in the paragraph, which is exactly
where Thunderbird sat. One word closed that. I think the paragraph is now in mild
tension with itself, requiring at MUST something that forbids a state it
separately says only SHOULD NOT happen, and I haven't found an erratum or a
working-group thread saying whether that was intended.

## The mechanical battery

`bash run-vacuity.sh`. Nine runs of `harness/vacuity.sh` at `-n 4`.

| module | config | verdict | rc |
|---|---|---|---|
| `MCAtomic3` | own | `NON_VACUOUS` | 0 |
| `MCDecomposed3` | own | `NON_VACUOUS` | 0 |
| `MCExpungeFirst3` | own | `NON_VACUOUS` | 0 |
| `MCStoreFirst3` | own | `NON_VACUOUS` | 0 |
| `MCDecomposed3` | `clause3-lost.cfg` | `NON_VACUOUS` | 0 |
| `MCExpungeFirst3` | `clause3-both.cfg` | `NON_VACUOUS` | 0 |
| `MCStoreFirst3` | `clause3-lost.cfg` | `NON_VACUOUS` | 0 |
| `MCAtomic3` | own, `--observe` | `VACUOUS_FROZEN_OBSERVE` | 8 |
| `MCStoreFirst3` | `clause3-lost.cfg`, `--observe` | `NON_VACUOUS` | 0 |

Two of those need explaining and both are findings rather than noise.

### A NON_VACUOUS whose probes did not run

The first four rows all read `NON_VACUOUS` at rc 0, and for three of them that
verdict covers two probes instead of four. `vacuity.sh`'s own remediation says
so, in the text that `-q` suppresses:

```
The satisfiability probe did not run, so nothing here says Spec
admits a behaviour.
The dead-action probe did not run, so no action was proved live.
```

A model that violates its invariant stops at the counterexample, so there's no
complete coverage block for `total == 0` to read. That's sound behaviour and the
message is honest. What's awkward is that the **verdict token is the same**, so a
caller reading only the token believes five probes passed when three never ran.
I hit it, and the only reason I noticed is that I printed the prose.

The fix on my side is rows 5 to 7: point the probe at a clause the server
satisfies, let the exploration finish, and the dead-action probe runs. Labelled
by run:

```
FIRED:   MCAtomic3 own
SKIPPED: MCDecomposed3 own
SKIPPED: MCExpungeFirst3 own
SKIPPED: MCStoreFirst3 own
FIRED:   MCDecomposed3 clause3-lost.cfg
FIRED:   MCExpungeFirst3 clause3-both.cfg
FIRED:   MCStoreFirst3 clause3-lost.cfg
```

I'd suggest `vacuity.sh` grow a token for "probes skipped because the run was
violated", but that's `harness/vacuity.sh` and not mine to edit.

### The dead-action numbers

`tlc -coverage 1`, read as `distinct:total`. The predicate is `total == 0` and
nothing matches it on any server.

| server | actions and totals |
|---|---|
| `MCAtomic3` | `Init 1:1`, `MoveOne 13:27`, `LeaveOne 13:27`, `Reply 9:16`, `Abort 7:19` |
| `MCDecomposedFull3` | `CopyOne 31:75`, `StoreOne 31:75`, `ExpungeOne 31:75`, `LeaveOne 31:75`, `Reply 9:16`, `Abort 63:117` |
| `MCExpungeFirstFull3` | `RemoveOne 21:48`, `AppendOne 21:48`, `LeaveOne 21:48`, `Reply 9:16`, `Abort 26:56` |
| `MCStoreFirstFull3` | `StoreOne 31:75`, `CopyOne 31:75`, `ExpungeOne 31:75`, `LeaveOne 31:75`, `Reply 9:16`, `Abort 63:117` |

Every `vacuity.sh` run also passed `--expect-actions` with the full action list,
which is the half of the probe that catches a deleted disjunct rather than a
dead guard.

### A frozen variable that is the requirement

`MCAtomic3` under `--observe Alias` exits 8:

```
field deleted never changes.
  It is {} in all 43 distinct states TLC reached.
```

The other four fields move: `inSource` 8 distinct values, `inTarget` 8, `left`
8, `reply` 3. So `flagged` is frozen in the conforming server.

That's not a defect. RFC 9051 section 6.4.8 says "the \Deleted flag MUST NOT be
set for any message", so a conforming server leaves it alone and the variable
sitting constantly FALSE is the requirement being met. Probe
`NoDeletedFlagEverSet` exits 0 for the same reason. The same observation over
`MCStoreFirst3` exits 0, because the flag does move there.

I'm reporting it rather than working around it because vector 5 fires on exactly
the shape a problem author should look at twice, and here the second look says
keep it. A learner's model that froze `flagged` by accident would look identical
from outside, and nothing mechanical separates the two.

## The seeded-bug matrix

`bash run-matrix.sh`. Five variants, each one definition of the reference
changed, verified by `diff` against `matrix/reference/`.

| variant | module mutated | clauses that catch it |
|---|---|---|
| `copy-without-expunge` | `MoveAtomic` | 1 and 3 |
| `expunge-without-copy` | `MoveAtomic` | 1 and 2 |
| `stray-deleted-flag` | `MoveAtomic` | 1 alone |
| `leave-half-moves` | `MoveAtomic` | 1 and 2, via the failure branch |
| `abort-loses-pending` | `MoveBase` | 1 and 2, via the tagged-NO path |

Grading the author's own three-clause property:

```
BUGS_CAUGHT
Your property holds of the reference (rc=0) and is violated by every
seeded variant (rc=12), on the same counterexample the oracle found.
```

**5 of 5 caught, rc 0.** No variant came back `VARIANT_INERT`, so the oracle
catches all five too.

**And I watched it say no, twice.** A matrix that only ever reports BUGS_CAUGHT
is not evidence of anything.

`submissions/WeakTrue.tla` is `Inv == TRUE`. Verdict `PROPERTY_TOO_WEAK` at
rc 40, with all five variants MISSED.

`submissions/WeakFloorOnly.tla` is the three-clause property with clause 1
removed, which is what a reader writes once they notice clause 1 implies the
other two. Verdict `PROPERTY_TOO_WEAK` at rc 40, **4 of 5 caught and
`stray-deleted-flag` MISSED**. That's the independent confirmation of the probe
result above: dropping clause 1 costs exactly one bug, and it's the one where
the message sits in a single mailbox carrying a flag.

Two things the matrix doesn't say, and its own header insists on both. The
variants are mutants of a correct reference, and about 10.9% of real faulty
specs are one mutation from correct, so this measures the variant set rather
than instruction. And `--property Inv` takes one name, so the oracle bundles all
four clauses into one conjunction. That's the right shape for "does it ever say
no" and says nothing against naming the three separately in the clause configs,
which answer a different question.

## Difficulty

**Level 3, at its lower edge. Candidate-selection only, not a placement.**
Placement comes from the load vector after the reference is frozen, and nothing
below is an input to that.

By `PRACTICE-PLAN.md:259`, level 3 is "several functions, or a nested one, or
rules relating entities". `MoveBase.tla` declares two functions over one entity
kind, `loc` from `Msg` to `SUBSET Mailbox` and `flagged` from `Msg` to
`BOOLEAN`, plus a set and a scalar. `loc` is a function into a set, which is the
nested reading. Tier 5 is out mechanically, since the `instance` column reads
`no` on all 17 rows. The progress half of tier 4 is out for the same reason:
`fairness` and `temporal` read `no` everywhere, and the whole story is safety.

**Level 2 is the live alternative, and it wins if the three clauses are given.**
Tier 2 is "one function as state, few entities", and `flagged` is nearly
degenerate, frozen in the conforming server and moving in only one of the four.
Hand a learner the three clauses and the modelling job is one function over three
model values, which is tier 2 work. What keeps it at 3 is deriving the clause set
from the paragraph and finding that clause 1 needs the flag.

Tier 4's other half, "the abstraction boundary is the question", is the one I'd
argue about. The RFC supplies its own second description of the machine, and
whether the three steps' intermediate states are observable is the content. But
a learner reaches every result here without deciding it, because the per-message
atomic model is the direct reading of the RFC's own sentence. So I'd call the
boundary visible rather than load-bearing.

The counterexamples support the lower edge. Every anomaly is 2 distinct states
at depth 2 with 4 variables, and counterexample width is what
`PRACTICE-PLAN.md:263` anchors the scale on. The fencing problem's smallest
reproduction is 22 states at depth 6. This one is an easier read than that by
the scale's own measure.

## Discrepancies

**The brief's "rest of the paragraph byte-identical" overstates by one
sentence.** Measured above. The SHOULD-to-MUST claim is exactly right, including
the line numbers in the surveyor's note in `sources/rfcs.md`.

**Appendix E corroborates a neighbour, not this clause.** Also measured above.
Worth fixing in `sources/rfcs.md` section 11.8, which reads "RFC 9051 Appendix E
corroborates" off a truncated quote.

**The fencing spike's variable over-count no longer reproduces.**
`sources/spikes/fencing/REPORT.md` reports that `harness/spike-measure.sh`
over-counts by one when `VARIABLES` sits alone on its line, and that `Broken.tla`
declares 7 while the tool reads 8. My `MoveBase.tla` has `VARIABLES` alone on its
line and the tool reads 4, which is correct. Re-measuring the fencing module:

```
$ bash harness/spike-measure.sh --dir sources/spikes/fencing --module Broken
recheck-fencing-vars  Broken  12  invariant violated  0.4  91  62  7  7  ...
```

7 declared, 7 reported. The awk in `spike-measure.sh` now carries a comment
describing that exact bug as fixed, so I read this as closed between the two
spikes rather than as a disagreement. The fencing report's discrepancy section is
stale, and a reader following it would distrust a correct number.

**`harness/vacuity.sh` returns NON_VACUOUS when three of its five probes were
skipped.** Covered above. The three broken servers under their own configs all
hit it. Not mine to fix.

**TLC leaves a trace-exploration module beside the spec on every violated run.**
This directory collected one `*_TTrace_*` file per violated run plus a `states/`
directory before I added `-noGenerateSpecTE` to every runner. Worth knowing for
any spike whose expected verdict is 12, which is most of them.
`harness/spike-measure.sh` is unaffected, since it copies into a temp directory
first.

## Files

- `MoveBase.tla`, the shared state, the three clauses, `Init`, `Reply`, `Abort`
- `MoveAtomic.tla`, the conforming server and the matrix reference
- `MoveDecomposed.tla`, copy then store then expunge, which duplicates
- `MoveExpungeFirst.tla`, expunge then copy, which loses
- `MoveStoreFirst.tla`, store then copy then expunge, which breaks clause 1 alone
- `Probe*.tla`, four probe modules carrying 14 probes
- `MC*.tla`, 16 wrapper modules carrying one config each
- `matrix/`, the seeded-bug matrix: reference, oracle, five variants
- `submissions/`, two deliberately weak properties
- `gen-wrappers.sh`, `gen-matrix.sh`, `emit-report.sh`, the generators
- `run-clauses.sh`, `run-probes.sh`, `run-traces.sh`, `run-vacuity.sh`,
  `run-measure.sh`, `run-matrix.sh`, every table above
- `measurements.tsv`, all 17 rows

## Verdict

**Good practice problem, and I'd build it.** The paragraph is nearly
pre-formalised, the three clauses are genuinely three, and the whole thing fits
in four variables and a two-state counterexample. I think it's the cleanest
property-decomposition exercise in the survey, and the decomposition is the
exercise rather than a given.

**Three things I'd change about how it's set.**

The clause set has to be derived, not handed over. Give a learner
`MovedOrUnaffected`, `NotLostOrOrphaned` and `NotInBothMailboxes` and you've
removed the whole problem. Give them the paragraph and the hard step is noticing
that the first sentence isn't the conjunction of the other two, which takes
finding the \Deleted flag in a different sentence.

The duplicate has to be reached before the loss. The duplicate has a real bug
report behind it and it's the one a conforming RFC 6851 server was allowed to
produce. The loss is the case nothing in the field has an instance of, which
makes it the better second half and a poor first one.

Say the silence out loud in the statement, or the prefix model is what a learner
will build. Nothing in either RFC says what happens to the rest of the set, and
an index is the obvious representation. A statement that doesn't flag the
silence gets a sound, uninteresting model and no way to tell that's what
happened.

One caution on all of it. The SHOULD-to-MUST story is what makes this candidate
unusual, and the model can't see it. TLC knows true and false, not MUST and
SHOULD, so the strengthening shows up only as which servers a reader should call
conforming under which revision. I think that's still worth the problem, since
the measured consequence is sharp: one word made the duplicate a violation of a
MUST. But a learner who never reads RFC 6851 gets the model without the history,
and nothing in the model will tell them anything is missing.
REPORT_EOF

printf 'wrote %s (%d lines)\n' "$HERE/REPORT.md" "$(wc -l < "$HERE/REPORT.md")"
