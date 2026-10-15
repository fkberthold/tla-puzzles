# AUDIT: the telegraph ruling applied to all 64 drill prompts

Bead `tla-3hwj`, read against the ruling recorded on `tla-0yis`. One reader,
2026-10-15, tree at `680d3e2`. No `PROMPT.md` was edited.

## The test, and how it was applied

The ruling's test is one question per item: does removing the sentence
leave the item underdetermined? Keep it if the prompt cannot pose its
problem or publish a reproducible count without it. Cut it if the reader
could have reached the answer from the rest and the sentence only shortens
the search.

To apply one threshold 64 times I sorted every candidate sentence into one
of four bins before ruling on it.

1. A domain fact the problem can't be posed without. PASS. (`sets/01`,
   "Which one is not specified.")
2. A constraint on the answer's shape. PASS, the `modules/06` precedent.
   (`core/06`, "one definition that serves both styles".)
3. A published outcome that forecloses without explaining: a count, a
   verdict, an error text. PASS, the ruling's Q3. (`control-state/03`,
   "The first thing TLC says will be about the end of the day.")
4. A sentence that names the discovery, the direction of the conclusion,
   or the location or shape of the fix, where the item has another
   foothold or the reader would find it by running. FAIL.

For closing questions, which is where most candidates live, the
discriminator was whether the wording carries the direction of the
conclusion. "Whether anything needed recording beyond the two switches"
carries it, since the answer is nothing. "Whether the count of reds could
have stood in for it" does not, since the honest answer is no and the
wording leans the other way. "How many things, and why that many" is open.

Severity. FAIL-clear when the sentence is the construct's whole role with
only the keyword removed, which is the `modules/07` shape central cut.
FAIL-mild when it names direction, location or shape and leaves the
construct to find.

Every verdict cites the sentence. Where an `ANSWER.md` author flagged the
same sentence as the item's caveat I say so, since that is evidence the
shape was seen and kept on purpose, and it bears on the remedy.

## Where the candidates came from

