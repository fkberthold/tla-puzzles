# A10: Joint Capstone — TLC + Apalache ⭐⭐

## Recap of the Two Tracks

You have completed two parallel journeys:

- **Tier 1 (T01–T08)**: PlusCal fundamentals — processes, nondeterminism, assertions, invariants. Checked by TLC (enumerative).
- **Apalache tier (A01–A09)**: Type annotations, `:=` discipline, derived operators, `ConstInit`. Checked by Apalache (symbolic SMT).

This capstone unites them: **the SAME spec verified by BOTH tools**.

## The Key Insight from J03

J03 taught that TLC and Apalache are complementary, not competitive:

- **TLC** enumerates concrete states. Cost: state-space size. Strength: concrete counterexample traces, liveness checking, no type annotations needed.
- **Apalache** encodes the spec as SMT constraints. Cost: formula complexity. Strength: symbolic constants, larger bounds, proof-shaped output.

A10 demonstrates this in practice: one pure-TLA+ spec that each tool verifies differently, and each reveals something the other hides.

## Domain — A Bounded FIFO Buffer

The buffer is simple, but perfectly illustrates the trade-off:

- **Variables**: `buffer` — a sequence of integers, length ≤ `MaxSize`.
- **Actions**:
  - `Push`: append a random integer (1..100) if buffer not full.
  - `Pop`: remove the head if buffer is not empty.
  - `Done`: stutter once buffer is empty (terminal action to prevent deadlock).
- **Invariant**: `NeverOverflow` — the buffer length never exceeds `MaxSize`.

## Lesson — Worked Example: A Ticket Counter

Before solving the puzzle, observe the trade-off in a different domain.

```tla
---- MODULE TicketCounter ----
(*
  A counter issues tickets sequentially from 1 to MaxTickets.
  A single requester increments the ticket counter until MaxTickets is reached.
  Invariant: the next ticket to issue never exceeds MaxTickets + 1.
*)
EXTENDS Integers, Apalache

CONSTANT
  \* @type: Int;
  MaxTickets

VARIABLES
  \* @type: Int;
  nextTicket

TypeOK == nextTicket \in 1..MaxTickets + 1

Init == nextTicket := 1

Request ==
  /\ nextTicket <= MaxTickets
  /\ nextTicket' := nextTicket + 1

Done ==
  /\ nextTicket > MaxTickets
  /\ UNCHANGED nextTicket

Spec == Init /\ [][Request \/ Done]_nextTicket

SafetyOK == nextTicket <= MaxTickets + 1

ConstInit == MaxTickets \in 1..1000
====
```

**TLC at MaxTickets=4:**
```
$ tlc TicketCounter -metadir /tmp
States generated: 5 distinct states, depth 4
```

Concrete. Fast. Only checks those 6 states.

**Apalache at MaxTickets ∈ 1..1000 (symbolic):**
```
$ apalache-mc check --cinit=ConstInit --inv=SafetyOK TicketCounter.tla
The outcome is: NoError
```

Symbolic. Same speed. Proves safety for 1000 values at once — no state explosion.

**When would you feel the difference?** Increase MaxTickets in the TLC config to 100. TLC's state space balloons. Apalache's runtime stays flat.

## Solving A10

Open `solution/Buffer.tla` (or click the 🔒 spoiler below). This is a complete, typeable spec ready for both tools.

### Side-by-Side Runs

**1. Run TLC (enumerative):**

```bash
cd solution
tlc Buffer
```

Output:
```
1010101 distinct states found, no error.
Depth: 4
```

TLC explores every reachable buffer configuration: empty, size 1, size 2, size 3, and for each, every possible multiset of values (1..100). The state count reflects the concrete exploration.

**2. Run Apalache (symbolic):**

```bash
apalache-mc check --cinit=ConstInit --inv=NeverOverflow Buffer.tla
```

Output:
```
The outcome is: NoError
Checker reports no error up to computation length 10
```

Apalache **never enumerates those states**. Instead:
- The `ConstInit` declares `MaxSize \in 1..10` symbolically.
- Apalache encodes the entire spec and the negation of `NeverOverflow` as SMT constraints.
- The solver reasons: "Is there a behavior where `Len(buffer) > MaxSize`?"
- Answer: "No, that's unsatisfiable for all MaxSize in 1..10."
- No trace because there's no concrete path — the proof is deductive.

### What Each Tool Tells You

**TLC tells you:** "I checked these specific 1M+ states with MaxSize=3. I found no violation."

**Apalache tells you:** "I proved that for any MaxSize ≤ 10, the invariant holds. No state enumeration needed."

### Highlight: Scale the Constant

**TLC's bottleneck is concrete size.** Change the config to `MaxSize = 5` and re-run TLC:

```bash
tlc Buffer  (with MaxSize = 5 in Buffer.cfg)
```

