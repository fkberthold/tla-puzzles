---------------------------- MODULE EstateNotice ----------------------------
\* The estate-notice reference, commented after the freeze. The spec text is
\* the frozen EstateNotice.tla byte for byte, sha256
\* 331223e49296a1a96176f217492834a09561aebb007cc0e82a94740062bb02c5, and
\* harness/comment-gate.sh checks that claim rather than trusting it. Comments
\* are the only addition.
\*
\* Written for a reader who has already built a model against this system. The
\* notes cover decisions, not syntax: the representation and what it beat, each
\* action's atomicity boundary, and for every one of the nine obligations which
\* requirement it grades and which seeded variant it caught. The measurements
\* come from step2-variants.md and step6-spread.md under reports/, and the
\* rejected representations from author-notes/ALTERNATIVES.md.
\*
\* Where a note says a variant was caught, the number beside it is the trace
\* length TLC reported. Where it says nothing catches something, that's a run
\* that came back rc=0 and not a guess.

\* The people the estate owes. A fact of the domain first and a finiteness
\* device second: every obligation below holds for any finite instance. The
\* config picks 2, which is the least that shows a paid creditor and an
\* out-of-time creditor in one observation, and the least that shows one claim
\* holding up the distribution while another is already settled. That instance
\* runs 138 states generated, 77 distinct, graph depth 9.
CONSTANTS Creditors

\* Three variables, one per Observe field, and no fourth. Observe below renders
\* as the identity over them, so the state is the interface. There's no pc
\* either, which is why this ships as plain TLA+ actions rather than PlusCal.
\*
\* Rivals weighed and rejected:
\*
\* One stage variable, running over open, closed and distributed, in place of
\* notice and distributed. The strongest rival. The winding-up goes through
\* those three in order and never turns back, so one variable carries both
\* facts and the one-way doors fall out of the shape. Rejected because a stage
\* is a fourth kind of thing that no Observe field names, and the reference
\* would stop reading field for field. There's a smaller reason under that one.
\* Folding the two facts together makes requirements 5 and 6 true by
\* construction, and the two mutants written for them, S07 and S08, would have
\* had nowhere to bite.
\*
\* Four sets of creditors, lodged, admitted, rejected and paid, with
\* nothing-lodged as the complement. Every obligation then reads as membership,
\* which I think a lot of readers find easier than a function into strings.
\* Rejected because a creditor can land in two of the four at once. He stands
\* in one place, and I'd rather that be unrepresentable than be a property I
\* have to write.
\*
\* A partition of Creditors into six named sets, disjoint and covering, with
\* standing computed from it. The honest version of the previous idea, and it
\* keeps the one-place rule free. Rejected on the same clause as the stage: six
\* set variables aren't the three Observe fields, so standing becomes a derived
\* view. My hunch is it costs more than it buys anyway.
\*
\* notice as a BOOLEAN. Shorter, and it saves a line in TypeOK. The strings won
\* because requirement 2 reads better with them. Observe.notice = "closed" says
\* what happened, where the boolean makes a reader carry a negation through the
\* one obligation that puts the open case and the closed case side by side.
\* Cheap call, and I could be talked out of it.
\*
\* What has no variable at all. No amount owed and no size of residue: the
\* system never asks how much, so an amount is state the interface can't show
\* and no obligation could constrain. No clock and no period: she closes the
\* notice by her own act, and a period is a step this system would have to
\* assign to no party. No beneficiaries: Rule 4 moves the debt to them and
\* stops there, and modelling them means a second set of parties and a recovery
\* protocol. Whether they ever pay the late creditor is their business, and
\* this system doesn't watch it.
VARIABLES standing, notice, distributed

\* The stuttering subscript for the whole behaviour, and not the subscript any
\* obligation below uses. Those are all _Observe. The two happen to carry the
\* same information here, because Observe is the identity over vars, and I'd
\* rather they stayed textually apart. A model whose state grows past the
\* interface would need them apart, and a reader who learns the habit here
\* carries it there.
vars == <<standing, notice, distributed>>

\* Where a creditor can stand with the executor. Six places, fixed by Rule 1
\* rather than by the config, and one at a time by the shape of the function.
\* The one-place rule costs no property because nothing can record a second.
Standings == {"none", "lodged", "admitted", "paid", "rejected", "outOfTime"}

