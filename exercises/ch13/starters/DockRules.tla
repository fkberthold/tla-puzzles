---- MODULE DockRules ----
\* Exercise 1, the rules file. Ships complete and is not edited.
\*
\* Nothing in here mentions a variable. Every operator takes the state it
\* judges as an argument, which is what lets one rules file serve any spec
\* that can hand it a function from bays to counts.
EXTENDS Integers

\* Private. Two operators below lean on it; nothing outside this file can.
LOCAL Level(bays, b) == bays[b]

NoBayOver(bays, cap) == \A b \in DOMAIN bays : Level(bays, b) <= cap

NoBayNegative(bays) == \A b \in DOMAIN bays : Level(bays, b) >= 0
====
