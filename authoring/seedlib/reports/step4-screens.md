# Seedlib step 4: statement, artifact, and both screens

V2-PLAN §9.6, bead `tla-ngg5`, wave seat P4, agent C. Shape D: diagnose a
vacuous pass. The statement is `authoring/seedlib/statement/PROBLEM.md`, the
artifact beside it is `SeedLibrary.tla` and `SeedLibrary.cfg`. The answer key
is at `authoring/seedlib/author-notes/ANSWER-KEY.md`.

**This report is author-only.** It names the gap in plain words. Nothing under
`statement/` points here, and no blind agent should receive it.

All runs: `harness/verdict.sh -t 300`, module by absolute path,
`JAVA_TOOL_OPTIONS=-DTLA-Library=<worktree>/harness`, TLC2 Version
2026.07.31.184830.

## The freeze check

`sha256sum -c FREEZE.sha256` in `authoring/seedlib/reference/`: all three
files OK (`SeedLib.tla`, `MCSeedLib.tla`, `MCSeedLib.cfg`). The reference I
built from is the one step 3 froze.

## The artifact

V45 from the frozen matrix, rebuilt as a submission someone could believe
they wrote in good faith. Two defects, exactly the matrix's:

- **V01**: `Checkout` carries two guards where the prose names three. The
  standing guard is gone.
- **V43**: `Observe` reads `OpeningStock`, `NoDebts`, and `AllGood` on three
  of its four fields. Only `season` reads a variable.

The disguise is one move. `NoDebts` and `AllGood` are honest `Init` helpers,
and `Observe` reuses them where it should read `owed` and `standing`. It
reads as a projection drafted from `Init` and never revisited, except the
`season` field, which is the one field a still image can't fake without
`TheReckoningComes` going red (frozen matrix, V44). The module is renamed
`SeedLibrary`, single file, pilot constants at the bottom. No comments, so
nothing pre-clears anything.

Before shipping it I rebuilt literal V45 from the frozen reference
(scratch copy, same two mutations) and re-ran it: `OK`, rc=0, 335 states
generated, 90 distinct, depth 7. That matches the RESULTS-2B row figure for
figure. The shipped artifact then reproduces the same numbers.

### The green evidence, every instrument we own

| check | command | result |
|---|---|---|
| green | `verdict.sh -t 300 SeedLibrary.tla` | `OK`, rc=0 |
| counts | same run's log | 335 generated, 90 distinct, depth 7, 3 branches over 270 |
| reachable | same, `-- -inv FALSE` | `SAFETY_VIOLATION`, rc=12 |
| non-vacuous | same, `-p Gate!NonVacuous` | `OK`, rc=0 |
| vacuity probes | `vacuity.sh -t 300` | `NON_VACUOUS`, rc=0 |
| live actions | same, `-- -coverage 1` | no `total == 0`, table below |

Action coverage, distinct:total.

| action | coverage |
|---|---|
| `Init` | 1:1 |
| `Checkout` | 53:148 |
| `Return` | 0:168 |
| `Close` | 36:95 |

The totals sit above the reference's (148 vs 112, 95 vs 103 redistributed)
because the deleted guard admits more transitions, while distinct stays at
the reference's 90. `Return`'s 0:168 is the same shape as the reference's
0:188: a return lands on states the search already holds. No numeric tell
anywhere, which is the property the matrix promised and the reason V45 was
ranked first for this cell.

### The exposure instruments (answer-key side)

Both run against a scratch copy, `Probes.tla`, EXTENDS the artifact.

| probe | property | verdict |
|---|---|---|
| stillness | `[][shelf, owed, standing fields of Observe all hold]_vars` | `OK`, rc=0 |
| raw restatement | requirement 1 over raw state instead of `Observe` | `LIVENESS_VIOLATION`, rc=13 |

The stillness pass is the diagnosis in one line: a 90-state model satisfies
"the visible library never changes". The raw restatement's counterexample is
the four-state trace the answer key carries: checkout, close into default,
checkout again while in default.

## Screen 1: §5.7, mechanism collision

Run twice, because the verdict turned out to be wording-sensitive. Both runs
verbatim in the table.