\* The two outcomes of a decision. Decide and ALodgedClaimEndsInHerDecision
\* both read this set, so the action and the obligation that grades it name the
\* same two words once. A variant that adds a third outcome has to change the
\* set, and then the obligation moves with it, which is the honest failure.
Decisions == {"admitted", "rejected"}

Notices == {"open", "closed"}

\* Her whole file, rendered as the identity over state. That rendering also
\* fixes the subscript for every action property below. See the note at
\* ADecisionStands for what a narrow subscript costs, measured.
Observe == [standing |-> standing, notice |-> notice, distributed |-> distributed]

\* A definition, not a behaviour: a claim she still has to deal with. Reads the
\* variable rather than Observe, because it's a guard and not an obligation.
\*
\* SheDistributesOnlyWhenClear spells the same two words out again instead of
\* calling this. That's deliberate. The obligation would otherwise grade the
\* guard against its own definition, and the two would move together under any
\* mutation of Unsettled. Step 6 found a sharper reason: read "lodged" in Rule
\* 7 as the standing rather than as brought-to-her and the invariant becomes a
\* single # "lodged" test, which lets her distribute over an admitted claim. A
\* panel seat wrote that model. Spelling both words out is what keeps the
\* reference's own reading visible.
Unsettled(c) == standing[c] \in {"lodged", "admitted"}

\* Nothing lodged, notice open, residue in hand. No obligation constrains the
\* opening and that was a deliberate spend: the count band had one line spare
\* and the reference held it for requirement 8 instead.
\*
\* The opening isn't ungraded, though. It's graded a layer up. S25 starts every
\* creditor lodged and S26 starts the notice closed, and both come back rc=0
\* against all nine obligations here. harness/vacuity.sh then catches both at
\* rc=5, VACUOUS_DEAD_ACTION, because a wrong opening leaves actions
\* permanently disabled: S25 starves Lodge and ComeForward, S26 starves Lodge,
\* Close, Decide and Pay. I'd stop short of saying every bad opening lands that
\* way. These two starve an action, and one that didn't wouldn't be seen.
Init ==
    /\ standing = [c \in Creditors |-> "none"]
    /\ notice = "open"
    /\ distributed = FALSE

\* One creditor, one claim, one step, inside the window. The atomicity boundary
\* is the single claim: he lodges his own, nobody lodges on his behalf, and the
\* notice and the residue hold still while he does it.
\*
\* The standing[c] = "none" guard carries three rules at once. He lodges once,
\* there's no second claim and no amendment, and there's no withdrawal, because
\* nothing in Next takes him back to "none" for a re-lodge to start from.
\*
\* S03 drops the notice = "open" guard and ClaimsStartWithTheCreditor catches it
\* in 3 states. S15 guards on {"none", "rejected"} so a rejected creditor can
\* lodge again with better evidence, which is real practice and which is
\* ambiguity 4 in the description. ADecisionStands catches that one in 4.
Lodge(c) ==
    /\ notice = "open"
    /\ standing[c] = "none"
    /\ standing' = [standing EXCEPT ![c] = "lodged"]
    /\ UNCHANGED <<notice, distributed>>

\* The late step, and it's his act rather than hers. That's ambiguity 5 and it's
\* the one that keeps the state this domain exists for: a closed notice with a
\* creditor still able to surface. S16 sweeps every unlodged creditor out of
\* time at the moment she closes, which makes the late appearance her doing, and
\* ClaimsStartWithTheCreditor catches it in 2 states.
\*
\* No guard on distributed, per Rule 8. He can still come forward after the
\* residue has gone, because by then he's coming forward against the
\* beneficiaries. I checked that reading rather than trusting it, and the check
\* corrected the argument I'd made for it. ALTERNATIVES.md says barring the late
\* step would cut the distributed layer from four places per creditor to three.
\* S22 bars it and comes back at 77 distinct, the reference's own count, with
\* 130 generated against 138. So the late step buys generated states and no
\* distinct ones, because a creditor can reach out of time before the
\* distribution with the notice closed and the residue still in hand. The
\* decision stands. The reason I gave for it didn't.
\*
\* S24 guards this on the notice being open instead, and
\* ClaimsStartWithTheCreditor catches it in 2 states.
ComeForward(c) ==
    /\ notice = "closed"
    /\ standing[c] = "none"
    /\ standing' = [standing EXCEPT ![c] = "outOfTime"]
    /\ UNCHANGED <<notice, distributed>>

