# Two technicians, two tools

A site has one ladder and one meter, and two technicians who each have one
job to do today. A job needs both tools. The agreed procedure is: take the
ladder, then take the meter, do the job, put both tools back, and you are
done for the day. A technician who reaches for a tool that is not on the
rack waits for it.

**A technician never does the job without both tools in hand.** That is the
rule to check.

The other thing to settle is the end of the day. Once both technicians
have finished, nothing more happens, and that is the intended outcome,
not a fault.

Write the specification and the rule from an empty file, and run it. The
first thing TLC says will be about the end of the day. Deal with it so that
the intended end is accepted, and say which of the ways of dealing with it
you chose and why.

Then: a new hire joins as the second technician and, being left-handed,
takes the meter first and the ladder second. Change only that, and run it
again. Report what TLC says, and whether the way you dealt with the end of
the day had anything to do with what it said.
