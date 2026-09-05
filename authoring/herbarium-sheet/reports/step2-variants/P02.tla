----------------------------- MODULE P02 -----------------------------
EXTENDS Naturals

\* Variant P02 (comes-from-wrong-subscript) of the herbarium-sheet reference.

CONSTANTS Sheets, Botanists, Names, Handling, None

ASSUME /\ Handling \in [Sheets -> Nat]
       /\ None \notin Names

VARIABLES slips, consulted, reading, accepted, doubted

vars == <<slips, consulted, reading, accepted, doubted>>

Observe ==
    [slips     |-> slips,
     consulted |-> consulted,
     reading   |-> reading,
     accepted  |-> accepted,
     doubted   |-> doubted]

Stamps == UNION {1..Handling[s] : s \in Sheets}

Slip == [name : Names, stamp : Stamps]

TopName(S) == (CHOOSE r \in S : \A q \in S : q.stamp =< r.stamp).name

Allowances == [s \in Sheets |-> IF s = 1 THEN 2 ELSE 1]

Init ==
    /\ slips = [s \in Sheets |-> {}]
    /\ consulted = [s \in Sheets |-> 0]
    /\ reading = [b \in Botanists |-> [s \in Sheets |-> None]]
    /\ accepted = [s \in Sheets |-> None]
    /\ doubted = [s \in Sheets |-> FALSE]

Consult(b, s) ==
    /\ consulted[s] < Handling[s]
    /\ consulted' = [consulted EXCEPT ![s] = @ + 1]
    /\ reading' = [reading EXCEPT ![b][s] = consulted[s] + 1]
    /\ UNCHANGED <<slips, accepted, doubted>>

File(b, s, n) ==
    /\ reading[b][s] # None
    /\ LET filed == slips[s] \cup {[name |-> n, stamp |-> reading[b][s]]}
       IN  /\ slips' = [slips EXCEPT ![s] = filed]
           /\ accepted' = [accepted EXCEPT ![s] = TopName(filed)]
           /\ reading' = [reading EXCEPT ![b][s] = None]
           /\ doubted' = [doubted EXCEPT ![s] = FALSE]
    /\ UNCHANGED consulted

FileStep(b, s) == \E n \in Names : File(b, s, n)

Doubt(b, s) ==
    /\ reading[b][s] # None
    /\ doubted[s] = FALSE
    /\ doubted' = [doubted EXCEPT ![s] = TRUE]
    /\ UNCHANGED <<slips, consulted, reading, accepted>>

Next ==
    \/ \E b \in Botanists, s \in Sheets : Consult(b, s)
    \/ \E b \in Botanists, s \in Sheets : FileStep(b, s)
    \/ \E b \in Botanists, s \in Sheets : Doubt(b, s)

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ \A b \in Botanists, s \in Sheets : WF_vars(FileStep(b, s))

TypeOK ==
    /\ Observe.slips \in [Sheets -> SUBSET Slip]
    /\ Observe.consulted \in [Sheets -> Nat]
    /\ Observe.reading \in [Botanists -> [Sheets -> Stamps \cup {None}]]
    /\ Observe.accepted \in [Sheets -> Names \cup {None}]
    /\ Observe.doubted \in [Sheets -> BOOLEAN]

RecordWellFormed ==
    \A s \in Sheets :
        /\ \A r \in Observe.slips[s] :
              /\ r.name \in Names
              /\ r.stamp \in 1..Observe.consulted[s]
        /\ \A r, q \in Observe.slips[s] : r.stamp = q.stamp => r = q
        /\ \A b \in Botanists :
              Observe.reading[b][s] # None =>
                  Observe.reading[b][s] \in 1..Observe.consulted[s]
        /\ Observe.consulted[s] =< Handling[s]

AcceptedIsTopSlip ==
    \A s \in Sheets :
        IF Observe.slips[s] = {}
        THEN Observe.accepted[s] = None
        ELSE Observe.accepted[s] = TopName(Observe.slips[s])

Opening ==
    /\ \A s \in Sheets :
          /\ Observe.slips[s] = {}
          /\ Observe.consulted[s] = 0
          /\ Observe.accepted[s] = None
          /\ Observe.doubted[s] = FALSE
    /\ \A b \in Botanists, s \in Sheets : Observe.reading[b][s] = None

RecordOnlyGrows ==
    [][\A s \in Sheets :
          /\ Observe.slips[s] \subseteq Observe'.slips[s]
          /\ Observe.consulted[s] =< Observe'.consulted[s]
          /\ (Observe'.consulted[s] # Observe.consulted[s] =>
                 /\ Observe'.consulted[s] = Observe.consulted[s] + 1
                 /\ \E b \in Botanists :
                       Observe'.reading[b][s] = Observe'.consulted[s])
          /\ \A b \in Botanists :
                (/\ Observe'.reading[b][s] # None
                 /\ Observe'.reading[b][s] # Observe.reading[b][s])
                    => /\ Observe'.consulted[s] # Observe.consulted[s]
                       /\ Observe'.consulted[s] = Observe'.reading[b][s]]_Observe

SlipComesFromAConsultation ==
    [][\A s \in Sheets :
          /\ (Observe'.slips[s] # Observe.slips[s] =>
                 \E b \in Botanists :
                     \E r \in Observe'.slips[s] \ Observe.slips[s] :
                         /\ Observe'.slips[s] \ Observe.slips[s] = {r}
                         /\ Observe.reading[b][s] # None
                         /\ Observe'.reading[b][s] = None
                         /\ r.stamp =< Observe.reading[b][s])
          /\ \A b \in Botanists :
                (/\ Observe.reading[b][s] # None
                 /\ Observe'.reading[b][s] = None)
                    => Observe'.slips[s] \ Observe.slips[s] # {}]_(Observe.slips)

DoubtClearsOnlyOnFiling ==
    [][\A s \in Sheets :
          (/\ Observe.doubted[s] = TRUE
           /\ Observe'.doubted[s] = FALSE)
              => Observe'.slips[s] \ Observe.slips[s] # {}]_Observe

ConsultationIsAnswered ==
    /\ \A b \in Botanists, s \in Sheets :
          (Observe.reading[b][s] # None) ~> (Observe.reading[b][s] = None)
    /\ \A s \in Sheets :
          (Observe.doubted[s] = TRUE) ~> (Observe.doubted[s] = FALSE)

=============================================================================
