# R13: Review — Boundary Values ⭐

## Lesson: Boundary Values for State-Space Reduction

A spec's state space depends on its CONSTANTS. If you set `Buffers = 1..1000`, TLC will explore states with buffer indices 1, 2, …, 1000. Most bugs that show up at index 47 also show up at index 3. **Boundary values** is the discipline of choosing the SMALLEST CONSTANT VALUES that still exercise every code path you care about.

The rule: pick the smallest values that hit each boundary your spec actually distinguishes.

- If your spec has `if (n = 0)` and `if (n > 0)`, two values cover both branches: `0` and `1`. You don't need `1..1000`.
- If your spec has `if (n < Cap)` and `if (n = Cap)`, you need `Cap` reachable from `0`. Setting `Cap = 2` is plenty.
- If your spec has `\E i, j \in 1..N : i # j`, you need at least `N = 2` to make the existential satisfiable. `N = 5` adds nothing.

**Worked example — coffee thermostat.**

```
(*--algorithm Thermostat {
  variables temp = 0;

  define {
    TypeOK == temp \in 0..MaxTemp
    SafeRange == temp <= MaxTemp /\ temp >= 0
  }

  fair process (heater = "Heater") {
    work:
      while (temp < MaxTemp) {
        either { temp := temp + 1; }
        or     { if (temp > 0) { temp := temp - 1; }; };
      }
  }
}*)
```

If you set `MaxTemp = 100` in the cfg, TLC explores ~101 distinct values of `temp` and a depth of ~101. With `MaxTemp = 3`, TLC explores 4 values and depth 4 — and STILL hits every branch of the `either/or` and the `if (temp > 0)`. The bug surface is identical; the runtime is dramatically smaller.

**Heuristic — Lamport's "three values":**

For most counter-like state, three values suffice — `{0, 1, MAX}`, where `MAX` is small (often `2` or `3`). One value to test the `= 0` case, one for `> 0 \land < MAX`, one for `= MAX`. Past that, you're paying for redundant exploration.

This is how production specs stay tractable. Real systems may have a thousand customers; the SPEC just needs three.

## Setup

A pre-written PlusCal spec is shown below as the file `Pantry.tla` (also visible in the 🔒 spoiler at the bottom of this page): a cook adds and removes jars from a pantry up to `MaxJars`. The `.cfg` already uses a small `MaxJars`. Your job is to feel the size difference between a sloppy choice and a tight one.

## Task

Open `solution/Pantry.cfg` (or click the ⚙️ spoiler below). It says `CONSTANT MaxJars = 3`.

1. Run TLC as-is:

   ```bash
   cd solution
   tlc Pantry
   ```

   Note the **distinct states found** and the **depth**.

2. Now bump `MaxJars` to `10`. Re-run. Note the new state count and depth.

3. Bump it to `20`. Re-run. State count grows further.

4. Drop it back to `3`. Same coverage of every branch, far fewer states.

The branches in `Pantry.tla` are: enter loop / exit loop, add jar, remove jar (only when `jars > 0`), do nothing (when `jars = 0` and the remove branch is taken). Three values — `0`, `1`, `2` (≤ `MaxJars = 3`) — exercise every one. The `MaxJars = 20` run gives you 20 numerically-distinct states that all behave the same way as `MaxJars = 3`.

## Check

- With `MaxJars = 3`: TLC reports **5 distinct states**, depth **5**, both invariants pass.
- With `MaxJars = 10`: TLC reports **12 distinct states**, depth **12**.
- With `MaxJars = 20`: TLC reports about **22 distinct states**, depth **22**.

The behavior space at `MaxJars = 3` already covers every meaningful case: jars empty, jars partial, jars full, attempt to remove from empty (the `if` branch). Increasing the bound just creates more numerically-distinct states with the same shape.

## Expected Result

You should see:

- A roughly LINEAR growth in state count with `MaxJars`.
- All values pass the same invariants (TypeOK adapts because it's `0..MaxJars`).
- The bug surface is identical — there's no behavior reachable at `MaxJars = 20` that wasn't reachable at `MaxJars = 3`.

## What to take away

- **Boundary values** is the discipline of choosing the smallest constant that still exercises every distinct branch.
- A spec checked at `Buffers = 3` typically tells you everything a check at `Buffers = 30` would, in 1/100th the time.
- TypeOK that says `n \in 0..N` automatically scales with the boundary — you don't have to update it.
- This is the ONE technique that makes large industrial specs check-able. Use it from day one.

## Hints

??? hint "💡 Hint 1 — Count the Branches"
    Read the spec's guards and conditionals. The lesson mentioned three boundaries to test: `jars = 0`, `0 < jars < MaxJars`, and `jars = MaxJars`. Now trace through what happens at each boundary when the Cook tries to increment or the remove branch (with its `if (jars > 0)`) fires. How many DISTINCT behaviors does each boundary enable? What's the smallest MaxJars that lets all of them happen?

??? hint "💡 Hint 2 — State Space Growth is Linear"
    Don't guess — measure. Set `MaxJars = 3`, `MaxJars = 10`, `MaxJars = 20`, and note the distinct state counts. What's the relationship? Is it exponential, linear, or something else? If it's linear, the smallest bound that exercises every branch is optimal — anything larger is redundant.

??? hint "💡 Hint 3 — TypeOK Automatically Scales"
    TypeOK is defined as `jars \in 0..MaxJars`. You don't update it when you change MaxJars. The invariant still passes because it automatically scales. This is the whole point of boundary values: pick the smallest constant that still exercises every branch, and let the invariant definitions adapt. No manual tuning needed.
