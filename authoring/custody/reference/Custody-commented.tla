------------------------------- MODULE Custody -------------------------------
\* One planning window of a two-parent custody arrangement. The model is
\* frozen. These comments were added in a later pass, and a strip-and-diff
\* gate holds the code identical to the frozen reference, so the commentary
\* can't have bent the spec toward itself.
\*
\* The comments cover modeling decisions, not syntax. Where a choice had a
\* live alternative, the alternative is named with the reason it lost.
\*
\* Plain TLA+ rather than PlusCal. The parties act independently and days
\* begin on their own, which is bare interleaving, so PlusCal buys nothing
\* here. Its pc variable would sit in the state for no observable reason,
\* and the obligations are action properties over an interface, which read
\* best against explicit actions.
EXTENDS Naturals, FiniteSets

\* Base and Hol are function-valued, and a cfg can't write a function, so
\* the instance data lives in MCCustody.tla and the cfgs bind it. Instance
\* operators inside this module would bend the reference toward one
\* instance.
\*
\* Sched(_) is the yardstick, and it's a declared constant on purpose. The
\* model defines Scheduled below, and the four schedule-reading obligations
\* could have read it. They don't, because an obligation that reads the
\* model's own operator moves when the model does: rewrite Scheduled and
\* both sides of every comparison shift together, and the broken model
\* grades clean. Sched is bound in the MC layer instead. The model derives
\* custody from its own operator while the obligations measure against the
\* instance's, so a rewrite moves one side of the comparison only.
\*
\* The cfg route that looks simpler, a definition override
\* Scheduled <- MCSched, does the opposite. An override replaces the
\* operator everywhere it appears, Custodian included, so the rewritten
\* model and the reference become the same spec. That route erases the
\* fault it was meant to catch.
CONSTANTS A, B, H, N, Base, Hol, Sched(_)

ASSUME A # B
ASSUME H \in Nat \ {0}
ASSUME N \in Nat
ASSUME Base \in [1..H -> {A, B}]
ASSUME /\ DOMAIN Hol \subseteq 1..H
       /\ \A d \in DOMAIN Hol : Hol[d] \in {A, B}
\* If a cfg binds Sched to something that isn't a schedule, this fails
\* loudly (rc=10) before anything grades against nonsense.
ASSUME \A d \in 1..H : Sched(d) \in {A, B}

Parents == {A, B}
Days == 1..H

\* Zero as the no-day marker, over a model value. With 0, "day d hasn't
\* begun" is d > today in every state, the opening included, and the
\* none-to-1 opening move is the same +1 as every later one. A model value
\* forces a case split at every comparison. The cost is that 0 must stay
\* out of Days, which 1..H gives for free.
NoDay == 0

\* Two named parents, not a Parents set constant. Two is the domain's own
\* number, not a bound, so there's no generality worth paying for. Other
\* over a set constant needs CHOOSE, which reads worse and checks the same.
Other(p) == IF p = A THEN B ELSE A

\* The model's own reading of the schedule: the designation wins on a
\* designated day, the base pattern otherwise. Definable from the constants
\* alone, so nothing mutable leaks into what's derived from it. The
\* obligations don't read this operator. See the note at CONSTANTS.
Scheduled(d) == IF d \in DOMAIN Hol THEN Hol[d] ELSE Base[d]

\* The biggest fork: derive custody, or maintain it. A maintaining model
\* keeps a custodian function and rewrites one entry on acceptance. This
\* one keeps the set of swapped days and derives everything else. Three
\* reasons. The cap becomes Cardinality of a set the model already holds.
\* At most one flip per day is near-structural, since days enter swapped
\* and never leave. And the interface promises that a deriving model and a
\* maintaining model look the same through Observe, so the smaller state
\* won.
\*
\* What's not in the state, on purpose: the swap count, the proposal
\* history, and who proposed what. The interface was designed not to see
\* those, so tracking them buys distinctions no obligation can grade.
VARIABLES today, swapped, pending

vars == <<today, swapped, pending>>

\* pending is a total function so Rule 7's one-slot-per-parent rides the
\* shape itself. The shape alone doesn't carry the whole rule, though: a
\* model can overwrite the slot in place. OneOutstanding below closes that.
TypeOK ==
    /\ today \in {NoDay} \cup Days
    /\ swapped \subseteq Days
    /\ pending \in [Parents -> {NoDay} \cup Days]

\* Rule 5 in one line: a swapped day goes to the parent who wouldn't have
\* had it under the base pattern and the designations.
Custodian(d) == IF d \in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)

