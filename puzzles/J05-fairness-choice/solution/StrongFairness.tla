---- MODULE StrongFairness ----
\* Side C: strong fairness. The action eventually fires
\* if it is enabled INFINITELY OFTEN, even if it gets disabled in between.
\*
\* Two competing servers; only one can serve at a time. We require server S1
\* to serve eventually. With WEAK fairness alone, S1 could be repeatedly
\* disabled (when S2 is the chosen server) and stall forever. With STRONG
\* fairness on S1's serve, it must eventually fire whenever it's repeatedly
\* enabled.
EXTENDS Integers, TLC

(*--algorithm StrongFairness {
  variables servedBy = "none", round = 0;

  define {
    TypeOK ==
      /\ servedBy \in {"none", "S1", "S2"}
      /\ round \in 0..3
    S1EventuallyServes == <>(servedBy = "S1")
  }

  fair process (server1 = "S1") {
    s1: while (round < 3) {
          await servedBy = "none";
          servedBy := "S1";
          round := round + 1;
        };
  }

  fair process (server2 = "S2") {
    s2: while (round < 3) {
          await servedBy = "none";
          servedBy := "S2";
          round := round + 1;
        };
  }

  fair process (clock = "Clock") {
    tick: while (round < 3) {
            await servedBy # "none";
            servedBy := "none";
          };
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES pc, servedBy, round

(* define statement *)
TypeOK ==
  /\ servedBy \in {"none", "S1", "S2"}
  /\ round \in 0..3
S1EventuallyServes == <>(servedBy = "S1")


vars == << pc, servedBy, round >>

ProcSet == {"S1"} \cup {"S2"} \cup {"Clock"}

Init == (* Global variables *)
        /\ servedBy = "none"
        /\ round = 0
        /\ pc = [self \in ProcSet |-> CASE self = "S1" -> "s1"
                                        [] self = "S2" -> "s2"
                                        [] self = "Clock" -> "tick"]

s1 == /\ pc["S1"] = "s1"
      /\ IF round < 3
            THEN /\ servedBy = "none"
                 /\ servedBy' = "S1"
                 /\ round' = round + 1
                 /\ pc' = [pc EXCEPT !["S1"] = "s1"]
            ELSE /\ pc' = [pc EXCEPT !["S1"] = "Done"]
                 /\ UNCHANGED << servedBy, round >>

server1 == s1

s2 == /\ pc["S2"] = "s2"
      /\ IF round < 3
            THEN /\ servedBy = "none"
                 /\ servedBy' = "S2"
                 /\ round' = round + 1
                 /\ pc' = [pc EXCEPT !["S2"] = "s2"]
            ELSE /\ pc' = [pc EXCEPT !["S2"] = "Done"]
                 /\ UNCHANGED << servedBy, round >>

server2 == s2

tick == /\ pc["Clock"] = "tick"
        /\ IF round < 3
              THEN /\ servedBy # "none"
                   /\ servedBy' = "none"
                   /\ pc' = [pc EXCEPT !["Clock"] = "tick"]
              ELSE /\ pc' = [pc EXCEPT !["Clock"] = "Done"]
                   /\ UNCHANGED servedBy
        /\ round' = round

clock == tick

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == server1 \/ server2 \/ clock
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(server1)
        /\ WF_vars(server2)
        /\ WF_vars(clock)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
