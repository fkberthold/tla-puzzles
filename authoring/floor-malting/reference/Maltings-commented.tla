----------------------------- MODULE Maltings -----------------------------
\* The floor-malting reference, commented after the freeze. The spec text is
\* the frozen Maltings.tla byte for byte, and harness/comment-gate.sh checks
\* that claim rather than trusting it. Comments are the only addition.
\*
\* Frozen sha256 of Maltings.tla:
\*   23d6cd110905089af76a477f81a3671e0e14a38ebba35151ae6dd8491c547f07
\*
\* Written for a reader who has already built a model of this system. The
\* notes cover decisions, not syntax: the state and its rejected rivals, the
\* atomicity boundary of each action, which requirement each obligation
\* grades and which measured variant it catches, and the rules nothing here
\* can carry. Requirement numbers are PROBLEM.md's, one to seven.
\*
\* Measurements come from step2-variants.md and step6-spread.md in
\* authoring/floor-malting/reports/. Variant ids read S01 to S25 for the
\* system mutations and P01 to P06 for the property ones.
EXTENDS Naturals

\* Four of the five are the description's bounds, and they carry the domain
\* rather than the state space. Every obligation below has to hold for any
\* finite instance. The shipped config picks 3 pieces, 2 maltsters, a lower
\* mark of 1 and an upper mark of 3: the least that puts one piece in each of
\* the three places at once, over a window a piece can sit inside for two
\* turnings and then fall out of.
\*
\* NoCount is the fifth, and it's the one constant that isn't a bound. It's
\* the marker a piece carries once it's off the floor, and it's declared here
\* so the cfg can bind it as a model value (NoCount = NoCount).
\*
\* Why a model value and not a string. The first draft used "none". TLC
\* refuses it. "none" \in Nat raises "Attempted to check if the value "none"
\* is an element of Nat", and reordering the disjunction moves the failure to
\* 0 = "none", which raises "Attempted to check equality of integer 0 with
\* non-integer". Both are evaluation errors rather than property violations,
\* so the run comes back TLC_EXCEPTION at rc=255 and says nothing about the
\* model. A model value compares FALSE against any other value without
\* complaint, so the same states fail cleanly instead of stopping the run.
\*
\* The rival I looked at was making the field a set, {n} on the floor and {}
\* off it. Set equality never raises, so it works. I rejected it because the
\* field stops being a count. A singleton set is a container for the number
\* instead of the number, and the description says a floor piece's
\* modification is how many times it's been turned. Costing a constant is
\* cheaper than costing the field its meaning.
CONSTANTS Pieces, Maltsters, LowerMark, UpperMark, NoCount

\* The window has to be a window. Set the marks equal and every piece is a
\* loss, GoodMaltComesFromReady is vacuous, and the instance grades nothing.
\*
\* What this ASSUME leaves out, and it's a real gap rather than a choice.
\* Nothing here says Maltsters is non-empty. An empty Maltsters enables no
\* step at all, makes both fairness conjuncts vacuous, and fails requirement
\* 7 while every safety obligation holds. Two of the three step-6 seats found
\* that blind, one by reasoning and one by writing the assumption into its
\* own module without remarking on it. I'd add the clause.
ASSUME /\ LowerMark \in Nat
       /\ UpperMark \in Nat
       /\ LowerMark < UpperMark

