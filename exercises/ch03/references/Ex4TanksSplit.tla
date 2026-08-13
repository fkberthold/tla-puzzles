---- MODULE Ex4TanksSplit ----
EXTENDS Integers, TLC

\* The seeded-wrong pump. The two halves of the transfer are legal PlusCal on
\* their own, so this module translates and runs. What changed is the labels:
\* Drain and Fill are separate steps, so Audit sits between them and sees a
\* moment when three litres exist in neither tank.

(*--algorithm tanks {
  variables
    tanks = <<7, 0>>;

  {
    Drain:
      tanks[1] := tanks[1] - 3;
    Audit:
      assert tanks[1] + tanks[2] = 7;
    Fill:
      tanks[2] := tanks[2] + 3;
    Settle:
      assert tanks[2] = 3;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "29ba82c4" /\ chksum(tla) = "30593036")
VARIABLES pc, tanks

vars == << pc, tanks >>

Init == (* Global variables *)
        /\ tanks = <<7, 0>>
        /\ pc = "Drain"

Drain == /\ pc = "Drain"
         /\ tanks' = [tanks EXCEPT ![1] = tanks[1] - 3]
         /\ pc' = "Audit"

Audit == /\ pc = "Audit"
         /\ Assert(tanks[1] + tanks[2] = 7,
                   "Failure of assertion at line 12, column 7.")
         /\ pc' = "Fill"
         /\ tanks' = tanks

Fill == /\ pc = "Fill"
        /\ tanks' = [tanks EXCEPT ![2] = tanks[2] + 3]
        /\ pc' = "Settle"

Settle == /\ pc = "Settle"
          /\ Assert(tanks[2] = 3,
                    "Failure of assertion at line 16, column 7.")
          /\ pc' = "Done"
          /\ tanks' = tanks

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Drain \/ Audit \/ Fill \/ Settle
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION
====
