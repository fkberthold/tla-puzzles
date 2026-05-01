# `Sequences`

Standard library. Brings sequences (1-indexed, finite, ordered).

```tla
EXTENDS Sequences
```

A sequence is written `<<x, y, z>>`. The empty sequence is `<<>>`.

## Operators

| Operator | Type | Meaning |
|---|---|---|
| `<<a, b, c>>` | — | sequence literal (length 3, indexed 1..3) |
| `<<>>` | — | empty sequence |
| `Len(s)` | Seq(T) → Nat | length of `s` |
| `Head(s)` | Seq(T) → T | first element (`s[1]`); undefined if `s = <<>>` |
| `Tail(s)` | Seq(T) → Seq(T) | all but the first element; undefined if `s = <<>>` |
| `Append(s, x)` | Seq(T) × T → Seq(T) | new sequence with `x` added at the end |
| `s \o t` | Seq(T) × Seq(T) → Seq(T) | concatenation |
| `SubSeq(s, m, n)` | Seq(T) × Nat × Nat → Seq(T) | the slice `<<s[m], ..., s[n]>>` (1-indexed) |
| `SelectSeq(s, P)` | Seq(T) × (T → Bool) → Seq(T) | filter — keep elements where `P` is true |

## 1-indexed access

Sequences are functions on `1..Len(s)`. Element access is `s[i]` for `i \in 1..Len(s)`.

```tla
s == <<10, 20, 30>>
\* s[1] = 10, s[2] = 20, s[3] = 30
\* DOMAIN s = {1, 2, 3} = 1..Len(s)
```

`s[0]` is undefined (out of domain). This trips up programmers used to 0-indexed languages.

## Special sets

| Set | Meaning |
|---|---|
| `Seq(T)` | the set of all finite sequences of `T` (infinite — bound with `Len(s) <= N` in `TypeOK`) |

## Example

```tla
queue == <<>>           \* empty
queue' = Append(queue, "alice")
\* queue' = <<"alice">>, Len(queue') = 1, Head(queue') = "alice"
```

## First introduced

T10 (Sequences — Literal, Append, 1-Indexed Access). Concat (`\o`) and SubSeq covered in T11.
