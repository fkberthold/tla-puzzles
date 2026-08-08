------------------------------- MODULE SeedLib -------------------------------
\* A neighborhood seed library lends packets of seed to its members. A
\* member checks out a packet, plants it, and returns new seed of the
\* same variety from the harvest. The loan is a debt in kind, and the
\* season close is the deadline that makes lateness cost.
\*
\* This is the reference the shipped problem artifact was built from.
\* The spec below is the frozen SeedLib.tla, byte for byte. Comments
\* were added in a separate pass, and a strip-and-diff gate checks the
\* claim.
\*
\* One idea carries the file. Every obligation reads the system through
\* Observe, so the operator is the measuring apparatus, and a live
\* Observe is what makes a green run mean anything. The artifact froze
\* three of the four fields and turned its green run into a report on a
\* still library. The notes at Observe and StandingGatesTheShelf carry
\* the mechanism.
EXTENDS Naturals, FiniteSets

\* The founding grant fixed four numbers: members, varieties, opening
\* stock, and the three-season horizon. All four are constants of the
\* program, so all four are CONSTANTS here, assigned by the model
\* configuration. NumSeasons began as a definition (NumSeasons == 3).
\* It moved up to a CONSTANT so the cfg owns the horizon: a spec-side
\* redefinition now collides with the declaration and dies at parse.
\* No property below reads these numbers. The instance lives in
\* MCSeedLib because a cfg can't write a function value for
\* OpeningStock.
CONSTANTS Members, Varieties, OpeningStock, NumSeasons

\* The contract on any instance: finite nonempty parties, stock as
\* whole-packet counts, at least one season.
ASSUME
    /\ IsFiniteSet(Members)
    /\ Members # {}
    /\ IsFiniteSet(Varieties)
    /\ Varieties # {}
    /\ OpeningStock \in [Varieties -> Nat]
    /\ NumSeasons \in Nat
    /\ NumSeasons >= 1

\* Four variables, one per Observe field. The observation fixes what a
\* visitor could tally, and no rule needs state beyond those fields, so
\* the cheapest correct representation is the observation itself. Four
\* other shapes lost to it.
\*
\* Packet identities. Rule 1 gives each packet its own history, but the
\* librarian goes by the label, and no property reads identity,
\* generation, or provenance. Identities multiply states with nothing
\* to catch the difference.
\*
\* A shelf derived from the ledger. Conservation ties the two, so shelf
\* could be a definition over owed. That bakes the conservation
\* property into the representation, and grading has to see the models
\* where the count doesn't follow. A free variable keeps it
\* falsifiable. I suspect the derived shelf is also the shortcut a
\* strong learner reaches for, and this file shouldn't hand it over.
\*
\* Debts as a set of member-variety pairs, or a boolean. A set can't
\* count to two, and OneDebtPerKind is about the count passing one. A
\* representation that can't show the violation can't grade it.
\*
\* Per-debt age. Tempting for the late-return fates, but default blocks
\* checkout, so a defaulter's debts are all past-season. Standing
\* already carries what age would say.
\*
\* The garden is elided whole. Planting, crop failure, and harvest
\* never appear, because the library learns nothing between checkout
\* and return. A failed crop and plain silence look alike from the
\* desk, so garden state would be state no observation reads. That's
\* the test for a safe elision: no rule reads the thing, and no
\* property constrains it.
VARIABLES season, shelf, owed, standing

vars == <<season, shelf, owed, standing>>

\* Seasons are numbers, not names like \"first\". The march is an order,
\* numbers carry order and the one-step move for free, and
\* Ended == NumSeasons + 1 keeps the end mark on the same axis.
Ended == NumSeasons + 1
Good == "good"
Default == "default"

InProgress == season \in 1..NumSeasons

\* The opening: season one, the founding donation, a clean ledger,
\* everyone in good standing. TheOpening below restates this through
\* Observe, which is what makes it gradable against any model's state.
Init ==
    /\ season = 1
    /\ shelf = OpeningStock
    /\ owed = [m \in Members |-> [v \in Varieties |-> 0]]
    /\ standing = [m \in Members |-> Good]

\* Rule 4. Three guards: good standing, stock on the shelf, no open
\* debt of the same variety. One indivisible step at the desk: the
\* packet leaves and the debt lands together, and nothing else moves.
\*
\* The standing guard is the one the artifact dropped. Dropped here, it
\* goes red at once on StandingGatesTheShelf. The note there says why
\* the artifact's run stayed green anyway.
Checkout(m, v) ==
    /\ InProgress
    /\ standing[m] = Good
    /\ shelf[v] > 0
    /\ owed[m][v] = 0
    /\ shelf' = [shelf EXCEPT ![v] = @ - 1]
    /\ owed' = [owed EXCEPT ![m][v] = @ + 1]
    /\ UNCHANGED <<season, standing>>

