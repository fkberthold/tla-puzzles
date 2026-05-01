# `Integers`

Standard library. Brings the integers `..., -2, -1, 0, 1, 2, ...` and the usual arithmetic.

```tla
EXTENDS Integers
```

## Operators

| Operator | Type | Meaning |
|---|---|---|
| `a + b` | Int × Int → Int | addition |
| `a - b` | Int × Int → Int | subtraction |
| `a * b` | Int × Int → Int | multiplication |
| `a \div b` | Int × Int → Int | integer division (truncates toward zero) |
| `a % b` | Int × Int → Int | remainder, sign follows the dividend |
| `-a` | Int → Int | unary negation |
| `a ^ n` | Int × Nat → Int | exponent (only `n ≥ 0`) |

## Comparisons

| Operator | Meaning |
|---|---|
| `a < b`, `a <= b`, `a > b`, `a >= b` | usual ordering on `Int` |

## Range constructor

| Operator | Type | Meaning |
|---|---|---|
| `a..b` | Int × Int → Set(Int) | the set `{a, a+1, ..., b}`. Empty if `a > b` |

`a..b` is the workhorse for bounding state variables. `count \in 0..3` says count is one of 0, 1, 2, or 3.

## Special set

`Int` — the set of all integers (infinite; TLC won't enumerate it, so spec writers always bound their variables with `..` or `\in 0..N` rather than `\in Int`).

## Example

```tla
TypeOK == count \in 0..MaxN
Inc == count' = count + 1
Reset == count' = 0
```

## First introduced

T01 (curriculum's first puzzle imports it for the `..` range invariant in TypeOK).