\* Two functions over Pieces, a place and a count. Observe renders as the
\* identity over them, field for field, so the state is the interface. That's
\* what this rung's representation level asks for, and it's why there's no
\* third variable, no history variable and no pc.
\*
\* Rivals weighed and rejected:
\*
\* A partition of Pieces into three named sets instead of a status function.
\* Isomorphic to what's here, and it lands on the same 216 states. The
\* function form wins because a piece has one stage value and there's
\* nowhere to record a second, so "a kilned piece is good or lost, never
\* both" is carried by the shape and costs no obligation. Under a partition
\* that rule needs a disjointness invariant to hold it.
\*
\* A sequence or a set of turnings instead of a counter. A sequence of
\* identical turnings is determined by its length, so it's the counter
\* wearing more syntax, and it reaches the same 216 states.
\*
\* A stored gone-over flag the step rules read. That's a third variable and
\* not an Observe field, so it's out at this representation level. It also
\* only adds states. The description leaves the flag open as a learner's
\* choice, and this module doesn't take it.
\*
\* A PlusCal process set over Maltsters. A set of maltsters with a single
\* loop label still carries a pc, and a pc is a third variable that isn't a
\* field. So Init, Next and Spec are written by hand. The cost is that the
\* module reads less like the ch.11 material, and nobody ships this one to a
\* learner.
\*
\* What has no variable at all. The kiln, which is outside the system and
\* takes any piece at any time. Who acted, since Observe shows the floor and
\* not the hands on it. And temperature, moisture and hours, because Rule 2
\* fixes modification as a count of turnings by fiat and says so. Real
\* modification is continuous, and continuous takes the state space past
\* what this rung can hold.
VARIABLES stage, modification

vars == <<stage, modification>>

\* Three places, and a piece is in exactly one. The type invariant is what
\* holds the set, and S21 (a fourth value, "binned") is what proves it does.
Stages == {"floor", "malt", "loss"}

\* The whole public face of the floor, rendered as the identity over state.
\* That rendering also fixes the subscript for every action property below.
\* The subscript names the state whose stutter a step property forgives, so
\* it has to be _Observe, the whole record, on all four of them. Subscript
\* one on the stage field alone and every turning slips past. Subscript it
\* on the count alone and every piece leaving the floor slips past. Both
\* directions are measured, at OnePairOfHands and at OffTheFloorIsFinal.
Observe == [stage |-> stage, modification |-> modification]

\* A definition, not a behavior. Both marks in one line: at or above the
\* lower and strictly below the upper. No obligation constrains Ready
\* directly, and the behavior it feeds is graded at GoodMaltComesFromReady.
\*
\* It reads modification arithmetically, so every call site has to sit behind
\* a guard on the piece being down on the floor. There's one call site, in
\* Kiln, and the guard is Kiln's first conjunct. Call it on an off-floor
\* piece and the comparison meets NoCount, which aborts the run rather than
\* returning FALSE. The note on Turn's guard order carries the measurement.
Ready(p) == modification[p] >= LowerMark /\ modification[p] < UpperMark

\* Every piece down on the floor, unturned. There's no steeping step and no
\* spreading step, so this is the only way a piece ever gets onto the floor.
\* That matters twice over: Opening grades it, and OffTheFloorIsFinal then
\* closes the only other route in. See the note at OffTheFloorIsFinal.
Init ==
    /\ stage = [p \in Pieces |-> "floor"]
    /\ modification = [p \in Pieces |-> 0]

\* One maltster, one piece, one turning, one step. The atomicity boundary is
\* the turning, and there's nothing smaller to interleave inside it. Two
\* maltsters can't act at once, and OnePairOfHands is what grades that.
\*
\* The guard order is load-bearing and not cosmetic. The floor guard has to
\* come before the arithmetic. Drop it (variant S19) and a maltster can turn
\* a piece that's already gone to the kiln, whose count is NoCount, so
\* NoCount < UpperMark raises "The first argument of < should be an integer"
\* and the run ends TLC_EXCEPTION at rc=255 after 13 states.
\*
\* Note what that costs. OffTheFloorIsFinal would have caught the behavior.
\* It never got the chance, because the abort happens inside the next-state
\* relation before any property is evaluated. V2-PLAN §5.1 reads rc=255 as
\* the check never happening rather than as a violation, so a tutor calling
\* it a violated property would be making the exact false statement §5.1
\* exists to stop.
\*
\* The ceiling guard is Rule 3, and it's a fact of the system rather than a
\* finiteness device. A matted bed is one solid slab and a shovel won't break
\* it up. It's also the only thing bounding the count, which is what lets
\* TypeOK say Nat with no ceiling. See the note there.
Turn(m, p) ==
    /\ stage[p] = "floor"
    /\ modification[p] < UpperMark
    /\ modification' = [modification EXCEPT ![p] = @ + 1]
    /\ UNCHANGED stage

