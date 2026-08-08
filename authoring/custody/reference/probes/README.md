# Must-fail witness probes

Three §5.3 probes. Each one is an invariant the reference has to **violate**, so
`SAFETY_VIOLATION` rc=12 is the pass and `OK` rc=0 is the failure. They witness
behavior no obligation in `MCCustody.cfg` can require, because every obligation
there is safety and safety cannot refute a spec that does less.

| Probe | What it witnesses | Pass |
|---|---|---|
| `CapReachable` | N days carry an agreed swap at once | rc=12 |
| `FlipAwayFromA` | a day scheduled to A ends up with B | rc=12 |
| `FlipAwayFromB` | a day scheduled to B ends up with A | rc=12 |

Two probes for the flip and not one. A spec that sends every swapped day to A
still moves the B days, so `FlipAwayFromB` fires on it and `FlipAwayFromA` does
not. The direction is what carries the witness, one per parent.

Each probe compares against `Sched`, the pinned schedule the `.cfg` supplies, so
a spec that rewrites its own `Scheduled` operator cannot move the yardstick.

Run one from the reference directory, with the probe as the root module:

```bash
harness/verdict.sh -t 300 -c probes/CapReachable.cfg probes/CapReachable.tla
```

TLC resolves `MCCustody` off the working directory, so the cwd has to be the
directory holding the spec under test. Point the same command at a copy of a
learner's or a variant's tree to probe that tree instead.
