# Spike: the ACME challenge retry deadlock

Built 2026-10-08 against TLC2 Version 2026.07.31.184830 (`tlc` with no
arguments, line 1). Every row came from `harness/spike-measure.sh` run from
the repository root. Raw rows are in `measurements.tsv`.

The three sentences do contradict, and the contradiction lands in a 3-state
trace over 4 distinct states in 0.4 seconds. That part held up.

Two things did not. **Erratum 5732's fix is not sufficient** on its own, and I
did not expect that going in. And the section 7.1.6 diagram, which errata 7826
treats as the arbiter, labels its own `processing` to `invalid` edge with the
phrase that section 8.2 uses for the edge that stays in `processing`. The
labels disagree while the graphs agree, and the mislabelling is what invites
the one modelling collapse that hides the bug.

## The three normative sentences

All three quoted from the RFC text, downloaded 2026-10-08:

```
curl -sS -o rfc8555.txt https://www.rfc-editor.org/rfc/rfc8555.txt
# 5323 lines, md5 e9b5c2fac497669080cb041ca737b831
```

**S1, section 8.2** (`rfc8555.txt:3497-3499`): "While the server is still
trying, the status of the challenge remains 'processing'; it is only marked
'invalid' once the server has given up."

**S2, section 8.2** (`rfc8555.txt:3504-3505`): "The server MUST add an entry to
the 'error' field in the challenge after each failed validation query."

**S3, section 8** (`rfc8555.txt:3426-3427`): "A challenge object with an error
MUST have status equal to 'invalid'."

S1 and S2 are built into `Challenge.tla`'s next-state relation. S3 is the
invariant `ErrorImpliesInvalid`, and `Challenge.cfg` checks it. The check
fails, which is the mechanical form of "these three cannot all hold".

A fourth ingredient is doing quiet work and is worth naming, because it is
what makes the failure matter rather than merely exist. Section 7.1.6 draws no
arrow out of `invalid`, so the state S3 forces a failed query into is final.
Without that, S3 would be a relabelling rather than a wedge.

## The counterexample, and whether it matches the erratum

```
bash sources/spikes/acme-challenge-retry-deadlock/run-check.sh Challenge
SAFETY_VIOLATION
rc=12
```

```
State 1: <Initial predicate>   status=Pending     errors=0  queries=0
State 2: <Respond>             status=Processing  errors=0  queries=0
State 3: <FailedQuery>         status=Processing  errors=1  queries=1
```

State 3 is a challenge object with an error whose status is not `invalid`. S2
requires the step that produced it and S3 forbids the state it produced.

**It matches erratum 5732, and the match is exact rather than close.** I
fetched the entry directly:

```
curl -sSL -A 'Mozilla/5.0' -o errata.html https://www.rfc-editor.org/errata/eid5732
```

Errata-ID 5732, status **Verified**, type Technical, reported by Rob Stradling
2019-05-23, verified by Paul Wouters 2024-02-22. It rewrites section 8 to "A
challenge object with an error MUST have status equal to 'processing' or
'invalid'." Its note reads:

> Section 8.2 says that 'The server MUST add an entry to the "error" field in
> the challenge after each failed validation query'. However, if the challenge
> must then become "invalid", it is never possible to retry any validation
> query (because "invalid" is a final state for a challenge object). This
> erratum is necessary to permit validation query retries to ever happen.

The erratum's claim has two halves and the model gets both. State 3 is the
state the erratum says section 8 forbids. And `Wedged.tla`, which resolves the
conflict in section 8's favour, satisfies `NeverTwoQueries == queries <= 1` at
rc=0: no behaviour of that spec holds a second validation query. That is the
erratum's sentence "it is never possible to retry any validation query", turned
into an invariant that holds.

The second half is the one I would build the problem around. It is the claim
that needs a counter, and section 7.1.6's diagram cannot state it at all,
because the retry is a `status` self-loop and a status-only machine cannot
count trips round a loop.

## The measured rows

