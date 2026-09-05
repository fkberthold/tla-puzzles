# Pair 6

These two runs are about requirement 6. The first stays inside the rules.
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
  consulted: sheet 1 = 0 | sheet 2 = 1
  reading:   b1 [sheet 1 = none, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = 1]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 3
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = 1]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 4
  slips:     sheet 1 {} | sheet 2 {n1 at 1}
  consulted: sheet 1 = 1 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = none | sheet 2 = n1
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 5
  slips:     sheet 1 {n2 at 1} | sheet 2 {n1 at 1}
  consulted: sheet 1 = 1 | sheet 2 = 1
  reading:   b1 [sheet 1 = none, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = n2 | sheet 2 = n1
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
  consulted: sheet 1 = 0 | sheet 2 = 1
  reading:   b1 [sheet 1 = none, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = 1]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 3
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 1 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = 1]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 4
  slips:     sheet 1 {} | sheet 2 {}
  consulted: sheet 1 = 2 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = 2, sheet 2 = 1]
  accepted:  sheet 1 = none | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 5
  slips:     sheet 1 {n2 at 2} | sheet 2 {}
  consulted: sheet 1 = 2 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = 1]
  accepted:  sheet 1 = n2 | sheet 2 = none
  doubted:   sheet 1 = FALSE | sheet 2 = FALSE

State 6
  slips:     sheet 1 {n2 at 2} | sheet 2 {}
  consulted: sheet 1 = 2 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = 1]
  accepted:  sheet 1 = n2 | sheet 2 = none
  doubted:   sheet 1 = TRUE | sheet 2 = FALSE

State 7
  slips:     sheet 1 {n2 at 2} | sheet 2 {n1 at 1}
  consulted: sheet 1 = 2 | sheet 2 = 1
  reading:   b1 [sheet 1 = 1, sheet 2 = none] | b2 [sheet 1 = none, sheet 2 = none]
  accepted:  sheet 1 = n2 | sheet 2 = n1
  doubted:   sheet 1 = TRUE | sheet 2 = FALSE
```

The forbidden run doesn't end. From its last state onward nothing more ever
happens. `b1` still holds an open consultation of sheet 1, and sheet 1 still
stands doubtful. Neither of those is ever answered.
