---------------------------- MODULE AssayOffice ----------------------------
\* The assay-office reference, commented after the freeze. The spec text is
\* the frozen AssayOffice.tla byte for byte, and harness/comment-gate.sh
\* checks that claim rather than trusting it. Comments are the only addition.
\*
\* Frozen AssayOffice.tla, sha256:
\*   3753cef27ac926be681c5da6f51f27179b15a40764f9bc655c39f95ace5d8906
\*
\* Written for a reader who has already put a property set against this
\* office. The notes cover decisions, not syntax: the state I shipped and the
\* rivals I turned down, where each step's atomicity boundary falls, what
\* each obligation grades and what it leaves ungraded, and the rules no
\* property here can carry. Numbers come from reports/step2-variants.md and
\* reports/step6-spread.md, and the rejected representations from
\* author-notes/ALTERNATIVES.md.

\* The office's own sets, not devices for keeping the model finite. Every
\* obligation below has to hold at any finite size. The shipped config picks
\* 3 wares and 2 officers. Three wares is the least that holds a ware in each
\* of the office's three outcomes at once, one untested, one struck and one
\* defaced, and that's the observation where the mark rule bites in both
\* directions at the same time. Two officers is the rung's own ask. No
\* Observe field names an officer, so a one-officer run and a two-officer run
\* produce the same observations, and the second officer is here for the load
\* vector rather than for anything the interface can see.
CONSTANTS Wares, Officers

