---- MODULE Ex4Tanks ----
EXTENDS Integers, TLC

(*--algorithm tanks {
  variables
    tanks = <<7, 0>>;

  {
    Pump:
      with (amount = 3) {
        tanks[1] := tanks[1] - amount ||
        tanks[2] := tanks[2] + amount;
      };
    Audit:
      assert tanks[1] + tanks[2] = 7;
    Settle:
      assert tanks[2] = 3;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "f4426267" /\ chksum(tla) = "619507db")
VARIABLES pc, tanks

vars == << pc, tanks >>

Init == (* Global variables *)
        /\ tanks = <<7, 0>>
        /\ pc = "Pump"

Pump == /\ pc = "Pump"
        /\ LET amount == 3 IN
             tanks' = [tanks EXCEPT ![1] = tanks[1] - amount,
                                    ![2] = tanks[2] + amount]
        /\ pc' = "Audit"

Audit == /\ pc = "Audit"
         /\ Assert(tanks[1] + tanks[2] = 7,
                   "Failure of assertion at line 15, column 7.")
         /\ pc' = "Settle"
         /\ tanks' = tanks

Settle == /\ pc = "Settle"
          /\ Assert(tanks[2] = 3,
                    "Failure of assertion at line 17, column 7.")
          /\ pc' = "Done"
          /\ tanks' = tanks

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Pump \/ Audit \/ Settle
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION
====