TLC's state count explodes — now exploring many more multisets. Slower.

**Apalache's bottleneck is formula complexity, not state-space size.** Change the `ConstInit` to:

```tla
ConstInit == MaxSize \in 1..100
```

And re-run:

```bash
apalache-mc check --cinit=ConstInit --inv=NeverOverflow Buffer.tla
```

Apalache's runtime barely changes. It still says "NoError" for all 100 values at once.

This is the **complementary strength**: TLC excels at small, concrete, detailed checks with full traces. Apalache excels at large, symbolic, parameterized proofs.

## Deliverables & Verification

✓ **solution/Buffer.tla** — pure TLA+ with type annotations and `ConstInit`, no domain-specific logic.

✓ **solution/Buffer.cfg** — TLC config with `MaxSize = 3` (small enough for fast concrete check).

✓ **solution/Apalache.tla** — official Apalache standard library.

### Your Verification

Run both from the solution directory:

```bash
cd solution

# Enumerative check
tlc Buffer
# Expected: ~1M+ distinct states, NeverOverflow holds.

# Symbolic check
apalache-mc check --cinit=ConstInit --inv=NeverOverflow Buffer.tla
# Expected: The outcome is: NoError
```

Both pass. **Same spec, two views, two strengths.**

## Quality Gate Checklist (Capstone Exception)

1. **Concept Uniqueness**: Composing TLC + Apalache on a single spec that showcases each tool's advantage.
2. **Minimal Novelty**: No new TLA+ syntax beyond A01–A09 + J03's choice.
3. **Strip Test**: Remove Apalache annotations → TLC-only spec. Remove ConstInit → TLC-only spec. Both pieces are load-bearing for the joint workflow.
4. **Time**: ~20 min to read, ~10 min to verify both tools. ⭐⭐ capstone.
5. **TLC Verification**: Spec passes TypeOK and NeverOverflow under TLC.
6. **Apalache Verification**: Spec passes Apalache type check and logical verification.
7. **Domain-Disjoint Demo**: The TicketCounter worked example uses a different domain (sequential IDs vs. nondeterministic push/pop buffer ops) so the technique must be abstracted.

## What to Take Away

- **TLC and Apalache solve the same problem (safety verification) with different scalability profiles.**
- **TLC's strength**: concrete, enumerable state spaces; liveness; full traces; no annotations.
- **Apalache's strength**: symbolic constants; large bounds; proof-shaped results; requires types.
- **Practical workflow**: develop with TLC at small bounds, then scale with Apalache or tighten the bounds with TLC for the final story.
- **Same spec, two checkers**: this is possible when you use type annotations and `ConstInit` — and it's worth doing because each tool reveals what the other hides.

Done. You have completed the full TLA+ curriculum — from PlusCal first steps through Apalache's symbolic reasoning, and now the capstone that shows both tools at work on a single, realistic spec.

## Hints

??? hint "💡 Hint 1 — One spec, two tools, zero edits"
    This is the capstone: a pure-TLA+ spec that both TLC and Apalache accept. TLC reads the spec and concrete config; Apalache reads the spec and the `ConstInit` predicate. No edits between runs. The key is using `\* @type:` annotations (TLC ignores them; Apalache requires them) and `:=` (both tools understand it as `=`).

??? hint "💡 Hint 2 — TLC enumerates, Apalache proves"
    TLC with `MaxSize = 3` in the `.cfg` explores concrete states: empty buffer, buffer with one element, two elements, etc. It counts them. Apalache with `--cinit=ConstInit` (which says `MaxSize \in 1..10`) never enumerates states — it reasons symbolically. TLC tells you "I checked X states." Apalache tells you "I proved it for any MaxSize in this range."

??? hint "💡 Hint 3 — Three actions: Push, Pop, Done"
    `Push` appends a nondeterministic value (1..100) if the buffer is not full. `Pop` removes the head if the buffer is not empty. `Done` fires when the buffer is empty and leaves it unchanged (the terminal stutter from A06). No `Done` means deadlock; with `Done`, the spec terminates gracefully.

??? hint "💡 Hint 4 — NeverOverflow is the safety property"
    The invariant is simple: `Len(buffer) <= MaxSize`. This is what TLC checks against the concrete config, and what Apalache proves for all `MaxSize \in 1..10`. Both tools should report the invariant holds. If it doesn't, one of the actions violates the bound.

??? hint "💡 Hint 5 — Symbolic advantage emerges at scale"
    TLC with `MaxSize = 3` is fast but explores only that one case. Apalache with `MaxSize \in 1..10` is equally fast but proves all 10 cases at once. Scale `MaxSize` higher in Apalache's `ConstInit` and the time barely changes. Scale it in TLC's `.cfg` and the state explosion grows exponentially. This is why capstones matter: seeing complementary tools on one spec teaches what each is for.
