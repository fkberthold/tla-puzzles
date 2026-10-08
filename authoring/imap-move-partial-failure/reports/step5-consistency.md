# Step 5 consistency check: imap-move-partial-failure

Bead `tla-pmm2.4`. Written 2026-10-08 by the one reader that saw RFC 9051
section 6.4.8, RFC 6851 section 3.3, the step 3 spike and the step 4 statement
together. No `VECTOR.md` and no difficulty number here, per decision D4.

Inputs read in full: `sources/spikes/imap-move-partial-failure/REPORT.md`,
`authoring/imap-move-partial-failure/statement/PROBLEM.md`, both RFC texts
fetched fresh, RFC 9051 Appendix E, and the complete errata lists for both RFCs.

## Verdict

**Not sufficient as it stands. One change is required and it is a small one.**

Requirement 1 is not the clause the RFC strengthened, and no model the standing
orders permit can break it. `PROBLEM.md:96` to `:97` closes the only door
through which a part entry could ever stand: "The clerk never marks an entry for
striking at all." With that sentence in force, every model built from the rules
has `Observe.sending` and `Observe.receiving` ranging over two values rather
than three, requirement 1 at `PROBLEM.md:177` is true by construction, and TLC
reports it the same way it reports a real pass. The statement warns about exactly
this hazard at `PROBLEM.md:44` and then walks the learner into it.

The same sentence is this statement's one leak. There is no defect narrative to
withhold here, so a leak has to look like a sentence that resolves a check, and
that is what `:96` does.

**The required change is to rule 3, not to requirement 1.** The RFC's analogue
of the part entry is the Deleted flag, and RFC 9051 states it as a prohibition
on a reachable action, not as a denial that the action exists: "the \Deleted flag
MUST NOT be set for any message" (`rfc9051.txt:4683`). Rule 3 should say the same
about the mark for striking, that the clerk does not leave one standing, rather
than that she never makes one. Then requirement 1 is non-vacuously true of a
correct model and false of a sloppy one, which is what a check is for.

A second change is wanted and is not a blocker. Rule 4's first promise at
`PROBLEM.md:111` and requirement 1 at `PROBLEM.md:177` are two different claims
presented as one, and the history paragraph at `PROBLEM.md:212` attaches the
revision to the weaker of the two. Detail in the last section.

Everything else comes back in the statement's favour. The modal promotion in Q2
is right, the silence in Q3 is handled better than the spike asked for, and the
prose carries no other hand-over.

## Q1. Is the per-item reading right, or convenient?

**It is right, and I reached it from the text without needing either half's
argument. But the argument both halves used to get there does not work, and the
conclusion it reaches about clause 3 is the wrong way round.**

### The reading

Read cold, three things in section 6.4.8 settle it.

**The vocabulary is asymmetric and the asymmetry is deliberate.** The clause is
"each individual message MUST be either moved or unaffected"
(`rfc9051.txt:4687`). The next two sentences name mailboxes explicitly, "in at
least one of the source or target mailboxes" (`:4688`) and "in both mailboxes"
(`:4690`). The clause that is supposed to be about location is the only one of
the three that does not mention a mailbox. Authors who meant a location
predicate had the vocabulary two lines away and did not use it.

**The sentence's own contrast is set against item, not here against there.**
"Regardless of whether the command is successful in moving the entire set, each
individual message" (`rfc9051.txt:4686`). The axis the sentence is drawn along
is the unit of atomicity. That is a claim about what the server may half-do, not
about where a message sits.

**"Moved" is defined earlier in the same section as a compound effect.** "a new
message is created in the target mailbox with a new UID, the original message is
removed from the source mailbox, and it appears to the client as a single
action" (`rfc9051.txt:4667` to `:4669`). Three parts. A clause asserting "moved
or unaffected" asserts one of two complete effects. Reading it as a location
predicate discards the definition the section gave two paragraphs earlier. And
"unaffected" has two non-location attributes to bite on in the same section, the
Deleted flag at `:4683` and the preservation of flags and internal date at
`:4665`.