| label | rc | verdict | secs | distinct | depth | vars |
|---|---|---|---|---|---|---|
| section-8-as-published | 12 | invariant violated | 0.4 | 4 | 3 | 5 |
| section-8-per-erratum-5732 | 12 | invariant violated | 0.3 | 6 | 4 | 5 |
| section-8-per-erratum-plus-clearing | 0 | checked, no violation | 0.4 | 13 | 6 | 5 |
| section-8-per-erratum-plus-clearing-maxq3 | 0 | checked, no violation | 0.3 | 18 | 7 | 5 |
| section-8-per-erratum-plus-clearing-maxq8 | 0 | checked, no violation | 0.4 | 43 | 12 | 5 |
| section-8-per-erratum-plus-clearing-3var | 0 | checked, no violation | 0.3 | 8 | 5 | 3 |
| retry-reachable-under-clearing | 12 | invariant violated | 0.3 | 6 | 4 | 5 |
| retry-reachable-prose-model | 12 | invariant violated | 0.3 | 6 | 4 | 5 |
| retry-unreachable-wedged-model | 0 | checked, no violation | 0.3 | 5 | 3 | 5 |
| section-8-holds-in-wedged-model | 0 | checked, no violation | 0.3 | 5 | 3 | 5 |
| section-8-as-published-3var | 12 | invariant violated | 0.3 | 4 | 3 | 3 |
| section-8-per-erratum-3var | 12 | invariant violated | 0.3 | 5 | 4 | 3 |
| section-8-per-erratum-maxq5 | 12 | invariant violated | 0.3 | 6 | 4 | 5 |
| prose-refines-section-7-1-6-diagram | 0 | checked, no violation | 0.3 | 13 | 6 | 5 |
| wedged-refines-section-7-1-6-diagram | 0 | checked, no violation | 0.3 | 5 | 3 | 5 |

**The headline row is 5 variables, 4 distinct states, depth 3, 0.4 seconds.**
The whole sweep of 15 models runs in about 5 seconds of wall clock. Nothing
here needs a budget, a state constraint, a symmetry set or a view.

The `vars` column read correctly on every row this time. The fencing spike
reported an over-count by one where `VARIABLES` sat alone on its line, and the
`grab` tracking now in `harness/spike-measure.sh`'s `nvars` awk fixes it:
`Challenge.tla` declares 5 and the tool reports 5, `Minimal.tla` declares 3 and
reports 3.

**A warning about the state counts on the rc=12 rows.** Those models stop at
the first counterexample, so 4 and 6 distinct are facts about the search, not
about the problem. The size of the problem is the rc=0 rows, and at
`MaxQueries = 2` that is 13 distinct states at depth 6. Scaling is gentle: 13,
18 and 43 at `MaxQueries` 2, 3 and 8, so about 5 states per extra permitted
query. There is one constant and it drives the space linearly.

### What the five variables cost

Three are load-bearing and two are not. `status`, `errors` and `queries` are
the contradiction: S3 needs `errors`, S1 needs `status`, and the erratum's own
sentence needs `queries`. `Minimal.tla` is those three alone and it reaches the
same anomaly in the same 4 states at the same depth.

`gaveUp` costs nothing. It is a function of `status` in every model here, and
rather than assert that I checked it:

```
bash run-check.sh Challenge gaveup-is-free.cfg   # INVARIANT GaveUpIffInvalid
OK
rc=0
```

What it buys is that the give-up decision is visible in the state rather than
only in the action structure, which turns the finality of a give-up into a
state invariant instead of a temporal one. The seeded-bug matrix uses that arm.

`clientRequest` costs 5 states, which is the whole difference between
`MCMinimalCleared` at 8 and `MCCleared` at 13. What it buys is one checkable
claim. Section 7.1.6 says "client requests for retries do not cause a state
change" (`rfc8555.txt:1687`), and without a variable the client can touch there
is no action for that sentence to be about.

I would build all five and then delete two, in that order, for the reason the
fencing spike gives about its clock: deleting a variable is the insight, and
you cannot have the insight before you have paid for the thing.

