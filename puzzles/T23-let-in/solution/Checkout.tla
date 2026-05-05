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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
