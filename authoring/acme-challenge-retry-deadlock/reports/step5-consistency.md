# Step 5: the consistency check

Written 2026-10-08 against TLC2 Version 2026.07.31.184830 (`tlc` with no
arguments, line 1). One reader, three inputs: RFC 8555 downloaded fresh, the
step 3 spike, and the step 4 statement.

The RFC copy I read is 5323 lines, md5 `e9b5c2fac497669080cb041ca737b831`,
which is byte for byte the copy the spike measured. So every line number below
is comparable with the spike's.

## Verdict

**The statement is NOT sufficient, and one edit is needed before the step 6
freeze.** Everything else about it is sound, and the two declared gaps are
real gaps rather than oversights.

The defect is one sentence wide. The nine requirements are all safety claims
and action claims, and the collapsed reading of the rules satisfies every one
of them. I measured that rather than reasoning about it:

| model, at the statement's own checking instance | nine requirements | rc |
|---|---|---|
| the collapse, one act writes the entry and gives up | all nine hold | 0 |
| the faithful reading, give-up is its own act | requirement 1 violated | 12 |

The collapse comes back green over 16 distinct states at depth 5, and the
retry loop provably never turns in it: the invariant "no applicant ever carries
more than one entry" **holds** at rc 0, and so does "no applicant ever stands
under inspection carrying an entry". Those two rc 0 results are the whole
problem. A learner who collapses the two acts gets nine green checks and a
model in which the office never goes back.

Nothing in the statement forces the loop to turn. Rule 3 says the office
**can** visit more than once, rule 9 relieves every act of obligation, and no
requirement is a reachability claim. The only instrument the statement offers
is the promised trace directory, which does not ship, and which could not do
the job even when it does. See Q3.

**The edit.** Add a second deliverable under "What to deliver". Suggested
wording, which withholds the diagnosis and supplies the instrument:

> Also deliver one formula you expect TLC to refute, and the run that refutes
> it. The office going back a second time is a claim that some run reaches a
> state, and none of the nine requirements is a claim of that kind. Pick a
> formula that is false if the office ever goes back twice, declare it as an
> `INVARIANT`, run it on its own, and report which way it came out.

That sentence does not say the rules forbid the loop and does not predict the
outcome. It names the distinction between a safety claim and a reachability
claim, which the spike's verdict section asks to be taught rather than
assumed, and it hands the learner the one tool that separates the two readings.

## Q1. Can a learner reach the four-way reading from the statement alone?

**Not reliably, and the reason is the one above.** The statement carries all
four passages faithfully. Rule 6 is section 8's sentence, rule 4 is section
8.2's error-entry MUST, rule 5 is section 8.2's "while the server is still
trying", and the handbook diagram is section 7.1.6 including the self-loop.
Flagging none of the conflict was correct.

What is missing is any obligation that the loop turn. The statement makes the
loop something a learner must **read about**, in three places: rule 3's
"within one inspection the office can visit more than once", rule 2's "later
word is how he asks the office to come back", and the Checking section's
justification of a patience of two. All three are permissions. Rule 9 then
says explicitly that nothing has to happen, which is faithful to the RFC and
which also removes the last lever. A model in which no applicant ever sends
word satisfies all nine as well, since every requirement is an upper bound and
the opening state satisfies requirements 1 and 2.

So the sentence that is missing is not a statement of the conflict. It is a
deliverable that is a reachability claim. The exact edit is in the verdict.

## Q2. Does the statement support the technique the problem needs?

**Too subtle as written, and the subtlety is misdirected rather than merely
thin.**

The statement does teach a vacuity lesson, in "Where a step rule is watching".
That lesson is about subscripts: a step rule whose subscript watches the wrong
field stops seeing the steps it was written about. It is a good section and it
is a **different** hazard from the one this problem turns on. A learner who
reads it has been told that green can be meaningless, has been given a
procedure for the subscript case, and has every reason to think that is the
vacuity lesson of this problem. It is not. The collapse defeats the nine
requirements with every subscript watching all three fields, which is what I
ran.

The nearest thing to the right technique is the paragraph at the end of "Your
task": "Forbid a step the rules allow, and every check stays green over a
system that no longer exists ... a model that never turns the loop will pass a
great many things." That names the direction and the symptom correctly. It
then hands the learner the traces as the instrument, and the traces cannot
carry it (Q3). So the statement names the technique's motivation and supplies
no technique.

On requirement 3's granularity, the author's choice was right and it is also
the trapdoor. Conditioning on `givenUp` **after** the step means a collapsed
model satisfies requirement 3 with a false antecedent, which I confirmed in
the rc 0 run above. Leaving the give-up granularity open is correct, per the
spike's "the give-up decision has to be the learner's choice". But an open
choice with no instrument for telling the two choices apart is a coin flip,
and the green side of the coin is the wrong one.

## Q3. The two declared gaps

### The distinct-state count under Checking

**Recommendation: quote no count, and do not write the sentence the spike
proposed.**

