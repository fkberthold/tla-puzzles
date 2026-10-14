# The charging bays

A delivery depot has three charging bays and two electric vans. A van
drives into an empty bay. While it is in a bay its charger can be plugged
in and later unplugged. A van drives out of its bay only once the charger
is unplugged. Out on the road, a van is in no bay at all.

Two rules. A charger is never plugged in at a bay with no van in it. A van
is never in two bays at once, and a bay never holds two vans.

All of the following must be possible in your model.

| what has happened | possible? |
|---|---|
| both vans are in bays, one of them plugged in and the other not | yes |
| a van drove in, plugged in, unplugged, and drove out, all at bay 2 | yes |
| van 1 drove out of bay 2 and van 2 then drove into bay 2 | yes |
| both vans sit in bays 1 and 2 while bay 3 has never had a van in it | yes |

Write the specification and both rules from an empty file, and run it with
deadlock checking on. A correct model finds 37 distinct states and reports
no error.

Then say which of the two rules you had to write down as a property, and
which one your choice of state made impossible to break.