## The modelling decision the RFC leaves to the reader

**The deadlock is reachable only if the give-up decision is an action distinct
from writing an error. Collapse the two and the contradiction never shows.**

S1 names two events in one sentence. A failed query, after which the status
"remains 'processing'". And the server giving up, after which it is "invalid".
`Challenge.tla` has `FailedQuery` and `GiveUp` as separate actions, and only
the first writes an error.

A reader who treats those as one event writes `Wedged.tla`, and I want to be
precise about what happens to them, because "the bug is hidden" undersells it.
The wedged spec is not inconsistent. It is consistent and useless:

| check against `Wedged.tla` | rc |
|---|---|
| section 8 as published, `ErrorImpliesInvalid` | 0 |
| the published section 7.1.6 diagram, `Refines` | 0 |
| erratum 5732's own sentence, `NeverTwoQueries` | 0 |

Every safety check a learner is likely to write comes back green. Nothing in
the output separates it from a correct model. The only thing wrong with it is
that section 8.2's entire retry mechanism is unreachable, and that is a
reachability claim rather than a safety one. It takes an invariant you expect
to be **refuted** to see it, which is the vacuity discipline pointed at a
submission rather than at a harness.

So I think this is the sentence step 5 should hold the statement against: the
RFC leaves it to the reader whether a failed validation query and a server
give-up are one event or two, and the reader who picks one gets a spec that
passes every check and models nothing.

## Erratum 5732 is not sufficient, and this is the finding I did not expect

`MCErratum.cfg` checks the erratum's corrected sentence against the
prose-faithful model. I expected rc=0. It exits 12.

```
State 1: <Initial predicate>   status=Pending     errors=0  queries=0
State 2: <Respond>             status=Processing  errors=0  queries=0
State 3: <FailedQuery>         status=Processing  errors=1  queries=1
State 4: <SuccessfulQuery>     status=Valid       errors=1  queries=2
```

That is the behaviour section 8.2's retry mechanism exists to produce. A query
fails, the server retries, the retry succeeds. The challenge is now `valid`
while still carrying the error entry S2 made it MUST write, and the erratum
permits an error only beside `processing` or `invalid`.

So the corrected section 8 and section 7.1.6's "If validation is successful,
the challenge moves to the 'valid' state" (`rfc8555.txt:1687-1689`) conflict on
exactly the path the erratum was written to open. I checked the RFC for a
sentence that empties the error field on success and did not find one, searching
sections 7.1.6, 7.5.1, 8 and 8.2 of the downloaded text. The surface I did not
search is the rest of the document, so read this as "not in the four sections
that govern the challenge object" rather than as "not in RFC 8555".

Still-open errata 7826 (status **Reported**, Rob Stradling 2024-02-28, fetched
the same way) is the community circling the same hole from the other side. It
calls the `error` field the server's "retry state" and argues the retry-state
sentence should be scoped to `processing`. Read that way, a successful
validation empties the field, and the erratum holds.

`ClearOnSuccess` in `Challenge.tla` is that reading as a switch, and the switch
exists because the choice changes the verdict:

| `ClearOnSuccess` | corrected section 8 | retry reachable |
|---|---|---|
| FALSE, the faithful reading | rc=12 | rc=12 |
| TRUE, errata 7826's reading | rc=0 | rc=12 |

The right-hand column is the vacuity guard on the rc=0, and it matters. Without
it, "the erratum holds under clearing" is a claim a wedged model would also
satisfy.

My call: **erratum 5732 fixes the deadlock and opens a smaller hole on the
success path**, and the RFC needs a third sentence that nobody has written yet.
I would not build the delivered problem on this. It is a finding to file, and I
think it is worth more than the extra exercise it could become, because a
learner who reaches it has gone past a verified erratum rather than reproduced
one.

## Prose against diagram