The spike's view is that the honest answer may be "no model satisfies all
nine". That claim is **false**, and this is a correction to the spike rather
than a judgement call. The collapsed model satisfies all nine at rc 0. The
true claim is narrower: no model that turns the retry loop satisfies all nine.
Putting the spike's version into the statement would be both wrong and a leak.

Any count that could be quoted presupposes a resolution of the contradiction,
and whichever resolution is picked the count hands it over. The Checking
section should therefore keep its first sentence, "No distinct-state count is
quoted here", and **drop its second**, "The pairs in traces are the check",
which promises an instrument that does not exist and could not work. Replace
it with a pointer to the refuted-invariant deliverable from the verdict.

### The traces

**They must contain a turn of the loop in the allowed run, and requirement 1
forbids exactly that. The pairs as specified cannot be authored.**

This is the finding I would most want carried into step 6. The statement says
of each pair: "A run the rules allow. Your model must be able to produce it."
A run that turns the loop contains a row in which an applicant stands at
`"inspecting"` with a defect count of one or more. Requirement 1 says a
non-zero defect count means he stands at `"refused"`. So that row breaks
requirement 1, and the run is not one the rules allow.

The consequence is that every allowed run authored to satisfy all nine is a
collapsed run, and the traces would then **certify the wedge** rather than
catch it. Shipping the directory does not fix Q1.

What the pairs must contain, if step 6 still wants them:

- One allowed run per requirement, each reaching the state that requirement is
  about, which is the project's existing lesson and is satisfiable for
  requirements 2 and 4 through 9.
- For the loop, a run in which some applicant reaches `"inspecting"` with a
  defect count of one and then takes a further step at the same applicant.
  That single row is unreachable in a collapsed model and is the only thing in
  the whole artifact that forces the loop. **Marking it allowed resolves the
  contradiction against requirement 1 and tells the learner the answer.**
- One further limit: the trace fields cannot show the applicant's word at all.
  `Observe` has three fields and none of them is the client's revisit request,
  so of the diagram's two self-loop arms the traces can exhibit only the office
  revisit. Rule 2's "later word changes nothing" is untestable over this
  interface.

My recommendation is to drop the per-requirement pair promise from "What you
get" and keep the refuted-invariant deliverable instead. If the pairs stay,
the loop-turning run has to be labelled allowed, and the statement should then
expect the problem to be easier than the spike assumed.

## Q4. Leakage

**The author's belief is confirmed, with one qualification.** Nothing in the
statement names the conflict, names the collapse, or tells the learner that
the rules cannot all hold. I read every rule, the interface, all nine
requirements, the diagram and both the Checking and Traces sections for it.

Four places I examined and cleared:

- Rule 5's "the office gives up on an applicant when it chooses. Nothing
  forces it" licenses the give-up as its own act without requiring it, because
  rule 9 removes the obligation. Both readings survive rule 5. That is the
  trap set correctly.
- Rule 3's "Reaching the number settles nothing by itself" forecloses a
  different wedge, where a learner gives up automatically at `Patience`. It
  adds nothing about this one.
- Rule 4's "When the office turns a man down it ordinarily writes an entry" is
  the RFC's SHOULD, correctly kept out of the nine.
- The handbook diagram reproduces the section 7.1.6 label defect **exactly**,
  which is the right call and is worth saying out loud. "Failed visit" labels
  the edge into `refused`, while rule 5 on the facing page says a failed visit
  leaves the man under inspection and only a give-up refuses him. The diagram
  has no give-up edge, as the RFC's has none. The statement calls it "the same
  machine as a drawing", which is the RFC's own implicit claim and is false
  about the labels. Nothing in the nine tests it, so the defect survives into
  step 6 intact and available.

The qualification: the paragraph at the end of "Your task" leaks the
**symptom**. It tells the learner in advance that the risk on this problem is
a loop that never turns and that checks will stay green over it. It does not
leak the cause, and the RFC contains no narrated cause to leak. I judge this
the right place to give ground, because without that paragraph the statement
has no instrument at all. It should stay.

## The erratum verification

**Verified over the whole RFC, not four sections. No such sentence exists.**

The spike searched sections 7.1.6, 7.5.1, 8 and 8.2 for a sentence emptying
the error field on success, found none, and named the rest of the document as
the surface it had not covered. I searched the rest.

A grep for the quoted field name finds it three times in 5323 lines, at lines
3431, 3502 and 3504.

Of the normative sentences anywhere in the document that mention an error, only
two concern the challenge object's error field: line 3426, which is section 8's
sentence, and line 3504, which is section 8.2's MUST. Every other normative
mention is about HTTP responses and problem documents, which is a different
object. That was 28 matches from a grep for lines carrying both an error
mention and one of MUST, SHOULD, MAY or SHALL.

A further grep for every clearing verb in the document, over the alternatives
clear, remov, empt, delet, reset, discard, unset and omit, returns 28 lines and
not one of them empties that field.

The nearest candidate is section 7.5.1 at lines 3074 to 3076, and it runs the
other way: "When finalizing an authorization, the server MAY remove challenges
other than the one that was completed, and it may modify the 'expires' field."
The completed challenge, the one that went valid, is the one this sentence
does **not** permit removing. So it stays, carrying whatever it carried.

