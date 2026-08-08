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

=============================================================================
