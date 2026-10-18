# The donor session

A mobile blood-donation session. Three donors turn up together. There is
one nurse and there are two donation chairs.

A donor's visit goes like this. They arrive and wait. The nurse calls them
over to the desk for screening, and the nurse screens one donor at a time.
Screening either clears the donor or defers them. A deferred donor leaves.
A cleared donor takes a chair when one is free, donates, moves to the rest
area, and then leaves.

The session is over when everyone has left. That is the intended end.

Two rules.

- **The nurse never has two donors at the desk.**
- **Nobody donates standing up.** Never more donors donating than there
  are chairs.

All of the following must be possible in your model.

| what has happened | possible? |
|---|---|
| donor 1 is resting, donor 2 is donating, and donor 3 is at the desk | yes |
| both chairs are taken and a cleared donor is waiting for one | yes |
| a donor is deferred and leaves without ever sitting | yes |
| everyone has left | yes |

Write the specification and the two rules from an empty file, and run it.
Report the verdict and the number of distinct states.

The table above is a claim about your model, not a description of the
system. Check every row against it. Say how you checked.

Then count the actions in your model whose only job is to move one donor
from one step of the visit to the next. If you found yourself writing the
same two lines in each of them, say what you did about it.