So the per-item reading is the text's reading. Two agents sharing a brief did not
manufacture it.

### Where both halves go wrong

The statement author's argument, as the bead notes record it, is that clause 1
at MUST makes clause 3 dead text **unless** clause 1 means per-item atomicity.
That "unless" is backwards.

- Under the location reading, clause 1 is exactly the conjunction of clauses 2
  and 3, so **clause 1** is the redundant one.
- Under the per-item reading, clause 1 is strictly stronger than their
  conjunction, so **clauses 2 and 3** are the redundant ones. Moved implies out
  of the source, unaffected implies not in the target, and either way the
  message is in exactly one mailbox.

The per-item reading does not rescue clause 3 from redundancy. It relocates the
redundancy. Clause 3 is dead text under RFC 9051 on either reading, and so is
clause 2.

The spike has this measured and stops one step short of saying it.
`ClauseOneImpliesNotBoth` exits 0 and `ClauseOneImpliesNotLost` **also** exits 0,
on two servers each (`REPORT.md`, the vacuity-probe table). The spike draws the
conclusion for clause 3 only, writing that "a server that satisfies RFC 9051's
MUST cannot leave a duplicate, and the SHOULD NOT has nothing left to permit".
The adjacent row says the same about loss and the report does not say so. Its own
clause matrix corroborates it from the other side: every server that breaks
clause 2 or clause 3 breaks clause 1 at the same step, and the matrix has no
cell where clause 1 reads 0 beside a 12.

**What this costs the project is a framing correction, not a defect.** Three
names are still right, and the reason is Lamport rather than logic. A named
obligation is a label in TLC's failure report, so merging two throws the label
away (`.claude/rules/tla-practice.md` section 1, quoting Specifying Systems
section 14.5.3, p. 259). The spike's seeded-bug matrix is the measurement that
earns the three names: the five variants have three distinct signatures across
the clauses, and `WeakFloorOnly` misses `stray-deleted-flag` by exactly one
(`REPORT.md`, the seeded-bug matrix and the submissions paragraph). Diagnostic
independence, not logical independence, is what pays for the third name. Both
halves should say so.

### The erratum search, over the full list

**No erratum touches section 6.4.8, and RFC 6851 has no errata at all.** The
spike's negative result holds, and I can now put a bound on it.

RFC 9051 carries **9 errata in total**: 3 Verified (7323, 8030, 8863), 5
Reported (7246, 7343, 7518, 7593, 8001), 1 Held for Document Update (6826), and
**0 Rejected**. Fetched from `https://www.rfc-editor.org/errata/rfc9051` and
re-fetched over the explicit All/Any view of `errata_search.php` with
`rec_status=15`, which renders three group headers and no Rejected group. The
sections named are 6.4.4.4, 6.3.10 twice, 7.5.2, 9, 4.1.1, Appendix E, and two
GLOBAL. None is 6.4.8.

Two near misses, so the negative is not mistaken for a gap. **7323 names
6.4.4.4, one digit from 6.4.8**, and is a BADCHARSET parenthesization fix in
SEARCH. The two GLOBAL errata are global in label only: 8863 is the
IMAPrev1 and IMAPrev2 spelling, and 6826 is Appendix E item 18.

RFC 6851: 0 errata at every status, from
`https://www.rfc-editor.org/errata/rfc6851` and the same All/Any view.

**The draft history answers the intent question better than an erratum could,
and neither half had it.** Bisecting the `draft-ietf-extra-imap4rev2` revision
series on the clause text: revisions 07, 13, 20, 21, 23 and **24** read "SHOULD
either be moved", and **25**, 26 and 30 read "MUST either be moved". The flip
landed in revision 25, and it did not land alone. The same revision rewrote the
lead-in from "Because a MOVE applies to a set of messages, it might fail partway
through the set" to "Unlike the COPY command, MOVE of a set of messages might
fail partway through the set". Two coordinated edits in one revision, posted by
the editor on 2021-01-20, the day IETF Last Call on revision 24 closed
(`https://datatracker.ietf.org/doc/draft-ietf-extra-imap4rev2/history/`).

