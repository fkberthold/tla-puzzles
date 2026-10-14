# Covering a sick driver

A bus depot runs three routes, numbered 1 to 3, with four drivers,
numbered 1 to 4. By default driver 1 drives route 1, driver 2 drives route
2, driver 3 drives route 3, and driver 4 is the spare with no route.

The depot keeps a standing list of stand-in arrangements. Each entry names
a route and the driver covering it. The day's roster is the default roster
with the standing list laid over it: where the list names a route, the
list's driver runs it, and everywhere else the default driver does.

When a driver calls in sick, every route that driver is rostered for today
is handed, on the spot, to one driver who is not sick, and each of those
routes goes on the list under that driver. A driver with no routes today
just goes sick. When a driver recovers, the entries for that driver's
default routes are struck off the list and the driver takes them back.

The rule: no route is ever rostered to a sick driver.

| what has happened | possible? |
|---|---|
| driver 1 sick, driver 4 covering route 1 | yes |
| driver 1 sick, then driver 4 sick, and route 1 is now covered by driver 2 | yes |
| driver 2 sick and covering route 1 at the same time | no |
| drivers 1, 2 and 3 all sick, driver 4 running every route | yes |
| all four drivers sick | no |

Write the specification and the rule from an empty file. Check it with
deadlock checking on. A correct model finds 33 distinct states and reports
no error.