\* Rule 5. Three effects in one indivisible step: packet to the shelf,
\* debt off the ledger, standing back if that cleared the member's
\* last debt. The guard takes a packet only against a debt, and that's
\* where no-donations lives: there's no other way a shelf count goes
\* up.
\*
\* The standing update reads owed', not owed, on purpose. The question
\* is whether this return cleared the book. Read the unprimed ledger
\* and a member who just cleared their last debt stays in default over
\* nothing, which DefaultIsNeverClean rejects.
Return(m, v) ==
    /\ InProgress
    /\ owed[m][v] > 0
    /\ shelf' = [shelf EXCEPT ![v] = @ + 1]
    /\ owed' = [owed EXCEPT ![m][v] = @ - 1]
    /\ standing' = [standing EXCEPT ![m] =
                        IF \A w \in Varieties : owed'[m][w] = 0
                        THEN Good
                        ELSE @]
    /\ UNCHANGED season

\* Rule 6. A close recomputes every standing from the ledger: owing
\* means default, a clear book means good. The debts hold still and so
\* does the shelf. Nothing is forgiven, nothing expires.
\*
\* Note who acts. Nothing obliges a member, ever. The calendar is the
\* one party that must act, so fairness lands on Close and nowhere
\* else (see Spec).
Close ==
    /\ InProgress
    /\ season' = season + 1
    /\ standing' = [m \in Members |->
                        IF \E v \in Varieties : owed[m][v] > 0
                        THEN Default
                        ELSE Good]
    /\ UNCHANGED <<shelf, owed>>

\* Members act freely while a season runs, in any order or not at all.
\* The calendar acts alone, in a step of its own.
Next ==
    \/ \E m \in Members, v \in Varieties : Checkout(m, v) \/ Return(m, v)
    \/ Close

\* WF_vars(Close) carries the one liveness obligation: a season in
\* progress eventually closes. Weak fairness is enough because Close
\* stays enabled until it fires. Fairness on a member action would
\* oblige somebody to garden, and the description obliges nobody.
Spec == Init /\ [][Next]_vars /\ WF_vars(Close)

\* The measuring apparatus. Grading reads a model, whatever state it
\* chose, through this one operator, and every obligation below reads
\* the system only through it. Here the four variables are the four
\* fields, so Observe is the identity record. In another model it's
\* whatever mapping renders that model's state as these fields.
\*
\* The consequence worth staring at: the action properties below are
\* subscripted _Observe. A step that doesn't move Observe is a
\* stuttering step to them, and stuttering steps are exempt. So a
\* model whose operator doesn't track its state makes every real step
\* invisible, one exemption at a time.
\*
\* That's the artifact's whole mechanism. It froze shelf, owed, and
\* standing at their opening values and left season live. Every
\* checkout and return became a stutter. The invariants held on a
\* still image: a constant shelf plus a zero ledger balances
\* conservation as an identity. The action properties examined only
\* the closes, and there the frozen fields make every consequent
\* true. The green run established types and the calendar's march,
\* nothing else. A still instrument reports a still world.
Observe ==
    [season |-> season, shelf |-> shelf, owed |-> owed, standing |-> standing]

\* Standard modules only, so the sum is hand-rolled rather than a
\* community fold.
RECURSIVE SumOver(_, _)
SumOver(f, S) ==
    IF S = {}
    THEN 0
    ELSE LET x == CHOOSE y \in S : TRUE
         IN f[x] + SumOver(f, S \ {x})

\* Both operators read Observe.owed rather than owed. Every obligation
\* goes through the operator, even where the raw variable is shorter.
\* That discipline is what keeps the property set portable to a model
\* with different state.
OwedTotal(v) == SumOver([m \in Members |-> Observe.owed[m][v]], Members)

Owes(m) == \E v \in Varieties : Observe.owed[m][v] > 0

\* Not one of the description's eleven obligations, and the one place
\* this file reads raw state. It fires first on several broken models
\* but carries nothing alone: with it out of the cfg, each of those
\* models is still caught by a stated property. And a type can't see
\* a missing guard.
TypeOK ==
    /\ season \in 1..Ended
    /\ shelf \in [Varieties -> Nat]
    /\ owed \in [Members -> [Varieties -> Nat]]
    /\ standing \in [Members -> {Good, Default}]

\* Item 2's floor. TypeOK's Nat range already implies it, but the
\* floor is the description's own clause, so it stands on its own
\* name and survives without TypeOK.
ShelfFloor == \A v \in Varieties : Observe.shelf[v] >= 0

