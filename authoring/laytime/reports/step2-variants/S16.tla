------------------------------ MODULE S16 ------------------------------
\* Seeded variant of authoring/laytime/reference/Laytime.tla (V2-PLAN 9.5).
\* MUTATION: Next is the Tender disjunct alone
EXTENDS Integers

CONSTANTS Allowance, Limit

ASSUME Allowance \in Nat /\ Limit \in Nat

VARIABLES noticeTendered, laytimeLeft, demurrage, finished

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

Init ==
    /\ noticeTendered = FALSE
    /\ laytimeLeft = Allowance
    /\ demurrage = 0
    /\ finished = FALSE

Next ==
    \/ /\ ~noticeTendered
       /\ noticeTendered' = TRUE
       /\ UNCHANGED <<laytimeLeft, demurrage, finished>>


Spec == Init /\ [][Next]_vars

=============================================================================
