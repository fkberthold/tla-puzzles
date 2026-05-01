---- MODULE Checkout ----
EXTENDS Integers, TLC

(*--algorithm Checkout {
  variables
    base = 50,
    discount = 10,
    shipping = 5,
    final = 0,
    phase = 0;

  define {
    Final(b, d, s) ==
      LET discountAmt == (b * d) \div 100
          subtotal    == b - discountAmt
      IN subtotal + s

    TypeOK ==
      /\ base \in 0..100
      /\ discount \in 0..100
      /\ shipping \in 0..20
      /\ final \in 0..200
      /\ phase \in 0..2
    Correct == phase = 2 => final = Final(base, discount, shipping)
    BoundedFinal == final <= base + shipping
  }

  fair process (cashier = "Cash") {
    compute:
      final := Final(base, discount, shipping);
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "98ca47d7" /\ chksum(tla) = "33b24426")
VARIABLES pc, base, discount, shipping, final, phase

(* define statement *)
Final(b, d, s) ==
  LET discountAmt == (b * d) \div 100
      subtotal    == b - discountAmt
  IN subtotal + s

TypeOK ==
  /\ base \in 0..100
  /\ discount \in 0..100
  /\ shipping \in 0..20
  /\ final \in 0..200
  /\ phase \in 0..2
Correct == phase = 2 => final = Final(base, discount, shipping)
BoundedFinal == final <= base + shipping


vars == << pc, base, discount, shipping, final, phase >>

ProcSet == {"Cash"}

Init == (* Global variables *)
        /\ base = 50
        /\ discount = 10
        /\ shipping = 5
        /\ final = 0
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "compute"]

compute == /\ pc["Cash"] = "compute"
           /\ final' = Final(base, discount, shipping)
           /\ phase' = phase + 1
           /\ pc' = [pc EXCEPT !["Cash"] = "finish"]
           /\ UNCHANGED << base, discount, shipping >>

finish == /\ pc["Cash"] = "finish"
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Cash"] = "Done"]
          /\ UNCHANGED << base, discount, shipping, final >>

cashier == compute \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == cashier
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(cashier)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
