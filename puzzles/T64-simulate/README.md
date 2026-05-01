# T64: -simulate Mode ⭐

## Lesson: -simulate Trades Exhaustiveness for Reach

Default TLC is **breadth-first model checking**: it explores every reachable state, level by level, and reports any invariant violation it can find. This is sound and complete — if a bug exists, TLC finds it.

For specs with too many states, BFS is the wrong tool. The state space might be billions of states even with tight bounds. You'll wait forever for a result. **`-simulate`** is the alternative: TLC generates random traces, each up to a configured depth. It checks invariants along the way. It will NOT prove correctness — but it will find some bugs quickly, especially shallow ones.

The contract:

- `-simulate num=N -depth D` runs N random traces, each up to D states deep.
- TLC starts from an initial state, picks a random enabled action, applies it, repeats.
- Invariants are checked at every state. If one is violated, TLC stops and prints the trace.
- **Liveness properties are NOT checked** under `-simulate`. Random traces can't witness things like "eventually reaches a state."
- No state space is enumerated. No deduplication. No "X distinct states" — just "X states checked across N traces."

**Worked example — slot machine.**

```
(*--algorithm Slots {
  variables tokens = 100, spins = 0;

  fair process (gambler = "Gambler") {
    play:
      while (tokens > 0 /\ spins < 1000) {
        either { tokens := tokens + 5; spins := spins + 1; }   \* small win
        or     { tokens := tokens - 1; spins := spins + 1; }   \* loss
        or     { tokens := tokens + 100; spins := spins + 1; } \* jackpot
      };
  }
}*)
```

The state space here is enormous: `tokens` can range 0..(100 + 100*1000), `spins` ranges 0..1000. Exhaustive checking would be infeasible.

Run `tlc -simulate num=20 -depth 1500 Slots`. TLC samples 20 random plays. It checks `TypeOK` along each trace. If `tokens` goes negative anywhere on any sampled trace, TLC reports the violation immediately. If none of the 20 traces hits the bug, you don't know whether the bug exists — you only know "20 random samples were clean."

**The right uses of `-simulate`:**

1. **State space is intractable.** You'd wait days for BFS. `-simulate` gives you something useful in seconds.
2. **Smoke testing.** Quickly verify a freshly written spec doesn't error in obvious ways.
3. **Stress testing.** With many simulations, hunt for shallow bugs (off-by-one, wrong initial value).
4. **Coverage extension.** When BFS reaches its scaling wall, simulation can probe deeper random behaviors.

**Wrong uses of `-simulate`:**

1. **Liveness checking.** Random traces don't witness `<>X` properties. Use full TLC.
2. **Exhaustive coverage claims.** "I ran simulate and it passed" is NOT proof of correctness. The bug might be on trace 1,000,001.
3. **Small specs.** If BFS finishes in 30 seconds, just use BFS.

**Combining with `-coverage`:**

```
tlc -simulate num=20 -depth 1500 -coverage 1 MySpec
```

Coverage works under simulate. The action coverage tells you whether your random walk is actually reaching the rare branches. If `coverage` shows `0` for the jackpot action, your simulation never hit a jackpot — you might want more traces, or longer ones, or biased random selection.

## Setup

A pre-written PlusCal spec lives in `solution/RandomWalk.tla`: a 3D random walker takes 200 steps, each step incrementing or decrementing one of `x`, `y`, `z`. The bounds give `x, y, z` each up to 401 distinct values, and `steps` up to 201 — the joint state space is enormous.

## Task

First try exhaustive checking:

```bash
cd solution
tlc RandomWalk    # Press Ctrl-C after a few seconds
```

You'll see TLC generating millions of states per second, working through the search but nowhere near done — billions of states are reachable.

Now switch to simulation:

```bash
tlc -simulate num=10 -depth 250 RandomWalk
```

This finishes in a second. TLC ran 10 random walks, each 250 states deep, checked `TypeOK` and `StaysReachable` at every state, and reports "the number of states generated: ~2500" with "Simulation using seed N." If both invariants hold on every trace, the run completes silently.

Now try a tight loop with coverage:

```bash
tlc -simulate num=10 -depth 250 -coverage 1 RandomWalk
```

The output now ALSO shows action coverage: how often each `either/or` branch was randomly selected. With 6 branches and ~2500 firings, each should fire ~400 times.

## Check

- Exhaustive `tlc RandomWalk`: doesn't terminate in reasonable time. Hit Ctrl-C.
- `tlc -simulate num=10 -depth 250 RandomWalk`: completes immediately, "the number of states generated" is around 2500, no errors.
- With `-coverage 1`: the per-line coverage shows roughly even firing of all six `x/y/z` increment/decrement branches.

## Expected Result

- The contrast between "BFS still running after a minute" and "simulate done in 1 second" is the whole point.
- Both modes check the same invariants. Simulate just doesn't promise to find a bug if one exists.
- Adding `-coverage` under simulate tells you whether your random sampling is hitting all the actions.

## What to take away

- `-simulate num=N -depth D` runs N random traces of up to D states.
- It DOES check invariants. It DOES NOT check liveness, and DOES NOT explore exhaustively.
- Use it when BFS is intractable, for smoke tests, or for finding shallow bugs.
- It is NEVER a substitute for full model checking on small specs.
- Combining `-simulate` with `-coverage` shows whether your random walk is exercising all the actions.
- Every simulate run prints its random seed. Reproduce a flaky run with `-seed N`.