\* Item 4, and the reason owed counts instead of answering yes or no.
\* The property is about the count passing one. A shape that can't
\* show two can't show the violation.
OneDebtPerKind ==
    \A m \in Members, v \in Varieties : Observe.owed[m][v] <= 1

\* Item 5, the census identity: shelf plus debts owed equals the
\* founding donation, per variety, always. No packet survives the
\* loop (the borrowed one is planted, the returned one is new seed),
\* but the count does. shelf stays a free variable so this stays
\* falsifiable.
\*
\* Its blind spot is worth knowing. A frozen observation satisfies it
\* forever, opening stock plus a zero ledger, and it's the invariant
\* a still image passes most gracefully.
ConservationInKind ==
    \A v \in Varieties : Observe.shelf[v] + OwedTotal(v) = OpeningStock[v]

\* Item 7. The antecedent needs a member seen in default. Freeze the
\* ledger and leave standing live, and this fires at the first close
\* that catches a member owing: shown in default over a ledger
\* reading zero. That's why the artifact's freeze had to take
\* standing too.
DefaultIsNeverClean ==
    \A m \in Members : Observe.standing[m] = Default => Owes(m)

\* Item 11 through the operator. Listed under PROPERTIES, so it
\* constrains the first state of every behavior and nothing after.
TheOpening ==
    /\ Observe.season = 1
    /\ Observe.shelf = OpeningStock
    /\ Observe.owed = [m \in Members |-> [v \in Varieties |-> 0]]
    /\ Observe.standing = [m \in Members |-> Good]

\* Item 1: no packet leaves the shelf to a member in default. This is
\* the property the artifact's missing guard violates, and the
\* deepest obligation here, for two reasons.
\*
\* First, recognition by signature. The property grades models whose
\* actions it can't name, so it doesn't say \"Checkout\". A checkout is
\* its footprint through Observe: one variety's count down one and
\* some member's debt for it up one, in the same step. The \E binds
\* the standing check to the member whose ledger row moved. Through
\* the observation, the ledger move is the only record of who
\* borrowed. And the check reads o.standing, the state before the
\* step: the member had to be good when the packet left, not after.
\*
\* Second, this can't be an invariant, and that's not a style call.
\* Drop the standing guard from Checkout and the reachable states
\* don't change. A default-then-checkout lands on a state a legal
\* history also reaches (borrow twice, then default), since a state
\* keeps no memory of the order. The blind panel proved the two state
\* sets byte-identical by dump comparison (reports/step6-spread.md).
\* So no state invariant can carry item 1. The defect lives in the
\* transitions, only a step formula sees it, and a frozen operator
\* blinds the step formulas first. That chain is the problem this
\* spec anchors.
StandingGatesTheShelf ==
    [][LET o == Observe
           n == Observe'
       IN \A v \in Varieties :
              n.shelf[v] < o.shelf[v] =>
                  \E m \in Members :
                      /\ n.owed[m][v] = o.owed[m][v] + 1
                      /\ o.standing[m] = Good]_Observe