Section 7.1.6's challenge diagram is transcribed in `Diagram.tla` as a
next-state relation over `status` alone: four edges, four labels, no counter.
`MCDiagram.tla` instantiates it and asks two separate questions, which is the
point, because the answers differ.

```
bash sources/spikes/acme-challenge-retry-deadlock/run-labels.sh
```

| module | cfg | token | rc | expected |
|---|---|---|---|---|
| MCDiagram | MCDiagram.cfg | OK | 0 | 0 |
| MCDiagram | label-failedquery.cfg | LIVENESS_VIOLATION | 13 | 13 |
| MCDiagram | label-giveup.cfg | OK | 0 | 0 |
| MCDiagram | label-retryloop.cfg | OK | 0 | 0 |
| MCWedgedDiagram | MCWedgedDiagram.cfg | OK | 0 | 0 |

**The graphs agree.** `Refines == D!DSpec` holds, so every transition of the
section 8.2 prose model projects onto an edge of the published diagram. That is
the `INSTANCE M WITH` shape from `.claude/rules/tla-practice.md` section 5,
checked with `PROPERTY`.

**The labels do not.** The diagram's `processing` to `invalid` edge is labelled
"Failed validation". Section 8.2's failed validation query does not take that
edge: the implied action `FailedQuery => D!FailedValidation` is violated at
rc=13. The action that does take it is `GiveUp`, at rc=0, and section 8.2 never
calls a give-up a failed validation. Meanwhile both of the prose model's
status-preserving actions land on the self-loop the diagram labels "Server
retry or client retry request", and one of them is the failed query.

So one phrase names two different edges across two sections of one document,
and the diagram has no give-up edge at all.

**And the wedged model is the one that matches the picture.** `MCWedgedDiagram`
checks `Refines` and `FailedQueryIsFailedValidation` together and both hold.
The reading that satisfies the diagram's labels is the reading that makes the
retry unreachable. That is uncomfortable, because errata 7826 settles an
ambiguity by appeal to this diagram, so the community treats it as the arbiter
and on this point the arbiter is the thing leading you wrong.

I think that makes the prose-against-diagram check the best part of the
problem, and not for the reason I assumed. The interesting result is not "the
diagram caught the prose". It is that the two artifacts agree on the state
graph, disagree on what drives one edge, and the disagreement is invisible to
any check over states. You need an implied action to see it.

## Vacuity probes

Four of the fifteen measured rows are rc=0, so each needs a paired probe that
TLC refutes. 14 probes, each naming one invariant so a refutation is
attributable, plus a negative control.

```
bash sources/spikes/acme-challenge-retry-deadlock/run-probes.sh
```

| module | cfg | invariant | token | rc | expected |
|---|---|---|---|---|---|
| Challenge | probe-processing.cfg | `NeverProcessing` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-valid.cfg | `NeverValid` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-invalid.cfg | `NeverInvalid` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-gaveup.cfg | `NeverGaveUp` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-clientasks.cfg | `ClientNeverAsks` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-error.cfg | `NoErrorEver` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-twoerrors.cfg | `ErrorsNeverTwo` | SAFETY_VIOLATION | 12 | 12 |
| Challenge | probe-query.cfg | `NoQueryEver` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | wedged-probe-processing.cfg | `NeverProcessing` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | wedged-probe-invalid.cfg | `NeverInvalid` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | wedged-probe-query.cfg | `NoQueryEver` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | wedged-probe-error.cfg | `NoErrorEver` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | wedged-probe-valid.cfg | `NeverValid` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | wedged-probe-clientasks.cfg | `ClientNeverAsks` | SAFETY_VIOLATION | 12 | 12 |
| Wedged | negative-control.cfg | `NeverTwoQueries` | OK | 0 | 0 |

All 14 refuted. The six against `Wedged.tla` are the ones carrying weight,
because the wedged model's headline verdict is an rc=0 and a model that moved
nowhere would satisfy `NeverTwoQueries` too. They establish that it leaves
`pending`, makes a first query, writes an error for it, reaches `invalid`,
still has an open success path, and fires its client-retry action. **The wedge
is on the second query and nowhere else.**

