---- MODULE Light ----
EXTENDS Integers, TLC

(*--algorithm Light {
  variables
    tick = 0,
    display = "red",
    goFlag = FALSE;

  define {
    Color(t) ==
      CASE t \in {0, 1}    -> "red"
        [] t = 2           -> "yellow"
        [] t \in {3, 4, 5} -> "green"
        [] OTHER           -> "off"
    IsGo(t) == IF Color(t) = "green" THEN TRUE ELSE FALSE

    TypeOK ==
      /\ tick \in 0..5
      /\ display \in {"red", "yellow", "green", "off"}
      /\ goFlag \in BOOLEAN
    DisplayMatches == display = Color(tick)
    GoMatches == goFlag = IsGo(tick)
  }

  fair process (controller = "Ctrl") {
    advance:
      while (tick < 5) {
        display := Color(tick + 1);
        goFlag := IsGo(tick + 1);
        tick := tick + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "54a72ecf" /\ chksum(tla) = "abde8a4c")
VARIABLES tick, display, goFlag, pc

(* define statement *)
Color(t) ==
  CASE t \in {0, 1}    -> "red"
    [] t = 2           -> "yellow"
    [] t \in {3, 4, 5} -> "green"
    [] OTHER           -> "off"
IsGo(t) == IF Color(t) = "green" THEN TRUE ELSE FALSE

TypeOK ==
  /\ tick \in 0..5
  /\ display \in {"red", "yellow", "green", "off"}
  /\ goFlag \in BOOLEAN
DisplayMatches == display = Color(tick)
GoMatches == goFlag = IsGo(tick)


vars == << tick, display, goFlag, pc >>

ProcSet == {"Ctrl"}

Init == (* Global variables *)
        /\ tick = 0
        /\ display = "red"
        /\ goFlag = FALSE
        /\ pc = [self \in ProcSet |-> "advance"]

advance == /\ pc["Ctrl"] = "advance"
           /\ IF tick < 5
                 THEN /\ display' = Color(tick + 1)
                      /\ goFlag' = IsGo(tick + 1)
                      /\ tick' = tick + 1
                      /\ pc' = [pc EXCEPT !["Ctrl"] = "advance"]
                 ELSE /\ pc' = [pc EXCEPT !["Ctrl"] = "Done"]
                      /\ UNCHANGED << tick, display, goFlag >>

controller == advance

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == controller
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(controller)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
