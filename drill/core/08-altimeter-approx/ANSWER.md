# Twin altimeters: answer

## The answer

```tla
---- MODULE Altimeters ----
EXTENDS Integers

CONSTANTS Tol, Span

VARIABLES a, b, fault

vars == <<a, b, fault>>

x \approx y == x - y <= Tol /\ y - x <= Tol

Readings == -Span..Span

TypeOK ==
  /\ a \in Readings
  /\ b \in Readings
  /\ fault \in BOOLEAN

Init ==
  /\ a = 0
  /\ b = 0
  /\ fault = FALSE

DriftA ==
  /\ \E d \in {-1, 1} :
       /\ a + d \in Readings
       /\ a' = a + d
  /\ fault' = ~(a' \approx b)
  /\ UNCHANGED b

DriftB ==
  /\ \E d \in {-1, 1} :
       /\ b + d \in Readings
       /\ b' = b + d
  /\ fault' = ~(a \approx b')
  /\ UNCHANGED a

Resync ==
  /\ fault
  /\ b' = a
  /\ fault' = FALSE
  /\ UNCHANGED a

Next == DriftA \/ DriftB \/ Resync

Spec == Init /\ [][Next]_vars

FaultIffDisagree == fault <=> ~(a \approx b)
====
```

```
SPECIFICATION Spec
CONSTANTS
  Tol = 1
  Span = 3
INVARIANTS
  TypeOK
  FaultIffDisagree
```

`x \approx y == ...` defines an infix operator. The left operand goes before
the symbol and the right after, and the symbol has to be one TLA+ reserves for
the purpose. `\approx` is one. `~=` isn't, and I'd guess it's the first thing a
reader coming from code tries.

`fault' = ~(a' \approx b)` uses the primed reading inside the operator. That's
an expression over the next state, and it's the plain way to say "reacts in the
same instant". The rule, `fault <=> ~(a \approx b)`, is the same shape
unprimed.

`Readings == -Span..Span` is a range with a negative end, so the module
extends `Integers`. The span is a count because the config can't carry a
negative literal (see the lift item), and the negation happens in the module.

## Measurements

From `verify/`, `tlc -workers 1 -noGenerateSpecTE -metadir states/<name>
<Module>.tla -config <Module>.cfg`.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `Altimeters` | reference | rc 0 | 199 | 49 | no error |
| `StaleLamp` | `DriftA` leaves the lamp alone | rc 12 | 6 | 6 | `Invariant FaultIffDisagree is violated.` |

49 is 7 by 7 readings, and the lamp is a function of the two, so that's all of
them.

## Acceptable variants

- Any reserved infix symbol: `\sim`, `\simeq`, `\cong`, `\doteq`. Same operator, other glyph.
- A prefix `Agree(x, y)`. Passes identically. It isn't written between two readings.
- `x - y \in -Tol..Tol`. Same test, as a membership.
- `fault' = (a' - b > Tol \/ b - a' > Tol)`. The negation pushed through.
- `{d \in -1..1 : d /= 0}` for `{-1, 1}`. Same set, more work.

## Wrong neighbors

| neighbor | what kills it |
|---|---|
| a drift that leaves `fault` alone | `FaultIffDisagree` red, six states in |
| `fault' = ~(a \approx b)`, unprimed `a` | the lamp reacts one step late. rc 12 (not measured) |
| `x ~= y == ...` | `~=` isn't a definable symbol. Parse error, rc 150 (not measured) |
| the rule as `fault => ~(a \approx b)` | one direction. A lamp that never lights passes it. The reference still passes, since it's weaker (not measured). |
| `Readings == 0..Span` | the drifts honour the wrong type, so TLC passes. 16 states instead of 49 is the tell (not measured). |

## Why not in prompt

"Something you can write between two readings" is the nudge toward an infix
definition, and "if and only if" is the nudge toward `<=>`. Both are in the
prose because neither has a domain reason to exist otherwise. The honest
caveat: a prefix `Agree(a, b)` is the better engineering here, since nobody has
to look up what `\approx` means, and the only reason to write the infix form is
that this item is for it. I'd tell the reader that in the answer and not in the
prompt.
