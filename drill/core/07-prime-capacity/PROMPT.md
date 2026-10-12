# Hash table capacity

A hash table keeps a capacity and a load. Items are inserted while there's
room and removed while there are any. The capacity is always a prime number.
It starts at 2. Whenever the table is more than half full it may grow, to a
prime larger than the current capacity and no more than double it. The table
never shrinks, and there's a ceiling on capacity that the model should
respect.

Write the specification from an empty file. Define what a prime is yourself.
Say what every variable can be. State the two rules: the capacity is always
prime, and the load never exceeds the capacity.

Check it with a ceiling of 20. A correct model finds 85 distinct states and no
deadlock.
