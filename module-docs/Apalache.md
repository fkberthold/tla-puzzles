# `Apalache`

Library that ships with the Apalache symbolic model checker. It also ships locally in `puzzles/A04-A09/solution/Apalache.tla` and `puzzles/T67-distributed-counter/solution/Apalache.tla` so the same spec can run under both TLC and Apalache.

```tla
EXTENDS Apalache
```

The module's operators are defined with TLA+ erasure semantics so TLC accepts them (`__x := __e == __x = __e`); Apalache replaces them with native symbolic semantics at check time.

## Operators used in this curriculum

| Operator | Type | Meaning |
|---|---|---|
| `x := e` | — | explicit assignment in a transition. Equivalent to `x' = e` for TLC; Apalache uses it to enforce assignment discipline (each variable is assigned exactly once per action). T04 covers this. |
| `ApaFoldSet(Op, base, S)` | (T × T → T) × T × Set(T) → T | fold a binary operator over a set, starting from `base`. T05 covers this. |
| `ApaFoldSeqLeft(Op, base, s)` | (T × T → T) × T × Seq(T) → T | fold over a sequence from left. |
| `Gen(size)` | Int → ? | generate a small data structure (Apalache-only; TLC sees it as `{}`). Not used in this curriculum. |

## Type annotations (comments, not operators)

Apalache reads typing hints from comments. The curriculum uses these patterns:

```tla
VARIABLES
  \* @type: Int;
  count,
  \* @type: Set(Str);
  members

CONSTANT
  \* @type: Int;
  MaxN

\* @typeAlias: order = { id: Int, qty: Int };
\* @type: Seq($order);
queue
```

A07 introduces the `ConstInit` pattern for symbolically parameterizing constants (`apalache check --cinit=ConstInit ...`).

## Apalache-only constructs

- `--cinit=Op` — symbolically initialize CONSTANTs from a predicate
- `--length=N` — bound the symbolic exploration depth
- Snowcat type checker — runs first, must pass before model checking

## When to choose Apalache vs TLC

See [J03: TLC vs Apalache](../../curriculum/judgments/J03.md) for the full judgment. Short version: TLC for liveness checking and concrete traces; Apalache for safety with large or symbolic constants.

## First introduced

A01 (Hello, Snowcat) — type annotations and basic Apalache workflow.
