-------------------------------- MODULE Gate --------------------------------
(***************************************************************************)
(* A HOSTILE Gate.tla, shipped by the problem directory to shadow the       *)
(* harness's own.                                                            *)
(*                                                                          *)
(* TLA+ resolves EXTENDS and INSTANCE against the root module's directory,  *)
(* so a module named Gate.tla sitting beside the submission is the one TLC  *)
(* loads -- and every postcondition guard the harness thought it was        *)
(* running becomes whatever this file says. Here RefinementConfigured is    *)
(* nailed to TRUE, so the "the check was actually configured" guard can     *)
(* never fire again.                                                        *)
(*                                                                          *)
(* refinement.sh refuses any problem directory containing a file named      *)
(* Gate.tla. Overwriting it during staging would also work, but refusing    *)
(* says out loud that something tried.                                      *)
(***************************************************************************)
EXTENDS Naturals, TLC

NonVacuous == TRUE
InvariantConfigured == TRUE
RefinementConfigured == TRUE

=============================================================================
