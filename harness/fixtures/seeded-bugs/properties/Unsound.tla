------------------------------ MODULE Unsound ------------------------------
(***************************************************************************)
(* A SUBMISSION THAT THE REFERENCE ITSELF VIOLATES.                         *)
(*                                                                          *)
(* "The light is always red" catches every variant with room to spare, so   *)
(* the rc==12 half of the matrix is satisfied on every row.  It is still    *)
(* wrong, because it is violated by the correct spec: the crossing is       *)
(* supposed to let traffic through.                                         *)
(*                                                                          *)
(* This is the negative control for the rc==0-against-the-reference half.   *)
(* Without it, "passes the matrix" would be satisfiable by asserting        *)
(* something false, which is the mirror image of asserting TRUE and just as *)
(* worthless.  Expected: PROPERTY_UNSOUND (41).                             *)
(***************************************************************************)
EXTENDS Crossing

Inv == ns = "red"

=============================================================================
