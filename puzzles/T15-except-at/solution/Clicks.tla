---- MODULE Clicks ----
EXTENDS Integers, TLC

(*--algorithm Clicks {
  variables
    clicks = [u \in {"u1", "u2", "u3"} |-> 0],
    step = 0;

  define {
    Users == DOMAIN clicks
    Total == clicks["u1"] + clicks["u2"] + clicks["u3"]

    TypeOK ==
      /\ Users = {"u1", "u2", "u3"}
      /\ \A u \in Users : clicks[u] \in 0..2
      /\ step \in 0..4
    TotalEqualsStep == Total = step
    EndsCorrect == step = 4 =>
      (clicks["u1"] = 2 /\ clicks["u2"] = 1 /\ clicks["u3"] = 1)
  }

  fair process (dashboard = "Dash") {
    clickU1:
      clicks := [clicks EXCEPT !["u1"] = @ + 1];
      step := step + 1;
    clickU2:
      clicks := [clicks EXCEPT !["u2"] = @ + 1];
      step := step + 1;
    clickU1again:
      clicks := [clicks EXCEPT !["u1"] = @ + 1];
      step := step + 1;
    clickU3:
      clicks := [clicks EXCEPT !["u3"] = @ + 1];
      step := step + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