\* The piece leaves the floor and its count goes in the same step. That's the
\* atomicity boundary, and it's the whole of ambiguity 15: the count belongs
\* to the bed lying on the stones and it goes when the bed does. The live
\* alternative keeps the count after the kiln, which costs requirement 2 its
\* second clause and leaves requirement 6 to freeze the count instead. I'd
\* take the drop, because it makes requirement 2 one rule rather than two.
\*
\* The outcome falls out of Ready at the moment of the step, so a green piece
\* and a matted piece both come out as a loss and the fuel is wasted. The
\* kiln itself is outside the system. Nothing about it is modeled and nobody
\* there acts, which is what keeps floor capacity and kiln capacity out of a
\* problem that would otherwise turn into allocation.
\*
\* Ready(p) sits behind this action's first conjunct. That's the guard the
\* note on Ready is about.
Kiln(m, p) ==
    /\ stage[p] = "floor"
    /\ stage' = [stage EXCEPT ![p] = IF Ready(p) THEN "malt" ELSE "loss"]
    /\ modification' = [modification EXCEPT ![p] = NoCount]

\* Always a loss, whatever the count. Same boundary as Kiln.
\*
\* This is the action that carries the least, and the numbers say so. In the
\* reference's own coverage table it fires 882 times and discovers 0 new
\* states, because a kilning of a green piece and a throwing out of the same
\* piece land on the same record. That row is also the sharpest live case for
\* the dead-action predicate being total == 0 rather than distinct == 0. Read
\* the wrong column and the reference reports one of its own actions dead.
\*
\* Two variants confirm the exit is unobservable. S23 gives a throwing out
\* the kiln's outcome rule, and S24 deletes this action and routes Remove
\* through Kiln alone. Both come back rc=0 against all eight obligations, at
\* the reference's own 216 distinct states. Observe carries where a piece
\* went and not how it got there, so no property over Observe can separate
\* the two exits, and Rule 5's claim that a throwing out is always a loss
\* grades nothing on its own. The description predicts a reviewer will hunt
\* for the missing property. Consider it hunted.
\*
\* One consequence for whoever runs the grader. S24 is a model the
\* description permits outright, so a vacuity run passing
\* --expect-actions Turn,Kiln,ThrowOut refuses a correct submission, and
\* refuses it with a message telling the learner to put ThrowOut back. Demand
\* Turn and nothing else, or pass no list at all.
\*
\* I kept two acts anyway. GoodMaltComesFromReady reads as a claim about the
\* kiln, and a reader tracing it back wants an action with that name to land
\* on. With one act, Rule 5 has nowhere to live at all.
ThrowOut(m, p) ==
    /\ stage[p] = "floor"
    /\ stage' = [stage EXCEPT ![p] = "loss"]
    /\ modification' = [modification EXCEPT ![p] = NoCount]

\* The two ways off the floor, named as one step so the fairness conjunct has
\* something to sit on. Both acts have the same effect on the piece, so the
\* disjunction still obliges something. Splitting it into two per-act
\* conjuncts would oblige more than the description asks, because it would
\* force every piece through both exits.
Remove(m, p) == Kiln(m, p) \/ ThrowOut(m, p)

\* One kind of party, several of them, interleaving freely. No clock, no
\* calendar, and no step that happens on its own.
\*
\* Nothing indexes state by a maltster, so m is a parameter the actions carry
\* and never read. Dropping it gives the same reachable graph and the same
\* 216 distinct states, and one of the three step-6 seats did exactly that.
\* It changes the generated count, 2,377 against 1,189, and leaves no mark on
\* the distinct count. I kept the quantifier because the rung's step-sources
\* level is read off the parties in the module, and an action with no
\* maltster in it leaves that reading with nothing to cite. It also keeps
\* Turn(m, p) honest about who turns a piece.
Next ==
    \E m \in Maltsters, p \in Pieces :
        \/ Turn(m, p)
        \/ Remove(m, p)

