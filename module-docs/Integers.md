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
| `a \div b` | Int × Int → Int | integer division, rounding down (see below) |
| `a % b` | Int × Int → Int | remainder, always in `0..b-1` (see below) |
| `-a` | Int → Int | unary negation |
| `a ^ n` | Int × Nat → Int | exponent (only `n ≥ 0`) |

## Negative operands

`\div` rounds down and `%` is never negative. The contract both obey is stated in the `Naturals.tla` that ships inside `tla2tools.jar`:

```
a % b  and  a \div b  are defined so that for any integers  a  and  b
with  b > 0 , the following formula is true:

   a  =  b * (a \div b) + (a % b)
```

TLC holds to it. Parenthesize the negative literal and the identity comes out:

```tla
\* (-17) \div 5 = -4                      (-17) % 5 = 3
\* 5 * ((-17) \div 5) + ((-17) % 5) = -17
```

The trap here is precedence, not arithmetic. Prefix `-` sits at 12-12, `\div` at 13-13, and `%` at 10-11. So `\div` binds tighter than the minus sign and `%` binds looser. Drop the parentheses and the two halves of the identity group different ways:

```tla
\* -17 \div 5 = -3        parses as -(17 \div 5)
\* -17 % 5    = 3         parses as (-17) % 5
```

Now `5 * (-3) + 3` is `-12` and the contract looks broken. Nothing is wrong but the grouping. Put parentheses around any negative literal you hand to `\div`. I'd do the same on `%`, where it costs nothing and saves the reader a lookup.

This one catches people who come from C or Java, where `/` truncates toward zero and `%` takes the sign of the dividend. TLA+ does neither.

A negative divisor is a separate case, and the module doesn't cover it. `\div` still rounds down, so `17 \div (-5)` is `-4`. `%` refuses, with "The second argument of % should be a positive number". The module defines the pair through a witness in `0..(b-1)`, and that interval is empty once `b` goes negative. So I read TLC's answer there as going past its own spec. Filed upstream as [tlaplus#721](https://github.com/tlaplus/tlaplus/issues/721), open since 2022.

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
