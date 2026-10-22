---- MODULE Trim ----
EXTENDS Integers, Sequences
VARIABLE tape

Full == <<10, 20, 30>>

Init == tape = Full
Next == UNCHANGED tape
Spec == Init /\ [][Next]_<<tape>>

Middle == SubSeq(tape, 2, 3) = <<20, 30>>
OneElement == SubSeq(tape, 2, 2) = <<20>>
Backwards == SubSeq(tape, 3, 1) = <<>>
BackwardsReindexed == DOMAIN SubSeq(tape, 2, 3) = 1..2
PastTheEnd == SubSeq(tape, 1, 5) = Full
BeforeTheStart == SubSeq(tape, 0, 2) = <<10, 20>>
=====================
