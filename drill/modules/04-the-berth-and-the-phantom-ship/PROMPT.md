# The berth and the phantom ship

Ten minutes of thinking. Every run is under a second.

## The system

One berth. Some ships. A ship moors when the berth is empty. It leaves
whenever. The harbour master's rule: a ship that has just left may not
moor again until some other ship has been in. "Empty" has to be a value
of the same variable that otherwise holds a ship, and the ships' names
don't matter.

The requirement: whenever the berth is empty, some ship is allowed to
moor.

Two things about the layout. The dock module must not import anything
TLC-specific. Put whatever the model needs, and only the model, in a
second file that brings the dock in whole.

## What happened

| model | verdict | distinct states |
|---|---|---|
| two ships | clean | 7 |
| one ship | violation | 3 |
| one ship, with "empty" listed as a second ship | refused before the first state, exit 10 | |
| the same, with one line deleted from the dock | clean | 3 |
| three ships | clean | 13 |
| three ships, told they're interchangeable | clean | 4 |

## The questions

1. Write the dock, the second file, and the config for row six. Which
   file does row six's line live in, and why can't it live in the dock?
2. Row three was refused by a line in the dock. Write it. Then delete it
   and run row four. The names in that config are all bare words, none
   of them quoted. Why didn't that protect you?
3. Row two: the requirement failed on a true model of a one-ship
   harbour. What does that say about the requirement?

Write it, reproduce the 7, then make the phantom ship.