\* Rule 7 lands as fairness, and the form is a decision. Weak fairness per
\* piece, on any maltster's act of taking that piece off the floor. A
\* maltster can take his time and leave a piece lying as long as he likes,
\* and he can't leave it lying forever.
\*
\* Four forms were measured against the shipped obligations, and they reject
\* only one. The reference is rc=0. WF_vars(Next) is rc=0, and so is per
\* maltster on any act of that maltster, and so is per piece on the kilning
\* alone. No fairness at all is rc=13, and per piece on the turning alone is
\* rc=13 at 7 states and a stutter, because a piece sits at UpperMark on the
\* floor forever.
\*
\* So the obligations can't insist on the per-piece form, and the reason for
\* preferring it is pedagogical rather than gradeable: it names a step the
\* reader can point at. WF_vars(Next) clears the floor here for a real
\* reason. Rule 3 caps the turnings a piece can take, so only finitely many
\* acts can be turnings and the rest take a piece off. That argument is sound
\* and the reader has to rebuild it before the conjunct means anything. This
\* problem is shape A, so the learner writes Spec and picks the fairness, and
\* three correct answers are three correct answers.
\*
\* What the pair of measurements does pin down is that the conjunct has to
\* name the removal. That much is graded.
Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ \A p \in Pieces : WF_vars(\E m \in Maltsters : Remove(m, p))

\* ---------------------------------------------------------------------
\* The obligations. Eight lines in the cfg: the seven requirements plus the
\* type invariant, which is the reference author's and is never something a
\* learner is asked to produce. The kind decisions carry more of the judgment
\* than the formulas do.
\*
\*   state invariants   TypeOK, CountBelongsToTheFloor
\*   opening condition  Opening (a PROPERTY, not an INVARIANT)
\*   action properties  OnePairOfHands, TurningAddsOne,
\*                      GoodMaltComesFromReady, OffTheFloorIsFinal
\*   liveness           TheFloorGetsCleared, the only one
\*
\* Every one of the eight has an arrow, and each fires on the channel §9.5
\* predicts: the two invariants at rc=12 and the six properties at rc=13.
\* Nothing is caught by TypeOK standing in for a rule it doesn't state.
\* ---------------------------------------------------------------------

\* Shape only, and no requirement. It's the eighth cfg line and it grades
\* none of the seven. It catches S21, a throwing out that lands a piece in a
\* fourth place, at rc=12 in 2 states.
\*
\* Two things it deliberately does not do.
\*
\* It doesn't tie the count to the place. It allows a floor piece carrying
\* NoCount and an off-floor piece carrying 2, and CountBelongsToTheFloor is
\* what rules both out. Folding the tie in here would be tidier to read, and
\* it would make requirement 2's first and third clauses true before the
\* learner writes anything.
\*
\* It doesn't cap the count. A modification is a count of turnings and
\* counting has no ceiling. What stops it is Rule 3's guard on Turn, which is
\* a rule of the system rather than a fact about numbers, and the space stays
\* at 216 either way. Type the field 0..UpperMark and drop requirement 2's
\* ceiling clause (variant P05) and the reference still passes, and S03, a
\* turning with no ceiling guard, is still caught at rc=12. So the trap
\* doesn't cost the catch. It costs the obligation: requirement 2's ceiling
\* becomes true by construction, the learner writes TRUE in a costume, and
\* the arrow that fires belongs to the type invariant they were never asked
\* to produce.
TypeOK ==
    /\ Observe.stage \in [Pieces -> Stages]
    /\ DOMAIN Observe.modification = Pieces
    /\ \A p \in Pieces :
           \/ Observe.modification[p] = NoCount
           \/ Observe.modification[p] \in Nat

