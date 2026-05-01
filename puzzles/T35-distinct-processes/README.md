# T35: Distinct Processes (Asymmetric) ⭐⭐

## Lesson: Two Processes, Two Different Bodies

So far every multi-process spec you've written used a process SET — a single body run by every member of a set:

```
fair process (person \in {"Alice", "Bob"}) { ... }   \* one body, run by Alice and Bob
```

That's the SYMMETRIC case. Today's lesson is the ASYMMETRIC case: declare TWO `fair process` blocks with DIFFERENT names and DIFFERENT bodies. Each runs as its own concurrent agent. They interleave the same way a process set does, but the work each does is genuinely different.

The syntax difference:

```
fair process (chef = "Chef") { ... }       \* "=" not "\in"; chef is one process
fair process (waiter = "Waiter") { ... }   \* a second process with a totally different body
```

The `=` in `(chef = "Chef")` declares a SINGLE process whose identity is `"Chef"`. PlusCal lets you put as many of these blocks as you want side by side, in addition to (or instead of) process-set blocks.

**Worked example — a mailroom.**

A `Postman` walks routes and delivers letters. A `Sorter` works the back room sorting incoming mail. They share a `pendingPile` integer.

```
(*--algorithm Mailroom {
  variables pendingPile = 0, delivered = 0;

  fair process (postman = "Postman") {
    routeLoop:
      while (delivered < 3) {
        deliver:
          delivered := delivered + 1;
      }
  }

  fair process (sorter = "Sorter") {
    sortLoop:
      while (pendingPile < 5) {
        sort:
          pendingPile := pendingPile + 1;
      }
  }
}*)
```

Two distinct processes. The postman knows nothing about sorting; the sorter knows nothing about delivery. TLC interleaves them: postman might take three steps, then sorter five, or they alternate, or any combination. Both eventually finish.

Note that EVERY label inside an asymmetric process — `routeLoop`, `deliver`, `sortLoop`, `sort` — is still an interleaving point, just like in T04. The processes are different, but the rules are the same.

The pieces:

- `fair process (NAME = "ID") { ... }` declares one named process.
- Each process has its own labels and its own loop, independent of any other.
- Variables can be shared (`pendingPile`, `delivered`) or each process can keep its own state — your call.

## Setup

A small kitchen has one chef and one server. The chef cooks dishes; the server delivers them to tables. They each work independently — there is no coordination yet (that's T36's job). Each does 3 dishes' worth of work and stops.

We expect that the server should never have served more dishes than the chef has cooked. Spoiler: without coordination, this WILL fail.

## Task

Write a PlusCal spec with:

- Variables `cooked = 0, served = 0`
- A process `chef = "Chef"` that loops 3 times, each time incrementing `cooked`
- A SEPARATE process `server = "Server"` that loops 3 times, each time incrementing `served`

## Check

1. **TypeOK**: `cooked \in 0..3 /\ served \in 0..3`
2. **NeverOverServe**: `served <= cooked` — TLC should VIOLATE this

## Expected Result

- TLC explores all interleavings of the chef's three steps and the server's three steps.
- `TypeOK` PASSES.
- TLC should report **`Invariant NeverOverServe is violated`** with a 2-state counterexample (initial state + the violating state where `served = 1` while `cooked = 0`). The total state count varies by label choice (canonical: ~6 states explored) but is not the metric — the violation finding is.

## Hint

The block layout looks like:

```
fair process (chef = "Chef") {
  cookLoop:
    while (cooked < 3) {
      bake:
        cooked := cooked + 1;
    }
}

fair process (server = "Server") {
  serveLoop:
    while (served < 3) {
      deliver:
        served := served + 1;
    }
}
```

This puzzle MOTIVATES the next one (T36): how do you make the server WAIT until there's something cooked? Answer: `await`.

## Hints

??? hint "💡 Hint 1 — What's the syntax difference from process sets?"
    In a process SET, you use `\in`: `fair process (worker \in {"W1", "W2"}) {...}` — one body run by multiple processes. For a distinct process, you use `=`: `fair process (chef = "Chef") {...}` — one identity, one process, one body. To add a SECOND distinct process, just write another `fair process` block with a different name.

??? hint "💡 Hint 2 — Each process runs concurrently, independently"
    The chef loops in the `cookLoop/bake` labels; the server loops in `serveLoop/deliver`. There is NO SHARED COORDINATION — they just interleave. TLC tries every possible order: chef's first step, then server's first step, then chef's second, etc. The invariant `NeverOverServe` will FAIL because the server can take a step before the chef does anything.

??? hint "💡 Hint 3 — Same labeling rules apply"
    Every label (including labels inside loops) is still an interleaving point. So the chef does `cookLoop` (the guard), then `bake` (the action), then back to `cookLoop`. The server does the same, and they can be interleaved at any label. That's why the race is so easy to trigger — no coordination at all.

