------------------------------- MODULE Bureau -------------------------------
CONSTANTS Operators, Bands

VARIABLES filed, credited

vars == <<filed, credited>>

ClaimsBy(o) == [station : Operators \ {o}, band : Bands]

Observe == [filed |-> filed, credited |-> credited]

Corroborated(a, c, b) ==
    /\ [station |-> c, band |-> b] \in Observe.filed[a]
    /\ [station |-> a, band |-> b] \in Observe.filed[c]

Init ==
    /\ filed = [o \in Operators |-> {}]
    /\ credited = [o \in Operators |-> {}]

Mail(o) ==
    /\ \E env \in (SUBSET ClaimsBy(o)) \ {{}} :
           filed' = [filed EXCEPT ![o] = @ \cup env]
    /\ UNCHANGED credited

Credit(a, c, b) ==
    /\ Corroborated(a, c, b)
    /\ [station |-> c, band |-> b] \notin credited[a]
    /\ credited' = [credited EXCEPT
                        ![a] = @ \cup {[station |-> c, band |-> b]},
                        ![c] = @ \cup {[station |-> a, band |-> b]}]
    /\ UNCHANGED filed

CreditStep == \E a, c \in Operators, b \in Bands : Credit(a, c, b)

Next ==
    \/ \E o \in Operators : Mail(o)
    \/ CreditStep

Spec == Init /\ [][Next]_vars /\ WF_vars(CreditStep)

TypeOK ==
    /\ filed \in [Operators -> SUBSET [station : Operators, band : Bands]]
    /\ credited \in [Operators -> SUBSET [station : Operators, band : Bands]]

Opening ==
    \A o \in Operators :
        /\ Observe.filed[o] = {}
        /\ Observe.credited[o] = {}

FilesWellFormed ==
    \A o \in Operators : Observe.filed[o] \subseteq ClaimsBy(o)

CreditIsCorroborated ==
    \A o \in Operators :
        \A f \in Observe.credited[o] : Corroborated(o, f.station, f.band)

CreditIsMutual ==
    \A a, c \in Operators, b \in Bands :
        [station |-> c, band |-> b] \in Observe.credited[a]
            <=> [station |-> a, band |-> b] \in Observe.credited[c]

FilesOnlyGrow ==
    [][\A o \in Operators : Observe.filed[o] \subseteq Observe'.filed[o]]_Observe

OneEnvelopeAtATime ==
    [][Observe'.filed # Observe.filed =>
           \E o \in Operators :
               /\ \A p \in Operators \ {o} : Observe'.filed[p] = Observe.filed[p]
               /\ Observe'.credited = Observe.credited]_Observe

CreditComesWhole ==
    [][Observe'.credited # Observe.credited =>
           \E a, c \in Operators, b \in Bands :
               /\ a # c
               /\ [station |-> c, band |-> b] \notin Observe.credited[a]
               /\ Observe'.credited[a] =
                      Observe.credited[a] \cup {[station |-> c, band |-> b]}
               /\ Observe'.credited[c] =
                      Observe.credited[c] \cup {[station |-> a, band |-> b]}
               /\ \A p \in Operators \ {a, c} :
                      Observe'.credited[p] = Observe.credited[p]
               /\ Observe'.filed = Observe.filed]_Observe

CreditIsPermanent ==
    [][\A o \in Operators : Observe.credited[o] \subseteq Observe'.credited[o]]_Observe

BureauKeepsUp ==
    \A a, c \in Operators, b \in Bands :
        (Corroborated(a, c, b)
             /\ [station |-> c, band |-> b] \notin Observe.credited[a])
            ~> [station |-> c, band |-> b] \in Observe.credited[a]

=============================================================================
