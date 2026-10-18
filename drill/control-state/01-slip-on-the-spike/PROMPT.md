# The slip on the spike

A small warehouse runs its rush orders off a spike by the aisle. This
morning's one rush order is on it.

Two pickers work the aisle. A picker who glances at the spike and sees the
slip there goes to the shelf for the item. When they come back with it they
take the slip off the spike and carry both to packing. A picker who glances
and sees the spike empty does nothing with it.

The rule the warehouse cares about: **a rush order is never picked twice.**

All of the following must be possible in your model.

| what has happened | possible? |
|---|---|
| nobody has looked yet, and the slip is on the spike | yes |
| one picker has seen the slip and is on the way to the shelf, the other has not looked | yes |
| both pickers have seen the slip, and neither has reached the shelf yet | yes |
| the slip is gone, and one picker is at packing with the item | yes |

Nothing else happens once the slip is gone. That is the end of the shift,
not an error.

Write the specification and the rule from an empty file, and run it. Report
the verdict.

The table above is a claim about your model, not a description of the
system. Check every row against it. Say how you checked.

Then: the floor supervisor proposes moving the spike onto the shelf itself,
next to the stock, so that a picker sees the slip and takes it in the same
reach. Change the model to match, run it, and report the verdict again. Say
in one sentence what changed in the model and why that changed the verdict.
