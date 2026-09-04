--------------------------- MODULE ObserveLattice ---------------------------
(***************************************************************************)
(* The Observe-freeze LATTICE in miniature (bead tla-29m4, seedlib step 2  *)
(* variants V38-V45).                                                      *)
(*                                                                         *)
(* Four state variables that all genuinely move, and one observation       *)
(* operator whose four fields are frozen or live INDEPENDENTLY, chosen by  *)
(* four boolean CONSTANTS. One module, one .cfg per lattice row, so the    *)
(* rows differ in nothing but which fields the observation can see.        *)
(*                                                                         *)
(* THE MODEL IS NEVER THE THING THAT BREAKS. season, shelf, owed and       *)
(* standing move on every row, so the state space, the action coverage and *)
(* the satisfiability of Spec are identical across all sixteen subsets.    *)
(* What changes is only how much of that motion Observe passes through --  *)
(* which is the whole shape of the bug: a healthy specification observed   *)
(* through a blinded window.                                               *)
(*                                                                         *)
(* THE ONLY OBLIGATION HERE IS TypeOK, AND IT IS STATED OVER THE RAW       *)
(* VARIABLES ON PURPOSE. In seedlib, single-field and all-four freezes are *)
(* caught by obligations that happen to notice (CloseSquaresTheBook,       *)
(* TheReckoningComes, DefaultIsNeverClean), and the three-field freeze is  *)
(* caught by nothing. That makes the seedlib package a poor instrument for *)
(* asking what the PROBES can see, because an obligation firing masks a    *)
(* probe that saw nothing. Here no obligation reads Observe at all, so     *)
(* every row is exactly as visible as the probe layer makes it -- and the  *)
(* answer comes out uniform instead of accidental.                         *)
(*                                                                         *)
(* Field names are seedlib's for lineage. The values are toggles rather    *)
(* than the real domain: 2^4 = 16 distinct states, four actions, all of    *)
(* which fire, and no fairness -- so probes 1 through 5 all report a       *)
(* perfectly healthy submission on every row.                              *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS FreezeSeason, FreezeShelf, FreezeOwed, FreezeStanding

VARIABLES season, shelf, owed, standing
vars == <<season, shelf, owed, standing>>

Init ==
    /\ season   = 0
    /\ shelf    = 0
    /\ owed     = 0
    /\ standing = 0

BumpSeason   == /\ season'   = 1 - season
                /\ UNCHANGED <<shelf, owed, standing>>
BumpShelf    == /\ shelf'    = 1 - shelf
                /\ UNCHANGED <<season, owed, standing>>
BumpOwed     == /\ owed'     = 1 - owed
                /\ UNCHANGED <<season, shelf, standing>>
BumpStanding == /\ standing' = 1 - standing
                /\ UNCHANGED <<season, shelf, owed>>

Next == BumpSeason \/ BumpShelf \/ BumpOwed \/ BumpStanding

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* The observation. A frozen field reports the initial value forever while *)
(* the variable underneath it keeps moving.                                *)
(***************************************************************************)
Observe ==
    [ season   |-> IF FreezeSeason   THEN 0 ELSE season,
      shelf    |-> IF FreezeShelf    THEN 0 ELSE shelf,
      owed     |-> IF FreezeOwed     THEN 0 ELSE owed,
      standing |-> IF FreezeStanding THEN 0 ELSE standing ]

TypeOK ==
    /\ season   \in 0..1
    /\ shelf    \in 0..1
    /\ owed     \in 0..1
    /\ standing \in 0..1

(***************************************************************************)
(* The probes the differential assertions drive directly, in the idiom     *)
(* harness/refinement.sh:22-25 states for refinement: name the expression, *)
(* assert as an ORDINARY INVARIANT that it never leaves its initial value, *)
(* and require TLC to VIOLATE it. A PASSING PROBE IS A FROZEN EXPRESSION.  *)
(*                                                                         *)
(* WholeObserveProbe is that idiom at the RECORD altitude, which is where  *)
(* it stops working: a record with one live field moves, so the probe is   *)
(* violated and reports "not frozen" however many of the other three are   *)
(* dead. The FieldProbe_* operators are the same idiom one altitude down.  *)
(***************************************************************************)
InitialObserve == [season |-> 0, shelf |-> 0, owed |-> 0, standing |-> 0]

WholeObserveProbe  == Observe = InitialObserve

FieldProbeSeason   == Observe.season   = InitialObserve.season
FieldProbeShelf    == Observe.shelf    = InitialObserve.shelf
FieldProbeOwed     == Observe.owed     = InitialObserve.owed
FieldProbeStanding == Observe.standing = InitialObserve.standing

=============================================================================