\* Requirement 2, both halves in one rule. A piece down on the floor has a
\* count and it's never above the upper mark. A piece off the floor has no
\* count at all. It catches S04, a kilning that keeps the count, at rc=12 in
\* 2 states, and it's the arrow for S03, S05 and S20 as well.
\*
\* The guard order here is what keeps the rule a check instead of a stopped
\* run, and it works in two places.
\*
\* The outer IF routes an off-floor piece into the ELSE, where the only test
\* is an equality against the marker. A model value compares against anything
\* without raising, so that branch is safe by construction.
\*
\* Inside the THEN branch, the \in Nat conjunct sits to the LEFT of the
\* comparison. A conjunction list evaluates left to right and stops at the
\* first FALSE, so a floor piece carrying NoCount fails the membership test
\* and the <= never runs.
\*
\* The step-6 panel measured what happens when the left half goes. One seat
\* wrote this requirement as two implications with a bare <= under a floor
\* guard, keeping the ceiling and the off-floor marker and dropping the
\* floor-implies-a-count direction. At the shipped instance no floor piece
\* ever carries NoCount, so it goes green and sweeps all seven trace pairs.
\* On the state that half exists to reject, an Init laying every piece on the
\* floor at NoCount with Next frozen, it returns rc=75, "The first argument
\* of <= should be an integer". The shipped form returns rc=12 on the same
\* state, and so does a third form writing \in 0..UpperMark, where set
\* membership means no comparison ever meets the marker.
\*
\* rc=75 is an evaluation error, and V2-PLAN §5.1 reads it as the check never
\* happening rather than as a violation. So the free pass here fails in the
\* wrong direction: a learner who ships that form sees a stopped run instead
\* of a red check, and the statement's guard warning is written about step
\* rules rather than about properties.
CountBelongsToTheFloor ==
    \A p \in Pieces :
        IF Observe.stage[p] = "floor"
        THEN /\ Observe.modification[p] \in Nat
             /\ Observe.modification[p] <= UpperMark
        ELSE Observe.modification[p] = NoCount

\* Requirement 1, and the kind trap runs both ways. As an INVARIANT this is
\* false the moment any piece is turned. And a state predicate under
\* PROPERTIES constrains the initial state alone, so an intended invariant
\* filed there silently grades the opening and nothing else. PROPERTIES is
\* the right home here.
\*
\* It catches S01, an opening with the whole floor already turned once, at
\* rc=13 in the initial state. S02 breaks the stage half instead and lands on
\* the line above, so the two conjuncts get separate arrows.
\*
\* Two things a tutor should know before quoting a run. The name never
\* appears: TLC splits a PROPERTIES state predicate into implied inits per
\* conjunct, so the arrow is a source location rather than an operator name.
\* That's now reproduced on two problems, so I'd read it as how TLC behaves
\* rather than a quirk of one module. And S20, an opening laying every piece
\* on the floor at the marker, breaks this and CountBelongsToTheFloor at
\* once, and the invariant wins at rc=12. Requirement 1 gets its own arrow
\* only when the rest of the opening is well formed.
Opening ==
    \A p \in Pieces :
        /\ Observe.stage[p] = "floor"
        /\ Observe.modification[p] = 0

