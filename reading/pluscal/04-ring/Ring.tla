---- MODULE Ring ----
EXTENDS Integers

CONSTANT Cap
ASSUME Cap \in 2..12

(* --algorithm ring {
     variables head = 0, tail = 0, count = 0;
     macro bump(i) { i := (i + 1) % Cap }
     { step: while (TRUE) {
         either { await count < Cap; bump(tail); count := count + 1 }
         or { await count > 0; bump(head); count := count - 1 } } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "8f27375b" /\ chksum(tla) = "a402f95")
VARIABLES head, tail, count

vars == << head, tail, count >>

Init == (* Global variables *)
        /\ head = 0
        /\ tail = 0
        /\ count = 0

Next == \/ /\ count < Cap
           /\ tail' = (tail + 1) % Cap
           /\ count' = count + 1
           /\ head' = head
        \/ /\ count > 0
           /\ head' = (head + 1) % Cap
           /\ count' = count - 1
           /\ tail' = tail

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

TypeOK ==
  /\ head \in 0..(Cap - 1)
  /\ tail \in 0..(Cap - 1)
  /\ count \in 0..Cap

Gap == (tail - head + Cap) % Cap = count % Cap

Ambiguous == (head = tail) => (count = 0 \/ count = Cap)

StepsByOne == [][count' \in {count - 1, count + 1}]_vars
====
