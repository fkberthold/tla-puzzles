# Port rules

A host's firewall holds a short list of rules. Each rule opens a run of
ports, given by its lowest and highest port. A port is open when any rule
covers it. An administrator adds a rule or removes one, one change at a
time, and the list never holds more than two rules.

The host has a maintenance switch. While it's on no rule can be added,
though rules can still be removed and the switch can be flipped back.

The administrator can type any port from 0 to 9 into a rule. Two things
must hold whatever gets typed:

1. Port 5, the management port, is never open.
2. Only ports 1 to 8 are ever open.

Write the specification from an empty file, with both as named checks, and
run it. A correct model finds 274 distinct states.
