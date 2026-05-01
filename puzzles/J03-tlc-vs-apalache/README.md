# J03: Judgment — TLC vs Apalache ⭐⭐

**Judgment puzzle.** No new syntax. The goal: when you have a spec ready to check, which model checker do you run — TLC or Apalache — and why?

## The choice

Both tools take a TLA+ spec and look for invariant violations. They take radically different routes.

- **Side A — TLC** (enumerative). For every reachable state, TLC builds the *concrete* state, fingerprints it, and stores it. To explore the next state, TLC enumerates every action and every value the action ranges over. It's a graph search over an explicit state space. CONSTANTS must be concrete values (`MaxN = 4`).

- **Side B — Apalache** (symbolic / SMT-backed). Apalache encodes "is there a behavior of length ≤ k that violates this invariant?" as a constraint problem and asks an SMT solver. It does *not* enumerate states. CONSTANTS can stay symbolic (handled with `--cinit`). Variables need TYPE annotations (`\* @type: Int;`) so the solver knows the SMT theory.

Both are sound for safety. Their costs scale on different things.

## A spec that runs in both

Open `solution/SmallCounter.tla` (or click the 🔒 spoiler below) — a counter from 0 to `MaxN` that increments or resets.

```bash
cd solution
tlc SmallCounter
```

Output: "5 distinct states found." TLC enumerated every value of `n` from 0 to `MaxN=4`.

The same spec, with type annotations active on `MaxN` and `n`, runs under Apalache as:

```bash
apalache-mc check --inv=NeverOverflow --cinit=ConstInit SmallCounter.tla
```

Apalache reports `The outcome is: NoError` — it proved no violation up to its default search depth (10 transitions), by SMT reasoning, **without ever enumerating the concrete states**. The `ConstInit` operator (defined at the bottom of the spec) parameterizes `MaxN` over `1..1000` symbolically; Apalache verifies safety for *every* value in that range at once.

If `apalache-mc` isn't on your `$PATH`, install from https://github.com/apalache-mc/apalache/releases. Either way, the core lesson is the *choice*, not the install — running TLC and reasoning about what Apalache would do is enough to internalize the trade-off.

## The fundamental difference

```
TLC:        for every concrete state s reachable from Init,
              for every action A,
                for every concrete next state s',
                  check Inv(s')
            ↓
            cost grows with the SIZE of the state space.

Apalache:   build SMT constraints "Spec /\ ¬Inv has a path of length ≤ k"
            ask the SMT solver: SAT or UNSAT?
            ↓
            cost grows with FORMULA COMPLEXITY, not state-space size.
```

This is why their winning scenarios are different.

## When to choose TLC

- The state space is **finite and small** (thousands to a few hundred million states).
- You want to see **counterexample traces with concrete values** — TLC prints `n = 3, x = "ready"`, easy to read.
- The spec uses **rich TLA+ idioms**: arbitrary `CHOOSE`, deeply nested record updates, fancy operators. TLC has fewer restrictions on what's expressible.
- You're at the **early authoring stage**: TLC's traces are excellent for learning what the spec does and doesn't do.
- You want **liveness checking** (TLC checks `[]<>`, `<>`, `~>` — Apalache currently does not).
- The CONSTANTS are concrete and small, or can be made small without losing the bug class.

## When to choose Apalache

- The state space is **huge or unbounded** with respect to a constant — `MaxN = 1_000_000` is a problem for TLC, fine for Apalache (SMT reasons abstractly about integers).
- You want to **leave a CONSTANT symbolic** — "for any `MaxN ≥ 1`, this invariant holds" — instead of testing one concrete value.
- You want to check **bounded behaviors of any length** efficiently with SMT (`--length=k`).
- The spec is **safety-only** (no `<>`, `~>`, fairness) — Apalache shines on safety, doesn't yet handle most liveness.
- You're willing to add **type annotations** (`\* @type: Int;`, `\* @type: Set(Str);`, etc.) on every variable, constant, and operator parameter.
- You want **proof-shaped output**: "the invariant holds up to length k" rather than "I checked these N states and found nothing."

## The trade-off

**TLC** is fast to start: write the spec, write the cfg, run. Concrete traces. Liveness. The cost is the state space — if your CONSTANTS make it big, TLC slows or runs out of memory.

**Apalache** scales differently: it shrugs at large bounded integers but stalls on sprawling untyped record updates and on liveness. The cost up front is the type annotations and a more constrained subset of TLA+. The win is that your check is closer to a *proof* than to an *enumeration*.

A useful rule of thumb:

> **Use TLC for everyday safety + liveness checking with concrete bounds. Reach for Apalache when the state space is the bottleneck, when you want to leave a CONSTANT symbolic, or when "I checked all 200M states" isn't a strong enough story.**

The two are complementary, not competitive. A common pattern in industrial use: develop and debug with TLC at small bounds, then run Apalache at larger or symbolic bounds for the final story.

## Mini-classification exercise

For each scenario, decide TLC, Apalache, or "either works":

1. A two-process mutex protocol; you want to check that mutual exclusion holds and that both processes eventually enter the critical section. (Liveness needed.)
2. A counter spec where the bound is `1..1_000_000`; you want to know there's no overflow.
3. A protocol where you want to argue "for any `N ≥ 2` workers, the invariant holds."
4. A small leader-election spec at `N=3`; you're learning the protocol and want to see a concrete bad trace if one exists.
5. A spec with a state space of about 4 million states, all safety properties.
6. A spec with deeply nested records and a fancy `CHOOSE` operator that you haven't yet annotated with types.

Rough answers: (1) TLC — needs liveness. (2) Apalache — TLC won't fit. (3) Apalache — symbolic CONSTANT. (4) TLC — small + traces. (5) Either; TLC if you want the trace, Apalache if you want a faster final pass. (6) TLC — Apalache typing the spec is a project on its own.

## What to take away

- TLC and Apalache solve the same problem with different complexity profiles. Match tool to bottleneck.
- TLC: enumerative, concrete, fast for small spaces, supports liveness.
- Apalache: symbolic/SMT, scales on bound size, requires type annotations, safety-focused (today).
- "I'll use TLC during authoring and Apalache for the final scaling story" is a perfectly normal workflow.

The Apalache tier (A01–A09) teaches the type annotations and the workflow in detail. This judgment is the bird's-eye view: which tool, for which problem, for which reason.

Done. J04 turns to a *structural* judgment: when do you split a spec into abstract and concrete levels and prove refinement?
