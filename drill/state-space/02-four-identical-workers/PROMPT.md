# Four identical workers

Ten minutes of thinking. Every run here is under a second.

## The system

A pool with two slots. Some number of workers share it, and they're
interchangeable: nothing about any worker differs from any other. A
worker that wants a slot joins a queue. The worker at the head of the
queue takes a slot when one is free. A holder gives its slot back whenever
it likes and goes back to idle.

The requirement: never more than two holders.

## What happened

The requirement holds, and the run is quick at any size I'd bother to
type in.

| workers | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| 2 | clean | 10 | 5 | 0.4 s |
| 3 | clean | 37 | 6 | 0.4 s |
| 4 | clean | 159 | 7 | 0.3 s |
| 5 | clean | 811 | 8 | 0.3 s |
| 6 | clean | 4,888 | 9 | 0.4 s |

The system I'm modelling this for has forty workers.

A colleague's fix was to cap the queue at two waiters. At five workers
that came back clean at 211 states.

## The questions

1. Read the growth off the table. What's multiplying, and why does the
   queue matter more than the slots?
2. There's a knob for this shape, and this system meets its condition
   to the letter. Name it. Two things have to be true, one of the model
   and one of the requirement, before TLC's answer under it can be
   trusted. Name both. Then build a config that breaks each one, so
   you've seen what the failure looks like.
3. The colleague's cap: what did it buy, and what can it no longer see?
4. You also want to check that every waiter is eventually served. Does
   your knob survive that? Run it and read what TLC prints.

Write the module and the configs. Reproduce the 811 before you shrink it.
