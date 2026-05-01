---- MODULE Kitchen ----
EXTENDS Integers, TLC

(*--algorithm Kitchen {
  variables dish = FALSE, delivered = 0;

  define {
    TypeOK == dish \in BOOLEAN /\ delivered \in 0..3
    OrderedDelivery == delivered <= 3
    EventuallyDone == <>(delivered = 3)
  }

  fair process (chef = "Chef") {
    cook:
      while (delivered < 3) {
        await ~dish;
        dish := TRUE;
      }
  }

  fair process (server = "Server") {
    take:
      while (delivered < 3) {
        await dish;
        dish := FALSE;
        delivered := delivered + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "a6a233d2" /\ chksum(tla) = "146c29d4")
VARIABLES dish, delivered, pc

(* define statement *)
TypeOK == dish \in BOOLEAN /\ delivered \in 0..3
OrderedDelivery == delivered <= 3
EventuallyDone == <>(delivered = 3)


vars == << dish, delivered, pc >>

ProcSet == {"Chef"} \cup {"Server"}

Init == (* Global variables *)
        /\ dish = FALSE
        /\ delivered = 0
        /\ pc = [self \in ProcSet |-> CASE self = "Chef" -> "cook"
                                        [] self = "Server" -> "take"]

cook == /\ pc["Chef"] = "cook"
        /\ IF delivered < 3
              THEN /\ ~dish
                   /\ dish' = TRUE
                   /\ pc' = [pc EXCEPT !["Chef"] = "cook"]
              ELSE /\ pc' = [pc EXCEPT !["Chef"] = "Done"]
                   /\ dish' = dish
        /\ UNCHANGED delivered

chef == cook

take == /\ pc["Server"] = "take"
        /\ IF delivered < 3
              THEN /\ dish
                   /\ dish' = FALSE
                   /\ delivered' = delivered + 1
                   /\ pc' = [pc EXCEPT !["Server"] = "take"]
              ELSE /\ pc' = [pc EXCEPT !["Server"] = "Done"]
                   /\ UNCHANGED << dish, delivered >>

server == take

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == chef \/ server
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(chef)
        /\ WF_vars(server)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
