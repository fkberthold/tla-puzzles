# T27: The Level System — Recognize Each ⭐

## Lesson: Three Kinds of Formulas

Every expression in TLA+ lives at one of three **levels**. Recognizing which level something is at tells you where it can legally appear.

| Level | Name | Mentions | Examples |
|---|---|---|---|
| 1 | **state** | only unprimed variables (or none) | `x > 0`, `r.field = 5`, `TypeOK` |
| 2 | **action** | at least one primed variable | `x' = x + 1`, `UNCHANGED y`, `Next` |
| 3 | **temporal** | uses `[]`, `<>`, `~>`, `WF`, `SF` | `[]TypeOK`, `<>Done`, `Spec` |

Mechanics:

- **State formulas** are checked at one state. `INVARIANT P` in a `.cfg` means "P is a state formula and TLC checks it on every reachable state."
- **Action formulas** relate two consecutive states. They appear inside `Next` or get wrapped in `[][...]_v` to lift them to temporal level.
- **Temporal formulas** are claims about behaviors — sequences of states. `PROPERTY P` in a `.cfg` means "P is a temporal formula." `SPECIFICATION Spec` requires `Spec` itself to be temporal.

The level rules are checked by the parser, not by TLC. Mismatch errors at parse time:

- `INVARIANT Next` → error. `Next` is action level (mentions primed variables); invariants must be state level.
- `INVARIANT Spec` → error. `Spec` is temporal level.
- `PROPERTY TypeOK` → wrong. `TypeOK` is a state predicate; you'd need `[]TypeOK` to lift it to temporal.

**Worked example — classifying expressions in a bank account spec.**

Suppose you have:

```
VARIABLE balance

TypeOK         == balance \in 0..1000
Deposit        == balance' = balance + 100
NoOverdraft    == balance >= 0
Stable         == balance' = balance
EventuallyRich == <>(balance > 500)
NeverNegative  == [](balance >= 0)
Spec           == (balance = 0) /\ [][Deposit]_balance
```

| Expression | Level | Why |
|---|---|---|
| `TypeOK` | state | only `balance`, no prime |
| `Deposit` | action | mentions `balance'` |
| `NoOverdraft` | state | only `balance`, no prime |
| `Stable` | action | mentions `balance'` (yes, even though it says `= balance` — the prime makes it action level) |
| `EventuallyRich` | temporal | uses `<>` |
| `NeverNegative` | temporal | uses `[]` |
| `Spec` | temporal | uses `[][...]_v`, top-level temporal |

Two traps to remember:

1. `UNCHANGED x` expands to `x' = x` — that's **action level**, not state level. You cannot put `UNCHANGED` in an invariant.
2. `Init` looks like `/\ x = 0 /\ y = "off"` — pure equalities, no primes — so `Init` is **state level**. That is why `SPECIFICATION` cannot be just `Init`; you need `Init /\ [][Next]_v` to make it temporal.

## Setup

A pure-TLA+ spec for a **lock** is shown below as the file `Lock.tla` (also in the 🔒 spoiler). It declares several named formulas: `TypeOK`, `Locked`, `LockIt`, `Unlock`, `Stable`, `EventuallyUnlocked`, `NeverDoubleLocked`, `Init`, `Next`, `Spec`. Some are state-level, some action-level, some temporal-level.

## Task

For each named formula in `Lock.tla`, classify its level (state / action / temporal). Write your answer down before reading the answer key below.

Then verify your reading by trying these `.cfg` edits, one at a time, and observing TLC's response:

1. **Replace `INVARIANT TypeOK` with `INVARIANT Next`.** What happens?
2. **Replace `INVARIANT TypeOK` with `INVARIANT NeverDoubleLocked`.** What happens?
3. **Replace `INVARIANT TypeOK` with `INVARIANT EventuallyUnlocked`.** What happens?
4. **Replace `PROPERTY EventuallyUnlocked` with `PROPERTY TypeOK`.** What happens?
5. Restore the original `Lock.cfg` (`SPECIFICATION Spec`, `INVARIANT TypeOK`, `PROPERTY EventuallyUnlocked`).

Each error message is TLC telling you about a level mismatch. The wording differs but the cause is always: the formula is at the wrong level for the directive.

## Check

Final clean run from `solution/`:

```bash
tlc Lock
```

Should report **no error** and a small state count.

## Expected Result

Answer key (don't peek until you've classified yourself):

| Formula | Level |
|---|---|
| `TypeOK` | state |
| `Locked` | state |
| `LockIt` | action (mentions `state'`) |
| `Unlock` | action |
| `Stable` | action (`UNCHANGED state` expands to `state' = state`) |
| `Init` | state |
| `Next` | action (`Next == LockIt \/ Unlock`) |
| `EventuallyUnlocked` | temporal (uses `<>`) |
| `NeverDoubleLocked` | temporal (uses `[]`) |
| `Spec` | temporal |

TLC summary on the clean cfg: **2 distinct states** (locked / unlocked), `TypeOK` passes, `EventuallyUnlocked` passes (with weak fairness, the system is forced to unlock).

If you classified `Stable` as state-level, you'd expect `INVARIANT Stable` to work — but `UNCHANGED` always introduces primes, so it does not. Re-read the table whenever you find yourself surprised.

## Hints

??? hint "💡 Hint 1 — Does it mention a prime?"
    The level of a formula depends on whether it mentions primed variables (`x'`, `y'`, etc.). State formulas have no primes. Action formulas have at least one prime. Read each named formula in `Lock.tla` and ask: do I see any primed variables? If yes, it's action level. If no, it's state level (unless it uses `[]` or `<>`, which makes it temporal).

??? hint "💡 Hint 2 — What does UNCHANGED expand to?"
    The keyword `UNCHANGED x` is a shorthand. It expands to `x' = x` — which contains a prime. So even though `Stable == UNCHANGED state` looks like it just talks about the current state, it actually mentions `state'`, making it **action level**. This is a common trap: many students think `UNCHANGED` is state-level.

??? hint "💡 Hint 3 — Temporal operators: `[]` and `<>`"
    If a formula contains `[]` (always), `<>` (eventually), or other temporal operators, it is **temporal level**. `NeverDoubleLocked == []...` uses `[]`, so it is temporal. Even if the inner expression is state-level, wrapping it in `[]` lifts the whole thing to temporal. Similarly, `EventuallyUnlocked` uses `<>`.
