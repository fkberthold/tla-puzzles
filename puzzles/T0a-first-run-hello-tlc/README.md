# T0a: First Run — Hello, TLC ⭐

**Tier 0 prelude.** No new concept. No code to write. The only goal is to run the toolchain end-to-end and recognize what success looks like.

## What this puzzle is

A pre-written tiny spec lives in `solution/Tick.tla`. It models a clock that ticks from 0 to 3. You will translate it, model-check it, and read TLC's output.

You are NOT expected to understand the spec yet. Tier 1 covers PlusCal. Tier 0 is purely about the workflow: command in, output out, what does each line mean.

## Run it

From this directory:

```bash
cd solution
tlc -pcal Tick.tla     # PlusCal → TLA+ translation
tlc Tick               # model-check
```

The first command rewrites `Tick.tla` in place, adding a `\* BEGIN TRANSLATION ... \* END TRANSLATION` block. That's the actual TLA+ that TLC will check. (T0d will explain what just happened. For now, just notice the file got bigger.)

The second command runs TLC against `Tick.tla` using the configuration in `Tick.cfg`.

## What to look for

Skim TLC's output until you find this line near the bottom:

```
6 states generated, 5 distinct states found, 0 states left on queue.
```

That's the success signal. Specifically:

- **"5 distinct states found"** — TLC explored 5 reachable states (initial + 3 ticks + 1 done). One reachable state per value of `count` plus the post-loop state.
- **"0 states left on queue"** — TLC finished. The state space is fully explored, not truncated.
- **"Model checking completed. No error has been found."** — every invariant in `Tick.cfg` held in every state.

If you see all three lines, the toolchain works.

## What's in the .cfg

Open `solution/Tick.cfg`. Two real lines:

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