(*--algorithm assayoffice {
  \* One variable, the office's book, mapping each ware to a record of three
  \* columns. Observe below projects it into three functions over Wares, one
  \* per field, so the state is the book and the interface is a view of it.
  \* The measured run at three wares and two officers is 601 states
  \* generated, 125 distinct, depth 7, with TLC's own clock at 01s.
  \*
  \* 125 is the count the description's arithmetic predicted before anyone
  \* ran it, five live records per ware at three wares. I'd rather cite a
  \* prediction that held than a number that was only measured.
  \*
  \* The rivals I weighed and turned down, at length in ALTERNATIVES.md:
  \*
  \* Three functions, one per field, named verdict, struck and damaged, with
  \* Observe renaming them field for field. That's the shape rung 1 uses and
  \* it's the strongest rival here. Both forms reach 125 states and satisfy
  \* all four obligations, so I read this as a legibility call rather than a
  \* correctness one. Shape B asks the learner to write properties over
  \* Observe, and three renamed functions make Observe a rename and nothing
  \* else. With one book the projection does real work, and a reader can see
  \* where the interface comes from.
  \*
  \* One status column per ware, holding unmarked, struck or defaced. The
  \* description rules this out by name and I agree with the reason. No-both
  \* would then hold by construction, so a learner writes TRUE in a costume
  \* and TLC passes it. Keeping the mark and the defacing as two facts is
  \* what makes variant S03 writable at all: S03 strikes a ware the office
  \* found substandard, and MarksFollowTheFinding catches it at rc=12 in 12
  \* distinct states. Under the three-valued column that mutant can't be
  \* stated.
  \*
  \* A per-officer bench, where an officer picks a ware up and acts on it in
  \* a second step. Nothing in the obligations forbids it, because the
  \* pick-up is stutter under Observe. It's rejected on the count. A local
  \* holding the chosen ware multiplies the space fourfold for each officer,
  \* which is 2,000 states at three wares and two officers, over the 1,000
  \* that state space 0 allows. Variant S10 builds the custody version and
  \* measures 3,375.
  \*
  \* What gets no variable at all: the hands, the bench, the true fineness,
  \* and anywhere a ware goes afterwards. Which officer tested a ware and
  \* which one struck it is invisible at this interface, and no obligation
  \* reads it. There's no real fineness behind the finding that the test
  \* could get wrong, because fallibility is a different problem in a
  \* different column. And nothing leaves the office, so a give-back would
  \* owe a fifth obligation saying only a struck or defaced ware may leave,
  \* at a rung capped at four.

  variables
    book = [w \in Wares |->
                [verdict |-> "none", struck |-> FALSE, damaged |-> FALSE]];

  define {
    Findings == {"none", "atStandard", "substandard"}

    Observe ==
        [finding |-> [w \in Wares |-> book[w].verdict],
         marked  |-> [w \in Wares |-> book[w].struck],
         defaced |-> [w \in Wares |-> book[w].damaged]]

    TypeOK ==
        /\ Observe.finding \in [Wares -> Findings]
        /\ Observe.marked \in [Wares -> BOOLEAN]
        /\ Observe.defaced \in [Wares -> BOOLEAN]

    MarksFollowTheFinding ==
        \A w \in Wares :
            /\ Observe.marked[w] => Observe.finding[w] = "atStandard"
            /\ Observe.defaced[w] => Observe.finding[w] = "substandard"

    TheRecordOnlyGrows ==
        [][\A w \in Wares :
              /\ (Observe.finding[w] # "none")
                     => (Observe'.finding[w] = Observe.finding[w])
              /\ Observe.marked[w] => Observe'.marked[w]
              /\ Observe.defaced[w] => Observe'.defaced[w]]_Observe

    SubstandardIsDefaced ==
        \A w \in Wares :
            (Observe.finding[w] = "substandard") ~> Observe.defaced[w]
  }

  \* One process per officer, one label, and no pc in the translation. A
  \* while (TRUE) with a single label holds the program counter constant, so
  \* pcal drops it, and a process set then costs nothing on top of the book.
  \* That elision is what keeps the count at 125 rather than at some multiple
  \* of it, and the description's section 4 asked for it in so many words.
  \*
  \* A uniprocess algorithm with one with over Officers reaches the same 125
  \* states and also drops pc. I kept the process set because the
  \* description's parties list has officers as actors, and shape B ships
  \* this module for the learner to read. A process set says who acts. A with
  \* inside one anonymous process makes the officers look like a set of
  \* names.
  \*
  \* The officers don't coordinate, so any officer's next step lands between
  \* any two of another's. Nothing in the algorithm arranges that. It falls
  \* out of Next being an existential over Officers with no per-officer state
  \* to sequence.
  \*
  \* Nothing is fair up here. The one duty in this system is the defacing,
  \* and its fairness conjunct sits below the translation in FairSpec. The
  \* note there says why it can't sit in the algorithm.

  process (officer \in Officers) {
    Bench:
      while (TRUE) {
        \* One ware per step, picked with no cause behind the pick. The
        \* officer works on whichever ware they like in whatever order, so
        \* the with models their choice rather than a queue or a scheduler.
        \* There's no bench limit and no cap on how many wares sit tested and
        \* not yet dealt with. Variant S21 caps the bench and comes back
        \* uncaught at 81 distinct states, which is what a change that only
        \* removes behaviours looks like from this interface.

        with (w \in Wares) {
          either {
            \* Testing. The await is rule 2's write-once guard, and it's the
            \* whole of "a ware is tested once". Drop it and you get variant
            \* S04, the re-assay, caught at rc=13 by TheRecordOnlyGrows in 3
            \* states. That's the mistake a real office might make, which is
            \* why the statement's trace pair for item 2 uses it.
            \*
            \* The inner with picks the finding, and it's a choice with
            \* nothing behind it. The office tests and the alloy is whatever
            \* it is, so nothing in the model decides which value comes back.
            \* Same reason there's no fineness variable.

            await book[w].verdict = "none";
            with (f \in Findings \ {"none"}) {
              book[w].verdict := f;
            };
          } or {
            \* Striking. The finding is already written, so this step reads
            \* the book rather than deciding anything. Section 3 of the
            \* description licenses fusing this step with the test, and I
            \* kept them apart anyway. Variant S16 is the fusion, uncaught at
            \* 64 distinct against the reference's 125, so the licence is
            \* real and the separation buys no obligation. It's here because
            \* rule 4 has to keep its finding and its act apart, and writing
            \* rule 3 the other way round would read as an accident.
            \*
            \* The second await trims a re-strike, which would change nothing
            \* observable. State-graph hygiene, not graded behaviour.

            await book[w].verdict = "atStandard";
            await ~book[w].struck;
            book[w].struck := TRUE;
          } or {
            \* Defacing, and this is the atomicity boundary the rung rests
            \* on. The finding and the act are two steps, so a ware can sit
            \* with a substandard finding against it and its body still
            \* whole. That state is where the duty exists and is unmet, and
            \* item 3's whole content lives in it.
            \*
            \* Variant S15 fuses the test and the defacing, which deletes
            \* that state. It comes back uncaught at 64 distinct against 125,
            \* and item 3 then holds with the fairness conjunct gone. So the
            \* fusion doesn't break an obligation. It turns the rung's one
            \* new high into decoration, which is worse and harder to see.
            \*
            \* The ~damaged guard also does work for the fairness below. Once
            \* the ware is defaced the action stops being enabled, so the
            \* weak-fairness conjunct is discharged instead of left demanding
            \* a step forever.

            await book[w].verdict = "substandard";
            await ~book[w].damaged;
            book[w].damaged := TRUE;
          };
        };
      };
  }
}*)
\* ---------------------------------------------------------------------
\* The obligations, and why the notes on them sit here.
\*
\* pcal copies a define block into the generated translation word for word,
\* blank lines and all, so a comment written up there moves the translation
\* and the comment gate reads that as a changed spec. The rung 1 author
\* measured that against harness/comment-gate.sh
\* (bonded-store/reference/BondedStore-commented.tla:181-185). The
\* definitions read the same either way, so this is where the reasoning
\* lives.
\*
\* Four cfg lines, and the kind decisions carry more judgment than the
\* formulas do.
\*
\*   state invariants   TypeOK, MarksFollowTheFinding
\*   action property    TheRecordOnlyGrows
\*   liveness           SubstandardIsDefaced, this batch's first eventually,
\*                      and the only reason FairSpec exists
\* ---------------------------------------------------------------------
\*
\* Findings.
\*
\* Three values, and the third is the absence of a finding rather than a
\* third verdict. The rules fix the set, so it lives in the module and not in
\* the config. A cfg that can vary it is a cfg that can model an office
\* testing against four standards, which isn't this system.
\*
\* TypeOK is the only thing that reads it, and that has a measured cost.
\* Variant S19 widens Findings to four values and comes back uncaught at 216
\* distinct states, because TypeOK reads Observe.finding \in [Wares ->
\* Findings] and widening the set widens the invariant with it. A type
\* invariant written against a literal set would catch that, and I'd not make
\* the change. Findings is the spec's own definition and the learner never
\* writes it.
\*
\* Observe.
\*
\* The office's whole public face, the three columns of the book an officer
\* could read off at any moment. It's a projection and not a rename, and that
\* rendering also fixes the subscript for the one action property below.
\*
\* Why the mark and the defacing are two fields is the only real decision in
\* the operator. A single column holding unmarked, struck and defaced makes
\* no-both true by construction, and then the clause forbidding it is TRUE
\* wearing a costume. So they're two facts that separate actions set, and a
\* step could in principle strike a ware that's already defaced.
\* MarksFollowTheFinding is what forbids it. The same trap catches any pair
\* of facts where one is a reading of the other.
\*
\* What the interface doesn't show is the hands and the bench. A model that
\* carries a per-officer work queue and one that skips straight to the
\* actions produce the same observations, so an officer picking a ware up is
\* stutter under Observe. That's what prices the custody rival out rather
\* than ruling it out.
\*
\* TypeOK.
\*
\* Shape only, and it's the reference author's own line rather than one the
\* learner is asked to write. The learner's copy of this module ships without
\* it, and without the other three, which is why Findings looks decorative
\* over there.
\*
\* It never fired. Not one of the 22 system variants was caught here, and
\* that's a fact about the representation rather than a gap in the matrix.
\* book is a function into a three-field record and Observe projects it field
\* by field, so a variant would have to write a value outside Findings or
\* outside BOOLEAN to break the type. The one mutation that does is S19, and
\* S19 widens the invariant along with the set.
\*
\* That matters downstream. Section 3.9 wants a violating trace per property
\* and TypeOK has no violating half here, so the four cfg lines read as three
\* graded obligations plus a scaffold, and the statement ships three trace
\* pairs rather than four.
\*
\* MarksFollowTheFinding.
\*
\* Both facts tied to the finding, in one invariant, in both directions. The
\* screener proposed the weaker "no ware both struck and defaced" and the
\* widening is load-bearing rather than defensive. Variant P06 drops the
\* defaced clause and the reference stays green. Run that weakened property
\* against S02, which lets an officer deface a ware found at standard, and it
\* comes back rc=0 over 343 distinct states. The shipped form catches S02 at
\* rc=12 in 3 states.
\*
\* The state count is the tell there. S02 on its own stops at 9 distinct
\* because the invariant fires early, so the 343 isn't a truncated run
\* passing by accident. The weak form leaves a ware the office found at
\* standard destroyable with nothing watching, and that's one of the two
\* frauds this institution exists to stop.
\*
\* This is the workhorse of the matrix. It fires on S01, S02, S03, S12 and
\* S13, which are a strike on an untested ware, a defacing of an at-standard
\* ware, a strike on a substandard one, and two openings that start every
\* ware marked or defaced with no finding. S03 is the no-both case, and it
\* arrives through this invariant rather than through an obligation of its
\* own, which is what folding no-both into item 1 predicted.
\*
\* What it can't see is a ware that's neither struck nor defaced. Both
\* clauses are vacuous there, and that's the hole the two Init variants sit
\* in. See the closing note.
\*
\* TheRecordOnlyGrows.
\*
\* One boxed action property over all three fields, because the rule is one
\* rule about the record rather than three rules about columns. The screener
\* proposed "a finding once recorded never changes" and the widening is
\* load-bearing again: this fires on S04, S05, S06 and S07, a rewritten
\* finding, a cleared finding, an erased mark and an undone defacing. The
\* narrow form sees the first two.
\*
\* The first clause's antecedent is the finding not being "none", not the
\* finding having changed. An untested ware is exactly the one a test may
\* write, so the property has to hold its tongue there and speak from the
\* write onward. The flag clauses need no such guard, because FALSE to TRUE
\* is the growth and TRUE to FALSE is the break.
\*
\* The subscript is the whole of Observe, never one field, and this is the
\* place to say why once. A subscript names the state whose stutter a step
\* property forgives. Variant P01 subscripts this _(Observe.finding) and the
\* reference stays green. Run it against S06, which clears a mark, and the
\* escape is clean at rc=0 where the shipped form returns rc=13. A
\* mark-clearing step leaves finding alone, so the property is satisfied by
\* its own stuttering disjunct and stops looking at the steps it was written
\* about. P02 is the same move one field over, _(Observe.marked) against a
\* finding that clears, and it escapes the same way.
\*
\* TLC issues no warning on either. And neither escape is rescued by another
\* obligation, which is where this rung differs from qsl: the liveness here
\* only watches defaced, so a wrong subscript on this property is a clean
\* pass over a broken office.
\*
\* What it doesn't carry is how many wares move in one step. It quantifies
\* over wares one at a time.
\*
\* SubstandardIsDefaced.
\*
\* The one liveness obligation, and the rung's single new high. The leads-to
\* re-arms in every state where the antecedent holds, so the office can't
\* discharge the duty once and retire.
\*
\* The form is where the step 6 panel split, and the split is worth more than
\* the formula. One seat wrote the antecedent under a bare <> with no leading
\* always. A temporal formula with no leading box binds at the opening state
\* alone, Init writes every finding as "none", so the antecedent is false
\* there for every ware and the implication holds for free on every
\* behaviour. Measured: that property comes back rc=0 over the shipped spec's
\* own 601 generated and 125 distinct, and rc=0 again against the forbidden
\* run built to break it. A one-state probe opening with a ware already
\* substandard and whole returns rc=13. So the property isn't dead. It just
\* never gets asked. The ~> carries its own always, and that's the whole
\* difference.
\*
\* This is the obligation that leans on FairSpec. Variant P03 drops the
\* conjunct and TLC returns rc=13 on a trace of 6 real states and then a
\* stuttering seventh. The violation is that nothing more happens, ever, and
\* that last clause has to be said out loud, because the six-state prefix on
\* its own is an ordinary run of the office.
\*
\* What it doesn't carry is a deadline or an order. Sooner or later is the
\* whole of the duty, and nothing here says which ware goes first.

\* Below is pcal's output, and it's the text TLC actually reads. Three things
\* about it. It carries no pc, for the reason in the note above the process.
\* A define block's operators are copied down here word for word, which is
\* why every obligation appears twice in this file. And ProcSet is generated
\* and unread, since nothing below it mentions the set.
\*
\* Read the algorithm above for intent and this block for what ran.

\* BEGIN TRANSLATION (chksum(pcal) = "a832d6c1" /\ chksum(tla) = "d50646b")
VARIABLE book

(* define statement *)
Findings == {"none", "atStandard", "substandard"}

Observe ==
    [finding |-> [w \in Wares |-> book[w].verdict],
     marked  |-> [w \in Wares |-> book[w].struck],
     defaced |-> [w \in Wares |-> book[w].damaged]]

TypeOK ==
    /\ Observe.finding \in [Wares -> Findings]
    /\ Observe.marked \in [Wares -> BOOLEAN]
    /\ Observe.defaced \in [Wares -> BOOLEAN]

MarksFollowTheFinding ==
    \A w \in Wares :
        /\ Observe.marked[w] => Observe.finding[w] = "atStandard"
        /\ Observe.defaced[w] => Observe.finding[w] = "substandard"

TheRecordOnlyGrows ==
    [][\A w \in Wares :
          /\ (Observe.finding[w] # "none")
                 => (Observe'.finding[w] = Observe.finding[w])
          /\ Observe.marked[w] => Observe'.marked[w]
          /\ Observe.defaced[w] => Observe'.defaced[w]]_Observe

SubstandardIsDefaced ==
    \A w \in Wares :
        (Observe.finding[w] = "substandard") ~> Observe.defaced[w]


vars == << book >>

ProcSet == (Officers)

Init == (* Global variables *)
        /\ book = [w \in Wares |->
                       [verdict |-> "none", struck |-> FALSE, damaged |-> FALSE]]

officer(self) == \E w \in Wares:
                   \/ /\ book[w].verdict = "none"
                      /\ \E f \in Findings \ {"none"}:
                           book' = [book EXCEPT ![w].verdict = f]
                   \/ /\ book[w].verdict = "atStandard"
                      /\ ~book[w].struck
                      /\ book' = [book EXCEPT ![w].struck = TRUE]
                   \/ /\ book[w].verdict = "substandard"
                      /\ ~book[w].damaged
                      /\ book' = [book EXCEPT ![w].damaged = TRUE]

Next == (\E self \in Officers: officer(self))

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

\* Deface is a hand copy of the third disjunct of officer, written out here
\* so the fairness conjunct below has a named action to sit on. Nothing keeps
\* the copy in step with the original. Change the defacing branch in the
\* algorithm and this operator goes stale in silence, and the run stays green
\* while the conjunct names an action the system no longer takes. I'd rather
\* name that than let a reader find it.
\*
\* The o parameter is unused, and that's the same elision as everywhere else
\* here. The translator dropped pc, so an officer carries no state at all,
\* and every officer's defacing of a given ware is the same action. I left
\* the parameter unused rather than write o \in Officers, which would look
\* like a guard and isn't one. The generated officer(self) ten lines up
\* carries the same unused parameter, so the shape at least matches what sits
\* beside it.
Deface(o, w) ==
    /\ book[w].verdict = "substandard"
    /\ ~book[w].damaged
    /\ book' = [book EXCEPT ![w].damaged = TRUE]

\* The specification formula, and it has its own name for a mechanical
\* reason. The translator writes Spec == Init /\ [][Next]_vars whether or not
\* the algorithm is fair, so a second definition of Spec isn't available. A
\* fair process annotation would give weak fairness on the whole process
\* step, which is a disjunction of an officer's three actions and obliges
\* none of them. So the fairness has to go outside the translation, and the
\* formula carrying it needs a name of its own. The cfg says SPECIFICATION
\* FairSpec. Run this module under Spec instead and you get a green run that
\* grades nothing about the duty.
\*
\* The conjunct is load-bearing. P03 replaces it with TRUE and TLC returns
\* rc=13.
\*
\* Neither quantifier is. I wrote the fine form on the argument that an
\* officer who tests wares forever would satisfy a coarser one while a
\* substandard ware sat whole. That argument is measured false at this
\* instance. WF_vars(Next) comes back rc=0, the per-officer disjunction comes
\* back rc=0, and the step 6 panel built a module to show the ware quantifier
\* was load-bearing and got refuted at rc=0 over 125 distinct states. The
\* mechanism is that every action here is monotone and Wares is finite, so no
\* behaviour tests forever, every behaviour reaches quiescence, and at
\* quiescence no substandard ware is undefaced. The coarse forms drag the
\* office to quiescence just as the fine one does.
\*
\* I'd keep the fine form, and on the other reason. This is the rung where
\* fairness first appears, and the fine form is the one that stays right when
\* the system stops being monotone. What I'd change is the argument, not the
\* code.
\*
\* One trap worth knowing, from variant S08. Delete the defacing branch and
\* keep this conjunct, and every behaviour that finds a ware substandard
\* falls out of FairSpec, because the conjunct demands a step Next forbids.
\* The state graph still holds all 64 states, including substandard undefaced
\* ones, but the temporal obligations are checked over the survivors and no
\* survivor ever finds a ware substandard. The run is rc=0 and the vacuity
\* probe reports NON_VACUOUS, because FairSpec does admit behaviours.
\* Fairness can empty out an obligation without emptying out the spec.
FairSpec ==
    /\ Spec
    /\ \A o \in Officers, w \in Wares : WF_vars(Deface(o, w))

\* ---------------------------------------------------------------------
\* What this property set deliberately can't carry.
\*
\* Who acts. Observe shows the book, not the hands in it. "The officer struck
\* the ware" can't be a property of any model at this interface, whatever
\* fields you add. At this shape the spec ships complete, so the learner
\* reads the actions instead of grading them.
\*
\* An obligation to test. The office owes nobody a deadline and a ware can
\* lie untested for the whole story. That's carried by restraint, meaning
\* there's no fairness on the testing step and no second liveness line.
\* Variant S22 adds the conjunct and comes back uncaught at 125 distinct,
\* which is what adding a fairness conjunct does: it removes behaviours, and
\* removing behaviours breaks nothing here.
\*
\* Most of the opening. MarksFollowTheFinding catches a ware that starts
\* marked or defaced with no finding, at the initial state, and it catches
\* nothing else about Init. S11 starts every ware at standard and S14 starts
\* every ware substandard, and both are green under all four obligations. A
\* fifth cfg line pinning the opening was priced and refused, because five
\* lines takes property count out of this rung's band and the fairness is
\* meant to be the only new high.
\*
\* That hole is closed one layer out, and I didn't expect it to be. Both
\* openings come back VACUOUS_DEAD_ACTION at rc=5 from harness/vacuity.sh,
\* because an Init that pre-writes every finding leaves the test branch's
\* guard never true. So the answer is "the dead-action probe catches it", not
\* "nothing does". I'd not read that as covering every opening mutation. It
\* catches an Init that makes an action unreachable. An opening that seeds
\* one ware out of three would leave every branch live, and I'd expect that
\* one to stay green. Nobody has run it.
\*
\* An office that does less. S20 restricts the defacing to one officer, S21
\* caps the bench, S18 adds a lodging step, and all three are green at 125,
\* 81 and 216 distinct. Every obligation here is a safety property, a boxed
\* action or a leads-to still discharged, and none of those can see a system
\* that takes a subset of the behaviours it should.
\*
\* State the operator doesn't read. S17 gives each ware a gone column and a
\* step that sets it. The space doubles to 1,000 and no Observe field moves,
\* so every such step is absorbed by the stuttering disjunct of the boxed
\* property. Anything outside the three columns is free.
\*
\* Fusions. S15 fuses the test and the defacing, S16 fuses the test and the
\* strike, and both come back green at 64 distinct against 125. Both delete a
\* state rather than add a behaviour, so no property over this interface
\* tells them apart from the reference. S16 is licensed. S15 isn't, and it's
\* the one that costs something, because the state it deletes is the state
\* item 3 is about.
\*
\* The truth of a finding. There's no fineness behind the office's word, so
\* nothing here asks whether the assay was right. Reassay, appeal, several
\* standards at once, a date letter that turns over each year, and the ware's
\* fate after the bench are all real and all outside. Each one costs at least
\* another obligation, and four lines is this rung's cap.
\* ---------------------------------------------------------------------

=============================================================================
