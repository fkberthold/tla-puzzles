---- MODULE OrderStates ----
EXTENDS Integers

States == {"new", "paid", "shipped", "delivered", "cancelled"}

ValidTransition(s, t) ==
  \/ (s = "new"      /\ t = "paid")
  \/ (s = "paid"     /\ t = "shipped")
  \/ (s = "shipped"  /\ t = "delivered")
  \/ (s \in {"new", "paid", "shipped"} /\ t = "cancelled")

Terminal(s) == s \in {"delivered", "cancelled"}

====
