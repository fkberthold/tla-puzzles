# J07: Judgment — When to Split a Label vs Combine Actions ⭐⭐

**Judgment puzzle.** No new syntax. The goal: every time you write a label boundary in PlusCal, you're making a claim about *atomicity*. When should two operations live in one label, and when should they be split into two?

## The choice

In PlusCal, a label marks an atomic step. **Everything between two labels happens as one indivisible action.** Other processes cannot observe an intermediate state inside a single label.

- **Side A — combine into one label.** Read and write happen together. No other process can sneak in between. Simulates a hardware atomic, a transaction, a held lock.
- **Side B — split across two labels.** The state between the two operations is *visible* to other processes. Other processes can interleave. Simulates a true concurrent memory model where reads and writes are separate events.

The same code with different label boundaries describes *different systems* — and TLC will faithfully report any race the boundaries permit.

## Side A — combined (atomic)

Open `solution/Atomic.tla` (or click the 🔒 spoiler below). Two clients each increment a shared counter:

```
fair process (client \in {"A", "B"}) {
  bump:
    counter := counter + 1;
}
```

`counter := counter + 1` reads-then-writes inside ONE label. Run it:

```bash
cd solution
tlc -pcal Atomic.tla && tlc Atomic
```

TLC reports `No error has been found.` The canonical solution reports 4 distinct states; your label choices may produce more, which is fine as long as the invariant `Correct == (both Done) => counter = 2` holds.

## Side B — split (interleavable)

Open `solution/Split.tla` (or click the 🔒 spoiler below). Same intent — two clients each increment the counter — but now read and write are explicitly separate:

```
fair process (client \in {"A", "B"})
  variables local = 0;
{
  read:
    local := counter;
  write:
    counter := local + 1;
}
```

Run it:

```bash
cd solution
tlc -pcal Split.tla && tlc Split
```

TLC reports **`Invariant Correct is violated`** with a trace showing the classic **lost update bug**:

```
State 1: counter = 0, both at "read"
State 2: A reads → local = [A |-> 0, B |-> 0],  A at "write", B at "read"
State 3: B reads → local = [A |-> 0, B |-> 0],  both at "write"
State 4: A writes → counter = 1,  A Done, B at "write"
State 5: B writes → counter = 1,  both Done   ← LOST UPDATE
```

(TLC shows `local` as a function over the process set: `local = [A |-> 0, B |-> 0]`.)

Both clients read 0, both compute "0+1," both write 1. Net effect: counter increased by 1, not 2. The trace length varies by label choice, but the violation finding is what matters here.

The two specs differ *only* in label structure. The bug exists or doesn't exist depending on where you drew the atomicity boundaries.

## When to choose ONE label (Side A)

- The operation is genuinely atomic in the real system: a hardware compare-and-swap, a transaction, a critical section under a held lock.
- You're modeling a *single-threaded* component where there's no concurrency to worry about.
- The intermediate state is uninteresting and unobservable — no one looks at it, no one cares.
- You want to *abstract over* the implementation. "Increment is atomic" is the contract; the spec doesn't need to model how.
- You're at a higher level of refinement: at the abstract spec, increment is atomic; the concrete spec may split it and prove refinement.

## When to choose MULTIPLE labels (Side B)

- The operations correspond to **separate observable events** in the real system: a read from memory, a network send, a database round-trip. Anything that takes time and is interruptible.
- You want TLC to **find races** between processes — which only happens if other processes can interleave.
- The intermediate state IS observable: other processes read it, write it, decide based on it.
- You're modeling a **concurrent memory model** faithfully. Two threads on a CPU don't have read-modify-write atomicity unless they're using a hardware atomic instruction.
- You're checking whether a *protocol* (a lock, a barrier, a fence) actually achieves the atomicity it's supposed to. You make the underlying ops non-atomic and check that the protocol on top recovers atomicity.

## The trade-off

**One label** gives you small, fast specs. The cost is *abstraction over reality*: you might be hiding the very race you wanted to find. If your code's `counter++` isn't actually atomic in production, a one-label spec will lie to you about safety.