\* Her act alone, one field, no period and no clock. Nothing else closes the
\* notice and nothing reopens it.
\*
\* Who acts is invisible at this interface, and the counts prove it rather than
\* argue it. S28 gives Close a creditor parameter, so a creditor closes her
\* notice, and it comes back rc=0 at 77 distinct, identical to the reference.
\* Generated moves from 138 to 163, which is the same close reached through two
\* witnesses. No property over Observe will ever say who took a step, whatever
\* fields get added. What the interface does carry is that the close happened
\* and that nothing lodged after it, which is requirements 5 and 2.
Close ==
    /\ notice = "open"
    /\ notice' = "closed"
    /\ UNCHANGED <<standing, distributed>>

\* One claim, one decision, one step. No guard on the notice: she can decide
\* while it's still open, which is ambiguity 8 and half of what makes the rung
\* new, because it's what puts her steps and the creditors' steps in each
\* other's way. S18 makes her wait for the close. That's a restriction, so
\* nothing here catches it, and it drops the space from 77 distinct to 56.
\*
\* d is drawn from Decisions rather than split into Admit(c) and Reject(c). The
\* split reads closer to Rule 5, which names admitting and rejecting apart. The
\* parameterized form won on where the fairness has to sit: requirement 7 wants
\* a conjunct on deciding a named creditor's claim, and under the split that
\* conjunct becomes a disjunction of two actions, which obliges neither.
\* DecideStep(c) below is the one named step that shape needs.
\*
\* S06 guards on {"lodged", "admitted"} so an admitted claim can turn rejected,
\* and ADecisionStands catches it in 4 states. S19 adds a disjunct deciding two
\* creditors in one step, and SheTakesOneClaimAtATime is the obligation that
\* exists for it. See the note there.
Decide(c, d) ==
    /\ standing[c] = "lodged"
    /\ standing' = [standing EXCEPT ![c] = d]
    /\ UNCHANGED <<notice, distributed>>

DecideStep(c) == \E d \in Decisions : Decide(c, d)

\* Its own act, after the admission, never in the same motion. That's ambiguity
\* 7, and the alternative collapses admitted and paid into one standing, which
\* would make Rule 6 true by construction rather than something a step can get
\* wrong.
\*
\* S17 adds a disjunct taking a lodged claim straight to paid, and S23 lets her
\* pay a claim that's still only lodged. ALodgedClaimEndsInHerDecision catches
\* both, each in 3 states.
Pay(c) ==
    /\ standing[c] = "admitted"
    /\ standing' = [standing EXCEPT ![c] = "paid"]
    /\ UNCHANGED <<notice, distributed>>

\* The terminal act, and the only one with three guards. Notice closed, nothing
\* distributed yet, every claim she holds settled. It happens once and it's
\* total: no partial distribution, no interim payment, no way to call it back.
\*
\* Each guard has its own seeded variant. S01 drops the settled conjunct and
\* SheDistributesOnlyWhenClear catches it in 4 states. S02 drops the closed
\* guard, same obligation, 2 states. S20 drops the distributed = FALSE guard so
\* she can distribute twice, and nothing catches it, because the second firing
\* leaves all three variables where they were. That's a stutter under
\* [Next]_vars: 154 generated against 138, and 77 distinct either way.
\*
\* Nothing is enabled once this fires and every creditor has settled or gone
\* out of time, so the system stops there. The config takes CHECK_DEADLOCK
\* FALSE. The alternative is a stuttering action for the executor once she's
\* finished, and inventing a step this system doesn't have, to quiet a checker,
\* puts a lie in the transition relation.
Distribute ==
    /\ notice = "closed"
    /\ distributed = FALSE
    /\ \A c \in Creditors : ~Unsettled(c)
    /\ distributed' = TRUE
    /\ UNCHANGED <<standing, notice>>

\* Two parties and six actions. Hers are Close, Decide, Pay and Distribute.
\* The creditors have Lodge and ComeForward. Nothing coordinates them, so any
\* creditor's step can land between any two of hers.
\*
\* Every disjunct frames the two Observe fields it doesn't touch, so no step
\* here ever moves two fields at once. That's the reference's own restraint and
\* nothing in the nine obligations grades it. Step 6's panel found the hole: a
\* model that closes the notice and lodges a claim in one motion passes all
\* eight requirements. Requirement 2 sees the notice open before the step and
\* is satisfied, requirement 5 sees it open and says nothing, and requirement 8
\* watches creditors against each other rather than fields. The allowed runs
\* don't catch it either, since they test that a model can produce eight runs
\* and never that it produces no more. I think that's a real gap in the
\* requirement set rather than a wording slip.
Next ==
    \/ Close
    \/ Distribute
    \/ \E c \in Creditors : Lodge(c)
    \/ \E c \in Creditors : ComeForward(c)
    \/ \E c \in Creditors : DecideStep(c)
    \/ \E c \in Creditors : Pay(c)

