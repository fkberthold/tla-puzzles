----------------------------- MODULE ParseBad -----------------------------
(***************************************************************************)
(* A PARSE PROBE, kept because the failure it isolates cost a run and does  *)
(* not read as a syntax error at the site.                                  *)
(*                                                                         *)
(* An implied action whose antecedent begins `identifier \in Set` does not  *)
(* parse. SANY commits to a function-constructor or record reading at the   *)
(* opening bracket and reports the error much later, at the `]_`, naming a  *)
(* token 47 columns from the cause.                                        *)
(*                                                                         *)
(* This module is DELIBERATELY BROKEN and nothing EXTENDS it. SANY parses   *)
(* the named module and its EXTENDS closure only, so it is inert in this    *)
(* directory. ParseGood.tla is the form that works.                        *)
(***************************************************************************)
VARIABLE s
CONSTANTS A, B

Bad == [][s \in {A, B} => s' = s]_s
=============================================================================