Why no public thread names it: the GENART Last Call review of revision 24
(Sparks, 2021-01-14, "Ready") records that its nits "were sent directly to the
editors". That is where a change of this size leaves the public record. Two web
searches for an extra-WG thread or an imap4rev2 issue returned nothing on point.

So: the strengthening was **deliberate** and is **undocumented in the RFC**. The
spike's "mild tension with itself" reading stands, and the tension is sharper
than the spike put it, because clause 1 at MUST subsumes clause 2 as well as
clause 3. [INFERRED, on deliberateness: from the two coordinated edits in one
revision at the Last Call deadline, not from any statement of intent.]

## Q2. Promoting a SHOULD NOT to a hard INVARIANT

**The promotion is right. Keep requirement 3 as an `INVARIANT`. The statement's
stated reason for keeping requirements 2 and 3 separate is wrong and should be
replaced.**

### Why the promotion is sound

The statement does not smuggle it. `PROBLEM.md:115` carries the asymmetry as
rules text, "They require the second and they only ask for the third", gives the
consequence in the society's own vocabulary, and then narrows the system: "The
clerk here does as asked on both counts, so all three are checks"
(`PROBLEM.md:119` to `:120`). A declared narrowing of the modelled system is the
correct handling of a SHOULD NOT, and nothing claims the orders require it.

There is a stronger reason the statement does not reach for, and it comes out of
Q1. Under RFC 9051, clause 3 is a logical consequence of clause 1, which is a
MUST. So checking the no-duplicates condition as a hard invariant **asserts
nothing a conforming RFC 9051 server can violate.** The promotion adds no
constraint at all. The spike measured the same thing from inside a model,
`ClauseOneImpliesNotBoth` at rc 0 on two servers. The modality only has teeth
against RFC 6851, where clause 1 was a SHOULD and the duplicate was permitted by
every MUST in the paragraph, which is where Thunderbird 610131 sat.

Answering the question as posed: no, clause 3 should **not** be demoted to
something the learner is told is a preference. It is a consequence of a MUST in
the edition the problem is set against. Telling the learner it is only a
preference would be true of 2013 and false of 2021.

### Does the independence measurement justify three names

Yes, and it is the only thing that does. The spike's measurement is the right
one: copy-first breaks clauses 1 and 3 and never touches 2, expunge-first breaks
1 and 2 and never touches 3 (`REPORT.md`, the clause matrix). Three distinct
failure signatures mean three distinct labels in TLC's report, which is the
p. 259 argument.

But note what that measurement is and is not. It shows the three can **fail
independently**, which is weaker than logical independence, and in the RFC's
clause set the independence is one-directional: clause 1 can fail alone, while
neither 2 nor 3 can fail without 1 failing too. So the three names are earned
diagnostically and not logically.

### The subsection that needs rewording

`PROBLEM.md:207` to `:208`, under "Requirements 2 and 3 are separate on purpose",
tells the reader not to join them and gives this reason: "The orders hold them at
different strengths, which is rule 4, and a single formula throws that away."

That reason does not work. TLC has one strength. Declaring two formulas under
`INVARIANT` says nothing about MUST against SHOULD NOT and cannot, which is the
spike's own closing caution: "TLC knows true and false, not MUST and SHOULD". A
learner who follows the given reason learns something false about what a `.cfg`
can express.

