# herbarium-sheet step 6: the panel, and the spread read on the argument

Bead `tla-h2cg.12`, rung 6 of batch 2, shape D at form left open 1, kind 3. Run
2026-09-05 over three blind seats, one instance each, eight learner files staged
by name. No seat ever saw the reference, the description or any report, so the
solves stay blind and the spread argument stands.

## The panel

| seat | model | properties | attempts | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 7 | 1 | row player over all 14 runs, 92 TLC logs under `runs/`, an 8-mutant battery, requirement 3 both subscripts, and `M5a`/`M5b`/`DoubtClearsFixed` for the diagnosis |
| p2 | claude-opus-5 | 8 | unknown | `TraceCheck` over all 14 runs, 140 logs under `tc/`, inherited and read rather than re-run, plus a 15-run variant battery it ran itself |
| p3 | claude-haiku-4-5 | 7 | 1, one first-draft bug TLC caught | none past the main run. Per-pair catches asserted, two of them false |

The property counts are the declared cfg lines. p1's seven are the statement's
seven and nothing else (`p1/SOLVE.md` cfg block). p2's eight are the seven plus
a `TypeOK` of its own, which the statement allows and says doesn't count against
the list (`p2/SOLVE.md` §1). p3's seven are the statement's seven
(`p3/Herbarium.cfg`).

**On the attempts column.** A session limit killed the p1 and p2 seats partway
through their first run, and both were dispatched again. p2's staging directory
still held its own killed run's module, cfg and replay tree, dated 01:32 to
01:35 against a report written at 05:13, so p2's second instance inherited a
finished spec it had not watched itself write. It says so in its own provenance
note and declines to give a count rather than invent one, which is the right
call. Read that cell as unknown, not as one. p1 inherited the same kind of
leftovers, moved them to `p1/_preexisting/` unread, and built its own from
scratch (`p1/SOLVE.md` §6), so its one attempt is real. p3 ran once and was
never killed.

The difference in handling is worth carrying into the next brief. Two seats hit
the same contamination, both disclosed it, and only one of them still has an
attempt count. Moving the leftovers unread costs nothing and keeps the cell.
I'd write p1's move into the seat brief as the instruction.

## Verdict: SHIP BLOCKED, and the problem discriminates

Two halves, and they point different ways.

The discrimination half is green. Rule 2 for spec-in-hand shapes says property
content converges by design, so convergence isn't a leak signal here, and the
spread has to be read off the kinds, the subscripts, the instruments and the
diagnosis. It's there. Requirement 3's subscript is the rung's one deliberate
hole, and it split the panel 2-1: p1 and p2 both took the wide form and both
measured the narrow one blind, and p3 took `_(Observe.consulted)`, which the
trace map already measured as blind to every filing
(`author-notes/step4-trace-map.md:126-131`). On the shape D object, p1 and p2
both diagnosed the seeded defect and both built checks that establish it. p3
reported that the green run establishes the very implication the formula can't
see. That's the failure this shape exists to catch, and the shape caught it.

The blocking half is the statement's own promise. `PROBLEM.md:34-36` tells the
learner that every forbidden run must break at least one requirement. For pair
5's forbidden run and a correct declared seven, that's false. The next section
settles it.

## The disagreement, and how it comes out

