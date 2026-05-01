# R11: Multi-Process Refresh ⭐

## Lesson: Re-Drilling Distinct Processes + `await`

No new concept. Tier 4 introduced two distinct named processes that synchronize via `await`. The reflexes:

- `process (NameA = "A") { ... }` and `process (NameB = "B") { ... }` declare two SEPARATE processes with different code.
- `await Cond;` halts the current process at that point until `Cond` is true. The other process must then run for `Cond` to become true.
- Without `await`, both processes interleave freely. With `await`, you can force a handshake.

**Worked example — bartender and waiter.**

The bartender mixes a drink, then signals "ready". The waiter waits for the signal, picks up the drink, and resets the signal. Two iterations.

```
(*--algorithm BarPickup {
  variables drinkReady = FALSE, served = 0;

  define {
    NeverDoubleSignal == ~(drinkReady = TRUE /\ served = 2)
  }

  fair process (bartender = "Bartender") {
    mix:
      while (served < 2) {
        await ~drinkReady;
        drinkReady := TRUE;
      }
  }

  fair process (waiter = "Waiter") {
    pickUp:
      while (served < 2) {
        await drinkReady;
        drinkReady := FALSE;
        served := served + 1;
      }
  }
}*)
```

What this shows:

- Two `fair process` blocks with different bodies — the bartender mixes; the waiter picks up.
- `await ~drinkReady` blocks the bartender until the waiter has cleared the previous drink.
- `await drinkReady` blocks the waiter until the bartender has signalled.
- The two `await`s lock-step the processes: M1 → P1 → M2 → P2, never M1 → M2 (because the second `await ~drinkReady` would fail).

TLC explores all interleavings allowed by the awaits — there are very few because the awaits force a strict handshake.

## Setup

A small kitchen has a chef and a server. The chef cooks one dish at a time and places it on the pass-through window. The server waits for a dish, takes it, and walks to the table. The pass-through window holds AT MOST ONE dish at a time. They go through this cycle 3 times.

## Task

Create `solution/Kitchen.tla` with PlusCal:

- `dish` boolean: TRUE when a dish sits on the window
- `delivered` integer counter, starts 0
- A `chef` process that cooks and places (sets `dish := TRUE`) — must wait when the window is full
- A `server` process that takes the dish (sets `dish := FALSE`) and increments `delivered` — must wait when the window is empty
- Both processes loop while `delivered < 3`

Use `await` so the chef cannot place a second dish before the server has taken the first.

## Check

Add invariants:

1. `TypeOK`: `dish \in BOOLEAN /\ delivered \in 0..3`
2. `WindowSafe`: this is implicit in the model (you can't have two dishes on the window) — write it as `TRUE` or omit
3. `OrderedDelivery`: `delivered <= 3`

Add a property:

4. `EventuallyDone`: `<>(delivered = 3)` — relies on `fair process` for both processes

## Expected Result

- TLC should report `No error has been found` with `EventuallyDone` PASSING.
- All invariants pass. The canonical solution reports 9–11 distinct states (the exact count depends on where you place labels between operations); your spec may produce more if you add extra labels — that's fine, the behavior is what matters.
- If you remove the `await ~dish` from the chef's loop, you'll see TLC report a state where the chef wrote `TRUE` over an existing `TRUE` — the second cook would silently overwrite. (Optional exploration.)

## Hints

??? hint "💡 Hint 1 — Which puzzle taught distinct processes?"
    T35 introduced two separate process blocks with different code running concurrently. This puzzle drills that again: chef and server are distinct processes, each with its own loops and awaits.

??? hint "💡 Hint 2 — await blocks until the condition becomes true"
    The chef awaits ~dish (window must be empty); the server awaits dish (window must be full). These awaits create a handshake: the chef cannot cook again until the server has cleared the window. Think: what sequencing do the awaits FORCE?

??? hint "💡 Hint 3 — fair process + liveness property"
    Both processes are fair, and EventuallyDone = <>(delivered = 3) requires that the loop eventually terminates. If you remove fair, the processes might both idle forever even when enabled — TLC would find a counterexample.

