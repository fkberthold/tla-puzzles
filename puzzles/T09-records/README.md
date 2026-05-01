# T09: Records — Constructor, Dot, EXCEPT ⭐⭐

## Lesson: Records — Bundling Named Fields

A RECORD is a value with named fields. You build one with the **constructor**:

```
[name |-> "Ada", age |-> 36]
```

You read a field with **dot**:

```
contact.name      \* "Ada"
contact.age       \* 36
```

You make an UPDATED COPY with `EXCEPT`:

```
[contact EXCEPT !.age = 37]      \* a new record with age = 37
```

`EXCEPT` does NOT mutate the original. It RETURNS a new record. So in PlusCal you write `contact := [contact EXCEPT !.age = 37]` to bind the variable to the updated value.

You can update multiple fields at once:

```
[contact EXCEPT !.age = 37, !.name = "Ada Lovelace"]
```

(R02 introduced you to record VALUES via the `define` block. T09 adds the missing piece: how to UPDATE one inside a process.)

**Worked example — a video-game character.**

A character has a `hp` (health), a `level`, and a `room`. The hero takes one action and one rest, watching their stats change.

```
(*--algorithm Hero {
  variables hero = [hp |-> 10, level |-> 1, room |-> "entrance"];

  define {
    Alive == hero.hp > 0
    Veteran == hero.level >= 2
  }

  fair process (player = "P1") {
    fight:
      \* Take 3 damage and move to the boss room.
      hero := [hero EXCEPT !.hp = hero.hp - 3, !.room = "boss"];
    rest:
      \* Survive the boss, gain a level, restore some hp.
      hero := [hero EXCEPT !.level = @ + 1, !.hp = 8];
  }
}*)
```

Sample invariants:

- `TypeOK == hero.hp \in 0..10 /\ hero.level \in 1..5 /\ hero.room \in {"entrance", "boss"}`
- `LevelMonotone == hero.level >= 1`

Two things to notice:

1. **Multiple updates in one EXCEPT.** Inside `fight`, both `hp` and `room` change in a single `EXCEPT` — comma-separated. They both happen as part of the SAME record-rewrite, so the one-assignment-per-label rule sees one assignment to `hero`, not two.

2. **`@` for "old value" inside EXCEPT.** Inside `rest`, `!.level = @ + 1` reads as "set level to the OLD level plus 1." `@` is a placeholder for the existing value of THAT field. (You'll meet `@` in detail in T15. For now: `@` means "what was there before.")

You can equivalently write `!.level = hero.level + 1`. Both are correct. `@` is shorter when the record name is long.

**The puzzle below** uses records to model a different domain. Build, read, and update.

## Setup

A bank account is a record with three fields: `balance` (a number), `owner` (a name), and `frozen` (a boolean). The bank performs a series of operations on a single account:

1. Open the account for "Bob" with $0 and not frozen.
2. Deposit $100.
3. Withdraw $30.
4. Freeze the account.

After all four steps, the bank should hold exactly $70 for Bob, frozen.

## Task

Write a PlusCal spec with:

- A variable `account` initialized to `[balance |-> 0, owner |-> "Bob", frozen |-> FALSE]` (the "open" state)
- A variable `step` starting at `0`
- A single fair process that runs four labels in order:
  1. **deposit**: set `balance` to `balance + 100` using EXCEPT with `@`. Increment `step`.
  2. **withdraw**: set `balance` to `balance - 30` using EXCEPT. Increment `step`.
  3. **freeze**: set `frozen` to `TRUE` using EXCEPT. Increment `step`.
  4. **finish**: increment `step`. (No record change.)

The labels can be sequenced naturally — no `goto` needed; PlusCal falls through to the next label.

In the `define` block, write:

- `Owner == account.owner`
- `Balance == account.balance`
- `IsFrozen == account.frozen`
- `TypeOK == account.balance \in 0..200 /\ account.owner \in {"Bob"} /\ account.frozen \in BOOLEAN /\ step \in 0..4`

## Check

1. **TypeOK** — see above.
2. **OwnerStable**: `Owner = "Bob"` — the owner field never changes
3. **EndsCorrect**: `step = 4 => (Balance = 70 /\ IsFrozen)` — after all steps, balance is 70 and account is frozen

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **5 distinct states** (one per value of `step`: 0, 1, 2, 3, 4); your spec will also be deterministic — no nondeterminism — and may produce the same count, but the number of states depends on your label placement, not your correctness.
- Inspect the trace by hand to confirm: balance goes 0 → 100 → 70 → 70 → 70, frozen flips false → false → false → true → true.

**Bonus to try.** Replace `EndsCorrect` with `BalanceMonotone == Balance >= 0`. Will TLC pass it for THIS puzzle? Will it pass it if the withdraw amount were larger? (You don't need to actually fail it — just think about why it currently passes.)

## Hints

??? hint "💡 Hint 1 — EXCEPT is shorthand for reassignment"
    The lesson section shows that `[contact EXCEPT !.age = 37]` returns a NEW record. You don't mutate the original — TLA+ has no mutation. So to "update" a variable, you write `account := [account EXCEPT !.field = newValue]`. What are the four field updates you need (one per label)?

??? hint "💡 Hint 2 — Use `@` for "the old value""
    Inside EXCEPT, `@` refers to the CURRENT value of that field. So `[account EXCEPT !.balance = @ + 100]` means "add 100 to the balance." For the second label, you'll use `@ - 30`. For the third label, you DON'T use EXCEPT on balance — which field does that label touch?

??? hint "💡 Hint 3 — Four sequential labels, one per action"
    The labels are `deposit`, `withdraw`, `freeze`, `finish`. PlusCal falls through naturally — after `deposit` completes, control passes to `withdraw` without needing a `goto`. Within each label, update the account once (using EXCEPT), then increment `step`. The fourth label just increments `step` and does nothing to the account.
