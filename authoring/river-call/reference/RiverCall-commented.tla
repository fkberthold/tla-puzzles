----------------------------- MODULE RiverCall -----------------------------
\* The river-call reference, commented after the freeze. The spec text is the
\* frozen RiverCall.tla byte for byte, and harness/comment-gate.sh checks that
\* claim rather than trusting it. Comments are the only addition.
\*
\*   sha256 RiverCall.tla
\*   81b35a2e70f4675a6416e3efd551d1fa009a780cff31f914b92494297da0c877
\*
\* Written for a reader who has already built their own model of this stretch
\* and wants to see where mine went differently. The notes cover decisions,
\* not syntax: the representation and what it beat, each action's atomicity
\* boundary, what each obligation grades and what it leaves ungraded, and what
\* the handed green run at flow 6 does and doesn't establish.
\*
\* Measurements come from step2-variants.md and step6-spread.md under
\* authoring/river-call/reports/. The rejected rivals come from
\* author-notes/ALTERNATIVES.md.
EXTENDS Integers, FiniteSets

\* Owners are named by their priority date. The set is a set of naturals and
\* Senior below is just <, so an owner's name is their place on the register.
\*
\* The rival was model values for owners plus a Priority constant function. It
\* loses on a mechanical fact. A model value has no name inside the module, so
\* nothing here can build a date function over {o1, o2, o3}. The way out is a
\* sibling MC module declaring every owner as its own constant, the way
\* MCCustody.cfg does with A = A. That buys abstract identities, and it costs
\* a file and five constants. This rung ships two files.
\*
\* The cost of what shipped is real. Seniority rides on identity, so a reader
\* can't tell an owner apart from their place in the order. Rule 2 says the
\* dates never change and never tie, so I think the two are one fact here. If
\* a later rung wants the register to move, this is the first thing that has
\* to come apart.
CONSTANTS Owners, Decree, Flow

\* What the constants have to satisfy, and one thing they don't. Nothing here
\* relates Flow to the sum of the decrees. That gap is on purpose. The shipped
\* diagnosis object is this module unchanged on a cfg where the flow covers
\* every decree, and an ASSUME forbidding it would answer the puzzle.
ASSUME /\ IsFiniteSet(Owners)
       /\ Owners \subseteq Nat
       /\ Flow \in Nat
       /\ DOMAIN Decree = Owners
       /\ \A o \in Owners : Decree[o] \in Nat

\* Two functions on Owners, one for the gates and one for the calls. Observe
\* renders as the identity over them, so the state is the interface and
\* nothing else is stored.
\*
\* Rivals weighed and rejected:
\*
\* A third variable holding the free water. Tempting, since Rule 5 counts
\* against it and the call guard reads it every time. It makes the reference's
\* variables wider than Observe's fields, which is a representation level up
\* and the wrong rung. Flow - Taken(diverted) says the same thing, and it
\* can't drift from the gates.
\*
\* calling as a subset of Owners instead of a function into BOOLEAN. Cheap
\* call, and the function won. The description reports the field per owner, so
\* a set would make Observe.calling read differently from Observe.diverted for
\* no gain.
\*
\* What has no variable at all: shortness. It's worked out from diverted, the
\* flow and the decrees wherever it's needed, and it's never reported as a
\* fact in its own right. Store it and ACallIsHonest grades a model against
\* that model's own idea of shortness. A model that gets Rule 5 wrong and
\* reports it consistently then walks through. The cost is that the two step
\* obligations now read the constants as well as the fields, and a reader
\* should expect that rather than reach for a third field.
VARIABLES diverted, calling

vars == <<diverted, calling>>

\* The whole public face of the stretch, the gates and the calls, rendered as
\* the identity over state. That rendering also fixes the subscript for both
\* step obligations. The note at ACallIsHonest says what breaks when a
\* subscript names one field instead of the whole record.
Observe == [diverted |-> diverted, calling |-> calling]

\* Older date, higher right. First in time, first in right is the whole of the
\* water law this module needs, and it lands as one comparison.
Senior(a, b) == a < b

\* Total draw, folded over the powerset of Owners. Integers and FiniteSets
\* carry no sum operator, so a fold is the standard-library answer. CHOOSE
\* picks one element deterministically, which keeps Tally a function rather
\* than a relation. Addition doesn't care which element it picks.
Taken(d) ==
    LET Tally[T \in SUBSET Owners] ==
            IF T = {} THEN 0
            ELSE LET o == CHOOSE x \in T : TRUE
                 IN  d[o] + Tally[T \ {o}]
    IN  Tally[Owners]

