---- MODULE Clock ----
EXTENDS Integers

(*--algorithm Clock {
  variables hour = 11, reset = FALSE;

  define {
    TypeOK == hour \in 11..12 /\ reset \in BOOLEAN
    ReachesNoon == <>( hour = 12 )
  }

  process (resetter = "Resetter") {
    loop:
      while (TRUE) {
        reset := ~reset;
      }
  }

  fair process (ticker = "Ticker") {
    advance:
      while (hour < 12) {
        await ~reset;
        hour := 12;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "c70b4094" /\ chksum(tla) = "810867ea")
VARIABLES hour, reset, pc

(* define statement *)
TypeOK == hour \in 11..12 /\ reset \in BOOLEAN
ReachesNoon == <>( hour = 12 )


vars == << hour, reset, pc >>

ProcSet == {"Resetter"} \cup {"Ticker"}

Init == (* Global variables *)
        /\ hour = 11
        /\ reset = FALSE
        /\ pc = [self \in ProcSet |-> CASE self = "Resetter" -> "loop"
                                        [] self = "Ticker" -> "advance"]

loop == /\ pc["Resetter"] = "loop"
        /\ reset' = ~reset
        /\ pc' = [pc EXCEPT !["Resetter"] = "loop"]
        /\ hour' = hour

resetter == loop

advance == /\ pc["Ticker"] = "advance"
           /\ IF hour < 12
                 THEN /\ ~reset
                      /\ hour' = 12
                      /\ pc' = [pc EXCEPT !["Ticker"] = "advance"]
                 ELSE /\ pc' = [pc EXCEPT !["Ticker"] = "Done"]
                      /\ hour' = hour
           /\ reset' = reset

ticker == advance

Next == resetter \/ ticker

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(ticker)

\* END TRANSLATION
====
