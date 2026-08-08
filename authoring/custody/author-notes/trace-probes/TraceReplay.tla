--------------------------- MODULE TraceReplay ---------------------------
(* Author-side probe: replays the hand-shaped satisfying trace through the *)
(* frozen reference's own Init and Next. INVARIANT NotDone MUST FAIL:      *)
(* rc=12 means every step of the trace is a real transition of the spec.   *)
(* rc=0 means some step is NOT legal and the trace must not ship.          *)
EXTENDS MCCustody, Sequences

VARIABLE i

T == <<
  [t |-> 0,  sw |-> {},      pa |-> 0,  pb |-> 0],
  [t |-> 0,  sw |-> {},      pa |-> 0,  pb |-> 6],
  [t |-> 1,  sw |-> {},      pa |-> 0,  pb |-> 6],
  [t |-> 1,  sw |-> {6},     pa |-> 0,  pb |-> 0],
  [t |-> 1,  sw |-> {6},     pa |-> 9,  pb |-> 0],
  [t |-> 1,  sw |-> {6},     pa |-> 0,  pb |-> 0],
  [t |-> 2,  sw |-> {6},     pa |-> 0,  pb |-> 0],
  [t |-> 2,  sw |-> {6},     pa |-> 3,  pb |-> 0],
  [t |-> 3,  sw |-> {6},     pa |-> 0,  pb |-> 0],
  [t |-> 3,  sw |-> {6},     pa |-> 12, pb |-> 0],
  [t |-> 3,  sw |-> {6},     pa |-> 12, pb |-> 12],
  [t |-> 3,  sw |-> {6, 12}, pa |-> 0,  pb |-> 0],
  [t |-> 3,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 4,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 5,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 6,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 7,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 8,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 9,  sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 10, sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 11, sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 12, sw |-> {6, 12}, pa |-> 0,  pb |-> 13],
  [t |-> 13, sw |-> {6, 12}, pa |-> 0,  pb |-> 0],
  [t |-> 14, sw |-> {6, 12}, pa |-> 0,  pb |-> 0]
>>

Match(k) ==
    /\ today = T[k].t
    /\ swapped = T[k].sw
    /\ pending = [p \in Parents |-> IF p = A THEN T[k].pa ELSE T[k].pb]

MatchNext ==
    /\ today' = T[i + 1].t
    /\ swapped' = T[i + 1].sw
    /\ pending' = [p \in Parents |-> IF p = A THEN T[i + 1].pa ELSE T[i + 1].pb]

RInit == Init /\ i = 1 /\ Match(1)

RNext ==
    /\ i < Len(T)
    /\ Next
    /\ i' = i + 1
    /\ MatchNext

RSpec == RInit /\ [][RNext]_<<vars, i>>

NotDone == i < Len(T)

===========================================================================
