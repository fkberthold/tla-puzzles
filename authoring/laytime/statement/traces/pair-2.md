# Pair 2

The first run stays inside the rules. The second breaks at least one rule.

## Allowed

```
State 1
  noticeTendered: FALSE
  laytimeLeft:    2
  demurrage:      0
  finished:       FALSE

State 2
  noticeTendered: TRUE
  laytimeLeft:    2
  demurrage:      0
  finished:       FALSE

State 3
  noticeTendered: TRUE
  laytimeLeft:    1
  demurrage:      0
  finished:       FALSE

State 4
  noticeTendered: TRUE
  laytimeLeft:    0
  demurrage:      0
  finished:       FALSE
```

## Forbidden

```
State 1
  noticeTendered: FALSE
  laytimeLeft:    2
  demurrage:      0
  finished:       FALSE

State 2
  noticeTendered: TRUE
  laytimeLeft:    2
  demurrage:      0
  finished:       FALSE

State 3
  noticeTendered: TRUE
  laytimeLeft:    0
  demurrage:      0
  finished:       FALSE
```
