---- MODULE FlakyLink ----
\* The system behind drill item 05-flaky-link, with one spec per candidate
\* fairness conjunct. The cfg picks the spec; the property is the delivery
\* guarantee the conjunct is supposed to buy.
VARIABLES link, msg

vars == <<link, msg>>

Init == /\ link = "up"
        /\ msg = "pending"

LinkDown == /\ link = "up"
            /\ link' = "down"
            /\ UNCHANGED msg

LinkUp == /\ link = "down"
          /\ link' = "up"
          /\ UNCHANGED msg

Deliver == /\ link = "up"
           /\ msg = "pending"
           /\ msg' = "delivered"
           /\ UNCHANGED link

Next == LinkDown \/ LinkUp \/ Deliver

Spec == Init /\ [][Next]_vars

\* The answer.
SpecSF == Spec /\ SF_vars(Deliver)

\* Neighbours.
SpecWF         == Spec /\ WF_vars(Deliver)
SpecWFNext     == Spec /\ WF_vars(Next)
SpecSFNext     == Spec /\ SF_vars(Next)
SpecWFBoth     == Spec /\ WF_vars(LinkUp) /\ WF_vars(Deliver)
SpecSFLinkFair == Spec /\ SF_vars(Deliver) /\ WF_vars(LinkUp)

\* Unconditional delivery. No conjunct on Deliver alone buys this, because a
\* link that stays down forever is a behaviour the prompt allows.
Delivered == (msg = "pending") ~> (msg = "delivered")

\* What strong fairness on Deliver buys: delivery whenever the link keeps
\* coming back, however briefly.
DeliveredIfLinkReturns == []<>(link = "up") => <>(msg = "delivered")
====
