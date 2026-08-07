---------------------------- MODULE PermitReview ----------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS Departments, MaxAmendments

Positions == {"none", "approved", "changes"}
Statuses  == {"open", "issued", "withdrawn"}

ASSUME /\ Departments # {}
       /\ IsFiniteSet(Departments)
       /\ Departments \cap {"applicant", "city"} = {}
       /\ MaxAmendments \in Nat

(* --algorithm PermitReview {
     variables
       position   = [d \in Departments |-> "none"],
       amendments = 0,
       status     = "open";

     define {
       Pending    == status = "open"
       ApprovedBy == {d \in Departments : position[d] = "approved"}
       Unanimous  == ApprovedBy = Departments

       Observe == [ issued     |-> status = "issued",
                    withdrawn  |-> status = "withdrawn",
                    approvedBy |-> ApprovedBy ]
     }

     process (Reviewer \in Departments)
     {
       Review:
         while (TRUE) {
           await Pending;
           with (p \in {"approved", "changes"}) {
             position[self] := p;
           }
         }
     }

     process (Applicant = "applicant")
     {
       AmendOrWithdraw:
         while (TRUE) {
           await Pending;
           either {
             await amendments < MaxAmendments;
             amendments := amendments + 1;
             position   := [d \in Departments |-> "none"];
           }
           or {
             status := "withdrawn";
           }
         }
     }

     process (City = "city")
     {
       Issue:
         while (TRUE) {
           await Pending /\ Unanimous;
           status := "issued";
         }
     }
   }
*)
\* BEGIN TRANSLATION (chksum(pcal) = "b7136896" /\ chksum(tla) = "8c98674")
VARIABLES position, amendments, status

(* define statement *)
Pending    == status = "open"
ApprovedBy == {d \in Departments : position[d] = "approved"}
Unanimous  == ApprovedBy = Departments

Observe == [ issued     |-> status = "issued",
             withdrawn  |-> status = "withdrawn",
             approvedBy |-> ApprovedBy ]


vars == << position, amendments, status >>

ProcSet == (Departments) \cup {"applicant"} \cup {"city"}

Init == (* Global variables *)
        /\ position = [d \in Departments |-> "none"]
        /\ amendments = 0
        /\ status = "open"

Reviewer(self) == /\ Pending
                  /\ \E p \in {"approved", "changes"}:
                       position' = [position EXCEPT ![self] = p]
                  /\ UNCHANGED << amendments, status >>

Applicant == /\ Pending
             /\ \/ /\ amendments < MaxAmendments
                   /\ amendments' = amendments + 1
                   /\ position' = [d \in Departments |-> "none"]
                   /\ UNCHANGED status
                \/ /\ status' = "withdrawn"
                   /\ UNCHANGED <<position, amendments>>

City == /\ Pending /\ Unanimous
        /\ status' = "issued"
        /\ UNCHANGED << position, amendments >>

Next == Applicant \/ City
           \/ (\E self \in Departments: Reviewer(self))

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

TypeOK ==
    /\ position   \in [Departments -> Positions]
    /\ amendments \in 0..MaxAmendments
    /\ status     \in Statuses

ObserveWellTyped ==
    Observe \in [issued: BOOLEAN, withdrawn: BOOLEAN, approvedBy: SUBSET Departments]

IssuedOnlyWhenUnanimous ==
    Observe.issued => (Observe.approvedBy = Departments)

OutcomeExclusive ==
    ~(Observe.issued /\ Observe.withdrawn)

AmendmentClearsApprovals ==
    [][ (amendments' # amendments) => (Observe'.approvedBy = {}) ]_vars

IssuanceIsFinal ==
    [](Observe.issued => []Observe.issued)

WithdrawalIsFinal ==
    [](Observe.withdrawn => []Observe.withdrawn)

OutcomeIsAbsorbing ==
    [][ (Observe.issued \/ Observe.withdrawn) => (Observe' = Observe) ]_vars

=============================================================================
