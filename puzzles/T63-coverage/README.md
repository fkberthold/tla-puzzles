# T63: -coverage for Spec Hygiene ⭐

## Lesson: -coverage Tells You What TLC Actually Did

Every action in your spec has a number: how many times did TLC fire it during exploration? Most actions fire many times. **Some actions fire ZERO times.** Those are dead code — actions that look like they could happen but never do, because their guard is unreachable.

Dead actions are bugs. They mean either (a) you wrote an action that contradicts other constraints, or (b) you wrote an action whose precondition is impossible given the rest of the spec, or (c) the boundaries you chose for constants are too small and the action is reachable but not at this scale.

`-coverage N` tells TLC to print coverage statistics every `N` minutes. Even on a fast spec, `-coverage 1` is enough — TLC prints the report once at the end.

**Worked example — fortune cookies.**

```
(*--algorithm CookieFactory {
  variables baked = 0, broken = 0;

  fair process (oven = "Oven") {
    bake:
      while (baked + broken < 10) {
        either {
          baked := baked + 1;
        } or {
          broken := broken + 1;
        };
      };
  }

  fair process (recycler = "Recycler") {
    \* Tries to recycle broken cookies into bake-ready dough.
    \* Requires broken >= 100 — UNREACHABLE under our bound of 10.
    recycle:
      while (broken < 100) { skip; };
      reuse:
        broken := broken - 100;
        baked := baked + 100;
  }
}*)
```

Run `tlc -coverage 1 CookieFactory` and read the output. Toward the end you'll see lines like:

```
<bake line 5, col 1 to line 5, col 4>: 21:200
<recycle line 17, col 1 to line 17, col 7>: 21:200
<reuse line 19, col 1 to line 19, col 5>: 0:0
```

The format: `<action line ranges>: distinct:total`. The `reuse` action has fired **zero times**. That's a flag: either the action is dead at this bound (`broken` can never reach 100 if total cookies stop at 10), or the spec is wrong.

To diagnose:

1. Read the precondition. Here it's `broken >= 100`.
2. Compare to the achievable values at this bound. `broken` is bounded above by the loop bound (`10`).
3. Conclusion: action is dead at this bound. Either the bound is too small to test this action, or the action is logically impossible given the rest of the spec.

The fix is one of: raise the bound, remove the dead action, or rewrite it so it can fire.

**One subtlety.** Action coverage on PlusCal-translated specs reports the LABEL action. If your label has multiple `either/or` branches inside, all branches share the same action and you can't distinguish their coverage from the action line alone — you'll need to look at the per-LINE coverage further down in TLC's output to see which branches were dead.

## Setup

A pre-written PlusCal spec lives in `solution/Vending.tla`: a vending machine with three concurrent processes — Inserter (puts coins in), Buyer (buys an item for 1 coin), and Refunder (refunds 5 coins). The Refunder's precondition is `coins >= 5`, but `coins` is bounded above by 2 in the spec.

## Task

Run TLC with the `-coverage` flag:

```bash
cd solution
tlc -coverage 1 Vending
```

Look at the output near the end. You'll see a coverage report listing each action and the number of times TLC fired it.

Find the line for `<refundLoop ...>`. The format is `distinct:total`. You'll see something like `8:8` — but those 8 firings are the ELSE branch (when `items > 0` is false). Look further down at the line-level coverage. The lines INSIDE the refund body — `coins >= 5`, `coins' = coins - 5` — should show **0**.

## Check

- TLC reports successful checking: 25 distinct states, no errors.
- The coverage report shows `refundLoop` with both lines `coins >= 5` and `coins' = coins - 5` at coverage **0** — meaning that branch never fired.
- `insertLoop` and `buyLoop`'s body lines all have nonzero coverage.

## Expected Result

You should be able to identify, by reading the coverage report alone:

- Insert and Buy actions fire many times.
- The refund body (the `coins - 5` decrement) is **dead code** at this scale.
- The fix would be either to raise the coin bound (so the spec can build up to 5 coins) or to remove the refund process entirely from the spec, since it represents an impossible situation.

## What to take away

- `-coverage N` produces a per-action and per-line coverage report at the end of the run.
- ZERO coverage on an action body is a red flag. It means the action is dead — either logically impossible or untestable at this scale.
- Always run `-coverage` once before declaring a spec "done." A passing spec with dead actions is a spec you don't actually understand.
- Coverage is reported at action and at line granularity. Read both — actions tell you which labeled steps fired; line numbers tell you which sub-expressions fired.

## Hints

??? hint "💡 Hint 1 — Coverage Is a Sanity Check"
    Before you declare a spec "done," run with `-coverage 1`. Read the output: every action should have nonzero firing counts on at least one distinct state. If an action has ZERO across all states, it's dead code — either logically impossible given your guards, or unreachable at your chosen constants. Finding a zero-coverage action means either your bounds are too tight (increase the constant) or your action is broken (rewrite or remove it). Coverage is TLC's equivalent of test code coverage — it warns you about untested paths.

??? hint "💡 Hint 2 — The Refund Precondition"
    In Vending, the Refunder process tries to execute only when `coins >= 5`. But what's the maximum `coins` can reach in this spec? If the Buyer and Inserter together can't build up to 5 coins, then `coins >= 5` is always false, and the Refund's inner actions (the state changes) never fire. Coverage will report the label as "visited" (because the loop itself executed) but the BODY actions as zero-coverage. This is the key distinction: label-level vs. line-level coverage reporting.

??? hint "💡 Hint 3 — You Choose: Tighten Bounds or Remove Dead Code"
    If Refunder's body has zero coverage, your spec is telling you one of two things: (1) the bound on coins is too low, so the refund scenario is unreachable at this scale (raise the constant), or (2) the refund behavior is logically impossible and you should remove it. Read the spec and the bounds carefully. Dead code at zero coverage is a spec quality issue — it means you wrote something you don't actually need or test.
