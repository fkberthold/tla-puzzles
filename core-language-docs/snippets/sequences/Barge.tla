---- MODULE Barge ----
EXTENDS Integers, Sequences
VARIABLE label

Init == label = "abc"
Next == UNCHANGED label
Spec == Init /\ [][Next]_<<label>>

StringLen == Len(label) = 3
StringTail == Tail(label) = "bc"
StringSub == SubSeq(label, 2, 3) = "bc"
StringConcat == label \o "d" = "abcd"

StringHead == Head(label) = "a"
StringAppend == Append(label, "d") = "abcd"
StringIndex == label[1] = "a"
StringDomain == DOMAIN label = 1..3
======================
