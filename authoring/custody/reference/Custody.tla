------------------------------- MODULE Custody -------------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS A, B, H, N, Base, Hol

ASSUME A # B
ASSUME H \in Nat \ {0}
ASSUME N \in Nat
ASSUME Base \in [1..H -> {A, B}]
ASSUME /\ DOMAIN Hol \subseteq 1..H
       /\ \A d \in DOMAIN Hol : Hol[d] \in {A, B}

Parents == {A, B}
Days == 1..H
NoDay == 0

Other(p) == IF p = A THEN B ELSE A

Scheduled(d) == IF d \in DOMAIN Hol THEN Hol[d] ELSE Base[d]

VARIABLES today, swapped, pending

vars == <<today, swapped, pending>>

TypeOK ==
    /\ today \in {NoDay} \cup Days
    /\ swapped \subseteq Days
    /\ pending \in [Parents -> {NoDay} \cup Days]

Custodian(d) == IF d \in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)

Observe == [today |-> today,
            custodian |-> [d \in Days |-> Custodian(d)],
            pending |-> pending]

Init ==
    /\ today = NoDay
    /\ swapped = {}
    /\ pending = [p \in Parents |-> NoDay]

BeginDay ==
    /\ today < H
    /\ today' = today + 1
    /\ pending' = [p \in Parents |->
                      IF pending[p] = today + 1 THEN NoDay ELSE pending[p]]
    /\ UNCHANGED swapped

Propose(p, d) ==
    /\ pending[p] = NoDay
    /\ d > today
    /\ d \notin swapped
    /\ pending' = [pending EXCEPT ![p] = d]
    /\ UNCHANGED <<today, swapped>>

Accept(p) ==
    /\ pending[p] # NoDay
    /\ Cardinality(swapped) < N
    /\ swapped' = swapped \cup {pending[p]}
    /\ pending' = [q \in Parents |->
                      IF pending[q] = pending[p] THEN NoDay ELSE pending[q]]
    /\ UNCHANGED today

Drop(p) ==
    /\ pending[p] # NoDay
    /\ pending' = [pending EXCEPT ![p] = NoDay]
    /\ UNCHANGED <<today, swapped>>

Next ==
    \/ BeginDay
    \/ \E p \in Parents :
          \/ Accept(p)
          \/ Drop(p)
          \/ \E d \in Days : Propose(p, d)

Spec == Init /\ [][Next]_vars /\ WF_vars(BeginDay)

TotalCustody == Observe.custodian \in [Days -> Parents]

OpeningBaseline == \A d \in Days : Observe.custodian[d] = Scheduled(d)

FlipOnce ==
    [][\A d \in Days :
          Observe.custodian[d] # Scheduled(d) =>
              Observe'.custodian[d] = Observe.custodian[d]]_Observe

FlipCause ==
    [][\A d \in Days :
          Observe'.custodian[d] # Observe.custodian[d] =>
              \E p \in Parents :
                  /\ Observe.pending[p] = d
                  /\ Observe'.pending[p] # d]_Observe

PastFixed ==
    [][\A d \in Days :
          d <= Observe.today => Observe'.custodian[d] = Observe.custodian[d]]_Observe

PendingFresh ==
    \A p \in Parents :
        \/ Observe.pending[p] = NoDay
        \/ /\ Observe.pending[p] \in Days
           /\ Observe.pending[p] > Observe.today
           /\ Observe.custodian[Observe.pending[p]] =
                  Scheduled(Observe.pending[p])

CapRespected ==
    Cardinality({d \in Days : Observe.custodian[d] # Scheduled(d)}) <= N

QuietAtEnd ==
    [][Observe.today = H => Observe' = Observe]_Observe

OpeningNoDayBegun == Observe.today = NoDay

TodayMarches ==
    [][\/ Observe'.today = Observe.today
       \/ /\ Observe.today = NoDay
          /\ Observe'.today = 1
       \/ /\ Observe.today \in Days
          /\ Observe'.today = Observe.today + 1]_Observe

WindowCompletes == <>(Observe.today = H)

===============================================================================
