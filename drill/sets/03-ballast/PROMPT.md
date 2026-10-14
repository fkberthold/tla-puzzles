# Ballast

A small ship has six ballast tanks, three down the port side and three down
the starboard side. A tank is full or empty. The crew fills or pumps out
one tank at a time.

The rule: the ship must never list. The full tanks on one side never
outnumber the full tanks on the other side by more than one.

When the voyage begins the tanks are however the last crew left them, which
can be any arrangement that obeys the rule.

Write the specification from an empty file, with the rule as a named check,
and run it with six tanks. A correct model finds 50 distinct states.

Then take the rule out of the starting condition, leave it everywhere else,
and read what TLC reports.