The reason that does work is the one the next sentence already gestures at,
"Each of the three above rules out something the other two allow"
(`PROBLEM.md:209`), plus the labelling argument: three names tell you which one
broke. Recommend the different-strengths sentence be cut from this subsection and
left where it belongs, in rule 4 at `PROBLEM.md:115` as history and as the reason
the clerk's conduct is narrowed.

## Q3. The silence about the rest of the set

**The statement's claim is verified. It leaves the choice open and it does not
make "stop here" the obvious reading. And the choice turns out not to matter at
this interface, which is a result neither half has.**

### The claim, checked against the text

Grepped `PROBLEM.md` for `stop`, `halt`, `cease`, `in turn`, `one at a time`,
`order`, `first failure`, `remaining`, `rest of`, `continue`, `carries on`,
`goes on`. Eleven hits, every one unrelated: nine are "standing orders" or "the
orders", one is the deadlock paragraph's "the system stops" at `PROBLEM.md:232`,
one is "Working out which of their rules" at `:174`. **No sentence says the clerk
stops at the first failure and none says she continues.**

The statement goes further than neutrality and actively removes the place a
learner would put an index. `PROBLEM.md:60` to `:62`: each roll "numbers its own
entries, and the two numberings have nothing to do with each other. So the
question a roll answers about a member is whether it carries an entry for her,
never under what number." And rule 2 says the secretary "has named a set of
members", a set and not a list. That is the prefix nudge disarmed at its source,
and it is better than the spike asked for. The spike's third recommendation, "Say
the silence out loud in the statement, or the prefix model is what a learner will
build", asks for an explicit flag. The statement instead removed the index. I
prefer what the statement did.

### Why the choice does not decide whether the problem has content

The brief holds that a prefix model is "sound and uninteresting, so this is the
one choice that decides whether the problem has content". **At this interface
that is not so, and the interface is why.**

`Observe` exposes three fields and not one of them carries an order: `sending`
and `receiving` are functions from `Members` to three conditions, and `answer` is
a scalar (`PROBLEM.md:139` to `:168`). `Members` is a set of model values. **No
formula over `Observe` can distinguish a prefix model from a set model**, because
the only thing the two disagree about is which member was reached first, and
order is not in the observation.

Concretely, at the declared instance of two members both models reach the same
four condition vectors: nobody over, m1 over, m2 over, both over. A fixed-order
prefix model omits one of those four. All three requirements hold in every case
and no check changes.

The spike's `NoMixedOutcome` probe does separate the two, and its counterexample
is why it can: its state 3 is a `LeaveOne` step read off against `pending`, and
both the action name and `pending` are internal state the spike's own model
declares. Neither is visible through `Observe`.

**So what the prefix reading costs is state count and nothing else.** It is not a
reason to change the statement. It is worth one sentence in the author notes,
because a learner who fixes an order has forbidden a step the orders allow, which
is the second failure direction the statement already names at `PROBLEM.md:42`,
and the traces are where that gets caught.

## Q4. The declared gap, and the leakage sweep

### The traces gap

Both omissions are declared and both should be closed before the reference is
frozen. The convention is already fixed by the siblings and should be followed
rather than reinvented: `authoring/custody/statement/traces/` and
`authoring/laytime/statement/traces/` each hold a `README.md`, one satisfying
behaviour, and one violating trace per requirement, each a table whose columns
are the `Observe` fields plus a narration of the step that led in, closing with a
**Where it breaks** line naming the state.

So: `traces/README.md`, one satisfying run, and `requirement-01.md`,
`requirement-02.md`, `requirement-03.md`.

**Authoring `requirement-01.md` is what will force the verdict's fix.** That file
has to exhibit a state where a roll carries a part entry, and under
`PROBLEM.md:96` no such state exists. The trace cannot be written until rule 3 is
changed. That is the gap and the defect meeting, and it is the reason to fix rule
3 rather than to soften requirement 1.