\* Rule 9 as a fairness decision. She owes the winding-up, so four conjuncts
\* name four of her steps one at a time. The creditors owe nobody anything, so
\* nothing sits on Lodge or ComeForward, and their freedom is carried by that
\* absence rather than by a property.
\*
\* All four are load-bearing, one at a time, and each drop breaks requirement 7
\* at a different length. S11 drops the DecideStep conjunct and breaks at 5.
\* S10 drops WF_vars(Close) and S12 drops the Pay conjunct, both at 7. S13
\* drops WF_vars(Distribute) at 9. P03 drops all four and breaks at 6.
\*
\* Two weaker forms pass anyway, and neither is catchable by any property here.
\* Blanket WF_vars(Next) comes back rc=0 at the reference's own 138 generated
\* and 77 distinct (P04). One WF over the disjunction of her four kinds of step
\* passes the same way, at the same counts, and it's closer to right, which
\* makes it harder to spot by eye. Both work for the same structural reason:
\* every action here permanently disables itself and Creditors is finite, so
\* the graph is a finite DAG, and no terminal state holds the residue, because
\* if nothing else is enabled then distributing is. So the fairness question is
\* real and the model can't be where it gets asked. It has to be asked in the
\* statement.
\*
\* One trap worth naming here, because it's the same conjuncts read the other
\* way. S09 drops Distribute from Next and leaves WF_vars(Distribute) in place.
\* Every obligation comes back green at 61 distinct, and harness/vacuity.sh
\* returns rc=7, VACUOUS_UNSATISFIABLE. A learner who deletes an action and
\* keeps its fairness hands in a spec that passes everything, and the passing
\* run means only that there was nothing left to fail.
Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(Close)
    /\ \A c \in Creditors : WF_vars(DecideStep(c))
    /\ \A c \in Creditors : WF_vars(Pay(c))
    /\ WF_vars(Distribute)

\* ---------------------------------------------------------------------
\* The obligations. Nine in the config, which is the top of the five-to-nine
\* band and the whole of what this system asks for. Eight of them are the
\* learner's requirements one for one. TypeOK is the reference author's and is
\* never a learner requirement.
\*
\*   state invariants   TypeOK, SheDistributesOnlyWhenClear (requirement 1)
\*   action properties  ClaimsStartWithTheCreditor (2),
\*                      ALodgedClaimEndsInHerDecision (3),
\*                      ADecisionStands (4), TheNoticeNeverReopens (5),
\*                      TheDistributionIsNeverUndone (6),
\*                      SheTakesOneClaimAtATime (8)
\*   liveness           TheEstateIsEventuallyDistributed (7), the only one
\*
\* Every action property is subscripted _Observe, the whole record, never one
\* field. The note at ADecisionStands carries the measurement behind that.
\* ---------------------------------------------------------------------

\* Shape only, and the reference author's own line rather than a requirement.
\* The six standings are a rule of the system, and this is where they become a
\* real cfg line instead of a shape argument.
\*
\* Caught: S14 adds a disjunct writing a seventh standing, at 2 states. That's
\* the only variant TypeOK caught in the whole matrix, and it's the one written
\* to break TypeOK, so nothing here is caught for the wrong reason.
TypeOK ==
    /\ Observe.standing \in [Creditors -> Standings]
    /\ Observe.notice \in Notices
    /\ Observe.distributed \in BOOLEAN

