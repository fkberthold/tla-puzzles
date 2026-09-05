------------------------------ MODULE Laytime ------------------------------
EXTENDS Integers

CONSTANTS Allowance, Limit

ASSUME Allowance \in Nat /\ Limit \in Nat

(*--algorithm laytime {
  variables
    noticeTendered = FALSE,
    laytimeLeft = Allowance,
    demurrage = 0,
    finished = FALSE;

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
    Statement:
      while (TRUE) {
        either {
          await ~noticeTendered;
          noticeTendered := TRUE;
        } or {
          await noticeTendered /\ ~finished /\ demurrage < Limit;
          if (laytimeLeft > 0) {
            laytimeLeft := laytimeLeft - 1;
          } else {
            demurrage := demurrage + 1;
          };
        } or {
          await noticeTendered /\ ~finished /\ demurrage < Limit;
          if (laytimeLeft = 0) {
            demurrage := demurrage + 1;
          };
        } or {
          await noticeTendered /\ ~finished;
          finished := TRUE;
        };
      };
  }
}*)
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

=============================================================================