Recommend the traces section follow laytime's three notes in substance
(`authoring/laytime/statement/PROBLEM.md:227` to `:231`), in particular the
over-constraint gate, "If your model can't produce the allowed run of every pair,
it's over-constrained, however green your checks are". That note is this
problem's only defence against the prefix model and against a learner who models
no failure at all.

### What the Checking section should say

Follow laytime's shape (`authoring/laytime/statement/PROBLEM.md:233` to `:257`):
the instance, why that size, what the `.cfg` declares, the deadlock flag, then
the distinct-state figure with the over-counting caveat. The statement already
has the first four. It needs the fifth.

**Do not quote 43.** The brief offers "atomic 3-message at 43 states depth 5",
and the statement checks at two members, not three (`PROBLEM.md:219`). The
spike's row for two is **17 distinct states at depth 4**, and the three-message
row is 43 at depth 5 (`REPORT.md`, the "How big it is" table). Quoting 43 against
a two-member instance would be wrong by the spike's own table.

**Do not quote 17 either, without re-measuring.** The spike's four variables are
`loc`, `flagged`, `pending` and `resp`, and `flagged` has no counterpart in a
statement-faithful model, since the statement renders the flag as a third
condition on the roll rather than as a separate attribute. The spike's state
count is a count over a different state shape. The figure the Checking section
quotes should be measured on the frozen reference at step 6 and nowhere else. 17
is a useful bracket for the author and not a number for the statement.

What the Checking section should say about counterexample shape is available and
is worth saying: every anomaly in the spike is **2 distinct states at depth 2**
(`REPORT.md`, the thirteen violated rows). A learner whose first counterexample
is twenty states deep has modelled the mechanism.

### Leakage

Swept the statement for sentences that resolve the clause-1 reading for the
learner. **One finding, and it is the verdict's finding.**

`PROBLEM.md:96` to `:97`: "The clerk never marks an entry for striking at all."
This does not hand over a diagnosis, because there is no defect narrative here to
withhold. It does something worse for a check: it settles requirement 1 in the
rules, so the requirement cannot be false of any model the rules permit. The RFC
states the same content as a prohibition on an action that exists
(`rfc9051.txt:4683`), and the difference between a prohibition and a denial is
exactly the difference between a check and a tautology.

Three candidates I considered and cleared:

- `PROBLEM.md:108` to `:113`, rule 4 handing over the three promises. This is the
  spike's first recommendation refused, "The clause set has to be derived, not
  handed over". It is a **format disagreement, not a leak.** Every statement in
  `authoring/` gives the learner its requirements under named keywords, and the
  interface is fixed because the checker compares values. The derivation step the
  spike wants belongs to a different problem format than this project has. Worth
  recording as the one place spike and statement want different things, and worth
  not acting on.
- The interface mandating three conditions (`PROBLEM.md:153`, `:162`). Same
  answer. The codomain has to be declared for the checker to run, and declaring
  it is what makes requirement 1 statable at all.
- `PROBLEM.md:212`, the history paragraph. Not a leak. It carries the
  SHOULD-to-MUST story, which is this candidate's distinguishing feature and
  which the spike correctly notes the model cannot see. It is misattached, which
  is a correctness point and is below.

## The two survey corrections, verified

### 1. The diff is two changed lines of nine. Confirmed.

Fetched both texts fresh. `rfc9051.txt` is 8659 lines and `rfc6851.txt` is 451,
matching the spike. The paragraph is bounded by blank lines, verified: lines 174
and 184 of `rfc6851.txt` and lines 4684 and 4694 of `rfc9051.txt` are all empty.

A unified diff over `rfc6851.txt` lines 175 to 183 against `rfc9051.txt` lines
4685 to 4693 reports two hunked lines and nothing else:

```
-   Because a MOVE applies to a set of messages, it might fail partway
+   Unlike the COPY command, MOVE of a set of messages might fail partway
-   moving the entire set, each individual message SHOULD either be moved
+   moving the entire set, each individual message MUST be either moved
```

