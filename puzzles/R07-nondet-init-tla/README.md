# R07: Review — Nondeterministic Init in Pure TLA+ ⭐

## Lesson: `\E` in an Init Predicate

Back in T02 you used `with` to make a PlusCal variable start with a nondeterministic value. In pure TLA+ there's no `with` — but you don't need one. The Init predicate is a FORMULA about the variables, and any variable assignment that satisfies the formula is a valid initial state. TLC takes ALL of them.

The pattern: **`Init == \E v \in S : x = v`** says "there exists some `v` in `S` such that `x = v`" — i.e. `x` is some value in `S`. TLC enumerates every possible `v` and starts an exploration from each.

Equivalent shorthand: **`Init == x \in S`**. Both mean the same thing — a nondeterministic initial value drawn from `S`. TLC accepts either; experienced spec authors usually write `x \in S` for one variable and reach for `\E` when several variables are coupled.

**Worked example — a clock with an unknown starting hour.**

A 12-hour clock starts at some hour between 1 and 12 (we don't know which), then ticks forward each step.

```
---- MODULE Clock ----
EXTENDS Integers

VARIABLE hour

Init == \E h \in 1..12 : hour = h

Tick == hour' = (hour % 12) + 1

Next == Tick

Spec == Init /\ [][Next]_hour

TypeOK == hour \in 1..12
================================
```

TLC starts with 12 distinct initial states — one per hour. From each, `Tick` walks the cycle. The reachable state space is just `{1,2,...,12}`, so TLC reports 12 distinct states total.

The two facts to take away:

1. `Init` is a PREDICATE, not an assignment. Any state where the predicate is true is a starting point.
2. `\E v \in S : x = v` is the canonical "nondeterministic initial value" idiom in pure TLA+. The spec doesn't COMMIT to one starting value; TLC checks the property under EVERY one.

If multiple variables are coupled, you'd write something like `Init == \E v \in S : x = v /\ y = f(v)` — the `\E` binds a witness and the body uses it.

## Setup

A library has a bookshelf that started with some unknown number of books between 0 and 5 — nobody counted before opening day. Each step, a borrower takes one book away. If the shelf is empty, nothing happens (the system stutters).

We want TLC to verify, no matter the unknown starting count, that the book count never goes negative.

## Task

Write a PURE TLA+ spec (no PlusCal block) with:

- `EXTENDS Integers`
- A single `VARIABLE books`
- An `Init` predicate that uses `\E` to pick a starting value from `0..5`
- A `Next` action that decrements `books` by 1 if `books > 0`, otherwise leaves it unchanged
- A `Spec` formula of the form `Init /\ [][Next]_books`

Add invariants:

- `TypeOK == books \in 0..5`
- `NeverNegative == books >= 0`

## Check

Run TLC. Both `TypeOK` and `NeverNegative` must hold.

## Expected Result

- TLC enumerates 6 initial states (`books = 0`, `books = 1`, ..., `books = 5`)
- From each, the `Borrow` action walks down to 0
- Total reachable states: 6 distinct
- All invariants pass

## Hint

For the `Next` action, you can write:

```
Borrow == books > 0 /\ books' = books - 1

Next == Borrow
```

Notice we don't need to handle the "nothing happens" case explicitly — `[Next]_books` already allows stuttering steps where `books` is unchanged. (You'll learn more about `[A]_v` and stuttering in T32, but the short version: stuttering is built in.)

In your `.cfg`, add `CHECK_DEADLOCK FALSE` so TLC doesn't flag the `books = 0` terminal state as a deadlock — we WANT the spec to stutter there, which is exactly what `[Next]_books` permits.
