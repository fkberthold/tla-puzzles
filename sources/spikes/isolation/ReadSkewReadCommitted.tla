-------------------------- MODULE ReadSkewReadCommitted --------------------------
(***************************************************************************)
(* A THIRD APPLICATION over the same given isolation scaffolding.          *)
(*                                                                         *)
(* Two accounts holding 10 each. A transfer moves 5 from one to the other,  *)
(* so the pair always sums to 20. A reporting transaction reads one account *)
(* and then the other, and prints the total. The requirement is that a      *)
(* total it prints is a total that was ever true.                           *)
(*                                                                         *)
(* This one is structurally unlike the other two. Its requirement is not a  *)
(* predicate over the committed store, which never breaks: it is a          *)
(* predicate over what a transaction OBSERVED. So the application carries   *)
(* its own history variable, `seen'. The isolation scaffolding did not      *)
(* change by one character to accommodate that.                             *)
(*                                                                         *)
(* The three ReadSkew*.tla files are byte for byte identical apart from the *)
(* module name and the EXTENDS line.                                        *)
(***************************************************************************)
EXTENDS IsoReadCommitted, Sequences

VARIABLES pc, seen

vars == <<pc, seen>> \o IsoVars

Reader == "reader"
Writer == "writer"
AccA   == "a"
AccB   == "b"

InitStore == [k \in Key |-> 10]

Total == 20

TypeOK ==
  /\ IsoTypeOK
  /\ pc \in [Txn -> {"begin", "readA", "readB", "putA", "putB", "finish", "done"}]
  /\ \A t \in Txn : DOMAIN seen[t] \subseteq Key

Init == /\ IsoInit(InitStore)
        /\ pc   = [t \in Txn |-> "begin"]
        /\ seen = [t \in Txn |-> << >>]

DoBegin(t) ==
  /\ pc[t] = "begin"
  /\ Begin(t)
  /\ pc' = [pc EXCEPT ![t] = IF t = Reader THEN "readA" ELSE "putA"]
  /\ UNCHANGED seen

\* The report reads one account, then the other, as two separate statements.
DoRead(t, k, nxt) ==
  /\ Running(t)
  /\ seen' = [seen EXCEPT ![t] = (k :> See(t, k)) @@ seen[t]]
  /\ Idle
  /\ pc' = [pc EXCEPT ![t] = nxt]

DoReadA == pc[Reader] = "readA" /\ DoRead(Reader, AccA, "readB")
DoReadB == pc[Reader] = "readB" /\ DoRead(Reader, AccB, "finish")

\* The transfer moves 5 from a to b, also as two separate statements.
DoPutA ==
  /\ pc[Writer] = "putA"
  /\ Running(Writer)
  /\ Put(Writer, AccA, 5)
  /\ pc' = [pc EXCEPT ![Writer] = "putB"]
  /\ UNCHANGED seen

DoPutB ==
  /\ pc[Writer] = "putB"
  /\ Running(Writer)
  /\ Put(Writer, AccB, 15)
  /\ pc' = [pc EXCEPT ![Writer] = "finish"]
  /\ UNCHANGED seen

DoFinish(t) ==
  /\ pc[t] = "finish"
  /\ Running(t)
  /\ Finish(t)
  /\ pc' = [pc EXCEPT ![t] = "done"]
  /\ UNCHANGED seen

Next == \/ DoReadA
        \/ DoReadB
        \/ DoPutA
        \/ DoPutB
        \/ \E t \in Txn : DoBegin(t) \/ DoFinish(t)

Spec == Init /\ [][Next]_vars

\* A report that read both accounts read a pair that really added up.
ReportIsConsistent ==
  \A t \in Txn :
    (DOMAIN seen[t] = Key) => (seen[t][AccA] + seen[t][AccB] = Total)

==========================================================================
