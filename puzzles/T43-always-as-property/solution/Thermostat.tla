---- MODULE Thermostat ----
EXTENDS Integers, TLC

(*--algorithm Thermostat {
  variables temp = 70;

  define {
    TypeOK == temp \in 60..80
    InRange == temp \in 60..80
    AlwaysInRange == []InRange
  }

  fair process (board = "Board") {
    tick:
      while (TRUE) {
        either {
          if (temp < 80) {
            temp := temp + 1;
          };
        } or {
          if (temp > 60) {
            temp := temp - 1;
          };
        } or {
          skip;
        };
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "a80ff0bc" /\ chksum(tla) = "dae3cdf9")
VARIABLE temp

(* define statement *)
TypeOK == temp \in 60..80
InRange == temp \in 60..80
AlwaysInRange == []InRange


vars == << temp >>

ProcSet == {"Board"}

Init == (* Global variables *)
        /\ temp = 70

board == \/ /\ IF temp < 80
                  THEN /\ temp' = temp + 1
                  ELSE /\ TRUE
                       /\ temp' = temp
         \/ /\ IF temp > 60
                  THEN /\ temp' = temp - 1
                  ELSE /\ TRUE
                       /\ temp' = temp
         \/ /\ TRUE
            /\ temp' = temp

Next == board

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(board)

\* END TRANSLATION 
================================
