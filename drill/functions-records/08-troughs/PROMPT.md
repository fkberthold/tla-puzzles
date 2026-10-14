# Troughs

A farm has a row of water troughs, and how many is a parameter of the
model: run it at three, then again at four. Each trough holds up to 2
units. A bowser arrives with 5 units and pours one unit at a time into any
trough with room. Cattle drink one unit at a time from any trough with
water in it, and a unit drunk is gone.

The rule: at every moment, the water still in the bowser, the water in the
troughs and the water drunk add up to the 5 units the bowser brought.

Write the specification and the rule from an empty file, with the number
of troughs as a parameter. The model stops when the bowser is empty and
the troughs are dry, which is intended, so check it with deadlock checking
off. A correct model finds 81 distinct states with three troughs and 168
with four, and reports no error at either.
