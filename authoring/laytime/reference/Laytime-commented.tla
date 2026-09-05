------------------------------ MODULE Laytime ------------------------------
\* The laytime reference, commented after the freeze. The spec text is the
\* frozen Laytime.tla byte for byte, and harness/comment-gate.sh checks that
\* claim rather than trusting it. Comments are the only addition.
\*
\* Frozen Laytime.tla, sha256:
\*   15ad020a86bfa33707bbc3567a7330ec508202083182f8dbc5d449ce9c124fd1
\*
\* Written for a reader who has already put their own spec of this statement
\* together from the prose. The notes cover decisions, not syntax: the four
\* variables I shipped and the rivals I turned down, where a step's atomicity
\* boundary falls, what each obligation grades and what it leaves ungraded,
\* and the rules no property here can carry. Numbers come from
\* reports/step2-variants.md and reports/step6-spread.md, and the rejected
\* representations from author-notes/ALTERNATIVES.md.
EXTENDS Integers

\* The charter's two terms, and neither is a device for keeping the model
\* finite. The allowance is the laytime the charterparty gives. The limit is
\* the charter's cap on the owner's demurrage claim, which is what makes the
\* statement a finite document without inventing a horizon. Every obligation
\* below has to hold at any pair of whole-period values.
\*
\* The shipped cfg picks 2 and 2. Two is the least allowance that makes the
\* drawdown happen more than once, so a model that empties the allowance in
\* one step is caught rather than indistinguishable. Two is the least limit
\* that lets the demurrage counter rise twice, which is what makes the
\* step-size clause bite on the demurrage side as well.
CONSTANTS Allowance, Limit

\* Nat rather than a positive range, so zero is in scope on both. A zero
\* allowance opens the statement already on demurrage. A zero limit stops it
\* before it starts, and that one is a real finding rather than a curiosity.
\* The note on the logging guard below says what it costs.
ASSUME Allowance \in Nat /\ Limit \in Nat