\* The graded interface. Every obligation below reads Observe and
\* subscripts on _Observe, not _vars. Here the two agree anyway, since with
\* two parents swapped is recoverable from the custodian field, but writing
\* against the interface is what lets a maintaining model grade the same.
\*
\* No field shows the swap set or the count. Both are derivable: a day
\* carries an agreed swap when its custodian differs from its scheduled
\* parent. A ledger field would push every model toward one representation
\* of the agreements, so the interface stays at outcomes.
Observe == [today |-> today,
            custodian |-> [d \in Days |-> Custodian(d)],
            pending |-> pending]

Init ==
    /\ today = NoDay
    /\ swapped = {}
    /\ pending = [p \in Parents |-> NoDay]

\* Half of the voiding fold. BeginDay clears every proposal naming the day
\* that begins, in the same step, and Accept below clears by day in the
\* same way. Rule 8 says voiding is immediate, and a separate Void action
\* makes it eventual instead: between cause and cleanup there are states
\* where a proposal names a begun day, and PendingFresh is false in every
\* one of them. The pilot hit that shape first. I'd expect this fold to be
\* the decision a reader is most tempted to unfold, and the spec breaks
\* visibly when they do.
BeginDay ==
    /\ today < H
    /\ today' = today + 1
    /\ pending' = [p \in Parents |->
                      IF pending[p] = today + 1 THEN NoDay ELSE pending[p]]
    /\ UNCHANGED swapped

\* Rule 7 as guards: one outstanding per parent (the NoDay guard), the day
\* hasn't begun (d > today, the 0-marker's payoff), and the day carries no
\* agreed swap. No guard says whose day it is: either parent can offer or
\* ask, and the swap's direction is fixed by the day, not the proposer.
\* Proposal and acceptance stay separate steps because Rule 6 says they
\* are, not for modeling convenience.
Propose(p, d) ==
    /\ pending[p] = NoDay
    /\ d > today
    /\ d \notin swapped
    /\ pending' = [pending EXCEPT ![p] = d]
    /\ UNCHANGED <<today, swapped>>

\* The other half of the voiding fold, and the same-day race. Both parents
\* can hold proposals naming one day, which Rule 6 makes the same swap.
\* Accepting p's proposal clears every proposal naming that day, not just
\* p's, so the loser is void the moment the winner lands. Clearing by
\* proposer would leave the loser standing on a swapped day, with
\* PendingFresh false until something else cleaned it up.
\*
\* The parameter is the proposer whose proposal resolves, not the parent
\* who accepts. Acceptance is the other parent's act, but no obligation
\* depends on whose hand moved, and an actor parameter doubles the action
\* space for zero observable difference.
Accept(p) ==
    /\ pending[p] # NoDay
    /\ Cardinality(swapped) < N
    /\ swapped' = swapped \cup {pending[p]}
    /\ pending' = [q \in Parents |->
                      IF pending[q] = pending[p] THEN NoDay ELSE pending[q]]
    /\ UNCHANGED today

\* Withdraw and decline, collapsed. They're distinct in the prose and one
\* event at the interface: the proposal is gone and custody didn't move. A
\* model with both produces the same observable behavior.
Drop(p) ==
    /\ pending[p] # NoDay
    /\ pending' = [pending EXCEPT ![p] = NoDay]
    /\ UNCHANGED <<today, swapped>>

Next ==
    \/ BeginDay
    \/ \E p \in Parents :
          \/ Accept(p)
          \/ Drop(p)
          \/ \E d \in Days : Propose(p, d)

\* Weak fairness on BeginDay and nothing else. Days begin on their own,
\* without either parent's leave, so the clock can't stall forever and
\* WindowCompletes holds on this one condition. The parents stay unfair on
\* purpose: nothing compels acceptance (Rule 6), and fairness on Accept
\* would quietly assert that something does. The window ending at
\* today = H is a deadlock by design, so deadlock checking stays off.
Spec == Init /\ [][Next]_vars /\ WF_vars(BeginDay)

\* Property 1. Against this model it holds by construction, since
\* Custodian is total. It earns its keep against maintaining models, which
\* can drop or double-assign a day.
TotalCustody == Observe.custodian \in [Days -> Parents]

\* Property 2. Reads Sched, not Scheduled, like every obligation below
\* that mentions the schedule. This and OpeningNoDayBegun are bare state
\* predicates listed under PROPERTIES, where TLC reads them as conditions
\* on the initial state. That channel was probed, not trusted: a false
\* opening predicate dies on the initial state (rc=13).
OpeningBaseline == \A d \in Days : Observe.custodian[d] = Sched(d)