Every `PROMPT.md`, every `META.md` (which names each item's lesson), and
every `ANSWER.md`'s "why not in prompt" section. Commands: `for f in
drill/<family>/*/PROMPT.md; do cat "$f"; done` per family, the same for
`META.md`, and `command grep -i -A 30 'why.not.in.prompt'
drill/<family>/*/ANSWER.md`. Verify counts are from the `META.md` tables
where they carry them (core, sets, sequences) and from the `ANSWER.md`
measured tables otherwise. Nothing was re-run.

---

## core

### core/01-box-office: PASS
- Sentence: "the house wants each written down as a rule of its own, since
  other windows reuse them separately" and "A booking is both at once, in
  one step."
- Test: bin 2. Without it the reader writes `Book` inline and never meets
  the two-conjuncts trap, which the author says at `ANSWER.md:139`. The 4
  is published and is the foreclosing row.

### core/02-vending-unchanged: PASS
- Sentence: none. The prompt is domain plus a count.
- Test: nothing names the forgotten variable. The 12 forecloses
  `TypedNextSilent` at 36 (`META.md` verify table).

### core/03-bakery-obligations: PASS
- Sentence: "The owner has three worries:" with a numbered list, and "Then
  break it. ... read what TLC reports. The answer says what it should
  report."
- Test: three numbered worries nudge three names (author, `ANSWER.md:173`),
  but the lesson lands in the break-it step when a bundled `Safe` can't say
  which worry broke. Nothing says to name them separately. The verdict is
  withheld.

### core/04-lift-types: PASS
- Sentence: none beyond the table. "floors below ground" and the row at -2
  are the domain.
- Test: the -2 row forecloses `Nat`. The config's missing negative literal
  is withheld.

### core/05-pelican-case: PASS
- Sentence: none. "Say what every variable can be" is the family's standard
  line.
- Test: the cycle table poses it. `CASE` is neither forced nor named.

### core/06-can-pyramid: PASS, marginal
- Sentence: "Write 'what the style says' as one definition that serves both
  styles, given a style's rule for a row and the number of rows."
- Test: bin 2. Without it the closed forms pass at the same 10
  (`ClosedForms`, rc 0, 10) and nothing forces the higher-order parameter.
  It is the item's problem statement, the same shape as `modules/06`.
  Marginal because "given a style's rule for a row" describes the
  parameter's kind.

### core/07-prime-capacity: PASS
- Sentence: "Define what a prime is yourself."
- Test: bin 2. A task statement. The author notes the universal is forced
  only by that sentence (`ANSWER.md:118`), which is what a constraint does.

### core/08-altimeter-approx: PASS, marginal
- Sentence: "Define 'in agreement' as something you can write between two
  readings, the way you'd write a comparison."
- Test: bin 2. A prefix `Agree(a, b)` passes at 49 and the sentence is what
  rules it out. Same shape as `core/06`. "If and only if" is the domain
  rule, not a hint.

## control-state

### control-state/01-slip-on-the-spike: PASS, marginal
- Sentence: "Say in one sentence what changed in the model and why that
  changed the verdict."
- Test: "why that changed the verdict" presupposes the second run's verdict
  differs from the first. That is a published outcome, bin 3, the same
  category as a count. The reader has run both before answering. Nothing
  says what the control point is or that it is the cause. Marginal because
  the author's caveat claims the prompt withholds "the verdict under
  either" (`ANSWER.md`, why-not-in-prompt), and this clause does not quite.

### control-state/02-pumps: FAIL-mild
- Sentence: "and whether anything about the pump needed recording beyond
  the position of its two switches."
- Test: carries the direction. The answer is nothing, and a reader who has
  the sentence before writing models two switches per pump and skips the
  label detour. The author says so: "points straight at the answer being
  'nothing'" (`ANSWER.md:139`). The first half of the question, "what in
  your model records where in the handbook procedure each pump is", poses
  the reflection on its own.
- Remedy: `verify/` holds a wrong-but-clean neighbor with a different
  count. `Switches` rc 0 at 26, `Phases` rc 0 at 63 (`ANSWER.md` measured
  runs). Two costs to name before publishing 26. `Phases` is over-built
  rather than wrong, so a count brands a defensible encoding. And this
  family withholds counts by design, four prompts say "Report the verdict
  and the number of distinct states", so publishing one here is a
  family-level change. The cheaper edit is to keep the first half of the
  question and cut the clause.

### control-state/03-two-tools: FAIL-mild
- Sentence: "Report what TLC says, and whether the way you dealt with the
  end of the day had anything to do with what it said."
- Test: the second clause is the lesson as a question, which the author
  says in those words (`ANSWER.md:162`). It tells the reader the deadlock
  treatment and the second verdict are connected, before the second run.
  "The first thing TLC says will be about the end of the day" is bin 3 and
  stays. "Say which of the ways of dealing with it you chose" is the
  `modules/03` category shape and stays.
- Remedy: no wrong-but-clean neighbor with a comparable count.
  `RookieNoDL` is wrong and clean at rc 0, 13 states. The right treatment
  on the new hire is `NewHire` at rc 11, 7 states, which is not clean, so
  the counts are not comparing like with like (`ANSWER.md` measured runs).
  The foreclosure available is the verdict: publishing that a correct
  treatment reports a stuck state on the second run would catch
  `CHECK_DEADLOCK FALSE` without naming it. Without that, the clause is the
  only foothold for the reader who wrote the forgiving config by reflex.
  Leave it unless the verdict is published.

### control-state/04-night-patrol: FAIL-mild
- Sentence: "and whether it belongs in the statement that the guard never
  stops for good."
- Test: names the location of the fix, the fairness tuple. The author:
  "points at the fairness tuple specifically" (`ANSWER.md:126`). The reader
  who slipped already has the lasso and the instruction "say at which state
  the guard stopped and what the guard was able to do there", which is the
  diagnosis. Finding that the tuple is why fairness did not force `Walk` is
  the item, and the clause hands over where to look. The first half,
  "whether it belongs in your specification's state at all", poses the
  reflection.
- Remedy: no count neighbor. `SlipTuple` rc 13 at 8, `Patrol` rc 0 at 8,
  same count (`ANSWER.md` measured runs). The verdict forecloses and the
  prompt already anticipates it ("If TLC reports a counter-example"). Cut
  the clause, keep the first half.

### control-state/05-crane-and-riggers: PASS, marginal
- Sentence: "Then say how many things in your model record where someone is
  in their own procedure, and why that many."
- Test: open on the number and on the reason. "their own procedure" leans
  toward per-process, which the author flags (`ANSWER.md:151`), but it is
  also how the riggers and the crane were described. The table's first row
  forecloses the site-wide phase. If Frank wants a count route,
  `SitePhase` is wrong and clean at rc 0, 3 states against `Crane` at 12,
  with the same family-convention cost as `control-state/02`.

### control-state/06-three-reds: PASS, marginal
- Sentence: "and whether the count of reds could have stood in for it."
- Test: open. The honest answer is no, and the wording leans toward yes, so
  it does not carry the direction. The author reads it as saying "it is not
  the count" (`ANSWER.md:144`). I read it the other way, and record the
  difference.

### control-state/07-donor-session: FAIL-mild
- Sentence: "If you found yourself writing the same two lines in each of
  them, say what you did about it."
- Test: names the smell and presupposes a fix. The author: "all but names
  the helper" (`ANSWER.md:135`). Without it the reader writes six actions
  and the item is fully determined at 199. The sentence is not a
  constraint, it is a conditional nudge, and the author says that is
  deliberate: "the prompt says so by asking rather than requiring".
- Remedy: no neighbor. The helper and no-helper specs explore the same 199
  states and nothing TLC checks tells them apart. Two options. Leave it,
  since it is the only foothold and the author argues the style retrieval
  should be asked. Or convert it to a constraint in the `modules/06` shape,
  "Write the move from one step of the visit to the next once, and use it
  in every action", which passes the ruling and forces the construct.
  Leaving it is defensible.

### control-state/08-wrong-label: PASS
- Sentence: "with one label per step of the visit".
- Test: bin 1. A diagnosis of a label bug cannot be posed without saying
  the spec has labels. The trace is the problem. The author's caveat is
  that the trace's second row is most of the diagnosis, which is the item's
  shape rather than a leak.

## state-space

This family is a guided investigation: a measured table and numbered
questions. The questions are the task, so most of what reads as
mechanism-in-English is bin 1. I looked for sentences inside questions that
name a mechanism rather than pose a task.

### state-space/01-clock-never-stops: FAIL-mild, low confidence
- Sentence: "Say what the supervisor reads to make its decision."
- Test: Q3's second sentence, "Is there a model where nothing needs
  capping?", poses the question. The first sentence points at the gap, and
  the gap is already named in the system description ("Once the gap since
  the last beat is longer than a fixed timeout"). So the reader could reach
  it from the rest. The author kept it so Q3 does not read as "find a
  trick" (`ANSWER.md:143`). Q2's "There are two places to put that cap" is
  the `modules/03` category shape and passes.
- Remedy: the neighbor question is moot. Both the capped clock (237 at cap
  12) and the gap model (`G01Gap`, rc 0, 9, `ANSWER.md:127`) are clean and
  both are what the prompt asks for. I would leave it, on the author's
  reason. Low confidence that it fails at all, since "what the supervisor
  reads" restates a domain fact.

### state-space/02-four-identical-workers: PASS, marginal
- Sentence: "There's a knob for this shape, and this system meets its
  condition to the letter. Name it. Two things have to be true, one of the
  model and one of the requirement, before TLC's answer under it can be
  trusted. Name both."
- Test: bin 1 with a hard edge. "Interchangeable" and "nothing about any
  worker differs" is the symmetry condition in prose and the author could
  not describe the system without it (`ANSWER.md:131`). "Two things ... one
  of the model and one of the requirement" tells the reader how many
  conditions and where each lives. It poses Q2, which is the item, and
  without it "Name it" alone would not drill the conditions. Marginal.

### state-space/03-view-hides-the-bug: PASS
- Sentence: "There's a way to say that to TLC. I said it for B." and "State
  the condition under which hiding a variable is safe".
- Test: bin 1. The mechanism exists unnamed, and the counts (3 at depth 2
  for a bug at depth 8) do the arguing. "Never read" against "counted" is
  the condition in prose and is the one fact the two clients must differ
  on.

### state-space/04-clean-run-colleague-deadlock: PASS, marginal
- Sentence: "You can settle this by running the same pair six ways."
- Test: a method hint, the shape of the answer table (author,
  `ANSWER.md:124`). It does not name the flag or the keyword and only helps
  a reader who already has both. Q3's "two ways ... One throws away the
  check. The other keeps it." is category-naming and poses the task.

### state-space/05-summary-record: PASS
- Sentence: "The error says TLC expected a boolean value and didn't find
  one."
- Test: bin 3, the ruling's Q3 exactly. Q1 lists four roles for four
  keywords and is the task. The row labels name what was done, and four
  unlabeled rows would be a guessing game (author).

### state-space/06-liveness-at-the-fence: FAIL-mild
- Sentence: "Think about what TLC does with a state it isn't allowed to
  expand, and what the fairness assumptions say about that state."
- Test: names the mechanism. The first sentence of Q1, "Say what, in the
  cut model, that verdict is resting on", poses it. The pointer hands over
  that the cut state's non-expansion and the fairness assumptions are where
  the answer lives. The author: "points at the mechanism. This is the cold
  item, so I kept that pointer short" (`ANSWER.md:119`).
- Remedy: no count neighbor. Every cut row is 10 states and the whole table
  is clean-or-13 at 10 (`ANSWER.md` whole table). The foreclosure is "Would
  you ship the clean verdict in row two?", which already signals doubt. Cut
  the pointer sentence, or shorten it to its first clause. This is the item
  the author calls cold, so a reader without the pointer may run long.
  Hard case.

### state-space/07-sentinel-and-the-roster: PASS, marginal
- Sentence: "Rows three and four were refused by something in the module,
  not the config. Write it, then take it out and run row three again."
- Test: "Write it" is the task, and the task needs a location. "Something
  in the module" narrows to a module construct without naming it. "say why
  it's worse than exit 10" presupposes the no-guard run is worse, which is
  bin 3. "The nurses' names don't matter" and "a maximum of zero is
  nonsense" are bin 1.

### state-space/08-the-database-you-did-not-need: PASS
- Sentence: "State snapshot isolation as two rules a transaction obeys, in
  prose, without mentioning versions or timestamps."
- Test: bin 2. The author calls it "a strong hint about what to delete" and
  kept it because without it the reader writes a smaller mechanism rather
  than none (`ANSWER.md:157`). The colleague's row already says the answer
  has no database in it, so the direction is in the table and the
  constraint is what makes Q3 the right task. Q2's "cross off" procedure is
  a task whose doing is the lesson.

## sets

All eight pass, and the rate is real rather than lenient. This family poses
with break-it steps and published counts instead of closing questions, and
every author withheld the construct's name on purpose.

### sets/01-any-healthy-upstream: PASS
- Sentence: "Which one is not specified." and "The answer says what TLC
  should report for the claim."
- Test: bin 1, the existential in prose, which the author names at
  `ANSWER.md:160`. The verdict on the claim is withheld. The 398 forecloses
  `LbChoose` at 189.

### sets/02-two-pools: PASS
- Sentence: "one of the four is a trainee who qualified last month" and
  rule 3.
- Test: bin 1. A rule about a named member is what forces who over how
  many. The 49 forecloses `PoolsCounts` at 9.

### sets/03-ballast: PASS
- Sentence: "which can be any arrangement that obeys the rule."
- Test: bin 1, the powerset in prose with the word "subset" withheld. The
  break-it step is where the draw's location lands.

### sets/04-convoys: PASS
- Sentence: "Two groups of trucks on the road can join up and carry on as
  one group."
- Test: bin 1. Neither union is named. Rule 1's "no truck is in two groups
  at once" is what forces the flattening.

### sets/05-leases: PASS
- Sentence: none. "Then take out the check that the resource is free before
  granting" is the break-it step.
- Test: neither brace form is on the page. The 61 forecloses both traps
  (343 and 64).

### sets/06-port-rules: PASS
- Sentence: "A port is open when any rule covers it."
- Test: bin 1, the flattening in prose, "union" withheld.

### sets/07-which-pub: PASS
- Sentence: "Count the votes in it before you read anything else."
- Test: a reading instruction for the break-it trace. The author considered
  naming the vote count and chose not to because it would say what is under
  test (`ANSWER.md:174`). The sentence names where to look, not what to
  find.

### sets/08-the-dive: PASS
- Sentence: "Only when every diver has checked in may anyone go down".
- Test: bin 1, "subset" withheld. The 321 forecloses `DiveWeakRule` at 625.

## temporal

### temporal/01-print-job: PASS
- Sentence: "One line for the property."
- Test: bin 2. Six rows and no operator.

### temporal/02-heartbeat: PASS
- Sentence: "A heartbeat counts as received when the stored number changes."
- Test: bin 1. It is what makes row 4 allowed and the answer an action.

### temporal/03-commit-sticks: PASS
- Sentence: "can a finite prefix of a behavior refute your property?"
- Test: asks the safety question without answering it.

### temporal/04-revision-freeze: PASS
- Sentence: none. Five rules and ten rows.

### temporal/05-flaky-link: PASS
- Sentence: "Nothing in the system can hold it up or bring it back."
- Test: bin 1. L2 does the foreclosing on its own (author).

### temporal/06-help-desk: PASS
- Sentence: "The specifier has decided what the clerk owes a waiting
  customer, and no more."
- Test: domain framing. L2 being allowed is what kills strong fairness, and
  it is a row.

### temporal/07-pipeline-halt: PASS, marginal
- Sentence: "Write that requirement as something TLC can check, without
  restating any stage's rules."
- Test: bin 2, and the strongest constraint in the corpus. The hand-written
  guard is the same predicate on this system and no run separates it from
  the answer (author, `ANSWER.md:85`), so without the constraint the item
  is underdetermined as a drill of `ENABLED`. The author ranks this item
  last in its family on telegraphing and keeps it because nothing else
  reaches the construct. "Then name the built-in TLC check it replaces"
  poses a question whose answer most readers reach.

### temporal/08-turnstile-clock: FAIL-mild
- Sentence: "The clock isn't the turnstile's business: the specification
  constrains the count and says nothing about the clock."
- Test: the clause after the colon is the subscript choice in English. The
  table determines the formula on its own: S2 kills `_<<count, clock>>`
  with the by-one action, S5 kills the enumerated-clock disjunction
  (`ANSWER.md` elimination table). The post-run question "why S2 is allowed
  under your formula" is where the reader explains the subscript. The
  author: "with it a reader who knows the subscript rule is most of the way
  there", kept so S2 does not look like a typo (`ANSWER.md:86`).
- Remedy: no count, this family has none. The rows foreclose. Cut the
  clause after the colon and keep "A wall clock beside it ticks. The clock
  isn't the turnstile's business." as the domain framing that motivates S2.
  That keeps the author's reason and drops the lesson statement. Hard
  case, because the remaining half-sentence still leans.

## sequences

### sequences/01-triage-board: FAIL-mild, the held-back item
- Sentence: "Say how you stopped the treated list growing without bound."
- Test: tells the reader the treated list grows without bound, which is the
  `CONSTRAINT` lesson, before anything has run. The reader discovers
  unbounded growth by running, since the run never ends. Central's note on
  `tla-3hwj` reached the same verdict.
- Remedy: no wrong-but-clean neighbor in `verify/` with a different count.
  The listing is `TriageRef` (rc 0, 7225), `TriageRefAdmits`, `TriageFifo`
  (rc 13), `TriageFifoAdmits`, `TriageSelect` (rc 0, 7225),
  `TriageSelectAdmits` (rc 13), `TriageRows` (`ls
  drill/sequences/01-triage-board/verify`, counts from `META.md`).
  `TriageSelect` is clean at the same 7225 and is foreclosed by its Admits
  run, not by a count. The `sequences/07` pattern is still available:
  `TriageRef.cfg` bounds with `CONSTRAINT TreatedBound`, so the prompt can
  state the bound ("stop the model once the treated list holds N") and
  publish 7225, with "Say how you held it there" kept, as `07` did. What
  that forecloses is unmeasured: the natural wrong-but-clean neighbor is a
  guard on the doctor instead of a constraint, which changes the reachable
  set and should come in at a different count. Measure that neighbor before
  publishing, since the count is only worth publishing if it catches
  something. Until then, cutting the sentence is safe for the reader's
  foothold, because the unbounded run is its own foothold.

### sequences/02-floor-robot: PASS
- Sentence: none beyond "in order" and "three rows of three", which nudge
  the shape (author).
- Test: the off-by-one is not nudged. The 653 forecloses `RobotFromStart`
  at 34.

### sequences/03-returns-desk: ALREADY-JUDGED, FAIL, forecloses nothing
- Sentence: "A colleague who wrote the same library found a different
  number of distinct states, and both of you are right. Say what the two of
  you chose differently, and which choice made the rule harder to break."
- Remedy: no wrong-but-clean neighbor. `DeskSeq` 38, `DeskSet` 27,
  `DeskFun` 27, all rc 0 and all correct (`META.md` verify table). A
  published count would brand two right answers wrong, which is the
  opposite of what the pattern is for. The sentence is also the only thing
  that makes the reader write a second encoding. Leave it, or restructure
  the item so the comparison is the task rather than a hint. Not re-ruled.

### sequences/04-deck-log: PASS
- Sentence: "Say what bounds the model."
- Test: open on whether it is a guard or a constraint (author). The bound
  is the five entries, which is domain. "In one go, still in order" is bin
  1 and is what the table's row 4 shows. One of the three named as unseen
  on `tla-0yis`, and I find nothing in it that fails.

### sequences/05-undo-history: PASS
- Sentence: none. Two sentences and a table.
- Test: rows 4 and 5 carry the semantics. No count is published and the
  Admits runs foreclose.

### sequences/06-dispatch-board: PASS
- Sentence: "the dispatcher strikes every call from that district off the
  board at once, and the calls that remain keep their order."
- Test: bin 1, close to a definition of a filter (author) but the
  direction of the test is withheld. The 98 forecloses both wrong
  neighbors.

### sequences/07-pneumatic-tube: ALREADY-JUDGED, FIXED in `c3d6342`
- Current text: "Keep to the two colors and stop the model once four
  capsules have gone in. Say how you held it there." plus the published
  129. Reads clean. Not re-ruled.

### sequences/08-pancake-pile: PASS, marginal
- Sentence: "Say how you built the flip."
- Test: "built" hints it was not called (author, `ANSWER.md:120`), which is
  the only lean. The author kept it so a reader who knows a community
  `Reverse` does not skip the point. The function literal is not named and
  the table carries the semantics. One of the three named as unseen, and
  marginal rather than failing.

## functions-records

### functions-records/01-shunting-yard: PASS
- Sentence: "what the checker would do if the line that says where the day
  starts and the line that says what the variable can be swapped their
  shapes."
- Test: not a telegraph. The reference uses the function set in both lines
  (`ANSWER.md:48`, "The set is the one you want in both lines"), so the
  question's premise that the two lines have different shapes does not
  match the answer. The author's own worry is that most readers will find
  only the readable swap. That is a loose question, which is a different
  defect, and I flag it as a discrepancy rather than a verdict.

### functions-records/02-charging-bays: FAIL-mild
- Sentence: "and which one your choice of state made impossible to break."
- Test: carries the direction. It says one of the two rules is
  structurally free, which is the lesson, and the author says so, "the
  lesson said sideways" (`ANSWER.md:184`). The item is fully determined
  without it at 37. The first half, "which of the two rules you had to
  write down as a property", presupposes the same thing, so cutting one
  half does not close it.
- Remedy: no wrong-but-clean neighbor with a different count. All four
  layouts, including keeping both sides, land on 37 at rc 0 (`ANSWER.md`
  measured runs). A count forecloses nothing. The open form is "Then say,
  for each rule, whether your model could have broken it, and why", which
  keeps the reflection and drops the presupposition. Or leave it, on the
  author's post-run defense.

### functions-records/03-ballast-tanks: PASS
- Sentence: "The gauges are read together, as one reading of all three
  tanks."
- Test: bin 2, the atomicity and the one-function state. The rows carry the
  rule.

### functions-records/04-autoclaves: PASS, marginal
- Sentence: "what the step that raises one autoclave's pressure has to say
  about that autoclave's door, and what it has to say about the other two
  autoclaves."
- Test: open. A reader with three variables answers "leave them unchanged"
  and a reader with one function answers "nothing", and both are right. The
  author calls it the copies-the-rest lesson asked as a question
  (`ANSWER.md:139`), and it is, but the wording does not carry which
  answer. Cited on `tla-0yis` as an instance of the shape. Marginal.

### functions-records/05-tool-crib: FAIL-mild
- Sentence: "and what happens to that set when a tool comes back."
- Test: carries the direction. "What happens to that set" presupposes the
  set is a thing in the model that changes, which is the domain-as-state
  reading. The author: "points at the domain being state"
  (`ANSWER.md:146`). The first half, "what the set of tools that are out
  looks like in your model", is open and poses the reflection. One of the
  three named as unseen on `tla-0yis`.
- Remedy: no wrong-but-clean neighbor with a different count. Partial,
  total-with-hole and by-worker all land on 63 at rc 0 (`ANSWER.md`
  measured runs). The author argues the total layout is legitimate and a
  drill should not force a shape. Keep the first half, cut the clause.

### functions-records/06-depot-cover: ALREADY-JUDGED, PASS
- Not re-ruled. The merge's meaning is the roster's definition.

### functions-records/07-stock-board: PASS, marginal
- Sentence: "how your model reads the cell for ivy's promised count, and in
  another how it writes it."
- Test: open. Points at access paths (author) without saying the write
  mirrors the read. All three layouts are 216 and the crossed-path message
  is what the reader doesn't have.

### functions-records/08-troughs: PASS
- Sentence: "with the number of troughs as a parameter" and the second
  count.
- Test: bin 2 plus bin 3. The 168 at four is what forecloses the
  hand-written sum, which passes at three with the same 81.

## modules

The ruling gives this family no exemption, and the per-item test lands
harder here than anywhere else because the constructs resist description.
Four of the five unjudged items fail, all mild except one, and each has a
refusal row in its own table that forecloses the wrong answer, so each can
lose its leak without losing the reader's foothold.

### modules/01-two-tanks-one-hose: FAIL-mild
- Sentence: "Each copy of the tank has to be told which capacity it has and
  which variable of the pair it lives in."
- Test: "which variable of the pair it lives in" is the variable
  substitution, the half of K104 the item is about (`META.md`). Q3 poses
  that discovery, "The tank module declares one thing that isn't a
  constant. What happens to it when the pair doesn't say where it goes?",
  and row six's refusal, "something the tank declares was never
  substituted", forecloses skipping it. So Q1's clause pre-answers Q3. The
  author reads the sentence as following from "shared" and "nothing written
  twice" (`ANSWER.md:216`), which is fair, and it still names the shape
  before the row delivers it.
- Remedy: no count needed. Row six is a refusal (`G01NoVar`, rc 150,
  `ANSWER.md` whole table) and forecloses. Cut "and which variable of the
  pair it lives in", or the whole sentence, and let row six and Q3 carry
  it. Moderate confidence, since the sentence also reads as a requirement.

### modules/02-signal-and-the-ticker: FAIL-mild, low confidence
- Sentence: "Write the line that ties the two, the definition TLC can name,
  and the config line that names it."
- Test: "the definition TLC can name" is the shape of the fix for row five,
  "the config naming the instance's formula directly | refused". Q5 poses
  it, "what can and can't a config name?", and row five forecloses the
  direct form. A reader without those four words tries the direct form,
  hits row five, and finds the named definition, which is what the row is
  for. The earlier "TLC can check that claim if you tell it how to read the
  count as a color and which keyword in the config asks for the check" is
  bin 1 and the author could not pose refinement without it.
- Remedy: no count needed. Row five is a refusal (rc 151, `ANSWER.md`
  whole table). Reword Q2 to "Write the line that ties the two, and the
  config line that asks for the check." Low confidence because this is four
  words inside the task statement in the family where the task is hardest
  to state.

### modules/03-the-bank-that-vouched: ALREADY-JUDGED, PASS marginal, re-read as asked
- Sentence: "and which of the two ways of bringing a module in would have
  kept it?"
- Re-read: "would have kept it" presupposes that the other way keeps the
  guard, and rows two and four show only that something was lost. The
  author's own caveat says the same: "question 2 all but says one keyword
  keeps the guard and the other loses it, so the retrieval is which is
  which rather than whether" (`ANSWER.md:156`). I would have put this at
  FAIL-mild on that clause, with Q4's "Write the one line in the office
  that makes row four refuse" as the surviving foothold. Recorded as a
  difference from central's reading. Not re-ruled.

### modules/04-the-berth-and-the-phantom-ship: FAIL-mild
- Sentence: "Which file does the permutation set live in, and why can't it
  live in the dock?"
- Test: "the permutation set" is a near-name for the operator the reader
  has to find. Row six, "told they're interchangeable", is the mechanism in
  prose and is bin 1. Q1 adds the operator's name in all but spelling. A
  reader who has "interchangeable" and a 13-to-4 drop in the table has what
  the drill is testing, and "permutation set" shortens the search for the
  keyword. The author lists "that permutations come from the TLC module" as
  withheld (`ANSWER.md:153`), and "permutation" is on the page.
- Remedy: row six's count forecloses, `Three.cfg` 13 against
  `ThreeSym.cfg` 4 (`ANSWER.md` whole table). Reword Q1 to "Which file does
  row six's line live in, and why can't it live in the dock?" Q2's
  "refused by a line in the dock. Write it." is the same task shape as
  `state-space/07` and passes.

### modules/05-the-helper-that-leaked: FAIL-clear
- Sentence: "and what are the two marks, on two different lines of the
  helper, that stop each one traveling?"
- Test: this is the construct with the keyword removed. A mark, on a
  definition and on an import, that stops a name being exported. The author
  says it in as many words: "tells the reader the fix is one word in two
  places, so the retrieval is the word and not the shape"
  (`ANSWER.md:160`). That is the `modules/07` shape central cut as clear, a
  construct's whole role described with only its spelling withheld. The
  first half of Q2, "Where did it come from", poses the harder puzzle on
  its own. "Keeps a private tooth count" is bin 2 and stays.
- Remedy: row two is a refusal (rc 150, `ANSWER.md` whole table) and
  forecloses the leak. Row four says the conveyor-side fix in prose,
  "bringing it in under a name instead". Reword Q2's second half to "and
  what stops each one traveling?" The reader who gets row two's refusal
  then has to find that the fix is a modifier and where it goes, which is
  the retrieval.

### modules/06-two-chutes-one-gate: ALREADY-JUDGED, PASS
- Not re-ruled. "Neither rule gets a definition of its own" is bin 2, and
  "arity 1" is bin 3.

### modules/07-the-hoist-and-the-crates: ALREADY-JUDGED, FIXED in `60215ed` and `b748d21`
- Current text reads clean. Q3's "There's a second way to write the sum
  that doesn't need that line at all" names that an alternative exists,
  which is the `modules/03` category shape. Not re-ruled.

### modules/08-doors-of-the-hall: ALREADY-JUDGED, FAIL mild
- Sentence: "and what does the instance have to become so it can be filled
  later?"
- Remedy: row three is a refusal (rc 150, `ANSWER.md` whole table) and
  forecloses the top-of-file placement. Cut the clause and keep "Why can't
  the width be filled there". Not re-ruled.

---

## Summary

### By verdict

| verdict | count | notes |
|---|---|---|
| PASS | 46 | 13 of them marginal |
| FAIL-mild | 15 | 13 new, plus `sequences/03` and `modules/08` already judged |
| FAIL-clear | 1 | `modules/05` |
| FIXED | 2 | `sequences/07`, `modules/07` |

The 13 new FAIL-mild: `control-state/02`, `03`, `04`, `07`,
`state-space/01`, `06`, `temporal/08`, `sequences/01`,
`functions-records/02`, `05`, `modules/01`, `02`, `04`.

The 13 marginal PASS: `core/06`, `08`, `control-state/01`, `05`, `06`,
`state-space/02`, `04`, `07`, `temporal/07`, `sequences/08`,
`functions-records/04`, `07`, `modules/03`.

### By family

| family | PASS | FAIL-mild | FAIL-clear | FIXED |
|---|---|---|---|---|
| core | 8 | 0 | 0 | 0 |
| control-state | 4 | 4 | 0 | 0 |
| state-space | 6 | 2 | 0 | 0 |
| sets | 8 | 0 | 0 | 0 |
| temporal | 7 | 1 | 0 | 0 |
| sequences | 5 | 2 | 0 | 1 |
| functions-records | 6 | 2 | 0 | 0 |
| modules | 2 | 4 | 1 | 1 |

The rate is 16 of 64, a quarter. The brief expected something nearer half,
on the strength of three workers finding "the shape" in roughly half of
their items. Both numbers are right about different things. The shape, a
closing question that states the lesson in English, is common. The
ruling's test fails only the questions whose wording carries the
direction of the conclusion, and passes the open ones. The shape
concentrates in `control-state`, `functions-records` and `modules`, where
the closing question is the family's device for drilling a choice TLC
cannot see. `core` and `sets` pose with counts and break-it steps and are
clean.

### Fix first

Ordered by how clean the remedy is. In the first six a foreclosing row
already exists, so the cut costs the reader nothing.

1. `modules/05`. Clear, and row two forecloses. Reword "the two marks, on
   two different lines of the helper" to "what stops each one traveling".
2. `modules/08`. Already ruled, row three forecloses. Cut the second half
   of Q2.
3. `modules/04`. Row six's count forecloses. Replace "the permutation set"
   with "row six's line".
4. `control-state/04`. The verdict forecloses and the prompt anticipates
   it. Cut "and whether it belongs in the statement that the guard never
   stops for good".
5. `modules/01`. Row six forecloses. Cut "and which variable of the pair
   it lives in".
6. `temporal/08`. S2 and S5 foreclose. Cut the clause after the colon.
7. `sequences/01`. The held-back item. Apply the `07` pattern once a
   guard-bounded neighbor has been measured, so that 7225 catches
   something.
8. `functions-records/05` and `functions-records/02`. Keep the first half
   of each closing question. No count route.
9. `modules/02`. Reword Q2 to drop "the definition TLC can name". Low
   confidence it needs it.

Leave, with the reason recorded:

- `control-state/02` and `control-state/07`: the question is the only
  foothold, and the count route needs a family-level decision on whether
  this family publishes counts at all.
- `control-state/03`: leave unless the second run's verdict is published.
- `state-space/06`: cold item, the pointer is short, and cutting it may
  push the item past ten minutes. Frank's call.
- `state-space/01`: low confidence it fails. Leave on the author's reason.
- `sequences/03`: all three encodings are right, so no count can
  foreclose. Leave or restructure.

### Confidence, and the hard cases

High confidence: every `core` and `sets` row, `temporal/01` through `06`,
`sequences/02`, `05`, `06`, `functions-records/03`, `08`,
`control-state/08`, `state-space/03`, `05`, and the rows marked
ALREADY-JUDGED that I did not re-rule.

Moderate confidence: `control-state/02`, `03`, `04`, `07`, `modules/01`,
`04`, `05`, `functions-records/02`, `05`, `temporal/08`, `sequences/01`.

The hard cases, where a different reader applying the same test could land
the other way:

- `modules/02`, "the definition TLC can name". Four words inside the task
  statement, in the family where the task is hardest to state. FAIL-mild
  at low confidence.
- `state-space/01`, "Say what the supervisor reads". The gap is already
  named in the system description, so the sentence restates a domain fact
  and also points at the answer. FAIL-mild at low confidence, and I would
  leave it.
- `state-space/06`, the "Think about..." pointer. Fails the letter of the
  test, and the author built the item cold on purpose. Whether a short
  mechanism pointer on a cold item is a telegraph or a scaffold is a
  judgment the ruling does not settle.
- `control-state/06` and `functions-records/04`. The authors read their
  own closing questions as stating the lesson. I read both as open because
  the wording does not carry the direction. If Frank reads them as the
  authors do, both move to FAIL-mild and the `control-state` and
  `functions-records` counts each rise by one.
- `temporal/07`, "without restating any stage's rules". Passes as a
  constraint, and it is the strongest constraint in the corpus. If a
  constraint can be so tight that it names the construct, this is where
  the line is.
- `modules/03`. Central's PASS marginal against my re-read, recorded
  above.
- `core/06`, `core/08`, `control-state/07`. Constraints or
  near-constraints. The ruling's `modules/06` precedent passes a
  constraint on the answer, and the difference between "write it as one
  definition" and "if you found yourself writing the same two lines, say
  what you did" is whether it is required or invited. I passed the
  required ones and failed the invited one.

### Discrepancies with the brief and the beads

- The brief said to expect "a real rate rather than a handful". The rate
  under the ruling's test is 16 of 64. See "By family" for why the shape
  count and the failure count differ.
- `control-state/01`'s author caveat says the prompt withholds "the
  verdict under either", and "why that changed the verdict" does not
  withhold that they differ. Bin 3 rather than a leak, but the caveat
  overstates.
- `functions-records/01`'s closing question presupposes the two lines have
  different shapes, and the reference uses the same shape in both
  (`ANSWER.md:48`). Not a telegraph. A loose premise that the item's author
  also worries about.
- Four `control-state` prompts (`02`, `05`, `06`, `07`) withhold the count
  and ask the reader to report it. Every count-based remedy in this family
  runs into that convention, and the bead's remedy pattern assumes a count
  can be published. That is a family-level decision the audit cannot make.

### What this file does not do

No `PROMPT.md` was edited. No count was re-measured. Every count cited is
from a `META.md` or `ANSWER.md` table in the tree at `680d3e2`. The remedy
rows say what `verify/` holds, not what a new neighbor would come in at.
