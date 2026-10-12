# The database you didn't need

Ten minutes of thinking. The longest run you'll do is about seven
seconds, and you'll want to stop before the next size up.

## The system

A rostering service. Every doctor is on call or off call, and the roster
starts with everyone on. A doctor who wants to go off call opens a
transaction, counts how many are on call, and takes herself off only if
at least two are. The database runs snapshot isolation.

The requirement: at least one doctor is always on call.

This is write skew. Two doctors each see two on call, each take
themselves off, and both commit because they wrote different rows. The
requirement is false under snapshot isolation and the model should say
so.

## What you built

You modelled the database. Each row has a chain of versions, each
stamped with the commit time it became visible. There's a global
timestamp counter that moves on every begin and every commit. A
transaction records the counter when it begins, and reads the newest
version of each row stamped at or before that. At commit it scans the
chain of every row it wrote for a version stamped after its start. One
of those is a conflict. Six variables.

## What happened

| doctors | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| 2 | violation | 29 | 7 | 0.4 s |
| 3 | violation | 462 | 10 | 0.4 s |
| 4 | violation | 13,683 | 13 | 0.7 s |
| 5 | violation | 637,658 | 16 | 7.1 s |

Yours is a cut-down version of a published full-fidelity model of the
same isolation level. That one reports a read-only anomaly at
405,673,796 distinct states, depth 13, in 64 minutes.

So you cut the timestamp counter. Three doctors, counter never past 4:
clean, 280 distinct states, depth 8.

A colleague's model of the same roster finds the same violation at 21
states with two doctors, 173 with three, 2,421 with four, 50,885 with
five, all under 1.2 seconds. It has no database in it.

## The questions

1. The cut at 4 came back clean on three doctors. Is the roster safe
   under snapshot isolation at that size? Work out where the violation
   sits in terms of the counter, then say what the cut did to it.
2. List what the requirement reads. List what your six variables hold.
   Cross off everything in the second list the first list never
   mentions.
3. State snapshot isolation as two rules a transaction obeys, in prose,
   without mentioning versions or timestamps. Then write the rules as a
   module and the roster as an application against it, and reproduce
   the 21.
4. Divide the two curves at each size. Where is the ratio going, and
   what is the 405 million telling you about the published model?

Write the mechanism model too, if you can do it in the time. Reproduce
the 29 before the 21, so you've paid for the lesson.
