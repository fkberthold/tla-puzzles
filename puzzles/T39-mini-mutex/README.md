# T39: Mini-Mutex (Two-Process) ⭐⭐

## Lesson: Atomic Test-and-Set with `await`

A MUTEX (mutual exclusion lock) lets at most one process hold a "critical section" at a time. The naive design is: check a flag, then set it. T04 already showed why that fails — splitting check and set across two labels lets a second process see the flag-as-false in between.

The fix is to put `await flag = FALSE; flag := TRUE;` IN THE SAME LABEL. The whole sequence is one atomic step. While `flag = TRUE`, the action is disabled; when it fires, both the check and the set happen together, and no other process can sneak in.

This is the spec-level analog of a hardware test-and-set instruction.

**Worked example — a bathroom key.**

Two roommates each want the bathroom. They share a key, modeled as a flag `keyTaken`. To enter, a roommate must wait for the key, then take it. To leave, they put it back.

```
(*--algorithm Bathroom {
  variables keyTaken = FALSE, occupants = {};

  fair process (roommate \in {"Alex", "Sam"}) {
    enter:
      await ~keyTaken;
      keyTaken := TRUE;
      occupants := occupants \union {self};
    leave:
      occupants := occupants \ {self};
      keyTaken := FALSE;
  }
}*)
```

The critical line is `enter:` — `await ~keyTaken; keyTaken := TRUE;` is ONE label, ONE atomic step. While `keyTaken` is true, no roommate can fire `enter`. As soon as someone fires it, `keyTaken` becomes true and locks out the other.

Mutex invariant: `Cardinality(occupants) <= 1`. TLC verifies it across all interleavings.

**What if you split it?** If you wrote:

```
enter:
  await ~keyTaken;
check_done:
  keyTaken := TRUE;
  occupants := occupants \union {self};
```

Now there's a label boundary BETWEEN the check and the set. Both roommates can pass `await ~keyTaken` (each in their own atomic step) before either sets `keyTaken`. Both then enter the bathroom. TLC finds it in 5 states. The fix and the bug differ by one label.

**The pattern in one line: atomic test-and-set is `await ~flag; flag := TRUE` in a single label.**

## Setup

A small office shares one printer. Two users (Alice and Bob) each want to send a document to the printer. We want at most one to be "printing" at a time.

Model a `printerInUse` boolean flag. Each user, when they want to print, must atomically wait for the printer to be free, claim it, do the work, and release it.

We want to verify that the set of currently printing users never has size 2.

## Task

Write a PlusCal spec with:

- Variables `printerInUse = FALSE`, `printing = {}` (the set of users currently printing)
- A process set `user \in {"Alice", "Bob"}` that, in sequence:
  1. **acquire**: atomically `await ~printerInUse; printerInUse := TRUE; printing := printing \union {self};`
  2. **release**: `printing := printing \ {self}; printerInUse := FALSE;`

Both users run once each, then stop.

## Check

1. **TypeOK**: `printerInUse \in BOOLEAN /\ printing \subseteq {"Alice", "Bob"}`
2. **MutualExclusion**: `Cardinality(printing) <= 1`
3. **FlagMatchesSet**: `printerInUse <=> (printing /= {})`

## Expected Result

- All three invariants PASS — the atomic acquire is correct.
- TLC explores around 7 distinct states.
- A trace that violates `MutualExclusion` does NOT exist. (If you broke the lock by splitting the acquire across two labels, TLC would find a violating trace in under 6 states.)

## Hint

Make sure your `acquire` label contains BOTH the await and the assignments. If you sneak `keyTaken := TRUE` into a separate label, you've reintroduced the T04 bug. The atomicity of the test-and-set is the whole point.

```
fair process (user \in {"Alice", "Bob"}) {
  acquire:
    await ~printerInUse;
    printerInUse := TRUE;
    printing := printing \union {self};
  release:
    printing := printing \ {self};
    printerInUse := FALSE;
}
```

## Hints

??? hint "💡 Hint 1 — Why does T04's naive split fail here?"
    In T04, if you split a test-and-set into two labels, both processes see the flag as false and both "lock" it. Here, `await ~printerInUse; printerInUse := TRUE;` in the same label means the entire sequence is ATOMIC. While the flag is true, both processes are disabled. Once one fires, the flag flips and the other is locked out.

??? hint "💡 Hint 2 — The await must be in the same label as the set"
    The invariant `MutualExclusion` will FAIL if you put the `await ~printerInUse` check in one label and the `printerInUse := TRUE` in another. The atomicity is essential. That's the entire lesson of T39: atomic test-and-set as a pattern, not a bug.

??? hint "💡 Hint 3 — Track both the flag and the process set"
    You have two state variables: `printerInUse` (the boolean flag) and `printing` (the set of users currently using the printer). The acquire label updates both; the release label clears both. The invariant `FlagMatchesSet` says these two should always agree: the flag is true IFF at least one user is in the set. That's your synchronization check.