A line-by-line pairing of the two blocks through `awk`, comparing field 1 against
field 2, prints `7 2 9`. **Two changed lines, seven identical.** Both edits
confirmed at the line numbers the spike cites: `rfc6851.txt:175` against
`rfc9051.txt:4685` for the COPY contrast, and `rfc6851.txt:177` against
`rfc9051.txt:4687` for the modal. The adverb does move with the modal: "SHOULD
either be" became "MUST be either". The survey's "with the rest of the paragraph
byte-identical" (`sources/rfcs.md` section 11.8) is wrong about the first
sentence and right from the second onward.

Two small slips in the spike's own prose, neither load-bearing. It writes "Six of
the nine lines are" identical and seven are. And it writes "the first sentence
carries two changes", where the two changes fall in two different sentences, the
fail-partway sentence and the moved-or-unaffected sentence. Its sentence
numbering in the diff section also runs one behind its clause numbering in the
matrix table, where clause 1 is moved-or-unaffected.

### 2. Appendix E does not record the strengthening. Confirmed, and more strongly.

`sources/rfcs.md` section 11.8 reads "RFC 9051 Appendix E corroborates", quoting
only "Tightened requirements about COPY/MOVE commands". **That is a truncated
quote and the full item is about something else.** `rfc9051.txt:8039`, item 8:

```
   8.   Tightened requirements about COPY/MOVE commands not creating a
        target mailbox.  Also required them to return the TRYCREATE
        response code, if the target mailbox doesn't exist and can be
        created.
```

The truncation cuts at exactly the word that changes the subject. Appendix E runs
from `rfc9051.txt:8009` to `:8110`, and a grep of it for `move`, `copy`,
`partial`, `orphan`, `duplicate`, `unaffected`, `lost` and `TRYCREATE` returns
MOVE in three items only: item 2 folding in RFC 6851, item 7 on the COPYUID
response code, and item 8 above. **No item mentions the per-message clause.**

**One reason the spike does not give, and it strengthens the finding.** Appendix
E is titled "Changes from RFC 3501 / IMAP4rev1" (`rfc9051.txt:8009`). RFC 3501
has no MOVE command, so a change log written against RFC 3501 has no baseline for
a clause that first appeared in RFC 6851. The appendix list runs A to F
(`rfc9051.txt:7861`, `:7976`, `:7985`, `:7993`, `:8009`, `:8110`) and there is no
"Changes from RFC 6851" appendix at all. So Appendix E is not merely silent on the
strengthening, it is **the wrong document to look in**, and no amount of reading
it could have corroborated the claim.

**`sources/rfcs.md` section 11.8 is wrong and other work rests on it.** The
sentence should be struck or replaced. Two downstream references to fix or check:
`sources/rfcs.md:1932`, the step 2 candidate row, which cites the SHOULD-to-MUST
as what "tells the learner which clause is load-bearing", and
`sources/rfcs.md:2152`, which generalises from this candidate to "every 'Changes
from RFC NNNN' appendix in this survey". That generalisation is built on the
wrong example and the whole method claim deserves a second look.

The replacement available is stronger than what it replaces: the draft series
records the edit directly, in revision 25 of `draft-ietf-extra-imap4rev2`, and
the Q1 bisection above gives the revision, the date and the coordinated second
edit.

## Things nobody asked about

### Rule 4's promise 1 and requirement 1 are two different claims

This is the second recommended change and the root of the verdict. The statement
renders the RFC's clause 1 twice, differently:

- `PROBLEM.md:111`, rule 4: "Every member is transferred whole, or left alone."
  This is the RFC's clause 1 faithfully. It implies both other promises.
- `PROBLEM.md:177`, requirement 1: "At every moment, neither roll carries a part
  entry for any member." This is a structural claim about the condition
  function's range. It permits a member off both rolls, so it does **not** imply
  requirement 2 at `PROBLEM.md:183`.

