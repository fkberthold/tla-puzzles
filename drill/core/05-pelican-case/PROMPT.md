# Pelican crossing

A pelican crossing runs on a button. The lights go round a fixed cycle:

| phase | vehicles see | walkers see | holds for |
|---|---|---|---|
| go | green | red | at least 4 s |
| slow | amber | red | 3 s |
| walk | red | green | 6 s |
| clear | red | flashing green | 2 s |

A clock counts down in whole seconds. When it reaches zero the lights move to
the next phase and the clock is set for that phase. The exception is "go":
green stays on past its 4 seconds until someone has pressed the button. A press
is remembered, whenever it's made, until the next "walk" begins. Pressing while
a press is already remembered does nothing. After "clear" the cycle returns to
"go" with a fresh 4 seconds. At switch-on the lights show "go" with the minimum
already served and no press remembered.

Write the specification from an empty file. Say what every variable can be.
State two rules: the clock never shows more than the current phase holds for,
and amber is only ever shown because someone pressed the button.

Check it. A correct model finds 34 distinct states.
