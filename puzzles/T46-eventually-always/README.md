# T46: `<>[]` Eventually Always ⭐⭐

## Lesson: `<>[]P` — eventually, P stays true forever

`<>[]P` reads "eventually always P." Unpack: there EXISTS a state from which P is true at every state that follows. After that state, P is permanently true. Equivalently: "P stabilizes."

Compare the four shapes:

| Shape | Meaning |
|-------|---------|
| `<>P`     | At least once, P. (T03, T42) |
| `[]P`     | Always P. (T43) |
| `[]<>P`   | Infinitely often P — recurring forever. (T45) |
| `<>[]P`   | Eventually always P — stabilizes to P. (this puzzle) |

`[]<>` and `<>[]` are easy to swap by accident. The order matters:

- `[]<>P` — every interval contains a P. P keeps recurring.
- `<>[]P` — some interval extends to the end with P. P latches and stays.

`<>[]` is the right shape for stabilization, fixpoints, and "eventually quiescent" guarantees.

**Worked example — a fermenting bottle.**

Yeast lowers a bottle's pH from 7 to about 4 over time, where it stabilizes. The brewer's claim: "eventually pH stays at 4 forever." That's `<>[]( pH = 4 )`.

```
(*--algorithm Bottle {
  variables pH = 7;

  define {
    Stabilizes == <>[](pH = 4)
    TypeOK == pH \in 4..7
  }

  fair process (yeast = "Yeast") {
    ferment:
      while (pH > 4) {
        pH := pH - 1;
      }
  }
}*)
```

The pH steps down 7 → 6 → 5 → 4 and stops. After it reaches 4 the loop guard fails, the process terminates, and pcal's `Terminating` clause keeps `pH = 4` stuttering forever. So `pH = 4` is true from step 4 onward — `<>[](pH = 4)` holds.

Compare:

- `<>(pH = 4)` — pH reaches 4 once. True. (Even if pH then jumped back up.)
- `[](pH = 4)` — pH is always 4. FALSE — the initial value is 7.
- `[]<>(pH = 4)` — pH = 4 infinitely often. True here only because the system halts at 4 (so 4 holds in every state from then on, which is infinitely many).
- `<>[](pH = 4)` — pH eventually stays at 4. True.

The interesting failure mode for `<>[]`: a system that keeps oscillating. Suppose the loop instead of stopping at 4 cycled `pH` between 4 and 5 forever. Then:

- `[]<>(pH = 4)` — passes (4 still recurs).
- `<>[](pH = 4)` — FAILS (no point past which 4 is permanent — 5 keeps coming back).

That's the practical distinction: `[]<>` tolerates flapping; `<>[]` does not.

In the cfg:

```
PROPERTY Stabilizes
```

## Setup

A counter starts at 0 and increments toward a maximum of 3. Each step the counter either bumps up by 1 (if not yet at max) or holds. The system claim: "the counter eventually settles at 3 and stays there."

## Task

Write a PlusCal spec with:

- A variable `n` initially `0`
- A `define` block with:
  - `TypeOK == n \in 0..3`
  - `Settles == <>[](n = 3)`
- A `fair process (counter = "Counter")` that loops forever:
  - `either` if `n < 3`, set `n := n + 1`
  - `or` `skip` (hold)

In `Counter.cfg`: `INVARIANT TypeOK` and `PROPERTY Settles`.

## Check

1. **TypeOK** holds.
2. **Settles** (`<>[](n = 3)`) passes — the counter eventually reaches 3 and stays.

## Expected Result

- TLC should report `No error has been found`. The canonical solution reports 4 distinct states: `n` in `{0, 1, 2, 3}`; your spec may produce more if you split any action into multiple labels — that's fine, the behavior is what matters.
- `Settles` passes. Once `n = 3`, the increment branch is disabled (`n < 3` is false), only `skip` remains, and the counter is permanently at 3. Weak fairness on the loop ensures the increment fires until `n = 3`.
- **Compare with `[]<>`**: `PROPERTY []<>(n = 3)` would also pass on this spec, because once `n = 3` it stays at 3 forever. But the two are not equivalent in general — see the strip test.
- **Strip test**: change the increment guard so `n` can go up AND down — replace the increment branch with `if (n < 3) n := n + 1 else n := 0` (when at max, reset). Rerun. Now the counter cycles 0→1→2→3→0→1→.... With the cycle:
  - `[]<>(n = 3)` still passes (3 recurs every cycle).
  - `<>[](n = 3)` FAILS — there is no point past which `n = 3` permanently. TLC produces a lasso showing the cycle.
- This is the cleanest demonstration of why `[]<>` and `<>[]` are different: stabilization vs. recurrence.

## Hints

??? hint "💡 Hint 1 — Stabilization, not oscillation"
    The task says `n` "settles at 3." What does that mean? Once `n = 3`, does it ever leave that state in your spec? If so, `<>[]` would fail.

??? hint "💡 Hint 2 — The loop guard"
    Your process loops forever with two branches: increment (conditionally) or `skip`. What prevents `n` from dropping back down? Why does the loop never reset `n`?

??? hint "💡 Hint 3 — The property formula"
    `Settles == <>[](n = 3)` reads "eventually, n is always 3." This holds when the loop reaches a state where the increment is disabled and only `skip` remains, so `n` stays at 3 forever.
