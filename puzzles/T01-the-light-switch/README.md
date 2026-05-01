# T01: The Light Switch ⭐

## Lesson: Your First Spec

A TLA+ spec declares VARIABLES that hold state, defines a PROCESS whose LABELED steps modify those variables, and checks INVARIANTS — properties that must hold in every reachable state. TLC explores every reachable state exhaustively and reports any state where an invariant fails.

**Worked example — a coffee shop counter.**

A barista serves cups until reaching 20, then closes the shop. Each cup is served during a "calm" or "busy" period depending on how many have gone out.

```
(*--algorithm CoffeeShop {
  variables cups = 0, status = "calm";

  fair process (barista = "Barista") {
    serve:
      while (cups < 20) {
        if (cups >= 15) {
          status := "busy";
        } else {
          status := "calm";
        };
        cups := cups + 1;
      };
    close:
      status := "closed";
  }
}*)
```

This demonstrates the whole T01 toolkit:

- `variables cups = 0, status = "calm"` — initial state of every variable
- `fair process (barista = "Barista")` — one worker doing work (`fair` means weak fairness: the process eventually takes a step if it can)
- `serve:` and `close:` — labels marking atomic steps; everything between two labels happens as ONE indivisible action
- `while (...) { ... }` — loop the process runs until a condition fails
- `if (...) { ... } else { ... }` — conditional state change
- `cups := cups + 1` — variable update (`:=`, not `=`)
- **One-assignment rule:** each variable may be assigned AT MOST ONCE per label. That's why `status := "closed"` needs its own `close:` label — `serve:` already assigns `status` (via the if/else inside the loop), and you can't assign the same variable twice in one label.

Sample invariants you'd check on this spec:

- `TypeOK == cups \in 0..20 /\ status \in {"calm", "busy", "closed"}`
- `ClosedOnlyAtLimit == status = "closed" => cups = 20`

TLC explores every reachable state, verifies both invariants, and (because this spec is deterministic) finds 21 distinct states — one per value of `cups`.

## Setup

A room has a single light switch. The switch is either ON or OFF. A person walks into the room and toggles the switch, then walks out. This happens 3 times.

## Task

Write a PlusCal spec with:

- A variable `light` that starts `"off"`
- A counter `count` that starts at 0
- A single process that toggles the light in a loop (off → on, on → off)
- The process runs 3 times, then stops

## Check

Add these invariants:

1. **TypeOK**: `light \in {"on", "off"} /\ count \in 0..3`
2. **Think about it**: Can you write an invariant that claims the light is ALWAYS off? What happens when you run TLC?

## Expected Result

- TLC should report `No error has been found`
- The "always off" invariant should be **violated** — TLC shows you the first toggle
- TypeOK should **pass**
- The canonical solution reports **5 distinct states** (1 initial + 3 toggles + 1 done); your spec may produce more if you split the toggle into multiple labels — that's fine, the behavior is what matters

## Hints

??? hint "💡 Hint 1 — How many toggles?"
    The spec runs 3 times. Start OFF. Each time you toggle, the state flips. How many distinct states should exist: initial OFF, then 3 toggles? Count them on your fingers.

??? hint "💡 Hint 2 — The 'always off' invariant"
    If you write an invariant claiming `light = "off"` always, TLC will find it false at the first toggle. That's not a bug in TLC — it means your spec ALLOWS the light to turn on. Invariants catch where reality differs from the claim.

??? hint "💡 Hint 3 — Split your assignments across labels"
    If you increment `count` AND toggle `light` in the same label, that's fine — two different variables. But you may still need to split them if the loop structure requires observing intermediate states. Try: `toggle:` (flip the light), then `increment:` (add to count), then loop back to `toggle`.