\* Requirement 1, and the only obligation about a single state besides TypeOK.
\* Both halves of Rule 7's gate: the notice is closed, and no claim she holds is
\* still live. The second half is spelled out as \notin {"lodged", "admitted"}
\* rather than through Unsettled, for the reason in the note at Unsettled.
\*
\* This is the workhorse of the matrix. S01 distributes with a claim still
\* lodged, 4 states. S02 distributes while the notice is open, 2 states. S27
\* opens with the residue already gone and is reported against the initial
\* state with no trace at all, which makes it the cheapest catch in the matrix
\* and a poor one to show anybody.
\*
\* It also catches things it wasn't written for, and that's worth knowing
\* before reading any green run as evidence. P01S03 and P02S07 both weaken
\* another property's subscript over a variant that property was meant to
\* catch, and both come back on this invariant instead, because S03 and S07
\* each break it too and it sits earlier in the search.
SheDistributesOnlyWhenClear ==
    Observe.distributed =>
        /\ Observe.notice = "closed"
        /\ \A c \in Creditors :
               Observe.standing[c] \notin {"lodged", "admitted"}

\* Requirement 2, the way in, and the only obligation that reads the notice and
\* a standing together. A creditor moves off "none" to exactly one of two
\* places, and which one is settled by the notice before the step. It's also
\* what stops a creditor appearing as admitted, rejected or paid without ever
\* having lodged, since neither disjunct offers those.
\*
\* Caught: S03 lodging after the close, 3 states. S04 an extra disjunct taking
\* a creditor from none straight to admitted, 2 states. S16 the sweep at the
\* close, 2 states. S24 coming forward while the notice is still open, 2
\* states.
\*
\* What it doesn't carry: which party moved him. Nothing over Observe can.
ClaimsStartWithTheCreditor ==
    [][\A c \in Creditors :
          (Observe.standing[c] = "none" /\ Observe'.standing[c] # "none") =>
              \/ /\ Observe.notice = "open"
                 /\ Observe'.standing[c] = "lodged"
              \/ /\ Observe.notice = "closed"
                 /\ Observe'.standing[c] = "outOfTime"]_Observe

\* Requirement 3. A lodged claim has exactly two exits, and both of them are
\* hers. Stated as a constraint on the step that moves it rather than on where
\* it ends up, so a claim that leaves "lodged" for anywhere else breaks it at
\* once instead of at the end of the run.
\*
\* Caught: S05 an extra disjunct withdrawing a lodged claim back to none, 3
\* states. S17 lodged straight to paid in one motion, 3 states. S23 paying a
\* claim she never admitted, 3 states.
ALodgedClaimEndsInHerDecision ==
    [][\A c \in Creditors :
          (Observe.standing[c] = "lodged" /\ Observe'.standing[c] # "lodged") =>
              Observe'.standing[c] \in Decisions]_Observe

\* Requirement 4, the finality rule, and the one place on this problem where a
\* wrong subscript is graded by the property it belongs to. Admitted has one
\* exit, to paid. Rejected, paid and out of time have none.
\*
\* Caught: S06 turning an admitted claim rejected, 4 states. S15 re-lodging
\* after a rejection, 4 states.
\*
\* The subscript. Every action property here is subscripted on the whole of
\* Observe, and the escape a narrow subscript buys was measured three ways.
\* ISO03, ISO06 and ISO07 each catch their variant in isolation at rc=13, and
\* the weakened form of each catches nothing at rc=0. The state counts say it
\* from the other side: ISO03W explores 97 distinct against S03's 6 before the
\* violation, so the weakened property isn't stopping the search at all.
\*
\* Two of those three still get caught, by SheDistributesOnlyWhenClear sitting
\* earlier in the search, which is incidental coverage and no comfort. This one
\* is the clean case. P05S06 subscripts this property on distributed and misses
\* S06 outright at rc=0, with all 77 states explored and nothing else catching
\* it. TLC reports green and warns about nothing.
ADecisionStands ==
    [][\A c \in Creditors :
          /\ (Observe.standing[c] = "admitted" =>
                  Observe'.standing[c] \in {"admitted", "paid"})
          /\ (Observe.standing[c] \in {"rejected", "paid", "outOfTime"} =>
                  Observe'.standing[c] = Observe.standing[c])]_Observe

\* Requirement 5, one of the two one-way doors. Caught: S07, an extra disjunct
\* taking a closed notice back to open, 3 states.
\*
\* This is one of the two the stage-variable representation would have made
\* true by construction. Under one ordered stage there's no step that could
\* break it, and an obligation that can't fail grades nothing.
TheNoticeNeverReopens ==
    [][Observe.notice = "closed" => Observe'.notice = "closed"]_Observe

\* Requirement 6, the other one-way door, and the one the screening pass left
\* out. It graded the notice against reopening and left the distribution
\* ungraded, so an estate could be un-distributed and nothing would notice.
\*
\* Caught: S08, an extra disjunct setting distributed' false, 4 states.
TheDistributionIsNeverUndone ==
    [][Observe.distributed => Observe'.distributed]_Observe

\* Requirement 7, the only liveness obligation, and the only item that needs
\* "eventually". It reads one field and says nothing about how the residue gets
\* there, which is the point: the winding-up has to finish, and every step of
\* it is hers to time.
\*
\* Caught: S10, S11, S12 and S13, one dropped fairness conjunct each, at 7, 5,
\* 7 and 9 states. P03 drops all four at 6. Each violation is a lasso, a finite
\* prefix and then the behaviour stuttering there forever. S10's is the stall
\* Rule 9 exists to rule out: the notice open, nothing lodged, and the executor
\* never closing.
\*
\* One more thing this obligation swallowed rather than left out. The screening
\* pass offered a second liveness item, that every claim lodged before the
\* close is eventually paid or rejected. It's implied by this one under the
\* safety rules, because distributing needs every lodged claim settled and
\* nothing can be lodged after the close. A redundant cfg line teaches nothing,
\* so it went.
TheEstateIsEventuallyDistributed == <>Observe.distributed

\* Requirement 8, and the newest of the nine. Rule 5 says she takes one claim at
\* a time, and until this line landed nothing graded it. S19 decides two
\* creditors in one step and passes requirements 1 through 7 at rc=0, because 2,
\* 3 and 4 hold for both creditors and no other item reads a step at all. With
\* this line S19 comes back rc=13 at 4 states: both creditors lodge, then one
\* act settles both.
\*
\* It's the only variant in the matrix that breaks this obligation, and adding
\* it moved nothing else. The reference stayed at 138 generated and 77 distinct,
\* and the other 35 variants came back on the obligations they came back on
\* before.
\*
\* Worth the line under shape A, where the learner writes the whole store. A
\* batch decision is the kind of thing somebody writes by accident when they
\* reach for a set.
SheTakesOneClaimAtATime ==
    [][\A a \in Creditors :
          \A b \in Creditors :
              (/\ a # b
               /\ Observe.standing[a] # Observe'.standing[a])
                  => Observe.standing[b] = Observe'.standing[b]]_Observe

\* ---------------------------------------------------------------------
\* What this obligation set deliberately can't carry, and one thing it can't
\* carry that I wish it could. Everything below was measured rather than
\* reasoned to, and the runs are in step2-variants.md section 5.
\*
\* Who acts. Observe shows the file, not the hand that wrote in it. S28 lets a
\* creditor close her notice and comes back at the reference's own 77 distinct.
\* No field you could add would change that, because the interface is what the
\* executor can read off her own papers, and her papers don't record who was
\* in the room.
\*
\* Permissions. "She may decide while the notice is open" asserts that a
\* behaviour exists. Safety and liveness constrain the behaviours that do
\* exist, so neither kind can demand one. S18 makes her wait for the close and
\* passes everything at 56 distinct against 77. S21 obliges the creditors to
\* lodge and S22 bars the late step, and both pass at 77. Three restrictions,
\* three structural misses.
\*
\* Idempotence. S20 lets her distribute twice. The second firing leaves all
\* three variables where they were, so it's a stutter under [Next]_vars and
\* generates no distinct state. The representation carries the rule, so no
\* property has to.
\*
\* The fairness form. Blanket WF_vars(Next) passes, and so does one WF over the
\* disjunction of her four kinds of step. No property change catches either,
\* because it's a claim about which behaviours Spec admits and both forms admit
\* a superset with the same violation-free part. The catch has to happen in the
\* statement.
\*
\* The opening. Nothing here constrains Init. Two bad openings, S25 and S26,
\* pass all nine and are caught a layer up by harness/vacuity.sh at rc=5,
\* because each starves an action. An opening that starved nothing wouldn't be
\* seen, and nobody has built one.
\*
\* A step that moves two Observe fields at once. This is the one I'd rather
\* have. Closing the notice and lodging a claim in one motion passes all eight
\* requirements, and the note at Next says why each of them looks away. It
\* belongs in the grading split rather than in a tenth cfg line, since the line
\* would be about the shape of a step and not about the winding-up.
\*
\* Ground truth. Whether a creditor is really owed anything is outside the
\* interface. She never knows, so the model never says.
\* ---------------------------------------------------------------------
=============================================================================