| phrasing | name | mechanism | verdict |
|---|---|---|---|
| "members check out seed packets... defaulters barred from checkout" | `SeedLibrary`, 0 hits, clear | derived `allocation`, `queue`: Resource Allocator, losa_ap, BlockingQueue | **BURNED**, rc=2 |
| "members owe returns in kind... seasonal closes mark defaulters" | `SeedLibrary`, 0 hits, clear | none derived | **CLEAR**, rc=0 |

Neither run is a clean bill on its own. §9.6 says a CLEAR with no mechanism
derived means the synonym table didn't recognize the phrasing, so I name the
mechanism myself: the nearest public mechanism is the Resource Allocator,
and the seeded §2.2 suspicion table already flags library-shaped domains as
allocator dress. What separates this system from the allocator is that no
object survives the loan (the packet is consumed and the debt is met with
new goods), the ledger caps one debt per member per kind, and default is a
deadline consequence with its own standing lattice. Those are the parts the
eleven requirements actually grade.

The recall probe below says what I think the collision is worth on this task
shape. The domain cleared step 0 before the reference was written. My runs
answer whether the statement's wording kept it clear, and the honest answer
is: the checkout vocabulary collides, the debt-in-kind vocabulary doesn't,
and central should read the BURNED row before step 5 dispatches.

## Screen 2: §5.7b, the eight questions plus R

Shape D hands the learner a spec, so Q1 and Q2 are answered in their second
form, about requirements. Answers in my own words, written before anyone
else's pass.

**Q1 (spec in hand). Hand the learner the spec and the rules it's measured
against. Anything left to model?** Split answer, per the rubric's own
instruction to write both halves down. One half is a diff: the spec's
`Checkout` carries two of the prose's three guards, and any reader who holds
rule against action finds that in minutes. That half is puzzle-shaped and
can't carry the problem. The other half is the task itself: decide what the
thirteen formal claims established when they ran green. That isn't a diff
against anything. The learner has to re-derive what each check means through
the observation in hand, and then build a trace or an instrument that makes
the answer stick. **System**, on the second half.

**Q2 (spec in hand). Requirements given as formal claims, or must the
learner decide what a requirement is?** Given, and that's the trap. All
thirteen are written out, one per requirement, names matching. The learner
must decide whether the given claims say what the prose says, which is the
rubric's "which the observation vocabulary cannot carry" question inverted:
this vocabulary could carry all eleven (the frozen reference proves it), and
the submitted operator carries almost none of them. Deciding what each
requirement means over the artifact's actual observation is deciding what
the requirement is. **Decided.**

**Q3. What is asked?** Whether the evidence establishes the design's
correctness. Not goal reachability. **System.**

**Q4. Who does the work once the spec compiles?** The spec compiled, ran,
and passed before the learner arrives. TLC's search is spent. Everything
that remains is the learner's reasoning, plus one TLC run they design
themselves. **Learner models, TLC checks.**

**Q5. Where does the difficulty live?** Not state space: 90 states, seconds.
It lives in connecting a verdict to what was measured: what a box-action
property subscripted by a projection quantifies over, what an invariant
stated over that projection can see, and what remains of "no error found"
when the projection holds still. **Abstraction, of the verdict rather than
the state.**

**Q6. How many agents, and can they fail?** Two members, a librarian, and a
calendar. Members act in any order or never, crops fail silently, debts
lapse into default. **Several, fallible.**

**Q7. Delete TLC. Is there a modeling decision left to defend?** Yes. The
whole diagnosis argument stands on paper: read the checks, read the
observation, argue what the pass established. TLC only adjudicates the
demonstration. **Yes.**

**Q8. Does the statement name an optimum?** No. Grepped: no "optimal",
"minimum", "fewest", "best". **No.**

**Tally: 8 of 8 system rows.** No three-row contradiction of Q1.

**KIND: ACCEPT, system.** The statement hands over a system's rules, a
fallible cast, and a claim to refute. The one puzzle-shaped half (the guard
diff) can't complete the task, which is R's subject.

### R: the route

**The route I meant.**