**Multiple labels** is more faithful to reality. The cost is the state space (more interleavings = more states) and the cognitive load (you need a label every time something interesting happens). Over-splitting bloats the spec without finding more bugs — every label adds branches.

A useful rule of thumb:

> **A label boundary is a promise: "no other process is observing this gap." Put a boundary wherever the real system *gives* you that promise (a lock held, a transaction open, a hardware atomic). Don't put one where the real system doesn't.**

Symmetrically:

> **A new label is also an opportunity: "let other processes interleave here." Add one wherever the real system *exposes* a moment another process could act (a network round-trip, an unlocked section, between an unprotected read and write).**

## Common patterns

- **`read; write` as separate labels** — concurrent variable access. Required to find lost updates.
- **`acquire-lock; critical-section; release-lock`** — three labels. The critical section can itself contain MULTIPLE labels (showing it's not all atomic; only mutual exclusion is guaranteed).
- **Atomic compare-and-swap** — one label combining the conditional check and the assignment, because hardware gives you that.
- **`await condition; do-thing`** — one label. The `await` and the action it guards must be atomic together; otherwise the condition can become false between them.
- **Sending a message across a network** — separate labels for `send` and `recv` on different processes. Network delays are exactly the gap.

## Mini-classification exercise

For each scenario, one label or multiple? (Many labels is fine; the exercise is *where* the boundaries go.)

1. A barista takes an order, grinds beans, brews, hands the cup over. Single thread.
2. Two threads each running `balance := balance + amount` against shared memory.
3. A leader writes a log entry then notifies followers. Network in between.
4. A request handler that, holding a lock, reads two fields and writes one.
5. A producer pushing to a bounded buffer; a consumer popping from it.
6. A thread acquiring a mutex.

Rough answers:

1. Probably one label per logically-separate step (take order, grind, brew, hand over) for clarity — but combining or separating doesn't matter for safety since it's single-threaded.
2. **Must split**: `read; write`. Otherwise you can't model the lost update.
3. Two labels minimum: write log, notify. The network gap is real.
4. One label for the locked section is fine *if you're modeling the lock as held*. The lock itself enforces atomicity — that's its job.
5. The push and pop are separate labels (otherwise no producer/consumer interleaving). Within each, append/take from the buffer is a single atomic step.
6. The `await` for free + the act of acquiring should be one label. If they're split, two threads can both pass `await` and then both acquire — racing on the lock you're trying to model.

## What to take away

- Labels are atomicity claims. Each one says "this much, and no more, happens indivisibly."
- One label = "the world freezes here." Multiple labels = "other processes can act between these."
- Drawing boundaries that match the *real* system is half the work of writing concurrent specs. Wrong boundaries hide bugs (too coarse) or invent races that can't happen (too fine).
- A useful diagnostic: if TLC says "no error" on a known-buggy concurrent design, your labels are too coarse. If TLC says "violation" on a design you know is correct (under a held lock, say), your labels are too fine for the model you're trying to express.

This closes the judgment intersticials. Each judgment was a *choice* between TLA+ idioms — records vs scattered, PlusCal vs pure TLA+, TLC vs Apalache, single-level vs refinement, fairness strength, safety vs liveness, label granularity. Building these reflexes is how you go from *writing specs* to *designing specs*.

## Hints

??? hint "💡 Hint 1 — Is this gap observable by other processes?"
    Between the two operations, can another process sneak in and see an intermediate state? Can another process *affect* whether the second operation succeeds? If yes to either, you need separate labels. If no (because a lock is held, or the process is alone), combine.

??? hint "💡 Hint 2 — Look for the real-world gap"
    Does each operation correspond to a separate network round-trip, system call, or hardware instruction in your actual implementation? Then: separate labels. Are both operations guaranteed atomic by hardware (compare-and-swap), or protected by a lock your spec models? Then: one label. The spec should match the *real* concurrency model.

??? hint "💡 Hint 3 — Run both and read the trace"
    Write the spec with one label, run TLC. Then split it. If split version finds a bug (like lost-update) that the combined version misses, the split was necessary — you were hiding a race. If both report "no error," combined was safer and cleaner. Let TLC guide you: trust the trace.
