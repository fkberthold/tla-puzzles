# The summary record

Ten minutes of thinking. Every run is under a second.

## The system

A warehouse with two items in stock, one unit of the first and two of
the second. Customers reserve units one at a time and cancel reservations
one at a time. The requirement: no item is ever reserved past its stock.

The model has the bug you'd guess. The reservation check reads the total
free across both items, not the free count of the item being reserved.
So one item can go over while the other has slack.

## What you built

You pulled the two numbers you care about, units free in total and units
held in total, into one named summary of the state. You'd like three
things from it.

1. TLC checks the requirement, and the error trace prints the summary
   next to the raw state instead of the raw state alone.
2. A colleague says: point TLC's idea of "same state" at the summary.
   Two states with the same totals are the same state, so the run
   shrinks.
3. Another colleague says: the summary is what you care about, so name
   it as the thing TLC checks.

## What happened

| what was done with the summary | verdict | distinct states | depth |
|---|---|---|---|
| nothing, requirement checked directly | violation | 4 | 3 |
| named as the thing to check | error, exit 75 | 1 | 1 |
| named as the thing to print | violation | 4 | 3 |
| named as "same state" | violation | 3 | 3 |

The error says TLC expected a boolean value and didn't find one.

## The questions

1. Four config keywords can take the summary's name. Which one states a
   claim? Which one prints? Which one changes what TLC counts? Which does
   nothing of the kind on its own?
2. Why did the second colleague's run find the bug anyway, and would it
   always? What did the 3 cost?
3. State a claim over the summary that is boolean and legal. Run it on
   the buggy model and explain the verdict.
4. In the 666 published modules this repo surveyed, 176 operators build
   a record from the state. How many of those are wired to each of the
   four keywords? Guess, then look it up.

Write the module and the configs. Reproduce the 75 first, since it's the
one that teaches.
