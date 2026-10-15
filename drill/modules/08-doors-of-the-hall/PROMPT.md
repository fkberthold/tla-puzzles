# Doors of the hall

Seven minutes of thinking. Every run is under a second.

## The system

A hall with several doorways, each of a fixed width. A doorway is a
shared module (other specs use it, you can't change it) with one
constant, its width, and one operator: does a thing of a given width get
through. A pallet sits in the hall and gets stacked wider one unit at a
time, from one. It's stacked only if it would still get through every
doorway afterwards. It can be unloaded back to one at any time.

The rule: the hall brings the doorway module in once per width, and the
width is only known when a quantifier over the hall's set of widths
binds it. The hall doesn't restate the doorway's test.

The requirement: the pallet gets through every doorway, always.

## What happened

| model | verdict | distinct states |
|---|---|---|
| doorways of 2 and 3 | clean | 2 |
| doorways of 3 and 4 | clean | 3 |
| the doorway brought in at the top of the hall, width filled from the quantifier's variable | refused: that variable was an unknown operator | |
| stacking without the check | violation | 3 |

## The questions

1. Write the doorway, the hall, and the config for row one.
2. Row three: the obvious place to bring a module in is the top of the
   file. Why can't the width be filled there?
3. Why 2 and 3?

Write it, reproduce the 2, then move the instance to the top and read
the refusal.