The negative control is the row that keeps the "expected" column honest. A
comparison that only ever sees one expected value is not a comparison. I also
ran the table once with that row's expectation deliberately set to 12 and
watched it print `DISAGREE`, so the agreement check is live rather than
decorative.

### The harness's own five vectors

The hand-written probes above are not a substitute for `harness/vacuity.sh`,
which catches two things none of them do: the dead-action predicate
`total == 0`, and a **deleted** action, which has no coverage row at all and is
therefore invisible to any predicate over the rows that are there.

```
bash sources/spikes/acme-challenge-retry-deadlock/run-vacuity.sh
```

| model | min-states | expected actions | token | rc |
|---|---|---|---|---|
| Challenge | 10 | 5 | NON_VACUOUS | 0 |
| Wedged | 4 | 4 | NON_VACUOUS | 0 |
| Wedged, negative control | 4 | 5, one absent | VACUOUS_DEAD_ACTION | 5 |

Both models pass all five vectors: non-empty space, an invariant configured, a
satisfiable `Spec`, every action firing, and every field of `Obs` taking more
than one value. The negative control names `GiveUp` against the wedged model,
which does not have it, and the probe reports it as the deleted shape rather
than the restricted one. So the dead-action channel is working and not merely
silent.

## Seeded-mutant pass

Five variants, each the reference with one action broken on purpose, each
aimed at one named arm of the oracle. Two submissions graded against the same
set.

```
bash sources/spikes/acme-challenge-retry-deadlock/run-matrix.sh
```

| submission | token | rc | caught |
|---|---|---|---|
| `Author.tla`, seven arms | BUGS_CAUGHT | 0 | **5 of 5** |
| `NaiveErrorRule.tla`, the erratum's sentence alone | PROPERTY_TOO_WEAK | 40 | **1 of 5** |

Phase 3 passed, so no variant came back `VARIANT_INERT`: the oracle catches all
five and the variant set is sound. Every one of `Author.tla`'s five catches
landed on the same counterexample as the oracle.

| variant | broken | arm that catches it | Author | Naive |
|---|---|---|---|---|
| `error-in-pending` | failed query returns to `pending` | `PendingIsUntouched` | caught | caught |
| `error-without-query` | give-up writes a further error | `ErrorsBoundedByQueries` | caught | missed |
| `reopen-after-giveup` | client response reopens an abandoned challenge | `GiveUpIsFinal` | caught | missed |
| `giveup-without-error` | give-up before any query failed | `InvalidCarriesError` | caught | missed |
| `error-not-written` | section 8.2's MUST dropped | `ProcessingAccountsForEveryQuery` | caught | missed |

**The 1 of 5 is the number I would carry forward.** `NaiveErrorRule.tla` is
nothing but erratum 5732's corrected sentence, which is the sentence this whole
problem is about, and on its own it catches one seeded bug in five. Stating the
rule the erratum fixes is necessary and nowhere near sufficient. If the problem
is set so that the learner's deliverable is that one invariant, the matrix says
the deliverable is thin.

The caveat `harness/seeded-bugs.sh` states at length applies and I am not going
to soften it. These are mutants of our own reference. About 10.9% of real
faulty specs are one mutation from correct and about 39.3% of single mutations
are semantically inert, so a caught-count measures this variant set and nothing
about a bug a learner would write. Do not report 5 of 5 as a pass rate.

One arm is weaker than the other six and the matrix is why I know which.
`ProcessingAccountsForEveryQuery` is derived rather than quoted: section 8.2
constrains a transition, and a transition is not a state predicate, so catching
a dropped error write needs an invariant that depends on the reference's own
action structure. `error-not-written` exists to hold that arm to account.
`InvalidCarriesError` comes from a SHOULD rather than a MUST, and it is
labelled so in `matrix/oracle/Oracle.tla` instead of being quietly promoted.

## Discrepancies

