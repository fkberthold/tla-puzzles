# T41: Tier 4 Capstone — Bounded Buffer ⭐⭐

## Lesson: Capstone — Tier 4 Toolkit Together

No new concept. This puzzle reaches for everything from Tier 4 in one spec:

- **T35** — distinct asymmetric processes (producers and a consumer with different bodies)
- **T36** — `await` for blocking on conditions
- **T37** — `ENABLED` to talk about when an action can fire
- **T38** — Append/Head/Tail and the producer/consumer pattern
- **T39** — atomic test-and-modify on a shared resource
- **T40** — (optional, not required here) procedures

The Tier 4 capstone scenario: a BOUNDED BUFFER. Multiple producers append to a queue, one consumer takes from the head. The queue has a CAPACITY: producers must wait when the buffer is full. The consumer must wait when it's empty.

The synchronization shape:

- Producer's append step: `await Len(buffer) < CAPACITY; buffer := Append(buffer, item);`
- Consumer's take step: `await buffer /= <<>>; buffer := Tail(buffer); ...`

Each of those `await`s is the standard Tier 4 idiom. Compose them, run TLC, and it tells you if your buffer is consistent.

**Worked recap — a hot-dog stand.**

Two grills (producers) cook hot dogs and place them on a holding tray (the bounded buffer). One window worker (consumer) picks them off and serves customers. Tray capacity: 2.

```
(*--algorithm HotDog {
  variables tray = <<>>, served = 0;

  fair process (grill \in {"G1", "G2"})
  variables made = 0;
  {
    grillLoop:
      while (made < 2) {
        cook:
          await Len(tray) < 2;
          tray := Append(tray, self);
          made := made + 1;
      };
  }

  fair process (window = "Window") {
    serveLoop:
      while (served < 4) {
        serve:
          await tray /= <<>>;
          tray := Tail(tray);
          served := served + 1;
      };
  }
}*)
```

Both grills make 2 hot dogs each (4 total); the window must serve all 4. Invariants you'd check:

- `BoundedTray == Len(tray) <= 2` — capacity respected
- `Conservation == served + Len(tray) <= 4` — no spontaneous hot dogs

Each TLC step is a producer or consumer firing its action; the awaits ensure the buffer never overflows or underflows. That's the whole pattern.

## Setup

A small tea shop has two brewers and one server. Each brewer brews 2 cups of tea, placing each cup on a shared counter. The counter holds at most 3 cups (the bounded buffer's capacity). The server takes one cup at a time from the counter and delivers it to a customer. The shop closes after 4 cups are served (2 brewers × 2 cups).

We want to verify that:

- The counter never holds more than 3 cups.
- The server never tries to serve from an empty counter.
- The server eventually serves all 4 cups (liveness).
- And — using `ENABLED` — the producer's "place a cup" action is enabled exactly when the counter is below capacity.

## Task

Write a PlusCal spec with:

- `EXTENDS Sequences, Integers, TLC`
- Variables `counter = <<>>, served = 0`
- A constant `CAPACITY == 3` (define it in the module, before the algorithm block)
- A process set `brewer \in {"B1", "B2"}` with a per-process local `brewed = 0`. Each brewer loops while `brewed < 2`. In the loop body, atomically `await Len(counter) < CAPACITY; counter := Append(counter, self); brewed := brewed + 1;`.
- A `server = "Server"` process that loops while `served < 4`. In the loop body, atomically `await counter /= <<>>; counter := Tail(counter); served := served + 1;`.

## Check

1. **TypeOK**: `counter \in Seq({"B1","B2"}) /\ served \in 0..4`
2. **BoundedCounter**: `Len(counter) <= CAPACITY`
3. **Conservation**: `served + Len(counter) <= 4`
4. **PlaceEnabledIffRoom**: For each brewer, `ENABLED <its place action>` should match `Len(counter) < CAPACITY` AND that brewer hasn't yet brewed 2. (Stated for each brewer separately — see the hint.)

Optional liveness:

5. **EventuallyServedAll**: `<>(served = 4)`

## Expected Result

- All four invariants PASS.
- Liveness `EventuallyServedAll` PASSES under default weak fairness.
- TLC explores roughly 100–200 distinct states.

## Hint

Brewer body, expanded:

```
fair process (brewer \in {"B1", "B2"})
variables brewed = 0;
{
  brewLoop:
    while (brewed < 2) {
      place:
        await Len(counter) < CAPACITY;
        counter := Append(counter, self);
        brewed := brewed + 1;
    };
}
```

For the `ENABLED` invariant, you'll want to refer to the translated action name. After running `pcal`, the brewer's `place` step becomes an action `place(self)` whose enabling condition is `pc[self] = "place" /\ Len(counter) < CAPACITY`. So:

```
PlaceEnabledIffRoom ==
  \A b \in {"B1", "B2"} :
    pc[b] = "place" =>
      ((ENABLED place(b)) <=> (Len(counter) < CAPACITY))
```

If you want to keep the invariant simpler and skip the `ENABLED` clause, that's fine — TypeOK + BoundedCounter + Conservation already form a complete safety story for the buffer.

This is the canonical bounded-buffer spec. Real systems run on this pattern: thread pools, message queues, audio buffers, log shippers. The spec captures the essential synchronization in a few labels.
