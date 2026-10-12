# Twin altimeters

An aircraft carries two altimeters. Each reading drifts up or down by one unit
at a time, within a fixed span either side of zero. The two readings are in
agreement when they differ by no more than a tolerance. A fault lamp is lit
exactly when the readings are not in agreement, and it reacts in the same
instant a reading changes. While the lamp is lit the crew may resync: the
second altimeter is set to the first, and the lamp goes out.

Write the specification from an empty file. Define "in agreement" as something
you can write between two readings, the way you'd write a comparison. Say what
every variable can be. State the rule: the lamp is lit if and only if the
readings disagree.

Check it with a tolerance of 1 and a span of 3. A correct model finds 49
distinct states.
