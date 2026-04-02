# T01: The Light Switch ⭐

## Setup

A room has a single light switch. The switch is either ON or OFF. A person walks into the room and toggles the switch, then walks out. This happens repeatedly.

## Task

Write a PlusCal spec with:
- A single variable `light` that starts `"off"`
- A single process that toggles the light in a loop (off → on, on → off)
- The process runs 3 times, then stops

## Check

Add these invariants:
1. **TypeOK**: `light` is always either `"on"` or `"off"` (never anything else)
2. **Think about it**: Can you write an invariant that the light is ALWAYS off? What happens when you run TLC?

## Expected Result

- TLC should find **5 distinct states** (initial + 3 toggles + done)
- The "always off" invariant should be **violated** — TLC shows you the first toggle
- The TypeOK invariant should **pass**

## Concept

**Your first spec.** Variables, a process, a while loop, labels, if/else, and your first invariant. This is the "hello world" of TLA+ — but unlike hello world, TLC actually *checks* something.

## Hint

The PlusCal structure looks like:

```
(*--algorithm LightSwitch {
  variables light = "off", count = 0;

  fair process (switcher = "Person") {
    toggle:
      while (count < 3) {
        \* toggle the light here
        \* increment count
      }
  }
}*)
```

Remember: each variable can only be updated once per label.