\* Item 2, minus the floor. A shelf count moves one packet at a time
\* and only with the matching ledger move: down means somebody's debt
\* for it rose by one, up means somebody's fell by one. The up clause
\* is where the no-donations rule bites, because a packet arriving
\* without a debt retiring has no legal signature.
\*
\* The two Cardinality clauses are the one-transaction rule. The desk
\* handles one member and one variety per step, so at most one shelf
\* count and at most one ledger cell move. Without them a model could
\* batch two checkouts into one step and each half would look legal.
ShelfDiscipline ==
    [][LET o == Observe
           n == Observe'
       IN /\ \A v \in Varieties :
                 /\ n.shelf[v] \in {o.shelf[v] - 1, o.shelf[v], o.shelf[v] + 1}
                 /\ n.shelf[v] = o.shelf[v] - 1 =>
                        \E m \in Members : n.owed[m][v] = o.owed[m][v] + 1
                 /\ n.shelf[v] = o.shelf[v] + 1 =>
                        \E m \in Members : n.owed[m][v] = o.owed[m][v] - 1
          /\ Cardinality({v \in Varieties : n.shelf[v] # o.shelf[v]}) <= 1
          /\ Cardinality({mv \in Members \X Varieties :
                              n.owed[mv[1]][mv[2]] # o.owed[mv[1]][mv[2]]})
                 <= 1]_Observe

\* Item 3, the ledger side of the same coin. A debt moves by one,
\* only with the opposite shelf move, so it appears only at a
\* checkout of that variety and clears only at a return of it.
\* Kind-matching is the point: a return of beans never touches a
\* lettuce debt.
\*
\* Conservation fires first on most breaks of this, so it reads as
\* dead weight. The variant matrix says otherwise: with conservation
\* and TypeOK out of the cfg, this property still catches the ledger
\* breaks on its own (reports/step2-variants.md, D4).
LedgerDiscipline ==
    [][LET o == Observe
           n == Observe'
       IN \A m \in Members, v \in Varieties :
              /\ n.owed[m][v] > o.owed[m][v] =>
                     /\ n.owed[m][v] = o.owed[m][v] + 1
                     /\ n.shelf[v] = o.shelf[v] - 1
              /\ n.owed[m][v] < o.owed[m][v] =>
                     /\ n.owed[m][v] = o.owed[m][v] - 1
                     /\ n.shelf[v] = o.shelf[v] + 1]_Observe

\* Item 6, three clauses, one per sentence of the description. At a
\* step where the season moves, every standing is recomputed from the
\* ledger. While the season holds, good standing is safe: nobody
\* enters default between closes. And the only way out of default is
\* the return that clears the last debt: a default-to-good flip needs
\* a debt going down in that step and a book at zero after it.
\*
\* In this spec the third clause never fires at a close. A close
\* moves no debts, and a defaulter always owes, so the recomputation
\* keeps them in default. The clause is written for the broken
\* models: a close that forgives, or restores standing over an open
\* book, trips it. These properties grade every model a learner
\* might submit, not just this one.
CloseSquaresTheBook ==
    [][LET o == Observe
           n == Observe'
       IN /\ n.season # o.season =>
                 \A m \in Members :
                     n.standing[m] = (IF \E v \in Varieties : n.owed[m][v] > 0
                                      THEN Default
                                      ELSE Good)
          /\ n.season = o.season =>
                 \A m \in Members :
                     o.standing[m] = Good => n.standing[m] = Good
          /\ \A m \in Members :
                 o.standing[m] = Default /\ n.standing[m] = Good =>
                     /\ \E v \in Varieties : n.owed[m][v] < o.owed[m][v]
                     /\ \A v \in Varieties : n.owed[m][v] = 0]_Observe

\* Item 10. The season moves forward one step at a time, never back,
\* and a step that moves it moves no shelf count and no debt.
\*
\* That stillness clause is the close's atomicity, and it protects
\* the deadline. Default is decided at the boundary, from the ledger
\* as the boundary finds it. Let a return share the close's step and
\* the boundary reads a ledger in mid-move, so whether the return
\* beat the deadline has no answer. Standing is left out of the
\* clause on purpose: standing is the one thing a close moves.
TheCalendarMarches ==
    [][LET o == Observe
           n == Observe'
       IN /\ n.season \in {o.season, o.season + 1}
          /\ n.season # o.season =>
                 /\ n.shelf = o.shelf
                 /\ n.owed = o.owed]_Observe

\* Item 9. After the program ends, nothing observable changes again.
\* Stated over the whole record at once, so a late return, a late
\* checkout, and a fourth close all trip it the same way.
TheEndIsTheEnd ==
    [][Observe.season = Ended => Observe' = Observe]_Observe

\* Item 8, the one liveness obligation. Each season leads to the
\* next, discharged by WF_vars(Close), and at the end an unmet debt
\* means default. Drop the fairness and the first conjunct goes red,
\* because nothing forces a season to close.
\*
\* The first conjunct is also why the artifact's freeze stopped at
\* season. Freeze the calendar too and the leads-to fails (the
\* variant matrix's freeze-everything row goes red right here). So
\* season stays live in any freeze that wants a green run, and the
\* calendar's honest march is most of what that green run still
\* means.
TheReckoningComes ==
    /\ \A s \in 1..NumSeasons :
           Observe.season = s ~> Observe.season = s + 1
    /\ [](Observe.season = Ended =>
              \A m \in Members : Owes(m) => Observe.standing[m] = Default)

\* Two gaps this property set carries on purpose, and one it can't
\* close from inside.
\*
\* Enabledness. Every obligation above says what must never happen,
\* or what the calendar must eventually do. None says a member action
\* must be possible. A model with an over-tight guard (checkout only
\* above two packets, return only in good standing) passes every
\* line here. The second of those breaks the description's way back
\* from default. Closing that class takes a new kind of obligation,
\* something must be possible, and I'd put it with the description's
\* owner, not with this module (reports/step2-variants.md, V07 and
\* V18).
\*
\* The horizon's value. NumSeasons is pinned by the cfg, and a
\* spec-side redefinition dies at parse. A different cfg is a
\* different instance, not a lie about this one, and no obligation
\* stated over Observe can object to a constant's value.
\*
\* A frozen operator. Every obligation is stated over Observe, so any
\* of them can be blinded the way the artifact blinded these. A
\* twelfth property over Observe would go blind with the rest. That
\* class is owned by the grading engine, as a live-lens probe beside
\* the property set, filed as tla-29m4.

=============================================================================