\* Rule 5, said once and read from everywhere. What the owner is taking, plus
\* the water nobody is taking, against their own decree. Flow - Taken(d) is
\* the free water, and it excludes d[o], so the sum is what o could take right
\* now.
\*
\* Two other readings were on the table and both cost the system. Short
\* against your current draw alone makes every owner under their decree short,
\* so a shut gate locks the river. Short against what seniors alone have taken
\* ignores the junior who's already in the water, which is the case the whole
\* domain is about.
\*
\* A third wrong reading turned up at the panel and nobody predicted it. Add
\* the owner's own draw on top of a quantity that already includes it, and the
\* result is stricter than the rules rather than looser. It emits fewer calls,
\* and every obligation in this module passes it. Rule 5 is graded here by the
\* honesty antecedent alone, and that only bites when the caller sits at zero.
\* So read this line off the formula, never off a green run.
Short(d, o) == d[o] + (Flow - Taken(d)) < Decree[o]

\* Every gate shut and no call standing. Rule 10.
\*
\* No obligation pins this, and the description turned down a fourth
\* requirement that would have. The argument was that the shipped Init fixes
\* the opening, and that holds only while the Init is the shipped one.
\* Measured: a variant opening with every call standing runs green on all four
\* lines. The learner writes their own Init at this rung, so I'd treat the
\* hole as live rather than closed.
Init ==
    /\ diverted = [o \in Owners |-> 0]
    /\ calling = [o \in Owners |-> FALSE]

\* One owner, one act, one step, and the step is a strict rise. The three
\* conjuncts are the three rules that reach a rise.
\*
\* The seniority guard reads the PRE-state calling, and that's Rule 7's last
\* clause rather than a convenience. A call reaches a junior's rise if it was
\* standing when the rise began, whatever happens to the call in the same act.
\* Read calling' here instead and a junior may rise in the very act a senior's
\* call goes out. The panel's third seat shipped that reading, and nothing in
\* the pair set caught it, because every shipped pair moves one field per
\* step.
\*
\* The flow check runs on the post-state, since Rule 4 is about where the
\* water lands. Every other guard in this module reads its pre-state, so this
\* one is worth marking.
\*
\* The range opens at diverted[o] + 1, so this action is rises alone and a
\* same-setting step can't come from here. It stops at Decree[o], which puts
\* the type invariant's range in the action as well as in the cfg.
Open(o) ==
    /\ \A s \in Owners : Senior(s, o) => ~ calling[s]
    /\ \E n \in (diverted[o] + 1) .. Decree[o] :
           /\ Taken([diverted EXCEPT ![o] = n]) =< Flow
           /\ diverted' = [diverted EXCEPT ![o] = n]
    /\ UNCHANGED calling

\* A fall, and it carries no guard beyond its range. Rule 3 makes any lower
\* setting legal at any time, lowering can't break the flow rule, and Rule 7
\* reaches rises alone. So no seniority test belongs here.
\*
\* Rule 3 gives an owner ONE act that moves the gate to any lawful setting, so
\* a single Set(o, n) is the closer reading, and the transition relation is
\* the same either way. I split it because the split puts Rule 7's guard where
\* it belongs instead of behind an IF inside Set. The split also pays off at
\* the dead-action probe. On the flow-6 instance the harness names CallOut and
\* CallBack as the actions that never fired, and one Set would report that
\* more bluntly.
\*
\* The range stops at diverted[o] - 1, so a shut gate has no Close step at
\* all. That, plus Open's strict rise, is what excludes the same-setting step.
\* The panel read the exclusion off the console before it opened the module:
\* 163 generated over 27 distinct on the flow-6 run is 27 times 6 plus 1.
\* Allowing a same-setting step would have read 27 times 9 plus 1.
Close(o) ==
    /\ \E n \in 0 .. (diverted[o] - 1) :
           diverted' = [diverted EXCEPT ![o] = n]
    /\ UNCHANGED calling

\* A call goes out. The ~ calling[o] guard trims a re-call step, which would
\* change nothing observable. It's state-graph hygiene, and no property here
\* can see it.
\*
\* Short(diverted, o) is Rule 6's half saying only a short owner may call, and
\* it's the guard the handed green run kills. See the closing note.
\*
\* UNCHANGED diverted keeps a call step off the gates. That's what leaves the
\* two kinds of event separable at the interface, and it's why ACallIsHonest
\* has to carry the whole record as its subscript.
CallOut(o) ==
    /\ ~ calling[o]
    /\ Short(diverted, o)
    /\ calling' = [calling EXCEPT ![o] = TRUE]
    /\ UNCHANGED diverted