**So the finding stands and it is worth filing upstream.** Erratum 5732 is
Verified and not sufficient. A challenge whose first validation query failed
and whose retry succeeded reaches `valid` while still carrying the entry
section 8.2 made it MUST write, and the erratum permits an error only beside
`processing` or `invalid`. RFC 8555 needs a third sentence that nobody has
written. Do not build the delivered problem on this.

### The diagram label, re-checked

**Confirmed, independently.** The section 7.1.6 diagram is at
`rfc8555.txt:1690-1709`. Its `processing` to `invalid` edge is labelled
"Failed validation" across lines 1701 and 1702. Section 8.2's sentence at
lines 3497 to 3499 reads "While the server is still trying, the status of the
challenge remains 'processing'; it is only marked 'invalid' once the server has
given up." So a failed validation query does not take the edge the diagram
labels with its name. The edge is taken by the give-up, which section 8.2
never calls a failed validation, and the diagram has no give-up edge. Both
terminal states have no outgoing arrow.

The spike's sharpest finding holds on a second reading.

## Things nobody asked about

**1. The fourth ingredient is textual, not only structural, and that is
stronger than the spike claimed.** The spike gives section 7.1.6 a structural
role: it "draws no arrow out of `invalid`", so the state section 8 forces a
failed query into is final. Section 7.1.6 also carries the contradiction in
prose, in a single paragraph, without needing section 8 at all:

- `rfc8555.txt:1674-1676`: "Note that within the 'processing' state, the server
  may attempt to validate the challenge multiple times (see Section 8.2)."
- `rfc8555.txt:1686-1688`: "If validation is successful, the challenge moves to
  the 'valid' state; if there is an error, the challenge moves to the 'invalid'
  state."

The first asserts the loop. The second moves a challenge out of `processing` on
an error, and section 8.2 requires a failed query to record an error. Read
together they are the wedge, two sentences apart, in the section the community
treats as the arbiter. "If there is an error" is ambiguous between a validation
outcome and the error field, and I am not going to resolve it here, but the
contradiction survives either reading because section 8.2 calls a failed query
an error in the field and keeps it in `processing` regardless.

**2. The RFC itself calls the error field the retry state.** At
`rfc8555.txt:3501-3502`: "The server MUST provide information about its retry
state to the client via the 'error' field in the challenge." That is a third
MUST about the field, immediately before section 8.2's error-entry MUST, and it
is normative text. The spike attributes the retry-state framing to still-open
errata 7826. Errata 7826 is quoting the RFC, which makes its argument stronger
than the spike presents it.

**3. The frozen three-field interface cannot express two of the spike's seven
oracle arms, and one seeded mutant survives because of it.** `Observe` carries
standing, defect count and the give-up flag. It has no visit counter. So
`ErrorsBoundedByQueries` and `ProcessingAccountsForEveryQuery` cannot be
written over it at all. Measured consequence: I rebuilt the spike's
`error-without-query` mutant, where the office puts a further entry on the list
of a man it has already turned down with no visit behind it, and checked it
against all nine. It comes back rc 0 over 25 distinct states. The mutant
survives.

Reasoning over the remaining four mutants, which I did not run, puts the
statement's nine at about 2 of 5: `error-in-pending` and `reopen-after-giveup`
are caught by requirements 3 and 7, `giveup-without-error` is deliberately out
of scope because it comes from a SHOULD, and `error-not-written` is not caught
because every one of the nine is an upper bound and none requires an entry ever
to be written. `INFERRED` for those four. Against the spike's seven-arm
reference at 5 of 5 and erratum 5732's sentence alone at 1 of 5, a nine-
requirement deliverable that catches about 2 of 5 is worth knowing before the
freeze. It is not an argument for adding requirements, since the two missing
arms need state the interface does not carry. It is an argument for the
refuted-invariant deliverable, which catches the one failure none of the nine
can see.

## Method

Three scratch modules were built in the worktree, run, and **not committed**,
since this bead's footprint is the report. Each encoded the statement's nine
requirements verbatim as formulas over `Observe`, with requirements 1 and 2 as
`INVARIANT` and requirements 3 through 9 as `PROPERTY` action formulas
subscripted over the tuple of all three variables, at the statement's own
instance of two applicants and a patience of two, with `CHECK_DEADLOCK FALSE`.
They differed only in the next-state relation: one collapsed the defect entry
and the give-up into a single act, one kept them as two acts, and one added the
`error-without-query` mutant to the collapsed base. Rebuilding them takes about
ten minutes and the five rc values are below.

| run | rc |
|---|---|
| nine requirements against the collapse | 0, 16 distinct, depth 5 |
| never two entries, against the collapse | 0, holds |
| never inspecting with an entry, against the collapse | 0, holds |
| nine requirements against the faithful reading | 12, requirement 1 violated at depth 3 |
| nine requirements against the error-without-query mutant | 0, 25 distinct |
