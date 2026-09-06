------------------------- MODULE LostUpdateReadCommitted -------------------------
(***************************************************************************)
(* A SECOND APPLICATION over the same given isolation scaffolding.          *)
(*                                                                         *)
(* A counter, and two clients that each want to add one to it. A client     *)
(* opens a transaction, reads the counter, adds one in its own head, and    *)
(* writes the result back. The requirement is that the counter ends up      *)
(* holding the number of transactions that committed.                      *)
(*                                                                         *)
(* Not one line of the isolation scaffolding changed to run this. The       *)
(* three LostUpdate*.tla files are byte for byte identical apart from the   *)
(* module name and the EXTENDS line, as the three OnCall*.tla files are.    *)
(*                                                                          *)
(***************************************************************************)
EXTENDS IsoReadCommitted, Sequences

VARIABLE pc

vars == <<pc>> \o IsoVars

Counter == "counter"

InitStore == [k \in Key |-> 0]

Succeeded == {t \in Txn : state[t] = "committed"}

TypeOK == /\ IsoTypeOK
          /\ pc \in [Txn -> {"begin", "write", "finish", "done"}]

Init == /\ IsoInit(InitStore)
        /\ pc = [t \in Txn |-> "begin"]

DoBegin(t) ==
  /\ pc[t] = "begin"
  /\ Begin(t)
  /\ pc' = [pc EXCEPT ![t] = "write"]

\* Read, add one, write back. The addition happens in the client, not in
\* the database, which is what makes this the lost-update shape rather
\* than an atomic increment.
DoWrite(t) ==
  /\ pc[t] = "write"
  /\ Running(t)
  /\ Put(t, Counter, See(t, Counter) + 1)
  /\ pc' = [pc EXCEPT ![t] = "finish"]

DoFinish(t) ==
  /\ pc[t] = "finish"
  /\ Running(t)
  /\ Finish(t)
  /\ pc' = [pc EXCEPT ![t] = "done"]

Next == \E t \in Txn : DoBegin(t) \/ DoWrite(t) \/ DoFinish(t)

Spec == Init /\ [][Next]_vars

\* Every increment that committed is in the counter, and nothing else is.
NoLostUpdate == store[Counter] = Cardinality(Succeeded)

==========================================================================