**An implied action whose antecedent opens with a set-membership test does not
parse.** The form `[][s \in S => s' = s]_s` exits 150 PARSE_ERROR, and SANY
reports the error at the subscript, 47 columns past the cause. Parenthesising
the antecedent fixes it. Isolated as a pair:

```
bash ../../../harness/verdict.sh ParseBad.tla    # PARSE_ERROR  rc=150
bash ../../../harness/verdict.sh ParseGood.tla   # LIVENESS_VIOLATION  rc=13
```

One pair of brackets is the whole difference between the two files. My reading
is that SANY commits to a function-constructor or record parse at the opening
bracket, but that is inference from the residual stack trace rather than
something I checked against the grammar, so `INFERRED`.

**Deadlock checking is an AND across the config and the command line, and
either side can switch it off silently.** Measured on `Wedged.tla`, five cells:

| `.cfg` | verdict.sh `-d` | rc |
|---|---|---|
| `CHECK_DEADLOCK TRUE` | absent | 0 |
| `CHECK_DEADLOCK TRUE` | present | 11 |
| `CHECK_DEADLOCK FALSE` | present | 0 |
| no keyword | present | 11 |
| no keyword | absent | 0 |

`harness/verdict.sh` passes TLC's `-deadlock` flag by default, which means "do
not check", so a learner who writes `CHECK_DEADLOCK TRUE` in their config and
runs through the harness gets no deadlock check and no notice of it. I have not
filed this, since it is outside my footprint.

**And deadlock checking would not have discriminated here anyway.** With the
flag on, the prose-faithful model and the wedged model both exit 11. Section
7.1.6 gives a challenge object two final states, so a reachable state with no
successor is intended in both, and rc=11 carries no information about which
model is wedged. The signal is the reachability probe, not the deadlock report.
This is why every config in the directory carries `CHECK_DEADLOCK FALSE`, which
79 of 337 configs in the corpus survey also do.

**The `--alias` refusal did not reproduce.**
`.claude/rules/dispatched-agents.md` says the isolation harness refuses any
command line containing `--alias`. It did not:

```
bash harness/seeded-bugs.sh --help --alias Obs      # ran, printed usage
```

The two refusals I did hit were different. A bare `echo` of a conjunction token
is refused, so that hazard is live on this build. And the harness refused two
compound commands of mine: one with nested command substitution, and a
`for ... done` loop containing `bash`. I kept the scratch-script route for the
matrix anyway, because the scripts also need to `cd` into the spike directory
so TLC resolves sibling modules, but the `--alias` line in the rules file is
not confirmed on this run.

**`scripts/test --list` reports 20 suites, 13 of them fast.**
`.claude/rules/dispatched-agents.md` says 15 suites and "the fast tier is 6 of
the 13 suites and about 4% of the wall time". The suite count and the fast-tier
split are both stale. `bash scripts/test --fast` ran all 13 fast suites green
in 15.8s. The ~257s figure for the full gate still holds against the budgets
`--list` prints (17.8s fast plus 239.5s slow). The rules file says `--list` is
the authority and that the number in prose is a description, so this is the
drift it predicted rather than a new problem.

## Difficulty

**Level 2 of 5. CANDIDATE-SELECTION ONLY, not a placement.** Placement comes
from the load vector after the reference is frozen.

I want to flag a mismatch rather than hide it behind the number.
`PRACTICE-PLAN.md:255-261` anchors the scale on state representation: tier 1 is
"scalar or set state, an algorithm with invariants over it" and tier 2 is "one
function as state, few entities". This model has no function-valued state
anywhere. Five scalars, one of them a model value and two of them booleans. By
the scale's own anchor it is tier 1.

I put it at 2 because tier 1's second clause does not fit. This is not an
algorithm with invariants over it. The work is finding three sentences across
two sections, deciding whether give-up is its own action, and noticing that a
published diagram's edge label does not mean what the prose means by the same
words. None of that is state-representation difficulty, which is what the scale
measures.

