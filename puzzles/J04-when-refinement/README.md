# J04: Judgment — When to Use Refinement ⭐⭐

**Judgment puzzle.** No new syntax. The goal: when does a system deserve TWO specs (abstract + concrete + refinement mapping), and when is one spec enough?

## The choice

By Tier 6 you'll have learned how to write an abstract spec and a concrete spec, then prove the concrete one *refines* the abstract one (every behavior of the concrete spec corresponds, under a variable mapping, to a behavior of the abstract spec). It's a powerful technique. It's also a real cost — two specs to maintain, a refinement mapping to keep correct, and TLC checking `Concrete!Spec => Abstract!Spec` which can be expensive.

So when do you reach for it?

- **Side A — single-level spec.** One module describing the system at the level of detail you actually want to check. No `INSTANCE`, no abstract counterpart. The spec says what the system *is*; you check invariants and properties directly.

- **Side B — abstract + concrete + refinement.** An abstract spec defines a *contract* — the visible behavior of the system. A concrete spec implements that contract with extra machinery (buffers, retries, threads, message queues). A refinement mapping shows the concrete spec is a faithful implementation: it does no more than the abstract spec allows.

Both produce checkable specs. The question is whether the second spec earns its keep.

## Side A — single level fits

Open `solution/Flat.tla`. A counter from 0 to `MaxN` with `Inc` and `Reset`.

```bash
cd solution
tlc Flat
```

4 distinct states. Everything we wanted to know — bounded, type-correct, `Inc` and `Reset` interact correctly — lives at one level. Adding an "abstract counter" above this would say nothing new; the spec *is* the abstract counter already. Don't pay for refinement when there's nothing to refine *to*.

## Side B — refinement fits

Open `solution/AbstractQueue.tla`. A queue with `Enq` and `Deq`, modeled as a sequence — at the *contract* level.

```bash
tlc AbstractQueue
```

7 distinct states. This spec says what a FIFO queue *does*: items go in, items come out in order. Nothing about *how*.

Now imagine the real system: a lock-free ring buffer with a head pointer, a tail pointer, padding for cache lines, retry loops on contention. That implementation is what you'd write as the **concrete spec**. It has many more variables, many more interleavings, and many more states. By itself it's hard to read — what does this spec *mean*?

Refinement is the answer:

- Write the **abstract spec** (`AbstractQueue.tla`) — clean, small, easy to understand.
- Write the **concrete spec** — the real implementation, with all its details.
- Provide a **refinement mapping**: an expression `q == fn(headPointer, tailPointer, ringBuffer)` that builds the abstract `q` from concrete state. (You'll learn the mechanics in T53–T59.)
- Have TLC check that `Concrete!Spec => AbstractQueue!Spec` under that mapping.

If the check passes, the concrete implementation is a *refinement* — it does nothing the abstract queue couldn't do. The contract is preserved.

## When to choose single-level (Side A)

- You only have **one level of detail** that matters. The spec is already at the level you want to verify.
- The system is **small enough** that abstract and concrete would be the same spec.
- You're **early in design** and the implementation hasn't been chosen — premature refinement is wasted work, because the concrete spec will keep changing.
- The properties you care about don't need a separate "what does this *mean*" layer. `Bounded == n <= MaxN` is fine without an abstract sibling.

## When to choose refinement (Side B)

- You have a **clear contract** (a small abstract spec a domain expert would recognize) AND a **complicated implementation** (lots of internal state, retries, message ordering, GC, caching).
- You want to argue: "the implementation is *correct relative to the contract*, not just internally consistent." Single-level invariants can prove the implementation doesn't crash; refinement proves it does the *right thing*.
- You're modeling an **algorithm or protocol** with a known specification (Paxos, Raft, MultiPaxos, lock-free queue). The classic literature is full of "Algorithm X refines specification Y" papers — refinement is how you cash that argument as a TLC check.
- You're doing **stepwise refinement**: A1 → A2 → A3, each level adding detail. Useful for very large designs.
- You want to **reuse properties**. Properties proved on the abstract spec automatically hold on the concrete one if refinement holds.
- You're asked to **specify a system you don't implement** (e.g., a database vendor's contract) and want clients of your spec to be able to refine it themselves.

## The trade-off

**Single-level** is cheap. One module, one set of variables, one thing to keep correct. The cost is conceptual: invariants and properties are stated at *implementation* terms, and a year from now a reader might not see what the spec is *for*.

**Refinement** is two (or more) specs to maintain plus a mapping to keep correct as the concrete spec evolves. The win is enormous when it fits: the abstract spec is a *meaning*, and refinement is *evidence* the implementation has that meaning. It separates "this protocol is correct" from "this code doesn't crash."

A useful rule of thumb:

> **If you'd describe the system to a colleague using the same vocabulary you'd use to write its spec, single-level is fine. If you'd describe it as "well, conceptually it's just X, but the implementation has all this machinery for Y reasons" — that gap between conceptually and actually is exactly what refinement formalizes.**

## Mini-classification exercise

For each system, single-level or refinement?

1. A single counter that increments to `MaxN`.
2. A bank that exposes `Transfer(from, to, amount)` but is implemented internally as message-passing between sharded account servers.
3. A 50-line PlusCal spec of a coffee-shop barista; you want to check that orders are served in arrival order.
4. A Raft consensus implementation; you want to argue it implements "an atomic register."
5. A web service whose API has 3 endpoints; the implementation does retries and caching but the API is the contract.
6. A small puzzle for a tutorial.

Rough answers: (1, 3, 6) single-level — there's no contract / implementation gap. (2, 4, 5) refinement — there's a clean external contract worth keeping separate from the messy implementation.

## What to take away

- Refinement is a *technique*, not a default. It earns its place when there's a real gap between contract and implementation.
- Single-level specs are not "less rigorous" — they are *appropriately scoped*.
- The first signal that refinement might help: you find yourself writing internal-implementation-detail invariants when you really wanted to check an external behavior.
- The second signal: someone asks "what does this spec *mean*?" and your honest answer is "well, it's basically just X, but..."

Done. Tier 6 covers the mechanics — `INSTANCE`, `INSTANCE WITH`, refinement mappings, stuttering, auxiliary variables, debugging failed refinements. This judgment is the *strategic* layer above all that: should you reach for those tools at all?
