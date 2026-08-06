--------------------------- MODULE EnabledSubst ---------------------------
(***************************************************************************)
(* Substitute the same variable for both of EnabledInner's variables.      *)
(*                                                                         *)
(* Push the substitution through by hand and you get                       *)
(*                                                                         *)
(*     ENABLED (z' = 0 /\ z' = 1)                                          *)
(*                                                                         *)
(* which is FALSE.  A theorem of EnabledInner would have stopped being a   *)
(* theorem, which is not allowed.  So TLA+ does not push the substitution  *)
(* through: the primed variables under ENABLED are bound, and substitution *)
(* does not reach bound identifiers.  I!F is still TRUE.                   *)
(***************************************************************************)
EXTENDS Integers

VARIABLE z

I == INSTANCE EnabledInner WITH x <- z, y <- z

Init == z = 0
Next == z' = 1 - z
Spec == Init /\ [][Next]_z

\* TRUE if substitution left ENABLED alone, FALSE if it went in.
StillTrue == I!F

\* And here is the same substitution written out by hand, which really is
\* FALSE -- so the two are not the same formula.
ByHand == ENABLED (z' = 0 /\ z' = 1)

Different == StillTrue /\ ~ByHand
===========================================================================
