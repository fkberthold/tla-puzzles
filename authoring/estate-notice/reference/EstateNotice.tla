---------------------------- MODULE EstateNotice ----------------------------
CONSTANTS Creditors

VARIABLES standing, notice, distributed

vars == <<standing, notice, distributed>>

Standings == {"none", "lodged", "admitted", "paid", "rejected", "outOfTime"}

Decisions == {"admitted", "rejected"}

Notices == {"open", "closed"}

Observe == [standing |-> standing, notice |-> notice, distributed |-> distributed]

Unsettled(c) == standing[c] \in {"lodged", "admitted"}

Init ==
    /\ standing = [c \in Creditors |-> "none"]
    /\ notice = "open"
    /\ distributed = FALSE

Lodge(c) ==
    /\ notice = "open"
    /\ standing[c] = "none"
    /\ standing' = [standing EXCEPT ![c] = "lodged"]
    /\ UNCHANGED <<notice, distributed>>

ComeForward(c) ==
    /\ notice = "closed"
    /\ standing[c] = "none"
    /\ standing' = [standing EXCEPT ![c] = "outOfTime"]
    /\ UNCHANGED <<notice, distributed>>

Close ==
    /\ notice = "open"
    /\ notice' = "closed"
    /\ UNCHANGED <<standing, distributed>>

Decide(c, d) ==
    /\ standing[c] = "lodged"
    /\ standing' = [standing EXCEPT ![c] = d]
    /\ UNCHANGED <<notice, distributed>>

DecideStep(c) == \E d \in Decisions : Decide(c, d)

Pay(c) ==
    /\ standing[c] = "admitted"
    /\ standing' = [standing EXCEPT ![c] = "paid"]
    /\ UNCHANGED <<notice, distributed>>

Distribute ==
    /\ notice = "closed"
    /\ distributed = FALSE
    /\ \A c \in Creditors : ~Unsettled(c)
    /\ distributed' = TRUE
    /\ UNCHANGED <<standing, notice>>

Next ==
    \/ Close
    \/ Distribute
    \/ \E c \in Creditors : Lodge(c)
    \/ \E c \in Creditors : ComeForward(c)
    \/ \E c \in Creditors : DecideStep(c)
    \/ \E c \in Creditors : Pay(c)

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(Close)
    /\ \A c \in Creditors : WF_vars(DecideStep(c))
    /\ \A c \in Creditors : WF_vars(Pay(c))
    /\ WF_vars(Distribute)

TypeOK ==
    /\ Observe.standing \in [Creditors -> Standings]
    /\ Observe.notice \in Notices
    /\ Observe.distributed \in BOOLEAN

SheDistributesOnlyWhenClear ==
    Observe.distributed =>
        /\ Observe.notice = "closed"
        /\ \A c \in Creditors :
               Observe.standing[c] \notin {"lodged", "admitted"}

ClaimsStartWithTheCreditor ==
    [][\A c \in Creditors :
          (Observe.standing[c] = "none" /\ Observe'.standing[c] # "none") =>
              \/ /\ Observe.notice = "open"
                 /\ Observe'.standing[c] = "lodged"
              \/ /\ Observe.notice = "closed"
                 /\ Observe'.standing[c] = "outOfTime"]_Observe

ALodgedClaimEndsInHerDecision ==
    [][\A c \in Creditors :
          (Observe.standing[c] = "lodged" /\ Observe'.standing[c] # "lodged") =>
              Observe'.standing[c] \in Decisions]_Observe

ADecisionStands ==
    [][\A c \in Creditors :
          /\ (Observe.standing[c] = "admitted" =>
                  Observe'.standing[c] \in {"admitted", "paid"})
          /\ (Observe.standing[c] \in {"rejected", "paid", "outOfTime"} =>
                  Observe'.standing[c] = Observe.standing[c])]_Observe

TheNoticeNeverReopens ==
    [][Observe.notice = "closed" => Observe'.notice = "closed"]_Observe

TheDistributionIsNeverUndone ==
    [][Observe.distributed => Observe'.distributed]_Observe

TheEstateIsEventuallyDistributed == <>Observe.distributed

=============================================================================
