---- MODULE Inventory ----
EXTENDS Integers, TLC

(*--algorithm Inventory {
  variables
    apples = 5,
    bananas = 5,
    cherries = 5,
    dates = 5,
    elderberries = 5,
    figs = 5,
    grapes = 5,
    honeydew = 5,
    sold = 0;

  define {
    TypeOK ==
      /\ apples \in 0..5
      /\ bananas \in 0..5
      /\ cherries \in 0..5
      /\ dates \in 0..5
      /\ elderberries \in 0..5
      /\ figs \in 0..5
      /\ grapes \in 0..5
      /\ honeydew \in 0..5
      /\ sold \in 0..40
    \* Deliberate violation: claims sold can never reach 6 — but it can.
    NotPastFive == sold <= 5
  }

  fair process (seller = "Seller") {
    work:
      while (sold < 8) {
        either { apples := apples - 1; }
        or     { bananas := bananas - 1; }
        or     { cherries := cherries - 1; }
        or     { dates := dates - 1; };
        sold := sold + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "18b2cf8b" /\ chksum(tla) = "d6853a04")
VARIABLES pc, apples, bananas, cherries, dates, elderberries, figs, grapes, 
          honeydew, sold

(* define statement *)
TypeOK ==
  /\ apples \in 0..5
  /\ bananas \in 0..5
  /\ cherries \in 0..5
  /\ dates \in 0..5
  /\ elderberries \in 0..5
  /\ figs \in 0..5
  /\ grapes \in 0..5
  /\ honeydew \in 0..5
  /\ sold \in 0..40

NotPastFive == sold <= 5


vars == << pc, apples, bananas, cherries, dates, elderberries, figs, grapes, 
           honeydew, sold >>

ProcSet == {"Seller"}

Init == (* Global variables *)
        /\ apples = 5
        /\ bananas = 5
        /\ cherries = 5
        /\ dates = 5
        /\ elderberries = 5
        /\ figs = 5
        /\ grapes = 5
        /\ honeydew = 5
        /\ sold = 0
        /\ pc = [self \in ProcSet |-> "work"]

work == /\ pc["Seller"] = "work"
        /\ IF sold < 8
              THEN /\ \/ /\ apples' = apples - 1
                         /\ UNCHANGED <<bananas, cherries, dates>>
                      \/ /\ bananas' = bananas - 1
                         /\ UNCHANGED <<apples, cherries, dates>>
                      \/ /\ cherries' = cherries - 1
                         /\ UNCHANGED <<apples, bananas, dates>>
                      \/ /\ dates' = dates - 1
                         /\ UNCHANGED <<apples, bananas, cherries>>
                   /\ sold' = sold + 1
                   /\ pc' = [pc EXCEPT !["Seller"] = "work"]
              ELSE /\ pc' = [pc EXCEPT !["Seller"] = "Done"]
                   /\ UNCHANGED << apples, bananas, cherries, dates, sold >>
        /\ UNCHANGED << elderberries, figs, grapes, honeydew >>

seller == work

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == seller
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(seller)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
