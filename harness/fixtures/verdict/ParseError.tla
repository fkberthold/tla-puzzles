------------------------- MODULE ParseError -------------------------
(***************************************************************************)
(* rc=150 fixture.  Deliberately unparseable: the Next definition trails    *)
(* off after an infix operator and the following line is not an expression. *)
(* Do NOT "fix" this file -- being broken is its entire job.                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = x +
     == /\ \/

Spec == Init /\ [][Next]_x

=============================================================================
