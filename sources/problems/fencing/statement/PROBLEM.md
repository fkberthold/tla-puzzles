# Lease expiry and stale writes

A lock service hands out a lease on one shared resource. A client asks the
lock service for the lease, does its work, and then writes the result to a
storage service. The storage service holds the data. It's a separate
component. It has no connection to the lock service and never asks it
anything.

A lease doesn't last. Some time after it's granted it expires, and the lock
service is then free to grant it to whoever asks next. The client that held
it isn't told.

Holding the lease is what entitles a client to write. Nothing in the system
enforces that.

## The first version

1. There is one lease and more than one client. Any client can ask for the
   lease at any time.
2. The lock service grants the lease only when no client holds it. An expired
   lease isn't held.
3. A granted lease expires without anything else having to happen first.
4. A client isn't told that its lease has expired, and has no way to find out.
5. A client writes to the storage service after it has been granted the lease.
   It can write at any point after the grant, including after the lease has
   expired.
6. The storage service accepts every write. It can't tell which client holds
   the lease, or whether any client does.

## The second version

The same system, with numbers added.

7. Every grant carries a number.
8. Each number the lock service issues is higher than every number it has
   issued before.
9. A client writes with the number that came with its grant.
10. The storage service rejects a write whose number is lower than the number
    on a write it has already accepted. It accepts any other write.
11. The storage service still knows nothing about leases, and still can't tell
    the clients apart.

## What to produce

Treat these as one problem in two states, before the numbers and after.

1. A model of the first version, and the properties you think establish that
   it behaves.
2. A model of the second version.
3. An account of what the numbers change. Check each property you wrote
   against both versions and say where it holds.

