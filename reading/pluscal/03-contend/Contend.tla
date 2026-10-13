---- MODULE Contend ----

(* --algorithm contend {
     variables lock = FALSE;
     fair  process (slow = "s") {
       s0: while (TRUE) { await ~lock; lock := TRUE; s1: lock := FALSE } }
     fair+ process (keen = "k") {
       k0: while (TRUE) { await ~lock; lock := TRUE; k1: lock := FALSE } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "74cc4590" /\ chksum(tla) = "3f0c1edb")
VARIABLES pc, lock

vars == << pc, lock >>

ProcSet == {"s"} \cup {"k"}

Init == (* Global variables *)
        /\ lock = FALSE
        /\ pc = [self \in ProcSet |-> CASE self = "s" -> "s0"
                                        [] self = "k" -> "k0"]

s0 == /\ pc["s"] = "s0"
      /\ ~lock
      /\ lock' = TRUE
      /\ pc' = [pc EXCEPT !["s"] = "s1"]

s1 == /\ pc["s"] = "s1"
      /\ lock' = FALSE
      /\ pc' = [pc EXCEPT !["s"] = "s0"]

slow == s0 \/ s1

k0 == /\ pc["k"] = "k0"
      /\ ~lock
      /\ lock' = TRUE
      /\ pc' = [pc EXCEPT !["k"] = "k1"]

k1 == /\ pc["k"] = "k1"
      /\ lock' = FALSE
      /\ pc' = [pc EXCEPT !["k"] = "k0"]

keen == k0 \/ k1

Next == slow \/ keen

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(slow)
        /\ SF_vars(keen)

\* END TRANSLATION 

TypeOK == lock \in BOOLEAN /\ pc \in [ProcSet -> {"s0","s1","k0","k1"}]

Held == lock <=> (pc["s"] = "s1" \/ pc["k"] = "k1")

MutEx == ~(pc["s"] = "s1" /\ pc["k"] = "k1")

KeenEnters == []<>(pc["k"] = "k1")
SlowEnters == []<>(pc["s"] = "s1")
====
