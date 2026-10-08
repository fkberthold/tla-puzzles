--------------------------- MODULE MCReInertProbe ---------------------------
(* The reachability probe behind the VARIANT_INERT verdict on                *)
(* matrix/variants/reinit-skips-rotation. Expect exit 0, which says the      *)
(* mutated branch is unreachable and so the mutation changes no behaviour.   *)
EXTENDS TxnFenceRotates

=============================================================================
