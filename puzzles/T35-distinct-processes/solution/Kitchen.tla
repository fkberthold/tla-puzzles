---- MODULE Kitchen ----
EXTENDS Integers, TLC

(*--algorithm Kitchen {
  variables cooked = 0, served = 0;

  define {
    TypeOK == cooked \in 0..3 /\ served \in 0..3
    NeverOverServe == served <= cooked
  }

  fair process (chef = "Chef") {
    cookLoop:
      while (cooked < 3) {
        bake:
          cooked := cooked + 1;
      }
  }

  fair process (server = "Server") {
    serveLoop:
      while (served < 3) {
        deliver:
          served := served + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "f3282c9b" /\ chksum(tla) = "4180f4c6")
VARIABLES pc, cooked, served

(* define statement *)
TypeOK == cooked \in 0..3 /\ served \in 0..3
NeverOverServe == served <= cooked


vars == << pc, cooked, served >>

ProcSet == {"Chef"} \cup {"Server"}

Init == (* Global variables *)
        /\ cooked = 0
        /\ served = 0
        /\ pc = [self \in ProcSet |-> CASE self = "Chef" -> "cookLoop"
                                        [] self = "Server" -> "serveLoop"]

cookLoop == /\ pc["Chef"] = "cookLoop"
            /\ IF cooked < 3
                  THEN /\ pc' = [pc EXCEPT !["Chef"] = "bake"]
                  ELSE /\ pc' = [pc EXCEPT !["Chef"] = "Done"]
            /\ UNCHANGED << cooked, served >>

bake == /\ pc["Chef"] = "bake"
        /\ cooked' = cooked + 1
        /\ pc' = [pc EXCEPT !["Chef"] = "cookLoop"]
        /\ UNCHANGED served

chef == cookLoop \/ bake

serveLoop == /\ pc["Server"] = "serveLoop"
             /\ IF served < 3
                   THEN /\ pc' = [pc EXCEPT !["Server"] = "deliver"]
                   ELSE /\ pc' = [pc EXCEPT !["Server"] = "Done"]
             /\ UNCHANGED << cooked, served >>

deliver == /\ pc["Server"] = "deliver"
           /\ served' = served + 1
           /\ pc' = [pc EXCEPT !["Server"] = "serveLoop"]
           /\ UNCHANGED cooked

server == serveLoop \/ deliver

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
================================
