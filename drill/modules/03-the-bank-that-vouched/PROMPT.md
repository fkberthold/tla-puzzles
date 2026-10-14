# The bank that vouched

Ten minutes of thinking. Every run is under a second.

## The system

A locker bank. It has some number of lockers, and all anyone tracks is
how many are in use. A parcel goes in when a locker is free. A parcel
comes out when any locker is in use. A bank with no lockers is nonsense,
and the bank module says so, in the one way a module can refuse a value
before the first state.

The bank is a library. A post office uses it. The office owns a shutter
it opens and closes, and it owns the two numbers the bank's size comes
from: the lockers it has, and the lockers it keeps back for staff. The
bank gets the difference. The office doesn't rewrite the bank. It brings
the bank in, tells it what its size is and which variable of the office
holds the count, and gets on with the shutter.

The requirement: the count never exceeds the bank's size.

## What happened

| model | verdict | distinct states |
|---|---|---|
| the bank alone, 3 lockers | clean | 4 |
| the bank alone, 0 lockers | refused before the first state, exit 10 | |
| the office, 4 lockers with 1 kept back | clean | 8 |
| the office, 2 lockers with 2 kept back | clean | 2 |
| the office rewritten to take the size as a plain number of its own, given 0 | clean | 2 |

## The questions

1. Write the bank, the office, and the config for row three.
2. Rows two and four handed the bank the same size. One was refused and
   one was clean. What did the bank's refusal depend on that the office
   took away, and which of the two ways of bringing a module in would
   have kept it?
3. Row five is there to rule something out. What?
4. Write the one line in the office that makes row four refuse, and say
   what it has to be about.

Write it, reproduce the 8, then reproduce the 2 and make it refuse.
