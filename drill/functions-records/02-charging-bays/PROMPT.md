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

The table above is a claim about your model, not a description of the
system. Check every row against it. Say how you checked.

Then say, for each rule, whether your model could have broken it, and why.