1. Read the claim against the run summary. Thirteen checks, all green.
2. Ask what each check reads. Twelve of thirteen read state through
   `Observe` (`TypeOK` is the exception, and it's the weakest of the set).
3. Hold `Observe` against the statement's contract, which says every field
   is a fact about the library as it stands right now. Three fields read
   opening values, not the state.
4. Conclude what the run established: the calendar's march, the types, and
   nothing about shelf, ledger, or standing. Then say why: every requirement
   was measured against a still image of the opening day.
5. Demonstrate. Either the default-member checkout trace with the argument
   that no shipped check can reject it, or a constructed instrument (the
   stillness property, or one requirement restated over raw state).

**Probes, tiling first.**

- **Tiling**: the statement numbers 11 requirements, the `.cfg` declares 13
  checks. Every requirement maps to a named check (requirement 2 gets two,
  `ShelfFloor` and `ShelfDiscipline`, and `TypeOK` maps to none). Zero
  holes. The pilot's cheapest route is closed by construction: the
  deficiency is not a missing check, it's thirteen present ones that don't
  bite.
- **Vocabulary absence**: domain color (packet, librarian, garden, crop)
  appears 0 times in the artifact, uniformly, as the stated observation
  predicts (counts and labels only). Every load-bearing noun (season, shelf,
  owed, standing, good, default, checkout, return, close) is in the
  artifact. No `unanimity`-class hit.
- **Elimination**: all four observation fields carry declared checks. No
  field is the unconstrained odd one out. The three constant fields are
  invisible to this probe, which is the point of the cell.
- **Answer form**: the task fixes the evidence genre (a trace or a check
  with a verdict), not the target. It does presuppose there's something to
  find, which shape D's framing already gives away, and I think that's the
  cell's floor rather than a leak. It names no operator, no check, and no
  location.
- **Pre-clearing**: no "looks wrong but is fine" passage in the statement.
  The artifact has no comments at all.
- **Recall**: §5.7's checkout-phrasing BURNED against the allocator family.
  What an allocator prior hands a critic here: a sense of what a lending
  spec usually checks. That helps them ask whether these checks bite, and
  hands over nothing about this package's observation or its missing guard.
  Nothing public models a green run that means nothing, which is why this
  cell has no precedent to lean on either way.

**Shortest route found, and whether it reaches the answer.** The shortest
route to *a* defect is the prose diff: rule against `Checkout`, three guards
against two, minutes. The brief asked me to say whether that route reaches
the deadness, and the step-2 evidence says it doesn't. The same deletion
against a live observation goes red in seconds (frozen matrix V01, rc=13,
caught by `StandingGatesTheShelf`). In this package it runs green (V45,
rc=0), with the reference's own distinct count, past every instrument the
harness owns. So a learner who stops at the diff holds a defect and no
answer: the task's first question ("what did this run establish") is
untouched, and the demonstration clause ("that the shipped checks cannot
reject") forces the why-did-it-pass argument, which has no answer short of
the observation layer. The diff is an entrance, not a shortcut.

The fastest honest route to the deadness itself is reading `Observe`
directly: four lines, three of them naming opening values. I don't count
that as a bypass either. Seeing the text is quick, and the work the task
grades is what the text means: that twelve subscripted and projected checks
quantified over a still image, what survives of the green verdict, and a
demonstration built to show it. That's the judgment this column exists to
teach (the `tla-y8tb` finding, made the explicit task rather than the
accident).

**Where would a shortcut live?** In the artifact, by construction, as with
every spec-in-hand shape. No reword hides `Observe` and none should try:
this cell's difficulty is the meaning argument, not concealment.

**ROUTE: ACCEPT.** The shortest complete route runs through the judgment the
problem is for. I looked for a route that completes the task without the
observation argument and couldn't build one: tiling has no holes, the guard
diff dead-ends into the why-did-it-pass question, and the run summary is
numerically indistinguishable from the reference's.

## Statement hygiene

- Banned-word lint on `PROBLEM.md`: no em dash, no semicolon, no "vacuous",
  "frozen", or neighbors. Grep clean.
- The statement nowhere names `Observe`'s contents, load-bearing checks, or
  the guard. The observation section restates the HANDOFF contract only.
- Delivery set for a blind agent: `PROBLEM.md`, `SeedLibrary.tla`,
  `SeedLibrary.cfg`. Author-only outputs: this report and the answer key,
  both outside `statement/`.
