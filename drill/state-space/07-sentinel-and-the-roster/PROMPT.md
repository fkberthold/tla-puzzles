# The sentinel and the roster

Ten minutes of thinking. Every run is under a second.

## The system

One ward, one shift at a time. Some nurses. The ward is either staffed
by one nurse or unstaffed. A nurse may start a shift when the ward is
unstaffed and she hasn't already worked a maximum number of shifts in a
row. When she starts, everybody else's run of consecutive shifts resets
to zero. A shift ends whenever.

The requirement: whenever the ward is unstaffed, somebody is allowed to
take the shift.

The nurses' names don't matter. "Unstaffed" has to be written as some
value of the same variable that otherwise holds a nurse. The maximum is
a number, and a maximum of zero is nonsense.

## What happened

| model | verdict | distinct states | depth |
|---|---|---|---|
| two nurses, maximum 2 | clean | 9 | 5 |
| one nurse, maximum 2 | violation | 5 | 5 |
| two nurses, "unstaffed" listed as a third nurse | refused before the first state, exit 10 | | |
| two nurses, maximum 0 | refused before the first state, exit 10 | | |
| three nurses | clean | 13 | 5 |
| three nurses, told they're interchangeable | clean | 5 | 5 |

I also tried spelling the nurses as quoted text instead of bare names.
The two-nurse run still passed at 9 states. Telling TLC the quoted
nurses are interchangeable exited 255.

## The questions

1. Write the config for the first row. Three constants: which is a bare
   name, which is a set of bare names, which is a number? And what's the
   difference between a bare name and quoted text, to TLC?
2. Rows three and four were refused by something in the module, not the
   config. Write it, then take it out and run row three again. Read what
   that run reports and say why it's worse than exit 10.
3. Row two: the requirement failed on a true model of a one-nurse ward.
   What does that say about the requirement, and about where the model's
   size lives?
4. Why did the quoted names work until row six?

Write the module and the configs. Reproduce the 9, then the 5, then
break it.