A reader who formalises rule 4's promise 1 writes something strictly stronger
than requirement 1 and is then told, correctly, that their formula passes. A
reader who formalises requirement 1 writes something the rules make
unfalsifiable. Neither reader is doing anything wrong.

There is a silver lining worth stating, because it is the one place the statement
improves on its source. The statement's three requirements, unlike the RFC's
three clauses, are **mutually logically independent**. Writing the per-member
condition pair as sending-then-receiving over the values off, part and on:

- on with part breaks requirement 1 alone.
- off with off breaks requirement 2 alone.
- on with on breaks requirement 3 alone.

No one of the three follows from the other two. That is a genuinely better
decomposition than the paragraph's, and it is what the Q1 analysis says the
paragraph does not achieve. It is worth keeping. It only needs the on-with-part
pair to be reachable, which is the rule 3 fix.

### The history paragraph is attached to the wrong formula

`PROBLEM.md:212`: "Requirement 1 has a history worth knowing. An earlier edition
of the standing orders put it as something the clerk should do. The present
edition makes it something she must do."

What the revision touched is the clause rendered at `PROBLEM.md:111`, rule 4's
promise 1, not the formula at `:177`. Once rule 3 is fixed and the two are the
same claim, the paragraph becomes true as written. Until then it tells the learner
that the RFC strengthened a no-intermediate-states structural invariant, which is
not what happened.

Separately, the paragraph sits under the heading "Requirements 2 and 3 are
separate on purpose" and is about requirement 1. Worth its own heading.

### The statement's vacuity warning predicts its own defect

`PROBLEM.md:40` to `:45` names three ways a model can be wrong and the third is
"A requirement can come out true because nothing your model is able to do would
ever break it. TLC reports that the same way it reports a real pass." That is
requirement 1 under rule 3, stated in advance. I am recording it because it means
the author had the right instinct and the defect is in one sentence of rule 3
rather than in the design.

The spike hit the same shape from the other side and reported it as a feature,
correctly for its own model: under the observe probe, `MCAtomic3` exits 8 with
"field deleted never changes. It is the empty set in all 43 distinct states TLC
reached" (`REPORT.md`, the frozen-variable section). A conforming server leaves
the flag alone, so the frozen variable **is** the requirement being met. The
spike's own caution is the one that applies to the statement: "A learner's model
that froze `flagged` by accident would look identical from outside, and nothing
mechanical separates the two." In the spike the flag is at least settable by a
non-conforming server. In the statement, rule 3 forbids the clerk from ever making
the mark, so there is no model at all in which the condition appears.

### A harness vacuity gap the spike found and could not fix

Not mine either, and it should be a bead if it is not one. `harness/vacuity.sh`
returns the `NON_VACUOUS` token at rc 0 when three of its five probes were
**skipped** because the run stopped at a counterexample (`REPORT.md`, "A
NON_VACUOUS whose probes did not run"). The prose explains it and the quiet flag
suppresses the prose, so a caller reading only the token believes five probes
passed when two ran. This problem's reference will be checked by a caller reading
the token.

### Both spike and statement are internally consistent on everything else

Checked and found no disagreement on: the three-clause decomposition, the
deadlock-checking requirement and its justification, the two-mailbox shape, the
tagged NO holding all three requirements (`PROBLEM.md:122` against
`rfc9051.txt:4692` and the spike's `NoMeansNothingHappened` probe at rc 12), the
refusal saying nothing about which members were reached (`PROBLEM.md:131` against
the spike's flat-abort model), and the COPY and APPEND contrast
(`PROBLEM.md:102` to `:105` against `rfc9051.txt:4630` and `:3446`).

The statement's choice of two members is right and its justification is right.
`PROBLEM.md:225`: "Two is the least that shows a member carried over and a member
still at her old branch in the same moment." The spike's mixed-outcome probe is
the measurement behind that sentence and the statement reached it blind.