p1 and p2 both diagnosed the seed and disagree about what rejects pair 5's
forbidden run. p2 says its set rejects it by requirement 6 and by its own
legality check (`p2/SOLVE.md`, the last section's second question). p1 says
nothing in its declared seven rejects it (`p1/SOLVE.md` §3, "Forbidden 5:
nothing in the declared seven").

The two requirement 6 forms are the same formula. p1's `EventuallyAnswered` and
p2's `ConsultationsAnswered` differ only in `~Obs.doubted[s]` against
`Obs.doubted[s] = FALSE` and in the spelling of the none marker. So the
disagreement was never about the property. It's about how you close a finite
trace.

I built a four-row trace player to settle it: `Obs == Tr[i]`, `Advance` under
`WF_i`, both seats' requirement 6 forms transcribed from their own files, and
the shipped requirement 5 alongside. Runs, all at `-workers 1`:

| trace played | property | rc |
|---|---|---|
| pair 5 forbidden | p1's requirement 6 | 13 |
| pair 5 forbidden | p2's requirement 6 | 13 |
| pair 5 forbidden | requirement 5 as shipped | 0 |
| pair 5 forbidden plus one lawful filing | both forms | 0 |
| **pair 7 allowed** | both forms | 13 |
| pair 4 forbidden | p3's declared seven | 0 |
| pair 4 forbidden | requirement 4 with its way-out clause | 13 |

The fifth row is the answer. The same instrument that "rejects" pair 5's
forbidden run also rejects pair 7's allowed run, which the statement guarantees
is lawful. So the rc=13 isn't a rejection. It's the stuttering tail the player
bolts onto a finite prefix, and requirement 6 is pure liveness, so no finite
prefix can violate it at all. Append one lawful filing step to the forbidden run
and both forms go quiet.

The statement says the same thing in the learner's hands.
`PROBLEM.md:284-286`: where a forbidden run's fault is that nothing more ever
happens, the trace says so under its last state. Pair 6's forbidden run carries
that sentence. Pair 5's doesn't. So the terminal reading is the one the
statement rules out for pair 5, and p2 took it anyway.

**p1 is right.** Nothing in a correct declared seven rejects pair 5's forbidden
run.

p2's own logs show where it slipped. It writes that requirement 6 fires on
allowed runs w=1, w=5, w=9 and w=13, and calls that liveness on a prefix rather
than a rejection. `tc/tc-9-TR6.log` reports no error and `tc/tc-10-TR6.log`
reports a violation, and w=10 is pair 5's forbidden run. The four traces its
requirement 6 actually fires on are w=1, w=5, w=13 and w=10. Three allowed
prefixes it discounted, and one forbidden prefix it counted. Same artifact,
opposite dispositions, and the off-by-one in the trace numbers is what hid the
inconsistency from it. I don't read that as a modeling error. p2's diagnosis of
the seed is the strongest on the panel and its instruments are sound. It
misclassified one row of its own log table.

## D4, ship blocker: the statement promises a universal it makes false

`PROBLEM.md:34-36`, step 5 of the instructions. With requirement 5 handed over
in its narrowed form and the learner told not to write their own, no correct
set has anything that breaks on pair 5's forbidden run. Requirements 1, 2, 3, 4
and 7 all hold on it, requirement 5 is blind to it by construction, and
requirement 6 can't be violated by a prefix the statement declines to mark
terminal. A learner who does the work as asked reaches a contradiction with the
instructions, and the honest resolution is the diagnosis the rung wants. The
dishonest one is p2's: find requirement 6 firing under a stuttering replay,
call it a rejection, and never notice that the same replay rejects three
allowed runs.

The fix I'd take is a reword of step 5, dropping the universal:

> Hold your model against the traces. Every allowed run must be a run your model
> can produce. For each forbidden run, work out which of your requirements
> breaks on it, and say so if none does.

That keeps the work, removes the false promise, and the closing clause is a
prompt the last section needs anyway. It does add a small tell, since it hints
that some run may break nothing. I think that's the cheaper cost. The step 5
report already found the seed reachable by inspection in about two minutes
(`reports/step5-leakage.md` §1) and asked the grader to weight the establishing
half, so a little more salience on the naming half doesn't change much.

The live alternative is to leave step 5 alone and mark pair 5's forbidden run
terminal, the way pair 6's is. That restores the promise literally, costs one
sentence in one trace file, and it's what I'd take if central would rather not
touch the instruction list. What it buys the learner is a rejection that has
nothing to do with the doubt, on a pair built to isolate requirement 5, and a
learner who stops there has skipped the diagnosis. That's the world p2 was
already in.

## Findings carried forward

**The 259 calibration is one-way, and p3 is the demonstration.** p2 measured two
wrong models landing on 259 distinct states exactly: `SpecReDoubt` at 1289
generated and `SpecUndoubt` at 1275, both at depth 7 (`p2/var-redoubt.log`,
`p2/var-r5-given-vs-undoubt.log`). p3's `Doubt` carries no `doubted[s] = FALSE`
guard (`p3/Herbarium.tla:48-51`), it reports 1289/259/7, and it reads the 259 as
"matched expected" (`p3/SOLVE.md` §2, §4). That's p2's prediction landing on
another seat's model in the same panel, from opposite directions and blind. The
statement states the count as a two-way check. It should give 1103 as the
figure that discriminates, or drop the two-way claim.

**Requirement 4's way-out clause is graded by pair 4, and now there's a live
proof.** The grading split says the way-in-alone form passes this instance
without carrying the requirement (`reports/step5-leakage.md` §7, row 4). p3's
requirement 4 has the way-in direction only (`p3/Herbarium.tla:88-98`), and its
whole declared seven come back rc=0 against pair 4's forbidden run, where the
same run with the way-out clause added comes back rc=13. The split's row 4 is
right, and the grader can point at a seat rather than at a prediction.

**A learner will meet the replay-convention problem, and the grader should
expect it.** Any trace player that closes a finite run with a stuttering tail
makes requirement 6 fire on pair 5's forbidden run and on the allowed runs of
pairs 1, 3 and 7. One sentence in the statement resolves it
(`PROBLEM.md:284-286`) and it's easy to read past. p1 applied it and p2 didn't,
and they're both strong seats. I'd put the convention in the grader's notes as
something to check for rather than something to assume.

**Rule 2's re-consultation is implicit and it's load-bearing here.** p2 flags
that a botanist may re-consult a sheet they already hold, the old stamp lost
rather than closed, and that a re-consultation mustn't discharge the
requirement 6 obligation (`p2/SOLVE.md` §6). Nothing in the statement says so
outright. It matters more than it looks, because pair 5's forbidden run turns on
exactly that step: b1's stamp is replaced, not closed, which is why requirement
4's way-out clause doesn't fire on it either.

**The requirement 7 warning under `PROPERTIES` is unannounced.** TLC prints a
paragraph recommending `INVARIANT` for a state-level formula under `PROPERTIES`,
which is what requirement 7 asks for. p1 and p2 both hit it and both read it
right (`p1/SOLVE.md` §2, `p2/SOLVE.md` §2). Neither was surprised, but a learner
will read it as their own mistake. A sentence in the statement costs nothing.

**The interface can't carry authorship, and all three seats found the same
edge.** p1 and p2 both name "every step is some botanist's" as unwritable over
`Observe`, and both agree with the statement's own note (`p1/SOLVE.md` §5,
`p2/SOLVE.md` §5). p2 adds a third the statement doesn't name: the shipped
requirement 5 carries nothing, so rule 6's real content is checked by nothing in
the declared set. That's the seed stated as a taxonomy entry rather than as a
bug, and it's the sharpest single line the panel produced.

## Recognition

All three seats named a mechanism. None named a published problem, so no run is
disqualified.

p1 recognized a versioned register with optimistic concurrency and the
lost-update problem, at rule 5 (`p1/SOLVE.md` §7). p2 recognized compare-and-set
on a version number with the doubt flag as a dirty bit, early, before writing
anything, and says it didn't look for a published source (`p2/SOLVE.md` §7). p3
recognized version control and amendment history (`p3/SOLVE.md` §7). Recorded,
not disqualifying, and all three used the reading soundly or not at all.

## Rule 6

All three seats came back first-try green on their own model, which for this
shape means little. The flag reads against the instruments and the diagnosis
instead, and there it splits: two of three built real checks and one built none.
Recorded, not fired.

**Step 6 closes SHIP BLOCKED on D4.** The problem discriminates and the
statement doesn't ship as written. D4 is a reword inside `PROBLEM.md`, and I'd
take D1 from the step 5 report with it since central is opening the file
anyway.
