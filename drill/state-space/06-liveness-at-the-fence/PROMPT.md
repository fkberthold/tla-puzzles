# Liveness at the fence

Ten minutes of thinking. One run you'll kill at 30 seconds. The rest are
under a second.

## The system

A sender puts one message on a lossy link. The link either delivers it,
which acknowledges it, or drops it. While the message is unacknowledged
the sender keeps resending. There's an attempt counter, because someone
wanted a number to look at. Nothing in the sender or the link reads it.

Two assumptions about fairness, in prose. The sender doesn't stall: if
it can resend, it eventually does. The link isn't dead: a message that
keeps being resent eventually gets through.

The requirement: the message is eventually acknowledged.

## What happened

| run | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| no cap on the counter | killed | 1,563,059 at 30 s | | 30.2 s |
| counter cut at 3 | clean | 10 | 7 | 0.4 s |
| cut at 3, sender's fairness dropped | violation | 10 | 7 | 0.3 s |
| sender gives up after 3 | violation | 10 | 7 | 0.4 s |

"Cut" means I told TLC not to look past states where the counter is 3.
"Gives up" means I changed the sender so it won't resend a fourth time.

The violation in the third row prints one state, the first one, and
then says the behaviour stays there forever. The one in the fourth row
ends with the counter at 3 and nothing in flight.

## The questions

1. Would you ship the clean verdict in row two? Say what, in the cut
   model, that verdict is resting on. Think about what TLC does with a
   state it isn't allowed to expand, and what the fairness assumptions
   say about that state.
2. Is row three's violation real? Would the uncut model have it?
3. Is row four's real? If it is, what's the honest requirement for a
   sender that gives up, and does it hold?
4. What would you delete, and what does the run look like after?

Write the module and the configs. Reproduce the 10 and the one-state
violation before you delete anything.
