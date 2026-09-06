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

## Author notes

Not for the learner.

**Where I was tempted to name state, and what I wrote instead.**

- The brief's own sentence "a lease lasts a fixed time" was the strongest pull
  toward a clock. Rule 3 says a lease expires "without anything else having to
  happen first", which says expiry is spontaneous and says nothing about how
  time is carried [brief, trap 1: "Describe leases expiring. Do not describe
  ticks."].
- For rule 10 I first had the storage service "remember the highest number it
  has accepted". That names a variable. The rule as written is a condition on
  which writes it rejects [rule 10].
- For rule 2 I first had the lock service track a current holder. The rule as
  written is a condition on when it grants [rule 2].
- I dropped written values entirely. An early draft had a write carry a value
  so that staleness could be described as one value overwriting another, which
  hands over a data structure and a name for it. A write is now accepted or
  rejected and carries nothing else [rules 6 and 10]. I think the problem
  loses nothing, because everything asked about is which writes land
  (INFERRED).
- No rule mentions a record, a function, or a set. Nothing here needs `EXCEPT`
  or `@`, since the only accumulating quantity in the second version is one
  number (INFERRED).

**The three traps.**

1. *Time.* Handled at rule 3, above. Nothing in the statement says a lease
   lasts a fixed anything, and no rule mentions duration, order of events in
   time, or a thing that advances.
2. *The pause.* Rules 4 and 5 carry it between them. Rule 4 says the client
   isn't told, rule 5 says it can write at any point after the grant including
   after expiry. Neither says the client pauses, stalls, or is delayed
   [rules 4 and 5, and brief trap 2].
3. *The fencing rule as answer.* Rules 7 to 11 state what the lock service
   issues and what the storage service checks, flat. No sentence says the
   numbers fix anything, and the ask at the end says "what the numbers change"
   rather than what they repair [rules 7 to 11, "What to produce" item 3].

**What I deliberately didn't write.** No sentence asserts that the storage
service only accepts writes from a current lease holder, or that two clients
never both write. The closest the statement comes is "holding the lease is
what entitles a client to write. Nothing in the system enforces that", which
states the intent and immediately says it isn't guaranteed. I think that's the
line to hold. The learner needs to know what the lease is for, or the problem
has no stakes, but the statement must not promise the property (INFERRED).

**Rules I'm unsure about.**

- Rule 3 is the one I'd re-examine first. "Without anything else having to
  happen first" is meant to rule out expiry being caused by a second client
  asking. It could be read as a constraint on how expiry is represented, which
  is the leak class this brief is about (INFERRED).
- Rule 1's "more than one client" fixes a fact about the system that a learner
  might otherwise have chosen. I think it's a system fact rather than a model
  decision, since the failure needs two clients to exist at all, but it's the
  second thing I'd challenge (INFERRED).
- The rules run longer than the 15-word bullet cap in Frank's writing rules. I
  kept them long, because a spec list carries items that must each be exact
  and none of them carry reasoning (INFERRED).
- The statement itself has no first-person hedges, against the usual voice
  check. A problem statement addressed to a learner reads wrong with an author
  in it, so the hedging lives here instead (INFERRED).

**Provenance of this pass.** I didn't look for the existing model. This
session made no file search and read no project file. The only tool calls
before the first write attempt were the `frank-writing` skill load and one
`mkdir -p` for the output directory.
