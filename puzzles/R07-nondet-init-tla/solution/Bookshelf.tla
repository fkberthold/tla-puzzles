---- MODULE Bookshelf ----
EXTENDS Integers

VARIABLE books

Init == \E n \in 0..5 : books = n

Borrow ==
  /\ books > 0
  /\ books' = books - 1

Next == Borrow

Spec == Init /\ [][Next]_books

TypeOK == books \in 0..5
NeverNegative == books >= 0
================================
