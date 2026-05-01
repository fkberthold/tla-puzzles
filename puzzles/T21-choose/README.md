# T21: CHOOSE — Picking a Witness (Beware: Deterministic) ⭐⭐

## Lesson: `CHOOSE` Is NOT Nondeterministic

`CHOOSE` looks like it picks from a set, and your instinct will say "this is like `with`." It is NOT.

```
CHOOSE x \in S : P(x)
```

Read: "the value `x` in `S` such that `P(x)`."

`CHOOSE` is a **mathematical operator that returns ONE specific value**. TLC commits to a particular choice — the SAME choice every time, deterministically — and never branches. `with` and `\E` introduce nondeterminism (multiple branches); `CHOOSE` does not.

```
\* These are different!
with (x \in S) { v := x; }            \* TLC explores EVERY x in S as a separate branch
v := CHOOSE x \in S : TRUE;           \* TLC picks ONE x and uses it deterministically — same x every run
```

**When does `CHOOSE` shine?**

- You need a STABLE REPRESENTATIVE of a set — say "the canonical choice." Two evaluations of the same `CHOOSE` give the same answer, so it works as a stable name.
- You need to PICK A WITNESS for an existential. If you've established `\E x \in S : P(x)`, `CHOOSE x \in S : P(x)` returns one such x.

**When `CHOOSE` is the wrong tool:**

- You want TLC to explore both branches → use `with` or `\E` in the next-state relation.
- You need different choices in different states → `CHOOSE` always returns the same value when applied to the same set and predicate.

**`CHOOSE` of an impossible predicate is undefined.** `CHOOSE x \in S : FALSE` has no value satisfying the predicate. TLC will report an error if you try to evaluate it. Always make sure the predicate is satisfiable.

**Worked example — picking a representative customer.**

A shop has a set of frequent customers. The marketing team wants to put one customer on a poster — any customer is fine, as long as the choice is STABLE so the printout matches across runs.

```
(*--algorithm Poster {
  variables
    customers = {"alice", "bob", "carol"},
    spokesperson = "tbd";

  define {
    \* CHOOSE picks ONE specific customer — TLC picks the same one every time.
    Pick == CHOOSE c \in customers : TRUE
  }

  fair process (marketing = "Marketing") {
    print:
      spokesperson := Pick;
  }
}*)
```

Sample invariants:

- `TypeOK == spokesperson \in customers \cup {"tbd"}`
- `Stable == TRUE`  \* spokesperson, once set, never changes — and it's always the same customer

What you'll see: TLC reports a deterministic spec — exactly 2 states, the initial and the post-print. No branching despite `customers` having 3 elements. `CHOOSE` did not introduce nondeterminism.

Compare against `with (c \in customers) { spokesperson := c; }`: that would give 4 states (1 initial + 3 different post-print states, one per customer choice).

**Picking a witness with a real predicate.** Say you've got a set of accounts and want the "smallest balance" one (whatever "smallest" means, picked stably).

```
PoorestAccount == CHOOSE a \in accounts : \A b \in accounts : balance[a] <= balance[b]
```

This returns the account with the minimum balance. (`CHOOSE` over a tied predicate picks ONE arbitrarily-but-stably; you don't get to control which.)

## Setup

A small lottery system has 4 numbered tickets `{1, 2, 3, 4}`. Two operators run:

1. **announceWinner** — `CHOOSE`s a winning ticket (any ticket; the predicate is always-true). Because `CHOOSE` is deterministic, the same ticket "wins" every run.
2. **announceMinValid** — `CHOOSE`s the SMALLEST ticket whose number is at least 2. The predicate filters; `CHOOSE` picks one (and "smallest" makes it predictable).

You'll see TLC report only one trace despite the larger set: `CHOOSE` is not branching.

## Task

Write a PlusCal spec with:

- A variable `tickets` initialized to `{1, 2, 3, 4}`
- A variable `winner` starting at `0`
- A variable `minValid` starting at `0`
- A variable `phase` starting at `0`

In the `define` block:

- `Tickets == tickets`
- `AnyTicket == CHOOSE t \in Tickets : TRUE`
- `SmallestAtLeast2 == CHOOSE t \in Tickets : t >= 2 /\ \A u \in Tickets : (u >= 2 => t <= u)`
- `TypeOK == winner \in Tickets \cup {0} /\ minValid \in Tickets \cup {0} /\ phase \in 0..2`
- `MinIs2 == phase = 2 => minValid = 2`

A single fair process runs two labels:

1. **announceWinner**: set `winner := AnyTicket`. Increment `phase`.
2. **announceMinValid**: set `minValid := SmallestAtLeast2`. Increment `phase`.

## Check

1. **TypeOK** — see above.
2. **MinIs2** — once both labels run, `minValid` equals 2 (the smallest ticket >= 2).
3. **WinnerStable**: `phase >= 1 => winner = AnyTicket` — `AnyTicket` is the same value across runs, so once set, `winner` matches it.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **3 distinct states** — one per `phase` value. The state count is small because `CHOOSE` is deterministic, not branching.
- `winner` ends up as a specific ticket (some number 1–4); rerun TLC and you'll see the same number every time. That's the deterministic nature of `CHOOSE`.

**Bonus.** Replace `AnyTicket` in the `announceWinner` body with a `with (t \in Tickets) { winner := t; }`. Predict the new state count, then run. (Hint: 4 branches at `announceWinner`, then 4 at `announceMinValid` — but the second one is still `CHOOSE`, not `with`.) This contrast pins down what `CHOOSE` is and isn't.

## Hints

??? hint "💡 Hint 1 — CHOOSE picks ONE value, deterministically"
    `CHOOSE x \in S : TRUE` picks a SPECIFIC element from `S` — the same element every time. It does NOT branch. Compare with `with (x \in S)`, which branches on every element. If you use `with`, TLC explores 4 branches; if you use `CHOOSE`, TLC picks one and ignores the rest.

??? hint "💡 Hint 2 — Predicate must be satisfiable"
    `CHOOSE x \in S : P(x)` returns one element that satisfies `P`. If NO element satisfies `P`, TLC errors. In the `SmallestAtLeast2` operator, the predicate `t >= 2 /\ \A u \in Tickets : (u >= 2 => t <= u)` is satisfiable (ticket 2 satisfies it), so TLC won't complain.

??? hint "💡 Hint 3 — Two operators, two different tools"
    `AnyTicket == CHOOSE t \in Tickets : TRUE` deterministically picks ONE ticket (the same one every run). `SmallestAtLeast2 == CHOOSE t \in Tickets : t >= 2 /\ \A u \in Tickets : (u >= 2 => t <= u)` deterministically picks the SMALLEST ticket >= 2 (which is 2). Neither branches — both are stable, deterministic choices.
