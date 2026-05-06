# T03b: Roll Call ⭐

## Lesson: Process Sets and `self`

So far you've written specs with ONE process at a time. To spec real concurrency you need MORE than one process — and PlusCal's `\in` form lets you declare a SET of processes that all run the same body.

```
fair process (student \in {"Sam", "Tia"}) {
  ...
}
```

That declares TWO concurrent processes, one per element of the set. Each is identical — they share the same body — but each has its own identity inside that body, accessible via the `self` keyword.

`self` evaluates to the running process's identity: `"Sam"` when Sam is running, `"Tia"` when Tia is running. The usual pattern is to combine `self` with a SET-VALUED variable so you can record which processes have done something:

```
present := present \union {self};
```

That adds the running process's name to the `present` set. After everyone has run, `present` contains every name in the process set.

**Worked example — taking attendance.**

A teacher calls roll. Two students — Sam and Tia — each shout "here" exactly once. The teacher tracks who has answered in the `present` set.

```
(*--algorithm RollCall {
  variables present = {};

  fair process (student \in {"Sam", "Tia"}) {
    answer:
      present := present \union {self};
  }
}*)
```

ONE label per process. ONE step per process. The process set just has multiple processes that take turns. TLC explores every order in which the students answer — there are 2! = 2 orderings — but the FINAL state is always the same: `present = {"Sam", "Tia"}`.

Sample invariants and properties:

- `TypeOK == present \subseteq {"Sam", "Tia"}`
- `EventuallyAllPresent == <>(present = {"Sam", "Tia"})` — a PROPERTY (TLC verifies it holds because each `fair` process must eventually take its `answer` step)

The interleaving here is COMMUTATIVE — every order ends in the same state. That's because each process touches only its own slot (`self`) of a set, and set union doesn't care about order. **T04 will introduce the case where interleaving DOES matter** — when two processes touch the SAME shared state in non-commutative ways. T03b is intentionally single-label so you can focus on the new SYNTAX (the process-set declaration and the `self` keyword) without a race confusing the picture.

**Two pieces, one concept.** Process-set syntax (`\in` instead of `=`) and the `self` keyword can't usefully be taught apart — `self` is meaningful only inside a process-set body, and a process set without `self` would be only marginally useful. Treat them as the SAME concept introduced together.

## Setup

A photographer is taking a group photo of two people: `"Ann"` and `"Ben"`. Each person walks into frame and smiles, exactly once. The photographer wants a record of who has smiled.

There's no race — each person's smile is independent. The point of this puzzle is to declare the two people as a process SET and to use `self` to record who smiled.

## Task

Write a PlusCal spec with:

- A variable `smiled` starting at `{}` (the set of people who have smiled)
- A process SET over `{"Ann", "Ben"}` running in ONE label:
  1. **smile**: `smiled := smiled \union {self}`

Use `fair` so each person is guaranteed to run.

## Check

1. **TypeOK**: `smiled \subseteq {"Ann", "Ben"}`
2. **AllSmiled**: `<>(smiled = {"Ann", "Ben"})` — a PROPERTY (add as PROPERTY in cfg, not INVARIANT)

## Expected Result

- TLC reports `No error has been found`.
- The canonical solution explores **4 distinct states** — initial (`smiled = {}`), two intermediate single-element subsets (`{"Ann"}`, `{"Ben"}`), and one terminal (`smiled = {"Ann", "Ben"}`). 1 + 2 + 1 = 4 states. The state count traces the lattice of subsets the system passes through; the multiplication is the demonstration that TLC explores every interleaving.
- The `AllSmiled` property holds because each `fair` process must eventually take its `smile` step.

## Hints

??? hint "💡 Hint 1 — Process-set syntax: `\in` declares a SET"
    `fair process (NAME \in SET) { ... }` declares ONE process per element of the set. The body runs once per element, but TLC explores every interleaving of the bodies. Use `\in` (not `=`) to indicate a set; `=` is for a single named process and you'll meet that form in T35.

??? hint "💡 Hint 2 — `self` evaluates to the running process's identity"
    Inside the body, `self` is `"Ann"` when Ann's process runs and `"Ben"` when Ben's process runs. To record who smiled, wrap `self` in a singleton set and union it with `smiled`: `smiled := smiled \union {self}`.

??? hint "💡 Hint 3 — One label, no race"
    Each process has just ONE label here — `smile`. There's no race because every interleaving ends with the same `smiled` set. The point is to get the SYNTAX right (`\in`, `self`, `\union`) before T04 introduces the harder case where labels expose a race.
