# Pair 3: one pair of hands

The first run is one the floor can produce. Your model must allow it. The
second is one the floor can't produce. Your properties must rule it out.

## Allowed

```
State 1
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 0 | p2 0 | p3 0

State 2
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 1 | p2 0 | p3 0

State 3
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 1 | p2 no count | p3 0

State 4
  stage:        p1 on the floor | p2 a loss | p3 on the floor
  modification: p1 2 | p2 no count | p3 0
```

## Forbidden

```
State 1
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 0 | p2 0 | p3 0

State 2
  stage:        p1 on the floor | p2 on the floor | p3 on the floor
  modification: p1 1 | p2 1 | p3 1
```