\* Property 3, at most one flip per day, stated without counting flips.
\* The formula freezes any day sitting off its schedule. That renders
\* at-most-once through two facts the rest of the set supplies. The
\* baseline says every day opens on schedule. Two parents make off-schedule
\* and has-flipped the same set of days: a first flip must land off
\* schedule, and the freeze then holds, so no day moves twice. Two parents
\* also make any change a reversal, which is Rule 5's other half riding
\* free. None of that is visible in the formula, which is why the argument
\* sits next to it.
FlipOnce ==
    [][\A d \in Days :
          Observe.custodian[d] # Sched(d) =>
              Observe'.custodian[d] = Observe.custodian[d]]_Observe

\* Property 4. Custody moves only in a step where a proposal for that day
\* resolves. This is what the pending field exists for: without it a flip
\* has no visible cause and the rule is unstateable. What it doesn't say:
\* which resolution it was. A drop that flips is an acceptance at the
\* interface, and no obligation can tell them apart, because the actor
\* isn't observable.
FlipCause ==
    [][\A d \in Days :
          Observe'.custodian[d] # Observe.custodian[d] =>
              \E p \in Parents :
                  /\ Observe.pending[p] = d
                  /\ Observe'.pending[p] # d]_Observe

\* Property 5. Once a day has begun its custodian never changes. On the
\* variant matrix something else always fired first, but I wouldn't drop
\* it on that evidence: the set grades arbitrary models, and which
\* obligation TLC names is an accident of search order.
PastFixed ==
    [][\A d \in Days :
          d <= Observe.today => Observe'.custodian[d] = Observe.custodian[d]]_Observe

\* Property 6, and the obligation the voiding fold protects. An
\* outstanding proposal always names a future day whose custody is still
\* on schedule. Make voiding eventual anywhere and this goes false in the
\* gap states.
PendingFresh ==
    \A p \in Parents :
        \/ Observe.pending[p] = NoDay
        \/ /\ Observe.pending[p] \in Days
           /\ Observe.pending[p] > Observe.today
           /\ Observe.custodian[Observe.pending[p]] =
                  Sched(Observe.pending[p])

\* Rule 7's resolve-before-reproposing clause, added after the variant
\* matrix found the hole: drop Propose's NoDay guard and a proposal gets
\* overwritten in place, which nothing else here can see. This says an
\* outstanding proposal never changes day without passing through none.
\*
\* The antecedent is parenthesized on purpose. As a bare junction list
\* with => in the bullet column, the parse rests on the alignment rule
\* rather than on anything a reader can see, and a grading obligation
\* shouldn't rest on that.
OneOutstanding ==
    [][\A p \in Parents :
          (/\ Observe.pending[p] # NoDay
           /\ Observe'.pending[p] # NoDay)
              => Observe'.pending[p] = Observe.pending[p]]_Observe

\* Property 7. Counts days off the pinned schedule at the interface rather
\* than reading Cardinality(swapped), so it grades models that keep no
\* swap set at all.
CapRespected ==
    Cardinality({d \in Days : Observe.custodian[d] # Sched(d)}) <= N

\* Property 8. Once day H has begun, the window just plays out.
QuietAtEnd ==
    [][Observe.today = H => Observe' = Observe]_Observe

\* Property 9 in three pieces: the opening clause, the march, and the one
\* liveness obligation in the whole set.
OpeningNoDayBegun == Observe.today = NoDay

TodayMarches ==
    [][\/ Observe'.today = Observe.today
       \/ /\ Observe.today = NoDay
          /\ Observe'.today = 1
       \/ /\ Observe.today \in Days
          /\ Observe'.today = Observe.today + 1]_Observe

WindowCompletes == <>(Observe.today = H)

\* What the obligation set doesn't capture, on purpose: that anything ever
\* happens. Everything above except WindowCompletes prohibits, and
\* WindowCompletes only makes the clock run. No obligation can require
\* that a swap is reachable, because a prohibition can't refute a model
\* that does less, and fairness on Accept would misstate Rule 6. A model
\* whose swaps change nothing passes every obligation here.
\*
\* That isn't a guess. A blind solver in the review panel rediscovered it
\* with no access to our variant matrix: a no-op-swap rendering passes the
\* whole property set at the reference's own state count. The probes
\* directory beside this spec is the answer. Three must-fail invariants,
\* one per witness: the cap is reachable, and each parent can lose a
\* scheduled day. rc=12 is the pass. The signature of a dead model is rc=0
\* at the reference's full state count, a healthy space with an
\* unreachable witness, and neither half says it alone. Two flip probes,
\* not one, because a model that swaps every day toward A still moves the
\* B days, and only the direction carries the witness.

===============================================================================
