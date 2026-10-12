# The pumping station

A pumping station has three identical pumps. The operator's handbook gives
the procedure for each one.

> To bring a pump online: open its inlet valve, then start its motor.
> To take a pump offline: stop its motor, then close its inlet valve.
> The station supply can drive at most two motors at once.

Two things must never happen. **A motor must never run against a closed
inlet** (it cavitates). **More than two motors must never run at once.**

All of the following must be possible in your model.

| what has happened | possible? |
|---|---|
| pump 1 is running while pump 2's inlet has just been opened and its motor is still off | yes |
| pump 1 and pump 2 both have their inlet open and their motor off, at the same time | yes |
| the operator opened pump 3's inlet and then closed it again without ever starting the motor | yes |
| the operator stopped pump 1's motor and started it again without touching the inlet | yes |

Write the specification and both rules from an empty file, and run it.
Report the verdict and the number of distinct states.

Then say, in two sentences, what in your model records *where in the
handbook procedure* each pump is, and whether anything about the pump
needed recording beyond the position of its two switches.