(*--algorithm laytime {
  \* Four variables, one per Observe field, and no fifth. Observe below
  \* renders as the identity over them, field for field, so the state is the
  \* interface and nothing hides behind a projection. The measured run at an
  \* allowance of 2 and a limit of 2 is 15 states generated, 11 distinct,
  \* depth 7, in 0.54 s (step2-variants.md check 6). The 11 is what
  \* DESCRIPTION.md section 4 estimated before anybody ran it.
  \*
  \* The rung pins this. Representation 2 says the reference's variables are
  \* the Observe fields and nothing else, so my freedom is in what each
  \* variable holds and how the steps move it. It's never in adding a carrier
  \* for something the interface doesn't show. The rivals I weighed sit at
  \* length in ALTERNATIVES.md, and the short of it is here.
  \*
  \* A variable for the mode, holding laytime or demurrage, flipped when the
  \* allowance empties. The strongest rival and the one I spent longest on. I
  \* turned it down twice over. The mode is laytimeLeft = 0 and nothing else,
  \* so the variable caches a test that costs nothing to run, and a cache can
  \* go stale. A model that lets this one drift takes a step no property here
  \* can see, because the mode isn't an Observe field.
  \*
  \* The second reason is the problem itself. The learner either sees the
  \* latch already sitting in the counter or invents state for it. Writing
  \* the variable into the reference answers that on the reference's own
  \* page. All three panel seats read the latch off the counter and none kept
  \* a phase variable (step6-spread.md, the verdict section), so the question
  \* is at least askable as it stands.
  \*
  \* A sequence of logged periods, each tagged working or excepted, with both
  \* counters derived from it. That's closer to what a laytime statement
  \* really is, since the statement is a document and the document is the
  \* log. I turned it down because the counters are what the statement
  \* records and the log is only how they got there. The sequence buys
  \* history nothing here reads, and it grows the state space by the order of
  \* the periods rather than by what they cost.
  \*
  \* One integer running down past zero, with the allowance left as the
  \* positive part and the demurrage as whatever sits below. One variable,
  \* and the no-split clause holds by construction. That last part is what
  \* killed it. Both Observe fields become projections of one number, so
  \* OnePeriodOneMove's third conjunct can't fail inside the model, and an
  \* obligation that can't break grades nothing. The note on that property
  \* carries the measurement from the other side.
  \*
  \* What gets no variable at all. The kind of a period, working or
  \* excepted, is the big one, and the third arm below says why. The weather
  \* is the agent's reason for a classification and never a step. The money,
  \* the settlement between charterer and owner, and both of those parties
  \* sit outside the boundary by Rule 2. There's no clock and no calendar,
  \* which is the one thing a domain about time running out can't have here.

  variables
    noticeTendered = FALSE,
    laytimeLeft = Allowance,
    demurrage = 0,
    finished = FALSE;

  \* The obligations sit in the define block below, and the notes on them sit
  \* under the algorithm rather than up here. pcal copies a define block into
  \* the generated translation word for word, blank lines and all. So a
  \* comment written inside it moves the translation, and the gate reads a
  \* moved translation as a changed spec. Measured on this file against
  \* harness/comment-gate.sh.

  define {
    Observe ==
        [noticeTendered |-> noticeTendered,
         laytimeLeft |-> laytimeLeft,
         demurrage |-> demurrage,
         finished |-> finished]

    TypeOK ==
        /\ Observe.noticeTendered \in BOOLEAN
        /\ Observe.laytimeLeft \in 0..Allowance
        /\ Observe.demurrage \in 0..Limit
        /\ Observe.finished \in BOOLEAN

    DemurrageWaitsForAllowance ==
        Observe.demurrage > 0 => Observe.laytimeLeft = 0

    OpensOnceClosesOnce ==
        [][ /\ ~Observe.noticeTendered =>
                  /\ Observe'.laytimeLeft = Observe.laytimeLeft
                  /\ Observe'.demurrage = Observe.demurrage
                  /\ Observe'.finished = Observe.finished
            /\ Observe.finished => Observe' = Observe
            /\ Observe.noticeTendered => Observe'.noticeTendered
            /\ Observe.finished => Observe'.finished ]_Observe

    OnePeriodOneMove ==
        [][ /\ Observe'.laytimeLeft
                  \in {Observe.laytimeLeft, Observe.laytimeLeft - 1}
            /\ Observe'.demurrage
                  \in {Observe.demurrage, Observe.demurrage + 1}
            /\ ~( /\ Observe'.laytimeLeft # Observe.laytimeLeft
                  /\ Observe'.demurrage # Observe.demurrage ) ]_Observe
  }

  {
    \* One label, one process, and no pc in the translation. A label per rule
    \* would read closer to the prose, and I kept one on purpose. A program
    \* counter is state the statement can't show, and I'd rather not carry a
    \* variable Observe has no honest field for.
    \*
    \* The single label is also the atomicity boundary, and it's the whole of
    \* it. Every step here is one write to the statement, made by the agent,
    \* after the time it records has already gone. There's no half-written
    \* period and no state where a period is part classified. That's what
    \* lets the no-split clause be a claim about steps rather than a
    \* restatement of how I defined a period.
    \*
    \* Nothing is fair and nothing has to happen. Rule 11 is graded by
    \* restraint. Spec below carries no fairness conjunct and the cfg carries
    \* no liveness line, and that absence is the whole of it.
    Statement:
      while (TRUE) {
        either {
          \* The notice of readiness, Rule 3. Tendered once, never withdrawn,
          \* and nothing in the statement moves before it. The guard is what
          \* makes the tender happen once.
          \*
          \* Withdrawal is caught at rc=13 over a 3-state trace (S02).
          \* Re-tendering an already tendered notice isn't caught at all.
          \* Setting a flag that's already set changes no field, so the step
          \* stutters under Observe (S17, rc=0 at 11 distinct). I think
          \* that's the right split rather than a gap. A re-tender that
          \* changes nothing costs nothing.
          await ~noticeTendered;
          noticeTendered := TRUE;
        } or {
          \* A logged period, and the arm carrying Rules 6 and 7. The agent
          \* writes one period, and the if carries the whole story of the
          \* allowance running out. While any allowance stands the period
          \* draws it down by one. Once it's gone the same period accrues
          \* one of demurrage instead. One counter moves and the other
          \* holds, so Rule 7's no-split clause rides on the shape of the
          \* step.
          \*
          \* Note what the mode is tested against. Not a variable, but
          \* laytimeLeft > 0. That test is the latch, and it can't go stale
          \* because there's nothing to keep in step with anything.
          \*
          \* demurrage < Limit is Rule 9's cap, and I put it in the guard
          \* rather than in a CONSTRAINT line. A constraint says the checker
          \* stopped looking and a guard says the agent stopped writing, and
          \* only one of those is true here.
          \*
          \* The cap costs something at a limit of zero, and the panel found
          \* it. Read as written, the guard is already false at the opening
          \* when Limit is 0, so the allowance never falls at all. At an
          \* allowance of 3 and a limit of 0 this reference reaches 3
          \* distinct states. Two of three seats moved their guard to
          \* left > 0 \/ dem < Limit and reached 9 (step6-spread.md finding
          \* 1). I think the seats have the better reading, because Rule 9's
          \* own stated reason is that there's nothing further to record, and
          \* against a full allowance there plainly is. This reference takes
          \* the letter instead. Nothing in the cfg separates the two
          \* readings at any instance the panel swept, so the fix is in the
          \* prose rather than here.
          await noticeTendered /\ ~finished /\ demurrage < Limit;
          if (laytimeLeft > 0) {
            laytimeLeft := laytimeLeft - 1;
          } else {
            demurrage := demurrage + 1;
          };
        } or {
          \* The excepted period, Rule 5, and the second half of Rule 8. The
          \* charter excuses this one, so while the allowance stands it draws
          \* nothing down and moves no field. Once the allowance is spent the
          \* exception stops applying and the period accrues like any other.
          \* That's the rule of the trade, and it's the sentence in this
          \* system worth reading twice.
          \*
          \* This arm is here for the reader and not for the checker, and I'd
          \* rather say so than let somebody find it. Nothing grades it. S14
          \* drops the accrual entirely, so an excepted period runs free on
          \* demurrage, and it comes back rc=0 on all four obligations and
          \* non-vacuous at both floors. Its numbers are the reference's own,
          \* every one of them: 15 generated, 11 distinct, depth 7
          \* (step2-variants.md finding 1). The transition S14 removes is one
          \* the arm above already reaches from an identical guard.
          \*
          \* The dead-action probe can't help either. This arm's coverage row
          \* reads 0 distinct out of 4 total, in the reference and in S14
          \* alike. The branch fires, so there's nothing for a total == 0
          \* predicate to match. Read distinct == 0 there and you'd fail a
          \* healthy reference.
          \*
          \* I kept the arm because the reference should say what the agent
          \* can do, not only what the statement records. Dropping it would
          \* lose no behavior and no state. The cost is a few self-loop
          \* edges, and they land in the generated count rather than the
          \* distinct one.
          await noticeTendered /\ ~finished /\ demurrage < Limit;
          if (laytimeLeft = 0) {
            demurrage := demurrage + 1;
          };
        } or {
          \* Closing the statement, Rule 9. Done once, only after the notice
          \* is tendered, and never undone. The guard carries no cap term on
          \* purpose. Once the demurrage claim reaches the limit the agent
          \* logs nothing further, and closing is the one step still open to
          \* him. He needn't take it.
          \*
          \* Closing before the notice is caught at 2 states and logging
          \* after the close at 4 (S18 and S04, both rc=13). No allowed run
          \* in the shipped trace pairs exercises a close at all
          \* (step6-spread.md finding 6). So the 11-state count is the only
          \* artifact in the delivery that speaks to the closing step being
          \* producible.
          \*
          \* After the close no action is enabled and the system stops. That
          \* is the intended end of the story, so the cfg carries
          \* CHECK_DEADLOCK FALSE. A checker reporting deadlock there is
          \* reporting the design working. The alternative was an idle
          \* action, and an idle action is a step this system assigns to
          \* nobody.
          await noticeTendered /\ ~finished;
          finished := TRUE;
        };
      };
  }
}*)
\* ---------------------------------------------------------------------
\* The obligations, and why their notes sit down here.
\*
\* Four cfg lines, and the kind decisions carry more of the judgment than
\* the formulas do.
\*
\*   state invariants   TypeOK, DemurrageWaitsForAllowance
\*   action properties  OpensOnceClosesOnce, OnePeriodOneMove
\*   liveness           none, and the absence is graded. Rule 11 says the
\*                      agent is under no obligation, and an obligation
\*                      would show up here as a liveness line
\* ---------------------------------------------------------------------
\*
\* Observe.
\*
\* The identity over the four variables, field for field. That rendering
\* also fixes the subscript for both action properties. The note at the end
\* of this block says what goes wrong when a subscript names one field
\* instead of the whole record.
\*
\* There's no fifth field for the mode. Whether the ship is on demurrage is
\* a fact about the allowance being spent, and it's readable off
\* laytimeLeft alone. I think a field carrying the mode would be the single
\* most damaging thing this operator could do. The whole abstraction
\* question is whether the learner sees the mode already sitting there. Put
\* it on the page and the question is answered.
\*
\* There's no field for the kind of a period either, and that one costs
\* something. The statement records what a period cost, not what the agent
\* called it. While the allowance stands an excepted period moves no field,
\* so it's a stutter at this interface. Once the allowance is spent every
\* period costs one whatever it's called. So in a correct model the kind
\* changes nothing the statement records, and in a model that gets Rule 8's
\* second half wrong this interface can't see the difference.
\*
\* TypeOK.
\*
\* Mine, not a learner requirement. It's the cfg line carrying the ranges
\* that Rules 1 and 9 fix, the allowance between zero and Allowance and the
\* demurrage between zero and Limit.
\*
\* Two variants land here and both land for the wrong reason. S13 drops the
\* cap from both logging guards and S19 draws the allowance down with no
\* laytimeLeft > 0 test. Each comes back rc=12 against TypeOK and against
\* nothing else (step2-variants.md finding 4). A learner who writes the
\* three stated rules and no type invariant catches neither.
\*
\* The under-approximation check is what carries them on the learner's
\* side. A model whose counters leave these ranges reaches Observe states
\* the reference can't. Worth knowing the shipped set leans on that for two
\* rules.
\*
\* DemurrageWaitsForAllowance.
\*
\* The boundary rule, and the line that decides this rung. It's a claim
\* about one state, so it's an invariant, and it breaks in one state with
\* nothing before it.
\*
\* It closes the shortest route to a wrong model here. Take a learner who
\* carries the allowance and the mode as two loose variables, and writes
\* every rule without noticing they're coupled. That latch drifts out of
\* step with the counter. Drift puts demurrage on the board while some of
\* the allowance still stands, and this line forbids that state.
\*
\* S11 opens with a period of demurrage against a full allowance and is
\* caught at the initial state, which is the shortest counterexample there
\* is. S07 accrues instead of drawing down and is caught at 3 states.
\*
\* OpensOnceClosesOnce.
\*
\* Four conjuncts, one per way the reckoning can open or close wrongly.
\* Nothing moves before the notice (S01, 2 states). Nothing moves after the
\* close (S04, 4 states). The notice is never withdrawn (S02, 3 states).
\* The close is never undone (S03, 4 states). All four at rc=13.
\*
\* The fourth is implied by the second, since Observe' = Observe pins
\* finished along with everything else. It stays because Rule 3 and Rule 9
\* state it and a reader shouldn't have to derive it.
\*
\* The grading cost is real and the panel measured it. Three of the four
\* conjuncts can't fail against the reference at this instance, so the
\* shipped trace pair for this rule grades the first conjunct and nothing
\* else. One panel seat in three wrote a form that permits both a withdrawn
\* notice and a reopened statement, and passed the pair anyway
\* (step6-spread.md, the requirement 1 section). A submission that drops
\* three of four conjuncts shouldn't score the same as one that writes
\* them, and nothing in the delivery currently stops it.
\*
\* OnePeriodOneMove.
\*
\* Three conjuncts, and each membership carries a direction and a step size
\* together. The allowance stays or falls by one, which is Rule 6 whole.
\* The demurrage stays or rises by one, which is Rule 7's direction and
\* size. Two periods at once is caught at 3 states (S05), a refill at 4
\* (S08), and a rebate at 6 (S09).
\*
\* The third conjunct is the no-split clause, and it's the load-bearing
\* one. S06 makes the period that spends the last of the allowance also
\* accrue one, which is Rule 7's no-split clause broken. It's caught at
\* rc=13 over 4 states. Drop the conjunct and the same system passes at
\* rc=0, so nothing else in the set notices (P03, step2-variants.md finding
\* 6). The post-state is a spent allowance with one period accrued, which
\* DemurrageWaitsForAllowance allows and the first two conjuncts allow.
\* That's the sharpest single argument for keeping all three together in
\* one property, and it's the same argument that killed the one-counter
\* representation above.
\*
\* The subscript, said once for both.
\*
\* The subscript names the state whose stutter a step property forgives, so
\* it has to be _Observe, the whole record, on both properties here.
\* Subscript OnePeriodOneMove on _(Observe.laytimeLeft) and a rebate step
\* leaves that field alone. The property is then satisfied by its own
\* stuttering disjunct, and it never looks at the step it was written for.
\* S09 goes from rc=13 to rc=0 under that one change. The same move on
\* OpensOnceClosesOnce over _(Observe.noticeTendered) takes S03 from rc=13
\* to rc=0 (P01 and P02, step2-variants.md finding 5). TLC reports green
\* either way and warns about nothing.
\*
\* This is shape A, so the learner writes the subscript with no spec to
\* copy it from. I'd treat it as the live failure mode for this problem.
\*
\* Below is pcal's output, and it's the text TLC actually reads. Two things
\* about it have tripped a reader already. It carries no pc variable, which
\* is right for a one-process algorithm with a single label, since a
\* constant program counter buys nothing. And a define block's operators
\* are copied down here word for word, which is why every obligation
\* appears twice in this file. Read the algorithm above for intent and this
\* block for what ran.

\* BEGIN TRANSLATION (chksum(pcal) = "dd142a3e" /\ chksum(tla) = "743cf47c")
VARIABLES noticeTendered, laytimeLeft, demurrage, finished

(* define statement *)
Observe ==
    [noticeTendered |-> noticeTendered,
     laytimeLeft |-> laytimeLeft,
     demurrage |-> demurrage,
     finished |-> finished]

TypeOK ==
    /\ Observe.noticeTendered \in BOOLEAN
    /\ Observe.laytimeLeft \in 0..Allowance
    /\ Observe.demurrage \in 0..Limit
    /\ Observe.finished \in BOOLEAN

DemurrageWaitsForAllowance ==
    Observe.demurrage > 0 => Observe.laytimeLeft = 0

OpensOnceClosesOnce ==
    [][ /\ ~Observe.noticeTendered =>
              /\ Observe'.laytimeLeft = Observe.laytimeLeft
              /\ Observe'.demurrage = Observe.demurrage
              /\ Observe'.finished = Observe.finished
        /\ Observe.finished => Observe' = Observe
        /\ Observe.noticeTendered => Observe'.noticeTendered
        /\ Observe.finished => Observe'.finished ]_Observe

OnePeriodOneMove ==
    [][ /\ Observe'.laytimeLeft
              \in {Observe.laytimeLeft, Observe.laytimeLeft - 1}
        /\ Observe'.demurrage
              \in {Observe.demurrage, Observe.demurrage + 1}
        /\ ~( /\ Observe'.laytimeLeft # Observe.laytimeLeft
              /\ Observe'.demurrage # Observe.demurrage ) ]_Observe


vars == << noticeTendered, laytimeLeft, demurrage, finished >>

Init == (* Global variables *)
        /\ noticeTendered = FALSE
        /\ laytimeLeft = Allowance
        /\ demurrage = 0
        /\ finished = FALSE

Next == \/ /\ ~noticeTendered
           /\ noticeTendered' = TRUE
           /\ UNCHANGED <<laytimeLeft, demurrage, finished>>
        \/ /\ noticeTendered /\ ~finished /\ demurrage < Limit
           /\ IF laytimeLeft > 0
                 THEN /\ laytimeLeft' = laytimeLeft - 1
                      /\ UNCHANGED demurrage
                 ELSE /\ demurrage' = demurrage + 1
                      /\ UNCHANGED laytimeLeft
           /\ UNCHANGED <<noticeTendered, finished>>
        \/ /\ noticeTendered /\ ~finished /\ demurrage < Limit
           /\ IF laytimeLeft = 0
                 THEN /\ demurrage' = demurrage + 1
                 ELSE /\ TRUE
                      /\ UNCHANGED demurrage
           /\ UNCHANGED <<noticeTendered, laytimeLeft, finished>>
        \/ /\ noticeTendered /\ ~finished
           /\ finished' = TRUE
           /\ UNCHANGED <<noticeTendered, laytimeLeft, demurrage>>

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

\* ---------------------------------------------------------------------
\* What this property set deliberately can't carry, and what I left out of
\* the model.
\*
\* Rule 8's second half. The headline one, and the third arm above carries
\* the measurement. An excepted period that runs free on demurrage is a
\* stutter at this interface, so no formula over these fields can see it.
\* The rule stands and nothing watches it. Two things follow. No seeded bug
\* for this problem may use that half, because a bug nothing detects grades
\* every submission the same. And the statement shouldn't lean on Rule 8 as
\* something the learner is marked on, since half of it isn't.
\*
\* Who acts. Observe shows the statement, not the hand writing it. S20 adds
\* a clock, a disjunct with the logging arm's guard and effect taken by
\* nobody, and it comes back rc=0 at 11 distinct with 19 generated. The
\* four extra generated states all fold into states that already exist. I
\* don't think any addition to the operator changes this, because a step's
\* author isn't a fact about the page.
\*
\* An obligation to act. The agent owes nothing, ever. That's carried by
\* restraint, and only an over-constrained spec gets it wrong.
\*
\* The opening. Nothing pins the four facts at the start. S10 opens with
\* the notice already tendered and S12 opens with the allowance spent, and
\* both pass all four obligations. A fifth cfg line would close it and
\* would break the rung's property count. That was a stated decision, and
\* those two rc=0 runs are its cost turning up where it was predicted.
\*
\* The vacuity layer catches them both, and the floor decides whether the
\* diagnosis is any good. At a floor of 4, S10 reports
\* VACUOUS_DEAD_ACTION, because the tender guard is never true, and S12
\* reports VACUOUS_FROZEN_OBSERVE, because the allowance holds zero
\* everywhere. At a floor of 11 both collapse to VACUOUS_EMPTY_SPACE. The
\* catch survives and the diagnosis doesn't, which is why the floor here is
\* set at 4 rather than at the reference's own count.
\*
\* A system that does too little. S15 drops the closing arm and S16 keeps
\* the tender alone, and both satisfy all four obligations. Every line here
\* is a safety property or a boxed action, and both kinds survive taking a
\* subset of the behaviors. The vacuity probes catch both. No property set
\* can see a system that does less than it should.
\*
\* Rule 9 at a limit of zero. The logging guard above carries it. The
\* reference takes the letter of the rule, two of three panel seats took
\* the reason, and nothing in the cfg tells the two readings apart.
\*
\* Whole periods, despatch, re-tendering, the excepted list, and parcels.
\* Every one of those is real and every one is out, and each is out for its
\* own reason.
\*
\* Real laytime is reckoned in hours, and a period does straddle the moment
\* the allowance runs out. Modeling that needs arithmetic on part-periods,
\* which is a bigger space for no new modeling question. Despatch, the
\* charterer's money back for finishing early, is a third counter and a
\* fourth rule, and the count here already sits at the top of this rung's
\* band. A notice re-tendered after it turns out invalid kills
\* OpensOnceClosesOnce outright, and that's the rule doing the boundary
\* work. Naming weather, holidays and strikes one by one is three words of
\* vocabulary and no new property. Parcels turn the counters into functions
\* and make this a different problem.
\* ---------------------------------------------------------------------

=============================================================================
