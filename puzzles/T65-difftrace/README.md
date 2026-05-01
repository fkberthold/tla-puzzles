# T65: -difftrace and Debugging Workflow ⭐

## Lesson: -difftrace Shows You What Changed

When TLC finds a violation, it prints a counterexample — a sequence of states from the initial state to the bad one. By default, every state shows EVERY variable. For a spec with 3 variables, this is fine. For a spec with 30 variables, it's a wall of values where 28 are unchanged at every step. The signal is buried in noise.

`-difftrace` is the fix. With this flag, TLC prints each state showing only the variables that **changed since the previous state**. The initial state and the violating state are printed in full — those are the anchors. Everything in between is a diff.

**Worked example — restaurant orders.**

```
(*--algorithm Restaurant {
  variables
    burgers = 5, fries = 5, drinks = 5, salads = 5, pizzas = 5,
    desserts = 5, soups = 5, served = 0;

  fair process (chef = "Chef") {
    cook:
      while (served < 6) {
        either { burgers := burgers - 1; }
        or     { fries := fries - 1; };
        served := served + 1;
      };
  }
}*)
```

The spec has 8 variables. Each step changes only 2 (the chosen item and `served`). All other 6 are identical step to step.

Without `-difftrace`, the trace looks like this:

```
State 1: burgers = 5, fries = 5, drinks = 5, salads = 5, pizzas = 5, desserts = 5, soups = 5, served = 0
State 2: burgers = 4, fries = 5, drinks = 5, salads = 5, pizzas = 5, desserts = 5, soups = 5, served = 1
State 3: burgers = 4, fries = 4, drinks = 5, salads = 5, pizzas = 5, desserts = 5, soups = 5, served = 2
...
```

Eight values per state. Most of them obviously not changing. To find what each step did, you have to scan and compare.

With `-difftrace`:

```
State 1 (full): burgers = 5, fries = 5, drinks = 5, salads = 5, pizzas = 5, desserts = 5, soups = 5, served = 0
State 2: burgers = 4, served = 1
State 3: fries = 4, served = 2
...
```

Now each state's diff IS the action it took. State 2 cooked a burger. State 3 cooked fries. The trace reads like a story.

**The debugging workflow:**

1. Run TLC with `-difftrace`. It finds a violation.
2. Verify the bug is real by reading the diff trace — the initial and final states are printed in full; intermediate states show only what changed.
3. Patch the spec to fix the bug. Re-run. Repeat.

`-difftrace` doesn't change WHAT TLC does — only how it presents the trace. The same number of states; the same exploration; the same outcome. Just a more readable diff.

**Combining with other flags.**

- `-difftrace` works alongside `-coverage` and `-simulate`. They're orthogonal flags.
- For very wide states (records with many fields), `-difftrace` even works on subfields — only the changed fields are shown.

**Liveness debugging.** When TLC reports a liveness violation (a `<>X` property failing), it prints a "lasso" — a finite prefix plus a cycle that loops forever without reaching X. Lasso traces tend to be longer than safety counterexamples; `-difftrace` is even more useful there. You can SEE the cycle as a sequence of small diffs.

## Setup

A pre-written PlusCal spec lives in `solution/Inventory.tla`: a seller picks one of four fruits to sell on each step, decrementing its stock and incrementing `sold`. There are also four other fruits (`elderberries`, `figs`, `grapes`, `honeydew`) that are NEVER touched — they're padding to demonstrate `-difftrace`.

The spec has a deliberate bug: invariant `NotPastFive` claims `sold <= 5`, but the loop runs while `sold < 8`, so `sold` can reach 7. Also the chosen fruit can go negative (TypeOK violation), which TLC will hit first.

## Task

Run TLC normally:

```bash
cd solution
tlc Inventory
```

Look at the counterexample trace. You'll see `TypeOK` violated — one of the fruits went negative. The trace prints all 10 variables (9 fruits + 1 sold) at every state. Most of them never change. The signal — which fruit is decreasing — is buried in noise.

Now run with `-difftrace`:

```bash
tlc -difftrace Inventory
```

The trace now shows the initial state in full, then EACH STEP shows only the variables that changed. The violation state at the end is also shown in full.

## Check

- Both runs report the same violation (TypeOK).
- The default trace is verbose: each state prints all 10 variables.
- The `-difftrace` trace is sharp: intermediate states show only `apples` (or whatever fruit was sold) and `sold`. The cause of the violation jumps out: the seller picked `apples` over and over until `apples` went negative.

## Expected Result

- TLC finds a violation. Trace length is 7 states.
- Default output: ~70 lines of variables.
- With `-difftrace`: each intermediate state is 2-3 lines (the variables that changed). Reading speed roughly 4× faster.

## What to take away

- **`-difftrace`** is a CLI flag — no spec change required.
- It prints initial and final states in full, intermediate states as diffs.
- For wide specs (many variables, many fields), it's the difference between a readable trace and a wall of unchanged values.
- It's especially valuable for liveness counterexamples (lasso traces tend to be long).
- Use it routinely when debugging — there's no downside.

## Hints

??? hint "💡 Hint 1 — The Signal-to-Noise Problem"
    Inventory has 10 variables (9 fruits + sold). Most of them don't change at each step — only the chosen fruit and sold increment. Without `-difftrace`, every state prints all 10 values, and you scan and compare to find the differences. With `-difftrace`, TLC shows you only what CHANGED at each step, making the trace 4-5× shorter and the causality obvious. The violation becomes: "sold climbed to 8 (violating NotPastFive)" and "apples went negative (violating TypeOK)." The bug jumps out.

??? hint "💡 Hint 2 — Full States at the Anchors"
    `-difftrace` prints the initial state IN FULL (all 10 variables) and the final (violating) state IN FULL (all 10 variables). Everything in between is a diff. This is intentional: you can always recompute the state of ANY variable at ANY step by starting from the initial state and applying the diffs in sequence. The full anchors at the start and end let you verify your understanding and check edge cases.

??? hint "💡 Hint 3 — It's a No-Cost Upgrade"
    `-difftrace` is a CLI flag. It doesn't change the spec, doesn't change what TLC does, doesn't slow it down. It ONLY changes the presentation of the trace. Once you find a violation and print it with `-difftrace`, the trace is far more readable. Make it a habit: if your spec has many variables, always add `-difftrace` to your debugging run.
