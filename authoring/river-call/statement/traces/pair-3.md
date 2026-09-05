# Pair 3

The first run stays inside the rules. The second breaks at least one rule.

## Allowed

```
State 1
  diverted: 1 -> 0, 2 -> 0, 3 -> 0
  calling:  1 -> no, 2 -> no, 3 -> no

State 2
  diverted: 1 -> 2, 2 -> 0, 3 -> 0
  calling:  1 -> no, 2 -> no, 3 -> no

State 3
  diverted: 1 -> 2, 2 -> 0, 3 -> 0
  calling:  1 -> no, 2 -> yes, 3 -> no
```

## Forbidden

```
State 1
  diverted: 1 -> 0, 2 -> 0, 3 -> 0
  calling:  1 -> no, 2 -> no, 3 -> no

State 2
  diverted: 1 -> 0, 2 -> 0, 3 -> 0
  calling:  1 -> yes, 2 -> no, 3 -> no
```
