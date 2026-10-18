# Riggers and the crane

A yard crane lifts loads that riggers attach. Two riggers work the same
crane. A rigger walks up to the load and hooks it on, which they only do
while the hook is down and the crane is still. They step back clear of
the load. Later, once the crane has set the hook down again, they return
for the next load.

The crane operator lifts when at least one rigger has stepped clear of a
hooked load and nobody is still at it, and parks the hook again when the
lift is done.

**The hook never moves while a rigger is at the load.** That is the rule.

All of the following must be possible in your model.

| what has happened | possible? |
|---|---|
| rigger 1 is at the load, hooking on, while rigger 2 has already stepped clear | yes |
| both riggers are at the load at once | yes |
| the crane is lifting while both riggers stand clear | yes |
| rigger 1 is back for the next load while rigger 2 still stands clear from the last | yes |

Write the specification and the rule from an empty file, and run it.
Report the verdict and the number of distinct states.

The table above is a claim about your model, not a description of the
system. Check every row against it. Say how you checked.

Then say how many things in your model record where someone is in their
own procedure, and why that many.