So my read is that the scale would misplace this problem in either direction,
and the honest report is the number plus the reason it is a poor fit. If the
load vector has a dimension for how much reading the problem takes before any
TLA+ gets written, this one would score high on it and low on everything else.

The optional diagram extension uses `INSTANCE`, which the plan marks as tier 5
territory. I would not read that as pushing the problem up. A one-variable
abstract module with four edges is the gentlest introduction to a refinement
mapping I can think of, and the mapping is the identity.

## Verdict

**Good practice problem, and I would build it.** The ground truth is as strong
as the survey said: a Verified erratum whose note states the defect in one
sentence, a second Reported erratum circling the hole the first one left, and
an implementation that skipped the mechanism outright. Let's Encrypt's Boulder
divergences document says under section 8.2 that "Boulder does not implement
the ability to retry challenges or the `Retry-After` header"
(`docs/acme-divergences.md:34` in `letsencrypt/boulder`, fetched 2026-10-08).

Three things I would change about how it gets set.

**The give-up decision has to be the learner's choice, not a given.** Hand them
a model with `FailedQuery` and `GiveUp` already separate and the problem is
over. The exercise is that S1 names two events in one sentence, and a reader
who collapses them gets a spec that passes every safety check they know how to
write. I would let them build the collapsed version, watch it come back green
on all three checks, and make the finding be that green meant nothing.

**The invariant you expect to be refuted is the technique, and it should be
taught rather than assumed.** `NeverTwoQueries == queries <= 1` holding at rc=0
is the whole result. Nothing about that reads as a finding until somebody
explains that an invariant you wanted broken is a reachability claim. This
problem is the smallest setting I have seen for that idea, and the seeded
matrix says it is also the part a learner would skip: the sentence the problem
is about catches 1 of 5 seeded bugs on its own.

**Set `MaxQueries = 2` and leave it there.** It is the smallest bound that can
show a retry, the whole sweep runs in 5 seconds, and the scaling rows say
raising it buys about 5 states per step and no new behaviour.

One caution on all of it. I built four readings of one RFC section and measured
them well, and I have not checked whether the prose-against-diagram result
generalises. My hunch is that it does wherever a standard ships a picture
alongside normative text, since the picture has no room for a sentence's worth
of qualification and the labels are where that shows up. That is a hunch, not a
result.

## Files

- `Challenge.tla` / `Challenge.cfg`, the prose-faithful model and the headline check
- `Wedged.tla` / `Wedged.cfg`, the collapse, and the erratum's sentence holding
- `Diagram.tla`, section 7.1.6's challenge diagram as its own relation
- `Minimal.tla`, the same anomaly at three variables
- `MC*.tla`, 10 wrapper modules carrying one config each
- `ParseBad.tla` / `ParseGood.tla`, the parse hazard, isolated
- `matrix/`, the seeded-bug matrix: reference, oracle, two submissions, five variants
- `probe-*.cfg`, `wedged-probe-*.cfg`, `label-*.cfg`, `deadlock-*.cfg`, the probes
- `run-*.sh`, `gen-probes.sh`, the drivers
- `measurements.tsv`, all 15 rows

## Re-running the numbers

From the repository root:

```bash
bash sources/spikes/acme-challenge-retry-deadlock/gen-probes.sh
bash sources/spikes/acme-challenge-retry-deadlock/run-measure.sh
bash sources/spikes/acme-challenge-retry-deadlock/run-probes.sh
bash sources/spikes/acme-challenge-retry-deadlock/run-labels.sh
bash sources/spikes/acme-challenge-retry-deadlock/run-vacuity.sh
bash sources/spikes/acme-challenge-retry-deadlock/run-matrix.sh
```

`run-matrix.sh` has to be a script rather than a command line, because
`harness/seeded-bugs.sh` takes `--alias` and the isolation harness has been
observed to refuse that token. It did not refuse it on this run, which is in
the discrepancies above. The drivers resolve their own root from
`${BASH_SOURCE[0]}`, so they write into whichever checkout invokes them.