\* Requirement 3. In any step, at most one piece's record changes. It catches
\* S06, an extra Next disjunct turning every eligible floor piece at once, at
\* rc=13 in 2 states, and S22, the same sweep on the way off the floor.
\*
\* This is the property the wrong-subscript probe was built for, and it
\* reproduces. Subscript it _(Observe.stage) and S06 escapes at rc=0, because
\* a floor-wide sweep of turnings changes no stage and the whole box is then
\* forgiven as stutter. TLC reports green with no warning.
\*
\* P06 reaches the same escape without touching the subscript, by dropping
\* both modification clauses so the property reads the stage field only. S06
\* escapes that too. So the hazard isn't really about the subscript. It's
\* about a property that reads less of Observe than the rule it states, and
\* the subscript is one of two ways to get there.
\*
\* What it deliberately doesn't capture: who acted. Observe shows the floor
\* and not the hands on it, so "a maltster turns the piece" can't be a
\* property of any model here, whatever fields you add. What's gradeable is
\* the shape of the change, and this rule plus TurningAddsOne is that shape.
\* Between them they say nothing sweeps the whole floor at once and nothing
\* advances without a hand.
OnePairOfHands ==
    [][\A p, q \in Pieces :
          (/\ p # q
           /\ \/ Observe'.stage[p] # Observe.stage[p]
              \/ Observe'.modification[p] # Observe.modification[p])
              => /\ Observe'.stage[q] = Observe.stage[q]
                 /\ Observe'.modification[q] = Observe.modification[q]]_Observe

\* Requirement 4. A piece on the floor before a step and on the floor after
\* it keeps its count or gains exactly one. It catches S07, a turning that
\* adds two, at rc=13 in 2 states.
\*
\* The antecedent asks for the floor on both sides, which is what keeps this
\* rule away from the marker. A step taking a piece off the floor fails the
\* antecedent, so the arithmetic in the consequent never meets NoCount.
\*
\* The wrong-subscript probe is the one that doesn't reproduce here, and the
\* reason matters more than the verdict. Subscript it _(Observe.stage) and
\* the property does go blind to S07, and S07 is then caught anyway at rc=12
\* by CountBelongsToTheFloor, because turning by two overshoots the upper
\* mark and lands at 4. The coverage is incidental. A learner with the wrong
\* subscript passes S07 for a reason that has nothing to do with the property
\* they got wrong, so a green run on one variant is weak evidence about one
\* property, in this problem more than most.
TurningAddsOne ==
    [][\A p \in Pieces :
          (Observe.stage[p] = "floor" /\ Observe'.stage[p] = "floor")
              => Observe'.modification[p] \in
                     {Observe.modification[p], Observe.modification[p] + 1}]_Observe

\* Requirement 5, and it grades both marks in one line. It catches S08, a
\* kilning that yields good malt unconditionally, at rc=13 in 2 states on the
\* early side, and S09, a Ready that loses its upper bound, at rc=13 in 5
\* states on the late side.
\*
\* The late-side conjunct is load-bearing, and that was worth measuring
\* rather than assuming. Drop < UpperMark (variant P04) and S09 escapes at
\* rc=0, with a matted piece coming out of the kiln as good malt and nothing
\* in the cfg objecting. The domain sketch's version of this rule graded the
\* early side alone, and the late side is half of why this domain was picked.
\*
\* The antecedent reads "not malt before, malt after", so it fires on the
\* step into good malt and not on every step after it. Reading Observe.stage
\* on the left of the implication is also what lets the consequent name the
\* pre-state window, which is where the rule actually lives.
GoodMaltComesFromReady ==
    [][\A p \in Pieces :
          (Observe.stage[p] # "malt" /\ Observe'.stage[p] = "malt")
              => /\ Observe.stage[p] = "floor"
                 /\ Observe.modification[p] >= LowerMark
                 /\ Observe.modification[p] < UpperMark]_Observe

\* Requirement 6. Once a piece is off the floor, its whole record holds
\* still. It catches S10, a loss coming back to the floor at 0, at rc=13 in 3
\* states, and S11, malt regraded to loss, at rc=13 in 4 states.
\*
\* It also closes the way in, and that row is worth reading twice. There's no
\* entry step in this system, so the only way a piece could arrive on the
\* floor is by coming back from off it, and this rule forbids exactly that.
\* With Pieces fixed and stage total over it there's no fourth place to
\* arrive from either, which TypeOK holds. So the way in, the ways out and
\* the ways between are all graded, and none of it took an extra obligation.
\*
\* This is the second wrong-subscript probe that reproduces. Subscript it
\* _(Observe.modification) and S11 escapes at rc=0, because regrading malt to
\* loss changes no count. Same shape as OnePairOfHands, opposite field.
OffTheFloorIsFinal ==
    [][\A p \in Pieces :
          Observe.stage[p] # "floor"
              => /\ Observe'.stage[p] = Observe.stage[p]
                 /\ Observe'.modification[p] = Observe.modification[p]]_Observe

\* Requirement 7, the one liveness obligation. A leads-to, so it re-arms in
\* every state where the antecedent holds. The floor can't be cleared once
\* and then discharge the rule for good. Nothing here refills it, and the
\* formula doesn't lean on that.
\*
\* It catches S12, fairness dropped, at rc=13 in 6 real states and then a
\* stutter: two pieces get kilned, the third gets turned to the upper mark
\* and lies there. It also catches S25, a Remove guarded to unmatted pieces,
\* at 7 states, which is the same ending reached by a system defect rather
\* than by missing fairness. This is the property that leans on the WF
\* conjunct in Spec.
\*
\* The kind is looser than what's written here, and I'd say so out loud
\* rather than leave a tutor to settle it live. Two of the three step-6 seats
\* wrote a plain \A p : <>(off the floor) instead of a leads-to. At this
\* instance the two agree, because Init lays every piece on the floor and
\* requirement 6 makes off-floor final. <> is the weaker formula in general,
\* and both should count here.
\*
\* One caution for anyone about to publish a trace. S12's counterexample
\* counted 7 real states on one pass and 6 on the six after, five of those at
\* different fingerprint seeds. A liveness counterexample is picked out of a
\* strongly connected component rather than computed, so re-run before you
\* quote a length.
TheFloorGetsCleared ==
    \A p \in Pieces :
        (Observe.stage[p] = "floor") ~> (Observe.stage[p] # "floor")

\* ---------------------------------------------------------------------
\* What this property set deliberately cannot carry. Most of it was named in
\* the description before the runs and then measured, and the step-6 panel
\* reached the same boundary blind, which I take as evidence it's real rather
\* than an author's rationalization.
\*
\* The two exits. Observe can't tell a kilning from a throwing out, so no
\* property over it can. Measured at ThrowOut: both variants aimed at the
\* distinction come back rc=0 at the reference's own 216 states.
\*
\* Who acts. The interface shows the floor and not the hands on it, so the
\* maltster in Turn(m, p) is not gradeable by anything in the cfg.
\*
\* Permissions. "A maltster may throw a piece out" asserts that a behavior
\* exists. Safety and liveness properties constrain the behaviors that do
\* exist, so neither kind can demand one.
\*
\* The fairness form. Three of the four forms measured pass. The obligations
\* pin only that the conjunct names the removal.
\*
\* A floor nobody turns. S17 deletes Turn from Next and passes all eight
\* obligations at rc=0, and passes the vacuity gate too, because 8 distinct
\* states clears the placeholder threshold of 4. Only a state floor set for
\* this problem catches it, and at 216 it comes back rc=3. I'd set the floor
\* at 216, and that's reasoning rather than measurement: every fork the
\* description leaves open either lands on 216 or adds states, and I don't
\* see a legitimate model of this instance that reaches fewer.
\*
\* A dropped guard. S19 turns a piece that's already off the floor, and the
\* run aborts at rc=255 instead of failing. The note on Turn carries it. This
\* is a live failure mode for a shape-A rung, since the learner writes the
\* step rules and a forgotten guard gets a stopped run rather than a red
\* check.
\*
\* Quiescence. When every piece is off the floor nothing is enabled and the
\* system stops. That's the end of the story, not a fault, and the cfg
\* carries CHECK_DEADLOCK FALSE for it. The alternative is inventing a
\* stuttering act the maltsters don't have, to keep a checker quiet about a
\* design that's working.
\* ---------------------------------------------------------------------
=============================================================================