\* Taking a call back is free at any time, short or not, by Rule 6. There's
\* nothing to forbid, so nothing grades this action. A variant refusing to
\* release a call while the owner is still short runs green on all four lines,
\* and that's right. It removes behaviors, and no obligation here can be
\* broken by a behavior that doesn't happen.
CallBack(o) ==
    /\ calling[o]
    /\ calling' = [calling EXCEPT ![o] = FALSE]
    /\ UNCHANGED diverted

\* Four events over one set of owners. There's no clock, no season, no
\* weather and no official.
\*
\* One owner moves per step, and nothing in the rules forbids two owners
\* acting at the same moment. The description checked that nothing needs to
\* forbid it. All three obligations quantify over owners rather than over
\* whichever one acted, so a joint step lands where a pair of separate steps
\* would. A variant adding a joint-open disjunct is caught, and it's caught by
\* FlowHolds rather than by anything watching how many gates moved.
Next ==
    \/ \E o \in Owners : Open(o)
    \/ \E o \in Owners : Close(o)
    \/ \E o \in Owners : CallOut(o)
    \/ \E o \in Owners : CallBack(o)

\* No fairness conjunct, and the absence is the point. Rule 9 says nothing has
\* to happen, and what carries it is restraint. There's no WF anywhere and no
\* liveness obligation in the cfg. A variant adding weak fairness on Open runs
\* green, and it doesn't even move the state graph: 757 generated and 136
\* distinct, the reference's own pair to the state. Only a control run catches
\* an over-constrained spec.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------
\* The obligations. Four cfg lines, which is the top of this rung's band.
\* The kinds carry more of the judgment than the formulas do:
\*
\*   state invariants   TypeOK, FlowHolds
\*   action properties  NobodyOpensAgainstACall, ACallIsHonest
\*   liveness           none, and that's Rule 9 graded by restraint
\*
\* Every one of them reads Observe rather than the variables. Under this
\* rendering the two are the same thing, and going through Observe keeps each
\* obligation stated against the interface a learner's own model has to
\* answer at.
\* ---------------------------------------------------------------------

\* The author's own invariant, and not one of the three stated requirements.
\* It carries three separate claims, and two of them have been broken in the
\* field.
\*
\* The domain clause says the register covers every owner. The panel's third
\* seat kept the range and the boolean and dropped this line, and nothing else
\* here would have caught that.
\*
\* The range runs from shut up to that owner's own decree, which is a
\* predicate over a number rather than a shape. A stated range earns a real
\* cfg line or it grades nothing. A variant letting Open reach up to Flow
\* lands here in two states.
TypeOK ==
    /\ DOMAIN Observe.diverted = Owners
    /\ \A o \in Owners : Observe.diverted[o] \in 0 .. Decree[o]
    /\ Observe.calling \in [Owners -> BOOLEAN]

\* Rule 4 as a claim about single states, which is what makes it an INVARIANT
\* rather than a property. It's the workhorse of the variant matrix. An
\* ungated Open, an off-by-one on the check, an Init already over the flow,
\* and a joint-open disjunct all land here.
\*
\* It does no work at all on the flow-6 instance, where 27 of 27 type-legal
\* states are flow-legal, so it never binds. See the closing note.
FlowHolds == Taken(Observe.diverted) =< Flow

\* Item 2, and a step rule rather than an invariant. That's forced rather than
\* chosen, and the trace is worth carrying.
\*
\* Take three owners on a flow of 3, each decreed 2. From every gate shut the
\* junior opens to 1, and nobody's short, since 2 units still sit free against
\* decrees of 2. Now the senior opens to 2, which is their own decree and
\* their own right. The free water drops to nothing, the middle owner is short
\* at 0 against 2, and the junior is still taking 1. So "no junior takes water
\* while a senior is calling" broke on the senior's own lawful act. Guarding
\* that act inverts priority, and shutting the junior's gate in the same step
\* needs the coordination Rule 8 denies. The rule has to move onto steps, and
\* out-of-priority water already running is a legal standing state.
\*
\* The antecedent is a rise, so a fall and a hold go untouched. That's Rule 7's
\* "a call doesn't reach a gate that's already open", carried by the antecedent
\* rather than by a clause of its own.
\*
\* The inner quantifier runs over EVERY senior, not the next one up. A variant
\* checking only the immediately senior owner is caught here. Restrict the
\* property the same way and the pair agrees with itself, and the run comes
\* back green.
NobodyOpensAgainstACall ==
    [][\A o \in Owners :
          Observe'.diverted[o] > Observe.diverted[o] =>
              \A s \in Owners :
                  Senior(s, o) => ~ Observe.calling[s]]_Observe

