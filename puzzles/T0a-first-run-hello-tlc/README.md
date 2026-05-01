# T0a: First Run — Hello, TLC ⭐

**Tier 0 prelude.** No new concept. No code to write. The only goal is to run the toolchain end-to-end and recognize what success looks like.

## What this puzzle is

A tiny pre-written spec models a clock that ticks from 0 to 3. You will translate it, model-check it, and read TLC's output. You are NOT expected to understand the spec yet — Tier 1 covers PlusCal, Tier 0 is purely about the workflow.

## The spec

Save the following two files into a working directory of your choice (call it whatever you like — the repo provides them under `puzzles/T0a-first-run-hello-tlc/solution/` if you have a local clone, but a fresh `~/tla-attempts/T0a/` works just as well):

`Tick.tla`:

```
---- MODULE Tick ----
EXTENDS Integers

(*--algorithm Tick {
  variables count = 0;

  define {
    TypeOK == count \in 0..3
  }

  fair process (clock = "Clock") {
    tick:
      while (count < 3) {
        count := count + 1;
      }
  }
}
*)
====
```

`Tick.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
```

The filename **must** match the module name on line 1 (`MODULE Tick` ↔ `Tick.tla`). The `====` on the last line closes the module. T0e covers the structure in detail; for now, just copy the text exactly.

## Run it

From the directory containing both files:

```bash
tlc -pcal Tick.tla     # PlusCal → TLA+ translation
tlc Tick               # model-check
```

The first command rewrites `Tick.tla` in place, adding a `\* BEGIN TRANSLATION ... \* END TRANSLATION` block. That's the actual TLA+ that TLC will check. (T0d explains what just happened. For now, just notice the file got bigger.)

The second command runs TLC against `Tick.tla` using the configuration in `Tick.cfg`.

## What to look for

Skim TLC's output until you find this line near the bottom:

```
6 states generated, 5 distinct states found, 0 states left on queue.
```

That's the success signal. Three specific things to spot:

- **"5 distinct states found"** — TLC explored 5 reachable states: the 4 states where `count` is 0, 1, 2, and 3 (the last tick), plus the `Done` state where the loop has exited with `count` still at 3.
- **"0 states left on queue"** — TLC finished. The state space is fully explored, not truncated.
- **"Model checking completed. No error has been found."** — every invariant declared in `Tick.cfg` held in every state.

If you see all three lines, the toolchain works.

## What's in the .cfg

Open the `Tick.cfg` you saved. Two real lines:

```
SPECIFICATION Spec
INVARIANT TypeOK
```

`SPECIFICATION Spec` tells TLC which definition in the spec describes "what the system does." `INVARIANT TypeOK` asks TLC to verify `TypeOK` in every reachable state. T0c covers the `.cfg` file in detail.

## What to take away

- The toolchain is two commands: translate, then check.
- Success looks like a count of distinct states and "No error has been found."
- The actual claim TLC verified — that `count` always stays in `0..3` — is encoded in the `INVARIANT` line, not in the spec.

Done. Move on to T0b, where TLC will report a *failure* and you will learn to read the trace.

## Hints

??? hint "💡 Hint 1 — What's the success signal?"
    The puzzle says to look for three specific lines in TLC's output. Search backwards from the bottom of the output — the signal you want is near the very end. What counts are you looking for?

??? hint "💡 Hint 2 — Understanding 'distinct states found'"
    The Tick spec models a clock counting from 0 to 3. The initial state is one state. Each tick is a state. When done, that's another state. Multiply that out — how many reachable states should exist?

??? hint "💡 Hint 3 — The translation step is always first"
    Remember: `tlc -pcal` translates PlusCal to TLA+. Without that translation, the second command has nothing to model-check. The two commands are a sequence: translate first, then check.
