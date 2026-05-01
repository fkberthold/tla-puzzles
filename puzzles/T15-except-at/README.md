# T15: Functions — EXCEPT with `@` ⭐

## Lesson: Relative Update with `@`

T14 wrote a NEW value for one entry: `[f EXCEPT ![k] = v]`. T15 adds the missing piece: how to write a new value that DEPENDS ON THE OLD ONE.

```
[counters EXCEPT ![k] = @ + 1]
```

Inside `EXCEPT`, the symbol `@` means "the old value at THIS key." So `@ + 1` is "increment whatever was there." It's the function-update equivalent of `x := x + 1` for scalars.

Without `@`, you'd write:

```
counters := [counters EXCEPT ![k] = counters[k] + 1];
```

That works, but as the function name gets longer or the key gets more complex, the redundancy mounts:

```
inventory := [inventory EXCEPT ![item] = inventory[item] + delta];   \* without @
inventory := [inventory EXCEPT ![item] = @ + delta];                 \* with @
```

`@` is a sharp tool for queue-append, counter-increment, list-update — anywhere "new value depends on old value" within `EXCEPT`.

You also get `@` in record syntax: `[r EXCEPT !.field = @ * 2]` doubles whatever was at `field`.

**Worked example — a tally board.**

A poll-station worker records votes for three candidates. Each ballot adds one to the chosen candidate's count. The pollster ALSO has a special "spoil" action that voids two votes from a candidate.

```
(*--algorithm Poll {
  variables tally = [c \in {"A", "B", "C"} |-> 0];

  fair process (counter = "Counter") {
    voteA:
      tally := [tally EXCEPT !["A"] = @ + 1];
    voteAagain:
      tally := [tally EXCEPT !["A"] = @ + 1];
    voteB:
      tally := [tally EXCEPT !["B"] = @ + 1];
    spoilA:
      tally := [tally EXCEPT !["A"] = @ - 2];     \* @ is the OLD value at "A", which is 2
  }
}*)
```

Sample invariants:

- `TypeOK == \A c \in DOMAIN tally : tally[c] \in -2..5`
- `Bzero == tally["B"] >= 0` — passes; B never gets decremented
- `Acycles == TRUE`  \* (placeholder for "trace through by hand and confirm A goes 0,1,2,2,0")

After the four labels, `tally["A"] = 0` (incremented twice to 2, then `@ - 2` makes it 0). `tally["B"] = 1`. `tally["C"] = 0`.

Two things to remember:

1. **`@` is local to one entry's update.** In `[f EXCEPT ![k1] = @ + 1, ![k2] = @ - 1]`, the first `@` means "old `f[k1]`" and the second means "old `f[k2]`." They DON'T see each other's new values.

2. **All `@`s in one EXCEPT see the OLD function.** `[f EXCEPT ![k1] = @ + f[k2]]` reads `f[k2]`'s OLD value, even if you also rewrote it in the same EXCEPT. This matters when the updates would conflict.

## Setup

A multi-counter dashboard tracks how many times each user has clicked a button. Users are `{"u1", "u2", "u3"}`. Each click increments the right user's counter by 1. After 4 clicks distributed across users, the dashboard reports the final tallies.

You'll script the clicks deterministically (no nondeterminism — one click per label). The point is the `@` syntax.

## Task

Write a PlusCal spec with:

- A variable `clicks` initialized to `[u \in {"u1", "u2", "u3"} |-> 0]`
- A variable `step` starting at `0`

A single fair process runs four labels:

1. **clickU1**: `clicks := [clicks EXCEPT !["u1"] = @ + 1]`. Increment `step`.
2. **clickU2**: `clicks := [clicks EXCEPT !["u2"] = @ + 1]`. Increment `step`.
3. **clickU1again**: `clicks := [clicks EXCEPT !["u1"] = @ + 1]`. Increment `step`.
4. **clickU3**: `clicks := [clicks EXCEPT !["u3"] = @ + 1]`. Increment `step`.

In the `define` block:

- `Users == DOMAIN clicks`
- `TypeOK == Users = {"u1", "u2", "u3"} /\ \A u \in Users : clicks[u] \in 0..2 /\ step \in 0..4`
- `Total == clicks["u1"] + clicks["u2"] + clicks["u3"]`
- `TotalEqualsStep == Total = step` — every click increments exactly one user's counter, so the total tracks `step`
- `EndsCorrect == step = 4 => (clicks["u1"] = 2 /\ clicks["u2"] = 1 /\ clicks["u3"] = 1)`

## Check

1. **TypeOK** — see above.
2. **TotalEqualsStep** — total clicks always equals step count.
3. **EndsCorrect** — the final tallies are 2, 1, 1.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **5 distinct states** (one per `step` value: 0, 1, 2, 3, 4). Your deterministic spec will likely produce the same count.

**Bonus.** Replace `@ + 1` with `clicks["u1"] + 1` (the verbose form) in the third label. Verify TLC still produces the same 5 states. The `@` form is shorter; the verbose form is equivalent.

## Hints

??? hint "💡 Hint 1 — `@` is the old value of THIS entry"
    Inside `[clicks EXCEPT ![key] = @ + 1]`, the `@` refers to the current value AT THAT KEY. So `@ + 1` increments whatever was stored there. Each click increments a different user's counter — the first and third clicks increment u1 (so u1 ends at 2), the second increments u2, the fourth increments u3.

??? hint "💡 Hint 2 — @ is scoped to one EXCEPT clause"
    If you have multiple updates in one EXCEPT, each `@` refers to its own key's old value: `[f EXCEPT ![k1] = @ + 1, ![k2] = @ - 1]` increments k1 and decrements k2. They don't interfere. All `@`s see the OLD function before any updates.

??? hint "💡 Hint 3 — Four clicks, one per label"
    The `clickU1`, `clickU2`, `clickU1again`, `clickU3` labels each update ONE user's counter by 1 (using `@ + 1`). After all four, u1 has 2, u2 has 1, u3 has 1. The invariant `TotalEqualsStep` confirms: 4 clicks, total of 4 increments distributed across users.
