# Box office

A small theatre sells seats at one fare from one window. The window does two
things, and the house wants each written down as a rule of its own, since other
windows reuse them separately:

- Taking a seat. There must be a seat free, and one fewer is free afterwards.
- Recording the fare. The takings go up by one fare.

A booking is both at once, in one step. A refund is the reverse of both at once,
in one step: a seat comes back and one fare leaves the takings. There is nothing
else to do at the window.

Write the specification from an empty file. Say what every variable can be.
State the rule the accountant cares about: the takings always equal the fare
times the number of seats taken.

Check it with 3 seats and a fare of 10. A correct model finds 4 distinct states
and reports no error.
