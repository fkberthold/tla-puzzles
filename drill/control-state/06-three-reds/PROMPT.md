# Three reds

Field procedure for a controller that has stopped responding. Cut the
power. Wait thirty seconds. Power it up. Watch the status light.

- **Green**: it is fixed. Done.
- **Amber**: still booting. Keep watching.
- **Red**: it has failed to come up. Go back and cut the power again.

On the third red, the technician does not cut the power again. They
escalate instead, and from then on they leave the controller alone.

So the procedure ends in one of two ways, fixed or escalated, and nothing
happens after either. Both are intended ends.

Three rules.

- **Never a fourth power cycle.**
- **Escalation happens on exactly the third red.** Not before, not after.
- **Once escalated, hands off.** The technician never touches it again.

All of the following must be possible in your model.

| what happened | possible? |
|---|---|
| green on the first boot, fixed after one power cycle | yes |
| red, red, green, fixed after three power cycles | yes |
| red, red, red, escalated, and nothing happens after | yes |
| red, then a long amber, then green, fixed after two power cycles | yes |

Write the specification and the three rules from an empty file, and run
it. Report the verdict and the number of distinct states.

The table above is a claim about your model, not a description of the
system. Check every row against it. Say how you checked.

Then say in two sentences what in your model records which step of the
procedure the technician is on, and whether the count of reds could have
stood in for it.
