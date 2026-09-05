# Pair 5

These two runs are about requirement 5. The first stays inside the rules.
The second breaks at least one of them.

## Allowed

```
State 1
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 0 | sheet 2 = 0
  reading:   b1 [sheet 1 = none, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 2
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 0
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 3
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 0
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = TRUE | sheet 2 = FALSE

State 4
  slips:     sheet 1 {n1 at 1} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 0
  reading:   b1 [sheet 1 = none, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = n1 | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE
```

## Forbidden

```
State 1
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 0 | sheet 2 = 0
  reading:   b1 [sheet 1 = none, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 2
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 0
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 3
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 0
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = TRUE | sheet 2 = FALSE

State 4
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 2 | sheet 2 = 0
  reading:   b1 [sheet 1 = 2, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE
```