\* Item 3, and the place to state the subscript rule once. The subscript names
\* the state whose stutter a step obligation forgives, so it has to be
\* _Observe, the whole record. Subscript this one _(Observe.diverted) instead
\* and every call step is exempt from the box, because a call leaves the gates
\* alone. The property then never examines the steps it exists to grade.
\* Measured: with that subscript the ungated-call variant this property was
\* written to catch comes back green, with no warning.
\*
\* The antecedent is the call going OUT, so taking one back goes untouched,
\* which is Rule 6's second half. The consequent works shortness out from the
\* pre-state gates and the constants, which is the whole reason shortness
\* stays off the interface.
\*
\* Two variants land here in two states each: dropping the guard, and reading
\* shortness against the owner's own draw alone. The seniors-only reading
\* doesn't land, because it turns out to imply the shipped Short rather than
\* contradict it.
ACallIsHonest ==
    [][\A o \in Owners :
          (~ Observe.calling[o] /\ Observe'.calling[o]) =>
              Short(Observe.diverted, o)]_Observe

\* Instance data at the foot of a frozen spec, which is a smell, and it's here
\* because TLC's config parser leaves no alternative at two files. That parser
\* takes model values, numbers, strings and sets of those. Decree = <<2, 2, 2>>
\* comes back with "expecting = or <-", and Decree = [o1 |-> 2] with
\* "expecting ]", both on the pinned build. So the register has to live in
\* some module. The repo's usual answer is a sibling MC module, and that's a
\* third file where this rung ships two. If the file count weren't fixed I'd
\* take the MC module.
\*
\* The one I rejected outright is a scalar Decree shared by every owner. It's
\* clean in the cfg and it costs the system, because Rule 2 gives each owner
\* their own amount, and a spec that can't say so models a smaller river.
Decrees == [o \in Owners |-> 2]

\* ---------------------------------------------------------------------
\* What this property set deliberately cannot carry.
\*
\* Whose hand is on the wheel. Observe shows the stretch, not the hands on it,
\* so "each owner sets only their own gate" isn't a property of any model
\* here, whatever fields you add. Measured from the other end: a variant
\* adding a watermaster who shuts a junior's gate under a call runs green,
\* because every step it adds lowers a setting. Item 2's antecedent doesn't
\* reach a fall, and item 1 can't mind one.
\*
\* A stream that moves. A variant giving the flow its own variable and a
\* weather step runs green over 544 distinct states. That step leaves both
\* Observe fields alone, so it stutters out of both action properties, and
\* FlowHolds reads the constant.
\*
\* Anything stricter than the rules. Refusing to release a call while short, a
\* stream that clips what it can't deliver, weak fairness on Open. All three
\* remove behaviors, and safety can't be broken by a behavior that doesn't
\* happen. Only a control run catches a strengthening.
\*
\* The opening, past what Init itself fixes. Nothing in the cfg constrains it,
\* and a variant opening with every call standing runs green.
\*
\* Return flow, storage, ties on the register, and a decree that moves. Each
\* one is a second system on top of this one, and return flow is the largest
\* thing I cut.
\*
\* ---------------------------------------------------------------------
\* The handed green run, and what it establishes.
\*
\* The rung hands the learner this module unchanged, on a cfg where the flow
\* covers the sum of the decrees. TLC returns green on all four lines. Nobody
\* can ever be short there, so the priority logic the spec exists to state
\* goes untouched by the run.
\*
\* Where each obligation stands on it. TypeOK is the only one doing work.
\* FlowHolds never binds, since 27 of 27 type-legal states are flow-legal.
\* NobodyOpensAgainstACall passes on its consequent, with Open firing 81 times
\* and calling never moving. ACallIsHonest passes on its antecedent, CallOut
\* sitting at 0 total. The project's own vacuity harness returns
\* VACUOUS_DEAD_ACTION and names CallOut and CallBack.
\*
\* One panel seat sharpened that last line, and I'd carry its reading. The
\* honesty obligation isn't inert on that instance, because deleting the guard
\* does fail there. With nobody ever short, "a call goes out honestly"
\* collapses into "no call ever goes out". So the run establishes that the
\* model emits no call, and nothing at all about which calls are honest, that
\* set being empty.
\*
\* A last word on the state count, since it's the number the statement offers
\* to compare against. 136 is the whole type-legal, flow-legal state set on
\* the checking instance, so any model reaching all of it reports 136 whatever
\* its transition relation does. The panel's third seat hit 136 and its model
\* was wrong four ways over. Hitting the number says the model reaches the
\* right states. It says nothing about how it gets there.
\* ---------------------------------------------------------------------
=============================================================================
