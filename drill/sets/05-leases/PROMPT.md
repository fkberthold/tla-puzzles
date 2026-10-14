# Leases

A lock service hands out leases on named resources. A client asks for a
resource and gets a lease on it when nobody holds one. A client gives a
lease back whenever it likes. A client may hold leases on several resources
at once.

Rules:

1. A resource is never leased to two clients at once.
2. No client holds more than two leases.

Write the specification from an empty file, with both rules as named checks,
and run it with three clients and three resources. A correct model finds 61
distinct states.

Then take out the check that the resource is free before granting, run it
again, and read what TLC reports.
