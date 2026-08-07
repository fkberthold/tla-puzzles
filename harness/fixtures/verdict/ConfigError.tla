------------------------- MODULE ConfigError -------------------------
(***************************************************************************)
(* rc=151 fixture.  The MODULE is deliberately fine -- the defect lives     *)
(* entirely in ConfigError.cfg, which names an INVARIANT that the spec does *)
(* not define.  Keeping the module valid is what separates the config       *)
(* channel from the parse channel that ParseError.tla covers.               *)
(*                                                                          *)
(* Measured 2026-08-06 on the TLC 2026.03.04.183147 nightly and re-measured *)
(* unchanged on tla2tools v1.8.0 (TLC 2026.07.31.184830): rc=151 is the     *)
(* *semantic* config failure -- the .cfg parses but refers to something     *)
(* that is not there. A .cfg that fails to PARSE is a different code        *)
(* entirely (255, see BadCfgSyntax.cfg), and a .cfg keyword with a missing  *)
(* operand is no error at all (rc=0, see DanglingKeyword.cfg).              *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = (x + 1) % 5
Spec == Init /\ [][Next]_x

=============================================================================
